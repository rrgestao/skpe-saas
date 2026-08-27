import assert from 'node:assert/strict'
import test from 'node:test'

import {
  canUpdateInitiativeActionEconomics,
  validateInitiativeActionEconomics,
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
