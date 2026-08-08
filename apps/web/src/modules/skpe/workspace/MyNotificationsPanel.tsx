import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'
import { platformRoutes } from '../app/skpeRoutes'

import './MyNotificationsPanel.css'

type NotificationPriority =
  | 'low'
  | 'medium'
  | 'high'
  | 'critical'
  | string

type NotificationFilter =
  | 'all'
  | 'unread'
  | 'read'
  | 'attention'
  | 'due_soon'

type WorkspaceNavigationSection =
  | 'journey'
  | 'initiatives'
  | 'governance'
  | 'overview'
  | 'indicators'
  | 'okrs'
  | 'monitoring'

type MyNotification = {
  notification_key: string
  source_type: string
  source_id: string
  organization_id: string
  project_id: string | null
  formulation_id: string | null
  source_code: string | null
  title: string
  description: string | null
  priority: NotificationPriority
  generated_at: string
  due_date: string | null
  overdue: boolean
  due_soon: boolean
  blocked: boolean
  normalized_status: string
  action_recommended: string
  route_section: string
  read_at: string | null
  is_read: boolean
  priority_order: number
}

type MyNotificationsPanelProps = {
  organizationId: string
  projectId: string | null
  onUnreadCountChange?: (count: number) => void
}

const priorityLabels: Record<string, string> = {
  low: 'Baixa',
  medium: 'Média',
  high: 'Alta',
  critical: 'Crítica',
}

const statusLabels: Record<string, string> = {
  overdue: 'Em atraso',
  blocked: 'Bloqueada',
  awaiting_validation: 'Aguardando validação',
  due_soon: 'Vencendo em breve',
  in_progress: 'Em andamento',
  not_started: 'Não iniciada',
}

const sourceTypeLabels: Record<string, string> = {
  journey_item: 'Jornada',
  initiative: 'Iniciativa',
  initiative_action: 'Ação de iniciativa',
  evidence_checklist_item: 'Evidência',
  governance_decision: 'Decisão',
}

function formatDate(value: string | null) {
  if (!value) return 'Sem vencimento'

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

function isAttentionNotification(item: MyNotification) {
  return (
    item.overdue ||
    item.blocked ||
    item.priority === 'critical' ||
    item.priority === 'high'
  )
}

function resolveNavigationSection(
  routeSection: string,
): WorkspaceNavigationSection {
  const allowedSections: WorkspaceNavigationSection[] = [
    'journey',
    'initiatives',
    'governance',
    'overview',
    'indicators',
    'okrs',
    'monitoring',
  ]

  if (
    allowedSections.includes(
      routeSection as WorkspaceNavigationSection,
    )
  ) {
    return routeSection as WorkspaceNavigationSection
  }

  return 'overview'
}

export function MyNotificationsPanel({
  organizationId,
  projectId,
  onUnreadCountChange,
}: MyNotificationsPanelProps) {
  const [items, setItems] = useState<MyNotification[]>([])
  const [filter, setFilter] = useState<NotificationFilter>('all')
  const [loading, setLoading] = useState(true)
  const [busyKey, setBusyKey] = useState<string | null>(null)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    async function loadNotifications() {
      setLoading(true)
      setErrorMessage(null)

      const { data, error } = await supabase.rpc(
        'get_my_skpe_notifications',
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
          `Não foi possível carregar suas notificações: ${translateBackendMessage(error.message)}`,
        )
        setLoading(false)
        return
      }

      setItems((data ?? []) as MyNotification[])
      setLoading(false)
    }

    void loadNotifications()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const counts = useMemo(
    () => ({
      all: items.length,
      unread: items.filter((item) => !item.is_read).length,
      read: items.filter((item) => item.is_read).length,
      attention: items.filter((item) =>
        isAttentionNotification(item),
      ).length,
      due_soon: items.filter((item) => item.due_soon).length,
    }),
    [items],
  )

  useEffect(() => {
    onUnreadCountChange?.(counts.unread)
  }, [counts.unread, onUnreadCountChange])

  const visibleItems = useMemo(() => {
    if (filter === 'all') return items

    if (filter === 'unread') {
      return items.filter((item) => !item.is_read)
    }

    if (filter === 'read') {
      return items.filter((item) => item.is_read)
    }

    if (filter === 'attention') {
      return items.filter((item) =>
        isAttentionNotification(item),
      )
    }

    return items.filter((item) => item.due_soon)
  }, [filter, items])

  function openNotification(item: MyNotification) {
    if (item.project_id && item.formulation_id) {
      window.location.assign(
        platformRoutes.skpe({
          organizationId: item.organization_id,
          projectId: item.project_id,
          formulationId: item.formulation_id,
          section: resolveNavigationSection(item.route_section),
        }),
      )
      return
    }

    window.location.assign(
      platformRoutes.module(item.organization_id, 'SK-PE'),
    )
  }

  async function toggleReadState(item: MyNotification) {
    setBusyKey(item.notification_key)
    setErrorMessage(null)

    const nextIsRead = !item.is_read

    const { data, error } = await supabase.rpc(
      'set_my_skpe_notification_read_state',
      {
        target_organization_id: organizationId,
        target_notification_key: item.notification_key,
        target_is_read: nextIsRead,
      },
    )

    if (error) {
      setErrorMessage(
        `Não foi possível atualizar a notificação: ${translateBackendMessage(error.message)}`,
      )
      setBusyKey(null)
      return
    }

    const savedState = Array.isArray(data) ? data[0] : null

    setItems((currentItems) =>
      currentItems.map((currentItem) =>
        currentItem.notification_key === item.notification_key
          ? {
              ...currentItem,
              read_at:
                savedState?.read_at ??
                (nextIsRead ? new Date().toISOString() : null),
              is_read: savedState?.is_read ?? nextIsRead,
            }
          : currentItem,
      ),
    )

    setBusyKey(null)
  }

  return (
    <section
      id="my-notifications-panel"
      className="skpe-notifications-panel"
      aria-labelledby="my-notifications-title"
    >
      <div className="skpe-notifications-heading">
        <div>
          <p className="skpe-card-code">Central pessoal</p>
          <h2 id="my-notifications-title">Notificações</h2>
          <p>
            Acompanhe alertas derivados das suas pendências reais no SK-PE,
            com prioridade, vencimento, vínculo com o item e ação recomendada.
          </p>
        </div>

        {!loading && !errorMessage && (
          <span className="skpe-notifications-total">
            {counts.unread}{' '}
            {counts.unread === 1 ? 'não lida' : 'não lidas'}
          </span>
        )}
      </div>

      <div
        className="skpe-notifications-filters"
        aria-label="Filtros de notificações"
      >
        {(
          [
            ['all', 'Todas'],
            ['unread', 'Não lidas'],
            ['read', 'Lidas'],
            ['attention', 'Atenção'],
            ['due_soon', 'Vencendo'],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            className={
              filter === value
                ? 'skpe-notifications-filter skpe-notifications-filter-active'
                : 'skpe-notifications-filter'
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
        <div className="skpe-notifications-state" role="status">
          Carregando suas notificações...
        </div>
      ) : errorMessage ? (
        <div
          className="skpe-notifications-state skpe-notifications-error"
          role="alert"
        >
          {errorMessage}
        </div>
      ) : visibleItems.length === 0 ? (
        <div className="skpe-notifications-state">
          <strong>Nenhuma notificação encontrada.</strong>
          <span>
            Não existem notificações correspondentes ao filtro selecionado.
          </span>
        </div>
      ) : (
        <div className="skpe-notifications-list">
          {visibleItems.map((item) => (
            <article
              key={item.notification_key}
              className={[
                'skpe-notifications-item',
                !item.is_read
                  ? 'skpe-notifications-item-unread'
                  : '',
                isAttentionNotification(item)
                  ? 'skpe-notifications-item-attention'
                  : '',
              ]
                .filter(Boolean)
                .join(' ')}
              role="button"
              tabIndex={0}
              aria-label={`Abrir notificação ${item.source_code ?? ''} ${item.title}`}
              onClick={() => openNotification(item)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault()
                  openNotification(item)
                }
              }}
            >
              <div className="skpe-notifications-item-main">
                <div className="skpe-notifications-item-labels">
                  {item.source_code && <span>{item.source_code}</span>}
                  <span>
                    {sourceTypeLabels[item.source_type] ??
                      item.source_type}
                  </span>
                  <span>
                    Prioridade:{' '}
                    {priorityLabels[item.priority] ?? item.priority}
                  </span>
                  <span>{item.is_read ? 'Lida' : 'Não lida'}</span>
                </div>

                <h3>{item.title}</h3>

                {item.description && <p>{item.description}</p>}

                <div className="skpe-notifications-context-grid">
                  <div>
                    <span>Gerada em</span>
                    <strong>{formatDateTime(item.generated_at)}</strong>
                  </div>

                  <div>
                    <span>Vencimento</span>
                    <strong
                      className={
                        item.overdue
                          ? 'skpe-notifications-value-alert'
                          : undefined
                      }
                    >
                      {formatDate(item.due_date)}
                    </strong>
                  </div>

                  <div>
                    <span>Situação</span>
                    <strong>
                      {statusLabels[item.normalized_status] ??
                        item.normalized_status}
                    </strong>
                  </div>

                  <div>
                    <span>Vínculo</span>
                    <strong>
                      {sourceTypeLabels[item.source_type] ??
                        item.source_type}
                    </strong>
                  </div>
                </div>

                <div className="skpe-notifications-action">
                  <span>Ação recomendada</span>
                  <strong>{item.action_recommended}</strong>
                </div>

                <div className="skpe-notifications-item-meta">
                  {item.blocked && <span>Bloqueada</span>}
                  {item.overdue && <span>Em atraso</span>}
                  {item.due_soon && <span>Vencendo em breve</span>}
                  {item.read_at && (
                    <span>
                      Lida em {formatDateTime(item.read_at)}
                    </span>
                  )}
                </div>
              </div>

              <div className="skpe-notifications-item-actions">
                <div className="skpe-notifications-status-stack">
                  <span
                    className={`skpe-notifications-priority skpe-notifications-priority-${item.priority}`}
                  >
                    {priorityLabels[item.priority] ?? item.priority}
                  </span>

                  {!item.is_read && (
                    <span className="skpe-notifications-unread-badge">
                      Nova
                    </span>
                  )}

                  {isAttentionNotification(item) && (
                    <span className="skpe-notifications-attention-badge">
                      Atenção
                    </span>
                  )}
                </div>

                <div className="skpe-notifications-buttons">
                  <button
                    type="button"
                    className="skpe-secondary-button"
                    disabled={busyKey === item.notification_key}
                    onClick={(event) => {
                      event.stopPropagation()
                      void toggleReadState(item)
                    }}
                  >
                    {busyKey === item.notification_key
                      ? 'Atualizando...'
                      : item.is_read
                        ? 'Marcar como não lida'
                        : 'Marcar como lida'}
                  </button>

                  <button
                    type="button"
                    className="skpe-card-link-button"
                    onClick={(event) => {
                      event.stopPropagation()
                      openNotification(item)
                    }}
                  >
                    Abrir item
                  </button>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  )
}
