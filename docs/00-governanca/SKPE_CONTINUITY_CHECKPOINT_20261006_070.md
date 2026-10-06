# SK-PE — Continuity Checkpoint 070

Date: 2026-10-06
Project: SPARKs PE application
Mode: EXECUTOR / AUTHORIZED
Front: Official SPARKOOP Login policy reference
Previous authority: SKPE_CONTINUITY_CHECKPOINT_20261005_069.md

## User directive

Before continuing the remaining application-development Journey, replace the non-canonical Login privacy-policy copy with the official SPARKOOP document supplied by the user and present its document-control information elegantly rather than reproducing the internal management-system header as the primary user interface.

## Source authority

Official attachment supplied by the user:

`SPARKOOP - Política de Segurança Cibernética e da Informação.pdf`

Document identity read from the official file:

- title: Política de Segurança Cibernética e da Informação;
- code: POL-001;
- revision: 00;
- unit: Governança;
- date: 08/01/2025;
- elaborator: Ricardo Rodrigues;
- approver: Robson Silva;
- homologator: Conselho de Administração.

Important semantic clarification:

The supplied official document is a Cybersecurity and Information Security Policy, not a Privacy/LGPD Policy. The application therefore must not relabel it as Política de Privacidade.

## Login correction

The Login legal reference now displays the official title:

`Política de Segurança Cibernética e da Informação`

The previous custom copy `Política de Privacidade da Plataforma SPARKs` was removed from Login.

The account-request acknowledgement now says:

`Li e estou ciente da Política de Segurança Cibernética e da Informação da SPARKOOP.`

It no longer fabricates privacy consent for a document that is not a privacy notice.

## Presentation decision

The official policy is presented in full substantive form inside the application.

The internal document-management header and revision table are not reproduced as the visual primary header. Instead:

- a compact official-document metadata block shows code, revision, date and unit;
- the policy sections are presented as readable application content;
- elaborator, approver, homologator and revision history are retained under an expandable `Controle documental` section.

This preserves fidelity to the official source while separating document-control metadata from the user-facing reading experience.

## Official substantive content represented

The Login policy viewer includes:

1. Objetivo;
2. Abrangência;
3. Documentos complementares;
4. Responsabilidades;
5. Procedimento 5.1 through 5.5;
6. Indicadores de desempenho;
7. Anexos;
8. Registros;
9. Controle documental/revision metadata.

## Account-request governance

Added DEV support for explicit acknowledgement of the official policy:

- acknowledged_policy_code;
- acknowledged_policy_revision;
- acknowledged_policy_effective_date;
- acknowledged_policy_version;
- policy_acknowledged_at.

New RPC:

`submit_platform_account_request_v2`

Frontend submits:

- POL-001;
- revision 00;
- effective/document date 2025-01-08;
- version identifier POL-001-R00-2025-01-08.

Legacy privacy_* fields remain populated only for backward compatibility with the existing table contract.

## DEV migrations

Applied in Supabase DEV:

- 20261006012000_govern_login_official_policy_acknowledgement.sql;
- 20261006012200_govern_login_official_policy_acknowledgement_v2.sql.

The second migration is the idempotent applied correction recorded in the DEV migration ledger.

## Runtime smoke

A transactional rollback smoke test confirmed that `submit_platform_account_request_v2` stores:

- acknowledged_policy_code = POL-001;
- acknowledged_policy_revision = 00;
- acknowledged_policy_effective_date = 2025-01-08;
- acknowledged_policy_version = POL-001-R00-2025-01-08;
- policy_acknowledged_at populated.

No test account request was persisted because the transaction was rolled back.

## Tests

`officialSecurityPolicyLogin.test.ts`

Result:

3/3 PASS

Coverage verifies:

- official SPARKOOP policy title and metadata;
- substantive policy sections;
- elegant document-control presentation;
- acknowledgement rather than false privacy consent;
- removal of the prior synthetic Privacy Policy copy;
- use of the governed v2 account-request RPC.

## Application-development continuity

This change is cross-cutting Login/application governance and does not alter COOTAQUARA Journey state.

After this checkpoint, continue the application-completion Journey from checkpoint 069/068 priorities without fabricating COOTAQUARA approvals.