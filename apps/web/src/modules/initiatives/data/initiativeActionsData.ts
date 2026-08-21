import { supabase } from '../../../lib/supabase'

import {
  initiativeKanbanStatuses,
  initiativeKanbanStatusLabels,
  type InitiativeActionRollupRow,
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

function mapRollupRow(
  row: InitiativeActionRollupRow,
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
    actionType: row.action_type,
    status: row.status,
    officialProgress,
    calculatedProgress,
    displayProgress:
      calculatedProgress ?? officialProgress,
    isRoot: row.is_root,
    hasEligibleChildren:
      row.has_eligible_children,
  }
}

export async function loadInitiativeActionBoard(
  initiativeId: string,
): Promise<InitiativeKanbanColumnModel[]> {
  const { data, error } = await supabase.rpc(
    'get_sparks_initiative_action_rollup',
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
    (data ?? []) as InitiativeActionRollupRow[]
  )
    .map(mapRollupRow)
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