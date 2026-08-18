-- SK-PE-CONT-01
-- GATE-17-B.4C.7 — Objective–Evolution Alignment Governed Operations
--
-- Missão:
--
-- Governar o alinhamento entre Objetivos Estratégicos e Ciclos de Evolução,
-- preservando duas verdades distintas e rastreáveis:
--
-- 1. alinhamento proposto:
--    Objetivo Estratégico <-> Scenario Cycle;
--
-- 2. alinhamento institucional:
--    Objetivo Estratégico <-> Evolution Cycle.
--
-- O alinhamento institucional somente é materializado na ratificação final
-- do PEM-02.GATE.
--
-- A aprovação intermediária do Cenário de Evolução materializa o Plano e
-- seus Ciclos, mas NÃO institucionaliza ainda o alinhamento dos Objetivos.
--
-- Nenhuma coluna evolution_cycle_id é adicionada a:
-- - Objetivos Estratégicos;
-- - OKRs;
-- - KRs.
--
-- Os relógios continuam separados:
-- Strategic Period != Governance Period != Execution Period != Measurement Period.


-- ============================================================
-- 01. GOVERNED UPSERT — PROPOSED ALIGNMENT
-- ============================================================

create or replace function
  public.upsert_skpe_objective_evolution_scenario_alignment(

    target_formulation_id uuid,

    target_strategic_objective_id uuid,

    target_scenario_cycle_id uuid,

    target_alignment_id uuid,

    target_alignment_role text,

    target_contribution_weight numeric,

    target_expected_result_in_cycle text,

    target_alignment_rationale text,

    change_reason text
  )
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$

declare

  v_formulation
    public.skpe_strategic_formulations%rowtype;

  v_objective
    public.skpe_strategic_objectives%rowtype;

  v_cycle
    public.skpe_evolution_scenario_cycles%rowtype;

  v_scenario
    public.skpe_evolution_scenarios%rowtype;

  v_existing
    public.skpe_objective_evolution_scenario_alignments%rowtype;

  v_latest_formulation_id uuid;

  v_id uuid;

  v_previous_data jsonb;

begin

  perform public.skpe_assert_reason(
    change_reason
  );


  -- ----------------------------------------------------------
  -- Formulação
  -- ----------------------------------------------------------

  select *
  into v_formulation

  from public.skpe_strategic_formulations

  where id =
        target_formulation_id;


  if v_formulation.id is null then

    raise exception
      'Formulação Estratégica não encontrada.'
      using errcode = '22023';

  end if;


  if not public.can_manage_skpe_formulation(
    v_formulation.organization_id
  ) then

    raise exception
      'Acesso negado à gestão do alinhamento da Formulação Estratégica.'
      using errcode = '42501';

  end if;


  -- ----------------------------------------------------------
  -- Evitar alinhamento em versão antiga da Formulação
  -- ----------------------------------------------------------

  select
    f.id

  into
    v_latest_formulation_id

  from public.skpe_strategic_formulations f

  where f.project_id =
        v_formulation.project_id

  order by
    f.version_number desc

  limit 1;


  if v_latest_formulation_id
     is distinct from
     v_formulation.id then

    raise exception
      'O alinhamento deve utilizar a versão mais recente da Formulação Estratégica.'
      using errcode = '55000';

  end if;


  -- ----------------------------------------------------------
  -- Objetivo
  -- ----------------------------------------------------------

  select *
  into v_objective

  from public.skpe_strategic_objectives

  where id =
        target_strategic_objective_id

    and formulation_id =
        v_formulation.id

    and organization_id =
        v_formulation.organization_id

    and project_id =
        v_formulation.project_id;


  if v_objective.id is null then

    raise exception
      'Objetivo Estratégico não pertence à Formulação informada.'
      using errcode = '22023';

  end if;


  if v_objective.status =
     'archived' then

    raise exception
      'Objetivo Estratégico arquivado não pode receber alinhamento com Ciclo de Evolução.'
      using errcode = '55000';

  end if;


  -- ----------------------------------------------------------
  -- Scenario Cycle
  -- ----------------------------------------------------------

  select *
  into v_cycle

  from public.skpe_evolution_scenario_cycles

  where id =
        target_scenario_cycle_id;


  if v_cycle.id is null then

    raise exception
      'Ciclo de Evolução proposto não encontrado.'
      using errcode = '22023';

  end if;


  if v_cycle.organization_id
       <> v_formulation.organization_id

     or v_cycle.project_id
       <> v_formulation.project_id then

    raise exception
      'Ciclo de Evolução e Formulação pertencem a escopos organizacionais diferentes.'
      using errcode = '22023';

  end if;


  -- ----------------------------------------------------------
  -- Cenário
  -- ----------------------------------------------------------

  select *
  into v_scenario

  from public.skpe_evolution_scenarios

  where id =
        v_cycle.scenario_id

  for update;


  if v_scenario.id is null then

    raise exception
      'Cenário de Evolução não encontrado.'
      using errcode = '22023';

  end if;


  if not public.can_manage_skpe_governance(
    v_scenario.organization_id
  ) then

    raise exception
      'Acesso negado à gestão do alinhamento Objetivo–Ciclo de Evolução.'
      using errcode = '42501';

  end if;


  if v_scenario.status not in (
    'draft',
    'adjusted'
  ) then

    raise exception
      'Alinhamentos Objetivo–Ciclo só podem ser editados enquanto o Cenário de Evolução estiver em rascunho ou ajuste.'
      using errcode = '55000';

  end if;


  -- ----------------------------------------------------------
  -- Horizonte
  -- ----------------------------------------------------------

  if v_cycle.strategic_horizon_id
       <> v_scenario.strategic_horizon_id then

    raise exception
      'Ciclo e Cenário possuem Horizontes Estratégicos divergentes.'
      using errcode = '55000';

  end if;


  -- ----------------------------------------------------------
  -- Contrato de alinhamento
  -- ----------------------------------------------------------

  if target_alignment_role not in (
    'primary',
    'supporting',
    'sustaining'
  ) then

    raise exception
      'Papel de alinhamento inválido.'
      using errcode = '22023';

  end if;


  if target_contribution_weight is not null

     and (
       target_contribution_weight < 0
       or target_contribution_weight > 100
     ) then

    raise exception
      'Peso de contribuição deve estar entre 0 e 100.'
      using errcode = '22023';

  end if;


  -- ==========================================================
  -- CREATE
  -- ==========================================================

  if target_alignment_id is null then


    insert into
      public.skpe_objective_evolution_scenario_alignments (

        organization_id,
        project_id,

        formulation_id,
        strategic_objective_id,

        strategic_horizon_id,

        scenario_id,
        scenario_cycle_id,

        alignment_role,
        contribution_weight,

        expected_result_in_cycle,
        rationale,

        validation_status,

        metadata,

        created_by,
        updated_by
      )

    values (

      v_formulation.organization_id,
      v_formulation.project_id,

      v_formulation.id,
      v_objective.id,

      v_cycle.strategic_horizon_id,

      v_scenario.id,
      v_cycle.id,

      target_alignment_role,
      target_contribution_weight,

      nullif(
        trim(target_expected_result_in_cycle),
        ''
      ),

      nullif(
        trim(target_alignment_rationale),
        ''
      ),

      'draft',

      jsonb_build_object(
        'governed_by',
        '17-B.4C.7'
      ),

      auth.uid(),
      auth.uid()
    )

    returning id
    into v_id;


    v_previous_data :=
      null;


  -- ==========================================================
  -- UPDATE
  -- ==========================================================

  else


    select *
    into v_existing

    from public.skpe_objective_evolution_scenario_alignments

    where id =
          target_alignment_id

    for update;


    if v_existing.id is null then

      raise exception
        'Alinhamento proposto não encontrado.'
        using errcode = '22023';

    end if;


    if v_existing.organization_id
         <> v_formulation.organization_id

       or v_existing.project_id
         <> v_formulation.project_id

       or v_existing.formulation_id
         <> v_formulation.id then

      raise exception
        'Alinhamento proposto não pertence à Formulação informada.'
        using errcode = '22023';

    end if;


    if v_existing.scenario_id
         <> v_scenario.id then

      raise exception
        'Alinhamento existente pertence a outro Cenário de Evolução.'
        using errcode = '55000';

    end if;


    v_previous_data :=
      to_jsonb(v_existing);


    update
      public.skpe_objective_evolution_scenario_alignments

    set

      strategic_objective_id =
        v_objective.id,

      strategic_horizon_id =
        v_cycle.strategic_horizon_id,

      scenario_id =
        v_scenario.id,

      scenario_cycle_id =
        v_cycle.id,

      alignment_role =
        target_alignment_role,

      contribution_weight =
        target_contribution_weight,

      expected_result_in_cycle =
        nullif(
          trim(target_expected_result_in_cycle),
          ''
        ),

      rationale =
        nullif(
          trim(target_alignment_rationale),
          ''
        ),

      validation_status =
        'draft',

      updated_at =
        timezone('utc', now()),

      updated_by =
        auth.uid()

    where id =
          v_existing.id

    returning id
    into v_id;


  end if;


  -- ----------------------------------------------------------
  -- Auditoria
  -- ----------------------------------------------------------

  perform
    public.skpe_record_operational_audit(

      v_formulation.organization_id,
      v_formulation.project_id,

      'objective_evolution_scenario_alignment',
      v_id,

      case
        when target_alignment_id is null
        then 'created'
        else 'updated'
      end,

      change_reason,

      v_previous_data,

      jsonb_build_object(

        'alignment_id',
        v_id,

        'formulation_id',
        v_formulation.id,

        'strategic_objective_id',
        v_objective.id,

        'scenario_id',
        v_scenario.id,

        'scenario_cycle_id',
        v_cycle.id,

        'alignment_role',
        target_alignment_role,

        'contribution_weight',
        target_contribution_weight
      )
    );


  return v_id;

end;

$function$;


-- ============================================================
-- 02. GOVERNED DELETE — PROPOSED ALIGNMENT
-- ============================================================

create or replace function
  public.delete_skpe_objective_evolution_scenario_alignment(

    target_alignment_id uuid,
    change_reason text
  )
returns void
language plpgsql
security definer
set search_path = ''
as $function$

declare

  v_alignment
    public.skpe_objective_evolution_scenario_alignments%rowtype;

  v_scenario
    public.skpe_evolution_scenarios%rowtype;

begin

  perform public.skpe_assert_reason(
    change_reason
  );


  select *
  into v_alignment

  from public.skpe_objective_evolution_scenario_alignments

  where id =
        target_alignment_id

  for update;


  if v_alignment.id is null then

    raise exception
      'Alinhamento proposto não encontrado.'
      using errcode = '22023';

  end if;


  if not public.can_manage_skpe_formulation(
    v_alignment.organization_id
  )

  or not public.can_manage_skpe_governance(
    v_alignment.organization_id
  ) then

    raise exception
      'Acesso negado à remoção do alinhamento Objetivo–Ciclo de Evolução.'
      using errcode = '42501';

  end if;


  select *
  into v_scenario

  from public.skpe_evolution_scenarios

  where id =
        v_alignment.scenario_id

  for update;


  if v_scenario.id is null then

    raise exception
      'Cenário de Evolução não encontrado.'
      using errcode = '22023';

  end if;


  if v_scenario.status not in (
    'draft',
    'adjusted'
  ) then

    raise exception
      'Alinhamento não pode ser removido após a submissão do Cenário de Evolução.'
      using errcode = '55000';

  end if;


  perform
    public.skpe_record_operational_audit(

      v_alignment.organization_id,
      v_alignment.project_id,

      'objective_evolution_scenario_alignment',
      v_alignment.id,

      'deleted',

      change_reason,

      to_jsonb(v_alignment),

      null
    );


  delete from
    public.skpe_objective_evolution_scenario_alignments

  where id =
        v_alignment.id;

end;

$function$;


-- ============================================================
-- 03. OBJECTIVE–EVOLUTION ALIGNMENT READINESS
-- ============================================================

create or replace function
  public.get_skpe_objective_evolution_alignment_readiness(
    target_project_id uuid
  )
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$

declare

  v_project
    public.skpe_projects%rowtype;

  v_horizon
    public.skpe_strategic_horizons%rowtype;

  v_formulation
    public.skpe_strategic_formulations%rowtype;

  v_plan
    public.skpe_evolution_plans%rowtype;

  v_objective_count integer :=
    0;

  v_aligned_objective_count integer :=
    0;

  v_alignment_count integer :=
    0;

  v_materializable_alignment_count integer :=
    0;

  v_missing_objectives jsonb :=
    '[]'::jsonb;

  v_issues jsonb :=
    '[]'::jsonb;

  v_blocking integer :=
    0;

begin

  -- ----------------------------------------------------------
  -- Project
  -- ----------------------------------------------------------

  select *
  into v_project

  from public.skpe_projects

  where id =
        target_project_id

    and archived_at is null;


  if v_project.id is null then

    raise exception
      'Projeto SK-PE não encontrado.'
      using errcode = '22023';

  end if;


  if not public.can_view_skpe_journey(
    v_project.organization_id
  ) then

    raise exception
      'Acesso negado à leitura do alinhamento Objetivo–Ciclo.'
      using errcode = '42501';

  end if;


  -- ----------------------------------------------------------
  -- Current Horizon
  -- ----------------------------------------------------------

  select *
  into v_horizon

  from public.skpe_strategic_horizons

  where project_id =
        v_project.id

    and is_current =
        true

  limit 1;


  -- ----------------------------------------------------------
  -- Approved formulation
  -- ----------------------------------------------------------

  select *
  into v_formulation

  from public.skpe_strategic_formulations

  where project_id =
        v_project.id

    and status =
        'approved'

  order by
    version_number desc

  limit 1;


  -- ----------------------------------------------------------
  -- Current Evolution Plan
  -- ----------------------------------------------------------

  if v_horizon.id is not null then

    select *
    into v_plan

    from public.skpe_evolution_plans

    where strategic_horizon_id =
          v_horizon.id

      and is_current =
          true

      and governance_status in (
        'approved',
        'historical_recognized'
      )

    order by
      version_number desc

    limit 1;

  end if;


  -- ----------------------------------------------------------
  -- Alignment can only be evaluated with approved formulation
  -- and current plan.
  -- ----------------------------------------------------------

  if v_formulation.id is null
     or v_plan.id is null then

    return jsonb_build_object(

      'projectId',
      v_project.id,

      'approvedFormulationId',
      v_formulation.id,

      'evolutionPlanId',
      v_plan.id,

      'sourceScenarioId',
      v_plan.source_scenario_id,

      'objectiveCount',
      0,

      'alignedObjectiveCount',
      0,

      'alignmentCount',
      0,

      'materializableAlignmentCount',
      0,

      'missingObjectives',
      '[]'::jsonb,

      'readyForClosure',
      false,

      'blockingIssueCount',
      0,

      'issues',
      '[]'::jsonb
    );

  end if;


  -- ----------------------------------------------------------
  -- Native materialization requires scenario lineage.
  -- ----------------------------------------------------------

  if v_plan.source_scenario_id is null then

    v_issues :=
      v_issues
      || jsonb_build_array(

        jsonb_build_object(

          'code',
          'EVOLUTION_PLAN_SOURCE_SCENARIO_MISSING',

          'severity',
          'blocking',

          'message',
          'O Plano de Evolução corrente não possui Cenário de Evolução de origem para materializar o alinhamento dos Objetivos.'
        )
      );

    v_blocking :=
      v_blocking + 1;

  end if;


  -- ----------------------------------------------------------
  -- Objectives of approved formulation
  -- ----------------------------------------------------------

  select
    count(*)

  into
    v_objective_count

  from public.skpe_strategic_objectives o

  where o.formulation_id =
        v_formulation.id

    and o.project_id =
        v_project.id

    and o.status <>
        'archived';


  -- ----------------------------------------------------------
  -- Proposed alignment count
  -- ----------------------------------------------------------

  if v_plan.source_scenario_id is not null then

    select
      count(*)

    into
      v_alignment_count

    from public.skpe_objective_evolution_scenario_alignments a

    join public.skpe_strategic_objectives o
      on o.id =
         a.strategic_objective_id

     and o.formulation_id =
         a.formulation_id

    where a.formulation_id =
          v_formulation.id

      and a.project_id =
          v_project.id

      and a.scenario_id =
          v_plan.source_scenario_id

      and a.validation_status <>
          'rejected'

      and o.status <>
          'archived';


    select
      count(
        distinct a.strategic_objective_id
      )

    into
      v_aligned_objective_count

    from public.skpe_objective_evolution_scenario_alignments a

    join public.skpe_strategic_objectives o
      on o.id =
         a.strategic_objective_id

     and o.formulation_id =
         a.formulation_id

    where a.formulation_id =
          v_formulation.id

      and a.project_id =
          v_project.id

      and a.scenario_id =
          v_plan.source_scenario_id

      and a.validation_status <>
          'rejected'

      and o.status <>
          'archived';


    -- --------------------------------------------------------
    -- Every proposed alignment must map to a materialized cycle
    -- of the current Evolution Plan.
    -- --------------------------------------------------------

    select
      count(*)

    into
      v_materializable_alignment_count

    from public.skpe_objective_evolution_scenario_alignments a

    join public.skpe_strategic_objectives o
      on o.id =
         a.strategic_objective_id

     and o.formulation_id =
         a.formulation_id

    join public.skpe_evolution_cycles c
      on c.source_scenario_cycle_id =
         a.scenario_cycle_id

     and c.evolution_plan_id =
         v_plan.id

    where a.formulation_id =
          v_formulation.id

      and a.project_id =
          v_project.id

      and a.scenario_id =
          v_plan.source_scenario_id

      and a.validation_status <>
          'rejected'

      and o.status <>
          'archived';


    -- --------------------------------------------------------
    -- Missing objectives
    -- --------------------------------------------------------

    select
      coalesce(

        jsonb_agg(

          jsonb_build_object(

            'id',
            o.id,

            'code',
            o.code,

            'name',
            o.title
          )

          order by
            o.code,
            o.title
        ),

        '[]'::jsonb
      )

    into
      v_missing_objectives

    from public.skpe_strategic_objectives o

    where o.formulation_id =
          v_formulation.id

      and o.project_id =
          v_project.id

      and o.status <>
          'archived'

      and not exists (

        select 1

        from public.skpe_objective_evolution_scenario_alignments a

        where a.strategic_objective_id =
              o.id

          and a.formulation_id =
              v_formulation.id

          and a.scenario_id =
              v_plan.source_scenario_id

          and a.validation_status <>
              'rejected'
      );

  end if;


  -- ----------------------------------------------------------
  -- Every strategic objective must participate in at least one
  -- Evolution Cycle.
  -- ----------------------------------------------------------

  if v_aligned_objective_count
       < v_objective_count then

    v_issues :=
      v_issues
      || jsonb_build_array(

        jsonb_build_object(

          'code',
          'OBJECTIVE_EVOLUTION_ALIGNMENT_MISSING',

          'severity',
          'blocking',

          'message',
          'Todo Objetivo Estratégico da Formulação aprovada deve estar alinhado a pelo menos um Ciclo de Evolução.',

          'missingObjectives',
          v_missing_objectives
        )
      );

    v_blocking :=
      v_blocking + 1;

  end if;


  -- ----------------------------------------------------------
  -- All proposed alignments must have materialized cycle lineage
  -- ----------------------------------------------------------

  if v_alignment_count
       <> v_materializable_alignment_count then

    v_issues :=
      v_issues
      || jsonb_build_array(

        jsonb_build_object(

          'code',
          'OBJECTIVE_EVOLUTION_ALIGNMENT_NOT_MATERIALIZABLE',

          'severity',
          'blocking',

          'message',
          'Existem alinhamentos propostos sem correspondência no Plano de Evolução corrente.',

          'alignmentCount',
          v_alignment_count,

          'materializableAlignmentCount',
          v_materializable_alignment_count
        )
      );

    v_blocking :=
      v_blocking + 1;

  end if;


  return jsonb_build_object(

    'projectId',
    v_project.id,

    'approvedFormulationId',
    v_formulation.id,

    'evolutionPlanId',
    v_plan.id,

    'sourceScenarioId',
    v_plan.source_scenario_id,

    'objectiveCount',
    v_objective_count,

    'alignedObjectiveCount',
    v_aligned_objective_count,

    'alignmentCount',
    v_alignment_count,

    'materializableAlignmentCount',
    v_materializable_alignment_count,

    'missingObjectives',
    v_missing_objectives,

    'readyForClosure',
    v_blocking = 0,

    'blockingIssueCount',
    v_blocking,

    'issues',
    v_issues
  );

end;

$function$;


-- ============================================================
-- 04. PEM-02 GATE READINESS — CONVERGED
-- ============================================================

create or replace function
  public.get_skpe_pem02_gate_readiness(
    target_project_id uuid
  )
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$

declare

  v_project
    public.skpe_projects%rowtype;

  v_gate
    public.skpe_journey_items%rowtype;

  v_pem02
    public.skpe_journey_items%rowtype;

  v_horizon
    public.skpe_strategic_horizons%rowtype;

  v_formulation
    public.skpe_strategic_formulations%rowtype;

  v_plan
    public.skpe_evolution_plans%rowtype;

  v_alignment_readiness jsonb;

  v_issues jsonb :=
    '[]'::jsonb;

  v_blocking integer :=
    0;

begin

  select *
  into v_project

  from public.skpe_projects

  where id =
        target_project_id

    and archived_at is null;


  if v_project.id is null then

    raise exception
      'Projeto SK-PE não encontrado.'
      using errcode = '22023';

  end if;


  if not public.can_view_skpe_journey(
    v_project.organization_id
  ) then

    raise exception
      'Acesso negado à leitura do Gate PEM-02.'
      using errcode = '42501';

  end if;


  -- ----------------------------------------------------------
  -- Journey
  -- ----------------------------------------------------------

  select *
  into v_gate

  from public.skpe_journey_items

  where project_id =
        v_project.id

    and code =
        'PEM-02.GATE'

    and item_type =
        'gate'

  limit 1;


  select *
  into v_pem02

  from public.skpe_journey_items

  where project_id =
        v_project.id

    and code =
        'PEM-02'

    and item_type =
        'macrophase'

  limit 1;


  -- ----------------------------------------------------------
  -- Horizon
  -- ----------------------------------------------------------

  select *
  into v_horizon

  from public.skpe_strategic_horizons

  where project_id =
        v_project.id

    and is_current =
        true

  limit 1;


  -- ----------------------------------------------------------
  -- Approved formulation
  -- ----------------------------------------------------------

  select *
  into v_formulation

  from public.skpe_strategic_formulations

  where project_id =
        v_project.id

    and status =
        'approved'

  order by
    version_number desc

  limit 1;


  -- ----------------------------------------------------------
  -- Evolution Plan
  -- ----------------------------------------------------------

  if v_horizon.id is not null then

    select *
    into v_plan

    from public.skpe_evolution_plans

    where strategic_horizon_id =
          v_horizon.id

      and is_current =
          true

      and governance_status in (
        'approved',
        'historical_recognized'
      )

    order by
      version_number desc

    limit 1;

  end if;


  -- ----------------------------------------------------------
  -- Base issues
  -- ----------------------------------------------------------

  if v_gate.id is null then

    v_issues :=
      v_issues
      || jsonb_build_array(
        jsonb_build_object(
          'code',
          'PEM02_GATE_MISSING',
          'severity',
          'blocking',
          'message',
          'PEM-02.GATE não localizado.'
        )
      );

    v_blocking :=
      v_blocking + 1;

  end if;


  if v_pem02.id is null
     or v_pem02.status <> 'completed'
     or v_pem02.progress <> 100 then

    v_issues :=
      v_issues
      || jsonb_build_array(
        jsonb_build_object(
          'code',
          'PEM02_NOT_COMPLETED',
          'severity',
          'blocking',
          'message',
          'A Macrofase PEM-02 deve estar concluída com progresso integral.'
        )
      );

    v_blocking :=
      v_blocking + 1;

  end if;


  if v_horizon.id is null then

    v_issues :=
      v_issues
      || jsonb_build_array(
        jsonb_build_object(
          'code',
          'CURRENT_HORIZON_MISSING',
          'severity',
          'blocking',
          'message',
          'Horizonte Estratégico corrente não localizado.'
        )
      );

    v_blocking :=
      v_blocking + 1;

  end if;


  if v_formulation.id is null then

    v_issues :=
      v_issues
      || jsonb_build_array(
        jsonb_build_object(
          'code',
          'APPROVED_FORMULATION_MISSING',
          'severity',
          'blocking',
          'message',
          'A Formulação Estratégica precisa estar aprovada antes do fechamento do PEM-02.GATE.'
        )
      );

    v_blocking :=
      v_blocking + 1;

  end if;


  if v_plan.id is null then

    v_issues :=
      v_issues
      || jsonb_build_array(
        jsonb_build_object(
          'code',
          'CURRENT_EVOLUTION_PLAN_MISSING',
          'severity',
          'blocking',
          'message',
          'Plano de Evolução corrente não localizado para o Horizonte Estratégico atual.'
        )
      );

    v_blocking :=
      v_blocking + 1;

  end if;


  -- ----------------------------------------------------------
  -- Objective–Evolution alignment readiness
  -- ----------------------------------------------------------

  if v_formulation.id is not null
     and v_plan.id is not null then

    v_alignment_readiness :=
      public.get_skpe_objective_evolution_alignment_readiness(
        v_project.id
      );


    v_issues :=
      v_issues
      || coalesce(
        v_alignment_readiness
        -> 'issues',
        '[]'::jsonb
      );


    v_blocking :=
      v_blocking
      + coalesce(
          (
            v_alignment_readiness
            ->> 'blockingIssueCount'
          )::integer,
          0
        );

  else

    v_alignment_readiness :=
      jsonb_build_object(

        'readyForClosure',
        false,

        'blockingIssueCount',
        0,

        'issues',
        '[]'::jsonb
      );

  end if;


  return jsonb_build_object(

    'projectId',
    v_project.id,

    'gateId',
    v_gate.id,

    'pem02Status',
    v_pem02.status,

    'pem02Progress',
    v_pem02.progress,

    'strategicHorizonId',
    v_horizon.id,

    'approvedFormulationId',
    v_formulation.id,

    'evolutionPlanId',
    v_plan.id,

    'objectiveEvolutionAlignment',
    v_alignment_readiness,

    'readyForClosure',
    v_blocking = 0,

    'blockingIssueCount',
    v_blocking,

    'issues',
    v_issues
  );

end;

$function$;


-- ============================================================
-- 05. INTERNAL MATERIALIZER
-- ============================================================

create or replace function
  public.skpe_materialize_pem02_objective_evolution_alignments(

    target_project_id uuid,
    target_gate_decision_id uuid
  )
returns integer
language plpgsql
security definer
set search_path = ''
as $function$

declare

  v_decision
    public.skpe_gate_decisions%rowtype;

  v_formulation
    public.skpe_strategic_formulations%rowtype;

  v_plan
    public.skpe_evolution_plans%rowtype;

  v_expected integer :=
    0;

  v_materialized integer :=
    0;

begin

  -- ----------------------------------------------------------
  -- Canonical PEM-02 closure decision
  -- ----------------------------------------------------------

  select *
  into v_decision

  from public.skpe_gate_decisions

  where id =
        target_gate_decision_id

    and project_id =
        target_project_id

  for update;


  if v_decision.id is null then

    raise exception
      'Decisão institucional do PEM-02.GATE não encontrada.'
      using errcode = '55000';

  end if;


  if v_decision.decision_context
       ->> 'decision_kind'
       <> 'pem02_gate_closure'

     or v_decision.decision_outcome
        not in (
          'approved',
          'approved_with_reservations'
        ) then

    raise exception
      'Decisão inválida para materialização do alinhamento Objetivo–Ciclo.'
      using errcode = '55000';

  end if;


  -- ----------------------------------------------------------
  -- Approved formulation
  -- ----------------------------------------------------------

  select *
  into v_formulation

  from public.skpe_strategic_formulations

  where project_id =
        target_project_id

    and status =
        'approved'

  order by
    version_number desc

  limit 1;


  if v_formulation.id is null then

    raise exception
      'Formulação Estratégica aprovada não localizada.'
      using errcode = '55000';

  end if;


  -- ----------------------------------------------------------
  -- Current native Evolution Plan
  -- ----------------------------------------------------------

  select *
  into v_plan

  from public.skpe_evolution_plans

  where project_id =
        target_project_id

    and is_current =
        true

    and governance_status =
        'approved'

  order by
    version_number desc

  limit 1;


  if v_plan.id is null then

    raise exception
      'Plano de Evolução aprovado e corrente não localizado.'
      using errcode = '55000';

  end if;


  if v_plan.source_scenario_id is null then

    raise exception
      'Plano de Evolução corrente não possui Cenário de origem materializável.'
      using errcode = '55000';

  end if;


  -- ----------------------------------------------------------
  -- Expected proposed alignments
  -- ----------------------------------------------------------

  select
    count(*)

  into
    v_expected

  from public.skpe_objective_evolution_scenario_alignments a

  where a.formulation_id =
        v_formulation.id

    and a.project_id =
        target_project_id

    and a.scenario_id =
        v_plan.source_scenario_id

    and a.validation_status <>
        'rejected';


  -- ----------------------------------------------------------
  -- Materialization
  -- ----------------------------------------------------------

  insert into
    public.skpe_objective_evolution_cycle_alignments (

      organization_id,
      project_id,

      formulation_id,
      strategic_objective_id,

      strategic_horizon_id,

      evolution_plan_id,
      evolution_cycle_id,

      source_scenario_alignment_id,

      materialization_gate_decision_id,

      alignment_role,
      contribution_weight,

      expected_result_in_cycle,
      rationale,

      metadata,

      created_by,
      updated_by
    )

  select

    a.organization_id,
    a.project_id,

    a.formulation_id,
    a.strategic_objective_id,

    c.strategic_horizon_id,

    c.evolution_plan_id,
    c.id,

    a.id,

    v_decision.id,

    a.alignment_role,
    a.contribution_weight,

    a.expected_result_in_cycle,
    a.rationale,

    jsonb_build_object(

      'materialized_from_scenario_alignment_id',
      a.id,

      'materialized_from_scenario_cycle_id',
      a.scenario_cycle_id,

      'materialized_by_gate',
      'PEM-02.GATE'
    ),

    auth.uid(),
    auth.uid()

  from
    public.skpe_objective_evolution_scenario_alignments a

  join
    public.skpe_evolution_cycles c

    on c.source_scenario_cycle_id =
       a.scenario_cycle_id

   and c.evolution_plan_id =
       v_plan.id

  where a.formulation_id =
        v_formulation.id

    and a.project_id =
        target_project_id

    and a.scenario_id =
        v_plan.source_scenario_id

    and a.validation_status <>
        'rejected'

  order by
    a.strategic_objective_id,
    c.sequence_number,
    c.id;


  get diagnostics
    v_materialized =
    row_count;


  if v_materialized
       <> v_expected then

    raise exception
      'Materialização incompleta do alinhamento Objetivo–Ciclo.'
      using
        errcode = '55000',
        detail =
          format(
            'Esperados: %s; materializados: %s.',
            v_expected,
            v_materialized
          );

  end if;


  -- ----------------------------------------------------------
  -- Proposed links become validated by final institutional Gate
  -- ----------------------------------------------------------

  update
    public.skpe_objective_evolution_scenario_alignments

  set

    validation_status =
      'validated',

    updated_at =
      timezone('utc', now()),

    updated_by =
      auth.uid()

  where formulation_id =
        v_formulation.id

    and project_id =
        target_project_id

    and scenario_id =
        v_plan.source_scenario_id

    and validation_status <>
        'rejected';


  return v_materialized;

end;

$function$;


-- ============================================================
-- 06. PEM-02.GATE RATIFICATION — WITH MATERIALIZATION
-- ============================================================

create or replace function
  public.ratify_skpe_pem02_gate(

    target_project_id uuid,

    decision_outcome text,
    decision_reason text,

    reservations text,
    adjustment_requirements text,

    change_reason text
  )
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$

declare

  v_project
    public.skpe_projects%rowtype;

  v_gate
    public.skpe_journey_items%rowtype;

  v_readiness jsonb;

  v_prev_decision uuid;

  v_sequence integer;

  v_decision uuid;

  v_validation_status text;

  v_materialized_alignments integer :=
    0;

begin

  perform public.skpe_assert_reason(
    change_reason
  );


  -- ----------------------------------------------------------
  -- Decision contract
  -- ----------------------------------------------------------

  if nullif(
    trim(decision_reason),
    ''
  ) is null then

    raise exception
      'Informe a justificativa da decisão do PEM-02.GATE.'
      using errcode = '22023';

  end if;


  if decision_outcome not in (

    'approved',
    'approved_with_reservations',
    'returned_for_adjustment'

  ) then

    raise exception
      'Resultado inválido para o PEM-02.GATE.'
      using errcode = '22023';

  end if;


  if decision_outcome =
     'approved_with_reservations'

     and nullif(
       trim(reservations),
       ''
     ) is null then

    raise exception
      'Aprovação com ressalvas exige descrição das ressalvas.'
      using errcode = '22023';

  end if;


  if decision_outcome =
     'returned_for_adjustment'

     and nullif(
       trim(adjustment_requirements),
       ''
     ) is null then

    raise exception
      'Retorno para ajuste exige requisitos de ajuste.'
      using errcode = '22023';

  end if;


  -- ----------------------------------------------------------
  -- Project
  -- ----------------------------------------------------------

  select *
  into v_project

  from public.skpe_projects

  where id =
        target_project_id

    and archived_at is null

  for update;


  if v_project.id is null then

    raise exception
      'Projeto SK-PE não encontrado.'
      using errcode = '22023';

  end if;


  if not public.can_ratify_skpe_governance(
    v_project.organization_id
  ) then

    raise exception
      'Acesso negado à ratificação do PEM-02.GATE.'
      using errcode = '42501';

  end if;


  -- ----------------------------------------------------------
  -- Gate
  -- ----------------------------------------------------------

  select *
  into v_gate

  from public.skpe_journey_items

  where project_id =
        v_project.id

    and code =
        'PEM-02.GATE'

    and item_type =
        'gate'

  for update;


  if v_gate.id is null then

    raise exception
      'PEM-02.GATE não localizado.'
      using errcode = '55000';

  end if;


  if v_gate.status =
     'completed' then

    raise exception
      'PEM-02.GATE já está concluído e não pode ser ratificado novamente.'
      using errcode = '55000';

  end if;


  -- ----------------------------------------------------------
  -- Canonical readiness
  -- ----------------------------------------------------------

  v_readiness :=
    public.get_skpe_pem02_gate_readiness(
      v_project.id
    );


  if decision_outcome in (
       'approved',
       'approved_with_reservations'
     )

     and not coalesce(
       (
         v_readiness
         ->> 'readyForClosure'
       )::boolean,
       false
     ) then

    raise exception
      'PEM-02.GATE possui pendências bloqueantes.'
      using
        errcode = '55000',
        detail = v_readiness::text;

  end if;


  -- ----------------------------------------------------------
  -- Previous PEM-02 closure decision
  -- ----------------------------------------------------------

  select
    id

  into
    v_prev_decision

  from public.skpe_gate_decisions

  where project_id =
        v_project.id

    and gate_journey_item_id =
        v_gate.id

    and decision_context
        ->> 'decision_kind' =
        'pem02_gate_closure'

  order by
    decision_sequence desc

  limit 1;


  -- ----------------------------------------------------------
  -- Shared Gate decision sequence
  -- Gate row is already FOR UPDATE, serializing ratification.
  -- ----------------------------------------------------------

  select

    coalesce(
      max(decision_sequence),
      0
    ) + 1

  into
    v_sequence

  from public.skpe_gate_decisions

  where project_id =
        v_project.id

    and gate_journey_item_id =
        v_gate.id;


  -- ----------------------------------------------------------
  -- Institutional Gate decision
  -- ----------------------------------------------------------

  insert into
    public.skpe_gate_decisions (

      organization_id,
      project_id,

      gate_journey_item_id,

      decision_outcome,
      decision_reason,

      reservations,
      adjustment_requirements,

      readiness_snapshot,

      decision_context,

      supersedes_decision_id,
      decision_sequence,

      decided_at,
      decided_by,

      decision_origin_type,
      decided_by_actor_type,
      decision_time_precision,

      metadata
    )

  values (

    v_project.organization_id,
    v_project.id,

    v_gate.id,

    decision_outcome,
    trim(decision_reason),

    case
      when decision_outcome =
           'approved_with_reservations'
      then nullif(
        trim(reservations),
        ''
      )
    end,

    case
      when decision_outcome =
           'returned_for_adjustment'
      then nullif(
        trim(adjustment_requirements),
        ''
      )
    end,

    v_readiness,

    jsonb_build_object(

      'decision_kind',
      'pem02_gate_closure',

      'project_id',
      v_project.id
    ),

    v_prev_decision,
    v_sequence,

    timezone('utc', now()),
    auth.uid(),

    'native_platform',
    'organization',
    'exact_datetime',

    jsonb_build_object(

      'gate',
      '17-B.4C.7',

      'journey_gate',
      'PEM-02.GATE',

      'objective_evolution_alignment',
      true
    )
  )

  returning id
  into v_decision;


  -- ==========================================================
  -- RETURN FOR ADJUSTMENT
  -- ==========================================================

  if decision_outcome =
     'returned_for_adjustment' then


    update
      public.skpe_journey_items

    set

      validation_status =
        'rejected',

      status =
        'in_progress',

      progress =
        least(progress, 99),

      is_current =
        true,

      actual_start_date =
        coalesce(
          actual_start_date,
          current_date
        ),

      actual_end_date =
        null,

      updated_by =
        auth.uid()

    where id =
          v_gate.id;


    insert into
      public.skpe_journey_audit (

        organization_id,
        project_id,

        journey_item_id,

        actor_user_id,

        action_code,
        reason,

        new_data
      )

    values (

      v_project.organization_id,
      v_project.id,

      v_gate.id,

      auth.uid(),

      'pem02_gate_returned_for_adjustment',

      change_reason,

      jsonb_build_object(

        'gate_decision_id',
        v_decision,

        'adjustment_requirements',
        adjustment_requirements
      )
    );


    perform
      public.skpe_recalculate_journey_project_internal(
        v_project.id,
        change_reason,
        auth.uid()
      );


    return jsonb_build_object(

      'gateId',
      v_gate.id,

      'gateDecisionId',
      v_decision,

      'decisionOutcome',
      decision_outcome,

      'status',
      'in_progress',

      'validationStatus',
      'rejected',

      'materializedObjectiveEvolutionAlignments',
      0
    );

  end if;


  -- ==========================================================
  -- FINAL OBJECTIVE–EVOLUTION MATERIALIZATION
  -- ==========================================================

  v_materialized_alignments :=
    public.skpe_materialize_pem02_objective_evolution_alignments(

      v_project.id,
      v_decision
    );


  -- ==========================================================
  -- APPROVAL
  -- ==========================================================

  v_validation_status :=
    case

      when decision_outcome =
           'approved_with_reservations'

      then
        'approved_with_reservations'

      else
        'approved'

    end;


  update
    public.skpe_journey_items

  set

    validation_status =
      v_validation_status,

    status =
      'completed',

    progress =
      100,

    is_current =
      false,

    actual_end_date =
      coalesce(
        actual_end_date,
        current_date
      ),

    updated_by =
      auth.uid()

  where id =
        v_gate.id;


  insert into
    public.skpe_journey_audit (

      organization_id,
      project_id,

      journey_item_id,

      actor_user_id,

      action_code,
      reason,

      new_data
    )

  values (

    v_project.organization_id,
    v_project.id,

    v_gate.id,

    auth.uid(),

    'pem02_gate_ratified',

    change_reason,

    jsonb_build_object(

      'gate_decision_id',
      v_decision,

      'decision_outcome',
      decision_outcome,

      'validation_status',
      v_validation_status,

      'materialized_objective_evolution_alignments',
      v_materialized_alignments,

      'readiness',
      v_readiness
    )
  );


  perform
    public.skpe_recalculate_journey_project_internal(
      v_project.id,
      change_reason,
      auth.uid()
    );


  return jsonb_build_object(

    'gateId',
    v_gate.id,

    'gateDecisionId',
    v_decision,

    'decisionOutcome',
    decision_outcome,

    'status',
    'completed',

    'validationStatus',
    v_validation_status,

    'materializedObjectiveEvolutionAlignments',
    v_materialized_alignments
  );

end;

$function$;


-- ============================================================
-- 07. FUNCTION PRIVILEGES
-- ============================================================
--
-- PostgreSQL grants EXECUTE to PUBLIC by default.
-- Every SECURITY DEFINER entrypoint is therefore explicitly
-- revoked before selective grants.
-- ============================================================

revoke all
on function
  public.upsert_skpe_objective_evolution_scenario_alignment(
    uuid,
    uuid,
    uuid,
    uuid,
    text,
    numeric,
    text,
    text,
    text
  )
from public, anon;


revoke all
on function
  public.delete_skpe_objective_evolution_scenario_alignment(
    uuid,
    text
  )
from public, anon;


revoke all
on function
  public.get_skpe_objective_evolution_alignment_readiness(
    uuid
  )
from public, anon;


revoke all
on function
  public.skpe_materialize_pem02_objective_evolution_alignments(
    uuid,
    uuid
  )
from public, anon, authenticated;


revoke all
on function
  public.get_skpe_pem02_gate_readiness(
    uuid
  )
from public, anon;


revoke all
on function
  public.ratify_skpe_pem02_gate(
    uuid,
    text,
    text,
    text,
    text,
    text
  )
from public, anon;


grant execute
on function
  public.upsert_skpe_objective_evolution_scenario_alignment(
    uuid,
    uuid,
    uuid,
    uuid,
    text,
    numeric,
    text,
    text,
    text
  )
to authenticated, service_role;


grant execute
on function
  public.delete_skpe_objective_evolution_scenario_alignment(
    uuid,
    text
  )
to authenticated, service_role;


grant execute
on function
  public.get_skpe_objective_evolution_alignment_readiness(
    uuid
  )
to authenticated, service_role;


grant execute
on function
  public.skpe_materialize_pem02_objective_evolution_alignments(
    uuid,
    uuid
  )
to service_role;


grant execute
on function
  public.get_skpe_pem02_gate_readiness(
    uuid
  )
to authenticated, service_role;


grant execute
on function
  public.ratify_skpe_pem02_gate(
    uuid,
    text,
    text,
    text,
    text,
    text
  )
to authenticated, service_role;


-- ============================================================
-- 08. DOCUMENTATION
-- ============================================================

comment on function
  public.upsert_skpe_objective_evolution_scenario_alignment(
    uuid,
    uuid,
    uuid,
    uuid,
    text,
    numeric,
    text,
    text,
    text
  )
is
  'Cria ou atualiza de forma governada o alinhamento proposto entre Objetivo Estratégico e Ciclo de Evolução de cenário. O alinhamento continua proposta até a ratificação do PEM-02.GATE.';


comment on function
  public.delete_skpe_objective_evolution_scenario_alignment(
    uuid,
    text
  )
is
  'Remove alinhamento proposto enquanto o Cenário de Evolução permanecer em rascunho ou ajuste, preservando auditoria.';


comment on function
  public.get_skpe_objective_evolution_alignment_readiness(
    uuid
  )
is
  'Avalia se todos os Objetivos Estratégicos não arquivados da Formulação aprovada possuem alinhamento materializável com o Cenário que originou o Plano de Evolução corrente.';


comment on function
  public.get_skpe_pem02_gate_readiness(
    uuid
  )
is
  'Deriva o readiness institucional do PEM-02.GATE incluindo conclusão da Macrofase, Horizonte, Formulação aprovada, Plano de Evolução e cobertura materializável dos Objetivos Estratégicos pelos Ciclos de Evolução.';


comment on function
  public.skpe_materialize_pem02_objective_evolution_alignments(
    uuid,
    uuid
  )
is
  'Materializador interno que converte alinhamentos Objetivo–Scenario Cycle em alinhamentos institucionais Objetivo–Evolution Cycle durante a decisão final de fechamento do PEM-02.GATE.';


comment on function
  public.ratify_skpe_pem02_gate(
    uuid,
    text,
    text,
    text,
    text,
    text
  )
is
  'Registra a decisão institucional agregadora do PEM-02.GATE, materializa os alinhamentos definitivos Objetivo–Ciclo e conclui o Gate somente quando todo o readiness canônico estiver atendido.';