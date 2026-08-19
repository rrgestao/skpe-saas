-- ============================================================
-- SK-PE-CONT-01
-- 17-B.5C - Contrato de Leitura Temporal Governada da Jornada
-- Migration permanente derivada do prototipo validado transacionalmente
-- ============================================================

create or replace function public.get_skpe_journey_temporal_read_model(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_as_of_date date default null
)
returns table(
  organization_id uuid,
  organization_timezone text,
  reference_date date,

  project_id uuid,
  project_code text,
  project_name text,
  project_status text,
  project_progress numeric,
  project_start_date date,
  project_target_end_date date,
  project_actual_end_date date,

  item_id uuid,
  parent_item_id uuid,
  item_type text,
  item_code text,
  item_name text,
  item_description text,
  item_status text,
  item_progress numeric,
  display_order integer,
  is_current boolean,
  is_mandatory boolean,
  responsible_user_id uuid,
  responsible_name text,
  validation_required boolean,
  validation_status text,
  blocked boolean,
  blocking_reason text,

  baseline_version_id uuid,
  baseline_version_number integer,
  baseline_governance_status text,
  baseline_start_date date,
  baseline_end_date date,
  baseline_source_mode text,

  current_plan_version_id uuid,
  current_plan_version_number integer,
  current_plan_kind text,
  current_plan_approved_at timestamptz,
  current_plan_start_date date,
  current_plan_end_date date,
  current_plan_source_mode text,

  current_forecast_version_id uuid,
  current_forecast_version_number integer,
  current_forecast_activated_at timestamptz,
  forecast_start_date date,
  forecast_end_date date,
  forecast_source_mode text,

  operational_expected_start_date date,
  operational_expected_end_date date,
  materialized_plan_start_date date,
  materialized_plan_end_date date,
  actual_start_date date,
  actual_end_date date,

  has_approved_plan boolean,
  has_active_forecast boolean,
  plan_projection_consistent boolean,

  current_plan_end_variance_vs_baseline_days integer,
  forecast_end_variance_vs_current_plan_days integer,
  actual_start_variance_vs_current_plan_days integer,
  actual_end_variance_vs_current_plan_days integer,

  is_start_overdue boolean,
  is_completion_overdue boolean,
  days_start_overdue integer,
  days_completion_overdue integer,
  temporal_state text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar a leitura temporal da jornada desta organizacao.'
      using errcode = '42501';
  end if;

  if target_project_id is not null and not exists (
    select 1
    from public.skpe_projects p0
    where p0.id = target_project_id
      and p0.organization_id = target_organization_id
      and p0.archived_at is null
  ) then
    raise exception
      'Projeto SK-PE ativo nao pertence a organizacao informada.'
      using errcode = '22023';
  end if;

  return query
  with project_scope as (
    select
      p.*,
      coalesce(nullif(trim(o.timezone_name), ''), 'UTC') as organization_timezone,
      coalesce(
        target_as_of_date,
        timezone(
          coalesce(nullif(trim(o.timezone_name), ''), 'UTC'),
          now()
        )::date
      ) as reference_date
    from public.skpe_projects p
    join public.organizations o
      on o.id = p.organization_id
    where p.organization_id = target_organization_id
      and p.archived_at is null
      and (target_project_id is null or p.id = target_project_id)
  )
  select
    p.organization_id,
    p.organization_timezone,
    p.reference_date,

    p.id,
    p.code,
    p.name,
    p.status,
    p.progress,
    p.start_date,
    p.target_end_date,
    p.actual_end_date,

    i.id,
    i.parent_item_id,
    i.item_type,
    i.code,
    i.name,
    i.description,
    i.status,
    i.progress,
    i.display_order,
    i.is_current,
    i.is_mandatory,
    i.responsible_user_id,
    coalesce(pr.display_name, pr.full_name, pr.email),
    i.validation_required,
    i.validation_status,
    i.blocked,
    i.blocking_reason,

    bv.id,
    bv.version_number,
    bv.governance_status,
    bi.planned_start_date,
    bi.planned_end_date,
    bi.source_mode,

    cpv.id,
    cpv.version_number,
    cpv.schedule_kind,
    cpv.approved_at,
    cpi.planned_start_date,
    cpi.planned_end_date,
    cpi.source_mode,

    cfv.id,
    cfv.version_number,
    cfv.activated_at,
    cfi.planned_start_date,
    cfi.planned_end_date,
    cfi.source_mode,

    coalesce(cfi.planned_start_date, cpi.planned_start_date),
    coalesce(cfi.planned_end_date, cpi.planned_end_date),
    i.planned_start_date,
    i.planned_end_date,
    i.actual_start_date,
    i.actual_end_date,

    (cpv.id is not null),
    (cfv.id is not null),
    case
      when cpv.id is null then
        i.planned_start_date is null
        and i.planned_end_date is null
      else
        i.planned_start_date is not distinct from cpi.planned_start_date
        and i.planned_end_date is not distinct from cpi.planned_end_date
    end,

    case
      when cpi.planned_end_date is not null
       and bi.planned_end_date is not null
        then (cpi.planned_end_date - bi.planned_end_date)::integer
      else null
    end,
    case
      when cfi.planned_end_date is not null
       and cpi.planned_end_date is not null
        then (cfi.planned_end_date - cpi.planned_end_date)::integer
      else null
    end,
    case
      when i.actual_start_date is not null
       and cpi.planned_start_date is not null
        then (i.actual_start_date - cpi.planned_start_date)::integer
      else null
    end,
    case
      when i.actual_end_date is not null
       and cpi.planned_end_date is not null
        then (i.actual_end_date - cpi.planned_end_date)::integer
      else null
    end,

    (
      i.actual_start_date is null
      and i.status not in ('completed', 'cancelled')
      and cpi.planned_start_date is not null
      and p.reference_date > cpi.planned_start_date
    ),
    (
      i.actual_end_date is null
      and i.status not in ('completed', 'cancelled')
      and cpi.planned_end_date is not null
      and p.reference_date > cpi.planned_end_date
    ),
    case
      when i.actual_start_date is null
       and i.status not in ('completed', 'cancelled')
       and cpi.planned_start_date is not null
       and p.reference_date > cpi.planned_start_date
        then (p.reference_date - cpi.planned_start_date)::integer
      else 0
    end,
    case
      when i.actual_end_date is null
       and i.status not in ('completed', 'cancelled')
       and cpi.planned_end_date is not null
       and p.reference_date > cpi.planned_end_date
        then (p.reference_date - cpi.planned_end_date)::integer
      else 0
    end,

    case
      when i.status = 'cancelled' then 'cancelled'
      when cpv.id is null
        or cpi.planned_start_date is null
        or cpi.planned_end_date is null
        then 'unscheduled'
      when i.status = 'completed' and i.actual_end_date is null
        then 'completed_without_actual_end'
      when i.status = 'completed' and i.actual_end_date <= cpi.planned_end_date
        then 'completed_on_time'
      when i.status = 'completed' and i.actual_end_date > cpi.planned_end_date
        then 'completed_late'
      when i.status = 'blocked' then 'blocked'
      when i.actual_end_date is null and p.reference_date > cpi.planned_end_date
        then 'completion_overdue'
      when i.actual_start_date is null and p.reference_date > cpi.planned_start_date
        then 'start_overdue'
      else 'on_schedule'
    end
  from project_scope p
  join public.skpe_journey_items i
    on i.project_id = p.id
   and i.archived_at is null
  left join public.profiles pr
    on pr.id = i.responsible_user_id

  -- Baseline original: primeira baseline institucional da Jornada.
  left join lateral (
    select v.*
    from public.skpe_journey_schedule_versions v
    where v.project_id = p.id
      and v.schedule_kind = 'baseline'
      and v.governance_status in ('approved', 'superseded')
    order by v.version_number asc
    limit 1
  ) bv on true
  left join public.skpe_journey_schedule_items bi
    on bi.schedule_version_id = bv.id
   and bi.journey_item_id = i.id

  -- Plano institucional vigente: baseline/rebaseline aprovado e corrente.
  left join lateral (
    select v.*
    from public.skpe_journey_schedule_versions v
    where v.project_id = p.id
      and v.is_current_plan
      and v.governance_status = 'approved'
    order by v.version_number desc
    limit 1
  ) cpv on true
  left join public.skpe_journey_schedule_items cpi
    on cpi.schedule_version_id = cpv.id
   and cpi.journey_item_id = i.id

  -- Forecast operacional vigente: nunca substitui o compromisso institucional.
  left join lateral (
    select v.*
    from public.skpe_journey_schedule_versions v
    where v.project_id = p.id
      and v.is_current_forecast
      and v.governance_status = 'active'
    order by v.version_number desc
    limit 1
  ) cfv on true
  left join public.skpe_journey_schedule_items cfi
    on cfi.schedule_version_id = cfv.id
   and cfi.journey_item_id = i.id

  order by p.created_at, i.display_order, i.code;
end;
$$;

revoke all on function public.get_skpe_journey_temporal_read_model(uuid, uuid, date)
from public, anon;

grant execute on function public.get_skpe_journey_temporal_read_model(uuid, uuid, date)
to authenticated, service_role;
