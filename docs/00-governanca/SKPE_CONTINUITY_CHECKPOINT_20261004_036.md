# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 036

Status: ATIVO
Gate: PEM-02.05 — lifecycle do Mapa Estratégico governado e exposto na UI

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_035.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## Objetivo da passagem

Completar o workflow operacional de PEM-02.05:

`readiness → submissão → validação humana → versão oficial → revisão controlada`

sem promover o estado atual da COOTAQUARA.

## Workflow canônico existente

O backend já possuía:

`transition_skpe_strategic_map(...)`

Ações:

- submit_validation;
- validate;
- return_for_adjustments;
- begin_revision.

Também já possuía:

`capture_skpe_strategic_map_version(...)`

Ao validar o Mapa, o workflow captura automaticamente uma versão oficial imutável.

## Painel de lifecycle

Novo componente:

`StrategicMapLifecyclePanel.tsx`

Foi incorporado à aba de Mapa Estratégico da Formulação.

O painel consulta:

- skpe_strategic_map_packages;
- skpe_strategic_map_versions;
- get_skpe_strategic_map_readiness;
- can_manage_skpe_formulation;
- can_validate_skpe_formulation.

## Informações exibidas

### Status do pacote

- Não criado;
- Em elaboração;
- Aguardando validação;
- Validado.

### Readiness

- Pronto;
- Bloqueado.

### Quantidade de pendências

Usa:

`blockingIssueCount`

do contrato canônico.

### Versão oficial

Quando existente:

- número;
- UUID;
- notas de validação.

## Ações da UI

### Em elaboração

Se:

- stageUnlocked = true;
- usuário pode gerenciar;
- readiness.readyForValidation = true;

habilita:

`Enviar para validação`

### Pendente de validação

Se:

- stageUnlocked = true;
- usuário pode validar;
- readiness.readyForValidation = true;

habilita:

`Validar e gerar versão oficial`

Também permite:

`Devolver para ajustes`

### Validado

Se usuário pode gerenciar:

`Iniciar revisão preservando versão oficial`

## Justificativa humana

Para:

- validate;
- return_for_adjustments;
- begin_revision;

a UI exige justificativa com pelo menos 10 caracteres.

Ao validar e receber:

- officialMapVersionId;
- officialMapVersionNumber;

a UI informa explicitamente:

`Mapa validado. Versão oficial vN capturada (...).`

## Backend — janela de edição

Migration:

`20261004053500_harden_strategic_map_lifecycle_window.sql`

Criada função:

`skpe_strategic_map_edit_window_open(formulation_id)`

A edição inicial do Mapa é permitida apenas quando:

`PEM-02.05 = in_progress`

Após validação, uma alteração posterior somente é permitida quando existe revisão formal aberta por:

`begin_revision`

identificada por:

`revisionOfOfficialVersionId`

no package metadata.

## Guards de conteúdo

Triggers ativos:

1. `skpe_objective_relations_edit_window_guard`;
2. `skpe_relation_validation_edit_window_guard`.

Eles protegem:

- criação;
- edição;
- exclusão de relação causal;
- registro de decisão humana sobre relação causal.

Assim, chamadas diretas/API também não podem alterar o Mapa fora da janela metodológica.

## Workflow do pacote endurecido

`transition_skpe_strategic_map(...)` passou a verificar no banco:

Para:

- submit_validation;
- validate;
- return_for_adjustments;

a janela inicial deve estar aberta em PEM-02.05.

`begin_revision` permanece como mecanismo formal de reabertura futura.

## Validação exige justificativa

O backend agora também exige:

- action = validate;
- decision_notes com pelo menos 10 caracteres.

Mensagem fail-closed:

`A validação do Mapa Estratégico exige justificativa humana com pelo menos 10 caracteres.`

Portanto, a exigência não depende apenas da UI.

## Relações causais

Permanece vigente o gate do checkpoint 035:

- hipóteses causais são registradas separadamente;
- cada relação exige validação humana;
- relação sem validação bloqueia readiness;
- relação rejeitada bloqueia readiness;
- OE desconectado bloqueia readiness.

## Estado atual COOTAQUARA

Pacote do Mapa:

`status = in_elaboration`

- submitted_for_validation_at = null;
- validated_at = null.

Versões oficiais:

`0`

Relações causais:

- 1 relação registrada;
- 1 exige validação humana;
- 0 eventos de validação.

Journey:

- PEM-02.03 = in_progress;
- PEM-02.04 = not_started;
- PEM-02.05 = not_started;
- PEM-02.GATE = not_started.

Portanto:

**nenhum avanço de negócio foi executado.**

## Testes

Suite integrada:

- strategicMapLifecyclePanel.test.ts;
- strategicMapLifecycleWindow.test.ts;
- causalRelationValidationGovernance.test.ts;
- causalRelationValidationUi.test.ts.

Resultado:

**11/11 PASS**

Também foram validados anteriormente neste gate:

- readiness;
- stage lock;
- causal validation;
- sequential journey.

## Build

`vite build`

Resultado:

**PASS**

- 2201 módulos transformados;
- warning não bloqueante de chunks > 500 kB;
- plugin timing CSS não bloqueante.

## Próximo gate

**CONCLUSÃO GOVERNADA DE PEM-02.05 E LIBERAÇÃO DO PEM-02.GATE**

Preparar contrato que permita concluir PEM-02.05 somente quando:

1. package status = validated;
2. versão oficial existe;
3. readiness.readyForFormulation = true;
4. não há relações causais pendentes/rejeitadas;
5. não há OEs desconectados;
6. versão oficial corresponde ao pacote validado atual.

Ao concluir PEM-02.05:

- liberar PEM-02.GATE;
- não concluir o GATE automaticamente;
- apresentar readiness do GATE;
- preservar formulação ainda não aprovada até decisão final.

Estado atual:

`MAP_PACKAGE = IN_ELABORATION`

`MAP_VALIDATION = NO`

`OFFICIAL_VERSION_COUNT = 0`

`PEM-02.05 = NOT_STARTED`
