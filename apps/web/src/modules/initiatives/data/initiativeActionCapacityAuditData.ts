import { supabase } from '../../../lib/supabase'

export type InitiativeActionCapacityAuditEntry = {
  auditId: string
  actionCode: string
  changeReason: string
  occurredAt: string
  previousData: Record<string, unknown> | null
  newData: Record<string, unknown> | null
}

type InitiativeActionCapacityAuditRow = {
  id: string
  action_code: string
  change_reason: string
  occurred_at: string
  previous_data: Record<string, unknown> | null
  new_data: Record<string, unknown> | null
}

export async function loadInitiativeActionCapacityAllocationAudit(
  organizationId: string,
  allocationId: string,
): Promise<InitiativeActionCapacityAuditEntry[]> {
  const { data, error } = await supabase
    .from('sparks_capacity_audit')
    .select(
      'id,action_code,change_reason,occurred_at,previous_data,new_data',
    )
    .eq('organization_id', organizationId)
    .eq('entity_type', 'capacity_allocation')
    .eq('entity_id', allocationId)
    .order('occurred_at', { ascending: false })
    .limit(20)

  if (error) {
    throw new Error(
      `Não foi possível carregar o histórico da alocação de capacidade: ${error.message}`,
    )
  }

  return ((data ?? []) as InitiativeActionCapacityAuditRow[]).map(
    (row) => ({
      auditId: row.id,
      actionCode: row.action_code,
      changeReason: row.change_reason,
      occurredAt: row.occurred_at,
      previousData: row.previous_data,
      newData: row.new_data,
    }),
  )
}
