import {
  useEffect,
  useState,
} from 'react'

import {
  canUpdateInitiativeActionProgress,
  initiativeActionLifecycleLabels,
  initiativeActionPriorityLabels,
  type InitiativeKanbanCardModel,
} from '../contracts/initiativeActions'
import {
  updateInitiativeActionProgress,
} from '../data/initiativeActionsData'
import {
  InitiativeLifecycleDialog,
} from './InitiativeLifecycleDialog'

type InitiativeActionDrawerProps = {
  card: InitiativeKanbanCardModel
  onClose: () => void
  onChanged: () => Promise<void>
}

function formatProgress(value: number) {
  return `${new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 1,
  }).format(value)}%`
}

function formatDate(value: string | null) {
  if (!value) return 'Não definida'

  const [year, month, day] =
    value.slice(0, 10).split('-')

  if (!year || !month || !day) {
    return value
  }

  return `${day}/${month}/${year}`
}

export function InitiativeActionDrawer({
  card,
  onClose,
  onChanged,
}: InitiativeActionDrawerProps) {
  const [showLifecycle, setShowLifecycle] =
    useState(false)
  const [progress, setProgress] = useState(
    String(card.officialProgress),
  )
  const [changeReason, setChangeReason] =
    useState('')
  const [savingProgress, setSavingProgress] =
    useState(false)
  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)

  const progressEditable =
    canUpdateInitiativeActionProgress(
      card.status,
    )

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (
        event.key === 'Escape' &&
        !showLifecycle &&
        !savingProgress
      ) {
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
  }, [
    onClose,
    savingProgress,
    showLifecycle,
  ])

  async function handleProgressUpdate() {
    const parsedProgress = Number(progress)
    const reason = changeReason.trim()

    if (
      !Number.isFinite(parsedProgress) ||
      parsedProgress < 0 ||
      parsedProgress >= 100
    ) {
      setErrorMessage(
        'Informe progresso entre 0 e menor que 100. A conclusão ocorre pela situação da ação.',
      )
      return
    }

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa com pelo menos 10 caracteres.',
      )
      return
    }

    if (
      parsedProgress === card.officialProgress
    ) {
      setErrorMessage(
        'Informe um progresso diferente do valor oficial atual.',
      )
      return
    }

    setSavingProgress(true)
    setErrorMessage(null)

    try {
      await updateInitiativeActionProgress(
        card.actionId,
        parsedProgress,
        reason,
      )

      await onChanged()
      onClose()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível atualizar o progresso.',
      )
    } finally {
      setSavingProgress(false)
    }
  }

  return (
    <>
      <div
        className="initiative-action-drawer-backdrop"
        role="presentation"
        onMouseDown={(event) => {
          if (
            event.target === event.currentTarget &&
            !savingProgress
          ) {
            onClose()
          }
        }}
      >
        <aside
          className="initiative-action-drawer"
          role="dialog"
          aria-modal="true"
          aria-labelledby="initiative-action-drawer-title"
        >
          <header className="initiative-action-drawer__header">
            <div>
              <span>
                {card.actionType === 'milestone'
                  ? 'Marco'
                  : 'Ação'}
              </span>
              <h2 id="initiative-action-drawer-title">
                {card.code} — {card.name}
              </h2>
            </div>

            <button
              type="button"
              onClick={onClose}
              disabled={savingProgress}
              aria-label="Fechar detalhes da ação"
            >
              Fechar
            </button>
          </header>

          {card.description ? (
            <p className="initiative-action-drawer__description">
              {card.description}
            </p>
          ) : null}

          <dl className="initiative-action-drawer__facts">
            <div>
              <dt>Situação</dt>
              <dd>
                {
                  initiativeActionLifecycleLabels[
                    card.status
                  ]
                }
              </dd>
            </div>

            <div>
              <dt>Prioridade</dt>
              <dd>
                {
                  initiativeActionPriorityLabels[
                    card.priority
                  ]
                }
              </dd>
            </div>

            <div>
              <dt>Início planejado</dt>
              <dd>
                {formatDate(
                  card.plannedStartDate,
                )}
              </dd>
            </div>

            <div>
              <dt>Prazo planejado</dt>
              <dd>
                {formatDate(
                  card.plannedDueDate,
                )}
              </dd>
            </div>

            <div>
              <dt>Progresso oficial</dt>
              <dd>
                {formatProgress(
                  card.officialProgress,
                )}
              </dd>
            </div>

            <div>
              <dt>Progresso calculado</dt>
              <dd>
                {card.calculatedProgress === null
                  ? 'Não aplicável'
                  : formatProgress(
                      card.calculatedProgress,
                    )}
              </dd>
            </div>
          </dl>

          <section className="initiative-action-drawer__section">
            <h3>Lifecycle</h3>
            <p>
              Você pode alterar a situação por aqui
              ou arrastando o cartão para uma coluna
              permitida. Nos dois casos a confirmação
              governada é obrigatória.
            </p>

            <button
              type="button"
              onClick={() =>
                setShowLifecycle(true)
              }
            >
              Alterar situação
            </button>
          </section>

          <section className="initiative-action-drawer__section">
            <h3>Progresso oficial</h3>

            {progressEditable ? (
              <>
                <label className="initiative-action-field">
                  <span>
                    Progresso de 0 a menor que 100
                  </span>
                  <input
                    type="number"
                    min="0"
                    max="99.99"
                    step="0.1"
                    value={progress}
                    onChange={(event) =>
                      setProgress(
                        event.target.value,
                      )
                    }
                    disabled={savingProgress}
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
                      setChangeReason(
                        event.target.value,
                      )
                    }
                    disabled={savingProgress}
                  />
                </label>

                <button
                  type="button"
                  onClick={() =>
                    void handleProgressUpdate()
                  }
                  disabled={savingProgress}
                >
                  {savingProgress
                    ? 'Salvando...'
                    : 'Atualizar progresso'}
                </button>
              </>
            ) : (
              <p>
                O progresso só pode ser atualizado
                quando a ação estiver em execução,
                em espera ou bloqueada.
              </p>
            )}
          </section>

          {card.hasEligibleChildren ? (
            <p className="initiative-action-drawer__note">
              Esta ação consolida ações subordinadas.
              O progresso calculado permanece derivado
              pelo roll-up governado.
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
        </aside>
      </div>

      {showLifecycle ? (
        <InitiativeLifecycleDialog
          card={card}
          onClose={() =>
            setShowLifecycle(false)
          }
          onChanged={onChanged}
        />
      ) : null}
    </>
  )
}