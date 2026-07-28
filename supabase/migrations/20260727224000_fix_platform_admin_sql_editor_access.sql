-- ============================================================
-- Plataforma SPARKs
-- Correção de acesso administrativo pelo Supabase SQL Editor
-- Data: 2026-07-27
--
-- Objetivo:
-- - manter o acesso do frontend restrito ao SUPER-ADMIN;
-- - permitir execução administrativa pelo service_role;
-- - permitir validações no Supabase SQL Editor, cuja sessão
--   administrativa não possui auth.uid().
-- ============================================================

begin;

create or replace function public.require_platform_super_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  -- Usuário autenticado com o perfil global SUPER-ADMIN.
  if public.is_platform_super_admin() then
    return;
  end if;

  -- Chamadas administrativas seguras realizadas com service_role.
  if coalesce(auth.role(), '') = 'service_role' then
    return;
  end if;

  -- Execução manual no SQL Editor do Supabase.
  -- session_user preserva o papel real que iniciou a sessão,
  -- mesmo dentro de uma função SECURITY DEFINER.
  if session_user in ('postgres', 'supabase_admin') then
    return;
  end if;

  raise exception 'Acesso restrito ao SUPER-ADMIN da Plataforma SPARKs.'
    using errcode = '42501';
end;
$$;

revoke all on function public.require_platform_super_admin() from public;
grant execute on function public.require_platform_super_admin()
  to authenticated, service_role;

commit;

-- Verificação imediata. No SQL Editor, deve retornar sem erro.
select
  session_user as sessao_sql,
  auth.uid() as usuario_autenticado,
  auth.role() as papel_jwt,
  'Acesso administrativo validado'::text as resultado;

select * from public.get_platform_admin_summary();
