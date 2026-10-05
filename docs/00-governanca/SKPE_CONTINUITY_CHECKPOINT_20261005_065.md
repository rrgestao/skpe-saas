# SK-PE — Continuity Checkpoint 065

Date: 2026-10-05
Project: COOTAQUARA
Mode: EXECUTOR / AUTHORIZED
Front: Application development — automatic Journey artifacts
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261004_064.md

## User directive consolidated

From now on, whenever a new Macrophase, Phase/Stage, Activity or Deliverable is opened in the SK-PE Journey, the application must make the corresponding working artifacts available immediately.

The artifact package must:

- contain SPARKs suggestions from the start;
- support project-leader review before organizational validation;
- support interaction with Management, Boards/Councils and other governance instances;
- remain editable/versioned while it is a proposal;
- never fabricate evidence, approval or institutional decision;
- never advance Journey status by artifact generation alone;
- allow additional artifacts to be created manually when needed;
- remain downloadable/visualizable even when generated as Markdown without uploaded binary file.

This behavior is application infrastructure and applies generically, not only to COOTAQUARA.

## Governance lifecycle

Canonical lifecycle for every generated artifact:

SPARKs suggestion -> project leader review -> organizational/human validation -> canonical incorporation

Automatic generation means availability of a proposal, never approval.

Blocked/not-started future Journey items cannot materialize their artifact packages early.

Gate items keep their dedicated institutional-decision mechanisms.

## DEV migrations applied

Applied to Supabase DEV:

- 20261005032000_auto_materialize_journey_artifacts_on_open.sql
- 20261005033500_require_all_opened_journey_artifacts.sql

The first migration establishes templates, stage-aware SPARKs suggestions, initial Markdown content and automatic materialization when an eligible Journey item transitions to in_progress.

The second migration makes generation requirement-driven and seeds explicit artifact requirements for PEM-03, PEM-04 and PEM-05. When no explicit requirement exists, a safe working/validation fallback pair is created.

## Explicit future artifact packages

PEM-03.01: OKR/KR matrix + validation package.
PEM-03.02: Indicators/Targets matrix + validation package.
PEM-03.03: Strategic Initiatives/Projects portfolio + validation package.
PEM-03.04: Execution Governance/Responsibilities matrix + validation package.
PEM-04.01: Strategy Activation Plan + validation package.
PEM-04.02: Communication and Mobilization Plan + validation package.
PEM-04.03: Capabilities and Change Management Plan + validation package.
PEM-04.04: Implementation Risk Matrix + validation package.
PEM-05.01: Monitoring Routine Record + validation package.
PEM-05.02: Performance Critical Analysis + validation package.
PEM-05.03: Learning and Improvement Record + Prioritized Improvement Plan.
PEM-05.04: Strategic Update Proposal + validation package.

## User-facing Journey behavior

Journey now exposes artifact access for opened/completed Macrophases, phases, activities and deliverables.

Action label: Abrir artefatos da etapa

When invoked:

1. the application calls the governed ensure function;
2. missing artifact proposals are created idempotently;
3. the Artifact workspace opens already filtered to the Journey item;
4. generated Markdown versions can be visualized and downloaded;
5. manually creating a new methodology artifact remains available to users with management permission.

## Runtime validation on COOTAQUARA

Operationally validated against PEM-02.05 — Modelo Estratégico Futuro.

Result:

- createdCount = 2
- existingCount = 0
- availableCount = 2
- proposalOnly = true
- humanValidationRequired = true

Created proposals:

- AUTO-PEM-02-05-TRABALHO — Caderno de Trabalho e Recomendações — Modelo Estratégico Futuro
- AUTO-PEM-02-05-VALIDACAO — Pacote para Validação — Modelo Estratégico Futuro

Both contain an initial v1 Markdown version and are stored as proposals in preparation.

No Journey status was changed. No approval or evidence was fabricated.

## Tests

Focused result: 25/25 PASS.

## Build

Production build: PASS.

- 2231 modules transformed;
- existing non-blocking Vite chunk-size warning only.

## COOTAQUARA Journey state preserved

- PEM-02 remains completed / 100%;
- PEM-02.GATE remains institutionally pending;
- PEM-03 remains blocked;
- no automatic Journey promotion occurred.

The next real institutional action remains validation of the three Evolution Cycles by COOTAQUARA.

## Next application-development direction

Continue implementing the established Journey through PEM-03, PEM-04 and PEM-05 with the rule that each newly opened operational unit has an appropriate artifact package, SPARKs proposal content, review/validation lifecycle, traceability, download/visualization, ability to create additional artifacts and no silent institutional promotion.