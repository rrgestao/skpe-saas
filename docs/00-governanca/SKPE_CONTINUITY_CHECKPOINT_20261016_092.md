# SPARKs PE - Continuity Checkpoint 092

Date: 2026-10-16
Repository: C:\DADOS\SPARKs\skpe-saas (RMKB-NTB only)
Branch: recovery/2026-09-13-recent-ux-preservation
Starting commit: faadaa9

## Product decision - V1-B01/C01

User approved option A+ on 2026-10-16: the SPARKs reference indicator catalog is transversal to modules; SK-PE methodology proposes standardized indicators; organizations may adopt these indicators and submit their own indicators for governed registration. A catalog definition must not be duplicated for each organization. Organization-specific application owns its targets, measurements, responsible persons and contextual relationships.

Existing implementation verified: SparksMeasureDualSelector uses canonical SparksSmartGrid and the RPCs get_sparks_measure_reference_catalog, get_sparks_measure_organization_indicators, adopt_sparks_measure_references_for_organization and archive_sparks_measure_reference_adoptions_for_organization. The component is already wired to MeasuresPerformanceWorkspace in administration mode. The governed adoption migration 20260909214455_govern_organization_measure_reference_adoption.sql exists. DO NOT create a parallel selector or schema.

## Messaging architecture decision

SKPE_E2E_EMAIL and SKPE_E2E_PASSWORD are credentials for automated login testing, not outgoing or incoming mail. Never place them in organization parameters. Plan separate platform/module/organization/project messaging configuration with protected backend secrets, sender identity verification, authorized recipients, audit and explicit handling of inbound replies. Email replies must never approve institutional decisions automatically.

## Implementation gates still open

1. Confirm navigation and role authorization for the existing adoption interface before enabling it. An unreachable administration mode must not be exposed without server-side authorization review.
2. Verify existing canonical schema and governance for organization-proposed indicators and promotion to transversal catalog. Do not invent SQL/migrations or mutate Supabase before specialist procedure and migration gates.
3. Verify existing corporate messaging/notification contracts before any new configuration form or secret storage.
4. Complete authenticated neutral organization end-to-end tests and monitoring/RAE lifecycle without changing COOTAQUARA.
5. Preserve the four untracked local maintenance scripts; do not deploy or promote main.

## Status

Decision recorded and existing assets located. C01 is DECIDED, not yet IMPLEMENTED/CLOSED. Messaging is APPROVED IN PRINCIPLE, not implemented. No production data, migration or credential changed.
