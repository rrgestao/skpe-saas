begin;

-- ============================================================
-- FE-09.A.11 — MINHAS DECISÕES
-- Consulta pessoal e somente leitura das decisões de governança
-- atribuídas ao usuário autenticado no SK-PE.
--
-- Fontes canônicas:
-- - skpe_governance_decisions
-- - skpe_strategy_reviews
-- - skpe_strategy_review_items
-- - skpe_monitoring_cycles
--
-- A responsabilidade pessoal segue a mesma regra da FE-09.A.07:
-- responsible_user_id = auth.uid()
-- ============================================================

create or replace function public.get_my_skpe_decisions(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_formulation_id uuid default null
)
returns table (
  decision_id uuid,
  organization_id uuid,
  project_id uuid,
  formulation_id uuid,

  formulation_version_number integer,
  formulation_version_label text,
  formulation_status text,

  code text,
  title text,
  decision_text text,
  rationale text,
  decision_type text,
  priority text,
  responsible_user_id uuid,
  due_date date,
  status text,
  escalation_level text,

  days_until_due integer,
  overdue boolean,
  due_soon boolean,
  blocked boolean,

  completed_at timestamptz,
  completion_notes text,
  ratified_at timestamptz,
  ratified_by uuid,
  is_ratified boolean,

  strategy_review_id uuid,
  review_code text,
  review_title text,
  review_type text,
  review_status text,
  review_scheduled_at timestamptz,
  review_held_at timestamptz,
  review_ratified_at timestamptz,

  monitoring_cycle_id uuid,
  cycle_code text,
  cycle_name text,
  cycle_type text,
  cycle_period_start date,
  cycle_period_end date,
  cycle_status text,

  strategy_review_item_id uuid,
  review_item_entity_type text,
  review_item_performance_status text,
  review_item_finding_type text,
  review_item_analysis_text text,
  review_item_root_cause text,
  review_item_recommendation text,
  review_item_requires_decision boolean,
  review_item_status text,

  strategic_theme_id uuid,
  strategic_objective_id uuid,
  indicator_id uuid,
  okr_id uuid,
  key_result_id uuid,
  initiative_id uuid,
  initiative_action_id uuid,
  initiative_risk_id uuid,
  initiative_outcome_id uuid,

  linked_initiative_action_id uuid,
  linked_initiative_action_code text,
  linked_initiative_action_name text,
  linked_initiative_action_status text,
  linked_initiative_action_due_date date,

  created_at timestamptz,
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
$$;

comment on function public.get_my_skpe_decisions(uuid, uuid, uuid) is
  'FE-09.A.11: consulta gerencial somente leitura das decisões de governança atribuídas ao usuário autenticado, com contexto de Formulação, ciclo de monitoramento, RAE, item de análise e ação de iniciativa vinculada.';

revoke all on function public.get_my_skpe_decisions(uuid, uuid, uuid)
from public, anon;

grant execute on function public.get_my_skpe_decisions(uuid, uuid, uuid)
to authenticated, service_role;

commit;
