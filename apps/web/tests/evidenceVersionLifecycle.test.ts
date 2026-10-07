import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const workspace = readFileSync(
  new URL('../src/modules/evidence/EvidenceManagementWorkspace.tsx', import.meta.url),
  'utf8',
)
const migration = readFileSync(
  new URL('../../../supabase/migrations/20261006134848_govern_transversal_evidence_versions.sql', import.meta.url),
  'utf8',
)

test('evidence version lifecycle preserves immutable history and returns new content to validation', () => {
  assert.match(migration, /create or replace function public\.add_sparks_evidence_version/)
  assert.match(migration, /can_manage_sparks_evidence/)
  assert.match(migration, /max\(version\.version_number\).*\+ 1/s)
  assert.match(migration, /insert into public\.sparks_evidence_versions/)
  assert.match(migration, /current_version_id = new_version_id/)
  assert.match(migration, /validation_status = 'pending'/)
  assert.match(migration, /reliability_level = 'not_assessed'/)
  assert.match(migration, /human_validation_required/)
  assert.doesNotMatch(migration, /delete\s+from\s+public\.sparks_evidence_versions/i)
})

test('evidence workspace exposes version history, prior downloads and governed new-version upload', () => {
  assert.match(workspace, /Versões físicas/)
  assert.match(workspace, /referência\(s\) histórica\(s\) sem arquivo físico/)
  assert.match(workspace, /Registrar nova versão/)
  assert.match(workspace, /add_sparks_evidence_version/)
  assert.match(workspace, /selectedVersionHistory\.some\(\(version\) => version\.content_hash === contentHash\)/)
  assert.match(workspace, /downloadEvidenceVersion/)
  assert.match(workspace, /A versão anterior será preservada/)
  assert.match(workspace, /retornará para validação humana/)
  assert.match(workspace, /\.remove\(\[uploadedPath\]\)/)
})

test('version storage stays scoped to the canonical private evidence bucket', () => {
  assert.match(migration, /target_storage_bucket is distinct from 'sparks-evidence'/)
  assert.match(migration, /target_storage_path not like target_organization_id::text \|\| '\/%'/)
  assert.match(migration, /revoke all on function public\.add_sparks_evidence_version[\s\S]*?from public, anon/)
  assert.match(migration, /grant execute on function public\.add_sparks_evidence_version[\s\S]*?to authenticated, service_role/)
})
