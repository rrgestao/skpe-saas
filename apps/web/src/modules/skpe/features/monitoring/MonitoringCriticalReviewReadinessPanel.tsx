import { useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './MonitoringCriticalReviewReadinessPanel.css'

type Props = {
  formulationId: string | null
  refreshToken?: number
}

type Issue = {
  code?: string
  message?: string
  affectedCount?: number
}

type Readiness = {
  cycleId?: string | null
  strategyReviewId?: string | null
  reviewStatus?: string | null
  reviewHeldAt?: string | null
  reviewRatifiedAt?: string | null
  readyForCompletion?: boolean
  blockingIssueCount?: number
  issues?: Issue[]
  metrics?: {
    reviewItems?: number
    governanceDecisions?: number
  }
}

export function MonitoringCriticalReviewReadinessPanel({
  formulationId,
  refreshToken = 0,
}: Props) {
  const [readiness, setReadiness] = useState<Readiness | null>(null)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setErrorMessage('')

      if (!formulationId) {
        setReadiness(null)
        return
      }

      const { data, error } = await supabase.rpc(
        'get_skpe_pem0502_critical_review_readiness',
        { target_formulation_id: formulationId },
      )

      if (!active) return

      if (error) {
        setReadiness(null)
        setErrorMessage(
          'Não foi possível avaliar a Análise Crítica de Desempenho: ' +
            error.message,
        )
        return
      }

      setReadiness((data ?? null) as Readiness | null)
    }

    void load()

    return () => {
      active = false
    }
  }, [formulationId, refreshToken])

  return (
    <article className="skpe-critical-review-readiness">
      <header>
        <div>
          <span>PEM-05.02 · Análise Crítica de Desempenho</span>
          <h2>Prontidão da RAE e das decisões</h2>
          <p>
            Esta etapa reutiliza a RAE do FE-08. Ela exige análise substantiva,
            conclusões ratificadas e decisões rastreáveis quando necessárias.
            Nenhuma conclusão ou decisão é criada automaticamente.
          </p>
        </div>
        <strong className={readiness?.readyForCompletion ? 'is-ready' : 'is-blocked'}>
          {readiness?.readyForCompletion ? 'Pronto' : 'Bloqueado'}
        </strong>
      </header>

      {errorMessage ? (
        <div className="skpe-monitoring-state is-error" role="alert">
          {errorMessage}
        </div>
      ) : null}

      {readiness ? (
        <>
          <div className="skpe-critical-review-readiness__metrics">
            <MetricCard
              label="Itens de análise"
              value={readiness.metrics?.reviewItems ?? 0}
            />
            <MetricCard
              label="Decisões de governança"
              value={readiness.metrics?.governanceDecisions ?? 0}
            />
            <MetricCard
              label="Status da RAE"
              value={readiness.reviewStatus ?? '—'}
            />
          </div>

          <div className="skpe-critical-review-readiness__review">
            <div>
              <small>RAE considerada</small>
              <strong>{readiness.strategyReviewId ?? 'Nenhuma RAE ratificada'}</strong>
            </div>
            <span>
              {readiness.reviewRatifiedAt
                ? 'Ratificada'
                : 'Ratificação pendente'}
            </span>
          </div>

          {(readiness.issues?.length ?? 0) > 0 ? (
            <div className="skpe-critical-review-readiness__issues">
              <strong>Bloqueadores</strong>
              {readiness.issues?.map((issue, index) => (
                <div key={(issue.code ?? 'issue') + ':' + index}>
                  <b>{issue.code ?? 'PENDÊNCIA'}</b>
                  <span>{issue.message ?? 'Pendência identificada pelo backend.'}</span>
                  {typeof issue.affectedCount === 'number' ? (
                    <small>{issue.affectedCount} item(ns)</small>
                  ) : null}
                </div>
              ))}
            </div>
          ) : null}
        </>
      ) : null}
    </article>
  )
}
