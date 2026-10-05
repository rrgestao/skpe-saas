import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const formulation = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicFormulationSection.tsx', import.meta.url),
  'utf8',
)
const okr = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicOkrWorkspace.tsx', import.meta.url),
  'utf8',
)
const indicators = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicIndicatorWorkspace.tsx', import.meta.url),
  'utf8',
)
const governance = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicExecutionGovernanceWorkspace.tsx', import.meta.url),
  'utf8',
)
const communication = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicCommunicationMobilizationWorkspace.tsx', import.meta.url),
  'utf8',
)
const capabilities = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicCapabilitiesChangeWorkspace.tsx', import.meta.url),
  'utf8',
)
const risks = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicImplementationRiskWorkspace.tsx', import.meta.url),
  'utf8',
)

test('PEM-03.01 provides full OKR and KR proposal workflow', () => {
  assert.match(okr, /configure_skpe_okr_package/)
  assert.match(okr, /upsert_skpe_okr_cycle/)
  assert.match(okr, /upsert_skpe_okr/)
  assert.match(okr, /link_skpe_okr_objective/)
  assert.match(okr, /upsert_skpe_key_result/)
  assert.match(okr, /transition_skpe_okr_package/)
  assert.match(okr, /fixedKrCountRequired:false/)
  assert.match(okr, /humanValidationRequired:true/)
})

test('PEM-03.02 provides full indicators and annual-target proposal workflow', () => {
  assert.match(indicators, /configure_skpe_indicator_package/)
  assert.match(indicators, /upsert_skpe_strategic_indicator/)
  assert.match(indicators, /upsert_skpe_indicator_target/)
  assert.match(indicators, /transition_skpe_indicator_package/)
  assert.match(indicators, /annualized/)
  assert.match(indicators, /humanValidationRequired:true/)
})

test('PEM-03.04 configures and validates execution governance without automatic decision', () => {
  assert.match(governance, /configure_skpe_monitoring_package/)
  assert.match(governance, /transition_skpe_monitoring_package/)
  assert.match(governance, /Nenhuma validação ocorreu automaticamente/)
})

test('PEM-04.02 supports communication proposal CRUD and human validation without sending messages', () => {
  assert.match(communication, /ensure_skpe_pem0402_communication_package/)
  assert.match(communication, /upsert_skpe_pem0402_communication_item/)
  assert.match(communication, /transition_skpe_pem0402_communication_package/)
  assert.match(communication, /Nenhuma comunicação foi enviada/)
})

test('PEM-04.03 supports capability/change applicability, proposal CRUD and validation', () => {
  assert.match(capabilities, /configure_skpe_pem0403_change_package/)
  assert.match(capabilities, /upsert_skpe_pem0403_change_item/)
  assert.match(capabilities, /transition_skpe_pem0403_change_package/)
  assert.match(capabilities, /humanValidationRequired: true/)
})

test('PEM-04.04 uses existing initiative-risk authority and explicit human validation', () => {
  assert.match(risks, /skpe_initiative_risks/)
  assert.match(risks, /upsert_skpe_initiative_risk/)
  assert.match(risks, /transition_skpe_initiative_risk_validation/)
  assert.match(risks, /Nenhuma aceitação ou decisão institucional foi criada automaticamente/)
})

test('future workspaces are wired into the formulation area', () => {
  for (const component of [
    'StrategicOkrWorkspace',
    'StrategicIndicatorWorkspace',
    'StrategicExecutionGovernanceWorkspace',
    'StrategicCommunicationMobilizationWorkspace',
    'StrategicCapabilitiesChangeWorkspace',
    'StrategicImplementationRiskWorkspace',
  ]) {
    assert.match(formulation, new RegExp(component))
  }
})
