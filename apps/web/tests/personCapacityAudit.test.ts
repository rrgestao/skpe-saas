import assert from 'node:assert/strict'
import test from 'node:test'

import {
  formatPersonCapacityAuditAction,
  formatPersonCapacityAuditActor,
  summarizePersonCapacityAuditChange,
} from '../src/modules/skpe/features/monitoring/personCapacityAudit.ts'

test('resume criação de período com campos auditáveis', () => {
  const changes = summarizePersonCapacityAuditChange({
    previousData: null,
    newData: {
      status: 'planned',
      period_start: '2026-09-01',
      period_end: '2026-09-30',
      capacity_amount: 160,
      capacity_unit: 'hours',
      notes: 'Capacidade aprovada.',
    },
  })

  assert.deepEqual(changes, [
    'Situação: planned',
    'Início: 2026-09-01',
    'Fim: 2026-09-30',
    'Capacidade: 160',
    'Unidade: hours',
    'Observações: Capacidade aprovada.',
  ])
})

test('resume somente campos efetivamente alterados', () => {
  const changes = summarizePersonCapacityAuditChange({
    previousData: {
      status: 'planned',
      period_start: '2026-09-01',
      period_end: '2026-09-30',
      capacity_amount: 160,
      capacity_unit: 'hours',
      notes: null,
    },
    newData: {
      status: 'active',
      period_start: '2026-09-01',
      period_end: '2026-09-30',
      capacity_amount: 160,
      capacity_unit: 'hours',
      notes: null,
    },
  })

  assert.deepEqual(changes, ['Situação: planned → active'])
})

test('traduz ações canônicas conhecidas sem inventar outras', () => {
  assert.equal(
    formatPersonCapacityAuditAction('capacity_period.created'),
    'Período criado',
  )
  assert.equal(
    formatPersonCapacityAuditAction('capacity_period.updated'),
    'Período atualizado',
  )
  assert.equal(
    formatPersonCapacityAuditAction('capacity_period.custom'),
    'capacity_period.custom',
  )
})

test('formata ator resolvido da auditoria de período', () => {
  assert.equal(
    formatPersonCapacityAuditActor({
      actorUserId: 'user-1',
      actorName: 'Maria Silva',
    }),
    'Maria Silva',
  )
})

test('expõe fallback quando usuário não possui nome organizacional resolvido', () => {
  assert.equal(
    formatPersonCapacityAuditActor({
      actorUserId: 'user-2',
      actorName: null,
    }),
    'Usuário identificado sem nome organizacional disponível',
  )
})

test('expõe fallback para sistema ou automação sem ator de usuário', () => {
  assert.equal(
    formatPersonCapacityAuditActor({
      actorUserId: null,
      actorName: null,
    }),
    'Sistema ou automação',
  )
})
