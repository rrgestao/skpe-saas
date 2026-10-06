import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004201000_govern_pem0501_monitoring_operation.sql', import.meta.url),
  'utf8',
)
const panel = readFileSync(
  new URL('../src/modules/skpe/features/monitoring/MonitoringOperationReadinessPanel.tsx', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/monitoring/MonitoringSection.tsx', import.meta.url),
  'utf8',
)

test('PEM-05.01 reuses validated FE-08 and cycle readiness', () => {
  assert.match(migration, /get_skpe_monitoring_package_readiness/)
  assert.match(migration, /get_skpe_monitoring_readiness/)
  assert.match(migration, /PEM0501_FE08_NOT_READY/)
  assert.match(migration, /PEM0501_OPERATED_CYCLE_MISSING/)
  assert.match(migration, /readyForReview/)
})

test('PEM-05.01 requires actual operational data and required evidence', () => {
  assert.match(migration, /PEM0501_OPERATIONAL_DATA_MISSING/)
  assert.match(migration, /PEM0501_REQUIRED_EVIDENCE_MISSING/)
  assert.match(migration, /skpe_indicator_measurements/)
  assert.match(migration, /skpe_key_result_check_ins/)
  assert.match(migration, /skpe_initiative_check_ins/)
  assert.match(migration, /skpe_initiative_outcome_measurements/)
})

test('PEM-05.01 completion is fail-closed without changing cycle state', () => {
  assert.match(migration, /skpe_guard_pem0501_completion/)
  assert.match(migration, /readyForCompletion/)
  assert.match(migration, /cycleOpenedAutomatically',false/)
  assert.match(migration, /performanceFabricated',false/)
  assert.doesNotMatch(migration, /update public\.skpe_monitoring_cycles/i)
  assert.doesNotMatch(migration, /insert into public\.skpe_indicator_measurements/i)
})

test('monitoring UI exposes PEM-05.01 operation readiness', () => {
  assert.match(panel, /Operação da Rotina de Monitoramento/)
  assert.match(panel, /get_skpe_pem0501_monitoring_operation_readiness/)
  assert.match(panel, /Não abre, submete, ratifica ou fecha ciclos automaticamente/)
  assert.match(panel, /Registros operacionais/)
  assert.match(panel, /Evidências obrigatórias ausentes/)
  assert.match(section, /<MonitoringOperationReadinessPanel/)
})
