import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicFormulationSection.tsx', import.meta.url),
  'utf8',
)
const tabs = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicFormulationStatusTabs.tsx', import.meta.url),
  'utf8',
)

test('PEM-02.03 positioning is reachable from the formulation workflow', () => {
  assert.match(tabs, /\| 'positioning'/)
  assert.match(tabs, /label: 'Posicionamento Estratégico'/)
  assert.match(tabs, /themeCount/)
  assert.match(tabs, /perspectiveCount/)
  assert.match(section, /activeTab === 'positioning'/)
  assert.match(section, /<StrategicPositioningSection/)
})

test('positioning remains in progress when draft themes or perspectives exist', () => {
  assert.match(tabs, /snapshot\.themeCount > 0 \|\| snapshot\.perspectiveCount > 0/)
  assert.match(tabs, /\? 'in_progress'/)
})

test('current PEM-02.03 opens formulation on positioning', () => {
  const cockpit = readFileSync(
    new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url),
    'utf8',
  )
  assert.match(cockpit, /current_stage_code === 'PEM-02\.03'/)
  assert.match(cockpit, /\? 'positioning'/)
  assert.match(section, /initialTab = 'overview'/)
  assert.match(section, /setActiveTab\(initialTab\)/)
})
