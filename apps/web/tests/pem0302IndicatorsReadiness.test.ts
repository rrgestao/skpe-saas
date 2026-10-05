import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004064500_guard_pem0302_completion.sql', import.meta.url),
  'utf8',
)
const statusTabs = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicFormulationStatusTabs.tsx', import.meta.url),
  'utf8',
)
const indicators = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicIndicatorsReadinessSection.tsx', import.meta.url),
  'utf8',
)
const indicatorWorkspace = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicIndicatorWorkspace.tsx', import.meta.url),
  'utf8',
)
const cockpit = readFileSync(
  new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url),
  'utf8',
)

test('PEM-03.02 completion reuses canonical indicators readiness', () => {
  assert.match(migration, /get_skpe_indicators_readiness/)
  assert.match(migration, /readyForFormulation/)
  assert.match(migration, /skpe_pem0302_completion_guard/)
  assert.match(migration, /completionEvidence/)
  assert.doesNotMatch(migration, /update public\.skpe_indicators/i)
  assert.doesNotMatch(migration, /update public\.skpe_indicator_targets/i)
})

test('Indicators and Targets are a dedicated formulation stage with full proposal workflow', () => {
  assert.match(statusTabs, /\| 'indicators'/)
  assert.match(statusTabs, /label: 'Indicadores e Metas'/)
  assert.match(statusTabs, /skpe_indicator_packages/)
  assert.match(indicators, /Indicadores e Metas/)
  assert.match(indicators, /get_skpe_indicators_readiness/)
  assert.doesNotMatch(indicators, /<small>PEM-03\.02/)
  assert.match(indicatorWorkspace, /configure_skpe_indicator_package/)
  assert.match(indicatorWorkspace, /upsert_skpe_strategic_indicator/)
  assert.match(indicatorWorkspace, /upsert_skpe_indicator_target/)
  assert.match(indicatorWorkspace, /transition_skpe_indicator_package/)
  assert.match(indicatorWorkspace, /humanValidationRequired:true/)
})

test('current PEM-03 stage opens the correct formulation tab', () => {
  assert.match(cockpit, /current_stage_code === 'PEM-03\.01'[\s\S]*'performance'/)
  assert.match(cockpit, /current_stage_code === 'PEM-03\.02'[\s\S]*'indicators'/)
  assert.match(cockpit, /current_stage_code === 'PEM-03\.03'[\s\S]*'initiatives'/)
  assert.match(cockpit, /current_stage_code === 'PEM-03\.04'[\s\S]*'plan'/)
})

test('indicator UI preserves benchmark as recommendation rather than own evidence', () => {
  assert.match(indicators, /Benchmark permanece recomendação/)
  assert.match(indicators, /fonte,\s*formula|fonte,\s*fórmula/)
})
