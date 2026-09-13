import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const migration = readFileSync(
  join(testDir, '../../../supabase/migrations/20260913172133_govern_cross_organization_event_participants.sql'),
  'utf8',
)

test('participação governada usa Pessoa canônica como identidade transversal', () => {
  assert.match(migration, /set_sparks_person_event_participant/)
  assert.match(migration, /from public\.sparks_people/)
  assert.match(migration, /person_id = target_person_id/)
})

test('Pessoa com login preserva user_id sem exigir membership na organização do evento', () => {
  assert.match(migration, /v_user_id := v_person\.profile_user_id/)
  assert.match(migration, /user_id = v_user_id/)
  assert.doesNotMatch(migration, /Participante precisa ser usuario ativo da organizacao/)
  assert.doesNotMatch(migration, /organization_memberships/)
})

test('função contextual do evento permanece distinta do papel estrutural', () => {
  assert.match(migration, /target_participant_role text/)
  assert.match(migration, /target_participant_function text/)
  assert.match(migration, /participant_function = nullif/)
})

test('participação interorganizacional não cria vínculo artificial com a organização cliente', () => {
  assert.doesNotMatch(migration, /insert into public\.sparks_organization_people/)
  assert.match(migration, /without fabricating membership in the event organization/)
})

test('mutações preservam autorização do gestor e auditoria', () => {
  assert.match(migration, /can_manage_sparks_event_source/)
  assert.match(migration, /event\.participant\.person\.set/)
  assert.match(migration, /sparks_agenda_audit/)
})

test('chair e secretary são papéis opcionais e específicos de cada reunião', () => {
  assert.match(migration, /target_participant_role text default 'participant'/)
  assert.doesNotMatch(migration, /exactly one chair|exactly one secretary|chair_required|secretary_required/i)
})

test('papel estrutural pode ser adequado durante a reunião com histórico auditável', () => {
  assert.match(migration, /participant_role = v_role/)
  assert.match(migration, /previous_data/)
  assert.match(migration, /new_data/)
  assert.match(migration, /repeating the operation updates the effective role while audit preserves the previous assignment/)
})
