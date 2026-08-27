begin;

-- 17-B.5F.3C.6K-PROPOSED-H1
-- Correct canonical skpe_projects field references in the integrated
-- management projection. The previous migration remains immutable.

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

  if public.can_view_sparks_people(target_organization_id) then
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
    'transversalInitiative', jsonb_build_object(
      'initiativeId', v_initiative.id,
      'code', v_initiative.code,
      'name', v_initiative.name,
      'lifecycleStatus', v_initiative.status,
      'sourceModuleCode', v_initiative.source_module_code
    ),
    'journeyTemporal', v_journey_temporal,
    'initiativeTemporal', v_initiative_temporal,
    'actionBoard', v_action_board,
    'economic', v_economic,
    'capacity', jsonb_build_object(
      'allocations', v_capacity_allocations,
      'involvedPeopleCapacity', v_person_capacity,
      'visible', public.can_view_sparks_people(target_organization_id)
    ),
    'governance', jsonb_build_object(
      'readOnlyProjection', true,
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

comment on function public.get_skpe_project_management_projection(uuid, uuid, date) is
  'Read-only integrated management projection for one SK-PE project, composing governed journey schedule, transversal initiative temporality, Kanban/action execution, economic projection and relevant person capacity without duplicating their sources of truth.';

commit;