import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const journeySection = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)

test('Journey keeps Gates inside their Macrophase hierarchy', () => {
  assert.match(
    journeySection,
    /item\.children\.map\(\(child\) => renderJourneyItem\(child, level \+ 1\)\)/,
  )
  assert.match(journeySection, /project && item\.item_type === 'gate'/)
  assert.match(journeySection, /item\.item_code === 'PEM-02\.GATE'/)
  assert.match(journeySection, /item\.item_code === 'PEM-03\.GATE'/)
  assert.match(journeySection, /item\.item_code === 'PEM-04\.GATE'/)
  assert.match(journeySection, /item\.item_code === 'PEM-05\.GATE'/)
})

test('future Gate panels are not rendered as a parallel top-level stack', () => {
  assert.doesNotMatch(
    journeySection,
    /<Pem02GatePanel[\s\S]*<Pem03GatePanel[\s\S]*<Pem04GatePanel[\s\S]*<Pem05GatePanel[\s\S]*<div className="skpe-journey-tabs"/,
  )
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
