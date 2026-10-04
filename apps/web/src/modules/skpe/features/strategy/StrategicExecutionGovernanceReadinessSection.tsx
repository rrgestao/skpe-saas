import { useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './StrategicExecutionGovernanceReadinessSection.css'

type Props = {
  formulationId: string | null
}

type ReadinessIssue = {
  code: string
  severity: string
  message: string
}

type MonitoringReadiness = {
  packageId?: string
  packageStatus?: string | null
  readyForValidation?: boolean
  readyForFormulation?: boolean
  blockingIssues?: ReadinessIssue[]
  recommendations?: ReadinessIssue[]
  metrics?: {
    activeStrategicIndicators?: number
    activeKeyResults?: number
    selectedInitiatives?: number
  }
}

type MonitoringPackage = {
  id: string
  status: string
  cycle_frequency: string
  review_frequency: string
  owner_user_id: string | null
  governance_owner_user_id: string | null
}

export function StrategicExecutionGovernanceReadinessSection({
  formulationId,
}: Props) {
  const [readiness, setReadiness] = useState<MonitoringReadiness | null>(null)
  const [monitoringPackage, setMonitoringPackage] =
    useState<MonitoringPackage | null>(null)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setErrorMessage('')

      if (!formulationId) {
        setReadiness(null)
        setMonitoringPackage(null)
        return
      }

      const [readinessResponse, packageResponse] = await Promise.all([
        supabase.rpc('get_skpe_monitoring_package_readiness', {
          p_formulation_id: formulationId,
          p_include_package_state: true,
        }),
        supabase
          .from('skpe_monitoring_packages')
          .select(
            'id,status,cycle_frequency,review_frequency,owner_user_id,governance_owner_user_id',
          )
          .eq('formulation_id', formulationId)
          .maybeSingle(),
      ])

      if (!active) return

      const firstError = readinessResponse.error ?? packageResponse.error
      if (firstError) {
        setErrorMessage(
          'Não foi possível avaliar a governança da execução: ' + firstError.message,
        )
        return
      }

      setReadiness((readinessResponse.data ?? null) as MonitoringReadiness | null)
      setMonitoringPackage(
        (packageResponse.data ?? null) as MonitoringPackage | null,
      )
    }

    void load()

    return () => {
      active = false
    }
  }, [formulationId])

  return (
    <section className="skpe-execution-governance-readiness">
      <header>
        <p className="skpe-eyebrow">PEM-03.04 · Responsabilidades e Governança da Execução</p>
        <h3>Prontidão da governança de execução</h3>
        <p>
          Esta etapa define quem acompanha a estratégia, quem governa os ciclos
          de revisão e qual a cadência de monitoramento. O painel lê o contrato
          canônico do pacote FE-08 e não cria responsáveis, fóruns ou decisões
          automaticamente.
        </p>
      </header>

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : null}

      {readiness ? (
        <>
          <div className="skpe-execution-governance-readiness__state">
            <strong>
              {readiness.readyForFormulation
                ? 'Governança pronta e validada para conclusão da etapa'
                : readiness.readyForValidation
                  ? 'Governança pronta para validação humana'
                  : 'Governança ainda possui bloqueadores'}
            </strong>
            <span>
              Pacote: {readiness.packageStatus ?? 'não configurado'}
            </span>
          </div>

          <div className="skpe-execution-governance-readiness__metrics">
            <MetricCard
              label="Indicadores ativos"
              value={readiness.metrics?.activeStrategicIndicators ?? 0}
            />
            <MetricCard
              label="KRs ativos"
              value={readiness.metrics?.activeKeyResults ?? 0}
            />
            <MetricCard
              label="Iniciativas selecionadas"
              value={readiness.metrics?.selectedInitiatives ?? 0}
            />
            <MetricCard
              label="Cadência de monitoramento"
              value={monitoringPackage?.cycle_frequency ?? '—'}
            />
            <MetricCard
              label="Cadência de revisão"
              value={monitoringPackage?.review_frequency ?? '—'}
            />
          </div>

          <div className="skpe-execution-governance-readiness__owners">
            <article>
              <small>Responsável pelo monitoramento</small>
              <strong>
                {monitoringPackage?.owner_user_id ? 'Definido' : 'Pendente'}
              </strong>
            </article>
            <article>
              <small>Responsável pela governança / RAE</small>
              <strong>
                {monitoringPackage?.governance_owner_user_id ? 'Definido' : 'Pendente'}
              </strong>
            </article>
          </div>

          {(readiness.blockingIssues?.length ?? 0) > 0 ? (
            <div className="skpe-execution-governance-readiness__issues is-blocking">
              <strong>Bloqueadores</strong>
              {readiness.blockingIssues?.map((issue) => (
                <article key={issue.code + ':' + issue.message}>
                  <div>
                    <b>{issue.code}</b>
                    <span>{issue.severity}</span>
                  </div>
                  <p>{issue.message}</p>
                </article>
              ))}
            </div>
          ) : null}

          {(readiness.recommendations?.length ?? 0) > 0 ? (
            <div className="skpe-execution-governance-readiness__issues">
              <strong>Recomendações</strong>
              {readiness.recommendations?.map((issue) => (
                <article key={issue.code + ':' + issue.message}>
                  <div>
                    <b>{issue.code}</b>
                    <span>{issue.severity}</span>
                  </div>
                  <p>{issue.message}</p>
                </article>
              ))}
            </div>
          ) : null}
        </>
      ) : null}
    </section>
  )
}
