import { supabase } from '../../../lib/supabase'

import {
  initiativeKanbanStatuses,
  initiativeKanbanStatusLabels,
  type InitiativeActionBoardRow,
  type InitiativeActionEconomicExecution,
  type InitiativeActionDomainOption,
  type InitiativeActionLifecycle,
  type InitiativeActionResponsibility,
  type InitiativeActionPersonCapacity,
  type InitiativeActionResponsibilityAssignment,
  type InitiativeActionResponsibilityCandidate,
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

type InitiativeActionResponsibilityCandidateRow = {
  organization_person_id: string
  person_id: string
  full_name: string
  preferred_name: string | null
  job_title: string | null
  organizational_area: string | null
  availability_percentage: number | string | null
}

type InitiativeActionDomainRow = {
  value_code: string
  value_name: string
}

export async function loadInitiativeActionResponsibilityCandidates(
  organizationId: string,
): Promise<InitiativeActionResponsibilityCandidate[]> {
  const { data, error } = await supabase.rpc(
    'get_sparks_people_for_responsibility',
    {
      target_organization_id: organizationId,
      target_search: null,
      target_relationship_type: null,
      target_only_active: true,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível carregar as pessoas elegíveis: ${error.message}`,
    )
  }

  return (
    (data ?? []) as InitiativeActionResponsibilityCandidateRow[]
  ).map((row) => {
    const parsedAvailability =
      row.availability_percentage === null
        ? null
        : Number(row.availability_percentage)

    return {
      organizationPersonId:
        row.organization_person_id,
      personId: row.person_id,
      displayName:
        row.preferred_name?.trim() ||
        row.full_name,
      jobTitle: row.job_title,
      organizationalArea:
        row.organizational_area,
      availabilityPercentage:
        parsedAvailability !== null &&
        Number.isFinite(parsedAvailability)
          ? parsedAvailability
          : null,
    }
  })
}

async function loadInitiativeActionDomainOptions(
  domainCode: string,
  organizationId: string,
): Promise<InitiativeActionDomainOption[]> {
  const { data, error } = await supabase.rpc(
    'get_sparks_domain_values',
    {
      target_domain_code: domainCode,
      target_organization_id: organizationId,
      target_module_code: 'SK-PE',
      include_inactive: false,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível carregar o domínio ${domainCode}: ${error.message}`,
    )
  }

  return (
    (data ?? []) as InitiativeActionDomainRow[]
  ).map((row) => ({
    code: row.value_code,
    name: row.value_name,
  }))
}

export async function loadInitiativeActionResponsibilityDomains(
  organizationId: string,
) {
  const [
    responsibilityTypes,
    authorityLevels,
  ] = await Promise.all([
    loadInitiativeActionDomainOptions(
      'RESPONSIBILITY_TYPE',
      organizationId,
    ),
    loadInitiativeActionDomainOptions(
      'AUTHORITY_LEVEL',
      organizationId,
    ),
  ])

  return {
    responsibilityTypes,
    authorityLevels,
  }
}

type InitiativeActionPersonCapacityRow = {
  capacity_period_id: string
  period_start: string
  period_end: string
  capacity_unit: string
  capacity_status: string
  capacity_amount: number | string
  allocated_current_amount: number | string
  available_amount: number | string
  utilization_percentage: number | string | null
  overallocation_amount: number | string
  is_overallocated: boolean
  current_allocation_count: number | string
}

export async function loadInitiativeActionPersonCapacity(
  organizationId: string,
  organizationPersonId: string,
  periodStart: string | null,
  periodEnd: string | null,
): Promise<InitiativeActionPersonCapacity[]> {
  const { data, error } = await supabase.rpc(
    'get_sparks_person_capacity_projection',
    {
      target_organization_id: organizationId,
      target_organization_person_id:
        organizationPersonId,
      target_period_start: periodStart,
      target_period_end: periodEnd,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível carregar a capacidade da pessoa: ${error.message}`,
    )
  }

  return (
    (data ?? []) as InitiativeActionPersonCapacityRow[]
  ).map((row) => ({
    capacityPeriodId: row.capacity_period_id,
    periodStart: row.period_start,
    periodEnd: row.period_end,
    capacityUnit: row.capacity_unit,
    capacityStatus: row.capacity_status,
    capacityAmount: Number(row.capacity_amount),
    allocatedCurrentAmount:
      Number(row.allocated_current_amount),
    availableAmount: Number(row.available_amount),
    utilizationPercentage:
      row.utilization_percentage === null
        ? null
        : Number(row.utilization_percentage),
    overallocationAmount:
      Number(row.overallocation_amount),
    isOverallocated: row.is_overallocated,
    currentAllocationCount:
      Number(row.current_allocation_count),
  }))
}

export async function assignInitiativeActionResponsibility(
  actionId: string,
  assignment: InitiativeActionResponsibilityAssignment,
) {
  const { data, error } = await supabase.rpc(
    'assign_sparks_initiative_action_responsibility',
    {
      target_action_id: actionId,
      target_organization_person_id:
        assignment.organizationPersonId,
      target_responsibility_type:
        assignment.responsibilityType,
      target_allocation_percentage:
        assignment.allocationPercentage,
      target_authority_level:
        assignment.authorityLevel,
      target_valid_from: assignment.validFrom,
      target_valid_until: assignment.validUntil,
      target_assignment_reason:
        assignment.assignmentReason,
      change_reason: assignment.changeReason,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível atribuir a responsabilidade: ${error.message}`,
    )
  }

  return data
}

export async function endInitiativeActionResponsibility(
  assignmentId: string,
  endDate: string | null,
  changeReason: string,
) {
  const reason = changeReason.trim()

  if (reason.length < 10) {
    throw new Error(
      'Informe uma justificativa com pelo menos 10 caracteres.',
    )
  }

  const { error } = await supabase.rpc(
    'end_sparks_initiative_action_responsibility',
    {
      target_assignment_id: assignmentId,
      target_end_date: endDate,
      change_reason: reason,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível encerrar a responsabilidade: ${error.message}`,
    )
  }
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
