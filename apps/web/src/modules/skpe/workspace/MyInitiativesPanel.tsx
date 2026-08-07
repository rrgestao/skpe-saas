import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'
import { platformRoutes } from '../app/skpeRoutes'

import './MyInitiativesPanel.css'

type InitiativeStatus =
  | 'proposed'
  | 'under_analysis'
  | 'approved'
  | 'planned'
  | 'in_progress'
  | 'on_hold'
  | 'blocked'
  | 'completed'

type InitiativePriority = 'low' | 'medium' | 'high' | 'critical'

type InitiativeCriticality = 'low' | 'medium' | 'high' | 'critical'

type InitiativeHealthStatus =
  | 'not_assessed'
  | 'on_track'
  | 'attention'
  | 'critical'
  | 'completed'

type InitiativeRiskLevel =
  | 'not_assessed'
  | 'low'
  | 'medium'
  | 'high'
  | 'critical'

type InitiativeClass =
  | 'initiative'
  | 'program'
  | 'project'
  | 'structuring_action'

type InitiativeType =
  | 'strategic_project'
  | 'operational_improvement'
  | 'process_initiative'
  | 'simple_action'
  | 'strategic_program'

type ResponsibilityRole = 'owner' | 'backup_owner' | 'sponsor' | 'related'

type InitiativeFilter =
  | 'all'
  | 'attention'
  | 'in_progress'
  | 'planned'
  | 'completed'

type StrategicLink = {
  id: string
  code: string
  name: string
  contributionType?: string | null
  contributionWeight?: number | null
  notes?: string | null
}

type KeyResultLink = {
  id: string
  code: string
  name: string
  okrId?: string | null
  contributionType?: string | null
  contributionWeight?: number | null
  notes?: string | null
}

type MyInitiative = {
  initiative_id: string
  organization_id: string
  project_id: string
  formulation_id: string | null
  formulation_version_number: number | null
  formulation_version_label: string | null
  formulation_status: string | null
  portfolio_item_id: string | null

  code: string
  name: string
  description: string | null
  initiative_type: InitiativeType
  initiative_class: InitiativeClass

  responsibility_role: ResponsibilityRole

  status: InitiativeStatus
  priority: InitiativePriority
  criticality: InitiativeCriticality
  health_status: InitiativeHealthStatus
  risk_level: InitiativeRiskLevel
  progress: number

  strategic_problem: string | null
  strategic_rationale: string | null
  strategic_theme: string | null

  owner_user_id: string | null
  backup_owner_user_id: string | null
  sponsor_user_id: string | null
  responsible_area_id: string | null
  responsible_area: string | null

  start_date: string | null
  due_date: string | null
  completed_at: string | null
  days_until_due: number | null
  is_overdue: boolean

  planned_cost: number | null
  actual_cost: number | null
  cost_variance: number | null
  planned_benefit: number | null
  realized_benefit: number | null
  estimated_effort: number | null
  effort_unit: string | null
  resource_estimate: string | null
  constraints_text: string | null
  currency_code: string | null
  estimate_confidence: string | null

  proposal_origin: string | null
  proposal_source_reference: string | null
  validation_status: string | null

  what_text: string | null
  why_text: string | null
  where_text: string | null
  when_text: string | null
  who_text: string | null
  how_text: string | null
  how_much_text: string | null
  five_w_two_h_completed_fields: number
  five_w_two_h_completeness: number
  five_w_two_h_complete: boolean

  portfolio_selection_status: string | null
  portfolio_priority: string | null
  portfolio_rank_position: number | null
  portfolio_total_score: number | null
  portfolio_risk_assessment_status: string | null
  portfolio_dependency_assessment_status: string | null
  portfolio_capacity_assessment_status: string | null

  strategic_objectives: StrategicLink[] | null
  key_results: KeyResultLink[] | null

  action_count: number
  open_action_count: number
  overdue_action_count: number
  milestone_count: number
  completed_milestone_count: number

  next_action_id: string | null
  next_action_code: string | null
  next_action_name: string | null
  next_action_due_date: string | null
  next_action_status: string | null

  open_risk_count: number
  high_critical_risk_count: number
  maximum_inherent_risk_score: number | null

  outcome_count: number
  achieved_outcome_count: number

  last_update_at: string | null
  updated_at: string
}

type MyInitiativesPanelProps = {
  organizationId: string
  projectId: string | null
}

const statusLabels: Record<InitiativeStatus, string> = {
  proposed: 'Proposta',
  under_analysis: 'Em análise',
  approved: 'Aprovada',
  planned: 'Planejada',
  in_progress: 'Em andamento',
  on_hold: 'Em espera',
  blocked: 'Bloqueada',
  completed: 'Concluída',
}

const priorityLabels: Record<InitiativePriority, string> = {
  low: 'Baixa',
  medium: 'Média',
  high: 'Alta',
  critical: 'Crítica',
}

const criticalityLabels: Record<InitiativeCriticality, string> = {
  low: 'Baixa',
  medium: 'Média',
  high: 'Alta',
  critical: 'Crítica',
}

const healthLabels: Record<InitiativeHealthStatus, string> = {
  not_assessed: 'Saúde não avaliada',
  on_track: 'No caminho',
  attention: 'Requer atenção',
  critical: 'Situação crítica',
  completed: 'Concluída',
}

const riskLabels: Record<InitiativeRiskLevel, string> = {
  not_assessed: 'Risco não avaliado',
  low: 'Risco baixo',
  medium: 'Risco médio',
  high: 'Risco alto',
  critical: 'Risco crítico',
}

const roleLabels: Record<ResponsibilityRole, string> = {
  owner: 'Responsável principal',
  backup_owner: 'Responsável substituto',
  sponsor: 'Patrocinador',
  related: 'Relacionado',
}

const classLabels: Record<InitiativeClass, string> = {
  initiative: 'Iniciativa',
  program: 'Programa',
  project: 'Projeto',
  structuring_action: 'Ação estruturante',
}

const typeLabels: Record<InitiativeType, string> = {
  strategic_project: 'Projeto estratégico',
  operational_improvement: 'Melhoria operacional',
  process_initiative: 'Iniciativa de processo',
  simple_action: 'Ação simples',
  strategic_program: 'Programa estratégico',
}

function formatDate(value: string | null) {
  if (!value) return 'Não informado'

  const [year, month, day] = value.split('-').map(Number)

  if (!year || !month || !day) return value

  return new Intl.DateTimeFormat('pt-BR').format(
    new Date(year, month - 1, day),
  )
}

function formatPercentage(value: number | null) {
  if (value === null || value === undefined) return '0%'

  return `${new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 1,
  }).format(value)}%`
}

function formatNumber(value: number | null) {
  if (value === null || value === undefined) return 'Não informado'

  return new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 2,
  }).format(value)
}

function formatCurrency(value: number | null, currencyCode: string | null) {
  if (value === null || value === undefined) return 'Não informado'

  try {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: currencyCode || 'BRL',
      maximumFractionDigits: 2,
    }).format(value)
  } catch {
    return formatNumber(value)
  }
}

function formatEffort(value: number | null, unit: string | null) {
  if (value === null || value === undefined) return 'Não informado'

  const unitLabels: Record<string, string> = {
    hours: 'h',
    days: 'dias',
    weeks: 'semanas',
    months: 'meses',
    points: 'pontos',
    custom: '',
  }

  const formatted = formatNumber(value)
  const unitLabel = unit ? (unitLabels[unit] ?? unit) : ''

  return unitLabel ? `${formatted} ${unitLabel}` : formatted
}

function formatDueSummary(item: MyInitiative) {
  if (!item.due_date) return 'Prazo não informado'
  if (item.status === 'completed') return `Concluída · ${formatDate(item.due_date)}`

  if (item.is_overdue && item.days_until_due !== null) {
    const days = Math.abs(item.days_until_due)

    return `${days} ${days === 1 ? 'dia' : 'dias'} em atraso`
  }

  if (item.days_until_due === 0) return 'Vence hoje'

  if (item.days_until_due !== null && item.days_until_due > 0) {
    return `${item.days_until_due} ${
      item.days_until_due === 1 ? 'dia restante' : 'dias restantes'
    }`
  }

  return `Prazo: ${formatDate(item.due_date)}`
}

function isAttentionItem(item: MyInitiative) {
  return (
    item.health_status === 'critical' ||
    item.health_status === 'attention' ||
    item.risk_level === 'critical' ||
    item.risk_level === 'high' ||
    item.status === 'blocked' ||
    item.is_overdue ||
    item.overdue_action_count > 0 ||
    item.high_critical_risk_count > 0
  )
}

function isPlannedItem(item: MyInitiative) {
  return (
    item.status === 'proposed' ||
    item.status === 'under_analysis' ||
    item.status === 'approved' ||
    item.status === 'planned'
  )
}

function getStrategicSummary(item: MyInitiative) {
  const objectives = item.strategic_objectives ?? []
  const keyResults = item.key_results ?? []

  return {
    objectives,
    keyResults,
    objectiveText:
      objectives.length > 0
        ? objectives
            .slice(0, 2)
            .map((objective) => `${objective.code} · ${objective.name}`)
            .join(' • ')
        : null,
    keyResultText:
      keyResults.length > 0
        ? keyResults
            .slice(0, 2)
            .map((keyResult) => `${keyResult.code} · ${keyResult.name}`)
            .join(' • ')
        : null,
  }
}

export function MyInitiativesPanel({
  organizationId,
  projectId,
}: MyInitiativesPanelProps) {
  const [items, setItems] = useState<MyInitiative[]>([])
  const [filter, setFilter] = useState<InitiativeFilter>('all')
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    async function loadInitiatives() {
      setLoading(true)
      setErrorMessage(null)

      const { data, error } = await supabase.rpc(
        'get_my_skpe_initiatives',
        {
          target_organization_id: organizationId,
          target_project_id: projectId,
          target_formulation_id: null,
        },
      )

      if (!active) return

      if (error) {
        setItems([])
        setErrorMessage(
          `Não foi possível carregar suas Iniciativas: ${translateBackendMessage(error.message)}`,
        )
        setLoading(false)
        return
      }

      setItems((data ?? []) as MyInitiative[])
      setLoading(false)
    }

    void loadInitiatives()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const counts = useMemo(
    () => ({
      all: items.length,
      attention: items.filter((item) => isAttentionItem(item)).length,
      in_progress: items.filter((item) => item.status === 'in_progress').length,
      planned: items.filter((item) => isPlannedItem(item)).length,
      completed: items.filter((item) => item.status === 'completed').length,
    }),
    [items],
  )

  const visibleItems = useMemo(() => {
    if (filter === 'all') return items

    if (filter === 'attention') {
      return items.filter((item) => isAttentionItem(item))
    }

    if (filter === 'planned') {
      return items.filter((item) => isPlannedItem(item))
    }

    return items.filter((item) => item.status === filter)
  }, [filter, items])

  function openInitiative(item: MyInitiative) {
    if (!item.formulation_id) return

    window.location.assign(
      platformRoutes.skpe({
        organizationId: item.organization_id,
        projectId: item.project_id,
        formulationId: item.formulation_id,
        section: 'initiatives',
      }),
    )
  }

  return (
    <section
      className="skpe-initiatives-panel"
      aria-labelledby="my-initiatives-title"
    >
      <div className="skpe-initiatives-heading">
        <div>
          <p className="skpe-card-code">Responsabilidades pessoais</p>
          <h2 id="my-initiatives-title">Minhas Iniciativas</h2>
          <p>
            Visão gerencial das iniciativas em que você atua como responsável,
            substituto ou patrocinador, com progresso, prazo, saúde, riscos,
            execução e vínculos estratégicos.
          </p>
        </div>

        {!loading && !errorMessage && (
          <span className="skpe-initiatives-total">
            {items.length}{' '}
            {items.length === 1 ? 'iniciativa' : 'iniciativas'}
          </span>
        )}
      </div>

      <div
        className="skpe-initiatives-filters"
        aria-label="Filtros de Iniciativas"
      >
        {(
          [
            ['all', 'Todas'],
            ['attention', 'Atenção'],
            ['in_progress', 'Em andamento'],
            ['planned', 'Planejadas'],
            ['completed', 'Concluídas'],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            className={
              filter === value
                ? 'skpe-initiatives-filter skpe-initiatives-filter-active'
                : 'skpe-initiatives-filter'
            }
            aria-pressed={filter === value}
            onClick={() => setFilter(value)}
          >
            {label}
            <span>{counts[value]}</span>
          </button>
        ))}
      </div>

      {loading ? (
        <div className="skpe-initiatives-state" role="status">
          Carregando suas Iniciativas...
        </div>
      ) : errorMessage ? (
        <div
          className="skpe-initiatives-state skpe-initiatives-error"
          role="alert"
        >
          {errorMessage}
        </div>
      ) : visibleItems.length === 0 ? (
        <div className="skpe-initiatives-state">
          <strong>Nenhuma Iniciativa encontrada.</strong>
          <span>
            Não existem iniciativas relacionadas a você correspondentes ao
            filtro selecionado.
          </span>
        </div>
      ) : (
        <div className="skpe-initiatives-list">
          {visibleItems.map((item) => {
            const progress = Math.max(0, Math.min(100, item.progress ?? 0))
            const canOpen = Boolean(item.formulation_id)
            const strategic = getStrategicSummary(item)
            const milestoneProgress =
              item.milestone_count > 0
                ? (item.completed_milestone_count / item.milestone_count) * 100
                : null
            const outcomeProgress =
              item.outcome_count > 0
                ? (item.achieved_outcome_count / item.outcome_count) * 100
                : null

            return (
              <article
                key={item.initiative_id}
                className={
                  isAttentionItem(item)
                    ? 'skpe-initiatives-item skpe-initiatives-item-attention'
                    : 'skpe-initiatives-item'
                }
                role={canOpen ? 'button' : undefined}
                tabIndex={canOpen ? 0 : undefined}
                aria-label={
                  canOpen
                    ? `Abrir iniciativa ${item.code} ${item.name}`
                    : undefined
                }
                onClick={() => {
                  if (canOpen) openInitiative(item)
                }}
                onKeyDown={(event) => {
                  if (
                    canOpen &&
                    (event.key === 'Enter' || event.key === ' ')
                  ) {
                    event.preventDefault()
                    openInitiative(item)
                  }
                }}
              >
                <div className="skpe-initiatives-item-main">
                  <div className="skpe-initiatives-item-labels">
                    <span>{item.code}</span>
                    <span>{classLabels[item.initiative_class]}</span>
                    <span>{typeLabels[item.initiative_type]}</span>
                    <span>{roleLabels[item.responsibility_role]}</span>

                    {item.formulation_version_number !== null && (
                      <span>
                        Formulação v{item.formulation_version_number}
                        {item.formulation_version_label
                          ? ` · ${item.formulation_version_label}`
                          : ''}
                      </span>
                    )}
                  </div>

                  <h3>{item.name}</h3>

                  {item.description && <p>{item.description}</p>}

                  {item.strategic_problem && (
                    <div className="skpe-initiatives-context">
                      <span>Problema, oportunidade ou necessidade</span>
                      <strong>{item.strategic_problem}</strong>
                    </div>
                  )}

                  {(strategic.objectiveText || strategic.keyResultText) && (
                    <div className="skpe-initiatives-strategy">
                      {strategic.objectiveText && (
                        <div>
                          <span>Objetivos Estratégicos — OKRs</span>
                          <strong>{strategic.objectiveText}</strong>

                          {strategic.objectives.length > 2 && (
                            <small>
                              + {strategic.objectives.length - 2}{' '}
                              {strategic.objectives.length - 2 === 1
                                ? 'objetivo vinculado'
                                : 'objetivos vinculados'}
                            </small>
                          )}
                        </div>
                      )}

                      {strategic.keyResultText && (
                        <div>
                          <span>Resultados-Chave relacionados</span>
                          <strong>{strategic.keyResultText}</strong>

                          {strategic.keyResults.length > 2 && (
                            <small>
                              + {strategic.keyResults.length - 2}{' '}
                              {strategic.keyResults.length - 2 === 1
                                ? 'KR vinculado'
                                : 'KRs vinculados'}
                            </small>
                          )}
                        </div>
                      )}
                    </div>
                  )}

                  <div className="skpe-initiatives-progress">
                    <div className="skpe-initiatives-progress-heading">
                      <span>Progresso da iniciativa</span>
                      <strong>{formatPercentage(progress)}</strong>
                    </div>

                    <div
                      className="skpe-initiatives-progress-track"
                      role="progressbar"
                      aria-label={`Progresso de ${item.name}`}
                      aria-valuemin={0}
                      aria-valuemax={100}
                      aria-valuenow={progress}
                    >
                      <span
                        className="skpe-initiatives-progress-value"
                        style={{ width: `${progress}%` }}
                      />
                    </div>
                  </div>

                  <div className="skpe-initiatives-kpis">
                    <div>
                      <span>Prazo</span>
                      <strong
                        className={
                          item.is_overdue
                            ? 'skpe-initiatives-value-alert'
                            : undefined
                        }
                      >
                        {formatDueSummary(item)}
                      </strong>
                      <small>{formatDate(item.due_date)}</small>
                    </div>

                    <div>
                      <span>Ações abertas</span>
                      <strong>{item.open_action_count}</strong>
                      <small>
                        {item.overdue_action_count > 0
                          ? `${item.overdue_action_count} em atraso`
                          : `${item.action_count} no total`}
                      </small>
                    </div>

                    <div>
                      <span>Marcos</span>
                      <strong>
                        {item.completed_milestone_count}/{item.milestone_count}
                      </strong>
                      <small>
                        {milestoneProgress === null
                          ? 'Sem marcos cadastrados'
                          : `${formatPercentage(milestoneProgress)} concluídos`}
                      </small>
                    </div>

                    <div>
                      <span>Riscos abertos</span>
                      <strong>{item.open_risk_count}</strong>
                      <small>
                        {item.high_critical_risk_count > 0
                          ? `${item.high_critical_risk_count} de alta criticidade`
                          : 'Sem risco crítico aberto'}
                      </small>
                    </div>

                    <div>
                      <span>Resultados</span>
                      <strong>
                        {item.achieved_outcome_count}/{item.outcome_count}
                      </strong>
                      <small>
                        {outcomeProgress === null
                          ? 'Sem resultados cadastrados'
                          : `${formatPercentage(outcomeProgress)} alcançados`}
                      </small>
                    </div>

                    <div>
                      <span>5W2H</span>
                      <strong>
                        {item.five_w_two_h_completed_fields}/7
                      </strong>
                      <small>
                        {item.five_w_two_h_complete
                          ? 'Descrição estruturada completa'
                          : `${formatPercentage(
                              item.five_w_two_h_completeness,
                            )} preenchido`}
                      </small>
                    </div>
                  </div>

                  {item.next_action_name && (
                    <div className="skpe-initiatives-next-action">
                      <span>Próxima ação ou marco</span>
                      <strong>
                        {item.next_action_code
                          ? `${item.next_action_code} · `
                          : ''}
                        {item.next_action_name}
                      </strong>
                      <small>
                        Prazo: {formatDate(item.next_action_due_date)}
                      </small>
                    </div>
                  )}

                  <div className="skpe-initiatives-financial">
                    <div>
                      <span>Custo planejado</span>
                      <strong>
                        {formatCurrency(
                          item.planned_cost,
                          item.currency_code,
                        )}
                      </strong>
                    </div>

                    <div>
                      <span>Custo realizado</span>
                      <strong>
                        {formatCurrency(
                          item.actual_cost,
                          item.currency_code,
                        )}
                      </strong>
                    </div>

                    <div>
                      <span>Benefício planejado</span>
                      <strong>
                        {formatCurrency(
                          item.planned_benefit,
                          item.currency_code,
                        )}
                      </strong>
                    </div>

                    <div>
                      <span>Esforço estimado</span>
                      <strong>
                        {formatEffort(
                          item.estimated_effort,
                          item.effort_unit,
                        )}
                      </strong>
                    </div>
                  </div>

                  <div className="skpe-initiatives-item-meta">
                    <span>Prioridade: {priorityLabels[item.priority]}</span>
                    <span>
                      Criticidade: {criticalityLabels[item.criticality]}
                    </span>
                    <span>{healthLabels[item.health_status]}</span>
                    <span>{riskLabels[item.risk_level]}</span>

                    {item.responsible_area && (
                      <span>Área: {item.responsible_area}</span>
                    )}

                    {item.portfolio_rank_position !== null && (
                      <span>
                        Posição no portfólio: {item.portfolio_rank_position}
                      </span>
                    )}

                    {item.portfolio_total_score !== null && (
                      <span>
                        Score do portfólio:{' '}
                        {formatNumber(item.portfolio_total_score)}
                      </span>
                    )}
                  </div>

                  {!canOpen && (
                    <div className="skpe-initiatives-origin-warning">
                      Esta iniciativa ainda não possui Formulação Estratégica
                      vinculada para abertura no contexto operacional.
                    </div>
                  )}
                </div>

                <div className="skpe-initiatives-item-actions">
                  <div className="skpe-initiatives-status-stack">
                    <span
                      className={`skpe-initiatives-status skpe-initiatives-status-${item.status}`}
                    >
                      {statusLabels[item.status]}
                    </span>

                    {isAttentionItem(item) && (
                      <span className="skpe-initiatives-attention-badge">
                        Atenção
                      </span>
                    )}
                  </div>

                  <button
                    type="button"
                    className="skpe-card-link-button"
                    disabled={!canOpen}
                    onClick={(event) => {
                      event.stopPropagation()
                      openInitiative(item)
                    }}
                  >
                    Abrir iniciativa
                  </button>
                </div>
              </article>
            )
          })}
        </div>
      )}
    </section>
  )
}
