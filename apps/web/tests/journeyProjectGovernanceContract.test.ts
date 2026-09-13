import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const migration = readFileSync(
  join(testDir, '../../../supabase/migrations/20260913143000_govern_skpe_sparkoop_project_leader_bootstrap.sql'),
  'utf8',
)

test('Jornada exige papel canônico Líder de Projeto na SPARKOOP', () => {
  assert.match(migration, /code,\s*name,\s*role_type/s)
  assert.match(migration, /'project_leader'/)
  assert.match(migration, /'Líder de Projeto'/)
  assert.match(migration, /where code = 'SPARKOOP'/)
})

test('bootstrap cria somente owner inicial e não acumula sponsor ou facilitator', () => {
  const bootstrap = migration.split('-- 3. REUNIÃO DE ABERTURA')[0]
  assert.match(bootstrap, /'owner'/)
  assert.doesNotMatch(bootstrap, /'sponsor'/)
  assert.doesNotMatch(bootstrap, /'facilitator'/)
})
test('bootstrap exige vínculo SPARKOOP e atribuição ativa ao papel project_leader', () => {
  assert.match(migration, /sop\.organization_id = v_sparkoop_organization_id/)
  assert.match(migration, /pra\.organizational_role_id = v_project_leader_role_id/)
  assert.match(migration, /pra\.assignment_status = 'active'/)
})

test('Reunião de Abertura substitui somente o owner inicial governado', () => {
  assert.match(migration, /initial_owner_assignment_id/)
  assert.match(migration, /pending_opening_reconciliation/)
  assert.match(migration, /initial_owner_role_code' = 'project_leader'/)
  assert.match(migration, /assign_organization_project_owner_opening_meeting/)
})

test('responsável da Organização deve pertencer à organização do Projeto', () => {
  assert.match(migration, /sop\.organization_id = v_binding\.organization_id/)
  assert.match(migration, /Responsável pelo Projeto definido pela Organização na Reunião de Abertura/)
})
