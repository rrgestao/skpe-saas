-- Reuso de conteúdo já materializado ao incorporar documento em série.
create or replace function public.register_sparks_evidence_series_document(
  target_organization_id uuid,
  target_series_key text,
  target_series_title text,
  target_document_family text,
  target_period_label text,
  target_period_start date,
  target_period_end date,
  target_reference_date date,
  target_evidence_title text,
  target_origin_module_code text,
  target_content_hash text,
  target_file_name text,
  target_mime_type text,
  target_file_size_bytes bigint,
  target_storage_bucket text,
  target_storage_path text,
  change_reason text,
  seed_evidence_asset_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  series_id_value uuid;
  member_asset_id uuid;
  duplicate_asset_id uuid;
  duplicate_member_series_id uuid;
  duplicate_member_period text;
  new_version_id uuid;
  next_version integer;
  physical_version_count bigint;
  seed_row public.sparks_evidence_assets%rowtype;
  seed_period_label text;
begin
  if not public.can_manage_sparks_evidence(target_organization_id) then
    raise exception 'Acesso administrativo necessário para registrar série documental.' using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if length(trim(coalesce(target_series_key, ''))) = 0
     or length(trim(coalesce(target_period_label, ''))) = 0 then
    raise exception 'Série e competência são obrigatórias.';
  end if;

  insert into public.sparks_evidence_series (
    organization_id, series_key, title, document_family, periodicity,
    origin_module_code, custodian_module_code, created_by, updated_by, metadata
  ) values (
    target_organization_id,
    trim(target_series_key),
    trim(target_series_title),
    trim(target_document_family),
    'annual',
    nullif(trim(coalesce(target_origin_module_code, '')), ''),
    'SK-DOC',
    auth.uid(),
    auth.uid(),
    jsonb_build_object('human_validation_required', true)
  )
  on conflict (organization_id, series_key)
  do update set
    title = excluded.title,
    document_family = excluded.document_family,
    updated_at = now(),
    updated_by = auth.uid()
  returning id into series_id_value;

  if seed_evidence_asset_id is not null then
    select * into seed_row
    from public.sparks_evidence_assets asset
    where asset.id = seed_evidence_asset_id
      and asset.organization_id = target_organization_id
      and asset.archived_at is null;

    if seed_row.id is not null then
      seed_period_label := coalesce(
        to_char(seed_row.reference_date, 'YYYY'),
        to_char(seed_row.reference_period_end, 'YYYY')
      );

      if seed_period_label is not null then
        insert into public.sparks_evidence_series_members (
          series_id, evidence_asset_id, period_label,
          period_start, period_end, reference_date, created_by,
          metadata
        ) values (
          series_id_value,
          seed_row.id,
          seed_period_label,
          seed_row.reference_period_start,
          seed_row.reference_period_end,
          seed_row.reference_date,
          auth.uid(),
          jsonb_build_object('seeded_from_existing_asset', true)
        )
        on conflict do nothing;

        update public.sparks_evidence_assets
        set metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
          'series_key', trim(target_series_key),
          'series_title', trim(target_series_title),
          'series_period_label', seed_period_label
        ),
        updated_by = auth.uid(),
        updated_at = now()
        where id = seed_row.id;
      end if;
    end if;
  end if;

  if target_content_hash is not null then
    select asset.id
    into duplicate_asset_id
    from public.sparks_evidence_assets asset
    where asset.organization_id = target_organization_id
      and asset.content_hash = target_content_hash
      and asset.archived_at is null
    limit 1;

    if duplicate_asset_id is not null then
      select member.series_id, member.period_label
      into duplicate_member_series_id, duplicate_member_period
      from public.sparks_evidence_series_members member
      where member.evidence_asset_id = duplicate_asset_id
      limit 1;

      if duplicate_member_series_id is null then
        insert into public.sparks_evidence_series_members (
          series_id, evidence_asset_id, period_label,
          period_start, period_end, reference_date, created_by,
          metadata
        ) values (
          series_id_value,
          duplicate_asset_id,
          trim(target_period_label),
          target_period_start,
          target_period_end,
          target_reference_date,
          auth.uid(),
          jsonb_build_object('reused_existing_content', true)
        )
        on conflict do nothing;

        update public.sparks_evidence_assets
        set metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
          'series_key', trim(target_series_key),
          'series_title', trim(target_series_title),
          'series_period_label', trim(target_period_label)
        ),
        updated_by = auth.uid(),
        updated_at = now()
        where id = duplicate_asset_id;

        return jsonb_build_object(
          'status', 'duplicate_content_reused',
          'series_id', series_id_value,
          'evidence_asset_id', duplicate_asset_id,
          'period_label', target_period_label
        );
      end if;

      return jsonb_build_object(
        'status', 'duplicate_content',
        'series_id', duplicate_member_series_id,
        'evidence_asset_id', duplicate_asset_id,
        'period_label', duplicate_member_period
      );
    end if;
  end if;

  select member.evidence_asset_id
  into member_asset_id
  from public.sparks_evidence_series_members member
  where member.series_id = series_id_value
    and member.period_label = trim(target_period_label)
  limit 1;

  if member_asset_id is null then
    insert into public.sparks_evidence_assets (
      organization_id, title, evidence_type, source_type,
      origin_module_code, reference_date, reference_period_start,
      reference_period_end, confidentiality_level, content_hash,
      created_by, updated_by, metadata
    ) values (
      target_organization_id,
      trim(target_evidence_title),
      'document',
      'internal',
      nullif(trim(coalesce(target_origin_module_code, '')), ''),
      target_reference_date,
      target_period_start,
      target_period_end,
      'internal',
      target_content_hash,
      auth.uid(),
      auth.uid(),
      jsonb_build_object(
        'asset_kind', 'periodic_source_document',
        'series_key', trim(target_series_key),
        'series_title', trim(target_series_title),
        'series_period_label', trim(target_period_label),
        'custodian_module_code', 'SK-DOC',
        'human_validation_required', true
      )
    )
    returning id into member_asset_id;

    insert into public.sparks_evidence_series_members (
      series_id, evidence_asset_id, period_label,
      period_start, period_end, reference_date, created_by
    ) values (
      series_id_value, member_asset_id, trim(target_period_label),
      target_period_start, target_period_end, target_reference_date, auth.uid()
    );
  end if;

  select count(*)
  into physical_version_count
  from public.sparks_evidence_versions version
  where version.evidence_asset_id = member_asset_id
    and version.storage_bucket is not null
    and version.storage_path is not null;

  select coalesce(max(version.version_number), 0) + 1
  into next_version
  from public.sparks_evidence_versions version
  where version.evidence_asset_id = member_asset_id;

  insert into public.sparks_evidence_versions (
    evidence_asset_id, version_number, version_label,
    storage_bucket, storage_path, file_name, mime_type,
    file_size_bytes, content_hash, change_summary, created_by, metadata
  ) values (
    member_asset_id,
    next_version,
    case when physical_version_count = 0 then '1.0' else (physical_version_count + 1)::text || '.0' end,
    target_storage_bucket,
    target_storage_path,
    target_file_name,
    target_mime_type,
    target_file_size_bytes,
    target_content_hash,
    trim(change_reason),
    auth.uid(),
    jsonb_build_object(
      'governed_series_version', true,
      'series_id', series_id_value,
      'period_label', trim(target_period_label),
      'human_validation_required', true
    )
  )
  returning id into new_version_id;

  update public.sparks_evidence_assets
  set current_version_id = new_version_id,
      content_hash = target_content_hash,
      reference_date = coalesce(target_reference_date, reference_date),
      reference_period_start = coalesce(target_period_start, reference_period_start),
      reference_period_end = coalesce(target_period_end, reference_period_end),
      validation_status = 'pending',
      reliability_level = 'not_assessed',
      metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
        'series_key', trim(target_series_key),
        'series_title', trim(target_series_title),
        'series_period_label', trim(target_period_label),
        'last_version_at', now(),
        'human_validation_required', true
      ),
      updated_at = now(),
      updated_by = auth.uid()
  where id = member_asset_id;

  return jsonb_build_object(
    'status', case when physical_version_count = 0 then 'created_period_document' else 'created_period_version' end,
    'series_id', series_id_value,
    'evidence_asset_id', member_asset_id,
    'version_id', new_version_id,
    'period_label', trim(target_period_label),
    'version_number', next_version
  );
end;
$function$;
