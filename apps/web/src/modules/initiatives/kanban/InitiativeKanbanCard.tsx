import type {
  InitiativeKanbanCardModel,
} from '../contracts/initiativeActions'

type InitiativeKanbanCardProps = {
  card: InitiativeKanbanCardModel
}

function formatProgress(value: number) {
  return `${new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 1,
  }).format(value)}%`
}

function shortActionId(actionId: string) {
  return actionId.slice(0, 8)
}

export function InitiativeKanbanCard({
  card,
}: InitiativeKanbanCardProps) {
  return (
    <article
      className="initiative-kanban-card"
      data-status={card.status}
      data-action-id={card.actionId}
    >
      <div className="initiative-kanban-card__header">
        <span className="initiative-kanban-card__type">
          {card.actionType === 'milestone'
            ? 'Marco'
            : 'Ação'}
        </span>

        {card.depth > 0 ? (
          <span className="initiative-kanban-card__depth">
            Nível {card.depth + 1}
          </span>
        ) : null}
      </div>

      <strong className="initiative-kanban-card__title">
        Ação {shortActionId(card.actionId)}
      </strong>

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
    </article>
  )
}