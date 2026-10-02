---
id: SPARKS-MEAS-PERF-M1-PROPOSAL
title: M1 Migration Proposal - Metric Binding e Benchmark Comparability
status: proposed
owner: product-platform
date: 2026-09-16
language: pt-BR
---

# M1 Migration Proposal

Esta proposta materializa o primeiro incremento estrutural autorizado pelo `ADR-PLAT-MEAS-001` sem executar DDL no banco live.

## Escopo

M1 introduz somente:

1. `sparks_measure_bindings` - separa adocao organizacional de binding contextual;
2. `sparks_benchmark_comparability_assessments` - governa se uma referencia pode ser comparada naquele contexto.

M1 preserva integralmente:

- `skpe_indicators`;
- `skpe_indicator_targets`;
- `skpe_indicator_measurements`;
- `skpe_benchmark_references`;
- `skpe_performance_snapshots`;
- `automatic_performance`, `manual_performance_override` e `effective_performance`;
- ciclos, readiness, RAE, check-ins e snapshots ratificados.
## Contrato de Metric Binding

Um binding liga um Indicador ja adotado pela Organizacao a um sujeito de negocio dentro de um contexto.

`OrganizationMetricAdoption != MetricBinding`.

O mesmo KPI adotado pode, no futuro, ser vinculado a mais de um sujeito sem duplicar a definicao global.

Adapter M1 autorizado:

- modulo: `SK-PE`;
- contexto: `strategic_formulation`;
- sujeitos: `strategic_objective`, `key_result` e `initiative`;
- tipos de vinculo: `measures`, `supports`, `diagnoses`, `guards`.

Outros modulos e sujeitos falham fechados com `0A000` ate existir adapter governado.

## Contrato de Comparabilidade

Avaliacao de comparabilidade possui as classes:

- `directly_comparable`;
- `comparable_with_caveats`;
- `adjacent_reference`;
- `context_only`;
- `not_comparable`;
- `not_assessed`.

A decisao considera formula, unidade, periodo, populacao e contexto de comparacao.
Origens de benchmark aceitas em M1:

- `reference_catalog` - referencia reutilizavel do catalogo global;
- `contextual` - referencia contextual atualmente exposta pela fachada transversal.

A origem e representada por `benchmark_origin_type + benchmark_reference_id`, evitando nova FK fisica para tabelas `skpe_*`.

Uma avaliacao `validated` exige classe de comparabilidade definida, justificativa, data e autor de validacao.

Cada nova avaliacao corrente supersede a anterior do mesmo KPI/binding/referencia; o historico nao e destruido.

## Seguranca

- RLS obrigatoria nas duas tabelas novas;
- leitura autorizada por Organizacao + acesso ao modulo de origem;
- `authenticated` recebe somente `SELECT` direto;
- INSERT/UPDATE/DELETE direto permanece bloqueado;
- mutacoes usam RPCs governadas;
- RPCs `SECURITY DEFINER` fazem verificacao explicita de `auth.uid()` e de autoridade organizacional;
- `PUBLIC` e `anon` nao recebem EXECUTE nas RPCs de mutacao;
- `service_role` preservado para operacao controlada.

## APIs propostas

- `create_sparks_measure_binding(...)`;
- `archive_sparks_measure_binding(...)`;
- `record_sparks_benchmark_comparability_assessment(...)`;
- `can_manage_sparks_measures(...)`;
- `can_view_sparks_measures(...)`.

Nao foi criada API transversal nova para Performance neste gate.
## Teste de nao regressao preparado

Arquivo:

`supabase/tests/transversal_measure_binding_benchmark_comparability_m1_test.sql`

O teste, a ser executado somente depois de uma aplicacao autorizada em ambiente de desenvolvimento, verifica:

- existencia e RLS das duas tabelas M1;
- permanencia das cinco autoridades fisicas `skpe_*` de Medidas/Performance;
- permanencia das fachadas `sparks_measure_*` e `sparks_performance_snapshots`;
- preservacao da tripla `automatic/manual/effective_performance`;
- preservacao do calculo e da agregacao estrategica atuais;
- existencia das novas APIs;
- ausencia de carga de dados estrutural pela migration.

## Shadow validation planejada

Antes de qualquer corte de autoridade, bindings novos deverao ser comparados com os vinculos fisicos existentes do SK-PE sem substituir estes ultimos.

A comparabilidade sera inicialmente informacional. Nenhum benchmark novo podera influenciar Meta ou Performance automaticamente por existir ou por possuir assessment.

## Estado do gate

`M1_MIGRATION_PROPOSAL=PREPARED`

`M1_APPLIED_TO_DATABASE=NO`

`CATALOG_IMPORT_EXECUTED=NO`

`SKPE_STORAGE_CHANGED=NO`

`NEXT_GATE=M1_REVIEW_AND_DEV_APPLICATION_DECISION`