import { useMemo, useState, type CSSProperties } from 'react'

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

type GanttVisibility = 'all' | 'mandatory'
type GanttBarKind = 'baseline' | 'plan' | 'forecast' | 'actual'

type GanttDisplayRow = {
  row: JourneyTemporalRow
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

function getRange(row: JourneyTemporalRow, kind: GanttBarKind) {
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

function buildTimeline(
  rows: JourneyTemporalRow[],
  referenceDate: string | null,
): Timeline | null {
  const dates: number[] = []

  for (const row of rows) {
    for (const kind of ['baseline', 'plan', 'forecast', 'actual'] as const) {
      const range = getRange(row, kind)
      if (!range) continue
      dates.push(parseDateOnly(range.start), parseDateOnly(range.end))
    }
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
    deliverable: 'EntregÃ¡vel',
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

function isMilestone(row: JourneyTemporalRow, range: DateRange) {
  return (
    (row.item_type === 'gate' || row.item_type === 'deliverable') &&
    range.start === range.end
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

  const flattenedRows = useMemo(() => flattenJourney(rows), [rows])
  const displayRows = useMemo(
    () =>
      visibility === 'mandatory'
        ? flattenedRows.filter(({ row }) => row.is_mandatory)
        : flattenedRows,
    [flattenedRows, visibility],
  )
  const timeline = useMemo(
    () => buildTimeline(rows, referenceDate),
    [rows, referenceDate],
  )

  if (!timeline) {
    return (
      <section className="skpe-gantt-empty">
        <h2>Gantt ainda sem programaÃ§Ã£o</h2>
        <p>
          A visÃ£o serÃ¡ preenchida quando houver baseline, plano vigente,
          forecast ou execuÃ§Ã£o registrada na Jornada EstratÃ©gica.
        </p>
      </section>
    )
  }

  const kinds: GanttBarKind[] = ['baseline', 'plan', 'forecast', 'actual']

  return (
    <section className="skpe-gantt-card" aria-label="Gantt governado da Jornada EstratÃ©gica">
      <header className="skpe-gantt-header">
        <div>
          <p className="skpe-eyebrow">ProjeÃ§Ã£o temporal governada</p>
          <h2>Planned Ã— Actual Ã— Forecast</h2>
          <p>
            O grÃ¡fico apenas projeta datas governadas pelo backend. Arrastar ou
            editar barras nÃ£o Ã© permitido nesta visÃ£o.
          </p>
        </div>

        <div className="skpe-gantt-filter" role="group" aria-label="Escopo do Gantt">
          <button
            type="button"
            className={visibility === 'all' ? 'is-active' : ''}
            onClick={() => setVisibility('all')}
          >
            Estrutura completa
          </button>
          <button
            type="button"
            className={visibility === 'mandatory' ? 'is-active' : ''}
            onClick={() => setVisibility('mandatory')}
          >
            Somente obrigatÃ³rios
          </button>
        </div>
      </header>

      <div className="skpe-gantt-legend" aria-label="Legenda do Gantt">
        <span><i className="skpe-gantt-legend-baseline" />Baseline original</span>
        <span><i className="skpe-gantt-legend-plan" />Plano vigente</span>
        <span><i className="skpe-gantt-legend-forecast" />Forecast</span>
        <span><i className="skpe-gantt-legend-actual" />Realizado</span>
        <span><i className="skpe-gantt-legend-reference" />Data de referÃªncia</span>
      </div>

      <div className="skpe-gantt-scroll">
        <div className="skpe-gantt-grid">
          <div className="skpe-gantt-axis-label">Item da jornada</div>
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

          {displayRows.map(({ row, depth }) => (
            <div className="skpe-gantt-row" key={row.item_id}>
              <button
                type="button"
                className={[
                  'skpe-gantt-row-label',
                  selectedItemId === row.item_id ? 'is-selected' : '',
                ]
                  .filter(Boolean)
                  .join(' ')}
                onClick={() => onSelectItem(row.item_id)}
                title={`${getItemTypeLabel(row.item_type)} Â· ${row.item_code} Â· ${row.item_name}`}
              >
                <span style={{ paddingLeft: `${Math.min(depth, 5) * 14}px` }}>
                  <small>{getItemTypeLabel(row.item_type)} Â· {row.item_code}</small>
                  <strong>{row.item_name}</strong>
                </span>
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
                    title={`Data de referÃªncia: ${formatDate(referenceDate)}`}
                    aria-hidden="true"
                  />
                )}

                {kinds.map((kind) => {
                  const range = getRange(row, kind)
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
              </div>
            </div>
          ))}
        </div>
      </div>

      <footer className="skpe-gantt-footer">
        <span>{displayRows.length} itens exibidos</span>
        <span>
          Janela visual: {formatDate(toDateOnly(timeline.startMs))} a{' '}
          {formatDate(toDateOnly(timeline.endMs))}
        </span>
      </footer>
    </section>
  )
}