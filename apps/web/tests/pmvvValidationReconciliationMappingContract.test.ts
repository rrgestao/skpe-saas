import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004000500_govern_pmvv_validation_reconciliation_mapping.sql', import.meta.url),
  'utf8',
)

test('PMVV validation reconciles only to existing approved identity items', () => {
  assert.match(migration, /pmvv_validation_to_existing_identity_item/)
  assert.match(migration, /'pmvv_validation','strategic_identity_item'/)
  assert.match(migration, /'existing_entity','direct_entity'/)
  assert.match(migration, /allows_create_new=false/)
  assert.match(migration, /allows_existing_entity=true/)
  assert.match(migration, /strategic_identity_item_by_element/)
})

test('PMVV validation materializer preserves business approval', () => {
  const start = migration.indexOf('create or replace function public.skpe_materialize_import_request_as_pmvv_validation_reference')
  const end = migration.indexOf('revoke all on function public.skpe_materialize_import_request_as_pmvv_validation_reference', start)
  assert.ok(start >= 0 && end > start)
  const body = migration.slice(start, end)

  assert.match(body, /PMVV_VALIDATION_HISTORY_RECONCILED/)
  assert.match(body, /businessContentUpdated',false/)
  assert.match(body, /businessApprovalReopened',false/)
  assert.match(body, /historicalValidationPreserved',true/)
  assert.doesNotMatch(body, /insert into public\.skpe_strategic_identity_items/i)
  assert.doesNotMatch(body, /update public\.skpe_strategic_identity_items/i)
})

test('dispatcher adds PMVV without dropping physical verification of existing routes', () => {
  assert.match(migration, /'strategic_identity','living_value','pmvv_validation'/)
  assert.match(migration, /skpe_materialize_import_request_as_pmvv_validation_reference/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_key_results where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_pestel_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_swot_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_tows_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_strategic_risk_items where id=v_entity_id\)/)
  assert.match(migration, /v_record\.entity_code in \('strategic_identity','pmvv_validation'\)/)
  assert.match(migration, /v_record\.entity_code='living_value'/)
})

test('PMVV reconciliation remains review-first and inference-free', () => {
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /require_approved_incorporation_items',true/)
  assert.match(migration, /require_governed_incorporation_decision',true/)
  assert.match(migration, /business_approval_reopened',false/)
  assert.match(migration, /semantic_inference',false/)
})
