import assert from 'node:assert/strict'
import test from 'node:test'

import {
  getInitiativeActionDraftLocks,
  isInitiativeActionCreateDraftDirty,
  isInitiativeActionLifecycleDraftDirty,
} from '../src/modules/initiatives/contracts/initiativeActionDraftGovernance.ts'

function baseFlags() {
  return {
    saving: false,
    editingCapacityAllocation: false,
    capacityAllocationCreationDraftDirty: false,
    responsibilityAssignmentDraftDirty: false,
    progressDraftDirty: false,
    economicsDraftDirty: false,
  }
}

test('mantém todas as mutações liberadas sem rascunho ou salvamento', () => {
  assert.deepEqual(
    getInitiativeActionDraftLocks(baseFlags()),
    {
      capacityAllocationCreationLocked: false,
      responsibilityAssignmentLocked: false,
      progressUpdateLocked: false,
      economicsUpdateLocked: false,
      otherMutationLocked: false,
      closeLocked: false,
    },
  )
})

test('rascunho de capacidade preserva o próprio formulário e bloqueia as demais mutações', () => {
  const result = getInitiativeActionDraftLocks({
    ...baseFlags(),
    capacityAllocationCreationDraftDirty: true,
  })

  assert.equal(result.capacityAllocationCreationLocked, false)
  assert.equal(result.responsibilityAssignmentLocked, true)
  assert.equal(result.progressUpdateLocked, true)
  assert.equal(result.economicsUpdateLocked, true)
  assert.equal(result.otherMutationLocked, true)
  assert.equal(result.closeLocked, true)
})

test('rascunho de responsabilidade preserva o próprio formulário e bloqueia as demais mutações', () => {
  const result = getInitiativeActionDraftLocks({
    ...baseFlags(),
    responsibilityAssignmentDraftDirty: true,
  })

  assert.equal(result.capacityAllocationCreationLocked, true)
  assert.equal(result.responsibilityAssignmentLocked, false)
  assert.equal(result.progressUpdateLocked, true)
  assert.equal(result.economicsUpdateLocked, true)
  assert.equal(result.closeLocked, true)
})

test('rascunho de progresso preserva o próprio formulário e bloqueia as demais mutações', () => {
  const result = getInitiativeActionDraftLocks({
    ...baseFlags(),
    progressDraftDirty: true,
  })

  assert.equal(result.capacityAllocationCreationLocked, true)
  assert.equal(result.responsibilityAssignmentLocked, true)
  assert.equal(result.progressUpdateLocked, false)
  assert.equal(result.economicsUpdateLocked, true)
  assert.equal(result.closeLocked, true)
})

test('rascunho econômico preserva o próprio formulário e bloqueia as demais mutações', () => {
  const result = getInitiativeActionDraftLocks({
    ...baseFlags(),
    economicsDraftDirty: true,
  })

  assert.equal(result.capacityAllocationCreationLocked, true)
  assert.equal(result.responsibilityAssignmentLocked, true)
  assert.equal(result.progressUpdateLocked, true)
  assert.equal(result.economicsUpdateLocked, false)
  assert.equal(result.closeLocked, true)
})

test('salvamento ou edição de alocação bloqueia todos os caminhos mutantes e fechamento', () => {
  for (const flags of [
    { ...baseFlags(), saving: true },
    { ...baseFlags(), editingCapacityAllocation: true },
  ]) {
    const result = getInitiativeActionDraftLocks(flags)

    assert.equal(result.capacityAllocationCreationLocked, true)
    assert.equal(result.responsibilityAssignmentLocked, true)
    assert.equal(result.progressUpdateLocked, true)
    assert.equal(result.economicsUpdateLocked, true)
    assert.equal(result.otherMutationLocked, true)
    assert.equal(result.closeLocked, true)
  }
})

test('detecta somente alterações efetivas no rascunho de criação de ação', () => {
  const defaults = {
    code: '',
    name: '',
    description: '',
    actionType: 'action' as const,
    priority: 'medium' as const,
    changeReason: '',
  }

  assert.equal(
    isInitiativeActionCreateDraftDirty(defaults),
    false,
  )
  assert.equal(
    isInitiativeActionCreateDraftDirty({
      ...defaults,
      name: 'Nova ação',
    }),
    true,
  )
  assert.equal(
    isInitiativeActionCreateDraftDirty({
      ...defaults,
      priority: 'high',
    }),
    true,
  )
})

test('movimentação solicitada não vira rascunho sozinha, mas justificativa sempre vira', () => {
  assert.equal(
    isInitiativeActionLifecycleDraftDirty(
      true,
      'in_progress',
      'in_progress',
      '',
    ),
    false,
  )
  assert.equal(
    isInitiativeActionLifecycleDraftDirty(
      true,
      'in_progress',
      'in_progress',
      'Justificativa operacional.',
    ),
    true,
  )
})

test('mudança manual de situação é rascunho mesmo antes da justificativa', () => {
  assert.equal(
    isInitiativeActionLifecycleDraftDirty(
      false,
      'blocked',
      'in_progress',
      '',
    ),
    true,
  )
})