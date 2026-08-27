import type { InitiativeActionCapacityAuditEntry } from '../data/initiativeActionCapacityAuditData'

const trackedFields = [
  'allocation_start',
  'allocation_end',
  'allocated_amount',
  'status',
  'notes',
] as const

const fieldLabels: Record<(typeof trackedFields)[number], string> = {
  allocation_start: 'Início',
  allocation_end: 'Fim',
  allocated_amount: 'Quantidade alocada',
  status: 'Situação',
  notes: 'Observações',
}

function formatAuditValue(value: unknown) {
  if (value === null || value === undefined || value === '') {
    return '—'
  }

  if (typeof value === 'number') {
    return new Intl.NumberFormat('pt-BR', {
      maximumFractionDigits: 2,
    }).format(value)
  }

  return String(value)
}

export function summarizeInitiativeActionCapacityAuditChange(
  entry: Pick<InitiativeActionCapacityAuditEntry, 'previousData' | 'newData'>,
): string[] {
  const previous = entry.previousData ?? {}
  const next = entry.newData ?? {}

  return trackedFields.flatMap((field) => {
    const before = previous[field]
    const after = next[field]

    if (before === after) {
      return []
    }

    if (entry.previousData === null) {
      return [`${fieldLabels[field]}: ${formatAuditValue(after)}`]
    }

    return [
      `${fieldLabels[field]}: ${formatAuditValue(before)} → ${formatAuditValue(after)}`,
    ]
  })
}

export function formatInitiativeActionCapacityAuditAction(actionCode: string) {
  if (actionCode === 'capacity_allocation.created') {
    return 'Alocação criada'
  }

  if (actionCode === 'capacity_allocation.updated') {
    return 'Alocação atualizada'
  }

  return actionCode
}

export function formatInitiativeActionCapacityAuditActor(
  entry: Pick<InitiativeActionCapacityAuditEntry, 'actorUserId' | 'actorName'>,
) {
  if (entry.actorName) {
    return entry.actorName
  }

  if (entry.actorUserId) {
    return 'Usuário identificado sem nome organizacional disponível'
  }

  return 'Sistema ou automação'
}
