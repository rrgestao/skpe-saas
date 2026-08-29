import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react'

import type {
  InitiativeKanbanCardModel,
  InitiativeKanbanColumnModel,
  InitiativeKanbanStatus,
} from '../contracts/initiativeActions'
import {
  loadInitiativeActionBoard,
} from '../data/initiativeActionsData'
import {
  InitiativeActionDrawer,
} from './InitiativeActionDrawer'
import {
  InitiativeActionCreateDialog,
} from './InitiativeActionCreateDialog'
import {
  InitiativeClosedActionsPanel,
} from './InitiativeClosedActionsPanel'
import {
  InitiativeKanbanColumn,
} from './InitiativeKanbanColumn'
import {
  InitiativeLifecycleDialog,
} from './InitiativeLifecycleDialog'

import './InitiativeKanbanBoard.css'

type InitiativeKanbanBoardProps = {
  initiativeId: string
  canManageInitiatives: boolean
  initialActionId?: string | null
}

type PendingTransition = {
  card: InitiativeKanbanCardModel
  targetStatus: InitiativeKanbanStatus
}

export function InitiativeKanbanBoard({
  initiativeId,
  canManageInitiatives,
  initialActionId = null,
}: InitiativeKanbanBoardProps) {
  const [columns, setColumns] = useState<
    InitiativeKanbanColumnModel[]
  >([])
  const [selectedCard, setSelectedCard] =
    useState<InitiativeKanbanCardModel | null>(
      null,
    )
  const [draggingCard, setDraggingCard] =
    useState<InitiativeKanbanCardModel | null>(
      null,
    )
  const [
    pendingTransition,
    setPendingTransition,
  ] = useState<PendingTransition | null>(null)

  const [loading, setLoading] = useState(true)
  const [showCreateDialog, setShowCreateDialog] =
    useState(false)
  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)

  const activeActionCount = useMemo(
    () =>
      columns.reduce(
        (total, column) => total + column.cards.length,
        0,
      ),
    [columns],
  )

  const loadBoard = useCallback(async () => {
    setLoading(true)
    setErrorMessage(null)

    try {
      const nextColumns =
        await loadInitiativeActionBoard(
          initiativeId,
        )

      setColumns(nextColumns)

      if (initialActionId) {
        const initialCard = nextColumns
          .flatMap((column) => column.cards)
          .find((card) => card.actionId === initialActionId)

        setSelectedCard(initialCard ?? null)
      }
    } catch (error) {
      setColumns([])
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível carregar o Kanban.',
      )
    } finally {
      setLoading(false)
    }
  }, [initiativeId, initialActionId])

  useEffect(() => {
    void loadBoard()
  }, [loadBoard])

  useEffect(() => {
    setSelectedCard(null)
    setDraggingCard(null)
    setPendingTransition(null)
    setShowCreateDialog(false)
  }, [initiativeId])

  async function handleActionChanged() {
    await loadBoard()
    setSelectedCard(null)
    setPendingTransition(null)
  }

  function requestTransition(
    card: InitiativeKanbanCardModel,
    targetStatus: InitiativeKanbanStatus,
  ) {
    setDraggingCard(null)
    setPendingTransition({
      card,
      targetStatus,
    })
  }

  if (loading) {
    return (
      <div className="initiative-kanban-state">
        Carregando ações…
      </div>
    )
  }

  if (errorMessage) {
    return (
      <div
        className="initiative-kanban-state initiative-kanban-state--error"
        role="alert"
      >
        {errorMessage}
      </div>
    )
  }

  return (
    <>
      <section
        className="initiative-kanban-guide"
        aria-label="Como usar o quadro de ações"
      >
        <div className="initiative-kanban-guide__copy">
          <p className="initiative-kanban-guide__eyebrow">
            Gestão das ações
          </p>
          <h3>Do planejamento à execução, no mesmo registro</h3>
          <p>
            Cada cartão é uma ação real desta iniciativa. Abra para consultar
            ou editar detalhes e, quando permitido, mova o cartão para avançar
            seu ciclo de vida governado. O Kanban não cria uma cópia da ação.
          </p>
        </div>

        <div className="initiative-kanban-guide__actions">
          <span className="initiative-kanban-guide__count">
            <strong>{activeActionCount}</strong>
            {activeActionCount === 1
              ? ' ação no quadro'
              : ' ações no quadro'}
          </span>

          {canManageInitiatives ? (
            <button
              type="button"
              className="initiative-kanban-primary-action"
              onClick={() =>
                setShowCreateDialog(true)
              }
            >
              Criar ação
            </button>
          ) : null}
        </div>
      </section>

      {activeActionCount === 0 ? (
        <section className="initiative-kanban-empty">
          <h3>Nenhuma ação ativa nesta iniciativa</h3>
          <p>
            O quadro ficará organizado por etapa de execução assim que a
            iniciativa possuir ações. A mesma ação poderá ser acompanhada e
            atualizada aqui sem duplicação de dados.
          </p>
          {canManageInitiatives ? (
            <button
              type="button"
              className="initiative-kanban-primary-action"
              onClick={() =>
                setShowCreateDialog(true)
              }
            >
              Criar primeira ação
            </button>
          ) : null}
        </section>
      ) : (
        <div
          className="initiative-kanban-board"
          aria-label="Kanban de ações da iniciativa"
        >
          {columns.map((column) => (
            <InitiativeKanbanColumn
              key={column.status}
              column={column}
              canManageInitiatives={canManageInitiatives}
              draggingCard={draggingCard}
              onOpenCard={setSelectedCard}
              onDragStart={setDraggingCard}
              onDragEnd={() =>
                setDraggingCard(null)
              }
              onRequestTransition={
                requestTransition
              }
            />
          ))}
        </div>
      )}

      {selectedCard ? (
        <InitiativeActionDrawer
          card={selectedCard}
          canManageInitiatives={canManageInitiatives}
          onClose={() =>
            setSelectedCard(null)
          }
          onChanged={handleActionChanged}
        />
      ) : null}

      {pendingTransition ? (
        <InitiativeLifecycleDialog
          card={pendingTransition.card}
          canManageInitiatives={canManageInitiatives}
          requestedStatus={
            pendingTransition.targetStatus
          }
          onClose={() =>
            setPendingTransition(null)
          }
          onChanged={handleActionChanged}
        />
      ) : null}

      {showCreateDialog ? (
        <InitiativeActionCreateDialog
          initiativeId={initiativeId}
          onClose={() =>
            setShowCreateDialog(false)
          }
          onChanged={loadBoard}
        />
      ) : null}
      {canManageInitiatives ? (
        <InitiativeClosedActionsPanel
          initiativeId={initiativeId}
          onChanged={loadBoard}
        />
      ) : null}
    </>
  )
}