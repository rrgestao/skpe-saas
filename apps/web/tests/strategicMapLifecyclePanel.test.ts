import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const panel = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicMapLifecyclePanel.tsx', import.meta.url),
  'utf8',
)
const formulation = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicFormulationSection.tsx', import.meta.url),
  'utf8',
)

test('map lifecycle uses canonical readiness and transition workflow', () => {
  assert.match(panel, /get_skpe_strategic_map_readiness/)
  assert.match(panel, /transition_skpe_strategic_map/)
  assert.match(panel, /Enviar para validação/)
  assert.match(panel, /Validar e gerar versão oficial/)
  assert.match(panel, /Devolver para ajustes/)
  assert.match(panel, /Iniciar revisão preservando versão oficial/)
})

test('map validation remains blocked when readiness or PEM-02.05 stage is not ready', () => {
  assert.match(panel, /!readiness\?\.readyForValidation/)
  assert.match(panel, /Workflow bloqueado: PEM-02\.05 ainda não foi liberado/)
  assert.match(panel, /disabled=\{busy \|\| !stageUnlocked \|\| !readiness\?\.readyForValidation\}/)
})

test('official strategic map version is exposed after validation', () => {
  assert.match(panel, /officialMapVersionId/)
  assert.match(panel, /officialMapVersionNumber/)
  assert.match(panel, /Versão oficial preservada/)
  assert.match(panel, /skpe_strategic_map_versions/)
  assert.match(formulation, /<StrategicMapLifecyclePanel/)
})
