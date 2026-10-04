import { useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './StrategicImplementationActivationReadinessSection.css'

type Props = {
  formulationId: string | null
}

type ReadinessIssue = {
  code?: string
  severity?: string
  message?: string
  affectedCount?: number
}

type ActivationReadiness = {
  readyForActivation?: boolean
  readyForCompletion?: boolean
  blockingIssueCount?: number
  issues?: ReadinessIssue[]
  metrics?: {
    selectedInitiatives?: number
    requiredActions?: number
    validatedRequiredActions?: number
  }
  activationPolicy?: {
    reusesPem0303Portfolio?: boolean
    reprioritizesPortfolio?: boolean
    startsExecutionAutomatically?: boolean
    requiresValidatedActions?: boolean
    requiresResponsibility?: boolean
    requiresPlannedHorizon?: boolean
  }
}

export function StrategicImplementationActivationReadinessSection({
  formulationId,
}: Props) {
  const [readiness, setReadiness] = useState<ActivationReadiness | null>(null)
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
        'get_skpe_pem0401_activation_readiness',
        { target_formulation_id: formulationId },
      )

      if (!active) return

      if (error) {
        setReadiness(null)
        setErrorMessage(
          'Não foi possível avaliar a ativação do Plano de Implementação: ' +
            error.message,
        )
        return
      }

      setReadiness((data ?? null) as ActivationReadiness | null)
    }

    void load()

    return () => {
      active = false
    }
  }, [formulationId])

  return (
    <section className="skpe-implementation-activation-readiness">
      <header>
        <p className="skpe-eyebrow">PEM-04.01 · Ativação do Plano de Implementação</p>
        <h3>Prontidão para ativar o portfólio aprovado</h3>
        <p>
          Esta etapa não redesenha nem reprioriza o portfólio de PEM-03.03.
          Ela confirma se as iniciativas selecionadas possuem condições reais
          para entrar em execução: responsabilidade, horizonte, ações, marcos e
          validações suficientes. Nenhuma execução é iniciada automaticamente.
        </p>
      </header>

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : null}

      {readiness ? (
        <>
          <div className="skpe-implementation-activation-readiness__state">
            <strong>
              {readiness.readyForActivation
                ? 'Plano pronto para ativação governada'
                : 'Plano ainda possui bloqueadores de ativação'}
            </strong>
            <span>
              {readiness.blockingIssueCount ?? 0} bloqueador(es)
            </span>
          </div>

          <div className="skpe-implementation-activation-readiness__metrics">
            <MetricCard
              label="Iniciativas selecionadas"
              value={readiness.metrics?.selectedInitiatives ?? 0}
            />
            <MetricCard
              label="Ações obrigatórias"
              value={readiness.metrics?.requiredActions ?? 0}
            />
            <MetricCard
              label="Ações obrigatórias validadas"
              value={readiness.metrics?.validatedRequiredActions ?? 0}
            />
          </div>

          {(readiness.issues?.length ?? 0) > 0 ? (
            <div className="skpe-implementation-activation-readiness__issues">
              <strong>Bloqueadores de ativação</strong>
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

          <p className="skpe-implementation-activation-readiness__policy">
            Regra canônica: reutiliza o portfólio validado em PEM-03.03, não
            reprioriza iniciativas e não inicia execução automaticamente.
          </p>
        </>
      ) : null}
    </section>
  )
}
