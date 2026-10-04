import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004035500_create_positioning_validation_events.sql', import.meta.url),
  'utf8',
)

test('PEM-02.03 validation ledger is append-only and non-mutating', () => {
  assert.match(migration, /skpe_positioning_validation_events/)
  assert.match(migration, /decision_action in \('keep','adjust','replace','remove'\)/)
  assert.match(migration, /canonical_mutation_applied',false/)
  assert.match(migration, /next_gate','PEM-02\.03_CONSOLIDATION'/)
  assert.doesNotMatch(migration, /update public\.skpe_strategic_themes/)
  assert.doesNotMatch(migration, /update public\.skpe_bsc_perspectives/)
})

test('PEM-02.03 validation requires human validation permission and audit', () => {
  assert.match(migration, /can_validate_skpe_formulation/)
  assert.match(migration, /auth\.uid\(\)/)
  assert.match(migration, /skpe_record_operational_audit/)
  assert.match(migration, /pem02\.03\.positioning_validation_recorded/)
  assert.match(migration, /grant execute on function public\.record_skpe_positioning_validation_decision[\s\S]*to authenticated/)
})

test('adjust or replace requires a proposal and every decision requires rationale', () => {
  assert.match(migration, /length\(trim\(coalesce\(decision_rationale,''\)\)\) < 10/)
  assert.match(migration, /normalized_action in \('adjust','replace'\)/)
  assert.match(migration, /Ajustar\/Substituir exige nome ou descrição proposta/)
})
