begin;

create or replace function public.set_sparks_person_event_participant(
  target_event_id uuid,
  target_person_id uuid,
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
  v_user_id uuid;
  v_participant_id uuid;
  v_before jsonb;
  v_after jsonb;
  v_role text := lower(trim(coalesce(target_participant_role, 'participant')));
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode='42501';
  end if;

  if length(trim(coalesce(change_reason,''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode='22023';
  end if;
  if v_role not in ('owner','chair','secretary','responsible','participant','observer') then
    raise exception 'Papel de participante invalido.' using errcode='22023';
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
    raise exception 'Acesso negado: o usuario nao pode gerir participantes deste evento.' using errcode='42501';
  end if;

  select * into v_person
  from public.sparks_people
  where id = target_person_id
    and person_status = 'active'
    and archived_at is null;

  if v_person.id is null then
    raise exception 'Pessoa nao encontrada, inativa ou arquivada.' using errcode='22023';
  end if;
  v_user_id := v_person.profile_user_id;

  if v_user_id is not null and not exists (
    select 1 from public.profiles p
    where p.id = v_user_id and p.active = true
  ) then
    raise exception 'A Pessoa possui usuario de plataforma inativo.' using errcode='22023';
  end if;

  select to_jsonb(ep), ep.id
  into v_before, v_participant_id
  from public.sparks_event_participants ep
  where ep.event_id = target_event_id
    and (
      ep.person_id = target_person_id
      or (v_user_id is not null and ep.user_id = v_user_id)
    )
  order by case when ep.person_id = target_person_id then 0 else 1 end, ep.created_at
  limit 1
  for update;

  if v_participant_id is null then
    insert into public.sparks_event_participants(
      event_id, person_id, user_id, participant_role, participant_function,
      response_status, attendance_status, required, created_by, updated_by
    ) values (
      target_event_id,
      target_person_id,
      v_user_id,
      v_role,
      nullif(trim(coalesce(target_participant_function,'')),''),
      'pending',
      'not_recorded',
      coalesce(target_required,true),
      auth.uid(),
      auth.uid()
    ) returning id into v_participant_id;
  else
    update public.sparks_event_participants
    set person_id = target_person_id,
        user_id = v_user_id,
        participant_role = v_role,
        participant_function = nullif(trim(coalesce(target_participant_function,'')),''),
        required = coalesce(target_required,true),
        updated_by = auth.uid(),
        updated_at = timezone('utc',now())
    where id = v_participant_id;
  end if;
  select to_jsonb(ep) into v_after
  from public.sparks_event_participants ep
  where ep.id = v_participant_id;

  insert into public.sparks_agenda_audit(
    organization_id,
    event_id,
    actor_user_id,
    action_code,
    change_reason,
    previous_data,
    new_data
  ) values (
    v_event.organization_id,
    v_event.id,
    auth.uid(),
    'event.participant.person.set',
    trim(change_reason),
    v_before,
    v_after
  );

  return v_participant_id;
end;
$function$;

revoke all on function public.set_sparks_person_event_participant(uuid,uuid,text,text,boolean,text)
  from public, anon;
grant execute on function public.set_sparks_person_event_participant(uuid,uuid,text,text,boolean,text)
  to authenticated, service_role;

comment on function public.set_sparks_person_event_participant(uuid,uuid,text,text,boolean,text) is
  'Governed event participation by canonical SPARKs Person. Supports same-organization, cross-organization and no-login people without fabricating membership in the event organization. Structural meeting roles are contextual and mutable per event; repeating the operation updates the effective role while audit preserves the previous assignment.';

commit;
