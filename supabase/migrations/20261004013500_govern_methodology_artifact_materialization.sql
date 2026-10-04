-- SK-PE - Materialize historical methodology artifacts into the canonical artifact authority.
-- Historical workbook labels (v13/v23) are preserved as source metadata.
-- Canonical versioning starts at v1; no synthetic intermediate versions are created.

create or replace function public.skpe_materialize_import_request_as_methodology_artifact(
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
  v_source_code text;
  v_source_title text;
  v_source_type text;
  v_source_status text;
  v_source_version text;
  v_source_date text;
  v_source_file text;
  v_artifact_type_code text;
  v_artifact_type_id uuid;
  v_artifact_status text;
  v_version_status text;
  v_artifact_id uuid;
  v_version_id uuid;
  v_file_extension text;
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
      message='Materializador de artefato metodológico exige entity_code = methodology_artifact.';
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
      message='Decisão vigente não permite materialização do artefato metodológico.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id=v_record.id
    and e.organization_id=v_request.organization_id
    and e.project_id=v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.source_entity_code='methodology_artifact'
    and e.target_entity_type='methodology_artifact'
    and e.resolution_status='resolved'
    and e.resolution_mode='create_new_entity'
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolved_at desc,e.resolution_sequence desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',
      message='Artefato metodológico não possui resolução governada para criação.';
  end if;

  v_source_code:=nullif(btrim(v_record.values_json->>'codigo'),'');
  v_source_title:=nullif(btrim(v_record.values_json->>'artefato'),'');
  v_source_type:=nullif(btrim(v_record.values_json->>'tipo'),'');
  v_source_status:=nullif(btrim(v_record.values_json->>'status'),'');
  v_source_version:=nullif(btrim(v_record.values_json->>'versao'),'');
  v_source_date:=nullif(btrim(v_record.values_json->>'data'),'');
  v_source_file:=nullif(btrim(v_record.values_json->>'local_repositorio'),'');

  if v_source_code is null or v_source_title is null then
    raise exception using errcode='55000',
      message='Artefato histórico exige código e título.';
  end if;

  case v_source_code
    when 'PEM-02.SGE-01' then
      v_artifact_type_code:='MANAGEMENT_WORKBOOK';
      v_artifact_status:='in_preparation';
      v_version_status:='draft';
    when 'ART-PMVV-RV02' then
      v_artifact_type_code:='EXECUTIVE_PRESENTATION';
      v_artifact_status:='validated';
      v_version_status:='approved';
    when 'ART-PMVV-V23' then
      v_artifact_type_code:='PHASE_TRANSITION_PROTOCOL';
      v_artifact_status:='submitted';
      v_version_status:='submitted';
    else
      raise exception using errcode='55000',
        message='Código de artefato histórico não possui classificação canônica determinística.';
  end case;

  select id into v_artifact_type_id
  from public.sparks_methodology_artifact_types
  where module_code='SK-PE'
    and artifact_type_code=v_artifact_type_code
    and active=true;

  if v_artifact_type_id is null then
    raise exception using errcode='55000',
      message='Tipo canônico de artefato metodológico não está ativo.';
  end if;

  select id into v_artifact_id
  from public.sparks_methodology_artifacts
  where organization_id=v_request.organization_id
    and project_id=v_request.project_id
    and external_id=v_source_code
  order by created_at
  limit 1;

  if v_artifact_id is not null then
    if not exists(
      select 1
      from public.sparks_methodology_artifacts a
      where a.id=v_artifact_id
        and a.artifact_type_id=v_artifact_type_id
    ) then
      raise exception using errcode='55000',
        message='Artefato histórico já existe com tipo canônico incompatível.';
    end if;

    return v_artifact_id;
  end if;

  insert into public.sparks_methodology_artifacts(
    organization_id,
    project_id,
    module_code,
    artifact_type_id,
    artifact_code,
    title,
    purpose,
    status,
    current_version_number,
    external_id,
    source,
    metadata,
    created_by,
    updated_by
  )
  values(
    v_request.organization_id,
    v_request.project_id,
    'SK-PE',
    v_artifact_type_id,
    'HIST-'||v_source_code,
    v_source_title,
    'Artefato histórico incorporado da jornada COOTAQUARA; conteúdo binário original não foi recriado pela importação.',
    v_artifact_status,
    1,
    v_source_code,
    'COOTAQUARA historical workbook v26',
    jsonb_build_object(
      'historical_import',true,
      'source_batch_id',v_record.batch_id,
      'source_import_record_id',v_record.id,
      'source_sheet',v_record.source_sheet,
      'source_row',v_record.source_row,
      'source_artifact_code',v_source_code,
      'source_artifact_type',v_source_type,
      'source_status',v_source_status,
      'source_version_label',v_source_version,
      'source_date',v_source_date,
      'source_repository_reference',v_source_file,
      'canonical_type_code',v_artifact_type_code,
      'canonical_version_started_at',1,
      'synthetic_intermediate_versions_created',false,
      'binary_file_recreated',false,
      'semantic_inference',false
    ),
    p_materialized_by_user_id,
    p_materialized_by_user_id
  )
  returning id into v_artifact_id;

  if v_source_file is not null and position('.' in v_source_file)>0 then
    v_file_extension:=lower(split_part(v_source_file,'.',array_length(string_to_array(v_source_file,'.'),1)));
  else
    v_file_extension:=null;
  end if;

  insert into public.sparks_methodology_artifact_versions(
    artifact_id,
    version_number,
    version_label,
    version_status,
    content_json,
    file_name,
    file_extension,
    change_summary,
    generated_by_ai,
    issued_at,
    created_by
  )
  values(
    v_artifact_id,
    1,
    'v1',
    v_version_status,
    jsonb_build_object(
      'historical_source_payload',v_record.values_json,
      'source_version_label',v_source_version,
      'source_status',v_source_status,
      'source_date',v_source_date,
      'source_repository_reference',v_source_file,
      'binary_content_available',false,
      'import_note','Primeira versão canônica criada a partir de metadados históricos; o arquivo original não foi recriado.'
    ),
    case when v_source_file is not null then v_source_file else null end,
    v_file_extension,
    'Incorporação governada de artefato histórico '||v_source_code||
      coalesce(' ('||v_source_version||')','')||'.',
    false,
    case when v_artifact_status in ('submitted','validated') then timezone('utc',now()) else null end,
    p_materialized_by_user_id
  )
  returning id into v_version_id;

  insert into public.sparks_methodology_artifact_audit(
    organization_id,
    project_id,
    artifact_id,
    artifact_version_id,
    actor_user_id,
    action_code,
    action_description,
    new_data,
    metadata
  )
  values(
    v_request.organization_id,
    v_request.project_id,
    v_artifact_id,
    v_version_id,
    p_materialized_by_user_id,
    'HISTORICAL_ARTIFACT_IMPORTED',
    'Artefato metodológico histórico incorporado pelo runtime governado sem recriação do arquivo binário.',
    jsonb_build_object(
      'artifact_code','HIST-'||v_source_code,
      'external_id',v_source_code,
      'artifact_type_code',v_artifact_type_code,
      'canonical_version_number',1,
      'canonical_version_label','v1',
      'source_version_label',v_source_version,
      'source_status',v_source_status,
      'artifact_status',v_artifact_status,
      'version_status',v_version_status
    ),
    jsonb_build_object(
      'import_record_id',v_record.id,
      'incorporation_request_id',v_request.id,
      'incorporation_decision_id',v_decision.id,
      'target_resolution_event_id',v_resolution.id,
      'historical_import',true,
      'synthetic_intermediate_versions_created',false,
      'binary_file_recreated',false,
      'semantic_inference',false
    )||p_metadata
  );

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values(
    v_record.batch_id,
    v_record.organization_id,
    v_record.project_id,
    p_materialized_by_user_id,
    'METHODOLOGY_ARTIFACT_MATERIALIZED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'incorporationDecisionId',v_decision.id,
      'targetResolutionEventId',v_resolution.id,
      'artifactId',v_artifact_id,
      'artifactVersionId',v_version_id,
      'sourceArtifactCode',v_source_code,
      'canonicalArtifactType',v_artifact_type_code,
      'sourceVersionLabel',v_source_version,
      'canonicalVersionNumber',1,
      'syntheticIntermediateVersionsCreated',false,
      'binaryFileRecreated',false,
      'semanticInference',false
    )||p_metadata
  );

  return v_artifact_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_methodology_artifact(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_materialize_import_request_as_methodology_artifact(uuid,text,uuid,jsonb)
to service_role;

do $$
declare
  v_catalog_id uuid;
  v_version_id uuid;
begin
  select id into v_catalog_id
  from public.skpe_incorporation_mapping_catalogs
  where mapping_code='methodology_artifact_to_canonical_artifact';

  if v_catalog_id is null then
    insert into public.skpe_incorporation_mapping_catalogs(
      mapping_code,mapping_name,description,source_entity_code,target_entity_type,
      resolution_strategy,materialization_strategy,provenance_strategy,
      requires_human_review,allows_create_new,allows_existing_entity,
      allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
    )
    values(
      'methodology_artifact_to_canonical_artifact',
      'Artefato metodológico histórico → autoridade canônica de artefatos',
      'Cria artefatos metodológicos canônicos somente para códigos históricos com classificação explícita e preserva a versão do arquivo de origem sem fabricar versões intermediárias.',
      'methodology_artifact','methodology_artifact',
      'create_new_entity','direct_entity','a1_object_and_fields',
      true,true,true,false,'active',1,
      jsonb_build_object(
        'deterministic_type_map',jsonb_build_object(
          'PEM-02.SGE-01','MANAGEMENT_WORKBOOK',
          'ART-PMVV-RV02','EXECUTIVE_PRESENTATION',
          'ART-PMVV-V23','PHASE_TRANSITION_PROTOCOL'
        ),
        'historical_source_version_preserved',true,
        'canonical_version_starts_at',1,
        'synthetic_intermediate_versions_created',false,
        'binary_file_recreated',false,
        'semantic_inference',false
      ),
      100,
      jsonb_build_object('module','SK-PE','semantic_family','methodology_artifact')
    )
    returning id into v_catalog_id;
  else
    update public.skpe_incorporation_mapping_catalogs
    set status='active',
        current_version=1,
        allows_create_new=true,
        allows_existing_entity=true,
        allows_semantic_inference=false,
        metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
          'deterministic_type_map',jsonb_build_object(
            'PEM-02.SGE-01','MANAGEMENT_WORKBOOK',
            'ART-PMVV-RV02','EXECUTIVE_PRESENTATION',
            'ART-PMVV-V23','PHASE_TRANSITION_PROTOCOL'
          ),
          'historical_source_version_preserved',true,
          'canonical_version_starts_at',1,
          'synthetic_intermediate_versions_created',false,
          'binary_file_recreated',false,
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
      'sparks_methodology_artifacts','create_new_entity','methodology_artifact:{codigo}',
      'skpe_execute_import_resolution_rules',
      'skpe_materialize_import_request_as_methodology_artifact',
      null,
      jsonb_build_object(
        'requires_human_review',true,
        'allows_semantic_inference',false,
        'require_valid_import_record',true,
        'require_approved_incorporation_items',true,
        'require_governed_incorporation_decision',true
      ),
      jsonb_build_object(
        'type_map',jsonb_build_object(
          'PEM-02.SGE-01','MANAGEMENT_WORKBOOK',
          'ART-PMVV-RV02','EXECUTIVE_PRESENTATION',
          'ART-PMVV-V23','PHASE_TRANSITION_PROTOCOL'
        ),
        'source_key','codigo',
        'source_title','artefato',
        'source_version','versao',
        'source_status','status',
        'source_file_reference','local_repositorio',
        'canonical_version_policy','start_at_v1_preserve_source_label_in_metadata',
        'binary_file_policy','metadata_only_until_original_file_is_available'
      ),
      timezone('utc',now()),
      jsonb_build_object(
        'historical_artifact_import',true,
        'common_finalizer','skpe_finalize_governed_import_materialization'
      )
    )
    returning id into v_version_id;
  end if;

  if not exists(
    select 1
    from public.skpe_incorporation_resolution_rules
    where mapping_version_id=v_version_id
      and rule_code='methodology_artifact_create_by_historical_code'
  ) then
    insert into public.skpe_incorporation_resolution_rules(
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
      output_key,depends_on_rule_code
    )
    values(
      v_version_id,1,'methodology_artifact_create_by_historical_code','custom','codigo',
      'methodology_artifact','exists',null,'{}'::jsonb,true,false,
      jsonb_build_object(
        'deterministic_source_key',true,
        'semantic_inference',false
      ),
      'create_new_entity_by_source_key',
      jsonb_build_object(
        'target_external_key_template','methodology_artifact:{source_value}',
        'resolution_status','resolved',
        'resolution_mode','create_new_entity',
        'requires_human_review',true
      ),
      'terminal','canonical_target',null
    );
  end if;
end $$;

alter function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
rename to skpe_execute_governed_import_materialization_initiative_input_v1;

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

  if v_record.entity_code <> 'methodology_artifact' then
    return public.skpe_execute_governed_import_materialization_initiative_input_v1(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,p_metadata
    );
  end if;

  if v_request.request_status='applied' then
    begin
      v_entity_id:=nullif(v_request.metadata->>'materialized_target_entity_id','')::uuid;
    exception when invalid_text_representation then
      raise exception using errcode='55000',
        message='Request methodology_artifact applied possui materialized_target_entity_id inválido.';
    end;

    if v_request.metadata->>'materialized_target_entity_type' <> 'methodology_artifact'
       or v_entity_id is null
       or not exists(
         select 1
         from public.sparks_methodology_artifacts
         where id=v_entity_id
           and organization_id=v_request.organization_id
           and project_id=v_request.project_id
       ) then
      raise exception using errcode='55000',
        message='Request methodology_artifact applied não possui alvo materializado verificável.';
    end if;

    return jsonb_build_object(
      'request_id',v_request.id,
      'import_record_id',v_record.id,
      'source_family','methodology_artifact',
      'handler_name','skpe_materialize_import_request_as_methodology_artifact',
      'materialized_entity_type','methodology_artifact',
      'materialized_entity_id',v_entity_id,
      'request_status','applied',
      'already_materialized',true,
      'already_finalized',true,
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1'
    );
  end if;

  v_entity_id:=public.skpe_materialize_import_request_as_methodology_artifact(
    p_request_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1',
      'historical_artifact_import',true,
      'semantic_inference',false
    )
  );

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,
    'methodology_artifact',
    v_entity_id,
    p_materialized_by_actor_type,
    p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1',
      'handler_name','skpe_materialize_import_request_as_methodology_artifact',
      'historical_artifact_import',true,
      'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family','methodology_artifact',
    'handler_name','skpe_materialize_import_request_as_methodology_artifact',
    'materialized_entity_type','methodology_artifact',
    'materialized_entity_id',v_entity_id,
    'request_status','applied',
    'already_materialized',false,
    'already_finalized',false,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
to service_role;
