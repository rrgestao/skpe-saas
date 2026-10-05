import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005010000_govern_evolution_scenario_conceptual_cycles.sql', import.meta.url),
  'utf8',
)

test('Evolution Scenario accepts conceptual cycles before dates are defined', () => {
  assert.match(migration, /alter column period_start drop not null/)
  assert.match(migration, /alter column period_end drop not null/)
  assert.match(migration, /deixe ambos em aberto enquanto o Ciclo estiver conceitual/)
  assert.match(migration, /conceptualCyclesMayPrecedeDates/)
})

test('Scenario readiness separates structure from temporalization', () => {
  assert.match(migration, /structurally_ready/)
  assert.match(migration, /temporalization_complete/)
  assert.match(migration, /ready_to_submit/)
  assert.match(migration, /ready_to_ratify/)
})

test('institutional approval still requires temporalized cycles', () => {
  assert.match(migration, /datesRequiredBeforeRatification/)
  assert.match(migration, /ready_to_ratify/)
  assert.match(migration, /ainda não pode ser ratificado/)
})
