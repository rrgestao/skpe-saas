import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004002500_govern_workbook_provenance_evidence_only.sql', import.meta.url),
  'utf8',
)

test('workbook governance and version history are evidence-only', () => {
  assert.match(migration, /version_control_to_batch_provenance/)
  assert.match(migration, /living_governance_to_batch_provenance/)
  assert.match(migration, /'existing_entity','evidence_only','a1_object'/)
  assert.match(migration, /business_entity_created',false/)
  assert.match(migration, /business_content_updated',false/)
  assert.match(migration, /historical_provenance_only',true/)
})

test('provenance resolver anchors records to their own import batch', () => {
  assert.match(migration, /skpe_execute_resolution_handler_current_import_batch_reference/)
  assert.match(migration, /match_strategy','current_import_batch'/)
  assert.match(migration, /v_batch\.project_id is distinct from p_project_id/)
  assert.match(migration, /target_entity_type='import_batch_provenance'/)
})

test('provenance materializer emits audit only and does not mutate business entities', () => {
  const start = migration.indexOf('create or replace function public.skpe_materialize_import_request_as_batch_provenance')
  const end = migration.indexOf('revoke all on function public.skpe_materialize_import_request_as_batch_provenance', start)
  assert.ok(start >= 0 && end > start)
  const body = migration.slice(start, end)

  assert.match(body, /WORKBOOK_HISTORICAL_PROVENANCE_RECONCILED/)
  assert.match(body, /businessEntityCreated',false/)
  assert.match(body, /businessContentUpdated',false/)
  assert.match(body, /evidenceOnly',true/)
  assert.doesNotMatch(body, /insert into public\.skpe_strategic_/i)
  assert.doesNotMatch(body, /update public\.skpe_strategic_/i)
  assert.doesNotMatch(body, /insert into public\.sparks_/i)
  assert.doesNotMatch(body, /update public\.sparks_/i)
})

test('dispatcher preserves prior routes while adding provenance-only types', () => {
  assert.match(migration, /'strategic_identity','living_value','pmvv_validation'/)
  assert.match(migration, /'version_control','living_governance'/)
  assert.match(migration, /skpe_materialize_import_request_as_batch_provenance/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_key_results where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_pestel_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_swot_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_tows_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_strategic_risk_items where id=v_entity_id\)/)
})

test('evidence-only mappings remain review-first and inference-free', () => {
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /require_approved_incorporation_items',true/)
  assert.match(migration, /require_governed_incorporation_decision',true/)
  assert.match(migration, /allows_semantic_inference=false/)
  assert.match(migration, /semantic_inference',false/)
})
