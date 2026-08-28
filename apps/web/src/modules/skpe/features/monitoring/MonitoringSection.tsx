import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'
import { useSkpeWorkspace } from '../../context/SkpeWorkspaceContext'
import {
  InitiativeEconomicExecutionDialog,
  type InitiativeEconomicDirect,
} from './InitiativeEconomicExecutionDialog'
import { PersonCapacityManagementDialog } from './PersonCapacityManagementDialog'
import { ManagementTimeline } from './ManagementTimeline'
import { ManagementExecutionMatrix } from './ManagementExecutionMatrix'
import type {
  ActionBoardExecutionRow,
  CapacityAllocationExecutionRow,
  PersonCapacityExecutionRow,
} from './monitoringExecutionMatrix'
import type {
  InitiativeTemporalTimelineRow,
  JourneyEventTimelineRow,
  JourneyTemporalTimelineRow,
} from './monitoringTimeline'

import './MonitoringSection.css'

type MonitoringDrilldownTarget = {
  initiativeId: string
  actionId: string | null
}

type MonitoringSectionProps = {
  fallbackProjectId: string | null
  canManageEconomic: boolean
  canViewJourney: boolean
  canViewInitiatives: boolean
  onOpenJourney: () => void
  onOpenInitiatives: (target?: MonitoringDrilldownTarget) => void
}



type OperationalProjection = {
  referenceDate?: string
  journeyTemporal?: JourneyTemporalTimelineRow[]
  journeyEvents?: JourneyEventTimelineRow[]
  initiativeTemporal?: InitiativeTemporalTimelineRow[]
  actionBoard?: ActionBoardExecutionRow[]
  economic?: {
    initiative?: {
      initiativeId: string
      organizationId: string
      code: string
      name: string
      lifecycleStatus: string
      direct: InitiativeEconomicDirect
    }
    actions?: {
      costByCurrency?: Array<{
        currencyCode: string
        currentPlannedCost: number
        actualRealizedCost: number
        currentPlanVariance: number
      }>
      effortByUnit?: Array<{
        effortUnit: string
        currentEstimatedEffort: number
        actualRealizedEffort: number
        currentPlanVariance: number
      }>
      dataQuality?: {
        actionsWithCostWithoutCurrency: number
        actionsWithEffortWithoutUnit: number
      }
    }
  }
  capacity?: {
    visible?: boolean
    allocations?: CapacityAllocationExecutionRow[]
    involvedPeopleCapacity?: PersonCapacityExecutionRow[]
  }
  governance?: {
    readOnlyProjection?: boolean
    journeyVisible?: boolean
    initiativesVisible?: boolean
    economicVisible?: boolean
    capacityVisible?: boolean
  }
}

function countBy<T>(rows: T[], read: (row: T) => string) {
  const counts = new Map<string, number>()
  for (const row of rows) {
    const key = read(row)
    counts.set(key, (counts.get(key) ?? 0) + 1)
  }
  return Array.from(counts.entries()).sort(([first], [second]) =>
    first.localeCompare(second, 'pt-BR'),
  )
}

function getTemporalException(
  row: InitiativeTemporalTimelineRow,
) {
  if (row.is_completion_overdue) {
    return {
      severity: 3,
      days: row.days_completion_overdue,
      label: `Conclusão em atraso: ${row.days_completion_overdue} dia(s)`,
    }
  }
  if (row.is_start_overdue) {
    return {
      severity: 2,
      days: row.days_start_overdue,
      label: `Início em atraso: ${row.days_start_overdue} dia(s)`,
    }
  }
  if (row.temporal_data_quality_state !== 'ok') {
    return {
      severity: 1,
      days: 0,
      label: `Qualidade temporal: ${row.temporal_data_quality_state}`,
    }
  }
  return null
}

export function MonitoringSection({
  fallbackProjectId,
  canManageEconomic,
  canViewJourney,
  canViewInitiatives,
  onOpenJourney,
  onOpenInitiatives,
}: MonitoringSectionProps) {
  const workspace = useSkpeWorkspace()
  const projectId = workspace.route.projectId ?? fallbackProjectId
  const organizationId = workspace.organization.id

  const [projection, setProjection] = useState<OperationalProjection | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [reloadToken, setReloadToken] = useState(0)
  const [showEconomicEditor, setShowEconomicEditor] = useState(false)
  const [showCapacityManager, setShowCapacityManager] = useState(false)
  const [canManageCapacity, setCanManageCapacity] = useState(false)
  const [capacityPermissionLoading, setCapacityPermissionLoading] = useState(true)
  const [capacityPermissionError, setCapacityPermissionError] = useState('')

  useEffect(() => {
    let active = true

    setCanManageCapacity(false)
    setCapacityPermissionLoading(true)
    setCapacityPermissionError('')

    async function loadCapacityPermission() {
      try {
        const { data, error } = await supabase.rpc(
          'can_manage_sparks_people',
          {
            target_organization_id: organizationId,
          },
        )

        if (!active) return

        if (error) {
          setCanManageCapacity(false)
          setCapacityPermissionError(
            'Não foi possível verificar a permissão de gestão de capacidade.',
          )
          return
        }

        setCanManageCapacity(data === true)
      } catch {
        if (!active) return
        setCanManageCapacity(false)
        setCapacityPermissionError(
          'Não foi possível verificar a permissão de gestão de capacidade.',
        )
      } finally {
        if (active) {
          setCapacityPermissionLoading(false)
        }
      }
    }

    void loadCapacityPermission()

    return () => {
      active = false
    }
  }, [organizationId])

  useEffect(() => {
    let active = true

    const load = async () => {
      if (!projectId) {
        setProjection(null)
        setError('Planejamento Estratégico ainda não iniciado.')
        setLoading(false)
        return
      }

      setLoading(true)
      setError('')

      const { data, error: projectionError } = await supabase.rpc(
        'get_skpe_project_operational_projection',
        {
          target_organization_id: organizationId,
          target_project_id: projectId,
          target_as_of_date: null,
        },
      )

      if (!active) return

      if (projectionError) {
        setProjection(null)
        setError('Não foi possível carregar o monitoramento governado deste projeto.')
      } else {
        setProjection((data ?? {}) as OperationalProjection)
      }

      setLoading(false)
    }

    void load()

    return () => {
      active = false
    }
  }, [organizationId, projectId, reloadToken])

  const initiativeTemporal = projection?.initiativeTemporal ?? []
  const actionBoard = projection?.actionBoard ?? []
  const events = projection?.journeyEvents ?? []
  const capacityRows = projection?.capacity?.involvedPeopleCapacity ?? []

  const temporalExceptions = useMemo(
    () =>
      initiativeTemporal
        .map((row) => ({ row, exception: getTemporalException(row) }))
        .filter(
          (entry): entry is {
            row: InitiativeTemporalTimelineRow
            exception: NonNullable<
              ReturnType<typeof getTemporalException>
            >
          } =>
            entry.exception !== null,
        )
        .sort(
          (first, second) =>
            second.exception.severity - first.exception.severity ||
            second.exception.days - first.exception.days ||
            first.row.code.localeCompare(second.row.code, 'pt-BR'),
        ),
    [initiativeTemporal],
  )

  const overallocated = useMemo(
    () => capacityRows.filter((row) => row.is_overallocated),
    [capacityRows],
  )

  const statusCounts = useMemo(
    () => countBy(actionBoard, (row) => row.status),
    [actionBoard],
  )

  const eventStatusCounts = useMemo(
    () => countBy(events, (row) => row.event_status),
    [events],
  )

  const economicInitiative = projection?.economic?.initiative
  const economicDirect = economicInitiative?.direct
  const economicQuality = projection?.economic?.actions?.dataQuality
  const costCurrencies = projection?.economic?.actions?.costByCurrency ?? []
  const effortUnits = projection?.economic?.actions?.effortByUnit ?? []
  const economicEditable =
    canManageEconomic &&
    economicInitiative !== undefined &&
    !['completed', 'cancelled', 'archived'].includes(
      economicInitiative.lifecycleStatus,
    )
  const allocations = projection?.capacity?.allocations ?? []

  return (
    <section className="skpe-monitoring" aria-label="Monitoramento gerencial do Planejamento Estratégico">
      <header className="skpe-monitoring-header">
        <div>
          <p className="skpe-eyebrow">Monitoramento governado</p>
          <h1>Execução estratégica em uma visão gerencial</h1>
          <p>
            Leitura integrada da projeção operacional canônica. Jornada, ações, agenda
            e capacidade permanecem em suas fontes governadas; a execução econômica da
            iniciativa pode ser registrada aqui por usuários autorizados.
          </p>
        </div>
        <div className="skpe-monitoring-actions">
          {canViewJourney ? (
            <button type="button" onClick={onOpenJourney}>
              Abrir Jornada
            </button>
          ) : null}
          {canViewInitiatives ? (
            <button type="button" onClick={() => onOpenInitiatives()}>
              Abrir Iniciativas / Kanban
            </button>
          ) : null}
          {economicEditable ? (
            <button type="button" onClick={() => setShowEconomicEditor(true)}>
              Registrar execução econômica
            </button>
          ) : null}
          {canManageCapacity ? (
            <button
              type="button"
              onClick={() =>
                setShowCapacityManager(true)
              }
            >
              Gerenciar capacidade
            </button>
          ) : null}
        </div>
      </header>

      {capacityPermissionLoading && (
        <div className="skpe-monitoring-state">
          Verificando permissão de gestão de capacidade...
        </div>
      )}
      {!capacityPermissionLoading && capacityPermissionError && (
        <div className="skpe-monitoring-state is-error" role="alert">
          {capacityPermissionError}
        </div>
      )}

      {loading && <div className="skpe-monitoring-state">Carregando monitoramento...</div>}
      {!loading && error && <div className="skpe-monitoring-state is-error">{error}</div>}

      {!loading && projection && (
        <>
          <div className="skpe-monitoring-grid">
            <article>
              <span>Jornada temporal</span>
              <strong>
                {canViewJourney
                  ? projection.journeyTemporal?.length ?? 0
                  : '—'}
              </strong>
              <small>
                {canViewJourney
                  ? 'itens na projeção temporal da jornada'
                  : 'domínio não autorizado para este usuário'}
              </small>
            </article>
            <article className={temporalExceptions.length > 0 ? 'is-warning' : ''}>
              <span>Exceções temporais</span>
              <strong>{temporalExceptions.length}</strong>
              <small>iniciativa/ações sinalizadas pelo backend</small>
            </article>
            <article>
              <span>Kanban transversal</span>
              <strong>
                {canViewInitiatives
                  ? actionBoard.length
                  : '—'}
              </strong>
              <small>
                {canViewInitiatives
                  ? 'ações ativas na projeção do board'
                  : 'domínio não autorizado para este usuário'}
              </small>
            </article>
            <article>
              <span>Agenda da Jornada</span>
              <strong>
                {canViewJourney ? events.length : '—'}
              </strong>
              <small>
                {canViewJourney
                  ? 'eventos vinculados à jornada'
                  : 'domínio não autorizado para este usuário'}
              </small>
            </article>
            <article className={overallocated.length > 0 ? 'is-warning' : ''}>
              <span>Capacidade</span>
              <strong>{projection.capacity?.visible === false ? '—' : allocations.length}</strong>
              <small>
                {projection.capacity?.visible === false
                  ? 'capacidade não visível para este usuário'
                  : `${overallocated.length} período(s) sobrealocado(s)`}
              </small>
            </article>
            <article>
              <span>Econômico</span>
              <strong>
                {canViewInitiatives
                  ? costCurrencies.length + effortUnits.length
                  : '—'}
              </strong>
              <small>
                {canViewInitiatives
                  ? `${costCurrencies.length} moeda(s) · ${effortUnits.length} unidade(s) de esforço`
                  : 'domínio não autorizado para este usuário'}
              </small>
            </article>
          </div>

          <div className="skpe-monitoring-columns">
            <article className="skpe-monitoring-panel">
              <header>
                <div>
                  <span>Prioridade gerencial</span>
                  <h2>Exceções que exigem atenção</h2>
                </div>
                <strong>{temporalExceptions.length + overallocated.length}</strong>
              </header>

              {temporalExceptions.length === 0 && overallocated.length === 0 ? (
                <p className="skpe-monitoring-empty">Nenhuma exceção temporal ou de capacidade sinalizada.</p>
              ) : (
                <div className="skpe-monitoring-exceptions">
                  {temporalExceptions.slice(0, 8).map(({ row, exception }) => (
                    <button
                      key={row.entity_id}
                      type="button"
                      className="skpe-monitoring-exception-link"
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
                      <strong>{row.code} · {row.name}</strong>
                      <span>{exception.label}</span>
                      <small>
                        {row.entity_type === 'action'
                          ? 'Abrir a\u00e7\u00e3o no Kanban'
                          : 'Abrir iniciativa no Kanban'}
                      </small>
                    </button>
                  ))}
                  {overallocated.slice(0, 5).map((row) => (
                    <div key={row.capacity_period_id}>
                      <strong>{row.person_name}</strong>
                      <span>
                        Sobrealocação de {row.overallocation_amount} {row.capacity_unit}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </article>

            <article className="skpe-monitoring-panel">
              <header>
                <div>
                  <span>Distribuições operacionais</span>
                  <h2>Status de execução e agenda</h2>
                </div>
              </header>

              <div className="skpe-monitoring-tags">
                {statusCounts.map(([status, count]) => (
                  <span key={`action-${status}`}>Ações · {status}: {count}</span>
                ))}
                {eventStatusCounts.map(([status, count]) => (
                  <span key={`event-${status}`}>Agenda · {status}: {count}</span>
                ))}
                {statusCounts.length === 0 && eventStatusCounts.length === 0 && (
                  <span>Sem ações ou eventos registrados.</span>
                )}
              </div>

              <div className="skpe-monitoring-quality">
                <span>
                  Custos sem moeda: {economicQuality?.actionsWithCostWithoutCurrency ?? 0}
                </span>
                <span>
                  Esforços sem unidade: {economicQuality?.actionsWithEffortWithoutUnit ?? 0}
                </span>
              </div>
            </article>
          </div>

          <ManagementTimeline
            journeyRows={projection.journeyTemporal ?? []}
            initiativeRows={initiativeTemporal}
            events={events}
            referenceDate={projection.referenceDate}
            journeyVisible={canViewJourney}
            initiativesVisible={canViewInitiatives}
            onOpenJourney={onOpenJourney}
            onOpenInitiatives={onOpenInitiatives}
          />

          {canViewInitiatives ? (
            <ManagementExecutionMatrix
              actions={actionBoard}
              temporalRows={initiativeTemporal}
              allocations={allocations}
              capacityRows={capacityRows}
              capacityVisible={
                projection.capacity?.visible === true
              }
              onOpenInitiatives={onOpenInitiatives}
            />
          ) : null}

          {economicInitiative && economicDirect ? (
            <article className="skpe-monitoring-economic">
              <header>
                <div>
                  <span>Execução econômica governada</span>
                  <h2>
                    {economicInitiative.code} · {economicInitiative.name}
                  </h2>
                </div>
                {economicEditable ? (
                  <button
                    type="button"
                    onClick={() => setShowEconomicEditor(true)}
                  >
                    Editar valores diretos
                  </button>
                ) : null}
              </header>

              <div className="skpe-monitoring-economic-grid">
                <div>
                  <span>Custo direto planejado</span>
                  <strong>
                    {economicDirect.currencyCode ?? '—'}{' '}
                    {economicDirect.plannedCost ?? '—'}
                  </strong>
                </div>
                <div>
                  <span>Custo direto realizado</span>
                  <strong>
                    {economicDirect.currencyCode ?? '—'}{' '}
                    {economicDirect.actualCost ?? '—'}
                  </strong>
                </div>
                <div>
                  <span>Esforço direto estimado</span>
                  <strong>
                    {economicDirect.estimatedEffort ?? '—'}{' '}
                    {economicDirect.effortUnit ?? ''}
                  </strong>
                </div>
                <div>
                  <span>Esforço direto realizado</span>
                  <strong>
                    {economicDirect.actualEffort ?? '—'}{' '}
                    {economicDirect.effortUnit ?? ''}
                  </strong>
                </div>
              </div>

              <div className="skpe-monitoring-economic-breakdown">
                {costCurrencies.map((row) => (
                  <span key={`cost-${row.currencyCode}`}>
                    Ações · {row.currencyCode}: planejado {row.currentPlannedCost}
                    {' · '}realizado {row.actualRealizedCost}
                  </span>
                ))}
                {effortUnits.map((row) => (
                  <span key={`effort-${row.effortUnit}`}>
                    Ações · {row.effortUnit}: estimado {row.currentEstimatedEffort}
                    {' · '}realizado {row.actualRealizedEffort}
                  </span>
                ))}
              </div>

              <p>
                Valores diretos da iniciativa e valores derivados das ações são
                apresentados separadamente. Não há roll-up automático nem conversão
                cambial.
              </p>
            </article>
          ) : null}

          <footer className="skpe-monitoring-footer">
            <span>Referência: {projection.referenceDate ?? 'data atual da organização'}</span>
            <span>
              Projeção somente leitura: {projection.governance?.readOnlyProjection === false ? 'não' : 'sim'}
            </span>
          </footer>
        </>
      )}
      {showEconomicEditor && economicInitiative ? (
        <InitiativeEconomicExecutionDialog
          initiativeId={economicInitiative.initiativeId}
          initiativeCode={economicInitiative.code}
          initiativeName={economicInitiative.name}
          lifecycleStatus={economicInitiative.lifecycleStatus}
          direct={economicInitiative.direct}
          onClose={() => setShowEconomicEditor(false)}
          onSaved={() => {
            setShowEconomicEditor(false)
            setReloadToken((current) => current + 1)
          }}
        />
      ) : null}

      {showCapacityManager ? (
        <PersonCapacityManagementDialog
          organizationId={organizationId}
          onClose={() =>
            setShowCapacityManager(false)
          }
          onSaved={() => {
            setShowCapacityManager(false)
            setReloadToken(
              (current) => current + 1,
            )
          }}
        />
      ) : null}
    </section>
  )
}
