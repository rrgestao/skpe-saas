# SK-PE — Continuity Checkpoint 078

Date: 2026-10-06
Project: SPARKs PE application
Mode: EXECUTOR / AUTHORIZED
Front: V1-B01 Measures — official measurement reading semantics
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261006_077.md

## Purpose

Resolve the v1 official-reading portion of historical Measures conflict C04 without hiding operational observations or fabricating validated results.

## Product rule applied

The application now explicitly distinguishes:

- latest operational observation;
- official validated reading.

Rules:

- submitted observations remain visible;
- rejected observations remain visible;
- validated observations may compose official reading;
- superseded observations do not become current official readings;
- a nonvalidated latest observation is never silently presented as institutional result;
- missing measurement remains distinct from numeric zero.

## Indicator grid

The governed indicator grid now exposes:

- Apuração;
- Situação da apuração;
- Leitura oficial;
- Data da apuração;
- Desempenho da última apuração;
- Desempenho oficial.

Status language:

- submitted = Aguardando validação;
- validated = Validada;
- rejected = Rejeitada;
- superseded = Substituída.

If the latest observation is not validated:

- Leitura oficial = Sem leitura oficial;
- Desempenho oficial = Não oficial.

The underlying latest observation remains visible for operational transparency.

## Workspace summary

Medidas e Desempenho now exposes a Validados summary/filter distinct from Apurados.

The user-facing rule explicitly states that only validated observations compose the official reading.

## Governed history/trend

The history panel continues to show current observations for transparency, but the official trajectory now uses only:

measurement_status = validated
and measured_value is not null

Pending/rejected observations remain visible in the history table with status.

The chart:

- requires at least 3 validated non-null observations;
- never converts missing observations into zero;
- does not classify upward/downward movement as good/bad automatically;
- remains descriptive until polarity/target/context support governed interpretation.

## DEV read-model hardening

Local migration:

supabase/migrations/20261006173500_harden_measure_official_history_semantics.sql

Applied DEV ledger entry:

20261006173303_harden_measure_official_history_semantics

The canonical history function keeps all current non-superseded observations visible, while valid_observation_count and trend_eligible count only validated non-null observations.

Post-application verification:

- validated-only count predicate present = true;
- non-null measurement predicate present = true;
- anon EXECUTE = false;
- authenticated EXECUTE = true.

No HOMOL or PRD migration was applied.

## Validation

Focused official-reading/history suite:

- 7/7 PASS.

Full application suite:

- 595/595 PASS;
- 0 failures.

Production build:

- PASS;
- 2243 modules transformed;
- existing non-blocking large-chunk warning remains.

git diff --check:

- PASS;
- line-ending notices only.

## C04 closure status

C04 official-reading semantics are now materially resolved for the indicator workspace/history:

- latest operational observation is distinct from official validated reading;
- official trend eligibility uses validated observations only.

C04 is not to be reinterpreted as permission to fabricate cycle-wide official snapshots. Monitoring cycle/snapshot contracts remain governed separately and will be validated in V1-B03.

## Remaining V1-B01 work

Historical C01/C02 are not silently closed.

Next focus:

C02 — qualify target and benchmark lifecycle by consumer.

Current known risks:

- contextual target selection excludes superseded but may still surface draft/non-active targets;
- benchmark selection may surface latest draft/archived reference;
- presence of target/benchmark must not equal official/eligible reference.

C01 — catalog adoption/write experience remains a separate Product decision. An older adoption UI implementation exists below an early administration return and is currently unreachable. Do not re-enable it by inference.

## Preservation rules

- local governed worktree remains development authority;
- origin = rrgestao/skpe-saas first;
- sparkooptech/skpe-saas second;
- push only recovery/2026-09-13-recent-ux-preservation;
- no main promotion;
- no PRD deployment;
- no artificial institutional advancement of COOTAQUARA.
