CREATE OR REPLACE FUNCTION public.skpe_materialize_import_request_as_key_result(p_request_id uuid, p_materialized_by_actor_type text, p_materialized_by_user_id uuid DEFAULT NULL::uuid, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_request public.skpe_import_incorporation_requests%rowtype;
  v_record public.skpe_import_records%rowtype;
  v_decision public.skpe_import_incorporation_decisions%rowtype;
  v_resolution public.skpe_import_target_resolution_events%rowtype;
  v_parent public.skpe_okrs%rowtype;
  v_kr public.skpe_key_results%rowtype;
  v_item public.skpe_import_incorporation_items%rowtype;
  v_code text; v_name text; v_parent_code text;
  v_source_target text; v_source_baseline text; v_source_data_source text;
  v_source_deadline text; v_source_responsible text; v_source_status text;
  v_metadata jsonb; v_object_provenance_id uuid;
begin
  if p_metadata is null or jsonb_typeof(p_metadata) <> 'object' then
    raise exception using errcode='22023',message='p_metadata deve ser objeto JSON.';
  end if;
  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request from public.skpe_import_incorporation_requests where id=p_request_id for update;
  select * into v_record from public.skpe_import_records where id=v_request.import_record_id;
  if v_record.entity_code <> 'key_result' then
    raise exception using errcode='55000',message='ImportRecord não pertence à família key_result.';
  end if;
  select * into v_decision from public.skpe_import_incorporation_decisions
   where incorporation_request_id=v_request.id order by decision_sequence desc limit 1;

  select * into v_resolution from public.skpe_import_target_resolution_events e
   where e.import_record_id=v_record.id
     and e.organization_id=v_request.organization_id and e.project_id=v_request.project_id
     and e.formulation_id is not distinct from v_request.formulation_id
     and e.source_entity_code='key_result' and e.target_entity_type='key_result'
     and e.resolution_status='resolved' and e.resolution_mode='create_new_entity'
     and e.target_entity_id is null and nullif(btrim(e.target_external_key),'') is not null
     and coalesce(jsonb_array_length(e.blockers),0)=0
   order by e.resolution_sequence desc,e.resolved_at desc limit 1;
  if v_resolution.id is null then
    raise exception using errcode='55000',message='Não existe resolução declarativa válida para criação do Resultado-Chave.';
  end if;
  if coalesce((v_resolution.resolution_output->>'semantic_inference')::boolean,false)
     or coalesce((v_resolution.metadata#>>'{pipeline_result,terminal_result,resolution_details,semantic_inference}')::boolean,false) then
    raise exception using errcode='55000',message='Materialização de Resultado-Chave não permite inferência semântica.';
  end if;

  v_code:=btrim(v_resolution.target_reference->>'code');
  v_parent_code:=btrim(v_resolution.target_reference->>'parent_okr_code');
  begin v_parent.id:=(v_resolution.target_reference->>'parent_okr_id')::uuid;
  exception when others then raise exception using errcode='55000',message='parent_okr_id inválido na resolução terminal.'; end;
  if v_code !~ '^KR-[0-9]{2}$' or v_resolution.target_external_key <> v_parent_code||':'||v_code then
    raise exception using errcode='55000',message='Chave canônica do Resultado-Chave é inválida.';
  end if;
  select * into v_parent from public.skpe_okrs where id=v_parent.id;
  if v_parent.id is null or v_parent.code<>v_parent_code or v_parent.project_id<>v_request.project_id
     or v_parent.formulation_id<>v_request.formulation_id then
    raise exception using errcode='55000',message='OKR pai não materializado ou incompatível com o contexto.';
  end if;
  if (v_resolution.target_reference->>'strategic_objective_id')::uuid is distinct from
     (select strategic_objective_id from public.skpe_okr_objectives where okr_id=v_parent.id and is_primary=true limit 1) then
    raise exception using errcode='55000',message='Objetivo Estratégico primário da resolução é incompatível com o OKR pai.';
  end if;

  select normalized_value#>>'{}' into v_name from public.skpe_import_incorporation_items
   where incorporation_request_id=v_request.id and source_field_name='resultado_chave' limit 1;
  select normalized_value#>>'{}' into v_source_target from public.skpe_import_incorporation_items where incorporation_request_id=v_request.id and source_field_name='meta' limit 1;
  select normalized_value#>>'{}' into v_source_baseline from public.skpe_import_incorporation_items where incorporation_request_id=v_request.id and source_field_name='linha_de_base' limit 1;
  select normalized_value#>>'{}' into v_source_data_source from public.skpe_import_incorporation_items where incorporation_request_id=v_request.id and source_field_name='fonte' limit 1;
  select normalized_value#>>'{}' into v_source_deadline from public.skpe_import_incorporation_items where incorporation_request_id=v_request.id and source_field_name='prazo' limit 1;
  select normalized_value#>>'{}' into v_source_responsible from public.skpe_import_incorporation_items where incorporation_request_id=v_request.id and source_field_name='responsavel' limit 1;
  select normalized_value#>>'{}' into v_source_status from public.skpe_import_incorporation_items where incorporation_request_id=v_request.id and source_field_name='status' limit 1;
  if nullif(btrim(v_name),'') is null then raise exception using errcode='55000',message='Nome do Resultado-Chave ausente.'; end if;

  select * into v_kr from public.skpe_key_results where okr_id=v_parent.id and lower(btrim(code))=lower(v_code) limit 1;
  if v_kr.id is not null then
    if v_kr.metadata->>'incorporation_request_id'=v_request.id::text then return v_kr.id; end if;
    raise exception using errcode='23505',message='Já existe Resultado-Chave com o mesmo código no OKR pai, proveniente de outro fluxo.';
  end if;

  v_metadata:=jsonb_strip_nulls(jsonb_build_object(
    'source_target',v_source_target,'source_baseline',v_source_baseline,'source_data_source',v_source_data_source,
    'source_deadline',v_source_deadline,'source_responsible',v_source_responsible,'source_status',v_source_status,
    'parent_okr_code',v_parent.code,'resolved_parent_okr_id',v_parent.id,
    'resolved_strategic_objective_id',v_resolution.target_reference->>'strategic_objective_id',
    'target_resolution_event_id',v_resolution.id,'target_external_key',v_resolution.target_external_key,
    'import_record_id',v_record.id,'incorporation_request_id',v_request.id,
    'incorporation_decision_id',v_decision.id,'incorporation_decision_sequence',v_decision.decision_sequence,
    'incorporation_mode','governed_import','technical_incorporation',true,
    'institutional_validation',false,'institutional_validation_pending',true,
    'semantic_inference',false,'historical_status_promoted',false,'canonical_owner_resolved',false,
    'materialized_by_actor_type',p_materialized_by_actor_type,'materialized_by_user_id',p_materialized_by_user_id,
    'materialized_at',timezone('utc',now())
  ))||p_metadata;

  insert into public.skpe_key_results(
    organization_id,project_id,formulation_id,okr_id,strategic_objective_id,code,name,description,
    baseline_value,target_value,current_value,unit,period_start,period_end,owner_user_id,status,progress,
    contribution_weight,annualized_target,validation_status,metadata,created_by,updated_by
  ) values (
    v_request.organization_id,v_request.project_id,v_request.formulation_id,v_parent.id,
    (v_resolution.target_reference->>'strategic_objective_id')::uuid,v_code,btrim(v_name),null,
    null,null,null,null,null,null,null,'draft',0,null,false,'draft',v_metadata,
    p_materialized_by_user_id,p_materialized_by_user_id
  ) returning * into v_kr;

  insert into public.skpe_data_provenance(
    organization_id,formulation_id,entity_type,entity_id,field_name,origin_actor_type,source_type,source_role,
    extraction_mode,information_state,validation_state,import_batch_id,import_record_id,source_locator,source_label,
    source_external_key,source_fingerprint,original_value,normalized_value,origin_date,incorporated_at,incorporated_by,
    metadata,idempotency_key
  ) values (
    v_request.organization_id,v_request.formulation_id,'key_result',v_kr.id,null,'organization','canonical_workbook','primary',
    v_record.extraction_mode,v_record.information_state,v_record.validation_state,v_request.batch_id,v_record.id,
    v_record.source_locator,v_record.entity_name,v_record.external_key,v_record.fingerprint,to_jsonb(v_record.values_json),
    to_jsonb(v_kr),v_record.created_at,timezone('utc',now()),p_materialized_by_user_id,
    p_metadata||jsonb_build_object('provenance_contract','A1','provenance_level','object','semantic_inference',false,
      'institutional_validation_pending',true,'incorporation_request_id',v_request.id,'incorporation_decision_id',v_decision.id,
      'target_resolution_event_id',v_resolution.id,'materializer','skpe_materialize_import_request_as_key_result'),
    'key_result:'||v_kr.id||':import_record:'||v_record.id
  ) returning id into v_object_provenance_id;

  for v_item in select * from public.skpe_import_incorporation_items where incorporation_request_id=v_request.id order by item_sequence
  loop
    insert into public.skpe_data_provenance(
      organization_id,formulation_id,entity_type,entity_id,field_name,origin_actor_type,source_type,source_role,
      extraction_mode,information_state,validation_state,import_batch_id,import_record_id,source_locator,source_label,
      source_external_key,source_fingerprint,original_value,normalized_value,origin_date,incorporated_at,incorporated_by,
      metadata,idempotency_key
    ) values (
      v_request.organization_id,v_request.formulation_id,'key_result',v_kr.id,v_item.target_field_name,'organization',
      'canonical_workbook',v_item.source_role,v_item.extraction_mode,v_item.information_state,'pending',
      v_request.batch_id,v_record.id,v_item.source_locator,v_item.source_field_name,v_record.external_key,v_record.fingerprint,
      v_item.original_value,v_item.normalized_value,v_record.created_at,timezone('utc',now()),p_materialized_by_user_id,
      p_metadata||jsonb_build_object('provenance_contract','A1','provenance_level','field','object_provenance_id',v_object_provenance_id,
        'incorporation_item_id',v_item.id,'incorporation_item_sequence',v_item.item_sequence,
        'source_field_name',v_item.source_field_name,'target_field_name',v_item.target_field_name,
        'semantic_inference',false,'institutional_validation_pending',true,'materializer','skpe_materialize_import_request_as_key_result'),
      'key_result:'||v_kr.id||':import_record:'||v_record.id||':field:'||v_item.target_field_name
    );
  end loop;

  perform public.skpe_record_operational_audit(v_kr.organization_id,v_kr.project_id,'key_result',v_kr.id,
    'key_result_created_by_governed_import','Materialização governada de Resultado-Chave histórico.',null,to_jsonb(v_kr));
  return v_kr.id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_key_result(uuid,text,uuid,jsonb) from public;
grant execute on function public.skpe_materialize_import_request_as_key_result(uuid,text,uuid,jsonb) to authenticated,service_role;

update public.skpe_incorporation_mapping_versions
set materializer_function_name = 'skpe_materialize_import_request_as_key_result',
    provenance_function_name = 'inline_a1_object_and_fields',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object('roadmap_step','CO-IMPORT-04-C9-E','semantic_inference',false)
where id = '88dedc42-30cd-44a1-8f2d-ee7d464ff83e';
