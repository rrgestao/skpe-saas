begin;

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
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode='42501';
  end if;

  select *
    into v_event
  from public.sparks_events
  where id = target_event_id;

  if v_event.id is null then
    raise exception 'Evento nao encontrado.' using errcode='P0002';
  end if;

  if not public.can_manage_sparks_event_source(
    v_event.organization_id,
    v_event.source_module_code,
    v_event.source_entity_type,
    v_event.source_entity_id
  ) then
    raise exception 'Acesso negado: o usuario nao pode gerir participantes deste evento.' using errcode='42501';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'participant_id', ep.id,
        'user_id', ep.user_id,
        'user_email', profile.email,
        'user_display_name', coalesce(profile.display_name, profile.full_name, profile.email),
        'participant_role', ep.participant_role,
        'response_status', ep.response_status,
        'attendance_status', ep.attendance_status,
        'required', ep.required
      )
      order by
        case ep.participant_role
          when 'owner' then 1
          when 'chair' then 2
          when 'secretary' then 3
          when 'responsible' then 4
          when 'participant' then 5
          else 6
        end,
        coalesce(profile.display_name, profile.full_name, profile.email),
        ep.user_id
    ),
    '[]'::jsonb
  )
    into v_participants
  from public.sparks_event_participants ep
  join public.profiles profile
    on profile.id = ep.user_id
  where ep.event_id = v_event.id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'user_id', candidate.user_id,
        'user_email', candidate.user_email,
        'user_display_name', candidate.user_display_name,
        'is_current_participant', candidate.is_current_participant
      )
      order by candidate.user_display_name, candidate.user_email, candidate.user_id
    ),
    '[]'::jsonb
  )
    into v_candidates
  from (
    select distinct
      membership.user_id,
      profile.email::text as user_email,
      coalesce(profile.display_name, profile.full_name, profile.email)::text as user_display_name,
      exists (
        select 1
        from public.sparks_event_participants ep
        where ep.event_id = v_event.id
          and ep.user_id = membership.user_id
      ) as is_current_participant
    from public.organization_memberships membership
    join public.profiles profile
      on profile.id = membership.user_id
    where membership.organization_id = v_event.organization_id
      and membership.status = 'active'
      and membership.valid_from <= timezone('utc', now())
      and (membership.valid_until is null or membership.valid_until >= timezone('utc', now()))
      and profile.active = true
      and (
        v_event.source_module_code is null
        or exists (
          select 1
          from public.organization_modules om
          join public.modules module
            on module.id = om.module_id
          join public.user_module_roles umr
            on umr.organization_module_id = om.id
           and umr.user_id = membership.user_id
          join public.module_roles mr
            on mr.id = umr.module_role_id
           and mr.module_id = module.id
          where om.organization_id = v_event.organization_id
            and module.code = v_event.source_module_code
            and module.status = 'active'
            and om.enabled = true
            and om.status in ('trial','active')
            and om.valid_from <= timezone('utc', now())
            and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
            and umr.status = 'active'
            and umr.valid_from <= timezone('utc', now())
            and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
            and mr.active = true
        )
      )
  ) candidate;

  return jsonb_build_object(
    'event_id', v_event.id,
    'event_status', v_event.status,
    'organization_id', v_event.organization_id,
    'source_module_code', v_event.source_module_code,
    'participants', v_participants,
    'eligible_users', v_candidates
  );
end;
$function$;

revoke all on function public.get_sparks_event_participant_management(uuid) from public, anon;
grant execute on function public.get_sparks_event_participant_management(uuid) to authenticated, service_role;

comment on function public.get_sparks_event_participant_management(uuid) is
  'Governed management read model for SPARKs event participants. Returns current participants and active organization users eligible for the event source module without exposing direct table reads.';

commit;