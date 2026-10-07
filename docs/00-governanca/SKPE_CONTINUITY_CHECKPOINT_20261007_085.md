# SK-PE — Continuity Checkpoint 085

Date: 2026-10-07
Project: SPARKs PE application
Mode: EXECUTOR / AUTHORIZED
Front: Evidence management UX, governed document series and private file preview
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261006_084.md

## Purpose

Close the evidence-management usability and modeling gaps found during live COOTAQUARA validation without changing institutional truth.

This checkpoint does not advance COOTAQUARA Journey stages.

## GRID and maintenance contract

The main Evidence GRID now follows the SPARKs Smart Grid interaction contract:

- single click selects;
- double click activates;
- Enter activates;
- primary action opens the same maintenance frame.

The maintenance frame centralizes:

- source/provenance reference;
- evidence-to-PEM-00 requirement association;
- file and current version;
- immutable physical-version history;
- governed new-version upload;
- series-document upload;
- embedded file preview.

## Source traceability

Short labels such as E05 — Mandioca are no longer the only recoverable identifier.

The UI consumes preserved provenance where available:

- source name;
- original sheet;
- source code;
- original key;
- date/period;
- responsible party;
- related risk;
- file name;
- version.

This improves source recovery without altering the evidence itself.

## Checklist / SK-DOC boundary

The product contract is now explicit:

- SK-DOC governs document identity, storage, provenance and version lifecycle;
- SK-PE governs strategic use, requirement linkage, sufficiency/quality interpretation and diagnosis/formulation consumption.

Evidence association to a PEM-00 operational requirement uses governed write paths and audit justification.

## Document-series model

Periodic documents are modeled as:

Document Series -> Period Document -> Immutable Versions

Example:

Balanço Patrimonial
- 2023 -> its own document and versions;
- 2024 -> its own document and versions;
- 2025 -> its own document and versions.

Different periods are never treated as versions of each other.

DEV now includes:

- public.sparks_evidence_series;
- public.sparks_evidence_series_members;
- public.register_sparks_evidence_series_document(...).

The registration operation:

- identifies the period explicitly;
- reuses already-existing physical content by SHA-256;
- avoids duplicate physical storage;
- creates a new period member for a different period;
- creates a new immutable version only for the same period when content changes.

## Historical-reference correction

Legacy references without storage are no longer presented as if they were physical files.

The maintenance frame distinguishes:

- Versões físicas;
- Referências históricas sem arquivo físico.

The COOTAQUARA Balanço 2025 audit confirmed:

- one legacy reference without storage/hash;
- one current physical PDF with storage/hash;
- no duplicate physical hash.

A broader COOTAQUARA hash audit found no duplicate physical content at this checkpoint.

## Embedded private file preview

A reusable EvidenceFilePreview component was added.

Supported v1 previews:

- PDF: embedded browser PDF rendering;
- PNG/JPG/JPEG/WebP/GIF/SVG/BMP: image preview;
- MD/TXT/CSV/JSON/XML/LOG/YAML/YML: text preview;
- XLSX/XLSM: sheet/cell preview, bounded for performance;
- DOCX: locally extracted textual content;
- PPTX: locally extracted slide text in slide order.

Unsupported legacy binary formats remain downloadable and are not falsely represented as renderable.

Privacy rule:

- preview downloads the private object through authenticated Supabase Storage;
- no public URL is created;
- no Office Online or Google Docs viewer is used;
- no private document is exported to an external preview service.

Current and previous physical versions can both be previewed.

## Validation

Focused evidence/document suite after final preview extension:

- 14/14 PASS;
- 0 failures.

Production build:

- PASS;
- 2247 modules transformed;
- existing large-chunk warning remains;
- JSZip/ExcelJS dynamic-import warning remains because those libraries are already statically imported elsewhere.

git diff --check:

- PASS;
- line-ending notices only.

Full application suite:

- one failure remains outside this evidence front:
  strategicPositioningValidationState.test.ts.
- the failure is associated with already-existing local Positioning Strategy changes and must be reconciled in that front rather than hidden in this checkpoint.

## DEV migration state

Applied only in DEV:

- govern_evidence_document_series;
- reuse_evidence_series_content.

No HOMOL or PRD deployment was performed.

## Institutional preservation

This checkpoint does not:

- approve or reject any COOTAQUARA strategic artifact;
- mark evidence sufficient automatically;
- treat linked evidence as validated automatically;
- fabricate historical financial values;
- advance Journey stages;
- deploy HOMOL;
- deploy PRD.

## Next direction

Proceed with V1-B02 + V1-B03:

- neutral full-Journey runtime validation;
- complete authenticated Monitoring / RAE cycle;
- no real-customer organization used as a test fixture;
- blocked transitions remain fail-closed;
- human approvals remain real human actions only.
