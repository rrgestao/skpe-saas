import { useEffect, useMemo, useState, type CSSProperties } from 'react'

import { supabase } from '../../../../lib/supabase'
import type { JourneyTemporalRow } from '../../contracts/journey'

import './JourneyGantt.css'

const DAY_MS = 86_400_000

type JourneyGanttProps = {
  rows: JourneyTemporalRow[]
  referenceDate: string | null
  formatDate: (value: string | null) => string
  selectedItemId: string | null
  onSelectItem: (itemId: string) => void
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

type OperationalProjection = {
  journeyEvents?: JourneyEventRow[]
  initiativeTemporal?: InitiativeTemporalRow[]
}

type GanttVisibility = 'all' | 'mandatory'
type GanttBarKind = 'baseline' | 'plan' | 'forecast' | 'actual'

type GanttDisplayRow = {
  row: JourneyTemporalRow
  depth: number
}

type InitiativeDisplayRow = {
  row: InitiativeTemporalRow
  depth: number
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

function flattenJourney(rows: JourneyTemporalRow[]): GanttDisplayRow[] {
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
      result.push({ row, depth })
      visit(row.item_id, depth + 1)
    }
  }

  visit(null, 0)
  return result
}

function flattenInitiative(rows: InitiativeTemporalRow[]): InitiativeDisplayRow[] {
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
    result.push({ row: initiative, depth: 0 })
  }

  const visit = (parentId: string | null, depth: number) => {
    for (const action of byParent.get(parentId) ?? []) {
      result.push({ row: action, depth })
      visit(action.entity_id, depth + 1)
    }
  }

  visit(null, 1)
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
}: JourneyGanttProps) {
  const [visibility, setVisibility] = useState<GanttVisibility>('all')
  const [events, setEvents] = useState<JourneyEventRow[]>([])
  const [initiativeTemporal, setInitiativeTemporal] = useState<InitiativeTemporalRow[]>([])
  const [projectionLoading, setProjectionLoading] = useState(false)
  const [projectionError, setProjectionError] = useState('')

  const organizationId = rows[0]?.organization_id ?? null
  const projectId = rows[0]?.project_id ?? null

  useEffect(() => {
    let active = true

    const loadProjection = async () => {
      if (!organizationId || !projectId) {
        setEvents([])
        setInitiativeTemporal([])
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
        setProjectionError('Projeção gerencial integrada indisponível nesta visualização.')
      } else {
        const projection = (data ?? {}) as OperationalProjection
        setEvents(projection.journeyEvents ?? [])
        setInitiativeTemporal(projection.initiativeTemporal ?? [])
      }

      setProjectionLoading(false)
    }

    void loadProjection()

    return () => {
      active = false
    }
  }, [organizationId, projectId, referenceDate])

  const flattenedRows = useMemo(() => flattenJourney(rows), [rows])
  const displayRows = useMemo(
    () =>
      visibility === 'mandatory'
        ? flattenedRows.filter(({ row }) => row.is_mandatory)
        : flattenedRows,
    [flattenedRows, visibility],
  )
  const initiativeRows = useMemo(
    () => flattenInitiative(initiativeTemporal),
    [initiativeTemporal],
  )
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

        <div className="skpe-gantt-filter" role="group" aria-label="Escopo da Jornada no Gantt">
          <button
            type="button"
            className={visibility === 'all' ? 'is-active' : ''}
            onClick={() => setVisibility('all')}
          >
            Jornada completa
          </button>
          <button
            type="button"
            className={visibility === 'mandatory' ? 'is-active' : ''}
            onClick={() => setVisibility('mandatory')}
          >
            Jornada obrigatória
          </button>
        </div>
      </header>

      <div className="skpe-gantt-legend" aria-label="Legenda do Gantt">
        <span><i className="skpe-gantt-legend-baseline" />Baseline original</span>
        <span><i className="skpe-gantt-legend-plan" />Plano vigente</span>
        <span><i className="skpe-gantt-legend-forecast" />Forecast</span>
        <span><i className="skpe-gantt-legend-actual" />Realizado</span>
        <span><i className="skpe-gantt-legend-event" />Evento / agenda</span>
        <span><i className="skpe-gantt-legend-reference" />Data de referência</span>
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

          {displayRows.map(({ row, depth }) => {
            const rowEvents = eventsByItem.get(row.item_id) ?? []

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
                  onClick={() => onSelectItem(row.item_id)}
                  title={`${getItemTypeLabel(row.item_type)} · ${row.item_code} · ${row.item_name}`}
                >
                  <span style={{ paddingLeft: `${Math.min(depth, 5) * 14}px` }}>
                    <small>{getItemTypeLabel(row.item_type)} · {row.item_code}</small>
                    <strong>{row.item_name}</strong>
                  </span>
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

                    return (
                      <span
                        key={event.event_id}
                        className={[
                          'skpe-gantt-event',
                          range.start === range.end ? 'skpe-gantt-event-milestone' : '',
                          event.event_status === 'in_progress' ? 'is-in-progress' : '',
                        ]
                          .filter(Boolean)
                          .join(' ')}
                        style={getBarStyle(range, timeline)}
                        title={title}
                        aria-label={title}
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

              {initiativeRows.map(({ row, depth }) => {
                const alert = getTemporalAlert(row)

                return (
                  <div className="skpe-gantt-row" key={`initiative-${row.entity_id}`}>
                    <div className="skpe-gantt-row-label skpe-gantt-row-label-readonly">
                      <span style={{ paddingLeft: `${Math.min(depth, 5) * 14}px` }}>
                        <small>
                          {row.entity_type === 'initiative' ? 'Iniciativa' : 'Ação'} · {row.code}
                        </small>
                        <strong>{row.name}</strong>
                      </span>
                      <span className="skpe-gantt-row-meta">
                        <em>{row.lifecycle_status}</em>
                        {alert && <b className="skpe-gantt-alert">{alert}</b>}
                      </span>
                    </div>

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
    </section>
  )
}
