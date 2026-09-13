---
id: skpe-form-ver-01
title: Formulação e Versionamento
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
  - sk-pe-business-rules-hub
  - sk-pe-formulacao-business-rules
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
  - ../README.md
  - ../business-rules/README.md
---

# SKPE-FORM-VER-01 — Formulação e Versionamento

Owner funcional do recorte B10. CAPABILITY_OWNER_FOUND=NO no catálogo anterior; ID proposto e usado nesta branch: `SKPE-FORM-VER-01`. Não foi encontrado owner semântico equivalente nos owners de produto e na busca dirigida Corporate. Canonicalidade documental não significa aceite da implementação. STATUS funcional agregado: CONFLICT.

BASELINE FIRST; DELTA SECOND. PRODUCT_BASELINE_SHA=d27373cc16740dfc86eb940abf639e322b072cc8; PRODUCT_DELTA_FROM_BASELINE=NONE; CURRENT_DELTA_EVIDENCE=NONE. Corporate de partida: 1c7318a1e0ddc9a57571789c003f5dd448e4cd98. Fontes técnicas abaixo estão fixadas no SHA, não em branch móvel. [Baseline B10/C02](../current-state.md) · [Roadmap](../roadmap.md) · [Contrato de regras](../business-rules/README.md) · [Owner detalhado](../business-rules/formulacao-versionamento.md).

## Propósito e fronteiras

Controlar a formulação estratégica de uma organização/projeto em versões rastreáveis: elaborar, validar, aprovar, derivar revisão e preservar histórico. Identidade, mapa, medidas, OKRs, iniciativas e monitoramento são dependências; suas regras internas não são reproduzidas aqui. A ordem de implementação do roadmap permanece intacta.

Atores técnicos: leitor (view), gestor (manage), validador (validate), aprovador (approve), admin organizacional e gestor de monitoramento. Autorizações são helpers SQL, não comprovação de acesso efetivo em ambiente. Product decide intenção e aceite; código não decide conflitos.

19 funcionalidades identificadas. IMPLEMENTED significa contrato encontrado; PARTIAL nas operações administrativas indica SQL presente sem consumidor UI localizado. A busca dos seis nomes de RPC FE-002 em apps/web/src não retornou chamadas. Nenhum formulário de criação/revisão/transição, validação de formulário ou botão enabled/disabled correspondente foi localizado; não confundir operações de entidades filhas com gestão da versão. Congelamento é guarda de estado, não ação freeze separada. Exclusão funcional e restauração de archived não foram localizadas.

## FUNCTION → RULE

| FUNCTION | NAME | STATUS | RELATED_RULES |
| --- | --- | --- | --- |
| [F-FORM-001](#f-form-001) | Criar versão independente | PARTIAL | [BR-SKPE-FORM-001](../business-rules/formulacao-versionamento.md#br-skpe-form-001); [BR-SKPE-FORM-002](../business-rules/formulacao-versionamento.md#br-skpe-form-002); [BR-SKPE-FORM-004](../business-rules/formulacao-versionamento.md#br-skpe-form-004); [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-030](../business-rules/formulacao-versionamento.md#br-skpe-form-030); [BR-SKPE-FORM-031](../business-rules/formulacao-versionamento.md#br-skpe-form-031); [BR-SKPE-FORM-032](../business-rules/formulacao-versionamento.md#br-skpe-form-032); [BR-SKPE-FORM-033](../business-rules/formulacao-versionamento.md#br-skpe-form-033) |
| [F-FORM-002](#f-form-002) | Editar cabeçalho | PARTIAL | [BR-SKPE-FORM-001](../business-rules/formulacao-versionamento.md#br-skpe-form-001); [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-007](../business-rules/formulacao-versionamento.md#br-skpe-form-007); [BR-SKPE-FORM-029](../business-rules/formulacao-versionamento.md#br-skpe-form-029); [BR-SKPE-FORM-030](../business-rules/formulacao-versionamento.md#br-skpe-form-030); [BR-SKPE-FORM-031](../business-rules/formulacao-versionamento.md#br-skpe-form-031); [BR-SKPE-FORM-032](../business-rules/formulacao-versionamento.md#br-skpe-form-032); [BR-SKPE-FORM-033](../business-rules/formulacao-versionamento.md#br-skpe-form-033) |
| [F-FORM-003](#f-form-003) | Iniciar elaboração | PARTIAL | [BR-SKPE-FORM-002](../business-rules/formulacao-versionamento.md#br-skpe-form-002); [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-009](../business-rules/formulacao-versionamento.md#br-skpe-form-009); [BR-SKPE-FORM-016](../business-rules/formulacao-versionamento.md#br-skpe-form-016) |
| [F-FORM-004](#f-form-004) | Consultar prontidão | IMPLEMENTED | [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-010](../business-rules/formulacao-versionamento.md#br-skpe-form-010); [BR-SKPE-FORM-021](../business-rules/formulacao-versionamento.md#br-skpe-form-021); [BR-SKPE-FORM-022](../business-rules/formulacao-versionamento.md#br-skpe-form-022); [BR-SKPE-FORM-023](../business-rules/formulacao-versionamento.md#br-skpe-form-023) |
| [F-FORM-005](#f-form-005) | Submeter à validação | PARTIAL | [BR-SKPE-FORM-002](../business-rules/formulacao-versionamento.md#br-skpe-form-002); [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-008](../business-rules/formulacao-versionamento.md#br-skpe-form-008); [BR-SKPE-FORM-010](../business-rules/formulacao-versionamento.md#br-skpe-form-010); [BR-SKPE-FORM-016](../business-rules/formulacao-versionamento.md#br-skpe-form-016); [BR-SKPE-FORM-021](../business-rules/formulacao-versionamento.md#br-skpe-form-021); [BR-SKPE-FORM-022](../business-rules/formulacao-versionamento.md#br-skpe-form-022); [BR-SKPE-FORM-023](../business-rules/formulacao-versionamento.md#br-skpe-form-023) |
| [F-FORM-006](#f-form-006) | Validar formulação | PARTIAL | [BR-SKPE-FORM-002](../business-rules/formulacao-versionamento.md#br-skpe-form-002); [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-011](../business-rules/formulacao-versionamento.md#br-skpe-form-011); [BR-SKPE-FORM-016](../business-rules/formulacao-versionamento.md#br-skpe-form-016); [BR-SKPE-FORM-021](../business-rules/formulacao-versionamento.md#br-skpe-form-021); [BR-SKPE-FORM-022](../business-rules/formulacao-versionamento.md#br-skpe-form-022); [BR-SKPE-FORM-023](../business-rules/formulacao-versionamento.md#br-skpe-form-023) |
| [F-FORM-007](#f-form-007) | Devolver para ajustes | PARTIAL | [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-012](../business-rules/formulacao-versionamento.md#br-skpe-form-012); [BR-SKPE-FORM-016](../business-rules/formulacao-versionamento.md#br-skpe-form-016); [BR-SKPE-FORM-030](../business-rules/formulacao-versionamento.md#br-skpe-form-030) |
| [F-FORM-008](#f-form-008) | Submeter à aprovação | PARTIAL | [BR-SKPE-FORM-002](../business-rules/formulacao-versionamento.md#br-skpe-form-002); [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-013](../business-rules/formulacao-versionamento.md#br-skpe-form-013); [BR-SKPE-FORM-016](../business-rules/formulacao-versionamento.md#br-skpe-form-016); [BR-SKPE-FORM-021](../business-rules/formulacao-versionamento.md#br-skpe-form-021); [BR-SKPE-FORM-022](../business-rules/formulacao-versionamento.md#br-skpe-form-022); [BR-SKPE-FORM-023](../business-rules/formulacao-versionamento.md#br-skpe-form-023) |
| [F-FORM-009](#f-form-009) | Aprovar e substituir | PARTIAL | [BR-SKPE-FORM-003](../business-rules/formulacao-versionamento.md#br-skpe-form-003); [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-008](../business-rules/formulacao-versionamento.md#br-skpe-form-008); [BR-SKPE-FORM-014](../business-rules/formulacao-versionamento.md#br-skpe-form-014); [BR-SKPE-FORM-016](../business-rules/formulacao-versionamento.md#br-skpe-form-016); [BR-SKPE-FORM-021](../business-rules/formulacao-versionamento.md#br-skpe-form-021); [BR-SKPE-FORM-022](../business-rules/formulacao-versionamento.md#br-skpe-form-022); [BR-SKPE-FORM-023](../business-rules/formulacao-versionamento.md#br-skpe-form-023); [BR-SKPE-FORM-030](../business-rules/formulacao-versionamento.md#br-skpe-form-030); [BR-SKPE-FORM-032](../business-rules/formulacao-versionamento.md#br-skpe-form-032) |
| [F-FORM-010](#f-form-010) | Arquivar elaboração | CONFLICT | [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-015](../business-rules/formulacao-versionamento.md#br-skpe-form-015); [BR-SKPE-FORM-016](../business-rules/formulacao-versionamento.md#br-skpe-form-016); [BR-SKPE-FORM-030](../business-rules/formulacao-versionamento.md#br-skpe-form-030); [BR-SKPE-FORM-031](../business-rules/formulacao-versionamento.md#br-skpe-form-031) |
| [F-FORM-011](#f-form-011) | Criar revisão derivada | PARTIAL | [BR-SKPE-FORM-001](../business-rules/formulacao-versionamento.md#br-skpe-form-001); [BR-SKPE-FORM-002](../business-rules/formulacao-versionamento.md#br-skpe-form-002); [BR-SKPE-FORM-003](../business-rules/formulacao-versionamento.md#br-skpe-form-003); [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-017](../business-rules/formulacao-versionamento.md#br-skpe-form-017); [BR-SKPE-FORM-018](../business-rules/formulacao-versionamento.md#br-skpe-form-018); [BR-SKPE-FORM-019](../business-rules/formulacao-versionamento.md#br-skpe-form-019); [BR-SKPE-FORM-030](../business-rules/formulacao-versionamento.md#br-skpe-form-030); [BR-SKPE-FORM-032](../business-rules/formulacao-versionamento.md#br-skpe-form-032); [BR-SKPE-FORM-033](../business-rules/formulacao-versionamento.md#br-skpe-form-033) |
| [F-FORM-012](#f-form-012) | Clonar conteúdo estruturado | CONFLICT | [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-018](../business-rules/formulacao-versionamento.md#br-skpe-form-018); [BR-SKPE-FORM-019](../business-rules/formulacao-versionamento.md#br-skpe-form-019); [BR-SKPE-FORM-020](../business-rules/formulacao-versionamento.md#br-skpe-form-020) |
| [F-FORM-013](#f-form-013) | Listar versões e histórico | IMPLEMENTED | [BR-SKPE-FORM-003](../business-rules/formulacao-versionamento.md#br-skpe-form-003); [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-024](../business-rules/formulacao-versionamento.md#br-skpe-form-024); [BR-SKPE-FORM-025](../business-rules/formulacao-versionamento.md#br-skpe-form-025); [BR-SKPE-FORM-034](../business-rules/formulacao-versionamento.md#br-skpe-form-034) |
| [F-FORM-014](#f-form-014) | Consultar auditoria | IMPLEMENTED | [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005); [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006); [BR-SKPE-FORM-030](../business-rules/formulacao-versionamento.md#br-skpe-form-030); [BR-SKPE-FORM-033](../business-rules/formulacao-versionamento.md#br-skpe-form-033) |
| [F-FORM-015](#f-form-015) | Resolver contexto na UI | CONFLICT | [BR-SKPE-FORM-003](../business-rules/formulacao-versionamento.md#br-skpe-form-003); [BR-SKPE-FORM-024](../business-rules/formulacao-versionamento.md#br-skpe-form-024); [BR-SKPE-FORM-025](../business-rules/formulacao-versionamento.md#br-skpe-form-025); [BR-SKPE-FORM-026](../business-rules/formulacao-versionamento.md#br-skpe-form-026); [BR-SKPE-FORM-034](../business-rules/formulacao-versionamento.md#br-skpe-form-034) |
| [F-FORM-016](#f-form-016) | Transportar contexto por rota | IMPLEMENTED | [BR-SKPE-FORM-027](../business-rules/formulacao-versionamento.md#br-skpe-form-027) |
| [F-FORM-017](#f-form-017) | Alimentar ciclos de monitoramento | IMPLEMENTED | [BR-SKPE-FORM-019](../business-rules/formulacao-versionamento.md#br-skpe-form-019); [BR-SKPE-FORM-028](../business-rules/formulacao-versionamento.md#br-skpe-form-028) |
| [F-FORM-018](#f-form-018) | Aplicar bloqueios de conteúdo | IMPLEMENTED | [BR-SKPE-FORM-007](../business-rules/formulacao-versionamento.md#br-skpe-form-007); [BR-SKPE-FORM-008](../business-rules/formulacao-versionamento.md#br-skpe-form-008); [BR-SKPE-FORM-031](../business-rules/formulacao-versionamento.md#br-skpe-form-031) |
| [F-FORM-019](#f-form-019) | Resolver semântica temporal | IMPLEMENTED | [BR-SKPE-FORM-029](../business-rules/formulacao-versionamento.md#br-skpe-form-029) |

## Contratos funcionais

### F-FORM-001

**ID:** F-FORM-001 · **NAME:** Criar versão independente · **PURPOSE:** Abrir elaboração inicial · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** Projeto não arquivado; sem aberta e sem approved/superseded · **INPUTS:** project_id, rótulo, resumo, vigência, justificativa

**BEHAVIOR:** Bloqueia projeto e chave transacional; numera max+1; herda organização e datas opcionais do projeto · **OUTPUTS:** UUID de draft auditado · **STATES:** ausente → draft

**DEPENDENCIES:** Projeto; auditoria · **IMPLEMENTATION_EVIDENCE:** [CREATE][S-CREATE]; [SCHEMA][S-SCHEMA] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-002

**ID:** F-FORM-002 · **NAME:** Editar cabeçalho · **PURPOSE:** Manter metadados e vigência · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** draft ou in_elaboration · **INPUTS:** ID, rótulo, resumo, rationale, datas, metadata, motivo

**BEHAVIOR:** Bloqueia linha; valida campos; atualiza cabeçalho e auditoria · **OUTPUTS:** UUID atualizado · **STATES:** draft/in_elaboration sem transição

**DEPENDENCIES:** ACL; set_updated_at · **IMPLEMENTATION_EVIDENCE:** [UPDATE][S-UPDATE]; [GUARD][S-GUARD] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-003

**ID:** F-FORM-003 · **NAME:** Iniciar elaboração · **PURPOSE:** Sair de rascunho formalmente · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** draft · **INPUTS:** ID; begin_elaboration; motivo

**BEHAVIOR:** Transição auditada · **OUTPUTS:** in_elaboration · **STATES:** draft → in_elaboration

**DEPENDENCIES:** transition_skpe_formulation · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-004

**ID:** F-FORM-004 · **NAME:** Consultar prontidão · **PURPOSE:** Expor pendências metodológicas · **STATUS:** IMPLEMENTED

**ACTORS:** view · **PRECONDITIONS:** Versão existente e autorizada · **INPUTS:** formulation_id

**BEHAVIOR:** Conta conteúdo; distingue blocking de recommendation · **OUTPUTS:** JSON readyForApproval e issues · **STATES:** Sem transição

**DEPENDENCIES:** Identidade, negócio, mapa, medidas, OKR · **IMPLEMENTATION_EVIDENCE:** [READY][S-READY] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-005

**ID:** F-FORM-005 · **NAME:** Submeter à validação · **PURPOSE:** Congelar conteúdo para análise · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** draft/in_elaboration; prontidão e guards · **INPUTS:** ID; submit_validation; motivo

**BEHAVIOR:** Verifica prontidão; triggers dos pacotes; grava submissão · **OUTPUTS:** pending_validation · **STATES:** draft/in_elaboration → pending_validation

**DEPENDENCIES:** F-FORM-004; pacotes · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION]; [IDENTITY][S-IDENTITY]; [BUSINESS][S-BUSINESS]; [MAP][S-MAP]; [MEASURES][S-MEASURES]; [OKR][S-OKR]; [INITIATIVES][S-INITIATIVES]; [MONITOR][S-MONITOR] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-006

**ID:** F-FORM-006 · **NAME:** Validar formulação · **PURPOSE:** Registrar validação institucional · **STATUS:** PARTIAL

**ACTORS:** validate · **PRECONDITIONS:** pending_validation; prontidão e guards · **INPUTS:** ID; validate; notas; motivo

**BEHAVIOR:** Revalida; registra ator, data e notas · **OUTPUTS:** validated · **STATES:** pending_validation → validated

**DEPENDENCIES:** Pacotes metodológicos · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-007

**ID:** F-FORM-007 · **NAME:** Devolver para ajustes · **PURPOSE:** Reabrir elaboração após análise · **STATUS:** PARTIAL

**ACTORS:** validate ou approve conforme origem · **PRECONDITIONS:** pending_validation ou pending_approval · **INPUTS:** ID; return_for_adjustments; notas >=10 caracteres; motivo

**BEHAVIOR:** Permissão específica da etapa; registra notas e muda status · **OUTPUTS:** in_elaboration · **STATES:** pending_validation/pending_approval → in_elaboration

**DEPENDENCIES:** Auditoria · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-008

**ID:** F-FORM-008 · **NAME:** Submeter à aprovação · **PURPOSE:** Encaminhar versão validada · **STATUS:** PARTIAL

**ACTORS:** validate · **PRECONDITIONS:** validated; prontidão e guards · **INPUTS:** ID; submit_approval; motivo

**BEHAVIOR:** Revalida e grava submissão à aprovação · **OUTPUTS:** pending_approval · **STATES:** validated → pending_approval

**DEPENDENCIES:** Pacotes · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-009

**ID:** F-FORM-009 · **NAME:** Aprovar e substituir · **PURPOSE:** Instituir versão aprovada única · **STATUS:** PARTIAL

**ACTORS:** approve · **PRECONDITIONS:** pending_approval; prontidão e guards · **INPUTS:** ID; approve; notas; motivo

**BEHAVIOR:** Bloqueia atual aprovada; marca anterior superseded; aprova candidata; audita ambas · **OUTPUTS:** approved e eventual superseded · **STATES:** pending_approval → approved; approved anterior → superseded

**DEPENDENCIES:** Unicidade; pacotes · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION]; [SCHEMA][S-SCHEMA] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-010

**ID:** F-FORM-010 · **NAME:** Arquivar elaboração · **PURPOSE:** Encerrar uma versão aberta editável · **STATUS:** CONFLICT

**ACTORS:** manage · **PRECONDITIONS:** Somente draft/in_elaboration · **INPUTS:** ID; archive; motivo

**BEHAVIOR:** Marca archived; não oferece archived a partir de superseded · **OUTPUTS:** archived auditado · **STATES:** draft/in_elaboration → archived

**DEPENDENCIES:** Conflito de diagrama documental · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION]; [DOC][S-DOC] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-011

**ID:** F-FORM-011 · **NAME:** Criar revisão derivada · **PURPOSE:** Preservar histórico e abrir nova versão · **STATUS:** PARTIAL

**ACTORS:** manage · **PRECONDITIONS:** Origem approved/superseded; sem outra approved; sem aberta · **INPUTS:** Origem, rótulo, resumo, novas datas, motivo

**BEHAVIOR:** Lock; max+1; derived_from; clone estruturado; auditoria · **OUTPUTS:** Novo draft com proveniência · **STATES:** approved/superseded preservada; novo draft

**DEPENDENCIES:** Clone; unicidades · **IMPLEMENTATION_EVIDENCE:** [REVISION][S-REVISION]; [CLONE][S-CLONE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-012

**ID:** F-FORM-012 · **NAME:** Clonar conteúdo estruturado · **PURPOSE:** Transportar definições à revisão · **STATUS:** CONFLICT

**ACTORS:** manage no destino · **PRECONDITIONS:** Mesma organização/projeto; origem approved/superseded; destino editável · **INPUTS:** source_formulation_id; target_formulation_id

**BEHAVIOR:** Remapeia IDs por códigos; filtra registros; reinicia diversos status/progressos; preserva current_value do KR · **OUTPUTS:** Contagens; novos vínculos; initiativesRequireRelinking · **STATES:** Destino permanece editável

**DEPENDENCIES:** Identidade, mapa, OKR, medidas; FORM-C03 · **IMPLEMENTATION_EVIDENCE:** [CLONE][S-CLONE]; [DOC][S-DOC] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-013

**ID:** F-FORM-013 · **NAME:** Listar versões e histórico · **PURPOSE:** Consultar versões explicitamente · **STATUS:** IMPLEMENTED

**ACTORS:** view · **PRECONDITIONS:** Organização autorizada · **INPUTS:** organization_id; project_id opcional

**BEHAVIOR:** Retorna todas as versões e flags de estado; ordena projeto/versão desc · **OUTPUTS:** Linhas com origem, datas e flags · **STATES:** Todos estados

**DEPENDENCIES:** get_skpe_formulations · **IMPLEMENTATION_EVIDENCE:** [LIST][S-LIST] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-014

**ID:** F-FORM-014 · **NAME:** Consultar auditoria · **PURPOSE:** Rastrear alterações de uma versão · **STATUS:** IMPLEMENTED

**ACTORS:** view · **PRECONDITIONS:** Versão existente; autorização organizacional · **INPUTS:** formulation_id

**BEHAVIOR:** Filtra strategic_formulation e entity_id; ordena occurred_at/id desc · **OUTPUTS:** Ações, motivo, antes/depois e ator · **STATES:** Todos estados

**DEPENDENCIES:** skpe_operational_audit · **IMPLEMENTATION_EVIDENCE:** [AUDIT][S-AUDIT] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-015

**ID:** F-FORM-015 · **NAME:** Resolver contexto na UI · **PURPOSE:** Alimentar a experiência de Formulação · **STATUS:** CONFLICT

**ACTORS:** Leitor autorizado por RLS · **PRECONDITIONS:** Organização/projeto selecionados · **INPUTS:** organizationId; projectId

**BEHAVIOR:** Filtra draft/under_review/approved; limita 2; só aceita exatamente 1; consultas auxiliares por projeto · **OUTPUTS:** formulationId ou null; abas e resumos · **STATES:** Filtro divergente do SQL

**DEPENDENCIES:** C02; FORM-C01; FORM-C05 · **IMPLEMENTATION_EVIDENCE:** [UI][S-UI]; [TABS][S-TABS]; [SCHEMA][S-SCHEMA] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-016

**ID:** F-FORM-016 · **NAME:** Transportar contexto por rota · **PURPOSE:** Endereçar próxima etapa com IDs explícitos · **STATUS:** IMPLEMENTED

**ACTORS:** Usuário da navegação · **PRECONDITIONS:** IDs informados; seção reconhecida · **INPUTS:** organizationId; projectId; formulationId; section

**BEHAVIOR:** Codifica e decodifica IDs; rejeita seção desconhecida · **OUTPUTS:** Rota/parâmetros; não valida autorização ou estado · **STATES:** Sem transição

**DEPENDENCIES:** Evolução; monitoramento; diagnóstico · **IMPLEMENTATION_EVIDENCE:** [ROUTE][S-ROUTE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** DIRECT para contrato de serialização: skpeRoutes.test.ts, 5 testes PASS; não cobre lifecycle nem integração autenticada

### F-FORM-017

**ID:** F-FORM-017 · **NAME:** Alimentar ciclos de monitoramento · **PURPOSE:** Vincular execução a uma versão aprovada · **STATUS:** IMPLEMENTED

**ACTORS:** manage de monitoramento · **PRECONDITIONS:** Formulação approved e pacote/condições do ciclo · **INPUTS:** formulation_id; payload de período; motivo

**BEHAVIOR:** RPC verifica versão e autorização; mantém FK do ciclo · **OUTPUTS:** Ciclo associado à versão · **STATES:** Formulação não muda

**DEPENDENCIES:** Pacote FE-08; ciclos · **IMPLEMENTATION_EVIDENCE:** [MONITOR][S-MONITOR] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-018

**ID:** F-FORM-018 · **NAME:** Aplicar bloqueios de conteúdo · **PURPOSE:** Proteger versões fora da elaboração · **STATUS:** IMPLEMENTED

**ACTORS:** manage; escrita governada · **PRECONDITIONS:** formulation_id existente · **INPUTS:** Insert/update/delete de conteúdo vinculado

**BEHAVIOR:** Assert e triggers bloqueiam status não editáveis; legado sem vínculo é exceção · **OUTPUTS:** Escrita permitida ou erro · **STATES:** draft/in_elaboration editáveis

**DEPENDENCIES:** Lista de tabelas protegidas; RPCs · **IMPLEMENTATION_EVIDENCE:** [GUARD][S-GUARD]; [SCHEMA][S-SCHEMA] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

### F-FORM-019

**ID:** F-FORM-019 · **NAME:** Resolver semântica temporal · **PURPOSE:** Separar vigência e horizonte estratégico · **STATUS:** IMPLEMENTED

**ACTORS:** Leitor do contrato temporal · **PRECONDITIONS:** Projeto; versão opcional deve pertencer ao projeto · **INPUTS:** project_id; formulation_id opcional

**BEHAVIOR:** Adaptador final ignora datas da formulação para período estratégico · **OUTPUTS:** Período delegado ao horizonte canônico · **STATES:** Sem transição

**DEPENDENCIES:** Contrato temporal posterior substitui compatibilidade anterior · **IMPLEMENTATION_EVIDENCE:** [TEMPORAL][S-TEMPORAL] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE: busca dirigida nas suítes versionadas; runtime não observado

## Lifecycle efetivo

| ENTITY | STATE | CAN_TRANSITION_TO / ação | WHO_CAN_TRIGGER | PRECONDITION | EFFECT | SOURCE | STATUS |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Formulação | draft | in_elaboration / begin_elaboration; pending_validation / submit_validation; archived / archive | manage | motivo; submissão exige prontidão e guards | Carimbos e auditoria | [TRANSITION][S-TRANSITION] | SQL_CONFIRMED |
| Formulação | in_elaboration | pending_validation / submit_validation; archived / archive | manage | motivo; submissão exige prontidão e guards | Congelamento ou arquivo | [TRANSITION][S-TRANSITION] | SQL_CONFIRMED |
| Formulação | pending_validation | validated / validate; in_elaboration / return_for_adjustments | validate | prontidão/guards para validar; notas >=10 para devolver | Validação ou devolução | [TRANSITION][S-TRANSITION] | SQL_CONFIRMED |
| Formulação | validated | pending_approval / submit_approval | validate | prontidão e guards; motivo | Submissão | [TRANSITION][S-TRANSITION] | SQL_CONFIRMED |
| Formulação | pending_approval | approved / approve; in_elaboration / return_for_adjustments | approve | prontidão/guards ou notas >=10; motivo | Aprovação ou devolução | [TRANSITION][S-TRANSITION] | SQL_CONFIRMED |
| Formulação | approved | superseded / efeito de aprovar outra versão | approve na candidata | Outra versão pending_approval pronta | Substitui anterior; revisão cria outro registro draft | [TRANSITION][S-TRANSITION]; [REVISION][S-REVISION] | SQL_CONFIRMED |
| Formulação | superseded | Nenhuma transição direta; pode originar novo draft | manage para revisão | Sem outra approved nem aberta | Origem histórica preservada | [REVISION][S-REVISION]; [TRANSITION][S-TRANSITION] | SQL_CONFIRMED |
| Formulação | archived | Nenhuma transição da RPC | N/A | Estado terminal na RPC | Histórico | [TRANSITION][S-TRANSITION] | SQL_CONFIRMED |
| Filtro UI | under_review | Não é estado da constraint de Formulação | Leitor | Consulta usa literal | Não mapear para pending_validation por inferência | [UI][S-UI]; [SCHEMA][S-SCHEMA] | CONFLICT |

### Confronto de estados

| UI_STATE | SQL_STATE | DOCUMENTED_STATE | PRODUCT_INTENT | Classificação |
| --- | --- | --- | --- | --- |
| draft | draft | Rascunho | Documentado; aceite não localizado | ALIGNED |
| omitido | in_elaboration | Em elaboração | Documentado | CONFLICT |
| under_review | pending_validation / validated / pending_approval são distintos | Etapas distintas | Mapeamento UI requer decisão C02 | CONFLICT |
| approved | approved | Aprovada | Unicidade técnica não escolhe contexto de edição | PARTIAL |
| omitidos | superseded / archived | Substituída → Arquivada no diagrama | Caminho de arquivo requer decisão | CONFLICT |
| completed nas abas | Não é status da formulação | Resumo de etapas | Não equivale a aprovação institucional | PARTIAL |

## Dependências metodológicas

| Dependência | Contrato de fronteira | Fonte |
| --- | --- | --- |
| Identidade/PMVV/valores | Clone estruturado; identidade deve estar validada para avanço | [CLONE][S-CLONE]; [IDENTITY][S-IDENTITY] |
| Insumos de negócio | Vínculos ativos e snapshots copiados; prontidão adicional | [CLONE][S-CLONE]; [BUSINESS][S-BUSINESS] |
| Temas, perspectivas, objetivos, BSC e relações causais | Remapeamento por código; pacote mapa pronto e validado | [CLONE][S-CLONE]; [MAP][S-MAP] |
| Indicadores/metas/benchmarks | Clone seletivo; pacote FE-05 é gate; detalhes no owner Medidas | [CLONE][S-CLONE]; [MEASURES][S-MEASURES] |
| OKRs/KRs/ciclos | Ciclos possuem formulation_id; clone preserva períodos; divergência de aplicabilidade aberta | [CLONE][S-CLONE]; [OKR][S-OKR]; [READY][S-READY] |
| Iniciativas | Não clonadas; religação futura; pacote FE-07 deve existir/pronto | [CLONE][S-CLONE]; [INITIATIVES][S-INITIATIVES] |
| Monitoramento | Prontidão FE-08; abertura de ciclo exige approved; sem detalhar execução | [MONITOR][S-MONITOR] |

## Conflitos e retomada

| CONFLICT_ID | DESCRIPTION | AFFECTED_FUNCTIONS | AFFECTED_RULES | EVIDENCE | HUMAN_DECISION_REQUIRED | STATUS |
| --- | --- | --- | --- | --- | --- | --- |
| FORM-C01 | Continuidade de C02/B10: filtro UI omite estados SQL e contexto pode ficar nulo. | [F-FORM-015](#f-form-015); [F-FORM-013](#f-form-013) | [BR-SKPE-FORM-025](../business-rules/formulacao-versionamento.md#br-skpe-form-025); [BR-SKPE-FORM-034](../business-rules/formulacao-versionamento.md#br-skpe-form-034) | [UI][S-UI]; [TABS][S-TABS]; [SCHEMA][S-SCHEMA] | YES | OPEN_PRODUCT_DECISION |
| FORM-C02 | Diagrama documental sugere superseded → archived; RPC só arquiva elaboração. | [F-FORM-010](#f-form-010) | [BR-SKPE-FORM-015](../business-rules/formulacao-versionamento.md#br-skpe-form-015) | [DOC][S-DOC]; [TRANSITION][S-TRANSITION] | YES | OPEN_PRODUCT_DECISION |
| FORM-C03 | Clone zera progress mas preserva current_value de KR; alcance de progresso operacional não clonado é ambíguo. | [F-FORM-012](#f-form-012) | [BR-SKPE-FORM-020](../business-rules/formulacao-versionamento.md#br-skpe-form-020) | [DOC][S-DOC]; [CLONE][S-CLONE] | YES | OPEN_PRODUCT_DECISION |
| FORM-C04 | OKR opcional no guard especializado versus obrigatório no readiness geral. | [F-FORM-004](#f-form-004); [F-FORM-005](#f-form-005); [F-FORM-006](#f-form-006); [F-FORM-008](#f-form-008); [F-FORM-009](#f-form-009) | [BR-SKPE-FORM-023](../business-rules/formulacao-versionamento.md#br-skpe-form-023) | [READY][S-READY]; [OKR][S-OKR] | YES | OPEN_PRODUCT_DECISION |
| FORM-C05 | Síntese por projeto e pacotes por versão usam escopos distintos. | [F-FORM-015](#f-form-015) | [BR-SKPE-FORM-026](../business-rules/formulacao-versionamento.md#br-skpe-form-026) | [UI][S-UI]; [TABS][S-TABS]; [SCHEMA][S-SCHEMA] | YES | OPEN_PRODUCT_DECISION |

Somente retomar decisão funcional em wave autorizada. C01/C02/C04 de Medidas permanecem OPEN_PRODUCT_DECISION. Os novos achados não bloqueiam a baseline inteira. Ausência de teste/aceite limita maturidade funcional, não a rastreabilidade documental.

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
