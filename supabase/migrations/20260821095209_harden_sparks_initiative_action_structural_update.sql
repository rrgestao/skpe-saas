begin;

-- ============================================================
-- SPARKs PaaS
-- Gate 17-B.5F.3C.6D — Hardening
--
-- Corrige a deteccao de update estrutural sem mudanca material.
-- A migration historica 20260821094420 permanece imutavel.
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

  v_target_parent_id uuid;
  v_target_code text;
  v_target_name text;
  v_target_description text;
  v_target_action_type text;
  v_target_source_reference text;
  v_target_why_text text;
  v_target_where_text text;
  v_target_how_text text;
  v_target_area_id uuid;
  v_target_planned_start_date date;
  v_target_planned_due_date date;
  v_target_priority text;
  v_target_metadata jsonb;

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
    raise exception
      'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  if action_payload is null
     or jsonb_typeof(action_payload) <> 'object' then
    raise exception
      'O payload da acao deve ser um objeto JSON.'
      using errcode = '22023';
  end if;

  if action_payload = '{}'::jsonb then
    raise exception
      'Nenhuma alteracao estrutural foi informada.'
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
    raise exception
      'Acao nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = v_action.initiative_id;

  if v_initiative.id is null then
    raise exception
      'Iniciativa pai da acao nao foi encontrada.'
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

  if v_initiative.status in (
    'completed',
    'cancelled',
    'archived'
  ) then
    raise exception
      'A iniciativa pai esta encerrada (%).',
      v_initiative.status
      using errcode = '55000';
  end if;

  if v_action.status in (
    'completed',
    'cancelled',
    'archived'
  ) then
    raise exception
      'Acoes encerradas nao podem ser editadas estruturalmente (%).',
      v_action.status
      using errcode = '55000';
  end if;

  v_target_parent_id := case
    when action_payload ? 'parentActionId'
      then nullif(action_payload ->> 'parentActionId', '')::uuid
    else v_action.parent_action_id
  end;

  v_target_code := case
    when action_payload ? 'code'
      then nullif(trim(action_payload ->> 'code'), '')
    else v_action.code
  end;

  v_target_name := case
    when action_payload ? 'name'
      then nullif(trim(action_payload ->> 'name'), '')
    else v_action.name
  end;

  v_target_description := case
    when action_payload ? 'description'
      then nullif(trim(action_payload ->> 'description'), '')
    else v_action.description
  end;

  v_target_action_type := case
    when action_payload ? 'actionType'
      then lower(trim(action_payload ->> 'actionType'))
    else v_action.action_type
  end;

  v_target_source_reference := case
    when action_payload ? 'sourceReference'
      then nullif(trim(action_payload ->> 'sourceReference'), '')
    else v_action.source_reference
  end;

  v_target_why_text := case
    when action_payload ? 'whyText'
      then nullif(trim(action_payload ->> 'whyText'), '')
    else v_action.why_text
  end;

  v_target_where_text := case
    when action_payload ? 'whereText'
      then nullif(trim(action_payload ->> 'whereText'), '')
    else v_action.where_text
  end;

  v_target_how_text := case
    when action_payload ? 'howText'
      then nullif(trim(action_payload ->> 'howText'), '')
    else v_action.how_text
  end;

  v_target_area_id := case
    when action_payload ? 'responsibleAreaId'
      then nullif(action_payload ->> 'responsibleAreaId', '')::uuid
    else v_action.responsible_area_id
  end;

  v_target_planned_start_date := case
    when action_payload ? 'plannedStartDate'
      then nullif(action_payload ->> 'plannedStartDate', '')::date
    else v_action.planned_start_date
  end;

  v_target_planned_due_date := case
    when action_payload ? 'plannedDueDate'
      then nullif(action_payload ->> 'plannedDueDate', '')::date
    else v_action.planned_due_date
  end;

  v_target_priority := case
    when action_payload ? 'priority'
      then lower(trim(action_payload ->> 'priority'))
    else v_action.priority
  end;

  v_target_metadata := case
    when action_payload ? 'metadata'
      then coalesce(action_payload -> 'metadata', '{}'::jsonb)
    else v_action.metadata
  end;

  if v_target_code is null then
    raise exception
      'O codigo da acao nao pode ficar vazio.'
      using errcode = '22023';
  end if;

  if v_target_name is null then
    raise exception
      'O nome da acao nao pode ficar vazio.'
      using errcode = '22023';
  end if;

  if v_target_action_type not in ('action', 'milestone') then
    raise exception
      'Tipo de acao invalido: %.',
      v_target_action_type
      using errcode = '22023';
  end if;

  if v_target_priority not in (
    'low',
    'medium',
    'high',
    'critical'
  ) then
    raise exception
      'Prioridade invalida: %.',
      v_target_priority
      using errcode = '22023';
  end if;

  if jsonb_typeof(v_target_metadata) <> 'object' then
    raise exception
      'metadata deve ser um objeto JSON.'
      using errcode = '22023';
  end if;

  if v_target_planned_start_date is not null
     and v_target_planned_due_date is not null
     and v_target_planned_due_date < v_target_planned_start_date then
    raise exception
      'A data prevista de conclusao nao pode anteceder o inicio previsto.'
      using errcode = '22023';
  end if;

  if v_target_parent_id = v_action.id then
    raise exception
      'Uma acao nao pode ser pai de si propria.'
      using errcode = '22023';
  end if;

  if v_target_parent_id is not null
     and not exists (
       select 1
       from public.sparks_initiative_actions parent_action
       where parent_action.id = v_target_parent_id
         and parent_action.organization_id = v_action.organization_id
         and parent_action.initiative_id = v_action.initiative_id
         and parent_action.archived_at is null
     ) then
    raise exception
      'Acao pai nao pertence a mesma iniciativa ou esta arquivada.'
      using errcode = '22023';
  end if;

  if v_target_parent_id is not null
     and exists (
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
       where id = v_target_parent_id
     ) then
    raise exception
      'A hierarquia de acoes criaria um ciclo.'
      using errcode = '22023';
  end if;

  if v_target_parent_id
       is not distinct from v_action.parent_action_id
     and v_target_code
       is not distinct from v_action.code
     and v_target_name
       is not distinct from v_action.name
     and v_target_description
       is not distinct from v_action.description
     and v_target_action_type
       is not distinct from v_action.action_type
     and v_target_source_reference
       is not distinct from v_action.source_reference
     and v_target_why_text
       is not distinct from v_action.why_text
     and v_target_where_text
       is not distinct from v_action.where_text
     and v_target_how_text
       is not distinct from v_action.how_text
     and v_target_area_id
       is not distinct from v_action.responsible_area_id
     and v_target_planned_start_date
       is not distinct from v_action.planned_start_date
     and v_target_planned_due_date
       is not distinct from v_action.planned_due_date
     and v_target_priority
       is not distinct from v_action.priority
     and v_target_metadata
       is not distinct from v_action.metadata then
    raise exception
      'Nenhuma alteracao estrutural efetiva foi identificada.'
      using errcode = '22023';
  end if;

  v_before := to_jsonb(v_action);

  update public.sparks_initiative_actions
  set
    parent_action_id = v_target_parent_id,
    code = v_target_code,
    name = v_target_name,
    description = v_target_description,
    action_type = v_target_action_type,
    source_reference = v_target_source_reference,
    why_text = v_target_why_text,
    where_text = v_target_where_text,
    how_text = v_target_how_text,
    responsible_area_id = v_target_area_id,
    planned_start_date = v_target_planned_start_date,
    planned_due_date = v_target_planned_due_date,
    priority = v_target_priority,
    metadata = v_target_metadata,
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

revoke all
on function public.update_sparks_initiative_action(
  uuid,
  jsonb,
  text
)
from public, anon;

grant execute
on function public.update_sparks_initiative_action(
  uuid,
  jsonb,
  text
)
to authenticated, service_role;

comment on function public.update_sparks_initiative_action(
  uuid,
  jsonb,
  text
) is
  'Atualiza atributos estruturais permitidos e rejeita updates sem mudanca material antes de alterar timestamps ou gerar auditoria.';

commit;