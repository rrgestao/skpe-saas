drop function if exists public.get_sparks_initiative_action_board(uuid);

create function public.get_sparks_initiative_action_board(
  target_initiative_id uuid
)
returns table(
  action_id uuid,
  organization_id uuid,
  initiative_id uuid,
  parent_action_id uuid,
  depth integer,
  code text,
  name text,
  description text,
  action_type text,
  status text,
  priority text,
  official_progress numeric,
  calculated_progress numeric,
  is_root boolean,
  has_eligible_children boolean,
  responsible_area_id uuid,
  responsible_area_name text,
  responsible_person_ids uuid[],
  responsible_person_names text[],
  planned_start_date date,
  planned_due_date date,
  planned_cost numeric,
  actual_cost numeric,
  currency_code text,
  estimated_effort numeric,
  actual_effort numeric,
  effort_unit text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  target_initiative public.sparks_initiatives%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Operacao exige usuario autenticado.'
      using errcode = '42501';
  end if;

  if target_initiative_id is null then
    raise exception 'Informe a iniciativa.'
      using errcode = '22023';
  end if;

  select initiative.*
  into target_initiative
  from public.sparks_initiatives initiative
  where initiative.id = target_initiative_id
    and initiative.archived_at is null;

  if target_initiative.id is null then
    raise exception 'Iniciativa nao encontrada ou arquivada.'
      using errcode = '22023';
  end if;

  if not public.can_read_organization(
    target_initiative.organization_id
  ) then
    raise exception
      'Acesso negado: o usuario nao pode consultar esta iniciativa.'
      using errcode = '42501';
  end if;

  return query
  select
    action.id as action_id,
    action.organization_id,
    action.initiative_id,
    action.parent_action_id,
    rollup.depth,
    action.code,
    action.name,
    action.description,
    action.action_type,
    action.status,
    action.priority,
    rollup.official_progress,
    rollup.calculated_progress,
    rollup.is_root,
    rollup.has_eligible_children,
    action.responsible_area_id,
    area_value.name as responsible_area_name,
    coalesce(responsibility_people.person_ids, '{}'::uuid[]) as responsible_person_ids,
    coalesce(responsibility_people.person_names, '{}'::text[]) as responsible_person_names,
    action.planned_start_date,
    action.planned_due_date,
    action.planned_cost,
    action.actual_cost,
    action.currency_code,
    action.estimated_effort,
    action.actual_effort,
    action.effort_unit,
    action.started_at,
    action.completed_at,
    action.created_at,
    action.updated_at
  from public.get_sparks_initiative_action_rollup(
    target_initiative.id
  ) rollup
  join public.sparks_initiative_actions action
    on action.id = rollup.action_id
   and action.organization_id = target_initiative.organization_id
   and action.initiative_id = target_initiative.id
  left join public.sparks_domain_values area_value
    on area_value.id = action.responsible_area_id
  left join lateral (
    select
      array_agg(distinct person.id order by person.id) as person_ids,
      array_agg(
        distinct coalesce(person.preferred_name, person.full_name)
        order by coalesce(person.preferred_name, person.full_name)
      ) as person_names
    from public.sparks_responsibility_assignments responsibility
    join public.sparks_organization_people relationship
      on relationship.id = responsibility.organization_person_id
     and relationship.organization_id = responsibility.organization_id
    join public.sparks_people person
      on person.id = relationship.person_id
    where responsibility.organization_id = action.organization_id
      and responsibility.module_code = action.source_module_code
      and responsibility.object_type = 'initiative_action'
      and responsibility.object_id = action.id
      and responsibility.status = 'active'
  ) responsibility_people on true
  where action.archived_at is null
    and action.status not in ('cancelled', 'archived')
  order by
    case action.priority
      when 'critical' then 1
      when 'high' then 2
      when 'medium' then 3
      when 'low' then 4
      else 5
    end,
    action.planned_due_date asc nulls last,
    action.created_at asc,
    action.code asc;
end;
$$;

revoke all on function public.get_sparks_initiative_action_board(uuid) from public;
revoke all on function public.get_sparks_initiative_action_board(uuid) from anon;
grant execute on function public.get_sparks_initiative_action_board(uuid) to authenticated;
grant execute on function public.get_sparks_initiative_action_board(uuid) to service_role;
