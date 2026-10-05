-- PEM-02.GATE integrated ratification lifecycle.
-- The Gate ratifies the Formulação Estratégica and institutionalizes the Plano de Evolução.
-- It no longer requires both to be already approved before the Gate decision.

create or replace function public.get_skpe_pem02_formulation_ratification_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  pem02_row public.skpe_journey_items%rowtype;
  map_package public.skpe_strategic_map_packages%rowtype;
  official_version public.skpe_strategic_map_versions%rowtype;
  issues jsonb:='[]'::jsonb;
  blocking integer:=0;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023', message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501', message='Acesso negado à prontidão da Formulação no PEM-02.GATE.';
  end if;

  select * into pem02_row
  from public.skpe_journey_items
  where project_id=formulation_row.project_id
    and code='PEM-02'
    and item_type='macrophase'
  limit 1;

  select * into map_package
  from public.skpe_strategic_map_packages
  where formulation_id=formulation_row.id;

  if map_package.id is not null then
    select * into official_version
    from public.skpe_strategic_map_versions
    where formulation_id=formulation_row.id
      and package_id=map_package.id
      and source_validated_at=map_package.validated_at
    order by version_number desc
    limit 1;
  end if;

  if pem02_row.id is null
     or pem02_row.status<>'completed'
     or pem02_row.progress<>100 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM02_NOT_COMPLETED',
      'severity','blocking',
      'message','A Macrofase PEM-02 precisa estar concluída antes da ratificação da Formulação.'
    ));
    blocking:=blocking+1;
  end if;

  if map_package.id is null or map_package.status<>'validated' then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','STRATEGIC_MAP_NOT_VALIDATED',
      'severity','blocking',
      'message','O Mapa Estratégico precisa estar validado no escopo institucional aprovado.'
    ));
    blocking:=blocking+1;
  end if;

  if official_version.id is null then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','STRATEGIC_MAP_OFFICIAL_VERSION_MISSING',
      'severity','blocking',
      'message','A versão oficial imutável do Mapa Estratégico precisa existir antes da ratificação.'
    ));
    blocking:=blocking+1;
  end if;

  return jsonb_build_object(
    'formulationId',formulation_row.id,
    'formulationStatus',formulation_row.status,
    'strategicMapPackageId',map_package.id,
    'strategicMapVersionId',official_version.id,
    'readyForRatification',blocking=0,
    'blockingIssueCount',blocking,
    'issues',issues,
    'deferredToPem03',jsonb_build_array(
      'KPIs dos Objetivos Estratégicos',
      'Metas de longo prazo',
      'OKRs e Resultados-Chave',
      'Iniciativas',
      'responsáveis operacionais do desdobramento'
    ),
    'methodologyRules',jsonb_build_object(
      'laterStageContentDoesNotBlockPem02Gate',true,
      'gateRatifiesFormulation',true,
      'approvedMapIsTheCanonicalContentBoundary',true
    )
  );
end;
$function$;

create or replace function public.get_skpe_pem02_gate_readiness(
  target_project_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  v_project public.skpe_projects%rowtype;
  v_gate public.skpe_journey_items%rowtype;
  v_pem02 public.skpe_journey_items%rowtype;
  v_horizon public.skpe_strategic_horizons%rowtype;
  v_formulation public.skpe_strategic_formulations%rowtype;
  v_scenario public.skpe_evolution_scenarios%rowtype;
  v_plan public.skpe_evolution_plans%rowtype;
  v_formulation_readiness jsonb;
  v_scenario_readiness jsonb;
  v_issues jsonb:='[]'::jsonb;
  v_blocking integer:=0;
begin
  select * into v_project
  from public.skpe_projects
  where id=target_project_id and archived_at is null;

  if v_project.id is null then
    raise exception using errcode='22023', message='Projeto SK-PE não encontrado.';
  end if;

  if not public.can_view_skpe_journey(v_project.organization_id) then
    raise exception using errcode='42501', message='Acesso negado à leitura do Gate PEM-02.';
  end if;

  select * into v_gate
  from public.skpe_journey_items
  where project_id=v_project.id and code='PEM-02.GATE' and item_type='gate'
  limit 1;

  select * into v_pem02
  from public.skpe_journey_items
  where project_id=v_project.id and code='PEM-02' and item_type='macrophase'
  limit 1;

  select * into v_horizon
  from public.skpe_strategic_horizons
  where project_id=v_project.id and is_current=true
  limit 1;

  select * into v_formulation
  from public.skpe_strategic_formulations
  where project_id=v_project.id
    and archived_at is null
    and status not in ('archived','superseded')
  order by version_number desc
  limit 1;

  if v_horizon.id is not null then
    select * into v_scenario
    from public.skpe_evolution_scenarios
    where strategic_horizon_id=v_horizon.id
      and status not in ('rejected','superseded')
    order by
      case status
        when 'approved' then 1
        when 'under_review' then 2
        when 'proposed' then 3
        when 'adjusted' then 4
        when 'draft' then 5
        when 'deferred' then 6
        else 9
      end,
      version_number desc
    limit 1;

    select * into v_plan
    from public.skpe_evolution_plans
    where strategic_horizon_id=v_horizon.id
      and is_current=true
      and governance_status in ('approved','historical_recognized')
    order by version_number desc
    limit 1;
  end if;

  if v_gate.id is null then
    v_issues:=v_issues || jsonb_build_array(jsonb_build_object(
      'code','PEM02_GATE_MISSING','severity','blocking','message','PEM-02.GATE não localizado.'
    ));
    v_blocking:=v_blocking+1;
  end if;

  if v_pem02.id is null or v_pem02.status<>'completed' or v_pem02.progress<>100 then
    v_issues:=v_issues || jsonb_build_array(jsonb_build_object(
      'code','PEM02_NOT_COMPLETED','severity','blocking',
      'message','A Macrofase PEM-02 deve estar concluída com progresso integral.'
    ));
    v_blocking:=v_blocking+1;
  end if;

  if v_horizon.id is null then
    v_issues:=v_issues || jsonb_build_array(jsonb_build_object(
      'code','CURRENT_HORIZON_MISSING','severity','blocking',
      'message','Horizonte Estratégico corrente não localizado.'
    ));
    v_blocking:=v_blocking+1;
  end if;

  if v_formulation.id is null then
    v_issues:=v_issues || jsonb_build_array(jsonb_build_object(
      'code','FORMULATION_CANDIDATE_MISSING','severity','blocking',
      'message','Formulação Estratégica candidata à ratificação não localizada.'
    ));
    v_blocking:=v_blocking+1;
    v_formulation_readiness:=jsonb_build_object(
      'readyForRatification',false,
      'blockingIssueCount',1,
      'issues',jsonb_build_array(jsonb_build_object(
        'code','FORMULATION_CANDIDATE_MISSING','severity','blocking'
      ))
    );
  else
    v_formulation_readiness:=
      public.get_skpe_pem02_formulation_ratification_readiness(v_formulation.id);

    if not coalesce((v_formulation_readiness->>'readyForRatification')::boolean,false) then
      v_issues:=v_issues || coalesce(v_formulation_readiness->'issues','[]'::jsonb);
      v_blocking:=v_blocking + coalesce(
        (v_formulation_readiness->>'blockingIssueCount')::integer,0
      );
    end if;
  end if;

  if v_scenario.id is null then
    v_issues:=v_issues || jsonb_build_array(jsonb_build_object(
      'code','EVOLUTION_SCENARIO_MISSING','severity','blocking',
      'message','Cenário de Evolução ainda não foi estruturado para o Horizonte Estratégico corrente.'
    ));
    v_blocking:=v_blocking+1;
    v_scenario_readiness:=jsonb_build_object(
      'ready_to_ratify',false,
      'structurally_ready',false,
      'temporalization_complete',false
    );
  else
    v_scenario_readiness:=public.skpe_get_evolution_scenario_readiness(v_scenario.id);

    if v_scenario.status='approved' then
      if v_plan.id is null then
        v_issues:=v_issues || jsonb_build_array(jsonb_build_object(
          'code','EVOLUTION_PLAN_MATERIALIZATION_MISSING','severity','blocking',
          'message','O Cenário está aprovado, mas o Plano de Evolução corrente não foi materializado.'
        ));
        v_blocking:=v_blocking+1;
      end if;
    elsif not coalesce((v_scenario_readiness->>'ready_to_ratify')::boolean,false) then
      v_issues:=v_issues || jsonb_build_array(jsonb_build_object(
        'code','EVOLUTION_SCENARIO_TEMPORALIZATION_PENDING','severity','blocking',
        'message','O Cenário de Evolução está estruturado, mas os períodos dos Ciclos precisam ser definidos antes da ratificação do PEM-02.GATE.'
      ));
      v_blocking:=v_blocking+1;
    end if;
  end if;

  return jsonb_build_object(
    'projectId',v_project.id,
    'gateId',v_gate.id,
    'pem02Status',v_pem02.status,
    'pem02Progress',v_pem02.progress,
    'strategicHorizonId',v_horizon.id,
    'candidateFormulationId',v_formulation.id,
    'formulationStatus',v_formulation.status,
    'formulationRatification',v_formulation_readiness,
    'evolutionScenarioId',v_scenario.id,
    'evolutionScenarioStatus',v_scenario.status,
    'evolutionScenarioReadiness',v_scenario_readiness,
    'evolutionPlanId',v_plan.id,
    'planWillBeMaterializedOnApproval',
      v_plan.id is null
      and v_scenario.id is not null
      and v_scenario.status<>'approved'
      and coalesce((v_scenario_readiness->>'ready_to_ratify')::boolean,false),
    'readyForClosure',v_blocking=0,
    'blockingIssueCount',v_blocking,
    'issues',v_issues,
    'methodologyRules',jsonb_build_object(
      'gateRatifiesFormulation',true,
      'gateRatifiesEvolutionScenario',true,
      'gateMaterializesEvolutionPlan',true,
      'planMustNotBePreApproved',true,
      'laterStageContentDoesNotBlock',true
    )
  );
end;
$function$;

alter function public.ratify_skpe_pem02_gate(uuid,text,text,text,text,text)
  rename to ratify_skpe_pem02_gate_pre_integrated_lifecycle_20261005;

create or replace function public.ratify_skpe_pem02_gate(
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
set search_path=''
as $function$
declare
  v_readiness jsonb;
  v_formulation_id uuid;
  v_scenario_id uuid;
  v_formulation public.skpe_strategic_formulations%rowtype;
  v_scenario public.skpe_evolution_scenarios%rowtype;
  v_current_approved public.skpe_strategic_formulations%rowtype;
  v_previous_formulation jsonb;
  v_updated_formulation jsonb;
begin
  if decision_outcome='returned_for_adjustment' then
    return public.ratify_skpe_pem02_gate_pre_integrated_lifecycle_20261005(
      target_project_id,decision_outcome,decision_reason,reservations,
      adjustment_requirements,change_reason
    );
  end if;

  v_readiness:=public.get_skpe_pem02_gate_readiness(target_project_id);

  if not coalesce((v_readiness->>'readyForClosure')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-02.GATE possui pendências bloqueantes.',
      detail=v_readiness::text;
  end if;

  v_formulation_id:=nullif(v_readiness->>'candidateFormulationId','')::uuid;
  v_scenario_id:=nullif(v_readiness->>'evolutionScenarioId','')::uuid;

  select * into v_scenario
  from public.skpe_evolution_scenarios
  where id=v_scenario_id
  for update;

  if v_scenario.id is null then
    raise exception using errcode='55000', message='Cenário de Evolução não localizado para a ratificação.';
  end if;

  if v_scenario.status<>'approved' then
    perform public.decide_skpe_evolution_scenario(
      v_scenario.id,
      decision_outcome,
      decision_reason,
      reservations,
      adjustment_requirements,
      'Ratificação integrada do Cenário/Plano de Evolução no PEM-02.GATE: ' || change_reason
    );
  end if;

  select * into v_formulation
  from public.skpe_strategic_formulations
  where id=v_formulation_id
  for update;

  if v_formulation.id is null then
    raise exception using errcode='55000', message='Formulação Estratégica candidata não localizada.';
  end if;

  if v_formulation.status<>'approved' then
    select * into v_current_approved
    from public.skpe_strategic_formulations
    where project_id=target_project_id
      and status='approved'
      and id<>v_formulation.id
    order by version_number desc
    limit 1
    for update;

    if v_current_approved.id is not null then
      update public.skpe_strategic_formulations
      set status='superseded',
          superseded_at=timezone('utc',now()),
          superseded_by=auth.uid(),
          status_changed_at=timezone('utc',now()),
          status_changed_by=auth.uid(),
          updated_at=timezone('utc',now()),
          updated_by=auth.uid()
      where id=v_current_approved.id;
    end if;

    v_previous_formulation:=to_jsonb(v_formulation);

    update public.skpe_strategic_formulations
    set status='approved',
        approved_at=timezone('utc',now()),
        approved_by=auth.uid(),
        approval_notes=decision_reason,
        status_changed_at=timezone('utc',now()),
        status_changed_by=auth.uid(),
        metadata=coalesce(metadata,'{}'::jsonb) || jsonb_build_object(
          'pem02GateRatification',jsonb_build_object(
            'ratifiedAt',timezone('utc',now()),
            'ratifiedBy',auth.uid(),
            'decisionOutcome',decision_outcome,
            'integratedEvolutionScenarioId',v_scenario.id,
            'laterStageContentDeferred',true
          )
        ),
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=v_formulation.id
    returning to_jsonb(public.skpe_strategic_formulations.*)
    into v_updated_formulation;

    perform public.skpe_record_operational_audit(
      v_formulation.organization_id,
      v_formulation.project_id,
      'strategic_formulation',
      v_formulation.id,
      'formulation_approved_by_pem02_gate',
      change_reason,
      v_previous_formulation,
      v_updated_formulation
    );
  end if;

  return public.ratify_skpe_pem02_gate_pre_integrated_lifecycle_20261005(
    target_project_id,
    decision_outcome,
    decision_reason,
    reservations,
    adjustment_requirements,
    change_reason
  );
end;
$function$;

revoke all on function public.get_skpe_pem02_formulation_ratification_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem02_formulation_ratification_readiness(uuid)
to authenticated,service_role;

revoke all on function public.get_skpe_pem02_gate_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem02_gate_readiness(uuid)
to authenticated,service_role;

revoke all on function public.ratify_skpe_pem02_gate(uuid,text,text,text,text,text)
from public,anon;
grant execute on function public.ratify_skpe_pem02_gate(uuid,text,text,text,text,text)
to authenticated,service_role;

comment on function public.get_skpe_pem02_gate_readiness(uuid) is
'PEM-02.GATE readiness without circular preapproval. The Gate ratifies the Formulação and Evolution Scenario and materializes the Plan.';
comment on function public.ratify_skpe_pem02_gate(uuid,text,text,text,text,text) is
'Integrated PEM-02.GATE ratification: ratifies Evolution Scenario/Plan and Formulação in the same institutional Gate decision flow.';
