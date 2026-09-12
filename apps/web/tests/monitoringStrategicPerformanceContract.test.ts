import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const source = readFileSync(
  join(testDir, '../src/modules/skpe/features/monitoring/MonitoringSection.tsx'),
  'utf8',
)

test('monitoramento estratégico reutiliza contratos governados do runtime', () => {
  assert.match(source, /get_skpe_monitoring_package_readiness/)
  assert.match(source, /get_skpe_strategic_performance/)
  assert.match(source, /workspace\.route\.formulationId/)
  assert.match(source, /workspace\.route\.cycleId/)
})

test('painel não sintetiza desempenho sem pacote ou ciclo formal', () => {
  assert.match(source, /FE08_PACKAGE_MISSING/)
  assert.match(source, /não sintetiza desempenho sem um ciclo formal/)
  assert.doesNotMatch(source, /visionProgress:\s*0/)
  assert.doesNotMatch(source, /setStrategicPerformance\(\{[^}]*0/)
})
