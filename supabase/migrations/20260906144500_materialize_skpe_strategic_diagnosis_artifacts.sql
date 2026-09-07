-- SK-PE - Diagnostico Estrategico canonico
-- Escopo: PESTEL, SWOT, TOWS e Riscos Estrategicos.
-- Regra: riscos estrategicos do diagnostico NAO substituem skpe_initiative_risks.
-- Esta migration apenas cria o modelo canonico e sua seguranca.
-- Nao materializa dados de importacao e nao altera o frontend.

create table public.skpe_pestel_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null,
  code text not null,
  dimension text not null,
  external_factor text not null,
  nature text,
  effect text,
  impact_label text,
  probability_label text,
  horizon text,
  strategic_implication text,
  preliminary_response text,
  related_swot_codes text[] not null default '{}',
  related_risk_codes text[] not null default '{}',
  evidence_references text[] not null default '{}',
  status text not null default 'draft',
  validation_status text not null default 'draft',
  source_import_record_id uuid references public.skpe_import_records(id) on delete set null,
  source_external_key text,
  source_sheet text,
  source_row integer,
  source_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,
  constraint skpe_pestel_items_project_scope_fkey
    foreign key (project_id, organization_id)
    references public.skpe_projects(id, organization_id)
    on delete cascade,
  constraint skpe_pestel_items_code_not_blank
    check (btrim(code) <> ''),
  constraint skpe_pestel_items_dimension_not_blank
    check (btrim(dimension) <> ''),
  constraint skpe_pestel_items_factor_not_blank
    check (btrim(external_factor) <> ''),
  constraint skpe_pestel_items_unique_code
    unique (organization_id, project_id, code)
);

create index idx_skpe_pestel_items_scope
  on public.skpe_pestel_items (organization_id, project_id, archived_at);

create index idx_skpe_pestel_items_import
  on public.skpe_pestel_items (source_import_record_id)
  where source_import_record_id is not null;

comment on table public.skpe_pestel_items is
  'Itens canonicos PESTEL do Diagnostico Estrategico SK-PE, preservando linhagem da importacao e evidencia.';

create trigger skpe_pestel_items_set_updated_at
before update on public.skpe_pestel_items
for each row execute function public.set_updated_at();


create table public.skpe_swot_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null,
  code text not null,
  quadrant text not null,
  factor text not null,
  evidence_description text,
  impact_label text,
  priority text,
  owner_label text,
  origin_pestel_codes text[] not null default '{}',
  evidence_references text[] not null default '{}',
  status text not null default 'draft',
  validation_status text not null default 'draft',
  source_import_record_id uuid references public.skpe_import_records(id) on delete set null,
  source_external_key text,
  source_sheet text,
  source_row integer,
  source_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,
  constraint skpe_swot_items_project_scope_fkey
    foreign key (project_id, organization_id)
    references public.skpe_projects(id, organization_id)
    on delete cascade,
  constraint skpe_swot_items_code_not_blank
    check (btrim(code) <> ''),
  constraint skpe_swot_items_quadrant_not_blank
    check (btrim(quadrant) <> ''),
  constraint skpe_swot_items_factor_not_blank
    check (btrim(factor) <> ''),
  constraint skpe_swot_items_unique_code
    unique (organization_id, project_id, code)
);

create index idx_skpe_swot_items_scope
  on public.skpe_swot_items (organization_id, project_id, archived_at);

create index idx_skpe_swot_items_import
  on public.skpe_swot_items (source_import_record_id)
  where source_import_record_id is not null;

comment on table public.skpe_swot_items is
  'Itens canonicos SWOT do Diagnostico Estrategico SK-PE, derivados de evidencias e contexto governados.';

create trigger skpe_swot_items_set_updated_at
before update on public.skpe_swot_items
for each row execute function public.set_updated_at();


create table public.skpe_tows_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null,
  code text not null,
  tows_type text not null,
  strategy_statement text not null,
  internal_factor_codes text[] not null default '{}',
  external_factor_codes text[] not null default '{}',
  decision_theme text,
  priority text,
  horizon text,
  owner_label text,
  gate_condition text,
  status text not null default 'draft',
  validation_status text not null default 'draft',
  source_import_record_id uuid references public.skpe_import_records(id) on delete set null,
  source_external_key text,
  source_sheet text,
  source_row integer,
  source_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,
  constraint skpe_tows_items_project_scope_fkey
    foreign key (project_id, organization_id)
    references public.skpe_projects(id, organization_id)
    on delete cascade,
  constraint skpe_tows_items_code_not_blank
    check (btrim(code) <> ''),
  constraint skpe_tows_items_type_not_blank
    check (btrim(tows_type) <> ''),
  constraint skpe_tows_items_strategy_not_blank
    check (btrim(strategy_statement) <> ''),
  constraint skpe_tows_items_unique_code
    unique (organization_id, project_id, code)
);

create index idx_skpe_tows_items_scope
  on public.skpe_tows_items (organization_id, project_id, archived_at);

create index idx_skpe_tows_items_import
  on public.skpe_tows_items (source_import_record_id)
  where source_import_record_id is not null;

comment on table public.skpe_tows_items is
  'Alternativas estrategicas canonicas TOWS do Diagnostico Estrategico SK-PE, preservando os cruzamentos SWOT que lhes deram origem.';

create trigger skpe_tows_items_set_updated_at
before update on public.skpe_tows_items
for each row execute function public.set_updated_at();


create table public.skpe_strategic_risk_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null,
  code text not null,
  risk_event text not null,
  category text,
  cause text,
  consequence text,
  probability_label text,
  impact_label text,
  inherent_score numeric,
  existing_controls text,
  control_gaps text,
  response_type text,
  treatment_plan text,
  monitoring_indicator text,
  monitoring_evidence text,
  owner_label text,
  due_horizon text,
  residual_score numeric,
  status text not null default 'draft',
  evidence_references text[] not null default '{}',
  management_recognition text,
  risk_acceptance text,
  acceptance_evidence text,
  implementation_cycle text,
  portfolio_destination text,
  completion_percent numeric,
  related_objective_codes text[] not null default '{}',
  validation_status text not null default 'draft',
  source_import_record_id uuid references public.skpe_import_records(id) on delete set null,
  source_external_key text,
  source_sheet text,
  source_row integer,
  source_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  archived_at timestamptz,
  constraint skpe_strategic_risk_items_project_scope_fkey
    foreign key (project_id, organization_id)
    references public.skpe_projects(id, organization_id)
    on delete cascade,
  constraint skpe_strategic_risk_items_code_not_blank
    check (btrim(code) <> ''),
  constraint skpe_strategic_risk_items_event_not_blank
    check (btrim(risk_event) <> ''),
  constraint skpe_strategic_risk_items_completion_check
    check (completion_percent is null or (completion_percent >= 0 and completion_percent <= 100)),
  constraint skpe_strategic_risk_items_unique_code
    unique (organization_id, project_id, code)
);

create index idx_skpe_strategic_risk_items_scope
  on public.skpe_strategic_risk_items (organization_id, project_id, archived_at);

create index idx_skpe_strategic_risk_items_import
  on public.skpe_strategic_risk_items (source_import_record_id)
  where source_import_record_id is not null;

comment on table public.skpe_strategic_risk_items is
  'Riscos estrategicos canonicos identificados no Diagnostico SK-PE. Preservam causa, consequencia, controles, lacunas, tratamento, indicador e evidencia de acompanhamento conforme SK-PE/ISO 31000. Nao substituem riscos operacionais/de execucao de public.skpe_initiative_risks.';

create trigger skpe_strategic_risk_items_set_updated_at
before update on public.skpe_strategic_risk_items
for each row execute function public.set_updated_at();


alter table public.skpe_pestel_items enable row level security;
alter table public.skpe_swot_items enable row level security;
alter table public.skpe_tows_items enable row level security;
alter table public.skpe_strategic_risk_items enable row level security;

create policy skpe_pestel_items_select
on public.skpe_pestel_items
for select
using (public.can_view_skpe_journey(organization_id));

create policy skpe_pestel_items_manage
on public.skpe_pestel_items
for all
using (public.can_manage_skpe_journey(organization_id))
with check (public.can_manage_skpe_journey(organization_id));

create policy skpe_swot_items_select
on public.skpe_swot_items
for select
using (public.can_view_skpe_journey(organization_id));

create policy skpe_swot_items_manage
on public.skpe_swot_items
for all
using (public.can_manage_skpe_journey(organization_id))
with check (public.can_manage_skpe_journey(organization_id));

create policy skpe_tows_items_select
on public.skpe_tows_items
for select
using (public.can_view_skpe_journey(organization_id));

create policy skpe_tows_items_manage
on public.skpe_tows_items
for all
using (public.can_manage_skpe_journey(organization_id))
with check (public.can_manage_skpe_journey(organization_id));

create policy skpe_strategic_risk_items_select
on public.skpe_strategic_risk_items
for select
using (public.can_view_skpe_journey(organization_id));

create policy skpe_strategic_risk_items_manage
on public.skpe_strategic_risk_items
for all
using (public.can_manage_skpe_journey(organization_id))
with check (public.can_manage_skpe_journey(organization_id));