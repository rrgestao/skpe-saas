-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-02 — Identidade Estratégica Operacional
--
-- Escopo:
-- 1. Operações auditadas de Propósito, Missão e Visão.
-- 2. Operações auditadas de Valores e comportamentos.
-- 3. Prontidão específica da Identidade Estratégica.
-- 4. Validação formal do pacote de Identidade.
-- 5. Bloqueio da Formulação quando a Identidade não estiver
--    completa e validada.
-- 6. Consulta consolidada e histórico auditável.
-- ============================================================

begin;

-- ============================================================
-- 1. ÍNDICES COMPLEMENTARES
-- ============================================================

create index if not exists idx_skpe_value_behaviors_value
  on public.skpe_strategic_value_behaviors(
    strategic_value_id,
    behavior_type,
    display_order
  );

create index if not exists idx_skpe_identity_items_validation
  on public.skpe_strategic_identity_items(
    formulation_id,
    validation_status,
    element_type
  );

-- ============================================================
-- 2. GARANTIA DO PACOTE DE IDENTIDADE
-- ============================================================

create or replace function public.ensure_skpe_strategic_identity(
  target_formulation_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  identity_row public.skpe_strategic_identity%rowtype;
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
  into identity_row
  from public.skpe_strategic_identity
  where formulation_id = target_formulation_id
  for update;

  if found then
    update public.skpe_strategic_identity
    set
      status = 'in_elaboration',
      validation_notes = null,
      updated_by = auth.uid()
    where id = identity_row.id
    returning *
    into identity_row;

    return identity_row.id;
  end if;

  insert into public.skpe_strategic_identity (
    organization_id,
    project_id,
    formulation_id,
    status,
    metadata,
    created_by,
    updated_by
  )
  values (
    formulation_row.organization_id,
    formulation_row.project_id,
    formulation_row.id,
    'in_elaboration',
    '{}'::jsonb,
    auth.uid(),
    auth.uid()
  )
  returning *
  into identity_row;

  perform public.skpe_record_operational_audit(
    identity_row.organization_id,
    identity_row.project_id,
    'strategic_identity',
    identity_row.id,
    'strategic_identity_created',
    'Criação automática do pacote de Identidade Estratégica.',
    null,
    to_jsonb(identity_row)
  );

  return identity_row.id;
end;
$$;

comment on function public.ensure_skpe_strategic_identity(uuid) is
  'Função interna que cria ou reabre para elaboração o pacote de Identidade Estratégica da versão.';

-- ============================================================
-- 3. CABEÇALHO E COERÊNCIA DA IDENTIDADE
-- ============================================================

create or replace function public.update_skpe_strategic_identity(
  target_formulation_id uuid,
  new_coherence_statement text default null,
  identity_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  identity_id uuid;
  previous_identity public.skpe_strategic_identity%rowtype;
  updated_identity public.skpe_strategic_identity%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  if identity_metadata is not null
     and jsonb_typeof(identity_metadata) <> 'object' then
    raise exception 'Os metadados da Identidade Estratégica devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  identity_id := public.ensure_skpe_strategic_identity(target_formulation_id);

  select *
  into previous_identity
  from public.skpe_strategic_identity
  where id = identity_id
  for update;

  update public.skpe_strategic_identity
  set
    coherence_statement = new_coherence_statement,
    metadata = coalesce(identity_metadata, metadata),
    status = 'in_elaboration',
    validation_notes = null,
    updated_by = auth.uid()
  where id = identity_id
  returning *
  into updated_identity;

  perform public.skpe_record_operational_audit(
    updated_identity.organization_id,
    updated_identity.project_id,
    'strategic_identity',
    updated_identity.id,
    'strategic_identity_updated',
    change_reason,
    to_jsonb(previous_identity),
    to_jsonb(updated_identity)
  );

  return updated_identity.id;
end;
$$;

-- ============================================================
-- 4. PROPÓSITO, MISSÃO E VISÃO
-- ============================================================

create or replace function public.upsert_skpe_identity_item(
  target_formulation_id uuid,
  identity_element_type text,
  identity_content text,
  identity_rationale text default null,
  identity_display_order integer default 100,
  item_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_type text;
  identity_id uuid;
  formulation_row public.skpe_strategic_formulations%rowtype;
  previous_item public.skpe_strategic_identity_items%rowtype;
  saved_item public.skpe_strategic_identity_items%rowtype;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);

  normalized_type := lower(trim(coalesce(identity_element_type, '')));

  if normalized_type not in ('purpose', 'mission', 'vision') then
    raise exception 'Tipo inválido. Use purpose, mission ou vision.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(identity_content, ''))) = 0 then
    raise exception 'O conteúdo do elemento da Identidade Estratégica é obrigatório.'
      using errcode = '22023';
  end if;

  if identity_display_order < 0 then
    raise exception 'A ordem de exibição não pode ser negativa.'
      using errcode = '22023';
  end if;

  if item_metadata is not null
     and jsonb_typeof(item_metadata) <> 'object' then
    raise exception 'Os metadados do elemento devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  identity_id := public.ensure_skpe_strategic_identity(target_formulation_id);

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  select *
  into previous_item
  from public.skpe_strategic_identity_items
  where formulation_id = target_formulation_id
    and element_type = normalized_type
  for update;

  if found then
    update public.skpe_strategic_identity_items
    set
      content = trim(identity_content),
      rationale = identity_rationale,
      display_order = identity_display_order,
      validation_status = 'draft',
      metadata = coalesce(item_metadata, metadata),
      updated_by = auth.uid()
    where id = previous_item.id
    returning *
    into saved_item;

    action_code := 'strategic_identity_item_updated';
  else
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
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      identity_id,
      normalized_type,
      trim(identity_content),
      identity_rationale,
      identity_display_order,
      'draft',
      coalesce(item_metadata, '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning *
    into saved_item;

    action_code := 'strategic_identity_item_created';
  end if;

  perform public.skpe_record_operational_audit(
    saved_item.organization_id,
    saved_item.project_id,
    'strategic_identity_item',
    saved_item.id,
    action_code,
    change_reason,
    case when previous_item.id is null then null else to_jsonb(previous_item) end,
    to_jsonb(saved_item)
  );

  return saved_item.id;
end;
$$;

create or replace function public.delete_skpe_identity_item(
  target_formulation_id uuid,
  identity_element_type text,
  change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_type text;
  previous_item public.skpe_strategic_identity_items%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);
  perform public.skpe_assert_formulation_editable(target_formulation_id);

  normalized_type := lower(trim(coalesce(identity_element_type, '')));

  if normalized_type not in ('purpose', 'mission', 'vision') then
    raise exception 'Tipo inválido. Use purpose, mission ou vision.'
      using errcode = '22023';
  end if;

  select *
  into previous_item
  from public.skpe_strategic_identity_items
  where formulation_id = target_formulation_id
    and element_type = normalized_type
  for update;

  if not found then
    return false;
  end if;

  delete from public.skpe_strategic_identity_items
  where id = previous_item.id;

  update public.skpe_strategic_identity
  set
    status = 'in_elaboration',
    validation_notes = null,
    updated_by = auth.uid()
  where formulation_id = target_formulation_id;

  perform public.skpe_record_operational_audit(
    previous_item.organization_id,
    previous_item.project_id,
    'strategic_identity_item',
    previous_item.id,
    'strategic_identity_item_deleted',
    change_reason,
    to_jsonb(previous_item),
    null
  );

  return true;
end;
$$;

-- ============================================================
-- 5. VALORES
-- ============================================================

create or replace function public.upsert_skpe_strategic_value(
  target_formulation_id uuid,
  value_code text,
  value_name text,
  value_description text,
  target_value_id uuid default null,
  value_display_order integer default 100,
  value_status text default 'active',
  value_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  identity_id uuid;
  formulation_row public.skpe_strategic_formulations%rowtype;
  previous_value public.skpe_strategic_values%rowtype;
  saved_value public.skpe_strategic_values%rowtype;
  normalized_status text;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);

  if length(trim(coalesce(value_code, ''))) = 0 then
    raise exception 'Informe o código do Valor.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(value_name, ''))) = 0 then
    raise exception 'Informe o nome do Valor.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(value_description, ''))) = 0 then
    raise exception 'Informe o significado do Valor.'
      using errcode = '22023';
  end if;

  if value_display_order < 0 then
    raise exception 'A ordem de exibição não pode ser negativa.'
      using errcode = '22023';
  end if;

  normalized_status := lower(trim(coalesce(value_status, 'active')));

  if normalized_status not in ('draft', 'active', 'archived') then
    raise exception 'Situação inválida para o Valor.'
      using errcode = '22023';
  end if;

  if value_metadata is not null
     and jsonb_typeof(value_metadata) <> 'object' then
    raise exception 'Os metadados do Valor devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  identity_id := public.ensure_skpe_strategic_identity(target_formulation_id);

  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if target_value_id is not null then
    select *
    into previous_value
    from public.skpe_strategic_values
    where id = target_value_id
      and formulation_id = target_formulation_id
    for update;

    if not found then
      raise exception 'Valor não encontrado nesta versão da Formulação.'
        using errcode = '22023';
    end if;

    update public.skpe_strategic_values
    set
      code = trim(value_code),
      name = trim(value_name),
      description = trim(value_description),
      display_order = value_display_order,
      status = normalized_status,
      metadata = coalesce(value_metadata, metadata),
      updated_by = auth.uid()
    where id = previous_value.id
    returning *
    into saved_value;

    action_code := 'strategic_value_updated';
  else
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
    values (
      formulation_row.organization_id,
      formulation_row.project_id,
      formulation_row.id,
      identity_id,
      trim(value_code),
      trim(value_name),
      trim(value_description),
      value_display_order,
      normalized_status,
      coalesce(value_metadata, '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning *
    into saved_value;

    action_code := 'strategic_value_created';
  end if;

  perform public.skpe_record_operational_audit(
    saved_value.organization_id,
    saved_value.project_id,
    'strategic_value',
    saved_value.id,
    action_code,
    change_reason,
    case when previous_value.id is null then null else to_jsonb(previous_value) end,
    to_jsonb(saved_value)
  );

  return saved_value.id;
end;
$$;

create or replace function public.archive_skpe_strategic_value(
  target_value_id uuid,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_value public.skpe_strategic_values%rowtype;
  archived_value public.skpe_strategic_values%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_value
  from public.skpe_strategic_values
  where id = target_value_id
  for update;

  if not found then
    raise exception 'Valor não encontrado.'
      using errcode = '22023';
  end if;

  perform public.skpe_assert_formulation_editable(previous_value.formulation_id);

  update public.skpe_strategic_values
  set
    status = 'archived',
    updated_by = auth.uid()
  where id = previous_value.id
  returning *
  into archived_value;

  update public.skpe_strategic_identity
  set
    status = 'in_elaboration',
    validation_notes = null,
    updated_by = auth.uid()
  where formulation_id = previous_value.formulation_id;

  perform public.skpe_record_operational_audit(
    archived_value.organization_id,
    archived_value.project_id,
    'strategic_value',
    archived_value.id,
    'strategic_value_archived',
    change_reason,
    to_jsonb(previous_value),
    to_jsonb(archived_value)
  );

  return archived_value.id;
end;
$$;

-- ============================================================
-- 6. COMPORTAMENTOS DOS VALORES
-- ============================================================

create or replace function public.upsert_skpe_value_behavior(
  target_value_id uuid,
  value_behavior_type text,
  behavior_description text,
  target_behavior_id uuid default null,
  behavior_display_order integer default 100,
  behavior_metadata jsonb default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  value_row public.skpe_strategic_values%rowtype;
  previous_behavior public.skpe_strategic_value_behaviors%rowtype;
  saved_behavior public.skpe_strategic_value_behaviors%rowtype;
  normalized_type text;
  action_code text;
begin
  perform public.skpe_assert_reason(change_reason);

  normalized_type := lower(trim(coalesce(value_behavior_type, '')));

  if normalized_type not in ('expected', 'incompatible') then
    raise exception 'Tipo inválido. Use expected ou incompatible.'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(behavior_description, ''))) = 0 then
    raise exception 'Informe a descrição do comportamento.'
      using errcode = '22023';
  end if;

  if behavior_display_order < 0 then
    raise exception 'A ordem de exibição não pode ser negativa.'
      using errcode = '22023';
  end if;

  if behavior_metadata is not null
     and jsonb_typeof(behavior_metadata) <> 'object' then
    raise exception 'Os metadados do comportamento devem ser um objeto JSON.'
      using errcode = '22023';
  end if;

  select *
  into value_row
  from public.skpe_strategic_values
  where id = target_value_id
  for update;

  if not found then
    raise exception 'Valor não encontrado.'
      using errcode = '22023';
  end if;

  if value_row.status = 'archived' then
    raise exception 'Não é possível incluir comportamentos em um Valor arquivado.'
      using errcode = '55000';
  end if;

  perform public.skpe_assert_formulation_editable(value_row.formulation_id);

  update public.skpe_strategic_identity
  set
    status = 'in_elaboration',
    validation_notes = null,
    updated_by = auth.uid()
  where formulation_id = value_row.formulation_id;

  if target_behavior_id is not null then
    select *
    into previous_behavior
    from public.skpe_strategic_value_behaviors
    where id = target_behavior_id
      and strategic_value_id = target_value_id
    for update;

    if not found then
      raise exception 'Comportamento não encontrado neste Valor.'
        using errcode = '22023';
    end if;

    update public.skpe_strategic_value_behaviors
    set
      behavior_type = normalized_type,
      description = trim(behavior_description),
      display_order = behavior_display_order,
      metadata = coalesce(behavior_metadata, metadata),
      updated_by = auth.uid()
    where id = previous_behavior.id
    returning *
    into saved_behavior;

    action_code := 'strategic_value_behavior_updated';
  else
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
    values (
      value_row.organization_id,
      value_row.project_id,
      value_row.formulation_id,
      value_row.id,
      normalized_type,
      trim(behavior_description),
      behavior_display_order,
      coalesce(behavior_metadata, '{}'::jsonb),
      auth.uid(),
      auth.uid()
    )
    returning *
    into saved_behavior;

    action_code := 'strategic_value_behavior_created';
  end if;

  perform public.skpe_record_operational_audit(
    saved_behavior.organization_id,
    saved_behavior.project_id,
    'strategic_value_behavior',
    saved_behavior.id,
    action_code,
    change_reason,
    case
      when previous_behavior.id is null then null
      else to_jsonb(previous_behavior)
    end,
    to_jsonb(saved_behavior)
  );

  return saved_behavior.id;
end;
$$;

create or replace function public.delete_skpe_value_behavior(
  target_behavior_id uuid,
  change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_behavior public.skpe_strategic_value_behaviors%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  select *
  into previous_behavior
  from public.skpe_strategic_value_behaviors
  where id = target_behavior_id
  for update;

  if not found then
    return false;
  end if;

  perform public.skpe_assert_formulation_editable(
    previous_behavior.formulation_id
  );

  delete from public.skpe_strategic_value_behaviors
  where id = previous_behavior.id;

  update public.skpe_strategic_identity
  set
    status = 'in_elaboration',
    validation_notes = null,
    updated_by = auth.uid()
  where formulation_id = previous_behavior.formulation_id;

  perform public.skpe_record_operational_audit(
    previous_behavior.organization_id,
    previous_behavior.project_id,
    'strategic_value_behavior',
    previous_behavior.id,
    'strategic_value_behavior_deleted',
    change_reason,
    to_jsonb(previous_behavior),
    null
  );

  return true;
end;
$$;

-- ============================================================
-- 7. PRONTIDÃO DA IDENTIDADE ESTRATÉGICA
-- ============================================================

create or replace function public.get_skpe_identity_readiness(
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
  identity_row public.skpe_strategic_identity%rowtype;
  issues jsonb;
  blocking_count integer;
  counts jsonb;
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
    raise exception 'Acesso negado à Identidade Estratégica.'
      using errcode = '42501';
  end if;

  select *
  into identity_row
  from public.skpe_strategic_identity
  where formulation_id = target_formulation_id;

  select jsonb_build_object(
    'purpose', (
      select count(*)
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
        and item.element_type = 'purpose'
    ),
    'mission', (
      select count(*)
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
        and item.element_type = 'mission'
    ),
    'vision', (
      select count(*)
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
        and item.element_type = 'vision'
    ),
    'activeValues', (
      select count(*)
      from public.skpe_strategic_values value
      where value.formulation_id = target_formulation_id
        and value.status <> 'archived'
    ),
    'expectedBehaviors', (
      select count(*)
      from public.skpe_strategic_value_behaviors behavior
      where behavior.formulation_id = target_formulation_id
        and behavior.behavior_type = 'expected'
    ),
    'incompatibleBehaviors', (
      select count(*)
      from public.skpe_strategic_value_behaviors behavior
      where behavior.formulation_id = target_formulation_id
        and behavior.behavior_type = 'incompatible'
    )
  )
  into counts;

  with issue_rows as (
    select
      'MISSION_MISSING'::text as code,
      'blocking'::text as severity,
      'A Missão é obrigatória.'::text as message,
      1::bigint as affected_count
    where not exists (
      select 1
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
        and item.element_type = 'mission'
    )

    union all

    select
      'VISION_MISSING',
      'blocking',
      'A Visão de Longo Prazo é obrigatória.',
      1
    where not exists (
      select 1
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
        and item.element_type = 'vision'
    )

    union all

    select
      'VALUES_MISSING',
      'blocking',
      'Registre ao menos um Valor organizacional inegociável.',
      1
    where not exists (
      select 1
      from public.skpe_strategic_values value
      where value.formulation_id = target_formulation_id
        and value.status <> 'archived'
    )

    union all

    select
      'VALUE_WITHOUT_EXPECTED_BEHAVIOR',
      'blocking',
      'Todo Valor deve possuir ao menos um comportamento esperado.',
      count(*)
    from public.skpe_strategic_values value
    where value.formulation_id = target_formulation_id
      and value.status <> 'archived'
      and not exists (
        select 1
        from public.skpe_strategic_value_behaviors behavior
        where behavior.strategic_value_id = value.id
          and behavior.behavior_type = 'expected'
      )
    having count(*) > 0

    union all

    select
      'VALUE_WITHOUT_INCOMPATIBLE_BEHAVIOR',
      'blocking',
      'Todo Valor deve explicitar ao menos um comportamento incompatível.',
      count(*)
    from public.skpe_strategic_values value
    where value.formulation_id = target_formulation_id
      and value.status <> 'archived'
      and not exists (
        select 1
        from public.skpe_strategic_value_behaviors behavior
        where behavior.strategic_value_id = value.id
          and behavior.behavior_type = 'incompatible'
      )
    having count(*) > 0

    union all

    select
      'PURPOSE_OPTIONAL',
      'information',
      'O Propósito é opcional e pode ser utilizado quando agregar clareza à razão de existir da organização.',
      1
    where not exists (
      select 1
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
        and item.element_type = 'purpose'
    )
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'code', issue.code,
          'severity', issue.severity,
          'message', issue.message,
          'affectedCount', issue.affected_count
        )
        order by
          case issue.severity
            when 'blocking' then 1
            when 'recommendation' then 2
            else 3
          end,
          issue.code
      ),
      '[]'::jsonb
    ),
    count(*) filter (where issue.severity = 'blocking')::integer
  into issues, blocking_count
  from issue_rows issue;

  return jsonb_build_object(
    'formulationId', formulation_row.id,
    'strategicIdentityId', identity_row.id,
    'identityStatus', identity_row.status,
    'readyForValidation', blocking_count = 0,
    'validated', identity_row.status = 'validated',
    'blockingIssueCount', blocking_count,
    'counts', counts,
    'issues', issues,
    'methodologyRules', jsonb_build_object(
      'purposeOptional', true,
      'missionRequired', true,
      'visionRequired', true,
      'minimumValues', 1,
      'expectedBehaviorPerValueRequired', true,
      'incompatibleBehaviorPerValueRequired', true
    )
  );
end;
$$;

-- ============================================================
-- 8. VALIDAÇÃO DO PACOTE DE IDENTIDADE
-- ============================================================

create or replace function public.transition_skpe_strategic_identity(
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
  previous_identity public.skpe_strategic_identity%rowtype;
  updated_identity public.skpe_strategic_identity%rowtype;
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

  perform public.skpe_assert_formulation_editable(target_formulation_id);

  select *
  into previous_identity
  from public.skpe_strategic_identity
  where formulation_id = target_formulation_id
  for update;

  if not found then
    raise exception 'A Identidade Estratégica ainda não foi criada.'
      using errcode = '22023';
  end if;

  if normalized_action = 'submit_validation' then
    if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para submeter a Identidade à validação.'
        using errcode = '42501';
    end if;

    if previous_identity.status not in (
      'draft',
      'in_elaboration',
      'rejected'
    ) then
      raise exception
        'A Identidade deve estar em elaboração para ser submetida à validação.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_identity_readiness(target_formulation_id);

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception
        'A Identidade Estratégica possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_strategic_identity
    set
      status = 'pending_validation',
      validation_notes = null,
      updated_by = auth.uid()
    where id = previous_identity.id
    returning *
    into updated_identity;

    update public.skpe_strategic_identity_items
    set
      validation_status = 'pending_validation',
      updated_by = auth.uid()
    where formulation_id = target_formulation_id;

  elsif normalized_action = 'validate' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para validar a Identidade Estratégica.'
        using errcode = '42501';
    end if;

    if previous_identity.status <> 'pending_validation' then
      raise exception
        'Somente uma Identidade pendente de validação pode ser validada.'
        using errcode = '55000';
    end if;

    readiness := public.get_skpe_identity_readiness(target_formulation_id);

    if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
      raise exception
        'A Identidade Estratégica possui pendências bloqueantes.'
        using errcode = '55000', detail = readiness::text;
    end if;

    update public.skpe_strategic_identity
    set
      status = 'validated',
      validation_notes = decision_notes,
      updated_by = auth.uid()
    where id = previous_identity.id
    returning *
    into updated_identity;

    update public.skpe_strategic_identity_items
    set
      validation_status = 'validated',
      updated_by = auth.uid()
    where formulation_id = target_formulation_id;

    update public.skpe_strategic_values
    set
      status = 'active',
      updated_by = auth.uid()
    where formulation_id = target_formulation_id
      and status <> 'archived';

  elsif normalized_action = 'return_for_adjustments' then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception 'Acesso negado para devolver a Identidade para ajustes.'
        using errcode = '42501';
    end if;

    if previous_identity.status not in (
      'pending_validation',
      'validated'
    ) then
      raise exception
        'A Identidade não está em situação que permita devolução para ajustes.'
        using errcode = '55000';
    end if;

    if length(trim(coalesce(decision_notes, ''))) < 10 then
      raise exception
        'Informe as orientações para os ajustes, com no mínimo 10 caracteres.'
        using errcode = '22023';
    end if;

    update public.skpe_strategic_identity
    set
      status = 'in_elaboration',
      validation_notes = decision_notes,
      updated_by = auth.uid()
    where id = previous_identity.id
    returning *
    into updated_identity;

    update public.skpe_strategic_identity_items
    set
      validation_status = 'draft',
      updated_by = auth.uid()
    where formulation_id = target_formulation_id;

  else
    raise exception
      'Transição inválida. Use submit_validation, validate ou return_for_adjustments.'
      using errcode = '22023';
  end if;

  perform public.skpe_record_operational_audit(
    updated_identity.organization_id,
    updated_identity.project_id,
    'strategic_identity',
    updated_identity.id,
    'strategic_identity_' || normalized_action,
    change_reason,
    to_jsonb(previous_identity),
    to_jsonb(updated_identity)
  );

  return jsonb_build_object(
    'formulationId', target_formulation_id,
    'strategicIdentityId', updated_identity.id,
    'previousStatus', previous_identity.status,
    'currentStatus', updated_identity.status,
    'transitionAction', normalized_action
  );
end;
$$;

-- ============================================================
-- 9. BLOQUEIO DA FORMULAÇÃO SEM IDENTIDADE VALIDADA
-- ============================================================

create or replace function public.skpe_guard_formulation_identity_ready()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  readiness jsonb;
  identity_status text;
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

  readiness := public.get_skpe_identity_readiness(new.id);

  if not coalesce((readiness ->> 'readyForValidation')::boolean, false) then
    raise exception
      'A Formulação não pode avançar: a Identidade Estratégica possui pendências bloqueantes.'
      using errcode = '55000', detail = readiness::text;
  end if;

  identity_status := readiness ->> 'identityStatus';

  if identity_status <> 'validated' then
    raise exception
      'A Formulação não pode avançar: valide a Identidade Estratégica antes da submissão da Formulação.'
      using errcode = '55000';
  end if;

  return new;
end;
$$;

drop trigger if exists skpe_strategic_formulations_guard_identity_ready
  on public.skpe_strategic_formulations;

create trigger skpe_strategic_formulations_guard_identity_ready
before update of status on public.skpe_strategic_formulations
for each row
execute function public.skpe_guard_formulation_identity_ready();

comment on function public.skpe_guard_formulation_identity_ready() is
  'Impede o avanço do ciclo da Formulação enquanto Missão, Visão, Valores e comportamentos não estiverem completos e validados.';

-- ============================================================
-- 10. CONSULTA CONSOLIDADA
-- ============================================================

create or replace function public.get_skpe_strategic_identity(
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
  identity_payload jsonb;
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
    raise exception 'Acesso negado à Identidade Estratégica.'
      using errcode = '42501';
  end if;

  readiness := public.get_skpe_identity_readiness(target_formulation_id);

  select jsonb_build_object(
    'formulation', jsonb_build_object(
      'id', formulation_row.id,
      'organizationId', formulation_row.organization_id,
      'projectId', formulation_row.project_id,
      'versionNumber', formulation_row.version_number,
      'versionLabel', formulation_row.version_label,
      'status', formulation_row.status
    ),
    'identity', case
      when identity.id is null then null
      else jsonb_build_object(
        'id', identity.id,
        'status', identity.status,
        'coherenceStatement', identity.coherence_statement,
        'validationNotes', identity.validation_notes,
        'metadata', identity.metadata,
        'createdAt', identity.created_at,
        'updatedAt', identity.updated_at
      )
    end,
    'items', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', item.id,
          'elementType', item.element_type,
          'content', item.content,
          'rationale', item.rationale,
          'displayOrder', item.display_order,
          'validationStatus', item.validation_status,
          'metadata', item.metadata,
          'createdAt', item.created_at,
          'updatedAt', item.updated_at
        )
        order by item.display_order, item.element_type
      )
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
    ), '[]'::jsonb),
    'values', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', value.id,
          'code', value.code,
          'name', value.name,
          'description', value.description,
          'displayOrder', value.display_order,
          'status', value.status,
          'metadata', value.metadata,
          'behaviors', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'id', behavior.id,
                'behaviorType', behavior.behavior_type,
                'description', behavior.description,
                'displayOrder', behavior.display_order,
                'metadata', behavior.metadata,
                'createdAt', behavior.created_at,
                'updatedAt', behavior.updated_at
              )
              order by
                case behavior.behavior_type
                  when 'expected' then 1
                  else 2
                end,
                behavior.display_order,
                behavior.description
            )
            from public.skpe_strategic_value_behaviors behavior
            where behavior.strategic_value_id = value.id
          ), '[]'::jsonb),
          'createdAt', value.created_at,
          'updatedAt', value.updated_at
        )
        order by value.display_order, value.name
      )
      from public.skpe_strategic_values value
      where value.formulation_id = target_formulation_id
        and value.status <> 'archived'
    ), '[]'::jsonb),
    'readiness', readiness
  )
  into identity_payload
  from public.skpe_strategic_identity identity
  where identity.formulation_id = target_formulation_id;

  if identity_payload is null then
    identity_payload := jsonb_build_object(
      'formulation', jsonb_build_object(
        'id', formulation_row.id,
        'organizationId', formulation_row.organization_id,
        'projectId', formulation_row.project_id,
        'versionNumber', formulation_row.version_number,
        'versionLabel', formulation_row.version_label,
        'status', formulation_row.status
      ),
      'identity', null,
      'items', '[]'::jsonb,
      'values', '[]'::jsonb,
      'readiness', readiness
    );
  end if;

  return identity_payload;
end;
$$;

create or replace function public.get_skpe_identity_audit(
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
    raise exception 'Acesso negado ao histórico da Identidade Estratégica.'
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
      'strategic_identity',
      'strategic_identity_item',
      'strategic_value',
      'strategic_value_behavior'
    )
    and (
      audit.previous_data ->> 'formulation_id' = target_formulation_id::text
      or audit.new_data ->> 'formulation_id' = target_formulation_id::text
    )
  order by audit.occurred_at desc, audit.id desc;
end;
$$;

-- ============================================================
-- 11. PRIVILÉGIOS
-- ============================================================

revoke all on function public.ensure_skpe_strategic_identity(uuid)
  from public, anon, authenticated;

revoke all on function public.skpe_guard_formulation_identity_ready()
  from public, anon, authenticated;

revoke all on function public.update_skpe_strategic_identity(
  uuid, text, jsonb, text
) from public, anon;

revoke all on function public.upsert_skpe_identity_item(
  uuid, text, text, text, integer, jsonb, text
) from public, anon;

revoke all on function public.delete_skpe_identity_item(
  uuid, text, text
) from public, anon;

revoke all on function public.upsert_skpe_strategic_value(
  uuid, text, text, text, uuid, integer, text, jsonb, text
) from public, anon;

revoke all on function public.archive_skpe_strategic_value(
  uuid, text
) from public, anon;

revoke all on function public.upsert_skpe_value_behavior(
  uuid, text, text, uuid, integer, jsonb, text
) from public, anon;

revoke all on function public.delete_skpe_value_behavior(
  uuid, text
) from public, anon;

revoke all on function public.get_skpe_identity_readiness(uuid)
  from public, anon;

revoke all on function public.transition_skpe_strategic_identity(
  uuid, text, text, text
) from public, anon;

revoke all on function public.get_skpe_strategic_identity(uuid)
  from public, anon;

revoke all on function public.get_skpe_identity_audit(uuid)
  from public, anon;

grant execute on function public.update_skpe_strategic_identity(
  uuid, text, jsonb, text
) to authenticated, service_role;

grant execute on function public.upsert_skpe_identity_item(
  uuid, text, text, text, integer, jsonb, text
) to authenticated, service_role;

grant execute on function public.delete_skpe_identity_item(
  uuid, text, text
) to authenticated, service_role;

grant execute on function public.upsert_skpe_strategic_value(
  uuid, text, text, text, uuid, integer, text, jsonb, text
) to authenticated, service_role;

grant execute on function public.archive_skpe_strategic_value(
  uuid, text
) to authenticated, service_role;

grant execute on function public.upsert_skpe_value_behavior(
  uuid, text, text, uuid, integer, jsonb, text
) to authenticated, service_role;

grant execute on function public.delete_skpe_value_behavior(
  uuid, text
) to authenticated, service_role;

grant execute on function public.get_skpe_identity_readiness(uuid)
  to authenticated, service_role;

grant execute on function public.transition_skpe_strategic_identity(
  uuid, text, text, text
) to authenticated, service_role;

grant execute on function public.get_skpe_strategic_identity(uuid)
  to authenticated, service_role;

grant execute on function public.get_skpe_identity_audit(uuid)
  to authenticated, service_role;

grant execute on function public.ensure_skpe_strategic_identity(uuid)
  to service_role;

commit;
