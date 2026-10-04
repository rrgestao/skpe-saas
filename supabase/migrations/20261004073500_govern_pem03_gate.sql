-- Govern PEM-03.GATE with explicit readiness, institutional ratification and fail-closed completion.
-- No business decision is created by this migration.

create or replace function public.get_skpe_pem03_gate_readiness(
  target_project_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  project_row public.skpe_projects%rowtype;
  gate_row public.skpe_journey_items%rowtype;
  macro_row public.skpe_journey_items%rowtype;
  formulation_row public.skpe_strategic_formulations%rowtype;
  okr_readiness jsonb := '{}'::jsonb;
  indicators_readiness jsonb := '{}'::jsonb;
  initiatives_readiness jsonb := '{}'::jsonb;
  governance_readiness jsonb := '{}'::jsonb;
  issues jsonb := '[]'::jsonb;
  blocking_count integer := 0;
begin
  select * into project_row
  from public.skpe_projects
  where id=target_project_id
    and archived_at is null;

  if project_row.id is null then
    raise exception using errcode='22023',message='Projeto SK-PE não encontrado.';
  end if;

  if not public.can_view_skpe_journey(project_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado à leitura do Gate PEM-03.';
  end if;

  select * into gate_row
  from public.skpe_journey_items
  where project_id=project_row.id
    and code='PEM-03.GATE'
    and item_type='gate'
  limit 1;

  select * into macro_row
  from public.skpe_journey_items
  where project_id=project_row.id
    and code='PEM-03'
    and item_type='macrophase'
  limit 1;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where project_id=project_row.id
    and archived_at is null
  order by version_number desc
  limit 1;

  if gate_row.id is null then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM03_GATE_MISSING',
      'severity','blocking',
      'message','PEM-03.GATE não localizado.'
    ));
  end if;

  if macro_row.id is null
     or macro_row.status<>'completed'
     or macro_row.progress<>100 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM03_NOT_COMPLETED',
      'severity','blocking',
      'message','A Macrofase PEM-03 deve estar concluída com progresso integral antes da ratificação.'
    ));
  end if;

  if exists (
    select 1
    from public.skpe_journey_items item
    where item.project_id=project_row.id
      and item.code in ('PEM-03.01','PEM-03.02','PEM-03.03','PEM-03.04')
      and item.status<>'completed'
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM03_STAGES_INCOMPLETE',
      'severity','blocking',
      'message','PEM-03.01, PEM-03.02, PEM-03.03 e PEM-03.04 devem estar concluídas antes do Gate.',
      'affectedCount',(
        select count(*)
        from public.skpe_journey_items item
        where item.project_id=project_row.id
          and item.code in ('PEM-03.01','PEM-03.02','PEM-03.03','PEM-03.04')
          and item.status<>'completed'
      )
    ));
  end if;

  if formulation_row.id is null then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','FORMULATION_MISSING',
      'severity','blocking',
      'message','Formulação Estratégica não localizada para a Macrofase 3.'
    ));
  else
    okr_readiness:=public.get_skpe_okr_deployment_readiness(formulation_row.id);
    indicators_readiness:=public.get_skpe_indicators_readiness(formulation_row.id);
    initiatives_readiness:=public.get_skpe_initiatives_readiness(formulation_row.id,true);
    governance_readiness:=public.get_skpe_monitoring_package_readiness(formulation_row.id,true);

    if not coalesce((okr_readiness->>'readyForValidation')::boolean,false) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0301_READINESS_BLOCKED',
        'severity','blocking',
        'message','O Desdobramento em OKRs ainda possui bloqueadores.'
      ));
    end if;

    if not coalesce((indicators_readiness->>'readyForFormulation')::boolean,false) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0302_READINESS_BLOCKED',
        'severity','blocking',
        'message','Indicadores e Metas ainda possuem bloqueadores ou pacote não validado.'
      ));
    end if;

    if not coalesce((initiatives_readiness->>'readyForFormulation')::boolean,false) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0303_READINESS_BLOCKED',
        'severity','blocking',
        'message','O portfólio de Iniciativas ainda possui bloqueadores ou pacote não validado.'
      ));
    end if;

    if not coalesce((governance_readiness->>'readyForFormulation')::boolean,false) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0304_READINESS_BLOCKED',
        'severity','blocking',
        'message','A Governança da Execução ainda possui bloqueadores ou pacote não validado.'
      ));
    end if;
  end if;

  select count(*)::integer into blocking_count
  from jsonb_array_elements(issues) issue
  where issue->>'severity'='blocking';

  return jsonb_build_object(
    'projectId',project_row.id,
    'gateId',gate_row.id,
    'pem03Status',macro_row.status,
    'pem03Progress',macro_row.progress,
    'formulationId',formulation_row.id,
    'okrReadiness',okr_readiness,
    'indicatorsReadiness',indicators_readiness,
    'initiativesReadiness',initiatives_readiness,
    'governanceReadiness',governance_readiness,
    'readyForClosure',blocking_count=0,
    'blockingIssueCount',blocking_count,
    'issues',issues
  );
end;
$function$;

revoke all on function public.get_skpe_pem03_gate_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem03_gate_readiness(uuid)
to authenticated,service_role;

create or replace function public.ratify_skpe_pem03_gate(
  target_project_id uuid,
  decision_outcome text,
  decision_reason text,
  reservations text default null,
  adjustment_requirements text default null,
  change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  project_row public.skpe_projects%rowtype;
  gate_row public.skpe_journey_items%rowtype;
  formulation_row public.skpe_strategic_formulations%rowtype;
  readiness jsonb;
  previous_decision_id uuid;
  next_sequence integer;
  decision_id uuid;
  target_validation_status text;
begin
  perform public.skpe_assert_reason(change_reason);

  if length(trim(coalesce(decision_reason,'')))<10 then
    raise exception using errcode='22023',message='Informe a justificativa da decisão do PEM-03.GATE com pelo menos 10 caracteres.';
  end if;

  if decision_outcome not in ('approved','approved_with_reservations','returned_for_adjustment') then
    raise exception using errcode='22023',message='Resultado inválido para o PEM-03.GATE.';
  end if;

  if decision_outcome='approved_with_reservations'
     and length(trim(coalesce(reservations,'')))<10 then
    raise exception using errcode='22023',message='Aprovação com ressalvas exige descrição das ressalvas.';
  end if;

  if decision_outcome='returned_for_adjustment'
     and length(trim(coalesce(adjustment_requirements,'')))<10 then
    raise exception using errcode='22023',message='Retorno para ajuste exige requisitos de ajuste.';
  end if;

  select * into project_row
  from public.skpe_projects
  where id=target_project_id
    and archived_at is null
  for update;

  if project_row.id is null then
    raise exception using errcode='22023',message='Projeto SK-PE não encontrado.';
  end if;

  if not public.can_ratify_skpe_governance(project_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado à ratificação do PEM-03.GATE.';
  end if;

  select * into gate_row
  from public.skpe_journey_items
  where project_id=project_row.id
    and code='PEM-03.GATE'
    and item_type='gate'
  for update;

  if gate_row.id is null then
    raise exception using errcode='55000',message='PEM-03.GATE não localizado.';
  end if;

  if gate_row.status='completed' then
    raise exception using errcode='55000',message='PEM-03.GATE já está concluído e não pode ser ratificado novamente.';
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where project_id=project_row.id
    and archived_at is null
  order by version_number desc
  limit 1;

  readiness:=public.get_skpe_pem03_gate_readiness(project_row.id);

  if decision_outcome in ('approved','approved_with_reservations')
     and not coalesce((readiness->>'readyForClosure')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-03.GATE possui pendências bloqueantes.',
      detail=readiness::text;
  end if;

  select id into previous_decision_id
  from public.skpe_gate_decisions
  where project_id=project_row.id
    and gate_journey_item_id=gate_row.id
    and decision_context->>'decision_kind'='pem03_gate_closure'
  order by decision_sequence desc
  limit 1;

  select coalesce(max(decision_sequence),0)+1 into next_sequence
  from public.skpe_gate_decisions
  where project_id=project_row.id
    and gate_journey_item_id=gate_row.id;

  insert into public.skpe_gate_decisions(
    organization_id,
    project_id,
    formulation_id,
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
  values(
    project_row.organization_id,
    project_row.id,
    formulation_row.id,
    gate_row.id,
    decision_outcome,
    trim(decision_reason),
    case when decision_outcome='approved_with_reservations' then trim(reservations) end,
    case when decision_outcome='returned_for_adjustment' then trim(adjustment_requirements) end,
    readiness,
    jsonb_build_object(
      'decision_kind','pem03_gate_closure',
      'project_id',project_row.id
    ),
    previous_decision_id,
    next_sequence,
    timezone('utc',now()),
    auth.uid(),
    'native_platform',
    'organization',
    'exact_datetime',
    jsonb_build_object(
      'journey_gate','PEM-03.GATE',
      'macrophase','PEM-03',
      'canonical_readiness_snapshot',true
    )
  )
  returning id into decision_id;

  if decision_outcome='returned_for_adjustment' then
    update public.skpe_journey_items
    set validation_status='rejected',
        status='in_progress',
        progress=least(progress,99),
        is_current=true,
        actual_start_date=coalesce(actual_start_date,current_date),
        actual_end_date=null,
        updated_by=auth.uid()
    where id=gate_row.id;

    insert into public.skpe_journey_audit(
      organization_id,project_id,journey_item_id,actor_user_id,
      action_code,reason,new_data
    )
    values(
      project_row.organization_id,project_row.id,gate_row.id,auth.uid(),
      'pem03_gate_returned_for_adjustment',
      change_reason,
      jsonb_build_object(
        'gate_decision_id',decision_id,
        'adjustment_requirements',adjustment_requirements,
        'readiness',readiness
      )
    );

    perform public.skpe_recalculate_journey_project_internal(
      project_row.id,change_reason,auth.uid()
    );

    return jsonb_build_object(
      'gateId',gate_row.id,
      'gateDecisionId',decision_id,
      'decisionOutcome',decision_outcome,
      'status','in_progress',
      'validationStatus','rejected'
    );
  end if;

  target_validation_status:=
    case
      when decision_outcome='approved_with_reservations'
        then 'approved_with_reservations'
      else 'approved'
    end;

  update public.skpe_journey_items
  set validation_status=target_validation_status,
      status='completed',
      progress=100,
      is_current=false,
      actual_end_date=coalesce(actual_end_date,current_date),
      updated_by=auth.uid()
  where id=gate_row.id;

  insert into public.skpe_journey_audit(
    organization_id,project_id,journey_item_id,actor_user_id,
    action_code,reason,new_data
  )
  values(
    project_row.organization_id,project_row.id,gate_row.id,auth.uid(),
    'pem03_gate_ratified',
    change_reason,
    jsonb_build_object(
      'gate_decision_id',decision_id,
      'decision_outcome',decision_outcome,
      'validation_status',target_validation_status,
      'readiness',readiness
    )
  );

  perform public.skpe_recalculate_journey_project_internal(
    project_row.id,change_reason,auth.uid()
  );

  return jsonb_build_object(
    'gateId',gate_row.id,
    'gateDecisionId',decision_id,
    'decisionOutcome',decision_outcome,
    'status','completed',
    'validationStatus',target_validation_status
  );
end;
$function$;

revoke all on function public.ratify_skpe_pem03_gate(uuid,text,text,text,text,text)
from public,anon;
grant execute on function public.ratify_skpe_pem03_gate(uuid,text,text,text,text,text)
to authenticated;

create or replace function public.skpe_guard_pem03_gate_completion()
returns trigger
language plpgsql
set search_path=''
as $function$
declare
  readiness jsonb;
begin
  if new.item_type='gate'
     and new.code='PEM-03.GATE' then

    if old.status='completed'
       and (
         new.status is distinct from old.status
         or new.validation_status is distinct from old.validation_status
         or new.progress is distinct from old.progress
       ) then
      raise exception using
        errcode='55000',
        message='PEM-03.GATE concluído é imutável; alterações exigem revisão governada.';
    end if;

    if new.status='completed' then
      if new.progress<>100 then
        raise exception using errcode='55000',message='PEM-03.GATE concluído deve possuir progresso integral.';
      end if;

      if new.validation_status not in ('approved','approved_with_reservations') then
        raise exception using errcode='55000',message='PEM-03.GATE só pode ser concluído com validação institucional aprovada.';
      end if;

      readiness:=public.get_skpe_pem03_gate_readiness(new.project_id);

      if not coalesce((readiness->>'readyForClosure')::boolean,false) then
        raise exception using
          errcode='55000',
          message='PEM-03.GATE não pode ser concluído com pendências bloqueantes.',
          detail=readiness::text;
      end if;

      if not exists (
        select 1
        from public.skpe_gate_decisions decision
        where decision.project_id=new.project_id
          and decision.gate_journey_item_id=new.id
          and decision.decision_context->>'decision_kind'='pem03_gate_closure'
          and decision.decision_outcome in ('approved','approved_with_reservations')
      ) then
        raise exception using errcode='55000',message='PEM-03.GATE exige decisão institucional de fechamento.';
      end if;
    elsif new.validation_status in ('approved','approved_with_reservations') then
      raise exception using errcode='55000',message='Validation status aprovado exige PEM-03.GATE concluído.';
    end if;
  end if;

  return new;
end;
$function$;

drop trigger if exists skpe_pem03_gate_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem03_gate_completion_guard
before update of status,progress,validation_status
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem03_gate_completion();

comment on function public.get_skpe_pem03_gate_readiness(uuid) is
'Canonical readiness for PEM-03.GATE. Aggregates PEM-03.01 to PEM-03.04 readiness and requires the macrophase to be fully completed.';

comment on function public.ratify_skpe_pem03_gate(uuid,text,text,text,text,text) is
'Explicit institutional ratification for PEM-03.GATE. Creates an append-only gate decision and is the only governed path to closure.';

comment on function public.skpe_guard_pem03_gate_completion() is
'Fail-closed invariant guard for PEM-03.GATE.';
