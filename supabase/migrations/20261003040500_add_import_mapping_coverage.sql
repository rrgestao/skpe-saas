-- ============================================================
-- SPARKs PE - COOTAQUARA / Import Mapping Coverage
-- Mede cobertura do lote pelos contratos ativos de incorporacao.
-- Read-only: nao cria requests, nao resolve targets e nao materializa dados.
-- ============================================================

create or replace function public.skpe_get_import_mapping_coverage(p_batch_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_batch public.skpe_import_batches%rowtype;
  v_total_records integer := 0;
  v_covered_records integer := 0;
  v_total_entity_types integer := 0;
  v_covered_entity_types integer := 0;
  v_entities jsonb := '[]'::jsonb;
begin
  select *
  into v_batch
  from public.skpe_import_batches
  where id = p_batch_id;

  if v_batch.id is null then
    raise exception 'Lote nao encontrado.';
  end if;

  if not public.can_view_skpe_journey(v_batch.organization_id) then
    raise exception 'Usuario sem permissao para consultar este lote.';
  end if;

  with active_mappings as (
    select
      c.source_entity_code,
      c.mapping_code,
      c.mapping_name,
      c.target_entity_type,
      c.requires_human_review,
      c.allows_semantic_inference,
      v.id as mapping_version_id,
      v.version_number,
      v.target_table,
      v.materializer_function_name,
      v.resolver_function_name
    from public.skpe_incorporation_mapping_catalogs c
    join public.skpe_incorporation_mapping_versions v
      on v.catalog_id = c.id
     and v.version_status = 'active'
    where c.status = 'active'
  ),
  entity_coverage as (
    select
      r.entity_code,
      count(*)::integer as records,
      max(am.mapping_code) as mapping_code,
      max(am.mapping_name) as mapping_name,
      max(am.target_entity_type) as target_entity_type,
      max(am.mapping_version_id::text)::uuid as mapping_version_id,
      max(am.version_number) as mapping_version_number,
      max(am.target_table) as target_table,
      max(am.materializer_function_name) as materializer_function_name,
      max(am.resolver_function_name) as resolver_function_name,
      bool_or(coalesce(am.requires_human_review, false)) as requires_human_review,
      bool_or(coalesce(am.allows_semantic_inference, false)) as allows_semantic_inference,
      count(*) filter (where am.mapping_code is not null)::integer as covered_records
    from public.skpe_import_records r
    left join active_mappings am
      on am.source_entity_code = r.entity_code
    where r.batch_id = v_batch.id
    group by r.entity_code
  )
  select
    coalesce(sum(records), 0)::integer,
    coalesce(sum(covered_records), 0)::integer,
    count(*)::integer,
    count(*) filter (where covered_records = records)::integer,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'entityCode', entity_code,
          'records', records,
          'coveredRecords', covered_records,
          'mappingStatus',
            case
              when covered_records = records then 'covered'
              when covered_records = 0 then 'unmapped'
              else 'partial'
            end,
          'mappingCode', mapping_code,
          'mappingName', mapping_name,
          'targetEntityType', target_entity_type,
          'targetTable', target_table,
          'mappingVersionId', mapping_version_id,
          'mappingVersionNumber', mapping_version_number,
          'materializerFunctionName', materializer_function_name,
          'resolverFunctionName', resolver_function_name,
          'requiresHumanReview', requires_human_review,
          'allowsSemanticInference', allows_semantic_inference
        )
        order by
          case when covered_records = records then 0 else 1 end,
          entity_code
      ),
      '[]'::jsonb
    )
  into
    v_total_records,
    v_covered_records,
    v_total_entity_types,
    v_covered_entity_types,
    v_entities
  from entity_coverage;

  return jsonb_build_object(
    'batchId', v_batch.id,
    'organizationId', v_batch.organization_id,
    'projectId', v_batch.project_id,
    'totalRecords', v_total_records,
    'coveredRecords', v_covered_records,
    'uncoveredRecords', greatest(v_total_records - v_covered_records, 0),
    'recordCoveragePercent',
      case when v_total_records = 0 then 0
      else round((v_covered_records::numeric / v_total_records::numeric) * 100, 2)
      end,
    'totalEntityTypes', v_total_entity_types,
    'coveredEntityTypes', v_covered_entity_types,
    'uncoveredEntityTypes', greatest(v_total_entity_types - v_covered_entity_types, 0),
    'entityCoveragePercent',
      case when v_total_entity_types = 0 then 0
      else round((v_covered_entity_types::numeric / v_total_entity_types::numeric) * 100, 2)
      end,
    'entities', v_entities,
    'protections', jsonb_build_object(
      'readOnly', true,
      'createsIncorporationRequests', false,
      'resolvesTargets', false,
      'materializesStrategicData', false
    )
  );
end;
$function$;

grant execute on function public.skpe_get_import_mapping_coverage(uuid) to authenticated;
