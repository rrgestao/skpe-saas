begin;

-- 17-B.5F.3C.6M-PROPOSED-H2
-- Correct canonical skpe_journey_items field reference in the Journey events projection.

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
    ji.name,
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
  group by e.id, ji.id, ji.code, ji.name, ji.item_type, ji.parent_item_id, o.timezone_name
  order by e.starts_at nulls last, ji.display_order, ji.code, e.id;
end;
$function$;

comment on function public.get_skpe_journey_events_projection(uuid, uuid, date, date, boolean, boolean) is
  'Read-only SK-PE project Journey <-> canonical SPARKs events projection. Journey item label uses canonical skpe_journey_items.name. It never materializes a second agenda or copies event schedule data into journey items.';

commit;