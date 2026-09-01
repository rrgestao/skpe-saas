import { useEffect, useMemo, useState, type ComponentType } from 'react'

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
  JourneyIcon: ComponentType
  InitiativesIcon: ComponentType
  onOpenJourney: () => void
  onOpenInitiatives: (target?: MonitoringDrilldownTarget) => void
  refreshRequestKey?: number
}



function EconomicExecutionIcon() {
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

function CapacityManagementIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="8" cy="8" r="2.4" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <circle cx="16" cy="8" r="2.4" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <path d="M3.8 17c.5-2.8 2-4.2 4.2-4.2s3.7 1.4 4.2 4.2M11.8 17c.5-2.8 2-4.2 4.2-4.2s3.7 1.4 4.2 4.2" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  )
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

function currencyDisplayLabel(currency: string | null | undefined) {
  const code = currency?.trim().toUpperCase() || 'BRL'
  return code === 'BRL' ? 'R$' : code
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

function describeTemporalDataQuality(state: string) {
  switch (state) {
    case 'actual_start_unknown':
      return 'A execução foi sinalizada, mas a data real de início ainda não foi registrada.'
    case 'actual_end_unknown':
      return 'A conclusão foi sinalizada, mas a data real de término ainda não foi registrada.'
    case 'planned_start_unknown':
    case 'current_plan_start_unknown':
      return 'A data planejada de início ainda não foi definida.'
    case 'planned_end_unknown':
    case 'current_plan_end_unknown':
      return 'A data planejada de conclusão ainda não foi definida.'
    case 'forecast_start_unknown':
      return 'A previsão operacional de início ainda não possui uma data definida.'
    case 'forecast_end_unknown':
      return 'A previsão operacional de conclusão ainda não possui uma data definida.'
    case 'baseline_start_unknown':
      return 'A linha de base ainda não possui data de início definida.'
    case 'baseline_end_unknown':
      return 'A linha de base ainda não possui data de conclusão definida.'
    default:
      return 'Há informações temporais incompletas que precisam ser revisadas.'
  }
}

function getTemporalException(
  row: InitiativeTemporalTimelineRow,
) {
  if (row.is_completion_overdue) {
    return {
      severity: 3,
      days: row.days_completion_overdue,
      label: `Conclusão em atraso há ${row.days_completion_overdue} dia(s).`,
      guidance:
        'Revisar o prazo, registrar a conclusão ou atualizar a previsão operacional de término.',
    }
  }

  if (row.is_start_overdue) {
    return {
      severity: 2,
      days: row.days_start_overdue,
      label: `Início em atraso há ${row.days_start_overdue} dia(s).`,
      guidance:
        'Confirmar o início, reprogramar a data ou atualizar a situação da execução.',
    }
  }

  if (row.temporal_data_quality_state !== 'ok') {
    return {
      severity: 1,
      days: 0,
      label: describeTemporalDataQuality(row.temporal_data_quality_state),
      guidance:
        'Completar ou corrigir as datas de planejamento e execução deste item.',
    }
  }

  return null
}

export function MonitoringSection({
  fallbackProjectId,
  canManageEconomic,
  canViewJourney,
  canViewInitiatives,
  JourneyIcon,
  InitiativesIcon,
  onOpenJourney,
  onOpenInitiatives,
  refreshRequestKey = 0,
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
  }, [organizationId, projectId, reloadToken, refreshRequestKey])

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
        <div
          className="skpe-monitoring-title-help"
          tabIndex={0}
          aria-label="Execução Estratégica. Visão Gerencial."
          data-help="Leitura integrada da projeção operacional canônica. Jornada, ações, agenda e capacidade permanecem em suas fontes governadas; a execução econômica da iniciativa pode ser registrada aqui por usuários autorizados."
        >
          <h1 className="skpe-monitoring-title">
            <span>Execução Estratégica</span>
            <span>Visão Gerencial</span>
          </h1>
        </div>

        <div
          className="skpe-monitoring-icon-actions"
          aria-label="Ações do monitoramento"
        >
          {canViewJourney ? (
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
          ) : null}

          {canViewInitiatives ? (
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

          {economicEditable ? (
            <button
              type="button"
              className="skpe-monitoring-icon-action"
              onClick={() => setShowEconomicEditor(true)}
              aria-label="Registrar execução econômica"
              title="Registrar execução econômica"
              data-tooltip="Registrar execução econômica"
            >
              <EconomicExecutionIcon />
            </button>
          ) : null}

          {canManageCapacity ? (
            <button
              type="button"
              className="skpe-monitoring-icon-action"
              onClick={() => setShowCapacityManager(true)}
              aria-label="Gerenciar capacidade"
              title="Gerenciar capacidade"
              data-tooltip="Gerenciar capacidade"
            >
              <CapacityManagementIcon />
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
              <span>Atenções temporais</span>
              <strong>{temporalExceptions.length}</strong>
              <small>itens que requerem revisão gerencial</small>
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
                  <span>Atenção gerencial</span>
                  <h2>Atenções prioritárias</h2>
                </div>
                <strong>{temporalExceptions.length + overallocated.length}</strong>
              </header>

              {temporalExceptions.length === 0 && overallocated.length === 0 ? (
                <p className="skpe-monitoring-empty">Nenhuma atenção temporal ou de capacidade identificada.</p>
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
                      <span className="skpe-monitoring-attention-guidance">
                        <b>Próxima ação:</b> {exception.guidance}
                      </span>
                      <small>
                        {row.entity_type === 'action'
                          ? 'Abrir ação para revisar'
                          : 'Abrir iniciativa para revisar'}
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
            JourneyIcon={JourneyIcon}
            InitiativesIcon={InitiativesIcon}
            onOpenEconomicExecution={() => setShowEconomicEditor(true)}
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
                    {currencyDisplayLabel(economicDirect.currencyCode)}{' '}
                    {economicDirect.plannedCost ?? '—'}
                  </strong>
                </div>
                <div>
                  <span>Custo direto realizado</span>
                  <strong>
                    {currencyDisplayLabel(economicDirect.currencyCode)}{' '}
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
                    Ações · {currencyDisplayLabel(row.currencyCode)}: planejado {row.currentPlannedCost}
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
