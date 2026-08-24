-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.6H-S5B
-- Derived Temporal Projection
--
-- Authorities:
--   public.sparks_initiatives
--   public.sparks_initiative_actions
--
-- Semantics:
--   baseline = compromisso temporal original
--   plan     = plano vigente
--   forecast = melhor estimativa operacional atual
--   actual   = realizado governado pelo lifecycle
--
-- Projection only:
--   - atraso e variancias sao derivados;
--   - temporal_state nao e persistido;
--   - Gantt e consumidor, nunca fonte de verdade;
--   - blocked permanece lifecycle, nao temporal_state;
--   - proposed/under_analysis nao geram atraso de inicio;
--     atraso de inicio exige compromisso approved/planned;
--   - dados legados sem started_at nao sao fabricados;
--   - completed sem actual_end possui temporal_state nulo
--     e qualidade de dado explicita, sem classificacao ficticia.
--
-- Out of scope:
--   agenda/events (6I)
--   costs/effort governance (6J)
-- ============================================================

begin;

create or replace function public.get_sparks_initiative_temporal_projection(
  target_organization_id uuid,
  target_initiative_id uuid default null,
  target_as_of_date date default null,
  target_include_archived boolean default false
)
returns table (
  entity_type text,
  entity_id uuid,
  organization_id uuid,
  initiative_id uuid,
  parent_action_id uuid,

  code text,
  name text,
  lifecycle_status text,
  priority text,

  organization_timezone text,
  reference_date date,

  baseline_start_date date,
  baseline_end_date date,

  current_plan_start_date date,
  current_plan_end_date date,

  forecast_start_date date,
  forecast_end_date date,

  actual_start_date date,
  actual_end_date date,

  current_plan_start_variance_vs_baseline_days integer,
  current_plan_end_variance_vs_baseline_days integer,
  forecast_start_variance_vs_current_plan_days integer,
  forecast_end_variance_vs_current_plan_days integer,
  actual_start_variance_vs_current_plan_days integer,
  actual_end_variance_vs_current_plan_days integer,

  is_start_overdue boolean,
  days_start_overdue integer,
  is_completion_overdue boolean,
  days_completion_overdue integer,

  temporal_state text,
  temporal_data_quality_state text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organizacao.'
      using errcode = '22023';
  end if;

  if not public.can_read_organization(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar a projecao temporal desta organizacao.'
      using errcode = '42501';
  end if;

  if target_initiative_id is not null
     and not exists (
       select 1
       from public.sparks_initiatives si0
       where si0.id = target_initiative_id
         and si0.organization_id = target_organization_id
     ) then
    raise exception
      'Iniciativa nao pertence a organizacao informada.'
      using errcode = '22023';
  end if;

  return query
  with org_context as (
    select
      o.id as organization_id,
      coalesce(nullif(trim(o.timezone_name), ''), 'UTC') as organization_timezone,
      coalesce(
        target_as_of_date,
        timezone(
          coalesce(nullif(trim(o.timezone_name), ''), 'UTC'),
          now()
        )::date
      ) as reference_date
    from public.organizations o
    where o.id = target_organization_id
  ),
  raw_entities as (
    select
      'initiative'::text as entity_type,
      si.id as entity_id,
      si.organization_id,
      si.id as initiative_id,
      null::uuid as parent_action_id,

      si.code,
      si.name,
      si.status as lifecycle_status,
      si.priority,

      oc.organization_timezone,
      oc.reference_date,

      si.baseline_start_date,
      si.baseline_target_end_date as baseline_end_date,

      si.start_date as current_plan_start_date,
      si.target_end_date as current_plan_end_date,

      si.forecast_start_date,
      si.forecast_end_date,

      timezone(oc.organization_timezone, si.started_at)::date as actual_start_date,
      timezone(oc.organization_timezone, si.completed_at)::date as actual_end_date,

      si.archived_at
    from public.sparks_initiatives si
    join org_context oc
      on oc.organization_id = si.organization_id
    where si.organization_id = target_organization_id
      and (
        target_initiative_id is null
        or si.id = target_initiative_id
      )
      and (
        target_include_archived
        or si.archived_at is null
      )

    union all

    select
      'action'::text as entity_type,
      a.id as entity_id,
      a.organization_id,
      a.initiative_id,
      a.parent_action_id,

      a.code,
      a.name,
      a.status as lifecycle_status,
      a.priority,

      oc.organization_timezone,
      oc.reference_date,

      a.baseline_start_date,
      a.baseline_due_date as baseline_end_date,

      a.planned_start_date as current_plan_start_date,
      a.planned_due_date as current_plan_end_date,

      a.forecast_start_date,
      a.forecast_due_date as forecast_end_date,

      timezone(oc.organization_timezone, a.started_at)::date as actual_start_date,
      timezone(oc.organization_timezone, a.completed_at)::date as actual_end_date,

      a.archived_at
    from public.sparks_initiative_actions a
    join public.sparks_initiatives si
      on si.id = a.initiative_id
     and si.organization_id = a.organization_id
    join org_context oc
      on oc.organization_id = a.organization_id
    where a.organization_id = target_organization_id
      and (
        target_initiative_id is null
        or a.initiative_id = target_initiative_id
      )
      and (
        target_include_archived
        or (
          a.archived_at is null
          and si.archived_at is null
        )
      )
  ),
  derived as (
    select
      r.*,

      case
        when r.current_plan_start_date is not null
         and r.baseline_start_date is not null
          then (r.current_plan_start_date - r.baseline_start_date)::integer
        else null
      end as current_plan_start_variance_vs_baseline_days,

      case
        when r.current_plan_end_date is not null
         and r.baseline_end_date is not null
          then (r.current_plan_end_date - r.baseline_end_date)::integer
        else null
      end as current_plan_end_variance_vs_baseline_days,

      case
        when r.forecast_start_date is not null
         and r.current_plan_start_date is not null
          then (r.forecast_start_date - r.current_plan_start_date)::integer
        else null
      end as forecast_start_variance_vs_current_plan_days,

      case
        when r.forecast_end_date is not null
         and r.current_plan_end_date is not null
          then (r.forecast_end_date - r.current_plan_end_date)::integer
        else null
      end as forecast_end_variance_vs_current_plan_days,

      case
        when r.actual_start_date is not null
         and r.current_plan_start_date is not null
          then (r.actual_start_date - r.current_plan_start_date)::integer
        else null
      end as actual_start_variance_vs_current_plan_days,

      case
        when r.actual_end_date is not null
         and r.current_plan_end_date is not null
          then (r.actual_end_date - r.current_plan_end_date)::integer
        else null
      end as actual_end_variance_vs_current_plan_days,

      (
        r.actual_start_date is null
        and r.lifecycle_status in (
          'approved',
          'planned'
        )
        and r.current_plan_start_date is not null
        and r.reference_date > r.current_plan_start_date
      ) as is_start_overdue,

      case
        when r.actual_start_date is null
         and r.lifecycle_status in (
           'approved',
           'planned'
         )
         and r.current_plan_start_date is not null
         and r.reference_date > r.current_plan_start_date
          then (r.reference_date - r.current_plan_start_date)::integer
        else 0
      end as days_start_overdue,

      (
        r.actual_end_date is null
        and r.lifecycle_status in (
          'in_progress',
          'on_hold',
          'blocked'
        )
        and r.current_plan_end_date is not null
        and r.reference_date > r.current_plan_end_date
      ) as is_completion_overdue,

      case
        when r.actual_end_date is null
         and r.lifecycle_status in (
           'in_progress',
           'on_hold',
           'blocked'
         )
         and r.current_plan_end_date is not null
         and r.reference_date > r.current_plan_end_date
          then (r.reference_date - r.current_plan_end_date)::integer
        else 0
      end as days_completion_overdue,

      case
        when r.lifecycle_status in (
          'in_progress',
          'on_hold',
          'blocked',
          'completed'
        )
        and r.actual_start_date is null
        and r.lifecycle_status = 'completed'
        and r.actual_end_date is null
          then 'actual_start_and_end_unknown'
        when r.lifecycle_status in (
          'in_progress',
          'on_hold',
          'blocked',
          'completed'
        )
        and r.actual_start_date is null
          then 'actual_start_unknown'
        when r.lifecycle_status = 'completed'
         and r.actual_end_date is null
          then 'actual_end_unknown'
        else 'ok'
      end as temporal_data_quality_state

    from raw_entities r
  )
  select
    d.entity_type,
    d.entity_id,
    d.organization_id,
    d.initiative_id,
    d.parent_action_id,

    d.code,
    d.name,
    d.lifecycle_status,
    d.priority,

    d.organization_timezone,
    d.reference_date,

    d.baseline_start_date,
    d.baseline_end_date,

    d.current_plan_start_date,
    d.current_plan_end_date,

    d.forecast_start_date,
    d.forecast_end_date,

    d.actual_start_date,
    d.actual_end_date,

    d.current_plan_start_variance_vs_baseline_days,
    d.current_plan_end_variance_vs_baseline_days,
    d.forecast_start_variance_vs_current_plan_days,
    d.forecast_end_variance_vs_current_plan_days,
    d.actual_start_variance_vs_current_plan_days,
    d.actual_end_variance_vs_current_plan_days,

    d.is_start_overdue,
    d.days_start_overdue,
    d.is_completion_overdue,
    d.days_completion_overdue,

    case
      when d.lifecycle_status = 'archived'
        or d.archived_at is not null
        then 'archived'
      when d.lifecycle_status = 'cancelled'
        then 'cancelled'
      when d.current_plan_start_date is null
        or d.current_plan_end_date is null
        then 'unscheduled'
      when d.lifecycle_status = 'completed'
       and d.actual_end_date is not null
       and d.actual_end_date <= d.current_plan_end_date
        then 'completed_on_time'
      when d.lifecycle_status = 'completed'
       and d.actual_end_date is not null
       and d.actual_end_date > d.current_plan_end_date
        then 'completed_late'
      when d.lifecycle_status = 'completed'
       and d.actual_end_date is null
        then null
      when d.is_completion_overdue
        then 'completion_overdue'
      when d.is_start_overdue
        then 'start_overdue'
      else 'on_schedule'
    end as temporal_state,

    d.temporal_data_quality_state

  from derived d
  order by
    case d.entity_type
      when 'initiative' then 0
      else 1
    end,
    d.initiative_id,
    d.parent_action_id nulls first,
    d.current_plan_start_date nulls last,
    d.current_plan_end_date nulls last,
    d.code;
end;
$function$;

revoke all
on function public.get_sparks_initiative_temporal_projection(
  uuid, uuid, date, boolean
)
from public, anon, authenticated;

grant execute
on function public.get_sparks_initiative_temporal_projection(
  uuid, uuid, date, boolean
)
to authenticated, service_role;

comment on function public.get_sparks_initiative_temporal_projection(
  uuid, uuid, date, boolean
) is
  'Projeta temporalidade transversal read-only de iniciativas e acoes. '
  'Deriva baseline, plano vigente, forecast, realizado, variancias, atraso, '
  'estado temporal e qualidade de dado sem persistir Gantt ou status de atraso.';

commit;