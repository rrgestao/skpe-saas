import assert from 'node:assert/strict'
import test from 'node:test'

import {
  validatePersonCapacityPeriodCreation,
} from '../src/modules/skpe/features/monitoring/personCapacityValidation.ts'

function validValues() {
  return {
    organizationPersonId: 'org-person-1',
    periodStart: '2026-09-01',
    periodEnd: '2026-09-30',
    capacityAmount: '160',
    capacityUnit: 'hours',
    status: 'planned',
    notes:
      'Capacidade mensal explicitamente acordada.',
    changeReason:
      'Capacidade aprovada para setembro de 2026.',
  }
}

test('valida criação explícita de período de capacidade', () => {
  const result =
    validatePersonCapacityPeriodCreation(
      validValues(),
    )

  assert.equal(result.ok, true)

  if (!result.ok) return

  assert.deepEqual(result.value, {
    organizationPersonId: 'org-person-1',
    periodStart: '2026-09-01',
    periodEnd: '2026-09-30',
    capacityAmount: 160,
    capacityUnit: 'hours',
    status: 'planned',
    notes:
      'Capacidade mensal explicitamente acordada.',
    changeReason:
      'Capacidade aprovada para setembro de 2026.',
  })
})

test('aceita capacidade zero sem inferir disponibilidade', () => {
  const result =
    validatePersonCapacityPeriodCreation({
      ...validValues(),
      capacityAmount: '0',
    })

  assert.equal(result.ok, true)

  if (!result.ok) return
  assert.equal(result.value.capacityAmount, 0)
})

test('rejeita capacidade negativa', () => {
  const result =
    validatePersonCapacityPeriodCreation({
      ...validValues(),
      capacityAmount: '-1',
    })

  assert.equal(result.ok, false)
})

test('rejeita período com datas invertidas', () => {
  const result =
    validatePersonCapacityPeriodCreation({
      ...validValues(),
      periodStart: '2026-10-01',
      periodEnd: '2026-09-30',
    })

  assert.equal(result.ok, false)
})

test('rejeita unidade fora do contrato canônico', () => {
  const result =
    validatePersonCapacityPeriodCreation({
      ...validValues(),
      capacityUnit: 'minutes',
    })

  assert.equal(result.ok, false)
})

test('limita situação inicial a planejada ou ativa', () => {
  const result =
    validatePersonCapacityPeriodCreation({
      ...validValues(),
      status: 'closed',
    })

  assert.equal(result.ok, false)
})

test('exige justificativa auditável com dez caracteres', () => {
  const result =
    validatePersonCapacityPeriodCreation({
      ...validValues(),
      changeReason: 'curta',
    })

  assert.equal(result.ok, false)
})
