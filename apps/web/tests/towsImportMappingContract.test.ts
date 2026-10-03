import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003083000_govern_tows_import_mapping.sql', import.meta.url),
  'utf8',
)

test('TOWS mapping is governed, review-gated and non-inferential', () => {
  assert.match(migration, /tows_to_tows_item/)
  assert.match(migration, /skpe_tows_items/)
  assert.match(migration, /skpe_materialize_import_request_as_tows/)
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /allows_semantic_inference',false/)
  assert.match(migration, /semantic_inference', false/)
  assert.match(migration, /historical_status_promoted', false/)
  assert.match(migration, /'draft', 'draft'/)
})

test('TOWS field mapping preserves factor codes without semantic resolution', () => {
  assert.match(migration, /'tipo','tows_type'/)
  assert.match(migration, /'estrategia_formulada','strategy_statement'/)
  assert.match(migration, /'forcas_fraquezas','internal_factor_codes'/)
  assert.match(migration, /'oportunidades_ameacas','external_factor_codes'/)
  assert.match(migration, /relationship_code_policy','preserve_tokens_without_semantic_inference'/)
})

test('TOWS target resolution is deterministic by reviewed source code', () => {
  assert.match(migration, /tows_create_new_candidate/)
  assert.match(migration, /create_new_entity_by_source_key/)
  assert.match(migration, /'source_key_field','codigo'/)
  assert.match(migration, /v_resolution\.target_external_key <> v_code/)
  assert.match(migration, /v_code !~ '\^TW-\(FO\|WO\|ST\|WT\)\[0-9\]\{2\}\$'/)
  assert.match(migration, /substring\(v_code from 4 for 2\) <> v_tows_type/)
})

test('TOWS materializer is idempotent and service-role only', () => {
  assert.match(migration, /where source_import_record_id = v_record\.id/)
  assert.match(migration, /Já existe item TOWS com o mesmo código/)
  assert.match(migration, /grant execute on function public\.skpe_materialize_import_request_as_tows[\s\S]*to service_role/)
  assert.match(migration, /revoke all on function public\.skpe_materialize_import_request_as_tows[\s\S]*from authenticated/)
})

test('dispatcher supports TOWS while preserving previous governed paths', () => {
  assert.match(migration, /entity_code not in \('key_result','pestel','swot','tows'\)/)
  assert.match(migration, /skpe_materialize_import_request_as_key_result/)
  assert.match(migration, /skpe_materialize_import_request_as_pestel/)
  assert.match(migration, /skpe_materialize_import_request_as_swot/)
  assert.match(migration, /skpe_materialize_import_request_as_tows/)
  assert.match(migration, /dispatcher_version','COOTAQUARA-DIAG-V3'/)
})
