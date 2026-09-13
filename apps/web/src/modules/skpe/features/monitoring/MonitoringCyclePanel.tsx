import { useEffect, useState } from 'react'

export type MonitoringCycleOption = {
  id: string
  code: string
  name: string
  cycleType: string
  periodStart: string
  periodEnd: string
  status: string
}

type Props = {
  cycles: MonitoringCycleOption[]
  selectedCycleId: string | null
  selectionLocked: boolean
  formulationStatus: string | null
  packageStatus: string | null
  canOpen: boolean
  defaultCycleType: string
  opening: boolean
  message: string
  onSelect: (cycleId: string | null) => void
  onOpen: (payload: {
    code: string
    name: string
    cycleType: string
    periodStart: string
    periodEnd: string
    cutoffDate: string | null
    reason: string
  }) => void
}
export function MonitoringCyclePanel({
  cycles,
  selectedCycleId,
  selectionLocked,
  formulationStatus,
  packageStatus,
  canOpen,
  defaultCycleType,
  opening,
  message,
  onSelect,
  onOpen,
}: Props) {
  const [code, setCode] = useState('')
  const [name, setName] = useState('')
  const [cycleType, setCycleType] = useState(defaultCycleType || 'monthly')
  const [periodStart, setPeriodStart] = useState('')
  const [periodEnd, setPeriodEnd] = useState('')
  const [cutoffDate, setCutoffDate] = useState('')
  const [reason, setReason] = useState('')

  useEffect(() => {
    setCycleType(defaultCycleType || 'monthly')
  }, [defaultCycleType])

  const prerequisitesOk = formulationStatus === 'approved' && packageStatus === 'validated' && canOpen
  const formOk = code.trim().length > 0 && name.trim().length > 0 && periodStart && periodEnd && periodStart <= periodEnd && reason.trim().length >= 10

  return (
    <section className="skpe-monitoring-cycle-panel" aria-label="Ciclos de monitoramento FE-08">
      <h3>Ciclos de monitoramento</h3>
      <label>
        <span>Ciclo em análise</span>
        <select
          value={selectedCycleId ?? ''}
          disabled={selectionLocked}
          onChange={(event) => onSelect(event.target.value || null)}
        >
          <option value="">Nenhum ciclo selecionado</option>
          {cycles.map((cycle) => (
            <option key={cycle.id} value={cycle.id}>
              {cycle.code} · {cycle.name} · {cycle.status}
            </option>
          ))}
        </select>
      </label>

      {!prerequisitesOk ? (
        <p className="skpe-monitoring-empty">
          Abertura bloqueada: exige Formulação aprovada, pacote FE-08 validado e autoridade de monitoramento.
        </p>
      ) : (
        <div className="skpe-monitoring-cycle-form">
          <label><span>Código *</span><input value={code} onChange={(event) => setCode(event.target.value)} /></label>
          <label><span>Nome *</span><input value={name} onChange={(event) => setName(event.target.value)} /></label>
          <label><span>Tipo</span><select value={cycleType} onChange={(event) => setCycleType(event.target.value)}><option value="monthly">Mensal</option><option value="quarterly">Trimestral</option><option value="semester">Semestral</option><option value="annual">Anual</option><option value="custom">Customizado</option></select></label>
          <label><span>Início *</span><input type="date" value={periodStart} onChange={(event) => setPeriodStart(event.target.value)} /></label>
          <label><span>Fim *</span><input type="date" value={periodEnd} onChange={(event) => setPeriodEnd(event.target.value)} /></label>
          <label><span>Data de corte</span><input type="date" value={cutoffDate} onChange={(event) => setCutoffDate(event.target.value)} /></label>
          <label className="skpe-monitoring-cycle-reason"><span>Justificativa *</span><textarea value={reason} onChange={(event) => setReason(event.target.value)} /></label>
          <button
            type="button"
            disabled={opening || !formOk}
            onClick={() => onOpen({
              code: code.trim(),
              name: name.trim(),
              cycleType,
              periodStart,
              periodEnd,
              cutoffDate: cutoffDate || null,
              reason: reason.trim(),
            })}
          >
            {opening ? 'Abrindo...' : 'Abrir ciclo de monitoramento'}
          </button>
        </div>
      )}

      {message ? <div className="skpe-monitoring-state" role="status">{message}</div> : null}
    </section>
  )
}
