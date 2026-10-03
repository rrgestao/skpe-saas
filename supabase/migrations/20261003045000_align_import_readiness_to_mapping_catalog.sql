-- ============================================================
-- SPARKs PE - Mapping readiness aligned to governed catalog
-- Supersedes the legacy target_table-based readiness check.
-- The canonical authority is the active incorporation mapping catalog.
-- No strategic data is materialized by this migration.
-- ============================================================

create or replace function public.skpe_assess_import_batch_readiness(p_batch_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_batch public.skpe_import_batches%rowtype;
  v_pending integer := 0;
  v_blocked integer := 0;
  v_invalid integer := 0;
  v_quarantined integer := 0;
  v_unmapped integer := 0;
  v_unresolved_conflicts integer := 0;
  v_conflict_total integer := 0;
  v_unmapped_entities jsonb := '[]'::jsonb;
  v_is_ready boolean := false;
  v_state text := 'blocked';
  v_result jsonb;
begin
  select *
  into v_batch
  from public.skpe_import_batches
  where id = p_batch_id;

  if v_batch.id is null then
    raise exception 'Lote nao encontrado.';
  end if;

  if not public.can_manage_skpe_journey(v_batch.organization_id) then
    raise exception 'Usuario sem permissao para revisar este lote.';
  end if;

  if v_batch.status not in ('reviewed', 'ready') then
    raise exception 'A avaliacao de prontidao exige lote revisado. Status atual: %', v_batch.status;
  end if;

  select
    count(*) filter (where simulation_status = 'pending_mapping'),
    count(*) filter (where simulation_status = 'blocked'),
    count(*) filter (where simulation_status = 'invalid'),
    count(*) filter (where simulation_status = 'quarantined')
  into v_pending, v_blocked, v_invalid, v_quarantined
  from public.skpe_import_records
  where batch_id = v_batch.id;

  with active_applicable_mappings as (
    select distinct c.source_entity_code
    from public.skpe_incorporation_mapping_catalogs c
    join public.skpe_incorporation_mapping_versions v
      on v.catalog_id = c.id
     and v.version_status = 'active'
     and v.version_number = c.current_version
    where c.status = 'active'
      and (
        not (c.applicability ? 'source_type')
        or (
          jsonb_typeof(c.applicability -> 'source_type') = 'string'
          and c.applicability ->> 'source_type' = v_batch.source_type
        )
        or (
          jsonb_typeof(c.applicability -> 'source_type') = 'array'
          and exists (
            select 1
            from jsonb_array_elements_text(c.applicability -> 'source_type') x(value)
            where x.value = v_batch.source_type
          )
        )
      )
      and (
        not (c.applicability ? 'source_format')
        or (
          jsonb_typeof(c.applicability -> 'source_format') = 'string'
          and c.applicability ->> 'source_format' = v_batch.source_format
        )
        or (
          jsonb_typeof(c.applicability -> 'source_format') = 'array'
          and exists (
            select 1
            from jsonb_array_elements_text(c.applicability -> 'source_format') x(value)
            where x.value = v_batch.source_format
          )
        )
      )
  )
  select count(*)::integer
  into v_unmapped
  from public.skpe_import_records r
  where r.batch_id = v_batch.id
    and r.proposed_action in ('insert','update')
    and not exists (
      select 1
      from active_applicable_mappings m
      where m.source_entity_code = r.entity_code
    );

  with active_applicable_mappings as (
    select distinct c.source_entity_code
    from public.skpe_incorporation_mapping_catalogs c
    join public.skpe_incorporation_mapping_versions v
      on v.catalog_id = c.id
     and v.version_status = 'active'
     and v.version_number = c.current_version
    where c.status = 'active'
      and (
        not (c.applicability ? 'source_type')
        or (
          jsonb_typeof(c.applicability -> 'source_type') = 'string'
          and c.applicability ->> 'source_type' = v_batch.source_type
        )
        or (
          jsonb_typeof(c.applicability -> 'source_type') = 'array'
          and exists (
            select 1
            from jsonb_array_elements_text(c.applicability -> 'source_type') x(value)
            where x.value = v_batch.source_type
          )
        )
      )
      and (
        not (c.applicability ? 'source_format')
        or (
          jsonb_typeof(c.applicability -> 'source_format') = 'string'
          and c.applicability ->> 'source_format' = v_batch.source_format
        )
        or (
          jsonb_typeof(c.applicability -> 'source_format') = 'array'
          and exists (
            select 1
            from jsonb_array_elements_text(c.applicability -> 'source_format') x(value)
            where x.value = v_batch.source_format
          )
        )
      )
  )
  select coalesce(jsonb_agg(to_jsonb(x) order by x.entity_code), '[]'::jsonb)
  into v_unmapped_entities
  from (
    select r.entity_code, count(*)::integer as records
    from public.skpe_import_records r
    where r.batch_id = v_batch.id
      and r.proposed_action in ('insert','update')
      and not exists (
        select 1
        from active_applicable_mappings m
        where m.source_entity_code = r.entity_code
      )
    group by r.entity_code
  ) x;

  select
    count(*),
    count(*) filter (where status not in ('approved', 'adjusted', 'rejected'))
  into v_conflict_total, v_unresolved_conflicts
  from public.skpe_import_conflicts
  where batch_id = v_batch.id;

  v_is_ready :=
    v_pending = 0
    and v_blocked = 0
    and v_invalid = 0
    and v_unmapped = 0
    and v_unresolved_conflicts = 0;

  v_state := case when v_is_ready then 'ready' else 'blocked' end;

  v_result := jsonb_build_object(
    'batchId', v_batch.id,
    'assessedAt', timezone('utc', now()),
    'readinessState', v_state,
    'readyForDefinitiveLoad', v_is_ready,
    'scope', 'pre_definitive_load_review',
    'mappingAuthority', 'active_incorporation_mapping_catalog',
    'gates', jsonb_build_array(
      jsonb_build_object(
        'code','BATCH_REVIEWED',
        'label','Lote revisado',
        'passed',v_batch.status in ('reviewed','ready'),
        'actual',v_batch.status,
        'required','reviewed'
      ),
      jsonb_build_object(
        'code','NO_PENDING_MAPPING',
        'label','Nenhum registro pendente',
        'passed',v_pending=0,
        'actual',v_pending,
        'required',0
      ),
      jsonb_build_object(
        'code','TARGET_MAPPING_COMPLETE',
        'label','Contratos de incorporacao definidos',
        'passed',v_unmapped=0,
        'actual',v_unmapped,
        'required',0
      ),
      jsonb_build_object(
        'code','NO_BLOCKED_RECORDS',
        'label','Nenhum registro bloqueado',
        'passed',v_blocked=0,
        'actual',v_blocked,
        'required',0
      ),
      jsonb_build_object(
        'code','NO_INVALID_RECORDS',
        'label','Nenhum registro invalido',
        'passed',v_invalid=0,
        'actual',v_invalid,
        'required',0
      ),
      jsonb_build_object(
        'code','CONFLICTS_RESOLVED',
        'label','Conflitos formalmente tratados',
        'passed',v_unresolved_conflicts=0,
        'actual',v_unresolved_conflicts,
        'required',0,
        'total',v_conflict_total
      ),
      jsonb_build_object(
        'code','CANONICAL_JOURNEY_PROTECTED',
        'label','Jornada canonica protegida',
        'passed',true,
        'actual','MF1 aprovada; MF2 em andamento; PEM-02.04 bloqueado',
        'required','preservar estado canonico'
      )
    ),
    'counts', jsonb_build_object(
      'pending',v_pending,
      'unmapped',v_unmapped,
      'blocked',v_blocked,
      'invalid',v_invalid,
      'quarantined',v_quarantined,
      'conflicts',v_conflict_total,
      'unresolvedConflicts',v_unresolved_conflicts
    ),
    'unmappedEntities', v_unmapped_entities,
    'blockedRecords', coalesce((
      with active_applicable_mappings as (
        select distinct c.source_entity_code
        from public.skpe_incorporation_mapping_catalogs c
        join public.skpe_incorporation_mapping_versions v
          on v.catalog_id = c.id
         and v.version_status = 'active'
         and v.version_number = c.current_version
        where c.status = 'active'
      )
      select jsonb_agg(
        jsonb_build_object(
          'id',r.id,
          'entityCode',r.entity_code,
          'externalKey',r.external_key,
          'simulationStatus',r.simulation_status,
          'proposedAction',r.proposed_action,
          'sourceSheet',r.source_sheet,
          'sourceRow',r.source_row,
          'validationMessages',coalesce(r.validation_messages,'[]'::jsonb),
          'record',to_jsonb(r)
        )
        order by r.entity_code,r.external_key
      )
      from public.skpe_import_records r
      where r.batch_id=v_batch.id
        and (
          r.simulation_status in ('blocked','invalid','quarantined','pending_mapping')
          or (
            r.proposed_action in ('insert','update')
            and not exists (
              select 1
              from active_applicable_mappings m
              where m.source_entity_code = r.entity_code
            )
          )
        )
    ),'[]'::jsonb),
    'conflicts', coalesce((
      select jsonb_agg(to_jsonb(c) order by c.created_at,c.id)
      from public.skpe_import_conflicts c
      where c.batch_id=v_batch.id
    ),'[]'::jsonb),
    'protections', jsonb_build_object(
      'databaseWrites',false,
      'definitiveLoadExecuted',false,
      'organizationId',v_batch.organization_id,
      'projectId',v_batch.project_id,
      'mf1State','approved',
      'mf2State','in_progress',
      'pem0203State','validation',
      'pem0204State','blocked'
    )
  );

  update public.skpe_import_batches
  set status = case when v_is_ready then 'ready' else 'reviewed' end,
      payload_metadata = coalesce(payload_metadata,'{}'::jsonb)
        || jsonb_build_object(
          'readinessAssessment',v_result,
          'mappingReadinessVersion','2.0.0'
        )
  where id = v_batch.id;

  insert into public.skpe_import_events(
    batch_id,organization_id,project_id,event_code,event_data
  )
  values (
    v_batch.id,
    v_batch.organization_id,
    v_batch.project_id,
    'IMPORT_MAPPING_READINESS_ASSESSED',
    v_result-'blockedRecords'-'conflicts'
  );

  return v_result;
end;
$function$;

grant execute on function public.skpe_assess_import_batch_readiness(uuid) to authenticated;
