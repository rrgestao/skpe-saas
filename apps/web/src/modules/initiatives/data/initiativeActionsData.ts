import { supabase } from '../../../lib/supabase'

import {
  initiativeKanbanStatuses,
  initiativeKanbanStatusLabels,
  type InitiativeActionBoardRow,
  type InitiativeKanbanCardModel,
  type InitiativeKanbanColumnModel,
  type InitiativeKanbanStatus,
} from '../contracts/initiativeActions'

function isKanbanStatus(
  status: string,
): status is InitiativeKanbanStatus {
  return initiativeKanbanStatuses.some(
    (candidate) => candidate === status,
  )
}

function normalizeProgress(value: unknown) {
  const parsed = Number(value)

  if (!Number.isFinite(parsed)) return 0

  return Math.min(100, Math.max(0, parsed))
}

function mapBoardRow(
  row: InitiativeActionBoardRow,
): InitiativeKanbanCardModel | null {
  if (!isKanbanStatus(row.status)) {
    return null
  }

  const officialProgress =
    normalizeProgress(row.official_progress)

  const calculatedProgress =
    row.calculated_progress === null
      ? null
      : normalizeProgress(row.calculated_progress)

  return {
    actionId: row.action_id,
    parentActionId: row.parent_action_id,
    depth: row.depth,

    code: row.code,
    name: row.name,
    description: row.description,

    actionType: row.action_type,
    status: row.status,
    priority: row.priority,

    officialProgress,
    calculatedProgress,
    displayProgress:
      calculatedProgress ?? officialProgress,

    isRoot: row.is_root,
    hasEligibleChildren:
      row.has_eligible_children,

    responsibleAreaId:
      row.responsible_area_id,

    plannedStartDate:
      row.planned_start_date,
    plannedDueDate:
      row.planned_due_date,

    startedAt: row.started_at,
    completedAt: row.completed_at,
  }
}

export async function loadInitiativeActionBoard(
  initiativeId: string,
): Promise<InitiativeKanbanColumnModel[]> {
  const { data, error } = await supabase.rpc(
    'get_sparks_initiative_action_board',
    {
      target_initiative_id: initiativeId,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível carregar as ações da iniciativa: ${error.message}`,
    )
  }

  const cards = (
    (data ?? []) as InitiativeActionBoardRow[]
  )
    .map(mapBoardRow)
    .filter(
      (
        item,
      ): item is InitiativeKanbanCardModel =>
        item !== null,
    )

  return initiativeKanbanStatuses.map(
    (status): InitiativeKanbanColumnModel => ({
      status,
      label: initiativeKanbanStatusLabels[status],
      cards: cards.filter(
        (card) => card.status === status,
      ),
    }),
  )
}
