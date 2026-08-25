-- ============================================================
-- Plataforma SPARKs / SK-PE-CONT-01
-- 17-B.5F.3C.6I-S5C
-- Unified Personal Agenda Read Model
--
-- Canonical semantics:
--   - Agenda is a transversal read model, never a duplicate SoT.
--   - Native items remain authoritative in public.sparks_events.
--   - Projected SK-PE items remain authoritative in SK-PE.
--   - Native personal relevance is structural participation only.
--   - No creator/manager inference is used as personal participation.
--   - Personal item visibility is sparse; absence means visible.
--   - Agenda-level visibility is a UI preference and does not disable this RPC.
--   - NATIVE is a reserved read namespace, never a module code.
--   - Explicit adapters only; no dynamic arbitrary function registry.
--   - A bounded date filter excludes unscheduled native events.
--   - Native date filtering uses interval overlap, not start-date-only matching.
--   - Linked source provenance on native events is preserved when present.
--
-- Out of scope:
--   - recurrence / external calendar sync
--   - notification delivery/preferences
--   - journey milestone/deadline adapters not yet semantically proven
--   - initiative/action auto-projection
--   - costs / effort governance (6J)
-- ============================================================

begin;

create or replace function public.get_my_sparks_agenda(
  target_organization_id uuid default null,
  target_module_code text default null,
  target_date_from date default null,
  target_date_to date default null,
  target_item_kind text default null,
  target_status text default null,
  target_include_hidden boolean default false
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
  route text,
  is_visible boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_module_code text := nullif(upper(trim(coalesce(target_module_code, ''))), '');
  v_item_kind text := nullif(lower(trim(coalesce(target_item_kind, ''))), '');
  v_status text := nullif(lower(trim(coalesce(target_status, ''))), '');
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if target_date_from is not null
     and target_date_to is not null
     and target_date_from > target_date_to then
    raise exception 'Intervalo de datas invalido.'
      using errcode = '22023';
  end if;

  if target_organization_id is not null
     and not public.can_read_organization(target_organization_id) then
    raise exception 'Acesso negado a organizacao.'
      using errcode = '42501';
  end if;

  -- NATIVE is a reserved projection namespace, not a module code.
  if v_module_code is not null
     and v_module_code <> 'NATIVE'
     and not exists (
       select 1
       from public.modules m
       where m.code = v_module_code
         and m.status = 'active'
     ) then
    raise exception 'Modulo inexistente ou inativo.'
      using errcode = '22023';
  end if;

  if target_organization_id is not null
     and v_module_code is not null
     and v_module_code <> 'NATIVE'
     and not public.has_module_access(
       target_organization_id,
       v_module_code
     ) then
    raise exception 'Acesso negado ao modulo solicitado.'
      using errcode = '42501';
  end if;

  return query
  with authorized_orgs as (
    select
      o.id,
      coalesce(nullif(trim(o.timezone_name), ''), 'UTC') as timezone_name
    from public.organizations o
    where (
      target_organization_id is null
      or o.id = target_organization_id
    )
      and public.can_read_organization(o.id)
  ),
  native_items as (
    select
      (
        'NATIVE:event:' ||
        e.id::text ||
        ':event'
      )::text as agenda_item_key,
      e.organization_id,
      e.source_module_code,
      coalesce(
        nullif(trim(e.source_entity_type), ''),
        'event'
      )::text as source_entity_type,
      coalesce(e.source_entity_id, e.id) as source_entity_id,
      null::text as source_code,
      'event'::text as item_kind,
      e.title,
      e.description,
      e.starts_at,
      e.ends_at,
      null::timestamptz as due_at,
      e.all_day,
      coalesce(
        nullif(trim(e.timezone_name), ''),
        ao.timezone_name,
        'UTC'
      )::text as timezone_name,
      e.status::text as source_status,
      e.status::text as status,
      e.priority::text as priority,
      ep.participant_role::text as user_relation,
      true as is_native,
      null::text as route
    from public.sparks_events e
    join authorized_orgs ao
      on ao.id = e.organization_id
    join public.sparks_event_participants ep
      on ep.event_id = e.id
     and ep.user_id = auth.uid()
    where e.status <> 'archived'
      and (
        e.source_module_code is null
        or public.has_module_access(
          e.organization_id,
          e.source_module_code
        )
      )
      and (
        v_module_code is null
        or (
          v_module_code = 'NATIVE'
          and e.source_module_code is null
        )
        or (
          v_module_code <> 'NATIVE'
          and e.source_module_code = v_module_code
        )
      )
      and (
        target_date_from is null
        or (
          e.starts_at is not null
          and timezone(
            coalesce(
              nullif(trim(e.timezone_name), ''),
              ao.timezone_name,
              'UTC'
            ),
            coalesce(e.ends_at, e.starts_at)
          )::date >= target_date_from
        )
      )
      and (
        target_date_to is null
        or (
          e.starts_at is not null
          and timezone(
            coalesce(
              nullif(trim(e.timezone_name), ''),
              ao.timezone_name,
              'UTC'
            ),
            e.starts_at
          )::date <= target_date_to
        )
      )
  ),
  skpe_orgs as (
    select ao.*
    from authorized_orgs ao
    where (
      v_module_code is null
      or v_module_code = 'SK-PE'
    )
      and public.has_module_access(ao.id, 'SK-PE')
  ),
  skpe_items as (
    select
      p.agenda_item_key,
      p.organization_id,
      p.source_module_code,
      p.source_entity_type,
      p.source_entity_id,
      p.source_code,
      p.item_kind,
      p.title,
      p.description,
      p.starts_at,
      p.ends_at,
      p.due_at,
      p.all_day,
      p.timezone_name,
      p.source_status,
      p.status,
      p.priority,
      p.user_relation,
      p.is_native,
      p.route
    from skpe_orgs so
    cross join lateral public.get_my_skpe_agenda_projection(
      so.id,
      target_date_from,
      target_date_to,
      true,
      true
    ) p
  ),
  composed as (
    select * from native_items
    union all
    select * from skpe_items
  ),
  personalized as (
    select
      c.*,
      coalesce(pref.is_visible, true) as is_visible
    from composed c
    left join public.sparks_user_agenda_item_preferences pref
      on pref.user_id = auth.uid()
     and pref.organization_id = c.organization_id
     and pref.agenda_item_key = c.agenda_item_key
  )
  select
    p.agenda_item_key,
    p.organization_id,
    p.source_module_code,
    p.source_entity_type,
    p.source_entity_id,
    p.source_code,
    p.item_kind,
    p.title,
    p.description,
    p.starts_at,
    p.ends_at,
    p.due_at,
    p.all_day,
    p.timezone_name,
    p.source_status,
    p.status,
    p.priority,
    p.user_relation,
    p.is_native,
    p.route,
    p.is_visible
  from personalized p
  where (
    v_item_kind is null
    or p.item_kind = v_item_kind
  )
    and (
      v_status is null
      or p.status = v_status
    )
    and (
      coalesce(target_include_hidden, false)
      or p.is_visible
    )
  order by
    coalesce(p.starts_at, p.due_at) asc nulls last,
    p.title asc,
    p.agenda_item_key asc;
end;
$$;

comment on function public.get_my_sparks_agenda(
  uuid,
  text,
  date,
  date,
  text,
  text,
  boolean
) is
  'Read model pessoal e transversal da Agenda SPARKs. Compoe eventos nativos com participacao estrutural do usuario e adapters projetados explicitamente, preservando cada source of truth e aplicando preferencias pessoais de visibilidade.';

revoke all on function public.get_my_sparks_agenda(
  uuid,
  text,
  date,
  date,
  text,
  text,
  boolean
) from public, anon, authenticated;

grant execute on function public.get_my_sparks_agenda(
  uuid,
  text,
  date,
  date,
  text,
  text,
  boolean
) to authenticated, service_role;

commit;