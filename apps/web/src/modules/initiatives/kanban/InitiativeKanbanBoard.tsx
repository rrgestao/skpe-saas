import {
  useCallback,
  useEffect,
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
      {canManageInitiatives ? (
        <div className="initiative-kanban-toolbar">
          <button
            type="button"
            onClick={() =>
              setShowCreateDialog(true)
            }
          >
            Nova ação
          </button>
        </div>
      ) : null}

      <div
        className="initiative-kanban-board"
        aria-label="Kanban de ações da iniciativa"
      >
        {columns.map((column) => (
          <InitiativeKanbanColumn
            key={column.status}
            column={column}
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

      {selectedCard ? (
        <InitiativeActionDrawer
          card={selectedCard}
          onClose={() =>
            setSelectedCard(null)
          }
          onChanged={handleActionChanged}
        />
      ) : null}

      {pendingTransition ? (
        <InitiativeLifecycleDialog
          card={pendingTransition.card}
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