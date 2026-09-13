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

test('Formulação usa o lifecycle canônico atual do runtime', () => {
  for (const status of ['draft', 'in_elaboration', 'pending_validation', 'validated', 'pending_approval', 'approved']) {
    assert.match(section, new RegExp(status))
  }
  assert.doesNotMatch(section, /under_review/)
})
test('lifecycle consulta prontidão e autoridades distintas', () => {
  assert.match(section, /get_skpe_formulation_readiness/)
  assert.match(section, /get_skpe_monitoring_package_readiness/)
  assert.match(section, /can_manage_skpe_formulation/)
  assert.match(section, /can_validate_skpe_formulation/)
  assert.match(section, /can_approve_skpe_formulation/)
})

test('transições reutilizam somente transition_skpe_formulation', () => {
  assert.match(section, /transition_skpe_formulation/)
  assert.doesNotMatch(section, /open_skpe_monitoring_cycle/)
})

test('painel preserva segregação entre elaborar validar e aprovar', () => {
  assert.match(panel, /Iniciar elaboração/)
  assert.match(panel, /Submeter à validação/)
  assert.match(panel, /Validar Formulação/)
  assert.match(panel, /Submeter à aprovação/)
  assert.match(panel, /Aprovar Formulação/)
  assert.match(panel, /Devolver para ajustes/)
})
