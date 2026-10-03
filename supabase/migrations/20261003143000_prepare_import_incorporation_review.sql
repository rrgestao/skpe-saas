-- ============================================================
-- SPARKs PE - Governed import incorporation review preparation
-- Creates/reuses an incorporation request, resolves the target,
-- materializes review ITEMS from the active mapping field_map,
-- and evaluates the request. It DOES NOT approve or materialize
-- any strategic target entity.
-- Service-role only.
-- ============================================================

create or replace function public.skpe_prepare_import_incorporation_review(
  p_import_record_id uuid,
  p_requested_by_actor_type text,
  p_requested_by_user_id uuid default null,
  p_request_reason text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_record public.skpe_import_records%rowtype;
  v_batch public.skpe_import_batches%rowtype;
  v_request public.skpe_import_incorporation_requests%rowtype;
  v_resolution public.skpe_import_target_resolution_events%rowtype;
  v_version public.skpe_incorporation_mapping_versions%rowtype;
  v_catalog public.skpe_incorporation_mapping_catalogs%rowtype;

  v_request_id uuid;
  v_resolution_event_id uuid;
  v_eligibility text;
  v_source_field text;
  v_target_field text;
  v_original_value jsonb;
  v_information_state text;
  v_items_created integer := 0;
  v_items_existing integer := 0;
  v_item_count integer := 0;
  v_reused_request boolean := false;
begin
  if p_import_record_id is null then
    raise exception using errcode='22023', message='p_import_record_id é obrigatório.';
  end if;

  if p_requested_by_actor_type not in (
    'organization','sparks_consultancy','external_consultancy','system','ai','unknown'
  ) then
    raise exception using errcode='22023', message='p_requested_by_actor_type inválido.';
  end if;

  if p_metadata is null or jsonb_typeof(p_metadata) <> 'object' then
    raise exception using errcode='22023', message='p_metadata deve ser objeto JSON.';
  end if;

  select * into v_record
  from public.skpe_import_records
  where id=p_import_record_id;

  if v_record.id is null then
    raise exception using errcode='22023', message='ImportRecord não encontrado.';
  end if;

  if v_record.quality_status <> 'valid' then
    raise exception using errcode='55000', message='Somente ImportRecord com quality_status = valid pode ser preparado para revisão.';
  end if;

  select * into v_batch
  from public.skpe_import_batches
  where id=v_record.batch_id;

  if v_batch.id is null then
    raise exception using errcode='55000', message='Batch do ImportRecord não encontrado.';
  end if;

  if v_batch.formulation_id is null then
    raise exception using errcode='55000', message='Batch não possui formulation_id.';
  end if;

  if v_batch.ingestion_profile_version_id is null then
    raise exception using errcode='55000', message='Batch não possui perfil de ingestão governado.';
  end if;

  -- Reuse an active request when preparation is retried.
  select * into v_request
  from public.skpe_import_incorporation_requests r
  where r.formulation_id=v_batch.formulation_id
    and r.import_record_id=v_record.id
    and r.request_status not in ('rejected','cancelled','superseded','applied')
  order by r.request_sequence desc
  limit 1;

  if v_request.id is not null then
    v_request_id := v_request.id;
    v_reused_request := true;
  else
    v_request_id := public.skpe_create_import_incorporation_request(
      v_batch.formulation_id,
      v_record.id,
      'incorporate',
      coalesce(nullif(btrim(p_request_reason),''),'Preparação governada para revisão de incorporação histórica.'),
      p_requested_by_actor_type,
      p_requested_by_user_id,
      p_metadata || jsonb_build_object(
        'prepared_by','skpe_prepare_import_incorporation_review',
        'technical_incorporation',true,
        'institutional_validation',false
      )
    );
  end if;

  -- Canonical target resolution selects the active applicable mapping.
  v_resolution_event_id := public.skpe_resolve_import_target(
    v_record.id,
    p_requested_by_actor_type,
    p_requested_by_user_id,
    p_metadata || jsonb_build_object(
      'caller','skpe_prepare_import_incorporation_review',
      'request_id',v_request_id
    )
  );

  select * into v_resolution
  from public.skpe_import_target_resolution_events
  where id=v_resolution_event_id;

  if v_resolution.id is null then
    raise exception using errcode='55000', message='Resolução de destino não foi persistida.';
  end if;

  if v_resolution.resolution_status <> 'resolved'
     or v_resolution.resolution_mode not in ('existing_entity','create_new_entity')
     or coalesce(jsonb_array_length(v_resolution.blockers),0) <> 0 then
    raise exception using errcode='55000', message='Resolução de destino não está apta para preparação de revisão.';
  end if;

  select * into v_version
  from public.skpe_incorporation_mapping_versions
  where id=v_resolution.mapping_version_id;

  if v_version.id is null or v_version.version_status <> 'active' then
    raise exception using errcode='55000', message='Versão ativa do mapping não encontrada.';
  end if;

  select * into v_catalog
  from public.skpe_incorporation_mapping_catalogs
  where id=v_version.catalog_id;

  if v_catalog.id is null
     or v_catalog.status <> 'active'
     or v_catalog.source_entity_code <> v_record.entity_code then
    raise exception using errcode='55000', message='Catálogo de mapping ativo incompatível com o ImportRecord.';
  end if;

  if jsonb_typeof(v_version.mapping_definition -> 'field_map') <> 'object' then
    raise exception using errcode='55000', message='Mapping ativo não possui field_map governado.';
  end if;

  -- Build one review item per governed field mapping. No semantic inference.
  for v_source_field, v_target_field in
    select key, value
    from jsonb_each_text(v_version.mapping_definition -> 'field_map')
    order by key
  loop
    if exists (
      select 1
      from public.skpe_import_incorporation_items i
      where i.incorporation_request_id=v_request_id
        and i.source_field_name=v_source_field
        and i.target_field_name=v_target_field
        and i.target_entity_type=v_catalog.target_entity_type
    ) then
      v_items_existing := v_items_existing + 1;
      continue;
    end if;

    if v_record.values_json ? v_source_field
       and v_record.values_json -> v_source_field is not null
       and v_record.values_json -> v_source_field <> 'null'::jsonb then
      v_original_value := v_record.values_json -> v_source_field;
      v_information_state := 'provided';
    else
      v_original_value := null;
      v_information_state := 'not_present_in_original';
    end if;

    perform public.skpe_add_import_incorporation_item(
      v_request_id,
      v_catalog.target_entity_type,
      v_target_field,
      v_resolution.resolution_mode,
      v_resolution.target_entity_id,
      v_resolution.target_external_key,
      v_source_field,
      null,
      v_original_value,
      v_original_value,
      v_information_state,
      'pending',
      'structured_mapping',
      1,
      'primary',
      'preserve',
      true,
      case
        when v_information_state='provided'
          then 'Campo preparado a partir do field_map governado. Requer revisão humana.'
        else 'Campo previsto no mapping, mas ausente na origem. Requer revisão humana.'
      end,
      jsonb_build_object(
        'mapping_catalog_id',v_catalog.id,
        'mapping_code',v_catalog.mapping_code,
        'mapping_version_id',v_version.id,
        'mapping_version',v_version.version_number,
        'resolution_event_id',v_resolution.id,
        'prepared_by','skpe_prepare_import_incorporation_review',
        'semantic_inference',false
      )
    );

    v_items_created := v_items_created + 1;
  end loop;

  select count(*) into v_item_count
  from public.skpe_import_incorporation_items
  where incorporation_request_id=v_request_id;

  if v_item_count = 0 then
    raise exception using errcode='55000', message='Nenhum item de incorporação foi preparado.';
  end if;

  v_eligibility := public.skpe_evaluate_import_incorporation_request(
    v_request_id,
    p_requested_by_actor_type,
    p_requested_by_user_id
  );

  select * into v_request
  from public.skpe_import_incorporation_requests
  where id=v_request_id;

  return jsonb_build_object(
    'requestId',v_request_id,
    'requestStatus',v_request.request_status,
    'eligibilityStatus',v_request.eligibility_status,
    'eligibility',v_eligibility,
    'requestReused',v_reused_request,
    'importRecordId',v_record.id,
    'batchId',v_record.batch_id,
    'organizationId',v_record.organization_id,
    'projectId',v_record.project_id,
    'formulationId',v_batch.formulation_id,
    'sourceEntityCode',v_record.entity_code,
    'sourceExternalKey',v_record.external_key,
    'mappingCode',v_catalog.mapping_code,
    'mappingVersionId',v_version.id,
    'mappingVersion',v_version.version_number,
    'targetEntityType',v_catalog.target_entity_type,
    'resolutionEventId',v_resolution.id,
    'resolutionMode',v_resolution.resolution_mode,
    'targetExternalKey',v_resolution.target_external_key,
    'itemsCreated',v_items_created,
    'itemsExisting',v_items_existing,
    'itemCount',v_item_count,
    'requiresHumanReview',true,
    'materializationExecuted',false,
    'semanticInference',false
  );
end;
$function$;

revoke all on function public.skpe_prepare_import_incorporation_review(uuid,text,uuid,text,jsonb) from public;
revoke all on function public.skpe_prepare_import_incorporation_review(uuid,text,uuid,text,jsonb) from authenticated;
grant execute on function public.skpe_prepare_import_incorporation_review(uuid,text,uuid,text,jsonb) to service_role;
