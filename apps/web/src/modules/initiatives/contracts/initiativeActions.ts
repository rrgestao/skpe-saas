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
