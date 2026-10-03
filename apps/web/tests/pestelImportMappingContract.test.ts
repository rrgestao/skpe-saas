import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003053000_govern_pestel_import_mapping.sql', import.meta.url),
  'utf8',
)

test('PESTEL mapping is governed, review-gated and non-inferential', () => {
  assert.match(migration, /pestel_to_pestel_item/)
  assert.match(migration, /skpe_pestel_items/)
  assert.match(migration, /skpe_materialize_import_request_as_pestel/)
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /allows_semantic_inference',false/)
  assert.match(migration, /semantic_inference',false/)
  assert.match(migration, /historical_status_promoted', false/)
  assert.match(migration, /'draft',\s*\n\s*'draft'/)
  assert.match(migration, /source_import_record_id/)
  assert.match(migration, /source_external_key/)
  assert.match(migration, /source_payload/)
})

test('PESTEL target resolution is deterministic by reviewed source code', () => {
  assert.match(migration, /pestel_create_new_candidate/)
  assert.match(migration, /create_new_entity_by_source_key/)
  assert.match(migration, /'source_key_field','codigo'/)
  assert.match(migration, /v_resolution\.target_external_key <> v_code/)
  assert.match(migration, /v_code !~ '\^PEST-\[A-Z0-9\]\+\$'/)
  assert.match(migration, /resolution_mode = 'create_new_entity'/)
})

test('PESTEL materializer is idempotent and service-role only', () => {
  assert.match(migration, /where source_import_record_id = v_record\.id/)
  assert.match(migration, /Já existe item PESTEL com o mesmo código/)
  assert.match(migration, /grant execute on function public\.skpe_materialize_import_request_as_pestel[\s\S]*to service_role/)
  assert.match(migration, /revoke all on function public\.skpe_materialize_import_request_as_pestel[\s\S]*from authenticated/)
  assert.doesNotMatch(migration, /grant execute on function public\.skpe_materialize_import_request_as_pestel[\s\S]*to authenticated/)
})

test('dispatcher supports PESTEL without removing existing Key Result path', () => {
  assert.match(migration, /entity_code not in \('key_result','pestel'\)/)
  assert.match(migration, /skpe_execute_governed_import_materialization_c8/)
  assert.match(migration, /skpe_materialize_import_request_as_key_result/)
  assert.match(migration, /skpe_materialize_import_request_as_pestel/)
  assert.match(migration, /skpe_finalize_governed_import_materialization/)
})
