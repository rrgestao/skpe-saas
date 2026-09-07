alter table public.sparks_evidence_assets
  add column if not exists source_evidence_asset_id uuid,
  add column if not exists source_locator jsonb not null default '{}'::jsonb,
  add column if not exists source_external_key text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'sparks_evidence_assets_source_evidence_asset_id_fkey'
      and conrelid = 'public.sparks_evidence_assets'::regclass
  ) then
    alter table public.sparks_evidence_assets
      add constraint sparks_evidence_assets_source_evidence_asset_id_fkey
      foreign key (source_evidence_asset_id)
      references public.sparks_evidence_assets(id)
      on delete restrict;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'sparks_evidence_assets_source_locator_object_check'
      and conrelid = 'public.sparks_evidence_assets'::regclass
  ) then
    alter table public.sparks_evidence_assets
      add constraint sparks_evidence_assets_source_locator_object_check
      check (jsonb_typeof(source_locator) = 'object');
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'sparks_evidence_assets_not_self_sourced_check'
      and conrelid = 'public.sparks_evidence_assets'::regclass
  ) then
    alter table public.sparks_evidence_assets
      add constraint sparks_evidence_assets_not_self_sourced_check
      check (source_evidence_asset_id is null or source_evidence_asset_id <> id);
  end if;
end
$$;

create unique index if not exists sparks_evidence_assets_source_external_key_unique
  on public.sparks_evidence_assets (organization_id, source_evidence_asset_id, source_external_key)
  where source_evidence_asset_id is not null
    and source_external_key is not null
    and archived_at is null;

create or replace function public.enforce_sparks_evidence_source_same_organization()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $function$
declare
  source_organization_id uuid;
begin
  if new.source_evidence_asset_id is null then
    return new;
  end if;

  select evidence.organization_id
    into source_organization_id
  from public.sparks_evidence_assets evidence
  where evidence.id = new.source_evidence_asset_id;

  if source_organization_id is null then
    raise exception 'EvidÃªncia-fonte nÃ£o encontrada.' using errcode = '23503';
  end if;

  if source_organization_id <> new.organization_id then
    raise exception 'EvidÃªncia derivada e evidÃªncia-fonte devem pertencer Ã  mesma organizaÃ§Ã£o.' using errcode = '23514';
  end if;

  return new;
end;
$function$;

drop trigger if exists trg_sparks_evidence_source_same_organization on public.sparks_evidence_assets;
create trigger trg_sparks_evidence_source_same_organization
before insert or update of organization_id, source_evidence_asset_id
on public.sparks_evidence_assets
for each row
execute function public.enforce_sparks_evidence_source_same_organization();

comment on column public.sparks_evidence_assets.source_evidence_asset_id is
  'Ativo de evidÃªncia-fonte do qual esta evidÃªncia foi extraÃ­da, derivada ou sintetizada, preservando a linhagem transversal.';
comment on column public.sparks_evidence_assets.source_locator is
  'Localizador estruturado da evidÃªncia dentro da fonte, como planilha, aba, linha, pÃ¡gina, seÃ§Ã£o, registro ou chave externa.';
comment on column public.sparks_evidence_assets.source_external_key is
  'Chave estÃ¡vel da evidÃªncia na fonte de origem, quando disponÃ­vel.';

alter table public.skpe_evidence_sources
  add column if not exists transversal_evidence_asset_id uuid;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'skpe_evidence_sources_transversal_asset_fkey'
      and conrelid = 'public.skpe_evidence_sources'::regclass
  ) then
    alter table public.skpe_evidence_sources
      add constraint skpe_evidence_sources_transversal_asset_fkey
      foreign key (transversal_evidence_asset_id)
      references public.sparks_evidence_assets(id)
      on delete set null;
  end if;
end
$$;

create unique index if not exists skpe_evidence_sources_transversal_asset_unique
  on public.skpe_evidence_sources (transversal_evidence_asset_id)
  where transversal_evidence_asset_id is not null;

comment on column public.skpe_evidence_sources.transversal_evidence_asset_id is
  'Ponte de compatibilidade para o ativo canÃ´nico em sparks_evidence_assets. skpe_evidence_sources deixa de ser autoridade transversal.';

do $migration$
declare
  project_scope record;
  latest_batch record;
  batch_row record;
  legacy_row record;
  import_row record;
  root_asset_id uuid;
  derived_asset_id uuid;
  version_id uuid;
  next_version_number integer;
  first_batch_at timestamptz;
  latest_version_id uuid;
  locator jsonb;
  normalized_validation text;
  normalized_reliability text;
begin
  for project_scope in
    select distinct source.organization_id, source.project_id
    from public.skpe_evidence_sources source
    where source.project_id is not null
  loop
    select batch.*
      into latest_batch
    from public.skpe_import_batches batch
    where batch.organization_id = project_scope.organization_id
      and batch.project_id = project_scope.project_id
      and batch.source_file is not null
    order by batch.created_at desc, batch.id desc
    limit 1;

    if latest_batch.id is null then
      continue;
    end if;

    select min(batch.created_at)
      into first_batch_at
    from public.skpe_import_batches batch
    where batch.organization_id = project_scope.organization_id
      and batch.project_id = project_scope.project_id
      and batch.source_file is not null;

    select asset.id
      into root_asset_id
    from public.sparks_evidence_assets asset
    where asset.organization_id = project_scope.organization_id
      and asset.source_evidence_asset_id is null
      and asset.archived_at is null
      and asset.metadata->>'asset_kind' = 'canonical_strategic_workbook'
      and asset.metadata->>'legacy_project_id' = project_scope.project_id::text
    order by asset.created_at
    limit 1;

    normalized_validation := case
      when latest_batch.validation_state = 'validated' then 'validated'
      when latest_batch.validation_state in ('under_review', 'reviewed') then 'under_review'
      else 'pending'
    end;

    if root_asset_id is null then
      insert into public.sparks_evidence_assets (
        organization_id,
        title,
        description,
        evidence_type,
        source_type,
        origin_module_code,
        external_origin,
        confidentiality_level,
        validation_status,
        reliability_level,
        metadata,
        created_at,
        updated_at
      ) values (
        project_scope.organization_id,
        'Planilha canÃ´nica de GestÃ£o EstratÃ©gica â€” ' || coalesce(nullif(latest_batch.organization_label, ''), latest_batch.source_file),
        'Artefato histÃ³rico vivo utilizado como fonte estruturada do Planejamento EstratÃ©gico. Suas versÃµes preservam a evoluÃ§Ã£o do conteÃºdo sem transformar divergÃªncias entre versÃµes em nÃ£o conformidade automÃ¡tica.',
        'dataset',
        'internal',
        'SK-PE',
        'skpe_import_batches',
        'internal',
        normalized_validation,
        'not_assessed',
        jsonb_build_object(
          'asset_kind', 'canonical_strategic_workbook',
          'legacy_project_id', project_scope.project_id,
          'formulation_id', latest_batch.formulation_id,
          'schema_code', latest_batch.schema_code,
          'schema_version', latest_batch.schema_version,
          'governance_rule', 'historical_living_artifact'
        ),
        coalesce(first_batch_at, timezone('utc', now())),
        latest_batch.created_at
      )
      returning id into root_asset_id;
    else
      update public.sparks_evidence_assets asset
      set validation_status = normalized_validation,
          updated_at = greatest(asset.updated_at, latest_batch.created_at),
          metadata = asset.metadata || jsonb_build_object(
            'formulation_id', latest_batch.formulation_id,
            'schema_code', latest_batch.schema_code,
            'schema_version', latest_batch.schema_version,
            'governance_rule', 'historical_living_artifact'
          )
      where asset.id = root_asset_id;
    end if;

    for batch_row in
      select batch.*
      from public.skpe_import_batches batch
      where batch.organization_id = project_scope.organization_id
        and batch.project_id = project_scope.project_id
        and batch.source_file is not null
      order by batch.created_at, batch.id
    loop
      select version.id
        into version_id
      from public.sparks_evidence_versions version
      where version.evidence_asset_id = root_asset_id
        and version.metadata->>'import_batch_id' = batch_row.id::text
      limit 1;

      if version_id is null then
        select coalesce(max(version.version_number), 0) + 1
          into next_version_number
        from public.sparks_evidence_versions version
        where version.evidence_asset_id = root_asset_id;

        insert into public.sparks_evidence_versions (
          evidence_asset_id,
          version_number,
          version_label,
          file_name,
          mime_type,
          change_summary,
          metadata,
          created_at
        ) values (
          root_asset_id,
          next_version_number,
          coalesce(substring(batch_row.source_file from '(?i)(v[0-9]+)'), batch_row.schema_version),
          batch_row.source_file,
          case when lower(coalesce(batch_row.source_format, 'xlsx')) = 'xlsx'
            then 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            else null
          end,
          'VersÃ£o reconciliada a partir do lote de importaÃ§Ã£o ' || batch_row.id::text || '.',
          jsonb_build_object(
            'import_batch_id', batch_row.id,
            'source_file_fingerprint', batch_row.source_file_fingerprint,
            'batch_status', batch_row.status,
            'validation_state', batch_row.validation_state,
            'schema_code', batch_row.schema_code,
            'schema_version', batch_row.schema_version,
            'source_format', batch_row.source_format
          ),
          batch_row.created_at
        )
        returning id into version_id;
      end if;
    end loop;

    select version.id
      into latest_version_id
    from public.sparks_evidence_versions version
    where version.evidence_asset_id = root_asset_id
      and version.metadata->>'import_batch_id' = latest_batch.id::text
    limit 1;

    update public.sparks_evidence_assets asset
    set current_version_id = latest_version_id
    where asset.id = root_asset_id
      and latest_version_id is not null;

    update public.skpe_data_provenance provenance
    set source_evidence_asset_id = root_asset_id
    where provenance.source_evidence_asset_id is null
      and provenance.organization_id = project_scope.organization_id
      and provenance.import_batch_id in (
        select batch.id
        from public.skpe_import_batches batch
        where batch.organization_id = project_scope.organization_id
          and batch.project_id = project_scope.project_id
      );

    for legacy_row in
      select source.*
      from public.skpe_evidence_sources source
      where source.organization_id = project_scope.organization_id
        and source.project_id = project_scope.project_id
      order by source.received_at, source.id
    loop
      import_row := null;

      if nullif(legacy_row.metadata->>'source_external_key', '') is not null then
        select record.*
          into import_row
        from public.skpe_import_records record
        join public.skpe_import_batches batch on batch.id = record.batch_id
        where batch.organization_id = project_scope.organization_id
          and batch.project_id = project_scope.project_id
          and record.external_key = legacy_row.metadata->>'source_external_key'
        order by batch.created_at desc, record.created_at desc, record.id desc
        limit 1;
      end if;

      locator := jsonb_strip_nulls(jsonb_build_object(
        'source_sheet', coalesce(import_row.source_sheet, legacy_row.metadata->>'source_sheet'),
        'source_row', import_row.source_row,
        'external_key', coalesce(import_row.external_key, legacy_row.metadata->>'source_external_key'),
        'import_record_id', import_row.id,
        'legacy_evidence_source_id', legacy_row.id
      ));

      normalized_validation := case
        when legacy_row.status = 'validated' then 'validated'
        when legacy_row.status in ('received', 'under_review') then 'under_review'
        when legacy_row.status = 'rejected' then 'rejected'
        else 'pending'
      end;

      normalized_reliability := case
        when legacy_row.reliability_level = 'high' then 'high'
        when legacy_row.reliability_level in ('medium', 'moderate') then 'moderate'
        when legacy_row.reliability_level = 'low' then 'low'
        else 'not_assessed'
      end;

      derived_asset_id := legacy_row.transversal_evidence_asset_id;

      if derived_asset_id is null then
        select asset.id
          into derived_asset_id
        from public.sparks_evidence_assets asset
        where asset.organization_id = project_scope.organization_id
          and asset.archived_at is null
          and asset.metadata->>'legacy_evidence_source_id' = legacy_row.id::text
        limit 1;
      end if;

      if derived_asset_id is null then
        insert into public.sparks_evidence_assets (
          organization_id,
          title,
          description,
          evidence_type,
          source_type,
          origin_module_code,
          external_origin,
          confidentiality_level,
          validation_status,
          reliability_level,
          source_evidence_asset_id,
          source_locator,
          source_external_key,
          metadata,
          created_at,
          updated_at
        ) values (
          legacy_row.organization_id,
          legacy_row.title,
          legacy_row.description,
          'other',
          'internal',
          'SK-PE',
          coalesce(legacy_row.metadata->'source_payload'->>'fonte', legacy_row.origin_organization),
          coalesce(legacy_row.confidentiality_level, 'internal'),
          normalized_validation,
          normalized_reliability,
          root_asset_id,
          locator,
          nullif(legacy_row.metadata->>'source_external_key', ''),
          jsonb_build_object(
            'asset_kind', 'evidence_assertion',
            'legacy_table', 'skpe_evidence_sources',
            'legacy_evidence_source_id', legacy_row.id,
            'legacy_project_id', legacy_row.project_id,
            'legacy_journey_item_id', legacy_row.journey_item_id,
            'cycle_code', legacy_row.cycle_code,
            'legacy_status', legacy_row.status,
            'classification', legacy_row.metadata->'source_payload'->>'classificacao',
            'criticality', legacy_row.metadata->'source_payload'->>'criticidade',
            'validation_action', legacy_row.metadata->'source_payload'->>'acao_de_validacao',
            'gap', legacy_row.metadata->'source_payload'->>'limitacoes_lacuna',
            'related_risk', legacy_row.metadata->'source_payload'->>'risco_relacionado',
            'source_payload', legacy_row.metadata->'source_payload',
            'reconciliation', legacy_row.metadata->>'reconciliation'
          ),
          coalesce(legacy_row.received_at, timezone('utc', now())),
          coalesce(legacy_row.validated_at, legacy_row.received_at, timezone('utc', now()))
        )
        returning id into derived_asset_id;
      else
        update public.sparks_evidence_assets asset
        set title = legacy_row.title,
            description = legacy_row.description,
            validation_status = normalized_validation,
            reliability_level = normalized_reliability,
            source_evidence_asset_id = root_asset_id,
            source_locator = locator,
            source_external_key = nullif(legacy_row.metadata->>'source_external_key', ''),
            updated_at = greatest(asset.updated_at, coalesce(legacy_row.validated_at, legacy_row.received_at, asset.updated_at)),
            metadata = asset.metadata || jsonb_build_object(
              'asset_kind', 'evidence_assertion',
              'legacy_table', 'skpe_evidence_sources',
              'legacy_evidence_source_id', legacy_row.id,
              'legacy_project_id', legacy_row.project_id,
              'legacy_journey_item_id', legacy_row.journey_item_id,
              'cycle_code', legacy_row.cycle_code,
              'legacy_status', legacy_row.status,
              'classification', legacy_row.metadata->'source_payload'->>'classificacao',
              'criticality', legacy_row.metadata->'source_payload'->>'criticidade',
              'validation_action', legacy_row.metadata->'source_payload'->>'acao_de_validacao',
              'gap', legacy_row.metadata->'source_payload'->>'limitacoes_lacuna',
              'related_risk', legacy_row.metadata->'source_payload'->>'risco_relacionado',
              'source_payload', legacy_row.metadata->'source_payload',
              'reconciliation', legacy_row.metadata->>'reconciliation'
            )
        where asset.id = derived_asset_id;
      end if;

      update public.skpe_evidence_sources source
      set transversal_evidence_asset_id = derived_asset_id
      where source.id = legacy_row.id
        and source.transversal_evidence_asset_id is distinct from derived_asset_id;
    end loop;
  end loop;
end
$migration$;