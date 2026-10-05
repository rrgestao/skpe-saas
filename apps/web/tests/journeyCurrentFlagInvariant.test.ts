import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004231500_enforce_journey_current_flag_invariant.sql', import.meta.url),
  'utf8',
)

test('journey current flag is restricted to in-progress items', () => {
  assert.match(migration, /status <> 'in_progress' and new\.is_current/)
  assert.match(migration, /new\.is_current := false/)
  assert.match(migration, /skpe_journey_current_flag_guard/)
})

test('legacy normalization changes only the technical current flag', () => {
  assert.match(migration, /update public\.skpe_journey_items/)
  assert.match(migration, /is_current=false/)
  assert.match(migration, /status<>'in_progress'/)
  assert.doesNotMatch(migration, /status\s*=\s*'completed'/i)
  assert.doesNotMatch(migration, /progress\s*=/i)
  assert.doesNotMatch(migration, /validation_status\s*=/i)
})
