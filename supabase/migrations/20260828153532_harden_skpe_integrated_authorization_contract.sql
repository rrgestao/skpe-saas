begin;

create or replace function public.can_view_sparks_initiatives(
  target_organization_id uuid,
  target_source_module_code text default null
)
returns boolean
language sql
stable
set search_path = ''
as $function$
  select
    public.is_platform_super_admin()
    or public.can_manage_organization(target_organization_id)
    or (
      nullif(upper(trim(target_source_module_code)), '') is not null
      and (
        public.has_module_permission(
          target_organization_id,
          upper(trim(target_source_module_code)),
          'initiatives.view'
        )
        or public.has_module_permission(
          target_organization_id,
          upper(trim(target_source_module_code)),
          'initiatives.manage'
        )
      )
    );
$function$;

comment on function public.can_view_sparks_initiatives(uuid, text) is
'Autoridade transversal de leitura de iniciativas da Plataforma SPARKs. Autoriza superadministrador, administrador da organizacao ou usuario com initiatives.view/initiatives.manage no modulo de origem.';

revoke all on function public.can_view_sparks_initiatives(uuid, text)
  from public, anon;
grant execute on function public.can_view_sparks_initiatives(uuid, text)
  to authenticated, service_role;

drop function public.get_skpe_effective_capabilities(uuid);

create function public.get_skpe_effective_capabilities(
  target_organization_id uuid
)
returns table(
  can_view_overview boolean,
  can_view_journey boolean,
  can_view_initiatives boolean,
  can_view_artifacts boolean,
  can_generate_delivery_kit boolean,
  can_view_governance boolean,
  can_manage_journey boolean,
  can_manage_initiatives boolean,
  can_manage_artifacts boolean,
  can_manage_skpe boolean,
  can_administer_users boolean,
  can_administer_memberships boolean,
  can_administer_settings boolean
)
language sql
stable
security definer
set search_path = ''
as $function$
  with access as (
    select
      public.is_platform_super_admin() as super_admin,
      public.is_organization_admin(target_organization_id) as organization_admin,
      public.has_module_permission(target_organization_id, 'SK-PE', 'module.view') as module_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'module.manage') as module_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'content.view') as content_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'content.edit') as content_edit,
      public.has_module_permission(target_organization_id, 'SK-PE', 'journey.view') as journey_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'journey.manage') as journey_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'initiatives.view') as initiatives_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'initiatives.manage') as initiatives_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'reports.view') as reports_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'reports.export') as reports_export,
      public.has_module_permission(target_organization_id, 'SK-PE', 'evidence_checklist.view') as evidence_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'evidence_checklist.manage') as evidence_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'governance_roles.view') as governance_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'governance_roles.manage') as governance_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_monitoring.view') as monitoring_view,
      public.has_module_permission(target_organization_id, 'SK-PE', 'strategic_governance.manage') as strategic_governance_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'users.manage') as users_manage,
      public.has_module_permission(target_organization_id, 'SK-PE', 'settings.manage') as settings_manage
  )
  select
    super_admin or organization_admin or module_view or content_view,
    super_admin or organization_admin or journey_view or journey_manage,
    super_admin or organization_admin or initiatives_view or initiatives_manage,
    super_admin or organization_admin or reports_view or evidence_view or content_view,
    super_admin or organization_admin or reports_export or reports_view or evidence_view,
    super_admin or organization_admin or governance_view or governance_manage or monitoring_view or strategic_governance_manage,
    super_admin or organization_admin or journey_manage,
    super_admin or organization_admin or initiatives_manage,
    super_admin or organization_admin or content_edit or evidence_manage or module_manage,
    super_admin or organization_admin or module_manage,
    super_admin or organization_admin or users_manage,
    super_admin or organization_admin,
    super_admin or organization_admin or settings_manage
  from access;
$function$;

revoke all on function public.get_skpe_effective_capabilities(uuid)
  from public, anon;
grant execute on function public.get_skpe_effective_capabilities(uuid)
  to authenticated, service_role;

comment on function public.get_skpe_effective_capabilities(uuid) is
'Capacidades efetivas do SK-PE, incluindo gestao de Jornada e gestao de Iniciativas como autoridades independentes.';

create or replace function public.get_skpe_project_management_projection(
  target_organization_id uuid,
  target_project_id uuid,
  target_as_of_date date default current_date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_reference_date date := coalesce(target_as_of_date, current_date);

  v_binding public.skpe_project_initiative_bindings%rowtype;
  v_project public.skpe_projects%rowtype;
  v_initiative public.sparks_initiatives%rowtype;

  v_can_view_journey boolean := false;
  v_can_view_initiatives boolean := false;
  v_can_view_capacity boolean := false;

  v_journey_temporal jsonb := '[]'::jsonb;
  v_initiative_temporal jsonb := '[]'::jsonb;
  v_action_board jsonb := '[]'::jsonb;
  v_economic jsonb := '{}'::jsonb;
  v_capacity_allocations jsonb := '[]'::jsonb;
  v_person_capacity jsonb := '[]'::jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required.'
      using errcode = '42501';
  end if;

  if target_organization_id is null or target_project_id is null then
    raise exception 'Organization and SK-PE project are required.'
      using errcode = '22023';
  end if;

  if not public.can_read_organization(target_organization_id) then
    raise exception 'Access denied to read this organization.'
      using errcode = '42501';
  end if;

  select project.*
    into v_project
  from public.skpe_projects project
  where project.id = target_project_id
    and project.organization_id = target_organization_id;

  if v_project.id is null then
    raise exception 'SK-PE project not found in the organization.'
      using errcode = 'P0002';
  end if;

  select binding.*
    into v_binding
  from public.skpe_project_initiative_bindings binding
  where binding.organization_id = target_organization_id
    and binding.skpe_project_id = target_project_id;

  if v_binding.id is null then
    raise exception 'SK-PE project is not bound to a transversal SPARKs initiative.'
      using errcode = 'P0002';
  end if;

  select initiative.*
    into v_initiative
  from public.sparks_initiatives initiative
  where initiative.id = v_binding.initiative_id
    and initiative.organization_id = target_organization_id;

  if v_initiative.id is null then
    raise exception 'Bound transversal initiative was not found in the organization.'
      using errcode = '55000';
  end if;

  v_can_view_journey :=
    public.can_view_skpe_journey(target_organization_id);

  v_can_view_initiatives :=
    public.can_view_sparks_initiatives(
      target_organization_id,
      v_initiative.source_module_code
    );

  if not v_can_view_journey and not v_can_view_initiatives then
    raise exception 'Access denied to SK-PE monitoring domains.'
      using errcode = '42501';
  end if;

  if v_can_view_journey then
    select coalesce(
      jsonb_agg(to_jsonb(journey) order by journey.display_order, journey.item_code),
      '[]'::jsonb
    )
      into v_journey_temporal
    from public.get_skpe_journey_temporal_read_model(
      target_organization_id,
      target_project_id,
      v_reference_date
    ) journey;
  end if;

  if v_can_view_initiatives then
    select coalesce(
      jsonb_agg(
        to_jsonb(temporal)
        order by
          case when temporal.entity_type = 'initiative' then 0 else 1 end,
          temporal.code,
          temporal.entity_id
      ),
      '[]'::jsonb
    )
      into v_initiative_temporal
    from public.get_sparks_initiative_temporal_projection(
      target_organization_id,
      v_initiative.id,
      v_reference_date,
      false
    ) temporal;

    select coalesce(
      jsonb_agg(
        to_jsonb(board)
        order by board.depth, board.code, board.action_id
      ),
      '[]'::jsonb
    )
      into v_action_board
    from public.get_sparks_initiative_action_board(v_initiative.id) board;

    v_economic := public.get_sparks_initiative_economic_projection(
      target_organization_id,
      v_initiative.id
    );

    v_can_view_capacity :=
      public.can_view_sparks_people(target_organization_id);

    if v_can_view_capacity then
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'allocationId', allocation.id,
            'capacityPeriodId', capacity.id,
            'organizationPersonId', capacity.organization_person_id,
            'personId', person.id,
            'personName', coalesce(person.preferred_name, person.full_name),
            'organizationalArea', relationship.organizational_area,
            'capacityUnit', capacity.capacity_unit,
            'capacityAmount', capacity.capacity_amount,
            'capacityStatus', capacity.status,
            'moduleCode', allocation.module_code,
            'objectType', allocation.object_type,
            'objectId', allocation.object_id,
            'allocationStart', allocation.allocation_start,
            'allocationEnd', allocation.allocation_end,
            'allocatedAmount', allocation.allocated_amount,
            'allocationStatus', allocation.status
          )
          order by
            coalesce(person.preferred_name, person.full_name),
            allocation.allocation_start,
            allocation.object_type,
            allocation.object_id
        ),
        '[]'::jsonb
      )
        into v_capacity_allocations
      from public.sparks_person_capacity_allocations allocation
      join public.sparks_person_capacity_periods capacity
        on capacity.id = allocation.capacity_period_id
       and capacity.organization_id = allocation.organization_id
      join public.sparks_organization_people relationship
        on relationship.id = capacity.organization_person_id
       and relationship.organization_id = capacity.organization_id
      join public.sparks_people person
        on person.id = relationship.person_id
      where allocation.organization_id = target_organization_id
        and allocation.module_code = v_initiative.source_module_code
        and (
          (
            lower(allocation.object_type) in ('initiative', 'sparks_initiative')
            and allocation.object_id = v_initiative.id
          )
          or
          (
            lower(allocation.object_type) in ('initiative_action', 'sparks_initiative_action')
            and exists (
              select 1
              from public.sparks_initiative_actions action
              where action.id = allocation.object_id
                and action.organization_id = target_organization_id
                and action.initiative_id = v_initiative.id
            )
          )
        );

      select coalesce(
        jsonb_agg(
          to_jsonb(person_capacity)
          order by
            person_capacity.person_name,
            person_capacity.period_start,
            person_capacity.capacity_unit
        ),
        '[]'::jsonb
      )
        into v_person_capacity
      from (
        select projection.*
        from (
          select distinct capacity.organization_person_id
          from public.sparks_person_capacity_allocations allocation
          join public.sparks_person_capacity_periods capacity
            on capacity.id = allocation.capacity_period_id
           and capacity.organization_id = allocation.organization_id
          where allocation.organization_id = target_organization_id
            and allocation.module_code = v_initiative.source_module_code
            and (
              (
                lower(allocation.object_type) in ('initiative', 'sparks_initiative')
                and allocation.object_id = v_initiative.id
              )
              or
              (
                lower(allocation.object_type) in ('initiative_action', 'sparks_initiative_action')
                and exists (
                  select 1
                  from public.sparks_initiative_actions action
                  where action.id = allocation.object_id
                    and action.organization_id = target_organization_id
                    and action.initiative_id = v_initiative.id
                )
              )
            )
        ) involved_person
        cross join lateral public.get_sparks_person_capacity_projection(
          target_organization_id,
          involved_person.organization_person_id,
          null,
          null
        ) projection
      ) person_capacity;
    end if;
  end if;

  return jsonb_build_object(
    'referenceDate', v_reference_date,
    'organizationId', target_organization_id,
    'skpeProject', jsonb_build_object(
      'projectId', v_project.id,
      'projectCode', v_project.code,
      'projectName', v_project.name,
      'projectStatus', v_project.status,
      'bindingId', v_binding.id,
      'bindingType', v_binding.binding_type
    ),
    'transversalInitiative',
      case
        when v_can_view_initiatives then
          jsonb_build_object(
            'initiativeId', v_initiative.id,
            'code', v_initiative.code,
            'name', v_initiative.name,
            'lifecycleStatus', v_initiative.status,
            'sourceModuleCode', v_initiative.source_module_code
          )
        else null
      end,
    'journeyTemporal', v_journey_temporal,
    'initiativeTemporal', v_initiative_temporal,
    'actionBoard', v_action_board,
    'economic', v_economic,
    'capacity', jsonb_build_object(
      'allocations', v_capacity_allocations,
      'involvedPeopleCapacity', v_person_capacity,
      'visible', v_can_view_initiatives and v_can_view_capacity
    ),
    'governance', jsonb_build_object(
      'readOnlyProjection', true,
      'journeyVisible', v_can_view_journey,
      'initiativesVisible', v_can_view_initiatives,
      'economicVisible', v_can_view_initiatives,
      'capacityVisible', v_can_view_initiatives and v_can_view_capacity,
      'duplicatesSourceOfTruth', false,
      'automaticScheduleMutation', false,
      'automaticLifecycleMutation', false,
      'automaticProgressMutation', false,
      'automaticEconomicMutation', false,
      'automaticCapacityNormalization', false,
      'agendaRemainsPersonalReadModel', true,
      'journeyScheduleAuthority', 'skpe_journey_schedule_versions/items',
      'initiativeTemporalAuthority', 'sparks_initiatives/sparks_initiative_actions',
      'kanbanAuthority', 'sparks_initiative_actions',
      'economicAuthority', 'sparks_initiatives/sparks_initiative_actions',
      'capacityAuthority', 'sparks_person_capacity_periods/allocations'
    )
  );
end;
$function$;

revoke all on function public.get_skpe_project_management_projection(uuid, uuid, date)
  from public, anon;
grant execute on function public.get_skpe_project_management_projection(uuid, uuid, date)
  to authenticated, service_role;

create or replace function public.get_skpe_project_operational_projection(
  target_organization_id uuid,
  target_project_id uuid,
  target_as_of_date date default current_date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_base jsonb;
  v_events jsonb := '[]'::jsonb;
  v_reference_date date := coalesce(target_as_of_date, current_date);
  v_journey_visible boolean := false;
begin
  v_base := public.get_skpe_project_management_projection(
    target_organization_id,
    target_project_id,
    v_reference_date
  );

  v_journey_visible :=
    coalesce(
      (v_base->'governance'->>'journeyVisible')::boolean,
      false
    );

  if v_journey_visible then
    select coalesce(
      jsonb_agg(
        to_jsonb(e)
        order by e.starts_at nulls last, e.journey_item_code, e.event_id
      ),
      '[]'::jsonb
    )
      into v_events
    from public.get_skpe_journey_events_projection(
      target_organization_id,
      target_project_id,
      null,
      null,
      false,
      false
    ) e;
  end if;

  return jsonb_set(
    v_base || jsonb_build_object('journeyEvents', v_events),
    '{governance}',
    coalesce(v_base->'governance','{}'::jsonb) || jsonb_build_object(
      'eventAuthority','sparks_events/sparks_event_participants',
      'journeyEventLinkAuthority','sparks_events.source_module_code/source_entity_type/source_entity_id',
      'duplicatesAgendaSourceOfTruth',false,
      'journeyEventsIncluded',v_journey_visible,
      'personalAgendaRemainsParticipantScoped',true
    ),
    true
  );
end;
$function$;

revoke all on function public.get_skpe_project_operational_projection(uuid, uuid, date)
  from public, anon;
grant execute on function public.get_skpe_project_operational_projection(uuid, uuid, date)
  to authenticated, service_role;

comment on function public.get_skpe_project_operational_projection(uuid, uuid, date) is
'Integrated SK-PE operational projection with domain-aware authorization. Journey/events and initiatives/economic/capacity are included only when the user can view the corresponding governed domain.';

commit;