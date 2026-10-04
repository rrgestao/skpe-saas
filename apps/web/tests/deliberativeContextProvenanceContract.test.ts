import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004025000_govern_deliberative_context_provenance.sql', import.meta.url),
  'utf8',
)

test('client validation and deliberative gate are historical context only', () => {
  assert.match(migration, /client_validation_to_deliberative_context/)
  assert.match(migration, /deliberative_gate_to_deliberative_context/)
  assert.match(migration, /'existing_entity','evidence_only','a1_object'/)
  assert.match(migration, /historical_context_only',true/)
  assert.match(migration, /canonical_decision_authority','entity_code=decision'/)
})

test('deliberative context never creates formal gate or governance decisions', () => {
  const start = migration.indexOf('create or replace function public.skpe_materialize_import_request_as_deliberative_context_provenance')
  const end = migration.indexOf('revoke all on function public.skpe_materialize_import_request_as_deliberative_context_provenance', start)
  assert.ok(start >= 0 && end > start)
  const body = migration.slice(start, end)

  assert.match(body, /formalGateDecisionCreated',false/)
  assert.match(body, /formalGovernanceDecisionCreated',false/)
  assert.doesNotMatch(body, /insert into public\.skpe_gate_decisions/i)
  assert.doesNotMatch(body, /update public\.skpe_gate_decisions/i)
  assert.doesNotMatch(body, /insert into public\.skpe_governance_decisions/i)
  assert.doesNotMatch(body, /update public\.skpe_governance_decisions/i)
})

test('deliberative context is anchored to the current canonical project', () => {
  assert.match(migration, /current_project_reference/)
  assert.match(migration, /deliberative_context_provenance/)
  assert.match(migration, /v_project_id <> v_record\.project_id/)
  assert.match(migration, /formal_decision_policy','do_not_create'/)
})

test('dispatcher delegates every previous entity family unchanged', () => {
  assert.match(migration, /rename to skpe_execute_governed_import_materialization_evidence_recon_v1/)
  assert.match(migration, /if v_record\.entity_code not in \('client_validation','deliberative_gate'\) then/)
  assert.match(migration, /return public\.skpe_execute_governed_import_materialization_evidence_recon_v1/)
})

test('deliberative context remains review-first and inference-free', () => {
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /require_approved_incorporation_items',true/)
  assert.match(migration, /require_governed_incorporation_decision',true/)
  assert.match(migration, /semantic_inference',false/)
})
