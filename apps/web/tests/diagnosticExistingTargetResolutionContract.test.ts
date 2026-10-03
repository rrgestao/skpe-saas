import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003213000_reconcile_existing_diagnostic_targets.sql', import.meta.url),
  'utf8',
)

test('diagnostic resolver supports exact existing-entity lookup', () => {
  assert.match(migration, /'pestel_item'/)
  assert.match(migration, /'swot_item'/)
  assert.match(migration, /'tows_item'/)
  assert.match(migration, /'strategic_risk_item'/)
  assert.match(migration, /resolution_mode_if_found','existing_entity'/)
  assert.match(migration, /resolution_mode_if_missing','create_new_entity'/)
  assert.match(migration, /exact_code_same_project/)
})

test('diagnostic mappings are versioned instead of mutated in place', () => {
  assert.match(migration, /version_number,[\s\S]*2/)
  assert.match(migration, /supersedes_version_id/)
  assert.match(migration, /version_status='superseded'/)
  assert.match(migration, /current_version=2/)
  assert.match(migration, /allows_existing_entity=true/)
})

test('resolver remains review-first and inference-free', () => {
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /semantic_inference',false/)
  assert.doesNotMatch(migration, /skpe_execute_governed_import_materialization/)
})
