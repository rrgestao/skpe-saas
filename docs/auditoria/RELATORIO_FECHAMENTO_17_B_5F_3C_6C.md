---
id: SKPE-AUD-17-B-5F-3C-6C-FECHAMENTO
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
roadmap_step: 17-B.5F.3C.6C
canonical_context: SK-PE-CONT-01
created_at: 2026-08-21
updated_at: 2026-08-21
origin: auditoria_controlada_supabase_github
technical_reconciliation_commit: f8ebbf8f12e12672f5604150e1ffa20df13b331d
depends_on:
  - supabase/migrations/20260820131447_sparks_initiatives_governance_foundation.sql
  - supabase/migrations/20260820145021_sparks_initiatives_governed_lifecycle_progress.sql
  - supabase/migrations/20260820145252_harden_sparks_initiative_lifecycle_contract.sql
  - supabase/migrations/20260821022449_sparks_initiative_actions_governance_foundation.sql
  - supabase/migrations/20260821024153_harden_sparks_initiative_actions_foundation.sql
---

# Fechamento Técnico 17-B.5F.3C.6C — Fundação Transversal de Ações de Iniciativas

## 1. Contexto e identificação do gate

Este documento integra a missão **SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE** e formaliza o encerramento do gate `17-B.5F.3C.6C — Initiative Actions Governance Foundation` no projeto Supabase `skpe-saas-dev` (`vumbfpbcozjebomcthdw`).

O gate sucede a fundação transversal de iniciativas e o contrato governado de lifecycle/progresso, preservando a separação entre o domínio organizacional transversal `sparks_*` e os objetos metodológicos especializados `skpe_*`.

O objetivo foi estabelecer uma fundação transversal para ações subordinadas a iniciativas, com hierarquia intra-iniciativa, planejamento temporal, custos, esforço, área responsável, auditoria dedicada, RLS e privilégios mínimos, sem antecipar RPCs operacionais, máquina de estados, roll-up automático, Kanban, Gantt, calendário ou sincronização automática com o SK-PE.

## 2. Dependências e critérios de entrada

- `17-B.5F.3C.6A — Fundação de Governança Transversal de Iniciativas` fechado;
- lifecycle e progresso transversal de iniciativas governados pelas migrations `20260820145021` e `20260820145252`;
- repositório canônico confirmado como `rrgestao/skpe-saas`;
- branch canônica `feature/formulacao-estrategica-operacional`;
- projeto Supabase dev confirmado como `skpe-saas-dev` (`vumbfpbcozjebomcthdw`);
- nenhuma materialização automática de ações legadas autorizada;
- nenhuma expansão para Kanban, Gantt, calendário ou gestão genérica de tarefas autorizada neste gate.

## 3. Escopo executado

A migration `20260821022449_sparks_initiative_actions_governance_foundation.sql` estabeleceu:

- `public.sparks_initiative_actions` como entidade transversal de ações pertencentes a iniciativas organizacionais;
- vínculo composto obrigatório entre ação, iniciativa e organização;
- hierarquia intra-iniciativa por `parent_action_id`, impedindo auto-parent;
- identidade por código dentro da iniciativa;
- `action_type` restrito a `action` e `milestone`;
- baseline original e planejamento vigente por datas separadas;
- execução real por `started_at`, `completed_at` e `last_update_at`;
- lifecycle inicial de ações por `status`, prioridade e progresso de 0 a 100;
- custo planejado, custo realizado, moeda e esforço estimado;
- área organizacional responsável vinculada ao domínio transversal `ORGANIZATIONAL_AREA`;
- trilha `public.sparks_initiative_action_audit`;
- índices de escopo, hierarquia, prazo e auditoria;
- RLS nas duas tabelas;
- `authenticated` com leitura apenas;
- ausência deliberada de policies de `INSERT`, `UPDATE` e `DELETE` para `authenticated`;
- privilégios operacionais preservados para `service_role`.

A migration `20260821024153_harden_sparks_initiative_actions_foundation.sql` corrigiu a policy de leitura da auditoria para vincular explicitamente:

- `initiative.id = sparks_initiative_action_audit.initiative_id`;
- `initiative.organization_id = sparks_initiative_action_audit.organization_id`;
- autorização pela função `public.can_manage_sparks_initiatives(...)`.

## 4. Invariantes preservadas

- `sparks_initiatives.status` permanece lifecycle organizacional transversal;
- `sparks_initiatives.progress` permanece progresso organizacional governado;
- ações não alteram automaticamente lifecycle ou progresso da iniciativa pai;
- `skpe_initiative_actions` não foi migrada, reescrita ou rematerializada;
- não foi criada sincronização automática entre `skpe_*` e `sparks_*`;
- `source_module_code` permanece proveniência/contexto, e não propriedade existencial ou autorização;
- responsabilidades pessoais continuam pertencendo à matriz transversal `sparks_responsibility_assignments`;
- Kanban, Gantt e calendário permanecem projeções/capacidades futuras, não novas entidades deste gate;
- nenhuma RPC operacional de ações foi criada;
- nenhuma máquina de estados de ações foi implementada neste gate.

## 5. Evidências de validação estrutural e de segurança

Foram confirmados:

- RLS habilitado em `sparks_initiative_actions` e `sparks_initiative_action_audit`;
- `authenticated` preservado com `SELECT` apenas nas duas tabelas;
- ausência de caminho direto de mutação para `authenticated`;
- FKs compostas preservando escopo ação + iniciativa + organização;
- trigger `sparks_initiative_actions_validate_domain_scope` validando que `responsible_area_id` pertença ao domínio ativo `ORGANIZATIONAL_AREA` da mesma organização;
- policy `sparks_initiative_actions_select_member` baseada em `can_read_organization(organization_id)`;
- policy endurecida `sparks_initiative_action_audit_select_authorized` vinculada explicitamente à iniciativa e à organização da linha auditada.

## 6. Evidência comportamental de autorização

O RLS foi validado com teste positivo e negativo sob role `authenticated`, simulando o `auth.uid()` real de usuários com escopos organizacionais distintos.

Controle positivo — administrador ativo da COOTAQUARA:

- `can_manage_sparks_initiatives = true`;
- ação técnica temporária visível: 1;
- registro de auditoria temporário visível: 1.

Controle negativo — administrador ativo exclusivamente da COOPERCOMPANY:

- `can_manage_sparks_initiatives = false` para a iniciativa da COOTAQUARA;
- ação técnica temporária visível: 0;
- registro de auditoria temporário visível: 0.

Os registros técnicos temporários utilizados exclusivamente para o teste foram removidos ao final, com contagem residual igual a zero nas duas tabelas.

Resultado: **PASS COMPORTAMENTAL / RLS VALIDADO / HARDENING VALIDADO**.

## 7. Reconciliação Supabase x repositório

Durante o fechamento foi identificado drift documental/técnico: as migrations `20260821022449` e `20260821024153` estavam aplicadas no Supabase dev, mas ainda ausentes do repositório canônico.

A recuperação foi realizada a partir do histórico de migrations do próprio Supabase, sem reaplicar DDL no banco.

O `supabase migration list --linked` confirmou equivalência Local = Remote, inclusive:

- `20260821022449 | 20260821022449`;
- `20260821024153 | 20260821024153`.

As duas migrations foram incorporadas ao repositório em commit atômico:

`f8ebbf8f12e12672f5604150e1ffa20df13b331d`

Mensagem:

`fix(platform): reconcile initiative actions migrations`

Após o push:

- `NEW_LOCAL = f8ebbf8f12e12672f5604150e1ffa20df13b331d`;
- `NEW_ORIGIN = f8ebbf8f12e12672f5604150e1ffa20df13b331d`;
- `NEW_REMOTE = f8ebbf8f12e12672f5604150e1ffa20df13b331d`;
- working tree limpo;
- os dois arquivos confirmados no GitHub remoto.

## 8. Riscos residuais e itens fora do escopo

O advisor de segurança do Supabase mantém um aviso preexistente, fora do escopo deste gate, relativo à proteção contra senhas vazadas (`auth_leaked_password_protection` desabilitada). Esse item deve ser tratado em gate próprio de segurança/Auth, sem expansão oportunista deste fechamento.

Permanecem fora do escopo e não devem ser interpretados como pendência do `17-B.5F.3C.6C`:

- RPCs governadas para criar/editar/transicionar ações;
- máquina de estados operacional de ações;
- roll-up governado de progresso das ações para iniciativas;
- atribuição pessoal governada por ação;
- projeções Kanban;
- projeções Gantt;
- agenda/calendário transversal;
- gestão de custo/financeiro expandida;
- migração ou sincronização automática de `skpe_initiative_actions`.

Esses pontos dependem de gates posteriores e devem preservar a semântica estabelecida nesta fundação.

## 9. Critérios de saída

- migration principal aplicada e registrada no Supabase dev;
- hardening aplicado e registrado no Supabase dev;
- RLS estrutural validado;
- RLS comportamental positivo e negativo validado;
- policy de auditoria corrigida e confirmada;
- dados técnicos temporários removidos;
- migration history Local = Remote;
- duas migrations presentes no repositório canônico;
- stage e commit restritos exclusivamente aos dois arquivos de migration na reconciliação;
- local, tracking branch e referência remota convergentes;
- working tree limpo após o push;
- nenhuma migration reaplicada durante a reconciliação.

Todos os critérios de saída foram atendidos.

## 10. Estado do gate

O estado estrutural no Supabase é **PASS**.

O estado comportamental de autorização/RLS é **PASS**.

O hardening de segurança é **PASS**.

A reconciliação Supabase x Git é **PASS**.

O fechamento técnico está **APROVADO**.

**GATE: 17-B.5F.3C.6C — PASS / CLOSED.**

A próxima evolução não deve reabrir este gate nem alterar suas invariantes sem decisão arquitetural explícita e novo gate governado sob a continuidade obrigatória da **SK-PE-CONT-01**.