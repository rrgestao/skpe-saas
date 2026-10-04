import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004052000_govern_causal_relation_validation.sql', import.meta.url),
  'utf8',
)

test('causal relation decisions are append-only human validation events', () => {
  assert.match(migration, /skpe_objective_relation_validation_events/)
  assert.match(migration, /decision_action in \('validate','reject'\)/)
  assert.match(migration, /supersedes_event_id/)
  assert.match(migration, /canonical_relation_mutated',false/)
  assert.match(migration, /can_validate_skpe_formulation/)
  assert.match(migration, /pem02\.05\.causal_relation_validation_recorded/)
})

test('strategic map readiness blocks unvalidated, rejected and disconnected causal content', () => {
  assert.match(migration, /CAUSAL_RELATION_VALIDATION_PENDING/)
  assert.match(migration, /CAUSAL_RELATION_REJECTED/)
  assert.match(migration, /OBJECTIVE_WITHOUT_CAUSAL_LINK/)
  assert.match(migration, /readyForValidation',content_blocking_count=0/)
  assert.match(migration, /pendingRelationValidations/)
  assert.match(migration, /rejectedRelations/)
  assert.match(migration, /disconnectedObjectives/)
})

test('validation decision does not rewrite the objective relation', () => {
  assert.doesNotMatch(migration, /update public\.skpe_objective_relations/)
  assert.doesNotMatch(migration, /delete from public\.skpe_objective_relations/)
})
