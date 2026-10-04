import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004073500_govern_pem03_gate.sql', import.meta.url),
  'utf8',
)
const panel = readFileSync(
  new URL('../src/modules/skpe/features/journey/Pem03GatePanel.tsx', import.meta.url),
  'utf8',
)
const journey = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)

test('PEM-03.GATE readiness aggregates all four deployment stages', () => {
  assert.match(migration, /get_skpe_pem03_gate_readiness/)
  assert.match(migration, /get_skpe_okr_deployment_readiness/)
  assert.match(migration, /get_skpe_indicators_readiness/)
  assert.match(migration, /get_skpe_initiatives_readiness/)
  assert.match(migration, /get_skpe_monitoring_package_readiness/)
  assert.match(migration, /readyForClosure/)
})

test('PEM-03.GATE ratification is explicit and append-only', () => {
  assert.match(migration, /ratify_skpe_pem03_gate/)
  assert.match(migration, /can_ratify_skpe_governance/)
  assert.match(migration, /insert into public\.skpe_gate_decisions/)
  assert.match(migration, /pem03_gate_closure/)
  assert.match(migration, /approved_with_reservations/)
  assert.match(migration, /returned_for_adjustment/)
})

test('PEM-03.GATE generic completion path is fail-closed', () => {
  assert.match(migration, /skpe_guard_pem03_gate_completion/)
  assert.match(migration, /PEM-03\.GATE concluído é imutável/)
  assert.match(migration, /exige decisão institucional de fechamento/)
  assert.match(migration, /readyForClosure/)
})

test('Journey exposes institutional PEM-03 Gate panel', () => {
  assert.match(panel, /get_skpe_pem03_gate_readiness/)
  assert.match(panel, /ratify_skpe_pem03_gate/)
  assert.match(panel, /Ratificação da Macrofase 3/)
  assert.match(panel, /PEM-03\.01 · OKRs/)
  assert.match(panel, /PEM-03\.02 · Indicadores e Metas/)
  assert.match(panel, /PEM-03\.03 · Iniciativas/)
  assert.match(panel, /PEM-03\.04 · Governança/)
  assert.match(panel, /Registrar decisão institucional/)
  assert.match(journey, /<Pem03GatePanel/)
})
