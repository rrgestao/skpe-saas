import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const migration = readFileSync(
  join(testDir, '../../../supabase/migrations/20260913184702_govern_institutional_strategy_event_visibility.sql'),
  'utf8',
)
const agenda = readFileSync(
  join(testDir, '../src/modules/skpe/features/agenda/AgendaSection.tsx'),
  'utf8',
)
const manager = readFileSync(
  join(testDir, '../src/modules/skpe/features/journey/JourneyEventManageDialog.tsx'),
  'utf8',
)
const managementMigration = readFileSync(
  join(testDir, '../../../supabase/migrations/20260913192035_expose_event_visibility_management.sql'),
  'utf8',
)

test('evento mantém identidade única e recebe escopo de visibilidade', () => {
  assert.match(migration, /alter table public\.sparks_events/)
  assert.match(migration, /visibility_scope/)
  assert.match(migration, /participants.*organization/s)
})

test('visibilidade institucional não cria participantes artificiais', () => {
  assert.match(migration, /Institutional visibility never creates participant records/)
  assert.doesNotMatch(migration, /insert into public\.sparks_event_participants/)
})

test('feed diferencia participante de observador institucional', () => {
  assert.match(migration, /engagement_level text/)
  assert.match(migration, /case when cp\.id is not null then 'participant' else 'institutional' end/)
  assert.match(migration, /is_participant boolean/)
})

test('visibilidade institucional não concede detalhes reservados automaticamente', () => {
  assert.match(migration, /detail_access boolean/)
  assert.match(migration, /public\.has_module_access/)
  assert.match(migration, /else null/)
})

test('Agenda deduplica o mesmo evento e enriquece participante', () => {
  assert.match(agenda, /const nativeKey = `NATIVE:event:\$\{event\.event_id\}:event`/)
  assert.match(agenda, /const current = merged\.get\(nativeKey\)/)
  assert.match(agenda, /merged\.set\(nativeKey, \{ \.\.\.current, \.\.\.engagement \}\)/)
})

test('Agenda comunica institucionalidade e participação de forma distinta', () => {
  assert.match(agenda, /Você participa/)
  assert.match(agenda, /Evento institucional/)
  assert.match(agenda, /engagement_message/)
})

test('gestor lê e altera o escopo institucional sem assumir estado local', () => {
  assert.match(managementMigration, /get_sparks_event_visibility_scope/)
  assert.match(manager, /get_sparks_event_visibility_scope/)
  assert.match(manager, /set_sparks_event_visibility_scope/)
  assert.match(manager, /Somente participantes/)
  assert.match(manager, /Organização/)
})

test('alteração de visibilidade exige justificativa governada', () => {
  assert.match(manager, /Justificativa da visibilidade/)
  assert.match(manager, /pelo menos 10 caracteres/)
  assert.match(migration, /event\.visibility\.changed/)
})
