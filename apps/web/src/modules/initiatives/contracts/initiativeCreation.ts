export type InitiativeCreationKind =
  | 'strategic_project'
  | 'strategic_program'
  | 'operational_improvement'
  | 'process_initiative'

export type InitiativeClass =
  | 'project'
  | 'program'
  | 'initiative'

export type InitiativeCategoryCode =
  | 'strategic'
  | 'operational'
  | 'process'

export type InitiativeCreationTaxonomy = {
  initiativeClass: InitiativeClass
  categoryCode: InitiativeCategoryCode
}

export type CreateInitiativeCommand = {
  organizationId: string
  kind: InitiativeCreationKind

  code: string
  name: string
  description: string | null

  priority: string
  criticality: string

  responsibleAreaId: string | null
  parentInitiativeId: string | null

  proposalOrigin: string
  sourceModuleCode: string
  proposalSourceReference: string | null

  strategicTheme: string | null

  startDate: string | null
  targetEndDate: string | null

  changeReason: string
}

export function resolveInitiativeCreationTaxonomy(
  kind: InitiativeCreationKind,
): InitiativeCreationTaxonomy {
  switch (kind) {
    case 'strategic_project':
      return {
        initiativeClass: 'project',
        categoryCode: 'strategic',
      }

    case 'strategic_program':
      return {
        initiativeClass: 'program',
        categoryCode: 'strategic',
      }

    case 'operational_improvement':
      return {
        initiativeClass: 'initiative',
        categoryCode: 'operational',
      }

    case 'process_initiative':
      return {
        initiativeClass: 'initiative',
        categoryCode: 'process',
      }
  }
}