import assert from 'node:assert/strict'
import test from 'node:test'

import {
  getAllowedPersonCapacityPeriodTransitions,
  validatePersonCapacityPeriodCreation,
  validatePersonCapacityPeriodTransition,
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

test('expõe somente transições permitidas do lifecycle', () => {
  assert.deepEqual(
    getAllowedPersonCapacityPeriodTransitions('planned'),
    ['active', 'cancelled'],
  )
  assert.deepEqual(
    getAllowedPersonCapacityPeriodTransitions('active'),
    ['closed', 'cancelled'],
  )
  assert.deepEqual(
    getAllowedPersonCapacityPeriodTransitions('closed'),
    [],
  )
  assert.deepEqual(
    getAllowedPersonCapacityPeriodTransitions('cancelled'),
    [],
  )
})

test('aceita planned para active com justificativa auditável', () => {
  const result = validatePersonCapacityPeriodTransition({
    currentStatus: 'planned',
    targetStatus: 'active',
    currentAllocationCount: 0,
    changeReason: 'Capacidade liberada para execução.',
  })

  assert.equal(result.ok, true)
})

test('rejeita planned para closed', () => {
  const result = validatePersonCapacityPeriodTransition({
    currentStatus: 'planned',
    targetStatus: 'closed',
    currentAllocationCount: 0,
    changeReason: 'Tentativa inválida de encerramento direto.',
  })

  assert.equal(result.ok, false)
})

test('rejeita active para planned', () => {
  const result = validatePersonCapacityPeriodTransition({
    currentStatus: 'active',
    targetStatus: 'planned',
    currentAllocationCount: 0,
    changeReason: 'Tentativa inválida de retorno ao planejamento.',
  })

  assert.equal(result.ok, false)
})

test('rejeita alteração de período terminal', () => {
  const result = validatePersonCapacityPeriodTransition({
    currentStatus: 'closed',
    targetStatus: 'active',
    currentAllocationCount: 0,
    changeReason: 'Tentativa inválida de reabertura do período.',
  })

  assert.equal(result.ok, false)
})

test('bloqueia terminalização com alocação aberta', () => {
  const result = validatePersonCapacityPeriodTransition({
    currentStatus: 'active',
    targetStatus: 'closed',
    currentAllocationCount: 1,
    changeReason: 'Encerramento solicitado para o período ativo.',
  })

  assert.equal(result.ok, false)
})

test('aceita terminalização sem alocações abertas', () => {
  const result = validatePersonCapacityPeriodTransition({
    currentStatus: 'active',
    targetStatus: 'closed',
    currentAllocationCount: 0,
    changeReason: 'Período concluído sem alocações em aberto.',
  })

  assert.equal(result.ok, true)

  if (!result.ok) return
  assert.equal(result.value.targetStatus, 'closed')
})
