# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 047

Status: ATIVO
Gate: PEM-04.04 — Gestão de Riscos da Implementação governada

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_046.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## Princípio arquitetural

PEM-04.04 não cria uma terceira fonte de verdade de riscos.

Authorities reutilizadas:

### Riscos das Iniciativas

`skpe_initiative_risks`

### Riscos Estratégicos

`skpe_strategic_risk_items`

### Mitigações Estratégicas

`skpe_strategic_risk_mitigation_links`

Read model:

`skpe_strategic_risk_mitigation_readiness`

## Readiness canônico

Nova função:

`get_skpe_pem0404_implementation_risk_readiness(formulation_id)`

Pré-requisito:

`get_skpe_pem0403_change_readiness(...).readyForCompletion = true`

## Riscos das Iniciativas

Para Iniciativas selecionadas do portfólio, riscos altos/críticos:

`inherent_score >= 15`

exigem:

- owner;
- response_type;
- response_plan com conteúdo;
- response_due_date;
- validation_status = validated.

Bloqueador:

`PEM0404_HIGH_INITIATIVE_RISK_UNMANAGED`

## Risco aceito

Quando:

`response_type = accept`

é exigida justificativa explícita:

`metadata.acceptanceReason`

Bloqueador:

`PEM0404_ACCEPTED_RISK_WITHOUT_REASON`

Assim:

**risco aceito não é tratado como risco sem tratamento.**

## Riscos Estratégicos

O readiness consome:

`skpe_strategic_risk_mitigation_readiness`

Para risco estratégico validado que exige mitigação:

`mitigation_required = true`

é obrigatório:

`readiness_status = ready`

Isso representa, no contrato já existente:

- mitigação primária;
- Iniciativa vinculada;
- Ação vinculada;
- 5W2H completo.

Bloqueador:

`PEM0404_STRATEGIC_RISK_MITIGATION_NOT_READY`

A etapa não exige efetividade final da mitigação antes da implementação, pois essa comprovação pertence ao ciclo de execução/monitoramento.

## Política de authority

O readiness declara:

- initiativeRiskAuthority = skpe_initiative_risks;
- strategicRiskAuthority = skpe_strategic_risk_items;
- strategicMitigationAuthority = skpe_strategic_risk_mitigation_links/readiness;
- duplicatesRisk = false;
- automaticRiskAcceptance = false;
- automaticMitigationCreation = false.

## Guard de conclusão

Função:

`skpe_guard_pem0404_completion()`

Trigger:

`skpe_pem0404_completion_guard`

PEM-04.04 só pode assumir:

`status = completed`

quando:

`readyForCompletion = true`

Ao concluir legitimamente, grava:

- readinessVerifiedAt;
- readinessSnapshot;
- riskCreatedAutomatically = false;
- riskAcceptedAutomatically = false.

## UI

Novo componente:

`StrategicImplementationRiskReadinessSection`

Apresenta:

- quantidade de riscos das iniciativas;
- riscos altos/críticos;
- riscos estratégicos validados;
- riscos estratégicos exigindo mitigação;
- bloqueadores.

Mensagem explícita:

`Nenhum risco é criado, aceito ou mitigado automaticamente.`

Quando:

`current_stage_code = PEM-04.04`

a Formulação abre automaticamente:

`plan`

## Migration

Aplicada no DEV:

`20261004183000_govern_pem0404_implementation_risks.sql`

Funções confirmadas no banco:

- get_skpe_pem0404_implementation_risk_readiness;
- skpe_guard_pem0404_completion.

## Testes

Executados:

- pem0404ImplementationRiskReadiness.test.ts;
- pem0403CapabilitiesChange.test.ts;
- pem0402CommunicationMobilization.test.ts.

Resultado:

**12/12 PASS**

## Build

`vite build`

Resultado:

**PASS**

- warning não bloqueante de chunk > 500 kB.

## Estado COOTAQUARA após aplicação

- PEM-04.03 = not_started;
- PEM-04.04 = not_started;
- PEM-04.GATE = not_started / pending.

A migration contém apenas:

- função de readiness;
- função de guard;
- trigger;
- grants/comments.

Não contém:

- INSERT de risco;
- UPDATE de risco;
- criação de mitigação;
- aceite de risco;
- promoção de Journey Item.

Conclusão:

**nenhum risco, mitigação ou decisão foi fabricado.**

## Próximo gate

**PEM-04.GATE — VALIDAÇÃO DA MACROFASE 4**

Preparar fechamento governado da Implementação e Mobilização usando o mesmo padrão de PEM-02.GATE e PEM-03.GATE:

1. readiness agregado de PEM-04.01 a PEM-04.04;
2. Macrofase 4 completed;
3. decisão institucional append-only;
4. aprovado / aprovado com ressalvas / devolvido para ajustes;
5. readiness snapshot;
6. auditoria;
7. guard fail-closed;
8. nenhuma ratificação automática.
