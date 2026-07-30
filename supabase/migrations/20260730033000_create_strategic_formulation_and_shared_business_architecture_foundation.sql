-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-00 — Fundação Canônica da Formulação Estratégica e
--         da Arquitetura de Negócios Compartilhada
--
-- Princípios:
-- 1. Missão como base da estratégia.
-- 2. Valores como fundamentos inegociáveis e transversais.
-- 3. O SK-PE é autossuficiente para produzir os insumos essenciais
--    de negócio mesmo sem contratação do SK-PN.
-- 4. VPC, BMC, Cadeia de Valor e demais artefatos de negócio são
--    objetos compartilhados da Plataforma, não duplicados por módulo.
-- 5. O SK-PN poderá aprofundar os mesmos objetos segundo o rigor de
--    sua metodologia, preservando origem, versões e rastreabilidade.
-- 6. Formulações aprovadas preservam a versão e o snapshot dos
--    artefatos de negócio efetivamente utilizados.
-- 7. BSC estrutura a estratégia de longo prazo.
-- 8. KPIs e metas são desdobrados dos Objetivos Estratégicos.
-- 9. BMKs fundamentam metas sempre que aplicável.
-- 10. OKRs desdobram os OEs em ciclos de curto prazo.
-- 11. Cada Objetivo do OKR deve possuir no mínimo 3 KRs.
-- 12. Recomenda-se no mínimo 3 iniciativas por KR.
-- 13. Isolamento por organização, projeto e versão da formulação.
-- ============================================================

begin;

-- ============================================================
-- 1. PERMISSÕES DA FORMULAÇÃO ESTRATÉGICA
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
      'strategic_formulation.view',
      'Consultar Formulação Estratégica',
      'Permite consultar PMVV, insumos compartilhados do negócio, Temas, Mapa Estratégico, KPIs, metas, BMKs, OKRs e seus desdobramentos.',
      'strategic_formulation'
    ),
    (
      'strategic_formulation.manage',
      'Gerenciar Formulação Estratégica',
      'Permite criar e alterar versões em elaboração da Formulação Estratégica e seus componentes.',
      'strategic_formulation'
    ),
    (
      'strategic_formulation.validate',
      'Validar Formulação Estratégica',
      'Permite realizar a validação metodológica e organizacional da Formulação Estratégica.',
      'strategic_formulation'
    ),
    (
      'strategic_formulation.approve',
      'Aprovar Formulação Estratégica',
      'Permite aprovar, publicar e substituir versões da Formulação Estratégica.',
      'strategic_formulation'
    ),
    (
      'business_architecture.view',
      'Consultar Arquitetura de Negócios',
      'Permite consultar artefatos compartilhados como VPC, BMC, Cadeia de Valor e demais Canvas e insumos de negócio.',
      'business_architecture'
    ),
    (
      'business_architecture.manage',
      'Gerenciar Arquitetura de Negócios',
      'Permite criar e evoluir no SK-PE os insumos essenciais de negócio compartilháveis com o futuro SK-PN.',
      'business_architecture'
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
      role.code = 'administrator'
      and permission.code in (
        'strategic_formulation.view',
        'strategic_formulation.manage',
        'strategic_formulation.validate',
        'strategic_formulation.approve',
        'business_architecture.view',
        'business_architecture.manage'
      )
    )
    or
    (
      role.code = 'manager'
      and permission.code in (
        'strategic_formulation.view',
        'strategic_formulation.manage',
        'strategic_formulation.validate',
        'strategic_formulation.approve',
        'business_architecture.view',
        'business_architecture.manage'
      )
    )
    or
    (
      role.code = 'editor'
      and permission.code in (
        'strategic_formulation.view',
        'strategic_formulation.manage',
        'business_architecture.view',
        'business_architecture.manage'
      )
    )
    or
    (
      role.code = 'approver'
      and permission.code in (
        'strategic_formulation.view',
        'strategic_formulation.validate',
        'strategic_formulation.approve',
        'business_architecture.view'
      )
    )
    or
    (
      role.code in ('viewer', 'visitor')
      and permission.code in (
        'strategic_formulation.view',
        'business_architecture.view'
      )
    )
  )
on conflict do nothing;

-- ============================================================
-- 2. AUTORIZAÇÃO
-- ============================================================

create or replace function public.can_view_skpe_formulation(
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
      'strategic_formulation.view'
    );
$$;

create or replace function public.can_manage_skpe_formulation(
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
      'strategic_formulation.manage'
    );
$$;

create or replace function public.can_validate_skpe_formulation(
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
      'strategic_formulation.validate'
    );
$$;

create or replace function public.can_approve_skpe_formulation(
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
      'strategic_formulation.approve'
    );
$$;


create or replace function public.can_view_business_architecture(
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
      'business_architecture.view'
    )
    or public.has_module_permission(
      target_organization_id,
      'SK-PE',
      'strategic_formulation.view'
    )
    or public.has_module_permission(
      target_organization_id,
      'SK-PN',
      'business_architecture.view'
    );
$$;

create or replace function public.can_manage_business_architecture(
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
      'business_architecture.manage'
    )
    or public.has_module_permission(
      target_organization_id,
      'SK-PE',
      'strategic_formulation.manage'
    )
    or public.has_module_permission(
      target_organization_id,
      'SK-PN',
      'business_architecture.manage'
    );
$$;

comment on function public.can_view_business_architecture(uuid) is
  'Autoriza leitura dos artefatos compartilhados de negócio por SK-PE, SK-PN ou administração da organização.';

comment on function public.can_manage_business_architecture(uuid) is
  'Autoriza evolução dos artefatos compartilhados de negócio por SK-PE, SK-PN ou administração da organização.';

-- ============================================================
-- 3. VERSÕES DA FORMULAÇÃO ESTRATÉGICA
-- ============================================================

create table if not exists public.skpe_strategic_formulations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  version_number integer not null,
  version_label text not null,
  status text not null default 'draft',
  change_summary text,
  rationale text,
  valid_from date,
  valid_until date,
  derived_from_formulation_id uuid
    references public.skpe_strategic_formulations(id) on delete set null,
  approved_at timestamptz,
  approved_by uuid references public.profiles(id) on delete set null,
  superseded_at timestamptz,
  superseded_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategic_formulations_version_positive
    check (version_number > 0),
  constraint skpe_strategic_formulations_label_not_blank
    check (length(trim(version_label)) > 0),
  constraint skpe_strategic_formulations_status_check
    check (status in (
      'draft',
      'in_elaboration',
      'pending_validation',
      'validated',
      'pending_approval',
      'approved',
      'superseded',
      'archived'
    )),
  constraint skpe_strategic_formulations_dates_check
    check (valid_until is null or valid_from is null or valid_until >= valid_from),
  constraint skpe_strategic_formulations_unique_version
    unique (project_id, version_number),
  constraint skpe_strategic_formulations_identity_scope
    unique (id, organization_id, project_id)
);

comment on table public.skpe_strategic_formulations is
  'Versões controladas da Formulação Estratégica por organização e projeto. Versões aprovadas não devem ser sobrescritas.';

create unique index if not exists ux_skpe_strategic_formulations_open_version
  on public.skpe_strategic_formulations(project_id)
  where status in (
    'draft',
    'in_elaboration',
    'pending_validation',
    'validated',
    'pending_approval'
  );

create unique index if not exists ux_skpe_strategic_formulations_approved
  on public.skpe_strategic_formulations(project_id)
  where status = 'approved';

create index if not exists idx_skpe_strategic_formulations_scope
  on public.skpe_strategic_formulations(
    organization_id,
    project_id,
    status,
    version_number desc
  );

drop trigger if exists skpe_strategic_formulations_set_updated_at
  on public.skpe_strategic_formulations;

create trigger skpe_strategic_formulations_set_updated_at
before update on public.skpe_strategic_formulations
for each row
execute function public.set_updated_at();

-- ============================================================
-- 4. IDENTIDADE ESTRATÉGICA — PMVV
-- ============================================================

create table if not exists public.skpe_strategic_identity (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  status text not null default 'draft',
  coherence_statement text,
  validation_notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategic_identity_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_strategic_identity_status_check
    check (status in (
      'draft',
      'in_elaboration',
      'pending_validation',
      'validated',
      'approved',
      'rejected'
    )),
  constraint skpe_strategic_identity_unique
    unique (formulation_id),
  constraint skpe_strategic_identity_scope_unique
    unique (id, formulation_id, organization_id, project_id)
);

comment on table public.skpe_strategic_identity is
  'Pacote da Identidade Estratégica da versão: Propósito quando adotado, Missão, Visão e Valores.';

create table if not exists public.skpe_strategic_identity_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  strategic_identity_id uuid not null,
  element_type text not null,
  content text not null,
  rationale text,
  display_order integer not null default 100,
  validation_status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategic_identity_items_identity_fkey
    foreign key (
      strategic_identity_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_strategic_identity(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_strategic_identity_items_type_check
    check (element_type in ('purpose', 'mission', 'vision')),
  constraint skpe_strategic_identity_items_content_not_blank
    check (length(trim(content)) > 0),
  constraint skpe_strategic_identity_items_validation_check
    check (validation_status in (
      'draft',
      'pending_validation',
      'validated',
      'approved',
      'rejected'
    )),
  constraint skpe_strategic_identity_items_unique
    unique (formulation_id, element_type)
);

comment on table public.skpe_strategic_identity_items is
  'Elementos textuais do PMVV. O Propósito é opcional; Missão e Visão são obrigatórios para aprovação.';

create table if not exists public.skpe_strategic_values (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  strategic_identity_id uuid not null,
  code text not null,
  name text not null,
  description text not null,
  display_order integer not null default 100,
  status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategic_values_identity_fkey
    foreign key (
      strategic_identity_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_strategic_identity(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_strategic_values_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_strategic_values_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_strategic_values_description_not_blank
    check (length(trim(description)) > 0),
  constraint skpe_strategic_values_status_check
    check (status in ('draft', 'active', 'archived')),
  constraint skpe_strategic_values_unique
    unique (formulation_id, code),
  constraint skpe_strategic_values_scope_unique
    unique (id, formulation_id, organization_id, project_id)
);

comment on table public.skpe_strategic_values is
  'Valores organizacionais inegociáveis, com significado e comportamentos associados.';

create table if not exists public.skpe_strategic_value_behaviors (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  strategic_value_id uuid not null,
  behavior_type text not null,
  description text not null,
  display_order integer not null default 100,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategic_value_behaviors_value_fkey
    foreign key (
      strategic_value_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_strategic_values(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_strategic_value_behaviors_type_check
    check (behavior_type in ('expected', 'incompatible')),
  constraint skpe_strategic_value_behaviors_description_not_blank
    check (length(trim(description)) > 0)
);

comment on table public.skpe_strategic_value_behaviors is
  'Comportamentos esperados e incompatíveis que tornam os Valores verificáveis na prática.';

-- ============================================================
-- 5. ARQUITETURA DE NEGÓCIOS COMPARTILHADA — SK-PE / SK-PN
-- ============================================================

create table if not exists public.platform_business_artifacts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  artifact_type text not null,
  methodology_code text,
  status text not null default 'active',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint platform_business_artifacts_code_not_blank
    check (length(trim(code)) > 0),
  constraint platform_business_artifacts_name_not_blank
    check (length(trim(name)) > 0),
  constraint platform_business_artifacts_type_check
    check (artifact_type in (
      'business_foundation',
      'value_proposition_canvas',
      'business_model_canvas',
      'value_chain',
      'stakeholder_map',
      'product_service_portfolio',
      'market_analysis',
      'capability_map',
      'process_architecture',
      'financial_model',
      'risk_hypothesis_map',
      'other_canvas'
    )),
  constraint platform_business_artifacts_status_check
    check (status in ('active', 'inactive', 'archived')),
  constraint platform_business_artifacts_unique_code
    unique (organization_id, code),
  constraint platform_business_artifacts_scope_unique
    unique (id, organization_id)
);

comment on table public.platform_business_artifacts is
  'Cadastro canônico e compartilhado dos artefatos de negócio usados por SK-PE e SK-PN, sem duplicação por módulo.';

create table if not exists public.platform_business_artifact_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  artifact_id uuid not null,
  version_number integer not null,
  version_label text not null,
  methodology_version text,
  origin_module text not null,
  origin_service_type text not null default 'strategic_planning',
  source_entity_type text,
  source_entity_id uuid,
  source_skpe_project_id uuid
    references public.skpe_projects(id) on delete set null,
  maturity_level text not null default 'essential',
  completeness_percent numeric(5,2) not null default 0,
  status text not null default 'draft',
  summary text,
  content_payload jsonb not null default '{}'::jsonb,
  validation_notes text,
  derived_from_version_id uuid
    references public.platform_business_artifact_versions(id)
    on delete set null,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  published_at timestamptz,
  published_by uuid references public.profiles(id) on delete set null,
  superseded_at timestamptz,
  superseded_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint platform_business_artifact_versions_artifact_fkey
    foreign key (artifact_id, organization_id)
    references public.platform_business_artifacts(id, organization_id)
    on delete cascade,
  constraint platform_business_artifact_versions_number_positive
    check (version_number > 0),
  constraint platform_business_artifact_versions_label_not_blank
    check (length(trim(version_label)) > 0),
  constraint platform_business_artifact_versions_origin_module_check
    check (origin_module in ('SK-PE', 'SK-PN', 'PLATFORM', 'IMPORT')),
  constraint platform_business_artifact_versions_service_check
    check (origin_service_type in (
      'strategic_planning',
      'business_plan',
      'consulting',
      'assisted_practice',
      'import',
      'other'
    )),
  constraint platform_business_artifact_versions_maturity_check
    check (maturity_level in (
      'essential',
      'structured',
      'complete',
      'validated',
      'published'
    )),
  constraint platform_business_artifact_versions_completeness_check
    check (completeness_percent between 0 and 100),
  constraint platform_business_artifact_versions_status_check
    check (status in (
      'draft',
      'in_elaboration',
      'pending_validation',
      'validated',
      'published',
      'superseded',
      'archived'
    )),
  constraint platform_business_artifact_versions_unique_version
    unique (artifact_id, version_number),
  constraint platform_business_artifact_versions_scope_unique
    unique (id, artifact_id, organization_id)
);

comment on table public.platform_business_artifact_versions is
  'Versões dos artefatos de negócio. O SK-PE pode criar o nível essencial; o SK-PN aprofunda o mesmo objeto, sem reiniciar ou duplicar o conteúdo.';

create unique index if not exists ux_platform_business_artifact_open_version
  on public.platform_business_artifact_versions(artifact_id)
  where status in ('draft', 'in_elaboration', 'pending_validation');

create unique index if not exists ux_platform_business_artifact_published_version
  on public.platform_business_artifact_versions(artifact_id)
  where status = 'published';

create table if not exists public.platform_business_artifact_elements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  artifact_id uuid not null,
  artifact_version_id uuid not null,
  parent_element_id uuid,
  block_code text,
  element_code text not null,
  element_type text not null,
  title text not null,
  description text,
  structured_payload jsonb not null default '{}'::jsonb,
  display_order integer not null default 100,
  status text not null default 'active',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint platform_business_artifact_elements_version_fkey
    foreign key (artifact_version_id, artifact_id, organization_id)
    references public.platform_business_artifact_versions(
      id,
      artifact_id,
      organization_id
    )
    on delete cascade,
  constraint platform_business_artifact_elements_code_not_blank
    check (length(trim(element_code)) > 0),
  constraint platform_business_artifact_elements_type_not_blank
    check (length(trim(element_type)) > 0),
  constraint platform_business_artifact_elements_title_not_blank
    check (length(trim(title)) > 0),
  constraint platform_business_artifact_elements_status_check
    check (status in ('draft', 'active', 'inactive', 'archived')),
  constraint platform_business_artifact_elements_unique_code
    unique (artifact_version_id, element_code),
  constraint platform_business_artifact_elements_scope_unique
    unique (id, artifact_version_id, artifact_id, organization_id),
  constraint platform_business_artifact_elements_parent_fkey
    foreign key (
      parent_element_id,
      artifact_version_id,
      artifact_id,
      organization_id
    )
    references public.platform_business_artifact_elements(
      id,
      artifact_version_id,
      artifact_id,
      organization_id
    )
    on delete cascade
);

comment on table public.platform_business_artifact_elements is
  'Elementos normalizados dos artefatos e Canvas. block_code e element_type permitem aplicar o rigor específico de VPC, BMC, Cadeia de Valor e demais métodos.';

create table if not exists public.platform_business_artifact_element_relations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  artifact_id uuid not null,
  artifact_version_id uuid not null,
  source_element_id uuid not null,
  target_element_id uuid not null,
  relation_type text not null,
  contribution_weight numeric(5,2),
  rationale text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint platform_business_element_relations_version_fkey
    foreign key (artifact_version_id, artifact_id, organization_id)
    references public.platform_business_artifact_versions(
      id,
      artifact_id,
      organization_id
    )
    on delete cascade,
  constraint platform_business_element_relations_source_fkey
    foreign key (
      source_element_id,
      artifact_version_id,
      artifact_id,
      organization_id
    )
    references public.platform_business_artifact_elements(
      id,
      artifact_version_id,
      artifact_id,
      organization_id
    )
    on delete cascade,
  constraint platform_business_element_relations_target_fkey
    foreign key (
      target_element_id,
      artifact_version_id,
      artifact_id,
      organization_id
    )
    references public.platform_business_artifact_elements(
      id,
      artifact_version_id,
      artifact_id,
      organization_id
    )
    on delete cascade,
  constraint platform_business_element_relations_type_check
    check (relation_type in (
      'flow',
      'supports',
      'enables',
      'delivers',
      'contributes_to',
      'derives_from',
      'validates',
      'conflicts_with',
      'impacts'
    )),
  constraint platform_business_element_relations_weight_check
    check (
      contribution_weight is null
      or contribution_weight between 0 and 100
    ),
  constraint platform_business_element_relations_no_self
    check (source_element_id <> target_element_id),
  constraint platform_business_element_relations_unique
    unique (source_element_id, target_element_id, relation_type)
);

create table if not exists public.platform_business_artifact_version_relations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  source_artifact_id uuid not null,
  source_version_id uuid not null,
  target_artifact_id uuid not null,
  target_version_id uuid not null,
  relation_type text not null,
  rationale text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint platform_business_version_relations_source_fkey
    foreign key (source_version_id, source_artifact_id, organization_id)
    references public.platform_business_artifact_versions(
      id,
      artifact_id,
      organization_id
    )
    on delete cascade,
  constraint platform_business_version_relations_target_fkey
    foreign key (target_version_id, target_artifact_id, organization_id)
    references public.platform_business_artifact_versions(
      id,
      artifact_id,
      organization_id
    )
    on delete cascade,
  constraint platform_business_version_relations_type_check
    check (relation_type in (
      'supports',
      'derives_from',
      'complements',
      'depends_on',
      'validates',
      'updates',
      'feeds',
      'conflicts_with'
    )),
  constraint platform_business_version_relations_no_self
    check (source_version_id <> target_version_id),
  constraint platform_business_version_relations_unique
    unique (source_version_id, target_version_id, relation_type)
);

comment on table public.platform_business_artifact_version_relations is
  'Relações causais e metodológicas entre versões de VPC, BMC, Cadeia de Valor e outros artefatos compartilhados.';

create table if not exists public.skpe_formulation_business_inputs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  artifact_id uuid not null,
  artifact_version_id uuid not null,
  input_role text not null,
  usage_mode text not null,
  requirement_level text not null default 'recommended',
  is_primary boolean not null default false,
  status text not null default 'active',
  source_version_number integer not null,
  snapshot_payload jsonb not null default '{}'::jsonb,
  snapshot_schema_version text,
  snapshot_captured_at timestamptz not null default timezone('utc', now()),
  gap_summary text,
  handoff_to_skpn_recommended boolean not null default false,
  handoff_notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_formulation_business_inputs_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_formulation_business_inputs_version_fkey
    foreign key (artifact_version_id, artifact_id, organization_id)
    references public.platform_business_artifact_versions(
      id,
      artifact_id,
      organization_id
    )
    on delete restrict,
  constraint skpe_formulation_business_inputs_role_check
    check (input_role in (
      'business_foundation',
      'value_proposition',
      'business_model',
      'value_chain',
      'stakeholders',
      'market',
      'products_services',
      'capabilities',
      'processes',
      'financial_viability',
      'risks_hypotheses',
      'other'
    )),
  constraint skpe_formulation_business_inputs_usage_check
    check (usage_mode in (
      'created_in_skpe',
      'reused_from_skpn',
      'reused_from_platform',
      'imported',
      'provisional'
    )),
  constraint skpe_formulation_business_inputs_requirement_check
    check (requirement_level in ('required', 'recommended', 'optional')),
  constraint skpe_formulation_business_inputs_status_check
    check (status in ('draft', 'active', 'superseded', 'dismissed')),
  constraint skpe_formulation_business_inputs_version_positive
    check (source_version_number > 0),
  constraint skpe_formulation_business_inputs_unique
    unique (formulation_id, artifact_version_id, input_role)
);

create unique index if not exists ux_skpe_formulation_business_input_primary
  on public.skpe_formulation_business_inputs(formulation_id, input_role)
  where is_primary and status = 'active';

comment on table public.skpe_formulation_business_inputs is
  'Vincula a Formulação a versões exatas dos artefatos compartilhados e preserva snapshot histórico. A ausência do SK-PN não impede o SK-PE de criar o nível essencial.';

-- ============================================================
-- 6. TEMAS E PERSPECTIVAS
-- ============================================================

create table if not exists public.skpe_strategic_themes (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  code text not null,
  name text not null,
  description text,
  rationale text,
  horizon_start date,
  horizon_end date,
  priority text not null default 'medium',
  owner_user_id uuid references public.profiles(id) on delete set null,
  display_order integer not null default 100,
  status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_strategic_themes_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_strategic_themes_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_strategic_themes_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_strategic_themes_dates_check
    check (horizon_end is null or horizon_start is null or horizon_end >= horizon_start),
  constraint skpe_strategic_themes_priority_check
    check (priority in ('low', 'medium', 'high', 'critical')),
  constraint skpe_strategic_themes_status_check
    check (status in ('draft', 'active', 'completed', 'suspended', 'archived')),
  constraint skpe_strategic_themes_unique
    unique (formulation_id, code)
);

comment on table public.skpe_strategic_themes is
  'Grandes frentes de transformação necessárias para fortalecer a arquitetura de negócios, cumprir a Missão e alcançar a Visão.';

create table if not exists public.skpe_bsc_perspectives (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  code text not null,
  name text not null,
  description text,
  display_order integer not null default 100,
  status text not null default 'active',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_bsc_perspectives_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_bsc_perspectives_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_bsc_perspectives_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_bsc_perspectives_status_check
    check (status in ('active', 'inactive', 'archived')),
  constraint skpe_bsc_perspectives_unique
    unique (formulation_id, code)
);

comment on table public.skpe_bsc_perspectives is
  'Perspectivas do Mapa Estratégico. São configuráveis para respeitar o modelo e a natureza da organização.';

-- ============================================================
-- 7. EVOLUÇÃO DOS OBJETIVOS ESTRATÉGICOS
-- ============================================================

alter table public.skpe_strategic_objectives
  add column if not exists formulation_id uuid
    references public.skpe_strategic_formulations(id) on delete restrict,
  add column if not exists strategic_theme_id uuid
    references public.skpe_strategic_themes(id) on delete set null,
  add column if not exists perspective_id uuid
    references public.skpe_bsc_perspectives(id) on delete set null,
  add column if not exists expected_result text,
  add column if not exists rationale text,
  add column if not exists priority text not null default 'medium',
  add column if not exists validation_status text not null default 'draft',
  add column if not exists approved_at timestamptz,
  add column if not exists approved_by uuid
    references public.profiles(id) on delete set null;

alter table public.skpe_strategic_objectives
  alter column management_model set default 'bsc';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'skpe_strategic_objectives_priority_check'
      and conrelid = 'public.skpe_strategic_objectives'::regclass
  ) then
    alter table public.skpe_strategic_objectives
      add constraint skpe_strategic_objectives_priority_check
      check (priority in ('low', 'medium', 'high', 'critical'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'skpe_strategic_objectives_validation_check'
      and conrelid = 'public.skpe_strategic_objectives'::regclass
  ) then
    alter table public.skpe_strategic_objectives
      add constraint skpe_strategic_objectives_validation_check
      check (validation_status in (
        'draft',
        'pending_validation',
        'validated',
        'approved',
        'rejected'
      ));
  end if;
end;
$$;

comment on table public.skpe_strategic_objectives is
  'Objetivos Estratégicos de longo prazo estruturados pelo BSC e conectados por relações de causa e efeito.';

comment on column public.skpe_strategic_objectives.management_model is
  'Campo legado de compatibilidade. Novos Objetivos Estratégicos devem utilizar o modelo BSC. Objetivos de OKR possuem entidade própria.';

create index if not exists idx_skpe_strategic_objectives_formulation
  on public.skpe_strategic_objectives(
    formulation_id,
    perspective_id,
    strategic_theme_id,
    status
  );

create table if not exists public.skpe_objective_relations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  source_objective_id uuid not null
    references public.skpe_strategic_objectives(id) on delete cascade,
  target_objective_id uuid not null
    references public.skpe_strategic_objectives(id) on delete cascade,
  relation_type text not null default 'cause_effect',
  contribution_strength text not null default 'medium',
  rationale text,
  display_order integer not null default 100,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  constraint skpe_objective_relations_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_objective_relations_type_check
    check (relation_type in ('cause_effect', 'supports', 'enables')),
  constraint skpe_objective_relations_strength_check
    check (contribution_strength in ('low', 'medium', 'high')),
  constraint skpe_objective_relations_no_self
    check (source_objective_id <> target_objective_id),
  constraint skpe_objective_relations_unique
    unique (source_objective_id, target_objective_id, relation_type)
);

comment on table public.skpe_objective_relations is
  'Relações direcionais de causa e efeito entre Objetivos Estratégicos do Mapa Estratégico.';

-- ============================================================
-- 8. CICLOS DE OKR E OBJETIVOS DO OKR
-- ============================================================

create table if not exists public.skpe_okr_cycles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  code text not null,
  name text not null,
  description text,
  cycle_type text not null default 'annual',
  reference_year integer,
  period_start date not null,
  period_end date not null,
  owner_user_id uuid references public.profiles(id) on delete set null,
  status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_okr_cycles_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_okr_cycles_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_okr_cycles_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_okr_cycles_type_check
    check (cycle_type in ('annual', 'semester', 'quarter', 'custom')),
  constraint skpe_okr_cycles_dates_check
    check (period_end >= period_start),
  constraint skpe_okr_cycles_status_check
    check (status in ('draft', 'active', 'completed', 'archived')),
  constraint skpe_okr_cycles_unique
    unique (formulation_id, code),
  constraint skpe_okr_cycles_scope_unique
    unique (id, formulation_id, organization_id, project_id)
);

create table if not exists public.skpe_okrs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  okr_cycle_id uuid not null,
  code text not null,
  title text not null,
  description text,
  owner_user_id uuid references public.profiles(id) on delete set null,
  status text not null default 'draft',
  progress numeric(5,2) not null default 0,
  display_order integer not null default 100,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_okrs_cycle_fkey
    foreign key (
      okr_cycle_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_okr_cycles(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_okrs_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_okrs_title_not_blank
    check (length(trim(title)) > 0),
  constraint skpe_okrs_status_check
    check (status in (
      'draft',
      'active',
      'at_risk',
      'achieved',
      'not_achieved',
      'cancelled'
    )),
  constraint skpe_okrs_progress_check
    check (progress between 0 and 100),
  constraint skpe_okrs_unique
    unique (okr_cycle_id, code),
  constraint skpe_okrs_scope_unique
    unique (id, formulation_id, organization_id, project_id)
);

comment on table public.skpe_okrs is
  'Objetivos qualitativos dos ciclos de OKR. Não substituem os Objetivos Estratégicos do BSC.';

create table if not exists public.skpe_okr_objectives (
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  okr_id uuid not null,
  strategic_objective_id uuid not null,
  contribution_weight numeric(5,2),
  is_primary boolean not null default false,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,

  primary key (okr_id, strategic_objective_id),
  constraint skpe_okr_objectives_okr_fkey
    foreign key (
      okr_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_okrs(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_okr_objectives_objective_fkey
    foreign key (strategic_objective_id)
    references public.skpe_strategic_objectives(id)
    on delete cascade,
  constraint skpe_okr_objectives_weight_check
    check (
      contribution_weight is null
      or contribution_weight between 0 and 100
    )
);

create unique index if not exists ux_skpe_okr_objectives_primary
  on public.skpe_okr_objectives(okr_id)
  where is_primary;

-- ============================================================
-- 9. EVOLUÇÃO DOS RESULTADOS-CHAVE
-- ============================================================

alter table public.skpe_key_results
  add column if not exists formulation_id uuid
    references public.skpe_strategic_formulations(id) on delete restrict,
  add column if not exists okr_id uuid
    references public.skpe_okrs(id) on delete cascade,
  add column if not exists contribution_weight numeric(5,2),
  add column if not exists annualized_target boolean not null default true,
  add column if not exists validation_status text not null default 'draft';

do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'skpe_key_results_unique_code'
      and conrelid = 'public.skpe_key_results'::regclass
  ) then
    alter table public.skpe_key_results
      drop constraint skpe_key_results_unique_code;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'skpe_key_results_contribution_weight_check'
      and conrelid = 'public.skpe_key_results'::regclass
  ) then
    alter table public.skpe_key_results
      add constraint skpe_key_results_contribution_weight_check
      check (
        contribution_weight is null
        or contribution_weight between 0 and 100
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'skpe_key_results_validation_check'
      and conrelid = 'public.skpe_key_results'::regclass
  ) then
    alter table public.skpe_key_results
      add constraint skpe_key_results_validation_check
      check (validation_status in (
        'draft',
        'pending_validation',
        'validated',
        'approved',
        'rejected'
      ));
  end if;
end;
$$;

create unique index if not exists ux_skpe_key_results_okr_code
  on public.skpe_key_results(okr_id, code)
  where okr_id is not null;

create unique index if not exists ux_skpe_key_results_legacy_objective_code
  on public.skpe_key_results(strategic_objective_id, code)
  where okr_id is null;

create index if not exists idx_skpe_key_results_okr
  on public.skpe_key_results(okr_id, status);

comment on column public.skpe_key_results.strategic_objective_id is
  'Objetivo Estratégico principal ao qual o KR contribui. Mantido para compatibilidade e rastreabilidade direta.';

comment on column public.skpe_key_results.okr_id is
  'Objetivo do OKR ao qual o Resultado-Chave pertence.';

-- ============================================================
-- 10. INDICADORES, METAS E BMKs
-- ============================================================

create table if not exists public.skpe_indicators (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  code text not null,
  name text not null,
  description text,
  indicator_scope text not null,
  strategic_objective_id uuid
    references public.skpe_strategic_objectives(id) on delete cascade,
  key_result_id uuid
    references public.skpe_key_results(id) on delete cascade,
  formula_text text,
  unit text not null,
  polarity text not null,
  measurement_frequency text,
  data_source text,
  baseline_value numeric,
  baseline_date date,
  owner_user_id uuid references public.profiles(id) on delete set null,
  status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_indicators_formulation_fkey
    foreign key (formulation_id, organization_id, project_id)
    references public.skpe_strategic_formulations(
      id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_indicators_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_indicators_name_not_blank
    check (length(trim(name)) > 0),
  constraint skpe_indicators_unit_not_blank
    check (length(trim(unit)) > 0),
  constraint skpe_indicators_scope_check
    check (indicator_scope in (
      'strategic_kpi',
      'key_result_indicator'
    )),
  constraint skpe_indicators_scope_reference_check
    check (
      (
        indicator_scope = 'strategic_kpi'
        and strategic_objective_id is not null
        and key_result_id is null
      )
      or
      (
        indicator_scope = 'key_result_indicator'
        and key_result_id is not null
      )
    ),
  constraint skpe_indicators_polarity_check
    check (polarity in (
      'higher_is_better',
      'lower_is_better',
      'target_is_better',
      'range_is_better'
    )),
  constraint skpe_indicators_status_check
    check (status in ('draft', 'active', 'inactive', 'archived')),
  constraint skpe_indicators_unique
    unique (project_id, code),
  constraint skpe_indicators_scope_unique
    unique (id, formulation_id, organization_id, project_id)
);

comment on table public.skpe_indicators is
  'Indicadores estratégicos dos OEs e indicadores operacionais dos KRs, explicitamente diferenciados pelo escopo.';

create table if not exists public.skpe_indicator_targets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  indicator_id uuid not null,
  target_type text not null,
  period_start date not null,
  period_end date not null,
  target_value numeric not null,
  minimum_value numeric,
  challenge_value numeric,
  tolerance_lower numeric,
  tolerance_upper numeric,
  owner_user_id uuid references public.profiles(id) on delete set null,
  status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_indicator_targets_indicator_fkey
    foreign key (
      indicator_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_indicators(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_indicator_targets_type_check
    check (target_type in (
      'annual',
      'intermediate',
      'long_term',
      'cycle'
    )),
  constraint skpe_indicator_targets_dates_check
    check (period_end >= period_start),
  constraint skpe_indicator_targets_status_check
    check (status in (
      'draft',
      'active',
      'achieved',
      'not_achieved',
      'superseded'
    )),
  constraint skpe_indicator_targets_unique
    unique (indicator_id, target_type, period_start, period_end),
  constraint skpe_indicator_targets_scope_unique
    unique (id, formulation_id, organization_id, project_id)
);

create table if not exists public.skpe_benchmark_references (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  project_id uuid not null,
  formulation_id uuid not null,
  indicator_id uuid not null,
  indicator_target_id uuid,
  benchmark_type text not null default 'sector',
  reference_organization text,
  source_name text not null,
  source_reference text,
  reference_period text,
  benchmark_value numeric not null,
  applicability text,
  gap_analysis text,
  notes text,
  verified_at timestamptz,
  verified_by uuid references public.profiles(id) on delete set null,
  status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_benchmark_references_indicator_fkey
    foreign key (
      indicator_id,
      formulation_id,
      organization_id,
      project_id
    )
    references public.skpe_indicators(
      id,
      formulation_id,
      organization_id,
      project_id
    )
    on delete cascade,
  constraint skpe_benchmark_references_target_fkey
    foreign key (indicator_target_id)
    references public.skpe_indicator_targets(id)
    on delete set null,
  constraint skpe_benchmark_references_type_check
    check (benchmark_type in (
      'internal',
      'sector',
      'market',
      'best_practice',
      'regulatory'
    )),
  constraint skpe_benchmark_references_source_not_blank
    check (length(trim(source_name)) > 0),
  constraint skpe_benchmark_references_status_check
    check (status in ('draft', 'verified', 'active', 'archived'))
);

comment on table public.skpe_benchmark_references is
  'Referências de benchmarking associadas aos KPIs e, quando aplicável, às metas que fundamentam.';

-- ============================================================
-- 11. PROTEÇÃO DAS VERSÕES APROVADAS
-- ============================================================

create or replace function public.skpe_guard_approved_formulation_content()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_formulation_id uuid;
  formulation_status text;
begin
  if tg_op = 'DELETE' then
    target_formulation_id := old.formulation_id;
  else
    target_formulation_id := new.formulation_id;
  end if;

  if target_formulation_id is null then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

  select formulation.status
  into formulation_status
  from public.skpe_strategic_formulations formulation
  where formulation.id = target_formulation_id;

  if formulation_status in ('approved', 'superseded', 'archived') then
    raise exception
      'A versão da Formulação Estratégica está bloqueada para edição. Crie uma nova versão.';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

do $$
declare
  target_table text;
begin
  foreach target_table in array array[
    'skpe_strategic_identity',
    'skpe_strategic_identity_items',
    'skpe_strategic_values',
    'skpe_strategic_value_behaviors',
    'skpe_formulation_business_inputs',
    'skpe_strategic_themes',
    'skpe_bsc_perspectives',
    'skpe_strategic_objectives',
    'skpe_objective_relations',
    'skpe_okr_cycles',
    'skpe_okrs',
    'skpe_okr_objectives',
    'skpe_key_results',
    'skpe_indicators',
    'skpe_indicator_targets',
    'skpe_benchmark_references'
  ]
  loop
    execute format(
      'drop trigger if exists %I on public.%I',
      target_table || '_guard_approved_formulation',
      target_table
    );

    execute format(
      'create trigger %I before insert or update or delete on public.%I
       for each row execute function public.skpe_guard_approved_formulation_content()',
      target_table || '_guard_approved_formulation',
      target_table
    );
  end loop;
end;
$$;

-- ============================================================
-- 12. SELEÇÃO EXPLÍCITA DO PROJETO
-- ============================================================

create or replace function public.get_skpe_projects_for_selection(
  target_organization_id uuid
)
returns table (
  project_id uuid,
  project_code text,
  project_name text,
  project_status text,
  project_progress numeric,
  current_phase_code text,
  planning_horizon_start_year integer,
  planning_horizon_end_year integer,
  reference_year integer,
  review_cycle text,
  valid_from date,
  valid_until date,
  start_date date,
  target_end_date date,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception 'Usuário sem permissão para consultar os projetos estratégicos desta organização.';
  end if;

  return query
  select
    project.id,
    project.code,
    project.name,
    project.status,
    project.progress,
    project.current_phase_code,
    project.planning_horizon_start_year,
    project.planning_horizon_end_year,
    project.reference_year,
    project.review_cycle,
    project.valid_from,
    project.valid_until,
    project.start_date,
    project.target_end_date,
    project.updated_at
  from public.skpe_projects project
  where project.organization_id = target_organization_id
    and project.archived_at is null
  order by
    case project.status
      when 'active' then 1
      when 'draft' then 2
      when 'suspended' then 3
      when 'completed' then 4
      else 5
    end,
    project.updated_at desc,
    project.name;
end;
$$;

comment on function public.get_skpe_projects_for_selection(uuid) is
  'Lista explicitamente os projetos estratégicos disponíveis para seleção. A interface não deve assumir o primeiro projeto retornado por outra consulta.';

-- ============================================================
-- 13. PRONTIDÃO METODOLÓGICA DA FORMULAÇÃO
-- ============================================================

create or replace function public.get_skpe_formulation_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  issues jsonb;
  counts jsonb;
  blocking_count integer;
begin
  select *
  into formulation_row
  from public.skpe_strategic_formulations
  where id = target_formulation_id;

  if not found then
    raise exception 'Versão da Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception 'Usuário sem permissão para consultar esta Formulação Estratégica.';
  end if;

  select jsonb_build_object(
    'identityItems', (
      select count(*)
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
    ),
    'values', (
      select count(*)
      from public.skpe_strategic_values value
      where value.formulation_id = target_formulation_id
        and value.status <> 'archived'
    ),
    'businessInputs', (
      select count(*)
      from public.skpe_formulation_business_inputs input
      where input.formulation_id = target_formulation_id
        and input.status = 'active'
    ),
    'businessInputsCreatedInSkpe', (
      select count(*)
      from public.skpe_formulation_business_inputs input
      where input.formulation_id = target_formulation_id
        and input.status = 'active'
        and input.usage_mode = 'created_in_skpe'
    ),
    'valueChainInputs', (
      select count(*)
      from public.skpe_formulation_business_inputs input
      where input.formulation_id = target_formulation_id
        and input.status = 'active'
        and input.input_role = 'value_chain'
    ),
    'themes', (
      select count(*)
      from public.skpe_strategic_themes theme
      where theme.formulation_id = target_formulation_id
        and theme.status <> 'archived'
    ),
    'objectives', (
      select count(*)
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = target_formulation_id
        and objective.status <> 'archived'
    ),
    'strategicKpis', (
      select count(*)
      from public.skpe_indicators indicator
      where indicator.formulation_id = target_formulation_id
        and indicator.indicator_scope = 'strategic_kpi'
        and indicator.status <> 'archived'
    ),
    'okrCycles', (
      select count(*)
      from public.skpe_okr_cycles cycle
      where cycle.formulation_id = target_formulation_id
        and cycle.status <> 'archived'
    ),
    'okrs', (
      select count(*)
      from public.skpe_okrs okr
      where okr.formulation_id = target_formulation_id
        and okr.status <> 'cancelled'
    ),
    'keyResults', (
      select count(*)
      from public.skpe_key_results kr
      where kr.formulation_id = target_formulation_id
        and kr.status <> 'cancelled'
    )
  )
  into counts;

  with issue_rows as (
    select
      'MISSION_MISSING'::text as code,
      'blocking'::text as severity,
      'A Missão é obrigatória para aprovação da Formulação Estratégica.'::text as message,
      1::bigint as affected_count
    where not exists (
      select 1
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
        and item.element_type = 'mission'
    )

    union all

    select
      'VISION_MISSING',
      'blocking',
      'A Visão de Longo Prazo é obrigatória para aprovação da Formulação Estratégica.',
      1
    where not exists (
      select 1
      from public.skpe_strategic_identity_items item
      where item.formulation_id = target_formulation_id
        and item.element_type = 'vision'
    )

    union all

    select
      'VALUES_MISSING',
      'blocking',
      'Registre os Valores inegociáveis da organização.',
      1
    where not exists (
      select 1
      from public.skpe_strategic_values value
      where value.formulation_id = target_formulation_id
        and value.status <> 'archived'
    )

    union all

    select
      'BUSINESS_FOUNDATION_MISSING',
      'blocking',
      'Desenvolva no SK-PE a Fundamentação do Negócio em nível essencial ou vincule uma versão já existente. A contratação do SK-PN não é exigida.',
      1
    where not exists (
      select 1
      from public.skpe_formulation_business_inputs input
      where input.formulation_id = target_formulation_id
        and input.status = 'active'
        and input.input_role in (
          'business_foundation',
          'value_proposition',
          'business_model'
        )
    )

    union all

    select
      'VALUE_CHAIN_INPUT_MISSING',
      'blocking',
      'Estruture no SK-PE a Cadeia de Valor em nível essencial ou vincule uma versão existente do SK-PN.',
      1
    where not exists (
      select 1
      from public.skpe_formulation_business_inputs input
      where input.formulation_id = target_formulation_id
        and input.status = 'active'
        and input.input_role = 'value_chain'
    )

    union all

    select
      'BUSINESS_INPUT_DEEPENING_RECOMMENDED',
      'recommendation',
      'Existem insumos essenciais ou estruturados que podem ser aprofundados posteriormente no SK-PN sem interromper o SK-PE.',
      count(*)
    from public.skpe_formulation_business_inputs input
    join public.platform_business_artifact_versions version
      on version.id = input.artifact_version_id
    where input.formulation_id = target_formulation_id
      and input.status = 'active'
      and input.handoff_to_skpn_recommended
      and version.maturity_level in ('essential', 'structured')
    having count(*) > 0

    union all

    select
      'THEMES_MISSING',
      'blocking',
      'Registre ao menos um Tema Estratégico.',
      1
    where not exists (
      select 1
      from public.skpe_strategic_themes theme
      where theme.formulation_id = target_formulation_id
        and theme.status <> 'archived'
    )

    union all

    select
      'OBJECTIVES_MISSING',
      'blocking',
      'Registre os Objetivos Estratégicos do Mapa Estratégico.',
      1
    where not exists (
      select 1
      from public.skpe_strategic_objectives objective
      where objective.formulation_id = target_formulation_id
        and objective.status <> 'archived'
    )

    union all

    select
      'OBJECTIVE_WITHOUT_KPI',
      'blocking',
      'Todo Objetivo Estratégico deve possuir ao menos um KPI.',
      count(*)
    from public.skpe_strategic_objectives objective
    where objective.formulation_id = target_formulation_id
      and objective.status <> 'archived'
      and not exists (
        select 1
        from public.skpe_indicators indicator
        where indicator.strategic_objective_id = objective.id
          and indicator.indicator_scope = 'strategic_kpi'
          and indicator.status <> 'archived'
      )
    having count(*) > 0

    union all

    select
      'KPI_WITHOUT_LONG_TERM_TARGET',
      'blocking',
      'Todo KPI estratégico deve possuir Meta de Longo Prazo.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = target_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status <> 'archived'
      and not exists (
        select 1
        from public.skpe_indicator_targets target
        where target.indicator_id = indicator.id
          and target.target_type = 'long_term'
          and target.status <> 'superseded'
      )
    having count(*) > 0

    union all

    select
      'KPI_WITHOUT_BENCHMARK',
      'recommendation',
      'Sempre que possível, associe um BMK ao KPI ou à Meta de Longo Prazo para fundamentar a ambição estratégica.',
      count(*)
    from public.skpe_indicators indicator
    where indicator.formulation_id = target_formulation_id
      and indicator.indicator_scope = 'strategic_kpi'
      and indicator.status <> 'archived'
      and not exists (
        select 1
        from public.skpe_benchmark_references benchmark
        where benchmark.indicator_id = indicator.id
          and benchmark.status <> 'archived'
      )
    having count(*) > 0

    union all

    select
      'OKRS_MISSING',
      'blocking',
      'Registre os Objetivos dos ciclos de OKR que desdobram os OEs.',
      1
    where not exists (
      select 1
      from public.skpe_okrs okr
      where okr.formulation_id = target_formulation_id
        and okr.status <> 'cancelled'
    )

    union all

    select
      'OKR_WITH_LESS_THAN_3_KRS',
      'blocking',
      'Cada Objetivo do OKR deve possuir no mínimo 3 Resultados-Chave.',
      count(*)
    from public.skpe_okrs okr
    where okr.formulation_id = target_formulation_id
      and okr.status <> 'cancelled'
      and (
        select count(*)
        from public.skpe_key_results kr
        where kr.okr_id = okr.id
          and kr.status <> 'cancelled'
      ) < 3
    having count(*) > 0

    union all

    select
      'KR_WITH_LESS_THAN_3_INITIATIVES',
      'recommendation',
      'Recomenda-se vincular no mínimo 3 iniciativas estruturadas a cada Resultado-Chave, preferencialmente projetos estratégicos, IPAs ou melhorias operacionais.',
      count(*)
    from public.skpe_key_results kr
    where kr.formulation_id = target_formulation_id
      and kr.status <> 'cancelled'
      and (
        select count(*)
        from public.skpe_initiative_key_results link
        where link.key_result_id = kr.id
      ) < 3
    having count(*) > 0
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'code', issue.code,
          'severity', issue.severity,
          'message', issue.message,
          'affectedCount', issue.affected_count
        )
        order by
          case issue.severity when 'blocking' then 1 else 2 end,
          issue.code
      ),
      '[]'::jsonb
    ),
    count(*) filter (where issue.severity = 'blocking')::integer
  into issues, blocking_count
  from issue_rows issue;

  return jsonb_build_object(
    'formulationId', formulation_row.id,
    'projectId', formulation_row.project_id,
    'organizationId', formulation_row.organization_id,
    'versionNumber', formulation_row.version_number,
    'status', formulation_row.status,
    'readyForApproval', blocking_count = 0,
    'blockingIssueCount', blocking_count,
    'counts', counts,
    'issues', issues,
    'businessArchitecture', jsonb_build_object(
      'sharedPlatformDomain', true,
      'skpeCanCreateEssentialInputs', true,
      'skpnLicenseRequired', false,
      'futureSkpnDeepeningSupported', true,
      'approvedFormulationKeepsSnapshot', true
    ),
    'methodologyRules', jsonb_build_object(
      'purposeOptional', true,
      'missionRequired', true,
      'visionRequired', true,
      'businessFoundationRequired', true,
      'valueChainRequired', true,
      'minimumKeyResultsPerOkr', 3,
      'recommendedMinimumInitiativesPerKeyResult', 3,
      'strategicKpiDifferentFromKrIndicator', true,
      'benchmarkSupportsTargetDefinition', true
    )
  );
end;
$$;

-- ============================================================
-- 14. ÍNDICES COMPLEMENTARES
-- ============================================================

create index if not exists idx_skpe_identity_items_formulation
  on public.skpe_strategic_identity_items(formulation_id, element_type);

create index if not exists idx_skpe_values_formulation
  on public.skpe_strategic_values(formulation_id, status, display_order);

create index if not exists idx_platform_business_artifacts_organization
  on public.platform_business_artifacts(
    organization_id,
    artifact_type,
    status
  );

create index if not exists idx_platform_business_versions_artifact
  on public.platform_business_artifact_versions(
    artifact_id,
    status,
    version_number desc
  );

create index if not exists idx_platform_business_elements_version
  on public.platform_business_artifact_elements(
    artifact_version_id,
    block_code,
    element_type,
    display_order
  );

create index if not exists idx_skpe_formulation_business_inputs
  on public.skpe_formulation_business_inputs(
    formulation_id,
    input_role,
    status
  );

create index if not exists idx_skpe_themes_formulation
  on public.skpe_strategic_themes(
    formulation_id,
    status,
    display_order
  );

create index if not exists idx_skpe_perspectives_formulation
  on public.skpe_bsc_perspectives(
    formulation_id,
    status,
    display_order
  );

create index if not exists idx_skpe_objective_relations_formulation
  on public.skpe_objective_relations(
    formulation_id,
    source_objective_id,
    target_objective_id
  );

create index if not exists idx_skpe_okr_cycles_formulation
  on public.skpe_okr_cycles(
    formulation_id,
    status,
    period_start,
    period_end
  );

create index if not exists idx_skpe_okrs_cycle
  on public.skpe_okrs(
    okr_cycle_id,
    status,
    display_order
  );

create index if not exists idx_skpe_indicators_formulation
  on public.skpe_indicators(
    formulation_id,
    indicator_scope,
    status
  );

create index if not exists idx_skpe_targets_indicator
  on public.skpe_indicator_targets(
    indicator_id,
    target_type,
    period_end
  );

create index if not exists idx_skpe_benchmarks_indicator
  on public.skpe_benchmark_references(
    indicator_id,
    status
  );

-- ============================================================
-- 15. RLS
-- ============================================================

alter table public.skpe_strategic_formulations enable row level security;
alter table public.skpe_strategic_identity enable row level security;
alter table public.skpe_strategic_identity_items enable row level security;
alter table public.skpe_strategic_values enable row level security;
alter table public.skpe_strategic_value_behaviors enable row level security;
alter table public.platform_business_artifacts enable row level security;
alter table public.platform_business_artifact_versions enable row level security;
alter table public.platform_business_artifact_elements enable row level security;
alter table public.platform_business_artifact_element_relations enable row level security;
alter table public.platform_business_artifact_version_relations enable row level security;
alter table public.skpe_formulation_business_inputs enable row level security;
alter table public.skpe_strategic_themes enable row level security;
alter table public.skpe_bsc_perspectives enable row level security;
alter table public.skpe_objective_relations enable row level security;
alter table public.skpe_okr_cycles enable row level security;
alter table public.skpe_okrs enable row level security;
alter table public.skpe_okr_objectives enable row level security;
alter table public.skpe_indicators enable row level security;
alter table public.skpe_indicator_targets enable row level security;
alter table public.skpe_benchmark_references enable row level security;

drop policy if exists skpe_strategic_formulations_select
  on public.skpe_strategic_formulations;
create policy skpe_strategic_formulations_select
on public.skpe_strategic_formulations
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_strategic_identity_select
  on public.skpe_strategic_identity;
create policy skpe_strategic_identity_select
on public.skpe_strategic_identity
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_strategic_identity_items_select
  on public.skpe_strategic_identity_items;
create policy skpe_strategic_identity_items_select
on public.skpe_strategic_identity_items
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_strategic_values_select
  on public.skpe_strategic_values;
create policy skpe_strategic_values_select
on public.skpe_strategic_values
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_strategic_value_behaviors_select
  on public.skpe_strategic_value_behaviors;
create policy skpe_strategic_value_behaviors_select
on public.skpe_strategic_value_behaviors
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists platform_business_artifacts_select
  on public.platform_business_artifacts;
create policy platform_business_artifacts_select
on public.platform_business_artifacts
for select to authenticated
using (public.can_view_business_architecture(organization_id));

drop policy if exists platform_business_artifact_versions_select
  on public.platform_business_artifact_versions;
create policy platform_business_artifact_versions_select
on public.platform_business_artifact_versions
for select to authenticated
using (public.can_view_business_architecture(organization_id));

drop policy if exists platform_business_artifact_elements_select
  on public.platform_business_artifact_elements;
create policy platform_business_artifact_elements_select
on public.platform_business_artifact_elements
for select to authenticated
using (public.can_view_business_architecture(organization_id));

drop policy if exists platform_business_artifact_element_relations_select
  on public.platform_business_artifact_element_relations;
create policy platform_business_artifact_element_relations_select
on public.platform_business_artifact_element_relations
for select to authenticated
using (public.can_view_business_architecture(organization_id));

drop policy if exists platform_business_artifact_version_relations_select
  on public.platform_business_artifact_version_relations;
create policy platform_business_artifact_version_relations_select
on public.platform_business_artifact_version_relations
for select to authenticated
using (public.can_view_business_architecture(organization_id));

drop policy if exists skpe_formulation_business_inputs_select
  on public.skpe_formulation_business_inputs;
create policy skpe_formulation_business_inputs_select
on public.skpe_formulation_business_inputs
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_strategic_themes_select
  on public.skpe_strategic_themes;
create policy skpe_strategic_themes_select
on public.skpe_strategic_themes
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_bsc_perspectives_select
  on public.skpe_bsc_perspectives;
create policy skpe_bsc_perspectives_select
on public.skpe_bsc_perspectives
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_objective_relations_select
  on public.skpe_objective_relations;
create policy skpe_objective_relations_select
on public.skpe_objective_relations
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_okr_cycles_select
  on public.skpe_okr_cycles;
create policy skpe_okr_cycles_select
on public.skpe_okr_cycles
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_okrs_select
  on public.skpe_okrs;
create policy skpe_okrs_select
on public.skpe_okrs
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_okr_objectives_select
  on public.skpe_okr_objectives;
create policy skpe_okr_objectives_select
on public.skpe_okr_objectives
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_indicators_select
  on public.skpe_indicators;
create policy skpe_indicators_select
on public.skpe_indicators
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_indicator_targets_select
  on public.skpe_indicator_targets;
create policy skpe_indicator_targets_select
on public.skpe_indicator_targets
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_benchmark_references_select
  on public.skpe_benchmark_references;
create policy skpe_benchmark_references_select
on public.skpe_benchmark_references
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

-- Escritas diretas ficam bloqueadas. A próxima migration criará as
-- funções operacionais auditadas para criação, edição, validação e aprovação.

-- ============================================================
-- 16. PRIVILÉGIOS
-- ============================================================

revoke all on table public.skpe_strategic_formulations from anon;
revoke all on table public.skpe_strategic_identity from anon;
revoke all on table public.skpe_strategic_identity_items from anon;
revoke all on table public.skpe_strategic_values from anon;
revoke all on table public.skpe_strategic_value_behaviors from anon;
revoke all on table public.platform_business_artifacts from anon;
revoke all on table public.platform_business_artifact_versions from anon;
revoke all on table public.platform_business_artifact_elements from anon;
revoke all on table public.platform_business_artifact_element_relations from anon;
revoke all on table public.platform_business_artifact_version_relations from anon;
revoke all on table public.skpe_formulation_business_inputs from anon;
revoke all on table public.skpe_strategic_themes from anon;
revoke all on table public.skpe_bsc_perspectives from anon;
revoke all on table public.skpe_objective_relations from anon;
revoke all on table public.skpe_okr_cycles from anon;
revoke all on table public.skpe_okrs from anon;
revoke all on table public.skpe_okr_objectives from anon;
revoke all on table public.skpe_indicators from anon;
revoke all on table public.skpe_indicator_targets from anon;
revoke all on table public.skpe_benchmark_references from anon;

revoke insert, update, delete
  on table public.skpe_strategic_formulations,
               public.skpe_strategic_identity,
               public.skpe_strategic_identity_items,
               public.skpe_strategic_values,
               public.skpe_strategic_value_behaviors,
               public.platform_business_artifacts,
               public.platform_business_artifact_versions,
               public.platform_business_artifact_elements,
               public.platform_business_artifact_element_relations,
               public.platform_business_artifact_version_relations,
               public.skpe_formulation_business_inputs,
               public.skpe_strategic_themes,
               public.skpe_bsc_perspectives,
               public.skpe_objective_relations,
               public.skpe_okr_cycles,
               public.skpe_okrs,
               public.skpe_okr_objectives,
               public.skpe_indicators,
               public.skpe_indicator_targets,
               public.skpe_benchmark_references
  from authenticated;

grant select
  on table public.skpe_strategic_formulations,
               public.skpe_strategic_identity,
               public.skpe_strategic_identity_items,
               public.skpe_strategic_values,
               public.skpe_strategic_value_behaviors,
               public.platform_business_artifacts,
               public.platform_business_artifact_versions,
               public.platform_business_artifact_elements,
               public.platform_business_artifact_element_relations,
               public.platform_business_artifact_version_relations,
               public.skpe_formulation_business_inputs,
               public.skpe_strategic_themes,
               public.skpe_bsc_perspectives,
               public.skpe_objective_relations,
               public.skpe_okr_cycles,
               public.skpe_okrs,
               public.skpe_okr_objectives,
               public.skpe_indicators,
               public.skpe_indicator_targets,
               public.skpe_benchmark_references
  to authenticated;

revoke all on function public.can_view_skpe_formulation(uuid)
  from public, anon;
revoke all on function public.can_manage_skpe_formulation(uuid)
  from public, anon;
revoke all on function public.can_validate_skpe_formulation(uuid)
  from public, anon;
revoke all on function public.can_approve_skpe_formulation(uuid)
  from public, anon;
revoke all on function public.can_view_business_architecture(uuid)
  from public, anon;
revoke all on function public.can_manage_business_architecture(uuid)
  from public, anon;
revoke all on function public.skpe_guard_approved_formulation_content()
  from public, anon;
revoke all on function public.get_skpe_projects_for_selection(uuid)
  from public, anon;
revoke all on function public.get_skpe_formulation_readiness(uuid)
  from public, anon;

grant execute on function public.can_view_skpe_formulation(uuid)
  to authenticated, service_role;
grant execute on function public.can_manage_skpe_formulation(uuid)
  to authenticated, service_role;
grant execute on function public.can_validate_skpe_formulation(uuid)
  to authenticated, service_role;
grant execute on function public.can_approve_skpe_formulation(uuid)
  to authenticated, service_role;
grant execute on function public.can_view_business_architecture(uuid)
  to authenticated, service_role;
grant execute on function public.can_manage_business_architecture(uuid)
  to authenticated, service_role;
grant execute on function public.get_skpe_projects_for_selection(uuid)
  to authenticated, service_role;
grant execute on function public.get_skpe_formulation_readiness(uuid)
  to authenticated, service_role;

commit;
