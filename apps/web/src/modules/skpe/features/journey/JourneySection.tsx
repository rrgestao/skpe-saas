import { useEffect, useMemo, useState, type ReactNode } from 'react'

import { supabase } from '../../../../lib/supabase'
import { statusLabelPtBr, translateBackendMessage } from '../../../../shared/i18n/ptBR'
import { useSkpeWorkspace } from '../../context/SkpeWorkspaceContext'
import { JourneyEventCreateDialog } from './JourneyEventCreateDialog'
import { JourneyItemStatusDialog } from './JourneyItemStatusDialog'
import { JourneyGantt } from './JourneyGantt'
import { JourneyProjectPlan } from './JourneyProjectPlan'
import { SvarJourneyGantt } from './SvarJourneyGantt'
import type {
  JourneyRow,
  JourneyStatus,
  JourneyTemporalReadRow,
  JourneyTemporalRow,
  JourneyTemporalState,
} from '../../contracts/journey'

type JourneyItem = JourneyTemporalRow & {
  children: JourneyItem[]
}

function ChevronDownIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M6 9l6 6 6-6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function CheckIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M5 12l4 4L19 6"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function ClockIcon() {
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
        d="M12 8v5l3 2"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  )
}

function methodologyTextPtBr(value: string | null | undefined) {
  if (!value) return ''

  const exactLabels: Record<string, string> = {
    'Diagnostico e Entendimento Estrategico': 'Diagnóstico e Entendimento Estratégico',
    'Formulacao Estrategica': 'Formulação Estratégica',
    'Abertura da Formulacao Estrategica': 'Abertura da Formulação Estratégica',
    'Direcionadores Estrategicos': 'Direcionadores Estratégicos',
  }

  const exact = exactLabels[value.trim()]
  if (exact) return exact

  const replacements: Array<[RegExp, string]> = [
    [/\bDiagnostico\b/g, 'Diagnóstico'],
    [/\bFormulacao\b/g, 'Formulação'],
    [/\bEstrategico\b/g, 'Estratégico'],
    [/\bEstrategica\b/g, 'Estratégica'],
    [/\bProposito\b/g, 'Propósito'],
    [/\bMissao\b/g, 'Missão'],
    [/\bVisao\b/g, 'Visão'],
    [/\bValidacao\b/g, 'Validação'],
    [/\bOrganizacao\b/g, 'Organização'],
    [/\bAdministracao\b/g, 'Administração'],
    [/\bConfiguracao\b/g, 'Configuração'],
    [/\bInformacao\b/g, 'Informação'],
    [/\bGovernanca\b/g, 'Governança'],
    [/\bExecucao\b/g, 'Execução'],
    [/\bAvaliacao\b/g, 'Avaliação'],
    [/\bConcluida\b/g, 'Concluída'],
    [/\bcriterios\b/g, 'critérios'],
    [/\borganizacao\b/g, 'organização'],
    [/\bformulacao\b/g, 'formulação'],
    [/\bproposito\b/g, 'propósito'],
    [/\bmissao\b/g, 'missão'],
    [/\bvisao\b/g, 'visão'],
    [/\bprincipios\b/g, 'princípios'],
  ]

  return replacements.reduce(
    (current, [pattern, replacement]) => current.replace(pattern, replacement),
    value,
  )
}

function getStatusLabel(status: JourneyStatus) {
  const labels: Record<JourneyStatus, string> = {
    not_started: 'Não iniciada',
    in_progress: 'Em andamento',
    blocked: 'Bloqueada',
    pending_validation: 'Aguardando validação',
    completed: 'Concluída',
    cancelled: 'Cancelada',
  }

  return labels[status]
}

function getProjectStatusLabel(status: string) {
  const labels: Record<string, string> = {
    draft: 'Rascunho',
    active: 'Ativo',
    suspended: 'Suspenso',
    completed: 'Concluído',
    cancelled: 'Cancelado',
    archived: 'Arquivado',
  }

  return labels[status] ?? status
}

function getItemTypeLabel(itemType: JourneyRow['item_type']) {
  const labels: Record<JourneyRow['item_type'], string> = {
    macrophase: 'Macrofase',
    phase: 'Fase',
    stage: 'Etapa',
    meta_stage: 'Metaetapa',
    activity: 'Atividade',
    deliverable: 'Entregável',
    gate: 'Ponto de validação',
  }

  return labels[itemType]
}

function getTemporalStateLabel(state: JourneyTemporalState) {
  const labels: Record<JourneyTemporalState, string> = {
    cancelled: 'Cancelado',
    unscheduled: 'Sem programação institucional',
    completed_without_actual_end: 'Concluído sem data real de término',
    completed_on_time: 'Concluído no prazo',
    completed_late: 'Concluído com atraso',
    blocked: 'Bloqueado',
    completion_overdue: 'Conclusão em atraso',
    start_overdue: 'Início em atraso',
    on_schedule: 'No prazo',
  }

  return labels[state]
}

function getPlanKindLabel(kind: JourneyTemporalRow['current_plan_kind']) {
  if (kind === 'baseline') return 'Linha de base'
  if (kind === 'rebaseline') return 'Revisão da linha de base'
  return 'Sem plano aprovado'
}

function formatVariance(value: number | null) {
  if (value === null) return 'Não aplicável'
  if (value === 0) return 'Sem variação'
  return value > 0 ? `+${value} dias` : `${value} dias`
}

function formatPeriod(
  start: string | null,
  end: string | null,
  formatDate: (value: string | null) => string,
) {
  if (!start && !end) return 'Não programado'
  if (start && end) return `${formatDate(start)} a ${formatDate(end)}`
  if (start) return `A partir de ${formatDate(start)}`
  return `Até ${formatDate(end)}`
}

function buildJourneyTree(rows: JourneyTemporalRow[]): JourneyItem[] {
  const itemMap = new Map<string, JourneyItem>()

  for (const row of rows) {
    itemMap.set(row.item_id, {
      ...row,
      children: [],
    })
  }

  const roots: JourneyItem[] = []

  for (const item of itemMap.values()) {
    if (item.parent_item_id && itemMap.has(item.parent_item_id)) {
      itemMap.get(item.parent_item_id)?.children.push(item)
    } else {
      roots.push(item)
    }
  }

  const sortItems = (items: JourneyItem[]) => {
    items.sort(
      (firstItem, secondItem) =>
        firstItem.display_order - secondItem.display_order,
    )

    for (const item of items) {
      sortItems(item.children)
    }
  }

  sortItems(roots)
  return roots
}

function getDefaultJourneyFocus(rows: JourneyTemporalRow[]) {
  const rowMap = new Map(rows.map((row) => [row.item_id, row]))
  const inProgress = rows.filter((row) => row.item_status === 'in_progress')
  const expandedIds = new Set<string>()

  for (const row of inProgress) {
    let current: JourneyTemporalRow | undefined = row
    const visited = new Set<string>()

    while (current && !visited.has(current.item_id)) {
      visited.add(current.item_id)

      if (
        rows.some(
          (candidate) => candidate.parent_item_id === current?.item_id,
        )
      ) {
        expandedIds.add(current.item_id)
      }

      current = current.parent_item_id
        ? rowMap.get(current.parent_item_id)
        : undefined
    }
  }

  const depthOf = (row: JourneyTemporalRow) => {
    let depth = 0
    let current: JourneyTemporalRow | undefined = row
    const visited = new Set<string>()

    while (current?.parent_item_id && !visited.has(current.item_id)) {
      visited.add(current.item_id)
      depth += 1
      current = rowMap.get(current.parent_item_id)
    }

    return depth
  }

  const selected =
    [...inProgress].sort(
      (first, second) =>
        depthOf(second) - depthOf(first) ||
        first.display_order - second.display_order,
    )[0] ?? null

  return {
    expandedIds,
    selectedItemId: selected?.item_id ?? null,
  }
}

function countJourneyDescendants(item: JourneyItem): number {
  return item.children.reduce(
    (total, child) => total + 1 + countJourneyDescendants(child),
    0,
  )
}

function buildJourneyBreadcrumb(
  rows: JourneyTemporalRow[],
  selectedItemId: string | null,
) {
  if (!selectedItemId) return [] as JourneyTemporalRow[]

  const rowMap = new Map(rows.map((row) => [row.item_id, row]))
  const breadcrumb: JourneyTemporalRow[] = []
  let current = rowMap.get(selectedItemId)

  while (current) {
    breadcrumb.unshift(current)
    current = current.parent_item_id
      ? rowMap.get(current.parent_item_id)
      : undefined
  }

  return breadcrumb
}

function getJourneyStatusIcon(
  status: JourneyStatus,
  LockIcon: () => ReactNode,
) {
  if (status === 'completed') return <CheckIcon />

  if (status === 'in_progress' || status === 'pending_validation') {
    return <ClockIcon />
  }

  return <LockIcon />
}

type JourneySectionProps = {
  organizationId: string
  formatDate: (value: string | null) => string
  refreshRequestKey?: number
  LockIcon: () => ReactNode
  InitiativesIcon: () => ReactNode
  MonitoringIcon: () => ReactNode
  ArtifactsIcon: () => ReactNode
  canViewInitiatives: boolean
  canViewMonitoring: boolean
  canViewArtifacts: boolean
  onOpenInitiatives: () => void
  onOpenMonitoring: () => void
  onOpenArtifacts: () => void
  canManageJourney: boolean
  canGenerateDeliverables: boolean
  onGenerateDeliverables: (item: JourneyRow) => void
}

export function JourneySection({
  organizationId,
  formatDate,
  refreshRequestKey = 0,
  LockIcon,
  InitiativesIcon,
  MonitoringIcon,
  ArtifactsIcon,
  canViewInitiatives,
  canViewMonitoring,
  canViewArtifacts,
  onOpenInitiatives,
  onOpenMonitoring,
  onOpenArtifacts,
  canManageJourney,
  canGenerateDeliverables,
  onGenerateDeliverables,
}: JourneySectionProps) {
  const workspace = useSkpeWorkspace()
  const [rows, setRows] = useState<JourneyTemporalRow[]>([])
  const [loading, setLoading] = useState(true)
  const [statusDialogRequest, setStatusDialogRequest] =
    useState<{
      item: JourneyItem
      targetStatus: JourneyStatus
      targetProgress: number
    } | null>(null)
  const [errorMessage, setErrorMessage] = useState('')
  const [expandedItems, setExpandedItems] = useState<Set<string>>(new Set())
  const [selectedItemId, setSelectedItemId] = useState<string | null>(null)
  const [journeyView, setJourneyView] =
    useState<'structure' | 'project-plan' | 'gantt' | 'svar'>('structure')
  const [eventDialogItemId, setEventDialogItemId] = useState<string | null>(null)
  const [eventProjectionRevision, setEventProjectionRevision] = useState(0)

  const journeyTree = useMemo(() => buildJourneyTree(rows), [rows])
  const project = rows[0] ?? null

  const selectedItem = useMemo(
    () => rows.find((row) => row.item_id === selectedItemId) ?? null,
    [rows, selectedItemId],
  )

  const selectedBreadcrumb = useMemo(
    () => buildJourneyBreadcrumb(rows, selectedItemId),
    [rows, selectedItemId],
  )

  const eventDialogItem = useMemo(
    () => rows.find((row) => row.item_id === eventDialogItemId) ?? null,
    [rows, eventDialogItemId],
  )

  const temporalSummary = useMemo(() => {
    const mandatoryRows = rows.filter((row) => row.is_mandatory)
    const planRow = rows.find((row) => row.has_approved_plan) ?? null
    const forecastRow = rows.find((row) => row.has_active_forecast) ?? null

    return {
      mandatoryCount: mandatoryRows.length,
      overdueCount: mandatoryRows.filter(
        (row) => row.is_start_overdue || row.is_completion_overdue,
      ).length,
      unscheduledCount: mandatoryRows.filter(
        (row) => row.temporal_state === 'unscheduled',
      ).length,
      blockedCount: mandatoryRows.filter(
        (row) => row.temporal_state === 'blocked',
      ).length,
      planRow,
      forecastRow,
    }
  }, [rows])

  const loadJourney = async () => {
    setLoading(true)
    setErrorMessage('')

    const { data, error } = await supabase.rpc(
      'get_skpe_journey_temporal_read_model',
      {
        target_organization_id: organizationId,
        target_project_id: workspace.route.projectId,
        target_as_of_date: null,
      },
    )

    if (error) {
      setRows([])
      setErrorMessage(translateBackendMessage(error.message))
      setLoading(false)
      return
    }

    const journeyRows = ((data ?? []) as JourneyTemporalReadRow[]).map(
      (row): JourneyTemporalRow => ({
        ...row,
        planned_start_date: row.current_plan_start_date,
        planned_end_date: row.current_plan_end_date,
      }),
    )

    setRows(journeyRows)

    const defaultFocus = getDefaultJourneyFocus(journeyRows)
    setExpandedItems(defaultFocus.expandedIds)
    setSelectedItemId(defaultFocus.selectedItemId)

    setLoading(false)
  }

  useEffect(() => {
    void loadJourney()
  }, [organizationId, workspace.route.projectId, refreshRequestKey])
  useEffect(() => {
    if (!selectedItemId) return

    const onKeyDown = (event: globalThis.KeyboardEvent) => {
      if (event.key === 'Escape') {
        setSelectedItemId(null)
      }
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [selectedItemId])


  const toggleExpanded = (itemId: string) => {
    setExpandedItems((current) => {
      const next = new Set(current)
      if (next.has(itemId)) next.delete(itemId)
      else next.add(itemId)
      return next
    })
  }

  const renderJourneyItem = (item: JourneyItem, level = 0) => {
    const hasChildren = item.children.length > 0
    const isExpanded = expandedItems.has(item.item_id)

    return (
      <article
        key={item.item_id}
        className={[
          'skpe-journey-tree-item',
          `skpe-journey-level-${Math.min(level, 4)}`,
          item.is_current ? 'skpe-phase-current' : '',
          selectedItemId === item.item_id ? 'skpe-journey-item-selected' : '',
          hasChildren ? 'skpe-journey-item-drillable' : '',
        ]
          .filter(Boolean)
          .join(' ')}
        onClick={() => {
          setSelectedItemId((current) =>
            current === item.item_id ? null : item.item_id,
          )
        }}
      >
        <div className="skpe-journey-item-main">
          <div className={`skpe-phase-marker skpe-phase-${item.item_status}`}>
            {getJourneyStatusIcon(item.item_status, LockIcon)}
          </div>

          <div className="skpe-journey-item-content">
            <div className="skpe-phase-heading">
              <div>
                <p>
                  {getItemTypeLabel(item.item_type)} · {item.item_code}
                </p>
                <h2>{methodologyTextPtBr(item.item_name)}</h2>
              </div>

              <div className="skpe-journey-heading-actions">
                <span className={`skpe-pill skpe-pill-${item.item_status}`}>
                  {getStatusLabel(item.item_status)}
                </span>

                <span className="skpe-pill">
                  {getTemporalStateLabel(item.temporal_state)}
                </span>

                {hasChildren && (
                  <button
                    type="button"
                    className={[
                      'skpe-tree-toggle-button',
                      isExpanded ? 'skpe-tree-toggle-expanded' : '',
                    ]
                      .filter(Boolean)
                      .join(' ')}
                    onClick={(event) => {
                      event.stopPropagation()
                      setSelectedItemId(item.item_id)
                      toggleExpanded(item.item_id)
                    }}
                    aria-expanded={isExpanded}
                    title={
                      isExpanded
                        ? 'Recolher níveis subordinados'
                        : 'Abrir fases, etapas e atividades'
                    }
                  >
                    <span>{countJourneyDescendants(item)} itens</span>
                    <ChevronDownIcon />
                  </button>
                )}
              </div>
            </div>

            {item.item_description && (
              <p>{methodologyTextPtBr(item.item_description)}</p>
            )}

            <div className="skpe-journey-meta">
              {item.responsible_name && (
                <span>
                  Responsável: <strong>{item.responsible_name}</strong>
                </span>
              )}

              <span>
                Plano vigente:{' '}
                <strong>
                  {formatPeriod(
                    item.current_plan_start_date,
                    item.current_plan_end_date,
                    formatDate,
                  )}
                </strong>
              </span>

              {item.has_active_forecast && (
                <span>
                  Previsão:{' '}
                  <strong>
                    {formatPeriod(
                      item.forecast_start_date,
                      item.forecast_end_date,
                      formatDate,
                    )}
                  </strong>
                </span>
              )}

              {(item.actual_start_date || item.actual_end_date) && (
                <span>
                  Realizado:{' '}
                  <strong>
                    {formatPeriod(
                      item.actual_start_date,
                      item.actual_end_date,
                      formatDate,
                    )}
                  </strong>
                </span>
              )}

              {item.validation_required && (
                <span>
                  Validação:{' '}
                  <strong>{statusLabelPtBr(item.validation_status)}</strong>
                </span>
              )}
            </div>

            {!item.plan_projection_consistent && (
              <div className="skpe-journey-blocked-message">
                Divergência detectada entre o plano institucional vigente e a projeção materializada da jornada.
              </div>
            )}

            {item.blocked && item.blocking_reason && (
              <div className="skpe-journey-blocked-message">
                {item.blocking_reason}
              </div>
            )}

            <div className="skpe-phase-progress">
              <div className="skpe-progress-track">
                <span style={{ width: `${item.item_progress}%` }} />
              </div>
              <strong>{item.item_progress}%</strong>
            </div>

            {canManageJourney && (
              <div
                className="skpe-journey-quick-actions"
                onClick={(event) => event.stopPropagation()}
              >
                {item.item_status === 'not_started' && (
                  <button
                    type="button"
                    onClick={() =>
                      setStatusDialogRequest({
                        item,
                        targetStatus: 'in_progress',
                        targetProgress: Math.max(
                          item.item_progress,
                          1,
                        ),
                      })
                    }
                    disabled={statusDialogRequest !== null}
                  >
                    Iniciar
                  </button>
                )}

                {item.item_status !== 'completed' && (
                  <button
                    type="button"
                    onClick={() =>
                      setStatusDialogRequest({
                        item,
                        targetStatus: 'completed',
                        targetProgress: 100,
                      })
                    }
                    disabled={statusDialogRequest !== null}
                  >
                    Concluir
                  </button>
                )}

                {item.item_status === 'completed' && (
                  <button
                    type="button"
                    onClick={() =>
                      setStatusDialogRequest({
                        item,
                        targetStatus: 'in_progress',
                        targetProgress: Math.min(
                          item.item_progress,
                          99,
                        ),
                      })
                    }
                    disabled={statusDialogRequest !== null}
                  >
                    Reabrir
                  </button>
                )}

                {canGenerateDeliverables &&
                  (item.item_type === 'macrophase' ||
                    item.item_type === 'stage') && (
                    <button
                      type="button"
                      className="skpe-generate-deliverables-button"
                      onClick={() => onGenerateDeliverables(item)}
                    >
                      Gerar artefatos e evidências
                    </button>
                  )}
              </div>
            )}
          </div>
        </div>

        {hasChildren && isExpanded && (
          <div className="skpe-journey-children">
            {item.children.map((child) => renderJourneyItem(child, level + 1))}
          </div>
        )}
      </article>
    )
  }

  return (
    <>
      <section className="skpe-page-heading skpe-administration-heading">
        <div>
          <p className="skpe-eyebrow">Metodologia de Planejamento Estratégico</p>


        </div>
        <div
          className="skpe-context-icon-actions"
          aria-label="Atalhos da Jornada Estratégica"
        >
          {canViewInitiatives ? (
            <button
              type="button"
              className="skpe-context-icon-action"
              onClick={onOpenInitiatives}
              aria-label="Abrir Iniciativas e Kanban"
              title="Abrir Iniciativas e Kanban"
              data-tooltip="Abrir Iniciativas e Kanban"
            >
              <InitiativesIcon />
            </button>
          ) : null}

          {canViewMonitoring ? (
            <button
              type="button"
              className="skpe-context-icon-action"
              onClick={onOpenMonitoring}
              aria-label="Abrir Monitoramento"
              title="Abrir Monitoramento"
              data-tooltip="Abrir Monitoramento"
            >
              <MonitoringIcon />
            </button>
          ) : null}

          {canViewArtifacts ? (
            <button
              type="button"
              className="skpe-context-icon-action"
              onClick={onOpenArtifacts}
              aria-label="Abrir Artefatos e evidências"
              title="Artefatos e evidências"
              data-tooltip="Artefatos e evidências"
            >
              <ArtifactsIcon />
            </button>
          ) : null}
        </div>


      </section>

      {project && (
        <div className="skpe-journey-summary-stack">
          <section
            className="skpe-journey-summary-grid skpe-journey-summary-grid-primary"
            aria-label="Indicadores principais da Jornada Estratégica"
          >
            <article className="skpe-admin-kpi-card skpe-journey-summary-card">
              <span>Progresso</span>
              <strong>{project.project_progress}%</strong>
              <small>
                Situação: {getProjectStatusLabel(project.project_status)}
              </small>
            </article>

            <article className="skpe-admin-kpi-card skpe-journey-summary-card">
              <span>Data de referência</span>
              <strong>{formatDate(project.reference_date)}</strong>
              <small>
                Data de corte da análise temporal · {project.organization_timezone}
              </small>
            </article>

            <article className="skpe-admin-kpi-card skpe-journey-summary-card">
              <span>Obrigatórios em atraso</span>
              <strong>{temporalSummary.overdueCount}</strong>
              <small>
                de {temporalSummary.mandatoryCount} itens obrigatórios
                {temporalSummary.blockedCount > 0
                  ? ` · ${temporalSummary.blockedCount} bloqueados`
                  : ''}
              </small>
            </article>

            <article className="skpe-admin-kpi-card skpe-journey-summary-card">
              <span>Obrigatórios sem programação</span>
              <strong>{temporalSummary.unscheduledCount}</strong>
              <small>Estado calculado pelo sistema</small>
            </article>
          </section>

          <section
            className="skpe-journey-summary-grid skpe-journey-summary-grid-planning"
            aria-label="Planejamento temporal da Jornada Estratégica"
          >
            <article className="skpe-admin-kpi-card skpe-journey-summary-card">
              <span>Plano institucional</span>
              <strong>
                {temporalSummary.planRow?.current_plan_version_number
                  ? `v${temporalSummary.planRow.current_plan_version_number}`
                  : '—'}
              </strong>
              <small>
                {temporalSummary.planRow
                  ? getPlanKindLabel(temporalSummary.planRow.current_plan_kind)
                  : 'Sem linha de base ou revisão da linha de base aprovada'}
              </small>
            </article>

            <article className="skpe-admin-kpi-card skpe-journey-summary-card">
              <span>Previsão operacional</span>
              <strong>
                {temporalSummary.forecastRow?.current_forecast_version_number
                  ? `v${temporalSummary.forecastRow.current_forecast_version_number}`
                  : '—'}
              </strong>
              <small>
                {temporalSummary.forecastRow
                  ? 'Previsão operacional ativa'
                  : 'Sem previsão operacional ativa'}
              </small>
            </article>
          </section>
        </div>
      )}
      {rows.length > 0 && !loading && (
        <div className="skpe-journey-view-switch-row">
          <div
            className="skpe-journey-view-tabs"
            role="tablist"
            aria-label="Visualização da jornada"
          >
            <button
              type="button"
              role="tab"
              aria-selected={journeyView === 'structure'}
              className={journeyView === 'structure' ? 'active' : ''}
              onClick={() => setJourneyView('structure')}
            >
              Estrutura
            </button>            <button
              type="button"
              role="tab"
              aria-selected={journeyView === 'project-plan'}
              className={journeyView === 'project-plan' ? 'active' : ''}
              onClick={() => setJourneyView('project-plan')}
            >
              Plano do Projeto
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={journeyView === 'gantt'}
              className={journeyView === 'gantt' ? 'active' : ''}
              onClick={() => setJourneyView('gantt')}
            >
              Cronograma (Gantt)
            </button>            <button
              type="button"
              role="tab"
              aria-selected={journeyView === 'svar'}
              className={journeyView === 'svar' ? 'active' : ''}
              onClick={() => setJourneyView('svar')}
            >
              Gantt interativo Beta
            </button>
          </div>
        </div>
      )}
      {errorMessage && (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      )}

      {loading ? (
        <section className="skpe-admin-state-card">
          <p>Carregando a Jornada Estratégica...</p>
        </section>
      ) : journeyTree.length === 0 ? (
        <section className="skpe-admin-state-card">
          <h2>Nenhuma jornada encontrada</h2>
          <p>Verifique se o projeto estratégico foi criado para esta organização.</p>
        </section>
      ) : journeyView === 'project-plan' && project ? (
        <JourneyProjectPlan
          organizationId={organizationId}
          projectId={project.project_id}
          rows={rows}
          canManageJourney={canManageJourney}
          formatDate={formatDate}
          onPlanMaterialized={loadJourney}
        />
      ) : journeyView === 'gantt' ? (
        <JourneyGantt
          rows={rows}
          referenceDate={project?.reference_date ?? null}
          formatDate={formatDate}
          selectedItemId={selectedItemId}
          onSelectItem={setSelectedItemId}
          canManageJourney={canManageJourney}
          onCreateEvent={(itemId) => setEventDialogItemId(itemId)}
          eventProjectionRevision={eventProjectionRevision}
        />
      ) : journeyView === 'svar' ? (
        <SvarJourneyGantt rows={rows} />
      ) : (
        <div
          className={[
            'skpe-journey-workspace',
            selectedItem
              ? 'skpe-journey-workspace-with-detail'
              : 'skpe-journey-workspace-full',
          ].join(' ')}
        >
          <section className="skpe-journey-tree">
            {journeyTree.map((item) => renderJourneyItem(item))}
          </section>

          {selectedItem && (
            <aside className="skpe-journey-detail-panel">
              <button
                type="button"
                className="skpe-journey-detail-close"
                onClick={() => setSelectedItemId(null)}
                aria-label="Fechar detalhes"
                title="Fechar detalhes"
              >
                ×
              </button>

              <>
                <div className="skpe-journey-breadcrumb">
                  {selectedBreadcrumb.map((breadcrumbItem, index) => (
                    <span key={breadcrumbItem.item_id}>
                      {index > 0 && <b>›</b>}
                      {breadcrumbItem.item_code}
                    </span>
                  ))}
                </div>

                <p className="skpe-eyebrow">
                  {getItemTypeLabel(selectedItem.item_type)}
                </p>
                <h2>{methodologyTextPtBr(selectedItem.item_name)}</h2>
                <p>
                  {selectedItem.item_description ??
                    'Não há descrição complementar cadastrada.'}
                </p>

                <dl className="skpe-journey-detail-list">
                  <div>
                    <dt>Situação da execução</dt>
                    <dd>{getStatusLabel(selectedItem.item_status)}</dd>
                  </div>
                  <div>
                    <dt>Estado temporal</dt>
                    <dd>{getTemporalStateLabel(selectedItem.temporal_state)}</dd>
                  </div>
                  <div>
                    <dt>Progresso</dt>
                    <dd>{selectedItem.item_progress}%</dd>
                  </div>
                  <div>
                    <dt>Responsável</dt>
                    <dd>{selectedItem.responsible_name ?? 'Não definido'}</dd>
                  </div>
                  <div>
                    <dt>Linha de base original</dt>
                    <dd>
                      {selectedItem.baseline_version_number
                        ? `v${selectedItem.baseline_version_number} · `
                        : ''}
                      {formatPeriod(
                        selectedItem.baseline_start_date,
                        selectedItem.baseline_end_date,
                        formatDate,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Plano institucional vigente</dt>
                    <dd>
                      {selectedItem.current_plan_version_number
                        ? `v${selectedItem.current_plan_version_number} · ${getPlanKindLabel(selectedItem.current_plan_kind)} · `
                        : ''}
                      {formatPeriod(
                        selectedItem.current_plan_start_date,
                        selectedItem.current_plan_end_date,
                        formatDate,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Previsão operacional</dt>
                    <dd>
                      {selectedItem.current_forecast_version_number
                        ? `v${selectedItem.current_forecast_version_number} · `
                        : ''}
                      {formatPeriod(
                        selectedItem.forecast_start_date,
                        selectedItem.forecast_end_date,
                        formatDate,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Realizado</dt>
                    <dd>
                      {formatPeriod(
                        selectedItem.actual_start_date,
                        selectedItem.actual_end_date,
                        formatDate,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Plano × linha de base</dt>
                    <dd>
                      {formatVariance(
                        selectedItem.current_plan_end_variance_vs_baseline_days,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Previsão × plano</dt>
                    <dd>
                      {formatVariance(
                        selectedItem.forecast_end_variance_vs_current_plan_days,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Realizado início × plano</dt>
                    <dd>
                      {formatVariance(
                        selectedItem.actual_start_variance_vs_current_plan_days,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Realizado fim × plano</dt>
                    <dd>
                      {formatVariance(
                        selectedItem.actual_end_variance_vs_current_plan_days,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Validação</dt>
                    <dd>
                      {selectedItem.validation_required
                        ? statusLabelPtBr(selectedItem.validation_status)
                        : 'Validação não obrigatória'}
                    </dd>
                  </div>
                </dl>

                {(selectedItem.is_start_overdue ||
                  selectedItem.is_completion_overdue) && (
                  <div className="skpe-journey-detail-hint">
                    {selectedItem.is_completion_overdue
                      ? `Conclusão em atraso há ${selectedItem.days_completion_overdue} dias na data de referência.`
                      : `Início em atraso há ${selectedItem.days_start_overdue} dias na data de referência.`}
                  </div>
                )}

                {canManageJourney && (
                  <div className="skpe-journey-detail-actions">
                    <button
                      type="button"
                      className="skpe-primary-action-button"
                      onClick={() => setEventDialogItemId(selectedItem.item_id)}
                    >
                      Novo evento da Jornada
                    </button>
                  </div>
                )}

                {selectedItem.item_type === 'macrophase' && (
                  <div className="skpe-journey-detail-hint">
                    Clique novamente no cartão ou no ícone de expansão para navegar pelos níveis subordinados.
                  </div>
                )}
              </>
            </aside>
          )}
        </div>
      )}

      {statusDialogRequest ? (
        <JourneyItemStatusDialog
          itemId={statusDialogRequest.item.item_id}
          itemCode={statusDialogRequest.item.item_code}
          itemName={methodologyTextPtBr(
            statusDialogRequest.item.item_name,
          )}
          currentStatus={
            statusDialogRequest.item.item_status
          }
          targetStatus={
            statusDialogRequest.targetStatus
          }
          targetProgress={
            statusDialogRequest.targetProgress
          }
          onClose={() =>
            setStatusDialogRequest(null)
          }
          onSaved={async () => {
            await loadJourney()
            setStatusDialogRequest(null)
          }}
        />
      ) : null}

      {eventDialogItem && (
        <JourneyEventCreateDialog
          organizationId={organizationId}
          itemId={eventDialogItem.item_id}
          itemCode={eventDialogItem.item_code}
          itemName={methodologyTextPtBr(eventDialogItem.item_name)}
          timezoneName={eventDialogItem.organization_timezone}
          suggestedStartDate={
            eventDialogItem.current_plan_start_date ??
            eventDialogItem.baseline_start_date
          }
          onClose={() => setEventDialogItemId(null)}
          onCreated={() => {
            setEventProjectionRevision((current) => current + 1)
            setEventDialogItemId(null)
          }}
        />
      )}
    </>
  )
}
