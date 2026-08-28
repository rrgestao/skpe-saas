import type {
  InitiativeTemporalTimelineRow,
} from './monitoringTimeline'

export type ActionBoardExecutionRow = {
  action_id: string
  initiative_id: string
  parent_action_id?: string | null
  code: string
  name: string
  status: string
  priority: string
  official_progress: number
  calculated_progress: number
  has_eligible_children: boolean
  planned_cost: number | null
  actual_cost: number | null
  currency_code: string | null
  estimated_effort: number | null
  actual_effort: number | null
  effort_unit: string | null
}

export type CapacityAllocationExecutionRow = {
  allocationId: string
  capacityPeriodId: string
  organizationPersonId: string
  personName: string
  capacityUnit: string
  objectType: string
  objectId: string
  allocatedAmount: number
  allocationStatus: string
}

export type PersonCapacityExecutionRow = {
  capacity_period_id: string
  person_name: string
  capacity_unit: string
  overallocation_amount: number
  is_overallocated: boolean
}

export type ExecutionMatrixCapacityGroup = {
  unit: string
  allocatedAmount: number
  allocationCount: number
  personCount: number
}

export type ExecutionMatrixRow = {
  action: ActionBoardExecutionRow
  temporal: InitiativeTemporalTimelineRow | null
  progressValue: number
  progressSource: 'official' | 'calculated'
  attentionReasons: string[]
  capacityGroups: ExecutionMatrixCapacityGroup[]
  hasOverallocatedCapacity: boolean
}

function normalizeObjectType(value: string) {
  return value.trim().toLowerCase()
}

function isActionAllocation(
  row: CapacityAllocationExecutionRow,
) {
  const type = normalizeObjectType(row.objectType)

  return (
    type === 'initiative_action' ||
    type === 'sparks_initiative_action'
  )
}

export function deriveExecutionAttentionReasons(
  temporal: InitiativeTemporalTimelineRow | null,
  hasOverallocatedCapacity: boolean,
  action: ActionBoardExecutionRow,
) {
  const reasons: string[] = []

  if (temporal?.is_completion_overdue) {
    reasons.push(
      `Conclusão em atraso: ${temporal.days_completion_overdue} dia(s)`,
    )
  } else if (temporal?.is_start_overdue) {
    reasons.push(
      `Início em atraso: ${temporal.days_start_overdue} dia(s)`,
    )
  }

  if (
    temporal &&
    temporal.temporal_data_quality_state !== 'ok'
  ) {
    reasons.push(
      `Qualidade temporal: ${temporal.temporal_data_quality_state}`,
    )
  }

  if (hasOverallocatedCapacity) {
    reasons.push('Capacidade sobrealocada')
  }

  if (
    (action.planned_cost !== null ||
      action.actual_cost !== null) &&
    !action.currency_code
  ) {
    reasons.push('Custo sem moeda')
  }

  if (
    (action.estimated_effort !== null ||
      action.actual_effort !== null) &&
    !action.effort_unit
  ) {
    reasons.push('Esforço sem unidade')
  }

  return reasons
}

export function buildExecutionMatrixRows(
  actions: ActionBoardExecutionRow[],
  temporalRows: InitiativeTemporalTimelineRow[],
  allocations: CapacityAllocationExecutionRow[],
  capacityRows: PersonCapacityExecutionRow[],
): ExecutionMatrixRow[] {
  const temporalByAction = new Map(
    temporalRows
      .filter((row) => row.entity_type === 'action')
      .map((row) => [row.entity_id, row]),
  )

  const overallocatedPeriods = new Set(
    capacityRows
      .filter((row) => row.is_overallocated)
      .map((row) => row.capacity_period_id),
  )

  const allocationsByAction = new Map<
    string,
    CapacityAllocationExecutionRow[]
  >()

  for (const allocation of allocations) {
    if (!isActionAllocation(allocation)) {
      continue
    }

    const current =
      allocationsByAction.get(allocation.objectId) ?? []

    current.push(allocation)
    allocationsByAction.set(
      allocation.objectId,
      current,
    )
  }

  const rows = actions.map((action) => {
    const actionAllocations =
      allocationsByAction.get(action.action_id) ?? []

    const groups = new Map<
      string,
      {
        allocatedAmount: number
        allocationCount: number
        people: Set<string>
      }
    >()

    for (const allocation of actionAllocations) {
      const current = groups.get(
        allocation.capacityUnit,
      ) ?? {
        allocatedAmount: 0,
        allocationCount: 0,
        people: new Set<string>(),
      }

      current.allocatedAmount +=
        allocation.allocatedAmount
      current.allocationCount += 1
      current.people.add(
        allocation.organizationPersonId,
      )

      groups.set(allocation.capacityUnit, current)
    }

    const capacityGroups =
      Array.from(groups.entries())
        .map(([unit, value]) => ({
          unit,
          allocatedAmount: value.allocatedAmount,
          allocationCount: value.allocationCount,
          personCount: value.people.size,
        }))
        .sort((first, second) =>
          first.unit.localeCompare(
            second.unit,
            'pt-BR',
          ),
        )

    const hasOverallocatedCapacity =
      actionAllocations.some((allocation) =>
        overallocatedPeriods.has(
          allocation.capacityPeriodId,
        ),
      )

    const temporal =
      temporalByAction.get(action.action_id) ?? null

    const progressSource: ExecutionMatrixRow['progressSource'] =
      action.has_eligible_children
        ? 'calculated'
        : 'official'

    const progressValue =
      progressSource === 'calculated'
        ? action.calculated_progress
        : action.official_progress

    return {
      action,
      temporal,
      progressValue,
      progressSource,
      attentionReasons:
        deriveExecutionAttentionReasons(
          temporal,
          hasOverallocatedCapacity,
          action,
        ),
      capacityGroups,
      hasOverallocatedCapacity,
    }
  })

  return rows.sort((first, second) => {
    const attentionDifference =
      Number(second.attentionReasons.length > 0) -
      Number(first.attentionReasons.length > 0)

    if (attentionDifference !== 0) {
      return attentionDifference
    }

    const priorityRank: Record<string, number> = {
      critical: 4,
      high: 3,
      medium: 2,
      low: 1,
    }

    const priorityDifference =
      (priorityRank[second.action.priority] ?? 0) -
      (priorityRank[first.action.priority] ?? 0)

    if (priorityDifference !== 0) {
      return priorityDifference
    }

    return first.action.code.localeCompare(
      second.action.code,
      'pt-BR',
    )
  })
}