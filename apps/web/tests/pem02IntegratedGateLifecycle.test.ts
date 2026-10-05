import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005011000_align_pem02_gate_ratification_lifecycle.sql', import.meta.url),
  'utf8',
)

test('PEM-02 Gate no longer requires Formulação and Plan to be preapproved', () => {
  assert.match(migration, /gateRatifiesFormulation/)
  assert.match(migration, /gateRatifiesEvolutionScenario/)
  assert.match(migration, /gateMaterializesEvolutionPlan/)
  assert.match(migration, /planMustNotBePreApproved/)
  assert.doesNotMatch(migration, /APPROVED_FORMULATION_MISSING/)
  assert.doesNotMatch(migration, /CURRENT_EVOLUTION_PLAN_MISSING/)
})

test('PEM-02 formulation readiness defers later-stage content', () => {
  assert.match(migration, /get_skpe_pem02_formulation_ratification_readiness/)
  assert.match(migration, /laterStageContentDoesNotBlockPem02Gate/)
  assert.match(migration, /KPIs dos Objetivos Estratégicos/)
  assert.match(migration, /OKRs e Resultados-Chave/)
})

test('Gate ratification institutionalizes scenario plan and formulation in one flow', () => {
  assert.match(migration, /decide_skpe_evolution_scenario/)
  assert.match(migration, /formulation_approved_by_pem02_gate/)
  assert.match(migration, /pem02GateRatification/)
  assert.match(migration, /ratify_skpe_pem02_gate_pre_integrated_lifecycle_20261005/)
})
