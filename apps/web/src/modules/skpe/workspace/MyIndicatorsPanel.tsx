import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'
import { platformRoutes } from '../app/skpeRoutes'

import './MyIndicatorsPanel.css'

type IndicatorStatus = 'draft' | 'active' | 'inactive'

type IndicatorPolarity =
  | 'higher_is_better'
  | 'lower_is_better'
  | 'target_is_better'
  | 'range_is_better'

type IndicatorTargetType =
  | 'annual'
  | 'intermediate'
  | 'long_term'
  | 'cycle'

type MyIndicator = {
  indicator_id: string
  organization_id: string
  project_id: string
  formulation_id: string
  strategic_objective_id: string
  strategic_objective_code: string
  strategic_objective_name: string
  code: string
  name: string
  description: string | null
  unit: string
  polarity: IndicatorPolarity
  measurement_frequency: string | null
  data_source: string | null
  baseline_value: number | null
  baseline_date: string | null
  status: IndicatorStatus
  target_id: string | null
  target_type: IndicatorTargetType | null
  target_value: number | null
  minimum_value: number | null
  challenge_value: number | null
  tolerance_lower: number | null
  tolerance_upper: number | null
  target_period_start: string | null
  target_period_end: string | null
  target_status: string | null
  updated_at: string
}

type IndicatorFilter = 'all' | 'active' | 'draft' | 'inactive'

type MyIndicatorsPanelProps = {
  organizationId: string
  projectId: string | null
}

const statusLabels: Record<IndicatorStatus, string> = {
  draft: 'Rascunho',
  active: 'Ativo',
  inactive: 'Inativo',
}

const polarityLabels: Record<IndicatorPolarity, string> = {
  higher_is_better: 'Quanto maior, melhor',
  lower_is_better: 'Quanto menor, melhor',
  target_is_better: 'Quanto mais próximo da meta, melhor',
  range_is_better: 'Faixa de desempenho',
}

const targetTypeLabels: Record<IndicatorTargetType, string> = {
  annual: 'Meta anual',
  intermediate: 'Meta intermediária',
  long_term: 'Meta de longo prazo',
  cycle: 'Meta do ciclo',
}

function formatDate(value: string | null) {
  if (!value) return 'Não informada'

  const [year, month, day] = value.split('-').map(Number)

  if (!year || !month || !day) return value

  return new Intl.DateTimeFormat('pt-BR').format(
    new Date(year, month - 1, day),
  )
}

function formatNumber(value: number | null, unit: string) {
  if (value === null || value === undefined) return 'Não informada'

  const formatted = new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 2,
  }).format(value)

  return unit ? `${formatted} ${unit}` : formatted
}

function formatFrequency(value: string | null) {
  if (!value) return 'Periodicidade não informada'

  const labels: Record<string, string> = {
    daily: 'Diária',
    weekly: 'Semanal',
    monthly: 'Mensal',
    quarterly: 'Trimestral',
    semiannual: 'Semestral',
    annual: 'Anual',
  }

  return labels[value] ?? value
}

export function MyIndicatorsPanel({
  organizationId,
  projectId,
}: MyIndicatorsPanelProps) {
  const [items, setItems] = useState<MyIndicator[]>([])
  const [filter, setFilter] = useState<IndicatorFilter>('all')
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    async function loadIndicators() {
      setLoading(true)
      setErrorMessage(null)

      const { data, error } = await supabase.rpc(
        'get_my_skpe_indicators',
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
          `Não foi possível carregar seus indicadores: ${translateBackendMessage(error.message)}`,
        )
        setLoading(false)
        return
      }

      setItems((data ?? []) as MyIndicator[])
      setLoading(false)
    }

    void loadIndicators()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const counts = useMemo(
    () => ({
      all: items.length,
      active: items.filter((item) => item.status === 'active').length,
      draft: items.filter((item) => item.status === 'draft').length,
      inactive: items.filter((item) => item.status === 'inactive').length,
    }),
    [items],
  )

  const visibleItems = useMemo(() => {
    if (filter === 'all') return items

    return items.filter((item) => item.status === filter)
  }, [filter, items])

  function openIndicatorOrigin(item: MyIndicator) {
    window.location.assign(
      platformRoutes.skpe({
        organizationId: item.organization_id,
        projectId: item.project_id,
        formulationId: item.formulation_id,
        section: 'indicators',
      }),
    )
  }

  return (
    <section
      className="skpe-indicators-panel"
      aria-labelledby="my-indicators-title"
    >
      <div className="skpe-indicators-heading">
        <div>
          <p className="skpe-card-code">Responsabilidades pessoais</p>
          <h2 id="my-indicators-title">Meus Indicadores</h2>
          <p>
            Indicadores Estratégicos sob sua responsabilidade no contexto
            atual, com linha de base, meta aplicável e referência de medição.
          </p>
        </div>

        {!loading && !errorMessage && (
          <span className="skpe-indicators-total">
            {items.length} {items.length === 1 ? 'indicador' : 'indicadores'}
          </span>
        )}
      </div>

      <div
        className="skpe-indicators-filters"
        aria-label="Filtros de indicadores"
      >
        {(
          [
            ['all', 'Todos'],
            ['active', 'Ativos'],
            ['draft', 'Rascunhos'],
            ['inactive', 'Inativos'],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            className={
              filter === value
                ? 'skpe-indicators-filter skpe-indicators-filter-active'
                : 'skpe-indicators-filter'
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
        <div className="skpe-indicators-state" role="status">
          Carregando seus indicadores...
        </div>
      ) : errorMessage ? (
        <div
          className="skpe-indicators-state skpe-indicators-error"
          role="alert"
        >
          {errorMessage}
        </div>
      ) : visibleItems.length === 0 ? (
        <div className="skpe-indicators-state">
          <strong>Nenhum indicador encontrado.</strong>
          <span>
            Não existem Indicadores Estratégicos sob sua responsabilidade
            correspondentes ao filtro selecionado.
          </span>
        </div>
      ) : (
        <div className="skpe-indicators-list">
          {visibleItems.map((item) => (
            <article
              key={item.indicator_id}
              className="skpe-indicators-item"
              role="button"
              tabIndex={0}
              onClick={() => openIndicatorOrigin(item)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault()
                  openIndicatorOrigin(item)
                }
              }}
            >
              <div className="skpe-indicators-item-main">
                <div className="skpe-indicators-item-labels">
                  <span>{item.code}</span>
                  <span>
                    {item.strategic_objective_code} ·{' '}
                    {item.strategic_objective_name}
                  </span>
                </div>

                <h3>{item.name}</h3>

                {item.description && <p>{item.description}</p>}

                <div className="skpe-indicators-values">
                  <div>
                    <span>Linha de base</span>
                    <strong>
                      {formatNumber(item.baseline_value, item.unit)}
                    </strong>
                    <small>{formatDate(item.baseline_date)}</small>
                  </div>

                  <div>
                    <span>
                      {item.target_type
                        ? targetTypeLabels[item.target_type]
                        : 'Meta aplicável'}
                    </span>
                    <strong>
                      {formatNumber(item.target_value, item.unit)}
                    </strong>
                    <small>
                      {item.target_period_end
                        ? `Até ${formatDate(item.target_period_end)}`
                        : 'Período não informado'}
                    </small>
                  </div>
                </div>

                <div className="skpe-indicators-item-meta">
                  <span>{formatFrequency(item.measurement_frequency)}</span>
                  <span>{polarityLabels[item.polarity]}</span>
                  {item.data_source && <span>Fonte: {item.data_source}</span>}
                </div>
              </div>

              <div className="skpe-indicators-item-actions">
                <span
                  className={`skpe-indicators-status skpe-indicators-status-${item.status}`}
                >
                  {statusLabels[item.status]}
                </span>

                <button
                  type="button"
                  className="skpe-card-link-button"
                  onClick={(event) => {
                    event.stopPropagation()
                    openIndicatorOrigin(item)
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
