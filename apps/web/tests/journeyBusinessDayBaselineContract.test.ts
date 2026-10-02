import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const root = join(testDir, '../../..')
const planner = readFileSync(
  join(testDir, '../src/modules/skpe/features/journey/JourneySchedulePlanner.tsx'),
  'utf8',
)
const cockpit = readFileSync(
  join(testDir, '../src/modules/skpe/SkpeCockpit.tsx'),
  'utf8',
)
const migration = readFileSync(
  join(root, 'supabase/migrations/20260916170000_govern_skpe_business_day_baseline_proposal.sql'),
  'utf8',
)

test('Jornada usa dias uteis na sugestao temporal', () => {
  assert.match(planner, /addBusinessDaysIso/)
  assert.match(planner, /businessDaysBetweenInclusive/)
  assert.match(planner, /90 dias úteis/)
  assert.match(planner, /45 dias úteis/)
})

test('Horizonte Estrategico permanece separado da janela da Jornada', () => {
  assert.match(migration, /journey_target_end_date := public\.skpe_business_day_at_offset\(current_date, 89\)/)
  assert.match(migration, /valid_until = make_date\(target_horizon_end_year, 12, 31\)/)
  assert.match(migration, /target_end_date = journey_target_end_date/)
  assert.doesNotMatch(
    migration,
    /target_end_date = make_date\(target_horizon_end_year, 12, 31\)/,
  )
})

test('Linha de Base nasce como proposta e exige aprovacao humana', () => {
  assert.match(migration, /'baseline'/)
  assert.match(migration, /'draft'/)
  assert.match(migration, /'Linha de Base Proposta da Jornada Estrategica'/)
  assert.match(migration, /is_current_plan,\s*metadata/)
  assert.match(migration, /false,\s*jsonb_build_object/)
  assert.match(migration, /baseline_proposal_version_id/)
})

test('Planejado ate hoje usa dias uteis no cockpit executivo', () => {
  assert.match(cockpit, /countBusinessDaysInclusive/)
  assert.match(cockpit, /elapsedBusinessDays/)
  assert.match(cockpit, /totalBusinessDays/)
})

test('Cadencia detalhada por PEM permanece explicitamente pendente', () => {
  assert.match(migration, /pending_methodological_allocation/)
  assert.match(migration, /pending_pem_duration_approval/)
  assert.match(migration, /provisional_equal_leaf_distribution/)
})

test('Cockpit distingue proposta temporal de plano aprovado', () => {
  const analytics = readFileSync(
    join(testDir, '../src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx'),
    'utf8',
  )
  assert.match(cockpit, /hasProposedPlan/)
  assert.match(cockpit, /planningStatus/)
  assert.match(analytics, /Proposto até hoje/)
  assert.match(analytics, /Planejado aprovado até hoje/)
})
