-- Evolution Scenario: allow conceptual cycles before temporalization.
-- Dates are optional while the Scenario is a proposal, but mandatory before ratification/materialization as a Plan.

alter table public.skpe_evolution_scenario_cycles
  alter column period_start drop not null,
  alter column period_end drop not null;

alter table public.skpe_evolution_scenario_cycles
  drop constraint if exists skpe_evolution_scenario_cycles_dates_check;

alter table public.skpe_evolution_scenario_cycles
  add constraint skpe_evolution_scenario_cycles_dates_check
  check (
    (period_start is null and period_end is null)
    or (
      period_start is not null
      and period_end is not null
      and period_end >= period_start
    )
  );

create or replace function public.upsert_skpe_evolution_scenario_cycle(
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
set search_path=''
as $function$
declare
  v_scenario public.skpe_evolution_scenarios%rowtype;
  v_cycle public.skpe_evolution_scenario_cycles%rowtype;
  v_id uuid;
begin
  perform public.skpe_assert_reason(change_reason);

  select * into v_scenario
  from public.skpe_evolution_scenarios
  where id=target_scenario_id
  for update;

  if v_scenario.id is null then
    raise exception using errcode='22023', message='Cenário de Evolução não encontrado.';
  end if;

  if not public.can_manage_skpe_governance(v_scenario.organization_id) then
    raise exception using errcode='42501', message='Acesso negado à gestão dos Ciclos de Evolução.';
  end if;

  if v_scenario.status not in ('draft','adjusted') then
    raise exception using errcode='55000',
      message='Ciclos só podem ser editados enquanto o cenário estiver em rascunho ou ajuste.';
  end if;

  if cycle_sequence_number is null or cycle_sequence_number<=0 then
    raise exception using errcode='22023', message='A sequência do Ciclo de Evolução deve ser positiva.';
  end if;

  if nullif(trim(cycle_title),'') is null then
    raise exception using errcode='22023', message='Informe o título do Ciclo de Evolução.';
  end if;

  if (cycle_period_start is null) <> (cycle_period_end is null) then
    raise exception using errcode='22023',
      message='Informe início e fim do período juntos, ou deixe ambos em aberto enquanto o Ciclo estiver conceitual.';
  end if;

  if cycle_period_start is not null and cycle_period_end<cycle_period_start then
    raise exception using errcode='22023', message='Informe um período estratégico válido para o Ciclo de Evolução.';
  end if;

  if coalesce(jsonb_typeof(cycle_target_maturity),'null')<>'object' then
    raise exception using errcode='22023', message='target_maturity deve ser objeto JSON.';
  end if;

  if coalesce(jsonb_typeof(cycle_assumptions),'null')<>'array'
     or coalesce(jsonb_typeof(cycle_entry_criteria),'null')<>'array'
     or coalesce(jsonb_typeof(cycle_exit_criteria),'null')<>'array'
     or coalesce(jsonb_typeof(cycle_strategic_focus),'null')<>'array' then
    raise exception using errcode='22023',
      message='Premissas, critérios e foco estratégico devem ser arrays JSON.';
  end if;

  if target_cycle_id is null then
    insert into public.skpe_evolution_scenario_cycles(
      organization_id,project_id,strategic_horizon_id,scenario_id,
      sequence_number,title,description,period_start,period_end,
      strategic_intent,expected_outcome,target_maturity,assumptions,
      entry_criteria,exit_criteria,strategic_focus,rationale,metadata,
      created_by,updated_by
    )
    values(
      v_scenario.organization_id,v_scenario.project_id,v_scenario.strategic_horizon_id,v_scenario.id,
      cycle_sequence_number,trim(cycle_title),nullif(trim(cycle_description),''),
      cycle_period_start,cycle_period_end,
      nullif(trim(cycle_strategic_intent),''),nullif(trim(cycle_expected_outcome),''),
      cycle_target_maturity,cycle_assumptions,cycle_entry_criteria,cycle_exit_criteria,
      cycle_strategic_focus,nullif(trim(cycle_rationale),''),
      jsonb_build_object(
        'temporalization_status',
        case when cycle_period_start is null then 'pending' else 'defined' end
      ),
      auth.uid(),auth.uid()
    )
    returning id into v_id;
  else
    select * into v_cycle
    from public.skpe_evolution_scenario_cycles
    where id=target_cycle_id
    for update;

    if v_cycle.id is null or v_cycle.scenario_id<>v_scenario.id then
      raise exception using errcode='22023',
        message='Ciclo de Evolução não encontrado neste cenário.';
    end if;

    update public.skpe_evolution_scenario_cycles
    set sequence_number=cycle_sequence_number,
        title=trim(cycle_title),
        description=nullif(trim(cycle_description),''),
        period_start=cycle_period_start,
        period_end=cycle_period_end,
        strategic_intent=nullif(trim(cycle_strategic_intent),''),
        expected_outcome=nullif(trim(cycle_expected_outcome),''),
        target_maturity=cycle_target_maturity,
        assumptions=cycle_assumptions,
        entry_criteria=cycle_entry_criteria,
        exit_criteria=cycle_exit_criteria,
        strategic_focus=cycle_strategic_focus,
        rationale=nullif(trim(cycle_rationale),''),
        metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
          'temporalization_status',
          case when cycle_period_start is null then 'pending' else 'defined' end
        ),
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=target_cycle_id
    returning id into v_id;
  end if;

  insert into public.skpe_journey_audit(
    organization_id,project_id,actor_user_id,action_code,reason,new_data
  )
  values(
    v_scenario.organization_id,v_scenario.project_id,auth.uid(),
    'evolution_scenario_cycle_upserted',change_reason,
    jsonb_build_object(
      'scenario_id',v_scenario.id,
      'cycle_id',v_id,
      'sequence_number',cycle_sequence_number,
      'period_start',cycle_period_start,
      'period_end',cycle_period_end,
      'temporalization_status',case when cycle_period_start is null then 'pending' else 'defined' end
    )
  );

  return v_id;
end;
$function$;

create or replace function public.skpe_get_evolution_scenario_readiness(
  target_scenario_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  v_scenario public.skpe_evolution_scenarios%rowtype;
  v_horizon public.skpe_strategic_horizons%rowtype;
  v_cycle_count integer:=0;
  v_dated_count integer:=0;
  v_undated_count integer:=0;
  v_first_start date;
  v_last_end date;
  v_gap_count integer:=0;
  v_horizon_start date;
  v_horizon_end date;
  v_covers_horizon boolean:=false;
  v_is_continuous boolean:=false;
begin
  select * into v_scenario
  from public.skpe_evolution_scenarios
  where id=target_scenario_id;

  if v_scenario.id is null then
    raise exception using errcode='22023', message='Cenário de Evolução não encontrado.';
  end if;

  select * into v_horizon
  from public.skpe_strategic_horizons
  where id=v_scenario.strategic_horizon_id;

  if v_horizon.id is null then
    raise exception using errcode='55000', message='Horizonte Estratégico do cenário não encontrado.';
  end if;

  v_horizon_start:=coalesce(v_horizon.valid_from,make_date(v_horizon.horizon_start_year,1,1));
  v_horizon_end:=coalesce(v_horizon.valid_until,make_date(v_horizon.horizon_end_year,12,31));

  select
    count(*)::integer,
    count(*) filter (where period_start is not null and period_end is not null)::integer,
    count(*) filter (where period_start is null or period_end is null)::integer,
    min(period_start),
    max(period_end)
  into v_cycle_count,v_dated_count,v_undated_count,v_first_start,v_last_end
  from public.skpe_evolution_scenario_cycles
  where scenario_id=target_scenario_id;

  if v_dated_count>0 then
    select count(*)::integer into v_gap_count
    from (
      select period_end,
             lead(period_start) over(order by period_start,sequence_number,id) as next_start
      from public.skpe_evolution_scenario_cycles
      where scenario_id=target_scenario_id
        and period_start is not null
        and period_end is not null
    ) q
    where q.next_start is not null
      and q.next_start>q.period_end+1;
  end if;

  v_covers_horizon :=
    v_cycle_count>0
    and v_undated_count=0
    and v_first_start=v_horizon_start
    and v_last_end=v_horizon_end;

  v_is_continuous :=
    v_cycle_count>0
    and v_undated_count=0
    and v_gap_count=0;

  return jsonb_build_object(
    'scenario_id',v_scenario.id,
    'strategic_horizon_id',v_horizon.id,
    'coverage_policy',v_scenario.coverage_policy,
    'cycle_count',v_cycle_count,
    'dated_cycle_count',v_dated_count,
    'undated_cycle_count',v_undated_count,
    'horizon_start',v_horizon_start,
    'horizon_end',v_horizon_end,
    'first_cycle_start',v_first_start,
    'last_cycle_end',v_last_end,
    'gap_count',v_gap_count,
    'has_gaps',v_gap_count>0,
    'is_continuous',v_is_continuous,
    'covers_horizon',v_covers_horizon,
    'structurally_ready',v_cycle_count>0,
    'temporalization_complete',v_cycle_count>0 and v_undated_count=0,
    'ready_to_submit',v_cycle_count>0,
    'ready_to_ratify',
      v_cycle_count>0
      and v_undated_count=0
      and (
        v_scenario.coverage_policy='allow_gaps'
        or (v_covers_horizon and v_is_continuous)
      ),
    'methodology_rules',jsonb_build_object(
      'conceptualCyclesMayPrecedeDates',true,
      'datesRequiredBeforeRatification',true,
      'planMaterializationRequiresTemporalizedCycles',true
    )
  );
end;
$function$;

alter function public.decide_skpe_evolution_scenario(uuid,text,text,text,text,text)
  rename to decide_skpe_evolution_scenario_pre_temporalization_guard_20261005;

create or replace function public.decide_skpe_evolution_scenario(
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
set search_path=''
as $function$
declare
  v_readiness jsonb;
begin
  if decision_outcome in ('approved','approved_with_reservations') then
    v_readiness:=public.skpe_get_evolution_scenario_readiness(target_scenario_id);

    if not coalesce((v_readiness->>'ready_to_ratify')::boolean,false) then
      raise exception using
        errcode='55000',
        message='O Cenário de Evolução ainda não pode ser ratificado: os Ciclos precisam estar temporalizados de forma compatível com a política de cobertura.',
        detail=v_readiness::text;
    end if;
  end if;

  return public.decide_skpe_evolution_scenario_pre_temporalization_guard_20261005(
    target_scenario_id,
    decision_outcome,
    decision_reason,
    reservations,
    adjustment_requirements,
    change_reason
  );
end;
$function$;

revoke all on function public.upsert_skpe_evolution_scenario_cycle(uuid,uuid,integer,text,text,date,date,text,text,jsonb,jsonb,jsonb,jsonb,jsonb,text,text)
from public,anon;
grant execute on function public.upsert_skpe_evolution_scenario_cycle(uuid,uuid,integer,text,text,date,date,text,text,jsonb,jsonb,jsonb,jsonb,jsonb,text,text)
to authenticated,service_role;

revoke all on function public.skpe_get_evolution_scenario_readiness(uuid)
from public,anon;
grant execute on function public.skpe_get_evolution_scenario_readiness(uuid)
to authenticated,service_role;

revoke all on function public.decide_skpe_evolution_scenario(uuid,text,text,text,text,text)
from public,anon;
grant execute on function public.decide_skpe_evolution_scenario(uuid,text,text,text,text,text)
to authenticated,service_role;

comment on function public.skpe_get_evolution_scenario_readiness(uuid) is
'Evolution Scenario readiness separates conceptual structure from temporalization. Conceptual cycles may exist without dates, but Gate ratification requires dates.';
