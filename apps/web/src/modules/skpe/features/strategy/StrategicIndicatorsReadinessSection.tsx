import { useEffect, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

import './StrategicIndicatorsReadinessSection.css'

type ReadinessIssue = {
  code: string
  severity: string
  scope?: string
  message: string
  affectedCount?: number
}

type IndicatorReadiness = {
  packageStatus?: string
  readyForValidation?: boolean
  validated?: boolean
  readyForFormulation?: boolean
  contentBlockingIssueCount?: number
  blockingIssueCount?: number
  counts?: {
    activeObjectives?: number
    activeIndicators?: number
    objectivesWithIndicators?: number
    activeLongTermTargets?: number
    activeIntermediateTargets?: number
    verifiedOrActiveBenchmarks?: number
    indicatorsWithBaseline?: number
    indicatorsWithOwner?: number
    financialIndicators?: number
    financialIndicatorPercentage?: number
  }
  issues?: ReadinessIssue[]
  methodologyRules?: {
    baselineRequired?: boolean
    intermediateTargetsRecommended?: boolean
    benchmarkRecommended?: boolean
    automatedCollectionRecommended?: boolean
  }
}

type Props = {
  formulationId: string | null
}

function packageLabel(status: string | undefined) {
  if (status === 'validated') return 'Validado'
  if (status === 'pending_validation') return 'Aguardando validação'
  if (status === 'in_elaboration') return 'Em elaboração'
  if (status === 'not_created') return 'Não criado'
  return status ?? 'Não informado'
}

export function StrategicIndicatorsReadinessSection({ formulationId }: Props) {
  const [readiness, setReadiness] = useState<IndicatorReadiness | null>(null)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    if (!formulationId) {
      setReadiness(null)
      return () => {
        active = false
      }
    }

    setErrorMessage('')

    void supabase
      .rpc('get_skpe_indicators_readiness', {
        p_formulation_id: formulationId,
      })
      .then((response) => {
        if (!active) return
        if (response.error) {
          setReadiness(null)
          setErrorMessage(response.error.message)
          return
        }
        setReadiness((response.data ?? null) as IndicatorReadiness | null)
      })

    return () => {
      active = false
    }
  }, [formulationId])

  if (errorMessage) {
    return (
      <section className="skpe-indicator-readiness is-error">
        Não foi possível carregar a prontidão de Indicadores e Metas: {errorMessage}
      </section>
    )
  }

  if (!readiness) {
    return (
      <section className="skpe-indicator-readiness">
        Prontidão de Indicadores e Metas indisponível para esta Formulação.
      </section>
    )
  }

  const blockingIssues =
    readiness.issues?.filter((issue) => issue.severity === 'blocking') ?? []
  const recommendations =
    readiness.issues?.filter((issue) => issue.severity !== 'blocking') ?? []

  return (
    <section className="skpe-indicator-readiness">
      <header>
        <div>
          <small>PEM-03.02 · Indicadores e Metas</small>
          <h3>
            {readiness.readyForValidation
              ? 'Conteúdo pronto para validação do pacote'
              : 'Indicadores e metas ainda possuem pendências'}
          </h3>
          <p>
            Este painel usa o readiness canônico da Formulação. Ele exige fonte,
            fórmula, método de cálculo, unidade, polaridade, frequência, baseline
            e meta coerente. Benchmark permanece recomendação quando aplicável;
            não é tratado como evidência própria da cooperativa.
          </p>
        </div>
        <div className="skpe-indicator-readiness-status">
          <span>Pacote</span>
          <strong>{packageLabel(readiness.packageStatus)}</strong>
        </div>
      </header>

      <div className="skpe-indicator-readiness-kpis">
        <article>
          <span>OEs ativos</span>
          <strong>{readiness.counts?.activeObjectives ?? 0}</strong>
        </article>
        <article>
          <span>Indicadores ativos</span>
          <strong>{readiness.counts?.activeIndicators ?? 0}</strong>
        </article>
        <article>
          <span>OEs com indicador</span>
          <strong>{readiness.counts?.objectivesWithIndicators ?? 0}</strong>
        </article>
        <article>
          <span>Metas de longo prazo</span>
          <strong>{readiness.counts?.activeLongTermTargets ?? 0}</strong>
        </article>
        <article>
          <span>Baselines</span>
          <strong>{readiness.counts?.indicatorsWithBaseline ?? 0}</strong>
        </article>
        <article>
          <span>Bloqueadores</span>
          <strong>{readiness.blockingIssueCount ?? 0}</strong>
        </article>
      </div>

      {blockingIssues.length > 0 ? (
        <section className="skpe-indicator-readiness-issues">
          <strong>Pendências bloqueantes</strong>
          {blockingIssues.map((issue) => (
            <article key={`${issue.code}:${issue.message}`}>
              <div>
                <b>{issue.code}</b>
                <span>{issue.scope ?? 'content'}</span>
              </div>
              <p>{issue.message}</p>
              {typeof issue.affectedCount === 'number' ? (
                <small>{issue.affectedCount} ocorrência(s)</small>
              ) : null}
            </article>
          ))}
        </section>
      ) : (
        <p className="skpe-indicator-readiness-ok">
          Nenhuma pendência bloqueante de conteúdo foi identificada.
        </p>
      )}

      {recommendations.length > 0 ? (
        <details className="skpe-indicator-readiness-recommendations">
          <summary>Recomendações metodológicas ({recommendations.length})</summary>
          {recommendations.map((issue) => (
            <article key={`${issue.code}:${issue.message}`}>
              <b>{issue.code}</b>
              <p>{issue.message}</p>
            </article>
          ))}
        </details>
      ) : null}

      <footer>
        <span>
          Readiness para validação: <b>{readiness.readyForValidation ? 'sim' : 'não'}</b>
        </span>
        <span>
          Pacote validado: <b>{readiness.validated ? 'sim' : 'não'}</b>
        </span>
        <span>
          Pronto para avançar: <b>{readiness.readyForFormulation ? 'sim' : 'não'}</b>
        </span>
      </footer>
    </section>
  )
}
