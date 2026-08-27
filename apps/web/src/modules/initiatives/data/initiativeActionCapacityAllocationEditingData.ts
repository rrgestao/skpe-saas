import { supabase } from '../../../lib/supabase'

import type { InitiativeActionCapacityAllocation } from '../contracts/initiativeActions'
import type { InitiativeActionCapacityAllocationEditCommand } from '../contracts/initiativeActionCapacityAllocationEditing'

export async function updateInitiativeActionCapacityAllocation(
  organizationId: string,
  actionId: string,
  allocation: InitiativeActionCapacityAllocation,
  command: InitiativeActionCapacityAllocationEditCommand,
) {
  const { data, error } = await supabase.rpc(
    'set_sparks_person_capacity_allocation',
    {
      target_organization_id: organizationId,
      target_allocation_id: allocation.allocationId,
      target_capacity_period_id: allocation.capacityPeriodId,
      target_module_code: 'SK-PE',
      target_object_type: 'initiative_action',
      target_object_id: actionId,
      target_allocation_start: command.allocationStart,
      target_allocation_end: command.allocationEnd,
      target_allocated_amount: command.allocatedAmount,
      target_status: allocation.status,
      target_notes: command.notes,
      change_reason: command.changeReason,
    },
  )

  if (error) {
    throw new Error(
      `Não foi possível editar a alocação de capacidade: ${error.message}`,
    )
  }

  return data
}
