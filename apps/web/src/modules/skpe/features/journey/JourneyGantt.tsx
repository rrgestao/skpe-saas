import { useEffect, useMemo, useState, type CSSProperties } from 'react'

import { supabase } from '../../../../lib/supabase'
import { JourneyEventManageDialog } from './JourneyEventManageDialog'
import type { JourneyTemporalRow } from '../../contracts/journey'

import './JourneyGantt.css'

const DAY_MS = 86_400_000

type JourneyGanttProps = {
  rows: JourneyTemporalRow[]
  referenceDate: string | null
  formatDate: (value: string | null) => string
  selectedItemId: string | null
  onSelectItem: (itemId: string) => void
  canManageJourney: boolean
  onCreateEvent: (itemId: string) => void
  eventProjectionRevision: number
}

type JourneyEventRow = {
  event_id: string
  journey_item_id: string
  journey_item_code: string
  journey_item_title: string
  journey_item_type: string
  parent_item_id: string | null
  event_type: string
  event_title: string
  event_description: string | null
  starts_at: string | null
  ends_at: string | null
  all_day: boolean
  timezone_name: string
  event_status: string
  priority: string
  location_text: string | null
  meeting_reference: string | null
  participant_count: number
  accepted_count: number
  attended_count: number
  current_user_role: string | null
}

type InitiativeTemporalRow = {
  entity_type: 'initiative' | 'action'
  entity_id: string
  organization_id: string
  initiative_id: string
  parent_action_id: string | null
  code: string
  name: string
  lifecycle_status: string
  priority: string
  organization_timezone: string
  reference_date: string
  baseline_start_date: string | null
  baseline_end_date: string | null
  current_plan_start_date: string | null
  current_plan_end_date: string | null
  forecast_start_date: string | null
  forecast_end_date: string | null
  actual_start_date: string | null
  actual_end_date: string | null
  current_plan_start_variance_vs_baseline_days: number | null
  current_plan_end_variance_vs_baseline_days: number | null
  forecast_start_variance_vs_current_plan_days: number | null
  forecast_end_variance_vs_current_plan_days: number | null
  actual_start_variance_vs_current_plan_days: number | null
  actual_end_variance_vs_current_plan_days: number | null
  is_start_overdue: boolean
  days_start_overdue: number
  is_completion_overdue: boolean
  days_completion_overdue: number
  temporal_state: string | null
  temporal_data_quality_state: string
}

type ActionBoardRow = {
  action_id: string
  parent_action_id: string | null
  depth: number
  code: string
  name: string
  action_type: string
  status: string
  priority: string
  official_progress: number
  calculated_progress: number
  is_root: boolean
  has_eligible_children: boolean
  planned_start_date: string | null
  planned_due_date: string | null
}

type EconomicProjection = {
  initiative?: {
    direct?: {
      plannedCost: number | null
      actualCost: number | null
      currencyCode: string | null
      costVariance: number | null
      estimatedEffort: number | null
      actualEffort: number | null
      effortUnit: string | null
      effortVariance: number | null
      resourceEstimate: string | null
    }
  }
  actions?: {
    counts?: {
      total: number
      currentPlan: number
      cancelled: number
      archived: number
    }
    costByCurrency?: Array<{
      currencyCode: string
      currentPlannedCost: number
      actualRealizedCost: number
      currentPlanVariance: number
      cancelledPlannedCost: number
      archivedPlannedCost: number
    }>
    effortByUnit?: Array<{
      effortUnit: string
      currentEstimatedEffort: number
      actualRealizedEffort: number
      currentPlanVariance: number
      cancelledEstimatedEffort: number
      archivedEstimatedEffort: number
    }>
    dataQuality?: {
      actionsWithCostWithoutCurrency: number
      actionsWithEffortWithoutUnit: number
    }
  }
}

type CapacityAllocation = {
  allocationId: string
  capacityPeriodId: string
  organizationPersonId: string
  personId: string
  personName: string
  organizationalArea: string | null
  capacityUnit: string
  capacityAmount: number
  capacityStatus: string
  moduleCode: string
  objectType: string
  objectId: string
  allocationStart: string
  allocationEnd: string
  allocatedAmount: number
  allocationStatus: string
}

type PersonCapacity = {
  capacity_period_id: string
  organization_person_id: string
  person_id: string
  person_name: string
  organizational_area: string | null
  period_start: string
  period_end: string
  capacity_unit: string
  capacity_status: string
  capacity_amount: number
  allocated_current_amount: number
  allocated_ended_amount: number
  available_amount: number
  utilization_percentage: number | null
  overallocation_amount: number
  is_overallocated: boolean
  current_allocation_count: number
}

type CapacityProjection = {
  allocations?: CapacityAllocation[]
  involvedPeopleCapacity?: PersonCapacity[]
  visible?: boolean
}

type OperationalProjection = {
  journeyEvents?: JourneyEventRow[]
  initiativeTemporal?: InitiativeTemporalRow[]
  actionBoard?: ActionBoardRow[]
  economic?: EconomicProjection
  capacity?: CapacityProjection
}

type GanttVisibility = 'all' | 'mandatory'
type GanttBarKind = 'baseline' | 'plan' | 'forecast' | 'actual'

type GanttDisplayRow = {
  row: JourneyTemporalRow
  depth: number
  hasChildren: boolean
}

type InitiativeDisplayRow = {
  row: InitiativeTemporalRow
  depth: number
  hasChildren: boolean
}

type DateRange = {
  start: string
  end: string
}

type Timeline = {
  startMs: number
  endMs: number
  totalDays: number
  ticks: Array<{
    key: string
    label: string
    position: number
  }>
  referencePosition: number | null
}

function parseDateOnly(value: string) {
  const [year, month, day] = value.split('-').map(Number)
  return Date.UTC(year, month - 1, day)
}

function toDateOnly(ms: number) {
  return new Date(ms).toISOString().slice(0, 10)
}

function toZonedDateOnly(value: string, timezoneName: string) {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: timezoneName || 'UTC',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date(value))

  const year = parts.find((part) => part.type === 'year')?.value
  const month = parts.find((part) => part.type === 'month')?.value
  const day = parts.find((part) => part.type === 'day')?.value

  return year && month && day ? `${year}-${month}-${day}` : value.slice(0, 10)
}

function daysBetween(startMs: number, endMs: number) {
  return Math.round((endMs - startMs) / DAY_MS)
}

function normalizeRange(
  start: string | null,
  end: string | null,
): DateRange | null {
  if (!start && !end) return null

  const resolvedStart = start ?? end
  const resolvedEnd = end ?? start

  if (!resolvedStart || !resolvedEnd) return null

  return parseDateOnly(resolvedStart) <= parseDateOnly(resolvedEnd)
    ? { start: resolvedStart, end: resolvedEnd }
    : { start: resolvedEnd, end: resolvedStart }
}

function getJourneyRange(row: JourneyTemporalRow, kind: GanttBarKind) {
  if (kind === 'baseline') {
    return normalizeRange(row.baseline_start_date, row.baseline_end_date)
  }

  if (kind === 'plan') {
    return normalizeRange(row.current_plan_start_date, row.current_plan_end_date)
  }

  if (kind === 'forecast') {
    return normalizeRange(row.forecast_start_date, row.forecast_end_date)
  }

  return normalizeRange(row.actual_start_date, row.actual_end_date)
}

function getInitiativeRange(row: InitiativeTemporalRow, kind: GanttBarKind) {
  if (kind === 'baseline') {
    return normalizeRange(row.baseline_start_date, row.baseline_end_date)
  }

  if (kind === 'plan') {
    return normalizeRange(row.current_plan_start_date, row.current_plan_end_date)
  }

  if (kind === 'forecast') {
    return normalizeRange(row.forecast_start_date, row.forecast_end_date)
  }

  return normalizeRange(row.actual_start_date, row.actual_end_date)
}

function getEventRange(event: JourneyEventRow): DateRange | null {
  if (!event.starts_at && !event.ends_at) return null

  const start = event.starts_at
    ? toZonedDateOnly(event.starts_at, event.timezone_name)
    : event.ends_at
      ? toZonedDateOnly(event.ends_at, event.timezone_name)
      : null
  const end = event.ends_at
    ? toZonedDateOnly(event.ends_at, event.timezone_name)
    : start

  return normalizeRange(start, end)
}

function flattenJourney(
  rows: JourneyTemporalRow[],
  expandedIds: Set<string>,
): GanttDisplayRow[] {
  const childrenByParent = new Map<string | null, JourneyTemporalRow[]>()
  const rowIds = new Set(rows.map((row) => row.item_id))

  for (const row of rows) {
    const parentId = row.parent_item_id && rowIds.has(row.parent_item_id)
      ? row.parent_item_id
      : null
    const siblings = childrenByParent.get(parentId) ?? []
    siblings.push(row)
    childrenByParent.set(parentId, siblings)
  }

  for (const siblings of childrenByParent.values()) {
    siblings.sort(
      (first, second) =>
        first.display_order - second.display_order ||
        first.item_code.localeCompare(second.item_code, 'pt-BR'),
    )
  }

  const result: GanttDisplayRow[] = []
  const visit = (parentId: string | null, depth: number) => {
    for (const row of childrenByParent.get(parentId) ?? []) {
      const hasChildren = (childrenByParent.get(row.item_id)?.length ?? 0) > 0
      result.push({ row, depth, hasChildren })

      if (hasChildren && expandedIds.has(row.item_id)) {
        visit(row.item_id, depth + 1)
      }
    }
  }

  visit(null, 0)
  return result
}

function flattenInitiative(
  rows: InitiativeTemporalRow[],
  expandedIds: Set<string>,
): InitiativeDisplayRow[] {
  const initiative = rows.find((row) => row.entity_type === 'initiative')
  const actions = rows
    .filter((row) => row.entity_type === 'action')
    .sort((first, second) => first.code.localeCompare(second.code, 'pt-BR'))
  const byParent = new Map<string | null, InitiativeTemporalRow[]>()
  const actionIds = new Set(actions.map((row) => row.entity_id))

  for (const action of actions) {
    const parentId = action.parent_action_id && actionIds.has(action.parent_action_id)
      ? action.parent_action_id
      : null
    const siblings = byParent.get(parentId) ?? []
    siblings.push(action)
    byParent.set(parentId, siblings)
  }

  const result: InitiativeDisplayRow[] = []

  if (initiative) {
    result.push({ row: initiative, depth: 0, hasChildren: actions.length > 0 })
  }

  const visit = (parentId: string | null, depth: number) => {
    for (const action of byParent.get(parentId) ?? []) {
      const hasChildren = (byParent.get(action.entity_id)?.length ?? 0) > 0
      result.push({ row: action, depth, hasChildren })

      if (hasChildren && expandedIds.has(action.entity_id)) {
        visit(action.entity_id, depth + 1)
      }
    }
  }

  if (!initiative || expandedIds.has(initiative.entity_id)) {
    visit(null, initiative ? 1 : 0)
  }

  return result
}

function buildTimeline(
  rows: JourneyTemporalRow[],
  initiatives: InitiativeTemporalRow[],
  events: JourneyEventRow[],
  referenceDate: string | null,
): Timeline | null {
  const dates: number[] = []

  for (const row of rows) {
    for (const kind of ['baseline', 'plan', 'forecast', 'actual'] as const) {
      const range = getJourneyRange(row, kind)
      if (!range) continue
      dates.push(parseDateOnly(range.start), parseDateOnly(range.end))
    }
  }

  for (const row of initiatives) {
    for (const kind of ['baseline', 'plan', 'forecast', 'actual'] as const) {
      const range = getInitiativeRange(row, kind)
      if (!range) continue
      dates.push(parseDateOnly(range.start), parseDateOnly(range.end))
    }
  }

  for (const event of events) {
    const range = getEventRange(event)
    if (!range) continue
    dates.push(parseDateOnly(range.start), parseDateOnly(range.end))
  }

  if (referenceDate) dates.push(parseDateOnly(referenceDate))
  if (dates.length === 0) return null

  const rawStart = Math.min(...dates)
  const rawEnd = Math.max(...dates)
  const paddingDays = Math.max(3, Math.min(14, Math.ceil(daysBetween(rawStart, rawEnd) * 0.03)))
  const startMs = rawStart - paddingDays * DAY_MS
  const endMs = rawEnd + paddingDays * DAY_MS
  const totalDays = Math.max(1, daysBetween(startMs, endMs) + 1)

  const first = new Date(startMs)
  let tickMs = Date.UTC(first.getUTCFullYear(), first.getUTCMonth() + 1, 1)
  const monthTicks: number[] = []

  while (tickMs <= endMs) {
    monthTicks.push(tickMs)
    const cursor = new Date(tickMs)
    tickMs = Date.UTC(cursor.getUTCFullYear(), cursor.getUTCMonth() + 1, 1)
  }

  const stride = Math.max(1, Math.ceil(monthTicks.length / 12))
  const formatter = new Intl.DateTimeFormat('pt-BR', {
    month: 'short',
    year: '2-digit',
    timeZone: 'UTC',
  })

  const ticks = monthTicks
    .filter((_, index) => index % stride === 0)
    .map((value) => ({
      key: toDateOnly(value),
      label: formatter.format(new Date(value)).replace('.', ''),
      position: (daysBetween(startMs, value) / totalDays) * 100,
    }))

  const referenceMs = referenceDate ? parseDateOnly(referenceDate) : null
  const referencePosition =
    referenceMs !== null && referenceMs >= startMs && referenceMs <= endMs
      ? (daysBetween(startMs, referenceMs) / totalDays) * 100
      : null

  return {
    startMs,
    endMs,
    totalDays,
    ticks,
    referencePosition,
  }
}

function getBarStyle(range: DateRange, timeline: Timeline): CSSProperties {
  const start = Math.max(timeline.startMs, parseDateOnly(range.start))
  const end = Math.min(timeline.endMs, parseDateOnly(range.end))
  const left = (daysBetween(timeline.startMs, start) / timeline.totalDays) * 100
  const duration = Math.max(1, daysBetween(start, end) + 1)
  const width = Math.max(0.65, (duration / timeline.totalDays) * 100)

  return {
    left: `${Math.max(0, left)}%`,
    width: `${Math.min(100 - Math.max(0, left), width)}%`,
  }
}

function getItemTypeLabel(itemType: JourneyTemporalRow['item_type']) {
  const labels: Record<JourneyTemporalRow['item_type'], string> = {
    macrophase: 'Macrofase',
    phase: 'Fase',
    stage: 'Etapa',
    meta_stage: 'Metaetapa',
    activity: 'Atividade',
    deliverable: 'Entregável',
    gate: 'Gate',
  }

  return labels[itemType]
}

function getBarTitle(
  kind: GanttBarKind,
  range: DateRange,
  formatDate: (value: string | null) => string,
) {
  const labels: Record<GanttBarKind, string> = {
    baseline: 'Baseline original',
    plan: 'Plano institucional vigente',
    forecast: 'Forecast operacional',
    actual: 'Realizado',
  }

  return `${labels[kind]}: ${formatDate(range.start)} a ${formatDate(range.end)}`
}

function getEventTitle(
  event: JourneyEventRow,
  range: DateRange,
  formatDate: (value: string | null) => string,
) {
  const participantSummary = `${event.accepted_count}/${event.participant_count} participantes confirmados`
  const attendanceSummary = event.attended_count > 0
    ? ` · ${event.attended_count} presença(s) registrada(s)`
    : ''

  return `${event.event_title} · ${event.event_status} · ${formatDate(range.start)} a ${formatDate(range.end)} · ${participantSummary}${attendanceSummary}`
}

function getTemporalAlert(row: InitiativeTemporalRow) {
  if (row.is_completion_overdue) {
    return `Conclusão em atraso: ${row.days_completion_overdue} dia(s)`
  }
  if (row.is_start_overdue) {
    return `Início em atraso: ${row.days_start_overdue} dia(s)`
  }
  if (row.temporal_data_quality_state !== 'ok') {
    return `Qualidade temporal: ${row.temporal_data_quality_state}`
  }
  return null
}

type TemporalVarianceSource = {
  current_plan_end_variance_vs_baseline_days: number | null
  forecast_end_variance_vs_current_plan_days: number | null
  actual_end_variance_vs_current_plan_days: number | null
}

function getTemporalVarianceLabels(row: TemporalVarianceSource) {
  const labels: string[] = []
  const append = (label: string, value: number | null) => {
    if (value === null || value === 0) return
    labels.push(`${label}: ${value > 0 ? '+' : ''}${value}d`)
  }

  append('Plano × baseline', row.current_plan_end_variance_vs_baseline_days)
  append('Forecast × plano', row.forecast_end_variance_vs_current_plan_days)
  append('Realizado × plano', row.actual_end_variance_vs_current_plan_days)

  return labels
}

function formatQuantity(value: number | null | undefined) {
  if (value === null || value === undefined) return '—'
  return new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 2 }).format(value)
}

function formatMoney(value: number, currencyCode: string) {
  try {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: currencyCode,
      maximumFractionDigits: 2,
    }).format(value)
  } catch {
    return `${currencyCode} ${formatQuantity(value)}`
  }
}

function getStatusCounts(rows: ActionBoardRow[]) {
  const counts = new Map<string, number>()

  for (const row of rows) {
    counts.set(row.status, (counts.get(row.status) ?? 0) + 1)
  }

  return Array.from(counts.entries()).sort(([first], [second]) =>
    first.localeCompare(second, 'pt-BR'),
  )
}

function openGovernedKanban() {
  const target = new URL(window.location.href)

  if (target.pathname.endsWith('/journey')) {
    target.pathname = `${target.pathname.slice(0, -'/journey'.length)}/initiatives`
    target.searchParams.delete('section')
  } else {
    target.searchParams.set('section', 'initiatives')
  }

  window.location.assign(target.toString())
}

function isMilestone(row: JourneyTemporalRow, range: DateRange) {
  return (
    (row.item_type === 'gate' || row.item_type === 'deliverable') &&
    range.start === range.end
  )
}

function renderTimelineBackground(timeline: Timeline) {
  return (
    <>
      {timeline.ticks.map((tick) => (
        <i
          key={tick.key}
          className="skpe-gantt-grid-line"
          style={{ left: `${tick.position}%` }}
          aria-hidden="true"
        />
      ))}
      {timeline.referencePosition !== null && (
        <i
          className="skpe-gantt-reference-line"
          style={{ left: `${timeline.referencePosition}%` }}
          aria-hidden="true"
        />
      )}
    </>
  )
}

export function JourneyGantt({
  rows,
  referenceDate,
  formatDate,
  selectedItemId,
  onSelectItem,
  canManageJourney,
  onCreateEvent,
  eventProjectionRevision,
}: JourneyGanttProps) {
  const [visibility, setVisibility] = useState<GanttVisibility>('all')
  const [events, setEvents] = useState<JourneyEventRow[]>([])
  const [initiativeTemporal, setInitiativeTemporal] = useState<InitiativeTemporalRow[]>([])
  const [actionBoard, setActionBoard] = useState<ActionBoardRow[]>([])
  const [economic, setEconomic] = useState<EconomicProjection>({})
  const [capacity, setCapacity] = useState<CapacityProjection>({})
  const [projectionLoading, setProjectionLoading] = useState(false)
  const [projectionError, setProjectionError] = useState('')
  const [selectedEvent, setSelectedEvent] = useState<JourneyEventRow | null>(null)
  const [localEventRevision, setLocalEventRevision] = useState(0)
  const [expandedJourneyIds, setExpandedJourneyIds] = useState<Set<string>>(() => new Set())
  const [expandedInitiativeIds, setExpandedInitiativeIds] = useState<Set<string>>(() => new Set())

  const organizationId = rows[0]?.organization_id ?? null
  const projectId = rows[0]?.project_id ?? null

  useEffect(() => {
    setExpandedJourneyIds(new Set())
    setExpandedInitiativeIds(new Set())
  }, [projectId])

  useEffect(() => {
    let active = true

    const loadProjection = async () => {
      if (!organizationId || !projectId) {
        setEvents([])
        setInitiativeTemporal([])
        setActionBoard([])
        setEconomic({})
        setCapacity({})
        setProjectionError('')
        return
      }

      setProjectionLoading(true)
      setProjectionError('')

      const { data, error } = await supabase.rpc(
        'get_skpe_project_operational_projection',
        {
          target_organization_id: organizationId,
          target_project_id: projectId,
          target_as_of_date: referenceDate,
        },
      )

      if (!active) return

      if (error) {
        setEvents([])
        setInitiativeTemporal([])
        setActionBoard([])
        setEconomic({})
        setCapacity({})
        setProjectionError('Projeção gerencial integrada indisponível nesta visualização.')
      } else {
        const projection = (data ?? {}) as OperationalProjection
        setEvents(projection.journeyEvents ?? [])
        setInitiativeTemporal(projection.initiativeTemporal ?? [])
        setActionBoard(projection.actionBoard ?? [])
        setEconomic(projection.economic ?? {})
        setCapacity(projection.capacity ?? {})
      }

      setProjectionLoading(false)
    }

    void loadProjection()

    return () => {
      active = false
    }
  }, [organizationId, projectId, referenceDate, eventProjectionRevision, localEventRevision])

  const journeyExpandableIds = useMemo(() => {
    const parentIds = new Set(rows.map((row) => row.parent_item_id).filter(Boolean) as string[])
    return parentIds
  }, [rows])
  const initiativeExpandableIds = useMemo(() => {
    const parentIds = new Set<string>()
    const initiative = initiativeTemporal.find((row) => row.entity_type === 'initiative')
    const actions = initiativeTemporal.filter((row) => row.entity_type === 'action')

    if (initiative && actions.length > 0) {
      parentIds.add(initiative.entity_id)
    }
    for (const action of actions) {
      if (action.parent_action_id) parentIds.add(action.parent_action_id)
    }

    return parentIds
  }, [initiativeTemporal])
  const flattenedRows = useMemo(
    () => flattenJourney(rows, expandedJourneyIds),
    [rows, expandedJourneyIds],
  )
  const displayRows = useMemo(
    () =>
      visibility === 'mandatory'
        ? flattenedRows.filter(({ row }) => row.is_mandatory)
        : flattenedRows,
    [flattenedRows, visibility],
  )
  const initiativeRows = useMemo(
    () => flattenInitiative(initiativeTemporal, expandedInitiativeIds),
    [initiativeTemporal, expandedInitiativeIds],
  )

  const toggleJourneyExpansion = (itemId: string) => {
    setExpandedJourneyIds((current) => {
      const next = new Set(current)
      if (next.has(itemId)) next.delete(itemId)
      else next.add(itemId)
      return next
    })
  }

  const toggleInitiativeExpansion = (entityId: string) => {
    setExpandedInitiativeIds((current) => {
      const next = new Set(current)
      if (next.has(entityId)) next.delete(entityId)
      else next.add(entityId)
      return next
    })
  }

  const collapseAll = () => {
    setExpandedJourneyIds(new Set())
    setExpandedInitiativeIds(new Set())
  }

  const expandAll = () => {
    setExpandedJourneyIds(new Set(journeyExpandableIds))
    setExpandedInitiativeIds(new Set(initiativeExpandableIds))
  }
  const eventsByItem = useMemo(() => {
    const grouped = new Map<string, JourneyEventRow[]>()

    for (const event of events) {
      const current = grouped.get(event.journey_item_id) ?? []
      current.push(event)
      grouped.set(event.journey_item_id, current)
    }

    return grouped
  }, [events])
  const timeline = useMemo(
    () => buildTimeline(rows, initiativeTemporal, events, referenceDate),
    [rows, initiativeTemporal, events, referenceDate],
  )
  const statusCounts = useMemo(() => getStatusCounts(actionBoard), [actionBoard])
  const temporalExceptions = useMemo(
    () =>
      initiativeTemporal
        .filter((row) => getTemporalAlert(row) !== null)
        .sort((first, second) => {
          if (first.is_completion_overdue !== second.is_completion_overdue) {
            return first.is_completion_overdue ? -1 : 1
          }
          if (first.is_start_overdue !== second.is_start_overdue) {
            return first.is_start_overdue ? -1 : 1
          }
          const firstDays = first.is_completion_overdue
            ? first.days_completion_overdue
            : first.days_start_overdue
          const secondDays = second.is_completion_overdue
            ? second.days_completion_overdue
            : second.days_start_overdue
          return secondDays - firstDays || first.code.localeCompare(second.code, 'pt-BR')
        }),
    [initiativeTemporal],
  )
  const overallocatedCapacity = useMemo(
    () => (capacity.involvedPeopleCapacity ?? []).filter((row) => row.is_overallocated),
    [capacity.involvedPeopleCapacity],
  )

  if (!timeline) {
    return (
      <section className="skpe-gantt-empty">
        <h2>Gantt ainda sem programação</h2>
        <p>
          A visão será preenchida quando houver baseline, plano vigente,
          forecast, execução registrada, iniciativas, ações ou eventos associados.
        </p>
      </section>
    )
  }

  const kinds: GanttBarKind[] = ['baseline', 'plan', 'forecast', 'actual']
  const costRows = economic.actions?.costByCurrency ?? []
  const effortRows = economic.actions?.effortByUnit ?? []
  const economicQuality = economic.actions?.dataQuality
  const capacityRows = capacity.involvedPeopleCapacity ?? []
  const allocations = capacity.allocations ?? []

  return (
    <section className="skpe-gantt-card" aria-label="Gantt gerencial integrado do Planejamento Estratégico">
      <header className="skpe-gantt-header">
        <div>
          <p className="skpe-eyebrow">Projeção gerencial integrada governada</p>
          <h2>Jornada × Iniciativa × Ações × Agenda</h2>
          <p>
            Uma única régua temporal para comparar baseline, plano, forecast e
            realizado. A Jornada, a iniciativa transversal, suas ações e os eventos
            mantêm suas próprias fontes canônicas; o Gantt apenas projeta os dados.
          </p>
          <p className="skpe-gantt-event-status" aria-live="polite">
            {projectionLoading
              ? 'Carregando projeção operacional integrada...'
              : projectionError || `${initiativeTemporal.length} item(ns) de iniciativa/ação · ${events.length} evento(s) da jornada`}
          </p>
        </div>

        <div className="skpe-gantt-header-actions">
          {canManageJourney && selectedItemId && (
            <button
              type="button"
              className="skpe-gantt-create-event-button"
              onClick={() => onCreateEvent(selectedItemId)}
            >
              Novo evento
            </button>
          )}

          <div className="skpe-gantt-filter" role="group" aria-label="Escopo da Jornada no Gantt">
            <button
              type="button"
              className={visibility === 'all' ? 'is-active' : ''}
              onClick={() => setVisibility('all')}
            >
              Todos os itens
            </button>
            <button
              type="button"
              className={visibility === 'mandatory' ? 'is-active' : ''}
              onClick={() => setVisibility('mandatory')}
            >
              Somente obrigatórios
            </button>
          </div>


        </div>
      </header>

      <div className="skpe-gantt-legend" aria-label="Legenda do Gantt">
        <span><i className="skpe-gantt-legend-baseline" />Baseline original</span>
        <span><i className="skpe-gantt-legend-plan" />Plano vigente</span>
        <span><i className="skpe-gantt-legend-forecast" />Forecast</span>
        <span><i className="skpe-gantt-legend-actual" />Realizado</span>
        <span><i className="skpe-gantt-legend-event" />Evento / agenda</span>
        <span><i className="skpe-gantt-legend-reference" />Data de referência</span>
        <span
          className="skpe-gantt-legend-actions"
          role="group"
          aria-label="Expansão hierárquica do Gantt"
        >
          <button
            type="button"
            className="skpe-gantt-icon-action"
            onClick={collapseAll}
            aria-label="Recolher tudo"
            title="Recolher tudo"
          >
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M6 9l6 6 6-6" />
            </svg>
          </button>
          <button
            type="button"
            className="skpe-gantt-icon-action"
            onClick={expandAll}
            aria-label="Expandir tudo"
            title="Expandir tudo"
          >
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M6 15l6-6 6 6" />
            </svg>
          </button>
        </span>
      </div>

      <div className="skpe-gantt-scroll">
        <div className="skpe-gantt-grid">
          <div className="skpe-gantt-axis-label">Objeto gerencial</div>
          <div className="skpe-gantt-axis">
            {timeline.ticks.map((tick) => (
              <span
                key={tick.key}
                className="skpe-gantt-axis-tick"
                style={{ left: `${tick.position}%` }}
              >
                {tick.label}
              </span>
            ))}
          </div>

          <div className="skpe-gantt-section-label">Jornada Estratégica</div>
          <div className="skpe-gantt-section-timeline">{renderTimelineBackground(timeline)}</div>

          {displayRows.map(({ row, depth, hasChildren }) => {
            const rowEvents = eventsByItem.get(row.item_id) ?? []
            const isExpanded = expandedJourneyIds.has(row.item_id)
            const varianceLabels = getTemporalVarianceLabels(row)

            return (
              <div className="skpe-gantt-row" key={`journey-${row.item_id}`}>
                <button
                  type="button"
                  className={[
                    'skpe-gantt-row-label',
                    selectedItemId === row.item_id ? 'is-selected' : '',
                  ]
                    .filter(Boolean)
                    .join(' ')}
                  onClick={() => {
                    onSelectItem(row.item_id)
                    if (hasChildren) toggleJourneyExpansion(row.item_id)
                  }}
                  aria-expanded={hasChildren ? isExpanded : undefined}
                  title={`${getItemTypeLabel(row.item_type)} · ${row.item_code} · ${row.item_name}`}
                >
                  <span style={{ paddingLeft: `${Math.min(depth, 5) * 14}px` }}>
                    <small>
                      {hasChildren ? `${isExpanded ? '▾' : '▸'} ` : ''}
                      {getItemTypeLabel(row.item_type)} · {row.item_code}
                    </small>
                    <strong>{row.item_name}</strong>
                  </span>
                  {varianceLabels.length > 0 && (
                    <span className="skpe-gantt-row-meta" aria-label="Desvios temporais">
                      {varianceLabels.map((label) => (
                        <em key={label}>{label}</em>
                      ))}
                    </span>
                  )}
                  {rowEvents.length > 0 && (
                    <em className="skpe-gantt-row-event-count">
                      {rowEvents.length} evento(s)
                    </em>
                  )}
                </button>

                <div
                  className={[
                    'skpe-gantt-timeline-cell',
                    selectedItemId === row.item_id ? 'is-selected' : '',
                  ]
                    .filter(Boolean)
                    .join(' ')}
                  onClick={() => onSelectItem(row.item_id)}
                >
                  {renderTimelineBackground(timeline)}

                  {kinds.map((kind) => {
                    const range = getJourneyRange(row, kind)
                    if (!range) return null

                    return (
                      <span
                        key={kind}
                        className={[
                          'skpe-gantt-bar',
                          `skpe-gantt-bar-${kind}`,
                          isMilestone(row, range) ? 'skpe-gantt-bar-milestone' : '',
                        ]
                          .filter(Boolean)
                          .join(' ')}
                        style={getBarStyle(range, timeline)}
                        title={getBarTitle(kind, range, formatDate)}
                        aria-label={getBarTitle(kind, range, formatDate)}
                      />
                    )
                  })}

                  {rowEvents.map((event) => {
                    const range = getEventRange(event)
                    if (!range) return null
                    const title = getEventTitle(event, range, formatDate)

                    const eventClassName = [
                      'skpe-gantt-event',
                      range.start === range.end ? 'skpe-gantt-event-milestone' : '',
                      event.event_status === 'in_progress' ? 'is-in-progress' : '',
                      canManageJourney ? 'is-manageable' : '',
                    ]
                      .filter(Boolean)
                      .join(' ')

                    if (!canManageJourney) {
                      return (
                        <span
                          key={event.event_id}
                          className={eventClassName}
                          style={getBarStyle(range, timeline)}
                          title={title}
                          aria-label={title}
                        />
                      )
                    }

                    return (
                      <button
                        key={event.event_id}
                        type="button"
                        className={eventClassName}
                        style={getBarStyle(range, timeline)}
                        title={title + " - abrir gest\u00e3o do evento"}
                        aria-label={title + " - abrir gest\u00e3o do evento"}
                        onClick={(clickEvent) => {
                          clickEvent.stopPropagation()
                          onSelectItem(row.item_id)
                          setSelectedEvent(event)
                        }}
                      />
                    )
                  })}
                </div>
              </div>
            )
          })}

          {initiativeRows.length > 0 && (
            <>
              <div className="skpe-gantt-section-label">Execução Estratégica</div>
              <div className="skpe-gantt-section-timeline">{renderTimelineBackground(timeline)}</div>

              {initiativeRows.map(({ row, depth, hasChildren }) => {
                const alert = getTemporalAlert(row)
                const isExpanded = expandedInitiativeIds.has(row.entity_id)
                const varianceLabels = getTemporalVarianceLabels(row)

                return (
                  <div className="skpe-gantt-row" key={`initiative-${row.entity_id}`}>
                    <button
                      type="button"
                      className={[
                        'skpe-gantt-row-label',
                        hasChildren ? '' : 'skpe-gantt-row-label-readonly',
                      ].filter(Boolean).join(' ')}
                      onClick={() => {
                        if (hasChildren) toggleInitiativeExpansion(row.entity_id)
                      }}
                      aria-expanded={hasChildren ? isExpanded : undefined}
                    >
                      <span style={{ paddingLeft: `${Math.min(depth, 5) * 14}px` }}>
                        <small>
                          {hasChildren ? `${isExpanded ? '▾' : '▸'} ` : ''}
                          {row.entity_type === 'initiative' ? 'Iniciativa' : 'Ação'} · {row.code}
                        </small>
                        <strong>{row.name}</strong>
                      </span>
                      <span className="skpe-gantt-row-meta">
                        <em>{row.lifecycle_status}</em>
                        {varianceLabels.map((label) => (
                          <em key={label}>{label}</em>
                        ))}
                        {alert && <b className="skpe-gantt-alert">{alert}</b>}
                      </span>
                    </button>

                    <div className="skpe-gantt-timeline-cell skpe-gantt-timeline-cell-readonly">
                      {renderTimelineBackground(timeline)}

                      {kinds.map((kind) => {
                        const range = getInitiativeRange(row, kind)
                        if (!range) return null

                        return (
                          <span
                            key={kind}
                            className={[
                              'skpe-gantt-bar',
                              `skpe-gantt-bar-${kind}`,
                              row.entity_type === 'initiative' ? 'skpe-gantt-bar-initiative' : '',
                            ]
                              .filter(Boolean)
                              .join(' ')}
                            style={getBarStyle(range, timeline)}
                            title={`${row.code} · ${getBarTitle(kind, range, formatDate)}`}
                            aria-label={`${row.code} · ${getBarTitle(kind, range, formatDate)}`}
                          />
                        )
                      })}
                    </div>
                  </div>
                )
              })}
            </>
          )}
        </div>
      </div>

      <footer className="skpe-gantt-footer">
        <span>
          {displayRows.length} item(ns) da jornada · {initiativeRows.length} item(ns) de execução · {events.length} evento(s)
        </span>
        <span>
          Janela visual: {formatDate(toDateOnly(timeline.startMs))} a{' '}
          {formatDate(toDateOnly(timeline.endMs))}
        </span>
      </footer>

      {selectedEvent && canManageJourney && (
        <JourneyEventManageDialog
          event={selectedEvent}
          onClose={() => setSelectedEvent(null)}
          onChanged={() => {
            setSelectedEvent(null)
            setLocalEventRevision((current) => current + 1)
          }}
          onParticipantChanged={() => {
            setLocalEventRevision((current) => current + 1)
          }}
        />
      )}

      <section className="skpe-management-summary" aria-label="Resumo gerencial da execução estratégica">
        <header className="skpe-management-summary-header">
          <div>
            <p className="skpe-eyebrow">Execução integrada</p>
            <h3>Prazo, Kanban, econômico e capacidade</h3>
          </div>
          <div className="skpe-gantt-filter">
            <button type="button" onClick={openGovernedKanban}>
              Abrir Kanban governado
            </button>
          </div>
          <p>
            Indicadores derivados exclusivamente das projeções governadas. Moedas e
            unidades de esforço/capacidade permanecem segregadas; não há conversão
            ou normalização automática.
          </p>
        </header>

        <div className="skpe-management-grid">
          <article className="skpe-management-card">
            <span className="skpe-management-card-kicker">Kanban transversal</span>
            <strong>{actionBoard.length}</strong>
            <small>Ações ativas na projeção do board</small>
            <div className="skpe-management-tags">
              {statusCounts.length === 0 ? (
                <span>Sem ações registradas</span>
              ) : (
                statusCounts.map(([status, count]) => (
                  <span key={status}>{status}: {count}</span>
                ))
              )}
            </div>
          </article>

          <article className="skpe-management-card">
            <span className="skpe-management-card-kicker">Capacidade humana</span>
            <strong>{capacity.visible === false ? '—' : allocations.length}</strong>
            <small>
              {capacity.visible === false
                ? 'Capacidade não visível para este usuário'
                : `${capacityRows.length} período(s) de capacidade envolvida`}
            </small>
            <div className="skpe-management-tags">
              {capacity.visible !== false && (
                <>
                  <span>Alocações: {allocations.length}</span>
                  <span className={overallocatedCapacity.length > 0 ? 'is-warning' : ''}>
                    Sobrealocados: {overallocatedCapacity.length}
                  </span>
                </>
              )}
            </div>
          </article>

          <article className="skpe-management-card">
            <span className="skpe-management-card-kicker">Exceções temporais</span>
            <strong>{temporalExceptions.length}</strong>
            <small>Itens sinalizados pela projeção temporal governada</small>
            {temporalExceptions.length === 0 ? (
              <p className="skpe-management-empty">Nenhuma exceção temporal sinalizada.</p>
            ) : (
              <div className="skpe-management-warnings" role="status">
                {temporalExceptions.slice(0, 5).map((row) => (
                  <span key={row.entity_id}>
                    {row.code} · {row.name}: {getTemporalAlert(row)}
                  </span>
                ))}
                {temporalExceptions.length > 5 && (
                  <span>+ {temporalExceptions.length - 5} exceção(ões) adicional(is) na régua temporal.</span>
                )}
              </div>
            )}
          </article>

          <article className="skpe-management-card skpe-management-card-wide">
            <span className="skpe-management-card-kicker">Custos das ações</span>
            {costRows.length === 0 ? (
              <p className="skpe-management-empty">Sem custos quantitativos registrados.</p>
            ) : (
              <div className="skpe-management-table-wrap">
                <table className="skpe-management-table">
                  <thead>
                    <tr>
                      <th>Moeda</th>
                      <th>Plano atual</th>
                      <th>Realizado</th>
                      <th>Variação</th>
                    </tr>
                  </thead>
                  <tbody>
                    {costRows.map((row) => (
                      <tr key={row.currencyCode}>
                        <td>{row.currencyCode}</td>
                        <td>{formatMoney(row.currentPlannedCost, row.currencyCode)}</td>
                        <td>{formatMoney(row.actualRealizedCost, row.currencyCode)}</td>
                        <td>{formatMoney(row.currentPlanVariance, row.currencyCode)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </article>

          <article className="skpe-management-card skpe-management-card-wide">
            <span className="skpe-management-card-kicker">Esforço das ações</span>
            {effortRows.length === 0 ? (
              <p className="skpe-management-empty">Sem esforço quantitativo registrado.</p>
            ) : (
              <div className="skpe-management-table-wrap">
                <table className="skpe-management-table">
                  <thead>
                    <tr>
                      <th>Unidade</th>
                      <th>Estimado atual</th>
                      <th>Realizado</th>
                      <th>Variação</th>
                    </tr>
                  </thead>
                  <tbody>
                    {effortRows.map((row) => (
                      <tr key={row.effortUnit}>
                        <td>{row.effortUnit}</td>
                        <td>{formatQuantity(row.currentEstimatedEffort)}</td>
                        <td>{formatQuantity(row.actualRealizedEffort)}</td>
                        <td>{formatQuantity(row.currentPlanVariance)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </article>
        </div>

        {(economicQuality?.actionsWithCostWithoutCurrency ?? 0) > 0 ||
        (economicQuality?.actionsWithEffortWithoutUnit ?? 0) > 0 ||
        overallocatedCapacity.length > 0 ? (
          <div className="skpe-management-warnings" role="status">
            {(economicQuality?.actionsWithCostWithoutCurrency ?? 0) > 0 && (
              <span>
                {economicQuality?.actionsWithCostWithoutCurrency} ação(ões) com custo sem moeda definida.
              </span>
            )}
            {(economicQuality?.actionsWithEffortWithoutUnit ?? 0) > 0 && (
              <span>
                {economicQuality?.actionsWithEffortWithoutUnit} ação(ões) com esforço sem unidade definida.
              </span>
            )}
            {overallocatedCapacity.map((row) => (
              <span key={row.capacity_period_id}>
                {row.person_name}: sobrealocação de {formatQuantity(row.overallocation_amount)} {row.capacity_unit}.
              </span>
            ))}
          </div>
        ) : null}
      </section>
    </section>
  )
}
