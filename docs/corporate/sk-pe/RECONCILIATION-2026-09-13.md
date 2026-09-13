---
id: skpe-corporate-dev-reconciliation-2026-09-13
title: Reconciliação Corporate × DEV do SK-PE — 2026-09-13
domain: products
type: reconciliation
status: active
owner: dev
canonicality: supporting
canonical: false
language: pt-BR
---

# Reconciliação Corporate × DEV — SK-PE

## Escopo e fontes

Corporate/Product:
- repositório `br-robson/projetos`;
- branch `main`;
- Source SHA `35583cc835cba6c71ed0c0f2d7cd4a1412b6fae6`;
- path `docs/products/sk-pe/`.

DEV:
- repositório `sparkooptech/skpe-saas`;
- base Corporate investigada originalmente no produto: `d27373cc16740dfc86eb940abf639e322b072cc8`;
- sprint Medidas encerrada em `429aa03b2a96aac59b487329c60349ebf4ec0f26`;
- implementação de Monitoramento alcançou `eedf3ceb237f7c9ee3d49f7a84f96aefce535c6b`.

Regra: implementação é evidência; não promove sozinha decisão, status ou regra Product.## Matriz de reconciliação

| Artefato / capability | Corporate diz | DEV hoje tem | Classificação | Decisão recomendada | Próximo gate |
| --- | --- | --- | --- | --- | --- |
| Product Hub `README.md` | Product Space SK-PE é autoridade documental canônica | Mirror local criado como referência, sem autoridade | STILL_VALID | Trazer integralmente e preservar autoridade Corporate | Nenhum gate técnico; apenas sincronização controlada |
| `roadmap.md` | Medidas=CURRENT/NOW; Monitoramento=NEXT; Formulação=terceira prioridade | Medidas e Monitoramento avançaram muito além da baseline Corporate | STATUS_STALE / SEMANTICS_VALID | Preservar prioridades como histórico de decisão, mas reconciliar status com evidência DEV antes de reutilizar como estado corrente | Corporate Product Review |
| `current-state.md` | Baseline em `d27373c`, com 31 recortes e conflitos explícitos | HEAD DEV atual está em `eedf3ce`, com várias lacunas do baseline já trabalhadas | HISTORICAL_BASELINE | Trazer integralmente com ressalva explícita de snapshot histórico | Rebaseline AS-IMPLEMENTED / AS-OBSERVED |
| Governance | Execução incremental, evidência e promoção separadas | Processo seguido nas sprints recentes | STILL_VALID | Trazer integralmente e manter como regra de governança | Nenhum, salvo revisão Product futura |
| `SKPE-MED-DES-01` | ACTIVE/PARTIAL_WITH_EXPLICIT_CONFLICTS; C01/C02/C04 abertos | Sprint própria concluída; read model, owner enrichment, UX e runtime auth auditados | PARTIALLY_RECONCILED | Não declarar todos os conflitos resolvidos; revisar C01/C02/C04 contra `429aa03+` | Acceptance/Reconciliation de Medidas |
| `SKPE-MON-ANL-01` | Frontend implementado, aceite parcial e conflitos; prioridade NEXT | Readiness, FE-08, lifecycle, coleta, validação, RAE, decisão, aprendizado, fechamento e reabertura implementados | IMPLEMENTATION_ADVANCED | Atualizar Corporate após revisão; não declarar DONE sem aceite e runtime real | Corporate rebase + acceptance |
| `SKPE-FORM-VER-01` | 19 funções; várias PARTIAL/CONFLICT na baseline | Lifecycle principal agora está operacionalizado no frontend pelo G3A | PARTIALLY_RESOLVED | Reavaliar função por função; preservar gaps de criação/revisão/clonagem/arquivo não comprovados | Gap Review de Formulação |
| `SKPE-FUND-NEG-01` | Owner canônico existente | Não foi alterado nesta wave | NOT_RECONCILED_IN_THIS_WAVE | Trazer integralmente; sem mudança de status | Futuro gate conforme roadmap Product |
| `SKPE-IDENT-01` | Owner canônico existente | Não foi alterado nesta wave | NOT_RECONCILED_IN_THIS_WAVE | Trazer integralmente; sem mudança de status | Futuro gate conforme roadmap Product |
| `business-rules/*` | Owners extensos de regras de Formulação, Fundamentação, Identidade e Medidas | DEV deve consumi-los, não reescrevê-los localmente | STILL_VALID_AS_AUTHORITY | Trazer integralmente como mirror; mudanças voltam ao Corporate | Reconciliar somente quando implementação divergir |
| Contrato de sugestões governadas da Fase 2 | Não existe ainda como owner equivalente no Product Space espelhado | `CONTRATO_SUGESTOES_GOVERNADAS_FASE2.md` + contrato executável e testes existem no DEV | NEW_DEV_CONTRACT_REQUIRES_PROMOTION | Submeter ao Corporate como evolução candidata; não promover silenciosamente | Product decision / documentação Corporate |
| FE-08 monitoramento governado | Baseline Corporate registrava frontend/runtime parcial | DEV passou a operacionalizar pacote, ciclo, readiness, RAE e fechamento | IMPLEMENTATION_ADVANCED | Rebaselinar Corporate contra HEAD atual e preservar separação entre implementação e aceite | Acceptance funcional + runtime real |

## Principais divergências que não devem ser escondidas

### D1 — Baseline Corporate ficou para trás do HEAD DEV

`current-state.md` é baseado em `d27373c`; o HEAD DEV reconciliado desta wave é `eedf3ce`.

Consequência: classificações PARTIAL/CONFLICT do snapshot não podem ser reaplicadas mecanicamente ao produto atual, nem removidas sem investigação.

### D2 — Roadmap preserva intenção, mas seus status precisam de rebase

A ordem Medidas → Monitoramento → gaps de Formulação continua útil como decisão Product histórica e semântica. Porém Medidas e Monitoramento já receberam execução substancial posterior.

Consequência: o roadmap mestre deve ser atualizado no Corporate depois da reconciliação, não substituído por uma cópia DEV.

### D3 — Monitoramento implementado não equivale a aceite em produção

A wave DEV executou testes de contrato, typecheck e build, mas não criou pacote/ciclo real nem realizou aceite autenticado completo com dados reais.

Consequência: `IMPLEMENTATION_ADVANCED` é fato; `DONE` ainda exige decisão/aceite.### D4 — Formulação teve avanço real, mas não está integralmente reconciliada

O G3A resolveu a ausência de operação frontend do lifecycle principal encontrada na baseline. Isso não prova, por si, criação de versão, revisão derivada, clonagem estruturada, arquivamento e todos os demais itens do owner `SKPE-FORM-VER-01`.

Consequência: a terceira prioridade do roadmap deve começar por uma revisão dirigida do owner canônico, não por uma reconstrução livre da Formulação.

### D5 — Novo contrato da Fase 2 ainda não é Corporate

O DEV formalizou `SOURCE → EVIDENCE → ANALYSIS → SUGGESTION → HUMAN DECISION → VALIDATED ELEMENT` e as ações KEEP/ADJUST/REPLACE/ADD/REMOVE.

Consequência: esse contrato deve ser proposto ao Corporate e reconciliado com Fundamentação, Identidade, Formulação e demais stages antes de se tornar regra canônica de produto.

## Plano recomendado de promoção

1. Preservar este mirror como referência imutável do Source SHA informado.
2. Rebaselinar `current-state.md` contra o HEAD DEV atual, mantendo AS-INTENDED, AS-DOCUMENTED, AS-IMPLEMENTED e AS-OBSERVED separados.
3. Reavaliar `SKPE-MED-DES-01` e os conflitos C01/C02/C04 contra a sprint encerrada de Medidas.
4. Reavaliar `SKPE-MON-ANL-01` contra os gates G1–G4D e registrar o que é implementação, o que é aceite e o que ainda depende de runtime real.
5. Reavaliar `SKPE-FORM-VER-01` função por função, usando G3A como evidência, sem presumir fechamento dos demais gaps.
6. Submeter o contrato transversal de sugestões governadas da Fase 2 como decisão Product/Corporate.
7. Atualizar `roadmap.md` no Corporate somente depois dessas reconciliações.
8. Atualizar este mirror a partir do novo SHA Corporate; nunca editar `source/` como atalho.

## Estado desta reconciliação

`MIRROR_INTEGRITY=PASS`
`CORPORATE_STATUS_PROMOTED=NO`
`PRODUCT_DECISIONS_CHANGED=NO`
`SUPABASE_CHANGED=NO`
`NEXT_ACTION=CORPORATE_REBASE_AND_ACCEPTANCE_REVIEW`
