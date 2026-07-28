-- ============================================================
-- Plataforma SPARKs
-- Correção da manutenção global de organizações
-- - inclui description no retorno da listagem administrativa;
-- - expõe detalhe completo para reabertura após salvar;
-- - preserva o upsert existente e valida o resultado persistido.
-- ============================================================

begin;

-- O PostgreSQL não permite alterar o tipo de retorno de uma função
-- existente com CREATE OR REPLACE. Por isso, a função é recriada.
drop function if exists public.get_platform_admin_organizations();

create function public.get_platform_admin_organizations()
returns table (
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  organization_level text,
  organization_type text,
  status text,
  parent_organization_id uuid,
  parent_organization_name text,
  cnpj text,
  state_code text,
  city text,
  institutional_email text,
  cooperative_branch text,
  description text,
  memberships_count bigint,
  enabled_modules_count bigint,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    o.id,
    o.code,
    o.legal_name,
    o.trade_name,
    o.organization_level::text,
    o.organization_type,
    o.status::text,
    o.parent_organization_id,
    coalesce(parent.trade_name, parent.legal_name, parent.code),
    coalesce(o.cnpj, o.tax_identifier),
    o.state_code::text,
    o.city,
    coalesce(o.institutional_email, o.email),
    o.cooperative_branch,
    o.description,
    (
      select count(*)
      from public.organization_memberships om
      where om.organization_id = o.id
        and om.status::text <> 'revoked'
    ),
    (
      select count(*)
      from public.organization_modules orm
      where orm.organization_id = o.id
        and orm.enabled = true
        and orm.status = 'active'
    ),
    o.created_at,
    o.updated_at
  from public.organizations o
  left join public.organizations parent
    on parent.id = o.parent_organization_id
  order by lower(coalesce(o.trade_name, o.legal_name, o.code));
end;
$$;

create or replace function public.get_platform_admin_organization_detail(
  target_organization_id uuid
)
returns table (
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  organization_level text,
  organization_type text,
  status text,
  parent_organization_id uuid,
  parent_organization_name text,
  cnpj text,
  state_code text,
  city text,
  institutional_email text,
  cooperative_branch text,
  description text,
  memberships_count bigint,
  enabled_modules_count bigint,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    o.id,
    o.code,
    o.legal_name,
    o.trade_name,
    o.organization_level::text,
    o.organization_type,
    o.status::text,
    o.parent_organization_id,
    coalesce(parent.trade_name, parent.legal_name, parent.code),
    coalesce(o.cnpj, o.tax_identifier),
    o.state_code::text,
    o.city,
    coalesce(o.institutional_email, o.email),
    o.cooperative_branch,
    o.description,
    (
      select count(*)
      from public.organization_memberships om
      where om.organization_id = o.id
        and om.status::text <> 'revoked'
    ),
    (
      select count(*)
      from public.organization_modules orm
      where orm.organization_id = o.id
        and orm.enabled = true
        and orm.status = 'active'
    ),
    o.created_at,
    o.updated_at
  from public.organizations o
  left join public.organizations parent
    on parent.id = o.parent_organization_id
  where o.id = target_organization_id;
end;
$$;

revoke all on function public.get_platform_admin_organizations() from public;
revoke all on function public.get_platform_admin_organization_detail(uuid) from public;

grant execute on function public.get_platform_admin_organizations() to authenticated, service_role;
grant execute on function public.get_platform_admin_organization_detail(uuid) to authenticated, service_role;

comment on function public.get_platform_admin_organization_detail(uuid) is
  'Retorna o cadastro completo da organização para visualização e manutenção pelo SUPER-ADMIN.';

commit;

-- Verificação somente de leitura.
select
  organization_id,
  organization_code,
  legal_name,
  trade_name,
  description,
  updated_at
from public.get_platform_admin_organizations()
order by lower(coalesce(trade_name, legal_name, organization_code));
