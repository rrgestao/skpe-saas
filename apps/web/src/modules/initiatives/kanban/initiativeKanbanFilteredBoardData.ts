import { supabase } from '../../../lib/supabase'

import {
  initiativeKanbanStatuses,
  initiativeKanbanStatusLabels,
  type InitiativeActionBoardRow,
  type InitiativeKanbanCardModel,
  type InitiativeKanbanColumnModel,
  type InitiativeKanbanStatus,
} from '../contracts/initiativeActions'

type FilteredBoardRow = InitiativeActionBoardRow & {
  responsible_area_name: string | null
  responsible_person_ids: string[] | null
  responsible_person_names: string[] | null
}

export type InitiativeKanbanFilteredCardModel = InitiativeKanbanCardModel & {
  responsibleAreaName: string | null
  responsiblePersonIds: string[]
  responsiblePersonNames: string[]
}

export type InitiativeKanbanFilteredColumnModel = Omit<
  InitiativeKanbanColumnModel,
  'cards'
> & {
  cards: InitiativeKanbanFilteredCardModel[]
}

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

function normalizeOptionalNumber(value: unknown) {
  if (value === null || value === undefined) {
    return null
  }

  const parsed = Number(value)

  return Number.isFinite(parsed) ? parsed : null
}

function mapBoardRow(
  row: FilteredBoardRow,
): InitiativeKanbanFilteredCardModel | null {
  if (!isKanbanStatus(row.status)) {
    return null
  }

  const officialProgress = normalizeProgress(
    row.official_progress,
  )
  const calculatedProgress =
    row.calculated_progress === null
      ? null
      : normalizeProgress(row.calculated_progress)

  return {
    actionId: row.action_id,
    organizationId: row.organization_id,
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
    responsibleAreaName:
      row.responsible_area_name,
    responsiblePersonIds:
      row.responsible_person_ids ?? [],
    responsiblePersonNames:
      row.responsible_person_names ?? [],
    plannedStartDate:
      row.planned_start_date,
    plannedDueDate:
      row.planned_due_date,
    plannedCost:
      normalizeOptionalNumber(row.planned_cost),
    actualCost:
      normalizeOptionalNumber(row.actual_cost),
    currencyCode: row.currency_code,
    estimatedEffort:
      normalizeOptionalNumber(row.estimated_effort),
    actualEffort:
      normalizeOptionalNumber(row.actual_effort),
    effortUnit: row.effort_unit,
    startedAt: row.started_at,
    completedAt: row.completed_at,
  }
}

export async function loadInitiativeKanbanFilteredBoard(
  initiativeId: string,
): Promise<InitiativeKanbanFilteredColumnModel[]> {
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

  const cards = ((data ?? []) as FilteredBoardRow[])
    .map(mapBoardRow)
    .filter(
      (
        card,
      ): card is InitiativeKanbanFilteredCardModel =>
        card !== null,
    )

  return initiativeKanbanStatuses.map(
    (status): InitiativeKanbanFilteredColumnModel => ({
      status,
      label: initiativeKanbanStatusLabels[status],
      cards: cards.filter(
        (card) => card.status === status,
      ),
    }),
  )
}
