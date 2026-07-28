-- ============================================================
-- SK-PE SaaS
-- Migration: Business Model Canvas para Projetos
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
  'project_canvas',
  true
from public.modules m
cross join (
  values
    ('project_canvas.view', 'Consultar Canvas do Projeto', 'Permite consultar o Business Model Canvas vinculado a projetos estrategicos.'),
    ('project_canvas.manage', 'Gerenciar Canvas do Projeto', 'Permite criar, editar, ordenar e atualizar blocos e itens do Canvas do Projeto.')
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
    (mr.code in ('administrator', 'manager', 'editor') and mp.code in ('project_canvas.view', 'project_canvas.manage'))
    or
    (mr.code in ('approver', 'viewer') and mp.code = 'project_canvas.view')
  )
on conflict do nothing;

-- ============================================================
-- CANVAS DO PROJETO
-- ============================================================

create table public.skpe_project_canvases (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  code text not null default 'PROJECT-BMC',
  name text not null default 'Business Model Canvas do Projeto',
  description text,
  status text not null default 'draft',
  version_number integer not null default 1,
  is_current boolean not null default true,
  template_code text not null default 'SKPE-PROJECT-BMC-2026.1',
  configuration jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),
  archived_at timestamptz,

  constraint skpe_project_canvases_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_project_canvases_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_project_canvases_status_check
    check (status in ('draft', 'in_review', 'approved', 'archived')),
  constraint skpe_project_canvases_version_check
    check (version_number > 0),
  constraint skpe_project_canvases_unique_version
    unique (project_id, version_number)
);

comment on table public.skpe_project_canvases is
  'Business Model Canvas complementar vinculado a cada projeto estrategico.';

create unique index skpe_project_canvases_one_current
  on public.skpe_project_canvases(project_id)
  where is_current = true and archived_at is null;

create index idx_skpe_project_canvases_organization
  on public.skpe_project_canvases(organization_id);

create index idx_skpe_project_canvases_project
  on public.skpe_project_canvases(project_id);

create trigger skpe_project_canvases_set_updated_at
before update on public.skpe_project_canvases
for each row
execute function public.set_updated_at();

-- ============================================================
-- BLOCOS DO CANVAS
-- ============================================================

create table public.skpe_project_canvas_blocks (
  id uuid primary key default gen_random_uuid(),
  canvas_id uuid not null
    references public.skpe_project_canvases(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  guidance text,
  display_order integer not null default 0,
  grid_area text,
  is_mandatory boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),

  constraint skpe_project_canvas_blocks_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_project_canvas_blocks_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_project_canvas_blocks_unique
    unique (canvas_id, code)
);

comment on table public.skpe_project_canvas_blocks is
  'Blocos estruturantes do Business Model Canvas do Projeto.';

create index idx_skpe_project_canvas_blocks_canvas
  on public.skpe_project_canvas_blocks(canvas_id, display_order);

create trigger skpe_project_canvas_blocks_set_updated_at
before update on public.skpe_project_canvas_blocks
for each row
execute function public.set_updated_at();

-- ============================================================
-- ITENS DOS BLOCOS
-- ============================================================

create table public.skpe_project_canvas_items (
  id uuid primary key default gen_random_uuid(),
  block_id uuid not null
    references public.skpe_project_canvas_blocks(id) on delete cascade,
  content text not null,
  description text,
  status text not null default 'active',
  priority text not null default 'medium',
  display_order integer not null default 0,
  linked_journey_item_id uuid
    references public.skpe_journey_items(id) on delete set null,
  responsible_user_id uuid
    references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),
  archived_at timestamptz,

  constraint skpe_project_canvas_items_content_not_blank
    check (length(trim(content)) > 0),
  constraint skpe_project_canvas_items_status_check
    check (status in ('active', 'validated', 'discarded')),
  constraint skpe_project_canvas_items_priority_check
    check (priority in ('low', 'medium', 'high', 'critical'))
);

comment on table public.skpe_project_canvas_items is
  'Conteudos, hipoteses e decisoes registrados em cada bloco do Canvas do Projeto.';

create index idx_skpe_project_canvas_items_block
  on public.skpe_project_canvas_items(block_id, display_order);

create index idx_skpe_project_canvas_items_journey
  on public.skpe_project_canvas_items(linked_journey_item_id);

create trigger skpe_project_canvas_items_set_updated_at
before update on public.skpe_project_canvas_items
for each row
execute function public.set_updated_at();

-- ============================================================
-- HISTORICO E AUDITORIA
-- ============================================================

create table public.skpe_project_canvas_history (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  canvas_id uuid
    references public.skpe_project_canvases(id) on delete set null,
  block_id uuid
    references public.skpe_project_canvas_blocks(id) on delete set null,
  item_id uuid
    references public.skpe_project_canvas_items(id) on delete set null,
  actor_user_id uuid not null
    references public.profiles(id) on delete restrict,
  action_code text not null,
  reason text,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz not null default timezone('utc', now()),

  constraint skpe_project_canvas_history_action_not_blank
    check (length(trim(action_code)) > 0)
);

comment on table public.skpe_project_canvas_history is
  'Trilha de auditoria das alteracoes realizadas no Canvas do Projeto.';

create index idx_skpe_project_canvas_history_project
  on public.skpe_project_canvas_history(project_id, occurred_at desc);

create index idx_skpe_project_canvas_history_canvas
  on public.skpe_project_canvas_history(canvas_id, occurred_at desc);

-- ============================================================
-- AUTORIZACAO
-- ============================================================

create or replace function public.can_view_skpe_project_canvas(
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
    and public.has_module_access(target_organization_id, 'SK-PE')
    and (
      public.has_module_permission(
        target_organization_id,
        'SK-PE',
        'project_canvas.view'
      )
      or public.has_module_permission(
        target_organization_id,
        'SK-PE',
        'project_canvas.manage'
      )
      or public.is_organization_admin(target_organization_id)
    );
$$;

create or replace function public.can_manage_skpe_project_canvas(
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
      'project_canvas.manage'
    );
$$;

-- ============================================================
-- CRIACAO DO CANVAS PADRAO
-- ============================================================

create or replace function public.create_skpe_project_canvas(
  target_project_id uuid,
  canvas_name text default 'Business Model Canvas do Projeto'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_project public.skpe_projects%rowtype;
  existing_canvas_id uuid;
  new_canvas_id uuid;
begin
  select *
    into target_project
  from public.skpe_projects
  where id = target_project_id
    and archived_at is null;

  if target_project.id is null then
    raise exception 'Projeto estrategico nao encontrado.';
  end if;

  if not public.can_manage_skpe_project_canvas(target_project.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode criar o Canvas deste projeto.'
      using errcode = '42501';
  end if;

  select id
    into existing_canvas_id
  from public.skpe_project_canvases
  where project_id = target_project_id
    and is_current = true
    and archived_at is null
  limit 1;

  if existing_canvas_id is not null then
    return existing_canvas_id;
  end if;

  insert into public.skpe_project_canvases (
    organization_id,
    project_id,
    code,
    name,
    description,
    status,
    version_number,
    is_current,
    template_code,
    created_by,
    updated_by
  )
  values (
    target_project.organization_id,
    target_project.id,
    'PROJECT-BMC',
    coalesce(nullif(trim(canvas_name), ''), 'Business Model Canvas do Projeto'),
    'Canvas complementar para concepcao, alinhamento, comunicacao e gestao do projeto estrategico.',
    'draft',
    1,
    true,
    'SKPE-PROJECT-BMC-2026.1',
    auth.uid(),
    auth.uid()
  )
  returning id into new_canvas_id;

  insert into public.skpe_project_canvas_blocks (
    canvas_id,
    code,
    name,
    description,
    guidance,
    display_order,
    grid_area,
    is_mandatory,
    created_by,
    updated_by
  )
  select
    new_canvas_id,
    block_data.code,
    block_data.name,
    block_data.description,
    block_data.guidance,
    block_data.display_order,
    block_data.grid_area,
    true,
    auth.uid(),
    auth.uid()
  from (
    values
      ('PURPOSE', 'Proposito e Problema', 'Razao de existir do projeto e problema ou oportunidade que motiva sua realizacao.', 'Que problema relevante sera resolvido? Por que este projeto deve existir agora?', 10, 'purpose'),
      ('STAKEHOLDERS', 'Partes Interessadas', 'Pessoas, grupos e organizacoes que influenciam ou sao impactados pelo projeto.', 'Quem decide, influencia, executa, financia, utiliza ou sera afetado?', 20, 'stakeholders'),
      ('BENEFICIARIES', 'Beneficiarios', 'Publicos que receberao diretamente os resultados e beneficios do projeto.', 'Quem percebe valor ao final? Quais necessidades devem ser atendidas?', 30, 'beneficiaries'),
      ('VALUE_PROPOSITION', 'Proposta de Valor do Projeto', 'Valor central que o projeto entregara aos beneficiarios e demais partes interessadas.', 'Que transformacao concreta sera entregue e por que ela e relevante?', 40, 'value'),
      ('DELIVERABLES', 'Entregas Principais', 'Produtos, resultados e capacidades que deverao ser produzidos.', 'Quais entregas comprovam que o projeto cumpriu seu proposito?', 50, 'deliverables'),
      ('KEY_ACTIVITIES', 'Atividades-Chave', 'Principais frentes de trabalho necessarias para produzir as entregas.', 'O que precisa ser feito para gerar os resultados esperados?', 60, 'activities'),
      ('KEY_RESOURCES', 'Recursos-Chave', 'Pessoas, competencias, tecnologia, informacoes, infraestrutura e recursos financeiros.', 'Quais recursos sao indispensaveis para executar o projeto?', 70, 'resources'),
      ('PARTNERS', 'Parceiros e Apoios', 'Organizacoes e atores externos que ampliam a capacidade de entrega.', 'Quem pode cooperar, fornecer, validar, financiar ou acelerar o projeto?', 80, 'partners'),
      ('GOVERNANCE', 'Governanca e Responsabilidades', 'Estrutura de patrocinio, decisao, coordenacao, validacao e prestacao de contas.', 'Quem patrocina, decide, coordena, executa e valida?', 90, 'governance'),
      ('RISKS', 'Riscos e Restricoes', 'Incertezas, premissas, dependencias e limitacoes relevantes.', 'O que pode impedir ou comprometer o sucesso do projeto?', 100, 'risks'),
      ('SUCCESS_METRICS', 'Indicadores de Sucesso', 'Medidas de desempenho, resultado, impacto e valor gerado.', 'Como saberemos, com evidencias, que o projeto foi bem-sucedido?', 110, 'metrics'),
      ('COSTS', 'Custos e Investimentos', 'Recursos financeiros e esforcos necessarios para viabilizar o projeto.', 'Quanto custara e quais investimentos serao necessarios?', 120, 'costs'),
      ('BENEFITS', 'Beneficios Esperados', 'Ganhos financeiros, operacionais, sociais, institucionais e estrategicos.', 'Que beneficios mensuraveis e nao mensuraveis serao gerados?', 130, 'benefits')
  ) as block_data(
    code,
    name,
    description,
    guidance,
    display_order,
    grid_area
  );

  insert into public.skpe_project_canvas_history (
    organization_id,
    project_id,
    canvas_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  values (
    target_project.organization_id,
    target_project.id,
    new_canvas_id,
    auth.uid(),
    'project_canvas_created',
    'Criacao do Canvas padrao do projeto.',
    jsonb_build_object(
      'template_code', 'SKPE-PROJECT-BMC-2026.1',
      'name', coalesce(nullif(trim(canvas_name), ''), 'Business Model Canvas do Projeto')
    )
  );

  return new_canvas_id;
end;
$$;

-- ============================================================
-- CONSULTA DO CANVAS
-- ============================================================

create or replace function public.get_skpe_project_canvas(
  target_project_id uuid
)
returns table (
  organization_id uuid,
  project_id uuid,
  project_code text,
  project_name text,
  canvas_id uuid,
  canvas_name text,
  canvas_status text,
  canvas_version integer,
  template_code text,
  block_id uuid,
  block_code text,
  block_name text,
  block_description text,
  block_guidance text,
  block_order integer,
  grid_area text,
  item_id uuid,
  item_content text,
  item_description text,
  item_status text,
  item_priority text,
  item_order integer,
  linked_journey_item_id uuid,
  responsible_user_id uuid,
  responsible_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  target_project public.skpe_projects%rowtype;
begin
  select *
    into target_project
  from public.skpe_projects
  where id = target_project_id
    and archived_at is null;

  if target_project.id is null then
    raise exception 'Projeto estrategico nao encontrado.';
  end if;

  if not public.can_view_skpe_project_canvas(target_project.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar o Canvas deste projeto.'
      using errcode = '42501';
  end if;

  return query
  select
    p.organization_id,
    p.id,
    p.code,
    p.name,
    c.id,
    c.name,
    c.status,
    c.version_number,
    c.template_code,
    b.id,
    b.code,
    b.name,
    b.description,
    b.guidance,
    b.display_order,
    b.grid_area,
    i.id,
    i.content,
    i.description,
    i.status,
    i.priority,
    i.display_order,
    i.linked_journey_item_id,
    i.responsible_user_id,
    coalesce(pr.display_name, pr.full_name, pr.email)
  from public.skpe_projects p
  join public.skpe_project_canvases c
    on c.project_id = p.id
   and c.is_current = true
   and c.archived_at is null
  join public.skpe_project_canvas_blocks b
    on b.canvas_id = c.id
  left join public.skpe_project_canvas_items i
    on i.block_id = b.id
   and i.archived_at is null
  left join public.profiles pr
    on pr.id = i.responsible_user_id
  where p.id = target_project_id
  order by b.display_order, i.display_order nulls last, i.created_at nulls last;
end;
$$;

-- ============================================================
-- ACAO RAPIDA: ADICIONAR ITEM AO BLOCO
-- ============================================================

create or replace function public.add_skpe_project_canvas_item(
  target_block_id uuid,
  item_content text,
  item_priority text default 'medium',
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_block public.skpe_project_canvas_blocks%rowtype;
  target_canvas public.skpe_project_canvases%rowtype;
  target_project public.skpe_projects%rowtype;
  new_item_id uuid;
  next_order integer;
begin
  select *
    into target_block
  from public.skpe_project_canvas_blocks
  where id = target_block_id;

  if target_block.id is null then
    raise exception 'Bloco do Canvas nao encontrado.';
  end if;

  select *
    into target_canvas
  from public.skpe_project_canvases
  where id = target_block.canvas_id
    and archived_at is null;

  select *
    into target_project
  from public.skpe_projects
  where id = target_canvas.project_id
    and archived_at is null;

  if not public.can_manage_skpe_project_canvas(target_project.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode alterar o Canvas deste projeto.'
      using errcode = '42501';
  end if;

  if item_content is null or length(trim(item_content)) = 0 then
    raise exception 'Informe o conteudo do item.';
  end if;

  if item_priority not in ('low', 'medium', 'high', 'critical') then
    raise exception 'Prioridade invalida.';
  end if;

  select coalesce(max(display_order), 0) + 10
    into next_order
  from public.skpe_project_canvas_items
  where block_id = target_block_id
    and archived_at is null;

  insert into public.skpe_project_canvas_items (
    block_id,
    content,
    priority,
    display_order,
    created_by,
    updated_by
  )
  values (
    target_block_id,
    trim(item_content),
    item_priority,
    next_order,
    auth.uid(),
    auth.uid()
  )
  returning id into new_item_id;

  insert into public.skpe_project_canvas_history (
    organization_id,
    project_id,
    canvas_id,
    block_id,
    item_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  values (
    target_project.organization_id,
    target_project.id,
    target_canvas.id,
    target_block.id,
    new_item_id,
    auth.uid(),
    'project_canvas_item_added',
    nullif(trim(change_reason), ''),
    jsonb_build_object(
      'content', trim(item_content),
      'priority', item_priority,
      'block_code', target_block.code
    )
  );

  return new_item_id;
end;
$$;

-- ============================================================
-- ACAO RAPIDA: VALIDAR OU REATIVAR ITEM
-- ============================================================

create or replace function public.set_skpe_project_canvas_item_status(
  target_item_id uuid,
  target_status text,
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_item public.skpe_project_canvas_items%rowtype;
  target_block public.skpe_project_canvas_blocks%rowtype;
  target_canvas public.skpe_project_canvases%rowtype;
  target_project public.skpe_projects%rowtype;
begin
  select *
    into target_item
  from public.skpe_project_canvas_items
  where id = target_item_id
    and archived_at is null
  for update;

  if target_item.id is null then
    raise exception 'Item do Canvas nao encontrado.';
  end if;

  select * into target_block
  from public.skpe_project_canvas_blocks
  where id = target_item.block_id;

  select * into target_canvas
  from public.skpe_project_canvases
  where id = target_block.canvas_id;

  select * into target_project
  from public.skpe_projects
  where id = target_canvas.project_id;

  if not public.can_manage_skpe_project_canvas(target_project.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode alterar o Canvas deste projeto.'
      using errcode = '42501';
  end if;

  if target_status not in ('active', 'validated', 'discarded') then
    raise exception 'Status invalido para o item do Canvas.';
  end if;

  if change_reason is null or length(trim(change_reason)) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  update public.skpe_project_canvas_items
  set
    status = target_status,
    updated_by = auth.uid()
  where id = target_item_id;

  insert into public.skpe_project_canvas_history (
    organization_id,
    project_id,
    canvas_id,
    block_id,
    item_id,
    actor_user_id,
    action_code,
    reason,
    previous_data,
    new_data
  )
  values (
    target_project.organization_id,
    target_project.id,
    target_canvas.id,
    target_block.id,
    target_item.id,
    auth.uid(),
    'project_canvas_item_status_changed',
    trim(change_reason),
    jsonb_build_object('status', target_item.status),
    jsonb_build_object('status', target_status)
  );
end;
$$;

-- ============================================================
-- RLS
-- ============================================================

alter table public.skpe_project_canvases enable row level security;
alter table public.skpe_project_canvas_blocks enable row level security;
alter table public.skpe_project_canvas_items enable row level security;
alter table public.skpe_project_canvas_history enable row level security;

create policy skpe_project_canvases_select_authorized
on public.skpe_project_canvases
for select
to authenticated
using (public.can_view_skpe_project_canvas(organization_id));

create policy skpe_project_canvases_manage_authorized
on public.skpe_project_canvases
for all
to authenticated
using (public.can_manage_skpe_project_canvas(organization_id))
with check (public.can_manage_skpe_project_canvas(organization_id));

create policy skpe_project_canvas_blocks_select_authorized
on public.skpe_project_canvas_blocks
for select
to authenticated
using (
  exists (
    select 1
    from public.skpe_project_canvases c
    where c.id = skpe_project_canvas_blocks.canvas_id
      and public.can_view_skpe_project_canvas(c.organization_id)
  )
);

create policy skpe_project_canvas_blocks_manage_authorized
on public.skpe_project_canvas_blocks
for all
to authenticated
using (
  exists (
    select 1
    from public.skpe_project_canvases c
    where c.id = skpe_project_canvas_blocks.canvas_id
      and public.can_manage_skpe_project_canvas(c.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.skpe_project_canvases c
    where c.id = skpe_project_canvas_blocks.canvas_id
      and public.can_manage_skpe_project_canvas(c.organization_id)
  )
);

create policy skpe_project_canvas_items_select_authorized
on public.skpe_project_canvas_items
for select
to authenticated
using (
  exists (
    select 1
    from public.skpe_project_canvas_blocks b
    join public.skpe_project_canvases c
      on c.id = b.canvas_id
    where b.id = skpe_project_canvas_items.block_id
      and public.can_view_skpe_project_canvas(c.organization_id)
  )
);

create policy skpe_project_canvas_items_manage_authorized
on public.skpe_project_canvas_items
for all
to authenticated
using (
  exists (
    select 1
    from public.skpe_project_canvas_blocks b
    join public.skpe_project_canvases c
      on c.id = b.canvas_id
    where b.id = skpe_project_canvas_items.block_id
      and public.can_manage_skpe_project_canvas(c.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.skpe_project_canvas_blocks b
    join public.skpe_project_canvases c
      on c.id = b.canvas_id
    where b.id = skpe_project_canvas_items.block_id
      and public.can_manage_skpe_project_canvas(c.organization_id)
  )
);

create policy skpe_project_canvas_history_select_authorized
on public.skpe_project_canvas_history
for select
to authenticated
using (public.can_manage_skpe_project_canvas(organization_id));

-- Historico inserido apenas por funcoes security definer.

-- ============================================================
-- PRIVILEGIOS
-- ============================================================

revoke all on table public.skpe_project_canvases from anon;
revoke all on table public.skpe_project_canvas_blocks from anon;
revoke all on table public.skpe_project_canvas_items from anon;
revoke all on table public.skpe_project_canvas_history from anon;

revoke all on function public.can_view_skpe_project_canvas(uuid) from public, anon;
revoke all on function public.can_manage_skpe_project_canvas(uuid) from public, anon;
revoke all on function public.create_skpe_project_canvas(uuid, text) from public, anon;
revoke all on function public.get_skpe_project_canvas(uuid) from public, anon;
revoke all on function public.add_skpe_project_canvas_item(uuid, text, text, text) from public, anon;
revoke all on function public.set_skpe_project_canvas_item_status(uuid, text, text) from public, anon;

grant execute on function public.can_view_skpe_project_canvas(uuid) to authenticated, service_role;
grant execute on function public.can_manage_skpe_project_canvas(uuid) to authenticated, service_role;
grant execute on function public.create_skpe_project_canvas(uuid, text) to authenticated, service_role;
grant execute on function public.get_skpe_project_canvas(uuid) to authenticated, service_role;
grant execute on function public.add_skpe_project_canvas_item(uuid, text, text, text) to authenticated, service_role;
grant execute on function public.set_skpe_project_canvas_item_status(uuid, text, text) to authenticated, service_role;

-- ============================================================
-- CRIACAO DO CANVAS PARA PROJETOS EXISTENTES
-- ============================================================

-- O seed abaixo replica a mesma estrutura da funcao sem depender de auth.uid(),
-- permitindo criar o Canvas inicial para projetos ja existentes durante a migration.

do $$
declare
  project_record record;
  new_canvas_id uuid;
begin
  for project_record in
    select p.id, p.organization_id, p.name
    from public.skpe_projects p
    where p.archived_at is null
      and not exists (
        select 1
        from public.skpe_project_canvases c
        where c.project_id = p.id
          and c.is_current = true
          and c.archived_at is null
      )
  loop
    insert into public.skpe_project_canvases (
      organization_id,
      project_id,
      code,
      name,
      description,
      status,
      version_number,
      is_current,
      template_code
    )
    values (
      project_record.organization_id,
      project_record.id,
      'PROJECT-BMC',
      'Business Model Canvas do Projeto',
      'Canvas complementar para concepcao, alinhamento, comunicacao e gestao do projeto estrategico.',
      'draft',
      1,
      true,
      'SKPE-PROJECT-BMC-2026.1'
    )
    returning id into new_canvas_id;

    insert into public.skpe_project_canvas_blocks (
      canvas_id,
      code,
      name,
      description,
      guidance,
      display_order,
      grid_area,
      is_mandatory
    )
    select
      new_canvas_id,
      block_data.code,
      block_data.name,
      block_data.description,
      block_data.guidance,
      block_data.display_order,
      block_data.grid_area,
      true
    from (
      values
        ('PURPOSE', 'Proposito e Problema', 'Razao de existir do projeto e problema ou oportunidade que motiva sua realizacao.', 'Que problema relevante sera resolvido? Por que este projeto deve existir agora?', 10, 'purpose'),
        ('STAKEHOLDERS', 'Partes Interessadas', 'Pessoas, grupos e organizacoes que influenciam ou sao impactados pelo projeto.', 'Quem decide, influencia, executa, financia, utiliza ou sera afetado?', 20, 'stakeholders'),
        ('BENEFICIARIES', 'Beneficiarios', 'Publicos que receberao diretamente os resultados e beneficios do projeto.', 'Quem percebe valor ao final? Quais necessidades devem ser atendidas?', 30, 'beneficiaries'),
        ('VALUE_PROPOSITION', 'Proposta de Valor do Projeto', 'Valor central que o projeto entregara aos beneficiarios e demais partes interessadas.', 'Que transformacao concreta sera entregue e por que ela e relevante?', 40, 'value'),
        ('DELIVERABLES', 'Entregas Principais', 'Produtos, resultados e capacidades que deverao ser produzidos.', 'Quais entregas comprovam que o projeto cumpriu seu proposito?', 50, 'deliverables'),
        ('KEY_ACTIVITIES', 'Atividades-Chave', 'Principais frentes de trabalho necessarias para produzir as entregas.', 'O que precisa ser feito para gerar os resultados esperados?', 60, 'activities'),
        ('KEY_RESOURCES', 'Recursos-Chave', 'Pessoas, competencias, tecnologia, informacoes, infraestrutura e recursos financeiros.', 'Quais recursos sao indispensaveis para executar o projeto?', 70, 'resources'),
        ('PARTNERS', 'Parceiros e Apoios', 'Organizacoes e atores externos que ampliam a capacidade de entrega.', 'Quem pode cooperar, fornecer, validar, financiar ou acelerar o projeto?', 80, 'partners'),
        ('GOVERNANCE', 'Governanca e Responsabilidades', 'Estrutura de patrocinio, decisao, coordenacao, validacao e prestacao de contas.', 'Quem patrocina, decide, coordena, executa e valida?', 90, 'governance'),
        ('RISKS', 'Riscos e Restricoes', 'Incertezas, premissas, dependencias e limitacoes relevantes.', 'O que pode impedir ou comprometer o sucesso do projeto?', 100, 'risks'),
        ('SUCCESS_METRICS', 'Indicadores de Sucesso', 'Medidas de desempenho, resultado, impacto e valor gerado.', 'Como saberemos, com evidencias, que o projeto foi bem-sucedido?', 110, 'metrics'),
        ('COSTS', 'Custos e Investimentos', 'Recursos financeiros e esforcos necessarios para viabilizar o projeto.', 'Quanto custara e quais investimentos serao necessarios?', 120, 'costs'),
        ('BENEFITS', 'Beneficios Esperados', 'Ganhos financeiros, operacionais, sociais, institucionais e estrategicos.', 'Que beneficios mensuraveis e nao mensuraveis serao gerados?', 130, 'benefits')
    ) as block_data(
      code,
      name,
      description,
      guidance,
      display_order,
      grid_area
    );
  end loop;
end;
$$;
