# SK-PE — Checkpoint de Continuidade — 2026-10-04 — 043

Status: ATIVO
Gate: PEM-04 — Implementação e Mobilização reconciliada

## Continuidade

Anterior:

`SKPE_CONTINUITY_CHECKPOINT_20261004_042.md`

Branch:

`recovery/2026-09-13-recent-ux-preservation`

## Próxima Macrofase canônica

Após PEM-03.GATE, a Jornada canônica segue para:

`PEM-04 — Implementação e Mobilização`

Etapas:

- PEM-04.01;
- PEM-04.02;
- PEM-04.03;
- PEM-04.04;
- PEM-04.GATE.

## Problema metodológico identificado

A etapa anterior:

`PEM-04.01 — Plano de Implementação`

podia ser interpretada como reconstrução do Plano de Iniciativas já governado em:

`PEM-03.03 — Iniciativas e Projetos Estratégicos`

Isso criaria duplicidade entre:

- formulação/desdobramento do portfólio;
- ativação da execução.

## Reconciliação

PEM-04 passa a representar exclusivamente:

**implantação, mobilização e gestão da execução da estratégia já aprovada.**

### PEM-04.01

Novo nome:

`Ativação do Plano de Implementação`

Critério:

- iniciativas selecionadas do portfólio aprovado possuem condições de ativação para execução;
- não há redefinição do portfólio nesta etapa.

### PEM-04.02

`Comunicação e Mobilização`

Critério:

- plano de comunicação e mobilização da implementação aprovado.

### PEM-04.03

`Capacidades e Gestão da Mudança`

Critério:

- lacunas de capacidade e necessidades de gestão da mudança avaliadas e tratadas.

### PEM-04.04

`Gestão de Riscos da Implementação`

Critério:

- riscos de implementação avaliados;
- responsáveis definidos;
- respostas críticas estabelecidas.

### PEM-04.GATE

`Validação da Macrofase 4`

Critério:

- aceite executivo da Implementação e Mobilização registrado.

## Dependências sequenciais

Foi formalizada a cadeia:

`PEM-03.GATE → PEM-04.01 → PEM-04.02 → PEM-04.03 → PEM-04.04 → PEM-04.GATE`

Dependências:

- PEM-04 exige PEM-03.GATE completed;
- PEM-04.01 exige PEM-03.GATE completed;
- PEM-04.02 exige PEM-04.01 completed;
- PEM-04.03 exige PEM-04.02 completed;
- PEM-04.04 exige PEM-04.03 completed;
- PEM-04.GATE exige PEM-04.04 completed.

As dependências foram registradas em:

- skpe_methodology_template_items;
- skpe_journey_items ativos.

A UI da Jornada já interpreta genericamente:

`metadata.unblock_dependencies`

e o banco já possui o guard:

`skpe_assert_journey_item_dependencies()`

Portanto, não foi necessário hardcode de PEM-04 no frontend.

## Autoridades de execução já existentes

A auditoria identificou contratos canônicos para:

### Ações de iniciativas

- upsert_skpe_initiative_action;
- update_skpe_initiative_action_progress;
- create_sparks_initiative_action;
- update_sparks_initiative_action_execution;
- get_sparks_initiative_action_board;
- responsabilidades de ações.

### Riscos de iniciativas

- upsert_skpe_initiative_risk;
- update_skpe_initiative_risk_assessment;
- transition_skpe_initiative_risk.

Essas authorities devem ser reutilizadas em PEM-04.

Não criar estrutura paralela para ações ou riscos.

## Migration

Aplicada no DEV:

`20261004075500_reconcile_pem04_implementation_sequence.sql`

A migration altera apenas:

- nomes;
- critérios metodológicos;
- dependências.

Ela NÃO altera:

- status;
- progress;
- validation_status;
- decisão executiva;
- conteúdo do portfólio.

## Estado COOTAQUARA após aplicação

### PEM-04

- status = not_started;
- progress = 0;
- depende de PEM-03.GATE completed.

### PEM-04.01

- status = not_started;
- depende de PEM-03.GATE completed.

### PEM-04.02

- status = not_started;
- depende de PEM-04.01 completed.

### PEM-04.03

- status = not_started;
- depende de PEM-04.02 completed.

### PEM-04.04

- status = not_started;
- depende de PEM-04.03 completed.

### PEM-04.GATE

- status = not_started;
- validation_status = pending;
- depende de PEM-04.04 completed.

Conclusão:

**nenhuma etapa da Macrofase 4 foi aberta ou promovida.**

## Testes

Executados:

- pem04ImplementationSequence.test.ts;
- pem03GateGovernance.test.ts;
- journeySequentialLockUi.test.ts.

Resultado:

**9/9 PASS**

## Build

`vite build`

Resultado:

**PASS**

- 2209 módulos transformados;
- warning não bloqueante de chunk > 500 kB.

## Próximo gate

**PEM-04.01 — ATIVAÇÃO DO PLANO DE IMPLEMENTAÇÃO**

Preparar a solução, sem iniciar a etapa, para:

1. consumir somente o portfólio estratégico validado em PEM-03.03;
2. não recriar ou repriorizar o portfólio;
3. verificar que iniciativas selecionadas possuem plano de ação executável;
4. verificar responsáveis e responsabilidades;
5. verificar marcos/horizonte de execução;
6. preparar ativação operacional;
7. distinguir plano aprovado de execução iniciada;
8. exigir readiness de ativação;
9. impedir início de execução fora da janela metodológica;
10. impedir conclusão enquanto houver iniciativa selecionada sem condições de ativação.

Até PEM-03.GATE:

`PEM-04 = BLOCKED`

`PEM-04.01 = BLOCKED`
