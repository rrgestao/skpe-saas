import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const workspace = readFileSync(
  join(testDir, '../src/modules/measures/MeasuresPerformanceWorkspace.tsx'),
  'utf8',
)
const grid = readFileSync(
  join(testDir, '../src/modules/measures/OrganizationIndicatorsSmartGrid.tsx'),
  'utf8',
)

test('G3 preserva responsabilidade, vínculo, evidência e interpretação no read model', () => {
  assert.match(workspace, /sparks_measure_indicators/)
  assert.match(workspace, /owner_user_id/)
  assert.match(grid, /Vínculo estratégico/)
  assert.match(grid, /Evidência/)
  assert.match(grid, /Interpretação/)
  assert.match(grid, /Override manual/)
  assert.match(grid, /Automática/)
})

test('G3 permanece read-only no enriquecimento contextual', () => {
  assert.equal(workspace.includes(".insert("), false)
  assert.equal(workspace.includes(".update("), false)
  assert.equal(workspace.includes(".delete("), false)
})
