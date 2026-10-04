# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 047

Status: ATIVO
Gate: PEM-04.04 — Gestão de Riscos da Implementação governada

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_046.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## Princípio arquitetural

PEM-04.04 não cria nova fonte de riscos.

Authorities reutilizadas:

- `skpe_strategic_risk_items`;
- `skpe_strategic_risk_mitigation_links`;
- `skpe_strategic_risk_mitigation_readiness`;
- `skpe_initiative_risks`;
- `skpe_initiative_actions`.

Portanto:

**nenhum risco é duplicado para a fase de implementação.**

## Readiness canônico

Nova função:

`get_skpe_pem0404_implementation_risk_readiness(formulation_id)`

Pré-requisito:

`get_skpe_pem0403_change_readiness(...).readyForCompletion = true`

## Riscos estratégicos

A função consulta:

`skpe_strategic_risk_mitigation_readiness`

Para riscos que exigem mitigação, é obrigatório:

- vínculo de mitigação;
- mitigação primária;
- Iniciativa/Ação;
- 5W2H completo.

Quando:

`mitigation_required = true`

e:

`readiness_status <> ready`

a etapa permanece bloqueada.

## Riscos das Iniciativas

A função considera apenas riscos vinculados a Iniciativas:

`selection_status = selected`

Riscos com:

`inherent_score >= 15`

são tratados como alto/crítico para o readiness de implementação.

Exigem:

- owner;
- response_type;
- response_plan suficiente;
- response_due_date;
- validation_status = validated.

## Risco aceito

Quando:

`response_type = accept`

o sistema não considera silêncio como aceitação.

É exigido conteúdo suficiente em:

`response_plan`

como justificativa/condição de aceitação.

## Métricas

O readiness expõe:

- strategicRisks;
- strategicRisksRequiringMitigation;
- strategicMitigationsNotReady;
- initiativeRisks;
- highOrCriticalInitiativeRisks;
- highOrCriticalInitiativeRisksNotReady.

## Política de authorities

O retorno explicita:

- strategicRiskAuthority = skpe_strategic_risk_items;
- strategicMitigationAuthority = skpe_strategic_risk_mitigation_links;
- initiativeRiskAuthority = skpe_initiative_risks;
- mitigationActionAuthority = skpe_initiative_actions;
- duplicatesRisk = false;
- humanValidationRequired = true.

## Guard de conclusão

Função:

`skpe_guard_pem0404_completion()`

Trigger:

`skpe_pem0404_completion_guard`

PEM-04.04 só pode assumir `completed` quando:

`readyForCompletion = true`

Ao concluir legitimamente, grava:

- readinessVerifiedAt;
- readinessSnapshot;
- riskDuplicated = false.

O guard não altera:

- riscos estratégicos;
- riscos de iniciativas;
- aceites;
- mitigações;
- ações.

## UI

Novo componente:

`StrategicImplementationRiskReadinessSection`

Exibe:

- riscos estratégicos;
- mitigações pendentes;
- riscos de iniciativas;
- riscos altos/críticos;
- altos/críticos pendentes;
- bloqueadores;
- política de não duplicação.

Quando:

`current_stage_code = PEM-04.04`

a Formulação abre a aba:

`plan`.

## Migration

Aplicada no DEV:

`20261004182500_govern_pem0404_implementation_risks.sql`

## Testes

Executados:

- pem0404ImplementationRisks.test.ts;
- pem0403CapabilitiesChange.test.ts;
- pem0402CommunicationMobilization.test.ts;
- pem0401ActivationReadiness.test.ts.

Resultado:

**16/16 PASS**

## Build

`vite build`

Resultado:

**PASS**

- 2217 módulos transformados;
- warning não bloqueante de chunk > 500 kB.

## Verificação de não promoção — COOTAQUARA

Após aplicação:

- PEM-04.03 = not_started;
- PEM-04.04 = not_started;
- PEM-04.GATE = not_started / validation_status pending.

A migration não contém INSERT/UPDATE de riscos ou mitigações.

Portanto:

**nenhum risco, aceite, resposta ou mitigação foi fabricado.**

## Próximo gate

**PEM-04.GATE — VALIDAÇÃO DA MACROFASE 4**

Preparar o fechamento governado da Macrofase 4 com:

1. PEM-04.01 completed;
2. PEM-04.02 completed;
3. PEM-04.03 completed;
4. PEM-04.04 completed;
5. readiness agregado;
6. decisão institucional append-only;
7. aprovação / aprovação com ressalvas / retorno para ajustes;
8. auditoria;
9. imutabilidade após conclusão;
10. nenhuma promoção automática.
