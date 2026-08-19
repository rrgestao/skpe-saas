-- ============================================================
-- SK-PE-CONT-01
-- 17-B.5B - Correcao de coerencia de estado e contagem de projecao
-- ============================================================

alter table public.skpe_journey_schedule_versions
  add constraint skpe_journey_schedule_versions_current_plan_status_check
  check (
    case
      when schedule_kind in ('baseline', 'rebaseline')
        then (governance_status = 'approved') = is_current_plan
      else not is_current_plan
    end
  );

alter table public.skpe_journey_schedule_versions
  add constraint skpe_journey_schedule_versions_current_forecast_status_check
  check (
    case
      when schedule_kind = 'forecast'
        then (governance_status = 'active') = is_current_forecast
      else not is_current_forecast
    end
  );

create or replace function public.skpe_materialize_current_journey_plan_internal(
  p_schedule_version_id uuid,
  p_actor_user_id uuid,
  p_change_reason text
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_version public.skpe_journey_schedule_versions%rowtype;
  v_updated integer := 0;
  v_cleared integer := 0;
  v_changed integer := 0;
begin
  if p_actor_user_id is null then
    raise exception 'Usuario responsavel pela materializacao nao informado.';
  end if;

  if p_change_reason is null or length(trim(p_change_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.';
  end if;

  select * into v_version
  from public.skpe_journey_schedule_versions
  where id = p_schedule_version_id
    and schedule_kind in ('baseline', 'rebaseline')
    and governance_status = 'approved'
    and is_current_plan
  for update;

  if v_version.id is null then
    raise exception 'Plano temporal aprovado e corrente nao encontrado.';
  end if;

  update public.skpe_journey_items i
  set
    planned_start_date = s.planned_start_date,
    planned_end_date = s.planned_end_date,
    updated_by = p_actor_user_id
  from public.skpe_journey_schedule_items s
  where i.project_id = v_version.project_id
    and i.archived_at is null
    and s.schedule_version_id = v_version.id
    and s.journey_item_id = i.id
    and (
      i.planned_start_date is distinct from s.planned_start_date
      or i.planned_end_date is distinct from s.planned_end_date
    );

  get diagnostics v_updated = row_count;

  update public.skpe_journey_items i
  set
    planned_start_date = null,
    planned_end_date = null,
    updated_by = p_actor_user_id
  where i.project_id = v_version.project_id
    and i.archived_at is null
    and (i.planned_start_date is not null or i.planned_end_date is not null)
    and not exists (
      select 1
      from public.skpe_journey_schedule_items s
      where s.schedule_version_id = v_version.id
        and s.journey_item_id = i.id
    );

  get diagnostics v_cleared = row_count;
  v_changed := v_updated + v_cleared;

  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    journey_item_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  ) values (
    v_version.organization_id,
    v_version.project_id,
    null,
    p_actor_user_id,
    'journey_schedule_plan_materialized',
    trim(p_change_reason),
    jsonb_build_object(
      'schedule_version_id', v_version.id,
      'version_number', v_version.version_number,
      'schedule_kind', v_version.schedule_kind,
      'projection_updated_rows', v_updated,
      'projection_cleared_rows', v_cleared,
      'projection_changed_rows', v_changed
    )
  );

  return v_changed;
end;
$$;

revoke all on function public.skpe_materialize_current_journey_plan_internal(uuid, uuid, text)
from public, anon, authenticated;
grant execute on function public.skpe_materialize_current_journey_plan_internal(uuid, uuid, text)
to service_role;;
