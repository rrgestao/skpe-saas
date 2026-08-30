---
id: SKPE-ROADMAP-POS-6J-WORKSPACE-JOURNEY-PROJECT
version: 1.0.0
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

A reconciliação pós-6J confirmou duas lacunas de experiência já apoiadas por contratos existentes:

1. `workspace.primary_dashboard` já é singular e governado, porém o módulo SK-PE ainda abre sempre em `overview` e apenas informa qual Painel Principal está salvo;
2. a criação/preparação do projeto estratégico e a Jornada já possuem contratos canônicos, mas sua relação ainda precisa ficar suficientemente visível e operacional para o usuário sem duplicar Projeto e Jornada.

## 2. Sequência canônica

### FE-09.A — Painel Principal como landing governado do usuário

Objetivo: fazer a entrada padrão no módulo SK-PE respeitar o `workspace.primary_dashboard` elegível do usuário, preservando `Meu Trabalho` como fallback e mantendo Favoritos como preferência separada.

Inclui:

- leitura da preferência pessoal já existente;
- aplicação somente na entrada padrão do módulo, sem sequestrar rotas explícitas;
- `my-work` e `executive` permanecendo na Visão Geral enquanto forem superfícies de `overview`;
- `portfolio` abrindo Iniciativas quando elegível;
- `governance` abrindo Governança quando elegível;
- fallback seguro para `overview` quando a preferência estiver ausente, inválida, inelegível ou indisponível;
- manutenção de `workspace.favorites` como lista independente, sem competir com o Painel Principal.

Não inclui:

- novos tipos de dashboard;
- mudança de schema das preferências;
- transformar Favoritos em múltiplos painéis principais;
- composição futura de widgets de Agenda/Mensageria, que deverá reutilizar esta semântica de landing.

Critério de saída: ao entrar por `/organizations/{id}/modules/SK-PE`, o usuário é direcionado uma única vez para o Painel Principal elegível; rotas explícitas continuam soberanas; fallback permanece determinístico.

**Status: OPEN.**

### FE-09.B — Visibilidade e wiring Projeto Estratégico ↔ Jornada

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

**Status: PLANNED — inicia somente após FE-09.A PASS/CLOSED.**

## 3. Ordem congelada

`17-B.5F.3C.6J -> FE-09.A -> FE-09.B`

Após o fechamento de 6J, restam **2 gates** neste roadmap pós-6J.

## 4. Regra de governança

- 6D–6J permanecem fechados;
- preferências existentes são reutilizadas, não remodeladas sem necessidade;
- Projeto e Jornada mantêm suas autoridades canônicas atuais;
- novas necessidades fora de FE-09.A/FE-09.B devem ser propostas separadamente.

**ROADMAP PÓS-6J — 2 GATES RESTANTES — FE-09.A OPEN.**