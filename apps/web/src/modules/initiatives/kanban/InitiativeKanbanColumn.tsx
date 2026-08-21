import type {
  InitiativeKanbanColumnModel,
} from '../contracts/initiativeActions'
import { InitiativeKanbanCard } from './InitiativeKanbanCard'

type InitiativeKanbanColumnProps = {
  column: InitiativeKanbanColumnModel
}

export function InitiativeKanbanColumn({
  column,
}: InitiativeKanbanColumnProps) {
  return (
    <section
      className="initiative-kanban-column"
      data-status={column.status}
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