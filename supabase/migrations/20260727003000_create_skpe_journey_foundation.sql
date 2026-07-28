-- ============================================================
-- SK-PE SaaS
-- Migration: Fundacao da Jornada Estrategica Operacional
-- ============================================================

-- ============================================================
-- PERMISSOES DO MODULO SK-PE
-- ============================================================

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
    ('journey.view', 'Consultar jornada estrategica', 'Permite consultar projetos, macrofases e itens da jornada estrategica.'),
    ('journey.manage', 'Gerenciar jornada estrategica', 'Permite criar, alterar, ordenar e atualizar itens da jornada estrategica.')
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
    (mr.code in ('administrator', 'manager', 'editor') and mp.code in ('journey.view', 'journey.manage'))
    or
    (mr.code in ('approver', 'viewer') and mp.code = 'journey.view')
  )
on conflict do nothing;

-- ============================================================
-- PROJETOS ESTRATEGICOS
-- ============================================================

create table public.skpe_projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  status text not null default 'active',
  start_date date,
  target_end_date date,
  actual_end_date date,
  progress numeric(5,2) not null default 0,
  current_phase_code text,
  methodology_version text,
  configuration jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),
  archived_at timestamptz,

  constraint skpe_projects_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_projects_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_projects_status_check
    check (status in ('draft', 'active', 'suspended', 'completed', 'archived')),
  constraint skpe_projects_progress_check
    check (progress between 0 and 100),
  constraint skpe_projects_dates_check
    check (target_end_date is null or start_date is null or target_end_date >= start_date),
  constraint skpe_projects_unique
    unique (organization_id, code)
);

comment on table public.skpe_projects is
  'Projetos de planejamento estrategico vinculados a uma organizacao.';

create index idx_skpe_projects_organization
  on public.skpe_projects(organization_id);

create index idx_skpe_projects_status
  on public.skpe_projects(status);

create trigger skpe_projects_set_updated_at
before update on public.skpe_projects
for each row
execute function public.set_updated_at();

-- ============================================================
-- ITENS HIERARQUICOS DA JORNADA
-- ============================================================

create table public.skpe_journey_items (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  parent_item_id uuid
    references public.skpe_journey_items(id) on delete cascade,
  item_type text not null,
  code text not null,
  name text not null,
  description text,
  status text not null default 'not_started',
  progress numeric(5,2) not null default 0,
  display_order integer not null default 0,
  is_current boolean not null default false,
  is_mandatory boolean not null default true,
  responsible_user_id uuid references public.profiles(id),
  planned_start_date date,
  planned_end_date date,
  actual_start_date date,
  actual_end_date date,
  validation_required boolean not null default false,
  validation_status text not null default 'not_required',
  blocked boolean not null default false,
  blocking_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),
  archived_at timestamptz,

  constraint skpe_journey_items_type_check
    check (item_type in ('macrophase', 'phase', 'stage', 'activity', 'deliverable', 'gate')),
  constraint skpe_journey_items_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_journey_items_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_journey_items_status_check
    check (status in ('not_started', 'in_progress', 'blocked', 'pending_validation', 'completed', 'cancelled')),
  constraint skpe_journey_items_progress_check
    check (progress between 0 and 100),
  constraint skpe_journey_items_validation_status_check
    check (validation_status in ('not_required', 'pending', 'approved', 'approved_with_reservations', 'rejected')),
  constraint skpe_journey_items_dates_check
    check (planned_end_date is null or planned_start_date is null or planned_end_date >= planned_start_date),
  constraint skpe_journey_items_unique
    unique (project_id, code)
);

comment on table public.skpe_journey_items is
  'Estrutura hierarquica configuravel da jornada estrategica: macrofases, fases, etapas, atividades, entregaveis e gates.';

create index idx_skpe_journey_items_project
  on public.skpe_journey_items(project_id);

create index idx_skpe_journey_items_parent
  on public.skpe_journey_items(parent_item_id);

create index idx_skpe_journey_items_status
  on public.skpe_journey_items(status);

create index idx_skpe_journey_items_order
  on public.skpe_journey_items(project_id, display_order);

create trigger skpe_journey_items_set_updated_at
before update on public.skpe_journey_items
for each row
execute function public.set_updated_at();

-- ============================================================
-- AUDITORIA DA JORNADA
-- ============================================================

create table public.skpe_journey_audit (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid
    references public.skpe_projects(id) on delete cascade,
  journey_item_id uuid
    references public.skpe_journey_items(id) on delete set null,
  actor_user_id uuid not null
    references public.profiles(id) on delete restrict,
  action_code text not null,
  reason text,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz not null default timezone('utc', now()),

  constraint skpe_journey_audit_action_not_blank
    check (length(trim(action_code)) > 0)
);

create index idx_skpe_journey_audit_organization
  on public.skpe_journey_audit(organization_id);

create index idx_skpe_journey_audit_project
  on public.skpe_journey_audit(project_id);

create index idx_skpe_journey_audit_occurred_at
  on public.skpe_journey_audit(occurred_at desc);

-- ============================================================
-- AUTORIZACAO
-- ============================================================

create or replace function public.can_view_skpe_journey(
  target_organization_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE');
$$;

create or replace function public.can_manage_skpe_journey(
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
      'journey.manage'
    );
$$;

-- ============================================================
-- CONSULTA DA JORNADA
-- ============================================================

create or replace function public.get_skpe_journey(
  target_organization_id uuid
)
returns table (
  project_id uuid,
  project_code text,
  project_name text,
  project_status text,
  project_progress numeric,
  item_id uuid,
  parent_item_id uuid,
  item_type text,
  item_code text,
  item_name text,
  item_description text,
  item_status text,
  item_progress numeric,
  display_order integer,
  is_current boolean,
  responsible_user_id uuid,
  responsible_name text,
  planned_start_date date,
  planned_end_date date,
  validation_required boolean,
  validation_status text,
  blocked boolean,
  blocking_reason text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar a jornada estrategica desta organizacao.'
      using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.code,
    p.name,
    p.status,
    p.progress,
    i.id,
    i.parent_item_id,
    i.item_type,
    i.code,
    i.name,
    i.description,
    i.status,
    i.progress,
    i.display_order,
    i.is_current,
    i.responsible_user_id,
    coalesce(pr.display_name, pr.full_name, pr.email),
    i.planned_start_date,
    i.planned_end_date,
    i.validation_required,
    i.validation_status,
    i.blocked,
    i.blocking_reason
  from public.skpe_projects p
  join public.skpe_journey_items i
    on i.project_id = p.id
  left join public.profiles pr
    on pr.id = i.responsible_user_id
  where p.organization_id = target_organization_id
    and p.archived_at is null
    and i.archived_at is null
  order by p.created_at, i.display_order, i.code;
end;
$$;

-- ============================================================
-- ATUALIZACAO RAPIDA DE STATUS E PROGRESSO
-- ============================================================

create or replace function public.set_skpe_journey_item_status(
  target_item_id uuid,
  target_status text,
  target_progress numeric,
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_item public.skpe_journey_items%rowtype;
  target_project public.skpe_projects%rowtype;
begin
  select *
    into target_item
  from public.skpe_journey_items
  where id = target_item_id
  for update;

  if target_item.id is null then
    raise exception 'Item da jornada nao encontrado.';
  end if;

  select *
    into target_project
  from public.skpe_projects
  where id = target_item.project_id;

  if not public.can_manage_skpe_journey(target_project.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode alterar a jornada estrategica desta organizacao.'
      using errcode = '42501';
  end if;

  if target_status not in ('not_started', 'in_progress', 'blocked', 'pending_validation', 'completed', 'cancelled') then
    raise exception 'Status invalido para o item da jornada.';
  end if;

  if target_progress < 0 or target_progress > 100 then
    raise exception 'O progresso deve estar entre 0 e 100.';
  end if;

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  update public.skpe_journey_items
  set
    status = target_status,
    progress = target_progress,
    is_current = case when target_status = 'in_progress' then true else is_current end,
    actual_start_date = case
      when target_status = 'in_progress' and actual_start_date is null
        then current_date
      else actual_start_date
    end,
    actual_end_date = case
      when target_status = 'completed'
        then coalesce(actual_end_date, current_date)
      else actual_end_date
    end,
    updated_by = auth.uid()
  where id = target_item_id;

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
    target_project.organization_id,
    target_project.id,
    target_item.id,
    auth.uid(),
    'journey_item_status_changed',
    trim(change_reason),
    jsonb_build_object(
      'status', target_item.status,
      'progress', target_item.progress
    ),
    jsonb_build_object(
      'status', target_status,
      'progress', target_progress
    )
  );
end;
$$;

-- ============================================================
-- RLS
-- ============================================================

alter table public.skpe_projects enable row level security;
alter table public.skpe_journey_items enable row level security;
alter table public.skpe_journey_audit enable row level security;

create policy skpe_projects_select_authorized
on public.skpe_projects
for select
to authenticated
using (public.can_view_skpe_journey(organization_id));

create policy skpe_projects_manage_authorized
on public.skpe_projects
for all
to authenticated
using (public.can_manage_skpe_journey(organization_id))
with check (public.can_manage_skpe_journey(organization_id));

create policy skpe_journey_items_select_authorized
on public.skpe_journey_items
for select
to authenticated
using (
  exists (
    select 1
    from public.skpe_projects p
    where p.id = skpe_journey_items.project_id
      and public.can_view_skpe_journey(p.organization_id)
  )
);

create policy skpe_journey_items_manage_authorized
on public.skpe_journey_items
for all
to authenticated
using (
  exists (
    select 1
    from public.skpe_projects p
    where p.id = skpe_journey_items.project_id
      and public.can_manage_skpe_journey(p.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.skpe_projects p
    where p.id = skpe_journey_items.project_id
      and public.can_manage_skpe_journey(p.organization_id)
  )
);

create policy skpe_journey_audit_select_authorized
on public.skpe_journey_audit
for select
to authenticated
using (public.can_manage_skpe_journey(organization_id));

-- Auditoria inserida apenas por funcoes security definer.

-- ============================================================
-- PRIVILEGIOS
-- ============================================================

revoke all on table public.skpe_projects from anon;
revoke all on table public.skpe_journey_items from anon;
revoke all on table public.skpe_journey_audit from anon;

revoke all on function public.can_view_skpe_journey(uuid) from public, anon;
revoke all on function public.can_manage_skpe_journey(uuid) from public, anon;
revoke all on function public.get_skpe_journey(uuid) from public, anon;
revoke all on function public.set_skpe_journey_item_status(uuid, text, numeric, text) from public, anon;

grant execute on function public.can_view_skpe_journey(uuid) to authenticated, service_role;
grant execute on function public.can_manage_skpe_journey(uuid) to authenticated, service_role;
grant execute on function public.get_skpe_journey(uuid) to authenticated, service_role;
grant execute on function public.set_skpe_journey_item_status(uuid, text, numeric, text) to authenticated, service_role;

-- ============================================================
-- PROJETO INICIAL DA COOTAQUARA
-- ============================================================

insert into public.skpe_projects (
  organization_id,
  code,
  name,
  description,
  status,
  progress,
  current_phase_code,
  methodology_version
)
select
  o.id,
  'PE-COOTAQUARA-2026',
  'Planejamento Estrategico da COOTAQUARA',
  'Projeto de planejamento estrategico, formulacao, desdobramento, implementacao e monitoramento da COOTAQUARA.',
  'active',
  29,
  'PEM-02',
  'SK-PE Canonica 2026'
from public.organizations o
where o.code = 'COOTAQUARA'
on conflict (organization_id, code) do update
set
  name = excluded.name,
  description = excluded.description,
  status = excluded.status,
  progress = excluded.progress,
  current_phase_code = excluded.current_phase_code,
  methodology_version = excluded.methodology_version;

insert into public.skpe_journey_items (
  project_id,
  item_type,
  code,
  name,
  description,
  status,
  progress,
  display_order,
  is_current
)
select
  p.id,
  'macrophase',
  phase_data.code,
  phase_data.name,
  phase_data.description,
  phase_data.status,
  phase_data.progress,
  phase_data.display_order,
  phase_data.is_current
from public.skpe_projects p
join public.organizations o
  on o.id = p.organization_id
cross join (
  values
    ('PEM-01', 'Diagnostico e Entendimento Estrategico', 'Consolidacao das evidencias, contexto, riscos, oportunidades e temas criticos para decisao.', 'completed', 100::numeric, 10, false),
    ('PEM-02', 'Formulacao Estrategica', 'Construcao e validacao do direcionamento estrategico, objetivos, escolhas e modelo estrategico futuro.', 'in_progress', 45::numeric, 20, true),
    ('PEM-03', 'Desdobramento Estrategico', 'Conversao da estrategia em objetivos, indicadores, metas, iniciativas e responsabilidades.', 'not_started', 0::numeric, 30, false),
    ('PEM-04', 'Implementacao e Mobilizacao', 'Estruturacao da execucao, comunicacao, engajamento e desenvolvimento das capacidades necessarias.', 'not_started', 0::numeric, 40, false),
    ('PEM-05', 'Monitoramento e Aprendizado', 'Acompanhamento dos resultados, analise critica, aprendizado e atualizacao continua da estrategia.', 'not_started', 0::numeric, 50, false)
) as phase_data(code, name, description, status, progress, display_order, is_current)
where o.code = 'COOTAQUARA'
  and p.code = 'PE-COOTAQUARA-2026'
on conflict (project_id, code) do update
set
  name = excluded.name,
  description = excluded.description,
  status = excluded.status,
  progress = excluded.progress,
  display_order = excluded.display_order,
  is_current = excluded.is_current;
