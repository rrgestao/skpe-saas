-- Governed temporalization of a proposed Evolution Scenario cycle.
-- SPARKs may propose dates; institutional validation remains separate.

create or replace function public.propose_skpe_evolution_cycle_temporalization(
  target_scenario_id uuid,
  target_cycle_id uuid,
  proposed_period_start date,
  proposed_period_end date,
  proposal_rationale text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_scenario public.skpe_evolution_scenarios%rowtype;
  v_cycle public.skpe_evolution_scenario_cycles%rowtype;
  v_before jsonb;
  v_after jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  if proposed_period_start is null or proposed_period_end is null then
    raise exception using
      errcode='22023',
      message='A proposta de temporalização exige início e fim.';
  end if;

  if proposed_period_end < proposed_period_start then
    raise exception using
      errcode='22023',
      message='O fim proposto do Ciclo não pode ser anterior ao início.';
  end if;

  if nullif(trim(proposal_rationale),'') is null then
    raise exception using
      errcode='22023',
      message='Informe a fundamentação da proposta de temporalização.';
  end if;

  select * into v_scenario
  from public.skpe_evolution_scenarios
  where id=target_scenario_id
  for update;

  if v_scenario.id is null then
    raise exception using
      errcode='22023',
      message='Cenário de Evolução não encontrado.';
  end if;

  if not public.can_manage_skpe_governance(v_scenario.organization_id) then
    raise exception using
      errcode='42501',
      message='Acesso negado à proposta de temporalização dos Ciclos de Evolução.';
  end if;

  if v_scenario.status not in ('draft','proposed','under_review','adjusted') then
    raise exception using
      errcode='55000',
      message='Somente Cenário ainda não aprovado pode receber proposta de temporalização.';
  end if;

  select * into v_cycle
  from public.skpe_evolution_scenario_cycles
  where id=target_cycle_id
    and scenario_id=target_scenario_id
  for update;

  if v_cycle.id is null then
    raise exception using
      errcode='22023',
      message='Ciclo de Evolução não encontrado neste Cenário.';
  end if;

  v_before:=to_jsonb(v_cycle);

  update public.skpe_evolution_scenario_cycles
  set
    period_start=proposed_period_start,
    period_end=proposed_period_end,
    metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
      'temporalization_status','proposed_for_validation',
      'temporalization_origin','sparks_methodological_suggestion',
      'temporalization_rationale',trim(proposal_rationale),
      'temporalization_proposed_at',timezone('utc',now()),
      'temporalization_proposed_by',auth.uid()
    ),
    updated_at=timezone('utc',now()),
    updated_by=auth.uid()
  where id=v_cycle.id
  returning to_jsonb(public.skpe_evolution_scenario_cycles.*)
  into v_after;

  insert into public.skpe_journey_audit(
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    previous_data,
    new_data
  )
  values(
    v_scenario.organization_id,
    v_scenario.project_id,
    auth.uid(),
    'evolution_cycle_temporalization_proposed',
    change_reason,
    v_before,
    v_after
  );

  return jsonb_build_object(
    'scenarioId',v_scenario.id,
    'cycleId',v_cycle.id,
    'scenarioStatus',v_scenario.status,
    'periodStart',proposed_period_start,
    'periodEnd',proposed_period_end,
    'governanceStatus','proposed_for_validation',
    'institutionalApprovalCreated',false
  );
end;
$function$;

revoke all on function public.propose_skpe_evolution_cycle_temporalization(uuid,uuid,date,date,text,text)
from public,anon;

grant execute on function public.propose_skpe_evolution_cycle_temporalization(uuid,uuid,date,date,text,text)
to authenticated,service_role;

comment on function public.propose_skpe_evolution_cycle_temporalization(uuid,uuid,date,date,text,text) is
'Records SPARKs suggested dates for a non-approved Evolution Scenario cycle. This is a proposal for organizational validation and does not create institutional approval.';
