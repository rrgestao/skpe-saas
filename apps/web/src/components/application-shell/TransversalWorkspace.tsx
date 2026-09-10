import type { ReactNode } from 'react'

import './TransversalWorkspace.css'

type TransversalWorkspaceProps = {
  header?: ReactNode
  primary: ReactNode
  secondary?: ReactNode
  actions?: ReactNode
  footer?: ReactNode
  className?: string
}

export function TransversalWorkspace({
  header,
  primary,
  secondary,
  actions,
  footer,
  className,
}: TransversalWorkspaceProps) {
  return (
    <section
      className={[
        'sparks-transversal-workspace',
        secondary ? 'sparks-transversal-workspace--split' : '',
        className ?? '',
      ]
        .filter(Boolean)
        .join(' ')}
    >
      {header && (
        <header className="sparks-transversal-workspace__header">
          {header}
        </header>
      )}

      <div className="sparks-transversal-workspace__body">
        <div className="sparks-transversal-workspace__pane sparks-transversal-workspace__pane--primary">
          {primary}
        </div>

        {secondary && (
          <>
            {actions && (
              <div className="sparks-transversal-workspace__actions">
                {actions}
              </div>
            )}
            <div className="sparks-transversal-workspace__pane sparks-transversal-workspace__pane--secondary">
              {secondary}
            </div>
          </>
        )}
      </div>

      {footer && (
        <footer className="sparks-transversal-workspace__footer">
          {footer}
        </footer>
      )}
    </section>
  )
}
