import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const panel = readFileSync(
  new URL('../src/modules/skpe/features/journey/Pem02GatePanel.tsx', import.meta.url),
  'utf8',
)

test('Macrophase 2 Gate explains that Macrophase 3 cannot start before ratification', () => {
  assert.match(panel, /Macrofase 3 permanece bloqueada/)
  assert.match(panel, /antes de iniciar o Desdobramento Estratégico/)
})

test('Gate cards show business language instead of internal implementation values', () => {
  assert.match(panel, /Macrofase 2 concluída/)
  assert.match(panel, /Horizonte Estratégico/)
  assert.match(panel, /Formulação Estratégica/)
  assert.match(panel, /Plano de Evolução/)
  assert.match(panel, /Prontidão para decisão/)
  assert.doesNotMatch(panel, /<small>PEM-02\.GATE<\/small>/)
  assert.doesNotMatch(panel, /Readiness sem bloqueadores/)
  assert.doesNotMatch(panel, /pronta para decisão no Gate/)
})

test('Strategic Horizon is rendered by year instead of UUID', () => {
  assert.match(panel, /strategicHorizonStartYear/)
  assert.match(panel, /strategicHorizonEndYear/)
  assert.match(panel, /horizonLabel/)
  assert.doesNotMatch(panel, /value: readiness\.strategicHorizonId \?\?/)
})

test('successful decision message does not expose internal decision identifiers', () => {
  assert.match(panel, /Decisão institucional registrada/)
  assert.doesNotMatch(panel, /sem identificador/)
})
