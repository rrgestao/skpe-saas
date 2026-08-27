export const personCapacityUnits = [
  'hours',
  'days',
  'weeks',
  'months',
  'points',
  'custom',
] as const

export type PersonCapacityUnit =
  (typeof personCapacityUnits)[number]

export const personCapacityPeriodStatuses = [
  'planned',
  'active',
  'closed',
  'cancelled',
] as const

export type PersonCapacityPeriodStatus =
  (typeof personCapacityPeriodStatuses)[number]

export type PersonCapacityPeriodFormValues = {
  organizationPersonId: string
  periodStart: string
  periodEnd: string
  capacityAmount: string
  capacityUnit: string
  status: string
  notes: string
  changeReason: string
}

export type PersonCapacityPeriodCreateCommand = {
  organizationPersonId: string
  periodStart: string
  periodEnd: string
  capacityAmount: number
  capacityUnit: PersonCapacityUnit
  status: 'planned' | 'active'
  notes: string | null
  changeReason: string
}

export type PersonCapacityPeriodTransitionValues = {
  currentStatus: string
  targetStatus: string
  currentAllocationCount: number
  changeReason: string
}

export type PersonCapacityPeriodTransitionCommand = {
  targetStatus: PersonCapacityPeriodStatus
  changeReason: string
}

export function getAllowedPersonCapacityPeriodTransitions(
  status: PersonCapacityPeriodStatus,
): PersonCapacityPeriodStatus[] {
  if (status === 'planned') {
    return ['active', 'cancelled']
  }

  if (status === 'active') {
    return ['closed', 'cancelled']
  }

  return []
}

function parsePersonCapacityPeriodStatus(
  value: string,
): PersonCapacityPeriodStatus | null {
  const normalized = value.trim().toLowerCase()

  return (
    personCapacityPeriodStatuses.find(
      (candidate) => candidate === normalized,
    ) ?? null
  )
}

export function validatePersonCapacityPeriodTransition(
  values: PersonCapacityPeriodTransitionValues,
):
  | {
      ok: true
      value: PersonCapacityPeriodTransitionCommand
    }
  | {
      ok: false
      message: string
    } {
  const currentStatus = parsePersonCapacityPeriodStatus(
    values.currentStatus,
  )
  const targetStatus = parsePersonCapacityPeriodStatus(
    values.targetStatus,
  )
  const changeReason = values.changeReason.trim()

  if (!currentStatus || !targetStatus) {
    return {
      ok: false,
      message: 'Situação de capacidade inválida.',
    }
  }

  if (
    !getAllowedPersonCapacityPeriodTransitions(
      currentStatus,
    ).includes(targetStatus)
  ) {
    return {
      ok: false,
      message:
        'A transição solicitada não é permitida para este período de capacidade.',
    }
  }

  if (
    (targetStatus === 'closed' ||
      targetStatus === 'cancelled') &&
    values.currentAllocationCount > 0
  ) {
    return {
      ok: false,
      message:
        'Finalize ou cancele as alocações abertas antes de terminalizar este período.',
    }
  }

  if (changeReason.length < 10) {
    return {
      ok: false,
      message:
        'Informe uma justificativa com pelo menos 10 caracteres.',
    }
  }

  return {
    ok: true,
    value: {
      targetStatus,
      changeReason,
    },
  }
}

export function validatePersonCapacityPeriodCreation(
  values: PersonCapacityPeriodFormValues,
):
  | {
      ok: true
      value: PersonCapacityPeriodCreateCommand
    }
  | {
      ok: false
      message: string
    } {
  const organizationPersonId =
    values.organizationPersonId.trim()
  const periodStart = values.periodStart.trim()
  const periodEnd = values.periodEnd.trim()
  const rawAmount = values.capacityAmount.trim()
  const rawUnit =
    values.capacityUnit.trim().toLowerCase()
  const rawStatus =
    values.status.trim().toLowerCase()
  const notes = values.notes.trim() || null
  const changeReason =
    values.changeReason.trim()

  if (!organizationPersonId) {
    return {
      ok: false,
      message: 'Selecione uma pessoa.',
    }
  }

  if (!periodStart || !periodEnd) {
    return {
      ok: false,
      message:
        'Informe o início e o fim do período de capacidade.',
    }
  }

  if (periodEnd < periodStart) {
    return {
      ok: false,
      message:
        'A data final não pode ser anterior à data inicial.',
    }
  }

  const capacityAmount = Number(rawAmount)

  if (
    !rawAmount ||
    !Number.isFinite(capacityAmount) ||
    capacityAmount < 0
  ) {
    return {
      ok: false,
      message:
        'Informe uma capacidade quantitativa não negativa.',
    }
  }

  const capacityUnit =
    personCapacityUnits.find(
      (candidate) => candidate === rawUnit,
    ) ?? null

  if (!capacityUnit) {
    return {
      ok: false,
      message:
        'Selecione uma unidade de capacidade válida.',
    }
  }

  if (
    rawStatus !== 'planned' &&
    rawStatus !== 'active'
  ) {
    return {
      ok: false,
      message:
        'A situação inicial deve ser planejada ou ativa.',
    }
  }

  if (changeReason.length < 10) {
    return {
      ok: false,
      message:
        'Informe uma justificativa com pelo menos 10 caracteres.',
    }
  }

  return {
    ok: true,
    value: {
      organizationPersonId,
      periodStart,
      periodEnd,
      capacityAmount,
      capacityUnit,
      status: rawStatus,
      notes,
      changeReason,
    },
  }
}
