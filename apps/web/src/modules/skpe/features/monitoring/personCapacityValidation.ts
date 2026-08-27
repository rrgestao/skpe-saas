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
