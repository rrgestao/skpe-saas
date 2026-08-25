-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.6I-S5A
-- Governed Transversal Agenda Persistence Foundation
--
-- Canonical semantics:
--   Agenda = capacidade transversal da plataforma.
--   Native event = autoridade em public.sparks_events.
--   Projected item = permanece autoridade no modulo de origem.
--   Agenda visibility = preferencia pessoal, default visible.
--   Item visibility = preferencia pessoal, default visible.
--   Notifications = capacidade distinta; nao controlada por Agenda.
--
-- Out of scope:
--   SK-PE projection adapters (6I-S5B)
--   unified personal agenda read model (6I-S5C)
--   recurrence / external calendar sync
--   notification delivery/preferences
--   costs / effort governance (6J)
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1. Native transversal events
-- ------------------------------------------------------------
create table public.sparks_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,

  event_type text not null,
  title text not null,
  description text,

  starts_at timestamptz,
  ends_at timestamptz,
  all_day boolean not null default false,
  timezone_name text,

  status text not null default 'draft',
  priority text not null default 'medium',

  source_module_code text,
  source_entity_type text,
  source_entity_id uuid,

  location_text text,
  meeting_reference text,

  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id) on delete set null,

  constraint sparks_events_type_check
    check (event_type in (
      'meeting',
      'review',
      'assembly',
      'workshop',
      'presentation',
      'validation_session',
      'institutional_event',
      'other'
    )),

  constraint sparks_events_status_check
    check (status in (
      'draft',
      'scheduled',
      'in_progress',
      'completed',
      'cancelled',
      'archived'
    )),

  constraint sparks_events_priority_check
    check (priority in ('low', 'medium', 'high', 'critical')),

  constraint sparks_events_title_not_blank
    check (length(trim(title)) > 0),

  constraint sparks_events_time_range_check
    check (
      ends_at is null
      or starts_at is null
      or ends_at >= starts_at
    ),

  constraint sparks_events_source_contract_check
    check (
      (
        source_module_code is null
        and source_entity_type is null
        and source_entity_id is null
      )
      or
      (
        source_module_code is not null
        and source_entity_type is not null
      )
    ),

  constraint sparks_events_source_module_not_blank
    check (
      source_module_code is null
      or length(trim(source_module_code)) > 0
    ),

  constraint sparks_events_source_entity_type_not_blank
    check (
      source_entity_type is null
      or length(trim(source_entity_type)) > 0
    ),

  constraint sparks_events_archive_contract_check
    check (
      (status = 'archived' and archived_at is not null)
      or
      (status <> 'archived' and archived_at is null)
    )
);

comment on table public.sparks_events is
  'Eventos nativos transversais da plataforma SPARKs. Itens projetados por modulos permanecem autoridade em suas fontes e nao sao copiados para esta tabela por default.';

create index ix_sparks_events_org_starts_at
  on public.sparks_events(organization_id, starts_at);

create index ix_sparks_events_org_status
  on public.sparks_events(organization_id, status);

create index ix_sparks_events_source
  on public.sparks_events(source_module_code, source_entity_type, source_entity_id);

create trigger sparks_events_set_updated_at
before update on public.sparks_events
for each row
execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 2. Structural participation in native events
-- ------------------------------------------------------------
create table public.sparks_event_participants (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null
    references public.sparks_events(id) on delete cascade,
  user_id uuid not null
    references public.profiles(id) on delete cascade,

  participant_role text not null default 'participant',
  response_status text not null default 'pending',
  attendance_status text not null default 'not_recorded',
  required boolean not null default true,

  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_event_participants_role_check
    check (participant_role in (
      'owner',
      'chair',
      'secretary',
      'responsible',
      'participant',
      'observer'
    )),

  constraint sparks_event_participants_response_check
    check (response_status in (
      'pending',
      'accepted',
      'declined',
      'tentative'
    )),

  constraint sparks_event_participants_attendance_check
    check (attendance_status in (
      'not_recorded',
      'attended',
      'absent'
    )),

  constraint sparks_event_participants_unique
    unique (event_id, user_id)
);

comment on table public.sparks_event_participants is
  'Vinculo estrutural entre usuarios e eventos nativos SPARKs. Substitui inferencias frageis por JSON para pertencimento pessoal.';

create index ix_sparks_event_participants_user_event
  on public.sparks_event_participants(user_id, event_id);

create index ix_sparks_event_participants_event
  on public.sparks_event_participants(event_id);

create trigger sparks_event_participants_set_updated_at
before update on public.sparks_event_participants
for each row
execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 3. Personal Agenda visibility preference
-- ------------------------------------------------------------
create table public.sparks_user_agenda_preferences (
  user_id uuid primary key
    references public.profiles(id) on delete cascade,
  agenda_visible boolean not null default true,
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.sparks_user_agenda_preferences is
  'Preferencia pessoal de visibilidade da Agenda SPARKs. Ausencia de registro significa agenda visivel.';

-- ------------------------------------------------------------
-- 4. Personal item visibility exceptions
-- ------------------------------------------------------------
create table public.sparks_user_agenda_item_preferences (
  user_id uuid not null
    references public.profiles(id) on delete cascade,
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  agenda_item_key text not null,
  is_visible boolean not null default true,
  updated_at timestamptz not null default timezone('utc', now()),

  primary key (user_id, agenda_item_key),

  constraint sparks_user_agenda_item_preferences_key_not_blank
    check (length(trim(agenda_item_key)) > 0),

  constraint sparks_user_agenda_item_preferences_key_length
    check (length(agenda_item_key) <= 512)
);

comment on table public.sparks_user_agenda_item_preferences is
  'Excecoes pessoais de visibilidade por agenda_item_key. Ausencia de registro significa item visivel.';

-- ------------------------------------------------------------
-- 5. Agenda audit
-- ------------------------------------------------------------
create table public.sparks_agenda_audit (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid
    references public.organizations(id) on delete set null,
  event_id uuid
    references public.sparks_events(id) on delete set null,
  agenda_item_key text,

  actor_user_id uuid
    references public.profiles(id) on delete set null,

  action_code text not null,
  change_reason text,
  previous_data jsonb,
  new_data jsonb,

  occurred_at timestamptz not null default timezone('utc', now()),

  constraint sparks_agenda_audit_action_not_blank
    check (length(trim(action_code)) > 0)
);

comment on table public.sparks_agenda_audit is
  'Trilha de auditoria das mutacoes governadas de eventos, participantes e preferencias pessoais da Agenda SPARKs.';

create index ix_sparks_agenda_audit_org_occurred
  on public.sparks_agenda_audit(organization_id, occurred_at desc);

create index ix_sparks_agenda_audit_event_occurred
  on public.sparks_agenda_audit(event_id, occurred_at desc);

create index ix_sparks_agenda_audit_actor_occurred
  on public.sparks_agenda_audit(actor_user_id, occurred_at desc);

-- ------------------------------------------------------------
-- 6. Governed event creation
-- ------------------------------------------------------------
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
as $$
declare
  v_event_id uuid;
  v_timezone_name text;
  v_source_module_code text;
  v_source_entity_type text;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organizacao.'
      using errcode = '22023';
  end if;

  if not public.can_manage_organization(target_organization_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir eventos desta organizacao.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  v_source_module_code := nullif(upper(trim(coalesce(target_source_module_code, ''))), '');
  v_source_entity_type := nullif(lower(trim(coalesce(target_source_entity_type, ''))), '');

  if v_source_module_code is not null then
    if not exists (
      select 1
      from public.modules m
      where m.code = v_source_module_code
        and m.status = 'active'
    ) then
      raise exception 'Modulo de origem inexistente ou inativo.'
        using errcode = '22023';
    end if;

    if not public.has_module_access(
      target_organization_id,
      v_source_module_code
    ) then
      raise exception 'Acesso negado ao modulo de origem do evento.'
        using errcode = '42501';
    end if;

    if v_source_entity_type is null then
      raise exception 'Evento associado a modulo exige tipo da entidade de origem.'
        using errcode = '22023';
    end if;
  else
    if v_source_entity_type is not null
       or target_source_entity_id is not null then
      raise exception 'Evento nativo SPARKs nao pode declarar entidade de origem sem modulo.'
        using errcode = '22023';
    end if;
  end if;

  if target_ends_at is not null
     and target_starts_at is not null
     and target_ends_at < target_starts_at then
    raise exception 'O termino do evento nao pode ser anterior ao inicio.'
      using errcode = '22023';
  end if;

  select coalesce(
    nullif(trim(target_timezone_name), ''),
    nullif(trim(o.timezone_name), ''),
    'UTC'
  )
  into v_timezone_name
  from public.organizations o
  where o.id = target_organization_id;

  if v_timezone_name is null then
    raise exception 'Organizacao nao encontrada.'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_timezone_names tz
    where tz.name = v_timezone_name
  ) then
    raise exception 'Timezone do evento invalido.'
      using errcode = '22023';
  end if;

  insert into public.sparks_events (
    organization_id,
    event_type,
    title,
    description,
    starts_at,
    ends_at,
    all_day,
    timezone_name,
    status,
    priority,
    source_module_code,
    source_entity_type,
    source_entity_id,
    location_text,
    meeting_reference,
    created_by,
    updated_by
  )
  values (
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
  )
  returning id into v_event_id;

  insert into public.sparks_agenda_audit (
    organization_id,
    event_id,
    actor_user_id,
    action_code,
    change_reason,
    new_data
  )
  select
    e.organization_id,
    e.id,
    auth.uid(),
    'event.created',
    trim(change_reason),
    to_jsonb(e)
  from public.sparks_events e
  where e.id = v_event_id;

  return v_event_id;
end;
$$;

-- ------------------------------------------------------------
-- 7. Governed event content update
--    Provenance and lifecycle are intentionally immutable here.
-- ------------------------------------------------------------
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
as $$
declare
  v_event public.sparks_events%rowtype;
  v_before jsonb;
  v_after jsonb;
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
  into v_event
  from public.sparks_events
  where id = target_event_id
    and archived_at is null
  for update;

  if v_event.id is null then
    raise exception 'Evento nao encontrado ou arquivado.'
      using errcode = '22023';
  end if;

  if not public.can_manage_organization(v_event.organization_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir este evento.'
      using errcode = '42501';
  end if;

  if v_event.source_module_code is not null
     and not public.has_module_access(
       v_event.organization_id,
       v_event.source_module_code
     ) then
    raise exception 'Acesso negado ao modulo de origem do evento.'
      using errcode = '42501';
  end if;

  if v_event.status in ('completed', 'cancelled', 'archived') then
    raise exception 'Evento encerrado nao pode ter conteudo replanejado.'
      using errcode = '55000';
  end if;

  if target_ends_at is not null
     and target_starts_at is not null
     and target_ends_at < target_starts_at then
    raise exception 'O termino do evento nao pode ser anterior ao inicio.'
      using errcode = '22023';
  end if;

  if nullif(trim(coalesce(target_timezone_name, '')), '') is not null
     and not exists (
       select 1
       from pg_catalog.pg_timezone_names tz
       where tz.name = trim(target_timezone_name)
     ) then
    raise exception 'Timezone do evento invalido.'
      using errcode = '22023';
  end if;

  v_before := to_jsonb(v_event);

  update public.sparks_events
  set
    event_type = lower(trim(target_event_type)),
    title = trim(target_title),
    description = nullif(trim(coalesce(target_description, '')), ''),
    starts_at = target_starts_at,
    ends_at = target_ends_at,
    all_day = coalesce(target_all_day, false),
    timezone_name = coalesce(
      nullif(trim(target_timezone_name), ''),
      timezone_name
    ),
    priority = lower(trim(coalesce(target_priority, 'medium'))),
    location_text = nullif(trim(coalesce(target_location_text, '')), ''),
    meeting_reference = nullif(trim(coalesce(target_meeting_reference, '')), ''),
    updated_by = auth.uid()
  where id = v_event.id;

  select to_jsonb(e)
  into v_after
  from public.sparks_events e
  where e.id = v_event.id;

  insert into public.sparks_agenda_audit (
    organization_id,
    event_id,
    actor_user_id,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_event.organization_id,
    v_event.id,
    auth.uid(),
    'event.updated',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_after;
end;
$$;

-- ------------------------------------------------------------
-- 8. Governed event lifecycle
-- ------------------------------------------------------------
create or replace function public.transition_sparks_event_lifecycle(
  target_event_id uuid,
  target_status text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.sparks_events%rowtype;
  v_target_status text := lower(trim(target_status));
  v_allowed boolean := false;
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
  into v_event
  from public.sparks_events
  where id = target_event_id
  for update;

  if v_event.id is null then
    raise exception 'Evento nao encontrado.'
      using errcode = '22023';
  end if;

  if not public.can_manage_organization(v_event.organization_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir este evento.'
      using errcode = '42501';
  end if;

  if v_event.source_module_code is not null
     and not public.has_module_access(
       v_event.organization_id,
       v_event.source_module_code
     ) then
    raise exception 'Acesso negado ao modulo de origem do evento.'
      using errcode = '42501';
  end if;

  v_allowed :=
    (v_event.status = 'draft' and v_target_status in ('scheduled', 'cancelled'))
    or
    (v_event.status = 'scheduled' and v_target_status in ('in_progress', 'completed', 'cancelled'))
    or
    (v_event.status = 'in_progress' and v_target_status in ('completed', 'cancelled'))
    or
    (v_event.status = 'completed' and v_target_status = 'archived')
    or
    (v_event.status = 'cancelled' and v_target_status = 'archived');

  if not v_allowed then
    raise exception
      'Transicao de lifecycle invalida: % -> %.',
      v_event.status,
      v_target_status
      using errcode = '55000';
  end if;

  if v_target_status = 'scheduled'
     and v_event.starts_at is null then
    raise exception 'Evento agendado exige data/hora de inicio.'
      using errcode = '22023';
  end if;

  v_before := to_jsonb(v_event);

  update public.sparks_events
  set
    status = v_target_status,
    archived_at = case
      when v_target_status = 'archived' then v_now
      else null
    end,
    archived_by = case
      when v_target_status = 'archived' then auth.uid()
      else null
    end,
    updated_by = auth.uid()
  where id = v_event.id;

  select to_jsonb(e)
  into v_after
  from public.sparks_events e
  where e.id = v_event.id;

  insert into public.sparks_agenda_audit (
    organization_id,
    event_id,
    actor_user_id,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_event.organization_id,
    v_event.id,
    auth.uid(),
    'event.lifecycle.' || v_target_status,
    trim(change_reason),
    v_before,
    v_after
  );

  return v_after;
end;
$$;

-- ------------------------------------------------------------
-- 9. Governed participant upsert/removal
-- ------------------------------------------------------------
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
as $$
declare
  v_event public.sparks_events%rowtype;
  v_participant_id uuid;
  v_before jsonb;
  v_after jsonb;
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
  into v_event
  from public.sparks_events
  where id = target_event_id
    and archived_at is null
  for update;

  if v_event.id is null then
    raise exception 'Evento nao encontrado ou arquivado.'
      using errcode = '22023';
  end if;

  if not public.can_manage_organization(v_event.organization_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir participantes deste evento.'
      using errcode = '42501';
  end if;

  if v_event.source_module_code is not null
     and not public.has_module_access(
       v_event.organization_id,
       v_event.source_module_code
     ) then
    raise exception 'Acesso negado ao modulo de origem do evento.'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.organization_memberships membership
    join public.profiles profile
      on profile.id = membership.user_id
    where membership.organization_id = v_event.organization_id
      and membership.user_id = target_user_id
      and membership.status = 'active'
      and membership.valid_from <= timezone('utc', now())
      and (
        membership.valid_until is null
        or membership.valid_until >= timezone('utc', now())
      )
      and profile.active = true
  ) then
    raise exception 'Participante precisa ser usuario ativo da organizacao.'
      using errcode = '22023';
  end if;

  if v_event.source_module_code is not null
     and not exists (
       select 1
       from public.organization_modules om
       join public.modules m
         on m.id = om.module_id
       join public.user_module_roles umr
         on umr.organization_module_id = om.id
       join public.module_roles mr
         on mr.id = umr.module_role_id
       where om.organization_id = v_event.organization_id
         and m.code = v_event.source_module_code
         and m.status = 'active'
         and om.enabled = true
         and om.status in ('trial', 'active')
         and om.valid_from <= timezone('utc', now())
         and (
           om.valid_until is null
           or om.valid_until >= timezone('utc', now())
         )
         and umr.user_id = target_user_id
         and umr.status = 'active'
         and umr.valid_from <= timezone('utc', now())
         and (
           umr.valid_until is null
           or umr.valid_until >= timezone('utc', now())
         )
         and mr.active = true
     ) then
    raise exception 'Participante nao possui acesso ativo ao modulo de origem do evento.'
      using errcode = '22023';
  end if;

  select to_jsonb(p)
  into v_before
  from public.sparks_event_participants p
  where p.event_id = target_event_id
    and p.user_id = target_user_id;

  insert into public.sparks_event_participants (
    event_id,
    user_id,
    participant_role,
    response_status,
    attendance_status,
    required,
    created_by,
    updated_by
  )
  values (
    target_event_id,
    target_user_id,
    lower(trim(target_participant_role)),
    'pending',
    'not_recorded',
    coalesce(target_required, true),
    auth.uid(),
    auth.uid()
  )
  on conflict (event_id, user_id)
  do update set
    participant_role = excluded.participant_role,
    required = excluded.required,
    updated_by = auth.uid()
  returning id into v_participant_id;

  select to_jsonb(p)
  into v_after
  from public.sparks_event_participants p
  where p.id = v_participant_id;

  insert into public.sparks_agenda_audit (
    organization_id,
    event_id,
    actor_user_id,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_event.organization_id,
    v_event.id,
    auth.uid(),
    'event.participant.set',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_participant_id;
end;
$$;

-- Participant owns their invitation response.
create or replace function public.respond_to_sparks_event_participation(
  target_event_id uuid,
  target_response_status text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.sparks_events%rowtype;
  v_participant public.sparks_event_participants%rowtype;
  v_status text := lower(trim(target_response_status));
  v_before jsonb;
  v_after jsonb;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  if v_status not in ('pending', 'accepted', 'declined', 'tentative') then
    raise exception 'Resposta de participacao invalida.'
      using errcode = '22023';
  end if;

  select e.*
  into v_event
  from public.sparks_events e
  where e.id = target_event_id
    and e.archived_at is null;

  if v_event.id is null then
    raise exception 'Evento nao encontrado ou arquivado.'
      using errcode = '22023';
  end if;

  if not public.can_read_organization(v_event.organization_id) then
    raise exception 'Acesso negado ao evento.'
      using errcode = '42501';
  end if;

  if v_event.source_module_code is not null
     and not public.has_module_access(
       v_event.organization_id,
       v_event.source_module_code
     ) then
    raise exception 'Acesso negado ao modulo de origem do evento.'
      using errcode = '42501';
  end if;

  select *
  into v_participant
  from public.sparks_event_participants p
  where p.event_id = target_event_id
    and p.user_id = auth.uid()
  for update;

  if v_participant.id is null then
    raise exception 'Usuario nao e participante deste evento.'
      using errcode = '42501';
  end if;

  v_before := to_jsonb(v_participant);

  update public.sparks_event_participants
  set
    response_status = v_status,
    updated_by = auth.uid()
  where id = v_participant.id;

  select to_jsonb(p)
  into v_after
  from public.sparks_event_participants p
  where p.id = v_participant.id;

  insert into public.sparks_agenda_audit (
    organization_id,
    event_id,
    actor_user_id,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_event.organization_id,
    v_event.id,
    auth.uid(),
    'event.participant.response',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_after;
end;
$$;

-- Organization manager governs attendance after/beside the event.
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
as $$
declare
  v_event public.sparks_events%rowtype;
  v_participant public.sparks_event_participants%rowtype;
  v_status text := lower(trim(target_attendance_status));
  v_before jsonb;
  v_after jsonb;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.'
      using errcode = '22023';
  end if;

  if v_status not in ('not_recorded', 'attended', 'absent') then
    raise exception 'Status de presenca invalido.'
      using errcode = '22023';
  end if;

  select *
  into v_event
  from public.sparks_events
  where id = target_event_id
    and archived_at is null
  for update;

  if v_event.id is null then
    raise exception 'Evento nao encontrado ou arquivado.'
      using errcode = '22023';
  end if;

  if not public.can_manage_organization(v_event.organization_id) then
    raise exception 'Acesso negado: o usuario nao pode registrar presenca neste evento.'
      using errcode = '42501';
  end if;

  if v_event.source_module_code is not null
     and not public.has_module_access(
       v_event.organization_id,
       v_event.source_module_code
     ) then
    raise exception 'Acesso negado ao modulo de origem do evento.'
      using errcode = '42501';
  end if;

  select *
  into v_participant
  from public.sparks_event_participants p
  where p.event_id = target_event_id
    and p.user_id = target_user_id
  for update;

  if v_participant.id is null then
    raise exception 'Usuario nao e participante deste evento.'
      using errcode = '22023';
  end if;

  v_before := to_jsonb(v_participant);

  update public.sparks_event_participants
  set
    attendance_status = v_status,
    updated_by = auth.uid()
  where id = v_participant.id;

  select to_jsonb(p)
  into v_after
  from public.sparks_event_participants p
  where p.id = v_participant.id;

  insert into public.sparks_agenda_audit (
    organization_id,
    event_id,
    actor_user_id,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    v_event.organization_id,
    v_event.id,
    auth.uid(),
    'event.participant.attendance',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_after;
end;
$$;

create or replace function public.remove_sparks_event_participant(
  target_event_id uuid,
  target_user_id uuid,
  change_reason text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.sparks_events%rowtype;
  v_before jsonb;
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
  into v_event
  from public.sparks_events
  where id = target_event_id
    and archived_at is null
  for update;

  if v_event.id is null then
    raise exception 'Evento nao encontrado ou arquivado.'
      using errcode = '22023';
  end if;

  if not public.can_manage_organization(v_event.organization_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir participantes deste evento.'
      using errcode = '42501';
  end if;

  if v_event.source_module_code is not null
     and not public.has_module_access(
       v_event.organization_id,
       v_event.source_module_code
     ) then
    raise exception 'Acesso negado ao modulo de origem do evento.'
      using errcode = '42501';
  end if;

  select to_jsonb(p)
  into v_before
  from public.sparks_event_participants p
  where p.event_id = target_event_id
    and p.user_id = target_user_id
  for update;

  if v_before is null then
    return false;
  end if;

  delete from public.sparks_event_participants
  where event_id = target_event_id
    and user_id = target_user_id;

  insert into public.sparks_agenda_audit (
    organization_id,
    event_id,
    actor_user_id,
    action_code,
    change_reason,
    previous_data
  )
  values (
    v_event.organization_id,
    v_event.id,
    auth.uid(),
    'event.participant.removed',
    trim(change_reason),
    v_before
  );

  return true;
end;
$$;

-- ------------------------------------------------------------
-- 10. Personal Agenda visibility
-- ------------------------------------------------------------
create or replace function public.set_my_sparks_agenda_visibility(
  target_visible boolean
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_before jsonb;
  v_after jsonb;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  select to_jsonb(p)
  into v_before
  from public.sparks_user_agenda_preferences p
  where p.user_id = auth.uid();

  insert into public.sparks_user_agenda_preferences (
    user_id,
    agenda_visible,
    updated_at
  )
  values (
    auth.uid(),
    coalesce(target_visible, true),
    timezone('utc', now())
  )
  on conflict (user_id)
  do update set
    agenda_visible = excluded.agenda_visible,
    updated_at = excluded.updated_at;

  select to_jsonb(p)
  into v_after
  from public.sparks_user_agenda_preferences p
  where p.user_id = auth.uid();

  insert into public.sparks_agenda_audit (
    actor_user_id,
    action_code,
    previous_data,
    new_data
  )
  values (
    auth.uid(),
    'agenda.visibility.set',
    v_before,
    v_after
  );

  return coalesce(target_visible, true);
end;
$$;

create or replace function public.get_my_sparks_agenda_visibility()
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_visible boolean;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  select p.agenda_visible
  into v_visible
  from public.sparks_user_agenda_preferences p
  where p.user_id = auth.uid();

  return coalesce(v_visible, true);
end;
$$;

-- ------------------------------------------------------------
-- 11. Personal item visibility
-- ------------------------------------------------------------
create or replace function public.set_my_sparks_agenda_item_visibility(
  target_organization_id uuid,
  target_agenda_item_key text,
  target_visible boolean
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_before jsonb;
  v_after jsonb;
  v_key text := trim(coalesce(target_agenda_item_key, ''));
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organizacao.'
      using errcode = '22023';
  end if;

  if not public.can_read_organization(target_organization_id) then
    raise exception 'Acesso negado: o usuario nao pode personalizar itens desta organizacao.'
      using errcode = '42501';
  end if;

  if length(v_key) = 0 then
    raise exception 'Informe a chave canonica do item da Agenda.'
      using errcode = '22023';
  end if;

  select to_jsonb(p)
  into v_before
  from public.sparks_user_agenda_item_preferences p
  where p.user_id = auth.uid()
    and p.agenda_item_key = v_key;

  if coalesce(target_visible, true) then
    delete from public.sparks_user_agenda_item_preferences
    where user_id = auth.uid()
      and agenda_item_key = v_key;

    v_after := jsonb_build_object(
      'user_id', auth.uid(),
      'organization_id', target_organization_id,
      'agenda_item_key', v_key,
      'is_visible', true,
      'uses_default', true
    );
  else
    insert into public.sparks_user_agenda_item_preferences (
      user_id,
      organization_id,
      agenda_item_key,
      is_visible,
      updated_at
    )
    values (
      auth.uid(),
      target_organization_id,
      v_key,
      false,
      timezone('utc', now())
    )
    on conflict (user_id, agenda_item_key)
    do update set
      organization_id = excluded.organization_id,
      is_visible = false,
      updated_at = excluded.updated_at;

    select to_jsonb(p)
    into v_after
    from public.sparks_user_agenda_item_preferences p
    where p.user_id = auth.uid()
      and p.agenda_item_key = v_key;
  end if;

  insert into public.sparks_agenda_audit (
    organization_id,
    agenda_item_key,
    actor_user_id,
    action_code,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    v_key,
    auth.uid(),
    'agenda.item.visibility.set',
    v_before,
    v_after
  );

  return coalesce(target_visible, true);
end;
$$;

-- ------------------------------------------------------------
-- 12. RLS: tables are not a direct-write public API.
--     Governed RPCs are the mutation surface.
-- ------------------------------------------------------------
alter table public.sparks_events enable row level security;
alter table public.sparks_event_participants enable row level security;
alter table public.sparks_user_agenda_preferences enable row level security;
alter table public.sparks_user_agenda_item_preferences enable row level security;
alter table public.sparks_agenda_audit enable row level security;

revoke all on table public.sparks_events from public, anon, authenticated;
revoke all on table public.sparks_event_participants from public, anon, authenticated;
revoke all on table public.sparks_user_agenda_preferences from public, anon, authenticated;
revoke all on table public.sparks_user_agenda_item_preferences from public, anon, authenticated;
revoke all on table public.sparks_agenda_audit from public, anon, authenticated;

-- ------------------------------------------------------------
-- 13. Function permissions
-- ------------------------------------------------------------
revoke all on function public.create_sparks_event(
  uuid, text, text, text, timestamptz, timestamptz, boolean, text,
  text, text, text, uuid, text, text, text
) from public, anon, authenticated;

revoke all on function public.update_sparks_event(
  uuid, text, text, text, timestamptz, timestamptz, boolean, text,
  text, text, text, text
) from public, anon, authenticated;

revoke all on function public.transition_sparks_event_lifecycle(
  uuid, text, text
) from public, anon, authenticated;

revoke all on function public.set_sparks_event_participant(
  uuid, uuid, text, boolean, text
) from public, anon, authenticated;

revoke all on function public.respond_to_sparks_event_participation(
  uuid, text, text
) from public, anon, authenticated;

revoke all on function public.record_sparks_event_attendance(
  uuid, uuid, text, text
) from public, anon, authenticated;

revoke all on function public.remove_sparks_event_participant(
  uuid, uuid, text
) from public, anon, authenticated;

revoke all on function public.set_my_sparks_agenda_visibility(
  boolean
) from public, anon, authenticated;

revoke all on function public.get_my_sparks_agenda_visibility()
from public, anon, authenticated;

revoke all on function public.set_my_sparks_agenda_item_visibility(
  uuid, text, boolean
) from public, anon, authenticated;

grant execute on function public.create_sparks_event(
  uuid, text, text, text, timestamptz, timestamptz, boolean, text,
  text, text, text, uuid, text, text, text
) to authenticated, service_role;

grant execute on function public.update_sparks_event(
  uuid, text, text, text, timestamptz, timestamptz, boolean, text,
  text, text, text, text
) to authenticated, service_role;

grant execute on function public.transition_sparks_event_lifecycle(
  uuid, text, text
) to authenticated, service_role;

grant execute on function public.set_sparks_event_participant(
  uuid, uuid, text, boolean, text
) to authenticated, service_role;

grant execute on function public.respond_to_sparks_event_participation(
  uuid, text, text
) to authenticated, service_role;

grant execute on function public.record_sparks_event_attendance(
  uuid, uuid, text, text
) to authenticated, service_role;

grant execute on function public.remove_sparks_event_participant(
  uuid, uuid, text
) to authenticated, service_role;

grant execute on function public.set_my_sparks_agenda_visibility(
  boolean
) to authenticated, service_role;

grant execute on function public.get_my_sparks_agenda_visibility()
to authenticated, service_role;

grant execute on function public.set_my_sparks_agenda_item_visibility(
  uuid, text, boolean
) to authenticated, service_role;

commit;
