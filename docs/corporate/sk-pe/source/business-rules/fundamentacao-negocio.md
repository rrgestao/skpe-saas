---
id: sk-pe-fundamentacao-business-rules
title: Regras de Fundamentação do Negócio
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
  - skpe-fund-neg-01
  - skpe-form-ver-01
  - skpe-ident-01
  - sk-pe-current-state
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
  - ./README.md
  - ../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md
---

# Regras de Fundamentação do Negócio

Owner único de 43 regras de [SKPE-FUND-NEG-01](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md). [Contrato canônico](README.md#contrato-canônico-de-regra). Produto d27373cc16740dfc86eb940abf639e322b072cc8; sem delta. IMPLEMENTED_RULE != CONFIRMED_PRODUCT_RULE. Nenhuma regra recebe PRODUCT_ACCEPTED por estar em SQL, frontend ou documento técnico; nenhum aceite Product específico foi localizado.

## Natureza metodológica e autoridade

RULE_KIND distingue PRODUCT_RULE (contrato funcional), METHODOLOGICAL_RULE (conteúdo/método) e IMPLEMENTATION_RULE (mecanismo). AUTHORITY_CLASS é outro eixo: IMPLEMENTED_RULE não equivale a CONFIRMED_PRODUCT_RULE. A existência de critérios de aceite em FE-004 não prova sua execução nem aceite Product.

Há três vocabulários de blocos. No compartilhado, segmentos, necessidades, oferta, produtos, canais/relacionamentos, capacidades/recursos, parceiros, lógica econômica e riscos são códigos de Fundamentação, não nove entidades separadas. O BMC legado separa canais, relacionamento, receitas, custos, recursos, atividades, parceiros, proposta e segmentos nos nove blocos BR-SKPE-FUND-035. VPC legado tem seis blocos BR-SKPE-FUND-036. BMC/VPC compartilhados usam apenas prontidão genérica (BR-SKPE-FUND-013); não importar automaticamente regras da prática BMC/VPC.

Canvas do Projeto 2026.2 contém PURPOSE, STAKEHOLDERS, BENEFICIARIES, VALUE_PROPOSITION, DELIVERABLES, KEY_ACTIVITIES, KEY_RESOURCES, PARTNERS, GOVERNANCE, RISKS, SUSTAINABILITY_ESG, SUCCESS_METRICS, COSTS e BENEFITS. A marca is_mandatory dos 14 blocos não constitui um guard metodológico de aprovação localizado.

Coerência entre blocos, qualidade da proposta para segmentos, consistência econômico-financeira, derivação automática de capacidades, diagnóstico prévio e correspondência entre atividades-chave e processos não foram demonstrados nos predicados examinados. Não criar regra de software apenas porque essas práticas são relevantes ao método. Relação Identidade→Cadeia já pertence a BR-SKPE-IDENT-023, referenciada sem redefinição.

[DOC][S-DOC]; [READY][S-READY]; [CANVAS-CREATE][S-CANVAS-CREATE]; [LEGACY-CREATE][S-LEGACY-CREATE]; [METHOD][S-METHOD]

## RULE → FUNCTION

| RULE | TITLE | APPLIES_TO | RULE_KIND | AUTHORITY_CLASS | ACCEPTANCE_STATUS | TEST_COVERAGE |
| --- | --- | --- | --- | --- | --- | --- |
| [BR-SKPE-FUND-001](#br-skpe-fund-001) | Artefato compartilhado e escopo próprio | [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016); [F-FUND-022](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-022) | PRODUCT_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-002](#br-skpe-fund-002) | Tipos de artefato e payload | [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033) | PRODUCT_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-003](#br-skpe-fund-003) | Código e primeira versão | [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-004](#br-skpe-fund-004) | Edição não é revisão | [F-FUND-002](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-002); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-005](#br-skpe-fund-005) | Conteúdo de elemento | [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-006](#br-skpe-fund-006) | Hierarquia local e unicidade | [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-007](#br-skpe-fund-007) | Arquivo de elemento preserva estrutura | [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-004](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-004); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014); [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-008](#br-skpe-fund-008) | Relação entre elementos | [F-FUND-005](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-005); [F-FUND-006](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-006); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-009](#br-skpe-fund-009) | Exclusão de relação | [F-FUND-006](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-006); [F-FUND-004](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-004); [F-FUND-013](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-013) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-010](#br-skpe-fund-010) | Nove blocos da fundamentação | [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-009](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-009); [F-FUND-010](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-010); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-011](#br-skpe-fund-011) | Três grupos e fluxo da cadeia | [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-005](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-005); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-009](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-009); [F-FUND-010](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-010) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-012](#br-skpe-fund-012) | Ativo documental versus não arquivado | [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-009](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-009); [F-FUND-010](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-010); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018) | METHODOLOGICAL_RULE | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-FUND-013](#br-skpe-fund-013) | BMC/VPC compartilhado tem validação genérica | [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-014](#br-skpe-fund-014) | Completude não significa coerência | [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-015](#br-skpe-fund-015) | Iniciar e submeter versão | [F-FUND-008](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-008); [F-FUND-009](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-009) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-016](#br-skpe-fund-016) | Validar versão compartilhada | [F-FUND-010](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-010) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-017](#br-skpe-fund-017) | Devolução e maturidade | [F-FUND-011](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-011); [F-FUND-002](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-002); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-018](#br-skpe-fund-018) | Publicação e supersessão | [F-FUND-012](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-012); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-019](#br-skpe-fund-019) | Arquivo de versão | [F-FUND-013](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-013); [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-020](#br-skpe-fund-020) | Revisão e concorrência | [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-021](#br-skpe-fund-021) | Clone de artefato preserva linhagem | [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014); [F-FUND-032](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-032) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-022](#br-skpe-fund-022) | Snapshot é contexto capturado | [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-023](#br-skpe-fund-023) | Snapshot pode ser recapturado na elaboração | [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016); [F-FUND-022](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-022) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-024](#br-skpe-fund-024) | Vínculo de insumo e tipos | [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016); [F-FUND-021](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-021) | PRODUCT_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-025](#br-skpe-fund-025) | Primariedade e dispensa | [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016); [F-FUND-017](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-017); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-026](#br-skpe-fund-026) | Dois insumos fundamentais e prontidão viva | [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018); [F-FUND-019](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-019); [F-FUND-021](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-021); [F-FUND-012](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-012) | PRODUCT_RULE | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-FUND-027](#br-skpe-fund-027) | Leitura consolidada não é leitura do snapshot | [F-FUND-019](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-019); [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-028](#br-skpe-fund-028) | Auditoria consultada tem filtro restrito | [F-FUND-020](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-020); [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-004](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-004); [F-FUND-005](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-005) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-029](#br-skpe-fund-029) | Permissões específicas da arquitetura | [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-002](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-002); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-030](#br-skpe-fund-030) | Autossuficiência e compartilhamento pretendidos | [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033); [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016) | METHODOLOGICAL_RULE | DOCUMENTED_RULE | UNKNOWN | NONE |
| [BR-SKPE-FUND-031](#br-skpe-fund-031) | Relações entre versões são estrutura disponível | [F-FUND-032](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-032); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-032](#br-skpe-fund-032) | Canvas do Projeto tem template próprio | [F-FUND-023](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-023); [F-FUND-024](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-024) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-033](#br-skpe-fund-033) | Leitura legada e disponibilidade da superfície | [F-FUND-024](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-024); [F-FUND-023](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-023); [F-FUND-025](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-025); [F-FUND-026](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-026) | PRODUCT_RULE | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-FUND-034](#br-skpe-fund-034) | Item do Canvas do Projeto | [F-FUND-025](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-025); [F-FUND-026](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-026) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-035](#br-skpe-fund-035) | BMC legado possui nove blocos estruturais | [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-030](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-030) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-036](#br-skpe-fund-036) | VPC legado possui seis blocos estruturais | [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028); [F-FUND-030](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-030) | METHODOLOGICAL_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-037](#br-skpe-fund-037) | Versionamento BMC/VPC legado | [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028); [F-FUND-029](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-029) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-038](#br-skpe-fund-038) | Proveniência legada não prova importação | [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-039](#br-skpe-fund-039) | Leitura BMC/VPC não seleciona só vigente | [F-FUND-029](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-029) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-040](#br-skpe-fund-040) | Item BMC/VPC legado não herda guard FE-03 | [F-FUND-030](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-030) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-041](#br-skpe-fund-041) | Validação BMC/VPC legada é atualização de status | [F-FUND-031](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-031) | IMPLEMENTATION_RULE | IMPLEMENTED_RULE | IMPLEMENTED_NOT_ACCEPTED | NONE |
| [BR-SKPE-FUND-042](#br-skpe-fund-042) | Coexistência não comprova unificação | [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-023](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-023); [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028); [F-FUND-032](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-032); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033) | PRODUCT_RULE | CONFLICTING_RULE | PENDING_PRODUCT_DECISION | NONE |
| [BR-SKPE-FUND-043](#br-skpe-fund-043) | Decisões de fronteira permanecem pendentes | [F-FUND-024](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-024); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033) | PRODUCT_RULE | PENDING_PRODUCT_DECISION | PENDING_PRODUCT_DECISION | NONE |

## Regras detalhadas

### BR-SKPE-FUND-001

**ID:** BR-SKPE-FUND-001 · **TITLE:** Artefato compartilhado e escopo próprio · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016); [F-FUND-022](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-022)

**STATEMENT:** Cabeçalho pertence à organização, não à versão de Formulação; versão possui origem/projeto fonte opcionais e numeração própria. FK composta mantém artefato/organização; criação FE-03 exige Formulação editável e grava proveniência. · **RATIONALE:** Explicitar artefato compartilhado e escopo próprio no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifacts; platform_business_artifact_versions; skpe_strategic_formulations · **PRECONDITIONS:** Formulação editável para criar · **TRIGGER:** Criar/persistir

**CONSTRAINT:** Cabeçalho pertence à organização, não à versão de Formulação; versão possui origem/projeto fonte opcionais e numeração própria. FK composta mantém artefato/organização; criação FE-03 exige Formulação editável e grava proveniência. · **OUTCOME:** Artefato organizacional com versão própria · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA]; [CREATE][S-CREATE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-002

**ID:** BR-SKPE-FUND-002 · **TITLE:** Tipos de artefato e payload · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033)

**STATEMENT:** São 12 tipos enumerados no schema: business_foundation, value_proposition_canvas, business_model_canvas, value_chain, stakeholder_map, product_service_portfolio, market_analysis, capability_map, process_architecture, financial_model, risk_hypothesis_map, other_canvas. BMC/VPC/cadeia não são novas tabelas nesse modelo. · **RATIONALE:** Explicitar tipos de artefato e payload no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifacts; platform_business_artifact_versions · **PRECONDITIONS:** Tipo válido · **TRIGGER:** Criar artefato

**CONSTRAINT:** São 12 tipos enumerados no schema: business_foundation, value_proposition_canvas, business_model_canvas, value_chain, stakeholder_map, product_service_portfolio, market_analysis, capability_map, process_architecture, financial_model, risk_hypothesis_map, other_canvas. BMC/VPC/cadeia não são novas tabelas nesse modelo. · **OUTCOME:** Cabeçalho active e versão draft · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA]; [CREATE][S-CREATE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-003

**ID:** BR-SKPE-FUND-003 · **TITLE:** Código e primeira versão · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016)

**STATEMENT:** Criação exige código/nome/rótulo não vazios, verifica duplicidade case-insensitive sob lock organizacional e grava versão 1; constraint de código do schema usa valor exato. Criar não implica vincular à Formulação. · **RATIONALE:** Explicitar código e primeira versão no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifacts; platform_business_artifact_versions; skpe_formulation_business_inputs · **PRECONDITIONS:** Gestão autorizada · **TRIGGER:** create FE-03 (10 argumentos)

**CONSTRAINT:** Criação exige código/nome/rótulo não vazios, verifica duplicidade case-insensitive sob lock organizacional e grava versão 1; constraint de código do schema usa valor exato. Criar não implica vincular à Formulação. · **OUTCOME:** UUID de versão; sem insumo automático · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [CREATE][S-CREATE]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-004

**ID:** BR-SKPE-FUND-004 · **TITLE:** Edição não é revisão · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-002](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-002); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014)

**STATEMENT:** Cabeçalho de versão só edita draft/in_elaboration; label obrigatório e JSONs fornecidos devem ser objetos. Atualização mantém version_number, limpa notas e converte draft em in_elaboration. · **RATIONALE:** Explicitar edição não é revisão no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_versions · **PRECONDITIONS:** Versão editável · **TRIGGER:** update

**CONSTRAINT:** Cabeçalho de versão só edita draft/in_elaboration; label obrigatório e JSONs fornecidos devem ser objetos. Atualização mantém version_number, limpa notas e converte draft em in_elaboration. · **OUTCOME:** Mesma versão alterada · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** draft → in_elaboration

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [UPDATE][S-UPDATE]; [GUARD][S-GUARD] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-005

**ID:** BR-SKPE-FUND-005 · **TITLE:** Conteúdo de elemento · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003)

**STATEMENT:** Código, tipo e título não vazios; ordem negativa explícita rejeitada; structured_payload fornecido deve ser objeto; block_code é livre. Atualizar exige ID da versão; sem ID insere, não resolve por código. · **RATIONALE:** Explicitar conteúdo de elemento no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_elements; platform_business_artifact_versions · **PRECONDITIONS:** Versão editável · **TRIGGER:** upsert elemento

**CONSTRAINT:** Código, tipo e título não vazios; ordem negativa explícita rejeitada; structured_payload fornecido deve ser objeto; block_code é livre. Atualizar exige ID da versão; sem ID insere, não resolve por código. · **OUTCOME:** UUID; elemento active · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** elemento → active; versão draft → in_elaboration

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [ELEMENT][S-ELEMENT]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-006

**ID:** BR-SKPE-FUND-006 · **TITLE:** Hierarquia local e unicidade · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014)

**STATEMENT:** Código de elemento único por versão; pai deve estar na mesma versão e não ser o próprio elemento. Não foi localizada verificação recursiva de ciclos hierárquicos; não afirmar aciclicidade global. · **RATIONALE:** Explicitar hierarquia local e unicidade no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_elements (pai/filho) · **PRECONDITIONS:** Pai opcional · **TRIGGER:** Salvar hierarquia

**CONSTRAINT:** Código de elemento único por versão; pai deve estar na mesma versão e não ser o próprio elemento. Não foi localizada verificação recursiva de ciclos hierárquicos; não afirmar aciclicidade global. · **OUTCOME:** FK composta e checagem de auto-parentesco · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [ELEMENT][S-ELEMENT]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-007

**ID:** BR-SKPE-FUND-007 · **TITLE:** Arquivo de elemento preserva estrutura · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-004](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-004); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014); [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015)

**STATEMENT:** Arquivar marca archived sem excluir relações ou filhos. Upsert por ID pode reativar; prontidão ignora archived e flow com extremos arquivados. Snapshot/revisão incluem também arquivados. · **RATIONALE:** Explicitar arquivo de elemento preserva estrutura no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_elements; platform_business_artifact_element_relations; snapshot_payload · **PRECONDITIONS:** Versão editável para manutenção · **TRIGGER:** Arquivar/reativar

**CONSTRAINT:** Arquivar marca archived sem excluir relações ou filhos. Upsert por ID pode reativar; prontidão ignora archived e flow com extremos arquivados. Snapshot/revisão incluem também arquivados. · **OUTCOME:** Histórico lógico preservado · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** active → archived; upsert → active

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [ARCHIVE-ELEMENT][S-ARCHIVE-ELEMENT]; [ELEMENT][S-ELEMENT]; [READY][S-READY]; [REVISION][S-REVISION]; [SNAPSHOT][S-SNAPSHOT] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-008

**ID:** BR-SKPE-FUND-008 · **TITLE:** Relação entre elementos · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-005](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-005); [F-FUND-006](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-006); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007)

**STATEMENT:** Extremos distintos, não arquivados e da mesma versão. Tipos flow/supports/enables/delivers/contributes_to/derives_from/validates/conflicts_with/impacts; peso opcional 0..100. Não impõe soma de pesos 100 nem grafo acíclico. · **RATIONALE:** Explicitar relação entre elementos no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_element_relations; elementos de origem/destino · **PRECONDITIONS:** Versão editável · **TRIGGER:** Salvar relação

**CONSTRAINT:** Extremos distintos, não arquivados e da mesma versão. Tipos flow/supports/enables/delivers/contributes_to/derives_from/validates/conflicts_with/impacts; peso opcional 0..100. Não impõe soma de pesos 100 nem grafo acíclico. · **OUTCOME:** Relação única por origem/destino/tipo · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [RELATION][S-RELATION]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-009

**ID:** BR-SKPE-FUND-009 · **TITLE:** Exclusão de relação · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-006](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-006); [F-FUND-004](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-004); [F-FUND-013](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-013)

**STATEMENT:** delete retorna false se relação ausente, após validar motivo; existente exige versão editável, exclui e audita. Não há RPC pública de exclusão física de artefato/versão/elemento FE-03 localizada. · **RATIONALE:** Explicitar exclusão de relação no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_element_relations · **PRECONDITIONS:** Relação existente para excluir · **TRIGGER:** delete relação

**CONSTRAINT:** delete retorna false se relação ausente, após validar motivo; existente exige versão editável, exclui e audita. Não há RPC pública de exclusão física de artefato/versão/elemento FE-03 localizada. · **OUTCOME:** boolean; notas limpas · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [DELETE-RELATION][S-DELETE-RELATION]; [DOC][S-DOC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-010

**ID:** BR-SKPE-FUND-010 · **TITLE:** Nove blocos da fundamentação · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-009](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-009); [F-FUND-010](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-010); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016)

**STATEMENT:** Para business_foundation, readiness exige ao menos um elemento elegível por customer_segments, needs_jobs, value_offering, products_services, channels_relationships, capabilities_resources, partners, economic_logic e risks_hypotheses; rascunho pode estar incompleto. · **RATIONALE:** Explicitar nove blocos da fundamentação no recorte baseline; sem inferir aceite

**ENTITIES:** business_foundation; elementos dos nove block_code · **PRECONDITIONS:** Tipo business_foundation · **TRIGGER:** Prontidão

**CONSTRAINT:** Para business_foundation, readiness exige ao menos um elemento elegível por customer_segments, needs_jobs, value_offering, products_services, channels_relationships, capabilities_resources, partners, economic_logic e risks_hypotheses; rascunho pode estar incompleto. · **OUTCOME:** Ausência de bloco bloqueia · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [READY][S-READY]; [DOC][S-DOC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-011

**ID:** BR-SKPE-FUND-011 · **TITLE:** Três grupos e fluxo da cadeia · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-005](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-005); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-009](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-009); [F-FUND-010](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-010)

**STATEMENT:** value_chain exige governance_management, core_business e support, além de ao menos uma relação flow entre extremos elegíveis. Não exige que esse flow conecte todos os grupos. · **RATIONALE:** Explicitar três grupos e fluxo da cadeia no recorte baseline; sem inferir aceite

**ENTITIES:** value_chain; elementos dos três grupos; relações flow · **PRECONDITIONS:** Tipo value_chain · **TRIGGER:** Prontidão

**CONSTRAINT:** value_chain exige governance_management, core_business e support, além de ao menos uma relação flow entre extremos elegíveis. Não exige que esse flow conecte todos os grupos. · **OUTCOME:** Ausência de grupo ou flow bloqueia · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [READY][S-READY]; [DOC][S-DOC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-012

**ID:** BR-SKPE-FUND-012 · **TITLE:** Ativo documental versus não arquivado · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-009](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-009); [F-FUND-010](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-010); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018)

**STATEMENT:** FE-004 exige elementos ativos; SQL usa status <> archived, admitindo draft e inactive na contagem e nos extremos flow. Upsert público produz active, mas schema aceita estados adicionais. Divergência não foi resolvida. · **RATIONALE:** Explicitar ativo documental versus não arquivado no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_elements; prontidão de versão · **PRECONDITIONS:** Elemento draft/inactive admitido no schema · **TRIGGER:** Avaliar prontidão

**CONSTRAINT:** FE-004 exige elementos ativos; SQL usa status <> archived, admitindo draft e inactive na contagem e nos extremos flow. Upsert público produz active, mas schema aceita estados adicionais. Divergência não foi resolvida. · **OUTCOME:** FUND-C02 aberto · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [DOC][S-DOC]; [READY][S-READY]; [SCHEMA][S-SCHEMA]; [RELATION][S-RELATION] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** FUND-C02 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; resolver somente em wave funcional autorizada · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-013

**ID:** BR-SKPE-FUND-013 · **TITLE:** BMC/VPC compartilhado tem validação genérica · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028)

**STATEMENT:** Tipos diferentes de business_foundation/value_chain requerem pelo menos um elemento não arquivado. Não há nove blocos BMC ou seis VPC obrigatórios nesse readiness; os templates legados não transferem automaticamente rigor para FE-03. · **RATIONALE:** Explicitar bmc/vpc compartilhado tem validação genérica no recorte baseline; sem inferir aceite

**ENTITIES:** business_model_canvas/value_proposition_canvas compartilhados; blocos BMC/VPC legados · **PRECONDITIONS:** BMC/VPC compartilhado · **TRIGGER:** Prontidão

**CONSTRAINT:** Tipos diferentes de business_foundation/value_chain requerem pelo menos um elemento não arquivado. Não há nove blocos BMC ou seis VPC obrigatórios nesse readiness; os templates legados não transferem automaticamente rigor para FE-03. · **OUTCOME:** Um elemento pode satisfazer o predicado · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [READY][S-READY]; [LEGACY-CREATE][S-LEGACY-CREATE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-014

**ID:** BR-SKPE-FUND-014 · **TITLE:** Completude não significa coerência · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018)

**STATEMENT:** Percentual mede blocos preenchidos; 100% na cadeia pode coexistir com flow ausente e readyForValidation=false. Falta de descrição é recomendação. Não valida semântica proposta/segmentos, receitas/custos nem derivação de capacidades. · **RATIONALE:** Explicitar completude não significa coerência no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_versions; elementos; relações flow · **PRECONDITIONS:** Consulta · **TRIGGER:** Calcular completude

**CONSTRAINT:** Percentual mede blocos preenchidos; 100% na cadeia pode coexistir com flow ausente e readyForValidation=false. Falta de descrição é recomendação. Não valida semântica proposta/segmentos, receitas/custos nem derivação de capacidades. · **OUTCOME:** Percentual, issues e prontidão distintos · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [READY][S-READY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-015

**ID:** BR-SKPE-FUND-015 · **TITLE:** Iniciar e submeter versão · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-008](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-008); [F-FUND-009](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-009)

**STATEMENT:** begin_elaboration aceita draft; submit_validation aceita draft/in_elaboration e exige prontidão. Gestão de arquitetura autoriza ambos; leitura de prontidão acrescenta view efetivo na submissão. · **RATIONALE:** Explicitar iniciar e submeter versão no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_versions · **PRECONDITIONS:** Estados elegíveis · **TRIGGER:** begin_elaboration/submit_validation

**CONSTRAINT:** begin_elaboration aceita draft; submit_validation aceita draft/in_elaboration e exige prontidão. Gestão de arquitetura autoriza ambos; leitura de prontidão acrescenta view efetivo na submissão. · **OUTCOME:** Transição auditada · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** draft → in_elaboration; draft/in_elaboration → pending_validation

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION]; [READY][S-READY] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-016

**ID:** BR-SKPE-FUND-016 · **TITLE:** Validar versão compartilhada · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-010](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-010)

**STATEMENT:** validate exige pending_validation, validate de Formulação e prontidão autorizada; grava validador/data, completude 100 e eleva maturidade essential/structured/complete para validated. Não é aceite Product desta documentação. · **RATIONALE:** Explicitar validar versão compartilhada no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_versions · **PRECONDITIONS:** pending_validation pronta · **TRIGGER:** validate

**CONSTRAINT:** validate exige pending_validation, validate de Formulação e prontidão autorizada; grava validador/data, completude 100 e eleva maturidade essential/structured/complete para validated. Não é aceite Product desta documentação. · **OUTCOME:** Versão validated · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** pending_validation → validated

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-017

**ID:** BR-SKPE-FUND-017 · **TITLE:** Devolução e maturidade · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-011](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-011); [F-FUND-002](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-002); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007)

**STATEMENT:** return_for_adjustments aceita pending_validation/validated com validate OU approve de Formulação e notas >=10; limpa validação/publicação e retorna in_elaboration. Maturidade validated/published volta a essential; completeness_percent anterior não é limpo nesse ramo. · **RATIONALE:** Explicitar devolução e maturidade no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_versions · **PRECONDITIONS:** Estado elegível · **TRIGGER:** return_for_adjustments

**CONSTRAINT:** return_for_adjustments aceita pending_validation/validated com validate OU approve de Formulação e notas >=10; limpa validação/publicação e retorna in_elaboration. Maturidade validated/published volta a essential; completeness_percent anterior não é limpo nesse ramo. · **OUTCOME:** Versão reaberta; percentual deve ser interpretado com readiness · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** pending_validation/validated → in_elaboration

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-018

**ID:** BR-SKPE-FUND-018 · **TITLE:** Publicação e supersessão · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-012](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-012); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018)

**STATEMENT:** publish exige versão validated, approve de Formulação e prontidão; publicação anterior do mesmo artefato vira superseded, alvo published. Índice impede mais de uma published; não há ação approve autônoma para artefato. · **RATIONALE:** Explicitar publicação e supersessão no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_versions; publicação anterior · **PRECONDITIONS:** Versão validada e pronta · **TRIGGER:** publish

**CONSTRAINT:** publish exige versão validated, approve de Formulação e prontidão; publicação anterior do mesmo artefato vira superseded, alvo published. Índice impede mais de uma published; não há ação approve autônoma para artefato. · **OUTCOME:** Única publicação corrente · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** validated → published; published anterior → superseded

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-019

**ID:** BR-SKPE-FUND-019 · **TITLE:** Arquivo de versão · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-013](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-013); [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001)

**STATEMENT:** archive aceita somente draft/in_elaboration com gestão de arquitetura. archived existe na versão; status active/inactive/archived do cabeçalho de artefato é outro eixo sem RPC de transição localizada. · **RATIONALE:** Explicitar arquivo de versão no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_versions; platform_business_artifacts · **PRECONDITIONS:** Versão editável · **TRIGGER:** archive

**CONSTRAINT:** archive aceita somente draft/in_elaboration com gestão de arquitetura. archived existe na versão; status active/inactive/archived do cabeçalho de artefato é outro eixo sem RPC de transição localizada. · **OUTCOME:** Versão archived · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** draft/in_elaboration → archived

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [TRANSITION][S-TRANSITION]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-020

**ID:** BR-SKPE-FUND-020 · **TITLE:** Revisão e concorrência · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014)

**STATEMENT:** Revisão somente de published/superseded, rejeita outra versão draft/in_elaboration/pending_validation/validated e outra published corrente. Lock do artefato e max(version_number)+1; índice de versão aberta inclui só draft/in_elaboration/pending_validation, mais estreito que a RPC. · **RATIONALE:** Explicitar revisão e concorrência no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_versions; artefato bloqueado para revisão · **PRECONDITIONS:** Origem elegível · **TRIGGER:** create revisão

**CONSTRAINT:** Revisão somente de published/superseded, rejeita outra versão draft/in_elaboration/pending_validation/validated e outra published corrente. Lock do artefato e max(version_number)+1; índice de versão aberta inclui só draft/in_elaboration/pending_validation, mais estreito que a RPC. · **OUTCOME:** Nova versão draft/essential/completude 0 · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [REVISION][S-REVISION]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-021

**ID:** BR-SKPE-FUND-021 · **TITLE:** Clone de artefato preserva linhagem · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014); [F-FUND-032](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-032)

**STATEMENT:** Revisão copia content_payload, todos elementos e relações; remapeia pais/extremos; archived permanece archived e demais elementos viram active. derived_from_version_id e metadata registram origem. Relações entre versões da tabela separada não são clonadas por esse trecho. · **RATIONALE:** Explicitar clone de artefato preserva linhagem no recorte baseline; sem inferir aceite

**ENTITIES:** Versões, elementos e relações clonados; derived_from_version_id · **PRECONDITIONS:** Revisão autorizada · **TRIGGER:** Clone interno

**CONSTRAINT:** Revisão copia content_payload, todos elementos e relações; remapeia pais/extremos; archived permanece archived e demais elementos viram active. derived_from_version_id e metadata registram origem. Relações entre versões da tabela separada não são clonadas por esse trecho. · **OUTCOME:** IDs novos; conteúdo transportado · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [REVISION][S-REVISION]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-022

**ID:** BR-SKPE-FUND-022 · **TITLE:** Snapshot é contexto capturado · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016)

**STATEMENT:** Helper retorna JSON 1.0 com artefato, versão, status/maturidade, conteúdo, todos elementos/relações e capturedAt. link persiste snapshot_payload e data/schema. Proveniência completa reside também na linha da versão; não afirmar que o JSON contém todas suas colunas. · **RATIONALE:** Explicitar snapshot é contexto capturado no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_formulation_business_inputs.snapshot_payload; artefato/versão/elementos/relações capturados · **PRECONDITIONS:** Versão existente · **TRIGGER:** Capturar/vincular

**CONSTRAINT:** Helper retorna JSON 1.0 com artefato, versão, status/maturidade, conteúdo, todos elementos/relações e capturedAt. link persiste snapshot_payload e data/schema. Proveniência completa reside também na linha da versão; não afirmar que o JSON contém todas suas colunas. · **OUTCOME:** Snapshot persistido pelo vínculo · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [SNAPSHOT][S-SNAPSHOT]; [LINK][S-LINK]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-023

**ID:** BR-SKPE-FUND-023 · **TITLE:** Snapshot pode ser recapturado na elaboração · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016); [F-FUND-022](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-022)

**STATEMENT:** Upsert por formulation_id/version_id/role substitui snapshot_payload e captured_at e reativa vínculo. Não é append-only nessa fase. Proteção após aprovação e cópia na revisão pertencem às regras transversais de Formulação. · **RATIONALE:** Explicitar snapshot pode ser recapturado na elaboração no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_formulation_business_inputs; Formulação origem/destino · **PRECONDITIONS:** Formulação editável · **TRIGGER:** Relink/revisão

**CONSTRAINT:** Upsert por formulation_id/version_id/role substitui snapshot_payload e captured_at e reativa vínculo. Não é append-only nessa fase. Proteção após aprovação e cópia na revisão pertencem às regras transversais de Formulação. · **OUTCOME:** Contexto substituível antes do bloqueio; clone preserva JSON · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LINK][S-LINK]; [CLONE][S-CLONE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-024

**ID:** BR-SKPE-FUND-024 · **TITLE:** Vínculo de insumo e tipos · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016); [F-FUND-021](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-021)

**STATEMENT:** Versão deve ser validada/publicada, pronta e da mesma organização da Formulação; origem pode ser outro projeto. Quatro roles têm pareamento obrigatório: business_foundation, value_chain, value_proposition→VPC e business_model→BMC. · **RATIONALE:** Explicitar vínculo de insumo e tipos no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_formulation_business_inputs; versão/artefato; Formulação · **PRECONDITIONS:** Formulação editável · **TRIGGER:** link

**CONSTRAINT:** Versão deve ser validada/publicada, pronta e da mesma organização da Formulação; origem pode ser outro projeto. Quatro roles têm pareamento obrigatório: business_foundation, value_chain, value_proposition→VPC e business_model→BMC. · **OUTCOME:** Insumo active referindo versão exata · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LINK][S-LINK]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-025

**ID:** BR-SKPE-FUND-025 · **TITLE:** Primariedade e dispensa · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016); [F-FUND-017](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-017); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018)

**STATEMENT:** Um primário active por Formulação/role. Novo primário pode marcar anterior superseded/primary=false; dismiss preserva snapshot e marca dismissed/primary=false. requirement_level não substitui a exigência dos dois primários no readiness. · **RATIONALE:** Explicitar primariedade e dispensa no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_formulation_business_inputs · **PRECONDITIONS:** Formulação editável para mutar · **TRIGGER:** Vincular/dispensar

**CONSTRAINT:** Um primário active por Formulação/role. Novo primário pode marcar anterior superseded/primary=false; dismiss preserva snapshot e marca dismissed/primary=false. requirement_level não substitui a exigência dos dois primários no readiness. · **OUTCOME:** Papéis ativos preservam unicidade · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** insumo → active/superseded/dismissed

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LINK][S-LINK]; [DISMISS][S-DISMISS]; [FORM-READY][S-FORM-READY]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-026

**ID:** BR-SKPE-FUND-026 · **TITLE:** Dois insumos fundamentais e prontidão viva · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018); [F-FUND-019](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-019); [F-FUND-021](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-021); [F-FUND-012](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-012)

**STATEMENT:** Prontidão exige business_foundation e value_chain primários ativos. Consulta status e conteúdo vivos da versão, não snapshot_payload: publicação posterior pode superseder a versão vinculada e mudar readiness mesmo com snapshot preservado. Decidir prontidão histórica versus corrente permanece aberto. · **RATIONALE:** Explicitar dois insumos fundamentais e prontidão viva no recorte baseline; sem inferir aceite

**ENTITIES:** Formulação; insumos primários; versões vivas; snapshot_payload · **PRECONDITIONS:** Versão vinculada muda fora da Formulação · **TRIGGER:** Consultar/avançar

**CONSTRAINT:** Prontidão exige business_foundation e value_chain primários ativos. Consulta status e conteúdo vivos da versão, não snapshot_payload: publicação posterior pode superseder a versão vinculada e mudar readiness mesmo com snapshot preservado. Decidir prontidão histórica versus corrente permanece aberto. · **OUTCOME:** FUND-C03 aberto · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [FORM-READY][S-FORM-READY]; [READ][S-READ]; [DOC][S-DOC]; [TRANSITION][S-TRANSITION] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** FUND-C03 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; resolver somente em wave funcional autorizada · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-027

**ID:** BR-SKPE-FUND-027 · **TITLE:** Leitura consolidada não é leitura do snapshot · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-019](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-019); [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016)

**STATEMENT:** Consulta devolve insumos ativos, descritores vivos e schema/data de captura, mas não snapshot_payload. Consumidor não deve tratar o descritor atual como o conteúdo histórico capturado. · **RATIONALE:** Explicitar leitura consolidada não é leitura do snapshot no recorte baseline; sem inferir aceite

**ENTITIES:** Formulação; insumos; artefatos e versões consultados · **PRECONDITIONS:** Formulação autorizada · **TRIGGER:** get arquitetura

**CONSTRAINT:** Consulta devolve insumos ativos, descritores vivos e schema/data de captura, mas não snapshot_payload. Consumidor não deve tratar o descritor atual como o conteúdo histórico capturado. · **OUTCOME:** JSON consolidado com limites explícitos · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [READ][S-READ]; [SNAPSHOT][S-SNAPSHOT] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-028

**ID:** BR-SKPE-FUND-028 · **TITLE:** Auditoria consultada tem filtro restrito · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-020](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-020); [F-FUND-003](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-003); [F-FUND-004](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-004); [F-FUND-005](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-005)

**STATEMENT:** Consulta restringe organização/projeto e tipos; exige source_entity_id/formulation_id direto no JSON antes/depois ou ID de insumo atual. Eventos de elementos/artefato com apenas FK ou metadata aninhada podem não entrar; não equivale a histórico completo de todos os filhos. · **RATIONALE:** Explicitar auditoria consultada tem filtro restrito no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_operational_audit; Formulação; insumos e entidades auditadas · **PRECONDITIONS:** view de Formulação · **TRIGGER:** get audit

**CONSTRAINT:** Consulta restringe organização/projeto e tipos; exige source_entity_id/formulation_id direto no JSON antes/depois ou ID de insumo atual. Eventos de elementos/artefato com apenas FK ou metadata aninhada podem não entrar; não equivale a histórico completo de todos os filhos. · **OUTCOME:** Subconjunto auditável; cobertura total não afirmada · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [AUDIT][S-AUDIT]; [ELEMENT][S-ELEMENT]; [CREATE][S-CREATE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-029

**ID:** BR-SKPE-FUND-029 · **TITLE:** Permissões específicas da arquitetura · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-002](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-002); [F-FUND-007](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-007); [F-FUND-015](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-015); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033)

**STATEMENT:** view/manage_business_architecture admite org-admin ou permissões de arquitetura SK-PE, Formulação SK-PE ou arquitetura SK-PN. Não foi localizada checagem de licença SK-PN; helpers internos de edição/captura não são executáveis por authenticated. · **RATIONALE:** Explicitar permissões específicas da arquitetura no recorte baseline; sem inferir aceite

**ENTITIES:** Organização/permissões; artefatos/versões; helpers internos · **PRECONDITIONS:** Usuário autorizado · **TRIGGER:** Operações públicas e internas

**CONSTRAINT:** view/manage_business_architecture admite org-admin ou permissões de arquitetura SK-PE, Formulação SK-PE ou arquitetura SK-PN. Não foi localizada checagem de licença SK-PN; helpers internos de edição/captura não são executáveis por authenticated. · **OUTCOME:** Privilégios por contrato; não comprova integração SK-PN · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [PERMISSION][S-PERMISSION]; [GUARD][S-GUARD]; [PRIVILEGES][S-PRIVILEGES] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-030

**ID:** BR-SKPE-FUND-030 · **TITLE:** Autossuficiência e compartilhamento pretendidos · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033); [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-016](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-016)

**STATEMENT:** FE-004 prevê produção essencial no SK-PE sem licença SK-PN e aprofundamento do mesmo objeto por SK-PN. Enum origin_module/usage_mode e flags handoff não demonstram envio, recebimento, reconciliação ou licenciamento observado. · **RATIONALE:** Explicitar autossuficiência e compartilhamento pretendidos no recorte baseline; sem inferir aceite

**ENTITIES:** Artefatos compartilhados; versões; origem e handoff · **PRECONDITIONS:** Frente de negócio · **TRIGGER:** Planejar reutilização

**CONSTRAINT:** FE-004 prevê produção essencial no SK-PE sem licença SK-PN e aprofundamento do mesmo objeto por SK-PN. Enum origin_module/usage_mode e flags handoff não demonstram envio, recebimento, reconciliação ou licenciamento observado. · **OUTCOME:** Interface documentada; não declarar integração executada · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** DOCUMENTED_RULE · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** UNKNOWN · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [DOC][S-DOC]; [SCHEMA][S-SCHEMA]; [LINK][S-LINK] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-031

**ID:** BR-SKPE-FUND-031 · **TITLE:** Relações entre versões são estrutura disponível · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-032](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-032); [F-FUND-014](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-014)

**STATEMENT:** Tabela admite supports/derives_from/complements/depends_on/validates/updates/feeds/conflicts_with, extremos distintos e da mesma organização. Sem RPC pública localizada no FE-03, não inferir derivação automática entre Canvas e Cadeia. · **RATIONALE:** Explicitar relações entre versões são estrutura disponível no recorte baseline; sem inferir aceite

**ENTITIES:** platform_business_artifact_version_relations · **PRECONDITIONS:** Versões existentes · **TRIGGER:** Persistir relação estrutural

**CONSTRAINT:** Tabela admite supports/derives_from/complements/depends_on/validates/updates/feeds/conflicts_with, extremos distintos e da mesma organização. Sem RPC pública localizada no FE-03, não inferir derivação automática entre Canvas e Cadeia. · **OUTCOME:** PARTIAL: schema sem fluxo operacional demonstrado · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [SCHEMA][S-SCHEMA]; [DOC][S-DOC] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-032

**ID:** BR-SKPE-FUND-032 · **TITLE:** Canvas do Projeto tem template próprio · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-023](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-023); [F-FUND-024](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-024)

**STATEMENT:** create legado retorna Canvas corrente ou cria draft versão 1/template SKPE-PROJECT-BMC-2026.2 com 14 blocos obrigatórios incluindo ESG. Não são os nove blocos do BMC organizacional; is_mandatory não comprova guard de completude. · **RATIONALE:** Explicitar canvas do projeto tem template próprio no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_project_canvases; skpe_project_canvas_blocks · **PRECONDITIONS:** Projeto autorizado não arquivado · **TRIGGER:** Criar Canvas

**CONSTRAINT:** create legado retorna Canvas corrente ou cria draft versão 1/template SKPE-PROJECT-BMC-2026.2 com 14 blocos obrigatórios incluindo ESG. Não são os nove blocos do BMC organizacional; is_mandatory não comprova guard de completude. · **OUTCOME:** Um corrente por projeto · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [CANVAS-CREATE][S-CANVAS-CREATE]; [CANVAS-SCHEMA][S-CANVAS-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-033

**ID:** BR-SKPE-FUND-033 · **TITLE:** Leitura legada e disponibilidade da superfície · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-024](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-024); [F-FUND-023](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-023); [F-FUND-025](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-025); [F-FUND-026](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-026)

**STATEMENT:** CanvasSection carrega primeiro projeto retornado pela jornada; chamada é condicionada a legacyCanvasSurfaceEnabled=false. A referência CANVAS da baseline comprova código presente, mas não tela alcançável. Política de retomada/substituição não localizada. · **RATIONALE:** Explicitar leitura legada e disponibilidade da superfície no recorte baseline; sem inferir aceite

**ENTITIES:** CanvasSection; projeto escolhido; Canvas do Projeto · **PRECONDITIONS:** Entrada atual do Cockpit · **TRIGGER:** Renderizar Canvas

**CONSTRAINT:** CanvasSection carrega primeiro projeto retornado pela jornada; chamada é condicionada a legacyCanvasSurfaceEnabled=false. A referência CANVAS da baseline comprova código presente, mas não tela alcançável. Política de retomada/substituição não localizada. · **OUTCOME:** FUND-C01 permanece aberto · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [UI][S-UI]; [UI-FLAG][S-UI-FLAG]; [UI-ENTRY][S-UI-ENTRY] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** APPLICATION_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** FUND-C01 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; resolver somente em wave funcional autorizada · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-034

**ID:** BR-SKPE-FUND-034 · **TITLE:** Item do Canvas do Projeto · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-025](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-025); [F-FUND-026](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-026)

**STATEMENT:** Adicionar exige conteúdo não vazio, prioridade low/medium/high/critical e gera ordem max+10; motivo de inclusão pode ser nulo no SQL. Troca de status exige justificativa >=10 e aceita active/validated/discarded sem matriz de origem. · **RATIONALE:** Explicitar item do canvas do projeto no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_project_canvas_items; skpe_project_canvas_history · **PRECONDITIONS:** Gestão de Canvas · **TRIGGER:** Adicionar/trocar status

**CONSTRAINT:** Adicionar exige conteúdo não vazio, prioridade low/medium/high/critical e gera ordem max+10; motivo de inclusão pode ser nulo no SQL. Troca de status exige justificativa >=10 e aceita active/validated/discarded sem matriz de origem. · **OUTCOME:** Item e histórico atualizados · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** item → active/validated/discarded

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [CANVAS-WRITE][S-CANVAS-WRITE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-035

**ID:** BR-SKPE-FUND-035 · **TITLE:** BMC legado possui nove blocos estruturais · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-030](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-030)

**STATEMENT:** Criação bmc semeia KEY_PARTNERS, KEY_ACTIVITIES, KEY_RESOURCES, VALUE_PROPOSITIONS, CUSTOMER_RELATIONSHIPS, CHANNELS, CUSTOMER_SEGMENTS, COST_STRUCTURE, REVENUE_STREAMS. Semear não valida coerência entre eles. · **RATIONALE:** Explicitar bmc legado possui nove blocos estruturais no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_business_artifacts bmc; skpe_business_artifact_blocks · **PRECONDITIONS:** Tipo bmc · **TRIGGER:** create legado

**CONSTRAINT:** Criação bmc semeia KEY_PARTNERS, KEY_ACTIVITIES, KEY_RESOURCES, VALUE_PROPOSITIONS, CUSTOMER_RELATIONSHIPS, CHANNELS, CUSTOMER_SEGMENTS, COST_STRUCTURE, REVENUE_STREAMS. Semear não valida coerência entre eles. · **OUTCOME:** Nove blocos vazios · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LEGACY-CREATE][S-LEGACY-CREATE] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-036

**ID:** BR-SKPE-FUND-036 · **TITLE:** VPC legado possui seis blocos estruturais · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028); [F-FUND-030](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-030)

**STATEMENT:** vpc_external/vpc_cooperative_member/vpc_consolidated semeiam CUSTOMER_JOBS, PAINS, GAINS, PRODUCTS_SERVICES, PAIN_RELIEVERS, GAIN_CREATORS. consolidated é tipo, não algoritmo de síntese identificado. · **RATIONALE:** Explicitar vpc legado possui seis blocos estruturais no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_business_artifacts vpc_*; skpe_business_artifact_blocks · **PRECONDITIONS:** Tipo VPC · **TRIGGER:** create legado

**CONSTRAINT:** vpc_external/vpc_cooperative_member/vpc_consolidated semeiam CUSTOMER_JOBS, PAINS, GAINS, PRODUCTS_SERVICES, PAIN_RELIEVERS, GAIN_CREATORS. consolidated é tipo, não algoritmo de síntese identificado. · **OUTCOME:** Seis blocos vazios · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** METHODOLOGICAL_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LEGACY-CREATE][S-LEGACY-CREATE]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-037

**ID:** BR-SKPE-FUND-037 · **TITLE:** Versionamento BMC/VPC legado · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028); [F-FUND-029](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-029)

**STATEMENT:** Overload de 15 argumentos incrementa versão por organização/tipo/código, retira is_current anterior e muda validated anterior para outdated. Cria novos blocos vazios, sem clone dos itens; project_id é opcional e não compõe chave de versionamento. · **RATIONALE:** Explicitar versionamento bmc/vpc legado no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_business_artifacts; blocos legados · **PRECONDITIONS:** Organização e código · **TRIGGER:** Criar nova linha-versionamento

**CONSTRAINT:** Overload de 15 argumentos incrementa versão por organização/tipo/código, retira is_current anterior e muda validated anterior para outdated. Cria novos blocos vazios, sem clone dos itens; project_id é opcional e não compõe chave de versionamento. · **OUTCOME:** Novo artefato draft corrente · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LEGACY-CREATE][S-LEGACY-CREATE]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-038

**ID:** BR-SKPE-FUND-038 · **TITLE:** Proveniência legada não prova importação · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033)

**STATEMENT:** source_module admite SK-PN/SK-PE/external; import_method admite native_integration/structured_import/file_import/manual; referências e caminhos são campos declarados. RPC apenas registra esses valores, não baixa arquivo nem invoca SK-PN. · **RATIONALE:** Explicitar proveniência legada não prova importação no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_business_artifacts (campos de proveniência) · **PRECONDITIONS:** Criação legada · **TRIGGER:** Registrar origem

**CONSTRAINT:** source_module admite SK-PN/SK-PE/external; import_method admite native_integration/structured_import/file_import/manual; referências e caminhos são campos declarados. RPC apenas registra esses valores, não baixa arquivo nem invoca SK-PN. · **OUTCOME:** Proveniência declarada; transporte não demonstrado · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LEGACY-CREATE][S-LEGACY-CREATE]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-039

**ID:** BR-SKPE-FUND-039 · **TITLE:** Leitura BMC/VPC não seleciona só vigente · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-029](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-029)

**STATEMENT:** get_skpe_business_artifacts filtra organização, archived_at null e projeto opcional; retorna is_current e contagens sem filtrar versão corrente ou status validated. · **RATIONALE:** Explicitar leitura bmc/vpc não seleciona só vigente no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_business_artifacts; blocks/items/links agregados · **PRECONDITIONS:** view · **TRIGGER:** Consultar catálogo

**CONSTRAINT:** get_skpe_business_artifacts filtra organização, archived_at null e projeto opcional; retorna is_current e contagens sem filtrar versão corrente ou status validated. · **OUTCOME:** Lista com versões e estados distintos · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LEGACY-READ][S-LEGACY-READ] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-040

**ID:** BR-SKPE-FUND-040 · **TITLE:** Item BMC/VPC legado não herda guard FE-03 · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-030](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-030)

**STATEMENT:** add exige gestão e motivo, grava not_assessed; tipos statement/hypothesis/evidence/decision/risk/opportunity e prioridades enum vêm do schema. Não checa status editável do artefato nem valida vínculo de journey pela mesma organização nessa RPC. · **RATIONALE:** Explicitar item bmc/vpc legado não herda guard fe-03 no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_business_artifact_items; bloco e artefato legado; journey_item · **PRECONDITIONS:** Bloco existente · **TRIGGER:** Adicionar item

**CONSTRAINT:** add exige gestão e motivo, grava not_assessed; tipos statement/hypothesis/evidence/decision/risk/opportunity e prioridades enum vêm do schema. Não checa status editável do artefato nem valida vínculo de journey pela mesma organização nessa RPC. · **OUTCOME:** Item novo; não promover ao contrato compartilhado · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LEGACY-ITEM][S-LEGACY-ITEM]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-041

**ID:** BR-SKPE-FUND-041 · **TITLE:** Validação BMC/VPC legada é atualização de status · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-031](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-031)

**STATEMENT:** set_status usa manage, aceita estados do schema sem matriz de transição/prontidão e marca validated_at/by ao validar. Não executa cadeia pending_validation→validated→published FE-03. · **RATIONALE:** Explicitar validação bmc/vpc legada é atualização de status no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_business_artifacts · **PRECONDITIONS:** Artefato existente · **TRIGGER:** set_status

**CONSTRAINT:** set_status usa manage, aceita estados do schema sem matriz de transição/prontidão e marca validated_at/by ao validar. Não executa cadeia pending_validation→validated→published FE-03. · **OUTCOME:** draft/under_review/validated/outdated/archived · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** qualquer estado → estado admitido

**RULE_KIND:** IMPLEMENTATION_RULE · **AUTHORITY_CLASS:** IMPLEMENTED_RULE · **VERIFICATION_STATUS:** SQL_CONFIRMED · **ACCEPTANCE_STATUS:** IMPLEMENTED_NOT_ACCEPTED · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [LEGACY-STATUS][S-LEGACY-STATUS]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] · **CONFIDENCE:** HIGH · **ENFORCEMENT:** DATABASE_ENFORCED · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** NONE · **PENDING_DECISION:** NONE · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-042

**ID:** BR-SKPE-FUND-042 · **TITLE:** Coexistência não comprova unificação · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-001](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-001); [F-FUND-023](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-023); [F-FUND-027](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-027); [F-FUND-028](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-028); [F-FUND-032](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-032); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033)

**STATEMENT:** FE-004 determina objetos compartilhados; baseline contém Canvas do Projeto, BMC/VPC skpe_business_* e platform_business_* com versionamentos diferentes. Não foi localizada ponte de migração/sincronização ou política de substituição; não afirmar que sejam o mesmo objeto. · **RATIONALE:** Explicitar coexistência não comprova unificação no recorte baseline; sem inferir aceite

**ENTITIES:** skpe_project_canvases; skpe_business_artifacts; platform_business_artifacts · **PRECONDITIONS:** Confrontar persistências · **TRIGGER:** Retomar arquitetura de negócio

**CONSTRAINT:** FE-004 determina objetos compartilhados; baseline contém Canvas do Projeto, BMC/VPC skpe_business_* e platform_business_* com versionamentos diferentes. Não foi localizada ponte de migração/sincronização ou política de substituição; não afirmar que sejam o mesmo objeto. · **OUTCOME:** FUND-C04 aberto · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** CONFLICTING_RULE · **VERIFICATION_STATUS:** PARTIAL · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [DOC][S-DOC]; [SCHEMA][S-SCHEMA]; [CANVAS-SCHEMA][S-CANVAS-SCHEMA]; [LEGACY-SCHEMA][S-LEGACY-SCHEMA] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** FUND-C04 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; resolver somente em wave funcional autorizada · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

### BR-SKPE-FUND-043

**ID:** BR-SKPE-FUND-043 · **TITLE:** Decisões de fronteira permanecem pendentes · **CAPABILITY:** SKPE-FUND-NEG-01 · **APPLIES_TO:** [F-FUND-024](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-024); [F-FUND-018](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-018); [F-FUND-033](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#f-fund-033)

**STATEMENT:** Product precisa definir disponibilidade da superfície, elegibilidade active, prontidão histórica e fronteira entre persistências quando a capability for retomada. A engenharia reversa não resolve esses pontos nem bloqueia toda a baseline. · **RATIONALE:** Explicitar decisões de fronteira permanecem pendentes no recorte baseline; sem inferir aceite

**ENTITIES:** Superfície de Canvas; elementos; versões; snapshot; modelos legados/compartilhados · **PRECONDITIONS:** Retomada futura autorizada · **TRIGGER:** Decisão humana

**CONSTRAINT:** Product precisa definir disponibilidade da superfície, elegibilidade active, prontidão histórica e fronteira entre persistências quando a capability for retomada. A engenharia reversa não resolve esses pontos nem bloqueia toda a baseline. · **OUTCOME:** OPEN_PRODUCT_DECISION · **EXCEPTIONS:** Sem exceção adicional comprovada além das ressalvas do enunciado · **STATE_TRANSITIONS:** N/A

**RULE_KIND:** PRODUCT_RULE · **AUTHORITY_CLASS:** PENDING_PRODUCT_DECISION · **VERIFICATION_STATUS:** DOCUMENT_CONFIRMED · **ACCEPTANCE_STATUS:** PENDING_PRODUCT_DECISION · **ACCEPTANCE_EVIDENCE:** NOT_LOCATED: critérios técnicos FE-004 não comprovam aceite executado por Product

**TEST_COVERAGE:** NONE · **TEST_EVIDENCE:** Nenhum assert dedicado localizado nas suítes versionadas pesquisadas; testes externos não examinados

**SOURCE_TYPE:** Documento/SQL/frontend conforme evidência fixada · **SOURCE_EVIDENCE:** [DOC][S-DOC]; [UI-FLAG][S-UI-FLAG]; [FORM-READY][S-FORM-READY]; [SCHEMA][S-SCHEMA] · **CONFIDENCE:** MEDIUM · **ENFORCEMENT:** DOCUMENTED_ONLY · **CATEGORY:** fundamentação do negócio

**CONFLICTS:** FUND-C01; FUND-C02; FUND-C03; FUND-C04 · **PENDING_DECISION:** OPEN_PRODUCT_DECISION; resolver somente em wave funcional autorizada · **OBSERVABILITY:** Leitura estática da baseline; nenhuma observação de runtime

## Referências transversais sem duplicação

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

## Testes e dívida

Busca estática nas suítes versionadas apps/web/tests, tests, supabase/tests, em arquivos test/spec sob apps/packages e em scripts/docs de verificação, pelos nomes das tabelas/RPCs, business_foundation, business_artifact, project_canvas e value_chain. Não houve assert dedicado localizado. Também não foi localizado verificador FE-03 versionado pelos nomes examinados. O critério documental de “verificador retornar OK” não é resultado de teste executado.

Cada regra local recebe TEST_COVERAGE=NONE dentro desse escopo; não se afirma inexistência de testes externos. Nenhuma migration, RPC, banco ou runtime foi executado. A validação documental verifica links/IDs/rastreabilidade e não conta como teste de produto.

Dívida de testes: permissões por operação; isolamento organizacional; bloqueio de edição; unicidade e concorrência da revisão; remapeamento de pais/extremos e arquivados no clone; matrizes de transição; active versus não arquivado; completude 100 sem flow; captura/recaptura/clone e timestamps do snapshot; mudança da prontidão após supersessão; primariedade e dispensa; filtros de auditoria; retorno dos contratos legados; consumidor frontend e integração SK-PN. A falta de teste direto/indireto não autoriza promover regra a aceita.

## Conflitos

[FUND-C01 a FUND-C04](../capabilities/SKPE-FUND-NEG-01-fundamentacao-negocio.md#conflitos-e-retomada) permanecem OPEN_PRODUCT_DECISION. Aceite pendente não implica bloqueio de toda baseline; a próxima ação segura é revisar a documentação desta branch.

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
