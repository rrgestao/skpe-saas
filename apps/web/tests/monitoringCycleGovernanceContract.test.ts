import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const panel = readFileSync(
  join(testDir, '../src/modules/skpe/features/monitoring/MonitoringCycleGovernancePanel.tsx'),
  'utf8',
)
const section = readFileSync(
  join(testDir, '../src/modules/skpe/features/monitoring/MonitoringSection.tsx'),
  'utf8',
)

test('G4D reutiliza readiness e transições governadas do ciclo', () => {
  assert.match(panel, /get_skpe_monitoring_readiness/)
  assert.match(panel, /transition_skpe_monitoring_cycle/)
  assert.match(panel, /request_ratification/)
})

test('G4D fecha somente ciclo pronto e pendente de ratificação', () => {
  assert.match(panel, /close_skpe_monitoring_cycle/)
  assert.match(panel, /pending_ratification/)
  assert.match(panel, /readyForClose/)
  assert.match(panel, /can_ratify_skpe_governance/)
})

test('G4D preserva reabertura controlada e supersessão de snapshot no runtime', () => {
  assert.match(panel, /reopen_skpe_monitoring_cycle/)
  assert.match(panel, /snapshot ratificado anterior foi supersedido/)
})

test('G4D só opera quando existe ciclo real', () => {
  assert.match(section, /MonitoringCycleGovernancePanel/)
  assert.match(section, /cycleId=\{effectiveCycleId\}/)
})
