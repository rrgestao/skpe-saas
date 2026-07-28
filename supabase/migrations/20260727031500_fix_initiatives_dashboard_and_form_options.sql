-- ============================================================
-- Plataforma SPARKs / SK-PE
-- Correção do Painel de Iniciativas e opções para cadastro
-- Conteúdos funcionais em Português do Brasil
-- ============================================================

begin;

create or replace function public.get_skpe_initiatives_dashboard(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_initiative_type text default null,
  target_responsible_area text default null,
  target_strategic_objective_id uuid default null,
  target_status text default null
)
returns table (
  total_initiatives bigint,
  proposed_count bigint,
  in_progress_count bigint,
  completed_count bigint,
  delayed_count bigint,
  blocked_count bigint,
  critical_count bigint,
  without_owner_count bigint,
  without_recent_update_count bigint,
  with_instrument_count bigint,
  without_instrument_count bigint,
  average_progress numeric,
  planned_cost numeric,
  actual_cost numeric,
  planned_benefit numeric,
  realized_benefit numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_initiatives(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode consultar as iniciativas desta organização.'
      using errcode = '42501';
  end if;

  return query
  with filtered_initiatives as (
    select distinct
      initiative.id,
      initiative.status,
      initiative.priority,
      initiative.owner_user_id,
      initiative.due_date,
      initiative.progress,
      initiative.risk_level,
      initiative.health_status,
      initiative.last_update_at,
      initiative.updated_at,
      initiative.created_at,
      initiative.planned_cost,
      initiative.actual_cost,
      initiative.planned_benefit,
      initiative.realized_benefit
    from public.skpe_initiatives initiative
    left join public.skpe_initiative_objectives initiative_objective
      on initiative_objective.initiative_id = initiative.id
    where initiative.organization_id = target_organization_id
      and initiative.archived_at is null
      and (target_project_id is null or initiative.project_id = target_project_id)
      and (target_initiative_type is null or initiative.initiative_type = target_initiative_type)
      and (target_responsible_area is null or initiative.responsible_area = target_responsible_area)
      and (target_status is null or initiative.status = target_status)
      and (
        target_strategic_objective_id is null
        or initiative_objective.strategic_objective_id = target_strategic_objective_id
      )
  )
  select
    count(*)::bigint,
    count(*) filter (
      where fi.status in ('proposed', 'under_analysis')
    )::bigint,
    count(*) filter (
      where fi.status = 'in_progress'
    )::bigint,
    count(*) filter (
      where fi.status = 'completed'
    )::bigint,
    count(*) filter (
      where fi.due_date < current_date
        and fi.status not in ('completed', 'cancelled', 'archived')
    )::bigint,
    count(*) filter (where fi.status = 'blocked')::bigint,
    count(*) filter (
      where fi.priority = 'critical'
         or fi.risk_level = 'critical'
         or fi.health_status = 'critical'
    )::bigint,
    count(*) filter (where fi.owner_user_id is null)::bigint,
    count(*) filter (
      where fi.status not in ('completed', 'cancelled', 'archived')
        and coalesce(fi.last_update_at, fi.updated_at, fi.created_at)
          < timezone('utc', now()) - interval '30 days'
    )::bigint,
    count(*) filter (
      where exists (
        select 1
        from public.skpe_initiative_instruments instrument
        where instrument.initiative_id = fi.id
          and instrument.status <> 'archived'
      )
    )::bigint,
    count(*) filter (
      where not exists (
        select 1
        from public.skpe_initiative_instruments instrument
        where instrument.initiative_id = fi.id
          and instrument.status <> 'archived'
      )
    )::bigint,
    coalesce(round(avg(fi.progress), 2), 0)::numeric,
    coalesce(sum(fi.planned_cost), 0)::numeric,
    coalesce(sum(fi.actual_cost), 0)::numeric,
    coalesce(sum(fi.planned_benefit), 0)::numeric,
    coalesce(sum(fi.realized_benefit), 0)::numeric
  from filtered_initiatives fi;
end;
$$;

revoke all on function public.get_skpe_initiatives_dashboard(uuid, uuid, text, text, uuid, text)
from public, anon;

grant execute on function public.get_skpe_initiatives_dashboard(uuid, uuid, text, text, uuid, text)
to authenticated, service_role;

commit;
