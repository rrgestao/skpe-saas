---
id: sk-pe-master-roadmap
title: Roadmap mestre do SK-PE
domain: products
type: roadmap
status: canonical
owner: product
canonicality: canonical
canonical: true
criticality: high
parent:
  - sk-pe-product-hub
related:
  - sk-pe-current-state
  - sk-pe-capability-execution-and-traceability
  - skpe-med-des-01
  - skpe-mon-anl-01-cockpit-resultados-desempenho
  - sparkoop-runtime-topology
  - sparkoop-deployment-map
  - sparkoop-dns-and-public-entry
tags:
  - sk-pe
  - sparks-pe
  - roadmap
  - product
  - governance
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product-space
created: 2026-09-07
updated: 2026-09-12
lineage:
  - repository: br-robson/projetos
    source_sha: 2915073884fefa1a7bd98a7775df5f37a5f85ec9
    path: docs/products/sk-pe/roadmap.md
  - ./current-state.md
---
# Roadmap mestre do SK-PE

## Identidade

Este documento é o roadmap mestre canônico do `SK-PE / SPARKs PE`.

Owner: Product / Corporate.

Repositório executável: `sparkooptech/skpe-saas`.

Branch canônica de desenvolvimento: `feature/formulacao-estrategica-operacional`.

Documento operacional complementar: `docs/ROADMAP_SKPE_SAAS.md` no repositório executável.

## Papel do documento

Este roadmap responde:

- o que deve evoluir no produto;
- por que essa evolução importa;
- qual outcome esperado orienta cada frente;
- qual prioridade relativa organiza a sequência de produto;
- qual status de produto deve ser comunicado.

Este documento não detalha scripts, migrations específicas, branches temporárias, microtarefas, comandos operacionais, releases ou decisões de runtime. Esses itens pertencem ao roadmap operacional do repositório executável quando forem necessários.


## Current Product Baseline

| Campo | Referência |
| --- | --- |
| Repository | sparkooptech/skpe-saas |
| Branch | feature/formulacao-estrategica-operacional |
| Baseline SHA | `d27373cc16740dfc86eb940abf639e322b072cc8` |
| Baseline date | `2026-09-12` |
| Conceptual baseline | [Estado atual canônico](current-state.md) |
| Runtime/HOMOL | [Fontes e limites](current-state.md#runtime-e-deployment-conhecido); shell/health HTTP 200; SHA implantado declarado, não verificado |

### Reconciliação de status em 12/09/2026

| Item do roadmap → capability | Estado comprovado na baseline | Implicação |
| --- | --- | --- |
| Medidas → [SKPE-MED-DES-01](capabilities/SKPE-MED-DES-01-medidas-desempenho.md) | B14–B17: UI, leitura contextual, catálogo, adoção e escritas existem; C01/C04 pendentes. | CURRENT / NOW mantido; primeiro gate READ_ONLY_REUSE não descreve todo o código posterior. Sem fechamento de aceite ou autorização retroativa. |
| Cockpit → [SKPE-MON-ANL-01](capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md) | B18: frontend encontrado após G1, com cards/distribuições/drill-down; C03 aberto. | NEXT continua prioridade de validação/evolução; não significa ausência de código nem G2 aceito. |
| Formulação e monitoramento | B10/B13/B19/B23/B24: contratos e UI encontrados, incluindo RAE no HEAD. | CURRENT mantido; completar reconciliação de versões, fluxo e aceite antes de declarar DONE. |

Os totais de GOV-20.1 abaixo permanecem históricos; o inventário atual tem granularidade própria em [current-state](current-state.md#inventário-de-capabilities). Prioridades Product/Corporate não foram reordenadas. Ponto de retomada: reconciliação/validação de Medidas; depois Cockpit e gaps de Formulação.

## Estado fundacional concluído

As frentes fundacionais abaixo estão registradas como `CLOSED / DONE` e não são reabertas por este roadmap:

| Frente | Status | Impacto no roadmap |
| --- | --- | --- |
| Canonicalização do repositório | DONE | O repositório executável canônico é `sparkooptech/skpe-saas`. |
| Branch canônica | DONE | A branch de desenvolvimento canônica é `feature/formulacao-estrategica-operacional`. |
| Proteção contra exclusão e force push | DONE | Risco destrutivo reduzido nos gates de governança aplicáveis. |
| Reconciliação preserve | DONE | Trabalho preservado foi classificado e deixou de ser backlog genérico. |
| Reconciliação Corporate | DONE | Autoridades arquiteturais e documentais relevantes foram reconciliadas no Corporate. |
| Resolução dos 12 bloqueados | DONE | Itens pendentes do GOV-15 foram classificados sem bloqueio genérico remanescente. |
| Contrato de roadmap Product ↔ DEV | DONE | Corporate/Product governa prioridade e escopo; DEV governa execução técnica. |

## Estado de infraestrutura relevante

Conforme GOV-20.1:

| Frente operacional | Status |
| --- | --- |
| P1 — Sincronização Robson/Ricardo | DONE |
| P2 — DNS / entrada pública | DONE |
| P3 — Configuração Traefik do SKPE-PAAS | DONE |
| P4 — Deployment / hostname / HTTPS | DONE |
| P5 — Remoção de acesso temporário | STILL_VALID |
| P6 — Auditoria de trabalho local | DONE |
| P7 — Higienização da estação | PARTIAL |

Traefik é componente comprovadamente existente da infraestrutura do SKPE-PAAS. Este roadmap não trata Traefik como nova tecnologia a adotar; ele apenas referencia o estado comprovado e deixa ajustes operacionais para o roadmap DEV quando houver execução.

Referências de infraestrutura:

- `docs/ecosystem/infrastructure/runtime-topology.md`
- `docs/ecosystem/infrastructure/deployment-map.md`
- `docs/ecosystem/infrastructure/dns-and-public-entry.md`

## Eixos funcionais sustentados

GOV-20.1 classificou os eixos funcionais em alto nível como:

- 12 eixos `IMPLEMENTED`;
- 5 eixos `PARTIAL`;
- 0 eixos `IN_PROGRESS`;
- 0 eixos `PLANNED`;
- 1 eixo `UNKNOWN`.

Esses números preservam o snapshot histórico GOV-20.1. Para o recorte investigado em 12/09/2026, consultar a baseline acima; a nova classificação não reabre frentes fundacionais nem altera prioridades.


## Prioridade atual Product/Corporate

`DECISAO`

`CURRENT_PRIORITY=SKPE-MED-DES-01 — Medidas e Desempenho`

`STATUS=CURRENT`

`PRIORITY=NOW`

Indicadores + Metas + Benchmarks passam a constituir a capability transversal de Medidas e Desempenho do SK-PE. Essa capability é a autoridade da medição: definição de indicador, finalidade, fonte, fórmula, unidade, periodicidade, linha de base, meta, horizonte, benchmark, regra de interpretação, vínculos com objetivo estratégico, KR, iniciativas, evidência de apuração e histórico/evolução.

`SECOND_PRIORITY=SKPE-MON-ANL-01 — Painel / Monitoramento de Desempenho`

`THIRD_PRIORITY=Fechamento de gaps de Formulação Estratégica`

Essas prioridades não constituem cronograma artificial. Elas indicam ordem de decisão de produto e dependência semântica.

`SKPE-MON-ANL-01 DEPENDS_ON=Medidas e Desempenho suficientemente governada para os contratos que o painel consome.`


`FIRST_IMPLEMENTATION_PATTERN=READ_ONLY_REUSE`

O primeiro padrão de implementação para Medidas e Desempenho é leitura/UI sobre contratos existentes, sem migration, sem escrita e sem redesign de schema por padrão.

`MEDIÇÃO != VISUALIZAÇÃO`

Medidas e Desempenho define a medida. Painel, Visão Executiva e Exploração Hierárquica consomem, apresentam, agregam, interpretam e permitem explorar medidas governadas.

## Roadmap por horizontes

### H0 — Fundação e governança

| EPIC | OUTCOME | STATUS | OWNER_TYPE | DEPENDENCIES |
| --- | --- | --- | --- | --- |
| Canonicalização de repositório e branch | Todos trabalham a partir do repositório e da branch canônica reconhecidos. | CLOSED / DONE | SHARED | GOV-08 a GOV-13 |
| Reconciliação preserve e Corporate | Preserve deixa de ser backlog aberto e Corporate concentra autoridade documental. | CLOSED / DONE | CORPORATE | GOV-14 a GOV-19 |
| Contrato Product ↔ DEV para roadmap | Mudanças de produto e execução técnica seguem autoridades separadas e linkadas. | CLOSED / DONE | SHARED | GOV-20.1 |

### H1 — Execução atual do produto

| EPIC | OUTCOME | STATUS | OWNER_TYPE | DEPENDENCIES |
| --- | --- | --- | --- | --- |
| SKPE-MED-DES-01 — Medidas e Desempenho | Indicadores, metas e benchmarks passam a ter autoridade semântica transversal antes de aprofundar experiências analíticas. | CURRENT / NOW | PRODUCT | GOV-24 e decisão Product/Corporate |
| SKPE-MON-ANL-01 — Cockpit de Resultados e Desempenho | Painel/monitoramento consome medidas governadas e permanece como segunda prioridade de produto. | NEXT | PRODUCT | Medidas e Desempenho suficientemente governada para os contratos do painel |
| Formulação estratégica integrada | Diagnóstico, formulação, PESTEL, SWOT, TOWS, riscos, identidade, objetivos, OKRs, iniciativas e monitoramento operam como uma experiência coerente. | CURRENT | PRODUCT | Branch canônica e documentos de capability |
| Evidências e rastreabilidade de decisão | Decisões e artefatos relevantes permanecem rastreáveis entre produto, implementação e Corporate. | CURRENT | PRODUCT | Governança do product space SK-PE |

### H2 — Operacionalização / HOMOL

| EPIC | OUTCOME | STATUS | OWNER_TYPE | DEPENDENCIES |
| --- | --- | --- | --- | --- |
| Remoção do acesso temporário | Acesso temporário só permanece enquanto necessário e é removido quando houver evidência operacional suficiente. | STILL_VALID | INFRA | P5 do GOV-20.1 |
| Higienização controlada da estação | Worktrees, branches e diretórios temporários são reduzidos sem perda de trabalho legítimo. | PARTIAL | DEV | P6 concluído e P7 pendente |
| Roadmap operacional DEV canônico | O repositório executável possui roadmap operacional novo, linkado a este roadmap mestre. | CURRENT | DEV | `docs/ROADMAP_SKPE_SAAS.md` |

### H3 — Maturidade do produto

| EPIC | OUTCOME | STATUS | OWNER_TYPE | DEPENDENCIES |
| --- | --- | --- | --- | --- |
| Maturidade analítica do SK-PE | Medidas governadas sustentam indicadores, metas, benchmarks, evidências, cockpit e visão executiva. | FUTURE | PRODUCT | SKPE-MED-DES-01 e SKPE-MON-ANL-01 |
| Exploração hierárquica e portfólio | Pessoas, capacidade, portfólio, cronograma e kanban evoluem conforme lacunas reais de uso. | FUTURE | PRODUCT | Validação de produto e evidências de uso |
| Consolidação de gaps funcionais | O eixo `UNKNOWN` e eixos `PARTIAL` são tratados por gates próprios antes de virar nova prioridade. | FUTURE | PRODUCT | Evidência funcional e ROADMAP_CHANGE_CANDIDATE quando aplicável |

### H4 — Escala futura

| EPIC | OUTCOME | STATUS | OWNER_TYPE | DEPENDENCIES |
| --- | --- | --- | --- | --- |
| Escala operacional e confiabilidade | PRD, backups, storage, observabilidade e resiliência são tratados quando HOMOL e necessidades de produto justificarem. | FUTURE | INFRA | HOMOL estabilizado e decisão Product/Corporate |
| Evolução multi-capability | Novas capabilities entram no roadmap mestre apenas por decisão Corporate/Product. | FUTURE | PRODUCT | Processo ROADMAP_CHANGE_CANDIDATE |

## Processo ROADMAP_CHANGE_CANDIDATE

Quando DEV identificar nova capability, mudança relevante de escopo, necessidade de repriorização, dependência estrutural ou mudança técnica com impacto de produto, deve registrar `ROADMAP_CHANGE_CANDIDATE`.

O registro deve conter:

- contexto;
- motivo;
- impacto;
- recomendação DEV.

Corporate/Product decide se o candidate altera o roadmap mestre. Até essa decisão, o candidate não redefine prioridade, capability, outcome ou escopo de produto.

## Relação com roadmap operacional

Repositório operacional: `sparkooptech/skpe-saas`.

Documento operacional: `docs/ROADMAP_SKPE_SAAS.md`.

O roadmap operacional é complementar e subordinado a este documento em termos de prioridade, capability, outcome e escopo de produto. Ele define como executar, em que ordem técnica, com quais gates, validações, releases e blockers.

Este roadmap mestre não replica microtarefas técnicas do roadmap operacional.
