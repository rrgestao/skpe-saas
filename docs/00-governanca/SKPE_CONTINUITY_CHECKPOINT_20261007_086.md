# SK-PE — Continuity Checkpoint 086

Date: 2026-10-07
Project: SPARKs PE application
Mode: EXECUTOR / AUTHORIZED
Front: V1-B02/B03 — Journey dependency compatibility, governed start and business-facing runtime
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261007_085.md

## Purpose

Advance the v1 closure Journey / Monitoring front without using COOTAQUARA as a synthetic test fixture and without promoting any real institutional state.

This checkpoint reconciles runtime compatibility and user-facing semantics that were already open in the local worktree after the evidence-management closure.

## Journey dependency compatibility

The Journey runtime now supports both dependency-storage shapes that exist in the product history:

- legacy direct metadata: metadata.unblock_dependencies;
- cloned methodology metadata: metadata.template_metadata.unblock_dependencies.

The same compatibility rule is used by:

- the database transition guard;
- hierarchical Journey recalculation;
- frontend lock/readiness rendering.

This removes a class of false unlocks/false locks caused only by metadata nesting differences.

Dependencies remain fail-closed:

- incomplete dependency definitions are rejected;
- a dependent step cannot enter execution/validation/completed states while the required predecessor status is unmet;
- recalculation blocks/unblocks only from governed dependency evidence;
- no hard-coded PEM-02 pair is used by the UI.

## Governed project start and Strategic Horizon

Starting the Journey at PEM-00 no longer writes an institutionally approved Strategic Horizon by implication.

The start operation now:

- creates the Strategic Project execution context;
- starts PEM-00;
- creates the Journey schedule/baseline context;
- records only a Strategic Horizon proposal;
- leaves legacy Horizon compatibility fields untouched until governed institutional approval.

This preserves the distinction:

Journey execution cadence != Strategic Horizon approval.

No approval is inferred from project creation.

## Business-facing language

Primary user-facing strategic and monitoring surfaces continue removing internal implementation/methodology codes where those codes add no decision value.

Examples covered by regression:

- Posicionamento Estratégico;
- Objetivos Estratégicos as the next business step;
- Governança do Mapa Estratégico;
- Prontidão das escolhas e do posicionamento;
- Prontidão do portfólio estratégico;
- Configuração do monitoramento estratégico;
- Portability/import governance using business-language descriptions instead of payload/staging jargon.

Internal codes remain available in contracts/audit where required; they are not used as primary UI language.

## Monitoring / RAE preservation

Monitoring panels keep governed distinctions between:

- monitoring-package configuration;
- operational readiness;
- cycle governance;
- measurement/check-in;
- RAE;
- analysis;
- decision;
- learning;
- human ratification.

No performance, cycle or RAE state is fabricated when a real governed cycle does not exist.

High-criticality decisions preserve responsible person and deadline requirements.

## Portability preservation

The business-language cleanup does not alter the governed round trip:

preview -> quality control -> review area -> simulation -> human review -> decision -> explicit governed materialization.

Review/decision still do not trigger materialization implicitly.

## DEV migration state

Applied only in DEV and present in Supabase migration ledger:

- fix_journey_nested_unblock_dependencies;
- fix_journey_nested_dependency_recalculation;
- reconcile_journey_start_with_governed_horizon.

No HOMOL or PRD deployment was performed.

## Validation

Focused V1-B02/B03 / business-language suite:

- 29/29 PASS;
- 0 failures.

Full application suite:

- 627/627 PASS;
- 0 failures.

Production build:

- PASS;
- 2247 modules transformed;
- known large-chunk warning remains;
- known ExcelJS/JSZip static/dynamic import warning remains.

git diff --check:

- PASS;
- line-ending notices only.

## Institutional preservation

This checkpoint does not:

- advance COOTAQUARA Journey stages;
- approve a Strategic Horizon;
- ratify positioning, objectives, portfolio or monitoring;
- create synthetic RAE decisions;
- create fake monitoring cycles;
- deploy HOMOL;
- deploy PRD.

## Next direction

Continue V1-B02/B03 with runtime validation focused on a neutral / non-customer context where possible:

1. verify the complete sequential Journey lock/unlock chain;
2. verify transition guard behavior for nested dependencies;
3. verify Monitoring package -> cycle -> collection -> RAE -> decision -> learning;
4. verify human ratification remains distinct from editing;
5. verify no organization-specific assumptions remain;
6. then proceed to release-readiness / HOMOL gate preparation.

Do not use real-customer institutional approvals as test actions.
