import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005033500_require_all_opened_journey_artifacts.sql', import.meta.url),
  'utf8',
)

test('PEM-03 through PEM-05 phases declare concrete artifact requirements', () => {
  for (const code of [
    'PEM-03.01','PEM-03.02','PEM-03.03','PEM-03.04',
    'PEM-04.01','PEM-04.02','PEM-04.03','PEM-04.04',
    'PEM-05.01','PEM-05.02','PEM-05.03','PEM-05.04',
  ]) {
    assert.match(migration, new RegExp(code.replace('.', '\\.')))
  }
})

test('requirement-driven materialization falls back safely when no explicit requirement exists', () => {
  assert.match(migration, /if v_match_count=0 then/)
  assert.match(migration, /configuredRequirementCount/)
  assert.match(migration, /proposalOnly/)
  assert.match(migration, /humanValidationRequired/)
})

test('configured artifacts remain proposals and never close Journey items', () => {
  assert.match(migration, /autoMaterializeOnOpen/)
  assert.match(migration, /proposalOnly/)
  assert.doesNotMatch(migration, /set\s+status\s*=\s*'completed'/i)
})
