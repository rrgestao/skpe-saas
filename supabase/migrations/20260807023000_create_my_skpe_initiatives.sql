begin;

-- ============================================================
-- FE-09.A.10 — MINHAS INICIATIVAS
-- Consulta pessoal e somente leitura das Iniciativas do SK-PE.
--
-- Escopo pessoal:
-- - Responsável principal;
-- - Responsável substituto;
-- - Patrocinador.
--
-- A consulta consolida sinais gerenciais reais já disponíveis:
-- progresso, prazo, saúde, risco, 5W2H, custos, benefícios,
-- esforço, portfólio, Objetivos Estratégicos — OKRs,
-- Resultados-Chave, ações, marcos, riscos e resultados.
--
-- A evolução posterior da Gestão de Iniciativas poderá acrescentar
-- TAP, estrutura de etapas/entregas, Sprints, Gantt e demais abas
-- sem romper este contrato pessoal.
-- ============================================================

create or replace function public.get_my_skpe_initiatives(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_formulation_id uuid default null
)
returns table (
  initiative_id uuid,
  organization_id uuid,
  project_id uuid,
  formulation_id uuid,
  formulation_version_number integer,
  formulation_version_label text,
  formulation_status text,
  portfolio_item_id uuid,

  code text,
  name text,
  description text,
  initiative_type text,
  initiative_class text,

  responsibility_role text,

  status text,
  priority text,
  criticality text,
  health_status text,
  risk_level text,
  progress numeric,

  strategic_problem text,
  strategic_rationale text,
  strategic_theme text,

  owner_user_id uuid,
  backup_owner_user_id uuid,
  sponsor_user_id uuid,
  responsible_area_id uuid,
  responsible_area text,

  start_date date,
  due_date date,
  completed_at timestamptz,
  days_until_due integer,
  is_overdue boolean,

  planned_cost numeric,
  actual_cost numeric,
  cost_variance numeric,
  planned_benefit numeric,
  realized_benefit numeric,
  estimated_effort numeric,
  effort_unit text,
  resource_estimate text,
  constraints_text text,
  currency_code text,
  estimate_confidence text,

  proposal_origin text,
  proposal_source_reference text,
  validation_status text,

  what_text text,
  why_text text,
  where_text text,
  when_text text,
  who_text text,
  how_text text,
  how_much_text text,
  five_w_two_h_completed_fields integer,
  five_w_two_h_completeness numeric,
  five_w_two_h_complete boolean,

  portfolio_selection_status text,
  portfolio_priority text,
  portfolio_rank_position integer,
  portfolio_total_score numeric,
  portfolio_risk_assessment_status text,
  portfolio_dependency_assessment_status text,
  portfolio_capacity_assessment_status text,

  strategic_objectives jsonb,
  key_results jsonb,

  action_count bigint,
  open_action_count bigint,
  overdue_action_count bigint,
  milestone_count bigint,
  completed_milestone_count bigint,

  next_action_id uuid,
  next_action_code text,
  next_action_name text,
  next_action_due_date date,
  next_action_status text,

  open_risk_count bigint,
  high_critical_risk_count bigint,
  maximum_inherent_risk_score integer,

  outcome_count bigint,
  achieved_outcome_count bigint,

  last_update_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
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
    public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
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
$$;

comment on function public.get_my_skpe_initiatives(uuid, uuid, uuid) is
  'FE-09.A.10: consulta gerencial somente leitura das Iniciativas relacionadas ao usuário autenticado como responsável principal, substituto ou patrocinador, respeitando organização, projeto e Formulação Estratégica.';

revoke all on function public.get_my_skpe_initiatives(uuid, uuid, uuid)
from public, anon;

grant execute on function public.get_my_skpe_initiatives(uuid, uuid, uuid)
to authenticated, service_role;

commit;
