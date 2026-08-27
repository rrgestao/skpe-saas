import { supabase } from '../../../../lib/supabase'
import {
  type PersonCapacityPeriodCreateCommand,
  type PersonCapacityPeriodStatus,
  type PersonCapacityPeriodTransitionCommand,
  type PersonCapacityUnit,
} from './personCapacityValidation'

export type PersonCapacityCandidate = {
  organizationPersonId: string
  displayName: string
  jobTitle: string | null
  organizationalArea: string | null
  availabilityPercentage: number | null
}

export type PersonCapacityPeriod = {
  capacityPeriodId: string
  periodStart: string
  periodEnd: string
  capacityUnit: PersonCapacityUnit
  capacityStatus: PersonCapacityPeriodStatus
  capacityAmount: number
  allocatedCurrentAmount: number
  availableAmount: number
  utilizationPercentage: number | null
  overallocationAmount: number
  isOverallocated: boolean
  currentAllocationCount: number
  notes: string | null
}

type PersonCandidateRow = {
  organization_person_id: string
  full_name: string
  preferred_name: string | null
  job_title: string | null
  organizational_area: string | null
  availability_percentage: number | string | null
}

export async function loadPersonCapacityCandidates(
  organizationId: string,
): Promise<PersonCapacityCandidate[]> {
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

  return ((data ?? []) as PersonCandidateRow[]).map(
    (row) => {
      const parsedAvailability =
        row.availability_percentage === null
          ? null
          : Number(row.availability_percentage)

      return {
        organizationPersonId:
          row.organization_person_id,
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
    },
  )
}

type PersonCapacityProjectionRow = {
  capacity_period_id: string
  period_start: string
  period_end: string
  capacity_unit: PersonCapacityUnit
  capacity_status: PersonCapacityPeriodStatus
  capacity_amount: number | string
  allocated_current_amount: number | string
  available_amount: number | string
  utilization_percentage: number | string | null
  overallocation_amount: number | string
  is_overallocated: boolean
  current_allocation_count: number | string
}

type PersonCapacityNotesRow = {
  id: string
  notes: string | null
}

export async function loadPersonCapacityPeriods(
  organizationId: string,
  organizationPersonId: string,
): Promise<PersonCapacityPeriod[]> {
  const [projectionResult, notesResult] = await Promise.all([
    supabase.rpc(
      'get_sparks_person_capacity_projection',
      {
        target_organization_id: organizationId,
        target_organization_person_id:
          organizationPersonId,
        target_period_start: null,
        target_period_end: null,
      },
    ),
    supabase
      .from('sparks_person_capacity_periods')
      .select('id, notes')
      .eq('organization_id', organizationId)
      .eq(
        'organization_person_id',
        organizationPersonId,
      ),
  ])

  if (projectionResult.error) {
    throw new Error(
      `Não foi possível carregar os períodos de capacidade: ${projectionResult.error.message}`,
    )
  }

  if (notesResult.error) {
    throw new Error(
      `Não foi possível carregar as observações dos períodos de capacidade: ${notesResult.error.message}`,
    )
  }

  const notesByPeriodId = new Map(
    ((notesResult.data ?? []) as PersonCapacityNotesRow[]).map(
      (row) => [row.id, row.notes],
    ),
  )

  return (
    (projectionResult.data ?? []) as PersonCapacityProjectionRow[]
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
    notes:
      notesByPeriodId.get(row.capacity_period_id) ??
      null,
  }))
}

export async function createPersonCapacityPeriod(
  organizationId: string,
  command: PersonCapacityPeriodCreateCommand,
) {
  const { data, error } = await supabase.rpc(
    'set_sparks_person_capacity_period',
    {
      target_organization_id: organizationId,
      target_capacity_period_id: null,
      target_organization_person_id:
        command.organizationPersonId,
      target_period_start: command.periodStart,
      target_period_end: command.periodEnd,
      target_capacity_amount:
        command.capacityAmount,
      target_capacity_unit:
        command.capacityUnit,
      target_status: command.status,
      target_notes: command.notes,
      change_reason: command.changeReason,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível registrar o período de capacidade: ${error.message}`,
    )
  }

  return data
}

export async function transitionPersonCapacityPeriod(
  organizationId: string,
  organizationPersonId: string,
  period: PersonCapacityPeriod,
  command: PersonCapacityPeriodTransitionCommand,
) {
  const { data, error } = await supabase.rpc(
    'set_sparks_person_capacity_period',
    {
      target_organization_id: organizationId,
      target_capacity_period_id:
        period.capacityPeriodId,
      target_organization_person_id:
        organizationPersonId,
      target_period_start: period.periodStart,
      target_period_end: period.periodEnd,
      target_capacity_amount:
        period.capacityAmount,
      target_capacity_unit: period.capacityUnit,
      target_status: command.targetStatus,
      target_notes: period.notes,
      change_reason: command.changeReason,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível alterar a situação do período de capacidade: ${error.message}`,
    )
  }

  return data
}
