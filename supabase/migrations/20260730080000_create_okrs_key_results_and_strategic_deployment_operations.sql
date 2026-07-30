-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-06 — OKRs, Resultados-Chave e Desdobramento Estratégico
--
-- Escopo:
-- 1. Aplicabilidade configurável dos OKRs por Formulação.
-- 2. Governança, validação e prontidão do pacote FE-06.
-- 3. Operações auditadas para ciclos, OKRs, vínculos com OEs e KRs.
-- 4. Alinhamentos e dependências entre OKRs.
-- 5. Cálculo automático e atualização operacional de progresso.
-- 6. Consulta consolidada, auditoria e bloqueio integrado da Formulação.
--
-- Fora de escopo:
-- - gestão completa de Iniciativas, programas, projetos, 5W2H e portfólio;
-- - orçamento, cronograma, riscos e benefícios das Iniciativas;
-- - integração financeira completa.
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
-- 1. CABEÇALHO DE GOVERNANÇA E ALINHAMENTOS
-- ============================================================

create table if not exists public.skpe_okr_packages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  okr_enabled boolean not null default false,
  status text not null default 'not_applicable',
  okr_required_for_all_objectives boolean not null default false,
  okr_cycle_required boolean not null default true,
  minimum_key_results_per_okr integer not null default 3,
  maximum_key_results_per_okr integer not null default 5,
  key_result_baseline_required boolean not null default true,
  okr_owner_required boolean not null default false,
  key_result_owner_required boolean not null default false,
  key_result_owner_recommended boolean not null default true,
  key_result_weights_required boolean not null default false,
  okr_alignment_enabled boolean not null default true,
  automatic_progress_calculation boolean not null default true,
  allow_manual_progress_override boolean not null default false,
  cycle_overlap_policy text not null default 'warn',
  clone_progress_policy text not null default 'reset_to_baseline',
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

  constraint skpe_okr_packages_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_okr_packages_status_check
    check (status in (
      'not_applicable',
      'in_elaboration',
      'pending_validation',
      'validated'
    )),
  constraint skpe_okr_packages_kr_limits_check
    check (
      minimum_key_results_per_okr between 1 and 20
      and maximum_key_results_per_okr between minimum_key_results_per_okr and 30
    ),
  constraint skpe_okr_packages_overlap_policy_check
    check (cycle_overlap_policy in ('allow', 'warn', 'block')),
  constraint skpe_okr_packages_clone_progress_policy_check
    check (clone_progress_policy in ('reset_to_baseline', 'inherit_current')),
  constraint skpe_okr_packages_unique
    unique (formulation_id)
);

comment on table public.skpe_okr_packages is
  'Cabeçalho de aplicabilidade, configuração, submissão e validação do pacote FE-06 de OKRs e Resultados-Chave.';

comment on column public.skpe_okr_packages.okr_enabled is
  'Define se a organização adotou OKRs nesta versão. O padrão é opt-in: false.';

comment on column public.skpe_okr_packages.clone_progress_policy is
  'Regra aplicada ao clonar a Formulação: reiniciar o valor atual na linha de base ou herdar o valor atual anterior.';

create table if not exists public.skpe_okr_alignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  source_okr_id uuid not null,
  target_okr_id uuid not null,
  relation_type text not null,
  rationale text,
  status text not null default 'active',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_okr_alignments_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_okr_alignments_source_fkey
    foreign key (
      source_okr_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_okrs(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_okr_alignments_target_fkey
    foreign key (
      target_okr_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_okrs(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_okr_alignments_type_check
    check (relation_type in (
      'vertical',
      'horizontal',
      'depends_on',
      'supports',
      'contributes_to',
      'parent_child'
    )),
  constraint skpe_okr_alignments_status_check
    check (status in ('active', 'archived')),
  constraint skpe_okr_alignments_no_self
    check (source_okr_id <> target_okr_id),
  constraint skpe_okr_alignments_unique
    unique (source_okr_id, target_okr_id, relation_type)
);

comment on table public.skpe_okr_alignments is
  'Alinhamentos verticais, horizontais, hierárquicos e dependências direcionais entre OKRs da mesma Formulação.';

-- Situação de validação individual do OKR, ausente na fundação.
alter table public.skpe_okrs
  add column if not exists validation_status text not null default 'draft';

alter table public.skpe_okrs
  drop constraint if exists skpe_okrs_validation_status_check;

alter table public.skpe_okrs
  add constraint skpe_okrs_validation_status_check
  check (validation_status in ('draft', 'pending_validation', 'validated'));

create index if not exists idx_skpe_okr_packages_scope
  on public.skpe_okr_packages(
    organization_id,
    project_id,
    formulation_id,
    okr_enabled,
    status
  );

create index if not exists idx_skpe_okr_cycles_readiness
  on public.skpe_okr_cycles(
    formulation_id,
    status,
    period_start,
    period_end,
    code
  );

create index if not exists idx_skpe_okrs_readiness
  on public.skpe_okrs(
    formulation_id,
    okr_cycle_id,
    status,
    validation_status,
    code
  );

create index if not exists idx_skpe_okr_objectives_readiness
  on public.skpe_okr_objectives(
    formulation_id,
    okr_id,
    strategic_objective_id,
    is_primary
  );

create index if not exists idx_skpe_key_results_readiness
  on public.skpe_key_results(
    formulation_id,
    okr_id,
    status,
    validation_status,
    code
  );

create index if not exists idx_skpe_okr_alignments_readiness
  on public.skpe_okr_alignments(
    formulation_id,
    status,
    source_okr_id,
    target_okr_id,
    relation_type
  );

create unique index if not exists ux_skpe_okr_alignments_single_parent
  on public.skpe_okr_alignments(target_okr_id)
  where relation_type = 'parent_child' and status = 'active';

-- Gatilhos de updated_at confirmados e idempotentes.
drop trigger if exists skpe_okr_packages_set_updated_at
  on public.skpe_okr_packages;
create trigger skpe_okr_packages_set_updated_at
before update on public.skpe_okr_packages
for each row execute function public.set_updated_at();

drop trigger if exists skpe_okr_cycles_set_updated_at
  on public.skpe_okr_cycles;
create trigger skpe_okr_cycles_set_updated_at
before update on public.skpe_okr_cycles
for each row execute function public.set_updated_at();

drop trigger if exists skpe_okrs_set_updated_at
  on public.skpe_okrs;
create trigger skpe_okrs_set_updated_at
before update on public.skpe_okrs
for each row execute function public.set_updated_at();

drop trigger if exists skpe_key_results_set_updated_at
  on public.skpe_key_results;
create trigger skpe_key_results_set_updated_at
before update on public.skpe_key_results
for each row execute function public.set_updated_at();

drop trigger if exists skpe_okr_alignments_set_updated_at
  on public.skpe_okr_alignments;
create trigger skpe_okr_alignments_set_updated_at
before update on public.skpe_okr_alignments
for each row execute function public.set_updated_at();

alter table public.skpe_okr_packages enable row level security;
alter table public.skpe_okr_alignments enable row level security;

drop policy if exists skpe_okr_packages_select
  on public.skpe_okr_packages;
create policy skpe_okr_packages_select
on public.skpe_okr_packages
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_okr_alignments_select
  on public.skpe_okr_alignments;
create policy skpe_okr_alignments_select
on public.skpe_okr_alignments
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

-- O cabeçalho e os alinhamentos são conteúdo estrutural: proteção transversal.
drop trigger if exists skpe_okr_packages_guard_approved_formulation
  on public.skpe_okr_packages;
create trigger skpe_okr_packages_guard_approved_formulation
before insert or update or delete on public.skpe_okr_packages
for each row execute function public.skpe_guard_approved_formulation_content();

drop trigger if exists skpe_okr_alignments_guard_approved_formulation
  on public.skpe_okr_alignments;
create trigger skpe_okr_alignments_guard_approved_formulation
before insert or update or delete on public.skpe_okr_alignments
for each row execute function public.skpe_guard_approved_formulation_content();

-- ============================================================
-- 2. PROTEÇÃO E FUNÇÕES INTERNAS
-- ============================================================

create or replace function public.skpe_assert_valid_responsible_area(
  p_organization_id uuid,
  p_area_id uuid
)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_area_id is null then
    return;
  end if;

  if not exists (
    select 1
    from public.sparks_domain_values area_value
    join public.sparks_domains area_domain
      on area_domain.id = area_value.domain_id
    where area_value.id = p_area_id
      and area_domain.organization_id = p_organization_id
      and area_domain.scope_type = 'organization'
      and area_domain.code = 'ORGANIZATIONAL_AREA'
      and area_value.active
  ) then
    raise exception 'Área responsável inválida ou inativa para a organização.'
      using errcode = '22023';
  end if;
end;
$$;

comment on function public.skpe_assert_valid_responsible_area(uuid, uuid) is
  'Valida área responsável no domínio organizacional existente, sem criar cadastro paralelo.';

create or replace function public.skpe_calculate_key_result_progress(
  p_polarity text,
  p_baseline_value numeric,
  p_current_value numeric,
  p_target_value numeric,
  p_range_lower numeric default null,
  p_range_upper numeric default null
)
returns numeric
language plpgsql
immutable
security definer
set search_path = ''
as $$
declare
  normalized_polarity text;
  raw_progress numeric;
  baseline_distance numeric;
  current_distance numeric;
begin
  normalized_polarity := lower(trim(coalesce(p_polarity, '')));

  if p_baseline_value is null
     or p_current_value is null
     or p_target_value is null then
    return null;
  end if;

  if normalized_polarity = 'higher_is_better' then
    if p_target_value = p_baseline_value then
      raw_progress := case when p_current_value >= p_target_value then 100 else 0 end;
    else
      raw_progress :=
        (p_current_value - p_baseline_value)
        * 100
        / nullif(p_target_value - p_baseline_value, 0);
    end if;

  elsif normalized_polarity = 'lower_is_better' then
    if p_target_value = p_baseline_value then
      raw_progress := case when p_current_value <= p_target_value then 100 else 0 end;
    else
      raw_progress :=
        (p_baseline_value - p_current_value)
        * 100
        / nullif(p_baseline_value - p_target_value, 0);
    end if;

  elsif normalized_polarity = 'target_is_better' then
    baseline_distance := abs(p_baseline_value - p_target_value);
    current_distance := abs(p_current_value - p_target_value);

    if baseline_distance = 0 then
      raw_progress := case when current_distance = 0 then 100 else 0 end;
    else
      raw_progress := (1 - current_distance / baseline_distance) * 100;
    end if;

  elsif normalized_polarity = 'range_is_better' then
    if p_range_lower is null
       or p_range_upper is null
       or p_range_lower > p_range_upper then
      return null;
    end if;

    baseline_distance := case
      when p_baseline_value < p_range_lower then p_range_lower - p_baseline_value
      when p_baseline_value > p_range_upper then p_baseline_value - p_range_upper
      else 0
    end;

    current_distance := case
      when p_current_value < p_range_lower then p_range_lower - p_current_value
      when p_current_value > p_range_upper then p_current_value - p_range_upper
      else 0
    end;

    if current_distance = 0 then
      raw_progress := 100;
    elsif baseline_distance = 0 then
      raw_progress := 0;
    else
      raw_progress := (1 - current_distance / baseline_distance) * 100;
    end if;

  else
    return null;
  end if;

  return round(greatest(0, least(100, coalesce(raw_progress, 0))), 2);
end;
$$;

comment on function public.skpe_calculate_key_result_progress(text, numeric, numeric, numeric, numeric, numeric) is
  'Calcula progresso de KR com proteção contra nulos, divisão por zero e limites de 0 a 100.';

create or replace function public.skpe_okr_parent_would_create_cycle(
  p_formulation_id uuid,
  p_parent_okr_id uuid,
  p_child_okr_id uuid,
  p_excluded_alignment_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with recursive parent_edges as (
    select alignment.source_okr_id, alignment.target_okr_id
    from public.skpe_okr_alignments alignment
    where alignment.formulation_id = p_formulation_id
      and alignment.relation_type = 'parent_child'
      and alignment.status = 'active'
      and (p_excluded_alignment_id is null or alignment.id <> p_excluded_alignment_id)
  ),
  descendants(current_okr_id, visited_path) as (
    select p_child_okr_id, array[p_child_okr_id]::uuid[]
    union all
    select edge.target_okr_id, descendants.visited_path || edge.target_okr_id
    from descendants
    join parent_edges edge on edge.source_okr_id = descendants.current_okr_id
    where not edge.target_okr_id = any(descendants.visited_path)
  )
  select exists (
    select 1 from descendants where current_okr_id = p_parent_okr_id
  );
$$;

comment on function public.skpe_okr_parent_would_create_cycle(uuid, uuid, uuid, uuid) is
  'Detecta ciclo hierárquico antes de criar relação parent_child entre OKRs.';

create or replace function public.skpe_guard_okr_operational_content()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_formulation_id uuid;
  formulation_status text;
  old_structural jsonb;
  new_structural jsonb;
begin
  if tg_op = 'DELETE' then
    target_formulation_id := old.formulation_id;
  else
    target_formulation_id := new.formulation_id;
  end if;

  if target_formulation_id is null then
    if tg_op = 'DELETE' then return old; end if;
    return new;
  end if;

  select formulation.status
  into formulation_status
  from public.skpe_strategic_formulations formulation
  where formulation.id = target_formulation_id;

  if formulation_status is null then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if formulation_status in ('draft', 'in_elaboration') then
    if tg_op = 'DELETE' then return old; end if;
    return new;
  end if;

  if tg_op in ('INSERT', 'DELETE') then
    raise exception 'A estrutura de OKRs está bloqueada na situação atual da Formulação.'
      using errcode = '55000';
  end if;

  if tg_table_name = 'skpe_okr_cycles' then
    old_structural := to_jsonb(old)
      - array['status', 'metadata', 'updated_at', 'updated_by'];
    new_structural := to_jsonb(new)
      - array['status', 'metadata', 'updated_at', 'updated_by'];
  elsif tg_table_name = 'skpe_okrs' then
    old_structural := to_jsonb(old)
      - array['status', 'progress', 'metadata', 'updated_at', 'updated_by'];
    new_structural := to_jsonb(new)
      - array['status', 'progress', 'metadata', 'updated_at', 'updated_by'];
  elsif tg_table_name = 'skpe_key_results' then
    old_structural := to_jsonb(old)
      - array['current_value', 'status', 'progress', 'metadata', 'updated_at', 'updated_by'];
    new_structural := to_jsonb(new)
      - array['current_value', 'status', 'progress', 'metadata', 'updated_at', 'updated_by'];
  else
    raise exception 'Tabela não suportada pelo controle operacional de OKRs.'
      using errcode = '55000';
  end if;

  if old_structural is distinct from new_structural then
    raise exception
      'Somente campos operacionais de acompanhamento podem ser alterados após o bloqueio da Formulação.'
      using errcode = '55000';
  end if;

  return new;
end;
$$;

comment on function public.skpe_guard_okr_operational_content() is
  'Mantém campos estruturais imutáveis após a Formulação deixar a elaboração, permitindo apenas progresso e transições operacionais auditadas.';

-- Substitui apenas os três gatilhos genéricos em entidades que precisam continuar
-- recebendo acompanhamento operacional após a aprovação da Formulação.
drop trigger if exists skpe_okr_cycles_guard_approved_formulation
  on public.skpe_okr_cycles;
create trigger skpe_okr_cycles_guard_approved_formulation
before insert or update or delete on public.skpe_okr_cycles
for each row execute function public.skpe_guard_okr_operational_content();

drop trigger if exists skpe_okrs_guard_approved_formulation
  on public.skpe_okrs;
create trigger skpe_okrs_guard_approved_formulation
before insert or update or delete on public.skpe_okrs
for each row execute function public.skpe_guard_okr_operational_content();

drop trigger if exists skpe_key_results_guard_approved_formulation
  on public.skpe_key_results;
create trigger skpe_key_results_guard_approved_formulation
before insert or update or delete on public.skpe_key_results
for each row execute function public.skpe_guard_okr_operational_content();

create or replace function public.ensure_skpe_okr_package(
  p_formulation_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_okr_packages%rowtype;
  source_package public.skpe_okr_packages%rowtype;
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
  from public.skpe_okr_packages
  where formulation_id = p_formulation_id
  for update;

  if found then
    return package_row.id;
  end if;

  if formulation_row.derived_from_formulation_id is not null then
    select *
    into source_package
    from public.skpe_okr_packages
    where formulation_id = formulation_row.derived_from_formulation_id;
  end if;

  insert into public.skpe_okr_packages (
    organization_id,
    project_id,
    formulation_id,
    okr_enabled,
    status,
    okr_required_for_all_objectives,
    okr_cycle_required,
    minimum_key_results_per_okr,
    maximum_key_results_per_okr,
    key_result_baseline_required,
    okr_owner_required,
    key_result_owner_required,
    key_result_owner_recommended,
    key_result_weights_required,
    okr_alignment_enabled,
    automatic_progress_calculation,
    allow_manual_progress_override,
    cycle_overlap_policy,
    clone_progress_policy,
    metadata,
    created_by,
    updated_by
  )
  values (
    formulation_row.organization_id,
    formulation_row.project_id,
    formulation_row.id,
    coalesce(source_package.okr_enabled, false),
    case when coalesce(source_package.okr_enabled, false)
      then 'in_elaboration' else 'not_applicable' end,
    coalesce(source_package.okr_required_for_all_objectives, false),
    coalesce(source_package.okr_cycle_required, true),
    coalesce(source_package.minimum_key_results_per_okr, 3),
    coalesce(source_package.maximum_key_results_per_okr, 5),
    coalesce(source_package.key_result_baseline_required, true),
    coalesce(source_package.okr_owner_required, false),
    coalesce(source_package.key_result_owner_required, false),
    coalesce(source_package.key_result_owner_recommended, true),
    coalesce(source_package.key_result_weights_required, false),
    coalesce(source_package.okr_alignment_enabled, true),
    coalesce(source_package.automatic_progress_calculation, true),
    coalesce(source_package.allow_manual_progress_override, false),
    coalesce(source_package.cycle_overlap_policy, 'warn'),
    coalesce(source_package.clone_progress_policy, 'reset_to_baseline'),
    coalesce(source_package.metadata, '{}'::jsonb)
      || case
        when source_package.id is null then '{}'::jsonb
        else jsonb_build_object(
          'clonedFromOkrPackageId', source_package.id,
          'clonedFromFormulationId', formulation_row.derived_from_formulation_id
        )
      end,
    auth.uid(),
    auth.uid()
  )
  returning * into package_row;

  -- A função de clonagem consolidada já clona ciclos, OKRs, vínculos e KRs.
  -- Aqui são clonados somente os alinhamentos, estrutura inexistente na FE-01.
  if formulation_row.derived_from_formulation_id is not null then
    insert into public.skpe_okr_alignments (
      organization_id,
      project_id,
      formulation_id,
      source_okr_id,
      target_okr_id,
      relation_type,
      rationale,
      status,
      metadata,
      created_by,
      updated_by
    )
    select
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      new_source.id,
      new_target.id,
      alignment.relation_type,
      alignment.rationale,
      'active',
      coalesce(alignment.metadata, '{}'::jsonb)
        || jsonb_build_object('clonedFromId', alignment.id),
      auth.uid(),
      auth.uid()
    from public.skpe_okr_alignments alignment
    join public.skpe_okrs old_source
      on old_source.id = alignment.source_okr_id
    join public.skpe_okr_cycles old_source_cycle
      on old_source_cycle.id = old_source.okr_cycle_id
    join public.skpe_okr_cycles new_source_cycle
      on new_source_cycle.formulation_id = formulation_row.id
     and new_source_cycle.code = old_source_cycle.code
    join public.skpe_okrs new_source
      on new_source.okr_cycle_id = new_source_cycle.id
     and new_source.code = old_source.code
    join public.skpe_okrs old_target
      on old_target.id = alignment.target_okr_id
    join public.skpe_okr_cycles old_target_cycle
      on old_target_cycle.id = old_target.okr_cycle_id
    join public.skpe_okr_cycles new_target_cycle
      on new_target_cycle.formulation_id = formulation_row.id
     and new_target_cycle.code = old_target_cycle.code
    join public.skpe_okrs new_target
      on new_target.okr_cycle_id = new_target_cycle.id
     and new_target.code = old_target.code
    where alignment.formulation_id = formulation_row.derived_from_formulation_id
      and alignment.status = 'active'
    on conflict (source_okr_id, target_okr_id, relation_type) do nothing;

    -- Regra padrão: o valor atual da versão anterior não vira automaticamente
    -- a nova linha de base. O original é preservado em metadata para rastreabilidade.
    if package_row.clone_progress_policy = 'reset_to_baseline' then
      update public.skpe_key_results
      set
        metadata = coalesce(metadata, '{}'::jsonb)
          || jsonb_build_object(
            'clonedCurrentValueOriginal', current_value,
            'progressResetOnClone', true
          ),
        current_value = baseline_value,
        progress = 0,
        status = 'draft',
        validation_status = 'draft',
        updated_by = auth.uid()
      where formulation_id = formulation_row.id
        and metadata ? 'clonedFromId';
    end if;
  end if;

  update public.skpe_okrs
  set
    validation_status = 'draft',
    progress = 0,
    updated_by = auth.uid()
  where formulation_id = p_formulation_id
    and status <> 'cancelled';

  perform public.skpe_record_operational_audit(
    package_row.organization_id,
    package_row.project_id,
    'okr_package',
    package_row.id,
    'okr_package_created',
    'Criação automática do pacote operacional da FE-06.',
    null,
    to_jsonb(package_row)
  );

  return package_row.id;
end;
$$;

comment on function public.ensure_skpe_okr_package(uuid) is
  'Garante o pacote FE-06, herda configurações, clona alinhamentos e normaliza progresso conforme a política da revisão.';

create or replace function public.skpe_invalidate_okr_package(
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
  previous_package public.skpe_okr_packages%rowtype;
  updated_package public.skpe_okr_packages%rowtype;
begin
  package_id := public.ensure_skpe_okr_package(p_formulation_id);

  select *
  into previous_package
  from public.skpe_okr_packages
  where id = package_id
  for update;

  update public.skpe_okrs
  set
    validation_status = 'draft',
    updated_by = auth.uid()
  where formulation_id = p_formulation_id
    and status <> 'cancelled';

  update public.skpe_key_results
  set
    validation_status = 'draft',
    updated_by = auth.uid()
  where formulation_id = p_formulation_id
    and status <> 'cancelled';

  if not previous_package.okr_enabled then
    update public.skpe_okr_packages
    set
      status = 'not_applicable',
      validation_notes = null,
      submitted_for_validation_at = null,
      submitted_for_validation_by = null,
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where id = previous_package.id
    returning * into updated_package;
  else
    update public.skpe_okr_packages
    set
      status = 'in_elaboration',
      validation_notes = null,
      submitted_for_validation_at = null,
      submitted_for_validation_by = null,
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where id = previous_package.id
    returning * into updated_package;
  end if;

  if to_jsonb(previous_package) is distinct from to_jsonb(updated_package) then
    perform public.skpe_record_operational_audit(
      updated_package.organization_id,
      updated_package.project_id,
      'okr_package',
      updated_package.id,
      'okr_package_invalidated',
      coalesce(
        nullif(trim(p_reason), ''),
        'Alteração estrutural invalidou a validação anterior da FE-06.'
      ),
      to_jsonb(previous_package),
      to_jsonb(updated_package)
    );
  end if;

  return updated_package.id;
end;
$$;

comment on function public.skpe_invalidate_okr_package(uuid, text) is
  'Retorna o pacote FE-06 à elaboração após mutação estrutural; atualizações de medição não usam esta função.';

create or replace function public.skpe_recalculate_okr_progress(
  p_okr_id uuid,
  p_reason text
)
returns numeric
language plpgsql
security definer
set search_path = ''
as $$
declare
  okr_row public.skpe_okrs%rowtype;
  package_row public.skpe_okr_packages%rowtype;
  previous_data jsonb;
  updated_data jsonb;
  calculated_progress numeric := 0;
  active_kr_count integer := 0;
  weighted_kr_count integer := 0;
  total_weight numeric := 0;
  cycle_status text;
  calculated_status text;
begin
  select *
  into okr_row
  from public.skpe_okrs
  where id = p_okr_id
  for update;

  if not found then
    raise exception 'OKR não encontrado.' using errcode = '22023';
  end if;

  select *
  into package_row
  from public.skpe_okr_packages
  where formulation_id = okr_row.formulation_id;

  select cycle.status
  into cycle_status
  from public.skpe_okr_cycles cycle
  where cycle.id = okr_row.okr_cycle_id;

  select
    count(*),
    count(*) filter (where kr.contribution_weight is not null),
    coalesce(sum(kr.contribution_weight), 0)
  into active_kr_count, weighted_kr_count, total_weight
  from public.skpe_key_results kr
  where kr.okr_id = p_okr_id
    and kr.formulation_id = okr_row.formulation_id
    and kr.status <> 'cancelled';

  if active_kr_count = 0 then
    calculated_progress := 0;
  elsif weighted_kr_count = active_kr_count and total_weight > 0 then
    select round(
      coalesce(sum(kr.progress * kr.contribution_weight) / nullif(total_weight, 0), 0),
      2
    )
    into calculated_progress
    from public.skpe_key_results kr
    where kr.okr_id = p_okr_id
      and kr.formulation_id = okr_row.formulation_id
      and kr.status <> 'cancelled';
  else
    select round(coalesce(avg(kr.progress), 0), 2)
    into calculated_progress
    from public.skpe_key_results kr
    where kr.okr_id = p_okr_id
      and kr.formulation_id = okr_row.formulation_id
      and kr.status <> 'cancelled';
  end if;

  calculated_progress := greatest(0, least(100, coalesce(calculated_progress, 0)));

  calculated_status := case
    when okr_row.status = 'cancelled' then 'cancelled'
    when calculated_progress >= 100 then 'achieved'
    when exists (
      select 1 from public.skpe_key_results kr
      where kr.okr_id = p_okr_id and kr.status = 'at_risk'
    ) then 'at_risk'
    when cycle_status = 'completed' then 'not_achieved'
    when okr_row.status = 'draft' then 'draft'
    else 'active'
  end;

  previous_data := to_jsonb(okr_row);

  update public.skpe_okrs
  set
    progress = calculated_progress,
    status = calculated_status,
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'automaticProgress', calculated_progress,
        'progressCalculatedAt', timezone('utc', now()),
        'progressCalculationMode', case
          when weighted_kr_count = active_kr_count and total_weight > 0
            then 'weighted_average'
          else 'simple_average'
        end
      ),
    updated_by = auth.uid()
  where id = p_okr_id
  returning to_jsonb(skpe_okrs) into updated_data;

  if previous_data is distinct from updated_data then
    perform public.skpe_record_operational_audit(
      okr_row.organization_id,
      okr_row.project_id,
      'okr',
      okr_row.id,
      'okr_progress_recalculated',
      coalesce(nullif(trim(p_reason), ''), 'Recálculo automático do progresso do OKR.'),
      previous_data,
      updated_data
    );
  end if;

  return calculated_progress;
end;
$$;

comment on function public.skpe_recalculate_okr_progress(uuid, text) is
  'Calcula progresso simples ou ponderado do OKR a partir dos KRs não cancelados.';

-- ============================================================
-- 3. CONFIGURAÇÃO METODOLÓGICA
-- ============================================================

create or replace function public.configure_skpe_okr_package(
  p_formulation_id uuid,
  p_okr_enabled boolean default false,
  p_okr_required_for_all_objectives boolean default false,
  p_okr_cycle_required boolean default true,
  p_minimum_key_results_per_okr integer default 3,
  p_maximum_key_results_per_okr integer default 5,
  p_key_result_baseline_required boolean default true,
  p_okr_owner_required boolean default false,
  p_key_result_owner_required boolean default false,
  p_key_result_owner_recommended boolean default true,
  p_key_result_weights_required boolean default false,
  p_okr_alignment_enabled boolean default true,
  p_automatic_progress_calculation boolean default true,
  p_allow_manual_progress_override boolean default false,
  p_cycle_overlap_policy text default 'warn',
  p_clone_progress_policy text default 'reset_to_baseline',
  p_metadata jsonb default null,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  package_id uuid;
  previous_package public.skpe_okr_packages%rowtype;
  updated_package public.skpe_okr_packages%rowtype;
  normalized_overlap_policy text;
  normalized_clone_policy text;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  if p_minimum_key_results_per_okr not between 1 and 20 then
    raise exception 'O mínimo de Resultados-Chave deve estar entre 1 e 20.'
      using errcode = '22023';
  end if;

  if p_maximum_key_results_per_okr < p_minimum_key_results_per_okr
     or p_maximum_key_results_per_okr > 30 then
    raise exception 'O máximo de Resultados-Chave deve ser maior ou igual ao mínimo e até 30.'
      using errcode = '22023';
  end if;

  normalized_overlap_policy := lower(trim(coalesce(p_cycle_overlap_policy, 'warn')));
  normalized_clone_policy := lower(trim(coalesce(p_clone_progress_policy, 'reset_to_baseline')));

  if normalized_overlap_policy not in ('allow', 'warn', 'block') then
    raise exception 'Política de sobreposição inválida. Use allow, warn ou block.'
      using errcode = '22023';
  end if;

  if normalized_clone_policy not in ('reset_to_baseline', 'inherit_current') then
    raise exception 'Política de clonagem inválida.' using errcode = '22023';
  end if;

  if p_metadata is not null and jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'Os metadados devem ser um objeto JSON.' using errcode = '22023';
  end if;

  package_id := public.ensure_skpe_okr_package(p_formulation_id);

  select * into previous_package
  from public.skpe_okr_packages
  where id = package_id
  for update;

  update public.skpe_okr_packages
  set
    okr_enabled = coalesce(p_okr_enabled, false),
    status = case when coalesce(p_okr_enabled, false)
      then 'in_elaboration' else 'not_applicable' end,
    okr_required_for_all_objectives = coalesce(p_okr_required_for_all_objectives, false),
    okr_cycle_required = coalesce(p_okr_cycle_required, true),
    minimum_key_results_per_okr = p_minimum_key_results_per_okr,
    maximum_key_results_per_okr = p_maximum_key_results_per_okr,
    key_result_baseline_required = coalesce(p_key_result_baseline_required, true),
    okr_owner_required = coalesce(p_okr_owner_required, false),
    key_result_owner_required = coalesce(p_key_result_owner_required, false),
    key_result_owner_recommended = coalesce(p_key_result_owner_recommended, true),
    key_result_weights_required = coalesce(p_key_result_weights_required, false),
    okr_alignment_enabled = coalesce(p_okr_alignment_enabled, true),
    automatic_progress_calculation = coalesce(p_automatic_progress_calculation, true),
    allow_manual_progress_override = coalesce(p_allow_manual_progress_override, false),
    cycle_overlap_policy = normalized_overlap_policy,
    clone_progress_policy = normalized_clone_policy,
    validation_notes = null,
    submitted_for_validation_at = null,
    submitted_for_validation_by = null,
    validated_at = null,
    validated_by = null,
    metadata = coalesce(p_metadata, metadata),
    updated_by = auth.uid()
  where id = package_id
  returning * into updated_package;

  update public.skpe_okrs
  set validation_status = 'draft', updated_by = auth.uid()
  where formulation_id = p_formulation_id and status <> 'cancelled';

  update public.skpe_key_results
  set validation_status = 'draft', updated_by = auth.uid()
  where formulation_id = p_formulation_id and status <> 'cancelled';

  perform public.skpe_record_operational_audit(
    updated_package.organization_id,
    updated_package.project_id,
    'okr_package',
    updated_package.id,
    'okr_package_configured',
    p_change_reason,
    to_jsonb(previous_package),
    to_jsonb(updated_package)
  );

  return updated_package.id;
end;
$$;

-- ============================================================
-- 4. CICLOS DE OKR
-- ============================================================

create or replace function public.upsert_skpe_okr_cycle(
  p_formulation_id uuid,
  p_code text,
  p_name text,
  p_description text,
  p_cycle_type text,
  p_period_start date,
  p_period_end date,
  p_reference_year integer default null,
  p_owner_user_id uuid default null,
  p_status text default 'draft',
  p_cycle_id uuid default null,
  p_metadata jsonb default null,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  project_row public.skpe_projects%rowtype;
  package_row public.skpe_okr_packages%rowtype;
  previous_cycle public.skpe_okr_cycles%rowtype;
  saved_cycle public.skpe_okr_cycles%rowtype;
  horizon_start date;
  horizon_end date;
  normalized_type text;
  normalized_status text;
  action_code text;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  select * into project_row
  from public.skpe_projects
  where id = formulation_row.project_id;

  select * into package_row
  from public.skpe_okr_packages
  where formulation_id = p_formulation_id;

  if formulation_row.id is null then
    raise exception 'Formulação não encontrada.' using errcode = '22023';
  end if;

  if not coalesce(package_row.okr_enabled, false) then
    raise exception 'Habilite o uso de OKRs antes de cadastrar ciclos.'
      using errcode = '55000';
  end if;

  if length(trim(coalesce(p_code, ''))) = 0
     or length(trim(coalesce(p_name, ''))) = 0 then
    raise exception 'Código e nome do ciclo são obrigatórios.' using errcode = '22023';
  end if;

  if p_period_start is null or p_period_end is null or p_period_end < p_period_start then
    raise exception 'Informe um período válido para o ciclo.' using errcode = '22023';
  end if;

  normalized_type := lower(trim(coalesce(p_cycle_type, 'annual')));
  normalized_status := lower(trim(coalesce(p_status, 'draft')));

  if normalized_type not in ('annual', 'semester', 'quarter', 'custom') then
    raise exception 'Tipo de ciclo inválido.' using errcode = '22023';
  end if;

  if normalized_status not in ('draft', 'active') then
    raise exception 'Na elaboração, use situação draft ou active.' using errcode = '22023';
  end if;

  horizon_start := coalesce(
    formulation_row.valid_from,
    case when project_row.planning_horizon_start_year is null then null
      else make_date(project_row.planning_horizon_start_year, 1, 1) end
  );
  horizon_end := coalesce(
    formulation_row.valid_until,
    case when project_row.planning_horizon_end_year is null then null
      else make_date(project_row.planning_horizon_end_year, 12, 31) end
  );

  if (horizon_start is not null and p_period_start < horizon_start)
     or (horizon_end is not null and p_period_end > horizon_end) then
    raise exception 'O ciclo deve estar integralmente contido no horizonte da Formulação.'
      using errcode = '22023';
  end if;

  if coalesce(package_row.cycle_overlap_policy, 'warn') = 'block'
     and exists (
       select 1
       from public.skpe_okr_cycles cycle
       where cycle.formulation_id = p_formulation_id
         and cycle.status <> 'archived'
         and (p_cycle_id is null or cycle.id <> p_cycle_id)
         and daterange(cycle.period_start, cycle.period_end, '[]')
           && daterange(p_period_start, p_period_end, '[]')
     ) then
    raise exception 'A política da Formulação bloqueia sobreposição entre ciclos de OKR.'
      using errcode = '55000';
  end if;

  if p_metadata is not null and jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'Os metadados do ciclo devem ser um objeto JSON.' using errcode = '22023';
  end if;

  if p_cycle_id is not null then
    select * into previous_cycle
    from public.skpe_okr_cycles
    where id = p_cycle_id and formulation_id = p_formulation_id
    for update;
  else
    select * into previous_cycle
    from public.skpe_okr_cycles
    where formulation_id = p_formulation_id
      and lower(code) = lower(trim(p_code))
    for update;
  end if;

  if previous_cycle.id is not null
     and previous_cycle.status in ('completed', 'archived') then
    raise exception 'Ciclo concluído ou arquivado não pode ser sobrescrito. Use reabertura controlada quando aplicável.'
      using errcode = '55000';
  end if;

  if previous_cycle.id is null then
    insert into public.skpe_okr_cycles (
      organization_id, project_id, formulation_id,
      code, name, description, cycle_type, reference_year,
      period_start, period_end, owner_user_id, status, metadata,
      created_by, updated_by
    ) values (
      formulation_row.organization_id, formulation_row.project_id, formulation_row.id,
      trim(p_code), trim(p_name), nullif(trim(p_description), ''), normalized_type,
      coalesce(p_reference_year, extract(year from p_period_start)::integer),
      p_period_start, p_period_end, p_owner_user_id, normalized_status,
      coalesce(p_metadata, '{}'::jsonb), auth.uid(), auth.uid()
    ) returning * into saved_cycle;
    action_code := 'okr_cycle_created';
  else
    update public.skpe_okr_cycles
    set
      code = trim(p_code),
      name = trim(p_name),
      description = nullif(trim(p_description), ''),
      cycle_type = normalized_type,
      reference_year = coalesce(p_reference_year, extract(year from p_period_start)::integer),
      period_start = p_period_start,
      period_end = p_period_end,
      owner_user_id = p_owner_user_id,
      status = normalized_status,
      metadata = coalesce(p_metadata, metadata),
      updated_by = auth.uid()
    where id = previous_cycle.id
    returning * into saved_cycle;
    action_code := 'okr_cycle_updated';
  end if;

  perform public.skpe_invalidate_okr_package(p_formulation_id, p_change_reason);

  perform public.skpe_record_operational_audit(
    saved_cycle.organization_id, saved_cycle.project_id,
    'okr_cycle', saved_cycle.id, action_code, p_change_reason,
    case when previous_cycle.id is null then null else to_jsonb(previous_cycle) end,
    to_jsonb(saved_cycle)
  );

  return saved_cycle.id;
end;
$$;

create or replace function public.close_skpe_okr_cycle(
  p_cycle_id uuid,
  p_closure_notes text default null,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_cycle public.skpe_okr_cycles%rowtype;
  updated_cycle public.skpe_okr_cycles%rowtype;
  okr_record record;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into previous_cycle
  from public.skpe_okr_cycles
  where id = p_cycle_id
  for update;

  if not found then raise exception 'Ciclo não encontrado.' using errcode = '22023'; end if;
  if not public.can_manage_skpe_formulation(previous_cycle.organization_id) then
    raise exception 'Acesso negado para encerrar o ciclo.' using errcode = '42501';
  end if;
  if previous_cycle.status <> 'active' then
    raise exception 'Somente ciclos ativos podem ser encerrados.' using errcode = '55000';
  end if;

  update public.skpe_okr_cycles
  set
    status = 'completed',
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'closedAt', timezone('utc', now()),
        'closedBy', auth.uid(),
        'closureNotes', nullif(trim(p_closure_notes), '')
      ),
    updated_by = auth.uid()
  where id = p_cycle_id
  returning * into updated_cycle;

  perform public.skpe_record_operational_audit(
    updated_cycle.organization_id, updated_cycle.project_id,
    'okr_cycle', updated_cycle.id, 'okr_cycle_closed', p_change_reason,
    to_jsonb(previous_cycle), to_jsonb(updated_cycle)
  );

  for okr_record in
    select okr.id from public.skpe_okrs okr
    where okr.okr_cycle_id = updated_cycle.id and okr.status <> 'cancelled'
  loop
    perform public.skpe_recalculate_okr_progress(okr_record.id, p_change_reason);
  end loop;

  return updated_cycle.id;
end;
$$;

create or replace function public.reopen_skpe_okr_cycle(
  p_cycle_id uuid,
  p_reopen_notes text default null,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_cycle public.skpe_okr_cycles%rowtype;
  formulation_status text;
  updated_cycle public.skpe_okr_cycles%rowtype;
  okr_record record;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into previous_cycle
  from public.skpe_okr_cycles
  where id = p_cycle_id
  for update;

  if not found then raise exception 'Ciclo não encontrado.' using errcode = '22023'; end if;
  if not public.can_manage_skpe_formulation(previous_cycle.organization_id) then
    raise exception 'Acesso negado para reabrir o ciclo.' using errcode = '42501';
  end if;
  if previous_cycle.status <> 'completed' then
    raise exception 'Somente ciclos concluídos podem ser reabertos.' using errcode = '55000';
  end if;

  select status into formulation_status
  from public.skpe_strategic_formulations
  where id = previous_cycle.formulation_id;

  if formulation_status in ('superseded', 'archived') then
    raise exception 'Não é possível reabrir ciclo de Formulação substituída ou arquivada.'
      using errcode = '55000';
  end if;

  update public.skpe_okr_cycles
  set
    status = 'active',
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'reopenedAt', timezone('utc', now()),
        'reopenedBy', auth.uid(),
        'reopenNotes', nullif(trim(p_reopen_notes), '')
      ),
    updated_by = auth.uid()
  where id = p_cycle_id
  returning * into updated_cycle;

  perform public.skpe_record_operational_audit(
    updated_cycle.organization_id, updated_cycle.project_id,
    'okr_cycle', updated_cycle.id, 'okr_cycle_reopened', p_change_reason,
    to_jsonb(previous_cycle), to_jsonb(updated_cycle)
  );

  for okr_record in
    select okr.id from public.skpe_okrs okr
    where okr.okr_cycle_id = updated_cycle.id and okr.status <> 'cancelled'
  loop
    perform public.skpe_recalculate_okr_progress(okr_record.id, p_change_reason);
  end loop;

  return updated_cycle.id;
end;
$$;

-- ============================================================
-- 5. OKRs E VÍNCULOS COM OBJETIVOS ESTRATÉGICOS
-- ============================================================

create or replace function public.upsert_skpe_okr(
  p_formulation_id uuid,
  p_cycle_id uuid,
  p_code text,
  p_title text,
  p_description text,
  p_rationale text default null,
  p_owner_user_id uuid default null,
  p_responsible_area_id uuid default null,
  p_priority text default 'medium',
  p_status text default 'draft',
  p_display_order integer default 100,
  p_parent_okr_id uuid default null,
  p_okr_id uuid default null,
  p_metadata jsonb default null,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  cycle_row public.skpe_okr_cycles%rowtype;
  parent_row public.skpe_okrs%rowtype;
  previous_okr public.skpe_okrs%rowtype;
  saved_okr public.skpe_okrs%rowtype;
  normalized_status text;
  normalized_priority text;
  merged_metadata jsonb;
  action_code text;
begin
  perform public.skpe_assert_reason(p_change_reason);
  perform public.skpe_assert_formulation_editable(p_formulation_id);

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  select * into cycle_row
  from public.skpe_okr_cycles
  where id = p_cycle_id and formulation_id = p_formulation_id;

  if formulation_row.id is null or cycle_row.id is null then
    raise exception 'Formulação ou ciclo de OKR inválido.' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.skpe_okr_packages package
    where package.formulation_id = p_formulation_id
      and package.okr_enabled
  ) then
    raise exception 'Habilite o uso de OKRs antes de cadastrar Objetivos do ciclo.'
      using errcode = '55000';
  end if;

  if cycle_row.status = 'archived' then
    raise exception 'Não é possível cadastrar OKR em ciclo arquivado.' using errcode = '55000';
  end if;

  if length(trim(coalesce(p_code, ''))) = 0
     or length(trim(coalesce(p_title, ''))) = 0 then
    raise exception 'Código e título do OKR são obrigatórios.' using errcode = '22023';
  end if;

  normalized_status := lower(trim(coalesce(p_status, 'draft')));
  normalized_priority := lower(trim(coalesce(p_priority, 'medium')));

  if normalized_status not in ('draft', 'active', 'at_risk') then
    raise exception 'Na elaboração, use status draft, active ou at_risk.' using errcode = '22023';
  end if;
  if normalized_priority not in ('low', 'medium', 'high', 'critical') then
    raise exception 'Prioridade inválida.' using errcode = '22023';
  end if;
  if coalesce(p_display_order, 100) < 0 then
    raise exception 'A ordem de exibição não pode ser negativa.' using errcode = '22023';
  end if;

  perform public.skpe_assert_valid_responsible_area(
    formulation_row.organization_id,
    p_responsible_area_id
  );

  if p_parent_okr_id is not null then
    select * into parent_row
    from public.skpe_okrs
    where id = p_parent_okr_id and formulation_id = p_formulation_id;

    if parent_row.id is null then
      raise exception 'OKR pai inválido para a Formulação.' using errcode = '22023';
    end if;
    if p_okr_id is not null and p_parent_okr_id = p_okr_id then
      raise exception 'Um OKR não pode ser pai de si próprio.' using errcode = '22023';
    end if;
  end if;

  if p_metadata is not null and jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'Os metadados do OKR devem ser um objeto JSON.' using errcode = '22023';
  end if;

  merged_metadata := coalesce(p_metadata, '{}'::jsonb)
    || jsonb_build_object(
      'rationale', nullif(trim(p_rationale), ''),
      'responsibleAreaId', p_responsible_area_id,
      'priority', normalized_priority
    );

  if p_parent_okr_id is not null then
    merged_metadata := merged_metadata
      || jsonb_build_object('parentOkrCode', parent_row.code);
  end if;

  if p_okr_id is not null then
    select * into previous_okr
    from public.skpe_okrs
    where id = p_okr_id and formulation_id = p_formulation_id
    for update;
  else
    select * into previous_okr
    from public.skpe_okrs
    where okr_cycle_id = p_cycle_id
      and lower(code) = lower(trim(p_code))
    for update;
  end if;

  if previous_okr.id is not null and previous_okr.status = 'cancelled' then
    raise exception 'OKR arquivado não pode ser sobrescrito. Preserve o histórico e use outro código.'
      using errcode = '55000';
  end if;

  if previous_okr.id is null then
    insert into public.skpe_okrs (
      organization_id, project_id, formulation_id, okr_cycle_id,
      code, title, description, owner_user_id, status, progress,
      display_order, metadata, validation_status, created_by, updated_by
    ) values (
      formulation_row.organization_id, formulation_row.project_id,
      formulation_row.id, cycle_row.id, trim(p_code), trim(p_title),
      nullif(trim(p_description), ''), p_owner_user_id, normalized_status, 0,
      coalesce(p_display_order, 100), merged_metadata, 'draft',
      auth.uid(), auth.uid()
    ) returning * into saved_okr;
    action_code := 'okr_created';
  else
    update public.skpe_okrs
    set
      okr_cycle_id = cycle_row.id,
      code = trim(p_code),
      title = trim(p_title),
      description = nullif(trim(p_description), ''),
      owner_user_id = p_owner_user_id,
      status = normalized_status,
      display_order = coalesce(p_display_order, 100),
      metadata = coalesce(previous_okr.metadata, '{}'::jsonb) || merged_metadata,
      validation_status = 'draft',
      updated_by = auth.uid()
    where id = previous_okr.id
    returning * into saved_okr;
    action_code := 'okr_updated';
  end if;

  if p_parent_okr_id is not null then
    perform public.upsert_skpe_okr_alignment(
      p_parent_okr_id,
      saved_okr.id,
      'parent_child',
      'Hierarquia informada no cadastro do OKR.',
      null,
      jsonb_build_object('createdFromOkrUpsert', true),
      p_change_reason
    );
  end if;

  perform public.skpe_invalidate_okr_package(p_formulation_id, p_change_reason);

  perform public.skpe_record_operational_audit(
    saved_okr.organization_id, saved_okr.project_id,
    'okr', saved_okr.id, action_code, p_change_reason,
    case when previous_okr.id is null then null else to_jsonb(previous_okr) end,
    to_jsonb(saved_okr)
  );

  return saved_okr.id;
end;
$$;

create or replace function public.archive_skpe_okr(
  p_okr_id uuid,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_okr public.skpe_okrs%rowtype;
  updated_okr public.skpe_okrs%rowtype;
  previous_key_results jsonb := '[]'::jsonb;
  updated_key_results jsonb := '[]'::jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into previous_okr
  from public.skpe_okrs
  where id = p_okr_id
  for update;

  if not found then raise exception 'OKR não encontrado.' using errcode = '22023'; end if;
  perform public.skpe_assert_formulation_editable(previous_okr.formulation_id);

  select coalesce(jsonb_agg(to_jsonb(kr) order by kr.code), '[]'::jsonb)
  into previous_key_results
  from public.skpe_key_results kr
  where kr.okr_id = previous_okr.id and kr.status <> 'cancelled';

  update public.skpe_key_results
  set
    status = 'cancelled',
    validation_status = 'draft',
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'archivedByOkrCascade', true,
        'archivedAt', timezone('utc', now()),
        'archivedBy', auth.uid()
      ),
    updated_by = auth.uid()
  where okr_id = previous_okr.id and status <> 'cancelled';

  select coalesce(jsonb_agg(to_jsonb(kr) order by kr.code), '[]'::jsonb)
  into updated_key_results
  from public.skpe_key_results kr
  where kr.okr_id = previous_okr.id;

  update public.skpe_okrs
  set
    status = 'cancelled',
    validation_status = 'draft',
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object('archivedAt', timezone('utc', now()), 'archivedBy', auth.uid()),
    updated_by = auth.uid()
  where id = p_okr_id
  returning * into updated_okr;

  update public.skpe_okr_alignments
  set status = 'archived', updated_by = auth.uid()
  where formulation_id = previous_okr.formulation_id
    and status = 'active'
    and (source_okr_id = p_okr_id or target_okr_id = p_okr_id);

  perform public.skpe_invalidate_okr_package(previous_okr.formulation_id, p_change_reason);

  if jsonb_array_length(previous_key_results) > 0 then
    perform public.skpe_record_operational_audit(
      updated_okr.organization_id, updated_okr.project_id,
      'okr', updated_okr.id, 'okr_key_results_archived', p_change_reason,
      previous_key_results, updated_key_results
    );
  end if;

  perform public.skpe_record_operational_audit(
    updated_okr.organization_id, updated_okr.project_id,
    'okr', updated_okr.id, 'okr_archived', p_change_reason,
    to_jsonb(previous_okr), to_jsonb(updated_okr)
  );

  return updated_okr.id;
end;
$$;

create or replace function public.link_skpe_okr_objective(
  p_okr_id uuid,
  p_strategic_objective_id uuid,
  p_contribution_weight numeric default null,
  p_is_primary boolean default false,
  p_notes text default null,
  p_change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  okr_row public.skpe_okrs%rowtype;
  objective_row public.skpe_strategic_objectives%rowtype;
  previous_link jsonb;
  new_link jsonb;
  previous_primary_link jsonb;
  previous_primary_objective_id uuid;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into okr_row from public.skpe_okrs where id = p_okr_id;
  select * into objective_row from public.skpe_strategic_objectives where id = p_strategic_objective_id;

  if okr_row.id is null or objective_row.id is null then
    raise exception 'OKR ou Objetivo Estratégico não encontrado.' using errcode = '22023';
  end if;
  perform public.skpe_assert_formulation_editable(okr_row.formulation_id);

  if objective_row.formulation_id <> okr_row.formulation_id
     or objective_row.organization_id <> okr_row.organization_id
     or objective_row.project_id <> okr_row.project_id then
    raise exception 'OKR e Objetivo Estratégico devem pertencer ao mesmo escopo.'
      using errcode = '22023';
  end if;
  if objective_row.status = 'archived' then
    raise exception 'Não é possível vincular Objetivo Estratégico arquivado.' using errcode = '55000';
  end if;
  if p_contribution_weight is not null and p_contribution_weight not between 0 and 100 then
    raise exception 'O peso de contribuição deve estar entre 0 e 100.' using errcode = '22023';
  end if;

  select to_jsonb(link) into previous_link
  from public.skpe_okr_objectives link
  where link.okr_id = p_okr_id
    and link.strategic_objective_id = p_strategic_objective_id;

  if coalesce(p_is_primary, false) then
    select link.strategic_objective_id, to_jsonb(link)
    into previous_primary_objective_id, previous_primary_link
    from public.skpe_okr_objectives link
    where link.okr_id = p_okr_id and link.is_primary
    limit 1;

    update public.skpe_okr_objectives
    set is_primary = false
    where okr_id = p_okr_id and is_primary;
  end if;

  insert into public.skpe_okr_objectives (
    organization_id, project_id, formulation_id,
    okr_id, strategic_objective_id, contribution_weight,
    is_primary, notes, created_by
  ) values (
    okr_row.organization_id, okr_row.project_id, okr_row.formulation_id,
    okr_row.id, objective_row.id, p_contribution_weight,
    coalesce(p_is_primary, false), nullif(trim(p_notes), ''), auth.uid()
  )
  on conflict (okr_id, strategic_objective_id)
  do update set
    contribution_weight = excluded.contribution_weight,
    is_primary = excluded.is_primary,
    notes = excluded.notes;

  select to_jsonb(link) into new_link
  from public.skpe_okr_objectives link
  where link.okr_id = p_okr_id
    and link.strategic_objective_id = p_strategic_objective_id;

  perform public.skpe_invalidate_okr_package(okr_row.formulation_id, p_change_reason);

  if previous_primary_objective_id is not null
     and previous_primary_objective_id <> p_strategic_objective_id then
    perform public.skpe_record_operational_audit(
      okr_row.organization_id, okr_row.project_id,
      'okr_objective_link', okr_row.id, 'okr_primary_objective_replaced', p_change_reason,
      previous_primary_link,
      coalesce(previous_primary_link, '{}'::jsonb) || jsonb_build_object('is_primary', false)
    );
  end if;

  perform public.skpe_record_operational_audit(
    okr_row.organization_id, okr_row.project_id,
    'okr_objective_link', okr_row.id, 'okr_objective_linked', p_change_reason,
    previous_link, new_link
  );

  return true;
end;
$$;

create or replace function public.unlink_skpe_okr_objective(
  p_okr_id uuid,
  p_strategic_objective_id uuid,
  p_change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  okr_row public.skpe_okrs%rowtype;
  previous_link jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);
  select * into okr_row from public.skpe_okrs where id = p_okr_id;
  if not found then raise exception 'OKR não encontrado.' using errcode = '22023'; end if;
  perform public.skpe_assert_formulation_editable(okr_row.formulation_id);

  select to_jsonb(link) into previous_link
  from public.skpe_okr_objectives link
  where link.okr_id = p_okr_id
    and link.strategic_objective_id = p_strategic_objective_id;

  if previous_link is null then return false; end if;

  delete from public.skpe_okr_objectives
  where okr_id = p_okr_id and strategic_objective_id = p_strategic_objective_id;

  perform public.skpe_invalidate_okr_package(okr_row.formulation_id, p_change_reason);

  perform public.skpe_record_operational_audit(
    okr_row.organization_id, okr_row.project_id,
    'okr_objective_link', okr_row.id, 'okr_objective_unlinked', p_change_reason,
    previous_link, null
  );

  return true;
end;
$$;

-- ============================================================
-- 6. RESULTADOS-CHAVE
-- ============================================================

create or replace function public.upsert_skpe_key_result(
  p_okr_id uuid,
  p_code text,
  p_name text,
  p_definition text,
  p_baseline_value numeric,
  p_target_value numeric,
  p_current_value numeric,
  p_unit text,
  p_polarity text,
  p_formula_text text,
  p_calculation_method text,
  p_data_source text,
  p_measurement_frequency text,
  p_period_start date,
  p_period_end date,
  p_owner_user_id uuid default null,
  p_responsible_area_id uuid default null,
  p_contribution_weight numeric default null,
  p_linked_indicator_id uuid default null,
  p_range_lower numeric default null,
  p_range_upper numeric default null,
  p_collection_automatable boolean default null,
  p_status text default 'draft',
  p_strategic_objective_id uuid default null,
  p_key_result_id uuid default null,
  p_metadata jsonb default null,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  okr_row public.skpe_okrs%rowtype;
  cycle_row public.skpe_okr_cycles%rowtype;
  package_row public.skpe_okr_packages%rowtype;
  objective_row public.skpe_strategic_objectives%rowtype;
  indicator_row public.skpe_indicators%rowtype;
  previous_kr public.skpe_key_results%rowtype;
  saved_kr public.skpe_key_results%rowtype;
  effective_objective_id uuid;
  normalized_polarity text;
  normalized_status text;
  normalized_frequency text;
  calculated_progress numeric;
  merged_metadata jsonb;
  action_code text;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into okr_row from public.skpe_okrs where id = p_okr_id;
  if not found then raise exception 'OKR não encontrado.' using errcode = '22023'; end if;
  perform public.skpe_assert_formulation_editable(okr_row.formulation_id);

  select * into cycle_row from public.skpe_okr_cycles where id = okr_row.okr_cycle_id;
  select * into package_row from public.skpe_okr_packages where formulation_id = okr_row.formulation_id;

  if not coalesce(package_row.okr_enabled, false) then
    raise exception 'Os OKRs não estão habilitados para esta Formulação.'
      using errcode = '55000';
  end if;

  if length(trim(coalesce(p_code, ''))) = 0
     or length(trim(coalesce(p_name, ''))) = 0 then
    raise exception 'Código e nome do Resultado-Chave são obrigatórios.' using errcode = '22023';
  end if;
  if p_period_start is null or p_period_end is null or p_period_end < p_period_start then
    raise exception 'Informe período válido para o Resultado-Chave.' using errcode = '22023';
  end if;
  if p_period_start < cycle_row.period_start or p_period_end > cycle_row.period_end then
    raise exception 'O Resultado-Chave deve estar integralmente contido no ciclo do OKR.'
      using errcode = '22023';
  end if;
  if length(trim(coalesce(p_unit, ''))) = 0 then
    raise exception 'A unidade de medida é obrigatória.' using errcode = '22023';
  end if;

  normalized_polarity := lower(trim(coalesce(p_polarity, '')));
  normalized_status := lower(trim(coalesce(p_status, 'draft')));
  normalized_frequency := lower(trim(coalesce(p_measurement_frequency, '')));

  if normalized_polarity not in (
    'higher_is_better', 'lower_is_better', 'target_is_better', 'range_is_better'
  ) then
    raise exception 'Polaridade inválida para o Resultado-Chave.' using errcode = '22023';
  end if;
  if normalized_status not in ('draft', 'active', 'at_risk') then
    raise exception 'Na elaboração, use status draft, active ou at_risk.' using errcode = '22023';
  end if;
  if normalized_frequency not in (
    'daily', 'weekly', 'monthly', 'bimonthly', 'quarterly',
    'semiannual', 'annual', 'on_demand'
  ) then
    raise exception 'Frequência de acompanhamento inválida.' using errcode = '22023';
  end if;
  if p_contribution_weight is not null and p_contribution_weight not between 0 and 100 then
    raise exception 'O peso deve estar entre 0 e 100.' using errcode = '22023';
  end if;

  if normalized_polarity = 'higher_is_better'
     and p_baseline_value is not null and p_target_value is not null
     and p_target_value < p_baseline_value then
    raise exception 'Para higher_is_better, o alvo não pode ser inferior à linha de base.'
      using errcode = '22023';
  end if;
  if normalized_polarity = 'lower_is_better'
     and p_baseline_value is not null and p_target_value is not null
     and p_target_value > p_baseline_value then
    raise exception 'Para lower_is_better, o alvo não pode ser superior à linha de base.'
      using errcode = '22023';
  end if;
  if normalized_polarity = 'range_is_better'
     and (p_range_lower is null or p_range_upper is null or p_range_lower > p_range_upper) then
    raise exception 'Para range_is_better, informe uma faixa válida.' using errcode = '22023';
  end if;
  if normalized_polarity = 'range_is_better'
     and p_target_value is not null
     and (p_target_value < p_range_lower or p_target_value > p_range_upper) then
    raise exception 'Para range_is_better, o valor-alvo deve estar contido na faixa.'
      using errcode = '22023';
  end if;

  effective_objective_id := p_strategic_objective_id;
  if effective_objective_id is null then
    select link.strategic_objective_id
    into effective_objective_id
    from public.skpe_okr_objectives link
    where link.okr_id = okr_row.id
    order by link.is_primary desc, link.created_at, link.strategic_objective_id
    limit 1;
  end if;

  if effective_objective_id is null then
    raise exception 'Vincule o OKR a um Objetivo Estratégico antes de cadastrar Resultados-Chave.'
      using errcode = '55000';
  end if;

  select * into objective_row
  from public.skpe_strategic_objectives
  where id = effective_objective_id;

  if objective_row.formulation_id <> okr_row.formulation_id
     or not exists (
       select 1 from public.skpe_okr_objectives link
       where link.okr_id = okr_row.id
         and link.strategic_objective_id = effective_objective_id
     ) then
    raise exception 'O Objetivo Estratégico do KR deve estar vinculado ao mesmo OKR.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_valid_responsible_area(
    okr_row.organization_id,
    p_responsible_area_id
  );

  if p_linked_indicator_id is not null then
    select * into indicator_row
    from public.skpe_indicators
    where id = p_linked_indicator_id;

    if indicator_row.id is null
       or indicator_row.formulation_id <> okr_row.formulation_id
       or indicator_row.organization_id <> okr_row.organization_id
       or indicator_row.project_id <> okr_row.project_id
       or indicator_row.status = 'archived' then
      raise exception 'O Indicador vinculado deve pertencer à mesma Formulação e estar ativo no escopo.'
        using errcode = '22023';
    end if;
  end if;

  if p_metadata is not null and jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'Os metadados do Resultado-Chave devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  calculated_progress := case
    when coalesce(package_row.automatic_progress_calculation, true) then
      public.skpe_calculate_key_result_progress(
        normalized_polarity, p_baseline_value, p_current_value, p_target_value,
        p_range_lower, p_range_upper
      )
    else null
  end;

  merged_metadata := coalesce(p_metadata, '{}'::jsonb)
    || jsonb_build_object(
      'polarity', normalized_polarity,
      'formulaText', nullif(trim(p_formula_text), ''),
      'calculationMethod', nullif(trim(p_calculation_method), ''),
      'dataSource', nullif(trim(p_data_source), ''),
      'measurementFrequency', normalized_frequency,
      'responsibleAreaId', p_responsible_area_id,
      'linkedIndicatorCode', case when indicator_row.id is null then null else indicator_row.code end,
      'linkedIndicatorScope', case when indicator_row.id is null then null else indicator_row.indicator_scope end,
      'rangeLower', p_range_lower,
      'rangeUpper', p_range_upper,
      'collectionAutomatable', p_collection_automatable,
      'automaticProgress', calculated_progress
    );

  if p_key_result_id is not null then
    select * into previous_kr
    from public.skpe_key_results
    where id = p_key_result_id
      and formulation_id = okr_row.formulation_id
    for update;
  else
    select * into previous_kr
    from public.skpe_key_results
    where okr_id = okr_row.id and lower(code) = lower(trim(p_code))
    for update;
  end if;

  if previous_kr.id is not null and previous_kr.status = 'cancelled' then
    raise exception 'Resultado-Chave arquivado não pode ser sobrescrito. Preserve o histórico e use outro código.'
      using errcode = '55000';
  end if;

  if previous_kr.id is null then
    insert into public.skpe_key_results (
      organization_id, project_id, strategic_objective_id,
      code, name, description, baseline_value, target_value, current_value,
      unit, period_start, period_end, owner_user_id, status, progress,
      metadata, created_by, updated_by, formulation_id, okr_id,
      contribution_weight, annualized_target, validation_status
    ) values (
      okr_row.organization_id, okr_row.project_id, effective_objective_id,
      trim(p_code), trim(p_name), nullif(trim(p_definition), ''),
      p_baseline_value, p_target_value, p_current_value, trim(p_unit),
      p_period_start, p_period_end, p_owner_user_id, normalized_status,
      coalesce(calculated_progress, 0), merged_metadata, auth.uid(), auth.uid(),
      okr_row.formulation_id, okr_row.id, p_contribution_weight,
      cycle_row.cycle_type = 'annual', 'draft'
    ) returning * into saved_kr;
    action_code := 'key_result_created';
  else
    update public.skpe_key_results
    set
      strategic_objective_id = effective_objective_id,
      code = trim(p_code),
      name = trim(p_name),
      description = nullif(trim(p_definition), ''),
      baseline_value = p_baseline_value,
      target_value = p_target_value,
      current_value = p_current_value,
      unit = trim(p_unit),
      period_start = p_period_start,
      period_end = p_period_end,
      owner_user_id = p_owner_user_id,
      status = normalized_status,
      progress = coalesce(calculated_progress, progress),
      metadata = coalesce(previous_kr.metadata, '{}'::jsonb) || merged_metadata,
      formulation_id = okr_row.formulation_id,
      okr_id = okr_row.id,
      contribution_weight = p_contribution_weight,
      annualized_target = cycle_row.cycle_type = 'annual',
      validation_status = 'draft',
      updated_by = auth.uid()
    where id = previous_kr.id
    returning * into saved_kr;
    action_code := 'key_result_updated';
  end if;

  perform public.skpe_invalidate_okr_package(okr_row.formulation_id, p_change_reason);
  perform public.skpe_recalculate_okr_progress(okr_row.id, p_change_reason);

  perform public.skpe_record_operational_audit(
    saved_kr.organization_id, saved_kr.project_id,
    'key_result', saved_kr.id, action_code, p_change_reason,
    case when previous_kr.id is null then null else to_jsonb(previous_kr) end,
    to_jsonb(saved_kr)
  );

  return saved_kr.id;
end;
$$;

create or replace function public.archive_skpe_key_result(
  p_key_result_id uuid,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_kr public.skpe_key_results%rowtype;
  updated_kr public.skpe_key_results%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into previous_kr
  from public.skpe_key_results
  where id = p_key_result_id
  for update;

  if not found then raise exception 'Resultado-Chave não encontrado.' using errcode = '22023'; end if;
  perform public.skpe_assert_formulation_editable(previous_kr.formulation_id);

  update public.skpe_key_results
  set
    status = 'cancelled',
    validation_status = 'draft',
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object('archivedAt', timezone('utc', now()), 'archivedBy', auth.uid()),
    updated_by = auth.uid()
  where id = p_key_result_id
  returning * into updated_kr;

  perform public.skpe_invalidate_okr_package(previous_kr.formulation_id, p_change_reason);
  perform public.skpe_recalculate_okr_progress(previous_kr.okr_id, p_change_reason);

  perform public.skpe_record_operational_audit(
    updated_kr.organization_id, updated_kr.project_id,
    'key_result', updated_kr.id, 'key_result_archived', p_change_reason,
    to_jsonb(previous_kr), to_jsonb(updated_kr)
  );

  return updated_kr.id;
end;
$$;

create or replace function public.update_skpe_key_result_progress(
  p_key_result_id uuid,
  p_current_value numeric,
  p_status text default null,
  p_manual_progress_override numeric default null,
  p_measurement_notes text default null,
  p_change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_kr public.skpe_key_results%rowtype;
  updated_kr public.skpe_key_results%rowtype;
  cycle_row public.skpe_okr_cycles%rowtype;
  package_row public.skpe_okr_packages%rowtype;
  automatic_progress numeric;
  effective_progress numeric;
  normalized_status text;
  range_lower numeric;
  range_upper numeric;
  okr_progress numeric;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into previous_kr
  from public.skpe_key_results
  where id = p_key_result_id
  for update;

  if not found then raise exception 'Resultado-Chave não encontrado.' using errcode = '22023'; end if;
  if not public.can_manage_skpe_formulation(previous_kr.organization_id) then
    raise exception 'Acesso negado para atualizar o Resultado-Chave.' using errcode = '42501';
  end if;

  select cycle.* into cycle_row
  from public.skpe_okr_cycles cycle
  join public.skpe_okrs okr on okr.okr_cycle_id = cycle.id
  where okr.id = previous_kr.okr_id;

  if cycle_row.status = 'completed' then
    raise exception 'O ciclo está encerrado. Reabra-o de forma controlada antes de atualizar o progresso.'
      using errcode = '55000';
  end if;

  select * into package_row
  from public.skpe_okr_packages
  where formulation_id = previous_kr.formulation_id;

  if not coalesce(package_row.okr_enabled, false) then
    raise exception 'Os OKRs não estão habilitados para esta Formulação.' using errcode = '55000';
  end if;

  if p_manual_progress_override is not null
     and not coalesce(package_row.allow_manual_progress_override, false) then
    raise exception 'A configuração da Formulação não permite substituição manual do progresso.'
      using errcode = '55000';
  end if;
  if p_manual_progress_override is not null
     and p_manual_progress_override not between 0 and 100 then
    raise exception 'O progresso manual deve estar entre 0 e 100.' using errcode = '22023';
  end if;

  range_lower := nullif(previous_kr.metadata ->> 'rangeLower', '')::numeric;
  range_upper := nullif(previous_kr.metadata ->> 'rangeUpper', '')::numeric;

  automatic_progress := public.skpe_calculate_key_result_progress(
    previous_kr.metadata ->> 'polarity',
    previous_kr.baseline_value,
    p_current_value,
    previous_kr.target_value,
    range_lower,
    range_upper
  );

  effective_progress := case
    when p_manual_progress_override is not null then p_manual_progress_override
    when coalesce(package_row.automatic_progress_calculation, true) then automatic_progress
    else previous_kr.progress
  end;
  effective_progress := greatest(0, least(100, coalesce(effective_progress, 0)));

  normalized_status := lower(trim(coalesce(p_status, previous_kr.status)));
  if normalized_status not in ('draft', 'active', 'at_risk', 'achieved', 'not_achieved') then
    raise exception 'Situação operacional inválida para o Resultado-Chave.' using errcode = '22023';
  end if;

  update public.skpe_key_results
  set
    current_value = p_current_value,
    progress = effective_progress,
    status = normalized_status,
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'automaticProgress', automatic_progress,
        'manualProgressOverride', p_manual_progress_override,
        'progressDivergence', case
          when p_manual_progress_override is null or automatic_progress is null then null
          else round(p_manual_progress_override - automatic_progress, 2)
        end,
        'lastMeasurementAt', timezone('utc', now()),
        'lastMeasurementBy', auth.uid(),
        'lastMeasurementNotes', nullif(trim(p_measurement_notes), '')
      ),
    updated_by = auth.uid()
  where id = p_key_result_id
  returning * into updated_kr;

  perform public.skpe_record_operational_audit(
    updated_kr.organization_id, updated_kr.project_id,
    'key_result', updated_kr.id, 'key_result_progress_updated', p_change_reason,
    to_jsonb(previous_kr), to_jsonb(updated_kr)
  );

  okr_progress := public.skpe_recalculate_okr_progress(updated_kr.okr_id, p_change_reason);

  return jsonb_build_object(
    'keyResultId', updated_kr.id,
    'currentValue', updated_kr.current_value,
    'automaticProgress', automatic_progress,
    'effectiveProgress', updated_kr.progress,
    'manualOverrideApplied', p_manual_progress_override is not null,
    'okrId', updated_kr.okr_id,
    'okrProgress', okr_progress
  );
end;
$$;

-- ============================================================
-- 7. ALINHAMENTOS E DEPENDÊNCIAS
-- ============================================================

create or replace function public.upsert_skpe_okr_alignment(
  p_source_okr_id uuid,
  p_target_okr_id uuid,
  p_relation_type text,
  p_rationale text default null,
  p_alignment_id uuid default null,
  p_metadata jsonb default null,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  source_okr public.skpe_okrs%rowtype;
  target_okr public.skpe_okrs%rowtype;
  package_row public.skpe_okr_packages%rowtype;
  previous_alignment public.skpe_okr_alignments%rowtype;
  saved_alignment public.skpe_okr_alignments%rowtype;
  normalized_type text;
  action_code text;
  replaced_parents jsonb := '[]'::jsonb;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into source_okr from public.skpe_okrs where id = p_source_okr_id;
  select * into target_okr from public.skpe_okrs where id = p_target_okr_id;

  if source_okr.id is null or target_okr.id is null then
    raise exception 'OKR de origem ou destino não encontrado.' using errcode = '22023';
  end if;
  perform public.skpe_assert_formulation_editable(source_okr.formulation_id);

  if source_okr.formulation_id <> target_okr.formulation_id
     or source_okr.organization_id <> target_okr.organization_id
     or source_okr.project_id <> target_okr.project_id then
    raise exception 'Os OKRs do alinhamento devem pertencer ao mesmo escopo.'
      using errcode = '22023';
  end if;
  if source_okr.id = target_okr.id then
    raise exception 'Um OKR não pode se alinhar a si próprio.' using errcode = '22023';
  end if;

  select * into package_row
  from public.skpe_okr_packages
  where formulation_id = source_okr.formulation_id;

  if not coalesce(package_row.okr_enabled, false) then
    raise exception 'Os OKRs não estão habilitados para esta Formulação.'
      using errcode = '55000';
  end if;

  if not coalesce(package_row.okr_alignment_enabled, true) then
    raise exception 'O alinhamento entre OKRs está desabilitado na configuração da Formulação.'
      using errcode = '55000';
  end if;

  normalized_type := lower(trim(coalesce(p_relation_type, '')));
  if normalized_type not in (
    'vertical', 'horizontal', 'depends_on', 'supports', 'contributes_to', 'parent_child'
  ) then
    raise exception 'Tipo de alinhamento inválido.' using errcode = '22023';
  end if;

  if normalized_type = 'parent_child'
     and public.skpe_okr_parent_would_create_cycle(
       source_okr.formulation_id,
       source_okr.id,
       target_okr.id,
       p_alignment_id
     ) then
    raise exception 'A relação parent_child criaria ciclo na hierarquia de OKRs.'
      using errcode = '55000';
  end if;

  if p_metadata is not null and jsonb_typeof(p_metadata) <> 'object' then
    raise exception 'Os metadados do alinhamento devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  if p_alignment_id is not null then
    select * into previous_alignment
    from public.skpe_okr_alignments
    where id = p_alignment_id and formulation_id = source_okr.formulation_id
    for update;
  else
    select * into previous_alignment
    from public.skpe_okr_alignments
    where source_okr_id = source_okr.id
      and target_okr_id = target_okr.id
      and relation_type = normalized_type
    for update;
  end if;

  if normalized_type = 'parent_child' then
    select coalesce(jsonb_agg(to_jsonb(existing_parent)), '[]'::jsonb)
    into replaced_parents
    from public.skpe_okr_alignments existing_parent
    where existing_parent.formulation_id = source_okr.formulation_id
      and existing_parent.target_okr_id = target_okr.id
      and existing_parent.relation_type = 'parent_child'
      and existing_parent.status = 'active'
      and existing_parent.source_okr_id <> source_okr.id;

    update public.skpe_okr_alignments
    set status = 'archived', updated_by = auth.uid()
    where formulation_id = source_okr.formulation_id
      and target_okr_id = target_okr.id
      and relation_type = 'parent_child'
      and status = 'active'
      and source_okr_id <> source_okr.id;
  end if;

  if previous_alignment.id is null then
    insert into public.skpe_okr_alignments (
      organization_id, project_id, formulation_id,
      source_okr_id, target_okr_id, relation_type,
      rationale, status, metadata, created_by, updated_by
    ) values (
      source_okr.organization_id, source_okr.project_id, source_okr.formulation_id,
      source_okr.id, target_okr.id, normalized_type,
      nullif(trim(p_rationale), ''), 'active', coalesce(p_metadata, '{}'::jsonb),
      auth.uid(), auth.uid()
    ) returning * into saved_alignment;
    action_code := 'okr_alignment_created';
  else
    update public.skpe_okr_alignments
    set
      source_okr_id = source_okr.id,
      target_okr_id = target_okr.id,
      relation_type = normalized_type,
      rationale = nullif(trim(p_rationale), ''),
      status = 'active',
      metadata = coalesce(p_metadata, metadata),
      updated_by = auth.uid()
    where id = previous_alignment.id
    returning * into saved_alignment;
    action_code := 'okr_alignment_updated';
  end if;

  perform public.skpe_invalidate_okr_package(source_okr.formulation_id, p_change_reason);

  perform public.skpe_record_operational_audit(
    saved_alignment.organization_id, saved_alignment.project_id,
    'okr_alignment', saved_alignment.id, action_code, p_change_reason,
    jsonb_build_object(
      'alignment', case when previous_alignment.id is null then null else to_jsonb(previous_alignment) end,
      'replacedParentAlignments', replaced_parents
    ),
    to_jsonb(saved_alignment)
  );

  return saved_alignment.id;
end;
$$;

create or replace function public.delete_skpe_okr_alignment(
  p_alignment_id uuid,
  p_change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_alignment public.skpe_okr_alignments%rowtype;
  updated_alignment public.skpe_okr_alignments%rowtype;
begin
  perform public.skpe_assert_reason(p_change_reason);

  select * into previous_alignment
  from public.skpe_okr_alignments
  where id = p_alignment_id
  for update;

  if not found then return false; end if;
  perform public.skpe_assert_formulation_editable(previous_alignment.formulation_id);

  update public.skpe_okr_alignments
  set status = 'archived', updated_by = auth.uid()
  where id = p_alignment_id
  returning * into updated_alignment;

  perform public.skpe_invalidate_okr_package(previous_alignment.formulation_id, p_change_reason);

  perform public.skpe_record_operational_audit(
    updated_alignment.organization_id, updated_alignment.project_id,
    'okr_alignment', updated_alignment.id, 'okr_alignment_archived', p_change_reason,
    to_jsonb(previous_alignment), to_jsonb(updated_alignment)
  );

  return true;
end;
$$;

-- ============================================================
-- 8. PRONTIDÃO METODOLÓGICA
-- ============================================================

create or replace function public.get_skpe_okrs_readiness(
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
  package_row public.skpe_okr_packages%rowtype;
  horizon_start date;
  horizon_end date;
  issues jsonb := '[]'::jsonb;
  counts jsonb := '{}'::jsonb;
  content_blocking_count integer := 0;
  total_blocking_count integer := 0;
  enabled boolean := false;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.' using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado à prontidão dos OKRs.' using errcode = '42501';
  end if;

  select * into project_row from public.skpe_projects where id = formulation_row.project_id;
  select * into package_row from public.skpe_okr_packages where formulation_id = p_formulation_id;
  enabled := coalesce(package_row.okr_enabled, false);

  horizon_start := coalesce(
    formulation_row.valid_from,
    case when project_row.planning_horizon_start_year is null then null
      else make_date(project_row.planning_horizon_start_year, 1, 1) end
  );
  horizon_end := coalesce(
    formulation_row.valid_until,
    case when project_row.planning_horizon_end_year is null then null
      else make_date(project_row.planning_horizon_end_year, 12, 31) end
  );

  select jsonb_build_object(
    'cycles', (select count(*) from public.skpe_okr_cycles cycle
      where cycle.formulation_id = p_formulation_id and cycle.status <> 'archived'),
    'activeCycles', (select count(*) from public.skpe_okr_cycles cycle
      where cycle.formulation_id = p_formulation_id and cycle.status = 'active'),
    'okrs', (select count(*) from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'),
    'keyResults', (select count(*) from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'),
    'objectiveLinks', (select count(*) from public.skpe_okr_objectives link
      where link.formulation_id = p_formulation_id),
    'alignments', (select count(*) from public.skpe_okr_alignments alignment
      where alignment.formulation_id = p_formulation_id and alignment.status = 'active'),
    'keyResultsWithOwner', (select count(*) from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and kr.owner_user_id is not null),
    'keyResultsWithLinkedIndicator', (select count(*) from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.metadata ->> 'linkedIndicatorCode', ''))) > 0),
    'keyResultsWithMeasurementHistory', (select count(distinct audit.entity_id)
      from public.skpe_operational_audit audit
      where audit.organization_id = formulation_row.organization_id
        and audit.project_id = formulation_row.project_id
        and audit.entity_type = 'key_result'
        and audit.action_code = 'key_result_progress_updated'
        and (audit.new_data ->> 'formulation_id') = p_formulation_id::text)
  ) into counts;

  if enabled then
    with issue_rows as (
      select 'OKR_PACKAGE_WITHOUT_VALID_CYCLE'::text code, 'blocking'::text severity,
        'content'::text issue_scope,
        'O pacote de OKRs está habilitado, mas não possui ciclo válido.'::text message,
        1::bigint affected_count
      where coalesce(package_row.okr_cycle_required, true)
        and not exists (
          select 1 from public.skpe_okr_cycles cycle
          where cycle.formulation_id = p_formulation_id
            and cycle.status <> 'archived'
            and cycle.period_end >= cycle.period_start
        )

      union all
      select 'CYCLE_OUTSIDE_FORMULATION_HORIZON', 'blocking', 'content',
        'Existem ciclos fora do horizonte da Formulação.', count(*)
      from public.skpe_okr_cycles cycle
      where cycle.formulation_id = p_formulation_id
        and cycle.status <> 'archived'
        and ((horizon_start is not null and cycle.period_start < horizon_start)
          or (horizon_end is not null and cycle.period_end > horizon_end))
      having count(*) > 0

      union all
      select 'CYCLE_OVERLAP_BLOCKED', 'blocking', 'content',
        'Existem ciclos sobrepostos e a política configurada é block.', count(*)
      from public.skpe_okr_cycles a
      join public.skpe_okr_cycles b
        on b.formulation_id = a.formulation_id and b.id > a.id
       and b.status <> 'archived'
       and daterange(a.period_start, a.period_end, '[]')
         && daterange(b.period_start, b.period_end, '[]')
      where a.formulation_id = p_formulation_id
        and a.status <> 'archived'
        and coalesce(package_row.cycle_overlap_policy, 'warn') = 'block'
      having count(*) > 0

      union all
      select 'DUPLICATE_CYCLE_CODE', 'blocking', 'content',
        'Existem códigos de ciclo duplicados, desconsiderando maiúsculas e minúsculas.', count(*)
      from (
        select lower(trim(cycle.code))
        from public.skpe_okr_cycles cycle
        where cycle.formulation_id = p_formulation_id and cycle.status <> 'archived'
        group by lower(trim(cycle.code)) having count(*) > 1
      ) duplicates
      having count(*) > 0

      union all
      select 'OKR_CODE_MISSING', 'blocking', 'content',
        'Existem OKRs sem código.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and length(trim(coalesce(okr.code, ''))) = 0
      having count(*) > 0

      union all
      select 'OKR_TITLE_MISSING', 'blocking', 'content',
        'Existem OKRs sem título.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and length(trim(coalesce(okr.title, ''))) = 0
      having count(*) > 0

      union all
      select 'OKR_DESCRIPTION_OR_RATIONALE_INSUFFICIENT', 'blocking', 'content',
        'Todo OKR deve possuir descrição e racional suficientes.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and (length(trim(coalesce(okr.description, ''))) < 10
          or length(trim(coalesce(okr.metadata ->> 'rationale', ''))) < 10)
      having count(*) > 0

      union all
      select 'OKR_WITHOUT_STRATEGIC_OBJECTIVE', 'blocking', 'content',
        'Todo OKR deve estar vinculado a pelo menos um Objetivo Estratégico.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and not exists (select 1 from public.skpe_okr_objectives link where link.okr_id = okr.id)
      having count(*) > 0

      union all
      select 'OKR_OBJECTIVE_SCOPE_MISMATCH', 'blocking', 'content',
        'Existem vínculos de OKR com Objetivo Estratégico de outro escopo.', count(*)
      from public.skpe_okr_objectives link
      left join public.skpe_okrs okr on okr.id = link.okr_id
      left join public.skpe_strategic_objectives objective
        on objective.id = link.strategic_objective_id
      where link.formulation_id = p_formulation_id
        and (okr.id is null or objective.id is null
          or okr.formulation_id <> p_formulation_id
          or objective.formulation_id <> p_formulation_id
          or link.organization_id <> formulation_row.organization_id
          or link.project_id <> formulation_row.project_id)
      having count(*) > 0

      union all
      select 'OBJECTIVE_WITHOUT_OKR', 'blocking', 'content',
        'A configuração exige ao menos um OKR por Objetivo Estratégico ativo.', count(*)
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = p_formulation_id
        and objective.status = 'active'
        and coalesce(package_row.okr_required_for_all_objectives, false)
        and not exists (
          select 1 from public.skpe_okr_objectives link
          join public.skpe_okrs okr on okr.id = link.okr_id
          where link.strategic_objective_id = objective.id and okr.status <> 'cancelled'
        )
      having count(*) > 0

      union all
      select 'OKR_OWNER_REQUIRED', 'blocking', 'content',
        'Existem OKRs sem responsável, embora a configuração o exija.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and coalesce(package_row.okr_owner_required, false)
        and okr.owner_user_id is null
      having count(*) > 0

      union all
      select 'OKR_WITHOUT_KEY_RESULT', 'blocking', 'content',
        'Todo OKR deve possuir Resultado-Chave ativo.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and not exists (
          select 1 from public.skpe_key_results kr
          where kr.okr_id = okr.id and kr.status <> 'cancelled'
        )
      having count(*) > 0

      union all
      select 'KEY_RESULTS_BELOW_MINIMUM', 'blocking', 'content',
        'Existem OKRs com quantidade de KRs abaixo do mínimo configurado.', count(*)
      from (
        select okr.id
        from public.skpe_okrs okr
        left join public.skpe_key_results kr
          on kr.okr_id = okr.id and kr.status <> 'cancelled'
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by okr.id
        having count(kr.id) < coalesce(package_row.minimum_key_results_per_okr, 3)
      ) insufficient
      having count(*) > 0

      union all
      select 'KEY_RESULTS_ABOVE_MAXIMUM', 'blocking', 'content',
        'Existem OKRs com quantidade de KRs acima do máximo configurado.', count(*)
      from (
        select okr.id
        from public.skpe_okrs okr
        join public.skpe_key_results kr
          on kr.okr_id = okr.id and kr.status <> 'cancelled'
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by okr.id
        having count(kr.id) > coalesce(package_row.maximum_key_results_per_okr, 5)
      ) excess
      having count(*) > 0

      union all
      select 'KEY_RESULT_CODE_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem código.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.code, ''))) = 0
      having count(*) > 0

      union all
      select 'KEY_RESULT_NOT_MEASURABLE', 'blocking', 'content',
        'Existem Resultados-Chave sem definição mensurável ou valor-alvo.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and (length(trim(coalesce(kr.description, ''))) < 10 or kr.target_value is null)
      having count(*) > 0

      union all
      select 'KEY_RESULT_UNIT_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem unidade de medida.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.unit, ''))) = 0
      having count(*) > 0

      union all
      select 'KEY_RESULT_POLARITY_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem polaridade válida.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and lower(coalesce(kr.metadata ->> 'polarity', '')) not in (
          'higher_is_better', 'lower_is_better', 'target_is_better', 'range_is_better'
        )
      having count(*) > 0

      union all
      select 'KEY_RESULT_BASELINE_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem linha de base, embora exigida.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and coalesce(package_row.key_result_baseline_required, true)
        and kr.baseline_value is null
      having count(*) > 0

      union all
      select 'KEY_RESULT_DATA_SOURCE_MISSING', 'blocking', 'content',
        'Existem Resultados-Chave sem fonte de dados.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.metadata ->> 'dataSource', ''))) = 0
      having count(*) > 0

      union all
      select 'KEY_RESULT_OUTSIDE_CYCLE', 'blocking', 'content',
        'Existem Resultados-Chave fora do período de seu ciclo.', count(*)
      from public.skpe_key_results kr
      join public.skpe_okrs okr on okr.id = kr.okr_id
      join public.skpe_okr_cycles cycle on cycle.id = okr.okr_cycle_id
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and (kr.period_start < cycle.period_start or kr.period_end > cycle.period_end)
      having count(*) > 0

      union all
      select 'KEY_RESULT_TARGET_POLARITY_MISMATCH', 'blocking', 'content',
        'Existem alvos incompatíveis com polaridade, linha de base ou faixa.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and kr.baseline_value is not null and kr.target_value is not null
        and (
          (kr.metadata ->> 'polarity' = 'higher_is_better' and kr.target_value < kr.baseline_value)
          or (kr.metadata ->> 'polarity' = 'lower_is_better' and kr.target_value > kr.baseline_value)
          or (kr.metadata ->> 'polarity' = 'range_is_better' and (
            nullif(kr.metadata ->> 'rangeLower', '')::numeric is null
            or nullif(kr.metadata ->> 'rangeUpper', '')::numeric is null
            or nullif(kr.metadata ->> 'rangeLower', '')::numeric
              > nullif(kr.metadata ->> 'rangeUpper', '')::numeric
            or kr.target_value < nullif(kr.metadata ->> 'rangeLower', '')::numeric
            or kr.target_value > nullif(kr.metadata ->> 'rangeUpper', '')::numeric
          ))
        )
      having count(*) > 0

      union all
      select 'KEY_RESULT_SCOPE_MISMATCH', 'blocking', 'content',
        'Existem Resultados-Chave vinculados a OKR, Objetivo ou Formulação de outro escopo.', count(*)
      from public.skpe_key_results kr
      left join public.skpe_okrs okr on okr.id = kr.okr_id
      left join public.skpe_strategic_objectives objective
        on objective.id = kr.strategic_objective_id
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and (okr.id is null or objective.id is null
          or okr.formulation_id <> p_formulation_id
          or objective.formulation_id <> p_formulation_id
          or kr.organization_id <> formulation_row.organization_id
          or kr.project_id <> formulation_row.project_id)
      having count(*) > 0

      union all
      select 'LINKED_INDICATOR_SCOPE_MISMATCH', 'blocking', 'content',
        'Existem KRs com código de Indicador que não resolve na mesma Formulação.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.metadata ->> 'linkedIndicatorCode', ''))) > 0
        and not exists (
          select 1 from public.skpe_indicators indicator
          where indicator.formulation_id = p_formulation_id
            and indicator.code = kr.metadata ->> 'linkedIndicatorCode'
            and indicator.status <> 'archived'
        )
      having count(*) > 0

      union all
      select 'KEY_RESULT_OWNER_REQUIRED', 'blocking', 'content',
        'Existem KRs sem responsável, embora a configuração o exija.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and coalesce(package_row.key_result_owner_required, false)
        and kr.owner_user_id is null
      having count(*) > 0

      union all
      select 'KEY_RESULT_WEIGHTS_INVALID', 'blocking', 'content',
        'Quando pesos são obrigatórios, todos os KRs devem ter peso e somar 100% por OKR.', count(*)
      from (
        select okr.id
        from public.skpe_okrs okr
        join public.skpe_key_results kr
          on kr.okr_id = okr.id and kr.status <> 'cancelled'
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
          and coalesce(package_row.key_result_weights_required, false)
        group by okr.id
        having count(*) filter (where kr.contribution_weight is null) > 0
          or round(coalesce(sum(kr.contribution_weight), 0), 2) <> 100.00
      ) invalid_weights
      having count(*) > 0

      union all
      select 'DUPLICATE_OKR_CODE', 'blocking', 'content',
        'Existem códigos de OKR duplicados no mesmo ciclo.', count(*)
      from (
        select okr.okr_cycle_id, lower(trim(okr.code))
        from public.skpe_okrs okr
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by okr.okr_cycle_id, lower(trim(okr.code)) having count(*) > 1
      ) duplicates
      having count(*) > 0

      union all
      select 'DUPLICATE_KEY_RESULT', 'blocking', 'content',
        'Existem Resultados-Chave duplicados por código ou nome dentro do mesmo OKR.', count(*)
      from (
        select kr.okr_id, lower(trim(kr.code)) key_value
        from public.skpe_key_results kr
        where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        group by kr.okr_id, lower(trim(kr.code)) having count(*) > 1
        union all
        select kr.okr_id, lower(trim(kr.name)) key_value
        from public.skpe_key_results kr
        where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        group by kr.okr_id, lower(trim(kr.name)) having count(*) > 1
      ) duplicates
      having count(*) > 0

      union all
      select 'OKR_PACKAGE_NOT_VALIDATED', 'blocking', 'formulation',
        'O pacote FE-06 deve estar validado antes do avanço da Formulação.', 1
      where package_row.id is null or package_row.status <> 'validated'

      union all
      select 'OKR_WITHOUT_OWNER', 'recommendation', 'content',
        'Recomenda-se indicar responsável para cada OKR.', count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        and okr.owner_user_id is null and not coalesce(package_row.okr_owner_required, false)
      having count(*) > 0

      union all
      select 'KEY_RESULT_WITHOUT_OWNER', 'recommendation', 'content',
        'Recomenda-se indicar responsável para cada Resultado-Chave.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and kr.owner_user_id is null
        and coalesce(package_row.key_result_owner_recommended, true)
        and not coalesce(package_row.key_result_owner_required, false)
      having count(*) > 0

      union all
      select 'KEY_RESULT_WITHOUT_LINKED_INDICATOR', 'recommendation', 'content',
        'Quando aplicável, vincule o KR ao Indicador Estratégico para explicitar a contribuição.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and length(trim(coalesce(kr.metadata ->> 'linkedIndicatorCode', ''))) = 0
      having count(*) > 0

      union all
      select 'KEY_RESULT_COLLECTION_NOT_AUTOMATABLE', 'recommendation', 'content',
        'Existem KRs sem método de coleta automatizável ou sem avaliação de automação.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and lower(coalesce(kr.metadata ->> 'collectionAutomatable', 'false')) <> 'true'
      having count(*) > 0

      union all
      select 'KEY_RESULT_FREQUENCY_INCOMPATIBLE', 'recommendation', 'content',
        'Revise KRs cuja frequência de medição é muito baixa para a duração do ciclo.', count(*)
      from public.skpe_key_results kr
      join public.skpe_okrs okr on okr.id = kr.okr_id
      join public.skpe_okr_cycles cycle on cycle.id = okr.okr_cycle_id
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and (
          (cycle.period_end - cycle.period_start < 180
            and kr.metadata ->> 'measurementFrequency' in ('semiannual', 'annual'))
          or (cycle.period_end - cycle.period_start < 90
            and kr.metadata ->> 'measurementFrequency' = 'quarterly')
        )
      having count(*) > 0

      union all
      select 'OKR_WITH_ONLY_ONE_KEY_RESULT', 'recommendation', 'content',
        'OKR com apenas um KR pode não representar adequadamente o resultado esperado.', count(*)
      from (
        select okr.id
        from public.skpe_okrs okr
        join public.skpe_key_results kr on kr.okr_id = okr.id and kr.status <> 'cancelled'
        where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by okr.id having count(*) = 1
      ) single_kr
      having count(*) > 0

      union all
      select 'OKR_CONCENTRATION_BY_OBJECTIVE', 'recommendation', 'content',
        'Mais de 60% dos OKRs estão concentrados em um único Objetivo Estratégico.', count(*)
      from (
        select link.strategic_objective_id
        from public.skpe_okr_objectives link
        join public.skpe_okrs okr on okr.id = link.okr_id
        where link.formulation_id = p_formulation_id and okr.status <> 'cancelled'
        group by link.strategic_objective_id
        having count(distinct link.okr_id) * 100.0
          / nullif((select count(*) from public.skpe_okrs x
            where x.formulation_id = p_formulation_id and x.status <> 'cancelled'), 0) > 60
      ) concentrated
      having count(*) > 0

      union all
      select 'OKR_ALIGNMENT_MISSING', 'recommendation', 'content',
        'A carteira possui múltiplos OKRs, mas não há alinhamento registrado.', 1
      where coalesce(package_row.okr_alignment_enabled, true)
        and (select count(*) from public.skpe_okrs okr
          where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled') > 1
        and not exists (select 1 from public.skpe_okr_alignments alignment
          where alignment.formulation_id = p_formulation_id and alignment.status = 'active')

      union all
      select 'KEY_RESULT_WEIGHTS_MISSING', 'recommendation', 'content',
        'A ponderação dos KRs pode melhorar a leitura do progresso do OKR.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and not coalesce(package_row.key_result_weights_required, false)
        and kr.contribution_weight is null
      having count(*) > 0

      union all
      select 'KEY_RESULT_ACTIVITY_LIKE_WORDING', 'recommendation', 'content',
        'A redação de alguns KRs começa com verbo típico de iniciativa; revise o foco no resultado mensurável.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and lower(trim(coalesce(kr.name, ''))) ~
          '^(implantar|criar|realizar|desenvolver|contratar|executar|promover)([[:space:]]|$)'
      having count(*) > 0

      union all
      select 'KEY_RESULT_STALE_MEASUREMENT', 'recommendation', 'content',
        'Existem KRs ativos sem atualização recente de valor atual.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status in ('active', 'at_risk')
        and (
          kr.current_value is null
          or not (kr.metadata ? 'lastMeasurementAt')
          or nullif(kr.metadata ->> 'lastMeasurementAt', '')::timestamptz
            < timezone('utc', now()) - interval '90 days'
        )
      having count(*) > 0

      union all
      select 'MANUAL_PROGRESS_DIVERGENCE', 'recommendation', 'content',
        'Existem substituições manuais com divergência superior a 10 pontos do cálculo automático.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
        and abs(coalesce(nullif(kr.metadata ->> 'progressDivergence', '')::numeric, 0)) > 10
      having count(*) > 0

      union all
      select 'KEY_RESULT_WITHOUT_PROGRESS_HISTORY', 'recommendation', 'content',
        'Existem KRs ativos sem histórico auditável de acompanhamento.', count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = p_formulation_id and kr.status in ('active', 'at_risk')
        and not exists (
          select 1 from public.skpe_operational_audit audit
          where audit.entity_type = 'key_result'
            and audit.entity_id = kr.id
            and audit.action_code = 'key_result_progress_updated'
        )
      having count(*) > 0

      union all
      select 'CYCLE_OVERLAP_WARNING', 'recommendation', 'content',
        'Existem ciclos sobrepostos; confirme se a sobreposição é intencional.', count(*)
      from public.skpe_okr_cycles a
      join public.skpe_okr_cycles b
        on b.formulation_id = a.formulation_id and b.id > a.id
       and b.status <> 'archived'
       and daterange(a.period_start, a.period_end, '[]')
         && daterange(b.period_start, b.period_end, '[]')
      where a.formulation_id = p_formulation_id
        and a.status <> 'archived'
        and coalesce(package_row.cycle_overlap_policy, 'warn') = 'warn'
      having count(*) > 0
    )
    select
      coalesce(jsonb_agg(jsonb_build_object(
        'code', code,
        'severity', severity,
        'scope', issue_scope,
        'message', message,
        'affectedCount', affected_count
      ) order by
        case severity when 'blocking' then 1 else 2 end,
        case issue_scope when 'content' then 1 else 2 end,
        code
      ), '[]'::jsonb),
      count(*) filter (where severity = 'blocking' and issue_scope = 'content')::integer,
      count(*) filter (where severity = 'blocking')::integer
    into issues, content_blocking_count, total_blocking_count
    from issue_rows;
  end if;

  return jsonb_build_object(
    'formulationId', formulation_row.id,
    'okrPackageId', package_row.id,
    'okrEnabled', enabled,
    'applicability', case when enabled then 'applicable' else 'not_applicable' end,
    'packageStatus', case
      when package_row.id is null then 'not_created'
      else package_row.status
    end,
    'readyForValidation', case when enabled then content_blocking_count = 0 else true end,
    'validated', case when enabled then coalesce(package_row.status = 'validated', false) else true end,
    'readyForFormulation', case when enabled then
      content_blocking_count = 0 and coalesce(package_row.status = 'validated', false)
      else true end,
    'contentBlockingIssueCount', content_blocking_count,
    'blockingIssueCount', total_blocking_count,
    'planningHorizon', jsonb_build_object('startDate', horizon_start, 'endDate', horizon_end),
    'counts', counts,
    'issues', issues,
    'methodologyRules', jsonb_build_object(
      'okrEnabled', enabled,
      'okrRequiredForAllObjectives', coalesce(package_row.okr_required_for_all_objectives, false),
      'okrCycleRequired', coalesce(package_row.okr_cycle_required, true),
      'minimumKeyResultsPerOkr', coalesce(package_row.minimum_key_results_per_okr, 3),
      'maximumKeyResultsPerOkr', coalesce(package_row.maximum_key_results_per_okr, 5),
      'keyResultBaselineRequired', coalesce(package_row.key_result_baseline_required, true),
      'okrOwnerRequired', coalesce(package_row.okr_owner_required, false),
      'keyResultOwnerRequired', coalesce(package_row.key_result_owner_required, false),
      'keyResultOwnerRecommended', coalesce(package_row.key_result_owner_recommended, true),
      'keyResultWeightsRequired', coalesce(package_row.key_result_weights_required, false),
      'okrAlignmentEnabled', coalesce(package_row.okr_alignment_enabled, true),
      'automaticProgressCalculation', coalesce(package_row.automatic_progress_calculation, true),
      'allowManualProgressOverride', coalesce(package_row.allow_manual_progress_override, false),
      'cycleOverlapPolicy', coalesce(package_row.cycle_overlap_policy, 'warn'),
      'cloneProgressPolicy', coalesce(package_row.clone_progress_policy, 'reset_to_baseline'),
      'initiativeRequiredInFe06', false
    )
  );
end;
$$;

-- ============================================================
-- 9. FLUXO DE VALIDAÇÃO DO PACOTE
-- ============================================================

create or replace function public.transition_skpe_okr_package(
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
  package_id uuid;
  previous_package public.skpe_okr_packages%rowtype;
  updated_package public.skpe_okr_packages%rowtype;
  formulation_row public.skpe_strategic_formulations%rowtype;
  readiness jsonb;
  normalized_action text;
begin
  perform public.skpe_assert_reason(p_change_reason);
  normalized_action := lower(trim(coalesce(p_transition_action, '')));

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then raise exception 'Formulação não encontrada.' using errcode = '22023'; end if;

  select * into previous_package
  from public.skpe_okr_packages
  where formulation_id = p_formulation_id
  for update;

  if previous_package.id is null then
    if normalized_action = 'submit_validation' then
      package_id := public.ensure_skpe_okr_package(p_formulation_id);
      select * into previous_package
      from public.skpe_okr_packages
      where id = package_id
      for update;
    else
      raise exception 'O pacote FE-06 ainda não foi criado.' using errcode = '55000';
    end if;
  else
    package_id := previous_package.id;
  end if;

  if not previous_package.okr_enabled then
    raise exception 'O pacote está formalmente não aplicável porque OKRs estão desabilitados.'
      using errcode = '55000';
  end if;

  if normalized_action = 'submit_validation' then
    perform public.skpe_assert_formulation_editable(p_formulation_id);
    readiness := public.get_skpe_okrs_readiness(p_formulation_id);
    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'A FE-06 possui pendências bloqueantes de conteúdo.'
        using errcode = '55000', detail = readiness::text;
    end if;
    if previous_package.status <> 'in_elaboration' then
      raise exception 'Somente pacote em elaboração pode ser submetido.' using errcode = '55000';
    end if;

    update public.skpe_okr_packages
    set
      status = 'pending_validation',
      validation_notes = null,
      submitted_for_validation_at = timezone('utc', now()),
      submitted_for_validation_by = auth.uid(),
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where id = package_id
    returning * into updated_package;

    update public.skpe_okrs
    set validation_status = 'pending_validation', updated_by = auth.uid()
    where formulation_id = p_formulation_id and status <> 'cancelled';
    update public.skpe_key_results
    set validation_status = 'pending_validation', updated_by = auth.uid()
    where formulation_id = p_formulation_id and status <> 'cancelled';

  elsif normalized_action = 'validate' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para validar o pacote FE-06.' using errcode = '42501';
    end if;
    if formulation_row.status not in ('draft', 'in_elaboration') then
      raise exception 'A validação do pacote ocorre enquanto a Formulação ainda está em elaboração.'
        using errcode = '55000';
    end if;
    if previous_package.status <> 'pending_validation' then
      raise exception 'Somente pacote pendente de validação pode ser validado.' using errcode = '55000';
    end if;
    readiness := public.get_skpe_okrs_readiness(p_formulation_id);
    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'A FE-06 possui pendências bloqueantes de conteúdo.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_okr_packages
    set
      status = 'validated',
      validation_notes = nullif(trim(p_decision_notes), ''),
      validated_at = timezone('utc', now()),
      validated_by = auth.uid(),
      updated_by = auth.uid()
    where id = package_id
    returning * into updated_package;

    update public.skpe_okrs
    set validation_status = 'validated', updated_by = auth.uid()
    where formulation_id = p_formulation_id and status <> 'cancelled';
    update public.skpe_key_results
    set validation_status = 'validated', updated_by = auth.uid()
    where formulation_id = p_formulation_id and status <> 'cancelled';

  elsif normalized_action = 'return_for_adjustments' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para devolver o pacote FE-06.' using errcode = '42501';
    end if;
    if previous_package.status not in ('pending_validation', 'validated') then
      raise exception 'Somente pacote pendente ou validado pode ser devolvido.' using errcode = '55000';
    end if;

    update public.skpe_okr_packages
    set
      status = 'in_elaboration',
      validation_notes = nullif(trim(p_decision_notes), ''),
      submitted_for_validation_at = null,
      submitted_for_validation_by = null,
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where id = package_id
    returning * into updated_package;

    update public.skpe_okrs
    set validation_status = 'draft', updated_by = auth.uid()
    where formulation_id = p_formulation_id and status <> 'cancelled';
    update public.skpe_key_results
    set validation_status = 'draft', updated_by = auth.uid()
    where formulation_id = p_formulation_id and status <> 'cancelled';

  else
    raise exception 'Transição inválida. Use submit_validation, validate ou return_for_adjustments.'
      using errcode = '22023';
  end if;

  perform public.skpe_record_operational_audit(
    updated_package.organization_id, updated_package.project_id,
    'okr_package', updated_package.id,
    'okr_package_' || normalized_action, p_change_reason,
    to_jsonb(previous_package), to_jsonb(updated_package)
  );

  return jsonb_build_object(
    'formulationId', p_formulation_id,
    'okrPackageId', updated_package.id,
    'previousStatus', previous_package.status,
    'currentStatus', updated_package.status,
    'transitionAction', normalized_action
  );
end;
$$;

-- ============================================================
-- 10. BLOQUEIO INTEGRADO DA FORMULAÇÃO
-- ============================================================

create or replace function public.skpe_guard_formulation_okrs_ready()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  readiness jsonb;
begin
  if new.status is not distinct from old.status then return new; end if;

  if new.status not in ('pending_validation', 'validated', 'pending_approval', 'approved') then
    return new;
  end if;

  readiness := public.get_skpe_okrs_readiness(new.id);

  if coalesce((readiness ->> 'okrEnabled')::boolean, false) then
    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'A Formulação não pode avançar: a FE-06 possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;
    if not coalesce((readiness ->> 'readyForFormulation')::boolean, false) then
      raise exception 'A Formulação não pode avançar: valide o pacote de OKRs e Resultados-Chave.'
        using errcode = '55000', detail = readiness::text;
    end if;
  end if;

  return new;
end;
$$;

comment on function public.skpe_guard_formulation_okrs_ready() is
  'Impede avanço quando OKRs estão habilitados e o pacote FE-06 está incompleto ou não validado; reconhece formalmente a não aplicabilidade.';

drop trigger if exists skpe_strategic_formulations_guard_okrs_ready
  on public.skpe_strategic_formulations;
create trigger skpe_strategic_formulations_guard_okrs_ready
before update of status on public.skpe_strategic_formulations
for each row execute function public.skpe_guard_formulation_okrs_ready();

-- ============================================================
-- 11. CONSULTA CONSOLIDADA E AUDITORIA
-- ============================================================

create or replace function public.get_skpe_okrs_package(
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
  package_row public.skpe_okr_packages%rowtype;
  readiness jsonb;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then raise exception 'Formulação não encontrada.' using errcode = '22023'; end if;
  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado à consulta consolidada da FE-06.' using errcode = '42501';
  end if;

  select * into package_row
  from public.skpe_okr_packages
  where formulation_id = p_formulation_id;

  readiness := public.get_skpe_okrs_readiness(p_formulation_id);

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
    'package', case when package_row.id is null then null else to_jsonb(package_row) end,
    'cycles', coalesce((
      select jsonb_agg(to_jsonb(cycle) order by cycle.period_start, cycle.code)
      from public.skpe_okr_cycles cycle
      where cycle.formulation_id = p_formulation_id and cycle.status <> 'archived'
    ), '[]'::jsonb),
    'strategicObjectives', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', objective.id,
        'code', objective.code,
        'title', objective.title,
        'perspectiveId', objective.perspective_id,
        'strategicThemeId', objective.strategic_theme_id,
        'status', objective.status
      ) order by objective.code)
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = p_formulation_id and objective.status = 'active'
    ), '[]'::jsonb),
    'okrs', coalesce((
      select jsonb_agg(to_jsonb(okr) order by cycle.period_start, okr.display_order, okr.code)
      from public.skpe_okrs okr
      join public.skpe_okr_cycles cycle on cycle.id = okr.okr_cycle_id
      where okr.formulation_id = p_formulation_id and okr.status <> 'cancelled'
    ), '[]'::jsonb),
    'okrObjectiveLinks', coalesce((
      select jsonb_agg(to_jsonb(link) order by link.okr_id, link.is_primary desc)
      from public.skpe_okr_objectives link
      where link.formulation_id = p_formulation_id
    ), '[]'::jsonb),
    'keyResults', coalesce((
      select jsonb_agg(
        to_jsonb(kr) || jsonb_build_object(
          'resolvedLinkedIndicator', case when indicator.id is null then null else
            jsonb_build_object(
              'id', indicator.id,
              'code', indicator.code,
              'name', indicator.name,
              'scope', indicator.indicator_scope,
              'status', indicator.status
            ) end
        )
        order by kr.okr_id, kr.code
      )
      from public.skpe_key_results kr
      left join public.skpe_indicators indicator
        on indicator.formulation_id = p_formulation_id
       and indicator.code = kr.metadata ->> 'linkedIndicatorCode'
       and indicator.status <> 'archived'
      where kr.formulation_id = p_formulation_id and kr.status <> 'cancelled'
    ), '[]'::jsonb),
    'alignments', coalesce((
      select jsonb_agg(to_jsonb(alignment) order by alignment.relation_type, alignment.created_at)
      from public.skpe_okr_alignments alignment
      where alignment.formulation_id = p_formulation_id and alignment.status = 'active'
    ), '[]'::jsonb),
    'initiativeReferences', coalesce((
      select jsonb_agg(jsonb_build_object(
        'initiativeId', link.initiative_id,
        'keyResultId', link.key_result_id,
        'contributionType', link.contribution_type,
        'contributionWeight', link.contribution_weight,
        'notes', link.notes
      ) order by link.key_result_id, link.initiative_id)
      from public.skpe_initiative_key_results link
      join public.skpe_key_results kr on kr.id = link.key_result_id
      where kr.formulation_id = p_formulation_id
    ), '[]'::jsonb),
    'validationHistory', coalesce((
      select jsonb_agg(jsonb_build_object(
        'auditId', audit.id,
        'actionCode', audit.action_code,
        'reason', audit.reason,
        'occurredAt', audit.occurred_at,
        'actorUserId', audit.actor_user_id,
        'previousData', audit.previous_data,
        'newData', audit.new_data
      ) order by audit.occurred_at desc)
      from public.skpe_operational_audit audit
      where audit.organization_id = formulation_row.organization_id
        and audit.project_id = formulation_row.project_id
        and audit.entity_type = 'okr_package'
        and (audit.previous_data ->> 'formulation_id' = p_formulation_id::text
          or audit.new_data ->> 'formulation_id' = p_formulation_id::text)
    ), '[]'::jsonb),
    'readiness', readiness
  );
end;
$$;

create or replace function public.get_skpe_okrs_audit(
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
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id = p_formulation_id;

  if not found then raise exception 'Formulação não encontrada.' using errcode = '22023'; end if;
  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado ao histórico da FE-06.' using errcode = '42501';
  end if;

  return query
  select
    audit.id, audit.entity_type, audit.entity_id, audit.action_code,
    audit.reason, audit.previous_data, audit.new_data,
    audit.occurred_at, audit.actor_user_id
  from public.skpe_operational_audit audit
  where audit.organization_id = formulation_row.organization_id
    and audit.project_id = formulation_row.project_id
    and audit.entity_type in (
      'okr_package', 'okr_cycle', 'okr', 'okr_objective_link',
      'key_result', 'okr_alignment'
    )
    and (
      audit.previous_data ->> 'formulation_id' = p_formulation_id::text
      or audit.new_data ->> 'formulation_id' = p_formulation_id::text
      or exists (
        select 1 from public.skpe_okrs okr
        where okr.formulation_id = p_formulation_id
          and okr.id = audit.entity_id
      )
      or exists (
        select 1 from public.skpe_key_results kr
        where kr.formulation_id = p_formulation_id
          and kr.id = audit.entity_id
      )
      or exists (
        select 1 from public.skpe_okr_cycles cycle
        where cycle.formulation_id = p_formulation_id
          and cycle.id = audit.entity_id
      )
    )
  order by audit.occurred_at desc, audit.id desc;
end;
$$;

-- ============================================================
-- 12. RLS, PRIVILÉGIOS E SUPERFÍCIE PÚBLICA
-- ============================================================

-- Auditoria permanece legível para quem pode consultar a Formulação.
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
on table public.skpe_okr_packages,
         public.skpe_okr_cycles,
         public.skpe_okrs,
         public.skpe_okr_objectives,
         public.skpe_key_results,
         public.skpe_okr_alignments
from public, anon, authenticated;

revoke all on table public.skpe_okr_packages, public.skpe_okr_alignments from anon;

grant select
on table public.skpe_okr_packages,
         public.skpe_okr_cycles,
         public.skpe_okrs,
         public.skpe_okr_objectives,
         public.skpe_key_results,
         public.skpe_okr_alignments
  to authenticated, service_role;

grant insert, update, delete
on table public.skpe_okr_packages,
         public.skpe_okr_cycles,
         public.skpe_okrs,
         public.skpe_okr_objectives,
         public.skpe_key_results,
         public.skpe_okr_alignments
  to service_role;

-- Funções internas: sem execução por usuários comuns.
revoke all on function public.ensure_skpe_okr_package(uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_invalidate_okr_package(uuid, text)
  from public, anon, authenticated;
revoke all on function public.skpe_assert_valid_responsible_area(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_calculate_key_result_progress(text, numeric, numeric, numeric, numeric, numeric)
  from public, anon, authenticated;
revoke all on function public.skpe_okr_parent_would_create_cycle(uuid, uuid, uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_recalculate_okr_progress(uuid, text)
  from public, anon, authenticated;
revoke all on function public.skpe_guard_okr_operational_content()
  from public, anon, authenticated;
revoke all on function public.skpe_guard_formulation_okrs_ready()
  from public, anon, authenticated;

-- Funções públicas: sem execução anônima/public e com execução autenticada.
revoke all on function public.configure_skpe_okr_package(
  uuid, boolean, boolean, boolean, integer, integer, boolean, boolean,
  boolean, boolean, boolean, boolean, boolean, boolean, text, text, jsonb, text
) from public, anon;
revoke all on function public.upsert_skpe_okr_cycle(
  uuid, text, text, text, text, date, date, integer, uuid, text, uuid, jsonb, text
) from public, anon;
revoke all on function public.close_skpe_okr_cycle(uuid, text, text) from public, anon;
revoke all on function public.reopen_skpe_okr_cycle(uuid, text, text) from public, anon;
revoke all on function public.upsert_skpe_okr(
  uuid, uuid, text, text, text, text, uuid, uuid, text, text, integer,
  uuid, uuid, jsonb, text
) from public, anon;
revoke all on function public.archive_skpe_okr(uuid, text) from public, anon;
revoke all on function public.link_skpe_okr_objective(
  uuid, uuid, numeric, boolean, text, text
) from public, anon;
revoke all on function public.unlink_skpe_okr_objective(uuid, uuid, text) from public, anon;
revoke all on function public.upsert_skpe_key_result(
  uuid, text, text, text, numeric, numeric, numeric, text, text, text, text,
  text, text, date, date, uuid, uuid, numeric, uuid, numeric, numeric,
  boolean, text, uuid, uuid, jsonb, text
) from public, anon;
revoke all on function public.archive_skpe_key_result(uuid, text) from public, anon;
revoke all on function public.update_skpe_key_result_progress(
  uuid, numeric, text, numeric, text, text
) from public, anon;
revoke all on function public.upsert_skpe_okr_alignment(
  uuid, uuid, text, text, uuid, jsonb, text
) from public, anon;
revoke all on function public.delete_skpe_okr_alignment(uuid, text) from public, anon;
revoke all on function public.get_skpe_okrs_readiness(uuid) from public, anon;
revoke all on function public.transition_skpe_okr_package(uuid, text, text, text)
  from public, anon;
revoke all on function public.get_skpe_okrs_package(uuid) from public, anon;
revoke all on function public.get_skpe_okrs_audit(uuid) from public, anon;

grant execute on function public.configure_skpe_okr_package(
  uuid, boolean, boolean, boolean, integer, integer, boolean, boolean,
  boolean, boolean, boolean, boolean, boolean, boolean, text, text, jsonb, text
) to authenticated, service_role;
grant execute on function public.upsert_skpe_okr_cycle(
  uuid, text, text, text, text, date, date, integer, uuid, text, uuid, jsonb, text
) to authenticated, service_role;
grant execute on function public.close_skpe_okr_cycle(uuid, text, text)
  to authenticated, service_role;
grant execute on function public.reopen_skpe_okr_cycle(uuid, text, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_okr(
  uuid, uuid, text, text, text, text, uuid, uuid, text, text, integer,
  uuid, uuid, jsonb, text
) to authenticated, service_role;
grant execute on function public.archive_skpe_okr(uuid, text)
  to authenticated, service_role;
grant execute on function public.link_skpe_okr_objective(
  uuid, uuid, numeric, boolean, text, text
) to authenticated, service_role;
grant execute on function public.unlink_skpe_okr_objective(uuid, uuid, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_key_result(
  uuid, text, text, text, numeric, numeric, numeric, text, text, text, text,
  text, text, date, date, uuid, uuid, numeric, uuid, numeric, numeric,
  boolean, text, uuid, uuid, jsonb, text
) to authenticated, service_role;
grant execute on function public.archive_skpe_key_result(uuid, text)
  to authenticated, service_role;
grant execute on function public.update_skpe_key_result_progress(
  uuid, numeric, text, numeric, text, text
) to authenticated, service_role;
grant execute on function public.upsert_skpe_okr_alignment(
  uuid, uuid, text, text, uuid, jsonb, text
) to authenticated, service_role;
grant execute on function public.delete_skpe_okr_alignment(uuid, text)
  to authenticated, service_role;
grant execute on function public.get_skpe_okrs_readiness(uuid)
  to authenticated, service_role;
grant execute on function public.transition_skpe_okr_package(uuid, text, text, text)
  to authenticated, service_role;
grant execute on function public.get_skpe_okrs_package(uuid)
  to authenticated, service_role;
grant execute on function public.get_skpe_okrs_audit(uuid)
  to authenticated, service_role;

grant execute on function public.ensure_skpe_okr_package(uuid) to service_role;
grant execute on function public.skpe_invalidate_okr_package(uuid, text) to service_role;
grant execute on function public.skpe_assert_valid_responsible_area(uuid, uuid) to service_role;
grant execute on function public.skpe_calculate_key_result_progress(text, numeric, numeric, numeric, numeric, numeric)
  to service_role;
grant execute on function public.skpe_okr_parent_would_create_cycle(uuid, uuid, uuid, uuid)
  to service_role;
grant execute on function public.skpe_recalculate_okr_progress(uuid, text) to service_role;
grant execute on function public.skpe_guard_okr_operational_content() to service_role;
grant execute on function public.skpe_guard_formulation_okrs_ready() to service_role;

commit;
