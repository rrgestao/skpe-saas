create or replace function public.can_manage_sparks_event_source(
  target_organization_id uuid,
  target_source_module_code text,
  target_source_entity_type text,
  target_source_entity_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select
    auth.uid() is not null
    and target_organization_id is not null
    and (
      public.can_manage_organization(target_organization_id)
      or (
        upper(trim(coalesce(target_source_module_code, ''))) = 'SK-PE'
        and lower(trim(coalesce(target_source_entity_type, ''))) = 'skpe_journey_item'
        and target_source_entity_id is not null
        and public.has_module_access(target_organization_id, 'SK-PE')
        and public.can_manage_skpe_journey(target_organization_id)
        and exists (
          select 1
          from public.skpe_journey_items ji
          join public.skpe_projects p
            on p.id = ji.project_id
           and p.organization_id = target_organization_id
           and p.archived_at is null
          where ji.id = target_source_entity_id
            and ji.archived_at is null
        )
      )
      or (
        lower(trim(coalesce(target_source_entity_type, ''))) = 'sparks_initiative'
        and target_source_entity_id is not null
        and exists (
          select 1
          from public.sparks_initiatives i
          where i.id = target_source_entity_id
            and i.organization_id = target_organization_id
            and i.archived_at is null
            and coalesce(upper(trim(i.source_module_code)), '') = upper(trim(coalesce(target_source_module_code, '')))
            and public.can_manage_sparks_initiatives(
              target_organization_id,
              i.source_module_code
            )
        )
      )
      or (
        lower(trim(coalesce(target_source_entity_type, ''))) = 'sparks_initiative_action'
        and target_source_entity_id is not null
        and exists (
          select 1
          from public.sparks_initiative_actions a
          join public.sparks_initiatives i
            on i.id = a.initiative_id
           and i.organization_id = a.organization_id
           and i.archived_at is null
          where a.id = target_source_entity_id
            and a.organization_id = target_organization_id
            and a.archived_at is null
            and coalesce(upper(trim(a.source_module_code)), '') = upper(trim(coalesce(target_source_module_code, '')))
            and public.can_manage_sparks_initiatives(
              target_organization_id,
              coalesce(a.source_module_code, i.source_module_code)
            )
        )
      )
    );
$function$;

comment on function public.can_manage_sparks_event_source(uuid, text, text, uuid) is
  'Autoriza gestao de eventos nativos da organizacao e eventos vinculados a fontes governadas. Suporta SK-PE journey item, sparks_initiative e sparks_initiative_action sem duplicar a autoridade dos objetos de origem.';
