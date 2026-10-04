import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const panel = readFileSync(
  new URL('../src/modules/skpe/features/journey/Pem02GatePanel.tsx', import.meta.url),
  'utf8',
)
const journey = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)

test('PEM-02 gate UI uses canonical readiness and governed ratification', () => {
  assert.match(panel, /get_skpe_pem02_gate_readiness/)
  assert.match(panel, /ratify_skpe_pem02_gate/)
  assert.match(panel, /can_ratify_skpe_governance/)
  assert.match(panel, /Aprovar Macrofase 2/)
  assert.match(panel, /Aprovar com ressalvas/)
  assert.match(panel, /Devolver para ajustes/)
})

test('gate approval remains blocked until canonical readiness is clean', () => {
  assert.match(panel, /!readiness\?\.readyForClosure/)
  assert.match(panel, /PEM-02\.GATE ainda possui pendências bloqueantes/)
  assert.match(panel, /Macrofase PEM-02 concluída/)
  assert.match(panel, /Formulação Estratégica aprovada/)
  assert.match(panel, /Plano de Evolução corrente/)
})

test('journey exposes the institutional gate panel', () => {
  assert.match(journey, /import \{ Pem02GatePanel \}/)
  assert.match(journey, /<Pem02GatePanel/)
  assert.match(journey, /projectId=\{project\.project_id\}/)
})
