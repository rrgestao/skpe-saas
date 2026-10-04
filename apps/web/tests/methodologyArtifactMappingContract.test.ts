import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004013500_govern_methodology_artifacts.sql', import.meta.url),
  'utf8',
)

test('historical methodology artifact types are classified deterministically', () => {
  assert.match(migration, /when 'xlsx' then\s+v_artifact_type_code:='MANAGEMENT_WORKBOOK'/)
  assert.match(migration, /when 'apresentação executiva \/ base aprovada' then\s+v_artifact_type_code:='EXECUTIVE_PRESENTATION'/)
  assert.match(migration, /when 'kit de encerramento' then\s+v_artifact_type_code:='PHASE_TRANSITION_PROTOCOL'/)
  assert.match(migration, /Tipo histórico de artefato ainda não possui classificação canônica determinística/)
})

test('technical artifact import never promotes historical validation status', () => {
  assert.match(migration, /historical_status_promoted',false/)
  assert.match(migration, /institutional_validation_performed',false/)
  assert.match(migration, /'in_review'/)
  assert.match(migration, /'review'/)
  assert.doesNotMatch(migration, /historical_status_promoted',true/)
  assert.doesNotMatch(migration, /institutional_validation_performed',true/)
})

test('methodology artifact materializer is governed and inference-free', () => {
  assert.match(migration, /skpe_assert_governed_import_materialization/)
  assert.match(migration, /decision_outcome not in \('approved','approved_with_reservations'\)/)
  assert.match(migration, /extraction_mode='inferred'/)
  assert.match(migration, /Mapping de artefato não aceita itens inferidos/)
  assert.match(migration, /semantic_inference',false/)
})

test('mapping creates canonical methodology artifacts and versions', () => {
  assert.match(migration, /methodology_artifact_to_canonical_artifact/)
  assert.match(migration, /'methodology_artifact','methodology_artifact'/)
  assert.match(migration, /'create_new_entity','direct_entity'/)
  assert.match(migration, /insert into public\.sparks_methodology_artifacts/)
  assert.match(migration, /insert into public\.sparks_methodology_artifact_versions/)
})

test('dispatcher preserves physical verification and adds methodology artifacts', () => {
  assert.match(migration, /'initiative','project_portfolio','methodology_artifact'/)
  assert.match(migration, /skpe_materialize_import_request_as_methodology_artifact/)
  assert.match(migration, /from public\.sparks_methodology_artifacts/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_key_results where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_pestel_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_swot_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_tows_items where id=v_entity_id\)/)
  assert.match(migration, /not exists\(select 1 from public\.skpe_strategic_risk_items where id=v_entity_id\)/)
})
