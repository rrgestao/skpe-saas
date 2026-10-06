import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004204500_govern_pem0502_critical_review.sql', import.meta.url),
  'utf8',
)
const panel = readFileSync(
  new URL('../src/modules/skpe/features/monitoring/MonitoringCriticalReviewReadinessPanel.tsx', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/monitoring/MonitoringSection.tsx', import.meta.url),
  'utf8',
)

test('PEM-05.02 reuses PEM-05.01 and the canonical FE-08 RAE', () => {
  assert.match(migration, /get_skpe_pem0501_monitoring_operation_readiness/)
  assert.match(migration, /skpe_strategy_reviews/)
  assert.match(migration, /review_type='rae'/)
  assert.match(migration, /PEM0502_RAE_MISSING/)
  assert.match(migration, /PEM0502_RAE_NOT_RATIFIED/)
})

test('PEM-05.02 requires substantive analysis and conclusions', () => {
  assert.match(migration, /PEM0502_CRITICAL_SYNTHESIS_INCOMPLETE/)
  assert.match(migration, /executive_summary/)
  assert.match(migration, /conclusions/)
  assert.match(migration, /PEM0502_REVIEW_ITEM_MISSING/)
  assert.match(migration, /PEM0502_REVIEW_ITEM_ANALYSIS_INCOMPLETE/)
})

test('PEM-05.02 requires traceable decisions when review items require them', () => {
  assert.match(migration, /requires_decision=true/)
  assert.match(migration, /skpe_governance_decisions/)
  assert.match(migration, /PEM0502_REQUIRED_DECISION_MISSING/)
  assert.match(migration, /PEM0502_CRITICAL_DECISION_INCOMPLETE/)
  assert.match(migration, /skpe_guard_pem0502_completion/)
})

test('PEM-05.02 never creates conclusions or decisions automatically', () => {
  assert.match(migration, /createsConclusionsAutomatically',false/)
  assert.match(migration, /createsDecisionsAutomatically',false/)
  assert.doesNotMatch(migration, /insert into public\.skpe_governance_decisions/i)
  assert.doesNotMatch(migration, /update public\.skpe_strategy_reviews/i)
})

test('monitoring UI exposes PEM-05.02 critical review readiness', () => {
  assert.match(panel, /Análise Crítica de Desempenho/)
  assert.match(panel, /get_skpe_pem0502_critical_review_readiness/)
  assert.match(panel, /Nenhuma conclusão ou decisão é criada automaticamente/)
  assert.match(panel, /Itens de análise/)
  assert.match(panel, /Decisões de governança/)
  assert.match(section, /<MonitoringCriticalReviewReadinessPanel/)
})
