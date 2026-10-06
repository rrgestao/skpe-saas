# SK-PE — Continuity Checkpoint 076

Date: 2026-10-06
Project: SPARKs PE application
Mode: EXECUTOR / AUTHORIZED
Front: Governed evidence version lifecycle
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261006_075.md

## Purpose

Complete the evidence lifecycle beyond initial registration/upload by supporting immutable version history and controlled publication of a new current version.

This front preserves SK-DOC as the document/evidence/version authority and does not alter COOTAQUARA institutional state.

## Governed evidence version lifecycle

A new canonical operation was added:

add_sparks_evidence_version

The operation:

- requires canonical evidence management permission;
- requires the evidence asset to belong to the target organization;
- requires a non-empty content hash, file name and governed storage path;
- requires the canonical private bucket sparks-evidence;
- requires organization-scoped Storage path;
- requires an auditable change reason with at least 10 characters;
- rejects content identical to the current version;
- rejects content already present anywhere in the asset version history;
- calculates the next immutable version number;
- inserts a new sparks_evidence_versions row;
- preserves all previous versions;
- sets the new version as current;
- updates the asset content hash;
- returns validation_status to pending;
- resets reliability and quality/completeness/currentness/overall assessments;
- marks human validation as required.

No prior version is deleted.

## Evidence Management UI

The evidence analysis panel now exposes:

- complete version history;
- version number/label;
- file name;
- creation date/time;
- change summary;
- download of previous physical versions;
- new-version file selection;
- mandatory version rationale;
- governed new-version publication.

The UI computes SHA-256 before upload and blocks duplicate content already present in the loaded version history.

The physical object is uploaded only to sparks-evidence under an organization/evidence scoped path.

If canonical version registration fails after upload, the uploaded object is removed to avoid Storage orphans.

The UI explicitly states that the previous version is preserved and that the evidence returns to human validation.

## Supabase DEV

Project: vumbfpbcozjebomcthdw

Local migration artifact:

supabase/migrations/20261006134848_govern_transversal_evidence_versions.sql

Applied DEV ledger entry:

20261006171329_govern_transversal_evidence_versions

Post-application verification:

- function exists = true;
- anon EXECUTE = false;
- authenticated EXECUTE = true;
- service_role EXECUTE = true.

No HOMOL or PRD migration was applied.

## Validation

Focused version lifecycle suite:

- 3/3 PASS.

Full application suite:

- 591/591 PASS;
- 0 failures.

Production build:

- PASS;
- 2243 modules transformed;
- existing non-blocking large-chunk warning remains.

git diff --check:

- PASS;
- line-ending notices only.

## Institutional preservation

This front does NOT:

- create organizational evidence automatically;
- validate a new version automatically;
- discard old versions;
- fabricate quality/reliability assessments;
- ratify a Journey Gate;
- open blocked COOTAQUARA stages;
- deploy HOMOL;
- alter PRD.

## Git governance

Required synchronization order:

1. local governed worktree;
2. origin = rrgestao/skpe-saas;
3. sparkooptech/skpe-saas as secondary.

Push only recovery/2026-09-13-recent-ux-preservation.

No main branch promotion belongs to this checkpoint.

## Next development direction

With the evidence intake + version lifecycle now operational, proceed to a formal v1 closure reconciliation that classifies remaining product work as:

- V1_BLOCKER;
- V1_REQUIRED;
- V1.1_OR_LATER.

Use current code/runtime/checkpoints rather than September status labels in isolation.

Priority domains for that reconciliation:

1. Medidas lifecycle and official-measurement semantics;
2. end-to-end generic-organization Journey validation;
3. executive dashboards by OE/KPI/OKR/initiative;
4. final report/output center completeness;
5. monitoring/RAE authenticated cycle;
6. budget/physical-financial initiative experience;
7. permissions/runtime security validation;
8. frontend performance/code splitting;
9. HOMOL acceptance and release readiness.
