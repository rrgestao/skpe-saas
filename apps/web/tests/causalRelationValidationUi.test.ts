import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const map = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicBscMap.tsx', import.meta.url),
  'utf8',
)

test('causal manager is unavailable outside PEM-02.05 editing stage', () => {
  assert.match(map, /Relações causais só podem ser alteradas durante PEM-02\.05/)
  assert.match(map, /causalManagerOpen && payload && canAdjustLayout/)
  assert.match(map, /\{canAdjustLayout \? \(/)
})

test('registered causal relations expose append-only human validation controls', () => {
  assert.match(map, /skpe_objective_relation_validation_events/)
  assert.match(map, /record_skpe_objective_relation_validation/)
  assert.match(map, /Validada humanamente/)
  assert.match(map, /Rejeitada — requer reformulação/)
  assert.match(map, /Pendente de validação humana/)
  assert.match(map, /Registrar decisão/)
  assert.match(map, /canonical_relation_mutation_requested: false/)
})
