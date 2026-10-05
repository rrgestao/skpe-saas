import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const journeySection = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)

test('Journey keeps Gates inside the Macrophase tree instead of rendering parallel Gate panels', () => {
  assert.doesNotMatch(journeySection, /<Pem02GatePanel/)
  assert.doesNotMatch(journeySection, /<Pem03GatePanel/)
  assert.doesNotMatch(journeySection, /<Pem04GatePanel/)
  assert.doesNotMatch(journeySection, /<Pem05GatePanel/)
  assert.doesNotMatch(journeySection, /import \{ Pem0[2345]GatePanel/)
  assert.match(journeySection, /item\.children\.map\(\(child\) => renderJourneyItem\(child, level \+ 1\)\)/)
})

test('Journey distinguishes schedule state from strategic validation state', () => {
  assert.match(journeySection, /unscheduled: 'Sem cronograma aprovado'/)
  assert.match(journeySection, /if \(!start && !end\) return 'Sem cronograma aprovado'/)
  assert.match(journeySection, /'Cronograma ainda não aprovado'/)
  assert.doesNotMatch(journeySection, /Sugestão metodológica pendente de validação/)
})

test('default focus expands current in-progress Macrophase only through the hierarchy', () => {
  assert.match(journeySection, /row\.item_type === 'macrophase'/)
  assert.match(journeySection, /row\.item_status === 'in_progress'/)
  assert.match(journeySection, /expandedIds\.add\(currentMacrophase\.item_id\)/)
})
