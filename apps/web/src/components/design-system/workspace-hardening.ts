const SCROLL_TOP_THRESHOLD = 160

let attachedMain: HTMLElement | null = null
let refreshScheduled = false

function getShell() {
  return document.querySelector<HTMLElement>('.skpe-shell')
}

function getMain() {
  return document.querySelector<HTMLElement>('.skpe-main')
}

function getPageScrollTop() {
  return Math.max(
    window.scrollY,
    document.documentElement.scrollTop,
    document.body.scrollTop,
  )
}

function syncHeaderMetrics() {
  const shell = getShell()
  const header = document.querySelector<HTMLElement>(
    '.skpe-cockpit-header',
  )

  if (!shell || !header) return

  shell.style.setProperty(
    '--skpe-cockpit-header-height',
    `${Math.ceil(header.getBoundingClientRect().height)}px`,
  )
}

function syncScrollTopVisibility() {
  const shell = getShell()
  if (!shell) return

  const mainScrollTop = getMain()?.scrollTop ?? 0
  const visible =
    Math.max(mainScrollTop, getPageScrollTop()) >=
    SCROLL_TOP_THRESHOLD

  shell.classList.toggle(
    'skpe-scroll-top-visible',
    visible,
  )
}

function getInitiativeDrawerCloseButton() {
  const drawer = document.querySelector<HTMLElement>(
    '.skpe-initiative-form-card',
  )

  if (!drawer) return null

  const headingButtons = Array.from(
    drawer.querySelectorAll<HTMLButtonElement>(
      '.skpe-card-heading button',
    ),
  )

  return (
    headingButtons.find((button) => {
      const label = button.textContent?.trim()
      return label === 'Fechar' || label === 'Cancelar'
    }) ?? null
  )
}

function hardenInitiativeDrawerCopy() {
  const drawer = document.querySelector<HTMLElement>(
    '.skpe-initiative-form-card',
  )

  if (!drawer) return

  const title = drawer.querySelector('h2')
  if (title?.textContent?.trim() === 'Nova iniciativa transversal') {
    title.textContent = 'Nova iniciativa'
  }

  const closeButton = getInitiativeDrawerCloseButton()

  if (closeButton) {
    closeButton.textContent = 'Cancelar'
    closeButton.classList.add('skpe-drawer-cancel-button')
    closeButton.setAttribute(
      'aria-label',
      'Cancelar cadastro da iniciativa',
    )
  }
}

function dismissInitiativeDrawerOnEscape(event: KeyboardEvent) {
  if (event.key !== 'Escape') return

  const closeButton = getInitiativeDrawerCloseButton()
  if (!closeButton || closeButton.disabled) return

  event.preventDefault()
  event.stopPropagation()
  closeButton.click()
}

function attachMainScrollListener() {
  const nextMain = getMain()
  if (nextMain === attachedMain) return

  attachedMain?.removeEventListener(
    'scroll',
    syncScrollTopVisibility,
  )

  attachedMain = nextMain
  attachedMain?.addEventListener(
    'scroll',
    syncScrollTopVisibility,
    { passive: true },
  )
}

function refreshWorkspaceHardening() {
  refreshScheduled = false
  attachMainScrollListener()
  syncHeaderMetrics()
  syncScrollTopVisibility()
  hardenInitiativeDrawerCopy()
}

function scheduleRefresh() {
  if (refreshScheduled) return
  refreshScheduled = true
  window.requestAnimationFrame(refreshWorkspaceHardening)
}

if (typeof window !== 'undefined' && typeof document !== 'undefined') {
  window.addEventListener('scroll', syncScrollTopVisibility, {
    passive: true,
  })
  window.addEventListener('resize', scheduleRefresh, {
    passive: true,
  })
  document.addEventListener(
    'keydown',
    dismissInitiativeDrawerOnEscape,
    true,
  )

  const observer = new MutationObserver(scheduleRefresh)
  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
  })

  scheduleRefresh()
}
