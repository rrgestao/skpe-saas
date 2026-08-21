drop policy if exists sparks_initiative_action_audit_select_authorized
on public.sparks_initiative_action_audit;

create policy sparks_initiative_action_audit_select_authorized
on public.sparks_initiative_action_audit
for select
to authenticated
using (
  exists (
    select 1
    from public.sparks_initiatives initiative
    where initiative.id = sparks_initiative_action_audit.initiative_id
      and initiative.organization_id = sparks_initiative_action_audit.organization_id
      and public.can_manage_sparks_initiatives(
        initiative.organization_id,
        initiative.source_module_code
      )
  )
);;
