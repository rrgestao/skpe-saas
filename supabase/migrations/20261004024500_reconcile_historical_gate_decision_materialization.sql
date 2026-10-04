-- SK-PE - Historical gate decision materialization for COOTAQUARA legacy decisions.
-- The existing resolver uses PEM-02.GATE as the anchor while the target entity type is gate_decision.
-- This layer accepts that governed anchor, creates an imported historical decision idempotently,
-- preserves date-only precision, and delegates every non-decision family to the prior dispatcher.

create or replace function public.skpe_materialize_import_request_as_historical_gate_decision(
  p_request_id uuid,
  p_materialized_by_actor_type text,
  p_materialized_by_user_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_request public.skpe_import_incorporation_requests%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_incorp_decision public.skpe_import_incorporation_decisions%rowtype;
  v_resolution public.skpe_import_target_resolution_events%rowtype;
  v_gate public.skpe_journey_items%rowtype;
  v_source_code text;
  v_source_date text;
  v_source_topic text;
  v_source_decision text;
  v_source_status text;
  v_source_conditions text;
  v_source_evidence text;
  v_source_responsible text;
  v_source_question text;
  v_decided_at timestamptz;
  v_existing_id uuid;
  v_prev_id uuid;
  v_prev_sequence integer := 0;
  v_gate_decision_id uuid;
  v_bad_items integer := 0;
  v_target_mismatch integer := 0;
begin
  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  if v_request.id is null then
    raise exception using errcode='22023', message='Incorporation Request não encontrado.';
  end if;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null or v_record.entity_code <> 'decision' then
    raise exception using errcode='55000',
      message='Materializador histórico de gate decision exige entity_code = decision.';
  end if;

  select * into v_incorp_decision
  from public.skpe_import_incorporation_decisions d
  where d.incorporation_request_id=v_request.id
  order by d.decision_sequence desc
  limit 1;

  if v_incorp_decision.id is null
     or v_incorp_decision.permits_incorporation <> true
     or v_incorp_decision.decision_outcome not in ('approved','approved_with_reservations') then
    raise exception using errcode='55000',
      message='Decisão de incorporação vigente não permite materialização da decisão histórica.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.source_entity_code='decision'
    and e.target_entity_type='gate_decision'
    and e.resolution_status='resolved'
    and e.resolution_mode='create_new_entity'
    and e.target_entity_id is not null
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',
      message='Decisão histórica não possui gate canônico resolvido como âncora.';
  end if;

  select * into v_gate
  from public.skpe_journey_items j
  where j.id=v_resolution.target_entity_id
    and j.project_id=v_request.project_id
    and j.code='PEM-02.GATE'
    and j.item_type='gate'
  limit 1;

  if v_gate.id is null then
    raise exception using errcode='55000',
      message='Âncora da decisão histórica não corresponde ao PEM-02.GATE canônico.';
  end if;

  select
    count(*) filter (
      where validation_state not in ('validated','validated_with_reservations')
         or item_status <> 'approved'
         or requires_human_review=true
         or extraction_mode='inferred'
    ),
    count(*) filter (
      where target_resolution_mode <> 'create_new_entity'
         or target_resolution_state <> 'resolved'
         or target_entity_type <> 'gate_decision'
         or target_entity_id is distinct from v_gate.id
    )
  into v_bad_items,v_target_mismatch
  from public.skpe_import_incorporation_items
  where incorporation_request_id=v_request.id;

  if v_bad_items <> 0 then
    raise exception using errcode='55000',
      message='Todos os Incorporation Items da decisão histórica devem estar validados e aprovados.';
  end if;

  if v_target_mismatch <> 0 then
    raise exception using errcode='55000',
      message='Incorporation Items da decisão histórica divergem da âncora PEM-02.GATE.';
  end if;

  v_source_code:=nullif(btrim(v_record.values_json->>'codigo'),'');
  v_source_date:=nullif(btrim(v_record.values_json->>'data'),'');
  v_source_topic:=nullif(btrim(v_record.values_json->>'tema'),'');
  v_source_decision:=nullif(btrim(v_record.values_json->>'decisao'),'');
  v_source_status:=nullif(btrim(v_record.values_json->>'situacao'),'');
  v_source_conditions:=nullif(btrim(v_record.values_json->>'condicoes'),'');
  v_source_evidence:=nullif(btrim(v_record.values_json->>'evidencias'),'');
  v_source_responsible:=nullif(btrim(v_record.values_json->>'responsavel'),'');
  v_source_question:=nullif(btrim(v_record.values_json->>'questao_decisoria'),'');

  if v_source_code not in ('DEC-02.03','DEC-02.04') then
    raise exception using errcode='55000',
      message='Código histórico não autorizado para este materializador de decisão.';
  end if;

  if lower(coalesce(v_source_decision,'')) <> 'aprovado integralmente'
     or lower(coalesce(v_source_status,'')) <> 'aprovado' then
    raise exception using errcode='55000',
      message='A decisão histórica não contém resultado de aprovação integral esperado.';
  end if;

  if v_source_date !~ '^\d{2}/\d{2}/\d{4}$' then
    raise exception using errcode='55000',
      message='Data histórica da decisão não está no formato DD/MM/AAAA.';
  end if;

  v_decided_at:=to_date(v_source_date,'DD/MM/YYYY')::timestamptz;

  select d.id into v_existing_id
  from public.skpe_gate_decisions d
  where d.project_id=v_request.project_id
    and d.gate_journey_item_id=v_gate.id
    and d.decision_origin_type='imported_historical'
    and (
      d.metadata->>'source_import_record_id'=v_record.id::text
      or d.decision_context->>'source_decision_code'=v_source_code
    )
  order by d.decision_sequence
  limit 1;

  if v_existing_id is not null then
    return v_existing_id;
  end if;

  select d.id,d.decision_sequence
  into v_prev_id,v_prev_sequence
  from public.skpe_gate_decisions d
  where d.project_id=v_request.project_id
    and d.gate_journey_item_id=v_gate.id
  order by d.decision_sequence desc
  limit 1;

  insert into public.skpe_gate_decisions(
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
    source_decision_date,
    source_external_key,
    metadata
  )
  values(
    v_request.organization_id,
    v_request.project_id,
    v_gate.id,
    'approved',
    coalesce(v_source_question,'Decisão histórica importada') ||
      case when v_source_conditions is not null then ' | Condições históricas: '||v_source_conditions else '' end,
    null,
    null,
    jsonb_build_object(
      'historical_import',true,
      'source_status',v_source_status,
      'source_decision',v_source_decision,
      'source_evidence_reference',v_source_evidence,
      'formal_evidence_still_required',
        lower(coalesce(v_source_conditions,'')) like '%evidência formal%'
        or lower(coalesce(v_source_conditions,'')) like '%evidencia formal%'
    ),
    jsonb_build_object(
      'decision_kind','historical_pem02_gate_decision',
      'source_decision_code',v_source_code,
      'source_topic',v_source_topic,
      'source_question',v_source_question,
      'source_conditions',v_source_conditions,
      'source_responsible',v_source_responsible,
      'source_date',v_source_date,
      'source_payload',v_record.values_json
    ),
    v_prev_id,
    coalesce(v_prev_sequence,0)+1,
    null,
    p_materialized_by_user_id,
    'imported_historical',
    'sparks_consultancy',
    'date_only',
    to_date(v_source_date,'DD/MM/YYYY'),
    v_record.external_key,
    jsonb_build_object(
      'historical_import',true,
      'source_batch_id',v_record.batch_id,
      'source_import_record_id',v_record.id,
      'source_external_key',v_record.external_key,
      'source_decision_code',v_source_code,
      'source_date',v_source_date,
      'historical_business_approval_preserved',true,
      'business_decision_repeated',false,
      'semantic_inference',false
    ) || p_metadata
  )
  returning id into v_gate_decision_id;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    'HISTORICAL_GATE_DECISION_MATERIALIZED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_incorp_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'gateJourneyItemId',v_gate.id,
      'gateDecisionId',v_gate_decision_id,
      'sourceDecisionCode',v_source_code,
      'sourceDate',v_source_date,
      'decisionOriginType','imported_historical',
      'decisionTimePrecision','date_only',
      'businessDecisionRepeated',false,
      'semanticInference',false
    ) || p_metadata
  );

  return v_gate_decision_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_historical_gate_decision(uuid,text,uuid,jsonb)
  from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_historical_gate_decision(uuid,text,uuid,jsonb)
  to service_role;

do $$
begin
  if to_regprocedure('public.skpe_execute_governed_import_materialization_pre_historical_gate_v1(uuid,text,uuid,jsonb)') is null
     and to_regprocedure('public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)') is not null then
    alter function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
      rename to skpe_execute_governed_import_materialization_pre_historical_gate_v1;
  end if;
end $$;

create or replace function public.skpe_execute_governed_import_materialization(
  p_request_id uuid,
  p_materialized_by_actor_type text,
  p_materialized_by_user_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_request public.skpe_import_incorporation_requests%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_entity_id uuid;
  v_finalize jsonb;
begin
  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  if v_request.id is null then
    raise exception using errcode='22023', message='Incorporation Request não encontrado.';
  end if;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null then
    raise exception using errcode='55000', message='ImportRecord do Request não encontrado.';
  end if;

  if v_record.entity_code <> 'decision' then
    return public.skpe_execute_governed_import_materialization_pre_historical_gate_v1(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_request.request_status='applied' then
    if v_request.metadata->>'materialized_target_entity_type'='gate_decision'
       and nullif(v_request.metadata->>'materialized_target_entity_id','') is not null
       and exists(
         select 1 from public.skpe_gate_decisions d
         where d.id=(v_request.metadata->>'materialized_target_entity_id')::uuid
       ) then
      return jsonb_build_object(
        'request_id',v_request.id,
        'request_status','applied',
        'materialized_entity_type','gate_decision',
        'materialized_entity_id',(v_request.metadata->>'materialized_target_entity_id')::uuid,
        'already_finalized',true,
        'dispatcher','skpe_execute_governed_import_materialization',
        'dispatcher_version','HISTORICAL-GATE-DECISION-V1'
      );
    end if;

    raise exception using errcode='55000',
      message='Request de decisão aplicado sem alvo histórico verificável.';
  end if;

  v_entity_id:=public.skpe_materialize_import_request_as_historical_gate_decision(
    p_request_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata
  );

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,
    'gate_decision',
    v_entity_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata || jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','HISTORICAL-GATE-DECISION-V1',
      'historical_import',true,
      'historical_business_approval_preserved',true,
      'business_decision_repeated',false,
      'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family','decision',
    'materialized_entity_type','gate_decision',
    'materialized_entity_id',v_entity_id,
    'historical_import',true,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','HISTORICAL-GATE-DECISION-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization_pre_historical_gate_v1(uuid,text,uuid,jsonb)
  from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization_pre_historical_gate_v1(uuid,text,uuid,jsonb)
  to service_role;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
  from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
  to service_role;

