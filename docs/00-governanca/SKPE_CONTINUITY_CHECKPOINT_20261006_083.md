# SK-PE — Continuity Checkpoint 083

Date: 2026-10-06
Project: SPARKs PE application
Mode: EXECUTOR / AUTHORIZED
Front: V1-R04 Evidence requirement coverage and sufficiency semantics
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261006_082.md

## Purpose

Close the v1 evidence-coverage gap without treating raw document counts as diagnostic completeness.

## Evidence semantic separation

The Evidence Management workspace now explicitly separates:

- evidence available;
- evidence linked/used;
- checklist requirement with file linked;
- checklist requirement with validated file;
- checklist item assessed;
- contextual sufficiency of evidence.

The UI states:

Requisito != arquivo != evidência suficiente.

A linked file is not automatically treated as a validated or sufficient evidence.

## Operational checklist authority

Coverage uses the canonical RPC:

get_skpe_evidence_checklist

For the materialized project checklist the application consumes:

- is_required;
- is_applicable;
- collection_status;
- assessment_status;
- files_count;
- validated_files_count;
- checklist completion/readiness data.

No coverage percentage is derived from the generic evidence asset inventory.

## Governed coverage

The workspace calculates only over required + applicable operational requirements:

- required applicable requirements;
- requirements with at least one linked file;
- requirements with at least one validated file;
- requirements with a contextual assessment;
- validated requirement coverage percentage.

If the operational checklist is not materialized, coverage is explicitly unavailable.

## Sufficiency rule

Sufficiency remains a contextual governed evaluation.

It is not derived from:

- number of files;
- availability;
- linkage alone;
- validated coverage percentage.

The existing sufficiency_status remains visible at evidence/use level.

## UI correction

The old card named Cobertura do Diagnóstico, which counted evidence assets marked as used, was renamed to Em uso estratégico.

This prevents a count of used evidence assets from being misread as checklist coverage.

## Validation

Focused evidence coverage suite:

- 3/3 PASS.

Full application suite:

- 608/608 PASS;
- 0 failures.

Production build:

- PASS;
- 2245 modules transformed;
- existing large-chunk warning remains.

git diff --check:

- PASS;
- line-ending notices only.

## Institutional preservation

This front does not:

- mark a checklist requirement sufficient automatically;
- validate evidence automatically;
- create evidence;
- materialize a missing checklist;
- advance a Journey stage;
- change COOTAQUARA;
- deploy HOMOL;
- change PRD.

## V1-R04 status

Evidence sufficiency and requirement coverage: materially implemented for v1.

Authenticated neutral-project E2E remains required before release acceptance.

## Next development direction

Proceed to V1-R05 — Portability / import-export end-to-end integrity.

Required closure:

- export artifacts remain interchange outputs, not silent product authority;
- import remains preview/review/materialization governed;
- round-trip metadata/provenance remains traceable;
- user-facing language clearly separates export, import preview and canonical materialization;
- no import silently approves strategic content.

## Git governance

Required order:

1. local governed worktree;
2. origin = rrgestao/skpe-saas;
3. sparkooptech/skpe-saas.

Push only recovery/2026-09-13-recent-ux-preservation.

No main promotion.
