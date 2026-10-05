import { useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './MonitoringLearningReadinessPanel.css'

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
  readyForCompletion?: boolean
  blockingIssueCount?: number
  issues?: Issue[]
  metrics?: {
    learnings?: number
    acceptedLearnings?: number
    incorporatedLearnings?: number
  }
}

export function MonitoringLearningReadinessPanel({
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
        'get_skpe_pem0503_learning_readiness',
        { target_formulation_id: formulationId },
      )

      if (!active) return

      if (error) {
        setReadiness(null)
        setErrorMessage(
          'Não foi possível avaliar Aprendizado e Melhoria: ' + error.message,
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
    <article className="skpe-learning-readiness">
      <header>
        <div>
          <span>Aprendizado e Melhoria</span>
          <h2>Prontidão dos aprendizados estratégicos</h2>
          <p>
            A etapa reutiliza o ledger canônico de aprendizados do FE-08. Ela
            preserva a diferença entre aprendizado, decisão e ação de melhoria:
            nenhum desses elementos é criado ou aceito automaticamente.
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
          <div className="skpe-learning-readiness__metrics">
            <MetricCard label="Aprendizados" value={readiness.metrics?.learnings ?? 0} />
            <MetricCard
              label="Aceitos"
              value={readiness.metrics?.acceptedLearnings ?? 0}
            />
            <MetricCard
              label="Incorporados"
              value={readiness.metrics?.incorporatedLearnings ?? 0}
            />
          </div>

          {(readiness.issues?.length ?? 0) > 0 ? (
            <div className="skpe-learning-readiness__issues">
              <strong>Bloqueadores</strong>
              {readiness.issues?.map((issue, index) => (
                <div key={(issue.code ?? 'issue') + ':' + index}>
                  <b>{issue.code ?? 'PENDÊNCIA'}</b>
                  <span>{issue.message ?? 'Pendência identificada pela solução.'}</span>
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
