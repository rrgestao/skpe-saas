create or replace function public.get_sparks_measure_reference_catalog(
  target_organization_id uuid,
  target_source_module_code text default null
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
  benchmarks jsonb,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_module_code text := upper(trim(coalesce(target_source_module_code, '')));
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.' using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.' using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
  ) then
    raise exception 'Acesso negado: somente a Administração da Organização pode consultar o Catálogo GERAL de Medidas e Desempenho.'
      using errcode = '42501';
  end if;

  if normalized_module_code <> '' and normalized_module_code <> 'SK-PE' then
    raise exception 'O adaptador de catálogo deste gate está habilitado somente para SK-PE.'
      using errcode = '0A000';
  end if;

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
            'status', benchmark.status
          )
          order by benchmark.reference_period desc nulls last, benchmark.source_name
        )
        from public.sparks_measure_reference_benchmarks benchmark
        where benchmark.reference_indicator_id = catalog.id
          and (benchmark.status is null or benchmark.status <> 'archived')
      ),
      '[]'::jsonb
    ) as benchmarks,
    catalog.updated_at
  from public.sparks_measure_reference_catalog catalog
  where catalog.is_current = true
    and lower(trim(coalesce(catalog.status, 'active'))) = 'active'
  order by catalog.catalog_code, catalog.name;
end;
$$;

comment on function public.get_sparks_measure_reference_catalog(uuid, text) is
  'Leitura governada do Catálogo GERAL de Medidas e Desempenho pela Administração da Organização. O catálogo permanece referência transversal; nenhuma cópia organizacional é criada por esta leitura.';

revoke all on function public.get_sparks_measure_reference_catalog(uuid, text) from public;
revoke all on function public.get_sparks_measure_reference_catalog(uuid, text) from anon;
grant execute on function public.get_sparks_measure_reference_catalog(uuid, text) to authenticated;

create or replace function public.adopt_sparks_measure_reference_indicator(
  target_organization_id uuid,
  target_source_module_code text,
  target_source_context_id uuid,
  target_subject_type text,
  target_subject_id uuid,
  target_reference_catalog_id uuid,
  target_code text default null,
  target_name text default null,
  target_description text default null,
  target_formula_text text default null,
  target_unit text default null,
  target_polarity text default null,
  target_measurement_frequency text default null,
  target_data_source text default null,
  target_owner_user_id uuid default null,
  target_status text default 'draft',
  target_reference_adaptation_notes text default null,
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
  normalized_module_code text := upper(trim(coalesce(target_source_module_code, '')));
  normalized_subject_type text := lower(trim(coalesce(target_subject_type, '')));
  catalog_row public.sparks_measure_reference_catalog%rowtype;
  formulation_row public.skpe_strategic_formulations%rowtype;
  legacy_row public.skpe_indicators%rowtype;
  adopted_indicator_id uuid;
  adopted_metadata jsonb;
  effective_code text;
  effective_name text;
  effective_description text;
  effective_formula text;
  effective_unit text;
  effective_polarity text;
  effective_frequency text;
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.' using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.' using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
  ) then
    raise exception 'Acesso negado: somente a Administração da Organização pode adotar referências de Medidas e Desempenho.'
      using errcode = '42501';
  end if;

  if normalized_module_code <> 'SK-PE' then
    raise exception 'A adoção governada deste gate está habilitada somente para SK-PE.'
      using errcode = '0A000';
  end if;

  if normalized_subject_type <> 'strategic_objective' then
    raise exception 'A adoção SK-PE deste gate suporta somente strategic_objective.'
      using errcode = '0A000';
  end if;

  if target_source_context_id is null or target_subject_id is null or target_reference_catalog_id is null then
    raise exception 'Contexto, Objetivo Estratégico e referência do Catálogo GERAL são obrigatórios.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(target_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo da adoção ou parametrização organizacional.'
      using errcode = '22023';
  end if;

  select *
  into catalog_row
  from public.sparks_measure_reference_catalog
  where id = target_reference_catalog_id
    and is_current = true
    and lower(trim(coalesce(status, 'active'))) = 'active';

  if not found then
    raise exception 'Referência vigente do Catálogo GERAL não encontrada.'
      using errcode = '22023';
  end if;

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_source_context_id;

  if not found or formulation_row.organization_id <> target_organization_id then
    raise exception 'A Formulação Estratégica deve pertencer à organização informada.'
      using errcode = '22023';
  end if;

  effective_code := coalesce(nullif(trim(target_code), ''), catalog_row.catalog_code);
  effective_name := coalesce(nullif(trim(target_name), ''), catalog_row.name);
  effective_description := coalesce(nullif(trim(target_description), ''), catalog_row.description);
  effective_formula := coalesce(nullif(trim(target_formula_text), ''), catalog_row.formula_text);
  effective_unit := coalesce(nullif(trim(target_unit), ''), catalog_row.unit);
  effective_polarity := coalesce(nullif(trim(target_polarity), ''), catalog_row.polarity);
  effective_frequency := coalesce(nullif(trim(target_measurement_frequency), ''), catalog_row.measurement_frequency);

  adopted_metadata := coalesce(target_metadata, '{}'::jsonb)
    || jsonb_build_object(
      'referenceCatalogId', catalog_row.id,
      'referenceCatalogCode', catalog_row.catalog_code,
      'referenceCatalogVersion', catalog_row.version_number,
      'referenceAdoptedAt', timezone('utc', now()),
      'referenceAdoptedBy', current_user_id,
      'organizationAdoption', true
    );

  adopted_indicator_id := public.sparks_upsert_measure_indicator(
    'SK-PE',
    'strategic_formulation',
    target_source_context_id,
    'strategic_objective',
    target_subject_id,
    effective_code,
    effective_name,
    effective_description,
    effective_formula,
    null,
    effective_unit,
    effective_polarity,
    effective_frequency,
    nullif(trim(coalesce(target_data_source, '')), ''),
    null,
    null,
    target_owner_user_id,
    catalog_row.indicator_category,
    null,
    null,
    null,
    null,
    coalesce(nullif(lower(trim(target_status)), ''), 'draft'),
    null,
    adopted_metadata,
    target_change_reason
  );

  update public.skpe_indicators
  set
    reference_catalog_id = catalog_row.id,
    reference_adaptation_notes = nullif(trim(coalesce(target_reference_adaptation_notes, '')), ''),
    metadata = coalesce(metadata, '{}'::jsonb) || adopted_metadata,
    updated_by = current_user_id
  where id = adopted_indicator_id
  returning * into legacy_row;

  if not found then
    raise exception 'Indicador adotado não foi materializado no adaptador SK-PE.'
      using errcode = 'P0001';
  end if;

  update public.sparks_measure_indicators
  set
    organization_id = legacy_row.organization_id,
    source_project_id = legacy_row.project_id,
    source_context_id = legacy_row.formulation_id,
    source_module_code = 'SK-PE',
    context_type = 'strategic_formulation',
    code = legacy_row.code,
    name = legacy_row.name,
    description = legacy_row.description,
    indicator_scope = legacy_row.indicator_scope,
    subject_type = 'strategic_objective',
    subject_id = legacy_row.strategic_objective_id,
    formula_text = legacy_row.formula_text,
    unit = legacy_row.unit,
    polarity = legacy_row.polarity,
    measurement_frequency = legacy_row.measurement_frequency,
    data_source = legacy_row.data_source,
    baseline_value = legacy_row.baseline_value,
    baseline_date = legacy_row.baseline_date,
    owner_user_id = legacy_row.owner_user_id,
    status = legacy_row.status,
    reference_catalog_id = catalog_row.id,
    reference_adaptation_notes = legacy_row.reference_adaptation_notes,
    metadata = coalesce(legacy_row.metadata, '{}'::jsonb) || adopted_metadata,
    updated_at = legacy_row.updated_at,
    updated_by = current_user_id
  where id = adopted_indicator_id;

  if not found then
    insert into public.sparks_measure_indicators (
      id, organization_id, source_project_id, source_context_id, source_module_code,
      context_type, code, name, description, indicator_scope, subject_type, subject_id,
      formula_text, unit, polarity, measurement_frequency, data_source, baseline_value,
      baseline_date, owner_user_id, status, reference_catalog_id,
      reference_adaptation_notes, metadata, created_at, created_by, updated_at, updated_by
    ) values (
      legacy_row.id, legacy_row.organization_id, legacy_row.project_id, legacy_row.formulation_id,
      'SK-PE', 'strategic_formulation', legacy_row.code, legacy_row.name, legacy_row.description,
      legacy_row.indicator_scope, 'strategic_objective', legacy_row.strategic_objective_id,
      legacy_row.formula_text, legacy_row.unit, legacy_row.polarity,
      legacy_row.measurement_frequency, legacy_row.data_source, legacy_row.baseline_value,
      legacy_row.baseline_date, legacy_row.owner_user_id, legacy_row.status, catalog_row.id,
      legacy_row.reference_adaptation_notes,
      coalesce(legacy_row.metadata, '{}'::jsonb) || adopted_metadata,
      legacy_row.created_at, legacy_row.created_by, legacy_row.updated_at, current_user_id
    );
  end if;

  return adopted_indicator_id;
end;
$$;

comment on function public.adopt_sparks_measure_reference_indicator(uuid, text, uuid, text, uuid, uuid, text, text, text, text, text, text, text, text, uuid, text, text, jsonb, text) is
  'Adoção governada Catálogo GERAL -> Organização -> contexto SK-PE. Mantém reference_catalog_id como vínculo canônico; adaptações organizacionais são registradas sem duplicar a fonte geral.';

revoke all on function public.adopt_sparks_measure_reference_indicator(uuid, text, uuid, text, uuid, uuid, text, text, text, text, text, text, text, text, uuid, text, text, jsonb, text) from public;
revoke all on function public.adopt_sparks_measure_reference_indicator(uuid, text, uuid, text, uuid, uuid, text, text, text, text, text, text, text, text, uuid, text, text, jsonb, text) from anon;
grant execute on function public.adopt_sparks_measure_reference_indicator(uuid, text, uuid, text, uuid, uuid, text, text, text, text, text, text, text, text, uuid, text, text, jsonb, text) to authenticated;
