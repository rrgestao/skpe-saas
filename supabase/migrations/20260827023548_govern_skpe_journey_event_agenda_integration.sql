begin;

-- 17-B.5F.3C.6M-PROPOSED
-- Governed SK-PE Journey <-> SPARKs Events/Agenda integration.
-- sparks_events remains the single event source of truth.
-- Journey events are linked by source_module_code/source_entity_type/source_entity_id.

create or replace function public.can_manage_sparks_event_source(
  target_organization_id uuid,
  target_source_module_code text,
  target_source_entity_type text,
  target_source_entity_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select
    auth.uid() is not null
    and target_organization_id is not null
    and (
      public.can_manage_organization(target_organization_id)
      or (
        upper(trim(coalesce(target_source_module_code, ''))) = 'SK-PE'
        and lower(trim(coalesce(target_source_entity_type, ''))) = 'skpe_journey_item'
        and target_source_entity_id is not null
        and public.has_module_access(target_organization_id, 'SK-PE')
        and public.can_manage_skpe_journey(target_organization_id)
        and exists (
          select 1
          from public.skpe_journey_items ji
          join public.skpe_projects p
            on p.id = ji.project_id
           and p.organization_id = target_organization_id
           and p.archived_at is null
          where ji.id = target_source_entity_id
            and ji.archived_at is null
        )
      )
    );
$function$;

revoke all on function public.can_manage_sparks_event_source(uuid, text, text, uuid) from public, anon, authenticated;
grant execute on function public.can_manage_sparks_event_source(uuid, text, text, uuid) to service_role;

comment on function public.can_manage_sparks_event_source(uuid, text, text, uuid) is
  'Internal authorization predicate for SPARKs event management. Organization managers keep global event authority; SK-PE journey managers receive authority only over events sourced from active skpe_journey_items in the same organization.';

create or replace function public.create_sparks_event(
  target_organization_id uuid,
  target_event_type text,
  target_title text,
  target_description text default null,
  target_starts_at timestamptz default null,
  target_ends_at timestamptz default null,
  target_all_day boolean default false,
  target_timezone_name text default null,
  target_priority text default 'medium',
  target_source_module_code text default null,
  target_source_entity_type text default null,
  target_source_entity_id uuid default null,
  target_location_text text default null,
  target_meeting_reference text default null,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_event_id uuid;
  v_timezone_name text;
  v_source_module_code text;
  v_source_entity_type text;
  v_auto_participant boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organizacao.' using errcode = '22023';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode = '22023';
  end if;

  v_source_module_code := nullif(upper(trim(coalesce(target_source_module_code, ''))), '');
  v_source_entity_type := nullif(lower(trim(coalesce(target_source_entity_type, ''))), '');

  if v_source_module_code is not null then
    if not exists (
      select 1 from public.modules m
      where m.code = v_source_module_code and m.status = 'active'
    ) then
      raise exception 'Modulo de origem inexistente ou inativo.' using errcode = '22023';
    end if;

    if not public.has_module_access(target_organization_id, v_source_module_code) then
      raise exception 'Acesso negado ao modulo de origem do evento.' using errcode = '42501';
    end if;

    if v_source_entity_type is null then
      raise exception 'Evento associado a modulo exige tipo da entidade de origem.' using errcode = '22023';
    end if;
  else
    if v_source_entity_type is not null or target_source_entity_id is not null then
      raise exception 'Evento nativo SPARKs nao pode declarar entidade de origem sem modulo.' using errcode = '22023';
    end if;
  end if;

  if not public.can_manage_sparks_event_source(
    target_organization_id,
    v_source_module_code,
    v_source_entity_type,
    target_source_entity_id
  ) then
    raise exception 'Acesso negado: o usuario nao pode gerir eventos desta fonte.' using errcode = '42501';
  end if;

  if target_ends_at is not null and target_starts_at is not null and target_ends_at < target_starts_at then
    raise exception 'O termino do evento nao pode ser anterior ao inicio.' using errcode = '22023';
  end if;

  select coalesce(nullif(trim(target_timezone_name), ''), nullif(trim(o.timezone_name), ''), 'UTC')
    into v_timezone_name
  from public.organizations o
  where o.id = target_organization_id;

  if v_timezone_name is null then
    raise exception 'Organizacao nao encontrada.' using errcode = '22023';
  end if;

  if not exists (select 1 from pg_catalog.pg_timezone_names tz where tz.name = v_timezone_name) then
    raise exception 'Timezone do evento invalido.' using errcode = '22023';
  end if;

  insert into public.sparks_events (
    organization_id, event_type, title, description, starts_at, ends_at, all_day,
    timezone_name, status, priority, source_module_code, source_entity_type,
    source_entity_id, location_text, meeting_reference, created_by, updated_by
  ) values (
    target_organization_id,
    lower(trim(target_event_type)),
    trim(target_title),
    nullif(trim(coalesce(target_description, '')), ''),
    target_starts_at,
    target_ends_at,
    coalesce(target_all_day, false),
    v_timezone_name,
    'draft',
    lower(trim(coalesce(target_priority, 'medium'))),
    v_source_module_code,
    v_source_entity_type,
    target_source_entity_id,
    nullif(trim(coalesce(target_location_text, '')), ''),
    nullif(trim(coalesce(target_meeting_reference, '')), ''),
    auth.uid(),
    auth.uid()
  ) returning id into v_event_id;

  insert into public.sparks_agenda_audit (
    organization_id, event_id, actor_user_id, action_code, change_reason, new_data
  )
  select e.organization_id, e.id, auth.uid(), 'event.created', trim(change_reason), to_jsonb(e)
  from public.sparks_events e where e.id = v_event_id;

  if v_source_module_code = 'SK-PE'
     and v_source_entity_type = 'skpe_journey_item'
     and target_source_entity_id is not null then
    select exists (
      select 1
      from public.organization_memberships membership
      join public.profiles profile on profile.id = membership.user_id
      where membership.organization_id = target_organization_id
        and membership.user_id = auth.uid()
        and membership.status = 'active'
        and membership.valid_from <= timezone('utc', now())
        and (membership.valid_until is null or membership.valid_until >= timezone('utc', now()))
        and profile.active = true
    ) and public.has_module_access(target_organization_id, 'SK-PE')
    into v_auto_participant;

    if v_auto_participant then
      insert into public.sparks_event_participants (
        event_id, user_id, participant_role, response_status, attendance_status,
        required, created_by, updated_by
      ) values (
        v_event_id, auth.uid(), 'owner', 'accepted', 'not_recorded', true, auth.uid(), auth.uid()
      )
      on conflict (event_id, user_id) do update set
        participant_role = 'owner',
        response_status = 'accepted',
        required = true,
        updated_by = auth.uid();

      insert into public.sparks_agenda_audit (
        organization_id, event_id, actor_user_id, action_code, change_reason, new_data
      )
      select target_organization_id, v_event_id, auth.uid(), 'event.participant.owner_auto',
             trim(change_reason), to_jsonb(p)
      from public.sparks_event_participants p
      where p.event_id = v_event_id and p.user_id = auth.uid();
    end if;
  end if;

  return v_event_id;
end;
$function$;

create or replace function public.update_sparks_event(
  target_event_id uuid,
  target_event_type text,
  target_title text,
  target_description text default null,
  target_starts_at timestamptz default null,
  target_ends_at timestamptz default null,
  target_all_day boolean default false,
  target_timezone_name text default null,
  target_priority text default 'medium',
  target_location_text text default null,
  target_meeting_reference text default null,
  change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_event public.sparks_events%rowtype;
  v_before jsonb;
  v_after jsonb;
begin
  if auth.uid() is null then raise exception 'Operacao exige usuario autenticado.' using errcode='42501'; end if;
  if length(trim(coalesce(change_reason, ''))) < 10 then raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode='22023'; end if;

  select * into v_event from public.sparks_events where id=target_event_id and archived_at is null for update;
  if v_event.id is null then raise exception 'Evento nao encontrado ou arquivado.' using errcode='22023'; end if;

  if not public.can_manage_sparks_event_source(v_event.organization_id, v_event.source_module_code, v_event.source_entity_type, v_event.source_entity_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir este evento.' using errcode='42501';
  end if;

  if v_event.source_module_code is not null and not public.has_module_access(v_event.organization_id, v_event.source_module_code) then
    raise exception 'Acesso negado ao modulo de origem do evento.' using errcode='42501';
  end if;

  if v_event.status in ('completed','cancelled','archived') then
    raise exception 'Evento encerrado nao pode ter conteudo replanejado.' using errcode='55000';
  end if;

  if target_ends_at is not null and target_starts_at is not null and target_ends_at < target_starts_at then
    raise exception 'O termino do evento nao pode ser anterior ao inicio.' using errcode='22023';
  end if;

  if nullif(trim(coalesce(target_timezone_name,'')),'') is not null
     and not exists (select 1 from pg_catalog.pg_timezone_names tz where tz.name=trim(target_timezone_name)) then
    raise exception 'Timezone do evento invalido.' using errcode='22023';
  end if;

  v_before := to_jsonb(v_event);

  update public.sparks_events set
    event_type=lower(trim(target_event_type)),
    title=trim(target_title),
    description=nullif(trim(coalesce(target_description,'')),''),
    starts_at=target_starts_at,
    ends_at=target_ends_at,
    all_day=coalesce(target_all_day,false),
    timezone_name=coalesce(nullif(trim(target_timezone_name),''), timezone_name),
    priority=lower(trim(coalesce(target_priority,'medium'))),
    location_text=nullif(trim(coalesce(target_location_text,'')),''),
    meeting_reference=nullif(trim(coalesce(target_meeting_reference,'')),''),
    updated_by=auth.uid()
  where id=v_event.id;

  select to_jsonb(e) into v_after from public.sparks_events e where e.id=v_event.id;

  insert into public.sparks_agenda_audit(organization_id,event_id,actor_user_id,action_code,change_reason,previous_data,new_data)
  values(v_event.organization_id,v_event.id,auth.uid(),'event.updated',trim(change_reason),v_before,v_after);

  return v_after;
end;
$function$;

create or replace function public.transition_sparks_event_lifecycle(
  target_event_id uuid,
  target_status text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_event public.sparks_events%rowtype;
  v_target_status text := lower(trim(target_status));
  v_allowed boolean := false;
  v_before jsonb;
  v_after jsonb;
  v_now timestamptz := timezone('utc', now());
begin
  if auth.uid() is null then raise exception 'Operacao exige usuario autenticado.' using errcode='42501'; end if;
  if length(trim(coalesce(change_reason,''))) < 10 then raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode='22023'; end if;

  select * into v_event from public.sparks_events where id=target_event_id for update;
  if v_event.id is null then raise exception 'Evento nao encontrado.' using errcode='22023'; end if;

  if not public.can_manage_sparks_event_source(v_event.organization_id, v_event.source_module_code, v_event.source_entity_type, v_event.source_entity_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir este evento.' using errcode='42501';
  end if;

  if v_event.source_module_code is not null and not public.has_module_access(v_event.organization_id, v_event.source_module_code) then
    raise exception 'Acesso negado ao modulo de origem do evento.' using errcode='42501';
  end if;

  v_allowed :=
    (v_event.status='draft' and v_target_status in ('scheduled','cancelled')) or
    (v_event.status='scheduled' and v_target_status in ('in_progress','completed','cancelled')) or
    (v_event.status='in_progress' and v_target_status in ('completed','cancelled')) or
    (v_event.status='completed' and v_target_status='archived') or
    (v_event.status='cancelled' and v_target_status='archived');

  if not v_allowed then
    raise exception 'Transicao de lifecycle invalida: % -> %.', v_event.status, v_target_status using errcode='55000';
  end if;

  if v_target_status='scheduled' and v_event.starts_at is null then
    raise exception 'Evento agendado exige data/hora de inicio.' using errcode='22023';
  end if;

  v_before := to_jsonb(v_event);

  update public.sparks_events set
    status=v_target_status,
    archived_at=case when v_target_status='archived' then v_now else null end,
    archived_by=case when v_target_status='archived' then auth.uid() else null end,
    updated_by=auth.uid()
  where id=v_event.id;

  select to_jsonb(e) into v_after from public.sparks_events e where e.id=v_event.id;

  insert into public.sparks_agenda_audit(organization_id,event_id,actor_user_id,action_code,change_reason,previous_data,new_data)
  values(v_event.organization_id,v_event.id,auth.uid(),'event.lifecycle.'||v_target_status,trim(change_reason),v_before,v_after);

  return v_after;
end;
$function$;

create or replace function public.set_sparks_event_participant(
  target_event_id uuid,
  target_user_id uuid,
  target_participant_role text,
  target_required boolean default true,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_event public.sparks_events%rowtype;
  v_participant_id uuid;
  v_before jsonb;
  v_after jsonb;
begin
  if auth.uid() is null then raise exception 'Operacao exige usuario autenticado.' using errcode='42501'; end if;
  if length(trim(coalesce(change_reason,''))) < 10 then raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode='22023'; end if;

  select * into v_event from public.sparks_events where id=target_event_id and archived_at is null for update;
  if v_event.id is null then raise exception 'Evento nao encontrado ou arquivado.' using errcode='22023'; end if;

  if not public.can_manage_sparks_event_source(v_event.organization_id, v_event.source_module_code, v_event.source_entity_type, v_event.source_entity_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir participantes deste evento.' using errcode='42501';
  end if;

  if v_event.source_module_code is not null and not public.has_module_access(v_event.organization_id,v_event.source_module_code) then
    raise exception 'Acesso negado ao modulo de origem do evento.' using errcode='42501';
  end if;

  if not exists (
    select 1 from public.organization_memberships membership
    join public.profiles profile on profile.id=membership.user_id
    where membership.organization_id=v_event.organization_id
      and membership.user_id=target_user_id
      and membership.status='active'
      and membership.valid_from <= timezone('utc',now())
      and (membership.valid_until is null or membership.valid_until >= timezone('utc',now()))
      and profile.active=true
  ) then
    raise exception 'Participante precisa ser usuario ativo da organizacao.' using errcode='22023';
  end if;

  if v_event.source_module_code is not null
     and not public.has_module_access_for_user(v_event.organization_id, v_event.source_module_code, target_user_id) then
    raise exception 'Participante nao possui acesso ativo ao modulo de origem do evento.' using errcode='22023';
  end if;

  select to_jsonb(p) into v_before from public.sparks_event_participants p
  where p.event_id=target_event_id and p.user_id=target_user_id;

  insert into public.sparks_event_participants(
    event_id,user_id,participant_role,response_status,attendance_status,required,created_by,updated_by
  ) values(
    target_event_id,target_user_id,lower(trim(target_participant_role)),'pending','not_recorded',coalesce(target_required,true),auth.uid(),auth.uid()
  )
  on conflict(event_id,user_id) do update set
    participant_role=excluded.participant_role,
    required=excluded.required,
    updated_by=auth.uid()
  returning id into v_participant_id;

  select to_jsonb(p) into v_after from public.sparks_event_participants p where p.id=v_participant_id;

  insert into public.sparks_agenda_audit(organization_id,event_id,actor_user_id,action_code,change_reason,previous_data,new_data)
  values(v_event.organization_id,v_event.id,auth.uid(),'event.participant.set',trim(change_reason),v_before,v_after);

  return v_participant_id;
end;
$function$;

create or replace function public.remove_sparks_event_participant(
  target_event_id uuid,
  target_user_id uuid,
  change_reason text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_event public.sparks_events%rowtype;
  v_before jsonb;
begin
  if auth.uid() is null then raise exception 'Operacao exige usuario autenticado.' using errcode='42501'; end if;
  if length(trim(coalesce(change_reason,''))) < 10 then raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode='22023'; end if;

  select * into v_event from public.sparks_events where id=target_event_id and archived_at is null for update;
  if v_event.id is null then raise exception 'Evento nao encontrado ou arquivado.' using errcode='22023'; end if;

  if not public.can_manage_sparks_event_source(v_event.organization_id, v_event.source_module_code, v_event.source_entity_type, v_event.source_entity_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir participantes deste evento.' using errcode='42501';
  end if;

  if v_event.source_module_code is not null and not public.has_module_access(v_event.organization_id,v_event.source_module_code) then
    raise exception 'Acesso negado ao modulo de origem do evento.' using errcode='42501';
  end if;

  select to_jsonb(p) into v_before from public.sparks_event_participants p
  where p.event_id=target_event_id and p.user_id=target_user_id for update;

  if v_before is null then return false; end if;

  delete from public.sparks_event_participants where event_id=target_event_id and user_id=target_user_id;

  insert into public.sparks_agenda_audit(organization_id,event_id,actor_user_id,action_code,change_reason,previous_data)
  values(v_event.organization_id,v_event.id,auth.uid(),'event.participant.removed',trim(change_reason),v_before);

  return true;
end;
$function$;

create or replace function public.record_sparks_event_attendance(
  target_event_id uuid,
  target_user_id uuid,
  target_attendance_status text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_event public.sparks_events%rowtype;
  v_participant public.sparks_event_participants%rowtype;
  v_status text := lower(trim(target_attendance_status));
  v_before jsonb;
  v_after jsonb;
begin
  if auth.uid() is null then raise exception 'Operacao exige usuario autenticado.' using errcode='42501'; end if;
  if length(trim(coalesce(change_reason,''))) < 10 then raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode='22023'; end if;
  if v_status not in ('not_recorded','attended','absent') then raise exception 'Status de presenca invalido.' using errcode='22023'; end if;

  select * into v_event from public.sparks_events where id=target_event_id and archived_at is null for update;
  if v_event.id is null then raise exception 'Evento nao encontrado ou arquivado.' using errcode='22023'; end if;

  if not public.can_manage_sparks_event_source(v_event.organization_id, v_event.source_module_code, v_event.source_entity_type, v_event.source_entity_id) then
    raise exception 'Acesso negado: o usuario nao pode registrar presenca neste evento.' using errcode='42501';
  end if;

  if v_event.source_module_code is not null and not public.has_module_access(v_event.organization_id,v_event.source_module_code) then
    raise exception 'Acesso negado ao modulo de origem do evento.' using errcode='42501';
  end if;

  select * into v_participant from public.sparks_event_participants p
  where p.event_id=target_event_id and p.user_id=target_user_id for update;
  if v_participant.id is null then raise exception 'Usuario nao e participante deste evento.' using errcode='22023'; end if;

  v_before := to_jsonb(v_participant);
  update public.sparks_event_participants set attendance_status=v_status, updated_by=auth.uid() where id=v_participant.id;
  select to_jsonb(p) into v_after from public.sparks_event_participants p where p.id=v_participant.id;

  insert into public.sparks_agenda_audit(organization_id,event_id,actor_user_id,action_code,change_reason,previous_data,new_data)
  values(v_event.organization_id,v_event.id,auth.uid(),'event.participant.attendance',trim(change_reason),v_before,v_after);

  return v_after;
end;
$function$;

create or replace function public.get_skpe_journey_events_projection(
  target_organization_id uuid,
  target_project_id uuid,
  target_date_from date default null,
  target_date_to date default null,
  target_include_cancelled boolean default false,
  target_include_archived boolean default false
)
returns table(
  event_id uuid,
  journey_item_id uuid,
  journey_item_code text,
  journey_item_title text,
  journey_item_type text,
  parent_item_id uuid,
  event_type text,
  event_title text,
  event_description text,
  starts_at timestamptz,
  ends_at timestamptz,
  all_day boolean,
  timezone_name text,
  event_status text,
  priority text,
  location_text text,
  meeting_reference text,
  participant_count bigint,
  accepted_count bigint,
  attended_count bigint,
  current_user_role text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then raise exception 'Operacao exige usuario autenticado.' using errcode='42501'; end if;
  if target_organization_id is null or target_project_id is null then raise exception 'Organizacao e projeto SK-PE sao obrigatorios.' using errcode='22023'; end if;
  if target_date_from is not null and target_date_to is not null and target_date_from > target_date_to then raise exception 'Intervalo de datas invalido.' using errcode='22023'; end if;
  if not public.can_read_organization(target_organization_id) then raise exception 'Acesso negado a organizacao.' using errcode='42501'; end if;
  if not public.has_module_access(target_organization_id,'SK-PE') then raise exception 'Acesso negado ao modulo SK-PE.' using errcode='42501'; end if;
  if not exists (
    select 1 from public.skpe_projects p
    where p.id=target_project_id and p.organization_id=target_organization_id and p.archived_at is null
  ) then raise exception 'Projeto SK-PE ativo nao encontrado na organizacao.' using errcode='P0002'; end if;

  return query
  select
    e.id,
    ji.id,
    ji.code,
    ji.title,
    ji.item_type,
    ji.parent_item_id,
    e.event_type,
    e.title,
    e.description,
    e.starts_at,
    e.ends_at,
    e.all_day,
    coalesce(nullif(trim(e.timezone_name),''), nullif(trim(o.timezone_name),''), 'UTC')::text,
    e.status,
    e.priority,
    e.location_text,
    e.meeting_reference,
    count(ep.id)::bigint,
    count(ep.id) filter (where ep.response_status='accepted')::bigint,
    count(ep.id) filter (where ep.attendance_status='attended')::bigint,
    max(ep.participant_role) filter (where ep.user_id=auth.uid())::text
  from public.sparks_events e
  join public.skpe_journey_items ji
    on ji.id=e.source_entity_id
   and ji.project_id=target_project_id
   and ji.archived_at is null
  join public.skpe_projects p
    on p.id=ji.project_id
   and p.organization_id=target_organization_id
   and p.archived_at is null
  join public.organizations o on o.id=p.organization_id
  left join public.sparks_event_participants ep on ep.event_id=e.id
  where e.organization_id=target_organization_id
    and e.source_module_code='SK-PE'
    and e.source_entity_type='skpe_journey_item'
    and (coalesce(target_include_cancelled,false) or e.status <> 'cancelled')
    and (coalesce(target_include_archived,false) or e.status <> 'archived')
    and (
      target_date_from is null
      or (e.starts_at is not null and timezone(coalesce(nullif(trim(e.timezone_name),''), nullif(trim(o.timezone_name),''), 'UTC'), coalesce(e.ends_at,e.starts_at))::date >= target_date_from)
    )
    and (
      target_date_to is null
      or (e.starts_at is not null and timezone(coalesce(nullif(trim(e.timezone_name),''), nullif(trim(o.timezone_name),''), 'UTC'), e.starts_at)::date <= target_date_to)
    )
  group by e.id, ji.id, ji.code, ji.title, ji.item_type, ji.parent_item_id, o.timezone_name
  order by e.starts_at nulls last, ji.display_order, ji.code, e.id;
end;
$function$;

revoke all on function public.get_skpe_journey_events_projection(uuid, uuid, date, date, boolean, boolean) from public, anon;
grant execute on function public.get_skpe_journey_events_projection(uuid, uuid, date, date, boolean, boolean) to authenticated, service_role;

comment on function public.get_skpe_journey_events_projection(uuid, uuid, date, date, boolean, boolean) is
  'Read-only SK-PE project Journey <-> canonical SPARKs events projection. It never materializes a second agenda or copies event schedule data into journey items.';

create or replace function public.get_skpe_project_operational_projection(
  target_organization_id uuid,
  target_project_id uuid,
  target_as_of_date date default current_date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_base jsonb;
  v_events jsonb := '[]'::jsonb;
  v_reference_date date := coalesce(target_as_of_date,current_date);
begin
  v_base := public.get_skpe_project_management_projection(
    target_organization_id,
    target_project_id,
    v_reference_date
  );

  select coalesce(jsonb_agg(to_jsonb(e) order by e.starts_at nulls last, e.journey_item_code, e.event_id),'[]'::jsonb)
    into v_events
  from public.get_skpe_journey_events_projection(
    target_organization_id,
    target_project_id,
    null,
    null,
    false,
    false
  ) e;

  return jsonb_set(
    v_base || jsonb_build_object('journeyEvents', v_events),
    '{governance}',
    coalesce(v_base->'governance','{}'::jsonb) || jsonb_build_object(
      'eventAuthority','sparks_events/sparks_event_participants',
      'journeyEventLinkAuthority','sparks_events.source_module_code/source_entity_type/source_entity_id',
      'duplicatesAgendaSourceOfTruth',false,
      'journeyEventsIncluded',true,
      'personalAgendaRemainsParticipantScoped',true
    ),
    true
  );
end;
$function$;

revoke all on function public.get_skpe_project_operational_projection(uuid, uuid, date) from public, anon;
grant execute on function public.get_skpe_project_operational_projection(uuid, uuid, date) to authenticated, service_role;

comment on function public.get_skpe_project_operational_projection(uuid, uuid, date) is
  'Integrated SK-PE operational projection: existing 6K management projection plus Journey-linked canonical SPARKs events. Read-only; no duplicated agenda persistence.';

commit;