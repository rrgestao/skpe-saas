import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004235900_govern_pem0205_objective_order.sql', import.meta.url),
  'utf8',
)

test('PEM-02.05 reordering preserves objective approval fields', () => {
  assert.match(migration, /reorder_skpe_strategic_objective_for_map/)
  assert.match(migration, /validationStatusPreserved/)
  assert.match(migration, /approvedAtPreserved/)
  assert.match(migration, /approvedByPreserved/)
  assert.doesNotMatch(migration, /validation_status='draft'/)
})

test('PEM-02.05 reordering is allowed only while the stage is current', () => {
  assert.match(migration, /code='PEM-02\.05'/)
  assert.match(migration, /status<>'in_progress'/)
  assert.match(migration, /not journey_row\.is_current/)
})

test('PEM-02.05 reordering is audited and denies anon execution', () => {
  assert.match(migration, /strategic_map_objective_reordered/)
  assert.match(migration, /revoke all on function/)
  assert.match(migration, /from public,anon/)
})
