import { useState } from 'react'

import {
  canTransitionInitiativeActionTo,
  type InitiativeKanbanCardModel,
  type InitiativeKanbanColumnModel,
  type InitiativeKanbanStatus,
} from '../contracts/initiativeActions'
import { InitiativeKanbanCard } from './InitiativeKanbanCard'

type InitiativeKanbanColumnProps = {
  column: InitiativeKanbanColumnModel
  draggingCard: InitiativeKanbanCardModel | null
  onOpenCard: (
    card: InitiativeKanbanCardModel,
  ) => void
  onDragStart: (
    card: InitiativeKanbanCardModel,
  ) => void
  onDragEnd: () => void
  onRequestTransition: (
    card: InitiativeKanbanCardModel,
    targetStatus: InitiativeKanbanStatus,
  ) => void
}

export function InitiativeKanbanColumn({
  column,
  draggingCard,
  onOpenCard,
  onDragStart,
  onDragEnd,
  onRequestTransition,
}: InitiativeKanbanColumnProps) {
  const [dragActive, setDragActive] =
    useState(false)

  const canDrop =
    draggingCard !== null &&
    draggingCard.status !== column.status &&
    canTransitionInitiativeActionTo(
      draggingCard,
      column.status,
    )

  return (
    <section
      className="initiative-kanban-column"
      data-status={column.status}
      data-drop-allowed={canDrop ? 'true' : 'false'}
      data-drop-active={
        canDrop && dragActive ? 'true' : 'false'
      }
      onDragEnter={(event) => {
        if (!canDrop) return

        event.preventDefault()
        setDragActive(true)
      }}
      onDragOver={(event) => {
        if (!canDrop) return

        event.preventDefault()
        event.dataTransfer.dropEffect = 'move'
      }}
      onDragLeave={(event) => {
        if (
          event.currentTarget.contains(
            event.relatedTarget as Node | null,
          )
        ) {
          return
        }

        setDragActive(false)
      }}
      onDrop={(event) => {
        setDragActive(false)

        if (!draggingCard || !canDrop) {
          return
        }

        event.preventDefault()

        onRequestTransition(
          draggingCard,
          column.status,
        )
      }}
    >
      <header className="initiative-kanban-column__header">
        <h3>{column.label}</h3>
        <span aria-label={`${column.cards.length} ações`}>
          {column.cards.length}
        </span>
      </header>

      <div className="initiative-kanban-column__cards">
        {column.cards.length > 0 ? (
          column.cards.map((card) => (
            <InitiativeKanbanCard
              key={card.actionId}
              card={card}
              onOpen={onOpenCard}
              onDragStart={onDragStart}
              onDragEnd={onDragEnd}
            />
          ))
        ) : (
          <p className="initiative-kanban-column__empty">
            Nenhuma ação neste estágio.
          </p>
        )}
      </div>
    </section>
  )
}