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

export type InitiativeKanbanStatus = Extract<
  InitiativeActionLifecycle,
  | 'planned'
  | 'in_progress'
  | 'on_hold'
  | 'blocked'
  | 'completed'
>

export type InitiativeActionRollupRow = {
  action_id: string
  parent_action_id: string | null
  depth: number
  action_type: InitiativeActionType
  status: InitiativeActionLifecycle
  official_progress: number
  calculated_progress: number | null
  is_root: boolean
  has_eligible_children: boolean
}

export type InitiativeKanbanCardModel = {
  actionId: string
  parentActionId: string | null
  depth: number
  actionType: InitiativeActionType
  status: InitiativeKanbanStatus
  officialProgress: number
  calculatedProgress: number | null
  displayProgress: number
  isRoot: boolean
  hasEligibleChildren: boolean
}

export type InitiativeKanbanColumnModel = {
  status: InitiativeKanbanStatus
  label: string
  cards: InitiativeKanbanCardModel[]
}

export const initiativeKanbanStatuses: readonly InitiativeKanbanStatus[] = [
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