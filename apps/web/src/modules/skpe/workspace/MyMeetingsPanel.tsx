import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'
import { platformRoutes } from '../app/skpeRoutes'

import './MyMeetingsPanel.css'

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

type MeetingRole =
  | 'chair'
  | 'secretary'
  | 'chair_and_secretary'
  | 'none'

type MeetingFilter =
  | 'all'
  | 'attention'
  | 'upcoming'
  | 'today'
  | 'in_progress'
  | 'completed'

type MyMeeting = {
  strategy_review_id: string
  organization_id: string
  project_id: string
  formulation_id: string

  formulation_version_number: number
  formulation_version_label: string
  formulation_status: string

  monitoring_cycle_id: string
  cycle_code: string
  cycle_name: string
  cycle_type: CycleType
  cycle_period_start: string
  cycle_period_end: string
  cycle_status: CycleStatus

  code: string
  title: string
  review_type: ReviewType
  status: ReviewStatus

  scheduled_at: string | null
  held_at: string | null

  chair_user_id: string | null
  secretary_user_id: string | null
  current_user_role: MeetingRole

  participants: unknown
  participant_count: number | null

  executive_summary: string | null
  conclusions: string | null
  minutes_reference: string | null

  ratified_at: string | null
  ratified_by: string | null
  is_ratified: boolean

  is_scheduled: boolean
  is_today: boolean
  is_upcoming: boolean
  is_overdue: boolean
  days_until_meeting: number | null

  review_item_count: number
  open_review_item_count: number
  decision_count: number
  open_decision_count: number

  created_at: string
  updated_at: string
}

type MyMeetingsPanelProps = {
  organizationId: string
  projectId: string | null
}

const reviewTypeLabels: Record<ReviewType, string> = {
  rae: 'RAE',
  executive: 'Revisão executiva',
  governance: 'Governança',
  assembly: 'Assembleia',
  extraordinary: 'Reunião extraordinária',
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

const meetingRoleLabels: Record<MeetingRole, string> = {
  chair: 'Presidência da reunião',
  secretary: 'Secretaria da reunião',
  chair_and_secretary: 'Presidência e secretaria',
  none: 'Sem papel pessoal comprovado',
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

function formatMeetingSummary(item: MyMeeting) {
  if (item.status === 'in_progress') return 'Reunião em andamento'

  if (item.is_today) {
    return item.scheduled_at
      ? `Hoje · ${formatDateTime(item.scheduled_at)}`
      : 'Hoje'
  }

  if (item.is_overdue && item.days_until_meeting !== null) {
    const days = Math.abs(item.days_until_meeting)

    return `${days} ${
      days === 1 ? 'dia em atraso' : 'dias em atraso'
    }`
  }

  if (item.days_until_meeting === 1) return 'Amanhã'

  if (
    item.is_upcoming &&
    item.days_until_meeting !== null &&
    item.days_until_meeting > 1
  ) {
    return `Em ${item.days_until_meeting} dias`
  }

  if (item.held_at) {
    return `Realizada em ${formatDateTime(item.held_at)}`
  }

  if (item.scheduled_at) {
    return `Agendada para ${formatDateTime(item.scheduled_at)}`
  }

  return 'Sem agenda informada'
}

function isAttentionMeeting(item: MyMeeting) {
  return (
    item.is_overdue ||
    item.status === 'pending_ratification' ||
    item.open_review_item_count > 0 ||
    item.open_decision_count > 0
  )
}

function isCompletedMeeting(item: MyMeeting) {
  return (
    item.status === 'ratified' ||
    item.status === 'closed' ||
    item.held_at !== null
  )
}

export function MyMeetingsPanel({
  organizationId,
  projectId,
}: MyMeetingsPanelProps) {
  const [items, setItems] = useState<MyMeeting[]>([])
  const [filter, setFilter] = useState<MeetingFilter>('all')
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    async function loadMeetings() {
      setLoading(true)
      setErrorMessage(null)

      const { data, error } = await supabase.rpc(
        'get_my_skpe_meetings',
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
          `Não foi possível carregar suas reuniões: ${translateBackendMessage(error.message)}`,
        )
        setLoading(false)
        return
      }

      setItems((data ?? []) as MyMeeting[])
      setLoading(false)
    }

    void loadMeetings()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const counts = useMemo(
    () => ({
      all: items.length,
      attention: items.filter((item) => isAttentionMeeting(item)).length,
      upcoming: items.filter((item) => item.is_upcoming).length,
      today: items.filter((item) => item.is_today).length,
      in_progress: items.filter((item) => item.status === 'in_progress').length,
      completed: items.filter((item) => isCompletedMeeting(item)).length,
    }),
    [items],
  )

  const visibleItems = useMemo(() => {
    if (filter === 'all') return items

    if (filter === 'attention') {
      return items.filter((item) => isAttentionMeeting(item))
    }

    if (filter === 'upcoming') {
      return items.filter((item) => item.is_upcoming)
    }

    if (filter === 'today') {
      return items.filter((item) => item.is_today)
    }

    if (filter === 'completed') {
      return items.filter((item) => isCompletedMeeting(item))
    }

    return items.filter((item) => item.status === 'in_progress')
  }, [filter, items])

  function openMeeting(item: MyMeeting) {
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
      className="skpe-meetings-panel"
      aria-labelledby="my-meetings-title"
    >
      <div className="skpe-meetings-heading">
        <div>
          <p className="skpe-card-code">Agenda de governança</p>
          <h2 id="my-meetings-title">Reuniões</h2>
          <p>
            Acompanhe reuniões estratégicas nas quais você exerce papel
            comprovado de presidência ou secretaria, incluindo agenda, ciclo,
            itens de análise, decisões e ratificação.
          </p>
        </div>

        {!loading && !errorMessage && (
          <span className="skpe-meetings-total">
            {items.length} {items.length === 1 ? 'reunião' : 'reuniões'}
          </span>
        )}
      </div>

      <div
        className="skpe-meetings-filters"
        aria-label="Filtros de reuniões"
      >
        {(
          [
            ['all', 'Todas'],
            ['attention', 'Atenção'],
            ['upcoming', 'Próximas'],
            ['today', 'Hoje'],
            ['in_progress', 'Em andamento'],
            ['completed', 'Realizadas'],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            className={
              filter === value
                ? 'skpe-meetings-filter skpe-meetings-filter-active'
                : 'skpe-meetings-filter'
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
        <div className="skpe-meetings-state" role="status">
          Carregando suas reuniões...
        </div>
      ) : errorMessage ? (
        <div
          className="skpe-meetings-state skpe-meetings-error"
          role="alert"
        >
          {errorMessage}
        </div>
      ) : visibleItems.length === 0 ? (
        <div className="skpe-meetings-state">
          <strong>Nenhuma reunião encontrada.</strong>
          <span>
            Não existem reuniões em que você exerça presidência ou secretaria
            correspondentes ao filtro selecionado.
          </span>
        </div>
      ) : (
        <div className="skpe-meetings-list">
          {visibleItems.map((item) => (
            <article
              key={item.strategy_review_id}
              className={
                isAttentionMeeting(item)
                  ? 'skpe-meetings-item skpe-meetings-item-attention'
                  : 'skpe-meetings-item'
              }
              role="button"
              tabIndex={0}
              aria-label={`Abrir reunião ${item.code} ${item.title}`}
              onClick={() => openMeeting(item)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault()
                  openMeeting(item)
                }
              }}
            >
              <div className="skpe-meetings-item-main">
                <div className="skpe-meetings-item-labels">
                  <span>{item.code}</span>
                  <span>{reviewTypeLabels[item.review_type]}</span>
                  <span>{meetingRoleLabels[item.current_user_role]}</span>
                  <span>
                    Formulação v{item.formulation_version_number}
                    {item.formulation_version_label
                      ? ` · ${item.formulation_version_label}`
                      : ''}
                  </span>
                </div>

                <h3>{item.title}</h3>

                {item.executive_summary && (
                  <p>{item.executive_summary}</p>
                )}

                <div className="skpe-meetings-governance-grid">
                  <div>
                    <span>Agenda</span>
                    <strong
                      className={
                        item.is_overdue
                          ? 'skpe-meetings-value-alert'
                          : undefined
                      }
                    >
                      {formatMeetingSummary(item)}
                    </strong>
                    <small>
                      {item.scheduled_at
                        ? formatDateTime(item.scheduled_at)
                        : 'Data e horário não informados'}
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

                <div className="skpe-meetings-kpis">
                  <div>
                    <span>Itens da pauta</span>
                    <strong>{item.review_item_count}</strong>
                    <small>
                      {item.open_review_item_count}{' '}
                      {item.open_review_item_count === 1
                        ? 'item aberto'
                        : 'itens abertos'}
                    </small>
                  </div>

                  <div>
                    <span>Decisões</span>
                    <strong>{item.decision_count}</strong>
                    <small>
                      {item.open_decision_count}{' '}
                      {item.open_decision_count === 1
                        ? 'decisão aberta'
                        : 'decisões abertas'}
                    </small>
                  </div>

                  <div>
                    <span>Participantes registrados</span>
                    <strong>
                      {item.participant_count ?? 'Não estruturado'}
                    </strong>
                    <small>
                      Informação exibida sem inferir participação pessoal
                    </small>
                  </div>

                  <div>
                    <span>Período do ciclo</span>
                    <strong>
                      {formatDate(item.cycle_period_start)} a{' '}
                      {formatDate(item.cycle_period_end)}
                    </strong>
                    <small>{cycleTypeLabels[item.cycle_type]}</small>
                  </div>
                </div>

                {item.conclusions && (
                  <div className="skpe-meetings-context">
                    <span>Conclusões registradas</span>
                    <strong>{item.conclusions}</strong>
                  </div>
                )}

                {item.minutes_reference && (
                  <div className="skpe-meetings-context">
                    <span>Referência de ata</span>
                    <strong>{item.minutes_reference}</strong>
                  </div>
                )}

                <div className="skpe-meetings-item-meta">
                  <span>{meetingRoleLabels[item.current_user_role]}</span>
                  <span>
                    Reunião: {reviewStatusLabels[item.status]}
                  </span>
                  <span>
                    Ciclo: {cycleStatusLabels[item.cycle_status]}
                  </span>

                  {item.is_ratified && <span>Ratificada</span>}

                  {item.held_at && (
                    <span>
                      Realizada em {formatDateTime(item.held_at)}
                    </span>
                  )}
                </div>
              </div>

              <div className="skpe-meetings-item-actions">
                <div className="skpe-meetings-status-stack">
                  <span
                    className={`skpe-meetings-status skpe-meetings-status-${item.status}`}
                  >
                    {reviewStatusLabels[item.status]}
                  </span>

                  {item.is_today &&
                    item.status !== 'closed' &&
                    item.status !== 'cancelled' && (
                      <span className="skpe-meetings-today-badge">
                        Hoje
                      </span>
                    )}

                  {isAttentionMeeting(item) && (
                    <span className="skpe-meetings-attention-badge">
                      Atenção
                    </span>
                  )}

                  {item.is_ratified && (
                    <span className="skpe-meetings-ratified-badge">
                      Ratificada
                    </span>
                  )}
                </div>

                <button
                  type="button"
                  className="skpe-card-link-button"
                  onClick={(event) => {
                    event.stopPropagation()
                    openMeeting(item)
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
