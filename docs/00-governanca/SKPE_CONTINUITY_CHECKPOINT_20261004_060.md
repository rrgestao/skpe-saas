# SK-PE — Continuity Checkpoint 060

Date: 2026-10-04
Project: COOTAQUARA
Mode: EXECUTOR / AUTHORIZED
Gate: PEM-02.GATE — integrated Formulação + Evolution Plan ratification prepared

## Authority

- Repository: `C:\DADOS\SPARKs\skpe-saas`
- Branch: `recovery/2026-09-13-recent-ux-preservation`
- Supabase DEV: `vumbfpbcozjebomcthdw`
- Project: `c4a93567-8ab3-4cb9-91ce-8421c3f305f1`
- Formulation: `a95075dc-53bf-44a0-ab36-e2a83aa930d3`
- Strategic Horizon: `4461281a-a80d-4a2a-b85f-1ece8d028ecf`
- Previous authority: `SKPE_CONTINUITY_CHECKPOINT_20261004_059.md`

## Methodological decision consolidated

The user confirmed the intended distinction:

### Evolution Scenario

Belongs methodologically to the Strategic Diagnosis.

Its purpose is to frame, among plausible strategic trajectories, the trajectory that best fits the organization considering diagnosis, maturity, risks, capabilities and ambition.

For COOTAQUARA:

- the scenario was intrinsic to the Diagnosis and subsequent formulation;
- it was not formally presented to management as an autonomous object named "Evolution Scenario";
- therefore no historical institutional approval may be fabricated.

### Evolution Plan

Is the temporal strategic trajectory institutionalized through Cycles.

Reference progression confirmed by the user:

1. Sustainment / Conditions to Evolve;
2. Traction / Value Generation;
3. Value Sustainment / Learning / Continuous Improvement.

This is a reference model, not a permanently fixed number of cycles.

The number, duration and content of cycles must remain adaptable to organizational maturity and strategic complexity.

## SK-PE alignment review

The current SK-PE methodology supports this logic conceptually:

- diagnosis precedes formulation;
- strategy progresses according to maturity and evidence;
- tactical deployment follows strategic formulation;
- governance, learning and continuous improvement close and restart the cycle.

The current skill does not explicitly name Evolution Scenario / Evolution Plan as canonical objects, so this remains an application-level specialization consistent with the broader SK-PE logic.

No final SK-PE Orchestrator x SPARKs PE alignment assessment was started; that remains deferred until v1 is complete.

## Circular Gate contract corrected

Previous contract required before PEM-02.GATE:

- an already approved Formulação;
- an already institutionalized Evolution Plan.

This was circular because the Gate is the institutional moment intended to ratify both.

Migration:

`20261005011000_align_pem02_gate_ratification_lifecycle.sql`

New semantics:

- PEM-02.GATE requires PEM-02 completed;
- current Strategic Horizon must exist;
- current Formulação must be ready for ratification, not preapproved;
- an Evolution Scenario proposal must exist;
- Scenario cycles must be temporalized before ratification;
- on Gate approval:
  - Evolution Scenario is ratified;
  - Evolution Plan is materialized;
  - Formulação is approved;
  - Gate closure is recorded;
- later-stage content does not block PEM-02.GATE.

Deferred to PEM-03 or later:

- KPIs;
- long-term targets;
- OKRs / KRs;
- initiatives;
- operational ownership of deployment.

No Gate ratification was executed in this checkpoint.

## PEM-02-specific Formulation readiness

New canonical readiness:

`get_skpe_pem02_formulation_ratification_readiness`

It validates only the real Macrophase 2 boundary:

- PEM-02 completed;
- Strategic Map validated;
- official immutable Strategic Map version exists.

It does not use the older global formulation readiness blockers that incorrectly required future-stage content.

Current COOTAQUARA result:

- Formulação status = draft;
- readyForRatification = true;
- blockingIssueCount = 0;
- Strategic Map package validated;
- official Strategic Map version exists.

## Conceptual Evolution Cycles

The system previously required dates at the moment a Scenario Cycle was first created.

That forced arbitrary dates before the concept itself could be reviewed.

Migration:

`20261005010000_govern_evolution_scenario_conceptual_cycles.sql`

New lifecycle:

- Scenario Cycle may be conceptual with no dates;
- conceptual cycle can be submitted as part of a proposal;
- readiness distinguishes:
  - structurally_ready;
  - temporalization_complete;
  - ready_to_submit;
  - ready_to_ratify;
- dates are mandatory before institutional ratification;
- materialization as an Evolution Plan still requires temporalized cycles.

## Temporal overlap guard corrected

The original temporal trigger interpreted multiple undated cycles as overlapping.

Migration:

`20261005010500_allow_conceptual_cycle_temporality_guard.sql`

New rule:

- if both dates are null, cycle is conceptual and overlap validation is skipped;
- if one date is informed, both are required;
- once dates exist:
  - cycle must remain inside the Strategic Horizon;
  - dated cycles cannot overlap.

## COOTAQUARA Evolution Scenario created

Scenario:

`9f49ca2d-a878-4caa-be84-5c64168276ae`

Title:

`Cenário de Evolução Progressiva por Maturidade`

Status:

`proposed`

Origin:

`diagnostic`

Important historical semantics:

- methodological adoption recognized;
- no autonomous historical institutional approval claimed;
- source rationale states that the framing was intrinsic to Diagnosis and guided Formulação;
- current proposal is now explicit for future institutional deliberation.

## Conceptual cycles created

### Cycle 1

`8ea7f47c-beac-4523-b93a-dce6cd1e47e6`

Title:

`Sustentação — Condições para Evoluir`

Intent:

Strengthen bases, capabilities and critical conditions to sustain strategic evolution.

Dates:

- start = null;
- end = null;
- temporalization_status = pending.

### Cycle 2

`818ab8e2-926c-4c86-b7ae-90306ea12887`

Title:

`Tração e Geração de Valor`

Intent:

Gain strategic traction and increase value generation according to organizational maturity.

Dates:

- start = null;
- end = null;
- temporalization_status = pending.

### Cycle 3

`c6f0d145-622f-4c9a-a854-94fab151782b`

Title:

`Sustentação do Valor, Aprendizado e Melhoria`

Intent:

Sustain results, institutionalize learning and feed the next continuous-improvement cycle.

Dates:

- start = null;
- end = null;
- temporalization_status = pending.

No targets, owners or dates were invented.

## Current Scenario readiness

- cycle_count = 3;
- structurally_ready = true;
- ready_to_submit = true;
- status = proposed;
- temporalization_complete = false;
- undated_cycle_count = 3;
- ready_to_ratify = false.

## Current PEM-02.GATE readiness

Current single blocker:

`EVOLUTION_SCENARIO_TEMPORALIZATION_PENDING`

Message:

The Evolution Scenario is structured, but Cycle periods must be defined before PEM-02.GATE ratification.

Everything else is ready at the Macrophase 2 boundary.

Current state:

- PEM-02 = completed / 100%;
- Formulação readyForRatification = true;
- Evolution Scenario = proposed;
- Evolution Plan = absent, as expected before Gate ratification;
- PEM-02.GATE = not_started;
- PEM-03 remains blocked pending PEM-02.GATE.

## Journey UI hierarchy preserved

Gate panels were re-embedded inside their Gate items in the Journey hierarchy.

Rules:

- no parallel standalone Gate stack;
- Gate details render only when their parent Macrophase hierarchy is rendered/expanded;
- future PEM-03/04/05 Gate blockers are not presented as current work;
- Gate functionality is preserved.

PEM-02 Gate UI now says:

- Formulação ready for ratification;
- Scenario and Evolution Plan;
- temporalization pending when cycle dates are absent.

It no longer says that Formulação and Plan must already be approved before the Gate.

## Evolution UI

Application contract updated so Scenario cycle dates may be null.

UI displays:

`Temporalização pendente`

instead of fake or invalid dates.

Scenario status labels now include:

- proposed = Proposto;
- under_review = Em revisão;
- deferred = Adiado.

## Tests

Focused tests executed:

- journeyMacrophaseHierarchyUi.test.ts;
- pem02GatePanel.test.ts;
- evolutionScenarioConceptualCycles.test.ts;
- evolutionScenarioConceptualTemporalGuard.test.ts;
- evolutionScenarioConceptualUi.test.ts;
- pem02IntegratedGateLifecycle.test.ts.

Result:

**18/18 PASS**

## Build

Production build:

**PASS**

- 2231 modules transformed;
- existing non-blocking chunk-size warning only.

## Security

Verified:

- anon cannot execute PEM-02 Gate readiness;
- anon cannot execute PEM-02 Gate ratification;
- anon cannot execute Evolution Scenario readiness;
- authenticated users retain governed execution access.

## v1 scope freeze

Still active:

- no new Macrophases;
- no new Gates;
- no invented methodology layers;
- no future-stage content created merely to satisfy a readiness;
- fix only contradictions that prevent legitimate execution of the existing Journey.

## Next canonical action

Do not ratify PEM-02.GATE yet.

The only legitimate missing decision is the **temporalization of the three Evolution Cycles** within the current Horizon:

`2026-08-01 -> 2030-12-31`

The solution must not invent those dates.

After explicit temporalization:

1. update the three Scenario Cycles;
2. readiness should become ready_to_ratify;
3. PEM-02.GATE may be presented for institutional decision;
4. on approval, the Gate will:
   - ratify the Evolution Scenario;
   - materialize the institutional Evolution Plan;
   - approve the Formulação;
   - close Macrophase 2 Gate;
   - release PEM-03.

No OKR, KPI, initiative, OE owner or detailed OE-to-OE causal relation is required to close PEM-02.GATE.
