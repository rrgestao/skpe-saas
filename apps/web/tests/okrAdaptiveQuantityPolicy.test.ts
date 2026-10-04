import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005001000_adapt_okr_quantity_to_maturity.sql', import.meta.url),
  'utf8',
)

test('OKR quantity policy defaults to adaptive guardrails instead of 3-5', () => {
  assert.match(migration, /minimum_key_results_per_okr set default 1/)
  assert.match(migration, /maximum_key_results_per_okr set default 30/)
  assert.match(migration, /p_minimum_key_results_per_okr integer default 1/)
  assert.match(migration, /p_maximum_key_results_per_okr integer default 30/)
  assert.doesNotMatch(migration, /minimum_key_results_per_okr integer default 3/)
  assert.doesNotMatch(migration, /maximum_key_results_per_okr integer default 5/)
})

test('OKR readiness exposes maturity-driven quantity policy', () => {
  assert.match(migration, /adaptive_by_maturity_and_complexity/)
  assert.match(migration, /coalesce\(package_row\.minimum_key_results_per_okr, 1\)/)
  assert.match(migration, /coalesce\(package_row\.maximum_key_results_per_okr, 30\)/)
})

test('fixed quantity is not treated as methodology', () => {
  assert.match(migration, /technical capacity, not a recommended methodological target/)
  assert.match(migration, /calibrate by maturity and complexity/)
})
