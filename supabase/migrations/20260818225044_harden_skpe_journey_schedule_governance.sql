-- ============================================================
-- SK-PE-CONT-01
-- 17-B.5B - Hardening da governanca temporal da Jornada
-- ============================================================

-- ------------------------------------------------------------
-- 1. Invariantes de estado e concorrencia
-- ------------------------------------------------------------
alter table public.skpe_journey_schedule_versions
  add constraint skpe_journey_schedule_versions_kind_status_check
  check (
    (
      schedule_kind in ('baseline', 'rebaseline')
      and governance_status in (
        'draft',
        'pending_approval',
        'approved',
        'superseded',
        'cancelled'
      )
    )
    or
    (
      schedule_kind = 'forecast'
      and governance_status in (
        'draft',
        'active',
        'superseded',
        'cancelled'
      )
    )
  );

create unique index ux_skpe_journey_schedule_open_plan_proposal
  on public.skpe_journey_schedule_versions(project_id)
  where schedule_kind in ('baseline', 'rebaseline')
    and governance_status in ('draft', 'pending_approval');

-- ------------------------------------------------------------
-- 2. Contexto da versao e cadeia de sucessao
-- ------------------------------------------------------------
create or replace function public.skpe_validate_journey_schedule_version_context()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_source public.skpe_journey_schedule_versions%rowtype;
begin
  select * into v_project
  from public.skpe_projects
  where id = new.project_id
    and archived_at is null;

  if v_project.id is null then
    raise exception 'Projeto SK-PE ativo nao encontrado.';
  end if;

  if new.organization_id <> v_project.organization_id then
    raise exception 'Organizacao da versao de cronograma diverge do projeto.';
  end if;

  if new.schedule_kind = 'baseline' and new.supersedes_version_id is not null then
    raise exception 'Baseline inicial nao pode substituir outra versao.';
  end if;

  if new.schedule_kind = 'rebaseline' then
    if new.supersedes_version_id is null then
      raise exception 'Rebaseline deve referenciar o plano que pretende substituir.';
    end if;

    select * into v_source
    from public.skpe_journey_schedule_versions
    where id = new.supersedes_version_id;

    if v_source.id is null
       or v_source.project_id <> new.project_id
       or v_source.schedule_kind not in ('baseline', 'rebaseline') then
      raise exception 'Rebaseline deve suceder baseline/rebaseline do mesmo projeto.';
    end if;

    if new.governance_status in ('draft', 'pending_approval')
       and (
         v_source.governance_status <> 'approved'
         or not v_source.is_current_plan
       ) then
      raise exception 'Rebaseline em elaboracao deve suceder o plano aprovado e corrente.';
    end if;
  end if;

  if new.schedule_kind = 'forecast' and new.supersedes_version_id is not null then
    select * into v_source
    from public.skpe_journey_schedule_versions
    where id = new.supersedes_version_id;

    if v_source.id is null
       or v_source.project_id <> new.project_id
       or v_source.schedule_kind <> 'forecast' then
      raise exception 'Forecast so pode suceder outro forecast do mesmo projeto.';
    end if;
  end if;

  return new;
end;
$$;

create trigger skpe_validate_journey_schedule_version_context
before insert or update
on public.skpe_journey_schedule_versions
for each row
execute function public.skpe_validate_journey_schedule_version_context();

revoke all on function public.skpe_validate_journey_schedule_version_context()
from public, anon, authenticated;

-- ------------------------------------------------------------
-- 3. Roll-up temporal interno
-- Pais com filhos ativos sao derivados; folhas sao planejadas explicitamente.
-- ------------------------------------------------------------
create or replace function public.skpe_rollup_journey_schedule_internal(
  p_schedule_version_id uuid,
  p_actor_user_id uuid
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_version public.skpe_journey_schedule_versions%rowtype;
  v_parent record;
  v_start date;
  v_end date;
  v_count integer := 0;
begin
  if p_actor_user_id is null then
    raise exception 'Usuario responsavel pelo roll-up nao informado.';
  end if;

  select * into v_version
  from public.skpe_journey_schedule_versions
  where id = p_schedule_version_id
  for update;

  if v_version.id is null then
    raise exception 'Versao de cronograma nao encontrada.';
  end if;

  delete from public.skpe_journey_schedule_items s
  where s.schedule_version_id = v_version.id
    and s.source_mode = 'derived';

  for v_parent in
    with recursive hierarchy as (
      select i.id, i.parent_item_id, 0 as depth
      from public.skpe_journey_items i
      where i.project_id = v_version.project_id
        and i.parent_item_id is null
        and i.archived_at is null
      union all
      select c.id, c.parent_item_id, h.depth + 1
      from public.skpe_journey_items c
      join hierarchy h on h.id = c.parent_item_id
      where c.project_id = v_version.project_id
        and c.archived_at is null
    )
    select i.id, h.depth
    from public.skpe_journey_items i
    join hierarchy h on h.id = i.id
    where i.project_id = v_version.project_id
      and i.archived_at is null
      and exists (
        select 1
        from public.skpe_journey_items c
        where c.parent_item_id = i.id
          and c.archived_at is null
          and c.status <> 'cancelled'
      )
    order by h.depth desc, i.id
  loop
    select
      min(coalesce(s.planned_start_date, s.planned_end_date)),
      max(coalesce(s.planned_end_date, s.planned_start_date))
    into v_start, v_end
    from public.skpe_journey_items c
    join public.skpe_journey_schedule_items s
      on s.journey_item_id = c.id
     and s.schedule_version_id = v_version.id
    where c.parent_item_id = v_parent.id
      and c.archived_at is null
      and c.status <> 'cancelled';

    if v_start is null and v_end is null then
      continue;
    end if;

    insert into public.skpe_journey_schedule_items (
      organization_id,
      project_id,
      schedule_version_id,
      journey_item_id,
      planned_start_date,
      planned_end_date,
      source_mode,
      planning_note,
      created_by,
      updated_by
    ) values (
      v_version.organization_id,
      v_version.project_id,
      v_version.id,
      v_parent.id,
      v_start,
      v_end,
      'derived',
      'Periodo derivado por roll-up dos filhos ativos.',
      p_actor_user_id,
      p_actor_user_id
    )
    on conflict (schedule_version_id, journey_item_id)
    do update set
      planned_start_date = excluded.planned_start_date,
      planned_end_date = excluded.planned_end_date,
      source_mode = 'derived',
      planning_note = excluded.planning_note,
      updated_by = p_actor_user_id;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke all on function public.skpe_rollup_journey_schedule_internal(uuid, uuid)
from public, anon, authenticated;
grant execute on function public.skpe_rollup_journey_schedule_internal(uuid, uuid)
to service_role;

-- ------------------------------------------------------------
-- 4. Readiness temporal backend-authoritative
-- Gate/entregavel folha funcionam como marcos: fim planejado obrigatorio.
-- Demais folhas obrigatorias exigem inicio e fim.
-- ------------------------------------------------------------
create or replace function public.get_skpe_journey_schedule_readiness(
  p_schedule_version_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_version public.skpe_journey_schedule_versions%rowtype;
  v_total integer;
  v_ready integer;
  v_missing jsonb;
begin
  select * into v_version
  from public.skpe_journey_schedule_versions
  where id = p_schedule_version_id;

  if v_version.id is null then
    raise exception 'Versao de cronograma nao encontrada.';
  end if;

  if not public.can_view_skpe_journey(v_version.organization_id) then
    raise exception 'Acesso negado ao cronograma da Jornada.' using errcode = '42501';
  end if;

  with mandatory_leaves as (
    select i.*
    from public.skpe_journey_items i
    where i.project_id = v_version.project_id
      and i.archived_at is null
      and i.is_mandatory
      and i.status <> 'cancelled'
      and not exists (
        select 1
        from public.skpe_journey_items c
        where c.parent_item_id = i.id
          and c.archived_at is null
          and c.status <> 'cancelled'
      )
  ), evaluated as (
    select
      i.id,
      i.code,
      i.name,
      i.item_type,
      s.planned_start_date,
      s.planned_end_date,
      case
        when i.item_type in ('gate', 'deliverable')
          then s.planned_end_date is not null
        else
          s.planned_start_date is not null
          and s.planned_end_date is not null
      end as is_ready
    from mandatory_leaves i
    left join public.skpe_journey_schedule_items s
      on s.schedule_version_id = v_version.id
     and s.journey_item_id = i.id
  )
  select
    count(*),
    count(*) filter (where is_ready),
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'itemId', id,
          'code', code,
          'name', name,
          'itemType', item_type,
          'plannedStartDate', planned_start_date,
          'plannedEndDate', planned_end_date
        ) order by code
      ) filter (where not is_ready),
      '[]'::jsonb
    )
  into v_total, v_ready, v_missing
  from evaluated;

  return jsonb_build_object(
    'scheduleVersionId', v_version.id,
    'projectId', v_version.project_id,
    'scheduleKind', v_version.schedule_kind,
    'governanceStatus', v_version.governance_status,
    'mandatoryLeafCount', coalesce(v_total, 0),
    'readyMandatoryLeafCount', coalesce(v_ready, 0),
    'missingMandatoryLeafCount', greatest(coalesce(v_total, 0) - coalesce(v_ready, 0), 0),
    'missingItems', coalesce(v_missing, '[]'::jsonb),
    'readyToSubmit', coalesce(v_total, 0) > 0 and coalesce(v_total, 0) = coalesce(v_ready, 0)
  );
end;
$$;

revoke all on function public.get_skpe_journey_schedule_readiness(uuid)
from public, anon;
grant execute on function public.get_skpe_journey_schedule_readiness(uuid)
to authenticated, service_role;

-- ------------------------------------------------------------
-- 5. Materializacao interna da projecao do plano vigente
-- ------------------------------------------------------------
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

  get diagnostics v_changed = row_count;

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

  v_changed := v_changed + found::integer;

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
      'projection_changed_rows', v_changed
    )
  );

  return v_changed;
end;
$$;

revoke all on function public.skpe_materialize_current_journey_plan_internal(uuid, uuid, text)
from public, anon, authenticated;
grant execute on function public.skpe_materialize_current_journey_plan_internal(uuid, uuid, text)
to service_role;

-- ------------------------------------------------------------
-- 6. Criacao endurecida: lock por projeto e clone de rebaseline
-- ------------------------------------------------------------
create or replace function public.create_skpe_journey_schedule_version(
  p_project_id uuid,
  p_schedule_kind text,
  p_title text,
  p_notes text,
  p_supersedes_version_id uuid,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project public.skpe_projects%rowtype;
  v_source public.skpe_journey_schedule_versions%rowtype;
  v_version_number integer;
  v_version_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;

  if p_change_reason is null or length(trim(p_change_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.';
  end if;

  if p_schedule_kind not in ('baseline', 'rebaseline', 'forecast') then
    raise exception 'Tipo de cronograma invalido.';
  end if;

  if p_title is null or length(trim(p_title)) = 0 then
    raise exception 'Informe um titulo para a versao do cronograma.';
  end if;

  select * into v_project
  from public.skpe_projects
  where id = p_project_id
    and archived_at is null
  for update;

  if v_project.id is null then
    raise exception 'Projeto SK-PE ativo nao encontrado.';
  end if;

  if not public.can_manage_skpe_journey_schedule(v_project.organization_id) then
    raise exception 'Acesso negado para gerenciar o cronograma da Jornada.'
      using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('skpe_journey_schedule:' || v_project.id::text, 0)
  );

  if p_schedule_kind = 'baseline' then
    if p_supersedes_version_id is not null then
      raise exception 'Baseline inicial nao pode substituir outra versao.';
    end if;

    if exists (
      select 1
      from public.skpe_journey_schedule_versions v
      where v.project_id = p_project_id
        and v.schedule_kind in ('baseline', 'rebaseline')
        and v.governance_status in ('draft', 'pending_approval', 'approved')
    ) then
      raise exception 'Ja existe proposta ou plano temporal vigente para este projeto.';
    end if;
  end if;

  if p_schedule_kind = 'rebaseline' then
    if p_supersedes_version_id is null then
      raise exception 'Rebaseline deve informar o plano aprovado que pretende substituir.';
    end if;

    select * into v_source
    from public.skpe_journey_schedule_versions
    where id = p_supersedes_version_id
      and project_id = p_project_id
    for update;

    if v_source.id is null
       or v_source.schedule_kind not in ('baseline', 'rebaseline')
       or v_source.governance_status <> 'approved'
       or not v_source.is_current_plan then
      raise exception 'Rebaseline deve suceder o plano aprovado e corrente do mesmo projeto.';
    end if;
  end if;

  if p_schedule_kind = 'forecast' and p_supersedes_version_id is not null then
    select * into v_source
    from public.skpe_journey_schedule_versions
    where id = p_supersedes_version_id
      and project_id = p_project_id;

    if v_source.id is null or v_source.schedule_kind <> 'forecast' then
      raise exception 'Forecast so pode suceder outro forecast do mesmo projeto.';
    end if;
  end if;

  select coalesce(max(version_number), 0) + 1
  into v_version_number
  from public.skpe_journey_schedule_versions
  where project_id = p_project_id;

  insert into public.skpe_journey_schedule_versions (
    organization_id,
    project_id,
    version_number,
    schedule_kind,
    governance_status,
    title,
    notes,
    supersedes_version_id,
    created_by,
    updated_by
  ) values (
    v_project.organization_id,
    v_project.id,
    v_version_number,
    p_schedule_kind,
    'draft',
    trim(p_title),
    nullif(trim(coalesce(p_notes, '')), ''),
    p_supersedes_version_id,
    auth.uid(),
    auth.uid()
  )
  returning id into v_version_id;

  if p_schedule_kind = 'rebaseline' then
    insert into public.skpe_journey_schedule_items (
      organization_id,
      project_id,
      schedule_version_id,
      journey_item_id,
      planned_start_date,
      planned_end_date,
      source_mode,
      planning_note,
      metadata,
      created_by,
      updated_by
    )
    select
      v_project.organization_id,
      v_project.id,
      v_version_id,
      s.journey_item_id,
      s.planned_start_date,
      s.planned_end_date,
      'explicit',
      s.planning_note,
      s.metadata || jsonb_build_object('cloned_from_schedule_version_id', v_source.id),
      auth.uid(),
      auth.uid()
    from public.skpe_journey_schedule_items s
    join public.skpe_journey_items i on i.id = s.journey_item_id
    where s.schedule_version_id = v_source.id
      and s.source_mode = 'explicit'
      and i.archived_at is null;
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
  ) values (
    v_project.organization_id,
    v_project.id,
    null,
    auth.uid(),
    'journey_schedule_version_created',
    trim(p_change_reason),
    case
      when v_source.id is null then null
      else jsonb_build_object('source_schedule_version_id', v_source.id)
    end,
    jsonb_build_object(
      'schedule_version_id', v_version_id,
      'version_number', v_version_number,
      'schedule_kind', p_schedule_kind,
      'governance_status', 'draft',
      'supersedes_version_id', p_supersedes_version_id
    )
  );

  return v_version_id;
end;
$$;

-- ------------------------------------------------------------
-- 7. Edicao endurecida: somente folhas e somente origem explicita
-- ------------------------------------------------------------
create or replace function public.set_skpe_journey_schedule_item(
  p_schedule_version_id uuid,
  p_journey_item_id uuid,
  p_planned_start_date date,
  p_planned_end_date date,
  p_source_mode text,
  p_planning_note text,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_version public.skpe_journey_schedule_versions%rowtype;
  v_item public.skpe_journey_items%rowtype;
  v_existing public.skpe_journey_schedule_items%rowtype;
  v_row_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;

  if p_change_reason is null or length(trim(p_change_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.';
  end if;

  if coalesce(p_source_mode, 'explicit') <> 'explicit' then
    raise exception 'Itens derivados sao calculados pelo backend e nao podem ser informados pelo cliente.';
  end if;

  if p_planned_start_date is null and p_planned_end_date is null then
    raise exception 'Informe ao menos uma data planejada.';
  end if;

  if p_planned_start_date is not null
     and p_planned_end_date is not null
     and p_planned_end_date < p_planned_start_date then
    raise exception 'Data final planejada nao pode anteceder a data inicial.';
  end if;

  select * into v_version
  from public.skpe_journey_schedule_versions
  where id = p_schedule_version_id
  for update;

  if v_version.id is null then
    raise exception 'Versao de cronograma nao encontrada.';
  end if;

  if v_version.governance_status <> 'draft' then
    raise exception 'Somente versoes draft podem ter datas editadas.';
  end if;

  if not public.can_manage_skpe_journey_schedule(v_version.organization_id) then
    raise exception 'Acesso negado para gerenciar o cronograma da Jornada.'
      using errcode = '42501';
  end if;

  select * into v_item
  from public.skpe_journey_items
  where id = p_journey_item_id
    and project_id = v_version.project_id
    and archived_at is null;

  if v_item.id is null then
    raise exception 'Item ativo da Jornada nao pertence ao projeto do cronograma.';
  end if;

  if exists (
    select 1
    from public.skpe_journey_items c
    where c.parent_item_id = v_item.id
      and c.archived_at is null
      and c.status <> 'cancelled'
  ) then
    raise exception 'Datas de itens agregadores sao derivadas automaticamente dos filhos ativos.';
  end if;

  select * into v_existing
  from public.skpe_journey_schedule_items
  where schedule_version_id = v_version.id
    and journey_item_id = v_item.id
  for update;

  insert into public.skpe_journey_schedule_items (
    organization_id,
    project_id,
    schedule_version_id,
    journey_item_id,
    planned_start_date,
    planned_end_date,
    source_mode,
    planning_note,
    created_by,
    updated_by
  ) values (
    v_version.organization_id,
    v_version.project_id,
    v_version.id,
    v_item.id,
    p_planned_start_date,
    p_planned_end_date,
    'explicit',
    nullif(trim(coalesce(p_planning_note, '')), ''),
    auth.uid(),
    auth.uid()
  )
  on conflict (schedule_version_id, journey_item_id)
  do update set
    planned_start_date = excluded.planned_start_date,
    planned_end_date = excluded.planned_end_date,
    source_mode = 'explicit',
    planning_note = excluded.planning_note,
    updated_by = auth.uid()
  returning id into v_row_id;

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
    v_item.id,
    auth.uid(),
    'journey_schedule_item_changed',
    trim(p_change_reason),
    case
      when v_existing.id is null then null
      else jsonb_build_object(
        'schedule_version_id', v_existing.schedule_version_id,
        'planned_start_date', v_existing.planned_start_date,
        'planned_end_date', v_existing.planned_end_date,
        'source_mode', v_existing.source_mode,
        'planning_note', v_existing.planning_note
      )
    end,
    jsonb_build_object(
      'schedule_version_id', v_version.id,
      'planned_start_date', p_planned_start_date,
      'planned_end_date', p_planned_end_date,
      'source_mode', 'explicit',
      'planning_note', nullif(trim(coalesce(p_planning_note, '')), '')
    )
  );

  return v_row_id;
end;
$$;

-- ------------------------------------------------------------
-- 8. Transicao governada com readiness e aprovacao institucional
-- ------------------------------------------------------------
create or replace function public.transition_skpe_journey_schedule_version(
  p_schedule_version_id uuid,
  p_action text,
  p_change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_version public.skpe_journey_schedule_versions%rowtype;
  v_previous jsonb;
  v_readiness jsonb;
  v_previous_plan public.skpe_journey_schedule_versions%rowtype;
  v_derived integer := 0;
  v_materialized integer := 0;
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

  perform pg_advisory_xact_lock(
    hashtextextended('skpe_journey_schedule:' || v_version.project_id::text, 0)
  );

  v_previous := jsonb_build_object(
    'governance_status', v_version.governance_status,
    'is_current_plan', v_version.is_current_plan,
    'is_current_forecast', v_version.is_current_forecast
  );

  if p_action = 'submit' then
    if v_version.schedule_kind not in ('baseline', 'rebaseline')
       or v_version.governance_status <> 'draft' then
      raise exception 'Somente baseline/rebaseline em draft pode ser submetido.';
    end if;

    if not public.can_manage_skpe_journey_schedule(v_version.organization_id) then
      raise exception 'Acesso negado para submeter o cronograma.' using errcode = '42501';
    end if;

    v_derived := public.skpe_rollup_journey_schedule_internal(v_version.id, auth.uid());
    v_readiness := public.get_skpe_journey_schedule_readiness(v_version.id);

    if not coalesce((v_readiness ->> 'readyToSubmit')::boolean, false) then
      raise exception 'Cronograma possui folhas obrigatorias sem planejamento temporal completo.'
        using errcode = '55000', detail = v_readiness::text;
    end if;

    update public.skpe_journey_schedule_versions
    set governance_status = 'pending_approval',
        submitted_at = timezone('utc', now()),
        submitted_by = auth.uid(),
        updated_by = auth.uid()
    where id = v_version.id;

    insert into public.skpe_journey_audit (
      organization_id, project_id, journey_item_id, actor_user_id,
      action_code, reason, previous_data, new_data
    ) values (
      v_version.organization_id, v_version.project_id, null, auth.uid(),
      'journey_schedule_submitted', trim(p_change_reason), v_previous,
      jsonb_build_object(
        'governance_status', 'pending_approval',
        'derived_items', v_derived,
        'readiness', v_readiness
      )
    );

  elsif p_action = 'return_for_adjustment' then
    if v_version.schedule_kind not in ('baseline', 'rebaseline')
       or v_version.governance_status <> 'pending_approval' then
      raise exception 'Somente baseline/rebaseline pendente pode retornar para ajuste.';
    end if;

    if not public.can_approve_skpe_journey_schedule(v_version.organization_id) then
      raise exception 'Acesso negado para devolver o cronograma para ajuste.' using errcode = '42501';
    end if;

    update public.skpe_journey_schedule_versions
    set governance_status = 'draft',
        submitted_at = null,
        submitted_by = null,
        updated_by = auth.uid()
    where id = v_version.id;

    insert into public.skpe_journey_audit (
      organization_id, project_id, journey_item_id, actor_user_id,
      action_code, reason, previous_data, new_data
    ) values (
      v_version.organization_id, v_version.project_id, null, auth.uid(),
      'journey_schedule_returned_for_adjustment', trim(p_change_reason), v_previous,
      jsonb_build_object('governance_status', 'draft')
    );

  elsif p_action = 'approve' then
    if v_version.schedule_kind not in ('baseline', 'rebaseline')
       or v_version.governance_status <> 'pending_approval' then
      raise exception 'Somente baseline/rebaseline pendente pode ser aprovado.';
    end if;

    if not public.can_approve_skpe_journey_schedule(v_version.organization_id) then
      raise exception 'Acesso negado para aprovar o cronograma.' using errcode = '42501';
    end if;

    v_derived := public.skpe_rollup_journey_schedule_internal(v_version.id, auth.uid());
    v_readiness := public.get_skpe_journey_schedule_readiness(v_version.id);

    if not coalesce((v_readiness ->> 'readyToSubmit')::boolean, false) then
      raise exception 'Cronograma deixou de atender aos requisitos temporais para aprovacao.'
        using errcode = '55000', detail = v_readiness::text;
    end if;

    select * into v_previous_plan
    from public.skpe_journey_schedule_versions
    where project_id = v_version.project_id
      and is_current_plan
    for update;

    if v_version.schedule_kind = 'baseline' and v_previous_plan.id is not null then
      raise exception 'Baseline inicial nao pode ser aprovado porque ja existe plano temporal corrente.';
    end if;

    if v_version.schedule_kind = 'rebaseline'
       and (
         v_previous_plan.id is null
         or v_previous_plan.id <> v_version.supersedes_version_id
         or v_previous_plan.governance_status <> 'approved'
       ) then
      raise exception 'Rebaseline deve substituir exatamente o plano aprovado e corrente.';
    end if;

    if v_previous_plan.id is not null then
      update public.skpe_journey_schedule_versions
      set governance_status = 'superseded',
          is_current_plan = false,
          superseded_at = timezone('utc', now()),
          superseded_by = auth.uid(),
          updated_by = auth.uid()
      where id = v_previous_plan.id;
    end if;

    update public.skpe_journey_schedule_versions
    set governance_status = 'approved',
        is_current_plan = true,
        approved_at = timezone('utc', now()),
        approved_by = auth.uid(),
        activated_at = timezone('utc', now()),
        activated_by = auth.uid(),
        updated_by = auth.uid()
    where id = v_version.id;

    v_materialized := public.skpe_materialize_current_journey_plan_internal(
      v_version.id,
      auth.uid(),
      p_change_reason
    );

    insert into public.skpe_journey_audit (
      organization_id, project_id, journey_item_id, actor_user_id,
      action_code, reason, previous_data, new_data
    ) values (
      v_version.organization_id, v_version.project_id, null, auth.uid(),
      'journey_schedule_approved', trim(p_change_reason), v_previous,
      jsonb_build_object(
        'governance_status', 'approved',
        'is_current_plan', true,
        'superseded_schedule_version_id', v_previous_plan.id,
        'derived_items', v_derived,
        'materialized_projection_rows', v_materialized,
        'readiness', v_readiness
      )
    );

  elsif p_action = 'activate_forecast' then
    if v_version.schedule_kind <> 'forecast'
       or v_version.governance_status <> 'draft' then
      raise exception 'Somente forecast em draft pode ser ativado.';
    end if;

    if not public.can_manage_skpe_journey_schedule(v_version.organization_id) then
      raise exception 'Acesso negado para ativar forecast.' using errcode = '42501';
    end if;

    v_derived := public.skpe_rollup_journey_schedule_internal(v_version.id, auth.uid());
    v_readiness := public.get_skpe_journey_schedule_readiness(v_version.id);

    if not coalesce((v_readiness ->> 'readyToSubmit')::boolean, false) then
      raise exception 'Forecast possui folhas obrigatorias sem previsao temporal completa.'
        using errcode = '55000', detail = v_readiness::text;
    end if;

    update public.skpe_journey_schedule_versions
    set governance_status = 'superseded',
        is_current_forecast = false,
        superseded_at = timezone('utc', now()),
        superseded_by = auth.uid(),
        updated_by = auth.uid()
    where project_id = v_version.project_id
      and is_current_forecast
      and id <> v_version.id;

    update public.skpe_journey_schedule_versions
    set governance_status = 'active',
        is_current_forecast = true,
        activated_at = timezone('utc', now()),
        activated_by = auth.uid(),
        updated_by = auth.uid()
    where id = v_version.id;

    insert into public.skpe_journey_audit (
      organization_id, project_id, journey_item_id, actor_user_id,
      action_code, reason, previous_data, new_data
    ) values (
      v_version.organization_id, v_version.project_id, null, auth.uid(),
      'journey_schedule_forecast_activated', trim(p_change_reason), v_previous,
      jsonb_build_object(
        'governance_status', 'active',
        'is_current_forecast', true,
        'derived_items', v_derived,
        'readiness', v_readiness
      )
    );

  elsif p_action = 'cancel' then
    if v_version.governance_status not in ('draft', 'pending_approval') then
      raise exception 'Somente versao draft ou pendente pode ser cancelada neste gate.';
    end if;

    if not public.can_manage_skpe_journey_schedule(v_version.organization_id)
       and not public.can_approve_skpe_journey_schedule(v_version.organization_id) then
      raise exception 'Acesso negado para cancelar a versao do cronograma.' using errcode = '42501';
    end if;

    update public.skpe_journey_schedule_versions
    set governance_status = 'cancelled',
        cancelled_at = timezone('utc', now()),
        cancelled_by = auth.uid(),
        updated_by = auth.uid()
    where id = v_version.id;

    insert into public.skpe_journey_audit (
      organization_id, project_id, journey_item_id, actor_user_id,
      action_code, reason, previous_data, new_data
    ) values (
      v_version.organization_id, v_version.project_id, null, auth.uid(),
      'journey_schedule_cancelled', trim(p_change_reason), v_previous,
      jsonb_build_object('governance_status', 'cancelled')
    );

  else
    raise exception 'Acao de transicao nao suportada.';
  end if;
end;
$$;

-- Reafirma ACL publica das operacoes alteradas/novas.
revoke all on function public.create_skpe_journey_schedule_version(uuid,text,text,text,uuid,text)
from public, anon;
revoke all on function public.set_skpe_journey_schedule_item(uuid,uuid,date,date,text,text,text)
from public, anon;
revoke all on function public.transition_skpe_journey_schedule_version(uuid,text,text)
from public, anon;

grant execute on function public.create_skpe_journey_schedule_version(uuid,text,text,text,uuid,text)
to authenticated, service_role;
grant execute on function public.set_skpe_journey_schedule_item(uuid,uuid,date,date,text,text,text)
to authenticated, service_role;
grant execute on function public.transition_skpe_journey_schedule_version(uuid,text,text)
to authenticated, service_role;;
