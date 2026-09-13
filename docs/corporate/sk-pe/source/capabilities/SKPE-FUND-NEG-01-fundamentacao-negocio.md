---
id: skpe-fund-neg-01
title: Fundamentação do Negócio, Canvas e Cadeia de Valor
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
  - skpe-ident-01
  - sk-pe-fundamentacao-business-rules
  - sk-pe-business-rules-hub
tags:
  - sk-pe
  - business-foundation
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

# SKPE-FUND-NEG-01 — Fundamentação do Negócio, Canvas e Cadeia de Valor

Owner funcional B12. CAPABILITY_OWNER_FOUND=NO na busca do catálogo anterior; ID proposto e adotado nesta branch: SKPE-FUND-NEG-01. STATUS agregado: PARTIAL. Canonicalidade documental não é aceite funcional, publicação em main ou runtime validado.

BASELINE FIRST; DELTA SECOND. PRODUCT_BASELINE_SHA=d27373cc16740dfc86eb940abf639e322b072cc8; PRODUCT_DELTA_FROM_BASELINE=NONE; BASELINE_EVIDENCE=d27373cc16740dfc86eb940abf639e322b072cc8; CURRENT_DELTA_EVIDENCE=NONE. Corporate base 2111404406b4ca1402872d41e27f7603b13c257d. [Baseline B12](../current-state.md) · [Roadmap](../roadmap.md) · [Contrato documental](../business-rules/README.md) · [Regras locais](../business-rules/fundamentacao-negocio.md).

## Propósito e fronteira

Estruturar insumos do negócio, Canvas e Cadeia de Valor, registrar versões e vincular contexto capturado à Formulação. A investigação distingue três persistências: Canvas do Projeto, BMC/VPC organizacional legado e arquitetura compartilhada FE-03. Não existe evidência suficiente para tratá-las como um fluxo único migrado.

As operações compartilhadas e BMC/VPC legadas não tiveram consumidores localizados em apps/web/src. CanvasSection tem leitura/inclusão/status, mas sua entrada está desativada. Funções PARTIAL têm contrato SQL presente sem jornada UI demonstrada; IMPLEMENTED identifica operação SQL concreta de consulta/guard/helper, nunca runtime observado. DOCUMENTED_ONLY identifica integração SK-PN prevista. Conflitos permanecem abertos; não inventar exclusão física, aprovação autônoma, derivações ou integração externa.

## Domínio

| ENTITY | PURPOSE | CARDINALITY | OWNER | PERSISTENCE | RELATIONSHIPS | VERSION_SCOPE | ORGANIZATION_SCOPE | CYCLE_SCOPE | LIFECYCLE |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Artefato compartilhado | Identidade estável de fundamento/BMC/VPC/cadeia e demais tipos | Organização 1:N artefatos | Arquitetura compartilhada | platform_business_artifacts | FK organização; código único organizacional | Cabeçalho não pertence a Formulação | Obrigatória | Sem cycle_id | active/inactive/archived; só criação active comprovada na RPC |
| Versão compartilhada | Conteúdo/proveniência de uma revisão | Artefato 1:N versões | Artefato | platform_business_artifact_versions | FK composta artefato/org; derived_from_version_id; projeto fonte opcional | Própria version_number; unique artefato/número | Obrigatória via escopo | Sem ciclo próprio | draft/in_elaboration/pending_validation/validated/published/superseded/archived |
| Elemento | Conteúdo normalizado e hierarquia | Versão 1:N; pai 0..1 | Versão | platform_business_artifact_elements | FK composta versão/artefato/org e pai; código único por versão | Sempre versão própria do artefato | Obrigatória | Sem ciclo próprio | draft/active/inactive/archived; upsert ativa |
| Relação de elementos | Fluxo ou causalidade local | N:N dirigido | Versão | platform_business_artifact_element_relations | Extremos mesma versão/org; unique origem/destino/tipo | Mesmo escopo dos dois elementos | Obrigatória | Sem ciclo próprio | Sem status; CRUD parcial via RPC |
| Relação de versões | Ligação entre artefatos versionados | N:N dirigido | Arquitetura compartilhada | platform_business_artifact_version_relations | FKs compostas para origem/destino da mesma org | Duas versões exatas | Obrigatória | Sem ciclo próprio | Sem status; operação pública não localizada |
| Insumo da Formulação | Uso de versão exata com contexto capturado | Formulação N:N versões; unique Formulação/versão/role | Formulação | skpe_formulation_business_inputs | FK composta Formulação/org/projeto; FK versão/artefato/org; 0..1 primary active por role | Formulação explícita + versão de artefato independente | Obrigatória | Via Formulação; sem cycle_id local | draft/active/superseded/dismissed; draft só schema |
| Snapshot de insumo | Contexto congelado na captura | 1 payload por insumo persistido | Insumo | snapshot_payload JSONB; schema/data em colunas | Contém IDs/número/estado/conteúdo/elementos/relações | Versão capturada; pode ser recapturado em elaboração | Herdada do insumo | Sem lifecycle próprio | Sem status próprio |
| Proveniência compartilhada | Identificar origem e revisão | Campos da versão e vínculo | Versão/insumo | origin_module/service, source_entity_type/id/project, derived_from, usage_mode, handoff | source_entity_id genérico não é FK para toda origem; projeto fonte tem FK | Da versão referenciada | Escopo da versão | Sem ciclo próprio | Campos e flags; não é workflow SK-PN |
| Canvas do Projeto | Estrutura legada de concepção do projeto | Projeto 1:N versões; no máximo um corrente não arquivado | Projeto | skpe_project_canvases | FK projeto/org; unique projeto/version_number | Própria coluna; sem Formulação | Obrigatória no cabeçalho | Sem cycle_id | draft/in_review/approved/archived admitidos |
| Bloco e item do Canvas do Projeto | Template de 14 blocos e conteúdo | Canvas 1:N blocos; bloco 1:N itens | Canvas/bloco | skpe_project_canvas_blocks; skpe_project_canvas_items | FKs em cadeia; item pode referir journey_item e responsável | Herdam Canvas; não versão FE-03 | Indireta pelo Canvas | Sem ciclo próprio | Bloco sem status; item active/validated/discarded + archived_at |
| Histórico do Canvas | Rastrear criação/inclusão/status | Canvas 1:N eventos | Canvas | skpe_project_canvas_history | IDs de organização/projeto/Canvas/bloco/item | Contexto do evento | Organização registrada | Sem ciclo próprio | Eventos, sem workflow próprio |
| BMC/VPC legado | Artefato organizacional por linha-versionamento | N versões por org/tipo/código | Organização; projeto opcional | skpe_business_artifacts | Unique org/tipo/código/versão; is_current parcial | Própria; cabeçalho e versão na mesma linha | Obrigatória | Sem Formulação/ciclo | draft/under_review/validated/outdated/archived + archived_at |
| Bloco e item BMC/VPC legado | Nove blocos BMC ou seis VPC com conteúdo | Artefato 1:N blocos; bloco 1:N itens | Artefato/bloco | skpe_business_artifact_blocks; skpe_business_artifact_items | FKs; código do bloco único por artefato; journey_item opcional | Herdada da linha-versionamento | Indireta pelo artefato | Sem ciclo próprio | Item not_assessed/pending/validated/rejected/outdated; add só not_assessed |
| Link legado de artefato | Referência tipada a jornada/objetivo/iniciativa/achado/fonte | Artefato 1:N; item opcional | Artefato legado | skpe_business_artifact_links | artifact_id e item_id têm FK; target_id polimórfico não tem FK ao alvo | Artefato legado exato | Indireta pelo artefato | Sem ciclo próprio | Sem status; consumer/manutenção não demonstrados |

[SCHEMA][S-SCHEMA]; [CANVAS-SCHEMA][S-CANVAS-SCHEMA]; [CANVAS-CREATE][S-CANVAS-CREATE]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA]; [LEGACY-CREATE][S-LEGACY-CREATE]; [LINK][S-LINK]

## FUNCTION → RULE

| FUNCTION | NAME | STATUS | RELATED_RULES |
| --- | --- | --- | --- |
| [F-FUND-001](#f-fund-001) | Criar artefato compartilhado | PARTIAL | [BR-SKPE-FUND-001](../business-rules/fundamentacao-negocio.md#br-skpe-fund-001); [BR-SKPE-FUND-002](../business-rules/fundamentacao-negocio.md#br-skpe-fund-002); [BR-SKPE-FUND-003](../business-rules/fundamentacao-negocio.md#br-skpe-fund-003); [BR-SKPE-FUND-013](../business-rules/fundamentacao-negocio.md#br-skpe-fund-013); [BR-SKPE-FUND-019](../business-rules/fundamentacao-negocio.md#br-skpe-fund-019); [BR-SKPE-FUND-029](../business-rules/fundamentacao-negocio.md#br-skpe-fund-029); [BR-SKPE-FUND-030](../business-rules/fundamentacao-negocio.md#br-skpe-fund-030); [BR-SKPE-FUND-042](../business-rules/fundamentacao-negocio.md#br-skpe-fund-042) |
| [F-FUND-002](#f-fund-002) | Editar cabeçalho da versão | PARTIAL | [BR-SKPE-FUND-004](../business-rules/fundamentacao-negocio.md#br-skpe-fund-004); [BR-SKPE-FUND-017](../business-rules/fundamentacao-negocio.md#br-skpe-fund-017); [BR-SKPE-FUND-029](../business-rules/fundamentacao-negocio.md#br-skpe-fund-029) |
| [F-FUND-003](#f-fund-003) | Manter elementos e blocos | PARTIAL | [BR-SKPE-FUND-002](../business-rules/fundamentacao-negocio.md#br-skpe-fund-002); [BR-SKPE-FUND-005](../business-rules/fundamentacao-negocio.md#br-skpe-fund-005); [BR-SKPE-FUND-006](../business-rules/fundamentacao-negocio.md#br-skpe-fund-006); [BR-SKPE-FUND-007](../business-rules/fundamentacao-negocio.md#br-skpe-fund-007); [BR-SKPE-FUND-010](../business-rules/fundamentacao-negocio.md#br-skpe-fund-010); [BR-SKPE-FUND-011](../business-rules/fundamentacao-negocio.md#br-skpe-fund-011); [BR-SKPE-FUND-012](../business-rules/fundamentacao-negocio.md#br-skpe-fund-012); [BR-SKPE-FUND-013](../business-rules/fundamentacao-negocio.md#br-skpe-fund-013); [BR-SKPE-FUND-028](../business-rules/fundamentacao-negocio.md#br-skpe-fund-028) |
| [F-FUND-004](#f-fund-004) | Arquivar elemento | PARTIAL | [BR-SKPE-FUND-007](../business-rules/fundamentacao-negocio.md#br-skpe-fund-007); [BR-SKPE-FUND-009](../business-rules/fundamentacao-negocio.md#br-skpe-fund-009); [BR-SKPE-FUND-028](../business-rules/fundamentacao-negocio.md#br-skpe-fund-028) |
| [F-FUND-005](#f-fund-005) | Manter relações entre elementos | PARTIAL | [BR-SKPE-FUND-008](../business-rules/fundamentacao-negocio.md#br-skpe-fund-008); [BR-SKPE-FUND-011](../business-rules/fundamentacao-negocio.md#br-skpe-fund-011); [BR-SKPE-FUND-028](../business-rules/fundamentacao-negocio.md#br-skpe-fund-028) |
| [F-FUND-006](#f-fund-006) | Excluir relação entre elementos | PARTIAL | [BR-SKPE-FUND-008](../business-rules/fundamentacao-negocio.md#br-skpe-fund-008); [BR-SKPE-FUND-009](../business-rules/fundamentacao-negocio.md#br-skpe-fund-009) |
| [F-FUND-007](#f-fund-007) | Consultar prontidão do artefato | IMPLEMENTED | [BR-SKPE-FUND-007](../business-rules/fundamentacao-negocio.md#br-skpe-fund-007); [BR-SKPE-FUND-008](../business-rules/fundamentacao-negocio.md#br-skpe-fund-008); [BR-SKPE-FUND-010](../business-rules/fundamentacao-negocio.md#br-skpe-fund-010); [BR-SKPE-FUND-011](../business-rules/fundamentacao-negocio.md#br-skpe-fund-011); [BR-SKPE-FUND-012](../business-rules/fundamentacao-negocio.md#br-skpe-fund-012); [BR-SKPE-FUND-013](../business-rules/fundamentacao-negocio.md#br-skpe-fund-013); [BR-SKPE-FUND-014](../business-rules/fundamentacao-negocio.md#br-skpe-fund-014); [BR-SKPE-FUND-017](../business-rules/fundamentacao-negocio.md#br-skpe-fund-017); [BR-SKPE-FUND-029](../business-rules/fundamentacao-negocio.md#br-skpe-fund-029) |
| [F-FUND-008](#f-fund-008) | Iniciar elaboração | PARTIAL | [BR-SKPE-FUND-015](../business-rules/fundamentacao-negocio.md#br-skpe-fund-015) |
| [F-FUND-009](#f-fund-009) | Submeter versão | PARTIAL | [BR-SKPE-FUND-010](../business-rules/fundamentacao-negocio.md#br-skpe-fund-010); [BR-SKPE-FUND-011](../business-rules/fundamentacao-negocio.md#br-skpe-fund-011); [BR-SKPE-FUND-012](../business-rules/fundamentacao-negocio.md#br-skpe-fund-012); [BR-SKPE-FUND-015](../business-rules/fundamentacao-negocio.md#br-skpe-fund-015) |
| [F-FUND-010](#f-fund-010) | Validar versão | PARTIAL | [BR-SKPE-FUND-010](../business-rules/fundamentacao-negocio.md#br-skpe-fund-010); [BR-SKPE-FUND-011](../business-rules/fundamentacao-negocio.md#br-skpe-fund-011); [BR-SKPE-FUND-012](../business-rules/fundamentacao-negocio.md#br-skpe-fund-012); [BR-SKPE-FUND-016](../business-rules/fundamentacao-negocio.md#br-skpe-fund-016) |
| [F-FUND-011](#f-fund-011) | Devolver versão para ajustes | PARTIAL | [BR-SKPE-FUND-017](../business-rules/fundamentacao-negocio.md#br-skpe-fund-017) |
| [F-FUND-012](#f-fund-012) | Publicar versão | PARTIAL | [BR-SKPE-FUND-018](../business-rules/fundamentacao-negocio.md#br-skpe-fund-018); [BR-SKPE-FUND-026](../business-rules/fundamentacao-negocio.md#br-skpe-fund-026) |
| [F-FUND-013](#f-fund-013) | Arquivar versão em elaboração | PARTIAL | [BR-SKPE-FUND-009](../business-rules/fundamentacao-negocio.md#br-skpe-fund-009); [BR-SKPE-FUND-019](../business-rules/fundamentacao-negocio.md#br-skpe-fund-019) |
| [F-FUND-014](#f-fund-014) | Criar revisão própria do artefato | PARTIAL | [BR-SKPE-FUND-001](../business-rules/fundamentacao-negocio.md#br-skpe-fund-001); [BR-SKPE-FUND-004](../business-rules/fundamentacao-negocio.md#br-skpe-fund-004); [BR-SKPE-FUND-006](../business-rules/fundamentacao-negocio.md#br-skpe-fund-006); [BR-SKPE-FUND-007](../business-rules/fundamentacao-negocio.md#br-skpe-fund-007); [BR-SKPE-FUND-020](../business-rules/fundamentacao-negocio.md#br-skpe-fund-020); [BR-SKPE-FUND-021](../business-rules/fundamentacao-negocio.md#br-skpe-fund-021); [BR-SKPE-FUND-031](../business-rules/fundamentacao-negocio.md#br-skpe-fund-031) |
| [F-FUND-015](#f-fund-015) | Capturar snapshot interno | IMPLEMENTED | [BR-SKPE-FUND-007](../business-rules/fundamentacao-negocio.md#br-skpe-fund-007); [BR-SKPE-FUND-022](../business-rules/fundamentacao-negocio.md#br-skpe-fund-022); [BR-SKPE-FUND-023](../business-rules/fundamentacao-negocio.md#br-skpe-fund-023); [BR-SKPE-FUND-027](../business-rules/fundamentacao-negocio.md#br-skpe-fund-027); [BR-SKPE-FUND-029](../business-rules/fundamentacao-negocio.md#br-skpe-fund-029) |
| [F-FUND-016](#f-fund-016) | Vincular insumo e capturar contexto | PARTIAL | [BR-SKPE-FUND-001](../business-rules/fundamentacao-negocio.md#br-skpe-fund-001); [BR-SKPE-FUND-003](../business-rules/fundamentacao-negocio.md#br-skpe-fund-003); [BR-SKPE-FUND-010](../business-rules/fundamentacao-negocio.md#br-skpe-fund-010); [BR-SKPE-FUND-022](../business-rules/fundamentacao-negocio.md#br-skpe-fund-022); [BR-SKPE-FUND-023](../business-rules/fundamentacao-negocio.md#br-skpe-fund-023); [BR-SKPE-FUND-024](../business-rules/fundamentacao-negocio.md#br-skpe-fund-024); [BR-SKPE-FUND-025](../business-rules/fundamentacao-negocio.md#br-skpe-fund-025); [BR-SKPE-FUND-027](../business-rules/fundamentacao-negocio.md#br-skpe-fund-027); [BR-SKPE-FUND-030](../business-rules/fundamentacao-negocio.md#br-skpe-fund-030) |
| [F-FUND-017](#f-fund-017) | Dispensar insumo | PARTIAL | [BR-SKPE-FUND-025](../business-rules/fundamentacao-negocio.md#br-skpe-fund-025) |
| [F-FUND-018](#f-fund-018) | Consultar prontidão da fundamentação | CONFLICT | [BR-SKPE-FUND-012](../business-rules/fundamentacao-negocio.md#br-skpe-fund-012); [BR-SKPE-FUND-014](../business-rules/fundamentacao-negocio.md#br-skpe-fund-014); [BR-SKPE-FUND-018](../business-rules/fundamentacao-negocio.md#br-skpe-fund-018); [BR-SKPE-FUND-025](../business-rules/fundamentacao-negocio.md#br-skpe-fund-025); [BR-SKPE-FUND-026](../business-rules/fundamentacao-negocio.md#br-skpe-fund-026); [BR-SKPE-FUND-043](../business-rules/fundamentacao-negocio.md#br-skpe-fund-043) |
| [F-FUND-019](#f-fund-019) | Consultar arquitetura consolidada | IMPLEMENTED | [BR-SKPE-FUND-026](../business-rules/fundamentacao-negocio.md#br-skpe-fund-026); [BR-SKPE-FUND-027](../business-rules/fundamentacao-negocio.md#br-skpe-fund-027) |
| [F-FUND-020](#f-fund-020) | Consultar auditoria da arquitetura | IMPLEMENTED | [BR-SKPE-FUND-028](../business-rules/fundamentacao-negocio.md#br-skpe-fund-028) |
| [F-FUND-021](#f-fund-021) | Bloquear avanço da Formulação sem insumos | IMPLEMENTED | [BR-SKPE-FUND-024](../business-rules/fundamentacao-negocio.md#br-skpe-fund-024); [BR-SKPE-FUND-026](../business-rules/fundamentacao-negocio.md#br-skpe-fund-026) |
| [F-FUND-022](#f-fund-022) | Reutilizar insumos na revisão de Formulação | IMPLEMENTED | [BR-SKPE-FUND-001](../business-rules/fundamentacao-negocio.md#br-skpe-fund-001); [BR-SKPE-FUND-023](../business-rules/fundamentacao-negocio.md#br-skpe-fund-023) |
| [F-FUND-023](#f-fund-023) | Criar Canvas do Projeto legado | PARTIAL | [BR-SKPE-FUND-032](../business-rules/fundamentacao-negocio.md#br-skpe-fund-032); [BR-SKPE-FUND-033](../business-rules/fundamentacao-negocio.md#br-skpe-fund-033); [BR-SKPE-FUND-042](../business-rules/fundamentacao-negocio.md#br-skpe-fund-042) |
| [F-FUND-024](#f-fund-024) | Consultar Canvas do Projeto na superfície legada | CONFLICT | [BR-SKPE-FUND-032](../business-rules/fundamentacao-negocio.md#br-skpe-fund-032); [BR-SKPE-FUND-033](../business-rules/fundamentacao-negocio.md#br-skpe-fund-033); [BR-SKPE-FUND-043](../business-rules/fundamentacao-negocio.md#br-skpe-fund-043) |
| [F-FUND-025](#f-fund-025) | Adicionar item ao Canvas do Projeto | PARTIAL | [BR-SKPE-FUND-033](../business-rules/fundamentacao-negocio.md#br-skpe-fund-033); [BR-SKPE-FUND-034](../business-rules/fundamentacao-negocio.md#br-skpe-fund-034) |
| [F-FUND-026](#f-fund-026) | Alterar situação de item do Canvas do Projeto | PARTIAL | [BR-SKPE-FUND-033](../business-rules/fundamentacao-negocio.md#br-skpe-fund-033); [BR-SKPE-FUND-034](../business-rules/fundamentacao-negocio.md#br-skpe-fund-034) |
| [F-FUND-027](#f-fund-027) | Criar BMC organizacional legado | PARTIAL | [BR-SKPE-FUND-013](../business-rules/fundamentacao-negocio.md#br-skpe-fund-013); [BR-SKPE-FUND-035](../business-rules/fundamentacao-negocio.md#br-skpe-fund-035); [BR-SKPE-FUND-037](../business-rules/fundamentacao-negocio.md#br-skpe-fund-037); [BR-SKPE-FUND-038](../business-rules/fundamentacao-negocio.md#br-skpe-fund-038); [BR-SKPE-FUND-042](../business-rules/fundamentacao-negocio.md#br-skpe-fund-042) |
| [F-FUND-028](#f-fund-028) | Criar VPC organizacional legado | PARTIAL | [BR-SKPE-FUND-013](../business-rules/fundamentacao-negocio.md#br-skpe-fund-013); [BR-SKPE-FUND-036](../business-rules/fundamentacao-negocio.md#br-skpe-fund-036); [BR-SKPE-FUND-037](../business-rules/fundamentacao-negocio.md#br-skpe-fund-037); [BR-SKPE-FUND-038](../business-rules/fundamentacao-negocio.md#br-skpe-fund-038); [BR-SKPE-FUND-042](../business-rules/fundamentacao-negocio.md#br-skpe-fund-042) |
| [F-FUND-029](#f-fund-029) | Consultar BMC/VPC legado | IMPLEMENTED | [BR-SKPE-FUND-037](../business-rules/fundamentacao-negocio.md#br-skpe-fund-037); [BR-SKPE-FUND-039](../business-rules/fundamentacao-negocio.md#br-skpe-fund-039) |
| [F-FUND-030](#f-fund-030) | Adicionar conteúdo a bloco BMC/VPC legado | PARTIAL | [BR-SKPE-FUND-035](../business-rules/fundamentacao-negocio.md#br-skpe-fund-035); [BR-SKPE-FUND-036](../business-rules/fundamentacao-negocio.md#br-skpe-fund-036); [BR-SKPE-FUND-040](../business-rules/fundamentacao-negocio.md#br-skpe-fund-040) |
| [F-FUND-031](#f-fund-031) | Alterar situação de BMC/VPC legado | PARTIAL | [BR-SKPE-FUND-041](../business-rules/fundamentacao-negocio.md#br-skpe-fund-041) |
| [F-FUND-032](#f-fund-032) | Representar relações entre versões compartilhadas | PARTIAL | [BR-SKPE-FUND-021](../business-rules/fundamentacao-negocio.md#br-skpe-fund-021); [BR-SKPE-FUND-031](../business-rules/fundamentacao-negocio.md#br-skpe-fund-031); [BR-SKPE-FUND-042](../business-rules/fundamentacao-negocio.md#br-skpe-fund-042) |
| [F-FUND-033](#f-fund-033) | Reaproveitar e aprofundar insumos com SK-PN | DOCUMENTED_ONLY | [BR-SKPE-FUND-002](../business-rules/fundamentacao-negocio.md#br-skpe-fund-002); [BR-SKPE-FUND-029](../business-rules/fundamentacao-negocio.md#br-skpe-fund-029); [BR-SKPE-FUND-030](../business-rules/fundamentacao-negocio.md#br-skpe-fund-030); [BR-SKPE-FUND-038](../business-rules/fundamentacao-negocio.md#br-skpe-fund-038); [BR-SKPE-FUND-042](../business-rules/fundamentacao-negocio.md#br-skpe-fund-042); [BR-SKPE-FUND-043](../business-rules/fundamentacao-negocio.md#br-skpe-fund-043) |

## Contratos funcionais

### F-FUND-001

**ID:** F-FUND-001 · **NAME:** Criar artefato compartilhado · **PURPOSE:** Criar artefato compartilhado · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture + gestão de Formulação · **PRECONDITIONS:** Formulação editável · **INPUTS:** formulation_id; tipo; código; nome; rótulo; maturidade; método; motivo

**BEHAVIOR:** Cria cabeçalho organizacional e versão 1 com proveniência; não vincula automaticamente · **OUTPUTS:** UUID de versão · **STATES:** artefato active; versão draft

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [CREATE][S-CREATE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-002

**ID:** F-FUND-002 · **NAME:** Editar cabeçalho da versão · **PURPOSE:** Editar cabeçalho da versão · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture · **PRECONDITIONS:** Versão draft/in_elaboration · **INPUTS:** version_id; rótulo; maturidade; summary; payload; metadata; motivo

**BEHAVIOR:** Atualiza mesma versão; limpa notas; valida objetos JSON · **OUTPUTS:** UUID · **STATES:** draft → in_elaboration

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [UPDATE][S-UPDATE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-003

**ID:** F-FUND-003 · **NAME:** Manter elementos e blocos · **PURPOSE:** Manter elementos e blocos · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture · **PRECONDITIONS:** Versão editável; pai do mesmo escopo · **INPUTS:** version_id; element_id opcional; código; bloco; tipo; título; conteúdo; pai; ordem; motivo

**BEHAVIOR:** Insere ou atualiza por ID, ativa elemento e reabre draft; bloco é código livre · **OUTPUTS:** UUID · **STATES:** elemento → active; versão draft → in_elaboration

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [ELEMENT][S-ELEMENT] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-004

**ID:** F-FUND-004 · **NAME:** Arquivar elemento · **PURPOSE:** Arquivar elemento · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture · **PRECONDITIONS:** Elemento existente; versão editável · **INPUTS:** element_id; motivo

**BEHAVIOR:** Marca archived, preserva registro e relações; limpa notas · **OUTPUTS:** UUID · **STATES:** elemento → archived

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [ARCHIVE-ELEMENT][S-ARCHIVE-ELEMENT] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-005

**ID:** F-FUND-005 · **NAME:** Manter relações entre elementos · **PURPOSE:** Manter relações entre elementos · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture · **PRECONDITIONS:** Mesma versão editável; extremos não arquivados · **INPUTS:** source_id; target_id; tipo; peso; rationale; metadata; relation_id opcional; motivo

**BEHAVIOR:** Valida tipo, peso e extremos; insere/atualiza relação · **OUTPUTS:** UUID · **STATES:** versão draft → in_elaboration

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [RELATION][S-RELATION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-006

**ID:** F-FUND-006 · **NAME:** Excluir relação entre elementos · **PURPOSE:** Excluir relação entre elementos · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture se relação existe · **PRECONDITIONS:** Versão editável para exclusão · **INPUTS:** relation_id; motivo

**BEHAVIOR:** Exclui fisicamente; false se ausente; limpa notas · **OUTPUTS:** boolean · **STATES:** Relação sem status

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [DELETE-RELATION][S-DELETE-RELATION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-007

**ID:** F-FUND-007 · **NAME:** Consultar prontidão do artefato · **PURPOSE:** Consultar prontidão do artefato · **STATUS:** IMPLEMENTED

**ACTORS:** view_business_architecture · **PRECONDITIONS:** Versão existente/autorizada · **INPUTS:** version_id

**BEHAVIOR:** Calcula blocos, fluxo e recomendações; inclui elementos não arquivados · **OUTPUTS:** JSON de prontidão e completude · **STATES:** Não transiciona

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [READY][S-READY] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-008

**ID:** F-FUND-008 · **NAME:** Iniciar elaboração · **PURPOSE:** Iniciar elaboração · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture · **PRECONDITIONS:** draft · **INPUTS:** version_id; begin_elaboration; notas; motivo

**BEHAVIOR:** transition_skpe_business_artifact_version executa ramo begin_elaboration com auditoria · **OUTPUTS:** Versão em elaboração · **STATES:** draft → in_elaboration

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-009

**ID:** F-FUND-009 · **NAME:** Submeter versão · **PURPOSE:** Submeter versão · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture + view efetivo · **PRECONDITIONS:** draft/in_elaboration; prontidão · **INPUTS:** version_id; submit_validation; notas; motivo

**BEHAVIOR:** transition_skpe_business_artifact_version executa ramo submit_validation com auditoria · **OUTPUTS:** Pendência registrada · **STATES:** draft/in_elaboration → pending_validation

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-010

**ID:** F-FUND-010 · **NAME:** Validar versão · **PURPOSE:** Validar versão · **STATUS:** PARTIAL

**ACTORS:** validate de Formulação + view_business_architecture · **PRECONDITIONS:** pending_validation; prontidão · **INPUTS:** version_id; validate; notas; motivo

**BEHAVIOR:** transition_skpe_business_artifact_version executa ramo validate com auditoria · **OUTPUTS:** Validador/data e completude registrados · **STATES:** pending_validation → validated

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-011

**ID:** F-FUND-011 · **NAME:** Devolver versão para ajustes · **PURPOSE:** Devolver versão para ajustes · **STATUS:** PARTIAL

**ACTORS:** validate OU approve de Formulação · **PRECONDITIONS:** pending_validation/validated; notas >=10 caracteres · **INPUTS:** version_id; return_for_adjustments; notas; motivo

**BEHAVIOR:** transition_skpe_business_artifact_version executa ramo return_for_adjustments com auditoria · **OUTPUTS:** Limpa validação/publicação; maturidade alta volta a essential · **STATES:** pending_validation/validated → in_elaboration

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-012

**ID:** F-FUND-012 · **NAME:** Publicar versão · **PURPOSE:** Publicar versão · **STATUS:** PARTIAL

**ACTORS:** approve de Formulação + view_business_architecture · **PRECONDITIONS:** validated; prontidão · **INPUTS:** version_id; publish; notas; motivo

**BEHAVIOR:** transition_skpe_business_artifact_version executa ramo publish com auditoria · **OUTPUTS:** Substitui publicação anterior e publica alvo · **STATES:** validated → published; anterior published → superseded

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-013

**ID:** F-FUND-013 · **NAME:** Arquivar versão em elaboração · **PURPOSE:** Arquivar versão em elaboração · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture · **PRECONDITIONS:** draft/in_elaboration · **INPUTS:** version_id; archive; notas; motivo

**BEHAVIOR:** transition_skpe_business_artifact_version executa ramo archive com auditoria · **OUTPUTS:** Versão arquivada · **STATES:** draft/in_elaboration → archived

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [TRANSITION][S-TRANSITION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-014

**ID:** F-FUND-014 · **NAME:** Criar revisão própria do artefato · **PURPOSE:** Criar revisão própria do artefato · **STATUS:** PARTIAL

**ACTORS:** manage_business_architecture · **PRECONDITIONS:** Origem published/superseded; sem versão aberta concorrente · **INPUTS:** source_version_id; rótulo; summary; motivo

**BEHAVIOR:** Incrementa versão; copia conteúdo, todos elementos e relações; remapeia pais/extremos · **OUTPUTS:** UUID da nova versão · **STATES:** nova draft/essential; origem preservada

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [REVISION][S-REVISION] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-015

**ID:** F-FUND-015 · **NAME:** Capturar snapshot interno · **PURPOSE:** Capturar snapshot interno · **STATUS:** IMPLEMENTED

**ACTORS:** Chamador interno; service_role na ACL · **PRECONDITIONS:** Versão existente · **INPUTS:** version_id

**BEHAVIOR:** Constrói JSON schema 1.0; não persiste sozinho; inclui elementos arquivados · **OUTPUTS:** JSON com capturedAt · **STATES:** Sem lifecycle próprio

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [SNAPSHOT][S-SNAPSHOT]; [PRIVILEGES][S-PRIVILEGES] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-016

**ID:** F-FUND-016 · **NAME:** Vincular insumo e capturar contexto · **PURPOSE:** Vincular insumo e capturar contexto · **STATUS:** PARTIAL

**ACTORS:** Gestão de Formulação; view_business_architecture na prontidão · **PRECONDITIONS:** Formulação editável; versão mesma organização validada/publicada e pronta · **INPUTS:** formulation_id; version_id; role; usage; requirement; primary; gap; handoff; motivo

**BEHAVIOR:** Upsert do vínculo; captura snapshot; pode substituir primário anterior e recapturar mesmo vínculo · **OUTPUTS:** UUID de insumo · **STATES:** → active; outro primário → superseded

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [LINK][S-LINK] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-017

**ID:** F-FUND-017 · **NAME:** Dispensar insumo · **PURPOSE:** Dispensar insumo · **STATUS:** PARTIAL

**ACTORS:** Gestão de Formulação · **PRECONDITIONS:** Formulação editável; insumo existente · **INPUTS:** input_id; motivo

**BEHAVIOR:** Marca dismissed e retira primary; preserva snapshot · **OUTPUTS:** UUID · **STATES:** insumo → dismissed

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [DISMISS][S-DISMISS] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-018

**ID:** F-FUND-018 · **NAME:** Consultar prontidão da fundamentação · **PURPOSE:** Consultar prontidão da fundamentação · **STATUS:** CONFLICT

**ACTORS:** view de Formulação e de artefatos · **PRECONDITIONS:** Formulação existente · **INPUTS:** formulation_id

**BEHAVIOR:** Exige dois primários ativos; reavalia versões vivas, não snapshot_payload · **OUTPUTS:** JSON de bloqueios · **STATES:** Pode variar após supersessão externa

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [FORM-READY][S-FORM-READY] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-019

**ID:** F-FUND-019 · **NAME:** Consultar arquitetura consolidada · **PURPOSE:** Consultar arquitetura consolidada · **STATUS:** IMPLEMENTED

**ACTORS:** view de Formulação e de artefatos · **PRECONDITIONS:** Formulação existente · **INPUTS:** formulation_id

**BEHAVIOR:** Retorna vínculos ativos com descritores vivos, data/schema do snapshot e readiness; não retorna snapshot_payload · **OUTPUTS:** JSON · **STATES:** Consulta não fixa vigência histórica

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [READ][S-READ] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-020

**ID:** F-FUND-020 · **NAME:** Consultar auditoria da arquitetura · **PURPOSE:** Consultar auditoria da arquitetura · **STATUS:** IMPLEMENTED

**ACTORS:** view de Formulação · **PRECONDITIONS:** Formulação existente · **INPUTS:** formulation_id

**BEHAVIOR:** Filtra organização/projeto, tipos e vínculo direto no JSON ou ID do insumo; não é toda auditoria de filhos · **OUTPUTS:** Eventos ordenados · **STATES:** Sem transição

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [AUDIT][S-AUDIT] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-021

**ID:** F-FUND-021 · **NAME:** Bloquear avanço da Formulação sem insumos · **PURPOSE:** Bloquear avanço da Formulação sem insumos · **STATUS:** IMPLEMENTED

**ACTORS:** Ator da transição de Formulação · **PRECONDITIONS:** Mudança para estado governado · **INPUTS:** UPDATE status da Formulação

**BEHAVIOR:** Trigger exige business readiness; composição dos guards pertence a Formulação · **OUTPUTS:** Avanço ou exceção · **STATES:** pending_validation/validated/pending_approval/approved

**DEPENDENCIES:** BR-SKPE-FORM-022 · **IMPLEMENTATION_EVIDENCE:** [FORM-GATE][S-FORM-GATE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-022

**ID:** F-FUND-022 · **NAME:** Reutilizar insumos na revisão de Formulação · **PURPOSE:** Reutilizar insumos na revisão de Formulação · **STATUS:** IMPLEMENTED

**ACTORS:** Gestão de Formulação · **PRECONDITIONS:** Revisão pelo contrato transversal · **INPUTS:** Formulação origem/destino

**BEHAVIOR:** Clone copia insumos ativos, versão exata e snapshot; não cria nova versão de artefato · **OUTPUTS:** Insumos na nova Formulação · **STATES:** snapshot copiado; data da coluna renovada

**DEPENDENCIES:** BR-SKPE-FORM-017/018 · **IMPLEMENTATION_EVIDENCE:** [CLONE][S-CLONE] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-023

**ID:** F-FUND-023 · **NAME:** Criar Canvas do Projeto legado · **PURPOSE:** Criar Canvas do Projeto legado · **STATUS:** PARTIAL

**ACTORS:** project_canvas.manage · **PRECONDITIONS:** Projeto não arquivado e autorizado · **INPUTS:** project_id; nome

**BEHAVIOR:** Retorna Canvas corrente se existe; senão cria template 2026.2 com 14 blocos · **OUTPUTS:** UUID · **STATES:** draft; version_number=1; is_current=true

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [CANVAS-CREATE][S-CANVAS-CREATE]; [UI][S-UI]; [UI-FLAG][S-UI-FLAG] · **DOCUMENTATION_EVIDENCE:** NOT_LOCATED como contrato Product específico do legado; evidência SQL/frontend nas referências de implementação. FE-004 descreve o modelo compartilhado, sem provar equivalência. · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-024

**ID:** F-FUND-024 · **NAME:** Consultar Canvas do Projeto na superfície legada · **PURPOSE:** Consultar Canvas do Projeto na superfície legada · **STATUS:** CONFLICT

**ACTORS:** project_canvas.view · **PRECONDITIONS:** Projeto; componente escolheria primeiro projeto de get_skpe_journey · **INPUTS:** organizationId → primeiro project_id

**BEHAVIOR:** RPC lê Canvas atual/blocos/itens; renderização de CanvasSection está desativada por constante false · **OUTPUTS:** Linhas de Canvas; tela não alcançável nessa entrada · **STATES:** Não altera estados

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [CANVAS-READ][S-CANVAS-READ]; [UI][S-UI]; [UI-FLAG][S-UI-FLAG]; [UI-ENTRY][S-UI-ENTRY] · **DOCUMENTATION_EVIDENCE:** NOT_LOCATED como contrato Product específico do legado; evidência SQL/frontend nas referências de implementação. FE-004 descreve o modelo compartilhado, sem provar equivalência. · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-025

**ID:** F-FUND-025 · **NAME:** Adicionar item ao Canvas do Projeto · **PURPOSE:** Adicionar item ao Canvas do Projeto · **STATUS:** PARTIAL

**ACTORS:** project_canvas.manage · **PRECONDITIONS:** Bloco de Canvas/projeto não arquivados · **INPUTS:** block_id; texto; prioridade; motivo opcional no SQL

**BEHAVIOR:** Trim, prioridade enum, ordem max+10; registra histórico; UI escrita desativada com a superfície · **OUTPUTS:** UUID · **STATES:** item active

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [CANVAS-WRITE][S-CANVAS-WRITE]; [UI][S-UI] · **DOCUMENTATION_EVIDENCE:** NOT_LOCATED como contrato Product específico do legado; evidência SQL/frontend nas referências de implementação. FE-004 descreve o modelo compartilhado, sem provar equivalência. · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-026

**ID:** F-FUND-026 · **NAME:** Alterar situação de item do Canvas do Projeto · **PURPOSE:** Alterar situação de item do Canvas do Projeto · **STATUS:** PARTIAL

**ACTORS:** project_canvas.manage · **PRECONDITIONS:** Item não arquivado; motivo >=10 caracteres · **INPUTS:** item_id; active/validated/discarded; motivo

**BEHAVIOR:** Atualiza status sem matriz origem/destino; grava histórico · **OUTPUTS:** void · **STATES:** → active/validated/discarded

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [CANVAS-WRITE][S-CANVAS-WRITE]; [UI][S-UI] · **DOCUMENTATION_EVIDENCE:** NOT_LOCATED como contrato Product específico do legado; evidência SQL/frontend nas referências de implementação. FE-004 descreve o modelo compartilhado, sem provar equivalência. · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-027

**ID:** F-FUND-027 · **NAME:** Criar BMC organizacional legado · **PURPOSE:** Criar BMC organizacional legado · **STATUS:** PARTIAL

**ACTORS:** business_artifacts.manage · **PRECONDITIONS:** Organização; projeto opcional da mesma organização; motivo · **INPUTS:** 15 argumentos: org/projeto/tipo/código/nome/proveniência/arquivo/motivo

**BEHAVIOR:** Overload legado cria linha-versionamento bmc e nove blocos; retira is_current anterior; não clona itens · **OUTPUTS:** UUID de artefato legado · **STATES:** novo draft; anterior validated → outdated

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [LEGACY-CREATE][S-LEGACY-CREATE] · **DOCUMENTATION_EVIDENCE:** NOT_LOCATED como contrato Product específico do legado; evidência SQL/frontend nas referências de implementação. FE-004 descreve o modelo compartilhado, sem provar equivalência. · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-028

**ID:** F-FUND-028 · **NAME:** Criar VPC organizacional legado · **PURPOSE:** Criar VPC organizacional legado · **STATUS:** PARTIAL

**ACTORS:** business_artifacts.manage · **PRECONDITIONS:** Tipo vpc_external/vpc_cooperative_member/vpc_consolidated · **INPUTS:** Mesma assinatura legada; proveniência declarada

**BEHAVIOR:** Cria seis blocos VPC; tipo consolidated não executa consolidação automática · **OUTPUTS:** UUID de artefato legado · **STATES:** draft; nova versão numérica

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [LEGACY-CREATE][S-LEGACY-CREATE]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] · **DOCUMENTATION_EVIDENCE:** NOT_LOCATED como contrato Product específico do legado; evidência SQL/frontend nas referências de implementação. FE-004 descreve o modelo compartilhado, sem provar equivalência. · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-029

**ID:** F-FUND-029 · **NAME:** Consultar BMC/VPC legado · **PURPOSE:** Consultar BMC/VPC legado · **STATUS:** IMPLEMENTED

**ACTORS:** business_artifacts.view · **PRECONDITIONS:** Organização autorizada · **INPUTS:** organization_id; project_id opcional

**BEHAVIOR:** Retorna artefatos não arquivados por archived_at, contagens de blocos/itens/links; não filtra is_current · **OUTPUTS:** Linhas agregadas · **STATES:** Qualquer status da seleção

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [LEGACY-READ][S-LEGACY-READ] · **DOCUMENTATION_EVIDENCE:** NOT_LOCATED como contrato Product específico do legado; evidência SQL/frontend nas referências de implementação. FE-004 descreve o modelo compartilhado, sem provar equivalência. · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-030

**ID:** F-FUND-030 · **NAME:** Adicionar conteúdo a bloco BMC/VPC legado · **PURPOSE:** Adicionar conteúdo a bloco BMC/VPC legado · **STATUS:** PARTIAL

**ACTORS:** business_artifacts.manage · **PRECONDITIONS:** Bloco existente; motivo · **INPUTS:** block_id; texto; descrição; tipo; prioridade; journey_id opcional

**BEHAVIOR:** Insere item not_assessed; não exige artefato draft nem avalia coerência entre blocos · **OUTPUTS:** UUID · **STATES:** item not_assessed; cabeçalho inalterado

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [LEGACY-ITEM][S-LEGACY-ITEM]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] · **DOCUMENTATION_EVIDENCE:** NOT_LOCATED como contrato Product específico do legado; evidência SQL/frontend nas referências de implementação. FE-004 descreve o modelo compartilhado, sem provar equivalência. · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-031

**ID:** F-FUND-031 · **NAME:** Alterar situação de BMC/VPC legado · **PURPOSE:** Alterar situação de BMC/VPC legado · **STATUS:** PARTIAL

**ACTORS:** business_artifacts.manage · **PRECONDITIONS:** Artefato existente; motivo · **INPUTS:** artifact_id; target_status

**BEHAVIOR:** Atualiza status admitido pelo schema e dados de validação; sem prontidão FE-03 · **OUTPUTS:** void · **STATES:** → draft/under_review/validated/outdated/archived

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [LEGACY-STATUS][S-LEGACY-STATUS]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] · **DOCUMENTATION_EVIDENCE:** NOT_LOCATED como contrato Product específico do legado; evidência SQL/frontend nas referências de implementação. FE-004 descreve o modelo compartilhado, sem provar equivalência. · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-032

**ID:** F-FUND-032 · **NAME:** Representar relações entre versões compartilhadas · **PURPOSE:** Representar relações entre versões compartilhadas · **STATUS:** PARTIAL

**ACTORS:** Leitor sob política de arquitetura · **PRECONDITIONS:** Versões mesma organização · **INPUTS:** source_version_id; target_version_id; tipo

**BEHAVIOR:** Tabela e FKs existem; operação pública de manutenção e consumidor não localizados · **OUTPUTS:** Relação persistível no schema, operação incompleta · **STATES:** Sem status

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [SCHEMA][S-SCHEMA] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

### F-FUND-033

**ID:** F-FUND-033 · **NAME:** Reaproveitar e aprofundar insumos com SK-PN · **PURPOSE:** Reaproveitar e aprofundar insumos com SK-PN · **STATUS:** DOCUMENTED_ONLY

**ACTORS:** Atores futuros de SK-PN; decisão Product · **PRECONDITIONS:** Contrato FE-004; artefatos compartilhados · **INPUTS:** Artefatos/versões/proveniência/handoff

**BEHAVIOR:** Documento prevê ida/retorno; enums e flags não provam transporte ou consumer SK-PN · **OUTPUTS:** Interface documentada; integração operacional não demonstrada · **STATES:** Sem lifecycle de handoff implementado localizado

**DEPENDENCIES:** Artefatos compartilhados; helpers de autorização e auditoria · **IMPLEMENTATION_EVIDENCE:** [DOC][S-DOC]; [SCHEMA][S-SCHEMA]; [LINK][S-LINK] · **DOCUMENTATION_EVIDENCE:** [DOC][S-DOC] · **TEST_EVIDENCE:** NONE no escopo pesquisado; nenhum assert específico localizado; runtime não executado

## Lifecycle

| ENTITY | STATE | CAN_TRANSITION_TO | WHO_CAN_TRIGGER | PRECONDITION | EFFECT | SOURCE | STATUS |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Artefato compartilhado | active/inactive/archived | Criação active; demais transições não localizadas | manage na criação | Formulação editável para criar | Cabeçalho sem workflow próprio demonstrado | [SCHEMA][S-SCHEMA]; [CREATE][S-CREATE] | PARTIAL |
| Versão compartilhada | draft | in_elaboration / pending_validation / archived | manage; view para submeter | Prontidão para submissão | Inicia, submete ou arquiva | [TRANSITION][S-TRANSITION] | PARTIAL |
| Versão compartilhada | in_elaboration | pending_validation / archived | manage; view para submeter | Prontidão para submissão | Conteúdo deixa de ser editável ao submeter | [TRANSITION][S-TRANSITION]; [GUARD][S-GUARD] | PARTIAL |
| Versão compartilhada | pending_validation | validated / in_elaboration | validate; validate OU approve para devolver | Prontidão para validar; notas >=10 para devolver | Valida ou reabre | [TRANSITION][S-TRANSITION] | PARTIAL |
| Versão compartilhada | validated | published / in_elaboration | approve para publicar; validate OU approve para devolver | Prontidão ou notas conforme ação | Publica ou reabre; percentual antigo pode permanecer | [TRANSITION][S-TRANSITION] | PARTIAL |
| Versão compartilhada | published | superseded quando outra é publicada; nova revisão draft | approve para outra publicação; manage para revisão | Revisão sem concorrente elegível | Origem não é editada em conteúdo | [TRANSITION][S-TRANSITION]; [REVISION][S-REVISION] | ALIGNED |
| Versão compartilhada | superseded | Nova revisão draft; não altera status da origem | manage | Sem outra published corrente/aberta segundo RPC | Nova versão; insumo antigo pode falhar readiness vivo | [REVISION][S-REVISION]; [FORM-READY][S-FORM-READY] | CONFLICT |
| Versão compartilhada | archived | Sem transição de saída localizada | N/A | N/A | Terminal nas ações FE-03 examinadas | [TRANSITION][S-TRANSITION] | ALIGNED |
| Elemento compartilhado | draft/active/inactive/archived | active por upsert; archived por archive | manage | Versão editável | Readiness inclui draft/inactive apesar de ativo documental | [ELEMENT][S-ELEMENT]; [ARCHIVE-ELEMENT][S-ARCHIVE-ELEMENT]; [READY][S-READY]; [DOC][S-DOC] | CONFLICT |
| Insumo | draft/active/superseded/dismissed | active por link; superseded por troca primária; dismissed por dismiss | Gestão de Formulação | Formulação editável; versão pronta ao vincular | Snapshot pode ser recapturado; draft só admitido no schema | [SCHEMA][S-SCHEMA]; [LINK][S-LINK]; [DISMISS][S-DISMISS] | PARTIAL |
| Snapshot | Sem estado próprio | Captura/recaptura/cópia sob lifecycle do insumo | Operações de vínculo/revisão | Condições da Formulação | Payload histórico não é estado da versão viva | [SNAPSHOT][S-SNAPSHOT]; [LINK][S-LINK]; [CLONE][S-CLONE] | ALIGNED |
| Cadeia de Valor | Estados da versão compartilhada | Mesmas transições FE-03 | Mesmos atores de versão | Três grupos e flow para prontidão | Sem lifecycle específico de cadeia | [SCHEMA][S-SCHEMA]; [READY][S-READY]; [TRANSITION][S-TRANSITION] | PARTIAL |
| Canvas do Projeto | draft/in_review/approved/archived | Somente criação draft comprovada; sem RPC de aprovação localizada | manage na criação | Projeto autorizado | Não equiparar status approved ao workflow FE-03 | [CANVAS-SCHEMA][S-CANVAS-SCHEMA]; [CANVAS-CREATE][S-CANVAS-CREATE] | PARTIAL |
| Item do Canvas do Projeto | active/validated/discarded | Qualquer um dos três | project_canvas.manage | Item não arquivado; motivo >=10 | Status + histórico; UI indisponível nessa entrada | [CANVAS-WRITE][S-CANVAS-WRITE]; [UI-FLAG][S-UI-FLAG] | PARTIAL |
| BMC/VPC legado | draft/under_review/validated/outdated/archived | Qualquer estado do enum; anterior validated→outdated na nova criação | business_artifacts.manage | Motivo; sem guard de prontidão nessa RPC | Atualiza timestamps de validação; is_current é independente | [LEGACY-STATUS][S-LEGACY-STATUS]; [LEGACY-CREATE][S-LEGACY-CREATE] | PARTIAL |
| Item BMC/VPC legado | not_assessed/pending/validated/rejected/outdated | Criação not_assessed; demais produtores não localizados | business_artifacts.manage para add | Bloco existente | Schema não prova operação completa de validação de item | [LEGACY-SCHEMA][S-LEGACY-SCHEMA]; [LEGACY-ITEM][S-LEGACY-ITEM] | PARTIAL |
| Relações de elementos/versões | Sem estado próprio | Insert/update/delete de elementos; versões só estrutura localizada | manage para relações de elementos | Versão editável | Não criar lifecycle de aprovação de relação | [RELATION][S-RELATION]; [DELETE-RELATION][S-DELETE-RELATION]; [SCHEMA][S-SCHEMA] | PARTIAL |

Os status ALIGNED/PARTIAL/CONFLICT descrevem alinhamento de contrato, não runtime observado. O inventário reúne 18 valores distintos de status, distribuídos por entidades; não são estados de um único workflow. Versões compartilhadas têm sete estados; maturidade essential/structured/complete/validated/published é outro eixo, alterável pelo update autorizado e pelas transições. Não há status approved na versão compartilhada: aprovação é da Formulação e publicação é da versão.

## Versionamento e snapshots

| Tema | Owner referenciado | Aplicação local |
| --- | --- | --- |
| Autorização de Formulação | [BR-SKPE-FORM-005](../business-rules/formulacao-versionamento.md#br-skpe-form-005) | Criar/vincular/dispensar usam contexto de Formulação; permissões próprias de arquitetura em BR-SKPE-FUND-029 |
| Motivo e auditoria | [BR-SKPE-FORM-006](../business-rules/formulacao-versionamento.md#br-skpe-form-006) | FE-03 chama helpers compartilhados; diferenças do Canvas legado ficam explícitas em sua regra |
| Proteção de Formulação | [BR-SKPE-FORM-008](../business-rules/formulacao-versionamento.md#br-skpe-form-008) | Insumos não são livremente regraváveis após aprovação; não confundir com imutabilidade absoluta do artefato compartilhado |
| Revisão da Formulação | [BR-SKPE-FORM-017](../business-rules/formulacao-versionamento.md#br-skpe-form-017); [BR-SKPE-FORM-018](../business-rules/formulacao-versionamento.md#br-skpe-form-018) | Copia insumos ativos/versão exata/snapshot; revisão do artefato é operação independente em BR-SKPE-FUND-020/021 |
| Guards de avanço | [BR-SKPE-FORM-022](../business-rules/formulacao-versionamento.md#br-skpe-form-022) | Trigger FE-03 exige prontidão do par de insumos; não redefinir toda cadeia transversal |
| DML direto | [BR-SKPE-FORM-031](../business-rules/formulacao-versionamento.md#br-skpe-form-031) | Política geral permanece no owner; guard local de elementos/relações complementa proteção de versão |
| Identidade e cadeia metodológica | [BR-SKPE-IDENT-023](../business-rules/identidade-estrategica.md#br-skpe-ident-023) | Missão/Valores orientam cadeia/estratégia; sem nova cópia de regra nem FK direta inferida |

Artefatos podem ser usados por diferentes Formulações da mesma organização; source_skpe_project_id identifica origem, não ownership exclusivo de uso. Snapshot é um JSON por insumo, substituível por relink em elaboração. Alterar o artefato não regrava automaticamente esse JSON, mas a consulta de prontidão usa a versão viva (FUND-C03). A revisão da Formulação copia snapshot_payload e renova a coluna snapshot_captured_at; capturedAt embutido permanece o da captura original. Distinguir data de cópia e data do conteúdo.

Vigência compartilhada é status published com índice único por artefato, sem is_current. Pode existir versão validated não publicada; ela é elegível para vínculo. Revision aceita apenas published/superseded e copia conteúdo com nova identidade; edição de draft/in_elaboration não cria versão. BMC/VPC legado usa is_current e outdated; Canvas do Projeto usa is_current e version_number, mas a RPC examinada só cria versão 1 ou retorna a atual. Nenhuma equivalência ou migração entre esses mecanismos foi demonstrada.

[SCHEMA][S-SCHEMA]; [LINK][S-LINK]; [SNAPSHOT][S-SNAPSHOT]; [REVISION][S-REVISION]; [CLONE][S-CLONE]; [LEGACY-CREATE][S-LEGACY-CREATE]; [CANVAS-CREATE][S-CANVAS-CREATE]

## Cadeia de Valor

VALUE_CHAIN_IMPLEMENTATION=PARTIAL: contrato SQL de artefato tipo value_chain, elementos e relações; consumidor frontend FE-03 não localizado. Não é tabela autônoma nem derivação automática do Canvas.

VALUE_CHAIN_PERSISTENCE=platform_business_artifacts + platform_business_artifact_versions + platform_business_artifact_elements + platform_business_artifact_element_relations.

VALUE_CHAIN_VERSIONING=versão própria; revisão/clonagem/publicação/supersessão FE-03; snapshot no insumo da Formulação.

VALUE_CHAIN_LINK_TO_STRATEGY=IMPLEMENTED_INTERFACE via skpe_formulation_business_inputs role value_chain, primário e readiness/guard da Formulação; execução em runtime não observada.

VALUE_CHAIN_LINK_TO_PROCESSES=PARTIAL: elementos/tipos/blocos e flow permitem descrição local; process_architecture e role processes são enums. Não foi localizada FK para cadastro de processos nem operação de derivação/sincronização de macroprocessos.

governance_management, core_business e support são grupos de block_code. Macroprocesso, atividade primária ou atividade de apoio podem ser descritos com element_type/título/payload, mas não há enum de macroprocesso ou tabela dedicada demonstrada nesse recorte. Não renomear core_business automaticamente como uma taxonomia externa de cadeia. Um flow é requisito mínimo; não prova encadeamento ponta a ponta, geração de valor, qualidade semântica ou derivação de capacidades. País, setor, organização e licença SK-PN não são pré-requisitos metodológicos especiais localizados.

[SCHEMA][S-SCHEMA]; [READY][S-READY]; [LINK][S-LINK]; [FORM-GATE][S-FORM-GATE]; [DOC][S-DOC]

## Interfaces

| INTERFACE | CLASSIFICATION | EVIDENCE | LIMIT |
| --- | --- | --- | --- |
| Formulação e Versionamento | IMPLEMENTED_INTERFACE | Insumos versionados, snapshot, clone e guard; [LINK][S-LINK]; [CLONE][S-CLONE]; [FORM-GATE][S-FORM-GATE] | Contrato SQL; frontend de vínculo não localizado; regras transversais referenciadas |
| Identidade Estratégica | METHODOLOGICAL_INTERFACE | [BR-SKPE-IDENT-023](../business-rules/identidade-estrategica.md#br-skpe-ident-023); [METHOD][S-METHOD] | Mesmo contexto metodológico não cria FK direta pacote-identidade→artefato |
| Diagnóstico | UNKNOWN | [LEGACY-SCHEMA][S-LEGACY-SCHEMA] | Link legado finding/evidence_source é target_id genérico; não prova consumo ou derivação; nenhum diagnóstico prévio no guard FE-03 |
| SK-PN / Plano de Negócios | DOCUMENTED_INTERFACE | [DOC][S-DOC]; [SCHEMA][S-SCHEMA]; [LINK][S-LINK]; [LEGACY-CREATE][S-LEGACY-CREATE] | Enums, origem e handoff não comprovam integração operacional |
| Temas/Perspectivas/Objetivos | METHODOLOGICAL_INTERFACE | [METHOD][S-METHOD]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] | strategic_objective é link_type polimórfico; sem derivação automática demonstrada |
| Processos | UNKNOWN | [SCHEMA][S-SCHEMA]; [RELATION][S-RELATION] | process_architecture/processes não comprovam interface com entidades de processos |
| Riscos | METHODOLOGICAL_INTERFACE | [READY][S-READY]; [SCHEMA][S-SCHEMA]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] | risks_hypotheses/risk_hypothesis_map/item_type risk não são FK para gestão de riscos |
| Iniciativas | UNKNOWN | [LEGACY-SCHEMA][S-LEGACY-SCHEMA] | link_type initiative e target_id sem FK ao alvo; não assumir criação/atualização de iniciativa |

A classificação de interface implementada exige chamada/ligação técnica concreta; coluna ou enum isolado é apenas estrutura. Nenhuma reversa profunda das capabilities vizinhas foi realizada.

## Conflitos e retomada

### FUND-C01

| FIELD | VALUE |
| --- | --- |
| CONFLICT_ID | FUND-C01 |
| STATUS | OPEN_PRODUCT_DECISION |
| DESCRIPTION | Disponibilidade da superfície de Canvas |
| AFFECTED_FUNCTIONS | [F-FUND-018](#f-fund-018); [F-FUND-023](#f-fund-023); [F-FUND-024](#f-fund-024); [F-FUND-025](#f-fund-025); [F-FUND-026](#f-fund-026); [F-FUND-033](#f-fund-033) |
| AFFECTED_RULES | [BR-SKPE-FUND-033](../business-rules/fundamentacao-negocio.md#br-skpe-fund-033); [BR-SKPE-FUND-043](../business-rules/fundamentacao-negocio.md#br-skpe-fund-043) |
| AS_DOCUMENTED | Baseline B12 cita CANVAS e classifica PARTIAL. |
| AS_IMPLEMENTED | CanvasSection existe, mas única entrada examinada é condicionada a legacyCanvasSurfaceEnabled=false. |
| AS_INTENDED | UNKNOWN: não localizada decisão de reativar, substituir ou descontinuar a superfície. |
| HUMAN_DECISION_REQUIRED | YES; decisão Product em retomada autorizada |
| SOURCE_EVIDENCE | [UI][S-UI]; [UI-FLAG][S-UI-FLAG]; [UI-ENTRY][S-UI-ENTRY] |

### FUND-C02

| FIELD | VALUE |
| --- | --- |
| CONFLICT_ID | FUND-C02 |
| STATUS | OPEN_PRODUCT_DECISION |
| DESCRIPTION | Elemento ativo versus elemento não arquivado |
| AFFECTED_FUNCTIONS | [F-FUND-003](#f-fund-003); [F-FUND-007](#f-fund-007); [F-FUND-009](#f-fund-009); [F-FUND-010](#f-fund-010); [F-FUND-018](#f-fund-018); [F-FUND-024](#f-fund-024); [F-FUND-033](#f-fund-033) |
| AFFECTED_RULES | [BR-SKPE-FUND-012](../business-rules/fundamentacao-negocio.md#br-skpe-fund-012); [BR-SKPE-FUND-043](../business-rules/fundamentacao-negocio.md#br-skpe-fund-043) |
| AS_DOCUMENTED | FE-004 exige conteúdo ativo nos nove blocos e nos três grupos. |
| AS_IMPLEMENTED | Readiness e extremos de fluxo aceitam status <> archived; schema permite draft/inactive. |
| AS_INTENDED | UNKNOWN: Product deve decidir elegibilidade e significado de active. |
| HUMAN_DECISION_REQUIRED | YES; decisão Product em retomada autorizada |
| SOURCE_EVIDENCE | [DOC][S-DOC]; [READY][S-READY]; [SCHEMA][S-SCHEMA] |

### FUND-C03

| FIELD | VALUE |
| --- | --- |
| CONFLICT_ID | FUND-C03 |
| STATUS | OPEN_PRODUCT_DECISION |
| DESCRIPTION | Prontidão corrente versus contexto histórico |
| AFFECTED_FUNCTIONS | [F-FUND-012](#f-fund-012); [F-FUND-018](#f-fund-018); [F-FUND-019](#f-fund-019); [F-FUND-021](#f-fund-021); [F-FUND-024](#f-fund-024); [F-FUND-033](#f-fund-033) |
| AFFECTED_RULES | [BR-SKPE-FUND-026](../business-rules/fundamentacao-negocio.md#br-skpe-fund-026); [BR-SKPE-FUND-043](../business-rules/fundamentacao-negocio.md#br-skpe-fund-043) |
| AS_DOCUMENTED | FE-004 preserva snapshot e afirma que evolução futura não altera retroativamente Formulação aprovada. |
| AS_IMPLEMENTED | Payload persiste, mas readiness lê versão viva e rejeita superseded; não se demonstrou regravação da Formulação aprovada. |
| AS_INTENDED | UNKNOWN: definir como apresentar e usar prontidão histórica/corrente; não declarar corrupção de snapshot. |
| HUMAN_DECISION_REQUIRED | YES; decisão Product em retomada autorizada |
| SOURCE_EVIDENCE | [DOC][S-DOC]; [FORM-READY][S-FORM-READY]; [LINK][S-LINK]; [TRANSITION][S-TRANSITION] |

### FUND-C04

| FIELD | VALUE |
| --- | --- |
| CONFLICT_ID | FUND-C04 |
| STATUS | OPEN_PRODUCT_DECISION |
| DESCRIPTION | Fronteira entre três modelos persistidos |
| AFFECTED_FUNCTIONS | [F-FUND-001](#f-fund-001); [F-FUND-018](#f-fund-018); [F-FUND-023](#f-fund-023); [F-FUND-024](#f-fund-024); [F-FUND-027](#f-fund-027); [F-FUND-028](#f-fund-028); [F-FUND-032](#f-fund-032); [F-FUND-033](#f-fund-033) |
| AFFECTED_RULES | [BR-SKPE-FUND-042](../business-rules/fundamentacao-negocio.md#br-skpe-fund-042); [BR-SKPE-FUND-043](../business-rules/fundamentacao-negocio.md#br-skpe-fund-043) |
| AS_DOCUMENTED | FE-004 prescreve objetos compartilhados, sem duplicação por módulo. |
| AS_IMPLEMENTED | Canvas de projeto, BMC/VPC legado e artefatos compartilhados coexistem; ponte/política de substituição não localizada. Não se afirma duplicação de dados reais. |
| AS_INTENDED | UNKNOWN: definir escopo, migração ou convivência e relação com SK-PN. |
| HUMAN_DECISION_REQUIRED | YES; decisão Product em retomada autorizada |
| SOURCE_EVIDENCE | [DOC][S-DOC]; [SCHEMA][S-SCHEMA]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA]; [CANVAS-SCHEMA][S-CANVAS-SCHEMA] |

Retomar FUND-C01–C04 somente em wave autorizada. Nenhum conflito bloqueia a baseline inteira. C01/C02/C04 de Medidas, FORM e IDENT permanecem sob seus owners, sem decisão ou edição nesta wave.

[S-SCHEMA]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L571-L969
[S-PERMISSION]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730033000_create_strategic_formulation_and_shared_business_architecture_foundation.sql#L239-L299
[S-GUARD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L47-L156
[S-CREATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L157-L376
[S-UPDATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L377-L478
[S-ELEMENT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L479-L661
[S-ARCHIVE-ELEMENT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L662-L730
[S-RELATION]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L731-L911
[S-DELETE-RELATION]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L912-L973
[S-READY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L974-L1254
[S-TRANSITION]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L1255-L1539
[S-REVISION]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L1540-L1779
[S-SNAPSHOT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L1780-L1883
[S-LINK]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L1884-L2146
[S-DISMISS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L2147-L2204
[S-FORM-READY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L2205-L2391
[S-FORM-GATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L2392-L2440
[S-READ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L2441-L2533
[S-AUDIT]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L2534-L2614
[S-PRIVILEGES]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730050000_create_business_foundation_and_value_chain_operations.sql#L2615-L2754
[S-CLONE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260730040000_create_strategic_formulation_governance_and_versioning.sql#L416-L480
[S-DOC]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-004_FUNDAMENTACAO_NEGOCIO_E_CADEIA_VALOR.md#L1-L142
[S-METHOD]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/docs/03-methodology/REQ-SKPE-FE-001_ARQUITETURA_CANONICA_FORMULACAO_ESTRATEGICA.md#L11-L153
[S-CANVAS-SCHEMA]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727011500_create_skpe_project_business_canvas.sql#L58-L215
[S-CANVAS-READ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727011500_create_skpe_project_business_canvas.sql#L436-L537
[S-CANVAS-WRITE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727011500_create_skpe_project_business_canvas.sql#L538-L744
[S-CANVAS-CREATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727013000_add_sustainability_esg_to_project_canvas.sql#L110-L263
[S-UI]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/SkpeCockpit.tsx#L1063-L1500
[S-UI-FLAG]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/SkpeCockpit.tsx#L1880-L1900
[S-UI-ENTRY]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/apps/web/src/modules/skpe/SkpeCockpit.tsx#L2248-L2270
[S-LEGACY-SCHEMA]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727023000_create_initiatives_business_artifacts_checklist_intelligence.sql#L353-L511
[S-LEGACY-READ]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727023000_create_initiatives_business_artifacts_checklist_intelligence.sql#L1104-L1169
[S-LEGACY-CREATE]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727024500_create_operational_functions_for_initiatives_artifacts_checklists.sql#L491-L646
[S-LEGACY-ITEM]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727024500_create_operational_functions_for_initiatives_artifacts_checklists.sql#L647-L734
[S-LEGACY-STATUS]: https://github.com/sparkooptech/skpe-saas/blob/d27373cc16740dfc86eb940abf639e322b072cc8/supabase/migrations/20260727024500_create_operational_functions_for_initiatives_artifacts_checklists.sql#L735-L794
