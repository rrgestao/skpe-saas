import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004223000_govern_pem05_gate.sql', import.meta.url),
  'utf8',
)
const panel = readFileSync(
  new URL('../src/modules/skpe/features/journey/Pem05GatePanel.tsx', import.meta.url),
  'utf8',
)
const journey = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)

test('PEM-05.GATE aggregates all four monitoring and learning stages', () => {
  assert.match(migration, /get_skpe_pem0501_monitoring_operation_readiness/)
  assert.match(migration, /get_skpe_pem0502_critical_review_readiness/)
  assert.match(migration, /get_skpe_pem0503_learning_readiness/)
  assert.match(migration, /get_skpe_pem0504_strategy_update_readiness/)
  assert.match(migration, /readyForClosure/)
})

test('PEM-05.GATE ratification is explicit and append-only', () => {
  assert.match(migration, /ratify_skpe_pem05_gate/)
  assert.match(migration, /can_ratify_skpe_governance/)
  assert.match(migration, /insert into public\.skpe_gate_decisions/)
  assert.match(migration, /pem05_gate_closure/)
  assert.match(migration, /approved_with_reservations/)
  assert.match(migration, /returned_for_adjustment/)
})

test('PEM-05.GATE generic completion is fail-closed', () => {
  assert.match(migration, /skpe_guard_pem05_gate_completion/)
  assert.match(migration, /PEM-05\.GATE concluído é imutável/)
  assert.match(migration, /exige decisão institucional de fechamento/)
  assert.match(migration, /readyForClosure/)
})

test('Journey exposes institutional PEM-05 Gate panel', () => {
  assert.match(panel, /get_skpe_pem05_gate_readiness/)
  assert.match(panel, /ratify_skpe_pem05_gate/)
  assert.match(panel, /Ratificação da Macrofase 5/)
  assert.match(panel, /Operação da Rotina de Monitoramento/)
  assert.match(panel, /Análise Crítica de Desempenho/)
  assert.match(panel, /Aprendizado e Melhoria/)
  assert.match(panel, /Atualização Estratégica Governada/)
  assert.doesNotMatch(panel, /<small>PEM-05\.GATE<\/small>/)
  assert.match(panel, /Registrar decisão institucional/)
  assert.match(journey, /<Pem05GatePanel/)
})
