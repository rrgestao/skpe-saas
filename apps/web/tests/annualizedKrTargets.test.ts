import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const model = readFileSync(
  new URL('../../../supabase/migrations/20261005150000_govern_annualized_key_result_targets.sql', import.meta.url),
  'utf8',
)
const integration = readFileSync(
  new URL('../../../supabase/migrations/20261005151500_integrate_annualized_kr_targets_with_readiness.sql', import.meta.url),
  'utf8',
)
const workspace = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicKrAnnualTargetsWorkspace.tsx', import.meta.url),
  'utf8',
)
const okrWorkspace = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicOkrWorkspace.tsx', import.meta.url),
  'utf8',
)

test('annual KR targets have a canonical year-by-year model distinct from Evolution Cycles', () => {
  assert.match(model, /skpe_key_result_annual_targets/)
  assert.match(model, /target_year integer not null/)
  assert.match(model, /transition','baseline_confirmation','annual/)
  assert.match(model, /annualTargetsAreEvolutionCycles',false/)
  assert.match(model, /year2026Treatment/)
})

test('annual target CRUD is proposal-only and requires human validation', () => {
  assert.match(model, /upsert_skpe_key_result_annual_target/)
  assert.match(model, /proposalOnly',true/)
  assert.match(model, /humanValidationRequired',true/)
  assert.doesNotMatch(model, /validation_status='validated'/)
})

test('readiness requires full-year annual trajectory while allowing 2026 transition treatment', () => {
  assert.match(model, /expected_full_year_start:=case when start_year=2026 then 2027 else start_year end/)
  assert.match(model, /KR_ANNUAL_TARGET_TRAJECTORY_INCOMPLETE/)
  assert.match(model, /transition_or_baseline_confirmation/)
})

test('OKR package and PEM-03.01 readiness include annual target trajectory', () => {
  assert.match(integration, /get_skpe_okrs_readiness_pre_annual_targets_20261005/)
  assert.match(integration, /get_skpe_okr_deployment_readiness_pre_annual_targets_20261005/)
  assert.match(integration, /annualTargetReadiness/)
  assert.match(integration, /annualTargetTrajectoryRequired',true/)
})

test('package validation synchronizes annual-target validation without creating separate approval', () => {
  assert.match(integration, /skpe_sync_annual_kr_target_validation_from_package/)
  assert.match(integration, /when 'pending_validation' then 'pending_validation'/)
  assert.match(integration, /when 'validated' then 'validated'/)
})

test('OKR workspace exposes annual target editor with the 2026 transition explanation', () => {
  assert.match(okrWorkspace, /StrategicKrAnnualTargetsWorkspace/)
  assert.match(workspace, /Metas anualizadas/)
  assert.match(workspace, /não são os três Ciclos de Evolução/)
  assert.match(workspace, /2027 é o primeiro exercício anual completo/)
  assert.match(workspace, /upsert_skpe_key_result_annual_target/)
})