import {
  Component,
  useMemo,
  type ErrorInfo,
  type ReactNode,
} from 'react'
import { Gantt, Willow } from '@svar-ui/react-gantt'

import type { JourneyTemporalRow } from '../../contracts/journey'

import '@svar-ui/react-gantt/all.css'
import './SvarJourneyGantt.css'

type SvarJourneyGanttProps = {
  rows: JourneyTemporalRow[]
}

type SvarBoundaryProps = {
  children: ReactNode
}

type SvarBoundaryState = {
  hasError: boolean
  message: string
}

type TemporalSource = 'actual' | 'plan' | 'forecast' | 'baseline'

type ProjectableRange = {
  start: Date
  end: Date
  source: TemporalSource
}

type SvarTask = {
  id: string
  text: string
  start: Date
  end: Date
  progress: number
  code: string
  responsible_name: string
  temporal_source: string
}

const sourceLabels: Record<TemporalSource, string> = {
  actual: 'Realizado',
  plan: 'Plano vigente',
  forecast: 'Forecast',
  baseline: 'Baseline',
}

class SvarRuntimeBoundary extends Component<
  SvarBoundaryProps,
  SvarBoundaryState
> {
  state: SvarBoundaryState = {
    hasError: false,
    message: '',
  }

  static getDerivedStateFromError(error: unknown): SvarBoundaryState {
    return {
      hasError: true,
      message:
        error instanceof Error
          ? error.message
          : 'Falha inesperada ao renderizar o Gantt interativo.',
    }
  }

  componentDidCatch(error: unknown, info: ErrorInfo) {
    console.error('SVAR Gantt Beta runtime error:', error, info)
  }

  render() {
    if (this.state.hasError) {
      return (
        <section className="skpe-svar-gantt-runtime-error" role="alert">
          <strong>O Gantt interativo Beta não pôde ser renderizado.</strong>
          <p>
            A Jornada continua disponível. Use as abas Estrutura ou Cronograma
            (Gantt) acima enquanto este Beta é estabilizado.
          </p>
          {this.state.message ? (
            <small>Detalhe técnico: {this.state.message}</small>
          ) : null}
        </section>
      )
    }

    return this.props.children
  }
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

  if (
    Number.isNaN(start.getTime()) ||
    Number.isNaN(end.getTime())
  ) {
    return null
  }

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

function SvarJourneyGanttCore({ rows }: SvarJourneyGanttProps) {
  const projection = useMemo(() => {
    const tasks: SvarTask[] = []

    for (const row of rows) {
      const range = getProjectableRange(row)
      if (!range) continue

      tasks.push({
        id: row.item_id,
        text: `${row.item_code} · ${row.item_name}`,
        start: range.start,
        end: range.end,
        progress: clampProgress(row.item_progress),
        code: row.item_code,
        responsible_name: row.responsible_name ?? 'Não definido',
        temporal_source: sourceLabels[range.source],
      })
    }

    tasks.sort((first, second) => {
      const byStart = first.start.getTime() - second.start.getTime()
      if (byStart !== 0) return byStart
      return first.code.localeCompare(second.code, 'pt-BR')
    })

    return {
      tasks,
      omittedCount: rows.length - tasks.length,
    }
  }, [rows])

  const scales = useMemo(
    () => [
      { unit: 'month', step: 1, format: '%F %Y' },
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
            Primeira projeção estabilizada em modo somente leitura, iniciando
            pela visão mensal. A granularidade diária será refinada sem voltar
            à numeração técnica de semanas.
          </p>
        </div>

        <span className="skpe-svar-gantt-readonly-badge">
          Somente leitura
        </span>
      </header>

      {projection.omittedCount > 0 && (
        <div className="skpe-svar-gantt-notice">
          {projection.omittedCount} item(ns) sem intervalo temporal canônico
          não foram projetados. Nenhuma data foi inferida.
        </div>
      )}

      <div className="skpe-svar-gantt-frame">
        <Willow>
          <Gantt
            tasks={projection.tasks}
            scales={scales}
            readonly
            cellHeight={42}
            cellWidth={54}
          />
        </Willow>
      </div>
    </section>
  )
}

export function SvarJourneyGantt(props: SvarJourneyGanttProps) {
  return (
    <SvarRuntimeBoundary>
      <SvarJourneyGanttCore {...props} />
    </SvarRuntimeBoundary>
  )
}