import type {
  ButtonHTMLAttributes,
  ReactNode,
} from 'react'
import {
  ArrowLeft,
  CalendarPlus,
  Download,
  Ellipsis,
  ExternalLink,
  Eye,
  Pencil,
  CirclePlus,
  Printer,
  RefreshCw,
  Save,
  Trash2,
  X,
  type LucideIcon,
} from 'lucide-react'

import './design-system.css'
import './workspace-hardening.css'
import './workspace-hardening'

export type SparksActionIconName =
  | 'add'
  | 'edit'
  | 'delete'
  | 'view'
  | 'print'
  | 'refresh'
  | 'back'
  | 'schedule'
  | 'more'
  | 'open'
  | 'save'
  | 'export'
  | 'close'

const sparksActionIcons: Record<SparksActionIconName, LucideIcon> = {
  add: CirclePlus,
  edit: Pencil,
  delete: Trash2,
  view: Eye,
  print: Printer,
  refresh: RefreshCw,
  back: ArrowLeft,
  schedule: CalendarPlus,
  more: Ellipsis,
  open: ExternalLink,
  save: Save,
  export: Download,
  close: X,
}

type IconActionButtonProps = Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  'children' | 'title' | 'aria-label'
> & {
  action: SparksActionIconName
  label: string
  variant?: 'default' | 'primary' | 'danger' | 'ghost'
  size?: 'sm' | 'md'
}

export function IconActionButton({
  action,
  label,
  variant = 'default',
  size = 'md',
  className = '',
  type = 'button',
  ...buttonProps
}: IconActionButtonProps) {
  const Icon = sparksActionIcons[action]

  return (
    <button
      {...buttonProps}
      type={type}
      className={[
        'sparks-icon-action',
        `sparks-icon-action--${variant}`,
        `sparks-icon-action--${size}`,
        className,
      ]
        .filter(Boolean)
        .join(' ')}
      aria-label={label}
      title={label}
      data-tooltip={label}
    >
      <Icon aria-hidden="true" strokeWidth={1.8} />
    </button>
  )
}
type MetricCardProps = {
  label: ReactNode
  value: ReactNode
  helper?: ReactNode
  footer?: ReactNode
  active?: boolean
  disabled?: boolean
  onClick?: () => void
  ariaLabel?: string
  tooltip?: string
  className?: string
}

export function MetricCard({
  label,
  value,
  helper,
  footer,
  active = false,
  disabled = false,
  onClick,
  ariaLabel,
  tooltip,
  className = '',
}: MetricCardProps) {
  const classes = [
    'sparks-metric-card',
    active ? 'sparks-metric-card--active' : '',
    onClick ? 'sparks-metric-card--interactive' : '',
    className,
  ]
    .filter(Boolean)
    .join(' ')

  const content = (
    <>
      <span className="sparks-metric-card__label">{label}</span>
      <strong className="sparks-metric-card__value">{value}</strong>
      {helper ? (
        <small className="sparks-metric-card__helper">{helper}</small>
      ) : null}
      {footer ? (
        <div className="sparks-metric-card__footer">{footer}</div>
      ) : null}
    </>
  )

  if (onClick) {
    return (
      <button
        type="button"
        className={classes}
        onClick={onClick}
        disabled={disabled}
        aria-pressed={active}
        aria-label={ariaLabel}
        title={tooltip}
        data-tooltip={tooltip}
      >
        {content}
      </button>
    )
  }

  return (
    <article className={classes} title={tooltip} data-tooltip={tooltip}>
      {content}
    </article>
  )
}

type WorkspaceTab<T extends string> = {
  id: T
  label: ReactNode
  disabled?: boolean
}

type WorkspaceTabsProps<T extends string> = {
  tabs: readonly WorkspaceTab<T>[]
  activeId: T
  onChange: (id: T) => void
  ariaLabel: string
}

export function WorkspaceTabs<T extends string>({
  tabs,
  activeId,
  onChange,
  ariaLabel,
}: WorkspaceTabsProps<T>) {
  return (
    <nav className="sparks-workspace-tabs" aria-label={ariaLabel}>
      {tabs.map((tab) => (
        <button
          key={tab.id}
          type="button"
          className={
            tab.id === activeId
              ? 'sparks-workspace-tabs__tab sparks-workspace-tabs__tab--active'
              : 'sparks-workspace-tabs__tab'
          }
          aria-current={tab.id === activeId ? 'page' : undefined}
          disabled={tab.disabled}
          onClick={() => onChange(tab.id)}
        >
          {tab.label}
        </button>
      ))}
    </nav>
  )
}

type ObjectWorkspaceHeaderProps = {
  eyebrow?: ReactNode
  title: ReactNode
  subtitle?: ReactNode
  actions?: ReactNode
}

export function ObjectWorkspaceHeader({
  eyebrow,
  title,
  subtitle,
  actions,
}: ObjectWorkspaceHeaderProps) {
  return (
    <header className="sparks-object-workspace-header">
      <div className="sparks-object-workspace-header__content">
        {eyebrow ? (
          <span className="sparks-object-workspace-header__eyebrow">
            {eyebrow}
          </span>
        ) : null}
        <h2>{title}</h2>
        {subtitle ? (
          <p className="sparks-object-workspace-header__subtitle">
            {subtitle}
          </p>
        ) : null}
      </div>

      {actions ? (
        <div className="sparks-object-workspace-header__actions">
          {actions}
        </div>
      ) : null}
    </header>
  )
}

type EmptyStateProps = {
  title: ReactNode
  description?: ReactNode
  icon?: ReactNode
  action?: ReactNode
  compact?: boolean
}

export function EmptyState({
  title,
  description,
  icon,
  action,
  compact = false,
}: EmptyStateProps) {
  return (
    <section
      className={
        compact
          ? 'sparks-empty-state sparks-empty-state--compact'
          : 'sparks-empty-state'
      }
    >
      {icon ? (
        <div className="sparks-empty-state__icon" aria-hidden="true">
          {icon}
        </div>
      ) : null}
      <h2>{title}</h2>
      {description ? <p>{description}</p> : null}
      {action ? <div className="sparks-empty-state__action">{action}</div> : null}
    </section>
  )
}

export type DesignSystemButtonProps =
  ButtonHTMLAttributes<HTMLButtonElement>