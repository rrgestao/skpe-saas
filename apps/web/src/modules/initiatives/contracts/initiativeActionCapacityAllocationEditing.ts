import type {
  InitiativeActionCapacityAllocation,
  InitiativeActionCapacityAllocationStatus,
} from './initiativeActions'

export type InitiativeActionCapacityAllocationEditValues = {
  allocationStart: string
  allocationEnd: string
  allocatedAmount: string
  notes: string
  changeReason: string
}

export type InitiativeActionCapacityAllocationEditCommand = {
  allocationStart: string
  allocationEnd: string
  allocatedAmount: number
  notes: string | null
  changeReason: string
}

export function canEditInitiativeActionCapacityAllocation(
  status: InitiativeActionCapacityAllocationStatus,
) {
  return status === 'planned' || status === 'active'
}

export function validateInitiativeActionCapacityAllocationEdit(
  allocation: InitiativeActionCapacityAllocation,
  values: InitiativeActionCapacityAllocationEditValues,
):
  | {
      ok: true
      value: InitiativeActionCapacityAllocationEditCommand
    }
  | {
      ok: false
      message: string
    } {
  if (!canEditInitiativeActionCapacityAllocation(allocation.status)) {
    return {
      ok: false,
      message: 'Alocações encerradas ou canceladas não podem ser editadas.',
    }
  }

  const allocationStart = values.allocationStart.trim()
  const allocationEnd = values.allocationEnd.trim()
  const notes = values.notes.trim() || null
  const changeReason = values.changeReason.trim()

  if (!allocationStart || !allocationEnd) {
    return {
      ok: false,
      message: 'Informe o início e o fim da alocação.',
    }
  }

  if (allocationEnd < allocationStart) {
    return {
      ok: false,
      message: 'A data final da alocação não pode ser anterior à data inicial.',
    }
  }

  const allocatedAmount = Number(values.allocatedAmount)

  if (
    values.allocatedAmount.trim() === '' ||
    !Number.isFinite(allocatedAmount) ||
    allocatedAmount < 0
  ) {
    return {
      ok: false,
      message: 'A quantidade alocada deve ser um número não negativo.',
    }
  }

  if (changeReason.length < 10) {
    return {
      ok: false,
      message: 'Informe uma justificativa com pelo menos 10 caracteres.',
    }
  }

  if (
    allocationStart === allocation.allocationStart &&
    allocationEnd === allocation.allocationEnd &&
    allocatedAmount === allocation.allocatedAmount &&
    notes === allocation.notes
  ) {
    return {
      ok: false,
      message: 'Informe ao menos uma alteração efetiva na alocação.',
    }
  }

  return {
    ok: true,
    value: {
      allocationStart,
      allocationEnd,
      allocatedAmount,
      notes,
      changeReason,
    },
  }
}
