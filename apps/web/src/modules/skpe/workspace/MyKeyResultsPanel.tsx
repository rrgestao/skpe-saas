import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'
import { platformRoutes } from '../app/skpeRoutes'

import './MyKeyResultsPanel.css'

type KeyResultStatus =
  | 'draft'
  | 'active'
  | 'at_risk'
  | 'achieved'
  | 'not_achieved'

type KeyResultValidationStatus =
  | 'draft'
  | 'pending_validation'
  | 'validated'

type KeyResultPolarity =
  | 'higher_is_better'
  | 'lower_is_better'
  | 'target_is_better'
  | 'range_is_better'

type KeyResultFilter =
  | 'all'
  | 'at_risk'
  | 'active'
  | 'draft'
  | 'completed'

type MyKeyResult = {
  key_result_id: string
  organization_id: string
  project_id: string
  formulation_id: string
  okr_id: string
  okr_code: string
  okr_title: string
  strategic_objective_id: string
  strategic_objective_code: string
  strategic_objective_name: string
  code: string
  name: string
  description: string | null
  baseline_value: number | null
  current_value: number | null
  target_value: number | null
  unit: string | null
  progress: number
  period_start: string | null
  period_end: string | null
  status: KeyResultStatus
  validation_status: KeyResultValidationStatus
  contribution_weight: number | null
  polarity: KeyResultPolarity | null
  measurement_frequency: string | null
  data_source: string | null
  formula_text: string | null
  calculation_method: string | null
  range_lower: number | null
  range_upper: number | null
  collection_automatable: boolean | null
  updated_at: string
}

type MyKeyResultsPanelProps = {
  organizationId: string
  projectId: string | null
}

const statusLabels: Record<KeyResultStatus, string> = {
  draft: 'Rascunho',
  active: 'Ativo',
  at_risk: 'Em risco',
  achieved: 'Alcançado',
  not_achieved: 'Não alcançado',
}

const polarityLabels: Record<KeyResultPolarity, string> = {
  higher_is_better: 'Quanto maior, melhor',
  lower_is_better: 'Quanto menor, melhor',
  target_is_better: 'Quanto mais próximo da meta, melhor',
  range_is_better: 'Faixa de desempenho',
}

const validationLabels: Record<KeyResultValidationStatus, string> = {
  draft: 'Validação em rascunho',
  pending_validation: 'Aguardando validação',
  validated: 'Validado',
}

function formatDate(value: string | null) {
  if (!value) return 'Não informado'

  const [year, month, day] = value.split('-').map(Number)

  if (!year || !month || !day) return value

  return new Intl.DateTimeFormat('pt-BR').format(
    new Date(year, month - 1, day),
  )
}

function formatNumber(value: number | null, unit: string | null) {
  if (value === null || value === undefined) return 'Não informado'

  const formatted = new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 2,
  }).format(value)

  return unit ? `${formatted} ${unit}` : formatted
}

function formatPercentage(value: number | null) {
  if (value === null || value === undefined) return '0%'

  return `${new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 1,
  }).format(value)}%`
}

function formatFrequency(value: string | null) {
  if (!value) return 'Periodicidade não informada'

  const labels: Record<string, string> = {
    daily: 'Diária',
    weekly: 'Semanal',
    monthly: 'Mensal',
    bimonthly: 'Bimestral',
    quarterly: 'Trimestral',
    semiannual: 'Semestral',
    annual: 'Anual',
    on_demand: 'Sob demanda',
  }

  return labels[value] ?? value
}

function isCompleted(status: KeyResultStatus) {
  return status === 'achieved' || status === 'not_achieved'
}

export function MyKeyResultsPanel({
  organizationId,
  projectId,
}: MyKeyResultsPanelProps) {
  const [items, setItems] = useState<MyKeyResult[]>([])
  const [filter, setFilter] = useState<KeyResultFilter>('all')
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    async function loadKeyResults() {
      setLoading(true)
      setErrorMessage(null)

      const { data, error } = await supabase.rpc(
        'get_my_skpe_key_results',
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
          `Não foi possível carregar seus Resultados-Chave: ${translateBackendMessage(error.message)}`,
        )
        setLoading(false)
        return
      }

      setItems((data ?? []) as MyKeyResult[])
      setLoading(false)
    }

    void loadKeyResults()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const counts = useMemo(
    () => ({
      all: items.length,
      at_risk: items.filter((item) => item.status === 'at_risk').length,
      active: items.filter((item) => item.status === 'active').length,
      draft: items.filter((item) => item.status === 'draft').length,
      completed: items.filter((item) => isCompleted(item.status)).length,
    }),
    [items],
  )

  const visibleItems = useMemo(() => {
    if (filter === 'all') return items

    if (filter === 'completed') {
      return items.filter((item) => isCompleted(item.status))
    }

    return items.filter((item) => item.status === filter)
  }, [filter, items])

  function openKeyResultOrigin(item: MyKeyResult) {
    window.location.assign(
      platformRoutes.skpe({
        organizationId: item.organization_id,
        projectId: item.project_id,
        formulationId: item.formulation_id,
        section: 'okrs',
      }),
    )
  }

  return (
    <section
      className="skpe-key-results-panel"
      aria-labelledby="my-key-results-title"
    >
      <div className="skpe-key-results-heading">
        <div>
          <p className="skpe-card-code">Responsabilidades pessoais</p>
          <h2 id="my-key-results-title">Meus KRs</h2>
          <p>
            Resultados-Chave sob sua responsabilidade, com progresso,
            desempenho atual, meta e contexto do OKR correspondente.
          </p>
        </div>

        {!loading && !errorMessage && (
          <span className="skpe-key-results-total">
            {items.length} {items.length === 1 ? 'KR' : 'KRs'}
          </span>
        )}
      </div>

      <div
        className="skpe-key-results-filters"
        aria-label="Filtros de Resultados-Chave"
      >
        {(
          [
            ['all', 'Todos'],
            ['at_risk', 'Em risco'],
            ['active', 'Ativos'],
            ['draft', 'Rascunhos'],
            ['completed', 'Concluídos'],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            className={
              filter === value
                ? 'skpe-key-results-filter skpe-key-results-filter-active'
                : 'skpe-key-results-filter'
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
        <div className="skpe-key-results-state" role="status">
          Carregando seus Resultados-Chave...
        </div>
      ) : errorMessage ? (
        <div
          className="skpe-key-results-state skpe-key-results-error"
          role="alert"
        >
          {errorMessage}
        </div>
      ) : visibleItems.length === 0 ? (
        <div className="skpe-key-results-state">
          <strong>Nenhum Resultado-Chave encontrado.</strong>
          <span>
            Não existem KRs sob sua responsabilidade correspondentes ao
            filtro selecionado.
          </span>
        </div>
      ) : (
        <div className="skpe-key-results-list">
          {visibleItems.map((item) => {
            const progress = Math.max(0, Math.min(100, item.progress ?? 0))

            return (
              <article
                key={item.key_result_id}
                className="skpe-key-results-item"
                role="button"
                tabIndex={0}
                onClick={() => openKeyResultOrigin(item)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault()
                    openKeyResultOrigin(item)
                  }
                }}
              >
                <div className="skpe-key-results-item-main">
                  <div className="skpe-key-results-item-labels">
                    <span>{item.code}</span>
                    <span>
                      {item.okr_code} · {item.okr_title}
                    </span>
                  </div>

                  <h3>{item.name}</h3>

                  {item.description && <p>{item.description}</p>}

                  <div className="skpe-key-results-objective">
                    <span>Objetivo Estratégico — OKRs</span>
                    <strong>
                      {item.strategic_objective_code} ·{' '}
                      {item.strategic_objective_name}
                    </strong>
                  </div>

                  <div className="skpe-key-results-progress">
                    <div className="skpe-key-results-progress-heading">
                      <span>Progresso do KR</span>
                      <strong>{formatPercentage(progress)}</strong>
                    </div>

                    <div
                      className="skpe-key-results-progress-track"
                      role="progressbar"
                      aria-label={`Progresso de ${item.name}`}
                      aria-valuemin={0}
                      aria-valuemax={100}
                      aria-valuenow={progress}
                    >
                      <span
                        className="skpe-key-results-progress-value"
                        style={{ width: `${progress}%` }}
                      />
                    </div>
                  </div>

                  <div className="skpe-key-results-values">
                    <div>
                      <span>Linha de base</span>
                      <strong>
                        {formatNumber(item.baseline_value, item.unit)}
                      </strong>
                    </div>

                    <div>
                      <span>Valor atual</span>
                      <strong>
                        {formatNumber(item.current_value, item.unit)}
                      </strong>
                    </div>

                    <div>
                      <span>Meta</span>
                      <strong>
                        {formatNumber(item.target_value, item.unit)}
                      </strong>
                    </div>
                  </div>

                  <div className="skpe-key-results-period">
                    <span>
                      Período: {formatDate(item.period_start)} até{' '}
                      {formatDate(item.period_end)}
                    </span>

                    {item.contribution_weight !== null && (
                      <span>
                        Peso de contribuição:{' '}
                        {formatPercentage(item.contribution_weight)}
                      </span>
                    )}
                  </div>

                  <div className="skpe-key-results-item-meta">
                    <span>{formatFrequency(item.measurement_frequency)}</span>

                    {item.polarity && (
                      <span>{polarityLabels[item.polarity]}</span>
                    )}

                    {item.data_source && (
                      <span>Fonte: {item.data_source}</span>
                    )}

                    <span>{validationLabels[item.validation_status]}</span>
                  </div>
                </div>

                <div className="skpe-key-results-item-actions">
                  <span
                    className={`skpe-key-results-status skpe-key-results-status-${item.status}`}
                  >
                    {statusLabels[item.status]}
                  </span>

                  <button
                    type="button"
                    className="skpe-card-link-button"
                    onClick={(event) => {
                      event.stopPropagation()
                      openKeyResultOrigin(item)
                    }}
                  >
                    Abrir origem
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
