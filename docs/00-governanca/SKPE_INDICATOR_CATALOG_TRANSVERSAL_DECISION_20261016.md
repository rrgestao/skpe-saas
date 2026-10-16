# Decision: transversal SPARKs Indicator Catalog (2026-10-16)

Status: PRODUCT DECISION APPROVED; IMPLEMENTATION INCOMPLETE.

## Product invariant

Every new organization indicator must reference an existing versioned SPARKs master-catalog definition. The master is transversal to SK-PE, SK-DA, SK-PN and the future Performance Management module. Organization adoption retains its own goals, measurements, accountability, evidence and strategic bindings. Never create a new organization-only definition.

## Required create-and-adopt experience

1. Search master catalog by name, code, known aliases and normalized semantic equivalents before offering creation; do not mistake a renamed indicator for a new concept.
2. If a suitable reference exists, adopt that reference via the existing governed organization-adoption contract.
3. Otherwise propose a new reference with code, name, definition, formula or clear measurement criterion, unit, polarity, frequency, source and applicability.
4. Authorized creation must register the master reference and the organization's adoption atomically; if either fails, neither persists. Concurrent duplicate proposals must resolve against the canonical catalog, not generate competing definitions.
5. New references should follow explicit governed draft/review/activation semantics; no automatic institutional approval. Define authorized roles for creation, review and activation separately from organization adoption.
6. Preserve existing versions, evidence, historical indicators and canonical UI. Provide a governed reconciliation path for legacy-only indicators; do not force a destructive NOT NULL change until all legacy references are mapped.

## Repository inspection

- Master table: public.skpe_indicator_reference_catalog (20260904015531_create_skpe_indicator_reference_catalog.sql).
- Existing governed master create/version RPC: public.upsert_platform_measure_reference_catalog (20260908170508_govern_platform_measure_reference_catalog.sql); currently restricted to require_platform_super_admin().
- Existing master administration UI: apps/web/src/modules/platform-admin/PlatformMeasureCatalog.tsx.
- Existing adoption RPC: public.adopt_sparks_measure_references_for_organization (20260909214455_govern_organization_measure_reference_adoption.sql).
- Existing dual selector: apps/web/src/modules/measures/SparksMeasureDualSelector.tsx.
- Legacy exception: 20260909234252_reconcile_organization_specific_measure_indicators.sql permits null reference_catalog_id when legacy_indicator_id exists.

## Security/implementation gate

Do not call the Platform Super Admin master-write RPC from ordinary organization UI or broaden its privileges. Design a separate governed atomic create-and-adopt backend operation with explicit membership/authorization checks, duplicate detection and audit, preserving Platform Super Admin control over official catalog activation. Validate real database schema and permissions before migrations; never write client/production data as a shortcut.

## Current local development state

The dual selector has a separate uncommitted local eligibility/deduplication safety improvement from the prior turn. Preserve it. This decision file does not represent deployed functionality or completed data reconciliation.
