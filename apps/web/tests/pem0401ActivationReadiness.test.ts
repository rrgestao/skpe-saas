import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004162500_govern_pem0401_activation_readiness.sql', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicImplementationActivationReadinessSection.tsx', import.meta.url),
  'utf8',
)
const cockpit = readFileSync(
  new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url),
  'utf8',
)

test('PEM-04.01 activation reuses the validated PEM-03.03 portfolio', () => {
  assert.match(migration, /get_skpe_initiatives_readiness/)
  assert.match(migration, /PEM0401_PORTFOLIO_NOT_VALIDATED/)
  assert.match(migration, /reusesPem0303Portfolio',true/)
  assert.match(migration, /reprioritizesPortfolio',false/)
  assert.match(migration, /startsExecutionAutomatically',false/)
})

test('PEM-04.01 requires executable actions without starting them', () => {
  assert.match(migration, /PEM0401_ACTION_PLAN_MISSING/)
  assert.match(migration, /PEM0401_ACTION_NOT_ACTIVATION_READY/)
  assert.match(migration, /validation_status<>'validated'/)
  assert.match(migration, /responsible_user_id is null/)
  assert.match(migration, /action\.start_date is null/)
  assert.match(migration, /action\.due_date is null/)
  assert.match(migration, /PEM0401_EXECUTION_ALREADY_STARTED/)
})

test('PEM-04.01 completion is fail-closed and records readiness evidence', () => {
  assert.match(migration, /skpe_guard_pem0401_completion/)
  assert.match(migration, /readyForCompletion/)
  assert.match(migration, /completionEvidence/)
  assert.match(migration, /executionStartedAutomatically',false/)
  assert.doesNotMatch(migration, /update public\.skpe_initiatives/i)
  assert.doesNotMatch(migration, /update public\.skpe_initiative_actions/i)
})

test('PEM-04.01 UI exposes activation readiness and opens initiatives workspace', () => {
  assert.match(section, /Ativação do Plano de Implementação/)
  assert.match(section, /get_skpe_pem0401_activation_readiness/)
  assert.match(section, /não redesenha nem reprioriza/)
  assert.match(section, /Nenhuma execução é iniciada automaticamente/)
  assert.match(section, /Bloqueadores de ativação/)
  assert.match(cockpit, /current_stage_code === 'PEM-04\.01'[\s\S]*'initiatives'/)
})
