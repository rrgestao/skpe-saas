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

test('Gate communicates ratification instead of requiring preapproval', () => {
  assert.match(panel, /Formulação Estratégica/)
  assert.match(panel, /Plano de Evolução/)
  assert.match(panel, /prontos para validação/)
  assert.match(panel, /antes de iniciar o Desdobramento Estratégico/)
  assert.doesNotMatch(panel, /Formulação Estratégica aprovada/)
  assert.doesNotMatch(panel, /Plano de Evolução corrente/)
})

test('Gate approval remains blocked until canonical readiness is clean', () => {
  assert.match(panel, /!readiness\?\.readyForClosure/)
  assert.match(panel, /Macrofase 2 ainda possui pendências que impedem a decisão institucional/)
  assert.match(panel, /Macrofase 2 concluída/)
})

test('institutional Gate panel is embedded in the Gate item hierarchy', () => {
  assert.match(journey, /import \{ Pem02GatePanel \}/)
  assert.match(journey, /item\.item_type === 'gate'/)
  assert.match(journey, /item\.item_code === 'PEM-02\.GATE'/)
  assert.match(journey, /<Pem02GatePanel/)
})
