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
    initiativeRisks?: number
    highOrCriticalInitiativeRisks?: number
    validatedStrategicRisks?: number
    strategicRisksRequiringMitigation?: number
  }
  authorityPolicy?: {
    initiativeRiskAuthority?: string
    strategicRiskAuthority?: string
    strategicMitigationAuthority?: string
    duplicatesRisk?: boolean
    automaticRiskAcceptance?: boolean
    automaticMitigationCreation?: boolean
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
          'Não foi possível avaliar os Riscos da Implementação: ' + error.message,
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
        <h3>Prontidão dos riscos para execução</h3>
        <p>
          Esta etapa não recria riscos. Ela consolida os riscos das iniciativas
          selecionadas e os riscos estratégicos já validados, verificando se os
          casos relevantes possuem owner, resposta, prazo, validação e mitigação
          estruturada quando exigida.
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
                ? 'Riscos da implementação prontos para conclusão da etapa'
                : 'Riscos da implementação ainda possuem bloqueadores'}
            </strong>
            <span>{readiness.blockingIssueCount ?? 0} bloqueador(es)</span>
          </div>

          <div className="skpe-implementation-risk-readiness__metrics">
            <MetricCard
              label="Riscos das iniciativas"
              value={readiness.metrics?.initiativeRisks ?? 0}
            />
            <MetricCard
              label="Riscos altos/críticos"
              value={readiness.metrics?.highOrCriticalInitiativeRisks ?? 0}
            />
            <MetricCard
              label="Riscos estratégicos validados"
              value={readiness.metrics?.validatedStrategicRisks ?? 0}
            />
            <MetricCard
              label="Estratégicos exigindo mitigação"
              value={readiness.metrics?.strategicRisksRequiringMitigation ?? 0}
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
            Nenhum risco é criado, aceito ou mitigado automaticamente. As
            authorities permanecem em skpe_initiative_risks e nos contratos
            canônicos de riscos estratégicos/mitigação.
          </p>
        </>
      ) : null}
    </section>
  )
}
