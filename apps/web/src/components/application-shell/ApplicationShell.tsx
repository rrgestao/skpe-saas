import type { ReactNode } from 'react'

import './ApplicationShell.css'

export type ApplicationShellContextItem = {
  label: string
  value: string
}

export type ApplicationShellNavigationItem = {
  id: string
  label: string
  icon?: ReactNode
  active?: boolean
  disabled?: boolean
  onActivate: () => void
}

type ApplicationShellProps = {
  brand: ReactNode
  contextItems: ApplicationShellContextItem[]
  userArea: ReactNode
  navigationItems: ApplicationShellNavigationItem[]
  navigationLabel?: string
  children: ReactNode
  footer?: ReactNode
  collapsed?: boolean
  mobileOpen?: boolean
  onToggleCollapsed?: () => void
  onCloseMobile?: () => void
}

export function ApplicationShell({
  brand,
  contextItems,
  userArea,
  navigationItems,
  navigationLabel = 'Navegação principal',
  children,
  footer,
  collapsed = false,
  mobileOpen = false,
  onToggleCollapsed,
  onCloseMobile,
}: ApplicationShellProps) {
  return (
    <div
      className={[
        'application-shell',
        collapsed ? 'application-shell-collapsed' : '',
        mobileOpen ? 'application-shell-mobile-open' : '',
      ]
        .filter(Boolean)
        .join(' ')}
    >
      <header className="application-shell-header">
        <div className="application-shell-brand">{brand}</div>

        <div
          className="application-shell-context"
          aria-label="Contexto atual"
        >
          {contextItems.map((item) => (
            <div
              key={`${item.label}-${item.value}`}
              className="application-shell-context-item"
            >
              <span>{item.label}</span>
              <strong>{item.value}</strong>
            </div>
          ))}
        </div>

        <div className="application-shell-user">{userArea}</div>
      </header>

      <aside
        className="application-shell-sidebar"
        aria-label={navigationLabel}
      >
        <div className="application-shell-sidebar-header">
          <strong>Menu</strong>

          {onToggleCollapsed && (
            <button
              type="button"
              className="application-shell-collapse-button"
              onClick={onToggleCollapsed}
              aria-label={
                collapsed
                  ? 'Expandir menu'
                  : 'Recolher menu'
              }
              title={
                collapsed
                  ? 'Expandir menu'
                  : 'Recolher menu'
              }
            >
              {collapsed ? '→' : '←'}
            </button>
          )}
        </div>

        <nav className="application-shell-navigation">
          {navigationItems.map((item) => (
            <button
              key={item.id}
              type="button"
              className={[
                'application-shell-navigation-item',
                item.active ? 'active' : '',
              ]
                .filter(Boolean)
                .join(' ')}
              onClick={() => {
                item.onActivate()
                onCloseMobile?.()
              }}
              disabled={item.disabled}
              aria-current={item.active ? 'page' : undefined}
              title={collapsed ? item.label : undefined}
            >
              {item.icon && (
                <span
                  className="application-shell-navigation-icon"
                  aria-hidden="true"
                >
                  {item.icon}
                </span>
              )}

              <span className="application-shell-navigation-label">
                {item.label}
              </span>
            </button>
          ))}
        </nav>
      </aside>

      {mobileOpen && (
        <button
          type="button"
          className="application-shell-mobile-backdrop"
          onClick={onCloseMobile}
          aria-label="Fechar menu"
        />
      )}

      <main className="application-shell-content">{children}</main>

      <footer className="application-shell-footer">
        {footer ?? (
          <>
            <span>
              Plataforma SPARKs
            </span>
            <span>
              © {new Date().getFullYear()} SPARKOOP — Todos os direitos reservados.
            </span>
          </>
        )}
      </footer>
    </div>
  )
}