begin;

-- 17-B.5F.3C.6L-PROPOSED-H1
-- Harden aggregate journey actual execution semantics.
-- Parent actual dates are derived from mandatory non-gate children, while
-- leaf actual dates remain governed by transition_skpe_journey_item_execution.

create or replace function public.skpe_recalculate_journey_project_internal(
  p_project_id uuid,
  p_reason text,
  p_actor_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_project public.skpe_projects%rowtype;
  v_item public.skpe_journey_items%rowtype;
  v_previous jsonb;
  v_progress numeric;
  v_status text;
  v_dependencies_met boolean;
  v_project_progress numeric;
  v_aggregate_actual_start date;
  v_aggregate_actual_end date;
begin
  if p_actor_user_id is null then
    raise exception 'Usuario responsavel pelo recalculo nao informado.';
  end if;

  if p_reason is null or length(trim(p_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.';
  end if;

  select *
    into v_project
  from public.skpe_projects
  where id = p_project_id
    and archived_at is null
  for update;

  if v_project.id is null then
    raise exception 'Projeto estrategico nao encontrado.';
  end if;

  perform 1
  from public.skpe_journey_items
  where project_id = p_project_id
    and archived_at is null
  order by id
  for update;

  for v_item in
    select *
    from public.skpe_journey_items
    where project_id = p_project_id
      and archived_at is null
      and jsonb_typeof(metadata->'unblock_dependencies') = 'array'
    order by display_order, code
    for update
  loop
    select not exists (
      select 1
      from jsonb_array_elements(v_item.metadata->'unblock_dependencies') d
      where coalesce(d->>'code', '') = ''
         or coalesce(d->>'required_status', '') = ''
         or not exists (
           select 1
           from public.skpe_journey_items prerequisite
           where prerequisite.project_id = v_item.project_id
             and prerequisite.archived_at is null
             and prerequisite.code = d->>'code'
             and prerequisite.status = d->>'required_status'
         )
    )
      into v_dependencies_met;

    v_previous := jsonb_build_object(
      'status', v_item.status,
      'progress', v_item.progress,
      'blocked', v_item.blocked,
      'blocking_reason', v_item.blocking_reason
    );

    if v_dependencies_met and v_item.blocked then
      update public.skpe_journey_items
      set
        status = 'not_started',
        progress = 0,
        blocked = false,
        blocking_reason = null,
        is_current = false,
        updated_at = timezone('utc', now()),
        updated_by = p_actor_user_id
      where id = v_item.id;
    elsif not v_dependencies_met and not v_item.blocked then
      update public.skpe_journey_items
      set
        status = 'blocked',
        blocked = true,
        blocking_reason = 'Dependencia metodologica ainda nao atendida.',
        is_current = false,
        updated_at = timezone('utc', now()),
        updated_by = p_actor_user_id
      where id = v_item.id;
    else
      continue;
    end if;

    insert into public.skpe_journey_audit (
      organization_id,
      project_id,
      journey_item_id,
      actor_user_id,
      action_code,
      reason,
      previous_data,
      new_data
    )
    select
      v_project.organization_id,
      v_project.id,
      i.id,
      p_actor_user_id,
      'journey_dependency_reassessed',
      trim(p_reason),
      v_previous,
      jsonb_build_object(
        'status', i.status,
        'progress', i.progress,
        'blocked', i.blocked,
        'blocking_reason', i.blocking_reason
      )
    from public.skpe_journey_items i
    where i.id = v_item.id;
  end loop;

  for v_item in
    with recursive hierarchy as (
      select i.id, i.parent_item_id, 0 depth
      from public.skpe_journey_items i
      where i.project_id = p_project_id
        and i.parent_item_id is null
        and i.archived_at is null

      union all

      select c.id, c.parent_item_id, h.depth + 1
      from public.skpe_journey_items c
      join hierarchy h on c.parent_item_id = h.id
      where c.project_id = p_project_id
        and c.archived_at is null
    )
    select i.*
    from public.skpe_journey_items i
    join hierarchy h on h.id = i.id
    where exists (
      select 1
      from public.skpe_journey_items c
      where c.parent_item_id = i.id
        and c.archived_at is null
        and c.status <> 'cancelled'
        and c.item_type <> 'gate'
        and c.is_mandatory = true
    )
    order by h.depth desc, i.display_order desc, i.code desc
  loop
    select
      round(
        greatest(
          0,
          least(
            100,
            sum(
              c.progress * case
                when coalesce(c.metadata->>'progress_weight','') ~ '^[0-9]+([.][0-9]+)?$'
                     and (c.metadata->>'progress_weight')::numeric > 0
                  then (c.metadata->>'progress_weight')::numeric
                else 1
              end
            )
            / nullif(
                sum(
                  case
                    when coalesce(c.metadata->>'progress_weight','') ~ '^[0-9]+([.][0-9]+)?$'
                         and (c.metadata->>'progress_weight')::numeric > 0
                      then (c.metadata->>'progress_weight')::numeric
                    else 1
                  end
                ),
                0
              )
          )
        ),
        0
      ),
      case
        when bool_and(c.status = 'completed' and c.progress = 100) then 'completed'
        when bool_and(c.status = 'not_started' and c.progress = 0) then 'not_started'
        else 'in_progress'
      end,
      min(c.actual_start_date) filter (where c.actual_start_date is not null),
      case
        when bool_and(c.status = 'completed' and c.progress = 100)
          then max(c.actual_end_date)
        else null
      end
    into
      v_progress,
      v_status,
      v_aggregate_actual_start,
      v_aggregate_actual_end
    from public.skpe_journey_items c
    where c.parent_item_id = v_item.id
      and c.archived_at is null
      and c.status <> 'cancelled'
      and c.item_type <> 'gate'
      and c.is_mandatory = true;

    if v_item.blocked then
      v_status := 'blocked';
    end if;

    if v_item.progress is distinct from v_progress
       or v_item.status is distinct from v_status
       or v_item.actual_start_date is distinct from v_aggregate_actual_start
       or v_item.actual_end_date is distinct from v_aggregate_actual_end then

      v_previous := jsonb_build_object(
        'status', v_item.status,
        'progress', v_item.progress,
        'actual_start_date', v_item.actual_start_date,
        'actual_end_date', v_item.actual_end_date
      );

      update public.skpe_journey_items
      set
        status = v_status,
        progress = v_progress,
        is_current = case when v_status = 'in_progress' then is_current else false end,
        actual_start_date = v_aggregate_actual_start,
        actual_end_date = v_aggregate_actual_end,
        updated_at = timezone('utc', now()),
        updated_by = p_actor_user_id
      where id = v_item.id;

      insert into public.skpe_journey_audit (
        organization_id,
        project_id,
        journey_item_id,
        actor_user_id,
        action_code,
        reason,
        previous_data,
        new_data
      )
      values (
        v_project.organization_id,
        v_project.id,
        v_item.id,
        p_actor_user_id,
        'journey_rollup_recalculated',
        trim(p_reason),
        v_previous,
        jsonb_build_object(
          'status', v_status,
          'progress', v_progress,
          'actual_start_date', v_aggregate_actual_start,
          'actual_end_date', v_aggregate_actual_end,
          'actual_source', 'derived_from_mandatory_children'
        )
      );
    end if;
  end loop;

  select round(
    coalesce(
      sum(
        i.progress * case
          when coalesce(i.metadata->>'progress_weight','') ~ '^[0-9]+([.][0-9]+)?$'
               and (i.metadata->>'progress_weight')::numeric > 0
            then (i.metadata->>'progress_weight')::numeric
          else 1
        end
      )
      / nullif(
          sum(
            case
              when coalesce(i.metadata->>'progress_weight','') ~ '^[0-9]+([.][0-9]+)?$'
                   and (i.metadata->>'progress_weight')::numeric > 0
                then (i.metadata->>'progress_weight')::numeric
              else 1
            end
          ),
          0
        ),
      v_project.progress
    ),
    0
  )
    into v_project_progress
  from public.skpe_journey_items i
  where i.project_id = p_project_id
    and i.parent_item_id is null
    and i.archived_at is null
    and i.status <> 'cancelled'
    and i.item_type <> 'gate'
    and i.is_mandatory = true;

  if v_project.progress is distinct from v_project_progress then
    update public.skpe_projects
    set
      progress = v_project_progress,
      updated_at = timezone('utc', now()),
      updated_by = p_actor_user_id
    where id = v_project.id;

    insert into public.skpe_journey_audit (
      organization_id,
      project_id,
      journey_item_id,
      actor_user_id,
      action_code,
      reason,
      previous_data,
      new_data
    )
    values (
      v_project.organization_id,
      v_project.id,
      null,
      p_actor_user_id,
      'journey_project_progress_recalculated',
      trim(p_reason),
      jsonb_build_object('progress', v_project.progress),
      jsonb_build_object('progress', v_project_progress)
    );
  end if;
end;
$function$;

comment on function public.skpe_recalculate_journey_project_internal(uuid, text, uuid) is
  'Recalculates governed SK-PE journey dependencies and hierarchical rollups. Aggregate actual start/end dates are derived from mandatory non-gate children and never from schedule dates.';

commit;