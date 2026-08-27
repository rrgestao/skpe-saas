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
as $function$
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
$function$;

comment on function public.get_sparks_initiative_action_board(uuid) is
  'Projecao read-only do Kanban transversal de actions, incluindo economia direta da acao. Combina metadados canonicos de sparks_initiative_actions com o roll-up governado, sem criar fonte de verdade Kanban, roll-up economico ou conversao cambial.';

revoke all on function public.get_sparks_initiative_action_board(uuid) from public;
grant execute on function public.get_sparks_initiative_action_board(uuid) to authenticated;
grant execute on function public.get_sparks_initiative_action_board(uuid) to service_role;