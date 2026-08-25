-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.6I-S5B
-- SK-PE Agenda Projection Adapter
--
-- Canonical semantics:
--   - read-only adapter;
--   - strategy review remains authoritative in SK-PE;
--   - nothing is copied into public.sparks_events;
--   - only structurally proven chair/secretary relations are personal;
--   - participants JSON remains informational only;
--   - scheduled_at is the temporal anchor;
--   - held_at is evidence of occurrence, never ends_at;
--   - source lifecycle is preserved separately from normalized agenda status.
--
-- Out of scope:
--   - journey schedule milestone/deadline adapters;
--   - initiatives/actions as agenda items;
--   - unified transversal read model (6I-S5C);
--   - recurrence/external calendar;
--   - notification delivery/preferences;
--   - costs/effort governance (6J).
-- ============================================================

begin;

create or replace function public.get_my_skpe_agenda_projection(
  target_organization_id uuid,
  target_date_from date default null,
  target_date_to date default null,
  target_include_cancelled boolean default false,
  target_include_closed boolean default true
)
returns table (
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

  if not public.has_module_access(
    target_organization_id,
    'SK-PE'
  ) then
    raise exception 'Acesso negado ao modulo SK-PE.'
      using errcode = '42501';
  end if;

  return query
  with org_context as (
    select
      o.id as organization_id,
      coalesce(nullif(trim(o.timezone_name), ''), 'UTC') as timezone_name
    from public.organizations o
    where o.id = target_organization_id
  ),
  source_rows as (
    select
      m.*,
      oc.timezone_name,
      timezone(oc.timezone_name, m.scheduled_at)::date as scheduled_local_date
    from public.get_my_skpe_meetings(
      target_organization_id,
      null,
      null
    ) m
    join org_context oc
      on oc.organization_id = m.organization_id
    where m.scheduled_at is not null
      and (
        target_include_cancelled
        or m.status <> 'cancelled'
      )
      and (
        target_include_closed
        or m.status <> 'closed'
      )
  )
  select
    (
      'SK-PE:strategy_review:'
      || s.strategy_review_id::text
      || ':event'
    )::text as agenda_item_key,

    s.organization_id,
    'SK-PE'::text as source_module_code,
    'strategy_review'::text as source_entity_type,
    s.strategy_review_id as source_entity_id,
    s.code as source_code,
    'event'::text as item_kind,
    s.title,
    null::text as description,

    s.scheduled_at as starts_at,

    -- held_at proves that the review occurred; it does not prove its end time.
    null::timestamptz as ends_at,
    null::timestamptz as due_at,

    false as all_day,
    s.timezone_name,
    s.status as source_status,

    case
      when s.status = 'cancelled'
        then 'cancelled'
      when s.status = 'in_progress'
        then 'in_progress'
      when s.held_at is not null
        or s.status in ('pending_ratification', 'ratified', 'closed')
        then 'completed'
      when s.is_overdue
        then 'overdue'
      else 'scheduled'
    end::text as status,

    -- No authoritative priority contract exists for strategy reviews.
    null::text as priority,

    s.current_user_role as user_relation,
    false as is_native,

    -- Route remains null until an explicit canonical frontend route is proven.
    null::text as route

  from source_rows s
  where (
      target_date_from is null
      or s.scheduled_local_date >= target_date_from
    )
    and (
      target_date_to is null
      or s.scheduled_local_date <= target_date_to
    )
  order by
    s.scheduled_at,
    s.strategy_review_id;
end;
$function$;

revoke all
on function public.get_my_skpe_agenda_projection(
  uuid, date, date, boolean, boolean
)
from public, anon, authenticated;

grant execute
on function public.get_my_skpe_agenda_projection(
  uuid, date, date, boolean, boolean
)
to authenticated, service_role;

comment on function public.get_my_skpe_agenda_projection(
  uuid, date, date, boolean, boolean
) is
  'Adapter read-only de Agenda para strategy reviews do SK-PE. '
  'Preserva skpe_strategy_reviews como autoridade, usa get_my_skpe_meetings '
  'para relevancia pessoal estrutural de chair/secretary e nao materializa '
  'eventos projetados em sparks_events.';

commit;