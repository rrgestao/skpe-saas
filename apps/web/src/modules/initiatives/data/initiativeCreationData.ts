import { supabase } from '../../../lib/supabase'

import {
  type CreateInitiativeCommand,
  resolveInitiativeCreationTaxonomy,
} from '../contracts/initiativeCreation'

export async function createInitiative(
  command: CreateInitiativeCommand,
): Promise<string> {
  const taxonomy =
    resolveInitiativeCreationTaxonomy(command.kind)

  const { data, error } = await supabase.rpc(
    'create_sparks_initiative',
    {
      target_organization_id:
        command.organizationId,

      target_initiative_class:
        taxonomy.initiativeClass,

      target_category_code:
        taxonomy.categoryCode,

      target_code:
        command.code,

      target_name:
        command.name,

      target_description:
        command.description,

      target_priority:
        command.priority,

      target_criticality:
        command.criticality,

      target_responsible_area_id:
        command.responsibleAreaId,

      target_parent_initiative_id:
        command.parentInitiativeId,

      target_proposal_origin:
        command.proposalOrigin,

      target_source_module_code:
        command.sourceModuleCode,

      target_proposal_source_reference:
        command.proposalSourceReference,

      target_strategic_theme:
        command.strategicTheme,

      target_start_date:
        command.startDate,

      target_end_date:
        command.targetEndDate,

      change_reason:
        command.changeReason,
    },
  )

  if (error) {
    throw new Error(error.message)
  }

  if (
    typeof data !== 'string' ||
    data.length === 0
  ) {
    throw new Error(
      'A criação da iniciativa não retornou um identificador válido.',
    )
  }

  return data
}