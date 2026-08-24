-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.6H-S5A
-- Governed Temporal Persistence
--
-- Canonical semantics:
--   baseline  = compromisso temporal original
--   plan      = plano vigente
--   forecast  = melhor estimativa operacional atual
--   actual    = realizado via lifecycle
--
-- Out of scope:
--   derived temporal projection / Gantt (6H-S5B+)
--   agenda/events (6I)
--   costs/effort governance (6J)
-- ============================================================

begin;

alter table public.sparks_initiatives
  add column baseline_start_date date,
  add column baseline_target_end_date date,
  add column forecast_start_date date,
  add column forecast_end_date date,
  add column started_at timestamptz;

alter table public.sparks_initiative_actions
  add column forecast_start_date date,
  add column forecast_due_date date;

alter table public.sparks_initiatives
  add constraint sparks_initiatives_baseline_range_check
  check (
    baseline_start_date is null
    or baseline_target_end_date is null
    or baseline_target_end_date >= baseline_start_date
  ),
  add constraint sparks_initiatives_forecast_range_check
  check (
    forecast_start_date is null
    or forecast_end_date is null
    or forecast_end_date >= forecast_start_date
  );

alter table public.sparks_initiative_actions
  add constraint sparks_initiative_actions_forecast_range_check
  check (
    forecast_start_date is null
    or forecast_due_date is null
    or forecast_due_date >= forecast_start_date
  );

create or replace function public.set_sparks_initiative_temporal_baseline(
  target_initiative_id uuid,
  target_baseline_start_date date,
  target_baseline_end_date date,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_initiative public.sparks_initiatives%rowtype;
  v_before jsonb;
  v_after jsonb;
  v_now timestamptz := timezone('utc', now());
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = target_initiative_id
    and archived_at is null
  for update;

  if v_initiative.id is null then
    raise exception 'Iniciativa nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_initiative.organization_id,
    v_initiative.source_module_code
  ) then
    raise exception 'Acesso negado: o usuario nao pode gerir esta iniciativa.'
      using errcode = '42501';
  end if;

  if v_initiative.status not in (
    'approved',
    'planned',
    'in_progress',
    'on_hold',
    'blocked'
  ) then
    raise exception
      'Baseline temporal exige iniciativa aprovada ou em execucao governada.'
      using errcode = '55000';
  end if;

  if v_initiative.baseline_start_date is not null
     or v_initiative.baseline_target_end_date is not null then
    raise exception 'A baseline temporal da iniciativa ja foi estabelecida.'
      using errcode = '55000';
  end if;

  if target_baseline_start_date is null
     or target_baseline_end_date is null then
    raise exception 'Informe inicio e fim da baseline temporal.'
      using errcode = '22023';
  end if;

  if target_baseline_end_date < target_baseline_start_date then
    raise exception 'O fim da baseline nao pode ser anterior ao inicio.'
      using errcode = '22023';
  end if;

  v_before := jsonb_build_object(
    'baseline_start_date', v_initiative.baseline_start_date,
    'baseline_target_end_date', v_initiative.baseline_target_end_date
  );

  update public.sparks_initiatives
  set
    baseline_start_date = target_baseline_start_date,
    baseline_target_end_date = target_baseline_end_date,
    updated_at = v_now,
    updated_by = auth.uid()
  where id = v_initiative.id;

  select jsonb_build_object(
    'baseline_start_date', baseline_start_date,
    'baseline_target_end_date', baseline_target_end_date
  )
  into v_after
  from public.sparks_initiatives
  where id = v_initiative.id;

  insert into public.sparks_initiative_audit (
    organization_id,
    initiative_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_initiative.organization_id,
    v_initiative.id,
    auth.uid(),
    v_initiative.source_module_code,
    'initiative_temporal_baseline_established',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_after;
end;
$$;

create or replace function public.update_sparks_initiative_temporal_plan(
  target_initiative_id uuid,
  target_plan_start_date date,
  target_plan_end_date date,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_initiative public.sparks_initiatives%rowtype;
  v_before jsonb;
  v_after jsonb;
  v_now timestamptz := timezone('utc', now());
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = target_initiative_id
    and archived_at is null
  for update;

  if v_initiative.id is null then
    raise exception 'Iniciativa nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_initiative.organization_id,
    v_initiative.source_module_code
  ) then
    raise exception 'Acesso negado: o usuario nao pode gerir esta iniciativa.'
      using errcode = '42501';
  end if;

  if v_initiative.status in ('completed', 'cancelled', 'archived') then
    raise exception 'Iniciativa encerrada nao pode ser replanejada.'
      using errcode = '55000';
  end if;

  if target_plan_start_date is not null
     and target_plan_end_date is not null
     and target_plan_end_date < target_plan_start_date then
    raise exception 'O fim do plano vigente nao pode ser anterior ao inicio.'
      using errcode = '22023';
  end if;

  if target_plan_start_date is not distinct from v_initiative.start_date
     and target_plan_end_date is not distinct from v_initiative.target_end_date then
    raise exception 'Nenhuma alteracao temporal do plano foi identificada.'
      using errcode = '22023';
  end if;

  v_before := jsonb_build_object(
    'start_date', v_initiative.start_date,
    'target_end_date', v_initiative.target_end_date
  );

  update public.sparks_initiatives
  set
    start_date = target_plan_start_date,
    target_end_date = target_plan_end_date,
    updated_at = v_now,
    updated_by = auth.uid()
  where id = v_initiative.id;

  select jsonb_build_object(
    'start_date', start_date,
    'target_end_date', target_end_date
  )
  into v_after
  from public.sparks_initiatives
  where id = v_initiative.id;

  insert into public.sparks_initiative_audit (
    organization_id,
    initiative_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_initiative.organization_id,
    v_initiative.id,
    auth.uid(),
    v_initiative.source_module_code,
    'initiative_temporal_plan_updated',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_after;
end;
$$;

create or replace function public.update_sparks_initiative_temporal_forecast(
  target_initiative_id uuid,
  target_forecast_start_date date,
  target_forecast_end_date date,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_initiative public.sparks_initiatives%rowtype;
  v_before jsonb;
  v_after jsonb;
  v_now timestamptz := timezone('utc', now());
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  select *
    into v_initiative
  from public.sparks_initiatives
  where id = target_initiative_id
    and archived_at is null
  for update;

  if v_initiative.id is null then
    raise exception 'Iniciativa nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_initiative.organization_id,
    v_initiative.source_module_code
  ) then
    raise exception 'Acesso negado: o usuario nao pode gerir esta iniciativa.'
      using errcode = '42501';
  end if;

  if v_initiative.status in ('completed', 'cancelled', 'archived') then
    raise exception 'Iniciativa encerrada nao pode ter forecast alterado.'
      using errcode = '55000';
  end if;

  if target_forecast_start_date is not null
     and target_forecast_end_date is not null
     and target_forecast_end_date < target_forecast_start_date then
    raise exception 'O fim do forecast nao pode ser anterior ao inicio.'
      using errcode = '22023';
  end if;

  if target_forecast_start_date is not distinct from v_initiative.forecast_start_date
     and target_forecast_end_date is not distinct from v_initiative.forecast_end_date then
    raise exception 'Nenhuma alteracao de forecast foi identificada.'
      using errcode = '22023';
  end if;

  v_before := jsonb_build_object(
    'forecast_start_date', v_initiative.forecast_start_date,
    'forecast_end_date', v_initiative.forecast_end_date
  );

  update public.sparks_initiatives
  set
    forecast_start_date = target_forecast_start_date,
    forecast_end_date = target_forecast_end_date,
    updated_at = v_now,
    updated_by = auth.uid()
  where id = v_initiative.id;

  select jsonb_build_object(
    'forecast_start_date', forecast_start_date,
    'forecast_end_date', forecast_end_date
  )
  into v_after
  from public.sparks_initiatives
  where id = v_initiative.id;

  insert into public.sparks_initiative_audit (
    organization_id,
    initiative_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_initiative.organization_id,
    v_initiative.id,
    auth.uid(),
    v_initiative.source_module_code,
    'initiative_temporal_forecast_updated',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_after;
end;
$$;

create or replace function public.update_sparks_initiative_action_temporal_forecast(
  target_action_id uuid,
  target_forecast_start_date date,
  target_forecast_due_date date,
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

  if length(trim(coalesce(change_reason, ''))) < 10 then
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
    raise exception 'Iniciativa pai da acao nao encontrada.'
      using errcode = '55000';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_action.organization_id,
    v_action.source_module_code
  ) then
    raise exception 'Acesso negado: o usuario nao pode gerir esta acao.'
      using errcode = '42501';
  end if;

  if v_initiative.status in ('completed', 'cancelled', 'archived')
     or v_action.status in ('completed', 'cancelled', 'archived') then
    raise exception 'Acao encerrada ou iniciativa pai encerrada nao pode ter forecast alterado.'
      using errcode = '55000';
  end if;

  if target_forecast_start_date is not null
     and target_forecast_due_date is not null
     and target_forecast_due_date < target_forecast_start_date then
    raise exception 'O fim do forecast nao pode ser anterior ao inicio.'
      using errcode = '22023';
  end if;

  if target_forecast_start_date is not distinct from v_action.forecast_start_date
     and target_forecast_due_date is not distinct from v_action.forecast_due_date then
    raise exception 'Nenhuma alteracao de forecast foi identificada.'
      using errcode = '22023';
  end if;

  v_before := jsonb_build_object(
    'forecast_start_date', v_action.forecast_start_date,
    'forecast_due_date', v_action.forecast_due_date
  );

  update public.sparks_initiative_actions
  set
    forecast_start_date = target_forecast_start_date,
    forecast_due_date = target_forecast_due_date,
    last_update_at = v_now,
    updated_at = v_now,
    updated_by = auth.uid()
  where id = v_action.id;

  select jsonb_build_object(
    'forecast_start_date', forecast_start_date,
    'forecast_due_date', forecast_due_date
  )
  into v_after
  from public.sparks_initiative_actions
  where id = v_action.id;

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
    'initiative_action_temporal_forecast_updated',
    trim(change_reason),
    v_before,
    v_after,
    v_now
  );

  return v_after;
end;
$$;

-- ============================================================
-- BASELINE PHYSICAL PROTECTION
-- ============================================================

create or replace function public.sparks_protect_initiative_temporal_baseline()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (
    old.baseline_start_date is not null
    or old.baseline_target_end_date is not null
  )
  and (
    new.baseline_start_date is distinct from old.baseline_start_date
    or new.baseline_target_end_date is distinct from old.baseline_target_end_date
  ) then
    raise exception 'A baseline temporal original da iniciativa e imutavel.'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

create trigger sparks_initiatives_protect_temporal_baseline
before update of
  baseline_start_date,
  baseline_target_end_date
on public.sparks_initiatives
for each row
execute function public.sparks_protect_initiative_temporal_baseline();

revoke all
on function public.sparks_protect_initiative_temporal_baseline()
from public, anon, authenticated;

grant execute
on function public.sparks_protect_initiative_temporal_baseline()
to service_role;

comment on function public.sparks_protect_initiative_temporal_baseline() is
  'Protege fisicamente a baseline temporal original da iniciativa depois de estabelecida.';

-- ============================================================
-- LIFECYCLE HARDENING: ACTUAL START
-- ============================================================

create or replace function public.transition_sparks_initiative_lifecycle(
  target_initiative_id uuid,
  target_status text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_initiative public.sparks_initiatives%rowtype;
  v_target_status text;
  v_now timestamptz := timezone('utc', now());
  v_before jsonb;
  v_after jsonb;
begin
  select *
    into v_initiative
  from public.sparks_initiatives
  where id = target_initiative_id
    and archived_at is null
  for update;

  if v_initiative.id is null then
    raise exception 'Iniciativa nao encontrada ou ja arquivada.'
      using errcode = '22023';
  end if;

  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if not public.can_manage_sparks_initiatives(
    v_initiative.organization_id,
    v_initiative.source_module_code
  ) then
    raise exception 'Acesso negado: o usuario nao pode gerir esta iniciativa.'
      using errcode = '42501';
  end if;

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  v_target_status := lower(trim(target_status));

  if v_target_status is null or v_target_status not in (
    'proposed','under_analysis','approved','planned','in_progress',
    'on_hold','blocked','completed','cancelled','archived'
  ) then
    raise exception 'Status de lifecycle invalido: %.', target_status
      using errcode = '22023';
  end if;

  if v_target_status = v_initiative.status then
    raise exception 'A iniciativa ja esta no status "%".', v_target_status
      using errcode = '22023';
  end if;

  if not (
    (v_initiative.status = 'proposed' and v_target_status in ('under_analysis','cancelled'))
    or (v_initiative.status = 'under_analysis' and v_target_status in ('proposed','approved','cancelled'))
    or (v_initiative.status = 'approved' and v_target_status in ('planned','cancelled'))
    or (v_initiative.status = 'planned' and v_target_status in ('in_progress','cancelled'))
    or (v_initiative.status = 'in_progress' and v_target_status in ('on_hold','blocked','completed','cancelled'))
    or (v_initiative.status = 'on_hold' and v_target_status in ('in_progress','cancelled'))
    or (v_initiative.status = 'blocked' and v_target_status in ('in_progress','on_hold','cancelled'))
    or (v_initiative.status = 'completed' and v_target_status = 'archived')
    or (v_initiative.status = 'cancelled' and v_target_status = 'archived')
  ) then
    raise exception 'Transicao de lifecycle nao permitida: % -> %.',
      v_initiative.status, v_target_status
      using errcode = '22023';
  end if;

  v_before := jsonb_build_object(
    'status', v_initiative.status,
    'progress', v_initiative.progress,
    'health_status', v_initiative.health_status,
    'started_at', v_initiative.started_at,
    'completed_at', v_initiative.completed_at,
    'archived_at', v_initiative.archived_at
  );

  update public.sparks_initiatives
  set
    status = v_target_status,
    started_at = case
      when v_target_status = 'in_progress'
        then coalesce(started_at, v_now)
      else started_at
    end,
    progress = case
      when v_target_status = 'completed' then 100
      else progress
    end,
    health_status = case
      when v_target_status = 'completed' then 'completed'
      else health_status
    end,
    completed_at = case
      when v_target_status = 'completed' then v_now
      else completed_at
    end,
    archived_at = case
      when v_target_status = 'archived' then v_now
      else archived_at
    end,
    archived_by = case
      when v_target_status = 'archived' then auth.uid()
      else archived_by
    end,
    last_update_at = v_now,
    updated_at = v_now,
    updated_by = auth.uid()
  where id = v_initiative.id;

  select jsonb_build_object(
    'status', status,
    'progress', progress,
    'health_status', health_status,
    'started_at', started_at,
    'completed_at', completed_at,
    'archived_at', archived_at
  )
    into v_after
  from public.sparks_initiatives
  where id = v_initiative.id;

  insert into public.sparks_initiative_audit (
    organization_id,
    initiative_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_initiative.organization_id,
    v_initiative.id,
    auth.uid(),
    v_initiative.source_module_code,
    'initiative_lifecycle_transitioned',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_after;
end;
$$;

revoke all
on function public.transition_sparks_initiative_lifecycle(uuid, text, text)
from public, anon;

grant execute
on function public.transition_sparks_initiative_lifecycle(uuid, text, text)
to authenticated, service_role;

comment on function public.transition_sparks_initiative_lifecycle(uuid, text, text) is
  'Executa lifecycle governado da iniciativa transversal e materializa started_at na primeira entrada em in_progress.';
revoke all
on function public.set_sparks_initiative_temporal_baseline(uuid, date, date, text)
from public, anon;

revoke all
on function public.update_sparks_initiative_temporal_plan(uuid, date, date, text)
from public, anon;

revoke all
on function public.update_sparks_initiative_temporal_forecast(uuid, date, date, text)
from public, anon;

revoke all
on function public.update_sparks_initiative_action_temporal_forecast(uuid, date, date, text)
from public, anon;

grant execute
on function public.set_sparks_initiative_temporal_baseline(uuid, date, date, text)
to authenticated, service_role;

grant execute
on function public.update_sparks_initiative_temporal_plan(uuid, date, date, text)
to authenticated, service_role;

grant execute
on function public.update_sparks_initiative_temporal_forecast(uuid, date, date, text)
to authenticated, service_role;

grant execute
on function public.update_sparks_initiative_action_temporal_forecast(uuid, date, date, text)
to authenticated, service_role;

comment on function public.set_sparks_initiative_temporal_baseline(uuid, date, date, text) is
  'Estabelece uma unica vez a baseline temporal original de uma iniciativa transversal.';

comment on function public.update_sparks_initiative_temporal_plan(uuid, date, date, text) is
  'Atualiza de forma governada o plano temporal vigente da iniciativa, preservando a baseline.';

comment on function public.update_sparks_initiative_temporal_forecast(uuid, date, date, text) is
  'Atualiza de forma governada o forecast temporal da iniciativa sem alterar baseline ou plano vigente.';

comment on function public.update_sparks_initiative_action_temporal_forecast(uuid, date, date, text) is
  'Atualiza de forma governada o forecast temporal de uma acao transversal.';

commit;