import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'
import { platformRoutes } from '../app/skpeRoutes'

import './MyDecisionsPanel.css'

type DecisionStatus =
  | 'open'
  | 'in_progress'
  | 'blocked'
  | 'completed'
  | 'cancelled'
  | 'overdue'

type DecisionPriority = 'low' | 'medium' | 'high' | 'critical'

type DecisionType =
  | 'corrective_action'
  | 'preventive_action'
  | 'resource_allocation'
  | 'reprioritization'
  | 'escalation'
  | 'strategy_review'
  | 'communication'
  | 'other'

type EscalationLevel = 'none' | 'management' | 'board' | 'assembly'

type ReviewType =
  | 'rae'
  | 'executive'
  | 'governance'
  | 'assembly'
  | 'extraordinary'

type ReviewStatus =
  | 'draft'
  | 'scheduled'
  | 'in_progress'
  | 'pending_ratification'
  | 'ratified'
  | 'closed'
  | 'cancelled'

type CycleType =
  | 'monthly'
  | 'quarterly'
  | 'semester'
  | 'annual'
  | 'custom'

type CycleStatus =
  | 'planned'
  | 'open'
  | 'collecting'
  | 'under_review'
  | 'pending_ratification'
  | 'closed'
  | 'cancelled'
  | 'reopened'

type ReviewItemEntityType =
  | 'strategic_theme'
  | 'strategic_objective'
  | 'indicator'
  | 'okr'
  | 'key_result'
  | 'initiative'
  | 'initiative_action'
  | 'initiative_risk'
  | 'initiative_outcome'

type ReviewItemPerformanceStatus =
  | 'not_assessed'
  | 'on_track'
  | 'attention'
  | 'critical'
  | 'achieved'

type ReviewItemFindingType =
  | 'information'
  | 'deviation'
  | 'risk'
  | 'opportunity'
  | 'decision'
  | 'learning'

type ReviewItemStatus = 'open' | 'analyzed' | 'decided' | 'closed'

type DecisionFilter =
  | 'all'
  | 'attention'
  | 'open'
  | 'in_progress'
  | 'blocked'
  | 'completed'

type MyDecision = {
  decision_id: string
  organization_id: string
  project_id: string
  formulation_id: string

  formulation_version_number: number
  formulation_version_label: string
  formulation_status: string

  code: string
  title: string
  decision_text: string
  rationale: string | null
  decision_type: DecisionType
  priority: DecisionPriority
  responsible_user_id: string
  due_date: string | null
  status: DecisionStatus
  escalation_level: EscalationLevel

  days_until_due: number | null
  overdue: boolean
  due_soon: boolean
  blocked: boolean

  completed_at: string | null
  completion_notes: string | null
  ratified_at: string | null
  ratified_by: string | null
  is_ratified: boolean

  strategy_review_id: string
  review_code: string
  review_title: string
  review_type: ReviewType
  review_status: ReviewStatus
  review_scheduled_at: string | null
  review_held_at: string | null
  review_ratified_at: string | null

  monitoring_cycle_id: string
  cycle_code: string
  cycle_name: string
  cycle_type: CycleType
  cycle_period_start: string
  cycle_period_end: string
  cycle_status: CycleStatus

  strategy_review_item_id: string | null
  review_item_entity_type: ReviewItemEntityType | null
  review_item_performance_status: ReviewItemPerformanceStatus | null
  review_item_finding_type: ReviewItemFindingType | null
  review_item_analysis_text: string | null
  review_item_root_cause: string | null
  review_item_recommendation: string | null
  review_item_requires_decision: boolean | null
  review_item_status: ReviewItemStatus | null

  strategic_theme_id: string | null
  strategic_objective_id: string | null
  indicator_id: string | null
  okr_id: string | null
  key_result_id: string | null
  initiative_id: string | null
  initiative_action_id: string | null
  initiative_risk_id: string | null
  initiative_outcome_id: string | null

  linked_initiative_action_id: string | null
  linked_initiative_action_code: string | null
  linked_initiative_action_name: string | null
  linked_initiative_action_status: string | null
  linked_initiative_action_due_date: string | null

  created_at: string
  updated_at: string
}

type MyDecisionsPanelProps = {
  organizationId: string
  projectId: string | null
}

const statusLabels: Record<DecisionStatus, string> = {
  open: 'Aberta',
  in_progress: 'Em andamento',
  blocked: 'Bloqueada',
  completed: 'Concluída',
  cancelled: 'Cancelada',
  overdue: 'Vencida',
}

const priorityLabels: Record<DecisionPriority, string> = {
  low: 'Baixa',
  medium: 'Média',
  high: 'Alta',
  critical: 'Crítica',
}

const decisionTypeLabels: Record<DecisionType, string> = {
  corrective_action: 'Ação corretiva',
  preventive_action: 'Ação preventiva',
  resource_allocation: 'Alocação de recursos',
  reprioritization: 'Repriorização',
  escalation: 'Escalonamento',
  strategy_review: 'Revisão da estratégia',
  communication: 'Comunicação',
  other: 'Outra',
}

const escalationLabels: Record<EscalationLevel, string> = {
  none: 'Sem escalonamento',
  management: 'Gestão',
  board: 'Conselho',
  assembly: 'Assembleia',
}

const reviewTypeLabels: Record<ReviewType, string> = {
  rae: 'RAE',
  executive: 'Revisão executiva',
  governance: 'Governança',
  assembly: 'Assembleia',
  extraordinary: 'Revisão extraordinária',
}

const reviewStatusLabels: Record<ReviewStatus, string> = {
  draft: 'Rascunho',
  scheduled: 'Agendada',
  in_progress: 'Em andamento',
  pending_ratification: 'Pendente de ratificação',
  ratified: 'Ratificada',
  closed: 'Encerrada',
  cancelled: 'Cancelada',
}

const cycleTypeLabels: Record<CycleType, string> = {
  monthly: 'Mensal',
  quarterly: 'Trimestral',
  semester: 'Semestral',
  annual: 'Anual',
  custom: 'Personalizado',
}

const cycleStatusLabels: Record<CycleStatus, string> = {
  planned: 'Planejado',
  open: 'Aberto',
  collecting: 'Em coleta',
  under_review: 'Em análise',
  pending_ratification: 'Pendente de ratificação',
  closed: 'Encerrado',
  cancelled: 'Cancelado',
  reopened: 'Reaberto',
}

const entityTypeLabels: Record<ReviewItemEntityType, string> = {
  strategic_theme: 'Tema Estratégico',
  strategic_objective: 'Objetivo Estratégico — OKRs',
  indicator: 'Indicador',
  okr: 'OKR',
  key_result: 'Resultado-Chave',
  initiative: 'Iniciativa',
  initiative_action: 'Ação de iniciativa',
  initiative_risk: 'Risco de iniciativa',
  initiative_outcome: 'Resultado da iniciativa',
}

const performanceLabels: Record<ReviewItemPerformanceStatus, string> = {
  not_assessed: 'Não avaliado',
  on_track: 'No caminho',
  attention: 'Requer atenção',
  critical: 'Crítico',
  achieved: 'Alcançado',
}

const findingLabels: Record<ReviewItemFindingType, string> = {
  information: 'Informação',
  deviation: 'Desvio',
  risk: 'Risco',
  opportunity: 'Oportunidade',
  decision: 'Decisão',
  learning: 'Aprendizado',
}

function formatDate(value: string | null) {
  if (!value) return 'Não informado'

  const [year, month, day] = value.split('-').map(Number)

  if (!year || !month || !day) return value

  return new Intl.DateTimeFormat('pt-BR').format(
    new Date(year, month - 1, day),
  )
}

function formatDateTime(value: string | null) {
  if (!value) return 'Não informado'

  const date = new Date(value)

  if (Number.isNaN(date.getTime())) return value

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(date)
}

function formatDueSummary(item: MyDecision) {
  if (!item.due_date) return 'Prazo não informado'

  if (item.status === 'completed') {
    return `Concluída · prazo ${formatDate(item.due_date)}`
  }

  if (item.status === 'cancelled') {
    return `Cancelada · prazo ${formatDate(item.due_date)}`
  }

  if (item.overdue && item.days_until_due !== null) {
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

function isAttentionItem(item: MyDecision) {
  return (
    item.overdue ||
    item.blocked ||
    item.due_soon ||
    item.priority === 'critical' ||
    item.priority === 'high' ||
    item.escalation_level !== 'none' ||
    item.review_item_performance_status === 'critical' ||
    item.review_item_performance_status === 'attention'
  )
}

export function MyDecisionsPanel({
  organizationId,
  projectId,
}: MyDecisionsPanelProps) {
  const [items, setItems] = useState<MyDecision[]>([])
  const [filter, setFilter] = useState<DecisionFilter>('all')
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    async function loadDecisions() {
      setLoading(true)
      setErrorMessage(null)

      const { data, error } = await supabase.rpc(
        'get_my_skpe_decisions',
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
          `Não foi possível carregar suas decisões: ${translateBackendMessage(error.message)}`,
        )
        setLoading(false)
        return
      }

      setItems((data ?? []) as MyDecision[])
      setLoading(false)
    }

    void loadDecisions()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const counts = useMemo(
    () => ({
      all: items.length,
      attention: items.filter((item) => isAttentionItem(item)).length,
      open: items.filter((item) => item.status === 'open').length,
      in_progress: items.filter((item) => item.status === 'in_progress').length,
      blocked: items.filter((item) => item.status === 'blocked').length,
      completed: items.filter((item) => item.status === 'completed').length,
    }),
    [items],
  )

  const visibleItems = useMemo(() => {
    if (filter === 'all') return items

    if (filter === 'attention') {
      return items.filter((item) => isAttentionItem(item))
    }

    return items.filter((item) => item.status === filter)
  }, [filter, items])

  function openDecision(item: MyDecision) {
    window.location.assign(
      platformRoutes.skpe({
        organizationId: item.organization_id,
        projectId: item.project_id,
        formulationId: item.formulation_id,
        section: 'governance',
      }),
    )
  }

  return (
    <section
      className="skpe-decisions-panel"
      aria-labelledby="my-decisions-title"
    >
      <div className="skpe-decisions-heading">
        <div>
          <p className="skpe-card-code">Responsabilidades pessoais</p>
          <h2 id="my-decisions-title">Minhas Decisões</h2>
          <p>
            Acompanhe as decisões de governança sob sua responsabilidade,
            incluindo prazo, prioridade, escalonamento, RAE de origem,
            contexto do ciclo e situação de ratificação.
          </p>
        </div>

        {!loading && !errorMessage && (
          <span className="skpe-decisions-total">
            {items.length} {items.length === 1 ? 'decisão' : 'decisões'}
          </span>
        )}
      </div>

      <div
        className="skpe-decisions-filters"
        aria-label="Filtros de decisões"
      >
        {(
          [
            ['all', 'Todas'],
            ['attention', 'Atenção'],
            ['open', 'Abertas'],
            ['in_progress', 'Em andamento'],
            ['blocked', 'Bloqueadas'],
            ['completed', 'Concluídas'],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            className={
              filter === value
                ? 'skpe-decisions-filter skpe-decisions-filter-active'
                : 'skpe-decisions-filter'
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
        <div className="skpe-decisions-state" role="status">
          Carregando suas decisões...
        </div>
      ) : errorMessage ? (
        <div
          className="skpe-decisions-state skpe-decisions-error"
          role="alert"
        >
          {errorMessage}
        </div>
      ) : visibleItems.length === 0 ? (
        <div className="skpe-decisions-state">
          <strong>Nenhuma decisão encontrada.</strong>
          <span>
            Não existem decisões sob sua responsabilidade correspondentes ao
            filtro selecionado.
          </span>
        </div>
      ) : (
        <div className="skpe-decisions-list">
          {visibleItems.map((item) => (
            <article
              key={item.decision_id}
              className={
                isAttentionItem(item)
                  ? 'skpe-decisions-item skpe-decisions-item-attention'
                  : 'skpe-decisions-item'
              }
              role="button"
              tabIndex={0}
              aria-label={`Abrir decisão ${item.code} ${item.title}`}
              onClick={() => openDecision(item)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault()
                  openDecision(item)
                }
              }}
            >
              <div className="skpe-decisions-item-main">
                <div className="skpe-decisions-item-labels">
                  <span>{item.code}</span>
                  <span>{decisionTypeLabels[item.decision_type]}</span>
                  <span>Prioridade {priorityLabels[item.priority]}</span>
                  <span>{escalationLabels[item.escalation_level]}</span>
                  <span>
                    Formulação v{item.formulation_version_number}
                    {item.formulation_version_label
                      ? ` · ${item.formulation_version_label}`
                      : ''}
                  </span>
                </div>

                <h3>{item.title}</h3>
                <p>{item.decision_text}</p>

                {item.rationale && (
                  <div className="skpe-decisions-context">
                    <span>Fundamentação da decisão</span>
                    <strong>{item.rationale}</strong>
                  </div>
                )}

                <div className="skpe-decisions-governance-grid">
                  <div>
                    <span>Revisão estratégica</span>
                    <strong>
                      {item.review_code} · {item.review_title}
                    </strong>
                    <small>
                      {reviewTypeLabels[item.review_type]} ·{' '}
                      {reviewStatusLabels[item.review_status]}
                    </small>
                  </div>

                  <div>
                    <span>Ciclo de monitoramento</span>
                    <strong>
                      {item.cycle_code} · {item.cycle_name}
                    </strong>
                    <small>
                      {cycleTypeLabels[item.cycle_type]} ·{' '}
                      {cycleStatusLabels[item.cycle_status]}
                    </small>
                  </div>
                </div>

                <div className="skpe-decisions-kpis">
                  <div>
                    <span>Prazo</span>
                    <strong
                      className={
                        item.overdue
                          ? 'skpe-decisions-value-alert'
                          : undefined
                      }
                    >
                      {formatDueSummary(item)}
                    </strong>
                    <small>{formatDate(item.due_date)}</small>
                  </div>

                  <div>
                    <span>Período do ciclo</span>
                    <strong>
                      {formatDate(item.cycle_period_start)} a{' '}
                      {formatDate(item.cycle_period_end)}
                    </strong>
                    <small>{cycleTypeLabels[item.cycle_type]}</small>
                  </div>

                  <div>
                    <span>RAE / revisão</span>
                    <strong>
                      {item.review_scheduled_at
                        ? formatDateTime(item.review_scheduled_at)
                        : 'Sem agenda informada'}
                    </strong>
                    <small>
                      {item.review_held_at
                        ? `Realizada em ${formatDateTime(item.review_held_at)}`
                        : 'Realização ainda não registrada'}
                    </small>
                  </div>

                  <div>
                    <span>Ratificação da decisão</span>
                    <strong>
                      {item.is_ratified ? 'Ratificada' : 'Não ratificada'}
                    </strong>
                    <small>
                      {item.ratified_at
                        ? formatDateTime(item.ratified_at)
                        : item.review_ratified_at
                          ? 'RAE ratificada; decisão ainda não ratificada'
                          : 'Depende do fluxo de governança'}
                    </small>
                  </div>
                </div>

                {item.strategy_review_item_id && (
                  <div className="skpe-decisions-review-item">
                    <div className="skpe-decisions-review-item-heading">
                      <span>Item analisado na revisão</span>

                      {item.review_item_entity_type && (
                        <strong>
                          {entityTypeLabels[item.review_item_entity_type]}
                        </strong>
                      )}
                    </div>

                    <div className="skpe-decisions-review-item-meta">
                      {item.review_item_performance_status && (
                        <span>
                          Desempenho:{' '}
                          {
                            performanceLabels[
                              item.review_item_performance_status
                            ]
                          }
                        </span>
                      )}

                      {item.review_item_finding_type && (
                        <span>
                          Achado:{' '}
                          {findingLabels[item.review_item_finding_type]}
                        </span>
                      )}

                      {item.review_item_status && (
                        <span>
                          Item:{' '}
                          {item.review_item_status === 'open'
                            ? 'Aberto'
                            : item.review_item_status === 'analyzed'
                              ? 'Analisado'
                              : item.review_item_status === 'decided'
                                ? 'Decidido'
                                : 'Encerrado'}
                        </span>
                      )}
                    </div>

                    {item.review_item_analysis_text && (
                      <p>{item.review_item_analysis_text}</p>
                    )}

                    {item.review_item_recommendation && (
                      <small>
                        Recomendação: {item.review_item_recommendation}
                      </small>
                    )}
                  </div>
                )}

                {item.linked_initiative_action_id && (
                  <div className="skpe-decisions-linked-action">
                    <span>Ação de iniciativa vinculada</span>
                    <strong>
                      {item.linked_initiative_action_code
                        ? `${item.linked_initiative_action_code} · `
                        : ''}
                      {item.linked_initiative_action_name ??
                        'Ação vinculada'}
                    </strong>
                    <small>
                      Situação:{' '}
                      {item.linked_initiative_action_status ??
                        'Não informada'}
                      {' · '}
                      Prazo:{' '}
                      {formatDate(item.linked_initiative_action_due_date)}
                    </small>
                  </div>
                )}

                {item.status === 'completed' && item.completion_notes && (
                  <div className="skpe-decisions-completion">
                    <span>Registro de conclusão</span>
                    <strong>{item.completion_notes}</strong>

                    {item.completed_at && (
                      <small>
                        Concluída em {formatDateTime(item.completed_at)}
                      </small>
                    )}
                  </div>
                )}

                <div className="skpe-decisions-item-meta">
                  <span>Prioridade: {priorityLabels[item.priority]}</span>
                  <span>{escalationLabels[item.escalation_level]}</span>
                  <span>
                    Revisão: {reviewStatusLabels[item.review_status]}
                  </span>
                  <span>
                    Ciclo: {cycleStatusLabels[item.cycle_status]}
                  </span>

                  {item.due_soon &&
                    !item.overdue &&
                    item.status !== 'completed' &&
                    item.status !== 'cancelled' && (
                      <span>Prazo próximo</span>
                    )}
                </div>
              </div>

              <div className="skpe-decisions-item-actions">
                <div className="skpe-decisions-status-stack">
                  <span
                    className={`skpe-decisions-status skpe-decisions-status-${item.status}`}
                  >
                    {statusLabels[item.status]}
                  </span>

                  {isAttentionItem(item) && (
                    <span className="skpe-decisions-attention-badge">
                      Atenção
                    </span>
                  )}

                  {item.is_ratified && (
                    <span className="skpe-decisions-ratified-badge">
                      Ratificada
                    </span>
                  )}
                </div>

                <button
                  type="button"
                  className="skpe-card-link-button"
                  onClick={(event) => {
                    event.stopPropagation()
                    openDecision(item)
                  }}
                >
                  Abrir governança
                </button>
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  )
}
