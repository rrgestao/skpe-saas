import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const panel = readFileSync(
  join(testDir, '../src/modules/skpe/features/monitoring/MonitoringExecutionCheckInsPanel.tsx'),
  'utf8',
)
const section = readFileSync(
  join(testDir, '../src/modules/skpe/features/monitoring/MonitoringSection.tsx'),
  'utf8',
)

test('G4B reutiliza os contratos canônicos de check-in', () => {
  assert.match(panel, /record_skpe_key_result_check_in/)
  assert.match(panel, /record_skpe_initiative_check_in/)
  assert.match(panel, /transition_skpe_monitoring_record/)
})

test('G4B preserva confiança, evidência e validação humana do KR', () => {
  assert.match(panel, /confidenceLevel/)
  assert.match(panel, /evidenceReference/)
  assert.match(panel, /'key_result_check_in'/)
  assert.match(panel, /'validate'/)
  assert.match(panel, /'reject'/)
  assert.match(panel, /'resubmit'/)
})

test('G4B preserva risco, marcos, atrasos, decisão e evidência da Iniciativa', () => {
  assert.match(panel, /riskLevel/)
  assert.match(panel, /milestonesSummary/)
  assert.match(panel, /delaysText/)
  assert.match(panel, /decisionRequired/)
  assert.match(panel, /evidenceReference/)
  assert.match(panel, /'initiative_check_in'/)
})

test('G4B só é montado quando existe ciclo real', () => {
  assert.match(section, /MonitoringExecutionCheckInsPanel/)
  assert.match(section, /effectiveCycleId && formulationId/)
  assert.match(section, /cycleId={effectiveCycleId}/)
})
