begin;

-- 17-B.5F.3C.6L-PROPOSED
-- Govern the actual execution timeline already persisted on skpe_journey_items.
-- Preserve historical actual dates, prevent lifecycle regressions and keep
-- compatibility with existing callers of set_skpe_journey_item_status.

alter table public.skpe_journey_items
  add constraint skpe_journey_items_actual_dates_check
  check (
    actual_end_date is null
    or (
      actual_start_date is not null
      and actual_end_date >= actual_start_date
    )
  ) not valid;

alter table public.skpe_journey_items
  validate constraint skpe_journey_items_actual_dates_check;

create or replace function public.transition_skpe_journey_item_execution(
  target_item_id uuid,
  target_status text,
  target_progress numeric,
  change_reason text,
  target_effective_date date default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_item public.skpe_journey_items%rowtype;
  v_project public.skpe_projects%rowtype;
  v_timezone text;
  v_today date;
  v_effective_date date;
  v_target_status text;
  v_before jsonb;
  v_after jsonb;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  select *
    into v_item
  from public.skpe_journey_items
  where id = target_item_id
    and archived_at is null
  for update;

  if v_item.id is null then
    raise exception 'Item ativo da jornada nao encontrado.'
      using errcode = '22023';
  end if;

  select p.*
    into v_project
  from public.skpe_projects p
  where p.id = v_item.project_id
    and p.archived_at is null;

  if v_project.id is null then
    raise exception 'Projeto SK-PE ativo do item nao encontrado.'
      using errcode = '55000';
  end if;

  if not public.can_manage_skpe_journey(v_project.organization_id) then
    raise exception 'Acesso negado para gerir a jornada.'
      using errcode = '42501';
  end if;

  select coalesce(nullif(trim(o.timezone_name), ''), 'UTC')
    into v_timezone
  from public.organizations o
  where o.id = v_project.organization_id;

  v_today := timezone(coalesce(v_timezone, 'UTC'), now())::date;
  v_effective_date := coalesce(target_effective_date, v_today);
  v_target_status := lower(trim(target_status));

  if v_effective_date > v_today then
    raise exception 'A data efetiva do realizado nao pode estar no futuro.'
      using errcode = '22023';
  end if;

  if v_target_status is null
     or v_target_status not in (
       'not_started',
       'in_progress',
       'blocked',
       'pending_validation',
       'completed',
       'cancelled'
     ) then
    raise exception 'Status de execucao da jornada invalido: %.', target_status
      using errcode = '22023';
  end if;

  if target_progress is null
     or target_progress < 0
     or target_progress > 100 then
    raise exception 'Progresso deve estar entre 0 e 100.'
      using errcode = '22023';
  end if;

  if v_target_status = 'not_started' and target_progress <> 0 then
    raise exception 'Item nao iniciado deve permanecer com progresso zero.'
      using errcode = '22023';
  end if;

  if v_target_status = 'completed' then
    target_progress := 100;
  elsif target_progress = 100 then
    raise exception 'Progresso 100 exige conclusao via lifecycle.'
      using errcode = '22023';
  end if;

  if v_item.status = v_target_status then
    if target_progress is not distinct from v_item.progress then
      raise exception 'Nenhuma alteracao de execucao foi identificada.'
        using errcode = '22023';
    end if;

    if v_target_status not in ('in_progress', 'blocked', 'pending_validation') then
      raise exception 'O status atual nao admite atualizacao isolada de progresso.'
        using errcode = '22023';
    end if;
  else
    if not (
      (v_item.status = 'not_started' and v_target_status in ('in_progress', 'blocked', 'cancelled'))
      or (v_item.status = 'in_progress' and v_target_status in ('blocked', 'pending_validation', 'completed', 'cancelled'))
      or (v_item.status = 'blocked' and v_target_status in ('in_progress', 'cancelled'))
      or (v_item.status = 'pending_validation' and v_target_status in ('in_progress', 'blocked', 'completed', 'cancelled'))
    ) then
      raise exception 'Transicao de execucao da jornada nao permitida: % -> %.',
        v_item.status, v_target_status
        using errcode = '22023';
    end if;
  end if;

  if v_item.status = 'blocked'
     and v_item.actual_start_date is null
     and v_target_status = 'in_progress'
     and target_progress > 0
     and v_effective_date is null then
    raise exception 'Inicio efetivo deve possuir data valida.'
      using errcode = '22023';
  end if;

  if v_target_status = 'completed'
     and v_item.actual_start_date is not null
     and v_effective_date < v_item.actual_start_date then
    raise exception 'Conclusao real nao pode anteceder o inicio real.'
      using errcode = '22023';
  end if;

  v_before := jsonb_build_object(
    'status', v_item.status,
    'progress', v_item.progress,
    'blocked', v_item.blocked,
    'blocking_reason', v_item.blocking_reason,
    'actual_start_date', v_item.actual_start_date,
    'actual_end_date', v_item.actual_end_date
  );

  update public.skpe_journey_items
  set
    status = v_target_status,
    progress = target_progress,
    blocked = (v_target_status = 'blocked'),
    blocking_reason = case
      when v_target_status = 'blocked' then trim(change_reason)
      else null
    end,
    is_current = (v_target_status = 'in_progress'),
    actual_start_date = case
      when v_target_status in ('in_progress', 'pending_validation', 'completed')
        then coalesce(actual_start_date, v_effective_date)
      else actual_start_date
    end,
    actual_end_date = case
      when v_target_status = 'completed'
        then coalesce(actual_end_date, v_effective_date)
      else actual_end_date
    end,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = v_item.id;

  select jsonb_build_object(
    'item_id', i.id,
    'project_id', i.project_id,
    'status', i.status,
    'progress', i.progress,
    'blocked', i.blocked,
    'blocking_reason', i.blocking_reason,
    'actual_start_date', i.actual_start_date,
    'actual_end_date', i.actual_end_date,
    'actual_source', 'governed_lifecycle'
  )
    into v_after
  from public.skpe_journey_items i
  where i.id = v_item.id;

  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    journey_item_id,
    actor_user_id,
    action_code,
    reason,
    previous_data,
    new_data,
    occurred_at
  )
  values (
    v_project.organization_id,
    v_project.id,
    v_item.id,
    auth.uid(),
    'journey_item_actual_execution_transitioned',
    trim(change_reason),
    v_before,
    v_after,
    timezone('utc', now())
  );

  perform public.skpe_recalculate_journey_project_internal(
    v_project.id,
    trim(change_reason),
    auth.uid()
  );

  return v_after;
end;
$function$;

create or replace function public.set_skpe_journey_item_status(
  target_item_id uuid,
  target_status text,
  target_progress numeric,
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  perform public.transition_skpe_journey_item_execution(
    target_item_id,
    target_status,
    target_progress,
    change_reason,
    null
  );
end;
$function$;

revoke all on function public.transition_skpe_journey_item_execution(uuid, text, numeric, text, date) from public, anon;
grant execute on function public.transition_skpe_journey_item_execution(uuid, text, numeric, text, date) to authenticated, service_role;

revoke all on function public.set_skpe_journey_item_status(uuid, text, numeric, text) from public, anon;
grant execute on function public.set_skpe_journey_item_status(uuid, text, numeric, text) to authenticated, service_role;

comment on function public.transition_skpe_journey_item_execution(uuid, text, numeric, text, date) is
  'Governed SK-PE journey actual execution lifecycle. Preserves first actual start and completion dates, supports an explicit non-future effective date, prevents terminal-state regression and audits every transition.';

comment on function public.set_skpe_journey_item_status(uuid, text, numeric, text) is
  'Backward-compatible wrapper for the governed SK-PE journey actual execution lifecycle.';

commit;