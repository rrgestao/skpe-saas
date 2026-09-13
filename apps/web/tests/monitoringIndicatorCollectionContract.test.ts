import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const panel = readFileSync(
  join(testDir, '../src/modules/skpe/features/monitoring/MonitoringIndicatorCollectionPanel.tsx'),
  'utf8',
)
const section = readFileSync(
  join(testDir, '../src/modules/skpe/features/monitoring/MonitoringSection.tsx'),
  'utf8',
)

test('G4A reutiliza o lifecycle governado do ciclo', () => {
  assert.match(panel, /get_skpe_monitoring_readiness/)
  assert.match(panel, /transition_skpe_monitoring_cycle/)
  assert.match(panel, /start_collection/)
  assert.match(panel, /submit_review/)
})

test('G4A registra medição e preserva validação humana separada', () => {
  assert.match(panel, /record_skpe_indicator_measurement/)
  assert.match(panel, /transition_skpe_monitoring_record/)
  assert.match(panel, /'indicator_measurement'/)
  assert.match(panel, /'validate'/)
  assert.match(panel, /'reject'/)
  assert.match(panel, /'resubmit'/)
})

test('G4A só submete o ciclo quando readiness autoriza', () => {
  assert.match(panel, /readyForReview/)
  assert.match(panel, /reviewBlockingIssues/)
  assert.match(panel, /can_manage_skpe_monitoring/)
  assert.match(panel, /can_manage_skpe_governance/)
})

test('Monitoramento só monta a coleta quando existe ciclo real', () => {
  assert.match(section, /MonitoringIndicatorCollectionPanel/)
  assert.match(section, /effectiveCycleId && formulationId/)
  assert.match(section, /cycleId={effectiveCycleId}/)
})
