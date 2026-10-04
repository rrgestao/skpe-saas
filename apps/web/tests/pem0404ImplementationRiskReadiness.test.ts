import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004183000_govern_pem0404_implementation_risks.sql', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicImplementationRiskReadinessSection.tsx', import.meta.url),
  'utf8',
)
const cockpit = readFileSync(
  new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url),
  'utf8',
)

test('PEM-04.04 composes existing initiative and strategic risk authorities', () => {
  assert.match(migration, /skpe_initiative_risks/)
  assert.match(migration, /skpe_strategic_risk_mitigation_readiness/)
  assert.match(migration, /duplicatesRisk',false/)
  assert.match(migration, /automaticRiskAcceptance',false/)
  assert.match(migration, /automaticMitigationCreation',false/)
})

test('PEM-04.04 requires treatment for high initiative risks', () => {
  assert.match(migration, /PEM0404_HIGH_INITIATIVE_RISK_UNMANAGED/)
  assert.match(migration, /owner_user_id is null/)
  assert.match(migration, /response_type is null/)
  assert.match(migration, /response_due_date is null/)
  assert.match(migration, /validation_status<>'validated'/)
  assert.match(migration, /PEM0404_ACCEPTED_RISK_WITHOUT_REASON/)
})

test('PEM-04.04 requires strategic risk mitigation readiness', () => {
  assert.match(migration, /PEM0404_STRATEGIC_RISK_MITIGATION_NOT_READY/)
  assert.match(migration, /mitigation_required/)
  assert.match(migration, /readiness_status<>'ready'/)
  assert.match(migration, /skpe_guard_pem0404_completion/)
})

test('PEM-04.04 UI exposes risk readiness and does not duplicate risks', () => {
  assert.match(section, /PEM-04\.04 · Gestão de Riscos da Implementação/)
  assert.match(section, /get_skpe_pem0404_implementation_risk_readiness/)
  assert.match(section, /não recria riscos/)
  assert.match(section, /Nenhum risco é criado, aceito ou mitigado automaticamente/)
  assert.match(section, /Bloqueadores/)
  assert.match(cockpit, /current_stage_code === 'PEM-04\.04'[\s\S]*'plan'/)
})
