import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004013500_govern_methodology_artifact_materialization.sql', import.meta.url),
  'utf8',
)

test('historical artifact codes have deterministic canonical types', () => {
  assert.match(migration, /'PEM-02\.SGE-01' then[\s\S]*'MANAGEMENT_WORKBOOK'/)
  assert.match(migration, /'ART-PMVV-RV02' then[\s\S]*'EXECUTIVE_PRESENTATION'/)
  assert.match(migration, /'ART-PMVV-V23' then[\s\S]*'PHASE_TRANSITION_PROTOCOL'/)
  assert.match(migration, /semantic_inference',false/)
})

test('historical source versions are preserved without synthetic canonical versions', () => {
  assert.match(migration, /source_version_label/)
  assert.match(migration, /canonical_version_starts_at',1/)
  assert.match(migration, /synthetic_intermediate_versions_created',false/)
  assert.match(migration, /version_number,[\s\S]*version_label/)
  assert.match(migration, /1,[\s\S]*'v1'/)
})

test('materializer is idempotent by historical artifact code in the same project', () => {
  assert.match(migration, /external_id=v_source_code/)
  assert.match(migration, /organization_id=v_request\.organization_id/)
  assert.match(migration, /project_id=v_request\.project_id/)
  assert.match(migration, /if v_artifact_id is not null then/)
})

test('binary files are not fabricated by historical metadata import', () => {
  assert.match(migration, /binary_file_recreated',false/)
  assert.match(migration, /binaryFileRecreated',false/)
  assert.match(migration, /binary_content_available',false/)
  assert.match(migration, /arquivo original não foi recriado/)
})

test('dispatcher delegates every pre-existing route to the previous dispatcher', () => {
  assert.match(migration, /rename to skpe_execute_governed_import_materialization_initiative_input_v1/)
  assert.match(migration, /if v_record\.entity_code <> 'methodology_artifact' then/)
  assert.match(migration, /return public\.skpe_execute_governed_import_materialization_initiative_input_v1/)
})

test('methodology artifact remains governed and review-first', () => {
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /require_approved_incorporation_items',true/)
  assert.match(migration, /require_governed_incorporation_decision',true/)
  assert.match(migration, /requires_human_review',true/)
  assert.match(migration, /METHODOLOGY_ARTIFACT_MATERIALIZED/)
})
