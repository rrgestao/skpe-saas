import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004062500_govern_okr_deployment_readiness.sql', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicOkrDecompositionSection.tsx', import.meta.url),
  'utf8',
)

test('PEM-03.01 readiness prioritizes measurable validated KRs without fixed quantity', () => {
  assert.match(migration, /fixedKrCountRequired',false/)
  assert.match(migration, /krQualityOverFixedQuantity',true/)
  assert.match(migration, /OKR_WITHOUT_KEY_RESULT/)
  assert.match(migration, /KEY_RESULT_NOT_MEASURABLE/)
  assert.match(migration, /KEY_RESULT_VALIDATION_PENDING/)
  assert.doesNotMatch(migration, /LESS_THAN_3_KRS/)
})

test('PEM-03.01 readiness requires OE to OKR traceability and human validation', () => {
  assert.match(migration, /STRATEGIC_OBJECTIVE_WITHOUT_OKR/)
  assert.match(migration, /OKR_WITHOUT_PRIMARY_OBJECTIVE/)
  assert.match(migration, /OKR_VALIDATION_PENDING/)
  assert.match(migration, /humanValidationRequired',true/)
})

test('PEM-03.01 completion fails closed when readiness is not satisfied', () => {
  assert.match(migration, /skpe_guard_pem0301_completion/)
  assert.match(migration, /new\.code<>'PEM-03\.01'/)
  assert.match(migration, /get_skpe_okr_deployment_readiness/)
  assert.match(migration, /não pode ser concluída/)
  assert.match(migration, /completionEvidence/)
})

test('OKR decomposition UI exposes canonical PEM-03.01 readiness', () => {
  assert.match(section, /get_skpe_okr_deployment_readiness/)
  assert.match(section, /Prontidão de OKRs e Resultados-Chave/)
  assert.match(section, /Não existe quantidade fixa/)
  assert.match(section, /OEs aprovados/)
  assert.match(section, /Pendências metodológicas/)
})
