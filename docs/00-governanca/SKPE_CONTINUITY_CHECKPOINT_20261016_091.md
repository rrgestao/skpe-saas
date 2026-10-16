# SK-PE — Continuity Checkpoint 091

Date: 2026-10-16
Project: SPARKs PE application
Mode: EXECUTOR / AUTHORIZED
Front: V1-P03 — Frontend performance / heavy dependency code splitting
Canonical local repository: C:\DADOS\SPARKs\skpe-saas
Base branch: recovery/2026-09-13-recent-ux-preservation
Previous commit: 457fe94b5578036e6828a13f5f9914b2d312737e
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261016_090.md

## Purpose

Reduce the production entry bundle without changing business contracts, routes, permissions or strategic data.

## Root cause confirmed

The build warning showed that JSZip and ExcelJS were dynamically imported by the evidence preview but also imported statically by portability and delivery-kit modules. The static imports prevented those heavy runtimes from being separated into on-demand chunks.

## Implementation

Runtime imports were moved behind dynamic imports in:

- portability canonical workbook generation;
- portability workbook parsing and OOXML normalization;
- portable ZIP package generation;
- methodology delivery-kit ZIP generation.

ExcelJS remains imported only as a TypeScript type where compile-time annotations are required.

A regression test now rejects reintroduction of static runtime imports in these critical paths.

## Build result

Before this change:

- main JS: approximately 3,421.39 kB;
- main JS gzip: approximately 905.81 kB;
- JSZip ineffective-dynamic-import warning: present;
- ExcelJS ineffective-dynamic-import warning: present.

After this change:

- main JS: approximately 2,396.16 kB;
- main JS gzip: approximately 619.87 kB;
- JSZip chunk: approximately 95.87 kB / 28.44 kB gzip;
- ExcelJS chunk: approximately 929.89 kB / 256.47 kB gzip;
- ineffective-dynamic-import warnings: eliminated;
- production build: PASS; 2247 modules transformed.

The main bundle reduction is approximately 1.0 MB uncompressed and 286 kB gzip.

## Closure status

V1-P03 is ADVANCED / PARTIAL, not closed.

The generic >500 kB warning remains because:

- the main application chunk is still above 500 kB;
- the ExcelJS on-demand chunk is still above 500 kB.

Further splitting must preserve deep links and existing route/workspace behavior and should be performed only where safe.

## Validation

- Existing full web suite before adding the regression file: 639/639 PASS.
- New heavy-dependency lazy-loading regression test: 1/1 PASS.
- Final full suite including the new regression file: 640/640 PASS; 0 failures.
- Production build: PASS.
- No JSZip/ExcelJS ineffective dynamic-import warnings remain.

## Preservation

- no database change;
- no migration;
- no Supabase mutation;
- no COOTAQUARA state change;
- no HOMOL or PRD deployment;
- no main-branch promotion.
