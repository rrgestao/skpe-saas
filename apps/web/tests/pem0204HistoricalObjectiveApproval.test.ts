import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004235500_govern_pem0204_historical_objective_approval.sql', import.meta.url),
  'utf8',
)

test('PEM-02.04 historical approval reuse requires reconciled evidence', () => {
  assert.match(migration, /recognize_skpe_objective_historical_approval/)
  assert.match(migration, /documentary_counterproof/)
  assert.match(migration, /pem0204_transport/)
  assert.match(migration, /noNewHumanDecisionCreated/)
})

test('PEM-02.04 recognition preserves historical occurrence and does not invent approver identity', () => {
  assert.match(migration, /decision_occurred_at/)
  assert.match(migration, /approved_at=decision_occurred_at/)
  assert.match(migration, /approved_by=null/)
  assert.match(migration, /historical_decision_reuse/)
})

test('PEM-02.04 readiness is generic and fail-closed', () => {
  assert.match(migration, /get_skpe_pem0204_objective_readiness/)
  assert.match(migration, /PEM0204_OBJECTIVE_APPROVALS_PENDING/)
  assert.match(migration, /PEM0204_APPROVAL_EVIDENCE_MISSING/)
  assert.match(migration, /skpe_guard_pem0204_completion/)
  assert.doesNotMatch(migration, /10 Objetivos/)
})

test('PEM-02.04 completion stores the readiness snapshot', () => {
  assert.match(migration, /completionEvidence/)
  assert.match(migration, /readinessVerifiedAt/)
  assert.match(migration, /readinessSnapshot/)
})
