# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 040

Status: ATIVO
Gate: PEM-03.03 — readiness canônico de Iniciativas consolidado

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_039.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## PEM-03.03 — Iniciativas e Projetos Estratégicos

A etapa foi preparada sem ser iniciada.

Fonte única de prontidão:

`get_skpe_initiatives_readiness(formulation_id, include_package_state)`

A solução reutiliza o contrato canônico existente, sem criar regra paralela no frontend.

## Readiness canônico reutilizado

O contrato já verifica, entre outros:

- existência de pacote FE-07;
- existência de iniciativas selecionadas;
- limite máximo configurado do portfólio;
- identificação suficiente da iniciativa;
- programa sem componentes;
- ação estruturante sem iniciativa/projeto pai;
- problema e racional estratégicos;
- responsável;
- área responsável;
- horizonte temporal;
- vínculo com OE e/ou KR;
- scoring de priorização;
- avaliação de risco;
- avaliação de capacidade;
- resultado/benefício esperado;
- critério de sucesso;
- plano de ação;
- 5W2H quando obrigatório;
- dependência crítica sem gestão;
- risco crítico sem resposta;
- validação do pacote.

Também produz recomendações para:

- sponsor;
- backup owner;
- vínculo com indicador;
- vínculo com KR;
- marcos.

## UI

`StrategicInitiativePlanSection` passou a receber `formulationId` e consultar:

`get_skpe_initiatives_readiness(..., true)`

A tela agora exibe:

**PEM-03.03 · Prontidão do portfólio**

Estados:

- Portfólio ainda possui bloqueadores metodológicos;
- Portfólio pronto para validação humana;
- Portfólio pronto e validado para conclusão da etapa.

KPIs:

- Selecionadas;
- Candidatas;
- Ações;
- Riscos;
- Resultados.

Também exibe separadamente:

- Bloqueadores;
- Recomendações.

Regra explícita de UI:

`Este painel usa o contrato canônico de prontidão. Ele não cria, seleciona nem prioriza iniciativas automaticamente.`

## Guard de conclusão

Migration aplicada no DEV:

`20261004070000_guard_pem0303_completion.sql`

Função:

`skpe_guard_pem0303_completion()`

Trigger:

`skpe_pem0303_completion_guard`

PEM-03.03 só pode assumir `completed` quando:

`get_skpe_initiatives_readiness(..., true).readyForFormulation = true`

Ou seja:

- conteúdo pronto;
- portfólio validado;
- sem bloqueadores canônicos.

O guard não cria, prioriza, seleciona, valida ou altera iniciativas.

Quando a conclusão for legítima, grava em:

`metadata.completionEvidence`

- packageStatus;
- applicability;
- readinessVerifiedAt;
- readinessSnapshot.

## Testes

Executados:

- pem0303InitiativesReadiness.test.ts;
- pem0302IndicatorsReadiness.test.ts;
- okrDeploymentReadiness.test.ts.

Resultado:

**11/11 PASS**

## Build

`vite build`

Resultado:

**PASS**

- 2205 módulos transformados;
- warning não bloqueante de chunk > 500 kB.

## Estado de negócio preservado

Nenhum:

- OKR;
- KR;
- indicador;
- meta;
- iniciativa;
- priorização;
- decisão humana;
- avanço de Jornada

foi criado por esta passagem.

## Próximo gate

**PEM-03.04 — RESPONSABILIDADES E GOVERNANÇA DA EXECUÇÃO**

Preparar a solução para exigir, antes de concluir a etapa:

1. responsáveis pelos elementos estratégicos;
2. sponsors/papéis de governança;
3. fóruns de acompanhamento;
4. cadência de revisão;
5. critérios de escalonamento e decisão;
6. integração com execução/monitoramento;
7. nenhuma responsabilidade crítica sem owner;
8. validação humana da governança de execução.

Até a ratificação de PEM-02.GATE, toda a Macrofase 3 continua bloqueada.
