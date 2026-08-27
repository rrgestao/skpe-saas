create or replace function public.guard_sparks_person_capacity_period_lifecycle()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.status not in ('planned','active') then
      raise exception 'New capacity period must start as planned or active.'
        using errcode = '55000';
    end if;

    return new;
  end if;

  if new.organization_id is distinct from old.organization_id
     or new.organization_person_id is distinct from old.organization_person_id then
    raise exception 'Capacity period organization and person identity are immutable.'
      using errcode = '55000';
  end if;

  if old.status in ('closed','cancelled') then
    raise exception 'Terminal capacity period cannot be modified.'
      using errcode = '55000';
  end if;

  if old.status = 'planned'
     and new.status not in ('planned','active','cancelled') then
    raise exception 'Invalid capacity period lifecycle transition.'
      using errcode = '55000';
  end if;

  if old.status = 'active'
     and new.status not in ('active','closed','cancelled') then
    raise exception 'Invalid capacity period lifecycle transition.'
      using errcode = '55000';
  end if;

  if exists (
    select 1
    from public.sparks_person_capacity_allocations allocation
    where allocation.capacity_period_id = old.id
  ) then
    if new.capacity_unit is distinct from old.capacity_unit then
      raise exception 'Capacity unit cannot change after allocations exist.'
        using errcode = '55000';
    end if;

    if exists (
      select 1
      from public.sparks_person_capacity_allocations allocation
      where allocation.capacity_period_id = old.id
        and (
          allocation.allocation_start < new.period_start
          or allocation.allocation_end > new.period_end
        )
    ) then
      raise exception 'Capacity period dates cannot exclude an existing allocation.'
        using errcode = '55000';
    end if;
  end if;

  if new.status in ('closed','cancelled')
     and new.status is distinct from old.status then
    if exists (
      select 1
      from public.sparks_person_capacity_allocations allocation
      where allocation.capacity_period_id = old.id
        and allocation.status in ('planned','active')
    ) then
      raise exception 'Capacity period cannot become terminal while open allocations exist.'
        using errcode = '55000';
    end if;

    if new.period_start is distinct from old.period_start
       or new.period_end is distinct from old.period_end
       or new.capacity_amount is distinct from old.capacity_amount
       or new.capacity_unit is distinct from old.capacity_unit then
      raise exception 'Terminalizing a capacity period may not change dates, amount or unit.'
        using errcode = '55000';
    end if;
  end if;

  return new;
end;
$$;

revoke execute on function public.guard_sparks_person_capacity_period_lifecycle()
  from public, anon, authenticated, service_role;

drop trigger if exists sparks_person_capacity_periods_guard_lifecycle
  on public.sparks_person_capacity_periods;

create trigger sparks_person_capacity_periods_guard_lifecycle
before insert or update
on public.sparks_person_capacity_periods
for each row
execute function public.guard_sparks_person_capacity_period_lifecycle();

create or replace function public.guard_sparks_person_capacity_allocation_period_state()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_period_status text;
begin
  if new.status not in ('planned','active') then
    return new;
  end if;

  select capacity.status
    into v_period_status
  from public.sparks_person_capacity_periods capacity
  where capacity.id = new.capacity_period_id
    and capacity.organization_id = new.organization_id;

  if v_period_status is null then
    raise exception 'Capacity period not found for allocation organization.'
      using errcode = 'P0002';
  end if;

  if v_period_status not in ('planned','active') then
    raise exception 'Open capacity allocation requires a planned or active capacity period.'
      using errcode = '55000';
  end if;

  return new;
end;
$$;

revoke execute on function public.guard_sparks_person_capacity_allocation_period_state()
  from public, anon, authenticated, service_role;

drop trigger if exists sparks_person_capacity_allocations_guard_period_state
  on public.sparks_person_capacity_allocations;

create trigger sparks_person_capacity_allocations_guard_period_state
before insert or update
on public.sparks_person_capacity_allocations
for each row
execute function public.guard_sparks_person_capacity_allocation_period_state();
