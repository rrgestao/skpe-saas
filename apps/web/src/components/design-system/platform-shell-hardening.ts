let scheduled = false
let observedHeader: HTMLElement | null = null
let observedFooter: HTMLElement | null = null
let headerObserver: ResizeObserver | null = null
let footerObserver: ResizeObserver | null = null

function getPlatformShell() {
  return document.querySelector<HTMLElement>('.platform-shell')
}

function measurePlatformShellChrome() {
  scheduled = false

  const shell = getPlatformShell()
  if (!shell) return

  const header = shell.querySelector<HTMLElement>('.topbar')
  const footer = shell.querySelector<HTMLElement>('.platform-footer')

  if (header) {
    shell.style.setProperty(
      '--platform-fixed-header-height',
      `${Math.ceil(header.getBoundingClientRect().height)}px`,
    )
  }

  if (footer) {
    shell.style.setProperty(
      '--platform-fixed-footer-height',
      `${Math.ceil(footer.getBoundingClientRect().height)}px`,
    )
  }

  if (header !== observedHeader) {
    headerObserver?.disconnect()
    observedHeader = header
    if (header) {
      headerObserver = new ResizeObserver(scheduleMeasurement)
      headerObserver.observe(header)
    }
  }

  if (footer !== observedFooter) {
    footerObserver?.disconnect()
    observedFooter = footer
    if (footer) {
      footerObserver = new ResizeObserver(scheduleMeasurement)
      footerObserver.observe(footer)
    }
  }
}

function scheduleMeasurement() {
  if (scheduled) return
  scheduled = true
  window.requestAnimationFrame(measurePlatformShellChrome)
}

if (typeof window !== 'undefined' && typeof document !== 'undefined') {
  window.addEventListener('resize', scheduleMeasurement, { passive: true })

  const mutationObserver = new MutationObserver(scheduleMeasurement)
  mutationObserver.observe(document.documentElement, {
    childList: true,
    subtree: true,
  })

  scheduleMeasurement()
}
