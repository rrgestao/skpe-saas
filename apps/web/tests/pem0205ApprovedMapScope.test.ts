import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005002500_align_pem0205_to_approved_map_scope.sql', import.meta.url),
  'utf8',
)

test('PEM-02.05 approved scope does not retroactively block on owners or detailed OE relations', () => {
  assert.match(migration, /OBJECTIVE_WITHOUT_OWNER/)
  assert.match(migration, /CAUSAL_RELATION_VALIDATION_PENDING/)
  assert.match(migration, /OBJECTIVE_WITHOUT_CAUSAL_LINK/)
  assert.match(migration, /'severity','recommendation'/)
  assert.match(migration, /'scope','next_intervention'/)
  assert.match(migration, /ownerDefinitionDeferredToNextIntervention/)
  assert.match(migration, /detailedCausalRelationsDeferredToNextIntervention/)
})

test('historical Map approval preserves the real approval scope', () => {
  assert.match(migration, /recognize_skpe_strategic_map_historical_approval/)
  assert.match(migration, /historical_decision_reuse/)
  assert.match(migration, /objectiveOwnersApproved',false/)
  assert.match(migration, /detailedObjectiveRelationsApproved',false/)
  assert.match(migration, /noNewHumanDecisionCreated',true/)
})

test('historical Map approval requires structured documentary evidence and leaves approver identity unset', () => {
  assert.match(migration, /map_confirmation/)
  assert.match(migration, /approved_without_reservations_at/)
  assert.match(migration, /validated_at=decision_occurred_at/)
  assert.match(migration, /validated_by=null/)
})
