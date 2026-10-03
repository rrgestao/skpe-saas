-- ============================================================
-- SPARKs PE - Governed SWOT incorporation mapping
-- Source: historical import entity_code = swot
-- Target: public.skpe_swot_items
-- No automatic materialization is performed by this migration.
-- ============================================================

create or replace function public.skpe_materialize_import_request_as_swot(
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
  v_quadrant text;
  v_factor text;
  v_evidence_description text;
  v_impact text;
  v_priority text;
  v_owner text;
  v_origin_pestel_text text;
  v_evidence_text text;

  v_origin_pestel_codes text[] := '{}';
  v_evidence_references text[] := '{}';

  v_existing_id uuid;
  v_swot_id uuid;
  v_metadata jsonb;
begin
  if p_request_id is null then
    raise exception using errcode='22023', message='p_request_id é obrigatório.';
  end if;

  if p_materialized_by_actor_type not in (
    'organization','sparks_consultancy','external_consultancy','system','ai','unknown'
  ) then
    raise exception using errcode='22023', message='p_materialized_by_actor_type inválido.';
  end if;

  if p_metadata is null or jsonb_typeof(p_metadata) <> 'object' then
    raise exception using errcode='22023', message='p_metadata deve ser objeto JSON.';
  end if;

  perform public.skpe_assert_governed_import_materialization(p_request_id);

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id = p_request_id;

  select * into v_record
  from public.skpe_import_records
  where id = v_request.import_record_id;

  if v_record.id is null or v_record.entity_code <> 'swot' then
    raise exception using errcode='55000', message='Materializador SWOT exige entity_code = swot.';
  end if;

  if v_record.quality_status <> 'valid' then
    raise exception using errcode='55000', message='ImportRecord SWOT precisa possuir quality_status = valid.';
  end if;

  select * into v_decision
  from public.skpe_import_incorporation_decisions d
  where d.incorporation_request_id = v_request.id
  order by d.decision_sequence desc
  limit 1;

  if v_decision.id is null
     or v_decision.permits_incorporation <> true
     or v_decision.decision_outcome not in ('approved','approved_with_reservations') then
    raise exception using errcode='55000', message='Decisão vigente não permite materialização SWOT.';
  end if;

  select * into v_resolution
  from public.skpe_import_target_resolution_events e
  where e.import_record_id = v_record.id
    and e.organization_id = v_request.organization_id
    and e.project_id = v_request.project_id
    and e.formulation_id is not distinct from v_request.formulation_id
    and e.source_entity_code = 'swot'
    and e.target_entity_type = 'swot_item'
    and e.resolution_status = 'resolved'
    and e.resolution_mode = 'create_new_entity'
    and e.target_entity_id is null
    and nullif(btrim(e.target_external_key),'') is not null
    and coalesce(jsonb_array_length(e.blockers),0) = 0
  order by e.resolution_sequence desc, e.resolved_at desc
  limit 1;

  if v_resolution.id is null then
    raise exception using errcode='55000', message='Não existe resolução declarativa válida para criação do item SWOT.';
  end if;

  select
    coalesce(
      jsonb_object_agg(
        source_field_name,
        coalesce(normalized_value, original_value)
        order by item_sequence
      ),
      '{}'::jsonb
    ),
    count(*) filter (where extraction_mode = 'inferred'),
    count(*) filter (
      where coalesce(target_entity_type,'') <> 'swot_item'
         or coalesce(target_resolution_mode,'') <> 'create_new_entity'
         or coalesce(target_resolution_state,'') not in ('pending_creation','resolved')
    )
  into v_items, v_inferred_count, v_invalid_target_count
  from public.skpe_import_incorporation_items
  where incorporation_request_id = v_request.id;

  if v_inferred_count <> 0 then
    raise exception using errcode='55000', message='Mapping SWOT não aceita Incorporation Items inferred.';
  end if;

  if v_invalid_target_count <> 0 then
    raise exception using errcode='55000', message='Há Incorporation Items SWOT com declaração de destino incompatível.';
  end if;

  v_code := nullif(btrim(v_items ->> 'codigo'),'');
  v_quadrant := nullif(btrim(v_items ->> 'quadrante'),'');
  v_factor := nullif(btrim(v_items ->> 'fator'),'');
  v_evidence_description := nullif(btrim(v_items ->> 'descricao_evidencia'),'');
  v_impact := nullif(btrim(v_items ->> 'impacto'),'');
  v_priority := nullif(btrim(v_items ->> 'prioridade'),'');
  v_owner := nullif(btrim(v_items ->> 'responsavel'),'');
  v_origin_pestel_text := nullif(btrim(v_items ->> 'origem_pestel'),'');
  v_evidence_text := nullif(btrim(v_items ->> 'evidencias_relacionadas'),'');

  if v_code is null or v_quadrant is null or v_factor is null then
    raise exception using errcode='55000', message='SWOT histórico não possui codigo, quadrante e fator mínimos.';
  end if;

  if v_resolution.target_external_key <> v_code then
    raise exception using errcode='55000', message='Resolução SWOT não corresponde ao código histórico revisado.';
  end if;

  if v_code !~ '^SW-[FOTW][0-9]{2}$' then
    raise exception using errcode='55000', message='Código SWOT não atende ao formato canônico esperado.';
  end if;

  if v_origin_pestel_text is not null then
    select coalesce(array_agg(distinct btrim(value) order by btrim(value)),'{}'::text[])
    into v_origin_pestel_codes
    from regexp_split_to_table(v_origin_pestel_text, '[,;/]+') x(value)
    where nullif(btrim(value),'') is not null;
  end if;

  if v_evidence_text is not null then
    select coalesce(array_agg(distinct btrim(value) order by btrim(value)),'{}'::text[])
    into v_evidence_references
    from regexp_split_to_table(v_evidence_text, '[,;/]+') x(value)
    where nullif(btrim(value),'') is not null;
  end if;

  select id into v_existing_id
  from public.skpe_swot_items
  where source_import_record_id = v_record.id
  limit 1;

  if v_existing_id is not null then
    return v_existing_id;
  end if;

  select id into v_existing_id
  from public.skpe_swot_items
  where organization_id = v_request.organization_id
    and project_id = v_request.project_id
    and lower(btrim(code)) = lower(v_code)
    and archived_at is null
  limit 1;

  if v_existing_id is not null then
    raise exception using
      errcode='23505',
      message='Já existe item SWOT com o mesmo código neste projeto, proveniente de outro fluxo.';
  end if;

  v_metadata :=
    jsonb_strip_nulls(
      jsonb_build_object(
        'import_record_id', v_record.id,
        'incorporation_request_id', v_request.id,
        'incorporation_decision_id', v_decision.id,
        'incorporation_decision_sequence', v_decision.decision_sequence,
        'target_resolution_event_id', v_resolution.id,
        'source_external_key', v_record.external_key,
        'source_status', nullif(btrim(v_record.values_json ->> 'status'),''),
        'historical_status_promoted', false,
        'institutional_validation_pending', true,
        'technical_incorporation', true,
        'semantic_inference', false,
        'materialized_by_actor_type', p_materialized_by_actor_type,
        'materialized_by_user_id', p_materialized_by_user_id,
        'materialized_at', timezone('utc',now())
      )
    )
    || p_metadata;

  insert into public.skpe_swot_items (
    organization_id, project_id, code, quadrant, factor,
    evidence_description, impact_label, priority, owner_label,
    origin_pestel_codes, evidence_references,
    status, validation_status,
    source_import_record_id, source_external_key, source_sheet, source_row,
    source_payload, metadata, created_by, updated_by
  )
  values (
    v_request.organization_id, v_request.project_id, v_code, v_quadrant, v_factor,
    v_evidence_description, v_impact, v_priority, v_owner,
    v_origin_pestel_codes, v_evidence_references,
    'draft', 'draft',
    v_record.id, v_record.external_key, v_record.source_sheet, v_record.source_row,
    v_record.values_json, v_metadata, p_materialized_by_user_id, p_materialized_by_user_id
  )
  returning id into v_swot_id;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,actor_user_id,event_code,event_data
  )
  values (
    v_record.batch_id,v_record.organization_id,v_record.project_id,p_materialized_by_user_id,
    'SWOT_ITEM_MATERIALIZED',
    jsonb_build_object(
      'importRecordId',v_record.id,
      'incorporationRequestId',v_request.id,
      'materializedEntityId',v_swot_id,
      'code',v_code,
      'institutionalValidation',false,
      'semanticInference',false
    )
  );

  return v_swot_id;
end;
$function$;

revoke all on function public.skpe_materialize_import_request_as_swot(uuid,text,uuid,jsonb) from public;
revoke all on function public.skpe_materialize_import_request_as_swot(uuid,text,uuid,jsonb) from authenticated;
grant execute on function public.skpe_materialize_import_request_as_swot(uuid,text,uuid,jsonb) to service_role;

do $$
declare
  v_catalog_id uuid;
  v_version_id uuid;
begin
  select id into v_catalog_id
  from public.skpe_incorporation_mapping_catalogs
  where mapping_code = 'swot_to_swot_item';

  if v_catalog_id is null then
    insert into public.skpe_incorporation_mapping_catalogs (
      mapping_code,mapping_name,description,source_entity_code,target_entity_type,
      resolution_strategy,materialization_strategy,provenance_strategy,
      requires_human_review,allows_create_new,allows_existing_entity,
      allows_semantic_inference,status,current_version,metadata,selection_priority,applicability
    )
    values (
      'swot_to_swot_item',
      'SWOT histórico para item SWOT canônico',
      'Incorpora fatores SWOT históricos no Diagnóstico Estratégico canônico com revisão humana, resolução determinística por código e proveniência integral.',
      'swot','swot_item','create_new','direct_entity','a1_object',
      true,true,false,false,'active',1,
      jsonb_build_object(
        'roadmap_step','COOTAQUARA-MAPPING-SWOT-V1',
        'methodology_rule','Conteúdo histórico é incorporado tecnicamente como draft e não equivale a validação institucional.',
        'semantic_inference',false
      ),
      100,
      jsonb_build_object(
        'module','SK-PE','semantic_family','swot','canonical_target','skpe_swot_items'
      )
    )
    returning id into v_catalog_id;
  else
    update public.skpe_incorporation_mapping_catalogs
    set mapping_name='SWOT histórico para item SWOT canônico',
        description='Incorpora fatores SWOT históricos no Diagnóstico Estratégico canônico com revisão humana, resolução determinística por código e proveniência integral.',
        source_entity_code='swot',
        target_entity_type='swot_item',
        resolution_strategy='create_new',
        materialization_strategy='direct_entity',
        provenance_strategy='a1_object',
        requires_human_review=true,
        allows_create_new=true,
        allows_existing_entity=false,
        allows_semantic_inference=false,
        status='active',
        current_version=1,
        selection_priority=100,
        applicability=jsonb_build_object(
          'module','SK-PE','semantic_family','swot','canonical_target','skpe_swot_items'
        ),
        metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
          'roadmap_step','COOTAQUARA-MAPPING-SWOT-V1',
          'methodology_rule','Conteúdo histórico é incorporado tecnicamente como draft e não equivale a validação institucional.',
          'semantic_inference',false
        )
    where id=v_catalog_id;
  end if;

  select id into v_version_id
  from public.skpe_incorporation_mapping_versions
  where catalog_id=v_catalog_id and version_number=1;

  if v_version_id is null then
    insert into public.skpe_incorporation_mapping_versions (
      catalog_id,version_number,version_status,effective_from,target_table,
      target_key_strategy,target_key_template,resolver_function_name,
      materializer_function_name,provenance_function_name,validation_profile,
      mapping_definition,activated_at,metadata
    )
    values (
      v_catalog_id,1,'active',timezone('utc',now()),'skpe_swot_items',
      'source_external_key','{external_key}',null,
      'skpe_materialize_import_request_as_swot',null,
      jsonb_build_object(
        'requires_human_review',true,
        'allows_semantic_inference',false,
        'require_valid_import_record',true,
        'require_reviewed_import_record',true,
        'require_approved_incorporation_items',true,
        'require_governed_incorporation_decision',true
      ),
      jsonb_build_object(
        'canonical_status','draft',
        'canonical_validation_status','draft',
        'target_resolution','create_new_entity_by_source_key',
        'target_key_field','codigo',
        'historical_status_policy','preserve_in_metadata_only',
        'relationship_code_policy','preserve_tokens_without_semantic_inference',
        'field_map',jsonb_build_object(
          'codigo','code',
          'quadrante','quadrant',
          'fator','factor',
          'descricao_evidencia','evidence_description',
          'impacto','impact_label',
          'prioridade','priority',
          'responsavel','owner_label',
          'origem_pestel','origin_pestel_codes',
          'evidencias_relacionadas','evidence_references'
        )
      ),
      timezone('utc',now()),
      jsonb_build_object(
        'roadmap_step','COOTAQUARA-MAPPING-SWOT-V1',
        'common_finalizer','skpe_finalize_governed_import_materialization',
        'provenance_strategy','source_import_record_columns',
        'semantic_inference',false
      )
    )
    returning id into v_version_id;
  else
    update public.skpe_incorporation_mapping_versions
    set version_status='active',
        effective_from=coalesce(effective_from,timezone('utc',now())),
        effective_until=null,
        target_table='skpe_swot_items',
        target_key_strategy='source_external_key',
        target_key_template='{external_key}',
        resolver_function_name=null,
        materializer_function_name='skpe_materialize_import_request_as_swot',
        provenance_function_name=null,
        validation_profile=jsonb_build_object(
          'requires_human_review',true,
          'allows_semantic_inference',false,
          'require_valid_import_record',true,
          'require_reviewed_import_record',true,
          'require_approved_incorporation_items',true,
          'require_governed_incorporation_decision',true
        ),
        mapping_definition=jsonb_build_object(
          'canonical_status','draft',
          'canonical_validation_status','draft',
          'target_resolution','create_new_entity_by_source_key',
          'target_key_field','codigo',
          'historical_status_policy','preserve_in_metadata_only',
          'relationship_code_policy','preserve_tokens_without_semantic_inference',
          'field_map',jsonb_build_object(
            'codigo','code',
            'quadrante','quadrant',
            'fator','factor',
            'descricao_evidencia','evidence_description',
            'impacto','impact_label',
            'prioridade','priority',
            'responsavel','owner_label',
            'origem_pestel','origin_pestel_codes',
            'evidencias_relacionadas','evidence_references'
          )
        ),
        activated_at=coalesce(activated_at,timezone('utc',now())),
        metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object(
          'roadmap_step','COOTAQUARA-MAPPING-SWOT-V1',
          'common_finalizer','skpe_finalize_governed_import_materialization',
          'provenance_strategy','source_import_record_columns',
          'semantic_inference',false
        )
    where id=v_version_id;
  end if;

  if not exists (
    select 1 from public.skpe_incorporation_resolution_rules
    where mapping_version_id=v_version_id and rule_code='swot_create_new_candidate'
  ) then
    insert into public.skpe_incorporation_resolution_rules (
      mapping_version_id,rule_sequence,rule_code,rule_type,source_field_name,
      target_entity_type,operator,expected_value,resolution_output,is_blocking,
      stop_on_match,metadata,resolver_handler_code,resolver_config,
      execution_mode,output_key,depends_on_rule_code
    )
    values (
      v_version_id,1,'swot_create_new_candidate','custom','codigo',
      'swot_item','exists',null,'{}'::jsonb,true,false,
      jsonb_build_object(
        'purpose','Resolver deterministicamente o candidato canônico do próprio item SWOT.',
        'roadmap_step','COOTAQUARA-MAPPING-SWOT-V1',
        'semantic_inference',false,
        'materializes_entity',false
      ),
      'create_new_entity_by_source_key',
      jsonb_build_object(
        'resolution_mode','create_new_entity',
        'source_key_field','codigo',
        'resolution_status','resolved',
        'requires_human_review',true,
        'requires_existing_target',false,
        'target_external_key_template','{source_value}'
      ),
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

  if v_record.entity_code not in ('key_result','pestel','swot') then
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
  else
    v_target_type:='swot_item';
    v_handler:='skpe_materialize_import_request_as_swot';
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

    return jsonb_build_object(
      'request_id',v_request.id,
      'import_record_id',v_record.id,
      'source_family',v_record.entity_code,
      'handler_name',v_handler,
      'context_target_id',null,
      'materialized_entity_type',v_target_type,
      'materialized_entity_id',v_entity_id,
      'request_status','applied',
      'already_materialized',true,
      'already_finalized',true,
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-DIAG-V2'
    );
  end if;

  if v_record.entity_code='key_result' then
    v_entity_id:=public.skpe_materialize_import_request_as_key_result(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher','skpe_execute_governed_import_materialization',
        'dispatcher_version','COOTAQUARA-DIAG-V2',
        'source_family','key_result','target_family','key_result',
        'technical_incorporation',true,'institutional_validation',false,
        'institutional_validation_pending',true,'semantic_inference',false
      )
    );
  elsif v_record.entity_code='pestel' then
    v_entity_id:=public.skpe_materialize_import_request_as_pestel(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher','skpe_execute_governed_import_materialization',
        'dispatcher_version','COOTAQUARA-DIAG-V2',
        'source_family','pestel','target_family','pestel_item',
        'technical_incorporation',true,'institutional_validation',false,
        'institutional_validation_pending',true,'semantic_inference',false
      )
    );
  else
    v_entity_id:=public.skpe_materialize_import_request_as_swot(
      p_request_id,p_materialized_by_actor_type,p_materialized_by_user_id,
      p_metadata||jsonb_build_object(
        'dispatcher','skpe_execute_governed_import_materialization',
        'dispatcher_version','COOTAQUARA-DIAG-V2',
        'source_family','swot','target_family','swot_item',
        'technical_incorporation',true,'institutional_validation',false,
        'institutional_validation_pending',true,'semantic_inference',false
      )
    );
  end if;

  v_finalize:=public.skpe_finalize_governed_import_materialization(
    p_request_id,v_target_type,v_entity_id,
    p_materialized_by_actor_type,p_materialized_by_user_id,
    p_metadata||jsonb_build_object(
      'dispatcher','skpe_execute_governed_import_materialization',
      'dispatcher_version','COOTAQUARA-DIAG-V2',
      'handler_name',v_handler,
      'technical_incorporation',true,'institutional_validation',false,
      'institutional_validation_pending',true,'semantic_inference',false
    )
  );

  return jsonb_build_object(
    'request_id',v_request.id,
    'import_record_id',v_record.id,
    'source_family',v_record.entity_code,
    'handler_name',v_handler,
    'context_target_id',null,
    'materialized_entity_type',v_target_type,
    'materialized_entity_id',v_entity_id,
    'request_status','applied',
    'already_materialized',false,
    'already_finalized',false,
    'finalization',v_finalize,
    'dispatcher','skpe_execute_governed_import_materialization',
    'dispatcher_version','COOTAQUARA-DIAG-V2'
  );
end;
$function$;

revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb) from public;
revoke all on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb) from authenticated;
grant execute on function public.skpe_execute_governed_import_materialization(uuid,text,uuid,jsonb) to service_role;
