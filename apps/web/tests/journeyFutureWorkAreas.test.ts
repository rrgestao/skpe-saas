import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const journey = readFileSync(new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url), 'utf8')
const cockpit = readFileSync(new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url), 'utf8')
const formulation = readFileSync(new URL('../src/modules/skpe/features/strategy/StrategicFormulationSection.tsx', import.meta.url), 'utf8')
const monitoring = readFileSync(new URL('../src/modules/skpe/features/monitoring/MonitoringSection.tsx', import.meta.url), 'utf8')

test('opened future Journey phases expose their work area without unlocking blocked phases', () => {
  assert.match(journey, /Abrir área de trabalho/)
  assert.match(journey, /\^PEM-0\[345\]/)
  assert.match(journey, /\['in_progress', 'completed'\]/)
})

test('PEM-03 and PEM-04 stages route to the appropriate formulation workspace', () => {
  assert.match(cockpit, /code === 'PEM-03\.01'[\s\S]*?'performance'/)
  assert.match(cockpit, /code === 'PEM-03\.02'[\s\S]*?'indicators'/)
  assert.match(cockpit, /code === 'PEM-03\.03' \|\| code === 'PEM-04\.01'[\s\S]*?'initiatives'/)
  assert.match(cockpit, /skpe:formulation:target-tab/)
  assert.match(formulation, /sessionStorage\.getItem\('skpe:formulation:target-tab'\)/)
})

test('PEM-05 stages route to Monitoring and focus the requested readiness section', () => {
  assert.match(cockpit, /code\.startsWith\('PEM-05'\)/)
  assert.match(cockpit, /skpe:monitoring:target-stage/)
  for (const code of ['01','02','03','04']) {
    assert.match(monitoring, new RegExp('id="skpe-monitoring-pem-05-' + code + '"'))
  }
})
