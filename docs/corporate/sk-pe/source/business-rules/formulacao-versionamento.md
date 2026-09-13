---
id: sk-pe-formulacao-business-rules
title: Regras de Formulação e Versionamento
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
  - skpe-form-ver-01
  - sk-pe-current-state
tags:
  - sk-pe
  - formulation
  - business-rules
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product
created: 2026-09-12
updated: 2026-09-12
lineage:
  - ./README.md
  - ../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md
---

# Regras de Formulação e Versionamento

Owner único das 34 regras `BR-SKPE-FORM-001` a `BR-SKPE-FORM-034` da capability [SKPE-FORM-VER-01](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md). [Contrato aprovado](README.md#contrato-canônico-de-regra). Produto: d27373cc16740dfc86eb940abf639e322b072cc8; sem delta. `IMPLEMENTED_RULE != CONFIRMED_PRODUCT_RULE`. O documento FE-002 se intitula canônico, mas não foi localizada evidência específica de aceite Product para promover seus predicados. Nenhuma regra é PRODUCT_ACCEPTED nesta wave.

## RULE → FUNCTION

| RULE | TITLE | APPLIES_TO | AUTHORITY_CLASS | ACCEPTANCE_STATUS | TEST_COVERAGE |
| --- | --- | --- | --- | --- | --- |
| [BR-SKPE-FORM-001](#br-skpe-form-001) | Escopo e campos obrigatórios | [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-002](#br-skpe-form-002) | Uma versão aberta por projeto | [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-003](#br-skpe-form-003) | Uma aprovada independente da aberta | [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013); [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-004](#br-skpe-form-004) | Criação independente limitada | [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-005](#br-skpe-form-005) | Autorização organizacional por ação | [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003); [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-012](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-012); [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013); [F-FORM-014](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-014) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-006](#br-skpe-form-006) | Justificativa e auditoria | [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-014](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-014) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-007](#br-skpe-form-007) | Cabeçalho editável | [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-018](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-018) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-008](#br-skpe-form-008) | Congelamento de conteúdo | [F-FORM-018](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-018); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-009](#br-skpe-form-009) | Início de elaboração | [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-010](#br-skpe-form-010) | Submissão de validação | [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-011](#br-skpe-form-011) | Validação formal | [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-012](#br-skpe-form-012) | Devolução contextual | [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-013](#br-skpe-form-013) | Encaminhamento à aprovação | [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-014](#br-skpe-form-014) | Aprovação e substituição atômicas | [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-015](#br-skpe-form-015) | Arquivamento e diagrama divergentes | [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010) | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-FORM-016](#br-skpe-form-016) | Transição desconhecida | [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-017](#br-skpe-form-017) | Origem governada da revisão | [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-018](#br-skpe-form-018) | Clonagem seletiva e remapeada | [F-FORM-012](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-012); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-019](#br-skpe-form-019) | Iniciativas não clonadas | [F-FORM-012](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-012); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-017](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-017) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-020](#br-skpe-form-020) | Valor corrente versus progresso clonado | [F-FORM-012](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-012) | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-FORM-021](#br-skpe-form-021) | Prontidão geral não é aceite | [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-022](#br-skpe-form-022) | Guards complementares obrigatórios | [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-023](#br-skpe-form-023) | Aplicabilidade OKR divergente entre gates | [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009) | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-FORM-024](#br-skpe-form-024) | Listagem não escolhe versão corrente | [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013); [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-025](#br-skpe-form-025) | Resolução UI e lifecycle SQL | [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015); [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013) | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-FORM-026](#br-skpe-form-026) | Escopo de síntese não prova isolamento da versão | [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015) | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-FORM-027](#br-skpe-form-027) | Round-trip do contexto de rota | [F-FORM-016](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-016) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | DIRECT |
| [BR-SKPE-FORM-028](#br-skpe-form-028) | Monitoramento depende de aprovação | [F-FORM-017](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-017) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-029](#br-skpe-form-029) | Vigência separada do horizonte | [F-FORM-019](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-019); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-030](#br-skpe-form-030) | Carimbos de eventos distintos | [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-014](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-014) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-031](#br-skpe-form-031) | Escrita direta e exclusão pública | [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010); [F-FORM-018](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-018) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-032](#br-skpe-form-032) | Concorrência com locks não é merge de edição | [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011) | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FORM-033](#br-skpe-form-033) | Intenção de governança auditada | [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-014](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-014) | DOCUMENTED_RULE | UNKNOWN | NONE |
| [BR-SKPE-FORM-034](#br-skpe-form-034) | Decisão sobre seleção vigente permanece aberta | [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015); [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013) | PENDING_PRODUCT_DECISION | PENDING_PRODUCT_DECISION | NONE |

## Regras detalhadas

### BR-SKPE-FORM-001

**ID:** BR-SKPE-FORM-001 · **TITLE:** Escopo e campos obrigatórios · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011)

**STATEMENT:** Cabeçalho exige organização/projeto existentes, número positivo, rótulo não vazio, status permitido e datas ordenadas quando ambas presentes; unique(project_id,version_number). · **RATIONALE:** Preservar escopo e campos obrigatórios no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Projeto existente · **TRIGGER:** Criar/editar

**CONSTRAINT:** Cabeçalho exige organização/projeto existentes, número positivo, rótulo não vazio, status permitido e datas ordenadas quando ambas presentes; unique(project_id,version_number). · **OUTCOME:** Registro válido ou rejeição · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA]; [CREATE][S-CREATE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-002

**ID:** BR-SKPE-FORM-002 · **TITLE:** Uma versão aberta por projeto · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011)

**STATEMENT:** Índice parcial admite no máximo uma versão entre draft, in_elaboration, pending_validation, validated e pending_approval por projeto. · **RATIONALE:** Preservar uma versão aberta por projeto no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Projeto · **TRIGGER:** Inserção/transição

**CONSTRAINT:** Índice parcial admite no máximo uma versão entre draft, in_elaboration, pending_validation, validated e pending_approval por projeto. · **OUTCOME:** Duplicidade rejeitada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-003

**ID:** BR-SKPE-FORM-003 · **TITLE:** Uma aprovada independente da aberta · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013); [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015)

**STATEMENT:** Índice parcial permite no máximo uma approved por projeto; ela pode coexistir com uma versão aberta. · **RATIONALE:** Preservar uma aprovada independente da aberta no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Projeto · **TRIGGER:** Inserção/transição

**CONSTRAINT:** Índice parcial permite no máximo uma approved por projeto; ela pode coexistir com uma versão aberta. · **OUTCOME:** Approved única; coexistência possível · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-004

**ID:** BR-SKPE-FORM-004 · **TITLE:** Criação independente limitada · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001)

**STATEMENT:** create_skpe_formulation rejeita aberta e histórico com status approved/superseded; cria draft max(version_number)+1, com organização herdada do projeto não arquivado. · **RATIONALE:** Preservar criação independente limitada no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** manage; motivo válido · **TRIGGER:** create_skpe_formulation

**CONSTRAINT:** create_skpe_formulation rejeita aberta e histórico com status approved/superseded; cria draft max(version_number)+1, com organização herdada do projeto não arquivado. · **OUTCOME:** Novo draft · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** ausente → draft

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [CREATE][S-CREATE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-005

**ID:** BR-SKPE-FORM-005 · **TITLE:** Autorização organizacional por ação · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003); [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-012](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-012); [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013); [F-FORM-014](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-014)

**STATEMENT:** Helpers separam view/manage/validate/approve: is_organization_admin ou respectiva module_permission SK-PE. Contrato não exige pessoas diferentes para criar e aprovar. · **RATIONALE:** Preservar autorização organizacional por ação no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Usuário autenticado e escopo · **TRIGGER:** Consulta/operação

**CONSTRAINT:** Helpers separam view/manage/validate/approve: is_organization_admin ou respectiva module_permission SK-PE. Contrato não exige pessoas diferentes para criar e aprovar. · **OUTCOME:** Acesso conforme helper · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [AUTH][S-AUTH]; [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-006

**ID:** BR-SKPE-FORM-006 · **TITLE:** Justificativa e auditoria · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-014](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-014)

**STATEMENT:** RPCs públicas de criação, cabeçalho, revisão e transição exigem motivo aparado com ao menos 10 caracteres e registram alteração em auditoria. · **RATIONALE:** Preservar justificativa e auditoria no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Operação autorizada · **TRIGGER:** Mutação governada

**CONSTRAINT:** RPCs públicas de criação, cabeçalho, revisão e transição exigem motivo aparado com ao menos 10 caracteres e registram alteração em auditoria. · **OUTCOME:** Ação/motivo/ator/antes-depois persistidos · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [REASON][S-REASON]; [CREATE][S-CREATE]; [UPDATE][S-UPDATE]; [REVISION][S-REVISION]; [TRANSITION][S-TRANSITION]; [AUDIT][S-AUDIT] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-007

**ID:** BR-SKPE-FORM-007 · **TITLE:** Cabeçalho editável · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-018](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-018)

**STATEMENT:** update_skpe_formulation bloqueia linha e permite atualização somente em draft/in_elaboration; metadata não nulo deve ser objeto JSON. · **RATIONALE:** Preservar cabeçalho editável no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** manage; versão existente · **TRIGGER:** update_skpe_formulation

**CONSTRAINT:** update_skpe_formulation bloqueia linha e permite atualização somente em draft/in_elaboration; metadata não nulo deve ser objeto JSON. · **OUTCOME:** Cabeçalho atualizado ou erro · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** draft/in_elaboration preservado

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [UPDATE][S-UPDATE]; [GUARD][S-GUARD] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-008

**ID:** BR-SKPE-FORM-008 · **TITLE:** Congelamento de conteúdo · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-018](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-018); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009)

**STATEMENT:** Guard de conteúdo vinculado rejeita inserção/atualização/exclusão fora de draft/in_elaboration; não equivale a proibição universal de toda escrita no banco. · **RATIONALE:** Preservar congelamento de conteúdo no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Tabela com trigger e vínculo · **TRIGGER:** DML de conteúdo

**CONSTRAINT:** Guard de conteúdo vinculado rejeita inserção/atualização/exclusão fora de draft/in_elaboration; não equivale a proibição universal de toda escrita no banco. · **OUTCOME:** Proteção do conteúdo · **EXCEPTIONS:** Registros legados com formulation_id null passam; guard usa NEW em update e OLD em delete · **STATE_TRANSITIONS:** Sem transição

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [GUARD][S-GUARD] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-009

**ID:** BR-SKPE-FORM-009 · **TITLE:** Início de elaboração · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003)

**STATEMENT:** begin_elaboration exige manage e draft e muda para in_elaboration. · **RATIONALE:** Preservar início de elaboração no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** draft; manage; motivo · **TRIGGER:** begin_elaboration

**CONSTRAINT:** begin_elaboration exige manage e draft e muda para in_elaboration. · **OUTCOME:** Data/ator e auditoria · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** draft → in_elaboration

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-010

**ID:** BR-SKPE-FORM-010 · **TITLE:** Submissão de validação · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004)

**STATEMENT:** submit_validation aceita draft/in_elaboration, exige manage, readyForApproval e guards metodológicos. · **RATIONALE:** Preservar submissão de validação no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Estado editável; prontidão · **TRIGGER:** submit_validation

**CONSTRAINT:** submit_validation aceita draft/in_elaboration, exige manage, readyForApproval e guards metodológicos. · **OUTCOME:** Carimbo de submissão · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** draft/in_elaboration → pending_validation

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-011

**ID:** BR-SKPE-FORM-011 · **TITLE:** Validação formal · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006)

**STATEMENT:** validate exige pending_validation, validate permission e nova prontidão. · **RATIONALE:** Preservar validação formal no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** pending_validation; validate · **TRIGGER:** validate

**CONSTRAINT:** validate exige pending_validation, validate permission e nova prontidão. · **OUTCOME:** validated_at/by e notas · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** pending_validation → validated

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-012

**ID:** BR-SKPE-FORM-012 · **TITLE:** Devolução contextual · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007)

**STATEMENT:** return_for_adjustments exige notas >=10 caracteres; validação devolve pending_validation e aprovação devolve pending_approval, cada qual com sua permissão. · **RATIONALE:** Preservar devolução contextual no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Uma das duas pendências · **TRIGGER:** return_for_adjustments

**CONSTRAINT:** return_for_adjustments exige notas >=10 caracteres; validação devolve pending_validation e aprovação devolve pending_approval, cada qual com sua permissão. · **OUTCOME:** Retorno editável com notas · **EXCEPTIONS:** Não limpa automaticamente carimbos anteriores · **STATE_TRANSITIONS:** pending_validation/pending_approval → in_elaboration

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-013

**ID:** BR-SKPE-FORM-013 · **TITLE:** Encaminhamento à aprovação · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008)

**STATEMENT:** submit_approval exige validated, permissão validate e rechecagem de prontidão. · **RATIONALE:** Preservar encaminhamento à aprovação no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** validated; validate · **TRIGGER:** submit_approval

**CONSTRAINT:** submit_approval exige validated, permissão validate e rechecagem de prontidão. · **OUTCOME:** Carimbo de submissão · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** validated → pending_approval

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-014

**ID:** BR-SKPE-FORM-014 · **TITLE:** Aprovação e substituição atômicas · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009)

**STATEMENT:** approve exige pending_approval, approve permission e prontidão; marca outra approved do projeto como superseded antes de aprovar candidata, auditando ambas. · **RATIONALE:** Preservar aprovação e substituição atômicas no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** pending_approval · **TRIGGER:** approve

**CONSTRAINT:** approve exige pending_approval, approve permission e prontidão; marca outra approved do projeto como superseded antes de aprovar candidata, auditando ambas. · **OUTCOME:** Approved única; histórico preservado · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** pending_approval → approved; anterior approved → superseded

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-015

**ID:** BR-SKPE-FORM-015 · **TITLE:** Arquivamento e diagrama divergentes · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010)

**STATEMENT:** RPC archive só aceita draft/in_elaboration; o diagrama FE-002 encadeia Aprovada → Substituída → Arquivada. Não há ação da RPC de superseded para archived. · **RATIONALE:** Preservar arquivamento e diagrama divergentes no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Comparar contrato e requisito · **TRIGGER:** archive

**CONSTRAINT:** RPC archive só aceita draft/in_elaboration; o diagrama FE-002 encadeia Aprovada → Substituída → Arquivada. Não há ação da RPC de superseded para archived. · **OUTCOME:** Divergência preservada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** draft/in_elaboration → archived; superseded → archived não implementada

**AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION]; [DOC][S-DOC] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** FORM-C02 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION: Product deve deliberar sem correção nesta wave · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-016

**ID:** BR-SKPE-FORM-016 · **TITLE:** Transição desconhecida · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-003](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-003); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010)

**STATEMENT:** Ação é normalizada com lower/trim; ação fora das sete aceitas gera 22023; origem inválida gera 55000. · **RATIONALE:** Preservar transição desconhecida no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Versão existente · **TRIGGER:** transition_skpe_formulation

**CONSTRAINT:** Ação é normalizada com lower/trim; ação fora das sete aceitas gera 22023; origem inválida gera 55000. · **OUTCOME:** Rejeição; nenhuma transição válida inferida · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-017

**ID:** BR-SKPE-FORM-017 · **TITLE:** Origem governada da revisão · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011)

**STATEMENT:** Revisão exige origem approved/superseded, mesma organização/projeto herdados e inexistência de outra approved e de versão aberta; registra derived_from e max+1. · **RATIONALE:** Preservar origem governada da revisão no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** manage; origem válida; motivo · **TRIGGER:** create_skpe_formulation_revision

**CONSTRAINT:** Revisão exige origem approved/superseded, mesma organização/projeto herdados e inexistência de outra approved e de versão aberta; registra derived_from e max+1. · **OUTCOME:** Novo draft com proveniência · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** origem preservada; novo draft

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [REVISION][S-REVISION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-018

**ID:** BR-SKPE-FORM-018 · **TITLE:** Clonagem seletiva e remapeada · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-012](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-012); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011)

**STATEMENT:** Clone copia identidade/valores, inputs ativos e snapshots, temas/perspectivas/objetivos/relações, ciclos/OKRs/KRs, indicadores/metas/benchmarks; remapeia IDs por códigos e filtra archived/cancelled/superseded conforme entidade. · **RATIONALE:** Preservar clonagem seletiva e remapeada no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Origem approved/superseded; destino editável; mesmo escopo · **TRIGGER:** clone_skpe_formulation_content

**CONSTRAINT:** Clone copia identidade/valores, inputs ativos e snapshots, temas/perspectivas/objetivos/relações, ciclos/OKRs/KRs, indicadores/metas/benchmarks; remapeia IDs por códigos e filtra archived/cancelled/superseded conforme entidade. · **OUTCOME:** Conteúdo derivado; não cópia byte a byte · **EXCEPTIONS:** Helper é concedido a authenticated; não assumir destino novo ou idempotência fora da RPC de revisão · **STATE_TRANSITIONS:** Diversos estados retornam draft; perspectivas active

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [CLONE][S-CLONE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-019

**ID:** BR-SKPE-FORM-019 · **TITLE:** Iniciativas não clonadas · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-012](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-012); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-017](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-017)

**STATEMENT:** Clone retorna initiativesCloned=0 e initiativesRequireRelinking=true; iniciativas e execução histórica não são copiadas por essa função. · **RATIONALE:** Preservar iniciativas não clonadas no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Revisão · **TRIGGER:** Clone

**CONSTRAINT:** Clone retorna initiativesCloned=0 e initiativesRequireRelinking=true; iniciativas e execução histórica não são copiadas por essa função. · **OUTCOME:** Religação futura necessária · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [CLONE][S-CLONE]; [DOC][S-DOC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-020

**ID:** BR-SKPE-FORM-020 · **TITLE:** Valor corrente versus progresso clonado · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-012](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-012)

**STATEMENT:** SQL zera progress do KR, mas copia kr.current_value; FE-002 diz que progresso operacional anterior não é clonado. A semântica de valor transportado demanda decisão. · **RATIONALE:** Preservar valor corrente versus progresso clonado no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** KR elegível na origem · **TRIGGER:** Clone

**CONSTRAINT:** SQL zera progress do KR, mas copia kr.current_value; FE-002 diz que progresso operacional anterior não é clonado. A semântica de valor transportado demanda decisão. · **OUTCOME:** Distinção registrada; não zerar por inferência · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [CLONE][S-CLONE]; [DOC][S-DOC] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** FORM-C03 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION: Product deve deliberar sem correção nesta wave · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-021

**ID:** BR-SKPE-FORM-021 · **TITLE:** Prontidão geral não é aceite · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009)

**STATEMENT:** readyForApproval é blocking_count=0: missão, visão, valores, insumos, temas, objetivos/KPI/meta e OKRs/KRs possuem predicados; recomendações não somam bloqueios. SQL não demonstra aceite Product. · **RATIONALE:** Preservar prontidão geral não é aceite no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** view; versão existente · **TRIGGER:** get_skpe_formulation_readiness

**CONSTRAINT:** readyForApproval é blocking_count=0: missão, visão, valores, insumos, temas, objetivos/KPI/meta e OKRs/KRs possuem predicados; recomendações não somam bloqueios. SQL não demonstra aceite Product. · **OUTCOME:** JSON de pendências; sem transição · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [READY][S-READY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-022

**ID:** BR-SKPE-FORM-022 · **TITLE:** Guards complementares obrigatórios · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004)

**STATEMENT:** Mudanças para pending_validation/validated/pending_approval/approved disparam guards: identidade validada; negócio pronto; mapa e medidas prontos/validados; OKR se habilitado; pacote iniciativas existente/pronto; monitoramento pronto. · **RATIONALE:** Preservar guards complementares obrigatórios no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Mudança de status · **TRIGGER:** Triggers before update

**CONSTRAINT:** Mudanças para pending_validation/validated/pending_approval/approved disparam guards: identidade validada; negócio pronto; mapa e medidas prontos/validados; OKR se habilitado; pacote iniciativas existente/pronto; monitoramento pronto. · **OUTCOME:** Falha de qualquer guard impede avanço · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [IDENTITY][S-IDENTITY]; [BUSINESS][S-BUSINESS]; [MAP][S-MAP]; [MEASURES][S-MEASURES]; [OKR][S-OKR]; [INITIATIVES][S-INITIATIVES]; [MONITOR][S-MONITOR] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-023

**ID:** BR-SKPE-FORM-023 · **TITLE:** Aplicabilidade OKR divergente entre gates · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-004](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-004); [F-FORM-005](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-005); [F-FORM-006](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-006); [F-FORM-008](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-008); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009)

**STATEMENT:** Guard FE-06 condiciona validação a okrEnabled; readiness geral exige OKRs e ao menos três KRs por OKR sem consultar esse flag. O efeito combinado não deve ser tratado como dispensa automática de OKR. · **RATIONALE:** Preservar aplicabilidade okr divergente entre gates no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Comparação de gates · **TRIGGER:** Avaliação de prontidão

**CONSTRAINT:** Guard FE-06 condiciona validação a okrEnabled; readiness geral exige OKRs e ao menos três KRs por OKR sem consultar esse flag. O efeito combinado não deve ser tratado como dispensa automática de OKR. · **OUTCOME:** Conflito de aplicabilidade preservado · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [READY][S-READY]; [OKR][S-OKR] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** FORM-C04 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION: Product deve deliberar sem correção nesta wave · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-024

**ID:** BR-SKPE-FORM-024 · **TITLE:** Listagem não escolhe versão corrente · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013); [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015)

**STATEMENT:** get_skpe_formulations retorna todas as versões no escopo e flags is_open/is_editable/is_immutable; ordenação desc não declara current. · **RATIONALE:** Preservar listagem não escolhe versão corrente no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** view organização · **TRIGGER:** get_skpe_formulations

**CONSTRAINT:** get_skpe_formulations retorna todas as versões no escopo e flags is_open/is_editable/is_immutable; ordenação desc não declara current. · **OUTCOME:** Lista com origem e estados · **EXCEPTIONS:** is_immutable só approved/superseded/archived; intermediários são não editáveis sem essa flag · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [LIST][S-LIST] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-025

**ID:** BR-SKPE-FORM-025 · **TITLE:** Resolução UI e lifecycle SQL · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015); [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013)

**STATEMENT:** UI consulta draft/under_review/approved e exige exatamente um resultado; SQL não possui under_review e permite aberta+approved. Não há mapeamento canônico para suprir estados omitidos. · **RATIONALE:** Preservar resolução ui e lifecycle sql no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Organização/projeto · **TRIGGER:** Consulta do selector

**CONSTRAINT:** UI consulta draft/under_review/approved e exige exatamente um resultado; SQL não possui under_review e permite aberta+approved. Não há mapeamento canônico para suprir estados omitidos. · **OUTCOME:** Contexto pode ser null ou excluir elaboração/validação · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** documento/frontend/SQL conforme fonte · **SOURCE_EVIDENCE:** [UI][S-UI]; [TABS][S-TABS]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** APPLICATION_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** FORM-C01 (C02 da baseline) · **PENDING_DECISION:** OPEN_PRODUCT_DECISION: Product deve deliberar sem correção nesta wave · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-026

**ID:** BR-SKPE-FORM-026 · **TITLE:** Escopo de síntese não prova isolamento da versão · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015)

**STATEMENT:** Consultas de identidade e contagens nas abas usam organização/projeto sem formulation_id, enquanto pacotes usam a versão resolvida. Síntese por projeto não comprova síntese da versão vigente. · **RATIONALE:** Preservar escopo de síntese não prova isolamento da versão no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Mais de uma versão no projeto · **TRIGGER:** Carregar síntese

**CONSTRAINT:** Consultas de identidade e contagens nas abas usam organização/projeto sem formulation_id, enquanto pacotes usam a versão resolvida. Síntese por projeto não comprova síntese da versão vigente. · **OUTCOME:** Isolamento documental não declarado · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** documento/frontend/SQL conforme fonte · **SOURCE_EVIDENCE:** [UI][S-UI]; [TABS][S-TABS]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** APPLICATION_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** FORM-C05 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION: Product deve deliberar sem correção nesta wave · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-027

**ID:** BR-SKPE-FORM-027 · **TITLE:** Round-trip do contexto de rota · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-016](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-016)

**STATEMENT:** Gerador/parser preservam organizationId, projectId e formulationId com codificação de caracteres; seção desconhecida retorna unknown. IDs na URL não validam estado ou acesso. · **RATIONALE:** Preservar round-trip do contexto de rota no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** IDs fornecidos · **TRIGGER:** Gerar/interpretar rota

**CONSTRAINT:** Gerador/parser preservam organizationId, projectId e formulationId com codificação de caracteres; seção desconhecida retorna unknown. IDs na URL não validam estado ou acesso. · **OUTCOME:** Contexto recuperado · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** CODE_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** DIRECT · **TEST_EVIDENCE:** apps/web/tests/skpeRoutes.test.ts: asserts de round-trip/encoding e seção desconhecida; 5/5 PASS nesta wave

**SOURCE_TYPE:** frontend; teste · **SOURCE_EVIDENCE:** [ROUTE][S-ROUTE]; [ROUTE-TEST][S-ROUTE-TEST] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** APPLICATION_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-028

**ID:** BR-SKPE-FORM-028 · **TITLE:** Monitoramento depende de aprovação · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-017](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-017)

**STATEMENT:** open_skpe_monitoring_cycle exige status approved e permissão manage de monitoramento; ciclos se vinculam a formulation_id, não são o próprio número da versão. · **RATIONALE:** Preservar monitoramento depende de aprovação no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Versão aprovada; pacote e payload válidos · **TRIGGER:** Abrir ciclo

**CONSTRAINT:** open_skpe_monitoring_cycle exige status approved e permissão manage de monitoramento; ciclos se vinculam a formulation_id, não são o próprio número da versão. · **OUTCOME:** Ciclo da versão; formulação inalterada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [MONITOR][S-MONITOR] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-029

**ID:** BR-SKPE-FORM-029 · **TITLE:** Vigência separada do horizonte · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-019](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-019); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002)

**STATEMENT:** Contrato temporal final valida vínculo da formulação opcional ao projeto, mas delega período ao horizonte estratégico; valid_from/valid_until da formulação não alteram esse período. · **RATIONALE:** Preservar vigência separada do horizonte no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Projeto e vínculo válidos · **TRIGGER:** Resolver período

**CONSTRAINT:** Contrato temporal final valida vínculo da formulação opcional ao projeto, mas delega período ao horizonte estratégico; valid_from/valid_until da formulação não alteram esse período. · **OUTCOME:** Horizonte canônico; vigência institucional separada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [TEMPORAL][S-TEMPORAL] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-030

**ID:** BR-SKPE-FORM-030 · **TITLE:** Carimbos de eventos distintos · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-007](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-007); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-014](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-014)

**STATEMENT:** created_at é criação, updated_at recebe trigger de atualização; approved_at, superseded_at e archived_at registram eventos distintos; status_changed_at/by registra última transição. · **RATIONALE:** Preservar carimbos de eventos distintos no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Operação correspondente · **TRIGGER:** Evento de lifecycle

**CONSTRAINT:** created_at é criação, updated_at recebe trigger de atualização; approved_at, superseded_at e archived_at registram eventos distintos; status_changed_at/by registra última transição. · **OUTCOME:** Histórico temporal; não selecionar current pelo maior timestamp · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA]; [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-031

**ID:** BR-SKPE-FORM-031 · **TITLE:** Escrita direta e exclusão pública · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-010](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-010); [F-FORM-018](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-018)

**STATEMENT:** Foundation revoga insert/update/delete de authenticated e concede leitura RLS; FE-01 expõe RPCs governadas e não expõe delete de formulação. Isso não prova impossibilidade de exclusão privilegiada/cascata. · **RATIONALE:** Preservar escrita direta e exclusão pública no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Papel authenticated · **TRIGGER:** Escrita direta

**CONSTRAINT:** Foundation revoga insert/update/delete de authenticated e concede leitura RLS; FE-01 expõe RPCs governadas e não expõe delete de formulação. Isso não prova impossibilidade de exclusão privilegiada/cascata. · **OUTCOME:** Sem operação de exclusão funcional localizada · **EXCEPTIONS:** FKs de projeto/organização usam cascade; referências de objetivos/KRs usam restrict; service_role fora desta garantia · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [ACL][S-ACL]; [GRANT][S-GRANT]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-032

**ID:** BR-SKPE-FORM-032 · **TITLE:** Concorrência com locks não é merge de edição · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-009](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-009); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011)

**STATEMENT:** Criação/revisão usam advisory lock por projeto e numeração única; update/transição bloqueiam linha. Não há parâmetro expected_updated_at para detectar edição obsoleta no update. · **RATIONALE:** Preservar concorrência com locks não é merge de edição no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Operações concorrentes · **TRIGGER:** RPCs

**CONSTRAINT:** Criação/revisão usam advisory lock por projeto e numeração única; update/transição bloqueiam linha. Não há parâmetro expected_updated_at para detectar edição obsoleta no update. · **OUTCOME:** Serialização/constraints; não afirmar resolução de conflito de conteúdo · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** SQL; documento · **SOURCE_EVIDENCE:** [CREATE][S-CREATE]; [UPDATE][S-UPDATE]; [REVISION][S-REVISION]; [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-033

**ID:** BR-SKPE-FORM-033 · **TITLE:** Intenção de governança auditada · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-001](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-001); [F-FORM-002](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-002); [F-FORM-011](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-011); [F-FORM-014](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-014)

**STATEMENT:** FE-002 descreve operações relevantes por funções auditadas/autorizadas e formulação multiprojeto/multiorganização; rótulo interno de regras canônicas não comprova aprovação Product localizada. · **RATIONALE:** Preservar intenção de governança auditada no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** Requisito histórico · **TRIGGER:** Leitura documental

**CONSTRAINT:** FE-002 descreve operações relevantes por funções auditadas/autorizadas e formulação multiprojeto/multiorganização; rótulo interno de regras canônicas não comprova aprovação Product localizada. · **OUTCOME:** Intenção documentada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** DOCUMENTED_RULE · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** UNKNOWN · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** documento/frontend/SQL conforme fonte · **SOURCE_EVIDENCE:** [DOC][S-DOC] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** governança e versionamento

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

### BR-SKPE-FORM-034

**ID:** BR-SKPE-FORM-034 · **TITLE:** Decisão sobre seleção vigente permanece aberta · **CAPABILITY:** SKPE-FORM-VER-01 · **APPLIES_TO:** [F-FORM-015](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-015); [F-FORM-013](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#f-form-013)

**STATEMENT:** Reconciliar UI, estados SQL e contexto versionado exige decisão Product no tratamento do B10/C02; nenhuma correção ou mapeamento é autorizado por este catálogo. · **RATIONALE:** Preservar decisão sobre seleção vigente permanece aberta no escopo evidenciado; descrição técnica não constitui decisão Product

**ENTITIES:** Formulação Estratégica; dependências citadas · **PRECONDITIONS:** B10/C02 da baseline · **TRIGGER:** Retomada funcional futura

**CONSTRAINT:** Reconciliar UI, estados SQL e contexto versionado exige decisão Product no tratamento do B10/C02; nenhuma correção ou mapeamento é autorizado por este catálogo. · **OUTCOME:** OPEN_PRODUCT_DECISION · **EXCEPTIONS:** Nenhuma exceção adicional localizada no contrato citado · **STATE_TRANSITIONS:** N/A

**AUTHORITY_CLASS:** PENDING_PRODUCT_DECISION · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: não há aceite Product específico comprovado nesta investigação

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum teste específico localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** documento/frontend/SQL conforme fonte · **SOURCE_EVIDENCE:** [UI][S-UI]; [SCHEMA][S-SCHEMA]; [DOC][S-DOC] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** governança e versionamento

**CONFLICTS:** FORM-C01 (C02 da baseline) · **PENDING_DECISION:** OPEN_PRODUCT_DECISION: Product deve deliberar sem correção nesta wave · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; runtime não observado

## Integridade

A [instalação dos triggers de conteúdo](https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L1629-L1666) enumera 16 tabelas protegidas. A garantia aqui é do SQL versionado; implantação e acessos privilegiados não foram auditados.

| Questão | Conclusão delimitada | ENFORCEMENT | RULE |
| --- | --- | --- | --- |
| Unicidade ativa/drafts | Uma aberta, uma approved por projeto; podem coexistir | DATABASE_ENFORCED | [BR-SKPE-FORM-002](#br-skpe-form-002); [BR-SKPE-FORM-003](#br-skpe-form-003) |
| Organização/projeto | FKs no cabeçalho independentes; RPC herda organização do projeto. Não afirmar FK composta de coerência no cabeçalho | DATABASE_ENFORCED nas RPCs | [BR-SKPE-FORM-001](#br-skpe-form-001) |
| Imutabilidade | Guards em tabelas vinculadas e assert; não garantia para escrita privilegiada ou vínculo legado null | DATABASE_ENFORCED delimitado | [BR-SKPE-FORM-008](#br-skpe-form-008) |
| Exclusão | Sem RPC pública de delete; ACL revoga DML; cascatas/restrict coexistem | DATABASE_ENFORCED delimitado | [BR-SKPE-FORM-031](#br-skpe-form-031) |
| Concorrência | Locks e índices; sem contrato de edição otimista expected_updated_at | DATABASE_ENFORCED; NOT_ENFORCED para comparação de revisão do cliente | [BR-SKPE-FORM-032](#br-skpe-form-032) |
| Campos/transições | Rótulo, motivo, datas, objeto metadata; estados e permissões | DATABASE_ENFORCED | [BR-SKPE-FORM-001](#br-skpe-form-001); [BR-SKPE-FORM-006](#br-skpe-form-006); [BR-SKPE-FORM-016](#br-skpe-form-016) |
| Pré-aprovação | Readiness geral mais guards independentes; flags de UI não aprovam | DATABASE_ENFORCED | [BR-SKPE-FORM-021](#br-skpe-form-021); [BR-SKPE-FORM-022](#br-skpe-form-022) |
| Ciclo | Cabeçalho não tem cycle_id; ciclos filhos apontam formulation_id | DATABASE_ENFORCED nos vínculos | [BR-SKPE-FORM-028](#br-skpe-form-028) |

## Regras temporais

| Semântica | Campos/contrato | Interpretação |
| --- | --- | --- |
| CREATED | created_at/by | Criação do registro; revisão tem criação própria |
| UPDATED | updated_at/by; trigger set_updated_at | Atualização do registro, não início de vigência |
| APPROVED | approved_at/by; submitted_for_approval_at/by | Submissão e aprovação são eventos diferentes |
| EFFECTIVE | valid_from / valid_until | Vigência institucional; campos effective_from/effective_to não localizados no cabeçalho |
| CURRENT | status approved no consumidor PEM; não há is_current no cabeçalho | Não inferir versão corrente pelo maior version_number ou created_at |
| HISTORICAL | derived_from_formulation_id; superseded_at/by; archived_at/by | Origem, substituição e arquivo são fatos separados |
| STATUS | status_changed_at/by; validated_at/by; submitted_for_validation_at/by | Devolução não apaga carimbos prévios; auditoria explica sequência |

[SCHEMA][S-SCHEMA]; [TRANSITION][S-TRANSITION]; [TEMPORAL][S-TEMPORAL]; [PEM][S-PEM]

## Testes e dívida de qualidade

Busca dirigida por formulation/formulação, estados e nomes das RPCs em apps/web/tests e supabase/tests. skpeRoutes.test.ts contém asserts diretos de round-trip dos IDs, encoding e rejeição de seção: BR-SKPE-FORM-027 recebe DIRECT; execução com node --experimental-strip-types --test retornou 5 PASS/0 FAIL. Isso não testa seleção vigente, permissões, lifecycle ou banco.

Fixtures de Formulação em strategic-map-adapter.test.ts e strategic-bsc-layout.test.ts exercitam layout/mapa; parseCanonicalWorkbook.test.ts contém rótulo de fase. Não demonstram cobertura direta ou indireta das regras de versionamento. Demais regras: NONE no escopo versionado pesquisado. Testes externos e validação autenticada não examinados. Dívida explícita: transições válidas/inválidas, concorrência, clone, guards, RLS e divergências de seleção. Nenhum teste SQL ou ambiente foi executado.

[ROUTE-TEST][S-ROUTE-TEST]

## Conflitos

Fonte Corporate da pendência original: [B10/C02 no current-state](../current-state.md). O título de regra canônica no requisito histórico não substitui decisão Product identificada.

[Conflitos, funções e evidências](../capabilities/SKPE-FORM-VER-01-formulacao-versionamento.md#conflitos-e-retomada). FORM-C01 é aprofundamento de C02/B10, não uma decisão nova. Todos permanecem OPEN_PRODUCT_DECISION; nenhuma correção é prescrita como aceite.

[S-AUTH]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L167-L237
[S-SCHEMA]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L304-L385
[S-GUARD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L107-L200
[S-CLONE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L206-L1083
[S-CREATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L1088-L1227
[S-UPDATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L1233-L1310
[S-REVISION]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L1316-L1476
[S-TRANSITION]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L1482-L1788
[S-LIST]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L1793-L1880
[S-AUDIT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L1882-L1934
[S-ACL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L2219-L2489
[S-GRANT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L1958-L2012
[S-READY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L1743-L2117
[S-REASON]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727024500_create_operational_functions_for_initiatives_artifacts_checklists.sql#L59-L73
[S-IDENTITY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L1191-L1243
[S-BUSINESS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L2392-L2435
[S-MAP]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730060000_create_strategic_themes_perspectives_and_objectives_operations.sql#L2522-L2574
[S-MEASURES]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730070000_create_strategic_indicators_targets_and_benchmarking_operations.sql#L2570-L2619
[S-OKR]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730080000_create_okrs_key_results_and_strategic_deployment_operations.sql#L3289-L3330
[S-INITIATIVES]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730090000_create_strategic_initiatives_portfolio_and_action_plans.sql#L5283-L5323
[S-MONITOR]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730100000_create_strategic_monitoring_governance_and_learning.sql#L1373-L1460
[S-TEMPORAL]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260818031435_gate_17_b4c3_temporal_semantic_correction.sql#L135-L198
[S-PEM]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260818132823_skpe_pem02_gate_governance_convergence.sql#L167-L189
[S-UI]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicFormulationSection.tsx#L52-L222
[S-TABS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicFormulationStatusTabs.tsx#L36-L222
[S-ROUTE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/app/skpeRoutes.ts#L90-L168
[S-ROUTE-TEST]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/skpeRoutes.test.ts#L1-L121
[S-DOC]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-002_GOVERNANCA_VERSIONAMENTO_FORMULACAO.md#L1-L113
