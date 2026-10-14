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

test('Journey uses the approved opening baseline for item dates and temporal status', () => {
  assert.match(journeySection, /unscheduled: 'Sem cronograma aprovado'/)
  assert.match(journeySection, /function getApprovedScheduleDates/)
  assert.match(journeySection, /baseline_governance_status === 'approved'/)
  assert.match(journeySection, /getEffectiveTemporalState/)
  assert.match(journeySection, /Linha de Base vigente · reunião de abertura/)
  assert.doesNotMatch(journeySection, /project\?\.project_status === 'active'/)
  assert.doesNotMatch(journeySection, /Cronograma ainda não aprovado/)
  assert.doesNotMatch(journeySection, /Sugestão metodológica pendente de validação/)
})

test('Journey uses canonical WorkspaceTabs for the four consolidated views', () => {
  assert.match(journeySection, /import \{ WorkspaceTabs \}/)
  assert.match(journeySection, /const journeyViewTabs:[\s\S]*label: 'Estrutura'/)
  assert.match(journeySection, /label: 'Plano do Projeto'/)
  assert.match(journeySection, /label: 'Cronograma \(Gantt\)'/)
  assert.match(journeySection, /label: 'Gantt interativo'/)
  assert.match(journeySection, /<WorkspaceTabs[\s\S]*tabs=\{journeyViewTabs\}/)
  assert.doesNotMatch(journeySection, /className="skpe-journey-view-tabs"/)
  assert.ok(journeySection.indexOf('skpe-journey-summary-stack') < journeySection.indexOf('<WorkspaceTabs'))
  assert.ok(journeySection.indexOf('<WorkspaceTabs') < journeySection.indexOf('{errorMessage && ('))
})

test('default focus expands current in-progress Macrophase only through the hierarchy', () => {
  assert.match(journeySection, /row\.item_type === 'macrophase'/)
  assert.match(journeySection, /row\.item_status === 'in_progress'/)
  assert.match(journeySection, /expandedIds\.add\(currentMacrophase\.item_id\)/)
})
