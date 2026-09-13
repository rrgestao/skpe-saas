---
id: sk-pe-identidade-business-rules
title: Regras de Identidade Estratégica
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
  - skpe-ident-01
  - skpe-form-ver-01
  - sk-pe-current-state
tags:
  - sk-pe
  - strategic-identity
  - business-rules
language: pt-BR
encoding: UTF-8
semantic_layer: canonical-product
created: 2026-09-12
updated: 2026-09-12
lineage:
  - ./README.md
  - ../capabilities/SKPE-IDENT-01-identidade-estrategica.md
---

# Regras de Identidade Estratégica

Owner único de 28 regras locais de [SKPE-IDENT-01](../capabilities/SKPE-IDENT-01-identidade-estrategica.md). [Contrato de campos e enums](README.md#contrato-canônico-de-regra). Produto d27373cc16740dfc86eb940abf639e322b072cc8; sem delta. `IMPLEMENTED_RULE != CONFIRMED_PRODUCT_RULE`. Nenhuma regra recebe PRODUCT_ACCEPTED por existir no SQL ou num requisito que se denomina canônico. Não foi localizada decisão Product específica que sustente promoção nesta investigação.

## Natureza metodológica e autoridade

RULE_KIND é eixo adicional de natureza: PRODUCT_RULE descreve contrato de produto; METHODOLOGICAL_RULE descreve requisito do método; IMPLEMENTATION_RULE descreve mecanismo. Não substitui AUTHORITY_CLASS: uma PRODUCT_RULE pode ser apenas implementada ou conflitante, sem autoridade Product confirmada.

Propósito opcional; missão/visão obrigatórias para prontidão; valores e comportamentos mínimos nos predicados. Nenhum teto de valores/comportamentos ou limite superior de tamanho textual foi localizado. Ordem é display_order, não sequência metodológica obrigatória. Texto não vazio não prova observabilidade do comportamento nem qualidade de missão/visão. A visão é de longo prazo no documento, mas não tem coluna de horizonte própria. Não usar os sete valores de uma fixture de planilha como regra geral do produto.

Posicionamento, premissas, direcionadores e narrativa estratégica não foram encontrados como entidades/operações autônomas nas quatro tabelas/RPCs FE-02 examinadas. Declaração de coerência e rationale não devem ser renomeados para inventar essas funcionalidades. Diagnóstico não aparece como pré-condição da edição de identidade. Não se conclui ausência global desses conceitos em outras capabilities.

[METHOD][S-METHOD]; [DOC][S-DOC]; [SCHEMA][S-SCHEMA]; [READY][S-READY]

## RULE → FUNCTION

| RULE | TITLE | APPLIES_TO | RULE_KIND | AUTHORITY_CLASS | ACCEPTANCE_STATUS | TEST_COVERAGE |
| --- | --- | --- | --- | --- | --- | --- |
| [BR-SKPE-IDENT-001](#br-skpe-ident-001) | Escopo e cardinalidade do pacote | [F-IDENT-001](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-001); [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-019](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-019) | PRODUCT_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-002](#br-skpe-ident-002) | Tipos e unicidade dos elementos | [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-007](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-007) | PRODUCT_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-003](#br-skpe-ident-003) | Formato de conteúdo e ordenação | [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-004](#br-skpe-ident-004) | Propósito opcional | [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-005](#br-skpe-ident-005) | Missão e visão obrigatórias para validação | [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-006](#br-skpe-ident-006) | Significado e código de valor | [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-007](#br-skpe-ident-007) | Situações de valor | [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-009](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-009) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-008](#br-skpe-ident-008) | Contrato do comportamento | [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-009](#br-skpe-ident-009) | Comportamento esperado mínimo | [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-010](#br-skpe-ident-010) | Comportamento incompatível mínimo | [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-011](#br-skpe-ident-011) | Valor ativo versus não arquivado | [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014) | METHODOLOGICAL_RULE | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-IDENT-012](#br-skpe-ident-012) | Declaração de coerência livre | [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-013](#br-skpe-ident-013) | Invalidação do pacote nas mutações | [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-007](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-007); [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-009](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-009); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011); [F-IDENT-019](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-019) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-014](#br-skpe-ident-014) | Submissão do pacote | [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-015](#br-skpe-ident-015) | Validação e permissões acumuladas | [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-016](#br-skpe-ident-016) | Devolução para ajustes | [F-IDENT-015](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-015) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-017](#br-skpe-ident-017) | Aprovação do pacote não equivale à da Formulação | [F-IDENT-002](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-002); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014); [F-IDENT-017](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-017); [F-IDENT-018](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-018) | PRODUCT_RULE | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-IDENT-018](#br-skpe-ident-018) | Consulta consolidada não filtra por aprovação | [F-IDENT-001](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-001) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-019](#br-skpe-ident-019) | Exibição parcial na UI | [F-IDENT-001](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-001); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-020](#br-skpe-ident-020) | Fallback legado não comprova identidade vigente | [F-IDENT-002](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-002); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014) | PRODUCT_RULE | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-IDENT-021](#br-skpe-ident-021) | Completude formal não é validação semântica | [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-022](#br-skpe-ident-022) | Sentido metodológico da visão | [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012) | METHODOLOGICAL_RULE | DOCUMENTED_RULE | UNKNOWN | NONE |
| [BR-SKPE-IDENT-023](#br-skpe-ident-023) | Identidade orienta a cadeia metodológica | [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-018](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-018) | METHODOLOGICAL_RULE | DOCUMENTED_RULE | UNKNOWN | NONE |
| [BR-SKPE-IDENT-024](#br-skpe-ident-024) | Histórico por evidência da versão | [F-IDENT-016](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-016); [F-IDENT-007](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-007); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-025](#br-skpe-ident-025) | Exclusão e completude posterior | [F-IDENT-007](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-007); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-026](#br-skpe-ident-026) | Helper interno e usuário autenticado | [F-IDENT-019](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-019); [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-IDENT-027](#br-skpe-ident-027) | Opcionalidade histórica dos comportamentos | [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014) | METHODOLOGICAL_RULE | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-IDENT-028](#br-skpe-ident-028) | Decisão de lifecycle e leitura pendente | [F-IDENT-001](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-001); [F-IDENT-002](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-002); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014); [F-IDENT-018](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-018) | PRODUCT_RULE | PENDING_PRODUCT_DECISION | PENDING_PRODUCT_DECISION | NONE |

## Regras detalhadas

### BR-SKPE-IDENT-001

**ID:** BR-SKPE-IDENT-001 · **TITLE:** Escopo e cardinalidade do pacote · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-001](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-001); [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-019](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-019)

**STATEMENT:** Pacote tem formulation_id obrigatório e único; FK composta assegura organização/projeto/versão. Filhos têm vínculos compostos ao pacote ou valor; não há identidade independente da Formulação nesse schema. · **RATIONALE:** Tornar explícito o contrato de escopo e cardinalidade do pacote sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Versão existente · **TRIGGER:** Persistir pacote/filhos

**CONSTRAINT:** Pacote tem formulation_id obrigatório e único; FK composta assegura organização/projeto/versão. Filhos têm vínculos compostos ao pacote ou valor; não há identidade independente da Formulação nesse schema. · **OUTCOME:** 0..1 pacote por versão; vínculo coerente · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-002

**ID:** BR-SKPE-IDENT-002 · **TITLE:** Tipos e unicidade dos elementos · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-007](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-007)

**STATEMENT:** Itens aceitam somente purpose, mission e vision; unique(formulation_id,element_type) permite no máximo um de cada por versão. · **RATIONALE:** Tornar explícito o contrato de tipos e unicidade dos elementos sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Identidade existente · **TRIGGER:** Salvar item

**CONSTRAINT:** Itens aceitam somente purpose, mission e vision; unique(formulation_id,element_type) permite no máximo um de cada por versão. · **OUTCOME:** Até três elementos PMV · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA]; [ITEM][S-ITEM] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-003

**ID:** BR-SKPE-IDENT-003 · **TITLE:** Formato de conteúdo e ordenação · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005)

**STATEMENT:** Upsert exige texto não vazio após trim; ordem explícita negativa é rejeitada; metadata fornecido deve ser objeto. display_order não impõe ordem metodológica fixa nem avalia qualidade semântica. · **RATIONALE:** Tornar explícito o contrato de formato de conteúdo e ordenação sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Formulação editável · **TRIGGER:** upsert_skpe_identity_item

**CONSTRAINT:** Upsert exige texto não vazio após trim; ordem explícita negativa é rejeitada; metadata fornecido deve ser objeto. display_order não impõe ordem metodológica fixa nem avalia qualidade semântica. · **OUTCOME:** Item draft salvo ou rejeitado · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** item → draft

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [ITEM][S-ITEM]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-004

**ID:** BR-SKPE-IDENT-004 · **TITLE:** Propósito opcional · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014)

**STATEMENT:** Ausência de purpose gera informação PURPOSE_OPTIONAL, sem bloqueio de prontidão. · **RATIONALE:** Tornar explícito o contrato de propósito opcional sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Avaliar prontidão · **TRIGGER:** get_skpe_identity_readiness

**CONSTRAINT:** Ausência de purpose gera informação PURPOSE_OPTIONAL, sem bloqueio de prontidão. · **OUTCOME:** Prontidão pode ser verdadeira sem propósito · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [READY][S-READY]; [DOC][S-DOC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-005

**ID:** BR-SKPE-IDENT-005 · **TITLE:** Missão e visão obrigatórias para validação · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014)

**STATEMENT:** Readiness bloqueia ausência de mission ou vision; existência de texto, não avaliação de significado, é o predicado implementado. · **RATIONALE:** Tornar explícito o contrato de missão e visão obrigatórias para validação sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Avaliar prontidão · **TRIGGER:** Submeter/validar

**CONSTRAINT:** Readiness bloqueia ausência de mission ou vision; existência de texto, não avaliação de significado, é o predicado implementado. · **OUTCOME:** Ausência bloqueia; pode salvar rascunho incompleto · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [READY][S-READY]; [SCHEMA][S-SCHEMA]; [DOC][S-DOC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-006

**ID:** BR-SKPE-IDENT-006 · **TITLE:** Significado e código de valor · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008)

**STATEMENT:** Valor exige código, nome e descrição não vazios; código é único por Formulação. Atualização exige target_value_id da versão; ausência do ID tenta inserir, não resolve por código. · **RATIONALE:** Tornar explícito o contrato de significado e código de valor sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Formulação editável · **TRIGGER:** upsert_skpe_strategic_value

**CONSTRAINT:** Valor exige código, nome e descrição não vazios; código é único por Formulação. Atualização exige target_value_id da versão; ausência do ID tenta inserir, não resolve por código. · **OUTCOME:** Valor salvo ou unicidade rejeitada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [VALUE][S-VALUE]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-007

**ID:** BR-SKPE-IDENT-007 · **TITLE:** Situações de valor · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-009](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-009)

**STATEMENT:** Upsert aceita draft/active/archived e pode reativar registro archived com ID; archive apenas marca status e reabre pacote, sem excluir comportamentos. · **RATIONALE:** Tornar explícito o contrato de situações de valor sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Formulação editável e valor do escopo · **TRIGGER:** Upsert/archive

**CONSTRAINT:** Upsert aceita draft/active/archived e pode reativar registro archived com ID; archive apenas marca status e reabre pacote, sem excluir comportamentos. · **OUTCOME:** Status atualizado; pacote in_elaboration · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** draft/active/archived → status pedido; archive → archived

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [VALUE][S-VALUE]; [ARCHIVE][S-ARCHIVE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-008

**ID:** BR-SKPE-IDENT-008 · **TITLE:** Contrato do comportamento · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010)

**STATEMENT:** Tipo é expected ou incompatible; descrição não vazia; ordem não negativa na RPC; metadata objeto; atualização exige behavior_id pertencente ao valor e rejeita valor archived. · **RATIONALE:** Tornar explícito o contrato de contrato do comportamento sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Valor não arquivado; Formulação editável · **TRIGGER:** upsert_skpe_value_behavior

**CONSTRAINT:** Tipo é expected ou incompatible; descrição não vazia; ordem não negativa na RPC; metadata objeto; atualização exige behavior_id pertencente ao valor e rejeita valor archived. · **OUTCOME:** Descrição vinculada; pacote reaberto · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [BEHAVIOR][S-BEHAVIOR]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-009

**ID:** BR-SKPE-IDENT-009 · **TITLE:** Comportamento esperado mínimo · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014)

**STATEMENT:** Cada valor não arquivado deve ter ao menos um comportamento expected para prontidão; não há teto de quantidade no schema examinado. · **RATIONALE:** Tornar explícito o contrato de comportamento esperado mínimo sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Valores não arquivados · **TRIGGER:** Avaliar prontidão

**CONSTRAINT:** Cada valor não arquivado deve ter ao menos um comportamento expected para prontidão; não há teto de quantidade no schema examinado. · **OUTCOME:** Ausência bloqueia · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [READY][S-READY]; [SCHEMA][S-SCHEMA]; [DOC][S-DOC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-010

**ID:** BR-SKPE-IDENT-010 · **TITLE:** Comportamento incompatível mínimo · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014)

**STATEMENT:** Cada valor não arquivado deve ter ao menos um comportamento incompatible para prontidão; contagem não comprova observabilidade ou qualidade prática do texto. · **RATIONALE:** Tornar explícito o contrato de comportamento incompatível mínimo sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Valores não arquivados · **TRIGGER:** Avaliar prontidão

**CONSTRAINT:** Cada valor não arquivado deve ter ao menos um comportamento incompatible para prontidão; contagem não comprova observabilidade ou qualidade prática do texto. · **OUTCOME:** Ausência bloqueia · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [READY][S-READY]; [DOC][S-DOC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-011

**ID:** BR-SKPE-IDENT-011 · **TITLE:** Valor ativo versus não arquivado · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014)

**STATEMENT:** FE-003 exige ao menos um valor ativo, mas SQL usa status <> archived, incluindo draft, tanto em activeValues quanto em VALUES_MISSING; validate converte não arquivados em active. · **RATIONALE:** Tornar explícito o contrato de valor ativo versus não arquivado sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Valor draft existente · **TRIGGER:** Prontidão/validação

**CONSTRAINT:** FE-003 exige ao menos um valor ativo, mas SQL usa status <> archived, incluindo draft, tanto em activeValues quanto em VALUES_MISSING; validate converte não arquivados em active. · **OUTCOME:** Divergência de significado preservada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [DOC][S-DOC]; [READY][S-READY]; [TRANSITION][S-TRANSITION] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** IDENT-C01 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; decisão humana necessária na retomada · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-012

**ID:** BR-SKPE-IDENT-012 · **TITLE:** Declaração de coerência livre · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012)

**STATEMENT:** update_skpe_strategic_identity aceita coherence_statement nula; metadata opcional deve ser objeto; readiness não verifica essa declaração. · **RATIONALE:** Tornar explícito o contrato de declaração de coerência livre sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Formulação editável · **TRIGGER:** Atualizar cabeçalho

**CONSTRAINT:** update_skpe_strategic_identity aceita coherence_statement nula; metadata opcional deve ser objeto; readiness não verifica essa declaração. · **OUTCOME:** Texto livre ou null; pacote reaberto · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [HEADER][S-HEADER]; [READY][S-READY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-013

**ID:** BR-SKPE-IDENT-013 · **TITLE:** Invalidação do pacote nas mutações · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-007](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-007); [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008); [F-IDENT-009](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-009); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011); [F-IDENT-019](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-019)

**STATEMENT:** Operações de edição efetiva reabrem pacote in_elaboration e alteram/limpam notas. Upsert de item redefine esse item para draft; outras mutações não necessariamente redefinem todos os status dos itens. · **RATIONALE:** Tornar explícito o contrato de invalidação do pacote nas mutações sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Mutação autorizada; Formulação editável · **TRIGGER:** Salvar/excluir/arquivar

**CONSTRAINT:** Operações de edição efetiva reabrem pacote in_elaboration e alteram/limpam notas. Upsert de item redefine esse item para draft; outras mutações não necessariamente redefinem todos os status dos itens. · **OUTCOME:** Validação do pacote deixa de valer · **EXCEPTIONS:** Exclusão de item/comportamento inexistente retorna false sem invalidar · **STATE_TRANSITIONS:** pacote → in_elaboration

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [ENSURE][S-ENSURE]; [HEADER][S-HEADER]; [ITEM][S-ITEM]; [DELETE-ITEM][S-DELETE-ITEM]; [VALUE][S-VALUE]; [ARCHIVE][S-ARCHIVE]; [BEHAVIOR][S-BEHAVIOR]; [DELETE-BEHAVIOR][S-DELETE-BEHAVIOR] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-014

**ID:** BR-SKPE-IDENT-014 · **TITLE:** Submissão do pacote · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013)

**STATEMENT:** submit_validation aceita pacote draft/in_elaboration/rejected; exige Formulação editável, manage e prontidão; muda pacote e todos os itens para pending_validation. · **RATIONALE:** Tornar explícito o contrato de submissão do pacote sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Pacote existente e pronto · **TRIGGER:** submit_validation

**CONSTRAINT:** submit_validation aceita pacote draft/in_elaboration/rejected; exige Formulação editável, manage e prontidão; muda pacote e todos os itens para pending_validation. · **OUTCOME:** Submissão auditada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** draft/in_elaboration/rejected → pending_validation

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-015

**ID:** BR-SKPE-IDENT-015 · **TITLE:** Validação e permissões acumuladas · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014)

**STATEMENT:** validate exige pacote pending_validation, prontidão e validate, mas também manage pelo assert de Formulação editável executado antes do ramo; leitura de readiness verifica view. Valida itens e ativa valores não arquivados. · **RATIONALE:** Tornar explícito o contrato de validação e permissões acumuladas sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Formulação editável; permissões efetivas cumulativas · **TRIGGER:** validate

**CONSTRAINT:** validate exige pacote pending_validation, prontidão e validate, mas também manage pelo assert de Formulação editável executado antes do ramo; leitura de readiness verifica view. Valida itens e ativa valores não arquivados. · **OUTCOME:** Pacote e itens validated; valores active · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** pending_validation → validated

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION]; [FORM-GUARD][S-FORM-GUARD]; [READY][S-READY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-016

**ID:** BR-SKPE-IDENT-016 · **TITLE:** Devolução para ajustes · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-015](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-015)

**STATEMENT:** return_for_adjustments admite pending_validation/validated; requer manage pelo assert e validate pelo ramo; notas >=10 caracteres; pacote in_elaboration e todos itens draft. · **RATIONALE:** Tornar explícito o contrato de devolução para ajustes sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Formulação editável; pacote elegível · **TRIGGER:** return_for_adjustments

**CONSTRAINT:** return_for_adjustments admite pending_validation/validated; requer manage pelo assert e validate pelo ramo; notas >=10 caracteres; pacote in_elaboration e todos itens draft. · **OUTCOME:** Notas preservadas; valores não mudam · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** pending_validation/validated → in_elaboration

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION]; [FORM-GUARD][S-FORM-GUARD] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-017

**ID:** BR-SKPE-IDENT-017 · **TITLE:** Aprovação do pacote não equivale à da Formulação · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-002](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-002); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014); [F-IDENT-017](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-017); [F-IDENT-018](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-018)

**STATEMENT:** Schema admite approved/rejected no pacote, mas transition oferece somente submit_validation/validate/return_for_adjustments. FE-001 prevê aprovação; gate exige validated, e não promove identidade a approved. · **RATIONALE:** Tornar explícito o contrato de aprovação do pacote não equivale à da formulação sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Comparar camada documental, SQL e UI · **TRIGGER:** Leitura do contrato

**CONSTRAINT:** Schema admite approved/rejected no pacote, mas transition oferece somente submit_validation/validate/return_for_adjustments. FE-001 prevê aprovação; gate exige validated, e não promove identidade a approved. · **OUTCOME:** Aprovação autônoma não comprovada; decisão permanece aberta · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA]; [TRANSITION][S-TRANSITION]; [GATE][S-GATE]; [METHOD][S-METHOD] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** IDENT-C02 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; decisão humana necessária na retomada · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-018

**ID:** BR-SKPE-IDENT-018 · **TITLE:** Consulta consolidada não filtra por aprovação · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-001](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-001)

**STATEMENT:** get_skpe_strategic_identity retorna todos itens da versão e valores não arquivados com comportamentos, ordenados; pacote ausente resulta identity null e arrays vazios. Não escolhe versão vigente. · **RATIONALE:** Tornar explícito o contrato de consulta consolidada não filtra por aprovação sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Formulação explícita autorizada · **TRIGGER:** get_skpe_strategic_identity

**CONSTRAINT:** get_skpe_strategic_identity retorna todos itens da versão e valores não arquivados com comportamentos, ordenados; pacote ausente resulta identity null e arrays vazios. Não escolhe versão vigente. · **OUTCOME:** Payload versionado com readiness · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [READ][S-READ] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-019

**ID:** BR-SKPE-IDENT-019 · **TITLE:** Exibição parcial na UI · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-001](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-001); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014)

**STATEMENT:** Com formulationId a UI usa RPC, mas tipa/renderiza somente itens e valores; não exibe comportamentos, coerência, prontidão ou ações de manutenção/validação no componente examinado. · **RATIONALE:** Tornar explícito o contrato de exibição parcial na ui sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** formulationId fornecido · **TRIGGER:** Carregar/renderizar

**CONSTRAINT:** Com formulationId a UI usa RPC, mas tipa/renderiza somente itens e valores; não exibe comportamentos, coerência, prontidão ou ações de manutenção/validação no componente examinado. · **OUTCOME:** Cards PMV e valores; não demonstra fluxo operacional completo · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** CODE_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [UI][S-UI]; [READ][S-READ] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** APPLICATION_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-020

**ID:** BR-SKPE-IDENT-020 · **TITLE:** Fallback legado não comprova identidade vigente · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-002](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-002); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014)

**STATEMENT:** Sem formulationId, UI consulta itens approved por organização/projeto e valores active com metadata.decision igual a Aprovado integralmente; validação operacional produz validated e não grava esse marcador. · **RATIONALE:** Tornar explícito o contrato de fallback legado não comprova identidade vigente sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Contexto sem versão explícita · **TRIGGER:** Consulta legada

**CONSTRAINT:** Sem formulationId, UI consulta itens approved por organização/projeto e valores active com metadata.decision igual a Aprovado integralmente; validação operacional produz validated e não grava esse marcador. · **OUTCOME:** Pode excluir conteúdo validado e misturar versões; não resolver por inferência · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [UI][S-UI]; [TRANSITION][S-TRANSITION]; [FORM-UI][S-FORM-UI] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** APPLICATION_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** IDENT-C03 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; decisão humana necessária na retomada · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-021

**ID:** BR-SKPE-IDENT-021 · **TITLE:** Completude formal não é validação semântica · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012)

**STATEMENT:** Readiness verifica presença/cardinalidade de textos e comportamentos. Não foi localizado validador de coerência semântica de missão, visão ou prática observável, nem campos temporais próprios da visão nas quatro entidades. · **RATIONALE:** Tornar explícito o contrato de completude formal não é validação semântica sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Escopo FE-02 examinado · **TRIGGER:** Verificar completude

**CONSTRAINT:** Readiness verifica presença/cardinalidade de textos e comportamentos. Não foi localizado validador de coerência semântica de missão, visão ou prática observável, nem campos temporais próprios da visão nas quatro entidades. · **OUTCOME:** Não declarar qualidade semântica validada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [READY][S-READY]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** NOT_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-022

**ID:** BR-SKPE-IDENT-022 · **TITLE:** Sentido metodológico da visão · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012)

**STATEMENT:** FE-001 descreve visão de longo prazo como condição futura desejada; isso não impõe data/horizonte próprio ao item vision nem valida automaticamente aderência textual. · **RATIONALE:** Tornar explícito o contrato de sentido metodológico da visão sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Leitura metodológica · **TRIGGER:** Elaborar visão

**CONSTRAINT:** FE-001 descreve visão de longo prazo como condição futura desejada; isso não impõe data/horizonte próprio ao item vision nem valida automaticamente aderência textual. · **OUTCOME:** Intenção textual documentada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** DOCUMENTED_RULE · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** UNKNOWN · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** Documento · **SOURCE_EVIDENCE:** [METHOD][S-METHOD]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-023

**ID:** BR-SKPE-IDENT-023 · **TITLE:** Identidade orienta a cadeia metodológica · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-004](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-004); [F-IDENT-005](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-005); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-018](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-018)

**STATEMENT:** FE-001 relaciona Missão e Valores à Cadeia de Valor, Temas, BSC e desdobramentos; não foi localizada FK ou pré-condição de diagnóstico no contrato de edição da identidade. · **RATIONALE:** Tornar explícito o contrato de identidade orienta a cadeia metodológica sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Elaboração metodológica · **TRIGGER:** Relacionar identidade à estratégia

**CONSTRAINT:** FE-001 relaciona Missão e Valores à Cadeia de Valor, Temas, BSC e desdobramentos; não foi localizada FK ou pré-condição de diagnóstico no contrato de edição da identidade. · **OUTCOME:** Interface metodológica; não inventar enforcement · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** DOCUMENTED_RULE · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** UNKNOWN · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** Documento · **SOURCE_EVIDENCE:** [METHOD][S-METHOD]; [ITEM][S-ITEM]; [HEADER][S-HEADER] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-024

**ID:** BR-SKPE-IDENT-024 · **TITLE:** Histórico por evidência da versão · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-016](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-016); [F-IDENT-007](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-007); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011)

**STATEMENT:** get_skpe_identity_audit filtra organização/projeto, tipos de entidade e formulation_id no JSON anterior ou novo; não depende da existência atual do filho excluído. · **RATIONALE:** Tornar explícito o contrato de histórico por evidência da versão sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** view; Formulação existente · **TRIGGER:** Consultar auditoria

**CONSTRAINT:** get_skpe_identity_audit filtra organização/projeto, tipos de entidade e formulation_id no JSON anterior ou novo; não depende da existência atual do filho excluído. · **OUTCOME:** Eventos ordenados por occurred_at/id desc · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [AUDIT][S-AUDIT] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-025

**ID:** BR-SKPE-IDENT-025 · **TITLE:** Exclusão e completude posterior · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-007](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-007); [F-IDENT-011](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-011); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012)

**STATEMENT:** delete de item/comportamento retorna false se ausente; se existe, exclui e reabre pacote. Missão/visão/comportamento obrigatório pode ser removido na elaboração e passa a faltar no readiness. · **RATIONALE:** Tornar explícito o contrato de exclusão e completude posterior sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Formulação editável; operação autorizada · **TRIGGER:** Excluir registro

**CONSTRAINT:** delete de item/comportamento retorna false se ausente; se existe, exclui e reabre pacote. Missão/visão/comportamento obrigatório pode ser removido na elaboração e passa a faltar no readiness. · **OUTCOME:** boolean; prontidão recalculada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [DELETE-ITEM][S-DELETE-ITEM]; [DELETE-BEHAVIOR][S-DELETE-BEHAVIOR]; [READY][S-READY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-026

**ID:** BR-SKPE-IDENT-026 · **TITLE:** Helper interno e usuário autenticado · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-019](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-019); [F-IDENT-003](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-003); [F-IDENT-006](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-006); [F-IDENT-008](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-008)

**STATEMENT:** ensure_skpe_strategic_identity é revogado de public/anon/authenticated e concedido a service_role; é chamado pelas operações públicas para criar/reabrir pacote. Não é ação pública independente da UI. · **RATIONALE:** Tornar explícito o contrato de helper interno e usuário autenticado sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Chamador autorizado e Formulação editável · **TRIGGER:** Garantir pacote

**CONSTRAINT:** ensure_skpe_strategic_identity é revogado de public/anon/authenticated e concedido a service_role; é chamado pelas operações públicas para criar/reabrir pacote. Não é ação pública independente da UI. · **OUTCOME:** UUID interno; criação automática auditada · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [ENSURE][S-ENSURE]; [PRIVILEGES][S-PRIVILEGES] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-027

**ID:** BR-SKPE-IDENT-027 · **TITLE:** Opcionalidade histórica dos comportamentos · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-010](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-010); [F-IDENT-012](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-012); [F-IDENT-013](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-013); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014)

**STATEMENT:** FE-001 afirma que valor pode conter comportamentos; FE-003 e readiness exigem ambos os tipos. A evolução documental não prova decisão formal de supersessão da regra metodológica. · **RATIONALE:** Tornar explícito o contrato de opcionalidade histórica dos comportamentos sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** Confronto de fontes históricas · **TRIGGER:** Revisão metodológica

**CONSTRAINT:** FE-001 afirma que valor pode conter comportamentos; FE-003 e readiness exigem ambos os tipos. A evolução documental não prova decisão formal de supersessão da regra metodológica. · **OUTCOME:** Divergência aberta sem promover fonte por inferência · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [METHOD][S-METHOD]; [DOC][S-DOC]; [READY][S-READY] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** identidade estratégica

**CONFLICTS:** IDENT-C04 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; decisão humana necessária na retomada · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

### BR-SKPE-IDENT-028

**ID:** BR-SKPE-IDENT-028 · **TITLE:** Decisão de lifecycle e leitura pendente · **CAPABILITY:** SKPE-IDENT-01 · **APPLIES_TO:** [F-IDENT-001](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-001); [F-IDENT-002](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-002); [F-IDENT-014](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-014); [F-IDENT-018](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#f-ident-018)

**STATEMENT:** Unificar significado de identidade validada/aprovada e critérios de leitura requer decisão Product; filtros legados não são autoridade suficiente. · **RATIONALE:** Tornar explícito o contrato de decisão de lifecycle e leitura pendente sem inferir aceite Product

**ENTITIES:** Identidade Estratégica e entidades explicitadas no enunciado · **PRECONDITIONS:** B11 parcial e divergências identificadas · **TRIGGER:** Retomada funcional futura

**CONSTRAINT:** Unificar significado de identidade validada/aprovada e critérios de leitura requer decisão Product; filtros legados não são autoridade suficiente. · **OUTCOME:** OPEN_PRODUCT_DECISION · **EXCEPTIONS:** Nenhuma exceção adicional localizada no escopo citado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** PENDING_PRODUCT_DECISION · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: nenhuma decisão específica de aceite Product comprovada nesta wave

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Busca nas suítes versionadas sem teste específico; importação de planilha não comprova esta regra; testes externos não examinados

**SOURCE_TYPE:** SQL/frontend/documento conforme referências · **SOURCE_EVIDENCE:** [DOC][S-DOC]; [UI][S-UI]; [TRANSITION][S-TRANSITION] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** identidade estratégica

**CONFLICTS:** IDENT-C02; IDENT-C03 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; decisão humana necessária na retomada · **OBSERVABILITY:** AS-IMPLEMENTED/AS-DOCUMENTED; sem execução SQL ou runtime observado

## Referências transversais sem duplicação

| Tema | Owner transversal referenciado | Aplicação à Identidade |
| --- | --- | --- |
| Permissões de Formulação | [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005) | Helpers usados no escopo; detalhe cumulativo da transição está em BR-SKPE-IDENT-015 |
| Bloqueio de conteúdo | [BR-SKPE-FORM-008](../business-rules/formulacao-versionamento.md#br-skpe-form-008) | Identidade/filhos estão nas tabelas protegidas; aprovação da Formulação bloqueia edição |
| Nova versão e revisão | [BR-SKPE-FORM-017](../business-rules/formulacao-versionamento.md#br-skpe-form-017); [BR-SKPE-FORM-018](../business-rules/formulacao-versionamento.md#br-skpe-form-018) | Revisão de Formulação transporta identidade, não cria versionamento paralelo |
| Avanço da Formulação | [BR-SKPE-FORM-022](../business-rules/formulacao-versionamento.md#br-skpe-form-022) | Identidade pronta/validated é interface de entrada; não repetir cadeia de guards |
| Resolução de contexto | [BR-SKPE-FORM-025](../business-rules/formulacao-versionamento.md#br-skpe-form-025) | C02/FORM-C01 pode produzir formulationId null e acionar fallback de Identidade |
| Horizonte | [BR-SKPE-FORM-029](../business-rules/formulacao-versionamento.md#br-skpe-form-029) | Visão não substitui horizonte nem cria ciclo próprio |
| Escrita direta | [BR-SKPE-FORM-031](../business-rules/formulacao-versionamento.md#br-skpe-form-031) | ACL transversal permanece; não redefinir política geral |

Na identidade clonada, pacote e itens voltam a draft, notas de validação são limpas; valores não arquivados e seus comportamentos são remapeados, com proveniência em metadata. A origem permanece separada pelo formulation_id. Não há status superseded no pacote; a supersessão pertence à Formulação. Não há is_current nem version_number próprio nas quatro entidades de Identidade.

Editar pacote validated enquanto a Formulação está draft/in_elaboration reabre o pacote. Se a Formulação está aprovada, usa-se o contrato de revisão transversal. O status approved isolado do pacote não substitui esse guard. created_at/updated_at são campos, não prova de vigência; não foi localizada data própria de approved_at ou effective_from na identidade. Não assumir atualização automática de timestamps além do código/triggers demonstrado.

[CLONE][S-CLONE]; [SCHEMA][S-SCHEMA]; [ENSURE][S-ENSURE]; [FORM-GUARD][S-FORM-GUARD]

## Testes e dívida

Busca por nomes das RPCs, identity/identidade/mission/vision/purpose/behavior/valores em apps/web/tests e supabase/tests. O resultado relevante é parseCanonicalWorkbook.test.ts: asserts de leitura da planilha, sete valores de fixture, alias e resolução de conflitos de preview. Esses asserts não exercitam schema, RPCs, readiness, validação ou seleção de identidade; nenhuma cobertura indireta dessas regras foi demonstrada.

Todas as regras locais recebem NONE no escopo pesquisado; não significa inexistência de testes externos. Nenhum teste de produto/SQL foi executado nesta wave. Dívida: validação e devolução, permissões acumuladas, invalidar pacote, leitura versionada versus fallback, cardinalidades, exclusões, clone e proteção da Formulação. Não criar testes que apenas espelhem documentação.
[TEST][S-TEST]

## Limites de auditoria e completude

ensure pode reabrir o pacote antes de update_skpe_strategic_identity capturar previous_identity; o snapshot dessa operação não comprova sozinho o status anterior à reabertura. Contagens globais de comportamentos no readiness não filtram status do valor; os bloqueios por valor e a leitura consolidada aplicam escopos próprios. Não interpretar counts como validação semântica ou como lista de valores ativos da UI.

[ENSURE][S-ENSURE]; [HEADER][S-HEADER]; [READY][S-READY]; [READ][S-READ]

## Conflitos

[Quatro conflitos e suas evidências](../capabilities/SKPE-IDENT-01-identidade-estrategica.md#conflitos-e-retomada) permanecem OPEN_PRODUCT_DECISION. Não houve promoção de autoridade, correção de código ou fechamento de aceite.

[S-SCHEMA]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L390-L565
[S-ENSURE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L39-L119
[S-HEADER]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L125-L181
[S-ITEM]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L187-L310
[S-DELETE-ITEM]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L312-L369
[S-VALUE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L376-L517
[S-ARCHIVE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L519-L574
[S-BEHAVIOR]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L581-L724
[S-DELETE-BEHAVIOR]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L726-L776
[S-READY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L783-L992
[S-TRANSITION]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L998-L1184
[S-GATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L1191-L1243
[S-READ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L1249-L1385
[S-AUDIT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L1387-L1450
[S-PRIVILEGES]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730043000_create_strategic_identity_operations.sql#L1456-L1547
[S-CLONE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L206-L413
[S-FORM-GUARD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L107-L199
[S-FORM-UI]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicFormulationSection.tsx#L135-L196
[S-UI]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/features/strategy/StrategicIdentitySection.tsx#L1-L197
[S-ENTRY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/SkpeCockpit.tsx#L8753-L8768
[S-DOC]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-003_IDENTIDADE_ESTRATEGICA_OPERACIONAL.md#L1-L100
[S-METHOD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-001_ARQUITETURA_CANONICA_FORMULACAO_ESTRATEGICA.md#L11-L153
[S-TEST]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/tests/parseCanonicalWorkbook.test.ts#L25-L104
