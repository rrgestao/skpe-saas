-- ============================================================
-- SK-PE-CONT-01
-- 17-B.5B - Fundacao governada de Cronograma da Jornada
-- Baseline / Rebaseline / Forecast sem antecipar a aprovacao final.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Capabilities especificas
-- ------------------------------------------------------------
insert into public.module_permissions (
  module_id,
  code,
  name,
  description,
  permission_group,
  active
)
select
  m.id,
  permission_data.code,
  permission_data.name,
  permission_data.description,
  'journey',
  true
from public.modules m
cross join (
  values
    (
      'journey.schedule.manage',
      'Gerenciar cronograma da jornada',
      'Permite criar, editar, submeter, replanejar e manter previsoes operacionais do cronograma da Jornada SK-PE.'
    ),
    (
      'journey.schedule.approve',
      'Aprovar cronograma da jornada',
      'Permite decidir institucionalmente sobre baseline e rebaseline do cronograma da Jornada SK-PE.'
    )
) as permission_data(code, name, description)
where m.code = 'SK-PE'
on conflict (module_id, code) do update
set
  name = excluded.name,
  description = excluded.description,
  permission_group = excluded.permission_group,
  active = true;

insert into public.role_permissions (
  module_role_id,
  module_permission_id
)
select
  mr.id,
  mp.id
from public.module_roles mr
join public.modules m
  on m.id = mr.module_id
join public.module_permissions mp
  on mp.module_id = m.id
where m.code = 'SK-PE'
  and (
    (
      mr.code in ('administrator', 'manager', 'editor')
      and mp.code = 'journey.schedule.manage'
    )
    or
    (
      mr.code in ('administrator', 'approver')
      and mp.code = 'journey.schedule.approve'
    )
  )
on conflict do nothing;

create or replace function public.can_manage_skpe_journey_schedule(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_organization_admin(target_organization_id)
    or public.has_module_permission(
      target_organization_id,
      'SK-PE',
      'journey.schedule.manage'
    );
$$;

create or replace function public.can_approve_skpe_journey_schedule(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_organization_admin(target_organization_id)
    or public.has_module_permission(
      target_organization_id,
      'SK-PE',
      'journey.schedule.approve'
    );
$$;

-- ------------------------------------------------------------
-- 2. Versionamento do cronograma
-- ------------------------------------------------------------
create table public.skpe_journey_schedule_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  version_number integer not null,
  schedule_kind text not null,
  governance_status text not null default 'draft',
  title text not null,
  notes text,
  supersedes_version_id uuid
    references public.skpe_journey_schedule_versions(id) on delete restrict,
  is_current_plan boolean not null default false,
  is_current_forecast boolean not null default false,
  submitted_at timestamptz,
  submitted_by uuid references public.profiles(id),
  approved_at timestamptz,
  approved_by uuid references public.profiles(id),
  activated_at timestamptz,
  activated_by uuid references public.profiles(id),
  superseded_at timestamptz,
  superseded_by uuid references public.profiles(id),
  cancelled_at timestamptz,
  cancelled_by uuid references public.profiles(id),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),

  constraint skpe_journey_schedule_versions_kind_check
    check (schedule_kind in ('baseline', 'rebaseline', 'forecast')),
  constraint skpe_journey_schedule_versions_status_check
    check (governance_status in (
      'draft',
      'pending_approval',
      'approved',
      'active',
      'superseded',
      'cancelled'
    )),
  constraint skpe_journey_schedule_versions_number_check
    check (version_number > 0),
  constraint skpe_journey_schedule_versions_title_not_blank
    check (length(trim(title)) > 0),
  constraint skpe_journey_schedule_versions_unique
    unique (project_id, version_number),
  constraint skpe_journey_schedule_versions_current_plan_kind_check
    check (
      not is_current_plan
      or schedule_kind in ('baseline', 'rebaseline')
    ),
  constraint skpe_journey_schedule_versions_current_forecast_kind_check
    check (
      not is_current_forecast
      or schedule_kind = 'forecast'
    )
);

comment on table public.skpe_journey_schedule_versions is
  'Versoes governadas do cronograma da Jornada SK-PE. Baseline/rebaseline representam compromisso institucional; forecast representa previsao operacional e nao substitui o plano aprovado.';

create unique index ux_skpe_journey_schedule_current_plan
  on public.skpe_journey_schedule_versions(project_id)
  where is_current_plan;

create unique index ux_skpe_journey_schedule_current_forecast
  on public.skpe_journey_schedule_versions(project_id)
  where is_current_forecast;

create index ix_skpe_journey_schedule_versions_project
  on public.skpe_journey_schedule_versions(project_id, version_number desc);

create index ix_skpe_journey_schedule_versions_status
  on public.skpe_journey_schedule_versions(project_id, governance_status);

create trigger skpe_journey_schedule_versions_set_updated_at
before update on public.skpe_journey_schedule_versions
for each row
execute function public.set_updated_at();

create table public.skpe_journey_schedule_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  schedule_version_id uuid not null
    references public.skpe_journey_schedule_versions(id) on delete cascade,
  journey_item_id uuid not null
    references public.skpe_journey_items(id) on delete restrict,
  planned_start_date date,
  planned_end_date date,
  source_mode text not null default 'explicit',
  planning_note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),

  constraint skpe_journey_schedule_items_source_mode_check
    check (source_mode in ('explicit', 'derived')),
  constraint skpe_journey_schedule_items_has_date_check
    check (planned_start_date is not null or planned_end_date is not null),
  constraint skpe_journey_schedule_items_dates_check
    check (
      planned_end_date is null
      or planned_start_date is null
      or planned_end_date >= planned_start_date
    ),
  constraint skpe_journey_schedule_items_unique
    unique (schedule_version_id, journey_item_id)
);

comment on table public.skpe_journey_schedule_items is
  'Datas planejadas por item da Jornada em uma versao especifica do cronograma. source_mode explicita se a data foi informada diretamente ou derivada por roll-up.';

create index ix_skpe_journey_schedule_items_version
  on public.skpe_journey_schedule_items(schedule_version_id);

create index ix_skpe_journey_schedule_items_journey_item
  on public.skpe_journey_schedule_items(journey_item_id);

create trigger skpe_journey_schedule_items_set_updated_at
before update on public.skpe_journey_schedule_items
for each row
execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 3. Integridade contextual
-- ------------------------------------------------------------
create or replace function public.skpe_validate_journey_schedule_context()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_version public.skpe_journey_schedule_versions%rowtype;
  v_item public.skpe_journey_items%rowtype;
  v_project public.skpe_projects%rowtype;
begin
  select * into v_version
  from public.skpe_journey_schedule_versions
  where id = new.schedule_version_id;

  if v_version.id is null then
    raise exception 'Versao de cronograma nao encontrada.';
  end if;

  select * into v_item
  from public.skpe_journey_items
  where id = new.journey_item_id
    and archived_at is null;

  if v_item.id is null then
    raise exception 'Item ativo da Jornada nao encontrado.';
  end if;

  select * into v_project
  from public.skpe_projects
  where id = v_version.project_id
    and archived_at is null;

  if v_project.id is null then
    raise exception 'Projeto SK-PE ativo nao encontrado.';
  end if;

  if v_item.project_id <> v_version.project_id then
    raise exception 'Item da Jornada e versao de cronograma pertencem a projetos diferentes.';
  end if;

  if new.project_id <> v_version.project_id
     or new.organization_id <> v_version.organization_id then
    raise exception 'Contexto da linha de cronograma diverge da versao informada.';
  end if;

  if v_project.organization_id <> v_version.organization_id then
    raise exception 'Organizacao da versao de cronograma diverge do projeto.';
  end if;

  return new;
end;
$$;

create trigger skpe_validate_journey_schedule_context
before insert or update on public.skpe_journey_schedule_items
for each row
execute function public.skpe_validate_journey_schedule_context();

-- Impede que clientes autenticados sobrescrevam diretamente a projecao
-- temporal existente em skpe_journey_items. Funcoes SECURITY DEFINER
-- pertencentes ao owner continuam aptas a materializar a projecao quando
-- o gate de aprovacao for implementado.
create or replace function public.skpe_guard_direct_journey_planned_dates_write()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if current_user <> 'postgres' then
    raise exception
      'Datas planejadas da Jornada sao backend-authoritative e devem ser alteradas por operacao governada.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger skpe_guard_direct_journey_planned_dates_write
before update of planned_start_date, planned_end_date
on public.skpe_journey_items
for each row
when (
  old.planned_start_date is distinct from new.planned_start_date
  or old.planned_end_date is distinct from new.planned_end_date
)
execute function public.skpe_guard_direct_journey_planned_dates_write();

-- ------------------------------------------------------------
-- 4. Operacoes governadas de elaboracao
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
  v_superseded public.skpe_journey_schedule_versions%rowtype;
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

  if p_schedule_kind = 'baseline' and exists (
    select 1
    from public.skpe_journey_schedule_versions v
    where v.project_id = p_project_id
      and v.schedule_kind in ('baseline', 'rebaseline')
      and v.governance_status in ('pending_approval', 'approved')
  ) then
    raise exception 'Ja existe baseline/rebaseline em validacao ou aprovado para este projeto.';
  end if;

  if p_schedule_kind = 'rebaseline' then
    if p_supersedes_version_id is null then
      raise exception 'Rebaseline deve informar a versao de plano que pretende substituir.';
    end if;

    select * into v_superseded
    from public.skpe_journey_schedule_versions
    where id = p_supersedes_version_id
      and project_id = p_project_id;

    if v_superseded.id is null
       or v_superseded.schedule_kind not in ('baseline', 'rebaseline')
       or v_superseded.governance_status <> 'approved' then
      raise exception 'Rebaseline deve referenciar um plano aprovado do mesmo projeto.';
    end if;
  end if;

  if p_schedule_kind = 'forecast'
     and p_supersedes_version_id is not null then
    select * into v_superseded
    from public.skpe_journey_schedule_versions
    where id = p_supersedes_version_id
      and project_id = p_project_id;

    if v_superseded.id is null
       or v_superseded.schedule_kind <> 'forecast' then
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
    null,
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
  v_source_mode text := coalesce(p_source_mode, 'explicit');
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;

  if p_change_reason is null or length(trim(p_change_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.';
  end if;

  if p_planned_start_date is null and p_planned_end_date is null then
    raise exception 'Informe ao menos uma data planejada.';
  end if;

  if p_planned_start_date is not null
     and p_planned_end_date is not null
     and p_planned_end_date < p_planned_start_date then
    raise exception 'Data final planejada nao pode anteceder a data inicial.';
  end if;

  if v_source_mode not in ('explicit', 'derived') then
    raise exception 'Modo de origem temporal invalido.';
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
    v_source_mode,
    nullif(trim(coalesce(p_planning_note, '')), ''),
    auth.uid(),
    auth.uid()
  )
  on conflict (schedule_version_id, journey_item_id)
  do update set
    planned_start_date = excluded.planned_start_date,
    planned_end_date = excluded.planned_end_date,
    source_mode = excluded.source_mode,
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
      'source_mode', v_source_mode,
      'planning_note', nullif(trim(coalesce(p_planning_note, '')), '')
    )
  );

  return v_row_id;
end;
$$;

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

    if not exists (
      select 1
      from public.skpe_journey_schedule_items i
      where i.schedule_version_id = v_version.id
    ) then
      raise exception 'Nao e possivel submeter um cronograma sem itens planejados.';
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
      jsonb_build_object('governance_status', 'pending_approval')
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

  elsif p_action = 'activate_forecast' then
    if v_version.schedule_kind <> 'forecast'
       or v_version.governance_status <> 'draft' then
      raise exception 'Somente forecast em draft pode ser ativado.';
    end if;

    if not public.can_manage_skpe_journey_schedule(v_version.organization_id) then
      raise exception 'Acesso negado para ativar forecast.' using errcode = '42501';
    end if;

    if not exists (
      select 1
      from public.skpe_journey_schedule_items i
      where i.schedule_version_id = v_version.id
    ) then
      raise exception 'Nao e possivel ativar forecast sem itens planejados.';
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
        'is_current_forecast', true
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
    raise exception 'Acao de transicao nao suportada neste gate.';
  end if;
end;
$$;

-- ------------------------------------------------------------
-- 5. RLS / ACL
-- ------------------------------------------------------------
alter table public.skpe_journey_schedule_versions enable row level security;
alter table public.skpe_journey_schedule_items enable row level security;

create policy skpe_journey_schedule_versions_select_authorized
on public.skpe_journey_schedule_versions
for select
to authenticated
using (public.can_view_skpe_journey(organization_id));

create policy skpe_journey_schedule_items_select_authorized
on public.skpe_journey_schedule_items
for select
to authenticated
using (public.can_view_skpe_journey(organization_id));

revoke all on table public.skpe_journey_schedule_versions from public, anon, authenticated;
revoke all on table public.skpe_journey_schedule_items from public, anon, authenticated;

grant select on table public.skpe_journey_schedule_versions to authenticated;
grant select on table public.skpe_journey_schedule_items to authenticated;
grant all on table public.skpe_journey_schedule_versions to service_role;
grant all on table public.skpe_journey_schedule_items to service_role;

revoke all on function public.can_manage_skpe_journey_schedule(uuid) from public, anon;
revoke all on function public.can_approve_skpe_journey_schedule(uuid) from public, anon;
revoke all on function public.create_skpe_journey_schedule_version(uuid,text,text,text,uuid,text) from public, anon;
revoke all on function public.set_skpe_journey_schedule_item(uuid,uuid,date,date,text,text,text) from public, anon;
revoke all on function public.delete_skpe_journey_schedule_item(uuid,uuid,text) from public, anon;
revoke all on function public.transition_skpe_journey_schedule_version(uuid,text,text) from public, anon;

revoke all on function public.skpe_validate_journey_schedule_context() from public, anon, authenticated;
revoke all on function public.skpe_guard_direct_journey_planned_dates_write() from public, anon, authenticated;

grant execute on function public.can_manage_skpe_journey_schedule(uuid) to authenticated, service_role;
grant execute on function public.can_approve_skpe_journey_schedule(uuid) to authenticated, service_role;
grant execute on function public.create_skpe_journey_schedule_version(uuid,text,text,text,uuid,text) to authenticated, service_role;
grant execute on function public.set_skpe_journey_schedule_item(uuid,uuid,date,date,text,text,text) to authenticated, service_role;
grant execute on function public.delete_skpe_journey_schedule_item(uuid,uuid,text) to authenticated, service_role;
grant execute on function public.transition_skpe_journey_schedule_version(uuid,text,text) to authenticated, service_role;;
