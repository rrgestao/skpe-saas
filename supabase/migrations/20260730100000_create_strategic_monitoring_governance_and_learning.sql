-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-08 — Monitoramento, Governança e Aprendizado Estratégico
--
-- Escopo:
-- 1. Pacote metodológico de monitoramento por Formulação.
-- 2. Ciclos periódicos de acompanhamento e fechamento.
-- 3. Séries históricas append-only de KPIs, KRs, Iniciativas e resultados.
-- 4. RAE, itens de análise, decisões e aprendizados estratégicos.
-- 5. Snapshots imutáveis de desempenho por ciclo.
-- 6. RLS, escrita exclusivamente por RPCs auditadas e segregação de funções.
--
-- Fora de escopo:
-- - interface React e dashboards definitivos;
-- - integração contábil, timesheet ou Gantt detalhado;
-- - substituição de módulos especializados de riscos, finanças ou documentos;
-- - dados específicos de qualquer organização.
-- ============================================================

begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- ============================================================
-- 1. PERMISSÕES E AUTORIZAÇÃO
-- ============================================================

insert into public.module_permissions (
  module_id, code, name, description, permission_group, active
)
select
  module.id,
  permission_data.code,
  permission_data.name,
  permission_data.description,
  permission_data.permission_group,
  true
from public.modules module
cross join (
  values
    (
      'strategic_monitoring.view',
      'Consultar Monitoramento Estratégico',
      'Permite consultar ciclos, medições, check-ins, desempenho, RAEs, decisões, aprendizados e snapshots.',
      'strategic_monitoring'
    ),
    (
      'strategic_monitoring.manage',
      'Gerenciar Monitoramento Estratégico',
      'Permite abrir ciclos e registrar medições e check-ins operacionais auditados.',
      'strategic_monitoring'
    ),
    (
      'strategic_governance.manage',
      'Gerenciar Governança Estratégica',
      'Permite preparar e conduzir RAEs, registrar análises, decisões e aprendizados.',
      'strategic_governance'
    ),
    (
      'strategic_governance.ratify',
      'Ratificar Governança Estratégica',
      'Permite ratificar RAEs, decisões e o fechamento formal de ciclos de monitoramento.',
      'strategic_governance'
    )
) as permission_data(code, name, description, permission_group)
where module.code = 'SK-PE'
on conflict (module_id, code) do update
set
  name = excluded.name,
  description = excluded.description,
  permission_group = excluded.permission_group,
  active = true;

insert into public.role_permissions (module_role_id, module_permission_id)
select role.id, permission.id
from public.module_roles role
join public.modules module on module.id = role.module_id
join public.module_permissions permission on permission.module_id = module.id
where module.code = 'SK-PE'
  and (
    (role.code in ('administrator', 'manager') and permission.code in (
      'strategic_monitoring.view',
      'strategic_monitoring.manage',
      'strategic_governance.manage',
      'strategic_governance.ratify'
    ))
    or (role.code = 'editor' and permission.code in (
      'strategic_monitoring.view',
      'strategic_monitoring.manage'
    ))
    or (role.code = 'approver' and permission.code in (
      'strategic_monitoring.view',
      'strategic_governance.manage',
      'strategic_governance.ratify'
    ))
    or (role.code in ('viewer', 'visitor') and permission.code = 'strategic_monitoring.view')
  )
on conflict do nothing;

create or replace function public.can_view_skpe_monitoring(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_monitoring.view')
    or public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_monitoring.manage')
    or public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_governance.manage')
    or public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_governance.ratify');
$$;

create or replace function public.can_manage_skpe_monitoring(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_monitoring.manage');
$$;

create or replace function public.can_manage_skpe_governance(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_governance.manage')
    or public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_governance.ratify');
$$;

create or replace function public.can_ratify_skpe_governance(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_governance.ratify');
$$;

-- ============================================================
-- 2. PACOTE METODOLÓGICO E CICLOS
-- ============================================================

create table if not exists public.skpe_monitoring_packages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  status text not null default 'in_elaboration',
  cycle_frequency text not null default 'monthly',
  review_frequency text not null default 'quarterly',
  cycle_overlap_policy text not null default 'block',
  evidence_required boolean not null default true,
  data_quality_required boolean not null default true,
  confidence_required_for_key_results boolean not null default true,
  allow_manual_progress_override boolean not null default false,
  data_freshness_days integer not null default 45,
  late_tolerance_days integer not null default 5,
  aggregation_policy text not null default 'explicit_weight',
  critical_threshold numeric(5,2) not null default 50,
  attention_threshold numeric(5,2) not null default 75,
  on_track_threshold numeric(5,2) not null default 100,
  owner_user_id uuid references public.profiles(id) on delete set null,
  governance_owner_user_id uuid references public.profiles(id) on delete set null,
  validation_notes text,
  submitted_for_validation_at timestamptz,
  submitted_for_validation_by uuid references public.profiles(id) on delete set null,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_monitoring_packages_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(id, organization_id, project_id)
    on delete cascade,
  constraint skpe_monitoring_packages_status_check
    check (status in ('in_elaboration', 'pending_validation', 'validated')),
  constraint skpe_monitoring_packages_cycle_frequency_check
    check (cycle_frequency in ('monthly', 'quarterly', 'semester', 'annual', 'custom')),
  constraint skpe_monitoring_packages_review_frequency_check
    check (review_frequency in ('monthly', 'quarterly', 'semester', 'annual', 'custom')),
  constraint skpe_monitoring_packages_overlap_check
    check (cycle_overlap_policy in ('allow', 'warn', 'block')),
  constraint skpe_monitoring_packages_freshness_check
    check (data_freshness_days between 1 and 730),
  constraint skpe_monitoring_packages_late_tolerance_check
    check (late_tolerance_days between 0 and 365),
  constraint skpe_monitoring_packages_aggregation_check
    check (aggregation_policy in ('equal_weight', 'explicit_weight')),
  constraint skpe_monitoring_packages_thresholds_check
    check (
      critical_threshold between 0 and 100
      and attention_threshold between critical_threshold and 100
      and on_track_threshold between attention_threshold and 100
    ),
  constraint skpe_monitoring_packages_unique unique (formulation_id),
  constraint skpe_monitoring_packages_scope_unique
    unique (id, formulation_id, organization_id, project_id)
);

create table if not exists public.skpe_monitoring_cycles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  monitoring_package_id uuid not null,
  code text not null,
  name text not null,
  cycle_type text not null default 'monthly',
  period_start date not null,
  period_end date not null,
  cutoff_date date,
  status text not null default 'planned',
  owner_user_id uuid references public.profiles(id) on delete set null,
  governance_owner_user_id uuid references public.profiles(id) on delete set null,
  opened_at timestamptz,
  opened_by uuid references public.profiles(id) on delete set null,
  submitted_for_review_at timestamptz,
  submitted_for_review_by uuid references public.profiles(id) on delete set null,
  closed_at timestamptz,
  closed_by uuid references public.profiles(id) on delete set null,
  cancellation_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_monitoring_cycles_package_fkey
    foreign key (monitoring_package_id, formulation_id, organization_id, project_id)
    references public.skpe_monitoring_packages(id, formulation_id, organization_id, project_id)
    on delete cascade,
  constraint skpe_monitoring_cycles_code_not_blank check (length(trim(code)) > 0),
  constraint skpe_monitoring_cycles_name_not_blank check (length(trim(name)) > 0),
  constraint skpe_monitoring_cycles_type_check
    check (cycle_type in ('monthly', 'quarterly', 'semester', 'annual', 'custom')),
  constraint skpe_monitoring_cycles_dates_check check (period_end >= period_start),
  constraint skpe_monitoring_cycles_cutoff_check
    check (cutoff_date is null or cutoff_date >= period_start),
  constraint skpe_monitoring_cycles_status_check
    check (status in (
      'planned', 'open', 'collecting', 'under_review',
      'pending_ratification', 'closed', 'cancelled', 'reopened'
    )),
  constraint skpe_monitoring_cycles_unique unique (formulation_id, code),
  constraint skpe_monitoring_cycles_scope_unique
    unique (id, formulation_id, organization_id, project_id)
);

-- ============================================================
-- 3. SÉRIES HISTÓRICAS APPEND-ONLY
-- ============================================================

create table if not exists public.skpe_indicator_measurements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  monitoring_cycle_id uuid not null,
  indicator_id uuid not null references public.skpe_indicators(id) on delete cascade,
  indicator_target_id uuid references public.skpe_indicator_targets(id) on delete set null,
  measurement_date date not null,
  period_start date,
  period_end date,
  measured_value numeric not null,
  automatic_performance numeric(7,2),
  manual_performance_override numeric(7,2),
  effective_performance numeric(7,2),
  status text not null default 'submitted',
  data_quality text not null default 'not_assessed',
  source_name text,
  source_reference text,
  evidence_reference text,
  notes text,
  supersedes_measurement_id uuid references public.skpe_indicator_measurements(id) on delete set null,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint skpe_indicator_measurements_cycle_fkey
    foreign key (monitoring_cycle_id, formulation_id, organization_id, project_id)
    references public.skpe_monitoring_cycles(id, formulation_id, organization_id, project_id)
    on delete cascade,
  constraint skpe_indicator_measurements_dates_check
    check (period_end is null or period_start is null or period_end >= period_start),
  constraint skpe_indicator_measurements_performance_check
    check (
      (automatic_performance is null or automatic_performance between 0 and 100)
      and (manual_performance_override is null or manual_performance_override between 0 and 100)
      and (effective_performance is null or effective_performance between 0 and 100)
    ),
  constraint skpe_indicator_measurements_status_check
    check (status in ('submitted', 'validated', 'rejected', 'superseded')),
  constraint skpe_indicator_measurements_quality_check
    check (data_quality in ('not_assessed', 'low', 'medium', 'high', 'verified')),
  constraint skpe_indicator_measurements_no_self_supersession
    check (supersedes_measurement_id is null or supersedes_measurement_id <> id)
);

create table if not exists public.skpe_key_result_check_ins (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  monitoring_cycle_id uuid not null,
  key_result_id uuid not null references public.skpe_key_results(id) on delete cascade,
  check_in_date date not null,
  current_value numeric not null,
  automatic_progress numeric(7,2),
  manual_progress_override numeric(7,2),
  effective_progress numeric(7,2) not null,
  operational_status text not null,
  health_status text not null default 'not_assessed',
  confidence_level text not null default 'not_assessed',
  forecast_value numeric,
  forecast_date date,
  blockers text,
  notes text,
  evidence_reference text,
  status text not null default 'submitted',
  supersedes_check_in_id uuid references public.skpe_key_result_check_ins(id) on delete set null,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint skpe_key_result_check_ins_cycle_fkey
    foreign key (monitoring_cycle_id, formulation_id, organization_id, project_id)
    references public.skpe_monitoring_cycles(id, formulation_id, organization_id, project_id)
    on delete cascade,
  constraint skpe_key_result_check_ins_progress_check
    check (
      automatic_progress is null or automatic_progress between 0 and 100
    ),
  constraint skpe_key_result_check_ins_manual_progress_check
    check (manual_progress_override is null or manual_progress_override between 0 and 100),
  constraint skpe_key_result_check_ins_effective_progress_check
    check (effective_progress between 0 and 100),
  constraint skpe_key_result_check_ins_operational_status_check
    check (operational_status in ('draft', 'active', 'at_risk', 'achieved', 'not_achieved')),
  constraint skpe_key_result_check_ins_health_check
    check (health_status in ('not_assessed', 'on_track', 'attention', 'critical')),
  constraint skpe_key_result_check_ins_confidence_check
    check (confidence_level in ('not_assessed', 'low', 'medium', 'high')),
  constraint skpe_key_result_check_ins_status_check
    check (status in ('submitted', 'validated', 'rejected', 'superseded')),
  constraint skpe_key_result_check_ins_no_self_supersession
    check (supersedes_check_in_id is null or supersedes_check_in_id <> id)
);

create table if not exists public.skpe_initiative_check_ins (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  monitoring_cycle_id uuid not null,
  initiative_id uuid not null,
  check_in_date date not null,
  progress numeric(7,2) not null,
  operational_status text not null,
  health_status text not null default 'not_assessed',
  risk_level text not null default 'not_assessed',
  actual_cost numeric(18,2),
  realized_benefit numeric(18,2),
  forecast_end_date date,
  milestones_summary text,
  delays_text text,
  blockers text,
  decision_required text,
  notes text,
  evidence_reference text,
  status text not null default 'submitted',
  supersedes_check_in_id uuid references public.skpe_initiative_check_ins(id) on delete set null,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint skpe_initiative_check_ins_cycle_fkey
    foreign key (monitoring_cycle_id, formulation_id, organization_id, project_id)
    references public.skpe_monitoring_cycles(id, formulation_id, organization_id, project_id)
    on delete cascade,
  constraint skpe_initiative_check_ins_initiative_fkey
    foreign key (initiative_id, organization_id, project_id)
    references public.skpe_initiatives(id, organization_id, project_id)
    on delete cascade,
  constraint skpe_initiative_check_ins_progress_check check (progress between 0 and 100),
  constraint skpe_initiative_check_ins_status_check
    check (length(trim(operational_status)) > 0),
  constraint skpe_initiative_check_ins_health_check
    check (length(trim(health_status)) > 0),
  constraint skpe_initiative_check_ins_risk_check
    check (length(trim(risk_level)) > 0),
  constraint skpe_initiative_check_ins_cost_check
    check (coalesce(actual_cost, 0) >= 0 and coalesce(realized_benefit, 0) >= 0),
  constraint skpe_initiative_check_ins_record_status_check
    check (status in ('submitted', 'validated', 'rejected', 'superseded')),
  constraint skpe_initiative_check_ins_no_self_supersession
    check (supersedes_check_in_id is null or supersedes_check_in_id <> id)
);

create table if not exists public.skpe_initiative_outcome_measurements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  monitoring_cycle_id uuid not null,
  initiative_outcome_id uuid not null references public.skpe_initiative_outcomes(id) on delete cascade,
  measurement_date date not null,
  measured_value numeric,
  qualitative_assessment text,
  effective_performance numeric(7,2),
  outcome_status text not null,
  evidence_reference text,
  notes text,
  status text not null default 'submitted',
  supersedes_measurement_id uuid references public.skpe_initiative_outcome_measurements(id) on delete set null,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint skpe_initiative_outcome_measurements_cycle_fkey
    foreign key (monitoring_cycle_id, formulation_id, organization_id, project_id)
    references public.skpe_monitoring_cycles(id, formulation_id, organization_id, project_id)
    on delete cascade,
  constraint skpe_initiative_outcome_measurements_content_check
    check (measured_value is not null or length(trim(coalesce(qualitative_assessment, ''))) > 0),
  constraint skpe_initiative_outcome_measurements_performance_check
    check (effective_performance is null or effective_performance between 0 and 100),
  constraint skpe_initiative_outcome_measurements_outcome_status_check
    check (outcome_status in (
      'planned', 'in_progress', 'achieved', 'partially_achieved',
      'not_achieved', 'cancelled', 'archived'
    )),
  constraint skpe_initiative_outcome_measurements_status_check
    check (status in ('submitted', 'validated', 'rejected', 'superseded')),
  constraint skpe_initiative_outcome_measurements_no_self_supersession
    check (supersedes_measurement_id is null or supersedes_measurement_id <> id)
);

-- ============================================================
-- 4. RAE, DECISÕES, APRENDIZADOS E SNAPSHOTS
-- ============================================================

create table if not exists public.skpe_strategy_reviews (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  monitoring_cycle_id uuid not null,
  code text not null,
  title text not null,
  review_type text not null default 'rae',
  status text not null default 'draft',
  scheduled_at timestamptz,
  held_at timestamptz,
  chair_user_id uuid references public.profiles(id) on delete set null,
  secretary_user_id uuid references public.profiles(id) on delete set null,
  participants jsonb not null default '[]'::jsonb,
  executive_summary text,
  conclusions text,
  minutes_reference text,
  ratified_at timestamptz,
  ratified_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategy_reviews_cycle_fkey
    foreign key (monitoring_cycle_id, formulation_id, organization_id, project_id)
    references public.skpe_monitoring_cycles(id, formulation_id, organization_id, project_id)
    on delete cascade,
  constraint skpe_strategy_reviews_code_not_blank check (length(trim(code)) > 0),
  constraint skpe_strategy_reviews_title_not_blank check (length(trim(title)) > 0),
  constraint skpe_strategy_reviews_type_check
    check (review_type in ('rae', 'executive', 'governance', 'assembly', 'extraordinary')),
  constraint skpe_strategy_reviews_status_check
    check (status in (
      'draft', 'scheduled', 'in_progress', 'pending_ratification',
      'ratified', 'closed', 'cancelled'
    )),
  constraint skpe_strategy_reviews_unique unique (monitoring_cycle_id, code),
  constraint skpe_strategy_reviews_scope_unique
    unique (id, formulation_id, organization_id, project_id)
);

create table if not exists public.skpe_strategy_review_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  strategy_review_id uuid not null,
  entity_type text not null,
  strategic_theme_id uuid references public.skpe_strategic_themes(id) on delete set null,
  strategic_objective_id uuid references public.skpe_strategic_objectives(id) on delete set null,
  indicator_id uuid references public.skpe_indicators(id) on delete set null,
  okr_id uuid references public.skpe_okrs(id) on delete set null,
  key_result_id uuid references public.skpe_key_results(id) on delete set null,
  initiative_id uuid references public.skpe_initiatives(id) on delete set null,
  initiative_action_id uuid references public.skpe_initiative_actions(id) on delete set null,
  initiative_risk_id uuid references public.skpe_initiative_risks(id) on delete set null,
  initiative_outcome_id uuid references public.skpe_initiative_outcomes(id) on delete set null,
  performance_status text not null default 'not_assessed',
  finding_type text not null default 'information',
  analysis_text text,
  root_cause text,
  recommendation text,
  requires_decision boolean not null default false,
  display_order integer not null default 0,
  status text not null default 'open',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategy_review_items_review_fkey
    foreign key (strategy_review_id, formulation_id, organization_id, project_id)
    references public.skpe_strategy_reviews(id, formulation_id, organization_id, project_id)
    on delete cascade,
  constraint skpe_strategy_review_items_entity_type_check
    check (entity_type in (
      'strategic_theme', 'strategic_objective', 'indicator', 'okr', 'key_result',
      'initiative', 'initiative_action', 'initiative_risk', 'initiative_outcome'
    )),
  constraint skpe_strategy_review_items_single_entity_check
    check (num_nonnulls(
      strategic_theme_id, strategic_objective_id, indicator_id, okr_id,
      key_result_id, initiative_id, initiative_action_id,
      initiative_risk_id, initiative_outcome_id
    ) = 1),
  constraint skpe_strategy_review_items_performance_check
    check (performance_status in ('not_assessed', 'on_track', 'attention', 'critical', 'achieved')),
  constraint skpe_strategy_review_items_finding_check
    check (finding_type in ('information', 'deviation', 'risk', 'opportunity', 'decision', 'learning')),
  constraint skpe_strategy_review_items_status_check
    check (status in ('open', 'analyzed', 'decided', 'closed'))
);

create table if not exists public.skpe_governance_decisions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  strategy_review_id uuid not null,
  strategy_review_item_id uuid references public.skpe_strategy_review_items(id) on delete set null,
  code text not null,
  title text not null,
  decision_text text not null,
  rationale text,
  decision_type text not null default 'corrective_action',
  priority text not null default 'medium',
  responsible_user_id uuid references public.profiles(id) on delete set null,
  due_date date,
  status text not null default 'open',
  escalation_level text not null default 'none',
  linked_initiative_action_id uuid references public.skpe_initiative_actions(id) on delete set null,
  completed_at timestamptz,
  completion_notes text,
  ratified_at timestamptz,
  ratified_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_governance_decisions_review_fkey
    foreign key (strategy_review_id, formulation_id, organization_id, project_id)
    references public.skpe_strategy_reviews(id, formulation_id, organization_id, project_id)
    on delete cascade,
  constraint skpe_governance_decisions_code_not_blank check (length(trim(code)) > 0),
  constraint skpe_governance_decisions_title_not_blank check (length(trim(title)) > 0),
  constraint skpe_governance_decisions_text_not_blank check (length(trim(decision_text)) > 0),
  constraint skpe_governance_decisions_type_check
    check (decision_type in (
      'corrective_action', 'preventive_action', 'resource_allocation',
      'reprioritization', 'escalation', 'strategy_review', 'communication', 'other'
    )),
  constraint skpe_governance_decisions_priority_check
    check (priority in ('low', 'medium', 'high', 'critical')),
  constraint skpe_governance_decisions_status_check
    check (status in ('open', 'in_progress', 'blocked', 'completed', 'cancelled', 'overdue')),
  constraint skpe_governance_decisions_escalation_check
    check (escalation_level in ('none', 'management', 'board', 'assembly')),
  constraint skpe_governance_decisions_unique unique (strategy_review_id, code)
);

create table if not exists public.skpe_strategic_learnings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  monitoring_cycle_id uuid references public.skpe_monitoring_cycles(id) on delete set null,
  strategy_review_id uuid references public.skpe_strategy_reviews(id) on delete set null,
  code text not null,
  title text not null,
  evidence_text text not null,
  interpretation_text text,
  lesson_text text not null,
  impact_level text not null default 'medium',
  recommendation text,
  status text not null default 'identified',
  governance_decision text,
  target_revision_formulation_id uuid references public.skpe_strategic_formulations(id) on delete set null,
  incorporated_at timestamptz,
  incorporated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategic_learnings_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(id, organization_id, project_id)
    on delete cascade,
  constraint skpe_strategic_learnings_code_not_blank check (length(trim(code)) > 0),
  constraint skpe_strategic_learnings_title_not_blank check (length(trim(title)) > 0),
  constraint skpe_strategic_learnings_evidence_not_blank check (length(trim(evidence_text)) > 0),
  constraint skpe_strategic_learnings_lesson_not_blank check (length(trim(lesson_text)) > 0),
  constraint skpe_strategic_learnings_impact_check
    check (impact_level in ('low', 'medium', 'high', 'critical')),
  constraint skpe_strategic_learnings_status_check
    check (status in ('identified', 'under_analysis', 'accepted', 'rejected', 'incorporated', 'archived')),
  constraint skpe_strategic_learnings_unique unique (formulation_id, code)
);

create table if not exists public.skpe_performance_snapshots (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  monitoring_cycle_id uuid not null,
  snapshot_version integer not null default 1,
  status text not null default 'generated',
  calculation_policy text not null,
  payload jsonb not null,
  checksum_sha256 text not null,
  generated_at timestamptz not null default timezone('utc', now()),
  generated_by uuid references public.profiles(id) on delete set null,
  ratified_at timestamptz,
  ratified_by uuid references public.profiles(id) on delete set null,

  constraint skpe_performance_snapshots_cycle_fkey
    foreign key (monitoring_cycle_id, formulation_id, organization_id, project_id)
    references public.skpe_monitoring_cycles(id, formulation_id, organization_id, project_id)
    on delete cascade,
  constraint skpe_performance_snapshots_version_check check (snapshot_version > 0),
  constraint skpe_performance_snapshots_status_check
    check (status in ('generated', 'ratified', 'superseded')),
  constraint skpe_performance_snapshots_checksum_check
    check (checksum_sha256 ~ '^[0-9a-f]{64}$'),
  constraint skpe_performance_snapshots_unique unique (monitoring_cycle_id, snapshot_version)
);

-- ============================================================
-- 5. ÍNDICES, UPDATED_AT, RLS E LEITURA
-- ============================================================

create index if not exists idx_skpe_monitoring_cycles_scope
  on public.skpe_monitoring_cycles(formulation_id, status, period_start, period_end);
create index if not exists idx_skpe_indicator_measurements_active
  on public.skpe_indicator_measurements(monitoring_cycle_id, indicator_id, measurement_date desc)
  where status in ('submitted', 'validated');
create index if not exists idx_skpe_kr_check_ins_active
  on public.skpe_key_result_check_ins(monitoring_cycle_id, key_result_id, check_in_date desc)
  where status in ('submitted', 'validated');
create index if not exists idx_skpe_initiative_check_ins_active
  on public.skpe_initiative_check_ins(monitoring_cycle_id, initiative_id, check_in_date desc)
  where status in ('submitted', 'validated');
create index if not exists idx_skpe_outcome_measurements_active
  on public.skpe_initiative_outcome_measurements(monitoring_cycle_id, initiative_outcome_id, measurement_date desc)
  where status in ('submitted', 'validated');
create index if not exists idx_skpe_strategy_reviews_scope
  on public.skpe_strategy_reviews(monitoring_cycle_id, status, scheduled_at);
create index if not exists idx_skpe_governance_decisions_due
  on public.skpe_governance_decisions(formulation_id, status, priority, due_date);
create index if not exists idx_skpe_strategic_learnings_scope
  on public.skpe_strategic_learnings(formulation_id, status, impact_level);

create unique index if not exists ux_skpe_indicator_measurements_submitted
  on public.skpe_indicator_measurements(monitoring_cycle_id, indicator_id)
  where status = 'submitted';
create unique index if not exists ux_skpe_indicator_measurements_validated
  on public.skpe_indicator_measurements(monitoring_cycle_id, indicator_id)
  where status = 'validated';
create unique index if not exists ux_skpe_kr_check_ins_submitted
  on public.skpe_key_result_check_ins(monitoring_cycle_id, key_result_id)
  where status = 'submitted';
create unique index if not exists ux_skpe_kr_check_ins_validated
  on public.skpe_key_result_check_ins(monitoring_cycle_id, key_result_id)
  where status = 'validated';
create unique index if not exists ux_skpe_initiative_check_ins_submitted
  on public.skpe_initiative_check_ins(monitoring_cycle_id, initiative_id)
  where status = 'submitted';
create unique index if not exists ux_skpe_initiative_check_ins_validated
  on public.skpe_initiative_check_ins(monitoring_cycle_id, initiative_id)
  where status = 'validated';
create unique index if not exists ux_skpe_outcome_measurements_submitted
  on public.skpe_initiative_outcome_measurements(monitoring_cycle_id, initiative_outcome_id)
  where status = 'submitted';
create unique index if not exists ux_skpe_outcome_measurements_validated
  on public.skpe_initiative_outcome_measurements(monitoring_cycle_id, initiative_outcome_id)
  where status = 'validated';
create unique index if not exists ux_skpe_performance_snapshots_ratified
  on public.skpe_performance_snapshots(monitoring_cycle_id)
  where status = 'ratified';

-- updated_at
drop trigger if exists skpe_monitoring_packages_set_updated_at on public.skpe_monitoring_packages;
create trigger skpe_monitoring_packages_set_updated_at
before update on public.skpe_monitoring_packages
for each row execute function public.set_updated_at();
drop trigger if exists skpe_monitoring_cycles_set_updated_at on public.skpe_monitoring_cycles;
create trigger skpe_monitoring_cycles_set_updated_at
before update on public.skpe_monitoring_cycles
for each row execute function public.set_updated_at();
drop trigger if exists skpe_strategy_reviews_set_updated_at on public.skpe_strategy_reviews;
create trigger skpe_strategy_reviews_set_updated_at
before update on public.skpe_strategy_reviews
for each row execute function public.set_updated_at();
drop trigger if exists skpe_strategy_review_items_set_updated_at on public.skpe_strategy_review_items;
create trigger skpe_strategy_review_items_set_updated_at
before update on public.skpe_strategy_review_items
for each row execute function public.set_updated_at();
drop trigger if exists skpe_governance_decisions_set_updated_at on public.skpe_governance_decisions;
create trigger skpe_governance_decisions_set_updated_at
before update on public.skpe_governance_decisions
for each row execute function public.set_updated_at();
drop trigger if exists skpe_strategic_learnings_set_updated_at on public.skpe_strategic_learnings;
create trigger skpe_strategic_learnings_set_updated_at
before update on public.skpe_strategic_learnings
for each row execute function public.set_updated_at();

alter table public.skpe_monitoring_packages enable row level security;
alter table public.skpe_monitoring_cycles enable row level security;
alter table public.skpe_indicator_measurements enable row level security;
alter table public.skpe_key_result_check_ins enable row level security;
alter table public.skpe_initiative_check_ins enable row level security;
alter table public.skpe_initiative_outcome_measurements enable row level security;
alter table public.skpe_strategy_reviews enable row level security;
alter table public.skpe_strategy_review_items enable row level security;
alter table public.skpe_governance_decisions enable row level security;
alter table public.skpe_strategic_learnings enable row level security;
alter table public.skpe_performance_snapshots enable row level security;

drop policy if exists skpe_monitoring_packages_select on public.skpe_monitoring_packages;
create policy skpe_monitoring_packages_select on public.skpe_monitoring_packages
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_monitoring_cycles_select on public.skpe_monitoring_cycles;
create policy skpe_monitoring_cycles_select on public.skpe_monitoring_cycles
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_indicator_measurements_select on public.skpe_indicator_measurements;
create policy skpe_indicator_measurements_select on public.skpe_indicator_measurements
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_key_result_check_ins_select on public.skpe_key_result_check_ins;
create policy skpe_key_result_check_ins_select on public.skpe_key_result_check_ins
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_initiative_check_ins_select on public.skpe_initiative_check_ins;
create policy skpe_initiative_check_ins_select on public.skpe_initiative_check_ins
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_initiative_outcome_measurements_select on public.skpe_initiative_outcome_measurements;
create policy skpe_initiative_outcome_measurements_select on public.skpe_initiative_outcome_measurements
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_strategy_reviews_select on public.skpe_strategy_reviews;
create policy skpe_strategy_reviews_select on public.skpe_strategy_reviews
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_strategy_review_items_select on public.skpe_strategy_review_items;
create policy skpe_strategy_review_items_select on public.skpe_strategy_review_items
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_governance_decisions_select on public.skpe_governance_decisions;
create policy skpe_governance_decisions_select on public.skpe_governance_decisions
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_strategic_learnings_select on public.skpe_strategic_learnings;
create policy skpe_strategic_learnings_select on public.skpe_strategic_learnings
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));
drop policy if exists skpe_performance_snapshots_select on public.skpe_performance_snapshots;
create policy skpe_performance_snapshots_select on public.skpe_performance_snapshots
for select to authenticated using (public.can_view_skpe_monitoring(organization_id));

-- O pacote é parte estrutural da Formulação e fica bloqueado após aprovação.
drop trigger if exists skpe_monitoring_packages_guard_formulation on public.skpe_monitoring_packages;
create trigger skpe_monitoring_packages_guard_formulation
before insert or update or delete on public.skpe_monitoring_packages
for each row execute function public.skpe_guard_approved_formulation_content();

-- ============================================================
-- 6. FUNÇÕES INTERNAS
-- ============================================================

create or replace function public.skpe_assert_monitoring_cycle_writable(p_cycle_id uuid)
returns public.skpe_monitoring_cycles
language plpgsql
security definer
set search_path = ''
as $$
declare
  cycle_row public.skpe_monitoring_cycles%rowtype;
begin
  select * into cycle_row
  from public.skpe_monitoring_cycles
  where id = p_cycle_id
  for update;

  if not found then
    raise exception 'Ciclo de monitoramento não encontrado.' using errcode = '22023';
  end if;

  if cycle_row.status in ('closed', 'cancelled') then
    raise exception 'O ciclo está fechado ou cancelado e não aceita novas mutações.' using errcode = '55000';
  end if;

  return cycle_row;
end;
$$;

create or replace function public.ensure_skpe_monitoring_package(p_formulation_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_monitoring_packages%rowtype;
  source_package public.skpe_monitoring_packages%rowtype;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.' using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into package_row
  from public.skpe_monitoring_packages
  where formulation_id = p_formulation_id
  for update;

  if found then
    return package_row.id;
  end if;

  if formulation_row.derived_from_formulation_id is not null then
    select * into source_package
    from public.skpe_monitoring_packages
    where formulation_id = formulation_row.derived_from_formulation_id;
  end if;

  insert into public.skpe_monitoring_packages (
    organization_id, project_id, formulation_id, status,
    cycle_frequency, review_frequency, cycle_overlap_policy,
    evidence_required, data_quality_required,
    confidence_required_for_key_results, allow_manual_progress_override,
    data_freshness_days, late_tolerance_days, aggregation_policy,
    critical_threshold, attention_threshold, on_track_threshold,
    owner_user_id, governance_owner_user_id, metadata,
    created_by, updated_by
  ) values (
    formulation_row.organization_id,
    formulation_row.project_id,
    formulation_row.id,
    'in_elaboration',
    coalesce(source_package.cycle_frequency, 'monthly'),
    coalesce(source_package.review_frequency, 'quarterly'),
    coalesce(source_package.cycle_overlap_policy, 'block'),
    coalesce(source_package.evidence_required, true),
    coalesce(source_package.data_quality_required, true),
    coalesce(source_package.confidence_required_for_key_results, true),
    coalesce(source_package.allow_manual_progress_override, false),
    coalesce(source_package.data_freshness_days, 45),
    coalesce(source_package.late_tolerance_days, 5),
    coalesce(source_package.aggregation_policy, 'explicit_weight'),
    coalesce(source_package.critical_threshold, 50),
    coalesce(source_package.attention_threshold, 75),
    coalesce(source_package.on_track_threshold, 100),
    source_package.owner_user_id,
    source_package.governance_owner_user_id,
    coalesce(source_package.metadata, '{}'::jsonb)
      || case when source_package.id is null then '{}'::jsonb else jsonb_build_object(
        'clonedFromMonitoringPackageId', source_package.id,
        'clonedFromFormulationId', formulation_row.derived_from_formulation_id
      ) end,
    auth.uid(), auth.uid()
  ) returning * into package_row;

  perform public.skpe_record_operational_audit(
    package_row.organization_id, package_row.project_id,
    'monitoring_package', package_row.id,
    'fe08.monitoring_package_created',
    'Criação automática do pacote FE-08.',
    null, to_jsonb(package_row)
  );

  return package_row.id;
end;
$$;

create or replace function public.skpe_calculate_strategic_performance(
  p_polarity text,
  p_baseline_value numeric,
  p_current_value numeric,
  p_target_value numeric,
  p_range_lower numeric default null,
  p_range_upper numeric default null
)
returns numeric
language sql
immutable
security definer
set search_path = ''
as $$
  select public.skpe_calculate_key_result_progress(
    p_polarity,
    p_baseline_value,
    p_current_value,
    p_target_value,
    p_range_lower,
    p_range_upper
  );
$$;

create or replace function public.skpe_monitoring_performance_status(
  p_package_id uuid,
  p_performance numeric
)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  package_row public.skpe_monitoring_packages%rowtype;
begin
  select * into package_row from public.skpe_monitoring_packages where id = p_package_id;
  if p_performance is null then return 'not_assessed'; end if;
  if p_performance < package_row.critical_threshold then return 'critical'; end if;
  if p_performance < package_row.attention_threshold then return 'attention'; end if;
  if p_performance >= package_row.on_track_threshold then return 'achieved'; end if;
  return 'on_track';
end;
$$;

create or replace function public.skpe_guard_snapshot_immutability()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'Snapshots de desempenho não podem ser excluídos.' using errcode = '55000';
  end if;

  if old.status = 'generated'
     and new.status = 'ratified'
     and (to_jsonb(old) - array['status','ratified_at','ratified_by'])
         = (to_jsonb(new) - array['status','ratified_at','ratified_by']) then
    return new;
  end if;

  if old.status = 'ratified'
     and new.status = 'superseded'
     and (to_jsonb(old) - array['status']) = (to_jsonb(new) - array['status']) then
    return new;
  end if;

  raise exception 'Snapshot imutável: somente ratificação ou supersessão controlada são permitidas.' using errcode = '55000';
end;
$$;

drop trigger if exists skpe_performance_snapshots_immutable on public.skpe_performance_snapshots;
create trigger skpe_performance_snapshots_immutable
before update or delete on public.skpe_performance_snapshots
for each row execute function public.skpe_guard_snapshot_immutability();

create or replace function public.skpe_assert_strategy_review_item_scope(
  p_strategy_review_id uuid,
  p_payload jsonb
)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  review_row public.skpe_strategy_reviews%rowtype;
  entity_type_value text := p_payload ->> 'entityType';
  entity_id uuid;
begin
  select * into review_row from public.skpe_strategy_reviews where id = p_strategy_review_id;
  if not found then raise exception 'RAE não encontrada.' using errcode = '22023'; end if;

  if entity_type_value = 'strategic_theme' then
    entity_id := nullif(p_payload ->> 'strategicThemeId', '')::uuid;
    if not exists (select 1 from public.skpe_strategic_themes e where e.id = entity_id and e.formulation_id = review_row.formulation_id) then
      raise exception 'Tema Estratégico fora do escopo da RAE.' using errcode = '22023';
    end if;
  elsif entity_type_value = 'strategic_objective' then
    entity_id := nullif(p_payload ->> 'strategicObjectiveId', '')::uuid;
    if not exists (select 1 from public.skpe_strategic_objectives e where e.id = entity_id and e.formulation_id = review_row.formulation_id) then
      raise exception 'Objetivo Estratégico fora do escopo da RAE.' using errcode = '22023';
    end if;
  elsif entity_type_value = 'indicator' then
    entity_id := nullif(p_payload ->> 'indicatorId', '')::uuid;
    if not exists (select 1 from public.skpe_indicators e where e.id = entity_id and e.formulation_id = review_row.formulation_id) then
      raise exception 'Indicador fora do escopo da RAE.' using errcode = '22023';
    end if;
  elsif entity_type_value = 'okr' then
    entity_id := nullif(p_payload ->> 'okrId', '')::uuid;
    if not exists (select 1 from public.skpe_okrs e where e.id = entity_id and e.formulation_id = review_row.formulation_id) then
      raise exception 'OKR fora do escopo da RAE.' using errcode = '22023';
    end if;
  elsif entity_type_value = 'key_result' then
    entity_id := nullif(p_payload ->> 'keyResultId', '')::uuid;
    if not exists (select 1 from public.skpe_key_results e where e.id = entity_id and e.formulation_id = review_row.formulation_id) then
      raise exception 'Resultado-Chave fora do escopo da RAE.' using errcode = '22023';
    end if;
  elsif entity_type_value = 'initiative' then
    entity_id := nullif(p_payload ->> 'initiativeId', '')::uuid;
    if not exists (
      select 1 from public.skpe_initiative_portfolio_items item
      where item.formulation_id = review_row.formulation_id and item.initiative_id = entity_id
    ) then raise exception 'Iniciativa fora do escopo da RAE.' using errcode = '22023'; end if;
  elsif entity_type_value = 'initiative_action' then
    entity_id := nullif(p_payload ->> 'initiativeActionId', '')::uuid;
    if not exists (
      select 1 from public.skpe_initiative_actions action
      join public.skpe_initiative_portfolio_items item
        on item.initiative_id = action.initiative_id
       and item.formulation_id = review_row.formulation_id
      where action.id = entity_id
    ) then raise exception 'Ação de Iniciativa fora do escopo da RAE.' using errcode = '22023'; end if;
  elsif entity_type_value = 'initiative_risk' then
    entity_id := nullif(p_payload ->> 'initiativeRiskId', '')::uuid;
    if not exists (
      select 1 from public.skpe_initiative_risks risk
      join public.skpe_initiative_portfolio_items item
        on item.initiative_id = risk.initiative_id
       and item.formulation_id = review_row.formulation_id
      where risk.id = entity_id
    ) then raise exception 'Risco de Iniciativa fora do escopo da RAE.' using errcode = '22023'; end if;
  elsif entity_type_value = 'initiative_outcome' then
    entity_id := nullif(p_payload ->> 'initiativeOutcomeId', '')::uuid;
    if not exists (select 1 from public.skpe_initiative_outcomes e where e.id = entity_id and e.formulation_id = review_row.formulation_id) then
      raise exception 'Resultado da Iniciativa fora do escopo da RAE.' using errcode = '22023';
    end if;
  else
    raise exception 'Tipo de entidade da RAE inválido.' using errcode = '22023';
  end if;
end;
$$;

-- ============================================================
-- 7. CONFIGURAÇÃO E VALIDAÇÃO DO PACOTE
-- ============================================================

create or replace function public.get_skpe_monitoring_package_readiness(
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
  package_row public.skpe_monitoring_packages%rowtype;
  blocking_issues jsonb := '[]'::jsonb;
  recommendations jsonb := '[]'::jsonb;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Formulação Estratégica não encontrada.' using errcode = '22023';
  end if;
  if not public.can_view_skpe_monitoring(formulation_row.organization_id)
     and not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado ao pacote FE-08.' using errcode = '42501';
  end if;

  select * into package_row
  from public.skpe_monitoring_packages
  where formulation_id = p_formulation_id;

  if not found then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_PACKAGE_MISSING',
      'severity', 'blocking',
      'message', 'O pacote FE-08 ainda não foi configurado.'
    ));
    return jsonb_build_object(
      'packageStatus', null,
      'readyForValidation', false,
      'readyForFormulation', false,
      'blockingIssues', blocking_issues,
      'recommendations', recommendations
    );
  end if;

  if package_row.owner_user_id is null then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_MONITORING_OWNER_MISSING', 'severity', 'blocking',
      'message', 'Defina o responsável pelo monitoramento estratégico.'
    ));
  end if;
  if package_row.governance_owner_user_id is null then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_GOVERNANCE_OWNER_MISSING', 'severity', 'blocking',
      'message', 'Defina o responsável pela governança e RAE.'
    ));
  end if;

  if exists (
    select 1 from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and indicator.measurement_frequency is null
  ) then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_ACTIVE_INDICATOR_WITHOUT_FREQUENCY', 'severity', 'blocking',
      'message', 'Existe Indicador Estratégico ativo sem frequência de apuração.'
    ));
  end if;

  if exists (
    select 1 from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and indicator.owner_user_id is null
  ) then
    recommendations := recommendations || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_INDICATOR_OWNER_RECOMMENDED', 'severity', 'recommendation',
      'message', 'Há Indicador Estratégico ativo sem responsável definido.'
    ));
  end if;

  if package_row.aggregation_policy = 'explicit_weight' and exists (
    select 1
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and case
        when indicator.metadata ->> 'monitoringWeight' ~ '^[0-9]+([.][0-9]+)?$'
          then (indicator.metadata ->> 'monitoringWeight')::numeric <= 0
        else true
      end
  ) then
    recommendations := recommendations || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_EXPLICIT_WEIGHT_NOT_DEFINED', 'severity', 'recommendation',
      'message', 'A agregação ponderada usará peso 1 para Indicadores sem metadata.monitoringWeight positivo.'
    ));
  end if;

  return jsonb_build_object(
    'packageId', package_row.id,
    'packageStatus', package_row.status,
    'readyForValidation', jsonb_array_length(blocking_issues) = 0,
    'readyForFormulation', jsonb_array_length(blocking_issues) = 0
      and (not p_include_package_state or package_row.status = 'validated'),
    'blockingIssues', blocking_issues,
    'recommendations', recommendations,
    'metrics', jsonb_build_object(
      'activeStrategicIndicators', (
        select count(*) from public.skpe_indicators i
        where i.formulation_id = p_formulation_id
          and i.indicator_scope = 'strategic_kpi' and i.status = 'active'
      ),
      'activeKeyResults', (
        select count(*) from public.skpe_key_results kr
        where kr.formulation_id = p_formulation_id and kr.status in ('active','at_risk')
      ),
      'selectedInitiatives', (
        select count(*) from public.skpe_initiative_portfolio_items item
        where item.formulation_id = p_formulation_id and item.selection_status = 'selected'
      )
    )
  );
end;
$$;

create or replace function public.configure_skpe_monitoring_package(
  p_formulation_id uuid,
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
  package_id uuid;
  previous_data jsonb;
  updated_row public.skpe_monitoring_packages%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row from public.skpe_strategic_formulations where id = p_formulation_id;
  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado para configurar o pacote FE-08.' using errcode = '42501';
  end if;

  package_id := public.ensure_skpe_monitoring_package(p_formulation_id);
  select to_jsonb(package) into previous_data
  from public.skpe_monitoring_packages package where package.id = package_id;

  update public.skpe_monitoring_packages
  set
    cycle_frequency = coalesce(nullif(p_payload ->> 'cycleFrequency', ''), cycle_frequency),
    review_frequency = coalesce(nullif(p_payload ->> 'reviewFrequency', ''), review_frequency),
    cycle_overlap_policy = coalesce(nullif(p_payload ->> 'cycleOverlapPolicy', ''), cycle_overlap_policy),
    evidence_required = coalesce((p_payload ->> 'evidenceRequired')::boolean, evidence_required),
    data_quality_required = coalesce((p_payload ->> 'dataQualityRequired')::boolean, data_quality_required),
    confidence_required_for_key_results = coalesce((p_payload ->> 'confidenceRequiredForKeyResults')::boolean, confidence_required_for_key_results),
    allow_manual_progress_override = coalesce((p_payload ->> 'allowManualProgressOverride')::boolean, allow_manual_progress_override),
    data_freshness_days = coalesce(nullif(p_payload ->> 'dataFreshnessDays', '')::integer, data_freshness_days),
    late_tolerance_days = coalesce(nullif(p_payload ->> 'lateToleranceDays', '')::integer, late_tolerance_days),
    aggregation_policy = coalesce(nullif(p_payload ->> 'aggregationPolicy', ''), aggregation_policy),
    critical_threshold = coalesce(nullif(p_payload ->> 'criticalThreshold', '')::numeric, critical_threshold),
    attention_threshold = coalesce(nullif(p_payload ->> 'attentionThreshold', '')::numeric, attention_threshold),
    on_track_threshold = coalesce(nullif(p_payload ->> 'onTrackThreshold', '')::numeric, on_track_threshold),
    owner_user_id = coalesce(nullif(p_payload ->> 'ownerUserId', '')::uuid, owner_user_id),
    governance_owner_user_id = coalesce(nullif(p_payload ->> 'governanceOwnerUserId', '')::uuid, governance_owner_user_id),
    metadata = coalesce(metadata, '{}'::jsonb) || coalesce(p_payload -> 'metadata', '{}'::jsonb),
    status = 'in_elaboration',
    validation_notes = null,
    submitted_for_validation_at = null,
    submitted_for_validation_by = null,
    validated_at = null,
    validated_by = null,
    updated_by = auth.uid()
  where id = package_id
  returning * into updated_row;

  perform public.skpe_record_operational_audit(
    updated_row.organization_id, updated_row.project_id,
    'monitoring_package', updated_row.id,
    'fe08.monitoring_package_configured',
    p_change_reason, previous_data, to_jsonb(updated_row)
  );
  return updated_row.id;
end;
$$;

create or replace function public.transition_skpe_monitoring_package(
  p_formulation_id uuid,
  p_action text,
  p_validation_notes text,
  p_change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_monitoring_packages%rowtype;
  previous_data jsonb;
  readiness jsonb;
  normalized_action text := lower(trim(p_action));
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into formulation_row from public.skpe_strategic_formulations where id = p_formulation_id;
  select * into package_row from public.skpe_monitoring_packages where formulation_id = p_formulation_id for update;
  if not found then raise exception 'Pacote FE-08 não encontrado.' using errcode = '22023'; end if;
  previous_data := to_jsonb(package_row);

  if normalized_action = 'submit' then
    perform public.skpe_assert_formulation_editable(p_formulation_id);
    if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para submeter o pacote FE-08.' using errcode = '42501';
    end if;
    readiness := public.get_skpe_monitoring_package_readiness(p_formulation_id, false);
    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'Pacote FE-08 incompleto. Pendências: %', readiness -> 'blockingIssues' using errcode = '55000';
    end if;
    update public.skpe_monitoring_packages set
      status = 'pending_validation',
      validation_notes = null,
      submitted_for_validation_at = timezone('utc', now()),
      submitted_for_validation_by = auth.uid(),
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where id = package_row.id returning * into package_row;
  elsif normalized_action = 'validate' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para validar o pacote FE-08.' using errcode = '42501';
    end if;
    if package_row.status <> 'pending_validation' then
      raise exception 'O pacote deve estar pendente de validação.' using errcode = '55000';
    end if;
    readiness := public.get_skpe_monitoring_package_readiness(p_formulation_id, false);
    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'Pacote FE-08 incompleto. Pendências: %', readiness -> 'blockingIssues' using errcode = '55000';
    end if;
    update public.skpe_monitoring_packages set
      status = 'validated',
      validation_notes = nullif(trim(p_validation_notes), ''),
      validated_at = timezone('utc', now()),
      validated_by = auth.uid(),
      updated_by = auth.uid()
    where id = package_row.id returning * into package_row;
  elsif normalized_action = 'return' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para devolver o pacote FE-08.' using errcode = '42501';
    end if;
    update public.skpe_monitoring_packages set
      status = 'in_elaboration',
      validation_notes = nullif(trim(p_validation_notes), ''),
      submitted_for_validation_at = null,
      submitted_for_validation_by = null,
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where id = package_row.id returning * into package_row;
  else
    raise exception 'Ação inválida. Use submit, validate ou return.' using errcode = '22023';
  end if;

  perform public.skpe_record_operational_audit(
    package_row.organization_id, package_row.project_id,
    'monitoring_package', package_row.id,
    'fe08.monitoring_package_' || normalized_action,
    p_change_reason, previous_data, to_jsonb(package_row)
  );
  return to_jsonb(package_row);
end;
$$;

create or replace function public.skpe_guard_formulation_monitoring_ready()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  readiness jsonb;
begin
  if new.status in ('pending_validation', 'validated', 'pending_approval', 'approved')
     and old.status is distinct from new.status then
    readiness := public.get_skpe_monitoring_package_readiness(new.id, true);
    if not coalesce((readiness ->> 'readyForFormulation')::boolean, false) then
      raise exception 'A Formulação não pode avançar: pacote FE-08 incompleto ou não validado. Pendências: %',
        readiness -> 'blockingIssues' using errcode = '55000';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists skpe_strategic_formulations_guard_fe08 on public.skpe_strategic_formulations;
create trigger skpe_strategic_formulations_guard_fe08
before update of status on public.skpe_strategic_formulations
for each row execute function public.skpe_guard_formulation_monitoring_ready();

-- ============================================================
-- 8. CICLOS E REGISTROS OPERACIONAIS
-- ============================================================

create or replace function public.open_skpe_monitoring_cycle(
  p_formulation_id uuid,
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
  package_row public.skpe_monitoring_packages%rowtype;
  cycle_row public.skpe_monitoring_cycles%rowtype;
  period_start_value date;
  period_end_value date;
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into formulation_row from public.skpe_strategic_formulations where id = p_formulation_id;
  if not found then raise exception 'Formulação Estratégica não encontrada.' using errcode = '22023'; end if;
  if formulation_row.status <> 'approved' then
    raise exception 'Somente Formulações aprovadas podem abrir ciclos de monitoramento.' using errcode = '55000';
  end if;
  if not public.can_manage_skpe_monitoring(formulation_row.organization_id) then
    raise exception 'Acesso negado para abrir ciclo de monitoramento.' using errcode = '42501';
  end if;

  select * into package_row
  from public.skpe_monitoring_packages
  where formulation_id = p_formulation_id
  for update;
  if not found or package_row.status <> 'validated' then
    raise exception 'O pacote FE-08 deve estar validado.' using errcode = '55000';
  end if;

  period_start_value := nullif(p_payload ->> 'periodStart', '')::date;
  period_end_value := nullif(p_payload ->> 'periodEnd', '')::date;
  if period_start_value is null or period_end_value is null then
    raise exception 'Informe periodStart e periodEnd.' using errcode = '22023';
  end if;
  if formulation_row.valid_from is not null and period_start_value < formulation_row.valid_from then
    raise exception 'O ciclo inicia antes da vigência da Formulação.' using errcode = '22023';
  end if;
  if formulation_row.valid_until is not null and period_end_value > formulation_row.valid_until then
    raise exception 'O ciclo termina após a vigência da Formulação.' using errcode = '22023';
  end if;

  if package_row.cycle_overlap_policy = 'block' and exists (
    select 1 from public.skpe_monitoring_cycles cycle
    where cycle.formulation_id = p_formulation_id
      and cycle.status not in ('cancelled', 'closed')
      and daterange(cycle.period_start, cycle.period_end, '[]')
          && daterange(period_start_value, period_end_value, '[]')
  ) then
    raise exception 'Existe ciclo aberto com período sobreposto.' using errcode = '55000';
  end if;

  insert into public.skpe_monitoring_cycles (
    organization_id, project_id, formulation_id, monitoring_package_id,
    code, name, cycle_type, period_start, period_end, cutoff_date,
    status, owner_user_id, governance_owner_user_id,
    opened_at, opened_by, metadata, created_by, updated_by
  ) values (
    formulation_row.organization_id,
    formulation_row.project_id,
    formulation_row.id,
    package_row.id,
    trim(p_payload ->> 'code'),
    trim(p_payload ->> 'name'),
    coalesce(nullif(p_payload ->> 'cycleType', ''), package_row.cycle_frequency),
    period_start_value,
    period_end_value,
    nullif(p_payload ->> 'cutoffDate', '')::date,
    'open',
    coalesce(nullif(p_payload ->> 'ownerUserId', '')::uuid, package_row.owner_user_id),
    coalesce(nullif(p_payload ->> 'governanceOwnerUserId', '')::uuid, package_row.governance_owner_user_id),
    timezone('utc', now()), auth.uid(),
    coalesce(p_payload -> 'metadata', '{}'::jsonb),
    auth.uid(), auth.uid()
  ) returning * into cycle_row;

  perform public.skpe_record_operational_audit(
    cycle_row.organization_id, cycle_row.project_id,
    'monitoring_cycle', cycle_row.id,
    'fe08.monitoring_cycle_opened', p_change_reason,
    null, to_jsonb(cycle_row)
  );
  return cycle_row.id;
end;
$$;

create or replace function public.record_skpe_indicator_measurement(
  p_cycle_id uuid,
  p_indicator_id uuid,
  p_measured_value numeric,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  cycle_row public.skpe_monitoring_cycles%rowtype;
  package_row public.skpe_monitoring_packages%rowtype;
  indicator_row public.skpe_indicators%rowtype;
  target_row public.skpe_indicator_targets%rowtype;
  previous_submitted public.skpe_indicator_measurements%rowtype;
  previous_validated public.skpe_indicator_measurements%rowtype;
  saved_row public.skpe_indicator_measurements%rowtype;
  measurement_date_value date;
  automatic_value numeric;
  manual_value numeric;
  effective_value numeric;
begin
  perform public.skpe_assert_reason(p_change_reason);
  cycle_row := public.skpe_assert_monitoring_cycle_writable(p_cycle_id);
  if not public.can_manage_skpe_monitoring(cycle_row.organization_id) then
    raise exception 'Acesso negado para registrar medição.' using errcode = '42501';
  end if;

  select * into package_row
  from public.skpe_monitoring_packages
  where id = cycle_row.monitoring_package_id;

  select * into indicator_row
  from public.skpe_indicators
  where id = p_indicator_id
    and formulation_id = cycle_row.formulation_id
    and indicator_scope = 'strategic_kpi'
    and status = 'active';
  if not found then
    raise exception 'Indicador Estratégico ativo não encontrado no escopo do ciclo.' using errcode = '22023';
  end if;

  measurement_date_value := coalesce(
    nullif(p_payload ->> 'measurementDate', '')::date,
    current_date
  );
  if measurement_date_value < cycle_row.period_start
     or measurement_date_value > cycle_row.period_end then
    raise exception 'A data da medição deve pertencer ao período do ciclo.' using errcode = '22023';
  end if;

  if nullif(p_payload ->> 'indicatorTargetId', '') is not null then
    select * into target_row
    from public.skpe_indicator_targets
    where id = (p_payload ->> 'indicatorTargetId')::uuid
      and indicator_id = indicator_row.id
      and formulation_id = cycle_row.formulation_id;
    if not found then
      raise exception 'Meta do Indicador não encontrada no escopo do ciclo.' using errcode = '22023';
    end if;
  else
    select * into target_row
    from public.skpe_indicator_targets
    where indicator_id = indicator_row.id
      and status in ('active', 'achieved', 'not_achieved')
      and measurement_date_value between period_start and period_end
    order by case target_type
      when 'cycle' then 1
      when 'intermediate' then 2
      when 'annual' then 3
      else 4
    end
    limit 1;
  end if;

  if target_row.id is not null then
    automatic_value := public.skpe_calculate_strategic_performance(
      indicator_row.polarity,
      indicator_row.baseline_value,
      p_measured_value,
      target_row.target_value,
      coalesce(target_row.tolerance_lower, target_row.minimum_value),
      target_row.tolerance_upper
    );
  end if;

  manual_value := nullif(p_payload ->> 'manualPerformanceOverride', '')::numeric;
  if manual_value is not null and not package_row.allow_manual_progress_override then
    raise exception 'O pacote FE-08 não permite substituição manual de desempenho.' using errcode = '55000';
  end if;
  if manual_value is not null and manual_value not between 0 and 100 then
    raise exception 'O desempenho manual deve estar entre 0 e 100.' using errcode = '22023';
  end if;
  effective_value := case
    when manual_value is null and automatic_value is null then null
    else greatest(0, least(100, coalesce(manual_value, automatic_value)))
  end;

  select * into previous_submitted
  from public.skpe_indicator_measurements
  where monitoring_cycle_id = cycle_row.id
    and indicator_id = indicator_row.id
    and status = 'submitted'
  for update;
  if found then
    update public.skpe_indicator_measurements
    set status = 'superseded'
    where id = previous_submitted.id;
  end if;

  select * into previous_validated
  from public.skpe_indicator_measurements
  where monitoring_cycle_id = cycle_row.id
    and indicator_id = indicator_row.id
    and status = 'validated'
  for update;

  insert into public.skpe_indicator_measurements (
    organization_id, project_id, formulation_id, monitoring_cycle_id,
    indicator_id, indicator_target_id, measurement_date, period_start, period_end,
    measured_value, automatic_performance, manual_performance_override,
    effective_performance, status, data_quality, source_name, source_reference,
    evidence_reference, notes, supersedes_measurement_id, metadata, created_by
  ) values (
    cycle_row.organization_id, cycle_row.project_id,
    cycle_row.formulation_id, cycle_row.id,
    indicator_row.id, target_row.id, measurement_date_value,
    nullif(p_payload ->> 'periodStart', '')::date,
    nullif(p_payload ->> 'periodEnd', '')::date,
    p_measured_value, automatic_value, manual_value, effective_value,
    'submitted', coalesce(nullif(p_payload ->> 'dataQuality', ''), 'not_assessed'),
    nullif(trim(p_payload ->> 'sourceName'), ''),
    nullif(trim(p_payload ->> 'sourceReference'), ''),
    nullif(trim(p_payload ->> 'evidenceReference'), ''),
    nullif(trim(p_payload ->> 'notes'), ''),
    coalesce(previous_submitted.id, previous_validated.id),
    coalesce(p_payload -> 'metadata', '{}'::jsonb), auth.uid()
  ) returning * into saved_row;

  perform public.skpe_record_operational_audit(
    saved_row.organization_id, saved_row.project_id,
    'indicator_measurement', saved_row.id,
    'fe08.indicator_measurement_recorded', p_change_reason,
    case
      when previous_submitted.id is not null then to_jsonb(previous_submitted)
      when previous_validated.id is not null then to_jsonb(previous_validated)
      else null
    end,
    to_jsonb(saved_row)
  );
  return saved_row.id;
end;
$$;

create or replace function public.record_skpe_key_result_check_in(
  p_cycle_id uuid,
  p_key_result_id uuid,
  p_current_value numeric,
  p_payload jsonb,
  p_change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  cycle_row public.skpe_monitoring_cycles%rowtype;
  package_row public.skpe_monitoring_packages%rowtype;
  key_result_row public.skpe_key_results%rowtype;
  previous_submitted public.skpe_key_result_check_ins%rowtype;
  previous_validated public.skpe_key_result_check_ins%rowtype;
  saved_check_in public.skpe_key_result_check_ins%rowtype;
  check_in_date_value date;
  automatic_value numeric;
  manual_value numeric;
  effective_value numeric;
  operational_status_value text;
  range_lower numeric;
  range_upper numeric;
begin
  perform public.skpe_assert_reason(p_change_reason);
  cycle_row := public.skpe_assert_monitoring_cycle_writable(p_cycle_id);
  if not public.can_manage_skpe_monitoring(cycle_row.organization_id) then
    raise exception 'Acesso negado para registrar check-in de KR.' using errcode = '42501';
  end if;

  select * into package_row
  from public.skpe_monitoring_packages
  where id = cycle_row.monitoring_package_id;

  select * into key_result_row
  from public.skpe_key_results
  where id = p_key_result_id
    and formulation_id = cycle_row.formulation_id
    and status in ('active', 'at_risk', 'achieved', 'not_achieved')
  for update;
  if not found then
    raise exception 'Resultado-Chave monitorável não encontrado no escopo do ciclo.' using errcode = '22023';
  end if;

  check_in_date_value := coalesce(
    nullif(p_payload ->> 'checkInDate', '')::date,
    current_date
  );
  if check_in_date_value < cycle_row.period_start
     or check_in_date_value > cycle_row.period_end then
    raise exception 'A data do check-in deve pertencer ao período do ciclo.' using errcode = '22023';
  end if;

  range_lower := nullif(key_result_row.metadata ->> 'rangeLower', '')::numeric;
  range_upper := nullif(key_result_row.metadata ->> 'rangeUpper', '')::numeric;
  automatic_value := public.skpe_calculate_key_result_progress(
    key_result_row.metadata ->> 'polarity',
    key_result_row.baseline_value,
    p_current_value,
    key_result_row.target_value,
    range_lower,
    range_upper
  );

  manual_value := nullif(p_payload ->> 'manualProgressOverride', '')::numeric;
  if manual_value is not null and not package_row.allow_manual_progress_override then
    raise exception 'O pacote FE-08 não permite substituição manual de progresso.' using errcode = '55000';
  end if;
  if manual_value is not null and manual_value not between 0 and 100 then
    raise exception 'O progresso manual deve estar entre 0 e 100.' using errcode = '22023';
  end if;

  effective_value := greatest(
    0,
    least(100, coalesce(manual_value, automatic_value, key_result_row.progress, 0))
  );
  operational_status_value := coalesce(
    nullif(p_payload ->> 'operationalStatus', ''),
    key_result_row.status
  );
  if operational_status_value not in ('active', 'at_risk', 'achieved', 'not_achieved') then
    raise exception 'Situação operacional inválida para o Resultado-Chave.' using errcode = '22023';
  end if;

  select * into previous_submitted
  from public.skpe_key_result_check_ins
  where monitoring_cycle_id = cycle_row.id
    and key_result_id = key_result_row.id
    and status = 'submitted'
  for update;
  if found then
    update public.skpe_key_result_check_ins
    set status = 'superseded'
    where id = previous_submitted.id;
  end if;

  select * into previous_validated
  from public.skpe_key_result_check_ins
  where monitoring_cycle_id = cycle_row.id
    and key_result_id = key_result_row.id
    and status = 'validated'
  for update;

  insert into public.skpe_key_result_check_ins (
    organization_id, project_id, formulation_id, monitoring_cycle_id, key_result_id,
    check_in_date, current_value, automatic_progress, manual_progress_override,
    effective_progress, operational_status, health_status, confidence_level,
    forecast_value, forecast_date, blockers, notes, evidence_reference,
    status, supersedes_check_in_id, metadata, created_by
  ) values (
    cycle_row.organization_id, cycle_row.project_id,
    cycle_row.formulation_id, cycle_row.id, key_result_row.id,
    check_in_date_value, p_current_value, automatic_value, manual_value,
    effective_value, operational_status_value,
    coalesce(nullif(p_payload ->> 'healthStatus', ''), 'not_assessed'),
    coalesce(nullif(p_payload ->> 'confidenceLevel', ''), 'not_assessed'),
    nullif(p_payload ->> 'forecastValue', '')::numeric,
    nullif(p_payload ->> 'forecastDate', '')::date,
    nullif(trim(p_payload ->> 'blockers'), ''),
    nullif(trim(p_payload ->> 'notes'), ''),
    nullif(trim(p_payload ->> 'evidenceReference'), ''),
    'submitted', coalesce(previous_submitted.id, previous_validated.id),
    coalesce(p_payload -> 'metadata', '{}'::jsonb), auth.uid()
  ) returning * into saved_check_in;

  perform public.skpe_record_operational_audit(
    saved_check_in.organization_id, saved_check_in.project_id,
    'key_result_check_in', saved_check_in.id,
    'fe08.key_result_check_in_recorded', p_change_reason,
    case
      when previous_submitted.id is not null then to_jsonb(previous_submitted)
      when previous_validated.id is not null then to_jsonb(previous_validated)
      else null
    end,
    to_jsonb(saved_check_in)
  );

  return jsonb_build_object(
    'checkInId', saved_check_in.id,
    'keyResultId', key_result_row.id,
    'automaticProgress', automatic_value,
    'effectiveProgress', effective_value,
    'projectionUpdated', false,
    'projectionUpdateRule', 'validation_required'
  );
end;
$$;

create or replace function public.record_skpe_initiative_check_in(
  p_cycle_id uuid,
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
  cycle_row public.skpe_monitoring_cycles%rowtype;
  initiative_row public.skpe_initiatives%rowtype;
  previous_submitted public.skpe_initiative_check_ins%rowtype;
  previous_validated public.skpe_initiative_check_ins%rowtype;
  saved_check_in public.skpe_initiative_check_ins%rowtype;
  check_in_date_value date;
  progress_value numeric;
  status_value text;
begin
  perform public.skpe_assert_reason(p_change_reason);
  cycle_row := public.skpe_assert_monitoring_cycle_writable(p_cycle_id);
  if not public.can_manage_skpe_monitoring(cycle_row.organization_id) then
    raise exception 'Acesso negado para registrar check-in de Iniciativa.' using errcode = '42501';
  end if;

  select * into initiative_row
  from public.skpe_initiatives
  where id = p_initiative_id
    and organization_id = cycle_row.organization_id
    and project_id = cycle_row.project_id
    and archived_at is null
  for update;
  if not found then
    raise exception 'Iniciativa não encontrada no escopo do ciclo.' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.skpe_initiative_portfolio_items item
    where item.formulation_id = cycle_row.formulation_id
      and item.initiative_id = p_initiative_id
      and item.selection_status = 'selected'
  ) then
    raise exception 'A Iniciativa não está selecionada na Formulação monitorada.' using errcode = '55000';
  end if;

  check_in_date_value := coalesce(
    nullif(p_payload ->> 'checkInDate', '')::date,
    current_date
  );
  if check_in_date_value < cycle_row.period_start
     or check_in_date_value > cycle_row.period_end then
    raise exception 'A data do check-in deve pertencer ao período do ciclo.' using errcode = '22023';
  end if;

  progress_value := coalesce(
    nullif(p_payload ->> 'progress', '')::numeric,
    initiative_row.progress
  );
  if progress_value not between 0 and 100 then
    raise exception 'O progresso da Iniciativa deve estar entre 0 e 100.' using errcode = '22023';
  end if;
  status_value := coalesce(
    nullif(p_payload ->> 'operationalStatus', ''),
    initiative_row.status
  );

  select * into previous_submitted
  from public.skpe_initiative_check_ins
  where monitoring_cycle_id = cycle_row.id
    and initiative_id = initiative_row.id
    and status = 'submitted'
  for update;
  if found then
    update public.skpe_initiative_check_ins
    set status = 'superseded'
    where id = previous_submitted.id;
  end if;

  select * into previous_validated
  from public.skpe_initiative_check_ins
  where monitoring_cycle_id = cycle_row.id
    and initiative_id = initiative_row.id
    and status = 'validated'
  for update;

  insert into public.skpe_initiative_check_ins (
    organization_id, project_id, formulation_id, monitoring_cycle_id, initiative_id,
    check_in_date, progress, operational_status, health_status, risk_level,
    actual_cost, realized_benefit, forecast_end_date, milestones_summary,
    delays_text, blockers, decision_required, notes, evidence_reference,
    status, supersedes_check_in_id, metadata, created_by
  ) values (
    cycle_row.organization_id, cycle_row.project_id,
    cycle_row.formulation_id, cycle_row.id, initiative_row.id,
    check_in_date_value, progress_value, status_value,
    coalesce(nullif(p_payload ->> 'healthStatus', ''), 'not_assessed'),
    coalesce(nullif(p_payload ->> 'riskLevel', ''), 'not_assessed'),
    nullif(p_payload ->> 'actualCost', '')::numeric,
    nullif(p_payload ->> 'realizedBenefit', '')::numeric,
    nullif(p_payload ->> 'forecastEndDate', '')::date,
    nullif(trim(p_payload ->> 'milestonesSummary'), ''),
    nullif(trim(p_payload ->> 'delaysText'), ''),
    nullif(trim(p_payload ->> 'blockers'), ''),
    nullif(trim(p_payload ->> 'decisionRequired'), ''),
    nullif(trim(p_payload ->> 'notes'), ''),
    nullif(trim(p_payload ->> 'evidenceReference'), ''),
    'submitted', coalesce(previous_submitted.id, previous_validated.id),
    coalesce(p_payload -> 'metadata', '{}'::jsonb), auth.uid()
  ) returning * into saved_check_in;

  perform public.skpe_record_operational_audit(
    saved_check_in.organization_id, saved_check_in.project_id,
    'initiative_check_in', saved_check_in.id,
    'fe08.initiative_check_in_recorded', p_change_reason,
    case
      when previous_submitted.id is not null then to_jsonb(previous_submitted)
      when previous_validated.id is not null then to_jsonb(previous_validated)
      else null
    end,
    to_jsonb(saved_check_in)
  );
  return saved_check_in.id;
end;
$$;

create or replace function public.record_skpe_initiative_outcome_measurement(
  p_cycle_id uuid,
  p_initiative_outcome_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  cycle_row public.skpe_monitoring_cycles%rowtype;
  outcome_row public.skpe_initiative_outcomes%rowtype;
  previous_submitted public.skpe_initiative_outcome_measurements%rowtype;
  previous_validated public.skpe_initiative_outcome_measurements%rowtype;
  saved_measurement public.skpe_initiative_outcome_measurements%rowtype;
  measurement_date_value date;
  measured_value numeric;
  performance_value numeric;
  status_value text;
begin
  perform public.skpe_assert_reason(p_change_reason);
  cycle_row := public.skpe_assert_monitoring_cycle_writable(p_cycle_id);
  if not public.can_manage_skpe_monitoring(cycle_row.organization_id) then
    raise exception 'Acesso negado para registrar medição de resultado.' using errcode = '42501';
  end if;

  select * into outcome_row
  from public.skpe_initiative_outcomes
  where id = p_initiative_outcome_id
    and formulation_id = cycle_row.formulation_id
  for update;
  if not found then
    raise exception 'Resultado da Iniciativa não encontrado no escopo do ciclo.' using errcode = '22023';
  end if;

  measurement_date_value := coalesce(
    nullif(p_payload ->> 'measurementDate', '')::date,
    current_date
  );
  if measurement_date_value < cycle_row.period_start
     or measurement_date_value > cycle_row.period_end then
    raise exception 'A data da medição deve pertencer ao período do ciclo.' using errcode = '22023';
  end if;

  measured_value := nullif(p_payload ->> 'measuredValue', '')::numeric;
  status_value := coalesce(
    nullif(p_payload ->> 'outcomeStatus', ''),
    outcome_row.status
  );
  if outcome_row.measurement_type = 'quantitative' and measured_value is null then
    raise exception 'Resultados quantitativos exigem measuredValue.' using errcode = '22023';
  end if;
  if outcome_row.measurement_type = 'qualitative'
     and length(trim(coalesce(p_payload ->> 'qualitativeAssessment', ''))) = 0 then
    raise exception 'Resultados qualitativos exigem qualitativeAssessment.' using errcode = '22023';
  end if;

  if outcome_row.measurement_type = 'quantitative' then
    performance_value := public.skpe_calculate_strategic_performance(
      outcome_row.polarity,
      outcome_row.baseline_value,
      measured_value,
      outcome_row.target_value,
      nullif(outcome_row.metadata ->> 'rangeLower', '')::numeric,
      nullif(outcome_row.metadata ->> 'rangeUpper', '')::numeric
    );
  end if;

  select * into previous_submitted
  from public.skpe_initiative_outcome_measurements
  where monitoring_cycle_id = cycle_row.id
    and initiative_outcome_id = outcome_row.id
    and status = 'submitted'
  for update;
  if found then
    update public.skpe_initiative_outcome_measurements
    set status = 'superseded'
    where id = previous_submitted.id;
  end if;

  select * into previous_validated
  from public.skpe_initiative_outcome_measurements
  where monitoring_cycle_id = cycle_row.id
    and initiative_outcome_id = outcome_row.id
    and status = 'validated'
  for update;

  insert into public.skpe_initiative_outcome_measurements (
    organization_id, project_id, formulation_id, monitoring_cycle_id,
    initiative_outcome_id, measurement_date, measured_value,
    qualitative_assessment, effective_performance, outcome_status,
    evidence_reference, notes, status, supersedes_measurement_id,
    metadata, created_by
  ) values (
    cycle_row.organization_id, cycle_row.project_id,
    cycle_row.formulation_id, cycle_row.id, outcome_row.id,
    measurement_date_value, measured_value,
    nullif(trim(p_payload ->> 'qualitativeAssessment'), ''),
    performance_value, status_value,
    nullif(trim(p_payload ->> 'evidenceReference'), ''),
    nullif(trim(p_payload ->> 'notes'), ''),
    'submitted', coalesce(previous_submitted.id, previous_validated.id),
    coalesce(p_payload -> 'metadata', '{}'::jsonb), auth.uid()
  ) returning * into saved_measurement;

  perform public.skpe_record_operational_audit(
    saved_measurement.organization_id, saved_measurement.project_id,
    'initiative_outcome_measurement', saved_measurement.id,
    'fe08.initiative_outcome_measurement_recorded', p_change_reason,
    case
      when previous_submitted.id is not null then to_jsonb(previous_submitted)
      when previous_validated.id is not null then to_jsonb(previous_validated)
      else null
    end,
    to_jsonb(saved_measurement)
  );
  return saved_measurement.id;
end;
$$;

-- ============================================================
-- 9. RAE, DECISÕES E APRENDIZADOS
-- ============================================================

create or replace function public.upsert_skpe_strategy_review(
  p_cycle_id uuid,
  p_review_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  cycle_row public.skpe_monitoring_cycles%rowtype;
  previous_data jsonb;
  saved_row public.skpe_strategy_reviews%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);
  cycle_row := public.skpe_assert_monitoring_cycle_writable(p_cycle_id);
  if not public.can_manage_skpe_governance(cycle_row.organization_id) then
    raise exception 'Acesso negado para gerenciar RAE.' using errcode = '42501';
  end if;

  if p_review_id is not null then
    select to_jsonb(review) into previous_data
    from public.skpe_strategy_reviews review
    where review.id = p_review_id and review.monitoring_cycle_id = p_cycle_id;
    if previous_data is null then
      raise exception 'RAE não encontrada no ciclo.' using errcode = '22023';
    end if;
    if previous_data ->> 'status' in ('ratified', 'closed', 'cancelled') then
      raise exception 'RAE ratificada, encerrada ou cancelada não pode ser reeditada.' using errcode = '55000';
    end if;
  end if;

  if coalesce(nullif(p_payload ->> 'status', ''), 'draft') in ('ratified', 'closed') then
    raise exception 'Use a RPC específica de ratificação para concluir a RAE.' using errcode = '55000';
  end if;

  insert into public.skpe_strategy_reviews (
    id, organization_id, project_id, formulation_id, monitoring_cycle_id,
    code, title, review_type, status, scheduled_at, held_at,
    chair_user_id, secretary_user_id, participants,
    executive_summary, conclusions, minutes_reference,
    metadata, created_by, updated_by
  ) values (
    coalesce(p_review_id, gen_random_uuid()),
    cycle_row.organization_id, cycle_row.project_id, cycle_row.formulation_id, cycle_row.id,
    trim(p_payload ->> 'code'), trim(p_payload ->> 'title'),
    coalesce(nullif(p_payload ->> 'reviewType', ''), 'rae'),
    coalesce(nullif(p_payload ->> 'status', ''), 'draft'),
    nullif(p_payload ->> 'scheduledAt', '')::timestamptz,
    nullif(p_payload ->> 'heldAt', '')::timestamptz,
    nullif(p_payload ->> 'chairUserId', '')::uuid,
    nullif(p_payload ->> 'secretaryUserId', '')::uuid,
    coalesce(p_payload -> 'participants', '[]'::jsonb),
    nullif(trim(p_payload ->> 'executiveSummary'), ''),
    nullif(trim(p_payload ->> 'conclusions'), ''),
    nullif(trim(p_payload ->> 'minutesReference'), ''),
    coalesce(p_payload -> 'metadata', '{}'::jsonb), auth.uid(), auth.uid()
  )
  on conflict (id) do update set
    code = excluded.code,
    title = excluded.title,
    review_type = excluded.review_type,
    status = excluded.status,
    scheduled_at = excluded.scheduled_at,
    held_at = excluded.held_at,
    chair_user_id = excluded.chair_user_id,
    secretary_user_id = excluded.secretary_user_id,
    participants = excluded.participants,
    executive_summary = excluded.executive_summary,
    conclusions = excluded.conclusions,
    minutes_reference = excluded.minutes_reference,
    metadata = excluded.metadata,
    updated_by = auth.uid()
  returning * into saved_row;

  perform public.skpe_record_operational_audit(
    saved_row.organization_id, saved_row.project_id,
    'strategy_review', saved_row.id,
    case when previous_data is null then 'fe08.strategy_review_created' else 'fe08.strategy_review_updated' end,
    p_change_reason, previous_data, to_jsonb(saved_row)
  );
  return saved_row.id;
end;
$$;

create or replace function public.upsert_skpe_strategy_review_item(
  p_strategy_review_id uuid,
  p_item_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  review_row public.skpe_strategy_reviews%rowtype;
  previous_data jsonb;
  saved_row public.skpe_strategy_review_items%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into review_row from public.skpe_strategy_reviews where id = p_strategy_review_id;
  if not found then raise exception 'RAE não encontrada.' using errcode = '22023'; end if;
  perform public.skpe_assert_monitoring_cycle_writable(review_row.monitoring_cycle_id);
  if not public.can_manage_skpe_governance(review_row.organization_id) then
    raise exception 'Acesso negado para gerenciar itens da RAE.' using errcode = '42501';
  end if;
  if review_row.status in ('ratified', 'closed', 'cancelled') then
    raise exception 'Itens de RAE ratificada, encerrada ou cancelada são imutáveis.' using errcode = '55000';
  end if;
  perform public.skpe_assert_strategy_review_item_scope(p_strategy_review_id, p_payload);

  if p_item_id is not null then
    select to_jsonb(item) into previous_data from public.skpe_strategy_review_items item
    where item.id = p_item_id and item.strategy_review_id = p_strategy_review_id;
  end if;

  insert into public.skpe_strategy_review_items (
    id, organization_id, project_id, formulation_id, strategy_review_id,
    entity_type, strategic_theme_id, strategic_objective_id, indicator_id,
    okr_id, key_result_id, initiative_id, initiative_action_id,
    initiative_risk_id, initiative_outcome_id, performance_status,
    finding_type, analysis_text, root_cause, recommendation,
    requires_decision, display_order, status, metadata, created_by, updated_by
  ) values (
    coalesce(p_item_id, gen_random_uuid()),
    review_row.organization_id, review_row.project_id, review_row.formulation_id, review_row.id,
    p_payload ->> 'entityType',
    nullif(p_payload ->> 'strategicThemeId', '')::uuid,
    nullif(p_payload ->> 'strategicObjectiveId', '')::uuid,
    nullif(p_payload ->> 'indicatorId', '')::uuid,
    nullif(p_payload ->> 'okrId', '')::uuid,
    nullif(p_payload ->> 'keyResultId', '')::uuid,
    nullif(p_payload ->> 'initiativeId', '')::uuid,
    nullif(p_payload ->> 'initiativeActionId', '')::uuid,
    nullif(p_payload ->> 'initiativeRiskId', '')::uuid,
    nullif(p_payload ->> 'initiativeOutcomeId', '')::uuid,
    coalesce(nullif(p_payload ->> 'performanceStatus', ''), 'not_assessed'),
    coalesce(nullif(p_payload ->> 'findingType', ''), 'information'),
    nullif(trim(p_payload ->> 'analysisText'), ''),
    nullif(trim(p_payload ->> 'rootCause'), ''),
    nullif(trim(p_payload ->> 'recommendation'), ''),
    coalesce((p_payload ->> 'requiresDecision')::boolean, false),
    coalesce(nullif(p_payload ->> 'displayOrder', '')::integer, 0),
    coalesce(nullif(p_payload ->> 'status', ''), 'open'),
    coalesce(p_payload -> 'metadata', '{}'::jsonb), auth.uid(), auth.uid()
  )
  on conflict (id) do update set
    entity_type = excluded.entity_type,
    strategic_theme_id = excluded.strategic_theme_id,
    strategic_objective_id = excluded.strategic_objective_id,
    indicator_id = excluded.indicator_id,
    okr_id = excluded.okr_id,
    key_result_id = excluded.key_result_id,
    initiative_id = excluded.initiative_id,
    initiative_action_id = excluded.initiative_action_id,
    initiative_risk_id = excluded.initiative_risk_id,
    initiative_outcome_id = excluded.initiative_outcome_id,
    performance_status = excluded.performance_status,
    finding_type = excluded.finding_type,
    analysis_text = excluded.analysis_text,
    root_cause = excluded.root_cause,
    recommendation = excluded.recommendation,
    requires_decision = excluded.requires_decision,
    display_order = excluded.display_order,
    status = excluded.status,
    metadata = excluded.metadata,
    updated_by = auth.uid()
  returning * into saved_row;

  perform public.skpe_record_operational_audit(
    saved_row.organization_id, saved_row.project_id,
    'strategy_review_item', saved_row.id,
    case when previous_data is null then 'fe08.strategy_review_item_created' else 'fe08.strategy_review_item_updated' end,
    p_change_reason, previous_data, to_jsonb(saved_row)
  );
  return saved_row.id;
end;
$$;

create or replace function public.record_skpe_governance_decision(
  p_strategy_review_id uuid,
  p_decision_id uuid,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  review_row public.skpe_strategy_reviews%rowtype;
  previous_data jsonb;
  saved_row public.skpe_governance_decisions%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into review_row from public.skpe_strategy_reviews where id = p_strategy_review_id;
  if not found then raise exception 'RAE não encontrada.' using errcode = '22023'; end if;
  perform public.skpe_assert_monitoring_cycle_writable(review_row.monitoring_cycle_id);
  if not public.can_manage_skpe_governance(review_row.organization_id) then
    raise exception 'Acesso negado para registrar decisão.' using errcode = '42501';
  end if;
  if review_row.status in ('ratified', 'closed', 'cancelled') then
    raise exception 'Novas decisões ou alterações estruturais exigem RAE ainda não ratificada.' using errcode = '55000';
  end if;
  if p_decision_id is not null then
    select to_jsonb(decision) into previous_data
    from public.skpe_governance_decisions decision
    where decision.id = p_decision_id
      and decision.strategy_review_id = p_strategy_review_id;
    if previous_data is null then
      raise exception 'Decisão de governança não encontrada na RAE.' using errcode = '22023';
    end if;
    if previous_data ->> 'status' in ('completed', 'cancelled') then
      raise exception 'Decisão concluída ou cancelada deve ser reaberta por transição controlada.' using errcode = '55000';
    end if;
  end if;

  if nullif(p_payload ->> 'strategyReviewItemId', '') is not null and not exists (
    select 1 from public.skpe_strategy_review_items item
    where item.id = (p_payload ->> 'strategyReviewItemId')::uuid
      and item.strategy_review_id = review_row.id
  ) then
    raise exception 'Item de análise fora do escopo da RAE.' using errcode = '22023';
  end if;
  if nullif(p_payload ->> 'linkedInitiativeActionId', '') is not null and not exists (
    select 1 from public.skpe_initiative_actions action
    join public.skpe_initiative_portfolio_items item
      on item.initiative_id = action.initiative_id
     and item.formulation_id = review_row.formulation_id
    where action.id = (p_payload ->> 'linkedInitiativeActionId')::uuid
  ) then
    raise exception 'Ação vinculada fora do escopo da Formulação.' using errcode = '22023';
  end if;
  if nullif(p_payload ->> 'status', '') is not null then
    raise exception 'A situação da decisão deve ser alterada somente pela RPC de transição.' using errcode = '55000';
  end if;

  insert into public.skpe_governance_decisions (
    id, organization_id, project_id, formulation_id, strategy_review_id,
    strategy_review_item_id, code, title, decision_text, rationale,
    decision_type, priority, responsible_user_id, due_date, status,
    escalation_level, linked_initiative_action_id, metadata,
    created_by, updated_by
  ) values (
    coalesce(p_decision_id, gen_random_uuid()),
    review_row.organization_id, review_row.project_id, review_row.formulation_id, review_row.id,
    nullif(p_payload ->> 'strategyReviewItemId', '')::uuid,
    trim(p_payload ->> 'code'), trim(p_payload ->> 'title'), trim(p_payload ->> 'decisionText'),
    nullif(trim(p_payload ->> 'rationale'), ''),
    coalesce(nullif(p_payload ->> 'decisionType', ''), 'corrective_action'),
    coalesce(nullif(p_payload ->> 'priority', ''), 'medium'),
    nullif(p_payload ->> 'responsibleUserId', '')::uuid,
    nullif(p_payload ->> 'dueDate', '')::date,
    coalesce(previous_data ->> 'status', 'open'),
    coalesce(nullif(p_payload ->> 'escalationLevel', ''), 'none'),
    nullif(p_payload ->> 'linkedInitiativeActionId', '')::uuid,
    coalesce(p_payload -> 'metadata', '{}'::jsonb), auth.uid(), auth.uid()
  )
  on conflict (id) do update set
    strategy_review_item_id = excluded.strategy_review_item_id,
    code = excluded.code,
    title = excluded.title,
    decision_text = excluded.decision_text,
    rationale = excluded.rationale,
    decision_type = excluded.decision_type,
    priority = excluded.priority,
    responsible_user_id = excluded.responsible_user_id,
    due_date = excluded.due_date,
    status = excluded.status,
    escalation_level = excluded.escalation_level,
    linked_initiative_action_id = excluded.linked_initiative_action_id,
    metadata = excluded.metadata,
    updated_by = auth.uid()
  returning * into saved_row;

  perform public.skpe_record_operational_audit(
    saved_row.organization_id, saved_row.project_id,
    'governance_decision', saved_row.id,
    case when previous_data is null then 'fe08.governance_decision_created' else 'fe08.governance_decision_updated' end,
    p_change_reason, previous_data, to_jsonb(saved_row)
  );
  return saved_row.id;
end;
$$;

create or replace function public.record_skpe_strategic_learning(
  p_formulation_id uuid,
  p_learning_id uuid,
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
  previous_data jsonb;
  saved_row public.skpe_strategic_learnings%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into formulation_row from public.skpe_strategic_formulations where id = p_formulation_id;
  if not found then raise exception 'Formulação Estratégica não encontrada.' using errcode = '22023'; end if;
  if not public.can_manage_skpe_governance(formulation_row.organization_id) then
    raise exception 'Acesso negado para registrar aprendizado.' using errcode = '42501';
  end if;
  if p_learning_id is not null then
    select to_jsonb(learning) into previous_data
    from public.skpe_strategic_learnings learning
    where learning.id = p_learning_id
      and learning.formulation_id = p_formulation_id;
    if previous_data is null then
      raise exception 'Aprendizado estratégico não encontrado na Formulação.' using errcode = '22023';
    end if;
    if previous_data ->> 'status' in ('accepted', 'rejected', 'incorporated', 'archived') then
      raise exception 'Aprendizado em situação decisória deve ser reaberto por transição controlada.' using errcode = '55000';
    end if;
  end if;
  if nullif(p_payload ->> 'status', '') is not null then
    raise exception 'A situação do aprendizado deve ser alterada somente pela RPC de transição.' using errcode = '55000';
  end if;

  if nullif(p_payload ->> 'monitoringCycleId', '') is not null and not exists (
    select 1 from public.skpe_monitoring_cycles cycle
    where cycle.id = (p_payload ->> 'monitoringCycleId')::uuid
      and cycle.formulation_id = p_formulation_id
  ) then raise exception 'Ciclo de monitoramento fora do escopo.' using errcode = '22023'; end if;
  if nullif(p_payload ->> 'strategyReviewId', '') is not null and not exists (
    select 1 from public.skpe_strategy_reviews review
    where review.id = (p_payload ->> 'strategyReviewId')::uuid
      and review.formulation_id = p_formulation_id
  ) then raise exception 'RAE fora do escopo.' using errcode = '22023'; end if;
  if nullif(p_payload ->> 'targetRevisionFormulationId', '') is not null and not exists (
    select 1 from public.skpe_strategic_formulations target
    where target.id = (p_payload ->> 'targetRevisionFormulationId')::uuid
      and target.organization_id = formulation_row.organization_id
      and target.project_id = formulation_row.project_id
  ) then raise exception 'Revisão-alvo fora do mesmo projeto estratégico.' using errcode = '22023'; end if;

  insert into public.skpe_strategic_learnings (
    id, organization_id, project_id, formulation_id,
    monitoring_cycle_id, strategy_review_id, code, title,
    evidence_text, interpretation_text, lesson_text, impact_level,
    recommendation, status, governance_decision,
    target_revision_formulation_id, metadata, created_by, updated_by
  ) values (
    coalesce(p_learning_id, gen_random_uuid()),
    formulation_row.organization_id, formulation_row.project_id, formulation_row.id,
    nullif(p_payload ->> 'monitoringCycleId', '')::uuid,
    nullif(p_payload ->> 'strategyReviewId', '')::uuid,
    trim(p_payload ->> 'code'), trim(p_payload ->> 'title'),
    trim(p_payload ->> 'evidenceText'),
    nullif(trim(p_payload ->> 'interpretationText'), ''),
    trim(p_payload ->> 'lessonText'),
    coalesce(nullif(p_payload ->> 'impactLevel', ''), 'medium'),
    nullif(trim(p_payload ->> 'recommendation'), ''),
    coalesce(previous_data ->> 'status', 'identified'),
    nullif(trim(p_payload ->> 'governanceDecision'), ''),
    nullif(p_payload ->> 'targetRevisionFormulationId', '')::uuid,
    coalesce(p_payload -> 'metadata', '{}'::jsonb), auth.uid(), auth.uid()
  )
  on conflict (id) do update set
    monitoring_cycle_id = excluded.monitoring_cycle_id,
    strategy_review_id = excluded.strategy_review_id,
    code = excluded.code,
    title = excluded.title,
    evidence_text = excluded.evidence_text,
    interpretation_text = excluded.interpretation_text,
    lesson_text = excluded.lesson_text,
    impact_level = excluded.impact_level,
    recommendation = excluded.recommendation,
    status = excluded.status,
    governance_decision = excluded.governance_decision,
    target_revision_formulation_id = excluded.target_revision_formulation_id,
    metadata = excluded.metadata,
    updated_by = auth.uid()
  returning * into saved_row;

  perform public.skpe_record_operational_audit(
    saved_row.organization_id, saved_row.project_id,
    'strategic_learning', saved_row.id,
    case when previous_data is null then 'fe08.strategic_learning_created' else 'fe08.strategic_learning_updated' end,
    p_change_reason, previous_data, to_jsonb(saved_row)
  );
  return saved_row.id;
end;
$$;

create or replace function public.transition_skpe_monitoring_cycle(
  p_cycle_id uuid,
  p_action text,
  p_change_reason text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_row public.skpe_monitoring_cycles%rowtype;
  updated_row public.skpe_monitoring_cycles%rowtype;
  action_value text := lower(trim(p_action));
  next_status text;
  readiness jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  previous_row := public.skpe_assert_monitoring_cycle_writable(p_cycle_id);

  if action_value in ('start_collection', 'submit_review') then
    if not public.can_manage_skpe_monitoring(previous_row.organization_id) then
      raise exception 'Acesso negado para transicionar o ciclo.' using errcode = '42501';
    end if;
  else
    if not public.can_manage_skpe_governance(previous_row.organization_id) then
      raise exception 'Acesso negado para transicionar o ciclo.' using errcode = '42501';
    end if;
  end if;

  next_status := case action_value
    when 'start_collection' then 'collecting'
    when 'submit_review' then 'under_review'
    when 'request_ratification' then 'pending_ratification'
    when 'cancel' then 'cancelled'
    else null
  end;
  if next_status is null then
    raise exception 'Ação inválida. Use start_collection, submit_review, request_ratification ou cancel.' using errcode = '22023';
  end if;

  if action_value = 'start_collection' and previous_row.status not in ('open', 'reopened') then
    raise exception 'O ciclo precisa estar aberto ou reaberto.' using errcode = '55000';
  elsif action_value = 'submit_review' and previous_row.status not in ('open', 'collecting', 'reopened') then
    raise exception 'O ciclo precisa estar em coleta.' using errcode = '55000';
  elsif action_value = 'request_ratification' and previous_row.status <> 'under_review' then
    raise exception 'O ciclo precisa estar sob análise.' using errcode = '55000';
  end if;

  if action_value = 'submit_review' then
    readiness := public.get_skpe_monitoring_readiness(previous_row.id);
    if not coalesce((readiness ->> 'readyForReview')::boolean, false) then
      raise exception 'O ciclo ainda não está pronto para análise. Pendências: %',
        readiness -> 'reviewBlockingIssues' using errcode = '55000';
    end if;
  end if;

  update public.skpe_monitoring_cycles set
    status = next_status,
    submitted_for_review_at = case when next_status = 'under_review' then timezone('utc', now()) else submitted_for_review_at end,
    submitted_for_review_by = case when next_status = 'under_review' then auth.uid() else submitted_for_review_by end,
    cancellation_reason = case when next_status = 'cancelled' then p_change_reason else cancellation_reason end,
    updated_by = auth.uid()
  where id = previous_row.id returning * into updated_row;

  perform public.skpe_record_operational_audit(
    updated_row.organization_id, updated_row.project_id,
    'monitoring_cycle', updated_row.id,
    'fe08.monitoring_cycle_' || action_value,
    p_change_reason, to_jsonb(previous_row), to_jsonb(updated_row)
  );
  return updated_row.status;
end;
$$;

create or replace function public.transition_skpe_monitoring_record(
  p_record_type text,
  p_record_id uuid,
  p_action text,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  type_value text := lower(trim(p_record_type));
  action_value text := lower(trim(p_action));
  target_status text;
  organization_value uuid;
  project_value uuid;
  cycle_value uuid;
  previous_data jsonb;
  new_data jsonb;
  key_result_check_in public.skpe_key_result_check_ins%rowtype;
  initiative_check_in public.skpe_initiative_check_ins%rowtype;
  outcome_measurement public.skpe_initiative_outcome_measurements%rowtype;
  previous_key_result public.skpe_key_results%rowtype;
  updated_key_result public.skpe_key_results%rowtype;
  previous_initiative public.skpe_initiatives%rowtype;
  updated_initiative public.skpe_initiatives%rowtype;
  previous_outcome public.skpe_initiative_outcomes%rowtype;
  updated_outcome public.skpe_initiative_outcomes%rowtype;
  okr_progress numeric;
begin
  perform public.skpe_assert_reason(p_change_reason);
  target_status := case action_value
    when 'validate' then 'validated'
    when 'reject' then 'rejected'
    when 'resubmit' then 'submitted'
    else null
  end;
  if target_status is null then
    raise exception 'Ação inválida. Use validate, reject ou resubmit.' using errcode = '22023';
  end if;

  if type_value = 'indicator_measurement' then
    select organization_id, project_id, monitoring_cycle_id, to_jsonb(m)
      into organization_value, project_value, cycle_value, previous_data
    from public.skpe_indicator_measurements m
    where id = p_record_id
    for update;
  elsif type_value = 'key_result_check_in' then
    select organization_id, project_id, monitoring_cycle_id, to_jsonb(c)
      into organization_value, project_value, cycle_value, previous_data
    from public.skpe_key_result_check_ins c
    where id = p_record_id
    for update;
  elsif type_value = 'initiative_check_in' then
    select organization_id, project_id, monitoring_cycle_id, to_jsonb(c)
      into organization_value, project_value, cycle_value, previous_data
    from public.skpe_initiative_check_ins c
    where id = p_record_id
    for update;
  elsif type_value = 'initiative_outcome_measurement' then
    select organization_id, project_id, monitoring_cycle_id, to_jsonb(m)
      into organization_value, project_value, cycle_value, previous_data
    from public.skpe_initiative_outcome_measurements m
    where id = p_record_id
    for update;
  else
    raise exception 'Tipo de registro inválido.' using errcode = '22023';
  end if;

  if previous_data is null then
    raise exception 'Registro de monitoramento não encontrado.' using errcode = '22023';
  end if;
  perform public.skpe_assert_monitoring_cycle_writable(cycle_value);

  if action_value in ('validate', 'reject')
     and previous_data ->> 'status' <> 'submitted' then
    raise exception 'Somente registros submetidos podem ser validados ou rejeitados.' using errcode = '55000';
  end if;
  if action_value = 'resubmit'
     and previous_data ->> 'status' <> 'rejected' then
    raise exception 'Somente registros rejeitados podem ser ressubmetidos.' using errcode = '55000';
  end if;

  if action_value in ('validate', 'reject') then
    if not public.can_manage_skpe_governance(organization_value) then
      raise exception 'Acesso negado para validar ou rejeitar registro.' using errcode = '42501';
    end if;
  elsif not public.can_manage_skpe_monitoring(organization_value) then
    raise exception 'Acesso negado para ressubmeter registro.' using errcode = '42501';
  end if;

  if action_value = 'validate' then
    if type_value = 'indicator_measurement' then
      update public.skpe_indicator_measurements current_record
      set status = 'superseded'
      where current_record.monitoring_cycle_id = cycle_value
        and current_record.indicator_id = (previous_data ->> 'indicator_id')::uuid
        and current_record.status = 'validated'
        and current_record.id <> p_record_id;
    elsif type_value = 'key_result_check_in' then
      update public.skpe_key_result_check_ins current_record
      set status = 'superseded'
      where current_record.monitoring_cycle_id = cycle_value
        and current_record.key_result_id = (previous_data ->> 'key_result_id')::uuid
        and current_record.status = 'validated'
        and current_record.id <> p_record_id;
    elsif type_value = 'initiative_check_in' then
      update public.skpe_initiative_check_ins current_record
      set status = 'superseded'
      where current_record.monitoring_cycle_id = cycle_value
        and current_record.initiative_id = (previous_data ->> 'initiative_id')::uuid
        and current_record.status = 'validated'
        and current_record.id <> p_record_id;
    else
      update public.skpe_initiative_outcome_measurements current_record
      set status = 'superseded'
      where current_record.monitoring_cycle_id = cycle_value
        and current_record.initiative_outcome_id = (previous_data ->> 'initiative_outcome_id')::uuid
        and current_record.status = 'validated'
        and current_record.id <> p_record_id;
    end if;
  end if;

  if type_value = 'indicator_measurement' then
    update public.skpe_indicator_measurements
    set
      status = target_status,
      validated_at = case when target_status = 'validated' then timezone('utc', now()) else null end,
      validated_by = case when target_status = 'validated' then auth.uid() else null end,
      metadata = coalesce(metadata, '{}'::jsonb)
        || jsonb_build_object('lastTransitionReason', p_change_reason)
    where id = p_record_id
    returning to_jsonb(skpe_indicator_measurements) into new_data;
  elsif type_value = 'key_result_check_in' then
    update public.skpe_key_result_check_ins
    set
      status = target_status,
      validated_at = case when target_status = 'validated' then timezone('utc', now()) else null end,
      validated_by = case when target_status = 'validated' then auth.uid() else null end,
      metadata = coalesce(metadata, '{}'::jsonb)
        || jsonb_build_object('lastTransitionReason', p_change_reason)
    where id = p_record_id
    returning * into key_result_check_in;
    new_data := to_jsonb(key_result_check_in);
  elsif type_value = 'initiative_check_in' then
    update public.skpe_initiative_check_ins
    set
      status = target_status,
      validated_at = case when target_status = 'validated' then timezone('utc', now()) else null end,
      validated_by = case when target_status = 'validated' then auth.uid() else null end,
      metadata = coalesce(metadata, '{}'::jsonb)
        || jsonb_build_object('lastTransitionReason', p_change_reason)
    where id = p_record_id
    returning * into initiative_check_in;
    new_data := to_jsonb(initiative_check_in);
  else
    update public.skpe_initiative_outcome_measurements
    set
      status = target_status,
      validated_at = case when target_status = 'validated' then timezone('utc', now()) else null end,
      validated_by = case when target_status = 'validated' then auth.uid() else null end,
      metadata = coalesce(metadata, '{}'::jsonb)
        || jsonb_build_object('lastTransitionReason', p_change_reason)
    where id = p_record_id
    returning * into outcome_measurement;
    new_data := to_jsonb(outcome_measurement);
  end if;

  if action_value = 'validate' and type_value = 'key_result_check_in' then
    select * into previous_key_result
    from public.skpe_key_results
    where id = key_result_check_in.key_result_id
    for update;

    update public.skpe_key_results
    set
      current_value = key_result_check_in.current_value,
      progress = key_result_check_in.effective_progress,
      status = key_result_check_in.operational_status,
      metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
        'automaticProgress', key_result_check_in.automatic_progress,
        'manualProgressOverride', key_result_check_in.manual_progress_override,
        'lastMeasurementAt', timezone('utc', now()),
        'lastMeasurementBy', auth.uid(),
        'lastCheckInId', key_result_check_in.id
      ),
      updated_by = auth.uid()
    where id = key_result_check_in.key_result_id
    returning * into updated_key_result;

    perform public.skpe_record_operational_audit(
      updated_key_result.organization_id, updated_key_result.project_id,
      'key_result', updated_key_result.id,
      'fe08.key_result_projection_validated', p_change_reason,
      to_jsonb(previous_key_result), to_jsonb(updated_key_result)
    );
    okr_progress := public.skpe_recalculate_okr_progress(
      updated_key_result.okr_id,
      p_change_reason
    );
    new_data := new_data || jsonb_build_object('okrProgress', okr_progress);
  elsif action_value = 'validate' and type_value = 'initiative_check_in' then
    select * into previous_initiative
    from public.skpe_initiatives
    where id = initiative_check_in.initiative_id
    for update;

    update public.skpe_initiatives
    set
      status = initiative_check_in.operational_status,
      progress = initiative_check_in.progress,
      actual_cost = coalesce(initiative_check_in.actual_cost, actual_cost),
      realized_benefit = coalesce(initiative_check_in.realized_benefit, realized_benefit),
      risk_level = case
        when initiative_check_in.risk_level = 'not_assessed' then risk_level
        else initiative_check_in.risk_level
      end,
      health_status = case
        when initiative_check_in.health_status = 'not_assessed' then health_status
        else initiative_check_in.health_status
      end,
      completed_at = case
        when initiative_check_in.operational_status = 'completed'
          then coalesce(completed_at, timezone('utc', now()))
        else completed_at
      end,
      last_update_at = timezone('utc', now()),
      updated_by = auth.uid()
    where id = initiative_check_in.initiative_id
    returning * into updated_initiative;

    perform public.skpe_record_operational_audit(
      updated_initiative.organization_id, updated_initiative.project_id,
      'initiative', updated_initiative.id,
      'fe08.initiative_projection_validated', p_change_reason,
      to_jsonb(previous_initiative), to_jsonb(updated_initiative)
    );
  elsif action_value = 'validate'
        and type_value = 'initiative_outcome_measurement' then
    select * into previous_outcome
    from public.skpe_initiative_outcomes
    where id = outcome_measurement.initiative_outcome_id
    for update;

    update public.skpe_initiative_outcomes
    set
      current_value = coalesce(outcome_measurement.measured_value, current_value),
      status = outcome_measurement.outcome_status,
      realized_at = case
        when outcome_measurement.outcome_status = 'achieved'
          then coalesce(realized_at, timezone('utc', now()))
        else realized_at
      end,
      metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
        'lastMeasurementId', outcome_measurement.id,
        'lastPerformance', outcome_measurement.effective_performance,
        'lastMeasurementAt', timezone('utc', now())
      ),
      updated_by = auth.uid()
    where id = outcome_measurement.initiative_outcome_id
    returning * into updated_outcome;

    perform public.skpe_record_operational_audit(
      updated_outcome.organization_id, updated_outcome.project_id,
      'initiative_outcome', updated_outcome.id,
      'fe08.initiative_outcome_projection_validated', p_change_reason,
      to_jsonb(previous_outcome), to_jsonb(updated_outcome)
    );
  end if;

  perform public.skpe_record_operational_audit(
    organization_value, project_value,
    type_value, p_record_id,
    'fe08.' || type_value || '_' || action_value,
    p_change_reason, previous_data, new_data
  );
  return p_record_id;
end;
$$;

create or replace function public.transition_skpe_governance_decision(
  p_decision_id uuid,
  p_action text,
  p_completion_notes text,
  p_change_reason text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_row public.skpe_governance_decisions%rowtype;
  updated_row public.skpe_governance_decisions%rowtype;
  action_value text := lower(trim(p_action));
  next_status text;
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into previous_row from public.skpe_governance_decisions where id = p_decision_id for update;
  if not found then raise exception 'Decisão de governança não encontrada.' using errcode = '22023'; end if;

  if action_value = 'ratify' then
    if not public.can_ratify_skpe_governance(previous_row.organization_id) then
      raise exception 'Acesso negado para ratificar decisão.' using errcode = '42501';
    end if;
    if not exists (
      select 1 from public.skpe_strategy_reviews review
      where review.id = previous_row.strategy_review_id
        and review.status in ('ratified', 'closed')
    ) then raise exception 'A RAE deve estar ratificada antes da decisão.' using errcode = '55000'; end if;
    update public.skpe_governance_decisions set
      ratified_at = timezone('utc', now()), ratified_by = auth.uid(), updated_by = auth.uid()
    where id = previous_row.id returning * into updated_row;
  else
    if not public.can_manage_skpe_governance(previous_row.organization_id) then
      raise exception 'Acesso negado para transicionar decisão.' using errcode = '42501';
    end if;
    next_status := case action_value
      when 'start' then 'in_progress'
      when 'block' then 'blocked'
      when 'complete' then 'completed'
      when 'cancel' then 'cancelled'
      when 'mark_overdue' then 'overdue'
      when 'reopen' then 'open'
      else null
    end;
    if next_status is null then
      raise exception 'Ação inválida para decisão de governança.' using errcode = '22023';
    end if;
    update public.skpe_governance_decisions set
      status = next_status,
      completed_at = case when next_status = 'completed' then timezone('utc', now()) else null end,
      completion_notes = case when next_status in ('completed', 'cancelled') then nullif(trim(p_completion_notes), '') else completion_notes end,
      updated_by = auth.uid()
    where id = previous_row.id returning * into updated_row;
  end if;

  perform public.skpe_record_operational_audit(
    updated_row.organization_id, updated_row.project_id,
    'governance_decision', updated_row.id,
    'fe08.governance_decision_' || action_value,
    p_change_reason, to_jsonb(previous_row), to_jsonb(updated_row)
  );
  return updated_row.status;
end;
$$;

create or replace function public.transition_skpe_strategic_learning(
  p_learning_id uuid,
  p_action text,
  p_governance_decision text,
  p_change_reason text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_row public.skpe_strategic_learnings%rowtype;
  updated_row public.skpe_strategic_learnings%rowtype;
  action_value text := lower(trim(p_action));
  next_status text;
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into previous_row
  from public.skpe_strategic_learnings
  where id = p_learning_id
  for update;
  if not found then
    raise exception 'Aprendizado estratégico não encontrado.' using errcode = '22023';
  end if;

  if action_value = 'incorporate' then
    if not public.can_ratify_skpe_governance(previous_row.organization_id) then
      raise exception 'Acesso negado para incorporar aprendizado.' using errcode = '42501';
    end if;
    if previous_row.status <> 'accepted' then
      raise exception 'Somente aprendizado aceito pode ser incorporado.' using errcode = '55000';
    end if;
    next_status := 'incorporated';
  else
    if not public.can_manage_skpe_governance(previous_row.organization_id) then
      raise exception 'Acesso negado para transicionar aprendizado.' using errcode = '42501';
    end if;
    next_status := case action_value
      when 'analyze' then 'under_analysis'
      when 'accept' then 'accepted'
      when 'reject' then 'rejected'
      when 'archive' then 'archived'
      when 'reopen' then 'identified'
      else null
    end;
    if next_status is null then
      raise exception 'Ação inválida para aprendizado estratégico.' using errcode = '22023';
    end if;
  end if;

  update public.skpe_strategic_learnings
  set
    status = next_status,
    governance_decision = coalesce(
      nullif(trim(p_governance_decision), ''),
      governance_decision
    ),
    incorporated_at = case
      when next_status = 'incorporated' then timezone('utc', now())
      else incorporated_at
    end,
    incorporated_by = case
      when next_status = 'incorporated' then auth.uid()
      else incorporated_by
    end,
    updated_by = auth.uid()
  where id = previous_row.id
  returning * into updated_row;

  perform public.skpe_record_operational_audit(
    updated_row.organization_id, updated_row.project_id,
    'strategic_learning', updated_row.id,
    'fe08.strategic_learning_' || action_value,
    p_change_reason, to_jsonb(previous_row), to_jsonb(updated_row)
  );
  return updated_row.status;
end;
$$;

-- ============================================================
-- 10. PRONTIDÃO DO CICLO, SNAPSHOT E FECHAMENTO
-- ============================================================

create or replace function public.get_skpe_monitoring_readiness(p_cycle_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  cycle_row public.skpe_monitoring_cycles%rowtype;
  package_row public.skpe_monitoring_packages%rowtype;
  blocking_issues jsonb := '[]'::jsonb;
  review_blocking_issues jsonb := '[]'::jsonb;
  recommendations jsonb := '[]'::jsonb;
begin
  select * into cycle_row from public.skpe_monitoring_cycles where id = p_cycle_id;
  if not found then raise exception 'Ciclo de monitoramento não encontrado.' using errcode = '22023'; end if;
  if not public.can_view_skpe_monitoring(cycle_row.organization_id) then
    raise exception 'Acesso negado ao ciclo de monitoramento.' using errcode = '42501';
  end if;
  select * into package_row from public.skpe_monitoring_packages where id = cycle_row.monitoring_package_id;

  if exists (
    select 1 from public.skpe_indicators indicator
    where indicator.formulation_id = cycle_row.formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and not exists (
        select 1 from public.skpe_indicator_measurements measurement
        where measurement.monitoring_cycle_id = cycle_row.id
          and measurement.indicator_id = indicator.id
          and measurement.status in ('submitted', 'validated')
      )
  ) then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_INDICATOR_MEASUREMENT_MISSING', 'severity', 'blocking',
      'message', 'Há Indicador Estratégico ativo sem medição no ciclo.'
    ));
  end if;

  if exists (
    select 1 from public.skpe_key_results kr
    where kr.formulation_id = cycle_row.formulation_id
      and kr.status in ('active', 'at_risk')
      and not exists (
        select 1 from public.skpe_key_result_check_ins check_in
        where check_in.monitoring_cycle_id = cycle_row.id
          and check_in.key_result_id = kr.id
          and check_in.status in ('submitted', 'validated')
      )
  ) then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_KEY_RESULT_CHECK_IN_MISSING', 'severity', 'blocking',
      'message', 'Há Resultado-Chave ativo sem check-in no ciclo.'
    ));
  end if;

  if exists (
    select 1 from public.skpe_initiative_portfolio_items item
    where item.formulation_id = cycle_row.formulation_id
      and item.selection_status = 'selected'
      and not exists (
        select 1 from public.skpe_initiative_check_ins check_in
        where check_in.monitoring_cycle_id = cycle_row.id
          and check_in.initiative_id = item.initiative_id
          and check_in.status in ('submitted', 'validated')
      )
  ) then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_INITIATIVE_CHECK_IN_MISSING', 'severity', 'blocking',
      'message', 'Há Iniciativa selecionada sem check-in no ciclo.'
    ));
  end if;

  if not exists (
    select 1 from public.skpe_strategy_reviews review
    where review.monitoring_cycle_id = cycle_row.id
      and review.review_type = 'rae'
      and review.status in ('ratified', 'closed')
  ) then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_RAE_NOT_RATIFIED', 'severity', 'blocking',
      'message', 'A RAE do ciclo ainda não foi ratificada.'
    ));
  end if;

  if exists (
    select 1 from public.skpe_governance_decisions decision
    join public.skpe_strategy_reviews review on review.id = decision.strategy_review_id
    where review.monitoring_cycle_id = cycle_row.id
      and decision.priority in ('high', 'critical')
      and (decision.responsible_user_id is null or decision.due_date is null)
      and decision.status not in ('completed', 'cancelled')
  ) then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_CRITICAL_DECISION_INCOMPLETE', 'severity', 'blocking',
      'message', 'Há decisão de alta criticidade sem responsável ou prazo.'
    ));
  end if;

  if package_row.data_quality_required and (
    exists (
      select 1 from public.skpe_indicator_measurements m
      where m.monitoring_cycle_id = cycle_row.id and m.status = 'submitted'
    )
    or exists (
      select 1 from public.skpe_key_result_check_ins c
      where c.monitoring_cycle_id = cycle_row.id and c.status = 'submitted'
    )
    or exists (
      select 1 from public.skpe_initiative_check_ins c
      where c.monitoring_cycle_id = cycle_row.id and c.status = 'submitted'
    )
    or exists (
      select 1 from public.skpe_initiative_outcome_measurements m
      where m.monitoring_cycle_id = cycle_row.id and m.status = 'submitted'
    )
  ) then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_RECORDS_NOT_VALIDATED', 'severity', 'blocking',
      'message', 'Existem medições ou check-ins submetidos que ainda não foram validados.'
    ));
  end if;

  if package_row.confidence_required_for_key_results and exists (
    select 1 from public.skpe_key_result_check_ins c
    where c.monitoring_cycle_id = cycle_row.id
      and c.status in ('submitted', 'validated')
      and c.confidence_level = 'not_assessed'
  ) then
    blocking_issues := blocking_issues || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_KEY_RESULT_CONFIDENCE_MISSING', 'severity', 'blocking',
      'message', 'Há check-in de Resultado-Chave sem nível de confiança avaliado.'
    ));
  end if;

  if package_row.evidence_required and exists (
    select 1 from public.skpe_indicator_measurements measurement
    where measurement.monitoring_cycle_id = cycle_row.id
      and measurement.status in ('submitted', 'validated')
      and length(trim(coalesce(measurement.evidence_reference, ''))) = 0
  ) then
    recommendations := recommendations || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_MEASUREMENT_EVIDENCE_MISSING', 'severity', 'recommendation',
      'message', 'Há medições de Indicadores sem referência de evidência.'
    ));
  end if;

  if package_row.evidence_required and (
    exists (
      select 1 from public.skpe_key_result_check_ins c
      where c.monitoring_cycle_id = cycle_row.id
        and c.status in ('submitted', 'validated')
        and length(trim(coalesce(c.evidence_reference, ''))) = 0
    )
    or exists (
      select 1 from public.skpe_initiative_check_ins c
      where c.monitoring_cycle_id = cycle_row.id
        and c.status in ('submitted', 'validated')
        and length(trim(coalesce(c.evidence_reference, ''))) = 0
    )
    or exists (
      select 1 from public.skpe_initiative_outcome_measurements m
      where m.monitoring_cycle_id = cycle_row.id
        and m.status in ('submitted', 'validated')
        and length(trim(coalesce(m.evidence_reference, ''))) = 0
    )
  ) then
    recommendations := recommendations || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_CHECK_IN_EVIDENCE_MISSING', 'severity', 'recommendation',
      'message', 'Há check-ins ou medições de resultados sem referência de evidência.'
    ));
  end if;

  if exists (
    select 1 from public.skpe_governance_decisions decision
    join public.skpe_strategy_reviews review on review.id = decision.strategy_review_id
    where review.monitoring_cycle_id = cycle_row.id
      and decision.status not in ('completed', 'cancelled')
      and decision.due_date < current_date
  ) then
    recommendations := recommendations || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_OVERDUE_DECISION', 'severity', 'recommendation',
      'message', 'Há decisão de governança vencida.'
    ));
  end if;

  if cycle_row.status not in ('closed', 'cancelled')
     and current_date > cycle_row.period_end + package_row.late_tolerance_days then
    recommendations := recommendations || jsonb_build_array(jsonb_build_object(
      'code', 'FE08_CYCLE_LATE', 'severity', 'recommendation',
      'message', 'O ciclo ultrapassou o período e a tolerância configurada sem fechamento.'
    ));
  end if;

  select coalesce(jsonb_agg(issue), '[]'::jsonb)
  into review_blocking_issues
  from jsonb_array_elements(blocking_issues) issue
  where issue ->> 'code' not in (
    'FE08_RAE_NOT_RATIFIED',
    'FE08_CRITICAL_DECISION_INCOMPLETE'
  );

  return jsonb_build_object(
    'cycleId', cycle_row.id,
    'cycleStatus', cycle_row.status,
    'readyForReview', jsonb_array_length(review_blocking_issues) = 0,
    'readyForClose', jsonb_array_length(blocking_issues) = 0,
    'reviewBlockingIssues', review_blocking_issues,
    'blockingIssues', blocking_issues,
    'recommendations', recommendations,
    'metrics', jsonb_build_object(
      'indicatorMeasurements', (select count(*) from public.skpe_indicator_measurements m where m.monitoring_cycle_id = cycle_row.id and m.status in ('submitted','validated')),
      'keyResultCheckIns', (select count(*) from public.skpe_key_result_check_ins c where c.monitoring_cycle_id = cycle_row.id and c.status in ('submitted','validated')),
      'initiativeCheckIns', (select count(*) from public.skpe_initiative_check_ins c where c.monitoring_cycle_id = cycle_row.id and c.status in ('submitted','validated')),
      'reviews', (select count(*) from public.skpe_strategy_reviews r where r.monitoring_cycle_id = cycle_row.id),
      'openDecisions', (
        select count(*) from public.skpe_governance_decisions d
        join public.skpe_strategy_reviews r on r.id = d.strategy_review_id
        where r.monitoring_cycle_id = cycle_row.id and d.status not in ('completed','cancelled')
      )
    )
  );
end;
$$;

create or replace function public.get_skpe_strategic_performance(p_cycle_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  cycle_row public.skpe_monitoring_cycles%rowtype;
  package_row public.skpe_monitoring_packages%rowtype;
  vision_performance numeric;
begin
  select * into cycle_row
  from public.skpe_monitoring_cycles
  where id = p_cycle_id;
  if not found then
    raise exception 'Ciclo de monitoramento não encontrado.' using errcode = '22023';
  end if;
  if not public.can_view_skpe_monitoring(cycle_row.organization_id) then
    raise exception 'Acesso negado ao desempenho estratégico.' using errcode = '42501';
  end if;

  select * into package_row
  from public.skpe_monitoring_packages
  where id = cycle_row.monitoring_package_id;

  select round(
    sum(measurement.effective_performance * weighted_indicator.weight_value)
    / nullif(sum(weighted_indicator.weight_value), 0),
    2
  )
  into vision_performance
  from public.skpe_indicator_measurements measurement
  join public.skpe_indicators indicator
    on indicator.id = measurement.indicator_id
  cross join lateral (
    select case
      when package_row.aggregation_policy = 'explicit_weight'
        then case
          when indicator.metadata ->> 'monitoringWeight' ~ '^[0-9]+([.][0-9]+)?$'
            then case
              when (indicator.metadata ->> 'monitoringWeight')::numeric > 0
                then (indicator.metadata ->> 'monitoringWeight')::numeric
              else 1::numeric
            end
          else 1::numeric
        end
      else 1::numeric
    end as weight_value
  ) weighted_indicator
  where measurement.monitoring_cycle_id = cycle_row.id
    and measurement.status in ('submitted', 'validated')
    and not (
      measurement.status = 'validated'
      and exists (
        select 1
        from public.skpe_indicator_measurements submitted_measurement
        where submitted_measurement.monitoring_cycle_id = measurement.monitoring_cycle_id
          and submitted_measurement.indicator_id = measurement.indicator_id
          and submitted_measurement.status = 'submitted'
      )
    )
    and indicator.indicator_scope = 'strategic_kpi'
    and indicator.status = 'active';

  return jsonb_build_object(
    'aggregationPolicy', package_row.aggregation_policy,
    'explicitWeightField', case
      when package_row.aggregation_policy = 'explicit_weight'
        then 'indicator.metadata.monitoringWeight'
      else null
    end,
    'objectives', coalesce((
      select jsonb_agg(jsonb_build_object(
        'strategicObjectiveId', objective.id,
        'code', objective.code,
        'name', objective.name,
        'strategicThemeId', objective.strategic_theme_id,
        'perspectiveId', objective.perspective_id,
        'performance', performance.objective_performance,
        'performanceStatus', public.skpe_monitoring_performance_status(
          package_row.id,
          performance.objective_performance
        ),
        'indicatorCount', performance.indicator_count,
        'totalWeight', performance.total_weight
      ) order by objective.code)
      from public.skpe_strategic_objectives objective
      join lateral (
        select
          round(
            sum(measurement.effective_performance * weighted_indicator.weight_value)
            / nullif(sum(weighted_indicator.weight_value), 0),
            2
          ) as objective_performance,
          count(*) as indicator_count,
          round(sum(weighted_indicator.weight_value), 4) as total_weight
        from public.skpe_indicators indicator
        join public.skpe_indicator_measurements measurement
          on measurement.indicator_id = indicator.id
         and measurement.monitoring_cycle_id = cycle_row.id
         and measurement.status in ('submitted', 'validated')
         and not (
           measurement.status = 'validated'
           and exists (
             select 1
             from public.skpe_indicator_measurements submitted_measurement
             where submitted_measurement.monitoring_cycle_id = measurement.monitoring_cycle_id
               and submitted_measurement.indicator_id = measurement.indicator_id
               and submitted_measurement.status = 'submitted'
           )
         )
        cross join lateral (
          select case
            when package_row.aggregation_policy = 'explicit_weight'
              then case
                when indicator.metadata ->> 'monitoringWeight' ~ '^[0-9]+([.][0-9]+)?$'
                  then case
                    when (indicator.metadata ->> 'monitoringWeight')::numeric > 0
                      then (indicator.metadata ->> 'monitoringWeight')::numeric
                    else 1::numeric
                  end
                else 1::numeric
              end
            else 1::numeric
          end as weight_value
        ) weighted_indicator
        where indicator.formulation_id = cycle_row.formulation_id
          and indicator.strategic_objective_id = objective.id
          and indicator.indicator_scope = 'strategic_kpi'
          and indicator.status = 'active'
      ) performance on performance.indicator_count > 0
      where objective.formulation_id = cycle_row.formulation_id
        and objective.status <> 'archived'
    ), '[]'::jsonb),
    'themes', coalesce((
      with theme_performance as (
        select
          objective.strategic_theme_id,
          sum(measurement.effective_performance * weighted_indicator.weight_value)
            / nullif(sum(weighted_indicator.weight_value), 0) as performance,
          count(distinct objective.id) as objective_count,
          count(distinct indicator.id) as indicator_count,
          sum(weighted_indicator.weight_value) as total_weight
        from public.skpe_strategic_objectives objective
        join public.skpe_indicators indicator
          on indicator.strategic_objective_id = objective.id
         and indicator.formulation_id = cycle_row.formulation_id
         and indicator.indicator_scope = 'strategic_kpi'
         and indicator.status = 'active'
        join public.skpe_indicator_measurements measurement
          on measurement.indicator_id = indicator.id
         and measurement.monitoring_cycle_id = cycle_row.id
         and measurement.status in ('submitted', 'validated')
         and not (
           measurement.status = 'validated'
           and exists (
             select 1
             from public.skpe_indicator_measurements submitted_measurement
             where submitted_measurement.monitoring_cycle_id = measurement.monitoring_cycle_id
               and submitted_measurement.indicator_id = measurement.indicator_id
               and submitted_measurement.status = 'submitted'
           )
         )
        cross join lateral (
          select case
            when package_row.aggregation_policy = 'explicit_weight'
              then case
                when indicator.metadata ->> 'monitoringWeight' ~ '^[0-9]+([.][0-9]+)?$'
                  then case
                    when (indicator.metadata ->> 'monitoringWeight')::numeric > 0
                      then (indicator.metadata ->> 'monitoringWeight')::numeric
                    else 1::numeric
                  end
                else 1::numeric
              end
            else 1::numeric
          end as weight_value
        ) weighted_indicator
        where objective.formulation_id = cycle_row.formulation_id
          and objective.status <> 'archived'
          and objective.strategic_theme_id is not null
        group by objective.strategic_theme_id
      )
      select jsonb_agg(jsonb_build_object(
        'strategicThemeId', theme.id,
        'code', theme.code,
        'name', theme.name,
        'performance', round(tp.performance, 2),
        'performanceStatus', public.skpe_monitoring_performance_status(
          package_row.id,
          round(tp.performance, 2)
        ),
        'objectiveCount', tp.objective_count,
        'indicatorCount', tp.indicator_count,
        'totalWeight', round(tp.total_weight, 4)
      ) order by theme.code)
      from theme_performance tp
      join public.skpe_strategic_themes theme
        on theme.id = tp.strategic_theme_id
    ), '[]'::jsonb),
    'visionProgress', vision_performance,
    'visionProgressStatus', public.skpe_monitoring_performance_status(
      package_row.id,
      vision_performance
    )
  );
end;
$$;

create or replace function public.skpe_build_performance_snapshot_payload(p_cycle_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  cycle_row public.skpe_monitoring_cycles%rowtype;
begin
  select * into cycle_row from public.skpe_monitoring_cycles where id = p_cycle_id;
  if not found then raise exception 'Ciclo de monitoramento não encontrado.' using errcode = '22023'; end if;

  return jsonb_build_object(
    'schemaVersion', 'FE08-1.0',
    'cycle', to_jsonb(cycle_row),
    'strategicPerformance', public.get_skpe_strategic_performance(cycle_row.id),
    'indicatorMeasurements', coalesce((
      select jsonb_agg(jsonb_build_object(
        'measurementId', m.id, 'indicatorId', m.indicator_id,
        'value', m.measured_value, 'performance', m.effective_performance,
        'measurementDate', m.measurement_date, 'dataQuality', m.data_quality,
        'status', m.status
      ) order by i.code)
      from public.skpe_indicator_measurements m
      join public.skpe_indicators i on i.id = m.indicator_id
      where m.monitoring_cycle_id = cycle_row.id
        and m.status in ('submitted','validated')
        and not (
          m.status = 'validated'
          and exists (
            select 1 from public.skpe_indicator_measurements sm
            where sm.monitoring_cycle_id = m.monitoring_cycle_id
              and sm.indicator_id = m.indicator_id
              and sm.status = 'submitted'
          )
        )
    ), '[]'::jsonb),
    'keyResults', coalesce((
      select jsonb_agg(jsonb_build_object(
        'checkInId', c.id, 'keyResultId', c.key_result_id,
        'currentValue', c.current_value, 'progress', c.effective_progress,
        'healthStatus', c.health_status, 'confidenceLevel', c.confidence_level,
        'status', c.operational_status
      ) order by kr.code)
      from public.skpe_key_result_check_ins c
      join public.skpe_key_results kr on kr.id = c.key_result_id
      where c.monitoring_cycle_id = cycle_row.id
        and c.status in ('submitted','validated')
        and not (
          c.status = 'validated'
          and exists (
            select 1 from public.skpe_key_result_check_ins sc
            where sc.monitoring_cycle_id = c.monitoring_cycle_id
              and sc.key_result_id = c.key_result_id
              and sc.status = 'submitted'
          )
        )
    ), '[]'::jsonb),
    'initiatives', coalesce((
      select jsonb_agg(jsonb_build_object(
        'checkInId', c.id, 'initiativeId', c.initiative_id,
        'progress', c.progress, 'healthStatus', c.health_status,
        'riskLevel', c.risk_level, 'status', c.operational_status,
        'actualCost', c.actual_cost, 'realizedBenefit', c.realized_benefit
      ) order by initiative.code)
      from public.skpe_initiative_check_ins c
      join public.skpe_initiatives initiative on initiative.id = c.initiative_id
      where c.monitoring_cycle_id = cycle_row.id
        and c.status in ('submitted','validated')
        and not (
          c.status = 'validated'
          and exists (
            select 1 from public.skpe_initiative_check_ins sc
            where sc.monitoring_cycle_id = c.monitoring_cycle_id
              and sc.initiative_id = c.initiative_id
              and sc.status = 'submitted'
          )
        )
    ), '[]'::jsonb),
    'initiativeOutcomes', coalesce((
      select jsonb_agg(jsonb_build_object(
        'measurementId', m.id,
        'initiativeOutcomeId', m.initiative_outcome_id,
        'measuredValue', m.measured_value,
        'qualitativeAssessment', m.qualitative_assessment,
        'performance', m.effective_performance,
        'outcomeStatus', m.outcome_status,
        'recordStatus', m.status
      ) order by outcome.code)
      from public.skpe_initiative_outcome_measurements m
      join public.skpe_initiative_outcomes outcome
        on outcome.id = m.initiative_outcome_id
      where m.monitoring_cycle_id = cycle_row.id
        and m.status in ('submitted','validated')
        and not (
          m.status = 'validated'
          and exists (
            select 1 from public.skpe_initiative_outcome_measurements sm
            where sm.monitoring_cycle_id = m.monitoring_cycle_id
              and sm.initiative_outcome_id = m.initiative_outcome_id
              and sm.status = 'submitted'
          )
        )
    ), '[]'::jsonb),
    'reviews', coalesce((
      select jsonb_agg(jsonb_build_object(
        'reviewId', review.id, 'code', review.code, 'title', review.title,
        'reviewType', review.review_type, 'status', review.status,
        'executiveSummary', review.executive_summary, 'conclusions', review.conclusions
      ) order by review.scheduled_at)
      from public.skpe_strategy_reviews review
      where review.monitoring_cycle_id = cycle_row.id
    ), '[]'::jsonb),
    'decisions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'decisionId', decision.id, 'code', decision.code, 'title', decision.title,
        'decisionType', decision.decision_type, 'priority', decision.priority,
        'responsibleUserId', decision.responsible_user_id,
        'dueDate', decision.due_date, 'status', decision.status
      ) order by decision.priority desc, decision.due_date)
      from public.skpe_governance_decisions decision
      join public.skpe_strategy_reviews review on review.id = decision.strategy_review_id
      where review.monitoring_cycle_id = cycle_row.id
    ), '[]'::jsonb),
    'learnings', coalesce((
      select jsonb_agg(jsonb_build_object(
        'learningId', learning.id, 'code', learning.code, 'title', learning.title,
        'impactLevel', learning.impact_level, 'status', learning.status,
        'lesson', learning.lesson_text, 'recommendation', learning.recommendation
      ) order by learning.created_at)
      from public.skpe_strategic_learnings learning
      where learning.monitoring_cycle_id = cycle_row.id
    ), '[]'::jsonb),
    'generatedAt', timezone('utc', now())
  );
end;
$$;

create or replace function public.ratify_skpe_strategy_review(
  p_strategy_review_id uuid,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_row public.skpe_strategy_reviews%rowtype;
  updated_row public.skpe_strategy_reviews%rowtype;
  cycle_row public.skpe_monitoring_cycles%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into previous_row
  from public.skpe_strategy_reviews
  where id = p_strategy_review_id
  for update;
  if not found then
    raise exception 'RAE não encontrada.' using errcode = '22023';
  end if;
  cycle_row := public.skpe_assert_monitoring_cycle_writable(previous_row.monitoring_cycle_id);
  if cycle_row.status not in ('under_review', 'pending_ratification') then
    raise exception 'A RAE somente pode ser ratificada quando o ciclo estiver sob análise ou pendente de ratificação.' using errcode = '55000';
  end if;
  if not public.can_ratify_skpe_governance(previous_row.organization_id) then
    raise exception 'Acesso negado para ratificar a RAE.' using errcode = '42501';
  end if;
  if previous_row.status not in ('pending_ratification', 'in_progress') then
    raise exception 'A RAE deve estar em andamento ou pendente de ratificação.' using errcode = '55000';
  end if;
  if previous_row.held_at is null
     or length(trim(coalesce(previous_row.executive_summary, ''))) = 0
     or length(trim(coalesce(previous_row.conclusions, ''))) = 0 then
    raise exception 'Informe data de realização, síntese executiva e conclusões antes da ratificação.' using errcode = '55000';
  end if;

  update public.skpe_strategy_reviews set
    status = 'ratified', ratified_at = timezone('utc', now()),
    ratified_by = auth.uid(), updated_by = auth.uid()
  where id = previous_row.id returning * into updated_row;

  perform public.skpe_record_operational_audit(
    updated_row.organization_id, updated_row.project_id,
    'strategy_review', updated_row.id,
    'fe08.strategy_review_ratified', p_change_reason,
    to_jsonb(previous_row), to_jsonb(updated_row)
  );
  return updated_row.id;
end;
$$;

create or replace function public.close_skpe_monitoring_cycle(
  p_cycle_id uuid,
  p_change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_cycle public.skpe_monitoring_cycles%rowtype;
  updated_cycle public.skpe_monitoring_cycles%rowtype;
  readiness jsonb;
  snapshot_payload jsonb;
  snapshot_row public.skpe_performance_snapshots%rowtype;
  next_version integer;
begin
  perform public.skpe_assert_reason(p_change_reason);
  previous_cycle := public.skpe_assert_monitoring_cycle_writable(p_cycle_id);
  if not public.can_ratify_skpe_governance(previous_cycle.organization_id) then
    raise exception 'Acesso negado para fechar o ciclo.' using errcode = '42501';
  end if;
  if previous_cycle.status <> 'pending_ratification' then
    raise exception 'O ciclo deve estar pendente de ratificação antes do fechamento.' using errcode = '55000';
  end if;

  readiness := public.get_skpe_monitoring_readiness(p_cycle_id);
  if not coalesce((readiness ->> 'readyForClose')::boolean, false) then
    raise exception 'Ciclo incompleto. Pendências: %',
      readiness -> 'blockingIssues' using errcode = '55000';
  end if;

  select coalesce(max(snapshot_version), 0) + 1
  into next_version
  from public.skpe_performance_snapshots
  where monitoring_cycle_id = p_cycle_id;

  update public.skpe_monitoring_cycles
  set
    status = 'closed',
    closed_at = timezone('utc', now()),
    closed_by = auth.uid(),
    updated_by = auth.uid()
  where id = p_cycle_id
  returning * into updated_cycle;

  snapshot_payload := public.skpe_build_performance_snapshot_payload(p_cycle_id);

  insert into public.skpe_performance_snapshots (
    organization_id, project_id, formulation_id, monitoring_cycle_id,
    snapshot_version, status, calculation_policy, payload,
    checksum_sha256, generated_by, ratified_at, ratified_by
  ) values (
    updated_cycle.organization_id,
    updated_cycle.project_id,
    updated_cycle.formulation_id,
    updated_cycle.id,
    next_version,
    'ratified',
    (
      select aggregation_policy
      from public.skpe_monitoring_packages
      where id = updated_cycle.monitoring_package_id
    ),
    snapshot_payload,
    encode(extensions.digest(snapshot_payload::text, 'sha256'), 'hex'),
    auth.uid(),
    timezone('utc', now()),
    auth.uid()
  ) returning * into snapshot_row;

  update public.skpe_monitoring_cycles
  set
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'ratifiedSnapshotId', snapshot_row.id,
      'ratifiedSnapshotVersion', snapshot_row.snapshot_version,
      'ratifiedSnapshotChecksum', snapshot_row.checksum_sha256
    ),
    updated_by = auth.uid()
  where id = p_cycle_id
  returning * into updated_cycle;

  perform public.skpe_record_operational_audit(
    updated_cycle.organization_id, updated_cycle.project_id,
    'monitoring_cycle', updated_cycle.id,
    'fe08.monitoring_cycle_closed', p_change_reason,
    to_jsonb(previous_cycle), to_jsonb(updated_cycle)
  );
  perform public.skpe_record_operational_audit(
    snapshot_row.organization_id, snapshot_row.project_id,
    'performance_snapshot', snapshot_row.id,
    'fe08.performance_snapshot_ratified', p_change_reason,
    null, to_jsonb(snapshot_row)
  );

  return jsonb_build_object(
    'cycleId', updated_cycle.id,
    'cycleStatus', updated_cycle.status,
    'snapshotId', snapshot_row.id,
    'snapshotVersion', snapshot_row.snapshot_version,
    'checksumSha256', snapshot_row.checksum_sha256
  );
end;
$$;

create or replace function public.reopen_skpe_monitoring_cycle(
  p_cycle_id uuid,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_cycle public.skpe_monitoring_cycles%rowtype;
  updated_cycle public.skpe_monitoring_cycles%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into previous_cycle from public.skpe_monitoring_cycles where id = p_cycle_id for update;
  if not found then raise exception 'Ciclo não encontrado.' using errcode = '22023'; end if;
  if previous_cycle.status <> 'closed' then
    raise exception 'Somente ciclos fechados podem ser reabertos.' using errcode = '55000';
  end if;
  if not public.can_ratify_skpe_governance(previous_cycle.organization_id) then
    raise exception 'Acesso negado para reabrir o ciclo.' using errcode = '42501';
  end if;

  update public.skpe_performance_snapshots
  set status = 'superseded'
  where monitoring_cycle_id = previous_cycle.id and status = 'ratified';

  update public.skpe_monitoring_cycles set
    status = 'reopened', closed_at = null, closed_by = null,
    updated_by = auth.uid(), metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object('reopenedAt', timezone('utc', now()), 'reopenedBy', auth.uid())
  where id = p_cycle_id returning * into updated_cycle;

  perform public.skpe_record_operational_audit(
    updated_cycle.organization_id, updated_cycle.project_id,
    'monitoring_cycle', updated_cycle.id,
    'fe08.monitoring_cycle_reopened', p_change_reason,
    to_jsonb(previous_cycle), to_jsonb(updated_cycle)
  );
  return updated_cycle.id;
end;
$$;

-- ============================================================
-- 11. CONSULTAS CONSOLIDADAS
-- ============================================================

create or replace function public.get_skpe_monitoring_cycle(p_cycle_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  cycle_row public.skpe_monitoring_cycles%rowtype;
begin
  select * into cycle_row from public.skpe_monitoring_cycles where id = p_cycle_id;
  if not found then raise exception 'Ciclo de monitoramento não encontrado.' using errcode = '22023'; end if;
  if not public.can_view_skpe_monitoring(cycle_row.organization_id) then
    raise exception 'Acesso negado ao ciclo.' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'cycle', to_jsonb(cycle_row),
    'readiness', public.get_skpe_monitoring_readiness(cycle_row.id),
    'currentPerformance', public.skpe_build_performance_snapshot_payload(cycle_row.id),
    'snapshots', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', snapshot.id, 'version', snapshot.snapshot_version,
        'status', snapshot.status, 'checksumSha256', snapshot.checksum_sha256,
        'generatedAt', snapshot.generated_at, 'ratifiedAt', snapshot.ratified_at
      ) order by snapshot.snapshot_version desc)
      from public.skpe_performance_snapshots snapshot
      where snapshot.monitoring_cycle_id = cycle_row.id
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.get_skpe_monitoring_audit(p_formulation_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
begin
  select * into formulation_row from public.skpe_strategic_formulations where id = p_formulation_id;
  if not found then raise exception 'Formulação Estratégica não encontrada.' using errcode = '22023'; end if;
  if not public.can_view_skpe_monitoring(formulation_row.organization_id) then
    raise exception 'Acesso negado à auditoria FE-08.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', audit.id, 'entityType', audit.entity_type, 'entityId', audit.entity_id,
      'actionCode', audit.action_code, 'reason', audit.reason,
      'previousData', audit.previous_data, 'newData', audit.new_data,
      'occurredAt', audit.occurred_at, 'actorUserId', audit.actor_user_id
    ) order by audit.occurred_at desc)
    from public.skpe_operational_audit audit
    where audit.organization_id = formulation_row.organization_id
      and audit.project_id = formulation_row.project_id
      and (audit.action_code like 'fe08.%' or audit.entity_type in (
        'monitoring_package', 'monitoring_cycle', 'indicator_measurement',
        'key_result_check_in', 'initiative_check_in',
        'initiative_outcome_measurement', 'strategy_review',
        'strategy_review_item', 'governance_decision',
        'strategic_learning', 'performance_snapshot'
      ))
  ), '[]'::jsonb);
end;
$$;

-- ============================================================
-- 12. PRIVILÉGIOS
-- ============================================================

revoke insert, update, delete, truncate
on table public.skpe_monitoring_packages,
         public.skpe_monitoring_cycles,
         public.skpe_indicator_measurements,
         public.skpe_key_result_check_ins,
         public.skpe_initiative_check_ins,
         public.skpe_initiative_outcome_measurements,
         public.skpe_strategy_reviews,
         public.skpe_strategy_review_items,
         public.skpe_governance_decisions,
         public.skpe_strategic_learnings,
         public.skpe_performance_snapshots
from public, anon, authenticated;

revoke all
on table public.skpe_monitoring_packages,
         public.skpe_monitoring_cycles,
         public.skpe_indicator_measurements,
         public.skpe_key_result_check_ins,
         public.skpe_initiative_check_ins,
         public.skpe_initiative_outcome_measurements,
         public.skpe_strategy_reviews,
         public.skpe_strategy_review_items,
         public.skpe_governance_decisions,
         public.skpe_strategic_learnings,
         public.skpe_performance_snapshots
from anon;

grant select
on table public.skpe_monitoring_packages,
         public.skpe_monitoring_cycles,
         public.skpe_indicator_measurements,
         public.skpe_key_result_check_ins,
         public.skpe_initiative_check_ins,
         public.skpe_initiative_outcome_measurements,
         public.skpe_strategy_reviews,
         public.skpe_strategy_review_items,
         public.skpe_governance_decisions,
         public.skpe_strategic_learnings,
         public.skpe_performance_snapshots
to authenticated, service_role;

grant insert, update, delete
on table public.skpe_monitoring_packages,
         public.skpe_monitoring_cycles,
         public.skpe_indicator_measurements,
         public.skpe_key_result_check_ins,
         public.skpe_initiative_check_ins,
         public.skpe_initiative_outcome_measurements,
         public.skpe_strategy_reviews,
         public.skpe_strategy_review_items,
         public.skpe_governance_decisions,
         public.skpe_strategic_learnings,
         public.skpe_performance_snapshots
to service_role;

-- Mutações operacionais legadas permanecem reservadas ao service_role para
-- impedir atualização de projeções sem o histórico append-only da FE-08.
do $$
begin
  if to_regprocedure('public.update_skpe_key_result_progress(uuid,numeric,text,numeric,text,text)') is not null then
    execute 'revoke all on function public.update_skpe_key_result_progress(uuid,numeric,text,numeric,text,text) from public, anon, authenticated';
    execute 'grant execute on function public.update_skpe_key_result_progress(uuid,numeric,text,numeric,text,text) to service_role';
  end if;
  if to_regprocedure('public.update_skpe_initiative_operational_progress(uuid,text,numeric,numeric,numeric,text,text,text)') is not null then
    execute 'revoke all on function public.update_skpe_initiative_operational_progress(uuid,text,numeric,numeric,numeric,text,text,text) from public, anon, authenticated';
    execute 'grant execute on function public.update_skpe_initiative_operational_progress(uuid,text,numeric,numeric,numeric,text,text,text) to service_role';
  end if;
  if to_regprocedure('public.update_skpe_initiative_outcome_progress(uuid,numeric,text,text)') is not null then
    execute 'revoke all on function public.update_skpe_initiative_outcome_progress(uuid,numeric,text,text) from public, anon, authenticated';
    execute 'grant execute on function public.update_skpe_initiative_outcome_progress(uuid,numeric,text,text) to service_role';
  end if;
end;
$$;

-- Internas
revoke all on function public.skpe_assert_monitoring_cycle_writable(uuid) from public, anon, authenticated;
revoke all on function public.skpe_assert_strategy_review_item_scope(uuid,jsonb) from public, anon, authenticated;
revoke all on function public.ensure_skpe_monitoring_package(uuid) from public, anon, authenticated;
revoke all on function public.skpe_calculate_strategic_performance(text,numeric,numeric,numeric,numeric,numeric) from public, anon, authenticated;
revoke all on function public.skpe_monitoring_performance_status(uuid,numeric) from public, anon, authenticated;
revoke all on function public.skpe_guard_snapshot_immutability() from public, anon, authenticated;
revoke all on function public.skpe_guard_formulation_monitoring_ready() from public, anon, authenticated;
revoke all on function public.skpe_build_performance_snapshot_payload(uuid) from public, anon, authenticated;

-- Públicas
revoke all on function public.get_skpe_monitoring_package_readiness(uuid,boolean) from public, anon;
revoke all on function public.configure_skpe_monitoring_package(uuid,jsonb,text) from public, anon;
revoke all on function public.transition_skpe_monitoring_package(uuid,text,text,text) from public, anon;
revoke all on function public.open_skpe_monitoring_cycle(uuid,jsonb,text) from public, anon;
revoke all on function public.record_skpe_indicator_measurement(uuid,uuid,numeric,jsonb,text) from public, anon;
revoke all on function public.record_skpe_key_result_check_in(uuid,uuid,numeric,jsonb,text) from public, anon;
revoke all on function public.record_skpe_initiative_check_in(uuid,uuid,jsonb,text) from public, anon;
revoke all on function public.record_skpe_initiative_outcome_measurement(uuid,uuid,jsonb,text) from public, anon;
revoke all on function public.upsert_skpe_strategy_review(uuid,uuid,jsonb,text) from public, anon;
revoke all on function public.upsert_skpe_strategy_review_item(uuid,uuid,jsonb,text) from public, anon;
revoke all on function public.record_skpe_governance_decision(uuid,uuid,jsonb,text) from public, anon;
revoke all on function public.record_skpe_strategic_learning(uuid,uuid,jsonb,text) from public, anon;
revoke all on function public.transition_skpe_monitoring_cycle(uuid,text,text) from public, anon;
revoke all on function public.transition_skpe_monitoring_record(text,uuid,text,text) from public, anon;
revoke all on function public.transition_skpe_governance_decision(uuid,text,text,text) from public, anon;
revoke all on function public.transition_skpe_strategic_learning(uuid,text,text,text) from public, anon;
revoke all on function public.get_skpe_strategic_performance(uuid) from public, anon;
revoke all on function public.get_skpe_monitoring_readiness(uuid) from public, anon;
revoke all on function public.ratify_skpe_strategy_review(uuid,text) from public, anon;
revoke all on function public.close_skpe_monitoring_cycle(uuid,text) from public, anon;
revoke all on function public.reopen_skpe_monitoring_cycle(uuid,text) from public, anon;
revoke all on function public.get_skpe_monitoring_cycle(uuid) from public, anon;
revoke all on function public.get_skpe_monitoring_audit(uuid) from public, anon;

grant execute on function public.get_skpe_monitoring_package_readiness(uuid,boolean) to authenticated, service_role;
grant execute on function public.configure_skpe_monitoring_package(uuid,jsonb,text) to authenticated, service_role;
grant execute on function public.transition_skpe_monitoring_package(uuid,text,text,text) to authenticated, service_role;
grant execute on function public.open_skpe_monitoring_cycle(uuid,jsonb,text) to authenticated, service_role;
grant execute on function public.record_skpe_indicator_measurement(uuid,uuid,numeric,jsonb,text) to authenticated, service_role;
grant execute on function public.record_skpe_key_result_check_in(uuid,uuid,numeric,jsonb,text) to authenticated, service_role;
grant execute on function public.record_skpe_initiative_check_in(uuid,uuid,jsonb,text) to authenticated, service_role;
grant execute on function public.record_skpe_initiative_outcome_measurement(uuid,uuid,jsonb,text) to authenticated, service_role;
grant execute on function public.upsert_skpe_strategy_review(uuid,uuid,jsonb,text) to authenticated, service_role;
grant execute on function public.upsert_skpe_strategy_review_item(uuid,uuid,jsonb,text) to authenticated, service_role;
grant execute on function public.record_skpe_governance_decision(uuid,uuid,jsonb,text) to authenticated, service_role;
grant execute on function public.record_skpe_strategic_learning(uuid,uuid,jsonb,text) to authenticated, service_role;
grant execute on function public.transition_skpe_monitoring_cycle(uuid,text,text) to authenticated, service_role;
grant execute on function public.transition_skpe_monitoring_record(text,uuid,text,text) to authenticated, service_role;
grant execute on function public.transition_skpe_governance_decision(uuid,text,text,text) to authenticated, service_role;
grant execute on function public.transition_skpe_strategic_learning(uuid,text,text,text) to authenticated, service_role;
grant execute on function public.get_skpe_strategic_performance(uuid) to authenticated, service_role;
grant execute on function public.get_skpe_monitoring_readiness(uuid) to authenticated, service_role;
grant execute on function public.ratify_skpe_strategy_review(uuid,text) to authenticated, service_role;
grant execute on function public.close_skpe_monitoring_cycle(uuid,text) to authenticated, service_role;
grant execute on function public.reopen_skpe_monitoring_cycle(uuid,text) to authenticated, service_role;
grant execute on function public.get_skpe_monitoring_cycle(uuid) to authenticated, service_role;
grant execute on function public.get_skpe_monitoring_audit(uuid) to authenticated, service_role;

comment on table public.skpe_monitoring_packages is
  'Configuração metodológica e validação do pacote FE-08 por Formulação Estratégica.';
comment on table public.skpe_monitoring_cycles is
  'Períodos operacionais de medição, análise, RAE e fechamento da estratégia.';
comment on table public.skpe_indicator_measurements is
  'Série histórica append-only das medições de Indicadores Estratégicos.';
comment on table public.skpe_key_result_check_ins is
  'Histórico de check-ins de Resultados-Chave, confiança, saúde e previsão.';
comment on table public.skpe_initiative_check_ins is
  'Histórico periódico de execução, custo, benefício, risco e saúde das Iniciativas.';
comment on table public.skpe_strategy_reviews is
  'Reuniões de Análise da Estratégia e demais instâncias formais de governança.';
comment on table public.skpe_governance_decisions is
  'Deliberações rastreáveis resultantes da análise e governança estratégica.';
comment on table public.skpe_strategic_learnings is
  'Aprendizados, evidências e recomendações para revisão controlada da estratégia.';
comment on table public.skpe_performance_snapshots is
  'Snapshots imutáveis e verificáveis do desempenho consolidado de cada ciclo.';

commit;
