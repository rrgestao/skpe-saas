-- ============================================================
-- SK-PE SaaS
-- Migration: Modelos metodologicos versionados e clonagem
-- ============================================================

-- ============================================================
-- MODELOS METODOLOGICOS
-- ============================================================

create table public.skpe_methodology_templates (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  status text not null default 'active',
  is_recommended boolean not null default false,
  owner_organization_id uuid
    references public.organizations(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),

  constraint skpe_methodology_templates_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_methodology_templates_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_methodology_templates_status_check
    check (status in ('draft', 'active', 'inactive', 'retired'))
);

comment on table public.skpe_methodology_templates is
  'Catalogo de modelos metodologicos reutilizaveis do SK-PE.';

create unique index skpe_methodology_templates_one_recommended
  on public.skpe_methodology_templates(is_recommended)
  where is_recommended = true and status = 'active';

create trigger skpe_methodology_templates_set_updated_at
before update on public.skpe_methodology_templates
for each row
execute function public.set_updated_at();

create table public.skpe_methodology_template_versions (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null
    references public.skpe_methodology_templates(id) on delete cascade,
  version_code text not null,
  name text not null,
  description text,
  status text not null default 'draft',
  effective_from date,
  published_at timestamptz,
  published_by uuid references public.profiles(id),
  release_notes text,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),

  constraint skpe_template_versions_code_not_blank
    check (length(trim(version_code)) > 0),
  constraint skpe_template_versions_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_template_versions_status_check
    check (status in ('draft', 'published', 'retired')),
  constraint skpe_template_versions_unique
    unique (template_id, version_code)
);

comment on table public.skpe_methodology_template_versions is
  'Versoes imutaveis/publicaveis dos modelos metodologicos do SK-PE.';

create index idx_skpe_template_versions_template
  on public.skpe_methodology_template_versions(template_id);

create trigger skpe_methodology_template_versions_set_updated_at
before update on public.skpe_methodology_template_versions
for each row
execute function public.set_updated_at();

create table public.skpe_methodology_template_items (
  id uuid primary key default gen_random_uuid(),
  template_version_id uuid not null
    references public.skpe_methodology_template_versions(id) on delete cascade,
  parent_item_id uuid
    references public.skpe_methodology_template_items(id) on delete cascade,
  item_type text not null,
  code text not null,
  name text not null,
  description text,
  display_order integer not null default 0,
  is_mandatory boolean not null default true,
  is_recommended boolean not null default true,
  default_duration_days integer,
  validation_required boolean not null default false,
  completion_criteria jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),

  constraint skpe_template_items_type_check
    check (item_type in ('macrophase', 'phase', 'stage', 'activity', 'deliverable', 'gate')),
  constraint skpe_template_items_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_template_items_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_template_items_duration_check
    check (default_duration_days is null or default_duration_days >= 0),
  constraint skpe_template_items_unique
    unique (template_version_id, code)
);

comment on table public.skpe_methodology_template_items is
  'Arvore padrao de macrofases, fases, etapas, atividades, entregaveis e gates por versao metodologica.';

create index idx_skpe_template_items_version
  on public.skpe_methodology_template_items(template_version_id);

create index idx_skpe_template_items_parent
  on public.skpe_methodology_template_items(parent_item_id);

create trigger skpe_methodology_template_items_set_updated_at
before update on public.skpe_methodology_template_items
for each row
execute function public.set_updated_at();

-- ============================================================
-- RASTREABILIDADE DO PROJETO EM RELACAO AO PADRAO
-- ============================================================

alter table public.skpe_projects
  add column methodology_template_id uuid
    references public.skpe_methodology_templates(id) on delete set null,
  add column methodology_template_version_id uuid
    references public.skpe_methodology_template_versions(id) on delete set null,
  add column template_cloned_at timestamptz,
  add column created_without_template boolean not null default false;

create index idx_skpe_projects_template_version
  on public.skpe_projects(methodology_template_version_id);

create table public.skpe_project_template_deviations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  template_id uuid
    references public.skpe_methodology_templates(id) on delete set null,
  template_version_id uuid
    references public.skpe_methodology_template_versions(id) on delete set null,
  template_item_id uuid
    references public.skpe_methodology_template_items(id) on delete set null,
  journey_item_id uuid
    references public.skpe_journey_items(id) on delete set null,
  deviation_type text not null,
  original_data jsonb,
  project_data jsonb,
  reason text not null,
  impact_assessment text,
  actor_user_id uuid not null
    references public.profiles(id) on delete restrict,
  occurred_at timestamptz not null default timezone('utc', now()),

  constraint skpe_project_deviations_type_check
    check (deviation_type in ('added', 'modified', 'disabled', 'removed', 'created_without_template')),
  constraint skpe_project_deviations_reason_check
    check (length(trim(reason)) >= 10)
);

comment on table public.skpe_project_template_deviations is
  'Registro auditavel das adaptacoes realizadas em relacao ao modelo metodologico de origem.';

create index idx_skpe_project_deviations_project
  on public.skpe_project_template_deviations(project_id, occurred_at desc);

-- ============================================================
-- AUTORIZACAO E CONSULTA DE MODELOS
-- ============================================================

create or replace function public.can_view_skpe_methodology_templates()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null;
$$;

create or replace function public.get_skpe_methodology_templates()
returns table (
  template_id uuid,
  template_code text,
  template_name text,
  template_description text,
  is_recommended boolean,
  version_id uuid,
  version_code text,
  version_name text,
  effective_from date
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    t.id,
    t.code,
    t.name,
    t.description,
    t.is_recommended,
    v.id,
    v.version_code,
    v.name,
    v.effective_from
  from public.skpe_methodology_templates t
  join public.skpe_methodology_template_versions v
    on v.template_id = t.id
  where t.status = 'active'
    and v.status = 'published'
  order by t.is_recommended desc, t.name, v.effective_from desc nulls last;
$$;

-- ============================================================
-- CRIACAO DE PROJETO A PARTIR DE MODELO
-- ============================================================

create or replace function public.create_skpe_project_from_template(
  target_organization_id uuid,
  project_code text,
  project_name text,
  project_description text default null,
  project_start_date date default null,
  project_target_end_date date default null,
  target_template_version_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_version public.skpe_methodology_template_versions%rowtype;
  selected_template public.skpe_methodology_templates%rowtype;
  new_project_id uuid;
  template_item record;
  new_parent_id uuid;
  new_item_id uuid;
begin
  if not public.can_manage_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode criar projetos estrategicos para esta organizacao.'
      using errcode = '42501';
  end if;

  if project_code is null or length(trim(project_code)) = 0 then
    raise exception 'Informe o codigo do projeto.';
  end if;

  if project_name is null or length(trim(project_name)) = 0 then
    raise exception 'Informe o nome do projeto.';
  end if;

  if project_target_end_date is not null
     and project_start_date is not null
     and project_target_end_date < project_start_date then
    raise exception 'A data final nao pode ser anterior a data inicial.';
  end if;

  if target_template_version_id is null then
    select v.*
      into selected_version
    from public.skpe_methodology_template_versions v
    join public.skpe_methodology_templates t
      on t.id = v.template_id
    where t.status = 'active'
      and t.is_recommended = true
      and v.status = 'published'
    order by v.effective_from desc nulls last, v.created_at desc
    limit 1;
  else
    select *
      into selected_version
    from public.skpe_methodology_template_versions
    where id = target_template_version_id
      and status = 'published';
  end if;

  if selected_version.id is null then
    raise exception 'Nenhuma versao metodologica publicada foi encontrada.';
  end if;

  select *
    into selected_template
  from public.skpe_methodology_templates
  where id = selected_version.template_id
    and status = 'active';

  if selected_template.id is null then
    raise exception 'O modelo metodologico selecionado nao esta ativo.';
  end if;

  insert into public.skpe_projects (
    organization_id,
    code,
    name,
    description,
    status,
    start_date,
    target_end_date,
    progress,
    methodology_version,
    methodology_template_id,
    methodology_template_version_id,
    template_cloned_at,
    created_without_template,
    created_by,
    updated_by
  )
  values (
    target_organization_id,
    trim(project_code),
    trim(project_name),
    nullif(trim(project_description), ''),
    'draft',
    project_start_date,
    project_target_end_date,
    0,
    selected_version.version_code,
    selected_template.id,
    selected_version.id,
    timezone('utc', now()),
    false,
    auth.uid(),
    auth.uid()
  )
  returning id into new_project_id;

  create temporary table if not exists pg_temp.skpe_template_clone_map (
    template_item_id uuid primary key,
    journey_item_id uuid not null
  ) on commit drop;

  truncate table pg_temp.skpe_template_clone_map;

  for template_item in
    with recursive template_tree as (
      select
        i.*,
        0 as depth
      from public.skpe_methodology_template_items i
      where i.template_version_id = selected_version.id
        and i.parent_item_id is null

      union all

      select
        child.*,
        parent.depth + 1
      from public.skpe_methodology_template_items child
      join template_tree parent
        on parent.id = child.parent_item_id
    )
    select *
    from template_tree
    order by depth, display_order, code
  loop
    new_parent_id := null;

    select journey_item_id
      into new_parent_id
    from pg_temp.skpe_template_clone_map
    where template_item_id = template_item.parent_item_id;

    insert into public.skpe_journey_items (
      project_id,
      parent_item_id,
      item_type,
      code,
      name,
      description,
      status,
      progress,
      display_order,
      is_current,
      is_mandatory,
      planned_start_date,
      planned_end_date,
      validation_required,
      validation_status,
      metadata,
      created_by,
      updated_by
    )
    values (
      new_project_id,
      new_parent_id,
      template_item.item_type,
      template_item.code,
      template_item.name,
      template_item.description,
      'not_started',
      0,
      template_item.display_order,
      false,
      template_item.is_mandatory,
      case
        when project_start_date is null then null
        else project_start_date
      end,
      case
        when project_start_date is null
          or template_item.default_duration_days is null then null
        else project_start_date + template_item.default_duration_days
      end,
      template_item.validation_required,
      case when template_item.validation_required then 'pending' else 'not_required' end,
      jsonb_build_object(
        'template_item_id', template_item.id,
        'completion_criteria', template_item.completion_criteria,
        'template_metadata', template_item.metadata
      ),
      auth.uid(),
      auth.uid()
    )
    returning id into new_item_id;

    insert into pg_temp.skpe_template_clone_map (
      template_item_id,
      journey_item_id
    )
    values (
      template_item.id,
      new_item_id
    );
  end loop;

  insert into public.skpe_journey_audit (
    organization_id,
    project_id,
    actor_user_id,
    action_code,
    reason,
    new_data
  )
  values (
    target_organization_id,
    new_project_id,
    auth.uid(),
    'project_created_from_template',
    'Projeto criado a partir do modelo metodologico recomendado.',
    jsonb_build_object(
      'template_id', selected_template.id,
      'template_code', selected_template.code,
      'template_version_id', selected_version.id,
      'template_version_code', selected_version.version_code
    )
  );

  return new_project_id;
end;
$$;

-- ============================================================
-- RLS
-- ============================================================

alter table public.skpe_methodology_templates enable row level security;
alter table public.skpe_methodology_template_versions enable row level security;
alter table public.skpe_methodology_template_items enable row level security;
alter table public.skpe_project_template_deviations enable row level security;

create policy skpe_methodology_templates_select_authenticated
on public.skpe_methodology_templates
for select
to authenticated
using (public.can_view_skpe_methodology_templates());

create policy skpe_methodology_template_versions_select_authenticated
on public.skpe_methodology_template_versions
for select
to authenticated
using (public.can_view_skpe_methodology_templates());

create policy skpe_methodology_template_items_select_authenticated
on public.skpe_methodology_template_items
for select
to authenticated
using (public.can_view_skpe_methodology_templates());

create policy skpe_project_deviations_select_authorized
on public.skpe_project_template_deviations
for select
to authenticated
using (public.can_manage_skpe_journey(organization_id));

-- Escrita nos modelos oficiais fica reservada a migracoes e service_role.
-- Desvios serao inseridos por funcoes security definer nas proximas etapas.

-- ============================================================
-- PRIVILEGIOS
-- ============================================================

revoke all on table public.skpe_methodology_templates from anon;
revoke all on table public.skpe_methodology_template_versions from anon;
revoke all on table public.skpe_methodology_template_items from anon;
revoke all on table public.skpe_project_template_deviations from anon;

revoke all on function public.can_view_skpe_methodology_templates() from public, anon;
revoke all on function public.get_skpe_methodology_templates() from public, anon;
revoke all on function public.create_skpe_project_from_template(uuid, text, text, text, date, date, uuid) from public, anon;

grant execute on function public.can_view_skpe_methodology_templates() to authenticated, service_role;
grant execute on function public.get_skpe_methodology_templates() to authenticated, service_role;
grant execute on function public.create_skpe_project_from_template(uuid, text, text, text, date, date, uuid) to authenticated, service_role;

-- ============================================================
-- MODELO OFICIAL RECOMENDADO SK-PE
-- ============================================================

insert into public.skpe_methodology_templates (
  code,
  name,
  description,
  status,
  is_recommended
)
values (
  'SKPE-OFICIAL',
  'Modelo Oficial de Planejamento Estrategico SK-PE',
  'Padrao metodologico recomendado para diagnostico, formulacao, desdobramento, implementacao, monitoramento e aprendizado estrategico.',
  'active',
  true
)
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description,
  status = excluded.status,
  is_recommended = excluded.is_recommended;

insert into public.skpe_methodology_template_versions (
  template_id,
  version_code,
  name,
  description,
  status,
  effective_from,
  published_at,
  release_notes
)
select
  t.id,
  'SK-PE-2026.1',
  'SK-PE Canonica 2026.1',
  'Primeira versao canonica versionada do modelo oficial do SK-PE.',
  'published',
  date '2026-07-27',
  timezone('utc', now()),
  'Estrutura inicial oficial com cinco macrofases e fases recomendadas.'
from public.skpe_methodology_templates t
where t.code = 'SKPE-OFICIAL'
on conflict (template_id, version_code) do update
set
  name = excluded.name,
  description = excluded.description,
  status = excluded.status,
  effective_from = excluded.effective_from,
  release_notes = excluded.release_notes;

-- ============================================================
-- CARGA PADRAO: MACROFASES
-- ============================================================

with version_target as (
  select v.id
  from public.skpe_methodology_template_versions v
  join public.skpe_methodology_templates t
    on t.id = v.template_id
  where t.code = 'SKPE-OFICIAL'
    and v.version_code = 'SK-PE-2026.1'
)
insert into public.skpe_methodology_template_items (
  template_version_id,
  item_type,
  code,
  name,
  description,
  display_order,
  is_mandatory,
  validation_required,
  completion_criteria
)
select
  version_target.id,
  'macrophase',
  data.code,
  data.name,
  data.description,
  data.display_order,
  true,
  true,
  data.criteria::jsonb
from version_target
cross join (
  values
    ('PEM-01', 'Diagnostico e Entendimento Estrategico', 'Compreender a organizacao, seu contexto, riscos, oportunidades, capacidades e temas criticos.', 10, '["Diagnostico consolidado", "Lacunas e riscos priorizados", "Validacao executiva realizada"]'),
    ('PEM-02', 'Formulacao Estrategica', 'Definir direcionadores, escolhas, objetivos e modelo estrategico futuro.', 20, '["Direcionadores validados", "Escolhas estrategicas aprovadas", "Modelo estrategico futuro definido"]'),
    ('PEM-03', 'Desdobramento Estrategico', 'Converter a estrategia em objetivos, indicadores, metas, iniciativas e responsabilidades.', 30, '["Mapa estrategico aprovado", "Indicadores e metas definidos", "Portfolio de iniciativas priorizado"]'),
    ('PEM-04', 'Implementacao e Mobilizacao', 'Preparar a execucao, a comunicacao, o engajamento e as capacidades necessarias.', 40, '["Plano de implementacao aprovado", "Responsaveis mobilizados", "Riscos de execucao tratados"]'),
    ('PEM-05', 'Monitoramento e Aprendizado', 'Acompanhar resultados, realizar analises criticas e promover aprendizado e atualizacao continua.', 50, '["Rotina de monitoramento implantada", "Analise critica realizada", "Ajustes estrategicos registrados"]')
) as data(code, name, description, display_order, criteria)
on conflict (template_version_id, code) do update
set
  name = excluded.name,
  description = excluded.description,
  display_order = excluded.display_order,
  is_mandatory = excluded.is_mandatory,
  validation_required = excluded.validation_required,
  completion_criteria = excluded.completion_criteria;

-- ============================================================
-- CARGA PADRAO: FASES E GATES
-- ============================================================

with version_target as (
  select v.id
  from public.skpe_methodology_template_versions v
  join public.skpe_methodology_templates t
    on t.id = v.template_id
  where t.code = 'SKPE-OFICIAL'
    and v.version_code = 'SK-PE-2026.1'
),
parent_map as (
  select i.code, i.id
  from public.skpe_methodology_template_items i
  join version_target v on v.id = i.template_version_id
)
insert into public.skpe_methodology_template_items (
  template_version_id,
  parent_item_id,
  item_type,
  code,
  name,
  description,
  display_order,
  is_mandatory,
  validation_required,
  completion_criteria
)
select
  version_target.id,
  parent_map.id,
  data.item_type,
  data.code,
  data.name,
  data.description,
  data.display_order,
  data.is_mandatory,
  data.validation_required,
  data.criteria::jsonb
from version_target
join (
  values
    ('PEM-01', 'phase', 'PEM-01.01', 'Abertura e Mandato', 'Formalizar escopo, governanca, papeis, premissas e criterios de sucesso.', 101, true, false, '["Mandato formalizado"]'),
    ('PEM-01', 'phase', 'PEM-01.02', 'Levantamento e Gestao de Evidencias', 'Organizar documentos, entrevistas, dados e demais evidencias relevantes.', 102, true, false, '["Base de evidencias consolidada"]'),
    ('PEM-01', 'phase', 'PEM-01.03', 'Analise de Contexto e PESTEL', 'Avaliar fatores politicos, economicos, sociais, tecnologicos, ambientais e legais.', 103, true, false, '["PESTEL validada"]'),
    ('PEM-01', 'phase', 'PEM-01.04', 'Partes Interessadas, Mercado e Posicionamento', 'Compreender atores, necessidades, segmentos, concorrencia e posicionamento.', 104, true, false, '["Mapa de partes interessadas", "Leitura de mercado consolidada"]'),
    ('PEM-01', 'phase', 'PEM-01.05', 'SWOT e TOWS', 'Sintetizar ambiente interno e externo e derivar alternativas estrategicas.', 105, true, false, '["SWOT validada", "TOWS consolidada"]'),
    ('PEM-01', 'phase', 'PEM-01.06', 'Riscos, Lacunas e Temas Criticos', 'Priorizar riscos, lacunas, prontidao e temas para decisao.', 106, true, false, '["Riscos e lacunas priorizados"]'),
    ('PEM-01', 'gate',  'PEM-01.GATE', 'Validacao da Macrofase 1', 'Confirmar o diagnostico e autorizar o inicio da formulacao.', 109, true, true, '["Aceite executivo registrado"]'),

    ('PEM-02', 'phase', 'PEM-02.01', 'Abertura da Formulacao Estrategica', 'Confirmar mandato, modelo futuro e criterios de formulacao.', 201, true, false, '["Mandato de formulacao confirmado"]'),
    ('PEM-02', 'phase', 'PEM-02.02', 'Direcionadores Estrategicos', 'Revisar ou formular proposito, missao, visao, valores e principios.', 202, true, false, '["Direcionadores aprovados"]'),
    ('PEM-02', 'phase', 'PEM-02.03', 'Escolhas e Posicionamento Estrategico', 'Definir onde atuar, como competir, como cooperar e como gerar valor.', 203, true, false, '["Escolhas estrategicas registradas"]'),
    ('PEM-02', 'phase', 'PEM-02.04', 'Objetivos Estrategicos', 'Formular objetivos coerentes com as escolhas e os resultados pretendidos.', 204, true, false, '["Objetivos estrategicos aprovados"]'),
    ('PEM-02', 'phase', 'PEM-02.05', 'Modelo Estrategico Futuro', 'Consolidar proposta de valor, modelo de atuacao e arquitetura estrategica futura.', 205, true, false, '["Modelo estrategico futuro validado"]'),
    ('PEM-02', 'gate',  'PEM-02.GATE', 'Validacao da Macrofase 2', 'Aprovar a formulacao antes do desdobramento.', 209, true, true, '["Aceite executivo registrado"]'),

    ('PEM-03', 'phase', 'PEM-03.01', 'Mapa Estrategico', 'Estruturar objetivos e relacoes de causa e efeito.', 301, true, false, '["Mapa estrategico aprovado"]'),
    ('PEM-03', 'phase', 'PEM-03.02', 'Indicadores e Metas', 'Definir indicadores, formulas, fontes, linhas de base e metas.', 302, true, false, '["Indicadores e metas aprovados"]'),
    ('PEM-03', 'phase', 'PEM-03.03', 'Iniciativas e Projetos Estrategicos', 'Identificar e priorizar iniciativas que viabilizam os objetivos.', 303, true, false, '["Portfolio priorizado"]'),
    ('PEM-03', 'phase', 'PEM-03.04', 'Responsabilidades e Governanca da Execucao', 'Definir patrocinadores, responsaveis, foruns e rotinas de decisao.', 304, true, false, '["Matriz de responsabilidades aprovada"]'),
    ('PEM-03', 'gate',  'PEM-03.GATE', 'Validacao da Macrofase 3', 'Aprovar o desdobramento antes da implementacao.', 309, true, true, '["Aceite executivo registrado"]'),

    ('PEM-04', 'phase', 'PEM-04.01', 'Plano de Implementacao', 'Organizar ondas, marcos, cronograma, recursos e dependencias.', 401, true, false, '["Plano de implementacao aprovado"]'),
    ('PEM-04', 'phase', 'PEM-04.02', 'Comunicacao e Mobilizacao', 'Planejar comunicacao, engajamento e alinhamento das partes interessadas.', 402, true, false, '["Plano de comunicacao e mobilizacao aprovado"]'),
    ('PEM-04', 'phase', 'PEM-04.03', 'Capacidades e Gestao da Mudanca', 'Desenvolver competencias, processos, tecnologia e mudancas necessarias.', 403, true, false, '["Plano de capacidades e mudanca definido"]'),
    ('PEM-04', 'phase', 'PEM-04.04', 'Gestao de Riscos da Implementacao', 'Monitorar riscos, impedimentos e planos de resposta da execucao.', 404, true, false, '["Riscos de implementacao tratados"]'),
    ('PEM-04', 'gate',  'PEM-04.GATE', 'Validacao da Macrofase 4', 'Confirmar prontidao e inicio da operacao monitorada.', 409, true, true, '["Aceite executivo registrado"]'),

    ('PEM-05', 'phase', 'PEM-05.01', 'Rotina de Monitoramento', 'Implantar paineis, reunioes, cadencias e responsabilidades de acompanhamento.', 501, true, false, '["Rotina de monitoramento ativa"]'),
    ('PEM-05', 'phase', 'PEM-05.02', 'Analise Critica de Desempenho', 'Avaliar resultados, desvios, causas, riscos e oportunidades.', 502, true, false, '["Analise critica registrada"]'),
    ('PEM-05', 'phase', 'PEM-05.03', 'Aprendizado e Melhoria', 'Registrar aprendizados, boas praticas e ajustes de execucao.', 503, true, false, '["Aprendizados incorporados"]'),
    ('PEM-05', 'phase', 'PEM-05.04', 'Atualizacao Estrategica', 'Revisar direcionadores, objetivos, metas e iniciativas quando necessario.', 504, true, false, '["Atualizacoes estrategicas formalizadas"]'),
    ('PEM-05', 'gate',  'PEM-05.GATE', 'Ciclo de Revisao Estrategica', 'Formalizar a revisao do ciclo e as decisoes de continuidade.', 509, true, true, '["Revisao estrategica aprovada"]')
) as data(parent_code, item_type, code, name, description, display_order, is_mandatory, validation_required, criteria)
  on true
join parent_map
  on parent_map.code = data.parent_code
on conflict (template_version_id, code) do update
set
  parent_item_id = excluded.parent_item_id,
  item_type = excluded.item_type,
  name = excluded.name,
  description = excluded.description,
  display_order = excluded.display_order,
  is_mandatory = excluded.is_mandatory,
  validation_required = excluded.validation_required,
  completion_criteria = excluded.completion_criteria;

-- ============================================================
-- VINCULO DO PROJETO COOTAQUARA AO PADRAO OFICIAL
-- ============================================================

update public.skpe_projects p
set
  methodology_template_id = t.id,
  methodology_template_version_id = v.id,
  methodology_version = v.version_code,
  template_cloned_at = coalesce(p.template_cloned_at, timezone('utc', now())),
  created_without_template = false
from public.skpe_methodology_templates t
join public.skpe_methodology_template_versions v
  on v.template_id = t.id
join public.organizations o
  on o.code = 'COOTAQUARA'
where p.organization_id = o.id
  and p.code = 'PE-COOTAQUARA-2026'
  and t.code = 'SKPE-OFICIAL'
  and v.version_code = 'SK-PE-2026.1';
