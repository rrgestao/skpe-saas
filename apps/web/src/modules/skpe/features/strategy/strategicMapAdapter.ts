import type { Edge, Node } from '@xyflow/react'

import type {
  StrategicMapObjective,
  StrategicMapPayload,
  StrategicMapPerspective,
  StrategicMapRelation,
  StrategicMapTheme,
} from '../../contracts/strategic-map.ts'

export type StrategicMapNodeData = {
  objective: StrategicMapObjective
  perspective: StrategicMapPerspective | null
  theme: StrategicMapTheme | null
  persistedPosition: boolean
}

export type StrategicMapEdgeData = {
  relation: StrategicMapRelation
}

export type StrategicMapNode = Node<StrategicMapNodeData, 'strategicObjective'>
export type StrategicMapEdge = Edge<StrategicMapEdgeData>

const FALLBACK_X_START = 80
const FALLBACK_X_STEP = 340
const FALLBACK_Y_START = 60
const FALLBACK_Y_STEP = 230

function isFiniteNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value)
}

export function readStrategicMapPosition(
  value: unknown,
): { x: number; y: number } | null {
  if (!value || typeof value !== 'object') return null

  const candidate = value as Record<string, unknown>
  if (!isFiniteNumber(candidate.x) || !isFiniteNumber(candidate.y)) return null

  return { x: candidate.x, y: candidate.y }
}

export function strategicMapToReactFlow(payload: StrategicMapPayload): {
  nodes: StrategicMapNode[]
  edges: StrategicMapEdge[]
} {
  const orderedPerspectives = [...payload.perspectives].sort(
    (first, second) =>
      first.displayOrder - second.displayOrder ||
      first.code.localeCompare(second.code, 'pt-BR'),
  )

  const perspectiveById = new Map(
    orderedPerspectives.map((perspective) => [perspective.id, perspective]),
  )

  const perspectiveIndexById = new Map(
    orderedPerspectives.map((perspective, index) => [perspective.id, index]),
  )

  const themeById = new Map(payload.themes.map((theme) => [theme.id, theme]))

  const orderedObjectives = [...payload.objectives].sort((first, second) => {
    const firstPerspectiveIndex = first.perspectiveId
      ? (perspectiveIndexById.get(first.perspectiveId) ?? Number.MAX_SAFE_INTEGER)
      : Number.MAX_SAFE_INTEGER
    const secondPerspectiveIndex = second.perspectiveId
      ? (perspectiveIndexById.get(second.perspectiveId) ?? Number.MAX_SAFE_INTEGER)
      : Number.MAX_SAFE_INTEGER

    return (
      firstPerspectiveIndex - secondPerspectiveIndex ||
      first.code.localeCompare(second.code, 'pt-BR')
    )
  })

  const slotByPerspective = new Map<string, number>()

  const nodes: StrategicMapNode[] = orderedObjectives.map((objective) => {
    const perspective = objective.perspectiveId
      ? (perspectiveById.get(objective.perspectiveId) ?? null)
      : null
    const theme = objective.strategicThemeId
      ? (themeById.get(objective.strategicThemeId) ?? null)
      : null
    const persistedPosition = readStrategicMapPosition(objective.mapPosition)

    let position = persistedPosition

    if (!position) {
      const perspectiveKey = perspective?.id ?? '__without_perspective__'
      const slot = slotByPerspective.get(perspectiveKey) ?? 0
      slotByPerspective.set(perspectiveKey, slot + 1)

      const perspectiveIndex = perspective
        ? (perspectiveIndexById.get(perspective.id) ?? orderedPerspectives.length)
        : orderedPerspectives.length

      position = {
        x: FALLBACK_X_START + slot * FALLBACK_X_STEP,
        y: FALLBACK_Y_START + perspectiveIndex * FALLBACK_Y_STEP,
      }
    }

    return {
      id: objective.id,
      type: 'strategicObjective',
      position,
      data: {
        objective,
        perspective,
        theme,
        persistedPosition: persistedPosition !== null,
      },
      draggable: true,
      selectable: true,
    }
  })

  const objectiveIds = new Set(payload.objectives.map((objective) => objective.id))

  const edges: StrategicMapEdge[] = payload.relations
    .filter(
      (relation) =>
        objectiveIds.has(relation.sourceObjectiveId) &&
        objectiveIds.has(relation.targetObjectiveId),
    )
    .map((relation) => ({
      id: relation.id,
      source: relation.sourceObjectiveId,
      target: relation.targetObjectiveId,
      data: { relation },
      type: 'smoothstep',
    }))

  return { nodes, edges }
}