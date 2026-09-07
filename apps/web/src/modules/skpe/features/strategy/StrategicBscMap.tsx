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
  Position,
  ReactFlow,
  type Edge,
  type Node,
  type NodeChange,
  type NodeProps,
  type ReactFlowInstance,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'

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
}

type LaneData = {
  perspective: StrategicMapPerspective
  visualIndex: number
}

type ThemeGroupData = {
  theme: StrategicMapTheme
  perspective: StrategicMapPerspective
  visualIndex: number
}

type ObjectiveData = {
  objective: StrategicMapObjective
  theme: StrategicMapTheme
  signalTone: StrategicObjectiveSignalTone
  signalLabel: string
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

type SavedObjectivePosition = {
  x: number
  y: number
}

type SavedLayout = Record<string, SavedObjectivePosition>

function PerspectiveLaneNode({ data }: NodeProps<LaneNode>) {
  return (
    <section className={`skpe-bsc-lane skpe-bsc-lane-${data.visualIndex % 5}`}>
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
      <header>
        <span>{data.theme.code}</span>
        <strong>{data.theme.name}</strong>
      </header>
    </section>
  )
}

function ObjectiveNode({ data }: NodeProps<ObjectiveNodeType>) {
  return (
    <article className="skpe-bsc-objective">
      <Handle type="source" id="top" position={Position.Top} isConnectable={false} />
      <Handle type="source" id="right" position={Position.Right} isConnectable={false} />
      <Handle type="source" id="left" position={Position.Left} isConnectable={false} />
      <div className="skpe-bsc-objective-heading">
        <small>{data.objective.code}</small>
        <span
          className={`skpe-bsc-objective-signal is-${data.signalTone}`}
          title={data.signalLabel}
          aria-label={data.signalLabel}
        />
      </div>
      <strong>{data.objective.title}</strong>
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

export function StrategicBscMap({ formulationId, objectiveSignals }: Props) {
  const [payload, setPayload] = useState<StrategicMapPayload | null>(null)
  const [nodes, setNodes] = useState<BscNode[]>([])
  const [loading, setLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [adjustMode, setAdjustMode] = useState(false)
  const [showSuggestedRelations, setShowSuggestedRelations] = useState(true)
  const flowRef = useRef<ReactFlowInstance<BscNode, BscEdge> | null>(null)

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
      data: { perspective: lane.perspective, visualIndex: lane.visualIndex },
      draggable: false,
      selectable: false,
      connectable: false,
      focusable: false,
      style: { width: lane.width, height: lane.height, zIndex: 0 },
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
        },
        draggable: false,
        selectable: false,
        connectable: false,
        focusable: false,
        style: { width: group.width, height: group.height, zIndex: 1 },
      }
    })

    const saved = formulationId ? readSavedLayout(formulationId) : {}

    const objectiveNodes: ObjectiveNodeType[] = layout.objectives.map((model) => {
      const group = groupByPair.get(`${model.perspective.id}:${model.theme.id}`)
      if (!group) throw new Error('Grupo temático do Objetivo não localizado.')

      const defaultPosition = { x: model.x - group.x, y: model.y - group.y }

      return {
        id: model.id,
        type: 'bscObjective',
        parentId: group.id,
        extent: 'parent',
        position: saved[model.id] ?? defaultPosition,
        data: {
          objective: model.objective,
          theme: model.theme,
          signalTone: objectiveSignals?.[model.id] ?? 'gray',
          signalLabel:
            objectiveSignals?.[model.id] === 'green'
              ? 'Desempenho do Objetivo Estratégico: verde'
              : objectiveSignals?.[model.id] === 'yellow'
                ? 'Desempenho do Objetivo Estratégico: amarelo'
                : objectiveSignals?.[model.id] === 'red'
                  ? 'Desempenho do Objetivo Estratégico: vermelho'
                  : objectiveSignals?.[model.id] === 'blue'
                    ? 'Desempenho do Objetivo Estratégico: azul'
                    : 'Objetivo Estratégico ainda não sensibilizado',
        },
        draggable: adjustMode,
        selectable: adjustMode,
        connectable: false,
        focusable: adjustMode,
        style: { width: BSC_OBJECTIVE_WIDTH, height: BSC_OBJECTIVE_HEIGHT, zIndex: 5 },
      }
    })

    const objectiveLayoutById = new Map(
      layout.objectives.map((model) => [model.id, model]),
    )

    function edgeHandles(sourceId: string, targetId: string) {
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
        const handles = edgeHandles(edge.source, edge.target)
        return {
          id: edge.id,
          source: edge.source,
          target: edge.target,
          type: 'smoothstep',
          sourceHandle: handles.sourceHandle,
          targetHandle: handles.targetHandle,
          selectable: false,
          focusable: false,
          data: { relation: edge.relation },
          zIndex: 6,
        }
      },
    )

    const hypothesisEdges: BscEdge[] = showSuggestedRelations
      ? suggestedRelations.map(
          (suggestion): BscEdge => {
            const handles = edgeHandles(suggestion.sourceId, suggestion.targetId)
            return {
              id: `suggested:${suggestion.sourceCode}:${suggestion.targetCode}`,
              source: suggestion.sourceId,
              target: suggestion.targetId,
              type: 'smoothstep',
              sourceHandle: handles.sourceHandle,
              targetHandle: handles.targetHandle,
              className: 'skpe-bsc-edge-suggested',
              selectable: false,
              focusable: false,
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
  }, [adjustMode, formulationId, objectiveSignals, payload, showSuggestedRelations, suggestedRelations])

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
    if (!formulationId) return
    const saved: SavedLayout = {}
    for (const node of nodes) {
      if (node.type !== 'bscObjective') continue
      saved[node.id] = { x: node.position.x, y: node.position.y }
    }
    writeSavedLayout(formulationId, saved)
  }, [formulationId, nodes])

  const restoreDefaultLayout = useCallback(() => {
    if (!formulationId) return
    clearSavedLayout(formulationId)
    setAdjustMode(false)
    const currentPayload = payload
    setPayload(null)
    queueMicrotask(() => setPayload(currentPayload))
  }, [formulationId, payload])

  const fitWholeMap = useCallback(() => {
    void flowRef.current?.fitView({ padding: 0.08, duration: 350 })
  }, [])

  const readableView = useCallback(() => {
    void flowRef.current?.setViewport(
      { x: 60, y: 28, zoom: 0.72 },
      { duration: 350 },
    )
  }, [])

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
      </header>


      <div className="skpe-bsc-toolbar">
        <button
          type="button"
          className={adjustMode ? 'is-active' : undefined}
          onClick={() => {
            if (adjustMode) persistCurrentPositions()
            setAdjustMode((current) => !current)
          }}
        >
          {adjustMode ? 'Concluir ajustes' : 'Ajustar mapa'}
        </button>

        <button type="button" onClick={readableView}>Visão legível</button>
        <button type="button" onClick={fitWholeMap}>Ajustar à tela</button>
        <button type="button" onClick={restoreDefaultLayout}>Restaurar padrão</button>

        {suggestedRelations.length > 0 ? (
          <button
            type="button"
            className={showSuggestedRelations ? 'is-active' : undefined}
            onClick={() => setShowSuggestedRelations((current) => !current)}
          >
            {showSuggestedRelations
              ? 'Ocultar relações sugeridas'
              : 'Exibir relações sugeridas'}
          </button>
        ) : null}
      </div>

      {adjustMode ? (
        <p className="skpe-bsc-adjust-note">
          Mova os Objetivos dentro do respectivo Tema. Os limites de Tema e Perspectiva não podem ser ultrapassados.
        </p>
      ) : null}

      <div className="skpe-bsc-map-canvas" aria-label="Mapa Estratégico">
        <ReactFlow
          nodes={nodes}
          edges={baseGraph.edges}
          nodeTypes={nodeTypes}
          onInit={(instance) => {
            flowRef.current = instance
            queueMicrotask(readableView)
          }}
          onNodesChange={handleNodesChange}
          onNodeDragStop={persistCurrentPositions}
          nodesDraggable={adjustMode}
          nodesConnectable={false}
          elementsSelectable={adjustMode}
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