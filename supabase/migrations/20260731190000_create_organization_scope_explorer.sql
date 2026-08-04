-- FE-09.A.01-C1.8.2-A
-- Read-only organizational scope explorer.
-- This migration creates no business table and performs no data mutation.

create or replace function public.get_organization_scope_explorer(
  root_organization_id uuid,
  target_module_code text default 'SK-PE',
  target_domain text default 'users',
  include_inactive boolean default false
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_domain text := lower(trim(coalesce(target_domain, 'users')));
  v_module text := upper(trim(coalesce(target_module_code, 'SK-PE')));
  v_result jsonb;
begin
  if auth.uid() is null and auth.role() <> 'service_role' and session_user not in ('postgres', 'supabase_admin') then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if root_organization_id is null then
    raise exception 'ROOT_ORGANIZATION_REQUIRED';
  end if;

  if v_domain not in ('users', 'areas', 'roles', 'responsibilities') then
    raise exception 'UNSUPPORTED_SCOPE_DOMAIN: %', v_domain;
  end if;

  if auth.role() <> 'service_role'
     and session_user not in ('postgres', 'supabase_admin')
     and not public.can_access_descendant_organization(root_organization_id, v_module, 'read') then
    raise exception 'ACCESS_DENIED_FOR_ROOT_ORGANIZATION';
  end if;

  with recursive relationship_edges as (
    select o.parent_organization_id as parent_id, o.id as child_id
    from public.organizations o
    where o.parent_organization_id is not null

    union

    select r.parent_organization_id, r.child_organization_id
    from public.organization_relationships r
    where r.status = 'active'
      and r.valid_from <= current_date
      and (r.valid_until is null or r.valid_until >= current_date)
  ), organization_tree as (
    select
      o.id as organization_id,
      o.parent_organization_id,
      0 as depth,
      array[o.id]::uuid[] as path
    from public.organizations o
    where o.id = root_organization_id

    union all

    select
      child.id,
      edge.parent_id,
      tree.depth + 1,
      tree.path || child.id
    from organization_tree tree
    join relationship_edges edge on edge.parent_id = tree.organization_id
    join public.organizations child on child.id = edge.child_id
    where not child.id = any(tree.path)
      and tree.depth < 50
  ), accessible_tree as (
    select distinct on (tree.organization_id)
      tree.organization_id,
      tree.parent_organization_id,
      tree.depth,
      tree.path
    from organization_tree tree
    where
      auth.role() = 'service_role'
      or session_user in ('postgres', 'supabase_admin')
      or public.can_access_descendant_organization(tree.organization_id, v_module, 'read')
    order by tree.organization_id, tree.depth
  ), organization_nodes as (
    select
      tree.organization_id,
      tree.parent_organization_id,
      tree.depth,
      tree.path,
      organization.code as organization_code,
      organization.legal_name,
      organization.trade_name,
      organization.status::text as organization_status,
      case
        when tree.organization_id = root_organization_id then 'root'
        when exists (
          select 1
          from public.organization_memberships membership
          where membership.organization_id = tree.organization_id
            and membership.user_id = auth.uid()
            and membership.status::text = 'active'
        ) then 'direct_membership'
        else 'hierarchical_policy'
      end as access_origin,
      case
        when tree.organization_id = root_organization_id then 'root'
        when public.can_access_descendant_organization(tree.organization_id, v_module, 'manage_users') then 'manage_users'
        else 'read_only'
      end as access_mode
    from accessible_tree tree
    join public.organizations organization on organization.id = tree.organization_id
    where include_inactive or organization.status::text = 'active'
  ), node_payloads as (
    select
      node.*,
      case v_domain
        when 'users' then (
          select coalesce(jsonb_agg(jsonb_build_object(
            'membership_id', membership.id,
            'user_id', profile.id,
            'email', profile.email,
            'display_name', profile.display_name,
            'user_active', profile.active,
            'membership_status', membership.status::text,
            'is_organization_admin', membership.is_organization_admin,
            'job_title', membership.job_title,
            'valid_from', membership.valid_from,
            'valid_until', membership.valid_until
          ) order by coalesce(profile.display_name, profile.email)), '[]'::jsonb)
          from public.organization_memberships membership
          join public.profiles profile on profile.id = membership.user_id
          where membership.organization_id = node.organization_id
            and (include_inactive or (membership.status::text = 'active' and profile.active))
        )
        when 'roles' then (
          select coalesce(jsonb_agg(jsonb_build_object(
            'role_id', role.id,
            'role_code', role.code,
            'role_name', role.name,
            'role_type', role.role_type,
            'organizational_area', role.organizational_area,
            'authority_level', role.authority_level,
            'is_governance_role', role.is_governance_role,
            'requires_mandate', role.requires_mandate,
            'active', role.active
          ) order by role.name), '[]'::jsonb)
          from public.sparks_organizational_roles role
          where role.organization_id = node.organization_id
            and (include_inactive or role.active)
        )
        when 'responsibilities' then (
          select coalesce(jsonb_agg(jsonb_build_object(
            'assignment_id', assignment.id,
            'object_type', assignment.object_type,
            'object_id', assignment.object_id,
            'organization_person_id', assignment.organization_person_id,
            'responsibility_type', assignment.responsibility_type,
            'allocation_percentage', assignment.allocation_percentage,
            'authority_level', assignment.authority_level,
            'valid_from', assignment.valid_from,
            'valid_until', assignment.valid_until,
            'status', assignment.status
          ) order by assignment.object_type, assignment.object_id), '[]'::jsonb)
          from public.sparks_responsibility_assignments assignment
          where assignment.organization_id = node.organization_id
            and assignment.module_code = v_module
            and (include_inactive or assignment.status = 'active')
        )
        when 'areas' then (
          select coalesce(jsonb_agg(jsonb_build_object(
            'area_id', value.id,
            'area_code', value.code,
            'area_name', value.name,
            'area_description', value.description,
            'parent_area_id', value.parent_value_id,
            'display_order', value.display_order,
            'active', value.active,
            'metadata', value.metadata
          ) order by value.display_order, value.name), '[]'::jsonb)
          from public.sparks_domain_values value
          join public.sparks_domains domain on domain.id = value.domain_id
          where domain.organization_id = node.organization_id
            and domain.scope_type = 'organization'
            and domain.code = 'ORGANIZATIONAL_AREA'
            and (include_inactive or value.active)
        )
      end as items
    from organization_nodes node
  )
  select jsonb_build_object(
    'contract_version', '1.0',
    'generated_at', timezone('utc', now()),
    'root_organization_id', root_organization_id,
    'module_code', v_module,
    'domain', v_domain,
    'include_inactive', include_inactive,
    'organization_count', count(*),
    'organizations', coalesce(jsonb_agg(jsonb_build_object(
      'organization_id', payload.organization_id,
      'organization_code', payload.organization_code,
      'organization_name', coalesce(payload.trade_name, payload.legal_name),
      'legal_name', payload.legal_name,
      'trade_name', payload.trade_name,
      'parent_organization_id', payload.parent_organization_id,
      'depth', payload.depth,
      'path', payload.path,
      'organization_status', payload.organization_status,
      'access_origin', payload.access_origin,
      'access_mode', payload.access_mode,
      'detail_available', true,
      'item_count', jsonb_array_length(payload.items),
      'items', payload.items
    ) order by payload.path), '[]'::jsonb)
  )
  into v_result
  from node_payloads payload;

  return coalesce(v_result, jsonb_build_object(
    'contract_version', '1.0',
    'generated_at', timezone('utc', now()),
    'root_organization_id', root_organization_id,
    'module_code', v_module,
    'domain', v_domain,
    'include_inactive', include_inactive,
    'organization_count', 0,
    'organizations', '[]'::jsonb
  ));
end;
$function$;

comment on function public.get_organization_scope_explorer(uuid, text, text, boolean) is
'Read-only aggregated explorer for organizations and the users, areas, roles or responsibilities visible in each accessible organizational scope.';

revoke all on function public.get_organization_scope_explorer(uuid, text, text, boolean) from public, anon;
grant execute on function public.get_organization_scope_explorer(uuid, text, text, boolean) to authenticated, service_role;