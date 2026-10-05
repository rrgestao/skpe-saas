import { useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './StrategicCommunicationMobilizationReadinessSection.css'

type Props = {
  formulationId: string | null
}

type Issue = {
  code?: string
  severity?: string
  message?: string
  affectedCount?: number
}

type Readiness = {
  packageId?: string | null
  packageStatus?: string | null
  readyForValidation?: boolean
  readyForCompletion?: boolean
  blockingIssueCount?: number
  issues?: Issue[]
  metrics?: {
    communicationItems?: number
    validatedItems?: number
  }
  deliveryPolicy?: {
    automaticSendingEnabled?: boolean
    evidenceAuthority?: string
    humanValidationRequired?: boolean
  }
}

export function StrategicCommunicationMobilizationReadinessSection({
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
        'get_skpe_pem0402_communication_readiness',
        {
          target_formulation_id: formulationId,
          include_package_state: true,
        },
      )

      if (!active) return

      if (error) {
        setReadiness(null)
        setErrorMessage(
          'Não foi possível avaliar Comunicação e Mobilização: ' + error.message,
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
    <section className="skpe-communication-mobilization-readiness">
      <header>
        <p className="skpe-eyebrow">Comunicação e Mobilização</p>
        <h3>Prontidão do plano de comunicação da implementação</h3>
        <p>
          O plano organiza públicos, objetivos, mensagens, canais, cadência,
          responsáveis e mobilização. A etapa prepara e valida o plano; não
          dispara mensagens automaticamente. As evidências permanecem vinculadas ao repositório de evidências do SPARKs.
        </p>
      </header>

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : null}

      {readiness ? (
        <>
          <div className="skpe-communication-mobilization-readiness__state">
            <strong>
              {readiness.readyForCompletion
                ? 'Plano validado e pronto para conclusão da etapa'
                : readiness.readyForValidation
                  ? 'Plano pronto para validação humana'
                  : 'Plano ainda possui bloqueadores'}
            </strong>
            <span>Pacote: {readiness.packageStatus ?? 'não configurado'}</span>
          </div>

          <div className="skpe-communication-mobilization-readiness__metrics">
            <MetricCard
              label="Itens de comunicação/mobilização"
              value={readiness.metrics?.communicationItems ?? 0}
            />
            <MetricCard
              label="Itens validados"
              value={readiness.metrics?.validatedItems ?? 0}
            />
            <MetricCard
              label="Envio automático"
              value={readiness.deliveryPolicy?.automaticSendingEnabled ? 'Sim' : 'Não'}
            />
          </div>

          {(readiness.issues?.length ?? 0) > 0 ? (
            <div className="skpe-communication-mobilization-readiness__issues">
              <strong>Bloqueadores</strong>
              {readiness.issues?.map((issue, index) => (
                <article key={(issue.code ?? 'issue') + ':' + index}>
                  <div>
                    <b>{issue.code ?? 'PENDÊNCIA'}</b>
                    {typeof issue.affectedCount === 'number' ? (
                      <span>{issue.affectedCount} item(ns)</span>
                    ) : null}
                  </div>
                  <p>{issue.message ?? 'Pendência identificada pela solução.'}</p>
                </article>
              ))}
            </div>
          ) : null}

          <p className="skpe-communication-mobilization-readiness__policy">
            Validação humana obrigatória. Nenhum e-mail, mensagem, aviso ou convocação é enviado automaticamente nesta etapa.
          </p>
        </>
      ) : null}
    </section>
  )
}
