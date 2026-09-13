begin;

create or replace function public.get_sparks_event_visibility_scope(
  target_event_id uuid
)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_event public.sparks_events%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.' using errcode='42501';
  end if;

  select * into v_event
  from public.sparks_events
  where id = target_event_id
    and archived_at is null;

  if v_event.id is null then
    raise exception 'Evento nao encontrado ou arquivado.' using errcode='22023';
  end if;
  if not public.can_manage_sparks_event_source(
    v_event.organization_id,
    v_event.source_module_code,
    v_event.source_entity_type,
    v_event.source_entity_id
  ) then
    raise exception 'Acesso negado: o usuario nao pode gerir a visibilidade deste evento.' using errcode='42501';
  end if;

  return v_event.visibility_scope;
end;
$function$;

revoke all on function public.get_sparks_event_visibility_scope(uuid)
  from public, anon;
grant execute on function public.get_sparks_event_visibility_scope(uuid)
  to authenticated, service_role;

comment on function public.get_sparks_event_visibility_scope(uuid) is
  'Governed management read for the visibility audience of one canonical SPARKs event.';

commit;
