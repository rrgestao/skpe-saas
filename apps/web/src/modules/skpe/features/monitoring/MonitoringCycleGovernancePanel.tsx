import { useEffect, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

type Props = {
  organizationId: string
  cycleId: string
  onChanged: () => void
}

type Issue = { code: string; message: string }
type Readiness = {
  cycleStatus: string
  readyForReview: boolean
  readyForClose: boolean
  reviewBlockingIssues: Issue[]
  blockingIssues: Issue[]
  recommendations: Issue[]
  metrics: Record<string, number>
}

export function MonitoringCycleGovernancePanel({ organizationId, cycleId, onChanged }: Props) {
  const [readiness, setReadiness] = useState<Readiness | null>(null)
  const [canGovern, setCanGovern] = useState(false)
  const [canRatify, setCanRatify] = useState(false)
  const [reason, setReason] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  const reload = async () => {
    const [readinessResponse, governResponse, ratifyResponse] = await Promise.all([
      supabase.rpc('get_skpe_monitoring_readiness', { p_cycle_id: cycleId }),
      supabase.rpc('can_manage_skpe_governance', { target_organization_id: organizationId }),
      supabase.rpc('can_ratify_skpe_governance', { target_organization_id: organizationId }),
    ])
    setReadiness(readinessResponse.error ? null : (readinessResponse.data as Readiness))
    setCanGovern(governResponse.error ? false : governResponse.data === true)
    setCanRatify(ratifyResponse.error ? false : ratifyResponse.data === true)
  }

  useEffect(() => {
    void reload()
  }, [cycleId, organizationId])

  const reasonOk = reason.trim().length >= 10

  const requestRatification = async () => {
    if (!canGovern || !reasonOk || readiness?.cycleStatus !== 'under_review') return
    setBusy(true); setMessage('')
    const { error } = await supabase.rpc('transition_skpe_monitoring_cycle', {
      p_cycle_id: cycleId,
      p_action: 'request_ratification',
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) { setMessage(error.message); return }
    setMessage('Ciclo encaminhado para ratificação.')
    await reload(); onChanged()
  }
  const closeCycle = async () => {
    if (!canRatify || !reasonOk || readiness?.cycleStatus !== 'pending_ratification' || !readiness.readyForClose) return
    setBusy(true); setMessage('')
    const { data, error } = await supabase.rpc('close_skpe_monitoring_cycle', {
      p_cycle_id: cycleId,
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) { setMessage(error.message); return }
    const result = data as { snapshotVersion?: number; checksumSha256?: string } | null
    setMessage(`Ciclo fechado com snapshot ratificado${result?.snapshotVersion ? ` v${result.snapshotVersion}` : ''}.`)
    await reload(); onChanged()
  }

  const reopenCycle = async () => {
    if (!canRatify || !reasonOk || readiness?.cycleStatus !== 'closed') return
    setBusy(true); setMessage('')
    const { error } = await supabase.rpc('reopen_skpe_monitoring_cycle', {
      p_cycle_id: cycleId,
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) { setMessage(error.message); return }
    setMessage('Ciclo reaberto. O snapshot ratificado anterior foi supersedido pelo runtime.')
    await reload(); onChanged()
  }

  return (
    <section className="skpe-monitoring-governance" aria-label="Governança e fechamento do ciclo">
      <header><div><span>Governança do ciclo</span><h3>Ratificação e fechamento</h3></div></header>
      {!readiness ? <p className="skpe-monitoring-empty">Readiness do ciclo indisponível.</p> : (
        <>
          <div className="skpe-monitoring-grid">
            <article><span>Status</span><strong>{readiness.cycleStatus}</strong></article>
            <article><span>Pronto para análise</span><strong>{readiness.readyForReview ? 'Sim' : 'Não'}</strong></article>
            <article><span>Pronto para fechamento</span><strong>{readiness.readyForClose ? 'Sim' : 'Não'}</strong></article>
          </div>
          {(readiness.blockingIssues ?? []).length > 0 ? (
            <div className="skpe-monitoring-tags">
              {readiness.blockingIssues.map((issue) => <span key={issue.code}>{issue.message}</span>)}
            </div>
          ) : null}
          {(readiness.recommendations ?? []).length > 0 ? (
            <div className="skpe-monitoring-tags">
              {readiness.recommendations.map((issue) => <span key={issue.code}>{issue.message}</span>)}
            </div>
          ) : null}
          <label><span>Justificativa auditável</span><textarea value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Explique a motivação da transição (mín. 10 caracteres)" /></label>
          <div className="skpe-monitoring-actions">
            <button type="button" onClick={() => { void requestRatification() }} disabled={!canGovern || busy || !reasonOk || readiness.cycleStatus !== 'under_review'}>Solicitar ratificação</button>
            <button type="button" onClick={() => { void closeCycle() }} disabled={!canRatify || busy || !reasonOk || readiness.cycleStatus !== 'pending_ratification' || !readiness.readyForClose}>Fechar ciclo e ratificar snapshot</button>
            <button type="button" onClick={() => { void reopenCycle() }} disabled={!canRatify || busy || !reasonOk || readiness.cycleStatus !== 'closed'}>Reabrir ciclo</button>
          </div>
        </>
      )}
      {message ? <p className="skpe-monitoring-message">{message}</p> : null}
    </section>
  )
}
