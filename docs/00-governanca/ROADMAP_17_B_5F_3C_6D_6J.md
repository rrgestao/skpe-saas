---
id: SKPE-ROADMAP-17-B-5F-3C-6D-6J
version: 1.6.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
canonical_context: SK-PE-CONT-01
created_at: 2026-08-21
updated_at: 2026-08-29
starts_after: 17-B.5F.3C.6C
ends_at: 17-B.5F.3C.6J
remaining_gates: 1
---

# Roadmap Governado 17-B.5F.3C.6D–6J — Operação e Visões Transversais de Iniciativas

## 1. Contexto

Este roadmap deriva do fechamento `17-B.5F.3C.6C — Initiative Actions Governance Foundation` e integra a missão **SK-PE-CONT-01 — Continuidade Segura e Fechamento Controlado do SPARKs PE**.

Seu objetivo é congelar a sequência restante desta trilha, impedindo expansão oportunista, duplicação de domínios e mistura entre autoridade transacional e projeções de experiência.

A fundação já aprovada permanece autoridade: `sparks_initiatives` representa iniciativas organizacionais transversais; `sparks_initiative_actions` representa suas ações de execução; objetos `skpe_*` continuam metodológicos/especializados e não são substituídos por sincronização automática.

## 2. Sequência canônica restante

### 17-B.5F.3C.6D — Operação Governada de Lifecycle e Execução de Ações

Objetivo: tornar `sparks_initiative_actions` operável exclusivamente por contratos governados, sem escrita direta por `authenticated`.

Inclui: criação governada; edição permitida; transições de lifecycle; progresso; datas reais; justificativa obrigatória; auditoria; autorização por organização e contexto.

Não inclui: roll-up para iniciativa, atribuição pessoal, Kanban, Gantt ou calendário.

Critério de saída: RPCs/contratos operacionais seguros, matriz de transições validada, testes positivos/negativos de autorização e ausência de mutação direta.

**Status: PASS / CLOSED em 2026-08-21.**

Commit técnico: `c3e2f07c01aac190da1e6e2526a7614d8034d0c0`.

Evidência documental: `docs/auditoria/RELATORIO_FECHAMENTO_17_B_5F_3C_6D.md`.

### 17-B.5F.3C.6E — Responsabilidades Governadas em Ações

Objetivo: vincular pessoas e papéis às ações pela autoridade transversal de responsabilidades, sem duplicar responsável pessoal em `sparks_initiative_actions`.

Inclui: integração com `sparks_responsibility_assignments`; papéis de responsabilidade; vigência; organização; auditoria; leitura contextual.

Não inclui: engine genérico de RH ou workflow de aprovação.

Critério de saída: atribuição e remoção governadas, integridade organizacional, RLS comportamental e ausência de fonte de verdade concorrente.

**Status: PASS / CLOSED em 2026-08-21.**

Commit técnico: `c38ac2e513aff98463d33dfe77edc1ab56e103ff`.

Evidência documental: `docs/auditoria/RELATORIO_FECHAMENTO_17_B_5F_3C_6E.md`.

### 17-B.5F.3C.6F — Roll-up Governado de Progresso e Saúde

Objetivo: definir como ações contribuem para progresso/saúde de iniciativas sem destruir a autoridade do progresso organizacional governado.

Inclui: política explícita de agregação; tratamento de milestones; pesos quando aplicáveis; exceções; bloqueios; completude; auditabilidade; possibilidade de override governado quando justificado.

Não inclui: cálculo metodológico automático de objetivos do SK-PE.

Critério de saída: algoritmo determinístico, casos-limite validados, não regressão do lifecycle da iniciativa e rastreabilidade do valor agregado.

**Status: PASS / CLOSED em 2026-08-21.**

Commit técnico: `d1ffe7225bd80d31785b66a8d1a9d3c942ab6e72`.

Evidência documental: `docs/auditoria/RELATORIO_FECHAMENTO_17_B_5F_3C_6F.md`.

### 17-B.5F.3C.6G — Projeção Kanban Transversal

Objetivo: disponibilizar visão Kanban como projeção das ações existentes, sem criar segunda fonte de verdade.

Inclui: colunas derivadas do lifecycle; filtros por organização, iniciativa, área e responsável; ordenação/apresentação governada; ações operacionais chamando os contratos do 6D.

Não inclui: entidade `kanban_card` paralela nem lifecycle próprio do quadro.

Critério de saída: Kanban funcional sobre o domínio existente, consistência bidirecional pela camada operacional e UX validada.

**Status: PASS / CLOSED em 2026-08-29.**

Commit técnico de fechamento: `f7919f4daa036ea6916d90e375ec77c793fff97c`.

Migration final do read model: `20260829151019_harden_sparks_initiative_action_board_filters`.

Evidência documental: `docs/auditoria/RELATORIO_FECHAMENTO_17_B_5F_3C_6G.md`.

Guardrail UX: `docs/00-governanca/GUARDRAIL_UX_BASILAR_6G_6H_JORNADA.md`.

### 17-B.5F.3C.6H — Gantt, Baseline e Desvio Temporal

Objetivo: oferecer visão temporal previsto x vigente x realizado para iniciativas e ações.

Inclui: baseline; planejamento vigente; datas reais; dependências somente se justificadas por contrato próprio; atraso/adiantamento; caminho crítico apenas se semanticamente suportado; visão por período.

Não inclui: duplicação de datas em entidade gráfica de Gantt.

Critério de saída: projeção Gantt derivada do domínio canônico, métricas de desvio reproduzíveis e rastreabilidade de replanejamento.

**Status: PASS / CLOSED em 2026-08-29.**

Commits técnicos finais:

- `80cada6d20ec931ee5940c3a82c3603e728a4af9` — hierarquia condensada e colapsável por padrão;
- `ccee191d8f51dd45ffec146a8ca7653d4b6cfb31` — exposição explícita dos desvios temporais canônicos.

Evidência documental: `docs/auditoria/RELATORIO_FECHAMENTO_17_B_5F_3C_6H.md`.

Guardrail UX atendido: o Gantt nasce hierárquico, colapsável e condensado, com `Recolher tudo` / `Expandir tudo` e sem renderização profunda desnecessária.

### 17-B.5F.3C.6I — Agenda, Calendário e Eventos Operacionais

Objetivo: estabelecer capacidade transversal de agenda/eventos vinculáveis a iniciativas, ações e demais objetos autorizados da Plataforma.

Inclui: evento, prazo, reunião, marco, recorrência quando necessária, vínculo polimórfico governado, participantes/visibilidade conforme autorização e projeções de calendário.

Não inclui: transformar MegaFases/Fases/Etapas em eventos; elas podem possuir eventos associados sem perder sua natureza metodológica.

Critério de saída: autoridade única para eventos, vínculos rastreáveis, calendário derivado e ausência de duplicação de cronograma.

**Status: PASS / CLOSED em 2026-08-29.**

Fundação reutilizada: `sparks_events`, `sparks_event_participants`, preferências pessoais de agenda, contratos governados de lifecycle, participantes e presença, `get_my_sparks_agenda` e `get_my_skpe_agenda_projection`.

Migrations finais do gate:

- `20260829190418_extend_sparks_event_source_to_initiatives_actions` — amplia vínculos autorizados para `sparks_initiative` e `sparks_initiative_action`;
- `20260829190604_harden_sparks_event_source_polymorphic_links` — exige tipo de origem reconhecido e objeto real, eliminando passagem genérica de vínculo;
- `20260829232922_extend_skpe_agenda_projection_with_initiative_deadlines` — projeta reuniões, prazos de iniciativas e prazos/marcos de ações diretamente das autoridades canônicas, sem persistência paralela.

Commits técnicos e de UX relevantes:

- `e17bccf2de1dd30da90ec56c0eb68043b0f146e4` — criação contextual de eventos a partir de iniciativas e ações reutilizando o diálogo governado;
- `f84cc5114f08ca0a01ced3f773beec007269159c` — projeção de prazos e marcos canônicos na agenda;
- `ab48a2b148cac3209a9eea3af265a60809e9c9ac` e `f4f1c68a1f214d1901ec553aab4616d63613ac1d` — hardenings de legibilidade e comportamento transversal do shell observados durante a validação do gate, sem alterar sua semântica funcional.

Evidência documental: `docs/auditoria/RELATORIO_FECHAMENTO_17_B_5F_3C_6I.md`.

A recorrência permanece condicional: não foi criado mecanismo recorrente sem necessidade funcional comprovada, conforme o próprio escopo “quando necessária”.

### 17-B.5F.3C.6J — Custos, Esforço e Controle Econômico de Execução

Objetivo: consolidar o controle econômico mínimo necessário para comparar planejado x realizado em iniciativas e ações, preservando a futura integração com módulos financeiros especializados.

Inclui: custo planejado e realizado já fundados; esforço; variações; moeda; totalizações governadas; visões gerenciais; regras de consolidação.

Não inclui: contabilidade, orçamento corporativo completo, contas a pagar/receber ou substituição de ERP.

Critério de saída: totalizações determinísticas, variações rastreáveis, integração semântica com iniciativa/ação e fronteira explícita com domínio financeiro especializado.

## 3. Ordem e dependências

A ordem canônica é:

`6C -> 6D -> 6E -> 6F -> 6G -> 6H -> 6I -> 6J`

Dependências principais:

- 6D depende da fundação 6C;
- 6E depende de 6D para operações governadas;
- 6F depende de 6D e deve considerar 6E apenas onde responsabilidade afete leitura/contexto, nunca cálculo de progresso por si só;
- 6G depende de 6D e consome 6E/6F quando disponíveis;
- 6H depende de 6D e da semântica temporal já fundada;
- 6I deve reutilizar iniciativas/ações e não duplicar Gantt ou jornadas;
- 6J depende da autoridade de iniciativas/ações e pode alimentar projeções de 6G/6H sem criar lifecycle paralelo.

## 4. Contagem congelada

Após o fechamento do `17-B.5F.3C.6I`, resta **1 gate** nesta trilha:

1. `17-B.5F.3C.6J`

A criação de subgates de hardening, testes ou reconciliação não altera esta contagem funcional; subgates existem para controle de implementação e não para expandir o roadmap funcional.

## 5. Regra de governança

Nenhum gate posterior deve reabrir as decisões encerradas em `6A`, `6B` ou `6C` sem decisão arquitetural explícita.

Projeções de UX devem consumir autoridades existentes, nunca criar fontes de verdade paralelas.

Qualquer necessidade nova que não se encaixe claramente em `6D–6J` deve ser registrada como proposta separada e não incorporada silenciosamente a esta trilha.

**ROADMAP 17-B.5F.3C.6D–6J — 6I CLOSED / 1 GATE RESTANTE — 6J OPEN.**