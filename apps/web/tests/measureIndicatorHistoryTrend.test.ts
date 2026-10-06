import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const panel = readFileSync(
  new URL('../src/modules/measures/MeasureIndicatorHistoryPanel.tsx', import.meta.url),
  'utf8',
)
const workspace = readFileSync(
  new URL('../src/modules/measures/MeasuresPerformanceWorkspace.tsx', import.meta.url),
  'utf8',
)
const grid = readFileSync(
  new URL('../src/modules/measures/OrganizationIndicatorsSmartGrid.tsx', import.meta.url),
  'utf8',
)

test('indicator history consumes the canonical history read model and its eligibility rule', () => {
  assert.match(panel, /get_sparks_measure_indicator_history/)
  assert.match(panel, /target_limit: 24/)
  assert.match(panel, /trend_eligible/)
  assert.match(panel, /officialChronological\.length >= 3/)
  assert.match(panel, /Histórico insuficiente para tendência governada/)
})

test('trend chart remains descriptive and never turns missing measurements into zero', () => {
  assert.match(panel, /measurement_status === 'validated' && row\.measured_value != null/)
  assert.match(panel, /ausência de dado não vira zero/i)
  assert.match(panel, /não classifica melhora ou piora automaticamente/)
  assert.match(panel, /Nenhuma apuração governada registrada/)
})

test('read-only indicators open governed history by double click', () => {
  assert.match(workspace, /onOpenHistory=\{setHistoryIndicatorId\}/)
  assert.match(workspace, /MeasureIndicatorHistoryPanel/)
  assert.match(workspace, /Dê duplo clique em um indicador/)
  assert.match(grid, /if \(readOnly\) onOpenHistory\?\.\(id\)/)
})
