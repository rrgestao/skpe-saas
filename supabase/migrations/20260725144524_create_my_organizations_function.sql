create or replace function public.get_my_organizations()
returns table (
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  organization_level public.organization_level,
  membership_status public.membership_status,
  is_organization_admin boolean
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    organization.id,
    organization.code,
    organization.legal_name,
    organization.trade_name,
    organization.organization_level,
    membership.status,
    membership.is_organization_admin
  from public.organization_memberships membership
  join public.organizations organization
    on organization.id = membership.organization_id
  where membership.user_id = auth.uid()
    and membership.status = 'active'
    and organization.status = 'active'
    and membership.valid_from <= timezone('utc', now())
    and (
      membership.valid_until is null
      or membership.valid_until >= timezone('utc', now())
    )
  order by organization.legal_name;
$$;

revoke all on function public.get_my_organizations() from public;
grant execute on function public.get_my_organizations() to authenticated;

comment on function public.get_my_organizations() is
  'Retorna as organizações ativas às quais o usuário autenticado possui vínculo ativo.';