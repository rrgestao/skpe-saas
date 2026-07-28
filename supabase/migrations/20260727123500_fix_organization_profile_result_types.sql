begin;

-- ============================================================
-- Plataforma SPARKs
-- Correção da API de Cadastro Institucional
-- Garante correspondência exata entre os tipos declarados pela
-- função e os tipos retornados pela consulta.
-- ============================================================

create or replace function public.get_sparks_organization_profile(
  target_organization_id uuid
)
returns table (
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  formatted_cnpj text,
  cnpj_digits text,
  institutional_email text,
  phone text,
  website text,
  postal_code text,
  street text,
  address_number text,
  address_complement text,
  district text,
  city text,
  state_code text,
  country_code text,
  logo_url text,
  logo_storage_path text,
  logo_version integer,
  cooperative_branch text,
  organization_size text,
  institutional_profile_updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (
    public.is_platform_super_admin()
    or exists (
      select 1
      from public.organization_memberships membership
      where membership.organization_id = target_organization_id
        and membership.user_id = auth.uid()
        and membership.status = 'active'
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar o cadastro institucional desta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    organization.id::uuid,
    organization.code::text,
    organization.legal_name::text,
    organization.trade_name::text,
    public.sparks_format_cnpj(organization.cnpj)::text,
    organization.cnpj::text,
    organization.institutional_email::text,
    organization.phone::text,
    organization.website::text,
    organization.postal_code::text,
    organization.street::text,
    organization.address_number::text,
    organization.address_complement::text,
    organization.district::text,
    organization.city::text,
    organization.state_code::text,
    organization.country_code::text,
    organization.logo_url::text,
    organization.logo_storage_path::text,
    coalesce(organization.logo_version, 0)::integer,
    organization.cooperative_branch::text,
    organization.organization_size::text,
    organization.institutional_profile_updated_at::timestamptz
  from public.organizations organization
  where organization.id = target_organization_id;
end;
$$;

comment on function public.get_sparks_organization_profile(uuid) is
  'Retorna o cadastro institucional consolidado da organização, com conversão explícita dos tipos de saída para estabilidade da API.';

revoke all on function public.get_sparks_organization_profile(uuid) from public;
grant execute on function public.get_sparks_organization_profile(uuid) to authenticated;

commit;
