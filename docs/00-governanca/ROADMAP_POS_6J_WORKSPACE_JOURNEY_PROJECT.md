---
id: SKPE-ROADMAP-POS-6J-WORKSPACE-JOURNEY-PROJECT
version: 1.1.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
canonical_context: SK-PE-CONT-01
created_at: 2026-08-29
updated_at: 2026-08-29
starts_after: 17-B.5F.3C.6J
remaining_gates: 2
---

# Roadmap pós-6J — Workspace Principal e Visibilidade Jornada ↔ Projeto

## 1. Contexto

A trilha `17-B.5F.3C.6D–6J` está integralmente encerrada. Este roadmap não reabre aqueles gates e não cria novos domínios transacionais.

A reconciliação pós-6J confirmou duas lacunas de experiência apoiadas por contratos existentes:

1. completar a família canônica `FE-09.A.06 — Painel Principal`, fazendo a entrada padrão do módulo aplicar a preferência `workspace.primary_dashboard` já persistida e governada;
2. tornar suficientemente visível e operacional a relação entre Projeto Estratégico e Jornada sem duplicar entidades ou fontes de verdade.

## 2. Sequência canônica

### FE-09.A.06-H — Painel Principal como landing governado do usuário

Esta entrega é continuação da família documental já existente `FE-09.A.06`; não constitui uma nova frente `FE-09.A`.

Objetivo: fazer a entrada padrão no módulo SK-PE respeitar o `workspace.primary_dashboard` elegível do usuário, preservando o fallback canônico e mantendo `workspace.favorites` como preferência separada.

Inclui:

- leitura da preferência pessoal já existente;
- aplicação somente na entrada padrão do módulo, sem sequestrar rotas explícitas;
- `my-work` e `executive` permanecendo na Visão Geral enquanto forem superfícies de `overview`;
- `portfolio` abrindo Iniciativas quando elegível;
- `governance` abrindo Governança quando elegível;
- fallback seguro conforme o contrato FE-09.A.06;
- manutenção de `workspace.favorites` como lista independente;
- sincronização dos atalhos do Meu Espaço de Trabalho com o roteamento governado do `SkpeWorkspace`.

Não inclui:

- novos tipos de dashboard;
- mudança de schema das preferências;
- transformar Favoritos em múltiplos painéis principais;
- composição futura de widgets de Agenda/Mensageria.

Evidência técnica materializada:

- commit `e97a946f08e7d959b1f9e0f09cfb183168bd4772` — `feat(skpe): apply primary dashboard on module entry`;
- testes web: `112/112 PASS`;
- build de produção: `PASS`;
- worktree local após push: limpa;
- DEV sem nova migration; última migration permanece `20260829232922`;
- contratos reutilizados: `get_my_module_preference`, `set_my_module_preference`, `delete_my_module_preference`.

Critério de saída: ao entrar pela rota padrão do módulo, o usuário é direcionado uma única vez para o Painel Principal elegível; rotas explícitas continuam soberanas; fallback permanece determinístico e não há loop de navegação.

**Status: IMPLEMENTED — validação final de comportamento ainda pendente antes de PASS/CLOSED.**

### PÓS-6J.02 — Visibilidade e wiring Projeto Estratégico ↔ Jornada

Este é um identificador interno deste roadmap. Não deve ser interpretado como continuação de uma família `FE-09.B` sem contrato canônico próprio.

Objetivo: tornar explícita para o usuário a relação entre o Projeto Estratégico e sua Jornada, reutilizando os contratos existentes e sem criar entidade concorrente.

Fundação já existente:

- `create_skpe_project_from_template`;
- `prepare_skpe_project`;
- `start_skpe_project_pem00`;
- `backfill_skpe_project_journey_from_template`;
- template publicado da Jornada;
- read models e projeções temporais do Projeto/Jornada.

Inclui:

- visibilidade clara do Projeto que materializa a Jornada;
- navegação contextual Projeto ↔ Jornada;
- identificação de template/estado quando útil ao usuário;
- reaproveitamento da hierarquia já materializada;
- correção apenas de wiring/UX comprovadamente faltante.

Não inclui:

- sincronização paralela;
- segunda tabela de Jornada;
- novo lifecycle;
- recriação automática de hierarquia já existente.

Critério de saída: o usuário compreende e navega a relação Projeto ↔ Jornada sem duplicidade de fonte de verdade.

**Status: PLANNED — inicia somente após FE-09.A.06-H PASS/CLOSED.**

## 3. Ordem congelada

`17-B.5F.3C.6J -> FE-09.A.06-H -> PÓS-6J.02`

Enquanto `FE-09.A.06-H` não estiver formalmente fechado, restam **2 gates** neste roadmap pós-6J.

## 4. Regra de governança

- 6D–6J permanecem fechados;
- a família FE-09.A.06 existente é reutilizada e não renomeada;
- preferências existentes são reutilizadas, não remodeladas sem necessidade;
- Projeto e Jornada mantêm suas autoridades canônicas atuais;
- novas necessidades fora desta sequência devem ser propostas separadamente.

**ROADMAP PÓS-6J — FE-09.A.06-H IMPLEMENTED / VALIDATION PENDING — PÓS-6J.02 PLANNED.**