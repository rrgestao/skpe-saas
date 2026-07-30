-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-04 — Temas, Perspectivas e Objetivos Estratégicos
--
-- Escopo:
-- 1. Pacote operacional do Mapa Estratégico.
-- 2. Operações auditadas de Temas Estratégicos.
-- 3. Operações auditadas de Perspectivas Estratégicas.
-- 4. Operações auditadas de Objetivos Estratégicos.
-- 5. Relações causais direcionais e política configurável de ciclos.
-- 6. Prontidão metodológica específica da FE-04.
-- 7. Validação formal do pacote e bloqueio integrado da Formulação.
-- 8. Consulta consolidada para futura representação visual.
--
-- Princípios de segurança:
-- - leitura por RLS;
-- - escrita somente por RPCs SECURITY DEFINER;
-- - justificativa obrigatória;
-- - auditoria antes/depois;
-- - nenhuma escrita direta para authenticated.
-- ============================================================

begin;

-- ============================================================
-- 1. PACOTE DE GOVERNANÇA DO MAPA ESTRATÉGICO
-- ============================================================

create table if not exists public.skpe_strategic_map_packages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  status text not null default 'in_elaboration',
  theme_required boolean not null default true,
  causal_cycle_policy text not null default 'warn',
  owner_recommended boolean not null default true,
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

  constraint skpe_strategic_map_packages_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_strategic_map_packages_status_check
    check (status in (
      'in_elaboration',
      'pending_validation',
      'validated'
    )),
  constraint skpe_strategic_map_packages_cycle_policy_check
    check (causal_cycle_policy in ('warn', 'block')),
  constraint skpe_strategic_map_packages_unique
    unique (formulation_id)
);

comment on table public.skpe_strategic_map_packages is
  'Cabeçalho de governança e validação do conjunto de Temas, Perspectivas, Objetivos e relações causais da FE-04.';

comment on column public.skpe_strategic_map_packages.theme_required is
  'Define se todo Objetivo ativo deve possuir Tema Estratégico na metodologia adotada para a versão.';

comment on column public.skpe_strategic_map_packages.causal_cycle_policy is
  'Política para ciclos causais: warn sinaliza metodologicamente; block impede a criação do ciclo.';

create index if not exists idx_skpe_strategic_map_packages_scope
  on public.skpe_strategic_map_packages(
    organization_id,
    project_id,
    formulation_id,
    status
  );

drop trigger if exists skpe_strategic_map_packages_set_updated_at
  on public.skpe_strategic_map_packages;

create trigger skpe_strategic_map_packages_set_updated_at
before update on public.skpe_strategic_map_packages
for each row
execute function public.set_updated_at();

alter table public.skpe_strategic_map_packages enable row level security;

drop policy if exists skpe_strategic_map_packages_select
  on public.skpe_strategic_map_packages;

create policy skpe_strategic_map_packages_select
on public.skpe_strategic_map_packages
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

-- A mesma trava transversal das demais entidades da Formulação protege
-- o pacote quando a versão não estiver em rascunho ou elaboração.
drop trigger if exists skpe_strategic_map_packages_guard_approved_formulation
  on public.skpe_strategic_map_packages;

create trigger skpe_strategic_map_packages_guard_approved_formulation
before insert or update or delete
on public.skpe_strategic_map_packages
for each row
execute function public.skpe_guard_approved_formulation_content();

-- ============================================================
-- 2. AJUSTES COMPATÍVEIS NAS ESTRUTURAS EXISTENTES
-- ============================================================

-- Amplia, sem romper os códigos já existentes, os tipos de relação causal
-- admitidos pela arquitetura da FE-04.
do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'skpe_objective_relations_type_check'
      and conrelid = 'public.skpe_objective_relations'::regclass
  ) then
    alter table public.skpe_objective_relations
      drop constraint skpe_objective_relations_type_check;
  end if;

  alter table public.skpe_objective_relations
    add constraint skpe_objective_relations_type_check
    check (relation_type in (
      'cause_effect',
      'supports',
      'enables',
      'contributes_to',
      'depends_on',
      'influences'
    ));
end;
$$;

create index if not exists idx_skpe_strategic_themes_map
  on public.skpe_strategic_themes(
    formulation_id,
    status,
    display_order,
    code
  );

create index if not exists idx_skpe_bsc_perspectives_map
  on public.skpe_bsc_perspectives(
    formulation_id,
    status,
    display_order,
    code
  );

create index if not exists idx_skpe_strategic_objectives_map
  on public.skpe_strategic_objectives(
    formulation_id,
    perspective_id,
    strategic_theme_id,
    status,
    priority
  );

create index if not exists idx_skpe_objective_relations_map
  on public.skpe_objective_relations(
    formulation_id,
    source_objective_id,
    target_objective_id,
    relation_type,
    display_order
  );

-- ============================================================
-- 3. FUNÇÕES INTERNAS DO PACOTE
-- ============================================================

create or replace function public.ensure_skpe_strategic_map_package(
  target_formulation_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_strategic_map_packages%rowtype;
  source_package public.skpe_strategic_map_packages%rowtype;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(target_formulation_id);

  select *
  into package_row
  from public.skpe_strategic_map_packages
  where formulation_id = target_formulation_id
  for update;

  if found then
    return package_row.id;
  end if;

  if formulation_row.derived_from_formulation_id is not null then
    select *
    into source_package
    from public.skpe_strategic_map_packages
    where formulation_id = formulation_row.derived_from_formulation_id;
  end if;

  insert into public.skpe_strategic_map_packages (
    organization_id,
    project_id,
    formulation_id,
    status,
    theme_required,
    causal_cycle_policy,
    owner_recommended,
    metadata,
    created_by,
    updated_by
  )
  values (
    formulation_row.organization_id,
    formulation_row.project_id,
    formulation_row.id,
    'in_elaboration',
    coalesce(source_package.theme_required, true),
    coalesce(source_package.causal_cycle_policy, 'warn'),
    coalesce(source_package.owner_recommended, true),
    coalesce(source_package.metadata, '{}'::jsonb)
      || case
        when source_package.id is null then '{}'::jsonb
        else jsonb_build_object(
          'clonedFromStrategicMapPackageId', source_package.id,
          'clonedFromFormulationId', formulation_row.derived_from_formulation_id
        )
      end,
    auth.uid(),
    auth.uid()
  )
  returning *
  into package_row;

  perform public.skpe_record_operational_audit(
    package_row.organization_id,
    package_row.project_id,
    'strategic_map_package',
    package_row.id,
    'strategic_map_package_created',
    'Criação automática do pacote operacional do Mapa Estratégico.',
    null,
    to_jsonb(package_row)
  );

  return package_row.id;
end;
$$;

comment on function public.ensure_skpe_strategic_map_package(uuid) is
  'Função interna que garante o cabeçalho de governança da FE-04 para uma versão editável da Formulação.';

create or replace function public.skpe_invalidate_strategic_map_package(
  target_formulation_id uuid,
  invalidation_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  package_id uuid;
  previous_package public.skpe_strategic_map_packages%rowtype;
  updated_package public.skpe_strategic_map_packages%rowtype;
begin
  package_id := public.ensure_skpe_strategic_map_package(
    target_formulation_id
  );

  select *
  into previous_package
  from public.skpe_strategic_map_packages
  where id = package_id
  for update;

  if previous_package.status = 'in_elaboration'
     and previous_package.validation_notes is null
     and previous_package.submitted_for_validation_at is null
     and previous_package.validated_at is null then
    return previous_package.id;
  end if;

  update public.skpe_strategic_map_packages
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

  update public.skpe_strategic_objectives
  set
    validation_status = 'draft',
    approved_at = null,
    approved_by = null,
    updated_by = auth.uid()
  where formulation_id = target_formulation_id
    and status <> 'archived';

  perform public.skpe_record_operational_audit(
    updated_package.organization_id,
    updated_package.project_id,
    'strategic_map_package',
    updated_package.id,
    'strategic_map_package_invalidated',
    coalesce(
      nullif(trim(invalidation_reason), ''),
      'Alteração do conteúdo invalidou a validação anterior do Mapa Estratégico.'
    ),
    to_jsonb(previous_package),
    to_jsonb(updated_package)
  );

  return updated_package.id;
end;
$$;

comment on function public.skpe_invalidate_strategic_map_package(uuid, text) is
  'Função interna que retorna a FE-04 para elaboração após qualquer mutação de conteúdo.';

create or replace function public.skpe_objective_relation_would_create_cycle(
  target_formulation_id uuid,
  candidate_source_objective_id uuid,
  candidate_target_objective_id uuid,
  excluded_relation_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with recursive edges as (
    select
      relation.source_objective_id,
      relation.target_objective_id
    from public.skpe_objective_relations relation
    join public.skpe_strategic_objectives source_objective
      on source_objective.id = relation.source_objective_id
    join public.skpe_strategic_objectives target_objective
      on target_objective.id = relation.target_objective_id
    where relation.formulation_id = target_formulation_id
      and (excluded_relation_id is null or relation.id <> excluded_relation_id)
      and source_objective.status <> 'archived'
      and target_objective.status <> 'archived'
  ),
  walk(current_objective_id, visited_path) as (
    select
      edge.target_objective_id,
      array[candidate_target_objective_id, edge.target_objective_id]::uuid[]
    from edges edge
    where edge.source_objective_id = candidate_target_objective_id

    union all

    select
      edge.target_objective_id,
      walk.visited_path || edge.target_objective_id
    from walk
    join edges edge
      on edge.source_objective_id = walk.current_objective_id
    where cardinality(walk.visited_path) < 100
      and (
        edge.target_objective_id = candidate_source_objective_id
        or not edge.target_objective_id = any(walk.visited_path)
      )
  )
  select exists (
    select 1
    from walk
    where current_objective_id = candidate_source_objective_id
  );
$$;

comment on function public.skpe_objective_relation_would_create_cycle(uuid, uuid, uuid, uuid) is
  'Função interna que detecta se uma relação direcionada criaria caminho de retorno ao Objetivo de origem.';

-- ============================================================
-- 4. CONFIGURAÇÃO METODOLÓGICA DO MAPA
-- ============================================================

create or replace function public.configure_skpe_strategic_map(
  target_formulation_id uuid,
  require_theme boolean default true,
  cycle_policy text default 'warn',
  recommend_owner boolean default true,
  package_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_policy text;
  package_id uuid;
  previous_package public.skpe_strategic_map_packages%rowtype;
  updated_package public.skpe_strategic_map_packages%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  normalized_policy := lower(trim(coalesce(cycle_policy, 'warn')));

  if normalized_policy not in ('warn', 'block') then
    raise exception 'Política de ciclos inválida. Use warn ou block.'
      using errcode = '22023';
  end if;

  if package_metadata is not null
     and jsonb_typeof(package_metadata) <> 'object' then
    raise exception 'Os metadados do Mapa Estratégico devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  package_id := public.ensure_skpe_strategic_map_package(
    target_formulation_id
  );

  select *
  into previous_package
  from public.skpe_strategic_map_packages
  where id = package_id
  for update;

  update public.skpe_strategic_map_packages
  set
    theme_required = require_theme,
    causal_cycle_policy = normalized_policy,
    owner_recommended = recommend_owner,
    metadata = coalesce(metadata, '{}'::jsonb)
      || coalesce(package_metadata, '{}'::jsonb),
    status = 'in_elaboration',
    validation_notes = null,
    submitted_for_validation_at = null,
    submitted_for_validation_by = null,
    validated_at = null,
    validated_by = null,
    updated_by = auth.uid()
  where id = package_id
  returning *
  into updated_package;

  update public.skpe_strategic_objectives
  set
    validation_status = 'draft',
    approved_at = null,
    approved_by = null,
    updated_by = auth.uid()
  where formulation_id = target_formulation_id
    and status <> 'archived';

  perform public.skpe_record_operational_audit(
    updated_package.organization_id,
    updated_package.project_id,
    'strategic_map_package',
    updated_package.id,
    'strategic_map_package_configured',
    change_reason,
    to_jsonb(previous_package),
    to_jsonb(updated_package)
  );

  return updated_package.id;
end;
$$;

-- ============================================================
-- 5. TEMAS ESTRATÉGICOS
-- ============================================================

create or replace function public.upsert_skpe_strategic_theme(
  target_formulation_id uuid,
  theme_code text,
  theme_name text,
  theme_description text default null,
  theme_rationale text default null,
  target_theme_id uuid default null,
  theme_priority text default 'medium',
  theme_display_order integer default 100,
  theme_horizon_start date default null,
  theme_horizon_end date default null,
  theme_owner_user_id uuid default null,
  theme_status text default 'active',
  theme_visual_color text default null,
  theme_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  previous_theme public.skpe_strategic_themes%rowtype;
  saved_theme public.skpe_strategic_themes%rowtype;
  linked_objective public.skpe_strategic_objectives%rowtype;
  synchronized_objective public.skpe_strategic_objectives%rowtype;
  normalized_priority text;
  normalized_status text;
  metadata_patch jsonb;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_formulation_editable(target_formulation_id);

  if length(trim(coalesce(theme_code, ''))) = 0 then
    raise exception 'Informe o código do Tema Estratégico.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(theme_name, ''))) = 0 then
    raise exception 'Informe o nome do Tema Estratégico.'
      using errcode = '22023';
  end if;

  if theme_display_order < 0 then
    raise exception 'A ordem de exibição do Tema não pode ser negativa.'
      using errcode = '22023';
  end if;

  if theme_horizon_end is not null
     and theme_horizon_start is not null
     and theme_horizon_end < theme_horizon_start then
    raise exception 'O fim do horizonte do Tema não pode ser anterior ao início.'
      using errcode = '22023';
  end if;

  normalized_priority := lower(trim(coalesce(theme_priority, 'medium')));
  normalized_status := lower(trim(coalesce(theme_status, 'active')));

  if normalized_priority not in ('low', 'medium', 'high', 'critical') then
    raise exception 'Prioridade inválida para o Tema Estratégico.'
      using errcode = '22023';
  end if;

  if normalized_status not in ('draft', 'active', 'completed', 'suspended') then
    raise exception 'Situação inválida. O arquivamento deve usar a operação específica.'
      using errcode = '22023';
  end if;

  if theme_metadata is not null
     and jsonb_typeof(theme_metadata) <> 'object' then
    raise exception 'Os metadados do Tema devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  metadata_patch := coalesce(theme_metadata, '{}'::jsonb);

  if theme_visual_color is not null then
    metadata_patch := metadata_patch || jsonb_build_object(
      'visualColor', trim(theme_visual_color)
    );
  end if;

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if target_theme_id is not null then
    select *
    into previous_theme
    from public.skpe_strategic_themes
    where id = target_theme_id
    for update;

    if not found
       or previous_theme.formulation_id <> target_formulation_id then
      raise exception 'Tema Estratégico não encontrado nesta Formulação.'
        using errcode = '22023';
    end if;

    if previous_theme.status = 'archived' then
      raise exception 'Tema arquivado não pode ser alterado.'
        using errcode = '55000';
    end if;

    update public.skpe_strategic_themes
    set
      code = trim(theme_code),
      name = trim(theme_name),
      description = nullif(trim(theme_description), ''),
      rationale = nullif(trim(theme_rationale), ''),
      horizon_start = theme_horizon_start,
      horizon_end = theme_horizon_end,
      priority = normalized_priority,
      owner_user_id = theme_owner_user_id,
      display_order = theme_display_order,
      status = normalized_status,
      metadata = coalesce(metadata, '{}'::jsonb) || metadata_patch,
      updated_by = auth.uid()
    where id = previous_theme.id
    returning *
    into saved_theme;

    action_code := 'strategic_theme_updated';

    if previous_theme.code is distinct from saved_theme.code then
      for linked_objective in
        select *
        from public.skpe_strategic_objectives objective
        where objective.strategic_theme_id = saved_theme.id
          and objective.status <> 'archived'
        for update
      loop
        update public.skpe_strategic_objectives
        set
          strategic_theme = saved_theme.code,
          validation_status = 'draft',
          approved_at = null,
          approved_by = null,
          updated_by = auth.uid()
        where id = linked_objective.id
        returning *
        into synchronized_objective;

        perform public.skpe_record_operational_audit(
          synchronized_objective.organization_id,
          synchronized_objective.project_id,
          'strategic_objective',
          synchronized_objective.id,
          'strategic_objective_theme_code_synchronized',
          change_reason,
          to_jsonb(linked_objective),
          to_jsonb(synchronized_objective)
        );
      end loop;
    end if;
  else
    insert into public.skpe_strategic_themes (
      organization_id,
      project_id,
      formulation_id,
      code,
      name,
      description,
      rationale,
      horizon_start,
      horizon_end,
      priority,
      owner_user_id,
      display_order,
      status,
      metadata,
      created_by,
      updated_by
    )
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      trim(theme_code),
      trim(theme_name),
      nullif(trim(theme_description), ''),
      nullif(trim(theme_rationale), ''),
      theme_horizon_start,
      theme_horizon_end,
      normalized_priority,
      theme_owner_user_id,
      theme_display_order,
      normalized_status,
      metadata_patch,
      auth.uid(),
      auth.uid()
    )
    returning *
    into saved_theme;

    action_code := 'strategic_theme_created';
  end if;

  perform public.skpe_record_operational_audit(
    saved_theme.organization_id,
    saved_theme.project_id,
    'strategic_theme',
    saved_theme.id,
    action_code,
    change_reason,
    case when previous_theme.id is null then null else to_jsonb(previous_theme) end,
    to_jsonb(saved_theme)
  );

  perform public.skpe_invalidate_strategic_map_package(
    target_formulation_id,
    'Alteração em Tema Estratégico invalidou a validação anterior do Mapa.'
  );

  return saved_theme.id;
end;
$$;

create or replace function public.archive_skpe_strategic_theme(
  target_theme_id uuid,
  change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_theme public.skpe_strategic_themes%rowtype;
  archived_theme public.skpe_strategic_themes%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_theme
  from public.skpe_strategic_themes
  where id = target_theme_id
  for update;

  if not found then
    return false;
  end if;

  perform public.skpe_assert_formulation_editable(
    previous_theme.formulation_id
  );

  if previous_theme.status = 'archived' then
    return true;
  end if;

  if exists (
    select 1
    from public.skpe_strategic_objectives objective
    where objective.strategic_theme_id = previous_theme.id
      and objective.status <> 'archived'
  ) then
    raise exception
      'O Tema possui Objetivos não arquivados. Reatribua ou arquive os Objetivos antes de arquivar o Tema.'
      using errcode = '55000';
  end if;

  update public.skpe_strategic_themes
  set
    status = 'archived',
    updated_by = auth.uid()
  where id = previous_theme.id
  returning *
  into archived_theme;

  perform public.skpe_record_operational_audit(
    archived_theme.organization_id,
    archived_theme.project_id,
    'strategic_theme',
    archived_theme.id,
    'strategic_theme_archived',
    change_reason,
    to_jsonb(previous_theme),
    to_jsonb(archived_theme)
  );

  perform public.skpe_invalidate_strategic_map_package(
    previous_theme.formulation_id,
    'Arquivamento de Tema Estratégico invalidou a validação anterior do Mapa.'
  );

  return true;
end;
$$;

-- ============================================================
-- 6. PERSPECTIVAS ESTRATÉGICAS
-- ============================================================

create or replace function public.upsert_skpe_bsc_perspective(
  target_formulation_id uuid,
  perspective_code text,
  perspective_name text,
  perspective_description text default null,
  target_perspective_id uuid default null,
  perspective_display_order integer default 100,
  perspective_status text default 'active',
  methodological_nature text default 'custom',
  perspective_model text default 'custom',
  perspective_visual_color text default null,
  perspective_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  previous_perspective public.skpe_bsc_perspectives%rowtype;
  saved_perspective public.skpe_bsc_perspectives%rowtype;
  linked_objective public.skpe_strategic_objectives%rowtype;
  synchronized_objective public.skpe_strategic_objectives%rowtype;
  normalized_status text;
  normalized_model text;
  metadata_patch jsonb;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_formulation_editable(target_formulation_id);

  if length(trim(coalesce(perspective_code, ''))) = 0 then
    raise exception 'Informe o código da Perspectiva Estratégica.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(perspective_name, ''))) = 0 then
    raise exception 'Informe o nome da Perspectiva Estratégica.'
      using errcode = '22023';
  end if;

  if perspective_display_order < 0 then
    raise exception 'A ordem vertical da Perspectiva não pode ser negativa.'
      using errcode = '22023';
  end if;

  normalized_status := lower(trim(coalesce(perspective_status, 'active')));
  normalized_model := lower(trim(coalesce(perspective_model, 'custom')));

  if normalized_status not in ('active', 'inactive') then
    raise exception 'Situação inválida. O arquivamento deve usar a operação específica.'
      using errcode = '22023';
  end if;

  if normalized_model not in ('bsc_standard', 'custom') then
    raise exception 'Modelo inválido. Use bsc_standard ou custom.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(methodological_nature, ''))) = 0 then
    raise exception 'Informe a natureza ou o grupo metodológico da Perspectiva.'
      using errcode = '22023';
  end if;

  if perspective_metadata is not null
     and jsonb_typeof(perspective_metadata) <> 'object' then
    raise exception 'Os metadados da Perspectiva devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  metadata_patch := coalesce(perspective_metadata, '{}'::jsonb)
    || jsonb_build_object(
      'methodologicalNature', trim(methodological_nature),
      'perspectiveModel', normalized_model
    );

  if perspective_visual_color is not null then
    metadata_patch := metadata_patch || jsonb_build_object(
      'visualColor', trim(perspective_visual_color)
    );
  end if;

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if target_perspective_id is not null then
    select *
    into previous_perspective
    from public.skpe_bsc_perspectives
    where id = target_perspective_id
    for update;

    if not found
       or previous_perspective.formulation_id <> target_formulation_id then
      raise exception 'Perspectiva não encontrada nesta Formulação.'
        using errcode = '22023';
    end if;

    if previous_perspective.status = 'archived' then
      raise exception 'Perspectiva arquivada não pode ser alterada.'
        using errcode = '55000';
    end if;

    update public.skpe_bsc_perspectives
    set
      code = trim(perspective_code),
      name = trim(perspective_name),
      description = nullif(trim(perspective_description), ''),
      display_order = perspective_display_order,
      status = normalized_status,
      metadata = coalesce(metadata, '{}'::jsonb) || metadata_patch,
      updated_by = auth.uid()
    where id = previous_perspective.id
    returning *
    into saved_perspective;

    action_code := 'bsc_perspective_updated';

    if previous_perspective.code is distinct from saved_perspective.code then
      for linked_objective in
        select *
        from public.skpe_strategic_objectives objective
        where objective.perspective_id = saved_perspective.id
          and objective.status <> 'archived'
        for update
      loop
        update public.skpe_strategic_objectives
        set
          perspective_code = saved_perspective.code,
          validation_status = 'draft',
          approved_at = null,
          approved_by = null,
          updated_by = auth.uid()
        where id = linked_objective.id
        returning *
        into synchronized_objective;

        perform public.skpe_record_operational_audit(
          synchronized_objective.organization_id,
          synchronized_objective.project_id,
          'strategic_objective',
          synchronized_objective.id,
          'strategic_objective_perspective_code_synchronized',
          change_reason,
          to_jsonb(linked_objective),
          to_jsonb(synchronized_objective)
        );
      end loop;
    end if;
  else
    insert into public.skpe_bsc_perspectives (
      organization_id,
      project_id,
      formulation_id,
      code,
      name,
      description,
      display_order,
      status,
      metadata,
      created_by,
      updated_by
    )
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      trim(perspective_code),
      trim(perspective_name),
      nullif(trim(perspective_description), ''),
      perspective_display_order,
      normalized_status,
      metadata_patch,
      auth.uid(),
      auth.uid()
    )
    returning *
    into saved_perspective;

    action_code := 'bsc_perspective_created';
  end if;

  perform public.skpe_record_operational_audit(
    saved_perspective.organization_id,
    saved_perspective.project_id,
    'bsc_perspective',
    saved_perspective.id,
    action_code,
    change_reason,
    case when previous_perspective.id is null then null else to_jsonb(previous_perspective) end,
    to_jsonb(saved_perspective)
  );

  perform public.skpe_invalidate_strategic_map_package(
    target_formulation_id,
    'Alteração em Perspectiva Estratégica invalidou a validação anterior do Mapa.'
  );

  return saved_perspective.id;
end;
$$;

create or replace function public.archive_skpe_bsc_perspective(
  target_perspective_id uuid,
  change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_perspective public.skpe_bsc_perspectives%rowtype;
  archived_perspective public.skpe_bsc_perspectives%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_perspective
  from public.skpe_bsc_perspectives
  where id = target_perspective_id
  for update;

  if not found then
    return false;
  end if;

  perform public.skpe_assert_formulation_editable(
    previous_perspective.formulation_id
  );

  if previous_perspective.status = 'archived' then
    return true;
  end if;

  if exists (
    select 1
    from public.skpe_strategic_objectives objective
    where objective.perspective_id = previous_perspective.id
      and objective.status <> 'archived'
  ) then
    raise exception
      'A Perspectiva possui Objetivos não arquivados. Reatribua ou arquive os Objetivos antes de arquivar a Perspectiva.'
      using errcode = '55000';
  end if;

  update public.skpe_bsc_perspectives
  set
    status = 'archived',
    updated_by = auth.uid()
  where id = previous_perspective.id
  returning *
  into archived_perspective;

  perform public.skpe_record_operational_audit(
    archived_perspective.organization_id,
    archived_perspective.project_id,
    'bsc_perspective',
    archived_perspective.id,
    'bsc_perspective_archived',
    change_reason,
    to_jsonb(previous_perspective),
    to_jsonb(archived_perspective)
  );

  perform public.skpe_invalidate_strategic_map_package(
    previous_perspective.formulation_id,
    'Arquivamento de Perspectiva invalidou a validação anterior do Mapa.'
  );

  return true;
end;
$$;

-- ============================================================
-- 7. OBJETIVOS ESTRATÉGICOS
-- ============================================================

create or replace function public.upsert_skpe_strategic_objective(
  target_formulation_id uuid,
  objective_code text,
  objective_name text,
  objective_description text default null,
  objective_expected_result text default null,
  objective_rationale text default null,
  target_objective_id uuid default null,
  target_theme_id uuid default null,
  target_perspective_id uuid default null,
  objective_priority text default 'medium',
  objective_horizon_start date default null,
  objective_horizon_end date default null,
  objective_owner_user_id uuid default null,
  objective_status text default 'active',
  objective_display_order integer default 100,
  objective_map_position jsonb default null,
  objective_visual_color text default null,
  objective_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  theme_row public.skpe_strategic_themes%rowtype;
  perspective_row public.skpe_bsc_perspectives%rowtype;
  previous_objective public.skpe_strategic_objectives%rowtype;
  saved_objective public.skpe_strategic_objectives%rowtype;
  normalized_priority text;
  normalized_status text;
  metadata_patch jsonb;
  theme_code_value text;
  perspective_code_value text;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_formulation_editable(target_formulation_id);

  if length(trim(coalesce(objective_code, ''))) = 0 then
    raise exception 'Informe o código do Objetivo Estratégico.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(objective_name, ''))) = 0 then
    raise exception 'Informe o título do Objetivo Estratégico.'
      using errcode = '22023';
  end if;

  if objective_display_order < 0 then
    raise exception 'A ordem de exibição do Objetivo não pode ser negativa.'
      using errcode = '22023';
  end if;

  if objective_horizon_end is not null
     and objective_horizon_start is not null
     and objective_horizon_end < objective_horizon_start then
    raise exception 'O fim do horizonte do Objetivo não pode ser anterior ao início.'
      using errcode = '22023';
  end if;

  normalized_priority := lower(trim(coalesce(objective_priority, 'medium')));
  normalized_status := lower(trim(coalesce(objective_status, 'active')));

  if normalized_priority not in ('low', 'medium', 'high', 'critical') then
    raise exception 'Prioridade inválida para o Objetivo Estratégico.'
      using errcode = '22023';
  end if;

  if normalized_status not in ('draft', 'active', 'completed', 'suspended') then
    raise exception 'Situação inválida. O arquivamento deve usar a operação específica.'
      using errcode = '22023';
  end if;

  if objective_map_position is not null
     and jsonb_typeof(objective_map_position) <> 'object' then
    raise exception 'A posição do Objetivo no Mapa deve ser um objeto JSON.'
      using errcode = '22023';
  end if;

  if objective_metadata is not null
     and jsonb_typeof(objective_metadata) <> 'object' then
    raise exception 'Os metadados do Objetivo devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  metadata_patch := coalesce(objective_metadata, '{}'::jsonb)
    || jsonb_build_object('displayOrder', objective_display_order);

  if objective_map_position is not null then
    metadata_patch := metadata_patch || jsonb_build_object(
      'mapPosition', objective_map_position
    );
  end if;

  if objective_visual_color is not null then
    metadata_patch := metadata_patch || jsonb_build_object(
      'visualColor', trim(objective_visual_color)
    );
  end if;

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if target_theme_id is not null then
    select *
    into theme_row
    from public.skpe_strategic_themes
    where id = target_theme_id;

    if not found
       or theme_row.formulation_id <> target_formulation_id
       or theme_row.status = 'archived' then
      raise exception 'Tema inválido ou fora do escopo desta Formulação.'
        using errcode = '22023';
    end if;

    theme_code_value := theme_row.code;
  end if;

  if target_perspective_id is not null then
    select *
    into perspective_row
    from public.skpe_bsc_perspectives
    where id = target_perspective_id;

    if not found
       or perspective_row.formulation_id <> target_formulation_id
       or perspective_row.status = 'archived' then
      raise exception 'Perspectiva inválida ou fora do escopo desta Formulação.'
        using errcode = '22023';
    end if;

    perspective_code_value := perspective_row.code;
  end if;

  if target_objective_id is not null then
    select *
    into previous_objective
    from public.skpe_strategic_objectives
    where id = target_objective_id
    for update;

    if not found
       or previous_objective.formulation_id <> target_formulation_id then
      raise exception 'Objetivo Estratégico não encontrado nesta Formulação.'
        using errcode = '22023';
    end if;

    if previous_objective.status = 'archived' then
      raise exception 'Objetivo arquivado não pode ser alterado.'
        using errcode = '55000';
    end if;

    update public.skpe_strategic_objectives
    set
      code = trim(objective_code),
      name = trim(objective_name),
      description = nullif(trim(objective_description), ''),
      management_model = 'bsc',
      perspective_code = perspective_code_value,
      strategic_theme = theme_code_value,
      horizon_start = objective_horizon_start,
      horizon_end = objective_horizon_end,
      owner_user_id = objective_owner_user_id,
      status = normalized_status,
      metadata = coalesce(metadata, '{}'::jsonb) || metadata_patch,
      updated_by = auth.uid(),
      strategic_theme_id = target_theme_id,
      perspective_id = target_perspective_id,
      expected_result = nullif(trim(objective_expected_result), ''),
      rationale = nullif(trim(objective_rationale), ''),
      priority = normalized_priority,
      validation_status = 'draft',
      approved_at = null,
      approved_by = null
    where id = previous_objective.id
    returning *
    into saved_objective;

    action_code := 'strategic_objective_updated';
  else
    insert into public.skpe_strategic_objectives (
      organization_id,
      project_id,
      code,
      name,
      description,
      management_model,
      perspective_code,
      strategic_theme,
      horizon_start,
      horizon_end,
      owner_user_id,
      status,
      progress,
      metadata,
      created_by,
      updated_by,
      formulation_id,
      strategic_theme_id,
      perspective_id,
      expected_result,
      rationale,
      priority,
      validation_status,
      approved_at,
      approved_by
    )
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      trim(objective_code),
      trim(objective_name),
      nullif(trim(objective_description), ''),
      'bsc',
      perspective_code_value,
      theme_code_value,
      objective_horizon_start,
      objective_horizon_end,
      objective_owner_user_id,
      normalized_status,
      0,
      metadata_patch,
      auth.uid(),
      auth.uid(),
      formulation_row.id,
      target_theme_id,
      target_perspective_id,
      nullif(trim(objective_expected_result), ''),
      nullif(trim(objective_rationale), ''),
      normalized_priority,
      'draft',
      null,
      null
    )
    returning *
    into saved_objective;

    action_code := 'strategic_objective_created';
  end if;

  perform public.skpe_record_operational_audit(
    saved_objective.organization_id,
    saved_objective.project_id,
    'strategic_objective',
    saved_objective.id,
    action_code,
    change_reason,
    case when previous_objective.id is null then null else to_jsonb(previous_objective) end,
    to_jsonb(saved_objective)
  );

  perform public.skpe_invalidate_strategic_map_package(
    target_formulation_id,
    'Alteração em Objetivo Estratégico invalidou a validação anterior do Mapa.'
  );

  return saved_objective.id;
end;
$$;

create or replace function public.archive_skpe_strategic_objective(
  target_objective_id uuid,
  change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_objective public.skpe_strategic_objectives%rowtype;
  archived_objective public.skpe_strategic_objectives%rowtype;
  relation_row public.skpe_objective_relations%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_objective
  from public.skpe_strategic_objectives
  where id = target_objective_id
  for update;

  if not found then
    return false;
  end if;

  perform public.skpe_assert_formulation_editable(
    previous_objective.formulation_id
  );

  if previous_objective.status = 'archived' then
    return true;
  end if;

  for relation_row in
    select *
    from public.skpe_objective_relations relation
    where relation.source_objective_id = previous_objective.id
       or relation.target_objective_id = previous_objective.id
    for update
  loop
    perform public.skpe_record_operational_audit(
      relation_row.organization_id,
      relation_row.project_id,
      'objective_relation',
      relation_row.id,
      'objective_relation_deleted_due_objective_archive',
      change_reason,
      to_jsonb(relation_row),
      null
    );
  end loop;

  delete from public.skpe_objective_relations
  where source_objective_id = previous_objective.id
     or target_objective_id = previous_objective.id;

  update public.skpe_strategic_objectives
  set
    status = 'archived',
    validation_status = 'draft',
    approved_at = null,
    approved_by = null,
    updated_by = auth.uid()
  where id = previous_objective.id
  returning *
  into archived_objective;

  perform public.skpe_record_operational_audit(
    archived_objective.organization_id,
    archived_objective.project_id,
    'strategic_objective',
    archived_objective.id,
    'strategic_objective_archived',
    change_reason,
    to_jsonb(previous_objective),
    to_jsonb(archived_objective)
  );

  perform public.skpe_invalidate_strategic_map_package(
    previous_objective.formulation_id,
    'Arquivamento de Objetivo Estratégico invalidou a validação anterior do Mapa.'
  );

  return true;
end;
$$;

-- ============================================================
-- 8. RELAÇÕES CAUSAIS ENTRE OBJETIVOS
-- ============================================================

create or replace function public.upsert_skpe_objective_relation(
  target_formulation_id uuid,
  source_objective_id uuid,
  target_objective_id uuid,
  objective_relation_type text default 'cause_effect',
  relation_strength text default 'medium',
  relation_weight numeric default null,
  relation_rationale text default null,
  relation_display_order integer default 100,
  target_relation_id uuid default null,
  relation_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  source_row public.skpe_strategic_objectives%rowtype;
  target_row public.skpe_strategic_objectives%rowtype;
  package_row public.skpe_strategic_map_packages%rowtype;
  previous_relation public.skpe_objective_relations%rowtype;
  saved_relation public.skpe_objective_relations%rowtype;
  normalized_type text;
  normalized_strength text;
  metadata_patch jsonb;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_formulation_editable(target_formulation_id);

  if source_objective_id = target_objective_id then
    raise exception 'Um Objetivo não pode possuir relação causal consigo próprio.'
      using errcode = '22023';
  end if;

  normalized_type := lower(trim(coalesce(
    objective_relation_type,
    'cause_effect'
  )));
  normalized_strength := lower(trim(coalesce(relation_strength, 'medium')));

  if normalized_type not in (
    'cause_effect',
    'supports',
    'enables',
    'contributes_to',
    'depends_on',
    'influences'
  ) then
    raise exception 'Tipo de relação causal inválido.'
      using errcode = '22023';
  end if;

  if normalized_strength not in ('low', 'medium', 'high') then
    raise exception 'Força de contribuição inválida.'
      using errcode = '22023';
  end if;

  if relation_weight is not null
     and (relation_weight < 0 or relation_weight > 100) then
    raise exception 'O peso da relação deve estar entre 0 e 100.'
      using errcode = '22023';
  end if;

  if relation_display_order < 0 then
    raise exception 'A ordem da relação não pode ser negativa.'
      using errcode = '22023';
  end if;

  if relation_metadata is not null
     and jsonb_typeof(relation_metadata) <> 'object' then
    raise exception 'Os metadados da relação devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  select *
  into source_row
  from public.skpe_strategic_objectives
  where id = source_objective_id;

  select *
  into target_row
  from public.skpe_strategic_objectives
  where id = target_objective_id;

  if source_row.id is null
     or target_row.id is null
     or source_row.formulation_id <> target_formulation_id
     or target_row.formulation_id <> target_formulation_id then
    raise exception 'Os Objetivos devem pertencer à mesma Formulação.'
      using errcode = '22023';
  end if;

  if source_row.organization_id <> formulation_row.organization_id
     or target_row.organization_id <> formulation_row.organization_id
     or source_row.project_id <> formulation_row.project_id
     or target_row.project_id <> formulation_row.project_id then
    raise exception 'Os Objetivos estão fora do escopo organizacional da Formulação.'
      using errcode = '22023';
  end if;

  if source_row.status = 'archived'
     or target_row.status = 'archived' then
    raise exception 'Não é permitido relacionar Objetivo arquivado.'
      using errcode = '55000';
  end if;

  perform public.ensure_skpe_strategic_map_package(target_formulation_id);

  select *
  into package_row
  from public.skpe_strategic_map_packages
  where formulation_id = target_formulation_id;

  if target_relation_id is not null then
    select *
    into previous_relation
    from public.skpe_objective_relations
    where id = target_relation_id
    for update;

    if not found
       or previous_relation.formulation_id <> target_formulation_id then
      raise exception 'Relação causal não encontrada nesta Formulação.'
        using errcode = '22023';
    end if;
  end if;

  if package_row.causal_cycle_policy = 'block'
     and public.skpe_objective_relation_would_create_cycle(
       target_formulation_id,
       source_objective_id,
       target_objective_id,
       target_relation_id
     ) then
    raise exception
      'A relação criaria um ciclo causal e a política da Formulação está configurada para bloqueio.'
      using errcode = '55000';
  end if;

  metadata_patch := coalesce(relation_metadata, '{}'::jsonb);

  if relation_weight is not null then
    metadata_patch := metadata_patch || jsonb_build_object(
      'relationWeight', relation_weight
    );
  end if;

  if target_relation_id is not null then
    update public.skpe_objective_relations
    set
      source_objective_id = source_row.id,
      target_objective_id = target_row.id,
      relation_type = normalized_type,
      contribution_strength = normalized_strength,
      rationale = nullif(trim(relation_rationale), ''),
      display_order = relation_display_order,
      metadata = coalesce(metadata, '{}'::jsonb) || metadata_patch
    where id = previous_relation.id
    returning *
    into saved_relation;

    action_code := 'objective_relation_updated';
  else
    insert into public.skpe_objective_relations (
      organization_id,
      project_id,
      formulation_id,
      source_objective_id,
      target_objective_id,
      relation_type,
      contribution_strength,
      rationale,
      display_order,
      metadata,
      created_by
    )
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      source_row.id,
      target_row.id,
      normalized_type,
      normalized_strength,
      nullif(trim(relation_rationale), ''),
      relation_display_order,
      metadata_patch,
      auth.uid()
    )
    returning *
    into saved_relation;

    action_code := 'objective_relation_created';
  end if;

  perform public.skpe_record_operational_audit(
    saved_relation.organization_id,
    saved_relation.project_id,
    'objective_relation',
    saved_relation.id,
    action_code,
    change_reason,
    case when previous_relation.id is null then null else to_jsonb(previous_relation) end,
    to_jsonb(saved_relation)
  );

  perform public.skpe_invalidate_strategic_map_package(
    target_formulation_id,
    'Alteração em relação causal invalidou a validação anterior do Mapa.'
  );

  return saved_relation.id;
end;
$$;

create or replace function public.delete_skpe_objective_relation(
  target_relation_id uuid,
  change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_relation public.skpe_objective_relations%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_relation
  from public.skpe_objective_relations
  where id = target_relation_id
  for update;

  if not found then
    return false;
  end if;

  perform public.skpe_assert_formulation_editable(
    previous_relation.formulation_id
  );

  delete from public.skpe_objective_relations
  where id = previous_relation.id;

  perform public.skpe_record_operational_audit(
    previous_relation.organization_id,
    previous_relation.project_id,
    'objective_relation',
    previous_relation.id,
    'objective_relation_deleted',
    change_reason,
    to_jsonb(previous_relation),
    null
  );

  perform public.skpe_invalidate_strategic_map_package(
    previous_relation.formulation_id,
    'Exclusão de relação causal invalidou a validação anterior do Mapa.'
  );

  return true;
end;
$$;

-- ============================================================
-- 9. PRONTIDÃO METODOLÓGICA DA FE-04
-- ============================================================

create or replace function public.get_skpe_strategic_map_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_strategic_map_packages%rowtype;
  issues jsonb;
  counts jsonb;
  content_blocking_count integer;
  total_blocking_count integer;
  cycle_count integer := 0;
  active_objective_count integer := 0;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado ao Mapa Estratégico.'
      using errcode = '42501';
  end if;

  select *
  into package_row
  from public.skpe_strategic_map_packages
  where formulation_id = target_formulation_id;

  select count(*)
  into active_objective_count
  from public.skpe_strategic_objectives objective
  where objective.formulation_id = target_formulation_id
    and objective.status = 'active';

  with recursive active_edges as (
    select
      relation.source_objective_id,
      relation.target_objective_id
    from public.skpe_objective_relations relation
    join public.skpe_strategic_objectives source_objective
      on source_objective.id = relation.source_objective_id
     and source_objective.status = 'active'
    join public.skpe_strategic_objectives target_objective
      on target_objective.id = relation.target_objective_id
     and target_objective.status = 'active'
    where relation.formulation_id = target_formulation_id
  ),
  walk(start_objective_id, current_objective_id, visited_path, is_cycle) as (
    select
      edge.source_objective_id,
      edge.target_objective_id,
      array[edge.source_objective_id, edge.target_objective_id]::uuid[],
      false
    from active_edges edge

    union all

    select
      walk.start_objective_id,
      edge.target_objective_id,
      walk.visited_path || edge.target_objective_id,
      edge.target_objective_id = walk.start_objective_id
    from walk
    join active_edges edge
      on edge.source_objective_id = walk.current_objective_id
    where not walk.is_cycle
      and cardinality(walk.visited_path) < 100
      and (
        edge.target_objective_id = walk.start_objective_id
        or not edge.target_objective_id = any(walk.visited_path)
      )
  )
  select count(distinct start_objective_id)
  into cycle_count
  from walk
  where is_cycle;

  select jsonb_build_object(
    'activeThemes', (
      select count(*)
      from public.skpe_strategic_themes theme
      where theme.formulation_id = target_formulation_id
        and theme.status = 'active'
    ),
    'activePerspectives', (
      select count(*)
      from public.skpe_bsc_perspectives perspective
      where perspective.formulation_id = target_formulation_id
        and perspective.status = 'active'
    ),
    'activeObjectives', active_objective_count,
    'objectiveRelations', (
      select count(*)
      from public.skpe_objective_relations relation
      where relation.formulation_id = target_formulation_id
    ),
    'causalCycleNodes', cycle_count,
    'objectivesWithIndicators', (
      select count(distinct indicator.strategic_objective_id)
      from public.skpe_indicators indicator
      join public.skpe_strategic_objectives objective
        on objective.id = indicator.strategic_objective_id
      where objective.formulation_id = target_formulation_id
        and objective.status = 'active'
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status <> 'archived'
    )
  )
  into counts;

  with issue_rows as (
    select
      'THEMES_MISSING'::text as code,
      'blocking'::text as severity,
      'content'::text as issue_scope,
      'Registre ao menos um Tema Estratégico ativo.'::text as message,
      1::bigint as affected_count
    where not exists (
      select 1
      from public.skpe_strategic_themes theme
      where theme.formulation_id = target_formulation_id
        and theme.status = 'active'
    )

    union all

    select
      'PERSPECTIVES_MISSING',
      'blocking',
      'content',
      'Registre ao menos uma Perspectiva Estratégica ativa.',
      1
    where not exists (
      select 1
      from public.skpe_bsc_perspectives perspective
      where perspective.formulation_id = target_formulation_id
        and perspective.status = 'active'
    )

    union all

    select
      'OBJECTIVES_MISSING',
      'blocking',
      'content',
      'Registre ao menos um Objetivo Estratégico ativo.',
      1
    where active_objective_count = 0

    union all

    select
      'OBJECTIVE_WITHOUT_PERSPECTIVE',
      'blocking',
      'content',
      'Todo Objetivo Estratégico ativo deve pertencer a uma Perspectiva ativa.',
      count(*)
    from public.skpe_strategic_objectives objective
    left join public.skpe_bsc_perspectives perspective
      on perspective.id = objective.perspective_id
     and perspective.formulation_id = target_formulation_id
     and perspective.status = 'active'
    where objective.formulation_id = target_formulation_id
      and objective.status = 'active'
      and perspective.id is null
    having count(*) > 0

    union all

    select
      'OBJECTIVE_WITHOUT_THEME',
      'blocking',
      'content',
      'A metodologia configurada exige Tema principal para todo Objetivo ativo.',
      count(*)
    from public.skpe_strategic_objectives objective
    left join public.skpe_strategic_themes theme
      on theme.id = objective.strategic_theme_id
     and theme.formulation_id = target_formulation_id
     and theme.status = 'active'
    where objective.formulation_id = target_formulation_id
      and objective.status = 'active'
      and coalesce(package_row.theme_required, true)
      and theme.id is null
    having count(*) > 0

    union all

    select
      'OBJECTIVE_WITHOUT_EXPECTED_RESULT',
      'blocking',
      'content',
      'Todo Objetivo ativo deve explicitar o resultado esperado.',
      count(*)
    from public.skpe_strategic_objectives objective
    where objective.formulation_id = target_formulation_id
      and objective.status = 'active'
      and length(trim(coalesce(objective.expected_result, ''))) = 0
    having count(*) > 0

    union all

    select
      'OBJECTIVE_WITHOUT_RATIONALE',
      'blocking',
      'content',
      'Todo Objetivo ativo deve possuir racional estratégico.',
      count(*)
    from public.skpe_strategic_objectives objective
    where objective.formulation_id = target_formulation_id
      and objective.status = 'active'
      and length(trim(coalesce(objective.rationale, ''))) = 0
    having count(*) > 0

    union all

    select
      'OBJECTIVE_SCOPE_MISMATCH',
      'blocking',
      'content',
      'Existem Objetivos vinculados à Formulação com organização ou projeto incompatível.',
      count(*)
    from public.skpe_strategic_objectives objective
    where objective.formulation_id = target_formulation_id
      and (
        objective.organization_id <> formulation_row.organization_id
        or objective.project_id <> formulation_row.project_id
      )
    having count(*) > 0

    union all

    select
      'RELATION_SCOPE_MISMATCH',
      'blocking',
      'content',
      'Existem relações entre Objetivos fora do escopo da Formulação.',
      count(*)
    from public.skpe_objective_relations relation
    join public.skpe_strategic_objectives source_objective
      on source_objective.id = relation.source_objective_id
    join public.skpe_strategic_objectives target_objective
      on target_objective.id = relation.target_objective_id
    where relation.formulation_id = target_formulation_id
      and (
        source_objective.formulation_id <> target_formulation_id
        or target_objective.formulation_id <> target_formulation_id
        or relation.organization_id <> formulation_row.organization_id
        or relation.project_id <> formulation_row.project_id
      )
    having count(*) > 0

    union all

    select
      'RELATION_TO_ARCHIVED_OBJECTIVE',
      'blocking',
      'content',
      'Existem relações causais apontando para Objetivo arquivado.',
      count(*)
    from public.skpe_objective_relations relation
    join public.skpe_strategic_objectives source_objective
      on source_objective.id = relation.source_objective_id
    join public.skpe_strategic_objectives target_objective
      on target_objective.id = relation.target_objective_id
    where relation.formulation_id = target_formulation_id
      and (
        source_objective.status = 'archived'
        or target_objective.status = 'archived'
      )
    having count(*) > 0

    union all

    select
      'THEME_ORDER_DUPLICATE',
      'blocking',
      'content',
      'A ordem de exibição dos Temas ativos deve ser única.',
      count(*)
    from (
      select theme.display_order
      from public.skpe_strategic_themes theme
      where theme.formulation_id = target_formulation_id
        and theme.status = 'active'
      group by theme.display_order
      having count(*) > 1
    ) duplicated_order
    having count(*) > 0

    union all

    select
      'PERSPECTIVE_ORDER_DUPLICATE',
      'blocking',
      'content',
      'A ordem vertical das Perspectivas ativas deve ser única.',
      count(*)
    from (
      select perspective.display_order
      from public.skpe_bsc_perspectives perspective
      where perspective.formulation_id = target_formulation_id
        and perspective.status = 'active'
      group by perspective.display_order
      having count(*) > 1
    ) duplicated_order
    having count(*) > 0

    union all

    select
      'OBJECTIVE_ORDER_DUPLICATE_IN_PERSPECTIVE',
      'blocking',
      'content',
      'A ordem dos Objetivos deve ser única dentro de cada Perspectiva ativa.',
      count(*)
    from (
      select
        objective.perspective_id,
        case
          when jsonb_typeof(objective.metadata -> 'displayOrder') = 'number'
            then (objective.metadata ->> 'displayOrder')::integer
          else 100
        end as display_order
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = target_formulation_id
        and objective.status = 'active'
        and objective.perspective_id is not null
      group by
        objective.perspective_id,
        case
          when jsonb_typeof(objective.metadata -> 'displayOrder') = 'number'
            then (objective.metadata ->> 'displayOrder')::integer
          else 100
        end
      having count(*) > 1
    ) duplicated_order
    having count(*) > 0

    union all

    select
      'CAUSAL_CYCLE_BLOCKED',
      'blocking',
      'content',
      'Foram encontrados ciclos causais e a política configurada determina bloqueio.',
      cycle_count::bigint
    where cycle_count > 0
      and coalesce(package_row.causal_cycle_policy, 'warn') = 'block'

    union all

    select
      case
        when package_row.id is null then 'STRATEGIC_MAP_PACKAGE_NOT_CREATED'
        else 'STRATEGIC_MAP_PACKAGE_NOT_VALIDATED'
      end,
      'blocking',
      'formulation',
      'O pacote da FE-04 deve estar validado antes do avanço da Formulação.',
      1
    where package_row.id is null
       or package_row.status <> 'validated'

    union all

    select
      'THEME_WITHOUT_OBJECTIVES',
      'recommendation',
      'content',
      'Existem Temas ativos sem Objetivos Estratégicos associados.',
      count(*)
    from public.skpe_strategic_themes theme
    where theme.formulation_id = target_formulation_id
      and theme.status = 'active'
      and not exists (
        select 1
        from public.skpe_strategic_objectives objective
        where objective.strategic_theme_id = theme.id
          and objective.status = 'active'
      )
    having count(*) > 0

    union all

    select
      'PERSPECTIVE_WITHOUT_OBJECTIVES',
      'recommendation',
      'content',
      'Existem Perspectivas ativas sem Objetivos Estratégicos associados.',
      count(*)
    from public.skpe_bsc_perspectives perspective
    where perspective.formulation_id = target_formulation_id
      and perspective.status = 'active'
      and not exists (
        select 1
        from public.skpe_strategic_objectives objective
        where objective.perspective_id = perspective.id
          and objective.status = 'active'
      )
    having count(*) > 0

    union all

    select
      'OBJECTIVE_WITHOUT_CAUSAL_RELATION',
      'recommendation',
      'content',
      'Existem Objetivos ativos sem relação causal de entrada ou saída.',
      count(*)
    from public.skpe_strategic_objectives objective
    where objective.formulation_id = target_formulation_id
      and objective.status = 'active'
      and active_objective_count > 1
      and not exists (
        select 1
        from public.skpe_objective_relations relation
        where relation.formulation_id = target_formulation_id
          and (
            relation.source_objective_id = objective.id
            or relation.target_objective_id = objective.id
          )
      )
    having count(*) > 0

    union all

    select
      'OBJECTIVE_WITHOUT_INDICATOR',
      'recommendation',
      'later_stage',
      'Existem Objetivos sem KPI. O vínculo será tratado na etapa de Indicadores e Metas.',
      count(*)
    from public.skpe_strategic_objectives objective
    where objective.formulation_id = target_formulation_id
      and objective.status = 'active'
      and not exists (
        select 1
        from public.skpe_indicators indicator
        where indicator.strategic_objective_id = objective.id
          and indicator.indicator_scope = 'strategic_kpi'
          and indicator.status <> 'archived'
      )
    having count(*) > 0

    union all

    select
      'OBJECTIVE_WITHOUT_OWNER',
      'recommendation',
      'content',
      'Existem Objetivos ativos sem responsável indicado.',
      count(*)
    from public.skpe_strategic_objectives objective
    where objective.formulation_id = target_formulation_id
      and objective.status = 'active'
      and coalesce(package_row.owner_recommended, true)
      and objective.owner_user_id is null
    having count(*) > 0

    union all

    select
      'CAUSAL_CYCLE_WARNING',
      'recommendation',
      'content',
      'Foram encontrados ciclos causais. Revise se representam retroalimentação legítima ou incoerência lógica.',
      cycle_count::bigint
    where cycle_count > 0
      and coalesce(package_row.causal_cycle_policy, 'warn') = 'warn'

    union all

    select
      'PERSPECTIVE_CONCENTRATION_HIGH',
      'recommendation',
      'content',
      'Mais de 60% dos Objetivos ativos estão concentrados em uma única Perspectiva.',
      max(perspective_count)
    from (
      select count(*)::bigint as perspective_count
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = target_formulation_id
        and objective.status = 'active'
        and objective.perspective_id is not null
      group by objective.perspective_id
    ) concentration
    having active_objective_count >= 4
       and max(perspective_count) > active_objective_count * 0.60

    union all

    select
      'OBJECTIVE_SCOPE_REVIEW',
      'recommendation',
      'content',
      'Existem Objetivos com redação muito extensa. Recomenda-se revisar foco, clareza e amplitude estratégica.',
      count(*)
    from public.skpe_strategic_objectives objective
    where objective.formulation_id = target_formulation_id
      and objective.status = 'active'
      and (
        length(objective.name) > 160
        or length(coalesce(objective.description, '')) > 1200
      )
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
    'strategicMapPackageId', package_row.id,
    'packageStatus', coalesce(package_row.status, 'not_created'),
    'readyForValidation', content_blocking_count = 0,
    'validated', coalesce(package_row.status = 'validated', false),
    'readyForFormulation',
      content_blocking_count = 0
      and coalesce(package_row.status = 'validated', false),
    'contentBlockingIssueCount', content_blocking_count,
    'blockingIssueCount', total_blocking_count,
    'counts', counts,
    'issues', issues,
    'methodologyRules', jsonb_build_object(
      'themeRequired', coalesce(package_row.theme_required, true),
      'perspectiveRequired', true,
      'expectedResultRequired', true,
      'rationaleRequired', true,
      'causalCyclePolicy', coalesce(package_row.causal_cycle_policy, 'warn'),
      'ownerRecommended', coalesce(package_row.owner_recommended, true),
      'indicatorRequiredInFe04', false,
      'okrRequiredInFe04', false,
      'initiativeRequiredInFe04', false
    )
  );
end;
$$;

-- ============================================================
-- 10. VALIDAÇÃO DO PACOTE DA FE-04
-- ============================================================

create or replace function public.transition_skpe_strategic_map(
  target_formulation_id uuid,
  transition_action text,
  decision_notes text default null,
  change_reason text default null
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
  previous_package public.skpe_strategic_map_packages%rowtype;
  updated_package public.skpe_strategic_map_packages%rowtype;
  readiness jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  normalized_action := lower(trim(coalesce(transition_action, '')));

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if formulation_row.status not in ('draft', 'in_elaboration') then
    raise exception
      'A versão da Formulação deve permanecer em rascunho ou elaboração durante a validação do pacote FE-04.'
      using errcode = '55000';
  end if;

  select *
  into previous_package
  from public.skpe_strategic_map_packages
  where formulation_id = target_formulation_id
  for update;

  if not found then
    if normalized_action = 'submit_validation' then
      if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
        raise exception 'Acesso negado para criar e submeter o Mapa Estratégico.'
          using errcode = '42501';
      end if;

      package_id := public.ensure_skpe_strategic_map_package(
        target_formulation_id
      );

      select *
      into previous_package
      from public.skpe_strategic_map_packages
      where id = package_id
      for update;
    else
      raise exception 'O pacote do Mapa Estratégico ainda não foi criado.'
        using errcode = '22023';
    end if;
  end if;

  if normalized_action = 'submit_validation' then
    if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para submeter o Mapa Estratégico à validação.'
        using errcode = '42501';
    end if;

    if previous_package.status <> 'in_elaboration' then
      raise exception 'O Mapa Estratégico deve estar em elaboração para ser submetido.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_strategic_map_readiness(
      target_formulation_id
    );

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'O Mapa Estratégico possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_strategic_map_packages
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

    update public.skpe_strategic_objectives
    set
      validation_status = 'pending_validation',
      updated_by = auth.uid()
    where formulation_id = target_formulation_id
      and status <> 'archived';

  elsif normalized_action = 'validate' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para validar o Mapa Estratégico.'
        using errcode = '42501';
    end if;

    if previous_package.status <> 'pending_validation' then
      raise exception 'Somente um Mapa pendente de validação pode ser validado.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_strategic_map_readiness(
      target_formulation_id
    );

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception 'O Mapa Estratégico possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_strategic_map_packages
    set
      status = 'validated',
      validation_notes = decision_notes,
      validated_at = timezone('utc', now()),
      validated_by = auth.uid(),
      updated_by = auth.uid()
    where id = previous_package.id
    returning *
    into updated_package;

    update public.skpe_strategic_objectives
    set
      validation_status = 'validated',
      updated_by = auth.uid()
    where formulation_id = target_formulation_id
      and status <> 'archived';

  elsif normalized_action = 'return_for_adjustments' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para devolver o Mapa para ajustes.'
        using errcode = '42501';
    end if;

    if previous_package.status not in ('pending_validation', 'validated') then
      raise exception 'O Mapa não está em situação que permita devolução.'
        using errcode = '55000';
    end if;

    if length(trim(coalesce(decision_notes, ''))) < 10 then
      raise exception 'Informe as orientações para ajuste, com no mínimo 10 caracteres.'
        using errcode = '22023';
    end if;

    update public.skpe_strategic_map_packages
    set
      status = 'in_elaboration',
      validation_notes = decision_notes,
      submitted_for_validation_at = null,
      submitted_for_validation_by = null,
      validated_at = null,
      validated_by = null,
      updated_by = auth.uid()
    where id = previous_package.id
    returning *
    into updated_package;

    update public.skpe_strategic_objectives
    set
      validation_status = 'draft',
      approved_at = null,
      approved_by = null,
      updated_by = auth.uid()
    where formulation_id = target_formulation_id
      and status <> 'archived';

  else
    raise exception
      'Transição inválida. Use submit_validation, validate ou return_for_adjustments.'
      using errcode = '22023';
  end if;

  perform public.skpe_record_operational_audit(
    updated_package.organization_id,
    updated_package.project_id,
    'strategic_map_package',
    updated_package.id,
    'strategic_map_' || normalized_action,
    change_reason,
    to_jsonb(previous_package),
    to_jsonb(updated_package)
  );

  return jsonb_build_object(
    'formulationId', target_formulation_id,
    'strategicMapPackageId', updated_package.id,
    'previousStatus', previous_package.status,
    'currentStatus', updated_package.status,
    'transitionAction', normalized_action
  );
end;
$$;

-- ============================================================
-- 11. BLOQUEIO INTEGRADO DA FORMULAÇÃO
-- ============================================================

create or replace function public.skpe_guard_formulation_strategic_map_ready()
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

  readiness := public.get_skpe_strategic_map_readiness(new.id);

  if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
    raise exception
      'A Formulação não pode avançar: o Mapa Estratégico possui pendências bloqueantes.'
      using errcode = '55000', detail = readiness::text;
  end if;

  if not coalesce((readiness ->> 'readyForFormulation')::boolean, false) then
    raise exception
      'A Formulação não pode avançar: valide o pacote de Temas, Perspectivas, Objetivos e relações causais.'
      using errcode = '55000', detail = readiness::text;
  end if;

  return new;
end;
$$;

comment on function public.skpe_guard_formulation_strategic_map_ready() is
  'Impede o avanço da Formulação enquanto a FE-04 estiver incompleta ou não validada.';

drop trigger if exists skpe_strategic_formulations_guard_strategic_map_ready
  on public.skpe_strategic_formulations;

create trigger skpe_strategic_formulations_guard_strategic_map_ready
before update of status on public.skpe_strategic_formulations
for each row
execute function public.skpe_guard_formulation_strategic_map_ready();

-- ============================================================
-- 12. CONSULTA CONSOLIDADA DO MAPA ESTRATÉGICO
-- ============================================================

create or replace function public.get_skpe_strategic_map(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_strategic_map_packages%rowtype;
  readiness jsonb;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado ao Mapa Estratégico.'
      using errcode = '42501';
  end if;

  select *
  into package_row
  from public.skpe_strategic_map_packages
  where formulation_id = target_formulation_id;

  readiness := public.get_skpe_strategic_map_readiness(
    target_formulation_id
  );

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
      else jsonb_build_object(
        'id', package_row.id,
        'status', package_row.status,
        'themeRequired', package_row.theme_required,
        'causalCyclePolicy', package_row.causal_cycle_policy,
        'ownerRecommended', package_row.owner_recommended,
        'validationNotes', package_row.validation_notes,
        'submittedForValidationAt', package_row.submitted_for_validation_at,
        'validatedAt', package_row.validated_at,
        'metadata', package_row.metadata,
        'createdAt', package_row.created_at,
        'updatedAt', package_row.updated_at
      )
    end,
    'themes', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', theme.id,
          'code', theme.code,
          'name', theme.name,
          'description', theme.description,
          'rationale', theme.rationale,
          'priority', theme.priority,
          'displayOrder', theme.display_order,
          'horizonStart', theme.horizon_start,
          'horizonEnd', theme.horizon_end,
          'ownerUserId', theme.owner_user_id,
          'status', theme.status,
          'visualColor', theme.metadata ->> 'visualColor',
          'metadata', theme.metadata,
          'createdAt', theme.created_at,
          'updatedAt', theme.updated_at
        )
        order by theme.display_order, theme.code
      )
      from public.skpe_strategic_themes theme
      where theme.formulation_id = target_formulation_id
        and theme.status <> 'archived'
    ), '[]'::jsonb),
    'perspectives', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', perspective.id,
          'code', perspective.code,
          'name', perspective.name,
          'description', perspective.description,
          'displayOrder', perspective.display_order,
          'status', perspective.status,
          'methodologicalNature',
            perspective.metadata ->> 'methodologicalNature',
          'perspectiveModel', perspective.metadata ->> 'perspectiveModel',
          'visualColor', perspective.metadata ->> 'visualColor',
          'metadata', perspective.metadata,
          'createdAt', perspective.created_at,
          'updatedAt', perspective.updated_at
        )
        order by perspective.display_order, perspective.code
      )
      from public.skpe_bsc_perspectives perspective
      where perspective.formulation_id = target_formulation_id
        and perspective.status <> 'archived'
    ), '[]'::jsonb),
    'objectives', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', objective.id,
          'code', objective.code,
          'title', objective.name,
          'description', objective.description,
          'expectedResult', objective.expected_result,
          'rationale', objective.rationale,
          'priority', objective.priority,
          'horizonStart', objective.horizon_start,
          'horizonEnd', objective.horizon_end,
          'ownerUserId', objective.owner_user_id,
          'status', objective.status,
          'validationStatus', objective.validation_status,
          'progress', objective.progress,
          'strategicThemeId', objective.strategic_theme_id,
          'perspectiveId', objective.perspective_id,
          'displayOrder', case
            when jsonb_typeof(objective.metadata -> 'displayOrder') = 'number'
              then (objective.metadata ->> 'displayOrder')::integer
            else 100
          end,
          'mapPosition', objective.metadata -> 'mapPosition',
          'visualColor', objective.metadata ->> 'visualColor',
          'metadata', objective.metadata,
          'createdAt', objective.created_at,
          'updatedAt', objective.updated_at
        )
        order by
          perspective.display_order,
          case
            when jsonb_typeof(objective.metadata -> 'displayOrder') = 'number'
              then (objective.metadata ->> 'displayOrder')::integer
            else 100
          end,
          objective.code
      )
      from public.skpe_strategic_objectives objective
      left join public.skpe_bsc_perspectives perspective
        on perspective.id = objective.perspective_id
      where objective.formulation_id = target_formulation_id
        and objective.status <> 'archived'
    ), '[]'::jsonb),
    'relations', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', relation.id,
          'sourceObjectiveId', relation.source_objective_id,
          'targetObjectiveId', relation.target_objective_id,
          'relationType', relation.relation_type,
          'contributionStrength', relation.contribution_strength,
          'relationWeight', relation.metadata -> 'relationWeight',
          'rationale', relation.rationale,
          'displayOrder', relation.display_order,
          'metadata', relation.metadata,
          'createdAt', relation.created_at
        )
        order by relation.display_order, relation.id
      )
      from public.skpe_objective_relations relation
      where relation.formulation_id = target_formulation_id
    ), '[]'::jsonb),
    'readiness', readiness
  );
end;
$$;

create or replace function public.get_skpe_strategic_map_audit(
  target_formulation_id uuid
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
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Acesso negado ao histórico do Mapa Estratégico.'
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
      'strategic_map_package',
      'strategic_theme',
      'bsc_perspective',
      'strategic_objective',
      'objective_relation'
    )
    and (
      audit.previous_data ->> 'formulation_id' = target_formulation_id::text
      or audit.new_data ->> 'formulation_id' = target_formulation_id::text
    )
  order by audit.occurred_at desc, audit.id desc;
end;
$$;

-- ============================================================
-- 13. RLS, PRIVILÉGIOS DE TABELAS E AUDITORIA
-- ============================================================

-- A auditoria operacional passa a reconhecer também o domínio legítimo
-- da Formulação Estratégica, sem conceder qualquer escrita direta.
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
on table public.skpe_strategic_map_packages,
             public.skpe_strategic_themes,
             public.skpe_bsc_perspectives,
             public.skpe_strategic_objectives,
             public.skpe_objective_relations
from public;

revoke all
on table public.skpe_strategic_map_packages
from anon;

revoke insert, update, delete
on table public.skpe_strategic_map_packages,
             public.skpe_strategic_themes,
             public.skpe_bsc_perspectives,
             public.skpe_strategic_objectives,
             public.skpe_objective_relations
from anon, authenticated;

grant select
on table public.skpe_strategic_map_packages,
             public.skpe_strategic_themes,
             public.skpe_bsc_perspectives,
             public.skpe_strategic_objectives,
             public.skpe_objective_relations
  to authenticated, service_role;

grant insert, update, delete
on table public.skpe_strategic_map_packages,
             public.skpe_strategic_themes,
             public.skpe_bsc_perspectives,
             public.skpe_strategic_objectives,
             public.skpe_objective_relations
  to service_role;

-- ============================================================
-- 14. PRIVILÉGIOS DAS FUNÇÕES
-- ============================================================

revoke all on function public.ensure_skpe_strategic_map_package(uuid)
  from public, anon, authenticated;
revoke all on function public.skpe_invalidate_strategic_map_package(uuid, text)
  from public, anon, authenticated;
revoke all on function public.skpe_objective_relation_would_create_cycle(
  uuid, uuid, uuid, uuid
) from public, anon, authenticated;
revoke all on function public.skpe_guard_formulation_strategic_map_ready()
  from public, anon, authenticated;

revoke all on function public.configure_skpe_strategic_map(
  uuid, boolean, text, boolean, jsonb, text
) from public, anon;
revoke all on function public.upsert_skpe_strategic_theme(
  uuid, text, text, text, text, uuid, text, integer,
  date, date, uuid, text, text, jsonb, text
) from public, anon;
revoke all on function public.archive_skpe_strategic_theme(uuid, text)
  from public, anon;
revoke all on function public.upsert_skpe_bsc_perspective(
  uuid, text, text, text, uuid, integer, text, text,
  text, text, jsonb, text
) from public, anon;
revoke all on function public.archive_skpe_bsc_perspective(uuid, text)
  from public, anon;
revoke all on function public.upsert_skpe_strategic_objective(
  uuid, text, text, text, text, text, uuid, uuid, uuid,
  text, date, date, uuid, text, integer, jsonb, text, jsonb, text
) from public, anon;
revoke all on function public.archive_skpe_strategic_objective(uuid, text)
  from public, anon;
revoke all on function public.upsert_skpe_objective_relation(
  uuid, uuid, uuid, text, text, numeric, text, integer,
  uuid, jsonb, text
) from public, anon;
revoke all on function public.delete_skpe_objective_relation(uuid, text)
  from public, anon;
revoke all on function public.get_skpe_strategic_map_readiness(uuid)
  from public, anon;
revoke all on function public.transition_skpe_strategic_map(
  uuid, text, text, text
) from public, anon;
revoke all on function public.get_skpe_strategic_map(uuid)
  from public, anon;
revoke all on function public.get_skpe_strategic_map_audit(uuid)
  from public, anon;

grant execute on function public.configure_skpe_strategic_map(
  uuid, boolean, text, boolean, jsonb, text
) to authenticated, service_role;
grant execute on function public.upsert_skpe_strategic_theme(
  uuid, text, text, text, text, uuid, text, integer,
  date, date, uuid, text, text, jsonb, text
) to authenticated, service_role;
grant execute on function public.archive_skpe_strategic_theme(uuid, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_bsc_perspective(
  uuid, text, text, text, uuid, integer, text, text,
  text, text, jsonb, text
) to authenticated, service_role;
grant execute on function public.archive_skpe_bsc_perspective(uuid, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_strategic_objective(
  uuid, text, text, text, text, text, uuid, uuid, uuid,
  text, date, date, uuid, text, integer, jsonb, text, jsonb, text
) to authenticated, service_role;
grant execute on function public.archive_skpe_strategic_objective(uuid, text)
  to authenticated, service_role;
grant execute on function public.upsert_skpe_objective_relation(
  uuid, uuid, uuid, text, text, numeric, text, integer,
  uuid, jsonb, text
) to authenticated, service_role;
grant execute on function public.delete_skpe_objective_relation(uuid, text)
  to authenticated, service_role;
grant execute on function public.get_skpe_strategic_map_readiness(uuid)
  to authenticated, service_role;
grant execute on function public.transition_skpe_strategic_map(
  uuid, text, text, text
) to authenticated, service_role;
grant execute on function public.get_skpe_strategic_map(uuid)
  to authenticated, service_role;
grant execute on function public.get_skpe_strategic_map_audit(uuid)
  to authenticated, service_role;

grant execute on function public.ensure_skpe_strategic_map_package(uuid)
  to service_role;
grant execute on function public.skpe_invalidate_strategic_map_package(uuid, text)
  to service_role;
grant execute on function public.skpe_objective_relation_would_create_cycle(
  uuid, uuid, uuid, uuid
) to service_role;
grant execute on function public.skpe_guard_formulation_strategic_map_ready()
  to service_role;

commit;
