import { useRef, type ComponentType, type ReactNode } from 'react'

import {
  deriveMonitoringTimelineWindow,
  formatMonitoringTimelineDate,
  getJourneyTimelineDepth,
  getMonitoringTimelinePoint,
  getMonitoringTimelineSegment,
  type InitiativeTemporalTimelineRow,
  type JourneyEventTimelineRow,
  type JourneyTemporalTimelineRow,
  type MonitoringTimelineWindow,
} from './monitoringTimeline'

type ManagementTimelineProps = {
  journeyRows: JourneyTemporalTimelineRow[]
  initiativeRows: InitiativeTemporalTimelineRow[]
  events: JourneyEventTimelineRow[]
  referenceDate?: string
  journeyVisible: boolean
  initiativesVisible: boolean
  onOpenJourney: () => void
  onOpenInitiatives: (target?: {
    initiativeId: string
    actionId: string | null
  }) => void
  JourneyIcon: ComponentType
  InitiativesIcon: ComponentType
  onOpenEconomicExecution: () => void}

function SyncedHorizontalViewport({
  children,
  contentWidth,
}: {
  children: ReactNode
  contentWidth: number
}) {
  const topRef = useRef<HTMLDivElement>(null)
  const bodyRef = useRef<HTMLDivElement>(null)
  const syncingRef = useRef(false)

  const syncScroll = (
    source: HTMLDivElement,
    target: HTMLDivElement | null,
  ) => {
    if (!target || syncingRef.current) return
    syncingRef.current = true
    target.scrollLeft = source.scrollLeft
    window.requestAnimationFrame(() => {
      syncingRef.current = false
    })
  }

  return (
    <>
      <div
        className="skpe-horizontal-scroll-top"
        ref={topRef}
        onScroll={(event) =>
          syncScroll(event.currentTarget, bodyRef.current)
        }
        aria-label="Rolagem horizontal da visualização"
      >
        <div style={{ width: contentWidth, height: 1 }} />
      </div>
      <div
        className="skpe-management-timeline-scroll"
        ref={bodyRef}
        onScroll={(event) =>
          syncScroll(event.currentTarget, topRef.current)
        }
      >
        {children}
      </div>
    </>
  )
}

type TimelineBarsProps = {
  window: MonitoringTimelineWindow
  planStart: string | null
  planEnd: string | null
  forecastStart: string | null
  forecastEnd: string | null
  actualStart: string | null
  actualEnd: string | null
  events?: JourneyEventTimelineRow[]
}

function TimelineBars({
  window,
  planStart,
  planEnd,
  forecastStart,
  forecastEnd,
  actualStart,
  actualEnd,
  events = [],
}: TimelineBarsProps) {
  const plan = getMonitoringTimelineSegment(
    planStart,
    planEnd,
    window,
  )
  const forecast = getMonitoringTimelineSegment(
    forecastStart,
    forecastEnd,
    window,
  )
  const actual = getMonitoringTimelineSegment(
    actualStart,
    actualEnd,
    window,
  )

  return (
    <div className="skpe-management-timeline-track">
      {window.referencePosition !== null ? (
        <span
          className="skpe-management-timeline-reference"
          style={{
            left: `${window.referencePosition}%`,
          }}
          aria-hidden="true"
        />
      ) : null}

      {plan ? (
        <span
          className="skpe-management-timeline-bar is-plan"
          style={{
            left: `${plan.left}%`,
            width: `${plan.width}%`,
          }}
          title={`Plano vigente: ${formatMonitoringTimelineDate(
            planStart,
          )} — ${formatMonitoringTimelineDate(planEnd)}`}
        />
      ) : null}

      {forecast ? (
        <span
          className="skpe-management-timeline-bar is-forecast"
          style={{
            left: `${forecast.left}%`,
            width: `${forecast.width}%`,
          }}
          title={`Forecast: ${formatMonitoringTimelineDate(
            forecastStart,
          )} — ${formatMonitoringTimelineDate(
            forecastEnd,
          )}`}
        />
      ) : null}

      {actual ? (
        <span
          className="skpe-management-timeline-bar is-actual"
          style={{
            left: `${actual.left}%`,
            width: `${actual.width}%`,
          }}
          title={`Realizado: ${formatMonitoringTimelineDate(
            actualStart,
          )} — ${formatMonitoringTimelineDate(actualEnd)}`}
        />
      ) : null}

      {events.map((event) => {
        const position = getMonitoringTimelinePoint(
          event.starts_at,
          window,
        )

        if (position === null) return null

        return (
          <span
            key={event.event_id}
            className="skpe-management-timeline-event"
            style={{ left: `${position}%` }}
            title={`${event.event_title} · ${formatMonitoringTimelineDate(
              event.starts_at,
            )} · ${event.event_status}`}
            aria-label={`${event.event_title}, ${formatMonitoringTimelineDate(
              event.starts_at,
            )}, situação ${event.event_status}`}
          />
        )
      })}
    </div>
  )
}

function TimelineEconomicIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle
        cx="12"
        cy="12"
        r="8"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />
      <path
        d="M9 9.4c0-1 1.1-1.8 2.6-1.8h.8c1.5 0 2.6.8 2.6 1.8s-1 1.7-2.6 1.9h-.8C10 11.5 9 12.3 9 13.5s1.1 1.8 2.6 1.8h.8c1.5 0 2.6-.8 2.6-1.8M12 6.3v11.4"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  )
}
export function ManagementTimeline({
  journeyRows,
  initiativeRows,
  events,
  referenceDate,
  journeyVisible,
  initiativesVisible,
  onOpenJourney,
  onOpenInitiatives,  JourneyIcon,
  InitiativesIcon,
  onOpenEconomicExecution,}: ManagementTimelineProps) {
  const window = deriveMonitoringTimelineWindow(
    journeyRows,
    initiativeRows,
    events,
    referenceDate,
  )

  if (!window) {
    return (
      <article className="skpe-management-timeline">
        <header>
          <div>
            <span>Prazo previsto × realizado</span>
            <h2>Linha do tempo gerencial</h2>
          </div>
        </header>
        <p className="skpe-monitoring-empty">
          Ainda não existem datas canônicas suficientes para
          materializar a linha do tempo.
        </p>
      </article>
    )
  }

  const journeyEvents = new Map<
    string,
    JourneyEventTimelineRow[]
  >()

  for (const event of events) {
    const current =
      journeyEvents.get(event.journey_item_id) ?? []
    current.push(event)
    journeyEvents.set(
      event.journey_item_id,
      current,
    )
  }

  const orderedJourney = [...journeyRows].sort(
    (first, second) =>
      first.display_order - second.display_order ||
      first.item_code.localeCompare(
        second.item_code,
        'pt-BR',
      ),
  )

  const orderedInitiatives = [...initiativeRows].sort(
    (first, second) => {
      if (first.entity_type !== second.entity_type) {
        return first.entity_type === 'initiative'
          ? -1
          : 1
      }

      return first.code.localeCompare(
        second.code,
        'pt-BR',
      )
    },
  )

  return (
    <article className="skpe-management-timeline">
      <header>
        <div>
          <span>Prazo previsto × realizado</span>
          <h2>Linha do tempo gerencial</h2>
          <p>
            Plano vigente, forecast e execução real são
            apresentados separadamente. Os marcos da Agenda
            permanecem eventos canônicos vinculados aos itens
            da Jornada.
          </p>
        </div>

        <div className="skpe-management-timeline-legend">
          <span className="is-plan">Plano vigente</span>
          <span className="is-forecast">Previsão operacional</span>
          <span className="is-actual">Realizado</span>
          <span className="is-event">Agenda</span>
        </div>
      </header>

      <div className="skpe-management-timeline-axis">
        <span>
          {formatMonitoringTimelineDate(
            window.startDate,
          )}
        </span>
        <strong>
          Referência{' '}
          {formatMonitoringTimelineDate(
            referenceDate,
          )}
        </strong>
        <span>
          {formatMonitoringTimelineDate(
            window.endDate,
          )}
        </span>
      </div>

      {journeyVisible ? (
        <section className="skpe-management-timeline-group">
        <header>
          <div>
            <span>Jornada do Planejamento Estratégico</span>
            <h3>MegaFases, fases, etapas e agenda</h3>
          </div>
          <div
          className="skpe-timeline-icon-actions"
          aria-label="Ações da linha do tempo gerencial"
        >
          <button
            type="button"
            className="skpe-monitoring-icon-action"
            onClick={onOpenJourney}
            aria-label="Abrir Jornada Estratégica"
            title="Abrir Jornada Estratégica"
            data-tooltip="Abrir Jornada Estratégica"
          >
            <JourneyIcon />
          </button>

          {initiativesVisible ? (
            <button
              type="button"
              className="skpe-monitoring-icon-action"
              onClick={() => onOpenInitiatives()}
              aria-label="Abrir Iniciativas e Kanban"
              title="Abrir Iniciativas e Kanban"
              data-tooltip="Abrir Iniciativas e Kanban"
            >
              <InitiativesIcon />
            </button>
          ) : null}

          <button
            type="button"
            className="skpe-monitoring-icon-action"
            onClick={onOpenEconomicExecution}
            aria-label="Registrar execução econômica"
            title="Registrar execução econômica"
            data-tooltip="Registrar execução econômica"
          >
            <TimelineEconomicIcon />
          </button>
        </div>
        </header>

        <SyncedHorizontalViewport contentWidth={920}>
          <div className="skpe-management-timeline-table">
            {orderedJourney.map((row) => {
              const rowEvents =
                journeyEvents.get(row.item_id) ?? []
              const depth = getJourneyTimelineDepth(
                orderedJourney,
                row.item_id,
              )

              return (
                <div
                  key={row.item_id}
                  className="skpe-management-timeline-row"
                >
                  <div
                    className="skpe-management-timeline-label"
                    style={{
                      paddingLeft: `${depth * 0.85}rem`,
                    }}
                  >
                    <small>{row.item_type}</small>
                    <strong>
                      {row.item_code} · {row.item_name}
                    </strong>
                    <span>
                      {Math.round(row.item_progress)}% ·{' '}
                      {row.temporal_state}
                      {rowEvents.length > 0
                        ? ` · ${rowEvents.length} evento(s)`
                        : ''}
                    </span>
                  </div>

                  <TimelineBars
                    window={window}
                    planStart={
                      row.current_plan_start_date
                    }
                    planEnd={
                      row.current_plan_end_date
                    }
                    forecastStart={
                      row.forecast_start_date
                    }
                    forecastEnd={
                      row.forecast_end_date
                    }
                    actualStart={row.actual_start_date}
                    actualEnd={row.actual_end_date}
                    events={rowEvents}
                  />
                </div>
              )
            })}

            {orderedJourney.length === 0 ? (
              <p className="skpe-monitoring-empty">
                Nenhum item temporal da Jornada foi
                projetado.
              </p>
            ) : null}
          </div>
        </SyncedHorizontalViewport>
      </section>
      ) : null}

      {initiativesVisible ? (
        <section className="skpe-management-timeline-group">
        <header>
          <div>
            <span>Execução transversal</span>
            <h3>Iniciativa e ações</h3>
          </div>
          <button
            type="button"
            onClick={() => onOpenInitiatives()}
          >
            Abrir Kanban
          </button>
        </header>

        <SyncedHorizontalViewport contentWidth={920}>
          <div className="skpe-management-timeline-table">
            {orderedInitiatives.map((row) => (
              <button
                key={row.entity_id}
                type="button"
                className="skpe-management-timeline-row is-link"
                onClick={() =>
                  onOpenInitiatives({
                    initiativeId: row.initiative_id,
                    actionId:
                      row.entity_type === 'action'
                        ? row.entity_id
                        : null,
                  })
                }
              >
                <span className="skpe-management-timeline-label">
                  <small>
                    {row.entity_type === 'initiative'
                      ? 'Iniciativa'
                      : 'Ação'}
                  </small>
                  <strong>
                    {row.code} · {row.name}
                  </strong>
                  <span>
                    {row.temporal_state ?? '—'}
                    {row.is_completion_overdue
                      ? ` · atraso ${row.days_completion_overdue} dia(s)`
                      : ''}
                  </span>
                </span>

                <TimelineBars
                  window={window}
                  planStart={
                    row.current_plan_start_date
                  }
                  planEnd={row.current_plan_end_date}
                  forecastStart={
                    row.forecast_start_date
                  }
                  forecastEnd={row.forecast_end_date}
                  actualStart={row.actual_start_date}
                  actualEnd={row.actual_end_date}
                />
              </button>
            ))}

            {orderedInitiatives.length === 0 ? (
              <p className="skpe-monitoring-empty">
                Nenhuma iniciativa ou ação temporal foi
                projetada.
              </p>
            ) : null}
          </div>
        </SyncedHorizontalViewport>
      </section>
      ) : null}

      <footer>
        <span>
          O gráfico é somente leitura e não cria datas,
          eventos ou consolidações.
        </span>
        <span>
          Janela canônica: {window.totalDays} dia(s)
        </span>
      </footer>
    </article>
  )
}