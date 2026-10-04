import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004234500_govern_pem0203_positioning_readiness.sql', import.meta.url),
  'utf8',
)
const panel = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicPositioningReadinessPanel.tsx', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicPositioningSection.tsx', import.meta.url),
  'utf8',
)

test('PEM-02.03 readiness requires a human decision for every Theme and Perspective', () => {
  assert.match(migration, /PEM0203_THEME_DECISIONS_PENDING/)
  assert.match(migration, /PEM0203_PERSPECTIVE_DECISIONS_PENDING/)
  assert.match(migration, /humanDecisionRequiredForEveryTheme',true/)
  assert.match(migration, /humanDecisionRequiredForEveryPerspective',true/)
})

test('PEM-02.03 readiness requires reconciled v26 counterproof', () => {
  assert.match(migration, /PEM0203_V26_COUNTERPROOF_PENDING/)
  assert.match(migration, /documentary_counterproof/)
  assert.match(migration, /counterproofRequiredBeforeCompletion',true/)
  assert.match(migration, /reportedAttestationIsNotEnough',true/)
})

test('PEM-02.03 blocks unresolved adjust replace or remove decisions', () => {
  assert.match(migration, /canonical_mutation_applied/)
  assert.match(migration, /PEM0203_CANONICAL_MUTATION_PENDING/)
  assert.match(migration, /canonicalMutationMustBeResolvedBeforeCompletion',true/)
})

test('PEM-02.03 completion is fail-closed and stores readiness evidence', () => {
  assert.match(migration, /skpe_guard_pem0203_completion/)
  assert.match(migration, /get_skpe_pem0203_positioning_readiness/)
  assert.match(migration, /não pode ser concluída/)
  assert.match(migration, /completionEvidence/)
})

test('Positioning UI exposes canonical PEM-02.03 readiness', () => {
  assert.match(panel, /get_skpe_pem0203_positioning_readiness/)
  assert.match(panel, /Prontidão de PEM-02\.03/)
  assert.match(panel, /Temas decididos/)
  assert.match(panel, /Perspectivas decididas/)
  assert.match(panel, /Contraprova v26/)
  assert.match(panel, /planilha \+ HTML v26/)
  assert.match(section, /<StrategicPositioningReadinessPanel/)
})
