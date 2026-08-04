-- FE-09.A.02.2.5-B5.1
-- Hierarquia organizacional canônica para o Portal da Plataforma.
-- Não altera dados de negócio.

create or replace function public.get_my_organization_hierarchy_v1()
returns table (
  organization_id uuid,
  parent_organization_id uuid,
  hierarchy_depth integer,
  hierarchy_path uuid[]
)
language sql
stable
security definer
set search_path = ''
as $function$
  with recursive canonical_parent as (
    select
      organization.id as organization_id,
      coalesce(
        organization.parent_organization_id,
        relationship.parent_organization_id
      ) as parent_organization_id
    from public.organizations organization
    left join lateral (
      select relation.parent_organization_id
      from public.organization_relationships relation
      where relation.child_organization_id = organization.id
        and relation.status = 'active'
        and relation.valid_from <= current_date
        and (
          relation.valid_until is null
          or relation.valid_until >= current_date
        )
      order by
        relation.valid_from desc,
        relation.created_at desc nulls last,
        relation.id
      limit 1
    ) relationship on true
    where organization.status::text = 'active'
  ),
  roots as (
    select
      parent.organization_id,
      parent.parent_organization_id,
      0::integer as hierarchy_depth,
      array[parent.organization_id]::uuid[] as hierarchy_path
    from canonical_parent parent
    where parent.parent_organization_id is null
       or not exists (
         select 1
         from canonical_parent possible_parent
         where possible_parent.organization_id =
           parent.parent_organization_id
       )
  ),
  tree as (
    select
      root.organization_id,
      root.parent_organization_id,
      root.hierarchy_depth,
      root.hierarchy_path
    from roots root

    union all

    select
      child.organization_id,
      child.parent_organization_id,
      tree.hierarchy_depth + 1,
      tree.hierarchy_path || child.organization_id
    from tree
    join canonical_parent child
      on child.parent_organization_id = tree.organization_id
    where not child.organization_id = any(tree.hierarchy_path)
      and tree.hierarchy_depth < 50
  ),
  visible as (
    select distinct on (tree.organization_id)
      tree.organization_id,
      tree.parent_organization_id,
      tree.hierarchy_depth,
      tree.hierarchy_path
    from tree
    where public.is_platform_super_admin()
       or exists (
         select 1
         from public.organization_memberships membership
         where membership.user_id = auth.uid()
           and membership.organization_id = tree.organization_id
           and membership.status::text = 'active'
       )
       or public.can_access_descendant_organization(
         tree.organization_id,
         'SK-PE',
         'read'
       )
    order by tree.organization_id, tree.hierarchy_depth
  )
  select
    visible.organization_id,
    visible.parent_organization_id,
    visible.hierarchy_depth,
    visible.hierarchy_path
  from visible
  order by visible.hierarchy_path;
$function$;

comment on function public.get_my_organization_hierarchy_v1() is
'Retorna a hierarquia organizacional canônica visível ao usuário autenticado. Prioriza organizations.parent_organization_id e usa organization_relationships como alternativa ativa.';

revoke all on function public.get_my_organization_hierarchy_v1()
from public, anon;

grant execute on function public.get_my_organization_hierarchy_v1()
to authenticated, service_role;
