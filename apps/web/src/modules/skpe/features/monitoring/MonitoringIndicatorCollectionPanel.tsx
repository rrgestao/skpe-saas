import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

type Indicator = {
  id: string
  code: string
  name: string
  unit: string | null
}

type Measurement = {
  id: string
  indicator_id: string
  measurement_date: string
  measured_value: number
  status: string
  data_quality: string
  evidence_reference: string | null
  effective_performance: number | null
}

type Readiness = {
  cycleStatus: string
  readyForReview: boolean
  reviewBlockingIssues?: Array<{ code: string; message: string }>
}
type Props = {
  organizationId: string
  formulationId: string
  cycleId: string
  onChanged: () => void
}

export function MonitoringIndicatorCollectionPanel({
  organizationId,
  formulationId,
  cycleId,
  onChanged,
}: Props) {
  const [cycleStatus, setCycleStatus] = useState<string | null>(null)
  const [readiness, setReadiness] = useState<Readiness | null>(null)
  const [indicators, setIndicators] = useState<Indicator[]>([])
  const [measurements, setMeasurements] = useState<Measurement[]>([])
  const [canManage, setCanManage] = useState(false)
  const [canGovern, setCanGovern] = useState(false)
  const [selectedIndicatorId, setSelectedIndicatorId] = useState('')
  const [measuredValue, setMeasuredValue] = useState('')
  const [measurementDate, setMeasurementDate] = useState('')
  const [dataQuality, setDataQuality] = useState('not_assessed')
  const [evidenceReference, setEvidenceReference] = useState('')
  const [sourceName, setSourceName] = useState('')
  const [notes, setNotes] = useState('')
  const [reason, setReason] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const reload = async () => {
    const [cycleResponse, readinessResponse, indicatorResponse, measurementResponse, manageResponse, governResponse] = await Promise.all([
      supabase.from('skpe_monitoring_cycles').select('status').eq('id', cycleId).maybeSingle(),
      supabase.rpc('get_skpe_monitoring_readiness', { p_cycle_id: cycleId }),
      supabase.from('skpe_indicators').select('id,code,name,unit').eq('formulation_id', formulationId).eq('indicator_scope', 'strategic_kpi').eq('status', 'active').order('code'),
      supabase.from('skpe_indicator_measurements').select('id,indicator_id,measurement_date,measured_value,status,data_quality,evidence_reference,effective_performance').eq('monitoring_cycle_id', cycleId).in('status', ['submitted', 'validated', 'rejected']).order('measurement_date', { ascending: false }),
      supabase.rpc('can_manage_skpe_monitoring', { target_organization_id: organizationId }),
      supabase.rpc('can_manage_skpe_governance', { target_organization_id: organizationId }),
    ])

    setCycleStatus(cycleResponse.error ? null : cycleResponse.data?.status ?? null)
    setReadiness(readinessResponse.error ? null : readinessResponse.data as Readiness)
    setIndicators(indicatorResponse.error ? [] : (indicatorResponse.data ?? []) as Indicator[])
    setMeasurements(measurementResponse.error ? [] : (measurementResponse.data ?? []) as Measurement[])
    setCanManage(manageResponse.error ? false : manageResponse.data === true)
    setCanGovern(governResponse.error ? false : governResponse.data === true)
  }

  useEffect(() => {
    void reload()
  }, [cycleId, formulationId, organizationId])

  const latestByIndicator = useMemo(() => {
    const map = new Map<string, Measurement>()
    for (const measurement of measurements) {
      if (!map.has(measurement.indicator_id)) map.set(measurement.indicator_id, measurement)
    }
    return map
  }, [measurements])
  const transitionCycle = async (action: 'start_collection' | 'submit_review') => {
    if (reason.trim().length < 10) {
      setMessage('Informe uma justificativa com pelo menos 10 caracteres.')
      return
    }
    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('transition_skpe_monitoring_cycle', {
      p_cycle_id: cycleId,
      p_action: action,
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setReason('')
    setMessage(action === 'start_collection' ? 'Coleta iniciada.' : 'Ciclo submetido para análise.')
    await reload()
    onChanged()
  }

  const recordMeasurement = async () => {
    if (!selectedIndicatorId || measuredValue.trim() === '' || reason.trim().length < 10) {
      setMessage('Selecione o KPI, informe o valor medido e registre uma justificativa auditável.')
      return
    }
    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('record_skpe_indicator_measurement', {
      p_cycle_id: cycleId,
      p_indicator_id: selectedIndicatorId,
      p_measured_value: Number(measuredValue),
      p_payload: {
        measurementDate: measurementDate || null,
        dataQuality,
        evidenceReference: evidenceReference.trim() || null,
        sourceName: sourceName.trim() || null,
        notes: notes.trim() || null,
      },
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setMeasuredValue('')
    setMeasurementDate('')
    setEvidenceReference('')
    setSourceName('')
    setNotes('')
    setReason('')
    setMessage('Medição submetida para validação.')
    await reload()
    onChanged()
  }

  const transitionRecord = async (
    measurementId: string,
    action: 'validate' | 'reject' | 'resubmit',
  ) => {
    if (reason.trim().length < 10) {
      setMessage('Informe uma justificativa com pelo menos 10 caracteres.')
      return
    }
    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('transition_skpe_monitoring_record', {
      p_record_type: 'indicator_measurement',
      p_record_id: measurementId,
      p_action: action,
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setReason('')
    setMessage(
      action === 'validate'
        ? 'Medição validada pela governança.'
        : action === 'reject'
          ? 'Medição rejeitada para ajuste.'
          : 'Medição ressubmetida para validação.',
    )
    await reload()
    onChanged()
  }

  const canCollect = canManage && ['open', 'collecting', 'reopened'].includes(cycleStatus ?? '')
  const canSubmitReview = canManage && Boolean(readiness?.readyForReview)

  return (
    <section className="skpe-monitoring-collection" aria-label="Coleta governada de medições estratégicas">
      <header>
        <div>
          <span>Coleta governada</span>
          <h3>Medições de KPIs estratégicos</h3>
        </div>
        <strong>{cycleStatus ?? 'status indisponível'}</strong>
      </header>

      <div className="skpe-monitoring-collection-actions">
        {cycleStatus === 'open' || cycleStatus === 'reopened' ? (
          <button type="button" disabled={!canManage || busy} onClick={() => { void transitionCycle('start_collection') }}>
            Iniciar coleta
          </button>
        ) : null}
        {['open', 'collecting', 'reopened'].includes(cycleStatus ?? '') ? (
          <button type="button" disabled={!canSubmitReview || busy} onClick={() => { void transitionCycle('submit_review') }}>
            Submeter ciclo para análise
          </button>
        ) : null}
      </div>
      {readiness?.reviewBlockingIssues?.length ? (
        <div className="skpe-monitoring-tags">
          {readiness.reviewBlockingIssues.map((issue) => (
            <span key={issue.code}>{issue.message}</span>
          ))}
        </div>
      ) : null}

      <div className="skpe-monitoring-package-form-grid">
        <label>
          <span>KPI estratégico</span>
          <select value={selectedIndicatorId} onChange={(event) => setSelectedIndicatorId(event.target.value)} disabled={!canCollect || busy}>
            <option value="">Selecione</option>
            {indicators.map((indicator) => (
              <option key={indicator.id} value={indicator.id}>{indicator.code} · {indicator.name}</option>
            ))}
          </select>
        </label>
        <label><span>Valor medido</span><input type="number" value={measuredValue} onChange={(event) => setMeasuredValue(event.target.value)} disabled={!canCollect || busy} /></label>
        <label><span>Data da medição</span><input type="date" value={measurementDate} onChange={(event) => setMeasurementDate(event.target.value)} disabled={!canCollect || busy} /></label>
        <label>
          <span>Qualidade do dado</span>
          <select value={dataQuality} onChange={(event) => setDataQuality(event.target.value)} disabled={!canCollect || busy}>
            <option value="not_assessed">Não avaliada</option>
            <option value="low">Baixa</option>
            <option value="medium">Média</option>
            <option value="high">Alta</option>
            <option value="verified">Verificada</option>
          </select>
        </label>
      </div>
      <div className="skpe-monitoring-package-form-grid">
        <label><span>Fonte</span><input value={sourceName} onChange={(event) => setSourceName(event.target.value)} disabled={!canCollect || busy} /></label>
        <label><span>Evidência</span><input value={evidenceReference} onChange={(event) => setEvidenceReference(event.target.value)} disabled={!canCollect || busy} /></label>
      </div>
      <label className="skpe-monitoring-package-reason">
        <span>Observações</span>
        <textarea value={notes} onChange={(event) => setNotes(event.target.value)} disabled={!canCollect || busy} />
      </label>
      <label className="skpe-monitoring-package-reason">
        <span>Justificativa da ação *</span>
        <textarea value={reason} onChange={(event) => setReason(event.target.value)} placeholder="Registre a motivação da ação." disabled={busy} />
      </label>

      <div className="skpe-monitoring-collection-actions">
        <button type="button" disabled={!canCollect || busy} onClick={() => { void recordMeasurement() }}>
          Registrar medição
        </button>
      </div>

      <div className="skpe-monitoring-collection-list">
        {indicators.map((indicator) => {
          const measurement = latestByIndicator.get(indicator.id)
          return (
            <article key={indicator.id}>
              <div>
                <strong>{indicator.code} · {indicator.name}</strong>
                <span>{measurement ? `${measurement.measured_value} ${indicator.unit ?? ''}` : 'Sem medição no ciclo'}</span>
              </div>
              <div>
                <span>{measurement?.status ?? 'missing'}</span>
                {measurement?.effective_performance != null ? (
                  <strong>{measurement.effective_performance.toFixed(1)}%</strong>
                ) : null}
              </div>
              {measurement?.status === 'submitted' && canGovern ? (
                <div className="skpe-monitoring-collection-actions">
                  <button type="button" disabled={busy} onClick={() => { void transitionRecord(measurement.id, 'validate') }}>Validar</button>
                  <button type="button" disabled={busy} onClick={() => { void transitionRecord(measurement.id, 'reject') }}>Rejeitar</button>
                </div>
              ) : null}
              {measurement?.status === 'rejected' && canManage ? (
                <div className="skpe-monitoring-collection-actions">
                  <button type="button" disabled={busy} onClick={() => { void transitionRecord(measurement.id, 'resubmit') }}>Ressubmeter</button>
                </div>
              ) : null}
            </article>
          )
        })}
      </div>

      {message ? <div className="skpe-monitoring-state" role="status">{message}</div> : null}
    </section>
  )
}
