# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 053

Status: ATIVO
Gate: PEM-05.04 — Atualização Estratégica Governada

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_052.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## PEM-05.04 — Atualização Estratégica Governada

A etapa foi preparada sem ser iniciada.

Authority formal de revisão já existente:

`create_skpe_formulation_revision(...)`

Essa função:

- deriva nova versão de Formulação aprovada/superseded;
- cria nova versão draft;
- preserva derived_from_formulation_id;
- clona conteúdo;
- preserva lineage;
- audita;
- não altera silenciosamente a versão aprovada.

## Lacuna de governança identificada

Não existia um registro canônico e explícito para a decisão:

**“o aprendizado deste ciclo exige atualização da estratégia?”**

Foi criado somente esse ledger decisório.

## Ledger append-only

Tabela:

`skpe_strategy_update_decisions`

Resultados:

- no_update_required;
- revision_required;
- revision_opened.

Campos principais:

- source_formulation_id;
- monitoring_cycle_id;
- strategy_review_id;
- decision_sequence;
- decision_outcome;
- decision_reason;
- target_revision_formulation_id;
- supersedes_decision_id;
- decided_at/by;
- metadata.

A sequência é append-only e decisões posteriores supersedem logicamente as anteriores sem apagá-las.

## Registro de decisão

Função:

`record_skpe_strategy_update_decision(...)`

Exige:

- Formulação válida;
- permissão can_ratify_skpe_governance;
- justificativa >= 10 caracteres;
- PEM-05.03 readyForCompletion.

### no_update_required

Não permite revisão-alvo.

### revision_required

Registra que revisão é necessária, mas não cria revisão.

### revision_opened

Exige target_revision_formulation_id e valida que:

- pertence ao mesmo projeto/organização;
- derived_from_formulation_id = Formulação de origem.

## Readiness

Função:

`get_skpe_pem0504_strategy_update_readiness(formulation_id)`

Pré-requisito:

`get_skpe_pem0503_learning_readiness(...).readyForCompletion = true`

Bloqueadores:

### Decisão ausente

`PEM0504_UPDATE_DECISION_MISSING`

### Revisão necessária, mas não aberta

`PEM0504_REVISION_REQUIRED_NOT_OPENED`

### Revisão-alvo inválida

`PEM0504_TARGET_REVISION_INVALID`

### Decisão “sem atualização” conflitando com aprendizado que aponta revisão

`PEM0504_NO_UPDATE_CONFLICTS_WITH_LEARNING`

### Aprendizados apontando revisão diferente da decisão institucional

`PEM0504_LEARNING_REVISION_LINEAGE_CONFLICT`

## Política explícita

- revisionAuthority = create_skpe_formulation_revision;
- mutatesApprovedFormulation = false;
- createsRevisionAutomatically = false;
- requiresInstitutionalDecision = true;
- preservesLineage = true.

## Guard de conclusão

Função:

`skpe_guard_pem0504_completion()`

Trigger:

`skpe_pem0504_completion_guard`

PEM-05.04 só pode assumir completed quando:

`readyForCompletion = true`

Ao concluir legitimamente, grava:

- strategyUpdateDecisionId;
- decisionOutcome;
- targetRevisionFormulationId;
- readinessVerifiedAt;
- readinessSnapshot;
- approvedFormulationMutated = false;
- revisionCreatedAutomatically = false.

## UI

Novo painel:

`MonitoringStrategyUpdateReadinessPanel`

Integrado ao MonitoringSection.

### Ação 1 — decisão institucional

Permite explicitamente:

- Nenhuma atualização necessária;
- Revisão estratégica necessária.

Exige justificativa humana.

### Ação 2 — abrir revisão formal

Só aparece quando a decisão atual é:

`revision_required`

O usuário informa:

- rótulo da nova versão;
- resumo da mudança.

A UI então executa, por ação humana explícita:

1. create_skpe_formulation_revision;
2. record_skpe_strategy_update_decision com revision_opened.

Assim:

**nenhuma revisão é aberta por efeito colateral do readiness ou da conclusão da etapa.**

## Migration

Aplicada no DEV:

`20261004220000_govern_pem0504_strategy_update.sql`

## Testes

Executados:

- pem0504StrategyUpdate.test.ts;
- pem0503LearningImprovement.test.ts;
- pem0502CriticalReview.test.ts;
- pem0501MonitoringOperation.test.ts.

Resultado:

**19/19 PASS**

## Build

`vite build`

Resultado:

**PASS**

- 2227 módulos transformados;
- warning não bloqueante de chunk > 500 kB.

## Verificação de não fabricação — COOTAQUARA

Decisões de atualização estratégica:

`0`

Formulações existentes:

- v1;
- status = draft;
- derived_from_formulation_id = null.

Nenhuma v2 foi criada.

Estado:

- PEM-05.03 = not_started;
- PEM-05.04 = not_started;
- PEM-05.GATE = not_started / pending.

Conclusão:

**nenhuma decisão de atualização, revisão estratégica ou avanço da Jornada foi fabricado.**

## Próximo gate

**PEM-05.GATE — CICLO DE REVISÃO ESTRATÉGICA**

Preparar fechamento governado da Macrofase 5:

1. PEM-05.01 completed;
2. PEM-05.02 completed;
3. PEM-05.03 completed;
4. PEM-05.04 completed;
5. readiness agregado;
6. decisão institucional append-only;
7. aprovado / aprovado com ressalvas / devolvido para ajustes;
8. snapshot completo do ciclo;
9. auditoria;
10. nenhuma ratificação automática.
