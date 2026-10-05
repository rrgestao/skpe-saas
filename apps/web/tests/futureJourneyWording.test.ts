import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005040000_align_future_journey_business_wording.sql', import.meta.url),
  'utf8',
)
const parameters = readFileSync(
  new URL('../src/modules/skpe/components/OrganizationParametersPanel.tsx', import.meta.url),
  'utf8',
)

test('future Journey wording aligns PEM-03.01 to OKR deployment rather than rebuilding the strategic map', () => {
  assert.match(migration, /'PEM-03\.01','Desdobramento em OKRs'/)
  assert.match(migration, /Objetivos de OKR qualitativos e Resultados-Chave mensuráveis/)
  assert.doesNotMatch(parameters, /PEM-03\.01 · Mapa Estratégico/)
  assert.match(parameters, /PEM-03\.01 · Desdobramento em OKRs/)
})

test('migration aligns both project Journey and methodology template without touching status', () => {
  assert.match(migration, /update public\.skpe_journey_items/)
  assert.match(migration, /update public\.skpe_methodology_template_items/)
  assert.doesNotMatch(migration, /status\s*=/i)
})
