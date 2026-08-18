-- SK-PE-CONT-01
-- GATE-17-B.4C.5 — PEM-02 Gate Governance Convergence
--
-- Missão:
--
-- Convergir a governança da Formulação Estratégica,
-- da Trajetória de Evolução e da Jornada no PEM-02.GATE,
-- evitando múltiplas verdades institucionais de fechamento.
--
-- Autoridades canônicas:
--
-- Formulação Estratégica:
--   mantém seu workflow próprio de elaboração,
--   validação e aprovação.
--
-- Evolution Plan:
--   resulta da decisão institucional sobre a trajetória
--   dos Ciclos de Evolução.
--
-- PEM-02.GATE:
--   funciona como decisão agregadora final da Macrofase 2.
--
-- O Gate somente pode ser concluído quando:
--
--   1. PEM-02 estiver concluída;
--   2. existir Horizonte Estratégico corrente;
--   3. existir Formulação Estratégica aprovada;
--   4. existir Plano de Evolução corrente;
--   5. houver decisão institucional específica
--      de fechamento do PEM-02.GATE.
--
-- Nenhuma relação Objetivo <-> Ciclo de Evolução
-- é criada neste Gate.


-- ============================================================
-- 01. PEM-02 GATE READINESS
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

  v_issues jsonb :=
    '[]'::jsonb;

  v_blocking integer :=
    0;

begin

  -- ----------------------------------------------------------
  -- Projeto
  -- ----------------------------------------------------------

  select *
  into v_project

  from public.skpe_projects

  where id = target_project_id
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
  -- Jornada
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
  -- Horizonte Estratégico corrente
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
  -- Formulação Estratégica institucionalmente aprovada
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
  -- Plano de Evolução corrente
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
  -- Issue: Gate inexistente
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


  -- ----------------------------------------------------------
  -- Issue: Macrofase 2 ainda não concluída
  -- ----------------------------------------------------------

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


  -- ----------------------------------------------------------
  -- Issue: Horizonte corrente inexistente
  -- ----------------------------------------------------------

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


  -- ----------------------------------------------------------
  -- Issue: Formulação não aprovada
  -- ----------------------------------------------------------

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


  -- ----------------------------------------------------------
  -- Issue: Plano de Evolução corrente inexistente
  -- ----------------------------------------------------------

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
-- 02. GOVERNED RATIFICATION OF PEM-02.GATE
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
  -- Shared sequence inside this Gate
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
  -- Institutional decision
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
      '17-B.4C.5',

      'journey_gate',
      'PEM-02.GATE'
    )

  )

  returning id
  into v_decision;


  -- ==========================================================
  -- RETURN FOR ADJUSTMENTS
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
      'rejected'

    );


  end if;


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
    v_validation_status

  );

end;

$function$;


-- ============================================================
-- 03. PEM-02.GATE COMPLETION GUARD
-- ============================================================
--
-- Protege contra:
--
-- - conclusão genérica via set_skpe_journey_item_status;
-- - progress != 100 em Gate concluído;
-- - validation_status aprovado sem Gate concluído;
-- - fechamento sem readiness;
-- - fechamento sem decisão institucional;
-- - reabertura/alteração genérica depois de concluído.
-- ============================================================

create or replace function
  public.skpe_guard_pem02_gate_completion()
returns trigger
language plpgsql
set search_path = ''
as $function$

declare

  v_readiness jsonb;

begin

  if new.item_type = 'gate'
     and new.code = 'PEM-02.GATE' then


    -- --------------------------------------------------------
    -- Gate concluído torna-se imutável pelo fluxo genérico.
    -- Revisões futuras devem ocorrer por mecanismo governado.
    -- --------------------------------------------------------

    if old.status = 'completed'

       and (

         new.status
           is distinct from old.status

         or new.validation_status
           is distinct from old.validation_status

         or new.progress
           is distinct from old.progress

       ) then

      raise exception
        'PEM-02.GATE concluído é imutável; alterações exigem revisão governada da Formulação/Planejamento.'
        using errcode = '55000';

    end if;


    -- --------------------------------------------------------
    -- Invariantes para Gate concluído
    -- --------------------------------------------------------

    if new.status = 'completed' then


      if new.progress <> 100 then

        raise exception
          'PEM-02.GATE concluído deve possuir progresso integral.'
          using errcode = '55000';

      end if;


      if new.validation_status not in (

        'approved',
        'approved_with_reservations'

      ) then

        raise exception
          'PEM-02.GATE só pode ser concluído com validação institucional aprovada.'
          using errcode = '55000';

      end if;


      v_readiness :=
        public.get_skpe_pem02_gate_readiness(
          new.project_id
        );


      if not coalesce(
        (
          v_readiness
          ->> 'readyForClosure'
        )::boolean,
        false
      ) then

        raise exception
          'PEM-02.GATE não pode ser concluído com pendências bloqueantes.'
          using
            errcode = '55000',
            detail = v_readiness::text;

      end if;


      if not exists (

        select 1

        from public.skpe_gate_decisions d

        where d.project_id =
              new.project_id

          and d.gate_journey_item_id =
              new.id

          and d.decision_context
              ->> 'decision_kind' =
              'pem02_gate_closure'

          and d.decision_outcome in (
            'approved',
            'approved_with_reservations'
          )

      ) then

        raise exception
          'PEM-02.GATE exige decisão institucional de fechamento.'
          using errcode = '55000';

      end if;


    -- --------------------------------------------------------
    -- Não permitir validation_status aprovado fora de completed
    -- --------------------------------------------------------

    elsif new.validation_status in (

      'approved',
      'approved_with_reservations'

    ) then

      raise exception
        'Validation status aprovado exige PEM-02.GATE concluído.'
        using errcode = '55000';

    end if;


  end if;


  return new;

end;

$function$;


-- ============================================================
-- 04. TRIGGER
-- ============================================================

drop trigger if exists
  skpe_guard_pem02_gate_completion
on public.skpe_journey_items;


create trigger
  skpe_guard_pem02_gate_completion

before update of
  status,
  progress,
  validation_status

on public.skpe_journey_items

for each row

execute function
  public.skpe_guard_pem02_gate_completion();


-- ============================================================
-- 05. PRIVILEGES
-- ============================================================

revoke all
on function
  public.get_skpe_pem02_gate_readiness(uuid)
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


revoke all
on function
  public.skpe_guard_pem02_gate_completion()
from public, anon, authenticated;


grant execute
on function
  public.get_skpe_pem02_gate_readiness(uuid)
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


grant execute
on function
  public.skpe_guard_pem02_gate_completion()
to service_role;


-- ============================================================
-- 06. DOCUMENTATION
-- ============================================================

comment on function
  public.get_skpe_pem02_gate_readiness(uuid)
is
  'Deriva o readiness institucional do PEM-02.GATE a partir da conclusão da Macrofase 2, Horizonte corrente, Formulação aprovada e Plano de Evolução corrente.';


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
  'Registra a decisão institucional agregadora do PEM-02.GATE e conclui o Gate somente quando o contrato canônico de readiness estiver atendido.';


comment on function
  public.skpe_guard_pem02_gate_completion()
is
  'Impede conclusão, aprovação ou reabertura genérica inconsistente do PEM-02.GATE.';