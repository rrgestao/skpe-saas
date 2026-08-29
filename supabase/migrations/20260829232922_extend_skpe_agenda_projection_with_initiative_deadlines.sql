create or replace function public.get_my_skpe_agenda_projection(
  target_organization_id uuid,
  target_date_from date default null,
  target_date_to date default null,
  target_include_cancelled boolean default false,
  target_include_closed boolean default true
)
returns table(
  agenda_item_key text,
  organization_id uuid,
  source_module_code text,
  source_entity_type text,
  source_entity_id uuid,
  source_code text,
  item_kind text,
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  due_at timestamptz,
  all_day boolean,
  timezone_name text,
  source_status text,
  status text,
  priority text,
  user_relation text,
  is_native boolean,
  route text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organizacao.'
      using errcode = '22023';
  end if;

  if target_date_from is not null
     and target_date_to is not null
     and target_date_from > target_date_to then
    raise exception 'Intervalo de datas invalido.'
      using errcode = '22023';
  end if;

  if not public.can_read_organization(target_organization_id) then
    raise exception 'Acesso negado a organizacao informada.'
      using errcode = '42501';
  end if;

  if not public.has_module_access(target_organization_id, 'SK-PE') then
    raise exception 'Acesso negado ao modulo SK-PE.'
      using errcode = '42501';
  end if;

  return query
  with org_context as (
    select
      o.id as organization_id,
      coalesce(nullif(trim(o.timezone_name), ''), 'UTC') as timezone_name,
      timezone(coalesce(nullif(trim(o.timezone_name), ''), 'UTC'), now())::date as local_today
    from public.organizations o
    where o.id = target_organization_id
  ),
  review_rows as (
    select
      m.*,
      oc.timezone_name,
      timezone(oc.timezone_name, m.scheduled_at)::date as scheduled_local_date
    from public.get_my_skpe_meetings(target_organization_id, null, null) m
    join org_context oc on oc.organization_id = m.organization_id
    where m.scheduled_at is not null
      and (target_include_cancelled or m.status <> 'cancelled')
      and (target_include_closed or m.status <> 'closed')
  ),
  review_items as (
    select
      ('SK-PE:strategy_review:' || s.strategy_review_id::text || ':event')::text as agenda_item_key,
      s.organization_id,
      'SK-PE'::text as source_module_code,
      'strategy_review'::text as source_entity_type,
      s.strategy_review_id as source_entity_id,
      s.code as source_code,
      'event'::text as item_kind,
      s.title,
      null::text as description,
      s.scheduled_at as starts_at,
      null::timestamptz as ends_at,
      null::timestamptz as due_at,
      false as all_day,
      s.timezone_name,
      s.status as source_status,
      case
        when s.status = 'cancelled' then 'cancelled'
        when s.status = 'in_progress' then 'in_progress'
        when s.held_at is not null or s.status in ('pending_ratification', 'ratified', 'closed') then 'completed'
        when s.is_overdue then 'overdue'
        else 'scheduled'
      end::text as status,
      null::text as priority,
      s.current_user_role as user_relation,
      false as is_native,
      null::text as route
    from review_rows s
    where (target_date_from is null or s.scheduled_local_date >= target_date_from)
      and (target_date_to is null or s.scheduled_local_date <= target_date_to)
  ),
  initiative_source as (
    select i.*, oc.timezone_name, oc.local_today
    from public.get_my_skpe_initiatives(target_organization_id, null, null) i
    join org_context oc on oc.organization_id = i.organization_id
    where i.due_date is not null
      and (target_include_cancelled or i.status <> 'cancelled')
      and (target_include_closed or i.status not in ('completed', 'archived'))
  ),
  initiative_items as (
    select
      ('SK-PE:sparks_initiative:' || i.initiative_id::text || ':deadline')::text as agenda_item_key,
      i.organization_id,
      'SK-PE'::text as source_module_code,
      'sparks_initiative'::text as source_entity_type,
      i.initiative_id as source_entity_id,
      i.code as source_code,
      'deadline'::text as item_kind,
      i.name as title,
      i.description,
      null::timestamptz as starts_at,
      null::timestamptz as ends_at,
      (i.due_date::timestamp at time zone i.timezone_name) as due_at,
      true as all_day,
      i.timezone_name,
      i.status as source_status,
      case
        when i.status = 'cancelled' then 'cancelled'
        when i.status in ('completed', 'archived') then 'completed'
        when i.due_date < i.local_today then 'overdue'
        else 'planned'
      end::text as status,
      i.priority,
      case
        when i.owner_user_id = auth.uid() then 'owner'
        when i.backup_owner_user_id = auth.uid() then 'backup_owner'
        when i.sponsor_user_id = auth.uid() then 'sponsor'
        else null
      end::text as user_relation,
      false as is_native,
      null::text as route
    from initiative_source i
    where (target_date_from is null or i.due_date >= target_date_from)
      and (target_date_to is null or i.due_date <= target_date_to)
  ),
  visible_initiatives as (
    select i.initiative_id
    from public.get_my_skpe_initiatives(target_organization_id, null, null) i
  ),
  action_source as (
    select
      a.id as action_id,
      a.organization_id,
      a.initiative_id,
      a.code,
      a.name,
      a.description,
      a.action_type,
      a.status,
      a.priority,
      coalesce(a.forecast_due_date, a.planned_due_date, a.baseline_due_date) as due_date,
      oc.timezone_name,
      oc.local_today
    from public.sparks_initiative_actions a
    join visible_initiatives vi on vi.initiative_id = a.initiative_id
    join org_context oc on oc.organization_id = a.organization_id
    where a.organization_id = target_organization_id
      and upper(trim(coalesce(a.source_module_code, ''))) = 'SK-PE'
      and a.archived_at is null
      and coalesce(a.forecast_due_date, a.planned_due_date, a.baseline_due_date) is not null
      and (target_include_cancelled or a.status <> 'cancelled')
      and (target_include_closed or a.status not in ('completed', 'archived'))
  ),
  action_items as (
    select
      (
        'SK-PE:sparks_initiative_action:' || a.action_id::text || ':' ||
        case when a.action_type = 'milestone' then 'milestone' else 'deadline' end
      )::text as agenda_item_key,
      a.organization_id,
      'SK-PE'::text as source_module_code,
      'sparks_initiative_action'::text as source_entity_type,
      a.action_id as source_entity_id,
      a.code as source_code,
      case when a.action_type = 'milestone' then 'milestone' else 'deadline' end::text as item_kind,
      a.name as title,
      a.description,
      null::timestamptz as starts_at,
      null::timestamptz as ends_at,
      (a.due_date::timestamp at time zone a.timezone_name) as due_at,
      true as all_day,
      a.timezone_name,
      a.status as source_status,
      case
        when a.status = 'cancelled' then 'cancelled'
        when a.status in ('completed', 'archived') then 'completed'
        when a.due_date < a.local_today then 'overdue'
        else 'planned'
      end::text as status,
      a.priority,
      null::text as user_relation,
      false as is_native,
      null::text as route
    from action_source a
    where (target_date_from is null or a.due_date >= target_date_from)
      and (target_date_to is null or a.due_date <= target_date_to)
  )
  select * from review_items
  union all
  select * from initiative_items
  union all
  select * from action_items
  order by coalesce(starts_at, due_at), title, agenda_item_key;
end;
$function$;

comment on function public.get_my_skpe_agenda_projection(uuid, date, date, boolean, boolean) is
  'Projeta na agenda SK-PE reunioes, prazos de iniciativas e prazos/marcos de acoes diretamente das autoridades canonicas, sem persistir cronograma duplicado.';
