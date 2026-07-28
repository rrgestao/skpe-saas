-- ============================================================
-- Plataforma SPARKs / Planejamento Estratégico
-- Governança Operacional: Papéis, Responsabilidades e Domínios
-- Data: 2026-07-27
-- ============================================================

begin;

-- ============================================================
-- 1. DOMÍNIOS TRANSVERSAIS DA PLATAFORMA
-- ============================================================

create table if not exists public.sparks_domains (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  scope_type text not null default 'global',
  module_code text,
  organization_id uuid references public.organizations(id) on delete cascade,
  allow_organization_extension boolean not null default false,
  protected boolean not null default true,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_domains_code_not_blank
    check (length(trim(code)) > 0),
  constraint sparks_domains_name_not_blank
    check (length(trim(name)) > 0),
  constraint sparks_domains_scope_check
    check (scope_type in ('global', 'module', 'organization')),
  constraint sparks_domains_scope_consistency_check
    check (
      (scope_type = 'global' and module_code is null and organization_id is null)
      or (scope_type = 'module' and module_code is not null and organization_id is null)
      or (scope_type = 'organization' and organization_id is not null)
    )
);

create unique index if not exists idx_sparks_domains_unique_global
  on public.sparks_domains(code)
  where scope_type = 'global' and organization_id is null and module_code is null;

create unique index if not exists idx_sparks_domains_unique_module
  on public.sparks_domains(module_code, code)
  where scope_type = 'module' and organization_id is null;

create unique index if not exists idx_sparks_domains_unique_organization
  on public.sparks_domains(organization_id, code)
  where scope_type = 'organization';

create index if not exists idx_sparks_domains_active
  on public.sparks_domains(active, scope_type, module_code);

create trigger sparks_domains_set_updated_at
before update on public.sparks_domains
for each row
execute function public.set_updated_at();

create table if not exists public.sparks_domain_values (
  id uuid primary key default gen_random_uuid(),
  domain_id uuid not null references public.sparks_domains(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  display_order integer not null default 100,
  parent_value_id uuid references public.sparks_domain_values(id) on delete set null,
  color_token text,
  icon_name text,
  valid_from date,
  valid_until date,
  protected boolean not null default true,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  constraint sparks_domain_values_code_not_blank
    check (length(trim(code)) > 0),
  constraint sparks_domain_values_name_not_blank
    check (length(trim(name)) > 0),
  constraint sparks_domain_values_dates_check
    check (valid_until is null or valid_from is null or valid_until >= valid_from),
  constraint sparks_domain_values_unique_code
    unique (domain_id, code)
);

create index if not exists idx_sparks_domain_values_active
  on public.sparks_domain_values(domain_id, active, display_order, name);

create trigger sparks_domain_values_set_updated_at
before update on public.sparks_domain_values
for each row
execute function public.set_updated_at();

-- ============================================================
-- 2. DOMÍNIOS CANÔNICOS INICIAIS
-- ============================================================

insert into public.sparks_domains (
  code, name, description, scope_type, module_code,
  allow_organization_extension, protected, active
)
values
  ('RESPONSIBILITY_TYPE', 'Tipos de responsabilidade', 'Responsabilidades atribuíveis aos objetos estratégicos.', 'global', null, true, true, true),
  ('ORGANIZATIONAL_ROLE_TYPE', 'Tipos de papel organizacional', 'Natureza dos papéis, funções, cargos e designações.', 'global', null, true, true, true),
  ('AUTHORITY_LEVEL', 'Níveis de autoridade', 'Níveis de autoridade para decisão, aprovação e validação.', 'global', null, true, true, true),
  ('DECISION_TYPE', 'Tipos de decisão', 'Categorias de decisões registradas na governança estratégica.', 'module', 'SK-PE', true, true, true),
  ('APPROVAL_STATUS', 'Situações de aprovação', 'Estados do fluxo de aprovação de objetos estratégicos.', 'module', 'SK-PE', false, true, true),
  ('VALIDATION_STATUS', 'Situações de validação', 'Estados do fluxo de validação de conteúdos e entregáveis.', 'module', 'SK-PE', false, true, true),
  ('STRATEGIC_OBJECT_TYPE', 'Tipos de objeto estratégico', 'Objetos que podem receber responsabilidades na jornada estratégica.', 'module', 'SK-PE', false, true, true),
  ('MEASUREMENT_FREQUENCY', 'Periodicidades de medição', 'Frequências usadas em indicadores, metas e revisões.', 'module', 'SK-PE', true, true, true),
  ('MEASUREMENT_UNIT', 'Unidades de medida', 'Unidades padronizadas para indicadores e metas.', 'module', 'SK-PE', true, true, true),
  ('INDICATOR_POLARITY', 'Polaridade de indicadores', 'Direção desejada de evolução de um indicador.', 'module', 'SK-PE', false, true, true),
  ('REVIEW_CYCLE', 'Ciclos de revisão', 'Periodicidades de revisão da estratégia.', 'module', 'SK-PE', true, true, true),
  ('RISK_LEVEL', 'Níveis de risco', 'Classificação padronizada da exposição ao risco.', 'global', null, false, true, true)
on conflict do nothing;

with domain as (
  select id from public.sparks_domains where code = 'RESPONSIBILITY_TYPE' and scope_type = 'global'
)
insert into public.sparks_domain_values (domain_id, code, name, description, display_order, protected)
select domain.id, value_data.code, value_data.name, value_data.description, value_data.display_order, true
from domain
cross join (values
  ('sponsor', 'Patrocinador', 'Assegura apoio institucional, legitimidade e recursos.', 10),
  ('owner', 'Responsável', 'Responde primariamente pelo resultado do objeto.', 20),
  ('co_owner', 'Corresponsável', 'Compartilha a responsabilidade principal.', 30),
  ('approver', 'Aprovador', 'Possui autoridade formal para aprovar.', 40),
  ('validator', 'Validador', 'Verifica aderência, qualidade e suficiência antes da aprovação.', 50),
  ('executor', 'Executor', 'Executa atividades e entregas vinculadas ao objeto.', 60),
  ('facilitator', 'Facilitador', 'Apoia a condução metodológica e a articulação.', 70),
  ('consulted', 'Consultado', 'Deve ser consultado antes da decisão ou execução.', 80),
  ('informed', 'Informado', 'Deve ser comunicado sobre decisões e resultados.', 90),
  ('data_owner', 'Responsável pelo dado', 'Responde pela origem, integridade e atualização do dado.', 100),
  ('indicator_owner', 'Responsável pelo indicador', 'Responde pela medição, análise e reporte do indicador.', 110),
  ('team_member', 'Membro da equipe', 'Integra a equipe responsável pela realização.', 120)
) as value_data(code, name, description, display_order)
on conflict (domain_id, code) do update
set name = excluded.name, description = excluded.description, display_order = excluded.display_order, active = true;

with domain as (
  select id from public.sparks_domains where code = 'ORGANIZATIONAL_ROLE_TYPE' and scope_type = 'global'
)
insert into public.sparks_domain_values (domain_id, code, name, description, display_order, protected)
select domain.id, value_data.code, value_data.name, value_data.description, value_data.display_order, true
from domain
cross join (values
  ('job', 'Cargo', 'Cargo permanente na estrutura organizacional.', 10),
  ('function', 'Função', 'Função exercida sem necessariamente representar um cargo.', 20),
  ('governance', 'Governança', 'Papel em órgão de administração, fiscalização ou governança.', 30),
  ('committee', 'Comitê ou comissão', 'Participação em comitê, comissão ou grupo colegiado.', 40),
  ('project', 'Projeto', 'Papel temporário vinculado a projeto.', 50),
  ('process', 'Processo', 'Papel vinculado à gestão ou execução de processo.', 60),
  ('temporary', 'Designação temporária', 'Designação com prazo ou finalidade específica.', 70)
) as value_data(code, name, description, display_order)
on conflict (domain_id, code) do update
set name = excluded.name, description = excluded.description, display_order = excluded.display_order, active = true;

with domain as (
  select id from public.sparks_domains where code = 'AUTHORITY_LEVEL' and scope_type = 'global'
)
insert into public.sparks_domain_values (domain_id, code, name, description, display_order, protected)
select domain.id, value_data.code, value_data.name, value_data.description, value_data.display_order, true
from domain
cross join (values
  ('operational', 'Operacional', 'Autoridade limitada à execução operacional.', 10),
  ('tactical', 'Tático', 'Autoridade gerencial e de coordenação.', 20),
  ('executive', 'Executivo', 'Autoridade executiva sobre unidades, programas ou resultados.', 30),
  ('governance', 'Governança', 'Autoridade de órgão colegiado ou instância formal de governança.', 40),
  ('statutory', 'Estatutário', 'Autoridade decorrente do estatuto, regimento ou mandato legal.', 50)
) as value_data(code, name, description, display_order)
on conflict (domain_id, code) do update
set name = excluded.name, description = excluded.description, display_order = excluded.display_order, active = true;

with domain as (
  select id from public.sparks_domains where code = 'STRATEGIC_OBJECT_TYPE' and module_code = 'SK-PE'
)
insert into public.sparks_domain_values (domain_id, code, name, description, display_order, protected)
select domain.id, value_data.code, value_data.name, value_data.description, value_data.display_order, true
from domain
cross join (values
  ('strategic_project', 'Projeto estratégico', 'Projeto que organiza a jornada de formulação e execução da estratégia.', 10),
  ('journey_item', 'Item da jornada', 'Macrofase, fase, etapa, atividade, entregável ou gate.', 20),
  ('strategic_driver', 'Direcionador estratégico', 'Missão, visão, valores, propósito ou diretriz.', 30),
  ('strategic_theme', 'Tema estratégico', 'Tema agregador das escolhas estratégicas.', 40),
  ('strategic_objective', 'Objetivo Estratégico — OKR', 'Objetivo estratégico ou objetivo de OKR.', 50),
  ('key_result', 'Resultado-chave', 'Resultado-chave associado a um objetivo.', 60),
  ('indicator', 'Indicador', 'Indicador de desempenho ou resultado.', 70),
  ('target', 'Meta', 'Meta vinculada a indicador, objetivo ou resultado-chave.', 80),
  ('initiative', 'Iniciativa', 'Programa, projeto, melhoria, processo ou ação.', 90),
  ('risk', 'Risco', 'Risco estratégico ou operacional relacionado à estratégia.', 100),
  ('decision', 'Decisão', 'Decisão estratégica sujeita a governança.', 110),
  ('evidence', 'Evidência', 'Evidência que demonstra realização, validação ou conformidade.', 120)
) as value_data(code, name, description, display_order)
on conflict (domain_id, code) do update
set name = excluded.name, description = excluded.description, display_order = excluded.display_order, active = true;

with domain as (
  select id from public.sparks_domains where code = 'APPROVAL_STATUS' and module_code = 'SK-PE'
)
insert into public.sparks_domain_values (domain_id, code, name, display_order, protected)
select domain.id, value_data.code, value_data.name, value_data.display_order, true
from domain
cross join (values
  ('draft', 'Rascunho', 10),
  ('pending', 'Aguardando aprovação', 20),
  ('approved', 'Aprovado', 30),
  ('approved_with_conditions', 'Aprovado com condicionantes', 40),
  ('rejected', 'Rejeitado', 50),
  ('revoked', 'Aprovação revogada', 60)
) as value_data(code, name, display_order)
on conflict (domain_id, code) do update
set name = excluded.name, display_order = excluded.display_order, active = true;

with domain as (
  select id from public.sparks_domains where code = 'MEASUREMENT_FREQUENCY' and module_code = 'SK-PE'
)
insert into public.sparks_domain_values (domain_id, code, name, display_order, protected)
select domain.id, value_data.code, value_data.name, value_data.display_order, true
from domain
cross join (values
  ('daily', 'Diária', 10), ('weekly', 'Semanal', 20), ('biweekly', 'Quinzenal', 30),
  ('monthly', 'Mensal', 40), ('bimonthly', 'Bimestral', 50), ('quarterly', 'Trimestral', 60),
  ('four_monthly', 'Quadrimestral', 70), ('semiannual', 'Semestral', 80), ('annual', 'Anual', 90),
  ('on_demand', 'Sob demanda', 100)
) as value_data(code, name, display_order)
on conflict (domain_id, code) do update
set name = excluded.name, display_order = excluded.display_order, active = true;

with domain as (
  select id from public.sparks_domains where code = 'INDICATOR_POLARITY' and module_code = 'SK-PE'
)
insert into public.sparks_domain_values (domain_id, code, name, display_order, protected)
select domain.id, value_data.code, value_data.name, value_data.display_order, true
from domain
cross join (values
  ('higher_is_better', 'Quanto maior, melhor', 10),
  ('lower_is_better', 'Quanto menor, melhor', 20),
  ('target_range', 'Faixa desejada', 30),
  ('exact_target', 'Valor exato', 40),
  ('informational', 'Informativo', 50)
) as value_data(code, name, display_order)
on conflict (domain_id, code) do update
set name = excluded.name, display_order = excluded.display_order, active = true;

with domain as (
  select id from public.sparks_domains where code = 'REVIEW_CYCLE' and module_code = 'SK-PE'
)
insert into public.sparks_domain_values (domain_id, code, name, display_order, protected)
select domain.id, value_data.code, value_data.name, value_data.display_order, true
from domain
cross join (values
  ('monthly', 'Revisão mensal', 10),
  ('quarterly', 'Revisão trimestral', 20),
  ('semiannual', 'Revisão semestral', 30),
  ('annual', 'Revisão anual', 40),
  ('biennial', 'Revisão bienal', 50),
  ('event_driven', 'Revisão por evento relevante', 60)
) as value_data(code, name, display_order)
on conflict (domain_id, code) do update
set name = excluded.name, display_order = excluded.display_order, active = true;

with domain as (
  select id from public.sparks_domains where code = 'RISK_LEVEL' and scope_type = 'global'
)
insert into public.sparks_domain_values (domain_id, code, name, display_order, protected, color_token)
select domain.id, value_data.code, value_data.name, value_data.display_order, true, value_data.color_token
from domain
cross join (values
  ('low', 'Baixo', 10, 'success'),
  ('medium', 'Médio', 20, 'warning'),
  ('high', 'Alto', 30, 'danger'),
  ('critical', 'Crítico', 40, 'critical')
) as value_data(code, name, display_order, color_token)
on conflict (domain_id, code) do update
set name = excluded.name, display_order = excluded.display_order, color_token = excluded.color_token, active = true;

-- ============================================================
-- 3. COMPLEMENTOS A PAPÉIS E RESPONSABILIDADES
-- ============================================================

alter table public.sparks_organizational_roles
  add column if not exists authority_level text,
  add column if not exists reports_to_role_id uuid references public.sparks_organizational_roles(id) on delete set null,
  add column if not exists responsibilities_summary text;

alter table public.sparks_responsibility_assignments
  add column if not exists delegated_from_assignment_id uuid references public.sparks_responsibility_assignments(id) on delete set null,
  add column if not exists delegated_by_person_id uuid references public.sparks_organization_people(id) on delete set null,
  add column if not exists delegation_reason text,
  add column if not exists delegation_started_at timestamptz,
  add column if not exists delegated_until date,
  add column if not exists approval_limit numeric(18,2),
  add column if not exists authority_level text,
  add column if not exists assignment_source text not null default 'manual';

alter table public.sparks_responsibility_assignments
  drop constraint if exists sparks_responsibility_assignments_type_check;

alter table public.sparks_responsibility_assignments
  add constraint sparks_responsibility_assignments_type_check
  check (responsibility_type in (
    'owner', 'co_owner', 'sponsor', 'approver', 'validator', 'executor',
    'consulted', 'informed', 'custodian', 'reviewer', 'facilitator',
    'data_owner', 'indicator_owner', 'team_member'
  ));

alter table public.sparks_responsibility_assignments
  drop constraint if exists sparks_responsibility_assignment_source_check;

alter table public.sparks_responsibility_assignments
  add constraint sparks_responsibility_assignment_source_check
  check (assignment_source in ('manual', 'role_inheritance', 'template', 'import', 'integration', 'delegation'));

-- ============================================================
-- 4. PERMISSÕES DO PLANEJAMENTO ESTRATÉGICO
-- ============================================================

insert into public.module_permissions (
  module_id, code, name, description, permission_group, active
)
select
  module.id,
  permission_data.code,
  permission_data.name,
  permission_data.description,
  permission_data.permission_group,
  true
from public.modules module
cross join (values
  ('governance_roles.view', 'Consultar papéis e responsabilidades', 'Permite consultar papéis organizacionais e responsabilidades estratégicas.', 'governance'),
  ('governance_roles.manage', 'Gerenciar papéis e responsabilidades', 'Permite criar, alterar, atribuir, delegar e encerrar responsabilidades estratégicas.', 'governance'),
  ('domains.view', 'Consultar tabelas de domínio', 'Permite consultar domínios e valores padronizados da plataforma e do módulo.', 'administration'),
  ('domains.manage', 'Gerenciar extensões de domínio', 'Permite gerenciar valores de domínio personalizáveis pela organização.', 'administration')
) as permission_data(code, name, description, permission_group)
where module.code = 'SK-PE'
on conflict (module_id, code) do update
set name = excluded.name,
    description = excluded.description,
    permission_group = excluded.permission_group,
    active = true;

insert into public.role_permissions (module_role_id, module_permission_id)
select role.id, permission.id
from public.module_roles role
join public.modules module on module.id = role.module_id
join public.module_permissions permission on permission.module_id = module.id
where module.code = 'SK-PE'
  and (
    (role.code in ('administrator', 'manager') and permission.code in ('governance_roles.view', 'governance_roles.manage', 'domains.view', 'domains.manage'))
    or (role.code in ('editor', 'approver') and permission.code in ('governance_roles.view', 'governance_roles.manage', 'domains.view'))
    or (role.code = 'viewer' and permission.code in ('governance_roles.view', 'domains.view'))
  )
on conflict do nothing;

-- ============================================================
-- 5. AUTORIZAÇÃO
-- ============================================================

create or replace function public.can_view_skpe_governance(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-PE', 'governance_roles.view');
$$;

create or replace function public.can_manage_skpe_governance(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-PE', 'governance_roles.manage');
$$;

create or replace function public.can_view_sparks_domains(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-PE', 'domains.view');
$$;

create or replace function public.can_manage_sparks_domains(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-PE', 'domains.manage');
$$;

-- ============================================================
-- 6. CONSULTAS OPERACIONAIS
-- ============================================================

create or replace function public.get_sparks_domain_values(
  target_domain_code text,
  target_organization_id uuid default null,
  target_module_code text default null,
  include_inactive boolean default false
)
returns table (
  domain_code text,
  domain_name text,
  domain_scope text,
  allow_organization_extension boolean,
  value_id uuid,
  value_code text,
  value_name text,
  value_description text,
  display_order integer,
  color_token text,
  icon_name text,
  active boolean,
  protected boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if target_organization_id is not null and not public.can_view_sparks_domains(target_organization_id) then
    raise exception 'Acesso negado às tabelas de domínio.';
  end if;

  return query
  select
    domain.code,
    domain.name,
    domain.scope_type,
    domain.allow_organization_extension,
    value.id,
    value.code,
    value.name,
    value.description,
    value.display_order,
    value.color_token,
    value.icon_name,
    value.active,
    value.protected
  from public.sparks_domains domain
  join public.sparks_domain_values value on value.domain_id = domain.id
  where domain.code = target_domain_code
    and domain.active
    and (include_inactive or value.active)
    and (
      domain.scope_type = 'global'
      or (domain.scope_type = 'module' and domain.module_code = target_module_code)
      or (domain.scope_type = 'organization' and domain.organization_id = target_organization_id)
    )
    and (value.valid_from is null or value.valid_from <= current_date)
    and (value.valid_until is null or value.valid_until >= current_date)
  order by
    case domain.scope_type when 'organization' then 1 when 'module' then 2 else 3 end,
    value.display_order,
    value.name;
end;
$$;

create or replace function public.get_skpe_governance_people(target_organization_id uuid)
returns table (
  organization_person_id uuid,
  person_id uuid,
  full_name text,
  preferred_name text,
  relationship_type text,
  job_title text,
  organizational_area text,
  organizational_unit text,
  is_director boolean,
  is_board_member boolean,
  is_committee_member boolean,
  relationship_status text,
  active_role_count bigint,
  active_responsibility_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado à governança operacional.';
  end if;

  return query
  select
    organization_person.id,
    person.id,
    person.full_name,
    person.preferred_name,
    organization_person.relationship_type,
    organization_person.job_title,
    organization_person.organizational_area,
    organization_person.organizational_unit,
    organization_person.is_director,
    organization_person.is_board_member,
    organization_person.is_committee_member,
    organization_person.status,
    count(distinct assignment.id) filter (where assignment.assignment_status = 'active'),
    count(distinct responsibility.id) filter (where responsibility.status = 'active')
  from public.sparks_organization_people organization_person
  join public.sparks_people person on person.id = organization_person.person_id
  left join public.sparks_person_role_assignments assignment
    on assignment.organization_person_id = organization_person.id
   and assignment.organization_id = target_organization_id
  left join public.sparks_responsibility_assignments responsibility
    on responsibility.organization_person_id = organization_person.id
   and responsibility.organization_id = target_organization_id
   and responsibility.module_code = 'SK-PE'
  where organization_person.organization_id = target_organization_id
    and organization_person.status in ('active', 'suspended')
    and person.person_status = 'active'
  group by organization_person.id, person.id
  order by coalesce(person.preferred_name, person.full_name), person.full_name;
end;
$$;

create or replace function public.get_skpe_organizational_roles(target_organization_id uuid)
returns table (
  role_id uuid,
  role_code text,
  role_name text,
  role_type text,
  description text,
  organizational_area text,
  authority_level text,
  is_governance_role boolean,
  requires_mandate boolean,
  active boolean,
  active_assignment_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado aos papéis organizacionais.';
  end if;

  return query
  select
    role.id,
    role.code,
    role.name,
    role.role_type,
    role.description,
    role.organizational_area,
    role.authority_level,
    role.is_governance_role,
    role.requires_mandate,
    role.active,
    count(assignment.id) filter (where assignment.assignment_status = 'active')
  from public.sparks_organizational_roles role
  left join public.sparks_person_role_assignments assignment
    on assignment.organizational_role_id = role.id
   and assignment.organization_id = target_organization_id
  where role.organization_id = target_organization_id
  group by role.id
  order by role.active desc, role.is_governance_role desc, role.name;
end;
$$;

create or replace function public.get_skpe_responsibility_assignments(
  target_organization_id uuid,
  target_object_type text default null,
  target_object_id uuid default null,
  include_inactive boolean default false
)
returns table (
  assignment_id uuid,
  object_type text,
  object_id uuid,
  responsibility_type text,
  organization_person_id uuid,
  person_id uuid,
  person_name text,
  job_title text,
  organizational_area text,
  allocation_percentage numeric,
  authority_level text,
  valid_from date,
  valid_until date,
  status text,
  assignment_source text,
  assignment_reason text,
  delegated boolean,
  delegated_until date
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado às responsabilidades estratégicas.';
  end if;

  return query
  select
    responsibility.id,
    responsibility.object_type,
    responsibility.object_id,
    responsibility.responsibility_type,
    organization_person.id,
    person.id,
    coalesce(person.preferred_name, person.full_name),
    organization_person.job_title,
    organization_person.organizational_area,
    responsibility.allocation_percentage,
    responsibility.authority_level,
    responsibility.valid_from,
    responsibility.valid_until,
    responsibility.status,
    responsibility.assignment_source,
    responsibility.assignment_reason,
    responsibility.delegated_from_assignment_id is not null,
    responsibility.delegated_until
  from public.sparks_responsibility_assignments responsibility
  join public.sparks_organization_people organization_person
    on organization_person.id = responsibility.organization_person_id
  join public.sparks_people person on person.id = organization_person.person_id
  where responsibility.organization_id = target_organization_id
    and responsibility.module_code = 'SK-PE'
    and (target_object_type is null or responsibility.object_type = target_object_type)
    and (target_object_id is null or responsibility.object_id = target_object_id)
    and (include_inactive or responsibility.status = 'active')
  order by responsibility.object_type, responsibility.responsibility_type, person.full_name;
end;
$$;

create or replace function public.get_skpe_governance_dashboard(target_organization_id uuid)
returns table (
  active_people bigint,
  active_roles bigint,
  people_with_roles bigint,
  active_responsibilities bigint,
  objects_with_responsibility bigint,
  objects_without_owner bigint,
  expired_responsibilities bigint,
  delegated_responsibilities bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_view_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado ao painel de governança.';
  end if;

  return query
  with active_people as (
    select count(*)::bigint as total
    from public.sparks_organization_people
    where organization_id = target_organization_id and status = 'active'
  ), active_roles as (
    select count(*)::bigint as total
    from public.sparks_organizational_roles
    where organization_id = target_organization_id and active
  ), people_with_roles as (
    select count(distinct organization_person_id)::bigint as total
    from public.sparks_person_role_assignments
    where organization_id = target_organization_id and assignment_status = 'active'
  ), active_responsibilities as (
    select count(*)::bigint as total
    from public.sparks_responsibility_assignments
    where organization_id = target_organization_id and module_code = 'SK-PE' and status = 'active'
  ), objects_with_responsibility as (
    select count(distinct (object_type, object_id))::bigint as total
    from public.sparks_responsibility_assignments
    where organization_id = target_organization_id and module_code = 'SK-PE' and status = 'active'
  ), objects_without_owner as (
    select count(*)::bigint as total
    from (
      select responsibility.object_type, responsibility.object_id
      from public.sparks_responsibility_assignments responsibility
      where responsibility.organization_id = target_organization_id
        and responsibility.module_code = 'SK-PE'
        and responsibility.status = 'active'
      group by responsibility.object_type, responsibility.object_id
      having count(*) filter (where responsibility.responsibility_type in ('owner', 'co_owner')) = 0
    ) missing
  ), expired_responsibilities as (
    select count(*)::bigint as total
    from public.sparks_responsibility_assignments
    where organization_id = target_organization_id
      and module_code = 'SK-PE'
      and status = 'active'
      and valid_until is not null
      and valid_until < current_date
  ), delegated_responsibilities as (
    select count(*)::bigint as total
    from public.sparks_responsibility_assignments
    where organization_id = target_organization_id
      and module_code = 'SK-PE'
      and status = 'active'
      and delegated_from_assignment_id is not null
  )
  select
    active_people.total,
    active_roles.total,
    people_with_roles.total,
    active_responsibilities.total,
    objects_with_responsibility.total,
    objects_without_owner.total,
    expired_responsibilities.total,
    delegated_responsibilities.total
  from active_people, active_roles, people_with_roles, active_responsibilities,
       objects_with_responsibility, objects_without_owner,
       expired_responsibilities, delegated_responsibilities;
end;
$$;

-- ============================================================
-- 7. FUNÇÕES DE MANUTENÇÃO AUDITADAS
-- ============================================================

create or replace function public.upsert_skpe_organizational_role(
  target_organization_id uuid,
  target_role_id uuid,
  target_code text,
  target_name text,
  target_role_type text,
  target_description text,
  target_organizational_area text,
  target_authority_level text,
  target_is_governance_role boolean,
  target_requires_mandate boolean,
  target_active boolean,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  role_id uuid;
  previous_record jsonb;
  new_record jsonb;
begin
  if not public.can_manage_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado para gerenciar papéis organizacionais.';
  end if;

  perform public.skpe_assert_reason(change_reason);

  if length(trim(coalesce(target_code, ''))) = 0 or length(trim(coalesce(target_name, ''))) = 0 then
    raise exception 'Informe o código e o nome do papel.';
  end if;

  if target_role_id is null then
    insert into public.sparks_organizational_roles (
      organization_id, code, name, role_type, description, organizational_area,
      authority_level, is_governance_role, requires_mandate, active,
      created_by, updated_by
    ) values (
      target_organization_id, upper(trim(target_code)), trim(target_name), target_role_type,
      nullif(trim(target_description), ''), nullif(trim(target_organizational_area), ''),
      nullif(trim(target_authority_level), ''), coalesce(target_is_governance_role, false),
      coalesce(target_requires_mandate, false), coalesce(target_active, true), auth.uid(), auth.uid()
    ) returning id into role_id;

    select to_jsonb(role) into new_record from public.sparks_organizational_roles role where role.id = role_id;
    perform public.skpe_record_operational_audit(target_organization_id, null, 'organizational_role', role_id, 'create', change_reason, null, new_record);
  else
    select to_jsonb(role) into previous_record
    from public.sparks_organizational_roles role
    where role.id = target_role_id and role.organization_id = target_organization_id;

    if previous_record is null then
      raise exception 'Papel organizacional não encontrado.';
    end if;

    update public.sparks_organizational_roles
    set code = upper(trim(target_code)), name = trim(target_name), role_type = target_role_type,
        description = nullif(trim(target_description), ''),
        organizational_area = nullif(trim(target_organizational_area), ''),
        authority_level = nullif(trim(target_authority_level), ''),
        is_governance_role = coalesce(target_is_governance_role, false),
        requires_mandate = coalesce(target_requires_mandate, false),
        active = coalesce(target_active, true), updated_by = auth.uid()
    where id = target_role_id;

    role_id := target_role_id;
    select to_jsonb(role) into new_record from public.sparks_organizational_roles role where role.id = role_id;
    perform public.skpe_record_operational_audit(target_organization_id, null, 'organizational_role', role_id, 'update', change_reason, previous_record, new_record);
  end if;

  return role_id;
end;
$$;

create or replace function public.assign_skpe_person_role(
  target_organization_id uuid,
  target_organization_person_id uuid,
  target_organizational_role_id uuid,
  target_mandate_start_date date,
  target_mandate_end_date date,
  target_appointment_document_reference text,
  target_notes text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  assignment_id uuid;
  new_record jsonb;
begin
  if not public.can_manage_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado para atribuir papéis.';
  end if;

  perform public.skpe_assert_reason(change_reason);

  if not exists (
    select 1 from public.sparks_organization_people
    where id = target_organization_person_id and organization_id = target_organization_id
  ) then
    raise exception 'Pessoa não vinculada à organização.';
  end if;

  if not exists (
    select 1 from public.sparks_organizational_roles
    where id = target_organizational_role_id and organization_id = target_organization_id and active
  ) then
    raise exception 'Papel organizacional não encontrado ou inativo.';
  end if;

  insert into public.sparks_person_role_assignments (
    organization_id, organization_person_id, organizational_role_id,
    mandate_start_date, mandate_end_date, assignment_status,
    appointment_document_reference, notes, created_by, updated_by
  ) values (
    target_organization_id, target_organization_person_id, target_organizational_role_id,
    target_mandate_start_date, target_mandate_end_date, 'active',
    nullif(trim(target_appointment_document_reference), ''), nullif(trim(target_notes), ''),
    auth.uid(), auth.uid()
  ) returning id into assignment_id;

  select to_jsonb(assignment) into new_record
  from public.sparks_person_role_assignments assignment where assignment.id = assignment_id;

  perform public.skpe_record_operational_audit(target_organization_id, null, 'person_role_assignment', assignment_id, 'assign', change_reason, null, new_record);

  return assignment_id;
end;
$$;

create or replace function public.assign_skpe_responsibility(
  target_organization_id uuid,
  target_object_type text,
  target_object_id uuid,
  target_organization_person_id uuid,
  target_responsibility_type text,
  target_allocation_percentage numeric,
  target_authority_level text,
  target_valid_from date,
  target_valid_until date,
  target_assignment_reason text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  assignment_id uuid;
  new_record jsonb;
begin
  if not public.can_manage_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado para atribuir responsabilidades.';
  end if;

  perform public.skpe_assert_reason(change_reason);

  if length(trim(coalesce(target_object_type, ''))) = 0 then
    raise exception 'Informe o tipo do objeto estratégico.';
  end if;

  if target_object_id is null then
    raise exception 'Informe o objeto estratégico.';
  end if;

  if not exists (
    select 1 from public.sparks_organization_people
    where id = target_organization_person_id and organization_id = target_organization_id and status = 'active'
  ) then
    raise exception 'Pessoa não vinculada ou inativa na organização.';
  end if;

  insert into public.sparks_responsibility_assignments (
    organization_id, module_code, object_type, object_id, organization_person_id,
    responsibility_type, allocation_percentage, authority_level,
    valid_from, valid_until, status, assignment_reason, assignment_source,
    created_by, updated_by
  ) values (
    target_organization_id, 'SK-PE', trim(target_object_type), target_object_id,
    target_organization_person_id, target_responsibility_type,
    target_allocation_percentage, nullif(trim(target_authority_level), ''),
    target_valid_from, target_valid_until, 'active', nullif(trim(target_assignment_reason), ''),
    'manual', auth.uid(), auth.uid()
  ) returning id into assignment_id;

  select to_jsonb(responsibility) into new_record
  from public.sparks_responsibility_assignments responsibility where responsibility.id = assignment_id;

  perform public.skpe_record_operational_audit(target_organization_id, null, 'responsibility_assignment', assignment_id, 'assign', change_reason, null, new_record);

  return assignment_id;
end;
$$;

create or replace function public.end_skpe_responsibility(
  target_assignment_id uuid,
  target_end_date date,
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_organization_id uuid;
  previous_record jsonb;
  new_record jsonb;
begin
  select responsibility.organization_id, to_jsonb(responsibility)
  into target_organization_id, previous_record
  from public.sparks_responsibility_assignments responsibility
  where responsibility.id = target_assignment_id and responsibility.module_code = 'SK-PE';

  if target_organization_id is null then
    raise exception 'Responsabilidade não encontrada.';
  end if;

  if not public.can_manage_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado para encerrar responsabilidades.';
  end if;

  perform public.skpe_assert_reason(change_reason);

  update public.sparks_responsibility_assignments
  set status = 'ended', valid_until = coalesce(target_end_date, current_date), updated_by = auth.uid()
  where id = target_assignment_id;

  select to_jsonb(responsibility) into new_record
  from public.sparks_responsibility_assignments responsibility where responsibility.id = target_assignment_id;

  perform public.skpe_record_operational_audit(target_organization_id, null, 'responsibility_assignment', target_assignment_id, 'end', change_reason, previous_record, new_record);
end;
$$;

create or replace function public.add_sparks_organization_domain_value(
  target_organization_id uuid,
  target_domain_code text,
  target_value_code text,
  target_value_name text,
  target_value_description text,
  target_display_order integer,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  source_domain public.sparks_domains%rowtype;
  organization_domain_id uuid;
  value_id uuid;
begin
  if not public.can_manage_sparks_domains(target_organization_id) then
    raise exception 'Acesso negado para gerenciar extensões de domínio.';
  end if;

  perform public.skpe_assert_reason(change_reason);

  select * into source_domain
  from public.sparks_domains
  where code = target_domain_code
    and active
    and scope_type in ('global', 'module')
  order by case scope_type when 'module' then 1 else 2 end
  limit 1;

  if source_domain.id is null then
    raise exception 'Domínio não encontrado.';
  end if;

  if not source_domain.allow_organization_extension then
    raise exception 'Este domínio não permite extensões pela organização.';
  end if;

  insert into public.sparks_domains (
    code, name, description, scope_type, organization_id,
    allow_organization_extension, protected, active, created_by, updated_by,
    metadata
  ) values (
    source_domain.code,
    source_domain.name || ' — extensão da organização',
    'Valores complementares específicos da organização.',
    'organization', target_organization_id, true, false, true, auth.uid(), auth.uid(),
    jsonb_build_object('source_domain_id', source_domain.id)
  )
  on conflict (organization_id, code) where scope_type = 'organization'
  do update set active = true, updated_by = auth.uid()
  returning id into organization_domain_id;

  insert into public.sparks_domain_values (
    domain_id, code, name, description, display_order,
    protected, active, created_by, updated_by
  ) values (
    organization_domain_id, lower(trim(target_value_code)), trim(target_value_name),
    nullif(trim(target_value_description), ''), coalesce(target_display_order, 100),
    false, true, auth.uid(), auth.uid()
  )
  on conflict (domain_id, code) do update
  set name = excluded.name,
      description = excluded.description,
      display_order = excluded.display_order,
      active = true,
      updated_by = auth.uid()
  returning id into value_id;

  perform public.skpe_record_operational_audit(
    target_organization_id, null, 'domain_value', value_id, 'upsert', change_reason,
    null, jsonb_build_object('domain_code', target_domain_code, 'value_code', target_value_code, 'value_name', target_value_name)
  );

  return value_id;
end;
$$;

-- ============================================================
-- 8. RLS E PRIVILÉGIOS
-- ============================================================

alter table public.sparks_domains enable row level security;
alter table public.sparks_domain_values enable row level security;

revoke all on table public.sparks_domains from anon, authenticated;
revoke all on table public.sparks_domain_values from anon, authenticated;

revoke all on function public.get_sparks_domain_values(text, uuid, text, boolean) from public;
revoke all on function public.get_skpe_governance_people(uuid) from public;
revoke all on function public.get_skpe_organizational_roles(uuid) from public;
revoke all on function public.get_skpe_responsibility_assignments(uuid, text, uuid, boolean) from public;
revoke all on function public.get_skpe_governance_dashboard(uuid) from public;
revoke all on function public.upsert_skpe_organizational_role(uuid, uuid, text, text, text, text, text, text, boolean, boolean, boolean, text) from public;
revoke all on function public.assign_skpe_person_role(uuid, uuid, uuid, date, date, text, text, text) from public;
revoke all on function public.assign_skpe_responsibility(uuid, text, uuid, uuid, text, numeric, text, date, date, text, text) from public;
revoke all on function public.end_skpe_responsibility(uuid, date, text) from public;
revoke all on function public.add_sparks_organization_domain_value(uuid, text, text, text, text, integer, text) from public;

grant execute on function public.get_sparks_domain_values(text, uuid, text, boolean) to authenticated;
grant execute on function public.get_skpe_governance_people(uuid) to authenticated;
grant execute on function public.get_skpe_organizational_roles(uuid) to authenticated;
grant execute on function public.get_skpe_responsibility_assignments(uuid, text, uuid, boolean) to authenticated;
grant execute on function public.get_skpe_governance_dashboard(uuid) to authenticated;
grant execute on function public.upsert_skpe_organizational_role(uuid, uuid, text, text, text, text, text, text, boolean, boolean, boolean, text) to authenticated;
grant execute on function public.assign_skpe_person_role(uuid, uuid, uuid, date, date, text, text, text) to authenticated;
grant execute on function public.assign_skpe_responsibility(uuid, text, uuid, uuid, text, numeric, text, date, date, text, text) to authenticated;
grant execute on function public.end_skpe_responsibility(uuid, date, text) to authenticated;
grant execute on function public.add_sparks_organization_domain_value(uuid, text, text, text, text, integer, text) to authenticated;

comment on table public.sparks_domains is 'Catálogo transversal de tabelas de domínio da Plataforma SPARKs.';
comment on table public.sparks_domain_values is 'Valores padronizados e extensões organizacionais das tabelas de domínio.';
comment on function public.get_skpe_governance_dashboard(uuid) is 'Painel resumido de pessoas, papéis, responsabilidades e lacunas de governança do Planejamento Estratégico.';

commit;
