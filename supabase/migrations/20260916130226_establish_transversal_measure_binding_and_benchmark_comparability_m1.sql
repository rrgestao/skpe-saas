-- SPARKs PaaS
-- M1 Proposal - Fundacao Transversal de Medidas e Desempenho
--
-- ESCOPO AUTORIZADO EM 2026-09-16:
--   1. Metric Binding transversal;
--   2. Benchmark Comparability Assessment transversal;
--   3. RLS, contratos e adapters SK-PE conservadores;
--   4. sem rename das tabelas skpe_* existentes;
--   5. sem importacao de KPI/BMK neste gate.
--
-- Migration M1 preparada sob gate aprovado em 2026-09-16; aplicacao controlada somente em ambiente dev.
-- ============================================================

create table public.sparks_measure_bindings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  organization_indicator_id uuid not null references public.sparks_measure_organization_indicators(id) on delete restrict,
  source_module_code text not null,
  context_type text not null,
  source_context_id uuid not null,
  subject_type text not null,
  subject_id uuid not null,
  binding_type text not null default 'measures',
  status text not null default 'active',
  effective_from date,
  effective_until date,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null
);
alter table public.sparks_measure_bindings
  add constraint sparks_measure_bindings_module_not_blank
    check (length(trim(source_module_code)) > 0),
  add constraint sparks_measure_bindings_context_not_blank
    check (length(trim(context_type)) > 0),
  add constraint sparks_measure_bindings_subject_not_blank
    check (length(trim(subject_type)) > 0),
  add constraint sparks_measure_bindings_type_check
    check (binding_type in ('measures','supports','diagnoses','guards')),
  add constraint sparks_measure_bindings_status_check
    check (status in ('active','archived')),
  add constraint sparks_measure_bindings_period_check
    check (effective_until is null or effective_from is null or effective_until >= effective_from);

create unique index ux_sparks_measure_bindings_active
  on public.sparks_measure_bindings(
    organization_id,
    organization_indicator_id,
    source_module_code,
    context_type,
    source_context_id,
    subject_type,
    subject_id,
    binding_type
  ) where status = 'active';

create index idx_sparks_measure_bindings_subject
  on public.sparks_measure_bindings(organization_id, subject_type, subject_id)
  where status = 'active';
comment on table public.sparks_measure_bindings is
  'Vinculo transversal entre um Indicador adotado pela Organizacao e um sujeito/contexto de negocio. '
  'A adocao organizacional nao implica binding; o binding nao altera a definicao global do KPI.';

create table public.sparks_benchmark_comparability_assessments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  organization_indicator_id uuid not null references public.sparks_measure_organization_indicators(id) on delete restrict,
  measure_binding_id uuid references public.sparks_measure_bindings(id) on delete restrict,
  source_module_code text not null,
  benchmark_origin_type text not null,
  benchmark_reference_id uuid not null,
  comparability_class text not null default 'not_assessed',
  formula_alignment text not null default 'not_assessed',
  unit_alignment text not null default 'not_assessed',
  period_alignment text not null default 'not_assessed',
  population_alignment text not null default 'not_assessed',
  context_alignment text not null default 'not_assessed',
  rationale text,
  caveats text,
  assessment_status text not null default 'draft',
  supersedes_assessment_id uuid references public.sparks_benchmark_comparability_assessments(id) on delete restrict,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null
);
alter table public.sparks_benchmark_comparability_assessments
  add constraint sparks_benchmark_comp_origin_check
    check (benchmark_origin_type in ('reference_catalog','contextual')),
  add constraint sparks_benchmark_comp_class_check
    check (comparability_class in (
      'directly_comparable','comparable_with_caveats','adjacent_reference',
      'context_only','not_comparable','not_assessed'
    )),
  add constraint sparks_benchmark_comp_alignment_check
    check (
      formula_alignment in ('aligned','partial','not_aligned','not_assessed')
      and unit_alignment in ('aligned','partial','not_aligned','not_assessed')
      and period_alignment in ('aligned','partial','not_aligned','not_assessed')
      and population_alignment in ('aligned','partial','not_aligned','not_assessed')
      and context_alignment in ('aligned','partial','not_aligned','not_assessed')
    ),
  add constraint sparks_benchmark_comp_status_check
    check (assessment_status in ('draft','validated','superseded','archived')),
  add constraint sparks_benchmark_comp_validated_fields_check
    check (
      assessment_status <> 'validated'
      or (comparability_class <> 'not_assessed' and validated_at is not null and validated_by is not null)
    );

create unique index ux_sparks_benchmark_comp_current
  on public.sparks_benchmark_comparability_assessments(
    organization_id, organization_indicator_id,
    coalesce(measure_binding_id, '00000000-0000-0000-0000-000000000000'::uuid),
    benchmark_origin_type, benchmark_reference_id
  ) where assessment_status in ('draft','validated');
-- Indices dedicados para FKs da M1. Evitam novos avisos unindexed_foreign_keys
-- e preservam custo previsivel de joins/validacoes sem depender de indices parciais.
create index idx_sparks_measure_bindings_organization
  on public.sparks_measure_bindings(organization_id);
create index idx_sparks_measure_bindings_organization_indicator
  on public.sparks_measure_bindings(organization_indicator_id);
create index idx_sparks_measure_bindings_created_by
  on public.sparks_measure_bindings(created_by) where created_by is not null;
create index idx_sparks_measure_bindings_updated_by
  on public.sparks_measure_bindings(updated_by) where updated_by is not null;

create index idx_sparks_benchmark_comp_organization
  on public.sparks_benchmark_comparability_assessments(organization_id);
create index idx_sparks_benchmark_comp_organization_indicator
  on public.sparks_benchmark_comparability_assessments(organization_indicator_id);
create index idx_sparks_benchmark_comp_binding
  on public.sparks_benchmark_comparability_assessments(measure_binding_id)
  where measure_binding_id is not null;
create index idx_sparks_benchmark_comp_supersedes
  on public.sparks_benchmark_comparability_assessments(supersedes_assessment_id)
  where supersedes_assessment_id is not null;
create index idx_sparks_benchmark_comp_validated_by
  on public.sparks_benchmark_comparability_assessments(validated_by)
  where validated_by is not null;
create index idx_sparks_benchmark_comp_created_by
  on public.sparks_benchmark_comparability_assessments(created_by)
  where created_by is not null;
create index idx_sparks_benchmark_comp_updated_by
  on public.sparks_benchmark_comparability_assessments(updated_by)
  where updated_by is not null;
comment on table public.sparks_benchmark_comparability_assessments is
  'Avaliacao governada de comparabilidade de benchmark. Benchmark existente nao implica comparabilidade e comparabilidade nao transforma benchmark em meta.';

create or replace function public.can_manage_sparks_measures(
  target_organization_id uuid
)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select public.is_platform_super_admin()
    or public.can_manage_organization(target_organization_id);
$$;

create or replace function public.can_view_sparks_measures(
  target_organization_id uuid,
  target_source_module_code text
)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select public.is_platform_super_admin()
    or public.can_manage_organization(target_organization_id)
    or (
      public.is_active_member(target_organization_id)
      and public.has_module_access(target_organization_id, upper(trim(target_source_module_code)))
    );
$$;
alter table public.sparks_measure_bindings enable row level security;
alter table public.sparks_benchmark_comparability_assessments enable row level security;

create policy sparks_measure_bindings_select_authorized
on public.sparks_measure_bindings
for select
to authenticated
using (public.can_view_sparks_measures(organization_id, source_module_code));

create policy sparks_benchmark_comp_select_authorized
on public.sparks_benchmark_comparability_assessments
for select
to authenticated
using (public.can_view_sparks_measures(organization_id, source_module_code));

revoke all on table public.sparks_measure_bindings from anon, authenticated;
revoke all on table public.sparks_benchmark_comparability_assessments from anon, authenticated;
grant select on table public.sparks_measure_bindings to authenticated;
grant select on table public.sparks_benchmark_comparability_assessments to authenticated;
grant all on table public.sparks_measure_bindings to service_role;
grant all on table public.sparks_benchmark_comparability_assessments to service_role;

revoke all on function public.can_manage_sparks_measures(uuid) from public, anon;
revoke all on function public.can_view_sparks_measures(uuid, text) from public, anon;
grant execute on function public.can_manage_sparks_measures(uuid) to authenticated, service_role;
grant execute on function public.can_view_sparks_measures(uuid, text) to authenticated, service_role;

-- Escrita direta por authenticated permanece bloqueada.
-- Operacoes abaixo sao APIs governadas e validam explicitamente auth/escopo.
create or replace function public.create_sparks_measure_binding(
  p_organization_id uuid,
  p_organization_indicator_id uuid,
  p_source_module_code text,
  p_context_type text,
  p_source_context_id uuid,
  p_subject_type text,
  p_subject_id uuid,
  p_binding_type text default 'measures',
  p_effective_from date default null,
  p_effective_until date default null,
  p_notes text default null,
  p_metadata jsonb default '{}'::jsonb,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_module text := upper(trim(coalesce(p_source_module_code, '')));
  normalized_context text := lower(trim(coalesce(p_context_type, '')));
  normalized_subject text := lower(trim(coalesce(p_subject_type, '')));
  existing_id uuid;
  saved_id uuid;
begin
  if current_user_id is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;
  if not public.can_manage_sparks_measures(p_organization_id) then
    raise exception 'Acesso negado para gerir bindings de Medidas.' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo do binding.' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.sparks_measure_organization_indicators oi
    where oi.id = p_organization_indicator_id
      and oi.organization_id = p_organization_id
      and oi.status = 'active'
  ) then
    raise exception 'Indicador adotado ativo nao encontrado para a Organizacao.' using errcode = '22023';
  end if;

  if normalized_module <> 'SK-PE' then
    raise exception 'M1 possui adapter de binding somente para SK-PE.' using errcode = '0A000';
  end if;
  if normalized_context <> 'strategic_formulation' then
    raise exception 'Adapter SK-PE exige context_type strategic_formulation.' using errcode = '0A000';
  end if;
  if not exists (
    select 1 from public.skpe_strategic_formulations f
    where f.id = p_source_context_id and f.organization_id = p_organization_id
  ) then
    raise exception 'Formulacao Estrategica fora do escopo da Organizacao.' using errcode = '22023';
  end if;

  if normalized_subject = 'strategic_objective' then
    if not exists (
      select 1 from public.skpe_strategic_objectives o
      where o.id = p_subject_id and o.formulation_id = p_source_context_id and o.status <> 'archived'
    ) then
      raise exception 'Objetivo Estrategico fora do contexto do binding.' using errcode = '22023';
    end if;
  elsif normalized_subject = 'key_result' then
    if not exists (
      select 1 from public.skpe_key_results kr
      where kr.id = p_subject_id and kr.formulation_id = p_source_context_id and kr.status <> 'archived'
    ) then
      raise exception 'Resultado-Chave fora do contexto do binding.' using errcode = '22023';
    end if;
  elsif normalized_subject = 'initiative' then
    if not exists (
      select 1 from public.sparks_initiatives i
      where i.id = p_subject_id and i.organization_id = p_organization_id and i.archived_at is null
    ) then
      raise exception 'Iniciativa transversal fora do escopo da Organizacao.' using errcode = '22023';
    end if;
  else
    raise exception 'Subject type ainda sem adapter governado em M1: %', normalized_subject using errcode = '0A000';
  end if;
  select b.id into existing_id
  from public.sparks_measure_bindings b
  where b.organization_id = p_organization_id
    and b.organization_indicator_id = p_organization_indicator_id
    and b.source_module_code = normalized_module
    and b.context_type = normalized_context
    and b.source_context_id = p_source_context_id
    and b.subject_type = normalized_subject
    and b.subject_id = p_subject_id
    and b.binding_type = lower(trim(coalesce(p_binding_type, 'measures')))
    and b.status = 'active'
  limit 1;

  if existing_id is not null then
    return existing_id;
  end if;

  insert into public.sparks_measure_bindings (
    organization_id, organization_indicator_id, source_module_code,
    context_type, source_context_id, subject_type, subject_id,
    binding_type, status, effective_from, effective_until, notes,
    metadata, created_by, updated_by
  ) values (
    p_organization_id, p_organization_indicator_id, normalized_module,
    normalized_context, p_source_context_id, normalized_subject, p_subject_id,
    lower(trim(coalesce(p_binding_type, 'measures'))), 'active',
    p_effective_from, p_effective_until, nullif(trim(coalesce(p_notes, '')), ''),
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'changeReason', trim(p_change_reason),
      'createdVia', 'create_sparks_measure_binding'
    ),
    current_user_id, current_user_id
  ) returning id into saved_id;

  return saved_id;
end;
$$;

revoke all on function public.create_sparks_measure_binding(uuid,uuid,text,text,uuid,text,uuid,text,date,date,text,jsonb,text) from public, anon;
grant execute on function public.create_sparks_measure_binding(uuid,uuid,text,text,uuid,text,uuid,text,date,date,text,jsonb,text) to authenticated, service_role;
create or replace function public.archive_sparks_measure_binding(
  p_binding_id uuid,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  binding_row public.sparks_measure_bindings%rowtype;
begin
  if current_user_id is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;
  select * into binding_row
  from public.sparks_measure_bindings
  where id = p_binding_id and status = 'active'
  for update;
  if not found then
    raise exception 'Binding ativo nao encontrado.' using errcode = '22023';
  end if;
  if not public.can_manage_sparks_measures(binding_row.organization_id) then
    raise exception 'Acesso negado para arquivar binding.' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo do arquivamento.' using errcode = '22023';
  end if;

  update public.sparks_measure_bindings
  set status = 'archived',
      metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
        'archiveReason', trim(p_change_reason), 'archivedAt', timezone('utc', now())
      ),
      updated_at = timezone('utc', now()), updated_by = current_user_id
  where id = p_binding_id;
  return p_binding_id;
end;
$$;
revoke all on function public.archive_sparks_measure_binding(uuid,text) from public, anon;
grant execute on function public.archive_sparks_measure_binding(uuid,text) to authenticated, service_role;

create or replace function public.record_sparks_benchmark_comparability_assessment(
  p_organization_id uuid,
  p_organization_indicator_id uuid,
  p_measure_binding_id uuid,
  p_source_module_code text,
  p_benchmark_origin_type text,
  p_benchmark_reference_id uuid,
  p_comparability_class text,
  p_formula_alignment text,
  p_unit_alignment text,
  p_period_alignment text,
  p_population_alignment text,
  p_context_alignment text,
  p_rationale text,
  p_caveats text,
  p_assessment_status text default 'draft',
  p_metadata jsonb default '{}'::jsonb,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_module text := upper(trim(coalesce(p_source_module_code, '')));
  normalized_origin text := lower(trim(coalesce(p_benchmark_origin_type, '')));
  normalized_status text := lower(trim(coalesce(p_assessment_status, 'draft')));
  adoption_row public.sparks_measure_organization_indicators%rowtype;
  previous_id uuid;
  saved_id uuid;
begin
  if current_user_id is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;
  if not public.can_manage_sparks_measures(p_organization_id) then
    raise exception 'Acesso negado para avaliar comparabilidade.' using errcode = '42501';
  end if;
  if normalized_module <> 'SK-PE' then
    raise exception 'M1 possui adapter de comparabilidade somente para SK-PE.' using errcode = '0A000';
  end if;
  if length(trim(coalesce(p_change_reason, ''))) = 0 then
    raise exception 'Informe o motivo da avaliacao de comparabilidade.' using errcode = '22023';
  end if;

  select * into adoption_row
  from public.sparks_measure_organization_indicators
  where id = p_organization_indicator_id
    and organization_id = p_organization_id
    and status = 'active';
  if not found then
    raise exception 'Indicador adotado ativo nao encontrado para a Organizacao.' using errcode = '22023';
  end if;

  if p_measure_binding_id is not null and not exists (
    select 1 from public.sparks_measure_bindings b
    where b.id = p_measure_binding_id
      and b.organization_id = p_organization_id
      and b.organization_indicator_id = p_organization_indicator_id
      and b.status = 'active'
  ) then
    raise exception 'Binding informado nao pertence ao Indicador/Organizacao.' using errcode = '22023';
  end if;

  if normalized_origin = 'reference_catalog' then
    if adoption_row.reference_catalog_id is null or not exists (
      select 1 from public.sparks_measure_reference_benchmarks rb
      where rb.id = p_benchmark_reference_id
        and rb.reference_indicator_id = adoption_row.reference_catalog_id
        and (rb.status is null or rb.status <> 'archived')
    ) then
      raise exception 'Benchmark de referencia nao pertence ao KPI adotado.' using errcode = '22023';
    end if;
  elsif normalized_origin = 'contextual' then
    if not exists (
      select 1
      from public.sparks_measure_benchmarks cb
      join public.skpe_indicators si on si.id = cb.indicator_id
      where cb.id = p_benchmark_reference_id
        and cb.organization_id = p_organization_id
        and (
          adoption_row.legacy_indicator_id = si.id
          or (adoption_row.reference_catalog_id is not null and si.reference_catalog_id = adoption_row.reference_catalog_id)
        )
        and (cb.status is null or cb.status <> 'archived')
    ) then
      raise exception 'Benchmark contextual nao pertence ao KPI adotado.' using errcode = '22023';
    end if;
  else
    raise exception 'Origem de benchmark nao suportada: %', normalized_origin using errcode = '22023';
  end if;
  if normalized_status = 'validated' then
    if lower(trim(coalesce(p_comparability_class, 'not_assessed'))) = 'not_assessed' then
      raise exception 'Avaliacao validada exige classe de comparabilidade.' using errcode = '22023';
    end if;
    if length(trim(coalesce(p_rationale, ''))) = 0 then
      raise exception 'Avaliacao validada exige justificativa.' using errcode = '22023';
    end if;
  end if;

  select a.id into previous_id
  from public.sparks_benchmark_comparability_assessments a
  where a.organization_id = p_organization_id
    and a.organization_indicator_id = p_organization_indicator_id
    and coalesce(a.measure_binding_id, '00000000-0000-0000-0000-000000000000'::uuid)
        = coalesce(p_measure_binding_id, '00000000-0000-0000-0000-000000000000'::uuid)
    and a.benchmark_origin_type = normalized_origin
    and a.benchmark_reference_id = p_benchmark_reference_id
    and a.assessment_status in ('draft','validated')
  order by a.created_at desc
  limit 1
  for update;

  if previous_id is not null then
    update public.sparks_benchmark_comparability_assessments
    set assessment_status = 'superseded',
        updated_at = timezone('utc', now()),
        updated_by = current_user_id
    where id = previous_id;
  end if;
  insert into public.sparks_benchmark_comparability_assessments (
    organization_id, organization_indicator_id, measure_binding_id,
    source_module_code, benchmark_origin_type, benchmark_reference_id,
    comparability_class, formula_alignment, unit_alignment,
    period_alignment, population_alignment, context_alignment,
    rationale, caveats, assessment_status, supersedes_assessment_id,
    validated_at, validated_by, metadata, created_by, updated_by
  ) values (
    p_organization_id, p_organization_indicator_id, p_measure_binding_id,
    normalized_module, normalized_origin, p_benchmark_reference_id,
    lower(trim(coalesce(p_comparability_class, 'not_assessed'))),
    lower(trim(coalesce(p_formula_alignment, 'not_assessed'))),
    lower(trim(coalesce(p_unit_alignment, 'not_assessed'))),
    lower(trim(coalesce(p_period_alignment, 'not_assessed'))),
    lower(trim(coalesce(p_population_alignment, 'not_assessed'))),
    lower(trim(coalesce(p_context_alignment, 'not_assessed'))),
    nullif(trim(coalesce(p_rationale, '')), ''),
    nullif(trim(coalesce(p_caveats, '')), ''),
    normalized_status, previous_id,
    case when normalized_status = 'validated' then timezone('utc', now()) else null end,
    case when normalized_status = 'validated' then current_user_id else null end,
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'changeReason', trim(p_change_reason),
      'createdVia', 'record_sparks_benchmark_comparability_assessment'
    ),
    current_user_id, current_user_id
  ) returning id into saved_id;
  return saved_id;
end;
$$;

revoke all on function public.record_sparks_benchmark_comparability_assessment(
  uuid,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,text,text,jsonb,text
) from public, anon;

grant execute on function public.record_sparks_benchmark_comparability_assessment(
  uuid,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,text,text,jsonb,text
) to authenticated, service_role;

comment on function public.create_sparks_measure_binding(
  uuid,uuid,text,text,uuid,text,uuid,text,date,date,text,jsonb,text
) is 'M1: cria binding governado de KPI adotado para sujeito contextual. Adapter inicial cobre SK-PE e Iniciativas transversais; demais sujeitos falham fechados.';

comment on function public.record_sparks_benchmark_comparability_assessment(
  uuid,uuid,uuid,text,text,uuid,text,text,text,text,text,text,text,text,text,jsonb,text
) is 'M1: registra assessment versionado de comparabilidade sem transformar benchmark em meta.';

-- FIM DA PROPOSTA M1.
-- Nao cria PerformanceRule/PerformanceAssessment fisicos neste gate.
-- Nao altera automatic_performance/manual_performance_override/effective_performance.
-- Nao altera snapshots, ciclos, RAE ou check-ins existentes.
