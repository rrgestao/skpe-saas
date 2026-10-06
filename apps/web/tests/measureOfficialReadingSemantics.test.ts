import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const historyPanel = readFileSync(
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
const migration = readFileSync(
  new URL('../../../supabase/migrations/20261006173500_harden_measure_official_history_semantics.sql', import.meta.url),
  'utf8',
)

test('official measure history counts only validated non-null observations', () => {
  assert.match(migration, /measurement\.status = 'validated'/)
  assert.match(migration, /measurement\.measured_value is not null/)
  assert.match(migration, /valid_observation_count/)
  assert.match(migration, /trend_eligible/)
})

test('history keeps operational observations visible but plots only validated official points', () => {
  assert.match(historyPanel, /row\.measurement_status === 'validated' && row\.measured_value != null/)
  assert.match(historyPanel, /Apurações pendentes ou rejeitadas continuam visíveis na tabela/)
  assert.match(historyPanel, /observações validadas/)
  assert.match(historyPanel, /measurementStatusLabel\(row\.measurement_status\)/)
})

test('measure grid distinguishes latest observation from official reading', () => {
  assert.match(grid, /Situação da apuração/)
  assert.match(grid, /Leitura oficial/)
  assert.match(grid, /Desempenho da última apuração/)
  assert.match(grid, /Desempenho oficial/)
  assert.match(grid, /measurement_status !== 'validated'/)
  assert.match(grid, /Sem leitura oficial/)
})

test('workspace exposes validated count and states the official-reading rule', () => {
  assert.match(workspace, /measurement_status: string \| null/)
  assert.match(workspace, /label: 'Validados'/)
  assert.match(workspace, /summaryFilter === 'validated'/)
  assert.match(workspace, /Somente estados governados compõem Meta oficial, Benchmark oficial e leitura oficial/)
})
