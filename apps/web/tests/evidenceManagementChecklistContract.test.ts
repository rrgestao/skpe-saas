import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004021000_govern_evidence_management_checklist.sql', import.meta.url),
  'utf8',
)

test('evidence management becomes one canonical evidence-collection checklist', () => {
  assert.match(migration, /HIST-EVIDENCE-MGMT-V26/)
  assert.match(migration, /'evidence_collection'/)
  assert.match(migration, /'methodology_required'/)
  assert.match(migration, /evidence_management_to_checklist_item/)
})

test('historical maturity is preserved without current assessment inference', () => {
  assert.match(migration, /source_maturity/)
  assert.match(migration, /source_evidence_level/)
  assert.match(migration, /current_collection_state_inferred',false/)
  assert.match(migration, /current_assessment_state_inferred',false/)
  assert.match(migration, /'not_requested'/)
  assert.match(migration, /'not_assessed'/)
})

test('materializer is idempotent by checklist code and source item code', () => {
  assert.match(migration, /code='HIST-EVIDENCE-MGMT-V26'/)
  assert.match(migration, /checklist_id=v_checklist_id/)
  assert.match(migration, /code=v_source_code/)
  assert.match(migration, /if v_item_id is not null then/)
})

test('evidence checklist import does not fabricate evidence files', () => {
  assert.match(migration, /evidence_file_created',false/)
  assert.match(migration, /evidenceFileCreated',false/)
  assert.doesNotMatch(migration, /insert into public\.sparks_evidence_assets/i)
  assert.doesNotMatch(migration, /insert into public\.sparks_evidence_versions/i)
})

test('dispatcher delegates all previous entity families unchanged', () => {
  assert.match(migration, /rename to skpe_execute_governed_import_materialization_methodology_artifact_v1/)
  assert.match(migration, /if v_record\.entity_code <> 'evidence_management' then/)
  assert.match(migration, /return public\.skpe_execute_governed_import_materialization_methodology_artifact_v1/)
})

test('evidence checklist materialization remains review-first and inference-free', () => {
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /require_approved_incorporation_items',true/)
  assert.match(migration, /require_governed_incorporation_decision',true/)
  assert.match(migration, /semantic_inference',false/)
})
