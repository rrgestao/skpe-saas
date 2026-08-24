import { supabase } from '../../../lib/supabase'

export type InitiativeLifecycleTarget =
  | 'cancelled'
  | 'archived'

type TransitionInitiativeLifecycleCommand = {
  initiativeId: string
  targetStatus: InitiativeLifecycleTarget
  changeReason: string
}

export async function transitionInitiativeLifecycle(
  command: TransitionInitiativeLifecycleCommand,
): Promise<void> {
  const { error } = await supabase.rpc(
    'transition_sparks_initiative_lifecycle',
    {
      target_initiative_id: command.initiativeId,
      target_status: command.targetStatus,
      change_reason: command.changeReason,
    },
  )

  if (error) {
    throw new Error(error.message)
  }
}