import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const journey = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)
const cockpit = readFileSync(
  new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url),
  'utf8',
)
const artifacts = readFileSync(
  new URL('../src/modules/skpe/features/artifacts/MethodologyArtifactsSection.tsx', import.meta.url),
  'utf8',
)

test('artifact access is available for opened Macrophases, phases, activities and deliverables', () => {
  assert.match(journey, /\['macrophase', 'phase', 'activity', 'deliverable'\]/)
  assert.match(journey, /\['in_progress', 'completed'\]/)
  assert.match(journey, /Abrir artefatos da etapa/)
  assert.doesNotMatch(journey, /Gerar artefatos e evidências/)
})

test('opening artifacts from Journey ensures the package before navigation', () => {
  assert.match(cockpit, /ensure_skpe_journey_item_artifacts/)
  assert.match(cockpit, /skpe:artifacts:item-code/)
  assert.match(cockpit, /navigateToSection\('artifacts'\)/)
})

test('artifact screen automatically filters to the Journey item requested', () => {
  assert.match(artifacts, /sessionStorage\.getItem\('skpe:artifacts:item-code'\)/)
  assert.match(artifacts, /setPhaseFilter\(requestedItemCode\)/)
})

test('markdown-only generated artifacts can be visualized and downloaded', () => {
  assert.match(artifacts, /visualizeTextVersion/)
  assert.match(artifacts, /downloadTextVersion/)
  assert.match(artifacts, /text\/markdown;charset=utf-8/)
  assert.match(artifacts, />Visualizar</)
  assert.match(artifacts, />Baixar</)
})
