import { supabase } from '../../../lib/supabase'

import type { InitiativeParentCandidate } from '../contracts/initiativeParentCandidates'

export async function loadInitiativeParentCandidates(
  organizationId: string,
): Promise<InitiativeParentCandidate[]> {
  const { data, error } = await supabase.rpc(
    'get_sparks_initiative_parent_candidates',
    {
      target_organization_id: organizationId,
    },
  )

  if (error) {
    throw new Error(error.message)
  }

  return (data ?? []) as InitiativeParentCandidate[]
}