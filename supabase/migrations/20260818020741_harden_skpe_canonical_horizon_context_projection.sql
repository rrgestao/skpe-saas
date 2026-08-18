-- GATE-17-B.4B.1 — Canonical Horizon Context Projection
-- Keep legacy RPC result shapes stable while sourcing Horizon values from the canonical entity.

create or replace function public.get_skpe_project_context(
  target_organization_id uuid
)
returns table(
  project_id uuid,
  project_code text,
  project_name text,
  project_status text,
  project_progress numeric,
  current_phase_code text,
  planning_horizon_start_year integer,
  planning_horizon_end_year integer,
  reference_year integer,
  review_cycle text,
  valid_from date,
  valid_until date
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode consultar o contexto estratégico desta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.code,
    p.name,
    p.status,
    p.progress,
    p.current_phase_code,
    h.horizon_start_year,
    h.horizon_end_year,
    p.reference_year,
    p.review_cycle,
    coalesce(h.valid_from, p.valid_from),
    coalesce(h.valid_until, p.valid_until)
  from public.skpe_projects p
  left join lateral (
    select
      sh.horizon_start_year,
      sh.horizon_end_year,
      sh.valid_from,
      sh.valid_until
    from public.skpe_strategic_horizons sh
    where sh.project_id = p.id
      and sh.is_current = true
      and sh.governance_status in ('approved','historical_recognized')
    order by sh.version_number desc
    limit 1
  ) h on true
  where p.organization_id = target_organization_id
    and p.archived_at is null
    and p.status <> 'archived'
  order by p.created_at desc
  limit 1;
end;
$$;

create or replace function public.get_skpe_projects_for_selection(
  target_organization_id uuid
)
returns table(
  project_id uuid,
  project_code text,
  project_name text,
  project_status text,
  project_progress numeric,
  current_phase_code text,
  planning_horizon_start_year integer,
  planning_horizon_end_year integer,
  reference_year integer,
  review_cycle text,
  valid_from date,
  valid_until date,
  start_date date,
  target_end_date date,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception
      'Usuário sem permissão para consultar os projetos estratégicos desta organização.'
      using errcode='42501';
  end if;

  return query
  select
    p.id,
    p.code,
    p.name,
    p.status,
    p.progress,
    p.current_phase_code,
    h.horizon_start_year,
    h.horizon_end_year,
    p.reference_year,
    p.review_cycle,
    coalesce(h.valid_from, p.valid_from),
    coalesce(h.valid_until, p.valid_until),
    p.start_date,
    p.target_end_date,
    p.updated_at
  from public.skpe_projects p
  left join lateral (
    select
      sh.horizon_start_year,
      sh.horizon_end_year,
      sh.valid_from,
      sh.valid_until
    from public.skpe_strategic_horizons sh
    where sh.project_id = p.id
      and sh.is_current = true
      and sh.governance_status in ('approved','historical_recognized')
    order by sh.version_number desc
    limit 1
  ) h on true
  where p.organization_id = target_organization_id
    and p.archived_at is null
  order by
    case p.status
      when 'active' then 1
      when 'draft' then 2
      when 'suspended' then 3
      when 'completed' then 4
      else 5
    end,
    p.updated_at desc,
    p.name;
end;
$$;

revoke all on function public.get_skpe_project_context(uuid) from public, anon;
revoke all on function public.get_skpe_projects_for_selection(uuid) from public, anon;

grant execute on function public.get_skpe_project_context(uuid) to authenticated, service_role;
grant execute on function public.get_skpe_projects_for_selection(uuid) to authenticated, service_role;