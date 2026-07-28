-- ============================================================
-- Plataforma SPARKs
-- Migration: Serviço transversal de evidências e biblioteca
--            versionada de padrões de checklist da PEM-00
-- Idioma dos conteúdos funcionais: Português do Brasil
-- ============================================================

begin;

-- ============================================================
-- 1. SERVIÇO CENTRAL DE EVIDÊNCIAS
-- ============================================================

create table if not exists public.sparks_evidence_assets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  title text not null,
  description text,
  evidence_type text not null,
  source_type text not null default 'internal',
  origin_module_code text,
  external_origin text,
  reference_date date,
  reference_period_start date,
  reference_period_end date,
  validity_date date,
  confidentiality_level text not null default 'internal',
  validation_status text not null default 'pending',
  reliability_level text not null default 'not_assessed',
  quality_score numeric(5,2),
  completeness_score numeric(5,2),
  currentness_score numeric(5,2),
  overall_score numeric(5,2),
  content_hash text,
  current_version_id uuid,
  skdoc_document_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,

  constraint sparks_evidence_assets_title_not_blank
    check (length(trim(title)) > 0),
  constraint sparks_evidence_assets_type_check
    check (evidence_type in (
      'document',
      'dataset',
      'indicator',
      'self_assessment',
      'assisted_diagnosis',
      'action_plan',
      'interview',
      'workshop',
      'bmc',
      'vpc',
      'benchmark',
      'market_study',
      'legal_reference',
      'image',
      'audio',
      'video',
      'other'
    )),
  constraint sparks_evidence_assets_source_check
    check (source_type in (
      'internal',
      'external',
      'public',
      'market',
      'benchmark',
      'regulatory',
      'partner',
      'other'
    )),
  constraint sparks_evidence_assets_confidentiality_check
    check (confidentiality_level in (
      'public',
      'internal',
      'restricted',
      'confidential'
    )),
  constraint sparks_evidence_assets_validation_check
    check (validation_status in (
      'pending',
      'under_review',
      'validated',
      'rejected',
      'outdated',
      'superseded'
    )),
  constraint sparks_evidence_assets_reliability_check
    check (reliability_level in (
      'not_assessed',
      'very_low',
      'low',
      'moderate',
      'high',
      'very_high'
    )),
  constraint sparks_evidence_assets_scores_check
    check (
      (quality_score is null or quality_score between 0 and 100)
      and (completeness_score is null or completeness_score between 0 and 100)
      and (currentness_score is null or currentness_score between 0 and 100)
      and (overall_score is null or overall_score between 0 and 100)
    ),
  constraint sparks_evidence_assets_period_check
    check (
      reference_period_end is null
      or reference_period_start is null
      or reference_period_end >= reference_period_start
    )
);

comment on table public.sparks_evidence_assets is
  'Cadastro central e transversal de evidências reutilizáveis pelos módulos da Plataforma SPARKs.';

create unique index if not exists uq_sparks_evidence_assets_hash
  on public.sparks_evidence_assets(organization_id, content_hash)
  where content_hash is not null and archived_at is null;

create index if not exists idx_sparks_evidence_assets_org_status
  on public.sparks_evidence_assets(
    organization_id,
    evidence_type,
    validation_status,
    validity_date
  )
  where archived_at is null;

create table if not exists public.sparks_evidence_versions (
  id uuid primary key default gen_random_uuid(),
  evidence_asset_id uuid not null
    references public.sparks_evidence_assets(id) on delete cascade,
  version_number integer not null,
  version_label text,
  storage_bucket text,
  storage_path text,
  file_name text,
  mime_type text,
  file_size_bytes bigint,
  content_hash text,
  extracted_text text,
  change_summary text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint sparks_evidence_versions_number_check
    check (version_number >= 1),
  constraint sparks_evidence_versions_size_check
    check (file_size_bytes is null or file_size_bytes >= 0),
  constraint sparks_evidence_versions_unique
    unique (evidence_asset_id, version_number)
);

alter table public.sparks_evidence_assets
  drop constraint if exists sparks_evidence_assets_current_version_fk;

alter table public.sparks_evidence_assets
  add constraint sparks_evidence_assets_current_version_fk
  foreign key (current_version_id)
  references public.sparks_evidence_versions(id)
  on delete set null;

create index if not exists idx_sparks_evidence_versions_asset
  on public.sparks_evidence_versions(evidence_asset_id, version_number desc);

create table if not exists public.sparks_evidence_links (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  evidence_asset_id uuid not null
    references public.sparks_evidence_assets(id) on delete cascade,
  module_code text not null,
  target_type text not null,
  target_id uuid not null,
  usage_purpose text,
  usage_status text not null default 'active',
  relevance_level text not null default 'important',
  is_primary boolean not null default false,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint sparks_evidence_links_module_not_blank
    check (length(trim(module_code)) > 0),
  constraint sparks_evidence_links_target_not_blank
    check (length(trim(target_type)) > 0),
  constraint sparks_evidence_links_usage_check
    check (usage_status in ('active', 'inactive', 'superseded')),
  constraint sparks_evidence_links_relevance_check
    check (relevance_level in ('fundamental', 'important', 'complementary', 'optional')),
  constraint sparks_evidence_links_unique
    unique (evidence_asset_id, module_code, target_type, target_id)
);

comment on table public.sparks_evidence_links is
  'Vínculos rastreáveis entre uma evidência central e contextos dos módulos SK-DOC, SK-DA, SK-PN, SK-PE e demais módulos.';

create index if not exists idx_sparks_evidence_links_target
  on public.sparks_evidence_links(
    organization_id,
    module_code,
    target_type,
    target_id
  )
  where usage_status = 'active';

create table if not exists public.sparks_evidence_usage_assessments (
  id uuid primary key default gen_random_uuid(),
  evidence_link_id uuid not null
    references public.sparks_evidence_links(id) on delete cascade,
  assessment_version integer not null default 1,
  adequacy_score numeric(5,2),
  sufficiency_score numeric(5,2),
  reliability_score numeric(5,2),
  confidence_level text not null default 'not_assessed',
  strengths text,
  gaps text,
  risks text,
  recommendations text,
  assessment_basis text,
  assessed_at timestamptz not null default timezone('utc', now()),
  assessed_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,

  constraint sparks_evidence_usage_scores_check
    check (
      (adequacy_score is null or adequacy_score between 0 and 100)
      and (sufficiency_score is null or sufficiency_score between 0 and 100)
      and (reliability_score is null or reliability_score between 0 and 100)
    ),
  constraint sparks_evidence_usage_confidence_check
    check (confidence_level in (
      'not_assessed',
      'very_low',
      'low',
      'moderate',
      'high',
      'very_high'
    )),
  constraint sparks_evidence_usage_unique_version
    unique (evidence_link_id, assessment_version)
);

-- ============================================================
-- 2. BIBLIOTECA VERSIONADA DE PADRÕES DE CHECKLIST
-- ============================================================

create table if not exists public.sparks_checklist_templates (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  module_code text not null default 'SK-PE',
  checklist_purpose text not null default 'PEM-00',
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_checklist_templates_code_not_blank
    check (length(trim(code)) > 0),
  constraint sparks_checklist_templates_name_not_blank
    check (length(trim(name)) > 0)
);

create table if not exists public.sparks_checklist_template_versions (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null
    references public.sparks_checklist_templates(id) on delete cascade,
  version_code text not null,
  name text not null,
  description text,
  status text not null default 'draft',
  applicability_rule jsonb not null default '{}'::jsonb,
  effective_from date,
  effective_until date,
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_checklist_template_versions_status_check
    check (status in ('draft', 'published', 'retired')),
  constraint sparks_checklist_template_versions_unique
    unique (template_id, version_code)
);

create table if not exists public.sparks_checklist_template_items (
  id uuid primary key default gen_random_uuid(),
  template_version_id uuid not null
    references public.sparks_checklist_template_versions(id) on delete cascade,
  parent_item_id uuid
    references public.sparks_checklist_template_items(id) on delete cascade,
  code text not null,
  item_type text not null default 'requirement',
  name text not null,
  description text,
  request_reason text,
  evidence_importance text not null default 'important',
  is_required boolean not null default false,
  applicability_rule jsonb not null default '{}'::jsonb,
  possible_evidences jsonb not null default '[]'::jsonb,
  best_practice_criteria jsonb not null default '{}'::jsonb,
  benchmark_guidance text,
  absence_impact text not null default 'moderate',
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_checklist_template_items_type_check
    check (item_type in ('axis', 'requirement', 'evidence_group')),
  constraint sparks_checklist_template_items_importance_check
    check (evidence_importance in ('fundamental', 'important', 'complementary', 'optional')),
  constraint sparks_checklist_template_items_absence_check
    check (absence_impact in ('low', 'moderate', 'high', 'critical')),
  constraint sparks_checklist_template_items_unique
    unique (template_version_id, code)
);

comment on table public.sparks_checklist_template_items is
  'Eixos e requisitos de padrões de checklist, com possíveis evidências, critérios de boas práticas e orientação de benchmark.';

-- ============================================================
-- 3. PADRÃO INICIAL DA PEM-00
-- ============================================================

insert into public.sparks_checklist_templates (
  code,
  name,
  description,
  module_code,
  checklist_purpose,
  active
)
values (
  'SPARKS-PEM00-GERAL',
  'Checklist Geral de Governança e Prontidão Estratégica',
  'Padrão inicial adaptável para caracterização, coleta, qualificação e análise de evidências na Macrofase 00.',
  'SK-PE',
  'PEM-00',
  true
)
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description,
  active = true;

with template as (
  select id
  from public.sparks_checklist_templates
  where code = 'SPARKS-PEM00-GERAL'
)
insert into public.sparks_checklist_template_versions (
  template_id,
  version_code,
  name,
  description,
  status,
  applicability_rule,
  effective_from,
  published_at
)
select
  template.id,
  '2026.1',
  'Padrão Geral 2026.1',
  'Versão inicial com quinze eixos de evidências para a PEM-00.',
  'published',
  '{"organization_types":["cooperative","association","company","other"],"adaptable":true}'::jsonb,
  date '2026-07-27',
  timezone('utc', now())
from template
on conflict (template_id, version_code) do update
set
  name = excluded.name,
  description = excluded.description,
  status = 'published',
  applicability_rule = excluded.applicability_rule;

with version as (
  select version.id
  from public.sparks_checklist_template_versions version
  join public.sparks_checklist_templates template
    on template.id = version.template_id
  where template.code = 'SPARKS-PEM00-GERAL'
    and version.version_code = '2026.1'
), axes(code, name, description, display_order) as (
  values
    ('EIXO-01', 'Identidade e Caracterização Organizacional', 'Compreensão da natureza, história, estrutura, porte, abrangência e contexto institucional.', 10),
    ('EIXO-02', 'Governança', 'Estruturas, papéis, ritos, decisões, controles e prestação de contas.', 20),
    ('EIXO-03', 'Estratégia', 'Direcionadores, planejamento, monitoramento e aprendizado estratégico.', 30),
    ('EIXO-04', 'Modelo de Negócios — BMC e VPC', 'Modelo de negócios, segmentos, propostas de valor, dores, ganhos e hipóteses.', 40),
    ('EIXO-05', 'Cooperados, Clientes e Partes Interessadas', 'Relacionamento, necessidades, participação, satisfação e geração de valor.', 50),
    ('EIXO-06', 'Processos e Operações', 'Processos-chave, capacidade operacional, padrões, controles e desempenho.', 60),
    ('EIXO-07', 'Pessoas e Cultura', 'Estrutura de pessoas, competências, cultura, comunicação e desenvolvimento.', 70),
    ('EIXO-08', 'Finanças e Controladoria', 'Planejamento financeiro, custos, resultados, liquidez, investimentos e controles.', 80),
    ('EIXO-09', 'Mercado e Comercialização', 'Mercados, clientes, canais, concorrência, posicionamento e desempenho comercial.', 90),
    ('EIXO-10', 'Tecnologia e Informação', 'Sistemas, dados, segurança, inovação e suporte à decisão.', 100),
    ('EIXO-11', 'Riscos, Controles e Conformidade', 'Riscos, controles internos, conformidade, integridade e continuidade.', 110),
    ('EIXO-12', 'Sustentabilidade e ESG', 'Impactos ambientais, sociais, governança, compromissos, metas e evidências.', 120),
    ('EIXO-13', 'Resultados e Indicadores', 'Indicadores, metas, tendências, comparações e análise crítica de resultados.', 130),
    ('EIXO-14', 'Autoavaliações, Diagnósticos e Planos de Ação', 'Resultados de avaliações, lacunas, recomendações, execução, reincidência e efetividade.', 140),
    ('EIXO-15', 'Documentos Legais, Normativos e Regulatórios', 'Documentos constitutivos, normativos, licenças, registros e obrigações aplicáveis.', 150)
)
insert into public.sparks_checklist_template_items (
  template_version_id,
  code,
  item_type,
  name,
  description,
  evidence_importance,
  is_required,
  possible_evidences,
  best_practice_criteria,
  absence_impact,
  display_order
)
select
  version.id,
  axes.code,
  'axis',
  axes.name,
  axes.description,
  'important',
  false,
  '[]'::jsonb,
  '{"scale":"0-5","dimensions":["existência","atualidade","completude","formalização","aplicação prática","monitoramento","resultados","aderência às melhores práticas"]}'::jsonb,
  'moderate',
  axes.display_order
from version
cross join axes
on conflict (template_version_id, code) do update
set
  name = excluded.name,
  description = excluded.description,
  best_practice_criteria = excluded.best_practice_criteria,
  display_order = excluded.display_order;

-- Requisitos iniciais representativos por eixo.
with version as (
  select version.id
  from public.sparks_checklist_template_versions version
  join public.sparks_checklist_templates template
    on template.id = version.template_id
  where template.code = 'SPARKS-PEM00-GERAL'
    and version.version_code = '2026.1'
), requirements(axis_code, code, name, importance, required, absence_impact, possible_evidences, display_order) as (
  values
    ('EIXO-01', 'EIXO-01.01', 'Caracterização institucional e cadastral', 'fundamental', true, 'high', '["Ficha cadastral","Histórico institucional","Organograma","Cadastro de unidades","Perfil do quadro social"]'::jsonb, 11),
    ('EIXO-02', 'EIXO-02.01', 'Estrutura e funcionamento da governança', 'fundamental', true, 'critical', '["Estatuto Social","Regimentos Internos","Atas de Assembleias","Atas dos Conselhos","Matriz de responsabilidades","Política de alçadas"]'::jsonb, 21),
    ('EIXO-03', 'EIXO-03.01', 'Direcionadores e planejamento estratégico vigente', 'important', false, 'high', '["Plano Estratégico vigente","Missão, visão e valores","Mapa estratégico","Objetivos e metas","Relatórios de monitoramento"]'::jsonb, 31),
    ('EIXO-04', 'EIXO-04.01', 'Modelo de Negócios e Propostas de Valor', 'important', false, 'high', '["Business Model Canvas — BMC","Value Proposition Canvas — VPC","Plano de Negócios","Estudos de clientes","Portfólio de produtos e serviços"]'::jsonb, 41),
    ('EIXO-05', 'EIXO-05.01', 'Conhecimento de cooperados, clientes e partes interessadas', 'important', false, 'high', '["Cadastro e segmentação","Pesquisas de satisfação","Pesquisas de necessidades","Mapa de partes interessadas","Registros de manifestações"]'::jsonb, 51),
    ('EIXO-06', 'EIXO-06.01', 'Mapeamento e desempenho dos processos-chave', 'important', false, 'high', '["Mapa de processos","SIPOC","Procedimentos operacionais","Indicadores de processos","Relatórios de produtividade e qualidade"]'::jsonb, 61),
    ('EIXO-07', 'EIXO-07.01', 'Estrutura, competências e cultura organizacional', 'important', false, 'moderate', '["Estrutura de cargos e funções","Matriz de competências","Plano de capacitação","Pesquisa de clima","Práticas de comunicação interna"]'::jsonb, 71),
    ('EIXO-08', 'EIXO-08.01', 'Planejamento e acompanhamento financeiro', 'fundamental', true, 'critical', '["Orçamento anual","Fluxo de caixa","Demonstrações contábeis","Relatórios gerenciais","Projeções financeiras","Plano de investimentos","Análise de custos"]'::jsonb, 81),
    ('EIXO-09', 'EIXO-09.01', 'Mercado, clientes, canais e comercialização', 'important', false, 'high', '["Plano comercial","Estudos de mercado","Carteira de clientes","Relatórios de vendas","Política comercial","Análise de concorrentes"]'::jsonb, 91),
    ('EIXO-10', 'EIXO-10.01', 'Tecnologia, dados e segurança da informação', 'important', false, 'moderate', '["Inventário de sistemas","Política de segurança","Plano de continuidade","Relatórios de incidentes","Arquitetura de dados","Projetos de inovação"]'::jsonb, 101),
    ('EIXO-11', 'EIXO-11.01', 'Gestão de riscos, controles e conformidade', 'fundamental', true, 'critical', '["Matriz de riscos","Controles internos","Código de Ética","Canal de denúncias","Políticas de conformidade","Relatórios de auditoria"]'::jsonb, 111),
    ('EIXO-12', 'EIXO-12.01', 'Práticas, compromissos e resultados de Sustentabilidade e ESG', 'important', false, 'high', '["Política de Sustentabilidade","Inventário de impactos","Indicadores ESG","Relatório de Sustentabilidade","Projetos sociais e ambientais","Metas e compromissos"]'::jsonb, 121),
    ('EIXO-13', 'EIXO-13.01', 'Sistema de indicadores e análise crítica de resultados', 'important', false, 'high', '["Painel de indicadores","Séries históricas","Metas","Relatórios de análise crítica","Comparações com referenciais","Planos decorrentes"]'::jsonb, 131),
    ('EIXO-14', 'EIXO-14.01', 'Autoavaliações, Diagnósticos Assistidos e Planos de Ação', 'fundamental', true, 'critical', '["Autoavaliações","Diagnósticos Assistidos","Relatórios de devolutiva","Planos de Ação","Registros de follow-up","Evidências de execução e efetividade"]'::jsonb, 141),
    ('EIXO-15', 'EIXO-15.01', 'Documentação legal, normativa e regulatória aplicável', 'fundamental', true, 'critical', '["Estatuto Social","Registros legais","Licenças","Certidões","Regulamentos","Políticas internas","Obrigações regulatórias"]'::jsonb, 151)
)
insert into public.sparks_checklist_template_items (
  template_version_id,
  parent_item_id,
  code,
  item_type,
  name,
  description,
  request_reason,
  evidence_importance,
  is_required,
  possible_evidences,
  best_practice_criteria,
  benchmark_guidance,
  absence_impact,
  display_order
)
select
  version.id,
  axis.id,
  requirements.code,
  'requirement',
  requirements.name,
  'Avaliar existência, atualidade, completude, aplicação prática, monitoramento e resultados das evidências relacionadas.',
  'Subsidiar o diagnóstico, identificar lacunas e comparar a situação observada com melhores práticas e benchmarks aplicáveis.',
  requirements.importance,
  requirements.required,
  requirements.possible_evidences,
  '{"scale":{"0":"Não apresentado","1":"Evidência insuficiente","2":"Atendimento parcial","3":"Atendimento adequado","4":"Boa prática implementada","5":"Prática madura e sistematizada"},"dimensions":["existência","atualidade","completude","formalização","aplicação prática","monitoramento","resultados","aderência às melhores práticas"]}'::jsonb,
  'Na ausência de evidências internas, complementar com entrevistas, dados públicos, informações de mercado e benchmarks, registrando o grau de confiança da conclusão.',
  requirements.absence_impact,
  requirements.display_order
from version
join requirements on true
join public.sparks_checklist_template_items axis
  on axis.template_version_id = version.id
 and axis.code = requirements.axis_code
on conflict (template_version_id, code) do update
set
  parent_item_id = excluded.parent_item_id,
  name = excluded.name,
  evidence_importance = excluded.evidence_importance,
  is_required = excluded.is_required,
  possible_evidences = excluded.possible_evidences,
  best_practice_criteria = excluded.best_practice_criteria,
  benchmark_guidance = excluded.benchmark_guidance,
  absence_impact = excluded.absence_impact,
  display_order = excluded.display_order;

-- ============================================================
-- 4. FUNÇÕES OPERACIONAIS
-- ============================================================

create or replace function public.get_sparks_checklist_templates()
returns table (
  template_id uuid,
  template_code text,
  template_name text,
  version_id uuid,
  version_code text,
  version_name text,
  applicability_rule jsonb,
  item_count bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    template.id,
    template.code,
    template.name,
    version.id,
    version.version_code,
    version.name,
    version.applicability_rule,
    count(item.id)
  from public.sparks_checklist_templates template
  join public.sparks_checklist_template_versions version
    on version.template_id = template.id
   and version.status = 'published'
  left join public.sparks_checklist_template_items item
    on item.template_version_id = version.id
  where template.active = true
  group by
    template.id,
    template.code,
    template.name,
    version.id,
    version.version_code,
    version.name,
    version.applicability_rule
  order by template.name, version.version_code desc;
$$;

create or replace function public.register_sparks_evidence_asset(
  target_organization_id uuid,
  evidence_title text,
  evidence_description text,
  target_evidence_type text,
  target_source_type text,
  target_origin_module_code text,
  target_reference_date date,
  target_validity_date date,
  target_confidentiality_level text,
  target_content_hash text,
  target_file_name text,
  target_mime_type text,
  target_file_size_bytes bigint,
  target_storage_bucket text,
  target_storage_path text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  asset_id uuid;
  version_id uuid;
begin
  if not public.can_manage_skpe_evidence_checklist(target_organization_id) then
    raise exception 'Acesso administrativo necessário para cadastrar evidências.';
  end if;

  if length(trim(coalesce(evidence_title, ''))) = 0 then
    raise exception 'Informe o título da evidência.';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if target_content_hash is not null then
    select evidence.id
      into asset_id
    from public.sparks_evidence_assets evidence
    where evidence.organization_id = target_organization_id
      and evidence.content_hash = target_content_hash
      and evidence.archived_at is null
    limit 1;
  end if;

  if asset_id is not null then
    return asset_id;
  end if;

  insert into public.sparks_evidence_assets (
    organization_id,
    title,
    description,
    evidence_type,
    source_type,
    origin_module_code,
    reference_date,
    validity_date,
    confidentiality_level,
    content_hash,
    created_by,
    updated_by,
    metadata
  ) values (
    target_organization_id,
    trim(evidence_title),
    nullif(trim(coalesce(evidence_description, '')), ''),
    target_evidence_type,
    coalesce(target_source_type, 'internal'),
    target_origin_module_code,
    target_reference_date,
    target_validity_date,
    coalesce(target_confidentiality_level, 'internal'),
    target_content_hash,
    auth.uid(),
    auth.uid(),
    jsonb_build_object('creation_reason', trim(change_reason))
  )
  returning id into asset_id;

  if target_file_name is not null then
    insert into public.sparks_evidence_versions (
      evidence_asset_id,
      version_number,
      version_label,
      storage_bucket,
      storage_path,
      file_name,
      mime_type,
      file_size_bytes,
      content_hash,
      change_summary,
      created_by
    ) values (
      asset_id,
      1,
      '1.0',
      target_storage_bucket,
      target_storage_path,
      target_file_name,
      target_mime_type,
      target_file_size_bytes,
      target_content_hash,
      trim(change_reason),
      auth.uid()
    )
    returning id into version_id;

    update public.sparks_evidence_assets
       set current_version_id = version_id
     where id = asset_id;
  end if;

  return asset_id;
end;
$$;

create or replace function public.link_sparks_evidence(
  target_organization_id uuid,
  target_evidence_asset_id uuid,
  target_module_code text,
  target_type text,
  target_id uuid,
  target_usage_purpose text,
  target_relevance_level text,
  target_is_primary boolean,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  link_id uuid;
begin
  if not public.can_manage_skpe_evidence_checklist(target_organization_id) then
    raise exception 'Acesso administrativo necessário para vincular evidências.';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if not exists (
    select 1
    from public.sparks_evidence_assets evidence
    where evidence.id = target_evidence_asset_id
      and evidence.organization_id = target_organization_id
      and evidence.archived_at is null
  ) then
    raise exception 'Evidência não encontrada para a organização informada.';
  end if;

  insert into public.sparks_evidence_links (
    organization_id,
    evidence_asset_id,
    module_code,
    target_type,
    target_id,
    usage_purpose,
    relevance_level,
    is_primary,
    created_by,
    metadata
  ) values (
    target_organization_id,
    target_evidence_asset_id,
    trim(target_module_code),
    trim(target_type),
    target_id,
    target_usage_purpose,
    coalesce(target_relevance_level, 'important'),
    coalesce(target_is_primary, false),
    auth.uid(),
    jsonb_build_object('link_reason', trim(change_reason))
  )
  on conflict (evidence_asset_id, module_code, target_type, target_id)
  do update set
    usage_status = 'active',
    usage_purpose = excluded.usage_purpose,
    relevance_level = excluded.relevance_level,
    is_primary = excluded.is_primary,
    notes = trim(change_reason)
  returning id into link_id;

  return link_id;
end;
$$;

-- ============================================================
-- 5. RLS E PERMISSÕES
-- ============================================================

alter table public.sparks_evidence_assets enable row level security;
alter table public.sparks_evidence_versions enable row level security;
alter table public.sparks_evidence_links enable row level security;
alter table public.sparks_evidence_usage_assessments enable row level security;
alter table public.sparks_checklist_templates enable row level security;
alter table public.sparks_checklist_template_versions enable row level security;
alter table public.sparks_checklist_template_items enable row level security;

create policy sparks_evidence_assets_select
on public.sparks_evidence_assets
for select to authenticated
using (
  public.can_view_skpe_evidence_checklist(organization_id)
);

create policy sparks_evidence_assets_manage
on public.sparks_evidence_assets
for all to authenticated
using (public.can_manage_skpe_evidence_checklist(organization_id))
with check (public.can_manage_skpe_evidence_checklist(organization_id));

create policy sparks_evidence_versions_select
on public.sparks_evidence_versions
for select to authenticated
using (
  exists (
    select 1
    from public.sparks_evidence_assets evidence
    where evidence.id = evidence_asset_id
      and (
        public.can_view_skpe_evidence_checklist(evidence.organization_id)
      )
  )
);

create policy sparks_evidence_versions_manage
on public.sparks_evidence_versions
for all to authenticated
using (
  exists (
    select 1
    from public.sparks_evidence_assets evidence
    where evidence.id = evidence_asset_id
      and public.can_manage_skpe_evidence_checklist(evidence.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.sparks_evidence_assets evidence
    where evidence.id = evidence_asset_id
      and public.can_manage_skpe_evidence_checklist(evidence.organization_id)
  )
);

create policy sparks_evidence_links_select
on public.sparks_evidence_links
for select to authenticated
using (
  public.can_view_skpe_evidence_checklist(organization_id)
);

create policy sparks_evidence_links_manage
on public.sparks_evidence_links
for all to authenticated
using (public.can_manage_skpe_evidence_checklist(organization_id))
with check (public.can_manage_skpe_evidence_checklist(organization_id));

create policy sparks_evidence_usage_assessments_select
on public.sparks_evidence_usage_assessments
for select to authenticated
using (
  exists (
    select 1
    from public.sparks_evidence_links link
    where link.id = evidence_link_id
      and (
        public.can_view_skpe_evidence_checklist(link.organization_id)
      )
  )
);

create policy sparks_evidence_usage_assessments_manage
on public.sparks_evidence_usage_assessments
for all to authenticated
using (
  exists (
    select 1
    from public.sparks_evidence_links link
    where link.id = evidence_link_id
      and public.can_manage_skpe_evidence_checklist(link.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.sparks_evidence_links link
    where link.id = evidence_link_id
      and public.can_manage_skpe_evidence_checklist(link.organization_id)
  )
);

create policy sparks_checklist_templates_read
on public.sparks_checklist_templates
for select to authenticated
using (active = true);

create policy sparks_checklist_template_versions_read
on public.sparks_checklist_template_versions
for select to authenticated
using (status = 'published');

create policy sparks_checklist_template_items_read
on public.sparks_checklist_template_items
for select to authenticated
using (
  exists (
    select 1
    from public.sparks_checklist_template_versions version
    where version.id = template_version_id
      and version.status = 'published'
  )
);

revoke all on table public.sparks_evidence_assets from anon;
revoke all on table public.sparks_evidence_versions from anon;
revoke all on table public.sparks_evidence_links from anon;
revoke all on table public.sparks_evidence_usage_assessments from anon;
revoke all on table public.sparks_checklist_templates from anon;
revoke all on table public.sparks_checklist_template_versions from anon;
revoke all on table public.sparks_checklist_template_items from anon;

grant select on public.sparks_evidence_assets to authenticated, service_role;
grant select on public.sparks_evidence_versions to authenticated, service_role;
grant select on public.sparks_evidence_links to authenticated, service_role;
grant select on public.sparks_evidence_usage_assessments to authenticated, service_role;
grant select on public.sparks_checklist_templates to authenticated, service_role;
grant select on public.sparks_checklist_template_versions to authenticated, service_role;
grant select on public.sparks_checklist_template_items to authenticated, service_role;

grant all on public.sparks_evidence_assets to service_role;
grant all on public.sparks_evidence_versions to service_role;
grant all on public.sparks_evidence_links to service_role;
grant all on public.sparks_evidence_usage_assessments to service_role;
grant all on public.sparks_checklist_templates to service_role;
grant all on public.sparks_checklist_template_versions to service_role;
grant all on public.sparks_checklist_template_items to service_role;

revoke all on function public.get_sparks_checklist_templates() from public, anon;
revoke all on function public.register_sparks_evidence_asset(uuid,text,text,text,text,text,date,date,text,text,text,text,bigint,text,text,text) from public, anon;
revoke all on function public.link_sparks_evidence(uuid,uuid,text,text,uuid,text,text,boolean,text) from public, anon;

grant execute on function public.get_sparks_checklist_templates() to authenticated, service_role;
grant execute on function public.register_sparks_evidence_asset(uuid,text,text,text,text,text,date,date,text,text,text,text,bigint,text,text,text) to authenticated, service_role;
grant execute on function public.link_sparks_evidence(uuid,uuid,text,text,uuid,text,text,boolean,text) to authenticated, service_role;

commit;
