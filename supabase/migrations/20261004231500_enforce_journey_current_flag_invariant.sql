-- Enforce the technical invariant between journey execution status and is_current.
-- Business status/progress/validation are not changed by this migration.

create or replace function public.skpe_guard_journey_current_flag()
returns trigger
language plpgsql
set search_path=''
as $function$
begin
  if new.status <> 'in_progress' and new.is_current then
    new.is_current := false;
  end if;

  return new;
end;
$function$;

drop trigger if exists skpe_journey_current_flag_guard
on public.skpe_journey_items;

create trigger skpe_journey_current_flag_guard
before insert or update of status,is_current
on public.skpe_journey_items
for each row
execute function public.skpe_guard_journey_current_flag();

update public.skpe_journey_items
set
  is_current=false,
  updated_at=timezone('utc',now())
where archived_at is null
  and status<>'in_progress'
  and is_current=true;

comment on function public.skpe_guard_journey_current_flag() is
'Technical invariant: is_current may only be true for an in_progress Journey Item. Does not promote or change business execution status.';
