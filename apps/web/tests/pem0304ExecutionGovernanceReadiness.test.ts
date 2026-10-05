import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004071500_guard_pem0304_completion.sql', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicExecutionGovernanceReadinessSection.tsx', import.meta.url),
  'utf8',
)
const workspace = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicExecutionGovernanceWorkspace.tsx', import.meta.url),
  'utf8',
)

test('PEM-03.04 completion reuses canonical monitoring package readiness', () => {
  assert.match(migration, /get_skpe_monitoring_package_readiness/)
  assert.match(migration, /readyForFormulation/)
  assert.match(migration, /skpe_pem0304_completion_guard/)
  assert.match(migration, /completionEvidence/)
  assert.doesNotMatch(migration, /update public\.skpe_monitoring_packages/i)
  assert.doesNotMatch(migration, /insert into public\.skpe_strategy_reviews/i)
})

test('execution governance UI exposes canonical FE-08 readiness and full configuration workflow', () => {
  assert.match(section, /Responsabilidades e Governança da Execução/)
  assert.match(section, /get_skpe_monitoring_package_readiness/)
  assert.match(section, /Cadência de monitoramento/)
  assert.match(section, /Cadência de revisão/)
  assert.match(section, /Responsável pelo monitoramento/)
  assert.match(section, /Responsável pela governança \/ RAE/)
  assert.match(section, /não cria responsáveis, fóruns ou decisões/)
  assert.doesNotMatch(section, /<p className="skpe-eyebrow">PEM-03\.04/)
  assert.match(workspace, /configure_skpe_monitoring_package/)
  assert.match(workspace, /transition_skpe_monitoring_package/)
  assert.match(workspace, /MonitoringPackageConfigurationPanel/)
  assert.match(workspace, /MonitoringPackageWorkflowPanel/)
})

test('execution governance UI separates blockers from recommendations', () => {
  assert.match(section, /Bloqueadores/)
  assert.match(section, /Recomendações/)
  assert.match(section, /readyForValidation/)
  assert.match(section, /readyForFormulation/)
})
