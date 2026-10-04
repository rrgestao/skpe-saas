import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004055000_guard_pem0205_completion.sql', import.meta.url),
  'utf8',
)

test('PEM-02.05 completion requires validated map and matching official version', () => {
  assert.match(migration, /new\.code <> 'PEM-02\.05'/)
  assert.match(migration, /package_row\.status <> 'validated'/)
  assert.match(migration, /get_skpe_strategic_map_readiness/)
  assert.match(migration, /readyForFormulation/)
  assert.match(migration, /skpe_strategic_map_versions/)
  assert.match(migration, /source_validated_at is distinct from package_row\.validated_at/)
})

test('PEM-02.05 completion records immutable map evidence in journey metadata', () => {
  assert.match(migration, /completionEvidence/)
  assert.match(migration, /strategicMapPackageId/)
  assert.match(migration, /strategicMapVersionId/)
  assert.match(migration, /strategicMapVersionNumber/)
  assert.match(migration, /mapValidatedAt/)
})
