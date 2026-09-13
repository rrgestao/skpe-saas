---
id: skpe-med-des-01
title: Medidas e Desempenho
domain: products
type: capability
status: active
owner: product
canonicality: canonical
canonical: true
criticality: high
parent:
  - sk-pe-product-hub
related:
  - sk-pe-business-rules-hub
  - sk-pe-medidas-business-rules
  - sk-pe-current-state
  - sk-pe-master-roadmap
  - skpe-mon-anl-01-cockpit-resultados-desempenho
  - sk-pe-capability-execution-and-traceability
tags:
  - sk-pe
  - medidas
  - desempenho
  - indicadores
  - metas
  - benchmarks
  - transversal
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product-capability
created: 2026-09-07
updated: 2026-09-12
lineage:
  - repository: br-robson/projetos
    source_sha: 2915073884fefa1a7bd98a7775df5f37a5f85ec9
    path: docs/products/sk-pe/capabilities/SKPE-MED-DES-01-medidas-desempenho.md
  - ./../current-state.md
---

# Medidas e Desempenho

## INTENT

`DECISAO`

Indicadores + Metas + Benchmarks constituem a capability transversal de Medidas e Desempenho do SK-PE.

A capability nasce formalizada dentro do product space SK-PE e estabelece autoridade semântica para medição de desempenho. Ela organiza como o produto define, interpreta, relaciona e evolui medidas antes que essas medidas sejam apresentadas em cockpit, visão executiva, mapa, exploração hierárquica, portfólio, cronograma ou kanban.

## SCOPE

A capability cobre a autoridade semântica para:

- definição de indicador;
- finalidade da medida;
- tipo ou natureza da medida;
- fonte;
- fórmula;
- unidade;
- periodicidade;
- linha de base;
- meta;
- horizonte da meta;
- benchmark;
- fonte e contexto do benchmark;
- responsável;
- regra de interpretação;
- vínculo com objetivo estratégico;
- vínculo com KR quando aplicável;
- vínculo com iniciativas;
- evidência de apuração;
- histórico e evolução.

Esses conceitos devem ser reconciliados com contratos existentes no Corporate e no produto antes de qualquer mudança de implementação.


## Baseline reconciliada em 12/09/2026

`SOURCE_SHA=d27373cc16740dfc86eb940abf639e322b072cc8`. [Owner de estado atual](../current-state.md), recortes B14–B17/B19 e conflitos C01/C02/C04. `STATUS=PARTIAL_WITH_EXPLICIT_CONFLICTS`; a autoridade semântica desta capability permanece intacta.

`FATO / AS-IMPLEMENTED`: MeasuresPerformanceWorkspace já consome get_sparks_measure_performance_context; a UI contém adoção de referência, seleção/arquivamento organizacional e edição/transição de benchmarks. A sequência de migrations de 08–09/09 introduz catálogo administrável, adoção organizacional e origem legacy_indicator_id. [Código](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/MeasuresPerformanceWorkspace.tsx) e [última reconciliação SQL](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909234252_reconcile_organization_specific_measure_indicators.sql).

`RECONCILIAÇÃO`: READ_ONLY_REUSE abaixo continua o contrato do primeiro gate; não descreve integralmente a implementação posterior. A autorização documental dessa ampliação não foi localizada nos owners consultados. Registrar C01, sem ratificar escrita nem alterar regra por inferência. Product deve reconciliar a evolução e seus critérios de aceite.

`FATO`: o vínculo físico indicador → KR existe em skpe_indicators.key_result_id e na view sparks_measure_indicators. O adapter sparks_upsert_measure_indicator suporta apenas strategic_objective. Portanto a existência do vínculo deixa de ser unknown físico neste SHA, mas seu uso operacional completo continua PARTIAL.

`FATO`: o read-model seleciona meta contextual, última apuração e benchmark recente; apuração ausente vira not_assessed. A última apuração não é filtrada por validated, exigindo reconciliação com FE09 (etapa FE-08) antes de ser tratada como desempenho oficial (C04).

`AS-OBSERVED`: não houve fluxo autenticado de Medidas ou auditoria RLS. Os 124 testes locais gerais passaram, sem teste dedicado dessa adoção. Trabalho externo ao SHA, população histórica, taxonomy aprovada e aceite funcional continuam UNKNOWN. Reuso entre produtos permanece INTENDED, sem novo produto/microserviço.

## Qualificação C01 C02 C04 em 12/09/2026

A [investigação dirigida no owner de estado atual](../current-state.md#investigação-dirigida-de-medidas-c01-c02-c04--12092026) aprofunda o mesmo SOURCE_SHA, sem delta do produto. Os três achados permanecem CONFLICT; nenhum foi resolvido ou aceito nesta wave.

- C01: seis fachadas existem; duas têm chamadas diretas na grid de benchmarks e uma é consumida indiretamente pela adoção. FE06/FE09 documentam contratos técnicos, mas a decisão canônica de ampliar o primeiro gate não foi localizada no escopo consultado. Product deve localizar ou deliberar essa autorização e o aceite.
- C02: filtros omitem estados válidos de formulação e oferecem approved para adoção, embora escrita exija draft/in_elaboration. A matriz distingue presença, atividade, vigência e validação; a precedência de versões depende de decisão Product antes da correção frontend.
- C04: última medição é escolhida por measurement_date/created_at, sem status/ciclo/supersessão. FE09 mantém um validated por ciclo/indicador; não foi estabelecida regra oficial global para esse RPC. A grid não expõe status de validação da apuração. Product deve definir leitura informativa versus oficial e critérios por consumidor antes de corrigir UI/read-model.

O [decision gate](../current-state.md#decision-gate-e-próximo-passo) contém ações propostas e limites. A autorização técnica e a presença de performance calculada não equivalem a aprovação funcional. Efetividade RLS, dados publicados e aceite autenticado permanecem UNKNOWN. Esta qualificação não altera o primeiro contrato nem autoriza implementação.

## STATUS — registro anterior

`STATUS=PARTIAL`

O GOV-24 identificou Medidas e Desempenho como capability transversal recomendada, com evidências suficientes para decisão Product/Corporate e lacunas suficientes para exigir gate próprio antes de implementação.

## DECISIONS

- `DECISAO`: Medidas e Desempenho passa a ser a autoridade de medição para Indicadores + Metas + Benchmarks no SK-PE.
- `DECISAO`: Painel, Visão Executiva e Exploração Hierárquica são consumidores de medidas governadas; não são autoridade da definição de KPI, meta ou benchmark.
- `DECISAO`: a reutilização externa é intencional, mas ainda não representa integração técnica com outros módulos.

## MEASUREMENT_AUTHORITY

Medidas e Desempenho define o significado, a finalidade, a origem, o cálculo, a periodicidade, a meta, o benchmark, a interpretação e a rastreabilidade de uma medida.

A cadeia metodológica de referência é:

`Evidência -> Diagnóstico -> PESTEL -> SWOT -> TOWS -> Riscos -> Direcionadores -> Objetivos -> KPI -> Meta -> OKR/KR -> Iniciativa -> Governança/Monitoramento`

A capability atua especialmente na passagem `Objetivos -> KPI -> Meta -> OKR/KR -> Iniciativa -> Governança/Monitoramento`, sem substituir as autoridades de formulação estratégica ou de execução operacional.

## CONSUMERS

São consumidores atuais ou potenciais desta capability:

- `SKPE-MON-ANL-01 — Painel / Monitoramento de Desempenho`;
- Visão Executiva;
- Exploração Hierárquica;
- mapa estratégico;
- objetivos;
- OKRs/KRs;
- iniciativas;
- portfólio;
- cronograma;
- kanban.

O cockpit apresenta, agrega, interpreta e permite explorar medidas governadas. Ele não transfere para si a autoridade sobre definição de KPI, meta ou benchmark.

## TRANSVERSAL_REUSE

`TRANSVERSAL_REUSE=INTENDED`

A capability possui natureza transversal e contratos potencialmente reutilizáveis por outros módulos SPARKOOP, incluindo SK-PN, SK-DA, SK-DOC e outros módulos que necessitem medidas e desempenho.

Essa intenção não cria novo produto, microserviço, módulo independente, repositório ou arquitetura física. Também não significa que esses módulos já estejam tecnicamente integrados ao SK-PE.

## DEPENDENCIES

- Roadmap mestre do SK-PE: `docs/products/sk-pe/roadmap.md`.
- Governança de execução e rastreabilidade: `docs/products/sk-pe/governance/capability-execution-and-traceability.md`.
- Capability consumidora: `docs/products/sk-pe/capabilities/SKPE-MON-ANL-01-cockpit-resultados-desempenho.md`.
- Repositório executável: `sparkooptech/skpe-saas`, branch `feature/formulacao-estrategica-operacional`.
- Roadmap operacional DEV: `docs/ROADMAP_SKPE_SAAS.md`.

## KNOWN_GAPS

### GAP-01

`GAP`

`KPI -> Meta -> OKR/KR` ainda requer autoridade transversal clara de medidas.

### GAP-02

`GAP`

Painel/monitoramento consome medidas, mas não deve se tornar autoridade da medição.

### GAP-03

`UNKNOWN`

Governance/authorization possui evidências documentais e técnicas, mas controle funcional efetivo não foi auditado no GOV-24.

GAP-03 não bloqueia esta decisão Product/Corporate. Ele deve permanecer como unknown/control-gate futuro.

## KNOWN_UNKNOWNS

- Estado exato de trabalho local ou não publicado de Ricardo em indicadores, metas, benchmarks, cockpit ou monitoramento.
- Existência de migrations, tabelas, views, RPCs ou contratos de medição preparados fora da branch canônica.
- Controle funcional efetivo de authorization aplicado a medidas e visualizações.

## BOUNDARIES

`MEDIÇÃO != VISUALIZAÇÃO`

Medidas e Desempenho é autoridade da medição.

Painel, cockpit, visão executiva, exploração hierárquica, mapa estratégico, portfólio, cronograma e kanban são experiências consumidoras. Elas podem apresentar, filtrar, agregar, sinalizar e explicar medidas governadas, mas não redefinem silenciosamente o conceito de indicador, meta, benchmark, KR ou regra de interpretação.

Este gate não cria novo produto, novo módulo físico, novo microserviço, novo repositório, nova migration, novo contrato Supabase, nova tela ou nova arquitetura runtime.


## Primeiro contrato de leitura

`READ_ONLY_REUSE=DEFINED`

O primeiro gate implementável de Medidas e Desempenho deve ser read-only sobre contratos existentes. O padrão é reutilizar `sparks_measure_*`, `get_my_sparks_measure_indicators` e contratos SK-PE já versionados, sem criar schema novo por padrão.

Campos e semântica mínima a expor quando disponíveis:

| Campo / semântica | Contrato inicial |
| --- | --- |
| indicador | exibir identificação humana, nome e descrição quando disponíveis |
| finalidade | exibir propósito/descrição da medida sem inventar interpretação |
| unidade | reutilizar `unit` |
| periodicidade | reutilizar `measurement_frequency` ou periodicidade equivalente |
| baseline | reutilizar valor/data de baseline quando presentes |
| meta | reutilizar target/meta existente; não confundir com benchmark |
| benchmark | reutilizar referência contextual existente; não tratar como meta organizacional |
| valor/status de desempenho | exibir valor medido e performance/status existente sem criar taxonomia nova |
| responsável existente | reutilizar `owner_user_id`, `governance_owner_user_id` ou responsável disponível |
| vínculo com objetivo | reutilizar vínculo com objetivo estratégico existente |
| vínculo com iniciativa | reutilizar vínculo iniciativa-indicador quando disponível |
| KR | `PARTIAL` enquanto contrato direto medida -> KR não estiver confirmado |
| evidência | `PARTIAL` enquanto contrato de apuração da medida não estiver confirmado |
| autorização runtime | `UNKNOWN` enquanto autorização efetiva não for auditada em runtime |

### Critérios de aceitação do primeiro gate

- sem migration;
- sem escrita;
- sem novo schema;
- sem redefinir KPI, meta ou benchmark;
- reutilizar `sparks_measure_*` e read-model existente;
- tornar unknowns e contratos parciais visíveis;
- a UI não expõe IDs metodológicos como rótulos principais;
- Painel, Visão Executiva e Exploração Hierárquica continuam consumidores, não autoridade da medição.

### Fronteira de execução

O primeiro gate pode preparar leitura e UI sobre o estado atual, mas não deve alterar Supabase, runtime, migrations, schema ou contratos de escrita. Se a leitura revelar lacuna física real, registrar novo `ROADMAP_CHANGE_CANDIDATE` ou gate técnico antes de qualquer alteração estrutural.

## ACCEPTANCE_DIRECTION

Uma futura implementação ou specification desta capability deve permitir validar objetivamente:

- quais indicadores existem e qual finalidade possuem;
- quais metas estão associadas a cada indicador;
- qual benchmark é usado, com fonte e contexto;
- como KPI, meta e KR se relacionam;
- como a medida se vincula a objetivo estratégico e iniciativa;
- qual evidência sustenta a apuração;
- qual regra de interpretação orienta sinais de desempenho;
- quais consumidores usam a medida sem redefini-la.


## Reconciliação com implementação existente

`AS-IMPLEMENTED`

A mineração dirigida das migrations do `sparkooptech/skpe-saas` confirma que já existe conhecimento físico e semântico relevante para Medidas e Desempenho. A implementação não parte do zero e não deve ser redesenhada sem preservar contratos já versionados.

Contratos já existentes:

- indicadores estratégicos em `skpe_indicators`;
- metas em `skpe_indicator_targets`;
- benchmarks em `skpe_benchmark_references` e catálogo de referência;
- baseline, fórmula, unidade, periodicidade, status e vínculo com objetivo estratégico;
- histórico/evolução por medições, snapshots e supersessão;
- vínculos com iniciativas por contratos governados;
- fachadas transversais de leitura `sparks_measure_*`;
- fachadas transversais de escrita `sparks_upsert_measure_*` e `sparks_record_measurement`;
- leitura pessoal transversal `get_my_sparks_measure_indicators`;
- separação explícita entre target/meta e benchmark;
- autorização por RLS, policies, grants e funções `SECURITY DEFINER`.

`AS-DOCUMENTED`

A decisão Product/Corporate de GOV-25 permanece válida: Medidas e Desempenho é a autoridade de medição; Painel, Visão Executiva e Exploração Hierárquica são consumidores. O documento Corporate agora incorpora que parte substancial dessa autoridade já possui contratos físicos no produto executável.

### Contratos parciais

- Responsável: há `owner_user_id`, `governance_owner_user_id` e vínculos de responsáveis, mas a responsabilidade específica por medida ainda precisa ser reconciliada no gate de implementation readiness.
- KR link: há OKRs/KRs e leitura de key results, mas a autoridade direta entre medida e KR deve ser confirmada antes de alterar schema ou UI.
- Evidence link: há `evidence_reference` e convergência de evidências transversais, mas o contrato exato entre apuração de medida e evidência precisa de validação.
- Regra de interpretação: há status, thresholds e performance automática/manual/efetiva; Product ainda deve decidir a taxonomia de interpretação que aparecerá aos usuários.

### Gaps

- Lacuna documental: o Corporate precisava registrar as fachadas transversais, a distinção target/benchmark e a existência de contratos físicos. Esta seção corrige essa lacuna.
- Lacuna de contrato: responsabilidade, vínculo com KR, evidência de apuração e regra de interpretação exigem confirmação antes de implementação.
- Lacuna física no banco: não foi comprovada lacuna física crítica para indicador, meta, benchmark, baseline, fórmula, unidade, periodicidade, objetivo, iniciativa, histórico, performance ou autorização.
- Lacuna de autorização: autorização existe como contrato implementado, mas sua efetividade runtime não foi auditada neste gate.

### Legacy relevante

A sequência observada indica evolução de autoridade SK-PE física para fachadas transversais SPARKS: primeiro surgem estruturas SK-PE de indicadores/metas/benchmarking, OKRs, iniciativas e monitoramento; depois aparecem catálogo de referência, vínculos governados, fachadas `sparks_measure_*`, escrita fail-closed e integração com evidências transversais.

### Unknowns

- Estado runtime real do banco e aplicação das migrations fora do Git.
- Trabalho local ou não publicado de Ricardo nessa frente.
- Taxonomia final de interpretação de performance aprovada por Product.
- Auditoria efetiva de authorization/RLS em execução.

### Decisões que não devem ser redesenhadas

- Não redesenhar `skpe_indicators`, `skpe_indicator_targets` ou `skpe_benchmark_references` sem prova de conflito.
- Não fundir meta e benchmark: target/meta é decisão organizacional; benchmark é referência contextual.
- Não duplicar medições em consumidores; consumidores devem usar medidas governadas.
- Não abrir suporte transversal amplo sem adapter: as fachadas atuais falham fechadas para módulos ou sujeitos não suportados.

## NEXT_CAPABILITY

`NEXT_CAPABILITY=SKPE-MON-ANL-01 — Painel / Monitoramento de Desempenho`

O aprofundamento do cockpit deve ocorrer depois que Medidas e Desempenho estiver suficientemente governada para os contratos que o painel consome.

## Piloto funcional e regras de negócio — 12/09/2026

Modelo refinado a partir do piloto `8fbfeb6b13b94723a24394a320878c46c531ee86`, no mesmo produto `d27373cc16740dfc86eb940abf639e322b072cc8`. `PRODUCT_DELTA_FROM_BASELINE=NONE`. O owner da capability explica funcionalidades e integrações; o [owner de regras](../business-rules/medidas-desempenho.md) concentra as 44 definições, autoridade, verificação, aceitação e teste. O [índice central](../business-rules/README.md) define o contrato documental. Não há promoção de autoridade nesta reorganização.

### Propósito, atores e fronteiras do piloto

Medidas define e relaciona indicador, fórmula descritiva, unidade, periodicidade, baseline, meta, tolerância, benchmark e apuração. Oferece leituras contextuais/pessoais e contratos de manutenção, cálculo, validação e histórico. Contrato SQL disponível não comprova UI alcançável ou aceite funcional.

Product governa semântica e aceite; super admin mantém catálogo; admin organizacional adota referências; gestor/validador de Formulação mantém definições; monitoramento registra; governança valida/ratifica; leitores consultam contextos autorizados. Essas permissões dependem dos contratos técnicos, sem auditoria runtime nesta wave.

Entidades: catálogo/versionamento, benchmark geral, vínculo organizacional, indicador, objetivo/KR, meta, benchmark contextual, pacote de indicadores, ciclo, medição, snapshot e vínculo iniciativa/indicador. Atividade, validação, apuração e current são eixos distintos.

Formulação governa versões/objetivos; monitoramento governa ciclos e ratificação; Cockpit consome e apresenta. Integrações constam por funcionalidade. Reuso multproduto permanece intenção; não ampliar o piloto a outras capabilities. SQL e frontend são AS-IMPLEMENTED; decisão canônica documenta AS-INTENDED; nenhum fluxo autenticado foi AS-OBSERVED nesta wave.

### Funcionalidades e relação FUNCTION → RULE

IDs F-MED permanecem estáveis. IMPLEMENTED significa caminho técnico encontrado; PARTIAL separa contrato de consumo/aceite incompleto; CONFLICT preserva divergência. A matriz não redefine regras: os links levam à única definição detalhada.

| FUNCTION_ID | Funcionalidade / intenção | READ / WRITE | Estado resumido | RELATED_RULES | STATUS |
| --- | --- | --- | --- | --- | --- |
| [F-MED-001](#f-med-001) | Consultar catálogo geral — Encontrar referências reutilizáveis | Leitura/guards; NO | draft/active/inactive/archived; is_current | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-009](../business-rules/medidas-desempenho.md#br-skpe-med-009); [BR-SKPE-MED-044](../business-rules/medidas-desempenho.md#br-skpe-med-044) | IMPLEMENTED |
| [F-MED-002](#f-med-002) | Criar versão e transicionar referência — Manter definição compartilhada com histórico | Leitura/guards; YES | draft/active/inactive/archived | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-009](../business-rules/medidas-desempenho.md#br-skpe-med-009); [BR-SKPE-MED-038](../business-rules/medidas-desempenho.md#br-skpe-med-038); [BR-SKPE-MED-043](../business-rules/medidas-desempenho.md#br-skpe-med-043) | CONFLICT |
| [F-MED-003](#f-med-003) | Excluir rascunho de catálogo — Retirar rascunho sem apagar histórico legítimo | Leitura/guards; YES | draft → excluído | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-011](../business-rules/medidas-desempenho.md#br-skpe-med-011) | IMPLEMENTED |
| [F-MED-004](#f-med-004) | Adotar referência na organização — Disponibilizar referência por vínculo organizacional | Leitura/guards; YES | ausente/archived → active | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-009](../business-rules/medidas-desempenho.md#br-skpe-med-009); [BR-SKPE-MED-010](../business-rules/medidas-desempenho.md#br-skpe-med-010); [BR-SKPE-MED-038](../business-rules/medidas-desempenho.md#br-skpe-med-038); [BR-SKPE-MED-042](../business-rules/medidas-desempenho.md#br-skpe-med-042) | CONFLICT |
| [F-MED-005](#f-med-005) | Retirar adoção organizacional — Arquivar vínculo conforme guard de uso | Leitura/guards; YES | active → archived | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-010](../business-rules/medidas-desempenho.md#br-skpe-med-010); [BR-SKPE-MED-038](../business-rules/medidas-desempenho.md#br-skpe-med-038); [BR-SKPE-MED-042](../business-rules/medidas-desempenho.md#br-skpe-med-042) | CONFLICT |
| [F-MED-006](#f-med-006) | Instanciar referência em objetivo estratégico — Criar indicador contextual por adapter | Leitura/guards; SQL_YES; UI_PATH_UNREACHABLE | Indicador draft por padrão | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-004](../business-rules/medidas-desempenho.md#br-skpe-med-004); [BR-SKPE-MED-005](../business-rules/medidas-desempenho.md#br-skpe-med-005); [BR-SKPE-MED-006](../business-rules/medidas-desempenho.md#br-skpe-med-006); [BR-SKPE-MED-009](../business-rules/medidas-desempenho.md#br-skpe-med-009); [BR-SKPE-MED-019](../business-rules/medidas-desempenho.md#br-skpe-med-019); [BR-SKPE-MED-038](../business-rules/medidas-desempenho.md#br-skpe-med-038); [BR-SKPE-MED-039](../business-rules/medidas-desempenho.md#br-skpe-med-039); [BR-SKPE-MED-042](../business-rules/medidas-desempenho.md#br-skpe-med-042); [BR-SKPE-MED-044](../business-rules/medidas-desempenho.md#br-skpe-med-044) | PARTIAL |
| [F-MED-007](#f-med-007) | Definir indicador estratégico — Manter fórmula descritiva, unidade, periodicidade e baseline | Leitura/guards; SQL_YES; DIRECT_UI_NOT_FOUND | draft/active/inactive | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-004](../business-rules/medidas-desempenho.md#br-skpe-med-004); [BR-SKPE-MED-005](../business-rules/medidas-desempenho.md#br-skpe-med-005); [BR-SKPE-MED-006](../business-rules/medidas-desempenho.md#br-skpe-med-006); [BR-SKPE-MED-007](../business-rules/medidas-desempenho.md#br-skpe-med-007); [BR-SKPE-MED-008](../business-rules/medidas-desempenho.md#br-skpe-med-008); [BR-SKPE-MED-017](../business-rules/medidas-desempenho.md#br-skpe-med-017); [BR-SKPE-MED-037](../business-rules/medidas-desempenho.md#br-skpe-med-037); [BR-SKPE-MED-038](../business-rules/medidas-desempenho.md#br-skpe-med-038) | PARTIAL |
| [F-MED-008](#f-med-008) | Arquivar indicador e dependências — Retirar indicador preservando rastreabilidade | Leitura/guards; SQL_YES; DIRECT_UI_NOT_FOUND | indicador → archived; metas → superseded | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-005](../business-rules/medidas-desempenho.md#br-skpe-med-005); [BR-SKPE-MED-012](../business-rules/medidas-desempenho.md#br-skpe-med-012) | PARTIAL |
| [F-MED-009](#f-med-009) | Consultar indicadores pessoais — Mostrar medidas sob responsabilidade do usuário | Leitura/guards; NO | draft/active/inactive | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-018](../business-rules/medidas-desempenho.md#br-skpe-med-018); [BR-SKPE-MED-020](../business-rules/medidas-desempenho.md#br-skpe-med-020) | IMPLEMENTED |
| [F-MED-010](#f-med-010) | Definir metas e tolerâncias — Registrar resultado esperado no horizonte | Leitura/guards; SQL_YES; DIRECT_UI_NOT_FOUND | draft/active na edição | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-003](../business-rules/medidas-desempenho.md#br-skpe-med-003); [BR-SKPE-MED-005](../business-rules/medidas-desempenho.md#br-skpe-med-005); [BR-SKPE-MED-013](../business-rules/medidas-desempenho.md#br-skpe-med-013); [BR-SKPE-MED-014](../business-rules/medidas-desempenho.md#br-skpe-med-014); [BR-SKPE-MED-015](../business-rules/medidas-desempenho.md#br-skpe-med-015); [BR-SKPE-MED-017](../business-rules/medidas-desempenho.md#br-skpe-med-017) | PARTIAL |
| [F-MED-011](#f-med-011) | Superseder meta — Preservar meta substituída no histórico | Leitura/guards; SQL_YES; DIRECT_UI_NOT_FOUND | não superseded → superseded | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-005](../business-rules/medidas-desempenho.md#br-skpe-med-005); [BR-SKPE-MED-014](../business-rules/medidas-desempenho.md#br-skpe-med-014); [BR-SKPE-MED-015](../business-rules/medidas-desempenho.md#br-skpe-med-015) | PARTIAL |
| [F-MED-012](#f-med-012) | Manter benchmark do indicador — Associar referência contextual distinta da meta | Leitura/guards; YES | draft | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-003](../business-rules/medidas-desempenho.md#br-skpe-med-003); [BR-SKPE-MED-005](../business-rules/medidas-desempenho.md#br-skpe-med-005); [BR-SKPE-MED-016](../business-rules/medidas-desempenho.md#br-skpe-med-016); [BR-SKPE-MED-017](../business-rules/medidas-desempenho.md#br-skpe-med-017); [BR-SKPE-MED-038](../business-rules/medidas-desempenho.md#br-skpe-med-038); [BR-SKPE-MED-043](../business-rules/medidas-desempenho.md#br-skpe-med-043) | CONFLICT |
| [F-MED-013](#f-med-013) | Verificar/ativar/arquivar benchmark — Governar confiabilidade da referência | Leitura/guards; YES | draft → verified → active; retorno/arquivo | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-003](../business-rules/medidas-desempenho.md#br-skpe-med-003); [BR-SKPE-MED-005](../business-rules/medidas-desempenho.md#br-skpe-med-005); [BR-SKPE-MED-016](../business-rules/medidas-desempenho.md#br-skpe-med-016); [BR-SKPE-MED-038](../business-rules/medidas-desempenho.md#br-skpe-med-038) | CONFLICT |
| [F-MED-014](#f-med-014) | Consultar Medidas do contexto — Apresentar indicador, meta, apuração e benchmark | Leitura/guards; NO | not_assessed ou status de measurement | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-002](../business-rules/medidas-desempenho.md#br-skpe-med-002); [BR-SKPE-MED-019](../business-rules/medidas-desempenho.md#br-skpe-med-019); [BR-SKPE-MED-020](../business-rules/medidas-desempenho.md#br-skpe-med-020); [BR-SKPE-MED-024](../business-rules/medidas-desempenho.md#br-skpe-med-024); [BR-SKPE-MED-030](../business-rules/medidas-desempenho.md#br-skpe-med-030); [BR-SKPE-MED-039](../business-rules/medidas-desempenho.md#br-skpe-med-039); [BR-SKPE-MED-040](../business-rules/medidas-desempenho.md#br-skpe-med-040) | CONFLICT |
| [F-MED-015](#f-med-015) | Registrar medição — Capturar apuração histórica e desempenho calculado | Leitura/guards; SQL_YES; DIRECT_UI_NOT_FOUND | submitted | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-008](../business-rules/medidas-desempenho.md#br-skpe-med-008); [BR-SKPE-MED-021](../business-rules/medidas-desempenho.md#br-skpe-med-021); [BR-SKPE-MED-022](../business-rules/medidas-desempenho.md#br-skpe-med-022); [BR-SKPE-MED-023](../business-rules/medidas-desempenho.md#br-skpe-med-023); [BR-SKPE-MED-031](../business-rules/medidas-desempenho.md#br-skpe-med-031); [BR-SKPE-MED-036](../business-rules/medidas-desempenho.md#br-skpe-med-036) | PARTIAL |
| [F-MED-016](#f-med-016) | Validar, rejeitar e ressubmeter medição — Governar o registro corrente por ciclo | Leitura/guards; SQL_YES; DIRECT_UI_NOT_FOUND | submitted ↔ rejected; submitted → validated | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-021](../business-rules/medidas-desempenho.md#br-skpe-med-021); [BR-SKPE-MED-022](../business-rules/medidas-desempenho.md#br-skpe-med-022); [BR-SKPE-MED-023](../business-rules/medidas-desempenho.md#br-skpe-med-023); [BR-SKPE-MED-036](../business-rules/medidas-desempenho.md#br-skpe-med-036) | PARTIAL |
| [F-MED-017](#f-med-017) | Calcular desempenho por polaridade — Comparar apuração com baseline e alvo | Leitura/guards; NO; RESULT_PERSISTED_BY_F015 | Não altera lifecycle | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-007](../business-rules/medidas-desempenho.md#br-skpe-med-007); [BR-SKPE-MED-025](../business-rules/medidas-desempenho.md#br-skpe-med-025); [BR-SKPE-MED-026](../business-rules/medidas-desempenho.md#br-skpe-med-026); [BR-SKPE-MED-027](../business-rules/medidas-desempenho.md#br-skpe-med-027); [BR-SKPE-MED-028](../business-rules/medidas-desempenho.md#br-skpe-med-028); [BR-SKPE-MED-029](../business-rules/medidas-desempenho.md#br-skpe-med-029); [BR-SKPE-MED-030](../business-rules/medidas-desempenho.md#br-skpe-med-030); [BR-SKPE-MED-031](../business-rules/medidas-desempenho.md#br-skpe-med-031); [BR-SKPE-MED-037](../business-rules/medidas-desempenho.md#br-skpe-med-037) | IMPLEMENTED |
| [F-MED-018](#f-med-018) | Agregar desempenho do ciclo — Consolidar visão/objetivos/perspectivas | Leitura/guards; NO | Leitura de ciclo, não latest global | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-002](../business-rules/medidas-desempenho.md#br-skpe-med-002); [BR-SKPE-MED-021](../business-rules/medidas-desempenho.md#br-skpe-med-021); [BR-SKPE-MED-032](../business-rules/medidas-desempenho.md#br-skpe-med-032); [BR-SKPE-MED-033](../business-rules/medidas-desempenho.md#br-skpe-med-033); [BR-SKPE-MED-034](../business-rules/medidas-desempenho.md#br-skpe-med-034); [BR-SKPE-MED-040](../business-rules/medidas-desempenho.md#br-skpe-med-040) | CONFLICT |
| [F-MED-019](#f-med-019) | Fechar/reabrir ciclo e versionar snapshot — Congelar leitura de governança e preservar versões | Leitura/guards; SQL_YES; END_TO_END_UNKNOWN | pending_ratification → closed → reopened | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-021](../business-rules/medidas-desempenho.md#br-skpe-med-021); [BR-SKPE-MED-033](../business-rules/medidas-desempenho.md#br-skpe-med-033); [BR-SKPE-MED-035](../business-rules/medidas-desempenho.md#br-skpe-med-035); [BR-SKPE-MED-040](../business-rules/medidas-desempenho.md#br-skpe-med-040) | PARTIAL |
| [F-MED-020](#f-med-020) | Consultar histórico e auditoria — Rastrear medidas e versões | Leitura/guards; NO | Preserva históricos | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-022](../business-rules/medidas-desempenho.md#br-skpe-med-022); [BR-SKPE-MED-023](../business-rules/medidas-desempenho.md#br-skpe-med-023); [BR-SKPE-MED-035](../business-rules/medidas-desempenho.md#br-skpe-med-035); [BR-SKPE-MED-036](../business-rules/medidas-desempenho.md#br-skpe-med-036) | PARTIAL |
| [F-MED-021](#f-med-021) | Configurar e validar pacote de indicadores — Avaliar prontidão metodológica | Leitura/guards; SQL_YES; DIRECT_UI_NOT_FOUND | in_elaboration → pending_validation → validated; retorno | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-005](../business-rules/medidas-desempenho.md#br-skpe-med-005); [BR-SKPE-MED-017](../business-rules/medidas-desempenho.md#br-skpe-med-017) | PARTIAL |
| [F-MED-022](#f-med-022) | Explorar vínculos com objetivo e KR — Situar medidas no desdobramento estratégico | Leitura/guards; NO; WRITE_ADAPTER_LIMITED | Estados lidos sem filtro de medição | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-002](../business-rules/medidas-desempenho.md#br-skpe-med-002); [BR-SKPE-MED-004](../business-rules/medidas-desempenho.md#br-skpe-med-004); [BR-SKPE-MED-019](../business-rules/medidas-desempenho.md#br-skpe-med-019); [BR-SKPE-MED-020](../business-rules/medidas-desempenho.md#br-skpe-med-020); [BR-SKPE-MED-024](../business-rules/medidas-desempenho.md#br-skpe-med-024); [BR-SKPE-MED-039](../business-rules/medidas-desempenho.md#br-skpe-med-039); [BR-SKPE-MED-040](../business-rules/medidas-desempenho.md#br-skpe-med-040) | PARTIAL |
| [F-MED-023](#f-med-023) | Relacionar iniciativa a indicador — Registrar contribuição sem inferir causalidade | Leitura/guards; DATABASE_CONTRACT; UI_UNKNOWN | draft/pending_validation/validated/rejected no vínculo | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-002](../business-rules/medidas-desempenho.md#br-skpe-med-002); [BR-SKPE-MED-041](../business-rules/medidas-desempenho.md#br-skpe-med-041); [BR-SKPE-MED-044](../business-rules/medidas-desempenho.md#br-skpe-med-044) | PARTIAL |
| [F-MED-024](#f-med-024) | Manter benchmark de referência geral — Administrar fonte comparável no catálogo | Leitura/guards; YES | Status do catálogo; draft excluível sob guards | [BR-SKPE-MED-001](../business-rules/medidas-desempenho.md#br-skpe-med-001); [BR-SKPE-MED-003](../business-rules/medidas-desempenho.md#br-skpe-med-003); [BR-SKPE-MED-011](../business-rules/medidas-desempenho.md#br-skpe-med-011); [BR-SKPE-MED-038](../business-rules/medidas-desempenho.md#br-skpe-med-038); [BR-SKPE-MED-043](../business-rules/medidas-desempenho.md#br-skpe-med-043) | IMPLEMENTED |

### Contratos funcionais e integrações

#### F-MED-001

**NAME:** Consultar catálogo geral. **PURPOSE:** Encontrar referências reutilizáveis. **STATUS:** IMPLEMENTED.

**ACTORS:** Admin de plataforma; admin organizacional no catálogo de adoção. **PRECONDITIONS:** Autenticação e permissão do RPC. **INPUTS:** Organização/módulo ou filtros de catálogo.

**BEHAVIOR:** Lista versões; adoção restringe current e active. **OUTPUTS:** Referências, fontes e benchmarks. **STATES:** draft/active/inactive/archived; is_current.

**DEPENDENCIES:** Catálogo transversal. **IMPLEMENTATION_EVIDENCE:** [CAT-READ][R-CAT-READ]; [CAT-ELIGIBLE][R-CAT-ELIGIBLE]; [UI-CAT][R-UI-CAT]. **DOCUMENTATION_EVIDENCE:** [AUTH][R-AUTH]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-002

**NAME:** Criar versão e transicionar referência. **PURPOSE:** Manter definição compartilhada com histórico. **STATUS:** CONFLICT.

**ACTORS:** Super admin de plataforma. **PRECONDITIONS:** require_platform_super_admin; código/nome/motivo. **INPUTS:** Definição, status, make_current.

**BEHAVIOR:** Cria nova versão; transiciona status e current separadamente. **OUTPUTS:** Referência versionada. **STATES:** draft/active/inactive/archived.

**DEPENDENCIES:** RPC catálogo. **IMPLEMENTATION_EVIDENCE:** [CAT-WRITE][R-CAT-WRITE]; [CAT-LIFE][R-CAT-LIFE]; [UI-CAT][R-UI-CAT]. **DOCUMENTATION_EVIDENCE:** [AUTH][R-AUTH]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-003

**NAME:** Excluir rascunho de catálogo. **PURPOSE:** Retirar rascunho sem apagar histórico legítimo. **STATUS:** IMPLEMENTED.

**ACTORS:** Super admin. **PRECONDITIONS:** Rascunho sem transições, benchmarks ou adoção por skpe_indicators. **INPUTS:** ID e motivo.

**BEHAVIOR:** Valida dependências; exclui e pode restaurar current anterior. **OUTPUTS:** ID excluído / referência restaurada. **STATES:** draft → excluído.

**DEPENDENCIES:** RPC + FK de adoção organizacional. **IMPLEMENTATION_EVIDENCE:** [CAT-DELETE][R-CAT-DELETE]; [DEL-PRIV][R-DEL-PRIV]; [UI-CAT][R-UI-CAT]. **DOCUMENTATION_EVIDENCE:** [AUTH][R-AUTH]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-004

**NAME:** Adotar referência na organização. **PURPOSE:** Disponibilizar referência por vínculo organizacional. **STATUS:** CONFLICT.

**ACTORS:** Admin organizacional / super admin. **PRECONDITIONS:** Referência current e active; organização e motivo. **INPUTS:** Lista de referências.

**BEHAVIOR:** Upsert do vínculo active com metadados de adoção. **OUTPUTS:** Indicadores organizacionais. **STATES:** ausente/archived → active.

**DEPENDENCIES:** Catálogo e selector. **IMPLEMENTATION_EVIDENCE:** [ADOPT-ORG][R-ADOPT-ORG]; [UI-DUAL][R-UI-DUAL]; [ORG-READ][R-ORG-READ]. **DOCUMENTATION_EVIDENCE:** [OPEN][R-OPEN]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-005

**NAME:** Retirar adoção organizacional. **PURPOSE:** Arquivar vínculo conforme guard de uso. **STATUS:** CONFLICT.

**ACTORS:** Admin organizacional / super admin. **PRECONDITIONS:** Organização, IDs e motivo; guard de uso no RPC. **INPUTS:** Referências adotadas.

**BEHAVIOR:** Arquiva vínculo; não é exclusão do indicador físico. **OUTPUTS:** Vínculo retirado do catálogo ativo. **STATES:** active → archived.

**DEPENDENCIES:** Adoção organizacional. **IMPLEMENTATION_EVIDENCE:** [ARCHIVE-ORG][R-ARCHIVE-ORG]; [UI-DUAL][R-UI-DUAL]. **DOCUMENTATION_EVIDENCE:** [OPEN][R-OPEN]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-006

**NAME:** Instanciar referência em objetivo estratégico. **PURPOSE:** Criar indicador contextual por adapter. **STATUS:** PARTIAL.

**ACTORS:** Admin organizacional mais permissão de edição da formulação. **PRECONDITIONS:** SK-PE/strategic_objective; formulação editável; referência elegível. **INPUTS:** Referência, objetivo, formulação, adaptações.

**BEHAVIOR:** RPC chama fachada e registra referência; handler existe, mas formulário administration é inalcançável após early return. **OUTPUTS:** Indicador contextual; experiência de UI incompleta. **STATES:** Indicador draft por padrão.

**DEPENDENCIES:** Adapter e early return. **IMPLEMENTATION_EVIDENCE:** [ADOPT-OE][R-ADOPT-OE]; [ADAPTER][R-ADAPTER]; [UI-EARLY][R-UI-EARLY]; [UI-FILTER][R-UI-FILTER]. **DOCUMENTATION_EVIDENCE:** [OPEN][R-OPEN]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-007

**NAME:** Definir indicador estratégico. **PURPOSE:** Manter fórmula descritiva, unidade, periodicidade e baseline. **STATUS:** PARTIAL.

**ACTORS:** Gestor de Formulação. **PRECONDITIONS:** Formulação editável; objetivo ativo no mesmo escopo. **INPUTS:** Código, nome, unidade, polaridade, frequência, baseline/data, owner.

**BEHAVIOR:** Valida e persiste atributos; não executa fórmula textual. **OUTPUTS:** Indicador e auditoria. **STATES:** draft/active/inactive.

**DEPENDENCIES:** Adapter SK-PE. **IMPLEMENTATION_EVIDENCE:** [IND][R-IND]; [ADAPTER][R-ADAPTER]; [FORM-GUARD][R-FORM-GUARD]. **DOCUMENTATION_EVIDENCE:** [FE06][R-FE06]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-008

**NAME:** Arquivar indicador e dependências. **PURPOSE:** Retirar indicador preservando rastreabilidade. **STATUS:** PARTIAL.

**ACTORS:** Gestor de Formulação. **PRECONDITIONS:** strategic_kpi; formulação editável; motivo. **INPUTS:** Indicador.

**BEHAVIOR:** Arquiva indicador e benchmarks; supersede metas não superseded. **OUTPUTS:** Contagens e auditoria. **STATES:** indicador → archived; metas → superseded.

**DEPENDENCIES:** Contrato FE05. **IMPLEMENTATION_EVIDENCE:** [ARCHIVE][R-ARCHIVE]. **DOCUMENTATION_EVIDENCE:** [FE06][R-FE06]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-009

**NAME:** Consultar indicadores pessoais. **PURPOSE:** Mostrar medidas sob responsabilidade do usuário. **STATUS:** IMPLEMENTED.

**ACTORS:** Membro autenticado com acesso SK-PE. **PRECONDITIONS:** Owner pessoal e objetivo ativo no SQL. **INPUTS:** Organização e projeto opcionais conforme assinatura.

**BEHAVIOR:** Consulta indicador não arquivado e meta contextual; filtra all/active/draft/inactive. **OUTPUTS:** Lista pessoal; sem medição. **STATES:** draft/active/inactive.

**DEPENDENCIES:** RPC pessoal. **IMPLEMENTATION_EVIDENCE:** [MY-SQL][R-MY-SQL]; [UI-MY][R-UI-MY]. **DOCUMENTATION_EVIDENCE:** [AUTH][R-AUTH]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-010

**NAME:** Definir metas e tolerâncias. **PURPOSE:** Registrar resultado esperado no horizonte. **STATUS:** PARTIAL.

**ACTORS:** Gestor de Formulação. **PRECONDITIONS:** Indicador e formulação editável. **INPUTS:** Tipo, período, alvo, mínimo/desafio, tolerâncias.

**BEHAVIOR:** Valida horizonte, polaridade e long_term único. **OUTPUTS:** Meta contextual. **STATES:** draft/active na edição.

**DEPENDENCIES:** Metas e guard FE05. **IMPLEMENTATION_EVIDENCE:** [TARGET][R-TARGET]; [ADAPTER][R-ADAPTER]. **DOCUMENTATION_EVIDENCE:** [FE06][R-FE06]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-011

**NAME:** Superseder meta. **PURPOSE:** Preservar meta substituída no histórico. **STATUS:** PARTIAL.

**ACTORS:** Gestor de Formulação. **PRECONDITIONS:** Meta existente; formulação editável; motivo. **INPUTS:** Meta e motivo.

**BEHAVIOR:** Marca superseded; não apaga fisicamente. **OUTPUTS:** Meta histórica. **STATES:** não superseded → superseded.

**DEPENDENCIES:** Metas. **IMPLEMENTATION_EVIDENCE:** [SUPER-TARGET][R-SUPER-TARGET]; [ADAPTER][R-ADAPTER]. **DOCUMENTATION_EVIDENCE:** [FE06][R-FE06]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-012

**NAME:** Manter benchmark do indicador. **PURPOSE:** Associar referência contextual distinta da meta. **STATUS:** CONFLICT.

**ACTORS:** Gestor de Formulação. **PRECONDITIONS:** Indicador, fonte e motivo; guard SQL de escopo. **INPUTS:** Benchmark, origem/período, valor, notas, meta opcional.

**BEHAVIOR:** Upsert via fachada; UI valida campos antes de enviar. **OUTPUTS:** Benchmark em rascunho. **STATES:** draft.

**DEPENDENCIES:** Grid e fachada. **IMPLEMENTATION_EVIDENCE:** [BENCH][R-BENCH]; [UI-BENCH][R-UI-BENCH]; [ADAPTER][R-ADAPTER]. **DOCUMENTATION_EVIDENCE:** [FE06][R-FE06]; [OPEN][R-OPEN]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-013

**NAME:** Verificar/ativar/arquivar benchmark. **PURPOSE:** Governar confiabilidade da referência. **STATUS:** CONFLICT.

**ACTORS:** Validador; gestor conforme ação. **PRECONDITIONS:** Formulação editável e permissão da transição. **INPUTS:** Benchmark, ação, motivo.

**BEHAVIOR:** verify exige draft e período; activate exige verified; outras ações próprias. **OUTPUTS:** Referência e trilha. **STATES:** draft → verified → active; retorno/arquivo.

**DEPENDENCIES:** Benchmark. **IMPLEMENTATION_EVIDENCE:** [BENCH-LIFE][R-BENCH-LIFE]; [UI-BENCH][R-UI-BENCH]. **DOCUMENTATION_EVIDENCE:** [FE06][R-FE06]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-014

**NAME:** Consultar Medidas do contexto. **PURPOSE:** Apresentar indicador, meta, apuração e benchmark. **STATUS:** CONFLICT.

**ACTORS:** Usuário com acesso ao módulo / super admin. **PRECONDITIONS:** Organização, módulo e autorização SQL. **INPUTS:** Projeto, sujeito e contexto opcionais.

**BEHAVIOR:** Seleciona meta contextual, última medição e benchmark; UI distingue ausência e zero. **OUTPUTS:** Grid, totais e filtros por presença. **STATES:** not_assessed ou status de measurement.

**DEPENDENCIES:** Read-model e shell. **IMPLEMENTATION_EVIDENCE:** [READ][R-READ]; [UI][R-UI]; [UI-GRID][R-UI-GRID]; [UI-SHELL][R-UI-SHELL]. **DOCUMENTATION_EVIDENCE:** [OPEN][R-OPEN]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-015

**NAME:** Registrar medição. **PURPOSE:** Capturar apuração histórica e desempenho calculado. **STATUS:** PARTIAL.

**ACTORS:** Gestor de monitoramento. **PRECONDITIONS:** Ciclo gravável; strategic_kpi active no escopo. **INPUTS:** Valor, data, meta opcional, evidência, override e motivo.

**BEHAVIOR:** Insere submitted, calcula desempenho, supersede submitted anterior. **OUTPUTS:** Medição e auditoria. **STATES:** submitted.

**DEPENDENCIES:** Ciclo e cálculo. **IMPLEMENTATION_EVIDENCE:** [RECORD][R-RECORD]; [ADAPTER][R-ADAPTER]. **DOCUMENTATION_EVIDENCE:** [FE09][R-FE09]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-016

**NAME:** Validar, rejeitar e ressubmeter medição. **PURPOSE:** Governar o registro corrente por ciclo. **STATUS:** PARTIAL.

**ACTORS:** Gestor de governança para validate/reject; monitoramento para resubmit. **PRECONDITIONS:** Ciclo gravável; estado permitido. **INPUTS:** Tipo, ID, ação e motivo.

**BEHAVIOR:** Transiciona registro; validação supersede validated anterior. **OUTPUTS:** Status, validated_at/by e histórico. **STATES:** submitted ↔ rejected; submitted → validated.

**DEPENDENCIES:** Registro e autorização. **IMPLEMENTATION_EVIDENCE:** [RECORD-LIFE][R-RECORD-LIFE]. **DOCUMENTATION_EVIDENCE:** [FE09][R-FE09]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-017

**NAME:** Calcular desempenho por polaridade. **PURPOSE:** Comparar apuração com baseline e alvo. **STATUS:** IMPLEMENTED.

**ACTORS:** Serviço SQL no registro. **PRECONDITIONS:** Entradas numéricas suficientes. **INPUTS:** Polaridade, baseline, medido, meta e faixa.

**BEHAVIOR:** Aplica fórmula própria da polaridade; limita e arredonda. **OUTPUTS:** Percentual ou null. **STATES:** Não altera lifecycle.

**DEPENDENCIES:** Cálculo compartilhado. **IMPLEMENTATION_EVIDENCE:** [CALC][R-CALC]; [CALC-DELEGATE][R-CALC-DELEGATE]; [RECORD][R-RECORD]. **DOCUMENTATION_EVIDENCE:** [FE09][R-FE09]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-018

**NAME:** Agregar desempenho do ciclo. **PURPOSE:** Consolidar visão/objetivos/perspectivas. **STATUS:** CONFLICT.

**ACTORS:** Leitor de monitoramento. **PRECONDITIONS:** Ciclo existente; can_view_skpe_monitoring. **INPUTS:** Ciclo e política de peso.

**BEHAVIOR:** Média ponderada dos KPI ativos; submitted prevalece sobre validated. **OUTPUTS:** JSON de desempenho e sinais. **STATES:** Leitura de ciclo, não latest global.

**DEPENDENCIES:** Pacote e medições. **IMPLEMENTATION_EVIDENCE:** [AGGREGATE][R-AGGREGATE]; [SIGNAL][R-SIGNAL]. **DOCUMENTATION_EVIDENCE:** [FE09][R-FE09]; [OPEN][R-OPEN]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-019

**NAME:** Fechar/reabrir ciclo e versionar snapshot. **PURPOSE:** Congelar leitura de governança e preservar versões. **STATUS:** PARTIAL.

**ACTORS:** Ratificador de governança. **PRECONDITIONS:** pending_ratification e readyForClose; reabrir apenas closed. **INPUTS:** Ciclo e motivo.

**BEHAVIOR:** Fecha com snapshot ratified/checksum; reabre e supersede snapshot anterior. **OUTPUTS:** Snapshot versionado e ciclo atualizado. **STATES:** pending_ratification → closed → reopened.

**DEPENDENCIES:** Governança FE08. **IMPLEMENTATION_EVIDENCE:** [CLOSE][R-CLOSE]; [REOPEN][R-REOPEN]; [IMMUTABLE][R-IMMUTABLE]. **DOCUMENTATION_EVIDENCE:** [FE09][R-FE09]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-020

**NAME:** Consultar histórico e auditoria. **PURPOSE:** Rastrear medidas e versões. **STATUS:** PARTIAL.

**ACTORS:** Leitor autorizado do contexto. **PRECONDITIONS:** Permissões de leitura SQL. **INPUTS:** Formulação ou ciclo.

**BEHAVIOR:** Consulta pacote, eventos e lista de snapshots. **OUTPUTS:** Histórico, autor, datas e justificativa. **STATES:** Preserva históricos.

**DEPENDENCIES:** Auditoria operacional. **IMPLEMENTATION_EVIDENCE:** [AUDIT][R-AUDIT]; [HISTORY][R-HISTORY]. **DOCUMENTATION_EVIDENCE:** [FE06][R-FE06]; [FE09][R-FE09]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-021

**NAME:** Configurar e validar pacote de indicadores. **PURPOSE:** Avaliar prontidão metodológica. **STATUS:** PARTIAL.

**ACTORS:** Gestor / validador de Formulação. **PRECONDITIONS:** Formulação draft/in_elaboration; permissões por ação. **INPUTS:** Configuração, submissão, decisão e motivo.

**BEHAVIOR:** Readiness; validação do pacote; alteração posterior invalida aceite técnico. **OUTPUTS:** Pacote, issues e validationStatus em metadata. **STATES:** in_elaboration → pending_validation → validated; retorno.

**DEPENDENCIES:** FE05. **IMPLEMENTATION_EVIDENCE:** [PACKAGE][R-PACKAGE]; [READY][R-READY]; [PACKAGE-LIFE][R-PACKAGE-LIFE]; [INVALIDATE][R-INVALIDATE]. **DOCUMENTATION_EVIDENCE:** [FE06][R-FE06]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-022

**NAME:** Explorar vínculos com objetivo e KR. **PURPOSE:** Situar medidas no desdobramento estratégico. **STATUS:** PARTIAL.

**ACTORS:** Leitor de Formulação. **PRECONDITIONS:** Contexto resolvido; permissões de leitura. **INPUTS:** Formulação, objetivos, KRs.

**BEHAVIOR:** UI lê indicadores/metas/medições; ligação KR física existe, adapter transversal só objetivo. **OUTPUTS:** Desdobramento, contagem de metas, última apuração. **STATES:** Estados lidos sem filtro de medição.

**DEPENDENCIES:** Formulação/OKR. **IMPLEMENTATION_EVIDENCE:** [UI-OKR][R-UI-OKR]; [UI-FORM][R-UI-FORM]; [IND-CONSTRAINT][R-IND-CONSTRAINT]; [ADAPTER][R-ADAPTER]. **DOCUMENTATION_EVIDENCE:** [FE06][R-FE06]; [OPEN][R-OPEN]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-023

**NAME:** Relacionar iniciativa a indicador. **PURPOSE:** Registrar contribuição sem inferir causalidade. **STATUS:** PARTIAL.

**ACTORS:** Gestor de Formulação; leitores autorizados. **PRECONDITIONS:** FKs de organização/projeto/formulação e RLS. **INPUTS:** Iniciativa, indicador, papel, tipo, atribuição.

**BEHAVIOR:** Tabela N:N com unicidade contextual; UI específica não comprovada. **OUTPUTS:** Vínculo governado. **STATES:** draft/pending_validation/validated/rejected no vínculo.

**DEPENDENCIES:** Iniciativas SPARKS. **IMPLEMENTATION_EVIDENCE:** [LINK][R-LINK]. **DOCUMENTATION_EVIDENCE:** [AUTH][R-AUTH]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

#### F-MED-024

**NAME:** Manter benchmark de referência geral. **PURPOSE:** Administrar fonte comparável no catálogo. **STATUS:** IMPLEMENTED.

**ACTORS:** Super admin de plataforma. **PRECONDITIONS:** Referência existente; fonte e justificativa. **INPUTS:** Tipo, fonte/período, população, valor, status.

**BEHAVIOR:** Upsert de benchmark geral; exclusão somente draft não verificado. **OUTPUTS:** Benchmark do catálogo, distinto do organizacional. **STATES:** Status do catálogo; draft excluível sob guards.

**DEPENDENCIES:** Admin de plataforma. **IMPLEMENTATION_EVIDENCE:** [CAT-BENCH][R-CAT-BENCH]; [BENCH-DELETE][R-BENCH-DELETE]; [UI-CAT][R-UI-CAT]. **DOCUMENTATION_EVIDENCE:** [AUTH][R-AUTH]. **TEST_EVIDENCE:** nenhum teste específico localizado; [dívida de cobertura](../business-rules/medidas-desempenho.md#revisão-de-testes).

### Lifecycle resumido

| Entidade | Resumo | Regras detalhadas |
| --- | --- | --- |
| Catálogo e adoção | status e current separados; adoção active/archived | [BR-009](../business-rules/medidas-desempenho.md#br-skpe-med-009), [BR-010](../business-rules/medidas-desempenho.md#br-skpe-med-010) |
| Indicador e Formulação | draft/active/inactive; arquivo por RPC; edição depende da versão | [BR-005](../business-rules/medidas-desempenho.md#br-skpe-med-005), [BR-012](../business-rules/medidas-desempenho.md#br-skpe-med-012) |
| Meta e benchmark | substituição não é exclusão; verificação é diferente de atividade | [BR-015](../business-rules/medidas-desempenho.md#br-skpe-med-015), [BR-016](../business-rules/medidas-desempenho.md#br-skpe-med-016) |
| Pacote e medição | validação do pacote, status do indicador e status da apuração são distintos | [BR-017](../business-rules/medidas-desempenho.md#br-skpe-med-017), [BR-022](../business-rules/medidas-desempenho.md#br-skpe-med-022) |
| Ciclo e snapshot | fechamento/ratificação e reabertura preservam histórico | [BR-035](../business-rules/medidas-desempenho.md#br-skpe-med-035) |

under_review é estado de ciclo, não da constraint de Formulação. proposed/under_analysis pertencem a iniciativas; published não foi localizado como estado das entidades centrais de Medidas. Não importar estados por analogia.

### Conflitos e decisões pendentes

| ID | STATUS | FUNCTIONS | RULES | Impacto documental |
| --- | --- | --- | --- | --- |
| C01 | OPEN_PRODUCT_DECISION | [F-MED-002](#f-med-002); [F-MED-004](#f-med-004); [F-MED-005](#f-med-005); [F-MED-006](#f-med-006); [F-MED-007](#f-med-007); [F-MED-012](#f-med-012); [F-MED-013](#f-med-013); [F-MED-024](#f-med-024) | [BR-SKPE-MED-038](../business-rules/medidas-desempenho.md#br-skpe-med-038); [BR-SKPE-MED-042](../business-rules/medidas-desempenho.md#br-skpe-med-042) | Disponibilidade técnica não comprova aprovação de adoção; handler contextual não prova UI alcançável. |
| C02 | OPEN_PRODUCT_DECISION | [F-MED-004](#f-med-004); [F-MED-005](#f-med-005); [F-MED-006](#f-med-006); [F-MED-009](#f-med-009); [F-MED-014](#f-med-014); [F-MED-022](#f-med-022) | [BR-SKPE-MED-019](../business-rules/medidas-desempenho.md#br-skpe-med-019); [BR-SKPE-MED-020](../business-rules/medidas-desempenho.md#br-skpe-med-020); [BR-SKPE-MED-039](../business-rules/medidas-desempenho.md#br-skpe-med-039); [BR-SKPE-MED-042](../business-rules/medidas-desempenho.md#br-skpe-med-042) | Seletores e lifecycle não são equivalentes; decisão de contexto permanece pendente. |
| C04 | OPEN_PRODUCT_DECISION | [F-MED-009](#f-med-009); [F-MED-014](#f-med-014); [F-MED-015](#f-med-015); [F-MED-016](#f-med-016); [F-MED-017](#f-med-017); [F-MED-018](#f-med-018); [F-MED-019](#f-med-019); [F-MED-022](#f-med-022) | [BR-SKPE-MED-020](../business-rules/medidas-desempenho.md#br-skpe-med-020); [BR-SKPE-MED-021](../business-rules/medidas-desempenho.md#br-skpe-med-021); [BR-SKPE-MED-024](../business-rules/medidas-desempenho.md#br-skpe-med-024); [BR-SKPE-MED-031](../business-rules/medidas-desempenho.md#br-skpe-med-031); [BR-SKPE-MED-033](../business-rules/medidas-desempenho.md#br-skpe-med-033); [BR-SKPE-MED-040](../business-rules/medidas-desempenho.md#br-skpe-med-040) | Leitura latest/preparatória não prova desempenho oficial; decisão de semântica e período permanece pendente. |

### Observabilidade e retomada

Known unknowns: aplicação das migrations, RLS efetiva, dados publicados, fluxos autenticados, aceite visual e testes externos. A ausência de testes específicos é dívida explícita no owner de regras; testes gerais da baseline não substituem cobertura por regra.

O retorno antecipado de administration mantém o selector organizacional alcançável e o formulário antigo de adoção contextual inalcançável nesse render. O contrato SQL continua disponível. Esta precisão permanece vinculada a F-MED-006 e BR-SKPE-MED-042, sem resolver C01/C02. A agregação por ciclo e o snapshot mantêm contratos separados; C04 não é decidido.

Próximo passo: revisar o modelo documental antes de replicação. Resolver C01/C02/C04 somente quando Medidas for retomada, com decisão Product e gate de verificação apropriado. A baseline inteira continua válida; esta wave não autoriza implementação nem merge automático.

[R-ADAPTER]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904234019_establish_transversal_measures_performance_write_facade.sql#L1
[R-ADOPT-OE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908135440_govern_measure_reference_catalog_adoption.sql#L114
[R-ADOPT-ORG]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909214455_govern_organization_measure_reference_adoption.sql#L118
[R-AGGREGATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L3182
[R-ARCHIVE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L746
[R-ARCHIVE-ORG]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909214455_govern_organization_measure_reference_adoption.sql#L208
[R-AUDIT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L2716
[R-AUTH]: https://github.com/br-robson/projetos/blob/30c59b472bdf0b3d0aaab9e0b0246d0f814ed875/docs/products/sk-pe/capabilities/SKPE-MED-DES-01-medidas-desempenho.md#L105
[R-BENCH]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L1145
[R-BENCH-DELETE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908220330_govern_platform_measure_reference_deletion.sql#L107
[R-BENCH-LIFE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L1332
[R-CALC]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730080000_create_okrs_key_results_and_strategic_deployment_operations.sql#L346
[R-CALC-DELEGATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L928
[R-CAT-BENCH]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908170508_govern_platform_measure_reference_catalog.sql#L327
[R-CAT-DELETE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908220330_govern_platform_measure_reference_deletion.sql#L1
[R-CAT-ELIGIBLE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908135440_govern_measure_reference_catalog_adoption.sql#L101
[R-CAT-LIFE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908170508_govern_platform_measure_reference_catalog.sql#L232
[R-CAT-READ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908170508_govern_platform_measure_reference_catalog.sql#L1
[R-CAT-WRITE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908170508_govern_platform_measure_reference_catalog.sql#L105
[R-CLOSE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L3584
[R-DEL-PRIV]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908220402_harden_platform_measure_reference_deletion_privileges.sql#L1
[R-FE06]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-006_INDICADORES_METAS_LONGO_PRAZO_BENCHMARKING.md#L1
[R-FE09]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-009_MONITORAMENTO_GOVERNANCA_APRENDIZADO_ESTRATEGICO.md#L1
[R-FORM-GUARD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L107
[R-HISTORY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L3736
[R-IMMUTABLE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L974
[R-IND]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L479
[R-IND-CONSTRAINT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L1455
[R-INVALIDATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L300
[R-LINK]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904213836_govern_sparks_initiative_indicator_links.sql#L1
[R-MY-SQL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260807013000_create_my_skpe_indicators.sql#L8
[R-OPEN]: https://github.com/br-robson/projetos/blob/30c59b472bdf0b3d0aaab9e0b0246d0f814ed875/docs/products/sk-pe/current-state.md#L409
[R-ORG-READ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909234252_reconcile_organization_specific_measure_indicators.sql#L25
[R-PACKAGE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L378
[R-PACKAGE-LIFE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L2353
[R-READ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908015851_govern_transversal_measure_performance_context_read.sql#L1
[R-READY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L1496
[R-RECORD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L1494
[R-RECORD-LIFE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L2525
[R-REOPEN]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L3689
[R-SIGNAL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L952
[R-SUPER-TARGET]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L1085
[R-TARGET]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L835
[R-UI]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/MeasuresPerformanceWorkspace.tsx#L145
[R-UI-BENCH]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/OrganizationIndicatorsSmartGrid.tsx#L232
[R-UI-CAT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/platform-admin/PlatformMeasureCatalog.tsx#L922
[R-UI-DUAL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/SparksMeasureDualSelector.tsx#L249
[R-UI-EARLY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/MeasuresPerformanceWorkspace.tsx#L428
[R-UI-FILTER]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/MeasuresPerformanceWorkspace.tsx#L204
[R-UI-FORM]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicFormulationSection.tsx#L140
[R-UI-GRID]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/measures/OrganizationIndicatorsSmartGrid.tsx#L87
[R-UI-MY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/workspace/MyIndicatorsPanel.tsx#L135
[R-UI-OKR]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicOkrDecompositionSection.tsx#L290
[R-UI-SHELL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/SkpeCockpit.tsx#L8863
