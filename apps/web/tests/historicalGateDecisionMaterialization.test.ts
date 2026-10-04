import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004024500_reconcile_historical_gate_decision_materialization.sql', import.meta.url),
  'utf8',
)

test('historical gate decision materialization anchors on PEM-02.GATE and preserves date-only history', () => {
  assert.match(migration, /j\.code='PEM-02\.GATE'/)
  assert.match(migration, /decision_origin_type/)
  assert.match(migration, /'imported_historical'/)
  assert.match(migration, /'date_only'/)
  assert.match(migration, /source_decision_date/)
  assert.match(migration, /DEC-02\.03/)
  assert.match(migration, /DEC-02\.04/)
})

test('historical gate decision materialization is idempotent and does not reinterpret business approval', () => {
  assert.match(migration, /source_import_record_id/)
  assert.match(migration, /source_decision_code/)
  assert.match(migration, /business_decision_repeated',false/)
  assert.match(migration, /historical_business_approval_preserved',true/)
  assert.match(migration, /semantic_inference',false/)
  assert.match(migration, /already_finalized/)
})
