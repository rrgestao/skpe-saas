import { useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './StrategicCapabilitiesChangeReadinessSection.css'

type Props = {
  formulationId: string | null
}

type Issue = {
  code?: string
  message?: string
  affectedCount?: number
}

type Readiness = {
  packageStatus?: string | null
  applicability?: string | null
  readyForValidation?: boolean
  readyForCompletion?: boolean
  blockingIssueCount?: number
  issues?: Issue[]
  metrics?: {
    changeItems?: number
    activeCapacityPeriods?: number
    activeCapacityAllocations?: number
  }
  authorityPolicy?: {
    personCapacityAuthority?: string
    duplicatesCapacityAllocation?: boolean
    evidenceAuthority?: string
    humanValidationRequired?: boolean
  }
}

export function StrategicCapabilitiesChangeReadinessSection({
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
        'get_skpe_pem0403_change_readiness',
        {
          target_formulation_id: formulationId,
          include_package_state: true,
        },
      )

      if (!active) return

      if (error) {
        setReadiness(null)
        setErrorMessage(
          'Não foi possível avaliar Capacidades e Gestão da Mudança: ' +
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
  }, [formulationId])

  return (
    <section className="skpe-capabilities-change-readiness">
      <header>
        <p className="skpe-eyebrow">Capacidades e Gestão da Mudança</p>
        <h3>Prontidão das capacidades e mudanças necessárias</h3>
        <p>
          Esta etapa registra lacunas e impactos que precisam ser tratados para
          executar a estratégia. A capacidade quantitativa de pessoas continua
          sendo controlada pela capacidade corporativa do SPARKs; o SK-PE não duplica esse controle.
        </p>
      </header>

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : null}

      {readiness ? (
        <>
          <div className="skpe-capabilities-change-readiness__state">
            <strong>
              {readiness.readyForCompletion
                ? 'Capacidades e mudança validadas para conclusão'
                : readiness.readyForValidation
                  ? 'Avaliação pronta para validação humana'
                  : 'Avaliação ainda possui bloqueadores'}
            </strong>
            <span>
              Aplicabilidade: {readiness.applicability ?? 'não definida'} · pacote:{' '}
              {readiness.packageStatus ?? 'não configurado'}
            </span>
          </div>

          <div className="skpe-capabilities-change-readiness__metrics">
            <MetricCard
              label="Lacunas/impactos registrados"
              value={readiness.metrics?.changeItems ?? 0}
            />
            <MetricCard
              label="Períodos de capacidade ativos"
              value={readiness.metrics?.activeCapacityPeriods ?? 0}
            />
            <MetricCard
              label="Alocações de capacidade ativas"
              value={readiness.metrics?.activeCapacityAllocations ?? 0}
            />
          </div>

          {(readiness.issues?.length ?? 0) > 0 ? (
            <div className="skpe-capabilities-change-readiness__issues">
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

          <p className="skpe-capabilities-change-readiness__policy">
            A capacidade de pessoas e as evidências permanecem nas fontes corporativas correspondentes. Validação humana obrigatória.
          </p>
        </>
      ) : null}
    </section>
  )
}
