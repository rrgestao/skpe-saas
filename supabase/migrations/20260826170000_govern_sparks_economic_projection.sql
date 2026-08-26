-- 17-B.5F.3C.6J-S5B - Governed Economic Projection
-- Read-only projection. No automatic parent mutation. No FX conversion.
-- Child costs aggregate only by currency_code.
-- Child effort aggregates only by effort_unit.

create or replace function public.get_sparks_initiative_economic_projection(
  target_organization_id uuid,
  target_initiative_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_initiative public.sparks_initiatives%rowtype;
  v_cost_by_currency jsonb := '[]'::jsonb;
  v_effort_by_unit jsonb := '[]'::jsonb;
  v_action_counts jsonb := '{}'::jsonb;
  v_data_quality jsonb := '{}'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organizacao.'
      using errcode = '22023';
  end if;

  if target_initiative_id is null then
    raise exception 'Informe a iniciativa.'
      using errcode = '22023';
  end if;

  if not public.can_read_organization(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar a projecao economica desta organizacao.'
      using errcode = '42501';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = target_initiative_id
    and organization_id = target_organization_id;

  if v_initiative.id is null then
    raise exception 'Iniciativa nao encontrada na organizacao informada.'
      using errcode = '22023';
  end if;

  with cost_rows as (
    select
      a.currency_code,
      coalesce(
        sum(a.planned_cost) filter (
          where a.status not in ('cancelled', 'archived')
            and a.archived_at is null
        ),
        0
      ) as current_planned_cost,
      coalesce(sum(a.actual_cost), 0) as actual_realized_cost,
      coalesce(
        sum(a.planned_cost) filter (
          where a.status = 'cancelled'
            and a.archived_at is null
        ),
        0
      ) as cancelled_planned_cost,
      coalesce(
        sum(a.planned_cost) filter (
          where a.status = 'archived'
             or a.archived_at is not null
        ),
        0
      ) as archived_planned_cost
    from public.sparks_initiative_actions a
    where a.organization_id = target_organization_id
      and a.initiative_id = target_initiative_id
      and a.currency_code is not null
      and (
        a.planned_cost is not null
        or a.actual_cost is not null
      )
    group by a.currency_code
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'currencyCode', c.currency_code,
        'currentPlannedCost', c.current_planned_cost,
        'actualRealizedCost', c.actual_realized_cost,
        'currentPlanVariance', c.actual_realized_cost - c.current_planned_cost,
        'cancelledPlannedCost', c.cancelled_planned_cost,
        'archivedPlannedCost', c.archived_planned_cost
      )
      order by c.currency_code
    ),
    '[]'::jsonb
  )
    into v_cost_by_currency
  from cost_rows c;

  with effort_rows as (
    select
      a.effort_unit,
      coalesce(
        sum(a.estimated_effort) filter (
          where a.status not in ('cancelled', 'archived')
            and a.archived_at is null
        ),
        0
      ) as current_estimated_effort,
      coalesce(sum(a.actual_effort), 0) as actual_realized_effort,
      coalesce(
        sum(a.estimated_effort) filter (
          where a.status = 'cancelled'
            and a.archived_at is null
        ),
        0
      ) as cancelled_estimated_effort,
      coalesce(
        sum(a.estimated_effort) filter (
          where a.status = 'archived'
             or a.archived_at is not null
        ),
        0
      ) as archived_estimated_effort
    from public.sparks_initiative_actions a
    where a.organization_id = target_organization_id
      and a.initiative_id = target_initiative_id
      and a.effort_unit is not null
      and (
        a.estimated_effort is not null
        or a.actual_effort is not null
      )
    group by a.effort_unit
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'effortUnit', e.effort_unit,
        'currentEstimatedEffort', e.current_estimated_effort,
        'actualRealizedEffort', e.actual_realized_effort,
        'currentPlanVariance', e.actual_realized_effort - e.current_estimated_effort,
        'cancelledEstimatedEffort', e.cancelled_estimated_effort,
        'archivedEstimatedEffort', e.archived_estimated_effort
      )
      order by e.effort_unit
    ),
    '[]'::jsonb
  )
    into v_effort_by_unit
  from effort_rows e;

  select jsonb_build_object(
    'total', count(*),
    'currentPlan', count(*) filter (
      where a.status not in ('cancelled', 'archived')
        and a.archived_at is null
    ),
    'cancelled', count(*) filter (
      where a.status = 'cancelled'
        and a.archived_at is null
    ),
    'archived', count(*) filter (
      where a.status = 'archived'
         or a.archived_at is not null
    )
  )
    into v_action_counts
  from public.sparks_initiative_actions a
  where a.organization_id = target_organization_id
    and a.initiative_id = target_initiative_id;

  select jsonb_build_object(
    'actionsWithCostWithoutCurrency', count(*) filter (
      where (a.planned_cost is not null or a.actual_cost is not null)
        and a.currency_code is null
    ),
    'actionsWithEffortWithoutUnit', count(*) filter (
      where (a.estimated_effort is not null or a.actual_effort is not null)
        and a.effort_unit is null
    )
  )
    into v_data_quality
  from public.sparks_initiative_actions a
  where a.organization_id = target_organization_id
    and a.initiative_id = target_initiative_id;

  return jsonb_build_object(
    'initiative',
    jsonb_build_object(
      'initiativeId', v_initiative.id,
      'organizationId', v_initiative.organization_id,
      'code', v_initiative.code,
      'name', v_initiative.name,
      'lifecycleStatus', v_initiative.status,
      'direct',
      jsonb_build_object(
        'plannedCost', v_initiative.planned_cost,
        'actualCost', v_initiative.actual_cost,
        'currencyCode', v_initiative.currency_code,
        'costVariance',
          case
            when v_initiative.planned_cost is not null
             and v_initiative.actual_cost is not null
              then v_initiative.actual_cost - v_initiative.planned_cost
            else null
          end,
        'estimatedEffort', v_initiative.estimated_effort,
        'actualEffort', v_initiative.actual_effort,
        'effortUnit', v_initiative.effort_unit,
        'effortVariance',
          case
            when v_initiative.estimated_effort is not null
             and v_initiative.actual_effort is not null
             and v_initiative.effort_unit is not null
              then v_initiative.actual_effort - v_initiative.estimated_effort
            else null
          end,
        'resourceEstimate', v_initiative.resource_estimate
      )
    ),
    'actions',
    jsonb_build_object(
      'counts', v_action_counts,
      'costByCurrency', v_cost_by_currency,
      'effortByUnit', v_effort_by_unit,
      'dataQuality', v_data_quality
    ),
    'governance',
    jsonb_build_object(
      'automaticInitiativeMutation', false,
      'mixedCurrencyAggregation', false,
      'mixedEffortUnitAggregation', false,
      'fxConversion', false,
      'plannedValuesForCancelledAndArchivedExcludedFromCurrentPlan', true,
      'realizedValuesPreservedAcrossLifecycle', true,
      'resourceEstimateIsQualitative', true
    )
  );
end;
$$;

revoke all on function public.get_sparks_initiative_economic_projection(uuid, uuid) from public;
revoke all on function public.get_sparks_initiative_economic_projection(uuid, uuid) from anon;

grant execute on function public.get_sparks_initiative_economic_projection(uuid, uuid) to authenticated;
grant execute on function public.get_sparks_initiative_economic_projection(uuid, uuid) to service_role;

comment on function public.get_sparks_initiative_economic_projection(uuid, uuid) is
  'Read-only governed economic projection for one SPARKs initiative. Direct initiative values remain authoritative and independent from child-derived aggregates.';
