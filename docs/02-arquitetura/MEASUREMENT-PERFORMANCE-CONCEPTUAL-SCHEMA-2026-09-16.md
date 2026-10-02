---
id: MEASUREMENT-PERFORMANCE-CONCEPTUAL-SCHEMA-2026-09-16
title: Schema Conceitual — Fundação Transversal de Medidas e Desempenho
status: proposal
owner: product-platform
language: pt-BR
updated: 2026-09-16
---

# Schema Conceitual — Fundação Transversal de Medidas e Desempenho

## Princípio

O schema alvo deve evoluir por adição e compatibilidade, não por substituição imediata do legado. IDs, histórico, snapshots e contratos SK-PE permanecem válidos até migration própria, testada e aprovada.

## Entidades conceituais

| Entidade | Papel | Estado atual | Evolução proposta |
| --- | --- | --- | --- |
| MetricDefinition | definição reutilizável de KPI/métrica | `skpe_indicator_reference_catalog` | manter identidade/versionamento; namespace físico pode convergir depois |
| MetricReferenceBenchmark | referência reutilizável de benchmark | `skpe_indicator_reference_benchmarks` | separar referência de observação/comparabilidade |
| OrganizationalMetricAdoption | adoção de definição pela organização | `sparks_measure_organization_indicators` | já transversal; fortalecer governança de overrides/versionamento |
| MetricBinding | vínculo da métrica adotada com sujeito/contexto | embutido em `skpe_indicators` | NOVA entidade transversal candidata |
| Target | compromisso contextual e temporal | `skpe_indicator_targets` | preservar; futuramente desacoplar de formulação SK-PE |
| Measurement | observação histórica | `skpe_indicator_measurements` | preservar série e supersessão; futuramente desacoplar ciclo SK-PE |
| BenchmarkComparabilityAssessment | avaliação explícita de comparabilidade | inexistente como entidade | NOVA entidade transversal candidata |
| PerformanceRule | regra/versionamento de cálculo | implícita em função + polaridade | NOVA entidade conceitual candidata |
| PerformanceAssessment | resultado calculado/validado de desempenho | campos na medição + agregações | NOVA entidade conceitual candidata |
| PerformanceSnapshot | fotografia governada | `skpe_performance_snapshots` | preservar; futura generalização após estabilização |
## Contrato conceitual de MetricBinding

`MetricBinding` deve referenciar a adoção organizacional, não clonar a definição global.

Campos conceituais mínimos: `id`, `organization_metric_adoption_id`, `organization_id`, `source_module_code`, `context_type`, `context_id`, `subject_type`, `subject_id`, `binding_role`, `status`, `effective_from`, `effective_to`, `owner_user_id`, `metadata`, auditoria e versionamento/supersessão quando aplicável.

Tipos de sujeito devem ser extensíveis por contrato governado, sem FK polimórfica improvisada. Exemplos futuros: `strategic_objective`, `key_result`, `initiative`, `process`, `project`, `risk`, `control`, `contract`, `sla`, `product`, `organizational_unit`, `esg_topic`, `regulatory_requirement`.

No SK-PE, o primeiro adapter deverá mapear `strategic_objective` e `key_result` preservando os IDs atuais de `skpe_indicators` enquanto a convergência física não ocorrer.

## Contrato conceitual de BenchmarkComparabilityAssessment

Campos mínimos: `id`, `organization_id`, `metric_definition_id` ou `metric_binding_id`, `benchmark_reference_id/observation_id`, `assessment_status`, `formula_compatible`, `unit_compatible`, `period_compatible`, `population_compatible`, `size_compatible`, `segment_compatible`, `geography_compatible`, `methodology_compatible`, `assessment_notes`, `assessed_at`, `assessed_by`, `metadata`.

Enum canônico proposto: `DIRECTLY_COMPARABLE`, `COMPARABLE_WITH_CAVEATS`, `ADJACENT_REFERENCE`, `CONTEXT_ONLY`, `NOT_COMPARABLE`, `NOT_ASSESSED`.

A avaliação não cria meta e não altera a definição do KPI.

## Contrato conceitual de PerformanceRule / PerformanceAssessment

`PerformanceRule` deve versionar regra de cálculo, polaridade, ranges, normalização, caps, rounding, thresholds e política de missing quando a regra deixar de ser trivial.

`PerformanceAssessment` deve registrar qual regra/versão foi aplicada, sobre qual medição/meta, resultado bruto, resultado normalizado, status, nível de oficialidade (`working`, `validated`, `ratified_snapshot`), explicação e timestamps.

Durante a transição, `automatic_performance`, `manual_performance_override` e `effective_performance` permanecem válidos e não são removidos.
## Proposta de evolução por fases — sem DDL neste gate

### Fase M1 — adicionar sem mover

Adicionar apenas entidades hoje ausentes e necessárias à transversalização: `MetricBinding` e `BenchmarkComparabilityAssessment`. Considerar `PerformanceRule/PerformanceAssessment` apenas após fechar a semântica de oficialidade e agregação.

Nenhuma tabela `skpe_*` seria renomeada ou removida em M1.

### Fase M2 — adapters bidirecionais e shadow validation

Fazer novos bindings coexistirem com `skpe_indicators`, usando adapter explícito e testes de equivalência. Leituras transversais devem comparar saída nova e legado antes de qualquer mudança de autoridade.

### Fase M3 — autoridade transversal por conceito

Somente após equivalência comprovada, decidir individualmente se Target, Measurement, Benchmark operacional e Snapshot migram para storage transversal. Cada conceito terá gate próprio; não haverá migração monolítica.

### Fase M4 — deprecação controlada

Depois de consumidores, RLS, auditoria, histórico, performance e snapshots funcionarem sobre autoridade transversal, congelar escrita no contrato físico legado e manter leitura/compatibilidade pelo período definido.

## Não regressão obrigatória

A evolução deve preservar, no mínimo: ausência de medição != zero; `submitted` != `validated`; supersessão sem apagar histórico; override auditável; target != benchmark; cálculo por polaridade; working performance separada de performance ratificada; check-ins de KR/Iniciativa; readiness; RAE; decisão/aprendizado; snapshot imutável e reabertura com supersessão.

Também deve preservar o encadeamento metodológico do SK-PE: `OE -> KPI -> Meta SMART -> KR/FCS -> Iniciativa -> Medição -> Desempenho -> Governança/Monitoramento`.

`MIGRATION_SQL_CREATED=NO`
`DATABASE_CHANGED=NO`
`CONCEPTUAL_SCHEMA_READY_FOR_REVIEW=YES`
