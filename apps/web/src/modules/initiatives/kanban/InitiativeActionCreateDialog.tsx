import {
  useEffect,
  useState,
} from 'react'

import {
  type InitiativeActionPriority,
  type InitiativeActionType,
} from '../contracts/initiativeActions'
import {
  createInitiativeAction,
} from '../data/initiativeActionsData'
import {
  isInitiativeActionCreateDraftDirty,
} from '../contracts/initiativeActionDraftGovernance'

type InitiativeActionCreateDialogProps = {
  initiativeId: string
  onClose: () => void
  onChanged: () => Promise<void>
}

export function InitiativeActionCreateDialog({
  initiativeId,
  onClose,
  onChanged,
}: InitiativeActionCreateDialogProps) {
  const [code, setCode] = useState('')
  const [name, setName] = useState('')
  const [description, setDescription] =
    useState('')
  const [actionType, setActionType] =
    useState<InitiativeActionType>('action')
  const [priority, setPriority] =
    useState<InitiativeActionPriority>('medium')
  const [changeReason, setChangeReason] =
    useState('')
  const [saving, setSaving] = useState(false)
  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)

  const draftDirty =
    isInitiativeActionCreateDraftDirty({
      code,
      name,
      description,
      actionType,
      priority,
      changeReason,
    })

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
    const normalizedCode = code.trim()
    const normalizedName = name.trim()
    const reason = changeReason.trim()

    if (!normalizedCode || !normalizedName) {
      setErrorMessage(
        'Informe o código e o nome da ação.',
      )
      return
    }

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa com pelo menos 10 caracteres.',
      )
      return
    }

    setSaving(true)
    setErrorMessage(null)

    try {
      await createInitiativeAction({
        initiativeId,
        code: normalizedCode,
        name: normalizedName,
        description:
          description.trim() || null,
        actionType,
        priority,
        changeReason: reason,
      })

      await onChanged()
      onClose()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível criar a ação.',
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
        aria-labelledby="initiative-action-create-title"
      >
        <header className="initiative-action-dialog__header">
          <div>
            <span>Cadastro governado</span>
            <h3 id="initiative-action-create-title">
              Nova ação
            </h3>
          </div>

          <button
            type="button"
            onClick={onClose}
            disabled={closeLocked}
          >
            Fechar
          </button>
        </header>

        <label className="initiative-action-field">
          <span>Código *</span>
          <input
            value={code}
            onChange={(event) =>
              setCode(event.target.value)
            }
            disabled={saving}
            placeholder="Ex.: A-01"
          />
        </label>

        <label className="initiative-action-field">
          <span>Nome *</span>
          <input
            value={name}
            onChange={(event) =>
              setName(event.target.value)
            }
            disabled={saving}
          />
        </label>

        <label className="initiative-action-field">
          <span>Tipo</span>
          <select
            value={actionType}
            onChange={(event) =>
              setActionType(
                event.target
                  .value as InitiativeActionType,
              )
            }
            disabled={saving}
          >
            <option value="action">Ação</option>
            <option value="milestone">Marco</option>
          </select>
        </label>

        <label className="initiative-action-field">
          <span>Prioridade</span>
          <select
            value={priority}
            onChange={(event) =>
              setPriority(
                event.target
                  .value as InitiativeActionPriority,
              )
            }
            disabled={saving}
          >
            <option value="low">Baixa</option>
            <option value="medium">Média</option>
            <option value="high">Alta</option>
            <option value="critical">Crítica</option>
          </select>
        </label>

        <label className="initiative-action-field">
          <span>Descrição</span>
          <textarea
            rows={4}
            value={description}
            onChange={(event) =>
              setDescription(event.target.value)
            }
            disabled={saving}
          />
        </label>

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

        {draftDirty ? (
          <p className="initiative-action-drawer__note">
            Salve a nova ação ou use Cancelar para descartar o rascunho antes
            de fechar por ESC, backdrop ou pelo botão Fechar.
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
            disabled={saving}
          >
            {saving
              ? 'Salvando...'
              : 'Salvar ação'}
          </button>
        </footer>
      </section>
    </div>
  )
}