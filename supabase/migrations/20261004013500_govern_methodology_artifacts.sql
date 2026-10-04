-- SK-PE - Govern historical methodology artifacts as canonical methodological records.
-- Technical incorporation preserves historical status/version without re-validating institutionally.

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
  v_items jsonb := '{}'::jsonb;
  v_inferred_count integer := 0;
  v_invalid_target_count integer := 0;
  v_code text;
  v_title text;
  v_source_type text;
  v_source_status text;
  v_version_label text;
  v_version_number integer;
  v_source_date text;
  v_repo text;
  v_artifact_type_code text;
  v_artifact_type_id uuid;
  v_existing_id uuid;
  v_artifact_id uuid;
  v_metadata jsonb;
begin
  if p_request_id is null then
    raise exception using errcode='22023',message='p_request_id é obrigatório.';
  end if;

  if p_metadata is null or jsonb_typeof(p_metadata) <> 'object' then
    raise exception using errcode='22023',message='p_metadata deve ser objeto JSON.';
  end if;

  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=p_request_id;

  select * into v_record
  from public.skpe_import_records
  where id=v_request.import_record_id;

  if v_record.id is null or v_record.entity_code <> 'methodology_artifact' then
    raise exception using errcode='55000',message='Materializador exige entity_code = methodology_artifact.';
  end if;

  if v_record.quality_status <> 'valid' then
    raise exception using errcode='55000',message='Artefato histórico precisa possuir quality_status = valid.';
  end if;

  select * into v_decision
  from public.skpe_import_incorporation_decisions d
  where d.incorporation_request_id=v_request.id
  order by d.decision_sequence desc
  limit 1;

  if v_decision.id is null
     or v_decision.permits_incorporation <> true
     or v_decision.decision_outcome not in ('approved','approved_with_reservations') then
    raise exception using errcode='55000',message='Decisão vigente não permite materialização do artefato.';
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
    and e.target_entity_id is null
    and nullif(btrim(e.target_external_key),'') is not null
    and coalesce(jsonb_array_length(e.blockers),0)=0
  order by e.resolution_sequence desc,e.resolved_at desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000',message='Não existe resolução declarativa válida para criação do artefato.';
  end if;

  select
    coalesce(
      jsonb_object_agg(
        source_field_name,
        coalesce(normalized_value,original_value)
        order by item_sequence
      ),
      '{}'::jsonb
    ),
    count(*) filter(where extraction_mode='inferred'),
    count(*) filter(
      where coalesce(target_entity_type,'') <> 'methodology_artifact'
         or coalesce(target_resolution_mode,'') <> 'create_new_entity'
         or coalesce(target_resolution_state,'') not in ('pending_creation','resolved')
    )
  into v_items,v_inferred_count,v_invalid_target_count
  from public.skpe_import_incorporation_items
  where incorporation_request_id=v_request.id;

  if v_inferred_count <> 0 then
    raise exception using errcode='55000',message='Mapping de artefato não aceita itens inferidos.';
  end if;

  if v_invalid_target_count <> 0 then
    raise exception using errcode='55000',message='Há itens de artefato com declaração de destino incompatível.';
  end if;

  v_code:=nullif(btrim(v_items->>'codigo'),'');
  v_title:=nullif(btrim(v_items->>'artefato'),'');
  v_source_type:=nullif(btrim(v_items->>'tipo'),'');
  v_source_status:=nullif(btrim(v_items->>'status'),'');
  v_version_label:=nullif(btrim(v_items->>'versao'),'');
  v_source_date:=nullif(btrim(v_items->>'data'),'');
  v_repo:=nullif(btrim(v_items->>'local_repositorio'),'');

  if v_code is null or v_title is null or v_source_type is null then
    raise exception using errcode='55000',message='Artefato histórico não possui código, título e tipo mínimos.';
  end if;

  if v_resolution.target_external_key <> v_code then
    raise exception using errcode='55000',message='Resolução do artefato não corresponde ao código histórico revisado.';
  end if;

  case lower(v_source_type)
    when 'xlsx' then
      v_artifact_type_code:='MANAGEMENT_WORKBOOK';
    when 'apresentação executiva / base aprovada' then
      v_artifact_type_code:='EXECUTIVE_PRESENTATION';
    when 'kit de encerramento' then
      v_artifact_type_code:='PHASE_TRANSITION_PROTOCOL';
    else
      raise exception using
        errcode='55000',
        message='Tipo histórico de artefato ainda não possui classificação canônica determinística.';
  end case;

  select id into v_artifact_type_id
  from public.sparks_methodology_artifact_types
  where module_code='SK-PE'
    and artifact_type_code=v_artifact_type_code
    and active=true
  limit 1;

  if v_artifact_type_id is null then
    raise exception using errcode='55000',message='Tipo canônico de artefato não está ativo.';
  end if;

  if v_version_label is null or v_version_label !~* '^v[0-9]+$' then
    raise exception using errcode='55000',message='Versão histórica não atende ao formato vN esperado.';
  end if;

  v_version_number:=substring(v_version_label from '[0-9]+')::integer;

  select id into v_existing_id
  from public.sparks_methodology_artifacts
  where organization_id=v_request.organization_id
    and project_id=v_request.project_id
    and artifact_code=v_code
  limit 1;

  if v_existing_id is not null then
    if exists(
      select 1
      from public.sparks_methodology_artifacts a
      join public.sparks_methodology_artifact_versions av on av.artifact_id=a.id
      where a.id=v_existing_id
        and (a.metadata->>'source_import_record_id')=v_record.id::text
        and av.version_number=v_version_number
    ) then
      return v_existing_id;
    end if;

    raise exception using
      errcode='23505',
      message='Já existe artefato canônico com o mesmo código neste projeto, proveniente de outro fluxo.';
  end if;

  v_metadata:=jsonb_strip_nulls(jsonb_build_object(
    'source_import_record_id',v_record.id,
    'incorporation_request_id',v_request.id,
    'incorporation_decision_id',v_decision.id,
    'target_resolution_event_id',v_resolution.id,
    'source_external_key',v_record.external_key,
    'historical_status',v_source_status,
    'historical_version_label',v_version_label,
    'historical_date',v_source_date,
    'historical_repository',v_repo,
    'historical_status_promoted',false,
    'institutional_validation_performed',false,
    'technical_incorporation',true,
    'semantic_inference',false,
    'materialized_by_actor_type',p_materialized_by_actor_type,
    'materialized_by_user_id',p_materialized_by_user_id,
    'materialized_at',timezone('utc',now())
  ))||p_metadata;

  insert into public.sparks_methodology_artifacts(
    organization_id,
    project_id,
    module_code,
    artifact_type_id,
    artifact_code,
    title,
    macrophase_code,
    phase_code,
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
    v_code,
    v_title,
    case when v_record.values_json->>'macrofase'='MF2' then 'PEM-02' else null end,
    case
      when v_code like 'ART-PMVV-%' then 'PEM-02.03'
      when v_code like 'PEM-02.SGE-%' then 'PEM-02'
      else null
    end,
    'in_review',
    v_version_number,
    v_record.external_key,
    'historical_workbook_import',
    v_metadata,
    p_materialized_by_user_id,
    p_materialized_by_user_id
  )
  returning id into v_artifact_id;

  insert into public.sparks_methodology_artifact_versions(
    artifact_id,
    version_number,
    version_label,
    version_status,
    content_json,
    file_name,
    change_summary,
    generated_by_ai,
    issued_at,
    created_by
  )
  values(
    v_artifact_id,
    v_version_number,
    v_version_label,
    'review',
    jsonb_build_object(
      'historical_payload',v_record.values_json,
      'historical_status',v_source_status,
      'historical_status_promoted',false,
      'institutional_validation_performed',false
    ),
    v_repo,
    'Versão histórica incorporada tecnicamente; validação institucional não promovida pela importação.',
    false,
    case
      when v_source_date ~ '^([0-9]{2})/([0-9]{2})/([0-9]{4})$'
      then to_timestamp(v_source_date,'DD/MM/YYYY')
      else null
    end,
    p_materialized_by_user_id
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
      'materializedEntityId',v_artifact_id,
      'artifactCode',v_code,
      'artifactTypeCode',v_artifact_type_code,
      'versionNumber',v_version_number,
      'historicalStatus',v_source_status,
      'historicalStatusPromoted',false,
      'institutionalValidationPerformed',false,
      'semanticInference',false
    )
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
      'Artefato metodológico histórico → artefato canônico',
      'Materializa artefatos históricos do SK-PE como registros metodológicos canônicos, preservando versão e status histórico sem promover validação institucional.',
      'methodology_artifact','methodology_artifact',
      'create_new_entity','direct_entity','a1_object_and_fields',
      true,true,false,false,'active',1,
      jsonb_build_object(
        'historical_status_promoted',false,
        'institutional_validation_performed',false,
        'technical_incorporation',true,
        'semantic_inference',false
      ),
      100,
      jsonb_build_object('module','SK-PE','semantic_family','methodology_artifact')
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
      'sparks_methodology_artifacts','source_key','{codigo}',
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
        'target_resolution','create_new_methodology_artifact_by_code',
        'historical_status_policy','preserve_without_promotion',
        'field_map',jsonb_build_object(
          'codigo','artifact_code',
          'artefato','title',
          'tipo','artifact_type_classifier',
          'status','historical_status',
          'versao','historical_version',
          'data','historical_date',
          'local_repositorio','historical_repository'
        )
      ),
      timezone('utc',now()),
      jsonb_build_object(
        'technical_incorporation',true,
        'common_finalizer','skpe_finalize_governed_import_materialization'
      )
    )
    returning id into v_version_id;
  end if;

  if not exists(
    select 1
    from public.skpe_incorporation_resolution_rules
    where mapping_version_id=v_version_id
      and rule_code='methodology_artifact_create_new'
  ) then
    insert into public.skpe_incorporation_resolution_rules(
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,execution_mode,
      output_key,depends_on_rule_code
    )
    values(
      v_version_id,1,'methodology_artifact_create_new','custom','codigo',
      'methodology_artifact','exists',null,'{}'::jsonb,true,false,
      jsonb_build_object('semantic_inference',false),
      'create_new_entity_by_source_key',
      jsonb_build_object('source_key_field','codigo'),
      'terminal','canonical_target',null
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

  if v_record.entity_code not in (
    'key_result','pestel','swot','tows','risk',
    'strategic_identity','living_value','pmvv_validation',
    'version_control','living_governance','project','journey',
    'initiative','project_portfolio','methodology_artifact'
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
  elsif v_record.entity_code in ('version_control','living_governance') then
    v_target_type:='import_batch_provenance';
    v_handler:='skpe_materialize_import_request_as_batch_provenance';
  elsif v_record.entity_code in ('project','journey') then
    v_target_type:='project_context_provenance';
    v_handler:='skpe_materialize_import_request_as_project_context_provenance';
  elsif v_record.entity_code in ('initiative','project_portfolio') then
    v_target_type:='approved_initiative_input_provenance';
    v_handler:='skpe_materialize_import_request_as_approved_initiative_input';
  else
    v_target_type:='methodology_artifact';
    v_handler:='skpe_materialize_import_request_as_methodology_artifact';
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
    if v_record.entity_code in ('project','journey','initiative','project_portfolio')
       and not exists(
         select 1 from public.skpe_projects
         where id=v_entity_id
           and organization_id=v_request.organization_id
       ) then
      raise exception using errcode='55000',message='Request ancorado no projeto não possui projeto canônico verificável.';
    end if;
    if v_record.entity_code='methodology_artifact'
       and not exists(
         select 1 from public.sparks_methodology_artifacts
         where id=v_entity_id
           and project_id=v_request.project_id
           and organization_id=v_request.organization_id
       ) then
      raise exception using errcode='55000',message='Request de artefato applied não possui artefato canônico verificável.';
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
      'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1'
    );
  end if;

  if v_record.entity_code='key_result' then
    v_entity_id:=public.skpe_materialize_import_request_as_key_result(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1')
    );
  elsif v_record.entity_code='pestel' then
    v_entity_id:=public.skpe_materialize_import_request_as_pestel(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1')
    );
  elsif v_record.entity_code='swot' then
    v_entity_id:=public.skpe_materialize_import_request_as_swot(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1')
    );
  elsif v_record.entity_code='tows' then
    v_entity_id:=public.skpe_materialize_import_request_as_tows(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1')
    );
  elsif v_record.entity_code='risk' then
    v_entity_id:=public.skpe_materialize_import_request_as_strategic_risk(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object('dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1')
    );
  elsif v_record.entity_code in ('strategic_identity','living_value') then
    v_entity_id:=public.skpe_materialize_import_request_as_existing_reference(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1',
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
        'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1',
        'reconciliation_only',true,
        'historical_validation_preserved',true,
        'business_content_updated',false,
        'business_approval_reopened',false,
        'semantic_inference',false
      )
    );
  elsif v_record.entity_code in ('version_control','living_governance') then
    v_entity_id:=public.skpe_materialize_import_request_as_batch_provenance(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1',
        'evidence_only',true,
        'historical_provenance_only',true,
        'business_entity_created',false,
        'business_content_updated',false,
        'semantic_inference',false
      )
    );
  elsif v_record.entity_code in ('project','journey') then
    v_entity_id:=public.skpe_materialize_import_request_as_project_context_provenance(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1',
        'evidence_only',true,
        'project_context_only',true,
        'legacy_journey_model',v_record.entity_code='journey',
        'canonical_project_updated',false,
        'canonical_journey_updated',false,
        'semantic_inference',false
      )
    );
  elsif v_record.entity_code in ('initiative','project_portfolio') then
    v_entity_id:=public.skpe_materialize_import_request_as_approved_initiative_input(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1',
        'historical_business_approval_preserved',true,
        'approved_directional_input',true,
        'future_development_stage','strategic_initiatives',
        'canonical_initiative_created',false,
        'canonical_initiative_updated',false,
        'semantic_matching_performed',false,
        'semantic_inference',false
      )
    );
  else
    v_entity_id:=public.skpe_materialize_import_request_as_methodology_artifact(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1',
        'historical_status_promoted',false,
        'institutional_validation_performed',false,
        'technical_incorporation',true,
        'semantic_inference',false
      )
    );
  end if;

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,v_target_type,v_entity_id,
    p_materialized_by_actor_type,p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1',
      'handler_name',v_handler,
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
    'dispatcher_version','COOTAQUARA-METHODOLOGY-ARTIFACT-V1'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
from public,anon,authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb)
to service_role;
