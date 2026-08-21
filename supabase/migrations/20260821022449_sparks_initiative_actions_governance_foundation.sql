begin;

-- ============================================================
-- SPARKs PaaS
-- Gate 17-B.5F.3C.6C
-- Fundacao Transversal de Acoes de Execucao
--
-- Escopo:
--   1. entidade transversal de acoes subordinadas a iniciativas;
--   2. hierarquia intra-iniciativa;
--   3. baseline, plano vigente e realizado;
--   4. custos e esforco operacionais de alto nivel;
--   5. auditoria dedicada;
--   6. validacao de area responsavel;
--   7. RLS e privilegios minimos.
--
-- Fora de escopo:
--   - RPCs operacionais;
--   - maquina de estados;
--   - atribuicao governada de responsabilidades pessoais;
--   - roll-up automatico para sparks_initiatives;
--   - Kanban, Gantt ou calendario como entidades;
--   - migracao de skpe_initiative_actions;
--   - sincronizacao automatica com SK-PE.
-- ============================================================

create table public.sparks_initiative_actions (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id) on delete restrict,

  initiative_id uuid not null,

  parent_action_id uuid,

  code text not null,
  name text not null,
  description text,

  action_type text not null default 'action',

  source_module_code text,
  source_reference text,

  why_text text,
  where_text text,
  how_text text,

  responsible_area_id uuid
    references public.sparks_domain_values(id) on delete set null,

  baseline_start_date date,
  baseline_due_date date,
  planned_start_date date,
  planned_due_date date,

  started_at timestamptz,
  completed_at timestamptz,
  last_update_at timestamptz,

  status text not null default 'planned',
  priority text not null default 'medium',
  progress numeric(5,2) not null default 0,

  planned_cost numeric(18,2),
  actual_cost numeric(18,2),
  currency_code text not null default 'BRL',

  estimated_effort numeric(18,2),
  effort_unit text,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id) on delete set null,

  archived_at timestamptz,
  archived_by uuid references public.profiles(id) on delete set null,

  constraint sparks_initiative_actions_scope_identity
    unique (id, organization_id, initiative_id),

  constraint sparks_initiative_actions_unique_code
    unique (initiative_id, code),

  constraint sparks_initiative_actions_initiative_scope_fkey
    foreign key (initiative_id, organization_id)
    references public.sparks_initiatives(id, organization_id)
    on delete restrict,

  constraint sparks_initiative_actions_parent_scope_fkey
    foreign key (parent_action_id, organization_id, initiative_id)
    references public.sparks_initiative_actions(id, organization_id, initiative_id)
    on delete restrict,

  constraint sparks_initiative_actions_code_not_blank
    check (length(trim(code)) > 0),

  constraint sparks_initiative_actions_name_not_blank
    check (length(trim(name)) > 0),

  constraint sparks_initiative_actions_type_check
    check (action_type in ('action', 'milestone')),

  constraint sparks_initiative_actions_source_module_not_blank
    check (
      source_module_code is null
      or length(trim(source_module_code)) > 0
    ),

  constraint sparks_initiative_actions_status_check
    check (
      status in (
        'planned', 'in_progress', 'on_hold', 'blocked',
        'completed', 'cancelled', 'archived'
      )
    ),

  constraint sparks_initiative_actions_priority_check
    check (priority in ('low', 'medium', 'high', 'critical')),

  constraint sparks_initiative_actions_progress_check
    check (progress >= 0 and progress <= 100),

  constraint sparks_initiative_actions_planned_progress_check
    check (status <> 'planned' or progress = 0),

  constraint sparks_initiative_actions_completion_check
    check (
      status <> 'completed'
      or (progress = 100 and completed_at is not null)
    ),

  constraint sparks_initiative_actions_archive_check
    check (
      (status = 'archived' and archived_at is not null and archived_by is not null)
      or (status <> 'archived' and archived_at is null)
    ),

  constraint sparks_initiative_actions_baseline_dates_check
    check (
      baseline_due_date is null
      or baseline_start_date is null
      or baseline_due_date >= baseline_start_date
    ),

  constraint sparks_initiative_actions_planned_dates_check
    check (
      planned_due_date is null
      or planned_start_date is null
      or planned_due_date >= planned_start_date
    ),

  constraint sparks_initiative_actions_costs_check
    check (
      coalesce(planned_cost, 0) >= 0
      and coalesce(actual_cost, 0) >= 0
    ),

  constraint sparks_initiative_actions_currency_check
    check (currency_code ~ '^[A-Z]{3}$'),

  constraint sparks_initiative_actions_effort_check
    check (estimated_effort is null or estimated_effort >= 0),

  constraint sparks_initiative_actions_effort_unit_check
    check (
      effort_unit is null
      or effort_unit in ('hours', 'days', 'weeks', 'months', 'points', 'custom')
    ),

  constraint sparks_initiative_actions_not_self_parent
    check (parent_action_id is null or parent_action_id <> id)
);

comment on table public.sparks_initiative_actions is
  'Acoes transversais de execucao pertencentes a iniciativas organizacionais da Plataforma SPARKs. Nao representam tarefas genericas da plataforma nem substituem cronogramas, jornadas ou objetos metodologicos especializados dos modulos.';

comment on column public.sparks_initiative_actions.source_module_code is
  'Modulo que originou ou contextualizou a acao. Proveniencia nao implica propriedade existencial nem concede autorizacao sobre a iniciativa ou a acao.';

comment on column public.sparks_initiative_actions.source_reference is
  'Referencia externa ou especializada de proveniencia, sem constituir fonte de verdade concorrente para a existencia da acao.';

comment on column public.sparks_initiative_actions.baseline_start_date is
  'Data de inicio originalmente comprometida para comparacao historica de planejamento.';

comment on column public.sparks_initiative_actions.baseline_due_date is
  'Data de conclusao originalmente comprometida para comparacao historica de planejamento.';

comment on column public.sparks_initiative_actions.planned_start_date is
  'Data de inicio do planejamento vigente, podendo refletir replanejamento governado futuro.';

comment on column public.sparks_initiative_actions.planned_due_date is
  'Data de conclusao do planejamento vigente, podendo refletir replanejamento governado futuro.';

comment on column public.sparks_initiative_actions.started_at is
  'Momento real de inicio da execucao. Sua operacao governada pertence ao gate de lifecycle posterior.';

comment on column public.sparks_initiative_actions.completed_at is
  'Momento real de conclusao. Nao deve ser derivado automaticamente do lifecycle da iniciativa pai.';

comment on column public.sparks_initiative_actions.progress is
  'Progresso operacional governado da acao, de 0 a 100, sem roll-up automatico para sparks_initiatives.';

comment on column public.sparks_initiative_actions.responsible_area_id is
  'Area organizacional responsavel. Responsabilidades pessoais pertencem a matriz transversal sparks_responsibility_assignments e nao sao duplicadas nesta entidade.';

comment on column public.sparks_initiative_actions.why_text is
  'Componente WHY do 5W2H. WHAT, WHEN, WHO e HOW MUCH sao derivados das autoridades estruturais da acao.';

comment on column public.sparks_initiative_actions.where_text is
  'Componente WHERE do 5W2H.';

comment on column public.sparks_initiative_actions.how_text is
  'Componente HOW do 5W2H.';

-- ============================================================
-- VALIDACAO DE ESCOPO DE DOMINIO
-- ============================================================

create or replace function public.sparks_validate_initiative_action_domain_scope()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.responsible_area_id is not null and not exists (
    select 1
    from public.sparks_domain_values area_value
    join public.sparks_domains area_domain
      on area_domain.id = area_value.domain_id
    where area_value.id = new.responsible_area_id
      and area_value.active
      and area_domain.active
      and area_domain.scope_type = 'organization'
      and area_domain.organization_id = new.organization_id
      and area_domain.code = 'ORGANIZATIONAL_AREA'
  ) then
    raise exception
      'Area responsavel invalida ou inativa para esta organizacao.'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

comment on function public.sparks_validate_initiative_action_domain_scope() is
  'Valida que a area responsavel da acao transversal seja um valor ativo do dominio ORGANIZATIONAL_AREA da mesma organizacao.';

create trigger sparks_initiative_actions_validate_domain_scope
before insert or update of organization_id, responsible_area_id
on public.sparks_initiative_actions
for each row
execute function public.sparks_validate_initiative_action_domain_scope();

-- ============================================================
-- AUDITORIA DEDICADA
-- ============================================================

create table public.sparks_initiative_action_audit (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id) on delete restrict,

  initiative_id uuid not null,

  action_id uuid not null,

  actor_user_id uuid not null
    references public.profiles(id) on delete restrict,

  source_module_code text,
  action_code text not null,
  change_reason text,
  previous_data jsonb,
  new_data jsonb,

  occurred_at timestamptz not null default timezone('utc', now()),

  constraint sparks_initiative_action_audit_action_scope_fkey
    foreign key (action_id, organization_id, initiative_id)
    references public.sparks_initiative_actions(id, organization_id, initiative_id)
    on delete restrict,

  constraint sparks_initiative_action_audit_initiative_scope_fkey
    foreign key (initiative_id, organization_id)
    references public.sparks_initiatives(id, organization_id)
    on delete restrict,

  constraint sparks_initiative_action_audit_action_code_not_blank
    check (length(trim(action_code)) > 0),

  constraint sparks_initiative_action_audit_source_module_not_blank
    check (
      source_module_code is null
      or length(trim(source_module_code)) > 0
    )
);

comment on table public.sparks_initiative_action_audit is
  'Trilha de auditoria dedicada das acoes transversais de execucao. Registra fatos governados sem substituir auditorias especializadas dos modulos de origem.';

comment on column public.sparks_initiative_action_audit.source_module_code is
  'Modulo que originou ou contextualizou a operacao auditada. A autorizacao de leitura continua derivada da iniciativa pai.';

-- ============================================================
-- INDICES
-- ============================================================

create index idx_sparks_initiative_actions_open_scope
  on public.sparks_initiative_actions(
    organization_id,
    initiative_id,
    status,
    priority
  )
  where archived_at is null;

create index idx_sparks_initiative_actions_parent
  on public.sparks_initiative_actions(parent_action_id)
  where archived_at is null;

create index idx_sparks_initiative_actions_responsible_area
  on public.sparks_initiative_actions(organization_id, responsible_area_id)
  where archived_at is null;

create index idx_sparks_initiative_actions_due_date
  on public.sparks_initiative_actions(initiative_id, planned_due_date)
  where archived_at is null;

create index idx_sparks_initiative_action_audit_action_occurred
  on public.sparks_initiative_action_audit(action_id, occurred_at desc);

create index idx_sparks_initiative_action_audit_initiative_occurred
  on public.sparks_initiative_action_audit(initiative_id, occurred_at desc);

create index idx_sparks_initiative_action_audit_organization_occurred
  on public.sparks_initiative_action_audit(organization_id, occurred_at desc);

-- ============================================================
-- RLS
-- ============================================================

alter table public.sparks_initiative_actions enable row level security;
alter table public.sparks_initiative_action_audit enable row level security;

create policy sparks_initiative_actions_select_member
on public.sparks_initiative_actions
for select
to authenticated
using (public.can_read_organization(organization_id));

create policy sparks_initiative_action_audit_select_authorized
on public.sparks_initiative_action_audit
for select
to authenticated
using (
  exists (
    select 1
    from public.sparks_initiatives initiative
    where initiative.id = initiative_id
      and initiative.organization_id = organization_id
      and public.can_manage_sparks_initiatives(
        initiative.organization_id,
        initiative.source_module_code
      )
  )
);

-- Deliberadamente nao existem policies de INSERT, UPDATE ou DELETE
-- para authenticated em nenhuma das duas tabelas.

-- ============================================================
-- PRIVILEGIOS
-- ============================================================

revoke all on table public.sparks_initiative_actions from anon;
revoke all on table public.sparks_initiative_actions from authenticated;
grant select on table public.sparks_initiative_actions to authenticated;
grant all on table public.sparks_initiative_actions to service_role;

revoke all on table public.sparks_initiative_action_audit from anon;
revoke all on table public.sparks_initiative_action_audit from authenticated;
grant select on table public.sparks_initiative_action_audit to authenticated;
grant all on table public.sparks_initiative_action_audit to service_role;

revoke all
on function public.sparks_validate_initiative_action_domain_scope()
from public, anon;

grant execute
on function public.sparks_validate_initiative_action_domain_scope()
to service_role;

-- ============================================================
-- GARANTIAS DE ESCOPO
-- ============================================================
-- 1. Nao altera sparks_initiatives existentes.
-- 2. Nao altera skpe_initiative_actions nem migra seus dados.
-- 3. Nao cria RPC operacional de acoes.
-- 4. Nao implementa maquina de estados.
-- 5. Nao sincroniza progresso com a iniciativa pai.
-- 6. Nao materializa responsabilidades pessoais.
-- 7. Nao cria dependencia do dominio transversal com SK-PE.
-- 8. Kanban, Gantt e calendario permanecem projecoes futuras.

commit;;
