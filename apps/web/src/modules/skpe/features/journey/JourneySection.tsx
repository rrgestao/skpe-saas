import { useEffect, useMemo, useState, type ReactNode } from 'react'

import { supabase } from '../../../../lib/supabase'
import { statusLabelPtBr, translateBackendMessage } from '../../../../shared/i18n/ptBR'
import { useSkpeWorkspace } from '../../context/SkpeWorkspaceContext'
import { JourneyEventCreateDialog } from './JourneyEventCreateDialog'
import { JourneyGantt } from './JourneyGantt'
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
    'Diagnostico e Entendimento Estrategico': 'DiagnÃ³stico e Entendimento EstratÃ©gico',
    'Formulacao Estrategica': 'FormulaÃ§Ã£o EstratÃ©gica',
    'Abertura da Formulacao Estrategica': 'Abertura da FormulaÃ§Ã£o EstratÃ©gica',
    'Direcionadores Estrategicos': 'Direcionadores EstratÃ©gicos',
  }

  const exact = exactLabels[value.trim()]
  if (exact) return exact

  const replacements: Array<[RegExp, string]> = [
    [/\bDiagnostico\b/g, 'DiagnÃ³stico'],
    [/\bFormulacao\b/g, 'FormulaÃ§Ã£o'],
    [/\bEstrategico\b/g, 'EstratÃ©gico'],
    [/\bEstrategica\b/g, 'EstratÃ©gica'],
    [/\bProposito\b/g, 'PropÃ³sito'],
    [/\bMissao\b/g, 'MissÃ£o'],
    [/\bVisao\b/g, 'VisÃ£o'],
    [/\bValidacao\b/g, 'ValidaÃ§Ã£o'],
    [/\bOrganizacao\b/g, 'OrganizaÃ§Ã£o'],
    [/\bAdministracao\b/g, 'AdministraÃ§Ã£o'],
    [/\bConfiguracao\b/g, 'ConfiguraÃ§Ã£o'],
    [/\bInformacao\b/g, 'InformaÃ§Ã£o'],
    [/\bGovernanca\b/g, 'GovernanÃ§a'],
    [/\bExecucao\b/g, 'ExecuÃ§Ã£o'],
    [/\bAvaliacao\b/g, 'AvaliaÃ§Ã£o'],
    [/\bConcluida\b/g, 'ConcluÃ­da'],
    [/\bcriterios\b/g, 'critÃ©rios'],
    [/\borganizacao\b/g, 'organizaÃ§Ã£o'],
    [/\bformulacao\b/g, 'formulaÃ§Ã£o'],
    [/\bproposito\b/g, 'propÃ³sito'],
    [/\bmissao\b/g, 'missÃ£o'],
    [/\bvisao\b/g, 'visÃ£o'],
    [/\bprincipios\b/g, 'princÃ­pios'],
  ]

  return replacements.reduce(
    (current, [pattern, replacement]) => current.replace(pattern, replacement),
    value,
  )
}

function getStatusLabel(status: JourneyStatus) {
  const labels: Record<JourneyStatus, string> = {
    not_started: 'NÃ£o iniciada',
    in_progress: 'Em andamento',
    blocked: 'Bloqueada',
    pending_validation: 'Aguardando validaÃ§Ã£o',
    completed: 'ConcluÃ­da',
    cancelled: 'Cancelada',
  }

  return labels[status]
}

function getProjectStatusLabel(status: string) {
  const labels: Record<string, string> = {
    draft: 'Rascunho',
    active: 'Ativo',
    suspended: 'Suspenso',
    completed: 'ConcluÃ­do',
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
    deliverable: 'EntregÃ¡vel',
    gate: 'Gate de validaÃ§Ã£o',
  }

  return labels[itemType]
}

function getTemporalStateLabel(state: JourneyTemporalState) {
  const labels: Record<JourneyTemporalState, string> = {
    cancelled: 'Cancelado',
    unscheduled: 'Sem programaÃ§Ã£o institucional',
    completed_without_actual_end: 'ConcluÃ­do sem data real de tÃ©rmino',
    completed_on_time: 'ConcluÃ­do no prazo',
    completed_late: 'ConcluÃ­do com atraso',
    blocked: 'Bloqueado',
    completion_overdue: 'ConclusÃ£o em atraso',
    start_overdue: 'InÃ­cio em atraso',
    on_schedule: 'No prazo',
  }

  return labels[state]
}

function getPlanKindLabel(kind: JourneyTemporalRow['current_plan_kind']) {
  if (kind === 'baseline') return 'Baseline'
  if (kind === 'rebaseline') return 'Rebaseline'
  return 'Sem plano aprovado'
}

function formatVariance(value: number | null) {
  if (value === null) return 'NÃ£o aplicÃ¡vel'
  if (value === 0) return 'Sem variaÃ§Ã£o'
  return value > 0 ? `+${value} dias` : `${value} dias`
}

function formatPeriod(
  start: string | null,
  end: string | null,
  formatDate: (value: string | null) => string,
) {
  if (!start && !end) return 'NÃ£o programado'
  if (start && end) return `${formatDate(start)} a ${formatDate(end)}`
  if (start) return `A partir de ${formatDate(start)}`
  return `AtÃ© ${formatDate(end)}`
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
  RefreshIcon: () => ReactNode
  JourneyIcon: () => ReactNode
  LockIcon: () => ReactNode
  canManageJourney: boolean
  canGenerateDeliverables: boolean
  onGenerateDeliverables: (item: JourneyRow) => void
}

export function JourneySection({
  organizationId,
  formatDate,
  RefreshIcon,
  JourneyIcon,
  LockIcon,
  canManageJourney,
  canGenerateDeliverables,
  onGenerateDeliverables,
}: JourneySectionProps) {
  const workspace = useSkpeWorkspace()
  const [rows, setRows] = useState<JourneyTemporalRow[]>([])
  const [loading, setLoading] = useState(true)
  const [savingItemId, setSavingItemId] = useState<string | null>(null)
  const [errorMessage, setErrorMessage] = useState('')
  const [expandedItems, setExpandedItems] = useState<Set<string>>(new Set())
  const [selectedItemId, setSelectedItemId] = useState<string | null>(null)
  const [journeyView, setJourneyView] = useState<'structure' | 'gantt'>('structure')
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

    setExpandedItems(
      new Set(
        journeyRows
          .filter(
            (row) =>
              row.item_type === 'macrophase' &&
              (row.is_current || row.item_status === 'in_progress'),
          )
          .map((row) => row.item_id),
      ),
    )

    setSelectedItemId((current) =>
      journeyRows.some((row) => row.item_id === current)
        ? current
        : journeyRows.find((row) => row.is_current)?.item_id ??
          journeyRows.find((row) => row.item_type === 'macrophase')?.item_id ??
          null,
    )

    setLoading(false)
  }

  useEffect(() => {
    void loadJourney()
  }, [organizationId, workspace.route.projectId])

  const updateJourneyItem = async (
    item: JourneyItem,
    targetStatus: JourneyStatus,
    targetProgress: number,
  ) => {
    const actionLabel =
      targetStatus === 'completed'
        ? 'concluir'
        : targetStatus === 'in_progress'
          ? 'iniciar'
          : 'atualizar'

    const reason = window.prompt(
      `Informe a justificativa para ${actionLabel} "${item.item_name}".`,
    )

    if (!reason) return

    if (reason.trim().length < 10) {
      window.alert('A justificativa deve ter pelo menos 10 caracteres.')
      return
    }

    setSavingItemId(item.item_id)

    const { error } = await supabase.rpc('set_skpe_journey_item_status', {
      target_item_id: item.item_id,
      target_status: targetStatus,
      target_progress: targetProgress,
      change_reason: reason.trim(),
    })

    if (error) {
      window.alert(translateBackendMessage(error.message))
      setSavingItemId(null)
      return
    }

    await loadJourney()
    setSavingItemId(null)
  }

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
          setSelectedItemId(item.item_id)
          if (hasChildren) toggleExpanded(item.item_id)
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
                  {getItemTypeLabel(item.item_type)} Â· {item.item_code}
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
                        ? 'Recolher nÃ­veis subordinados'
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
                  ResponsÃ¡vel: <strong>{item.responsible_name}</strong>
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
                  Forecast:{' '}
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
                  ValidaÃ§Ã£o:{' '}
                  <strong>{statusLabelPtBr(item.validation_status)}</strong>
                </span>
              )}
            </div>

            {!item.plan_projection_consistent && (
              <div className="skpe-journey-blocked-message">
                DivergÃªncia detectada entre o plano institucional vigente e a projeÃ§Ã£o materializada da jornada.
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
                      void updateJourneyItem(
                        item,
                        'in_progress',
                        Math.max(item.item_progress, 1),
                      )
                    }
                    disabled={savingItemId === item.item_id}
                  >
                    Iniciar
                  </button>
                )}

                {item.item_status !== 'completed' && (
                  <button
                    type="button"
                    onClick={() =>
                      void updateJourneyItem(item, 'completed', 100)
                    }
                    disabled={savingItemId === item.item_id}
                  >
                    Concluir
                  </button>
                )}

                {item.item_status === 'completed' && (
                  <button
                    type="button"
                    onClick={() =>
                      void updateJourneyItem(
                        item,
                        'in_progress',
                        Math.min(item.item_progress, 99),
                      )
                    }
                    disabled={savingItemId === item.item_id}
                  >
                    Reabrir
                  </button>
                )}

                {level === 0 && canGenerateDeliverables && (
                  <button
                    type="button"
                    className="skpe-generate-deliverables-button"
                    onClick={() => onGenerateDeliverables(item)}
                  >
                    Gerar entregÃ¡veis
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
          <p className="skpe-eyebrow">Metodologia de Planejamento EstratÃ©gico</p>
          <h1>Jornada EstratÃ©gica</h1>
          <p>
            ExecuÃ§Ã£o, compromisso institucional e previsÃ£o operacional da jornada em uma Ãºnica leitura temporal governada.
          </p>
        </div>

        <button
          type="button"
          className="skpe-refresh-button"
          onClick={() => void loadJourney()}
          disabled={loading}
        >
          <RefreshIcon />
          Atualizar jornada
        </button>
      </section>

      {project && (
        <>
          <section className="skpe-project-context-card">
            <div>
              <span>Projeto estratÃ©gico</span>
              <strong>{project.project_name}</strong>
              <small>{project.project_code}</small>
            </div>

            <div>
              <span>Progresso geral</span>
              <strong>{project.project_progress}%</strong>
              <small>
                SituaÃ§Ã£o: {getProjectStatusLabel(project.project_status)}
              </small>
            </div>

            <div>
              <span>Data de referÃªncia</span>
              <strong>{formatDate(project.reference_date)}</strong>
              <small>{project.organization_timezone}</small>
            </div>
          </section>

          <section className="skpe-admin-kpi-grid" aria-label="Resumo temporal da jornada">
            <article className="skpe-admin-kpi-card">
              <span>Plano institucional</span>
              <strong>
                {temporalSummary.planRow?.current_plan_version_number
                  ? `v${temporalSummary.planRow.current_plan_version_number}`
                  : 'â€”'}
              </strong>
              <small>
                {temporalSummary.planRow
                  ? getPlanKindLabel(temporalSummary.planRow.current_plan_kind)
                  : 'Sem baseline/rebaseline aprovado'}
              </small>
            </article>

            <article className="skpe-admin-kpi-card">
              <span>Forecast operacional</span>
              <strong>
                {temporalSummary.forecastRow?.current_forecast_version_number
                  ? `v${temporalSummary.forecastRow.current_forecast_version_number}`
                  : 'â€”'}
              </strong>
              <small>
                {temporalSummary.forecastRow
                  ? 'PrevisÃ£o operacional ativa'
                  : 'Sem forecast ativo'}
              </small>
            </article>

            <article className="skpe-admin-kpi-card">
              <span>ObrigatÃ³rios em atraso</span>
              <strong>{temporalSummary.overdueCount}</strong>
              <small>
                de {temporalSummary.mandatoryCount} itens obrigatÃ³rios
                {temporalSummary.blockedCount > 0
                  ? ` Â· ${temporalSummary.blockedCount} bloqueados`
                  : ''}
              </small>
            </article>

            <article className="skpe-admin-kpi-card">
              <span>ObrigatÃ³rios sem programaÃ§Ã£o</span>
              <strong>{temporalSummary.unscheduledCount}</strong>
              <small>Estado calculado pelo backend</small>
            </article>
          </section>
        </>
      )}

      {rows.length > 0 && !loading && (
        <div className="skpe-gantt-view-switch" role="group" aria-label="Visualizacao da jornada">
          <button
            type="button"
            className={journeyView === 'structure' ? 'is-active' : ''}
            onClick={() => setJourneyView('structure')}
          >
            Estrutura
          </button>
          <button
            type="button"
            className={journeyView === 'gantt' ? 'is-active' : ''}
            onClick={() => setJourneyView('gantt')}
          >
            Gantt temporal
          </button>
        </div>
      )}

      {errorMessage && (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      )}

      {loading ? (
        <section className="skpe-admin-state-card">
          <p>Carregando a Jornada EstratÃ©gica...</p>
        </section>
      ) : journeyTree.length === 0 ? (
        <section className="skpe-admin-state-card">
          <h2>Nenhuma jornada encontrada</h2>
          <p>Verifique se o projeto estratÃ©gico foi criado para esta organizaÃ§Ã£o.</p>
        </section>
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
      ) : (
        <div className="skpe-journey-workspace">
          <section className="skpe-journey-tree">
            {journeyTree.map((item) => renderJourneyItem(item))}
          </section>

          <aside className="skpe-journey-detail-panel">
            {selectedItem ? (
              <>
                <div className="skpe-journey-breadcrumb">
                  {selectedBreadcrumb.map((breadcrumbItem, index) => (
                    <span key={breadcrumbItem.item_id}>
                      {index > 0 && <b>â€º</b>}
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
                    'NÃ£o hÃ¡ descriÃ§Ã£o complementar cadastrada.'}
                </p>

                <dl className="skpe-journey-detail-list">
                  <div>
                    <dt>SituaÃ§Ã£o da execuÃ§Ã£o</dt>
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
                    <dt>ResponsÃ¡vel</dt>
                    <dd>{selectedItem.responsible_name ?? 'NÃ£o definido'}</dd>
                  </div>
                  <div>
                    <dt>Baseline original</dt>
                    <dd>
                      {selectedItem.baseline_version_number
                        ? `v${selectedItem.baseline_version_number} Â· `
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
                        ? `v${selectedItem.current_plan_version_number} Â· ${getPlanKindLabel(selectedItem.current_plan_kind)} Â· `
                        : ''}
                      {formatPeriod(
                        selectedItem.current_plan_start_date,
                        selectedItem.current_plan_end_date,
                        formatDate,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Forecast operacional</dt>
                    <dd>
                      {selectedItem.current_forecast_version_number
                        ? `v${selectedItem.current_forecast_version_number} Â· `
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
                    <dt>Plano Ã— baseline</dt>
                    <dd>
                      {formatVariance(
                        selectedItem.current_plan_end_variance_vs_baseline_days,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Forecast Ã— plano</dt>
                    <dd>
                      {formatVariance(
                        selectedItem.forecast_end_variance_vs_current_plan_days,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Realizado inÃ­cio Ã— plano</dt>
                    <dd>
                      {formatVariance(
                        selectedItem.actual_start_variance_vs_current_plan_days,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>Realizado fim Ã— plano</dt>
                    <dd>
                      {formatVariance(
                        selectedItem.actual_end_variance_vs_current_plan_days,
                      )}
                    </dd>
                  </div>
                  <div>
                    <dt>ValidaÃ§Ã£o</dt>
                    <dd>
                      {selectedItem.validation_required
                        ? statusLabelPtBr(selectedItem.validation_status)
                        : 'ValidaÃ§Ã£o nÃ£o obrigatÃ³ria'}
                    </dd>
                  </div>
                </dl>

                {(selectedItem.is_start_overdue ||
                  selectedItem.is_completion_overdue) && (
                  <div className="skpe-journey-detail-hint">
                    {selectedItem.is_completion_overdue
                      ? `ConclusÃ£o em atraso hÃ¡ ${selectedItem.days_completion_overdue} dias na data de referÃªncia.`
                      : `InÃ­cio em atraso hÃ¡ ${selectedItem.days_start_overdue} dias na data de referÃªncia.`}
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
                    Clique novamente no cartÃ£o ou no Ã­cone de expansÃ£o para navegar pelos nÃ­veis subordinados.
                  </div>
                )}
              </>
            ) : (
              <div className="skpe-user-detail-empty">
                <JourneyIcon />
                <h2>Selecione um item</h2>
                <p>Consulte seus detalhes e navegue pela estrutura metodolÃ³gica.</p>
              </div>
            )}
          </aside>
        </div>
      )}

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
