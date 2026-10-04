import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004015500_enable_review_field_maps_for_composite_mappings.sql', import.meta.url),
  'utf8',
)

test('review contract versions mappings instead of mutating active definitions in place', () => {
  assert.match(migration, /v_new_number:=v_old\.version_number\+1/)
  assert.match(migration, /supersedes_version_id/)
  assert.match(migration, /version_status='superseded'/)
  assert.match(migration, /current_version=v_new_number/)
})

test('decision review contract contains exactly the 12 historical fields required by materializer', () => {
  const start = migration.indexOf("when 'decision_to_gate_decision' then")
  const end = migration.indexOf("when 'deliberative_gate_to_deliberative_context' then", start)
  assert.ok(start >= 0 && end > start)
  const block = migration.slice(start, end)
  const fields = [
    'alternativas','codigo','condicoes','data','decisao','evidencias',
    'macrofase','prazo','questao_decisoria','responsavel','situacao','tema',
  ]
  for (const field of fields) assert.ok(block.includes("'" + field + "','" + field + "'"))
  const pairs = [...block.matchAll(/'([^']+)','\1'/g)]
  assert.equal(pairs.length, 12)
})

test('all previously non-preparable mappings receive explicit source field maps', () => {
  const mappings = [
    'client_validation_to_deliberative_context',
    'decision_to_gate_decision',
    'deliberative_gate_to_deliberative_context',
    'evidence_to_existing_evidence_asset',
    'evidence_management_to_checklist_item',
    'methodology_artifact_to_canonical_artifact',
    'pending_item_to_project_pending_context',
    'pmvv_institutionalization_to_project_input_context',
    'traceability_to_project_snapshot_context',
  ]
  for (const mapping of mappings) assert.ok(migration.includes(mapping))
  assert.match(migration, /'field_map',v_field_map/)
  assert.match(migration, /human_review_contract','explicit_source_fields_v1'/)
})

test('resolution and materialization contracts are copied unchanged into the new version', () => {
  assert.match(migration, /v_old\.resolver_function_name/)
  assert.match(migration, /v_old\.materializer_function_name/)
  assert.match(migration, /v_old\.provenance_function_name/)
  assert.match(migration, /from public\.skpe_incorporation_resolution_rules r/)
  assert.match(migration, /r\.resolver_handler_code/)
  assert.match(migration, /r\.resolver_config/)
  assert.match(migration, /r\.execution_mode/)
})

test('review map evolution remains inference-free', () => {
  assert.match(migration, /review_preparation_enabled',true/)
  assert.match(migration, /semantic_inference',false/)
})
