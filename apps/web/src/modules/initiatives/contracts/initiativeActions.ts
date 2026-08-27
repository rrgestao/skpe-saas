export type InitiativeActionLifecycle =
  | 'planned'
  | 'in_progress'
  | 'on_hold'
  | 'blocked'
  | 'completed'
  | 'cancelled'
  | 'archived'

export type InitiativeActionType =
  | 'action'
  | 'milestone'

export type InitiativeActionPriority =
  | 'low'
  | 'medium'
  | 'high'
  | 'critical'

export type InitiativeActionEffortUnit =
  | 'hours'
  | 'days'
  | 'weeks'
  | 'months'
  | 'points'
  | 'custom'

export type InitiativeActionResponsibility = {
  assignmentId: string
  organizationPersonId: string
  personId: string
  personName: string
  jobTitle: string | null
  organizationalArea: string | null
  responsibilityType: string
  allocationPercentage: number | null
  authorityLevel: string | null
  validFrom: string | null
  validUntil: string | null
}

export type InitiativeActionResponsibilityCandidate = {
  organizationPersonId: string
  personId: string
  displayName: string
  jobTitle: string | null
  organizationalArea: string | null
  availabilityPercentage: number | null
}

export type InitiativeActionDomainOption = {
  code: string
  name: string
}

export type InitiativeActionPersonCapacity = {
  capacityPeriodId: string
  periodStart: string
  periodEnd: string
  capacityUnit: string
  capacityStatus: string
  capacityAmount: number
  allocatedCurrentAmount: number
  availableAmount: number
  utilizationPercentage: number | null
  overallocationAmount: number
  isOverallocated: boolean
  currentAllocationCount: number
}

export type InitiativeActionCapacityAllocationFormValues = {
  capacityPeriodId: string
  allocationStart: string
  allocationEnd: string
  allocatedAmount: string
  status: string
  notes: string
  changeReason: string
}

export type InitiativeActionCapacityAllocationCommand = {
  capacityPeriodId: string
  allocationStart: string
  allocationEnd: string
  allocatedAmount: number
  status: 'planned' | 'active'
  notes: string | null
  changeReason: string
}

export type InitiativeActionResponsibilityFormValues = {
  organizationPersonId: string
  responsibilityType: string
  allocationPercentage: string
  authorityLevel: string
  validFrom: string
  validUntil: string
  assignmentReason: string
  changeReason: string
}

export type InitiativeActionResponsibilityAssignment = {
  organizationPersonId: string
  responsibilityType: string
  allocationPercentage: number | null
  authorityLevel: string | null
  validFrom: string | null
  validUntil: string | null
  assignmentReason: string | null
  changeReason: string
}

export type InitiativeKanbanStatus = Extract<
  InitiativeActionLifecycle,
  | 'planned'
  | 'in_progress'
  | 'on_hold'
  | 'blocked'
  | 'completed'
>

export type InitiativeActionBoardRow = {
  action_id: string
  organization_id: string
  initiative_id: string
  parent_action_id: string | null
  depth: number

  code: string
  name: string
  description: string | null
  action_type: InitiativeActionType

  status: InitiativeActionLifecycle
  priority: InitiativeActionPriority

  official_progress: number
  calculated_progress: number | null

  is_root: boolean
  has_eligible_children: boolean

  responsible_area_id: string | null

  planned_start_date: string | null
  planned_due_date: string | null

  planned_cost: number | null
  actual_cost: number | null
  currency_code: string
  estimated_effort: number | null
  actual_effort: number | null
  effort_unit: InitiativeActionEffortUnit | null

  started_at: string | null
  completed_at: string | null

  created_at: string
  updated_at: string
}

export type InitiativeKanbanCardModel = {
  actionId: string
  organizationId: string
  parentActionId: string | null
  depth: number

  code: string
  name: string
  description: string | null

  actionType: InitiativeActionType
  status: InitiativeKanbanStatus
  priority: InitiativeActionPriority

  officialProgress: number
  calculatedProgress: number | null
  displayProgress: number

  isRoot: boolean
  hasEligibleChildren: boolean

  responsibleAreaId: string | null

  plannedStartDate: string | null
  plannedDueDate: string | null

  plannedCost: number | null
  actualCost: number | null
  currencyCode: string
  estimatedEffort: number | null
  actualEffort: number | null
  effortUnit: InitiativeActionEffortUnit | null

  startedAt: string | null
  completedAt: string | null
}

export type InitiativeKanbanColumnModel = {
  status: InitiativeKanbanStatus
  label: string
  cards: InitiativeKanbanCardModel[]
}

export const initiativeKanbanStatuses:
  readonly InitiativeKanbanStatus[] = [
    'planned',
    'in_progress',
    'on_hold',
    'blocked',
    'completed',
  ]

export const initiativeKanbanStatusLabels:
  Record<InitiativeKanbanStatus, string> = {
    planned: 'Planejado',
    in_progress: 'Em execução',
    on_hold: 'Em espera',
    blocked: 'Bloqueado',
    completed: 'Concluído',
  }

export const initiativeActionLifecycleLabels:
  Record<InitiativeActionLifecycle, string> = {
    planned: 'Planejado',
    in_progress: 'Em execução',
    on_hold: 'Em espera',
    blocked: 'Bloqueado',
    completed: 'Concluído',
    cancelled: 'Cancelado',
    archived: 'Arquivado',
  }

export const initiativeActionPriorityLabels:
  Record<InitiativeActionPriority, string> = {
    low: 'Baixa',
    medium: 'Média',
    high: 'Alta',
    critical: 'Crítica',
  }

export const initiativeActionEffortUnitLabels:
  Record<InitiativeActionEffortUnit, string> = {
    hours: 'Horas',
    days: 'Dias',
    weeks: 'Semanas',
    months: 'Meses',
    points: 'Pontos',
    custom: 'Personalizada',
  }

export const initiativeActionEffortUnits:
  readonly InitiativeActionEffortUnit[] = [
    'hours',
    'days',
    'weeks',
    'months',
    'points',
    'custom',
  ]

const initiativeActionResponsibilityTypeLabels:
  Record<string, string> = {
    owner: 'Responsável principal',
    co_owner: 'Corresponsável',
    sponsor: 'Patrocinador',
    approver: 'Aprovador',
    validator: 'Validador',
    executor: 'Executor',
  }

export function formatInitiativeActionResponsibilityType(
  value: string,
) {
  const normalized =
    value.trim().toLowerCase()

  const known =
    initiativeActionResponsibilityTypeLabels[
      normalized
    ]

  if (known) return known

  const readable = normalized
    .replaceAll('_', ' ')
    .trim()

  if (!readable) return 'Responsabilidade'

  return (
    readable.charAt(0).toUpperCase() +
    readable.slice(1)
  )
}

export const initiativeActionAllowedTransitions:
  Record<
    InitiativeActionLifecycle,
    readonly InitiativeActionLifecycle[]
  > = {
    planned: [
      'in_progress',
      'blocked',
      'cancelled',
    ],
    in_progress: [
      'on_hold',
      'blocked',
      'completed',
      'cancelled',
    ],
    on_hold: [
      'in_progress',
      'blocked',
      'cancelled',
    ],
    blocked: [
      'in_progress',
      'on_hold',
      'cancelled',
    ],
    completed: ['archived'],
    cancelled: ['archived'],
    archived: [],
  }

export function getAllowedInitiativeActionTransitions(
  card: InitiativeKanbanCardModel,
): readonly InitiativeActionLifecycle[] {
  const transitions =
    initiativeActionAllowedTransitions[card.status]

  if (
    card.status === 'blocked' &&
    card.startedAt === null
  ) {
    return transitions.filter(
      (status) => status !== 'on_hold',
    )
  }

  return transitions
}

export function canTransitionInitiativeActionTo(
  card: InitiativeKanbanCardModel,
  targetStatus: InitiativeActionLifecycle,
) {
  return getAllowedInitiativeActionTransitions(
    card,
  ).includes(targetStatus)
}

export function canUpdateInitiativeActionProgress(
  status: InitiativeActionLifecycle,
) {
  return (
    status === 'in_progress' ||
    status === 'on_hold' ||
    status === 'blocked'
  )
}

export function canUpdateInitiativeActionEconomics(
  status: InitiativeActionLifecycle,
) {
  return (
    status !== 'completed' &&
    status !== 'cancelled' &&
    status !== 'archived'
  )
}

export type InitiativeActionEconomicFormValues = {
  plannedCost: string
  actualCost: string
  currencyCode: string
  estimatedEffort: string
  actualEffort: string
  effortUnit: string
  changeReason: string
}

export type InitiativeActionEconomicExecution = {
  plannedCost: number | null
  actualCost: number | null
  currencyCode: string
  estimatedEffort: number | null
  actualEffort: number | null
  effortUnit: InitiativeActionEffortUnit | null
  changeReason: string
}

export type InitiativeActionEconomicValidationResult =
  | {
      ok: true
      value: InitiativeActionEconomicExecution
    }
  | {
      ok: false
      message: string
    }

function parseOptionalNonNegativeNumber(
  rawValue: string,
  label: string,
):
  | { ok: true; value: number | null }
  | { ok: false; message: string } {
  const normalized = rawValue.trim()

  if (normalized === '') {
    return {
      ok: true,
      value: null,
    }
  }

  const parsed = Number(normalized)

  if (
    !Number.isFinite(parsed) ||
    parsed < 0
  ) {
    return {
      ok: false,
      message: `${label} deve ser um número não negativo.`,
    }
  }

  return {
    ok: true,
    value: parsed,
  }
}

export function validateInitiativeActionEconomics(
  values: InitiativeActionEconomicFormValues,
): InitiativeActionEconomicValidationResult {
  const changeReason = values.changeReason.trim()

  if (changeReason.length < 10) {
    return {
      ok: false,
      message:
        'Informe uma justificativa com pelo menos 10 caracteres.',
    }
  }

  const currencyCode =
    values.currencyCode.trim().toUpperCase()

  if (!/^[A-Z]{3}$/.test(currencyCode)) {
    return {
      ok: false,
      message:
        'Informe a moeda com exatamente 3 letras, por exemplo BRL.',
    }
  }

  const plannedCost =
    parseOptionalNonNegativeNumber(
      values.plannedCost,
      'Custo planejado',
    )

  if (!plannedCost.ok) {
    return plannedCost
  }

  const actualCost =
    parseOptionalNonNegativeNumber(
      values.actualCost,
      'Custo realizado',
    )

  if (!actualCost.ok) {
    return actualCost
  }

  const estimatedEffort =
    parseOptionalNonNegativeNumber(
      values.estimatedEffort,
      'Esforço estimado',
    )

  if (!estimatedEffort.ok) {
    return estimatedEffort
  }

  const actualEffort =
    parseOptionalNonNegativeNumber(
      values.actualEffort,
      'Esforço realizado',
    )

  if (!actualEffort.ok) {
    return actualEffort
  }

  const rawEffortUnit =
    values.effortUnit.trim().toLowerCase()

  const effortUnit =
    rawEffortUnit === ''
      ? null
      : initiativeActionEffortUnits.find(
          (candidate) =>
            candidate === rawEffortUnit,
        ) ?? null

  if (
    rawEffortUnit !== '' &&
    effortUnit === null
  ) {
    return {
      ok: false,
      message: 'Unidade de esforço inválida.',
    }
  }

  if (
    (
      estimatedEffort.value !== null ||
      actualEffort.value !== null
    ) &&
    effortUnit === null
  ) {
    return {
      ok: false,
      message:
        'Informe a unidade quando houver esforço estimado ou realizado.',
    }
  }

  return {
    ok: true,
    value: {
      plannedCost: plannedCost.value,
      actualCost: actualCost.value,
      currencyCode,
      estimatedEffort:
        estimatedEffort.value,
      actualEffort: actualEffort.value,
      effortUnit,
      changeReason,
    },
  }
}
export function canManageInitiativeActionResponsibilities(
  status: InitiativeActionLifecycle,
) {
  return (
    status !== 'completed' &&
    status !== 'cancelled' &&
    status !== 'archived'
  )
}

export function validateInitiativeActionResponsibilityAssignment(
  values: InitiativeActionResponsibilityFormValues,
):
  | {
      ok: true
      value: InitiativeActionResponsibilityAssignment
    }
  | {
      ok: false
      message: string
    } {
  const organizationPersonId =
    values.organizationPersonId.trim()
  const responsibilityType =
    values.responsibilityType.trim()
  const authorityLevel =
    values.authorityLevel.trim() || null
  const validFrom =
    values.validFrom.trim() || null
  const validUntil =
    values.validUntil.trim() || null
  const assignmentReason =
    values.assignmentReason.trim() || null
  const changeReason =
    values.changeReason.trim()

  if (!organizationPersonId) {
    return {
      ok: false,
      message: 'Selecione uma pessoa responsável.',
    }
  }

  if (!responsibilityType) {
    return {
      ok: false,
      message: 'Selecione o tipo de responsabilidade.',
    }
  }

  if (changeReason.length < 10) {
    return {
      ok: false,
      message:
        'Informe uma justificativa com pelo menos 10 caracteres.',
    }
  }

  let allocationPercentage: number | null = null
  const rawAllocation =
    values.allocationPercentage.trim()

  if (rawAllocation) {
    const parsed = Number(rawAllocation)

    if (
      !Number.isFinite(parsed) ||
      parsed < 0 ||
      parsed > 100
    ) {
      return {
        ok: false,
        message:
          'A alocação deve estar entre 0 e 100%.',
      }
    }

    allocationPercentage = parsed
  }

  if (
    validFrom !== null &&
    validUntil !== null &&
    validUntil < validFrom
  ) {
    return {
      ok: false,
      message:
        'A data final da vigência não pode ser anterior à data inicial.',
    }
  }

  return {
    ok: true,
    value: {
      organizationPersonId,
      responsibilityType,
      allocationPercentage,
      authorityLevel,
      validFrom,
      validUntil,
      assignmentReason,
      changeReason,
    },
  }
}
export function formatInitiativeActionCapacityAmount(
  value: number,
  unit: string,
) {
  const formatted = new Intl.NumberFormat(
    'pt-BR',
    {
      maximumFractionDigits: 2,
    },
  ).format(value)

  const labels: Record<string, string> = {
    hours: 'h',
    days: 'dias',
    weeks: 'sem.',
    months: 'meses',
    points: 'pts',
    custom: 'un.',
  }

  return `${formatted} ${labels[unit] ?? unit}`
}

export function getInitiativeActionCapacityAlert(
  items: readonly InitiativeActionPersonCapacity[],
) {
  if (items.some((item) => item.isOverallocated)) {
    return 'Há sobrealocação explícita no período consultado.'
  }

  if (items.length === 0) {
    return 'Não há capacidade quantitativa cadastrada para a pessoa no período da ação.'
  }

  return null
}
export function deriveInitiativeActionCapacityAllocationRange(
  capacity: InitiativeActionPersonCapacity,
  plannedStartDate: string | null,
  plannedDueDate: string | null,
) {
  const start =
    plannedStartDate &&
    plannedStartDate > capacity.periodStart
      ? plannedStartDate
      : capacity.periodStart

  const end =
    plannedDueDate &&
    plannedDueDate < capacity.periodEnd
      ? plannedDueDate
      : capacity.periodEnd

  if (end < start) {
    return {
      allocationStart: capacity.periodStart,
      allocationEnd: capacity.periodEnd,
    }
  }

  return {
    allocationStart: start,
    allocationEnd: end,
  }
}

export function validateInitiativeActionCapacityAllocation(
  values: InitiativeActionCapacityAllocationFormValues,
  capacity: InitiativeActionPersonCapacity | null,
):
  | {
      ok: true
      value: InitiativeActionCapacityAllocationCommand
    }
  | {
      ok: false
      message: string
    } {
  const capacityPeriodId =
    values.capacityPeriodId.trim()
  const allocationStart =
    values.allocationStart.trim()
  const allocationEnd =
    values.allocationEnd.trim()
  const status = values.status.trim().toLowerCase()
  const notes = values.notes.trim() || null
  const changeReason =
    values.changeReason.trim()

  if (!capacity || !capacityPeriodId) {
    return {
      ok: false,
      message:
        'Selecione um período de capacidade.',
    }
  }

  if (
    capacity.capacityPeriodId !==
    capacityPeriodId
  ) {
    return {
      ok: false,
      message:
        'O período de capacidade selecionado é inválido.',
    }
  }

  if (!allocationStart || !allocationEnd) {
    return {
      ok: false,
      message:
        'Informe o início e o fim da alocação.',
    }
  }

  if (allocationEnd < allocationStart) {
    return {
      ok: false,
      message:
        'A data final da alocação não pode ser anterior à data inicial.',
    }
  }

  if (
    allocationStart < capacity.periodStart ||
    allocationEnd > capacity.periodEnd
  ) {
    return {
      ok: false,
      message:
        'A alocação deve permanecer dentro do período de capacidade selecionado.',
    }
  }

  const allocatedAmount =
    Number(values.allocatedAmount)

  if (
    values.allocatedAmount.trim() === '' ||
    !Number.isFinite(allocatedAmount) ||
    allocatedAmount < 0
  ) {
    return {
      ok: false,
      message:
        'Informe uma quantidade alocada não negativa.',
    }
  }

  if (
    status !== 'planned' &&
    status !== 'active'
  ) {
    return {
      ok: false,
      message:
        'A situação inicial da alocação deve ser planejada ou ativa.',
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
      capacityPeriodId,
      allocationStart,
      allocationEnd,
      allocatedAmount,
      status,
      notes,
      changeReason,
    },
  }
}
