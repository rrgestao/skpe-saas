begin;

-- ============================================================
-- 17-B.5F.3C.6J-B
-- Governed transversal person capacity & allocation foundation.
--
-- Semantic boundaries:
-- - sparks_organization_people remains the canonical human resource identity.
-- - workload_hours / availability_percentage remain relationship attributes.
-- - responsibility allocation_percentage remains responsibility semantics.
-- - estimated_effort / actual_effort remain execution-effort semantics.
-- - portfolio capacity assessment remains an assessment, not quantitative capacity.
-- - capacity is explicit, temporal and unit-bound.
-- - allocation is explicit, temporal and separate from responsibility.
-- - over-allocation is allowed and exposed by projection; never silently normalized.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Capacity periods
-- ------------------------------------------------------------
create table public.sparks_person_capacity_periods (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  organization_person_id uuid not null
    references public.sparks_organization_people(id) on delete cascade,

  period_start date not null,
  period_end date not null,

  capacity_amount numeric(18,2) not null,
  capacity_unit text not null,

  status text not null default 'planned',
  notes text,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_person_capacity_periods_dates_check
    check (period_end >= period_start),

  constraint sparks_person_capacity_periods_amount_check
    check (capacity_amount >= 0),

  constraint sparks_person_capacity_periods_unit_check
    check (capacity_unit in ('hours','days','weeks','months','points','custom')),

  constraint sparks_person_capacity_periods_status_check
    check (status in ('planned','active','closed','cancelled')),

  constraint sparks_person_capacity_periods_scope_unique
    unique (id, organization_id)
);

comment on table public.sparks_person_capacity_periods is
  'Capacidade quantitativa e temporal de uma pessoa vinculada a uma organizacao SPARKs. Nao deriva automaticamente de workload_hours, availability_percentage, responsabilidades ou esforco de iniciativas/acoes.';

comment on column public.sparks_person_capacity_periods.organization_person_id is
  'Identidade canonica do recurso humano: public.sparks_organization_people.id.';

comment on column public.sparks_person_capacity_periods.capacity_amount is
  'Quantidade de capacidade disponivel no periodo, expressa exclusivamente em capacity_unit.';

comment on column public.sparks_person_capacity_periods.capacity_unit is
  'Unidade explicita da capacidade. Nao ha conversao implicita entre unidades.';

create index ix_sparks_person_capacity_periods_person_period
  on public.sparks_person_capacity_periods(
    organization_person_id,
    period_start,
    period_end
  );

create index ix_sparks_person_capacity_periods_org_status
  on public.sparks_person_capacity_periods(organization_id, status);

create trigger sparks_person_capacity_periods_set_updated_at
before update on public.sparks_person_capacity_periods
for each row
execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 2. Capacity allocations
-- ------------------------------------------------------------
create table public.sparks_person_capacity_allocations (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id) on delete cascade,

  capacity_period_id uuid not null,
  module_code text not null,
  object_type text not null,
  object_id uuid not null,

  allocation_start date not null,
  allocation_end date not null,
  allocated_amount numeric(18,2) not null,

  status text not null default 'planned',
  notes text,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_person_capacity_allocations_capacity_scope_fkey
    foreign key (capacity_period_id, organization_id)
    references public.sparks_person_capacity_periods(id, organization_id)
    on delete cascade,

  constraint sparks_person_capacity_allocations_module_not_blank
    check (length(trim(module_code)) > 0),

  constraint sparks_person_capacity_allocations_object_type_not_blank
    check (length(trim(object_type)) > 0),

  constraint sparks_person_capacity_allocations_dates_check
    check (allocation_end >= allocation_start),

  constraint sparks_person_capacity_allocations_amount_check
    check (allocated_amount >= 0),

  constraint sparks_person_capacity_allocations_status_check
    check (status in ('planned','active','ended','cancelled'))
);

comment on table public.sparks_person_capacity_allocations is
  'Alocacao quantitativa de capacidade humana para um objeto transversal SPARKs. E separada de sparks_responsibility_assignments e pode produzir sobre-alocacao explicita.';

comment on column public.sparks_person_capacity_allocations.allocated_amount is
  'Quantidade alocada na mesma unidade do periodo de capacidade referenciado.';

create index ix_sparks_person_capacity_allocations_capacity
  on public.sparks_person_capacity_allocations(capacity_period_id, status);

create index ix_sparks_person_capacity_allocations_object
  on public.sparks_person_capacity_allocations(
    organization_id,
    module_code,
    object_type,
    object_id
  );

create trigger sparks_person_capacity_allocations_set_updated_at
before update on public.sparks_person_capacity_allocations
for each row
execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 3. Audit
-- ------------------------------------------------------------
create table public.sparks_capacity_audit (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,

  entity_type text not null,
  entity_id uuid not null,
  actor_user_id uuid references public.profiles(id) on delete set null,
  action_code text not null,
  change_reason text not null,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz not null default timezone('utc', now()),

  constraint sparks_capacity_audit_entity_type_check
    check (entity_type in ('capacity_period','capacity_allocation')),

  constraint sparks_capacity_audit_action_not_blank
    check (length(trim(action_code)) > 0),

  constraint sparks_capacity_audit_reason_check
    check (length(trim(change_reason)) >= 10)
);

comment on table public.sparks_capacity_audit is
  'Trilha de auditoria governada da capacidade e das alocacoes quantitativas de pessoas na plataforma SPARKs.';

create index ix_sparks_capacity_audit_entity
  on public.sparks_capacity_audit(entity_type, entity_id, occurred_at desc);

create index ix_sparks_capacity_audit_org
  on public.sparks_capacity_audit(organization_id, occurred_at desc);

-- ------------------------------------------------------------
-- 4. RLS
-- ------------------------------------------------------------
alter table public.sparks_person_capacity_periods enable row level security;
alter table public.sparks_person_capacity_allocations enable row level security;
alter table public.sparks_capacity_audit enable row level security;

create policy sparks_person_capacity_periods_select
on public.sparks_person_capacity_periods
for select
to authenticated
using (public.can_view_sparks_people(organization_id));

create policy sparks_person_capacity_allocations_select
on public.sparks_person_capacity_allocations
for select
to authenticated
using (public.can_view_sparks_people(organization_id));

create policy sparks_capacity_audit_select
on public.sparks_capacity_audit
for select
to authenticated
using (public.can_view_sparks_people(organization_id));

-- Mutations are RPC-governed. No direct authenticated writes.
revoke all on table public.sparks_person_capacity_periods from public, anon, authenticated;
revoke all on table public.sparks_person_capacity_allocations from public, anon, authenticated;
revoke all on table public.sparks_capacity_audit from public, anon, authenticated;

grant select on table public.sparks_person_capacity_periods to authenticated;
grant select on table public.sparks_person_capacity_allocations to authenticated;
grant select on table public.sparks_capacity_audit to authenticated;

-- ------------------------------------------------------------
-- 5. Governed capacity period mutation
-- ------------------------------------------------------------
create or replace function public.set_sparks_person_capacity_period(
  target_organization_id uuid,
  target_capacity_period_id uuid,
  target_organization_person_id uuid,
  target_period_start date,
  target_period_end date,
  target_capacity_amount numeric,
  target_capacity_unit text,
  target_status text,
  target_notes text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_unit text := nullif(lower(trim(coalesce(target_capacity_unit, ''))), '');
  v_status text := nullif(lower(trim(coalesce(target_status, ''))), '');
  v_notes text := nullif(trim(coalesce(target_notes, '')), '');
  v_reason text := nullif(trim(coalesce(change_reason, '')), '');

  v_id uuid;
  v_existing public.sparks_person_capacity_periods%rowtype;
  v_relationship public.sparks_organization_people%rowtype;
  v_before jsonb;
  v_after jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required.'
      using errcode = '42501';
  end if;

  if target_organization_id is null
     or target_organization_person_id is null then
    raise exception 'Organization and organization person are required.'
      using errcode = '22023';
  end if;

  if not public.can_manage_sparks_people(target_organization_id) then
    raise exception 'Access denied to manage person capacity.'
      using errcode = '42501';
  end if;

  if length(coalesce(v_reason, '')) < 10 then
    raise exception 'Change reason must contain at least 10 characters.'
      using errcode = '22023';
  end if;

  if target_period_start is null or target_period_end is null
     or target_period_end < target_period_start then
    raise exception 'Invalid capacity period.'
      using errcode = '22023';
  end if;

  if target_capacity_amount is null or target_capacity_amount < 0 then
    raise exception 'Capacity amount must be zero or positive.'
      using errcode = '22023';
  end if;

  if v_unit not in ('hours','days','weeks','months','points','custom') then
    raise exception 'Invalid capacity unit.'
      using errcode = '22023';
  end if;

  if v_status not in ('planned','active','closed','cancelled') then
    raise exception 'Invalid capacity status.'
      using errcode = '22023';
  end if;

  select relationship.*
    into v_relationship
  from public.sparks_organization_people relationship
  join public.sparks_people person
    on person.id = relationship.person_id
  where relationship.id = target_organization_person_id
    and relationship.organization_id = target_organization_id
    and relationship.status = 'active'
    and person.person_status = 'active'
  for update of relationship;

  if v_relationship.id is null then
    raise exception 'Person does not have an active relationship with the organization.'
      using errcode = '22023';
  end if;

  if v_relationship.start_date is not null
     and target_period_start < v_relationship.start_date then
    raise exception 'Capacity period cannot start before the organization relationship.'
      using errcode = '22023';
  end if;

  if v_relationship.end_date is not null
     and target_period_end > v_relationship.end_date then
    raise exception 'Capacity period cannot end after the organization relationship.'
      using errcode = '22023';
  end if;

  if target_capacity_period_id is not null then
    select capacity.*
      into v_existing
    from public.sparks_person_capacity_periods capacity
    where capacity.id = target_capacity_period_id
      and capacity.organization_id = target_organization_id
    for update;

    if v_existing.id is null then
      raise exception 'Capacity period not found.'
        using errcode = 'P0002';
    end if;

    if v_existing.organization_person_id <> target_organization_person_id then
      raise exception 'Capacity period person identity is immutable.'
        using errcode = '55000';
    end if;

    v_before := to_jsonb(v_existing);
  end if;

  if v_status <> 'cancelled'
     and exists (
       select 1
       from public.sparks_person_capacity_periods capacity
       where capacity.organization_id = target_organization_id
         and capacity.organization_person_id = target_organization_person_id
         and capacity.capacity_unit = v_unit
         and capacity.status <> 'cancelled'
         and capacity.id is distinct from target_capacity_period_id
         and daterange(capacity.period_start, capacity.period_end, '[]')
             && daterange(target_period_start, target_period_end, '[]')
     ) then
    raise exception 'An overlapping capacity period already exists for this person and unit.'
      using errcode = '23505';
  end if;

  if target_capacity_period_id is null then
    insert into public.sparks_person_capacity_periods (
      organization_id,
      organization_person_id,
      period_start,
      period_end,
      capacity_amount,
      capacity_unit,
      status,
      notes,
      created_by,
      updated_by
    )
    values (
      target_organization_id,
      target_organization_person_id,
      target_period_start,
      target_period_end,
      target_capacity_amount,
      v_unit,
      v_status,
      v_notes,
      v_user_id,
      v_user_id
    )
    returning id into v_id;
  else
    update public.sparks_person_capacity_periods
    set
      period_start = target_period_start,
      period_end = target_period_end,
      capacity_amount = target_capacity_amount,
      capacity_unit = v_unit,
      status = v_status,
      notes = v_notes,
      updated_by = v_user_id
    where id = target_capacity_period_id
      and organization_id = target_organization_id
    returning id into v_id;
  end if;

  select to_jsonb(capacity)
    into v_after
  from public.sparks_person_capacity_periods capacity
  where capacity.id = v_id;

  insert into public.sparks_capacity_audit (
    organization_id,
    entity_type,
    entity_id,
    actor_user_id,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    'capacity_period',
    v_id,
    v_user_id,
    case when target_capacity_period_id is null
      then 'capacity_period.created'
      else 'capacity_period.updated'
    end,
    v_reason,
    v_before,
    v_after
  );

  return v_id;
end;
$function$;

-- ------------------------------------------------------------
-- 6. Governed allocation mutation
-- ------------------------------------------------------------
create or replace function public.set_sparks_person_capacity_allocation(
  target_organization_id uuid,
  target_allocation_id uuid,
  target_capacity_period_id uuid,
  target_module_code text,
  target_object_type text,
  target_object_id uuid,
  target_allocation_start date,
  target_allocation_end date,
  target_allocated_amount numeric,
  target_status text,
  target_notes text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_module_code text := nullif(upper(trim(coalesce(target_module_code, ''))), '');
  v_object_type text := nullif(lower(trim(coalesce(target_object_type, ''))), '');
  v_status text := nullif(lower(trim(coalesce(target_status, ''))), '');
  v_notes text := nullif(trim(coalesce(target_notes, '')), '');
  v_reason text := nullif(trim(coalesce(change_reason, '')), '');

  v_capacity public.sparks_person_capacity_periods%rowtype;
  v_existing public.sparks_person_capacity_allocations%rowtype;
  v_id uuid;
  v_before jsonb;
  v_after jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required.'
      using errcode = '42501';
  end if;

  if target_organization_id is null
     or target_capacity_period_id is null
     or target_object_id is null then
    raise exception 'Organization, capacity period and target object are required.'
      using errcode = '22023';
  end if;

  if not public.can_manage_sparks_people(target_organization_id) then
    raise exception 'Access denied to manage person capacity allocation.'
      using errcode = '42501';
  end if;

  if length(coalesce(v_reason, '')) < 10 then
    raise exception 'Change reason must contain at least 10 characters.'
      using errcode = '22023';
  end if;

  if v_module_code is null or v_object_type is null then
    raise exception 'Module code and object type are required.'
      using errcode = '22023';
  end if;

  if target_allocation_start is null or target_allocation_end is null
     or target_allocation_end < target_allocation_start then
    raise exception 'Invalid allocation period.'
      using errcode = '22023';
  end if;

  if target_allocated_amount is null or target_allocated_amount < 0 then
    raise exception 'Allocated amount must be zero or positive.'
      using errcode = '22023';
  end if;

  if v_status not in ('planned','active','ended','cancelled') then
    raise exception 'Invalid allocation status.'
      using errcode = '22023';
  end if;

  select capacity.*
    into v_capacity
  from public.sparks_person_capacity_periods capacity
  where capacity.id = target_capacity_period_id
    and capacity.organization_id = target_organization_id
  for update;

  if v_capacity.id is null then
    raise exception 'Capacity period not found.'
      using errcode = 'P0002';
  end if;

  if v_capacity.status = 'cancelled' then
    raise exception 'Cannot allocate against a cancelled capacity period.'
      using errcode = '55000';
  end if;

  if target_allocation_start < v_capacity.period_start
     or target_allocation_end > v_capacity.period_end then
    raise exception 'Allocation period must be contained in the capacity period.'
      using errcode = '22023';
  end if;

  if target_allocation_id is not null then
    select allocation.*
      into v_existing
    from public.sparks_person_capacity_allocations allocation
    where allocation.id = target_allocation_id
      and allocation.organization_id = target_organization_id
    for update;

    if v_existing.id is null then
      raise exception 'Capacity allocation not found.'
        using errcode = 'P0002';
    end if;

    if v_existing.capacity_period_id <> target_capacity_period_id then
      raise exception 'Capacity period binding is immutable for an allocation.'
        using errcode = '55000';
    end if;

    v_before := to_jsonb(v_existing);
  end if;

  if v_status in ('planned','active')
     and exists (
       select 1
       from public.sparks_person_capacity_allocations allocation
       where allocation.organization_id = target_organization_id
         and allocation.capacity_period_id = target_capacity_period_id
         and allocation.module_code = v_module_code
         and allocation.object_type = v_object_type
         and allocation.object_id = target_object_id
         and allocation.status in ('planned','active')
         and allocation.id is distinct from target_allocation_id
         and daterange(allocation.allocation_start, allocation.allocation_end, '[]')
             && daterange(target_allocation_start, target_allocation_end, '[]')
     ) then
    raise exception 'An overlapping allocation for the same target object already exists.'
      using errcode = '23505';
  end if;

  if target_allocation_id is null then
    insert into public.sparks_person_capacity_allocations (
      organization_id,
      capacity_period_id,
      module_code,
      object_type,
      object_id,
      allocation_start,
      allocation_end,
      allocated_amount,
      status,
      notes,
      created_by,
      updated_by
    )
    values (
      target_organization_id,
      target_capacity_period_id,
      v_module_code,
      v_object_type,
      target_object_id,
      target_allocation_start,
      target_allocation_end,
      target_allocated_amount,
      v_status,
      v_notes,
      v_user_id,
      v_user_id
    )
    returning id into v_id;
  else
    update public.sparks_person_capacity_allocations
    set
      module_code = v_module_code,
      object_type = v_object_type,
      object_id = target_object_id,
      allocation_start = target_allocation_start,
      allocation_end = target_allocation_end,
      allocated_amount = target_allocated_amount,
      status = v_status,
      notes = v_notes,
      updated_by = v_user_id
    where id = target_allocation_id
      and organization_id = target_organization_id
    returning id into v_id;
  end if;

  select to_jsonb(allocation)
    into v_after
  from public.sparks_person_capacity_allocations allocation
  where allocation.id = v_id;

  insert into public.sparks_capacity_audit (
    organization_id,
    entity_type,
    entity_id,
    actor_user_id,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    'capacity_allocation',
    v_id,
    v_user_id,
    case when target_allocation_id is null
      then 'capacity_allocation.created'
      else 'capacity_allocation.updated'
    end,
    v_reason,
    v_before,
    v_after
  );

  return v_id;
end;
$function$;

-- ------------------------------------------------------------
-- 7. Read-only capacity projection
-- ------------------------------------------------------------
create or replace function public.get_sparks_person_capacity_projection(
  target_organization_id uuid,
  target_organization_person_id uuid default null,
  target_period_start date default null,
  target_period_end date default null
)
returns table (
  capacity_period_id uuid,
  organization_id uuid,
  organization_person_id uuid,
  person_id uuid,
  person_name text,
  organizational_area text,
  period_start date,
  period_end date,
  capacity_unit text,
  capacity_status text,
  capacity_amount numeric,
  allocated_current_amount numeric,
  allocated_ended_amount numeric,
  available_amount numeric,
  utilization_percentage numeric,
  overallocation_amount numeric,
  is_overallocated boolean,
  current_allocation_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Organization is required.'
      using errcode = '22023';
  end if;

  if not public.can_view_sparks_people(target_organization_id) then
    raise exception 'Access denied to view person capacity.'
      using errcode = '42501';
  end if;

  if target_period_start is not null
     and target_period_end is not null
     and target_period_end < target_period_start then
    raise exception 'Invalid projection period.'
      using errcode = '22023';
  end if;

  return query
  select
    capacity.id,
    capacity.organization_id,
    capacity.organization_person_id,
    relationship.person_id,
    coalesce(person.preferred_name, person.full_name),
    relationship.organizational_area,
    capacity.period_start,
    capacity.period_end,
    capacity.capacity_unit,
    capacity.status,
    capacity.capacity_amount,
    coalesce(allocation.allocated_current_amount, 0)::numeric,
    coalesce(allocation.allocated_ended_amount, 0)::numeric,
    (capacity.capacity_amount - coalesce(allocation.allocated_current_amount, 0))::numeric,
    case
      when capacity.capacity_amount = 0
        then case
          when coalesce(allocation.allocated_current_amount, 0) = 0 then 0
          else null
        end
      else round(
        (coalesce(allocation.allocated_current_amount, 0) / capacity.capacity_amount) * 100,
        2
      )
    end::numeric,
    greatest(
      coalesce(allocation.allocated_current_amount, 0) - capacity.capacity_amount,
      0
    )::numeric,
    coalesce(allocation.allocated_current_amount, 0) > capacity.capacity_amount,
    coalesce(allocation.current_allocation_count, 0)::bigint
  from public.sparks_person_capacity_periods capacity
  join public.sparks_organization_people relationship
    on relationship.id = capacity.organization_person_id
   and relationship.organization_id = capacity.organization_id
  join public.sparks_people person
    on person.id = relationship.person_id
  left join lateral (
    select
      sum(a.allocated_amount) filter (
        where a.status in ('planned','active')
      ) as allocated_current_amount,
      sum(a.allocated_amount) filter (
        where a.status = 'ended'
      ) as allocated_ended_amount,
      count(*) filter (
        where a.status in ('planned','active')
      ) as current_allocation_count
    from public.sparks_person_capacity_allocations a
    where a.capacity_period_id = capacity.id
      and a.organization_id = capacity.organization_id
  ) allocation on true
  where capacity.organization_id = target_organization_id
    and (
      target_organization_person_id is null
      or capacity.organization_person_id = target_organization_person_id
    )
    and (
      target_period_start is null
      or capacity.period_end >= target_period_start
    )
    and (
      target_period_end is null
      or capacity.period_start <= target_period_end
    )
  order by
    coalesce(person.preferred_name, person.full_name),
    capacity.period_start,
    capacity.capacity_unit;
end;
$function$;

comment on function public.set_sparks_person_capacity_period(
  uuid, uuid, uuid, date, date, numeric, text, text, text, text
) is
  'Governed transversal mutation of an explicit person capacity period. Rejects overlapping non-cancelled capacity baselines for the same person and unit.';

comment on function public.set_sparks_person_capacity_allocation(
  uuid, uuid, uuid, text, text, uuid, date, date, numeric, text, text, text
) is
  'Governed transversal quantitative allocation of person capacity to a SPARKs object. Responsibility assignment remains a separate source of truth.';

comment on function public.get_sparks_person_capacity_projection(
  uuid, uuid, date, date
) is
  'Read-only transversal projection of person capacity, allocation, utilization and explicit over-allocation. No unit conversion and no automatic effort/responsibility roll-up.';

-- ------------------------------------------------------------
-- 8. RPC privileges
-- ------------------------------------------------------------
revoke all on function public.set_sparks_person_capacity_period(
  uuid, uuid, uuid, date, date, numeric, text, text, text, text
) from public, anon;

revoke all on function public.set_sparks_person_capacity_allocation(
  uuid, uuid, uuid, text, text, uuid, date, date, numeric, text, text, text
) from public, anon;

revoke all on function public.get_sparks_person_capacity_projection(
  uuid, uuid, date, date
) from public, anon;

grant execute on function public.set_sparks_person_capacity_period(
  uuid, uuid, uuid, date, date, numeric, text, text, text, text
) to authenticated, service_role;

grant execute on function public.set_sparks_person_capacity_allocation(
  uuid, uuid, uuid, text, text, uuid, date, date, numeric, text, text, text
) to authenticated, service_role;

grant execute on function public.get_sparks_person_capacity_projection(
  uuid, uuid, date, date
) to authenticated, service_role;

commit;
