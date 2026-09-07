import { useMemo, useState } from 'react'
import { Filter, X } from 'lucide-react'
import { Grid, Willow, type IColumnConfig } from '@svar-ui/react-grid'

import '@svar-ui/react-grid/all.css'
import { SparksGridNavigator } from '../../../components/design-system/SparksGridNavigator'
import './OrganizationUsersSmartGrid.css'

type UserModuleAccess = {
  moduleCode: string
  moduleName: string
  moduleShortName: string
  roleName: string
}

export type OrganizationUserGridItem = {
  userId: string
  email: string
  displayName: string | null
  avatarUrl: string | null
  membershipStatus: string
  isOrganizationAdmin: boolean
  jobTitle: string | null
  modules: UserModuleAccess[]
}

type OrganizationUsersSmartGridProps = {
  users: OrganizationUserGridItem[]
  selectedUserId: string | null
  onSelectUser: (userId: string) => void
}

type UserGridRow = {
  id: string
  userId: string
  displayName: string
  email: string
  avatarUrl: string | null
  jobTitle: string
  membership: string
  organizationAdmin: string
  skpeRole: string
  otherModules: string
}

const headerLabels: Record<string, string> = {
  displayName: 'Usuário',
  jobTitle: 'Função',
  membership: 'Vínculo',
  organizationAdmin: 'Adm. Organização',
  skpeRole: 'Papel no SK-PE',
  otherModules: 'Outros módulos e papéis',
}

function normalize(value: unknown) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLocaleLowerCase('pt-BR')
}

function membershipLabel(value: string) {
  const labels: Record<string, string> = {
    active: 'Ativo',
    inactive: 'Inativo',
    invited: 'Convidado',
    pending: 'Pendente',
    suspended: 'Suspenso',
    revoked: 'Revogado',
    ended: 'Encerrado',
  }

  return labels[value] ?? value
}

function buildSkpeRole(user: OrganizationUserGridItem) {
  const skpe = user.modules.find((module) => module.moduleCode === 'SK-PE')
  return skpe?.roleName || 'Não atribuído'
}

function buildOtherModules(user: OrganizationUserGridItem) {
  const values = user.modules
    .filter((module) => module.moduleCode !== 'SK-PE')
    .map((module) => {
      const moduleName = module.moduleShortName || module.moduleName || module.moduleCode
      return `${moduleName}: ${module.roleName || 'Sem papel'}`
    })

  return values.length > 0 ? values.join(' · ') : 'Nenhum outro módulo'
}

function UserIdentityCell({ row }: { row: any }) {
  const typedRow = row as UserGridRow

  return (
    <div className="sparks-user-grid__identity">
      <span className="sparks-user-grid__avatar" aria-hidden="true">
        {typedRow.avatarUrl ? (
          <img src={typedRow.avatarUrl} alt="" />
        ) : (
          <span>
            {(typedRow.displayName || typedRow.email)
              .split(/\s+/)
              .map((part) => part[0])
              .join('')
              .slice(0, 2)
              .toUpperCase()}
          </span>
        )}
      </span>
      <span className="sparks-user-grid__identity-text">
        <strong>{typedRow.displayName}</strong>
        <small>{typedRow.email}</small>
      </span>
    </div>
  )
}

export function OrganizationUsersSmartGrid({
  users,
  selectedUserId,
  onSelectUser,
}: OrganizationUsersSmartGridProps) {
  const [columnFilters, setColumnFilters] = useState<Record<string, string>>({})
  const [openColumnFilter, setOpenColumnFilter] = useState<string | null>(null)

  const rows = useMemo<UserGridRow[]>(
    () =>
      users.map((user) => ({
        id: user.userId,
        userId: user.userId,
        displayName: user.displayName ?? user.email,
        email: user.email,
        avatarUrl: user.avatarUrl,
        jobTitle: user.jobTitle ?? 'Função não informada',
        membership: membershipLabel(user.membershipStatus),
        organizationAdmin: user.isOrganizationAdmin ? 'Sim' : 'Não',
        skpeRole: buildSkpeRole(user),
        otherModules: buildOtherModules(user),
      })),
    [users],
  )

  const data = useMemo(() => {
    const activeFilters = Object.entries(columnFilters).filter(([, value]) => value.trim())
    if (activeFilters.length === 0) return rows

    return rows.filter((row) =>
      activeFilters.every(([id, value]) => {
        if (id === 'displayName') {
          return normalize(`${row.displayName} ${row.email}`).includes(normalize(value))
        }
        const record = row as unknown as Record<string, unknown>
        return normalize(record[id]).includes(normalize(value))
      }),
    )
  }, [rows, columnFilters])

  function UserHeaderCell({ column }: { column: any }) {
    const id = String(column?.id ?? '')
    const label = headerLabels[id] ?? String(column?.header?.text ?? '')
    const value = columnFilters[id] ?? ''
    const open = openColumnFilter === id

    return (
      <div className="sparks-data-explorer-header-cell">
        {open ? (
          <div className="sparks-data-explorer-header-filter-input-wrap" onClick={(event) => event.stopPropagation()}>
            <input
              autoFocus
              className="sparks-data-explorer-header-filter-input"
              value={value}
              placeholder={`Filtrar ${label.toLocaleLowerCase('pt-BR')}`}
              aria-label={`Filtrar ${label}`}
              onChange={(event) =>
                setColumnFilters((current) => ({ ...current, [id]: event.target.value }))
              }
              onKeyDown={(event) => {
                if (event.key === 'Escape') setOpenColumnFilter(null)
              }}
            />
            {value ? (
              <button
                type="button"
                className="sparks-data-explorer-header-filter-clear"
                aria-label={`Limpar filtro de ${label}`}
                title={`Limpar filtro de ${label}`}
                onClick={(event) => {
                  event.stopPropagation()
                  setColumnFilters((current) => ({ ...current, [id]: '' }))
                }}
              >
                <X aria-hidden="true" size={14} />
              </button>
            ) : null}
          </div>
        ) : (
          <span className="sparks-data-explorer-header-label">{label}</span>
        )}

        <button
          type="button"
          className={
            value
              ? 'sparks-data-explorer-header-filter-button sparks-data-explorer-header-filter-button--active'
              : 'sparks-data-explorer-header-filter-button'
          }
          aria-label={`${open ? 'Fechar' : 'Abrir'} filtro de ${label}`}
          title={`${open ? 'Fechar' : 'Filtrar'} ${label}`}
          onClick={(event) => {
            event.stopPropagation()
            setOpenColumnFilter((current) => (current === id ? null : id))
          }}
        >
          <Filter aria-hidden="true" size={14} />
        </button>
      </div>
    )
  }

  function smartHeader(text: string) {
    return {
      text,
      cell: UserHeaderCell,
      css: 'sparks-data-explorer-header-main',
    }
  }

  const columns: IColumnConfig[] = [
    { id: 'displayName', header: smartHeader('Usuário'), width: 330, sort: true, resize: true, cell: UserIdentityCell },
    { id: 'jobTitle', header: smartHeader('Função'), width: 190, sort: true, resize: true },
    { id: 'membership', header: smartHeader('Vínculo'), width: 135, sort: true, resize: true },
    { id: 'organizationAdmin', header: smartHeader('Adm. Organização'), width: 165, sort: true, resize: true },
    { id: 'skpeRole', header: smartHeader('Papel no SK-PE'), width: 190, sort: true, resize: true },
    { id: 'otherModules', header: smartHeader('Outros módulos e papéis'), width: 320, sort: true, resize: true, tooltip: true },
  ]

  function init(api: { on: (action: string, handler: (event: { id?: string | number }) => void) => void }) {
    api.on('select-row', (event) => {
      if (event.id === undefined || event.id === null) return
      onSelectUser(String(event.id))
    })
  }

  return (
    <div className="sparks-user-grid" data-sparks-grid-shell role="region" aria-label="Matriz de usuários da organização">
      <Willow>
        <Grid
          data={data}
          columns={columns}
          init={init}
          select
          selectedRows={selectedUserId ? [selectedUserId] : []}
          autoRowHeight
        />
      </Willow>
      <SparksGridNavigator />
    </div>
  )
}
