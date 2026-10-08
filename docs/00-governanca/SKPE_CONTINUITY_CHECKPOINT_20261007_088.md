# SK-PE — Continuity Checkpoint 088

Date: 2026-10-07
Project: SPARKs PE application
Mode: EXECUTOR / AUTHORIZED
Front: V1-B02 — Neutral authenticated runtime validation harness
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261007_087.md

## Purpose

Prepare the neutral full-Journey runtime validation path without using COOTAQUARA or any other real customer organization as a synthetic fixture.

## Neutral tenant confirmed

DEV already contains a dedicated technical organization:

- code: SKPE-V1-RUNTIME
- purpose: SPARKs PE v1 runtime validation
- status: active

The tenant has its own technical Strategic Project:

- code: PE-SKPE-V1-RUNTIME-2026
- name: Validação Runtime E2E — SPARKs PE v1
- current phase: PEM-00
- project status: draft
- progress: 0%

No real-customer institutional state was used.

## Runtime fail-closed evidence

The neutral Journey contains the governed dependency:

PEM-02.04 -> PEM-02.03 completed

A controlled DEV database attempt tried to move PEM-02.04 to in_progress while PEM-02.03 remained not_started.

The trigger rejected the transition with SQLSTATE 55000 and the explicit dependency message.

The post-check confirmed that PEM-02.04 remained not_started.

This proves runtime fail-closed behavior in DEV in addition to static/unit tests.

## Authentication constraint discovered

The Journey mutation RPC set_skpe_journey_item_status requires a real authenticated actor so that:

- auth.uid() is valid;
- authorization is evaluated through the normal application contract;
- audit records identify the correct technical actor;
- no service-role impersonation is introduced.

The neutral organization already has:

- one active membership;
- one organization administrator.

However, the repository does not contain a dedicated E2E credential and does not have a Playwright/Cypress/browser E2E harness.

No personal user identity was silently reused.

## Minimal authenticated harness

Added:

apps/web/scripts/validate-neutral-runtime.mjs

The harness uses the existing @supabase/supabase-js dependency and does not add a new testing framework.

It is hard-scoped to:

- organization SKPE-V1-RUNTIME;
- project PE-SKPE-V1-RUNTIME-2026.

It refuses to execute for another organization code.

The harness:

1. loads Supabase public configuration from .env.local;
2. optionally loads local-only .env.e2e.local;
3. requires SKPE_E2E_EMAIL and SKPE_E2E_PASSWORD from local environment;
4. authenticates through Supabase Auth;
5. confirms the neutral tenant;
6. confirms active organization-admin membership for the authenticated technical user;
7. confirms the neutral Strategic Project;
8. loads the governed Journey read model;
9. performs an authenticated fail-closed dependency check;
10. verifies that the blocked attempt did not mutate Journey state.

No service-role key is used.

## Fail-safe behavior

The harness was executed without E2E credentials.

Expected result:

- FAIL before authentication;
- no Journey mutation;
- explicit instruction to provide credentials outside Git.

This confirms that missing credentials cannot accidentally fall back to a personal identity or privileged database context.

## NPM command

Added:

npm run test:e2e:neutral

The command invokes only the neutral runtime harness.

## Validation

Harness contract tests:

- 4/4 PASS.

Full application suite:

- 635/635 PASS;
- 0 failures.

Production build:

- PASS;
- 2247 modules transformed;
- existing large-chunk warning remains;
- existing ExcelJS / JSZip ineffective-dynamic-import warnings remain.

git diff --check:

- PASS.

## Remaining prerequisite for authenticated E2E

To execute the complete neutral Journey through the normal RPC path, configure a dedicated technical credential locally:

- SKPE_E2E_EMAIL
- SKPE_E2E_PASSWORD

The credential must belong only to the SKPE-V1-RUNTIME validation context and must not be committed to Git.

No secret was created or versioned in this checkpoint.

## Next direction

Once the dedicated technical credential is available:

1. run npm run test:e2e:neutral;
2. confirm authenticated precheck;
3. extend the harness incrementally to exercise PEM-00 first;
4. preserve one transition at a time with observable audit evidence;
5. never auto-approve institutional decisions;
6. advance through Gates only through explicit governed test actions;
7. continue through Monitoring / RAE / Learning using the lifecycle closed in checkpoint 087.

If credential provisioning remains unavailable, continue V1_REQUIRED / V1_RELEASE work without fabricating an authenticated actor.
