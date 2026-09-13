---
id: sk-pe-medidas-business-rules
title: Regras de negócio de Medidas e Desempenho
domain: products
type: business-rules
status: canonical
owner: product
canonicality: canonical
canonical: true
criticality: high
parent:
  - sk-pe-business-rules-hub
related:
  - skpe-med-des-01
  - sk-pe-current-state
tags:
  - sk-pe
  - business-rules
  - medidas
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product-business-rules
created: 2026-09-12
updated: 2026-09-12
lineage:
  - ./README.md
  - ../capabilities/SKPE-MED-DES-01-medidas-desempenho.md
---

# Regras de Medidas e Desempenho

Único owner detalhado de BR-SKPE-MED-001 a BR-SKPE-MED-044. [Capability funcional](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md) · [Contrato e enums](README.md#contrato-canônico-de-regra). Origem: piloto Corporate `8fbfeb6b13b94723a24394a320878c46c531ee86`; produto `d27373cc16740dfc86eb940abf639e322b072cc8`, sem delta. IDs, enunciados e classes de autoridade são preservados.

Aceite das duas CONFIRMED_PRODUCT_RULE provém das decisões explícitas já existentes na capability. Questões ligadas a C01/C02/C04 ficam PENDING_PRODUCT_DECISION; implementação sem aceite localizado fica IMPLEMENTED_NOT_ACCEPTED. Documentação/inferência sem aceite conhecido permanece UNKNOWN. Nenhuma classificação foi promovida nesta wave.

## Revisão de testes

Busca dirigida no SHA em `apps/web/tests` e `supabase/tests` por medidas, indicadores, benchmarks, cálculo, supersessão e snapshots; revisão do único resultado adjacente: [parseCanonicalWorkbook.test.ts][R-TEST-ADJ] lista nomes de abas de indicadores/metas/benchmarks, mas não exerce as regras deste catálogo. Não há base para classificá-lo como cobertura indireta destas regras. Suítes externas/ambiente runtime não foram examinados.

`RULES_WITH_DIRECT_TEST=0`; `RULES_WITH_INDIRECT_TEST=0`; `RULES_WITHOUT_TEST=44`; `RULES_UNKNOWN_TEST=0`. NONE é limitado às suítes versionadas pesquisadas; não prova inexistência universal. Nenhum teste de produto/SQL foi executado nesta wave. A dívida de qualidade permanece aberta: teste por regra deve indicar ID, comportamento/assertion, SHA e resultado antes de qualquer TEST_CONFIRMED.

## Índice inverso RULE → FUNCTION

| RULE | TITLE | APPLIES_TO | AUTHORITY_CLASS | VERIFICATION_STATUS | ACCEPTANCE_STATUS | TEST_COVERAGE |
| --- | --- | --- | --- | --- | --- | --- |
| [BR-SKPE-MED-001](#br-skpe-med-001) | Autoridade da medição | [F-MED-001](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-001); [F-MED-002](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-002); [F-MED-003](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-003); [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-005](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-005); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-008](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-008); [F-MED-009](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-009); [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-011](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-011); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013); [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017); [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020); [F-MED-021](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-021); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022); [F-MED-023](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-023); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024) | CONFIRMED_PRODUCT_RULE | DOCUMENT_CONFIRMED | PRODUCT_ACCEPTED | NONE |
| [BR-SKPE-MED-002](#br-skpe-med-002) | Consumidores não redefinem a medida | [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022); [F-MED-023](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-023) | CONFIRMED_PRODUCT_RULE | DOCUMENT_CONFIRMED | PRODUCT_ACCEPTED | NONE |
| [BR-SKPE-MED-003](#br-skpe-med-003) | Meta e benchmark distintos | [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024) | DOCUMENTED_RULE | DOCUMENT_CONFIRMED | UNKNOWN | NONE |
| [BR-SKPE-MED-004](#br-skpe-med-004) | Adapter limitado | [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-005](#br-skpe-med-005) | Edição governada | [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-008](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-008); [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-011](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-011); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013); [F-MED-021](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-021) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-006](#br-skpe-med-006) | Identidade e escopo do indicador | [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-007](#br-skpe-med-007) | Baseline em par | [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-008](#br-skpe-med-008) | Periodicidade enumerada | [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-009](#br-skpe-med-009) | Versão corrente do catálogo | [F-MED-001](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-001); [F-MED-002](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-002); [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-010](#br-skpe-med-010) | Vínculo de adoção | [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-005](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-005) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-011](#br-skpe-med-011) | Exclusão limitada a rascunhos | [F-MED-003](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-003); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-012](#br-skpe-med-012) | Arquivamento em cascata lógica | [F-MED-008](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-008) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-013](#br-skpe-med-013) | Horizonte e faixa da meta | [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-014](#br-skpe-med-014) | Uma meta longa não superseded | [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-011](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-011) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-015](#br-skpe-med-015) | Estados editáveis de meta | [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-011](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-011) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-016](#br-skpe-med-016) | Transições de benchmark | [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-017](#br-skpe-med-017) | Validação do pacote não é atividade do indicador | [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-021](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-021) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-018](#br-skpe-med-018) | Leitura pessoal delimitada | [F-MED-009](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-009) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-019](#br-skpe-med-019) | Seleção de formulação divergente | [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022) | CONFLICTING_RULE | PARTIAL | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-020](#br-skpe-med-020) | Presença não prova elegibilidade | [F-MED-009](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-009); [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022) | CONFLICTING_RULE | PARTIAL | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-021](#br-skpe-med-021) | Validação antes da projeção oficial | [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019) | DOCUMENTED_RULE | DOCUMENT_CONFIRMED | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-022](#br-skpe-med-022) | Supersessão de medição | [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-023](#br-skpe-med-023) | Tempo da medição | [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-024](#br-skpe-med-024) | Última medição contextual irrestrita | [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022) | CONFLICTING_RULE | PARTIAL | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-025](#br-skpe-med-025) | Cálculo ausente | [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-026](#br-skpe-med-026) | Polaridade crescente | [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-027](#br-skpe-med-027) | Polaridade decrescente | [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-028](#br-skpe-med-028) | Alvo específico | [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-029](#br-skpe-med-029) | Faixa desejável | [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-030](#br-skpe-med-030) | Limite e arredondamento | [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-031](#br-skpe-med-031) | Override e alvo histórico | [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017) | IMPLEMENTED_RULE | SQL_CONFIRMED | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-032](#br-skpe-med-032) | Agregação por peso | [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-033](#br-skpe-med-033) | Universo da agregação | [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019) | IMPLEMENTED_RULE | SQL_CONFIRMED | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-034](#br-skpe-med-034) | Semáforo parametrizado | [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-035](#br-skpe-med-035) | Snapshot governado | [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-036](#br-skpe-med-036) | Integridade da série | [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-037](#br-skpe-med-037) | Fórmula textual não comprovada como executável | [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017) | INFERRED_RULE | PARTIAL | UNKNOWN | NONE |
| [BR-SKPE-MED-038](#br-skpe-med-038) | Autorização da ampliação pendente | [F-MED-002](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-002); [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-005](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-005); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024) | PENDING_PRODUCT_DECISION | DOCUMENT_CONFIRMED | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-039](#br-skpe-med-039) | Seleção por intenção pendente | [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022) | PENDING_PRODUCT_DECISION | DOCUMENT_CONFIRMED | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-040](#br-skpe-med-040) | Oficialidade pendente | [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022) | PENDING_PRODUCT_DECISION | DOCUMENT_CONFIRMED | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-041](#br-skpe-med-041) | Vínculo não prova causalidade | [F-MED-023](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-023) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-042](#br-skpe-med-042) | UI administrativa alcançável | [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-005](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-005); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006) | IMPLEMENTED_RULE | CODE_CONFIRMED | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-MED-043](#br-skpe-med-043) | Validação de formulário não é autorização | [F-MED-002](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-002); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024) | IMPLEMENTED_RULE | SQL_CONFIRMED | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-MED-044](#br-skpe-med-044) | Reuso externo permanece intenção | [F-MED-001](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-001); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-023](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-023) | DOCUMENTED_RULE | DOCUMENT_CONFIRMED | UNKNOWN | NONE |

## Definições de regras

Cada registro segue o contrato do hub. RATIONALE operacional não é decisão Product adicional; ENFORCEMENT descreve fonte técnica versionada, não comprovação de implantação.

### BR-SKPE-MED-001

**ID:** BR-SKPE-MED-001 · **TITLE:** Autoridade da medição · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-001](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-001); [F-MED-002](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-002); [F-MED-003](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-003); [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-005](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-005); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-008](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-008); [F-MED-009](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-009); [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-011](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-011); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013); [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017); [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020); [F-MED-021](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-021); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022); [F-MED-023](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-023); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024)

**STATEMENT:** Medidas e Desempenho detém a semântica de indicador, meta e benchmark. · **RATIONALE:** Decisão explícita preexistente na capability; nenhuma nova decisão nesta wave

**ENTITIES:** Catálogo transversal; RPC catálogo; RPC + FK de adoção organizacional; Catálogo e selector; Adoção organizacional; Adapter e early return; Adapter SK-PE; Contrato FE05; RPC pessoal; Metas e guard FE05; Metas; Grid e fachada; Benchmark; Read-model e shell; Ciclo e cálculo; Registro e autorização; Cálculo compartilhado; Pacote e medições; Governança FE08; Auditoria operacional; FE05; Formulação/OKR; Iniciativas SPARKS; Admin de plataforma · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Medidas e Desempenho detém a semântica de indicador, meta e benchmark. · **OUTCOME:** Decisões semânticas pertencem ao owner Product · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** CONFIRMED_PRODUCT_RULE · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** PRODUCT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** [AUTH][R-AUTH]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** CORPORATE · **SOURCE_EVIDENCE:** [AUTH][R-AUTH] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** AUTHORITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-002

**ID:** BR-SKPE-MED-002 · **TITLE:** Consumidores não redefinem a medida · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022); [F-MED-023](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-023)

**STATEMENT:** Painel, Visão Executiva e Exploração Hierárquica são consumidores; não redefinem KPI/meta/benchmark. · **RATIONALE:** Decisão explícita preexistente na capability

**ENTITIES:** Read-model e shell; Pacote e medições; Formulação/OKR; Iniciativas SPARKS · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Painel, Visão Executiva e Exploração Hierárquica são consumidores; não redefinem KPI/meta/benchmark. · **OUTCOME:** Interpretação preserva autoridade de Medidas · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** CONFIRMED_PRODUCT_RULE · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** PRODUCT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** [AUTH][R-AUTH]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** CORPORATE · **SOURCE_EVIDENCE:** [AUTH][R-AUTH] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** AUTHORITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-003

**ID:** BR-SKPE-MED-003 · **TITLE:** Meta e benchmark distintos · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024)

**STATEMENT:** Meta é alvo organizacional; benchmark é referência contextual com fonte/período. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Metas e guard FE05; Grid e fachada; Benchmark; Admin de plataforma · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Meta é alvo organizacional; benchmark é referência contextual com fonte/período. · **OUTCOME:** Não substituir alvo por referência comparativa · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** DOCUMENTED_RULE · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** UNKNOWN · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** CORPORATE; DOCUMENTATION · **SOURCE_EVIDENCE:** [AUTH][R-AUTH]; [FE06][R-FE06] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-004

**ID:** BR-SKPE-MED-004 · **TITLE:** Adapter limitado · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022)

**STATEMENT:** Fachada de indicador aceita apenas SK-PE, strategic_formulation e strategic_objective; demais contextos falham fechados. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Adapter e early return; Adapter SK-PE; Formulação/OKR · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Fachada de indicador aceita apenas SK-PE, strategic_formulation e strategic_objective; demais contextos falham fechados. · **OUTCOME:** Delega ao upsert SK-PE ou erro 0A000 · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [ADAPTER][R-ADAPTER] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-005

**ID:** BR-SKPE-MED-005 · **TITLE:** Edição governada · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-008](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-008); [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-011](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-011); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013); [F-MED-021](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-021)

**STATEMENT:** Alterar indicador/meta/benchmark requer formulação editável e permissões do contrato; não basta acesso de leitura. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Adapter e early return; Adapter SK-PE; Contrato FE05; Metas e guard FE05; Metas; Grid e fachada; Benchmark; FE05 · **PRECONDITIONS:** Formulação existente · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Alterar indicador/meta/benchmark requer formulação editável e permissões do contrato; não basta acesso de leitura. · **OUTCOME:** Aceita o contrato descrito ou rejeita a operação incompatível · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** Edição em draft/in_elaboration; demais estados bloqueados

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** DOCUMENTATION; SQL · **SOURCE_EVIDENCE:** [FORM-GUARD][R-FORM-GUARD]; [BENCH-LIFE][R-BENCH-LIFE]; [FE02][R-FE02] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-006

**ID:** BR-SKPE-MED-006 · **TITLE:** Identidade e escopo do indicador · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007)

**STATEMENT:** Código, nome e unidade são obrigatórios; objetivo deve estar ativo na mesma organização/projeto/formulação. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Adapter e early return; Adapter SK-PE · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Código, nome e unidade são obrigatórios; objetivo deve estar ativo na mesma organização/projeto/formulação. · **OUTCOME:** Indicador coerente com objetivo; erro em campos vazios ou escopo divergente · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [IND][R-IND]; [IND-CONSTRAINT][R-IND-CONSTRAINT] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-007

**ID:** BR-SKPE-MED-007 · **TITLE:** Baseline em par · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017)

**STATEMENT:** baseline_value e baseline_date devem ser informados juntos ou ambos ausentes. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Adapter SK-PE; Cálculo compartilhado · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** baseline_value e baseline_date devem ser informados juntos ou ambos ausentes. · **OUTCOME:** Par valor/data consistente · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [IND][R-IND] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** TEMPORAL

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-008

**ID:** BR-SKPE-MED-008 · **TITLE:** Periodicidade enumerada · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015)

**STATEMENT:** Frequência informada deve ser daily, weekly, monthly, bimonthly, quarterly, semiannual, annual ou on_demand; não implica coleta automática. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Adapter SK-PE; Ciclo e cálculo · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Frequência informada deve ser daily, weekly, monthly, bimonthly, quarterly, semiannual, annual ou on_demand; não implica coleta automática. · **OUTCOME:** Aceita o contrato descrito ou rejeita a operação incompatível · **EXCEPTIONS:** Frequência vazia é normalizada para null · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [IND][R-IND] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** TEMPORAL

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-009

**ID:** BR-SKPE-MED-009 · **TITLE:** Versão corrente do catálogo · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-001](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-001); [F-MED-002](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-002); [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006)

**STATEMENT:** Adoção exige is_current=true e status=active; nova versão pode desmarcar current das anteriores do mesmo código. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Catálogo transversal; RPC catálogo; Catálogo e selector; Adapter e early return · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Adoção exige is_current=true e status=active; nova versão pode desmarcar current das anteriores do mesmo código. · **OUTCOME:** Disponibilidade para adoção não é inferida apenas de active · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** Versão anterior current → false quando nova current é criada

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [CAT-WRITE][R-CAT-WRITE]; [CAT-ELIGIBLE][R-CAT-ELIGIBLE]; [ADOPT-OE][R-ADOPT-OE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-010

**ID:** BR-SKPE-MED-010 · **TITLE:** Vínculo de adoção · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-005](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-005)

**STATEMENT:** Adoção organizacional usa vínculo único organização/referência, ativa ou reativa esse vínculo e registra motivo; não é cópia integral do catálogo. Arquivamento bloqueia quando existe skpe_indicator não archived vinculado à referência na organização; vínculo ativo ausente é ignorado. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Catálogo e selector; Adoção organizacional · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Adoção organizacional usa vínculo único organização/referência, ativa ou reativa esse vínculo e registra motivo; não é cópia integral do catálogo. Arquivamento bloqueia quando existe skpe_indicator não archived vinculado à referência na organização; vínculo ativo ausente é ignorado. · **OUTCOME:** Vínculo active retornado · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** ausente/archived → active

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [ADOPT-ORG][R-ADOPT-ORG]; [ORG-READ][R-ORG-READ]; [ARCHIVE-ORG][R-ARCHIVE-ORG] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-011

**ID:** BR-SKPE-MED-011 · **TITLE:** Exclusão limitada a rascunhos · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-003](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-003); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024)

**STATEMENT:** Excluir referência requer super admin, motivo, draft, zero transições e ausência das dependências verificadas; benchmark geral draft exige ausência de verified_at. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** RPC + FK de adoção organizacional; Admin de plataforma · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Excluir referência requer super admin, motivo, draft, zero transições e ausência das dependências verificadas; benchmark geral draft exige ausência de verified_at. · **OUTCOME:** Exclusão restrita; histórico legítimo preservado · **EXCEPTIONS:** Referência corrente excluída pode restaurar versão anterior; outras FKs ainda podem bloquear exclusão · **STATE_TRANSITIONS:** draft → excluído

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [CAT-DELETE][R-CAT-DELETE]; [BENCH-DELETE][R-BENCH-DELETE]; [DEL-PRIV][R-DEL-PRIV] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-012

**ID:** BR-SKPE-MED-012 · **TITLE:** Arquivamento em cascata lógica · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-008](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-008)

**STATEMENT:** Arquivar strategic_kpi marca metas não superseded como superseded e benchmarks não archived como archived. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Contrato FE05 · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Arquivar strategic_kpi marca metas não superseded como superseded e benchmarks não archived como archived. · **OUTCOME:** Histórico físico mantido · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** indicador → archived; dependências → superseded/archived

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [ARCHIVE][R-ARCHIVE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-013

**ID:** BR-SKPE-MED-013 · **TITLE:** Horizonte e faixa da meta · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010)

**STATEMENT:** Período deve ser válido e contido no horizonte conhecido; tolerância inferior não supera superior; long_term respeita polaridade e faixa contendo o alvo quando range_is_better. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Metas e guard FE05 · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Período deve ser válido e contido no horizonte conhecido; tolerância inferior não supera superior; long_term respeita polaridade e faixa contendo o alvo quando range_is_better. · **OUTCOME:** Meta compatível com tempo e direção · **EXCEPTIONS:** Limite de horizonte ausente não é inventado; guards de polaridade específicos de long_term · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** DOCUMENTATION; SQL · **SOURCE_EVIDENCE:** [TARGET][R-TARGET]; [FE06][R-FE06] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-014

**ID:** BR-SKPE-MED-014 · **TITLE:** Uma meta longa não superseded · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-011](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-011)

**STATEMENT:** Upsert bloqueia segunda long_term não superseded do indicador, excluindo o próprio ID em edição. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Metas e guard FE05; Metas · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Upsert bloqueia segunda long_term não superseded do indicador, excluindo o próprio ID em edição. · **OUTCOME:** Erro 23505 para duplicidade detectada · **EXCEPTIONS:** Guard de RPC consultivo; não afirmar garantia concorrente por índice exclusivo desse predicado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [TARGET][R-TARGET] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-015

**ID:** BR-SKPE-MED-015 · **TITLE:** Estados editáveis de meta · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-011](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-011)

**STATEMENT:** Upsert FE05 aceita tipo annual/intermediate/long_term e status draft/active; tabela também representa achieved/not_achieved/superseded. Substituição usa RPC própria. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Metas e guard FE05; Metas · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Upsert FE05 aceita tipo annual/intermediate/long_term e status draft/active; tabela também representa achieved/not_achieved/superseded. Substituição usa RPC própria. · **OUTCOME:** Aceita o contrato descrito ou rejeita a operação incompatível · **EXCEPTIONS:** Tipo cycle pertence a outros contratos, não ao upsert FE05 · **STATE_TRANSITIONS:** draft/active definidos pelo upsert; não superseded → superseded

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [TARGET][R-TARGET]; [SUPER-TARGET][R-SUPER-TARGET] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-016

**ID:** BR-SKPE-MED-016 · **TITLE:** Transições de benchmark · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013)

**STATEMENT:** verify exige draft e período de referência; activate exige verified; retorno aceita verified/active; archive usa ação própria e permissões. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Grid e fachada; Benchmark · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** verify exige draft e período de referência; activate exige verified; retorno aceita verified/active; archive usa ação própria e permissões. · **OUTCOME:** Aceita o contrato descrito ou rejeita a operação incompatível · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** draft → verified → active; verified/active → draft; → archived

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** DOCUMENTATION; SQL · **SOURCE_EVIDENCE:** [BENCH-LIFE][R-BENCH-LIFE]; [FE06][R-FE06] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-017

**ID:** BR-SKPE-MED-017 · **TITLE:** Validação do pacote não é atividade do indicador · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-010](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-010); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-021](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-021)

**STATEMENT:** Pacote FE05 pode ser submetido e validado com readiness; alterações posteriores invalidam pacote e metadata.validationStatus sem equivaler a indicador.status. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Adapter SK-PE; Metas e guard FE05; Grid e fachada; FE05 · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Pacote FE05 pode ser submetido e validado com readiness; alterações posteriores invalidam pacote e metadata.validationStatus sem equivaler a indicador.status. · **OUTCOME:** Aceita o contrato descrito ou rejeita a operação incompatível · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** in_elaboration → pending_validation → validated; alteração/retorno → in_elaboration

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [PACKAGE-LIFE][R-PACKAGE-LIFE]; [INVALIDATE][R-INVALIDATE]; [READY][R-READY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-018

**ID:** BR-SKPE-MED-018 · **TITLE:** Leitura pessoal delimitada · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-009](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-009)

**STATEMENT:** Consulta pessoal exige responsabilidade do usuário, indicador não archived e objetivo active; retorna meta contextual, não uma medição. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** RPC pessoal · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Consulta pessoal exige responsabilidade do usuário, indicador não archived e objetivo active; retorna meta contextual, não uma medição. · **OUTCOME:** Lista all/active/draft/inactive · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** FRONTEND; SQL · **SOURCE_EVIDENCE:** [MY-SQL][R-MY-SQL]; [UI-MY][R-UI-MY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-019

**ID:** BR-SKPE-MED-019 · **TITLE:** Seleção de formulação divergente · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022)

**STATEMENT:** Filtro draft/under_review/approved omite estados válidos; under_review não é estado SQL de formulação. FORM resolve contexto apenas com uma linha. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Adapter e early return; Read-model e shell; Formulação/OKR · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Filtro draft/under_review/approved omite estados válidos; under_review não é estado SQL de formulação. FORM resolve contexto apenas com uma linha. · **OUTCOME:** Pode omitir contexto; formulário antigo de adoção não é alcançável no render administration · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** FRONTEND; SQL · **SOURCE_EVIDENCE:** [UI-FILTER][R-UI-FILTER]; [UI-FORM][R-UI-FORM]; [FORM-CONSTRAINT][R-FORM-CONSTRAINT]; [UI-EARLY][R-UI-EARLY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** APPLICATION_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** C02 · **PENDING_DECISION:** BR-SKPE-MED-039 · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-020

**ID:** BR-SKPE-MED-020 · **TITLE:** Presença não prova elegibilidade · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-009](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-009); [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022)

**STATEMENT:** Cards withTarget/withBenchmark/assessed verificam presença. Meta contextual exclui superseded mas pode ser draft/futura/passada; benchmark não filtra archived; medição não filtra validated. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** RPC pessoal; Read-model e shell; Formulação/OKR · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Cards withTarget/withBenchmark/assessed verificam presença. Meta contextual exclui superseded mas pode ser draft/futura/passada; benchmark não filtra archived; medição não filtra validated. · **OUTCOME:** Exibição deve ser qualificada antes de ser interpretada como vigente/oficial · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** FRONTEND; SQL · **SOURCE_EVIDENCE:** [READ][R-READ]; [UI][R-UI]; [UI-GRID][R-UI-GRID] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** APPLICATION_ENFORCED + DATABASE_ENFORCED · **CATEGORY:** TEMPORAL

**CONFLICTS:** C02,C04 · **PENDING_DECISION:** BR-SKPE-MED-039, BR-SKPE-MED-040 · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-021

**ID:** BR-SKPE-MED-021 · **TITLE:** Validação antes da projeção oficial · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019)

**STATEMENT:** FE09 distingue submissão de validação e preserva um validado corrente por ciclo; projeções de KR/iniciativa/resultado só se atualizam após validação formal. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Ciclo e cálculo; Registro e autorização; Pacote e medições; Governança FE08 · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** FE09 distingue submissão de validação e preserva um validado corrente por ciclo; projeções de KR/iniciativa/resultado só se atualizam após validação formal. · **OUTCOME:** Intenção documental; não certifica todos os consumidores de desempenho · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** DOCUMENTED_RULE · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** DOCUMENTATION · **SOURCE_EVIDENCE:** [FE09][R-FE09] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** LIFECYCLE

**CONFLICTS:** C04 · **PENDING_DECISION:** BR-SKPE-MED-040 · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-022

**ID:** BR-SKPE-MED-022 · **TITLE:** Supersessão de medição · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020)

**STATEMENT:** Registro cria submitted e supersede submitted anterior; validate exige submitted e supersede validated anterior do mesmo ciclo/indicador. reject exige submitted; resubmit exige rejected. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Ciclo e cálculo; Registro e autorização; Auditoria operacional · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Registro cria submitted e supersede submitted anterior; validate exige submitted e supersede validated anterior do mesmo ciclo/indicador. reject exige submitted; resubmit exige rejected. · **OUTCOME:** Preserva validated até nova validação · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** submitted → validated/rejected; rejected → submitted; anterior → superseded

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [RECORD][R-RECORD]; [RECORD-LIFE][R-RECORD-LIFE]; [MEAS-UNIQUE][R-MEAS-UNIQUE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-023

**ID:** BR-SKPE-MED-023 · **TITLE:** Tempo da medição · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020)

**STATEMENT:** measurement_date vem do payload ou current_date e deve pertencer ao ciclo; period_start/end são campos separados, created_at registra inserção e validated_at registra validação. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Ciclo e cálculo; Registro e autorização; Auditoria operacional · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** measurement_date vem do payload ou current_date e deve pertencer ao ciclo; period_start/end são campos separados, created_at registra inserção e validated_at registra validação. · **OUTCOME:** Não confundir data do fenômeno, inserção e validação · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [RECORD][R-RECORD]; [MEAS-TABLE][R-MEAS-TABLE]; [RECORD-LIFE][R-RECORD-LIFE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** TEMPORAL

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-024

**ID:** BR-SKPE-MED-024 · **TITLE:** Última medição contextual irrestrita · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022)

**STATEMENT:** RPC ordena measurement_date DESC NULLS LAST, created_at DESC, limit 1; não filtra status/ciclo/supersessão. OKR ordena só measurement_date. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Read-model e shell; Formulação/OKR · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** RPC ordena measurement_date DESC NULLS LAST, created_at DESC, limit 1; não filtra status/ciclo/supersessão. OKR ordena só measurement_date. · **OUTCOME:** submitted/rejected/superseded podem vencer; não equivale a oficial · **EXCEPTIONS:** Empate completo não tem desempate por ID definido · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** FRONTEND; SQL · **SOURCE_EVIDENCE:** [READ][R-READ]; [VIEWS][R-VIEWS]; [UI-OKR][R-UI-OKR] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED + APPLICATION_ENFORCED · **CATEGORY:** TEMPORAL

**CONFLICTS:** C04 · **PENDING_DECISION:** BR-SKPE-MED-040 · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-025

**ID:** BR-SKPE-MED-025 · **TITLE:** Cálculo ausente · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017)

**STATEMENT:** Cálculo retorna null se baseline, valor atual ou target forem null; polaridade desconhecida também retorna null. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Cálculo compartilhado · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Cálculo retorna null se baseline, valor atual ou target forem null; polaridade desconhecida também retorna null. · **OUTCOME:** Ausência não é transformada em zero nesse caminho · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [CALC][R-CALC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-026

**ID:** BR-SKPE-MED-026 · **TITLE:** Polaridade crescente · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017)

**STATEMENT:** higher_is_better usa 100*(valor-baseline)/(target-baseline); se target=baseline, retorna 100 quando valor>=target, senão 0. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Cálculo compartilhado · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** higher_is_better usa 100*(valor-baseline)/(target-baseline); se target=baseline, retorna 100 quando valor>=target, senão 0. · **OUTCOME:** Percentual sujeito a limite e arredondamento finais · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [CALC][R-CALC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-027

**ID:** BR-SKPE-MED-027 · **TITLE:** Polaridade decrescente · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017)

**STATEMENT:** lower_is_better usa 100*(baseline-valor)/(baseline-target); se target=baseline, retorna 100 quando valor<=target, senão 0. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Cálculo compartilhado · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** lower_is_better usa 100*(baseline-valor)/(baseline-target); se target=baseline, retorna 100 quando valor<=target, senão 0. · **OUTCOME:** Denominador zero tratado pelo ramo explícito · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [CALC][R-CALC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-028

**ID:** BR-SKPE-MED-028 · **TITLE:** Alvo específico · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017)

**STATEMENT:** target_is_better usa 100*(1-abs(valor-target)/abs(baseline-target)); baseline no alvo dá 100 apenas quando valor também está no alvo. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Cálculo compartilhado · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** target_is_better usa 100*(1-abs(valor-target)/abs(baseline-target)); baseline no alvo dá 100 apenas quando valor também está no alvo. · **OUTCOME:** Distância relativa ao alvo, limitada a 0–100 · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [CALC][R-CALC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-029

**ID:** BR-SKPE-MED-029 · **TITLE:** Faixa desejável · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017)

**STATEMENT:** range_is_better exige limites válidos; compara distância de baseline e valor à faixa. Dentro da faixa dá 100; baseline dentro e valor fora dá 0; demais casos usam 100*(1-distância_atual/distância_baseline). · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Cálculo compartilhado · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** range_is_better exige limites válidos; compara distância de baseline e valor à faixa. Dentro da faixa dá 100; baseline dentro e valor fora dá 0; demais casos usam 100*(1-distância_atual/distância_baseline). · **OUTCOME:** null para faixa inválida · **EXCEPTIONS:** O guard inicial ainda exige target não null, mesmo no cálculo por faixa · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [CALC][R-CALC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-030

**ID:** BR-SKPE-MED-030 · **TITLE:** Limite e arredondamento · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017)

**STATEMENT:** Cálculo final é limitado a 0–100 e round(...,2); grid apresenta effective_performance com toFixed(1). Não há fórmula separada de attainment localizada no recorte. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Read-model e shell; Cálculo compartilhado · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Cálculo final é limitado a 0–100 e round(...,2); grid apresenta effective_performance com toFixed(1). Não há fórmula separada de attainment localizada no recorte. · **OUTCOME:** Precisão de armazenamento/cálculo difere da apresentação · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** FRONTEND; SQL · **SOURCE_EVIDENCE:** [CALC][R-CALC]; [UI-GRID][R-UI-GRID] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED + APPLICATION_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-031

**ID:** BR-SKPE-MED-031 · **TITLE:** Override e alvo histórico · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017)

**STATEMENT:** Override manual exige permissão do pacote e 0–100; effective usa manual ou automático. Cálculo é feito no registro submitted com target associado, não recalculado pela meta contextual exibida. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Ciclo e cálculo; Cálculo compartilhado · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Override manual exige permissão do pacote e 0–100; effective usa manual ou automático. Cálculo é feito no registro submitted com target associado, não recalculado pela meta contextual exibida. · **OUTCOME:** Performance numérica não comprova validação · **EXCEPTIONS:** Ambos manual/automático ausentes mantêm null; target explícito do payload segue guard próprio · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [RECORD][R-RECORD]; [READ][R-READ] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** C04 · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-032

**ID:** BR-SKPE-MED-032 · **TITLE:** Agregação por peso · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018)

**STATEMENT:** Desempenho de ciclo usa sum(performance*peso)/nullif(sum(peso),0), round 2; explicit_weight usa monitoringWeight positivo ou fallback 1, demais políticas peso 1. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Pacote e medições · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Desempenho de ciclo usa sum(performance*peso)/nullif(sum(peso),0), round 2; explicit_weight usa monitoringWeight positivo ou fallback 1, demais políticas peso 1. · **OUTCOME:** Null sem universo; peso de linha com performance null permanece no denominador no SQL lido · **EXCEPTIONS:** Não aplicar essa fórmula automaticamente ao dashboard de iniciativas · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [AGGREGATE][R-AGGREGATE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-033

**ID:** BR-SKPE-MED-033 · **TITLE:** Universo da agregação · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019)

**STATEMENT:** Agregação de ciclo aceita KPI estratégico active e medições submitted/validated; quando há submitted, exclui validated do mesmo indicador/ciclo. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Pacote e medições; Governança FE08 · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Agregação de ciclo aceita KPI estratégico active e medições submitted/validated; quando há submitted, exclui validated do mesmo indicador/ciclo. · **OUTCOME:** Leitura preparatória pode preferir submissão; gate de fechamento é distinto · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [AGGREGATE][R-AGGREGATE]; [CLOSE-READY][R-CLOSE-READY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** C04 · **PENDING_DECISION:** BR-SKPE-MED-040 · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-034

**ID:** BR-SKPE-MED-034 · **TITLE:** Semáforo parametrizado · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018)

**STATEMENT:** Performance null gera not_assessed; abaixo de critical_threshold gera critical; abaixo de attention_threshold gera attention; >=on_track_threshold gera achieved; restante on_track. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Pacote e medições · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Performance null gera not_assessed; abaixo de critical_threshold gera critical; abaixo de attention_threshold gera attention; >=on_track_threshold gera achieved; restante on_track. · **OUTCOME:** Sinal depende do pacote, não apenas da cor na UI · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [SIGNAL][R-SIGNAL] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** CALCULATION

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-035

**ID:** BR-SKPE-MED-035 · **TITLE:** Snapshot governado · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020)

**STATEMENT:** Fechar exige pending_ratification, permissão de ratificação e readyForClose; gera snapshot ratified versionado com checksum. Reabrir closed supersede snapshots ratified. Trigger impede exclusão e mutação fora das transições previstas. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Governança FE08; Auditoria operacional · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Fechar exige pending_ratification, permissão de ratificação e readyForClose; gera snapshot ratified versionado com checksum. Reabrir closed supersede snapshots ratified. Trigger impede exclusão e mutação fora das transições previstas. · **OUTCOME:** Versão histórica preservada, sem certificar dados publicados · **EXCEPTIONS:** Bloqueio de submitted em readiness depende de data_quality_required; não é filtro validated incondicional no builder · **STATE_TRANSITIONS:** ciclo pending_ratification → closed → reopened; snapshot ratified → superseded

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [CLOSE][R-CLOSE]; [REOPEN][R-REOPEN]; [IMMUTABLE][R-IMMUTABLE]; [CLOSE-READY][R-CLOSE-READY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-036

**ID:** BR-SKPE-MED-036 · **TITLE:** Integridade da série · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-015](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-015); [F-MED-016](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-016); [F-MED-020](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-020)

**STATEMENT:** Índices únicos separados limitam um submitted e um validated por ciclo/indicador; FK vincula ciclo/formulação/organização/projeto; auto-supersessão é proibida. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Ciclo e cálculo; Registro e autorização; Auditoria operacional · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Índices únicos separados limitam um submitted e um validated por ciclo/indicador; FK vincula ciclo/formulação/organização/projeto; auto-supersessão é proibida. · **OUTCOME:** Múltiplas versões históricas coexistem sem duplicar estados correntes · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [MEAS-UNIQUE][R-MEAS-UNIQUE]; [MEAS-TABLE][R-MEAS-TABLE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-037

**ID:** BR-SKPE-MED-037 · **TITLE:** Fórmula textual não comprovada como executável · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-017](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-017)

**STATEMENT:** formula_text é armazenada e considerada no readiness; não foi localizado avaliador dessa expressão nos caminhos de Medidas investigados. · **RATIONALE:** Inferência limitada à busca dirigida; não prova inexistência global

**ENTITIES:** Adapter SK-PE; Cálculo compartilhado · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** formula_text é armazenada e considerada no readiness; não foi localizado avaliador dessa expressão nos caminhos de Medidas investigados. · **OUTCOME:** Não apresentar fórmula descritiva como motor executado · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** INFERRED_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** UNKNOWN · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [IND][R-IND]; [READY][R-READY]; [CALC][R-CALC] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** UNKNOWN · **CATEGORY:** CALCULATION

**CONFLICTS:** NONE · **PENDING_DECISION:** Confirmar com Product/DEV se existe motor externo ou outro consumidor · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-038

**ID:** BR-SKPE-MED-038 · **TITLE:** Autorização da ampliação pendente · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-002](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-002); [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-005](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-005); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-007](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-007); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-013](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-013); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024)

**STATEMENT:** Não localizar aprovação canônica para escrita ampliada não autoriza nem proíbe retroativamente seu uso. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** RPC catálogo; Catálogo e selector; Adoção organizacional; Adapter e early return; Adapter SK-PE; Grid e fachada; Benchmark; Admin de plataforma · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Não localizar aprovação canônica para escrita ampliada não autoriza nem proíbe retroativamente seu uso. · **OUTCOME:** OPEN_PRODUCT_DECISION preservado · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** PENDING_PRODUCT_DECISION · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** CORPORATE · **SOURCE_EVIDENCE:** [OPEN][R-OPEN]; [READONLY][R-READONLY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** AUTHORITY

**CONFLICTS:** C01 · **PENDING_DECISION:** Product localizar/deliberar escopo, perfis e aceite quando retomar Medidas · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-039

**ID:** BR-SKPE-MED-039 · **TITLE:** Seleção por intenção pendente · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022)

**STATEMENT:** Product deve definir versão de leitura versus versão editável e a precedência aberta/aprovada por consumidor. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Adapter e early return; Read-model e shell; Formulação/OKR · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Product deve definir versão de leitura versus versão editável e a precedência aberta/aprovada por consumidor. · **OUTCOME:** Não implementar seleção nova nesta wave · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** PENDING_PRODUCT_DECISION · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** CORPORATE; DOCUMENTATION · **SOURCE_EVIDENCE:** [OPEN][R-OPEN]; [FE02][R-FE02] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** AUTHORITY

**CONFLICTS:** C02 · **PENDING_DECISION:** Decisão Product na retomada de Medidas · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-040

**ID:** BR-SKPE-MED-040 · **TITLE:** Oficialidade pendente · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-014](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-014); [F-MED-018](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-018); [F-MED-019](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-019); [F-MED-022](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-022)

**STATEMENT:** Product deve definir leitura informativa versus oficial, ciclo/período, desempate e transparência de validação em cada consumidor. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Read-model e shell; Pacote e medições; Governança FE08; Formulação/OKR · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Product deve definir leitura informativa versus oficial, ciclo/período, desempate e transparência de validação em cada consumidor. · **OUTCOME:** Baseline permanece válida; conflito não resolvido · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** PENDING_PRODUCT_DECISION · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** CORPORATE; DOCUMENTATION · **SOURCE_EVIDENCE:** [OPEN][R-OPEN]; [FE09][R-FE09] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** AUTHORITY

**CONFLICTS:** C04 · **PENDING_DECISION:** Decisão Product na retomada de Medidas · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-041

**ID:** BR-SKPE-MED-041 · **TITLE:** Vínculo não prova causalidade · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-023](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-023)

**STATEMENT:** Vínculo iniciativa/indicador possui FK de escopo, papel, contribuição, atribuição e unicidade. Atribuição causal requer justificativa institucional segundo comentário SQL; o schema não infere causalidade. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Iniciativas SPARKS · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Vínculo iniciativa/indicador possui FK de escopo, papel, contribuição, atribuição e unicidade. Atribuição causal requer justificativa institucional segundo comentário SQL; o schema não infere causalidade. · **OUTCOME:** Integridade estrutural aplicada no banco; justificativa causal não comprovada como guard · **EXCEPTIONS:** Causalidade institucional é DOCUMENTED_ONLY no comentário, não um teste automático · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** SQL · **SOURCE_EVIDENCE:** [LINK][R-LINK] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-042

**ID:** BR-SKPE-MED-042 · **TITLE:** UI administrativa alcançável · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-004](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-004); [F-MED-005](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-005); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006)

**STATEMENT:** mode administration retorna SparksMeasureDualSelector antes do JSX antigo de adoção contextual; este formulário não é alcançável por esse render. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Catálogo e selector; Adoção organizacional; Adapter e early return · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** mode administration retorna SparksMeasureDualSelector antes do JSX antigo de adoção contextual; este formulário não é alcançável por esse render. · **OUTCOME:** Handler contextual presente não é evidência de fluxo funcional acessível · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** CODE_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** [OPEN][R-OPEN]

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** FRONTEND · **SOURCE_EVIDENCE:** [UI-EARLY][R-UI-EARLY]; [UI-DUAL][R-UI-DUAL] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** APPLICATION_ENFORCED · **CATEGORY:** LIFECYCLE

**CONFLICTS:** C01,C02 · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-043

**ID:** BR-SKPE-MED-043 · **TITLE:** Validação de formulário não é autorização · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-002](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-002); [F-MED-012](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-012); [F-MED-024](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-024)

**STATEMENT:** Grid exige indicador/fonte/motivo; catálogo exige campos e motivo; botões de salvar são desabilitados durante saving. Isso não substitui guards SQL nem aprovação Product. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** RPC catálogo; Grid e fachada; Admin de plataforma · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Grid exige indicador/fonte/motivo; catálogo exige campos e motivo; botões de salvar são desabilitados durante saving. Isso não substitui guards SQL nem aprovação Product. · **OUTCOME:** Prevenção local de envio incompleto; controle efetivo depende do backend · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** FRONTEND; SQL · **SOURCE_EVIDENCE:** [UI-BENCH][R-UI-BENCH]; [UI-CAT][R-UI-CAT]; [BENCH][R-BENCH]; [CAT-WRITE][R-CAT-WRITE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** APPLICATION_ENFORCED · **CATEGORY:** INTEGRITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

### BR-SKPE-MED-044

**ID:** BR-SKPE-MED-044 · **TITLE:** Reuso externo permanece intenção · **CAPABILITY:** SKPE-MED-DES-01 · **APPLIES_TO:** [F-MED-001](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-001); [F-MED-006](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-006); [F-MED-023](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#f-med-023)

**STATEMENT:** Natureza transversal e fachadas não comprovam integração operacional com outros produtos. · **RATIONALE:** Finalidade operacional descrita pela função relacionada; não é justificativa Product adicional

**ENTITIES:** Catálogo transversal; Adapter e early return; Iniciativas SPARKS · **PRECONDITIONS:** Escopo e permissões da função relacionada · **TRIGGER:** Operação da função relacionada

**CONSTRAINT:** Natureza transversal e fachadas não comprovam integração operacional com outros produtos. · **OUTCOME:** Não inventar funcionalidade multproduto entregue · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** DOCUMENTED_RULE · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** UNKNOWN · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED; não inferir aceite

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste direto ou indireto específico localizado no SHA e nas suítes versionadas examinadas; ver revisão de testes. Não significa inexistência de testes externos.

**SOURCE_TYPE:** CORPORATE; SQL · **SOURCE_EVIDENCE:** [AUTH][R-AUTH]; [ADAPTER][R-ADAPTER] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** AUTHORITY

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Comparar entradas, resultado/erro, estado e trilha das funções relacionadas em gate futuro; fonte estático inspecionado, execução autenticada não observada

## Pendências Product

| CONFLICT_ID | STATUS | Regras afetadas | Impacto documental |
| --- | --- | --- | --- |
| C01 | OPEN_PRODUCT_DECISION | [BR-SKPE-MED-038](#br-skpe-med-038); [BR-SKPE-MED-042](#br-skpe-med-042) | Disponibilidade técnica não comprova autorização de adoção. |
| C02 | OPEN_PRODUCT_DECISION | [BR-SKPE-MED-019](#br-skpe-med-019); [BR-SKPE-MED-020](#br-skpe-med-020); [BR-SKPE-MED-039](#br-skpe-med-039); [BR-SKPE-MED-042](#br-skpe-med-042) | Preservar divergência de seleção/lifecycle; não corrigir UI. |
| C04 | OPEN_PRODUCT_DECISION | [BR-SKPE-MED-020](#br-skpe-med-020); [BR-SKPE-MED-021](#br-skpe-med-021); [BR-SKPE-MED-024](#br-skpe-med-024); [BR-SKPE-MED-031](#br-skpe-med-031); [BR-SKPE-MED-033](#br-skpe-med-033); [BR-SKPE-MED-040](#br-skpe-med-040) | Não atribuir oficialidade a latest ou agregação preparatória. |

Funções afetadas estão no índice inverso e na [capability](../capabilities/SKPE-MED-DES-01-medidas-desempenho.md#conflitos-e-decisões-pendentes). Resolver apenas na retomada de Medidas; baseline inteira preservada.

[R-ADAPTER]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904234019_establish_transversal_measures_performance_write_facade.sql#L1
[R-ADOPT-OE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908135440_govern_measure_reference_catalog_adoption.sql#L114
[R-ADOPT-ORG]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909214455_govern_organization_measure_reference_adoption.sql#L118
[R-AGGREGATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L3182
[R-ARCHIVE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L746
[R-ARCHIVE-ORG]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909214455_govern_organization_measure_reference_adoption.sql#L208
[R-AUTH]: https://github.com/br-robson/projetos/blob/30c59b472bdf0b3d0aaab9e0b0246d0f814ed875/docs/products/sk-pe/capabilities/SKPE-MED-DES-01-medidas-desempenho.md#L105
[R-BENCH]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L1145
[R-BENCH-DELETE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908220330_govern_platform_measure_reference_deletion.sql#L107
[R-BENCH-LIFE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L1332
[R-CALC]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730080000_create_okrs_key_results_and_strategic_deployment_operations.sql#L346
[R-CAT-DELETE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908220330_govern_platform_measure_reference_deletion.sql#L1
[R-CAT-ELIGIBLE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908135440_govern_measure_reference_catalog_adoption.sql#L101
[R-CAT-WRITE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908170508_govern_platform_measure_reference_catalog.sql#L105
[R-CLOSE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L3584
[R-CLOSE-READY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L2957
[R-DEL-PRIV]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908220402_harden_platform_measure_reference_deletion_privileges.sql#L1
[R-FE02]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-002_GOVERNANCA_VERSIONAMENTO_FORMULACAO.md#L1
[R-FE06]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-006_INDICADORES_METAS_LONGO_PRAZO_BENCHMARKING.md#L1
[R-FE09]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-009_MONITORAMENTO_GOVERNANCA_APRENDIZADO_ESTRATEGICO.md#L1
[R-FORM-CONSTRAINT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L335
[R-FORM-GUARD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L107
[R-IMMUTABLE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L974
[R-IND]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L479
[R-IND-CONSTRAINT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L1455
[R-INVALIDATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L300
[R-LINK]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904213836_govern_sparks_initiative_indicator_links.sql#L1
[R-MEAS-TABLE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L271
[R-MEAS-UNIQUE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L707
[R-MY-SQL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260807013000_create_my_skpe_indicators.sql#L8
[R-OPEN]: https://github.com/br-robson/projetos/blob/30c59b472bdf0b3d0aaab9e0b0246d0f814ed875/docs/products/sk-pe/current-state.md#L409
[R-ORG-READ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260909234252_reconcile_organization_specific_measure_indicators.sql#L25
[R-PACKAGE-LIFE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L2353
[R-READ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260908015851_govern_transversal_measure_performance_context_read.sql#L1
[R-READONLY]: https://github.com/br-robson/projetos/blob/30c59b472bdf0b3d0aaab9e0b0246d0f814ed875/docs/products/sk-pe/capabilities/SKPE-MED-DES-01-medidas-desempenho.md#L195
[R-READY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L1496
[R-RECORD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L1494
[R-RECORD-LIFE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L2525
[R-REOPEN]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L3689
[R-SIGNAL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L952
[R-SUPER-TARGET]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L1085
[R-TARGET]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L835
[R-TEST-ADJ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/parseCanonicalWorkbook.test.ts#L7
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
[R-VIEWS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260904233009_establish_transversal_measures_performance_facade.sql#L98
