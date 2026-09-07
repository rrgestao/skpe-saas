import type {
  StrategicMapObjective,
  StrategicMapPayload,
  StrategicMapPerspective,
  StrategicMapRelation,
  StrategicMapTheme,
} from '../../contracts/strategic-map.ts'

export const BSC_LANE_HEIGHT = 278
export const BSC_LANE_GAP = 28
export const BSC_LABEL_WIDTH = 288
export const BSC_OBJECTIVE_WIDTH = 372
export const BSC_OBJECTIVE_HEIGHT = 132
export const BSC_OBJECTIVE_GAP = 28
export const BSC_THEME_GROUP_PADDING = 30
export const BSC_THEME_GROUP_HEADER = 48
export const BSC_THEME_GROUP_GAP = 28
export const BSC_CANVAS_PADDING = 34

export type StrategicBscLaneModel = {
  id: string
  perspective: StrategicMapPerspective
  visualIndex: number
  x: number
  y: number
  width: number
  height: number
}

export type StrategicBscThemeGroupModel = {
  id: string
  perspective: StrategicMapPerspective
  theme: StrategicMapTheme
  themeVisualIndex: number
  x: number
  y: number
  width: number
  height: number
  objectiveIds: string[]
}

export type StrategicBscObjectiveModel = {
  id: string
  objective: StrategicMapObjective
  perspective: StrategicMapPerspective
  theme: StrategicMapTheme
  x: number
  y: number
}

export type StrategicBscEdgeModel = {
  id: string
  relation: StrategicMapRelation
  source: string
  target: string
}

export type StrategicBscLayout = {
  lanes: StrategicBscLaneModel[]
  themeGroups: StrategicBscThemeGroupModel[]
  objectives: StrategicBscObjectiveModel[]
  edges: StrategicBscEdgeModel[]
  width: number
  height: number
}

export function buildStrategicBscLayout(
  payload: StrategicMapPayload,
): StrategicBscLayout {
  const perspectives = [...payload.perspectives].sort(
    (first, second) =>
      second.displayOrder - first.displayOrder ||
      second.code.localeCompare(first.code, 'pt-BR'),
  )

  const themes = [...payload.themes].sort(
    (first, second) =>
      first.displayOrder - second.displayOrder ||
      first.code.localeCompare(second.code, 'pt-BR'),
  )

  const themeById = new Map(themes.map((theme) => [theme.id, theme]))
  const themeVisualIndex = new Map(
    themes.map((theme, index) => [theme.id, index]),
  )

  const objectivesByPerspective = new Map<string, StrategicMapObjective[]>()

  for (const objective of payload.objectives) {
    if (!objective.perspectiveId || !objective.strategicThemeId) continue

    const list = objectivesByPerspective.get(objective.perspectiveId) ?? []
    list.push(objective)
    objectivesByPerspective.set(objective.perspectiveId, list)
  }

  for (const list of objectivesByPerspective.values()) {
    list.sort((first, second) =>
      first.code.localeCompare(second.code, 'pt-BR'),
    )
  }

  const laneWidths = perspectives.map((perspective) => {
    const objectives = objectivesByPerspective.get(perspective.id) ?? []
    const grouped = new Map<string, StrategicMapObjective[]>()

    for (const objective of objectives) {
      if (!objective.strategicThemeId) continue
      const list = grouped.get(objective.strategicThemeId) ?? []
      list.push(objective)
      grouped.set(objective.strategicThemeId, list)
    }

    const groupWidths = [...grouped.values()].map(
      (groupObjectives) =>
        BSC_THEME_GROUP_PADDING * 2 +
        groupObjectives.length * BSC_OBJECTIVE_WIDTH +
        Math.max(0, groupObjectives.length - 1) * BSC_OBJECTIVE_GAP,
    )

    return (
      BSC_LABEL_WIDTH +
      BSC_THEME_GROUP_PADDING +
      groupWidths.reduce((sum, width) => sum + width, 0) +
      Math.max(0, groupWidths.length - 1) * BSC_THEME_GROUP_GAP
    )
  })

  const laneWidth = Math.max(
    BSC_LABEL_WIDTH + BSC_OBJECTIVE_WIDTH * 2 + 180,
    ...laneWidths,
  )

  const width = laneWidth + BSC_CANVAS_PADDING * 2
  const lanes: StrategicBscLaneModel[] = []
  const themeGroups: StrategicBscThemeGroupModel[] = []
  const objectiveModels: StrategicBscObjectiveModel[] = []

  perspectives.forEach((perspective, perspectiveIndex) => {
    const laneY =
      BSC_CANVAS_PADDING +
      perspectiveIndex * (BSC_LANE_HEIGHT + BSC_LANE_GAP)

    lanes.push({
      id: `perspective:${perspective.id}`,
      perspective,
      visualIndex: perspectiveIndex,
      x: BSC_CANVAS_PADDING,
      y: laneY,
      width: laneWidth,
      height: BSC_LANE_HEIGHT,
    })

    const objectives = objectivesByPerspective.get(perspective.id) ?? []
    const grouped = new Map<string, StrategicMapObjective[]>()

    for (const objective of objectives) {
      if (!objective.strategicThemeId) continue
      const list = grouped.get(objective.strategicThemeId) ?? []
      list.push(objective)
      grouped.set(objective.strategicThemeId, list)
    }

    const orderedGroups = [...grouped.entries()].sort(
      ([firstThemeId], [secondThemeId]) =>
        (themeVisualIndex.get(firstThemeId) ?? 999) -
        (themeVisualIndex.get(secondThemeId) ?? 999),
    )

    let groupX =
      BSC_CANVAS_PADDING +
      BSC_LABEL_WIDTH +
      BSC_THEME_GROUP_PADDING

    for (const [themeId, groupObjectives] of orderedGroups) {
      const theme = themeById.get(themeId)
      if (!theme) continue

      groupObjectives.sort((first, second) =>
        first.code.localeCompare(second.code, 'pt-BR'),
      )

      const groupWidth =
        BSC_THEME_GROUP_PADDING * 2 +
        groupObjectives.length * BSC_OBJECTIVE_WIDTH +
        Math.max(0, groupObjectives.length - 1) * BSC_OBJECTIVE_GAP

      themeGroups.push({
        id: `theme-group:${perspective.id}:${theme.id}`,
        perspective,
        theme,
        themeVisualIndex: themeVisualIndex.get(theme.id) ?? 0,
        x: groupX,
        y: laneY + 18,
        width: groupWidth,
        height: BSC_LANE_HEIGHT - 36,
        objectiveIds: groupObjectives.map((objective) => objective.id),
      })

      groupObjectives.forEach((objective, objectiveIndex) => {
        objectiveModels.push({
          id: objective.id,
          objective,
          perspective,
          theme,
          x:
            groupX +
            BSC_THEME_GROUP_PADDING +
            objectiveIndex * (BSC_OBJECTIVE_WIDTH + BSC_OBJECTIVE_GAP),
          y: laneY + BSC_THEME_GROUP_HEADER + 54,
        })
      })

      groupX += groupWidth + BSC_THEME_GROUP_GAP
    }
  })

  const renderedObjectiveIds = new Set(
    objectiveModels.map((model) => model.objective.id),
  )

  const edges = payload.relations
    .filter(
      (relation) =>
        renderedObjectiveIds.has(relation.sourceObjectiveId) &&
        renderedObjectiveIds.has(relation.targetObjectiveId),
    )
    .map((relation) => ({
      id: relation.id,
      relation,
      source: relation.sourceObjectiveId,
      target: relation.targetObjectiveId,
    }))

  const height =
    BSC_CANVAS_PADDING * 2 +
    perspectives.length * BSC_LANE_HEIGHT +
    Math.max(0, perspectives.length - 1) * BSC_LANE_GAP

  return {
    lanes,
    themeGroups,
    objectives: objectiveModels,
    edges,
    width,
    height,
  }
}