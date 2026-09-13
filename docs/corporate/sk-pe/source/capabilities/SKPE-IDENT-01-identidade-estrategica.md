---
id: skpe-ident-01
title: Identidade Estratégica
domain: products
type: capability
status: canonical
owner: product
canonicality: canonical
canonical: true
criticality: high
parent:
  - sk-pe-product-hub
related:
  - sk-pe-current-state
  - skpe-form-ver-01
  - sk-pe-identidade-business-rules
  - sk-pe-business-rules-hub
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
  - ../README.md
  - ../business-rules/README.md
---

# SKPE-IDENT-01 — Identidade Estratégica

Owner funcional do B11; CAPABILITY_OWNER_FOUND=NO no catálogo anterior. ID proposto e adotado nesta branch: SKPE-IDENT-01. STATUS agregado: PARTIAL, com conflitos explicitamente abertos. Canonicalidade documental não é aceite funcional.

BASELINE FIRST; DELTA SECOND. PRODUCT_BASELINE_SHA=d27373cc16740dfc86eb940abf639e322b072cc8; PRODUCT_DELTA_FROM_BASELINE=NONE; CURRENT_DELTA_EVIDENCE=NONE. Corporate base: be769c3fb9a4407a70de02881cc540bdfc7e67ea. [Baseline B11](../current-state.md) · [Roadmap](../roadmap.md) · [Contrato](../business-rules/README.md) · [Regras detalhadas](../business-rules/identidade-estrategica.md).

## Propósito e fronteira

Registrar e consultar Propósito opcional, Missão, Visão, Valores/significados, comportamentos e declaração de coerência de uma versão da Formulação. Leitores, gestores e validadores são autorizados por helpers de Formulação; Product governa intenção e aceite. Não há operação autônoma de aprovação, ciclo ou versionamento de identidade comprovada nas RPCs examinadas.

A busca das operações de escrita/transição em apps/web/src não encontrou consumidores; localizou somente get_skpe_strategic_identity em StrategicIdentitySection. O componente renderiza leitura, sem formulários, salvar, validar ou botões enabled/disabled dessas operações. PARTIAL nas funções de manutenção distingue contrato SQL de fluxo completo da UI. A entrada Cockpit pode fornecer apenas organização e usar projeto do workspace; a entrada Formulação pode fornecer formulationId. Não presumir equivalência das duas leituras.

## Domínio

| ENTITY | CARDINALITY | OWNER | PERSISTENCE | RELATIONSHIPS | VERSION_SCOPE | CYCLE_SCOPE |
| --- | --- | --- | --- | --- | --- | --- |
| Pacote de identidade | 0..1 por Formulação | Formulação | skpe_strategic_identity | FK composta versão/organização/projeto; unique formulation_id | Obrigatório; sem versão própria | Sem cycle_id |
| Propósito/Missão/Visão | 0..1 de cada tipo por versão; 0..3 itens | Pacote | skpe_strategic_identity_items | FK composta para pacote; PMV é tipo, não tabela separada | Obrigatório | Sem ciclo próprio |
| Valor | 0..N; mínimo metodológico no readiness | Pacote | skpe_strategic_values | FK composta pacote; código único por versão | Obrigatório | Sem ciclo próprio |
| Comportamento | 0..N por valor; mínimo um de cada tipo no readiness | Valor | skpe_strategic_value_behaviors | FK composta valor; expected/incompatible | Obrigatório | Sem ciclo próprio |
| Declaração de coerência | 0..1 texto nullable | Pacote | coherence_statement | Campo do cabeçalho, não entidade narrativa autônoma | Do pacote | Sem ciclo próprio |

[SCHEMA][S-SCHEMA]

## FUNCTION → RULE

| FUNCTION | NAME | STATUS | RELATED_RULES |
| --- | --- | --- | --- |
| [F-IDENT-001](#f-ident-001) | Consultar identidade da versão | IMPLEMENTED | [BR-SKPE-IDENT-001](../business-rules/identidade-estrategica.md#br-skpe-ident-001); [BR-SKPE-IDENT-018](../business-rules/identidade-estrategica.md#br-skpe-ident-018); [BR-SKPE-IDENT-019](../business-rules/identidade-estrategica.md#br-skpe-ident-019); [BR-SKPE-IDENT-028](../business-rules/identidade-estrategica.md#br-skpe-ident-028) |
| [F-IDENT-002](#f-ident-002) | Ler identidade no fallback da UI | CONFLICT | [BR-SKPE-IDENT-017](../business-rules/identidade-estrategica.md#br-skpe-ident-017); [BR-SKPE-IDENT-020](../business-rules/identidade-estrategica.md#br-skpe-ident-020); [BR-SKPE-IDENT-028](../business-rules/identidade-estrategica.md#br-skpe-ident-028) |
| [F-IDENT-003](#f-ident-003) | Manter Propósito | PARTIAL | [BR-SKPE-IDENT-001](../business-rules/identidade-estrategica.md#br-skpe-ident-001); [BR-SKPE-IDENT-002](../business-rules/identidade-estrategica.md#br-skpe-ident-002); [BR-SKPE-IDENT-003](../business-rules/identidade-estrategica.md#br-skpe-ident-003); [BR-SKPE-IDENT-004](../business-rules/identidade-estrategica.md#br-skpe-ident-004); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013); [BR-SKPE-IDENT-021](../business-rules/identidade-estrategica.md#br-skpe-ident-021); [BR-SKPE-IDENT-026](../business-rules/identidade-estrategica.md#br-skpe-ident-026) |
| [F-IDENT-004](#f-ident-004) | Manter Missão | PARTIAL | [BR-SKPE-IDENT-001](../business-rules/identidade-estrategica.md#br-skpe-ident-001); [BR-SKPE-IDENT-002](../business-rules/identidade-estrategica.md#br-skpe-ident-002); [BR-SKPE-IDENT-003](../business-rules/identidade-estrategica.md#br-skpe-ident-003); [BR-SKPE-IDENT-005](../business-rules/identidade-estrategica.md#br-skpe-ident-005); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013); [BR-SKPE-IDENT-021](../business-rules/identidade-estrategica.md#br-skpe-ident-021); [BR-SKPE-IDENT-023](../business-rules/identidade-estrategica.md#br-skpe-ident-023) |
| [F-IDENT-005](#f-ident-005) | Manter Visão | PARTIAL | [BR-SKPE-IDENT-001](../business-rules/identidade-estrategica.md#br-skpe-ident-001); [BR-SKPE-IDENT-002](../business-rules/identidade-estrategica.md#br-skpe-ident-002); [BR-SKPE-IDENT-003](../business-rules/identidade-estrategica.md#br-skpe-ident-003); [BR-SKPE-IDENT-005](../business-rules/identidade-estrategica.md#br-skpe-ident-005); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013); [BR-SKPE-IDENT-021](../business-rules/identidade-estrategica.md#br-skpe-ident-021); [BR-SKPE-IDENT-022](../business-rules/identidade-estrategica.md#br-skpe-ident-022); [BR-SKPE-IDENT-023](../business-rules/identidade-estrategica.md#br-skpe-ident-023) |
| [F-IDENT-006](#f-ident-006) | Manter declaração de coerência | PARTIAL | [BR-SKPE-IDENT-012](../business-rules/identidade-estrategica.md#br-skpe-ident-012); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013); [BR-SKPE-IDENT-019](../business-rules/identidade-estrategica.md#br-skpe-ident-019); [BR-SKPE-IDENT-021](../business-rules/identidade-estrategica.md#br-skpe-ident-021); [BR-SKPE-IDENT-023](../business-rules/identidade-estrategica.md#br-skpe-ident-023); [BR-SKPE-IDENT-026](../business-rules/identidade-estrategica.md#br-skpe-ident-026) |
| [F-IDENT-007](#f-ident-007) | Excluir elemento PMV | PARTIAL | [BR-SKPE-IDENT-002](../business-rules/identidade-estrategica.md#br-skpe-ident-002); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013); [BR-SKPE-IDENT-024](../business-rules/identidade-estrategica.md#br-skpe-ident-024); [BR-SKPE-IDENT-025](../business-rules/identidade-estrategica.md#br-skpe-ident-025) |
| [F-IDENT-008](#f-ident-008) | Manter valor | PARTIAL | [BR-SKPE-IDENT-001](../business-rules/identidade-estrategica.md#br-skpe-ident-001); [BR-SKPE-IDENT-006](../business-rules/identidade-estrategica.md#br-skpe-ident-006); [BR-SKPE-IDENT-007](../business-rules/identidade-estrategica.md#br-skpe-ident-007); [BR-SKPE-IDENT-009](../business-rules/identidade-estrategica.md#br-skpe-ident-009); [BR-SKPE-IDENT-011](../business-rules/identidade-estrategica.md#br-skpe-ident-011); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013); [BR-SKPE-IDENT-026](../business-rules/identidade-estrategica.md#br-skpe-ident-026) |
| [F-IDENT-009](#f-ident-009) | Arquivar valor | PARTIAL | [BR-SKPE-IDENT-007](../business-rules/identidade-estrategica.md#br-skpe-ident-007); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013) |
| [F-IDENT-010](#f-ident-010) | Manter comportamento de valor | PARTIAL | [BR-SKPE-IDENT-001](../business-rules/identidade-estrategica.md#br-skpe-ident-001); [BR-SKPE-IDENT-008](../business-rules/identidade-estrategica.md#br-skpe-ident-008); [BR-SKPE-IDENT-009](../business-rules/identidade-estrategica.md#br-skpe-ident-009); [BR-SKPE-IDENT-010](../business-rules/identidade-estrategica.md#br-skpe-ident-010); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013); [BR-SKPE-IDENT-019](../business-rules/identidade-estrategica.md#br-skpe-ident-019); [BR-SKPE-IDENT-021](../business-rules/identidade-estrategica.md#br-skpe-ident-021); [BR-SKPE-IDENT-027](../business-rules/identidade-estrategica.md#br-skpe-ident-027) |
| [F-IDENT-011](#f-ident-011) | Excluir comportamento | PARTIAL | [BR-SKPE-IDENT-009](../business-rules/identidade-estrategica.md#br-skpe-ident-009); [BR-SKPE-IDENT-010](../business-rules/identidade-estrategica.md#br-skpe-ident-010); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013); [BR-SKPE-IDENT-024](../business-rules/identidade-estrategica.md#br-skpe-ident-024); [BR-SKPE-IDENT-025](../business-rules/identidade-estrategica.md#br-skpe-ident-025) |
| [F-IDENT-012](#f-ident-012) | Consultar prontidão metodológica | IMPLEMENTED | [BR-SKPE-IDENT-004](../business-rules/identidade-estrategica.md#br-skpe-ident-004); [BR-SKPE-IDENT-005](../business-rules/identidade-estrategica.md#br-skpe-ident-005); [BR-SKPE-IDENT-009](../business-rules/identidade-estrategica.md#br-skpe-ident-009); [BR-SKPE-IDENT-010](../business-rules/identidade-estrategica.md#br-skpe-ident-010); [BR-SKPE-IDENT-011](../business-rules/identidade-estrategica.md#br-skpe-ident-011); [BR-SKPE-IDENT-012](../business-rules/identidade-estrategica.md#br-skpe-ident-012); [BR-SKPE-IDENT-019](../business-rules/identidade-estrategica.md#br-skpe-ident-019); [BR-SKPE-IDENT-021](../business-rules/identidade-estrategica.md#br-skpe-ident-021); [BR-SKPE-IDENT-022](../business-rules/identidade-estrategica.md#br-skpe-ident-022); [BR-SKPE-IDENT-025](../business-rules/identidade-estrategica.md#br-skpe-ident-025); [BR-SKPE-IDENT-027](../business-rules/identidade-estrategica.md#br-skpe-ident-027) |
| [F-IDENT-013](#f-ident-013) | Submeter identidade à validação | PARTIAL | [BR-SKPE-IDENT-004](../business-rules/identidade-estrategica.md#br-skpe-ident-004); [BR-SKPE-IDENT-005](../business-rules/identidade-estrategica.md#br-skpe-ident-005); [BR-SKPE-IDENT-009](../business-rules/identidade-estrategica.md#br-skpe-ident-009); [BR-SKPE-IDENT-010](../business-rules/identidade-estrategica.md#br-skpe-ident-010); [BR-SKPE-IDENT-014](../business-rules/identidade-estrategica.md#br-skpe-ident-014); [BR-SKPE-IDENT-019](../business-rules/identidade-estrategica.md#br-skpe-ident-019); [BR-SKPE-IDENT-027](../business-rules/identidade-estrategica.md#br-skpe-ident-027) |
| [F-IDENT-014](#f-ident-014) | Validar identidade | PARTIAL | [BR-SKPE-IDENT-004](../business-rules/identidade-estrategica.md#br-skpe-ident-004); [BR-SKPE-IDENT-005](../business-rules/identidade-estrategica.md#br-skpe-ident-005); [BR-SKPE-IDENT-009](../business-rules/identidade-estrategica.md#br-skpe-ident-009); [BR-SKPE-IDENT-010](../business-rules/identidade-estrategica.md#br-skpe-ident-010); [BR-SKPE-IDENT-011](../business-rules/identidade-estrategica.md#br-skpe-ident-011); [BR-SKPE-IDENT-015](../business-rules/identidade-estrategica.md#br-skpe-ident-015); [BR-SKPE-IDENT-017](../business-rules/identidade-estrategica.md#br-skpe-ident-017); [BR-SKPE-IDENT-019](../business-rules/identidade-estrategica.md#br-skpe-ident-019); [BR-SKPE-IDENT-020](../business-rules/identidade-estrategica.md#br-skpe-ident-020); [BR-SKPE-IDENT-027](../business-rules/identidade-estrategica.md#br-skpe-ident-027); [BR-SKPE-IDENT-028](../business-rules/identidade-estrategica.md#br-skpe-ident-028) |
| [F-IDENT-015](#f-ident-015) | Devolver identidade para ajustes | PARTIAL | [BR-SKPE-IDENT-016](../business-rules/identidade-estrategica.md#br-skpe-ident-016) |
| [F-IDENT-016](#f-ident-016) | Consultar auditoria da identidade | IMPLEMENTED | [BR-SKPE-IDENT-024](../business-rules/identidade-estrategica.md#br-skpe-ident-024) |
| [F-IDENT-017](#f-ident-017) | Reaproveitar identidade na revisão | PARTIAL | [BR-SKPE-IDENT-017](../business-rules/identidade-estrategica.md#br-skpe-ident-017) |
| [F-IDENT-018](#f-ident-018) | Integrar prontidão ao avanço da Formulação | IMPLEMENTED | [BR-SKPE-IDENT-017](../business-rules/identidade-estrategica.md#br-skpe-ident-017); [BR-SKPE-IDENT-023](../business-rules/identidade-estrategica.md#br-skpe-ident-023); [BR-SKPE-IDENT-028](../business-rules/identidade-estrategica.md#br-skpe-ident-028) |
| [F-IDENT-019](#f-ident-019) | Garantir e reabrir pacote interno | IMPLEMENTED | [BR-SKPE-IDENT-001](../business-rules/identidade-estrategica.md#br-skpe-ident-001); [BR-SKPE-IDENT-013](../business-rules/identidade-estrategica.md#br-skpe-ident-013); [BR-SKPE-IDENT-026](../business-rules/identidade-estrategica.md#br-skpe-ident-026) |

## Contratos funcionais

### F-IDENT-001

**ID:** F-IDENT-001 · **NAME:** Consultar identidade da versão · **PURPOSE:** Ler PMVV, valores e comportamentos no contexto explícito · **STATUS:** IMPLEMENTED

**ACTORS:** view de Formulação · **PRECONDITIONS:** Formulação existente/autorizada · **INPUTS:** formulation_id

**BEHAVIOR:** RPC retorna pacote, itens, valores não arquivados com comportamentos e readiness; não cria pacote · **OUTPUTS:** JSON ou pacote null com arrays vazios · **STATES:** Qualquer estado legível

**DEPENDENCIES:** Formulação; UI usa apenas items/values · **IMPLEMENTATION_EVIDENCE:** [READ][S-READ]; [UI][S-UI] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-002

**ID:** F-IDENT-002 · **NAME:** Ler identidade no fallback da UI · **PURPOSE:** Exibir conteúdo sem formulationId explícito · **STATUS:** CONFLICT

**ACTORS:** Leitor sob RLS · **PRECONDITIONS:** projectId por prop ou workspace · **INPUTS:** organizationId; projectId

**BEHAVIOR:** Filtra itens approved; valores active com metadata.decision exata; sem formulation_id · **OUTPUTS:** Cards ou vazio/erro · **STATES:** Filtro legado não equivale a validated

**DEPENDENCIES:** Contexto de Formulação/C02; entrada Cockpit · **IMPLEMENTATION_EVIDENCE:** [UI][S-UI]; [ENTRY][S-ENTRY]; [FORM-UI][S-FORM-UI] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-003

**ID:** F-IDENT-003 · **NAME:** Manter Propósito · **PURPOSE:** Cadastrar ou revisar texto de Propósito · **STATUS:** PARTIAL

**ACTORS:** manage de Formulação · **PRECONDITIONS:** Formulação editável; motivo · **INPUTS:** formulation_id; tipo purpose; texto; rationale; ordem; metadata

**BEHAVIOR:** Upsert por versão/tipo; texto aparado; item draft; pacote reaberto · **OUTPUTS:** UUID do item · **STATES:** item → draft; pacote → in_elaboration

**DEPENDENCIES:** ensure; auditoria; sem formulário de escrita localizado · **IMPLEMENTATION_EVIDENCE:** [ITEM][S-ITEM]; [ENSURE][S-ENSURE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-004

**ID:** F-IDENT-004 · **NAME:** Manter Missão · **PURPOSE:** Cadastrar ou revisar texto de Missão · **STATUS:** PARTIAL

**ACTORS:** manage de Formulação · **PRECONDITIONS:** Formulação editável; motivo · **INPUTS:** formulation_id; tipo mission; texto; rationale; ordem; metadata

**BEHAVIOR:** Upsert por versão/tipo; texto aparado; item draft; pacote reaberto · **OUTPUTS:** UUID do item · **STATES:** item → draft; pacote → in_elaboration

**DEPENDENCIES:** ensure; auditoria; sem formulário de escrita localizado · **IMPLEMENTATION_EVIDENCE:** [ITEM][S-ITEM]; [ENSURE][S-ENSURE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-005

**ID:** F-IDENT-005 · **NAME:** Manter Visão · **PURPOSE:** Cadastrar ou revisar texto de Visão · **STATUS:** PARTIAL

**ACTORS:** manage de Formulação · **PRECONDITIONS:** Formulação editável; motivo · **INPUTS:** formulation_id; tipo vision; texto; rationale; ordem; metadata

**BEHAVIOR:** Upsert por versão/tipo; texto aparado; item draft; pacote reaberto · **OUTPUTS:** UUID do item · **STATES:** item → draft; pacote → in_elaboration

**DEPENDENCIES:** ensure; auditoria; sem formulário de escrita localizado · **IMPLEMENTATION_EVIDENCE:** [ITEM][S-ITEM]; [ENSURE][S-ENSURE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-006

**ID:** F-IDENT-006 · **NAME:** Manter declaração de coerência · **PURPOSE:** Registrar síntese do pacote · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** Formulação editável · **INPUTS:** coherence_statement; metadata; motivo

**BEHAVIOR:** Garante/reabre pacote; substitui declaração; metadata opcional objeto · **OUTPUTS:** UUID do pacote · **STATES:** → in_elaboration

**DEPENDENCIES:** Formulação; auditoria · **IMPLEMENTATION_EVIDENCE:** [HEADER][S-HEADER]; [ENSURE][S-ENSURE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-007

**ID:** F-IDENT-007 · **NAME:** Excluir elemento PMV · **PURPOSE:** Remover item por tipo · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** Formulação editável; tipo válido · **INPUTS:** formulation_id; tipo; motivo

**BEHAVIOR:** Exclui item e invalida pacote; false se ausente · **OUTPUTS:** boolean · **STATES:** pacote → in_elaboration se houve exclusão

**DEPENDENCIES:** Readiness detecta missão/visão ausente · **IMPLEMENTATION_EVIDENCE:** [DELETE-ITEM][S-DELETE-ITEM] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-008

**ID:** F-IDENT-008 · **NAME:** Manter valor · **PURPOSE:** Registrar código, nome e significado · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** Formulação editável · **INPUTS:** ID opcional; código; nome; descrição; ordem; status; metadata; motivo

**BEHAVIOR:** Atualiza por ID no escopo ou insere; código duplicado não vira upsert automático · **OUTPUTS:** UUID · **STATES:** draft/active/archived; pacote reaberto

**DEPENDENCIES:** Identidade e auditoria · **IMPLEMENTATION_EVIDENCE:** [VALUE][S-VALUE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-009

**ID:** F-IDENT-009 · **NAME:** Arquivar valor · **PURPOSE:** Retirar valor do conjunto elegível · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** Valor existente; Formulação editável · **INPUTS:** value_id; motivo

**BEHAVIOR:** Marca archived sem excluir comportamentos; invalida pacote · **OUTPUTS:** UUID · **STATES:** valor → archived; pacote → in_elaboration

**DEPENDENCIES:** Readiness e consulta deixam de considerar valor · **IMPLEMENTATION_EVIDENCE:** [ARCHIVE][S-ARCHIVE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-010

**ID:** F-IDENT-010 · **NAME:** Manter comportamento de valor · **PURPOSE:** Descrever prática esperada ou incompatível · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** Valor não arquivado; Formulação editável · **INPUTS:** value_id; behavior_id opcional; tipo; descrição; ordem; metadata; motivo

**BEHAVIOR:** Valida pertencimento; insere/atualiza; invalida pacote · **OUTPUTS:** UUID · **STATES:** Comportamento sem status; pacote → in_elaboration

**DEPENDENCIES:** Valor; Formulação · **IMPLEMENTATION_EVIDENCE:** [BEHAVIOR][S-BEHAVIOR] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-011

**ID:** F-IDENT-011 · **NAME:** Excluir comportamento · **PURPOSE:** Remover descrição vinculada · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** Registro existente e Formulação editável · **INPUTS:** behavior_id; motivo

**BEHAVIOR:** Exclui e invalida pacote; false se ausente · **OUTPUTS:** boolean · **STATES:** pacote → in_elaboration se excluído

**DEPENDENCIES:** Readiness recalculado · **IMPLEMENTATION_EVIDENCE:** [DELETE-BEHAVIOR][S-DELETE-BEHAVIOR] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-012

**ID:** F-IDENT-012 · **NAME:** Consultar prontidão metodológica · **PURPOSE:** Expor completude e bloqueios · **STATUS:** IMPLEMENTED

**ACTORS:** view · **PRECONDITIONS:** Formulação existente/autorizada · **INPUTS:** formulation_id

**BEHAVIOR:** Conta itens/valores e verifica comportamentos por valor não arquivado · **OUTPUTS:** readyForValidation; validated; counts; issues · **STATES:** Não transiciona

**DEPENDENCIES:** Regras metodológicas FE-003 · **IMPLEMENTATION_EVIDENCE:** [READY][S-READY] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-013

**ID:** F-IDENT-013 · **NAME:** Submeter identidade à validação · **PURPOSE:** Encaminhar pacote completo · **STATUS:** PARTIAL

**ACTORS:** manage e view efetivo pela prontidão · **PRECONDITIONS:** Formulação editável; pacote draft/in_elaboration/rejected · **INPUTS:** submit_validation; motivo

**BEHAVIOR:** Valida prontidão; muda pacote e todos itens para pending_validation · **OUTPUTS:** JSON de transição · **STATES:** → pending_validation

**DEPENDENCIES:** Formulação permanece editável · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-014

**ID:** F-IDENT-014 · **NAME:** Validar identidade · **PURPOSE:** Registrar validação do pacote · **STATUS:** PARTIAL

**ACTORS:** manage + validate; view para readiness · **PRECONDITIONS:** Formulação editável; pacote pending_validation · **INPUTS:** validate; notas; motivo

**BEHAVIOR:** Revalida; pacote/itens validated; valores não arquivados active · **OUTPUTS:** JSON de transição · **STATES:** pending_validation → validated

**DEPENDENCIES:** Assert editável exige manage antes da permissão validate · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION]; [FORM-GUARD][S-FORM-GUARD] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-015

**ID:** F-IDENT-015 · **NAME:** Devolver identidade para ajustes · **PURPOSE:** Reabrir pacote após análise · **STATUS:** PARTIAL

**ACTORS:** manage + validate · **PRECONDITIONS:** Formulação editável; pacote pending_validation/validated · **INPUTS:** return_for_adjustments; notas >=10 caracteres; motivo

**BEHAVIOR:** Pacote in_elaboration; itens draft; mantém valores · **OUTPUTS:** JSON de transição · **STATES:** pending_validation/validated → in_elaboration

**DEPENDENCIES:** Não é aprovação da Formulação · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-016

**ID:** F-IDENT-016 · **NAME:** Consultar auditoria da identidade · **PURPOSE:** Recuperar operações de pacote e filhos · **STATUS:** IMPLEMENTED

**ACTORS:** view · **PRECONDITIONS:** Formulação existente/autorizada · **INPUTS:** formulation_id

**BEHAVIOR:** Filtra organização/projeto e formulation_id no JSON antes/depois, incluindo registros excluídos · **OUTPUTS:** Linhas de auditoria ordenadas · **STATES:** Todos estados

**DEPENDENCIES:** skpe_operational_audit · **IMPLEMENTATION_EVIDENCE:** [AUDIT][S-AUDIT] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-017

**ID:** F-IDENT-017 · **NAME:** Reaproveitar identidade na revisão · **PURPOSE:** Transportar conteúdo para nova Formulação · **STATUS:** PARTIAL

**ACTORS:** manage no contrato transversal · **PRECONDITIONS:** Revisão governada de Formulação · **INPUTS:** origem/destino via revisão

**BEHAVIOR:** Clone copia pacote/itens/valores/comportamentos e redefine estados; detalhes pertencem a Formulação · **OUTPUTS:** Identidade da nova versão · **STATES:** Pacote/itens/valores draft

**DEPENDENCIES:** BR-SKPE-FORM-017/018; não há revisão autônoma de identidade · **IMPLEMENTATION_EVIDENCE:** [CLONE][S-CLONE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-018

**ID:** F-IDENT-018 · **NAME:** Integrar prontidão ao avanço da Formulação · **PURPOSE:** Impedir avanço sem identidade válida · **STATUS:** IMPLEMENTED

**ACTORS:** Ator da transição de Formulação · **PRECONDITIONS:** Mudança para etapas governadas · **INPUTS:** UPDATE status da Formulação

**BEHAVIOR:** Trigger consulta readiness de identidade e exige status validated · **OUTPUTS:** Avanço ou exceção · **STATES:** Identidade não recebe approved por esse trigger

**DEPENDENCIES:** BR-SKPE-FORM-022; demais pacotes fora deste recorte · **IMPLEMENTATION_EVIDENCE:** [GATE][S-GATE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

### F-IDENT-019

**ID:** F-IDENT-019 · **NAME:** Garantir e reabrir pacote interno · **PURPOSE:** Materializar identidade para operações · **STATUS:** IMPLEMENTED

**ACTORS:** Chamador interno autorizado; helper não público a authenticated · **PRECONDITIONS:** Formulação editável · **INPUTS:** formulation_id

**BEHAVIOR:** Busca/bloqueia pacote existente e reabre; ou cria in_elaboration com auditoria automática · **OUTPUTS:** UUID · **STATES:** ausente/draft/validada etc. → in_elaboration se Formulação editável

**DEPENDENCIES:** Helper não é botão nem RPC pública do usuário · **IMPLEMENTATION_EVIDENCE:** [ENSURE][S-ENSURE]; [PRIVILEGES][S-PRIVILEGES] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: nenhum teste operacional específico localizado nas suítes versionadas; testes externos não examinados

## Lifecycle

| ENTITY | STATE | CAN_TRANSITION_TO | WHO_CAN_TRIGGER | PRECONDITION | EFFECT | SOURCE | STATUS |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pacote | ausente | in_elaboration | manage via operação interna | Formulação editável | ensure cria | [ENSURE][S-ENSURE] | ALIGNED |
| Pacote | draft/in_elaboration/rejected | pending_validation | manage e view para readiness | Prontidão; Formulação editável | Pacote e itens pendentes | [TRANSITION][S-TRANSITION] | PARTIAL: UI de transição não localizada |
| Pacote | pending_validation | validated ou in_elaboration | manage + validate; view para validar | Prontidão para validar; notas >=10 para devolver | Valida itens/ativa valores ou devolve itens draft | [TRANSITION][S-TRANSITION]; [FORM-GUARD][S-FORM-GUARD] | PARTIAL |
| Pacote | validated | in_elaboration | manage por edição; manage+validate na devolução | Formulação ainda editável | Invalida pacote; não exige revisão autônoma | [ENSURE][S-ENSURE]; [TRANSITION][S-TRANSITION] | PARTIAL |
| Pacote | approved | Sem ação approve na RPC; mutações usam editabilidade da Formulação | manage nas mutações | Status admitido pelo schema; origem não comprovada via FE-02 | Não confundir approved da Formulação com pacote | [SCHEMA][S-SCHEMA]; [TRANSITION][S-TRANSITION]; [ENSURE][S-ENSURE] | CONFLICT: IDENT-C02 |
| Pacote | rejected | pending_validation; não há ação reject na RPC | manage e prontidão | Estado do schema sem produtor localizado na RPC | Pode submeter; rejeição não comprovada | [SCHEMA][S-SCHEMA]; [TRANSITION][S-TRANSITION] | PARTIAL |
| Itens | draft/pending_validation/validated/approved/rejected | draft em upsert/devolução; pending_validation em submissão; validated na validação | Atores das operações | Formulação editável | approved/rejected admitidos sem ação correspondente na RPC | [ITEM][S-ITEM]; [TRANSITION][S-TRANSITION]; [SCHEMA][S-SCHEMA] | CONFLICT com filtro legado |
| Valores | draft/active/archived | Status pedido no upsert; active na validação; archived no arquivo | manage; validate acumulado para validar | Formulação editável | Readiness inclui draft; UI legada só active com marcador | [VALUE][S-VALUE]; [ARCHIVE][S-ARCHIVE]; [TRANSITION][S-TRANSITION]; [UI][S-UI] | CONFLICT: IDENT-C01/C03 |
| Comportamento | Sem status | Insert/update/delete | manage | Valor não archived no upsert; Formulação editável | Não criar lifecycle independente | [BEHAVIOR][S-BEHAVIOR]; [DELETE-BEHAVIOR][S-DELETE-BEHAVIOR] | ALIGNED |

## Versionamento e regras transversais

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

## Dependências

| Interface | Evidência e limite |
| --- | --- |
| Formulação | FK composta, guard de avanço e revisão; sem duplicar regras transversais |
| Temas/Perspectivas/Objetivos/BSC | Cadeia metodológica em FE-001; identidade não contém FKs diretas para esses objetos |
| Horizonte/Ciclos | Acesso indireto pelo contexto da Formulação; visão sem coluna de horizonte/ciclo |
| Diagnóstico | Não localizado como guard de edição/readiness da identidade |
| Plano de Negócios/SK-PN | Cadeia de Valor é relação metodológica; nenhuma chamada direta a SK-PN nas RPCs de Identidade |
| Portabilidade | Parser tem entidades de importação strategic_identity/living_value; não confundir preview e fixture com persistência FE-02 ou aceite Product |

[SCHEMA][S-SCHEMA]; [METHOD][S-METHOD]; [ITEM][S-ITEM]; [READY][S-READY]; [TEST][S-TEST]

## Conflitos e retomada

| CONFLICT_ID | DESCRIPTION | AFFECTED_FUNCTIONS | AFFECTED_RULES | AS_DOCUMENTED | AS_IMPLEMENTED | AS_INTENDED | EVIDENCE | HUMAN_DECISION_REQUIRED | STATUS |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IDENT-C01 | Valor ativo versus não arquivado | [F-IDENT-008](#f-ident-008); [F-IDENT-012](#f-ident-012); [F-IDENT-014](#f-ident-014) | [BR-SKPE-IDENT-011](../business-rules/identidade-estrategica.md#br-skpe-ident-011) | Ao menos um valor ativo (FE-003) | Readiness inclui draft; validate ativa não arquivados | UNKNOWN: decisão Product não localizada | [DOC][S-DOC]; [READY][S-READY]; [TRANSITION][S-TRANSITION] | YES | OPEN_PRODUCT_DECISION |
| IDENT-C02 | Aprovação/validação e estado efetivo | [F-IDENT-002](#f-ident-002); [F-IDENT-014](#f-ident-014); [F-IDENT-017](#f-ident-017); [F-IDENT-018](#f-ident-018) | [BR-SKPE-IDENT-017](../business-rules/identidade-estrategica.md#br-skpe-ident-017); [BR-SKPE-IDENT-028](../business-rules/identidade-estrategica.md#br-skpe-ident-028) | FE-001 prevê aprovação; FE-003 descreve validação | Schema admite approved/rejected; RPC não oferece approve/reject; gate exige validated | UNKNOWN: decisão Product não localizada | [METHOD][S-METHOD]; [SCHEMA][S-SCHEMA]; [TRANSITION][S-TRANSITION]; [GATE][S-GATE] | YES | OPEN_PRODUCT_DECISION |
| IDENT-C03 | Leitura vigente e fallback legado | [F-IDENT-001](#f-ident-001); [F-IDENT-002](#f-ident-002); [F-IDENT-014](#f-ident-014) | [BR-SKPE-IDENT-020](../business-rules/identidade-estrategica.md#br-skpe-ident-020); [BR-SKPE-IDENT-028](../business-rules/identidade-estrategica.md#br-skpe-ident-028) | Consulta consolidada da versão em FE-003 | Fallback por projeto filtra approved/marcador enquanto RPC usa versão e itens de qualquer status | UNKNOWN: decisão Product não localizada | [DOC][S-DOC]; [UI][S-UI]; [TRANSITION][S-TRANSITION]; [FORM-UI][S-FORM-UI] | YES | OPEN_PRODUCT_DECISION |
| IDENT-C04 | Comportamentos opcionais versus obrigatórios | [F-IDENT-010](#f-ident-010); [F-IDENT-012](#f-ident-012); [F-IDENT-013](#f-ident-013); [F-IDENT-014](#f-ident-014) | [BR-SKPE-IDENT-027](../business-rules/identidade-estrategica.md#br-skpe-ident-027) | FE-001 pode conter; FE-003 exige ambos | SQL exige expected e incompatible para cada não arquivado | UNKNOWN: decisão Product não localizada | [METHOD][S-METHOD]; [DOC][S-DOC]; [READY][S-READY] | YES | OPEN_PRODUCT_DECISION |

Retomar decisão funcional apenas em wave autorizada. Não resolver IDENT-C01–C04 nem C01/C02/C04 de Medidas por inferência. A baseline inteira permanece válida.

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
