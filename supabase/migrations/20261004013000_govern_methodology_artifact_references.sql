-- SK-PE - Preserve historical methodology artifact register entries as project provenance.
-- No canonical methodology artifact is created until file/version evidence is available and classified.

create or replace function public.skpe_materialize_import_request_as_methodology_artifact_reference(
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
  v_project_id uuid;
begin
  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null or v_record.entity_code <> 'methodology_artifact' then
    raise exception using errcode='55000',
      message='Materializador de referência de artefato exige entity_code = methodology_artifact.';
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
      message='Decisão vigente não permite finalizar a referência histórica de artefato.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.target_entity_type='methodology_artifact_reference_provenance'
    and e.resolution_status='resolved'
    and e.resolution_mode='existing_entity'
    and e.target_entity_id is not null
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',
      message='Referência histórica de artefato não possui projeto canônico resolvido.';
  end if;

  v_project_id:=v_resolution.target_entity_id;

  if v_project_id <> v_record.project_id
     or not exists(
       select 1 from public.skpe_projects p
       where p.id=v_project_id
         and p.organization_id=v_request.organization_id
     ) then
    raise exception using errcode='55000',
      message='Referência histórica de artefato não corresponde ao projeto canônico.';
  end if;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    'METHODOLOGY_ARTIFACT_REFERENCE_PRESERVED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'canonicalProjectId',v_project_id,
      'historicalArtifactCode',v_record.values_json->>'codigo',
      'historicalArtifactTitle',v_record.values_json->>'artefato',
      'historicalArtifactVersion',v_record.values_json->>'versao',
      'historicalArtifactStatus',v_record.values_json->>'status',
      'historicalRepositoryReference',v_record.values_json->>'local_repositorio',
      'canonicalArtifactCreated',false,
      'artifactFileMaterialized',false,
      'artifactTypeInferred',false,
      'requiresDocumentRecoveryForPromotion',true,
      'evidenceOnly',true,
      'semanticInference',false
    )||p_metadata
  );

  return v_project_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_methodology_artifact_reference(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_methodology_artifact_reference(uuid,text,uuid,jsonb)
to service_role;

do $$
declare
  v_catalog_id uuid;
  v_version_id uuid;
begin
  select id into v_catalog_id
  from public.skpe_incorporation_mapping_catalogs
  where mapping_code='methodology_artifact_to_historical_reference';

  if v_catalog_id is null then
    insert into public.skpe_incorporation_mapping_catalogs(
      mapping_code,mapping_name,description,source_entity_code,target_entity_type,
      resolution_strategy,materialization_strategy,provenance_strategy,
      requires_human_review,allows_create_new,allows_existing_entity,
      allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
    )
    values(
      'methodology_artifact_to_historical_reference',
      'Registro histórico de artefato → referência documental do projeto',
      'Preserva registros históricos de artefatos metodológicos sem criar artefato canônico enquanto arquivo, versão e tipologia não estiverem comprovados.',
      'methodology_artifact','methodology_artifact_reference_provenance',
      'existing_entity','evidence_only','a1_object',
      true,false,true,false,'active',1,
      jsonb_build_object(
        'canonical_artifact_created',false,
        'artifact_file_materialized',false,
        'artifact_type_inferred',false,
        'requires_document_recovery_for_promotion',true,
        'evidence_only',true,
        'semantic_inference',false
      ),
      100,
      jsonb_build_object('module','SK-PE','semantic_family','methodology_artifact_reference')
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
      'skpe_projects','existing_entity','{project_id}',
      'skpe_execute_import_resolution_rules',
      'skpe_materialize_import_request_as_methodology_artifact_reference',
      null,
      jsonb_build_object(
        'requires_human_review',true,
        'allows_semantic_inference',false,
        'require_valid_import_record',true,
        'require_approved_incorporation_items',true,
        'require_governed_incorporation_decision',true
      ),
      jsonb_build_object(
        'target_resolution','current_canonical_project',
        'business_materialization','deferred_until_document_recovery',
        'historical_payload_policy','preserve_in_import_record',
        'canonical_artifact_policy','do_not_create_without_document_evidence',
        'field_map',jsonb_build_object(
          'codigo','historical_artifact_code',
          'artefato','historical_artifact_title',
          'versao','historical_artifact_version',
          'status','historical_artifact_status',
          'local_repositorio','historical_repository_reference'
        )
      ),
      timezone('utc',now()),
      jsonb_build_object(
        'evidence_only',true,
        'requires_document_recovery_for_promotion',true,
        'common_finalizer','skpe_finalize_governed_import_materialization'
      )
    )
    returning id into v_version_id;
  end if;

  if not exists(
    select 1
    from public.skpe_incorporation_resolution_rules
    where mapping_version_id=v_version_id
      and rule_code='methodology_artifact_project_reference'
  ) then
    insert into public.skpe_incorporation_resolution_rules(
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
      output_key,depends_on_rule_code
    )
    values(
      v_version_id,1,'methodology_artifact_project_reference','custom','codigo',
      'methodology_artifact_reference_provenance','exists',null,'{}'::jsonb,true,false,
      jsonb_build_object(
        'evidence_only',true,
        'artifact_type_inferred',false,
        'semantic_inference',false
      ),
      'current_project_reference','{}'::jsonb,'terminal','canonical_target',null
    );
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

  if v_record.entity_code='methodology_artifact' then
    v_target_type:='methodology_artifact_reference_provenance';
    v_handler:='skpe_materialize_import_request_as_methodology_artifact_reference';
  else
    return public.skpe_execute_governed_import_materialization_c8(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_request.request_status='applied' then
    begin
      v_entity_id:=nullif(v_request.metadata->>'materialized_target_entity_id','')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='55000',message='Request applied possui materialized_target_entity_id inválido.';
    end;

    if v_request.metadata->>'materialized_target_entity_type' <> v_target_type
       or v_entity_id is null
       or not exists(
         select 1 from public.skpe_projects
         where id=v_entity_id
           and organization_id=v_request.organization_id
       ) then
      raise exception using errcode='55000',
        message='Request de referência de artefato applied não possui projeto canônico verificável.';
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
      'dispatcher_version','COOTAQUARA-ARTIFACT-REF-V1'
    );
  end if;

  v_entity_id:=public.skpe_materialize_import_request_as_methodology_artifact_reference(
    p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher_version','COOTAQUARA-ARTIFACT-REF-V1',
      'evidence_only',true,
      'canonical_artifact_created',false,
      'artifact_file_materialized',false,
      'artifact_type_inferred',false,
      'requires_document_recovery_for_promotion',true,
      'semantic_inference',false
    )
  );

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,v_target_type,v_entity_id,
    p_materialized_by_actor_type,p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-ARTIFACT-REF-V1',
      'handler_name',v_handler,
      'reconciliation_only',true,
      'evidence_only',true,
      'business_content_updated',false,
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
    'dispatcher_version','COOTAQUARA-ARTIFACT-REF-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
to service_role;
