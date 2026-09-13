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

test('G2B resolve responsáveis por identidade autenticável e salva somente configuração', () => {
  assert.match(source, /get_skpe_governance_people/)
  assert.match(source, /sparks_people/)
  assert.match(source, /profile_user_id/)
  assert.match(source, /configure_skpe_monitoring_package/)
  assert.match(source, /Configuração FE-08 salva em elaboração/)
  assert.doesNotMatch(source, /open_skpe_monitoring_cycle/)
  assert.doesNotMatch(source, /transition_skpe_monitoring_package/)
})
