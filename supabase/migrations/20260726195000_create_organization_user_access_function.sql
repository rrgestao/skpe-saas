-- ============================================================
-- SK-PE SaaS
-- Migration: Consulta Administrativa de Usuários e Acessos
-- ============================================================

create or replace function public.get_organization_user_access(target_organization_id uuid)
returns table (
  membership_id uuid,
  user_id uuid,
  user_email text,
  user_display_name text,
  user_active boolean,
  membership_status text,
  is_organization_admin boolean,
  job_title text,
  membership_valid_from timestamptz,
  membership_valid_until timestamptz,
  organization_module_id uuid,
  module_id uuid,
  module_code text,
  module_name text,
  module_short_name text,
  user_module_role_id uuid,
  module_role_id uuid,
  role_code text,
  role_name text,
  module_role_status text,
  module_role_valid_from timestamptz,
  module_role_valid_until timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_manage_organization(target_organization_id) then
    raise exception 'Acesso negado: o usuário não pode administrar esta organização.' using errcode='42501';
  end if;

  return query
  select
    membership.id,
    profile.id,
    profile.email,
    profile.display_name,
    profile.active,
    membership.status::text,
    membership.is_organization_admin,
    membership.job_title,
    membership.valid_from,
    membership.valid_until,
    organization_module.id,
    platform_module.id,
    platform_module.code,
    platform_module.name,
    platform_module.short_name,
    user_module_role.id,
    module_role.id,
    module_role.code,
    module_role.name,
    user_module_role.status::text,
    user_module_role.valid_from,
    user_module_role.valid_until
  from public.organization_memberships membership
  join public.profiles profile on profile.id=membership.user_id
  left join public.organization_modules organization_module
    on organization_module.organization_id=membership.organization_id
  left join public.user_module_roles user_module_role
    on user_module_role.organization_module_id=organization_module.id
   and user_module_role.user_id=membership.user_id
  left join public.modules platform_module
    on platform_module.id=organization_module.module_id
  left join public.module_roles module_role
    on module_role.id=user_module_role.module_role_id
   and module_role.module_id=platform_module.id
  where membership.organization_id=target_organization_id
  order by membership.is_organization_admin desc,
           coalesce(profile.display_name,profile.email),
           platform_module.name,
           module_role.name;
end;
$$;

comment on function public.get_organization_user_access(uuid) is
  'Retorna usuários, vínculos organizacionais, módulos e papéis de uma organização para administradores autorizados.';

revoke all on function public.get_organization_user_access(uuid) from public;
grant execute on function public.get_organization_user_access(uuid) to authenticated,service_role;
