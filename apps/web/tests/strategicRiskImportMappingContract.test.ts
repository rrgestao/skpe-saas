import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003100000_govern_strategic_risk_import_mapping.sql', import.meta.url),
  'utf8',
)

test('strategic risk mapping is governed, review-gated and non-inferential', () => {
  assert.match(migration, /risk_to_strategic_risk_item/)
  assert.match(migration, /skpe_strategic_risk_items/)
  assert.match(migration, /skpe_materialize_import_request_as_strategic_risk/)
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /allows_semantic_inference',false/)
  assert.match(migration, /semantic_inference', false/)
  assert.match(migration, /risk_scope', 'strategic_diagnosis'/)
  assert.match(migration, /operational_initiative_risk', false/)
})

test('strategic risk numeric fields fail closed', () => {
  assert.match(migration, /nivel_inerente histórico não é numérico e não pode ser inferido/)
  assert.match(migration, /risco_residual histórico não é numérico e não pode ser inferido/)
  assert.match(migration, /conclusao histórica não é numérica e não pode ser inferida/)
  assert.match(migration, /completion_percent < 0 or v_completion_percent > 100/)
  assert.match(migration, /numeric_fields_fail_closed',true/)
})

test('strategic risk objective references only accept explicit OE codes', () => {
  assert.match(migration, /where btrim\(value\) ~ '\^OE-\[A-Z0-9\]\+\$'/)
  assert.match(migration, /source_related_objective_text/)
  assert.match(migration, /relationship_code_policy','only_explicit_oe_codes'/)
})

test('strategic risk target resolution is deterministic by reviewed source code', () => {
  assert.match(migration, /risk_create_new_candidate/)
  assert.match(migration, /create_new_entity_by_source_key/)
  assert.match(migration, /'source_key_field','codigo'/)
  assert.match(migration, /v_resolution\.target_external_key <> v_code/)
  assert.match(migration, /v_code !~ '\^RIC-\[0-9\]\{2\}\$'/)
})

test('strategic risk materializer is idempotent and service-role only', () => {
  assert.match(migration, /where source_import_record_id = v_record\.id/)
  assert.match(migration, /Já existe risco estratégico com o mesmo código/)
  assert.match(migration, /grant execute on function public\.skpe_materialize_import_request_as_strategic_risk[\s\S]*to service_role/)
  assert.match(migration, /revoke all on function public\.skpe_materialize_import_request_as_strategic_risk[\s\S]*from authenticated/)
})

test('dispatcher supports risk while preserving previous governed paths', () => {
  assert.match(migration, /entity_code not in \('key_result','pestel','swot','tows','risk'\)/)
  assert.match(migration, /skpe_materialize_import_request_as_key_result/)
  assert.match(migration, /skpe_materialize_import_request_as_pestel/)
  assert.match(migration, /skpe_materialize_import_request_as_swot/)
  assert.match(migration, /skpe_materialize_import_request_as_tows/)
  assert.match(migration, /skpe_materialize_import_request_as_strategic_risk/)
  assert.match(migration, /dispatcher_version','COOTAQUARA-DIAG-V4'/)
})
