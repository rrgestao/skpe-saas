import type { Edge, Node } from '@xyflow/react'

import type {
  StrategicMapObjective,
  StrategicMapPayload,
  StrategicMapPerspective,
  StrategicMapRelation,
} from '../../contracts/strategic-map.ts'

export type StrategicMapNodeData = {
  objective: StrategicMapObjective
  perspective: StrategicMapPerspective | null
  persistedPosition: boolean
}

export type StrategicMapEdgeData = {
  relation: StrategicMapRelation
}

export type StrategicMapNode = Node<StrategicMapNodeData, 'strategicObjective'>
export type StrategicMapEdge = Edge<StrategicMapEdgeData>

const FALLBACK_X_STEP = 340
const FALLBACK_Y_STEP = 220

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

function fallbackPosition(
  objective: StrategicMapObjective,
  perspective: StrategicMapPerspective | null,
): { x: number; y: number } {
  const perspectiveOrder = perspective?.displayOrder ?? 0
  const objectiveOrder = Number.isFinite(objective.displayOrder)
    ? objective.displayOrder
    : 100

  return {
    x: Math.max(0, objectiveOrder) * FALLBACK_X_STEP,
    y: Math.max(0, perspectiveOrder) * FALLBACK_Y_STEP,
  }
}

export function strategicMapToReactFlow(payload: StrategicMapPayload): {
  nodes: StrategicMapNode[]
  edges: StrategicMapEdge[]
} {
  const perspectiveById = new Map(
    payload.perspectives.map((perspective) => [perspective.id, perspective]),
  )

  const nodes: StrategicMapNode[] = payload.objectives.map((objective) => {
    const perspective = objective.perspectiveId
      ? (perspectiveById.get(objective.perspectiveId) ?? null)
      : null
    const persistedPosition = readStrategicMapPosition(objective.mapPosition)

    return {
      id: objective.id,
      type: 'strategicObjective',
      position:
        persistedPosition ?? fallbackPosition(objective, perspective),
      data: {
        objective,
        perspective,
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