import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004190000_govern_pem04_gate.sql', import.meta.url),
  'utf8',
)
const panel = readFileSync(
  new URL('../src/modules/skpe/features/journey/Pem04GatePanel.tsx', import.meta.url),
  'utf8',
)
const journey = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)

test('PEM-04.GATE readiness aggregates all four implementation stages', () => {
  assert.match(migration, /get_skpe_pem04_gate_readiness/)
  assert.match(migration, /get_skpe_pem0401_activation_readiness/)
  assert.match(migration, /get_skpe_pem0402_communication_readiness/)
  assert.match(migration, /get_skpe_pem0403_change_readiness/)
  assert.match(migration, /get_skpe_pem0404_implementation_risk_readiness/)
  assert.match(migration, /readyForClosure/)
})

test('PEM-04.GATE ratification is explicit and append-only', () => {
  assert.match(migration, /ratify_skpe_pem04_gate/)
  assert.match(migration, /can_ratify_skpe_governance/)
  assert.match(migration, /insert into public\.skpe_gate_decisions/)
  assert.match(migration, /pem04_gate_closure/)
  assert.match(migration, /approved_with_reservations/)
  assert.match(migration, /returned_for_adjustment/)
})

test('PEM-04.GATE generic completion path is fail-closed', () => {
  assert.match(migration, /skpe_guard_pem04_gate_completion/)
  assert.match(migration, /PEM-04\.GATE concluído é imutável/)
  assert.match(migration, /exige decisão institucional de fechamento/)
  assert.match(migration, /readyForClosure/)
})

test('Journey exposes institutional PEM-04 Gate panel', () => {
  assert.match(panel, /get_skpe_pem04_gate_readiness/)
  assert.match(panel, /ratify_skpe_pem04_gate/)
  assert.match(panel, /Ratificação da Macrofase 4/)
  assert.match(panel, /Ativação do Plano de Implementação/)
  assert.match(panel, /Comunicação e Mobilização/)
  assert.match(panel, /Capacidades e Gestão da Mudança/)
  assert.match(panel, /Riscos da Implementação/)
  assert.doesNotMatch(panel, /<small>PEM-04\.GATE<\/small>/)
  assert.match(panel, /Registrar decisão institucional/)
  assert.match(journey, /<Pem04GatePanel/)
})

