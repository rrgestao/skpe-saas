import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const root = join(testDir, '../../..')
const migration = readFileSync(
  join(root, 'supabase/migrations/20260916190500_govern_skpe_performance_deviation_ranges.sql'),
  'utf8',
)
const cockpit = readFileSync(
  join(testDir, '../src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx'),
  'utf8',
)
const panel = readFileSync(
  join(testDir, '../src/modules/skpe/components/OrganizationParametersPanel.tsx'),
  'utf8',
)

test('SPARKs PE governa faixas default de desvio em percentual', () => {
  assert.match(migration, /SKPE\.PERFORMANCE\.DEVIATION\.ADEQUATE_MAX_PERCENT[\s\S]*'15'::jsonb/)
  assert.match(migration, /SKPE\.PERFORMANCE\.DEVIATION\.ATTENTION_MAX_PERCENT[\s\S]*'30'::jsonb/)
  assert.match(migration, /'percent'/)
})
test('card de desvio usa valor percentual, direcao e criticidade separadas', () => {
  assert.match(cockpit, /journeyVarianceBand/)
  assert.match(cockpit, /Math\.abs\(journeyVariance\)/)
  assert.match(cockpit, /journeyVariance\.toFixed\(0\)\}%/)
  assert.doesNotMatch(cockpit, /journeyVariance\.toFixed\(0\)\} p\.p\./)
  assert.match(cockpit, /is-negative/)
  assert.match(cockpit, /is-positive/)
  assert.match(cockpit, /title=\{journeyVarianceTooltip\}/)
})

test('card consulta parametros efetivos com escopo de organizacao e projeto', () => {
  assert.match(cockpit, /list_sparks_effective_parameters/)
  assert.match(cockpit, /p_organization_id: organizationId/)
  assert.match(cockpit, /p_project_id: projectId/)
})

test('Administracao permite adequar e restaurar as faixas de desempenho', () => {
  assert.match(panel, /SKPE\.PERFORMANCE\.DEVIATION\.ADEQUATE_MAX_PERCENT/)
  assert.match(panel, /SKPE\.PERFORMANCE\.DEVIATION\.ATTENTION_MAX_PERCENT/)
  assert.match(panel, /faixa adequada/i)
  assert.match(panel, /faixa de atenção/i)
  assert.match(panel, /Restaurar padrão SPARKs/)
})
