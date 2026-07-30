-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-07 — Iniciativas Estratégicas, Programas, Projetos e
--         Planos de Ação
--
-- Escopo:
-- 1. Reutilização e evolução de skpe_initiatives.
-- 2. Portfólio versionado por Formulação Estratégica.
-- 3. Planos de ação estruturados, dependências, riscos e benefícios.
-- 4. Prontidão, validação, snapshots e contrato consolidado.
-- 5. Segurança por RLS, RPCs auditadas e ausência de DML direto.
--
-- Fora de escopo:
-- - frontend React;
-- - orçamento financeiro detalhado e integração contábil;
-- - gestão completa de recursos, timesheets ou Gantt;
-- - substituição de futuros módulos especializados de riscos/finanças.
-- ============================================================

begin;

-- ============================================================
-- 1. EVOLUÇÃO DA ESTRUTURA MESTRE DE INICIATIVAS
-- ============================================================

alter table public.skpe_initiatives
  add column if not exists initiative_class text,
  add column if not exists strategic_problem text,
  add column if not exists strategic_rationale text,
  add column if not exists criticality text not null default 'medium',
  add column if not exists responsible_area_id uuid
    references public.sparks_domain_values(id) on delete set null,
  add column if not exists backup_owner_user_id uuid
    references public.profiles(id) on delete set null,
  add column if not exists estimated_effort numeric(18,2),
  add column if not exists effort_unit text,
  add column if not exists resource_estimate text,
  add column if not exists currency_code text not null default 'BRL',
  add column if not exists estimate_confidence text not null default 'medium',
  add column if not exists constraints_text text;

update public.skpe_initiatives
set initiative_class = case initiative_type
  when 'strategic_program' then 'program'
  when 'strategic_project' then 'project'
  when 'simple_action' then 'structuring_action'
  else 'initiative'
end
where initiative_class is null;

alter table public.skpe_initiatives
  alter column initiative_class set default 'initiative',
  alter column initiative_class set not null;

alter table public.skpe_initiatives
  drop constraint if exists skpe_initiatives_class_check;
alter table public.skpe_initiatives
  add constraint skpe_initiatives_class_check
  check (initiative_class in (
    'initiative',
    'program',
    'project',
    'structuring_action'
  ));

alter table public.skpe_initiatives
  drop constraint if exists skpe_initiatives_criticality_check;
alter table public.skpe_initiatives
  add constraint skpe_initiatives_criticality_check
  check (criticality in ('low', 'medium', 'high', 'critical'));

alter table public.skpe_initiatives
  drop constraint if exists skpe_initiatives_effort_check;
alter table public.skpe_initiatives
  add constraint skpe_initiatives_effort_check
  check (estimated_effort is null or estimated_effort >= 0);

alter table public.skpe_initiatives
  drop constraint if exists skpe_initiatives_effort_unit_check;
alter table public.skpe_initiatives
  add constraint skpe_initiatives_effort_unit_check
  check (
    effort_unit is null
    or effort_unit in ('hours', 'days', 'weeks', 'months', 'points', 'custom')
  );

alter table public.skpe_initiatives
  drop constraint if exists skpe_initiatives_currency_code_check;
alter table public.skpe_initiatives
  add constraint skpe_initiatives_currency_code_check
  check (currency_code ~ '^[A-Z]{3}$');

alter table public.skpe_initiatives
  drop constraint if exists skpe_initiatives_estimate_confidence_check;
alter table public.skpe_initiatives
  add constraint skpe_initiatives_estimate_confidence_check
  check (estimate_confidence in ('low', 'medium', 'high'));

create unique index if not exists ux_skpe_initiatives_scope_identity
  on public.skpe_initiatives(id, organization_id, project_id);

create index if not exists idx_skpe_initiatives_fe07_class
  on public.skpe_initiatives(
    organization_id,
    project_id,
    initiative_class,
    status,
    criticality
  )
  where archived_at is null;

create index if not exists idx_skpe_initiatives_fe07_parent
  on public.skpe_initiatives(parent_initiative_id)
  where archived_at is null;

comment on column public.skpe_initiatives.initiative_class is
  'Classificação metodológica canônica da FE-07: iniciativa, programa, projeto ou ação estruturante.';
comment on column public.skpe_initiatives.strategic_problem is
  'Problema, oportunidade ou necessidade estratégica endereçada.';
comment on column public.skpe_initiatives.strategic_rationale is
  'Justificativa estratégica da Iniciativa no contexto do Planejamento Estratégico.';
comment on column public.skpe_initiatives.responsible_area_id is
  'Área responsável validada pelo domínio organizacional ORGANIZATIONAL_AREA.';
comment on column public.skpe_initiatives.estimated_effort is
  'Estimativa de esforço de alto nível, sem substituir gestão detalhada de recursos.';

-- ============================================================
-- 2. CABEÇALHO DE GOVERNANÇA DO PACOTE FE-07
-- ============================================================

create table if not exists public.skpe_initiative_packages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  initiative_management_enabled boolean not null default true,
  status text not null default 'in_elaboration',
  owner_required boolean not null default true,
  responsible_area_required boolean not null default true,
  action_plan_required boolean not null default true,
  five_w_two_h_required boolean not null default true,
  outcome_required boolean not null default true,
  success_criterion_required boolean not null default true,
  risk_assessment_required boolean not null default true,
  portfolio_scoring_required boolean not null default true,
  okr_or_key_result_link_recommended boolean not null default true,
  indicator_link_recommended boolean not null default true,
  maximum_selected_initiatives integer not null default 20,
  weight_strategic_value numeric(5,2) not null default 30,
  weight_expected_benefit numeric(5,2) not null default 20,
  weight_urgency numeric(5,2) not null default 15,
  weight_capacity_fit numeric(5,2) not null default 15,
  weight_effort_feasibility numeric(5,2) not null default 10,
  weight_risk_manageability numeric(5,2) not null default 5,
  weight_dependency_manageability numeric(5,2) not null default 5,
  validation_notes text,
  submitted_for_validation_at timestamptz,
  submitted_for_validation_by uuid
    references public.profiles(id) on delete set null,
  validated_at timestamptz,
  validated_by uuid
    references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_initiative_packages_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_packages_status_check
    check (status in (
      'not_applicable',
      'in_elaboration',
      'pending_validation',
      'validated'
    )),
  constraint skpe_initiative_packages_maximum_check
    check (maximum_selected_initiatives between 1 and 500),
  constraint skpe_initiative_packages_weights_range_check
    check (
      weight_strategic_value between 0 and 100
      and weight_expected_benefit between 0 and 100
      and weight_urgency between 0 and 100
      and weight_capacity_fit between 0 and 100
      and weight_effort_feasibility between 0 and 100
      and weight_risk_manageability between 0 and 100
      and weight_dependency_manageability between 0 and 100
    ),
  constraint skpe_initiative_packages_weights_sum_check
    check (
      weight_strategic_value
      + weight_expected_benefit
      + weight_urgency
      + weight_capacity_fit
      + weight_effort_feasibility
      + weight_risk_manageability
      + weight_dependency_manageability = 100
    ),
  constraint skpe_initiative_packages_enabled_status_check
    check (
      (initiative_management_enabled and status <> 'not_applicable')
      or (not initiative_management_enabled and status = 'not_applicable')
    ),
  constraint skpe_initiative_packages_unique
    unique (formulation_id),
  constraint skpe_initiative_packages_scope_identity
    unique (id, formulation_id, organization_id, project_id)
);

comment on table public.skpe_initiative_packages is
  'Configuração, aplicabilidade, prontidão e validação do pacote FE-07 por versão da Formulação Estratégica.';

-- ============================================================
-- 3. PARTICIPAÇÃO DA INICIATIVA NO PORTFÓLIO VERSIONADO
-- ============================================================

create table if not exists public.skpe_initiative_portfolio_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  initiative_id uuid not null,
  selection_status text not null default 'candidate',
  portfolio_priority text not null default 'medium',
  criticality text not null default 'medium',
  rank_position integer,
  decision_reason text,
  constraints_text text,
  strategic_value_score numeric(5,2),
  expected_benefit_score numeric(5,2),
  urgency_score numeric(5,2),
  capacity_fit_score numeric(5,2),
  effort_feasibility_score numeric(5,2),
  risk_manageability_score numeric(5,2),
  dependency_manageability_score numeric(5,2),
  total_score numeric(5,2),
  risk_assessment_status text not null default 'not_assessed',
  risk_assessment_notes text,
  dependency_assessment_status text not null default 'not_assessed',
  dependency_assessment_notes text,
  capacity_assessment_status text not null default 'not_assessed',
  capacity_assessment_notes text,
  validation_status text not null default 'draft',
  selected_at timestamptz,
  selected_by uuid references public.profiles(id) on delete set null,
  validated_snapshot jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_initiative_portfolio_items_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_portfolio_items_initiative_fkey
    foreign key (initiative_id, organization_id, project_id)
    references public.skpe_initiatives(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_portfolio_items_selection_check
    check (selection_status in ('candidate', 'selected', 'deferred', 'excluded')),
  constraint skpe_initiative_portfolio_items_priority_check
    check (portfolio_priority in ('low', 'medium', 'high', 'critical')),
  constraint skpe_initiative_portfolio_items_criticality_check
    check (criticality in ('low', 'medium', 'high', 'critical')),
  constraint skpe_initiative_portfolio_items_rank_check
    check (rank_position is null or rank_position > 0),
  constraint skpe_initiative_portfolio_items_scores_check
    check (
      (strategic_value_score is null or strategic_value_score between 0 and 100)
      and (expected_benefit_score is null or expected_benefit_score between 0 and 100)
      and (urgency_score is null or urgency_score between 0 and 100)
      and (capacity_fit_score is null or capacity_fit_score between 0 and 100)
      and (effort_feasibility_score is null or effort_feasibility_score between 0 and 100)
      and (risk_manageability_score is null or risk_manageability_score between 0 and 100)
      and (dependency_manageability_score is null or dependency_manageability_score between 0 and 100)
      and (total_score is null or total_score between 0 and 100)
    ),
  constraint skpe_initiative_portfolio_items_risk_assessment_check
    check (risk_assessment_status in (
      'not_assessed',
      'no_material_risk',
      'risks_identified'
    )),
  constraint skpe_initiative_portfolio_items_dependency_assessment_check
    check (dependency_assessment_status in (
      'not_assessed',
      'no_material_dependency',
      'dependencies_identified'
    )),
  constraint skpe_initiative_portfolio_items_capacity_assessment_check
    check (capacity_assessment_status in (
      'not_assessed',
      'adequate',
      'constrained',
      'inadequate'
    )),
  constraint skpe_initiative_portfolio_items_validation_check
    check (validation_status in ('draft', 'pending_validation', 'validated')),
  constraint skpe_initiative_portfolio_items_unique
    unique (formulation_id, initiative_id),
  constraint skpe_initiative_portfolio_items_scope_identity
    unique (id, formulation_id, organization_id, project_id)
);

comment on table public.skpe_initiative_portfolio_items is
  'Participação, seleção, priorização e snapshot de uma Iniciativa em uma versão específica da Formulação Estratégica.';

create index if not exists idx_skpe_initiative_packages_scope
  on public.skpe_initiative_packages(
    organization_id,
    project_id,
    formulation_id,
    status
  );

create index if not exists idx_skpe_initiative_portfolio_scope
  on public.skpe_initiative_portfolio_items(
    organization_id,
    project_id,
    formulation_id,
    selection_status,
    portfolio_priority,
    rank_position
  );

create unique index if not exists ux_skpe_initiative_portfolio_rank
  on public.skpe_initiative_portfolio_items(formulation_id, rank_position)
  where rank_position is not null and selection_status = 'selected';

-- ============================================================
-- 4. PLANO DE AÇÃO E MARCOS
-- ============================================================

create table if not exists public.skpe_initiative_actions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  initiative_id uuid not null,
  origin_formulation_id uuid,
  parent_action_id uuid
    references public.skpe_initiative_actions(id) on delete set null,
  code text not null,
  name text not null,
  description text,
  action_type text not null default 'action',
  what_text text,
  why_text text,
  where_text text,
  when_text text,
  who_text text,
  how_text text,
  how_much_text text,
  responsible_user_id uuid
    references public.profiles(id) on delete set null,
  backup_responsible_user_id uuid
    references public.profiles(id) on delete set null,
  responsible_area_id uuid
    references public.sparks_domain_values(id) on delete set null,
  start_date date,
  due_date date,
  completed_at timestamptz,
  status text not null default 'draft',
  priority text not null default 'medium',
  progress numeric(5,2) not null default 0,
  is_required_for_readiness boolean not null default true,
  display_order integer not null default 0,
  estimated_cost numeric(18,2),
  actual_cost numeric(18,2),
  estimated_effort numeric(18,2),
  effort_unit text,
  currency_code text not null default 'BRL',
  validation_status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,

  constraint skpe_initiative_actions_initiative_fkey
    foreign key (initiative_id, organization_id, project_id)
    references public.skpe_initiatives(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_actions_origin_formulation_fkey
    foreign key (origin_formulation_id)
    references public.skpe_strategic_formulations(id)
    on delete set null,
  constraint skpe_initiative_actions_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_initiative_actions_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_initiative_actions_type_check
    check (action_type in ('action', 'milestone')),
  constraint skpe_initiative_actions_status_check
    check (status in (
      'draft',
      'planned',
      'in_progress',
      'blocked',
      'completed',
      'cancelled',
      'archived'
    )),
  constraint skpe_initiative_actions_priority_check
    check (priority in ('low', 'medium', 'high', 'critical')),
  constraint skpe_initiative_actions_progress_check
    check (progress between 0 and 100),
  constraint skpe_initiative_actions_dates_check
    check (due_date is null or start_date is null or due_date >= start_date),
  constraint skpe_initiative_actions_cost_effort_check
    check (
      coalesce(estimated_cost, 0) >= 0
      and coalesce(actual_cost, 0) >= 0
      and coalesce(estimated_effort, 0) >= 0
    ),
  constraint skpe_initiative_actions_effort_unit_check
    check (
      effort_unit is null
      or effort_unit in ('hours', 'days', 'weeks', 'months', 'points', 'custom')
    ),
  constraint skpe_initiative_actions_currency_check
    check (currency_code ~ '^[A-Z]{3}$'),
  constraint skpe_initiative_actions_validation_check
    check (validation_status in ('draft', 'pending_validation', 'validated')),
  constraint skpe_initiative_actions_completion_check
    check (
      status <> 'completed'
      or (progress = 100 and completed_at is not null)
    ),
  constraint skpe_initiative_actions_unique_code
    unique (initiative_id, code)
);

create index if not exists idx_skpe_initiative_actions_scope
  on public.skpe_initiative_actions(
    organization_id,
    project_id,
    initiative_id,
    status,
    due_date
  )
  where archived_at is null;

create index if not exists idx_skpe_initiative_actions_parent
  on public.skpe_initiative_actions(parent_action_id)
  where archived_at is null;

comment on table public.skpe_initiative_actions is
  'Ações e marcos operacionais estruturados da Iniciativa, com 5W2H, responsabilidade, prazo, custo e esforço de alto nível.';

-- ============================================================
-- 5. DEPENDÊNCIAS VERSIONADAS DO PORTFÓLIO
-- ============================================================

create table if not exists public.skpe_initiative_dependencies (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  source_portfolio_item_id uuid not null,
  target_portfolio_item_id uuid not null,
  relation_type text not null,
  criticality text not null default 'medium',
  owner_user_id uuid references public.profiles(id) on delete set null,
  response_plan text,
  status text not null default 'active',
  validation_status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_initiative_dependencies_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_dependencies_source_fkey
    foreign key (
      source_portfolio_item_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_initiative_portfolio_items(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_dependencies_target_fkey
    foreign key (
      target_portfolio_item_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_initiative_portfolio_items(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_dependencies_relation_check
    check (relation_type in ('depends_on', 'precedes', 'enables', 'related_to')),
  constraint skpe_initiative_dependencies_criticality_check
    check (criticality in ('low', 'medium', 'high', 'critical')),
  constraint skpe_initiative_dependencies_status_check
    check (status in ('active', 'managed', 'resolved', 'archived')),
  constraint skpe_initiative_dependencies_validation_check
    check (validation_status in ('draft', 'pending_validation', 'validated')),
  constraint skpe_initiative_dependencies_no_self
    check (source_portfolio_item_id <> target_portfolio_item_id),
  constraint skpe_initiative_dependencies_unique
    unique (source_portfolio_item_id, target_portfolio_item_id, relation_type)
);

create index if not exists idx_skpe_initiative_dependencies_scope
  on public.skpe_initiative_dependencies(
    formulation_id,
    status,
    criticality,
    source_portfolio_item_id,
    target_portfolio_item_id
  );

comment on table public.skpe_initiative_dependencies is
  'Dependências, precedências e relações habilitadoras entre Iniciativas da mesma Formulação Estratégica.';

-- ============================================================
-- 6. RISCOS ESTRATÉGICOS DE ALTO NÍVEL
-- ============================================================

create table if not exists public.skpe_initiative_risks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  initiative_id uuid not null,
  origin_formulation_id uuid,
  code text not null,
  risk_event text not null,
  cause text,
  consequence text,
  probability integer,
  impact integer,
  inherent_score integer generated always as (
    case
      when probability is null or impact is null then null
      else probability * impact
    end
  ) stored,
  response_type text,
  response_plan text,
  owner_user_id uuid references public.profiles(id) on delete set null,
  response_due_date date,
  status text not null default 'identified',
  residual_probability integer,
  residual_impact integer,
  residual_score integer generated always as (
    case
      when residual_probability is null or residual_impact is null then null
      else residual_probability * residual_impact
    end
  ) stored,
  occurred_at timestamptz,
  validation_status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,

  constraint skpe_initiative_risks_initiative_fkey
    foreign key (initiative_id, organization_id, project_id)
    references public.skpe_initiatives(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_risks_origin_formulation_fkey
    foreign key (origin_formulation_id)
    references public.skpe_strategic_formulations(id)
    on delete set null,
  constraint skpe_initiative_risks_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_initiative_risks_event_not_blank
    check (length(trim(risk_event)) > 0),
  constraint skpe_initiative_risks_probability_check
    check (probability is null or probability between 1 and 5),
  constraint skpe_initiative_risks_impact_check
    check (impact is null or impact between 1 and 5),
  constraint skpe_initiative_risks_residual_probability_check
    check (residual_probability is null or residual_probability between 1 and 5),
  constraint skpe_initiative_risks_residual_impact_check
    check (residual_impact is null or residual_impact between 1 and 5),
  constraint skpe_initiative_risks_response_type_check
    check (response_type is null or response_type in ('avoid', 'mitigate', 'transfer', 'accept')),
  constraint skpe_initiative_risks_status_check
    check (status in (
      'identified',
      'assessed',
      'response_planned',
      'monitoring',
      'occurred',
      'closed',
      'archived'
    )),
  constraint skpe_initiative_risks_validation_check
    check (validation_status in ('draft', 'pending_validation', 'validated')),
  constraint skpe_initiative_risks_residual_pair_check
    check (
      (residual_probability is null and residual_impact is null)
      or (residual_probability is not null and residual_impact is not null)
    ),
  constraint skpe_initiative_risks_unique_code
    unique (initiative_id, code)
);

create index if not exists idx_skpe_initiative_risks_scope
  on public.skpe_initiative_risks(
    organization_id,
    project_id,
    initiative_id,
    status,
    inherent_score desc
  )
  where archived_at is null;

comment on table public.skpe_initiative_risks is
  'Riscos estratégicos de alto nível das Iniciativas, sem substituir futuro módulo corporativo especializado.';

-- ============================================================
-- 7. RESULTADOS, BENEFÍCIOS E CRITÉRIOS DE SUCESSO
-- ============================================================

create table if not exists public.skpe_initiative_outcomes (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  portfolio_item_id uuid not null,
  indicator_id uuid references public.skpe_indicators(id) on delete set null,
  code text not null,
  name text not null,
  description text,
  outcome_type text not null,
  measurement_type text not null default 'qualitative',
  baseline_value numeric,
  target_value numeric,
  current_value numeric,
  unit text,
  polarity text,
  acceptance_criteria text,
  due_date date,
  owner_user_id uuid references public.profiles(id) on delete set null,
  status text not null default 'planned',
  validation_status text not null default 'draft',
  realized_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_initiative_outcomes_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_outcomes_portfolio_fkey
    foreign key (
      portfolio_item_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_initiative_portfolio_items(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_initiative_outcomes_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_initiative_outcomes_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_initiative_outcomes_type_check
    check (outcome_type in ('expected_result', 'benefit', 'success_criterion')),
  constraint skpe_initiative_outcomes_measurement_check
    check (measurement_type in ('qualitative', 'quantitative')),
  constraint skpe_initiative_outcomes_polarity_check
    check (
      polarity is null
      or polarity in (
        'higher_is_better',
        'lower_is_better',
        'target_is_better',
        'range_is_better'
      )
    ),
  constraint skpe_initiative_outcomes_status_check
    check (status in (
      'planned',
      'in_progress',
      'achieved',
      'partially_achieved',
      'not_achieved',
      'cancelled',
      'archived'
    )),
  constraint skpe_initiative_outcomes_validation_check
    check (validation_status in ('draft', 'pending_validation', 'validated')),
  constraint skpe_initiative_outcomes_measurement_content_check
    check (
      (
        measurement_type = 'quantitative'
        and target_value is not null
        and length(trim(coalesce(unit, ''))) > 0
      )
      or (
        measurement_type = 'qualitative'
        and length(trim(coalesce(acceptance_criteria, ''))) > 0
      )
    ),
  constraint skpe_initiative_outcomes_unique_code
    unique (portfolio_item_id, code)
);

create index if not exists idx_skpe_initiative_outcomes_scope
  on public.skpe_initiative_outcomes(
    formulation_id,
    portfolio_item_id,
    outcome_type,
    status
  );

create index if not exists idx_skpe_initiative_outcomes_indicator
  on public.skpe_initiative_outcomes(indicator_id)
  where indicator_id is not null;

comment on table public.skpe_initiative_outcomes is
  'Resultados esperados, benefícios e critérios de sucesso versionados por item de portfólio, com vínculo opcional a Indicador Estratégico.';

-- ============================================================
-- 8. EVOLUÇÃO DOS VÍNCULOS ESTRATÉGICOS EXISTENTES
-- ============================================================

alter table public.skpe_initiative_objectives
  add column if not exists organization_id uuid,
  add column if not exists project_id uuid,
  add column if not exists formulation_id uuid,
  add column if not exists portfolio_item_id uuid,
  add column if not exists validation_status text not null default 'draft',
  add column if not exists metadata jsonb not null default '{}'::jsonb;

update public.skpe_initiative_objectives link
set
  organization_id = initiative.organization_id,
  project_id = initiative.project_id
from public.skpe_initiatives initiative
where initiative.id = link.initiative_id
  and (link.organization_id is null or link.project_id is null);

alter table public.skpe_initiative_objectives
  alter column organization_id set not null,
  alter column project_id set not null;

alter table public.skpe_initiative_objectives
  drop constraint if exists skpe_initiative_objectives_validation_check;
alter table public.skpe_initiative_objectives
  add constraint skpe_initiative_objectives_validation_check
  check (validation_status in ('draft', 'pending_validation', 'validated'));

alter table public.skpe_initiative_objectives
  drop constraint if exists skpe_initiative_objectives_scope_fkey;
alter table public.skpe_initiative_objectives
  add constraint skpe_initiative_objectives_scope_fkey
  foreign key (initiative_id, organization_id, project_id)
  references public.skpe_initiatives(id, organization_id, project_id)
  on delete cascade;

alter table public.skpe_initiative_objectives
  drop constraint if exists skpe_initiative_objectives_formulation_fkey;
alter table public.skpe_initiative_objectives
  add constraint skpe_initiative_objectives_formulation_fkey
  foreign key (formulation_id, organization_id, project_id)
  references public.skpe_strategic_formulations(id, organization_id, project_id)
  on delete cascade;

alter table public.skpe_initiative_objectives
  drop constraint if exists skpe_initiative_objectives_portfolio_fkey;
alter table public.skpe_initiative_objectives
  add constraint skpe_initiative_objectives_portfolio_fkey
  foreign key (
    portfolio_item_id,
    formulation_id,
    organization_id,
    project_id
  )
  references public.skpe_initiative_portfolio_items(
    id,
    formulation_id,
    organization_id,
    project_id
  )
  on delete cascade;

create index if not exists idx_skpe_initiative_objectives_fe07
  on public.skpe_initiative_objectives(
    formulation_id,
    portfolio_item_id,
    strategic_objective_id
  )
  where formulation_id is not null;

alter table public.skpe_initiative_key_results
  add column if not exists organization_id uuid,
  add column if not exists project_id uuid,
  add column if not exists formulation_id uuid,
  add column if not exists portfolio_item_id uuid,
  add column if not exists validation_status text not null default 'draft',
  add column if not exists metadata jsonb not null default '{}'::jsonb;

update public.skpe_initiative_key_results link
set
  organization_id = initiative.organization_id,
  project_id = initiative.project_id
from public.skpe_initiatives initiative
where initiative.id = link.initiative_id
  and (link.organization_id is null or link.project_id is null);

alter table public.skpe_initiative_key_results
  alter column organization_id set not null,
  alter column project_id set not null;

alter table public.skpe_initiative_key_results
  drop constraint if exists skpe_initiative_key_results_validation_check;
alter table public.skpe_initiative_key_results
  add constraint skpe_initiative_key_results_validation_check
  check (validation_status in ('draft', 'pending_validation', 'validated'));

alter table public.skpe_initiative_key_results
  drop constraint if exists skpe_initiative_key_results_scope_fkey;
alter table public.skpe_initiative_key_results
  add constraint skpe_initiative_key_results_scope_fkey
  foreign key (initiative_id, organization_id, project_id)
  references public.skpe_initiatives(id, organization_id, project_id)
  on delete cascade;

alter table public.skpe_initiative_key_results
  drop constraint if exists skpe_initiative_key_results_formulation_fkey;
alter table public.skpe_initiative_key_results
  add constraint skpe_initiative_key_results_formulation_fkey
  foreign key (formulation_id, organization_id, project_id)
  references public.skpe_strategic_formulations(id, organization_id, project_id)
  on delete cascade;

alter table public.skpe_initiative_key_results
  drop constraint if exists skpe_initiative_key_results_portfolio_fkey;
alter table public.skpe_initiative_key_results
  add constraint skpe_initiative_key_results_portfolio_fkey
  foreign key (
    portfolio_item_id,
    formulation_id,
    organization_id,
    project_id
  )
  references public.skpe_initiative_portfolio_items(
    id,
    formulation_id,
    organization_id,
    project_id
  )
  on delete cascade;

create index if not exists idx_skpe_initiative_key_results_fe07
  on public.skpe_initiative_key_results(
    formulation_id,
    portfolio_item_id,
    key_result_id
  )
  where formulation_id is not null;

comment on column public.skpe_initiative_objectives.formulation_id is
  'Versão da Formulação à qual pertence o vínculo estratégico. Nulo somente para registros legados anteriores à FE-07.';
comment on column public.skpe_initiative_key_results.formulation_id is
  'Versão da Formulação à qual pertence o vínculo com Resultado-Chave. Nulo somente para registros legados anteriores à FE-07.';

-- ============================================================
-- 9. UPDATED_AT, RLS E POLÍTICAS DE LEITURA
-- ============================================================

drop trigger if exists skpe_initiative_packages_set_updated_at
  on public.skpe_initiative_packages;
create trigger skpe_initiative_packages_set_updated_at
before update on public.skpe_initiative_packages
for each row execute function public.set_updated_at();

drop trigger if exists skpe_initiative_portfolio_items_set_updated_at
  on public.skpe_initiative_portfolio_items;
create trigger skpe_initiative_portfolio_items_set_updated_at
before update on public.skpe_initiative_portfolio_items
for each row execute function public.set_updated_at();

drop trigger if exists skpe_initiative_actions_set_updated_at
  on public.skpe_initiative_actions;
create trigger skpe_initiative_actions_set_updated_at
before update on public.skpe_initiative_actions
for each row execute function public.set_updated_at();

drop trigger if exists skpe_initiative_dependencies_set_updated_at
  on public.skpe_initiative_dependencies;
create trigger skpe_initiative_dependencies_set_updated_at
before update on public.skpe_initiative_dependencies
for each row execute function public.set_updated_at();

drop trigger if exists skpe_initiative_risks_set_updated_at
  on public.skpe_initiative_risks;
create trigger skpe_initiative_risks_set_updated_at
before update on public.skpe_initiative_risks
for each row execute function public.set_updated_at();

drop trigger if exists skpe_initiative_outcomes_set_updated_at
  on public.skpe_initiative_outcomes;
create trigger skpe_initiative_outcomes_set_updated_at
before update on public.skpe_initiative_outcomes
for each row execute function public.set_updated_at();

alter table public.skpe_initiative_packages enable row level security;
alter table public.skpe_initiative_portfolio_items enable row level security;
alter table public.skpe_initiative_actions enable row level security;
alter table public.skpe_initiative_dependencies enable row level security;
alter table public.skpe_initiative_risks enable row level security;
alter table public.skpe_initiative_outcomes enable row level security;

drop policy if exists skpe_initiative_packages_select
  on public.skpe_initiative_packages;
create policy skpe_initiative_packages_select
on public.skpe_initiative_packages
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_initiative_portfolio_items_select
  on public.skpe_initiative_portfolio_items;
create policy skpe_initiative_portfolio_items_select
on public.skpe_initiative_portfolio_items
for select to authenticated
using (
  public.can_view_skpe_formulation(organization_id)
  or public.can_view_skpe_initiatives(organization_id)
);

drop policy if exists skpe_initiative_actions_select
  on public.skpe_initiative_actions;
create policy skpe_initiative_actions_select
on public.skpe_initiative_actions
for select to authenticated
using (public.can_view_skpe_initiatives(organization_id));

drop policy if exists skpe_initiative_dependencies_select
  on public.skpe_initiative_dependencies;
create policy skpe_initiative_dependencies_select
on public.skpe_initiative_dependencies
for select to authenticated
using (
  public.can_view_skpe_formulation(organization_id)
  or public.can_view_skpe_initiatives(organization_id)
);

drop policy if exists skpe_initiative_risks_select
  on public.skpe_initiative_risks;
create policy skpe_initiative_risks_select
on public.skpe_initiative_risks
for select to authenticated
using (public.can_view_skpe_initiatives(organization_id));

drop policy if exists skpe_initiative_outcomes_select
  on public.skpe_initiative_outcomes;
create policy skpe_initiative_outcomes_select
on public.skpe_initiative_outcomes
for select to authenticated
using (
  public.can_view_skpe_formulation(organization_id)
  or public.can_view_skpe_initiatives(organization_id)
);

-- Resíduo legado identificado na inspeção: remove escrita direta.
drop policy if exists skpe_initiative_key_results_manage
  on public.skpe_initiative_key_results;

-- ============================================================
-- 10. FUNÇÕES INTERNAS DE ESCOPO, HIERARQUIA E PONTUAÇÃO
-- ============================================================

create or replace function public.skpe_assert_fe07_responsible_area(
  p_organization_id uuid,
  p_area_id uuid
)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_area_id is null then
    return;
  end if;

  if not exists (
    select 1
    from public.sparks_domain_values area_value
    join public.sparks_domains area_domain
      on area_domain.id = area_value.domain_id
    where area_value.id = p_area_id
      and area_domain.organization_id = p_organization_id
      and area_domain.scope_type = 'organization'
      and area_domain.code = 'ORGANIZATIONAL_AREA'
      and area_value.active
  ) then
    raise exception 'Área responsável inválida ou inativa para a organização.'
      using errcode = '22023';
  end if;
end;
$$;

create or replace function public.skpe_initiative_hierarchy_would_create_cycle(
  p_initiative_id uuid,
  p_parent_initiative_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with recursive ancestors as (
    select initiative.id, initiative.parent_initiative_id
    from public.skpe_initiatives initiative
    where initiative.id = p_parent_initiative_id

    union all

    select parent.id, parent.parent_initiative_id
    from public.skpe_initiatives parent
    join ancestors current_node
      on parent.id = current_node.parent_initiative_id
  )
  select exists (
    select 1
    from ancestors
    where id = p_initiative_id
  );
$$;

create or replace function public.skpe_assert_initiative_hierarchy(
  p_initiative_id uuid,
  p_parent_initiative_id uuid,
  p_organization_id uuid,
  p_project_id uuid,
  p_initiative_class text
)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  parent_row public.skpe_initiatives%rowtype;
begin
  if p_parent_initiative_id is null then
    if p_initiative_class = 'structuring_action' then
      raise exception 'Ação estruturante deve possuir uma Iniciativa ou projeto pai.'
        using errcode = '22023';
    end if;
    return;
  end if;

  if p_parent_initiative_id = p_initiative_id then
    raise exception 'Uma Iniciativa não pode ser pai de si própria.'
      using errcode = '22023';
  end if;

  select *
  into parent_row
  from public.skpe_initiatives
  where id = p_parent_initiative_id
    and archived_at is null;

  if not found then
    raise exception 'Iniciativa pai não encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  if parent_row.organization_id <> p_organization_id
     or parent_row.project_id <> p_project_id then
    raise exception 'Pai e filho devem pertencer à mesma organização e ao mesmo projeto SK-PE.'
      using errcode = '22023';
  end if;

  if p_initiative_class = 'program' then
    raise exception 'Programa não pode ser subordinado a outra Iniciativa.'
      using errcode = '22023';
  end if;

  if parent_row.initiative_class = 'structuring_action' then
    raise exception 'Ação estruturante não pode possuir Iniciativas filhas.'
      using errcode = '22023';
  end if;

  if p_initiative_class = 'project'
     and parent_row.initiative_class <> 'program' then
    raise exception 'Projeto somente pode ser subordinado a um programa.'
      using errcode = '22023';
  end if;

  if p_initiative_class = 'structuring_action'
     and parent_row.initiative_class not in ('initiative', 'project') then
    raise exception 'Ação estruturante deve ser subordinada a uma Iniciativa ou projeto.'
      using errcode = '22023';
  end if;

  if p_initiative_id is not null
     and public.skpe_initiative_hierarchy_would_create_cycle(
       p_initiative_id,
       p_parent_initiative_id
     ) then
    raise exception 'A hierarquia proposta criaria um ciclo.'
      using errcode = '22023';
  end if;
end;
$$;

create or replace function public.skpe_calculate_initiative_portfolio_score(
  p_portfolio_item_id uuid
)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  item_row public.skpe_initiative_portfolio_items%rowtype;
  package_row public.skpe_initiative_packages%rowtype;
  calculated_score numeric;
begin
  select *
  into item_row
  from public.skpe_initiative_portfolio_items
  where id = p_portfolio_item_id;

  if not found then
    raise exception 'Item de portfólio não encontrado.'
      using errcode = '22023';
  end if;

  select *
  into package_row
  from public.skpe_initiative_packages
  where formulation_id = item_row.formulation_id;

  if not found then
    raise exception 'Pacote FE-07 não encontrado.'
      using errcode = '22023';
  end if;

  if item_row.strategic_value_score is null
     or item_row.expected_benefit_score is null
     or item_row.urgency_score is null
     or item_row.capacity_fit_score is null
     or item_row.effort_feasibility_score is null
     or item_row.risk_manageability_score is null
     or item_row.dependency_manageability_score is null then
    return null;
  end if;

  calculated_score := (
    item_row.strategic_value_score * package_row.weight_strategic_value
    + item_row.expected_benefit_score * package_row.weight_expected_benefit
    + item_row.urgency_score * package_row.weight_urgency
    + item_row.capacity_fit_score * package_row.weight_capacity_fit
    + item_row.effort_feasibility_score * package_row.weight_effort_feasibility
    + item_row.risk_manageability_score * package_row.weight_risk_manageability
    + item_row.dependency_manageability_score * package_row.weight_dependency_manageability
  ) / 100;

  return round(calculated_score, 2);
end;
$$;

create or replace function public.skpe_dependency_would_create_cycle(
  p_formulation_id uuid,
  p_source_portfolio_item_id uuid,
  p_target_portfolio_item_id uuid,
  p_excluded_dependency_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with recursive dependency_path as (
    select dependency.target_portfolio_item_id as current_item_id
    from public.skpe_initiative_dependencies dependency
    where dependency.formulation_id = p_formulation_id
      and dependency.source_portfolio_item_id = p_target_portfolio_item_id
      and dependency.relation_type in ('depends_on', 'precedes')
      and dependency.status <> 'archived'
      and (p_excluded_dependency_id is null or dependency.id <> p_excluded_dependency_id)

    union

    select dependency.target_portfolio_item_id
    from public.skpe_initiative_dependencies dependency
    join dependency_path path
      on dependency.source_portfolio_item_id = path.current_item_id
    where dependency.formulation_id = p_formulation_id
      and dependency.relation_type in ('depends_on', 'precedes')
      and dependency.status <> 'archived'
      and (p_excluded_dependency_id is null or dependency.id <> p_excluded_dependency_id)
  )
  select exists (
    select 1
    from dependency_path
    where current_item_id = p_source_portfolio_item_id
  );
$$;

create or replace function public.ensure_skpe_initiative_package(
  p_formulation_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  source_package public.skpe_initiative_packages%rowtype;
  package_id uuid;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  select id
  into package_id
  from public.skpe_initiative_packages
  where formulation_id = p_formulation_id;

  if package_id is not null then
    return package_id;
  end if;

  perform public.skpe_assert_formulation_editable(p_formulation_id);

  if formulation_row.derived_from_formulation_id is not null then
    select *
    into source_package
    from public.skpe_initiative_packages
    where formulation_id = formulation_row.derived_from_formulation_id;
  end if;

  insert into public.skpe_initiative_packages (
    organization_id,
    project_id,
    formulation_id,
    initiative_management_enabled,
    status,
    owner_required,
    responsible_area_required,
    action_plan_required,
    five_w_two_h_required,
    outcome_required,
    success_criterion_required,
    risk_assessment_required,
    portfolio_scoring_required,
    okr_or_key_result_link_recommended,
    indicator_link_recommended,
    maximum_selected_initiatives,
    weight_strategic_value,
    weight_expected_benefit,
    weight_urgency,
    weight_capacity_fit,
    weight_effort_feasibility,
    weight_risk_manageability,
    weight_dependency_manageability,
    metadata,
    created_by,
    updated_by
  )
  values (
    formulation_row.organization_id,
    formulation_row.project_id,
    formulation_row.id,
    coalesce(source_package.initiative_management_enabled, true),
    case
      when coalesce(source_package.initiative_management_enabled, true)
        then 'in_elaboration'
      else 'not_applicable'
    end,
    coalesce(source_package.owner_required, true),
    coalesce(source_package.responsible_area_required, true),
    coalesce(source_package.action_plan_required, true),
    coalesce(source_package.five_w_two_h_required, true),
    coalesce(source_package.outcome_required, true),
    coalesce(source_package.success_criterion_required, true),
    coalesce(source_package.risk_assessment_required, true),
    coalesce(source_package.portfolio_scoring_required, true),
    coalesce(source_package.okr_or_key_result_link_recommended, true),
    coalesce(source_package.indicator_link_recommended, true),
    coalesce(source_package.maximum_selected_initiatives, 20),
    coalesce(source_package.weight_strategic_value, 30),
    coalesce(source_package.weight_expected_benefit, 20),
    coalesce(source_package.weight_urgency, 15),
    coalesce(source_package.weight_capacity_fit, 15),
    coalesce(source_package.weight_effort_feasibility, 10),
    coalesce(source_package.weight_risk_manageability, 5),
    coalesce(source_package.weight_dependency_manageability, 5),
    coalesce(source_package.metadata, '{}'::jsonb)
      || case
        when source_package.id is null then '{}'::jsonb
        else jsonb_build_object(
          'clonedFromInitiativePackageId', source_package.id,
          'clonedFromFormulationId', formulation_row.derived_from_formulation_id
        )
      end,
    auth.uid(),
    auth.uid()
  )
  returning id into package_id;

  if source_package.id is not null
     and source_package.initiative_management_enabled then
    insert into public.skpe_initiative_portfolio_items (
      organization_id,
      project_id,
      formulation_id,
      initiative_id,
      selection_status,
      portfolio_priority,
      criticality,
      rank_position,
      decision_reason,
      constraints_text,
      strategic_value_score,
      expected_benefit_score,
      urgency_score,
      capacity_fit_score,
      effort_feasibility_score,
      risk_manageability_score,
      dependency_manageability_score,
      total_score,
      risk_assessment_status,
      risk_assessment_notes,
      dependency_assessment_status,
      dependency_assessment_notes,
      capacity_assessment_status,
      capacity_assessment_notes,
      validation_status,
      metadata,
      created_by,
      updated_by
    )
    select
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      source_item.initiative_id,
      source_item.selection_status,
      source_item.portfolio_priority,
      source_item.criticality,
      source_item.rank_position,
      source_item.decision_reason,
      source_item.constraints_text,
      source_item.strategic_value_score,
      source_item.expected_benefit_score,
      source_item.urgency_score,
      source_item.capacity_fit_score,
      source_item.effort_feasibility_score,
      source_item.risk_manageability_score,
      source_item.dependency_manageability_score,
      source_item.total_score,
      source_item.risk_assessment_status,
      source_item.risk_assessment_notes,
      source_item.dependency_assessment_status,
      source_item.dependency_assessment_notes,
      source_item.capacity_assessment_status,
      source_item.capacity_assessment_notes,
      'draft',
      coalesce(source_item.metadata, '{}'::jsonb)
        || jsonb_build_object(
          'clonedFromPortfolioItemId', source_item.id,
          'clonedFromFormulationId', formulation_row.derived_from_formulation_id
        ),
      auth.uid(),
      auth.uid()
    from public.skpe_initiative_portfolio_items source_item
    where source_item.formulation_id = formulation_row.derived_from_formulation_id
      and source_item.selection_status <> 'excluded'
    on conflict (formulation_id, initiative_id) do nothing;

    insert into public.skpe_initiative_objectives (
      initiative_id,
      strategic_objective_id,
      contribution_type,
      contribution_weight,
      notes,
      created_by,
      organization_id,
      project_id,
      formulation_id,
      portfolio_item_id,
      validation_status,
      metadata
    )
    select
      target_item.initiative_id,
      target_objective.id,
      source_link.contribution_type,
      source_link.contribution_weight,
      source_link.notes,
      auth.uid(),
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      target_item.id,
      'draft',
      coalesce(source_link.metadata, '{}'::jsonb)
        || jsonb_build_object('clonedFromInitiativeObjective', true)
    from public.skpe_initiative_objectives source_link
    join public.skpe_initiative_portfolio_items source_item
      on source_item.id = source_link.portfolio_item_id
    join public.skpe_strategic_objectives source_objective
      on source_objective.id = source_link.strategic_objective_id
    join public.skpe_initiative_portfolio_items target_item
      on target_item.formulation_id = formulation_row.id
     and target_item.initiative_id = source_item.initiative_id
    join public.skpe_strategic_objectives target_objective
      on target_objective.formulation_id = formulation_row.id
     and target_objective.code = source_objective.code
    where source_link.formulation_id = formulation_row.derived_from_formulation_id
    on conflict (initiative_id, strategic_objective_id) do nothing;

    insert into public.skpe_initiative_key_results (
      initiative_id,
      key_result_id,
      contribution_type,
      contribution_weight,
      notes,
      created_by,
      organization_id,
      project_id,
      formulation_id,
      portfolio_item_id,
      validation_status,
      metadata
    )
    select
      target_item.initiative_id,
      target_kr.id,
      source_link.contribution_type,
      source_link.contribution_weight,
      source_link.notes,
      auth.uid(),
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      target_item.id,
      'draft',
      coalesce(source_link.metadata, '{}'::jsonb)
        || jsonb_build_object('clonedFromInitiativeKeyResult', true)
    from public.skpe_initiative_key_results source_link
    join public.skpe_initiative_portfolio_items source_item
      on source_item.id = source_link.portfolio_item_id
    join public.skpe_key_results source_kr
      on source_kr.id = source_link.key_result_id
    join public.skpe_okrs source_okr
      on source_okr.id = source_kr.okr_id
    join public.skpe_initiative_portfolio_items target_item
      on target_item.formulation_id = formulation_row.id
     and target_item.initiative_id = source_item.initiative_id
    join public.skpe_okrs target_okr
      on target_okr.formulation_id = formulation_row.id
     and target_okr.code = source_okr.code
    join public.skpe_key_results target_kr
      on target_kr.formulation_id = formulation_row.id
     and target_kr.okr_id = target_okr.id
     and target_kr.code = source_kr.code
    where source_link.formulation_id = formulation_row.derived_from_formulation_id
    on conflict (initiative_id, key_result_id) do nothing;

    insert into public.skpe_initiative_outcomes (
      organization_id,
      project_id,
      formulation_id,
      portfolio_item_id,
      indicator_id,
      code,
      name,
      description,
      outcome_type,
      measurement_type,
      baseline_value,
      target_value,
      current_value,
      unit,
      polarity,
      acceptance_criteria,
      due_date,
      owner_user_id,
      status,
      validation_status,
      metadata,
      created_by,
      updated_by
    )
    select
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      target_item.id,
      target_indicator.id,
      source_outcome.code,
      source_outcome.name,
      source_outcome.description,
      source_outcome.outcome_type,
      source_outcome.measurement_type,
      source_outcome.baseline_value,
      source_outcome.target_value,
      source_outcome.baseline_value,
      source_outcome.unit,
      source_outcome.polarity,
      source_outcome.acceptance_criteria,
      source_outcome.due_date,
      source_outcome.owner_user_id,
      'planned',
      'draft',
      coalesce(source_outcome.metadata, '{}'::jsonb)
        || jsonb_build_object('clonedFromOutcomeId', source_outcome.id),
      auth.uid(),
      auth.uid()
    from public.skpe_initiative_outcomes source_outcome
    join public.skpe_initiative_portfolio_items source_item
      on source_item.id = source_outcome.portfolio_item_id
    join public.skpe_initiative_portfolio_items target_item
      on target_item.formulation_id = formulation_row.id
     and target_item.initiative_id = source_item.initiative_id
    left join public.skpe_indicators source_indicator
      on source_indicator.id = source_outcome.indicator_id
    left join public.skpe_indicators target_indicator
      on target_indicator.formulation_id = formulation_row.id
     and target_indicator.code = source_indicator.code
    where source_outcome.formulation_id = formulation_row.derived_from_formulation_id
    on conflict (portfolio_item_id, code) do nothing;

    insert into public.skpe_initiative_dependencies (
      organization_id,
      project_id,
      formulation_id,
      source_portfolio_item_id,
      target_portfolio_item_id,
      relation_type,
      criticality,
      owner_user_id,
      response_plan,
      status,
      validation_status,
      metadata,
      created_by,
      updated_by
    )
    select
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      target_source.id,
      target_target.id,
      source_dependency.relation_type,
      source_dependency.criticality,
      source_dependency.owner_user_id,
      source_dependency.response_plan,
      'active',
      'draft',
      coalesce(source_dependency.metadata, '{}'::jsonb)
        || jsonb_build_object('clonedFromDependencyId', source_dependency.id),
      auth.uid(),
      auth.uid()
    from public.skpe_initiative_dependencies source_dependency
    join public.skpe_initiative_portfolio_items source_source
      on source_source.id = source_dependency.source_portfolio_item_id
    join public.skpe_initiative_portfolio_items source_target
      on source_target.id = source_dependency.target_portfolio_item_id
    join public.skpe_initiative_portfolio_items target_source
      on target_source.formulation_id = formulation_row.id
     and target_source.initiative_id = source_source.initiative_id
    join public.skpe_initiative_portfolio_items target_target
      on target_target.formulation_id = formulation_row.id
     and target_target.initiative_id = source_target.initiative_id
    where source_dependency.formulation_id = formulation_row.derived_from_formulation_id
      and source_dependency.status <> 'archived'
    on conflict (source_portfolio_item_id, target_portfolio_item_id, relation_type)
    do nothing;
  end if;

  return package_id;
end;
$$;

create or replace function public.skpe_invalidate_initiative_package(
  p_formulation_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_status text;
begin
  select status
  into formulation_status
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if formulation_status is null then
    raise exception 'Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if formulation_status not in ('draft', 'in_elaboration') then
    return;
  end if;

  update public.skpe_initiative_packages
  set
    status = case
      when initiative_management_enabled then 'in_elaboration'
      else 'not_applicable'
    end,
    submitted_for_validation_at = null,
    submitted_for_validation_by = null,
    validated_at = null,
    validated_by = null,
    validation_notes = null,
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'lastInvalidationReason', p_reason,
        'lastInvalidatedAt', timezone('utc', now())
      ),
    updated_by = auth.uid()
  where formulation_id = p_formulation_id;

  update public.skpe_initiative_portfolio_items
  set validation_status = 'draft', updated_by = auth.uid()
  where formulation_id = p_formulation_id;

  update public.skpe_initiative_objectives
  set validation_status = 'draft'
  where formulation_id = p_formulation_id;

  update public.skpe_initiative_key_results
  set validation_status = 'draft'
  where formulation_id = p_formulation_id;

  update public.skpe_initiative_outcomes
  set validation_status = 'draft', updated_by = auth.uid()
  where formulation_id = p_formulation_id;

  update public.skpe_initiative_dependencies
  set validation_status = 'draft', updated_by = auth.uid()
  where formulation_id = p_formulation_id;
end;
$$;

create or replace function public.skpe_capture_initiative_validation_snapshot(
  p_portfolio_item_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  item_row public.skpe_initiative_portfolio_items%rowtype;
  initiative_row public.skpe_initiatives%rowtype;
  snapshot jsonb;
begin
  select *
  into item_row
  from public.skpe_initiative_portfolio_items
  where id = p_portfolio_item_id;

  if not found then
    raise exception 'Item de portfólio não encontrado.'
      using errcode = '22023';
  end if;

  select *
  into initiative_row
  from public.skpe_initiatives
  where id = item_row.initiative_id;

  snapshot := jsonb_build_object(
    'capturedAt', timezone('utc', now()),
    'formulationId', item_row.formulation_id,
    'portfolioItem', to_jsonb(item_row) - 'validated_snapshot',
    'initiative', to_jsonb(initiative_row),
    'objectives', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', objective.id,
          'code', objective.code,
          'name', objective.name,
          'contributionType', link.contribution_type,
          'contributionWeight', link.contribution_weight,
          'notes', link.notes
        ) order by objective.code
      )
      from public.skpe_initiative_objectives link
      join public.skpe_strategic_objectives objective
        on objective.id = link.strategic_objective_id
      where link.portfolio_item_id = item_row.id
        and link.formulation_id = item_row.formulation_id
    ), '[]'::jsonb),
    'keyResults', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', kr.id,
          'code', kr.code,
          'name', kr.name,
          'okrId', kr.okr_id,
          'contributionType', link.contribution_type,
          'contributionWeight', link.contribution_weight,
          'notes', link.notes
        ) order by kr.code
      )
      from public.skpe_initiative_key_results link
      join public.skpe_key_results kr
        on kr.id = link.key_result_id
      where link.portfolio_item_id = item_row.id
        and link.formulation_id = item_row.formulation_id
    ), '[]'::jsonb),
    'outcomes', coalesce((
      select jsonb_agg(to_jsonb(outcome) order by outcome.code)
      from public.skpe_initiative_outcomes outcome
      where outcome.portfolio_item_id = item_row.id
        and outcome.status <> 'archived'
    ), '[]'::jsonb),
    'actions', coalesce((
      select jsonb_agg(to_jsonb(action) order by action.display_order, action.code)
      from public.skpe_initiative_actions action
      where action.initiative_id = item_row.initiative_id
        and action.archived_at is null
        and (
          action.origin_formulation_id is null
          or action.origin_formulation_id = item_row.formulation_id
        )
    ), '[]'::jsonb),
    'risks', coalesce((
      select jsonb_agg(to_jsonb(risk) order by risk.inherent_score desc nulls last, risk.code)
      from public.skpe_initiative_risks risk
      where risk.initiative_id = item_row.initiative_id
        and risk.archived_at is null
        and (
          risk.origin_formulation_id is null
          or risk.origin_formulation_id = item_row.formulation_id
        )
    ), '[]'::jsonb),
    'dependencies', coalesce((
      select jsonb_agg(to_jsonb(dependency) order by dependency.created_at)
      from public.skpe_initiative_dependencies dependency
      where dependency.formulation_id = item_row.formulation_id
        and dependency.status <> 'archived'
        and (
          dependency.source_portfolio_item_id = item_row.id
          or dependency.target_portfolio_item_id = item_row.id
        )
    ), '[]'::jsonb)
  );

  return snapshot;
end;
$$;

create or replace function public.skpe_guard_initiative_versioned_operational_content()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_formulation_id uuid;
  formulation_status text;
  structural_old jsonb;
  structural_new jsonb;
begin
  if tg_op = 'DELETE' then
    target_formulation_id := old.formulation_id;
  else
    target_formulation_id := new.formulation_id;
  end if;

  select status
  into formulation_status
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if formulation_status is null then
    raise exception 'Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if formulation_status in ('draft', 'in_elaboration') then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

  if tg_op in ('INSERT', 'DELETE') then
    raise exception 'Conteúdo estrutural da FE-07 está bloqueado na situação "%".', formulation_status
      using errcode = '55000';
  end if;

  if tg_table_name = 'skpe_initiative_outcomes' then
    structural_old := to_jsonb(old)
      - array['current_value', 'status', 'realized_at', 'metadata', 'updated_at', 'updated_by'];
    structural_new := to_jsonb(new)
      - array['current_value', 'status', 'realized_at', 'metadata', 'updated_at', 'updated_by'];
  elsif tg_table_name = 'skpe_initiative_dependencies' then
    structural_old := to_jsonb(old)
      - array['status', 'metadata', 'updated_at', 'updated_by'];
    structural_new := to_jsonb(new)
      - array['status', 'metadata', 'updated_at', 'updated_by'];
  else
    raise exception 'Tabela não suportada pelo guardião operacional da FE-07.'
      using errcode = '55000';
  end if;

  if structural_old <> structural_new then
    raise exception 'Somente campos operacionais podem ser alterados após o bloqueio da Formulação.'
      using errcode = '55000';
  end if;

  return new;
end;
$$;

-- Conteúdo estrutural versionado: utiliza o guardião transversal existente.
drop trigger if exists skpe_initiative_packages_guard_formulation
  on public.skpe_initiative_packages;
create trigger skpe_initiative_packages_guard_formulation
before insert or update or delete on public.skpe_initiative_packages
for each row execute function public.skpe_guard_approved_formulation_content();

drop trigger if exists skpe_initiative_portfolio_guard_formulation
  on public.skpe_initiative_portfolio_items;
create trigger skpe_initiative_portfolio_guard_formulation
before insert or update or delete on public.skpe_initiative_portfolio_items
for each row execute function public.skpe_guard_approved_formulation_content();

drop trigger if exists skpe_initiative_objectives_guard_formulation
  on public.skpe_initiative_objectives;
create trigger skpe_initiative_objectives_guard_formulation
before insert or update or delete on public.skpe_initiative_objectives
for each row execute function public.skpe_guard_approved_formulation_content();

drop trigger if exists skpe_initiative_key_results_guard_formulation
  on public.skpe_initiative_key_results;
create trigger skpe_initiative_key_results_guard_formulation
before insert or update or delete on public.skpe_initiative_key_results
for each row execute function public.skpe_guard_approved_formulation_content();

-- Conteúdo versionado com atualização operacional autorizada.
drop trigger if exists skpe_initiative_outcomes_guard_formulation
  on public.skpe_initiative_outcomes;
create trigger skpe_initiative_outcomes_guard_formulation
before insert or update or delete on public.skpe_initiative_outcomes
for each row execute function public.skpe_guard_initiative_versioned_operational_content();

drop trigger if exists skpe_initiative_dependencies_guard_formulation
  on public.skpe_initiative_dependencies;
create trigger skpe_initiative_dependencies_guard_formulation
before insert or update or delete on public.skpe_initiative_dependencies
for each row execute function public.skpe_guard_initiative_versioned_operational_content();

-- ============================================================
-- 11. PRONTIDÃO METODOLÓGICA
-- ============================================================

create or replace function public.get_skpe_initiatives_readiness(
  p_formulation_id uuid,
  p_include_package_state boolean default true
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_initiative_packages%rowtype;
  blocking_issues jsonb := '[]'::jsonb;
  recommendations jsonb := '[]'::jsonb;
  issue_count integer := 0;
  recommendation_count integer := 0;
  selected_count integer := 0;
  candidate_count integer := 0;
  action_count integer := 0;
  risk_count integer := 0;
  outcome_count integer := 0;
  record_row record;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id)
     and not public.can_view_skpe_initiatives(formulation_row.organization_id) then
    raise exception 'Acesso negado ao pacote FE-07.'
      using errcode = '42501';
  end if;

  select *
  into package_row
  from public.skpe_initiative_packages
  where formulation_id = p_formulation_id;

  if not found then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE07_PACKAGE_MISSING',
      'severity', 'blocking',
      'message', 'O pacote FE-07 ainda não foi configurado para esta Formulação.'
    ));

    return jsonb_build_object(
      'applicability', 'undetermined',
      'packageStatus', null,
      'readyForValidation', false,
      'readyForFormulation', false,
      'blockingIssues', blocking_issues,
      'recommendations', recommendations,
      'metrics', jsonb_build_object(
        'selectedInitiatives', 0,
        'candidateInitiatives', 0,
        'actions', 0,
        'risks', 0,
        'outcomes', 0
      )
    );
  end if;

  if not package_row.initiative_management_enabled then
    return jsonb_build_object(
      'applicability', 'not_applicable',
      'packageStatus', package_row.status,
      'readyForValidation', true,
      'readyForFormulation', true,
      'blockingIssues', '[]'::jsonb,
      'recommendations', '[]'::jsonb,
      'metrics', jsonb_build_object(
        'selectedInitiatives', 0,
        'candidateInitiatives', 0,
        'actions', 0,
        'risks', 0,
        'outcomes', 0
      )
    );
  end if;

  select count(*) filter (where selection_status = 'selected'),
         count(*) filter (where selection_status = 'candidate')
  into selected_count, candidate_count
  from public.skpe_initiative_portfolio_items
  where formulation_id = p_formulation_id;

  select count(*)
  into action_count
  from public.skpe_initiative_actions action
  join public.skpe_initiative_portfolio_items item
    on item.initiative_id = action.initiative_id
   and item.formulation_id = p_formulation_id
  where action.archived_at is null;

  select count(*)
  into risk_count
  from public.skpe_initiative_risks risk
  join public.skpe_initiative_portfolio_items item
    on item.initiative_id = risk.initiative_id
   and item.formulation_id = p_formulation_id
  where risk.archived_at is null;

  select count(*)
  into outcome_count
  from public.skpe_initiative_outcomes
  where formulation_id = p_formulation_id
    and status <> 'archived';

  if selected_count = 0 then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE07_NO_SELECTED_INITIATIVE',
      'severity', 'blocking',
      'message', 'Nenhuma Iniciativa foi selecionada para a Formulação.'
    ));
  end if;

  if selected_count > package_row.maximum_selected_initiatives then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE07_PORTFOLIO_LIMIT_EXCEEDED',
      'severity', 'blocking',
      'message', format(
        'O portfólio possui %s Iniciativas selecionadas e excede o limite configurado de %s.',
        selected_count,
        package_row.maximum_selected_initiatives
      )
    ));
  end if;

  for record_row in
    select
      item.id as current_portfolio_item_id,
      item.initiative_id,
      item.strategic_value_score,
      item.expected_benefit_score,
      item.urgency_score,
      item.capacity_fit_score,
      item.effort_feasibility_score,
      item.risk_manageability_score,
      item.dependency_manageability_score,
      item.total_score,
      item.risk_assessment_status,
      item.capacity_assessment_status,
      initiative.code,
      initiative.name,
      initiative.description,
      initiative.strategic_problem,
      initiative.strategic_rationale,
      initiative.owner_user_id,
      initiative.responsible_area_id,
      initiative.start_date,
      initiative.due_date,
      initiative.sponsor_user_id,
      initiative.backup_owner_user_id
    from public.skpe_initiative_portfolio_items item
    join public.skpe_initiatives initiative
      on initiative.id = item.initiative_id
    where item.formulation_id = p_formulation_id
      and item.selection_status = 'selected'
  loop
    if length(trim(coalesce(record_row.code, ''))) = 0
       or length(trim(coalesce(record_row.name, ''))) = 0
       or length(trim(coalesce(record_row.description, ''))) < 10 then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_INITIATIVE_IDENTIFICATION_INCOMPLETE',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Iniciativa selecionada sem código, nome ou descrição suficiente.'
      ));
    end if;

    if exists (
      select 1
      from public.skpe_initiatives initiative_check
      where initiative_check.id = record_row.initiative_id
        and initiative_check.initiative_class = 'program'
        and not exists (
          select 1
          from public.skpe_initiatives child
          join public.skpe_initiative_portfolio_items child_item
            on child_item.initiative_id = child.id
           and child_item.formulation_id = p_formulation_id
           and child_item.selection_status = 'selected'
          where child.parent_initiative_id = initiative_check.id
            and child.archived_at is null
        )
    ) then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_PROGRAM_WITHOUT_COMPONENTS',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Programa selecionado sem projeto ou Iniciativa componente no portfólio.'
      ));
    end if;

    if exists (
      select 1
      from public.skpe_initiatives initiative_check
      where initiative_check.id = record_row.initiative_id
        and initiative_check.initiative_class = 'structuring_action'
        and initiative_check.parent_initiative_id is null
    ) then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_STRUCTURING_ACTION_WITHOUT_PARENT',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Ação estruturante selecionada sem Iniciativa ou projeto pai.'
      ));
    end if;

    if length(trim(coalesce(record_row.strategic_problem, ''))) < 10
       or length(trim(coalesce(record_row.strategic_rationale, ''))) < 10 then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_STRATEGIC_RATIONALE_INCOMPLETE',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Problema e justificativa estratégica devem ser explicitados.'
      ));
    end if;

    if package_row.owner_required and record_row.owner_user_id is null then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_OWNER_REQUIRED',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Iniciativa selecionada sem responsável.'
      ));
    end if;

    if package_row.responsible_area_required and record_row.responsible_area_id is null then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_RESPONSIBLE_AREA_REQUIRED',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Iniciativa selecionada sem área responsável.'
      ));
    end if;

    if record_row.start_date is not null
       and formulation_row.valid_from is not null
       and record_row.start_date < formulation_row.valid_from then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_START_BEFORE_FORMULATION',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Data inicial anterior ao horizonte da Formulação.'
      ));
    end if;

    if record_row.due_date is not null
       and formulation_row.valid_until is not null
       and record_row.due_date > formulation_row.valid_until then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_DUE_AFTER_FORMULATION',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Data final posterior ao horizonte da Formulação.'
      ));
    end if;

    if not exists (
      select 1
      from public.skpe_initiative_objectives objective_link
      where objective_link.portfolio_item_id = record_row.current_portfolio_item_id
        and objective_link.formulation_id = p_formulation_id
    ) and not exists (
      select 1
      from public.skpe_initiative_key_results kr_link
      where kr_link.portfolio_item_id = record_row.current_portfolio_item_id
        and kr_link.formulation_id = p_formulation_id
    ) then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_STRATEGIC_LINK_REQUIRED',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Iniciativa selecionada sem vínculo com Objetivo Estratégico ou Resultado-Chave.'
      ));
    end if;

    if package_row.portfolio_scoring_required
       and (
         record_row.strategic_value_score is null
         or record_row.expected_benefit_score is null
         or record_row.urgency_score is null
         or record_row.capacity_fit_score is null
         or record_row.effort_feasibility_score is null
         or record_row.risk_manageability_score is null
         or record_row.dependency_manageability_score is null
         or record_row.total_score is null
       ) then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_SCORING_INCOMPLETE',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Priorização do item de portfólio incompleta.'
      ));
    end if;

    if package_row.risk_assessment_required
       and record_row.risk_assessment_status = 'not_assessed' then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_RISK_ASSESSMENT_REQUIRED',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Avaliação de riscos ainda não realizada.'
      ));
    end if;

    if record_row.capacity_assessment_status = 'not_assessed' then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_CAPACITY_ASSESSMENT_REQUIRED',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Avaliação de capacidade ainda não realizada.'
      ));
    end if;

    if package_row.outcome_required
       and not exists (
         select 1
         from public.skpe_initiative_outcomes outcome
         where outcome.portfolio_item_id = record_row.current_portfolio_item_id
           and outcome.outcome_type in ('expected_result', 'benefit')
           and outcome.status <> 'archived'
       ) then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_OUTCOME_REQUIRED',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Iniciativa sem resultado ou benefício esperado.'
      ));
    end if;

    if package_row.success_criterion_required
       and not exists (
         select 1
         from public.skpe_initiative_outcomes outcome
         where outcome.portfolio_item_id = record_row.current_portfolio_item_id
           and outcome.outcome_type = 'success_criterion'
           and outcome.status <> 'archived'
       ) then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_SUCCESS_CRITERION_REQUIRED',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Iniciativa sem critério de sucesso.'
      ));
    end if;

    if package_row.action_plan_required
       and not exists (
         select 1
         from public.skpe_initiative_actions action
         where action.initiative_id = record_row.initiative_id
           and action.archived_at is null
           and action.is_required_for_readiness
       ) then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_ACTION_PLAN_REQUIRED',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Iniciativa sem plano de ação obrigatório.'
      ));
    end if;

    if package_row.five_w_two_h_required
       and exists (
         select 1
         from public.skpe_initiative_actions action
         where action.initiative_id = record_row.initiative_id
           and action.archived_at is null
           and action.is_required_for_readiness
           and (
             length(trim(coalesce(action.what_text, ''))) < 5
             or length(trim(coalesce(action.why_text, ''))) < 5
             or length(trim(coalesce(action.where_text, ''))) < 3
             or length(trim(coalesce(action.when_text, ''))) < 3
             or length(trim(coalesce(action.who_text, ''))) < 3
             or length(trim(coalesce(action.how_text, ''))) < 5
             or length(trim(coalesce(action.how_much_text, ''))) < 3
           )
       ) then
      blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_ACTION_5W2H_INCOMPLETE',
        'severity', 'blocking',
        'entityId', record_row.initiative_id,
        'message', 'Plano de ação obrigatório contém item com 5W2H incompleto.'
      ));
    end if;

    if record_row.sponsor_user_id is null then
      recommendations := recommendations || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_SPONSOR_RECOMMENDED',
        'severity', 'recommendation',
        'entityId', record_row.initiative_id,
        'message', 'Recomenda-se designar patrocinador para a Iniciativa.'
      ));
    end if;

    if record_row.backup_owner_user_id is null then
      recommendations := recommendations || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_BACKUP_OWNER_RECOMMENDED',
        'severity', 'recommendation',
        'entityId', record_row.initiative_id,
        'message', 'Recomenda-se designar responsável substituto.'
      ));
    end if;

    if package_row.indicator_link_recommended
       and not exists (
         select 1
         from public.skpe_initiative_outcomes outcome
         where outcome.portfolio_item_id = record_row.current_portfolio_item_id
           and outcome.indicator_id is not null
           and outcome.status <> 'archived'
       ) then
      recommendations := recommendations || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_INDICATOR_LINK_RECOMMENDED',
        'severity', 'recommendation',
        'entityId', record_row.initiative_id,
        'message', 'Recomenda-se vincular benefício ou critério de sucesso a Indicador Estratégico.'
      ));
    end if;

    if package_row.okr_or_key_result_link_recommended
       and not exists (
         select 1
         from public.skpe_initiative_key_results kr_link
         where kr_link.portfolio_item_id = record_row.current_portfolio_item_id
           and kr_link.formulation_id = p_formulation_id
       ) then
      recommendations := recommendations || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_KEY_RESULT_LINK_RECOMMENDED',
        'severity', 'recommendation',
        'entityId', record_row.initiative_id,
        'message', 'Recomenda-se associar a Iniciativa a Resultado-Chave quando OKRs estiverem habilitados.'
      ));
    end if;

    if not exists (
      select 1
      from public.skpe_initiative_actions action
      where action.initiative_id = record_row.initiative_id
        and action.action_type = 'milestone'
        and action.archived_at is null
    ) then
      recommendations := recommendations || jsonb_build_array(jsonb_build_object(
        'code', 'FE07_MILESTONE_RECOMMENDED',
        'severity', 'recommendation',
        'entityId', record_row.initiative_id,
        'message', 'Recomenda-se registrar ao menos um marco relevante.'
      ));
    end if;
  end loop;

  for record_row in
    select dependency.*
    from public.skpe_initiative_dependencies dependency
    where dependency.formulation_id = p_formulation_id
      and dependency.status <> 'archived'
      and dependency.criticality in ('high', 'critical')
      and (
        dependency.owner_user_id is null
        or length(trim(coalesce(dependency.response_plan, ''))) < 10
      )
  loop
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE07_CRITICAL_DEPENDENCY_UNMANAGED',
      'severity', 'blocking',
      'entityId', record_row.id,
      'message', 'Dependência alta ou crítica sem responsável e plano de resposta suficientes.'
    ));
  end loop;

  for record_row in
    select risk.*
    from public.skpe_initiative_risks risk
    join public.skpe_initiative_portfolio_items item
      on item.initiative_id = risk.initiative_id
     and item.formulation_id = p_formulation_id
    where risk.archived_at is null
      and coalesce(risk.inherent_score, 0) >= 15
      and (
        risk.owner_user_id is null
        or length(trim(coalesce(risk.response_plan, ''))) < 10
      )
  loop
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE07_CRITICAL_RISK_UNMANAGED',
      'severity', 'blocking',
      'entityId', record_row.id,
      'message', 'Risco alto ou crítico sem responsável e resposta suficientes.'
    ));
  end loop;

  if p_include_package_state and package_row.status <> 'validated' then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE07_PACKAGE_NOT_VALIDATED',
      'severity', 'blocking',
      'message', 'O pacote FE-07 ainda não foi validado.'
    ));
  end if;

  issue_count := jsonb_array_length(blocking_issues);
  recommendation_count := jsonb_array_length(recommendations);

  return jsonb_build_object(
    'applicability', 'applicable',
    'packageStatus', package_row.status,
    'readyForValidation', issue_count = 0,
    'readyForFormulation', issue_count = 0 and package_row.status = 'validated',
    'blockingIssues', blocking_issues,
    'recommendations', recommendations,
    'metrics', jsonb_build_object(
      'selectedInitiatives', selected_count,
      'candidateInitiatives', candidate_count,
      'actions', action_count,
      'risks', risk_count,
      'outcomes', outcome_count,
      'blockingIssueCount', issue_count,
      'recommendationCount', recommendation_count
    )
  );
end;
$$;

-- ============================================================
-- 12. RPCs DE CONFIGURAÇÃO E INICIATIVA MESTRE
-- ============================================================

create or replace function public.configure_skpe_initiative_package(
  p_formulation_id uuid,
  p_configuration jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_id uuid;
  previous_data jsonb;
  new_data jsonb;
  enabled_value boolean;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para configurar o pacote FE-07.'
      using errcode = '42501';
  end if;

  package_id := public.ensure_skpe_initiative_package(p_formulation_id);

  select to_jsonb(package_row)
  into previous_data
  from public.skpe_initiative_packages package_row
  where package_row.id = package_id;

  enabled_value := coalesce(
    (p_configuration ->> 'initiativeManagementEnabled')::boolean,
    (previous_data ->> 'initiative_management_enabled')::boolean,
    true
  );

  update public.skpe_initiative_packages
  set
    initiative_management_enabled = enabled_value,
    status = case when enabled_value then 'in_elaboration' else 'not_applicable' end,
    owner_required = coalesce(
      (p_configuration ->> 'ownerRequired')::boolean,
      owner_required
    ),
    responsible_area_required = coalesce(
      (p_configuration ->> 'responsibleAreaRequired')::boolean,
      responsible_area_required
    ),
    action_plan_required = coalesce(
      (p_configuration ->> 'actionPlanRequired')::boolean,
      action_plan_required
    ),
    five_w_two_h_required = coalesce(
      (p_configuration ->> 'fiveWTwoHRequired')::boolean,
      five_w_two_h_required
    ),
    outcome_required = coalesce(
      (p_configuration ->> 'outcomeRequired')::boolean,
      outcome_required
    ),
    success_criterion_required = coalesce(
      (p_configuration ->> 'successCriterionRequired')::boolean,
      success_criterion_required
    ),
    risk_assessment_required = coalesce(
      (p_configuration ->> 'riskAssessmentRequired')::boolean,
      risk_assessment_required
    ),
    portfolio_scoring_required = coalesce(
      (p_configuration ->> 'portfolioScoringRequired')::boolean,
      portfolio_scoring_required
    ),
    okr_or_key_result_link_recommended = coalesce(
      (p_configuration ->> 'okrOrKeyResultLinkRecommended')::boolean,
      okr_or_key_result_link_recommended
    ),
    indicator_link_recommended = coalesce(
      (p_configuration ->> 'indicatorLinkRecommended')::boolean,
      indicator_link_recommended
    ),
    maximum_selected_initiatives = coalesce(
      (p_configuration ->> 'maximumSelectedInitiatives')::integer,
      maximum_selected_initiatives
    ),
    weight_strategic_value = coalesce(
      (p_configuration ->> 'weightStrategicValue')::numeric,
      weight_strategic_value
    ),
    weight_expected_benefit = coalesce(
      (p_configuration ->> 'weightExpectedBenefit')::numeric,
      weight_expected_benefit
    ),
    weight_urgency = coalesce(
      (p_configuration ->> 'weightUrgency')::numeric,
      weight_urgency
    ),
    weight_capacity_fit = coalesce(
      (p_configuration ->> 'weightCapacityFit')::numeric,
      weight_capacity_fit
    ),
    weight_effort_feasibility = coalesce(
      (p_configuration ->> 'weightEffortFeasibility')::numeric,
      weight_effort_feasibility
    ),
    weight_risk_manageability = coalesce(
      (p_configuration ->> 'weightRiskManageability')::numeric,
      weight_risk_manageability
    ),
    weight_dependency_manageability = coalesce(
      (p_configuration ->> 'weightDependencyManageability')::numeric,
      weight_dependency_manageability
    ),
    validation_notes = null,
    submitted_for_validation_at = null,
    submitted_for_validation_by = null,
    validated_at = null,
    validated_by = null,
    metadata = coalesce(metadata, '{}'::jsonb)
      || coalesce(p_configuration -> 'metadata', '{}'::jsonb),
    updated_by = auth.uid()
  where id = package_id
  returning to_jsonb(skpe_initiative_packages)
  into new_data;

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_package',
    package_id,
    'fe07.package_configured',
    p_change_reason,
    previous_data,
    new_data
  );

  return package_id;
end;
$$;

create or replace function public.upsert_skpe_initiative(
  p_formulation_id uuid,
  p_initiative_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  initiative_row public.skpe_initiatives%rowtype;
  target_initiative_id uuid;
  target_parent_id uuid;
  target_area_id uuid;
  target_class text;
  previous_data jsonb;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(formulation_row.organization_id)
     or not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para gerenciar Iniciativas da FE-07.'
      using errcode = '42501';
  end if;

  perform public.ensure_skpe_initiative_package(p_formulation_id);

  target_class := coalesce(nullif(p_payload ->> 'initiativeClass', ''), 'initiative');
  target_parent_id := nullif(p_payload ->> 'parentInitiativeId', '')::uuid;
  target_area_id := nullif(p_payload ->> 'responsibleAreaId', '')::uuid;

  perform public.skpe_assert_fe07_responsible_area(
    formulation_row.organization_id,
    target_area_id
  );

  if p_initiative_id is null then
    perform public.skpe_assert_initiative_hierarchy(
      null,
      target_parent_id,
      formulation_row.organization_id,
      formulation_row.project_id,
      target_class
    );

    insert into public.skpe_initiatives (
      organization_id,
      project_id,
      parent_initiative_id,
      code,
      name,
      description,
      initiative_type,
      initiative_class,
      status,
      priority,
      criticality,
      responsible_area,
      responsible_area_id,
      owner_user_id,
      backup_owner_user_id,
      sponsor_user_id,
      start_date,
      due_date,
      progress,
      planned_cost,
      planned_benefit,
      estimated_effort,
      effort_unit,
      resource_estimate,
      currency_code,
      estimate_confidence,
      strategic_theme,
      strategic_problem,
      strategic_rationale,
      constraints_text,
      proposal_origin,
      proposal_source_reference,
      validation_status,
      source_type,
      metadata,
      created_by,
      updated_by,
      last_update_at
    )
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      target_parent_id,
      trim(p_payload ->> 'code'),
      trim(p_payload ->> 'name'),
      nullif(trim(p_payload ->> 'description'), ''),
      coalesce(
        nullif(p_payload ->> 'initiativeType', ''),
        case target_class
          when 'program' then 'strategic_program'
          when 'project' then 'strategic_project'
          when 'structuring_action' then 'simple_action'
          else 'operational_improvement'
        end
      ),
      target_class,
      coalesce(nullif(p_payload ->> 'status', ''), 'proposed'),
      coalesce(nullif(p_payload ->> 'priority', ''), 'medium'),
      coalesce(nullif(p_payload ->> 'criticality', ''), 'medium'),
      nullif(trim(p_payload ->> 'responsibleArea'), ''),
      target_area_id,
      nullif(p_payload ->> 'ownerUserId', '')::uuid,
      nullif(p_payload ->> 'backupOwnerUserId', '')::uuid,
      nullif(p_payload ->> 'sponsorUserId', '')::uuid,
      nullif(p_payload ->> 'startDate', '')::date,
      nullif(p_payload ->> 'dueDate', '')::date,
      0,
      nullif(p_payload ->> 'plannedCost', '')::numeric,
      nullif(p_payload ->> 'plannedBenefit', '')::numeric,
      nullif(p_payload ->> 'estimatedEffort', '')::numeric,
      nullif(p_payload ->> 'effortUnit', ''),
      nullif(trim(p_payload ->> 'resourceEstimate'), ''),
      coalesce(nullif(upper(p_payload ->> 'currencyCode'), ''), 'BRL'),
      coalesce(nullif(p_payload ->> 'estimateConfidence', ''), 'medium'),
      nullif(trim(p_payload ->> 'strategicTheme'), ''),
      nullif(trim(p_payload ->> 'strategicProblem'), ''),
      nullif(trim(p_payload ->> 'strategicRationale'), ''),
      nullif(trim(p_payload ->> 'constraintsText'), ''),
      coalesce(nullif(p_payload ->> 'proposalOrigin', ''), 'organization'),
      nullif(trim(p_payload ->> 'proposalSourceReference'), ''),
      'pending_validation',
      coalesce(nullif(p_payload ->> 'sourceType', ''), 'strategic_planning'),
      coalesce(p_payload -> 'metadata', '{}'::jsonb),
      auth.uid(),
      auth.uid(),
      timezone('utc', now())
    )
    returning id into target_initiative_id;

    previous_data := null;
  else
    select *
    into initiative_row
    from public.skpe_initiatives
    where id = p_initiative_id
      and organization_id = formulation_row.organization_id
      and project_id = formulation_row.project_id
      and archived_at is null
    for update;

    if not found then
      raise exception 'Iniciativa não encontrada no escopo da Formulação.'
        using errcode = '22023';
    end if;

    previous_data := to_jsonb(initiative_row);
    target_initiative_id := initiative_row.id;

    perform public.skpe_assert_initiative_hierarchy(
      target_initiative_id,
      target_parent_id,
      formulation_row.organization_id,
      formulation_row.project_id,
      target_class
    );

    update public.skpe_initiatives
    set
      parent_initiative_id = target_parent_id,
      code = trim(p_payload ->> 'code'),
      name = trim(p_payload ->> 'name'),
      description = nullif(trim(p_payload ->> 'description'), ''),
      initiative_type = coalesce(
        nullif(p_payload ->> 'initiativeType', ''),
        initiative_type
      ),
      initiative_class = target_class,
      priority = coalesce(nullif(p_payload ->> 'priority', ''), priority),
      criticality = coalesce(nullif(p_payload ->> 'criticality', ''), criticality),
      responsible_area = nullif(trim(p_payload ->> 'responsibleArea'), ''),
      responsible_area_id = target_area_id,
      owner_user_id = nullif(p_payload ->> 'ownerUserId', '')::uuid,
      backup_owner_user_id = nullif(p_payload ->> 'backupOwnerUserId', '')::uuid,
      sponsor_user_id = nullif(p_payload ->> 'sponsorUserId', '')::uuid,
      start_date = nullif(p_payload ->> 'startDate', '')::date,
      due_date = nullif(p_payload ->> 'dueDate', '')::date,
      planned_cost = nullif(p_payload ->> 'plannedCost', '')::numeric,
      planned_benefit = nullif(p_payload ->> 'plannedBenefit', '')::numeric,
      estimated_effort = nullif(p_payload ->> 'estimatedEffort', '')::numeric,
      effort_unit = nullif(p_payload ->> 'effortUnit', ''),
      resource_estimate = nullif(trim(p_payload ->> 'resourceEstimate'), ''),
      currency_code = coalesce(nullif(upper(p_payload ->> 'currencyCode'), ''), currency_code),
      estimate_confidence = coalesce(
        nullif(p_payload ->> 'estimateConfidence', ''),
        estimate_confidence
      ),
      strategic_theme = nullif(trim(p_payload ->> 'strategicTheme'), ''),
      strategic_problem = nullif(trim(p_payload ->> 'strategicProblem'), ''),
      strategic_rationale = nullif(trim(p_payload ->> 'strategicRationale'), ''),
      constraints_text = nullif(trim(p_payload ->> 'constraintsText'), ''),
      proposal_origin = coalesce(
        nullif(p_payload ->> 'proposalOrigin', ''),
        proposal_origin
      ),
      proposal_source_reference = nullif(
        trim(p_payload ->> 'proposalSourceReference'),
        ''
      ),
      validation_status = 'pending_validation',
      metadata = coalesce(metadata, '{}'::jsonb)
        || coalesce(p_payload -> 'metadata', '{}'::jsonb),
      updated_by = auth.uid(),
      last_update_at = timezone('utc', now())
    where id = target_initiative_id;
  end if;

  insert into public.skpe_initiative_portfolio_items (
    organization_id,
    project_id,
    formulation_id,
    initiative_id,
    selection_status,
    portfolio_priority,
    criticality,
    decision_reason,
    validation_status,
    metadata,
    created_by,
    updated_by
  )
  values (
    formulation_row.organization_id,
    formulation_row.project_id,
    formulation_row.id,
    target_initiative_id,
    coalesce(nullif(p_payload ->> 'selectionStatus', ''), 'candidate'),
    coalesce(nullif(p_payload ->> 'portfolioPriority', ''), 'medium'),
    coalesce(nullif(p_payload ->> 'criticality', ''), 'medium'),
    nullif(trim(p_payload ->> 'decisionReason'), ''),
    'draft',
    coalesce(p_payload -> 'portfolioMetadata', '{}'::jsonb),
    auth.uid(),
    auth.uid()
  )
  on conflict (formulation_id, initiative_id)
  do update set
    portfolio_priority = excluded.portfolio_priority,
    criticality = excluded.criticality,
    decision_reason = coalesce(excluded.decision_reason, skpe_initiative_portfolio_items.decision_reason),
    validation_status = 'draft',
    updated_by = auth.uid();

  select to_jsonb(initiative)
  into new_data
  from public.skpe_initiatives initiative
  where initiative.id = target_initiative_id;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Iniciativa criada ou alterada.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative',
    target_initiative_id,
    case when p_initiative_id is null
      then 'fe07.initiative_created'
      else 'fe07.initiative_updated'
    end,
    p_change_reason,
    previous_data,
    new_data
  );

  return target_initiative_id;
end;
$$;

create or replace function public.archive_skpe_initiative(
  p_formulation_id uuid,
  p_initiative_id uuid,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  initiative_row public.skpe_initiatives%rowtype;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  select * into initiative_row
  from public.skpe_initiatives
  where id = p_initiative_id
    and organization_id = formulation_row.organization_id
    and project_id = formulation_row.project_id
  for update;

  if not found then
    raise exception 'Iniciativa não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Acesso negado para arquivar a Iniciativa.' using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.skpe_initiatives child
    where child.parent_initiative_id = p_initiative_id
      and child.archived_at is null
  ) then
    raise exception 'Arquive ou reclassifique as Iniciativas filhas antes de arquivar o registro.'
      using errcode = '55000';
  end if;

  update public.skpe_initiatives
  set
    status = 'archived',
    archived_at = timezone('utc', now()),
    updated_by = auth.uid(),
    last_update_at = timezone('utc', now())
  where id = p_initiative_id
  returning to_jsonb(skpe_initiatives) into new_data;

  update public.skpe_initiative_portfolio_items
  set
    selection_status = 'excluded',
    validation_status = 'draft',
    updated_by = auth.uid()
  where formulation_id = p_formulation_id
    and initiative_id = p_initiative_id;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Iniciativa arquivada.'
  );

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative',
    p_initiative_id,
    'fe07.initiative_archived',
    p_change_reason,
    to_jsonb(initiative_row),
    new_data
  );
end;
$$;

create or replace function public.update_skpe_initiative_operational_progress(
  p_initiative_id uuid,
  p_status text,
  p_progress numeric,
  p_actual_cost numeric,
  p_realized_benefit numeric,
  p_risk_level text,
  p_health_status text,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  initiative_row public.skpe_initiatives%rowtype;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
  into initiative_row
  from public.skpe_initiatives
  where id = p_initiative_id
    and archived_at is null
  for update;

  if not found then
    raise exception 'Iniciativa não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Acesso negado para atualizar a execução da Iniciativa.'
      using errcode = '42501';
  end if;

  update public.skpe_initiatives
  set
    status = coalesce(p_status, status),
    progress = coalesce(p_progress, progress),
    actual_cost = coalesce(p_actual_cost, actual_cost),
    realized_benefit = coalesce(p_realized_benefit, realized_benefit),
    risk_level = coalesce(p_risk_level, risk_level),
    health_status = coalesce(p_health_status, health_status),
    completed_at = case
      when coalesce(p_status, status) = 'completed'
        then coalesce(completed_at, timezone('utc', now()))
      else completed_at
    end,
    last_update_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = p_initiative_id
  returning to_jsonb(skpe_initiatives) into new_data;

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative',
    p_initiative_id,
    'fe07.initiative_operational_progress_updated',
    p_change_reason,
    to_jsonb(initiative_row),
    new_data
  );
end;
$$;

-- ============================================================
-- 13. RPCs DE PORTFÓLIO E VÍNCULOS ESTRATÉGICOS
-- ============================================================

create or replace function public.upsert_skpe_initiative_portfolio_item(
  p_formulation_id uuid,
  p_initiative_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  initiative_row public.skpe_initiatives%rowtype;
  portfolio_item_id uuid;
  previous_data jsonb;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  select * into initiative_row
  from public.skpe_initiatives
  where id = p_initiative_id
    and organization_id = formulation_row.organization_id
    and project_id = formulation_row.project_id
    and archived_at is null;

  if not found then
    raise exception 'Iniciativa não encontrada no escopo da Formulação.'
      using errcode = '22023';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id)
     or not public.can_manage_skpe_initiatives(formulation_row.organization_id) then
    raise exception 'Acesso negado para gerenciar o portfólio.'
      using errcode = '42501';
  end if;

  perform public.ensure_skpe_initiative_package(p_formulation_id);

  select to_jsonb(item), item.id
  into previous_data, portfolio_item_id
  from public.skpe_initiative_portfolio_items item
  where item.formulation_id = p_formulation_id
    and item.initiative_id = p_initiative_id;

  insert into public.skpe_initiative_portfolio_items (
    organization_id,
    project_id,
    formulation_id,
    initiative_id,
    selection_status,
    portfolio_priority,
    criticality,
    rank_position,
    decision_reason,
    constraints_text,
    strategic_value_score,
    expected_benefit_score,
    urgency_score,
    capacity_fit_score,
    effort_feasibility_score,
    risk_manageability_score,
    dependency_manageability_score,
    risk_assessment_status,
    risk_assessment_notes,
    dependency_assessment_status,
    dependency_assessment_notes,
    capacity_assessment_status,
    capacity_assessment_notes,
    validation_status,
    metadata,
    created_by,
    updated_by,
    selected_at,
    selected_by
  )
  values (
    formulation_row.organization_id,
    formulation_row.project_id,
    formulation_row.id,
    initiative_row.id,
    coalesce(nullif(p_payload ->> 'selectionStatus', ''), 'candidate'),
    coalesce(nullif(p_payload ->> 'portfolioPriority', ''), 'medium'),
    coalesce(nullif(p_payload ->> 'criticality', ''), initiative_row.criticality),
    nullif(p_payload ->> 'rankPosition', '')::integer,
    nullif(trim(p_payload ->> 'decisionReason'), ''),
    nullif(trim(p_payload ->> 'constraintsText'), ''),
    nullif(p_payload ->> 'strategicValueScore', '')::numeric,
    nullif(p_payload ->> 'expectedBenefitScore', '')::numeric,
    nullif(p_payload ->> 'urgencyScore', '')::numeric,
    nullif(p_payload ->> 'capacityFitScore', '')::numeric,
    nullif(p_payload ->> 'effortFeasibilityScore', '')::numeric,
    nullif(p_payload ->> 'riskManageabilityScore', '')::numeric,
    nullif(p_payload ->> 'dependencyManageabilityScore', '')::numeric,
    coalesce(nullif(p_payload ->> 'riskAssessmentStatus', ''), 'not_assessed'),
    nullif(trim(p_payload ->> 'riskAssessmentNotes'), ''),
    coalesce(nullif(p_payload ->> 'dependencyAssessmentStatus', ''), 'not_assessed'),
    nullif(trim(p_payload ->> 'dependencyAssessmentNotes'), ''),
    coalesce(nullif(p_payload ->> 'capacityAssessmentStatus', ''), 'not_assessed'),
    nullif(trim(p_payload ->> 'capacityAssessmentNotes'), ''),
    'draft',
    coalesce(p_payload -> 'metadata', '{}'::jsonb),
    auth.uid(),
    auth.uid(),
    case when p_payload ->> 'selectionStatus' = 'selected' then timezone('utc', now()) else null end,
    case when p_payload ->> 'selectionStatus' = 'selected' then auth.uid() else null end
  )
  on conflict (formulation_id, initiative_id)
  do update set
    selection_status = excluded.selection_status,
    portfolio_priority = excluded.portfolio_priority,
    criticality = excluded.criticality,
    rank_position = excluded.rank_position,
    decision_reason = excluded.decision_reason,
    constraints_text = excluded.constraints_text,
    strategic_value_score = excluded.strategic_value_score,
    expected_benefit_score = excluded.expected_benefit_score,
    urgency_score = excluded.urgency_score,
    capacity_fit_score = excluded.capacity_fit_score,
    effort_feasibility_score = excluded.effort_feasibility_score,
    risk_manageability_score = excluded.risk_manageability_score,
    dependency_manageability_score = excluded.dependency_manageability_score,
    risk_assessment_status = excluded.risk_assessment_status,
    risk_assessment_notes = excluded.risk_assessment_notes,
    dependency_assessment_status = excluded.dependency_assessment_status,
    dependency_assessment_notes = excluded.dependency_assessment_notes,
    capacity_assessment_status = excluded.capacity_assessment_status,
    capacity_assessment_notes = excluded.capacity_assessment_notes,
    validation_status = 'draft',
    selected_at = case
      when excluded.selection_status = 'selected'
        then coalesce(skpe_initiative_portfolio_items.selected_at, timezone('utc', now()))
      else null
    end,
    selected_by = case
      when excluded.selection_status = 'selected'
        then coalesce(skpe_initiative_portfolio_items.selected_by, auth.uid())
      else null
    end,
    metadata = coalesce(skpe_initiative_portfolio_items.metadata, '{}'::jsonb)
      || excluded.metadata,
    updated_by = auth.uid()
  returning id into portfolio_item_id;

  update public.skpe_initiative_portfolio_items
  set
    total_score = public.skpe_calculate_initiative_portfolio_score(portfolio_item_id),
    updated_by = auth.uid()
  where id = portfolio_item_id
  returning to_jsonb(skpe_initiative_portfolio_items) into new_data;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Item de portfólio criado ou alterado.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_portfolio_item',
    portfolio_item_id,
    'fe07.portfolio_item_upserted',
    p_change_reason,
    previous_data,
    new_data
  );

  return portfolio_item_id;
end;
$$;

create or replace function public.recalculate_skpe_initiative_portfolio_scores(
  p_formulation_id uuid,
  p_change_reason text
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  changed_count integer;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para recalcular o portfólio.'
      using errcode = '42501';
  end if;

  update public.skpe_initiative_portfolio_items item
  set
    total_score = public.skpe_calculate_initiative_portfolio_score(item.id),
    updated_by = auth.uid()
  where item.formulation_id = p_formulation_id;

  get diagnostics changed_count = row_count;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Pontuações de portfólio recalculadas.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_package',
    (select id from public.skpe_initiative_packages where formulation_id = p_formulation_id),
    'fe07.portfolio_scores_recalculated',
    p_change_reason,
    null,
    jsonb_build_object('changedCount', changed_count)
  );

  return changed_count;
end;
$$;

create or replace function public.link_skpe_initiative_objective(
  p_formulation_id uuid,
  p_initiative_id uuid,
  p_strategic_objective_id uuid,
  p_contribution_type text,
  p_contribution_weight numeric,
  p_notes text,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  objective_row public.skpe_strategic_objectives%rowtype;
  portfolio_item_row public.skpe_initiative_portfolio_items%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  select * into objective_row
  from public.skpe_strategic_objectives
  where id = p_strategic_objective_id
    and formulation_id = p_formulation_id
    and organization_id = formulation_row.organization_id
    and project_id = formulation_row.project_id;

  if not found then
    raise exception 'Objetivo Estratégico não pertence à Formulação informada.'
      using errcode = '22023';
  end if;

  select * into portfolio_item_row
  from public.skpe_initiative_portfolio_items
  where formulation_id = p_formulation_id
    and initiative_id = p_initiative_id;

  if not found then
    raise exception 'A Iniciativa deve integrar o portfólio da Formulação antes do vínculo.'
      using errcode = '22023';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para vincular Objetivo Estratégico.'
      using errcode = '42501';
  end if;

  insert into public.skpe_initiative_objectives (
    initiative_id,
    strategic_objective_id,
    contribution_type,
    contribution_weight,
    notes,
    created_by,
    organization_id,
    project_id,
    formulation_id,
    portfolio_item_id,
    validation_status,
    metadata
  )
  values (
    p_initiative_id,
    p_strategic_objective_id,
    coalesce(p_contribution_type, 'direct'),
    p_contribution_weight,
    nullif(trim(p_notes), ''),
    auth.uid(),
    formulation_row.organization_id,
    formulation_row.project_id,
    p_formulation_id,
    portfolio_item_row.id,
    'draft',
    '{}'::jsonb
  )
  on conflict (initiative_id, strategic_objective_id)
  do update set
    contribution_type = excluded.contribution_type,
    contribution_weight = excluded.contribution_weight,
    notes = excluded.notes,
    organization_id = excluded.organization_id,
    project_id = excluded.project_id,
    formulation_id = excluded.formulation_id,
    portfolio_item_id = excluded.portfolio_item_id,
    validation_status = 'draft';

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Vínculo entre Iniciativa e Objetivo Estratégico alterado.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_objective',
    p_initiative_id,
    'fe07.initiative_objective_linked',
    p_change_reason,
    null,
    jsonb_build_object(
      'formulationId', p_formulation_id,
      'objectiveId', p_strategic_objective_id,
      'contributionType', p_contribution_type,
      'contributionWeight', p_contribution_weight
    )
  );
end;
$$;

create or replace function public.unlink_skpe_initiative_objective(
  p_formulation_id uuid,
  p_initiative_id uuid,
  p_strategic_objective_id uuid,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  previous_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para remover vínculo estratégico.'
      using errcode = '42501';
  end if;

  select to_jsonb(link)
  into previous_data
  from public.skpe_initiative_objectives link
  where link.formulation_id = p_formulation_id
    and link.initiative_id = p_initiative_id
    and link.strategic_objective_id = p_strategic_objective_id;

  delete from public.skpe_initiative_objectives
  where formulation_id = p_formulation_id
    and initiative_id = p_initiative_id
    and strategic_objective_id = p_strategic_objective_id;

  if not found then
    raise exception 'Vínculo não encontrado.' using errcode = '22023';
  end if;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Vínculo com Objetivo Estratégico removido.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_objective',
    p_initiative_id,
    'fe07.initiative_objective_unlinked',
    p_change_reason,
    previous_data,
    null
  );
end;
$$;

create or replace function public.link_skpe_initiative_key_result(
  p_formulation_id uuid,
  p_initiative_id uuid,
  p_key_result_id uuid,
  p_contribution_type text,
  p_contribution_weight numeric,
  p_notes text,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  key_result_row public.skpe_key_results%rowtype;
  portfolio_item_row public.skpe_initiative_portfolio_items%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  select * into key_result_row
  from public.skpe_key_results
  where id = p_key_result_id
    and formulation_id = p_formulation_id
    and organization_id = formulation_row.organization_id
    and project_id = formulation_row.project_id;

  if not found then
    raise exception 'Resultado-Chave não pertence à Formulação informada.'
      using errcode = '22023';
  end if;

  select * into portfolio_item_row
  from public.skpe_initiative_portfolio_items
  where formulation_id = p_formulation_id
    and initiative_id = p_initiative_id;

  if not found then
    raise exception 'A Iniciativa deve integrar o portfólio da Formulação antes do vínculo.'
      using errcode = '22023';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para vincular Resultado-Chave.'
      using errcode = '42501';
  end if;

  insert into public.skpe_initiative_key_results (
    initiative_id,
    key_result_id,
    contribution_type,
    contribution_weight,
    notes,
    created_by,
    organization_id,
    project_id,
    formulation_id,
    portfolio_item_id,
    validation_status,
    metadata
  )
  values (
    p_initiative_id,
    p_key_result_id,
    coalesce(p_contribution_type, 'direct'),
    p_contribution_weight,
    nullif(trim(p_notes), ''),
    auth.uid(),
    formulation_row.organization_id,
    formulation_row.project_id,
    p_formulation_id,
    portfolio_item_row.id,
    'draft',
    '{}'::jsonb
  )
  on conflict (initiative_id, key_result_id)
  do update set
    contribution_type = excluded.contribution_type,
    contribution_weight = excluded.contribution_weight,
    notes = excluded.notes,
    organization_id = excluded.organization_id,
    project_id = excluded.project_id,
    formulation_id = excluded.formulation_id,
    portfolio_item_id = excluded.portfolio_item_id,
    validation_status = 'draft';

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Vínculo entre Iniciativa e Resultado-Chave alterado.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_key_result',
    p_initiative_id,
    'fe07.initiative_key_result_linked',
    p_change_reason,
    null,
    jsonb_build_object(
      'formulationId', p_formulation_id,
      'keyResultId', p_key_result_id,
      'contributionType', p_contribution_type,
      'contributionWeight', p_contribution_weight
    )
  );
end;
$$;

create or replace function public.unlink_skpe_initiative_key_result(
  p_formulation_id uuid,
  p_initiative_id uuid,
  p_key_result_id uuid,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  previous_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para remover vínculo com Resultado-Chave.'
      using errcode = '42501';
  end if;

  select to_jsonb(link)
  into previous_data
  from public.skpe_initiative_key_results link
  where link.formulation_id = p_formulation_id
    and link.initiative_id = p_initiative_id
    and link.key_result_id = p_key_result_id;

  delete from public.skpe_initiative_key_results
  where formulation_id = p_formulation_id
    and initiative_id = p_initiative_id
    and key_result_id = p_key_result_id;

  if not found then
    raise exception 'Vínculo não encontrado.' using errcode = '22023';
  end if;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Vínculo com Resultado-Chave removido.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_key_result',
    p_initiative_id,
    'fe07.initiative_key_result_unlinked',
    p_change_reason,
    previous_data,
    null
  );
end;
$$;

-- ============================================================
-- 14. RPCs DE PLANO DE AÇÃO
-- ============================================================

create or replace function public.upsert_skpe_initiative_action(
  p_initiative_id uuid,
  p_action_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  initiative_row public.skpe_initiatives%rowtype;
  action_row public.skpe_initiative_actions%rowtype;
  target_action_id uuid;
  target_parent_id uuid;
  target_area_id uuid;
  target_origin_formulation_id uuid;
  previous_data jsonb;
  new_data jsonb;
  affected_formulation_id uuid;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
  into initiative_row
  from public.skpe_initiatives
  where id = p_initiative_id
    and archived_at is null;

  if not found then
    raise exception 'Iniciativa não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Acesso negado para gerenciar o plano de ação.'
      using errcode = '42501';
  end if;

  target_parent_id := nullif(p_payload ->> 'parentActionId', '')::uuid;
  target_area_id := nullif(p_payload ->> 'responsibleAreaId', '')::uuid;
  target_origin_formulation_id := nullif(p_payload ->> 'originFormulationId', '')::uuid;

  perform public.skpe_assert_fe07_responsible_area(
    initiative_row.organization_id,
    target_area_id
  );

  if target_origin_formulation_id is not null then
    if not exists (
      select 1
      from public.skpe_strategic_formulations formulation
      where formulation.id = target_origin_formulation_id
        and formulation.organization_id = initiative_row.organization_id
        and formulation.project_id = initiative_row.project_id
    ) then
      raise exception 'Formulação de origem incompatível com a Iniciativa.'
        using errcode = '22023';
    end if;
  end if;

  if target_parent_id is not null then
    if target_parent_id = p_action_id then
      raise exception 'Uma ação não pode ser pai de si própria.' using errcode = '22023';
    end if;

    if not exists (
      select 1
      from public.skpe_initiative_actions parent_action
      where parent_action.id = target_parent_id
        and parent_action.initiative_id = p_initiative_id
        and parent_action.archived_at is null
    ) then
      raise exception 'Ação pai não pertence à mesma Iniciativa.' using errcode = '22023';
    end if;

    if p_action_id is not null and exists (
      with recursive descendants as (
        select child.id
        from public.skpe_initiative_actions child
        where child.parent_action_id = p_action_id
          and child.archived_at is null

        union all

        select child.id
        from public.skpe_initiative_actions child
        join descendants current_descendant
          on child.parent_action_id = current_descendant.id
        where child.archived_at is null
      )
      select 1
      from descendants
      where id = target_parent_id
    ) then
      raise exception 'A hierarquia de ações criaria um ciclo.' using errcode = '22023';
    end if;
  end if;

  if p_action_id is null then
    insert into public.skpe_initiative_actions (
      organization_id,
      project_id,
      initiative_id,
      origin_formulation_id,
      parent_action_id,
      code,
      name,
      description,
      action_type,
      what_text,
      why_text,
      where_text,
      when_text,
      who_text,
      how_text,
      how_much_text,
      responsible_user_id,
      backup_responsible_user_id,
      responsible_area_id,
      start_date,
      due_date,
      completed_at,
      status,
      priority,
      progress,
      is_required_for_readiness,
      display_order,
      estimated_cost,
      actual_cost,
      estimated_effort,
      effort_unit,
      currency_code,
      validation_status,
      metadata,
      created_by,
      updated_by
    )
    values (
      initiative_row.organization_id,
      initiative_row.project_id,
      initiative_row.id,
      target_origin_formulation_id,
      target_parent_id,
      trim(p_payload ->> 'code'),
      trim(p_payload ->> 'name'),
      nullif(trim(p_payload ->> 'description'), ''),
      coalesce(nullif(p_payload ->> 'actionType', ''), 'action'),
      nullif(trim(p_payload ->> 'whatText'), ''),
      nullif(trim(p_payload ->> 'whyText'), ''),
      nullif(trim(p_payload ->> 'whereText'), ''),
      nullif(trim(p_payload ->> 'whenText'), ''),
      nullif(trim(p_payload ->> 'whoText'), ''),
      nullif(trim(p_payload ->> 'howText'), ''),
      nullif(trim(p_payload ->> 'howMuchText'), ''),
      nullif(p_payload ->> 'responsibleUserId', '')::uuid,
      nullif(p_payload ->> 'backupResponsibleUserId', '')::uuid,
      target_area_id,
      nullif(p_payload ->> 'startDate', '')::date,
      nullif(p_payload ->> 'dueDate', '')::date,
      case
        when coalesce(nullif(p_payload ->> 'status', ''), 'draft') = 'completed'
          then timezone('utc', now())
        else null
      end,
      coalesce(nullif(p_payload ->> 'status', ''), 'draft'),
      coalesce(nullif(p_payload ->> 'priority', ''), 'medium'),
      coalesce(nullif(p_payload ->> 'progress', '')::numeric, 0),
      coalesce((p_payload ->> 'requiredForReadiness')::boolean, true),
      coalesce(nullif(p_payload ->> 'displayOrder', '')::integer, 0),
      nullif(p_payload ->> 'estimatedCost', '')::numeric,
      nullif(p_payload ->> 'actualCost', '')::numeric,
      nullif(p_payload ->> 'estimatedEffort', '')::numeric,
      nullif(p_payload ->> 'effortUnit', ''),
      coalesce(nullif(upper(p_payload ->> 'currencyCode'), ''), 'BRL'),
      'draft',
      coalesce(p_payload -> 'metadata', '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning id into target_action_id;

    previous_data := null;
  else
    select *
    into action_row
    from public.skpe_initiative_actions
    where id = p_action_id
      and initiative_id = p_initiative_id
      and archived_at is null
    for update;

    if not found then
      raise exception 'Ação não encontrada.' using errcode = '22023';
    end if;

    previous_data := to_jsonb(action_row);
    target_action_id := action_row.id;

    update public.skpe_initiative_actions
    set
      origin_formulation_id = coalesce(target_origin_formulation_id, skpe_initiative_actions.origin_formulation_id),
      parent_action_id = target_parent_id,
      code = trim(p_payload ->> 'code'),
      name = trim(p_payload ->> 'name'),
      description = nullif(trim(p_payload ->> 'description'), ''),
      action_type = coalesce(nullif(p_payload ->> 'actionType', ''), action_type),
      what_text = nullif(trim(p_payload ->> 'whatText'), ''),
      why_text = nullif(trim(p_payload ->> 'whyText'), ''),
      where_text = nullif(trim(p_payload ->> 'whereText'), ''),
      when_text = nullif(trim(p_payload ->> 'whenText'), ''),
      who_text = nullif(trim(p_payload ->> 'whoText'), ''),
      how_text = nullif(trim(p_payload ->> 'howText'), ''),
      how_much_text = nullif(trim(p_payload ->> 'howMuchText'), ''),
      responsible_user_id = nullif(p_payload ->> 'responsibleUserId', '')::uuid,
      backup_responsible_user_id = nullif(p_payload ->> 'backupResponsibleUserId', '')::uuid,
      responsible_area_id = target_area_id,
      start_date = nullif(p_payload ->> 'startDate', '')::date,
      due_date = nullif(p_payload ->> 'dueDate', '')::date,
      status = coalesce(nullif(p_payload ->> 'status', ''), status),
      priority = coalesce(nullif(p_payload ->> 'priority', ''), priority),
      progress = coalesce(nullif(p_payload ->> 'progress', '')::numeric, progress),
      is_required_for_readiness = coalesce(
        (p_payload ->> 'requiredForReadiness')::boolean,
        is_required_for_readiness
      ),
      display_order = coalesce(
        nullif(p_payload ->> 'displayOrder', '')::integer,
        display_order
      ),
      estimated_cost = nullif(p_payload ->> 'estimatedCost', '')::numeric,
      actual_cost = nullif(p_payload ->> 'actualCost', '')::numeric,
      estimated_effort = nullif(p_payload ->> 'estimatedEffort', '')::numeric,
      effort_unit = nullif(p_payload ->> 'effortUnit', ''),
      currency_code = coalesce(nullif(upper(p_payload ->> 'currencyCode'), ''), currency_code),
      validation_status = 'draft',
      metadata = coalesce(metadata, '{}'::jsonb)
        || coalesce(p_payload -> 'metadata', '{}'::jsonb),
      completed_at = case
        when coalesce(nullif(p_payload ->> 'status', ''), status) = 'completed'
          then coalesce(completed_at, timezone('utc', now()))
        else completed_at
      end,
      updated_by = auth.uid()
    where id = target_action_id;
  end if;

  select to_jsonb(action)
  into new_data
  from public.skpe_initiative_actions action
  where action.id = target_action_id;

  for affected_formulation_id in
    select item.formulation_id
    from public.skpe_initiative_portfolio_items item
    join public.skpe_strategic_formulations formulation
      on formulation.id = item.formulation_id
    where item.initiative_id = p_initiative_id
      and formulation.status in ('draft', 'in_elaboration')
  loop
    perform public.skpe_invalidate_initiative_package(
      affected_formulation_id,
      'Plano de ação da Iniciativa alterado.'
    );
  end loop;

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative_action',
    target_action_id,
    case when p_action_id is null
      then 'fe07.action_created'
      else 'fe07.action_updated'
    end,
    p_change_reason,
    previous_data,
    new_data
  );

  return target_action_id;
end;
$$;

create or replace function public.update_skpe_initiative_action_progress(
  p_action_id uuid,
  p_status text,
  p_progress numeric,
  p_actual_cost numeric,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  action_row public.skpe_initiative_actions%rowtype;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
  into action_row
  from public.skpe_initiative_actions
  where id = p_action_id
    and archived_at is null
  for update;

  if not found then
    raise exception 'Ação não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(action_row.organization_id) then
    raise exception 'Acesso negado para atualizar a ação.' using errcode = '42501';
  end if;

  update public.skpe_initiative_actions
  set
    status = coalesce(p_status, status),
    progress = coalesce(p_progress, progress),
    actual_cost = coalesce(p_actual_cost, actual_cost),
    completed_at = case
      when coalesce(p_status, status) = 'completed'
        then coalesce(completed_at, timezone('utc', now()))
      else completed_at
    end,
    updated_by = auth.uid()
  where id = p_action_id
  returning to_jsonb(skpe_initiative_actions) into new_data;

  perform public.skpe_record_operational_audit(
    action_row.organization_id,
    action_row.project_id,
    'initiative_action',
    p_action_id,
    'fe07.action_progress_updated',
    p_change_reason,
    to_jsonb(action_row),
    new_data
  );
end;
$$;

create or replace function public.archive_skpe_initiative_action(
  p_action_id uuid,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  action_row public.skpe_initiative_actions%rowtype;
  new_data jsonb;
  affected_formulation_id uuid;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into action_row
  from public.skpe_initiative_actions
  where id = p_action_id
    and archived_at is null
  for update;

  if not found then
    raise exception 'Ação não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(action_row.organization_id) then
    raise exception 'Acesso negado para arquivar a ação.' using errcode = '42501';
  end if;

  if exists (
    select 1 from public.skpe_initiative_actions child
    where child.parent_action_id = p_action_id
      and child.archived_at is null
  ) then
    raise exception 'Arquive ou reclassifique as ações filhas antes desta operação.'
      using errcode = '55000';
  end if;

  update public.skpe_initiative_actions
  set
    status = 'archived',
    archived_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = p_action_id
  returning to_jsonb(skpe_initiative_actions) into new_data;

  for affected_formulation_id in
    select item.formulation_id
    from public.skpe_initiative_portfolio_items item
    join public.skpe_strategic_formulations formulation
      on formulation.id = item.formulation_id
    where item.initiative_id = action_row.initiative_id
      and formulation.status in ('draft', 'in_elaboration')
  loop
    perform public.skpe_invalidate_initiative_package(
      affected_formulation_id,
      'Ação do plano arquivada.'
    );
  end loop;

  perform public.skpe_record_operational_audit(
    action_row.organization_id,
    action_row.project_id,
    'initiative_action',
    p_action_id,
    'fe07.action_archived',
    p_change_reason,
    to_jsonb(action_row),
    new_data
  );
end;
$$;

-- ============================================================
-- 15. RPCs DE DEPENDÊNCIAS, RISCOS E RESULTADOS
-- ============================================================

create or replace function public.upsert_skpe_initiative_dependency(
  p_formulation_id uuid,
  p_dependency_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  source_item public.skpe_initiative_portfolio_items%rowtype;
  target_item public.skpe_initiative_portfolio_items%rowtype;
  dependency_row public.skpe_initiative_dependencies%rowtype;
  target_dependency_id uuid;
  source_item_id uuid;
  target_item_id uuid;
  relation_value text;
  previous_data jsonb;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para gerenciar dependências.' using errcode = '42501';
  end if;

  source_item_id := nullif(p_payload ->> 'sourcePortfolioItemId', '')::uuid;
  target_item_id := nullif(p_payload ->> 'targetPortfolioItemId', '')::uuid;
  relation_value := coalesce(nullif(p_payload ->> 'relationType', ''), 'depends_on');

  select * into source_item
  from public.skpe_initiative_portfolio_items
  where id = source_item_id
    and formulation_id = p_formulation_id;

  select * into target_item
  from public.skpe_initiative_portfolio_items
  where id = target_item_id
    and formulation_id = p_formulation_id;

  if source_item.id is null or target_item.id is null then
    raise exception 'Origem e destino devem pertencer ao portfólio da mesma Formulação.'
      using errcode = '22023';
  end if;

  if relation_value in ('depends_on', 'precedes')
     and public.skpe_dependency_would_create_cycle(
       p_formulation_id,
       source_item_id,
       target_item_id,
       p_dependency_id
     ) then
    raise exception 'A dependência proposta criaria um ciclo.' using errcode = '22023';
  end if;

  if p_dependency_id is null then
    insert into public.skpe_initiative_dependencies (
      organization_id,
      project_id,
      formulation_id,
      source_portfolio_item_id,
      target_portfolio_item_id,
      relation_type,
      criticality,
      owner_user_id,
      response_plan,
      status,
      validation_status,
      metadata,
      created_by,
      updated_by
    )
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      p_formulation_id,
      source_item_id,
      target_item_id,
      relation_value,
      coalesce(nullif(p_payload ->> 'criticality', ''), 'medium'),
      nullif(p_payload ->> 'ownerUserId', '')::uuid,
      nullif(trim(p_payload ->> 'responsePlan'), ''),
      coalesce(nullif(p_payload ->> 'status', ''), 'active'),
      'draft',
      coalesce(p_payload -> 'metadata', '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning id into target_dependency_id;

    previous_data := null;
  else
    select * into dependency_row
    from public.skpe_initiative_dependencies
    where id = p_dependency_id
      and formulation_id = p_formulation_id
    for update;

    if not found then
      raise exception 'Dependência não encontrada.' using errcode = '22023';
    end if;

    previous_data := to_jsonb(dependency_row);
    target_dependency_id := dependency_row.id;

    update public.skpe_initiative_dependencies
    set
      source_portfolio_item_id = source_item_id,
      target_portfolio_item_id = target_item_id,
      relation_type = relation_value,
      criticality = coalesce(nullif(p_payload ->> 'criticality', ''), criticality),
      owner_user_id = nullif(p_payload ->> 'ownerUserId', '')::uuid,
      response_plan = nullif(trim(p_payload ->> 'responsePlan'), ''),
      status = coalesce(nullif(p_payload ->> 'status', ''), status),
      validation_status = 'draft',
      metadata = coalesce(metadata, '{}'::jsonb)
        || coalesce(p_payload -> 'metadata', '{}'::jsonb),
      updated_by = auth.uid()
    where id = target_dependency_id;
  end if;

  select to_jsonb(dependency)
  into new_data
  from public.skpe_initiative_dependencies dependency
  where dependency.id = target_dependency_id;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Dependência de Iniciativa criada ou alterada.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_dependency',
    target_dependency_id,
    'fe07.dependency_upserted',
    p_change_reason,
    previous_data,
    new_data
  );

  return target_dependency_id;
end;
$$;

create or replace function public.transition_skpe_initiative_dependency(
  p_dependency_id uuid,
  p_status text,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  dependency_row public.skpe_initiative_dependencies%rowtype;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into dependency_row
  from public.skpe_initiative_dependencies
  where id = p_dependency_id
  for update;

  if not found then
    raise exception 'Dependência não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(dependency_row.organization_id) then
    raise exception 'Acesso negado para atualizar a dependência.' using errcode = '42501';
  end if;

  if p_status not in ('active', 'managed', 'resolved', 'archived') then
    raise exception 'Situação de dependência inválida.' using errcode = '22023';
  end if;

  update public.skpe_initiative_dependencies
  set status = p_status,
      updated_by = auth.uid()
  where id = p_dependency_id
  returning to_jsonb(skpe_initiative_dependencies) into new_data;

  perform public.skpe_record_operational_audit(
    dependency_row.organization_id,
    dependency_row.project_id,
    'initiative_dependency',
    p_dependency_id,
    'fe07.dependency_transitioned',
    p_change_reason,
    to_jsonb(dependency_row),
    new_data
  );
end;
$$;

create or replace function public.upsert_skpe_initiative_risk(
  p_initiative_id uuid,
  p_risk_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  initiative_row public.skpe_initiatives%rowtype;
  risk_row public.skpe_initiative_risks%rowtype;
  target_risk_id uuid;
  previous_data jsonb;
  new_data jsonb;
  affected_formulation_id uuid;
  target_origin_formulation_id uuid;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into initiative_row
  from public.skpe_initiatives
  where id = p_initiative_id
    and archived_at is null;

  if not found then
    raise exception 'Iniciativa não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Acesso negado para gerenciar riscos.' using errcode = '42501';
  end if;

  target_origin_formulation_id := nullif(p_payload ->> 'originFormulationId', '')::uuid;

  if target_origin_formulation_id is not null and not exists (
    select 1
    from public.skpe_strategic_formulations formulation
    where formulation.id = target_origin_formulation_id
      and formulation.organization_id = initiative_row.organization_id
      and formulation.project_id = initiative_row.project_id
  ) then
    raise exception 'Formulação de origem incompatível com a Iniciativa.'
      using errcode = '22023';
  end if;

  if p_risk_id is null then
    insert into public.skpe_initiative_risks (
      organization_id,
      project_id,
      initiative_id,
      origin_formulation_id,
      code,
      risk_event,
      cause,
      consequence,
      probability,
      impact,
      response_type,
      response_plan,
      owner_user_id,
      response_due_date,
      status,
      residual_probability,
      residual_impact,
      validation_status,
      metadata,
      created_by,
      updated_by
    )
    values (
      initiative_row.organization_id,
      initiative_row.project_id,
      initiative_row.id,
      target_origin_formulation_id,
      trim(p_payload ->> 'code'),
      trim(p_payload ->> 'riskEvent'),
      nullif(trim(p_payload ->> 'cause'), ''),
      nullif(trim(p_payload ->> 'consequence'), ''),
      nullif(p_payload ->> 'probability', '')::integer,
      nullif(p_payload ->> 'impact', '')::integer,
      nullif(p_payload ->> 'responseType', ''),
      nullif(trim(p_payload ->> 'responsePlan'), ''),
      nullif(p_payload ->> 'ownerUserId', '')::uuid,
      nullif(p_payload ->> 'responseDueDate', '')::date,
      coalesce(nullif(p_payload ->> 'status', ''), 'identified'),
      nullif(p_payload ->> 'residualProbability', '')::integer,
      nullif(p_payload ->> 'residualImpact', '')::integer,
      'draft',
      coalesce(p_payload -> 'metadata', '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning id into target_risk_id;

    previous_data := null;
  else
    select * into risk_row
    from public.skpe_initiative_risks
    where id = p_risk_id
      and initiative_id = p_initiative_id
      and archived_at is null
    for update;

    if not found then
      raise exception 'Risco não encontrado.' using errcode = '22023';
    end if;

    previous_data := to_jsonb(risk_row);
    target_risk_id := risk_row.id;

    update public.skpe_initiative_risks
    set
      origin_formulation_id = coalesce(
        target_origin_formulation_id,
        origin_formulation_id
      ),
      code = trim(p_payload ->> 'code'),
      risk_event = trim(p_payload ->> 'riskEvent'),
      cause = nullif(trim(p_payload ->> 'cause'), ''),
      consequence = nullif(trim(p_payload ->> 'consequence'), ''),
      probability = nullif(p_payload ->> 'probability', '')::integer,
      impact = nullif(p_payload ->> 'impact', '')::integer,
      response_type = nullif(p_payload ->> 'responseType', ''),
      response_plan = nullif(trim(p_payload ->> 'responsePlan'), ''),
      owner_user_id = nullif(p_payload ->> 'ownerUserId', '')::uuid,
      response_due_date = nullif(p_payload ->> 'responseDueDate', '')::date,
      status = coalesce(nullif(p_payload ->> 'status', ''), status),
      residual_probability = nullif(p_payload ->> 'residualProbability', '')::integer,
      residual_impact = nullif(p_payload ->> 'residualImpact', '')::integer,
      validation_status = 'draft',
      metadata = coalesce(metadata, '{}'::jsonb)
        || coalesce(p_payload -> 'metadata', '{}'::jsonb),
      occurred_at = case
        when coalesce(nullif(p_payload ->> 'status', ''), status) = 'occurred'
          then coalesce(occurred_at, timezone('utc', now()))
        else occurred_at
      end,
      updated_by = auth.uid()
    where id = target_risk_id;
  end if;

  select to_jsonb(risk)
  into new_data
  from public.skpe_initiative_risks risk
  where risk.id = target_risk_id;

  for affected_formulation_id in
    select item.formulation_id
    from public.skpe_initiative_portfolio_items item
    join public.skpe_strategic_formulations formulation
      on formulation.id = item.formulation_id
    where item.initiative_id = p_initiative_id
      and formulation.status in ('draft', 'in_elaboration')
  loop
    perform public.skpe_invalidate_initiative_package(
      affected_formulation_id,
      'Risco estratégico da Iniciativa alterado.'
    );
  end loop;

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative_risk',
    target_risk_id,
    'fe07.risk_upserted',
    p_change_reason,
    previous_data,
    new_data
  );

  return target_risk_id;
end;
$$;

create or replace function public.transition_skpe_initiative_risk(
  p_risk_id uuid,
  p_status text,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  risk_row public.skpe_initiative_risks%rowtype;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into risk_row
  from public.skpe_initiative_risks
  where id = p_risk_id
    and archived_at is null
  for update;

  if not found then
    raise exception 'Risco não encontrado.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(risk_row.organization_id) then
    raise exception 'Acesso negado para atualizar o risco.' using errcode = '42501';
  end if;

  if p_status not in (
    'identified',
    'assessed',
    'response_planned',
    'monitoring',
    'occurred',
    'closed',
    'archived'
  ) then
    raise exception 'Situação de risco inválida.' using errcode = '22023';
  end if;

  update public.skpe_initiative_risks
  set
    status = p_status,
    occurred_at = case
      when p_status = 'occurred' then coalesce(occurred_at, timezone('utc', now()))
      else occurred_at
    end,
    archived_at = case
      when p_status = 'archived' then coalesce(archived_at, timezone('utc', now()))
      else archived_at
    end,
    updated_by = auth.uid()
  where id = p_risk_id
  returning to_jsonb(skpe_initiative_risks) into new_data;

  perform public.skpe_record_operational_audit(
    risk_row.organization_id,
    risk_row.project_id,
    'initiative_risk',
    p_risk_id,
    'fe07.risk_transitioned',
    p_change_reason,
    to_jsonb(risk_row),
    new_data
  );
end;
$$;

create or replace function public.upsert_skpe_initiative_outcome(
  p_formulation_id uuid,
  p_portfolio_item_id uuid,
  p_outcome_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  portfolio_item_row public.skpe_initiative_portfolio_items%rowtype;
  outcome_row public.skpe_initiative_outcomes%rowtype;
  indicator_row public.skpe_indicators%rowtype;
  target_outcome_id uuid;
  target_indicator_id uuid;
  previous_data jsonb;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  select * into portfolio_item_row
  from public.skpe_initiative_portfolio_items
  where id = p_portfolio_item_id
    and formulation_id = p_formulation_id;

  if not found then
    raise exception 'Item de portfólio não pertence à Formulação.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para gerenciar resultados e benefícios.'
      using errcode = '42501';
  end if;

  target_indicator_id := nullif(p_payload ->> 'indicatorId', '')::uuid;

  if target_indicator_id is not null then
    select * into indicator_row
    from public.skpe_indicators
    where id = target_indicator_id
      and formulation_id = p_formulation_id
      and organization_id = formulation_row.organization_id
      and project_id = formulation_row.project_id;

    if not found then
      raise exception 'Indicador não pertence à Formulação informada.' using errcode = '22023';
    end if;
  end if;

  if p_outcome_id is null then
    insert into public.skpe_initiative_outcomes (
      organization_id,
      project_id,
      formulation_id,
      portfolio_item_id,
      indicator_id,
      code,
      name,
      description,
      outcome_type,
      measurement_type,
      baseline_value,
      target_value,
      current_value,
      unit,
      polarity,
      acceptance_criteria,
      due_date,
      owner_user_id,
      status,
      validation_status,
      metadata,
      created_by,
      updated_by
    )
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      p_formulation_id,
      portfolio_item_row.id,
      target_indicator_id,
      trim(p_payload ->> 'code'),
      trim(p_payload ->> 'name'),
      nullif(trim(p_payload ->> 'description'), ''),
      p_payload ->> 'outcomeType',
      coalesce(nullif(p_payload ->> 'measurementType', ''), 'qualitative'),
      nullif(p_payload ->> 'baselineValue', '')::numeric,
      nullif(p_payload ->> 'targetValue', '')::numeric,
      nullif(p_payload ->> 'currentValue', '')::numeric,
      nullif(trim(p_payload ->> 'unit'), ''),
      nullif(p_payload ->> 'polarity', ''),
      nullif(trim(p_payload ->> 'acceptanceCriteria'), ''),
      nullif(p_payload ->> 'dueDate', '')::date,
      nullif(p_payload ->> 'ownerUserId', '')::uuid,
      coalesce(nullif(p_payload ->> 'status', ''), 'planned'),
      'draft',
      coalesce(p_payload -> 'metadata', '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning id into target_outcome_id;

    previous_data := null;
  else
    select * into outcome_row
    from public.skpe_initiative_outcomes
    where id = p_outcome_id
      and portfolio_item_id = p_portfolio_item_id
      and formulation_id = p_formulation_id
    for update;

    if not found then
      raise exception 'Resultado ou benefício não encontrado.' using errcode = '22023';
    end if;

    previous_data := to_jsonb(outcome_row);
    target_outcome_id := outcome_row.id;

    update public.skpe_initiative_outcomes
    set
      indicator_id = target_indicator_id,
      code = trim(p_payload ->> 'code'),
      name = trim(p_payload ->> 'name'),
      description = nullif(trim(p_payload ->> 'description'), ''),
      outcome_type = p_payload ->> 'outcomeType',
      measurement_type = coalesce(
        nullif(p_payload ->> 'measurementType', ''),
        measurement_type
      ),
      baseline_value = nullif(p_payload ->> 'baselineValue', '')::numeric,
      target_value = nullif(p_payload ->> 'targetValue', '')::numeric,
      current_value = nullif(p_payload ->> 'currentValue', '')::numeric,
      unit = nullif(trim(p_payload ->> 'unit'), ''),
      polarity = nullif(p_payload ->> 'polarity', ''),
      acceptance_criteria = nullif(trim(p_payload ->> 'acceptanceCriteria'), ''),
      due_date = nullif(p_payload ->> 'dueDate', '')::date,
      owner_user_id = nullif(p_payload ->> 'ownerUserId', '')::uuid,
      status = coalesce(nullif(p_payload ->> 'status', ''), status),
      validation_status = 'draft',
      metadata = coalesce(metadata, '{}'::jsonb)
        || coalesce(p_payload -> 'metadata', '{}'::jsonb),
      updated_by = auth.uid()
    where id = target_outcome_id;
  end if;

  select to_jsonb(outcome)
  into new_data
  from public.skpe_initiative_outcomes outcome
  where outcome.id = target_outcome_id;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Resultado, benefício ou critério de sucesso alterado.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_outcome',
    target_outcome_id,
    'fe07.outcome_upserted',
    p_change_reason,
    previous_data,
    new_data
  );

  return target_outcome_id;
end;
$$;

create or replace function public.update_skpe_initiative_outcome_progress(
  p_outcome_id uuid,
  p_current_value numeric,
  p_status text,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  outcome_row public.skpe_initiative_outcomes%rowtype;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into outcome_row
  from public.skpe_initiative_outcomes
  where id = p_outcome_id
  for update;

  if not found then
    raise exception 'Resultado ou benefício não encontrado.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(outcome_row.organization_id) then
    raise exception 'Acesso negado para atualizar o resultado.' using errcode = '42501';
  end if;

  update public.skpe_initiative_outcomes
  set
    current_value = coalesce(p_current_value, current_value),
    status = coalesce(p_status, status),
    realized_at = case
      when coalesce(p_status, status) = 'achieved'
        then coalesce(realized_at, timezone('utc', now()))
      else realized_at
    end,
    updated_by = auth.uid()
  where id = p_outcome_id
  returning to_jsonb(skpe_initiative_outcomes) into new_data;

  perform public.skpe_record_operational_audit(
    outcome_row.organization_id,
    outcome_row.project_id,
    'initiative_outcome',
    p_outcome_id,
    'fe07.outcome_progress_updated',
    p_change_reason,
    to_jsonb(outcome_row),
    new_data
  );
end;
$$;

create or replace function public.archive_skpe_initiative_outcome(
  p_formulation_id uuid,
  p_outcome_id uuid,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  outcome_row public.skpe_initiative_outcomes%rowtype;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  select * into outcome_row
  from public.skpe_initiative_outcomes
  where id = p_outcome_id
    and formulation_id = p_formulation_id
  for update;

  if not found then
    raise exception 'Resultado ou benefício não encontrado.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para arquivar o resultado.' using errcode = '42501';
  end if;

  update public.skpe_initiative_outcomes
  set status = 'archived',
      validation_status = 'draft',
      updated_by = auth.uid()
  where id = p_outcome_id
  returning to_jsonb(skpe_initiative_outcomes) into new_data;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Resultado ou benefício arquivado.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_outcome',
    p_outcome_id,
    'fe07.outcome_archived',
    p_change_reason,
    to_jsonb(outcome_row),
    new_data
  );
end;
$$;

-- ============================================================
-- 16. TRANSIÇÃO DO PACOTE, CONTRATOS E AUDITORIA
-- ============================================================

create or replace function public.transition_skpe_initiative_package(
  p_formulation_id uuid,
  p_action text,
  p_notes text,
  p_change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_initiative_packages%rowtype;
  readiness jsonb;
  previous_data jsonb;
  new_data jsonb;
  portfolio_record record;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.' using errcode = '22023';
  end if;

  select * into package_row
  from public.skpe_initiative_packages
  where formulation_id = p_formulation_id
  for update;

  if not found then
    raise exception 'Pacote FE-07 não configurado.' using errcode = '22023';
  end if;

  previous_data := to_jsonb(package_row);

  if p_action = 'submit' then
    perform public.skpe_assert_formulation_editable(p_formulation_id);

    if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para submeter o pacote FE-07.' using errcode = '42501';
    end if;

    if not package_row.initiative_management_enabled then
      raise exception 'Pacote não aplicável não deve ser submetido.' using errcode = '55000';
    end if;

    readiness := public.get_skpe_initiatives_readiness(p_formulation_id, false);

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'O pacote FE-07 possui pendências bloqueantes: %',
        readiness -> 'blockingIssues'
        using errcode = '55000';
    end if;

    update public.skpe_initiative_packages
    set
      status = 'pending_validation',
      validation_notes = nullif(trim(p_notes), ''),
      submitted_for_validation_at = timezone('utc', now()),
      submitted_for_validation_by = auth.uid(),
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_portfolio_items
    set validation_status = 'pending_validation', updated_by = auth.uid()
    where formulation_id = p_formulation_id
      and selection_status = 'selected';

    update public.skpe_initiative_objectives
    set validation_status = 'pending_validation'
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_key_results
    set validation_status = 'pending_validation'
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_outcomes
    set validation_status = 'pending_validation', updated_by = auth.uid()
    where formulation_id = p_formulation_id
      and status <> 'archived';

    update public.skpe_initiative_dependencies
    set validation_status = 'pending_validation', updated_by = auth.uid()
    where formulation_id = p_formulation_id
      and status <> 'archived';

  elsif p_action = 'validate' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para validar o pacote FE-07.' using errcode = '42501';
    end if;

    if package_row.status <> 'pending_validation' then
      raise exception 'Somente pacote pendente de validação pode ser validado.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_initiatives_readiness(p_formulation_id, false);

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'O pacote FE-07 possui pendências bloqueantes: %',
        readiness -> 'blockingIssues'
        using errcode = '55000';
    end if;

    for portfolio_record in
      select id
      from public.skpe_initiative_portfolio_items
      where formulation_id = p_formulation_id
        and selection_status = 'selected'
    loop
      update public.skpe_initiative_portfolio_items
      set
        validated_snapshot = public.skpe_capture_initiative_validation_snapshot(
          portfolio_record.id
        ),
        validation_status = 'validated',
        updated_by = auth.uid()
      where id = portfolio_record.id;
    end loop;

    update public.skpe_initiative_objectives
    set validation_status = 'validated'
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_key_results
    set validation_status = 'validated'
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_outcomes
    set validation_status = 'validated', updated_by = auth.uid()
    where formulation_id = p_formulation_id
      and status <> 'archived';

    update public.skpe_initiative_dependencies
    set validation_status = 'validated', updated_by = auth.uid()
    where formulation_id = p_formulation_id
      and status <> 'archived';

    update public.skpe_initiative_packages
    set
      status = 'validated',
      validation_notes = nullif(trim(p_notes), ''),
      validated_at = timezone('utc', now()),
      validated_by = auth.uid(),
      updated_by = auth.uid()
    where formulation_id = p_formulation_id;

  elsif p_action = 'return' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para devolver o pacote FE-07.' using errcode = '42501';
    end if;

    if package_row.status not in ('pending_validation', 'validated') then
      raise exception 'Pacote não está em situação passível de devolução.'
        using errcode = '55000';
    end if;

    update public.skpe_initiative_packages
    set
      status = 'in_elaboration',
      validation_notes = nullif(trim(p_notes), ''),
      submitted_for_validation_at = null,
      submitted_for_validation_by = null,
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_portfolio_items
    set validation_status = 'draft', updated_by = auth.uid()
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_objectives
    set validation_status = 'draft'
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_key_results
    set validation_status = 'draft'
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_outcomes
    set validation_status = 'draft', updated_by = auth.uid()
    where formulation_id = p_formulation_id;

    update public.skpe_initiative_dependencies
    set validation_status = 'draft', updated_by = auth.uid()
    where formulation_id = p_formulation_id;
  else
    raise exception 'Ação de transição inválida: %', p_action using errcode = '22023';
  end if;

  select to_jsonb(package_after)
  into new_data
  from public.skpe_initiative_packages package_after
  where package_after.formulation_id = p_formulation_id;

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_package',
    package_row.id,
    'fe07.package_' || p_action,
    p_change_reason,
    previous_data,
    new_data
  );

  return new_data;
end;
$$;

create or replace function public.get_skpe_initiatives_package(
  p_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_initiative_packages%rowtype;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.' using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id)
     and not public.can_view_skpe_initiatives(formulation_row.organization_id) then
    raise exception 'Acesso negado ao pacote FE-07.' using errcode = '42501';
  end if;

  select * into package_row
  from public.skpe_initiative_packages
  where formulation_id = p_formulation_id;

  return jsonb_build_object(
    'configuration', to_jsonb(package_row),
    'readiness', public.get_skpe_initiatives_readiness(p_formulation_id, true),
    'portfolio', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'portfolioItem', to_jsonb(item),
          'initiative', to_jsonb(initiative),
          'parentInitiative', case
            when parent.id is null then null
            else jsonb_build_object(
              'id', parent.id,
              'code', parent.code,
              'name', parent.name,
              'initiativeClass', parent.initiative_class
            )
          end,
          'objectives', coalesce((
            select jsonb_agg(jsonb_build_object(
              'id', objective.id,
              'code', objective.code,
              'name', objective.name,
              'perspectiveId', objective.perspective_id,
              'contributionType', objective_link.contribution_type,
              'contributionWeight', objective_link.contribution_weight,
              'notes', objective_link.notes
            ) order by objective.code)
            from public.skpe_initiative_objectives objective_link
            join public.skpe_strategic_objectives objective
              on objective.id = objective_link.strategic_objective_id
            where objective_link.portfolio_item_id = item.id
              and objective_link.formulation_id = p_formulation_id
          ), '[]'::jsonb),
          'keyResults', coalesce((
            select jsonb_agg(jsonb_build_object(
              'id', kr.id,
              'code', kr.code,
              'name', kr.name,
              'okrId', kr.okr_id,
              'contributionType', kr_link.contribution_type,
              'contributionWeight', kr_link.contribution_weight,
              'notes', kr_link.notes
            ) order by kr.code)
            from public.skpe_initiative_key_results kr_link
            join public.skpe_key_results kr
              on kr.id = kr_link.key_result_id
            where kr_link.portfolio_item_id = item.id
              and kr_link.formulation_id = p_formulation_id
          ), '[]'::jsonb),
          'outcomes', coalesce((
            select jsonb_agg(to_jsonb(outcome) order by outcome.code)
            from public.skpe_initiative_outcomes outcome
            where outcome.portfolio_item_id = item.id
              and outcome.status <> 'archived'
          ), '[]'::jsonb),
          'actions', coalesce((
            select jsonb_agg(to_jsonb(action) order by action.display_order, action.code)
            from public.skpe_initiative_actions action
            where action.initiative_id = item.initiative_id
              and action.archived_at is null
          ), '[]'::jsonb),
          'risks', coalesce((
            select jsonb_agg(to_jsonb(risk) order by risk.inherent_score desc nulls last, risk.code)
            from public.skpe_initiative_risks risk
            where risk.initiative_id = item.initiative_id
              and risk.archived_at is null
          ), '[]'::jsonb)
        ) order by item.rank_position nulls last, item.total_score desc nulls last, initiative.name
      )
      from public.skpe_initiative_portfolio_items item
      join public.skpe_initiatives initiative
        on initiative.id = item.initiative_id
      left join public.skpe_initiatives parent
        on parent.id = initiative.parent_initiative_id
      where item.formulation_id = p_formulation_id
    ), '[]'::jsonb),
    'dependencies', coalesce((
      select jsonb_agg(to_jsonb(dependency) order by dependency.created_at)
      from public.skpe_initiative_dependencies dependency
      where dependency.formulation_id = p_formulation_id
        and dependency.status <> 'archived'
    ), '[]'::jsonb),
    'strategicTraceability', jsonb_build_object(
      'themes', coalesce((
        select jsonb_agg(distinct jsonb_build_object(
          'id', theme.id,
          'code', theme.code,
          'name', theme.name
        ))
        from public.skpe_initiative_objectives link
        join public.skpe_strategic_objectives objective
          on objective.id = link.strategic_objective_id
        join public.skpe_strategic_themes theme
          on theme.id = objective.strategic_theme_id
        where link.formulation_id = p_formulation_id
      ), '[]'::jsonb),
      'perspectives', coalesce((
        select jsonb_agg(distinct jsonb_build_object(
          'id', perspective.id,
          'code', perspective.code,
          'name', perspective.name
        ))
        from public.skpe_initiative_objectives link
        join public.skpe_strategic_objectives objective
          on objective.id = link.strategic_objective_id
        join public.skpe_bsc_perspectives perspective
          on perspective.id = objective.perspective_id
        where link.formulation_id = p_formulation_id
      ), '[]'::jsonb),
      'okrs', coalesce((
        select jsonb_agg(distinct jsonb_build_object(
          'id', okr.id,
          'code', okr.code,
          'title', okr.title
        ))
        from public.skpe_initiative_key_results link
        join public.skpe_key_results kr on kr.id = link.key_result_id
        join public.skpe_okrs okr on okr.id = kr.okr_id
        where link.formulation_id = p_formulation_id
      ), '[]'::jsonb),
      'indicators', coalesce((
        select jsonb_agg(distinct jsonb_build_object(
          'id', indicator.id,
          'code', indicator.code,
          'name', indicator.name
        ))
        from public.skpe_initiative_outcomes outcome
        join public.skpe_indicators indicator on indicator.id = outcome.indicator_id
        where outcome.formulation_id = p_formulation_id
          and outcome.status <> 'archived'
      ), '[]'::jsonb)
    ),
    'validationHistory', coalesce((
      select jsonb_agg(jsonb_build_object(
        'action', audit.action_code,
        'reason', audit.reason,
        'occurredAt', audit.occurred_at,
        'actorUserId', audit.actor_user_id,
        'previousData', audit.previous_data,
        'newData', audit.new_data
      ) order by audit.occurred_at desc)
      from public.skpe_operational_audit audit
      where audit.entity_type = 'initiative_package'
        and audit.entity_id = package_row.id
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.get_skpe_initiatives_audit(
  p_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.' using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id)
     and not public.can_view_skpe_initiatives(formulation_row.organization_id) then
    raise exception 'Acesso negado à auditoria da FE-07.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', audit.id,
      'entityType', audit.entity_type,
      'entityId', audit.entity_id,
      'actionCode', audit.action_code,
      'reason', audit.reason,
      'previousData', audit.previous_data,
      'newData', audit.new_data,
      'occurredAt', audit.occurred_at,
      'actorUserId', audit.actor_user_id
    ) order by audit.occurred_at desc)
    from public.skpe_operational_audit audit
    where audit.organization_id = formulation_row.organization_id
      and audit.project_id = formulation_row.project_id
      and (
        audit.entity_type like 'initiative%'
        or audit.action_code like 'fe07.%'
      )
  ), '[]'::jsonb);
end;
$$;

-- ============================================================
-- 17. BLOQUEIO INTEGRADO À TRANSIÇÃO DA FORMULAÇÃO
-- ============================================================

create or replace function public.skpe_guard_formulation_initiatives_ready()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  readiness jsonb;
  package_exists boolean;
begin
  if new.status in ('pending_validation', 'validated', 'pending_approval', 'approved')
     and old.status is distinct from new.status then
    select exists (
      select 1
      from public.skpe_initiative_packages package
      where package.formulation_id = new.id
    ) into package_exists;

    if not package_exists then
      raise exception 'Configure formalmente a aplicabilidade do pacote FE-07 antes de avançar a Formulação.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_initiatives_readiness(new.id, true);

    if not coalesce((readiness ->> 'readyForFormulation')::boolean, false) then
      raise exception 'A Formulação não pode avançar: pacote FE-07 incompleto ou não validado. Pendências: %',
        readiness -> 'blockingIssues'
        using errcode = '55000';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists skpe_strategic_formulations_guard_fe07
  on public.skpe_strategic_formulations;
create trigger skpe_strategic_formulations_guard_fe07
before update of status on public.skpe_strategic_formulations
for each row execute function public.skpe_guard_formulation_initiatives_ready();

-- ============================================================
-- 17.1 RPCs COMPLEMENTARES DE HIERARQUIA E PORTFÓLIO
-- ============================================================

create or replace function public.set_skpe_initiative_parent(
  p_formulation_id uuid,
  p_initiative_id uuid,
  p_parent_initiative_id uuid,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  initiative_row public.skpe_initiatives%rowtype;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  select * into initiative_row
  from public.skpe_initiatives
  where id = p_initiative_id
    and organization_id = formulation_row.organization_id
    and project_id = formulation_row.project_id
    and archived_at is null
  for update;

  if not found then
    raise exception 'Iniciativa não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(initiative_row.organization_id) then
    raise exception 'Acesso negado para alterar a hierarquia.' using errcode = '42501';
  end if;

  perform public.skpe_assert_initiative_hierarchy(
    initiative_row.id,
    p_parent_initiative_id,
    initiative_row.organization_id,
    initiative_row.project_id,
    initiative_row.initiative_class
  );

  update public.skpe_initiatives
  set parent_initiative_id = p_parent_initiative_id,
      updated_by = auth.uid(),
      last_update_at = timezone('utc', now())
  where id = p_initiative_id
  returning to_jsonb(skpe_initiatives) into new_data;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Hierarquia da Iniciativa alterada.'
  );

  perform public.skpe_record_operational_audit(
    initiative_row.organization_id,
    initiative_row.project_id,
    'initiative',
    p_initiative_id,
    'fe07.initiative_parent_changed',
    p_change_reason,
    to_jsonb(initiative_row),
    new_data
  );
end;
$$;

create or replace function public.set_skpe_initiative_portfolio_decision(
  p_formulation_id uuid,
  p_initiative_id uuid,
  p_selection_status text,
  p_portfolio_priority text,
  p_rank_position integer,
  p_decision_reason text,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  item_row public.skpe_initiative_portfolio_items%rowtype;
  new_data jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para decidir o portfólio.' using errcode = '42501';
  end if;

  select * into item_row
  from public.skpe_initiative_portfolio_items
  where formulation_id = p_formulation_id
    and initiative_id = p_initiative_id
  for update;

  if not found then
    raise exception 'Item de portfólio não encontrado.' using errcode = '22023';
  end if;

  update public.skpe_initiative_portfolio_items
  set
    selection_status = p_selection_status,
    portfolio_priority = coalesce(p_portfolio_priority, portfolio_priority),
    rank_position = p_rank_position,
    decision_reason = nullif(trim(p_decision_reason), ''),
    selected_at = case
      when p_selection_status = 'selected'
        then coalesce(selected_at, timezone('utc', now()))
      else null
    end,
    selected_by = case
      when p_selection_status = 'selected'
        then coalesce(selected_by, auth.uid())
      else null
    end,
    validation_status = 'draft',
    updated_by = auth.uid()
  where id = item_row.id
  returning to_jsonb(skpe_initiative_portfolio_items) into new_data;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Decisão de portfólio alterada.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_portfolio_item',
    item_row.id,
    'fe07.portfolio_decision_changed',
    p_change_reason,
    to_jsonb(item_row),
    new_data
  );
end;
$$;

create or replace function public.reorder_skpe_initiative_portfolio(
  p_formulation_id uuid,
  p_ordering jsonb,
  p_change_reason text
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  order_item jsonb;
  changed_count integer := 0;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para reordenar o portfólio.' using errcode = '42501';
  end if;

  if jsonb_typeof(p_ordering) <> 'array' then
    raise exception 'A ordenação deve ser fornecida como array JSON.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_ordering) element
    group by (element ->> 'rankPosition')::integer
    having count(*) > 1
  ) then
    raise exception 'A ordenação contém posições duplicadas.' using errcode = '22023';
  end if;

  update public.skpe_initiative_portfolio_items item
  set rank_position = null,
      validation_status = 'draft',
      updated_by = auth.uid()
  where item.formulation_id = p_formulation_id
    and item.selection_status = 'selected'
    and item.id in (
      select (element ->> 'portfolioItemId')::uuid
      from jsonb_array_elements(p_ordering) element
    );

  for order_item in select value from jsonb_array_elements(p_ordering)
  loop
    update public.skpe_initiative_portfolio_items
    set rank_position = (order_item ->> 'rankPosition')::integer,
        validation_status = 'draft',
        updated_by = auth.uid()
    where id = (order_item ->> 'portfolioItemId')::uuid
      and formulation_id = p_formulation_id
      and selection_status = 'selected';

    changed_count := changed_count + case when found then 1 else 0 end;
  end loop;

  perform public.skpe_invalidate_initiative_package(
    p_formulation_id,
    'Ordenação do portfólio alterada.'
  );

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'initiative_package',
    (select id from public.skpe_initiative_packages where formulation_id = p_formulation_id),
    'fe07.portfolio_reordered',
    p_change_reason,
    null,
    jsonb_build_object('ordering', p_ordering, 'changedCount', changed_count)
  );

  return changed_count;
end;
$$;

create or replace function public.set_skpe_initiative_action_parent(
  p_action_id uuid,
  p_parent_action_id uuid,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  action_row public.skpe_initiative_actions%rowtype;
  new_data jsonb;
  affected_formulation_id uuid;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into action_row
  from public.skpe_initiative_actions
  where id = p_action_id
    and archived_at is null
  for update;

  if not found then
    raise exception 'Ação não encontrada.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(action_row.organization_id) then
    raise exception 'Acesso negado para alterar a hierarquia de ações.' using errcode = '42501';
  end if;

  if p_parent_action_id = p_action_id then
    raise exception 'Uma ação não pode ser pai de si própria.' using errcode = '22023';
  end if;

  if p_parent_action_id is not null and not exists (
    select 1 from public.skpe_initiative_actions parent_action
    where parent_action.id = p_parent_action_id
      and parent_action.initiative_id = action_row.initiative_id
      and parent_action.archived_at is null
  ) then
    raise exception 'Ação pai não pertence à mesma Iniciativa.' using errcode = '22023';
  end if;

  if p_parent_action_id is not null and exists (
    with recursive descendants as (
      select child.id
      from public.skpe_initiative_actions child
      where child.parent_action_id = p_action_id
        and child.archived_at is null
      union all
      select child.id
      from public.skpe_initiative_actions child
      join descendants current_descendant
        on child.parent_action_id = current_descendant.id
      where child.archived_at is null
    )
    select 1 from descendants where id = p_parent_action_id
  ) then
    raise exception 'A hierarquia de ações criaria um ciclo.' using errcode = '22023';
  end if;

  update public.skpe_initiative_actions
  set parent_action_id = p_parent_action_id,
      validation_status = 'draft',
      updated_by = auth.uid()
  where id = p_action_id
  returning to_jsonb(skpe_initiative_actions) into new_data;

  for affected_formulation_id in
    select item.formulation_id
    from public.skpe_initiative_portfolio_items item
    join public.skpe_strategic_formulations formulation
      on formulation.id = item.formulation_id
    where item.initiative_id = action_row.initiative_id
      and formulation.status in ('draft', 'in_elaboration')
  loop
    perform public.skpe_invalidate_initiative_package(
      affected_formulation_id,
      'Hierarquia de ações alterada.'
    );
  end loop;

  perform public.skpe_record_operational_audit(
    action_row.organization_id,
    action_row.project_id,
    'initiative_action',
    p_action_id,
    'fe07.action_parent_changed',
    p_change_reason,
    to_jsonb(action_row),
    new_data
  );
end;
$$;

create or replace function public.update_skpe_initiative_risk_assessment(
  p_risk_id uuid,
  p_probability integer,
  p_impact integer,
  p_residual_probability integer,
  p_residual_impact integer,
  p_response_type text,
  p_response_plan text,
  p_owner_user_id uuid,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  risk_row public.skpe_initiative_risks%rowtype;
  new_data jsonb;
  affected_formulation_id uuid;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into risk_row
  from public.skpe_initiative_risks
  where id = p_risk_id
    and archived_at is null
  for update;

  if not found then
    raise exception 'Risco não encontrado.' using errcode = '22023';
  end if;

  if not public.can_manage_skpe_initiatives(risk_row.organization_id) then
    raise exception 'Acesso negado para avaliar o risco.' using errcode = '42501';
  end if;

  update public.skpe_initiative_risks
  set probability = p_probability,
      impact = p_impact,
      residual_probability = p_residual_probability,
      residual_impact = p_residual_impact,
      response_type = p_response_type,
      response_plan = nullif(trim(p_response_plan), ''),
      owner_user_id = p_owner_user_id,
      status = case
        when length(trim(coalesce(p_response_plan, ''))) >= 10
          then 'response_planned'
        else 'assessed'
      end,
      validation_status = 'draft',
      updated_by = auth.uid()
  where id = p_risk_id
  returning to_jsonb(skpe_initiative_risks) into new_data;

  for affected_formulation_id in
    select item.formulation_id
    from public.skpe_initiative_portfolio_items item
    join public.skpe_strategic_formulations formulation
      on formulation.id = item.formulation_id
    where item.initiative_id = risk_row.initiative_id
      and formulation.status in ('draft', 'in_elaboration')
  loop
    perform public.skpe_invalidate_initiative_package(
      affected_formulation_id,
      'Avaliação de risco alterada.'
    );
  end loop;

  perform public.skpe_record_operational_audit(
    risk_row.organization_id,
    risk_row.project_id,
    'initiative_risk',
    p_risk_id,
    'fe07.risk_assessment_updated',
    p_change_reason,
    to_jsonb(risk_row),
    new_data
  );
end;
$$;

create or replace function public.get_skpe_initiatives_portfolio(
  p_formulation_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    public.get_skpe_initiatives_package(p_formulation_id) -> 'portfolio',
    '[]'::jsonb
  );
$$;

-- ============================================================
-- 18. PRIVILÉGIOS, HARDENING E DESATIVAÇÃO DE RPCs LEGADAS
-- ============================================================

revoke insert, update, delete, truncate
on table public.skpe_initiatives,
         public.skpe_initiative_objectives,
         public.skpe_initiative_instruments,
         public.skpe_initiative_key_results,
         public.skpe_initiative_packages,
         public.skpe_initiative_portfolio_items,
         public.skpe_initiative_actions,
         public.skpe_initiative_dependencies,
         public.skpe_initiative_risks,
         public.skpe_initiative_outcomes
from public, anon, authenticated;

revoke all
on table public.skpe_initiative_packages,
         public.skpe_initiative_portfolio_items,
         public.skpe_initiative_actions,
         public.skpe_initiative_dependencies,
         public.skpe_initiative_risks,
         public.skpe_initiative_outcomes
from anon;

grant select
on table public.skpe_initiatives,
         public.skpe_initiative_objectives,
         public.skpe_initiative_instruments,
         public.skpe_initiative_key_results,
         public.skpe_initiative_packages,
         public.skpe_initiative_portfolio_items,
         public.skpe_initiative_actions,
         public.skpe_initiative_dependencies,
         public.skpe_initiative_risks,
         public.skpe_initiative_outcomes
to authenticated, service_role;

grant insert, update, delete
on table public.skpe_initiatives,
         public.skpe_initiative_objectives,
         public.skpe_initiative_instruments,
         public.skpe_initiative_key_results,
         public.skpe_initiative_packages,
         public.skpe_initiative_portfolio_items,
         public.skpe_initiative_actions,
         public.skpe_initiative_dependencies,
         public.skpe_initiative_risks,
         public.skpe_initiative_outcomes
to service_role;

-- Remove execução autenticada das mutações legadas quando existentes.
do $$
begin
  if to_regprocedure('public.create_skpe_initiative(uuid,text,text,text,text,text,text,uuid,uuid,date,date,numeric,numeric,text,uuid,uuid,text)') is not null then
    execute 'revoke all on function public.create_skpe_initiative(uuid,text,text,text,text,text,text,uuid,uuid,date,date,numeric,numeric,text,uuid,uuid,text) from public, anon, authenticated';
  end if;

  if to_regprocedure('public.create_skpe_initiative_v2(uuid,text,text,text,text,text,text,text,text,uuid,uuid,date,date,numeric,numeric,text,text,text,text,text,text,text,text,uuid,uuid,text)') is not null then
    execute 'revoke all on function public.create_skpe_initiative_v2(uuid,text,text,text,text,text,text,text,text,uuid,uuid,date,date,numeric,numeric,text,text,text,text,text,text,text,text,uuid,uuid,text) from public, anon, authenticated';
  end if;

  if to_regprocedure('public.update_skpe_initiative_status(uuid,text,numeric,text,numeric,numeric,text)') is not null then
    execute 'revoke all on function public.update_skpe_initiative_status(uuid,text,numeric,text,numeric,numeric,text) from public, anon, authenticated';
  end if;

  if to_regprocedure('public.link_skpe_initiative_objective(uuid,uuid,text,numeric,text,text)') is not null then
    execute 'revoke all on function public.link_skpe_initiative_objective(uuid,uuid,text,numeric,text,text) from public, anon, authenticated';
  end if;

  if to_regprocedure('public.link_skpe_initiative_key_result(uuid,uuid,text,numeric,text,text)') is not null then
    execute 'revoke all on function public.link_skpe_initiative_key_result(uuid,uuid,text,numeric,text,text) from public, anon, authenticated';
  end if;
end;
$$;

-- Funções internas sem execução por usuários comuns.
revoke all on function public.skpe_assert_fe07_responsible_area(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_initiative_hierarchy_would_create_cycle(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_assert_initiative_hierarchy(uuid, uuid, uuid, uuid, text)
  from public, anon, authenticated;
revoke all on function public.skpe_calculate_initiative_portfolio_score(uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_dependency_would_create_cycle(uuid, uuid, uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.ensure_skpe_initiative_package(uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_invalidate_initiative_package(uuid, text)
  from public, anon, authenticated;
revoke all on function public.skpe_capture_initiative_validation_snapshot(uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_guard_initiative_versioned_operational_content()
  from public, anon, authenticated;
revoke all on function public.skpe_guard_formulation_initiatives_ready()
  from public, anon, authenticated;

-- RPCs públicas: execução somente para usuários autenticados e service_role.
revoke all on function public.set_skpe_initiative_parent(uuid, uuid, uuid, text)
  from public, anon;
revoke all on function public.set_skpe_initiative_portfolio_decision(uuid, uuid, text, text, integer, text, text)
  from public, anon;
revoke all on function public.reorder_skpe_initiative_portfolio(uuid, jsonb, text)
  from public, anon;
revoke all on function public.set_skpe_initiative_action_parent(uuid, uuid, text)
  from public, anon;
revoke all on function public.update_skpe_initiative_risk_assessment(uuid, integer, integer, integer, integer, text, text, uuid, text)
  from public, anon;
revoke all on function public.get_skpe_initiatives_portfolio(uuid)
  from public, anon;
revoke all on function public.configure_skpe_initiative_package(uuid, jsonb, text)
  from public, anon;
revoke all on function public.upsert_skpe_initiative(uuid, uuid, jsonb, text)
  from public, anon;
revoke all on function public.archive_skpe_initiative(uuid, uuid, text)
  from public, anon;
revoke all on function public.update_skpe_initiative_operational_progress(uuid, text, numeric, numeric, numeric, text, text, text)
  from public, anon;
revoke all on function public.upsert_skpe_initiative_portfolio_item(uuid, uuid, jsonb, text)
  from public, anon;
revoke all on function public.recalculate_skpe_initiative_portfolio_scores(uuid, text)
  from public, anon;
revoke all on function public.link_skpe_initiative_objective(uuid, uuid, uuid, text, numeric, text, text)
  from public, anon;
revoke all on function public.unlink_skpe_initiative_objective(uuid, uuid, uuid, text)
  from public, anon;
revoke all on function public.link_skpe_initiative_key_result(uuid, uuid, uuid, text, numeric, text, text)
  from public, anon;
revoke all on function public.unlink_skpe_initiative_key_result(uuid, uuid, uuid, text)
  from public, anon;
revoke all on function public.upsert_skpe_initiative_action(uuid, uuid, jsonb, text)
  from public, anon;
revoke all on function public.update_skpe_initiative_action_progress(uuid, text, numeric, numeric, text)
  from public, anon;
revoke all on function public.archive_skpe_initiative_action(uuid, text)
  from public, anon;
revoke all on function public.upsert_skpe_initiative_dependency(uuid, uuid, jsonb, text)
  from public, anon;
revoke all on function public.transition_skpe_initiative_dependency(uuid, text, text)
  from public, anon;
revoke all on function public.upsert_skpe_initiative_risk(uuid, uuid, jsonb, text)
  from public, anon;
revoke all on function public.transition_skpe_initiative_risk(uuid, text, text)
  from public, anon;
revoke all on function public.upsert_skpe_initiative_outcome(uuid, uuid, uuid, jsonb, text)
  from public, anon;
revoke all on function public.update_skpe_initiative_outcome_progress(uuid, numeric, text, text)
  from public, anon;
revoke all on function public.archive_skpe_initiative_outcome(uuid, uuid, text)
  from public, anon;
revoke all on function public.transition_skpe_initiative_package(uuid, text, text, text)
  from public, anon;
revoke all on function public.get_skpe_initiatives_readiness(uuid, boolean)
  from public, anon;
revoke all on function public.get_skpe_initiatives_package(uuid)
  from public, anon;
revoke all on function public.get_skpe_initiatives_audit(uuid)
  from public, anon;

grant execute on function public.set_skpe_initiative_parent(uuid, uuid, uuid, text)
  to authenticated, service_role;
grant execute on function public.set_skpe_initiative_portfolio_decision(uuid, uuid, text, text, integer, text, text)
  to authenticated, service_role;
grant execute on function public.reorder_skpe_initiative_portfolio(uuid, jsonb, text)
  to authenticated, service_role;
grant execute on function public.set_skpe_initiative_action_parent(uuid, uuid, text)
  to authenticated, service_role;
grant execute on function public.update_skpe_initiative_risk_assessment(uuid, integer, integer, integer, integer, text, text, uuid, text)
  to authenticated, service_role;
grant execute on function public.get_skpe_initiatives_portfolio(uuid)
  to authenticated, service_role;
grant execute on function public.configure_skpe_initiative_package(uuid, jsonb, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_initiative(uuid, uuid, jsonb, text)
  to authenticated, service_role;
grant execute on function public.archive_skpe_initiative(uuid, uuid, text)
  to authenticated, service_role;
grant execute on function public.update_skpe_initiative_operational_progress(uuid, text, numeric, numeric, numeric, text, text, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_initiative_portfolio_item(uuid, uuid, jsonb, text)
  to authenticated, service_role;
grant execute on function public.recalculate_skpe_initiative_portfolio_scores(uuid, text)
  to authenticated, service_role;
grant execute on function public.link_skpe_initiative_objective(uuid, uuid, uuid, text, numeric, text, text)
  to authenticated, service_role;
grant execute on function public.unlink_skpe_initiative_objective(uuid, uuid, uuid, text)
  to authenticated, service_role;
grant execute on function public.link_skpe_initiative_key_result(uuid, uuid, uuid, text, numeric, text, text)
  to authenticated, service_role;
grant execute on function public.unlink_skpe_initiative_key_result(uuid, uuid, uuid, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_initiative_action(uuid, uuid, jsonb, text)
  to authenticated, service_role;
grant execute on function public.update_skpe_initiative_action_progress(uuid, text, numeric, numeric, text)
  to authenticated, service_role;
grant execute on function public.archive_skpe_initiative_action(uuid, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_initiative_dependency(uuid, uuid, jsonb, text)
  to authenticated, service_role;
grant execute on function public.transition_skpe_initiative_dependency(uuid, text, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_initiative_risk(uuid, uuid, jsonb, text)
  to authenticated, service_role;
grant execute on function public.transition_skpe_initiative_risk(uuid, text, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_initiative_outcome(uuid, uuid, uuid, jsonb, text)
  to authenticated, service_role;
grant execute on function public.update_skpe_initiative_outcome_progress(uuid, numeric, text, text)
  to authenticated, service_role;
grant execute on function public.archive_skpe_initiative_outcome(uuid, uuid, text)
  to authenticated, service_role;
grant execute on function public.transition_skpe_initiative_package(uuid, text, text, text)
  to authenticated, service_role;
grant execute on function public.get_skpe_initiatives_readiness(uuid, boolean)
  to authenticated, service_role;
grant execute on function public.get_skpe_initiatives_package(uuid)
  to authenticated, service_role;
grant execute on function public.get_skpe_initiatives_audit(uuid)
  to authenticated, service_role;

comment on function public.get_skpe_initiatives_readiness(uuid, boolean) is
  'Avalia bloqueios, recomendações e métricas metodológicas do pacote FE-07.';
comment on function public.get_skpe_initiatives_package(uuid) is
  'Retorna o contrato consolidado da FE-07 para futura interface, incluindo portfólio, rastreabilidade, ações, riscos, dependências e resultados.';
comment on function public.transition_skpe_initiative_package(uuid, text, text, text) is
  'Controla submissão, validação e devolução do pacote FE-07, com snapshot e auditoria.';

commit;
