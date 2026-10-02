import { useMemo } from 'react'

import {
  SparksSmartGrid,
  type SparksSmartGridColumn,
  type SparksSmartGridRow,
} from '../../../components/design-system/SparksSmartGrid'
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

type Props = {
  users: OrganizationUserGridItem[]
  selectedUserId: string | null
  onSelectUser: (userId: string) => void
  onOpenUser: (userId: string) => void
}

type UserGridRow = SparksSmartGridRow & {
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
function membershipLabel(value: string) {
  const labels: Record<string, string> = {
    active: 'Ativo', inactive: 'Inativo', invited: 'Convidado', pending: 'Pendente',
    suspended: 'Suspenso', revoked: 'Revogado', ended: 'Encerrado',
  }
  return labels[value] ?? value
}

function buildSkpeRole(user: OrganizationUserGridItem) {
  return user.modules.find((module) => module.moduleCode === 'SK-PE')?.roleName || 'Não atribuído'
}

function buildOtherModules(user: OrganizationUserGridItem) {
  const values = user.modules
    .filter((module) => module.moduleCode !== 'SK-PE')
    .map((module) => `${module.moduleShortName || module.moduleName || module.moduleCode}: ${module.roleName || 'Sem papel'}`)
  return values.length > 0 ? values.join(' · ') : 'Nenhum outro módulo'
}

function UserIdentityCell({ row }: { row: any }) {
  const typedRow = row as UserGridRow
  return (
    <div className="sparks-user-grid__identity">
      <span className="sparks-user-grid__avatar" aria-hidden="true">
        {typedRow.avatarUrl ? <img src={typedRow.avatarUrl} alt="" /> : <span>{(typedRow.displayName || typedRow.email).split(/\s+/).map((part) => part[0]).join('').slice(0, 2).toUpperCase()}</span>}
      </span>
      <span className="sparks-user-grid__identity-text" title={`${typedRow.displayName} · ${typedRow.email}`}>
        <strong>{typedRow.displayName}</strong>
      </span>
    </div>
  )
}

export function OrganizationUsersSmartGrid({ users, selectedUserId, onSelectUser, onOpenUser }: Props) {
  const rows = useMemo<UserGridRow[]>(() => users.map((user) => ({
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
  })), [users])

  const columns = useMemo<SparksSmartGridColumn[]>(() => [
    { id: 'displayName', label: 'Usuário', minWidth: 300, cell: UserIdentityCell, filterValue: (row) => `${row.displayName ?? ''} ${row.email ?? ''}` },
    { id: 'jobTitle', label: 'Função', minWidth: 180 },
    { id: 'membership', label: 'Vínculo', minWidth: 120, align: 'center' },
    { id: 'organizationAdmin', label: 'Adm. Organização', minWidth: 150, align: 'center' },
    { id: 'skpeRole', label: 'Papel no SK-PE', minWidth: 180 },
    { id: 'otherModules', label: 'Outros módulos e papéis', minWidth: 300, tooltip: true },
  ], [])

  return (
    <div className="sparks-user-grid" data-sparks-grid-shell>
      <SparksSmartGrid
        rows={rows}
        columns={columns}
        ariaLabel="Matriz de usuários da organização"
        viewportMode="standard"
        selectedId={selectedUserId}
        onSelect={(id) => onSelectUser(id)}
        onDoubleClick={(id) => {
          onSelectUser(id)
          onOpenUser(id)
        }}
      />
    </div>
  )
}
