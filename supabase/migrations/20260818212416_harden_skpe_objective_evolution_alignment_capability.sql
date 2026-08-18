create or replace function public.can_manage_skpe_objective_evolution_alignment(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.can_manage_skpe_formulation(target_organization_id)
    and public.can_manage_skpe_governance(target_organization_id);
$$;

revoke execute
on function public.can_manage_skpe_objective_evolution_alignment(uuid)
from public;

revoke execute
on function public.can_manage_skpe_objective_evolution_alignment(uuid)
from anon;

grant execute
on function public.can_manage_skpe_objective_evolution_alignment(uuid)
to authenticated;

grant execute
on function public.can_manage_skpe_objective_evolution_alignment(uuid)
to service_role;

revoke execute
on function public.can_manage_skpe_governance(uuid)
from public;

revoke execute
on function public.can_manage_skpe_governance(uuid)
from anon;

grant execute
on function public.can_manage_skpe_governance(uuid)
to authenticated;

grant execute
on function public.can_manage_skpe_governance(uuid)
to service_role;