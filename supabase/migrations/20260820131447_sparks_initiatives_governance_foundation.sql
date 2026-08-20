-- ============================================================
-- SPARKs PaaS
-- Gate 17-B.5F.3C.6A
-- Fundacao de Governanca Transversal de Iniciativas
--
-- Escopo:
--   1. autorizacao transversal;
--   2. auditoria transversal;
--   3. semantica de lifecycle/progresso;
--   4. RLS e privilegios minimos.
--
-- Fora de escopo:
--   - operacoes de lifecycle;
--   - maquina de estados;
--   - sincronizacao com SK-PE;
--   - frontend;
--   - alteracao de dados existentes.
-- ============================================================


-- ============================================================
-- 1. AUTORIZACAO TRANSVERSAL
-- ============================================================

create or replace function public.can_manage_sparks_initiatives(
  target_organization_id uuid,
  target_source_module_code text default null
)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.can_manage_organization(target_organization_id)
    or (
      nullif(upper(trim(target_source_module_code)), '') is not null
      and public.has_module_permission(
        target_organization_id,
        upper(trim(target_source_module_code)),
        'initiatives.manage'
      )
    );
$$;

comment on function public.can_manage_sparks_initiatives(uuid, text) is
  'Autoridade transversal para gestao de iniciativas da Plataforma SPARKs. '
  'Autoriza superadministrador da plataforma, administrador da organizacao '
  'ou usuario que possua initiatives.manage no modulo de origem informado. '
  'Nao concede autorizacao por mera associacao, membership ou simples acesso ao modulo.';


-- ============================================================
-- 2. AUDITORIA TRANSVERSAL DE INICIATIVAS
-- ============================================================

create table public.sparks_initiative_audit (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null
    references public.organizations(id) on delete cascade,

  initiative_id uuid not null
    references public.sparks_initiatives(id) on delete restrict,

  actor_user_id uuid not null
    references public.profiles(id) on delete restrict,

  source_module_code text,

  action_code text not null,

  change_reason text,

  previous_data jsonb,

  new_data jsonb,

  occurred_at timestamptz not null
    default timezone('utc', now()),

  constraint sparks_initiative_audit_action_not_blank
    check (length(trim(action_code)) > 0),

  constraint sparks_initiative_audit_source_module_not_blank
    check (
      source_module_code is null
      or length(trim(source_module_code)) > 0
    )
);

comment on table public.sparks_initiative_audit is
  'Trilha de auditoria transversal das iniciativas e projetos organizacionais '
  'da Plataforma SPARKs. Registra fatos governados de alteracao sem substituir '
  'auditorias especializadas dos modulos de origem.';

comment on column public.sparks_initiative_audit.source_module_code is
  'Modulo que originou ou contextualizou a operacao auditada, quando aplicavel.';

comment on column public.sparks_initiative_audit.change_reason is
  'Justificativa da alteracao governada. A obrigatoriedade operacional '
  'sera aplicada pelas operacoes especificas de lifecycle e progresso.';

comment on column public.sparks_initiative_audit.previous_data is
  'Snapshot governado do estado relevante anterior a operacao.';

comment on column public.sparks_initiative_audit.new_data is
  'Snapshot governado do estado relevante posterior a operacao.';


-- ============================================================
-- 3. INDICES DA AUDITORIA
-- ============================================================

create index idx_sparks_initiative_audit_organization
  on public.sparks_initiative_audit(organization_id);

create index idx_sparks_initiative_audit_initiative_occurred
  on public.sparks_initiative_audit(
    initiative_id,
    occurred_at desc
  );

create index idx_sparks_initiative_audit_occurred_at
  on public.sparks_initiative_audit(occurred_at desc);


-- ============================================================
-- 4. SEMANTICA CANONICA DE EXECUCAO TRANSVERSAL
-- ============================================================

comment on column public.sparks_initiatives.status is
  'Estado organizacional da iniciativa ou projeto transversal. '
  'Nao representa automaticamente o estado metodologico de workspace, '
  'jornada ou outro objeto especializado de modulo.';

comment on column public.sparks_initiatives.progress is
  'Progresso organizacional governado da iniciativa ou projeto transversal, '
  'em percentual de 0 a 100. Nao e projecao automatica do progresso da '
  'Jornada SK-PE, de projeto metodologico ou de outro modulo especializado.';

comment on column public.sparks_initiatives.health_status is
  'Saude organizacional da execucao da iniciativa ou projeto transversal. '
  'Representa avaliacao governada da situacao de execucao e nao o estado '
  'metodologico de modulo especializado.';

comment on column public.sparks_initiatives.completed_at is
  'Momento de conclusao organizacional da iniciativa ou projeto transversal. '
  'Nao e derivado automaticamente do encerramento metodologico de jornada, '
  'workspace ou outro modulo especializado.';


-- ============================================================
-- 5. RLS
-- ============================================================

alter table public.sparks_initiative_audit
  enable row level security;

drop policy if exists
  sparks_initiative_audit_select_authorized
  on public.sparks_initiative_audit;

create policy sparks_initiative_audit_select_authorized
on public.sparks_initiative_audit
for select
to authenticated
using (
  public.can_manage_sparks_initiatives(
    organization_id,
    source_module_code
  )
);

-- Nao existem policies de INSERT, UPDATE ou DELETE para authenticated.
-- A escrita sera realizada exclusivamente por operacoes governadas
-- implementadas no Gate 17-B.5F.3C.6B.


-- ============================================================
-- 6. PRIVILEGIOS DA TABELA
-- ============================================================

revoke all
on table public.sparks_initiative_audit
from anon;

revoke all
on table public.sparks_initiative_audit
from authenticated;

grant select
on table public.sparks_initiative_audit
to authenticated;

grant all
on table public.sparks_initiative_audit
to service_role;


-- ============================================================
-- 7. PRIVILEGIOS DA FUNCAO
-- ============================================================

revoke all
on function public.can_manage_sparks_initiatives(uuid, text)
from public;

revoke all
on function public.can_manage_sparks_initiatives(uuid, text)
from anon;

grant execute
on function public.can_manage_sparks_initiatives(uuid, text)
to authenticated, service_role;


-- ============================================================
-- 8. GARANTIAS DE ESCOPO
-- ============================================================
--
-- Esta migration deliberadamente:
--
-- 1. NAO altera registros existentes em sparks_initiatives;
-- 2. NAO altera registros existentes em skpe_projects;
-- 3. NAO sincroniza status ou progress entre tabelas;
-- 4. NAO cria RPC de lifecycle;
-- 5. NAO cria maquina de estados;
-- 6. NAO altera constraints de lifecycle;
-- 7. NAO implementa regras de completed_at ou archived_at;
-- 8. NAO cria dependencia do dominio transversal com SK-PE.
--
-- ============================================================