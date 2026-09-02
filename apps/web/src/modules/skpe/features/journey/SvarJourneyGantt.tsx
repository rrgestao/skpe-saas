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
  parent?: string | number
  open?: boolean
  type?: 'task' | 'milestone' | 'summary'
}

const sourceLabels: Record<TemporalSource, string> = {
  actual: 'Realizado',
  plan: 'Plano vigente',
  forecast: 'Previsão operacional',
  baseline: 'Linha de base',
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
            A Jornada continua disponível. O erro foi isolado sem comprometer
            os registros canônicos do cronograma.
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

  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
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

function formatMonth(date: Date) {
  return `${String(date.getMonth() + 1).padStart(2, '0')}/${date.getFullYear()}`
}

function SvarJourneyGanttCore({ rows }: SvarJourneyGanttProps) {
  const projection = useMemo(() => {
    const tasks: SvarTask[] = []
    const projectableIds = new Set(
      rows
        .filter((row) => getProjectableRange(row) !== null)
        .map((row) => row.item_id),
    )
    const currentPath = new Set<string>()
    const rowMap = new Map(rows.map((row) => [row.item_id, row]))

    for (const row of rows.filter((item) => item.item_status === 'in_progress')) {
      let current: JourneyTemporalRow | undefined = row
      const visited = new Set<string>()

      while (current && !visited.has(current.item_id)) {
        visited.add(current.item_id)
        currentPath.add(current.item_id)
        current = current.parent_item_id
          ? rowMap.get(current.parent_item_id)
          : undefined
      }
    }

    const projectStartValue =
      rows.find((row) => row.project_start_date)?.project_start_date ?? null
    const projectEndValue =
      rows.find((row) => row.project_target_end_date)?.project_target_end_date ??
      null

    const projectStart = projectStartValue
      ? parseDateOnly(projectStartValue)
      : null
    const projectEnd = projectEndValue ? parseDateOnly(projectEndValue) : null

    const hasProjectWindow =
      projectStart &&
      projectEnd &&
      !Number.isNaN(projectStart.getTime()) &&
      !Number.isNaN(projectEnd.getTime())

    if (hasProjectWindow) {
      tasks.push({
        id: 'skpe-project-program-window',
        text: 'Projeto Estratégico · Programação global da Jornada',
        start: projectStart,
        end: projectEnd,
        progress: clampProgress(rows[0]?.project_progress ?? 0),
        code: 'PE',
        responsible_name: 'SPARKs PE',
        temporal_source: 'Janela institucional',
        parent: 0,
        open: true,
        type: 'summary',
      })
    }

    for (const row of rows) {
      const range = getProjectableRange(row)
      if (!range) continue

      const isActualMilestone =
        range.source === 'actual' &&
        range.start.getTime() === range.end.getTime()

      const parent =
        row.parent_item_id && projectableIds.has(row.parent_item_id)
          ? row.parent_item_id
          : hasProjectWindow
            ? 'skpe-project-program-window'
            : 0

      tasks.push({
        id: row.item_id,
        text: `${row.item_code} · ${row.item_name}`,
        start: range.start,
        end: range.end,
        progress: clampProgress(row.item_progress),
        code: row.item_code,
        responsible_name: row.responsible_name ?? 'Não definido',
        temporal_source: sourceLabels[range.source],
        parent,
        open: currentPath.has(row.item_id),
        type: isActualMilestone ? 'milestone' : 'task',
      })
    }

    tasks.sort((first, second) => {
      if (first.id === 'skpe-project-program-window') return -1
      if (second.id === 'skpe-project-program-window') return 1
      const byStart = first.start.getTime() - second.start.getTime()
      if (byStart !== 0) return byStart
      return first.code.localeCompare(second.code, 'pt-BR')
    })

    const projectedItemCount = tasks.filter(
      (task) => task.id !== 'skpe-project-program-window',
    ).length

    // SVAR 2.7.x can throw while expanding a leaf task.
    // Only tasks that actually own projected children may be open.
    const parentIds = new Set(
      tasks
        .map((task) => task.parent)
        .filter(
          (parent): parent is string | number =>
            parent !== undefined && parent !== 0,
        )
        .map((parent) => String(parent)),
    )

    for (const task of tasks) {
      const hasProjectedChildren = parentIds.has(String(task.id))
      task.open =
        hasProjectedChildren &&
        (
          task.id === 'skpe-project-program-window' ||
          currentPath.has(task.id)
        )
    }

    return {
      tasks,
      omittedCount: rows.length - projectedItemCount,
      projectStart,
      projectEnd,
    }
  }, [rows])

  const scales = useMemo(
    () => [
      {
        unit: 'month',
        step: 1,
        format: formatMonth,
        css: () => 'skpe-svar-month-scale-cell',
      },
    ],
    [],
  )

  const columns = useMemo(
    () => [
      {
        id: 'text',
        header: 'Item',
        flexgrow: 2,
        sort: true,
      },
      {
        id: 'start',
        header: 'Início',
        width: 120,
        align: 'center' as const,
        sort: true,
      },
      {
        id: 'duration',
        header: 'Duração',
        width: 90,
        align: 'center' as const,
      },
    ],
    [],
  )

  if (projection.tasks.length === 0) {
    return (
      <section className="skpe-svar-gantt-empty">
        <strong>Gantt interativo ainda sem intervalos projetáveis</strong>
        <p>
          Nenhuma data canônica de realizado, plano, previsão operacional ou
          linha de base está disponível para os itens desta Jornada.
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
            Visão mensal da janela institucional da Jornada e das datas
            temporais já materializadas. Registros realizados em um único dia
            são apresentados como marcos.
          </p>
        </div>

        <span className="skpe-svar-gantt-readonly-badge">
          Somente leitura
        </span>
      </header>

      {projection.omittedCount > 0 && (
        <div className="skpe-svar-gantt-notice">
          {projection.omittedCount} item(ns) ainda não possuem intervalo
          planejado, previsão operacional, linha de base ou realizado
          materializado. Nenhuma data de Macrofase foi inferida.
        </div>
      )}

      <div className="skpe-svar-gantt-frame">
        <Willow>
          <Gantt
            tasks={projection.tasks}
            links={[]}
            scales={scales}
            columns={columns}
            start={projection.projectStart ?? undefined}
            end={projection.projectEnd ?? undefined}
            readonly
            cellHeight={42}
            cellWidth={72}
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