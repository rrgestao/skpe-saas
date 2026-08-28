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
  onOpenJourney: () => void
  onOpenInitiatives: (target?: {
    initiativeId: string
    actionId: string | null
  }) => void
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

export function ManagementTimeline({
  journeyRows,
  initiativeRows,
  events,
  referenceDate,
  onOpenJourney,
  onOpenInitiatives,
}: ManagementTimelineProps) {
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
          <span className="is-forecast">Forecast</span>
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

      <section className="skpe-management-timeline-group">
        <header>
          <div>
            <span>Jornada do Planejamento Estratégico</span>
            <h3>MegaFases, fases, etapas e agenda</h3>
          </div>
          <button type="button" onClick={onOpenJourney}>
            Abrir Jornada
          </button>
        </header>

        <div className="skpe-management-timeline-scroll">
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
        </div>
      </section>

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

        <div className="skpe-management-timeline-scroll">
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
        </div>
      </section>

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