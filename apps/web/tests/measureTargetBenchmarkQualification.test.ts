import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const grid = readFileSync(
  new URL('../src/modules/measures/OrganizationIndicatorsSmartGrid.tsx', import.meta.url),
  'utf8',
)
const workspace = readFileSync(
  new URL('../src/modules/measures/MeasuresPerformanceWorkspace.tsx', import.meta.url),
  'utf8',
)
const migration = readFileSync(
  new URL('../../../supabase/migrations/20261006180500_qualify_measure_target_benchmark_context.sql', import.meta.url),
  'utf8',
)

test('context read model prefers governed target lifecycle without hiding draft fallback', () => {
  assert.match(migration, /candidate\.status in \('active', 'achieved', 'not_achieved'\) then 0/)
  assert.match(migration, /candidate\.status = 'draft' then 1/)
  assert.match(migration, /candidate\.status <> 'superseded'/)
})

test('context read model prefers active or verified benchmark over draft and archived', () => {
  assert.match(migration, /candidate\.status = 'active' then 0/)
  assert.match(migration, /candidate\.status = 'verified' then 1/)
  assert.match(migration, /candidate\.status = 'draft' then 2/)
  assert.match(migration, /candidate\.status = 'archived' then 3/)
})

test('indicator grid distinguishes selected references from official target and benchmark', () => {
  assert.match(grid, /Meta selecionada/)
  assert.match(grid, /Situação da meta/)
  assert.match(grid, /Meta oficial/)
  assert.match(grid, /Benchmark selecionado/)
  assert.match(grid, /Situação do benchmark/)
  assert.match(grid, /Benchmark oficial/)
  assert.match(grid, /Meta não oficial/)
  assert.match(grid, /Benchmark não oficial/)
})

test('workspace summary distinguishes registered references from official references', () => {
  assert.match(workspace, /Com meta registrada/)
  assert.match(workspace, /Metas oficiais/)
  assert.match(workspace, /Com benchmark registrado/)
  assert.match(workspace, /Benchmarks oficiais/)
  assert.match(workspace, /Presença não equivale a oficialidade/)
})
