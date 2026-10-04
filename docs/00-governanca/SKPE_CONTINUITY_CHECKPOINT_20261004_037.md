# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 037

Status: ATIVO
Gate: PEM-02.GATE — readiness e ratificação institucional expostos

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_036.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## Objetivo da passagem

Fechar tecnicamente a transição:

`PEM-02.05 → PEM-02.GATE`

sem ratificar a COOTAQUARA e sem promover a Formulação atual.

## Rollup da Macrofase

Foi confirmado que o rollup hierárquico da Jornada exclui itens:

`item_type = gate`

Portanto, não existe circularidade entre:

- conclusão da Macrofase PEM-02;
- prontidão do PEM-02.GATE.

Quando os filhos obrigatórios não-gate PEM-02.01 a PEM-02.05 estiverem completed/100%:

- PEM-02 pode chegar a completed/100%;
- o GATE continua separado;
- o GATE então pode avaliar readiness.

## Guard de conclusão PEM-02.05

Migration aplicada:

`20261004055000_guard_pem0205_completion.sql`

Trigger:

`skpe_pem0205_completion_readiness_guard`

Ao tentar concluir PEM-02.05, o banco exige:

1. Formulação Estratégica ativa;
2. strategic_map_package existente;
3. package.status = validated;
4. get_skpe_strategic_map_readiness(...).readyForFormulation = true;
5. versão oficial do Mapa existente;
6. versão oficial vinculada ao package validado;
7. source_validated_at da versão correspondente a validated_at do package atual.

Se alguma condição falhar, a conclusão é recusada.

## Evidência de conclusão

Quando PEM-02.05 puder ser concluída, a Jornada passa a registrar em metadata:

`completionEvidence`

com:

- strategicMapPackageId;
- strategicMapVersionId;
- strategicMapVersionNumber;
- mapValidatedAt;
- readinessVerifiedAt.

Isso conecta a conclusão metodológica da etapa à versão imutável efetivamente validada.

## Readiness canônico do PEM-02.GATE

Autoridade existente:

`get_skpe_pem02_gate_readiness(project_id)`

Pré-requisitos:

1. PEM-02 completed;
2. PEM-02 progress = 100;
3. Horizonte Estratégico corrente;
4. Formulação Estratégica approved;
5. Plano de Evolução corrente com governance_status approved ou historical_recognized.

O Gate não cria alinhamentos Objetivo–Ciclo.

## Ratificação canônica

Autoridade existente:

`ratify_skpe_pem02_gate(...)`

Resultados permitidos:

- approved;
- approved_with_reservations;
- returned_for_adjustment.

A função:

- exige permissão de ratificação;
- exige justificativa;
- exige ressalvas quando aplicável;
- exige requisitos de ajuste quando aplicável;
- captura readiness_snapshot;
- registra decisão em skpe_gate_decisions;
- preserva supersedes_decision_id e decision_sequence;
- registra decided_at e decided_by;
- usa decision_kind = pem02_gate_closure;
- atualiza Journey Item do Gate;
- recalcula a Jornada.

Aprovação só é permitida quando:

`readyForClosure = true`

## Novo painel do Gate

Componente criado:

`Pem02GatePanel.tsx`

Integrado à tela da Jornada.

O painel consulta:

- get_skpe_pem02_gate_readiness;
- can_ratify_skpe_governance.

## Prontidão exibida

O painel apresenta cinco condições:

1. Macrofase PEM-02 concluída;
2. Horizonte Estratégico corrente;
3. Formulação Estratégica aprovada;
4. Plano de Evolução corrente;
5. readiness sem bloqueadores.

Cada condição aparece como:

- Atendido;
- Pendente.

Também são exibidas as issues canônicas do backend.

## Decisão institucional

Para usuários com permissão, a UI oferece:

- Aprovar Macrofase 2;
- Aprovar com ressalvas;
- Devolver para ajustes.

Aprovação e aprovação com ressalvas ficam desabilitadas enquanto:

`readyForClosure = false`

Justificativa mínima na UI:

- 10 caracteres.

Aprovação com ressalvas exige:

- texto de ressalvas.

Retorno exige:

- ajustes requeridos.

A decisão é enviada exclusivamente para:

`ratify_skpe_pem02_gate(...)`

Não existe conclusão genérica paralela.

## Estado COOTAQUARA

Nenhuma ratificação foi executada.

Permanece:

- PEM-02.03 = in_progress;
- PEM-02.04 = not_started;
- PEM-02.05 = not_started;
- PEM-02.GATE = not_started;
- Formulação = draft;
- Mapa = in_elaboration;
- versões oficiais do Mapa = 0;
- Plano de Evolução corrente elegível = inexistente.

Logo:

`readyForClosure = false`

continua sendo o estado esperado.

## Testes

Executados:

- pem0205CompletionGuard.test.ts;
- pem02GatePanel.test.ts;
- strategicMapLifecyclePanel.test.ts;
- strategicMapLifecycleWindow.test.ts.

Resultado:

**11/11 PASS**

## Build

`vite build`

Resultado:

**PASS**

- 2203 módulos transformados;
- warning não bloqueante de chunk > 500 kB.

## Estado metodológico final da Macrofase 2

A solução agora possui contratos governados para:

### PEM-02.03
- Posicionamento;
- Temas;
- Perspectivas;
- validação humana;
- reconciliação v26.

### PEM-02.04
- Objetivos Estratégicos;
- dependência formal de PEM-02.03.

### PEM-02.05
- Mapa Estratégico;
- relações de causa e efeito;
- validação humana por relação;
- readiness;
- submissão;
- validação do pacote;
- versão oficial imutável;
- revisão formal;
- completion guard.

### PEM-02.GATE
- readiness agregado;
- decisão institucional;
- aprovação;
- aprovação com ressalvas;
- retorno para ajustes;
- trilha decisória;
- fechamento governado.

## Próximo gate

**PREPARAR A TRANSIÇÃO DA MACROFASE 2 PARA A FASE DE DESDOBRAMENTO TÁTICO**

Sem avançar a COOTAQUARA, revisar agora:

1. qual Journey Item é liberado após PEM-02.GATE;
2. dependências entre Formulação aprovada e OKRs;
3. Indicadores/KPIs;
4. Metas;
5. Iniciativas Estratégicas;
6. Plano de Iniciativas;
7. conexão com Monitoramento;
8. garantir que a Fase 5 da metodologia só consuma Objetivos/Mapa oficialmente aprovados.

Estado:

`PEM-02.GATE = PREPARED`

`RATIFICATION_EXECUTED = NO`
