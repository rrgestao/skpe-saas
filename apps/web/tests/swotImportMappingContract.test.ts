import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003070000_govern_swot_import_mapping.sql', import.meta.url),
  'utf8',
)

test('SWOT mapping is governed, review-gated and non-inferential', () => {
  assert.match(migration, /swot_to_swot_item/)
  assert.match(migration, /skpe_swot_items/)
  assert.match(migration, /skpe_materialize_import_request_as_swot/)
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /allows_semantic_inference',false/)
  assert.match(migration, /semantic_inference', false/)
  assert.match(migration, /historical_status_promoted', false/)
  assert.match(migration, /'draft', 'draft'/)
  assert.match(migration, /source_import_record_id/)
  assert.match(migration, /source_external_key/)
  assert.match(migration, /source_payload/)
})

test('SWOT field mapping preserves references without semantic resolution', () => {
  assert.match(migration, /'quadrante','quadrant'/)
  assert.match(migration, /'fator','factor'/)
  assert.match(migration, /'origem_pestel','origin_pestel_codes'/)
  assert.match(migration, /'evidencias_relacionadas','evidence_references'/)
  assert.match(migration, /relationship_code_policy','preserve_tokens_without_semantic_inference'/)
})

test('SWOT target resolution is deterministic by reviewed source code', () => {
  assert.match(migration, /swot_create_new_candidate/)
  assert.match(migration, /create_new_entity_by_source_key/)
  assert.match(migration, /'source_key_field','codigo'/)
  assert.match(migration, /v_resolution\.target_external_key <> v_code/)
  assert.match(migration, /v_code !~ '\^SW-\[FOTW\]\[0-9\]\{2\}\$'/)
  assert.match(migration, /resolution_mode = 'create_new_entity'/)
})

test('SWOT materializer is idempotent and service-role only', () => {
  assert.match(migration, /where source_import_record_id = v_record\.id/)
  assert.match(migration, /Já existe item SWOT com o mesmo código/)
  assert.match(migration, /grant execute on function public\.skpe_materialize_import_request_as_swot[\s\S]*to service_role/)
  assert.match(migration, /revoke all on function public\.skpe_materialize_import_request_as_swot[\s\S]*from authenticated/)
})

test('dispatcher supports SWOT while preserving Key Result and PESTEL', () => {
  assert.match(migration, /entity_code not in \('key_result','pestel','swot'\)/)
  assert.match(migration, /skpe_materialize_import_request_as_key_result/)
  assert.match(migration, /skpe_materialize_import_request_as_pestel/)
  assert.match(migration, /skpe_materialize_import_request_as_swot/)
  assert.match(migration, /skpe_finalize_governed_import_materialization/)
  assert.match(migration, /dispatcher_version','COOTAQUARA-DIAG-V2'/)
})
