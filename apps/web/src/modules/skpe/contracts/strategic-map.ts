export type StrategicMapJsonObject = Record<string, unknown>

export type StrategicMapFormulation = {
  id: string
  organizationId: string
  projectId: string
  versionNumber: number
  versionLabel: string | null
  status: string
  validFrom: string | null
  validUntil: string | null
}

export type StrategicMapPackage = {
  id: string
  status: string
  themeRequired: boolean
  causalCyclePolicy: string
  ownerRecommended: boolean
  validationNotes: string | null
  submittedForValidationAt: string | null
  validatedAt: string | null
  metadata: StrategicMapJsonObject
  createdAt: string
  updatedAt: string
}

export type StrategicMapTheme = {
  id: string
  code: string
  name: string
  description: string | null
  rationale: string | null
  priority: string | null
  displayOrder: number
  horizonStart: string | null
  horizonEnd: string | null
  ownerUserId: string | null
  status: string
  visualColor: string | null
  metadata: StrategicMapJsonObject
  createdAt: string
  updatedAt: string
}

export type StrategicMapPerspective = {
  id: string
  code: string
  name: string
  description: string | null
  displayOrder: number
  status: string
  methodologicalNature: string | null
  perspectiveModel: string | null
  visualColor: string | null
  metadata: StrategicMapJsonObject
  createdAt: string
  updatedAt: string
}

export type StrategicMapObjective = {
  id: string
  code: string
  title: string
  description: string | null
  expectedResult: string | null
  rationale: string | null
  priority: string | null
  horizonStart: string | null
  horizonEnd: string | null
  ownerUserId: string | null
  status: string
  validationStatus: string
  progress: number
  strategicThemeId: string | null
  perspectiveId: string | null
  displayOrder: number
  mapPosition: unknown
  visualColor: string | null
  metadata: StrategicMapJsonObject
  createdAt: string
  updatedAt: string
}

export type StrategicMapRelation = {
  id: string
  sourceObjectiveId: string
  targetObjectiveId: string
  relationType: string
  contributionStrength: string | null
  relationWeight: unknown
  rationale: string | null
  displayOrder: number
  metadata: StrategicMapJsonObject
  createdAt: string
}

export type StrategicMapReadiness = StrategicMapJsonObject

export type StrategicMapPayload = {
  formulation: StrategicMapFormulation
  package: StrategicMapPackage | null
  themes: StrategicMapTheme[]
  perspectives: StrategicMapPerspective[]
  objectives: StrategicMapObjective[]
  relations: StrategicMapRelation[]
  readiness: StrategicMapReadiness
}