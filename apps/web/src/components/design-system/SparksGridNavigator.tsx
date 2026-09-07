import { useCallback, useEffect, useRef, useState } from 'react'
import {
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
} from 'lucide-react'

type Direction = 'up' | 'down' | 'left' | 'right'

function findScrollableElement(
  shell: HTMLElement,
  direction: Direction,
): HTMLElement {
  const horizontal = direction === 'left' || direction === 'right'
  const candidates = [
    shell,
    ...Array.from(shell.querySelectorAll<HTMLElement>('*')),
  ]

  let best = shell
  let bestRange = horizontal
    ? shell.scrollWidth - shell.clientWidth
    : shell.scrollHeight - shell.clientHeight

  for (const candidate of candidates) {
    const range = horizontal
      ? candidate.scrollWidth - candidate.clientWidth
      : candidate.scrollHeight - candidate.clientHeight

    if (range > bestRange + 2) {
      best = candidate
      bestRange = range
    }
  }

  return best
}

export function SparksGridNavigator() {
  const rootRef = useRef<HTMLDivElement>(null)
  const [availability, setAvailability] = useState({
    up: false,
    down: false,
    left: false,
    right: false,
  })

  const resolveShell = useCallback(
    () =>
      rootRef.current?.closest<HTMLElement>(
        '[data-sparks-grid-shell]',
      ) ?? null,
    [],
  )

  const refreshAvailability = useCallback(() => {
    const shell = resolveShell()
    if (!shell) return

    const vertical = findScrollableElement(shell, 'down')
    const horizontal = findScrollableElement(shell, 'right')
    const epsilon = 3

    setAvailability({
      up: vertical.scrollTop > epsilon,
      down:
        vertical.scrollTop + vertical.clientHeight <
        vertical.scrollHeight - epsilon,
      left: horizontal.scrollLeft > epsilon,
      right:
        horizontal.scrollLeft + horizontal.clientWidth <
        horizontal.scrollWidth - epsilon,
    })
  }, [resolveShell])

  const move = useCallback(
    (direction: Direction) => {
      const shell = resolveShell()
      if (!shell) return

      const target = findScrollableElement(shell, direction)
      const horizontal =
        direction === 'left' || direction === 'right'
      const amount = horizontal
        ? Math.max(240, Math.round(target.clientWidth * 0.72))
        : Math.max(160, Math.round(target.clientHeight * 0.58))

      target.scrollBy({
        left:
          direction === 'left'
            ? -amount
            : direction === 'right'
              ? amount
              : 0,
        top:
          direction === 'up'
            ? -amount
            : direction === 'down'
              ? amount
              : 0,
        behavior: 'smooth',
      })

      window.setTimeout(refreshAvailability, 220)
    },
    [refreshAvailability, resolveShell],
  )

  useEffect(() => {
    refreshAvailability()

    const shell = resolveShell()
    if (!shell) return

    const candidates = [
      shell,
      ...Array.from(shell.querySelectorAll<HTMLElement>('*')),
    ]

    const onScroll = () => refreshAvailability()
    const observer = new ResizeObserver(refreshAvailability)

    for (const candidate of candidates) {
      candidate.addEventListener('scroll', onScroll, {
        passive: true,
      })
      observer.observe(candidate)
    }

    window.addEventListener('resize', refreshAvailability)

    return () => {
      for (const candidate of candidates) {
        candidate.removeEventListener('scroll', onScroll)
      }
      observer.disconnect()
      window.removeEventListener('resize', refreshAvailability)
    }
  }, [refreshAvailability, resolveShell])

  return (
    <div
      ref={rootRef}
      className="sparks-grid-navigator"
      role="group"
      aria-label="Navegação direcional do grid"
    >
      <button
        type="button"
        className="sparks-grid-navigator__button sparks-grid-navigator__button--up"
        onClick={() => move('up')}
        disabled={!availability.up}
        title="Rolar grid para cima"
        aria-label="Rolar grid para cima"
      >
        <ChevronUp aria-hidden="true" size={17} />
      </button>

      <button
        type="button"
        className="sparks-grid-navigator__button sparks-grid-navigator__button--left"
        onClick={() => move('left')}
        disabled={!availability.left}
        title="Rolar grid para a esquerda"
        aria-label="Rolar grid para a esquerda"
      >
        <ChevronLeft aria-hidden="true" size={17} />
      </button>

      <span
        className="sparks-grid-navigator__center"
        aria-hidden="true"
      />

      <button
        type="button"
        className="sparks-grid-navigator__button sparks-grid-navigator__button--right"
        onClick={() => move('right')}
        disabled={!availability.right}
        title="Rolar grid para a direita"
        aria-label="Rolar grid para a direita"
      >
        <ChevronRight aria-hidden="true" size={17} />
      </button>

      <button
        type="button"
        className="sparks-grid-navigator__button sparks-grid-navigator__button--down"
        onClick={() => move('down')}
        disabled={!availability.down}
        title="Rolar grid para baixo"
        aria-label="Rolar grid para baixo"
      >
        <ChevronDown aria-hidden="true" size={17} />
      </button>
    </div>
  )
}
