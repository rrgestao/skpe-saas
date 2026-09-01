import { useMemo } from 'react'
import { Gantt, Willow } from '@svar-ui/react-gantt'

import type { JourneyTemporalRow } from '../../contracts/journey'

import '@svar-ui/react-gantt/all.css'
import './SvarJourneyGantt.css'

type SvarJourneyGanttProps = {
  rows: JourneyTemporalRow[]
}

type TemporalSource = 'actual' | 'plan' | 'forecast' | 'baseline'

type ProjectableRange = {
  start: Date
  end: Date
  source: TemporalSource
}

type SvarTask = {
  id: string
  parent?: string
  text: string
  code: string
  start: Date
  end: Date
  progress: number
  type?: 'summary'
  open?: boolean
  responsible_name: string
  temporal_source: string
}

const sourceLabels: Record<TemporalSource, string> = {
  actual: 'Realizado',
  plan: 'Plano vigente',
  forecast: 'Forecast',
  baseline: 'Baseline',
}

function parseDateOnly(value: string) {
  const [year, month, day] = value.split('-').map(Number)
  return new Date(year, month - 1, day)
}

function normalizeRange(
  startValue: string | null,
  endValue: string | null,
  source: TemporalSource,
): ProjectableRange | null {
  if (!startValue && !endValue) return null

  const resolvedStart = startValue ?? endValue
  const resolvedEnd = endValue ?? startValue

  if (!resolvedStart || !resolvedEnd) return null

  const start = parseDateOnly(resolvedStart)
  const end = parseDateOnly(resolvedEnd)

  return start.getTime() <= end.getTime()
    ? { start, end, source }
    : { start: end, end: start, source }
}

function getProjectableRange(row: JourneyTemporalRow) {
  return (
    normalizeRange(row.actual_start_date, row.actual_end_date, 'actual') ??
    normalizeRange(
      row.current_plan_start_date,
      row.current_plan_end_date,
      'plan',
    ) ??
    normalizeRange(row.forecast_start_date, row.forecast_end_date, 'forecast') ??
    normalizeRange(row.baseline_start_date, row.baseline_end_date, 'baseline')
  )
}

function clampProgress(value: number) {
  return Math.max(0, Math.min(100, value))
}

export function SvarJourneyGantt({ rows }: SvarJourneyGanttProps) {
  const projection = useMemo(() => {
    const rangeById = new Map<string, ProjectableRange>()

    for (const row of rows) {
      const range = getProjectableRange(row)
      if (range) rangeById.set(row.item_id, range)
    }

    const projectableIds = new Set(rangeById.keys())
    const childCount = new Map<string, number>()

    for (const row of rows) {
      if (
        row.parent_item_id &&
        projectableIds.has(row.item_id) &&
        projectableIds.has(row.parent_item_id)
      ) {
        childCount.set(
          row.parent_item_id,
          (childCount.get(row.parent_item_id) ?? 0) + 1,
        )
      }
    }

    const tasks: SvarTask[] = rows
      .filter((row) => projectableIds.has(row.item_id))
      .sort(
        (first, second) =>
          first.display_order - second.display_order ||
          first.item_code.localeCompare(second.item_code, 'pt-BR'),
      )
      .map((row) => {
        const range = rangeById.get(row.item_id)!

        return {
          id: row.item_id,
          parent:
            row.parent_item_id && projectableIds.has(row.parent_item_id)
              ? row.parent_item_id
              : undefined,
          text: row.item_name,
          code: row.item_code,
          start: range.start,
          end: range.end,
          progress: clampProgress(row.item_progress),
          type: (childCount.get(row.item_id) ?? 0) > 0 ? 'summary' : undefined,
          open: row.item_type === 'macrophase' || row.is_current,
          responsible_name: row.responsible_name ?? 'Não definido',
          temporal_source: sourceLabels[range.source],
        }
      })

    return {
      tasks,
      omittedCount: rows.length - tasks.length,
    }
  }, [rows])

  const scales = useMemo(
    () => [
      { unit: 'month', step: 1, format: '%F %Y' },
      { unit: 'week', step: 1, format: 'Sem. %w' },
    ],
    [],
  )

  const columns = useMemo(
    () => [
      { id: 'code', header: 'Código', width: 105, sort: true },
      { id: 'text', header: 'Jornada Estratégica', flexgrow: 2, sort: true },
      {
        id: 'responsible_name',
        header: 'Responsável',
        width: 180,
        sort: true,
      },
      {
        id: 'temporal_source',
        header: 'Fonte temporal',
        width: 125,
        sort: true,
      },
      {
        id: 'progress',
        header: 'Progresso',
        width: 90,
        align: 'center' as const,
        sort: true,
      },
    ],
    [],
  )

  if (projection.tasks.length === 0) {
    return (
      <section className="skpe-svar-gantt-empty">
        <strong>Gantt interativo ainda sem intervalos projetáveis</strong>
        <p>
          Nenhuma data canônica de realizado, plano, forecast ou baseline está
          disponível para os itens desta Jornada.
        </p>
      </section>
    )
  }

  return (
    <section className="skpe-svar-gantt-beta" aria-label="Gantt interativo Beta">
      <header className="skpe-svar-gantt-beta-header">
        <div>
          <span className="skpe-svar-gantt-beta-kicker">SVAR Gantt OSS</span>
          <h2>Gantt interativo · Beta</h2>
          <p>
            Visualização somente leitura sobre o read-model temporal governado
            do SPARKs. A fonte temporal exibida em cada linha preserva a origem
            canônica da data.
          </p>
        </div>

        <span className="skpe-svar-gantt-readonly-badge">
          Somente leitura
        </span>
      </header>

      {projection.omittedCount > 0 && (
        <div className="skpe-svar-gantt-notice">
          {projection.omittedCount} item(ns) sem intervalo temporal canônico
          foram mantidos fora deste Beta. Nenhuma data foi inferida.
        </div>
      )}

      <div className="skpe-svar-gantt-frame">
        <Willow>
          <Gantt
            tasks={projection.tasks}
            scales={scales}
            columns={columns}
            readonly
            cellHeight={42}
            cellWidth={54}
          />
        </Willow>
      </div>
    </section>
  )
}