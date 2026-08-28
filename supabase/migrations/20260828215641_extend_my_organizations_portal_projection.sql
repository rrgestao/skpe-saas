begin;

drop function if exists public.get_my_organizations_v2();

create function public.get_my_organizations_v2()
returns table(
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  organization_level text,
  membership_status text,
  is_organization_admin boolean,
  access_origin text,
  access_mode text,
  source_organization_id uuid,
  source_organization_name text,
  hierarchy_depth integer,
  can_manage_organization boolean,
  cooperative_branch text,
  logo_storage_path text
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    organization.id::uuid as organization_id,
    organization.code::text as organization_code,
    organization.legal_name::text,
    organization.trade_name::text,
    organization.organization_level::text,
    coalesce(direct_membership.status::text, 'hierarchical') as membership_status,
    (
      public.is_platform_super_admin()
      or coalesce(direct_membership.is_organization_admin, false)
    ) as is_organization_admin,
    case
      when direct_membership.id is not null then 'direct_membership'
      when public.is_platform_super_admin() then 'platform_super_admin'
      else 'hierarchical_management'
    end::text as access_origin,
    case
      when public.is_platform_super_admin() then 'administrative'
      when direct_membership.is_organization_admin = true then 'administrative'
      when direct_membership.id is not null then 'direct'
      else 'read_only'
    end::text as access_mode,
    hierarchy_source.organization_id::uuid as source_organization_id,
    hierarchy_source.organization_name::text as source_organization_name,
    hierarchy_source.depth::integer as hierarchy_depth,
    (
      public.is_platform_super_admin()
      or coalesce(direct_membership.is_organization_admin, false)
    ) as can_manage_organization,
    case
      when organization.organization_type = 'system' then 'Todos os Ramos'
      else organization.cooperative_branch
    end::text as cooperative_branch,
    organization.logo_storage_path::text
  from public.organizations organization
  left join public.organization_memberships direct_membership
    on direct_membership.organization_id = organization.id
   and direct_membership.user_id = auth.uid()
   and direct_membership.status = 'active'
   and direct_membership.valid_from <= timezone('utc', now())
   and (
     direct_membership.valid_until is null
     or direct_membership.valid_until >= timezone('utc', now())
   )
  left join lateral (
    select
      ancestor.organization_id,
      coalesce(source.trade_name, source.legal_name, source.code) as organization_name,
      ancestor.depth
    from public.get_organization_ancestors(organization.id, 50) ancestor
    join public.organization_memberships source_membership
      on source_membership.organization_id = ancestor.organization_id
     and source_membership.user_id = auth.uid()
     and source_membership.status = 'active'
     and source_membership.is_organization_admin = true
     and source_membership.valid_from <= timezone('utc', now())
     and (
       source_membership.valid_until is null
       or source_membership.valid_until >= timezone('utc', now())
     )
    join public.organizations source
      on source.id = ancestor.organization_id
    order by ancestor.depth
    limit 1
  ) hierarchy_source on true
  where organization.status = 'active'
    and (
      public.is_platform_super_admin()
      or public.can_access_descendant_organization(organization.id, null, 'read')
    )
  order by lower(coalesce(organization.trade_name, organization.legal_name, organization.code));
$function$;

revoke all on function public.get_my_organizations_v2() from public, anon;
grant execute on function public.get_my_organizations_v2() to authenticated, service_role;

commit;
