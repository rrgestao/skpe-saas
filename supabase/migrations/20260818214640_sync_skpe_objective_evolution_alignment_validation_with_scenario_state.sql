create or replace function public.sync_skpe_objective_evolution_alignment_validation_with_scenario_state()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  if new.status = 'proposed'
     and old.status in ('draft', 'adjusted') then
    update public.skpe_objective_evolution_scenario_alignments
    set
      validation_status = 'pending_validation',
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
    where scenario_id = new.id
      and validation_status = 'draft';

  elsif new.status in ('draft', 'adjusted', 'deferred', 'rejected') then
    update public.skpe_objective_evolution_scenario_alignments
    set
      validation_status = 'draft',
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
    where scenario_id = new.id
      and validation_status = 'pending_validation';
  end if;

  return new;
end;
$$;

revoke execute
on function public.sync_skpe_objective_evolution_alignment_validation_with_scenario_state()
from public;

revoke execute
on function public.sync_skpe_objective_evolution_alignment_validation_with_scenario_state()
from anon;

revoke execute
on function public.sync_skpe_objective_evolution_alignment_validation_with_scenario_state()
from authenticated;

grant execute
on function public.sync_skpe_objective_evolution_alignment_validation_with_scenario_state()
to service_role;

drop trigger if exists trg_skpe_evolution_scenario_alignment_validation_sync
on public.skpe_evolution_scenarios;

create trigger trg_skpe_evolution_scenario_alignment_validation_sync
after update of status
on public.skpe_evolution_scenarios
for each row
when (old.status is distinct from new.status)
execute function public.sync_skpe_objective_evolution_alignment_validation_with_scenario_state();