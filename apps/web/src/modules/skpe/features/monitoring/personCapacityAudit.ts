import type { PersonCapacityAuditEntry } from './personCapacity'

const trackedFields = [
  'status',
  'period_start',
  'period_end',
  'capacity_amount',
  'capacity_unit',
  'notes',
] as const

const fieldLabels: Record<(typeof trackedFields)[number], string> = {
  status: 'Situação',
  period_start: 'Início',
  period_end: 'Fim',
  capacity_amount: 'Capacidade',
  capacity_unit: 'Unidade',
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

export function summarizePersonCapacityAuditChange(
  entry: Pick<PersonCapacityAuditEntry, 'previousData' | 'newData'>,
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

export function formatPersonCapacityAuditAction(actionCode: string) {
  if (actionCode === 'capacity_period.created') {
    return 'Período criado'
  }

  if (actionCode === 'capacity_period.updated') {
    return 'Período atualizado'
  }

  return actionCode
}
