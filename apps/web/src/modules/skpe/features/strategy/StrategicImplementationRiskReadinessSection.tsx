import { useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './StrategicImplementationRiskReadinessSection.css'

type Props = {
  formulationId: string | null
}

type Issue = {
  code?: string
  message?: string
  affectedCount?: number
}

type Readiness = {
  readyForCompletion?: boolean
  blockingIssueCount?: number
  issues?: Issue[]
  metrics?: {
    strategicRisks?: number
    strategicRisksRequiringMitigation?: number
    strategicMitigationsNotReady?: number
    initiativeRisks?: number
    highOrCriticalInitiativeRisks?: number
    highOrCriticalInitiativeRisksNotReady?: number
  }
  authorityPolicy?: {
    strategicRiskAuthority?: string
    strategicMitigationAuthority?: string
    initiativeRiskAuthority?: string
    mitigationActionAuthority?: string
    duplicatesRisk?: boolean
    humanValidationRequired?: boolean
  }
}

export function StrategicImplementationRiskReadinessSection({
  formulationId,
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
        'get_skpe_pem0404_implementation_risk_readiness',
        { target_formulation_id: formulationId },
      )

      if (!active) return

      if (error) {
        setReadiness(null)
        setErrorMessage(
          'Não foi possível avaliar os riscos da implementação: ' + error.message,
        )
        return
      }

      setReadiness((data ?? null) as Readiness | null)
    }

    void load()

    return () => {
      active = false
    }
  }, [formulationId])

  return (
    <section className="skpe-implementation-risk-readiness">
      <header>
        <p className="skpe-eyebrow">PEM-04.04 · Gestão de Riscos da Implementação</p>
        <h3>Prontidão dos riscos para a implementação</h3>
        <p>
          Esta etapa não replica riscos. Ela consolida as authorities já
          existentes de riscos estratégicos, vínculos de mitigação, riscos das
          iniciativas e ações 5W2H para verificar se a implementação pode
          avançar com respostas e responsabilidades governadas.
        </p>
      </header>

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : null}

      {readiness ? (
        <>
          <div className="skpe-implementation-risk-readiness__state">
            <strong>
              {readiness.readyForCompletion
                ? 'Riscos prontos para conclusão da etapa'
                : 'Riscos ainda possuem bloqueadores'}
            </strong>
            <span>{readiness.blockingIssueCount ?? 0} bloqueador(es)</span>
          </div>

          <div className="skpe-implementation-risk-readiness__metrics">
            <MetricCard
              label="Riscos estratégicos"
              value={readiness.metrics?.strategicRisks ?? 0}
            />
            <MetricCard
              label="Mitigações estratégicas pendentes"
              value={readiness.metrics?.strategicMitigationsNotReady ?? 0}
            />
            <MetricCard
              label="Riscos das iniciativas"
              value={readiness.metrics?.initiativeRisks ?? 0}
            />
            <MetricCard
              label="Riscos altos/críticos"
              value={readiness.metrics?.highOrCriticalInitiativeRisks ?? 0}
            />
            <MetricCard
              label="Altos/críticos pendentes"
              value={readiness.metrics?.highOrCriticalInitiativeRisksNotReady ?? 0}
            />
          </div>

          {(readiness.issues?.length ?? 0) > 0 ? (
            <div className="skpe-implementation-risk-readiness__issues">
              <strong>Bloqueadores</strong>
              {readiness.issues?.map((issue, index) => (
                <article key={(issue.code ?? 'issue') + ':' + index}>
                  <div>
                    <b>{issue.code ?? 'PENDÊNCIA'}</b>
                    {typeof issue.affectedCount === 'number' ? (
                      <span>{issue.affectedCount} item(ns)</span>
                    ) : null}
                  </div>
                  <p>{issue.message ?? 'Pendência identificada pelo backend.'}</p>
                </article>
              ))}
            </div>
          ) : null}

          <p className="skpe-implementation-risk-readiness__policy">
            Riscos estratégicos, riscos de iniciativas e ações de mitigação
            permanecem em suas authorities canônicas. Nenhum risco é duplicado
            por PEM-04.04.
          </p>
        </>
      ) : null}
    </section>
  )
}
