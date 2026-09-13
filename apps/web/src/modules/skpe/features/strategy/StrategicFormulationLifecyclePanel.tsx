import { useState } from 'react'

type Issue = { code: string; severity: string; message: string; affectedCount?: number }

type Props = {
  status: string
  readyForApproval: boolean
  formulationIssues: Issue[]
  monitoringReady: boolean
  monitoringStatus: string | null
  canManage: boolean
  canValidate: boolean
  canApprove: boolean
  transitioning: boolean
  message: string
  onTransition: (action: string, reason: string, notes: string) => void
}

const statusLabels: Record<string, string> = {
  draft: 'Rascunho',
  in_elaboration: 'Em elaboração',
  pending_validation: 'Pendente de validação',
  validated: 'Validada',
  pending_approval: 'Pendente de aprovação',
  approved: 'Aprovada',
  superseded: 'Substituída',
  archived: 'Arquivada',
}
export function StrategicFormulationLifecyclePanel({
  status,
  readyForApproval,
  formulationIssues,
  monitoringReady,
  monitoringStatus,
  canManage,
  canValidate,
  canApprove,
  transitioning,
  message,
  onTransition,
}: Props) {
  const [reason, setReason] = useState('')
  const [notes, setNotes] = useState('')

  const reasonOk = reason.trim().length >= 10
  const notesOk = notes.trim().length >= 10
  const readyToAdvance = readyForApproval && monitoringReady

  const actionButton = (
    action: string,
    label: string,
    enabled: boolean,
    requireNotes = false,
  ) => (
    <button
      type="button"
      disabled={transitioning || !enabled || !reasonOk || (requireNotes && !notesOk)}
      onClick={() => onTransition(action, reason, notes)}
    >
      {label}
    </button>
  )
  return (
    <article className="skpe-formulation-lifecycle" aria-label="Lifecycle governado da Formulação Estratégica">
      <header>
        <div>
          <span>Governança da Formulação</span>
          <h3>{statusLabels[status] ?? status}</h3>
        </div>
      </header>

      <div className="skpe-formulation-lifecycle-status">
        <span>Prontidão metodológica: {readyForApproval ? 'apta' : 'com pendências'}</span>
        <span>FE-08: {monitoringReady ? 'validado' : monitoringStatus ?? 'não configurado'}</span>
      </div>

      {!readyToAdvance && status !== 'draft' && status !== 'in_elaboration' ? (
        <p className="skpe-formulation-lifecycle-warning">
          A Formulação não pode avançar enquanto houver pendências metodológicas ou o pacote FE-08 não estiver validado.
        </p>
      ) : null}

      {formulationIssues.length > 0 ? (
        <div className="skpe-formulation-lifecycle-issues">
          {formulationIssues.slice(0, 8).map((issue) => (
            <span key={issue.code}>{issue.message}</span>
          ))}
        </div>
      ) : null}
      {status !== 'approved' && status !== 'superseded' && status !== 'archived' ? (
        <>
          <label className="skpe-formulation-lifecycle-reason">
            <span>Justificativa da transição *</span>
            <textarea value={reason} onChange={(event) => setReason(event.target.value)} />
          </label>
          {(status === 'pending_validation' || status === 'pending_approval') ? (
            <label className="skpe-formulation-lifecycle-reason">
              <span>Notas da decisão</span>
              <textarea value={notes} onChange={(event) => setNotes(event.target.value)} />
            </label>
          ) : null}
        </>
      ) : null}

      {message ? <div className="skpe-admin-message">{message}</div> : null}

      <div className="skpe-formulation-lifecycle-actions">
        {status === 'draft' ? actionButton('begin_elaboration', 'Iniciar elaboração', canManage) : null}
        {['draft', 'in_elaboration'].includes(status)
          ? actionButton('submit_validation', 'Submeter à validação', canManage && readyToAdvance)
          : null}
        {status === 'pending_validation'
          ? actionButton('validate', 'Validar Formulação', canValidate && readyToAdvance)
          : null}
        {status === 'pending_validation'
          ? actionButton('return_for_adjustments', 'Devolver para ajustes', canValidate, true)
          : null}
        {status === 'validated'
          ? actionButton('submit_approval', 'Submeter à aprovação', canValidate && readyToAdvance)
          : null}
        {status === 'pending_approval'
          ? actionButton('approve', 'Aprovar Formulação', canApprove && readyToAdvance)
          : null}
        {status === 'pending_approval'
          ? actionButton('return_for_adjustments', 'Devolver para ajustes', canApprove, true)
          : null}
      </div>
    </article>
  )
}
