-- SK-PE - Preserve workbook governance and version history as evidence-only provenance.
-- These records are anchored to the import batch and never promoted to strategic business entities.

create or replace function public.skpe_execute_resolution_handler_current_import_batch_reference(
  p_source_value text,
  p_project_id uuid,
  p_config jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_batch_id uuid;
  v_batch public.skpe_import_batches%rowtype;
begin
  if p_project_id is null then
    raise exception using errcode='22023',message='project_id é obrigatório.';
  end if;

  begin
    v_batch_id:=nullif(btrim(p_config->>'batch_id'),'')::uuid;
  exception when others then
    raise exception using errcode='22023',message='batch_id inválido.';
  end;

  if v_batch_id is null then
    raise exception using errcode='22023',message='batch_id é obrigatório.';
  end if;

  select * into v_batch
  from public.skpe_import_batches
  where id=v_batch_id;

  if v_batch.id is null then
    return jsonb_build_object(
      'resolution_status','blocked',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',null,
      'target_reference','{}'::jsonb,
      'resolution_details',jsonb_build_object('batch_id',v_batch_id),
      'warnings','[]'::jsonb,
      'blockers',jsonb_build_array(jsonb_build_object(
        'code','IMPORT_BATCH_NOT_FOUND',
        'message','Lote de importação não encontrado para ancoragem de proveniência.'
      )),
      'requires_human_review',true
    );
  end if;

  if v_batch.project_id is distinct from p_project_id then
    return jsonb_build_object(
      'resolution_status','blocked',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',null,
      'target_reference','{}'::jsonb,
      'resolution_details',jsonb_build_object(
        'batch_id',v_batch_id,
        'batch_project_id',v_batch.project_id,
        'record_project_id',p_project_id
      ),
      'warnings','[]'::jsonb,
      'blockers',jsonb_build_array(jsonb_build_object(
        'code','IMPORT_BATCH_PROJECT_MISMATCH',
        'message','Lote e registro histórico pertencem a projetos distintos.'
      )),
      'requires_human_review',true
    );
  end if;

  return jsonb_build_object(
    'resolution_status','resolved',
    'resolution_mode','existing_entity',
    'target_entity_id',v_batch.id,
    'target_external_key',v_batch.id::text,
    'target_reference',jsonb_build_object(
      'entity_type','import_batch_provenance',
      'entity_id',v_batch.id,
      'source_file',v_batch.source_file,
      'project_id',v_batch.project_id
    ),
    'resolution_details',jsonb_build_object(
      'match_count',1,
      'match_strategy','current_import_batch',
      'source_value',p_source_value
    ),
    'warnings','[]'::jsonb,
    'blockers','[]'::jsonb,
    'requires_human_review',true
  );
end;
$function$;

revoke all on function public.skpe_execute_resolution_handler_current_import_batch_reference(text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_resolution_handler_current_import_batch_reference(text,uuid,jsonb)
to service_role;

insert into public.skpe_incorporation_resolution_handlers(
  handler_code,handler_name,description,handler_type,handler_version,status,
  input_contract,output_contract,configuration_contract,allows_semantic_inference,metadata
)
values(
  'current_import_batch_reference',
  'Lote atual como âncora de proveniência',
  'Resolve deterministicamente o próprio lote de importação como alvo técnico para conteúdo histórico que deve ser preservado sem promoção a entidade estratégica.',
  'canonical_lookup',1,'active',
  jsonb_build_object('required',jsonb_build_array('project_id','batch_id')),
  jsonb_build_object('fields',jsonb_build_array(
    'target_entity_id','target_external_key','target_reference',
    'resolution_status','resolution_mode','warnings','blockers'
  )),
  jsonb_build_object('required',jsonb_build_array('batch_id')),
  false,
  jsonb_build_object(
    'deterministic',true,
    'evidence_only',true,
    'materializes_entity',false,
    'semantic_inference',false
  )
)
on conflict(handler_code) do update
set handler_name=excluded.handler_name,
    description=excluded.description,
    handler_type=excluded.handler_type,
    handler_version=excluded.handler_version,
    status=excluded.status,
    input_contract=excluded.input_contract,
    output_contract=excluded.output_contract,
    configuration_contract=excluded.configuration_contract,
    allows_semantic_inference=excluded.allows_semantic_inference,
    metadata=coalesce(public.skpe_incorporation_resolution_handlers.metadata,'{}'::jsonb)||excluded.metadata;

create or replace function public.skpe_execute_incorporation_resolution_handler(
  p_handler_code text,
  p_source_value text,
  p_project_id uuid,
  p_config jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_handler public.skpe_incorporation_resolution_handlers%rowtype;
begin
  if nullif(btrim(p_handler_code),'') is null then
    raise exception using errcode='22023',message='resolver_handler_code é obrigatório.';
  end if;

  select * into v_handler
  from public.skpe_incorporation_resolution_handlers
  where handler_code=p_handler_code;

  if v_handler.id is null then
    raise exception using errcode='55000',message='Handler de resolução não cadastrado.';
  end if;

  if v_handler.status <> 'active' then
    raise exception using errcode='55000',message='Handler de resolução não está ativo.';
  end if;

  case p_handler_code
    when 'journey_item_by_numeric_token' then
      return public.skpe_execute_resolution_handler_journey_item_by_numeric_token(p_source_value,p_project_id,p_config);
    when 'create_new_entity_by_source_key' then
      return public.skpe_execute_resolution_handler_create_new_entity_by_source_key(p_source_value,p_project_id,p_config);
    when 'canonical_entity_by_code' then
      return public.skpe_execute_resolution_handler_canonical_entity_by_code(p_source_value,p_project_id,p_config);
    when 'cross_sheet_positional_create_new_candidate' then
      return public.skpe_execute_resolution_handler_cross_sheet_positional_create_new_candidate(p_source_value,p_project_id,p_config);
    when 'key_result_parent_okr_candidate' then
      return public.skpe_execute_resolution_handler_key_result_parent_okr_candidate(p_source_value,p_project_id,p_config);
    when 'strategic_identity_item_by_element' then
      return public.skpe_execute_resolution_handler_strategic_identity_item_by_element(p_source_value,p_project_id,p_config);
    when 'strategic_value_by_name' then
      return public.skpe_execute_resolution_handler_strategic_value_by_name(p_source_value,p_project_id,p_config);
    when 'current_import_batch_reference' then
      return public.skpe_execute_resolution_handler_current_import_batch_reference(p_source_value,p_project_id,p_config);
    else
      raise exception using errcode='0A000',message='Handler cadastrado ainda não possui executor implementado.';
  end case;
end;
$function$;

create or replace function public.skpe_materialize_import_request_as_batch_provenance(
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
  v_decision public.skpe_import_incorporation_decisions%rowtype;
  v_resolution public.skpe_import_target_resolution_events%rowtype;
  v_batch_id uuid;
begin
  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null
     or v_record.entity_code not in ('version_control','living_governance') then
    raise exception using errcode='55000',message='Materializador de proveniência não suporta este entity_code.';
  end if;

  select * into v_decision
  from public.skpe_import_incorporation_decisions d
  where d.incorporation_request_id=v_request.id
  order by d.decision_sequence desc
  limit 1;

  if v_decision.id is null
     or v_decision.permits_incorporation <> true
     or v_decision.decision_outcome not in ('approved','approved_with_reservations') then
    raise exception using errcode='55000',message='Decisão vigente não permite finalização da proveniência histórica.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.target_entity_type='import_batch_provenance'
    and e.resolution_status='resolved'
    and e.resolution_mode='existing_entity'
    and e.target_entity_id is not null
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',message='Registro histórico não possui lote de proveniência resolvido.';
  end if;

  v_batch_id:=v_resolution.target_entity_id;

  if v_batch_id <> v_record.batch_id
     or not exists(
       select 1 from public.skpe_import_batches b
       where b.id=v_batch_id
         and b.project_id=v_request.project_id
         and b.organization_id=v_request.organization_id
     ) then
    raise exception using errcode='55000',message='Âncora de proveniência não corresponde ao lote do ImportRecord.';
  end if;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    'WORKBOOK_HISTORICAL_PROVENANCE_RECONCILED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'provenanceBatchId',v_batch_id,
      'sourceEntityCode',v_record.entity_code,
      'businessEntityCreated',false,
      'businessContentUpdated',false,
      'evidenceOnly',true,
      'reconciliationOnly',true,
      'semanticInference',false
    )||p_metadata
  );

  return v_batch_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_batch_provenance(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_batch_provenance(uuid,text,uuid,jsonb)
to service_role;

do $$
declare
  v_source_code text;
  v_mapping_code text;
  v_mapping_name text;
  v_description text;
  v_source_field text;
  v_target_field text;
  v_catalog_id uuid;
  v_version_id uuid;
begin
  foreach v_source_code in array array['version_control','living_governance']
  loop
    if v_source_code='version_control' then
      v_mapping_code:='version_control_to_batch_provenance';
      v_mapping_name:='Controle de versões → proveniência do lote';
      v_description:='Preserva histórico de versões do workbook como proveniência auditável do lote, sem criar entidade estratégica.';
      v_source_field:='versao';
      v_target_field:='historical_version';
    else
      v_mapping_code:='living_governance_to_batch_provenance';
      v_mapping_name:='Governança viva do workbook → proveniência do lote';
      v_description:='Preserva instruções e estado operacional da governança do workbook como evidência histórica, sem promover instruções a fatos estratégicos.';
      v_source_field:='como_usar';
      v_target_field:='historical_governance_instruction';
    end if;

    select id into v_catalog_id
    from public.skpe_incorporation_mapping_catalogs
    where mapping_code=v_mapping_code;

    if v_catalog_id is null then
      insert into public.skpe_incorporation_mapping_catalogs(
        mapping_code,mapping_name,description,source_entity_code,target_entity_type,
        resolution_strategy,materialization_strategy,provenance_strategy,
        requires_human_review,allows_create_new,allows_existing_entity,
        allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
      )
      values(
        v_mapping_code,v_mapping_name,v_description,v_source_code,'import_batch_provenance',
        'existing_entity','evidence_only','a1_object',
        true,false,true,false,'active',1,
        jsonb_build_object(
          'evidence_only',true,
          'historical_provenance_only',true,
          'business_entity_created',false,
          'business_content_updated',false,
          'semantic_inference',false
        ),
        100,
        jsonb_build_object('module','SK-PE','semantic_family',v_source_code)
      )
      returning id into v_catalog_id;
    else
      update public.skpe_incorporation_mapping_catalogs
      set mapping_name=v_mapping_name,
          description=v_description,
          source_entity_code=v_source_code,
          target_entity_type='import_batch_provenance',
          resolution_strategy='existing_entity',
          materialization_strategy='evidence_only',
          provenance_strategy='a1_object',
          requires_human_review=true,
          allows_create_new=false,
          allows_existing_entity=true,
          allows_semantic_inference=false,
          status='active',
          current_version=1,
          selection_priority=100,
          applicability=jsonb_build_object('module','SK-PE','semantic_family',v_source_code),
          metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
            'evidence_only',true,
            'historical_provenance_only',true,
            'business_entity_created',false,
            'business_content_updated',false,
            'semantic_inference',false
          )
      where id=v_catalog_id;
    end if;

    select id into v_version_id
    from public.skpe_incorporation_mapping_versions
    where catalog_id=v_catalog_id and version_number=1;

    if v_version_id is null then
      insert into public.skpe_incorporation_mapping_versions(
        catalog_id,version_number,version_status,effective_from,target_table,
        target_key_strategy,target_key_template,resolver_function_name,
        materializer_function_name,provenance_function_name,validation_profile,
        mapping_definition,activated_at,metadata
      )
      values(
        v_catalog_id,1,'active',timezone('utc',now()),
        'skpe_import_batches','existing_entity','{batch_id}',
        'skpe_execute_import_resolution_rules',
        'skpe_materialize_import_request_as_batch_provenance',
        null,
        jsonb_build_object(
          'requires_human_review',true,
          'allows_semantic_inference',false,
          'require_valid_import_record',true,
          'require_approved_incorporation_items',true,
          'require_governed_incorporation_decision',true
        ),
        jsonb_build_object(
          'target_resolution','current_import_batch',
          'business_materialization','none',
          'historical_payload_policy','preserve_in_import_record',
          'field_map',jsonb_build_object(v_source_field,v_target_field)
        ),
        timezone('utc',now()),
        jsonb_build_object(
          'evidence_only',true,
          'historical_provenance_only',true,
          'common_finalizer','skpe_finalize_governed_import_materialization'
        )
      )
      returning id into v_version_id;
    else
      update public.skpe_incorporation_mapping_versions
      set version_status='active',
          effective_from=coalesce(effective_from,timezone('utc',now())),
          effective_until=null,
          target_table='skpe_import_batches',
          target_key_strategy='existing_entity',
          target_key_template='{batch_id}',
          resolver_function_name='skpe_execute_import_resolution_rules',
          materializer_function_name='skpe_materialize_import_request_as_batch_provenance',
          validation_profile=jsonb_build_object(
            'requires_human_review',true,
            'allows_semantic_inference',false,
            'require_valid_import_record',true,
            'require_approved_incorporation_items',true,
            'require_governed_incorporation_decision',true
          ),
          mapping_definition=jsonb_build_object(
            'target_resolution','current_import_batch',
            'business_materialization','none',
            'historical_payload_policy','preserve_in_import_record',
            'field_map',jsonb_build_object(v_source_field,v_target_field)
          ),
          activated_at=coalesce(activated_at,timezone('utc',now())),
          metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
            'evidence_only',true,
            'historical_provenance_only',true,
            'common_finalizer','skpe_finalize_governed_import_materialization'
          )
      where id=v_version_id;
    end if;

    if not exists(
      select 1
      from public.skpe_incorporation_resolution_rules
      where mapping_version_id=v_version_id
        and rule_code=v_source_code||'_current_batch_provenance'
    ) then
      insert into public.skpe_incorporation_resolution_rules(
        mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
        target_entity_type,operator,expected_value,resolution_output,is_blocking,
        stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
        output_key,depends_on_rule_code
      )
      values(
        v_version_id,1,v_source_code||'_current_batch_provenance','custom',v_source_field,
        'import_batch_provenance','exists',null,'{}'::jsonb,true,false,
        jsonb_build_object(
          'evidence_only',true,
          'historical_provenance_only',true,
          'semantic_inference',false
        ),
        'current_import_batch_reference','{}'::jsonb,'terminal','canonical_target',null
      );
    end if;

    v_catalog_id:=null;
    v_version_id:=null;
  end loop;
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
  v_target_type text;
  v_handler text;
begin
  if p_request_id is null then
    raise exception using errcode='22023',message='p_request_id é obrigatório.';
  end if;

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  if v_request.id is null then
    raise exception using errcode='22023',message='Incorporation Request não encontrado.';
  end if;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null then
    raise exception using errcode='55000',message='ImportRecord do Request não encontrado.';
  end if;

  if v_record.entity_code not in (
    'key_result','pestel','swot','tows','risk',
    'strategic_identity','living_value','pmvv_validation',
    'version_control','living_governance'
  ) then
    return public.skpe_execute_governed_import_materialization_c8(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_record.entity_code='key_result' then
    v_target_type:='key_result';
    v_handler:='skpe_materialize_import_request_as_key_result';
  elsif v_record.entity_code='pestel' then
    v_target_type:='pestel_item';
    v_handler:='skpe_materialize_import_request_as_pestel';
  elsif v_record.entity_code='swot' then
    v_target_type:='swot_item';
    v_handler:='skpe_materialize_import_request_as_swot';
  elsif v_record.entity_code='tows' then
    v_target_type:='tows_item';
    v_handler:='skpe_materialize_import_request_as_tows';
  elsif v_record.entity_code='risk' then
    v_target_type:='strategic_risk_item';
    v_handler:='skpe_materialize_import_request_as_strategic_risk';
  elsif v_record.entity_code='strategic_identity' then
    v_target_type:='strategic_identity_item';
    v_handler:='skpe_materialize_import_request_as_existing_reference';
  elsif v_record.entity_code='living_value' then
    v_target_type:='strategic_value';
    v_handler:='skpe_materialize_import_request_as_existing_reference';
  elsif v_record.entity_code='pmvv_validation' then
    v_target_type:='strategic_identity_item';
    v_handler:='skpe_materialize_import_request_as_pmvv_validation_reference';
  else
    v_target_type:='import_batch_provenance';
    v_handler:='skpe_materialize_import_request_as_batch_provenance';
  end if;

  if v_request.request_status='applied' then
    begin
      v_entity_id:=nullif(v_request.metadata->>'materialized_target_entity_id','')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='55000',message='Request applied possui materialized_target_entity_id inválido.';
    end;

    if v_request.metadata->>'materialized_target_entity_type' <> v_target_type or v_entity_id is null then
      raise exception using errcode='55000',message='Request applied não possui alvo materializado compatível.';
    end if;

    if v_record.entity_code='key_result'
       and not exists(select 1 from public.skpe_key_results where id=v_entity_id) then
      raise exception using errcode='55000',message='Request key_result applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code='pestel'
       and not exists(select 1 from public.skpe_pestel_items where id=v_entity_id) then
      raise exception using errcode='55000',message='Request pestel applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code='swot'
       and not exists(select 1 from public.skpe_swot_items where id=v_entity_id) then
      raise exception using errcode='55000',message='Request swot applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code='tows'
       and not exists(select 1 from public.skpe_tows_items where id=v_entity_id) then
      raise exception using errcode='55000',message='Request tows applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code='risk'
       and not exists(select 1 from public.skpe_strategic_risk_items where id=v_entity_id) then
      raise exception using errcode='55000',message='Request risk applied não possui alvo materializado verificável.';
    end if;
    if v_record.entity_code in ('strategic_identity','pmvv_validation')
       and not exists(
         select 1 from public.skpe_strategic_identity_items
         where id=v_entity_id
           and project_id=v_request.project_id
           and formulation_id=v_request.formulation_id
       ) then
      raise exception using errcode='55000',message='Request de Identidade/PMVV applied não possui alvo reconciliado verificável.';
    end if;
    if v_record.entity_code='living_value'
       and not exists(
         select 1 from public.skpe_strategic_values
         where id=v_entity_id
           and project_id=v_request.project_id
           and formulation_id=v_request.formulation_id
       ) then
      raise exception using errcode='55000',message='Request living_value applied não possui alvo reconciliado verificável.';
    end if;
    if v_record.entity_code in ('version_control','living_governance')
       and not exists(
         select 1 from public.skpe_import_batches
         where id=v_entity_id
           and project_id=v_request.project_id
           and organization_id=v_request.organization_id
       ) then
      raise exception using errcode='55000',message='Request de proveniência histórica applied não possui lote verificável.';
    end if;

    return jsonb_build_object(
      'request_id',v_request.id,
      'import_record_id',v_record.id,
      'source_family',v_record.entity_code,
      'handler_name',v_handler,
      'materialized_entity_type',v_target_type,
      'materialized_entity_id',v_entity_id,
      'request_status','applied',
      'already_materialized',true,
      'already_finalized',true,
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-PROVENANCE-V1'
    );
  end if;

  if v_record.entity_code='key_result' then
    v_entity_id:=public.skpe_materialize_import_request_as_key_result(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PROVENANCE-V1')
    );
  elsif v_record.entity_code='pestel' then
    v_entity_id:=public.skpe_materialize_import_request_as_pestel(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PROVENANCE-V1')
    );
  elsif v_record.entity_code='swot' then
    v_entity_id:=public.skpe_materialize_import_request_as_swot(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PROVENANCE-V1')
    );
  elsif v_record.entity_code='tows' then
    v_entity_id:=public.skpe_materialize_import_request_as_tows(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PROVENANCE-V1')
    );
  elsif v_record.entity_code='risk' then
    v_entity_id:=public.skpe_materialize_import_request_as_strategic_risk(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-PROVENANCE-V1')
    );
  elsif v_record.entity_code in ('strategic_identity','living_value') then
    v_entity_id:=public.skpe_materialize_import_request_as_existing_reference(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-PROVENANCE-V1',
        'reconciliation_only',true,
        'business_content_updated',false,
        'business_approval_reopened',false,
        'semantic_inference',false
      )
    );
  elsif v_record.entity_code='pmvv_validation' then
    v_entity_id:=public.skpe_materialize_import_request_as_pmvv_validation_reference(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-PROVENANCE-V1',
        'reconciliation_only',true,
        'historical_validation_preserved',true,
        'business_content_updated',false,
        'business_approval_reopened',false,
        'semantic_inference',false
      )
    );
  else
    v_entity_id:=public.skpe_materialize_import_request_as_batch_provenance(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-PROVENANCE-V1',
        'evidence_only',true,
        'historical_provenance_only',true,
        'business_entity_created',false,
        'business_content_updated',false,
        'semantic_inference',false
      )
    );
  end if;

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,v_target_type,v_entity_id,
    p_materialized_by_actor_type,p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-PROVENANCE-V1',
      'handler_name',v_handler,
      'reconciliation_only',v_record.entity_code in (
        'strategic_identity','living_value','pmvv_validation','version_control','living_governance'
      ),
      'evidence_only',v_record.entity_code in ('version_control','living_governance'),
      'business_content_updated',case
        when v_record.entity_code in (
          'strategic_identity','living_value','pmvv_validation','version_control','living_governance'
        ) then false
        else true
      end,
      'business_approval_reopened',false,
      'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family',v_record.entity_code,
    'handler_name',v_handler,
    'materialized_entity_type',v_target_type,
    'materialized_entity_id',v_entity_id,
    'request_status','applied',
    'already_materialized',false,
    'already_finalized',false,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','COOTAQUARA-PROVENANCE-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
to service_role;
