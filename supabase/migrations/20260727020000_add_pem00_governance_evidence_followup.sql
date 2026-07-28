-- ============================================================
-- SPARKs / SK-PE
-- Migration: PEM-00, gestao de evidencias, avaliacoes e follow-up
-- ============================================================

begin;

-- ============================================================
-- 1. FONTES DE EVIDENCIA E INTELIGENCIA DIAGNOSTICA
-- ============================================================

create table public.skpe_evidence_sources (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  journey_item_id uuid
    references public.skpe_journey_items(id) on delete set null,
  source_type text not null,
  title text not null,
  description text,
  origin_organization text,
  cycle_code text,
  reference_date date,
  status text not null default 'identified',
  reliability_level text not null default 'not_assessed',
  confidentiality_level text not null default 'internal',
  received_at timestamptz,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_evidence_sources_type_check
    check (source_type in (
      'document',
      'self_assessment',
      'assisted_diagnosis',
      'action_plan',
      'interview',
      'workshop',
      'dataset',
      'indicator_report',
      'external_report',
      'other'
    )),
  constraint skpe_evidence_sources_status_check
    check (status in (
      'identified',
      'requested',
      'received',
      'under_review',
      'validated',
      'rejected',
      'outdated',
      'missing'
    )),
  constraint skpe_evidence_sources_reliability_check
    check (reliability_level in (
      'not_assessed',
      'low',
      'medium',
      'high'
    )),
  constraint skpe_evidence_sources_confidentiality_check
    check (confidentiality_level in (
      'public',
      'internal',
      'restricted',
      'confidential'
    )),
  constraint skpe_evidence_sources_title_not_blank
    check (length(trim(title)) > 0)
);

create index idx_skpe_evidence_sources_project
  on public.skpe_evidence_sources(project_id, status);

create index idx_skpe_evidence_sources_type
  on public.skpe_evidence_sources(project_id, source_type);

create trigger skpe_evidence_sources_set_updated_at
before update on public.skpe_evidence_sources
for each row
execute function public.set_updated_at();

comment on table public.skpe_evidence_sources is
  'Fontes documentais e diagnosticas utilizadas pelo SK-PE e integraveis ao SK-DOC.';

create table public.skpe_assessment_findings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  evidence_source_id uuid not null
    references public.skpe_evidence_sources(id) on delete cascade,
  linked_journey_item_id uuid
    references public.skpe_journey_items(id) on delete set null,
  instrument_name text,
  axis_code text,
  axis_name text,
  criterion_code text,
  criterion_name text,
  requirement_code text,
  finding_type text not null,
  description text not null,
  recommendation text,
  criticality text not null default 'medium',
  recurrence_key text,
  recurrence_count integer not null default 1,
  status text not null default 'open',
  first_identified_at date,
  last_identified_at date,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_assessment_findings_type_check
    check (finding_type in (
      'strength',
      'opportunity',
      'gap',
      'risk',
      'nonconformity',
      'recommendation',
      'good_practice'
    )),
  constraint skpe_assessment_findings_criticality_check
    check (criticality in ('low', 'medium', 'high', 'critical')),
  constraint skpe_assessment_findings_status_check
    check (status in (
      'open',
      'under_treatment',
      'treated',
      'accepted',
      'recurrent',
      'discarded'
    )),
  constraint skpe_assessment_findings_recurrence_check
    check (recurrence_count >= 1),
  constraint skpe_assessment_findings_description_not_blank
    check (length(trim(description)) > 0)
);

create index idx_skpe_assessment_findings_project
  on public.skpe_assessment_findings(project_id, status, criticality);

create index idx_skpe_assessment_findings_source
  on public.skpe_assessment_findings(evidence_source_id);

create index idx_skpe_assessment_findings_recurrence
  on public.skpe_assessment_findings(project_id, recurrence_key)
  where recurrence_key is not null;

create trigger skpe_assessment_findings_set_updated_at
before update on public.skpe_assessment_findings
for each row
execute function public.set_updated_at();

comment on table public.skpe_assessment_findings is
  'Achados estruturados de autoavaliacoes, diagnosticos assistidos e demais instrumentos.';

-- ============================================================
-- 2. PLANOS DE ACAO E FOLLOW-UP
-- ============================================================

create table public.skpe_action_plans (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  evidence_source_id uuid
    references public.skpe_evidence_sources(id) on delete set null,
  code text not null,
  title text not null,
  description text,
  reference_cycle text,
  status text not null default 'active',
  progress numeric(5,2) not null default 0,
  reference_date date,
  last_reviewed_at timestamptz,
  next_review_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_action_plans_status_check
    check (status in (
      'draft',
      'active',
      'suspended',
      'completed',
      'outdated',
      'archived'
    )),
  constraint skpe_action_plans_progress_check
    check (progress between 0 and 100),
  constraint skpe_action_plans_code_not_blank
    check (length(trim(code)) > 0),
  constraint skpe_action_plans_title_not_blank
    check (length(trim(title)) > 0),
  constraint skpe_action_plans_unique
    unique (project_id, code)
);

create index idx_skpe_action_plans_project
  on public.skpe_action_plans(project_id, status);

create trigger skpe_action_plans_set_updated_at
before update on public.skpe_action_plans
for each row
execute function public.set_updated_at();

create table public.skpe_action_plan_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  action_plan_id uuid not null
    references public.skpe_action_plans(id) on delete cascade,
  finding_id uuid
    references public.skpe_assessment_findings(id) on delete set null,
  linked_journey_item_id uuid
    references public.skpe_journey_items(id) on delete set null,
  action_code text not null,
  description text not null,
  owner_user_id uuid references public.profiles(id) on delete set null,
  start_date date,
  due_date date,
  completed_at timestamptz,
  status text not null default 'not_started',
  progress numeric(5,2) not null default 0,
  priority text not null default 'medium',
  evidence_required boolean not null default true,
  effectiveness_status text not null default 'not_assessed',
  last_update_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint skpe_action_plan_items_status_check
    check (status in (
      'not_started',
      'in_progress',
      'blocked',
      'overdue',
      'pending_evidence',
      'completed',
      'cancelled'
    )),
  constraint skpe_action_plan_items_progress_check
    check (progress between 0 and 100),
  constraint skpe_action_plan_items_priority_check
    check (priority in ('low', 'medium', 'high', 'critical')),
  constraint skpe_action_plan_items_effectiveness_check
    check (effectiveness_status in (
      'not_assessed',
      'ineffective',
      'partially_effective',
      'effective'
    )),
  constraint skpe_action_plan_items_dates_check
    check (due_date is null or start_date is null or due_date >= start_date),
  constraint skpe_action_plan_items_code_not_blank
    check (length(trim(action_code)) > 0),
  constraint skpe_action_plan_items_description_not_blank
    check (length(trim(description)) > 0),
  constraint skpe_action_plan_items_unique
    unique (action_plan_id, action_code)
);

create index idx_skpe_action_plan_items_plan
  on public.skpe_action_plan_items(action_plan_id, status);

create index idx_skpe_action_plan_items_due
  on public.skpe_action_plan_items(project_id, due_date)
  where status not in ('completed', 'cancelled');

create index idx_skpe_action_plan_items_owner
  on public.skpe_action_plan_items(owner_user_id, status);

create trigger skpe_action_plan_items_set_updated_at
before update on public.skpe_action_plan_items
for each row
execute function public.set_updated_at();

create table public.skpe_action_followups (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  project_id uuid not null
    references public.skpe_projects(id) on delete cascade,
  action_item_id uuid not null
    references public.skpe_action_plan_items(id) on delete cascade,
  followup_date timestamptz not null default timezone('utc', now()),
  previous_status text,
  new_status text,
  previous_progress numeric(5,2),
  new_progress numeric(5,2),
  note text not null,
  evidence_reference text,
  effectiveness_comment text,
  created_by uuid not null
    references public.profiles(id) on delete restrict,

  constraint skpe_action_followups_note_not_blank
    check (length(trim(note)) >= 10),
  constraint skpe_action_followups_progress_check
    check (
      (previous_progress is null or previous_progress between 0 and 100)
      and (new_progress is null or new_progress between 0 and 100)
    )
);

create index idx_skpe_action_followups_item
  on public.skpe_action_followups(action_item_id, followup_date desc);

comment on table public.skpe_action_followups is
  'Historico de acompanhamento, cobranca, evidencias e efetividade das acoes.';

-- ============================================================
-- 3. PERMISSOES E RLS
-- ============================================================

insert into public.module_permissions (
  module_id,
  code,
  name,
  description
)
select
  module.id,
  permission.code,
  permission.name,
  permission.description
from public.modules module
cross join (
  values
    ('evidence.view', 'Consultar evidencias', 'Consultar fontes, achados, planos de acao e follow-ups do SK-PE.'),
    ('evidence.manage', 'Gerenciar evidencias', 'Cadastrar, validar e acompanhar evidencias, diagnosticos e planos de acao do SK-PE.')
) as permission(code, name, description)
where module.code = 'SK-PE'
on conflict (module_id, code) do update
set
  name = excluded.name,
  description = excluded.description;

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
  and permission.code = 'evidence.view'
  and role.code in (
    'administrator',
    'manager',
    'editor',
    'approver',
    'viewer'
  )
on conflict do nothing;

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
  and permission.code = 'evidence.manage'
  and role.code in (
    'administrator',
    'manager',
    'editor'
  )
on conflict do nothing;

alter table public.skpe_evidence_sources enable row level security;
alter table public.skpe_assessment_findings enable row level security;
alter table public.skpe_action_plans enable row level security;
alter table public.skpe_action_plan_items enable row level security;
alter table public.skpe_action_followups enable row level security;

create policy skpe_evidence_sources_select
on public.skpe_evidence_sources
for select to authenticated
using (public.can_view_skpe_journey(organization_id));

create policy skpe_assessment_findings_select
on public.skpe_assessment_findings
for select to authenticated
using (public.can_view_skpe_journey(organization_id));

create policy skpe_action_plans_select
on public.skpe_action_plans
for select to authenticated
using (public.can_view_skpe_journey(organization_id));

create policy skpe_action_plan_items_select
on public.skpe_action_plan_items
for select to authenticated
using (public.can_view_skpe_journey(organization_id));

create policy skpe_action_followups_select
on public.skpe_action_followups
for select to authenticated
using (public.can_view_skpe_journey(organization_id));

revoke all on table public.skpe_evidence_sources from anon;
revoke all on table public.skpe_assessment_findings from anon;
revoke all on table public.skpe_action_plans from anon;
revoke all on table public.skpe_action_plan_items from anon;
revoke all on table public.skpe_action_followups from anon;

-- ============================================================
-- 4. NOVA VERSAO CANONICA DO MODELO: SK-PE-2026.2
-- ============================================================

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
  template.id,
  'SK-PE-2026.2',
  'SK-PE Canonica 2026.2',
  'Versao canonica com PEM-00, governanca transversal, gestao de evidencias, autoavaliacoes, diagnosticos assistidos e follow-up de planos de acao.',
  'published',
  date '2026-07-27',
  timezone('utc', now()),
  'Inclui a Macrofase 00 e a inteligencia de evidencias e execucao. Mantem as demais macrofases e reforca o acompanhamento de planos existentes.'
from public.skpe_methodology_templates template
where template.code = 'SKPE-OFICIAL'
on conflict (template_id, version_code) do update
set
  name = excluded.name,
  description = excluded.description,
  status = excluded.status,
  effective_from = excluded.effective_from,
  published_at = excluded.published_at,
  release_notes = excluded.release_notes;

-- Copia a arvore da versao 2026.1 para 2026.2 preservando a hierarquia.
do $$
declare
  source_version_id uuid;
  target_version_id uuid;
  source_item record;
  target_parent_id uuid;
  target_item_id uuid;
begin
  select source_version.id
    into source_version_id
  from public.skpe_methodology_template_versions source_version
  join public.skpe_methodology_templates template
    on template.id = source_version.template_id
  where template.code = 'SKPE-OFICIAL'
    and source_version.version_code = 'SK-PE-2026.1';

  select target_version.id
    into target_version_id
  from public.skpe_methodology_template_versions target_version
  join public.skpe_methodology_templates template
    on template.id = target_version.template_id
  where template.code = 'SKPE-OFICIAL'
    and target_version.version_code = 'SK-PE-2026.2';

  create temporary table if not exists pg_temp.skpe_version_copy_map (
    source_item_id uuid primary key,
    target_item_id uuid not null
  ) on commit drop;

  truncate table pg_temp.skpe_version_copy_map;

  for source_item in
    with recursive source_tree as (
      select item.*, 0 as depth
      from public.skpe_methodology_template_items item
      where item.template_version_id = source_version_id
        and item.parent_item_id is null

      union all

      select child.*, parent.depth + 1
      from public.skpe_methodology_template_items child
      join source_tree parent
        on parent.id = child.parent_item_id
    )
    select *
    from source_tree
    order by depth, display_order, code
  loop
    target_parent_id := null;

    if source_item.parent_item_id is not null then
      select map.target_item_id
        into target_parent_id
      from pg_temp.skpe_version_copy_map map
      where map.source_item_id = source_item.parent_item_id;
    end if;

    insert into public.skpe_methodology_template_items (
      template_version_id,
      parent_item_id,
      item_type,
      code,
      name,
      description,
      display_order,
      is_mandatory,
      is_recommended,
      default_duration_days,
      validation_required,
      completion_criteria,
      metadata
    )
    values (
      target_version_id,
      target_parent_id,
      source_item.item_type,
      source_item.code,
      source_item.name,
      source_item.description,
      source_item.display_order + 100,
      source_item.is_mandatory,
      source_item.is_recommended,
      source_item.default_duration_days,
      source_item.validation_required,
      source_item.completion_criteria,
      source_item.metadata || jsonb_build_object(
        'copied_from_version', 'SK-PE-2026.1',
        'copied_from_item_id', source_item.id
      )
    )
    on conflict (template_version_id, code) do update
    set
      parent_item_id = excluded.parent_item_id,
      item_type = excluded.item_type,
      name = excluded.name,
      description = excluded.description,
      display_order = excluded.display_order,
      is_mandatory = excluded.is_mandatory,
      is_recommended = excluded.is_recommended,
      default_duration_days = excluded.default_duration_days,
      validation_required = excluded.validation_required,
      completion_criteria = excluded.completion_criteria,
      metadata = excluded.metadata
    returning id into target_item_id;

    insert into pg_temp.skpe_version_copy_map (
      source_item_id,
      target_item_id
    )
    values (
      source_item.id,
      target_item_id
    )
    on conflict (source_item_id) do update
    set target_item_id = excluded.target_item_id;
  end loop;
end;
$$;

-- Insere a PEM-00 como primeira macrofase.
with target_version as (
  select version.id
  from public.skpe_methodology_template_versions version
  join public.skpe_methodology_templates template
    on template.id = version.template_id
  where template.code = 'SKPE-OFICIAL'
    and version.version_code = 'SK-PE-2026.2'
)
insert into public.skpe_methodology_template_items (
  template_version_id,
  item_type,
  code,
  name,
  description,
  display_order,
  is_mandatory,
  is_recommended,
  validation_required,
  completion_criteria,
  metadata
)
select
  target_version.id,
  'macrophase',
  'PEM-00',
  'Governanca, Abertura e Gestao de Evidencias',
  'Estabelecer mandato, governanca, caracterizacao, checklist dinamico, base de evidencias e prontidao para o diagnostico.',
  10,
  true,
  true,
  true,
  '["Mandato e escopo validados", "Governanca e ritos definidos", "Checklist dinamico emitido", "Evidencias criticas recebidas e classificadas", "Autoavaliacoes e diagnosticos analisados", "Planos de acao anteriores avaliados", "Gate de prontidao aprovado"]'::jsonb,
  jsonb_build_object(
    'transversal_governance', true,
    'skdoc_integration', true,
    'dynamic_checklist', true,
    'assessment_intelligence', true,
    'action_plan_followup', true
  )
from target_version
on conflict (template_version_id, code) do update
set
  name = excluded.name,
  description = excluded.description,
  display_order = excluded.display_order,
  validation_required = excluded.validation_required,
  completion_criteria = excluded.completion_criteria,
  metadata = excluded.metadata;

-- Reordena as macrofases copiadas para depois da PEM-00.
update public.skpe_methodology_template_items item
set display_order = case item.code
  when 'PEM-01' then 20
  when 'PEM-02' then 30
  when 'PEM-03' then 40
  when 'PEM-04' then 50
  when 'PEM-05' then 60
  else item.display_order
end
from public.skpe_methodology_template_versions version
join public.skpe_methodology_templates template
  on template.id = version.template_id
where item.template_version_id = version.id
  and template.code = 'SKPE-OFICIAL'
  and version.version_code = 'SK-PE-2026.2'
  and item.item_type = 'macrophase';

-- Ajusta as duas primeiras fases da PEM-01, que antes concentravam abertura e evidencias.
update public.skpe_methodology_template_items item
set
  name = case item.code
    when 'PEM-01.01' then 'Consolidacao da Base Diagnostica'
    when 'PEM-01.02' then 'Analise de Avaliacoes, Diagnosticos e Planos Anteriores'
    else item.name
  end,
  description = case item.code
    when 'PEM-01.01' then 'Consolidar e qualificar as evidencias validadas na PEM-00 para uso nas analises diagnosticas.'
    when 'PEM-01.02' then 'Interpretar autoavaliacoes, diagnosticos assistidos, lacunas recorrentes, planos anteriores e sua efetividade.'
    else item.description
  end,
  completion_criteria = case item.code
    when 'PEM-01.01' then '["Base diagnostica consolidada", "Evidencias criticas rastreaveis"]'::jsonb
    when 'PEM-01.02' then '["Lacunas historicas analisadas", "Planos anteriores classificados", "Reincidencias identificadas"]'::jsonb
    else item.completion_criteria
  end
from public.skpe_methodology_template_versions version
join public.skpe_methodology_templates template
  on template.id = version.template_id
where item.template_version_id = version.id
  and template.code = 'SKPE-OFICIAL'
  and version.version_code = 'SK-PE-2026.2'
  and item.code in ('PEM-01.01', 'PEM-01.02');

-- Fases da PEM-00.
with target_version as (
  select version.id
  from public.skpe_methodology_template_versions version
  join public.skpe_methodology_templates template
    on template.id = version.template_id
  where template.code = 'SKPE-OFICIAL'
    and version.version_code = 'SK-PE-2026.2'
), parent_item as (
  select item.id, item.template_version_id
  from public.skpe_methodology_template_items item
  join target_version
    on target_version.id = item.template_version_id
  where item.code = 'PEM-00'
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
  is_recommended,
  validation_required,
  completion_criteria,
  metadata
)
select
  parent_item.template_version_id,
  parent_item.id,
  data.item_type,
  data.code,
  data.name,
  data.description,
  data.display_order,
  true,
  true,
  data.validation_required,
  data.criteria::jsonb,
  data.metadata::jsonb
from parent_item
cross join (
  values
    ('phase', 'PEM-00.01', 'Abertura, Mandato e Escopo', 'Formalizar contratacao, objetivos, limites, premissas, patrocinio e criterios de sucesso.', 11, false, '["Termo de abertura validado", "Mandato e escopo confirmados"]', '{"governance":true}'),
    ('phase', 'PEM-00.02', 'Governanca, Papeis e Ritos', 'Definir patrocinadores, comites, papeis, responsabilidades, cadencias, foruns e regras de decisao.', 12, false, '["Matriz de governanca aprovada", "Ritos e foruns definidos"]', '{"governance":true,"transversal":true}'),
    ('phase', 'PEM-00.03', 'Caracterizacao da Organizacao', 'Registrar natureza, tipo, ramo, porte, estrutura, territorio, maturidade e demais atributos que orientam o metodo.', 13, false, '["Perfil organizacional consolidado"]', '{"dynamic_checklist_input":true}'),
    ('phase', 'PEM-00.04', 'Checklist Dinamico de Informacoes', 'Gerar e validar o checklist conforme contexto, porte, ramo, maturidade, escopo e modelos de referencia aplicaveis.', 14, false, '["Checklist dinamico emitido", "Responsaveis e prazos definidos"]', '{"dynamic_checklist":true}'),
    ('phase', 'PEM-00.05', 'Gestao de Evidencias e Integracao SK-DOC', 'Solicitar, receber, classificar, validar, proteger e vincular evidencias as analises e decisoes do projeto.', 15, false, '["Repositorio de evidencias estruturado", "Evidencias criticas validadas"]', '{"skdoc_integration":true,"evidence_management":true}'),
    ('phase', 'PEM-00.06', 'Autoavaliacoes e Diagnosticos Assistidos', 'Importar e estruturar eixos, criterios, resultados, lacunas, recomendacoes e historico de instrumentos anteriores.', 16, false, '["Instrumentos anteriores inventariados", "Achados estruturados"]', '{"assessment_intelligence":true}'),
    ('phase', 'PEM-00.07', 'Planos de Acao e Follow-up', 'Analisar planos existentes, atualizacao, execucao, evidencias, atrasos, paralisacoes, reincidencias e efetividade.', 17, false, '["Planos anteriores classificados", "Acoes paradas identificadas", "Follow-up definido"]', '{"action_plan_followup":true}'),
    ('phase', 'PEM-00.08', 'Lacunas, Pendencias e Prontidao', 'Consolidar lacunas de informacao, riscos de qualidade, pendencias criticas e nivel de prontidao para o diagnostico.', 18, false, '["Lacunas e pendencias registradas", "Nivel de prontidao calculado"]', '{"readiness":true}'),
    ('gate', 'PEM-00.GATE', 'Gate 00 - Prontidao para o Diagnostico', 'Autorizar o inicio da PEM-01 mediante mandato, governanca, evidencias minimas, lacunas conhecidas e plano de complementacao.', 19, true, '["Mandato validado", "Governanca definida", "Checklist emitido", "Evidencias minimas recebidas", "Lacunas registradas", "Plano de complementacao aprovado"]', '{"readiness_gate":true}')
) as data(
  item_type,
  code,
  name,
  description,
  display_order,
  validation_required,
  criteria,
  metadata
)
on conflict (template_version_id, code) do update
set
  parent_item_id = excluded.parent_item_id,
  item_type = excluded.item_type,
  name = excluded.name,
  description = excluded.description,
  display_order = excluded.display_order,
  validation_required = excluded.validation_required,
  completion_criteria = excluded.completion_criteria,
  metadata = excluded.metadata;

-- Atividades e entregaveis criticos da PEM-00.
with target_version as (
  select version.id
  from public.skpe_methodology_template_versions version
  join public.skpe_methodology_templates template
    on template.id = version.template_id
  where template.code = 'SKPE-OFICIAL'
    and version.version_code = 'SK-PE-2026.2'
), parent_items as (
  select item.id, item.code, item.template_version_id
  from public.skpe_methodology_template_items item
  join target_version
    on target_version.id = item.template_version_id
  where item.code in (
    'PEM-00.04',
    'PEM-00.05',
    'PEM-00.06',
    'PEM-00.07',
    'PEM-00.08'
  )
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
  is_recommended,
  validation_required,
  completion_criteria,
  metadata
)
select
  parent_items.template_version_id,
  parent_items.id,
  data.item_type,
  data.code,
  data.name,
  data.description,
  data.display_order,
  data.is_mandatory,
  true,
  data.validation_required,
  data.criteria::jsonb,
  data.metadata::jsonb
from parent_items
join (
  values
    ('PEM-00.04', 'activity', 'PEM-00.04.01', 'Gerar Checklist Contextualizado', 'Combinar regras por tipo, natureza, ramo, porte, maturidade, escopo e modelo de referencia.', 141, true, false, '["Checklist gerado"]', '{"wizard_ready":true}'),
    ('PEM-00.04', 'deliverable', 'PEM-00.04.ED01', 'Checklist de Informacoes e Evidencias', 'Lista controlada de informacoes, responsaveis, prazos, criticidade e situacao de atendimento.', 149, true, true, '["Checklist aprovado"]', '{"skdoc_integration":true}'),
    ('PEM-00.05', 'activity', 'PEM-00.05.01', 'Solicitar e Receber Evidencias', 'Controlar solicitacoes, recebimentos, pendencias e responsaveis.', 151, true, false, '["Solicitacoes controladas"]', '{"skdoc_integration":true}'),
    ('PEM-00.05', 'activity', 'PEM-00.05.02', 'Classificar e Validar Evidencias', 'Avaliar origem, atualidade, completude, confiabilidade, confidencialidade e aderencia.', 152, true, false, '["Evidencias classificadas e validadas"]', '{"skdoc_integration":true}'),
    ('PEM-00.05', 'deliverable', 'PEM-00.05.ED01', 'Base de Evidencias do Projeto', 'Repositorio rastreavel das evidencias aceitas, rejeitadas, ausentes e desatualizadas.', 159, true, true, '["Base de evidencias disponivel"]', '{"skdoc_integration":true}'),
    ('PEM-00.06', 'activity', 'PEM-00.06.01', 'Inventariar Instrumentos Anteriores', 'Identificar autoavaliacoes, diagnosticos assistidos, ciclos, eixos, criterios e relatorios disponiveis.', 161, true, false, '["Inventario concluido"]', '{"assessment_intelligence":true}'),
    ('PEM-00.06', 'activity', 'PEM-00.06.02', 'Estruturar Achados e Reincidencias', 'Extrair lacunas, riscos, recomendacoes, fortalezas, criticidade e repeticao entre ciclos.', 162, true, false, '["Achados estruturados", "Reincidencias calculadas"]', '{"assessment_intelligence":true}'),
    ('PEM-00.06', 'deliverable', 'PEM-00.06.ED01', 'Matriz de Achados de Avaliacoes e Diagnosticos', 'Visao consolidada por instrumento, eixo, criterio, criticidade, recorrencia e situacao.', 169, true, true, '["Matriz validada"]', '{"assessment_intelligence":true}'),
    ('PEM-00.07', 'activity', 'PEM-00.07.01', 'Inventariar Planos de Acao Existentes', 'Registrar planos, acoes, responsaveis, prazos, status, evidencias e ultima atualizacao.', 171, true, false, '["Planos inventariados"]', '{"action_plan_followup":true}'),
    ('PEM-00.07', 'activity', 'PEM-00.07.02', 'Avaliar Execucao e Efetividade', 'Distinguir execucao declarada, execucao comprovada, atraso, paralisacao e resultado efetivo.', 172, true, false, '["Execucao e efetividade avaliadas"]', '{"action_plan_followup":true}'),
    ('PEM-00.07', 'activity', 'PEM-00.07.03', 'Configurar Cadencia de Follow-up', 'Definir alertas, responsaveis, reunioes, evidencias obrigatorias e escalonamento de pendencias.', 173, true, false, '["Cadencia de follow-up definida"]', '{"action_plan_followup":true}'),
    ('PEM-00.07', 'deliverable', 'PEM-00.07.ED01', 'Painel de Planos Anteriores e Follow-up', 'Painel de acoes vencidas, paradas, sem evidencias, reincidentes e sem efetividade.', 179, true, true, '["Painel validado"]', '{"action_plan_followup":true}'),
    ('PEM-00.08', 'activity', 'PEM-00.08.01', 'Calcular Prontidao Diagnostica', 'Avaliar atendimento do checklist, cobertura das evidencias e riscos de informacao.', 181, true, false, '["Prontidao calculada"]', '{"readiness":true}'),
    ('PEM-00.08', 'deliverable', 'PEM-00.08.ED01', 'Relatorio de Prontidao, Lacunas e Pendencias', 'Consolidar lacunas, impactos, responsaveis, prazos e plano de complementacao.', 189, true, true, '["Relatorio aprovado"]', '{"readiness":true}')
) as data(
  parent_code,
  item_type,
  code,
  name,
  description,
  display_order,
  is_mandatory,
  validation_required,
  criteria,
  metadata
)
  on data.parent_code = parent_items.code
on conflict (template_version_id, code) do update
set
  parent_item_id = excluded.parent_item_id,
  item_type = excluded.item_type,
  name = excluded.name,
  description = excluded.description,
  display_order = excluded.display_order,
  is_mandatory = excluded.is_mandatory,
  validation_required = excluded.validation_required,
  completion_criteria = excluded.completion_criteria,
  metadata = excluded.metadata;

-- ============================================================
-- 5. BACKFILL DA JORNADA PARA PROJETOS EXISTENTES
-- ============================================================

create or replace function public.backfill_skpe_project_journey_from_template(
  target_project_id uuid
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_project public.skpe_projects%rowtype;
  template_item record;
  resolved_parent_id uuid;
  existing_item_id uuid;
  inserted_count integer := 0;
begin
  select *
    into target_project
  from public.skpe_projects
  where id = target_project_id;

  if target_project.id is null then
    raise exception 'Projeto nao encontrado.';
  end if;

  if auth.uid() is not null
     and not public.can_manage_skpe_journey(target_project.organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode complementar a jornada deste projeto.'
      using errcode = '42501';
  end if;

  if auth.uid() is null
     and session_user not in ('postgres', 'supabase_admin') then
    raise exception
      'Acesso negado: contexto administrativo invalido.'
      using errcode = '42501';
  end if;

  if target_project.methodology_template_version_id is null then
    raise exception 'O projeto nao possui versao metodologica vinculada.';
  end if;

  create temporary table if not exists pg_temp.skpe_backfill_map (
    template_item_id uuid primary key,
    journey_item_id uuid not null
  ) on commit drop;

  truncate table pg_temp.skpe_backfill_map;

  for template_item in
    with recursive template_tree as (
      select item.*, 0 as depth
      from public.skpe_methodology_template_items item
      where item.template_version_id =
        target_project.methodology_template_version_id
        and item.parent_item_id is null

      union all

      select child.*, parent.depth + 1
      from public.skpe_methodology_template_items child
      join template_tree parent
        on parent.id = child.parent_item_id
    )
    select *
    from template_tree
    order by depth, display_order, code
  loop
    resolved_parent_id := null;

    if template_item.parent_item_id is not null then
      select journey_item_id
        into resolved_parent_id
      from pg_temp.skpe_backfill_map
      where template_item_id = template_item.parent_item_id;
    end if;

    select journey.id
      into existing_item_id
    from public.skpe_journey_items journey
    where journey.project_id = target_project.id
      and journey.code = template_item.code
    limit 1;

    if existing_item_id is null then
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
        target_project.id,
        resolved_parent_id,
        template_item.item_type,
        template_item.code,
        template_item.name,
        template_item.description,
        'not_started',
        0,
        template_item.display_order,
        false,
        template_item.is_mandatory,
        target_project.start_date,
        case
          when target_project.start_date is null
            or template_item.default_duration_days is null
          then null
          else target_project.start_date
            + template_item.default_duration_days
        end,
        template_item.validation_required,
        case
          when template_item.validation_required
          then 'pending'
          else 'not_required'
        end,
        jsonb_build_object(
          'template_item_id', template_item.id,
          'completion_criteria', template_item.completion_criteria,
          'template_metadata', template_item.metadata,
          'backfilled_at', timezone('utc', now())
        ),
        auth.uid(),
        auth.uid()
      )
      returning id into existing_item_id;

      inserted_count := inserted_count + 1;
    else
      update public.skpe_journey_items
      set
        parent_item_id = resolved_parent_id,
        item_type = template_item.item_type,
        name = template_item.name,
        description = template_item.description,
        display_order = template_item.display_order,
        is_mandatory = template_item.is_mandatory,
        validation_required = template_item.validation_required,
        metadata = coalesce(metadata, '{}'::jsonb)
          || jsonb_build_object(
            'template_item_id', template_item.id,
            'completion_criteria', template_item.completion_criteria,
            'template_metadata', template_item.metadata
          ),
        updated_at = timezone('utc', now()),
        updated_by = auth.uid()
      where id = existing_item_id;
    end if;

    insert into pg_temp.skpe_backfill_map (
      template_item_id,
      journey_item_id
    )
    values (
      template_item.id,
      existing_item_id
    )
    on conflict (template_item_id) do update
    set journey_item_id = excluded.journey_item_id;
  end loop;

  return inserted_count;
end;
$$;

revoke all on function
  public.backfill_skpe_project_journey_from_template(uuid)
  from public, anon;

grant execute on function
  public.backfill_skpe_project_journey_from_template(uuid)
  to authenticated, service_role;

-- Atualiza o projeto inicial da COOTAQUARA para a nova versao e complementa a arvore.
do $$
declare
  target_project_id uuid;
  target_version_id uuid;
  target_template_id uuid;
  inserted_items integer;
begin
  select version.id, template.id
    into target_version_id, target_template_id
  from public.skpe_methodology_template_versions version
  join public.skpe_methodology_templates template
    on template.id = version.template_id
  where template.code = 'SKPE-OFICIAL'
    and version.version_code = 'SK-PE-2026.2';

  select project.id
    into target_project_id
  from public.skpe_projects project
  join public.organizations organization
    on organization.id = project.organization_id
  where organization.code = 'COOTAQUARA'
    and project.code = 'PE-COOTAQUARA-2026'
  limit 1;

  if target_project_id is not null then
    update public.skpe_projects
    set
      methodology_template_id = target_template_id,
      methodology_template_version_id = target_version_id,
      methodology_version = 'SK-PE-2026.2',
      template_cloned_at = timezone('utc', now()),
      configuration = coalesce(configuration, '{}'::jsonb)
        || jsonb_build_object(
          'pem00_enabled', true,
          'governance_transversal', true,
          'skdoc_evidence_integration', true,
          'assessment_followup_enabled', true
        )
    where id = target_project_id;

    inserted_items :=
      public.backfill_skpe_project_journey_from_template(
        target_project_id
      );
  end if;
end;
$$;

-- ============================================================
-- 6. FUNCAO DE RESUMO PARA FOLLOW-UP EXECUTIVO
-- ============================================================

create or replace function public.get_skpe_action_followup_summary(
  target_organization_id uuid
)
returns table (
  total_actions bigint,
  completed_actions bigint,
  overdue_actions bigint,
  stalled_30_days bigint,
  stalled_60_days bigint,
  stalled_90_days bigint,
  actions_without_evidence bigint,
  recurrent_findings bigint,
  completion_rate numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_journey(target_organization_id) then
    raise exception
      'Acesso negado: o usuario nao pode consultar o follow-up desta organizacao.'
      using errcode = '42501';
  end if;

  return query
  select
    count(item.id)::bigint,
    count(item.id) filter (
      where item.status = 'completed'
    )::bigint,
    count(item.id) filter (
      where item.due_date < current_date
        and item.status not in ('completed', 'cancelled')
    )::bigint,
    count(item.id) filter (
      where coalesce(item.last_update_at, item.created_at)
        < timezone('utc', now()) - interval '30 days'
        and item.status not in ('completed', 'cancelled')
    )::bigint,
    count(item.id) filter (
      where coalesce(item.last_update_at, item.created_at)
        < timezone('utc', now()) - interval '60 days'
        and item.status not in ('completed', 'cancelled')
    )::bigint,
    count(item.id) filter (
      where coalesce(item.last_update_at, item.created_at)
        < timezone('utc', now()) - interval '90 days'
        and item.status not in ('completed', 'cancelled')
    )::bigint,
    count(item.id) filter (
      where item.status = 'completed'
        and item.evidence_required = true
        and not exists (
          select 1
          from public.skpe_action_followups followup
          where followup.action_item_id = item.id
            and nullif(trim(followup.evidence_reference), '') is not null
        )
    )::bigint,
    (
      select count(finding.id)::bigint
      from public.skpe_assessment_findings finding
      where finding.organization_id = target_organization_id
        and finding.recurrence_count > 1
        and finding.status <> 'discarded'
    ),
    case
      when count(item.id) = 0 then 0::numeric
      else round(
        100.0
        * count(item.id) filter (
          where item.status = 'completed'
        )
        / count(item.id),
        2
      )
    end
  from public.skpe_action_plan_items item
  where item.organization_id = target_organization_id;
end;
$$;

revoke all on function
  public.get_skpe_action_followup_summary(uuid)
  from public, anon;

grant execute on function
  public.get_skpe_action_followup_summary(uuid)
  to authenticated, service_role;

commit;
