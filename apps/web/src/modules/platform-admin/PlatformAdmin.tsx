import { useEffect, useMemo, useState } from 'react'
import type { FormEvent, KeyboardEvent } from 'react'

import { supabase } from '../../lib/supabase'

import { PortabilityAdmin } from '../portability/PortabilityAdmin'

import './PlatformAdmin.css'

type PlatformAdminProps = {
  onBack: () => void
}

type AdminTab =
  | 'dashboard'
  | 'organizations'
  | 'users'
  | 'memberships'
  | 'modules'
  | 'roles'
  | 'invitations'
  | 'portability'

// VISUALIZACAO HIERARQUICA DE ORGANIZACOES - V5
type ViewMode = 'cards' | 'grid' | 'hierarchy'
type SortDirection = 'asc' | 'desc'
type OrganizationDetailTab = 'data' | 'users' | 'modules' | 'hierarchy'
type UserDetailTab = 'profile' | 'organizations' | 'roles' | 'moduleRoles' | 'audit'

type Summary = {
  organizations_total: number
  organizations_active: number
  users_total: number
  users_active: number
  memberships_active: number
  modules_total: number
  modules_active: number
  pending_invitations: number
}

type Organization = {
  organization_id: string
  organization_code: string
  legal_name: string
  trade_name: string | null
  organization_level: string
  organization_type: string | null
  status: string
  parent_organization_id: string | null
  parent_organization_name: string | null
  cnpj: string | null
  state_code: string | null
  city: string | null
  institutional_email: string | null
  cooperative_branch: string | null
  cooperative_branch_id?: string | null
  cooperative_branch_code?: string | null
  primary_activity_description?: string | null
  economic_activities?: OrganizationEconomicActivity[] | null
  phone?: string | null
  website?: string | null
  postal_code?: string | null
  street?: string | null
  address_number?: string | null
  address_complement?: string | null
  district?: string | null
  country_code?: string | null
  description: string | null
  memberships_count: number
  enabled_modules_count: number
  created_at: string
  updated_at: string
}

type OrganizationLevel = {
  level_code: string
  level_name: string
}

type PlatformUser = {
  user_id: string
  full_name: string | null
  display_name: string | null
  email: string | null
  phone: string | null
  active: boolean
  platform_roles: string
  memberships_count: number
  admin_memberships_count: number
  created_at: string
  updated_at: string
}

type Membership = {
  membership_id: string
  user_id: string
  user_name: string
  user_email: string | null
  organization_id: string
  organization_name: string
  organization_code: string
  membership_status: string
  is_organization_admin: boolean
  job_title: string | null
  valid_from: string
  valid_until: string | null
}

type PlatformModule = {
  module_id: string
  module_code: string
  module_name: string
  module_short_name: string
  description: string | null
  status: string
  is_core: boolean
  display_order: number
  enabled_organizations_count: number
}

type OrganizationModule = {
  module_id: string
  module_code: string
  module_name: string
  module_short_name: string
  module_status: string
  organization_module_id: string | null
  enabled: boolean
  organization_module_status: string | null
}

type PlatformRole = {
  platform_role_id: string
  role_code: string
  role_name: string
  description: string | null
  role_level: number
  active: boolean
  users_count: number
}

type UserRole = {
  platform_role_id: string
  role_code: string
  role_name: string
  role_level: number
  assigned: boolean
  assignment_status: string | null
  user_platform_role_id: string | null
}

type OrganizationModuleRole = {
  organization_module_id: string
  module_id: string
  module_code: string
  module_name: string
  module_short_name: string
  module_role_id: string
  role_code: string
  role_name: string
  role_description: string | null
  role_level: number
}

type UserModuleRole = {
  organization_id: string
  organization_code: string
  organization_name: string
  membership_id: string
  membership_status: string
  organization_module_id: string
  module_id: string
  module_code: string
  module_name: string
  module_short_name: string
  module_role_id: string
  role_code: string
  role_name: string
  role_description: string | null
  role_level: number
  assigned: boolean
  assignment_status: string | null
  user_module_role_id: string | null
  valid_from: string | null
  valid_until: string | null
}

type UserAuditEvent = {
  audit_source: string
  audit_id: string
  occurred_at: string
  actor_user_id: string | null
  actor_name: string
  actor_email: string | null
  organization_id: string | null
  organization_name: string | null
  event_type: string
  event_description: string | null
  entity_table: string | null
  entity_id: string | null
  details: Record<string, unknown>
}

type Invitation = {
  invitation_id: string
  email: string
  full_name: string | null
  organization_id: string | null
  organization_name: string | null
  platform_role_id: string | null
  platform_role_name: string | null
  is_organization_admin: boolean
  job_title: string | null
  status: string
  requested_at: string
  sent_at: string | null
  failure_reason: string | null
}

type OrganizationEconomicActivity = {
  organization_activity_id?: string | null
  cnae_catalog_id: string | null
  version_code?: string | null
  subclass_code: string
  formatted_code: string
  description: string
  is_primary: boolean
  verification_status?: string | null
  source_type?: string | null
  source_reference?: string | null
}

type CooperativeBranch = {
  branch_id: string
  branch_code: string
  branch_name: string
  short_name: string | null
  description: string | null
  display_order: number
  status: string
}

type CnaeCatalogSearchRow = {
  cnae_catalog_id: string
  version_code: string
  subclass_code: string
  formatted_code: string
  description: string
  section_code: string | null
  section_name: string | null
}

type SelectedCnae = {
  cnaeCatalogId: string
  versionCode: string
  subclassCode: string
  formattedCode: string
  description: string
  isPrimary: boolean
}

type OrganizationForm = {
  organizationId: string | null
  code: string
  legalName: string
  tradeName: string
  organizationLevel: string
  organizationType: string
  status: string
  parentOrganizationId: string
  cnpj: string
  cooperativeBranchCode: string
  institutionalEmail: string
  phone: string
  website: string
  postalCode: string
  street: string
  addressNumber: string
  addressComplement: string
  district: string
  city: string
  stateCode: string
  countryCode: string
  cnaeSourceType: string
  cnaeSourceReference: string
  description: string
  changeReason: string
}

type UserForm = {
  userId: string
  fullName: string
  displayName: string
  phone: string
  active: boolean
}

type MembershipForm = {
  membershipId: string | null
  organizationId: string
  userId: string
  status: string
  isOrganizationAdmin: boolean
  jobTitle: string
  validUntil: string
  reason: string
}

type InvitationForm = {
  email: string
  fullName: string
  organizationId: string
  platformRoleId: string
  isOrganizationAdmin: boolean
  jobTitle: string
}

type UserCreationForm = {
  email: string
  fullName: string
  phone: string
  password: string
  confirmPassword: string
  organizationId: string
  platformRoleIds: string[]
  moduleRoleAssignments: Record<string, string>
  isOrganizationAdmin: boolean
  jobTitle: string
}

const EMPTY_SUMMARY: Summary = {
  organizations_total: 0,
  organizations_active: 0,
  users_total: 0,
  users_active: 0,
  memberships_active: 0,
  modules_total: 0,
  modules_active: 0,
  pending_invitations: 0,
}

const EMPTY_ORGANIZATION_FORM: OrganizationForm = {
  organizationId: null,
  code: '',
  legalName: '',
  tradeName: '',
  organizationLevel: 'singular',
  organizationType: 'cooperative',
  status: 'draft',
  parentOrganizationId: '',
  cnpj: '',
  cooperativeBranchCode: '',
  institutionalEmail: '',
  phone: '',
  website: '',
  postalCode: '',
  street: '',
  addressNumber: '',
  addressComplement: '',
  district: '',
  city: '',
  stateCode: '',
  countryCode: 'BR',
  cnaeSourceType: 'manual_confirmed',
  cnaeSourceReference: '',
  description: '',
  changeReason: '',
}

const EMPTY_USER_FORM: UserForm = {
  userId: '',
  fullName: '',
  displayName: '',
  phone: '',
  active: true,
}

const EMPTY_MEMBERSHIP_FORM: MembershipForm = {
  membershipId: null,
  organizationId: '',
  userId: '',
  status: 'active',
  isOrganizationAdmin: false,
  jobTitle: '',
  validUntil: '',
  reason: '',
}

const EMPTY_INVITATION_FORM: InvitationForm = {
  email: '',
  fullName: '',
  organizationId: '',
  platformRoleId: '',
  isOrganizationAdmin: false,
  jobTitle: '',
}

const EMPTY_USER_CREATION_FORM: UserCreationForm = {
  email: '',
  fullName: '',
  phone: '',
  password: '',
  confirmPassword: '',
  organizationId: '',
  platformRoleIds: [],
  moduleRoleAssignments: {},
  isOrganizationAdmin: false,
  jobTitle: '',
}

const STATUS_LABELS: Record<string, string> = {
  draft: 'Rascunho',
  active: 'Ativo',
  inactive: 'Inativo',
  suspended: 'Suspenso',
  archived: 'Arquivado',
  invited: 'Convidado',
  revoked: 'Revogado',
  pending: 'Pendente',
  sent: 'Enviado',
  accepted: 'Aceito',
  cancelled: 'Cancelado',
  failed: 'Falhou',
  planned: 'Planejado',
  deprecated: 'Descontinuado',
  trial: 'Avaliação',
}

const ORGANIZATION_TYPE_LABELS: Record<string, string> = {
  cooperative: 'Cooperativa',
  system: 'Sistema',
  company: 'Empresa',
  association: 'Associação',
  institute: 'Instituto',
  foundation: 'Fundação',
  public_body: 'Órgão público',
  other: 'Outro',
}


const CANONICAL_ORGANIZATION_LEVELS: Record<string, OrganizationLevel> = {
  singular: { level_code: 'singular', level_name: 'Cooperativa singular' },
  federation_central: { level_code: 'federation_central', level_name: 'Central ou federação' },
  confederation: { level_code: 'confederation', level_name: 'Confederação' },
  national: { level_code: 'national', level_name: 'Nacional' },
  regional: { level_code: 'regional', level_name: 'Regional' },
  state: { level_code: 'state', level_name: 'Estadual' },
  matrix: { level_code: 'matrix', level_name: 'Matriz' },
  branch: { level_code: 'branch', level_name: 'Filial' },
  unit: { level_code: 'unit', level_name: 'Unidade' },
}

const ORGANIZATION_LEVEL_CODES_BY_TYPE: Record<string, string[]> = {
  cooperative: ['singular', 'federation_central', 'confederation'],
  system: ['national', 'regional', 'state'],
  company: ['matrix', 'branch', 'unit'],
}

function getOrganizationLevelsForType(
  organizationType: string,
  availableLevels: OrganizationLevel[],
) {
  const allowedCodes = ORGANIZATION_LEVEL_CODES_BY_TYPE[organizationType]

  if (!allowedCodes) {
    return availableLevels
  }

  const levelMap = new Map(
    availableLevels.map((level) => [level.level_code, level]),
  )

  return allowedCodes.map(
    (code) => levelMap.get(code) ?? CANONICAL_ORGANIZATION_LEVELS[code],
  )
}

const TAB_LABELS: Record<AdminTab, string> = {
  dashboard: 'Visão geral',
  organizations: 'Organizações',
  users: 'Usuários',
  memberships: 'Vínculos e acessos',
  modules: 'Módulos',
  roles: 'Perfis globais',
  invitations: 'Convites',
  portability: 'Importação, exportação e portabilidade',
}

function labelStatus(value: string | null | undefined) {
  if (!value) return 'Não informado'
  return STATUS_LABELS[value] ?? value
}

function labelOrganizationType(value: string | null | undefined) {
  if (!value) return 'Não informado'
  return ORGANIZATION_TYPE_LABELS[value] ?? value
}

function onlyDigits(value: string) {
  return value.replace(/\D/g, '')
}

function formatCnpjInput(value: string) {
  const digits = onlyDigits(value).slice(0, 14)
  return digits
    .replace(/^(\d{2})(\d)/, '$1.$2')
    .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
    .replace(/\.(\d{3})(\d)/, '.$1/$2')
    .replace(/(\d{4})(\d)/, '$1-$2')
}

function formatPostalCodeInput(value: string) {
  const digits = onlyDigits(value).slice(0, 8)
  return digits.replace(/^(\d{5})(\d)/, '$1-$2')
}

function formatDate(value: string | null | undefined) {
  if (!value) return '—'
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(new Date(value))
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value))
}

function getUserName(user: PlatformUser) {
  return user.display_name ?? user.full_name ?? user.email ?? user.user_id
}

function generateSecureTemporaryPassword(length = 16) {
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
  const lower = 'abcdefghijkmnopqrstuvwxyz'
  const numbers = '23456789'
  const symbols = '!@#$%&*?'
  const all = `${upper}${lower}${numbers}${symbols}`

  const pick = (source: string) => {
    const value = new Uint32Array(1)
    crypto.getRandomValues(value)
    return source[value[0] % source.length]
  }

  const characters = [pick(upper), pick(lower), pick(numbers), pick(symbols)]
  while (characters.length < Math.max(length, 12)) characters.push(pick(all))

  for (let index = characters.length - 1; index > 0; index -= 1) {
    const value = new Uint32Array(1)
    crypto.getRandomValues(value)
    const swapIndex = value[0] % (index + 1)
    ;[characters[index], characters[swapIndex]] = [characters[swapIndex], characters[index]]
  }

  return characters.join('')
}


function activateWithKeyboard(
  event: KeyboardEvent<HTMLElement>,
  action: () => void,
) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    action()
  }
}

function SearchIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <circle cx="11" cy="11" r="6.5" fill="none" stroke="currentColor" strokeWidth="1.8" />
      <path d="M16 16l4 4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  )
}

function CloseIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path d="M6 6l12 12M18 6L6 18" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  )
}

function EditIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path d="M4 20h4l11-11-4-4L4 16v4zM13.5 6.5l4 4" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function PrintIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path d="M7 8V4h10v4M7 17H5a2 2 0 01-2-2v-4a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2h-2M7 14h10v6H7z" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function SaveIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path
        d="M5 4h12l2 2v14H5zM8 4v6h8V4M8 20v-6h8v6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function WarningIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path
        d="M12 3L2.8 20h18.4L12 3zM12 9v5M12 17.5h.01"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function HierarchyIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path d="M12 5v4M5 19v-4h14v4M5 15v-3h14v3M12 9v3" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
      <rect x="9" y="2.5" width="6" height="3.5" rx="1" fill="none" stroke="currentColor" strokeWidth="1.6" />
      <rect x="2" y="18" width="6" height="3.5" rx="1" fill="none" stroke="currentColor" strokeWidth="1.6" />
      <rect x="9" y="18" width="6" height="3.5" rx="1" fill="none" stroke="currentColor" strokeWidth="1.6" />
      <rect x="16" y="18" width="6" height="3.5" rx="1" fill="none" stroke="currentColor" strokeWidth="1.6" />
    </svg>
  )
}

function ChevronIcon({ expanded }: { expanded: boolean }) {
  return (
    <svg className={expanded ? 'is-expanded' : ''} viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path d="M9 6l6 6-6 6" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function ViewToggle({
  value,
  onChange,
  showHierarchy = false,
}: {
  value: ViewMode
  onChange: (value: ViewMode) => void
  showHierarchy?: boolean
}) {
  return (
    <div className="pa-view-toggle" aria-label="Modo de visualização">
      <button type="button" className={value === 'cards' ? 'active' : ''} onClick={() => onChange('cards')} title="Visualizar em cards" aria-label="Visualizar em cards">▦</button>
      <button type="button" className={value === 'grid' ? 'active' : ''} onClick={() => onChange('grid')} title="Visualizar em linhas" aria-label="Visualizar em linhas">☷</button>
      {showHierarchy && (
        <button type="button" className={value === 'hierarchy' ? 'active' : ''} onClick={() => onChange('hierarchy')} title="Visualizar hierarquia" aria-label="Visualizar hierarquia">
          <HierarchyIcon />
        </button>
      )}
    </div>
  )
}

export function PlatformAdmin({ onBack }: PlatformAdminProps) {
  const [activeTab, setActiveTab] = useState<AdminTab>('dashboard')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState<'success' | 'error' | 'info'>('info')

  const [summary, setSummary] = useState<Summary>(EMPTY_SUMMARY)
  const [organizations, setOrganizations] = useState<Organization[]>([])
  const [organizationLevels, setOrganizationLevels] = useState<OrganizationLevel[]>([])
  const [users, setUsers] = useState<PlatformUser[]>([])
  const [memberships, setMemberships] = useState<Membership[]>([])
  const [modules, setModules] = useState<PlatformModule[]>([])
  const [roles, setRoles] = useState<PlatformRole[]>([])
  const [invitations, setInvitations] = useState<Invitation[]>([])
  const [cooperativeBranches, setCooperativeBranches] = useState<CooperativeBranch[]>([])

  const [search, setSearch] = useState('')
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc')
  const [viewMode, setViewMode] = useState<ViewMode>('cards')
  const [expandedOrganizationIds, setExpandedOrganizationIds] =
    useState<Set<string>>(() => new Set())

  const [organizationPanelOpen, setOrganizationPanelOpen] = useState(false)
  const [organizationForm, setOrganizationForm] = useState<OrganizationForm>(EMPTY_ORGANIZATION_FORM)
  const [organizationDetailTab, setOrganizationDetailTab] = useState<OrganizationDetailTab>('data')
  const [organizationLogoFile, setOrganizationLogoFile] = useState<File | null>(null)
  const [organizationLogoPreview, setOrganizationLogoPreview] = useState<string | null>(null)
  const [selectedCnaes, setSelectedCnaes] = useState<SelectedCnae[]>([])
  const [cnaeSearch, setCnaeSearch] = useState('')
  const [cnaeResults, setCnaeResults] = useState<CnaeCatalogSearchRow[]>([])
  const [searchingCnaes, setSearchingCnaes] = useState(false)
  const [cnaeSearchError, setCnaeSearchError] = useState('')
  const [lookingUpCep, setLookingUpCep] = useState(false)
  const [cepLookupMessage, setCepLookupMessage] = useState<{
    type: 'info' | 'success' | 'error'
    text: string
  } | null>(null)

  const [organizationDirty, setOrganizationDirty] = useState(false)
  const [organizationErrorField, setOrganizationErrorField] =
    useState<string | null>(null)

  const [userPanelOpen, setUserPanelOpen] = useState(false)
  const [userDetailTab, setUserDetailTab] = useState<UserDetailTab>('profile')
  const [userForm, setUserForm] = useState<UserForm>(EMPTY_USER_FORM)

  const [membershipPanelOpen, setMembershipPanelOpen] = useState(false)
  const [membershipForm, setMembershipForm] = useState<MembershipForm>(EMPTY_MEMBERSHIP_FORM)

  const [userCreationPanelOpen, setUserCreationPanelOpen] = useState(false)
  const [userCreationForm, setUserCreationForm] = useState<UserCreationForm>(EMPTY_USER_CREATION_FORM)
  const [showCreationPassword, setShowCreationPassword] = useState(false)

  const [invitationPanelOpen, setInvitationPanelOpen] = useState(false)
  const [invitationForm, setInvitationForm] = useState<InvitationForm>(EMPTY_INVITATION_FORM)

  const [selectedOrganizationForModules, setSelectedOrganizationForModules] = useState('')
  const [organizationModules, setOrganizationModules] = useState<OrganizationModule[]>([])

  const [selectedUserForRoles, setSelectedUserForRoles] = useState('')
  const [userRoles, setUserRoles] = useState<UserRole[]>([])
  const [organizationModuleRoles, setOrganizationModuleRoles] = useState<OrganizationModuleRole[]>([])
  const [loadingOrganizationModuleRoles, setLoadingOrganizationModuleRoles] = useState(false)
  const [userModuleRoles, setUserModuleRoles] = useState<UserModuleRole[]>([])
  const [userAudit, setUserAudit] = useState<UserAuditEvent[]>([])
  const [loadingUserRelations, setLoadingUserRelations] = useState(false)

  const showMessage = (text: string, type: 'success' | 'error' | 'info' = 'info') => {
    setMessage(text)
    setMessageType(type)
  }

  const clearMessage = () => {
    setMessage('')
    setMessageType('info')
  }

  const normalizeErrorText = (value: string) =>
    value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLocaleLowerCase('pt-BR')

  const resolveOrganizationErrorField = (reason: string) => {
    const normalized = normalizeErrorText(reason)

    if (normalized.includes('ramo cooperativista')) {
      return 'organization-field-branch'
    }
    if (normalized.includes('cnpj')) {
      return 'organization-field-cnpj'
    }
    if (normalized.includes('cep')) {
      return 'organization-field-postal-code'
    }
    if (normalized.includes('logradouro')) {
      return 'organization-field-street'
    }
    if (normalized.includes('numero')) {
      return 'organization-field-number'
    }
    if (normalized.includes('bairro')) {
      return 'organization-field-district'
    }
    if (normalized.includes('municipio') || normalized.includes('cidade')) {
      return 'organization-field-city'
    }
    if (normalized.includes('uf') || normalized.includes('estado')) {
      return 'organization-field-state'
    }
    if (normalized.includes('e-mail') || normalized.includes('email')) {
      return 'organization-field-email'
    }
    if (normalized.includes('cnae')) {
      return 'organization-field-cnaes'
    }
    if (normalized.includes('justificativa')) {
      return 'organization-field-change-reason'
    }

    return 'organization-form-top'
  }

  const focusOrganizationError = (fieldId: string) => {
    window.requestAnimationFrame(() => {
      const target = document.getElementById(fieldId)
      target?.scrollIntoView({
        behavior: 'smooth',
        block: 'center',
      })
      target
        ?.querySelector<HTMLElement>('input, select, textarea, button')
        ?.focus({ preventScroll: true })
    })
  }

  const reportOrganizationSaveError = (reason: string) => {
    const fieldId = resolveOrganizationErrorField(reason)
    setOrganizationErrorField(fieldId)
    showMessage(
      `Não foi possível salvar as alterações. ${reason} As informações alteradas continuam nesta tela, mas ainda não foram gravadas. Corrija a pendência e salve novamente. Se fechar, trocar de área ou atualizar a página, os dados alterados serão perdidos.`,
      'error',
    )
    focusOrganizationError(fieldId)
  }

  const requestCloseOrganizationPanel = () => {
    if (
      organizationDirty &&
      !window.confirm(
        'Existem alterações não salvas. Ao sair desta tela, as informações alteradas serão perdidas. Deseja sair sem salvar?',
      )
    ) {
      return
    }

    setOrganizationDirty(false)
    setOrganizationErrorField(null)
    clearMessage()
    setOrganizationPanelOpen(false)
  }

  const changeOrganizationDetailTab = (tab: OrganizationDetailTab) => {
    if (
      organizationDetailTab === 'data' &&
      tab !== 'data' &&
      organizationDirty &&
      !window.confirm(
        'Existem alterações não salvas nos dados gerais. Ao trocar de área, essas informações serão perdidas. Deseja continuar?',
      )
    ) {
      return
    }

    if (organizationDetailTab === 'data' && tab !== 'data') {
      setOrganizationDirty(false)
      setOrganizationErrorField(null)
      clearMessage()
    }

    setOrganizationDetailTab(tab)
  }

  const loadAll = async () => {
    setLoading(true)
    clearMessage()

    const [
      summaryResponse,
      organizationsResponse,
      levelsResponse,
      usersResponse,
      membershipsResponse,
      modulesResponse,
      rolesResponse,
      invitationsResponse,
      branchesResponse,
    ] = await Promise.all([
      supabase.rpc('get_platform_admin_summary'),
      supabase.rpc('get_platform_admin_organizations'),
      supabase.rpc('get_platform_admin_organization_levels'),
      supabase.rpc('get_platform_admin_users'),
      supabase.rpc('get_platform_admin_memberships', {
        filter_user_id: null,
        filter_organization_id: null,
      }),
      supabase.rpc('get_platform_admin_modules'),
      supabase.rpc('get_platform_admin_platform_roles'),
      supabase.rpc('get_platform_admin_invitations'),
      supabase.rpc('get_cooperative_branches', {
        include_inactive: false,
      }),
    ])

    const firstError = [
      summaryResponse.error,
      organizationsResponse.error,
      levelsResponse.error,
      usersResponse.error,
      membershipsResponse.error,
      modulesResponse.error,
      rolesResponse.error,
      invitationsResponse.error,
      branchesResponse.error,
    ].find(Boolean)

    if (firstError) {
      showMessage(`Não foi possível carregar a Administração da Plataforma: ${firstError.message}`, 'error')
      setLoading(false)
      return
    }

    setSummary(((summaryResponse.data ?? [EMPTY_SUMMARY])[0] ?? EMPTY_SUMMARY) as Summary)
    setOrganizations((organizationsResponse.data ?? []) as Organization[])
    setOrganizationLevels((levelsResponse.data ?? []) as OrganizationLevel[])
    setUsers((usersResponse.data ?? []) as PlatformUser[])
    setMemberships((membershipsResponse.data ?? []) as Membership[])
    setModules((modulesResponse.data ?? []) as PlatformModule[])
    setRoles((rolesResponse.data ?? []) as PlatformRole[])
    setInvitations((invitationsResponse.data ?? []) as Invitation[])
    setCooperativeBranches((branchesResponse.data ?? []) as CooperativeBranch[])
    setLoading(false)
  }

  useEffect(() => {
    void loadAll()
  }, [])

  useEffect(() => {
    if (!organizationPanelOpen || !organizationDirty) return

    const warnBeforeUnload = (event: BeforeUnloadEvent) => {
      event.preventDefault()
      event.returnValue = ''
    }

    window.addEventListener('beforeunload', warnBeforeUnload)
    return () =>
      window.removeEventListener('beforeunload', warnBeforeUnload)
  }, [organizationPanelOpen, organizationDirty])

  useEffect(() => {
    if (!selectedOrganizationForModules) {
      setOrganizationModules([])
      return
    }

    const loadOrganizationModules = async () => {
      const { data, error } = await supabase.rpc('get_platform_admin_organization_modules', {
        target_organization_id: selectedOrganizationForModules,
      })

      if (error) {
        showMessage(`Erro ao carregar módulos da organização: ${error.message}`, 'error')
        return
      }

      setOrganizationModules((data ?? []) as OrganizationModule[])
    }

    void loadOrganizationModules()
  }, [selectedOrganizationForModules])

  useEffect(() => {
    if (!selectedUserForRoles) {
      setUserRoles([])
      return
    }

    const loadUserRoles = async () => {
      const { data, error } = await supabase.rpc('get_platform_admin_user_roles', {
        target_user_id: selectedUserForRoles,
      })

      if (error) {
        showMessage(`Erro ao carregar perfis globais do usuário: ${error.message}`, 'error')
        return
      }

      setUserRoles((data ?? []) as UserRole[])
    }

    void loadUserRoles()
  }, [selectedUserForRoles])


  useEffect(() => {
    if (!selectedUserForRoles) {
      setUserModuleRoles([])
      setUserAudit([])
      return
    }

    const loadUserRelatedAccess = async () => {
      setLoadingUserRelations(true)
      const [moduleRolesResponse, auditResponse] = await Promise.all([
        supabase.rpc('get_platform_admin_user_module_roles', {
          target_user_id: selectedUserForRoles,
        }),
        supabase.rpc('get_platform_admin_user_audit', {
          target_user_id: selectedUserForRoles,
          limit_count: 150,
        }),
      ])

      if (moduleRolesResponse.error) {
        showMessage(`Erro ao carregar perfis por módulo: ${moduleRolesResponse.error.message}`, 'error')
        setUserModuleRoles([])
      } else {
        setUserModuleRoles((moduleRolesResponse.data ?? []) as UserModuleRole[])
      }

      if (auditResponse.error) {
        showMessage(`Erro ao carregar auditoria do usuário: ${auditResponse.error.message}`, 'error')
        setUserAudit([])
      } else {
        setUserAudit((auditResponse.data ?? []) as UserAuditEvent[])
      }

      setLoadingUserRelations(false)
    }

    void loadUserRelatedAccess()
  }, [selectedUserForRoles])


  useEffect(() => {
    const organizationId = userCreationForm.organizationId

    if (!organizationId) {
      setOrganizationModuleRoles([])
      setUserCreationForm((current) => ({
        ...current,
        moduleRoleAssignments: {},
        isOrganizationAdmin: false,
      }))
      return
    }

    const loadOrganizationModuleRoles = async () => {
      setLoadingOrganizationModuleRoles(true)
      const { data, error } = await supabase.rpc(
        'get_platform_admin_organization_module_roles',
        { target_organization_id: organizationId },
      )

      if (error) {
        showMessage(`Erro ao carregar os perfis dos módulos habilitados: ${error.message}`, 'error')
        setOrganizationModuleRoles([])
        setLoadingOrganizationModuleRoles(false)
        return
      }

      setOrganizationModuleRoles((data ?? []) as OrganizationModuleRole[])
      setLoadingOrganizationModuleRoles(false)
    }

    void loadOrganizationModuleRoles()
  }, [userCreationForm.organizationId])

  const normalizedSearch = search.trim().toLocaleLowerCase('pt-BR')

  const activePlatformRoles = useMemo(
    () => roles.filter((role) => role.active),
    [roles],
  )

  const visitorPlatformRole = useMemo(
    () => activePlatformRoles.find((role) => role.role_code === 'visitor') ?? null,
    [activePlatformRoles],
  )

  const visitorSelected = visitorPlatformRole
    ? userCreationForm.platformRoleIds.includes(visitorPlatformRole.platform_role_id)
    : false

  const moduleRoleGroups = useMemo(() => {
    const groups = new Map<string, {
      organizationModuleId: string
      moduleCode: string
      moduleName: string
      moduleShortName: string
      roles: OrganizationModuleRole[]
    }>()

    for (const role of organizationModuleRoles) {
      const current = groups.get(role.organization_module_id)
      if (current) {
        current.roles.push(role)
      } else {
        groups.set(role.organization_module_id, {
          organizationModuleId: role.organization_module_id,
          moduleCode: role.module_code,
          moduleName: role.module_name,
          moduleShortName: role.module_short_name,
          roles: [role],
        })
      }
    }

    return Array.from(groups.values()).map((group) => ({
      ...group,
      roles: [...group.roles].sort((a, b) =>
        b.role_level - a.role_level || a.role_name.localeCompare(b.role_name, 'pt-BR'),
      ),
    }))
  }, [organizationModuleRoles])

  const toggleCreationPlatformRole = (role: PlatformRole) => {
    setUserCreationForm((current) => {
      const isSelected = current.platformRoleIds.includes(role.platform_role_id)

      if (role.role_code === 'visitor') {
        return {
          ...current,
          platformRoleIds: isSelected ? [] : [role.platform_role_id],
          moduleRoleAssignments: {},
          isOrganizationAdmin: false,
        }
      }

      return {
        ...current,
        platformRoleIds: isSelected
          ? current.platformRoleIds.filter((id) => id !== role.platform_role_id)
          : [
              ...current.platformRoleIds.filter(
                (id) => id !== visitorPlatformRole?.platform_role_id,
              ),
              role.platform_role_id,
            ],
      }
    })
  }

  const setCreationModuleRole = (organizationModuleId: string, moduleRoleId: string) => {
    setUserCreationForm((current) => ({
      ...current,
      moduleRoleAssignments: {
        ...current.moduleRoleAssignments,
        [organizationModuleId]: moduleRoleId,
      },
    }))
  }


  const availableOrganizationLevels = useMemo(
    () =>
      getOrganizationLevelsForType(
        organizationForm.organizationType,
        organizationLevels,
      ),
    [organizationForm.organizationType, organizationLevels],
  )

  const changeOrganizationType = (organizationType: string) => {
    const nextLevels = getOrganizationLevelsForType(
      organizationType,
      organizationLevels,
    )

    setOrganizationForm((current) => ({
      ...current,
      organizationType,
      cooperativeBranchCode:
        organizationType === 'cooperative'
          ? current.cooperativeBranchCode
          : '',
      organizationLevel: nextLevels.some(
        (level) => level.level_code === current.organizationLevel,
      )
        ? current.organizationLevel
        : nextLevels[0]?.level_code ?? current.organizationLevel,
    }))
  }

  useEffect(() => {
    const term = cnaeSearch.trim()

    if (!organizationPanelOpen || term.length < 2) {
      setCnaeResults([])
      setCnaeSearchError('')
      setSearchingCnaes(false)
      return
    }

    let cancelled = false

    const timer = window.setTimeout(async () => {
      setSearchingCnaes(true)
      setCnaeSearchError('')

      const { data, error } = await supabase.rpc('search_cnae_catalog', {
        search_term: term,
        result_limit: 20,
        result_offset: 0,
      })

      if (cancelled) return

      if (error) {
        setCnaeResults([])
        setCnaeSearchError(error.message)
        setSearchingCnaes(false)
        return
      }

      const selectedIds = new Set(
        selectedCnaes.map((item) => item.cnaeCatalogId),
      )

      setCnaeResults(
        ((data ?? []) as CnaeCatalogSearchRow[]).filter(
          (item) => !selectedIds.has(item.cnae_catalog_id),
        ),
      )
      setSearchingCnaes(false)
    }, 300)

    return () => {
      cancelled = true
      window.clearTimeout(timer)
    }
  }, [cnaeSearch, organizationPanelOpen, selectedCnaes])

  const addCnae = (candidate: CnaeCatalogSearchRow) => {
    setOrganizationDirty(true)
    setOrganizationErrorField(null)

    if (
      selectedCnaes.some(
        (item) => item.cnaeCatalogId === candidate.cnae_catalog_id,
      )
    ) {
      return
    }

    const isFirst = selectedCnaes.length === 0
    setSelectedCnaes((current) => [
      ...current,
      {
        cnaeCatalogId: candidate.cnae_catalog_id,
        versionCode: candidate.version_code,
        subclassCode: candidate.subclass_code,
        formattedCode: candidate.formatted_code,
        description: candidate.description,
        isPrimary: isFirst,
      },
    ])
    setCnaeResults((current) =>
      current.filter(
        (item) => item.cnae_catalog_id !== candidate.cnae_catalog_id,
      ),
    )
  }

  const makePrimaryCnae = (cnaeCatalogId: string) => {
    setOrganizationDirty(true)
    setOrganizationErrorField(null)
    setSelectedCnaes((current) =>
      current.map((item) => ({
        ...item,
        isPrimary: item.cnaeCatalogId === cnaeCatalogId,
      })),
    )
  }

  const removeCnae = (cnaeCatalogId: string) => {
    setOrganizationDirty(true)
    setOrganizationErrorField(null)
    setSelectedCnaes((current) => {
      const removed = current.find(
        (item) => item.cnaeCatalogId === cnaeCatalogId,
      )
      const remaining = current.filter(
        (item) => item.cnaeCatalogId !== cnaeCatalogId,
      )

      if (removed?.isPrimary && remaining.length > 0) {
        remaining[0] = { ...remaining[0], isPrimary: true }
      }

      return remaining
    })
  }

  const lookupPostalCode = async () => {
    if (lookingUpCep) return

    const normalizedCep = onlyDigits(organizationForm.postalCode)
    if (normalizedCep.length !== 8) {
      setCepLookupMessage({
        type: 'error',
        text: 'Informe um CEP válido com oito dígitos.',
      })
      return
    }

    setLookingUpCep(true)
    setCepLookupMessage({
      type: 'info',
      text: 'Consultando o endereço...',
    })

    try {
      const { data, error } = await supabase.functions.invoke(
        'lookup-address-by-cep',
        { body: { cep: normalizedCep } },
      )

      if (error) {
        setCepLookupMessage({
          type: 'error',
          text: 'Não foi possível consultar o CEP. O endereço permanece disponível para preenchimento manual.',
        })
        return
      }

      const payload = data as {
        ok?: boolean
        address?: {
          cep?: string
          street?: string
          district?: string
          city?: string
          stateCode?: string
        }
        error?: string
      } | null

      if (!payload?.ok || !payload.address) {
        setCepLookupMessage({
          type: 'error',
          text:
            payload?.error ??
            'A consulta não retornou um endereço válido. Preencha os campos manualmente.',
        })
        return
      }

      const address = payload.address
      setOrganizationForm((current) => ({
        ...current,
        postalCode: formatPostalCodeInput(
          address.cep ?? normalizedCep,
        ),
        street: address.street?.trim() || current.street,
        district: address.district?.trim() || current.district,
        city: address.city?.trim() || current.city,
        stateCode:
          address.stateCode?.trim().toUpperCase() ||
          current.stateCode,
      }))
      setCepLookupMessage({
        type: 'success',
        text: 'Endereço localizado. Confira os dados e informe o número e o complemento.',
      })
    } finally {
      setLookingUpCep(false)
    }
  }

  const openUserMaintenance = (user: PlatformUser) => {
    setUserModuleRoles([])
    setUserAudit([])
    setUserForm({
      userId: user.user_id,
      fullName: user.full_name ?? '',
      displayName: user.display_name ?? '',
      phone: user.phone ?? '',
      active: user.active,
    })
    setSelectedUserForRoles(user.user_id)
    setUserDetailTab('profile')
    setUserPanelOpen(true)
  }

  const organizationMemberships = useMemo(
    () => memberships.filter((membership) => membership.organization_id === organizationForm.organizationId),
    [memberships, organizationForm.organizationId],
  )

  const organizationChildren = useMemo(
    () => organizations.filter((organization) => organization.parent_organization_id === organizationForm.organizationId),
    [organizations, organizationForm.organizationId],
  )

  const selectedOrganizationParent = useMemo(
    () => organizations.find((organization) => organization.organization_id === organizationForm.parentOrganizationId) ?? null,
    [organizations, organizationForm.parentOrganizationId],
  )

  const userMemberships = useMemo(
    () => memberships.filter((membership) => membership.user_id === userForm.userId),
    [memberships, userForm.userId],
  )


  const selectedUser = useMemo(
    () => users.find((user) => user.user_id === userForm.userId) ?? null,
    [users, userForm.userId],
  )

  const selectedUserIsVisitor = useMemo(
    () => userRoles.some((role) => role.role_code === 'visitor' && role.assigned),
    [userRoles],
  )

  const userModuleRoleGroups = useMemo(() => {
    const groups = new Map<string, {
      organizationId: string
      organizationCode: string
      organizationName: string
      membershipStatus: string
      organizationModuleId: string
      moduleCode: string
      moduleName: string
      moduleShortName: string
      assignedRoleId: string
      roles: UserModuleRole[]
    }>()

    for (const role of userModuleRoles) {
      const current = groups.get(role.organization_module_id)
      if (current) {
        current.roles.push(role)
        if (role.assigned) current.assignedRoleId = role.module_role_id
      } else {
        groups.set(role.organization_module_id, {
          organizationId: role.organization_id,
          organizationCode: role.organization_code,
          organizationName: role.organization_name,
          membershipStatus: role.membership_status,
          organizationModuleId: role.organization_module_id,
          moduleCode: role.module_code,
          moduleName: role.module_name,
          moduleShortName: role.module_short_name,
          assignedRoleId: role.assigned ? role.module_role_id : '',
          roles: [role],
        })
      }
    }

    return Array.from(groups.values()).map((group) => ({
      ...group,
      roles: [...group.roles].sort((a, b) =>
        b.role_level - a.role_level || a.role_name.localeCompare(b.role_name, 'pt-BR'),
      ),
    }))
  }, [userModuleRoles])

  const assignedModuleRolesCount = useMemo(
    () => userModuleRoleGroups.filter((group) => Boolean(group.assignedRoleId)).length,
    [userModuleRoleGroups],
  )

  const organizationMatchesSearch = (organization: Organization) => {
    if (!normalizedSearch) return true

    return [
      organization.organization_code,
      organization.trade_name,
      organization.legal_name,
      organization.cnpj,
      organization.city,
      organization.cooperative_branch,
      organization.parent_organization_name,
    ]
      .filter(Boolean)
      .some((value) =>
        String(value).toLocaleLowerCase('pt-BR').includes(normalizedSearch),
      )
  }

  const filteredOrganizations = useMemo(() => {
    return [...organizations]
      .filter(organizationMatchesSearch)
      .sort((first, second) => {
        const comparison = (first.trade_name ?? first.legal_name).localeCompare(second.trade_name ?? second.legal_name, 'pt-BR')
        return sortDirection === 'asc' ? comparison : -comparison
      })
  }, [organizations, normalizedSearch, sortDirection])

  const organizationHierarchy = useMemo(() => {
    const byId = new Map(
      organizations.map((organization) => [organization.organization_id, organization]),
    )
    const childrenByParent = new Map<string, Organization[]>()
    const rootKey = '__root__'

    const compareOrganizations = (first: Organization, second: Organization) => {
      const comparison = (first.trade_name ?? first.legal_name).localeCompare(second.trade_name ?? second.legal_name, 'pt-BR')
      return sortDirection === 'asc' ? comparison : -comparison
    }

    for (const organization of organizations) {
      const parentId = organization.parent_organization_id
      const parentKey = parentId && byId.has(parentId) ? parentId : rootKey
      const children = childrenByParent.get(parentKey) ?? []
      children.push(organization)
      childrenByParent.set(parentKey, children)
    }

    for (const children of childrenByParent.values()) {
      children.sort(compareOrganizations)
    }

    const matchIds = new Set<string>()
    const visibleIds = new Set<string>()

    if (!normalizedSearch) {
      for (const organization of organizations) {
        visibleIds.add(organization.organization_id)
      }
    } else {
      for (const organization of organizations) {
        if (!organizationMatchesSearch(organization)) continue

        matchIds.add(organization.organization_id)
        visibleIds.add(organization.organization_id)

        let parentId = organization.parent_organization_id
        const visited = new Set<string>([organization.organization_id])

        while (parentId && !visited.has(parentId)) {
          visited.add(parentId)
          const parent = byId.get(parentId)
          if (!parent) break
          visibleIds.add(parent.organization_id)
          parentId = parent.parent_organization_id
        }
      }
    }

    const roots = (childrenByParent.get(rootKey) ?? []).filter(
      (organization) => visibleIds.has(organization.organization_id),
    )
    const expandableIds: string[] = []

    for (const organization of organizations) {
      const visibleChildren = (childrenByParent.get(organization.organization_id) ?? []).filter(
        (child) => visibleIds.has(child.organization_id),
      )
      if (visibleChildren.length > 0) expandableIds.push(organization.organization_id)
    }

    return { byId, childrenByParent, roots, visibleIds, matchIds, expandableIds }
  }, [organizations, normalizedSearch, sortDirection])

  useEffect(() => {
    if (activeTab !== 'organizations' && viewMode === 'hierarchy') {
      setViewMode('cards')
    }
  }, [activeTab, viewMode])

  useEffect(() => {
    if (viewMode !== 'hierarchy') return
    setExpandedOrganizationIds(new Set(organizationHierarchy.expandableIds))
  }, [viewMode, normalizedSearch, organizations])

  const toggleOrganizationExpansion = (organizationId: string) => {
    setExpandedOrganizationIds((current) => {
      const next = new Set(current)
      if (next.has(organizationId)) next.delete(organizationId)
      else next.add(organizationId)
      return next
    })
  }

  const expandAllOrganizations = () => {
    setExpandedOrganizationIds(new Set(organizationHierarchy.expandableIds))
  }

  const collapseAllOrganizations = () => {
    setExpandedOrganizationIds(new Set())
  }

  const filteredUsers = useMemo(() => {
    return [...users]
      .filter((user) => {
        if (!normalizedSearch) return true
        return [getUserName(user), user.email, user.platform_roles].filter(Boolean).some((value) => String(value).toLocaleLowerCase('pt-BR').includes(normalizedSearch))
      })
      .sort((first, second) => {
        const comparison = getUserName(first).localeCompare(getUserName(second), 'pt-BR')
        return sortDirection === 'asc' ? comparison : -comparison
      })
  }, [users, normalizedSearch, sortDirection])

  const filteredMemberships = useMemo(() => {
    return [...memberships]
      .filter((membership) => {
        if (!normalizedSearch) return true
        return [membership.user_name, membership.user_email, membership.organization_name, membership.job_title].filter(Boolean).some((value) => String(value).toLocaleLowerCase('pt-BR').includes(normalizedSearch))
      })
      .sort((first, second) => {
        const comparison = first.organization_name.localeCompare(second.organization_name, 'pt-BR') || first.user_name.localeCompare(second.user_name, 'pt-BR')
        return sortDirection === 'asc' ? comparison : -comparison
      })
  }, [memberships, normalizedSearch, sortDirection])

  const filteredModules = useMemo(() => {
    return [...modules]
      .filter((module) => !normalizedSearch || [module.module_code, module.module_name, module.module_short_name].some((value) => value.toLocaleLowerCase('pt-BR').includes(normalizedSearch)))
      .sort((first, second) => {
        const comparison = first.module_name.localeCompare(second.module_name, 'pt-BR')
        return sortDirection === 'asc' ? comparison : -comparison
      })
  }, [modules, normalizedSearch, sortDirection])

  const filteredRoles = useMemo(() => {
    return [...roles]
      .filter((role) => !normalizedSearch || [role.role_code, role.role_name, role.description].filter(Boolean).some((value) => String(value).toLocaleLowerCase('pt-BR').includes(normalizedSearch)))
      .sort((first, second) => {
        const comparison = first.role_name.localeCompare(second.role_name, 'pt-BR')
        return sortDirection === 'asc' ? comparison : -comparison
      })
  }, [roles, normalizedSearch, sortDirection])

  const filteredInvitations = useMemo(() => {
    return [...invitations]
      .filter((invitation) => !normalizedSearch || [invitation.email, invitation.full_name, invitation.organization_name, invitation.platform_role_name].filter(Boolean).some((value) => String(value).toLocaleLowerCase('pt-BR').includes(normalizedSearch)))
      .sort((first, second) => {
        const firstName = first.full_name ?? first.email
        const secondName = second.full_name ?? second.email
        const comparison = firstName.localeCompare(secondName, 'pt-BR')
        return sortDirection === 'asc' ? comparison : -comparison
      })
  }, [invitations, normalizedSearch, sortDirection])

  const applyOrganizationToForm = (organization: Organization) => {
    const activities = organization.economic_activities ?? []
    const officialActivities = activities.filter(
      (activity) => Boolean(activity.cnae_catalog_id),
    )
    const sourceActivity =
      officialActivities.find((activity) => activity.is_primary) ??
      officialActivities[0]

    setSelectedCnaes(
      officialActivities.map((activity) => ({
        cnaeCatalogId: activity.cnae_catalog_id as string,
        versionCode: activity.version_code ?? '2.3',
        subclassCode: activity.subclass_code,
        formattedCode: activity.formatted_code,
        description: activity.description,
        isPrimary: activity.is_primary,
      })),
    )
    setCnaeSearch('')
    setCnaeResults([])
    setCnaeSearchError('')
    setCepLookupMessage(null)
    setOrganizationDirty(false)
    setOrganizationErrorField(null)

    setOrganizationForm({
      organizationId: organization.organization_id,
      code: organization.organization_code,
      legalName: organization.legal_name,
      tradeName: organization.trade_name ?? '',
      organizationLevel: organization.organization_level,
      organizationType: organization.organization_type ?? 'other',
      status: organization.status,
      parentOrganizationId: organization.parent_organization_id ?? '',
      cnpj: formatCnpjInput(organization.cnpj ?? ''),
      cooperativeBranchCode:
        organization.cooperative_branch_code ??
        cooperativeBranches.find(
          (branch) =>
            branch.branch_id === organization.cooperative_branch_id ||
            branch.branch_name === organization.cooperative_branch,
        )?.branch_code ??
        '',
      institutionalEmail: organization.institutional_email ?? '',
      phone: organization.phone ?? '',
      website: organization.website ?? '',
      postalCode: formatPostalCodeInput(organization.postal_code ?? ''),
      street: organization.street ?? '',
      addressNumber: organization.address_number ?? '',
      addressComplement: organization.address_complement ?? '',
      district: organization.district ?? '',
      city: organization.city ?? '',
      stateCode: organization.state_code ?? '',
      countryCode: organization.country_code ?? 'BR',
      cnaeSourceType: sourceActivity?.source_type ?? 'manual_confirmed',
      cnaeSourceReference: sourceActivity?.source_reference ?? '',
      description: organization.description ?? '',
      changeReason: '',
    })
  }

  const openNewOrganization = () => {
    clearMessage()
    setOrganizationDirty(false)
    setOrganizationErrorField(null)
    setOrganizationLogoFile(null)
    setOrganizationLogoPreview(null)
    setSelectedCnaes([])
    setCnaeSearch('')
    setCnaeResults([])
    setCnaeSearchError('')
    setCepLookupMessage(null)
    setOrganizationForm({
      ...EMPTY_ORGANIZATION_FORM,
      organizationLevel: getOrganizationLevelsForType(
        EMPTY_ORGANIZATION_FORM.organizationType,
        organizationLevels,
      )[0]?.level_code ?? 'singular',
    })
    setSelectedOrganizationForModules('')
    setOrganizationDetailTab('data')
    setOrganizationPanelOpen(true)
  }

  const openOrganizationEdit = async (organization: Organization) => {
    if (
      organizationPanelOpen &&
      organizationDirty &&
      !window.confirm(
        'Existem alterações não salvas. Ao abrir outra organização, as informações alteradas serão perdidas. Deseja continuar?',
      )
    ) {
      return
    }

    clearMessage()
    setOrganizationDirty(false)
    setOrganizationErrorField(null)
    setOrganizationLogoFile(null)
    setOrganizationLogoPreview(null)
    applyOrganizationToForm(organization)
    setSelectedOrganizationForModules(organization.organization_id)
    setOrganizationDetailTab('data')
    setOrganizationPanelOpen(true)

    const [detailResponse, brandingResponse] = await Promise.all([
      supabase.rpc('get_platform_admin_organization_detail_v2', {
        target_organization_id: organization.organization_id,
      }),
      supabase.rpc('get_platform_admin_organization_branding', {
        target_organization_id: organization.organization_id,
      }),
    ])

    if (detailResponse.error) {
      showMessage(`A organização foi aberta, mas o detalhe completo não pôde ser atualizado: ${detailResponse.error.message}`, 'error')
    } else {
      const detailedOrganization = ((detailResponse.data ?? []) as Organization[])[0]
      if (detailedOrganization) applyOrganizationToForm(detailedOrganization)
    }

    if (!brandingResponse.error) {
      const branding = ((brandingResponse.data ?? []) as Array<{ logo_url: string | null; logo_storage_path: string | null }>)[0]
      if (branding?.logo_storage_path) {
        const { data: signedData } = await supabase.storage
          .from('organization-branding')
          .createSignedUrl(branding.logo_storage_path, 60 * 60)
        setOrganizationLogoPreview(signedData?.signedUrl ?? branding.logo_url ?? null)
      } else {
        setOrganizationLogoPreview(branding?.logo_url ?? null)
      }
    }
  }

  const saveOrganization = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    clearMessage()
    setOrganizationErrorField(null)

    if (!organizationForm.code.trim() || !organizationForm.legalName.trim()) {
      reportOrganizationSaveError(
        'Informe o código e a razão social da organização.',
      )
      return
    }

    if (organizationForm.changeReason.trim().length < 10) {
      reportOrganizationSaveError(
        'Informe uma justificativa com pelo menos 10 caracteres.',
      )
      return
    }

    if (
      selectedCnaes.length > 0 &&
      selectedCnaes.filter((item) => item.isPrimary).length !== 1
    ) {
      reportOrganizationSaveError(
        'Selecione exatamente um CNAE principal.',
      )
      return
    }

    setSaving(true)

    try {
      const { data, error } = await supabase.rpc(
        'upsert_platform_admin_organization_v2',
        {
          target_organization_id: organizationForm.organizationId,
          payload: {
            code: organizationForm.code,
            legal_name: organizationForm.legalName,
            trade_name: organizationForm.tradeName,
            organization_level: organizationForm.organizationLevel,
            organization_type: organizationForm.organizationType,
            status: organizationForm.status,
            parent_organization_id:
              organizationForm.parentOrganizationId || null,
            cnpj: onlyDigits(organizationForm.cnpj),
            cooperative_branch_code:
              organizationForm.organizationType === 'cooperative'
                ? organizationForm.cooperativeBranchCode || null
                : null,
            institutional_email:
              organizationForm.institutionalEmail || null,
            phone: organizationForm.phone || null,
            website: organizationForm.website || null,
            postal_code: onlyDigits(organizationForm.postalCode),
            street: organizationForm.street || null,
            address_number: organizationForm.addressNumber || null,
            address_complement:
              organizationForm.addressComplement || null,
            district: organizationForm.district || null,
            city: organizationForm.city || null,
            state_code: organizationForm.stateCode || null,
            country_code: organizationForm.countryCode || 'BR',
            selected_cnaes: selectedCnaes.map((item) => ({
              cnae_catalog_id: item.cnaeCatalogId,
              is_primary: item.isPrimary,
            })),
            cnae_source_type: organizationForm.cnaeSourceType,
            cnae_source_reference:
              organizationForm.cnaeSourceReference || null,
            description: organizationForm.description || null,
            change_reason: organizationForm.changeReason,
          },
        },
      )

      if (error) {
        reportOrganizationSaveError(error.message)
        return
      }

      const savedOrganizationId = String(
        data ?? organizationForm.organizationId ?? '',
      )
      if (!savedOrganizationId) {
        showMessage(
          'A operação não retornou o identificador da organização salva.',
          'error',
        )
        return
      }

      if (organizationLogoFile) {
        if (organizationLogoFile.size > 5 * 1024 * 1024) {
          showMessage(
            'A organização foi salva, mas a logo excede o limite de 5 MB.',
            'error',
          )
          return
        }

        const extension =
          organizationLogoFile.name.split('.').pop()?.toLowerCase() ||
          'png'
        const logoStoragePath =
          `${savedOrganizationId}/logo/logo-institucional-${Date.now()}.${extension}`
        const { error: uploadError } = await supabase.storage
          .from('organization-branding')
          .upload(logoStoragePath, organizationLogoFile, {
            upsert: true,
            contentType: organizationLogoFile.type,
          })

        if (uploadError) {
          showMessage(
            `A organização foi salva, mas não foi possível enviar a logo: ${uploadError.message}`,
            'error',
          )
          return
        }

        const { error: logoError } = await supabase.rpc(
          'set_platform_admin_organization_logo',
          {
            target_organization_id: savedOrganizationId,
            target_logo_storage_path: logoStoragePath,
            change_reason:
              'Atualização da identidade visual pela Administração da Plataforma.',
          },
        )

        if (logoError) {
          showMessage(
            `A organização foi salva, mas a identidade visual não pôde ser vinculada: ${logoError.message}`,
            'error',
          )
          return
        }

        const { data: signedData } = await supabase.storage
          .from('organization-branding')
          .createSignedUrl(logoStoragePath, 60 * 60)
        setOrganizationLogoPreview(signedData?.signedUrl ?? null)
        setOrganizationLogoFile(null)
      }

      const { data: refreshedData, error: refreshError } =
        await supabase.rpc(
          'get_platform_admin_organization_detail_v2',
          { target_organization_id: savedOrganizationId },
        )

      if (refreshError) {
        showMessage(
          `A organização foi salva, mas não foi possível reler os dados persistidos: ${refreshError.message}`,
          'error',
        )
        await loadAll()
        return
      }

      const persistedOrganization =
        ((refreshedData ?? []) as Organization[])[0]
      if (!persistedOrganization) {
        showMessage(
          'A organização foi salva, mas o registro persistido não foi localizado para conferência.',
          'error',
        )
        await loadAll()
        return
      }

      applyOrganizationToForm(persistedOrganization)
      setOrganizationDirty(false)
      setOrganizationErrorField(null)
      setSelectedOrganizationForModules(savedOrganizationId)
      await loadAll()
      showMessage(
        organizationForm.organizationId
          ? 'Organização atualizada e conferida com sucesso.'
          : 'Organização criada e conferida com sucesso.',
        'success',
      )
      setOrganizationPanelOpen(false)
      setOrganizationDetailTab('data')
    } finally {
      setSaving(false)
    }
  }

  const openNewMembership = () => {
    setMembershipForm(EMPTY_MEMBERSHIP_FORM)
    setMembershipPanelOpen(true)
  }

  const openNewMembershipForOrganization = (organizationId: string) => {
    setMembershipForm({ ...EMPTY_MEMBERSHIP_FORM, organizationId })
    setMembershipPanelOpen(true)
  }

  const openNewMembershipForUser = (userId: string) => {
    setMembershipForm({ ...EMPTY_MEMBERSHIP_FORM, userId })
    setMembershipPanelOpen(true)
  }

  const saveUserProfile = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaving(true)
    clearMessage()

    const { error } = await supabase.rpc('update_platform_admin_user_profile', {
      target_user_id: userForm.userId,
      input_full_name: userForm.fullName || null,
      input_display_name: userForm.displayName || null,
      input_phone: userForm.phone || null,
      input_active: userForm.active,
    })

    if (error) {
      showMessage(`Não foi possível salvar o usuário: ${error.message}`, 'error')
      setSaving(false)
      return
    }

    await loadAll()
    const { data: auditData } = await supabase.rpc('get_platform_admin_user_audit', {
      target_user_id: userForm.userId,
      limit_count: 150,
    })
    setUserAudit((auditData ?? []) as UserAuditEvent[])
    showMessage('Usuário atualizado com sucesso.', 'success')
    setSaving(false)
  }

  const openMembershipEdit = (membership: Membership) => {
    setMembershipForm({
      membershipId: membership.membership_id,
      organizationId: membership.organization_id,
      userId: membership.user_id,
      status: membership.membership_status,
      isOrganizationAdmin: membership.is_organization_admin,
      jobTitle: membership.job_title ?? '',
      validUntil: membership.valid_until ? membership.valid_until.slice(0, 10) : '',
      reason: '',
    })
    setMembershipPanelOpen(true)
  }

  const saveMembership = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaving(true)
    clearMessage()

    const { error } = await supabase.rpc('upsert_platform_admin_membership', {
      target_membership_id: membershipForm.membershipId,
      target_organization_id: membershipForm.organizationId,
      target_user_id: membershipForm.userId,
      input_status: membershipForm.status,
      input_is_organization_admin: membershipForm.isOrganizationAdmin,
      input_job_title: membershipForm.jobTitle || null,
      input_valid_until: membershipForm.validUntil ? `${membershipForm.validUntil}T23:59:59-03:00` : null,
      input_reason: membershipForm.reason,
    })

    if (error) {
      showMessage(`Não foi possível salvar o vínculo: ${error.message}`, 'error')
      setSaving(false)
      return
    }

    setMembershipPanelOpen(false)
    showMessage('Vínculo organizacional salvo com sucesso.', 'success')
    await loadAll()
    if (membershipForm.userId === userForm.userId) {
      const [moduleRolesResponse, auditResponse] = await Promise.all([
        supabase.rpc('get_platform_admin_user_module_roles', { target_user_id: userForm.userId }),
        supabase.rpc('get_platform_admin_user_audit', { target_user_id: userForm.userId, limit_count: 150 }),
      ])
      if (!moduleRolesResponse.error) setUserModuleRoles((moduleRolesResponse.data ?? []) as UserModuleRole[])
      if (!auditResponse.error) setUserAudit((auditResponse.data ?? []) as UserAuditEvent[])
    }
    setSaving(false)
  }

  const createUserDirectly = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaving(true)
    clearMessage()

    if (!userCreationForm.fullName.trim()) {
      showMessage('Informe o nome completo do usuário.', 'error')
      setSaving(false)
      return
    }

    if (userCreationForm.password.length < 10) {
      showMessage('A senha inicial deve possuir pelo menos 10 caracteres.', 'error')
      setSaving(false)
      return
    }

    if (userCreationForm.password !== userCreationForm.confirmPassword) {
      showMessage('A confirmação da senha não corresponde à senha inicial.', 'error')
      setSaving(false)
      return
    }

    if (userCreationForm.isOrganizationAdmin && !userCreationForm.organizationId) {
      showMessage('Selecione uma organização para definir o usuário como administrador local.', 'error')
      setSaving(false)
      return
    }

    if (visitorSelected && !userCreationForm.organizationId) {
      showMessage('O perfil VISITANTE exige ao menos uma organização inicial para definir o escopo de consulta.', 'error')
      setSaving(false)
      return
    }

    if (visitorSelected && userCreationForm.isOrganizationAdmin) {
      showMessage('O VISITANTE não pode ser administrador da organização.', 'error')
      setSaving(false)
      return
    }

    const moduleRoleAssignments = Object.entries(userCreationForm.moduleRoleAssignments)
      .filter(([, moduleRoleId]) => Boolean(moduleRoleId))
      .map(([organizationModuleId, moduleRoleId]) => ({
        organizationModuleId,
        moduleRoleId,
      }))

    const { data, error } = await supabase.functions.invoke('create-platform-user', {
      body: {
        email: userCreationForm.email,
        password: userCreationForm.password,
        fullName: userCreationForm.fullName,
        phone: userCreationForm.phone || null,
        organizationId: userCreationForm.organizationId || null,
        platformRoleIds: userCreationForm.platformRoleIds,
        moduleRoleAssignments: visitorSelected ? [] : moduleRoleAssignments,
        isOrganizationAdmin: visitorSelected ? false : userCreationForm.isOrganizationAdmin,
        jobTitle: userCreationForm.jobTitle || null,
      },
    })

    const functionError = data && typeof data === 'object' && 'error' in data
      ? String((data as { error?: unknown }).error ?? '')
      : ''

    if (error || functionError) {
      showMessage(`Não foi possível criar o usuário: ${functionError || error?.message || 'erro não identificado'}. Confirme se a Edge Function create-platform-user foi implantada.`, 'error')
      setSaving(false)
      return
    }

    setUserCreationPanelOpen(false)
    setUserCreationForm(EMPTY_USER_CREATION_FORM)
    setShowCreationPassword(false)
    showMessage('Usuário criado e ativado com sucesso, sem envio de convite.', 'success')
    await loadAll()
    setSaving(false)
  }

  const sendInvitation = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaving(true)
    clearMessage()

    const { error } = await supabase.functions.invoke('invite-platform-user', {
      body: {
        email: invitationForm.email,
        fullName: invitationForm.fullName || null,
        organizationId: invitationForm.organizationId || null,
        platformRoleId: invitationForm.platformRoleId || null,
        isOrganizationAdmin: invitationForm.isOrganizationAdmin,
        jobTitle: invitationForm.jobTitle || null,
        redirectTo: window.location.origin,
      },
    })

    if (error) {
      showMessage(`Não foi possível enviar o convite: ${error.message}. Confirme se a Edge Function invite-platform-user foi implantada.`, 'error')
      setSaving(false)
      return
    }

    setInvitationPanelOpen(false)
    setInvitationForm(EMPTY_INVITATION_FORM)
    showMessage('Convite enviado e registrado com sucesso.', 'success')
    await loadAll()
    setSaving(false)
  }

  const toggleOrganizationModule = async (module: OrganizationModule) => {
    const nextEnabled = !module.enabled
    const reason = window.prompt(
      nextEnabled
        ? 'Informe a justificativa para habilitar este módulo:'
        : 'Informe a justificativa para desabilitar este módulo:',
      'Manutenção realizada pela Administração da Plataforma.',
    )

    if (!reason?.trim()) return

    const { error } = await supabase.rpc('set_platform_admin_organization_module', {
      target_organization_id: selectedOrganizationForModules,
      target_module_id: module.module_id,
      input_enabled: nextEnabled,
      input_reason: reason.trim(),
    })

    if (error) {
      showMessage(`Não foi possível alterar o módulo: ${error.message}`, 'error')
      return
    }

    setOrganizationModules((current) => current.map((item) => item.module_id === module.module_id ? { ...item, enabled: nextEnabled, organization_module_status: nextEnabled ? 'active' : 'cancelled' } : item))
    showMessage('Habilitação do módulo atualizada.', 'success')
    await loadAll()
  }

  const toggleUserRole = async (role: UserRole) => {
    const reason = window.prompt(
      role.assigned
        ? `Informe a justificativa para revogar ${role.role_name}:`
        : `Informe a justificativa para atribuir ${role.role_name}:`,
      'Manutenção realizada pela Administração da Plataforma.',
    )

    if (!reason?.trim()) return

    const { error } = await supabase.rpc('set_platform_admin_user_role', {
      target_user_id: selectedUserForRoles,
      target_platform_role_id: role.platform_role_id,
      input_assigned: !role.assigned,
      input_reason: reason.trim(),
    })

    if (error) {
      showMessage(`Não foi possível alterar o perfil global: ${error.message}`, 'error')
      return
    }

    setUserRoles((current) => current.map((item) => item.platform_role_id === role.platform_role_id ? { ...item, assigned: !item.assigned, assignment_status: !item.assigned ? 'active' : 'revoked' } : item))
    showMessage('Perfil global do usuário atualizado.', 'success')
    await loadAll()
    const { data: auditData } = await supabase.rpc('get_platform_admin_user_audit', {
      target_user_id: selectedUserForRoles,
      limit_count: 150,
    })
    setUserAudit((auditData ?? []) as UserAuditEvent[])
  }

  const changeUserModuleRole = async (
    organizationModuleId: string,
    moduleName: string,
    nextRoleId: string,
  ) => {
    const reason = window.prompt(
      nextRoleId
        ? `Informe a justificativa para alterar o perfil em ${moduleName}:`
        : `Informe a justificativa para revogar o perfil em ${moduleName}:`,
      'Manutenção realizada pela Administração da Plataforma.',
    )

    if (!reason?.trim()) return

    const { error } = await supabase.rpc('set_platform_admin_user_module_role', {
      target_user_id: userForm.userId,
      target_organization_module_id: organizationModuleId,
      target_module_role_id: nextRoleId || null,
      input_valid_until: null,
      input_reason: reason.trim(),
    })

    if (error) {
      showMessage(`Não foi possível alterar o perfil por módulo: ${error.message}`, 'error')
      return
    }

    const [moduleRolesResponse, auditResponse] = await Promise.all([
      supabase.rpc('get_platform_admin_user_module_roles', {
        target_user_id: userForm.userId,
      }),
      supabase.rpc('get_platform_admin_user_audit', {
        target_user_id: userForm.userId,
        limit_count: 150,
      }),
    ])

    if (!moduleRolesResponse.error) {
      setUserModuleRoles((moduleRolesResponse.data ?? []) as UserModuleRole[])
    }
    if (!auditResponse.error) {
      setUserAudit((auditResponse.data ?? []) as UserAuditEvent[])
    }

    showMessage('Perfil por módulo atualizado com sucesso.', 'success')
    await loadAll()
  }

  const scrollToPageTop = () => {
    const scrollingElement = document.scrollingElement
    scrollingElement?.scrollTo({ top: 0, behavior: 'smooth' })
    document.documentElement.scrollTop = 0
    document.body.scrollTop = 0
    window.scrollTo({ top: 0, behavior: 'smooth' })
    document.querySelector<HTMLElement>('.platform-content')?.scrollTo({ top: 0, behavior: 'smooth' })
    document.querySelector<HTMLElement>('.pa-side-panel')?.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const printCurrentView = () => {
    window.print()
  }

  function renderOrganizationHierarchyNode(organization: Organization) {
    const children = (organizationHierarchy.childrenByParent.get(organization.organization_id) ?? []).filter(
      (child) => organizationHierarchy.visibleIds.has(child.organization_id),
    )
    const totalChildren = (organizationHierarchy.childrenByParent.get(organization.organization_id) ?? []).length
    const hasChildren = children.length > 0
    const expanded = expandedOrganizationIds.has(organization.organization_id)
    const isSearchMatch = organizationHierarchy.matchIds.has(organization.organization_id)
    const missingParent = Boolean(
      organization.parent_organization_id &&
        !organizationHierarchy.byId.has(organization.parent_organization_id),
    )
    const levelLabel = organizationLevels.find(
      (level) => level.level_code === organization.organization_level,
    )?.level_name ?? organization.organization_level

    return (
      <div className="pa-hierarchy-branch" key={organization.organization_id}>
        <div className={`pa-hierarchy-node ${isSearchMatch ? 'is-search-match' : ''} ${missingParent ? 'has-hierarchy-warning' : ''}`}>
          <button
            type="button"
            className="pa-hierarchy-expand-button"
            onClick={() => toggleOrganizationExpansion(organization.organization_id)}
            disabled={!hasChildren}
            aria-label={hasChildren ? (expanded ? `Recolher subordinadas de ${organization.trade_name ?? organization.legal_name}` : `Expandir subordinadas de ${organization.trade_name ?? organization.legal_name}`) : 'Organização sem subordinadas visíveis'}
            title={hasChildren ? (expanded ? 'Recolher subordinadas' : 'Expandir subordinadas') : 'Sem subordinadas'}
          >
            {hasChildren ? <ChevronIcon expanded={expanded} /> : <span aria-hidden="true">•</span>}
          </button>

          <button type="button" className="pa-hierarchy-main" onClick={() => void openOrganizationEdit(organization)}>
            <span className="pa-hierarchy-code">{organization.organization_code}</span>
            <span className="pa-hierarchy-name">
              <strong>{organization.trade_name ?? organization.legal_name}</strong>
              <small>{labelOrganizationType(organization.organization_type)} · {levelLabel}</small>
            </span>
          </button>

          <div className="pa-hierarchy-metrics" aria-label="Resumo da organização">
            <span title="Subordinadas diretas">{totalChildren} subordinada(s)</span>
            <span title="Usuários vinculados">{organization.memberships_count} usuário(s)</span>
            <span title="Módulos habilitados">{organization.enabled_modules_count} módulo(s)</span>
          </div>

          <span className={`pa-status pa-status-${organization.status}`}>{labelStatus(organization.status)}</span>

          <div className="pa-hierarchy-actions">
            <button type="button" title="Editar organização" aria-label={`Editar ${organization.trade_name ?? organization.legal_name}`} onClick={() => void openOrganizationEdit(organization)}>
              <EditIcon />
            </button>
          </div>
        </div>

        {missingParent && (
          <div className="pa-hierarchy-warning" role="status">
            A organização superior informada não foi encontrada no cadastro mestre.
          </div>
        )}

        {hasChildren && expanded && (
          <div className="pa-hierarchy-children">
            {children.map((child) => renderOrganizationHierarchyNode(child))}
          </div>
        )}
      </div>
    )
  }

  const toolbar = (actionLabel?: string, action?: () => void) => (
    <section className="pa-toolbar">
      <div className="pa-search">
        <SearchIcon />
        <input
          type="search"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder={`Pesquisar em ${TAB_LABELS[activeTab].toLocaleLowerCase('pt-BR')}`}
          aria-label={`Pesquisar em ${TAB_LABELS[activeTab]}`}
        />
      </div>

      <button type="button" className="pa-sort-button" onClick={() => setSortDirection((current) => current === 'asc' ? 'desc' : 'asc')}>
        {sortDirection === 'asc' ? 'A → Z' : 'Z → A'}
      </button>

      <ViewToggle
        value={viewMode}
        onChange={setViewMode}
        showHierarchy={activeTab === 'organizations'}
      />

      <button type="button" className="pa-icon-button" onClick={printCurrentView} title="Imprimir listagem">
        <PrintIcon />
      </button>

      {actionLabel && action && (
        <button type="button" className="pa-primary-button" onClick={action}>
          + {actionLabel}
        </button>
      )}
    </section>
  )

  return (
    <section className="platform-admin">
      <div className="pa-heading">
        <div>
          <button type="button" className="pa-back-button" onClick={onBack}>← Voltar ao Portal da Plataforma</button>
          <p className="pa-eyebrow">SUPER-ADMIN</p>
          <h1>Administração da Plataforma</h1>
          <p>Gerencie os cadastros mestres, as organizações, os usuários, os módulos e os acessos globais da Plataforma SPARKs.</p>
        </div>

        <button type="button" className="pa-secondary-button" onClick={() => void loadAll()} disabled={loading}>
          {loading ? 'Atualizando...' : 'Atualizar dados'}
        </button>
      </div>

      <div className="pa-layout">
        <nav className="pa-navigation" aria-label="Administração da Plataforma">
          {(Object.keys(TAB_LABELS) as AdminTab[]).map((tab) => (
            <button
              type="button"
              key={tab}
              className={activeTab === tab ? 'active' : ''}
              onClick={() => {
                setActiveTab(tab)
                setSearch('')
                clearMessage()
              }}
            >
              {TAB_LABELS[tab]}
            </button>
          ))}
        </nav>

        <div className="pa-content">
          {message && (
            <p className={`pa-message pa-message-${messageType}`} role={messageType === 'error' ? 'alert' : 'status'}>
              {message}
            </p>
          )}

          {loading ? (
            <div className="pa-state-card">Carregando a Administração da Plataforma...</div>
          ) : activeTab === 'dashboard' ? (
            <>
              <div className="pa-section-heading">
                <div>
                  <h2>Visão geral</h2>
                  <p>Resumo dos principais cadastros e controles globais.</p>
                </div>
              </div>

              <section className="pa-summary-grid">
                <article><span>Organizações</span><strong>{summary.organizations_total}</strong><small>{summary.organizations_active} ativas</small></article>
                <article><span>Usuários</span><strong>{summary.users_total}</strong><small>{summary.users_active} ativos</small></article>
                <article><span>Vínculos ativos</span><strong>{summary.memberships_active}</strong><small>usuário × organização</small></article>
                <article><span>Módulos</span><strong>{summary.modules_total}</strong><small>{summary.modules_active} ativos</small></article>
                <article><span>Convites pendentes</span><strong>{summary.pending_invitations}</strong><small>aguardando envio ou aceite</small></article>
              </section>

              <section className="pa-quick-grid">
                <button type="button" onClick={() => { setActiveTab('organizations'); openNewOrganization() }}><strong>Nova organização</strong><span>Cadastre uma nova organização e seu contexto institucional.</span></button>
                <button type="button" onClick={() => { setActiveTab('invitations'); setInvitationPanelOpen(true) }}><strong>Convidar usuário</strong><span>Crie uma conta com vínculo e perfil inicial de forma segura.</span></button>
                <button type="button" onClick={() => { setActiveTab('memberships'); openNewMembership() }}><strong>Novo vínculo</strong><span>Associe um usuário existente a uma organização.</span></button>
                <button type="button" onClick={() => setActiveTab('modules')}><strong>Habilitar módulos</strong><span>Defina os módulos disponíveis por organização.</span></button>
                <button type="button" onClick={() => setActiveTab('roles')}><strong>Perfis globais</strong><span>Gerencie atribuições de SUPER-ADMIN e outros perfis globais.</span></button>
                <button type="button" onClick={() => setActiveTab('portability')}><strong>Importação e exportação</strong><span>Gerencie planilhas, portais HTML e pacotes estratégicos portáveis.</span></button>
              </section>

              <aside className="pa-guidance-card">
                <strong>Separação de escopos</strong>
                <p>A Administração da Plataforma mantém cadastros globais. A Administração da Organização permanece limitada aos dados e às permissões da organização selecionada.</p>
              </aside>
            </>
          ) : activeTab === 'organizations' ? (
            <>
              <div className="pa-section-heading"><div><h2>Organizações</h2><p>Cadastre, atualize e consulte as organizações da plataforma.</p></div></div>
              {toolbar('Nova organização', openNewOrganization)}

              {viewMode === 'cards' ? (
                <section className="pa-card-grid">
                  {filteredOrganizations.map((organization) => (
                    <article className="pa-record-card pa-interactive-record" key={organization.organization_id} role="button" tabIndex={0} aria-label={`Abrir manutenção de ${organization.trade_name ?? organization.legal_name}`} onClick={() => openOrganizationEdit(organization)} onKeyDown={(event) => activateWithKeyboard(event, () => openOrganizationEdit(organization))}>
                      <div className="pa-record-card-header">
                        <div><small>{organization.organization_code}</small><h3>{organization.trade_name ?? organization.legal_name}</h3></div>
                        <span className={`pa-status pa-status-${organization.status}`}>{labelStatus(organization.status)}</span>
                      </div>
                      <dl>
                        <div><dt>Tipo</dt><dd>{labelOrganizationType(organization.organization_type)}</dd></div>
                        <div><dt>Nível</dt><dd>{organizationLevels.find((level) => level.level_code === organization.organization_level)?.level_name ?? organization.organization_level}</dd></div>
                        <div><dt>Superior</dt><dd>{organization.parent_organization_name ?? 'Sem organização superior'}</dd></div>
                        <div><dt>Usuários</dt><dd>{organization.memberships_count}</dd></div>
                        <div><dt>Módulos</dt><dd>{organization.enabled_modules_count}</dd></div>
                      </dl>
                      <div className="pa-card-actions">
                        <button type="button" title="Editar" onClick={(event) => { event.stopPropagation(); openOrganizationEdit(organization) }}><EditIcon /></button>
                        <button type="button" title="Imprimir" onClick={(event) => { event.stopPropagation(); printCurrentView() }}><PrintIcon /></button>
                      </div>
                    </article>
                  ))}
                </section>
              ) : viewMode === 'hierarchy' ? (
                <section className="pa-hierarchy-view" aria-label="Hierarquia das organizações">
                  <div className="pa-hierarchy-toolbar">
                    <div>
                      <strong>Estrutura organizacional</strong>
                      <span>
                        {normalizedSearch
                          ? `${organizationHierarchy.matchIds.size} registro(s) localizado(s), com os respectivos ancestrais.`
                          : `${organizations.length} organização(ões) distribuída(s) por dependência hierárquica.`}
                      </span>
                    </div>
                    <div className="pa-hierarchy-toolbar-actions">
                      <button type="button" className="pa-secondary-button" onClick={expandAllOrganizations}>Expandir tudo</button>
                      <button type="button" className="pa-secondary-button" onClick={collapseAllOrganizations}>Recolher tudo</button>
                    </div>
                  </div>

                  {organizationHierarchy.roots.length === 0 ? (
                    <div className="pa-empty-state">Nenhuma organização foi localizada na estrutura hierárquica.</div>
                  ) : (
                    <div className="pa-hierarchy-tree">
                      {organizationHierarchy.roots.map((organization) => renderOrganizationHierarchyNode(organization))}
                    </div>
                  )}
                </section>
              ) : (
                <div className="pa-table-card">
                  <table>
                    <thead><tr><th onClick={() => setSortDirection((current) => current === 'asc' ? 'desc' : 'asc')}>Organização</th><th>Código</th><th>Tipo</th><th>Nível</th><th>Superior</th><th>Situação</th><th>Usuários</th><th>Módulos</th><th>Ações</th></tr></thead>
                    <tbody>{filteredOrganizations.map((organization) => (
                      <tr key={organization.organization_id} className="pa-interactive-record" role="button" tabIndex={0} aria-label={`Abrir manutenção de ${organization.trade_name ?? organization.legal_name}`} onClick={() => openOrganizationEdit(organization)} onKeyDown={(event) => activateWithKeyboard(event, () => openOrganizationEdit(organization))}>
                        <td><strong>{organization.trade_name ?? organization.legal_name}</strong></td><td>{organization.organization_code}</td><td>{labelOrganizationType(organization.organization_type)}</td><td>{organizationLevels.find((level) => level.level_code === organization.organization_level)?.level_name ?? organization.organization_level}</td><td>{organization.parent_organization_name ?? '—'}</td><td>{labelStatus(organization.status)}</td><td>{organization.memberships_count}</td><td>{organization.enabled_modules_count}</td>
                        <td><button type="button" title="Editar" onClick={(event) => { event.stopPropagation(); openOrganizationEdit(organization) }}><EditIcon /></button></td>
                      </tr>
                    ))}</tbody>
                  </table>
                </div>
              )}
            </>
          ) : activeTab === 'users' ? (
            <>
              <div className="pa-section-heading"><div><h2>Usuários</h2><p>Crie e administre contas, vínculos organizacionais e perfis globais.</p></div><div className="pa-heading-actions"><button type="button" className="pa-primary-button" onClick={() => { setUserCreationForm(EMPTY_USER_CREATION_FORM); setShowCreationPassword(false); setUserCreationPanelOpen(true) }}>+ Criar usuário</button><button type="button" className="pa-secondary-button" onClick={() => setInvitationPanelOpen(true)}>Convidar por e-mail</button></div></div>
              {toolbar()}

              {viewMode === 'cards' ? (
                <section className="pa-card-grid">
                  {filteredUsers.map((user) => (
                    <article className="pa-record-card pa-interactive-record" key={user.user_id} role="button" tabIndex={0} aria-label={`Abrir manutenção de ${getUserName(user)}`} onClick={() => openUserMaintenance(user)} onKeyDown={(event) => activateWithKeyboard(event, () => openUserMaintenance(user))}>
                      <div className="pa-record-card-header"><div><small>{user.email ?? 'Sem e-mail'}</small><h3>{getUserName(user)}</h3></div><span className={`pa-status pa-status-${user.active ? 'active' : 'inactive'}`}>{user.active ? 'Ativo' : 'Inativo'}</span></div>
                      <dl><div><dt>Perfis globais</dt><dd>{user.platform_roles || 'Nenhum'}</dd></div><div><dt>Organizações</dt><dd>{user.memberships_count}</dd></div><div><dt>Administrações locais</dt><dd>{user.admin_memberships_count}</dd></div></dl>
                    </article>
                  ))}
                </section>
              ) : (
                <div className="pa-table-card"><table><thead><tr><th onClick={() => setSortDirection((current) => current === 'asc' ? 'desc' : 'asc')}>Usuário</th><th>E-mail</th><th>Situação</th><th>Perfis globais</th><th>Organizações</th><th>Admin local</th></tr></thead><tbody>{filteredUsers.map((user) => <tr key={user.user_id} className="pa-interactive-record" role="button" tabIndex={0} aria-label={`Abrir manutenção de ${getUserName(user)}`} onClick={() => openUserMaintenance(user)} onKeyDown={(event) => activateWithKeyboard(event, () => openUserMaintenance(user))}><td><strong>{getUserName(user)}</strong></td><td>{user.email ?? '—'}</td><td>{user.active ? 'Ativo' : 'Inativo'}</td><td>{user.platform_roles || '—'}</td><td>{user.memberships_count}</td><td>{user.admin_memberships_count}</td></tr>)}</tbody></table></div>
              )}
            </>
          ) : activeTab === 'memberships' ? (
            <>
              <div className="pa-section-heading"><div><h2>Vínculos e acessos</h2><p>Associe usuários às organizações e defina administradores locais.</p></div></div>
              {toolbar('Novo vínculo', openNewMembership)}
              {viewMode === 'cards' ? (
                <section className="pa-card-grid">
                  {filteredMemberships.map((membership) => (
                    <article className="pa-record-card pa-interactive-record" key={membership.membership_id} role="button" tabIndex={0} aria-label={`Abrir vínculo de ${membership.user_name}`} onClick={() => openMembershipEdit(membership)} onKeyDown={(event) => activateWithKeyboard(event, () => openMembershipEdit(membership))}>
                      <div className="pa-record-card-header"><div><small>{membership.organization_code}</small><h3>{membership.user_name}</h3><p>{membership.organization_name}</p></div><span className={`pa-status pa-status-${membership.membership_status}`}>{labelStatus(membership.membership_status)}</span></div>
                      <dl><div><dt>Cargo/função</dt><dd>{membership.job_title ?? 'Não informado'}</dd></div><div><dt>Administrador local</dt><dd>{membership.is_organization_admin ? 'Sim' : 'Não'}</dd></div><div><dt>Vigência</dt><dd>{formatDate(membership.valid_from)} a {formatDate(membership.valid_until)}</dd></div></dl>
                      <div className="pa-card-actions"><button type="button" title="Editar" onClick={(event) => { event.stopPropagation(); openMembershipEdit(membership) }}><EditIcon /></button></div>
                    </article>
                  ))}
                </section>
              ) : (
                <div className="pa-table-card"><table><thead><tr><th onClick={() => setSortDirection((current) => current === 'asc' ? 'desc' : 'asc')}>Organização</th><th>Usuário</th><th>Cargo/função</th><th>Situação</th><th>Admin local</th><th>Vigência</th><th>Ações</th></tr></thead><tbody>{filteredMemberships.map((membership) => <tr key={membership.membership_id} className="pa-interactive-record" role="button" tabIndex={0} aria-label={`Abrir vínculo de ${membership.user_name}`} onClick={() => openMembershipEdit(membership)} onKeyDown={(event) => activateWithKeyboard(event, () => openMembershipEdit(membership))}><td><strong>{membership.organization_name}</strong></td><td>{membership.user_name}</td><td>{membership.job_title ?? '—'}</td><td>{labelStatus(membership.membership_status)}</td><td>{membership.is_organization_admin ? 'Sim' : 'Não'}</td><td>{formatDate(membership.valid_until)}</td><td><button type="button" title="Editar" onClick={(event) => { event.stopPropagation(); openMembershipEdit(membership) }}><EditIcon /></button></td></tr>)}</tbody></table></div>
              )}
            </>
          ) : activeTab === 'modules' ? (
            <>
              <div className="pa-section-heading"><div><h2>Módulos</h2><p>Consulte o catálogo e habilite módulos por organização.</p></div></div>
              <div className="pa-selector-card"><label>Organização<select value={selectedOrganizationForModules} onChange={(event) => setSelectedOrganizationForModules(event.target.value)}><option value="">Selecione uma organização</option>{organizations.map((organization) => <option key={organization.organization_id} value={organization.organization_id}>{organization.trade_name ?? organization.legal_name}</option>)}</select></label></div>
              {selectedOrganizationForModules ? (
                <section className="pa-card-grid pa-module-grid">{organizationModules.map((module) => <article className="pa-record-card" key={module.module_id}><div className="pa-record-card-header"><div><small>{module.module_code}</small><h3>{module.module_name}</h3></div><span className={`pa-status pa-status-${module.enabled ? 'active' : 'inactive'}`}>{module.enabled ? 'Habilitado' : 'Desabilitado'}</span></div><p>{labelStatus(module.module_status)}</p><button type="button" className={module.enabled ? 'pa-danger-button' : 'pa-primary-button'} onClick={() => void toggleOrganizationModule(module)}>{module.enabled ? 'Desabilitar' : 'Habilitar'}</button></article>)}</section>
              ) : (
                <>{toolbar()}<section className="pa-card-grid">{filteredModules.map((module) => <article className="pa-record-card" key={module.module_id}><div className="pa-record-card-header"><div><small>{module.module_code}</small><h3>{module.module_name}</h3></div><span className={`pa-status pa-status-${module.status}`}>{labelStatus(module.status)}</span></div><p>{module.description ?? 'Módulo da Plataforma SPARKs.'}</p><dl><div><dt>Organizações habilitadas</dt><dd>{module.enabled_organizations_count}</dd></div><div><dt>Núcleo da plataforma</dt><dd>{module.is_core ? 'Sim' : 'Não'}</dd></div></dl></article>)}</section></>
              )}
            </>
          ) : activeTab === 'roles' ? (
            <>
              <div className="pa-section-heading"><div><h2>Perfis globais</h2><p>Atribua ou revogue papéis globais dos usuários da plataforma.</p></div></div>
              <div className="pa-selector-card"><label>Usuário<select value={selectedUserForRoles} onChange={(event) => setSelectedUserForRoles(event.target.value)}><option value="">Selecione um usuário</option>{users.map((user) => <option key={user.user_id} value={user.user_id}>{getUserName(user)} — {user.email ?? 'sem e-mail'}</option>)}</select></label></div>
              {selectedUserForRoles ? (
                <section className="pa-card-grid pa-module-grid">{userRoles.map((role) => <article className="pa-record-card" key={role.platform_role_id}><div className="pa-record-card-header"><div><small>{role.role_code}</small><h3>{role.role_name}</h3></div><span className={`pa-status pa-status-${role.assigned ? 'active' : 'inactive'}`}>{role.assigned ? 'Atribuído' : 'Não atribuído'}</span></div><p>Nível global {role.role_level}</p><button type="button" className={role.assigned ? 'pa-danger-button' : 'pa-primary-button'} onClick={() => void toggleUserRole(role)}>{role.assigned ? 'Revogar perfil' : 'Atribuir perfil'}</button></article>)}</section>
              ) : (
                <>{toolbar()}<section className="pa-card-grid">{filteredRoles.map((role) => <article className="pa-record-card" key={role.platform_role_id}><div className="pa-record-card-header"><div><small>{role.role_code}</small><h3>{role.role_name}</h3></div><span className={`pa-status pa-status-${role.active ? 'active' : 'inactive'}`}>{role.active ? 'Ativo' : 'Inativo'}</span></div><p>{role.description ?? 'Perfil global da plataforma.'}</p><dl><div><dt>Nível</dt><dd>{role.role_level}</dd></div><div><dt>Usuários</dt><dd>{role.users_count}</dd></div></dl></article>)}</section></>
              )}
            </>
          ) : activeTab === 'invitations' ? (
            <>
              <div className="pa-section-heading"><div><h2>Convites</h2><p>Crie novos usuários por meio de convite seguro e auditável.</p></div></div>
              {toolbar('Convidar usuário', () => setInvitationPanelOpen(true))}
              {viewMode === 'cards' ? (
                <section className="pa-card-grid">{filteredInvitations.map((invitation) => <article className="pa-record-card" key={invitation.invitation_id}><div className="pa-record-card-header"><div><small>{invitation.email}</small><h3>{invitation.full_name ?? invitation.email}</h3></div><span className={`pa-status pa-status-${invitation.status}`}>{labelStatus(invitation.status)}</span></div><dl><div><dt>Organização</dt><dd>{invitation.organization_name ?? 'Sem vínculo inicial'}</dd></div><div><dt>Perfil global</dt><dd>{invitation.platform_role_name ?? 'Nenhum'}</dd></div><div><dt>Solicitado em</dt><dd>{formatDate(invitation.requested_at)}</dd></div></dl>{invitation.failure_reason && <p className="pa-inline-error">{invitation.failure_reason}</p>}</article>)}</section>
              ) : (
                <div className="pa-table-card"><table><thead><tr><th>Nome</th><th>E-mail</th><th>Organização</th><th>Perfil global</th><th>Situação</th><th>Data</th></tr></thead><tbody>{filteredInvitations.map((invitation) => <tr key={invitation.invitation_id}><td><strong>{invitation.full_name ?? '—'}</strong></td><td>{invitation.email}</td><td>{invitation.organization_name ?? '—'}</td><td>{invitation.platform_role_name ?? '—'}</td><td>{labelStatus(invitation.status)}</td><td>{formatDate(invitation.requested_at)}</td></tr>)}</tbody></table></div>
              )}
            </>
          ) : (
            <PortabilityAdmin organizations={organizations.map((organization) => ({
              id: organization.organization_id,
              code: organization.organization_code,
              name: organization.trade_name ?? organization.legal_name,
            }))} />
          )}
        </div>
      </div>

      {organizationPanelOpen && (
        <div className="pa-modal-backdrop" role="presentation" onMouseDown={requestCloseOrganizationPanel}>
          <aside className="pa-side-panel pa-side-panel-wide" role="dialog" aria-modal="true" aria-label="Cadastro da organização" onMouseDown={(event) => event.stopPropagation()}>
            <div className="pa-panel-header"><div><p className="pa-eyebrow">Cadastro mestre</p><h2>{organizationForm.organizationId ? 'Visualização e manutenção da organização' : 'Nova organização'}</h2></div><button type="button" onClick={requestCloseOrganizationPanel} title="Fechar cadastro" aria-label="Fechar cadastro"><CloseIcon /></button></div>
            <nav className="pa-detail-tabs" aria-label="Dados relacionados à organização">
              <button type="button" className={organizationDetailTab === 'data' ? 'active' : ''} onClick={() => changeOrganizationDetailTab('data')}>Dados gerais</button>
              <button type="button" className={organizationDetailTab === 'users' ? 'active' : ''} onClick={() => changeOrganizationDetailTab('users')} disabled={!organizationForm.organizationId}>Usuários e acessos <span>{organizationMemberships.length}</span></button>
              <button type="button" className={organizationDetailTab === 'modules' ? 'active' : ''} onClick={() => changeOrganizationDetailTab('modules')} disabled={!organizationForm.organizationId}>Módulos <span>{organizationModules.filter((module) => module.enabled).length}</span></button>
              <button type="button" className={organizationDetailTab === 'hierarchy' ? 'active' : ''} onClick={() => changeOrganizationDetailTab('hierarchy')} disabled={!organizationForm.organizationId}>Hierarquia <span>{organizationChildren.length}</span></button>
            </nav>

            {organizationDetailTab === 'data' ? (
              <form
                id="organization-form-top"
                className="pa-form pa-onboarding-form"
                onSubmit={saveOrganization}
                onChange={() => {
                  setOrganizationDirty(true)
                  setOrganizationErrorField(null)
                }}
              >
                {/* FEEDBACK E PROTECAO DE DADOS NAO SALVOS - V4 */}
                <div
                  className={`pa-sticky-form-actions ${message ? `pa-sticky-form-actions-${messageType}` : organizationDirty ? 'pa-sticky-form-actions-dirty' : ''}`}
                  aria-live="polite"
                >
                  <div className="pa-sticky-form-message">
                    {message ? (
                      <>
                        {messageType === 'error' && <WarningIcon />}
                        <div>
                          <strong>{messageType === 'error' ? 'Atenção: alterações não gravadas' : messageType === 'success' ? 'Operação concluída' : 'Informação'}</strong>
                          <span>{message}</span>
                        </div>
                      </>
                    ) : organizationDirty ? (
                      <>
                        <WarningIcon />
                        <div>
                          <strong>Existem alterações não salvas</strong>
                          <span>Salve antes de fechar, trocar de área ou atualizar a página.</span>
                        </div>
                      </>
                    ) : (
                      <div>
                        <strong>Cadastro institucional</strong>
                        <span>Os dados permanecem preservados até que uma ação seja executada.</span>
                      </div>
                    )}
                  </div>

                  <div className="pa-sticky-form-buttons">
                    <button
                      type="button"
                      className="pa-secondary-button pa-button-with-icon"
                      onClick={requestCloseOrganizationPanel}
                      title="Fechar cadastro"
                    >
                      <CloseIcon />
                      <span>Fechar</span>
                    </button>
                    <button
                      type="submit"
                      className="pa-primary-button pa-button-with-icon"
                      disabled={saving}
                      title={organizationForm.organizationId ? 'Salvar alterações' : 'Criar organização'}
                    >
                      <SaveIcon />
                      <span>{saving ? 'Salvando...' : organizationForm.organizationId ? 'Salvar alterações' : 'Criar organização'}</span>
                    </button>
                  </div>
                </div>
                <section className="pa-organization-branding-editor">
                  <div className="pa-organization-logo-preview">
                    {organizationLogoPreview ? <img src={organizationLogoPreview} alt={`Logo de ${organizationForm.tradeName || organizationForm.legalName || 'organização'}`} /> : <span>{(organizationForm.tradeName || organizationForm.legalName || organizationForm.code || 'OR').slice(0, 2).toUpperCase()}</span>}
                  </div>
                  <div>
                    <strong>Identidade visual da organização</strong>
                    <p>A logo será reutilizada no Portal, no Planejamento Estratégico, nos relatórios, documentos e exportações.</p>
                    <label className="pa-logo-upload-button">
                      <span>Selecionar logo</span>
                      <input type="file" accept="image/png,image/jpeg,image/webp,image/svg+xml" onChange={(event) => {
                        const file = event.target.files?.[0] ?? null
                        if (file && file.size > 5 * 1024 * 1024) {
                          showMessage('A logo deve possuir no máximo 5 MB.', 'error')
                          event.target.value = ''
                          return
                        }
                        setOrganizationLogoFile(file)
                        if (file) setOrganizationLogoPreview(URL.createObjectURL(file))
                      }} />
                    </label>
                    <small>PNG, JPG, WEBP ou SVG, com até 5 MB.</small>
                  </div>
                </section>

                <section className="pa-onboarding-section">
                  <header>
                    <span>1</span>
                    <div>
                      <h3>Identificação e enquadramento</h3>
                      <p>Dados mestres utilizados em toda a Plataforma SPARKs.</p>
                    </div>
                  </header>

                  <div className="pa-form-grid">
                    <label>Código<input value={organizationForm.code} onChange={(event) => setOrganizationForm((current) => ({ ...current, code: event.target.value.toUpperCase() }))} required /></label>
                    <label>Situação<select value={organizationForm.status} onChange={(event) => setOrganizationForm((current) => ({ ...current, status: event.target.value }))}><option value="draft">Rascunho</option><option value="active">Ativo</option><option value="suspended">Suspenso</option><option value="inactive">Inativo</option><option value="archived">Arquivado</option></select></label>
                  </div>
                  <label>Razão social<input value={organizationForm.legalName} onChange={(event) => setOrganizationForm((current) => ({ ...current, legalName: event.target.value }))} required /></label>
                  <label>Nome fantasia<input value={organizationForm.tradeName} onChange={(event) => setOrganizationForm((current) => ({ ...current, tradeName: event.target.value }))} /></label>
                  <div className="pa-form-grid">
                    <label>Tipo<select value={organizationForm.organizationType} onChange={(event) => changeOrganizationType(event.target.value)}>{Object.entries(ORGANIZATION_TYPE_LABELS).map(([code, name]) => <option key={code} value={code}>{name}</option>)}</select></label>
                    <label>Nível<select value={organizationForm.organizationLevel} onChange={(event) => setOrganizationForm((current) => ({ ...current, organizationLevel: event.target.value }))}>{availableOrganizationLevels.map((level) => <option key={level.level_code} value={level.level_code}>{level.level_name}</option>)}</select><small className="pa-field-hint">{organizationForm.organizationType === 'system' ? 'Para organizações do tipo Sistema: Nacional, Regional ou Estadual.' : 'As opções são ajustadas conforme o tipo de organização.'}</small></label>
                  </div>
                  <label>Organização superior<select value={organizationForm.parentOrganizationId} onChange={(event) => setOrganizationForm((current) => ({ ...current, parentOrganizationId: event.target.value }))}><option value="">Sem organização superior</option>{organizations.filter((organization) => organization.organization_id !== organizationForm.organizationId).map((organization) => <option key={organization.organization_id} value={organization.organization_id}>{organization.trade_name ?? organization.legal_name}</option>)}</select></label>
                  <div className="pa-form-grid">
                    <label id="organization-field-cnpj" className={organizationErrorField === 'organization-field-cnpj' ? 'pa-field-invalid' : ''}>CNPJ<input value={organizationForm.cnpj} onChange={(event) => setOrganizationForm((current) => ({ ...current, cnpj: formatCnpjInput(event.target.value) }))} inputMode="numeric" /></label>
                    {organizationForm.organizationType === 'cooperative' ? (
                      <label id="organization-field-branch" className={organizationErrorField === 'organization-field-branch' ? 'pa-field-invalid' : ''}>Ramo cooperativista<select value={organizationForm.cooperativeBranchCode} onChange={(event) => setOrganizationForm((current) => ({ ...current, cooperativeBranchCode: event.target.value }))}><option value="">Selecione o ramo</option>{cooperativeBranches.map((branch) => <option key={branch.branch_id} value={branch.branch_code}>{branch.branch_name}</option>)}</select><small className="pa-field-hint">Catálogo mestre oficial, incluindo o Ramo Seguros.</small></label>
                    ) : (
                      <div className="pa-not-applicable-field"><strong>Ramo cooperativista</strong><span>Não aplicável ao tipo de organização selecionado.</span></div>
                    )}
                  </div>
                  <label>Descrição institucional<textarea rows={4} value={organizationForm.description} onChange={(event) => setOrganizationForm((current) => ({ ...current, description: event.target.value }))} placeholder="Apresente a finalidade, atuação e contexto institucional da organização." /></label>
                </section>

                <section className="pa-onboarding-section">
                  <header>
                    <span>2</span>
                    <div>
                      <h3>Endereço institucional</h3>
                      <p>O CEP pode preencher automaticamente os dados, que permanecem editáveis.</p>
                    </div>
                  </header>

                  <div className="pa-cep-row">
                    <label id="organization-field-postal-code" className={organizationErrorField === 'organization-field-postal-code' ? 'pa-field-invalid' : ''}>CEP<input value={organizationForm.postalCode} onChange={(event) => setOrganizationForm((current) => ({ ...current, postalCode: formatPostalCodeInput(event.target.value) }))} onBlur={() => { if (onlyDigits(organizationForm.postalCode).length === 8) void lookupPostalCode() }} inputMode="numeric" /></label>
                    <button type="button" className="pa-secondary-button" onClick={() => void lookupPostalCode()} disabled={lookingUpCep}>{lookingUpCep ? 'Consultando...' : 'Consultar CEP'}</button>
                  </div>
                  {cepLookupMessage && <div className={`pa-lookup-message pa-lookup-message-${cepLookupMessage.type}`} role="status">{cepLookupMessage.text}</div>}
                  <label id="organization-field-street" className={organizationErrorField === 'organization-field-street' ? 'pa-field-invalid' : ''}>Logradouro<input value={organizationForm.street} onChange={(event) => setOrganizationForm((current) => ({ ...current, street: event.target.value }))} /></label>
                  <div className="pa-form-grid">
                    <label id="organization-field-number" className={organizationErrorField === 'organization-field-number' ? 'pa-field-invalid' : ''}>Número<input value={organizationForm.addressNumber} onChange={(event) => setOrganizationForm((current) => ({ ...current, addressNumber: event.target.value }))} /></label>
                    <label>Complemento<input value={organizationForm.addressComplement} onChange={(event) => setOrganizationForm((current) => ({ ...current, addressComplement: event.target.value }))} /></label>
                  </div>
                  <label id="organization-field-district" className={organizationErrorField === 'organization-field-district' ? 'pa-field-invalid' : ''}>Bairro<input value={organizationForm.district} onChange={(event) => setOrganizationForm((current) => ({ ...current, district: event.target.value }))} /></label>
                  <div className="pa-form-grid pa-form-grid-three">
                    <label id="organization-field-city" className={organizationErrorField === 'organization-field-city' ? 'pa-field-invalid' : ''}>Município<input value={organizationForm.city} onChange={(event) => setOrganizationForm((current) => ({ ...current, city: event.target.value }))} /></label>
                    <label id="organization-field-state" className={organizationErrorField === 'organization-field-state' ? 'pa-field-invalid' : ''}>UF<input maxLength={2} value={organizationForm.stateCode} onChange={(event) => setOrganizationForm((current) => ({ ...current, stateCode: event.target.value.toUpperCase() }))} /></label>
                    <label>País<input maxLength={2} value={organizationForm.countryCode} onChange={(event) => setOrganizationForm((current) => ({ ...current, countryCode: event.target.value.toUpperCase() }))} /></label>
                  </div>
                </section>

                <section
                  id="organization-field-cnaes"
                  className={`pa-onboarding-section ${organizationErrorField === 'organization-field-cnaes' ? 'pa-field-invalid' : ''}`}
                >
                  <header>
                    <span>3</span>
                    <div>
                      <h3>Atividades econômicas</h3>
                      <p>Selecione CNAEs do catálogo oficial vigente e defina exatamente um como principal.</p>
                    </div>
                  </header>

                  <label>Pesquisar CNAE<input value={cnaeSearch} onChange={(event) => setCnaeSearch(event.target.value)} placeholder="Digite o código ou parte da descrição" /></label>
                  {searchingCnaes && <p className="pa-field-help">Pesquisando no catálogo oficial...</p>}
                  {cnaeSearchError && <p className="pa-inline-error">{cnaeSearchError}</p>}
                  {cnaeResults.length > 0 && (
                    <div className="pa-cnae-results">
                      {cnaeResults.map((candidate) => (
                        <button type="button" key={candidate.cnae_catalog_id} onClick={() => addCnae(candidate)}>
                          <strong>{candidate.formatted_code}</strong>
                          <span>{candidate.description}</span>
                          <small>{candidate.section_name ?? 'CNAE oficial'}</small>
                        </button>
                      ))}
                    </div>
                  )}

                  <div className="pa-cnae-selected">
                    {selectedCnaes.length === 0 ? (
                      <div className="pa-empty-state">Nenhum CNAE selecionado. O primeiro CNAE incluído será definido como principal.</div>
                    ) : selectedCnaes.map((item) => (
                      <article key={item.cnaeCatalogId} className={item.isPrimary ? 'is-primary' : ''}>
                        <div>
                          <span>{item.isPrimary ? 'Principal' : 'Secundário'}</span>
                          <strong>{item.formattedCode}</strong>
                          <p>{item.description}</p>
                        </div>
                        <div className="pa-cnae-actions">
                          {!item.isPrimary && <button type="button" onClick={() => makePrimaryCnae(item.cnaeCatalogId)}>Tornar principal</button>}
                          <button type="button" className="pa-danger-button" onClick={() => removeCnae(item.cnaeCatalogId)}>Remover</button>
                        </div>
                      </article>
                    ))}
                  </div>

                  <div className="pa-form-grid">
                    <label>Origem da confirmação<select value={organizationForm.cnaeSourceType} onChange={(event) => setOrganizationForm((current) => ({ ...current, cnaeSourceType: event.target.value }))}><option value="manual_confirmed">Confirmação manual</option><option value="official_cnpj">Comprovante oficial do CNPJ</option><option value="official_ibge">Fonte oficial IBGE/CONCLA</option><option value="official_document">Documento oficial da organização</option></select></label>
                    <label>Referência da fonte<input value={organizationForm.cnaeSourceReference} onChange={(event) => setOrganizationForm((current) => ({ ...current, cnaeSourceReference: event.target.value }))} placeholder="Número, endereço eletrônico ou documento consultado" /></label>
                  </div>
                </section>

                <section className="pa-onboarding-section">
                  <header>
                    <span>4</span>
                    <div>
                      <h3>Contatos institucionais</h3>
                      <p>Informações compartilhadas pelos módulos da plataforma.</p>
                    </div>
                  </header>
                  <label id="organization-field-email" className={organizationErrorField === 'organization-field-email' ? 'pa-field-invalid' : ''}>E-mail institucional<input type="email" value={organizationForm.institutionalEmail} onChange={(event) => setOrganizationForm((current) => ({ ...current, institutionalEmail: event.target.value }))} /></label>
                  <div className="pa-form-grid">
                    <label>Telefone<input value={organizationForm.phone} onChange={(event) => setOrganizationForm((current) => ({ ...current, phone: event.target.value }))} /></label>
                    <label>Site<input type="url" value={organizationForm.website} onChange={(event) => setOrganizationForm((current) => ({ ...current, website: event.target.value }))} placeholder="https://" /></label>
                  </div>
                </section>

                <section className="pa-onboarding-section pa-onboarding-control">
                  <header>
                    <span>5</span>
                    <div>
                      <h3>Controle e prontidão</h3>
                      <p>Rascunhos podem ser incompletos. A ativação exige cadastro institucional, endereço, ramo aplicável e CNAE principal.</p>
                    </div>
                  </header>
                  <div className={`pa-readiness-notice ${organizationForm.status === 'active' ? 'is-active' : 'is-draft'}`}>
                    <strong>{organizationForm.status === 'active' ? 'Validação para ativação habilitada' : 'Cadastro em preparação'}</strong>
                    <span>{organizationForm.status === 'active' ? 'O banco verificará todos os requisitos obrigatórios antes de concluir.' : 'Você pode salvar o registro incompleto e concluir os dados posteriormente.'}</span>
                  </div>
                  <label id="organization-field-change-reason" className={organizationErrorField === 'organization-field-change-reason' ? 'pa-field-invalid' : ''}>Justificativa para auditoria *<textarea rows={3} value={organizationForm.changeReason} onChange={(event) => setOrganizationForm((current) => ({ ...current, changeReason: event.target.value }))} placeholder="Informe o motivo da criação ou alteração, com pelo menos 10 caracteres." required /></label>
                </section>

                <div className="pa-form-actions">
                  <button type="button" className="pa-secondary-button pa-button-with-icon" onClick={requestCloseOrganizationPanel}>
                    <CloseIcon />
                    <span>Fechar</span>
                  </button>
                  <button type="submit" className="pa-primary-button pa-button-with-icon" disabled={saving}>
                    <SaveIcon />
                    <span>{saving ? 'Salvando e conferindo...' : organizationForm.organizationId ? 'Salvar alterações' : 'Criar organização'}</span>
                  </button>
                </div>
              </form>
            ) : organizationDetailTab === 'users' ? (
              <section className="pa-related-section">
                <div className="pa-related-heading"><div><h3>Usuários e acessos da organização</h3><p>Vínculos, papéis funcionais e condição de administrador local.</p></div><button type="button" className="pa-primary-button" onClick={() => openNewMembershipForOrganization(organizationForm.organizationId as string)}>+ Vincular usuário</button></div>
                {organizationMemberships.length === 0 ? <div className="pa-empty-state">Nenhum usuário vinculado a esta organização.</div> : <div className="pa-related-grid">{organizationMemberships.map((membership) => <article key={membership.membership_id} className="pa-related-card pa-interactive-record" role="button" tabIndex={0} onClick={() => openMembershipEdit(membership)} onKeyDown={(event) => activateWithKeyboard(event, () => openMembershipEdit(membership))}><div><small>{membership.user_email ?? 'Sem e-mail'}</small><h4>{membership.user_name}</h4><p>{membership.job_title ?? 'Função não informada'}</p></div><dl><div><dt>Situação</dt><dd>{labelStatus(membership.membership_status)}</dd></div><div><dt>Admin local</dt><dd>{membership.is_organization_admin ? 'Sim' : 'Não'}</dd></div></dl></article>)}</div>}
              </section>
            ) : organizationDetailTab === 'modules' ? (
              <section className="pa-related-section">
                <div className="pa-related-heading"><div><h3>Módulos habilitados</h3><p>Controle os módulos disponíveis para a organização.</p></div></div>
                <div className="pa-related-grid">{organizationModules.map((module) => <article key={module.module_id} className="pa-related-card"><div><small>{module.module_code}</small><h4>{module.module_name}</h4><p>{module.enabled ? 'Módulo habilitado para a organização.' : 'Módulo ainda não habilitado.'}</p></div><button type="button" className={module.enabled ? 'pa-danger-button' : 'pa-primary-button'} onClick={() => void toggleOrganizationModule(module)}>{module.enabled ? 'Desabilitar' : 'Habilitar'}</button></article>)}</div>
              </section>
            ) : (
              <section className="pa-related-section">
                <div className="pa-related-heading"><div><h3>Posição na estrutura organizacional</h3><p>Organização superior e organizações diretamente subordinadas.</p></div></div>
                <div className="pa-hierarchy-summary"><article><span>Organização superior</span>{selectedOrganizationParent ? <button type="button" onClick={() => void openOrganizationEdit(selectedOrganizationParent)}>{selectedOrganizationParent.trade_name ?? selectedOrganizationParent.legal_name}</button> : <strong>Sem organização superior</strong>}</article><article><span>Subordinadas diretas</span><strong>{organizationChildren.length}</strong></article></div>
                {organizationChildren.length === 0 ? <div className="pa-empty-state">Nenhuma organização subordinada diretamente.</div> : <div className="pa-related-grid">{organizationChildren.map((organization) => <article key={organization.organization_id} className="pa-related-card pa-interactive-record" role="button" tabIndex={0} onClick={() => void openOrganizationEdit(organization)} onKeyDown={(event) => activateWithKeyboard(event, () => void openOrganizationEdit(organization))}><div><small>{organization.organization_code}</small><h4>{organization.trade_name ?? organization.legal_name}</h4><p>{labelOrganizationType(organization.organization_type)} · {labelStatus(organization.status)}</p></div></article>)}</div>}
              </section>
            )}
          </aside>
        </div>
      )}

      {userPanelOpen && (
        <div className="pa-modal-backdrop" role="presentation" onMouseDown={() => setUserPanelOpen(false)}>
          <aside className="pa-side-panel pa-side-panel-wide" role="dialog" aria-modal="true" aria-label="Visualização e manutenção do usuário" onMouseDown={(event) => event.stopPropagation()}>
            <div className="pa-panel-header"><div><p className="pa-eyebrow">Cadastro e relações</p><h2>Visualização e manutenção do usuário</h2></div><button type="button" onClick={() => setUserPanelOpen(false)} title="Fechar"><CloseIcon /></button></div>

            <section className="pa-user-context-sticky" aria-label="Usuário em manutenção">
              <div className="pa-user-context-avatar" aria-hidden="true">{(selectedUser ? getUserName(selectedUser) : userForm.displayName || userForm.fullName || 'U').slice(0, 1).toLocaleUpperCase('pt-BR')}</div>
              <div className="pa-user-context-copy">
                <span>Usuário em manutenção</span>
                <strong>{selectedUser ? getUserName(selectedUser) : userForm.displayName || userForm.fullName || 'Usuário'}</strong>
                <small>{selectedUser?.email ?? 'E-mail não informado'}</small>
              </div>
              <div className="pa-user-context-badges">
                <span className={`pa-status pa-status-${userForm.active ? 'active' : 'inactive'}`}>{userForm.active ? 'Ativo' : 'Inativo'}</span>
                <span>{userMemberships.length} organização(ões)</span>
                <span>{userRoles.filter((role) => role.assigned).length} perfil(is) global(is)</span>
                <span>{assignedModuleRolesCount} perfil(is) modular(es)</span>
              </div>
            </section>

            <nav className="pa-detail-tabs" aria-label="Dados relacionados ao usuário">
              <button type="button" className={userDetailTab === 'profile' ? 'active' : ''} onClick={() => setUserDetailTab('profile')}>Dados do usuário</button>
              <button type="button" className={userDetailTab === 'organizations' ? 'active' : ''} onClick={() => setUserDetailTab('organizations')}>Organizações e acessos <span>{userMemberships.length}</span></button>
              <button type="button" className={userDetailTab === 'roles' ? 'active' : ''} onClick={() => setUserDetailTab('roles')}>Perfis globais <span>{userRoles.filter((role) => role.assigned).length}</span></button>
              <button type="button" className={userDetailTab === 'moduleRoles' ? 'active' : ''} onClick={() => setUserDetailTab('moduleRoles')}>Perfis por módulo <span>{assignedModuleRolesCount}</span></button>
              <button type="button" className={userDetailTab === 'audit' ? 'active' : ''} onClick={() => setUserDetailTab('audit')}>Auditoria <span>{userAudit.length}</span></button>
            </nav>

            {userDetailTab === 'profile' ? (
              <form className="pa-form" onSubmit={saveUserProfile}>
                <label>Nome completo<input value={userForm.fullName} onChange={(event) => setUserForm((current) => ({ ...current, fullName: event.target.value }))} /></label>
                <label>Nome de exibição<input value={userForm.displayName} onChange={(event) => setUserForm((current) => ({ ...current, displayName: event.target.value }))} /></label>
                <label>Telefone<input value={userForm.phone} onChange={(event) => setUserForm((current) => ({ ...current, phone: event.target.value }))} /></label>
                <label className="pa-checkbox"><input type="checkbox" checked={userForm.active} onChange={(event) => setUserForm((current) => ({ ...current, active: event.target.checked }))} />Usuário ativo na plataforma</label>
                <div className="pa-form-actions"><button type="button" className="pa-secondary-button" onClick={() => setUserPanelOpen(false)}>Fechar</button><button type="submit" className="pa-primary-button" disabled={saving}>{saving ? 'Salvando...' : 'Salvar usuário'}</button></div>
              </form>
            ) : userDetailTab === 'organizations' ? (
              <section className="pa-related-section">
                <div className="pa-related-heading"><div><h3>Organizações e acessos</h3><p>Todos os vínculos do usuário e seus papéis funcionais.</p></div><button type="button" className="pa-primary-button" onClick={() => openNewMembershipForUser(userForm.userId)}>+ Vincular organização</button></div>
                {userMemberships.length === 0 ? <div className="pa-empty-state">Este usuário ainda não possui vínculo organizacional.</div> : <div className="pa-related-grid">{userMemberships.map((membership) => <article key={membership.membership_id} className="pa-related-card pa-interactive-record" role="button" tabIndex={0} onClick={() => openMembershipEdit(membership)} onKeyDown={(event) => activateWithKeyboard(event, () => openMembershipEdit(membership))}><div><small>{membership.organization_code}</small><h4>{membership.organization_name}</h4><p>{membership.job_title ?? 'Função não informada'}</p></div><dl><div><dt>Situação</dt><dd>{labelStatus(membership.membership_status)}</dd></div><div><dt>Admin local</dt><dd>{membership.is_organization_admin ? 'Sim' : 'Não'}</dd></div></dl></article>)}</div>}
              </section>
            ) : userDetailTab === 'roles' ? (
              <section className="pa-related-section">
                <div className="pa-related-heading"><div><h3>Perfis globais</h3><p>A lista é carregada integralmente do banco. Atribua ou revogue perfis com efeito em toda a plataforma.</p></div></div>
                <div className="pa-related-grid">{userRoles.map((role) => <article key={role.platform_role_id} className="pa-related-card"><div><small>{role.role_code}</small><h4>{role.role_name}</h4><p>Nível global {role.role_level}</p></div><button type="button" className={role.assigned ? 'pa-danger-button' : 'pa-primary-button'} onClick={() => void toggleUserRole(role)}>{role.assigned ? 'Revogar perfil' : 'Atribuir perfil'}</button></article>)}</div>
              </section>
            ) : userDetailTab === 'moduleRoles' ? (
              <section className="pa-related-section">
                <div className="pa-related-heading"><div><h3>Perfis por módulo</h3><p>Perfis disponíveis nos módulos habilitados das organizações às quais o usuário está vinculado.</p></div></div>
                {selectedUserIsVisitor ? (
                  <div className="pa-visitor-notice"><strong>VISITANTE — acesso dinâmico somente leitura</strong><span>O VISITANTE não recebe papéis modulares adicionais. Ele consulta os módulos habilitados nas organizações autorizadas, sem permissão de alteração.</span></div>
                ) : loadingUserRelations ? (
                  <div className="pa-empty-state">Carregando perfis por módulo...</div>
                ) : userModuleRoleGroups.length === 0 ? (
                  <div className="pa-empty-state">Não há módulos habilitados nas organizações vinculadas ou o usuário ainda não possui vínculo ativo.</div>
                ) : (
                  <div className="pa-module-access-grid">
                    {userModuleRoleGroups.map((group) => (
                      <article className="pa-module-access-card" key={group.organizationModuleId}>
                        <div className="pa-module-access-heading">
                          <div><small>{group.organizationCode} · {group.moduleCode}</small><h4>{group.moduleName}</h4><p>{group.organizationName}</p></div>
                          <span className={`pa-status pa-status-${group.assignedRoleId ? 'active' : 'inactive'}`}>{group.assignedRoleId ? 'Perfil atribuído' : 'Sem perfil'}</span>
                        </div>
                        <label>Perfil no módulo
                          <select value={group.assignedRoleId} onChange={(event) => void changeUserModuleRole(group.organizationModuleId, group.moduleName, event.target.value)} disabled={group.membershipStatus !== 'active'}>
                            <option value="">Sem perfil neste módulo</option>
                            {group.roles.map((role) => <option key={role.module_role_id} value={role.module_role_id}>{role.role_name}</option>)}
                          </select>
                        </label>
                        {group.membershipStatus !== 'active' && <small className="pa-inline-warning">O vínculo com a organização está {labelStatus(group.membershipStatus).toLocaleLowerCase('pt-BR')} e precisa ser ativado antes da atribuição.</small>}
                      </article>
                    ))}
                  </div>
                )}
              </section>
            ) : (
              <section className="pa-related-section">
                <div className="pa-related-heading"><div><h3>Auditoria do usuário</h3><p>Histórico consolidado de perfis, vínculos e alterações de acesso.</p></div><button type="button" className="pa-secondary-button" onClick={() => window.print()}><PrintIcon /> Imprimir</button></div>
                {loadingUserRelations ? <div className="pa-empty-state">Carregando auditoria...</div> : userAudit.length === 0 ? <div className="pa-empty-state">Nenhum evento de auditoria relacionado a este usuário.</div> : <div className="pa-audit-timeline">{userAudit.map((event) => <article key={`${event.audit_source}-${event.audit_id}`}><div className="pa-audit-marker" aria-hidden="true" /><div className="pa-audit-card"><div className="pa-audit-heading"><div><small>{event.audit_source === 'global' ? 'Plataforma' : 'Organização'} · {formatDateTime(event.occurred_at)}</small><h4>{event.event_description ?? event.event_type}</h4></div><span>{event.organization_name ?? 'Escopo global'}</span></div><p><strong>Responsável:</strong> {event.actor_name}{event.actor_email ? ` — ${event.actor_email}` : ''}</p><p><strong>Evento:</strong> {event.event_type}</p></div></article>)}</div>}
              </section>
            )}
          </aside>
        </div>
      )}

      {membershipPanelOpen && (
        <div className="pa-modal-backdrop" role="presentation" onMouseDown={() => setMembershipPanelOpen(false)}>
          <aside className="pa-side-panel" role="dialog" aria-modal="true" aria-label="Vínculo organizacional" onMouseDown={(event) => event.stopPropagation()}>
            <div className="pa-panel-header"><div><p className="pa-eyebrow">Acesso local</p><h2>{membershipForm.membershipId ? 'Editar vínculo' : 'Novo vínculo'}</h2></div><button type="button" onClick={() => setMembershipPanelOpen(false)} title="Fechar"><CloseIcon /></button></div>
            <form className="pa-form" onSubmit={saveMembership}>
              <label>Organização<select value={membershipForm.organizationId} onChange={(event) => setMembershipForm((current) => ({ ...current, organizationId: event.target.value }))} required><option value="">Selecione</option>{organizations.map((organization) => <option key={organization.organization_id} value={organization.organization_id}>{organization.trade_name ?? organization.legal_name}</option>)}</select></label>
              <label>Usuário<select value={membershipForm.userId} onChange={(event) => setMembershipForm((current) => ({ ...current, userId: event.target.value }))} required><option value="">Selecione</option>{users.map((user) => <option key={user.user_id} value={user.user_id}>{getUserName(user)} — {user.email ?? 'sem e-mail'}</option>)}</select></label>
              <div className="pa-form-grid"><label>Situação<select value={membershipForm.status} onChange={(event) => setMembershipForm((current) => ({ ...current, status: event.target.value }))}><option value="invited">Convidado</option><option value="active">Ativo</option><option value="suspended">Suspenso</option><option value="revoked">Revogado</option></select></label><label>Válido até<input type="date" value={membershipForm.validUntil} onChange={(event) => setMembershipForm((current) => ({ ...current, validUntil: event.target.value }))} /></label></div>
              <label>Cargo/função<input value={membershipForm.jobTitle} onChange={(event) => setMembershipForm((current) => ({ ...current, jobTitle: event.target.value }))} /></label>
              <label className="pa-checkbox"><input type="checkbox" checked={membershipForm.isOrganizationAdmin} onChange={(event) => setMembershipForm((current) => ({ ...current, isOrganizationAdmin: event.target.checked }))} />Administrador da organização</label>
              <label>Justificativa<textarea rows={4} value={membershipForm.reason} onChange={(event) => setMembershipForm((current) => ({ ...current, reason: event.target.value }))} required /></label>
              <div className="pa-form-actions"><button type="button" className="pa-secondary-button" onClick={() => setMembershipPanelOpen(false)}>Cancelar</button><button type="submit" className="pa-primary-button" disabled={saving}>{saving ? 'Salvando...' : 'Salvar vínculo'}</button></div>
            </form>
          </aside>
        </div>
      )}

      {userCreationPanelOpen && (
        <div className="pa-modal-backdrop" role="presentation" onMouseDown={() => setUserCreationPanelOpen(false)}>
          <aside className="pa-side-panel" role="dialog" aria-modal="true" aria-label="Criar usuário" onMouseDown={(event) => event.stopPropagation()}>
            <div className="pa-panel-header"><div><p className="pa-eyebrow">Administração global</p><h2>Criar usuário</h2></div><button type="button" onClick={() => setUserCreationPanelOpen(false)} title="Fechar"><CloseIcon /></button></div>
            <form className="pa-form" onSubmit={createUserDirectly}>
              <label>Nome completo<input value={userCreationForm.fullName} onChange={(event) => setUserCreationForm((current) => ({ ...current, fullName: event.target.value }))} required /></label>
              <label>E-mail<input type="email" value={userCreationForm.email} onChange={(event) => setUserCreationForm((current) => ({ ...current, email: event.target.value }))} required /></label>
              <label>Telefone<input value={userCreationForm.phone} onChange={(event) => setUserCreationForm((current) => ({ ...current, phone: event.target.value }))} /></label>
              <div className="pa-form-grid">
                <label>Senha inicial<input type={showCreationPassword ? 'text' : 'password'} value={userCreationForm.password} onChange={(event) => setUserCreationForm((current) => ({ ...current, password: event.target.value }))} minLength={10} autoComplete="new-password" required /></label>
                <label>Confirmar senha<input type={showCreationPassword ? 'text' : 'password'} value={userCreationForm.confirmPassword} onChange={(event) => setUserCreationForm((current) => ({ ...current, confirmPassword: event.target.value }))} minLength={10} autoComplete="new-password" required /></label>
              </div>
              <div className="pa-inline-actions"><button type="button" className="pa-secondary-button" onClick={() => { const password = generateSecureTemporaryPassword(); setUserCreationForm((current) => ({ ...current, password, confirmPassword: password })); setShowCreationPassword(true) }}>Gerar senha temporária</button><label className="pa-checkbox"><input type="checkbox" checked={showCreationPassword} onChange={(event) => setShowCreationPassword(event.target.checked)} />Exibir senha</label></div>
              <label>Organização inicial<select value={userCreationForm.organizationId} onChange={(event) => setUserCreationForm((current) => ({ ...current, organizationId: event.target.value, moduleRoleAssignments: {}, isOrganizationAdmin: event.target.value && !visitorSelected ? current.isOrganizationAdmin : false }))}><option value="">Sem vínculo inicial</option>{organizations.map((organization) => <option key={organization.organization_id} value={organization.organization_id}>{organization.trade_name ?? organization.legal_name}</option>)}</select></label>

              <fieldset className="pa-access-profile-fieldset">
                <legend>Perfis globais disponíveis ({activePlatformRoles.length})</legend>
                <p className="pa-field-help">A lista é carregada integralmente da tabela de perfis globais ativos. É possível combinar perfis, exceto o VISITANTE, que é exclusivo.</p>
                <div className="pa-access-profile-list">
                  {activePlatformRoles.map((role) => (
                    <label className={`pa-access-profile-option ${userCreationForm.platformRoleIds.includes(role.platform_role_id) ? 'selected' : ''}`} key={role.platform_role_id}>
                      <input
                        type="checkbox"
                        checked={userCreationForm.platformRoleIds.includes(role.platform_role_id)}
                        onChange={() => toggleCreationPlatformRole(role)}
                      />
                      <span><strong>{role.role_name}</strong><small>{role.description ?? `Nível ${role.role_level}`}</small></span>
                    </label>
                  ))}
                </div>
              </fieldset>

              {visitorSelected ? (
                <div className="pa-visitor-notice">
                  <strong>VISITANTE — somente leitura</strong>
                  <span>Visualiza todos os módulos habilitados da organização selecionada, respeitando sigilo e escopo hierárquico. Não pode criar, editar, excluir, aprovar, configurar, administrar usuários ou receber outros perfis de escrita.</span>
                </div>
              ) : userCreationForm.organizationId ? (
                <fieldset className="pa-access-profile-fieldset">
                  <legend>Perfis nos módulos habilitados</legend>
                  <p className="pa-field-help">Selecione, quando necessário, um papel para cada módulo habilitado na organização. Todos os papéis ativos do módulo são carregados.</p>
                  {loadingOrganizationModuleRoles ? (
                    <p className="pa-form-note">Carregando perfis dos módulos...</p>
                  ) : moduleRoleGroups.length === 0 ? (
                    <p className="pa-form-note">A organização não possui módulos com papéis disponíveis.</p>
                  ) : (
                    <div className="pa-module-role-list">
                      {moduleRoleGroups.map((group) => (
                        <label key={group.organizationModuleId}>
                          {group.moduleName} ({group.moduleShortName})
                          <select
                            value={userCreationForm.moduleRoleAssignments[group.organizationModuleId] ?? ''}
                            onChange={(event) => setCreationModuleRole(group.organizationModuleId, event.target.value)}
                          >
                            <option value="">Sem perfil neste módulo</option>
                            {group.roles.map((role) => (
                              <option key={role.module_role_id} value={role.module_role_id}>
                                {role.role_name}
                              </option>
                            ))}
                          </select>
                        </label>
                      ))}
                    </div>
                  )}
                </fieldset>
              ) : null}

              <label>Cargo/função inicial<input value={userCreationForm.jobTitle} onChange={(event) => setUserCreationForm((current) => ({ ...current, jobTitle: event.target.value }))} /></label>
              <label className="pa-checkbox"><input type="checkbox" checked={userCreationForm.isOrganizationAdmin} onChange={(event) => setUserCreationForm((current) => ({ ...current, isOrganizationAdmin: event.target.checked }))} disabled={!userCreationForm.organizationId || visitorSelected} />Administrador da organização inicial</label>
              <p className="pa-form-note">A conta será criada ativa e com o e-mail confirmado, sem convite. A senha inicial não será armazenada pela Plataforma SPARKs nem exibida novamente após o fechamento desta tela. Comunique-a ao usuário por canal seguro.</p>
              <div className="pa-form-actions"><button type="button" className="pa-secondary-button" onClick={() => setUserCreationPanelOpen(false)}>Cancelar</button><button type="submit" className="pa-primary-button" disabled={saving}>{saving ? 'Criando...' : 'Criar usuário'}</button></div>
            </form>
          </aside>
        </div>
      )}

      {invitationPanelOpen && (
        <div className="pa-modal-backdrop" role="presentation" onMouseDown={() => setInvitationPanelOpen(false)}>
          <aside className="pa-side-panel" role="dialog" aria-modal="true" aria-label="Convidar usuário" onMouseDown={(event) => event.stopPropagation()}>
            <div className="pa-panel-header"><div><p className="pa-eyebrow">Novo usuário</p><h2>Convidar usuário</h2></div><button type="button" onClick={() => setInvitationPanelOpen(false)} title="Fechar"><CloseIcon /></button></div>
            <form className="pa-form" onSubmit={sendInvitation}>
              <label>Nome completo<input value={invitationForm.fullName} onChange={(event) => setInvitationForm((current) => ({ ...current, fullName: event.target.value }))} /></label>
              <label>E-mail<input type="email" value={invitationForm.email} onChange={(event) => setInvitationForm((current) => ({ ...current, email: event.target.value }))} required /></label>
              <label>Organização inicial<select value={invitationForm.organizationId} onChange={(event) => setInvitationForm((current) => ({ ...current, organizationId: event.target.value }))}><option value="">Sem vínculo inicial</option>{organizations.map((organization) => <option key={organization.organization_id} value={organization.organization_id}>{organization.trade_name ?? organization.legal_name}</option>)}</select></label>
              <label>Perfil global inicial<select value={invitationForm.platformRoleId} onChange={(event) => setInvitationForm((current) => ({ ...current, platformRoleId: event.target.value }))}><option value="">Nenhum perfil global</option>{roles.filter((role) => role.active).map((role) => <option key={role.platform_role_id} value={role.platform_role_id}>{role.role_name}</option>)}</select></label>
              <label>Cargo/função inicial<input value={invitationForm.jobTitle} onChange={(event) => setInvitationForm((current) => ({ ...current, jobTitle: event.target.value }))} /></label>
              <label className="pa-checkbox"><input type="checkbox" checked={invitationForm.isOrganizationAdmin} onChange={(event) => setInvitationForm((current) => ({ ...current, isOrganizationAdmin: event.target.checked }))} disabled={!invitationForm.organizationId} />Administrador da organização inicial</label>
              <p className="pa-form-note">O convite é enviado por uma Edge Function segura. A chave de serviço nunca é exposta no navegador.</p>
              <div className="pa-form-actions"><button type="button" className="pa-secondary-button" onClick={() => setInvitationPanelOpen(false)}>Cancelar</button><button type="submit" className="pa-primary-button" disabled={saving}>{saving ? 'Enviando...' : 'Enviar convite'}</button></div>
            </form>
          </aside>
        </div>
      )}
      <button type="button" className="pa-scroll-top-button" onClick={scrollToPageTop} title="Voltar ao início da tela" aria-label="Voltar ao início da tela">↑</button>
    </section>
  )
}
