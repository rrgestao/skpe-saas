# SK-PE — Continuity Checkpoint 075

Date: 2026-10-06
Project: SPARKs PE application
Mode: EXECUTOR / AUTHORIZED
Front: Executive output discoverability and governed indicator trends
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261006_074.md

## Purpose

Continue the enterprise application-completion front by making executive outputs first-class and by adding historical indicator analytics only where the canonical measurement history supports a real trend.

No institutional state of COOTAQUARA is changed.

## Entregas e Relatórios as a first-class area

The module navigation now exposes a dedicated Entregas e Relatórios entry whenever the user can view methodology artifacts.

This is separate from Importação e Exportação.

The former Artefatos e evidências presentation was reframed as a business-facing output center:

- active section title: Entregas e Relatórios;
- page eyebrow: Central de saídas executivas;
- page title: Entregas e Relatórios;
- explanation that reports and delivery kits are generated from governed artifacts;
- Kit action renamed to Gerar entregas e relatório.

Existing artifact versioning, readiness, validation and audit remain the source authority.

## Governed indicator history and trend

The application now consumes the existing canonical read model:

get_sparks_measure_indicator_history

The read model itself establishes trend eligibility only when at least three valid observations exist.

A new Histórico e Tendência panel is opened from the read-only Indicators grid by double click.

The panel provides:

- valid observation count;
- first observed value;
- latest observed value;
- governed historical period;
- trajectory chart when trend is eligible;
- observed minimum and maximum;
- measurement table with date, value, performance, data quality, source and evidence.

## Anti-fabrication rules

The historical visualization:

- excludes null measured values from the plotted trajectory;
- never converts missing observations to zero;
- does not draw a trend with fewer than three valid observations;
- explicitly displays Histórico insuficiente para tendência governada when needed;
- does not classify upward/downward movement as good or bad automatically;
- states that improvement/deterioration interpretation depends on governed polarity, target and context.

No synthetic historical point is created.

## Validation

Focused tests:

- 5/5 PASS.

Full application suite:

- 588/588 PASS;
- 0 failures.

Production build:

- PASS;
- 2243 modules transformed;
- existing non-blocking large-chunk warning only.

git diff --check:

- PASS;
- line-ending notices only.

## Institutional preservation

This front does not:

- ratify COOTAQUARA PEM-02.GATE;
- open blocked COOTAQUARA stages;
- create measurements;
- create targets;
- infer historical observations;
- validate an indicator;
- promote a Journey stage;
- deploy HOMOL;
- change PRD.

## Git governance

Required synchronization order:

1. local governed worktree;
2. origin = rrgestao/skpe-saas;
3. sparkooptech/skpe-saas as secondary.

Push only recovery/2026-09-13-recent-ux-preservation.

No main branch promotion belongs to this checkpoint.

## Next development direction

Continue with enterprise operational completeness, especially:

1. evidence version/update lifecycle after initial upload;
2. richer executive report discovery and cross-report navigation;
3. analytical views by strategic objective and indicator;
4. generic-organization runtime validation;
5. performance/code-splitting backlog for the large production bundle;
6. isolated security-hardening backlog from Supabase advisor findings.

Do not create strategic health or trend interpretations without governed data and rules.
