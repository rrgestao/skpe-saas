-- ============================================================
-- SK-PE-CONT-01
-- 17-B.5B - Itens derivados pertencem exclusivamente ao backend
-- ============================================================

create or replace function public.delete_skpe_journey_schedule_item(
  p_schedule_version_id uuid,
  p_journey_item_id uuid,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_version public.skpe_journey_schedule_versions%rowtype;
  v_existing public.skpe_journey_schedule_items%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;

  if p_change_reason is null or length(trim(p_change_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.';
  end if;

  select * into v_version
  from public.skpe_journey_schedule_versions
  where id = p_schedule_version_id
  for update;

  if v_version.id is null then
    raise exception 'Versao de cronograma nao encontrada.';
  end if;

  if v_version.governance_status <> 'draft' then
    raise exception 'Somente versoes draft podem ter datas removidas.';
  end if;

  if not public.can_manage_skpe_journey_schedule(v_version.organization_id) then
    raise exception 'Acesso negado para gerenciar o cronograma da Jornada.'
      using errcode = '42501';
  end if;

  select * into v_existing
  from public.skpe_journey_schedule_items
  where schedule_version_id = v_version.id
    and journey_item_id = p_journey_item_id
  for update;

  if v_existing.id is null then
    raise exception 'Item de cronograma nao encontrado.';
  end if;

  if v_existing.source_mode <> 'explicit' then
    raise exception 'Itens temporais derivados sao backend-authoritative e nao podem ser removidos diretamente.'
      using errcode = '42501';
  end if;

  delete from public.skpe_journey_schedule_items
  where id = v_existing.id;

  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    journey_item_id,
    actor_user_id,
    action_code,
    reason,
    previous_data,
    new_data
  ) values (
    v_version.organization_id,
    v_version.project_id,
    p_journey_item_id,
    auth.uid(),
    'journey_schedule_item_removed',
    trim(p_change_reason),
    jsonb_build_object(
      'schedule_version_id', v_existing.schedule_version_id,
      'planned_start_date', v_existing.planned_start_date,
      'planned_end_date', v_existing.planned_end_date,
      'source_mode', v_existing.source_mode,
      'planning_note', v_existing.planning_note
    ),
    null
  );
end;
$$;

revoke all on function public.delete_skpe_journey_schedule_item(uuid,uuid,text)
from public, anon;
grant execute on function public.delete_skpe_journey_schedule_item(uuid,uuid,text)
to authenticated, service_role;;
