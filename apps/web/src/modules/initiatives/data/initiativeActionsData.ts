import { supabase } from '../../../lib/supabase'

import {
  initiativeKanbanStatuses,
  initiativeKanbanStatusLabels,
  type InitiativeActionBoardRow,
  type InitiativeActionEconomicExecution,
  type InitiativeActionLifecycle,
  type InitiativeActionResponsibility,
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

function normalizeOptionalNumber(
  value: unknown,
) {
  if (value === null || value === undefined) {
    return null
  }

  const parsed = Number(value)

  return Number.isFinite(parsed)
    ? parsed
    : null
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

    plannedCost:
      normalizeOptionalNumber(
        row.planned_cost,
      ),
    actualCost:
      normalizeOptionalNumber(
        row.actual_cost,
      ),
    currencyCode: row.currency_code,
    estimatedEffort:
      normalizeOptionalNumber(
        row.estimated_effort,
      ),
    actualEffort:
      normalizeOptionalNumber(
        row.actual_effort,
      ),
    effortUnit: row.effort_unit,

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

export async function transitionInitiativeAction(
  actionId: string,
  targetStatus: InitiativeActionLifecycle,
  changeReason: string,
) {
  const { data, error } = await supabase.rpc(
    'transition_sparks_initiative_action_lifecycle',
    {
      target_action_id: actionId,
      target_status: targetStatus,
      change_reason: changeReason,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível alterar a situação da ação: ${error.message}`,
    )
  }

  return data
}

export async function updateInitiativeActionProgress(
  actionId: string,
  progress: number,
  changeReason: string,
) {
  const { data, error } = await supabase.rpc(
    'update_sparks_initiative_action_execution',
    {
      target_action_id: actionId,
      target_progress: progress,
      change_reason: changeReason,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível atualizar o progresso da ação: ${error.message}`,
    )
  }

  return data
}

export async function updateInitiativeActionEconomics(
  actionId: string,
  execution: InitiativeActionEconomicExecution,
) {
  const { data, error } = await supabase.rpc(
    'update_sparks_initiative_action',
    {
      target_action_id: actionId,
      action_payload: {
        plannedCost: execution.plannedCost,
        actualCost: execution.actualCost,
        currencyCode: execution.currencyCode,
        estimatedEffort:
          execution.estimatedEffort,
        actualEffort:
          execution.actualEffort,
        effortUnit: execution.effortUnit,
      },
      change_reason: execution.changeReason,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível atualizar a execução econômica da ação: ${error.message}`,
    )
  }

  return data
}

type InitiativeActionResponsibilityRow = {
  assignment_id: string
  organization_person_id: string
  person_id: string
  person_name: string
  job_title: string | null
  organizational_area: string | null
  responsibility_type: string
  allocation_percentage: number | string | null
  authority_level: string | null
  valid_from: string | null
  valid_until: string | null
}

export async function loadInitiativeActionResponsibilities(
  actionId: string,
): Promise<InitiativeActionResponsibility[]> {
  const { data, error } = await supabase.rpc(
    'get_sparks_initiative_action_responsibilities',
    {
      target_action_id: actionId,
      include_inactive: false,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível carregar os responsáveis da ação: ${error.message}`,
    )
  }

  return (
    (data ?? []) as InitiativeActionResponsibilityRow[]
  ).map((row) => {
    const parsedAllocation =
      row.allocation_percentage === null
        ? null
        : Number(row.allocation_percentage)

    return {
      assignmentId: row.assignment_id,
      organizationPersonId:
        row.organization_person_id,
      personId: row.person_id,
      personName: row.person_name,
      jobTitle: row.job_title,
      organizationalArea:
        row.organizational_area,
      responsibilityType:
        row.responsibility_type,
      allocationPercentage:
        parsedAllocation !== null &&
        Number.isFinite(parsedAllocation)
          ? parsedAllocation
          : null,
      authorityLevel: row.authority_level,
      validFrom: row.valid_from,
      validUntil: row.valid_until,
    }
  })
}

export type CreateInitiativeActionCommand = {
  initiativeId: string
  code: string
  name: string
  description: string | null
  actionType: 'action' | 'milestone'
  priority: 'low' | 'medium' | 'high' | 'critical'
  changeReason: string
}

export async function createInitiativeAction(
  command: CreateInitiativeActionCommand,
) {
  const { data, error } = await supabase.rpc(
    'create_sparks_initiative_action',
    {
      target_initiative_id: command.initiativeId,
      action_payload: {
        code: command.code,
        name: command.name,
        description: command.description,
        actionType: command.actionType,
        priority: command.priority,
      },
      change_reason: command.changeReason,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível criar a ação: ${error.message}`,
    )
  }

  return data
}

export type CancelledInitiativeAction = {
  id: string
  code: string
  name: string
  status: 'cancelled'
  progress: number
}

export async function loadCancelledInitiativeActions(
  initiativeId: string,
): Promise<CancelledInitiativeAction[]> {
  const { data, error } = await supabase
    .from('sparks_initiative_actions')
    .select('id,code,name,status,progress')
    .eq('initiative_id', initiativeId)
    .eq('status', 'cancelled')
    .is('archived_at', null)
    .order('code', { ascending: true })

  if (error) {
    throw new Error(
      `Não foi possível carregar as ações canceladas: ${error.message}`,
    )
  }

  return (data ?? []) as CancelledInitiativeAction[]
}
