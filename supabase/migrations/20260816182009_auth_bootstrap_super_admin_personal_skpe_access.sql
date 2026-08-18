-- SK-PE-CONT-01 / AUTH-BOOTSTRAP-01
-- Permite SUPER-ADMIN nas consultas pessoais sem criar membership artificial.

CREATE OR REPLACE FUNCTION public.get_my_skpe_decisions(target_organization_id uuid, target_project_id uuid DEFAULT NULL::uuid, target_formulation_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(decision_id uuid, organization_id uuid, project_id uuid, formulation_id uuid, formulation_version_number integer, formulation_version_label text, formulation_status text, code text, title text, decision_text text, rationale text, decision_type text, priority text, responsible_user_id uuid, due_date date, status text, escalation_level text, days_until_due integer, overdue boolean, due_soon boolean, blocked boolean, completed_at timestamp with time zone, completion_notes text, ratified_at timestamp with time zone, ratified_by uuid, is_ratified boolean, strategy_review_id uuid, review_code text, review_title text, review_type text, review_status text, review_scheduled_at timestamp with time zone, review_held_at timestamp with time zone, review_ratified_at timestamp with time zone, monitoring_cycle_id uuid, cycle_code text, cycle_name text, cycle_type text, cycle_period_start date, cycle_period_end date, cycle_status text, strategy_review_item_id uuid, review_item_entity_type text, review_item_performance_status text, review_item_finding_type text, review_item_analysis_text text, review_item_root_cause text, review_item_recommendation text, review_item_requires_decision boolean, review_item_status text, strategic_theme_id uuid, strategic_objective_id uuid, indicator_id uuid, okr_id uuid, key_result_id uuid, initiative_id uuid, initiative_action_id uuid, initiative_risk_id uuid, initiative_outcome_id uuid, linked_initiative_action_id uuid, linked_initiative_action_code text, linked_initiative_action_name text, linked_initiative_action_status text, linked_initiative_action_due_date date, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar decisões do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    decision.id as decision_id,
    decision.organization_id,
    decision.project_id,
    decision.formulation_id,

    formulation.version_number as formulation_version_number,
    formulation.version_label as formulation_version_label,
    formulation.status as formulation_status,

    decision.code,
    decision.title,
    decision.decision_text,
    decision.rationale,
    decision.decision_type,
    decision.priority,
    decision.responsible_user_id,
    decision.due_date,
    decision.status,
    decision.escalation_level,

    case
      when decision.due_date is null then null
      else (decision.due_date - current_date)
    end::integer as days_until_due,

    (
      decision.status = 'overdue'
      or (
        decision.due_date is not null
        and decision.due_date < current_date
        and decision.status not in ('completed', 'cancelled')
      )
    ) as overdue,

    (
      decision.due_date between current_date and current_date + 7
      and decision.status not in ('completed', 'cancelled')
    ) as due_soon,

    decision.status = 'blocked' as blocked,

    decision.completed_at,
    decision.completion_notes,
    decision.ratified_at,
    decision.ratified_by,
    decision.ratified_at is not null as is_ratified,

    review.id as strategy_review_id,
    review.code as review_code,
    review.title as review_title,
    review.review_type,
    review.status as review_status,
    review.scheduled_at as review_scheduled_at,
    review.held_at as review_held_at,
    review.ratified_at as review_ratified_at,

    cycle.id as monitoring_cycle_id,
    cycle.code as cycle_code,
    cycle.name as cycle_name,
    cycle.cycle_type,
    cycle.period_start as cycle_period_start,
    cycle.period_end as cycle_period_end,
    cycle.status as cycle_status,

    review_item.id as strategy_review_item_id,
    review_item.entity_type as review_item_entity_type,
    review_item.performance_status as review_item_performance_status,
    review_item.finding_type as review_item_finding_type,
    review_item.analysis_text as review_item_analysis_text,
    review_item.root_cause as review_item_root_cause,
    review_item.recommendation as review_item_recommendation,
    review_item.requires_decision as review_item_requires_decision,
    review_item.status as review_item_status,

    review_item.strategic_theme_id,
    review_item.strategic_objective_id,
    review_item.indicator_id,
    review_item.okr_id,
    review_item.key_result_id,
    review_item.initiative_id,
    review_item.initiative_action_id,
    review_item.initiative_risk_id,
    review_item.initiative_outcome_id,

    decision.linked_initiative_action_id,
    linked_action.code as linked_initiative_action_code,
    linked_action.name as linked_initiative_action_name,
    linked_action.status as linked_initiative_action_status,
    linked_action.due_date as linked_initiative_action_due_date,

    decision.created_at,
    decision.updated_at

  from public.skpe_governance_decisions decision

  join public.skpe_strategic_formulations formulation
    on formulation.id = decision.formulation_id

  join public.skpe_strategy_reviews review
    on review.id = decision.strategy_review_id

  join public.skpe_monitoring_cycles cycle
    on cycle.id = review.monitoring_cycle_id

  left join public.skpe_strategy_review_items review_item
    on review_item.id = decision.strategy_review_item_id

  left join public.skpe_initiative_actions linked_action
    on linked_action.id = decision.linked_initiative_action_id

  where decision.organization_id = target_organization_id
    and decision.responsible_user_id = current_user_id
    and (
      target_project_id is null
      or decision.project_id = target_project_id
    )
    and (
      target_formulation_id is null
      or decision.formulation_id = target_formulation_id
    )

  order by
    case
      when decision.status = 'overdue'
        or (
          decision.due_date is not null
          and decision.due_date < current_date
          and decision.status not in ('completed', 'cancelled')
        )
        then 0
      when decision.status = 'blocked' then 1
      when decision.priority = 'critical' then 2
      when decision.priority = 'high' then 3
      when decision.due_date between current_date and current_date + 7
        and decision.status not in ('completed', 'cancelled')
        then 4
      when decision.status = 'in_progress' then 5
      when decision.status = 'open' then 6
      when decision.status = 'completed' then 7
      when decision.status = 'cancelled' then 8
      else 9
    end,
    decision.due_date nulls last,
    review.scheduled_at nulls last,
    decision.title,
    decision.code;
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_my_skpe_indicators(target_organization_id uuid, target_project_id uuid DEFAULT NULL::uuid, target_formulation_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(indicator_id uuid, organization_id uuid, project_id uuid, formulation_id uuid, strategic_objective_id uuid, strategic_objective_code text, strategic_objective_name text, code text, name text, description text, unit text, polarity text, measurement_frequency text, data_source text, baseline_value numeric, baseline_date date, status text, target_id uuid, target_type text, target_value numeric, minimum_value numeric, challenge_value numeric, tolerance_lower numeric, tolerance_upper numeric, target_period_start date, target_period_end date, target_status text, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar indicadores do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    indicator.id as indicator_id,
    indicator.organization_id,
    indicator.project_id,
    indicator.formulation_id,
    indicator.strategic_objective_id,
    objective.code as strategic_objective_code,
    objective.name as strategic_objective_name,
    indicator.code,
    indicator.name,
    indicator.description,
    indicator.unit,
    indicator.polarity,
    indicator.measurement_frequency,
    indicator.data_source,
    indicator.baseline_value,
    indicator.baseline_date,
    indicator.status,
    target.id as target_id,
    target.target_type,
    target.target_value,
    target.minimum_value,
    target.challenge_value,
    target.tolerance_lower,
    target.tolerance_upper,
    target.period_start as target_period_start,
    target.period_end as target_period_end,
    target.status as target_status,
    indicator.updated_at
  from public.skpe_indicators indicator
  join public.skpe_strategic_objectives objective
    on objective.id = indicator.strategic_objective_id
  left join lateral (
    select candidate.*
    from public.skpe_indicator_targets candidate
    where candidate.indicator_id = indicator.id
      and candidate.formulation_id = indicator.formulation_id
      and candidate.status <> 'superseded'
    order by
      case
        when candidate.period_start <= current_date
          and candidate.period_end >= current_date
          then 0
        when candidate.period_end >= current_date
          then 1
        else 2
      end,
      candidate.period_end desc,
      candidate.updated_at desc
    limit 1
  ) target on true
  where indicator.organization_id = target_organization_id
    and indicator.owner_user_id = current_user_id
    and indicator.indicator_scope = 'strategic_kpi'
    and indicator.status <> 'archived'
    and objective.status = 'active'
    and (
      target_project_id is null
      or indicator.project_id = target_project_id
    )
    and (
      target_formulation_id is null
      or indicator.formulation_id = target_formulation_id
    )
  order by
    objective.code,
    indicator.code,
    indicator.name;
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_my_skpe_initiatives(target_organization_id uuid, target_project_id uuid DEFAULT NULL::uuid, target_formulation_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(initiative_id uuid, organization_id uuid, project_id uuid, formulation_id uuid, formulation_version_number integer, formulation_version_label text, formulation_status text, portfolio_item_id uuid, code text, name text, description text, initiative_type text, initiative_class text, responsibility_role text, status text, priority text, criticality text, health_status text, risk_level text, progress numeric, strategic_problem text, strategic_rationale text, strategic_theme text, owner_user_id uuid, backup_owner_user_id uuid, sponsor_user_id uuid, responsible_area_id uuid, responsible_area text, start_date date, due_date date, completed_at timestamp with time zone, days_until_due integer, is_overdue boolean, planned_cost numeric, actual_cost numeric, cost_variance numeric, planned_benefit numeric, realized_benefit numeric, estimated_effort numeric, effort_unit text, resource_estimate text, constraints_text text, currency_code text, estimate_confidence text, proposal_origin text, proposal_source_reference text, validation_status text, what_text text, why_text text, where_text text, when_text text, who_text text, how_text text, how_much_text text, five_w_two_h_completed_fields integer, five_w_two_h_completeness numeric, five_w_two_h_complete boolean, portfolio_selection_status text, portfolio_priority text, portfolio_rank_position integer, portfolio_total_score numeric, portfolio_risk_assessment_status text, portfolio_dependency_assessment_status text, portfolio_capacity_assessment_status text, strategic_objectives jsonb, key_results jsonb, action_count bigint, open_action_count bigint, overdue_action_count bigint, milestone_count bigint, completed_milestone_count bigint, next_action_id uuid, next_action_code text, next_action_name text, next_action_due_date date, next_action_status text, open_risk_count bigint, high_critical_risk_count bigint, maximum_inherent_risk_score integer, outcome_count bigint, achieved_outcome_count bigint, last_update_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar Iniciativas do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    initiative.id as initiative_id,
    initiative.organization_id,
    initiative.project_id,

    portfolio.formulation_id,
    portfolio.formulation_version_number,
    portfolio.formulation_version_label,
    portfolio.formulation_status,
    portfolio.portfolio_item_id,

    initiative.code,
    initiative.name,
    initiative.description,
    initiative.initiative_type,
    initiative.initiative_class,

    case
      when initiative.owner_user_id = current_user_id then 'owner'
      when initiative.backup_owner_user_id = current_user_id then 'backup_owner'
      when initiative.sponsor_user_id = current_user_id then 'sponsor'
      else 'related'
    end as responsibility_role,

    initiative.status,
    initiative.priority,
    initiative.criticality,
    initiative.health_status,
    initiative.risk_level,
    initiative.progress,

    initiative.strategic_problem,
    initiative.strategic_rationale,
    initiative.strategic_theme,

    initiative.owner_user_id,
    initiative.backup_owner_user_id,
    initiative.sponsor_user_id,
    initiative.responsible_area_id,
    initiative.responsible_area,

    initiative.start_date,
    initiative.due_date,
    initiative.completed_at,

    case
      when initiative.due_date is null then null
      else (initiative.due_date - current_date)
    end::integer as days_until_due,

    (
      initiative.due_date is not null
      and initiative.due_date < current_date
      and initiative.status not in (
        'completed',
        'cancelled',
        'archived'
      )
    ) as is_overdue,

    initiative.planned_cost,
    initiative.actual_cost,

    case
      when initiative.planned_cost is null
       and initiative.actual_cost is null then null
      else coalesce(initiative.actual_cost, 0)
         - coalesce(initiative.planned_cost, 0)
    end as cost_variance,

    initiative.planned_benefit,
    initiative.realized_benefit,
    initiative.estimated_effort,
    initiative.effort_unit,
    initiative.resource_estimate,
    initiative.constraints_text,
    initiative.currency_code,
    initiative.estimate_confidence,

    initiative.proposal_origin,
    initiative.proposal_source_reference,
    initiative.validation_status,

    initiative.what_text,
    initiative.why_text,
    initiative.where_text,
    initiative.when_text,
    initiative.who_text,
    initiative.how_text,
    initiative.how_much_text,

    (
      (case when length(trim(coalesce(initiative.what_text, ''))) > 0 then 1 else 0 end)
      + (case when length(trim(coalesce(initiative.why_text, ''))) > 0 then 1 else 0 end)
      + (case when length(trim(coalesce(initiative.where_text, ''))) > 0 then 1 else 0 end)
      + (case when length(trim(coalesce(initiative.when_text, ''))) > 0 then 1 else 0 end)
      + (case when length(trim(coalesce(initiative.who_text, ''))) > 0 then 1 else 0 end)
      + (case when length(trim(coalesce(initiative.how_text, ''))) > 0 then 1 else 0 end)
      + (case when length(trim(coalesce(initiative.how_much_text, ''))) > 0 then 1 else 0 end)
    )::integer as five_w_two_h_completed_fields,

    round(
      (
        (
          (case when length(trim(coalesce(initiative.what_text, ''))) > 0 then 1 else 0 end)
          + (case when length(trim(coalesce(initiative.why_text, ''))) > 0 then 1 else 0 end)
          + (case when length(trim(coalesce(initiative.where_text, ''))) > 0 then 1 else 0 end)
          + (case when length(trim(coalesce(initiative.when_text, ''))) > 0 then 1 else 0 end)
          + (case when length(trim(coalesce(initiative.who_text, ''))) > 0 then 1 else 0 end)
          + (case when length(trim(coalesce(initiative.how_text, ''))) > 0 then 1 else 0 end)
          + (case when length(trim(coalesce(initiative.how_much_text, ''))) > 0 then 1 else 0 end)
        )::numeric
        / 7::numeric
      ) * 100,
      2
    ) as five_w_two_h_completeness,

    (
      length(trim(coalesce(initiative.what_text, ''))) > 0
      and length(trim(coalesce(initiative.why_text, ''))) > 0
      and length(trim(coalesce(initiative.where_text, ''))) > 0
      and length(trim(coalesce(initiative.when_text, ''))) > 0
      and length(trim(coalesce(initiative.who_text, ''))) > 0
      and length(trim(coalesce(initiative.how_text, ''))) > 0
      and length(trim(coalesce(initiative.how_much_text, ''))) > 0
    ) as five_w_two_h_complete,

    portfolio.portfolio_selection_status,
    portfolio.portfolio_priority,
    portfolio.portfolio_rank_position,
    portfolio.portfolio_total_score,
    portfolio.portfolio_risk_assessment_status,
    portfolio.portfolio_dependency_assessment_status,
    portfolio.portfolio_capacity_assessment_status,

    coalesce(strategy.strategic_objectives, '[]'::jsonb)
      as strategic_objectives,

    coalesce(strategy.key_results, '[]'::jsonb)
      as key_results,

    coalesce(actions.action_count, 0)::bigint as action_count,
    coalesce(actions.open_action_count, 0)::bigint as open_action_count,
    coalesce(actions.overdue_action_count, 0)::bigint as overdue_action_count,
    coalesce(actions.milestone_count, 0)::bigint as milestone_count,
    coalesce(actions.completed_milestone_count, 0)::bigint
      as completed_milestone_count,

    next_action.next_action_id,
    next_action.next_action_code,
    next_action.next_action_name,
    next_action.next_action_due_date,
    next_action.next_action_status,

    coalesce(risks.open_risk_count, 0)::bigint as open_risk_count,
    coalesce(risks.high_critical_risk_count, 0)::bigint
      as high_critical_risk_count,
    risks.maximum_inherent_risk_score,

    coalesce(outcomes.outcome_count, 0)::bigint as outcome_count,
    coalesce(outcomes.achieved_outcome_count, 0)::bigint
      as achieved_outcome_count,

    initiative.last_update_at,
    initiative.updated_at

  from public.skpe_initiatives initiative

  left join lateral (
    select
      item.id as portfolio_item_id,
      item.formulation_id,
      formulation.version_number as formulation_version_number,
      formulation.version_label as formulation_version_label,
      formulation.status as formulation_status,
      item.selection_status as portfolio_selection_status,
      item.portfolio_priority,
      item.rank_position as portfolio_rank_position,
      item.total_score as portfolio_total_score,
      item.risk_assessment_status as portfolio_risk_assessment_status,
      item.dependency_assessment_status
        as portfolio_dependency_assessment_status,
      item.capacity_assessment_status
        as portfolio_capacity_assessment_status
    from public.skpe_initiative_portfolio_items item
    join public.skpe_strategic_formulations formulation
      on formulation.id = item.formulation_id
    where item.initiative_id = initiative.id
      and item.organization_id = initiative.organization_id
      and item.project_id = initiative.project_id
      and (
        target_formulation_id is null
        or item.formulation_id = target_formulation_id
      )
      and (
        target_formulation_id is not null
        or formulation.status not in ('superseded', 'archived')
      )
    order by
      case
        when target_formulation_id is not null then 0
        when formulation.status in (
          'draft',
          'in_elaboration',
          'pending_validation',
          'validated',
          'pending_approval'
        ) then 0
        when formulation.status = 'approved' then 1
        else 2
      end,
      formulation.version_number desc
    limit 1
  ) portfolio on true

  left join lateral (
    select
      coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'id', objective.id,
            'code', objective.code,
            'name', objective.name,
            'contributionType', objective_link.contribution_type,
            'contributionWeight', objective_link.contribution_weight,
            'notes', objective_link.notes
          )
          order by objective.code, objective.name
        )
        from public.skpe_initiative_objectives objective_link
        join public.skpe_strategic_objectives objective
          on objective.id = objective_link.strategic_objective_id
        where objective_link.initiative_id = initiative.id
          and (
            portfolio.formulation_id is null
            or objective_link.formulation_id = portfolio.formulation_id
          )
      ), '[]'::jsonb) as strategic_objectives,

      coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'id', kr.id,
            'code', kr.code,
            'name', kr.name,
            'okrId', kr.okr_id,
            'contributionType', kr_link.contribution_type,
            'contributionWeight', kr_link.contribution_weight,
            'notes', kr_link.notes
          )
          order by kr.code, kr.name
        )
        from public.skpe_initiative_key_results kr_link
        join public.skpe_key_results kr
          on kr.id = kr_link.key_result_id
        where kr_link.initiative_id = initiative.id
          and (
            portfolio.formulation_id is null
            or kr_link.formulation_id = portfolio.formulation_id
          )
          and kr.status <> 'cancelled'
      ), '[]'::jsonb) as key_results
  ) strategy on true

  left join lateral (
    select
      count(*) filter (
        where action.status not in ('cancelled', 'archived')
      ) as action_count,

      count(*) filter (
        where action.status not in (
          'completed',
          'cancelled',
          'archived'
        )
      ) as open_action_count,

      count(*) filter (
        where action.due_date < current_date
          and action.status not in (
            'completed',
            'cancelled',
            'archived'
          )
      ) as overdue_action_count,

      count(*) filter (
        where action.action_type = 'milestone'
          and action.status not in ('cancelled', 'archived')
      ) as milestone_count,

      count(*) filter (
        where action.action_type = 'milestone'
          and action.status = 'completed'
      ) as completed_milestone_count

    from public.skpe_initiative_actions action
    where action.initiative_id = initiative.id
      and action.archived_at is null
  ) actions on true

  left join lateral (
    select
      action.id as next_action_id,
      action.code as next_action_code,
      action.name as next_action_name,
      action.due_date as next_action_due_date,
      action.status as next_action_status
    from public.skpe_initiative_actions action
    where action.initiative_id = initiative.id
      and action.archived_at is null
      and action.status not in (
        'completed',
        'cancelled',
        'archived'
      )
    order by
      action.due_date nulls last,
      action.display_order,
      action.code,
      action.name
    limit 1
  ) next_action on true

  left join lateral (
    select
      count(*) filter (
        where risk.status not in ('closed', 'archived')
      ) as open_risk_count,

      count(*) filter (
        where risk.status not in ('closed', 'archived')
          and (
            risk.inherent_score >= 15
            or risk.residual_score >= 15
          )
      ) as high_critical_risk_count,

      max(
        greatest(
          coalesce(risk.inherent_score, 0),
          coalesce(risk.residual_score, 0)
        )
      )::integer as maximum_inherent_risk_score

    from public.skpe_initiative_risks risk
    where risk.initiative_id = initiative.id
      and risk.archived_at is null
  ) risks on true

  left join lateral (
    select
      count(*) filter (
        where outcome.status not in ('cancelled', 'archived')
      ) as outcome_count,

      count(*) filter (
        where outcome.status = 'achieved'
      ) as achieved_outcome_count

    from public.skpe_initiative_outcomes outcome
    where portfolio.portfolio_item_id is not null
      and outcome.portfolio_item_id = portfolio.portfolio_item_id
  ) outcomes on true

  where initiative.organization_id = target_organization_id
    and initiative.archived_at is null
    and initiative.status not in ('cancelled', 'archived')
    and (
      initiative.owner_user_id = current_user_id
      or initiative.backup_owner_user_id = current_user_id
      or initiative.sponsor_user_id = current_user_id
    )
    and (
      target_project_id is null
      or initiative.project_id = target_project_id
    )
    and (
      target_formulation_id is null
      or portfolio.portfolio_item_id is not null
    )

  order by
    case
      when initiative.health_status = 'critical' then 0
      when initiative.risk_level = 'critical' then 1
      when (
        initiative.due_date is not null
        and initiative.due_date < current_date
        and initiative.status not in ('completed', 'cancelled', 'archived')
      ) then 2
      when initiative.health_status = 'attention' then 3
      when initiative.risk_level = 'high' then 4
      else 5
    end,
    case initiative.status
      when 'blocked' then 0
      when 'in_progress' then 1
      when 'on_hold' then 2
      when 'planned' then 3
      when 'approved' then 4
      when 'under_analysis' then 5
      when 'proposed' then 6
      when 'completed' then 7
      else 8
    end,
    case initiative.priority
      when 'critical' then 0
      when 'high' then 1
      when 'medium' then 2
      when 'low' then 3
      else 4
    end,
    initiative.due_date nulls last,
    initiative.name,
    initiative.code;
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_my_skpe_key_results(target_organization_id uuid, target_project_id uuid DEFAULT NULL::uuid, target_formulation_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(key_result_id uuid, organization_id uuid, project_id uuid, formulation_id uuid, okr_id uuid, okr_code text, okr_title text, strategic_objective_id uuid, strategic_objective_code text, strategic_objective_name text, code text, name text, description text, baseline_value numeric, current_value numeric, target_value numeric, unit text, progress numeric, period_start date, period_end date, status text, validation_status text, contribution_weight numeric, polarity text, measurement_frequency text, data_source text, formula_text text, calculation_method text, range_lower numeric, range_upper numeric, collection_automatable boolean, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar Resultados-Chave do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    kr.id as key_result_id,
    kr.organization_id,
    kr.project_id,
    kr.formulation_id,
    kr.okr_id,
    okr.code as okr_code,
    okr.title as okr_title,
    kr.strategic_objective_id,
    objective.code as strategic_objective_code,
    objective.name as strategic_objective_name,
    kr.code,
    kr.name,
    kr.description,
    kr.baseline_value,
    kr.current_value,
    kr.target_value,
    kr.unit,
    kr.progress,
    kr.period_start,
    kr.period_end,
    kr.status,
    kr.validation_status,
    kr.contribution_weight,
    nullif(kr.metadata ->> 'polarity', '') as polarity,
    nullif(kr.metadata ->> 'measurementFrequency', '') as measurement_frequency,
    nullif(kr.metadata ->> 'dataSource', '') as data_source,
    nullif(kr.metadata ->> 'formulaText', '') as formula_text,
    nullif(kr.metadata ->> 'calculationMethod', '') as calculation_method,
    nullif(kr.metadata ->> 'rangeLower', '')::numeric as range_lower,
    nullif(kr.metadata ->> 'rangeUpper', '')::numeric as range_upper,
    nullif(kr.metadata ->> 'collectionAutomatable', '')::boolean
      as collection_automatable,
    kr.updated_at
  from public.skpe_key_results kr
  join public.skpe_okrs okr
    on okr.id = kr.okr_id
  join public.skpe_strategic_objectives objective
    on objective.id = kr.strategic_objective_id
  where kr.organization_id = target_organization_id
    and kr.owner_user_id = current_user_id
    and kr.status <> 'cancelled'
    and okr.status <> 'cancelled'
    and (
      target_project_id is null
      or kr.project_id = target_project_id
    )
    and (
      target_formulation_id is null
      or kr.formulation_id = target_formulation_id
    )
  order by
    case kr.status
      when 'at_risk' then 0
      when 'active' then 1
      when 'draft' then 2
      when 'not_achieved' then 3
      when 'achieved' then 4
      else 5
    end,
    kr.period_end,
    okr.code,
    kr.code,
    kr.name;
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_my_skpe_meetings(target_organization_id uuid, target_project_id uuid DEFAULT NULL::uuid, target_formulation_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(strategy_review_id uuid, organization_id uuid, project_id uuid, formulation_id uuid, formulation_version_number integer, formulation_version_label text, formulation_status text, monitoring_cycle_id uuid, cycle_code text, cycle_name text, cycle_type text, cycle_period_start date, cycle_period_end date, cycle_status text, code text, title text, review_type text, status text, scheduled_at timestamp with time zone, held_at timestamp with time zone, chair_user_id uuid, secretary_user_id uuid, current_user_role text, participants jsonb, participant_count integer, executive_summary text, conclusions text, minutes_reference text, ratified_at timestamp with time zone, ratified_by uuid, is_ratified boolean, is_scheduled boolean, is_today boolean, is_upcoming boolean, is_overdue boolean, days_until_meeting integer, review_item_count integer, open_review_item_count integer, decision_count integer, open_decision_count integer, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar reuniões do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    review.id as strategy_review_id,
    review.organization_id,
    review.project_id,
    review.formulation_id,

    formulation.version_number as formulation_version_number,
    formulation.version_label as formulation_version_label,
    formulation.status as formulation_status,

    cycle.id as monitoring_cycle_id,
    cycle.code as cycle_code,
    cycle.name as cycle_name,
    cycle.cycle_type,
    cycle.period_start as cycle_period_start,
    cycle.period_end as cycle_period_end,
    cycle.status as cycle_status,

    review.code,
    review.title,
    review.review_type,
    review.status,

    review.scheduled_at,
    review.held_at,

    review.chair_user_id,
    review.secretary_user_id,

    case
      when review.chair_user_id = current_user_id
       and review.secretary_user_id = current_user_id
        then 'chair_and_secretary'
      when review.chair_user_id = current_user_id
        then 'chair'
      when review.secretary_user_id = current_user_id
        then 'secretary'
      else 'none'
    end::text as current_user_role,

    review.participants,

    case
      when jsonb_typeof(review.participants) = 'array'
        then jsonb_array_length(review.participants)
      else null
    end::integer as participant_count,

    review.executive_summary,
    review.conclusions,
    review.minutes_reference,

    review.ratified_at,
    review.ratified_by,
    review.ratified_at is not null as is_ratified,

    (
      review.scheduled_at is not null
      and review.status not in ('cancelled', 'closed')
    ) as is_scheduled,

    (
      review.scheduled_at is not null
      and review.scheduled_at::date = current_date
      and review.status not in ('cancelled', 'closed')
    ) as is_today,

    (
      review.scheduled_at is not null
      and review.scheduled_at > now()
      and review.status not in ('cancelled', 'closed')
    ) as is_upcoming,

    (
      review.scheduled_at is not null
      and review.scheduled_at < now()
      and review.held_at is null
      and review.status in ('draft', 'scheduled')
    ) as is_overdue,

    case
      when review.scheduled_at is null then null
      else (review.scheduled_at::date - current_date)
    end::integer as days_until_meeting,

    (
      select count(*)::integer
      from public.skpe_strategy_review_items review_item
      where review_item.strategy_review_id = review.id
    ) as review_item_count,

    (
      select count(*)::integer
      from public.skpe_strategy_review_items review_item
      where review_item.strategy_review_id = review.id
        and review_item.status in ('open', 'analyzed')
    ) as open_review_item_count,

    (
      select count(*)::integer
      from public.skpe_governance_decisions decision
      where decision.strategy_review_id = review.id
    ) as decision_count,

    (
      select count(*)::integer
      from public.skpe_governance_decisions decision
      where decision.strategy_review_id = review.id
        and decision.status not in ('completed', 'cancelled')
    ) as open_decision_count,

    review.created_at,
    review.updated_at

  from public.skpe_strategy_reviews review

  join public.skpe_strategic_formulations formulation
    on formulation.id = review.formulation_id

  join public.skpe_monitoring_cycles cycle
    on cycle.id = review.monitoring_cycle_id

  where review.organization_id = target_organization_id
    and (
      review.chair_user_id = current_user_id
      or review.secretary_user_id = current_user_id
    )
    and (
      target_project_id is null
      or review.project_id = target_project_id
    )
    and (
      target_formulation_id is null
      or review.formulation_id = target_formulation_id
    )

  order by
    case
      when review.status = 'in_progress' then 0
      when review.scheduled_at is not null
       and review.scheduled_at::date = current_date
       and review.status not in ('cancelled', 'closed')
        then 1
      when review.scheduled_at is not null
       and review.scheduled_at < now()
       and review.held_at is null
       and review.status in ('draft', 'scheduled')
        then 2
      when review.scheduled_at is not null
       and review.scheduled_at > now()
       and review.status not in ('cancelled', 'closed')
        then 3
      when review.status = 'pending_ratification' then 4
      when review.status = 'ratified' then 5
      when review.status = 'closed' then 6
      when review.status = 'cancelled' then 7
      else 8
    end,
    case
      when review.scheduled_at >= now() then review.scheduled_at
      else null
    end nulls last,
    review.scheduled_at desc nulls last,
    review.title,
    review.code;

end;
$function$;

CREATE OR REPLACE FUNCTION public.get_my_skpe_notifications(target_organization_id uuid, target_project_id uuid DEFAULT NULL::uuid, target_formulation_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(notification_key text, source_type text, source_id uuid, organization_id uuid, project_id uuid, formulation_id uuid, source_code text, title text, description text, priority text, generated_at timestamp with time zone, due_date date, overdue boolean, due_soon boolean, blocked boolean, normalized_status text, action_recommended text, route_section text, read_at timestamp with time zone, is_read boolean, priority_order integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
    and public.has_module_access(
      target_organization_id,
      'SK-PE'
    )
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar notificações do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    pending.pending_id as notification_key,
    pending.source_type,
    pending.source_id,
    pending.organization_id,
    pending.project_id,
    pending.formulation_id,
    pending.source_code,
    pending.title,
    pending.description,
    pending.priority,

    pending.updated_at as generated_at,

    pending.due_date,
    pending.overdue,
    pending.due_soon,
    pending.blocked,
    pending.normalized_status,

    case
      when pending.blocked then
        'Verifique o bloqueio e defina a ação necessária para liberar o item.'

      when pending.normalized_status = 'overdue' then
        'Regularize o item em atraso ou atualize seu prazo e situação.'

      when pending.normalized_status = 'awaiting_validation' then
        'Revise o item e conclua a validação pendente.'

      when pending.normalized_status = 'due_soon' then
        'Acompanhe o item e conclua as ações necessárias antes do vencimento.'

      when pending.normalized_status = 'in_progress' then
        'Acompanhe a execução e atualize o andamento quando necessário.'

      else
        'Revise o item e defina a próxima ação necessária.'
    end as action_recommended,

    pending.route_section,

    state.read_at,

    state.read_at is not null as is_read,

    pending.priority_order

  from public.get_my_skpe_pending_items(
    target_organization_id,
    target_project_id,
    target_formulation_id
  ) as pending

  left join public.skpe_user_notification_states state
    on state.user_id = current_user_id
   and state.organization_id = pending.organization_id
   and state.notification_key = pending.pending_id

  order by
    case
      when state.read_at is null then 0
      else 1
    end,
    pending.priority_order,
    pending.due_date nulls last,
    pending.updated_at desc,
    pending.title;
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_my_skpe_pending_items(target_organization_id uuid, target_project_id uuid DEFAULT NULL::uuid, target_formulation_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(pending_id text, source_type text, source_id uuid, organization_id uuid, project_id uuid, formulation_id uuid, source_code text, title text, description text, responsibility_type text, original_status text, normalized_status text, priority text, due_date date, overdue boolean, due_soon boolean, blocked boolean, blocking_reason text, route_section text, updated_at timestamp with time zone, priority_order integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
    )
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar pendências do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  with pending_sources as (

    -- ========================================================
    -- 1. ITENS DA JORNADA
    -- ========================================================
    select
      'journey_item:' || item.id::text as pending_id,
      'journey_item'::text as source_type,
      item.id as source_id,
      project.organization_id,
      project.id as project_id,
      target_formulation_id as formulation_id,
      item.code as source_code,
      item.name as title,
      item.description,
      'responsible'::text as responsibility_type,
      item.status as original_status,
      case
        when item.planned_end_date < current_date
          and item.status not in ('completed', 'cancelled')
          then 'overdue'
        when item.blocked or item.status = 'blocked'
          then 'blocked'
        when item.status = 'pending_validation'
          or item.validation_status = 'pending'
          then 'awaiting_validation'
        when item.planned_end_date between current_date and current_date + 7
          then 'due_soon'
        when item.status = 'in_progress'
          then 'in_progress'
        else 'not_started'
      end as normalized_status,
      case
        when item.is_mandatory then 'high'
        else 'medium'
      end as priority,
      item.planned_end_date as due_date,
      (
        item.planned_end_date < current_date
        and item.status not in ('completed', 'cancelled')
      ) as overdue,
      (
        item.planned_end_date between current_date and current_date + 7
        and item.status not in ('completed', 'cancelled')
      ) as due_soon,
      (item.blocked or item.status = 'blocked') as blocked,
      item.blocking_reason,
      'journey'::text as route_section,
      item.updated_at,
      case
        when item.planned_end_date < current_date
          and item.status not in ('completed', 'cancelled') then 10
        when item.blocked or item.status = 'blocked' then 20
        when item.status = 'pending_validation'
          or item.validation_status = 'pending' then 30
        when item.is_mandatory then 40
        when item.planned_end_date between current_date and current_date + 7
          then 50
        else 60
      end as priority_order
    from public.skpe_journey_items item
    join public.skpe_projects project
      on project.id = item.project_id
    where project.organization_id = target_organization_id
      and project.archived_at is null
      and item.archived_at is null
      and item.responsible_user_id = current_user_id
      and item.status not in ('completed', 'cancelled')
      and (
        target_project_id is null
        or project.id = target_project_id
      )

    union all

    -- ========================================================
    -- 2. INICIATIVAS
    -- ========================================================
    select
      'initiative:' || initiative.id::text,
      'initiative'::text,
      initiative.id,
      initiative.organization_id,
      initiative.project_id,
      target_formulation_id,
      initiative.code,
      initiative.name,
      initiative.description,
      'owner'::text,
      initiative.status,
      case
        when initiative.due_date < current_date
          and initiative.status not in (
            'completed', 'cancelled', 'archived'
          )
          then 'overdue'
        when initiative.status = 'blocked'
          then 'blocked'
        when initiative.validation_status in (
          'pending_validation', 'under_review'
        )
          then 'awaiting_validation'
        when initiative.due_date between current_date and current_date + 7
          then 'due_soon'
        when initiative.status = 'in_progress'
          then 'in_progress'
        else 'not_started'
      end,
      initiative.priority,
      initiative.due_date,
      (
        initiative.due_date < current_date
        and initiative.status not in (
          'completed', 'cancelled', 'archived'
        )
      ),
      (
        initiative.due_date between current_date and current_date + 7
        and initiative.status not in (
          'completed', 'cancelled', 'archived'
        )
      ),
      initiative.status = 'blocked',
      case
        when initiative.status = 'blocked'
          then 'Iniciativa bloqueada.'
        else null
      end,
      'initiatives'::text,
      initiative.updated_at,
      case
        when initiative.due_date < current_date
          and initiative.status not in (
            'completed', 'cancelled', 'archived'
          ) then 10
        when initiative.status = 'blocked' then 20
        when initiative.validation_status in (
          'pending_validation', 'under_review'
        ) then 30
        when initiative.priority = 'critical' then 40
        when initiative.priority = 'high' then 45
        when initiative.due_date between current_date and current_date + 7
          then 50
        else 60
      end
    from public.skpe_initiatives initiative
    where initiative.organization_id = target_organization_id
      and initiative.archived_at is null
      and initiative.owner_user_id = current_user_id
      and initiative.status not in (
        'completed', 'cancelled', 'archived'
      )
      and (
        target_project_id is null
        or initiative.project_id = target_project_id
      )

    union all

    -- ========================================================
    -- 3. AÇÕES DAS INICIATIVAS
    -- ========================================================
    select
      'initiative_action:' || action.id::text,
      'initiative_action'::text,
      action.id,
      action.organization_id,
      action.project_id,
      action.origin_formulation_id,
      action.code,
      action.name,
      action.description,
      case
        when action.responsible_user_id = current_user_id
          then 'responsible'
        else 'backup_responsible'
      end,
      action.status,
      case
        when action.due_date < current_date
          and action.status not in (
            'completed', 'cancelled', 'archived'
          )
          then 'overdue'
        when action.status = 'blocked'
          then 'blocked'
        when action.validation_status = 'pending_validation'
          then 'awaiting_validation'
        when action.due_date between current_date and current_date + 7
          then 'due_soon'
        when action.status = 'in_progress'
          then 'in_progress'
        else 'not_started'
      end,
      action.priority,
      action.due_date,
      (
        action.due_date < current_date
        and action.status not in (
          'completed', 'cancelled', 'archived'
        )
      ),
      (
        action.due_date between current_date and current_date + 7
        and action.status not in (
          'completed', 'cancelled', 'archived'
        )
      ),
      action.status = 'blocked',
      case
        when action.status = 'blocked'
          then 'Ação bloqueada.'
        else null
      end,
      'initiatives'::text,
      action.updated_at,
      case
        when action.due_date < current_date
          and action.status not in (
            'completed', 'cancelled', 'archived'
          ) then 10
        when action.status = 'blocked' then 20
        when action.validation_status = 'pending_validation' then 30
        when action.priority = 'critical' then 40
        when action.priority = 'high' then 45
        when action.due_date between current_date and current_date + 7
          then 50
        else 60
      end
    from public.skpe_initiative_actions action
    where action.organization_id = target_organization_id
      and action.archived_at is null
      and (
        action.responsible_user_id = current_user_id
        or action.backup_responsible_user_id = current_user_id
      )
      and action.status not in (
        'completed', 'cancelled', 'archived'
      )
      and (
        target_project_id is null
        or action.project_id = target_project_id
      )
      and (
        target_formulation_id is null
        or action.origin_formulation_id is null
        or action.origin_formulation_id = target_formulation_id
      )

    union all

    -- ========================================================
    -- 4. ITENS DO CHECKLIST DE EVIDÊNCIAS
    -- ========================================================
    select
      'evidence_checklist_item:' || checklist_item.id::text,
      'evidence_checklist_item'::text,
      checklist_item.id,
      checklist.organization_id,
      checklist.project_id,
      target_formulation_id,
      checklist_item.code,
      checklist_item.name,
      checklist_item.description,
      'responsible'::text,
      checklist_item.collection_status,
      case
        when checklist_item.due_date < current_date
          and checklist_item.collection_status not in (
            'received', 'not_applicable', 'closed'
          )
          then 'overdue'
        when checklist_item.collection_status = 'under_review'
          then 'awaiting_validation'
        when checklist_item.due_date
          between current_date and current_date + 7
          then 'due_soon'
        when checklist_item.collection_status in (
          'requested',
          'partially_received',
          'needs_complement'
        )
          then 'in_progress'
        else 'not_started'
      end,
      case
        when checklist_item.is_required then 'high'
        else 'medium'
      end,
      checklist_item.due_date,
      (
        checklist_item.due_date < current_date
        and checklist_item.collection_status not in (
          'received', 'not_applicable', 'closed'
        )
      ),
      (
        checklist_item.due_date
          between current_date and current_date + 7
        and checklist_item.collection_status not in (
          'received', 'not_applicable', 'closed'
        )
      ),
      false,
      null::text,
      'journey'::text,
      checklist_item.updated_at,
      case
        when checklist_item.due_date < current_date
          and checklist_item.collection_status not in (
            'received', 'not_applicable', 'closed'
          ) then 10
        when checklist_item.collection_status = 'under_review'
          then 30
        when checklist_item.is_required then 40
        when checklist_item.due_date
          between current_date and current_date + 7 then 50
        else 60
      end
    from public.skpe_evidence_checklist_items checklist_item
    join public.skpe_evidence_checklists checklist
      on checklist.id = checklist_item.checklist_id
    where checklist.organization_id = target_organization_id
      and checklist.status <> 'archived'
      and checklist_item.responsible_user_id = current_user_id
      and checklist_item.is_applicable
      and checklist_item.collection_status not in (
        'received', 'not_applicable', 'closed'
      )
      and (
        target_project_id is null
        or checklist.project_id = target_project_id
      )

    union all

    -- ========================================================
    -- 5. DECISÕES DE GOVERNANÇA
    -- ========================================================
    select
      'governance_decision:' || decision.id::text,
      'governance_decision'::text,
      decision.id,
      decision.organization_id,
      decision.project_id,
      decision.formulation_id,
      decision.code,
      decision.title,
      decision.decision_text,
      'responsible'::text,
      decision.status,
      case
        when decision.status = 'overdue'
          or (
            decision.due_date < current_date
            and decision.status not in ('completed', 'cancelled')
          )
          then 'overdue'
        when decision.status = 'blocked'
          then 'blocked'
        when decision.due_date between current_date and current_date + 7
          then 'due_soon'
        when decision.status = 'in_progress'
          then 'in_progress'
        else 'not_started'
      end,
      decision.priority,
      decision.due_date,
      (
        decision.status = 'overdue'
        or (
          decision.due_date < current_date
          and decision.status not in ('completed', 'cancelled')
        )
      ),
      (
        decision.due_date between current_date and current_date + 7
        and decision.status not in ('completed', 'cancelled')
      ),
      decision.status = 'blocked',
      case
        when decision.status = 'blocked'
          then decision.rationale
        else null
      end,
      'governance'::text,
      decision.updated_at,
      case
        when decision.status = 'overdue'
          or (
            decision.due_date < current_date
            and decision.status not in ('completed', 'cancelled')
          ) then 10
        when decision.status = 'blocked' then 20
        when decision.priority = 'critical' then 40
        when decision.priority = 'high' then 45
        when decision.due_date between current_date and current_date + 7
          then 50
        else 60
      end
    from public.skpe_governance_decisions decision
    where decision.organization_id = target_organization_id
      and decision.responsible_user_id = current_user_id
      and decision.status not in ('completed', 'cancelled')
      and (
        target_project_id is null
        or decision.project_id = target_project_id
      )
      and (
        target_formulation_id is null
        or decision.formulation_id = target_formulation_id
      )
  )
  select
    source.pending_id,
    source.source_type,
    source.source_id,
    source.organization_id,
    source.project_id,
    source.formulation_id,
    source.source_code,
    source.title,
    source.description,
    source.responsibility_type,
    source.original_status,
    source.normalized_status,
    source.priority,
    source.due_date,
    source.overdue,
    source.due_soon,
    source.blocked,
    source.blocking_reason,
    source.route_section,
    source.updated_at,
    source.priority_order
  from pending_sources source
  order by
    source.priority_order,
    source.due_date nulls last,
    source.updated_at desc,
    source.title;
end;
$function$;

;
