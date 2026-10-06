import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const analytics = readFileSync(
  new URL('../src/modules/initiatives/analytics/StrategicObjectiveExecutiveAnalytics.tsx', import.meta.url),
  'utf8',
)
const cockpit = readFileSync(
  new URL('../src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx', import.meta.url),
  'utf8',
)

test('objective analytics preserves the governed traceability chain without synthetic health', () => {
  assert.match(analytics, /skpe_strategic_objectives/)
  assert.match(analytics, /skpe_indicators/)
  assert.match(analytics, /skpe_indicator_targets/)
  assert.match(analytics, /skpe_benchmark_references/)
  assert.match(analytics, /skpe_key_results/)
  assert.match(analytics, /skpe_initiative_key_results/)
  assert.match(analytics, /sparks_initiatives/)
  assert.match(analytics, /sparks_initiative_actions/)
  assert.match(analytics, /Esta leitura não cria nota de saúde/)
})

test('objective analytics distinguishes official target and benchmark lifecycle', () => {
  assert.match(analytics, /\['active', 'achieved', 'not_achieved'\]/)
  assert.match(analytics, /\['active', 'verified'\]/)
  assert.match(analytics, /Metas oficiais/)
  assert.match(analytics, /Benchmarks oficiais/)
})

test('objective cards drill down to canonical measures and initiatives work areas', () => {
  assert.match(analytics, /onOpenMeasures\(row\.id/)
  assert.match(analytics, /onOpenInitiatives\(row\.id/)
  assert.match(cockpit, /StrategicObjectiveExecutiveAnalytics/)
  assert.match(cockpit, /onOpenMeasures=\{onObjectivePerformanceDrilldown\}/)
  assert.match(cockpit, /onOpenInitiatives=\{onObjectiveInitiativesDrilldown\}/)
})
