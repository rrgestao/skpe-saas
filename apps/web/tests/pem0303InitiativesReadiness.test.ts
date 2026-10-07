import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004070000_guard_pem0303_completion.sql', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicInitiativePlanSection.tsx', import.meta.url),
  'utf8',
)

test('PEM-03.03 completion reuses canonical initiatives readiness', () => {
  assert.match(migration, /get_skpe_initiatives_readiness/)
  assert.match(migration, /readyForFormulation/)
  assert.match(migration, /skpe_pem0303_completion_guard/)
  assert.match(migration, /completionEvidence/)
  assert.doesNotMatch(migration, /update public\.skpe_initiatives/i)
  assert.doesNotMatch(migration, /update public\.skpe_initiative_portfolio_items/i)
})

test('Initiatives UI exposes canonical portfolio readiness without automating decisions', () => {
  assert.match(section, /get_skpe_initiatives_readiness/)
  assert.match(section, /Prontidão do portfólio estratégico/)
  assert.match(section, /Portfólio ainda possui bloqueadores metodológicos/)
  assert.match(section, /Bloqueadores/)
  assert.match(section, /Recomendações/)
  assert.match(section, /não cria,\s*seleciona nem prioriza iniciativas automaticamente/)
})

test('Initiatives readiness shows portfolio execution metrics', () => {
  assert.match(section, /Selecionadas/)
  assert.match(section, /Candidatas/)
  assert.match(section, /Ações/)
  assert.match(section, /Riscos/)
  assert.match(section, /Resultados/)
})
