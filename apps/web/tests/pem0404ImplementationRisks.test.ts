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
const workspace = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicImplementationRiskWorkspace.tsx', import.meta.url),
  'utf8',
)
const validationMigration = readFileSync(
  new URL('../../../supabase/migrations/20261005121000_govern_implementation_risk_human_validation.sql', import.meta.url),
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

test('PEM-04.04 UI exposes risk readiness and governed human-validation workflow', () => {
  assert.match(section, /Gestão de Riscos da Implementação/)
  assert.match(section, /get_skpe_pem0404_implementation_risk_readiness/)
  assert.match(section, /não recria riscos/)
  assert.match(section, /Nenhum risco é criado, aceito ou mitigado automaticamente/)
  assert.match(section, /Bloqueadores/)
  assert.doesNotMatch(section, /<p className="skpe-eyebrow">PEM-04\.04/)
  assert.match(workspace, /upsert_skpe_initiative_risk/)
  assert.match(workspace, /transition_skpe_initiative_risk_validation/)
  assert.match(validationMigration, /human validation workflow for implementation risks/i)
  assert.match(validationMigration, /automaticRiskAcceptance',false/)
  assert.match(cockpit, /current_stage_code === 'PEM-04\.04'[\s\S]*'plan'/)
})
