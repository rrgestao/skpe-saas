import {
  initiativeActionPriorityLabels,
  type InitiativeKanbanCardModel,
} from '../contracts/initiativeActions'

type InitiativeKanbanCardProps = {
  card: InitiativeKanbanCardModel
  onOpen: (
    card: InitiativeKanbanCardModel,
  ) => void
  onDragStart: (
    card: InitiativeKanbanCardModel,
  ) => void
  onDragEnd: () => void
}

function formatProgress(value: number) {
  return `${new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 1,
  }).format(value)}%`
}

function formatDate(value: string | null) {
  if (!value) return null

  const [year, month, day] =
    value.slice(0, 10).split('-')

  if (!year || !month || !day) {
    return value
  }

  return `${day}/${month}/${year}`
}

export function InitiativeKanbanCard({
  card,
  onOpen,
  onDragStart,
  onDragEnd,
}: InitiativeKanbanCardProps) {
  const plannedDueDate =
    formatDate(card.plannedDueDate)

  return (
    <article
      className="initiative-kanban-card"
      data-status={card.status}
      data-action-id={card.actionId}
      draggable
      onDragStart={(event) => {
        event.dataTransfer.effectAllowed = 'move'
        event.dataTransfer.setData(
          'text/plain',
          card.actionId,
        )
        onDragStart(card)
      }}
      onDragEnd={onDragEnd}
    >
      <div className="initiative-kanban-card__header">
        <span className="initiative-kanban-card__type">
          {card.actionType === 'milestone'
            ? 'Marco'
            : 'Ação'}
          {' · '}
          {
            initiativeActionPriorityLabels[
              card.priority
            ]
          }
        </span>

        {card.depth > 0 ? (
          <span className="initiative-kanban-card__depth">
            Nível {card.depth + 1}
          </span>
        ) : null}
      </div>

      <strong className="initiative-kanban-card__title">
        {card.code} — {card.name}
      </strong>

      {plannedDueDate ? (
        <span className="initiative-kanban-card__children">
          Prazo planejado: {plannedDueDate}
        </span>
      ) : null}

      <div className="initiative-kanban-card__progress">
        <div className="initiative-kanban-card__progress-copy">
          <span>Progresso</span>
          <strong>
            {formatProgress(card.displayProgress)}
          </strong>
        </div>

        <progress
          value={card.displayProgress}
          max={100}
          aria-label={`Progresso ${formatProgress(
            card.displayProgress,
          )}`}
        />
      </div>

      {card.calculatedProgress !== null &&
      card.calculatedProgress !==
        card.officialProgress ? (
        <p className="initiative-kanban-card__rollup">
          Oficial {formatProgress(card.officialProgress)}
          {' · '}
          Calculado{' '}
          {formatProgress(card.calculatedProgress)}
        </p>
      ) : null}

      {card.hasEligibleChildren ? (
        <span className="initiative-kanban-card__children">
          Consolida ações subordinadas
        </span>
      ) : null}

      <button
        type="button"
        className="initiative-kanban-card__open"
        onClick={() => onOpen(card)}
      >
        Detalhes e ações
      </button>
    </article>
  )
}