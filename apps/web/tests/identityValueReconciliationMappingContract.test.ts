import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003235500_govern_identity_value_reconciliation_mappings.sql', import.meta.url),
  'utf8',
)

test('identity and value mappings reconcile existing approved entities only', () => {
  assert.match(migration, /strategic_identity_to_existing_identity_item/)
  assert.match(migration, /living_value_to_existing_strategic_value/)
  assert.match(migration, /'existing_entity','direct_entity'/)
  assert.match(migration, /true,false,true,false,'active',1/)
  assert.match(migration, /business_content_updated',false/)
  assert.match(migration, /business_approval_reopened',false/)
  assert.match(migration, /semantic_inference',false/)
})

test('deterministic resolvers use same project and formulation', () => {
  assert.match(migration, /skpe_execute_resolution_handler_strategic_identity_item_by_element/)
  assert.match(migration, /skpe_execute_resolution_handler_strategic_value_by_name/)
  assert.match(migration, /exact_element_same_project_same_formulation/)
  assert.match(migration, /exact_name_same_project_same_formulation/)
  assert.match(migration, /resolution_mode','existing_entity'/)
})

test('existing-reference materializer does not mutate approved identity or values', () => {
  const start = migration.indexOf('create or replace function public.skpe_materialize_import_request_as_existing_reference')
  const end = migration.indexOf('revoke all on function public.skpe_materialize_import_request_as_existing_reference', start)
  assert.ok(start >= 0 && end > start)
  const body = migration.slice(start, end)

  assert.match(body, /EXISTING_CANONICAL_ENTITY_RECONCILED/)
  assert.match(body, /businessContentUpdated',false/)
  assert.match(body, /businessApprovalReopened',false/)
  assert.doesNotMatch(body, /insert into public\.skpe_strategic_identity_items/i)
  assert.doesNotMatch(body, /update public\.skpe_strategic_identity_items/i)
  assert.doesNotMatch(body, /insert into public\.skpe_strategic_values/i)
  assert.doesNotMatch(body, /update public\.skpe_strategic_values/i)
})

test('dispatcher preserves physical-target verification for existing supported types', () => {
  assert.match(migration, /not exists\(select 1 from public\.skpe_key_results where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_pestel_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_swot_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_tows_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_strategic_risk_items where id=v_entity_id\)/)
  assert.match(migration, /from public\.skpe_strategic_identity_items/)
  assert.match(migration, /from public\.skpe_strategic_values/)
})

test('identity and value reconciliation still requires governed review and decision', () => {
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /require_approved_incorporation_items',true/)
  assert.match(migration, /require_governed_incorporation_decision',true/)
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /decision_outcome not in \('approved','approved_with_reservations'\)/)
})
