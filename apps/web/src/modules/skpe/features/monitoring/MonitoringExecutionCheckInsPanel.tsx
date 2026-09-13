import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

type Kr = { id: string; code: string; name: string; unit: string | null; status: string }
type Initiative = { id: string; code: string; name: string; status: string; progress: number }
type CheckIn = { id: string; status: string; entityId: string; value: number | null; confidence?: string | null }

type Props = {
  organizationId: string
  formulationId: string
  cycleId: string
  onChanged: () => void
}

export function MonitoringExecutionCheckInsPanel({
  organizationId,
  formulationId,
  cycleId,
  onChanged,
}: Props) {
  const [krs, setKrs] = useState<Kr[]>([])
  const [initiatives, setInitiatives] = useState<Initiative[]>([])
  const [krCheckIns, setKrCheckIns] = useState<CheckIn[]>([])
  const [initiativeCheckIns, setInitiativeCheckIns] = useState<CheckIn[]>([])
  const [canManage, setCanManage] = useState(false)
  const [canGovern, setCanGovern] = useState(false)
  const [selectedKrId, setSelectedKrId] = useState('')
  const [krCurrentValue, setKrCurrentValue] = useState('')
  const [krStatus, setKrStatus] = useState('active')
  const [krHealth, setKrHealth] = useState('not_assessed')
  const [krConfidence, setKrConfidence] = useState('not_assessed')
  const [krForecastValue, setKrForecastValue] = useState('')
  const [krForecastDate, setKrForecastDate] = useState('')
  const [krBlockers, setKrBlockers] = useState('')
  const [krEvidence, setKrEvidence] = useState('')
  const [krNotes, setKrNotes] = useState('')

  const [selectedInitiativeId, setSelectedInitiativeId] = useState('')
  const [initiativeProgress, setInitiativeProgress] = useState('')
  const [initiativeStatus, setInitiativeStatus] = useState('in_progress')
  const [initiativeHealth, setInitiativeHealth] = useState('not_assessed')
  const [initiativeRisk, setInitiativeRisk] = useState('not_assessed')
  const [initiativeActualCost, setInitiativeActualCost] = useState('')
  const [initiativeBenefit, setInitiativeBenefit] = useState('')
  const [initiativeForecastEnd, setInitiativeForecastEnd] = useState('')
  const [initiativeMilestones, setInitiativeMilestones] = useState('')
  const [initiativeDelays, setInitiativeDelays] = useState('')
  const [initiativeBlockers, setInitiativeBlockers] = useState('')
  const [initiativeDecision, setInitiativeDecision] = useState('')
  const [initiativeEvidence, setInitiativeEvidence] = useState('')
  const [initiativeNotes, setInitiativeNotes] = useState('')
  const [reason, setReason] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const reload = async () => {
    const [krResponse, portfolioResponse, krCheckInResponse, initiativeCheckInResponse, manageResponse, governResponse] = await Promise.all([
      supabase.from('skpe_key_results').select('id,code,name,unit,status').eq('formulation_id', formulationId).in('status', ['active', 'at_risk', 'achieved', 'not_achieved']).order('code'),
      supabase.from('skpe_initiative_portfolio_items').select('initiative_id').eq('formulation_id', formulationId).eq('selection_status', 'selected'),
      supabase.from('skpe_key_result_check_ins').select('id,key_result_id,status,current_value,confidence_level').eq('monitoring_cycle_id', cycleId).in('status', ['submitted', 'validated', 'rejected']).order('check_in_date', { ascending: false }),
      supabase.from('skpe_initiative_check_ins').select('id,initiative_id,status,progress').eq('monitoring_cycle_id', cycleId).in('status', ['submitted', 'validated', 'rejected']).order('check_in_date', { ascending: false }),
      supabase.rpc('can_manage_skpe_monitoring', { target_organization_id: organizationId }),
      supabase.rpc('can_manage_skpe_governance', { target_organization_id: organizationId }),
    ])

    const initiativeIds = (portfolioResponse.data ?? []).map((row) => row.initiative_id)
    let initiativeRows: Initiative[] = []
    if (!portfolioResponse.error && initiativeIds.length > 0) {
      const response = await supabase.from('sparks_initiatives').select('id,code,name,status,progress').in('id', initiativeIds).order('code')
      initiativeRows = response.error ? [] : (response.data ?? []) as Initiative[]
    }

    setKrs(krResponse.error ? [] : (krResponse.data ?? []) as Kr[])
    setInitiatives(initiativeRows)
    setKrCheckIns(krCheckInResponse.error ? [] : (krCheckInResponse.data ?? []).map((row) => ({ id: row.id, status: row.status, entityId: row.key_result_id, value: row.current_value, confidence: row.confidence_level })))
    setInitiativeCheckIns(initiativeCheckInResponse.error ? [] : (initiativeCheckInResponse.data ?? []).map((row) => ({ id: row.id, status: row.status, entityId: row.initiative_id, value: row.progress })))
    setCanManage(manageResponse.error ? false : manageResponse.data === true)
    setCanGovern(governResponse.error ? false : governResponse.data === true)
  }

  useEffect(() => {
    void reload()
  }, [cycleId, formulationId, organizationId])

  const latestKr = useMemo(() => {
    const map = new Map<string, CheckIn>()
    for (const row of krCheckIns) if (!map.has(row.entityId)) map.set(row.entityId, row)
    return map
  }, [krCheckIns])

  const latestInitiative = useMemo(() => {
    const map = new Map<string, CheckIn>()
    for (const row of initiativeCheckIns) if (!map.has(row.entityId)) map.set(row.entityId, row)
    return map
  }, [initiativeCheckIns])

  const ensureReason = () => {
    if (reason.trim().length >= 10) return true
    setMessage('Informe uma justificativa com pelo menos 10 caracteres.')
    return false
  }

  const recordKr = async () => {
    if (!selectedKrId || krCurrentValue.trim() === '' || !ensureReason()) return
    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('record_skpe_key_result_check_in', {
      p_cycle_id: cycleId,
      p_key_result_id: selectedKrId,
      p_current_value: Number(krCurrentValue),
      p_payload: {
        operationalStatus: krStatus,
        healthStatus: krHealth,
        confidenceLevel: krConfidence,
        forecastValue: krForecastValue || null,
        forecastDate: krForecastDate || null,
        blockers: krBlockers.trim() || null,
        evidenceReference: krEvidence.trim() || null,
        notes: krNotes.trim() || null,
      },
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setMessage('Check-in do KR submetido para validação.')
    setReason('')
    setKrCurrentValue('')
    setKrForecastValue('')
    setKrForecastDate('')
    setKrBlockers('')
    setKrEvidence('')
    setKrNotes('')
    await reload()
    onChanged()
  }

  const recordInitiative = async () => {
    if (!selectedInitiativeId || initiativeProgress.trim() === '' || !ensureReason()) return
    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('record_skpe_initiative_check_in', {
      p_cycle_id: cycleId,
      p_initiative_id: selectedInitiativeId,
      p_payload: {
        progress: Number(initiativeProgress),
        operationalStatus: initiativeStatus,
        healthStatus: initiativeHealth,
        riskLevel: initiativeRisk,
        actualCost: initiativeActualCost || null,
        realizedBenefit: initiativeBenefit || null,
        forecastEndDate: initiativeForecastEnd || null,
        milestonesSummary: initiativeMilestones.trim() || null,
        delaysText: initiativeDelays.trim() || null,
        blockers: initiativeBlockers.trim() || null,
        decisionRequired: initiativeDecision.trim() || null,
        evidenceReference: initiativeEvidence.trim() || null,
        notes: initiativeNotes.trim() || null,
      },
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setMessage('Check-in da Iniciativa submetido para validação.')
    setReason('')
    setInitiativeProgress('')
    setInitiativeActualCost('')
    setInitiativeBenefit('')
    setInitiativeForecastEnd('')
    setInitiativeMilestones('')
    setInitiativeDelays('')
    setInitiativeBlockers('')
    setInitiativeDecision('')
    setInitiativeEvidence('')
    setInitiativeNotes('')
    await reload()
    onChanged()
  }

  const transitionRecord = async (
    recordType: 'key_result_check_in' | 'initiative_check_in',
    recordId: string,
    action: 'validate' | 'reject' | 'resubmit',
  ) => {
    if (!ensureReason()) return
    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('transition_skpe_monitoring_record', {
      p_record_type: recordType,
      p_record_id: recordId,
      p_action: action,
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setReason('')
    setMessage('Transição do check-in registrada com rastreabilidade.')
    await reload()
    onChanged()
  }

  const renderValidationActions = (
    recordType: 'key_result_check_in' | 'initiative_check_in',
    row: CheckIn | undefined,
  ) => {
    if (!row) return null
    if (row.status === 'submitted' && canGovern) {
      return (
        <div className="skpe-monitoring-collection-actions">
          <button type="button" disabled={busy} onClick={() => { void transitionRecord(recordType, row.id, 'validate') }}>Validar</button>
          <button type="button" disabled={busy} onClick={() => { void transitionRecord(recordType, row.id, 'reject') }}>Rejeitar</button>
        </div>
      )
    }
    if (row.status === 'rejected' && canManage) {
      return (
        <div className="skpe-monitoring-collection-actions">
          <button type="button" disabled={busy} onClick={() => { void transitionRecord(recordType, row.id, 'resubmit') }}>Ressubmeter</button>
        </div>
      )
    }
    return null
  }

  return (
    <section className="skpe-monitoring-checkins" aria-label="Check-ins governados de execução estratégica">
      <header>
        <div><span>Execução estratégica</span><h3>Check-ins de KRs e Iniciativas</h3></div>
      </header>
      <label className="skpe-monitoring-package-reason">
        <span>Justificativa da ação *</span>
        <textarea value={reason} onChange={(event) => setReason(event.target.value)} placeholder="Registre a motivação da ação." disabled={busy} />
      </label>

      <section className="skpe-monitoring-checkins-block" aria-label="Check-ins de Resultados-Chave">
        <h4>Resultados-Chave</h4>
        <div className="skpe-monitoring-package-form-grid">
          <label>
            <span>Resultado-Chave</span>
            <select value={selectedKrId} onChange={(event) => setSelectedKrId(event.target.value)} disabled={!canManage || busy}>
              <option value="">Selecione</option>
              {krs.map((kr) => <option key={kr.id} value={kr.id}>{kr.code} · {kr.name}</option>)}
            </select>
          </label>
          <label><span>Valor atual</span><input type="number" value={krCurrentValue} onChange={(event) => setKrCurrentValue(event.target.value)} disabled={!canManage || busy} /></label>
          <label>
            <span>Situação operacional</span>
            <select value={krStatus} onChange={(event) => setKrStatus(event.target.value)} disabled={!canManage || busy}>
              <option value="active">Ativo</option>
              <option value="at_risk">Em risco</option>
              <option value="achieved">Atingido</option>
              <option value="not_achieved">Não atingido</option>
            </select>
          </label>
          <label>
            <span>Saúde</span>
            <select value={krHealth} onChange={(event) => setKrHealth(event.target.value)} disabled={!canManage || busy}>
              <option value="not_assessed">Não avaliada</option>
              <option value="healthy">Saudável</option>
              <option value="attention">Atenção</option>
              <option value="critical">Crítica</option>
            </select>
          </label>
          <label>
            <span>Confiança</span>
            <select value={krConfidence} onChange={(event) => setKrConfidence(event.target.value)} disabled={!canManage || busy}>
              <option value="not_assessed">Não avaliada</option>
              <option value="low">Baixa</option>
              <option value="medium">Média</option>
              <option value="high">Alta</option>
            </select>
          </label>
        </div>
        <div className="skpe-monitoring-package-form-grid">
          <label><span>Previsão de valor</span><input type="number" value={krForecastValue} onChange={(event) => setKrForecastValue(event.target.value)} disabled={!canManage || busy} /></label>
          <label><span>Data prevista</span><input type="date" value={krForecastDate} onChange={(event) => setKrForecastDate(event.target.value)} disabled={!canManage || busy} /></label>
          <label><span>Evidência</span><input value={krEvidence} onChange={(event) => setKrEvidence(event.target.value)} disabled={!canManage || busy} /></label>
        </div>
        <label className="skpe-monitoring-package-reason"><span>Bloqueios</span><textarea value={krBlockers} onChange={(event) => setKrBlockers(event.target.value)} disabled={!canManage || busy} /></label>
        <label className="skpe-monitoring-package-reason"><span>Observações</span><textarea value={krNotes} onChange={(event) => setKrNotes(event.target.value)} disabled={!canManage || busy} /></label>
        <div className="skpe-monitoring-collection-actions">
          <button type="button" disabled={!canManage || busy} onClick={() => { void recordKr() }}>Registrar check-in do KR</button>
        </div>

        <div className="skpe-monitoring-collection-list">
          {krs.map((kr) => {
            const row = latestKr.get(kr.id)
            return (
              <article key={kr.id}>
                <div>
                  <strong>{kr.code} · {kr.name}</strong>
                  <span>{row ? `${row.value ?? '—'} ${kr.unit ?? ''}` : 'Sem check-in no ciclo'}</span>
                  <small>{row?.confidence ? `Confiança: ${row.confidence}` : ''}</small>
                </div>
                <div><span>{row?.status ?? 'missing'}</span></div>
                {renderValidationActions('key_result_check_in', row)}
              </article>
            )
          })}
        </div>
      </section>

      <section className="skpe-monitoring-checkins-block" aria-label="Check-ins de Iniciativas Estratégicas">
        <h4>Iniciativas selecionadas</h4>
        <div className="skpe-monitoring-package-form-grid">
          <label>
            <span>Iniciativa</span>
            <select value={selectedInitiativeId} onChange={(event) => setSelectedInitiativeId(event.target.value)} disabled={!canManage || busy}>
              <option value="">Selecione</option>
              {initiatives.map((initiative) => <option key={initiative.id} value={initiative.id}>{initiative.code} · {initiative.name}</option>)}
            </select>
          </label>
          <label><span>Progresso (%)</span><input type="number" min={0} max={100} value={initiativeProgress} onChange={(event) => setInitiativeProgress(event.target.value)} disabled={!canManage || busy} /></label>
          <label><span>Situação operacional</span><input value={initiativeStatus} onChange={(event) => setInitiativeStatus(event.target.value)} disabled={!canManage || busy} /></label>
          <label><span>Saúde</span><input value={initiativeHealth} onChange={(event) => setInitiativeHealth(event.target.value)} disabled={!canManage || busy} /></label>
          <label><span>Risco</span><input value={initiativeRisk} onChange={(event) => setInitiativeRisk(event.target.value)} disabled={!canManage || busy} /></label>
          <label><span>Custo realizado</span><input type="number" value={initiativeActualCost} onChange={(event) => setInitiativeActualCost(event.target.value)} disabled={!canManage || busy} /></label>
          <label><span>Benefício realizado</span><input type="number" value={initiativeBenefit} onChange={(event) => setInitiativeBenefit(event.target.value)} disabled={!canManage || busy} /></label>
          <label><span>Previsão de término</span><input type="date" value={initiativeForecastEnd} onChange={(event) => setInitiativeForecastEnd(event.target.value)} disabled={!canManage || busy} /></label>
          <label><span>Evidência</span><input value={initiativeEvidence} onChange={(event) => setInitiativeEvidence(event.target.value)} disabled={!canManage || busy} /></label>
        </div>
        <label className="skpe-monitoring-package-reason"><span>Marcos</span><textarea value={initiativeMilestones} onChange={(event) => setInitiativeMilestones(event.target.value)} disabled={!canManage || busy} /></label>
        <label className="skpe-monitoring-package-reason"><span>Atrasos</span><textarea value={initiativeDelays} onChange={(event) => setInitiativeDelays(event.target.value)} disabled={!canManage || busy} /></label>
        <label className="skpe-monitoring-package-reason"><span>Bloqueios</span><textarea value={initiativeBlockers} onChange={(event) => setInitiativeBlockers(event.target.value)} disabled={!canManage || busy} /></label>
        <label className="skpe-monitoring-package-reason"><span>Decisão requerida</span><textarea value={initiativeDecision} onChange={(event) => setInitiativeDecision(event.target.value)} disabled={!canManage || busy} /></label>
        <label className="skpe-monitoring-package-reason"><span>Observações</span><textarea value={initiativeNotes} onChange={(event) => setInitiativeNotes(event.target.value)} disabled={!canManage || busy} /></label>
        <div className="skpe-monitoring-collection-actions">
          <button type="button" disabled={!canManage || busy} onClick={() => { void recordInitiative() }}>Registrar check-in da Iniciativa</button>
        </div>

        <div className="skpe-monitoring-collection-list">
          {initiatives.map((initiative) => {
            const row = latestInitiative.get(initiative.id)
            return (
              <article key={initiative.id}>
                <div>
                  <strong>{initiative.code} · {initiative.name}</strong>
                  <span>{row ? `${row.value ?? '—'}%` : 'Sem check-in no ciclo'}</span>
                </div>
                <div><span>{row?.status ?? 'missing'}</span></div>
                {renderValidationActions('initiative_check_in', row)}
              </article>
            )
          })}
        </div>
      </section>

      {message ? <div className="skpe-monitoring-state" role="status">{message}</div> : null}
    </section>
  )
}
