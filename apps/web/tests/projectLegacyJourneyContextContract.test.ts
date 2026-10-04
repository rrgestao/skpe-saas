import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004004500_govern_project_and_legacy_journey_context.sql', import.meta.url),
  'utf8',
)

test('project sheet and legacy journey are project-context evidence only', () => {
  assert.match(migration, /project_sheet_to_existing_project_context/)
  assert.match(migration, /legacy_journey_to_existing_project_context/)
  assert.match(migration, /'existing_entity','evidence_only','a1_object'/)
  assert.match(migration, /canonical_project_updated',false/)
  assert.match(migration, /canonical_journey_updated',false/)
  assert.match(migration, /legacy_journey_model'/)
})

test('project-context resolver anchors to the current canonical project', () => {
  assert.match(migration, /skpe_execute_resolution_handler_current_project_reference/)
  assert.match(migration, /match_strategy','current_canonical_project'/)
  assert.match(migration, /'entity_type','project_context_provenance'/)
  assert.match(migration, /'project_context_provenance','exists'/)
})

test('project-context materializer does not mutate project or journey business state', () => {
  const start = migration.indexOf('create or replace function public.skpe_materialize_import_request_as_project_context_provenance')
  const end = migration.indexOf('revoke all on function public.skpe_materialize_import_request_as_project_context_provenance', start)
  assert.ok(start >= 0 && end > start)
  const body = migration.slice(start, end)

  assert.match(body, /PROJECT_HISTORICAL_CONTEXT_RECONCILED/)
  assert.match(body, /canonicalProjectUpdated',false/)
  assert.match(body, /canonicalJourneyUpdated',false/)
  assert.match(body, /businessEntityCreated',false/)
  assert.doesNotMatch(body, /update public\.skpe_projects/i)
  assert.doesNotMatch(body, /insert into public\.skpe_projects/i)
  assert.doesNotMatch(body, /update public\.skpe_journey_items/i)
  assert.doesNotMatch(body, /insert into public\.skpe_journey_items/i)
})

test('dispatcher preserves existing routes while adding project-context types', () => {
  assert.match(migration, /'version_control','living_governance','project','journey'/)
  assert.match(migration, /skpe_materialize_import_request_as_project_context_provenance/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_key_results where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_pestel_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_swot_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_tows_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_strategic_risk_items where id=v_entity_id\)/)
})

test('legacy journey contract explicitly preserves the canonical six-macrophase journey', () => {
  assert.match(migration, /antiga Jornada MF1–MF4/)
  assert.match(migration, /Não atualiza a Jornada canônica atual PEM-00–PEM-05/)
  assert.match(migration, /canonical_journey_policy/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /semantic_inference',false/)
})
