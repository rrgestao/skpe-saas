import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const cockpit = readFileSync(
  new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url),
  'utf8',
)

test('deep-linked diagnosis/formulation waits for strategic project context before access fallback', () => {
  assert.match(cockpit, /strategicProjectContextLoading/)
  assert.match(cockpit, /capabilitiesLoading \|\| strategicProjectContextLoading/)
  assert.match(cockpit, /loadStrategicProjectContext\(\)\.finally/)
  assert.match(cockpit, /canShowDiagnosis/)
  assert.match(cockpit, /canShowFormulation/)
})
