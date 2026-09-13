begin;

alter table public.sparks_events
  add column if not exists visibility_scope text not null default 'participants';

do $block$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.sparks_events'::regclass
      and conname = 'sparks_events_visibility_scope_check'
  ) then
    alter table public.sparks_events
      add constraint sparks_events_visibility_scope_check
      check (visibility_scope in ('participants','organization'));
  end if;
end
$block$;

comment on column public.sparks_events.visibility_scope is
  'Audience of the single canonical event. participants = only directly involved people; organization = institutional visibility to authorized organization readers without making them participants.';
create or replace function public.set_sparks_event_visibility_scope(
  target_event_id uuid,
  target_visibility_scope text,
  change_reason text
)
returns text
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_event public.sparks_events%rowtype;
  v_scope text := lower(trim(coalesce(target_visibility_scope,'')));
  v_before jsonb;
  v_after jsonb;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode='42501';
  end if;
  if v_scope not in ('participants','organization') then
    raise exception 'Escopo de visibilidade invalido.' using errcode='22023';
  end if;
  if length(trim(coalesce(change_reason,''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode='22023';
  end if;
  select * into v_event
  from public.sparks_events
  where id = target_event_id
    and archived_at is null
  for update;

  if v_event.id is null then
    raise exception 'Evento nao encontrado ou arquivado.' using errcode='22023';
  end if;

  if not public.can_manage_sparks_event_source(
    v_event.organization_id,
    v_event.source_module_code,
    v_event.source_entity_type,
    v_event.source_entity_id
  ) then
    raise exception 'Acesso negado: o usuario nao pode alterar a visibilidade deste evento.' using errcode='42501';
  end if;

  v_before := to_jsonb(v_event);

  update public.sparks_events
  set visibility_scope = v_scope,
      updated_by = auth.uid(),
      updated_at = timezone('utc',now())
  where id = v_event.id;
  select to_jsonb(e) into v_after
  from public.sparks_events e
  where e.id = v_event.id;

  insert into public.sparks_agenda_audit(
    organization_id,event_id,actor_user_id,action_code,change_reason,previous_data,new_data
  ) values (
    v_event.organization_id,v_event.id,auth.uid(),'event.visibility.changed',
    trim(change_reason),v_before,v_after
  );

  return v_scope;
end;
$function$;

revoke all on function public.set_sparks_event_visibility_scope(uuid,text,text)
  from public, anon;
grant execute on function public.set_sparks_event_visibility_scope(uuid,text,text)
  to authenticated, service_role;

comment on function public.set_sparks_event_visibility_scope(uuid,text,text) is
  'Governed audience change for one canonical SPARKs event. Institutional visibility never creates participant records.';
create or replace function public.get_sparks_organization_event_feed(
  target_organization_id uuid,
  target_date_from date default null,
  target_date_to date default null,
  target_module_code text default null
)
returns table (
  event_id uuid,
  organization_id uuid,
  source_module_code text,
  event_type text,
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  all_day boolean,
  timezone_name text,
  status text,
  priority text,
  visibility_scope text,
  is_participant boolean,
  participant_role text,
  participant_function text,
  response_status text,
  attendance_status text,
  engagement_level text,
  engagement_message text,
  detail_access boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode='42501';
  end if;

  if target_date_from is not null
     and target_date_to is not null
     and target_date_from > target_date_to then
    raise exception 'Intervalo de datas invalido.' using errcode='22023';
  end if;

  return query
  with current_participant as (
    select ep.*
    from public.sparks_event_participants ep
    where ep.user_id = auth.uid()
  )
  select
    e.id,
    e.organization_id,
    e.source_module_code,
    e.event_type,
    e.title,
    case
      when cp.id is not null
        or e.source_module_code is null
        or public.has_module_access(e.organization_id,e.source_module_code)
      then e.description
      else null
    end,
    e.starts_at,
    e.ends_at,
    e.all_day,
    coalesce(nullif(trim(e.timezone_name),''),'UTC')::text,
    e.status,
    e.priority,
    e.visibility_scope,
    (cp.id is not null),
    cp.participant_role,
    cp.participant_function,
    cp.response_status,
    cp.attendance_status,
    case when cp.id is not null then 'participant' else 'institutional' end,
    case
      when cp.id is not null and cp.response_status = 'pending'
        then 'Sua participação requer confirmação.'
      when cp.id is not null
        then 'Você participa desta reunião estratégica.'
      else 'A estratégia está em movimento: acompanhe este evento institucional.'
    end,
    (
      cp.id is not null
      or e.source_module_code is null
      or public.has_module_access(e.organization_id,e.source_module_code)
    )
  from public.sparks_events e
  left join current_participant cp on cp.event_id = e.id
  where e.organization_id = target_organization_id
    and e.status <> 'archived'
    and (
      cp.id is not null
      or (
        e.visibility_scope = 'organization'
        and public.can_read_organization(e.organization_id)
      )
    )
    and (
      target_module_code is null
      or e.source_module_code = upper(trim(target_module_code))
    )
    and (
      target_date_from is null
      or e.starts_at is null
      or e.starts_at::date >= target_date_from
    )
    and (
      target_date_to is null
      or e.starts_at is null
      or e.starts_at::date <= target_date_to
    )
  order by e.starts_at asc nulls last, e.title, e.id;
end;
$function$;

revoke all on function public.get_sparks_organization_event_feed(uuid,date,date,text)
  from public, anon;
grant execute on function public.get_sparks_organization_event_feed(uuid,date,date,text)
  to authenticated, service_role;

comment on function public.get_sparks_organization_event_feed(uuid,date,date,text) is
  'Single-event institutional and participant-aware projection. Organization readers see institutional movement; participants receive richer engagement without duplicating the event.';

commit;
