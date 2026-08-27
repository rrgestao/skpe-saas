import assert from 'node:assert/strict'
import test from 'node:test'

import {
  canEditInitiativeActionCapacityAllocation,
  validateInitiativeActionCapacityAllocationEdit,
} from '../src/modules/initiatives/contracts/initiativeActionCapacityAllocationEditing.ts'
import type { InitiativeActionCapacityAllocation } from '../src/modules/initiatives/contracts/initiativeActions.ts'

function allocation(
  status: InitiativeActionCapacityAllocation['status'] = 'planned',
): InitiativeActionCapacityAllocation {
  return {
    allocationId: 'allocation-1',
    capacityPeriodId: 'capacity-1',
    organizationPersonId: 'person-1',
    allocationStart: '2026-08-01',
    allocationEnd: '2026-08-31',
    allocatedAmount: 40,
    capacityUnit: 'hours',
    status,
    notes: 'Original',
  }
}

test('permite editar somente alocação planejada ou ativa', () => {
  assert.equal(canEditInitiativeActionCapacityAllocation('planned'), true)
  assert.equal(canEditInitiativeActionCapacityAllocation('active'), true)
  assert.equal(canEditInitiativeActionCapacityAllocation('ended'), false)
  assert.equal(canEditInitiativeActionCapacityAllocation('cancelled'), false)
})

test('valida edição efetiva de alocação planejada', () => {
  const result = validateInitiativeActionCapacityAllocationEdit(
    allocation(),
    {
      allocationStart: '2026-08-02',
      allocationEnd: '2026-08-30',
      allocatedAmount: '32.5',
      notes: 'Ajustada',
      changeReason: 'Ajuste de capacidade aprovado.',
    },
  )

  assert.equal(result.ok, true)

  if (!result.ok) return

  assert.deepEqual(result.value, {
    allocationStart: '2026-08-02',
    allocationEnd: '2026-08-30',
    allocatedAmount: 32.5,
    notes: 'Ajustada',
    changeReason: 'Ajuste de capacidade aprovado.',
  })
})

test('rejeita edição de alocação terminal', () => {
  const result = validateInitiativeActionCapacityAllocationEdit(
    allocation('ended'),
    {
      allocationStart: '2026-08-02',
      allocationEnd: '2026-08-30',
      allocatedAmount: '20',
      notes: '',
      changeReason: 'Tentativa de alteração terminal.',
    },
  )

  assert.equal(result.ok, false)
})

test('rejeita datas invertidas, quantidade negativa e justificativa curta', () => {
  const inverted = validateInitiativeActionCapacityAllocationEdit(
    allocation(),
    {
      allocationStart: '2026-08-20',
      allocationEnd: '2026-08-10',
      allocatedAmount: '20',
      notes: '',
      changeReason: 'Justificativa válida.',
    },
  )
  assert.equal(inverted.ok, false)

  const negative = validateInitiativeActionCapacityAllocationEdit(
    allocation(),
    {
      allocationStart: '2026-08-01',
      allocationEnd: '2026-08-31',
      allocatedAmount: '-1',
      notes: '',
      changeReason: 'Justificativa válida.',
    },
  )
  assert.equal(negative.ok, false)

  const shortReason = validateInitiativeActionCapacityAllocationEdit(
    allocation(),
    {
      allocationStart: '2026-08-01',
      allocationEnd: '2026-08-31',
      allocatedAmount: '20',
      notes: '',
      changeReason: 'curta',
    },
  )
  assert.equal(shortReason.ok, false)
})

test('rejeita edição sem alteração efetiva', () => {
  const result = validateInitiativeActionCapacityAllocationEdit(
    allocation(),
    {
      allocationStart: '2026-08-01',
      allocationEnd: '2026-08-31',
      allocatedAmount: '40',
      notes: 'Original',
      changeReason: 'Reenvio sem mudança efetiva.',
    },
  )

  assert.equal(result.ok, false)
})
