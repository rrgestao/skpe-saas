import './SparksSummaryCards.css'

export type SparksSummaryCardItem = {
  id: string
  label: string
  value: string | number
  title?: string
}

type SparksSummaryCardsProps = {
  items: SparksSummaryCardItem[]
  selectedId?: string | null
  onSelect?: (id: string) => void
  ariaLabel?: string
  className?: string
}

export function SparksSummaryCards({
  items,
  selectedId = null,
  onSelect,
  ariaLabel = 'Resumo',
  className = '',
}: SparksSummaryCardsProps) {
  const interactive = Boolean(onSelect)

  return (
    <div
      className={`sparks-summary-cards ${className}`.trim()}
      role={interactive ? 'group' : undefined}
      aria-label={ariaLabel}
      data-sparks-summary-cards
    >
      {items.map((item) => {
        const active = selectedId === item.id

        if (interactive) {
          return (
            <button
              key={item.id}
              type="button"
              className={`sparks-summary-card${active ? ' is-active' : ''}`}
              aria-pressed={active}
              title={item.title}
              onClick={() => onSelect?.(item.id)}
            >
              <span className="sparks-summary-card__label">{item.label}</span>
              <strong className="sparks-summary-card__value">{item.value}</strong>
            </button>
          )
        }

        return (
          <article key={item.id} className="sparks-summary-card" title={item.title}>
            <span className="sparks-summary-card__label">{item.label}</span>
            <strong className="sparks-summary-card__value">{item.value}</strong>
          </article>
        )
      })}
    </div>
  )
}
