import { useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './MonitoringOperationReadinessPanel.css'

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
  monitoringPackageStatus?: string | null
  cycleId?: string | null
  cycleCode?: string | null
  cycleName?: string | null
  cycleStatus?: string | null
  cyclePeriodStart?: string | null
  cyclePeriodEnd?: string | null
  readyForCompletion?: boolean
  blockingIssueCount?: number
  issues?: Issue[]
  metrics?: {
    operationalRecords?: number
    missingRequiredEvidence?: number
    indicatorMeasurements?: number
    keyResultCheckIns?: number
    initiativeCheckIns?: number
  }
}

export function MonitoringOperationReadinessPanel({
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
        'get_skpe_pem0501_monitoring_operation_readiness',
        { target_formulation_id: formulationId },
      )

      if (!active) return

      if (error) {
        setReadiness(null)
        setErrorMessage(
          'Não foi possível avaliar a Operação da Rotina de Monitoramento: ' +
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
    <article className="skpe-monitoring-operation-readiness">
      <header>
        <div>
          <span>Operação da Rotina de Monitoramento</span>
          <h2>Prontidão do ciclo para análise crítica</h2>
          <p>
            A etapa reutiliza integralmente o FE-08. Ela comprova que um ciclo
            foi operado, recebeu medições/check-ins e chegou pronto para revisão.
            Não abre, submete, ratifica ou fecha ciclos automaticamente.
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
          <div className="skpe-monitoring-operation-readiness__metrics">
            <MetricCard
              label="Registros operacionais"
              value={readiness.metrics?.operationalRecords ?? 0}
            />
            <MetricCard
              label="Medições de indicadores"
              value={readiness.metrics?.indicatorMeasurements ?? 0}
            />
            <MetricCard
              label="Check-ins de KRs"
              value={readiness.metrics?.keyResultCheckIns ?? 0}
            />
            <MetricCard
              label="Check-ins de iniciativas"
              value={readiness.metrics?.initiativeCheckIns ?? 0}
            />
            <MetricCard
              label="Evidências obrigatórias ausentes"
              value={readiness.metrics?.missingRequiredEvidence ?? 0}
            />
          </div>

          <div className="skpe-monitoring-operation-readiness__cycle">
            <div>
              <small>Ciclo considerado</small>
              <strong>
                {readiness.cycleCode
                  ? readiness.cycleCode + ' · ' + (readiness.cycleName ?? '')
                  : 'Nenhum ciclo operado pronto para revisão'}
              </strong>
            </div>
            <span>{readiness.cycleStatus ?? '—'}</span>
          </div>

          {(readiness.issues?.length ?? 0) > 0 ? (
            <div className="skpe-monitoring-operation-readiness__issues">
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
