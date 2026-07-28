-- ============================================================
-- Plataforma SPARKs / SK-PE
-- Migration: Iniciativas, BMC/VPC organizacional e inteligência
--            do checklist da PEM-00
-- Idioma dos conteúdos funcionais: Português do Brasil
-- ============================================================

begin;

-- ============================================================
-- 1. PERMISSÕES
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
  module.id,
  permission_data.code,
  permission_data.name,
  permission_data.description,
  permission_data.permission_group,
  true
from public.modules module
cross join (
  values
    (
      'initiatives.view',
      'Consultar iniciativas',
      'Permite consultar o painel, os indicadores e os detalhes das iniciativas estratégicas, operacionais e de processos.',
      'initiatives'
    ),
    (
      'initiatives.manage',
      'Gerenciar iniciativas',
      'Permite criar, alterar, priorizar, vincular e acompanhar iniciativas.',
      'initiatives'
    ),
    (
      'business_artifacts.view',
      'Consultar BMC e VPC',
      'Permite consultar os artefatos BMC e VPC organizacionais integrados ao planejamento estratégico.',
      'business_artifacts'
    ),
    (
      'business_artifacts.manage',
      'Gerenciar BMC e VPC',
      'Permite importar, estruturar, versionar e vincular BMC e VPC ao planejamento estratégico.',
      'business_artifacts'
    ),
    (
      'evidence_checklist.view',
      'Consultar checklist e evidências',
      'Permite consultar o checklist dinâmico, suas evidências e avaliações de atendimento.',
      'evidence_checklist'
    ),
    (
      'evidence_checklist.manage',
      'Gerenciar checklist e evidências',
      'Permite solicitar, receber, avaliar e acompanhar evidências vinculadas aos itens do checklist da PEM-00.',
      'evidence_checklist'
    )
) as permission_data(code, name, description, permission_group)
where module.code = 'SK-PE'
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
  role.id,
  permission.id
from public.module_roles role
join public.modules module
  on module.id = role.module_id
join public.module_permissions permission
  on permission.module_id = module.id
where module.code = 'SK-PE'
  and (
    (
      role.code in ('administrator', 'manager', 'editor')
      and permission.code in (
        'initiatives.view',
        'initiatives.manage',
        'business_artifacts.view',
        'business_artifacts.manage',
        'evidence_checklist.view',
        'evidence_checklist.manage'
      )
    )
    or
    (
      role.code in ('approver', 'viewer')
      and permission.code in (
        'initiatives.view',
        'business_artifacts.view',
        'evidence_checklist.view'
      )
    )
  )
on conflict do nothing;

-- ============================================================
-- 2. INICIATIVAS
-- ============================================================

create table public.skpe_initiatives (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  parent_initiative_id uuid
    references public.skpe_initiatives(id) on delete set null,
  linked_journey_item_id uuid
    references public.skpe_journey_items(id) on delete set null,
  code text not null,
  name text not null,
  description text,
  initiative_type text not null,
  status text not null default 'proposed',
  priority text not null default 'medium',
  responsible_area text,
  owner_user_id uuid
    references public.profiles(id) on delete set null,
  sponsor_user_id uuid
    references public.profiles(id) on delete set null,
  start_date date,
  due_date date,
  completed_at timestamptz,
  progress numeric(5,2) not null default 0,
  planned_cost numeric(18,2),
  actual_cost numeric(18,2),
  planned_benefit numeric(18,2),
  realized_benefit numeric(18,2),
  risk_level text not null default 'not_assessed',
  last_update_at timestamptz,
  health_status text not null default 'not_assessed',
  strategic_theme text,
  source_type text not null default 'strategic_planning',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,

  constraint skpe_initiatives_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_initiatives_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_initiatives_type_check
    check (initiative_type in (
      'strategic_project',
      'operational_improvement',
      'process_initiative',
      'simple_action',
      'strategic_program'
    )),
  constraint skpe_initiatives_status_check
    check (status in (
      'proposed',
      'under_analysis',
      'approved',
      'planned',
      'in_progress',
      'on_hold',
      'blocked',
      'completed',
      'cancelled',
      'archived'
    )),
  constraint skpe_initiatives_priority_check
    check (priority in ('low', 'medium', 'high', 'critical')),
  constraint skpe_initiatives_progress_check
    check (progress between 0 and 100),
  constraint skpe_initiatives_risk_check
    check (risk_level in ('not_assessed', 'low', 'medium', 'high', 'critical')),
  constraint skpe_initiatives_health_check
    check (health_status in ('not_assessed', 'on_track', 'attention', 'critical', 'completed')),
  constraint skpe_initiatives_costs_check
    check (
      coalesce(planned_cost, 0) >= 0
      and coalesce(actual_cost, 0) >= 0
      and coalesce(planned_benefit, 0) >= 0
      and coalesce(realized_benefit, 0) >= 0
    ),
  constraint skpe_initiatives_dates_check
    check (due_date is null or start_date is null or due_date >= start_date),
  constraint skpe_initiatives_unique_code
    unique (project_id, code)
);

comment on table public.skpe_initiatives is
  'Iniciativas estratégicas, melhorias operacionais, iniciativas de processos, ações simples e programas vinculados ao SK-PE.';

create index idx_skpe_initiatives_dashboard
  on public.skpe_initiatives(
    organization_id,
    project_id,
    initiative_type,
    status,
    priority
  )
  where archived_at is null;

create index idx_skpe_initiatives_area
  on public.skpe_initiatives(organization_id, responsible_area)
  where archived_at is null;

create index idx_skpe_initiatives_owner
  on public.skpe_initiatives(owner_user_id)
  where archived_at is null;

create trigger skpe_initiatives_set_updated_at
before update on public.skpe_initiatives
for each row
execute function public.set_updated_at();

-- ============================================================
-- 3. OBJETIVOS ESTRATÉGICOS — OKRs E VÍNCULOS
-- ============================================================

create table public.skpe_strategic_objectives (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  management_model text not null default 'simplified',
  perspective_code text,
  strategic_theme text,
  horizon_start date,
  horizon_end date,
  owner_user_id uuid
    references public.profiles(id) on delete set null,
  status text not null default 'draft',
  progress numeric(5,2) not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategic_objectives_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_strategic_objectives_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_strategic_objectives_model_check
    check (management_model in ('simplified', 'bsc', 'okr', 'hybrid')),
  constraint skpe_strategic_objectives_status_check
    check (status in ('draft', 'active', 'completed', 'suspended', 'archived')),
  constraint skpe_strategic_objectives_progress_check
    check (progress between 0 and 100),
  constraint skpe_strategic_objectives_unique_code
    unique (project_id, code)
);

comment on table public.skpe_strategic_objectives is
  'Objetivos Estratégicos — OKRs, compatíveis com modelos simplificado, BSC, OKRs ou híbrido.';

create index idx_skpe_strategic_objectives_project
  on public.skpe_strategic_objectives(project_id, status);

create trigger skpe_strategic_objectives_set_updated_at
before update on public.skpe_strategic_objectives
for each row
execute function public.set_updated_at();

create table public.skpe_initiative_objectives (
  initiative_id uuid not null
    references public.skpe_initiatives(id) on delete cascade,
  strategic_objective_id uuid not null
    references public.skpe_strategic_objectives(id) on delete cascade,
  contribution_type text not null default 'direct',
  contribution_weight numeric(5,2),
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  primary key (initiative_id, strategic_objective_id),
  constraint skpe_initiative_objectives_type_check
    check (contribution_type in ('direct', 'supporting', 'enabling')),
  constraint skpe_initiative_objectives_weight_check
    check (contribution_weight is null or contribution_weight between 0 and 100)
);

-- ============================================================
-- 4. INSTRUMENTOS CONTEXTUAIS DAS INICIATIVAS
-- ============================================================

create table public.skpe_initiative_instruments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  initiative_id uuid not null
    references public.skpe_initiatives(id) on delete cascade,
  instrument_type text not null,
  instrument_reference_id uuid,
  instrument_code text,
  status text not null default 'active',
  is_primary boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_initiative_instruments_type_check
    check (instrument_type in (
      'project_canvas',
      'sipoc_canvas',
      'action_plan',
      'program_canvas',
      'other'
    )),
  constraint skpe_initiative_instruments_status_check
    check (status in ('active', 'draft', 'archived')),
  constraint skpe_initiative_instruments_unique
    unique (initiative_id, instrument_type, instrument_reference_id)
);

comment on table public.skpe_initiative_instruments is
  'Instrumentos contextuais associados às iniciativas, como Canvas do Projeto, SIPOC Canvas e Plano de Ação.';

create index idx_skpe_initiative_instruments_initiative
  on public.skpe_initiative_instruments(initiative_id, status);

create trigger skpe_initiative_instruments_set_updated_at
before update on public.skpe_initiative_instruments
for each row
execute function public.set_updated_at();

-- ============================================================
-- 5. BMC E VPC ORGANIZACIONAIS / INTEGRAÇÃO SK-PN
-- ============================================================

create table public.skpe_business_artifacts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid
    references public.skpe_projects(id) on delete cascade,
  artifact_type text not null,
  code text not null,
  name text not null,
  description text,
  source_module text not null default 'external',
  source_reference_id uuid,
  source_reference_code text,
  source_file_name text,
  source_storage_path text,
  source_mime_type text,
  import_method text not null default 'manual',
  version_number integer not null default 1,
  status text not null default 'draft',
  is_current boolean not null default true,
  reference_date date,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,

  constraint skpe_business_artifacts_type_check
    check (artifact_type in ('bmc', 'vpc_external', 'vpc_cooperative_member', 'vpc_consolidated')),
  constraint skpe_business_artifacts_source_check
    check (source_module in ('SK-PN', 'SK-PE', 'external')),
  constraint skpe_business_artifacts_import_check
    check (import_method in ('native_integration', 'structured_import', 'file_import', 'manual')),
  constraint skpe_business_artifacts_status_check
    check (status in ('draft', 'under_review', 'validated', 'outdated', 'archived')),
  constraint skpe_business_artifacts_version_check
    check (version_number > 0),
  constraint skpe_business_artifacts_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_business_artifacts_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_business_artifacts_unique_version
    unique (organization_id, artifact_type, code, version_number)
);

comment on table public.skpe_business_artifacts is
  'BMC e VPC organizacionais importados do SK-PN ou de fontes externas e utilizados como evidências estruturadas no SK-PE.';

create unique index skpe_business_artifacts_one_current
  on public.skpe_business_artifacts(organization_id, artifact_type, code)
  where is_current = true and archived_at is null;

create index idx_skpe_business_artifacts_project
  on public.skpe_business_artifacts(project_id, artifact_type, status)
  where archived_at is null;

create trigger skpe_business_artifacts_set_updated_at
before update on public.skpe_business_artifacts
for each row
execute function public.set_updated_at();

create table public.skpe_business_artifact_blocks (
  id uuid primary key default gen_random_uuid(),
  artifact_id uuid not null
    references public.skpe_business_artifacts(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  guidance text,
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_business_artifact_blocks_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_business_artifact_blocks_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_business_artifact_blocks_unique
    unique (artifact_id, code)
);

create index idx_skpe_business_artifact_blocks_artifact
  on public.skpe_business_artifact_blocks(artifact_id, display_order);

create trigger skpe_business_artifact_blocks_set_updated_at
before update on public.skpe_business_artifact_blocks
for each row
execute function public.set_updated_at();

create table public.skpe_business_artifact_items (
  id uuid primary key default gen_random_uuid(),
  block_id uuid not null
    references public.skpe_business_artifact_blocks(id) on delete cascade,
  content text not null,
  description text,
  item_type text not null default 'statement',
  priority text not null default 'medium',
  validation_status text not null default 'not_assessed',
  linked_journey_item_id uuid
    references public.skpe_journey_items(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  display_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_business_artifact_items_content_not_blank
    check (length(trim(content)) > 0),
  constraint skpe_business_artifact_items_type_check
    check (item_type in ('statement', 'hypothesis', 'evidence', 'decision', 'risk', 'opportunity')),
  constraint skpe_business_artifact_items_priority_check
    check (priority in ('low', 'medium', 'high', 'critical')),
  constraint skpe_business_artifact_items_validation_check
    check (validation_status in ('not_assessed', 'pending', 'validated', 'rejected', 'outdated'))
);

create index idx_skpe_business_artifact_items_block
  on public.skpe_business_artifact_items(block_id, display_order);

create trigger skpe_business_artifact_items_set_updated_at
before update on public.skpe_business_artifact_items
for each row
execute function public.set_updated_at();

create table public.skpe_business_artifact_links (
  id uuid primary key default gen_random_uuid(),
  artifact_id uuid not null
    references public.skpe_business_artifacts(id) on delete cascade,
  artifact_item_id uuid
    references public.skpe_business_artifact_items(id) on delete cascade,
  link_type text not null,
  target_id uuid not null,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint skpe_business_artifact_links_type_check
    check (link_type in (
      'journey_item',
      'strategic_objective',
      'initiative',
      'finding',
      'evidence_source'
    )),
  constraint skpe_business_artifact_links_unique
    unique (artifact_id, artifact_item_id, link_type, target_id)
);

-- ============================================================
-- 6. CHECKLIST DINÂMICO DA PEM-00
-- ============================================================

create table public.skpe_evidence_checklists (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  template_code text,
  organization_profile_snapshot jsonb not null default '{}'::jsonb,
  status text not null default 'draft',
  issued_at timestamptz,
  due_date date,
  completion_percentage numeric(5,2) not null default 0,
  readiness_score numeric(5,2),
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_evidence_checklists_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_evidence_checklists_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_evidence_checklists_status_check
    check (status in ('draft', 'issued', 'in_collection', 'under_review', 'completed', 'archived')),
  constraint skpe_evidence_checklists_completion_check
    check (completion_percentage between 0 and 100),
  constraint skpe_evidence_checklists_readiness_check
    check (readiness_score is null or readiness_score between 0 and 100),
  constraint skpe_evidence_checklists_unique_code
    unique (project_id, code)
);

comment on table public.skpe_evidence_checklists is
  'Checklists dinâmicos da PEM-00 gerados conforme tipo, natureza, ramo, porte e maturidade da organização.';

create index idx_skpe_evidence_checklists_project
  on public.skpe_evidence_checklists(project_id, status);

create trigger skpe_evidence_checklists_set_updated_at
before update on public.skpe_evidence_checklists
for each row
execute function public.set_updated_at();

create table public.skpe_evidence_checklist_items (
  id uuid primary key default gen_random_uuid(),
  checklist_id uuid not null
    references public.skpe_evidence_checklists(id) on delete cascade,
  journey_item_id uuid
    references public.skpe_journey_items(id) on delete set null,
  parent_item_id uuid
    references public.skpe_evidence_checklist_items(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  request_reason text,
  applicability_rule jsonb not null default '{}'::jsonb,
  is_required boolean not null default false,
  is_applicable boolean not null default true,
  responsible_area text,
  responsible_user_id uuid
    references public.profiles(id) on delete set null,
  due_date date,
  collection_status text not null default 'not_requested',
  assessment_status text not null default 'not_assessed',
  compliance_level integer,
  quality_score numeric(5,2),
  completeness_score numeric(5,2),
  currentness_score numeric(5,2),
  reliability_score numeric(5,2),
  overall_score numeric(5,2),
  strengths text,
  gaps text,
  risks text,
  recommendations text,
  analyst_notes text,
  last_assessed_at timestamptz,
  assessed_by uuid references public.profiles(id) on delete set null,
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_evidence_checklist_items_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_evidence_checklist_items_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_evidence_checklist_items_collection_check
    check (collection_status in (
      'not_requested',
      'requested',
      'partially_received',
      'received',
      'under_review',
      'needs_complement',
      'not_applicable',
      'closed'
    )),
  constraint skpe_evidence_checklist_items_assessment_check
    check (assessment_status in (
      'not_assessed',
      'not_met',
      'partially_met',
      'met',
      'good_practice',
      'mature_practice',
      'not_applicable'
    )),
  constraint skpe_evidence_checklist_items_compliance_check
    check (compliance_level is null or compliance_level between 0 and 5),
  constraint skpe_evidence_checklist_items_scores_check
    check (
      (quality_score is null or quality_score between 0 and 100)
      and (completeness_score is null or completeness_score between 0 and 100)
      and (currentness_score is null or currentness_score between 0 and 100)
      and (reliability_score is null or reliability_score between 0 and 100)
      and (overall_score is null or overall_score between 0 and 100)
    ),
  constraint skpe_evidence_checklist_items_unique_code
    unique (checklist_id, code)
);

comment on table public.skpe_evidence_checklist_items is
  'Itens do checklist da PEM-00 com coleta de múltiplas evidências e avaliação frente às melhores práticas.';

create index idx_skpe_evidence_checklist_items_checklist
  on public.skpe_evidence_checklist_items(checklist_id, display_order);

create index idx_skpe_evidence_checklist_items_status
  on public.skpe_evidence_checklist_items(checklist_id, collection_status, assessment_status);

create trigger skpe_evidence_checklist_items_set_updated_at
before update on public.skpe_evidence_checklist_items
for each row
execute function public.set_updated_at();

create table public.skpe_evidence_checklist_item_files (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  checklist_item_id uuid not null
    references public.skpe_evidence_checklist_items(id) on delete cascade,
  evidence_source_id uuid
    references public.skpe_evidence_sources(id) on delete set null,
  skdoc_document_id uuid,
  storage_bucket text,
  storage_path text,
  file_name text not null,
  mime_type text,
  file_size_bytes bigint,
  document_date date,
  reference_period_start date,
  reference_period_end date,
  version_label text,
  validation_status text not null default 'pending',
  confidentiality_level text not null default 'internal',
  uploaded_at timestamptz not null default timezone('utc', now()),
  uploaded_by uuid references public.profiles(id) on delete set null,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  notes text,
  metadata jsonb not null default '{}'::jsonb,

  constraint skpe_evidence_checklist_item_files_name_not_blank
    check (length(trim(file_name)) > 0),
  constraint skpe_evidence_checklist_item_files_size_check
    check (file_size_bytes is null or file_size_bytes >= 0),
  constraint skpe_evidence_checklist_item_files_validation_check
    check (validation_status in ('pending', 'under_review', 'validated', 'rejected', 'outdated')),
  constraint skpe_evidence_checklist_item_files_confidentiality_check
    check (confidentiality_level in ('public', 'internal', 'restricted', 'confidential')),
  constraint skpe_evidence_checklist_item_files_period_check
    check (
      reference_period_end is null
      or reference_period_start is null
      or reference_period_end >= reference_period_start
    )
);

comment on table public.skpe_evidence_checklist_item_files is
  'Arquivos e documentos vinculados aos itens do checklist, com referência futura ao SK-DOC.';

create index idx_skpe_evidence_checklist_item_files_item
  on public.skpe_evidence_checklist_item_files(checklist_item_id, validation_status);

create index idx_skpe_evidence_checklist_item_files_skdoc
  on public.skpe_evidence_checklist_item_files(skdoc_document_id)
  where skdoc_document_id is not null;

create table public.skpe_evidence_checklist_assessments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  checklist_item_id uuid not null
    references public.skpe_evidence_checklist_items(id) on delete cascade,
  assessment_version integer not null default 1,
  compliance_level integer not null,
  quality_score numeric(5,2),
  completeness_score numeric(5,2),
  currentness_score numeric(5,2),
  reliability_score numeric(5,2),
  overall_score numeric(5,2),
  strengths text,
  gaps text,
  risks text,
  recommendations text,
  assessment_basis text,
  assessed_at timestamptz not null default timezone('utc', now()),
  assessed_by uuid not null references public.profiles(id) on delete restrict,
  metadata jsonb not null default '{}'::jsonb,

  constraint skpe_evidence_checklist_assessments_level_check
    check (compliance_level between 0 and 5),
  constraint skpe_evidence_checklist_assessments_scores_check
    check (
      (quality_score is null or quality_score between 0 and 100)
      and (completeness_score is null or completeness_score between 0 and 100)
      and (currentness_score is null or currentness_score between 0 and 100)
      and (reliability_score is null or reliability_score between 0 and 100)
      and (overall_score is null or overall_score between 0 and 100)
    ),
  constraint skpe_evidence_checklist_assessments_unique_version
    unique (checklist_item_id, assessment_version)
);

comment on table public.skpe_evidence_checklist_assessments is
  'Histórico versionado das avaliações dos itens do checklist frente às melhores práticas.';

create index idx_skpe_evidence_checklist_assessments_item
  on public.skpe_evidence_checklist_assessments(checklist_item_id, assessment_version desc);

-- ============================================================
-- 7. FUNÇÕES DE AUTORIZAÇÃO
-- ============================================================

create or replace function public.can_view_skpe_initiatives(
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
      'initiatives.view'
    );
$$;

create or replace function public.can_manage_skpe_initiatives(
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
      'initiatives.manage'
    );
$$;

create or replace function public.can_view_skpe_business_artifacts(
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
      'business_artifacts.view'
    );
$$;

create or replace function public.can_manage_skpe_business_artifacts(
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
      'business_artifacts.manage'
    );
$$;

create or replace function public.can_view_skpe_evidence_checklist(
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
      'evidence_checklist.view'
    );
$$;

create or replace function public.can_manage_skpe_evidence_checklist(
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
      'evidence_checklist.manage'
    );
$$;

-- ============================================================
-- 8. PAINEL GERENCIAL DE INICIATIVAS
-- ============================================================

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
  with filtered as (
    select distinct initiative.*
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
    count(*) filter (where status in ('proposed', 'under_analysis'))::bigint,
    count(*) filter (where status = 'in_progress')::bigint,
    count(*) filter (where status = 'completed')::bigint,
    count(*) filter (
      where due_date < current_date
        and status not in ('completed', 'cancelled', 'archived')
    )::bigint,
    count(*) filter (where status = 'blocked')::bigint,
    count(*) filter (
      where priority = 'critical'
         or risk_level = 'critical'
         or health_status = 'critical'
    )::bigint,
    count(*) filter (where owner_user_id is null)::bigint,
    count(*) filter (
      where status not in ('completed', 'cancelled', 'archived')
        and coalesce(last_update_at, updated_at, created_at)
          < timezone('utc', now()) - interval '30 days'
    )::bigint,
    count(*) filter (
      where exists (
        select 1
        from public.skpe_initiative_instruments instrument
        where instrument.initiative_id = filtered.id
          and instrument.status <> 'archived'
      )
    )::bigint,
    count(*) filter (
      where not exists (
        select 1
        from public.skpe_initiative_instruments instrument
        where instrument.initiative_id = filtered.id
          and instrument.status <> 'archived'
      )
    )::bigint,
    coalesce(round(avg(progress), 2), 0)::numeric,
    coalesce(sum(planned_cost), 0)::numeric,
    coalesce(sum(actual_cost), 0)::numeric,
    coalesce(sum(planned_benefit), 0)::numeric,
    coalesce(sum(realized_benefit), 0)::numeric
  from filtered;
end;
$$;

create or replace function public.get_skpe_initiatives(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_initiative_type text default null,
  target_responsible_area text default null,
  target_strategic_objective_id uuid default null,
  target_status text default null
)
returns table (
  initiative_id uuid,
  project_id uuid,
  project_code text,
  initiative_code text,
  initiative_name text,
  initiative_description text,
  initiative_type text,
  initiative_status text,
  priority text,
  responsible_area text,
  owner_user_id uuid,
  owner_name text,
  start_date date,
  due_date date,
  progress numeric,
  risk_level text,
  health_status text,
  last_update_at timestamptz,
  delayed boolean,
  strategic_objectives jsonb,
  instruments jsonb
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
  select
    initiative.id,
    initiative.project_id,
    project.code,
    initiative.code,
    initiative.name,
    initiative.description,
    initiative.initiative_type,
    initiative.status,
    initiative.priority,
    initiative.responsible_area,
    initiative.owner_user_id,
    coalesce(owner.display_name, owner.full_name, owner.email),
    initiative.start_date,
    initiative.due_date,
    initiative.progress,
    initiative.risk_level,
    initiative.health_status,
    initiative.last_update_at,
    (
      initiative.due_date < current_date
      and initiative.status not in ('completed', 'cancelled', 'archived')
    ),
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', objective.id,
          'code', objective.code,
          'name', objective.name,
          'management_model', objective.management_model,
          'contribution_type', link.contribution_type,
          'contribution_weight', link.contribution_weight
        )
        order by objective.code
      )
      from public.skpe_initiative_objectives link
      join public.skpe_strategic_objectives objective
        on objective.id = link.strategic_objective_id
      where link.initiative_id = initiative.id
    ), '[]'::jsonb),
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', instrument.id,
          'type', instrument.instrument_type,
          'reference_id', instrument.instrument_reference_id,
          'code', instrument.instrument_code,
          'status', instrument.status,
          'is_primary', instrument.is_primary
        )
        order by instrument.is_primary desc, instrument.created_at
      )
      from public.skpe_initiative_instruments instrument
      where instrument.initiative_id = initiative.id
        and instrument.status <> 'archived'
    ), '[]'::jsonb)
  from public.skpe_initiatives initiative
  join public.skpe_projects project
    on project.id = initiative.project_id
  left join public.profiles owner
    on owner.id = initiative.owner_user_id
  where initiative.organization_id = target_organization_id
    and initiative.archived_at is null
    and (target_project_id is null or initiative.project_id = target_project_id)
    and (target_initiative_type is null or initiative.initiative_type = target_initiative_type)
    and (target_responsible_area is null or initiative.responsible_area = target_responsible_area)
    and (target_status is null or initiative.status = target_status)
    and (
      target_strategic_objective_id is null
      or exists (
        select 1
        from public.skpe_initiative_objectives objective_link
        where objective_link.initiative_id = initiative.id
          and objective_link.strategic_objective_id = target_strategic_objective_id
      )
    )
  order by
    case initiative.priority
      when 'critical' then 1
      when 'high' then 2
      when 'medium' then 3
      else 4
    end,
    initiative.due_date nulls last,
    initiative.name;
end;
$$;

-- ============================================================
-- 9. CONSULTAS DE BMC/VPC E CHECKLIST
-- ============================================================

create or replace function public.get_skpe_business_artifacts(
  target_organization_id uuid,
  target_project_id uuid default null
)
returns table (
  artifact_id uuid,
  artifact_type text,
  artifact_code text,
  artifact_name text,
  source_module text,
  import_method text,
  version_number integer,
  artifact_status text,
  is_current boolean,
  reference_date date,
  source_file_name text,
  blocks_count bigint,
  items_count bigint,
  linked_items_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_business_artifacts(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode consultar os artefatos BMC/VPC desta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    artifact.id,
    artifact.artifact_type,
    artifact.code,
    artifact.name,
    artifact.source_module,
    artifact.import_method,
    artifact.version_number,
    artifact.status,
    artifact.is_current,
    artifact.reference_date,
    artifact.source_file_name,
    count(distinct block.id)::bigint,
    count(distinct item.id)::bigint,
    count(distinct link.id)::bigint
  from public.skpe_business_artifacts artifact
  left join public.skpe_business_artifact_blocks block
    on block.artifact_id = artifact.id
  left join public.skpe_business_artifact_items item
    on item.block_id = block.id
  left join public.skpe_business_artifact_links link
    on link.artifact_id = artifact.id
  where artifact.organization_id = target_organization_id
    and artifact.archived_at is null
    and (target_project_id is null or artifact.project_id = target_project_id)
  group by artifact.id
  order by artifact.artifact_type, artifact.version_number desc;
end;
$$;

create or replace function public.get_skpe_evidence_checklist(
  target_organization_id uuid,
  target_project_id uuid
)
returns table (
  checklist_id uuid,
  checklist_code text,
  checklist_name text,
  checklist_status text,
  completion_percentage numeric,
  readiness_score numeric,
  item_id uuid,
  parent_item_id uuid,
  journey_item_id uuid,
  item_code text,
  item_name text,
  item_description text,
  request_reason text,
  is_required boolean,
  is_applicable boolean,
  responsible_area text,
  due_date date,
  collection_status text,
  assessment_status text,
  compliance_level integer,
  overall_score numeric,
  files_count bigint,
  validated_files_count bigint,
  strengths text,
  gaps text,
  risks text,
  recommendations text,
  display_order integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_evidence_checklist(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode consultar o checklist de evidências desta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    checklist.id,
    checklist.code,
    checklist.name,
    checklist.status,
    checklist.completion_percentage,
    checklist.readiness_score,
    item.id,
    item.parent_item_id,
    item.journey_item_id,
    item.code,
    item.name,
    item.description,
    item.request_reason,
    item.is_required,
    item.is_applicable,
    item.responsible_area,
    item.due_date,
    item.collection_status,
    item.assessment_status,
    item.compliance_level,
    item.overall_score,
    count(file.id)::bigint,
    count(file.id) filter (where file.validation_status = 'validated')::bigint,
    item.strengths,
    item.gaps,
    item.risks,
    item.recommendations,
    item.display_order
  from public.skpe_evidence_checklists checklist
  join public.skpe_evidence_checklist_items item
    on item.checklist_id = checklist.id
  left join public.skpe_evidence_checklist_item_files file
    on file.checklist_item_id = item.id
  where checklist.organization_id = target_organization_id
    and checklist.project_id = target_project_id
    and checklist.status <> 'archived'
  group by checklist.id, item.id
  order by checklist.created_at desc, item.display_order, item.code;
end;
$$;

-- ============================================================
-- 10. RLS
-- ============================================================

alter table public.skpe_initiatives enable row level security;
alter table public.skpe_strategic_objectives enable row level security;
alter table public.skpe_initiative_objectives enable row level security;
alter table public.skpe_initiative_instruments enable row level security;
alter table public.skpe_business_artifacts enable row level security;
alter table public.skpe_business_artifact_blocks enable row level security;
alter table public.skpe_business_artifact_items enable row level security;
alter table public.skpe_business_artifact_links enable row level security;
alter table public.skpe_evidence_checklists enable row level security;
alter table public.skpe_evidence_checklist_items enable row level security;
alter table public.skpe_evidence_checklist_item_files enable row level security;
alter table public.skpe_evidence_checklist_assessments enable row level security;

create policy skpe_initiatives_select
on public.skpe_initiatives
for select to authenticated
using (public.can_view_skpe_initiatives(organization_id));

create policy skpe_strategic_objectives_select
on public.skpe_strategic_objectives
for select to authenticated
using (public.can_view_skpe_initiatives(organization_id));

create policy skpe_initiative_objectives_select
on public.skpe_initiative_objectives
for select to authenticated
using (
  exists (
    select 1
    from public.skpe_initiatives initiative
    where initiative.id = skpe_initiative_objectives.initiative_id
      and public.can_view_skpe_initiatives(initiative.organization_id)
  )
);

create policy skpe_initiative_instruments_select
on public.skpe_initiative_instruments
for select to authenticated
using (public.can_view_skpe_initiatives(organization_id));

create policy skpe_business_artifacts_select
on public.skpe_business_artifacts
for select to authenticated
using (public.can_view_skpe_business_artifacts(organization_id));

create policy skpe_business_artifact_blocks_select
on public.skpe_business_artifact_blocks
for select to authenticated
using (
  exists (
    select 1
    from public.skpe_business_artifacts artifact
    where artifact.id = skpe_business_artifact_blocks.artifact_id
      and public.can_view_skpe_business_artifacts(artifact.organization_id)
  )
);

create policy skpe_business_artifact_items_select
on public.skpe_business_artifact_items
for select to authenticated
using (
  exists (
    select 1
    from public.skpe_business_artifact_blocks block
    join public.skpe_business_artifacts artifact
      on artifact.id = block.artifact_id
    where block.id = skpe_business_artifact_items.block_id
      and public.can_view_skpe_business_artifacts(artifact.organization_id)
  )
);

create policy skpe_business_artifact_links_select
on public.skpe_business_artifact_links
for select to authenticated
using (
  exists (
    select 1
    from public.skpe_business_artifacts artifact
    where artifact.id = skpe_business_artifact_links.artifact_id
      and public.can_view_skpe_business_artifacts(artifact.organization_id)
  )
);

create policy skpe_evidence_checklists_select
on public.skpe_evidence_checklists
for select to authenticated
using (public.can_view_skpe_evidence_checklist(organization_id));

create policy skpe_evidence_checklist_items_select
on public.skpe_evidence_checklist_items
for select to authenticated
using (
  exists (
    select 1
    from public.skpe_evidence_checklists checklist
    where checklist.id = skpe_evidence_checklist_items.checklist_id
      and public.can_view_skpe_evidence_checklist(checklist.organization_id)
  )
);

create policy skpe_evidence_checklist_item_files_select
on public.skpe_evidence_checklist_item_files
for select to authenticated
using (public.can_view_skpe_evidence_checklist(organization_id));

create policy skpe_evidence_checklist_assessments_select
on public.skpe_evidence_checklist_assessments
for select to authenticated
using (public.can_view_skpe_evidence_checklist(organization_id));

-- Escritas diretas permanecem bloqueadas. Serão realizadas por funções
-- controladas e auditadas nas próximas migrations operacionais.

-- ============================================================
-- 11. PRIVILÉGIOS
-- ============================================================

revoke all on table public.skpe_initiatives from anon;
revoke all on table public.skpe_strategic_objectives from anon;
revoke all on table public.skpe_initiative_objectives from anon;
revoke all on table public.skpe_initiative_instruments from anon;
revoke all on table public.skpe_business_artifacts from anon;
revoke all on table public.skpe_business_artifact_blocks from anon;
revoke all on table public.skpe_business_artifact_items from anon;
revoke all on table public.skpe_business_artifact_links from anon;
revoke all on table public.skpe_evidence_checklists from anon;
revoke all on table public.skpe_evidence_checklist_items from anon;
revoke all on table public.skpe_evidence_checklist_item_files from anon;
revoke all on table public.skpe_evidence_checklist_assessments from anon;

revoke all on function public.can_view_skpe_initiatives(uuid) from public, anon;
revoke all on function public.can_manage_skpe_initiatives(uuid) from public, anon;
revoke all on function public.can_view_skpe_business_artifacts(uuid) from public, anon;
revoke all on function public.can_manage_skpe_business_artifacts(uuid) from public, anon;
revoke all on function public.can_view_skpe_evidence_checklist(uuid) from public, anon;
revoke all on function public.can_manage_skpe_evidence_checklist(uuid) from public, anon;
revoke all on function public.get_skpe_initiatives_dashboard(uuid, uuid, text, text, uuid, text) from public, anon;
revoke all on function public.get_skpe_initiatives(uuid, uuid, text, text, uuid, text) from public, anon;
revoke all on function public.get_skpe_business_artifacts(uuid, uuid) from public, anon;
revoke all on function public.get_skpe_evidence_checklist(uuid, uuid) from public, anon;

grant execute on function public.can_view_skpe_initiatives(uuid) to authenticated, service_role;
grant execute on function public.can_manage_skpe_initiatives(uuid) to authenticated, service_role;
grant execute on function public.can_view_skpe_business_artifacts(uuid) to authenticated, service_role;
grant execute on function public.can_manage_skpe_business_artifacts(uuid) to authenticated, service_role;
grant execute on function public.can_view_skpe_evidence_checklist(uuid) to authenticated, service_role;
grant execute on function public.can_manage_skpe_evidence_checklist(uuid) to authenticated, service_role;
grant execute on function public.get_skpe_initiatives_dashboard(uuid, uuid, text, text, uuid, text) to authenticated, service_role;
grant execute on function public.get_skpe_initiatives(uuid, uuid, text, text, uuid, text) to authenticated, service_role;
grant execute on function public.get_skpe_business_artifacts(uuid, uuid) to authenticated, service_role;
grant execute on function public.get_skpe_evidence_checklist(uuid, uuid) to authenticated, service_role;

-- ============================================================
-- 12. REGISTRO DE DECISÕES DE ARQUITETURA
-- ============================================================

comment on table public.skpe_initiative_instruments is
  'O Canvas não integra o menu principal do SK-PE: é acessado no contexto da iniciativa à qual pertence.';

comment on column public.skpe_evidence_checklist_item_files.skdoc_document_id is
  'Referência futura ao documento oficial mantido pelo módulo transversal SK-DOC.';

comment on column public.skpe_business_artifacts.source_module is
  'Origem do artefato: integração nativa com SK-PN, construção no SK-PE ou importação externa.';

commit;
