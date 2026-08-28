import {
  useEffect,
  useMemo,
  useState,
} from 'react'

import {
  getAllowedInitiativeActionTransitions,
  initiativeActionLifecycleLabels,
  type InitiativeActionLifecycle,
  type InitiativeKanbanCardModel,
} from '../contracts/initiativeActions'
import {
  transitionInitiativeAction,
} from '../data/initiativeActionsData'

type InitiativeLifecycleDialogProps = {
  card: InitiativeKanbanCardModel
  canManageInitiatives: boolean
  requestedStatus?: InitiativeActionLifecycle | null
  onClose: () => void
  onChanged: () => Promise<void>
}

export function InitiativeLifecycleDialog({
  card,
  canManageInitiatives,
  requestedStatus = null,
  onClose,
  onChanged,
}: InitiativeLifecycleDialogProps) {
  const transitions = useMemo(
    () =>
      getAllowedInitiativeActionTransitions(
        card,
      ),
    [card],
  )

  const defaultStatus =
    requestedStatus &&
    transitions.includes(requestedStatus)
      ? requestedStatus
      : transitions[0] ?? card.status

  const [targetStatus, setTargetStatus] =
    useState<InitiativeActionLifecycle>(
      defaultStatus,
    )
  const [changeReason, setChangeReason] =
    useState('')
  const [saving, setSaving] = useState(false)
  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)

  const isDropConfirmation =
    requestedStatus !== null

  const draftDirty =
    changeReason.trim().length > 0 ||
    (!isDropConfirmation &&
      targetStatus !== defaultStatus)

  const closeLocked = saving || draftDirty

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape' && !closeLocked) {
        onClose()
      }
    }

    window.addEventListener(
      'keydown',
      handleKeyDown,
    )

    return () => {
      window.removeEventListener(
        'keydown',
        handleKeyDown,
      )
    }
  }, [closeLocked, onClose])

  async function handleSubmit() {
    if (!canManageInitiatives) {
      setErrorMessage(
        'Você não possui permissão para alterar o lifecycle desta ação.',
      )
      return
    }

    const reason = changeReason.trim()

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa com pelo menos 10 caracteres.',
      )
      return
    }

    if (!transitions.includes(targetStatus)) {
      setErrorMessage(
        'A transição selecionada não está disponível para esta ação.',
      )
      return
    }

    setSaving(true)
    setErrorMessage(null)

    try {
      await transitionInitiativeAction(
        card.actionId,
        targetStatus,
        reason,
      )

      await onChanged()
      onClose()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível alterar a situação da ação.',
      )
    } finally {
      setSaving(false)
    }
  }

  return (
    <div
      className="initiative-action-dialog-backdrop"
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
        className="initiative-action-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="initiative-action-lifecycle-title"
      >
        <header className="initiative-action-dialog__header">
          <div>
            <span>Lifecycle governado</span>
            <h3 id="initiative-action-lifecycle-title">
              {isDropConfirmation
                ? 'Confirmar movimentação'
                : 'Alterar situação'}
            </h3>
          </div>

          <button
            type="button"
            onClick={onClose}
            disabled={closeLocked}
            aria-label="Fechar alteração de situação"
          >
            Fechar
          </button>
        </header>

        <p>
          {card.code} — {card.name}
        </p>

        {!canManageInitiatives ? (
          <p className="initiative-action-drawer__note">
            Modo de consulta. Alterar o lifecycle exige permissão de gestão
            de iniciativas.
          </p>
        ) : null}

        {transitions.length === 0 ? (
          <p>
            Não há transições disponíveis para esta ação.
          </p>
        ) : isDropConfirmation ? (
          <div className="initiative-action-transition-summary">
            <span>Movimentação solicitada</span>
            <strong>
              {
                initiativeActionLifecycleLabels[
                  card.status
                ]
              }
              {' → '}
              {
                initiativeActionLifecycleLabels[
                  targetStatus
                ]
              }
            </strong>
            <p>
              O cartão somente será movimentado
              depois da confirmação e da aceitação
              da transição pelo contrato governado.
            </p>
          </div>
        ) : (
          <label className="initiative-action-field">
            <span>Nova situação</span>
            <select
              value={targetStatus}
              onChange={(event) =>
                setTargetStatus(
                  event.target
                    .value as InitiativeActionLifecycle,
                )
              }
              disabled={saving || !canManageInitiatives}
            >
              {transitions.map((status) => (
                <option
                  key={status}
                  value={status}
                >
                  {
                    initiativeActionLifecycleLabels[
                      status
                    ]
                  }
                </option>
              ))}
            </select>
          </label>
        )}

        {transitions.length > 0 ? (
          <label className="initiative-action-field">
            <span>
              Justificativa para auditoria *
            </span>
            <textarea
              value={changeReason}
              onChange={(event) =>
                setChangeReason(
                  event.target.value,
                )
              }
              disabled={saving || !canManageInitiatives}
              rows={4}
            />
          </label>
        ) : null}

        {draftDirty ? (
          <p className="initiative-action-drawer__note">
            Confirme a alteração ou use Cancelar para descartar o rascunho
            antes de fechar por ESC, backdrop ou pelo botão Fechar.
          </p>
        ) : null}

        {errorMessage ? (
          <div
            className="initiative-action-message initiative-action-message--error"
            role="alert"
          >
            {errorMessage}
          </div>
        ) : null}

        <footer className="initiative-action-dialog__actions">
          <button
            type="button"
            onClick={onClose}
            disabled={saving}
          >
            Cancelar
          </button>

          <button
            type="button"
            onClick={() => void handleSubmit()}
            disabled={
              saving ||
              !canManageInitiatives ||
              transitions.length === 0
            }
          >
            {saving
              ? 'Salvando...'
              : isDropConfirmation
                ? 'Confirmar movimentação'
                : 'Confirmar alteração'}
          </button>
        </footer>
      </section>
    </div>
  )
}