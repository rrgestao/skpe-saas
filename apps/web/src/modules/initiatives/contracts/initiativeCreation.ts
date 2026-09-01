export type InitiativeCreationKind =
  | 'strategic_project'
  | 'strategic_program'
  | 'structuring_action'
  | 'process'
  | 'sprint'
  | 'task'
  | 'work'

export type InitiativeClass =
  | 'project'
  | 'program'
  | 'structuring_action'
  | 'process'
  | 'sprint'
  | 'task'
  | 'work'

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
      return { initiativeClass: 'project', categoryCode: 'strategic' }
    case 'strategic_program':
      return { initiativeClass: 'program', categoryCode: 'strategic' }
    case 'structuring_action':
      return { initiativeClass: 'structuring_action', categoryCode: 'strategic' }
    case 'process':
      return { initiativeClass: 'process', categoryCode: 'process' }
    case 'sprint':
      return { initiativeClass: 'sprint', categoryCode: 'operational' }
    case 'task':
      return { initiativeClass: 'task', categoryCode: 'operational' }
    case 'work':
      return { initiativeClass: 'work', categoryCode: 'operational' }
  }
}