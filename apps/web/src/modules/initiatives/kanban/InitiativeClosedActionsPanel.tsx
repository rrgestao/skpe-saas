import {
  useEffect,
  useState,
} from 'react'

import {
  loadCancelledInitiativeActions,
  transitionInitiativeAction,
  type CancelledInitiativeAction,
} from '../data/initiativeActionsData'

type InitiativeClosedActionsPanelProps = {
  initiativeId: string
  onChanged: () => Promise<void>
}

export function InitiativeClosedActionsPanel({
  initiativeId,
  onChanged,
}: InitiativeClosedActionsPanelProps) {
  const [actions, setActions] =
    useState<CancelledInitiativeAction[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)
  const [archiveAction, setArchiveAction] =
    useState<CancelledInitiativeAction | null>(
      null,
    )
  const [changeReason, setChangeReason] =
    useState('')
  const [saving, setSaving] = useState(false)

  async function loadClosedActions() {
    setLoading(true)
    setErrorMessage(null)

    try {
      setActions(
        await loadCancelledInitiativeActions(
          initiativeId,
        ),
      )
    } catch (error) {
      setActions([])
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível carregar as ações canceladas.',
      )
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void loadClosedActions()
  }, [initiativeId])

  async function handleArchive() {
    if (!archiveAction) return

    const reason = changeReason.trim()

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa com pelo menos 10 caracteres.',
      )
      return
    }

    setSaving(true)
    setErrorMessage(null)

    try {
      await transitionInitiativeAction(
        archiveAction.id,
        'archived',
        reason,
      )

      setArchiveAction(null)
      setChangeReason('')
      await loadClosedActions()
      await onChanged()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível arquivar a ação.',
      )
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <section className="initiative-action-drawer__section">
        <h3>Ações encerradas</h3>
        <p>Carregando ações canceladas...</p>
      </section>
    )
  }

  return (
    <section className="initiative-action-drawer__section">
      <h3>Ações encerradas</h3>

      <p>
        Ações canceladas permanecem fora das cinco colunas operacionais e
        podem ser arquivadas conforme o ciclo de vida governado.
      </p>

      {actions.length === 0 ? (
        <p>Nenhuma ação cancelada pendente de arquivamento.</p>
      ) : (
        actions.map((action) => (
          <div
            key={action.id}
            className="initiative-action-transition-summary"
          >
            <strong>
              {action.code} — {action.name}
            </strong>

            <span>
              Cancelada · Progresso {action.progress}%
            </span>

            <button
              type="button"
              onClick={() => {
                setArchiveAction(action)
                setChangeReason('')
                setErrorMessage(null)
              }}
              disabled={saving}
            >
              Arquivar ação
            </button>
          </div>
        ))
      )}

      {archiveAction ? (
        <div className="initiative-action-transition-summary">
          <strong>
            Arquivar {archiveAction.code}
          </strong>

          <label className="initiative-action-field">
            <span>
              Justificativa para auditoria *
            </span>
            <textarea
              rows={4}
              value={changeReason}
              onChange={(event) =>
                setChangeReason(event.target.value)
              }
              disabled={saving}
            />
          </label>

          <div className="initiative-action-dialog__actions">
            <button
              type="button"
              onClick={() => {
                setArchiveAction(null)
                setChangeReason('')
                setErrorMessage(null)
              }}
              disabled={saving}
            >
              Cancelar
            </button>

            <button
              type="button"
              onClick={() => void handleArchive()}
              disabled={saving}
            >
              {saving
                ? 'Arquivando...'
                : 'Confirmar arquivamento'}
            </button>
          </div>
        </div>
      ) : null}

      {errorMessage ? (
        <div
          className="initiative-action-message initiative-action-message--error"
          role="alert"
        >
          {errorMessage}
        </div>
      ) : null}
    </section>
  )
}