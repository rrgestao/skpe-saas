import { supabase } from '../../../lib/supabase'

export type InitiativeActionCapacityAuditEntry = {
  auditId: string
  actorUserId: string | null
  actorName: string | null
  actionCode: string
  changeReason: string
  occurredAt: string
  previousData: Record<string, unknown> | null
  newData: Record<string, unknown> | null
}

type InitiativeActionCapacityAuditRow = {
  id: string
  actor_user_id: string | null
  action_code: string
  change_reason: string
  occurred_at: string
  previous_data: Record<string, unknown> | null
  new_data: Record<string, unknown> | null
}

type SparksPersonActorRow = {
  profile_user_id: string | null
  full_name: string
  preferred_name: string | null
}

export async function loadInitiativeActionCapacityAllocationAudit(
  organizationId: string,
  allocationId: string,
): Promise<InitiativeActionCapacityAuditEntry[]> {
  const { data, error } = await supabase
    .from('sparks_capacity_audit')
    .select(
      'id,actor_user_id,action_code,change_reason,occurred_at,previous_data,new_data',
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

  const rows = (data ?? []) as InitiativeActionCapacityAuditRow[]
  const actorUserIds = Array.from(
    new Set(
      rows
        .map((row) => row.actor_user_id)
        .filter((value): value is string => Boolean(value)),
    ),
  )

  const actorNames = new Map<string, string>()

  if (actorUserIds.length > 0) {
    const { data: peopleData, error: peopleError } = await supabase
      .from('sparks_people')
      .select('profile_user_id,full_name,preferred_name')
      .in('profile_user_id', actorUserIds)

    if (!peopleError) {
      for (const person of (peopleData ?? []) as SparksPersonActorRow[]) {
        if (!person.profile_user_id || actorNames.has(person.profile_user_id)) {
          continue
        }

        actorNames.set(
          person.profile_user_id,
          person.preferred_name?.trim() || person.full_name,
        )
      }
    }
  }

  return rows.map((row) => ({
    auditId: row.id,
    actorUserId: row.actor_user_id,
    actorName: row.actor_user_id
      ? actorNames.get(row.actor_user_id) ?? null
      : null,
    actionCode: row.action_code,
    changeReason: row.change_reason,
    occurredAt: row.occurred_at,
    previousData: row.previous_data,
    newData: row.new_data,
  }))
}
