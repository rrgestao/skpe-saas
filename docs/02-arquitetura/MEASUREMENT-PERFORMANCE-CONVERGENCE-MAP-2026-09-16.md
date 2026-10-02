---
id: MEASUREMENT-PERFORMANCE-CONVERGENCE-MAP-2026-09-16
title: Mapa de Convergência — Medidas e Desempenho
status: discovery-complete-for-current-gate
owner: product-platform
language: pt-BR
updated: 2026-09-16
---

# Mapa de Convergência — Medidas e Desempenho

## Objetivo

Este documento classifica o que já é transversal no runtime, o que é transversal apenas por adapter sobre SK-PE e o que ainda é autoridade física/funcional exclusiva do SK-PE.

A regra do gate permanece: nenhuma migration estrutural, rename de tabela ou importação do catálogo KPI/BMK está autorizada nesta etapa.

## Classificação arquitetural

| Domínio | Estado atual | Autoridade física atual | Interface transversal | Classificação |
| --- | --- | --- | --- | --- |
| Catálogo de definições de KPI | Versionado e vigente | `skpe_indicator_reference_catalog` | `sparks_measure_reference_catalog` + RPCs de catálogo | TRANSVERSAL_FACADE_OVER_SKPE_STORAGE |
| Benchmark de referência do catálogo | Versionado por referência | `skpe_indicator_reference_benchmarks` | `sparks_measure_reference_benchmarks` | TRANSVERSAL_FACADE_OVER_SKPE_STORAGE |
| Adoção no nível da organização | Persistência própria transversal | `sparks_measure_organization_indicators` | RPCs de adoção/retirada/consulta | TRANSVERSAL_PHYSICAL |
| Indicador contextual | Persistência SK-PE | `skpe_indicators` | `sparks_measure_indicators` + write facade | TRANSVERSAL_ADAPTER_OVER_SKPE |
| Meta contextual | Persistência SK-PE | `skpe_indicator_targets` | `sparks_measure_targets` + write facade | TRANSVERSAL_ADAPTER_OVER_SKPE |
| Benchmark operacional/contextual | Persistência SK-PE | `skpe_benchmark_references` | `sparks_measure_benchmarks` + write facade | TRANSVERSAL_ADAPTER_OVER_SKPE |
| Medição | Persistência SK-PE | `skpe_indicator_measurements` | `sparks_measure_measurements` + `sparks_record_measurement` | TRANSVERSAL_ADAPTER_OVER_SKPE |
| Snapshot de desempenho | Persistência SK-PE | `skpe_performance_snapshots` | `sparks_performance_snapshots` | TRANSVERSAL_READ_FACADE_ONLY |
## Contratos ainda SK-PE puros

Permanecem semanticamente e fisicamente acoplados ao SK-PE neste gate:

- `skpe_monitoring_cycles` e lifecycle do ciclo;
- `skpe_monitoring_packages` e thresholds;
- `skpe_calculate_strategic_performance` / `skpe_calculate_key_result_progress`;
- `get_skpe_strategic_performance`;
- readiness de monitoramento;
- check-ins de KR e Iniciativa;
- RAE, decisões e aprendizado;
- ratificação, fechamento, reabertura e supersessão de snapshots.

Esses contratos não devem ser movidos mecanicamente para um namespace SPARKS. Primeiro devem ser separados entre: motor genérico de Medidas/Desempenho e especialização estratégica do SK-PE.

## Adoção organizacional versus binding contextual

A tabela `sparks_measure_organization_indicators` já materializa a decisão organizacional de adotar uma referência do Catálogo GERAL. Ela suporta overrides, owner, fonte, notas de adaptação e também um `legacy_indicator_id` para reconciliação.

Isso não equivale ao binding contextual final. Hoje o vínculo com objetivo/KR/formulação continua materializado em `skpe_indicators`.

Contrato alvo:

`MetricDefinition -> OrganizationalAdoption -> MetricBinding -> Target -> Measurement -> PerformanceAssessment`

A adoção organizacional deve sobreviver à troca de consumidor/módulo. O binding é o elo contextual que liga a métrica adotada a OE, KR, processo, projeto, iniciativa, risco, controle, produto, unidade, contrato/SLA ou outro sujeito governado.
## Semântica de desempenho observada

O runtime atual calcula `automatic_performance` no registro da medição, ainda em estado `submitted`, usando polaridade, baseline, valor medido, meta e faixa/tolerância aplicável.

`manual_performance_override` só é aceito quando permitido pelo pacote de monitoramento. `effective_performance` usa o override quando presente; caso contrário usa o cálculo automático, limitado a 0–100.

A função de agregação estratégica atual usa medições `submitted` ou `validated`. Quando coexistem para o mesmo ciclo/indicador, uma `submitted` nova prevalece na agregação preparatória sobre o `validated` anterior.

Portanto, ficam distinguidos três níveis:

1. `working_performance`: leitura operacional em elaboração durante o ciclo; pode usar `submitted`.
2. `validated_performance`: performance derivada de medição validada no escopo governado.
3. `ratified_snapshot_performance`: fotografia histórica ratificada e imutável/supersedível por governança.

Não deve existir uma única coluna ou regra chamada genericamente de "performance oficial" sem qualificar qual desses níveis está sendo usado.

## Agregação atual e evolução necessária

O `get_skpe_strategic_performance` já evita média puramente ingênua quando `aggregation_policy='explicit_weight'`, usando `indicator.metadata.monitoringWeight`; caso contrário aplica peso 1.

Ele agrega Indicador -> Objetivo -> Tema -> Visão e converte o valor agregado em status por thresholds do pacote.

A capability transversal futura deve generalizar a mecânica, não copiar a hierarquia estratégica. O motor genérico deve receber: conjunto elegível, regra de peso, cobertura, política de missing, blockers/mandatory metrics, algoritmo e versão. O SK-PE continuará definindo a hierarquia OE/Tema/Visão que consome esse motor.
## Riscos e pendências objetivas

### R1 — adoção contextual ainda não comprovada em runtime

`adopt_sparks_measure_reference_indicator` está implantada e consumida pelo frontend, mas a busca versionada não localizou teste específico dessa RPC. O banco também não possui hoje indicador contextual com `reference_catalog_id` preenchido.

A função materializa primeiro em `skpe_indicators` e depois sincroniza `sparks_measure_indicators`, que no runtime continua sendo uma view. O caminho deve ser validado em gate técnico específico antes de ser usado para carga em escala.

`STATUS=IMPLEMENTED_NOT_RUNTIME_PROVEN`

### R2 — latest contextual não é performance oficial

`get_sparks_measure_performance_context` escolhe a medição mais recente por `measurement_date`/`created_at`, sem restringir status, supersessão ou ciclo. É adequado como leitura informativa, mas não como regra universal de oficialidade.

`STATUS=READ_MODEL_CONFLICT_OPEN`

### R3 — catálogo e benchmark ainda carregam namespace físico SK-PE

As views transversais já escondem o namespace do consumidor, mas o storage segue `skpe_*`. Isso é dívida de convergência, não defeito funcional que autorize rename imediato.

`STATUS=STORAGE_CONVERGENCE_DEFERRED`

## Próximo desenho de persistência — ainda não autorizado

Quando houver gate de migration, a primeira evolução deve priorizar entidades ausentes em vez de renomear tabelas existentes: `MetricBinding`, `BenchmarkComparabilityAssessment` e `PerformanceRule/PerformanceAssessment` versionáveis.

A eventual convergência física de catálogo, meta, medição e snapshot deve ser posterior e compatível com IDs/histórico existentes.

`STRUCTURAL_MIGRATION_AUTHORIZED=NO`
`CATALOG_IMPORT_AUTHORIZED=NO`
`NEXT_GATE=CONCEPTUAL_SCHEMA_AND_MIGRATION_PROPOSAL`
