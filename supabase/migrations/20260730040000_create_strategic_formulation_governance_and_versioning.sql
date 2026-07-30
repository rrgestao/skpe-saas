-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-01 — Governança, versionamento e operações auditadas
--          da Formulação Estratégica
--
-- Escopo:
-- 1. Ciclo de vida controlado da Formulação Estratégica.
-- 2. Criação, atualização, submissão, validação e aprovação por RPC.
-- 3. Revisões com clonagem estruturada do conteúdo da versão anterior.
-- 4. Imutabilidade fora dos estados de elaboração.
-- 5. Auditoria obrigatória com justificativa.
-- 6. Correção das unicidades legadas para permitir múltiplas versões.
-- 7. Histórico consultável e seleção explícita de projeto.
--
-- Observação:
-- As iniciativas não são clonadas entre versões da Formulação.
-- Elas permanecem como objetos operacionais e poderão ser vinculadas
-- novamente aos novos OEs/KRs após validação da revisão.
-- ============================================================

begin;

-- ============================================================
-- 1. METADADOS DO CICLO DE VIDA
-- ============================================================

alter table public.skpe_strategic_formulations
  add column if not exists status_changed_at timestamptz
    not null default timezone('utc', now()),
  add column if not exists status_changed_by uuid
    references public.profiles(id) on delete set null,
  add column if not exists submitted_for_validation_at timestamptz,
  add column if not exists submitted_for_validation_by uuid
    references public.profiles(id) on delete set null,
  add column if not exists validated_at timestamptz,
  add column if not exists validated_by uuid
    references public.profiles(id) on delete set null,
  add column if not exists validation_notes text,
  add column if not exists submitted_for_approval_at timestamptz,
  add column if not exists submitted_for_approval_by uuid
    references public.profiles(id) on delete set null,
  add column if not exists approval_notes text,
  add column if not exists archived_at timestamptz,
  add column if not exists archived_by uuid
    references public.profiles(id) on delete set null;

comment on column public.skpe_strategic_formulations.status_changed_at is
  'Data e hora da última transição formal de situação da versão.';

comment on column public.skpe_strategic_formulations.status_changed_by is
  'Usuário responsável pela última transição formal de situação.';

comment on column public.skpe_strategic_formulations.validation_notes is
  'Registro sintético da decisão de validação ou devolução para ajustes.';

comment on column public.skpe_strategic_formulations.approval_notes is
  'Registro sintético da decisão de aprovação ou devolução para ajustes.';

-- ============================================================
-- 2. UNICIDADE COMPATÍVEL COM VERSIONAMENTO
-- ============================================================

do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'skpe_strategic_objectives_unique_code'
      and conrelid = 'public.skpe_strategic_objectives'::regclass
  ) then
    alter table public.skpe_strategic_objectives
      drop constraint skpe_strategic_objectives_unique_code;
  end if;

  if exists (
    select 1
    from pg_constraint
    where conname = 'skpe_indicators_unique'
      and conrelid = 'public.skpe_indicators'::regclass
  ) then
    alter table public.skpe_indicators
      drop constraint skpe_indicators_unique;
  end if;
end;
$$;

create unique index if not exists ux_skpe_objectives_formulation_code
  on public.skpe_strategic_objectives(formulation_id, code)
  where formulation_id is not null;

create unique index if not exists ux_skpe_objectives_legacy_project_code
  on public.skpe_strategic_objectives(project_id, code)
  where formulation_id is null;

create unique index if not exists ux_skpe_indicators_formulation_code
  on public.skpe_indicators(formulation_id, code)
  where formulation_id is not null;

create unique index if not exists ux_skpe_indicators_legacy_project_code
  on public.skpe_indicators(project_id, code)
  where formulation_id is null;

-- ============================================================
-- 3. VALIDAÇÃO DE EDITABILIDADE
-- ============================================================

create or replace function public.skpe_assert_formulation_editable(
  target_formulation_id uuid
)
returns void
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

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception
      'Acesso negado: o usuário não pode alterar esta Formulação Estratégica.'
      using errcode = '42501';
  end if;

  if formulation_row.status not in ('draft', 'in_elaboration') then
    raise exception
      'A versão da Formulação Estratégica está bloqueada para edição na situação "%". Retorne-a para elaboração ou crie uma revisão.',
      formulation_row.status
      using errcode = '55000';
  end if;
end;
$$;

comment on function public.skpe_assert_formulation_editable(uuid) is
  'Valida existência, autorização e situação editável da Formulação. Função interna para RPCs operacionais.';

-- A proteção anteriormente limitada às versões aprovadas passa a
-- bloquear qualquer conteúdo fora dos estados draft/in_elaboration.
create or replace function public.skpe_guard_approved_formulation_content()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_formulation_id uuid;
  formulation_status text;
begin
  if tg_op = 'DELETE' then
    target_formulation_id := old.formulation_id;
  else
    target_formulation_id := new.formulation_id;
  end if;

  -- Registros legados ainda não vinculados a uma versão permanecem
  -- fora desta trava até sua migração controlada.
  if target_formulation_id is null then
    if tg_op = 'DELETE' then
      return old;
    end if;
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

  if formulation_status not in ('draft', 'in_elaboration') then
    raise exception
      'O conteúdo da Formulação Estratégica está bloqueado na situação "%".',
      formulation_status
      using errcode = '55000';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

comment on function public.skpe_guard_approved_formulation_content() is
  'Bloqueia alterações do conteúdo enquanto a Formulação estiver em validação, validada, em aprovação, aprovada, substituída ou arquivada.';

-- ============================================================
-- 4. CLONAGEM ESTRUTURADA DE UMA REVISÃO
-- ============================================================

create or replace function public.clone_skpe_formulation_content(
  source_formulation_id uuid,
  target_formulation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  source_formulation public.skpe_strategic_formulations%rowtype;
  target_formulation public.skpe_strategic_formulations%rowtype;
  source_identity_id uuid;
  target_identity_id uuid;

  count_identity integer := 0;
  count_identity_items integer := 0;
  count_values integer := 0;
  count_value_behaviors integer := 0;
  count_business_inputs integer := 0;
  count_themes integer := 0;
  count_perspectives integer := 0;
  count_objectives integer := 0;
  count_objective_relations integer := 0;
  count_okr_cycles integer := 0;
  count_okrs integer := 0;
  count_okr_objectives integer := 0;
  count_key_results integer := 0;
  count_indicators integer := 0;
  count_targets integer := 0;
  count_benchmarks integer := 0;
begin
  select *
  into source_formulation
  from public.skpe_strategic_formulations
  where id = source_formulation_id;

  if not found then
    raise exception 'Formulação de origem não encontrada.'
      using errcode = '22023';
  end if;

  select *
  into target_formulation
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Formulação de destino não encontrada.'
      using errcode = '22023';
  end if;

  if source_formulation.organization_id <> target_formulation.organization_id
     or source_formulation.project_id <> target_formulation.project_id then
    raise exception
      'A origem e o destino da revisão devem pertencer à mesma organização e ao mesmo projeto.'
      using errcode = '22023';
  end if;

  if source_formulation.status not in ('approved', 'superseded') then
    raise exception
      'Somente versões aprovadas ou substituídas podem originar uma revisão.'
      using errcode = '55000';
  end if;

  perform public.skpe_assert_formulation_editable(target_formulation_id);

  -- Identidade Estratégica
  select identity.id
  into source_identity_id
  from public.skpe_strategic_identity identity
  where identity.formulation_id = source_formulation_id;

  if source_identity_id is not null then
    insert into public.skpe_strategic_identity (
      organization_id,
      project_id,
      formulation_id,
      status,
      coherence_statement,
      validation_notes,
      metadata,
      created_by,
      updated_by
    )
    select
      target_formulation.organization_id,
      target_formulation.project_id,
      target_formulation.id,
      'draft',
      identity.coherence_statement,
      null,
      coalesce(identity.metadata, '{}'::jsonb)
        || jsonb_build_object(
          'clonedFromIdentityId', identity.id,
          'clonedFromFormulationId', source_formulation.id
        ),
      auth.uid(),
      auth.uid()
    from public.skpe_strategic_identity identity
    where identity.id = source_identity_id
    returning id into target_identity_id;

    get diagnostics count_identity = row_count;

    insert into public.skpe_strategic_identity_items (
      organization_id,
      project_id,
      formulation_id,
      strategic_identity_id,
      element_type,
      content,
      rationale,
      display_order,
      validation_status,
      metadata,
      created_by,
      updated_by
    )
    select
      target_formulation.organization_id,
      target_formulation.project_id,
      target_formulation.id,
      target_identity_id,
      item.element_type,
      item.content,
      item.rationale,
      item.display_order,
      'draft',
      coalesce(item.metadata, '{}'::jsonb)
        || jsonb_build_object('clonedFromId', item.id),
      auth.uid(),
      auth.uid()
    from public.skpe_strategic_identity_items item
    where item.formulation_id = source_formulation_id;

    get diagnostics count_identity_items = row_count;

    insert into public.skpe_strategic_values (
      organization_id,
      project_id,
      formulation_id,
      strategic_identity_id,
      code,
      name,
      description,
      display_order,
      status,
      metadata,
      created_by,
      updated_by
    )
    select
      target_formulation.organization_id,
      target_formulation.project_id,
      target_formulation.id,
      target_identity_id,
      value.code,
      value.name,
      value.description,
      value.display_order,
      'draft',
      coalesce(value.metadata, '{}'::jsonb)
        || jsonb_build_object('clonedFromId', value.id),
      auth.uid(),
      auth.uid()
    from public.skpe_strategic_values value
    where value.formulation_id = source_formulation_id
      and value.status <> 'archived';

    get diagnostics count_values = row_count;

    insert into public.skpe_strategic_value_behaviors (
      organization_id,
      project_id,
      formulation_id,
      strategic_value_id,
      behavior_type,
      description,
      display_order,
      metadata,
      created_by,
      updated_by
    )
    select
      target_formulation.organization_id,
      target_formulation.project_id,
      target_formulation.id,
      new_value.id,
      behavior.behavior_type,
      behavior.description,
      behavior.display_order,
      coalesce(behavior.metadata, '{}'::jsonb)
        || jsonb_build_object('clonedFromId', behavior.id),
      auth.uid(),
      auth.uid()
    from public.skpe_strategic_value_behaviors behavior
    join public.skpe_strategic_values old_value
      on old_value.id = behavior.strategic_value_id
    join public.skpe_strategic_values new_value
      on new_value.formulation_id = target_formulation.id
     and new_value.code = old_value.code
    where behavior.formulation_id = source_formulation_id;

    get diagnostics count_value_behaviors = row_count;
  end if;

  -- Insumos compartilhados de negócio: reutiliza as mesmas versões
  -- e preserva o snapshot histórico usado na Formulação anterior.
  insert into public.skpe_formulation_business_inputs (
    organization_id,
    project_id,
    formulation_id,
    artifact_id,
    artifact_version_id,
    input_role,
    usage_mode,
    requirement_level,
    is_primary,
    status,
    source_version_number,
    snapshot_payload,
    snapshot_schema_version,
    snapshot_captured_at,
    gap_summary,
    handoff_to_skpn_recommended,
    handoff_notes,
    metadata,
    created_by,
    updated_by
  )
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    input.artifact_id,
    input.artifact_version_id,
    input.input_role,
    input.usage_mode,
    input.requirement_level,
    input.is_primary,
    'active',
    input.source_version_number,
    input.snapshot_payload,
    input.snapshot_schema_version,
    timezone('utc', now()),
    input.gap_summary,
    input.handoff_to_skpn_recommended,
    input.handoff_notes,
    coalesce(input.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', input.id),
    auth.uid(),
    auth.uid()
  from public.skpe_formulation_business_inputs input
  where input.formulation_id = source_formulation_id
    and input.status = 'active';

  get diagnostics count_business_inputs = row_count;

  -- Temas Estratégicos
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
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    theme.code,
    theme.name,
    theme.description,
    theme.rationale,
    theme.horizon_start,
    theme.horizon_end,
    theme.priority,
    theme.owner_user_id,
    theme.display_order,
    'draft',
    coalesce(theme.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', theme.id),
    auth.uid(),
    auth.uid()
  from public.skpe_strategic_themes theme
  where theme.formulation_id = source_formulation_id
    and theme.status <> 'archived';

  get diagnostics count_themes = row_count;

  -- Perspectivas BSC
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
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    perspective.code,
    perspective.name,
    perspective.description,
    perspective.display_order,
    'active',
    coalesce(perspective.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', perspective.id),
    auth.uid(),
    auth.uid()
  from public.skpe_bsc_perspectives perspective
  where perspective.formulation_id = source_formulation_id
    and perspective.status <> 'archived';

  get diagnostics count_perspectives = row_count;

  -- Objetivos Estratégicos
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
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    objective.code,
    objective.name,
    objective.description,
    'bsc',
    new_perspective.code,
    objective.strategic_theme,
    objective.horizon_start,
    objective.horizon_end,
    objective.owner_user_id,
    'draft',
    0,
    coalesce(objective.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', objective.id),
    auth.uid(),
    auth.uid(),
    target_formulation.id,
    new_theme.id,
    new_perspective.id,
    objective.expected_result,
    objective.rationale,
    objective.priority,
    'draft',
    null,
    null
  from public.skpe_strategic_objectives objective
  left join public.skpe_strategic_themes old_theme
    on old_theme.id = objective.strategic_theme_id
  left join public.skpe_strategic_themes new_theme
    on new_theme.formulation_id = target_formulation.id
   and new_theme.code = old_theme.code
  left join public.skpe_bsc_perspectives old_perspective
    on old_perspective.id = objective.perspective_id
  left join public.skpe_bsc_perspectives new_perspective
    on new_perspective.formulation_id = target_formulation.id
   and new_perspective.code = old_perspective.code
  where objective.formulation_id = source_formulation_id
    and objective.status <> 'archived';

  get diagnostics count_objectives = row_count;

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
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    new_source.id,
    new_target.id,
    relation.relation_type,
    relation.contribution_strength,
    relation.rationale,
    relation.display_order,
    coalesce(relation.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', relation.id),
    auth.uid()
  from public.skpe_objective_relations relation
  join public.skpe_strategic_objectives old_source
    on old_source.id = relation.source_objective_id
  join public.skpe_strategic_objectives new_source
    on new_source.formulation_id = target_formulation.id
   and new_source.code = old_source.code
  join public.skpe_strategic_objectives old_target
    on old_target.id = relation.target_objective_id
  join public.skpe_strategic_objectives new_target
    on new_target.formulation_id = target_formulation.id
   and new_target.code = old_target.code
  where relation.formulation_id = source_formulation_id;

  get diagnostics count_objective_relations = row_count;

  -- Ciclos e Objetivos do OKR
  insert into public.skpe_okr_cycles (
    organization_id,
    project_id,
    formulation_id,
    code,
    name,
    description,
    cycle_type,
    reference_year,
    period_start,
    period_end,
    owner_user_id,
    status,
    metadata,
    created_by,
    updated_by
  )
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    cycle.code,
    cycle.name,
    cycle.description,
    cycle.cycle_type,
    cycle.reference_year,
    cycle.period_start,
    cycle.period_end,
    cycle.owner_user_id,
    'draft',
    coalesce(cycle.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', cycle.id),
    auth.uid(),
    auth.uid()
  from public.skpe_okr_cycles cycle
  where cycle.formulation_id = source_formulation_id
    and cycle.status <> 'archived';

  get diagnostics count_okr_cycles = row_count;

  insert into public.skpe_okrs (
    organization_id,
    project_id,
    formulation_id,
    okr_cycle_id,
    code,
    title,
    description,
    owner_user_id,
    status,
    progress,
    display_order,
    metadata,
    created_by,
    updated_by
  )
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    new_cycle.id,
    okr.code,
    okr.title,
    okr.description,
    okr.owner_user_id,
    'draft',
    0,
    okr.display_order,
    coalesce(okr.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', okr.id),
    auth.uid(),
    auth.uid()
  from public.skpe_okrs okr
  join public.skpe_okr_cycles old_cycle
    on old_cycle.id = okr.okr_cycle_id
  join public.skpe_okr_cycles new_cycle
    on new_cycle.formulation_id = target_formulation.id
   and new_cycle.code = old_cycle.code
  where okr.formulation_id = source_formulation_id
    and okr.status <> 'cancelled';

  get diagnostics count_okrs = row_count;

  insert into public.skpe_okr_objectives (
    organization_id,
    project_id,
    formulation_id,
    okr_id,
    strategic_objective_id,
    contribution_weight,
    is_primary,
    notes,
    created_by
  )
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    new_okr.id,
    new_objective.id,
    link.contribution_weight,
    link.is_primary,
    link.notes,
    auth.uid()
  from public.skpe_okr_objectives link
  join public.skpe_okrs old_okr
    on old_okr.id = link.okr_id
  join public.skpe_okr_cycles old_cycle
    on old_cycle.id = old_okr.okr_cycle_id
  join public.skpe_okr_cycles new_cycle
    on new_cycle.formulation_id = target_formulation.id
   and new_cycle.code = old_cycle.code
  join public.skpe_okrs new_okr
    on new_okr.okr_cycle_id = new_cycle.id
   and new_okr.code = old_okr.code
  join public.skpe_strategic_objectives old_objective
    on old_objective.id = link.strategic_objective_id
  join public.skpe_strategic_objectives new_objective
    on new_objective.formulation_id = target_formulation.id
   and new_objective.code = old_objective.code
  where link.formulation_id = source_formulation_id;

  get diagnostics count_okr_objectives = row_count;

  -- Resultados-Chave
  insert into public.skpe_key_results (
    organization_id,
    project_id,
    strategic_objective_id,
    code,
    name,
    description,
    baseline_value,
    target_value,
    current_value,
    unit,
    period_start,
    period_end,
    owner_user_id,
    status,
    progress,
    metadata,
    created_by,
    updated_by,
    formulation_id,
    okr_id,
    contribution_weight,
    annualized_target,
    validation_status
  )
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    new_objective.id,
    kr.code,
    kr.name,
    kr.description,
    kr.baseline_value,
    kr.target_value,
    kr.current_value,
    kr.unit,
    kr.period_start,
    kr.period_end,
    kr.owner_user_id,
    'draft',
    0,
    coalesce(kr.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', kr.id),
    auth.uid(),
    auth.uid(),
    target_formulation.id,
    new_okr.id,
    kr.contribution_weight,
    kr.annualized_target,
    'draft'
  from public.skpe_key_results kr
  join public.skpe_strategic_objectives old_objective
    on old_objective.id = kr.strategic_objective_id
  join public.skpe_strategic_objectives new_objective
    on new_objective.formulation_id = target_formulation.id
   and new_objective.code = old_objective.code
  left join public.skpe_okrs old_okr
    on old_okr.id = kr.okr_id
  left join public.skpe_okr_cycles old_cycle
    on old_cycle.id = old_okr.okr_cycle_id
  left join public.skpe_okr_cycles new_cycle
    on new_cycle.formulation_id = target_formulation.id
   and new_cycle.code = old_cycle.code
  left join public.skpe_okrs new_okr
    on new_okr.okr_cycle_id = new_cycle.id
   and new_okr.code = old_okr.code
  where kr.formulation_id = source_formulation_id
    and kr.status <> 'cancelled';

  get diagnostics count_key_results = row_count;

  -- Indicadores
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
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    indicator.code,
    indicator.name,
    indicator.description,
    indicator.indicator_scope,
    new_indicator_objective.id,
    new_kr.id,
    indicator.formula_text,
    indicator.unit,
    indicator.polarity,
    indicator.measurement_frequency,
    indicator.data_source,
    indicator.baseline_value,
    indicator.baseline_date,
    indicator.owner_user_id,
    'draft',
    coalesce(indicator.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', indicator.id),
    auth.uid(),
    auth.uid()
  from public.skpe_indicators indicator
  left join public.skpe_strategic_objectives old_indicator_objective
    on old_indicator_objective.id = indicator.strategic_objective_id
  left join public.skpe_strategic_objectives new_indicator_objective
    on new_indicator_objective.formulation_id = target_formulation.id
   and new_indicator_objective.code = old_indicator_objective.code
  left join public.skpe_key_results old_kr
    on old_kr.id = indicator.key_result_id
  left join public.skpe_strategic_objectives old_kr_objective
    on old_kr_objective.id = old_kr.strategic_objective_id
  left join public.skpe_strategic_objectives new_kr_objective
    on new_kr_objective.formulation_id = target_formulation.id
   and new_kr_objective.code = old_kr_objective.code
  left join public.skpe_okrs old_kr_okr
    on old_kr_okr.id = old_kr.okr_id
  left join public.skpe_okr_cycles old_kr_cycle
    on old_kr_cycle.id = old_kr_okr.okr_cycle_id
  left join public.skpe_okr_cycles new_kr_cycle
    on new_kr_cycle.formulation_id = target_formulation.id
   and new_kr_cycle.code = old_kr_cycle.code
  left join public.skpe_okrs new_kr_okr
    on new_kr_okr.okr_cycle_id = new_kr_cycle.id
   and new_kr_okr.code = old_kr_okr.code
  left join public.skpe_key_results new_kr
    on new_kr.formulation_id = target_formulation.id
   and new_kr.code = old_kr.code
   and new_kr.strategic_objective_id = new_kr_objective.id
   and (
     (old_kr.okr_id is null and new_kr.okr_id is null)
     or
     (old_kr.okr_id is not null and new_kr.okr_id = new_kr_okr.id)
   )
  where indicator.formulation_id = source_formulation_id
    and indicator.status <> 'archived'
    and (
      (
        indicator.indicator_scope = 'strategic_kpi'
        and new_indicator_objective.id is not null
      )
      or
      (
        indicator.indicator_scope = 'key_result_indicator'
        and new_kr.id is not null
      )
    );

  get diagnostics count_indicators = row_count;

  -- Metas
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
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    new_indicator.id,
    target.target_type,
    target.period_start,
    target.period_end,
    target.target_value,
    target.minimum_value,
    target.challenge_value,
    target.tolerance_lower,
    target.tolerance_upper,
    target.owner_user_id,
    'draft',
    coalesce(target.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', target.id),
    auth.uid(),
    auth.uid()
  from public.skpe_indicator_targets target
  join public.skpe_indicators old_indicator
    on old_indicator.id = target.indicator_id
  join public.skpe_indicators new_indicator
    on new_indicator.formulation_id = target_formulation.id
   and new_indicator.code = old_indicator.code
  where target.formulation_id = source_formulation_id
    and target.status <> 'superseded';

  get diagnostics count_targets = row_count;

  -- BMKs
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
  select
    target_formulation.organization_id,
    target_formulation.project_id,
    target_formulation.id,
    new_indicator.id,
    new_target.id,
    benchmark.benchmark_type,
    benchmark.reference_organization,
    benchmark.source_name,
    benchmark.source_reference,
    benchmark.reference_period,
    benchmark.benchmark_value,
    benchmark.applicability,
    benchmark.gap_analysis,
    benchmark.notes,
    null,
    null,
    'draft',
    coalesce(benchmark.metadata, '{}'::jsonb)
      || jsonb_build_object('clonedFromId', benchmark.id),
    auth.uid(),
    auth.uid()
  from public.skpe_benchmark_references benchmark
  join public.skpe_indicators old_indicator
    on old_indicator.id = benchmark.indicator_id
  join public.skpe_indicators new_indicator
    on new_indicator.formulation_id = target_formulation.id
   and new_indicator.code = old_indicator.code
  left join public.skpe_indicator_targets old_target
    on old_target.id = benchmark.indicator_target_id
  left join public.skpe_indicator_targets new_target
    on new_target.indicator_id = new_indicator.id
   and new_target.target_type = old_target.target_type
   and new_target.period_start = old_target.period_start
   and new_target.period_end = old_target.period_end
  where benchmark.formulation_id = source_formulation_id
    and benchmark.status <> 'archived';

  get diagnostics count_benchmarks = row_count;

  return jsonb_build_object(
    'strategicIdentity', count_identity,
    'identityItems', count_identity_items,
    'values', count_values,
    'valueBehaviors', count_value_behaviors,
    'businessInputs', count_business_inputs,
    'strategicThemes', count_themes,
    'bscPerspectives', count_perspectives,
    'strategicObjectives', count_objectives,
    'objectiveRelations', count_objective_relations,
    'okrCycles', count_okr_cycles,
    'okrs', count_okrs,
    'okrObjectiveLinks', count_okr_objectives,
    'keyResults', count_key_results,
    'indicators', count_indicators,
    'indicatorTargets', count_targets,
    'benchmarkReferences', count_benchmarks,
    'initiativesCloned', 0,
    'initiativesRequireRelinking', true
  );
end;
$$;

comment on function public.clone_skpe_formulation_content(uuid, uuid) is
  'Clona o conteúdo estruturado de uma versão aprovada/substituída para uma nova revisão editável. Não clona iniciativas.';

-- ============================================================
-- 5. CRIAÇÃO DA PRIMEIRA VERSÃO
-- ============================================================

create or replace function public.create_skpe_formulation(
  target_project_id uuid,
  version_label text,
  change_summary text default null,
  rationale text default null,
  valid_from date default null,
  valid_until date default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  project_row public.skpe_projects%rowtype;
  new_formulation public.skpe_strategic_formulations%rowtype;
  next_version integer;
begin
  perform public.skpe_assert_reason(change_reason);

  if length(trim(coalesce(version_label, ''))) = 0 then
    raise exception 'Informe o rótulo da versão da Formulação Estratégica.'
      using errcode = '22023';
  end if;

  if valid_until is not null
     and valid_from is not null
     and valid_until < valid_from then
    raise exception 'A data final da vigência não pode ser anterior à data inicial.'
      using errcode = '22023';
  end if;

  select *
  into project_row
  from public.skpe_projects
  where id = target_project_id
    and archived_at is null
  for update;

  if not found then
    raise exception 'Projeto estratégico não encontrado ou arquivado.'
      using errcode = '22023';
  end if;

  if not public.can_manage_skpe_formulation(project_row.organization_id) then
    raise exception
      'Acesso negado: o usuário não pode criar a Formulação Estratégica deste projeto.'
      using errcode = '42501';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_project_id::text, 0)
  );

  if exists (
    select 1
    from public.skpe_strategic_formulations formulation
    where formulation.project_id = target_project_id
      and formulation.status in (
        'draft',
        'in_elaboration',
        'pending_validation',
        'validated',
        'pending_approval'
      )
  ) then
    raise exception
      'Já existe uma versão aberta da Formulação Estratégica para este projeto.'
      using errcode = '23505';
  end if;

  if exists (
    select 1
    from public.skpe_strategic_formulations formulation
    where formulation.project_id = target_project_id
      and formulation.status in ('approved', 'superseded')
  ) then
    raise exception
      'O projeto já possui histórico aprovado. Crie uma revisão derivada da versão aprovada vigente.'
      using errcode = '55000';
  end if;

  select coalesce(max(formulation.version_number), 0) + 1
  into next_version
  from public.skpe_strategic_formulations formulation
  where formulation.project_id = target_project_id;

  insert into public.skpe_strategic_formulations (
    organization_id,
    project_id,
    version_number,
    version_label,
    status,
    change_summary,
    rationale,
    valid_from,
    valid_until,
    status_changed_at,
    status_changed_by,
    metadata,
    created_by,
    updated_by
  )
  values (
    project_row.organization_id,
    project_row.id,
    next_version,
    trim(version_label),
    'draft',
    change_summary,
    rationale,
    coalesce(valid_from, project_row.valid_from),
    coalesce(valid_until, project_row.valid_until),
    timezone('utc', now()),
    auth.uid(),
    '{}'::jsonb,
    auth.uid(),
    auth.uid()
  )
  returning *
  into new_formulation;

  perform public.skpe_record_operational_audit(
    new_formulation.organization_id,
    new_formulation.project_id,
    'strategic_formulation',
    new_formulation.id,
    'formulation_created',
    change_reason,
    null,
    to_jsonb(new_formulation)
  );

  return new_formulation.id;
end;
$$;

comment on function public.create_skpe_formulation(uuid, text, text, text, date, date, text) is
  'Cria a primeira versão independente da Formulação. Após existir histórico aprovado, novas versões devem ser revisões derivadas.';

-- ============================================================
-- 6. ATUALIZAÇÃO DO CABEÇALHO DA VERSÃO
-- ============================================================

create or replace function public.update_skpe_formulation(
  target_formulation_id uuid,
  new_version_label text,
  new_change_summary text,
  new_rationale text,
  new_valid_from date,
  new_valid_until date,
  new_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_formulation public.skpe_strategic_formulations%rowtype;
  updated_formulation public.skpe_strategic_formulations%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_formulation
  from public.skpe_strategic_formulations
  where id = target_formulation_id
  for update;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(target_formulation_id);

  if length(trim(coalesce(new_version_label, ''))) = 0 then
    raise exception 'Informe o rótulo da versão da Formulação Estratégica.'
      using errcode = '22023';
  end if;

  if new_valid_until is not null
     and new_valid_from is not null
     and new_valid_until < new_valid_from then
    raise exception 'A data final da vigência não pode ser anterior à data inicial.'
      using errcode = '22023';
  end if;

  if new_metadata is not null and jsonb_typeof(new_metadata) <> 'object' then
    raise exception 'Os metadados da Formulação devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  update public.skpe_strategic_formulations
  set
    version_label = trim(new_version_label),
    change_summary = new_change_summary,
    rationale = new_rationale,
    valid_from = new_valid_from,
    valid_until = new_valid_until,
    metadata = coalesce(new_metadata, metadata),
    updated_by = auth.uid()
  where id = target_formulation_id
  returning *
  into updated_formulation;

  perform public.skpe_record_operational_audit(
    updated_formulation.organization_id,
    updated_formulation.project_id,
    'strategic_formulation',
    updated_formulation.id,
    'formulation_header_updated',
    change_reason,
    to_jsonb(previous_formulation),
    to_jsonb(updated_formulation)
  );

  return updated_formulation.id;
end;
$$;

-- ============================================================
-- 7. REVISÃO DERIVADA COM CLONAGEM DO CONTEÚDO
-- ============================================================

create or replace function public.create_skpe_formulation_revision(
  source_formulation_id uuid,
  version_label text,
  change_summary text,
  new_valid_from date default null,
  new_valid_until date default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  source_formulation public.skpe_strategic_formulations%rowtype;
  new_formulation public.skpe_strategic_formulations%rowtype;
  next_version integer;
  clone_summary jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  if length(trim(coalesce(version_label, ''))) = 0 then
    raise exception 'Informe o rótulo da nova revisão.'
      using errcode = '22023';
  end if;

  select *
  into source_formulation
  from public.skpe_strategic_formulations
  where id = source_formulation_id
  for update;

  if not found then
    raise exception 'Formulação de origem não encontrada.'
      using errcode = '22023';
  end if;

  if not public.can_manage_skpe_formulation(source_formulation.organization_id) then
    raise exception
      'Acesso negado: o usuário não pode criar uma revisão desta Formulação.'
      using errcode = '42501';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(source_formulation.project_id::text, 0)
  );

  if source_formulation.status not in ('approved', 'superseded') then
    raise exception
      'A revisão deve ser derivada de uma versão aprovada ou substituída.'
      using errcode = '55000';
  end if;

  if exists (
    select 1
    from public.skpe_strategic_formulations current_version
    where current_version.project_id = source_formulation.project_id
      and current_version.status = 'approved'
      and current_version.id <> source_formulation.id
  ) then
    raise exception
      'Existe uma versão aprovada vigente. A revisão deve ser derivada dessa versão, e não de uma versão histórica substituída.'
      using errcode = '55000';
  end if;

  if exists (
    select 1
    from public.skpe_strategic_formulations formulation
    where formulation.project_id = source_formulation.project_id
      and formulation.status in (
        'draft',
        'in_elaboration',
        'pending_validation',
        'validated',
        'pending_approval'
      )
  ) then
    raise exception
      'Já existe uma versão aberta da Formulação Estratégica para este projeto.'
      using errcode = '23505';
  end if;

  if coalesce(new_valid_until, source_formulation.valid_until) is not null
     and coalesce(new_valid_from, source_formulation.valid_from) is not null
     and coalesce(new_valid_until, source_formulation.valid_until)
       < coalesce(new_valid_from, source_formulation.valid_from) then
    raise exception 'A data final da vigência não pode ser anterior à data inicial.'
      using errcode = '22023';
  end if;

  select coalesce(max(formulation.version_number), 0) + 1
  into next_version
  from public.skpe_strategic_formulations formulation
  where formulation.project_id = source_formulation.project_id;

  insert into public.skpe_strategic_formulations (
    organization_id,
    project_id,
    version_number,
    version_label,
    status,
    change_summary,
    rationale,
    valid_from,
    valid_until,
    derived_from_formulation_id,
    status_changed_at,
    status_changed_by,
    metadata,
    created_by,
    updated_by
  )
  values (
    source_formulation.organization_id,
    source_formulation.project_id,
    next_version,
    trim(version_label),
    'draft',
    change_summary,
    source_formulation.rationale,
    coalesce(new_valid_from, source_formulation.valid_from),
    coalesce(new_valid_until, source_formulation.valid_until),
    source_formulation.id,
    timezone('utc', now()),
    auth.uid(),
    coalesce(source_formulation.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'derivedFromFormulationId', source_formulation.id,
        'derivedFromVersionNumber', source_formulation.version_number
      ),
    auth.uid(),
    auth.uid()
  )
  returning *
  into new_formulation;

  clone_summary := public.clone_skpe_formulation_content(
    source_formulation.id,
    new_formulation.id
  );

  perform public.skpe_record_operational_audit(
    new_formulation.organization_id,
    new_formulation.project_id,
    'strategic_formulation',
    new_formulation.id,
    'formulation_revision_created',
    change_reason,
    to_jsonb(source_formulation),
    jsonb_build_object(
      'formulation', to_jsonb(new_formulation),
      'cloneSummary', clone_summary
    )
  );

  return new_formulation.id;
end;
$$;

comment on function public.create_skpe_formulation_revision(uuid, text, text, date, date, text) is
  'Cria uma revisão derivada e clona PMVV, insumos compartilhados, Temas, BSC, OEs, OKRs, KRs, indicadores, metas e BMKs.';

-- ============================================================
-- 8. TRANSIÇÕES DO CICLO DE VIDA
-- ============================================================

create or replace function public.transition_skpe_formulation(
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
  previous_formulation public.skpe_strategic_formulations%rowtype;
  updated_formulation public.skpe_strategic_formulations%rowtype;
  current_approved public.skpe_strategic_formulations%rowtype;
  superseded_formulation public.skpe_strategic_formulations%rowtype;
  readiness jsonb;
begin
  perform public.skpe_assert_reason(change_reason);

  normalized_action := lower(trim(coalesce(transition_action, '')));

  select *
  into previous_formulation
  from public.skpe_strategic_formulations
  where id = target_formulation_id
  for update;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.'
      using errcode = '22023';
  end if;

  if normalized_action = 'begin_elaboration' then
    if not public.can_manage_skpe_formulation(previous_formulation.organization_id) then
      raise exception 'Acesso negado para iniciar a elaboração.'
        using errcode = '42501';
    end if;

    if previous_formulation.status <> 'draft' then
      raise exception 'Somente uma versão em rascunho pode iniciar a elaboração.'
        using errcode = '55000';
    end if;

    update public.skpe_strategic_formulations
    set
      status = 'in_elaboration',
      status_changed_at = timezone('utc', now()),
      status_changed_by = auth.uid(),
      updated_by = auth.uid()
    where id = target_formulation_id
    returning * into updated_formulation;

  elsif normalized_action = 'submit_validation' then
    if not public.can_manage_skpe_formulation(previous_formulation.organization_id) then
      raise exception 'Acesso negado para submeter a Formulação à validação.'
        using errcode = '42501';
    end if;

    if previous_formulation.status not in ('draft', 'in_elaboration') then
      raise exception 'A Formulação deve estar em rascunho ou elaboração para ser submetida à validação.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_formulation_readiness(target_formulation_id);

    if not coalesce((readiness ->> 'readyForApproval')::boolean, false) then
      raise exception
        'A Formulação possui pendências bloqueantes e não pode ser submetida à validação.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_strategic_formulations
    set
      status = 'pending_validation',
      submitted_for_validation_at = timezone('utc', now()),
      submitted_for_validation_by = auth.uid(),
      status_changed_at = timezone('utc', now()),
      status_changed_by = auth.uid(),
      updated_by = auth.uid()
    where id = target_formulation_id
    returning * into updated_formulation;

  elsif normalized_action = 'validate' then
    if not public.can_validate_skpe_formulation(previous_formulation.organization_id) then
      raise exception 'Acesso negado para validar a Formulação.'
        using errcode = '42501';
    end if;

    if previous_formulation.status <> 'pending_validation' then
      raise exception 'Somente uma Formulação pendente de validação pode ser validada.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_formulation_readiness(target_formulation_id);

    if not coalesce((readiness ->> 'readyForApproval')::boolean, false) then
      raise exception
        'A Formulação possui pendências bloqueantes e não pode ser validada.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_strategic_formulations
    set
      status = 'validated',
      validated_at = timezone('utc', now()),
      validated_by = auth.uid(),
      validation_notes = decision_notes,
      status_changed_at = timezone('utc', now()),
      status_changed_by = auth.uid(),
      updated_by = auth.uid()
    where id = target_formulation_id
    returning * into updated_formulation;

  elsif normalized_action = 'return_for_adjustments' then
    if length(trim(coalesce(decision_notes, ''))) < 10 then
      raise exception
        'Informe as orientações para os ajustes, com no mínimo 10 caracteres.'
        using errcode = '22023';
    end if;

    if previous_formulation.status = 'pending_validation' then
      if not public.can_validate_skpe_formulation(previous_formulation.organization_id) then
        raise exception 'Acesso negado para devolver a Formulação em validação.'
          using errcode = '42501';
      end if;

      update public.skpe_strategic_formulations
      set
        status = 'in_elaboration',
        validation_notes = decision_notes,
        status_changed_at = timezone('utc', now()),
        status_changed_by = auth.uid(),
        updated_by = auth.uid()
      where id = target_formulation_id
      returning * into updated_formulation;

    elsif previous_formulation.status = 'pending_approval' then
      if not public.can_approve_skpe_formulation(previous_formulation.organization_id) then
        raise exception 'Acesso negado para devolver a Formulação em aprovação.'
          using errcode = '42501';
      end if;

      update public.skpe_strategic_formulations
      set
        status = 'in_elaboration',
        approval_notes = decision_notes,
        status_changed_at = timezone('utc', now()),
        status_changed_by = auth.uid(),
        updated_by = auth.uid()
      where id = target_formulation_id
      returning * into updated_formulation;

    else
      raise exception
        'Somente Formulações pendentes de validação ou aprovação podem ser devolvidas para ajustes.'
        using errcode = '55000';
    end if;

  elsif normalized_action = 'submit_approval' then
    if not public.can_validate_skpe_formulation(previous_formulation.organization_id) then
      raise exception 'Acesso negado para submeter a Formulação à aprovação.'
        using errcode = '42501';
    end if;

    if previous_formulation.status <> 'validated' then
      raise exception 'Somente uma Formulação validada pode ser submetida à aprovação.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_formulation_readiness(target_formulation_id);

    if not coalesce((readiness ->> 'readyForApproval')::boolean, false) then
      raise exception
        'A Formulação possui pendências bloqueantes e não pode ser submetida à aprovação.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_strategic_formulations
    set
      status = 'pending_approval',
      submitted_for_approval_at = timezone('utc', now()),
      submitted_for_approval_by = auth.uid(),
      status_changed_at = timezone('utc', now()),
      status_changed_by = auth.uid(),
      updated_by = auth.uid()
    where id = target_formulation_id
    returning * into updated_formulation;

  elsif normalized_action = 'approve' then
    if not public.can_approve_skpe_formulation(previous_formulation.organization_id) then
      raise exception 'Acesso negado para aprovar a Formulação.'
        using errcode = '42501';
    end if;

    if previous_formulation.status <> 'pending_approval' then
      raise exception 'Somente uma Formulação pendente de aprovação pode ser aprovada.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_formulation_readiness(target_formulation_id);

    if not coalesce((readiness ->> 'readyForApproval')::boolean, false) then
      raise exception
        'A Formulação possui pendências bloqueantes e não pode ser aprovada.'
        using errcode = '55000', detail = readiness::text;
    end if;

    select *
    into current_approved
    from public.skpe_strategic_formulations
    where project_id = previous_formulation.project_id
      and status = 'approved'
      and id <> target_formulation_id
    for update;

    if found then
      update public.skpe_strategic_formulations
      set
        status = 'superseded',
        superseded_at = timezone('utc', now()),
        superseded_by = auth.uid(),
        status_changed_at = timezone('utc', now()),
        status_changed_by = auth.uid(),
        updated_by = auth.uid()
      where id = current_approved.id
      returning * into superseded_formulation;

      perform public.skpe_record_operational_audit(
        superseded_formulation.organization_id,
        superseded_formulation.project_id,
        'strategic_formulation',
        superseded_formulation.id,
        'formulation_superseded',
        change_reason,
        to_jsonb(current_approved),
        to_jsonb(superseded_formulation)
      );
    end if;

    update public.skpe_strategic_formulations
    set
      status = 'approved',
      approved_at = timezone('utc', now()),
      approved_by = auth.uid(),
      approval_notes = decision_notes,
      status_changed_at = timezone('utc', now()),
      status_changed_by = auth.uid(),
      updated_by = auth.uid()
    where id = target_formulation_id
    returning * into updated_formulation;

  elsif normalized_action = 'archive' then
    if not public.can_manage_skpe_formulation(previous_formulation.organization_id) then
      raise exception 'Acesso negado para arquivar a Formulação.'
        using errcode = '42501';
    end if;

    if previous_formulation.status not in ('draft', 'in_elaboration') then
      raise exception
        'Somente uma Formulação em rascunho ou elaboração pode ser arquivada diretamente.'
        using errcode = '55000';
    end if;

    update public.skpe_strategic_formulations
    set
      status = 'archived',
      archived_at = timezone('utc', now()),
      archived_by = auth.uid(),
      status_changed_at = timezone('utc', now()),
      status_changed_by = auth.uid(),
      updated_by = auth.uid()
    where id = target_formulation_id
    returning * into updated_formulation;

  else
    raise exception
      'Transição inválida. Use: begin_elaboration, submit_validation, validate, return_for_adjustments, submit_approval, approve ou archive.'
      using errcode = '22023';
  end if;

  perform public.skpe_record_operational_audit(
    updated_formulation.organization_id,
    updated_formulation.project_id,
    'strategic_formulation',
    updated_formulation.id,
    'formulation_' || normalized_action,
    change_reason,
    to_jsonb(previous_formulation),
    to_jsonb(updated_formulation)
  );

  return jsonb_build_object(
    'formulationId', updated_formulation.id,
    'previousStatus', previous_formulation.status,
    'currentStatus', updated_formulation.status,
    'transitionAction', normalized_action,
    'statusChangedAt', updated_formulation.status_changed_at,
    'statusChangedBy', updated_formulation.status_changed_by
  );
end;
$$;

comment on function public.transition_skpe_formulation(uuid, text, text, text) is
  'Executa as transições formais do ciclo de vida com autorização, prontidão metodológica, auditoria e substituição automática da versão aprovada anterior.';

-- ============================================================
-- 9. CONSULTA DAS VERSÕES E DO HISTÓRICO
-- ============================================================

create or replace function public.get_skpe_formulations(
  target_organization_id uuid,
  target_project_id uuid default null
)
returns table (
  formulation_id uuid,
  organization_id uuid,
  project_id uuid,
  project_code text,
  project_name text,
  version_number integer,
  version_label text,
  formulation_status text,
  change_summary text,
  rationale text,
  valid_from date,
  valid_until date,
  derived_from_formulation_id uuid,
  derived_from_version_number integer,
  approved_at timestamptz,
  approved_by uuid,
  status_changed_at timestamptz,
  status_changed_by uuid,
  created_at timestamptz,
  created_by uuid,
  updated_at timestamptz,
  updated_by uuid,
  is_open boolean,
  is_editable boolean,
  is_immutable boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_formulation(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode consultar as Formulações desta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    formulation.id,
    formulation.organization_id,
    formulation.project_id,
    project.code,
    project.name,
    formulation.version_number,
    formulation.version_label,
    formulation.status,
    formulation.change_summary,
    formulation.rationale,
    formulation.valid_from,
    formulation.valid_until,
    formulation.derived_from_formulation_id,
    source.version_number,
    formulation.approved_at,
    formulation.approved_by,
    formulation.status_changed_at,
    formulation.status_changed_by,
    formulation.created_at,
    formulation.created_by,
    formulation.updated_at,
    formulation.updated_by,
    formulation.status in (
      'draft',
      'in_elaboration',
      'pending_validation',
      'validated',
      'pending_approval'
    ),
    formulation.status in ('draft', 'in_elaboration'),
    formulation.status in ('approved', 'superseded', 'archived')
  from public.skpe_strategic_formulations formulation
  join public.skpe_projects project
    on project.id = formulation.project_id
  left join public.skpe_strategic_formulations source
    on source.id = formulation.derived_from_formulation_id
  where formulation.organization_id = target_organization_id
    and (target_project_id is null or formulation.project_id = target_project_id)
  order by
    project.name,
    formulation.version_number desc;
end;
$$;

create or replace function public.get_skpe_formulation_audit(
  target_formulation_id uuid
)
returns table (
  audit_id uuid,
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
    raise exception 'Acesso negado ao histórico desta Formulação.'
      using errcode = '42501';
  end if;

  return query
  select
    audit.id,
    audit.action_code,
    audit.reason,
    audit.previous_data,
    audit.new_data,
    audit.occurred_at,
    audit.actor_user_id
  from public.skpe_operational_audit audit
  where audit.entity_type = 'strategic_formulation'
    and audit.entity_id = target_formulation_id
  order by audit.occurred_at desc, audit.id desc;
end;
$$;

-- ============================================================
-- 10. AUDITORIA VISÍVEL PARA A FORMULAÇÃO
-- ============================================================

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
  or public.can_view_business_architecture(organization_id)
);

comment on table public.skpe_operational_audit is
  'Auditoria operacional transversal do SK-PE, incluindo iniciativas, artefatos, checklist, Formulação Estratégica e Arquitetura de Negócios compartilhada.';

-- ============================================================
-- 11. PRIVILÉGIOS
-- ============================================================

revoke all on function public.skpe_assert_formulation_editable(uuid)
  from public, anon, authenticated;
revoke all on function public.clone_skpe_formulation_content(uuid, uuid)
  from public, anon, authenticated;

revoke all on function public.create_skpe_formulation(
  uuid, text, text, text, date, date, text
) from public, anon;

revoke all on function public.update_skpe_formulation(
  uuid, text, text, text, date, date, jsonb, text
) from public, anon;

revoke all on function public.create_skpe_formulation_revision(
  uuid, text, text, date, date, text
) from public, anon;

revoke all on function public.transition_skpe_formulation(
  uuid, text, text, text
) from public, anon;

revoke all on function public.get_skpe_formulations(uuid, uuid)
  from public, anon;

revoke all on function public.get_skpe_formulation_audit(uuid)
  from public, anon;

grant execute on function public.create_skpe_formulation(
  uuid, text, text, text, date, date, text
) to authenticated, service_role;

grant execute on function public.update_skpe_formulation(
  uuid, text, text, text, date, date, jsonb, text
) to authenticated, service_role;

grant execute on function public.create_skpe_formulation_revision(
  uuid, text, text, date, date, text
) to authenticated, service_role;

grant execute on function public.transition_skpe_formulation(
  uuid, text, text, text
) to authenticated, service_role;

grant execute on function public.get_skpe_formulations(uuid, uuid)
  to authenticated, service_role;

grant execute on function public.get_skpe_formulation_audit(uuid)
  to authenticated, service_role;

grant execute on function public.skpe_assert_formulation_editable(uuid)
  to service_role;

grant execute on function public.clone_skpe_formulation_content(uuid, uuid)
  to service_role;

commit;
