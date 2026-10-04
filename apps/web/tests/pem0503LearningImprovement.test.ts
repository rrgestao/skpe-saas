import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004211500_govern_pem0503_learning_improvement.sql', import.meta.url),
  'utf8',
)
const panel = readFileSync(
  new URL('../src/modules/skpe/features/monitoring/MonitoringLearningReadinessPanel.tsx', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/monitoring/MonitoringSection.tsx', import.meta.url),
  'utf8',
)

test('PEM-05.03 reuses canonical strategic learning ledger', () => {
  assert.match(migration, /skpe_strategic_learnings/)
  assert.match(migration, /get_skpe_pem0502_critical_review_readiness/)
  assert.match(migration, /PEM0503_CRITICAL_REVIEW_NOT_READY/)
  assert.match(migration, /learningAuthority','skpe_strategic_learnings'/)
  assert.match(migration, /learningIsNotDecision',true/)
})

test('PEM-05.03 requires evidence, interpretation, lesson and recommendation', () => {
  assert.match(migration, /PEM0503_LEARNING_MISSING/)
  assert.match(migration, /PEM0503_LEARNING_CONTENT_INCOMPLETE/)
  assert.match(migration, /evidence_text/)
  assert.match(migration, /interpretation_text/)
  assert.match(migration, /lesson_text/)
  assert.match(migration, /recommendation/)
})

test('PEM-05.03 preserves human acceptance and governed improvement action', () => {
  assert.match(migration, /PEM0503_LEARNING_DECISION_PENDING/)
  assert.match(migration, /PEM0503_ACTION_DECISION_LINK_MISSING/)
  assert.match(migration, /PEM0503_IMPROVEMENT_ACTION_OWNER_DUE_MISSING/)
  assert.match(migration, /PEM0503_HIGH_IMPACT_GOVERNANCE_DECISION_MISSING/)
  assert.match(migration, /skpe_governance_decisions/)
})

test('PEM-05.03 completion is fail-closed and never fabricates learning/action', () => {
  assert.match(migration, /skpe_guard_pem0503_completion/)
  assert.match(migration, /learningCreatedAutomatically',false/)
  assert.match(migration, /learningAcceptedAutomatically',false/)
  assert.match(migration, /improvementActionCreatedAutomatically',false/)
  assert.doesNotMatch(migration, /insert into public\.skpe_strategic_learnings/i)
  assert.doesNotMatch(migration, /insert into public\.skpe_governance_decisions/i)
})

test('monitoring UI exposes PEM-05.03 learning readiness', () => {
  assert.match(panel, /PEM-05\.03 · Aprendizado e Melhoria/)
  assert.match(panel, /get_skpe_pem0503_learning_readiness/)
  assert.match(panel, /nenhum desses elementos é criado ou aceito automaticamente/)
  assert.match(panel, /Aprendizados/)
  assert.match(panel, /Incorporados/)
  assert.match(section, /<MonitoringLearningReadinessPanel/)
})
