import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const contracts = readFileSync(
  new URL('../src/modules/skpe/contracts/evolution.ts', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/evolution/EvolutionCyclesSection.tsx', import.meta.url),
  'utf8',
)

test('scenario cycle contract allows pending temporalization', () => {
  assert.match(contracts, /period_start: string \| null/)
  assert.match(contracts, /period_end: string \| null/)
})

test('Evolution UI labels conceptual cycles without fake dates', () => {
  assert.match(section, /Temporalização pendente/)
  assert.match(section, /proposed: 'Proposto'/)
  assert.match(section, /under_review: 'Em revisão'/)
})
