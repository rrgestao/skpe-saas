-- SK-PE-CONT-01
-- GATE-17-B.4C.6 — Objective–Evolution Alignment Foundation
--
-- Missão:
--
-- Criar a fundação canônica para alinhamento entre
-- Objetivos Estratégicos e Ciclos de Evolução sem misturar:
--
-- - Horizonte Estratégico do Objetivo;
-- - Ciclo de Evolução;
-- - Ciclo de OKR;
-- - período de KR;
-- - período de execução.
--
-- Modelo de governança:
--
-- FORMULAÇÃO
--   Objetivo Estratégico
--        ↕
--   Scenario Cycle
--   alinhamento proposto/editável
--
-- RATIFICAÇÃO
--        ↓
--
-- INSTITUCIONAL
--   Objetivo Estratégico
--        ↕
--   Evolution Cycle
--   alinhamento materializado com linhagem.
--
-- SPARKs recomenda; a organização decide.


-- ============================================================
-- 01. IDENTIDADES COMPOSTAS CANÔNICAS
-- ============================================================

alter table
  public.skpe_strategic_objectives

add constraint
  skpe_strategic_objectives_identity_scope

unique (
  id,
  formulation_id,
  organization_id,
  project_id
);


alter table
  public.skpe_evolution_cycles

add constraint
  skpe_evolution_cycles_scope_unique

unique (
  id,
  evolution_plan_id,
  strategic_horizon_id,
  organization_id,
  project_id
);


-- ============================================================
-- 02. ALIGNMENT — PROPOSED / FORMULATION
-- ============================================================

create table
  public.skpe_objective_evolution_scenario_alignments (

    id uuid
      primary key
      default gen_random_uuid(),

    organization_id uuid
      not null,

    project_id uuid
      not null,

    formulation_id uuid
      not null,

    strategic_objective_id uuid
      not null,

    strategic_horizon_id uuid
      not null,

    scenario_id uuid
      not null,

    scenario_cycle_id uuid
      not null,

    alignment_role text
      not null
      default 'supporting',

    contribution_weight numeric
      null,

    expected_result_in_cycle text
      null,

    rationale text
      null,

    validation_status text
      not null
      default 'draft',

    metadata jsonb
      not null
      default '{}'::jsonb,

    created_at timestamptz
      not null
      default timezone('utc', now()),

    created_by uuid
      null,

    updated_at timestamptz
      not null
      default timezone('utc', now()),

    updated_by uuid
      null,


    constraint
      skpe_objective_evolution_scenario_alignment_role_check

    check (
      alignment_role in (
        'primary',
        'supporting',
        'sustaining'
      )
    ),


    constraint
      skpe_objective_evolution_scenario_alignment_weight_check

    check (
      contribution_weight is null
      or (
        contribution_weight >= 0
        and contribution_weight <= 100
      )
    ),


    constraint
      skpe_objective_evolution_scenario_alignment_validation_check

    check (
      validation_status in (
        'draft',
        'pending_validation',
        'validated',
        'rejected'
      )
    ),


    constraint
      skpe_objective_evolution_scenario_alignment_metadata_check

    check (
      jsonb_typeof(metadata) = 'object'
    ),


    constraint
      skpe_objective_evolution_scenario_alignment_unique

    unique (
      strategic_objective_id,
      scenario_cycle_id
    ),


    constraint
      skpe_objective_evolution_scenario_alignment_scope_unique

    unique (
      id,
      formulation_id,
      organization_id,
      project_id
    ),


    constraint
      skpe_objective_evolution_scenario_alignment_org_fkey

    foreign key (
      organization_id
    )

    references
      public.organizations(id)

    on delete cascade,


    constraint
      skpe_objective_evolution_scenario_alignment_project_fkey

    foreign key (
      project_id
    )

    references
      public.skpe_projects(id)

    on delete cascade,


    constraint
      skpe_objective_evolution_scenario_alignment_formulation_fkey

    foreign key (
      formulation_id,
      organization_id,
      project_id
    )

    references
      public.skpe_strategic_formulations(
        id,
        organization_id,
        project_id
      )

    on delete cascade,


    constraint
      skpe_objective_evolution_scenario_alignment_objective_fkey

    foreign key (
      strategic_objective_id,
      formulation_id,
      organization_id,
      project_id
    )

    references
      public.skpe_strategic_objectives(
        id,
        formulation_id,
        organization_id,
        project_id
      )

    on delete cascade,


    constraint
      skpe_objective_evolution_scenario_alignment_cycle_fkey

    foreign key (
      scenario_cycle_id,
      scenario_id,
      strategic_horizon_id,
      organization_id,
      project_id
    )

    references
      public.skpe_evolution_scenario_cycles(
        id,
        scenario_id,
        strategic_horizon_id,
        organization_id,
        project_id
      )

    on delete cascade,


    constraint
      skpe_objective_evolution_scenario_alignment_created_by_fkey

    foreign key (
      created_by
    )

    references
      public.profiles(id)

    on delete set null,


    constraint
      skpe_objective_evolution_scenario_alignment_updated_by_fkey

    foreign key (
      updated_by
    )

    references
      public.profiles(id)

    on delete set null
  );


-- ============================================================
-- 03. ALIGNMENT — INSTITUTIONAL
-- ============================================================

create table
  public.skpe_objective_evolution_cycle_alignments (

    id uuid
      primary key
      default gen_random_uuid(),

    organization_id uuid
      not null,

    project_id uuid
      not null,

    formulation_id uuid
      not null,

    strategic_objective_id uuid
      not null,

    strategic_horizon_id uuid
      not null,

    evolution_plan_id uuid
      not null,

    evolution_cycle_id uuid
      not null,

    source_scenario_alignment_id uuid
      null,

    materialization_gate_decision_id uuid
      null,

    alignment_role text
      not null,

    contribution_weight numeric
      null,

    expected_result_in_cycle text
      null,

    rationale text
      null,

    metadata jsonb
      not null
      default '{}'::jsonb,

    created_at timestamptz
      not null
      default timezone('utc', now()),

    created_by uuid
      null,

    updated_at timestamptz
      not null
      default timezone('utc', now()),

    updated_by uuid
      null,


    constraint
      skpe_objective_evolution_cycle_alignment_role_check

    check (
      alignment_role in (
        'primary',
        'supporting',
        'sustaining'
      )
    ),


    constraint
      skpe_objective_evolution_cycle_alignment_weight_check

    check (
      contribution_weight is null
      or (
        contribution_weight >= 0
        and contribution_weight <= 100
      )
    ),


    constraint
      skpe_objective_evolution_cycle_alignment_metadata_check

    check (
      jsonb_typeof(metadata) = 'object'
    ),


    constraint
      skpe_objective_evolution_cycle_alignment_unique

    unique (
      strategic_objective_id,
      evolution_cycle_id
    ),


    constraint
      skpe_objective_evolution_cycle_alignment_org_fkey

    foreign key (
      organization_id
    )

    references
      public.organizations(id)

    on delete cascade,


    constraint
      skpe_objective_evolution_cycle_alignment_project_fkey

    foreign key (
      project_id
    )

    references
      public.skpe_projects(id)

    on delete cascade,


    constraint
      skpe_objective_evolution_cycle_alignment_formulation_fkey

    foreign key (
      formulation_id,
      organization_id,
      project_id
    )

    references
      public.skpe_strategic_formulations(
        id,
        organization_id,
        project_id
      )

    on delete restrict,


    constraint
      skpe_objective_evolution_cycle_alignment_objective_fkey

    foreign key (
      strategic_objective_id,
      formulation_id,
      organization_id,
      project_id
    )

    references
      public.skpe_strategic_objectives(
        id,
        formulation_id,
        organization_id,
        project_id
      )

    on delete restrict,


    constraint
      skpe_objective_evolution_cycle_alignment_plan_fkey

    foreign key (
      evolution_plan_id,
      strategic_horizon_id,
      organization_id,
      project_id
    )

    references
      public.skpe_evolution_plans(
        id,
        strategic_horizon_id,
        organization_id,
        project_id
      )

    on delete cascade,


    constraint
      skpe_objective_evolution_cycle_alignment_cycle_fkey

    foreign key (
      evolution_cycle_id,
      evolution_plan_id,
      strategic_horizon_id,
      organization_id,
      project_id
    )

    references
      public.skpe_evolution_cycles(
        id,
        evolution_plan_id,
        strategic_horizon_id,
        organization_id,
        project_id
      )

    on delete cascade,


    constraint
      skpe_objective_evolution_cycle_alignment_source_fkey

    foreign key (
      source_scenario_alignment_id,
      formulation_id,
      organization_id,
      project_id
    )

    references
      public.skpe_objective_evolution_scenario_alignments(
        id,
        formulation_id,
        organization_id,
        project_id
      )

    on delete set null (
      source_scenario_alignment_id
    ),


    constraint
      skpe_objective_evolution_cycle_alignment_gate_fkey

    foreign key (
      materialization_gate_decision_id
    )

    references
      public.skpe_gate_decisions(id)

    on delete set null,


    constraint
      skpe_objective_evolution_cycle_alignment_created_by_fkey

    foreign key (
      created_by
    )

    references
      public.profiles(id)

    on delete set null,


    constraint
      skpe_objective_evolution_cycle_alignment_updated_by_fkey

    foreign key (
      updated_by
    )

    references
      public.profiles(id)

    on delete set null
  );


-- ============================================================
-- 04. INDEXES
-- ============================================================

create index
  ix_skpe_objective_evolution_scenario_alignments_formulation

on public.skpe_objective_evolution_scenario_alignments (
  formulation_id,
  strategic_objective_id
);


create index
  ix_skpe_objective_evolution_scenario_alignments_cycle

on public.skpe_objective_evolution_scenario_alignments (
  scenario_id,
  scenario_cycle_id
);


create index
  ix_skpe_objective_evolution_cycle_alignments_formulation

on public.skpe_objective_evolution_cycle_alignments (
  formulation_id,
  strategic_objective_id
);


create index
  ix_skpe_objective_evolution_cycle_alignments_plan

on public.skpe_objective_evolution_cycle_alignments (
  evolution_plan_id,
  evolution_cycle_id
);


-- ============================================================
-- 05. ROW LEVEL SECURITY
-- ============================================================

alter table
  public.skpe_objective_evolution_scenario_alignments
enable row level security;


alter table
  public.skpe_objective_evolution_cycle_alignments
enable row level security;


create policy
  skpe_objective_evolution_scenario_alignments_select

on
  public.skpe_objective_evolution_scenario_alignments

for select

to authenticated

using (
  public.can_view_skpe_formulation(
    organization_id
  )
);


create policy
  skpe_objective_evolution_cycle_alignments_select

on
  public.skpe_objective_evolution_cycle_alignments

for select

to authenticated

using (
  public.can_view_skpe_formulation(
    organization_id
  )
);


-- ============================================================
-- 06. PRIVILEGES
-- ============================================================
--
-- Authenticated possui somente leitura direta.
--
-- Escritas futuras deverão ocorrer por RPCs governadas.
-- Isso evita que o frontend transforme alinhamentos propostos
-- ou institucionais diretamente sem auditoria.
-- ============================================================

revoke all
on table
  public.skpe_objective_evolution_scenario_alignments
from public, anon, authenticated;


revoke all
on table
  public.skpe_objective_evolution_cycle_alignments
from public, anon, authenticated;


grant select
on table
  public.skpe_objective_evolution_scenario_alignments
to authenticated;


grant select
on table
  public.skpe_objective_evolution_cycle_alignments
to authenticated;


grant all
on table
  public.skpe_objective_evolution_scenario_alignments
to service_role;


grant all
on table
  public.skpe_objective_evolution_cycle_alignments
to service_role;


-- ============================================================
-- 07. DOCUMENTATION
-- ============================================================

comment on table
  public.skpe_objective_evolution_scenario_alignments
is
  'Alinhamento proposto entre Objetivo Estratégico e Ciclo de Evolução de cenário durante a Formulação. É fonte editável pré-ratificação e não substitui horizonte do Objetivo, ciclo de OKR, período de KR ou execução.';


comment on table
  public.skpe_objective_evolution_cycle_alignments
is
  'Alinhamento institucional entre Objetivo Estratégico e Ciclo de Evolução materializado a partir do alinhamento proposto no fechamento do PEM-02.GATE.';


comment on column
  public.skpe_objective_evolution_scenario_alignments.alignment_role
is
  'Papel temporal do Objetivo no Ciclo de Evolução: primary, supporting ou sustaining.';


comment on column
  public.skpe_objective_evolution_scenario_alignments.expected_result_in_cycle
is
  'Resultado intermediário esperado do Objetivo dentro deste Ciclo de Evolução, sem redefinir o resultado final do Objetivo.';


comment on column
  public.skpe_objective_evolution_scenario_alignments.contribution_weight
is
  'Peso opcional da contribuição relativa deste Ciclo para a trajetória do Objetivo; não representa meta nem progresso.';


comment on column
  public.skpe_objective_evolution_cycle_alignments.source_scenario_alignment_id
is
  'Linhagem para o alinhamento proposto que originou este vínculo institucional.';


comment on column
  public.skpe_objective_evolution_cycle_alignments.materialization_gate_decision_id
is
  'Decisão institucional de Gate associada à materialização do alinhamento definitivo.';