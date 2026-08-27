begin;

-- 17-B.5F.3C.6M-PROPOSED-H1
-- Restore canonical target-user module access validation inside
-- set_sparks_event_participant without relying on a nonexistent helper.

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
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode='42501';
  end if;

  if length(trim(coalesce(change_reason,''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.' using errcode='22023';
  end if;

  select *
    into v_event
  from public.sparks_events
  where id=target_event_id
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

  if v_event.source_module_code is not null
     and not public.has_module_access(v_event.organization_id,v_event.source_module_code) then
    raise exception 'Acesso negado ao modulo de origem do evento.' using errcode='42501';
  end if;

  if not exists (
    select 1
    from public.organization_memberships membership
    join public.profiles profile
      on profile.id=membership.user_id
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
     and not exists (
       select 1
       from public.organization_modules om
       join public.modules m
         on m.id=om.module_id
       join public.user_module_roles umr
         on umr.organization_module_id=om.id
       join public.module_roles mr
         on mr.id=umr.module_role_id
       where om.organization_id=v_event.organization_id
         and m.code=v_event.source_module_code
         and m.status='active'
         and om.enabled=true
         and om.status in ('trial','active')
         and om.valid_from <= timezone('utc',now())
         and (om.valid_until is null or om.valid_until >= timezone('utc',now()))
         and umr.user_id=target_user_id
         and umr.status='active'
         and umr.valid_from <= timezone('utc',now())
         and (umr.valid_until is null or umr.valid_until >= timezone('utc',now()))
         and mr.active=true
     ) then
    raise exception 'Participante nao possui acesso ativo ao modulo de origem do evento.' using errcode='22023';
  end if;

  select to_jsonb(p)
    into v_before
  from public.sparks_event_participants p
  where p.event_id=target_event_id
    and p.user_id=target_user_id;

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

  select to_jsonb(p)
    into v_after
  from public.sparks_event_participants p
  where p.id=v_participant_id;

  insert into public.sparks_agenda_audit(
    organization_id,event_id,actor_user_id,action_code,change_reason,previous_data,new_data
  ) values(
    v_event.organization_id,v_event.id,auth.uid(),'event.participant.set',trim(change_reason),v_before,v_after
  );

  return v_participant_id;
end;
$function$;

comment on function public.set_sparks_event_participant(uuid, uuid, text, boolean, text) is
  'Governed event participant management. For module-sourced events the participant must have an active organization membership and active role in the source module.';

commit;