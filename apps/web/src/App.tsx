import { useEffect, useMemo, useState } from 'react'
import type { FormEvent, KeyboardEvent } from 'react'
import type {
  AuthChangeEvent,
  Session,
} from '@supabase/supabase-js'

import { supabase } from './lib/supabase'
import { useLocation, useNavigate } from 'react-router-dom'

import { SkpeWorkspace } from './modules/skpe/app/SkpeWorkspace'
import {
  parsePlatformRoute,
  platformRoutes,
} from './modules/skpe/app/skpeRoutes'
import { PlatformAdmin } from './modules/platform-admin/PlatformAdmin'
import { OrganizationBrandingLogo } from './components/organization-branding/OrganizationBrandingLogo'
import { UserProfileDialog } from './components/user-profile/UserProfileDialog'

import './App.css'

const LAST_SUCCESSFUL_EMAIL_KEY =
  'skpe:last-successful-email'
const PLATFORM_THEME_KEY = 'sparks:platform-theme'

type MessageType = 'info' | 'success' | 'error'

type Organization = {
  organization_id: string
  organization_code: string
  legal_name: string
  trade_name: string | null
  organization_level: string
  membership_status: string
  is_organization_admin: boolean
  access_origin: string
  access_mode: string
  source_organization_id: string | null
  source_organization_name: string | null
  hierarchy_depth: number | null
  can_manage_organization: boolean
}

type OrganizationHierarchyNode = {
  organization_id: string
  parent_organization_id: string | null
  hierarchy_depth: number
  hierarchy_path: string[]
}

type PlatformModule = {
  organization_module_id: string
  module_id: string
  module_code: string
  module_name: string
  module_short_name: string
  module_description: string | null
  module_route_path: string | null
  module_icon_name: string | null
  role_code: string
  role_name: string
}

type PlatformRole = {
  role_code: string
  role_name: string
  role_level: number
  valid_from: string
  valid_until: string | null
}

type OrganizationNetworkRow = {
  organization_id: string
  organization_code: string
  organization_name: string
  organization_level: string
  hierarchy_depth: number
  module_enabled: boolean
  active_projects: number
  average_project_progress: number
  initiatives_total: number
  initiatives_attention: number
  active_memberships: number
}


const ORGANIZATION_LEVEL_LABELS: Record<string, string> = {
  singular: 'Cooperativa singular',
  federation_central: 'Central ou federação',
  confederation: 'Confederação',
  system_guardian: 'Organização guardiã do sistema',
  matrix: 'Matriz',
  branch: 'Filial',
  unit: 'Unidade',
  national: 'Nacional',
  regional: 'Regional',
  state: 'Estadual',
  municipal: 'Municipal',
}

const MEMBERSHIP_STATUS_LABELS: Record<string, string> = {
  invited: 'Convidado',
  active: 'Ativo',
  suspended: 'Suspenso',
  revoked: 'Revogado',
  inactive: 'Inativo',
  pending: 'Pendente',
  archived: 'Arquivado',
}

function getOrganizationLevelLabel(value: string) {
  return ORGANIZATION_LEVEL_LABELS[value] ?? value
}

function getOrganizationMembershipStatusLabel(
  organization: Organization,
) {
  const normalized = organization.membership_status?.trim()

  if (normalized && MEMBERSHIP_STATUS_LABELS[normalized]) {
    return MEMBERSHIP_STATUS_LABELS[normalized]
  }

  // access_origin/access_mode nao sao situacoes de vinculo.
  // Quando uma RPC legada devolver a modalidade no campo de status,
  // preservamos a semantica do vinculo direto ativo na interface.
  if (
    normalized === 'hierarchical' ||
    normalized === 'hierarchical_management' ||
    normalized === 'direct_membership' ||
    normalized === 'direct'
  ) {
    return 'Ativo'
  }

  return normalized || 'Nao informado'
}

function isHierarchicalReadOnlyAccess(
  organization: Organization,
) {
  return (
    organization.access_origin === 'hierarchical_management' ||
    organization.access_mode === 'read_only'
  )
}


function getOrganizationProfileLabel(
  organization: Organization,
) {
  if (isHierarchicalReadOnlyAccess(organization)) {
    return 'Visualização hierárquica'
  }

  return organization.is_organization_admin
    ? 'Administrador'
    : 'Participante'
}

type PasswordVisibilityButtonProps = {
  visible: boolean
  onToggle: () => void
  label?: string
}

function EyeIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      focusable="false"
    >
      <path
        d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />

      <circle
        cx="12"
        cy="12"
        r="3"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      />
    </svg>
  )
}

function EyeOffIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      focusable="false"
    >
      <path
        d="M3 3l18 18"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      />

      <path
        d="M10.6 10.6a2 2 0 002.8 2.8"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />

      <path
        d="M9.9 4.2A10.7 10.7 0 0112 4c5 0 9 4 10 8a12.8 12.8 0 01-2.4 4.4"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />

      <path
        d="M6.2 6.2A12 12 0 002 12c1 4 5 8 10 8a10.6 10.6 0 004.4-1"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function SunIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <circle cx="12" cy="12" r="4" fill="none" stroke="currentColor" strokeWidth="1.8" />
      <path d="M12 2v2M12 20v2M4.93 4.93l1.42 1.42M17.65 17.65l1.42 1.42M2 12h2M20 12h2M4.93 19.07l1.42-1.42M17.65 6.35l1.42-1.42" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  )
}

function MoonIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path d="M20 15.2A8.4 8.4 0 118.8 4a7 7 0 0011.2 11.2z" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}
function SettingsIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <circle cx="12" cy="12" r="3" fill="none" stroke="currentColor" strokeWidth="1.8" />
      <path d="M19.4 15a1.7 1.7 0 00.34 1.88l.06.06-2.12 2.12-.06-.06a1.7 1.7 0 00-1.88-.34 1.7 1.7 0 00-1.03 1.56V20.3h-3v-.08a1.7 1.7 0 00-1.03-1.56 1.7 1.7 0 00-1.88.34l-.06.06-2.12-2.12.06-.06A1.7 1.7 0 007 15a1.7 1.7 0 00-1.56-1.03h-.08v-3h.08A1.7 1.7 0 007 9a1.7 1.7 0 00-.34-1.88l-.06-.06 2.12-2.12.06.06A1.7 1.7 0 0010.68 5 1.7 1.7 0 0011.7 3.44v-.08h3v.08A1.7 1.7 0 0015.74 5a1.7 1.7 0 001.88-.34l.06-.06 2.12 2.12-.06.06A1.7 1.7 0 0019.4 9a1.7 1.7 0 001.56 1.03h.08v3h-.08A1.7 1.7 0 0019.4 15z" fill="none" stroke="currentColor" strokeWidth="1.45" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function SearchIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      focusable="false"
    >
      <circle
        cx="11"
        cy="11"
        r="6.5"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      />
      <path
        d="M16 16l4 4"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
    </svg>
  )
}

function CardsViewIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <rect x="3.5" y="4" width="7" height="6" rx="1" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <rect x="13.5" y="4" width="7" height="6" rx="1" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <rect x="3.5" y="14" width="7" height="6" rx="1" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <rect x="13.5" y="14" width="7" height="6" rx="1" fill="none" stroke="currentColor" strokeWidth="1.7" />
    </svg>
  )
}

function RowsViewIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path d="M9 6h11M9 12h11M9 18h11" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
      <circle cx="5" cy="6" r="1" fill="currentColor" />
      <circle cx="5" cy="12" r="1" fill="currentColor" />
      <circle cx="5" cy="18" r="1" fill="currentColor" />
    </svg>
  )
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

function ArrowRightIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      focusable="false"
    >
      <path
        d="M5 12h14M13 6l6 6-6 6"
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
      <rect x="9" y="3" width="6" height="4" rx="1" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <rect x="3" y="17" width="6" height="4" rx="1" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <rect x="15" y="17" width="6" height="4" rx="1" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <path d="M12 7v5M6 17v-3h12v3" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}
function LogoutIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path d="M4 3.5h9.5v17H4z" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinejoin="round" />
      <path d="M13.5 12H21M18 9l3 3-3 3" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M8.5 12h.01" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" />
    </svg>
  )
}
function StrategyIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      focusable="false"
    >
      <circle
        cx="12"
        cy="12"
        r="8"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <circle
        cx="12"
        cy="12"
        r="4"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <circle
        cx="12"
        cy="12"
        r="1.5"
        fill="currentColor"
      />

      <path
        d="M14 10l5-5M16.5 5H19v2.5"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function PasswordVisibilityButton({
  visible,
  onToggle,
  label = 'senha',
}: PasswordVisibilityButtonProps) {
  const accessibleLabel = visible
    ? `Ocultar ${label}`
    : `Mostrar ${label}`

  return (
    <button
      type="button"
      className="password-toggle"
      onClick={onToggle}
      aria-label={accessibleLabel}
      aria-pressed={visible}
      title={accessibleLabel}
    >
      {visible ? <EyeOffIcon /> : <EyeIcon />}
    </button>
  )
}

function App() {
  const location = useLocation()
  const navigate = useNavigate()

  const [session, setSession] =
    useState<Session | null>(null)

  const [userProfileOpen, setUserProfileOpen] =
    useState(false)

  const [userAvatarUrl, setUserAvatarUrl] =
    useState<string | null>(null)

  const [userDisplayName, setUserDisplayName] =
    useState('')

  const [userProfileRefresh, setUserProfileRefresh] =
    useState(0)

  const [platformTheme, setPlatformTheme] = useState<'light' | 'dark'>(() => {
    const savedTheme = localStorage.getItem(PLATFORM_THEME_KEY)

    if (savedTheme === 'light' || savedTheme === 'dark') {
      return savedTheme
    }

    return window.matchMedia?.('(prefers-color-scheme: dark)').matches
      ? 'dark'
      : 'light'
  })
  const [email, setEmail] = useState(() => {
    return (
      localStorage.getItem(
        LAST_SUCCESSFUL_EMAIL_KEY,
      ) ?? ''
    )
  })

  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] =
    useState(false)

  const [passwordFieldReady, setPasswordFieldReady] =
    useState(false)

  const [organizations, setOrganizations] =
    useState<Organization[]>([])

  const [organizationHierarchy, setOrganizationHierarchy] =
    useState<OrganizationHierarchyNode[]>([])

  const [platformAdminOpen, setPlatformAdminOpen] =
    useState(false)

  const [organizationAdminOpen, setOrganizationAdminOpen] =
    useState(false)

  const [organizationViewMode, setOrganizationViewMode] =
    useState<'cards' | 'grid' | 'hierarchy'>('cards')

  const [organizationSearch, setOrganizationSearch] =
    useState('')

  const [organizationSortDirection, setOrganizationSortDirection] =
    useState<'asc' | 'desc'>('asc')

  const [
    selectedOrganization,
    setSelectedOrganization,
  ] = useState<Organization | null>(null)

  const visibleOrganizations = useMemo(() => {
    const term = organizationSearch.trim().toLocaleLowerCase('pt-BR')
    return [...organizations]
      .filter((organization) => {
        if (!term) return true
        return [organization.organization_code, organization.trade_name, organization.legal_name]
          .filter(Boolean)
          .some((value) => String(value).toLocaleLowerCase('pt-BR').includes(term))
      })
      .sort((first, second) => {
        const firstName = first.trade_name ?? first.legal_name ?? first.organization_code
        const secondName = second.trade_name ?? second.legal_name ?? second.organization_code
        const comparison = firstName.localeCompare(secondName, 'pt-BR')
        return organizationSortDirection === 'asc' ? comparison : -comparison
      })
  }, [organizations, organizationSearch, organizationSortDirection])

  const hierarchicalVisibleOrganizations = useMemo(() => {
    if (organizationHierarchy.length === 0) {
      return visibleOrganizations
    }

    const hierarchyByOrganization = new Map(
      organizationHierarchy.map((node) => [
        node.organization_id,
        node,
      ]),
    )

    return [...visibleOrganizations].sort((first, second) => {
      const firstNode = hierarchyByOrganization.get(
        first.organization_id,
      )
      const secondNode = hierarchyByOrganization.get(
        second.organization_id,
      )

      const firstPath = firstNode?.hierarchy_path.join('/') ?? first.organization_id
      const secondPath = secondNode?.hierarchy_path.join('/') ?? second.organization_id

      const pathComparison = firstPath.localeCompare(
        secondPath,
        'pt-BR',
      )

      if (pathComparison !== 0) {
        return pathComparison
      }

      const firstName =
        first.trade_name ??
        first.legal_name ??
        first.organization_code
      const secondName =
        second.trade_name ??
        second.legal_name ??
        second.organization_code

      return firstName.localeCompare(secondName, 'pt-BR')
    })
  }, [organizationHierarchy, visibleOrganizations])


  const [modules, setModules] =
    useState<PlatformModule[]>([])

  const [organizationNetwork, setOrganizationNetwork] =
    useState<OrganizationNetworkRow[]>([])

  const [loadingOrganizationNetwork, setLoadingOrganizationNetwork] =
    useState(false)

  const networkSummary = useMemo(() => {
    const rows = organizationNetwork
    const organizationsTotal = rows.length
    const activeProjects = rows.reduce((total, row) => total + Number(row.active_projects ?? 0), 0)
    const initiativesTotal = rows.reduce((total, row) => total + Number(row.initiatives_total ?? 0), 0)
    const initiativesAttention = rows.reduce((total, row) => total + Number(row.initiatives_attention ?? 0), 0)
    const progressRows = rows.filter((row) => Number(row.active_projects ?? 0) > 0)
    const averageProgress = progressRows.length
      ? progressRows.reduce((total, row) => total + Number(row.average_project_progress ?? 0), 0) / progressRows.length
      : 0

    return {
      organizationsTotal,
      activeProjects,
      initiativesTotal,
      initiativesAttention,
      averageProgress,
    }
  }, [organizationNetwork])

  const [openedModule, setOpenedModule] =
    useState<PlatformModule | null>(null)

  const [platformRoles, setPlatformRoles] =
    useState<PlatformRole[]>([])

  const [message, setMessage] = useState('')

  const [messageType, setMessageType] =
    useState<MessageType>('info')

  const [loading, setLoading] = useState(true)

  const [loadingModules, setLoadingModules] =
    useState(false)

  const [
    forgotPasswordMode,
    setForgotPasswordMode,
  ] = useState(false)

  const [
    passwordRecoveryMode,
    setPasswordRecoveryMode,
  ] = useState(false)

  const [newPassword, setNewPassword] =
    useState('')

  const [
    confirmNewPassword,
    setConfirmNewPassword,
  ] = useState('')

  const [
    showNewPassword,
    setShowNewPassword,
  ] = useState(false)

  const [
    showConfirmNewPassword,
    setShowConfirmNewPassword,
  ] = useState(false)

  const showMessage = (
    text: string,
    type: MessageType = 'info',
  ) => {
    setMessage(text)
    setMessageType(type)
  }

  const clearMessage = () => {
    setMessage('')
    setMessageType('info')
  }

  useEffect(() => {
    if (!session?.user.id) {
      setUserAvatarUrl(null)
      setUserDisplayName('')
      return
    }

    let active = true

    const loadTransversalProfile = async () => {
      const { data, error } = await supabase.rpc(
        'get_my_transversal_profile',
      )

      if (!active || error) {
        if (error) {
          console.error('Erro ao carregar perfil transversal', error)
        }
        return
      }

      const profile = ((data ?? [])[0] ?? null) as {
        full_name: string | null
        display_name: string | null
        avatar_storage_path: string | null
      } | null

      if (!profile) {
        return
      }

      setUserDisplayName(
        profile.display_name ??
          profile.full_name ??
          session.user.email ??
          'Usuário',
      )

      if (!profile.avatar_storage_path) {
        setUserAvatarUrl(null)
        return
      }

      const { data: signedData, error: signedError } =
        await supabase.storage
          .from('user-avatars')
          .createSignedUrl(
            profile.avatar_storage_path,
            60 * 60,
          )

      if (!active) {
        return
      }

      if (signedError) {
        setUserAvatarUrl(null)
        return
      }

      setUserAvatarUrl(signedData.signedUrl)
    }

    void loadTransversalProfile()

    return () => {
      active = false
    }
  }, [session?.user.id, session?.user.email, userProfileRefresh])

  useEffect(() => {
    let mounted = true

    const loadInitialSession = async () => {
      const { data, error } =
        await supabase.auth.getSession()

      if (!mounted) {
        return
      }

      if (error) {
        showMessage(
          `Erro ao verificar sessão: ${error.message}`,
          'error',
        )
      }

      setSession(data.session)
      setLoading(false)
    }

    void loadInitialSession()

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(
      (
        event: AuthChangeEvent,
        currentSession: Session | null,
      ) => {
        if (!mounted) {
          return
        }

        setSession(currentSession)

        if (event === 'PASSWORD_RECOVERY') {
          setPasswordRecoveryMode(true)
          setForgotPasswordMode(false)
          setPassword('')
          setShowPassword(false)

          showMessage(
            'Defina uma nova senha para concluir a recuperação da conta.',
            'info',
          )
        }

        if (event === 'SIGNED_OUT') {
          setPassword('')
          setShowPassword(false)
          setPasswordFieldReady(false)
          setOrganizations([])
          setOrganizationHierarchy([])
          setModules([])
          setPlatformRoles([])
          setSelectedOrganization(null)
          setOpenedModule(null)
          setPlatformAdminOpen(false)
          setOrganizationAdminOpen(false)
        }
      },
    )

    return () => {
      mounted = false
      subscription.unsubscribe()
    }
  }, [])

  useEffect(() => {
    let mounted = true

    const loadAuthenticatedUserData =
      async () => {
        if (!session || passwordRecoveryMode) {
          setOrganizations([])
          setOrganizationHierarchy([])
          setPlatformRoles([])
          return
        }

        setLoading(true)
        clearMessage()

        const [
          organizationsResponse,
          platformRolesResponse,
          hierarchyResponse,
        ] = await Promise.all([
          supabase.rpc('get_my_organizations_v2'),
          supabase.rpc('get_my_platform_roles'),
          supabase.rpc('get_my_organization_hierarchy_v1'),
        ])

        if (!mounted) {
          return
        }

        if (organizationsResponse.error) {
          showMessage(
            `Erro ao carregar organizações: ${organizationsResponse.error.message}`,
            'error',
          )

          setOrganizations([])
        } else {
          setOrganizations(
            (organizationsResponse.data ??
              []) as Organization[],
          )
        }

        if (hierarchyResponse.error) {
          console.error(
            'Não foi possível carregar a hierarquia organizacional canônica:',
            hierarchyResponse.error,
          )

          setOrganizationHierarchy([])
        } else {
          setOrganizationHierarchy(
            (hierarchyResponse.data ?? []) as OrganizationHierarchyNode[],
          )
        }

        if (platformRolesResponse.error) {
          console.error(
            'Não foi possível carregar os papéis globais:',
            platformRolesResponse.error,
          )

          setPlatformRoles([])
        } else {
          setPlatformRoles(
            (platformRolesResponse.data ??
              []) as PlatformRole[],
          )
        }

        setLoading(false)
      }

    void loadAuthenticatedUserData()

    return () => {
      mounted = false
    }
  }, [session, passwordRecoveryMode])

  const handleSelectOrganization = async (
    organization: Organization,
    preserveRoute = false,
  ) => {
    setPlatformAdminOpen(false)
    setOrganizationAdminOpen(false)
    setSelectedOrganization(organization)
    setOpenedModule(null)
    setModules([])
    setOrganizationNetwork([])
    setLoadingModules(true)
    setLoadingOrganizationNetwork(true)
    clearMessage()

    if (!preserveRoute) {
      navigate(
        platformRoutes.organization(
          organization.organization_id,
        ),
      )
    }

    const [modulesResponse, networkResponse] = await Promise.all([
      supabase.rpc('get_my_modules', {
        target_organization_id: organization.organization_id,
      }),
      supabase.rpc('get_organization_network_dashboard', {
        target_organization_id: organization.organization_id,
        target_module_code: 'SK-PE',
      }),
    ])

    if (modulesResponse.error) {
      showMessage(
        `Erro ao carregar módulos: ${modulesResponse.error.message}`,
        'error',
      )
      setModules([])
    } else {
      setModules((modulesResponse.data ?? []) as PlatformModule[])
    }

    if (networkResponse.error) {
      console.error('Não foi possível carregar o painel da rede organizacional:', networkResponse.error)
      setOrganizationNetwork([])
    } else {
      setOrganizationNetwork((networkResponse.data ?? []) as OrganizationNetworkRow[])
    }

    setLoadingModules(false)
    setLoadingOrganizationNetwork(false)
  }

  const handleReturnToOrganizations = () => {
    setPlatformAdminOpen(false)
    setOrganizationAdminOpen(false)
    setSelectedOrganization(null)
    setOpenedModule(null)
    setModules([])
    setOrganizationNetwork([])
    setLoadingOrganizationNetwork(false)
    clearMessage()
    navigate(platformRoutes.home())
  }

  const handleOpenPlatformAdmin = () => {
    setPlatformAdminOpen(true)
    setOrganizationAdminOpen(false)
    setSelectedOrganization(null)
    setOpenedModule(null)
    setModules([])
    clearMessage()
    navigate(platformRoutes.platformAdmin())
  }

  const handleClosePlatformAdmin = () => {
    setPlatformAdminOpen(false)
    clearMessage()
    navigate(platformRoutes.home())
  }
  const handleOpenOrganizationAdmin = () => {
    if (!selectedOrganization) {
      return
    }

    const canManageOrganization =
      selectedOrganization.is_organization_admin ||
      platformRoles.some(
        (role) => role.role_code === 'super_admin',
      )

    if (!canManageOrganization) {
      showMessage(
        'Seu perfil nao possui permissao para administrar esta organização.',
        'error',
      )
      return
    }

    setPlatformAdminOpen(false)
    setOrganizationAdminOpen(true)
    setOpenedModule(null)
    clearMessage()
    navigate(
      platformRoutes.organizationAdmin(
        selectedOrganization.organization_id,
      ),
    )
  }

  const handleCloseOrganizationAdmin = () => {
    setOrganizationAdminOpen(false)
    clearMessage()
    navigate(
      selectedOrganization
        ? platformRoutes.organization(
            selectedOrganization.organization_id,
          )
        : platformRoutes.home(),
    )
  }

  const handleReturnToModules = () => {
    setOpenedModule(null)
    clearMessage()
    navigate(
      selectedOrganization
        ? platformRoutes.organization(
            selectedOrganization.organization_id,
          )
        : platformRoutes.home(),
    )
  }

  const handleOpenModule = (
    module: PlatformModule,
  ) => {
    if (module.module_code === 'SK-PE') {
      setOpenedModule(module)
      clearMessage()
      if (selectedOrganization) {
        navigate(
          platformRoutes.module(
            selectedOrganization.organization_id,
            module.module_code,
          ),
        )
      }
      return
    }

    showMessage(
      `${module.module_name} ainda está em desenvolvimento.`,
      'info',
    )
  }

  const handleLogin = async (
    event: FormEvent<HTMLFormElement>,
  ) => {
    event.preventDefault()

    setLoading(true)
    clearMessage()

    const normalizedEmail = email
      .trim()
      .toLowerCase()

    const { error } =
      await supabase.auth.signInWithPassword({
        email: normalizedEmail,
        password,
      })

    if (error) {
      showMessage(
        `Não foi possível entrar: ${error.message}`,
        'error',
      )

      setLoading(false)
      return
    }

    localStorage.setItem(
      LAST_SUCCESSFUL_EMAIL_KEY,
      normalizedEmail,
    )

    setEmail(normalizedEmail)
    setPassword('')
    setShowPassword(false)
    setPasswordFieldReady(false)
    setLoading(false)
  }

  const handleLogout = async () => {
    setLoading(true)
    clearMessage()

    const { error } =
      await supabase.auth.signOut()

    if (error) {
      showMessage(
        `Não foi possível sair: ${error.message}`,
        'error',
      )

      setLoading(false)
      return
    }

    setPassword('')
    setShowPassword(false)
    setPasswordFieldReady(false)
    setOrganizations([])
    setModules([])
    setPlatformRoles([])
    setSelectedOrganization(null)
    setOpenedModule(null)
    setPlatformAdminOpen(false)
    setOrganizationAdminOpen(false)
    setLoading(false)
  }

  const handlePasswordResetRequest = async (
    event: FormEvent<HTMLFormElement>,
  ) => {
    event.preventDefault()

    setLoading(true)
    clearMessage()

    const normalizedEmail = email
      .trim()
      .toLowerCase()

    const { error } =
      await supabase.auth.resetPasswordForEmail(
        normalizedEmail,
        {
          redirectTo: window.location.origin,
        },
      )

    if (error) {
      console.error(
        'Falha ao solicitar recuperação de senha:',
        error,
      )
    }

    setEmail(normalizedEmail)

    showMessage(
      'Caso exista uma conta vinculada a este e-mail, enviaremos as instruções de recuperação.',
      'success',
    )

    setLoading(false)
  }

  const handleNewPassword = async (
    event: FormEvent<HTMLFormElement>,
  ) => {
    event.preventDefault()
    clearMessage()

    if (newPassword.length < 8) {
      showMessage(
        'A nova senha deve ter pelo menos 8 caracteres.',
        'error',
      )

      return
    }

    if (newPassword !== confirmNewPassword) {
      showMessage(
        'As senhas informadas não são iguais.',
        'error',
      )

      return
    }

    setLoading(true)

    try {
      const { error: updateError } =
        await supabase.auth.updateUser({
          password: newPassword,
        })

      if (updateError) {
        showMessage(
          `Não foi possível atualizar a senha: ${updateError.message}`,
          'error',
        )

        return
      }

      setNewPassword('')
      setConfirmNewPassword('')
      setShowNewPassword(false)
      setShowConfirmNewPassword(false)

      showMessage(
        'Senha atualizada com sucesso. Entre novamente com a nova senha.',
        'success',
      )

      await supabase.auth.signOut()

      setPasswordRecoveryMode(false)
      setForgotPasswordMode(false)
      setSession(null)

      window.history.replaceState(
        {},
        document.title,
        window.location.origin,
      )
    } catch (error) {
      console.error(
        'Erro inesperado durante a atualização da senha:',
        error,
      )

      showMessage(
        'Ocorreu um erro inesperado ao atualizar a senha.',
        'error',
      )
    } finally {
      setLoading(false)
    }
  }

  const openForgotPassword = () => {
    setForgotPasswordMode(true)
    setPassword('')
    setShowPassword(false)
    setPasswordFieldReady(false)
    clearMessage()
  }

  const returnToLogin = () => {
    setForgotPasswordMode(false)
    setPassword('')
    setShowPassword(false)
    setPasswordFieldReady(false)
    clearMessage()
  }

  const isPlatformSuperAdmin =
    platformRoles.some(
      (role) =>
        role.role_code === 'super_admin',
    )

  const currentRoute = useMemo(
    () => parsePlatformRoute(location.pathname),
    [location.pathname],
  )

  useEffect(() => {
    if (!session || passwordRecoveryMode || loading) {
      return
    }

    if (
      currentRoute.kind === 'home' ||
      currentRoute.kind === 'workspace'
    ) {
      if (
        platformAdminOpen ||
        organizationAdminOpen ||
        selectedOrganization ||
        openedModule
      ) {
        setPlatformAdminOpen(false)
        setOrganizationAdminOpen(false)
        setSelectedOrganization(null)
        setOpenedModule(null)
        setModules([])
        setOrganizationNetwork([])
      }
      return
    }

    if (currentRoute.kind === 'platform-admin') {
      if (!isPlatformSuperAdmin) {
        clearMessage()
        setPlatformAdminOpen(false)
        setOrganizationAdminOpen(false)
        setSelectedOrganization(null)
        setOpenedModule(null)
        setModules([])
        setOrganizationNetwork([])
        navigate(platformRoutes.home(), { replace: true })
        return
      }

      setPlatformAdminOpen(true)
      setOrganizationAdminOpen(false)
      setSelectedOrganization(null)
      setOpenedModule(null)
      setModules([])
      return
    }

    if (currentRoute.kind === 'unknown') {
      showMessage(
        'A rota informada não é reconhecida. Retornamos ao início da plataforma.',
        'error',
      )
      navigate(platformRoutes.home(), { replace: true })
      return
    }

    const routeOrganization = organizations.find(
      (organization) =>
        organization.organization_id ===
        currentRoute.organizationId,
    )

    if (!routeOrganization) {
      if (organizations.length > 0) {
        showMessage(
          'A organização indicada na rota não está disponível para o seu usuário.',
          'error',
        )
        navigate(platformRoutes.home(), { replace: true })
      }
      return
    }

    if (
      selectedOrganization?.organization_id !==
      routeOrganization.organization_id
    ) {
      void handleSelectOrganization(
        routeOrganization,
        true,
      )
      return
    }

    setPlatformAdminOpen(false)

    if (currentRoute.kind === 'organization') {
      setOrganizationAdminOpen(false)
      setOpenedModule(null)
      return
    }

    if (currentRoute.kind === 'organization-admin') {
      const canManageOrganization =
        routeOrganization.is_organization_admin ||
        isPlatformSuperAdmin

      if (!canManageOrganization) {
        showMessage(
          'Seu perfil não possui permissão para administrar esta organização.',
          'error',
        )
        navigate(
          platformRoutes.organization(
            routeOrganization.organization_id,
          ),
          { replace: true },
        )
        return
      }

      setOrganizationAdminOpen(true)
      setOpenedModule(null)
      return
    }

    setOrganizationAdminOpen(false)

    if (loadingModules) {
      return
    }

    const requestedModuleCode =
      currentRoute.kind === 'skpe'
        ? 'SK-PE'
        : currentRoute.moduleCode.toUpperCase()

    const requestedModule = modules.find(
      (module) =>
        module.module_code.toUpperCase() ===
        requestedModuleCode,
    )

    if (requestedModule) {
      setOpenedModule(requestedModule)
      return
    }

    showMessage(
      'O módulo indicado na rota não está disponível para esta organização.',
      'error',
    )
    navigate(
      platformRoutes.organization(
        routeOrganization.organization_id,
      ),
      { replace: true },
    )
  }, [
    currentRoute,
    isPlatformSuperAdmin,
    loading,
    loadingModules,
    modules,
    navigate,
    openedModule,
    organizationAdminOpen,
    organizations,
    passwordRecoveryMode,
    platformAdminOpen,
    selectedOrganization,
    session,
  ])

  if (organizationAdminOpen && selectedOrganization) {
    return (
      <SkpeWorkspace
        mode="organization-admin"
        initialSection="organization"
        organizationId={
          selectedOrganization.organization_id
        }
        organizationName={
          selectedOrganization.trade_name ??
          selectedOrganization.legal_name
        }
        organizationCode={
          selectedOrganization.organization_code
        }
        userRoleCode="administrator"
        userRoleName="Administrador da Organização"
        isOrganizationAdmin={
          selectedOrganization.is_organization_admin ||
          isPlatformSuperAdmin
        }
        isPlatformSuperAdmin={
          isPlatformSuperAdmin
        }
        onReturnToModules={
          handleCloseOrganizationAdmin
        }
        userDisplayName={userDisplayName || session?.user.email || 'Usuário'}
        userEmail={session?.user.email ?? ''}
        userAvatarUrl={userAvatarUrl}
        onOpenPlatformAdmin={handleOpenPlatformAdmin}
        onOpenUserProfile={() => setUserProfileOpen(true)}
      />
    )
  }

  if (openedModule && selectedOrganization) {
    return (
      <SkpeWorkspace
        organizationId={
          selectedOrganization.organization_id
        }
        organizationName={
          selectedOrganization.trade_name ??
          selectedOrganization.legal_name
        }
        organizationCode={
          selectedOrganization.organization_code
        }
        userRoleCode={openedModule.role_code}
        userRoleName={openedModule.role_name}
        isOrganizationAdmin={
          selectedOrganization.is_organization_admin
        }
        isPlatformSuperAdmin={
          isPlatformSuperAdmin
        }
        onReturnToModules={
          handleReturnToModules
        }
        userDisplayName={userDisplayName || session?.user.email || 'Usuário'}
        userEmail={session?.user.email ?? ''}
        userAvatarUrl={userAvatarUrl}
        onOpenPlatformAdmin={handleOpenPlatformAdmin}
        onOpenUserProfile={() => setUserProfileOpen(true)}
      />
    )
  }

  if (
    loading &&
    !session &&
    !forgotPasswordMode
  ) {
    return (
      <main className="app-shell">
        <section className="panel login-panel">
          <p className="loading-text">
            Carregando...
          </p>
        </section>
      </main>
    )
  }

  if (passwordRecoveryMode) {
    return (
      <main className="app-shell">
        <section className="panel login-panel">
          <div className="login-brand">
            <img
              src="/sparkoop-mascot.png"
              alt="Mascote da Plataforma SPARKs"
            />

            <p className="eyebrow">
              Plataforma SPARKs
            </p>
          </div>

          <h1>Definir nova senha</h1>

          <p className="supporting-text">
            Informe e confirme a nova senha da
            sua conta.
          </p>

          <form
            onSubmit={handleNewPassword}
            className="login-form"
          >
            <label>
              Nova senha

              <div className="password-field">
                <input
                  type={
                    showNewPassword
                      ? 'text'
                      : 'password'
                  }
                  value={newPassword}
                  onChange={(event) =>
                    setNewPassword(
                      event.target.value,
                    )
                  }
                  autoComplete="new-password"
                  minLength={8}
                  required
                />

                <PasswordVisibilityButton
                  visible={showNewPassword}
                  onToggle={() =>
                    setShowNewPassword(
                      (current) => !current,
                    )
                  }
                  label="nova senha"
                />
              </div>
            </label>

            <label>
              Confirmar nova senha

              <div className="password-field">
                <input
                  type={
                    showConfirmNewPassword
                      ? 'text'
                      : 'password'
                  }
                  value={
                    confirmNewPassword
                  }
                  onChange={(event) =>
                    setConfirmNewPassword(
                      event.target.value,
                    )
                  }
                  autoComplete="new-password"
                  minLength={8}
                  required
                />

                <PasswordVisibilityButton
                  visible={
                    showConfirmNewPassword
                  }
                  onToggle={() =>
                    setShowConfirmNewPassword(
                      (current) => !current,
                    )
                  }
                  label="confirmação da nova senha"
                />
              </div>
            </label>

            <button
              type="submit"
              className="primary-button"
              disabled={loading}
            >
              {loading
                ? 'Atualizando...'
                : 'Atualizar senha'}
            </button>
          </form>

          {message && (
            <p
              className={`message message-${messageType}`}
              role={
                messageType === 'error'
                  ? 'alert'
                  : 'status'
              }
            >
              {message}
            </p>
          )}
        </section>
      </main>
    )
  }

  if (!session) {
    return (
      <main className="app-shell">
        <section className="panel login-panel">
          <div className="login-brand">
            <img
              src="/sparkoop-mascot.png"
              alt="Mascote da Plataforma SPARKs"
            />

            <p className="eyebrow">
              Plataforma SPARKs
            </p>
          </div>

          <h1>
            {forgotPasswordMode
              ? 'Recuperar acesso'
              : 'Gestão Integrada das Organizações'}
          </h1>

          <p className="supporting-text">
            {forgotPasswordMode
              ? 'Informe seu e-mail para receber as instruções de recuperação.'
              : 'Entre com seu usuário para acessar a plataforma.'}
          </p>

          {forgotPasswordMode ? (
            <form
              onSubmit={
                handlePasswordResetRequest
              }
              className="login-form"
            >
              <label>
                E-mail

                <input
                  type="email"
                  value={email}
                  onChange={(event) =>
                    setEmail(
                      event.target.value,
                    )
                  }
                  autoComplete="email"
                  required
                />
              </label>

              <button
                type="submit"
                className="primary-button"
                disabled={loading}
              >
                {loading
                  ? 'Enviando...'
                  : 'Enviar instruções'}
              </button>

              <button
                type="button"
                className="text-button"
                onClick={returnToLogin}
                disabled={loading}
              >
                Voltar para o login
              </button>
            </form>
          ) : (
            <form
              onSubmit={handleLogin}
              className="login-form"
              autoComplete="off"
            >
              <label>
                E-mail

                <input
                  type="email"
                  value={email}
                  onChange={(event) =>
                    setEmail(
                      event.target.value,
                    )
                  }
                  autoComplete="email"
                  required
                />
              </label>

              <label>
                Senha

                <div className="password-field">
                  <input
                    type={
                      showPassword
                        ? 'text'
                        : 'password'
                    }
                    value={password}
                    readOnly={!passwordFieldReady}
                    onFocus={() =>
                      setPasswordFieldReady(true)
                    }
                    onChange={(event) =>
                      setPassword(
                        event.target.value,
                      )
                    }
                    autoComplete="off"
                    name="sparks-login-password"
                    required
                  />

                  <PasswordVisibilityButton
                    visible={showPassword}
                    onToggle={() =>
                      setShowPassword(
                        (current) =>
                          !current,
                      )
                    }
                  />
                </div>
              </label>

              <button
                type="submit"
                className="primary-button"
                disabled={loading}
              >
                {loading
                  ? 'Entrando...'
                  : 'Entrar'}
              </button>

              <button
                type="button"
                className="text-button"
                onClick={openForgotPassword}
                disabled={loading}
              >
                Esqueci minha senha
              </button>
            </form>
          )}

          {message && (
            <p
              className={`message message-${messageType}`}
              role={
                messageType === 'error'
                  ? 'alert'
                  : 'status'
              }
            >
              {message}
            </p>
          )}
        </section>
      </main>
    )
  }

  return (
    <main className={`platform-shell platform-theme-${platformTheme}`}>
      <header className="topbar">
        <div className="brand-area">
          <span className="brand-symbol" aria-hidden="true">
            <img src="/sparkoop-mascot.png" alt="" />
          </span>

          <div>
            <p className="brand-name">
              Plataforma SPARKs
            </p>

            <p className="brand-caption">
              Gestão integrada das
              organizações
            </p>
          </div>
        </div>

        <div className="topbar-organization-branding">
          <OrganizationBrandingLogo
            organizationId={selectedOrganization?.organization_id ?? null}
            organizationName={
              selectedOrganization?.trade_name ??
              selectedOrganization?.legal_name ??
              null
            }
          />
        </div>
        <div className="user-area">
          <button
            type="button"
            className="platform-theme-button"
            onClick={() => {
              const nextTheme = platformTheme === 'dark' ? 'light' : 'dark'
              setPlatformTheme(nextTheme)
              localStorage.setItem(PLATFORM_THEME_KEY, nextTheme)
            }}
            aria-label={
              platformTheme === 'dark'
                ? 'Ativar modo claro'
                : 'Ativar modo escuro'
            }
            title={
              platformTheme === 'dark'
                ? 'Modo claro'
                : 'Modo escuro'
            }
          >
            {platformTheme === 'dark' ? <SunIcon /> : <MoonIcon />}
          </button>
          {isPlatformSuperAdmin && (
            <button
            type="button"
            className="platform-admin-topbar-icon-button"
            onClick={handleOpenPlatformAdmin}
            disabled={loading}
            aria-label="Administração da Plataforma"
            title="Administração da Plataforma"
          >
            <span className="platform-admin-action-glyph" aria-hidden="true">
              <SettingsIcon />
            </span>
          </button>
          )}

          <button
            type="button"
            className="user-profile-summary user-profile-trigger"
            onClick={() => setUserProfileOpen(true)}
            aria-label="Abrir meu perfil"
            title="Meu perfil"
          >
            <div className="user-avatar" aria-hidden="true">
              {userAvatarUrl ? (
                <img src={userAvatarUrl} alt="" />
              ) : (
                (userDisplayName || session.user.email || 'U')
                  .slice(0, 2)
                  .toUpperCase()
              )}
            </div>

            <div className="user-identification">
              <strong>
                {userDisplayName || session.user.email}
              </strong>

              <div className="user-badges">
                {isPlatformSuperAdmin && (
                  <span className="badge badge-platform">
                    SUPER-ADMIN
                  </span>
                )}

                {selectedOrganization
                  ?.is_organization_admin && (
                  <span className="badge badge-organization">
                    Admin
                  </span>
                )}
              </div>
            </div>
          </button>



          <button
            type="button"
            className="logout-icon-button"
            onClick={handleLogout}
            disabled={loading}
            aria-label={loading ? 'Saindo da Plataforma' : 'Sair da Plataforma'}
            title={loading ? 'Saindo...' : 'Sair da Plataforma'}
          >
            <LogoutIcon />
          </button>
        </div>
      </header>

      <UserProfileDialog
        open={userProfileOpen}
        userId={session.user.id}
        email={session.user.email ?? ''}
        onClose={() => setUserProfileOpen(false)}
        onSaved={() => {
          setUserProfileRefresh((current) => current + 1)
        }}
      />

      <div className="platform-content">
        {platformAdminOpen && isPlatformSuperAdmin ? (
          <PlatformAdmin onBack={handleClosePlatformAdmin} />
        ) : selectedOrganization ? (
          <>
            <button
              type="button"
              className="back-button"
              onClick={
                handleReturnToOrganizations
              }
            >
              ← Voltar para organizações
            </button>

            <section className="page-heading">
              <div>
                <p className="eyebrow">
                  {
                    selectedOrganization.organization_code
                  }
                </p>

                <h1>
                  {selectedOrganization.trade_name ??
                    selectedOrganization.legal_name}
                </h1>

                <p className="supporting-text">
                  Acesse a administração organizacional ou selecione um dos módulos disponíveis.
                </p>
              </div>

              <div className="organization-summary">
                <span>
                  Nível:{' '}
                  {
                    getOrganizationLevelLabel(
                      selectedOrganization.organization_level,
                    )
                  }
                </span>

                <span>
                  Vínculo:{' '}
                  {
                    getOrganizationMembershipStatusLabel(
                      selectedOrganization,
                    )
                  }
                </span>
              </div>
            </section>
            {(selectedOrganization.is_organization_admin ||
              isPlatformSuperAdmin) && (
              <section className="platform-admin-entry organization-admin-entry">
                <button
                  type="button"
                  className="platform-admin-entry-icon-button"
                  onClick={handleOpenOrganizationAdmin}
                  aria-label="Acessar Administração da Organização"
                  title="Acessar Administração da Organização"
                >
                  <span className="platform-admin-action-glyph" aria-hidden="true">
                    <SettingsIcon />
                  </span>
                </button>

                <div className="platform-admin-entry-content">
                  <p className="eyebrow">
                    Escopo organizacional
                  </p>

                  <h2>Administração da Organização</h2>

                  <p>
                    Gerencie cadastro institucional, usuários,
                    vínculos, acessos, papéis, áreas, hierarquia,
                    domínios e configurações exclusivas desta
                    organização, sem entrar em um módulo.
                  </p>
                </div>
              </section>
            )}

            {message && (
              <p
                className={`message message-${messageType}`}
                role={
                  messageType === 'error'
                    ? 'alert'
                    : 'status'
                }
              >
                {message}
              </p>
            )}

            {loadingOrganizationNetwork ? (
              <div className="state-card">
                <p>Carregando visão consolidada da rede organizacional...</p>
              </div>
            ) : organizationNetwork.length > 0 ? (
              <section className="network-dashboard" aria-label="Painel consolidado da rede organizacional">
                <div className="network-dashboard-heading">
                  <div>
                    <p className="eyebrow">Visão consolidada</p>
                    <h2>Desempenho da organização e de sua rede</h2>
                    <p>Acompanhamento do Planejamento Estratégico das organizações acessíveis no nível atual.</p>
                  </div>
                </div>

                <div className="network-summary-grid">
                  {[
                    ['Organizações', networkSummary.organizationsTotal, 'Abrir organizações da rede'],
                    ['Projetos estratégicos', networkSummary.activeProjects, 'Abrir detalhamento por organização'],
                    ['Progresso médio', `${networkSummary.averageProgress.toLocaleString('pt-BR', { maximumFractionDigits: 1 })}%`, 'Comparar progresso da rede'],
                    ['Iniciativas', networkSummary.initiativesTotal, `${networkSummary.initiativesAttention} requerem atenção`],
                  ].map(([label, value, detail]) => (
                    <article
                      key={String(label)}
                      className="network-summary-card network-interactive-record"
                      role="button"
                      tabIndex={0}
                      onClick={() => document.getElementById('network-organization-details')?.scrollIntoView({ behavior: 'smooth', block: 'start' })}
                      onKeyDown={(event) => activateWithKeyboard(event, () => document.getElementById('network-organization-details')?.scrollIntoView({ behavior: 'smooth', block: 'start' }))}
                    >
                      <span>{label}</span><strong>{value}</strong><small>{detail}</small>
                    </article>
                  ))}
                </div>

                <div className="network-table-wrap" id="network-organization-details">
                  <table className="network-table">
                    <thead><tr><th>Organização</th><th>Nível</th><th>Módulo</th><th>Projetos</th><th>Progresso</th><th>Iniciativas</th><th>Atenção</th></tr></thead>
                    <tbody>
                      {organizationNetwork.map((row) => {
                        const accessibleOrganization = organizations.find((organization) => organization.organization_id === row.organization_id)
                        const openOrganization = () => {
                          if (accessibleOrganization) {
                            void handleSelectOrganization(accessibleOrganization)
                            return
                          }
                          showMessage('A organização está visível no consolidado, mas não há permissão para abrir seu contexto detalhado.', 'info')
                        }
                        return (
                          <tr
                            key={row.organization_id}
                            className="network-interactive-record"
                            role="button"
                            tabIndex={0}
                            aria-label={`Abrir contexto de ${row.organization_name}`}
                            onClick={openOrganization}
                            onKeyDown={(event) => activateWithKeyboard(event, openOrganization)}
                          >
                            <td><span style={{ paddingLeft: `${Math.min(Number(row.hierarchy_depth ?? 0), 5) * 14}px` }}><strong>{row.organization_name}</strong><small>{row.organization_code}</small></span></td>
                            <td>{getOrganizationLevelLabel(row.organization_level)}</td>
                            <td>{row.module_enabled ? 'Habilitado' : 'Não habilitado'}</td>
                            <td>{row.active_projects}</td>
                            <td>{Number(row.average_project_progress ?? 0).toLocaleString('pt-BR', { maximumFractionDigits: 1 })}%</td>
                            <td>{row.initiatives_total}</td>
                            <td>{row.initiatives_attention}</td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </div>
              </section>
            ) : null}

            {loadingModules ? (
              <div className="state-card">
                <p>
                  Carregando módulos...
                </p>
              </div>
            ) : modules.length === 0 ? (
              <div className="state-card">
                <h2>
                  Nenhum módulo disponível
                </h2>

                <p>
                  O usuário não possui acesso
                  ativo a módulos desta
                  organização.
                </p>
              </div>
            ) : (
              <section className="module-grid">
                {modules.map((module) => (
                  <article
                    className="module-card module-card-interactive"
                    key={module.organization_module_id}
                    role="button"
                    tabIndex={0}
                    aria-label={`Acessar ${module.module_name}`}
                    onClick={() => handleOpenModule(module)}
                    onKeyDown={(event) => activateWithKeyboard(event, () => handleOpenModule(module))}
                  >
                    <div className="module-icon">
                      <StrategyIcon />
                    </div>

                    <div className="module-card-content">
                      <p className="module-code">
                        {
                          module.module_short_name
                        }
                      </p>

                      <h2>
                        {module.module_name}
                      </h2>

                      <p className="module-description">
                        {module.module_description ??
                          'Módulo da Plataforma SPARKs.'}
                      </p>

                      <div className="module-meta">
                        <span>Perfil</span>

                        <strong>
                          {module.role_name}
                        </strong>
                      </div>
                    </div>


                  </article>
                ))}
              </section>
            )}
          </>
        ) : (
          <>
            <section className="page-heading">
              <div>
                <p className="eyebrow">
                  Portal da Plataforma
                </p>

                <h1>
                  Minhas organizações
                </h1>

                <p className="supporting-text">
                  Selecione a organização em
                  que deseja trabalhar.
                </p>
              </div>
            </section>

            {isPlatformSuperAdmin && (
              <section
                className="platform-admin-entry"
                role="button"
                tabIndex={0}
                onClick={handleOpenPlatformAdmin}
                onKeyDown={(event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault()
                    handleOpenPlatformAdmin()
                  }
                }}
                aria-label="Acessar Administração da Plataforma"
                title="Acessar Administração da Plataforma"
              >
                <span
                  className="platform-admin-entry-icon-button"
                  aria-hidden="true"
                >
                  <span className="platform-admin-action-glyph">
                    <SettingsIcon />
                  </span>
                </span>
                <div className="platform-admin-entry-content">
                  <p className="eyebrow">Acesso global</p>
                  <h2>Administração da Plataforma</h2>
                  <p>
                    Gerencie organizações, usuários, vínculos, módulos,
                    perfis globais, hierarquias e parâmetros mestres sem
                    precisar selecionar uma organização.
                  </p>
                </div>
              </section>
            )}

            {message && (
              <p
                className={`message message-${messageType}`}
                role={
                  messageType === 'error'
                    ? 'alert'
                    : 'status'
                }
              >
                {message}
              </p>
            )}

            {organizations.length === 0 ? (
              <div className="state-card">
                <h2>
                  Nenhuma organização
                  disponível
                </h2>

                <p>
                  O usuário está autenticado,
                  mas não possui vínculo ativo
                  com uma organização.
                </p>
              </div>
            ) : (
              <>
                <section className="primary-list-toolbar">
                  <div className="primary-list-search">
                    <SearchIcon />
                    <input type="search" value={organizationSearch} onChange={(event) => setOrganizationSearch(event.target.value)} placeholder="Pesquisar organizações" aria-label="Pesquisar organizações" />
                  </div>
                  <button type="button" className="primary-list-sort" onClick={() => setOrganizationSortDirection((current) => current === 'asc' ? 'desc' : 'asc')} title="Alterar ordenação alfabética">
                    {organizationSortDirection === 'asc' ? 'A → Z' : 'Z → A'}
                  </button>
                  <div className="primary-list-view-toggle" aria-label="Modo de visualização">
                    <button type="button" className={organizationViewMode === 'cards' ? 'active' : ''} onClick={() => setOrganizationViewMode('cards')} title="Visualizar em cards"><CardsViewIcon /></button>
                    <button type="button" className={organizationViewMode === 'grid' ? 'active' : ''} onClick={() => setOrganizationViewMode('grid')} title="Visualizar em linhas"><RowsViewIcon /></button>
                  <button
                    type="button"
                    className={organizationViewMode === 'hierarchy' ? 'active' : ''}
                    onClick={() => setOrganizationViewMode('hierarchy')}
                    aria-label="Visualizar organizações por hierarquia"
                    title="Hierarquia"
                  >
                    <HierarchyIcon />
                  </button>
                  </div>
                </section>
                {organizationViewMode === 'hierarchy' ? (
                  <section className="organization-hierarchy-view" aria-label="Hierarquia das organizações">
                    {hierarchicalVisibleOrganizations.map((organization) => {
                      const canonicalNode = organizationHierarchy.find(
                        (node) =>
                          node.organization_id ===
                          organization.organization_id,
                      )
                      const depth = Math.max(
                        0,
                        Number(
                          canonicalNode?.hierarchy_depth ??
                            organization.hierarchy_depth ??
                            0,
                        ),
                      )
                      const accessType = isHierarchicalReadOnlyAccess(organization) ? 'Hierárquico' : 'Direto'
                      return (
                        <article
                          key={organization.organization_id}
                          className="organization-hierarchy-row"
                          style={{ marginLeft: `${Math.min(depth, 6) * 28}px` }}
                          role="button"
                          tabIndex={0}
                          onClick={() => void handleSelectOrganization(organization)}
                          onKeyDown={(event) => activateWithKeyboard(event, () => void handleSelectOrganization(organization))}
                        >
                          <span className="organization-hierarchy-branch" aria-hidden="true">{depth > 0 ? '└─' : '●'}</span>
                          <div className="organization-hierarchy-main">
                            <strong>{organization.trade_name ?? organization.legal_name}</strong>
                            <small>{organization.organization_code}</small>
                          </div>
                          <span>{getOrganizationLevelLabel(organization.organization_level)}</span>
                          <span>Tipo de acesso: {accessType}</span>
                          <span>Status do vínculo: {getOrganizationMembershipStatusLabel(organization)}</span>
                          <span>Perfil: {getOrganizationProfileLabel(organization)}</span>
                          <ArrowRightIcon />
                        </article>
                      )
                    })}
                  </section>
                ) : organizationViewMode === 'cards' ? (
              <section className="organization-grid">
                {visibleOrganizations.map(
                  (organization) => (
                    <article
                      className="organization-card"
                      key={
                        organization.organization_id
                      }
                      role="button"
                      tabIndex={0}
                      aria-label={`Abrir ${organization.trade_name ?? organization.legal_name}`}
                      onClick={() => void handleSelectOrganization(organization)}
                      onKeyDown={(event) =>
                        activateWithKeyboard(event, () =>
                          void handleSelectOrganization(organization),
                        )
                      }
                    >
                      <div className="organization-card-header">
                        <div>
                          <p className="organization-code">
                            {
                              organization.organization_code
                            }
                          </p>

                          <h2>
                            {organization.trade_name ??
                              organization.legal_name}
                          </h2>
                        </div>

                        <div className="organization-access-badges">
                          {organization.is_organization_admin && (
                            <span className="badge badge-organization">
                              ADMIN
                            </span>
                          )}

                          {isHierarchicalReadOnlyAccess(organization) && (
                            <span className="badge badge-hierarchical">
                              VISUALIZAÇÃO
                            </span>
                          )}
                        </div>
                      </div>

                      <div
                        className="organization-card-branding"
                        aria-label={`Identidade visual de ${organization.trade_name ?? organization.legal_name}`}
                      >
                        <OrganizationBrandingLogo
                          organizationId={organization.organization_id}
                          organizationName={
                            organization.trade_name ??
                            organization.legal_name
                          }
                        />
                      </div>

                      <dl>
                        <div>
                          <dt>Nível</dt>

                          <dd>
                            {
                              getOrganizationLevelLabel(
                                organization.organization_level,
                              )
                            }
                          </dd>
                        </div>

                                                <div>
                          <dt>Acesso</dt>

                          <dd>
                            {
                              isHierarchicalReadOnlyAccess(organization) ? 'Hierárquico' : 'Direto'
                            }
                          </dd>
                        </div>
                      </dl>


                    </article>
                  ),
                )}
              </section>
                ) : (
                  <section className="organization-table-card">
                    <table className="organization-table">
                      <thead><tr><th onClick={() => setOrganizationSortDirection((current) => current === 'asc' ? 'desc' : 'asc')}>Organização</th><th>Código</th><th>Nível</th><th>Tipo de acesso</th><th>Status do vínculo</th><th>Perfil</th><th>Ações</th></tr></thead>
                      <tbody>{visibleOrganizations.map((organization) => (
                        <tr
                          key={organization.organization_id}
                          className="interactive-record-row"
                          role="button"
                          tabIndex={0}
                          aria-label={`Abrir ${organization.trade_name ?? organization.legal_name}`}
                          onClick={() => void handleSelectOrganization(organization)}
                          onKeyDown={(event) =>
                            activateWithKeyboard(event, () =>
                              void handleSelectOrganization(organization),
                            )
                          }
                        >
                          <td><strong>{organization.trade_name ?? organization.legal_name}</strong></td>
                          <td>{organization.organization_code}</td>
                          <td>{getOrganizationLevelLabel(organization.organization_level)}</td>
                          <td>{isHierarchicalReadOnlyAccess(organization) ? 'Hierárquico' : 'Direto'}</td>
                          <td>{getOrganizationMembershipStatusLabel(organization)}</td>
                          <td>{getOrganizationProfileLabel(organization)}</td>
                          <td><button type="button" title="Acessar organização" onClick={(event) => { event.stopPropagation(); void handleSelectOrganization(organization) }}>→</button></td>
                        </tr>
                      ))}</tbody>
                    </table>
                  </section>
                )}
              </>
            )}
          </>
        )}
      </div>
      <footer className="platform-footer">
        <strong>Plataforma SPARKs</strong>
        <span>© SPARKOOP — Todos os direitos reservados</span>
      </footer>    </main>
  )
}

export default App
