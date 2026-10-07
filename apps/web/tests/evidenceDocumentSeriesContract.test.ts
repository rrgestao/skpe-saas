import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const workspace = readFileSync(
  new URL('../src/modules/evidence/EvidenceManagementWorkspace.tsx', import.meta.url),
  'utf8',
)
const seriesMigration = readFileSync(
  new URL('../../../supabase/migrations/20261007195500_govern_evidence_document_series.sql', import.meta.url),
  'utf8',
)
const reuseMigration = readFileSync(
  new URL('../../../supabase/migrations/20261007201500_reuse_evidence_series_content.sql', import.meta.url),
  'utf8',
)

test('periodic evidence is modeled as series -> period document -> immutable versions', () => {
  assert.match(seriesMigration, /create table if not exists public\.sparks_evidence_series/)
  assert.match(seriesMigration, /create table if not exists public\.sparks_evidence_series_members/)
  assert.match(seriesMigration, /unique \(series_id, period_label\)/)
  assert.match(seriesMigration, /register_sparks_evidence_series_document/)
  assert.match(seriesMigration, /physical_version_count/)
  assert.match(seriesMigration, /created_period_document/)
  assert.match(seriesMigration, /created_period_version/)
})

test('duplicate physical content is reused rather than stored again', () => {
  assert.match(reuseMigration, /duplicate_content_reused/)
  assert.match(reuseMigration, /reused_existing_content/)
  assert.match(reuseMigration, /asset\.content_hash = target_content_hash/)
  assert.match(reuseMigration, /insert into public\.sparks_evidence_series_members/)
})

test('evidence maintenance supports governed multi-period upload', () => {
  assert.match(workspace, /Série documental/)
  assert.match(workspace, /Análise histórica por competência/)
  assert.match(workspace, /multiple/)
  assert.match(workspace, /inferDocumentYear/)
  assert.match(workspace, /register_sparks_evidence_series_document/)
  assert.match(workspace, /Exercícios diferentes não são versões entre si/)
  assert.match(workspace, /Há mais de um arquivo para a mesma competência/)
})

test('historical references without physical files are not presented as physical versions', () => {
  assert.match(workspace, /Versões físicas/)
  assert.match(workspace, /referência\(s\) histórica\(s\) sem arquivo físico/)
  assert.match(workspace, /não contam como PDFs ou versões físicas armazenadas/)
  assert.match(workspace, /Boolean\(version\.storage_bucket && version\.storage_path\)/)
})
