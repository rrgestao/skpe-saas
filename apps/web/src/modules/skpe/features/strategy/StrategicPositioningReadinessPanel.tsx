import { useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './StrategicPositioningReadinessPanel.css'

type ReadinessIssue = {
  code?: string
  severity?: string
  message?: string
  affectedCount?: number
}

type PositioningReadiness = {
  readyForCompletion?: boolean
  blockingIssueCount?: number
  issues?: ReadinessIssue[]
  counts?: {
    themes?: number
    themeDecisions?: number
    perspectives?: number
    perspectiveDecisions?: number
    unresolvedCanonicalMutations?: number
  }
  counterproof?: {
    required?: boolean
    confirmed?: boolean
    expectedArtifacts?: string[]
  }
}

type Props = {
  formulationId: string
}

export function StrategicPositioningReadinessPanel({ formulationId }: Props) {
  const [readiness, setReadiness] = useState<PositioningReadiness | null>(null)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setErrorMessage('')

      const { data, error } = await supabase.rpc(
        'get_skpe_pem0203_positioning_readiness',
        {
          target_formulation_id: formulationId,
        },
      )

      if (!active) return

      if (error) {
        setReadiness(null)
        setErrorMessage(
          'Não foi possível avaliar a prontidão de PEM-02.03: ' + error.message,
        )
        return
      }

      setReadiness((data ?? null) as PositioningReadiness | null)
    }

    void load()

    return () => {
      active = false
    }
  }, [formulationId])

  if (errorMessage) {
    return (
      <section className="skpe-positioning-readiness is-error">
        {errorMessage}
      </section>
    )
  }

  if (!readiness) return null

  return (
    <section className="skpe-positioning-readiness">
      <header>
        <div>
          <p className="skpe-eyebrow">Prontidão das escolhas e do posicionamento</p>
          <h2>
            {readiness.readyForCompletion
              ? 'Posicionamento pronto para conclusão governada'
              : 'Posicionamento ainda possui bloqueadores'}
          </h2>
          <p>
            O relato de validação não substitui a decisão humana individual nem
            a contraprova estruturada. A etapa só pode ser concluída após a
            reconciliação da planilha + HTML da contraprova documental.
          </p>
        </div>
        <span className={readiness.readyForCompletion ? 'is-ready' : 'is-blocked'}>
          {readiness.readyForCompletion
            ? 'Pronto para concluir'
            : (readiness.blockingIssueCount ?? 0) + ' bloqueio(s)'}
        </span>
      </header>

      <div className="skpe-positioning-readiness__metrics">
        <MetricCard
          label="Temas decididos"
          value={
            (readiness.counts?.themeDecisions ?? 0) +
            '/' +
            (readiness.counts?.themes ?? 0)
          }
        />
        <MetricCard
          label="Perspectivas decididas"
          value={
            (readiness.counts?.perspectiveDecisions ?? 0) +
            '/' +
            (readiness.counts?.perspectives ?? 0)
          }
        />
        <MetricCard
          label="Alterações canônicas pendentes"
          value={readiness.counts?.unresolvedCanonicalMutations ?? 0}
        />
        <MetricCard
          label="Contraprova documental"
          value={readiness.counterproof?.confirmed ? 'Reconciliada' : 'Pendente'}
          helper={
            readiness.counterproof?.expectedArtifacts?.join(' + ') ??
            'Planilha + HTML da contraprova'
          }
        />
      </div>

      {(readiness.issues?.length ?? 0) > 0 ? (
        <div className="skpe-positioning-readiness__issues">
          <strong>Pendências que impedem concluir a etapa</strong>
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
    </section>
  )
}
