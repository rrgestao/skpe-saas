# SPARKs PE — Roadmap de Fechamento da v1

Date: 2026-10-06
Status: ACTIVE CLOSURE AUTHORITY
Scope: first production-ready version of the SPARKs PE module
Technical baseline: af92e2d04c9be9834f30071ccddecea68c17733f
Branch: recovery/2026-09-13-recent-ux-preservation

## Purpose

This document reconciles the September master/current-state roadmap with the actual October implementation and runtime evidence.

It is not a rewrite of the historical roadmap. Historical PARTIAL/UNKNOWN/CONFLICT labels remain valid for their original baseline, but they must not be interpreted as the present implementation state without reconciliation.

This closure roadmap classifies remaining work into:

- V1_BLOCKER: must be resolved before v1 release acceptance;
- V1_REQUIRED: belongs in the functional v1 and must be closed before declaring the product functionally complete;
- V1_RELEASE: operational/release-readiness requirement after functional closure and before production release;
- V1.1_OR_LATER: valuable evolution that does not block the first complete version.

## v1 completion definition

### Functional v1 complete

The product must support a coherent end-to-end strategic-management cycle:

Preparation -> Diagnosis -> Strategic Analysis -> Identity/Positioning -> Objectives/Map -> Measures/Targets/Benchmarks -> OKRs/KRs -> Initiatives/Actions -> Execution Governance -> Monitoring -> RAE/Decision/Learning -> Evolution

with:

- governed evidence and provenance;
- human validation at institutional decision points;
- executive overview and drill-down;
- management outputs/reports;
- traceability from evidence to execution/result;
- no synthetic approvals, measurements, trends or historical facts.

### v1 release ready

Functional v1 complete plus:

- authenticated HOMOL validation;
- critical authorization/security issues treated;
- reproducible migration/deployment verification;
- rollback/backup minimum;
- runtime observability sufficient for controlled release;
- final UX/performance acceptance.

## Reconciled status of major historical roadmap fronts

| Front | October state | Closure classification | Remaining closure |
| --- | --- | --- | --- |
| Journey PEM-00..PEM-05 | Advanced / governed | V1_BLOCKER | Execute neutral-organization end-to-end runtime validation, including Gates and future phases without advancing COOTAQUARA artificially. |
| Strategic diagnosis | Advanced | V1_REQUIRED | Full runtime regression across diagnosis -> formulation traceability and real evidence consumption. |
| PESTEL / SWOT / TOWS | Advanced | V1_REQUIRED | Authenticated E2E validation and visual/business-language acceptance. |
| Strategic risks / mitigation | Advanced | V1_REQUIRED | Validate risk -> treatment -> initiative/action -> evidence -> residual-risk chain in runtime. |
| Identity / positioning | Advanced | V1_REQUIRED | Validate full edit/review/validation lifecycle and consolidated output. |
| Themes / perspectives / objectives / BSC map | Advanced | V1_REQUIRED | Validate full lifecycle, causal relations and read-only behavior outside governed stage/revision. |
| Measures and Performance | Advanced but semantic decisions remain | V1_BLOCKER | Close C01/C02/C04 product semantics and validate authenticated lifecycle. |
| Indicator historical trend | Implemented | CLOSED_FOR_V1 | Governed read model, >=3 valid observation rule, no synthetic trend. |
| OKRs / KRs | Advanced | V1_REQUIRED | Authenticated lifecycle, annual targets and traceability to OE/KPI/initiatives. |
| Initiatives / actions | Advanced | V1_REQUIRED | Complete executive objective/KPI/OKR/initiative drill-down and validate lifecycle. |
| Initiative budget / economic execution | Operational base exists | V1_REQUIRED | Final v1 management UX for budget vs actual, effort and physical-financial reading. |
| Monitoring FE-08 | Advanced | V1_BLOCKER | Authenticated cycle: measurement -> analysis -> exception -> decision -> review/RAE -> ratification/learning. |
| RAE / decisions / learning | Advanced | V1_BLOCKER | Authenticated E2E, audit, roles and human-decision validation. |
| Evidence registration/upload | Implemented + DEV validated | CLOSED_FOR_V1 | Initial governed intake complete. |
| Evidence version lifecycle | Implemented + DEV validated | CLOSED_FOR_V1 | Immutable version history and return-to-validation complete. |
| Evidence checklist / sufficiency | Advanced | V1_REQUIRED | Validate checklist <-> evidence <-> sufficiency <-> diagnosis/decision runtime chain. |
| Executive Overview | Advanced | V1_REQUIRED | Add objective-centric and measure-centric executive drill-down; final visual acceptance. |
| Results/Performance Cockpit | Advanced | V1_REQUIRED | Complete OE/KPI/OKR/initiative analytical path and contextual filters. |
| Executive performance report | Implemented | CLOSED_FOR_V1_BASE | HTML output and governed absence handling complete; final report center integration remains. |
| Executive portfolio CSV | Implemented | CLOSED_FOR_V1_BASE | Tabular executive extraction complete. |
| Entregas e Relatórios navigation | Implemented | CLOSED_FOR_V1_BASE | First-class area complete; final publication set still required. |
| Final PE report / delivery package | Partial | V1_REQUIRED | Consolidate full executive PE report and phase/final delivery packages from governed artifacts. |
| Import / export / portability | Implemented + DEV validated | CLOSED_FOR_V1 | Multi-organization round-trip, authority preservation, human review/decision and explicit governed materialization closed in checkpoint 084. |
| Organization/user administration | Advanced | V1_RELEASE | Runtime permission/profile/role scenarios and unauthorized-path validation. |
| Security hardening | Backlog identified | V1_RELEASE | Triage Supabase security advisor findings and close critical/high release-relevant items. |
| Frontend performance | Build green, bundle large | V1_RELEASE | Code splitting/lazy-loading for heavy areas; establish acceptable bundle/runtime threshold. |
| HOMOL runtime | Historical evidence only / new baseline not deployed | V1_RELEASE | Deploy reconciled baseline, verify effective SHA and authenticated smoke/E2E. |
| Production release readiness | Not yet closed | V1_RELEASE | Backup/restore minimum, rollback, migration ledger, monitoring/logging, release checklist. |
| Temporary access cleanup | Still valid infra item | V1_RELEASE | Confirm existence and remove safely when replacement path is proven. |
| Local hygiene | Partial | V1.1_OR_LATER unless risk emerges | Preserve legitimate work; cleanup is operational, not a functional v1 blocker. |
| Advanced scale / multi-capability | Future | V1.1_OR_LATER | Product decision after v1. |
| Advanced portfolio/capacity analytics | Future | V1.1_OR_LATER | Evolve from real usage evidence. |

## V1_BLOCKER — mandatory before functional closure

### V1-B01 — Measures lifecycle and official reading semantics

Historical conflicts C01/C02/C04 must be resolved as explicit product contracts.

Required decisions:

1. which measure/catalog adoption write experiences are officially part of v1 and for which roles;
2. lifecycle precedence for indicator, target, benchmark and measurement states by consumer;
3. what each UI treats as official/current measurement;
4. how submitted, validated, rejected and superseded measurements are exposed;
5. cycle/date-cut and tie-break rules;
6. whether contextual display can show nonvalidated observations and how they are qualified.

Acceptance:

- one written Product decision;
- frontend/read model aligned;
- tests cover each state;
- authenticated DEV/HOMOL scenario demonstrates the rule;
- no rejected/superseded/submitted observation is silently presented as official.

### V1-B02 — Neutral full-Journey runtime validation

Use a neutral/generic organization created or selected specifically for application validation.

Must exercise:

- PEM-00 through PEM-05;
- all Gates;
- schedule/baseline;
- evidence;
- diagnosis;
- formulation;
- measures;
- OKRs;
- initiatives;
- activation;
- monitoring;
- RAE;
- decisions;
- learning;
- evolution;
- outputs.

The test organization must not mutate COOTAQUARA institutional truth.

Acceptance:

- every transition has observable evidence;
- blocked transitions fail closed;
- approvals require human action where specified;
- no current/future stage is unlocked by test shortcuts;
- generated outputs match current canonical state.

### V1-B03 — Monitoring / RAE complete authenticated cycle

Acceptance scenario:

validated measure -> monitoring cycle -> collection -> analysis -> management exception -> review/RAE -> decision -> responsibility/deadline -> ratification -> learning/evolution.

Must prove:

- permissions;
- audit;
- lifecycle;
- responsibility;
- no fabricated result;
- correct downstream refresh in Overview/Cockpit.

## V1_REQUIRED — product completeness before v1 declaration

### V1-R01 — Objective-centered executive analytics

Create an executive drill-down:

Strategic Objective -> KPI/Indicator -> Target/Benchmark -> OKR/KR -> Initiative -> Action -> Result/Attention.

Rules:

- read-only analytical aggregation;
- missing data remains missing;
- no synthetic health score unless governed;
- filters must retain project/organization context;
- drill-down returns to canonical work area.

### V1-R02 — Final Executive Report / Publication Center

The Entregas e Relatórios area must expose at minimum:

- Executive Strategic Plan report;
- Executive Results/Performance report;
- final delivery kit;
- phase/stage governed artifacts;
- portfolio CSV;
- canonical import/export outputs.

The full Strategic Plan report should reconcile, when available:

- institutional context;
- diagnosis;
- strategic analyses;
- identity/positioning;
- map/objectives;
- indicators/targets/benchmarks;
- OKRs;
- initiatives;
- governance/monitoring;
- risks;
- traceability;
- pending gaps/assumptions.

It must never fill missing approved content with generated facts.

### V1-R03 — Initiative budget / physical-financial management UX

Complete the already-approved roadmap scope without becoming corporate accounting.

Minimum:

- planned vs actual monetary execution;
- planned vs actual effort;
- action-level economic entries;
- initiative rollup;
- physical progress beside economic progress;
- target/end-date context;
- variances;
- management interpretation;
- responsive UX;
- exports/traceability where current contracts support them.

### V1-R04 — Evidence sufficiency and strategic consumption

Prove and refine:

expected checklist item -> linked evidence -> quality/sufficiency -> analytical use -> diagnosis/formulation decision.

Must distinguish:

- available;
- linked;
- sufficient;
- validated;
- currently used.

### V1-R05 — Import/export portability E2E — CLOSED_FOR_V1 (Checkpoint 084)

Closure status: 613/613 full-suite PASS; production build PASS; DEV Edge Function skpe-import-incorporation v11 active with JWT verification. No real customer materialization executed.

Minimum scenarios:

- export;
- versioned review;
- reimport;
- no-change;
- update;
- blocked/conflict;
- governed materialization;
- provenance preserved;
- ZIP/HTML/XLSX never become hidden product authority.

### V1-R06 — Full visual/business-language regression

Review every primary section:

- no internal codes in primary user headings unless useful;
- empty states;
- tooltips;
- status/date-target conventions;
- accessibility basics;
- responsive behavior;
- grid consistency;
- organization accent palette;
- clear distinction between proposal, validation, approval and execution.

## V1_RELEASE — release readiness

### V1-P01 — Authenticated permissions matrix

Test minimum profiles:

- platform admin;
- organization admin;
- project leader;
- participant/editor;
- read-only/visitor;
- unauthorized user;
- cross-organization cases.

### V1-P02 — Security hardening triage

Use current Supabase advisors and application contracts.

Required before release:

- classify findings as release-critical/high vs legacy/lower;
- fix release-critical/high items;
- verify Storage/RLS/function grants for new v1 flows;
- verify Auth configuration relevant to production.

### V1-P03 — Frontend performance

Current production build is green but emits the large-chunk warning.

Required:

- map heavy modules;
- lazy-load major workspaces where safe;
- preserve route/deep-link behavior;
- measure post-split bundle;
- keep regression/build green.

### V1-P04 — HOMOL acceptance

Deploy only after closure baseline is committed.

Required evidence:

- deployed SHA;
- health;
- authenticated login;
- organization context;
- Journey;
- dashboards;
- reports;
- evidence upload/version;
- measures/history;
- monitoring;
- exports;
- permission scenarios.

### V1-P05 — Release operational controls

Minimum:

- database migration ledger reconciled;
- backup/restore path;
- rollback path;
- environment secrets/config validation;
- application/runtime logs;
- error visibility;
- release checklist;
- explicit PRD authorization.

## V1.1_OR_LATER

Do not block v1 for:

- advanced predictive analytics;
- synthetic strategic-health scoring not yet governed;
- multi-capability expansion not already required by v1;
- sophisticated scenario simulation beyond current Evolution contracts;
- broad infrastructure replatforming;
- complete local workstation hygiene where no release risk exists;
- advanced portfolio/capacity analytics beyond current validated user need.

## Execution order from this checkpoint

1. V1-B01 — Measures semantic closure.
2. V1-R01 — Objective-centered executive analytics.
3. V1-R02 — Final report/publication center.
4. V1-R03 — Initiative budget / physical-financial UX.
5. V1-R04 + V1-R05 — evidence sufficiency and portability E2E.
6. V1-B02 + V1-B03 — neutral full-Journey and monitoring/RAE authenticated validation.
7. V1-R06 — full UX/business-language regression.
8. V1-P01 + V1-P02 + V1-P03 — permissions, security, performance.
9. V1-P04 + V1-P05 — HOMOL and release readiness.

## Non-negotiable preservation rules

- local governed development state remains authoritative over older remote content;
- origin = rrgestao/skpe-saas first;
- sparkooptech/skpe-saas second;
- no local update from remote without explicit user authorization;
- no main promotion unless explicitly authorized;
- no PRD deployment without explicit authorization;
- COOTAQUARA remains a real institutional project, not a test fixture;
- human decisions are never fabricated for application completion.
