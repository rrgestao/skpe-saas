import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'

import './MyPendingItemsPanel.css'

type PendingNavigationSection =
  | 'journey'
  | 'initiatives'
  | 'governance'

type PendingSourceType =
  | 'journey_item'
  | 'initiative'
  | 'initiative_action'
  | 'evidence_checklist_item'
  | 'governance_decision'

type PendingNormalizedStatus =
  | 'overdue'
  | 'blocked'
  | 'awaiting_validation'
  | 'due_soon'
  | 'in_progress'
  | 'not_started'

type PendingItem = {
  pending_id: string
  source_type: PendingSourceType
  source_id: string
  organization_id: string
  project_id: string
  formulation_id: string | null
  source_code: string | null
  title: string
  description: string | null
  responsibility_type: string
  original_status: string
  normalized_status: PendingNormalizedStatus
  priority: string
  due_date: string | null
  overdue: boolean
  due_soon: boolean
  blocked: boolean
  blocking_reason: string | null
  route_section: PendingNavigationSection
  updated_at: string
  priority_order: number
}

type PendingFilter =
  | 'all'
  | 'overdue'
  | 'blocked'
  | 'due_soon'
  | 'in_progress'

type MyPendingItemsPanelProps = {
  organizationId: string
  projectId: string | null
  onNavigate: (section: PendingNavigationSection) => void
}

const statusLabels: Record<PendingNormalizedStatus, string> = {
  overdue: 'Em atraso',
  blocked: 'Bloqueada',
  awaiting_validation: 'Aguardando validação',
  due_soon: 'Próxima do prazo',
  in_progress: 'Em andamento',
  not_started: 'Não iniciada',
}

const sourceLabels: Record<PendingSourceType, string> = {
  journey_item: 'Jornada Estratégica',
  initiative: 'Iniciativa',
  initiative_action: 'Ação de iniciativa',
  evidence_checklist_item: 'Evidência',
  governance_decision: 'Decisão de governança',
}

const responsibilityLabels: Record<string, string> = {
  responsible: 'Responsável',
  backup_responsible: 'Responsável substituto',
  owner: 'Proprietário',
}

function formatDate(value: string | null) {
  if (!value) return 'Sem prazo definido'

  const [year, month, day] = value.split('-').map(Number)

  if (!year || !month || !day) return value

  return new Intl.DateTimeFormat('pt-BR').format(
    new Date(year, month - 1, day),
  )
}

function priorityLabel(value: string) {
  const labels: Record<string, string> = {
    low: 'Baixa',
    medium: 'Média',
    high: 'Alta',
    critical: 'Crítica',
  }

  return labels[value] ?? 'Não classificada'
}

export function MyPendingItemsPanel({
  organizationId,
  projectId,
  onNavigate,
}: MyPendingItemsPanelProps) {
  const [items, setItems] = useState<PendingItem[]>([])
  const [filter, setFilter] = useState<PendingFilter>('all')
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    async function loadPendingItems() {
      setLoading(true)
      setErrorMessage(null)

      const { data, error } = await supabase.rpc(
        'get_my_skpe_pending_items',
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
          `Não foi possível carregar suas pendências: ${translateBackendMessage(error.message)}`,
        )
        setLoading(false)
        return
      }

      setItems((data ?? []) as PendingItem[])
      setLoading(false)
    }

    void loadPendingItems()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const counts = useMemo(
    () => ({
      all: items.length,
      overdue: items.filter((item) => item.overdue).length,
      blocked: items.filter((item) => item.blocked).length,
      due_soon: items.filter((item) => item.due_soon).length,
      in_progress: items.filter(
        (item) => item.normalized_status === 'in_progress',
      ).length,
    }),
    [items],
  )

  const visibleItems = useMemo(() => {
    if (filter === 'all') return items
    if (filter === 'overdue') return items.filter((item) => item.overdue)
    if (filter === 'blocked') return items.filter((item) => item.blocked)
    if (filter === 'due_soon') return items.filter((item) => item.due_soon)

    return items.filter(
      (item) => item.normalized_status === 'in_progress',
    )
  }, [filter, items])

  return (
    <section
      className="skpe-pending-panel"
      aria-labelledby="my-pending-items-title"
    >
      <div className="skpe-pending-heading">
        <div>
          <p className="skpe-card-code">Responsabilidades pessoais</p>
          <h2 id="my-pending-items-title">Minhas Pendências</h2>
          <p>
            Itens atribuídos a você no contexto atual, organizados por
            urgência, bloqueios e prazos.
          </p>
        </div>

        {!loading && !errorMessage && (
          <span className="skpe-pending-total">
            {items.length} {items.length === 1 ? 'pendência' : 'pendências'}
          </span>
        )}
      </div>

      <div
        className="skpe-pending-filters"
        aria-label="Filtros de pendências"
      >
        {(
          [
            ['all', 'Todas'],
            ['overdue', 'Em atraso'],
            ['blocked', 'Bloqueadas'],
            ['due_soon', 'Próximas do prazo'],
            ['in_progress', 'Em andamento'],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            className={
              filter === value
                ? 'skpe-pending-filter skpe-pending-filter-active'
                : 'skpe-pending-filter'
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
        <div className="skpe-pending-state" role="status">
          Carregando suas pendências...
        </div>
      ) : errorMessage ? (
        <div className="skpe-pending-state skpe-pending-error" role="alert">
          {errorMessage}
        </div>
      ) : visibleItems.length === 0 ? (
        <div className="skpe-pending-state">
          <strong>Nenhuma pendência encontrada.</strong>
          <span>
            Não existem itens correspondentes ao filtro selecionado.
          </span>
        </div>
      ) : (
        <div className="skpe-pending-list">
          {visibleItems.map((item) => (
            <article
              key={item.pending_id}
              className="skpe-pending-item"
              role="button"
              tabIndex={0}
              onClick={() => onNavigate(item.route_section)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault()
                  onNavigate(item.route_section)
                }
              }}
            >
              <div className="skpe-pending-item-main">
                <div className="skpe-pending-item-labels">
                  <span>{sourceLabels[item.source_type]}</span>
                  <span>
                    {responsibilityLabels[item.responsibility_type] ??
                      'Responsabilidade atribuída'}
                  </span>
                </div>

                <h3>{item.title}</h3>

                {item.description && <p>{item.description}</p>}

                <div className="skpe-pending-item-meta">
                  {item.source_code && <span>{item.source_code}</span>}
                  <span>Prazo: {formatDate(item.due_date)}</span>
                  <span>Prioridade: {priorityLabel(item.priority)}</span>
                </div>

                {item.blocking_reason && (
                  <div className="skpe-pending-blocking-reason">
                    {item.blocking_reason}
                  </div>
                )}
              </div>

              <div className="skpe-pending-item-actions">
                <span
                  className={`skpe-pending-status skpe-pending-status-${item.normalized_status}`}
                >
                  {statusLabels[item.normalized_status]}
                </span>

                <button
                  type="button"
                  className="skpe-card-link-button"
                  onClick={(event) => {
                    event.stopPropagation()
                    onNavigate(item.route_section)
                  }}
                >
                  Abrir origem
                </button>
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  )
}
