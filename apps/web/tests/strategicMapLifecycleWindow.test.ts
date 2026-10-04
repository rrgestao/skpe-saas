import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004053500_harden_strategic_map_lifecycle_window.sql', import.meta.url),
  'utf8',
)

test('strategic map content is editable only in PEM-02.05 or formal revision', () => {
  assert.match(migration, /skpe_strategic_map_edit_window_open/)
  assert.match(migration, /code='PEM-02\.05'/)
  assert.match(migration, /stage_status='in_progress'/)
  assert.match(migration, /revisionOfOfficialVersionId/)
  assert.match(migration, /skpe_objective_relations_edit_window_guard/)
  assert.match(migration, /skpe_relation_validation_edit_window_guard/)
})

test('map validation requires a human justification', () => {
  assert.match(migration, /normalized_action='validate'/)
  assert.match(migration, /length\(trim\(coalesce\(decision_notes,''\)\)\) < 10/)
  assert.match(migration, /exige justificativa humana com pelo menos 10 caracteres/)
})

test('initial package workflow cannot bypass PEM-02.05', () => {
  assert.match(migration, /submit_validation','validate','return_for_adjustments/)
  assert.match(migration, /O workflow inicial do Mapa Estratégico só pode avançar durante PEM-02\.05/)
  assert.match(migration, /begin_revision/)
})
