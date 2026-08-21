begin;

-- ============================================================
-- SPARKs PaaS
-- Gate 17-B.5F.3C.6D
-- Operacao Governada de Lifecycle e Execucao de Acoes
--
-- Escopo:
--   1. criacao governada;
--   2. edicao estrutural governada;
--   3. lifecycle governado;
--   4. progresso/execucao governados;
--   5. auditoria obrigatoria;
--   6. protecao de identidade e baseline.
--
-- Fora de escopo:
--   - responsabilidades pessoais (6E);
--   - roll-up para iniciativa (6F);
--   - Kanban (6G);
--   - Gantt (6H);
--   - agenda/calendario (6I);
--   - operacao economica de custos/esforco (6J);
--   - sincronizacao automatica com skpe_*.
-- ============================================================

alter table public.sparks_initiative_actions
  add constraint sparks_initiative_actions_execution_started_check
  check (
    status not in ('in_progress', 'on_hold', 'completed')
    or started_at is not null
  ),
  add constraint sparks_initiative_actions_progress_started_check
  check (
    progress = 0
    or started_at is not null
  );

-- ============================================================
-- PROTECAO DE IDENTIDADE E BASELINE
-- ============================================================

create or replace function public.sparks_protect_initiative_action_identity()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.organization_id is distinct from old.organization_id then
    raise exception 'A organizacao da acao e imutavel.'
      using errcode = '22023';
  end if;

  if new.initiative_id is distinct from old.initiative_id then
    raise exception 'A iniciativa pai da acao e imutavel.'
      using errcode = '22023';
  end if;

  if new.source_module_code is distinct from old.source_module_code then
    raise exception 'O modulo de origem da acao e imutavel.'
      using errcode = '22023';
  end if;

  if new.baseline_start_date is distinct from old.baseline_start_date
     or new.baseline_due_date is distinct from old.baseline_due_date then
    raise exception 'A baseline original da acao e imutavel.'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

create trigger sparks_initiative_actions_protect_identity
before update of
  organization_id,
  initiative_id,
  source_module_code,
  baseline_start_date,
  baseline_due_date
on public.sparks_initiative_actions
for each row
execute function public.sparks_protect_initiative_action_identity();

revoke all
on function public.sparks_protect_initiative_action_identity()
from public, anon, authenticated;

grant execute
on function public.sparks_protect_initiative_action_identity()
to service_role;

comment on function public.sparks_protect_initiative_action_identity() is
  'Protege identidade, proveniencia estrutural e baseline original das acoes transversais depois da criacao.';

-- ============================================================
-- CREATE GOVERNADO
-- ============================================================

create or replace function public.create_sparks_initiative_action(
  target_initiative_id uuid,
  action_payload jsonb,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_initiative public.sparks_initiatives%rowtype;
  v_action_id uuid;
  v_parent_id uuid;
  v_area_id uuid;
  v_metadata jsonb;
  v_result jsonb;
  v_key text;
  v_now timestamptz := timezone('utc', now());

  v_allowed_keys constant text[] := array[
    'code',
    'name',
    'description',
    'actionType',
    'parentActionId',
    'sourceReference',
    'whyText',
    'whereText',
    'howText',
    'responsibleAreaId',
    'baselineStartDate',
    'baselineDueDate',
    'plannedStartDate',
    'plannedDueDate',
    'priority',
    'metadata'
  ];
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  if action_payload is null or jsonb_typeof(action_payload) <> 'object' then
    raise exception 'O payload da acao deve ser um objeto JSON.'
      using errcode = '22023';
  end if;

  for v_key in
    select jsonb_object_keys(action_payload)
  loop
    if not (v_key = any(v_allowed_keys)) then
      raise exception
        'Campo nao permitido no contrato de criacao da acao: %.',
        v_key
        using errcode = '22023';
    end if;
  end loop;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = target_initiative_id
    and archived_at is null
  for share;

  if v_initiative.id is null then
    raise exception 'Iniciativa nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  if v_initiative.status in ('completed', 'cancelled', 'archived') then
    raise exception
      'Nao e permitido criar acao para iniciativa encerrada (%).',
      v_initiative.status
      using errcode = '55000';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_initiative.organization_id,
    v_initiative.source_module_code
  ) then
    raise exception
      'Acesso negado: o usuario nao pode gerir esta iniciativa.'
      using errcode = '42501';
  end if;

  if nullif(trim(action_payload ->> 'code'), '') is null then
    raise exception 'Informe o codigo da acao.'
      using errcode = '22023';
  end if;

  if nullif(trim(action_payload ->> 'name'), '') is null then
    raise exception 'Informe o nome da acao.'
      using errcode = '22023';
  end if;

  v_parent_id :=
    nullif(action_payload ->> 'parentActionId', '')::uuid;

  v_area_id :=
    nullif(action_payload ->> 'responsibleAreaId', '')::uuid;

  v_metadata :=
    coalesce(action_payload -> 'metadata', '{}'::jsonb);

  if jsonb_typeof(v_metadata) <> 'object' then
    raise exception 'metadata deve ser um objeto JSON.'
      using errcode = '22023';
  end if;

  if v_parent_id is not null and not exists (
    select 1
    from public.sparks_initiative_actions parent_action
    where parent_action.id = v_parent_id
      and parent_action.organization_id = v_initiative.organization_id
      and parent_action.initiative_id = v_initiative.id
      and parent_action.archived_at is null
  ) then
    raise exception
      'Acao pai nao pertence a mesma iniciativa ou esta arquivada.'
      using errcode = '22023';
  end if;

  insert into public.sparks_initiative_actions (
    organization_id,
    initiative_id,
    parent_action_id,
    code,
    name,
    description,
    action_type,
    source_module_code,
    source_reference,
    why_text,
    where_text,
    how_text,
    responsible_area_id,
    baseline_start_date,
    baseline_due_date,
    planned_start_date,
    planned_due_date,
    status,
    priority,
    progress,
    metadata,
    created_by,
    updated_by
  )
  values (
    v_initiative.organization_id,
    v_initiative.id,
    v_parent_id,
    trim(action_payload ->> 'code'),
    trim(action_payload ->> 'name'),
    nullif(trim(action_payload ->> 'description'), ''),
    coalesce(
      nullif(lower(trim(action_payload ->> 'actionType')), ''),
      'action'
    ),
    nullif(upper(trim(v_initiative.source_module_code)), ''),
    nullif(trim(action_payload ->> 'sourceReference'), ''),
    nullif(trim(action_payload ->> 'whyText'), ''),
    nullif(trim(action_payload ->> 'whereText'), ''),
    nullif(trim(action_payload ->> 'howText'), ''),
    v_area_id,
    nullif(action_payload ->> 'baselineStartDate', '')::date,
    nullif(action_payload ->> 'baselineDueDate', '')::date,
    nullif(action_payload ->> 'plannedStartDate', '')::date,
    nullif(action_payload ->> 'plannedDueDate', '')::date,
    'planned',
    coalesce(
      nullif(lower(trim(action_payload ->> 'priority')), ''),
      'medium'
    ),
    0,
    v_metadata,
    auth.uid(),
    auth.uid()
  )
  returning id into v_action_id;

  select to_jsonb(action)
    into v_result
  from public.sparks_initiative_actions action
  where action.id = v_action_id;

  insert into public.sparks_initiative_action_audit (
    organization_id,
    initiative_id,
    action_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data,
    occurred_at
  )
  values (
    v_initiative.organization_id,
    v_initiative.id,
    v_action_id,
    auth.uid(),
    v_initiative.source_module_code,
    'initiative_action_created',
    trim(change_reason),
    null,
    v_result,
    v_now
  );

  return v_result;
end;
$$;

-- ============================================================
-- UPDATE ESTRUTURAL GOVERNADO
-- ============================================================

create or replace function public.update_sparks_initiative_action(
  target_action_id uuid,
  action_payload jsonb,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_action public.sparks_initiative_actions%rowtype;
  v_initiative public.sparks_initiatives%rowtype;
  v_parent_id uuid;
  v_area_id uuid;
  v_metadata jsonb;
  v_before jsonb;
  v_after jsonb;
  v_key text;
  v_now timestamptz := timezone('utc', now());

  v_allowed_keys constant text[] := array[
    'code',
    'name',
    'description',
    'actionType',
    'parentActionId',
    'sourceReference',
    'whyText',
    'whereText',
    'howText',
    'responsibleAreaId',
    'plannedStartDate',
    'plannedDueDate',
    'priority',
    'metadata'
  ];
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  if action_payload is null or jsonb_typeof(action_payload) <> 'object' then
    raise exception 'O payload da acao deve ser um objeto JSON.'
      using errcode = '22023';
  end if;

  if action_payload = '{}'::jsonb then
    raise exception 'Nenhuma alteracao estrutural foi informada.'
      using errcode = '22023';
  end if;

  for v_key in
    select jsonb_object_keys(action_payload)
  loop
    if not (v_key = any(v_allowed_keys)) then
      raise exception
        'Campo nao permitido no contrato de edicao da acao: %.',
        v_key
        using errcode = '22023';
    end if;
  end loop;

  select *
    into v_action
  from public.sparks_initiative_actions
  where id = target_action_id
    and archived_at is null
  for update;

  if v_action.id is null then
    raise exception 'Acao nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = v_action.initiative_id;

  if v_initiative.id is null then
    raise exception 'Iniciativa pai da acao nao foi encontrada.'
      using errcode = '55000';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_action.organization_id,
    v_action.source_module_code
  ) then
    raise exception
      'Acesso negado: o usuario nao pode gerir esta acao.'
      using errcode = '42501';
  end if;

  if v_initiative.status in ('completed', 'cancelled', 'archived') then
    raise exception
      'A iniciativa pai esta encerrada (%).',
      v_initiative.status
      using errcode = '55000';
  end if;

  if v_action.status in ('completed', 'cancelled', 'archived') then
    raise exception
      'Acoes encerradas nao podem ser editadas estruturalmente (%).',
      v_action.status
      using errcode = '55000';
  end if;

  if action_payload ? 'code'
     and nullif(trim(action_payload ->> 'code'), '') is null then
    raise exception 'O codigo da acao nao pode ficar vazio.'
      using errcode = '22023';
  end if;

  if action_payload ? 'name'
     and nullif(trim(action_payload ->> 'name'), '') is null then
    raise exception 'O nome da acao nao pode ficar vazio.'
      using errcode = '22023';
  end if;

  v_parent_id := case
    when action_payload ? 'parentActionId'
      then nullif(action_payload ->> 'parentActionId', '')::uuid
    else v_action.parent_action_id
  end;

  v_area_id := case
    when action_payload ? 'responsibleAreaId'
      then nullif(action_payload ->> 'responsibleAreaId', '')::uuid
    else v_action.responsible_area_id
  end;

  if action_payload ? 'metadata' then
    v_metadata :=
      coalesce(action_payload -> 'metadata', '{}'::jsonb);

    if jsonb_typeof(v_metadata) <> 'object' then
      raise exception 'metadata deve ser um objeto JSON.'
        using errcode = '22023';
    end if;
  else
    v_metadata := v_action.metadata;
  end if;

  if v_parent_id = v_action.id then
    raise exception 'Uma acao nao pode ser pai de si propria.'
      using errcode = '22023';
  end if;

  if v_parent_id is not null and not exists (
    select 1
    from public.sparks_initiative_actions parent_action
    where parent_action.id = v_parent_id
      and parent_action.organization_id = v_action.organization_id
      and parent_action.initiative_id = v_action.initiative_id
      and parent_action.archived_at is null
  ) then
    raise exception
      'Acao pai nao pertence a mesma iniciativa ou esta arquivada.'
      using errcode = '22023';
  end if;

  if v_parent_id is not null and exists (
    with recursive descendants as (
      select child.id
      from public.sparks_initiative_actions child
      where child.parent_action_id = v_action.id
        and child.archived_at is null

      union all

      select child.id
      from public.sparks_initiative_actions child
      join descendants d
        on child.parent_action_id = d.id
      where child.archived_at is null
    )
    select 1
    from descendants
    where id = v_parent_id
  ) then
    raise exception 'A hierarquia de acoes criaria um ciclo.'
      using errcode = '22023';
  end if;

  v_before := to_jsonb(v_action);

  update public.sparks_initiative_actions
  set
    parent_action_id = v_parent_id,

    code = case
      when action_payload ? 'code'
        then trim(action_payload ->> 'code')
      else code
    end,

    name = case
      when action_payload ? 'name'
        then trim(action_payload ->> 'name')
      else name
    end,

    description = case
      when action_payload ? 'description'
        then nullif(trim(action_payload ->> 'description'), '')
      else description
    end,

    action_type = case
      when action_payload ? 'actionType'
        then lower(trim(action_payload ->> 'actionType'))
      else action_type
    end,

    source_reference = case
      when action_payload ? 'sourceReference'
        then nullif(trim(action_payload ->> 'sourceReference'), '')
      else source_reference
    end,

    why_text = case
      when action_payload ? 'whyText'
        then nullif(trim(action_payload ->> 'whyText'), '')
      else why_text
    end,

    where_text = case
      when action_payload ? 'whereText'
        then nullif(trim(action_payload ->> 'whereText'), '')
      else where_text
    end,

    how_text = case
      when action_payload ? 'howText'
        then nullif(trim(action_payload ->> 'howText'), '')
      else how_text
    end,

    responsible_area_id = v_area_id,

    planned_start_date = case
      when action_payload ? 'plannedStartDate'
        then nullif(action_payload ->> 'plannedStartDate', '')::date
      else planned_start_date
    end,

    planned_due_date = case
      when action_payload ? 'plannedDueDate'
        then nullif(action_payload ->> 'plannedDueDate', '')::date
      else planned_due_date
    end,

    priority = case
      when action_payload ? 'priority'
        then lower(trim(action_payload ->> 'priority'))
      else priority
    end,

    metadata = v_metadata,
    updated_at = v_now,
    updated_by = auth.uid()

  where id = v_action.id;

  select to_jsonb(action)
    into v_after
  from public.sparks_initiative_actions action
  where action.id = v_action.id;

  insert into public.sparks_initiative_action_audit (
    organization_id,
    initiative_id,
    action_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data,
    occurred_at
  )
  values (
    v_action.organization_id,
    v_action.initiative_id,
    v_action.id,
    auth.uid(),
    v_action.source_module_code,
    'initiative_action_updated',
    trim(change_reason),
    v_before,
    v_after,
    v_now
  );

  return v_after;
end;
$$;

-- ============================================================
-- LIFECYCLE GOVERNADO
-- ============================================================

create or replace function public.transition_sparks_initiative_action_lifecycle(
  target_action_id uuid,
  target_status text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_action public.sparks_initiative_actions%rowtype;
  v_initiative public.sparks_initiatives%rowtype;
  v_target_status text;
  v_before jsonb;
  v_after jsonb;
  v_now timestamptz := timezone('utc', now());
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  select *
    into v_action
  from public.sparks_initiative_actions
  where id = target_action_id
  for update;

  if v_action.id is null then
    raise exception 'Acao nao encontrada.'
      using errcode = '22023';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = v_action.initiative_id;

  if v_initiative.id is null then
    raise exception 'Iniciativa pai da acao nao foi encontrada.'
      using errcode = '55000';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_action.organization_id,
    v_action.source_module_code
  ) then
    raise exception
      'Acesso negado: o usuario nao pode gerir esta acao.'
      using errcode = '42501';
  end if;

  v_target_status := lower(trim(target_status));

  if v_target_status is null
     or v_target_status not in (
       'planned',
       'in_progress',
       'on_hold',
       'blocked',
       'completed',
       'cancelled',
       'archived'
     ) then
    raise exception 'Status de lifecycle invalido: %.', target_status
      using errcode = '22023';
  end if;

  if v_target_status = v_action.status then
    raise exception 'A acao ja esta no status "%".', v_target_status
      using errcode = '22023';
  end if;

  if v_initiative.status in ('completed', 'cancelled', 'archived')
     and v_target_status <> 'archived' then
    raise exception
      'A iniciativa pai esta encerrada (%).',
      v_initiative.status
      using errcode = '55000';
  end if;

  if not (
    (
      v_action.status = 'planned'
      and v_target_status in ('in_progress', 'blocked', 'cancelled')
    )
    or (
      v_action.status = 'in_progress'
      and v_target_status in (
        'on_hold',
        'blocked',
        'completed',
        'cancelled'
      )
    )
    or (
      v_action.status = 'on_hold'
      and v_target_status in ('in_progress', 'blocked', 'cancelled')
    )
    or (
      v_action.status = 'blocked'
      and v_target_status in ('in_progress', 'on_hold', 'cancelled')
    )
    or (
      v_action.status = 'completed'
      and v_target_status = 'archived'
    )
    or (
      v_action.status = 'cancelled'
      and v_target_status = 'archived'
    )
  ) then
    raise exception
      'Transicao de lifecycle nao permitida: % -> %.',
      v_action.status,
      v_target_status
      using errcode = '22023';
  end if;

  if v_action.status = 'blocked'
     and v_target_status = 'on_hold'
     and v_action.started_at is null then
    raise exception
      'Acao bloqueada antes do inicio nao pode ir para on_hold.'
      using errcode = '22023';
  end if;

  if v_target_status = 'archived' and exists (
    select 1
    from public.sparks_initiative_actions child
    where child.parent_action_id = v_action.id
      and child.archived_at is null
  ) then
    raise exception
      'Arquive as acoes filhas antes de arquivar esta acao.'
      using errcode = '55000';
  end if;

  v_before := to_jsonb(v_action);

  update public.sparks_initiative_actions
  set
    status = v_target_status,

    started_at = case
      when v_target_status = 'in_progress'
        then coalesce(started_at, v_now)
      else started_at
    end,

    progress = case
      when v_target_status = 'completed'
        then 100
      else progress
    end,

    completed_at = case
      when v_target_status = 'completed'
        then v_now
      else completed_at
    end,

    archived_at = case
      when v_target_status = 'archived'
        then v_now
      else archived_at
    end,

    archived_by = case
      when v_target_status = 'archived'
        then auth.uid()
      else archived_by
    end,

    last_update_at = v_now,
    updated_at = v_now,
    updated_by = auth.uid()

  where id = v_action.id;

  select to_jsonb(action)
    into v_after
  from public.sparks_initiative_actions action
  where action.id = v_action.id;

  insert into public.sparks_initiative_action_audit (
    organization_id,
    initiative_id,
    action_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data,
    occurred_at
  )
  values (
    v_action.organization_id,
    v_action.initiative_id,
    v_action.id,
    auth.uid(),
    v_action.source_module_code,
    'initiative_action_lifecycle_transitioned',
    trim(change_reason),
    v_before,
    v_after,
    v_now
  );

  return v_after;
end;
$$;

-- ============================================================
-- EXECUCAO / PROGRESSO GOVERNADO
-- ============================================================

create or replace function public.update_sparks_initiative_action_execution(
  target_action_id uuid,
  target_progress numeric,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_action public.sparks_initiative_actions%rowtype;
  v_initiative public.sparks_initiatives%rowtype;
  v_before jsonb;
  v_after jsonb;
  v_now timestamptz := timezone('utc', now());
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  select *
    into v_action
  from public.sparks_initiative_actions
  where id = target_action_id
    and archived_at is null
  for update;

  if v_action.id is null then
    raise exception 'Acao nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = v_action.initiative_id;

  if v_initiative.id is null then
    raise exception 'Iniciativa pai da acao nao foi encontrada.'
      using errcode = '55000';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_action.organization_id,
    v_action.source_module_code
  ) then
    raise exception
      'Acesso negado: o usuario nao pode gerir esta acao.'
      using errcode = '42501';
  end if;

  if v_initiative.status in ('completed', 'cancelled', 'archived') then
    raise exception
      'A iniciativa pai esta encerrada (%).',
      v_initiative.status
      using errcode = '55000';
  end if;

  if v_action.status not in ('in_progress', 'on_hold', 'blocked') then
    raise exception
      'Progresso so pode ser atualizado em acao em execucao, suspensa ou bloqueada.'
      using errcode = '22023';
  end if;

  if target_progress is null
     or target_progress < 0
     or target_progress >= 100 then
    raise exception
      'O progresso deve estar entre 0 e menor que 100; conclusao ocorre via lifecycle.'
      using errcode = '22023';
  end if;

  if v_action.status = 'blocked'
     and v_action.started_at is null
     and target_progress <> 0 then
    raise exception
      'Acao bloqueada antes do inicio deve permanecer com progresso zero.'
      using errcode = '22023';
  end if;

  if target_progress is not distinct from v_action.progress then
    raise exception 'Nenhuma alteracao de progresso foi identificada.'
      using errcode = '22023';
  end if;

  v_before := to_jsonb(v_action);

  update public.sparks_initiative_actions
  set
    progress = target_progress,
    last_update_at = v_now,
    updated_at = v_now,
    updated_by = auth.uid()
  where id = v_action.id;

  select to_jsonb(action)
    into v_after
  from public.sparks_initiative_actions action
  where action.id = v_action.id;

  insert into public.sparks_initiative_action_audit (
    organization_id,
    initiative_id,
    action_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data,
    occurred_at
  )
  values (
    v_action.organization_id,
    v_action.initiative_id,
    v_action.id,
    auth.uid(),
    v_action.source_module_code,
    'initiative_action_execution_updated',
    trim(change_reason),
    v_before,
    v_after,
    v_now
  );

  return v_after;
end;
$$;

-- ============================================================
-- PRIVILEGIOS
-- ============================================================

revoke all
on function public.create_sparks_initiative_action(uuid, jsonb, text)
from public, anon;

revoke all
on function public.update_sparks_initiative_action(uuid, jsonb, text)
from public, anon;

revoke all
on function public.transition_sparks_initiative_action_lifecycle(
  uuid,
  text,
  text
)
from public, anon;

revoke all
on function public.update_sparks_initiative_action_execution(
  uuid,
  numeric,
  text
)
from public, anon;

grant execute
on function public.create_sparks_initiative_action(uuid, jsonb, text)
to authenticated, service_role;

grant execute
on function public.update_sparks_initiative_action(uuid, jsonb, text)
to authenticated, service_role;

grant execute
on function public.transition_sparks_initiative_action_lifecycle(
  uuid,
  text,
  text
)
to authenticated, service_role;

grant execute
on function public.update_sparks_initiative_action_execution(
  uuid,
  numeric,
  text
)
to authenticated, service_role;

comment on function public.create_sparks_initiative_action(
  uuid,
  jsonb,
  text
) is
  'Cria acao transversal por contrato governado, herdando organizacao e modulo da iniciativa pai e sem operar custos/esforco.';

comment on function public.update_sparks_initiative_action(
  uuid,
  jsonb,
  text
) is
  'Atualiza estrutura permitida sem alterar baseline, lifecycle, progresso ou campos economicos.';

comment on function public.transition_sparks_initiative_action_lifecycle(
  uuid,
  text,
  text
) is
  'Executa lifecycle governado e registra inicio, conclusao e arquivamento da acao.';

comment on function public.update_sparks_initiative_action_execution(
  uuid,
  numeric,
  text
) is
  'Atualiza progresso operacional sem concluir automaticamente a acao e sem roll-up para a iniciativa pai.';

-- ============================================================
-- GARANTIAS DO GATE
-- ============================================================
-- 1. authenticated continua sem INSERT/UPDATE/DELETE direto.
-- 2. Toda mutacao ocorre via contratos SECURITY DEFINER com auth
--    e autorizacao internas.
-- 3. Baseline, organizacao, iniciativa e modulo de origem ficam
--    imutaveis depois da criacao.
-- 4. Progresso 100 somente por lifecycle -> completed.
-- 5. Nenhum roll-up para sparks_initiatives.
-- 6. Nenhuma responsabilidade pessoal criada.
-- 7. Nenhuma operacao de custo/esforco exposta.
-- 8. Nenhuma sincronizacao automatica com skpe_*.

commit;