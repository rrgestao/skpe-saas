import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004011500_govern_approved_initiative_inputs.sql', import.meta.url),
  'utf8',
)

test('initiative and portfolio records remain approved directional inputs', () => {
  assert.match(migration, /initiative_to_approved_initiative_input/)
  assert.match(migration, /project_portfolio_to_approved_initiative_input/)
  assert.match(migration, /historical_business_approval_preserved',true/)
  assert.match(migration, /approved_directional_input',true/)
  assert.match(migration, /future_development_stage','strategic_initiatives'/)
  assert.match(migration, /semantic_matching_performed',false/)
})

test('initiative inputs are evidence only and never auto-create canonical initiatives', () => {
  assert.match(migration, /'existing_entity','evidence_only','a1_object'/)
  assert.match(migration, /canonical_initiative_policy','do_not_create_or_update'/)
  assert.match(migration, /semantic_matching_policy','forbidden_at_import_mapping_stage'/)

  const start = migration.indexOf('create or replace function public.skpe_materialize_import_request_as_approved_initiative_input')
  const end = migration.indexOf('revoke all on function public.skpe_materialize_import_request_as_approved_initiative_input', start)
  assert.ok(start >= 0 && end > start)
  const body = migration.slice(start, end)

  assert.match(body, /APPROVED_INITIATIVE_INPUT_RECONCILED/)
  assert.match(body, /canonicalInitiativeCreated',false/)
  assert.match(body, /canonicalInitiativeUpdated',false/)
  assert.doesNotMatch(body, /insert into public\.skpe_initiatives/i)
  assert.doesNotMatch(body, /update public\.skpe_initiatives/i)
  assert.doesNotMatch(body, /insert into public\.sparks_initiatives/i)
  assert.doesNotMatch(body, /update public\.sparks_initiatives/i)
})

test('initiative input mapping anchors only to the canonical project', () => {
  assert.match(migration, /current_project_reference/)
  assert.match(migration, /approved_initiative_input_provenance/)
  assert.match(migration, /v_project_id <> v_record\.project_id/)
})

test('dispatcher preserves prior routes while adding initiative input routes', () => {
  assert.match(migration, /'initiative','project_portfolio'/)
  assert.match(migration, /skpe_materialize_import_request_as_approved_initiative_input/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_key_results where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_pestel_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_swot_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_tows_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_strategic_risk_items where id=v_entity_id\)/)
})

test('initiative inputs remain review-first and inference-free', () => {
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /require_approved_incorporation_items',true/)
  assert.match(migration, /require_governed_incorporation_decision',true/)
  assert.match(migration, /semantic_inference',false/)
})
