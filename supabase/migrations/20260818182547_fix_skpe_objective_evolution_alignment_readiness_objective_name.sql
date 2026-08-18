-- SK-PE-CONT-01
-- GATE-17-B.4C.8-FIX-01
--
-- Correção preventiva de runtime identificada durante a integração
-- da aplicação de Ciclos de Evolução.
--
-- A função de readiness criada em 17-B.4C.7 referenciava
-- skpe_strategic_objectives.title, porém o atributo canônico da
-- entidade Objetivo Estratégico é name.
--
-- Esta migration:
-- - não altera schema;
-- - não cria nova fonte de verdade;
-- - não altera semântica do readiness;
-- - não altera permissões;
-- - não altera materialização;
-- - apenas corrige title -> name na função existente.
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
            o.name
          )

          order by
            o.code,
            o.name
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
