import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
type PointerEvent as ReactPointerEvent,
} from 'react'
import {
  applyNodeChanges,
  BaseEdge,
  Background,
  Controls,
  Handle,
  NodeResizer,
  Position,
  ReactFlow,
  type Edge,
  type EdgeProps,
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
  personalResponsibilityReasons: string[]
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
  tooltip?: string
  targetPerspectiveWidth?: number
}

type BscEdge = Edge<BscEdgeData>
// SKPE_FE04_CAUSAL_ASSIST_V1
type CausalRelationConfidence = 'low' | 'medium' | 'high'

type CausalRelationDraft = {
  relationId: string | null
  sourceObjectiveId: string
  targetObjectiveId: string
  relationType:
    | 'cause_effect'
    | 'supports'
    | 'enables'
    | 'contributes_to'
    | 'depends_on'
    | 'influences'
  contributionStrength: 'low' | 'medium' | 'high'
  rationale: string
  confidence: CausalRelationConfidence
  assistanceScope: 'curated_hypothesis' | 'strategic_map_context'
}

function causalRelationTypeLabel(value: CausalRelationDraft['relationType']) {
  const labels: Record<CausalRelationDraft['relationType'], string> = {
    cause_effect: 'Causa e efeito',
    supports: 'Sustenta',
    enables: 'Habilita',
    contributes_to: 'Contribui para',
    depends_on: 'Depende de',
    influences: 'Influencia',
  }
  return labels[value] ?? value
}

function causalStrengthLabel(value: CausalRelationDraft['contributionStrength']) {
  return value === 'high' ? 'Alta' : value === 'low' ? 'Baixa' : 'Média'
}

function causalConfidenceLabel(value: CausalRelationConfidence) {
  return value === 'high' ? 'Alta' : value === 'low' ? 'Baixa' : 'Média'
}

type CausalIntegrityStatus = 'blocked' | 'fragile' | 'plausible'

function assessCausalIntegrity(
  payload: StrategicMapPayload,
  draft: CausalRelationDraft,
) {
  const source = payload.objectives.find(
    (objective) => objective.id === draft.sourceObjectiveId,
  )
  const target = payload.objectives.find(
    (objective) => objective.id === draft.targetObjectiveId,
  )

  if (!source || !target) {
    return {
      status: 'blocked' as CausalIntegrityStatus,
      title: 'Impossível registrar',
      message:
        'Selecione dois Objetivos Estratégicos válidos da mesma Formulação.',
    }
  }

  if (source.id === target.id) {
    return {
      status: 'blocked' as CausalIntegrityStatus,
      title: 'Impossível registrar',
      message:
        'Uma relação causal exige Objetivos distintos; um OE não pode causar efeito sobre si próprio.',
    }
  }

  const duplicate = payload.relations.some(
    (relation) =>
      relation.id !== draft.relationId &&
      relation.sourceObjectiveId === source.id &&
      relation.targetObjectiveId === target.id,
  )

  if (duplicate) {
    return {
      status: 'blocked' as CausalIntegrityStatus,
      title: 'Impossível registrar',
      message:
        'Já existe uma relação registrada entre estes Objetivos nesta direção. Edite a relação existente para preservar unicidade e rastreabilidade.',
    }
  }

  if (draft.rationale.trim().length < 80) {
    return {
      status: 'fragile' as CausalIntegrityStatus,
      title: 'Fragilidade metodológica',
      message:
        'O racional ainda é insuficiente para demonstrar o mecanismo causal. Descreva como o resultado do OE de origem cria condição, capacidade ou efeito que contribui para o OE de destino.',
    }
  }

  if (
    draft.assistanceScope === 'strategic_map_context' ||
    draft.confidence === 'low'
  ) {
    return {
      status: 'fragile' as CausalIntegrityStatus,
      title: 'Fragilidade de referência',
      message:
        'A hipótese está sustentada somente pelo contexto disponível no Mapa Estratégico. O diagnóstico, as análises de ambiente (PESTEL e SWOT/TOWS), os riscos e as evidências ainda não foram confrontados em uma visão consolidada e governada das informações.',
    }
  }

  return {
    status: 'plausible' as CausalIntegrityStatus,
    title: 'Hipótese metodologicamente plausível',
    message:
      'Há coerência suficiente para registrar a hipótese em elaboração. Isso não equivale à validação humana da relação causal.',
  }
}
function buildStrategicMapAssistedRationale(
  payload: StrategicMapPayload,
  sourceObjectiveId: string,
  targetObjectiveId: string,
  suggestions: ResolvedStrategicCauseEffectSuggestion[],
) {
  const source = payload.objectives.find(
    (objective) => objective.id === sourceObjectiveId,
  )
  const target = payload.objectives.find(
    (objective) => objective.id === targetObjectiveId,
  )

  if (!source || !target) {
    return {
      rationale: '',
      confidence: 'low' as CausalRelationConfidence,
      assistanceScope: 'strategic_map_context' as const,
    }
  }

  const curated = suggestions.find(
    (suggestion) =>
      suggestion.sourceId === sourceObjectiveId &&
      suggestion.targetId === targetObjectiveId,
  )

  if (curated) {
    const paragraphs = [
      curated.rationale.trim(),
      source.expectedResult?.trim()
        ? `No OE de origem, o resultado esperado é: ${source.expectedResult.trim()}`
        : '',
      target.expectedResult?.trim()
        ? `No OE de destino, o resultado esperado é: ${target.expectedResult.trim()}`
        : '',
      `Na lógica do Balanced Scorecard (BSC), que organiza relações de causa e efeito entre objetivos, esta relação é tratada como hipótese estratégica: o avanço de ${source.code} — ${source.title} deve produzir ou fortalecer condições que favoreçam ${target.code} — ${target.title}.`,
      'A hipótese deve ser confrontada com diagnóstico, PESTEL, SWOT/TOWS, riscos, evidências e demais artefatos metodológicos antes da validação humana do Mapa Estratégico.',
    ].filter(Boolean)

    return {
      rationale: paragraphs.join('\n\n'),
      confidence: 'high' as CausalRelationConfidence,
      assistanceScope: 'curated_hypothesis' as const,
    }
  }

  const sourceContext = [
    source.expectedResult?.trim(),
    source.rationale?.trim(),
    source.description?.trim(),
  ].filter(Boolean)
  const targetContext = [
    target.expectedResult?.trim(),
    target.rationale?.trim(),
    target.description?.trim(),
  ].filter(Boolean)

  const enoughContext = sourceContext.length >= 2 && targetContext.length >= 2
  const someContext = sourceContext.length > 0 && targetContext.length > 0

  return {
    rationale: [
      `Hipótese causal assistida para ${source.code} — ${source.title} → ${target.code} — ${target.title}.`,
      source.expectedResult?.trim()
        ? `O OE de origem busca produzir: ${source.expectedResult.trim()}`
        : '',
      target.expectedResult?.trim()
        ? `O OE de destino busca alcançar: ${target.expectedResult.trim()}`
        : '',
      source.rationale?.trim()
        ? `Racional disponível para o OE de origem: ${source.rationale.trim()}`
        : '',
      target.rationale?.trim()
        ? `Racional disponível para o OE de destino: ${target.rationale.trim()}`
        : '',
      'A relação é metodologicamente plausível somente se os resultados do OE de origem criarem condições, capacidades ou efeitos que contribuam materialmente para o OE de destino. Este texto não constitui validação: deve ser confrontado com diagnóstico, PESTEL, SWOT/TOWS, riscos, evidências e demais artefatos estratégicos antes da decisão humana.',
    ]
      .filter(Boolean)
      .join('\n\n'),
    confidence: (enoughContext
      ? 'medium'
      : someContext
        ? 'low'
        : 'low') as CausalRelationConfidence,
    assistanceScope: 'strategic_map_context' as const,
  }
}


// SKPE_MAP_RESPONSIBILITY_ROUTE_INTERACTION_V1
const BSC_RELATION_CORRIDOR_OFFSET = 34
const BSC_RELATION_CORNER_RADIUS = 10
const BSC_ARROWHEAD_LENGTH = 12
const BSC_ARROWHEAD_BASE_RATIO = 0.03
const BSC_ARROWHEAD_BASE_MIN = 24
const BSC_ARROWHEAD_BASE_MAX = 48

function resolveBscArrowheadBase(targetPerspectiveWidth: number | undefined) {
  const perspectiveWidth = targetPerspectiveWidth ?? 1000
  return Math.min(
    BSC_ARROWHEAD_BASE_MAX,
    Math.max(
      BSC_ARROWHEAD_BASE_MIN,
      perspectiveWidth * BSC_ARROWHEAD_BASE_RATIO,
    ),
  )
}

function buildBscOrthogonalRelationPath(
  sourceX: number,
  sourceY: number,
  targetX: number,
  targetY: number,
) {
  const deltaX = targetX - sourceX
  const deltaY = targetY - sourceY

  // OEs lado a lado: relação direta, sem contorno superior desnecessário.
  if (
    Math.abs(deltaX) >= BSC_RELATION_CORNER_RADIUS * 2 &&
    Math.abs(deltaY) <= 24
  ) {
    return Math.abs(deltaY) <= 2
      ? `M ${sourceX} ${sourceY} L ${targetX} ${targetY}`
      : `M ${sourceX} ${sourceY} L ${targetX} ${sourceY} L ${targetX} ${targetY}`
  }

  if (Math.abs(deltaX) < BSC_RELATION_CORNER_RADIUS * 2) {
    return `M ${sourceX} ${sourceY} L ${targetX} ${targetY}`
  }

  const corridorY = sourceY - BSC_RELATION_CORRIDOR_OFFSET
  const horizontalDirection = deltaX >= 0 ? 1 : -1
  const finalVerticalDirection = targetY >= corridorY ? 1 : -1
  const radius = Math.min(
    BSC_RELATION_CORNER_RADIUS,
    Math.max(4, Math.abs(deltaX) / 4),
  )

  const firstTurnX = sourceX + horizontalDirection * radius
  const secondTurnX = targetX - horizontalDirection * radius
  const finalTurnY = corridorY + finalVerticalDirection * radius

  return [
    `M ${sourceX} ${sourceY}`,
    `L ${sourceX} ${corridorY + radius}`,
    `Q ${sourceX} ${corridorY} ${firstTurnX} ${corridorY}`,
    `L ${secondTurnX} ${corridorY}`,
    `Q ${targetX} ${corridorY} ${targetX} ${finalTurnY}`,
    `L ${targetX} ${targetY}`,
  ].join(' ')
}

function RoutedStrategicEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  style,
  data,
}: EdgeProps<BscEdge>) {
  const path = buildBscOrthogonalRelationPath(
    sourceX,
    sourceY,
    targetX,
    targetY,
  )
  const tooltip = data?.tooltip
  const arrowBase = resolveBscArrowheadBase(data?.targetPerspectiveWidth)
  const markerId = `skpe-bsc-arrow-${id.replace(/[^a-zA-Z0-9_-]/g, '-')}`

  return (
    <g className="skpe-bsc-edge-with-tooltip">
      <defs>
        <marker
          id={markerId}
          markerUnits="userSpaceOnUse"
          markerWidth={BSC_ARROWHEAD_LENGTH}
          markerHeight={arrowBase}
          refX={BSC_ARROWHEAD_LENGTH}
          refY={arrowBase / 2}
          orient="auto"
          overflow="visible"
          viewBox={`0 0 ${BSC_ARROWHEAD_LENGTH} ${arrowBase}`}
        >
          <path
            d={`M 0 0 L ${BSC_ARROWHEAD_LENGTH} ${arrowBase / 2} L 0 ${arrowBase} z`}
            fill={
              typeof style?.stroke === 'string'
                ? style.stroke
                : 'currentColor'
            }
            stroke="none"
          />
        </marker>
      </defs>
      <BaseEdge
        id={id}
        path={path}
        markerEnd={`url(#${markerId})`}
        style={style}
      />
      <path
        d={path}
        className="skpe-bsc-edge-tooltip-hitbox"
        fill="none"
        stroke="transparent"
        strokeWidth={18}
        pointerEvents="stroke"
      >
        {tooltip ? <title>{tooltip}</title> : null}
      </path>
    </g>
  )
}
// SKPE_BSC_RELATION_STORY_TOOLTIP_V1
// SKPE_BSC_RELATION_STORY_TOOLTIP_V1
function PerspectiveContributionEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  data,
}: EdgeProps<BscEdge>) {
  const tooltip = data?.tooltip
  const centerX = (sourceX + targetX) / 2
  const gap = Math.max(1, Math.abs(targetY - sourceY))

  // Optional aggregate BSC contribution marker.
  // No tail: a much wider base converges directly to the next perspective.
  const baseHalfWidth = Math.min(190, Math.max(120, gap * 0.62))

  const path = [
    `M ${centerX - baseHalfWidth} ${sourceY}`,
    `L ${centerX + baseHalfWidth} ${sourceY}`,
    `L ${centerX} ${targetY}`,
    'Z',
  ].join(' ')

  return (
    <path
      id={id}
      d={path}
      className="skpe-bsc-perspective-contribution-arrow"
    >
      {tooltip ? <title>{tooltip}</title> : null}
    </path>
  )
}
const strategicEdgeTypes = {
  routedStrategic: RoutedStrategicEdge,
  perspectiveContribution: PerspectiveContributionEdge,
}

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
      <Handle type="source" id="perspective-top" position={Position.Top} isConnectable={false} />
      <Handle type="source" id="perspective-bottom" position={Position.Bottom} isConnectable={false} />
      <Handle type="target" id="perspective-top" position={Position.Top} isConnectable={false} />
      <Handle type="target" id="perspective-bottom" position={Position.Bottom} isConnectable={false} />
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
  // MAPA-OE-TOOLTIP-SEMANTIC-FIX-V1_3
  const objectiveDescription = data.objective.description?.trim() || null
  const objectiveExpectedResult = data.objective.expectedResult?.trim() || null
  const objectiveTooltipText =
    objectiveDescription ??
    (objectiveExpectedResult
      ? `Resultado esperado: ${objectiveExpectedResult}`
      : null)

  return (
    <article
      className={`skpe-bsc-objective${
        data.initiativeExecution
          ? ` has-execution-${executionTone}`
          : ''
      }`}
      /* MON-FORM-OE-DESCRIPTION-TOOLTIP-V1_1 */
      aria-label={[
        data.objective.code,
        data.objective.title,
        objectiveTooltipText,
      ]
        .filter(Boolean)
        .join(' — ')}
      data-personal-responsibility={data.personalResponsibilityReasons.length > 0 ? 'true' : 'false'}
      title={
        data.personalResponsibilityReasons.length > 0
          ? `Você possui responsabilidade vinculada a este Objetivo Estratégico: ${data.personalResponsibilityReasons.join(', ')}.`
          : undefined
      }>
      <NodeResizer
        isVisible={data.canResize}
        minWidth={280}
        minHeight={88}
      />
      <Handle
        type="source"
        id="center-source"
        position={Position.Top}
        isConnectable={false}
        className="skpe-bsc-center-handle"
      />
      <Handle
        type="target"
        id="center-target"
        position={Position.Top}
        isConnectable={false}
        className="skpe-bsc-center-handle"
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
      {objectiveTooltipText ? (
        <span
          className="skpe-bsc-objective-description-tooltip"
          role="tooltip"
        >
          {objectiveTooltipText}
        </span>
      ) : null}
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
  const [personalResponsibilityByObjective, setPersonalResponsibilityByObjective] = useState<
    Record<string, string[]>
  >({})
  const [mapInteractionActive, setMapInteractionActive] = useState(false)
  const [selectedRelationId, setSelectedRelationId] = useState<string | null>(null)
  const [causalManagerOpen, setCausalManagerOpen] = useState(false)
  const [causalSaving, setCausalSaving] = useState(false)
  const [causalMessage, setCausalMessage] = useState('')
  const [causalDraft, setCausalDraft] = useState<CausalRelationDraft>({
    relationId: null,
    sourceObjectiveId: '',
    targetObjectiveId: '',
    relationType: 'cause_effect',
    contributionStrength: 'medium',
    rationale: '',
    confidence: 'low',
    assistanceScope: 'strategic_map_context',
  })
  const [relationRoutes, setRelationRoutes] = useState<SavedRelationRoutes>({})
  const flowRef = useRef<ReactFlowInstance<BscNode, BscEdge> | null>(null)
  const canvasRef = useRef<HTMLDivElement | null>(null)
  const causalManagerRef = useRef<HTMLElement | null>(null)
  // MAPA-UX-RUNTIME-FIX-V1 - movable toolbar
  const toolbarRef = useRef<HTMLDivElement | null>(null)
  const [toolbarPosition, setToolbarPosition] = useState<{
    left: number
    top: number
  } | null>(null)

  // SKPE_FE04_CAUSAL_DISMISS_V2_2
  useEffect(() => {
    if (!causalManagerOpen) return

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return
      setCausalManagerOpen(false)
      setCausalMessage('')
    }

    const handlePointerDown = (event: PointerEvent) => {
      const target = event.target
      if (!(target instanceof Node)) return

      const panel = causalManagerRef.current
      if (panel?.contains(target)) return

      const element =
        target instanceof Element
          ? target
          : target.parentElement

      if (element?.closest('[data-skpe-causal-trigger="true"]')) return

      setCausalManagerOpen(false)
      setCausalMessage('')
    }

    window.addEventListener('keydown', handleKeyDown)
    document.addEventListener('pointerdown', handlePointerDown, true)

    return () => {
      window.removeEventListener('keydown', handleKeyDown)
      document.removeEventListener('pointerdown', handlePointerDown, true)
    }
  }, [causalManagerOpen])
  const handleToolbarDragStart = useCallback(
    (event: ReactPointerEvent<HTMLButtonElement>) => {
      if (event.button !== 0) return

      const canvas = canvasRef.current
      const toolbar = toolbarRef.current
      if (!canvas || !toolbar) return

      event.preventDefault()
      event.stopPropagation()

      const canvasRect = canvas.getBoundingClientRect()
      const toolbarRect = toolbar.getBoundingClientRect()

      const startPointerX = event.clientX
      const startPointerY = event.clientY
      const startLeft =
        toolbarPosition?.left ?? toolbarRect.left - canvasRect.left
      const startTop =
        toolbarPosition?.top ?? toolbarRect.top - canvasRect.top

      const clamp = (value: number, minimum: number, maximum: number) =>
        Math.max(minimum, Math.min(maximum, value))

      const handlePointerMove = (moveEvent: PointerEvent) => {
        const currentCanvas = canvasRef.current
        const currentToolbar = toolbarRef.current
        if (!currentCanvas || !currentToolbar) return

        const maxLeft = Math.max(
          0,
          currentCanvas.clientWidth - currentToolbar.offsetWidth,
        )
        const maxTop = Math.max(
          0,
          currentCanvas.clientHeight - currentToolbar.offsetHeight,
        )

        setToolbarPosition({
          left: clamp(
            startLeft + moveEvent.clientX - startPointerX,
            0,
            maxLeft,
          ),
          top: clamp(
            startTop + moveEvent.clientY - startPointerY,
            0,
            maxTop,
          ),
        })
      }

      const handlePointerUp = () => {
        window.removeEventListener('pointermove', handlePointerMove)
        window.removeEventListener('pointerup', handlePointerUp)
      }

      window.addEventListener('pointermove', handlePointerMove)
      window.addEventListener('pointerup', handlePointerUp)
    },
    [toolbarPosition],
  )

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

  useEffect(() => {
    let active = true

    if (!payload || payload.objectives.length === 0) {
      setPersonalResponsibilityByObjective({})
      return () => {
        active = false
      }
    }

    const currentPayload = payload

    async function loadPersonalResponsibilities() {
      const { data: authData } = await supabase.auth.getUser()
      if (!active) return
      const userId = authData.user?.id
      if (!userId) {
        setPersonalResponsibilityByObjective({})
        return
      }

      const organizationId = currentPayload.formulation.organizationId
      const objectiveIds = currentPayload.objectives.map((objective) => objective.id)
      const next = new Map<string, Set<string>>()
      const add = (objectiveId: string, reason: string) => {
        if (!next.has(objectiveId)) next.set(objectiveId, new Set<string>())
        next.get(objectiveId)?.add(reason)
      }

      for (const objective of currentPayload.objectives) {
        if (objective.ownerUserId === userId) add(objective.id, 'OE')
      }

      const indicatorResult = await supabase
        .from('sparks_measure_indicators')
        .select('subject_id')
        .eq('organization_id', organizationId)
        .eq('subject_type', 'strategic_objective')
        .eq('owner_user_id', userId)
        .in('subject_id', objectiveIds)

      if (!indicatorResult.error) {
        for (const row of indicatorResult.data ?? []) {
          if (typeof row.subject_id === 'string') add(row.subject_id, 'KPI')
        }
      }

      const peopleResult = await supabase
        .from('sparks_people')
        .select('id')
        .eq('profile_user_id', userId)
        .is('archived_at', null)

      const personIds = (peopleResult.data ?? [])
        .map((row) => row.id)
        .filter((id): id is string => typeof id === 'string')

      if (!peopleResult.error && personIds.length > 0) {
        const orgPeopleResult = await supabase
          .from('sparks_organization_people')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .in('person_id', personIds)

        const organizationPersonIds = (orgPeopleResult.data ?? [])
          .map((row) => row.id)
          .filter((id): id is string => typeof id === 'string')

        if (!orgPeopleResult.error && organizationPersonIds.length > 0) {
          const assignmentsResult = await supabase
            .from('sparks_responsibility_assignments')
            .select('object_id, valid_from, valid_until')
            .eq('organization_id', organizationId)
            .eq('object_type', 'initiative')
            .eq('responsibility_type', 'owner')
            .eq('status', 'active')
            .in('organization_person_id', organizationPersonIds)

          const today = new Date().toISOString().slice(0, 10)
          const initiativeIds = (assignmentsResult.data ?? [])
            .filter((row) =>
              (!row.valid_from || row.valid_from <= today) &&
              (!row.valid_until || row.valid_until >= today),
            )
            .map((row) => row.object_id)
            .filter((id): id is string => typeof id === 'string')

          if (!assignmentsResult.error && initiativeIds.length > 0) {
            const linksResult = await supabase
              .from('skpe_sparks_initiative_strategic_links')
              .select('strategic_objective_id')
              .eq('formulation_id', currentPayload.formulation.id)
              .in('sparks_initiative_id', Array.from(new Set(initiativeIds)))
              .not('strategic_objective_id', 'is', null)

            if (!linksResult.error) {
              for (const row of linksResult.data ?? []) {
                if (typeof row.strategic_objective_id === 'string') {
                  add(row.strategic_objective_id, 'iniciativa')
                }
              }
            }
          }
        }
      }

      if (!active) return
      setPersonalResponsibilityByObjective(
        Object.fromEntries(
          Array.from(next.entries()).map(([objectiveId, reasons]) => [
            objectiveId,
            Array.from(reasons),
          ]),
        ),
      )
    }

    void loadPersonalResponsibilities()

    return () => {
      active = false
    }
  }, [payload])

  useEffect(() => {
    const handlePointerDown = (event: PointerEvent) => {
      const canvas = canvasRef.current
      const target = event.target
      if (!canvas || !(target instanceof HTMLElement)) return
      if (!canvas.contains(target)) setMapInteractionActive(false)
    }

    document.addEventListener('pointerdown', handlePointerDown, true)
    return () => document.removeEventListener('pointerdown', handlePointerDown, true)
  }, [])
  const suggestedRelations = useMemo(
    () =>
      payload
        ? resolveStrategicCauseEffectSuggestions(
            payload.objectives,
            payload.perspectives,
          )
        : [],
    [payload],
  )

  const objectiveOptions = useMemo(
    () =>
      payload
        ? [...payload.objectives]
            .filter((objective) => objective.status !== 'archived')
            .sort(
              (left, right) =>
                left.displayOrder - right.displayOrder ||
                left.code.localeCompare(right.code, 'pt-BR'),
            )
        : [],
    [payload],
  )

  const resetCausalDraft = useCallback(() => {
    setCausalDraft({
      relationId: null,
      sourceObjectiveId: '',
      targetObjectiveId: '',
      relationType: 'cause_effect',
      contributionStrength: 'medium',
      rationale: '',
      confidence: 'low',
      assistanceScope: 'strategic_map_context',
    })
    setCausalMessage('')
  }, [])

  const loadCausalDraftFromRelation = useCallback(
    (relation: StrategicMapRelation) => {
      setCausalManagerOpen(true)
      setCausalMessage('')
      setCausalDraft({
        relationId: relation.id,
        sourceObjectiveId: relation.sourceObjectiveId,
        targetObjectiveId: relation.targetObjectiveId,
        relationType:
          (relation.relationType as CausalRelationDraft['relationType']) ||
          'cause_effect',
        contributionStrength:
          (relation.contributionStrength as CausalRelationDraft['contributionStrength']) ||
          'medium',
        rationale: relation.rationale ?? '',
        confidence: 'high',
        assistanceScope: 'strategic_map_context',
      })
    },
    [],
  )

  const suggestCausalRationale = useCallback(() => {
    if (!payload) return

    if (!causalDraft.sourceObjectiveId || !causalDraft.targetObjectiveId) {
      setCausalMessage('Selecione o OE de origem e o OE de destino.')
      return
    }

    if (causalDraft.sourceObjectiveId === causalDraft.targetObjectiveId) {
      setCausalMessage('Origem e destino devem ser Objetivos distintos.')
      return
    }

    const assisted = buildStrategicMapAssistedRationale(
      payload,
      causalDraft.sourceObjectiveId,
      causalDraft.targetObjectiveId,
      suggestedRelations,
    )

    setCausalDraft((current) => ({
      ...current,
      rationale: assisted.rationale,
      confidence: assisted.confidence,
      assistanceScope: assisted.assistanceScope,
    }))

    setCausalMessage(
      assisted.assistanceScope === 'curated_hypothesis'
        ? 'Hipótese assistida encontrada no repertório metodológico atual. Revise antes de registrar.'
        : 'Hipótese construída com o contexto atualmente disponível no Mapa. Evidências transversais ainda devem ser confrontadas antes da validação.',
    )
  }, [
    payload,
    causalDraft.sourceObjectiveId,
    causalDraft.targetObjectiveId,
    suggestedRelations,
  ])

  const causalIntegrity = useMemo(
    () =>
      payload
        ? assessCausalIntegrity(payload, causalDraft)
        : {
            status: 'blocked' as CausalIntegrityStatus,
            title: 'Impossível registrar',
            message: 'O Mapa Estratégico ainda não foi carregado.',
          },
    [payload, causalDraft],
  )
  const persistCausalRelation = useCallback(async () => {
    if (!payload || !formulationId) return

    if (!causalDraft.sourceObjectiveId || !causalDraft.targetObjectiveId) {
      setCausalMessage('Selecione origem e destino.')
      return
    }

    if (causalDraft.sourceObjectiveId === causalDraft.targetObjectiveId) {
      setCausalMessage('Um Objetivo não pode possuir relação causal consigo próprio.')
      return
    }

    if (causalIntegrity.status === 'blocked') {
      setCausalMessage(causalIntegrity.message)
      return
    }

    if (
      causalIntegrity.status === 'fragile' &&
      causalDraft.rationale.trim().length < 80
    ) {
      setCausalMessage(
        `${causalIntegrity.title}: ${causalIntegrity.message}`,
      )
      return
    }

    setCausalSaving(true)
    setCausalMessage('')

    const { error } = await supabase.rpc('upsert_skpe_objective_relation', {
      target_formulation_id: formulationId,
      source_objective_id: causalDraft.sourceObjectiveId,
      target_objective_id: causalDraft.targetObjectiveId,
      objective_relation_type: causalDraft.relationType,
      relation_strength: causalDraft.contributionStrength,
      relation_weight: null,
      relation_rationale: causalDraft.rationale.trim(),
      relation_display_order: 100,
      target_relation_id: causalDraft.relationId,
      relation_metadata: {
        assistance: {
          generated: true,
          scope: causalDraft.assistanceScope,
          confidence: causalDraft.confidence,
          humanValidationRequired: true,
        },
      },
      change_reason: causalDraft.relationId
        ? 'Ajuste governado de relação causal no Mapa Estratégico FE-04.'
        : 'Registro governado de hipótese causal no Mapa Estratégico FE-04.',
    })

    if (error) {
      setCausalSaving(false)
      setCausalMessage(`Não foi possível registrar a relação: ${error.message}`)
      return
    }

    try {
      setPayload(await loadStrategicMap(formulationId))
      setCausalMessage(
        'Relação registrada como hipótese em elaboração. A validação humana do pacote FE-04 continua obrigatória.',
      )
      setCausalDraft((current) => ({ ...current, relationId: null }))
    } catch (error) {
      setCausalMessage(
        error instanceof Error
          ? error.message
          : 'Relação registrada, mas o Mapa não pôde ser recarregado.',
      )
    } finally {
      setCausalSaving(false)
    }
  }, [payload, formulationId, causalDraft, causalIntegrity])

  const deleteCausalRelation = useCallback(
    async (relation: StrategicMapRelation) => {
      if (!formulationId) return
      if (!window.confirm('Excluir esta relação causal do Mapa Estratégico?')) return

      setCausalSaving(true)
      setCausalMessage('')

      const { error } = await supabase.rpc('delete_skpe_objective_relation', {
        target_relation_id: relation.id,
        change_reason:
          'Exclusão governada de relação causal no Mapa Estratégico FE-04.',
      })

      if (error) {
        setCausalSaving(false)
        setCausalMessage(`Não foi possível excluir a relação: ${error.message}`)
        return
      }

      try {
        setPayload(await loadStrategicMap(formulationId))
        resetCausalDraft()
        setCausalMessage(
          'Relação excluída. A governança do Mapa permanece preservada.',
        )
      } catch (error) {
        setCausalMessage(
          error instanceof Error
            ? error.message
            : 'Relação excluída, mas o Mapa não pôde ser recarregado.',
        )
      } finally {
        setCausalSaving(false)
      }
    },
    [formulationId, resetCausalDraft],
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
          personalResponsibilityReasons: personalResponsibilityByObjective[model.id] ?? [],
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
    const objectiveById = new Map(
      payload.objectives.map((objective) => [objective.id, objective]),
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

      const sourceCenterX = source.x + BSC_OBJECTIVE_WIDTH / 2
      const sourceCenterY = source.y + BSC_OBJECTIVE_HEIGHT / 2
      const targetCenterX = target.x + BSC_OBJECTIVE_WIDTH / 2
      const targetCenterY = target.y + BSC_OBJECTIVE_HEIGHT / 2

      const verticalCenterDistance = Math.abs(targetCenterY - sourceCenterY)
      const sameVisualRow =
        verticalCenterDistance <= Math.max(24, BSC_OBJECTIVE_HEIGHT * 0.45)

      // OEs lado a lado devem se conectar diretamente pelas faces laterais mais próximas.
      if (sameVisualRow) {
        return targetCenterX >= sourceCenterX
          ? { sourceHandle: 'right', targetHandle: 'left' }
          : { sourceHandle: 'left', targetHandle: 'right' }
      }

      // Para OEs em linhas diferentes, preserva-se o trajeto ortogonal superior.
      return {
        sourceHandle: 'top',
        targetHandle: 'bottom',
      }
    }

    const canonicalEdges: BscEdge[] = layout.edges.map(
      (edge): BscEdge => {
        const handles = edgeHandles(edge.id, edge.source, edge.target)
        return {
          id: edge.id,
          source: edge.source,
          target: edge.target,
          type: 'routedStrategic',
          sourceHandle: handles.sourceHandle,
          targetHandle: handles.targetHandle,
          selectable: adjustMode && canAdjustLayout,
          focusable: adjustMode && canAdjustLayout,
          selected: selectedRelationId === edge.id,
          className:
            selectedRelationId === edge.id
              ? 'skpe-bsc-edge-canonical is-selected'
              : 'skpe-bsc-edge-canonical',
          data: {
            relation: edge.relation,
            targetPerspectiveWidth:
              layout.lanes.find(
                (lane) =>
                  lane.perspective.id ===
                  objectiveLayoutById.get(edge.target)?.perspective.id,
              )?.width ?? layout.width,
            tooltip: [
              'Hipótese de causa e efeito — pendente de validação pela organização.',
              `${objectiveById.get(edge.source)?.code ?? 'OE'} → ${objectiveById.get(edge.target)?.code ?? 'OE'}`,
              edge.relation.rationale?.trim() ||
                'Racional causal ainda não registrado. A relação deve ser explicada e validada antes de ser considerada aprovada.',
            ].join('\n'),
          },
          zIndex: 3,
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
              type: 'routedStrategic',
              sourceHandle: handles.sourceHandle,
              targetHandle: handles.targetHandle,
              className:
                selectedRelationId === edgeId
                  ? 'skpe-bsc-edge-suggested is-selected'
                  : 'skpe-bsc-edge-suggested',
              selectable: adjustMode && canAdjustLayout,
              focusable: adjustMode && canAdjustLayout,
              selected: selectedRelationId === edgeId,
              data: {
                suggestion,
                targetPerspectiveWidth:
                  layout.lanes.find(
                    (lane) =>
                      lane.perspective.id ===
                      objectiveLayoutById.get(suggestion.targetId)?.perspective.id,
                  )?.width ?? layout.width,
                tooltip: [
                  'Hipótese de causa e efeito — pendente de validação pela organização.',
                  `${suggestion.sourceCode} → ${suggestion.targetCode}`,
                  suggestion.rationale,
                ].join('\n'),
              },
              zIndex: 3,
            }
          },
        )
      : []

    const orderedLanes = [...layout.lanes].sort(
      (left, right) =>
        left.perspective.displayOrder - right.perspective.displayOrder ||
        left.perspective.code.localeCompare(right.perspective.code, 'pt-BR'),
    )

    const perspectiveHypothesisEdges: BscEdge[] = showSuggestedRelations
      ? orderedLanes.slice(0, -1).map((sourceLane, index) => {
          const targetLane = orderedLanes[index + 1]
          const targetIsAbove = targetLane.y < sourceLane.y

          return {
            id: `hypothesis:perspective:${sourceLane.perspective.id}:${targetLane.perspective.id}`,
            source: sourceLane.id,
            target: targetLane.id,
            type: 'perspectiveContribution',
            sourceHandle: targetIsAbove ? 'perspective-top' : 'perspective-bottom',
            targetHandle: targetIsAbove ? 'perspective-bottom' : 'perspective-top',
            className: 'skpe-bsc-edge-perspective-hypothesis',
            selectable: false,
            focusable: false,
            data: {
              tooltip: [
                'Hipótese agregada de contribuição entre perspectivas — pendente de validação.',
                `${sourceLane.perspective.code} — ${sourceLane.perspective.name}`,
                `alavanca`,
                `${targetLane.perspective.code} — ${targetLane.perspective.name}`,
                'Leitura BSC: o conjunto de capacidades e resultados da perspectiva de origem cria condições para o desempenho da perspectiva seguinte. Esta seta não significa relação individual obrigatória entre todos os OEs.',
              ].join('\n'),
            },
            zIndex: 2,
          }
        })
      : []

    return {
      nodes: [...laneNodes, ...themeNodes, ...objectiveNodes] as BscNode[],
      edges: [
        ...canonicalEdges,
        ...perspectiveHypothesisEdges,
        ...hypothesisEdges,
      ],
    }
  }, [
    adjustMode,
    canAdjustLayout,
    formulationId,
    objectiveInitiativeExecution,
    personalResponsibilityByObjective,
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


        <small className="skpe-bsc-hypothesis-notice">
          Relações de causa e efeito exibidas neste Mapa são hipóteses a serem apresentadas e validadas pela organização.
        </small></header>{adjustMode && canAdjustLayout ? (
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
      {causalManagerOpen && payload ? (
        <section
          ref={causalManagerRef}
          className="skpe-bsc-causal-manager skpe-bsc-causal-sidepanel"
          aria-label="Gestão governada das relações causais"
        >
          <header>
            <div>
              <small>FE-04 · Formulação Estratégica</small>
              <strong>Relações de causa e efeito</strong>
            </div>
            <button type="button" onClick={() => setCausalManagerOpen(false)}>
              Fechar
            </button>
          </header>

          <p className="skpe-bsc-causal-manager-intro">
            Sugestões são hipóteses metodológicas. O registro abaixo não equivale
            à validação da Organização; a relação somente integra o Mapa
            governado após a validação humana do pacote FE-04.
          </p>

          <div className="skpe-bsc-causal-grid">
            <label>
              <span>OE de origem</span>
              <select
                value={causalDraft.sourceObjectiveId}
                onChange={(event) =>
                  setCausalDraft((current) => ({
                    ...current,
                    sourceObjectiveId: event.target.value,
                    rationale: '',
                    confidence: 'low',
                    assistanceScope: 'strategic_map_context',
                  }))
                }
              >
                <option value="">Selecione</option>
                {objectiveOptions.map((objective) => (
                  <option key={objective.id} value={objective.id}>
                    {objective.code} — {objective.title}
                  </option>
                ))}
              </select>
            </label>

            <label>
              <span>OE de destino</span>
              <select
                value={causalDraft.targetObjectiveId}
                onChange={(event) =>
                  setCausalDraft((current) => ({
                    ...current,
                    targetObjectiveId: event.target.value,
                    rationale: '',
                    confidence: 'low',
                    assistanceScope: 'strategic_map_context',
                  }))
                }
              >
                <option value="">Selecione</option>
                {objectiveOptions.map((objective) => (
                  <option key={objective.id} value={objective.id}>
                    {objective.code} — {objective.title}
                  </option>
                ))}
              </select>
            </label>

            <label>
              <span>Tipo de relação</span>
              <select
                value={causalDraft.relationType}
                onChange={(event) =>
                  setCausalDraft((current) => ({
                    ...current,
                    relationType:
                      event.target.value as CausalRelationDraft['relationType'],
                  }))
                }
              >
                {(
                  [
                    'cause_effect',
                    'supports',
                    'enables',
                    'contributes_to',
                    'depends_on',
                    'influences',
                  ] as const
                ).map((value) => (
                  <option key={value} value={value}>
                    {causalRelationTypeLabel(value)}
                  </option>
                ))}
              </select>
            </label>

            <label>
              <span>Força da contribuição</span>
              <select
                value={causalDraft.contributionStrength}
                onChange={(event) =>
                  setCausalDraft((current) => ({
                    ...current,
                    contributionStrength:
                      event.target.value as CausalRelationDraft['contributionStrength'],
                  }))
                }
              >
                {(['low', 'medium', 'high'] as const).map((value) => (
                  <option key={value} value={value}>
                    {causalStrengthLabel(value)}
                  </option>
                ))}
              </select>
            </label>
          </div>

          <div className="skpe-bsc-causal-assist-line">
            <button
              type="button"
              onClick={suggestCausalRationale}
              disabled={causalSaving}
            >
              Sugerir justificativa assistida
            </button>
            <span>
              Grau de confiança:{' '}
              <strong>{causalConfidenceLabel(causalDraft.confidence)}</strong>
              {' '}· Abrangência da análise:{' '}
              <strong>
                {causalDraft.assistanceScope === 'curated_hypothesis'
                  ? 'hipótese apoiada pelo repertório metodológico'
                  : 'informações atualmente disponíveis no Mapa Estratégico'}
              </strong>
            </span>
          </div>

          <div
            className={`skpe-bsc-causal-integrity is-${causalIntegrity.status}`}
            role="status"
          >
            <strong>{causalIntegrity.title}</strong>
            <span>{causalIntegrity.message}</span>
          </div>

          <label className="skpe-bsc-causal-rationale">
            <span>Racional causal</span>
            <textarea
              value={causalDraft.rationale}
              rows={9}
              onChange={(event) =>
                setCausalDraft((current) => ({
                  ...current,
                  rationale: event.target.value,
                }))
              }
              placeholder="Explique por que o avanço do OE de origem cria condições, capacidades ou resultados que contribuem para o OE de destino."
            />
          </label>

          <div className="skpe-bsc-causal-actions">
            <button
              type="button"
              className="skpe-bsc-causal-primary-action"
              onClick={persistCausalRelation}
              disabled={causalSaving || causalIntegrity.status === 'blocked'}
              title={
                causalIntegrity.status === 'blocked'
                  ? causalIntegrity.message
                  : causalDraft.relationId
                    ? 'Salvar os ajustes desta relação causal'
                    : 'Criar a relação causal no Mapa como hipótese em elaboração'
              }
            >
              {causalSaving
                ? 'Criando relação...'
                : causalDraft.relationId
                  ? 'Salvar relação causal'
                  : 'Criar relação causal no Mapa'}
            </button>
            <button type="button" onClick={resetCausalDraft} disabled={causalSaving}>
              Limpar
            </button>
          </div>

          {causalIntegrity.status === 'fragile' ? (
            <small className="skpe-bsc-causal-action-help">
              A relação pode ser registrada apenas como hipótese em elaboração.
              A fragilidade indicada acima deverá ser tratada antes da validação humana.
            </small>
          ) : causalIntegrity.status === 'blocked' ? (
            <small className="skpe-bsc-causal-action-help">
              A criação está indisponível porque a condição acima compromete
              integridade, unicidade ou referência estrutural da relação.
            </small>
          ) : null}

          {causalMessage ? (
            <p className="skpe-bsc-causal-message" role="status">
              {causalMessage}
            </p>
          ) : null}

          <div className="skpe-bsc-causal-existing">
            <strong>Relações registradas</strong>
            {payload.relations.length === 0 ? (
              <p>Nenhuma relação causal foi registrada nesta Formulação.</p>
            ) : (
              <ul>
                {payload.relations.map((relation) => {
                  const source = payload.objectives.find(
                    (objective) => objective.id === relation.sourceObjectiveId,
                  )
                  const target = payload.objectives.find(
                    (objective) => objective.id === relation.targetObjectiveId,
                  )
                  return (
                    <li key={relation.id}>
                      <div>
                        <strong>
                          {source?.code ?? 'OE'} → {target?.code ?? 'OE'}
                        </strong>
                        <span>
                          {causalRelationTypeLabel(
                            relation.relationType as CausalRelationDraft['relationType'],
                          )}{' '}
                          · força{' '}
                          {causalStrengthLabel(
                            (relation.contributionStrength ??
                              'medium') as CausalRelationDraft['contributionStrength'],
                          )}
                        </span>
                        {relation.rationale ? <p>{relation.rationale}</p> : null}
                      </div>
                      <div className="skpe-bsc-causal-existing-actions">
                        <button
                          type="button"
                          onClick={() => loadCausalDraftFromRelation(relation)}
                        >
                          Editar
                        </button>
                        <button
                          type="button"
                          onClick={() => void deleteCausalRelation(relation)}
                          disabled={causalSaving}
                        >
                          Excluir
                        </button>
                      </div>
                    </li>
                  )
                })}
              </ul>
            )}
          </div>
        </section>
      ) : null}

      <div
        ref={canvasRef}
        className={`skpe-bsc-map-canvas${mapInteractionActive ? ' is-interaction-active' : ''}${causalManagerOpen ? ' is-causal-manager-open' : ''}`}
        aria-label="Mapa Estratégico"
        data-map-interaction={mapInteractionActive ? 'active' : 'passive'}
        onPointerDownCapture={(event) => {
          const target = event.target as HTMLElement
          if (target.closest('.react-flow')) setMapInteractionActive(true)
        }}
      >
        <div
          ref={toolbarRef}
          className="skpe-bsc-toolbar"
          style={
            toolbarPosition
              ? {
                  left: toolbarPosition.left,
                  top: toolbarPosition.top,
                  right: 'auto',
                  bottom: 'auto',
                  transform: 'none',
                }
              : undefined
          }
        >
          <button
            type="button"
            className="skpe-bsc-toolbar-drag-handle nodrag nopan nowheel"
            aria-label="Mover barra de ferramentas"
            title="Arraste para mover"
            onPointerDown={handleToolbarDragStart}
            onMouseDown={(event) => event.stopPropagation()}
          >
            <span aria-hidden="true">⠿</span>
          </button>
                {canAdjustLayout ? (
                  <button
                    type="button"
                    className={adjustMode ? 'is-active' : undefined}
                    aria-label={adjustMode ? 'Concluir ajustes do Mapa Estratégico' : 'Ajustar Mapa Estratégico'}
                    title={adjustMode ? 'Concluir ajustes' : 'Ajustar mapa'}
                    data-tooltip={adjustMode ? 'Concluir ajustes' : 'Ajustar mapa'}
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

                <button type="button" className="skpe-bsc-toolbar-action" onClick={readableView} aria-label="Exibir mapa em visão legível" title="Visão legível" data-tooltip="Visão legível">Visão legível</button>
                <button type="button" className="skpe-bsc-toolbar-action" onClick={fitWholeMap} aria-label="Ajustar Mapa Estratégico à tela" title="Ajustar à tela" data-tooltip="Ajustar à tela">Ajustar à tela</button>
                <button type="button" className="skpe-bsc-toolbar-action" onClick={restoreDefaultLayout} aria-label="Restaurar layout padrão do Mapa Estratégico" title="Restaurar padrão" data-tooltip="Restaurar padrão">Restaurar padrão</button>

                <button
                  type="button"
                  className={causalManagerOpen ? 'is-active' : undefined}
                  onClick={() => {
                    setCausalManagerOpen((current) => !current)
                    setCausalMessage('')
                  }}
                >
                  Relações causais
                </button>

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
          edgeTypes={strategicEdgeTypes}
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
          panOnDrag={mapInteractionActive}
          panOnScroll={mapInteractionActive}
          zoomOnScroll={mapInteractionActive}
          zoomOnPinch={mapInteractionActive}
          zoomOnDoubleClick={mapInteractionActive}
          preventScrolling={mapInteractionActive}
          nodesFocusable={mapInteractionActive}          deleteKeyCode={null}
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
