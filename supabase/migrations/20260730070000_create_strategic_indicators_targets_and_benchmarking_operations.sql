-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-05 — Indicadores Estratégicos, Metas de Longo Prazo
--         e Benchmarking
--
-- Escopo:
-- 1. Pacote operacional e validável da FE-05.
-- 2. Gestão auditada de Indicadores Estratégicos vinculados aos OEs.
-- 3. Gestão auditada de Metas de Longo Prazo e metas intermediárias.
-- 4. Gestão auditada e verificável de referências de benchmarking.
-- 5. Prontidão metodológica específica da FE-05.
-- 6. Bloqueio do avanço da Formulação enquanto a FE-05 estiver
--    incompleta ou não validada.
-- 7. Consulta consolidada e histórico de auditoria.
--
-- Fora de escopo:
-- - implementação completa de OKRs;
-- - Resultados-Chave;
-- - indicadores de Resultados-Chave;
-- - Iniciativas.
--
-- Princípios de segurança:
-- - leitura por RLS;
-- - escrita somente por RPCs SECURITY DEFINER;
-- - set search_path = '';
-- - justificativa obrigatória;
-- - auditoria antes/depois;
-- - nenhuma política ALL para authenticated;
-- - nenhuma escrita direta para authenticated;
-- - funções internas não executáveis por authenticated.
-- ============================================================

begin;

-- ============================================================
-- 1. PACOTE DE GOVERNANÇA DA FE-05
-- ============================================================

create table if not exists public.skpe_indicator_packages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  status text not null default 'in_elaboration',
  baseline_required boolean not null default true,
  intermediate_targets_recommended boolean not null default true,
  benchmark_recommended boolean not null default true,
  automated_collection_recommended boolean not null default true,
  max_indicators_per_objective integer not null default 5,
  financial_concentration_threshold numeric(5,2) not null default 60.00,
  baseline_freshness_months integer not null default 24,
  validation_notes text,
  submitted_for_validation_at timestamptz,
  submitted_for_validation_by uuid
    references public.profiles(id) on delete set null,
  validated_at timestamptz,
  validated_by uuid
    references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_indicator_packages_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_indicator_packages_status_check
    check (status in (
      'in_elaboration',
      'pending_validation',
      'validated'
    )),
  constraint skpe_indicator_packages_max_per_objective_check
    check (max_indicators_per_objective between 1 and 20),
  constraint skpe_indicator_packages_financial_threshold_check
    check (financial_concentration_threshold between 0 and 100),
  constraint skpe_indicator_packages_freshness_check
    check (baseline_freshness_months between 1 and 120),
  constraint skpe_indicator_packages_unique
    unique (formulation_id)
);

comment on table public.skpe_indicator_packages is
  'Cabeçalho de governança e validação do pacote FE-05 de Indicadores Estratégicos, Metas de Longo Prazo e Benchmarking.';

comment on column public.skpe_indicator_packages.baseline_required is
  'Regra padrão da versão para exigir linha de base. Pode ser sobrescrita por indicador em metadata.baselineRequired.';

comment on column public.skpe_indicator_packages.financial_concentration_threshold is
  'Percentual a partir do qual a concentração de indicadores financeiros gera recomendação metodológica.';

create index if not exists idx_skpe_indicator_packages_scope
  on public.skpe_indicator_packages(
    organization_id,
    project_id,
    formulation_id,
    status
  );

create index if not exists idx_skpe_indicators_objective_readiness
  on public.skpe_indicators(
    formulation_id,
    strategic_objective_id,
    indicator_scope,
    status,
    code
  );

create index if not exists idx_skpe_targets_readiness
  on public.skpe_indicator_targets(
    formulation_id,
    indicator_id,
    target_type,
    status,
    period_start,
    period_end
  );

create index if not exists idx_skpe_benchmarks_readiness
  on public.skpe_benchmark_references(
    formulation_id,
    indicator_id,
    status,
    benchmark_type
  );

-- As tabelas estruturais da FE-00 já possuíam updated_at, mas não havia
-- gatilhos próprios confirmados no repositório para mantê-lo em cada mutação.
drop trigger if exists skpe_indicators_set_updated_at
  on public.skpe_indicators;
create trigger skpe_indicators_set_updated_at
before update on public.skpe_indicators
for each row
execute function public.set_updated_at();

drop trigger if exists skpe_indicator_targets_set_updated_at
  on public.skpe_indicator_targets;
create trigger skpe_indicator_targets_set_updated_at
before update on public.skpe_indicator_targets
for each row
execute function public.set_updated_at();

drop trigger if exists skpe_benchmark_references_set_updated_at
  on public.skpe_benchmark_references;
create trigger skpe_benchmark_references_set_updated_at
before update on public.skpe_benchmark_references
for each row
execute function public.set_updated_at();

drop trigger if exists skpe_indicator_packages_set_updated_at
  on public.skpe_indicator_packages;

create trigger skpe_indicator_packages_set_updated_at
before update on public.skpe_indicator_packages
for each row
execute function public.set_updated_at();

alter table public.skpe_indicator_packages enable row level security;

drop policy if exists skpe_indicator_packages_select
  on public.skpe_indicator_packages;

create policy skpe_indicator_packages_select
on public.skpe_indicator_packages
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop trigger if exists skpe_indicator_packages_guard_formulation
  on public.skpe_indicator_packages;

create trigger skpe_indicator_packages_guard_formulation
before insert or update or delete
on public.skpe_indicator_packages
for each row
execute function public.skpe_guard_approved_formulation_content();

-- ============================================================
-- 2. FUNÇÕES INTERNAS DO PACOTE
-- ============================================================

create or replace function public.ensure_skpe_indicator_package(
  p_formulation_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_indicator_packages%rowtype;
  source_package public.skpe_indicator_packages%rowtype;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select *
  into package_row
  from public.skpe_indicator_packages
  where formulation_id = p_formulation_id
  for update;

  if found then
    return package_row.id;
  end if;

  if formulation_row.derived_from_formulation_id is not null then
    select *
    into source_package
    from public.skpe_indicator_packages
    where formulation_id = formulation_row.derived_from_formulation_id;
  end if;

  insert into public.skpe_indicator_packages (
    organization_id,
    project_id,
    formulation_id,
    status,
    baseline_required,
    intermediate_targets_recommended,
    benchmark_recommended,
    automated_collection_recommended,
    max_indicators_per_objective,
    financial_concentration_threshold,
    baseline_freshness_months,
    metadata,
    created_by,
    updated_by
  )
  values (
    formulation_row.organization_id,
    formulation_row.project_id,
    formulation_row.id,
    'in_elaboration',
    coalesce(source_package.baseline_required, true),
    coalesce(source_package.intermediate_targets_recommended, true),
    coalesce(source_package.benchmark_recommended, true),
    coalesce(source_package.automated_collection_recommended, true),
    coalesce(source_package.max_indicators_per_objective, 5),
    coalesce(source_package.financial_concentration_threshold, 60.00),
    coalesce(source_package.baseline_freshness_months, 24),
    coalesce(source_package.metadata, '{}'::jsonb)
      || case
        when source_package.id is null then '{}'::jsonb
        else jsonb_build_object(
          'clonedFromIndicatorPackageId', source_package.id,
          'clonedFromFormulationId', formulation_row.derived_from_formulation_id
        )
      end,
    auth.uid(),
    auth.uid()
  )
  returning *
  into package_row;

  update public.skpe_indicators
  set
    metadata = (coalesce(metadata, '{}'::jsonb)
      - 'validatedAt'
      - 'validatedBy')
      || jsonb_build_object('validationStatus', 'draft'),
    updated_by = auth.uid()
  where formulation_id = p_formulation_id
    and indicator_scope = 'strategic_kpi'
    and status <> 'archived';

  perform public.skpe_record_operational_audit(
    package_row.organization_id,
    package_row.project_id,
    'indicator_package',
    package_row.id,
    'indicator_package_created',
    'Criação automática do pacote operacional da FE-05.',
    null,
    to_jsonb(package_row)
  );

  return package_row.id;
end;
$$;

comment on function public.ensure_skpe_indicator_package(uuid) is
  'Função interna que garante o cabeçalho de governança da FE-05 para uma Formulação editável.';

create or replace function public.skpe_invalidate_indicator_package(
  p_formulation_id uuid,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  package_id uuid;
  previous_package public.skpe_indicator_packages%rowtype;
  updated_package public.skpe_indicator_packages%rowtype;
begin
  package_id := public.ensure_skpe_indicator_package(p_formulation_id);

  select *
  into previous_package
  from public.skpe_indicator_packages
  where id = package_id
  for update;

  update public.skpe_indicators
  set
    metadata = (coalesce(metadata, '{}'::jsonb)
      - 'validatedAt'
      - 'validatedBy')
      || jsonb_build_object('validationStatus', 'draft'),
    updated_by = auth.uid()
  where formulation_id = p_formulation_id
    and indicator_scope = 'strategic_kpi'
    and status <> 'archived';

  if previous_package.status = 'in_elaboration'
     and previous_package.validation_notes is null
     and previous_package.submitted_for_validation_at is null
     and previous_package.validated_at is null then
    return previous_package.id;
  end if;

  update public.skpe_indicator_packages
  set
    status = 'in_elaboration',
    validation_notes = null,
    submitted_for_validation_at = null,
    submitted_for_validation_by = null,
    validated_at = null,
    validated_by = null,
    updated_by = auth.uid()
  where id = previous_package.id
  returning *
  into updated_package;

  perform public.skpe_record_operational_audit(
    updated_package.organization_id,
    updated_package.project_id,
    'indicator_package',
    updated_package.id,
    'indicator_package_invalidated',
    coalesce(
      nullif(trim(p_reason), ''),
      'Alteração do conteúdo invalidou a validação anterior da FE-05.'
    ),
    to_jsonb(previous_package),
    to_jsonb(updated_package)
  );

  return updated_package.id;
end;
$$;

comment on function public.skpe_invalidate_indicator_package(uuid, text) is
  'Função interna que retorna a FE-05 para elaboração após qualquer mutação de conteúdo.';

-- ============================================================
-- 3. CONFIGURAÇÃO METODOLÓGICA DA FE-05
-- ============================================================

create or replace function public.configure_skpe_indicator_package(
  p_formulation_id uuid,
  p_baseline_required boolean default true,
  p_intermediate_targets_recommended boolean default true,
  p_benchmark_recommended boolean default true,
  p_automated_collection_recommended boolean default true,
  p_max_indicators_per_objective integer default 5,
  p_financial_concentration_threshold numeric default 60.00,
  p_baseline_freshness_months integer default 24,
  p_metadata jsonb default '{}'::jsonb,
  p_change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_id uuid;
  previous_package public.skpe_indicator_packages%rowtype;
  updated_package public.skpe_indicator_packages%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(p_formulation_id);

  if p_max_indicators_per_objective not between 1 and 20 then
    raise exception 'O limite recomendado de indicadores por Objetivo deve estar entre 1 e 20.'
      using errcode = '22023';
  end if;

  if p_financial_concentration_threshold not between 0 and 100 then
    raise exception 'O limiar de concentração financeira deve estar entre 0 e 100.'
      using errcode = '22023';
  end if;

  if p_baseline_freshness_months not between 1 and 120 then
    raise exception 'A atualidade da linha de base deve estar entre 1 e 120 meses.'
      using errcode = '22023';
  end if;

  package_id := public.ensure_skpe_indicator_package(p_formulation_id);

  select *
  into previous_package
  from public.skpe_indicator_packages
  where id = package_id
  for update;

  update public.skpe_indicator_packages
  set
    baseline_required = coalesce(p_baseline_required, true),
    intermediate_targets_recommended = coalesce(p_intermediate_targets_recommended, true),
    benchmark_recommended = coalesce(p_benchmark_recommended, true),
    automated_collection_recommended = coalesce(p_automated_collection_recommended, true),
    max_indicators_per_objective = p_max_indicators_per_objective,
    financial_concentration_threshold = p_financial_concentration_threshold,
    baseline_freshness_months = p_baseline_freshness_months,
    status = 'in_elaboration',
    validation_notes = null,
    submitted_for_validation_at = null,
    submitted_for_validation_by = null,
    validated_at = null,
    validated_by = null,
    metadata = coalesce(previous_package.metadata, '{}'::jsonb)
      || coalesce(p_metadata, '{}'::jsonb),
    updated_by = auth.uid()
  where id = package_id
  returning *
  into updated_package;

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'indicator_package',
    package_id,
    'indicator_package_configured',
    p_change_reason,
    to_jsonb(previous_package),
    to_jsonb(updated_package)
  );

  return to_jsonb(updated_package);
end;
$$;

-- ============================================================
-- 4. INDICADORES ESTRATÉGICOS — CRIAÇÃO E ATUALIZAÇÃO
-- ============================================================

create or replace function public.upsert_skpe_strategic_indicator(
  p_formulation_id uuid,
  p_code text,
  p_name text,
  p_description text,
  p_strategic_objective_id uuid,
  p_formula_text text,
  p_calculation_method text,
  p_unit text,
  p_polarity text,
  p_measurement_frequency text,
  p_data_source text,
  p_baseline_value numeric default null,
  p_baseline_date date default null,
  p_owner_user_id uuid default null,
  p_indicator_category text default null,
  p_collection_method text default null,
  p_collection_automatable boolean default null,
  p_responsible_area text default null,
  p_baseline_required_override boolean default null,
  p_status text default 'active',
  p_indicator_id uuid default null,
  p_metadata jsonb default '{}'::jsonb,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  objective_row public.skpe_strategic_objectives%rowtype;
  previous_indicator public.skpe_indicators%rowtype;
  updated_indicator public.skpe_indicators%rowtype;
  indicator_id uuid;
  normalized_frequency text;
  normalized_category text;
  merged_metadata jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select *
  into objective_row
  from public.skpe_strategic_objectives
  where id = p_strategic_objective_id;

  if not found
     or objective_row.formulation_id <> p_formulation_id
     or objective_row.organization_id <> formulation_row.organization_id
     or objective_row.project_id <> formulation_row.project_id
     or objective_row.status <> 'active' then
    raise exception 'O Objetivo Estratégico deve estar ativo e pertencer à mesma Formulação, organização e projeto.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(p_code, ''))) = 0 then
    raise exception 'Informe o código do Indicador Estratégico.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(p_name, ''))) = 0 then
    raise exception 'Informe o nome do Indicador Estratégico.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(p_unit, ''))) = 0 then
    raise exception 'Informe a unidade de medida do Indicador Estratégico.'
      using errcode = '22023';
  end if;

  if p_polarity not in (
    'higher_is_better',
    'lower_is_better',
    'target_is_better',
    'range_is_better'
  ) then
    raise exception 'Polaridade inválida para o Indicador Estratégico.'
      using errcode = '22023';
  end if;

  if p_status not in ('draft', 'active', 'inactive') then
    raise exception 'Situação inválida para o Indicador Estratégico. O arquivamento deve usar a RPC específica.'
      using errcode = '22023';
  end if;

  normalized_frequency := nullif(lower(trim(coalesce(p_measurement_frequency, ''))), '');
  if normalized_frequency is not null
     and normalized_frequency not in (
       'daily',
       'weekly',
       'monthly',
       'bimonthly',
       'quarterly',
       'semiannual',
       'annual',
       'on_demand'
     ) then
    raise exception 'Frequência inválida. Use daily, weekly, monthly, bimonthly, quarterly, semiannual, annual ou on_demand.'
      using errcode = '22023';
  end if;

  normalized_category := nullif(lower(trim(coalesce(p_indicator_category, ''))), '');
  if normalized_category is not null
     and normalized_category not in (
       'financial',
       'customer_market',
       'internal_process',
       'people_learning',
       'governance',
       'social',
       'environmental',
       'sustainability',
       'other'
     ) then
    raise exception 'Categoria metodológica inválida para o Indicador.'
      using errcode = '22023';
  end if;

  if (p_baseline_value is null) <> (p_baseline_date is null) then
    raise exception 'Linha de base e data da linha de base devem ser informadas em conjunto.'
      using errcode = '22023';
  end if;

  if p_indicator_id is not null then
    select *
    into previous_indicator
    from public.skpe_indicators
    where id = p_indicator_id
    for update;

    if not found
       or previous_indicator.formulation_id <> p_formulation_id
       or previous_indicator.indicator_scope <> 'strategic_kpi'
       or previous_indicator.status = 'archived' then
      raise exception 'Indicador Estratégico não encontrado nesta Formulação.'
        using errcode = '22023';
    end if;
  end if;

  merged_metadata := coalesce(previous_indicator.metadata, '{}'::jsonb)
    || coalesce(p_metadata, '{}'::jsonb)
    || jsonb_strip_nulls(jsonb_build_object(
      'calculationMethod', nullif(trim(coalesce(p_calculation_method, '')), ''),
      'indicatorCategory', normalized_category,
      'collectionMethod', nullif(trim(coalesce(p_collection_method, '')), ''),
      'collectionAutomatable', p_collection_automatable,
      'responsibleArea', nullif(trim(coalesce(p_responsible_area, '')), ''),
      'baselineRequired', p_baseline_required_override,
      'validationStatus', 'draft'
    ))
    - 'validatedAt'
    - 'validatedBy';

  if p_indicator_id is null then
    insert into public.skpe_indicators (
      organization_id,
      project_id,
      formulation_id,
      code,
      name,
      description,
      indicator_scope,
      strategic_objective_id,
      key_result_id,
      formula_text,
      unit,
      polarity,
      measurement_frequency,
      data_source,
      baseline_value,
      baseline_date,
      owner_user_id,
      status,
      metadata,
      created_by,
      updated_by
    )
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      trim(p_code),
      trim(p_name),
      nullif(trim(coalesce(p_description, '')), ''),
      'strategic_kpi',
      objective_row.id,
      null,
      nullif(trim(coalesce(p_formula_text, '')), ''),
      trim(p_unit),
      p_polarity,
      normalized_frequency,
      nullif(trim(coalesce(p_data_source, '')), ''),
      p_baseline_value,
      p_baseline_date,
      p_owner_user_id,
      p_status,
      merged_metadata,
      auth.uid(),
      auth.uid()
    )
    returning *
    into updated_indicator;

    indicator_id := updated_indicator.id;
  else
    update public.skpe_indicators
    set
      code = trim(p_code),
      name = trim(p_name),
      description = nullif(trim(coalesce(p_description, '')), ''),
      strategic_objective_id = objective_row.id,
      key_result_id = null,
      indicator_scope = 'strategic_kpi',
      formula_text = nullif(trim(coalesce(p_formula_text, '')), ''),
      unit = trim(p_unit),
      polarity = p_polarity,
      measurement_frequency = normalized_frequency,
      data_source = nullif(trim(coalesce(p_data_source, '')), ''),
      baseline_value = p_baseline_value,
      baseline_date = p_baseline_date,
      owner_user_id = p_owner_user_id,
      status = p_status,
      metadata = merged_metadata,
      updated_by = auth.uid()
    where id = p_indicator_id
    returning *
    into updated_indicator;

    indicator_id := updated_indicator.id;
  end if;

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'strategic_indicator',
    indicator_id,
    case when p_indicator_id is null
      then 'strategic_indicator_created'
      else 'strategic_indicator_updated'
    end,
    p_change_reason,
    case when p_indicator_id is null then null else to_jsonb(previous_indicator) end,
    to_jsonb(updated_indicator)
  );

  perform public.skpe_invalidate_indicator_package(
    p_formulation_id,
    p_change_reason
  );

  return indicator_id;
end;
$$;

create or replace function public.archive_skpe_strategic_indicator(
  p_indicator_id uuid,
  p_change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_indicator public.skpe_indicators%rowtype;
  updated_indicator public.skpe_indicators%rowtype;
  target_count integer := 0;
  benchmark_count integer := 0;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
  into previous_indicator
  from public.skpe_indicators
  where id = p_indicator_id
  for update;

  if not found or previous_indicator.indicator_scope <> 'strategic_kpi' then
    raise exception 'Indicador Estratégico não encontrado.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(previous_indicator.formulation_id);

  update public.skpe_indicator_targets
  set
    status = 'superseded',
    updated_by = auth.uid()
  where indicator_id = p_indicator_id
    and status <> 'superseded';
  get diagnostics target_count = row_count;

  update public.skpe_benchmark_references
  set
    status = 'archived',
    updated_by = auth.uid()
  where indicator_id = p_indicator_id
    and status <> 'archived';
  get diagnostics benchmark_count = row_count;

  update public.skpe_indicators
  set
    status = 'archived',
    updated_by = auth.uid(),
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'archivedAt', timezone('utc', now()),
        'supersededTargets', target_count,
        'archivedBenchmarks', benchmark_count
      )
  where id = p_indicator_id
  returning *
  into updated_indicator;

  perform public.skpe_record_operational_audit(
    updated_indicator.organization_id,
    updated_indicator.project_id,
    'strategic_indicator',
    updated_indicator.id,
    'strategic_indicator_archived',
    p_change_reason,
    to_jsonb(previous_indicator),
    to_jsonb(updated_indicator)
  );

  perform public.skpe_invalidate_indicator_package(
    updated_indicator.formulation_id,
    p_change_reason
  );

  return jsonb_build_object(
    'indicatorId', updated_indicator.id,
    'status', updated_indicator.status,
    'supersededTargets', target_count,
    'archivedBenchmarks', benchmark_count
  );
end;
$$;

-- ============================================================
-- 5. METAS — CRIAÇÃO, ATUALIZAÇÃO E SUPERAÇÃO
-- ============================================================

create or replace function public.upsert_skpe_indicator_target(
  p_indicator_id uuid,
  p_target_type text,
  p_period_start date,
  p_period_end date,
  p_target_value numeric,
  p_minimum_value numeric default null,
  p_challenge_value numeric default null,
  p_tolerance_lower numeric default null,
  p_tolerance_upper numeric default null,
  p_owner_user_id uuid default null,
  p_status text default 'active',
  p_target_id uuid default null,
  p_metadata jsonb default '{}'::jsonb,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  indicator_row public.skpe_indicators%rowtype;
  formulation_row public.skpe_strategic_formulations%rowtype;
  project_row public.skpe_projects%rowtype;
  previous_target public.skpe_indicator_targets%rowtype;
  updated_target public.skpe_indicator_targets%rowtype;
  target_id uuid;
  horizon_start_date date;
  horizon_end_date date;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
  into indicator_row
  from public.skpe_indicators
  where id = p_indicator_id;

  if not found
     or indicator_row.indicator_scope <> 'strategic_kpi'
     or indicator_row.status = 'archived' then
    raise exception 'Indicador Estratégico ativo ou em elaboração não encontrado.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(indicator_row.formulation_id);

  if p_target_type not in ('annual', 'intermediate', 'long_term') then
    raise exception 'A FE-05 aceita metas annual, intermediate ou long_term. Metas de ciclo pertencem à etapa de OKRs.'
      using errcode = '22023';
  end if;

  if p_status not in ('draft', 'active') then
    raise exception 'Situação inválida para definição da Meta. Superação e apuração de resultado usam fluxos próprios.'
      using errcode = '22023';
  end if;

  if p_period_start is null or p_period_end is null or p_period_end < p_period_start then
    raise exception 'Informe um período válido para a Meta.'
      using errcode = '22023';
  end if;

  if p_tolerance_lower is not null
     and p_tolerance_upper is not null
     and p_tolerance_lower > p_tolerance_upper then
    raise exception 'A tolerância inferior não pode superar a tolerância superior.'
      using errcode = '22023';
  end if;

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = indicator_row.formulation_id;

  select *
  into project_row
  from public.skpe_projects
  where id = indicator_row.project_id;

  horizon_start_date := coalesce(
    formulation_row.valid_from,
    case
      when project_row.planning_horizon_start_year is null then null
      else make_date(project_row.planning_horizon_start_year, 1, 1)
    end
  );

  horizon_end_date := coalesce(
    formulation_row.valid_until,
    case
      when project_row.planning_horizon_end_year is null then null
      else make_date(project_row.planning_horizon_end_year, 12, 31)
    end
  );

  if horizon_start_date is not null and p_period_start < horizon_start_date then
    raise exception 'A Meta inicia antes do horizonte da Formulação.'
      using errcode = '22023';
  end if;

  if horizon_end_date is not null and p_period_end > horizon_end_date then
    raise exception 'A Meta termina após o horizonte da Formulação.'
      using errcode = '22023';
  end if;

  if p_target_type = 'long_term'
     and exists (
       select 1
       from public.skpe_indicator_targets existing_target
       where existing_target.indicator_id = p_indicator_id
         and existing_target.target_type = 'long_term'
         and existing_target.status <> 'superseded'
         and (p_target_id is null or existing_target.id <> p_target_id)
     ) then
    raise exception 'O Indicador já possui Meta de Longo Prazo vigente. Atualize ou supere a Meta existente.'
      using errcode = '23505';
  end if;

  if indicator_row.baseline_value is not null then
    if indicator_row.polarity = 'higher_is_better'
       and p_target_type = 'long_term'
       and p_target_value < indicator_row.baseline_value then
      raise exception 'A Meta de Longo Prazo é incompatível com a polaridade higher_is_better.'
        using errcode = '22023';
    end if;

    if indicator_row.polarity = 'lower_is_better'
       and p_target_type = 'long_term'
       and p_target_value > indicator_row.baseline_value then
      raise exception 'A Meta de Longo Prazo é incompatível com a polaridade lower_is_better.'
        using errcode = '22023';
    end if;
  end if;

  if indicator_row.polarity = 'range_is_better'
     and p_target_type = 'long_term'
     and (
       p_tolerance_lower is null
       or p_tolerance_upper is null
       or p_target_value < p_tolerance_lower
       or p_target_value > p_tolerance_upper
     ) then
    raise exception 'Indicadores range_is_better exigem tolerâncias inferior e superior contendo o valor-alvo.'
      using errcode = '22023';
  end if;

  if p_target_id is not null then
    select *
    into previous_target
    from public.skpe_indicator_targets
    where id = p_target_id
    for update;

    if not found
       or previous_target.indicator_id <> p_indicator_id
       or previous_target.status = 'superseded' then
      raise exception 'Meta vigente não encontrada para este Indicador.'
        using errcode = '22023';
    end if;
  end if;

  if p_target_id is null then
    insert into public.skpe_indicator_targets (
      organization_id,
      project_id,
      formulation_id,
      indicator_id,
      target_type,
      period_start,
      period_end,
      target_value,
      minimum_value,
      challenge_value,
      tolerance_lower,
      tolerance_upper,
      owner_user_id,
      status,
      metadata,
      created_by,
      updated_by
    )
    values (
      indicator_row.organization_id,
      indicator_row.project_id,
      indicator_row.formulation_id,
      indicator_row.id,
      p_target_type,
      p_period_start,
      p_period_end,
      p_target_value,
      p_minimum_value,
      p_challenge_value,
      p_tolerance_lower,
      p_tolerance_upper,
      p_owner_user_id,
      p_status,
      coalesce(p_metadata, '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning *
    into updated_target;

    target_id := updated_target.id;
  else
    update public.skpe_indicator_targets
    set
      target_type = p_target_type,
      period_start = p_period_start,
      period_end = p_period_end,
      target_value = p_target_value,
      minimum_value = p_minimum_value,
      challenge_value = p_challenge_value,
      tolerance_lower = p_tolerance_lower,
      tolerance_upper = p_tolerance_upper,
      owner_user_id = p_owner_user_id,
      status = p_status,
      metadata = coalesce(previous_target.metadata, '{}'::jsonb)
        || coalesce(p_metadata, '{}'::jsonb),
      updated_by = auth.uid()
    where id = p_target_id
    returning *
    into updated_target;

    target_id := updated_target.id;
  end if;

  perform public.skpe_record_operational_audit(
    indicator_row.organization_id,
    indicator_row.project_id,
    'indicator_target',
    target_id,
    case when p_target_id is null
      then 'indicator_target_created'
      else 'indicator_target_updated'
    end,
    p_change_reason,
    case when p_target_id is null then null else to_jsonb(previous_target) end,
    to_jsonb(updated_target)
  );

  perform public.skpe_invalidate_indicator_package(
    indicator_row.formulation_id,
    p_change_reason
  );

  return target_id;
end;
$$;

create or replace function public.supersede_skpe_indicator_target(
  p_target_id uuid,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_target public.skpe_indicator_targets%rowtype;
  updated_target public.skpe_indicator_targets%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
  into previous_target
  from public.skpe_indicator_targets
  where id = p_target_id
  for update;

  if not found then
    raise exception 'Meta não encontrada.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(previous_target.formulation_id);

  update public.skpe_indicator_targets
  set
    status = 'superseded',
    updated_by = auth.uid()
  where id = p_target_id
  returning *
  into updated_target;

  perform public.skpe_record_operational_audit(
    updated_target.organization_id,
    updated_target.project_id,
    'indicator_target',
    updated_target.id,
    'indicator_target_superseded',
    p_change_reason,
    to_jsonb(previous_target),
    to_jsonb(updated_target)
  );

  perform public.skpe_invalidate_indicator_package(
    updated_target.formulation_id,
    p_change_reason
  );

  return updated_target.id;
end;
$$;

-- ============================================================
-- 6. BENCHMARKING — CRIAÇÃO, ATUALIZAÇÃO E VERIFICAÇÃO
-- ============================================================

create or replace function public.upsert_skpe_benchmark_reference(
  p_indicator_id uuid,
  p_benchmark_type text,
  p_reference_organization text,
  p_source_name text,
  p_source_reference text,
  p_reference_period text,
  p_benchmark_value numeric,
  p_applicability text,
  p_gap_analysis text,
  p_notes text,
  p_indicator_target_id uuid default null,
  p_benchmark_id uuid default null,
  p_metadata jsonb default '{}'::jsonb,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  indicator_row public.skpe_indicators%rowtype;
  target_row public.skpe_indicator_targets%rowtype;
  previous_benchmark public.skpe_benchmark_references%rowtype;
  updated_benchmark public.skpe_benchmark_references%rowtype;
  benchmark_id uuid;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select *
  into indicator_row
  from public.skpe_indicators
  where id = p_indicator_id;

  if not found
     or indicator_row.indicator_scope <> 'strategic_kpi'
     or indicator_row.status = 'archived' then
    raise exception 'Indicador Estratégico não encontrado para o benchmarking.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(indicator_row.formulation_id);

  if p_benchmark_type not in (
    'internal',
    'sector',
    'market',
    'best_practice',
    'regulatory'
  ) then
    raise exception 'Tipo de benchmarking inválido.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(p_source_name, ''))) = 0 then
    raise exception 'Informe a fonte da referência de benchmarking.'
      using errcode = '22023';
  end if;

  if p_indicator_target_id is not null then
    select *
    into target_row
    from public.skpe_indicator_targets
    where id = p_indicator_target_id;

    if not found
       or target_row.indicator_id <> p_indicator_id
       or target_row.formulation_id <> indicator_row.formulation_id then
      raise exception 'A Meta referenciada pelo benchmarking não pertence ao mesmo Indicador e Formulação.'
        using errcode = '22023';
    end if;
  end if;

  if p_benchmark_id is not null then
    select *
    into previous_benchmark
    from public.skpe_benchmark_references
    where id = p_benchmark_id
    for update;

    if not found
       or previous_benchmark.indicator_id <> p_indicator_id
       or previous_benchmark.status = 'archived' then
      raise exception 'Referência de benchmarking não arquivada não encontrada para este Indicador.'
        using errcode = '22023';
    end if;
  end if;

  if p_benchmark_id is null then
    insert into public.skpe_benchmark_references (
      organization_id,
      project_id,
      formulation_id,
      indicator_id,
      indicator_target_id,
      benchmark_type,
      reference_organization,
      source_name,
      source_reference,
      reference_period,
      benchmark_value,
      applicability,
      gap_analysis,
      notes,
      verified_at,
      verified_by,
      status,
      metadata,
      created_by,
      updated_by
    )
    values (
      indicator_row.organization_id,
      indicator_row.project_id,
      indicator_row.formulation_id,
      indicator_row.id,
      p_indicator_target_id,
      p_benchmark_type,
      nullif(trim(coalesce(p_reference_organization, '')), ''),
      trim(p_source_name),
      nullif(trim(coalesce(p_source_reference, '')), ''),
      nullif(trim(coalesce(p_reference_period, '')), ''),
      p_benchmark_value,
      nullif(trim(coalesce(p_applicability, '')), ''),
      nullif(trim(coalesce(p_gap_analysis, '')), ''),
      nullif(trim(coalesce(p_notes, '')), ''),
      null,
      null,
      'draft',
      coalesce(p_metadata, '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning *
    into updated_benchmark;

    benchmark_id := updated_benchmark.id;
  else
    update public.skpe_benchmark_references
    set
      indicator_target_id = p_indicator_target_id,
      benchmark_type = p_benchmark_type,
      reference_organization = nullif(trim(coalesce(p_reference_organization, '')), ''),
      source_name = trim(p_source_name),
      source_reference = nullif(trim(coalesce(p_source_reference, '')), ''),
      reference_period = nullif(trim(coalesce(p_reference_period, '')), ''),
      benchmark_value = p_benchmark_value,
      applicability = nullif(trim(coalesce(p_applicability, '')), ''),
      gap_analysis = nullif(trim(coalesce(p_gap_analysis, '')), ''),
      notes = nullif(trim(coalesce(p_notes, '')), ''),
      verified_at = null,
      verified_by = null,
      status = 'draft',
      metadata = coalesce(previous_benchmark.metadata, '{}'::jsonb)
        || coalesce(p_metadata, '{}'::jsonb),
      updated_by = auth.uid()
    where id = p_benchmark_id
    returning *
    into updated_benchmark;

    benchmark_id := updated_benchmark.id;
  end if;

  perform public.skpe_record_operational_audit(
    indicator_row.organization_id,
    indicator_row.project_id,
    'benchmark_reference',
    benchmark_id,
    case when p_benchmark_id is null
      then 'benchmark_reference_created'
      else 'benchmark_reference_updated'
    end,
    p_change_reason,
    case when p_benchmark_id is null then null else to_jsonb(previous_benchmark) end,
    to_jsonb(updated_benchmark)
  );

  perform public.skpe_invalidate_indicator_package(
    indicator_row.formulation_id,
    p_change_reason
  );

  return benchmark_id;
end;
$$;

create or replace function public.transition_skpe_benchmark_reference(
  p_benchmark_id uuid,
  p_transition_action text,
  p_decision_notes text default null,
  p_change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_action text;
  formulation_status text;
  previous_benchmark public.skpe_benchmark_references%rowtype;
  updated_benchmark public.skpe_benchmark_references%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);

  normalized_action := lower(trim(coalesce(p_transition_action, '')));

  select *
  into previous_benchmark
  from public.skpe_benchmark_references
  where id = p_benchmark_id
  for update;

  if not found then
    raise exception 'Referência de benchmarking não encontrada.'
      using errcode = '22023';
  end if;

  select formulation.status
  into formulation_status
  from public.skpe_strategic_formulations formulation
  where formulation.id = previous_benchmark.formulation_id;

  if formulation_status is null then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if formulation_status not in ('draft', 'in_elaboration') then
    raise exception
      'A versão da Formulação está bloqueada para alteração de benchmarking na situação "%".',
      formulation_status
      using errcode = '55000';
  end if;

  if normalized_action in ('verify', 'activate') then
    if not public.can_validate_skpe_formulation(previous_benchmark.organization_id) then
      raise exception 'Acesso negado para verificar ou ativar benchmarking.'
        using errcode = '42501';
    end if;
  elsif normalized_action in ('return_to_draft', 'archive') then
    if not public.can_manage_skpe_formulation(previous_benchmark.organization_id)
       and not public.can_validate_skpe_formulation(previous_benchmark.organization_id) then
      raise exception 'Acesso negado para alterar a situação do benchmarking.'
        using errcode = '42501';
    end if;
  else
    raise exception 'Transição inválida. Use verify, activate, return_to_draft ou archive.'
      using errcode = '22023';
  end if;

  if normalized_action = 'verify' then
    if previous_benchmark.status <> 'draft' then
      raise exception 'Somente uma referência em rascunho pode ser verificada.'
        using errcode = '55000';
    end if;

    if length(trim(coalesce(previous_benchmark.reference_period, ''))) = 0 then
      raise exception 'Informe o período de referência antes da verificação.'
        using errcode = '22023';
    end if;

    update public.skpe_benchmark_references
    set
      status = 'verified',
      verified_at = timezone('utc', now()),
      verified_by = auth.uid(),
      notes = coalesce(nullif(trim(coalesce(p_decision_notes, '')), ''), notes),
      updated_by = auth.uid()
    where id = p_benchmark_id
    returning *
    into updated_benchmark;

  elsif normalized_action = 'activate' then
    if previous_benchmark.status <> 'verified' then
      raise exception 'Somente uma referência verificada pode ser ativada.'
        using errcode = '55000';
    end if;

    update public.skpe_benchmark_references
    set
      status = 'active',
      notes = coalesce(nullif(trim(coalesce(p_decision_notes, '')), ''), notes),
      updated_by = auth.uid()
    where id = p_benchmark_id
    returning *
    into updated_benchmark;

  elsif normalized_action = 'return_to_draft' then
    if previous_benchmark.status not in ('verified', 'active') then
      raise exception 'Somente uma referência verificada ou ativa pode retornar para rascunho.'
        using errcode = '55000';
    end if;

    update public.skpe_benchmark_references
    set
      status = 'draft',
      verified_at = null,
      verified_by = null,
      notes = coalesce(nullif(trim(coalesce(p_decision_notes, '')), ''), notes),
      updated_by = auth.uid()
    where id = p_benchmark_id
    returning *
    into updated_benchmark;

  elsif normalized_action = 'archive' then
    if previous_benchmark.status = 'archived' then
      raise exception 'A referência de benchmarking já está arquivada.'
        using errcode = '55000';
    end if;

    update public.skpe_benchmark_references
    set
      status = 'archived',
      notes = coalesce(nullif(trim(coalesce(p_decision_notes, '')), ''), notes),
      updated_by = auth.uid()
    where id = p_benchmark_id
    returning *
    into updated_benchmark;
  end if;

  perform public.skpe_record_operational_audit(
    updated_benchmark.organization_id,
    updated_benchmark.project_id,
    'benchmark_reference',
    updated_benchmark.id,
    'benchmark_reference_' || normalized_action,
    p_change_reason,
    to_jsonb(previous_benchmark),
    to_jsonb(updated_benchmark)
  );

  perform public.skpe_invalidate_indicator_package(
    updated_benchmark.formulation_id,
    p_change_reason
  );

  return jsonb_build_object(
    'benchmarkId', updated_benchmark.id,
    'previousStatus', previous_benchmark.status,
    'currentStatus', updated_benchmark.status,
    'transitionAction', normalized_action
  );
end;
$$;

-- ============================================================
-- 7. PRONTIDÃO METODOLÓGICA DA FE-05
-- ============================================================

create or replace function public.get_skpe_indicators_readiness(
  p_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  project_row public.skpe_projects%rowtype;
  package_row public.skpe_indicator_packages%rowtype;
  horizon_start_date date;
  horizon_end_date date;
  issues jsonb;
  counts jsonb;
  content_blocking_count integer;
  total_blocking_count integer;
  active_indicator_count integer := 0;
  financial_indicator_count integer := 0;
  effective_financial_percentage numeric := 0;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado aos Indicadores Estratégicos e Metas.'
      using errcode = '42501';
  end if;

  select *
  into project_row
  from public.skpe_projects
  where id = formulation_row.project_id;

  select *
  into package_row
  from public.skpe_indicator_packages
  where formulation_id = p_formulation_id;

  horizon_start_date := coalesce(
    formulation_row.valid_from,
    case
      when project_row.planning_horizon_start_year is null then null
      else make_date(project_row.planning_horizon_start_year, 1, 1)
    end
  );

  horizon_end_date := coalesce(
    formulation_row.valid_until,
    case
      when project_row.planning_horizon_end_year is null then null
      else make_date(project_row.planning_horizon_end_year, 12, 31)
    end
  );

  select count(*)
  into active_indicator_count
  from public.skpe_indicators indicator
  where indicator.formulation_id = p_formulation_id
    and indicator.indicator_scope = 'strategic_kpi'
    and indicator.status = 'active';

  select count(*)
  into financial_indicator_count
  from public.skpe_indicators indicator
  where indicator.formulation_id = p_formulation_id
    and indicator.indicator_scope = 'strategic_kpi'
    and indicator.status = 'active'
    and lower(coalesce(indicator.metadata ->> 'indicatorCategory', '')) = 'financial';

  if active_indicator_count > 0 then
    effective_financial_percentage :=
      financial_indicator_count::numeric * 100 / active_indicator_count::numeric;
  end if;

  select jsonb_build_object(
    'activeObjectives', (
      select count(*)
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = p_formulation_id
        and objective.status = 'active'
    ),
    'activeIndicators', active_indicator_count,
    'objectivesWithIndicators', (
      select count(distinct indicator.strategic_objective_id)
      from public.skpe_indicators indicator
      where indicator.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
    ),
    'activeLongTermTargets', (
      select count(*)
      from public.skpe_indicator_targets target
      join public.skpe_indicators indicator
        on indicator.id = target.indicator_id
      where target.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
        and target.target_type = 'long_term'
        and target.status <> 'superseded'
    ),
    'activeIntermediateTargets', (
      select count(*)
      from public.skpe_indicator_targets target
      join public.skpe_indicators indicator
        on indicator.id = target.indicator_id
      where target.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
        and target.target_type in ('annual', 'intermediate')
        and target.status <> 'superseded'
    ),
    'verifiedOrActiveBenchmarks', (
      select count(*)
      from public.skpe_benchmark_references benchmark
      join public.skpe_indicators indicator
        on indicator.id = benchmark.indicator_id
      where benchmark.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
        and benchmark.status in ('verified', 'active')
    ),
    'indicatorsWithBaseline', (
      select count(*)
      from public.skpe_indicators indicator
      where indicator.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
        and indicator.baseline_value is not null
        and indicator.baseline_date is not null
    ),
    'indicatorsWithOwner', (
      select count(*)
      from public.skpe_indicators indicator
      where indicator.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
        and indicator.owner_user_id is not null
    ),
    'financialIndicators', financial_indicator_count,
    'financialIndicatorPercentage', round(effective_financial_percentage, 2),
    'automatableIndicators', (
      select count(*)
      from public.skpe_indicators indicator
      where indicator.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
        and lower(coalesce(indicator.metadata ->> 'collectionAutomatable', 'false')) = 'true'
    )
  )
  into counts;

  with issue_rows as (
    select
      'OBJECTIVE_WITHOUT_INDICATOR'::text as code,
      'blocking'::text as severity,
      'content'::text as issue_scope,
      'Todo Objetivo Estratégico ativo deve possuir ao menos um Indicador Estratégico ativo.'::text as message,
      count(*)::bigint as affected_count
    from public.skpe_strategic_objectives objective
    where objective.formulation_id = p_formulation_id
      and objective.status = 'active'
      and not exists (
        select 1
        from public.skpe_indicators indicator
        where indicator.strategic_objective_id = objective.id
          and indicator.formulation_id = p_formulation_id
          and indicator.indicator_scope = 'strategic_kpi'
          and indicator.status = 'active'
      )
    having count(*) > 0

    union all

    select
      'INDICATOR_CODE_MISSING',
      'blocking',
      'content',
      'Existem Indicadores Estratégicos sem código.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.code, ''))) = 0
    having count(*) > 0

    union all

    select
      'INDICATOR_NAME_MISSING',
      'blocking',
      'content',
      'Existem Indicadores Estratégicos sem nome.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.name, ''))) = 0
    having count(*) > 0

    union all

    select
      'INDICATOR_DEFINITION_MISSING',
      'blocking',
      'content',
      'Todo Indicador Estratégico ativo deve possuir definição clara.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.description, ''))) < 10
    having count(*) > 0

    union all

    select
      'INDICATOR_FORMULA_MISSING',
      'blocking',
      'content',
      'Todo Indicador Estratégico ativo deve possuir fórmula ou expressão de cálculo.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.formula_text, ''))) = 0
    having count(*) > 0

    union all

    select
      'INDICATOR_CALCULATION_METHOD_MISSING',
      'blocking',
      'content',
      'Todo Indicador Estratégico ativo deve registrar o método de cálculo.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.metadata ->> 'calculationMethod', ''))) = 0
    having count(*) > 0

    union all

    select
      'INDICATOR_UNIT_MISSING',
      'blocking',
      'content',
      'Todo Indicador Estratégico ativo deve possuir unidade de medida.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.unit, ''))) = 0
    having count(*) > 0

    union all

    select
      'INDICATOR_POLARITY_INVALID',
      'blocking',
      'content',
      'Existem Indicadores com polaridade ausente ou inválida.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and indicator.polarity not in (
        'higher_is_better',
        'lower_is_better',
        'target_is_better',
        'range_is_better'
      )
    having count(*) > 0

    union all

    select
      'INDICATOR_FREQUENCY_MISSING',
      'blocking',
      'content',
      'Todo Indicador Estratégico ativo deve possuir frequência de apuração.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.measurement_frequency, ''))) = 0
    having count(*) > 0

    union all

    select
      'INDICATOR_FREQUENCY_INVALID',
      'blocking',
      'content',
      'Existem Indicadores com frequência fora do catálogo metodológico da FE-05.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.measurement_frequency, ''))) > 0
      and lower(indicator.measurement_frequency) not in (
        'daily',
        'weekly',
        'monthly',
        'bimonthly',
        'quarterly',
        'semiannual',
        'annual',
        'on_demand'
      )
    having count(*) > 0

    union all

    select
      'INDICATOR_DATA_SOURCE_MISSING',
      'blocking',
      'content',
      'Todo Indicador Estratégico ativo deve possuir fonte de dados.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.data_source, ''))) = 0
    having count(*) > 0

    union all

    select
      'INDICATOR_BASELINE_MISSING',
      'blocking',
      'content',
      'Existem Indicadores que exigem linha de base, mas não possuem valor e data de referência.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and case
        when lower(coalesce(indicator.metadata ->> 'baselineRequired', '')) = 'true' then true
        when lower(coalesce(indicator.metadata ->> 'baselineRequired', '')) = 'false' then false
        else coalesce(package_row.baseline_required, true)
      end
      and (indicator.baseline_value is null or indicator.baseline_date is null)
    having count(*) > 0

    union all

    select
      'INDICATOR_WITHOUT_LONG_TERM_TARGET',
      'blocking',
      'content',
      'Todo Indicador Estratégico ativo deve possuir Meta de Longo Prazo vigente.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and not exists (
        select 1
        from public.skpe_indicator_targets target
        where target.indicator_id = indicator.id
          and target.formulation_id = p_formulation_id
          and target.target_type = 'long_term'
          and target.status <> 'superseded'
      )
    having count(*) > 0

    union all

    select
      'MULTIPLE_LONG_TERM_TARGETS',
      'blocking',
      'content',
      'Cada Indicador Estratégico deve possuir apenas uma Meta de Longo Prazo vigente.',
      count(*)
    from (
      select target.indicator_id
      from public.skpe_indicator_targets target
      join public.skpe_indicators indicator
        on indicator.id = target.indicator_id
      where target.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
        and target.target_type = 'long_term'
        and target.status <> 'superseded'
      group by target.indicator_id
      having count(*) > 1
    ) duplicated_long_term
    having count(*) > 0

    union all

    select
      'TARGET_POLARITY_MISMATCH',
      'blocking',
      'content',
      'Existem Metas de Longo Prazo incompatíveis com a polaridade e a linha de base do Indicador.',
      count(*)
    from public.skpe_indicator_targets target
    join public.skpe_indicators indicator
      on indicator.id = target.indicator_id
    where target.formulation_id = p_formulation_id
      and target.target_type = 'long_term'
      and target.status <> 'superseded'
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and indicator.baseline_value is not null
      and (
        (indicator.polarity = 'higher_is_better' and target.target_value < indicator.baseline_value)
        or
        (indicator.polarity = 'lower_is_better' and target.target_value > indicator.baseline_value)
        or
        (
          indicator.polarity = 'range_is_better'
          and (
            target.tolerance_lower is null
            or target.tolerance_upper is null
            or target.tolerance_lower > target.tolerance_upper
            or target.target_value < target.tolerance_lower
            or target.target_value > target.tolerance_upper
          )
        )
      )
    having count(*) > 0

    union all

    select
      'TARGET_OUTSIDE_FORMULATION_HORIZON',
      'blocking',
      'content',
      'Existem Metas fora do horizonte temporal da Formulação Estratégica.',
      count(*)
    from public.skpe_indicator_targets target
    join public.skpe_indicators indicator
      on indicator.id = target.indicator_id
    where target.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and target.status <> 'superseded'
      and (
        (horizon_start_date is not null and target.period_start < horizon_start_date)
        or
        (horizon_end_date is not null and target.period_end > horizon_end_date)
      )
    having count(*) > 0

    union all

    select
      'INDICATOR_SCOPE_MISMATCH',
      'blocking',
      'content',
      'Existem Indicadores vinculados a Objetivo, Formulação, organização ou projeto incompatível.',
      count(*)
    from public.skpe_indicators indicator
    left join public.skpe_strategic_objectives objective
      on objective.id = indicator.strategic_objective_id
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status <> 'archived'
      and (
        indicator.organization_id <> formulation_row.organization_id
        or indicator.project_id <> formulation_row.project_id
        or indicator.key_result_id is not null
        or objective.id is null
        or objective.formulation_id <> p_formulation_id
        or objective.organization_id <> formulation_row.organization_id
        or objective.project_id <> formulation_row.project_id
      )
    having count(*) > 0

    union all

    select
      'TARGET_SCOPE_MISMATCH',
      'blocking',
      'content',
      'Existem Metas vinculadas a Indicador ou escopo incompatível.',
      count(*)
    from public.skpe_indicator_targets target
    left join public.skpe_indicators indicator
      on indicator.id = target.indicator_id
    where target.formulation_id = p_formulation_id
      and target.status <> 'superseded'
      and (
        indicator.id is null
        or indicator.formulation_id <> p_formulation_id
        or target.organization_id <> formulation_row.organization_id
        or target.project_id <> formulation_row.project_id
      )
    having count(*) > 0

    union all

    select
      'BENCHMARK_SCOPE_MISMATCH',
      'blocking',
      'content',
      'Existem referências de benchmarking vinculadas a Indicador, Meta ou escopo incompatível.',
      count(*)
    from public.skpe_benchmark_references benchmark
    left join public.skpe_indicators indicator
      on indicator.id = benchmark.indicator_id
    left join public.skpe_indicator_targets target
      on target.id = benchmark.indicator_target_id
    where benchmark.formulation_id = p_formulation_id
      and benchmark.status <> 'archived'
      and (
        indicator.id is null
        or indicator.formulation_id <> p_formulation_id
        or benchmark.organization_id <> formulation_row.organization_id
        or benchmark.project_id <> formulation_row.project_id
        or (
          benchmark.indicator_target_id is not null
          and (
            target.id is null
            or target.indicator_id <> benchmark.indicator_id
            or target.formulation_id <> p_formulation_id
          )
        )
      )
    having count(*) > 0

    union all

    select
      'INDICATOR_DUPLICATE_NAME_IN_OBJECTIVE',
      'blocking',
      'content',
      'Existem Indicadores ativos com o mesmo nome dentro do mesmo Objetivo Estratégico.',
      count(*)
    from (
      select
        indicator.strategic_objective_id,
        lower(trim(indicator.name))
      from public.skpe_indicators indicator
      where indicator.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
      group by indicator.strategic_objective_id, lower(trim(indicator.name))
      having count(*) > 1
    ) duplicated_indicator
    having count(*) > 0

    union all

    select
      'BENCHMARK_DUPLICATE',
      'blocking',
      'content',
      'Existem referências de benchmarking duplicadas para o mesmo Indicador, fonte, período e valor.',
      count(*)
    from (
      select
        benchmark.indicator_id,
        lower(trim(benchmark.source_name)),
        lower(trim(coalesce(benchmark.reference_period, ''))),
        benchmark.benchmark_value
      from public.skpe_benchmark_references benchmark
      where benchmark.formulation_id = p_formulation_id
        and benchmark.status <> 'archived'
      group by
        benchmark.indicator_id,
        lower(trim(benchmark.source_name)),
        lower(trim(coalesce(benchmark.reference_period, ''))),
        benchmark.benchmark_value
      having count(*) > 1
    ) duplicated_benchmark
    having count(*) > 0

    union all

    select
      case
        when package_row.id is null then 'INDICATOR_PACKAGE_NOT_CREATED'
        else 'INDICATOR_PACKAGE_NOT_VALIDATED'
      end,
      'blocking',
      'formulation',
      'O pacote da FE-05 deve estar validado antes do avanço da Formulação.',
      1
    where package_row.id is null
       or package_row.status <> 'validated'

    union all

    select
      'INDICATOR_WITHOUT_OWNER',
      'recommendation',
      'content',
      'Existem Indicadores Estratégicos ativos sem responsável indicado.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and indicator.owner_user_id is null
    having count(*) > 0

    union all

    select
      'INDICATOR_WITHOUT_VERIFIED_BENCHMARK',
      'recommendation',
      'content',
      'Sempre que aplicável, associe uma referência de benchmarking verificada ou ativa ao Indicador ou à Meta.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and coalesce(package_row.benchmark_recommended, true)
      and not exists (
        select 1
        from public.skpe_benchmark_references benchmark
        where benchmark.indicator_id = indicator.id
          and benchmark.formulation_id = p_formulation_id
          and benchmark.status in ('verified', 'active')
      )
    having count(*) > 0

    union all

    select
      'INTERMEDIATE_TARGETS_MISSING',
      'recommendation',
      'content',
      'Recomenda-se desdobrar a Meta de Longo Prazo em metas anuais ou intermediárias.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and coalesce(package_row.intermediate_targets_recommended, true)
      and exists (
        select 1
        from public.skpe_indicator_targets target
        where target.indicator_id = indicator.id
          and target.target_type = 'long_term'
          and target.status <> 'superseded'
      )
      and not exists (
        select 1
        from public.skpe_indicator_targets target
        where target.indicator_id = indicator.id
          and target.target_type in ('annual', 'intermediate')
          and target.status <> 'superseded'
      )
    having count(*) > 0

    union all

    select
      'EXCESS_INDICATORS_PER_OBJECTIVE',
      'recommendation',
      'content',
      'Existem Objetivos com quantidade de Indicadores acima do limite metodológico recomendado.',
      count(*)
    from (
      select indicator.strategic_objective_id
      from public.skpe_indicators indicator
      where indicator.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status = 'active'
      group by indicator.strategic_objective_id
      having count(*) > coalesce(package_row.max_indicators_per_objective, 5)
    ) excess_by_objective
    having count(*) > 0

    union all

    select
      'FINANCIAL_INDICATOR_CONCENTRATION',
      'recommendation',
      'content',
      'A carteira de Indicadores está excessivamente concentrada em indicadores financeiros.',
      financial_indicator_count::bigint
    where active_indicator_count >= 3
      and effective_financial_percentage >=
        coalesce(package_row.financial_concentration_threshold, 60.00)

    union all

    select
      'COLLECTION_AUTOMATION_RECOMMENDED',
      'recommendation',
      'content',
      'Existem Indicadores sem método de coleta automatizável ou sem avaliação de automação.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and coalesce(package_row.automated_collection_recommended, true)
      and lower(coalesce(indicator.metadata ->> 'collectionAutomatable', 'false')) <> 'true'
    having count(*) > 0

    union all

    select
      'COLLECTION_METHOD_MISSING',
      'recommendation',
      'content',
      'Existem Indicadores sem método de coleta documentado.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.metadata ->> 'collectionMethod', ''))) = 0
    having count(*) > 0

    union all

    select
      'LOW_MEASUREMENT_FREQUENCY',
      'recommendation',
      'content',
      'Revise Indicadores com apuração exclusivamente anual; a periodicidade pode ser insuficiente para a gestão estratégica.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and lower(coalesce(indicator.measurement_frequency, '')) = 'annual'
      and horizon_start_date is not null
      and horizon_end_date is not null
      and horizon_end_date >= horizon_start_date + interval '1 year'
    having count(*) > 0

    union all

    select
      'BASELINE_OUTDATED',
      'recommendation',
      'content',
      'Existem linhas de base desatualizadas em relação ao início da Formulação.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and indicator.baseline_date is not null
      and indicator.baseline_date <
        coalesce(horizon_start_date, current_date)
        - make_interval(months => coalesce(package_row.baseline_freshness_months, 24))
    having count(*) > 0

    union all

    select
      'INDICATOR_CATEGORY_MISSING',
      'recommendation',
      'content',
      'Classifique os Indicadores por natureza para avaliar o equilíbrio da carteira estratégica.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = p_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status = 'active'
      and length(trim(coalesce(indicator.metadata ->> 'indicatorCategory', ''))) = 0
    having count(*) > 0
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'code', issue.code,
          'severity', issue.severity,
          'scope', issue.issue_scope,
          'message', issue.message,
          'affectedCount', issue.affected_count
        )
        order by
          case issue.severity
            when 'blocking' then 1
            when 'recommendation' then 2
            else 3
          end,
          case issue.issue_scope
            when 'content' then 1
            when 'formulation' then 2
            else 3
          end,
          issue.code
      ),
      '[]'::jsonb
    ),
    count(*) filter (
      where issue.severity = 'blocking'
        and issue.issue_scope = 'content'
    )::integer,
    count(*) filter (
      where issue.severity = 'blocking'
    )::integer
  into issues, content_blocking_count, total_blocking_count
  from issue_rows issue;

  return jsonb_build_object(
    'formulationId', formulation_row.id,
    'indicatorPackageId', package_row.id,
    'packageStatus', coalesce(package_row.status, 'not_created'),
    'readyForValidation', content_blocking_count = 0,
    'validated', coalesce(package_row.status = 'validated', false),
    'readyForFormulation',
      content_blocking_count = 0
      and coalesce(package_row.status = 'validated', false),
    'contentBlockingIssueCount', content_blocking_count,
    'blockingIssueCount', total_blocking_count,
    'planningHorizon', jsonb_build_object(
      'startDate', horizon_start_date,
      'endDate', horizon_end_date
    ),
    'counts', counts,
    'issues', issues,
    'methodologyRules', jsonb_build_object(
      'baselineRequired', coalesce(package_row.baseline_required, true),
      'intermediateTargetsRecommended', coalesce(package_row.intermediate_targets_recommended, true),
      'benchmarkRecommended', coalesce(package_row.benchmark_recommended, true),
      'automatedCollectionRecommended', coalesce(package_row.automated_collection_recommended, true),
      'maxIndicatorsPerObjective', coalesce(package_row.max_indicators_per_objective, 5),
      'financialConcentrationThreshold', coalesce(package_row.financial_concentration_threshold, 60.00),
      'baselineFreshnessMonths', coalesce(package_row.baseline_freshness_months, 24),
      'keyResultIndicatorsRequiredInFe05', false,
      'okrRequiredInFe05', false,
      'initiativeRequiredInFe05', false
    )
  );
end;
$$;

-- ============================================================
-- 8. VALIDAÇÃO DO PACOTE DA FE-05
-- ============================================================

create or replace function public.transition_skpe_indicator_package(
  p_formulation_id uuid,
  p_transition_action text,
  p_decision_notes text default null,
  p_change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_action text;
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_id uuid;
  previous_package public.skpe_indicator_packages%rowtype;
  updated_package public.skpe_indicator_packages%rowtype;
  readiness jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);

  normalized_action := lower(trim(coalesce(p_transition_action, '')));

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if formulation_row.status not in ('draft', 'in_elaboration') then
    raise exception 'A Formulação deve permanecer em rascunho ou elaboração durante a validação da FE-05.'
      using errcode = '55000';
  end if;

  select *
  into previous_package
  from public.skpe_indicator_packages
  where formulation_id = p_formulation_id
  for update;

  if not found then
    if normalized_action = 'submit_validation' then
      if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
        raise exception 'Acesso negado para criar e submeter o pacote FE-05.'
          using errcode = '42501';
      end if;

      package_id := public.ensure_skpe_indicator_package(p_formulation_id);

      select *
      into previous_package
      from public.skpe_indicator_packages
      where id = package_id
      for update;
    else
      raise exception 'O pacote FE-05 ainda não foi criado.'
        using errcode = '22023';
    end if;
  end if;

  if normalized_action = 'submit_validation' then
    if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para submeter a FE-05 à validação.'
        using errcode = '42501';
    end if;

    if previous_package.status <> 'in_elaboration' then
      raise exception 'A FE-05 deve estar em elaboração para ser submetida.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_indicators_readiness(p_formulation_id);

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'A FE-05 possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_indicator_packages
    set
      status = 'pending_validation',
      validation_notes = null,
      submitted_for_validation_at = timezone('utc', now()),
      submitted_for_validation_by = auth.uid(),
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where id = previous_package.id
    returning *
    into updated_package;

    update public.skpe_indicators
    set
      metadata = (coalesce(metadata, '{}'::jsonb)
        - 'validatedAt'
        - 'validatedBy')
        || jsonb_build_object('validationStatus', 'pending_validation'),
      updated_by = auth.uid()
    where formulation_id = p_formulation_id
      and indicator_scope = 'strategic_kpi'
      and status <> 'archived';

  elsif normalized_action = 'validate' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para validar a FE-05.'
        using errcode = '42501';
    end if;

    if previous_package.status <> 'pending_validation' then
      raise exception 'Somente um pacote FE-05 pendente de validação pode ser validado.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_indicators_readiness(p_formulation_id);

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'A FE-05 possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_indicator_packages
    set
      status = 'validated',
      validation_notes = p_decision_notes,
      validated_at = timezone('utc', now()),
      validated_by = auth.uid(),
      updated_by = auth.uid()
    where id = previous_package.id
    returning *
    into updated_package;

    update public.skpe_indicators
    set
      metadata = coalesce(metadata, '{}'::jsonb)
        || jsonb_build_object(
          'validationStatus', 'validated',
          'validatedAt', timezone('utc', now()),
          'validatedBy', auth.uid()
        ),
      updated_by = auth.uid()
    where formulation_id = p_formulation_id
      and indicator_scope = 'strategic_kpi'
      and status <> 'archived';

  elsif normalized_action = 'return_for_adjustments' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para devolver a FE-05 para ajustes.'
        using errcode = '42501';
    end if;

    if previous_package.status not in ('pending_validation', 'validated') then
      raise exception 'A FE-05 não está em situação que permita devolução.'
        using errcode = '55000';
    end if;

    if length(trim(coalesce(p_decision_notes, ''))) < 10 then
      raise exception 'Informe as orientações para ajuste, com no mínimo 10 caracteres.'
        using errcode = '22023';
    end if;

    update public.skpe_indicator_packages
    set
      status = 'in_elaboration',
      validation_notes = p_decision_notes,
      submitted_for_validation_at = null,
      submitted_for_validation_by = null,
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where id = previous_package.id
    returning *
    into updated_package;

    update public.skpe_indicators
    set
      metadata = (coalesce(metadata, '{}'::jsonb)
        - 'validatedAt'
        - 'validatedBy')
        || jsonb_build_object('validationStatus', 'draft'),
      updated_by = auth.uid()
    where formulation_id = p_formulation_id
      and indicator_scope = 'strategic_kpi'
      and status <> 'archived';
  else
    raise exception 'Transição inválida. Use submit_validation, validate ou return_for_adjustments.'
      using errcode = '22023';
  end if;

  perform public.skpe_record_operational_audit(
    updated_package.organization_id,
    updated_package.project_id,
    'indicator_package',
    updated_package.id,
    'indicator_package_' || normalized_action,
    p_change_reason,
    to_jsonb(previous_package),
    to_jsonb(updated_package)
  );

  return jsonb_build_object(
    'formulationId', p_formulation_id,
    'indicatorPackageId', updated_package.id,
    'previousStatus', previous_package.status,
    'currentStatus', updated_package.status,
    'transitionAction', normalized_action
  );
end;
$$;

-- ============================================================
-- 9. BLOQUEIO INTEGRADO DA FORMULAÇÃO
-- ============================================================

create or replace function public.skpe_guard_formulation_indicators_ready()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  readiness jsonb;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  if new.status not in (
    'pending_validation',
    'validated',
    'pending_approval',
    'approved'
  ) then
    return new;
  end if;

  readiness := public.get_skpe_indicators_readiness(new.id);

  if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
    raise exception 'A Formulação não pode avançar: a FE-05 possui pendências bloqueantes.'
      using errcode = '55000', detail = readiness::text;
  end if;

  if not coalesce((readiness ->> 'readyForFormulation')::boolean, false) then
    raise exception 'A Formulação não pode avançar: valide o pacote de Indicadores, Metas e Benchmarking.'
      using errcode = '55000', detail = readiness::text;
  end if;

  return new;
end;
$$;

comment on function public.skpe_guard_formulation_indicators_ready() is
  'Impede o avanço da Formulação enquanto a FE-05 estiver incompleta ou não validada.';

drop trigger if exists skpe_strategic_formulations_guard_indicators_ready
  on public.skpe_strategic_formulations;

create trigger skpe_strategic_formulations_guard_indicators_ready
before update of status on public.skpe_strategic_formulations
for each row
execute function public.skpe_guard_formulation_indicators_ready();

-- ============================================================
-- 10. CONSULTA CONSOLIDADA DA FE-05
-- ============================================================

create or replace function public.get_skpe_indicators_package(
  p_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_indicator_packages%rowtype;
  readiness jsonb;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado à consulta consolidada da FE-05.'
      using errcode = '42501';
  end if;

  select *
  into package_row
  from public.skpe_indicator_packages
  where formulation_id = p_formulation_id;

  readiness := public.get_skpe_indicators_readiness(p_formulation_id);

  return jsonb_build_object(
    'formulation', jsonb_build_object(
      'id', formulation_row.id,
      'organizationId', formulation_row.organization_id,
      'projectId', formulation_row.project_id,
      'versionNumber', formulation_row.version_number,
      'versionLabel', formulation_row.version_label,
      'status', formulation_row.status,
      'validFrom', formulation_row.valid_from,
      'validUntil', formulation_row.valid_until
    ),
    'package', case
      when package_row.id is null then null
      else to_jsonb(package_row)
    end,
    'objectives', coalesce((
      select jsonb_agg(to_jsonb(objective) order by objective.code)
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = p_formulation_id
        and objective.status = 'active'
    ), '[]'::jsonb),
    'indicators', coalesce((
      select jsonb_agg(to_jsonb(indicator) order by indicator.code)
      from public.skpe_indicators indicator
      where indicator.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status <> 'archived'
    ), '[]'::jsonb),
    'targets', coalesce((
      select jsonb_agg(
        to_jsonb(target)
        order by target.indicator_id, target.period_end, target.target_type
      )
      from public.skpe_indicator_targets target
      join public.skpe_indicators indicator
        on indicator.id = target.indicator_id
      where target.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and target.status <> 'superseded'
    ), '[]'::jsonb),
    'benchmarks', coalesce((
      select jsonb_agg(
        to_jsonb(benchmark)
        order by benchmark.indicator_id, benchmark.source_name
      )
      from public.skpe_benchmark_references benchmark
      join public.skpe_indicators indicator
        on indicator.id = benchmark.indicator_id
      where benchmark.formulation_id = p_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and benchmark.status <> 'archived'
    ), '[]'::jsonb),
    'readiness', readiness
  );
end;
$$;

create or replace function public.get_skpe_indicators_audit(
  p_formulation_id uuid
)
returns table (
  audit_id uuid,
  entity_type text,
  entity_id uuid,
  action_code text,
  reason text,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz,
  actor_user_id uuid
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado ao histórico da FE-05.'
      using errcode = '42501';
  end if;

  return query
  select
    audit.id,
    audit.entity_type,
    audit.entity_id,
    audit.action_code,
    audit.reason,
    audit.previous_data,
    audit.new_data,
    audit.occurred_at,
    audit.actor_user_id
  from public.skpe_operational_audit audit
  where audit.organization_id = formulation_row.organization_id
    and audit.project_id = formulation_row.project_id
    and audit.entity_type in (
      'indicator_package',
      'strategic_indicator',
      'indicator_target',
      'benchmark_reference'
    )
    and (
      audit.previous_data ->> 'formulation_id' = p_formulation_id::text
      or audit.new_data ->> 'formulation_id' = p_formulation_id::text
    )
  order by audit.occurred_at desc, audit.id desc;
end;
$$;

-- ============================================================
-- 11. RLS, PRIVILÉGIOS DE TABELAS E AUDITORIA
-- ============================================================

-- Preserva a política transversal de auditoria já ampliada pela FE-04.
drop policy if exists skpe_operational_audit_select
  on public.skpe_operational_audit;

create policy skpe_operational_audit_select
on public.skpe_operational_audit
for select to authenticated
using (
  public.can_view_skpe_initiatives(organization_id)
  or public.can_view_skpe_business_artifacts(organization_id)
  or public.can_view_skpe_evidence_checklist(organization_id)
  or public.can_view_skpe_formulation(organization_id)
);

revoke insert, update, delete
on table public.skpe_indicator_packages,
             public.skpe_indicators,
             public.skpe_indicator_targets,
             public.skpe_benchmark_references
from public;

revoke all
on table public.skpe_indicator_packages
from anon;

revoke insert, update, delete
on table public.skpe_indicator_packages,
             public.skpe_indicators,
             public.skpe_indicator_targets,
             public.skpe_benchmark_references
from anon, authenticated;

grant select
on table public.skpe_indicator_packages,
             public.skpe_indicators,
             public.skpe_indicator_targets,
             public.skpe_benchmark_references
  to authenticated, service_role;

grant insert, update, delete
on table public.skpe_indicator_packages,
             public.skpe_indicators,
             public.skpe_indicator_targets,
             public.skpe_benchmark_references
  to service_role;

-- ============================================================
-- 12. PRIVILÉGIOS DAS FUNÇÕES
-- ============================================================

revoke all on function public.ensure_skpe_indicator_package(uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_invalidate_indicator_package(uuid, text)
  from public, anon, authenticated;
revoke all on function public.skpe_guard_formulation_indicators_ready()
  from public, anon, authenticated;

revoke all on function public.configure_skpe_indicator_package(
  uuid, boolean, boolean, boolean, boolean, integer, numeric, integer, jsonb, text
) from public, anon;
revoke all on function public.upsert_skpe_strategic_indicator(
  uuid, text, text, text, uuid, text, text, text, text, text, text,
  numeric, date, uuid, text, text, boolean, text, boolean, text, uuid, jsonb, text
) from public, anon;
revoke all on function public.archive_skpe_strategic_indicator(uuid, text)
  from public, anon;
revoke all on function public.upsert_skpe_indicator_target(
  uuid, text, date, date, numeric, numeric, numeric, numeric, numeric,
  uuid, text, uuid, jsonb, text
) from public, anon;
revoke all on function public.supersede_skpe_indicator_target(uuid, text)
  from public, anon;
revoke all on function public.upsert_skpe_benchmark_reference(
  uuid, text, text, text, text, text, numeric, text, text, text,
  uuid, uuid, jsonb, text
) from public, anon;
revoke all on function public.transition_skpe_benchmark_reference(
  uuid, text, text, text
) from public, anon;
revoke all on function public.get_skpe_indicators_readiness(uuid)
  from public, anon;
revoke all on function public.transition_skpe_indicator_package(
  uuid, text, text, text
) from public, anon;
revoke all on function public.get_skpe_indicators_package(uuid)
  from public, anon;
revoke all on function public.get_skpe_indicators_audit(uuid)
  from public, anon;

grant execute on function public.configure_skpe_indicator_package(
  uuid, boolean, boolean, boolean, boolean, integer, numeric, integer, jsonb, text
) to authenticated, service_role;
grant execute on function public.upsert_skpe_strategic_indicator(
  uuid, text, text, text, uuid, text, text, text, text, text, text,
  numeric, date, uuid, text, text, boolean, text, boolean, text, uuid, jsonb, text
) to authenticated, service_role;
grant execute on function public.archive_skpe_strategic_indicator(uuid, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_indicator_target(
  uuid, text, date, date, numeric, numeric, numeric, numeric, numeric,
  uuid, text, uuid, jsonb, text
) to authenticated, service_role;
grant execute on function public.supersede_skpe_indicator_target(uuid, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_benchmark_reference(
  uuid, text, text, text, text, text, numeric, text, text, text,
  uuid, uuid, jsonb, text
) to authenticated, service_role;
grant execute on function public.transition_skpe_benchmark_reference(
  uuid, text, text, text
) to authenticated, service_role;
grant execute on function public.get_skpe_indicators_readiness(uuid)
  to authenticated, service_role;
grant execute on function public.transition_skpe_indicator_package(
  uuid, text, text, text
) to authenticated, service_role;
grant execute on function public.get_skpe_indicators_package(uuid)
  to authenticated, service_role;
grant execute on function public.get_skpe_indicators_audit(uuid)
  to authenticated, service_role;

grant execute on function public.ensure_skpe_indicator_package(uuid)
  to service_role;
grant execute on function public.skpe_invalidate_indicator_package(uuid, text)
  to service_role;
grant execute on function public.skpe_guard_formulation_indicators_ready()
  to service_role;

commit;
