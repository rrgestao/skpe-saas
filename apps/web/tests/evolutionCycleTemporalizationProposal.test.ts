import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005013500_govern_proposed_cycle_temporalization.sql', import.meta.url),
  'utf8',
)

test('SPARKs can propose cycle dates without creating institutional approval', () => {
  assert.match(migration, /propose_skpe_evolution_cycle_temporalization/)
  assert.match(migration, /sparks_methodological_suggestion/)
  assert.match(migration, /proposed_for_validation/)
  assert.match(migration, /institutionalApprovalCreated',false/)
})

test('only non-approved scenarios may receive a date proposal', () => {
  assert.match(migration, /'draft','proposed','under_review','adjusted'/)
  assert.match(migration, /Somente Cenário ainda não aprovado/)
})

test('temporalization proposal is audited', () => {
  assert.match(migration, /evolution_cycle_temporalization_proposed/)
  assert.match(migration, /previous_data/)
  assert.match(migration, /new_data/)
})
