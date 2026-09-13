import { useState } from 'react'

type Props = {
  status: string | null
  readyForValidation: boolean
  canSubmit: boolean
  canValidate: boolean
  transitioning: boolean
  message: string
  onTransition: (action: 'submit' | 'validate' | 'return', reason: string, notes: string) => void
}

export function MonitoringPackageWorkflowPanel({
  status,
  readyForValidation,
  canSubmit,
  canValidate,
  transitioning,
  message,
  onTransition,
}: Props) {
  const [reason, setReason] = useState('')
  const [notes, setNotes] = useState('')
  const reasonOk = reason.trim().length >= 10
  const returnOk = reasonOk && notes.trim().length >= 10
  const submitAvailable = status === 'in_elaboration' && readyForValidation && canSubmit
  const validationAvailable = status === 'pending_validation' && canValidate

  return (
    <section className="skpe-monitoring-package-workflow" aria-label="Fluxo de validação FE-08">
      <h3>Fluxo de validação do pacote</h3>
      <p className="skpe-monitoring-empty">
        Submeter, validar e devolver são decisões humanas distintas. Nenhuma transição ocorre automaticamente.
      </p>
      <label className="skpe-monitoring-package-reason">
        <span>Justificativa da transição *</span>
        <textarea
          value={reason}
          onChange={(event) => setReason(event.target.value)}
          placeholder="Registre o fundamento da decisão."
        />
      </label>
      {status === 'pending_validation' ? (
        <label className="skpe-monitoring-package-reason">
          <span>Nota da validação / devolução</span>
          <textarea
            value={notes}
            onChange={(event) => setNotes(event.target.value)}
            placeholder="Registre observações da validação ou os ajustes solicitados."
          />
        </label>
      ) : null}
      {message ? <div className="skpe-monitoring-state" role="status">{message}</div> : null}
      <div className="skpe-monitoring-package-actions">
        {submitAvailable ? (
          <button
            type="button"
            disabled={transitioning || !reasonOk}
            onClick={() => onTransition('submit', reason, '')}
          >
            Submeter para validação
          </button>
        ) : null}
        {validationAvailable ? (
          <>
            <button
              type="button"
              disabled={transitioning || !reasonOk}
              onClick={() => onTransition('validate', reason, notes)}
            >
              Validar pacote
            </button>
            <button
              type="button"
              disabled={transitioning || !returnOk}
              onClick={() => onTransition('return', reason, notes)}
            >
              Devolver para ajustes
            </button>
          </>
        ) : null}
      </div>
      {!submitAvailable && status === 'in_elaboration' && !readyForValidation ? (
        <p className="skpe-monitoring-empty">Resolva as pendências bloqueantes antes de submeter.</p>
      ) : null}
    </section>
  )
}
