-- ============================================================
-- Plataforma SPARKs / SK-PE
-- FE-03.01 — Endurecimento de RLS dos Objetivos Estratégicos
--             e Resultados-Chave
--
-- Correções:
-- 1. Remove a política legada de escrita direta dos KRs.
-- 2. Revoga INSERT, UPDATE e DELETE de usuários comuns.
-- 3. Preserva escrita por service_role e RPCs SECURITY DEFINER.
-- 4. Alinha a leitura aos domínios de Iniciativas e Formulação.
-- ============================================================

begin;

-- ============================================================
-- 1. RESULTADOS-CHAVE: REMOVER ESCRITA DIRETA LEGADA
-- ============================================================

drop policy if exists skpe_key_results_manage
  on public.skpe_key_results;

revoke insert, update, delete
on table public.skpe_key_results
from public;

revoke insert, update, delete
on table public.skpe_key_results
from anon, authenticated;

grant select
on table public.skpe_key_results
to authenticated, service_role;

grant insert, update, delete
on table public.skpe_key_results
to service_role;

-- ============================================================
-- 2. OBJETIVOS ESTRATÉGICOS: REMOVER PRIVILÉGIOS DESNECESSÁRIOS
-- ============================================================

revoke insert, update, delete
on table public.skpe_strategic_objectives
from public;

revoke insert, update, delete
on table public.skpe_strategic_objectives
from anon, authenticated;

grant select
on table public.skpe_strategic_objectives
to authenticated, service_role;

grant insert, update, delete
on table public.skpe_strategic_objectives
to service_role;

-- ============================================================
-- 3. LEITURA COMPATÍVEL COM OS DOIS DOMÍNIOS
-- ============================================================

drop policy if exists skpe_strategic_objectives_select
  on public.skpe_strategic_objectives;

create policy skpe_strategic_objectives_select
on public.skpe_strategic_objectives
for select
to authenticated
using (
  public.can_view_skpe_initiatives(organization_id)
  or public.can_view_skpe_formulation(organization_id)
);

drop policy if exists skpe_key_results_select
  on public.skpe_key_results;

create policy skpe_key_results_select
on public.skpe_key_results
for select
to authenticated
using (
  public.can_view_skpe_initiatives(organization_id)
  or public.can_view_skpe_formulation(organization_id)
);

comment on table public.skpe_strategic_objectives is
  'Objetivos Estratégicos compartilhados entre Formulação e desdobramento por Iniciativas. Escritas de usuários ocorrem somente por operações auditadas.';

comment on table public.skpe_key_results is
  'Resultados-Chave compartilhados entre Formulação, OKRs e Iniciativas. Escritas de usuários ocorrem somente por operações auditadas.';

commit;
