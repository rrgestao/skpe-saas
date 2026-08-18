-- SK-PE-CONT-01
-- GATE-17-B.4C.4D — Governed Operations for Evolution Cycles
--
-- Responsabilidades:
--
-- 1. criar/editar Cenário de Evolução;
-- 2. criar/editar Ciclos de Evolução propostos;
-- 3. governar transições do cenário;
-- 4. registrar decisão institucional no PEM-02.GATE;
-- 5. materializar Evolution Plan + Evolution Cycles;
-- 6. preservar auditoria, autorização e rastreabilidade.
--
-- Contrato metodológico:
--
-- PEM-01.GATE -> institucionaliza o Horizonte Estratégico.
-- PEM-02.GATE -> institucionaliza a trajetória de evolução
--                dentro do Horizonte.
--
-- Strategic Period
--   != Governance Effective Period
--   != Execution Period
--   != Measurement / Reference Period.


-- ============================================================
-- 01. INTERNAL READINESS HELPER
-- ============================================================
--
-- Deriva:
-- - quantidade de ciclos;
-- - primeira e última data;
-- - lacunas;
-- - continuidade;
-- - cobertura integral do Horizonte;
-- - readiness para submissão.
--
-- Nenhum desses resultados é persistido como nova verdade.
-- ============================================================

create or replace function
  public.skpe_get_evolution_scenario_readiness(
    target_scenario_id uuid
  )
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$

declare

  v_scenario public.skpe_evolution_scenarios%rowtype;
  v_horizon public.skpe_strategic_horizons%rowtype;

  v_cycle_count integer;

  v_first_start date;
  v_last_end date;

  v_gap_count integer;

  v_horizon_start date;
  v_horizon_end date;

  v_covers_horizon boolean;
  v_is_continuous boolean;

begin

  select *
  into v_scenario
  from public.skpe_evolution_scenarios
  where id = target_scenario_id;


  if v_scenario.id is null then

    raise exception
      'Cenário de Evolução não encontrado.'
      using errcode = '22023';

  end if;


  select *
  into v_horizon
  from public.skpe_strategic_horizons
  where id = v_scenario.strategic_horizon_id;


  if v_horizon.id is null then

    raise exception
      'Horizonte Estratégico do cenário não encontrado.'
      using errcode = '55000';

  end if;


  v_horizon_start :=
    make_date(
      v_horizon.horizon_start_year,
      1,
      1
    );


  v_horizon_end :=
    make_date(
      v_horizon.horizon_end_year,
      12,
      31
    );


  select
    count(*)::integer,
    min(period_start),
    max(period_end)

  into
    v_cycle_count,
    v_first_start,
    v_last_end

  from public.skpe_evolution_scenario_cycles

  where scenario_id = target_scenario_id;


  select
    count(*)::integer

  into
    v_gap_count

  from (

    select

      period_end,

      lead(period_start)
      over (
        order by
          period_start,
          sequence_number,
          id
      ) as next_start

    from public.skpe_evolution_scenario_cycles

    where scenario_id = target_scenario_id

  ) q

  where q.next_start is not null

    and q.next_start >
        q.period_end + 1;


  v_covers_horizon :=
    v_cycle_count > 0
    and v_first_start = v_horizon_start
    and v_last_end = v_horizon_end;


  v_is_continuous :=
    v_cycle_count > 0
    and v_gap_count = 0;


  return jsonb_build_object(

    'scenario_id',
    v_scenario.id,

    'strategic_horizon_id',
    v_horizon.id,

    'coverage_policy',
    v_scenario.coverage_policy,

    'cycle_count',
    v_cycle_count,

    'horizon_start',
    v_horizon_start,

    'horizon_end',
    v_horizon_end,

    'first_cycle_start',
    v_first_start,

    'last_cycle_end',
    v_last_end,

    'gap_count',
    v_gap_count,

    'has_gaps',
    v_gap_count > 0,

    'is_continuous',
    v_is_continuous,

    'covers_horizon',
    v_covers_horizon,

    'ready_to_submit',
    v_cycle_count > 0
    and (
      v_scenario.coverage_policy = 'allow_gaps'
      or (
        v_covers_horizon
        and v_is_continuous
      )
    )

  );

end;

$function$;


-- ============================================================
-- 02. UPSERT EVOLUTION SCENARIO
-- ============================================================

create or replace function
  public.upsert_skpe_evolution_scenario(

    target_project_id uuid,
    target_scenario_id uuid,

    scenario_title text,
    scenario_description text,
    scenario_strategic_rationale text,

    scenario_origin_type text,
    scenario_source_reference text,

    scenario_coverage_policy text,

    change_reason text
  )
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$

declare

  v_project public.skpe_projects%rowtype;

  v_horizon public.skpe_strategic_horizons%rowtype;

  v_scenario public.skpe_evolution_scenarios%rowtype;

  v_previous_scenario_id uuid;

  v_version integer;

  v_id uuid;

begin

  perform public.skpe_assert_reason(
    change_reason
  );


  select *
  into v_project

  from public.skpe_projects

  where id = target_project_id
    and archived_at is null

  for update;


  if v_project.id is null then

    raise exception
      'Projeto SK-PE não encontrado.'
      using errcode = '22023';

  end if;


  if not public.can_manage_skpe_governance(
    v_project.organization_id
  ) then

    raise exception
      'Acesso negado à gestão do Cenário de Evolução.'
      using errcode = '42501';

  end if;


  select *
  into v_horizon

  from public.skpe_strategic_horizons

  where project_id = target_project_id
    and is_current = true

  for update;


  if v_horizon.id is null then

    raise exception
      'Defina e institucionalize o Horizonte Estratégico antes dos Ciclos de Evolução.'
      using errcode = '55000';

  end if;


  if nullif(
    trim(scenario_title),
    ''
  ) is null then

    raise exception
      'Informe o título do Cenário de Evolução.'
      using errcode = '22023';

  end if;


  if scenario_origin_type not in (

    'consultancy_suggestion',
    'organization',
    'diagnostic',
    'historical_import',
    'system'

  ) then

    raise exception
      'Origem do Cenário de Evolução inválida.'
      using errcode = '22023';

  end if;


  if scenario_coverage_policy not in (

    'allow_gaps',
    'require_continuous'

  ) then

    raise exception
      'Política de cobertura do Cenário de Evolução inválida.'
      using errcode = '22023';

  end if;


  if target_scenario_id is null then


    if exists (

      select 1

      from public.skpe_evolution_scenarios

      where strategic_horizon_id = v_horizon.id

        and status in (
          'draft',
          'proposed',
          'under_review',
          'adjusted',
          'deferred'
        )

    ) then

      raise exception
        'Já existe Cenário de Evolução em aberto para o Horizonte Estratégico atual.'
        using errcode = '55000';

    end if;


    select
      id

    into
      v_previous_scenario_id

    from public.skpe_evolution_scenarios

    where strategic_horizon_id =
          v_horizon.id

    order by
      version_number desc

    limit 1;


    select
      coalesce(
        max(version_number),
        0
      ) + 1

    into
      v_version

    from public.skpe_evolution_scenarios

    where strategic_horizon_id =
          v_horizon.id;


    insert into
      public.skpe_evolution_scenarios (

        organization_id,
        project_id,
        strategic_horizon_id,

        version_number,
        status,

        title,
        description,
        strategic_rationale,

        origin_type,
        source_reference,

        coverage_policy,

        supersedes_scenario_id,

        metadata,

        created_by,
        updated_by
      )

    values (

      v_project.organization_id,
      v_project.id,
      v_horizon.id,

      v_version,
      'draft',

      trim(scenario_title),

      nullif(
        trim(scenario_description),
        ''
      ),

      nullif(
        trim(scenario_strategic_rationale),
        ''
      ),

      scenario_origin_type,

      nullif(
        trim(scenario_source_reference),
        ''
      ),

      scenario_coverage_policy,

      v_previous_scenario_id,

      jsonb_build_object(
        'created_during_phase',
        v_project.current_phase_code
      ),

      auth.uid(),
      auth.uid()
    )

    returning id
    into v_id;


  else


    select *
    into v_scenario

    from public.skpe_evolution_scenarios

    where id =
          target_scenario_id

    for update;


    if v_scenario.id is null
       or v_scenario.project_id <>
          target_project_id
       or v_scenario.strategic_horizon_id <>
          v_horizon.id then

      raise exception
        'Cenário de Evolução não encontrado no projeto/Horizonte atual.'
        using errcode = '22023';

    end if;


    if v_scenario.status not in (
      'draft',
      'adjusted'
    ) then

      raise exception
        'Somente Cenário de Evolução em rascunho ou ajuste pode ser editado.'
        using errcode = '55000';

    end if;


    update
      public.skpe_evolution_scenarios

    set

      title =
        trim(scenario_title),

      description =
        nullif(
          trim(scenario_description),
          ''
        ),

      strategic_rationale =
        nullif(
          trim(scenario_strategic_rationale),
          ''
        ),

      origin_type =
        scenario_origin_type,

      source_reference =
        nullif(
          trim(scenario_source_reference),
          ''
        ),

      coverage_policy =
        scenario_coverage_policy,

      updated_at =
        timezone('utc', now()),

      updated_by =
        auth.uid()

    where id =
          target_scenario_id

    returning id
    into v_id;


  end if;


  insert into
    public.skpe_journey_audit (

      organization_id,
      project_id,

      actor_user_id,

      action_code,
      reason,

      new_data
    )

  values (

    v_project.organization_id,
    v_project.id,

    auth.uid(),

    'evolution_scenario_upserted',
    change_reason,

    jsonb_build_object(

      'scenario_id',
      v_id,

      'strategic_horizon_id',
      v_horizon.id,

      'origin_type',
      scenario_origin_type,

      'coverage_policy',
      scenario_coverage_policy

    )

  );


  return v_id;

end;

$function$;


-- ============================================================
-- 03. UPSERT EVOLUTION SCENARIO CYCLE
-- ============================================================

create or replace function
  public.upsert_skpe_evolution_scenario_cycle(

    target_scenario_id uuid,
    target_cycle_id uuid,

    cycle_sequence_number integer,

    cycle_title text,
    cycle_description text,

    cycle_period_start date,
    cycle_period_end date,

    cycle_strategic_intent text,
    cycle_expected_outcome text,

    cycle_target_maturity jsonb,
    cycle_assumptions jsonb,
    cycle_entry_criteria jsonb,
    cycle_exit_criteria jsonb,
    cycle_strategic_focus jsonb,

    cycle_rationale text,

    change_reason text
  )
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$

declare

  v_scenario
    public.skpe_evolution_scenarios%rowtype;

  v_cycle
    public.skpe_evolution_scenario_cycles%rowtype;

  v_id uuid;

begin

  perform public.skpe_assert_reason(
    change_reason
  );


  select *
  into v_scenario

  from public.skpe_evolution_scenarios

  where id = target_scenario_id

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
      'Acesso negado à gestão dos Ciclos de Evolução.'
      using errcode = '42501';

  end if;


  if v_scenario.status not in (
    'draft',
    'adjusted'
  ) then

    raise exception
      'Ciclos só podem ser editados enquanto o cenário estiver em rascunho ou ajuste.'
      using errcode = '55000';

  end if;


  if cycle_sequence_number is null
     or cycle_sequence_number <= 0 then

    raise exception
      'A sequência do Ciclo de Evolução deve ser positiva.'
      using errcode = '22023';

  end if;


  if nullif(
    trim(cycle_title),
    ''
  ) is null then

    raise exception
      'Informe o título do Ciclo de Evolução.'
      using errcode = '22023';

  end if;


  if cycle_period_start is null
     or cycle_period_end is null
     or cycle_period_end <
        cycle_period_start then

    raise exception
      'Informe um período estratégico válido para o Ciclo de Evolução.'
      using errcode = '22023';

  end if;


  if coalesce(
    jsonb_typeof(cycle_target_maturity),
    'null'
  ) <> 'object' then

    raise exception
      'target_maturity deve ser objeto JSON.'
      using errcode = '22023';

  end if;


  if coalesce(
       jsonb_typeof(cycle_assumptions),
       'null'
     ) <> 'array'

     or coalesce(
       jsonb_typeof(cycle_entry_criteria),
       'null'
     ) <> 'array'

     or coalesce(
       jsonb_typeof(cycle_exit_criteria),
       'null'
     ) <> 'array'

     or coalesce(
       jsonb_typeof(cycle_strategic_focus),
       'null'
     ) <> 'array' then

    raise exception
      'Premissas, critérios e foco estratégico devem ser arrays JSON.'
      using errcode = '22023';

  end if;


  if target_cycle_id is null then


    insert into
      public.skpe_evolution_scenario_cycles (

        organization_id,
        project_id,

        strategic_horizon_id,
        scenario_id,

        sequence_number,

        title,
        description,

        period_start,
        period_end,

        strategic_intent,
        expected_outcome,

        target_maturity,
        assumptions,

        entry_criteria,
        exit_criteria,

        strategic_focus,

        rationale,

        metadata,

        created_by,
        updated_by
      )

    values (

      v_scenario.organization_id,
      v_scenario.project_id,

      v_scenario.strategic_horizon_id,
      v_scenario.id,

      cycle_sequence_number,

      trim(cycle_title),

      nullif(
        trim(cycle_description),
        ''
      ),

      cycle_period_start,
      cycle_period_end,

      nullif(
        trim(cycle_strategic_intent),
        ''
      ),

      nullif(
        trim(cycle_expected_outcome),
        ''
      ),

      cycle_target_maturity,
      cycle_assumptions,

      cycle_entry_criteria,
      cycle_exit_criteria,

      cycle_strategic_focus,

      nullif(
        trim(cycle_rationale),
        ''
      ),

      '{}'::jsonb,

      auth.uid(),
      auth.uid()
    )

    returning id
    into v_id;


  else


    select *
    into v_cycle

    from public.skpe_evolution_scenario_cycles

    where id =
          target_cycle_id

    for update;


    if v_cycle.id is null
       or v_cycle.scenario_id <>
          v_scenario.id then

      raise exception
        'Ciclo de Evolução não encontrado neste cenário.'
        using errcode = '22023';

    end if;


    update
      public.skpe_evolution_scenario_cycles

    set

      sequence_number =
        cycle_sequence_number,

      title =
        trim(cycle_title),

      description =
        nullif(
          trim(cycle_description),
          ''
        ),

      period_start =
        cycle_period_start,

      period_end =
        cycle_period_end,

      strategic_intent =
        nullif(
          trim(cycle_strategic_intent),
          ''
        ),

      expected_outcome =
        nullif(
          trim(cycle_expected_outcome),
          ''
        ),

      target_maturity =
        cycle_target_maturity,

      assumptions =
        cycle_assumptions,

      entry_criteria =
        cycle_entry_criteria,

      exit_criteria =
        cycle_exit_criteria,

      strategic_focus =
        cycle_strategic_focus,

      rationale =
        nullif(
          trim(cycle_rationale),
          ''
        ),

      updated_at =
        timezone('utc', now()),

      updated_by =
        auth.uid()

    where id =
          target_cycle_id

    returning id
    into v_id;


  end if;


  insert into
    public.skpe_journey_audit (

      organization_id,
      project_id,

      actor_user_id,

      action_code,
      reason,

      new_data
    )

  values (

    v_scenario.organization_id,
    v_scenario.project_id,

    auth.uid(),

    'evolution_scenario_cycle_upserted',
    change_reason,

    jsonb_build_object(

      'scenario_id',
      v_scenario.id,

      'cycle_id',
      v_id,

      'sequence_number',
      cycle_sequence_number,

      'period_start',
      cycle_period_start,

      'period_end',
      cycle_period_end

    )

  );


  return v_id;

end;

$function$;


-- ============================================================
-- 04. TRANSITION EVOLUTION SCENARIO
-- ============================================================

create or replace function
  public.transition_skpe_evolution_scenario(

    target_scenario_id uuid,

    transition_action text,

    change_reason text
  )
returns text
language plpgsql
security definer
set search_path = ''
as $function$

declare

  v_scenario
    public.skpe_evolution_scenarios%rowtype;

  v_new_status text;

  v_readiness jsonb;

begin

  perform public.skpe_assert_reason(
    change_reason
  );


  select *
  into v_scenario

  from public.skpe_evolution_scenarios

  where id =
        target_scenario_id

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
      'Acesso negado à gestão do Cenário de Evolução.'
      using errcode = '42501';

  end if;


  perform pg_advisory_xact_lock(
    hashtextextended(
      v_scenario.id::text,
      0
    )
  );


  if transition_action =
     'submit' then


    v_readiness :=
      public.skpe_get_evolution_scenario_readiness(
        v_scenario.id
      );


    if coalesce(
      (
        v_readiness
        ->> 'ready_to_submit'
      )::boolean,
      false
    ) = false then


      if coalesce(
        (
          v_readiness
          ->> 'cycle_count'
        )::integer,
        0
      ) = 0 then

        raise exception
          'Inclua pelo menos um Ciclo de Evolução antes da submissão.'
          using errcode = '55000';

      end if;


      raise exception
        'A política require_continuous exige cobertura integral e contínua do Horizonte Estratégico.'
        using errcode = '55000';


    end if;


  end if;


  v_new_status :=
    case transition_action

      when 'submit'
        then case
          when v_scenario.status in (
            'draft',
            'adjusted'
          )
          then 'proposed'
        end

      when 'start_review'
        then case
          when v_scenario.status =
               'proposed'
          then 'under_review'
        end

      when 'defer'
        then case
          when v_scenario.status in (
            'draft',
            'proposed',
            'under_review',
            'adjusted'
          )
          then 'deferred'
        end

      when 'reject'
        then case
          when v_scenario.status in (
            'draft',
            'proposed',
            'under_review',
            'adjusted',
            'deferred'
          )
          then 'rejected'
        end

      when 'reopen'
        then case
          when v_scenario.status in (
            'deferred',
            'rejected'
          )
          then 'draft'
        end

      else null

    end;


  if v_new_status is null then

    raise exception
      'Transição inválida para o estado atual do Cenário de Evolução.'
      using errcode = '55000';

  end if;


  update
    public.skpe_evolution_scenarios

  set

    status =
      v_new_status,

    updated_at =
      timezone('utc', now()),

    updated_by =
      auth.uid()

  where id =
        v_scenario.id;


  insert into
    public.skpe_journey_audit (

      organization_id,
      project_id,

      actor_user_id,

      action_code,
      reason,

      new_data
    )

  values (

    v_scenario.organization_id,
    v_scenario.project_id,

    auth.uid(),

    'evolution_scenario_transitioned',
    change_reason,

    jsonb_build_object(

      'scenario_id',
      v_scenario.id,

      'previous_status',
      v_scenario.status,

      'new_status',
      v_new_status,

      'action',
      transition_action,

      'readiness',
      v_readiness

    )

  );


  return v_new_status;

end;

$function$;


-- ============================================================
-- 05. DECIDE EVOLUTION SCENARIO
-- ============================================================
--
-- A decisão é registrada no PEM-02.GATE.
--
-- approved / approved_with_reservations:
--   -> aprova o cenário;
--   -> supersede plano anterior corrente;
--   -> cria Evolution Plan;
--   -> materializa Evolution Cycles.
--
-- returned_for_adjustment:
--   -> volta o cenário para adjusted;
--   -> não materializa plano/ciclos.
-- ============================================================

create or replace function
  public.decide_skpe_evolution_scenario(

    target_scenario_id uuid,

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

  v_scenario
    public.skpe_evolution_scenarios%rowtype;

  v_horizon
    public.skpe_strategic_horizons%rowtype;

  v_project
    public.skpe_projects%rowtype;

  v_gate
    public.skpe_journey_items%rowtype;

  v_pem02
    public.skpe_journey_items%rowtype;

  v_readiness jsonb;

  v_prev_decision uuid;

  v_next_sequence integer;

  v_decision uuid;

  v_prev_plan
    public.skpe_evolution_plans%rowtype;

  v_plan_id uuid;

  v_plan_version integer;

  v_materialized_cycles integer;

begin

  perform public.skpe_assert_reason(
    change_reason
  );


  if nullif(
    trim(decision_reason),
    ''
  ) is null then

    raise exception
      'Informe a justificativa da decisão institucional.'
      using errcode = '22023';

  end if;


  if decision_outcome not in (

    'approved',
    'approved_with_reservations',
    'returned_for_adjustment'

  ) then

    raise exception
      'Resultado de decisão inválido para o Cenário de Evolução.'
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


  select *
  into v_scenario

  from public.skpe_evolution_scenarios

  where id =
        target_scenario_id

  for update;


  if v_scenario.id is null then

    raise exception
      'Cenário de Evolução não encontrado.'
      using errcode = '22023';

  end if;


  if v_scenario.status not in (
    'proposed',
    'under_review'
  ) then

    raise exception
      'O cenário precisa estar submetido ou em revisão para decisão institucional.'
      using errcode = '55000';

  end if;


  if not public.can_ratify_skpe_governance(
    v_scenario.organization_id
  ) then

    raise exception
      'Acesso negado: o usuário não possui permissão para deliberar o Cenário de Evolução.'
      using errcode = '42501';

  end if;


  perform pg_advisory_xact_lock(
    hashtextextended(
      v_scenario.id::text,
      0
    )
  );


  select *
  into v_horizon

  from public.skpe_strategic_horizons

  where id =
        v_scenario.strategic_horizon_id

    and project_id =
        v_scenario.project_id

  for update;


  if v_horizon.id is null
     or not v_horizon.is_current then

    raise exception
      'A decisão exige o Horizonte Estratégico corrente do projeto.'
      using errcode = '55000';

  end if;


  select *
  into v_project

  from public.skpe_projects

  where id =
        v_scenario.project_id

    and archived_at is null

  for update;


  if v_project.id is null then

    raise exception
      'Projeto SK-PE não encontrado.'
      using errcode = '22023';

  end if;


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


  if v_gate.id is null
     or v_pem02.id is null then

    raise exception
      'Estrutura PEM-02/PEM-02.GATE não localizada no projeto.'
      using errcode = '55000';

  end if;


  if not (

    (
      v_pem02.status =
        'completed'

      and v_pem02.progress =
          100
    )

    or v_gate.status in (
      'in_progress',
      'completed'
    )

  ) then

    raise exception
      'A trajetória de evolução só pode ser ratificada no fechamento da Formulação Estratégica (PEM-02).'
      using errcode = '55000';

  end if;


  v_readiness :=
    public.skpe_get_evolution_scenario_readiness(
      v_scenario.id
    );


  if coalesce(
    (
      v_readiness
      ->> 'ready_to_submit'
    )::boolean,
    false
  ) = false then

    raise exception
      'O Cenário de Evolução não atende à política de cobertura definida.'
      using errcode = '55000';

  end if;


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
        'evolution_scenario'

  order by
    decision_sequence desc

  limit 1;


  select

    coalesce(
      max(decision_sequence),
      0
    ) + 1

  into
    v_next_sequence

  from public.skpe_gate_decisions

  where project_id =
        v_project.id

    and gate_journey_item_id =
        v_gate.id;


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
      'evolution_scenario',

      'scenario_id',
      v_scenario.id,

      'strategic_horizon_id',
      v_horizon.id,

      'scenario_version',
      v_scenario.version_number
    ),

    v_prev_decision,
    v_next_sequence,

    timezone('utc', now()),
    auth.uid(),

    'native_platform',
    'organization',
    'exact_datetime',

    jsonb_build_object(

      'gate',
      '17-B.4C.4D',

      'journey_gate',
      'PEM-02.GATE'
    )
  )

  returning id
  into v_decision;


  -- ----------------------------------------------------------
  -- RETURNED FOR ADJUSTMENT
  -- ----------------------------------------------------------

  if decision_outcome =
     'returned_for_adjustment' then


    update
      public.skpe_evolution_scenarios

    set

      status =
        'adjusted',

      updated_at =
        timezone('utc', now()),

      updated_by =
        auth.uid()

    where id =
          v_scenario.id;


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

      'evolution_scenario_returned_for_adjustment',
      change_reason,

      jsonb_build_object(

        'scenario_id',
        v_scenario.id,

        'gate_decision_id',
        v_decision,

        'adjustment_requirements',
        adjustment_requirements
      )

    );


    return jsonb_build_object(

      'scenario_id',
      v_scenario.id,

      'gate_decision_id',
      v_decision,

      'decision_outcome',
      decision_outcome,

      'evolution_plan_id',
      null,

      'materialized_cycles',
      0

    );


  end if;


  -- ----------------------------------------------------------
  -- APPROVAL
  -- ----------------------------------------------------------

  update
    public.skpe_evolution_scenarios

  set

    status =
      'approved',

    updated_at =
      timezone('utc', now()),

    updated_by =
      auth.uid()

  where id =
        v_scenario.id;


  select *
  into v_prev_plan

  from public.skpe_evolution_plans

  where strategic_horizon_id =
        v_horizon.id

    and is_current =
        true

  for update;


  if v_prev_plan.id is not null then


    update
      public.skpe_evolution_plans

    set

      is_current =
        false,

      governance_status =
        'superseded',

      superseded_at =
        timezone('utc', now()),

      superseded_by =
        auth.uid(),

      updated_at =
        timezone('utc', now()),

      updated_by =
        auth.uid()

    where id =
          v_prev_plan.id;


  end if;


  select

    coalesce(
      max(version_number),
      0
    ) + 1

  into
    v_plan_version

  from public.skpe_evolution_plans

  where strategic_horizon_id =
        v_horizon.id;


  insert into
    public.skpe_evolution_plans (

      organization_id,
      project_id,

      strategic_horizon_id,

      source_scenario_id,

      version_number,

      governance_status,
      is_current,

      decision_origin_type,

      decision_gate_id,

      source_reference,

      valid_from,
      valid_until,

      supersedes_plan_id,

      approved_at,
      approved_by,

      metadata,

      created_by,
      updated_by
    )

  values (

    v_project.organization_id,
    v_project.id,

    v_horizon.id,

    v_scenario.id,

    v_plan_version,

    'approved',
    true,

    'native_platform',

    v_decision,

    v_scenario.source_reference,

    current_date,
    v_horizon.valid_until,

    v_prev_plan.id,

    timezone('utc', now()),
    auth.uid(),

    jsonb_build_object(

      'gate',
      '17-B.4C.4D',

      'scenario_version',
      v_scenario.version_number,

      'decision_outcome',
      decision_outcome,

      'coverage',
      v_readiness
    ),

    auth.uid(),
    auth.uid()
  )

  returning id
  into v_plan_id;


  insert into
    public.skpe_evolution_cycles (

      organization_id,
      project_id,

      strategic_horizon_id,

      evolution_plan_id,

      source_scenario_cycle_id,

      sequence_number,

      title,
      description,

      period_start,
      period_end,

      strategic_intent,
      expected_outcome,

      target_maturity,
      assumptions,

      entry_criteria,
      exit_criteria,

      strategic_focus,

      metadata,

      created_by,
      updated_by
    )

  select

    c.organization_id,
    c.project_id,

    c.strategic_horizon_id,

    v_plan_id,

    c.id,

    c.sequence_number,

    c.title,
    c.description,

    c.period_start,
    c.period_end,

    c.strategic_intent,
    c.expected_outcome,

    c.target_maturity,
    c.assumptions,

    c.entry_criteria,
    c.exit_criteria,

    c.strategic_focus,

    jsonb_build_object(

      'materialized_from_scenario_id',
      v_scenario.id,

      'materialized_from_scenario_cycle_id',
      c.id
    ),

    auth.uid(),
    auth.uid()

  from
    public.skpe_evolution_scenario_cycles c

  where
    c.scenario_id =
    v_scenario.id

  order by
    c.sequence_number,
    c.period_start,
    c.id;


  get diagnostics
    v_materialized_cycles =
    row_count;


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

    'evolution_scenario_approved',
    change_reason,

    jsonb_build_object(

      'scenario_id',
      v_scenario.id,

      'gate_decision_id',
      v_decision,

      'evolution_plan_id',
      v_plan_id,

      'materialized_cycles',
      v_materialized_cycles,

      'decision_outcome',
      decision_outcome,

      'coverage',
      v_readiness
    )

  );


  return jsonb_build_object(

    'scenario_id',
    v_scenario.id,

    'gate_decision_id',
    v_decision,

    'decision_outcome',
    decision_outcome,

    'evolution_plan_id',
    v_plan_id,

    'materialized_cycles',
    v_materialized_cycles

  );

end;

$function$;


-- ============================================================
-- 06. FUNCTION PRIVILEGES
-- ============================================================
--
-- PUBLIC / anon:
-- sem execução.
--
-- authenticated:
-- somente as quatro operações governadas.
--
-- helper interno:
-- service_role apenas.
-- ============================================================

revoke all
on function
  public.skpe_get_evolution_scenario_readiness(uuid)
from public, anon, authenticated;


revoke all
on function
  public.upsert_skpe_evolution_scenario(
    uuid,
    uuid,
    text,
    text,
    text,
    text,
    text,
    text,
    text
  )
from public, anon;


revoke all
on function
  public.upsert_skpe_evolution_scenario_cycle(
    uuid,
    uuid,
    integer,
    text,
    text,
    date,
    date,
    text,
    text,
    jsonb,
    jsonb,
    jsonb,
    jsonb,
    jsonb,
    text,
    text
  )
from public, anon;


revoke all
on function
  public.transition_skpe_evolution_scenario(
    uuid,
    text,
    text
  )
from public, anon;


revoke all
on function
  public.decide_skpe_evolution_scenario(
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
  public.upsert_skpe_evolution_scenario(
    uuid,
    uuid,
    text,
    text,
    text,
    text,
    text,
    text,
    text
  )
to authenticated, service_role;


grant execute
on function
  public.upsert_skpe_evolution_scenario_cycle(
    uuid,
    uuid,
    integer,
    text,
    text,
    date,
    date,
    text,
    text,
    jsonb,
    jsonb,
    jsonb,
    jsonb,
    jsonb,
    text,
    text
  )
to authenticated, service_role;


grant execute
on function
  public.transition_skpe_evolution_scenario(
    uuid,
    text,
    text
  )
to authenticated, service_role;


grant execute
on function
  public.decide_skpe_evolution_scenario(
    uuid,
    text,
    text,
    text,
    text,
    text
  )
to authenticated, service_role;


grant execute
on function
  public.skpe_get_evolution_scenario_readiness(uuid)
to service_role;


-- ============================================================
-- 07. SEMANTIC DOCUMENTATION
-- ============================================================

comment on function
  public.skpe_get_evolution_scenario_readiness(uuid)
is
  'Helper interno: deriva readiness, lacunas e cobertura do Cenário de Evolução sem persistir verdade duplicada.';


comment on function
  public.upsert_skpe_evolution_scenario(
    uuid,
    uuid,
    text,
    text,
    text,
    text,
    text,
    text,
    text
  )
is
  'Cria ou edita proposta governada de trajetória de evolução vinculada ao Horizonte Estratégico corrente.';


comment on function
  public.upsert_skpe_evolution_scenario_cycle(
    uuid,
    uuid,
    integer,
    text,
    text,
    date,
    date,
    text,
    text,
    jsonb,
    jsonb,
    jsonb,
    jsonb,
    jsonb,
    text,
    text
  )
is
  'Cria ou edita Ciclo de Evolução proposto enquanto o cenário estiver em draft/adjusted.';


comment on function
  public.transition_skpe_evolution_scenario(
    uuid,
    text,
    text
  )
is
  'Transiciona Cenário de Evolução; submit valida readiness e política de cobertura.';


comment on function
  public.decide_skpe_evolution_scenario(
    uuid,
    text,
    text,
    text,
    text,
    text
  )
is
  'Registra decisão institucional no PEM-02.GATE e materializa Evolution Plan + Evolution Cycles quando aprovado.';