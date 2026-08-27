import { supabase } from '../../../lib/supabase'

export async function loadInitiativeActionCapacityManagementPermission(
  organizationId: string,
): Promise<boolean> {
  const { data, error } = await supabase.rpc(
    'can_manage_sparks_people',
    {
      target_organization_id: organizationId,
    },
  )

  if (error) {
    throw new Error(
      error.message ||
        'Não foi possível verificar a permissão de gestão de capacidade.',
    )
  }

  return data === true
}
