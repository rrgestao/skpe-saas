---
id: skpe-reconciliation-2026-09-16-measurement-performance
title: Reconciliação 2026-09-16 — Medidas e Desempenho
status: active
owner: product-platform
language: pt-BR
---

# Reconciliação 2026-09-16 — Medidas e Desempenho

## Autoridade da decisão

Em 16/09/2026 foi aprovada a promoção de Medidas e Desempenho para capability transversal da Plataforma SPARKs.

Esta decisão supersede, para este tema, a condição documental anterior `TRANSVERSAL_REUSE=INTENDED`. A nova direção de produto é `TRANSVERSAL_PLATFORM_DIRECTION=APPROVED`.

`SKPE-MED-DES-01` permanece como origem, histórico e especialização do SK-PE; o ownership técnico alvo passa a ser transversal à Plataforma.

## Estratégia de transição

`Facade -> Convergence -> eventual Storage Evolution`.

Não renomear nem eliminar tabelas `skpe_*` no estágio atual. Não criar identidade paralela para conceitos já existentes. Fachadas `sparks_measure_*` e contratos atuais são ponte de compatibilidade, não justificativa para duplicar storage.

## Estado real do catálogo

A leitura do runtime `skpe-saas-dev` em 16/09/2026 confirmou:

- `skpe_indicator_reference_catalog`: 60 linhas;
- 46 `catalog_code` distintos;
- 46 linhas `is_current=true`;
- 14 linhas são versões históricas anteriores.

O pacote `SPARKs_PE_Base_KPIs_BMK_Ramos_v1_0` contém 78 candidatos. Logo, a reconciliação correta é `46 identidades vigentes x 78 candidatos`, preservando integralmente as 60 linhas/versionamentos já existentes.

O total canônico final é desconhecido até a classificação semântica. Não somar 46 + 78 nem substituir o catálogo vigente pelo pacote.

## Regra de merge

Para cada candidato, comparar conceito, finalidade, fórmula, unidade, polaridade, periodicidade e contexto de aplicação.

Quando o candidato corresponder a uma identidade vigente, preservar o ID existente. O `kpi_id` do pacote permanece como referência de origem/alias. Se a nova definição alterar metodologia materialmente, avaliar nova versão do KPI existente em vez de sobrescrever histórico.

Classificações permitidas:

- `SAME`
- `ALIAS`
- `SPECIALIZATION`
- `DERIVED`
- `DIFFERENT_FORMULA`
- `CONTEXTUAL_VARIANT`
- `TRUE_DUPLICATE`
- `NEEDS_HUMAN_DECISION`

## Benchmark e desempenho

`Benchmark Comparability Assessment` passa a ser conceito aprovado. Benchmark não é meta e sua utilização exige compatibilidade metodológica e contextual explícita.

Performance evoluirá para `Performance Rule` e `Performance Assessment` versionáveis, preservando o cálculo atual durante a transição.

## Baseline funcional preservado

Os avanços de 12/09/2026 em Medidas e Monitoramento são parte do Current Truth a preservar: read-model contextual, autorização, evidência, performance automática/manual/efetiva, ciclo real, coleta/validação de KPI, check-ins de KR e Iniciativa, RAE, decisões, aprendizado, ratificação, fechamento, snapshot e reabertura governada.

Check-in de KR/Iniciativa é estado gerencial contextual e não deve ser convertido automaticamente em medição formal de KPI.

## Autoridade operacional do repositório

A partir da decisão de 16/09/2026:

- desenvolvimento ativo: worktree local autorizado;
- remoto principal: `rrgestao/skpe-saas`;
- remoto secundário de comparação/reconciliação: `sparkooptech/skpe-saas`;
- avanços legítimos mais maduros encontrados no remoto secundário devem ser reconciliados, não descartados;
- documentos anteriores que tratem `sparkooptech/skpe-saas` como autoridade remota única passam a ser históricos onde conflitarem com esta decisão.

O período crítico de confusão de remotos/branches foi 11–13/09/2026 e deve ser tratado como janela especial de reconciliação.

## Próximo gate

`NEXT_GATE=KPI_CATALOG_SEMANTIC_RECONCILIATION`

`DATABASE_MIGRATION_EXECUTED=NO`

`CATALOG_IMPORT_EXECUTED=NO`

`LEGACY_IDS_PRESERVED=YES`

## Primeira matriz semântica — sobreposições com o catálogo vigente

| Candidato v1.0 | Catálogo vigente | Classificação preliminar | Justificativa |
| --- | --- | --- | --- |
| KPI-CONSUMO-002 — Margem bruta | FIN-MB-01 — Margem bruta | SAME | Conceito e fórmula equivalentes; preservar ID vigente e tratar o ID v1.0 como referência/alias de origem. |
| KPI-BAS-01 — Margem de contribuição por solução | FIN-MC-01 — Margem de contribuição | SPECIALIZATION | Mesma família, mas o candidato restringe o escopo à solução e usa custos variáveis diretos; não colapsar sem decisão metodológica. |
| KPI-BAS-02 — Margem operacional / sobras sobre ingressos | FIN-MO-01 — Margem operacional | CONTEXTUAL_VARIANT | Variante cooperativista/contábil com ingressos/sobras; fórmula e semântica precisam ser reconciliadas. |
| KPI-BAS-04 — Concentração de receita Top 1/Top 5 | FIN-CONC-CLI-01 e FIN-CONC-PROJ-01 | NEEDS_HUMAN_DECISION | Candidato generaliza Top N e diferentes sujeitos; atuais preservam cliente e projeto separadamente. |
| KPI-CREDITO-001 — Inadimplência 90+ dias | FIN-DEL-01 — Taxa de inadimplência | SPECIALIZATION | Aging 90+ e denominador de carteira tornam o indicador uma especialização material. |
| KPI-CREDITO-003 — ROA/ROE | FIN-ROA-01 e FIN-ROE-01 | NEEDS_HUMAN_DECISION | O candidato combina dois KPIs canônicos distintos; não criar KPI composto automaticamente. |
| KPI-TRV-006 — NPS/CSAT/satisfação | CLI-NPS-01 e CLI-SAT-01 | NEEDS_HUMAN_DECISION | Agrupa métodos diferentes já modelados como KPIs distintos. |
| KPI-TRV-012 — Turnover voluntário | PES-TURN-01 — Taxa de rotatividade | SPECIALIZATION | Turnover voluntário é subconjunto do turnover total e requer regra própria de eventos incluídos. |
| KPI-CONSUMO-003 — Giro de estoque | FIN-PME-01 — Prazo médio de estocagem | DERIVED | Medidas relacionadas matematicamente, mas não equivalentes; preservar ambas quando pertinentes. |
| KPI-TPBS-002 — Margem por contrato/serviço | FIN-MARG-PROJ-01 — Margem por projeto | CONTEXTUAL_VARIANT | Sujeito e definição de contribuição/custo diferem; não tratar como alias direto. |

## Primeira matriz semântica — sobreposições internas do pacote v1.0

| Candidatos | Classificação preliminar | Tratamento recomendado |
| --- | --- | --- |
| KPI-BAS-03 / KPI-TRV-002 — FCO sobre receita | ALIAS | Preferir a definição completa BAS-03 como candidata; preservar TRV-002 como alias/origem até homologação. |
| KPI-BAS-06 / KPI-TRV-005 — churn/retenção | NEEDS_HUMAN_DECISION | Churn e retenção são relacionados/inversos sob certas definições, mas não devem ser fundidos sem fórmula explícita. |
| KPI-BAS-07 / KPI-TRV-007 — adoção/uso | SPECIALIZATION | BAS-07 mede benefícios; TRV-007 é mais amplo para produtos e benefícios. |
| KPI-BAS-08 / KPI-TRV-008 — reclamações normalizadas | SPECIALIZATION | BAS-08 fixa base por mil cooperados; TRV-008 ainda não define denominador. |
| KPI-BAS-11 / KPI-TRV-011 — disponibilidade/SLA | SPECIALIZATION | BAS-11 trata canais críticos; TRV-011 é conceito mais amplo e ainda incompleto. |
| KPI-BAS-20 / KPI-TRV-015 — tempo de remediação | ALIAS | Mesmo conceito aparente; BAS-20 possui fórmula e unidade completas. |
| KPI-BAS-22 / KPI-TRV-016 — atingimento KR/FCS | ALIAS | Mesmo conceito aparente; BAS-22 possui fórmula, unidade, polaridade e periodicidade. |
| KPI-TRV-001 / KPI-CONSUMO-001 | SPECIALIZATION | Crescimento de mesmas lojas/canais é especialização de crescimento de receita. |
| KPI-TRV-008 / KPI-SAUDE-003 | SPECIALIZATION | Reclamações em saúde exigem população/regra regulatória próprias. |
| KPI-TRV-011 / KPI-INFRA-005 / KPI-TPBS-004 / KPI-TRANSPORTE-004 | SPECIALIZATION | Disponibilidade/SLA possui especializações por infraestrutura, entrega e frota; não colapsar fórmulas específicas. |

Esta matriz é preliminar e conservadora. `SAME` poderá ser consolidado mantendo a identidade vigente; as demais classes exigem modelagem/curadoria antes de qualquer carga.

## Reconciliação dos remotos críticos — 2026-09-16

Foi feita conferência read-only dos dois remotos autorizados para os branches de 12/09 diretamente ligados a Medidas e Monitoramento.

| Branch crítico | rrgestao/skpe-saas | sparkooptech/skpe-saas | Local remote refs | Resultado |
| --- | --- | --- | --- | --- |
| `sprint/2026-09-12-medidas-desempenho` | `429aa03b2a96aac59b487329c60349ebf4ec0f26` | `429aa03b2a96aac59b487329c60349ebf4ec0f26` | ambos no mesmo SHA | ALIGNED |
| `sprint/2026-09-12-monitoramento-desempenho` | `eedf3ceb237f7c9ee3d49f7a84f96aefce535c6b` | `eedf3ceb237f7c9ee3d49f7a84f96aefce535c6b` | ambos no mesmo SHA | ALIGNED |

O SHA correto do fechamento do ciclo de monitoramento é `eedf3ceb237f7c9ee3d49f7a84f96aefce535c6b`; qualquer registro anterior sem o prefixo `eed` deve ser tratado como erro de transcrição, não como commit distinto.

`CRITICAL_MEASURES_BRANCH_REMOTE_DIVERGENCE=NO`

`CRITICAL_MONITORING_BRANCH_REMOTE_DIVERGENCE=NO`

Essa conclusão é limitada aos dois branches críticos acima. Não implica equivalência global entre todos os branches, `main`, worktrees ou alterações locais posteriores.
## Gate de decisão após Discovery e schema conceitual

A direção transversal já está aprovada em Product. Permanecem decisões de implementação que não devem ser inferidas.

1. `MetricBinding`: candidato para primeira entidade nova transversal, preservando adoção organizacional e bindings SK-PE existentes durante transição.
2. `BenchmarkComparabilityAssessment`: candidato para primeira entidade nova transversal, sem transformar referência em meta ou observação qualificada por default.
3. `PerformanceRule/PerformanceAssessment`: conceito aprovado no desenho, mas a entrada já em M1 ou postergação para gate posterior ainda requer decisão.
4. Oficialidade de desempenho: cada consumidor deve declarar se lê `working_performance`, `validated_performance` ou `ratified_snapshot_performance`.
5. Catálogo v1.0: aliases, compostos e casos `NEEDS_HUMAN_DECISION` precisam de curadoria antes de carga.
6. Benchmark v1.0: registros sem período/valor qualificado ou marcados `A PESQUISAR` não podem ser carregados como observações comparáveis.

Recomendação técnica para o próximo incremento: preparar **migration proposal M1** somente para `MetricBinding` e `BenchmarkComparabilityAssessment`, acompanhada de contratos de compatibilidade e testes, mas não aplicar no banco até gate explícito.

`DISCOVERY_GATE=COMPLETE_FOR_CURRENT_SCOPE`
`CONCEPTUAL_SCHEMA=READY_FOR_PRODUCT_REVIEW`
`M1_MIGRATION_PROPOSAL=RECOMMENDED_NOT_AUTHORIZED`
`DATABASE_CHANGE=NO`
`CATALOG_LOAD=NO`

# DECISION NEEDED — TRANSVERSAL MEASUREMENT & PERFORMANCE FOUNDATION

## M1 Migration Proposal — autorizado e preparado

Em 2026-09-16 Product autorizou a preparacao, sem aplicacao, da migration M1 da Fundacao Transversal.

Artefatos preparados:

- `supabase/migrations/20260916130226_establish_transversal_measure_binding_and_benchmark_comparability_m1.sql`;
- `supabase/tests/transversal_measure_binding_benchmark_comparability_m1_test.sql`;
- `docs/02-arquitetura/MEASUREMENT-PERFORMANCE-M1-MIGRATION-PROPOSAL-2026-09-16.md`.

Escopo fisico proposto: `sparks_measure_bindings` e `sparks_benchmark_comparability_assessments`.

`SKPE_MUTATION_COUNT=0` na migration proposta.

`CREATE_TABLE_COUNT=2`; `RLS_ENABLE_COUNT=2`; `DIFF_CHECK=PASS`.

A migration nao foi executada em banco local, branch Supabase ou projeto live. O teste SQL foi preparado para o gate posterior a uma eventual aplicacao autorizada em desenvolvimento.

`M1_APPLIED_TO_DATABASE=NO`

`NEXT_GATE=M1_REVIEW_AND_DEV_APPLICATION_DECISION`