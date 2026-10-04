import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const summary = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicArchitectureSummary.tsx', import.meta.url),
  'utf8',
)

test('PEM-02.05 exposes canonical strategic map readiness instead of duplicating rules', () => {
  assert.match(summary, /get_skpe_strategic_map_readiness/)
  assert.match(summary, /Prontidão do Modelo Estratégico Futuro/)
  assert.match(summary, /readyForValidation/)
  assert.match(summary, /Pendências de prontidão/)
  assert.match(summary, /Temas ativos/)
  assert.match(summary, /Perspectivas ativas/)
  assert.match(summary, /Objetivos ativos/)
  assert.match(summary, /Relações causais/)
  assert.match(summary, /não aprova o mapa/)
})
