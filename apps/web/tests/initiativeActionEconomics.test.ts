import assert from 'node:assert/strict'
import test from 'node:test'

import {
  canManageInitiativeActionResponsibilities,
  canUpdateInitiativeActionEconomics,
  deriveInitiativeActionCapacityAllocationRange,
  formatInitiativeActionCapacityAmount,
  formatInitiativeActionResponsibilityType,
  getInitiativeActionCapacityAlert,
  validateInitiativeActionCapacityAllocation,
  validateInitiativeActionEconomics,
  validateInitiativeActionResponsibilityAssignment,
} from '../src/modules/initiatives/contracts/initiativeActions.ts'

function validValues() {
  return {
    plannedCost: '1000.50',
    actualCost: '800.25',
    currencyCode: 'brl',
    estimatedEffort: '40',
    actualEffort: '32',
    effortUnit: 'hours',
    changeReason:
      'Atualização econômica mensal da ação.',
  }
}

test('normaliza e valida execução econômica da ação', () => {
  const result =
    validateInitiativeActionEconomics(
      validValues(),
    )

  assert.equal(result.ok, true)

  if (!result.ok) return

  assert.deepEqual(result.value, {
    plannedCost: 1000.5,
    actualCost: 800.25,
    currencyCode: 'BRL',
    estimatedEffort: 40,
    actualEffort: 32,
    effortUnit: 'hours',
    changeReason:
      'Atualização econômica mensal da ação.',
  })
})

test('aceita custos e esforços vazios como nulos', () => {
  const result =
    validateInitiativeActionEconomics({
      ...validValues(),
      plannedCost: '',
      actualCost: '',
      estimatedEffort: '',
      actualEffort: '',
      effortUnit: '',
    })

  assert.equal(result.ok, true)

  if (!result.ok) return

  assert.equal(result.value.plannedCost, null)
  assert.equal(result.value.actualCost, null)
  assert.equal(
    result.value.estimatedEffort,
    null,
  )
  assert.equal(result.value.actualEffort, null)
  assert.equal(result.value.effortUnit, null)
})

test('rejeita custo ou esforço negativo', () => {
  const costResult =
    validateInitiativeActionEconomics({
      ...validValues(),
      actualCost: '-1',
    })

  assert.equal(costResult.ok, false)

  const effortResult =
    validateInitiativeActionEconomics({
      ...validValues(),
      actualEffort: '-0.1',
    })

  assert.equal(effortResult.ok, false)
})

test('exige moeda ISO com exatamente três letras', () => {
  const result =
    validateInitiativeActionEconomics({
      ...validValues(),
      currencyCode: 'REAL',
    })

  assert.equal(result.ok, false)
})

test('exige unidade quando houver esforço', () => {
  const result =
    validateInitiativeActionEconomics({
      ...validValues(),
      effortUnit: '',
    })

  assert.equal(result.ok, false)
})

test('rejeita unidade de esforço fora do contrato', () => {
  const result =
    validateInitiativeActionEconomics({
      ...validValues(),
      effortUnit: 'minutes',
    })

  assert.equal(result.ok, false)
})

test('exige justificativa com pelo menos dez caracteres', () => {
  const result =
    validateInitiativeActionEconomics({
      ...validValues(),
      changeReason: 'curta',
    })

  assert.equal(result.ok, false)
})

test('bloqueia edição econômica em lifecycle encerrado', () => {
  assert.equal(
    canUpdateInitiativeActionEconomics(
      'completed',
    ),
    false,
  )
  assert.equal(
    canUpdateInitiativeActionEconomics(
      'cancelled',
    ),
    false,
  )
  assert.equal(
    canUpdateInitiativeActionEconomics(
      'archived',
    ),
    false,
  )
  assert.equal(
    canUpdateInitiativeActionEconomics(
      'in_progress',
    ),
    true,
  )
})
test('traduz tipos conhecidos de responsabilidade da ação', () => {
  assert.equal(
    formatInitiativeActionResponsibilityType(
      'owner',
    ),
    'Responsável principal',
  )
  assert.equal(
    formatInitiativeActionResponsibilityType(
      'co_owner',
    ),
    'Corresponsável',
  )
})

test('humaniza tipo de responsabilidade não catalogado no frontend', () => {
  assert.equal(
    formatInitiativeActionResponsibilityType(
      'technical_reviewer',
    ),
    'Technical reviewer',
  )
})
test('valida atribuição governada de responsabilidade', () => {
  const result =
    validateInitiativeActionResponsibilityAssignment({
      organizationPersonId: 'person-link-1',
      responsibilityType: 'owner',
      allocationPercentage: '50',
      authorityLevel: 'tactical',
      validFrom: '2026-08-27',
      validUntil: '2026-12-31',
      assignmentReason:
        'Responsabilidade operacional definida.',
      changeReason:
        'Atribuição aprovada para execução da ação.',
    })

  assert.equal(result.ok, true)

  if (!result.ok) return

  assert.equal(
    result.value.allocationPercentage,
    50,
  )
  assert.equal(
    result.value.authorityLevel,
    'tactical',
  )
})

test('rejeita alocação fora de 0 a 100', () => {
  const result =
    validateInitiativeActionResponsibilityAssignment({
      organizationPersonId: 'person-link-1',
      responsibilityType: 'executor',
      allocationPercentage: '120',
      authorityLevel: '',
      validFrom: '',
      validUntil: '',
      assignmentReason: '',
      changeReason:
        'Atribuição operacional da responsabilidade.',
    })

  assert.equal(result.ok, false)
})

test('rejeita vigência invertida na responsabilidade', () => {
  const result =
    validateInitiativeActionResponsibilityAssignment({
      organizationPersonId: 'person-link-1',
      responsibilityType: 'executor',
      allocationPercentage: '',
      authorityLevel: '',
      validFrom: '2026-10-01',
      validUntil: '2026-09-01',
      assignmentReason: '',
      changeReason:
        'Atribuição operacional da responsabilidade.',
    })

  assert.equal(result.ok, false)
})

test('bloqueia gestão de responsabilidade em ação terminal', () => {
  assert.equal(
    canManageInitiativeActionResponsibilities(
      'completed',
    ),
    false,
  )
  assert.equal(
    canManageInitiativeActionResponsibilities(
      'cancelled',
    ),
    false,
  )
  assert.equal(
    canManageInitiativeActionResponsibilities(
      'archived',
    ),
    false,
  )
  assert.equal(
    canManageInitiativeActionResponsibilities(
      'in_progress',
    ),
    true,
  )
})
test('formata quantidade de capacidade sem converter unidade', () => {
  assert.equal(
    formatInitiativeActionCapacityAmount(
      12.5,
      'hours',
    ),
    '12,5 h',
  )
  assert.equal(
    formatInitiativeActionCapacityAmount(
      3,
      'points',
    ),
    '3 pts',
  )
})

test('sinaliza sobrealocação explícita de capacidade', () => {
  const alert = getInitiativeActionCapacityAlert([
    {
      capacityPeriodId: 'cap-1',
      periodStart: '2026-08-01',
      periodEnd: '2026-08-31',
      capacityUnit: 'hours',
      capacityStatus: 'active',
      capacityAmount: 100,
      allocatedCurrentAmount: 120,
      availableAmount: -20,
      utilizationPercentage: 120,
      overallocationAmount: 20,
      isOverallocated: true,
      currentAllocationCount: 3,
    },
  ])

  assert.equal(
    alert,
    'Há sobrealocação explícita no período consultado.',
  )
})

test('informa ausência de capacidade quantitativa cadastrada', () => {
  assert.equal(
    getInitiativeActionCapacityAlert([]),
    'Não há capacidade quantitativa cadastrada para a pessoa no período da ação.',
  )
})
test('deriva intervalo de alocação pela interseção com a ação', () => {
  const capacity = {
    capacityPeriodId: 'cap-1',
    periodStart: '2026-08-01',
    periodEnd: '2026-08-31',
    capacityUnit: 'hours',
    capacityStatus: 'active',
    capacityAmount: 100,
    allocatedCurrentAmount: 20,
    availableAmount: 80,
    utilizationPercentage: 20,
    overallocationAmount: 0,
    isOverallocated: false,
    currentAllocationCount: 1,
  }

  assert.deepEqual(
    deriveInitiativeActionCapacityAllocationRange(
      capacity,
      '2026-08-10',
      '2026-09-15',
    ),
    {
      allocationStart: '2026-08-10',
      allocationEnd: '2026-08-31',
    },
  )
})

test('valida criação de alocação quantitativa da ação', () => {
  const capacity = {
    capacityPeriodId: 'cap-1',
    periodStart: '2026-08-01',
    periodEnd: '2026-08-31',
    capacityUnit: 'hours',
    capacityStatus: 'active',
    capacityAmount: 100,
    allocatedCurrentAmount: 80,
    availableAmount: 20,
    utilizationPercentage: 80,
    overallocationAmount: 0,
    isOverallocated: false,
    currentAllocationCount: 2,
  }

  const result =
    validateInitiativeActionCapacityAllocation(
      {
        capacityPeriodId: 'cap-1',
        allocationStart: '2026-08-10',
        allocationEnd: '2026-08-20',
        allocatedAmount: '30',
        status: 'planned',
        notes: 'Alocação planejada.',
        changeReason:
          'Alocação aprovada para execução desta ação.',
      },
      capacity,
    )

  assert.equal(result.ok, true)

  if (!result.ok) return

  assert.equal(
    result.value.allocatedAmount,
    30,
  )
  assert.equal(
    result.value.status,
    'planned',
  )
})

test('não bloqueia quantidade acima da disponibilidade no frontend', () => {
  const capacity = {
    capacityPeriodId: 'cap-1',
    periodStart: '2026-08-01',
    periodEnd: '2026-08-31',
    capacityUnit: 'hours',
    capacityStatus: 'active',
    capacityAmount: 100,
    allocatedCurrentAmount: 95,
    availableAmount: 5,
    utilizationPercentage: 95,
    overallocationAmount: 0,
    isOverallocated: false,
    currentAllocationCount: 2,
  }

  const result =
    validateInitiativeActionCapacityAllocation(
      {
        capacityPeriodId: 'cap-1',
        allocationStart: '2026-08-10',
        allocationEnd: '2026-08-20',
        allocatedAmount: '20',
        status: 'active',
        notes: '',
        changeReason:
          'Sobrealocação consciente para prioridade estratégica.',
      },
      capacity,
    )

  assert.equal(result.ok, true)
})

test('rejeita alocação fora do período de capacidade', () => {
  const capacity = {
    capacityPeriodId: 'cap-1',
    periodStart: '2026-08-01',
    periodEnd: '2026-08-31',
    capacityUnit: 'hours',
    capacityStatus: 'active',
    capacityAmount: 100,
    allocatedCurrentAmount: 0,
    availableAmount: 100,
    utilizationPercentage: 0,
    overallocationAmount: 0,
    isOverallocated: false,
    currentAllocationCount: 0,
  }

  const result =
    validateInitiativeActionCapacityAllocation(
      {
        capacityPeriodId: 'cap-1',
        allocationStart: '2026-07-31',
        allocationEnd: '2026-08-20',
        allocatedAmount: '10',
        status: 'planned',
        notes: '',
        changeReason:
          'Alocação planejada para a execução da ação.',
      },
      capacity,
    )

  assert.equal(result.ok, false)
})
