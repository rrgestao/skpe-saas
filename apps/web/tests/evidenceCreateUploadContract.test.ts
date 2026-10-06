import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const workspace = readFileSync(
  new URL('../src/modules/evidence/EvidenceManagementWorkspace.tsx', import.meta.url),
  'utf8',
)
const migration = readFileSync(
  new URL('../../../supabase/migrations/20261006120500_create_transversal_evidence_storage.sql', import.meta.url),
  'utf8',
)

test('transversal evidence storage is private and governed by canonical evidence authorization', () => {
  assert.match(migration, /'sparks-evidence'/)
  assert.match(migration, /false,[\s\S]*?52428800/)
  assert.match(migration, /can_view_sparks_evidence/)
  assert.match(migration, /can_manage_sparks_evidence/)
  assert.match(migration, /for insert[\s\S]*?for update[\s\S]*?for delete/i)
})

test('evidence workspace registers and links evidence without duplicating SK-DOC authority', () => {
  assert.match(workspace, /Registrar evidência/)
  assert.match(workspace, /crypto\.subtle\.digest\('SHA-256'/)
  assert.match(workspace, /sparks_evidence_assets/)
  assert.match(workspace, /content_hash/)
  assert.match(workspace, /\.from\('sparks-evidence'\)[\s\S]*?\.upload/)
  assert.match(workspace, /register_sparks_evidence_asset/)
  assert.match(workspace, /link_sparks_evidence/)
  assert.match(workspace, /target_type: 'strategic_project'/)
  assert.match(workspace, /SK-DOC governa documentos, evidências e versões/)
})

test('failed registration cleans uploaded object and duplicate hash reuses canonical evidence', () => {
  assert.match(workspace, /assetId = existingEvidence\?\.id \?\? null/)
  assert.match(workspace, /if \(!assetId\)[\s\S]*?\.upload/)
  assert.match(workspace, /if \(uploadedPath\)[\s\S]*?\.remove\(\[uploadedPath\]\)/)
})
