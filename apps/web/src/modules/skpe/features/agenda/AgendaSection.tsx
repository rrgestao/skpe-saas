import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

import './AgendaSection.css'

type AgendaItem = {
  agenda_item_key: string
  organization_id: string
  source_module_code: string | null
  source_entity_type: string
  source_entity_id: string
  source_code: string | null
  item_kind: string
  title: string
  description: string | null
  starts_at: string | null
  ends_at: string | null
  due_at: string | null
  all_day: boolean
  timezone_name: string
  source_status: string | null
  status: string | null
  priority: string | null
  user_relation: string | null
  is_native: boolean
  route: string | null
  is_visible: boolean
}

type AgendaSectionProps = {
  organizationId: string
  refreshRequestKey?: number
}

function monthStart(value: Date) {
  return new Date(value.getFullYear(), value.getMonth(), 1)
}

function monthEnd(value: Date) {
  return new Date(value.getFullYear(), value.getMonth() + 1, 0)
}

function toDateOnly(value: Date) {
  const year = value.getFullYear()
  const month = String(value.getMonth() + 1).padStart(2, '0')
  const day = String(value.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function localDateKey(value: string | null, timezoneName: string) {
  if (!value) return null
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezoneName || 'UTC',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date(value))

  const year = parts.find((part) => part.type === 'year')?.value
  const month = parts.find((part) => part.type === 'month')?.value
  const day = parts.find((part) => part.type === 'day')?.value
  return year && month && day ? `${year}-${month}-${day}` : null
}

function itemDateKey(item: AgendaItem) {
  return localDateKey(item.starts_at ?? item.due_at, item.timezone_name)
}

function formatTime(item: AgendaItem) {
  if (item.all_day) return 'Dia inteiro'
  if (!item.starts_at) return item.due_at ? 'Prazo' : 'Sem horário'

  return new Intl.DateTimeFormat('pt-BR', {
    timeZone: item.timezone_name || 'UTC',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(item.starts_at))
}

function statusLabel(value: string | null) {
  const labels: Record<string, string> = {
    scheduled: 'Agendado',
    in_progress: 'Em andamento',
    completed: 'Concluído',
    overdue: 'Em atraso',
    cancelled: 'Cancelado',
    planned: 'Planejado',
    active: 'Ativo',
  }
  return value ? labels[value] ?? value : 'Sem situação'
}

export function AgendaSection({ organizationId, refreshRequestKey = 0 }: AgendaSectionProps) {
  const [cursor, setCursor] = useState(() => monthStart(new Date()))
  const [items, setItems] = useState<AgendaItem[]>([])
  const [loading, setLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')

  const rangeStart = monthStart(cursor)
  const rangeEnd = monthEnd(cursor)

  const loadAgenda = async () => {
    setLoading(true)
    setErrorMessage('')

    const { data, error } = await supabase.rpc('get_my_sparks_agenda', {
      target_organization_id: organizationId,
      target_module_code: 'SK-PE',
      target_date_from: toDateOnly(rangeStart),
      target_date_to: toDateOnly(rangeEnd),
      target_item_kind: null,
      target_status: null,
      target_include_hidden: false,
    })

    if (error) {
      setItems([])
      setErrorMessage('Não foi possível carregar sua agenda do Planejamento Estratégico.')
    } else {
      setItems((data ?? []) as AgendaItem[])
    }

    setLoading(false)
  }

  useEffect(() => {
    void loadAgenda()
  }, [organizationId, cursor.getFullYear(), cursor.getMonth(), refreshRequestKey])

  const itemsByDate = useMemo(() => {
    const grouped = new Map<string, AgendaItem[]>()
    for (const item of items) {
      const key = itemDateKey(item)
      if (!key) continue
      const current = grouped.get(key) ?? []
      current.push(item)
      grouped.set(key, current)
    }
    return grouped
  }, [items])

  const calendarDays = useMemo(() => {
    const first = monthStart(cursor)
    const startOffset = first.getDay()
    const gridStart = new Date(first.getFullYear(), first.getMonth(), 1 - startOffset)
    return Array.from({ length: 42 }, (_, index) => {
      const date = new Date(gridStart)
      date.setDate(gridStart.getDate() + index)
      return date
    })
  }, [cursor])

  const monthLabel = new Intl.DateTimeFormat('pt-BR', {
    month: 'long',
    year: 'numeric',
  }).format(cursor)

  const moveMonth = (offset: number) => {
    setCursor((current) => monthStart(new Date(current.getFullYear(), current.getMonth() + offset, 1)))
  }

  return (
    <section className="skpe-agenda-page">
      <header className="skpe-page-heading skpe-agenda-heading">
        <div>
          <p className="skpe-eyebrow">Agenda transversal governada</p>
          <h1>Agenda</h1>
          <p>
            Eventos e compromissos pessoais do Planejamento Estratégico, projetados das fontes canônicas sem duplicar cronograma ou registros.
          </p>
        </div>
        <div className="skpe-agenda-actions">
          <button type="button" onClick={() => moveMonth(-1)} aria-label="Mês anterior">‹</button>
          <button type="button" onClick={() => setCursor(monthStart(new Date()))}>Hoje</button>
          <button type="button" onClick={() => moveMonth(1)} aria-label="Próximo mês">›</button>

        </div>
      </header>

      {errorMessage && <div className="skpe-admin-message skpe-admin-message-error">{errorMessage}</div>}

      <section className="skpe-agenda-calendar" aria-label={`Calendário de ${monthLabel}`}>
        <div className="skpe-agenda-month-title">{monthLabel}</div>
        <div className="skpe-agenda-weekdays" aria-hidden="true">
          {['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'].map((label) => <span key={label}>{label}</span>)}
        </div>
        <div className="skpe-agenda-month-grid">
          {calendarDays.map((date) => {
            const key = toDateOnly(date)
            const dayItems = itemsByDate.get(key) ?? []
            const outside = date.getMonth() !== cursor.getMonth()
            const today = key === toDateOnly(new Date())

            return (
              <article
                key={key}
                className={[
                  'skpe-agenda-day',
                  outside ? 'is-outside' : '',
                  today ? 'is-today' : '',
                ].filter(Boolean).join(' ')}
              >
                <strong>{date.getDate()}</strong>
                <div className="skpe-agenda-day-items">
                  {dayItems.slice(0, 3).map((item) => (
                    <div key={item.agenda_item_key} className="skpe-agenda-chip" title={item.title}>
                      <span>{formatTime(item)}</span>
                      <b>{item.title}</b>
                    </div>
                  ))}
                  {dayItems.length > 3 && <small>+{dayItems.length - 3} compromisso(s)</small>}
                </div>
              </article>
            )
          })}
        </div>
      </section>

      <section className="skpe-agenda-list" aria-label="Compromissos do mês">
        <header>
          <div>
            <p className="skpe-eyebrow">Período selecionado</p>
            <h2>Compromissos do mês</h2>
          </div>
          <strong>{items.length}</strong>
        </header>

        {loading && items.length === 0 ? (
          <p className="skpe-agenda-empty">Carregando agenda...</p>
        ) : items.length === 0 ? (
          <p className="skpe-agenda-empty">Nenhum compromisso pessoal do SK-PE neste mês.</p>
        ) : (
          <div className="skpe-agenda-list-items">
            {items.map((item) => (
              <article key={item.agenda_item_key}>
                <div className="skpe-agenda-date-badge">
                  <strong>{itemDateKey(item)?.slice(8, 10) ?? '—'}</strong>
                  <span>{formatTime(item)}</span>
                </div>
                <div className="skpe-agenda-item-content">
                  <strong>{item.title}</strong>
                  {item.description && <p>{item.description}</p>}
                  <div>
                    <span>{statusLabel(item.status)}</span>
                    <span>{item.is_native ? 'Evento' : 'Projeção SK-PE'}</span>
                    {item.user_relation && <span>{item.user_relation}</span>}
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </section>
  )
}