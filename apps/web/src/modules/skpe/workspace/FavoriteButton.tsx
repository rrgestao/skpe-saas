type FavoriteButtonProps = {
  label: string
  isFavorite: boolean
  disabled?: boolean
  busy?: boolean
  onToggle: () => void
}

export function FavoriteButton({
  label,
  isFavorite,
  disabled = false,
  busy = false,
  onToggle,
}: FavoriteButtonProps) {
  const actionLabel = isFavorite
    ? `Remover ${label} dos favoritos`
    : `Adicionar ${label} aos favoritos`

  return (
    <button
      type="button"
      className={`skpe-secondary-button skpe-favorite-button ${
        isFavorite ? 'skpe-favorite-button-active' : ''
      }`}
      aria-pressed={isFavorite}
      aria-label={actionLabel}
      title={actionLabel}
      disabled={disabled || busy}
      onClick={onToggle}
    >
      <span className="skpe-favorite-button-icon" aria-hidden="true">
        {isFavorite ? '★' : '☆'}
      </span>
      <span>
        {busy
          ? 'Salvando...'
          : isFavorite
            ? 'Favorito'
            : 'Adicionar aos favoritos'}
      </span>
    </button>
  )
}
