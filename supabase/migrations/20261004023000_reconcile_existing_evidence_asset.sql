-- SK-PE - Reconcile historical evidence records with already canonical evidence assets.
-- This migration does not create or update evidence business content.

create or replace function public.skpe_execute_resolution_handler_evidence_asset_by_external_key(
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
  v_source_code text;
  v_external_key text;
  v_match_count integer := 0;
  v_target_id uuid;
  v_target_title text;
  v_validation_status text;
  v_reliability_level text;
begin
  if p_project_id is null then
    raise exception using errcode='22023',message='project_id é obrigatório.';
  end if;

  v_source_code:=nullif(btrim(p_source_value),'');
  if v_source_code is null then
    return jsonb_build_object(
      'resolution_status','blocked',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',null,
      'target_reference','{}'::jsonb,
      'resolution_details','{}'::jsonb,
      'warnings','[]'::jsonb,
      'blockers',jsonb_build_array(jsonb_build_object(
        'code','EVIDENCE_CODE_MISSING',
        'message','Código histórico da evidência não informado.'
      )),
      'requires_human_review',true
    );
  end if;

  v_external_key:='evidence:'||lower(v_source_code);

  select count(*)
  into v_match_count
  from public.sparks_evidence_assets e
  where e.source_external_key=v_external_key
    and e.metadata->>'legacy_project_id'=p_project_id::text
    and e.archived_at is null;

  if v_match_count=1 then
    select e.id,e.title,e.validation_status,e.reliability_level
    into v_target_id,v_target_title,v_validation_status,v_reliability_level
    from public.sparks_evidence_assets e
    where e.source_external_key=v_external_key
      and e.metadata->>'legacy_project_id'=p_project_id::text
      and e.archived_at is null;
  end if;

  if v_match_count=0 then
    return jsonb_build_object(
      'resolution_status','requires_review',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',v_external_key,
      'target_reference',jsonb_build_object(
        'entity_type','evidence_asset',
        'source_external_key',v_external_key,
        'project_id',p_project_id
      ),
      'resolution_details',jsonb_build_object(
        'source_value',v_source_code,
        'match_count',0,
        'match_strategy','exact_source_external_key_same_legacy_project'
      ),
      'warnings',jsonb_build_array(jsonb_build_object(
        'code','CANONICAL_EVIDENCE_ASSET_NOT_FOUND',
        'message','Ativo canônico de evidência não localizado.'
      )),
      'blockers','[]'::jsonb,
      'requires_human_review',true
    );
  end if;

  if v_match_count>1 then
    return jsonb_build_object(
      'resolution_status','blocked',
      'resolution_mode','unresolved',
      'target_entity_id',null,
      'target_external_key',v_external_key,
      'target_reference','{}'::jsonb,
      'resolution_details',jsonb_build_object(
        'source_value',v_source_code,
        'match_count',v_match_count
      ),
      'warnings','[]'::jsonb,
      'blockers',jsonb_build_array(jsonb_build_object(
        'code','CANONICAL_EVIDENCE_ASSET_AMBIGUOUS',
        'message','Mais de um ativo canônico corresponde à evidência histórica.'
      )),
      'requires_human_review',true
    );
  end if;

  return jsonb_build_object(
    'resolution_status','resolved',
    'resolution_mode','existing_entity',
    'target_entity_id',v_target_id,
    'target_external_key',v_external_key,
    'target_reference',jsonb_build_object(
      'entity_type','evidence_asset',
      'entity_id',v_target_id,
      'source_external_key',v_external_key,
      'title',v_target_title,
      'validation_status',v_validation_status,
      'reliability_level',v_reliability_level,
      'project_id',p_project_id
    ),
    'resolution_details',jsonb_build_object(
      'source_value',v_source_code,
      'match_count',1,
      'match_strategy','exact_source_external_key_same_legacy_project'
    ),
    'warnings','[]'::jsonb,
    'blockers','[]'::jsonb,
    'requires_human_review',true
  );
end;
$function$;

revoke all on function public.skpe_execute_resolution_handler_evidence_asset_by_external_key(text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_resolution_handler_evidence_asset_by_external_key(text,uuid,jsonb)
to service_role;

insert into public.skpe_incorporation_resolution_handlers(
  handler_code,handler_name,description,handler_type,handler_version,status,
  input_contract,output_contract,configuration_contract,allows_semantic_inference,metadata
)
values(
  'evidence_asset_by_external_key',
  'Evidência canônica por chave externa histórica',
  'Resolve ativo de evidência já existente por source_external_key e projeto legado, sem alterar o ativo.',
  'canonical_lookup',1,'active',
  jsonb_build_object('required',jsonb_build_array('source_value','project_id')),
  jsonb_build_object('fields',jsonb_build_array(
    'target_entity_id','target_external_key','target_reference',
    'resolution_status','resolution_mode','warnings','blockers'
  )),
  '{}'::jsonb,
  false,
  jsonb_build_object(
    'deterministic',true,
    'reconciliation_only',true,
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
    when 'current_project_reference' then
      return public.skpe_execute_resolution_handler_current_project_reference(p_source_value,p_project_id,p_config);
    when 'evidence_asset_by_external_key' then
      return public.skpe_execute_resolution_handler_evidence_asset_by_external_key(p_source_value,p_project_id,p_config);
    else
      raise exception using errcode='0A000',message='Handler cadastrado ainda não possui executor implementado.';
  end case;
end;
$function$;

create or replace function public.skpe_materialize_import_request_as_existing_evidence_asset(
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
  v_target_id uuid;
  v_source_code text;
  v_expected_key text;
begin
  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null or v_record.entity_code <> 'evidence' then
    raise exception using errcode='55000',
      message='Materializador de reconciliação de evidência exige entity_code = evidence.';
  end if;

  select * into v_decision
  from public.skpe_import_incorporation_decisions d
  where d.incorporation_request_id=v_request.id
  order by d.decision_sequence desc
  limit 1;

  if v_decision.id is null
     or v_decision.permits_incorporation <> true
     or v_decision.decision_outcome not in ('approved','approved_with_reservations') then
    raise exception using errcode='55000',
      message='Decisão vigente não permite finalização da reconciliação de evidência.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.source_entity_code='evidence'
    and e.target_entity_type='evidence_asset'
    and e.resolution_status='resolved'
    and e.resolution_mode='existing_entity'
    and e.target_entity_id is not null
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',
      message='Evidência histórica não possui ativo canônico existente resolvido.';
  end if;

  v_target_id:=v_resolution.target_entity_id;
  v_source_code:=nullif(btrim(v_record.values_json->>'codigo'),'');
  v_expected_key:='evidence:'||lower(v_source_code);

  if not exists(
    select 1
    from public.sparks_evidence_assets e
    where e.id=v_target_id
      and e.source_external_key=v_expected_key
      and e.metadata->>'legacy_project_id'=v_request.project_id::text
      and e.archived_at is null
  ) then
    raise exception using errcode='55000',
      message='Ativo canônico de evidência não corresponde à chave histórica e ao projeto.';
  end if;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    'EXISTING_EVIDENCE_ASSET_RECONCILED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'evidenceAssetId',v_target_id,
      'sourceEvidenceCode',v_source_code,
      'businessContentUpdated',false,
      'validationStatusUpdated',false,
      'reliabilityUpdated',false,
      'formalDocumentCreated',false,
      'reconciliationOnly',true,
      'semanticInference',false
    )||p_metadata
  );

  return v_target_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_existing_evidence_asset(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_existing_evidence_asset(uuid,text,uuid,jsonb)
to service_role;

do $$
declare
  v_catalog_id uuid;
  v_version_id uuid;
begin
  select id into v_catalog_id
  from public.skpe_incorporation_mapping_catalogs
  where mapping_code='evidence_to_existing_evidence_asset';

  if v_catalog_id is null then
    insert into public.skpe_incorporation_mapping_catalogs(
      mapping_code,mapping_name,description,source_entity_code,target_entity_type,
      resolution_strategy,materialization_strategy,provenance_strategy,
      requires_human_review,allows_create_new,allows_existing_entity,
      allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
    )
    values(
      'evidence_to_existing_evidence_asset',
      'Evidência histórica → ativo canônico existente',
      'Reconcilia a evidência histórica E14 com o ativo canônico já existente, preservando a lacuna documental sem alterar conteúdo, validação ou confiabilidade.',
      'evidence','evidence_asset',
      'existing_entity','direct_entity','a1_object_and_fields',
      true,false,true,false,'active',1,
      jsonb_build_object(
        'reconciliation_only',true,
        'business_content_updated',false,
        'validation_status_updated',false,
        'reliability_updated',false,
        'formal_document_created',false,
        'semantic_inference',false
      ),
      100,
      jsonb_build_object('module','SK-PE','semantic_family','evidence')
    )
    returning id into v_catalog_id;
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
      'sparks_evidence_assets','existing_entity','evidence:{codigo}',
      'skpe_execute_import_resolution_rules',
      'skpe_materialize_import_request_as_existing_evidence_asset',
      null,
      jsonb_build_object(
        'requires_human_review',true,
        'allows_semantic_inference',false,
        'require_valid_import_record',true,
        'require_approved_incorporation_items',true,
        'require_governed_incorporation_decision',true
      ),
      jsonb_build_object(
        'source_key','codigo',
        'canonical_lookup','source_external_key=evidence:<lower(codigo)> and legacy_project_id=current_project',
        'business_content_policy','do_not_update',
        'validation_status_policy','preserve_existing',
        'reliability_policy','preserve_existing',
        'formal_document_policy','do_not_fabricate'
      ),
      timezone('utc',now()),
      jsonb_build_object(
        'reconciliation_only',true,
        'common_finalizer','skpe_finalize_governed_import_materialization'
      )
    )
    returning id into v_version_id;
  end if;

  if not exists(
    select 1
    from public.skpe_incorporation_resolution_rules
    where mapping_version_id=v_version_id
      and rule_code='evidence_existing_asset_by_external_key'
  ) then
    insert into public.skpe_incorporation_resolution_rules(
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
      output_key,depends_on_rule_code
    )
    values(
      v_version_id,1,'evidence_existing_asset_by_external_key','custom','codigo',
      'evidence_asset','exists',null,'{}'::jsonb,true,false,
      jsonb_build_object('reconciliation_only',true,'semantic_inference',false),
      'evidence_asset_by_external_key','{}'::jsonb,'terminal','canonical_target',null
    );
  end if;
end $$;

alter function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
rename to skpe_execute_governed_import_materialization_evidence_checklist_v1;

create function public.skpe_execute_governed_import_materialization(
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

  if v_record.entity_code <> 'evidence' then
    return public.skpe_execute_governed_import_materialization_evidence_checklist_v1(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_request.request_status='applied' then
    begin
      v_entity_id:=nullif(v_request.metadata->>'materialized_target_entity_id','')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='55000',
        message='Request evidence applied possui materialized_target_entity_id inválido.';
    end;

    if v_request.metadata->>'materialized_target_entity_type' <> 'evidence_asset'
       or v_entity_id is null
       or not exists(
         select 1
         from public.sparks_evidence_assets e
         where e.id=v_entity_id
           and e.metadata->>'legacy_project_id'=v_request.project_id::text
           and e.archived_at is null
       ) then
      raise exception using errcode='55000',
        message='Request evidence applied não possui ativo canônico verificável.';
    end if;

    return jsonb_build_object(
      'request_id',v_request.id,
      'import_record_id',v_record.id,
      'source_family','evidence',
      'handler_name','skpe_materialize_import_request_as_existing_evidence_asset',
      'materialized_entity_type','evidence_asset',
      'materialized_entity_id',v_entity_id,
      'request_status','applied',
      'already_materialized',true,
      'already_finalized',true,
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-EVIDENCE-RECON-V1'
    );
  end if;

  v_entity_id:=public.skpe_materialize_import_request_as_existing_evidence_asset(
    p_request_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher_version','COOTAQUARA-EVIDENCE-RECON-V1',
      'reconciliation_only',true,
      'business_content_updated',false,
      'validation_status_updated',false,
      'reliability_updated',false,
      'formal_document_created',false,
      'semantic_inference',false
    )
  );

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,
    'evidence_asset',
    v_entity_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-EVIDENCE-RECON-V1',
      'handler_name','skpe_materialize_import_request_as_existing_evidence_asset',
      'reconciliation_only',true,
      'business_content_updated',false,
      'validation_status_updated',false,
      'reliability_updated',false,
      'formal_document_created',false,
      'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family','evidence',
    'handler_name','skpe_materialize_import_request_as_existing_evidence_asset',
    'materialized_entity_type','evidence_asset',
    'materialized_entity_id',v_entity_id,
    'request_status','applied',
    'already_materialized',false,
    'already_finalized',false,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','COOTAQUARA-EVIDENCE-RECON-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
to service_role;
