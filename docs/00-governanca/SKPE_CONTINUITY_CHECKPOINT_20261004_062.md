# SK-PE — Continuity Checkpoint 062

Date: 2026-10-04
Project: COOTAQUARA
Mode: EXECUTOR / AUTHORIZED
Gate: PEM-02.GATE technically ready; institutional validation still pending

## Authority

- Repository: `C:\DADOS\SPARKs\skpe-saas`
- Branch: `recovery/2026-09-13-recent-ux-preservation`
- Supabase DEV: `vumbfpbcozjebomcthdw`
- Project: `c4a93567-8ab3-4cb9-91ce-8421c3f305f1`
- Previous authority: `SKPE_CONTINUITY_CHECKPOINT_20261004_061.md`

## Clarification ratified by project leader

The user clarified the temporal operating rule of SPARKs PE:

1. Contract / Service Order is the primary authority for contracted scope and schedule when it contains explicit dates.
2. The roadmap must allow the source document to feed Macrophases, phases, activities and schedule proposals.
3. When contract dates are absent, SPARKs must produce a schedule proposal automatically instead of leaving the Journey without dates.
4. Usual delivery reference: **45 business days**.
5. Extended delivery reference when complexity/scope requires it: **up to 90 business days**.
6. Post-delivery implementation follow-up: **up to 90 business days**.
7. For projects already under execution before SPARKs PE was available, do not fabricate retroactive planned dates:
   - completed work preserves actual dates;
   - remaining work receives a governed proposal from the current real execution point.

These dates remain SPARKs proposals until organizational validation. No automatic schedule approval is allowed.

## Macrophase sequencing

Confirmed:

- PEM-03 cannot start before PEM-02.GATE is institutionally completed.
- PEM-02.GATE is the ratification boundary between Strategic Formulation and Strategic Deployment.
- Generic `Start` / `Complete` lifecycle actions must not be shown for Gate items.
- Gate closure must occur only through the governed institutional decision panel.

PEM-02.GATE description is now:

`Ratificar a Formulação Estratégica e o Plano de Evolução antes de iniciar o Desdobramento Estratégico.`

## User-facing language correction

Main Journey UI no longer exposes internal methodology codes in card headings.

Removed from primary user presentation:

- `PEM-02.GATE` as a visible small label;
- UUID as the visible Strategic Horizon;
- raw states such as `completed`, `draft`;
- `Readiness sem bloqueadores`;
- `Plano vigente: Não aplicável ao item já concluído`;
- generic technical Gate start/complete buttons;
- internal prerequisite codes in blocking copy.

User-facing Gate now presents:

- Macrofase 2 concluída — `Concluída · 100%`;
- Horizonte Estratégico — `2026–2030`;
- Formulação Estratégica — `Pronta para validação institucional`;
- Plano de Evolução — `3 ciclos propostos · prontos para validação`;
- Prontidão para decisão — `Nenhuma pendência`.

The Gate explanatory copy explicitly states that Macrofase 3 remains blocked until the institutional decision is registered.

## Completed-item schedule display

For completed Journey items with no historical approved schedule:

- do not show `Plano vigente: Não aplicável ao item já concluído`;
- display the known `Realizado` period;
- do not fabricate historical planned dates.

For pending/future items:

- an approved schedule displays as `Cronograma aprovado`;
- a draft/pending proposal displays as `Cronograma proposto`;
- if no proposal exists, display `Aguardando proposta de cronograma`.

## Temporal policy migration

Applied DEV migration:

`20261005023000_align_journey_schedule_policy_and_legacy_reconciliation.sql`

It establishes:

- standard/usual delivery = 45 business days;
- extended delivery = 90 business days;
- follow-up = 90 business days;
- Contract / Service Order precedence;
- current phase cadence totaling 45 business days:
  - PEM-00 = 8;
  - PEM-01 = 9;
  - PEM-02 = 10;
  - PEM-03 = 9;
  - PEM-04 = 9.

The historical `ACCELERATED_DURATION=45` parameter remains only for compatibility.

## Legacy reconciliation — COOTAQUARA

Existing draft schedule version:

`6412727f-0055-4fcb-bc10-64dd474904a0`

Before reconciliation it contained zero schedule items.

The canonical function:

`reconcile_skpe_journey_schedule_proposal`

reconciled the project as a legacy/in-flight implementation:

- completed items preserve actual dates;
- PEM-02.GATE proposed milestone = 05/10/2026;
- PEM-03 proposed = 06/10/2026 to 19/10/2026;
- PEM-04 proposed = 20/10/2026 to 02/11/2026;
- PEM-05 implementation follow-up proposed = 03/11/2026 to 08/03/2027;
- PEM-05.GATE proposed milestone = 08/03/2027.

The schedule remains:

- `governance_status = draft`;
- `is_current_plan = false`;
- metadata `proposal_status = proposed_for_validation`.

Therefore no institutional schedule commitment was manufactured.

A runtime correction was also applied to ensure PEM-05.GATE is placed at the end of the follow-up window, not at its beginning.

## Gate readiness

PEM-02.GATE remains technically ready:

- PEM-02 completed 100%;
- current Horizon exists;
- Formulação ready for ratification;
- Evolution Scenario has 3 continuous dated cycles covering 2026–2030;
- blockingIssueCount = 0;
- readyForClosure = true.

This means **technical readiness only**.

The latest Evolution Cycle temporalization was proposed by SPARKs and accepted by the project leader, but has not yet been validated by COOTAQUARA as a new institutional decision.

Therefore:

- do not ratify PEM-02.GATE yet;
- do not approve the Formulação through the Gate yet;
- do not materialize the institutional Evolution Plan yet;
- do not unblock PEM-03 yet.

## Suggested institutional justification

After COOTAQUARA validates the Evolution Cycle proposal, the recommended justification for Macrophase 2 is:

`Ratifica-se a Macrofase 2 — Formulação Estratégica, considerando a validação já realizada pela Alta Gestão da COOTAQUARA quanto às Perspectivas, Temas e Objetivos Estratégicos, a consolidação do Mapa Estratégico e a validação do Plano de Evolução para o Horizonte 2026–2030. O desdobramento estratégico seguirá para a formulação e validação de OKRs, Resultados-Chave, indicadores, metas, iniciativas e governança da execução, preservando a possibilidade de revisão e melhoria das propostas antes de sua validação institucional.`

Do not use this justification before the Evolution Plan/Cycle dates have been validated by the organization.

## v30 proposal bundle

The v30 strategic proposal bundle remains separate from canonical PEM-03 materialization.

Proposal batch:

`ad1dc304-cf9d-4948-b384-36be6ad7622a`

State:

- staged;
- validation pending;
- proposal-only;
- canonical materialization disabled;
- project-leader review required;
- organization validation required.

This preserves the agreed lifecycle:

`SPARKs proposes -> project leader evaluates -> Organization validates -> canonical materialization`

## Tests

Focused user-facing / schedule tests:

- journeyUserFacingLanguage.test.ts;
- pem02GateUserFacing.test.ts;
- journeySchedulePolicy.test.ts;
- journeyMacrophaseHierarchyUi.test.ts;
- pem02GatePanel.test.ts.

Result:

**21/21 PASS**

## Build

Production build:

**PASS**

- 2231 modules transformed;
- existing non-blocking chunk-size warning only.

## Next canonical action

1. Visually validate the corrected Journey/Gate UI in DEV.
2. Present the Cycle temporalization proposal to COOTAQUARA.
3. If COOTAQUARA validates it, register that real institutional decision.
4. Ratify PEM-02.GATE using the governed institutional panel.
5. Only then release PEM-03.
6. Continue PEM-03 proposals from v30 under the proposal -> leader review -> organization validation -> canonical materialization lifecycle.
