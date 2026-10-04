import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004182500_govern_pem0404_implementation_risks.sql', import.meta.url),
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

test('PEM-04.04 reuses strategic and initiative risk authorities', () => {
  assert.match(migration, /skpe_strategic_risk_mitigation_readiness/)
  assert.match(migration, /skpe_initiative_risks/)
  assert.match(migration, /strategicRiskAuthority','skpe_strategic_risk_items'/)
  assert.match(migration, /strategicMitigationAuthority','skpe_strategic_risk_mitigation_links'/)
  assert.match(migration, /duplicatesRisk',false/)
})

test('PEM-04.04 requires governed mitigation for strategic and high initiative risks', () => {
  assert.match(migration, /PEM0404_STRATEGIC_MITIGATION_NOT_READY/)
  assert.match(migration, /readiness_status<>'ready'/)
  assert.match(migration, /PEM0404_HIGH_INITIATIVE_RISK_NOT_READY/)
  assert.match(migration, /owner_user_id is null/)
  assert.match(migration, /response_due_date is null/)
  assert.match(migration, /validation_status<>'validated'/)
})

test('PEM-04.04 completion is fail-closed without mutating risks', () => {
  assert.match(migration, /skpe_guard_pem0404_completion/)
  assert.match(migration, /readyForCompletion/)
  assert.match(migration, /riskDuplicated',false/)
  assert.doesNotMatch(migration, /update public\.skpe_initiative_risks/i)
  assert.doesNotMatch(migration, /insert into public\.skpe_initiative_risks/i)
})

test('PEM-04.04 UI exposes risk readiness and opens plan workspace', () => {
  assert.match(section, /PEM-04\.04 · Gestão de Riscos da Implementação/)
  assert.match(section, /get_skpe_pem0404_implementation_risk_readiness/)
  assert.match(section, /não replica riscos/)
  assert.match(section, /Nenhum risco é duplicado/)
  assert.match(section, /Bloqueadores/)
  assert.match(cockpit, /current_stage_code === 'PEM-04\.04'[\s\S]*'plan'/)
})
