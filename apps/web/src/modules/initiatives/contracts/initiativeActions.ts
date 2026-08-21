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