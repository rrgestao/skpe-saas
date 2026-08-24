-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.6G-C2B.5A.1
-- Organization Overview Metric Convergence
--
-- Authority for initiative portfolio:
--   public.sparks_initiatives
--
-- Preserves module-scoped semantics of:
--   public.get_organization_network_dashboard(...)
--
-- Explicitly removes read dependency on:
--   public.skpe_initiatives
-- ============================================================

begin;

create or replace function public.get_organization_network_dashboard(
  target_organization_id uuid,
  target_module_code text default 'SK-PE'
)
returns table(
  organization_id uuid,
  organization_code text,
  organization_name text,
  organization_level text,
  hierarchy_depth integer,
  module_enabled boolean,
  active_projects bigint,
  average_project_progress numeric,
  initiatives_total bigint,
  initiatives_attention bigint,
  active_memberships bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  with recursive child_edges as (
    select
      o.parent_organization_id as parent_id,
      o.id as child_id
    from public.organizations o
    where o.parent_organization_id is not null

    union

    select
      r.parent_organization_id,
      r.child_organization_id
    from public.organization_relationships r
    join public.organization_relationship_types rt
      on rt.id = r.relationship_type_id
    where rt.is_hierarchical = true
      and r.status = 'active'
      and r.valid_from <= current_date
      and (
        r.valid_until is null
        or r.valid_until >= current_date
      )
  ),
  network as (
    select
      target_organization_id as organization_id,
      0 as hierarchy_depth,
      array[target_organization_id]::uuid[] as path

    union all

    select
      e.child_id,
      n.hierarchy_depth + 1,
      n.path || e.child_id
    from network n
    join child_edges e
      on e.parent_id = n.organization_id
    where n.hierarchy_depth < 20
      and not (e.child_id = any(n.path))
  ),
  visible_network as (
    select distinct on (n.organization_id)
      n.organization_id,
      n.hierarchy_depth
    from network n
    where n.organization_id = target_organization_id
       or public.is_platform_super_admin()
       or public.can_access_descendant_organization(
            n.organization_id,
            target_module_code,
            'consolidated'
          )
    order by
      n.organization_id,
      n.hierarchy_depth
  )
  select
    o.id,
    o.code,
    coalesce(o.trade_name, o.legal_name, o.code),
    o.organization_level::text,
    vn.hierarchy_depth,
    exists (
      select 1
      from public.organization_modules om
      join public.modules m
        on m.id = om.module_id
      where om.organization_id = o.id
        and upper(m.code) = upper(target_module_code)
        and m.status = 'active'
        and om.enabled = true
        and om.status in ('trial', 'active')
    ),
    coalesce(projects.active_projects, 0),
    coalesce(projects.average_progress, 0),
    coalesce(initiatives.initiatives_total, 0),
    coalesce(initiatives.initiatives_attention, 0),
    coalesce(memberships.active_memberships, 0)
  from visible_network vn
  join public.organizations o
    on o.id = vn.organization_id
  left join lateral (
    select
      count(*) filter (
        where p.status in ('draft', 'active', 'suspended')
      ) as active_projects,
      round(
        coalesce(
          avg(p.progress) filter (
            where p.status <> 'archived'
          ),
          0
        )::numeric,
        2
      ) as average_progress
    from public.skpe_projects p
    where p.organization_id = o.id
      and p.archived_at is null
  ) projects on true
  left join lateral (
    select
      count(*) filter (
        where i.status <> 'archived'
      ) as initiatives_total,
      count(*) filter (
        where i.status = 'blocked'
           or i.health_status in ('attention', 'critical')
           or i.risk_level in ('high', 'critical')
      ) as initiatives_attention
    from public.sparks_initiatives i
    where i.organization_id = o.id
      and i.archived_at is null
      and upper(coalesce(i.source_module_code, ''))
          = upper(trim(target_module_code))
  ) initiatives on true
  left join lateral (
    select
      count(*) as active_memberships
    from public.organization_memberships om
    where om.organization_id = o.id
      and om.status = 'active'
      and om.valid_from <= timezone('utc', now())
      and (
        om.valid_until is null
        or om.valid_until >= timezone('utc', now())
      )
  ) memberships on true
  where o.status = 'active'
  order by
    vn.hierarchy_depth,
    lower(coalesce(o.trade_name, o.legal_name, o.code));
$$;

commit;