import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import {
  applyNodeChanges,
  Background,
  Controls,
  Handle,
  MarkerType,
  NodeResizer,
  Position,
  ReactFlow,
  type Edge,
  type Node,
  type NodeChange,
  type NodeProps,
  type ReactFlowInstance,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'

import { supabase } from '../../../../lib/supabase'

import type {
  StrategicMapObjective,
  StrategicMapPayload,
  StrategicMapPerspective,
  StrategicMapRelation,
  StrategicMapTheme,
} from '../../contracts/strategic-map.ts'
import {
  BSC_OBJECTIVE_HEIGHT,
  BSC_OBJECTIVE_WIDTH,
  buildStrategicBscLayout,
} from './strategicBscLayout.ts'
import {
  resolveStrategicCauseEffectSuggestions,
  type ResolvedStrategicCauseEffectSuggestion,
} from './strategicCauseEffectSuggestions.ts'
import { loadStrategicMap } from './strategicMapLoader.ts'

import './StrategicBscMap.css'

export type StrategicObjectiveSignalTone =
  | 'green'
  | 'yellow'
  | 'red'
  | 'blue'
  | 'gray'

type Props = {
  formulationId: string | null
  objectiveSignals?: Record<string, StrategicObjectiveSignalTone>
  canAdjustLayout?: boolean
  onObjectiveInitiativesDrilldown?: (
    objectiveId: string,
    objectiveTitle: string,
    initiativeIds: string[],
  ) => void
  onObjectivePerformanceDrilldown?: (
    objectiveId: string,
    objectiveTitle: string,
  ) => void
}

type LaneData = {
  perspective: StrategicMapPerspective
  visualIndex: number
  canResize: boolean
}

type ThemeGroupData = {
  theme: StrategicMapTheme
  perspective: StrategicMapPerspective
  visualIndex: number
  canResize: boolean
}

type InitiativeExecutionTone = 'green' | 'yellow' | 'red' | 'blue' | 'gray'

type LinkedInitiativeExecution = {
  id: string
  code: string
  name: string
  status: string
  progress: number | null
  startDate: string | null
  dueDate: string | null
  expectedProgress: number | null
  adherence: number | null
  executionTone: InitiativeExecutionTone
}

type ObjectiveInitiativeExecution = {
  initiatives: LinkedInitiativeExecution[]
}

type ObjectiveData = {
  objective: StrategicMapObjective
  theme: StrategicMapTheme
  signalTone: StrategicObjectiveSignalTone
  signalLabel: string
  initiativeExecution: ObjectiveInitiativeExecution | null
  canResize: boolean
  onInitiativesDrilldown?: (
    objectiveId: string,
    objectiveTitle: string,
    initiativeIds: string[],
  ) => void
  onPerformanceDrilldown?: (
    objectiveId: string,
    objectiveTitle: string,
  ) => void
}

type LaneNode = Node<LaneData, 'bscPerspectiveLane'>
type ThemeGroupNode = Node<ThemeGroupData, 'bscThemeGroup'>
type ObjectiveNodeType = Node<ObjectiveData, 'bscObjective'>
type BscNode = LaneNode | ThemeGroupNode | ObjectiveNodeType

type BscEdgeData = {
  relation?: StrategicMapRelation
  suggestion?: ResolvedStrategicCauseEffectSuggestion
}

type BscEdge = Edge<BscEdgeData>

type RelationRouteMode = 'auto' | 'vertical' | 'right' | 'left'
type SavedRelationRoutes = Record<string, RelationRouteMode>

type SavedNodeLayout = {
  x: number
  y: number
  width?: number
  height?: number
}

type SavedLayout = Record<string, SavedNodeLayout>

function initiativeStatusLabel(status: string) {
  switch (status) {
    case 'in_progress':
      return 'Em andamento'
    case 'completed':
      return 'Concluída'
    case 'cancelled':
      return 'Cancelada'
    case 'on_hold':
      return 'Em espera'
    case 'blocked':
      return 'Bloqueada'
    case 'planned':
      return 'Planejada'
    case 'proposed':
      return 'Proposta'
    default:
      return status.replaceAll('_', ' ')
  }
}

function clampPercent(value: number) {
  return Math.max(0, Math.min(100, value))
}

function formatExecutionPercent(value: number | null) {
  return value == null
    ? 'não apurado'
    : `${value.toLocaleString('pt-BR', { maximumFractionDigits: 1 })}%`
}

function calculateExpectedInitiativeProgress(
  startDate: string | null,
  dueDate: string | null,
  now = Date.now(),
) {
  if (!startDate || !dueDate) return null

  const start = Date.parse(startDate)
  const due = Date.parse(dueDate)
  if (!Number.isFinite(start) || !Number.isFinite(due) || due <= start) return null

  if (now <= start) return 0
  if (now >= due) return 100

  return clampPercent(((now - start) / (due - start)) * 100)
}

function classifyInitiativeExecution(
  status: string,
  progress: number | null,
  expectedProgress: number | null,
): { tone: InitiativeExecutionTone; adherence: number | null } {
  if (status === 'blocked') {
    return {
      tone: 'red',
      adherence:
        progress != null && expectedProgress != null && expectedProgress > 0
          ? (progress / expectedProgress) * 100
          : null,
    }
  }

  if (progress == null || expectedProgress == null) {
    return { tone: 'gray', adherence: null }
  }

  if (expectedProgress <= 0) {
    if (progress > 0) return { tone: 'green', adherence: 100 }
    if (['planned', 'proposed', 'approved'].includes(status)) {
      return { tone: 'blue', adherence: null }
    }
    return { tone: 'gray', adherence: null }
  }

  const adherence = (progress / expectedProgress) * 100

  if (adherence >= 95) return { tone: 'green', adherence }
  if (adherence >= 75) return { tone: 'yellow', adherence }
  return { tone: 'red', adherence }
}

function initiativeExecutionWorstTone(
  execution: ObjectiveInitiativeExecution | null,
): InitiativeExecutionTone {
  if (!execution || execution.initiatives.length === 0) return 'gray'

  const rank: Record<InitiativeExecutionTone, number> = {
    green: 1,
    blue: 2,
    gray: 3,
    yellow: 4,
    red: 5,
  }

  return execution.initiatives.reduce<InitiativeExecutionTone>(
    (worst, initiative) =>
      rank[initiative.executionTone] > rank[worst]
        ? initiative.executionTone
        : worst,
    'green',
  )
}

function initiativeExecutionCountLabel(execution: ObjectiveInitiativeExecution) {
  const started = execution.initiatives.filter(
    (initiative) =>
      (initiative.progress ?? 0) > 0 ||
      ['in_progress', 'blocked', 'on_hold', 'completed'].includes(initiative.status),
  ).length

  return `${started}/${execution.initiatives.length} iniciativas`
}

function initiativeAverageProgress(execution: ObjectiveInitiativeExecution) {
  const measured = execution.initiatives
    .map((initiative) => initiative.progress)
    .filter((progress): progress is number => progress != null)

  if (measured.length === 0) return null
  return measured.reduce((sum, progress) => sum + progress, 0) / measured.length
}

function initiativeExecutionAverageLabel(execution: ObjectiveInitiativeExecution) {
  return `Desempenho médio · ${formatExecutionPercent(
    initiativeAverageProgress(execution),
  )}`
}

function initiativeExecutionToneLabel(tone: InitiativeExecutionTone) {
  const labels: Record<InitiativeExecutionTone, string> = {
    green: 'verde — aderente ao esperado',
    yellow: 'amarelo — abaixo do esperado',
    red: 'vermelho — atraso relevante',
    blue: 'azul — planejada e ainda dentro da janela de início',
    gray: 'cinza — dados insuficientes para apuração',
  }
  return labels[tone]
}

function initiativeExecutionTooltip(execution: ObjectiveInitiativeExecution | null) {
  if (!execution || execution.initiatives.length === 0) {
    return 'Nenhuma iniciativa estratégica vinculada foi localizada para este Objetivo Estratégico.'
  }

  const worstTone = initiativeExecutionWorstTone(execution)
  const visible = execution.initiatives.slice(0, 6).map((initiative) =>
    [
      `${initiative.code} — ${initiative.name}`,
      initiativeStatusLabel(initiative.status),
      `real ${formatExecutionPercent(initiative.progress)}`,
      `esperado ${formatExecutionPercent(initiative.expectedProgress)}`,
      initiative.adherence == null
        ? 'aderência não apurada'
        : `aderência ${formatExecutionPercent(initiative.adherence)}`,
      initiativeExecutionToneLabel(initiative.executionTone),
    ].join(' — '),
  )
  const hidden = execution.initiatives.length - visible.length

  return [
    `${initiativeExecutionCountLabel(execution)} vinculadas ao OE.`,
    `${initiativeExecutionAverageLabel(execution)}.`,
    `Pior situação de execução: ${initiativeExecutionToneLabel(worstTone)}.`,
    ...visible,
    hidden > 0 ? `+ ${hidden} iniciativa(s) adicional(is).` : '',
    'Regra temporal: progresso esperado é linear entre início e término planejados. Aderência = progresso real / progresso esperado.',
    'Faixas aprovadas: verde >= 95% do esperado; amarelo entre 75% e 94,9%; vermelho < 75%; azul quando ainda não deveria ter iniciado; cinza quando faltam dados suficientes.',
    'Este é um sinal de execução das iniciativas vinculadas. O círculo de desempenho do OE continua reservado à sensibilização governada por KPI, meta e medição.',
  ].filter(Boolean).join('\n')
}

function objectiveSignalTooltip(
  tone: StrategicObjectiveSignalTone,
  execution: ObjectiveInitiativeExecution | null,
) {
  const performance =
    tone === 'gray'
      ? 'Ainda não sensibilizado — não há indicador, meta e medição governada suficiente para determinar o desempenho deste Objetivo Estratégico.'
      : `Desempenho governado do Objetivo Estratégico: ${tone}.`

  return `${performance}\n${initiativeExecutionTooltip(execution)}`
}

function PerspectiveLaneNode({ data }: NodeProps<LaneNode>) {
  return (
    <section className={`skpe-bsc-lane skpe-bsc-lane-${data.visualIndex % 5}`}>
      <NodeResizer
        isVisible={data.canResize}
        minWidth={700}
        minHeight={180}
      />
      <div className="skpe-bsc-lane-label">
        <small>{data.perspective.code}</small>
        <strong>{data.perspective.name}</strong>
        {data.perspective.description ? <p>{data.perspective.description}</p> : null}
      </div>
    </section>
  )
}

function ThemeGroupNode({ data }: NodeProps<ThemeGroupNode>) {
  return (
    <section className={`skpe-bsc-theme-group skpe-bsc-theme-${data.visualIndex % 4}`}>
      <NodeResizer
        isVisible={data.canResize}
        minWidth={320}
        minHeight={150}
      />
      <header>
        <span>{data.theme.code}</span>
        <strong>{data.theme.name}</strong>
      </header>
    </section>
  )
}

function ObjectiveNode({ data }: NodeProps<ObjectiveNodeType>) {
  const executionTone = initiativeExecutionWorstTone(data.initiativeExecution)

  return (
    <article
      className={`skpe-bsc-objective${
        data.initiativeExecution
          ? ` has-execution-${executionTone}`
          : ''
      }`}
    >
      <NodeResizer
        isVisible={data.canResize}
        minWidth={280}
        minHeight={88}
      />
      <Handle type="source" id="top" position={Position.Top} isConnectable={false} />
      <Handle type="source" id="right" position={Position.Right} isConnectable={false} />
      <Handle type="source" id="left" position={Position.Left} isConnectable={false} />
      <div className="skpe-bsc-objective-heading">
        <small>{data.objective.code}</small>
        <span
          className={`skpe-bsc-objective-signal nodrag nopan is-${data.signalTone}`}
          data-skpe-objective-action="performance"
          title="Abrir Medidas e Desempenho deste Objetivo Estratégico"
          aria-label={data.signalLabel}
          role={data.onPerformanceDrilldown ? 'button' : undefined}
          tabIndex={data.onPerformanceDrilldown ? 0 : undefined}
          onPointerDown={(event) => event.stopPropagation()}
          onClick={(event) => {
            if (!data.onPerformanceDrilldown) return
            event.stopPropagation()
            data.onPerformanceDrilldown(data.objective.id, data.objective.title)
          }}
          onKeyDown={(event) => {
            if (!data.onPerformanceDrilldown) return
            if (event.key !== 'Enter' && event.key !== ' ') return
            event.preventDefault()
            event.stopPropagation()
            data.onPerformanceDrilldown(data.objective.id, data.objective.title)
          }}
        />
      </div>
      <strong>{data.objective.title}</strong>
      {data.initiativeExecution ? (
        <div
          className="skpe-bsc-objective-execution nodrag nopan"
          data-skpe-objective-action="initiatives"
          title={initiativeExecutionTooltip(data.initiativeExecution)}
          aria-label={initiativeExecutionTooltip(data.initiativeExecution)}
          role={data.onInitiativesDrilldown ? 'button' : undefined}
          tabIndex={data.onInitiativesDrilldown ? 0 : undefined}
          onPointerDown={(event) => event.stopPropagation()}
          onClick={(event) => {
            if (!data.onInitiativesDrilldown) return
            event.stopPropagation()
            data.onInitiativesDrilldown(
              data.objective.id,
              data.objective.title,
              data.initiativeExecution?.initiatives.map((initiative) => initiative.id) ?? [],
            )
          }}
          onKeyDown={(event) => {
            if (!data.onInitiativesDrilldown) return
            if (event.key !== 'Enter' && event.key !== ' ') return
            event.preventDefault()
            event.stopPropagation()
            data.onInitiativesDrilldown(
              data.objective.id,
              data.objective.title,
              data.initiativeExecution?.initiatives.map((initiative) => initiative.id) ?? [],
            )
          }}
        >
          <span>{initiativeExecutionCountLabel(data.initiativeExecution)}</span>
          <span>{initiativeExecutionAverageLabel(data.initiativeExecution)}</span>
        </div>
      ) : null}
      <Handle type="target" id="bottom" position={Position.Bottom} isConnectable={false} />
      <Handle type="target" id="left" position={Position.Left} isConnectable={false} />
      <Handle type="target" id="right" position={Position.Right} isConnectable={false} />
    </article>
  )
}

const nodeTypes = {
  bscPerspectiveLane: PerspectiveLaneNode,
  bscThemeGroup: ThemeGroupNode,
  bscObjective: ObjectiveNode,
}

function storageKey(formulationId: string) {
  return `skpe:bsc-layout:${formulationId}`
}

function relationRouteStorageKey(formulationId: string) {
  return `skpe:bsc-relation-routes:${formulationId}`
}

function readSavedRelationRoutes(formulationId: string): SavedRelationRoutes {
  try {
    const raw = window.localStorage.getItem(relationRouteStorageKey(formulationId))
    if (!raw) return {}
    const parsed = JSON.parse(raw) as SavedRelationRoutes
    return parsed && typeof parsed === 'object' ? parsed : {}
  } catch {
    return {}
  }
}

function writeSavedRelationRoutes(
  formulationId: string,
  routes: SavedRelationRoutes,
) {
  try {
    window.localStorage.setItem(
      relationRouteStorageKey(formulationId),
      JSON.stringify(routes),
    )
  } catch {
    // Local presentation preference only.
  }
}

function readSavedLayout(formulationId: string): SavedLayout {
  try {
    const raw = window.localStorage.getItem(storageKey(formulationId))
    if (!raw) return {}
    const parsed = JSON.parse(raw) as SavedLayout
    return parsed && typeof parsed === 'object' ? parsed : {}
  } catch {
    return {}
  }
}

function writeSavedLayout(formulationId: string, layout: SavedLayout) {
  try {
    window.localStorage.setItem(storageKey(formulationId), JSON.stringify(layout))
  } catch {
    // Local presentation preference only.
  }
}

function clearSavedLayout(formulationId: string) {
  try {
    window.localStorage.removeItem(storageKey(formulationId))
  } catch {
    // Local presentation preference only.
  }
}

export function StrategicBscMap({
  formulationId,
  objectiveSignals,
  canAdjustLayout = false,
  onObjectiveInitiativesDrilldown,
  onObjectivePerformanceDrilldown,
}: Props) {
  const [payload, setPayload] = useState<StrategicMapPayload | null>(null)
  const [nodes, setNodes] = useState<BscNode[]>([])
  const [loading, setLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [adjustMode, setAdjustMode] = useState(false)
  const [showSuggestedRelations, setShowSuggestedRelations] = useState(true)
  const [objectiveInitiativeExecution, setObjectiveInitiativeExecution] = useState<
    Record<string, ObjectiveInitiativeExecution>
  >({})
  const [selectedRelationId, setSelectedRelationId] = useState<string | null>(null)
  const [relationRoutes, setRelationRoutes] = useState<SavedRelationRoutes>({})
  const flowRef = useRef<ReactFlowInstance<BscNode, BscEdge> | null>(null)
  const canvasRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    setRelationRoutes(
      formulationId ? readSavedRelationRoutes(formulationId) : {},
    )
    setSelectedRelationId(null)
  }, [formulationId])

  useEffect(() => {
    let active = true

    if (!formulationId) {
      setPayload(null)
      setNodes([])
      setErrorMessage('')
      setLoading(false)
      return () => {
        active = false
      }
    }

    const targetFormulationId = formulationId

    async function load() {
      setLoading(true)
      setErrorMessage('')

      try {
        const nextPayload = await loadStrategicMap(targetFormulationId)
        if (!active) return
        setPayload(nextPayload)
      } catch (error) {
        if (!active) return
        setPayload(null)
        setNodes([])
        setErrorMessage(
          error instanceof Error ? error.message : 'Não foi possível carregar o Mapa Estratégico.',
        )
      } finally {
        if (active) setLoading(false)
      }
    }

    void load()

    return () => {
      active = false
    }
  }, [formulationId])

  useEffect(() => {
    let active = true

    if (!formulationId) {
      setObjectiveInitiativeExecution({})
      return () => {
        active = false
      }
    }

    const targetFormulationId = formulationId

    async function loadObjectiveInitiativeExecution() {
      const { data: linkRows, error: linkError } = await supabase
        .from('skpe_sparks_initiative_strategic_links')
        .select('strategic_objective_id, sparks_initiative_id')
        .eq('formulation_id', targetFormulationId)
        .not('strategic_objective_id', 'is', null)

      if (!active) return
      if (linkError || !linkRows || linkRows.length === 0) {
        setObjectiveInitiativeExecution({})
        return
      }

      const initiativeIds = Array.from(
        new Set(
          linkRows
            .map((row) => row.sparks_initiative_id)
            .filter((value): value is string => typeof value === 'string' && value.length > 0),
        ),
      )

      if (initiativeIds.length === 0) {
        setObjectiveInitiativeExecution({})
        return
      }

      type InitiativeExecutionRow = {
        id: string
        code: string | null
        name: string | null
        status: string | null
        progress: number | null
        target_start_date?: string | null
        target_end_date?: string | null
        start_date?: string | null
        due_date?: string | null
        archived_at: string | null
      }

      let initiativeRows: InitiativeExecutionRow[] = []
      let initiativeError: unknown = null

      const datedTarget = await supabase
        .from('sparks_initiatives')
        .select(
          'id, code, name, status, progress, target_start_date, target_end_date, archived_at',
        )
        .in('id', initiativeIds)
        .is('archived_at', null)

      if (!datedTarget.error && datedTarget.data) {
        initiativeRows = datedTarget.data as unknown as InitiativeExecutionRow[]
      } else {
        const datedLegacy = await supabase
          .from('sparks_initiatives')
          .select('id, code, name, status, progress, start_date, due_date, archived_at')
          .in('id', initiativeIds)
          .is('archived_at', null)

        if (!datedLegacy.error && datedLegacy.data) {
          initiativeRows = datedLegacy.data as unknown as InitiativeExecutionRow[]
        } else {
          const fallback = await supabase
            .from('sparks_initiatives')
            .select('id, code, name, status, progress, archived_at')
            .in('id', initiativeIds)
            .is('archived_at', null)

          initiativeError = fallback.error
          initiativeRows = (fallback.data ?? []) as unknown as InitiativeExecutionRow[]
        }
      }

      if (!active) return
      if (initiativeError || initiativeRows.length === 0) {
        setObjectiveInitiativeExecution({})
        return
      }

      const initiativeById = new Map(
        initiativeRows.map((initiative) => [initiative.id, initiative]),
      )
      const next: Record<string, ObjectiveInitiativeExecution> = {}

      for (const link of linkRows) {
        const objectiveId = link.strategic_objective_id
        const initiative = initiativeById.get(link.sparks_initiative_id)
        if (!objectiveId || !initiative) continue

        if (!next[objectiveId]) next[objectiveId] = { initiatives: [] }
        if (next[objectiveId].initiatives.some((item) => item.id === initiative.id)) continue

        const startDate =
          initiative.target_start_date ??
          initiative.start_date ??
          null
        const dueDate =
          initiative.target_end_date ??
          initiative.due_date ??
          null
        const progress =
          typeof initiative.progress === 'number' && Number.isFinite(initiative.progress)
            ? clampPercent(initiative.progress)
            : null
        const expectedProgress = calculateExpectedInitiativeProgress(
          startDate,
          dueDate,
        )
        const execution = classifyInitiativeExecution(
          initiative.status ?? '',
          progress,
          expectedProgress,
        )

        next[objectiveId].initiatives.push({
          id: initiative.id,
          code: initiative.code ?? 'Iniciativa',
          name: initiative.name ?? 'Iniciativa sem nome',
          status: initiative.status ?? '',
          progress,
          startDate,
          dueDate,
          expectedProgress,
          adherence: execution.adherence,
          executionTone: execution.tone,
        })
      }

      setObjectiveInitiativeExecution(next)
    }

    void loadObjectiveInitiativeExecution()

    return () => {
      active = false
    }
  }, [formulationId])

  const suggestedRelations = useMemo(
    () =>
      payload
        ? resolveStrategicCauseEffectSuggestions(payload.objectives)
        : [],
    [payload],
  )

  const baseGraph = useMemo(() => {
    if (!payload) return { nodes: [] as BscNode[], edges: [] as BscEdge[] }

    const layout = buildStrategicBscLayout(payload)
    const saved = formulationId ? readSavedLayout(formulationId) : {}
    const laneByPerspectiveId = new Map(
      layout.lanes.map((lane) => [lane.perspective.id, lane]),
    )
    const groupByPair = new Map(
      layout.themeGroups.map((group) => [
        `${group.perspective.id}:${group.theme.id}`,
        group,
      ]),
    )

    const laneNodes: LaneNode[] = layout.lanes.map((lane) => ({
      id: lane.id,
      type: 'bscPerspectiveLane',
      position: { x: lane.x, y: lane.y },
      data: {
        perspective: lane.perspective,
        visualIndex: lane.visualIndex,
        canResize: adjustMode && canAdjustLayout,
      },
      draggable: false,
      selectable: adjustMode && canAdjustLayout,
      connectable: false,
      focusable: adjustMode && canAdjustLayout,
      style: {
        width: saved[lane.id]?.width ?? lane.width,
        height: saved[lane.id]?.height ?? lane.height,
        zIndex: 0,
        '--skpe-perspective-base':
          lane.perspective.visualColor ??
          'var(--organization-accent, var(--skpe-accent, #176b53))',
      } as React.CSSProperties,
    }))

    const themeNodes: ThemeGroupNode[] = layout.themeGroups.map((group) => {
      const lane = laneByPerspectiveId.get(group.perspective.id)
      if (!lane) throw new Error('Perspectiva do Tema não localizada.')

      return {
        id: group.id,
        type: 'bscThemeGroup',
        parentId: lane.id,
        extent: 'parent',
        position: { x: group.x - lane.x, y: group.y - lane.y },
        data: {
          theme: group.theme,
          perspective: group.perspective,
          visualIndex: group.themeVisualIndex,
          canResize: adjustMode && canAdjustLayout,
        },
        draggable: false,
        selectable: adjustMode && canAdjustLayout,
        connectable: false,
        focusable: adjustMode && canAdjustLayout,
        style: {
          width: saved[group.id]?.width ?? group.width,
          height: saved[group.id]?.height ?? group.height,
          zIndex: 1,
        },
      }
    })

    const objectiveNodes: ObjectiveNodeType[] = layout.objectives.map((model) => {
      const group = groupByPair.get(`${model.perspective.id}:${model.theme.id}`)
      if (!group) throw new Error('Grupo temático do Objetivo não localizado.')

      const defaultPosition = { x: model.x - group.x, y: model.y - group.y }

      const signalTone = objectiveSignals?.[model.id] ?? 'gray'
      const initiativeExecution = objectiveInitiativeExecution[model.id] ?? null

      return {
        id: model.id,
        type: 'bscObjective',
        parentId: group.id,
        extent: 'parent',
        position: saved[model.id] ?? defaultPosition,
        data: {
          objective: model.objective,
          theme: model.theme,
          signalTone,
          signalLabel: objectiveSignalTooltip(signalTone, initiativeExecution),
          initiativeExecution,
          canResize: adjustMode && canAdjustLayout,
          onInitiativesDrilldown: onObjectiveInitiativesDrilldown,
          onPerformanceDrilldown: onObjectivePerformanceDrilldown,
        },
        draggable: adjustMode && canAdjustLayout,
        selectable: adjustMode && canAdjustLayout,
        connectable: false,
        focusable: adjustMode && canAdjustLayout,
        style: {
          width: saved[model.id]?.width ?? BSC_OBJECTIVE_WIDTH,
          height: saved[model.id]?.height ?? BSC_OBJECTIVE_HEIGHT,
          zIndex: 5,
        },
      }
    })

    const objectiveLayoutById = new Map(
      layout.objectives.map((model) => [model.id, model]),
    )

    function edgeHandles(
      edgeId: string,
      sourceId: string,
      targetId: string,
    ) {
      const routeMode = relationRoutes[edgeId] ?? 'auto'

      if (routeMode === 'vertical') {
        return { sourceHandle: 'top', targetHandle: 'bottom' }
      }

      if (routeMode === 'right') {
        return { sourceHandle: 'right', targetHandle: 'left' }
      }

      if (routeMode === 'left') {
        return { sourceHandle: 'left', targetHandle: 'right' }
      }

      const source = objectiveLayoutById.get(sourceId)
      const target = objectiveLayoutById.get(targetId)

      if (!source || !target) {
        return { sourceHandle: 'top', targetHandle: 'bottom' }
      }

      if (source.perspective.id !== target.perspective.id) {
        return { sourceHandle: 'top', targetHandle: 'bottom' }
      }

      const sourceIsLeft = source.x <= target.x
      return sourceIsLeft
        ? { sourceHandle: 'right', targetHandle: 'left' }
        : { sourceHandle: 'left', targetHandle: 'right' }
    }

    const canonicalEdges: BscEdge[] = layout.edges.map(
      (edge): BscEdge => {
        const handles = edgeHandles(edge.id, edge.source, edge.target)
        return {
          id: edge.id,
          source: edge.source,
          target: edge.target,
          type: 'smoothstep',
          sourceHandle: handles.sourceHandle,
          targetHandle: handles.targetHandle,
          selectable: adjustMode && canAdjustLayout,
          focusable: adjustMode && canAdjustLayout,
          selected: selectedRelationId === edge.id,
          className:
            selectedRelationId === edge.id
              ? 'skpe-bsc-edge-canonical is-selected'
              : 'skpe-bsc-edge-canonical',
          data: { relation: edge.relation },
          zIndex: 6,
        }
      },
    )

    const hypothesisEdges: BscEdge[] = showSuggestedRelations
      ? suggestedRelations.map(
          (suggestion): BscEdge => {
            const edgeId = `suggested:${suggestion.sourceCode}:${suggestion.targetCode}`
            const handles = edgeHandles(
              edgeId,
              suggestion.sourceId,
              suggestion.targetId,
            )
            return {
              id: edgeId,
              source: suggestion.sourceId,
              target: suggestion.targetId,
              type: 'smoothstep',
              sourceHandle: handles.sourceHandle,
              targetHandle: handles.targetHandle,
              className:
                selectedRelationId === edgeId
                  ? 'skpe-bsc-edge-suggested is-selected'
                  : 'skpe-bsc-edge-suggested',
              selectable: adjustMode && canAdjustLayout,
              focusable: adjustMode && canAdjustLayout,
              selected: selectedRelationId === edgeId,
              data: { suggestion },
              markerEnd: { type: MarkerType.ArrowClosed },
              zIndex: 4,
            }
          },
        )
      : []

    return {
      nodes: [...laneNodes, ...themeNodes, ...objectiveNodes] as BscNode[],
      edges: [...canonicalEdges, ...hypothesisEdges],
    }
  }, [
    adjustMode,
    canAdjustLayout,
    formulationId,
    objectiveInitiativeExecution,
    objectiveSignals,
    onObjectiveInitiativesDrilldown,
    onObjectivePerformanceDrilldown,
    payload,
    relationRoutes,
    selectedRelationId,
    showSuggestedRelations,
    suggestedRelations,
  ])

  useEffect(() => {
    setNodes(baseGraph.nodes)
  }, [baseGraph.nodes])

  const handleNodesChange = useCallback(
    (changes: NodeChange<BscNode>[]) => {
      if (!adjustMode) return
      setNodes((currentNodes) => applyNodeChanges(changes, currentNodes))
    },
    [adjustMode],
  )

  const persistCurrentPositions = useCallback(() => {
    if (!formulationId || !canAdjustLayout) return
    const saved: SavedLayout = {}
    for (const node of nodes) {
      const styleWidth =
        typeof node.style?.width === 'number' ? node.style.width : undefined
      const styleHeight =
        typeof node.style?.height === 'number' ? node.style.height : undefined
      saved[node.id] = {
        x: node.position.x,
        y: node.position.y,
        width: node.measured?.width ?? styleWidth,
        height: node.measured?.height ?? styleHeight,
      }
    }
    writeSavedLayout(formulationId, saved)
  }, [canAdjustLayout, formulationId, nodes])

  const setRelationRoute = useCallback(
    (mode: RelationRouteMode) => {
      if (!formulationId || !canAdjustLayout || !selectedRelationId) return

      const nextRoutes = { ...relationRoutes }
      if (mode === 'auto') {
        delete nextRoutes[selectedRelationId]
      } else {
        nextRoutes[selectedRelationId] = mode
      }

      setRelationRoutes(nextRoutes)
      writeSavedRelationRoutes(formulationId, nextRoutes)
    },
    [
      canAdjustLayout,
      formulationId,
      relationRoutes,
      selectedRelationId,
    ],
  )

  const restoreDefaultLayout = useCallback(() => {
    if (!formulationId) return
    clearSavedLayout(formulationId)
    try {
      window.localStorage.removeItem(relationRouteStorageKey(formulationId))
    } catch {
      // Local presentation preference only.
    }
    setRelationRoutes({})
    setSelectedRelationId(null)
    setAdjustMode(false)
    const currentPayload = payload
    setPayload(null)
    queueMicrotask(() => setPayload(currentPayload))
  }, [formulationId, payload])

  const fitWholeMap = useCallback(() => {
    void flowRef.current?.fitView({ padding: 0.02, duration: 350 })
  }, [])

  const readableView = useCallback(() => {
    void flowRef.current?.setViewport(
      { x: 60, y: 28, zoom: 0.72 },
      { duration: 350 },
    )
  }, [])

  useEffect(() => {
    if (!canAdjustLayout && adjustMode) {
      setAdjustMode(false)
    }
  }, [adjustMode, canAdjustLayout])

  useEffect(() => {
    const element = canvasRef.current
    if (!element || adjustMode) return

    let previousWidth = element.clientWidth
    let previousHeight = element.clientHeight
    let frame = 0

    const observer = new ResizeObserver((entries) => {
      const nextWidth = Math.round(entries[0]?.contentRect.width ?? 0)
      const nextHeight = Math.round(entries[0]?.contentRect.height ?? 0)
      if (!nextWidth || !nextHeight) return
      if (nextWidth === previousWidth && nextHeight === previousHeight) return
      previousWidth = nextWidth
      previousHeight = nextHeight
      window.cancelAnimationFrame(frame)
      frame = window.requestAnimationFrame(() => {
        void flowRef.current?.fitView({ padding: 0.02, duration: 260 })
      })
    })

    observer.observe(element)

    return () => {
      window.cancelAnimationFrame(frame)
      observer.disconnect()
    }
  }, [adjustMode, payload])

  if (!formulationId) {
    return <article className="skpe-bsc-state"><h3>Mapa Estratégico</h3><p>Nenhuma versão explícita da Formulação foi localizada.</p></article>
  }

  if (loading) {
    return <article className="skpe-bsc-state"><h3>Mapa Estratégico</h3><p>Carregando Perspectivas, Temas e Objetivos Estratégicos.</p></article>
  }

  if (errorMessage) {
    return <article className="skpe-bsc-state skpe-bsc-state-error"><h3>Mapa Estratégico</h3><p>{errorMessage}</p></article>
  }

  if (!payload || payload.objectives.length === 0) {
    return <article className="skpe-bsc-state"><h3>Mapa Estratégico</h3><p>Nenhum Objetivo Estratégico está materializado nesta versão.</p></article>
  }

  return (
    <section className="skpe-bsc-map">
      <header className="skpe-bsc-map-header">
        <div>
          <small>Arquitetura Estratégica</small>
          <h3>Mapa Estratégico</h3>
        </div>
        <p>
          Perspectivas estruturam as faixas e Temas agrupam os Objetivos Estratégicos.
        </p>
      </header>{adjustMode && canAdjustLayout ? (
        <>
          <p className="skpe-bsc-adjust-note">
            Mova e redimensione Objetivos Estratégicos, Perspectivas e Temas.
            Selecione uma relação para ajustar somente sua rota visual, sem alterar
            origem ou destino estratégico.
          </p>

          {selectedRelationId ? (
            <div
              className="skpe-bsc-relation-route-toolbar"
              aria-label="Ajuste visual da relação selecionada"
            >
              <strong>Rota da relação</strong>
              {([
                ['auto', 'Automática'],
                ['vertical', 'Vertical'],
                ['right', 'Pela direita'],
                ['left', 'Pela esquerda'],
              ] as const).map(([mode, label]) => (
                <button
                  key={mode}
                  type="button"
                  className={
                    (relationRoutes[selectedRelationId] ?? 'auto') === mode
                      ? 'is-active'
                      : undefined
                  }
                  onClick={() => setRelationRoute(mode)}
                >
                  {label}
                </button>
              ))}
            </div>
          ) : null}
        </>
      ) : null}

      <div
        ref={canvasRef}
        className="skpe-bsc-map-canvas"
        aria-label="Mapa Estratégico"
      >
        <div className="skpe-bsc-toolbar">
                {canAdjustLayout ? (
                  <button
                    type="button"
                    className={adjustMode ? 'is-active' : undefined}
                    onClick={() => {
                      if (adjustMode) {
                        persistCurrentPositions()
                        setAdjustMode(false)
                        window.requestAnimationFrame(() => {
                          void flowRef.current?.fitView({ padding: 0.02, duration: 320 })
                        })
                        return
                      }
                      setAdjustMode(true)
                    }}
                  >
                    {adjustMode ? 'Concluir ajustes' : 'Ajustar mapa'}
                  </button>
                ) : null}

                <button type="button" onClick={readableView}>Visão legível</button>
                <button type="button" onClick={fitWholeMap}>Ajustar à tela</button>
                <button type="button" onClick={restoreDefaultLayout}>Restaurar padrão</button>

                {suggestedRelations.length > 0 ? (
                  <button
                    type="button"
                    onClick={() => setShowSuggestedRelations((current) => !current)}
                  >
                    {showSuggestedRelations
                      ? 'Ocultar relações'
                      : 'Exibir relações'}
                  </button>
                ) : null}
              </div>

        <ReactFlow
          nodes={nodes}
          edges={baseGraph.edges}
          nodeTypes={nodeTypes}
          proOptions={{ hideAttribution: true }}
          onInit={(instance) => {
            flowRef.current = instance
            queueMicrotask(fitWholeMap)
          }}
          onNodesChange={handleNodesChange}
          onNodeDragStop={persistCurrentPositions}
          onEdgeClick={(_, edge) => {
            if (!adjustMode || !canAdjustLayout) return
            setSelectedRelationId(edge.id)
          }}
          onNodeClick={(event, node) => {
            if (node.type !== 'bscObjective') return

            const actionTarget = (
              event.target as HTMLElement | null
            )?.closest<HTMLElement>('[data-skpe-objective-action]')

            if (!actionTarget) return

            const objectiveNode = node as ObjectiveNodeType
            const action = actionTarget.dataset.skpeObjectiveAction

            if (action === 'performance') {
              objectiveNode.data.onPerformanceDrilldown?.(
                objectiveNode.data.objective.id,
                objectiveNode.data.objective.title,
              )
              return
            }

            if (action === 'initiatives') {
              objectiveNode.data.onInitiativesDrilldown?.(
                objectiveNode.data.objective.id,
                objectiveNode.data.objective.title,
                objectiveNode.data.initiativeExecution?.initiatives.map(
                  (initiative) => initiative.id,
                ) ?? [],
              )
            }
          }}
          onPaneClick={() => setSelectedRelationId(null)}
          nodesDraggable={adjustMode && canAdjustLayout}
          nodesConnectable={false}
          elementsSelectable={adjustMode && canAdjustLayout}
          panOnDrag
          zoomOnDoubleClick={false}
          deleteKeyCode={null}
          minZoom={0.32}
          maxZoom={1.35}
        >
          <Background gap={24} size={1} />
          <Controls showInteractive={false} />
        </ReactFlow>
      </div>
    </section>
  )
}
