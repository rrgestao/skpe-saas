import { useRef } from 'react'
import {
  buildExecutionMatrixRows,
  type ActionBoardExecutionRow,
  type CapacityAllocationExecutionRow,
  type PersonCapacityExecutionRow,
} from './monitoringExecutionMatrix'
import type {
  InitiativeTemporalTimelineRow,
} from './monitoringTimeline'

type ManagementExecutionMatrixProps = {
  actions: ActionBoardExecutionRow[]
  temporalRows: InitiativeTemporalTimelineRow[]
  allocations: CapacityAllocationExecutionRow[]
  capacityRows: PersonCapacityExecutionRow[]
  capacityVisible: boolean
  onOpenInitiatives: (target?: {
    initiativeId: string
    actionId: string | null
  }) => void
}

function formatNumber(
  value: number | null | undefined,
) {
  if (value === null || value === undefined) {
    return '—'
  }

  return new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 2,
  }).format(value)
}

function formatEconomic(
  planned: number | null,
  actual: number | null,
  unit: string | null,
) {
  const normalizedUnit =
    unit?.trim().toUpperCase() === 'BRL'
      ? 'R$'
      : unit ?? '—'

  return {
    planned: `${normalizedUnit} ${formatNumber(planned)}`,
    actual: `${normalizedUnit} ${formatNumber(actual)}`,
  }
}

function SyncedMatrixViewport({
  children,
}: {
  children: React.ReactNode
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
        aria-label="Rolagem horizontal da matriz executiva"
      >
        <div style={{ width: 1180, height: 1 }} />
      </div>
      <div
        className="skpe-execution-matrix-scroll"
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

export function ManagementExecutionMatrix({
  actions,
  temporalRows,
  allocations,
  capacityRows,
  capacityVisible,
  onOpenInitiatives,
}: ManagementExecutionMatrixProps) {
  const rows = buildExecutionMatrixRows(
    actions,
    temporalRows,
    allocations,
    capacityRows,
  )

  return (
    <article className="skpe-execution-matrix">
      <header>
        <div>
          <span>Unidade de decisão</span>
          <h2>Matriz executiva por ação</h2>
          <p>
            Prazo, progresso, custo, esforço e capacidade
            permanecem dimensões independentes. A matriz apenas
            as coloca lado a lado para leitura gerencial.
          </p>
        </div>
        <strong>{rows.length} ação(ões)</strong>
      </header>

      <SyncedMatrixViewport>
        <table>
          <thead>
            <tr>
              <th>Ação</th>
              <th>Situação e progresso</th>
              <th>Prazo</th>
              <th>Custo</th>
              <th>Esforço</th>
              <th>Capacidade</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => {
              const cost = formatEconomic(
                row.action.planned_cost,
                row.action.actual_cost,
                row.action.currency_code,
              )
              const effort = formatEconomic(
                row.action.estimated_effort,
                row.action.actual_effort,
                row.action.effort_unit,
              )

              return (
                <tr key={row.action.action_id}>
                  <td>
                    <button
                      type="button"
                      className="skpe-execution-matrix-action"
                      onClick={() =>
                        onOpenInitiatives({
                          initiativeId:
                            row.action.initiative_id,
                          actionId:
                            row.action.action_id,
                        })
                      }
                    >
                      <strong>
                        {row.action.code} ·{' '}
                        {row.action.name}
                      </strong>
                      <span>
                        Prioridade: {row.action.priority}
                      </span>
                    </button>

                    {row.attentionReasons.length > 0 ? (
                      <div className="skpe-execution-matrix-alerts">
                        {row.attentionReasons.map(
                          (reason) => (
                            <span key={reason}>
                              {reason}
                            </span>
                          ),
                        )}
                      </div>
                    ) : null}
                  </td>

                  <td>
                    <strong>{row.action.status}</strong>
                    <span>
                      {formatNumber(row.progressValue)}%
                    </span>
                    <small>
                      progresso{' '}
                      {row.progressSource === 'calculated'
                        ? 'calculado'
                        : 'oficial'}
                    </small>
                  </td>

                  <td>
                    {row.temporal ? (
                      <>
                        <strong>
                          {row.temporal.temporal_state ??
                            '—'}
                        </strong>
                        <span>
                          Plano até{' '}
                          {row.temporal
                            .current_plan_end_date ?? '—'}
                        </span>
                        <small>
                          {row.temporal
                            .is_completion_overdue
                            ? `${row.temporal.days_completion_overdue} dia(s) de atraso`
                            : row.temporal
                                .is_start_overdue
                              ? `${row.temporal.days_start_overdue} dia(s) para início`
                              : 'sem atraso sinalizado'}
                        </small>
                      </>
                    ) : (
                      <span>
                        Sem projeção temporal da ação.
                      </span>
                    )}
                  </td>

                  <td>
                    <strong>
                      Planejado {cost.planned}
                    </strong>
                    <span>
                      Realizado {cost.actual}
                    </span>
                    <small>
                      Sem conversão ou consolidação
                      cambial.
                    </small>
                  </td>

                  <td>
                    <strong>
                      Estimado {effort.planned}
                    </strong>
                    <span>
                      Realizado {effort.actual}
                    </span>
                    <small>
                      Unidade canônica da própria ação.
                    </small>
                  </td>

                  <td>
                    {!capacityVisible ? (
                      <span>
                        Não visível para este usuário.
                      </span>
                    ) : row.capacityGroups.length ===
                      0 ? (
                      <span>Sem alocação registrada.</span>
                    ) : (
                      <div className="skpe-execution-matrix-capacity">
                        {row.capacityGroups.map(
                          (group) => (
                            <span key={group.unit}>
                              {formatNumber(
                                group.allocatedAmount,
                              )}{' '}
                              {group.unit} ·{' '}
                              {group.personCount} pessoa(s)
                            </span>
                          ),
                        )}
                      </div>
                    )}

                    {row.hasOverallocatedCapacity ? (
                      <small className="is-warning">
                        Há período de capacidade
                        sobrealocado nesta ação.
                      </small>
                    ) : null}
                  </td>
                </tr>
              )
            })}

            {rows.length === 0 ? (
              <tr>
                <td colSpan={6}>
                  Nenhuma ação ativa disponível na projeção.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </SyncedMatrixViewport>

      <footer>
        <span>
          A matriz é somente leitura e não altera
          lifecycle, progresso, economia ou capacidade.
        </span>
        <span>
          Sobrealocação é exibida; nunca normalizada.
        </span>
      </footer>
    </article>
  )
}