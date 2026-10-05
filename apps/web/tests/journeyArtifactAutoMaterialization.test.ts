import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005032000_auto_materialize_journey_artifacts_on_open.sql', import.meta.url),
  'utf8',
)

test('Journey opening automatically ensures usable proposal artifacts', () => {
  assert.match(migration, /ensure_skpe_journey_item_artifacts/)
  assert.match(migration, /skpe_journey_artifacts_on_open/)
  assert.match(migration, /new\.status='in_progress'/)
  assert.match(migration, /'macrophase','phase','activity','deliverable'/)
})

test('automatic artifacts are proposal-only and do not fabricate validation', () => {
  assert.match(migration, /'proposalOnly',true/)
  assert.match(migration, /'humanValidationRequired',true/)
  assert.match(migration, /não representa decisão institucional, aprovação, evidência ou aceite/)
})

test('automatic artifacts always receive an initial downloadable markdown version', () => {
  assert.match(migration, /sparks_methodology_artifact_versions/)
  assert.match(migration, /v_file_name,'md'/)
  assert.match(migration, /content_markdown/)
  assert.match(migration, /current_version_number,planned_due_date/)
})

test('future blocked or not started Journey items cannot materialize artifacts early', () => {
  assert.match(migration, /v_item\.status not in \('in_progress','completed'\)/)
  assert.match(migration, /Itens ainda bloqueados ou não iniciados não podem materializar propostas/)
})

test('PEM-03 through PEM-05 phase suggestions are explicitly governed', () => {
  for (const code of [
    'PEM-03.01','PEM-03.02','PEM-03.03','PEM-03.04',
    'PEM-04.01','PEM-04.02','PEM-04.03','PEM-04.04',
    'PEM-05.01','PEM-05.02','PEM-05.03','PEM-05.04',
  ]) {
    assert.match(migration, new RegExp(code.replace('.', '\\.')))
  }
})
