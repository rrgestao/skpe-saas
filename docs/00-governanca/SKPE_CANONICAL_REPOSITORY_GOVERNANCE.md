# SK-PE Canonical Repository Governance

Decision: `sparkooptech/skpe-saas` is the corporate canonical repository for SK-PE.

Effective date: 2026-09-07.

Current canonical development branch: `feature/formulacao-estrategica-operacional`.

Canonical head observed at this gate: `4baea804e9f42fb3a1ae76cab60928a84886a4bb`.

This branch is the current canonical development branch. This decision does not make the current branching model permanent, and it does not authorize production, HOMOL, Supabase, database, hosting, Auth, Storage, Edge Function, DNS, or migration changes.

## Repository Roles

`https://github.com/sparkooptech/skpe-saas.git` is the only corporate canonical origin for new SK-PE development, migrations, and functional evolution.

`rrgestao/skpe-saas` is classified as `READ_ONLY_HISTORICAL`. It may be used for audit, archaeology, historical proof, comparison, and controlled recovery. It must not be used as the source for new canonical development, exclusive migrations, release source, or a new architectural baseline.

## Branch Roles

Canonical development: `feature/formulacao-estrategica-operacional`.

Release / HOMOL: `main`. The branch contains historical HOMOL/deployment assets and must not be rewritten, deleted, or simply aligned to the canonical development branch without a dedicated promotion/release gate.

Preservation: `preserve/*`. `preserve/skpe-saas-legitimate-local-work` is `DO_NOT_DELETE` until explicit reconciliation of its unique content is complete.

Docs: `docs/*` is reserved for isolated documentation and audit work.

Feature: `feature/*` is reserved for governed functional evolution.

Fix: `fix/*` is reserved for governed fixes.

A future integration branch may exist only by explicit architectural decision. It must not be created only because of a conventional GitFlow template.

## Operational Rules

No new development, migration, or functional evolution may start exclusively in `rrgestao/skpe-saas`.

New migrations applied or planned for Supabase must have a corresponding versioned file in the canonical repository.

The current Supabase DEV project remains a critical system of record. This Git governance decision does not authorize migration execution, database reset, project recreation, or project rebind.

Ricardo and other developers may continue functional development on the canonical development branch, provided that the remote is the corporate `sparkooptech/skpe-saas` repository.

Before substantive writes, agents and scripts must validate that `origin` is `https://github.com/sparkooptech/skpe-saas.git` and block execution if a different remote is detected.

Historical documentation is not the current source of truth when it conflicts with this decision.

## Branch Protection Readiness

For `feature/formulacao-estrategica-operacional`, the initial governance target is:

- prevent force push;
- prevent branch deletion;
- preserve history;
- require work to be based on the canonical remote;
- evaluate mandatory pull requests according to Ricardo's active workflow;
- evaluate at least one approval for sensitive changes;
- require reliable CI/checks only after those checks exist;
- require explicit review for migrations;
- require a dedicated gate for Supabase and infrastructure changes.

MUST_HAVE_NOW:

- prevent force push;
- prevent deletion;
- document canonical remote validation;
- document migration provenance requirement.

SHOULD_HAVE:

- one approval for sensitive changes;
- reviewed pull request flow where compatible with ongoing development;
- CODEOWNERS or equivalent review routing for migrations and infrastructure.

FUTURE:

- required status checks after reliable CI exists;
- formal DEV to HOMOL to PRD promotion model;
- ruleset-based enforcement for protected paths.

## Exceptions

`main` and `preserve/skpe-saas-legitimate-local-work` remain logically protected because they contain unique historical assets. They must not be removed, rewritten, or automatically converged by this gate.
