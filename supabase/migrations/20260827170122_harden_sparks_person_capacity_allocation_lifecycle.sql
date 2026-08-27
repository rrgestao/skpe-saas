begin;

create or replace function public.guard_sparks_person_capacity_allocation_update()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  if new.organization_id is distinct from old.organization_id
     or new.capacity_period_id is distinct from old.capacity_period_id
     or new.module_code is distinct from old.module_code
     or new.object_type is distinct from old.object_type
     or new.object_id is distinct from old.object_id then
    raise exception 'Capacity allocation identity is immutable.'
      using errcode = '55000';
  end if;

  if old.status in ('ended','cancelled') then
    raise exception 'Terminal capacity allocation cannot be modified.'
      using errcode = '55000';
  end if;

  if old.status = 'planned'
     and new.status not in ('planned','active','cancelled') then
    raise exception 'Invalid capacity allocation lifecycle transition.'
      using errcode = '55000';
  end if;

  if old.status = 'active'
     and new.status not in ('active','ended','cancelled') then
    raise exception 'Invalid capacity allocation lifecycle transition.'
      using errcode = '55000';
  end if;

  if new.status in ('ended','cancelled')
     and new.status is distinct from old.status
     and (
       new.allocation_start is distinct from old.allocation_start
       or new.allocation_end is distinct from old.allocation_end
       or new.allocated_amount is distinct from old.allocated_amount
       or new.notes is distinct from old.notes
     ) then
    raise exception 'Terminalizing a capacity allocation may only change lifecycle status and audit metadata.'
      using errcode = '55000';
  end if;

  return new;
end;
$function$;

revoke all on function public.guard_sparks_person_capacity_allocation_update()
from public, anon, authenticated;

drop trigger if exists sparks_person_capacity_allocations_guard_lifecycle
on public.sparks_person_capacity_allocations;

create trigger sparks_person_capacity_allocations_guard_lifecycle
before update on public.sparks_person_capacity_allocations
for each row
execute function public.guard_sparks_person_capacity_allocation_update();

comment on function public.guard_sparks_person_capacity_allocation_update() is
  'Enforces immutable capacity-allocation identity and governed lifecycle transitions. Planned allocations may activate or cancel; active allocations may end or cancel; ended/cancelled allocations are terminal.';

commit;
