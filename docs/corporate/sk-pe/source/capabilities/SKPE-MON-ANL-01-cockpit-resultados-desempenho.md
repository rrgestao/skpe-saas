---
id: skpe-mon-anl-01-cockpit-resultados-desempenho
title: SKPE-MON-ANL-01 — Cockpit de Resultados e Desempenho
domain: products
type: capability
status: active
owner: product
canonicality: supporting
canonical: false
criticality: high
parent:
  - sk-pe-product-hub
related:
  - skpe-med-des-01
  - sk-pe-current-state
  - sk-pe-capability-execution-and-traceability
  - specification-driven-architecture-hub
tags:
  - sk-pe
  - monitoring
  - analytics
  - performance
  - dashboard
  - strategic-map
  - capability
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product-capability
created: 2026-09-06
updated: 2026-09-12
lineage:
  - repository: br-robson/projetos
    source_sha: 2915073884fefa1a7bd98a7775df5f37a5f85ec9
    path: docs/products/sk-pe/capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md
  - ./../current-state.md
---

# SKPE-MON-ANL-01 — Cockpit de Resultados e Desempenho


## Baseline reconciliada em 12/09/2026

`SOURCE_SHA=d27373cc16740dfc86eb940abf639e322b072cc8`. [Owner de estado atual](../current-state.md), recorte B18 e conflito C03. `STATUS=FRONTEND_IMPLEMENTED_ACCEPTANCE_PARTIAL_WITH_CONFLICTS`. G1 abaixo é o último gate documental anterior, não ausência de frontend no SHA atual.

`FATO / AS-IMPLEMENTED`: [InitiativePerformanceCockpit](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx) já apresenta cards, distribuições por situação/prioridade/área/classe, sinais de atenção, mapa e callbacks de drill-down. O mapa permanece cinza sem sinal governado e exige associação unívoca de formulação. O commit 4baea804e9f42fb3a1ae76cab60928a84886a4bb registra evolução analítica em 07/09.

`CONFLICT`: a contagem local de críticas considera criticality; a RPC também considera priority/risk_level/health_status. A média da RPC usa coalesce para zero quando não há universo elegível, enquanto o contrato exige ausência distinta de zero. attentionTotal soma sinais potencialmente sobrepostos. [Contrato SQL](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260906201500_converge_sparks_portfolio_with_skpe_suggested_drafts.sql). Esses achados não redefinem silenciosamente os critérios abaixo.

`AS-OBSERVED`: shell/health HOMOL responderam 200, sem navegação autenticada. Não há teste analítico dedicado nos 18 arquivos TS nem comprovação de aceite visual/G2 nesta auditoria. O próximo gate deve revisar implementação existente contra os critérios de G2 e primeira entrega, sem recriar tela por pressupor que não existe. Prioridade posterior a Medidas preservada.

## Estado — registro G1 anterior

`CAPABILITY_ID=SKPE-MON-ANL-01`

`STATUS=G1_DATA_RECONCILED`

Esta capability inaugura, no SK-PE, o fluxo explícito de execução por capacidades e rastreabilidade incremental.

Ela ainda não é specification authority. Este documento registra intenção, escopo, decisões suportadas, fontes reconciliadas, critérios de aceite e gaps antes da implementação.

## Intenção

Transformar o Monitoramento do SK-PE de uma visão predominantemente operacional em uma camada analítica capaz de apoiar dirigentes, gestores e responsáveis pela estratégia na leitura de resultados, desempenho, atenção necessária e saúde da execução estratégica.

O Cockpit não substitui o Grid operacional já existente. Ele complementa a gestão com síntese, análise e navegação orientada à decisão.

## Usuários e decisões suportadas

O Cockpit deve apoiar, no mínimo:

- dirigentes e administradores do SK-PE na leitura consolidada da execução;
- gestores responsáveis por objetivos, iniciativas, indicadores e resultados;
- responsáveis pela governança da execução estratégica;
- usuários que precisem identificar rapidamente onde atuar.

Decisões que a tela deve ajudar a responder:

1. Onde a execução está saudável, em atenção ou crítica?
2. Quais iniciativas exigem ação imediata?
3. Quais objetivos estratégicos estão recebendo execução suficiente ou insuficiente?
4. Quais áreas concentram execução, bloqueios, atrasos ou lacunas?
5. O portfólio está avançando no ritmo esperado?
6. Quais indicadores e metas sinalizam desvio relevante?
7. Quais itens precisam de drill-down para investigação operacional?

## Relação com o SK-PE

A capability pertence à Fase 6 — Governança da execução, comunicação e aprendizado — e depende dos artefatos construídos nas fases anteriores.

Sua leitura deve preservar rastreabilidade entre:

`Objetivo Estratégico -> Indicador/Meta -> OKR/KR -> Iniciativa -> Ação -> Resultado -> Evidência`

Quando uma dimensão ainda não estiver materializada ou reconciliada no produto, a tela deve explicitar ausência de leitura em vez de inventar resultado.


## Fronteira com Medidas e Desempenho

`DECISAO / DIRETRIZ`

O Cockpit de Resultados e Desempenho não é autoridade de definição da medida. Ele consome a capability `SKPE-MED-DES-01 — Medidas e Desempenho`, que governa indicadores, metas, benchmarks, fórmulas, fontes, periodicidade, regras de interpretação e vínculos com objetivos, KRs e iniciativas.

`MEDIÇÃO != VISUALIZAÇÃO`

O cockpit apresenta, agrega, interpreta e permite explorar medidas governadas. Ele não redefine silenciosamente KPI, meta, benchmark ou regra de interpretação.

Visão Executiva e Exploração Hierárquica são experiências analíticas complementares e também consumidoras de Medidas e Desempenho.

A interface de usuário deve privilegiar linguagem de decisão e operação. IDs metodológicos, códigos internos e nomenclaturas de controle não devem ser expostos como rótulos principais ao usuário final, salvo quando houver necessidade explícita de rastreabilidade.

## Estrutura funcional alvo

### 1. Resumo executivo

Cards de leitura rápida, clicáveis quando houver drill-down governado:

- Progresso médio;
- Total de iniciativas;
- Em execução;
- Rascunhos;
- Em análise;
- Críticas;
- Bloqueadas.

Os cards não devem distorcer progresso: rascunhos e itens ainda não incorporados à execução não entram no cálculo operacional médio, salvo regra futura explicitamente aprovada.

### 2. Desempenho da execução

Visualizações candidatas:

- evolução do progresso do portfólio ao longo do tempo;
- planejado x realizado, quando houver baseline temporal governada;
- distribuição das iniciativas por situação;
- distribuição por prioridade;
- distribuição por área responsável;
- execução por classe/tipo de iniciativa;
- concentração de bloqueios e criticidade.

A primeira implementação deve usar apenas métricas cujas fontes e regras de cálculo estejam comprovadas no estado atual do sistema.

### 3. Atenção necessária

Painel de exceção para priorizar gestão.

Sinais candidatos, sujeitos a existência de dado confiável:

- iniciativas críticas;
- iniciativas bloqueadas;
- iniciativas atrasadas;
- rascunhos aguardando curadoria;
- iniciativas sem responsável;
- iniciativas sem término-alvo;
- iniciativas sem atualização dentro de cadência governada;
- indicadores/metas fora de faixa, quando a camada transversal de Medidas & Desempenho estiver integrada à leitura.

A tela deve distinguir ausência de dado de situação problemática.

### 4. Mapa Estratégico sinalizado

Criar uma leitura executiva do Mapa Estratégico, sem substituir o artefato de formulação.

Cada objetivo estratégico poderá receber um estado analítico derivado de evidências de execução vinculadas.

Estados visuais candidatos:

- `SAUDAVEL`;
- `ATENCAO`;
- `CRITICO`;
- `SEM_LEITURA`.

Esses estados não devem ser atribuídos por regra arbitrária. A implementação deve registrar a regra de derivação usada e só utilizar dimensões efetivamente governadas.

O objetivo é permitir navegação:

`Mapa sinalizado -> Objetivo Estratégico -> Iniciativas/Indicadores vinculados -> detalhe operacional`.

### 5. Resultados e desempenho por dimensão

O Cockpit deve evoluir para permitir leituras por:

- objetivo estratégico;
- tema estratégico;
- perspectiva, quando aplicável;
- área responsável;
- responsável;
- prioridade;
- situação;
- período;
- indicador/meta;
- iniciativa.

A disponibilidade de cada dimensão depende de reconciliação do modelo atual.

## Comportamento de navegação

`DECISAO`

A tela analítica não deve ser isolada do plano operacional.

Sempre que possível:

- clique em card ou segmento de gráfico aplica filtro ou drill-down correspondente;
- clique simples em linha de Grid seleciona;
- duplo clique abre a ficha/detalhe;
- detalhe deve preferir frame lateral direito quando a experiência permitir;
- retorno à visão analítica deve preservar contexto e filtros quando tecnicamente viável.

## Semântica visual

`DECISAO`

A tela deve priorizar leitura executiva, atenção e comparação.

Regras:

- não usar cor apenas como decoração;
- cor de alerta exige regra semântica explícita;
- não classificar algo como crítico sem critério governado;
- `SEM_LEITURA` deve ser visualmente diferente de `SAUDAVEL`;
- gráficos devem mostrar unidade, universo e período quando aplicável;
- valores ausentes não devem ser convertidos silenciosamente em zero.

## Padrão de Grid relacionado

Os Grids governados pelo Cockpit devem reutilizar o padrão transversal de experiência já consolidado na execução do SK-PE:

- células dimensionadas para comportar o conteúdo dentro de limites de usabilidade;
- seleção por clique simples;
- abertura de ficha por duplo clique;
- filtros por coluna e recursos do Smart Grid;
- atributos semânticos de classificação, responsabilidade, datas e progresso centralizados conforme padrão compartilhado do design system.

## Fontes de dados reconciliadas no G1

A inspeção somente leitura do Supabase `vumbfpbcozjebomcthdw` confirmou os seguintes contratos disponíveis no estado atual:

### Portfólio de iniciativas

`get_sparks_initiatives_portfolio`

Retorna, entre outros:

- iniciativa;
- projeto SK-PE;
- categoria;
- classe;
- status;
- prioridade;
- criticidade;
- área responsável;
- origem;
- módulo fonte;
- tema estratégico;
- início;
- término-alvo;
- progresso;
- risco;
- saúde;
- última atualização.

`get_sparks_initiatives_portfolio_dashboard`

Retorna:

- total de iniciativas;
- propostas;
- em execução;
- concluídas;
- bloqueadas;
- críticas;
- progresso médio.

### Objetivos e vínculos

Foram confirmados:

- `skpe_strategic_objectives`;
- `skpe_initiative_objectives`.

Isso torna tecnicamente possível construir leitura de execução por objetivo, mas a regra de saúde do objetivo ainda precisa ser governada.

### Riscos e mitigação

Foram confirmados:

- `skpe_strategic_risk_items`;
- `skpe_strategic_risk_mitigation_links`.

Esses objetos permitem relacionar risco estratégico, mitigação, iniciativa e ação, sem concluir automaticamente que a efetividade já foi avaliada.

### Medidas e desempenho

Foram confirmados os objetos:

- `skpe_indicators`;
- `skpe_indicator_targets`;
- `skpe_benchmark_references`;
- `skpe_indicator_measurements`;
- `skpe_performance_snapshots`;
- `skpe_sparks_initiative_indicator_links`;
- `sparks_measure_indicators`;
- `sparks_measure_targets`;
- `sparks_measure_benchmarks`;
- `sparks_measure_measurements`;
- `sparks_performance_snapshots`.

Também foram confirmadas funções de leitura/cálculo, incluindo:

- `get_my_sparks_measure_indicators`;
- `get_skpe_strategic_performance`;
- `skpe_calculate_strategic_performance`;
- `skpe_monitoring_performance_status`.

`get_my_sparks_measure_indicators` já expõe indicador, baseline, unidade, polaridade, frequência, fonte de dados e alvo, incluindo valores de meta e tolerâncias quando existentes.

A existência do contrato não prova, sozinha, população histórica suficiente para qualquer gráfico temporal.

## Readiness dos widgets após G1

| Widget / leitura | Readiness | Fundamentação atual |
| --- | --- | --- |
| Cards executivos do portfólio | `READY` | RPC de dashboard já disponível e em uso operacional |
| Distribuição por situação | `READY` | `initiative_status` no portfólio unificado |
| Distribuição por prioridade | `READY` | `priority` no portfólio unificado |
| Distribuição por área | `READY` | `responsible_area_*` no portfólio unificado |
| Distribuição por classe | `READY` | `initiative_class` no portfólio unificado |
| Críticas e bloqueadas | `READY` | `criticality` e `initiative_status` disponíveis |
| Rascunhos aguardando curadoria | `READY` | proposta/status/origem já governados no portfólio |
| Sem responsável / sem término-alvo | `READY` | área/responsabilidade e `target_end_date` disponíveis; regra visual deve diferenciar ausência de dado |
| Atrasadas | `PARTIAL` | datas existem, mas regra governada de atraso ainda não foi fechada |
| Evolução temporal do portfólio | `PARTIAL` | snapshots/performance existem, mas população e granularidade histórica ainda precisam ser verificadas |
| Indicadores e metas fora de faixa | `PARTIAL` | contratos de indicadores/metas/tolerâncias existem; população e regra de status por contexto ainda precisam ser validadas |
| Mapa Estratégico sinalizado | `PARTIAL` | objetivos e vínculos existem; regra de saúde do objetivo ainda não foi governada |
| Planejado x realizado | `PARTIAL` | baseline/forecast e medições existem em partes do modelo; contrato analítico consolidado ainda precisa ser definido |

Nenhum widget foi classificado como `BLOCKED` neste G1, mas os itens `PARTIAL` não devem ser simulados como se estivessem prontos.

## Critérios de aceite da primeira implementação

A primeira versão do Cockpit somente poderá ser considerada funcionalmente aceita quando:

1. coexistir com a tela de Monitoramento Inicial sem substituí-la;
2. apresentar resumo executivo consistente com os dados do portfólio;
3. possuir pelo menos uma visualização analítica de composição/distribuição com regra de cálculo verificável;
4. possuir painel de atenção com pelo menos três sinais derivados de dados reais;
5. possuir Mapa Estratégico sinalizado ou, se ainda faltar contrato de dados, um estado explícito e não enganoso de `SEM_LEITURA`;
6. permitir drill-down de pelo menos uma visualização para a execução operacional;
7. não contabilizar rascunhos como progresso operacional executado;
8. não converter ausência de dado em zero sem regra explícita;
9. preservar PT-BR e padrões visuais do SK-PE;
10. passar build e validação visual humana.

## Critérios técnicos e de governança

A primeira implementação deve registrar:

- fontes de dados utilizadas;
- funções/RPCs/views consumidas ou criadas;
- regras de cálculo;
- filtros e drill-downs;
- dependências;
- gaps;
- acceptance evidence;
- impacto sobre banco, frontend e demais capacidades.

Qualquer alteração que possa colidir com banco destrutivo, Auth, Storage, Edge Functions, secrets, bindings, deploy ou ambientes deve parar no collision gate antes da execução.

## Gaps e known unknowns após G1

`OPEN_GAPS=`

- série histórica/população de snapshots ainda precisa ser confirmada antes de gráfico temporal;
- regra governada de atraso precisa ser reconciliada com datas/status atuais;
- regra governada de saúde do Objetivo Estratégico ainda precisa ser definida;
- integração analítica com indicadores/metas/benchmarks existe em contrato, mas ainda precisa validar população por organização/projeto;
- periodicidade de atualização esperada por iniciativa ainda não foi adotada como regra deste Cockpit;
- experiência final de drill-down deve reutilizar componentes atuais sem criar navegação paralela.

## Evidência de baseline e G1

`ACCEPTANCE_EVIDENCE=USER_APPROVED_CONCEPTUAL_DIRECTION_IN_CHAT_2026-09-06 + READ_ONLY_SUPABASE_SCHEMA_RECONCILIATION_2026-09-06`

A direção aprovada pelo usuário é que a tela analítica contenha gráficos de análise de desempenho, sinalização de iniciativas que demandam atenção urgente, exposição de resultados/desempenho e leitura de Mapa Estratégico sinalizado.

O G1 confirmou, por inspeção somente leitura, contratos reais de portfólio, objetivos, riscos e Medidas & Desempenho no sistema de registro atual.

## Próximo gate — escopo original G2, a reconciliar com a baseline

`NEXT_CAPABILITY_GATE=SKPE-MON-ANL-01-G2`

Objetivo do G2:

- definir a composição visual da primeira wave usando somente widgets `READY` e estados explícitos para itens `PARTIAL`;
- definir regras de drill-down;
- definir quais sinais de atenção entram na primeira entrega;
- não criar DDL nem alterar infraestrutura;
- então materializar a primeira wave frontend do Cockpit de Resultados e Desempenho.
