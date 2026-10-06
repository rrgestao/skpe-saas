import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const cockpit = readFileSync(
  new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url),
  'utf8',
)
const artifacts = readFileSync(
  new URL('../src/modules/skpe/features/artifacts/MethodologyArtifactsSection.tsx', import.meta.url),
  'utf8',
)
const delivery = readFileSync(
  new URL('../src/modules/skpe/DeliveryKitDialog.tsx', import.meta.url),
  'utf8',
)

test('executive outputs are discoverable as a first-class SK-PE navigation area', () => {
  assert.match(cockpit, /activeSection === 'artifacts'[\s\S]*?Entregas e Relatórios/)
  assert.match(cockpit, /navigateToSection\('artifacts'\)/)
  assert.match(cockpit, /hidden=!\{?canViewArtifacts\}?|hidden=\{!canViewArtifacts\}/)
  assert.match(cockpit, /case 'artifacts':[\s\S]*?Entregas e Relatórios/)
})

test('outputs center explains that reports and kits come from governed artifacts', () => {
  assert.match(artifacts, /Central de saídas executivas/)
  assert.match(artifacts, /Gere relatórios e kits de entrega a partir dos artefatos governados/)
  assert.match(artifacts, /Gerar entregas e relatório/)
  assert.match(delivery, /Gerar Relat.rio Executivo/)
  assert.match(delivery, /Gerar Kit em ZIP/)
  assert.match(artifacts, /Relatório Executivo do PE/)
  assert.match(artifacts, /Kit Final de Entregas/)
  assert.match(artifacts, /Desempenho e Portfólio/)
  assert.match(cockpit, /onOpenPerformanceOutputs=\{\(\) => navigateToSection\('overview'\)\}/)
})
