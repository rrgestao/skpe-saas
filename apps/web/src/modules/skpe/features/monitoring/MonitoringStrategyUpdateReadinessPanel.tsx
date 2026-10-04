import { useCallback, useEffect, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './MonitoringStrategyUpdateReadinessPanel.css'

type Props = {
  organizationId: string
  formulationId: string | null
  refreshToken?: number
}

type Issue = {
  code?: string
  message?: string
}

type Readiness = {
  strategyUpdateDecisionId?: string | null
  decisionSequence?: number | null
  decisionOutcome?: string | null
  decisionReason?: string | null
  targetRevisionFormulationId?: string | null
  targetRevisionVersionNumber?: number | null
  targetRevisionStatus?: string | null
  readyForCompletion?: boolean
  blockingIssueCount?: number
  issues?: Issue[]
}

type InitialDecision = 'no_update_required' | 'revision_required'

export function MonitoringStrategyUpdateReadinessPanel({
  organizationId,
  formulationId,
  refreshToken = 0,
}: Props) {
  const [readiness, setReadiness] = useState<Readiness | null>(null)
  const [canRatify, setCanRatify] = useState(false)
  const [outcome, setOutcome] = useState<InitialDecision>('no_update_required')
  const [reason, setReason] = useState('')
  const [versionLabel, setVersionLabel] = useState('')
  const [changeSummary, setChangeSummary] = useState('')
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')

  const refresh = useCallback(async () => {
    if (!formulationId) {
      setReadiness(null)
      setCanRatify(false)
      return
    }

    const [readinessResponse, permissionResponse] = await Promise.all([
      supabase.rpc('get_skpe_pem0504_strategy_update_readiness', {
        target_formulation_id: formulationId,
      }),
      supabase.rpc('can_ratify_skpe_governance', {
        target_organization_id: organizationId,
      }),
    ])

    if (readinessResponse.error) {
      setReadiness(null)
      setMessage(readinessResponse.error.message)
    } else {
      setReadiness((readinessResponse.data ?? null) as Readiness | null)
    }

    setCanRatify(Boolean(permissionResponse.data))
    if (permissionResponse.error) setMessage(permissionResponse.error.message)
  }, [formulationId, organizationId])

  useEffect(() => {
    void refresh()
  }, [refresh, refreshToken])

  async function recordDecision() {
    if (!formulationId || reason.trim().length < 10) {
      setMessage('Registre uma justificativa com pelo menos 10 caracteres.')
      return
    }

    setBusy(true)
    setMessage('')

    const { error } = await supabase.rpc('record_skpe_strategy_update_decision', {
      target_formulation_id: formulationId,
      target_decision_outcome: outcome,
      target_decision_reason: reason.trim(),
      target_revision_formulation_id: null,
      decision_metadata: {
        source: 'pem05.04.ui',
        humanDecision: true,
      },
    })

    if (error) {
      setBusy(false)
      setMessage(error.message)
      return
    }

    setReason('')
    setBusy(false)
    setMessage(
      outcome === 'no_update_required'
        ? 'Decisão registrada: nenhuma atualização estratégica necessária neste ciclo.'
        : 'Decisão registrada: revisão estratégica necessária. A revisão ainda não foi criada.',
    )
    await refresh()
  }

  async function createRevision() {
    if (!formulationId) return

    if (versionLabel.trim().length < 2 || changeSummary.trim().length < 10) {
      setMessage(
        'Informe um rótulo de versão e um resumo da mudança com pelo menos 10 caracteres.',
      )
      return
    }

    setBusy(true)
    setMessage('')

    const { data: revisionId, error: revisionError } = await supabase.rpc(
      'create_skpe_formulation_revision',
      {
        source_formulation_id: formulationId,
        version_label: versionLabel.trim(),
        change_summary: changeSummary.trim(),
        new_valid_from: null,
        new_valid_until: null,
        change_reason: changeSummary.trim(),
      },
    )

    if (revisionError || typeof revisionId !== 'string') {
      setBusy(false)
      setMessage(revisionError?.message ?? 'A revisão não pôde ser criada.')
      return
    }

    const { error: decisionError } = await supabase.rpc(
      'record_skpe_strategy_update_decision',
      {
        target_formulation_id: formulationId,
        target_decision_outcome: 'revision_opened',
        target_decision_reason: changeSummary.trim(),
        target_revision_formulation_id: revisionId,
        decision_metadata: {
          source: 'pem05.04.ui',
          humanDecision: true,
          revisionCreatedByExplicitAction: true,
        },
      },
    )

    if (decisionError) {
      setBusy(false)
      setMessage(
        'A revisão foi criada, mas o vínculo decisório não foi registrado: ' +
          decisionError.message,
      )
      await refresh()
      return
    }

    setVersionLabel('')
    setChangeSummary('')
    setBusy(false)
    setMessage('Revisão estratégica criada e vinculada à decisão institucional.')
    await refresh()
  }

  return (
    <article className="skpe-strategy-update-readiness">
      <header>
        <div>
          <span>PEM-05.04 · Atualização Estratégica Governada</span>
          <h2>Decisão de atualização da estratégia</h2>
          <p>
            A Formulação aprovada nunca é alterada silenciosamente. A decisão
            pode concluir que não há atualização necessária ou determinar uma
            revisão. Uma nova revisão só é criada por ação humana explícita.
          </p>
        </div>
        <strong className={readiness?.readyForCompletion ? 'is-ready' : 'is-blocked'}>
          {readiness?.readyForCompletion ? 'Pronto' : 'Bloqueado'}
        </strong>
      </header>

      {readiness ? (
        <>
          <div className="skpe-strategy-update-readiness__metrics">
            <MetricCard
              label="Decisão atual"
              value={readiness.decisionOutcome ?? 'Pendente'}
            />
            <MetricCard
              label="Sequência decisória"
              value={readiness.decisionSequence ?? 0}
            />
            <MetricCard
              label="Revisão-alvo"
              value={
                readiness.targetRevisionVersionNumber
                  ? 'v' + readiness.targetRevisionVersionNumber
                  : '—'
              }
            />
          </div>

          {(readiness.issues?.length ?? 0) > 0 ? (
            <div className="skpe-strategy-update-readiness__issues">
              <strong>Bloqueadores</strong>
              {readiness.issues?.map((issue, index) => (
                <div key={(issue.code ?? 'issue') + ':' + index}>
                  <b>{issue.code ?? 'PENDÊNCIA'}</b>
                  <span>{issue.message ?? 'Pendência identificada pelo backend.'}</span>
                </div>
              ))}
            </div>
          ) : null}

          {canRatify ? (
            <div className="skpe-strategy-update-readiness__decision">
              <label>
                Decisão institucional
                <select
                  value={outcome}
                  onChange={(event) =>
                    setOutcome(event.target.value as InitialDecision)
                  }
                >
                  <option value="no_update_required">
                    Nenhuma atualização necessária
                  </option>
                  <option value="revision_required">
                    Revisão estratégica necessária
                  </option>
                </select>
              </label>

              <label>
                Justificativa
                <textarea
                  rows={3}
                  value={reason}
                  onChange={(event) => setReason(event.target.value)}
                />
              </label>

              <button type="button" disabled={busy} onClick={() => void recordDecision()}>
                {busy ? 'Registrando...' : 'Registrar decisão institucional'}
              </button>

              {readiness.decisionOutcome === 'revision_required' ? (
                <div className="skpe-strategy-update-readiness__revision">
                  <strong>Abrir revisão formal</strong>
                  <p>
                    Esta ação criará uma nova versão draft derivada da Formulação
                    aprovada, preservando lineage e versionamento.
                  </p>
                  <label>
                    Rótulo da nova versão
                    <input
                      value={versionLabel}
                      onChange={(event) => setVersionLabel(event.target.value)}
                    />
                  </label>
                  <label>
                    Resumo da mudança
                    <textarea
                      rows={3}
                      value={changeSummary}
                      onChange={(event) => setChangeSummary(event.target.value)}
                    />
                  </label>
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => void createRevision()}
                  >
                    {busy ? 'Criando revisão...' : 'Criar revisão estratégica'}
                  </button>
                </div>
              ) : null}
            </div>
          ) : null}
        </>
      ) : null}

      {message ? <p className="skpe-strategy-update-readiness__message">{message}</p> : null}
    </article>
  )
}
