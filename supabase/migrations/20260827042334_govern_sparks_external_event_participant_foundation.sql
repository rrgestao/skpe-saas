begin;

alter table public.sparks_event_participants
  add column if not exists person_id uuid,
  add column if not exists participant_function text;

alter table public.sparks_event_participants
  alter column user_id drop not null;
do $block$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.sparks_event_participants'::regclass
      and conname = 'sparks_event_participants_person_id_fkey'
  ) then
    alter table public.sparks_event_participants
      add constraint sparks_event_participants_person_id_fkey
      foreign key (person_id) references public.sparks_people(id) on delete restrict;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.sparks_event_participants'::regclass
      and conname = 'sparks_event_participants_identity_check'
  ) then
    alter table public.sparks_event_participants
      add constraint sparks_event_participants_identity_check
      check (user_id is not null or person_id is not null);
  end if;
end
$block$;

update public.sparks_event_participants ep
set person_id = person.id
from public.sparks_people person
where ep.person_id is null
  and ep.user_id is not null
  and person.profile_user_id = ep.user_id
  and person.archived_at is null;

create unique index if not exists sparks_event_participants_event_person_uidx
  on public.sparks_event_participants(event_id, person_id)
  where person_id is not null;

comment on column public.sparks_event_participants.person_id is
  'Canonical SPARKs person identity for event participation. External participants may have no platform user.';
comment on column public.sparks_event_participants.participant_function is
  'Contextual function in this event, such as speaker, facilitator, auditor or invited specialist; distinct from participant_role and organizational relationship.';

create or replace function public.set_sparks_external_event_participant(
  target_event_id uuid,
  target_person_id uuid,
  target_full_name text,
  target_preferred_name text default null,
  target_primary_email text default null,
  target_external_organization text default null,
  target_relationship_type text default 'other',
  target_job_title text default null,
  target_participant_role text default 'participant',
  target_participant_function text default null,
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
  v_person public.sparks_people%rowtype;
  v_person_id uuid := target_person_id;
  v_participant_id uuid;
  v_before jsonb;
  v_after jsonb;
  v_relationship_type text := lower(trim(coalesce(target_relationship_type, 'other')));
  v_participant_role text := lower(trim(coalesce(target_participant_role, 'participant')));
  v_email text := nullif(lower(trim(coalesce(target_primary_email, ''))), '');
  v_existing_count integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode='42501';
  end if;
  if length(trim(coalesce(change_reason,''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode='22023';
  end if;

  select * into v_event
  from public.sparks_events
  where id = target_event_id and archived_at is null
  for update;

  if v_event.id is null then
    raise exception 'Evento nao encontrado ou arquivado.' using errcode='22023';
  end if;
  if not public.can_manage_sparks_event_source(v_event.organization_id, v_event.source_module_code, v_event.source_entity_type, v_event.source_entity_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir participantes deste evento.' using errcode='42501';
  end if;
  if v_event.source_module_code is not null and not public.has_module_access(v_event.organization_id, v_event.source_module_code) then
    raise exception 'Acesso negado ao modulo de origem do evento.' using errcode='42501';
  end if;
  if v_participant_role not in ('owner','chair','secretary','responsible','participant','observer') then
    raise exception 'Papel de participante invalido.' using errcode='22023';
  end if;
  if v_relationship_type not in ('service_provider','representative','partner','other') then
    raise exception 'Natureza da relacao externa invalida.' using errcode='22023';
  end if;

  if v_person_id is not null then
    if not exists (
      select 1 from public.sparks_organization_people relationship
      where relationship.organization_id = v_event.organization_id
        and relationship.person_id = v_person_id
        and relationship.status = 'active'
        and (relationship.start_date is null or relationship.start_date <= current_date)
        and (relationship.end_date is null or relationship.end_date >= current_date)
    ) then
      raise exception 'A pessoa selecionada nao possui vinculo ativo com esta organizacao.' using errcode='42501';
    end if;
  else
    if length(trim(coalesce(target_full_name,''))) = 0 then
      raise exception 'Informe o nome da pessoa externa.' using errcode='22023';
    end if;

    if v_email is not null then
      select count(*)::integer, min(person.id)
        into v_existing_count, v_person_id
      from public.sparks_people person
      join public.sparks_organization_people relationship
        on relationship.person_id = person.id
       and relationship.organization_id = v_event.organization_id
       and relationship.status = 'active'
       and (relationship.start_date is null or relationship.start_date <= current_date)
       and (relationship.end_date is null or relationship.end_date >= current_date)
      where person.archived_at is null
        and person.person_status = 'active'
        and lower(coalesce(person.primary_email,'')) = v_email;

      if v_existing_count > 1 then
        raise exception 'Mais de uma pessoa ativa possui este e-mail na organizacao. Selecione a pessoa existente.' using errcode='22023';
      end if;
    end if;

    if v_person_id is null then
      insert into public.sparks_people(
        full_name, preferred_name, primary_email, person_status, data_source,
        metadata, created_by, updated_by
      ) values (
        trim(target_full_name),
        nullif(trim(coalesce(target_preferred_name,'')),''),
        v_email,
        'active',
        'manual',
        '{}'::jsonb,
        auth.uid(),
        auth.uid()
      ) returning id into v_person_id;
    end if;
  end if;

  select * into v_person
  from public.sparks_people
  where id = v_person_id and archived_at is null;

  if v_person.id is null then
    raise exception 'Pessoa externa nao encontrada ou arquivada.' using errcode='22023';
  end if;
  if v_person.profile_user_id is not null then
    raise exception 'A pessoa selecionada possui usuario de plataforma. Use o fluxo de participante interno.' using errcode='22023';
  end if;

  if not exists (
    select 1 from public.sparks_organization_people relationship
    where relationship.organization_id = v_event.organization_id
      and relationship.person_id = v_person_id
      and relationship.status = 'active'
      and (relationship.start_date is null or relationship.start_date <= current_date)
      and (relationship.end_date is null or relationship.end_date >= current_date)
  ) then
    insert into public.sparks_organization_people(
      organization_id, person_id, relationship_type, job_title, start_date,
      status, metadata, created_by, updated_by
    ) values (
      v_event.organization_id,
      v_person_id,
      v_relationship_type,
      nullif(trim(coalesce(target_job_title,'')),''),
      current_date,
      'active',
      jsonb_strip_nulls(jsonb_build_object(
        'external_organization', nullif(trim(coalesce(target_external_organization,'')), ''),
        'source', 'sparks_event_participant'
      )),
      auth.uid(),
      auth.uid()
    );
  end if;

  select to_jsonb(p) into v_before
  from public.sparks_event_participants p
  where p.event_id = target_event_id and p.person_id = v_person_id;

  insert into public.sparks_event_participants(
    event_id, person_id, user_id, participant_role, participant_function,
    response_status, attendance_status, required, created_by, updated_by
  ) values (
    target_event_id,
    v_person_id,
    null,
    v_participant_role,
    nullif(trim(coalesce(target_participant_function,'')),''),
    'pending',
    'not_recorded',
    coalesce(target_required,true),
    auth.uid(),
    auth.uid()
  )
  on conflict (event_id, person_id) where person_id is not null
  do update set
    participant_role = excluded.participant_role,
    participant_function = excluded.participant_function,
    required = excluded.required,
    updated_by = auth.uid(),
    updated_at = timezone('utc', now())
  returning id into v_participant_id;

  select to_jsonb(p) into v_after
  from public.sparks_event_participants p
  where p.id = v_participant_id;

  insert into public.sparks_agenda_audit(
    organization_id,event_id,actor_user_id,action_code,change_reason,previous_data,new_data
  ) values (
    v_event.organization_id,v_event.id,auth.uid(),'event.participant.external.set',
    trim(change_reason),v_before,v_after
  );

  return v_participant_id;
end;
$function$;

create or replace function public.remove_sparks_event_participant_by_id(
  target_event_id uuid,
  target_participant_id uuid,
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

  select to_jsonb(p) into v_before
  from public.sparks_event_participants p
  where p.id=target_participant_id and p.event_id=target_event_id
  for update;

  if v_before is null then return false; end if;

  delete from public.sparks_event_participants where id=target_participant_id and event_id=target_event_id;

  insert into public.sparks_agenda_audit(organization_id,event_id,actor_user_id,action_code,change_reason,previous_data)
  values(v_event.organization_id,v_event.id,auth.uid(),'event.participant.removed',trim(change_reason),v_before);

  return true;
end;
$function$;

create or replace function public.record_sparks_event_attendance_by_id(
  target_event_id uuid,
  target_participant_id uuid,
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

  select * into v_participant
  from public.sparks_event_participants p
  where p.id=target_participant_id and p.event_id=target_event_id
  for update;
  if v_participant.id is null then raise exception 'Participante nao encontrado neste evento.' using errcode='22023'; end if;

  v_before := to_jsonb(v_participant);
  update public.sparks_event_participants
  set attendance_status=v_status, updated_by=auth.uid(), updated_at=timezone('utc',now())
  where id=v_participant.id;

  select to_jsonb(p) into v_after from public.sparks_event_participants p where p.id=v_participant.id;

  insert into public.sparks_agenda_audit(organization_id,event_id,actor_user_id,action_code,change_reason,previous_data,new_data)
  values(v_event.organization_id,v_event.id,auth.uid(),'event.participant.attendance',trim(change_reason),v_before,v_after);

  return v_after;
end;
$function$;

create or replace function public.get_sparks_event_participant_management(
  target_event_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_event public.sparks_events%rowtype;
  v_participants jsonb := '[]'::jsonb;
  v_candidates jsonb := '[]'::jsonb;
  v_external_candidates jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then raise exception 'Operacao exige usuario autenticado.' using errcode='42501'; end if;

  select * into v_event from public.sparks_events where id = target_event_id;
  if v_event.id is null then raise exception 'Evento nao encontrado.' using errcode='P0002'; end if;
  if not public.can_manage_sparks_event_source(v_event.organization_id, v_event.source_module_code, v_event.source_entity_type, v_event.source_entity_id) then
    raise exception 'Acesso negado: o usuario nao pode gerir participantes deste evento.' using errcode='42501';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'participant_id', ep.id,
    'person_id', ep.person_id,
    'user_id', ep.user_id,
    'participant_origin', case when ep.user_id is null then 'external' else 'internal' end,
    'user_email', coalesce(profile.email, person.primary_email),
    'user_display_name', coalesce(profile.display_name, profile.full_name, person.preferred_name, person.full_name, profile.email, person.primary_email),
    'external_organization', relationship.metadata ->> 'external_organization',
    'relationship_type', relationship.relationship_type,
    'job_title', relationship.job_title,
    'participant_role', ep.participant_role,
    'participant_function', ep.participant_function,
    'response_status', ep.response_status,
    'attendance_status', ep.attendance_status,
    'required', ep.required
  ) order by
    case ep.participant_role when 'owner' then 1 when 'chair' then 2 when 'secretary' then 3 when 'responsible' then 4 when 'participant' then 5 else 6 end,
    coalesce(profile.display_name, profile.full_name, person.preferred_name, person.full_name, profile.email, person.primary_email), ep.id), '[]'::jsonb)
  into v_participants
  from public.sparks_event_participants ep
  left join public.profiles profile on profile.id = ep.user_id
  left join public.sparks_people person on person.id = ep.person_id
  left join lateral (
    select r.* from public.sparks_organization_people r
    where r.organization_id = v_event.organization_id
      and r.person_id = ep.person_id
      and r.status = 'active'
    order by r.is_primary_relationship desc, r.start_date desc nulls last, r.created_at desc
    limit 1
  ) relationship on true
  where ep.event_id = v_event.id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'user_id', candidate.user_id,
    'user_email', candidate.user_email,
    'user_display_name', candidate.user_display_name,
    'is_current_participant', candidate.is_current_participant
  ) order by candidate.user_display_name, candidate.user_email, candidate.user_id), '[]'::jsonb)
  into v_candidates
  from (
    select distinct membership.user_id,
      profile.email::text as user_email,
      coalesce(profile.display_name, profile.full_name, profile.email)::text as user_display_name,
      exists(select 1 from public.sparks_event_participants ep where ep.event_id=v_event.id and ep.user_id=membership.user_id) as is_current_participant
    from public.organization_memberships membership
    join public.profiles profile on profile.id=membership.user_id
    where membership.organization_id=v_event.organization_id
      and membership.status='active'
      and membership.valid_from <= timezone('utc',now())
      and (membership.valid_until is null or membership.valid_until >= timezone('utc',now()))
      and profile.active=true
      and (v_event.source_module_code is null or exists(
        select 1
        from public.organization_modules om
        join public.modules module on module.id=om.module_id
        join public.user_module_roles umr on umr.organization_module_id=om.id and umr.user_id=membership.user_id
        join public.module_roles mr on mr.id=umr.module_role_id and mr.module_id=module.id
        where om.organization_id=v_event.organization_id
          and module.code=v_event.source_module_code
          and module.status='active'
          and om.enabled=true
          and om.status in ('trial','active')
          and om.valid_from <= timezone('utc',now())
          and (om.valid_until is null or om.valid_until >= timezone('utc',now()))
          and umr.status='active'
          and umr.valid_from <= timezone('utc',now())
          and (umr.valid_until is null or umr.valid_until >= timezone('utc',now()))
          and mr.active=true
      ))
  ) candidate;

  select coalesce(jsonb_agg(jsonb_build_object(
    'person_id', candidate.person_id,
    'display_name', candidate.display_name,
    'primary_email', candidate.primary_email,
    'external_organization', candidate.external_organization,
    'relationship_type', candidate.relationship_type,
    'job_title', candidate.job_title,
    'is_current_participant', candidate.is_current_participant
  ) order by candidate.display_name, candidate.primary_email, candidate.person_id), '[]'::jsonb)
  into v_external_candidates
  from (
    select distinct on (person.id)
      person.id as person_id,
      coalesce(person.preferred_name, person.full_name)::text as display_name,
      person.primary_email::text as primary_email,
      relationship.metadata ->> 'external_organization' as external_organization,
      relationship.relationship_type::text as relationship_type,
      relationship.job_title::text as job_title,
      exists(select 1 from public.sparks_event_participants ep where ep.event_id=v_event.id and ep.person_id=person.id) as is_current_participant
    from public.sparks_organization_people relationship
    join public.sparks_people person on person.id=relationship.person_id
    where relationship.organization_id=v_event.organization_id
      and relationship.status='active'
      and (relationship.start_date is null or relationship.start_date <= current_date)
      and (relationship.end_date is null or relationship.end_date >= current_date)
      and person.person_status='active'
      and person.archived_at is null
      and person.profile_user_id is null
    order by person.id, relationship.is_primary_relationship desc, relationship.start_date desc nulls last, relationship.created_at desc
  ) candidate;

  return jsonb_build_object(
    'event_id', v_event.id,
    'event_status', v_event.status,
    'organization_id', v_event.organization_id,
    'source_module_code', v_event.source_module_code,
    'participants', v_participants,
    'eligible_users', v_candidates,
    'eligible_external_people', v_external_candidates
  );
end;
$function$;

revoke all on function public.set_sparks_external_event_participant(uuid,uuid,text,text,text,text,text,text,text,text,boolean,text) from public, anon;
grant execute on function public.set_sparks_external_event_participant(uuid,uuid,text,text,text,text,text,text,text,text,boolean,text) to authenticated, service_role;
revoke all on function public.remove_sparks_event_participant_by_id(uuid,uuid,text) from public, anon;
grant execute on function public.remove_sparks_event_participant_by_id(uuid,uuid,text) to authenticated, service_role;
revoke all on function public.record_sparks_event_attendance_by_id(uuid,uuid,text,text) from public, anon;
grant execute on function public.record_sparks_event_attendance_by_id(uuid,uuid,text,text) to authenticated, service_role;
revoke all on function public.get_sparks_event_participant_management(uuid) from public, anon;
grant execute on function public.get_sparks_event_participant_management(uuid) to authenticated, service_role;

comment on function public.set_sparks_external_event_participant(uuid,uuid,text,text,text,text,text,text,text,text,boolean,text) is
  'Governed creation/reuse and event assignment of an external SPARKs person without requiring platform login.';
comment on function public.remove_sparks_event_participant_by_id(uuid,uuid,text) is
  'Governed participant removal by participant identity, valid for internal and external people.';
comment on function public.record_sparks_event_attendance_by_id(uuid,uuid,text,text) is
  'Governed attendance recording by participant identity, valid for internal and external people.';
comment on function public.get_sparks_event_participant_management(uuid) is
  'Governed participant management projection with unified internal/external human identity and eligible external people.';

commit;