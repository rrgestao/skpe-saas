import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004031500_govern_final_composite_provenance.sql', import.meta.url),
  'utf8',
)

test('final composite families are governed as distinct project provenance types', () => {
  assert.match(migration, /pending_item_to_project_pending_context/)
  assert.match(migration, /pmvv_institutionalization_to_project_input_context/)
  assert.match(migration, /traceability_to_project_snapshot_context/)
  assert.match(migration, /pending_context_provenance/)
  assert.match(migration, /pmvv_institutionalization_input_provenance/)
  assert.match(migration, /traceability_snapshot_provenance/)
})

test('pending items preserve unresolved and incomplete records for future curation', () => {
  assert.match(migration, /requiresFutureCuration/)
  assert.match(migration, /v_source_code is null/)
  assert.match(migration, /pendencia_acao/)
  assert.match(migration, /do_not_create_action_plan_or_action_item_without_curated_parent_plan/)
})

test('PMVV institutionalization inputs cannot rewrite identity or auto-create execution', () => {
  assert.match(migration, /do_not_change_identity_or_create_execution_action_automatically/)
  assert.match(migration, /identityUpdated',false/)
  assert.match(migration, /initiativeCreated',false/)
})

test('traceability snapshots do not fabricate cross-entity links', () => {
  assert.match(migration, /do_not_create_cross_entity_links_from_composite_historical_row/)
  assert.match(migration, /traceabilityLinksCreated',false/)
  assert.match(migration, /requires_future_curation/)
})

test('composite materializer creates no business action, initiative or identity entity', () => {
  const start = migration.indexOf('create or replace function public.skpe_materialize_import_request_as_composite_project_provenance')
  const end = migration.indexOf('revoke all on function public.skpe_materialize_import_request_as_composite_project_provenance', start)
  assert.ok(start >= 0 && end > start)
  const body = migration.slice(start, end)

  assert.doesNotMatch(body, /insert into public\.skpe_action_plans/i)
  assert.doesNotMatch(body, /insert into public\.skpe_action_plan_items/i)
  assert.doesNotMatch(body, /insert into public\.skpe_initiatives/i)
  assert.doesNotMatch(body, /insert into public\.sparks_initiatives/i)
  assert.doesNotMatch(body, /update public\.skpe_strategic_identity/i)
  assert.doesNotMatch(body, /insert into public\.sparks_evidence_links/i)
})

test('dispatcher delegates all previous entity families unchanged', () => {
  assert.match(migration, /rename to skpe_execute_governed_import_materialization_deliberative_context_v1/)
  assert.match(migration, /if v_record\.entity_code not in \('pending_item','pmvv_institutionalization','traceability'\) then/)
  assert.match(migration, /return public\.skpe_execute_governed_import_materialization_deliberative_context_v1/)
})

test('final composite mappings remain review-first and inference-free', () => {
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /require_approved_incorporation_items',true/)
  assert.match(migration, /require_governed_incorporation_decision',true/)
  assert.match(migration, /semantic_inference',false/)
})
