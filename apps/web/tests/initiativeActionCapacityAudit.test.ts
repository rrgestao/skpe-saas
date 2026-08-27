import assert from 'node:assert/strict'
import test from 'node:test'

import {
  formatInitiativeActionCapacityAuditAction,
  summarizeInitiativeActionCapacityAuditChange,
} from '../src/modules/initiatives/contracts/initiativeActionCapacityAudit.ts'

test('resume criação de alocação com campos auditáveis', () => {
  const changes = summarizeInitiativeActionCapacityAuditChange({
    previousData: null,
    newData: {
      allocation_start: '2026-08-27',
      allocation_end: '2026-08-31',
      allocated_amount: 12.5,
      status: 'planned',
      notes: 'Reserva inicial',
    },
  })

  assert.deepEqual(changes, [
    'Início: 2026-08-27',
    'Fim: 2026-08-31',
    'Quantidade alocada: 12,5',
    'Situação: planned',
    'Observações: Reserva inicial',
  ])
})

test('resume somente campos alterados da alocação', () => {
  const changes = summarizeInitiativeActionCapacityAuditChange({
    previousData: {
      allocation_start: '2026-08-27',
      allocation_end: '2026-08-31',
      allocated_amount: 12.5,
      status: 'planned',
      notes: 'Reserva inicial',
    },
    newData: {
      allocation_start: '2026-08-27',
      allocation_end: '2026-08-31',
      allocated_amount: 12.5,
      status: 'active',
      notes: 'Reserva inicial',
    },
  })

  assert.deepEqual(changes, [
    'Situação: planned → active',
  ])
})

test('traduz ações canônicas da auditoria de alocação', () => {
  assert.equal(
    formatInitiativeActionCapacityAuditAction('capacity_allocation.created'),
    'Alocação criada',
  )
  assert.equal(
    formatInitiativeActionCapacityAuditAction('capacity_allocation.updated'),
    'Alocação atualizada',
  )
  assert.equal(
    formatInitiativeActionCapacityAuditAction('custom.action'),
    'custom.action',
  )
})
