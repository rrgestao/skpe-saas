import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const triggerMigration = readFileSync(
  new URL('../../../supabase/migrations/20261007213000_fix_journey_nested_unblock_dependencies.sql', import.meta.url),
  'utf8',
)
const recalculationMigration = readFileSync(
  new URL('../../../supabase/migrations/20261007214500_fix_journey_nested_dependency_recalculation.sql', import.meta.url),
  'utf8',
)
const journeySection = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)
const journeyContract = readFileSync(
  new URL('../src/modules/skpe/contracts/journey.ts', import.meta.url),
  'utf8',
)

test('journey transition guard supports legacy and cloned template dependency metadata', () => {
  assert.match(triggerMigration, /metadata -> 'unblock_dependencies'/)
  assert.match(triggerMigration, /metadata -> 'template_metadata' -> 'unblock_dependencies'/)
  assert.match(triggerMigration, /coalesce/)
  assert.match(triggerMigration, /jsonb_array_elements\(dependencies\)/)
})

test('journey hierarchical recalculation supports nested cloned dependencies', () => {
  assert.match(recalculationMigration, /jsonb_typeof\(coalesce\(/)
  assert.match(recalculationMigration, /metadata->'template_metadata'->'unblock_dependencies'/)
  assert.match(recalculationMigration, /jsonb_array_elements\(coalesce\(/)
  assert.match(recalculationMigration, /Dependencia metodologica ainda nao atendida/)
})

test('journey UI resolves direct and template metadata dependencies consistently', () => {
  assert.match(journeyContract, /template_metadata\?:/)
  assert.match(journeyContract, /unblock_dependencies\?: Array/)
  assert.match(journeySection, /item\.metadata\?\.unblock_dependencies/)
  assert.match(journeySection, /item\.metadata\?\.template_metadata\?\.unblock_dependencies/)
  assert.match(journeySection, /methodologyLocked = unmetDependencies\.length > 0/)
})
