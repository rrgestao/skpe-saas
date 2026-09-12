---
id: sprint-2026-09-12-skpe-med-des-01
title: Sprint 2026-09-12 — SKPE-MED-DES-01
status: active
owner: dev
language: pt-BR
---

# Sprint 2026-09-12 — SKPE-MED-DES-01

## Base

- Capability: `SKPE-MED-DES-01 — Medidas e Desempenho`.
- Branch: `sprint/2026-09-12-medidas-desempenho`.
- Base SHA: `d27373cc16740dfc86eb940abf639e322b072cc8`.
- Repositório canônico: `sparkooptech/skpe-saas`.
- Padrão inicial: `READ_ONLY_REUSE`.

## Escopo do primeiro gate

Inventariar e reconciliar contratos existentes de indicadores, metas, benchmarks,
medições, vínculos e autorização antes de qualquer alteração estrutural.

Restrições: sem migration, sem escrita, sem novo schema e sem redefinir KPI,
meta ou benchmark.

## Evidência inicial

Runtime `skpe-saas-dev` confirma `skpe_indicators`, `skpe_indicator_targets`,
`skpe_benchmark_references`, `skpe_indicator_measurements`, fachadas
`sparks_measure_*` e RPC `get_my_sparks_measure_indicators`.

## Gates de aceite

- `G1_RUNTIME_CONTRACT_INVENTORY=IN_PROGRESS`
- `G2_READ_MODEL_REUSE=PLANNED`
- `G3_UI_READ_ONLY=PLANNED`
- `G4_AUTHORIZATION_RUNTIME_AUDIT=PLANNED`
- `G5_TESTS_BUILD_AND_TRACEABILITY=PLANNED`

## Achados iniciais

- target/meta permanece distinto de benchmark;
- há vínculo direto `skpe_indicators.key_result_id` a confirmar semanticamente;
- há `evidence_reference` em medições a reconciliar como evidência de apuração;
- policies `SELECT` autenticadas existem nos objetos SK-PE centrais;
- nenhuma lacuna física crítica foi comprovada neste primeiro levantamento.

## Guardrail

Qualquer necessidade de migration, escrita, novo contrato físico ou mudança de
autoridade semântica exige gate próprio antes de implementação.
## G2 — Read Model Reuse

Status: PASS

Achados:
- `get_sparks_measure_performance_context` é o read-model contextual vigente;
- o runtime expõe indicador, baseline, meta, apuração, evidência, desempenho e benchmark;
- o primeiro gate permaneceu sem migration, sem DDL e sem escrita no Supabase;
- a UI contextual foi endurecida como read-only;
- ações mutantes de benchmark não são expostas no contexto de consulta;
- o grid passou a exibir fonte de dados, linha de base, horizonte da meta, data/fonte/evidência da apuração e contexto do benchmark;
- ausência de apuração continua distinta de valor zero.

Validação técnica:
- TypeScript dos testes: PASS;
- testes: 124/124 PASS;
- build: PASS;
- Supabase alterado: NÃO.

Próximo gate sugerido:
- G3 — reconciliar responsabilidade, vínculo direto com KR, evidência e regra de interpretação já existentes, sem criar schema novo.

## G3 — Reconciliação dos contratos parciais

Status: PASS

Achados confirmados no runtime:
- responsabilidade da medida existe em `skpe_indicators.owner_user_id` e na fachada `sparks_measure_indicators`;
- vínculo direto com KR existe em `skpe_indicators.key_result_id` e é projetado como `subject_type='key_result'` + `subject_id`;
- evidência de apuração existe em `skpe_indicator_measurements.evidence_reference`;
- interpretação de desempenho distingue `automatic_performance`, `manual_performance_override` e `effective_performance`.

Implementação:
- UI contextual passou a exibir Responsabilidade, Vínculo estratégico, Evidência e Interpretação;
- responsabilidade é apresentada como estado definido/não definido, sem expor UUID;
- override manual é explicitamente distinguido da interpretação automática;
- nenhuma migration, DDL ou escrita foi executada.

Validação técnica:
- TypeScript: PASS;
- testes: 131/131 PASS antes do guard específico do G3;
- build: PASS;
- Supabase alterado: NÃO.
