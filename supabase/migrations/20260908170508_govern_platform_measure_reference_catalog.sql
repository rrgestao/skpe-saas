create or replace function public.get_platform_measure_reference_catalog(
  target_include_inactive boolean default true,
  target_include_archived boolean default false
)
returns table(
  reference_catalog_id uuid,
  catalog_code text,
  version_number integer,
  name text,
  description text,
  purpose text,
  formula_text text,
  unit text,
  polarity text,
  measurement_frequency text,
  indicator_category text,
  applicability jsonb,
  excellence_criteria jsonb,
  reference_sources jsonb,
  status text,
  is_current boolean,
  metadata jsonb,
  benchmarks jsonb,
  created_at timestamptz,
  created_by uuid,
  updated_at timestamptz,
  updated_by uuid
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    catalog.id,
    catalog.catalog_code,
    catalog.version_number,
    catalog.name,
    catalog.description,
    catalog.purpose,
    catalog.formula_text,
    catalog.unit,
    catalog.polarity,
    catalog.measurement_frequency,
    catalog.indicator_category,
    catalog.applicability,
    catalog.excellence_criteria,
    catalog.reference_sources,
    catalog.status,
    catalog.is_current,
    catalog.metadata,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', benchmark.id,
            'benchmarkType', benchmark.benchmark_type,
            'sourceName', benchmark.source_name,
            'sourceReference', benchmark.source_reference,
            'referencePeriod', benchmark.reference_period,
            'populationContext', benchmark.population_context,
            'benchmarkValue', benchmark.benchmark_value,
            'lowerBound', benchmark.lower_bound,
            'upperBound', benchmark.upper_bound,
            'applicability', benchmark.applicability,
            'comparabilityNotes', benchmark.comparability_notes,
            'confidenceLevel', benchmark.confidence_level,
            'verifiedAt', benchmark.verified_at,
            'verifiedBy', benchmark.verified_by,
            'status', benchmark.status,
            'metadata', benchmark.metadata,
            'createdAt', benchmark.created_at,
            'updatedAt', benchmark.updated_at
          )
          order by benchmark.reference_period desc nulls last, benchmark.source_name
        )
        from public.skpe_indicator_reference_benchmarks benchmark
        where benchmark.reference_indicator_id = catalog.id
          and (target_include_archived or benchmark.status <> 'archived')
      ),
      '[]'::jsonb
    ),
    catalog.created_at,
    catalog.created_by,
    catalog.updated_at,
    catalog.updated_by
  from public.skpe_indicator_reference_catalog catalog
  where (target_include_archived or catalog.status <> 'archived')
    and (target_include_inactive or catalog.status in ('draft','active'))
  order by catalog.catalog_code, catalog.version_number desc;
end;
$$;

comment on function public.get_platform_measure_reference_catalog(boolean, boolean) is
  'Leitura administrativa completa do Catálogo GERAL de Medidas e Desempenho, restrita a Platform Super Admin.';

revoke all on function public.get_platform_measure_reference_catalog(boolean, boolean) from public;
revoke all on function public.get_platform_measure_reference_catalog(boolean, boolean) from anon;
grant execute on function public.get_platform_measure_reference_catalog(boolean, boolean) to authenticated;

create or replace function public.upsert_platform_measure_reference_catalog(
  target_catalog_code text,
  target_name text,
  target_description text default null,
  target_purpose text default null,
  target_formula_text text default null,
  target_unit text default null,
  target_polarity text default 'higher_is_better',
  target_measurement_frequency text default null,
  target_indicator_category text default null,
  target_applicability jsonb default '{}'::jsonb,
  target_excellence_criteria jsonb default '[]'::jsonb,
  target_reference_sources jsonb default '[]'::jsonb,
  target_status text default 'draft',
  target_make_current boolean default true,
  target_metadata jsonb default '{}'::jsonb,
  target_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_code text := upper(trim(coalesce(target_catalog_code, '')));
  previous_row public.skpe_indicator_reference_catalog%rowtype;
  created_row public.skpe_indicator_reference_catalog%rowtype;
  next_version integer := 1;
  audit_event jsonb;
  merged_metadata jsonb;
begin
  perform public.require_platform_super_admin();

  if length(normalized_code) = 0 then
    raise exception 'Informe o código da referência do Catálogo GERAL.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_name, ''))) = 0 then
    raise exception 'Informe o nome da referência do Catálogo GERAL.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo da criação ou nova versão da referência.' using errcode = '22023';
  end if;

  if coalesce(target_status, '') not in ('draft','active','inactive','archived') then
    raise exception 'Situação inválida para a referência geral.' using errcode = '22023';
  end if;

  select *
  into previous_row
  from public.skpe_indicator_reference_catalog
  where upper(trim(catalog_code)) = normalized_code
  order by version_number desc
  limit 1
  for update;

  if found then
    next_version := previous_row.version_number + 1;
  end if;

  audit_event := jsonb_build_object(
    'action', case when previous_row.id is null then 'created' else 'version_created' end,
    'reason', trim(target_change_reason),
    'changedAt', timezone('utc', now()),
    'changedBy', current_user_id,
    'previousReferenceId', previous_row.id,
    'previousVersion', previous_row.version_number
  );

  merged_metadata := coalesce(target_metadata, '{}'::jsonb)
    || jsonb_build_object(
      'lastChangeReason', trim(target_change_reason),
      'lastChangedAt', timezone('utc', now()),
      'lastChangedBy', current_user_id,
      'changeHistory', coalesce(coalesce(target_metadata, '{}'::jsonb)->'changeHistory', '[]'::jsonb) || jsonb_build_array(audit_event)
    );

  if target_make_current then
    update public.skpe_indicator_reference_catalog
    set
      is_current = false,
      updated_at = timezone('utc', now()),
      updated_by = current_user_id,
      metadata = coalesce(metadata, '{}'::jsonb)
        || jsonb_build_object(
          'supersededReason', trim(target_change_reason),
          'supersededAt', timezone('utc', now()),
          'supersededBy', current_user_id
        )
    where upper(trim(catalog_code)) = normalized_code
      and is_current = true;
  end if;

  insert into public.skpe_indicator_reference_catalog (
    id, catalog_code, version_number, name, description, purpose, formula_text, unit,
    polarity, measurement_frequency, indicator_category, applicability, excellence_criteria,
    reference_sources, status, is_current, metadata, created_at, created_by, updated_at, updated_by
  ) values (
    gen_random_uuid(), normalized_code, next_version, trim(target_name),
    nullif(trim(coalesce(target_description, '')), ''),
    nullif(trim(coalesce(target_purpose, '')), ''),
    nullif(trim(coalesce(target_formula_text, '')), ''),
    nullif(trim(coalesce(target_unit, '')), ''),
    target_polarity,
    nullif(trim(coalesce(target_measurement_frequency, '')), ''),
    nullif(trim(coalesce(target_indicator_category, '')), ''),
    coalesce(target_applicability, '{}'::jsonb),
    coalesce(target_excellence_criteria, '[]'::jsonb),
    coalesce(target_reference_sources, '[]'::jsonb),
    target_status, target_make_current, merged_metadata,
    timezone('utc', now()), current_user_id, timezone('utc', now()), current_user_id
  )
  returning * into created_row;

  return created_row.id;
end;
$$;

comment on function public.upsert_platform_measure_reference_catalog(text, text, text, text, text, text, text, text, text, jsonb, jsonb, jsonb, text, boolean, jsonb, text) is
  'Cria referência ou nova versão no Catálogo GERAL. Nunca sobrescreve silenciosamente a versão anterior; toda mutação exige change_reason e Platform Super Admin.';

revoke all on function public.upsert_platform_measure_reference_catalog(text, text, text, text, text, text, text, text, text, jsonb, jsonb, jsonb, text, boolean, jsonb, text) from public;
revoke all on function public.upsert_platform_measure_reference_catalog(text, text, text, text, text, text, text, text, text, jsonb, jsonb, jsonb, text, boolean, jsonb, text) from anon;
grant execute on function public.upsert_platform_measure_reference_catalog(text, text, text, text, text, text, text, text, text, jsonb, jsonb, jsonb, text, boolean, jsonb, text) to authenticated;

create or replace function public.transition_platform_measure_reference_catalog(
  target_reference_catalog_id uuid,
  target_status text,
  target_make_current boolean default null,
  target_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  current_row public.skpe_indicator_reference_catalog%rowtype;
  effective_current boolean;
  audit_event jsonb;
begin
  perform public.require_platform_super_admin();

  if target_reference_catalog_id is null then
    raise exception 'Informe a referência do Catálogo GERAL.' using errcode = '22023';
  end if;

  if coalesce(target_status, '') not in ('draft','active','inactive','archived') then
    raise exception 'Situação inválida para a referência geral.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo da transição da referência.' using errcode = '22023';
  end if;

  select *
  into current_row
  from public.skpe_indicator_reference_catalog
  where id = target_reference_catalog_id
  for update;

  if not found then
    raise exception 'Referência do Catálogo GERAL não encontrada.' using errcode = '22023';
  end if;

  effective_current := coalesce(
    target_make_current,
    case when target_status = 'active' then true else false end
  );

  if target_status in ('inactive','archived') then
    effective_current := false;
  end if;

  if effective_current then
    update public.skpe_indicator_reference_catalog
    set is_current = false, updated_at = timezone('utc', now()), updated_by = current_user_id
    where upper(trim(catalog_code)) = upper(trim(current_row.catalog_code))
      and id <> current_row.id
      and is_current = true;
  end if;

  audit_event := jsonb_build_object(
    'action', 'status_transition',
    'fromStatus', current_row.status,
    'toStatus', target_status,
    'fromCurrent', current_row.is_current,
    'toCurrent', effective_current,
    'reason', trim(target_change_reason),
    'changedAt', timezone('utc', now()),
    'changedBy', current_user_id
  );

  update public.skpe_indicator_reference_catalog
  set
    status = target_status,
    is_current = effective_current,
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'lastChangeReason', trim(target_change_reason),
        'lastChangedAt', timezone('utc', now()),
        'lastChangedBy', current_user_id,
        'changeHistory', coalesce(metadata->'changeHistory', '[]'::jsonb) || jsonb_build_array(audit_event)
      ),
    updated_at = timezone('utc', now()),
    updated_by = current_user_id
  where id = target_reference_catalog_id;

  return target_reference_catalog_id;
end;
$$;

comment on function public.transition_platform_measure_reference_catalog(uuid, text, boolean, text) is
  'Transição governada de situação/vigência do Catálogo GERAL, restrita a Platform Super Admin e com motivo obrigatório.';

revoke all on function public.transition_platform_measure_reference_catalog(uuid, text, boolean, text) from public;
revoke all on function public.transition_platform_measure_reference_catalog(uuid, text, boolean, text) from anon;
grant execute on function public.transition_platform_measure_reference_catalog(uuid, text, boolean, text) to authenticated;

create or replace function public.upsert_platform_measure_reference_benchmark(
  target_reference_catalog_id uuid,
  target_benchmark_type text,
  target_source_name text,
  target_source_reference text default null,
  target_reference_period text default null,
  target_population_context text default null,
  target_benchmark_value numeric default null,
  target_lower_bound numeric default null,
  target_upper_bound numeric default null,
  target_applicability text default null,
  target_comparability_notes text default null,
  target_confidence_level text default null,
  target_status text default 'draft',
  target_benchmark_id uuid default null,
  target_metadata jsonb default '{}'::jsonb,
  target_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  reference_row public.skpe_indicator_reference_catalog%rowtype;
  previous_row public.skpe_indicator_reference_benchmarks%rowtype;
  benchmark_id uuid;
  audit_event jsonb;
  merged_metadata jsonb;
begin
  perform public.require_platform_super_admin();

  if target_reference_catalog_id is null then
    raise exception 'Informe a referência geral associada ao benchmark.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_source_name, ''))) = 0 then
    raise exception 'Informe a fonte do benchmark.' using errcode = '22023';
  end if;

  if length(trim(coalesce(target_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo da inclusão ou alteração do benchmark.' using errcode = '22023';
  end if;

  select * into reference_row
  from public.skpe_indicator_reference_catalog
  where id = target_reference_catalog_id;

  if not found then
    raise exception 'Referência do Catálogo GERAL não encontrada.' using errcode = '22023';
  end if;

  if target_benchmark_id is not null then
    select * into previous_row
    from public.skpe_indicator_reference_benchmarks
    where id = target_benchmark_id
    for update;

    if not found or previous_row.reference_indicator_id <> target_reference_catalog_id then
      raise exception 'Benchmark não encontrado para a referência informada.' using errcode = '22023';
    end if;
  end if;

  audit_event := jsonb_build_object(
    'action', case when target_benchmark_id is null then 'created' else 'updated' end,
    'reason', trim(target_change_reason),
    'changedAt', timezone('utc', now()),
    'changedBy', current_user_id
  );

  merged_metadata := coalesce(previous_row.metadata, '{}'::jsonb)
    || coalesce(target_metadata, '{}'::jsonb)
    || jsonb_build_object(
      'lastChangeReason', trim(target_change_reason),
      'lastChangedAt', timezone('utc', now()),
      'lastChangedBy', current_user_id,
      'changeHistory', coalesce(previous_row.metadata->'changeHistory', '[]'::jsonb) || jsonb_build_array(audit_event)
    );

  if target_benchmark_id is null then
    benchmark_id := gen_random_uuid();

    insert into public.skpe_indicator_reference_benchmarks (
      id, reference_indicator_id, benchmark_type, source_name, source_reference,
      reference_period, population_context, benchmark_value, lower_bound, upper_bound,
      applicability, comparability_notes, confidence_level, verified_at, verified_by,
      status, metadata, created_at, created_by, updated_at, updated_by
    ) values (
      benchmark_id, target_reference_catalog_id, target_benchmark_type, trim(target_source_name),
      nullif(trim(coalesce(target_source_reference, '')), ''),
      nullif(trim(coalesce(target_reference_period, '')), ''),
      nullif(trim(coalesce(target_population_context, '')), ''),
      target_benchmark_value, target_lower_bound, target_upper_bound,
      nullif(trim(coalesce(target_applicability, '')), ''),
      nullif(trim(coalesce(target_comparability_notes, '')), ''),
      nullif(trim(coalesce(target_confidence_level, '')), ''),
      case when target_status = 'active' then timezone('utc', now()) else null end,
      case when target_status = 'active' then current_user_id else null end,
      target_status, merged_metadata, timezone('utc', now()), current_user_id,
      timezone('utc', now()), current_user_id
    );
  else
    benchmark_id := target_benchmark_id;

    update public.skpe_indicator_reference_benchmarks
    set
      benchmark_type = target_benchmark_type,
      source_name = trim(target_source_name),
      source_reference = nullif(trim(coalesce(target_source_reference, '')), ''),
      reference_period = nullif(trim(coalesce(target_reference_period, '')), ''),
      population_context = nullif(trim(coalesce(target_population_context, '')), ''),
      benchmark_value = target_benchmark_value,
      lower_bound = target_lower_bound,
      upper_bound = target_upper_bound,
      applicability = nullif(trim(coalesce(target_applicability, '')), ''),
      comparability_notes = nullif(trim(coalesce(target_comparability_notes, '')), ''),
      confidence_level = nullif(trim(coalesce(target_confidence_level, '')), ''),
      verified_at = case when target_status = 'active' then coalesce(previous_row.verified_at, timezone('utc', now())) else previous_row.verified_at end,
      verified_by = case when target_status = 'active' then coalesce(previous_row.verified_by, current_user_id) else previous_row.verified_by end,
      status = target_status,
      metadata = merged_metadata,
      updated_at = timezone('utc', now()),
      updated_by = current_user_id
    where id = target_benchmark_id;
  end if;

  return benchmark_id;
end;
$$;

comment on function public.upsert_platform_measure_reference_benchmark(uuid, text, text, text, text, text, numeric, numeric, numeric, text, text, text, text, uuid, jsonb, text) is
  'Inclusão/alteração governada de benchmark do Catálogo GERAL, restrita a Platform Super Admin e com motivo obrigatório.';

revoke all on function public.upsert_platform_measure_reference_benchmark(uuid, text, text, text, text, text, numeric, numeric, numeric, text, text, text, text, uuid, jsonb, text) from public;
revoke all on function public.upsert_platform_measure_reference_benchmark(uuid, text, text, text, text, text, numeric, numeric, numeric, text, text, text, text, uuid, jsonb, text) from anon;
grant execute on function public.upsert_platform_measure_reference_benchmark(uuid, text, text, text, text, text, numeric, numeric, numeric, text, text, text, text, uuid, jsonb, text) to authenticated;
