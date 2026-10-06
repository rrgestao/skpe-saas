import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const section = readFileSync(
  join(testDir, '../src/modules/skpe/features/strategy/StrategicFormulationSection.tsx'),
  'utf8',
)
const panel = readFileSync(
  join(testDir, '../src/modules/skpe/features/strategy/StrategicFormulationLifecyclePanel.tsx'),
  'utf8',
)
const gate = readFileSync(
  join(testDir, '../src/modules/skpe/features/journey/Pem02GatePanel.tsx'),
  'utf8',
)

test('Formulação reconhece o lifecycle canônico atual do runtime', () => {
  for (const status of ['draft', 'in_elaboration', 'pending_validation', 'validated', 'pending_approval', 'approved']) {
    assert.match(section, new RegExp(status))
  }
  assert.doesNotMatch(section, /under_review/)
})

test('ratificação institucional da Formulação pertence ao Gate da Macrofase 2', () => {
  assert.match(gate, /get_skpe_pem02_gate_readiness/)
  assert.match(gate, /can_ratify_skpe_governance/)
  assert.match(gate, /ratify_skpe_pem02_gate/)
  assert.match(gate, /formulationRatification/)
  assert.match(gate, /readyForRatification/)
})

test('Formulação não executa transição institucional silenciosa dentro da seção de trabalho', () => {
  assert.doesNotMatch(section, /transition_skpe_formulation/)
  assert.doesNotMatch(section, /open_skpe_monitoring_cycle/)
  assert.match(section, /phase2SuggestionGovernanceNotice/)
})

test('painel de lifecycle preserva segregação entre elaborar validar e aprovar', () => {
  assert.match(panel, /Iniciar elaboração/)
  assert.match(panel, /Submeter à validação/)
  assert.match(panel, /Validar Formulação/)
  assert.match(panel, /Submeter à aprovação/)
  assert.match(panel, /Aprovar Formulação/)
  assert.match(panel, /Devolver para ajustes/)
})
