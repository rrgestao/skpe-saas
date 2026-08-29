---
id: SKPE-RELATORIO-FECHAMENTO-17-B-5F-3C-6G
version: 1.0.0
status: approved
domain: SPARKs PaaS
owner: SPARKs PE
canonical_context: SK-PE-CONT-01
gate: 17-B.5F.3C.6G
created_at: 2026-08-29
updated_at: 2026-08-29
---

# Relatório de Fechamento — 17-B.5F.3C.6G — Projeção Kanban Transversal

## 1. Resultado

**17-B.5F.3C.6G = PASS / CLOSED em 2026-08-29.**

O Kanban permanece projeção operacional sobre `sparks_initiative_actions`, sem entidade `kanban_card`, lifecycle próprio ou persistência gráfica paralela.

## 2. Autoridades preservadas

- ações: `sparks_initiative_actions`;
- lifecycle e mutações: contratos governados do 6D;
- responsabilidades: `sparks_responsibility_assignments` e contratos do 6E;
- progresso/roll-up: contratos do 6F;
- leitura do quadro: `get_sparks_initiative_action_board(uuid)`.

## 3. Read model final

Migration final:

`20260829151019_harden_sparks_initiative_action_board_filters`

A projeção expõe, em uma única chamada, os dados necessários à visão Kanban, incluindo:

- lifecycle da ação;
- prioridade;
- progresso oficial e calculado;
- hierarquia;
- datas;
- execução econômica já disponível;
- área responsável;
- pessoas com responsabilidades ativas.

A ampliação do read model não cria nova fonte de verdade; apenas agrega dados canônicos existentes para consumo da projeção.

## 4. UX entregue

O Kanban foi endurecido para:

- explicitar que cada cartão é a própria ação governada;
- alternar com o Portfólio sem empilhar duas grandes superfícies;
- apresentar contexto da iniciativa selecionada;
- permitir criação de ação no contexto correto;
- apresentar estado vazio orientador;
- permitir filtro por Área responsável;
- permitir filtro por Responsável;
- manter drag/drop subordinado às transições governadas;
- abrir detalhes sem criar registro paralelo.

Guardrail associado:

`docs/00-governanca/GUARDRAIL_UX_BASILAR_6G_6H_JORNADA.md`.

## 5. Evidências técnicas

Commit técnico de fechamento:

`f7919f4daa036ea6916d90e375ec77c793fff97c`

HEAD validado localmente no gate de fechamento:

`f7919f4daa036ea6916d90e375ec77c793fff97c`

Testes frontend:

- total: 112;
- PASS: 112;
- FAIL: 0.

Build de produção:

- TypeScript: PASS;
- Vite build: PASS;
- 174 módulos transformados;
- build concluído com sucesso.

O warning de bundle superior a 500 kB foi classificado como sinal de otimização de performance futura e não como falha funcional do 6G. O guardrail UX já determina carregamento sob demanda e redução de superfícies simultâneas nos próximos avanços.

## 6. Critérios de saída

| Critério | Resultado |
|---|---|
| Kanban sobre domínio existente | PASS |
| Sem segunda fonte de verdade | PASS |
| Colunas derivadas do lifecycle | PASS |
| Mutação por contratos governados | PASS |
| Filtro por iniciativa | PASS |
| Filtro por área | PASS |
| Filtro por responsável | PASS |
| Ordenação/apresentação governada | PASS |
| Consistência com lifecycle | PASS |
| UX mínima orientadora | PASS |
| Testes | PASS |
| Build | PASS |

## 7. Continuidade

Gate seguinte:

`17-B.5F.3C.6H — Gantt, Baseline e Desvio Temporal`.

O 6H deve observar obrigatoriamente o guardrail já aprovado de Gantt hierárquico, colapsável e condensável, evitando expansão integral como estado padrão e sem persistência gráfica paralela.

**SKPE_17_B_5F_3C_6G = PASS/CLOSED.**
