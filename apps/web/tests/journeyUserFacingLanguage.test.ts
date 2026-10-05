import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const section = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)

test('Journey hides internal item codes from the primary heading', () => {
  assert.doesNotMatch(section, /getItemTypeLabel\(item\.item_type\)\} · \{item\.item_code\}/)
  assert.match(section, /\{getItemTypeLabel\(item\.item_type\)\}/)
})

test('Journey uses user-facing schedule language', () => {
  assert.match(section, /Cronograma aprovado/)
  assert.match(section, /Cronograma proposto/)
  assert.match(section, /Aguardando proposta de cronograma/)
  assert.doesNotMatch(section, /Plano vigente:/)
  assert.doesNotMatch(section, /Não aplicável ao item já concluído/)
})

test('completed items without an approved plan rely on the actual period instead of fake plan text', () => {
  assert.match(section, /item\.item_status === 'completed' && !item\.has_approved_plan/)
  assert.match(section, /Realizado:/)
})

test('draft or pending schedule proposal dates are loaded for user display', () => {
  assert.match(section, /skpe_journey_schedule_versions/)
  assert.match(section, /\['draft', 'pending_approval'\]/)
  assert.match(section, /proposal_start_date/)
  assert.match(section, /proposal_end_date/)
})

test('institutional validation points do not expose generic start or complete actions', () => {
  assert.match(section, /canManageJourney && item\.item_type !== 'gate'/)
})
