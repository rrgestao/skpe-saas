import { useEffect, useState } from 'react'

import { supabase } from '../../../../lib/supabase'
import { translateBackendMessage } from '../../../../shared/i18n/ptBR'
import type {
  JourneyStatus,
} from '../../contracts/journey'
import {
  isJourneyStatusChangeDraftDirty,
  validateJourneyStatusChangeReason,
} from './journeyItemStatusChange'

import './JourneyItemStatusDialog.css'

type JourneyItemStatusDialogProps = {
  itemId: string
  itemCode: string
  itemName: string
  currentStatus: JourneyStatus
  targetStatus: JourneyStatus
  targetProgress: number
  onClose: () => void
  onSaved: () => Promise<void> | void
}

function getStatusLabel(status: JourneyStatus) {
  const labels: Record<JourneyStatus, string> = {
    not_started: 'Não iniciado',
    in_progress: 'Em andamento',
    blocked: 'Bloqueado',
    pending_validation: 'Aguardando validação',
    completed: 'Concluído',
    cancelled: 'Cancelado',
  }

  return labels[status]
}

export function JourneyItemStatusDialog({
  itemId,
  itemCode,
  itemName,
  currentStatus,
  targetStatus,
  targetProgress,
  onClose,
  onSaved,
}: JourneyItemStatusDialogProps) {
  const [changeReason, setChangeReason] =
    useState('')
  const [saving, setSaving] = useState(false)
  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)

  const draftDirty =
    isJourneyStatusChangeDraftDirty(
      changeReason,
    )

  const closeLocked =
    saving || draftDirty

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (
        event.key === 'Escape' &&
        !closeLocked
      ) {
        onClose()
      }
    }

    window.addEventListener(
      'keydown',
      handleKeyDown,
    )

    return () =>
      window.removeEventListener(
        'keydown',
        handleKeyDown,
      )
  }, [closeLocked, onClose])

  async function handleSubmit() {
    const validation =
      validateJourneyStatusChangeReason(
        changeReason,
      )

    if (!validation.valid) {
      setErrorMessage(validation.error)
      return
    }

    setSaving(true)
    setErrorMessage(null)

    const { error } = await supabase.rpc(
      'set_skpe_journey_item_status',
      {
        target_item_id: itemId,
        target_status: targetStatus,
        target_progress: targetProgress,
        change_reason: validation.reason,
      },
    )

    if (error) {
      setErrorMessage(
        translateBackendMessage(error.message),
      )
      setSaving(false)
      return
    }

    await onSaved()
  }

  return (
    <div
      className="skpe-journey-status-dialog-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (
          event.target === event.currentTarget &&
          !closeLocked
        ) {
          onClose()
        }
      }}
    >
      <section
        className="skpe-journey-status-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="skpe-journey-status-dialog-title"
      >
        <header>
          <div>
            <span>Alteração governada da Jornada</span>
            <h3 id="skpe-journey-status-dialog-title">
              Alterar situação do item
            </h3>
            <p>
              {itemCode} · {itemName}
            </p>
          </div>

          <button
            type="button"
            onClick={onClose}
            disabled={closeLocked}
          >
            Fechar
          </button>
        </header>

        <div className="skpe-journey-status-dialog-summary">
          <div>
            <span>Situação atual</span>
            <strong>
              {getStatusLabel(currentStatus)}
            </strong>
          </div>

          <div>
            <span>Nova situação</span>
            <strong>
              {getStatusLabel(targetStatus)}
            </strong>
          </div>

          <div>
            <span>Progresso resultante</span>
            <strong>{targetProgress}%</strong>
          </div>
        </div>

        <label>
          <span>Justificativa *</span>
          <textarea
            value={changeReason}
            onChange={(event) =>
              setChangeReason(event.target.value)
            }
            rows={4}
            disabled={saving}
            placeholder="Registre o motivo da alteração para a trilha de auditoria."
          />
        </label>

        {draftDirty ? (
          <p className="skpe-journey-status-dialog-note">
            Confirme a alteração ou use Cancelar
            para descartar o rascunho antes de
            fechar por ESC, backdrop ou pelo botão
            Fechar.
          </p>
        ) : null}

        {errorMessage ? (
          <div
            className="skpe-journey-status-dialog-error"
            role="alert"
          >
            {errorMessage}
          </div>
        ) : null}

        <footer>
          <button
            type="button"
            onClick={onClose}
            disabled={saving}
          >
            Cancelar
          </button>

          <button
            type="button"
            className="is-primary"
            onClick={() => void handleSubmit()}
            disabled={saving}
          >
            {saving
              ? 'Salvando...'
              : 'Confirmar alteração'}
          </button>
        </footer>
      </section>
    </div>
  )
}