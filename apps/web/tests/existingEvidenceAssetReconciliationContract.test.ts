import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004023000_reconcile_existing_evidence_asset.sql', import.meta.url),
  'utf8',
)

test('historical evidence resolves exactly to the existing canonical asset', () => {
  assert.match(migration, /evidence_asset_by_external_key/)
  assert.match(migration, /'evidence:'\|\|lower\(v_source_code\)/)
  assert.match(migration, /legacy_project_id'=p_project_id::text/)
  assert.match(migration, /resolution_mode','existing_entity'/)
})

test('evidence reconciliation never creates or updates evidence business content', () => {
  const start = migration.indexOf('create or replace function public.skpe_materialize_import_request_as_existing_evidence_asset')
  const end = migration.indexOf('revoke all on function public.skpe_materialize_import_request_as_existing_evidence_asset', start)
  assert.ok(start >= 0 && end > start)
  const body = migration.slice(start, end)

  assert.match(body, /businessContentUpdated',false/)
  assert.match(body, /validationStatusUpdated',false/)
  assert.match(body, /reliabilityUpdated',false/)
  assert.match(body, /formalDocumentCreated',false/)
  assert.doesNotMatch(body, /insert into public\.sparks_evidence_assets/i)
  assert.doesNotMatch(body, /update public\.sparks_evidence_assets/i)
  assert.doesNotMatch(body, /insert into public\.sparks_evidence_versions/i)
})

test('resolution dispatcher preserves all prior handlers and adds exact evidence lookup', () => {
  assert.match(migration, /current_project_reference/)
  assert.match(migration, /current_import_batch_reference/)
  assert.match(migration, /strategic_identity_item_by_element/)
  assert.match(migration, /strategic_value_by_name/)
  assert.match(migration, /evidence_asset_by_external_key/)
})

test('materialization dispatcher delegates every previous entity family unchanged', () => {
  assert.match(migration, /rename to skpe_execute_governed_import_materialization_evidence_checklist_v1/)
  assert.match(migration, /if v_record\.entity_code <> 'evidence' then/)
  assert.match(migration, /return public\.skpe_execute_governed_import_materialization_evidence_checklist_v1/)
})

test('evidence reconciliation remains review-first and inference-free', () => {
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /require_approved_incorporation_items',true/)
  assert.match(migration, /require_governed_incorporation_decision',true/)
  assert.match(migration, /semantic_inference',false/)
})
