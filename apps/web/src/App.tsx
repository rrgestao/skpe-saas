import { useEffect, useMemo, useState } from 'react'
import type { FormEvent, KeyboardEvent } from 'react'
import type {
  AuthChangeEvent,
  Session,
} from '@supabase/supabase-js'

import { supabase } from './lib/supabase'
import { SkpeCockpit } from './modules/skpe/SkpeCockpit'
import { PlatformAdmin } from './modules/platform-admin/PlatformAdmin'

import './App.css'

const LAST_SUCCESSFUL_EMAIL_KEY =
  'skpe:last-successful-email'

type MessageType = 'info' | 'success' | 'error'

type Organization = {
  organization_id: string
  organization_code: string
  legal_name: string
  trade_name: string | null
  organization_level: string
  membership_status: string
  is_organization_admin: boolean
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

function getMembershipStatusLabel(value: string) {
  return MEMBERSHIP_STATUS_LABELS[value] ?? value
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
  const [session, setSession] =
    useState<Session | null>(null)

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

  const [organizations, setOrganizations] =
    useState<Organization[]>([])

  const [platformAdminOpen, setPlatformAdminOpen] =
    useState(false)

  const [organizationViewMode, setOrganizationViewMode] =
    useState<'cards' | 'grid'>('cards')

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
          setOrganizations([])
          setModules([])
          setPlatformRoles([])
          setSelectedOrganization(null)
          setOpenedModule(null)
          setPlatformAdminOpen(false)
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
          setPlatformRoles([])
          return
        }

        setLoading(true)
        clearMessage()

        const [
          organizationsResponse,
          platformRolesResponse,
        ] = await Promise.all([
          supabase.rpc('get_my_organizations'),
          supabase.rpc('get_my_platform_roles'),
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
  ) => {
    setPlatformAdminOpen(false)
    setSelectedOrganization(organization)
    setOpenedModule(null)
    setModules([])
    setOrganizationNetwork([])
    setLoadingModules(true)
    setLoadingOrganizationNetwork(true)
    clearMessage()

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
    setSelectedOrganization(null)
    setOpenedModule(null)
    setModules([])
    setOrganizationNetwork([])
    setLoadingOrganizationNetwork(false)
    clearMessage()
  }

  const handleOpenPlatformAdmin = () => {
    setPlatformAdminOpen(true)
    setSelectedOrganization(null)
    setOpenedModule(null)
    setModules([])
    clearMessage()
  }

  const handleClosePlatformAdmin = () => {
    setPlatformAdminOpen(false)
    clearMessage()
  }

  const handleReturnToModules = () => {
    setOpenedModule(null)
    clearMessage()
  }

  const handleOpenModule = (
    module: PlatformModule,
  ) => {
    if (module.module_code === 'SK-PE') {
      setOpenedModule(module)
      clearMessage()
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
    setOrganizations([])
    setModules([])
    setPlatformRoles([])
    setSelectedOrganization(null)
    setOpenedModule(null)
    setPlatformAdminOpen(false)
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
    clearMessage()
  }

  const returnToLogin = () => {
    setForgotPasswordMode(false)
    setPassword('')
    setShowPassword(false)
    clearMessage()
  }

  const isPlatformSuperAdmin =
    platformRoles.some(
      (role) =>
        role.role_code === 'super_admin',
    )

  if (openedModule && selectedOrganization) {
    return (
      <SkpeCockpit
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
          <p className="eyebrow">
            Plataforma SPARKs
          </p>

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
          <p className="eyebrow">
            Plataforma SPARKs
          </p>

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
                    onChange={(event) =>
                      setPassword(
                        event.target.value,
                      )
                    }
                    autoComplete="current-password"
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
    <main className="platform-shell">
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

        <div className="user-area">
          <div className="user-identification">
            <strong>
              {session.user.email}
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
                  ADMIN DA ORGANIZAÇÃO
                </span>
              )}
            </div>
          </div>

          {isPlatformSuperAdmin && (
            <button
              type="button"
              className="platform-admin-topbar-button"
              onClick={handleOpenPlatformAdmin}
              disabled={loading}
            >
              Administração da Plataforma
            </button>
          )}

          <button
            type="button"
            className="secondary-button"
            onClick={handleLogout}
            disabled={loading}
          >
            {loading ? 'Saindo...' : 'Sair'}
          </button>
        </div>
      </header>

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
                  Selecione um dos módulos
                  disponíveis para esta
                  organização.
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
                    getMembershipStatusLabel(
                      selectedOrganization.membership_status,
                    )
                  }
                </span>
              </div>
            </section>

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

                    <button
                      type="button"
                      className="module-access-button"
                      onClick={(event) => {
                        event.stopPropagation()
                        handleOpenModule(module)
                      }}
                    >
                      Acessar módulo
                      <ArrowRightIcon />
                    </button>
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
              <section className="platform-admin-entry">
                <div className="platform-admin-entry-icon" aria-hidden="true">⚙</div>
                <div className="platform-admin-entry-content">
                  <p className="eyebrow">Acesso global</p>
                  <h2>Administração da Plataforma</h2>
                  <p>
                    Gerencie organizações, usuários, vínculos, módulos,
                    perfis globais, hierarquias e parâmetros mestres sem
                    precisar selecionar uma organização.
                  </p>
                </div>
                <button
                  type="button"
                  className="platform-admin-entry-button"
                  onClick={handleOpenPlatformAdmin}
                >
                  Acessar administração
                  <ArrowRightIcon />
                </button>
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
                    <button type="button" className={organizationViewMode === 'cards' ? 'active' : ''} onClick={() => setOrganizationViewMode('cards')} title="Visualizar em cards">▦</button>
                    <button type="button" className={organizationViewMode === 'grid' ? 'active' : ''} onClick={() => setOrganizationViewMode('grid')} title="Visualizar em linhas">☷</button>
                  </div>
                </section>
                {organizationViewMode === 'cards' ? (
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

                        {organization.is_organization_admin && (
                          <span className="badge badge-organization">
                            ADMIN
                          </span>
                        )}
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
                          <dt>Vínculo</dt>

                          <dd>
                            {
                              getMembershipStatusLabel(
                                organization.membership_status,
                              )
                            }
                          </dd>
                        </div>
                      </dl>

                      <button
                        type="button"
                        className="organization-access-button"
                        onClick={(event) => {
                          event.stopPropagation()
                          void handleSelectOrganization(organization)
                        }}
                      >
                        Acessar organização
                        <ArrowRightIcon />
                      </button>
                    </article>
                  ),
                )}
              </section>
                ) : (
                  <section className="organization-table-card">
                    <table className="organization-table">
                      <thead><tr><th onClick={() => setOrganizationSortDirection((current) => current === 'asc' ? 'desc' : 'asc')}>Organização</th><th>Código</th><th>Nível</th><th>Vínculo</th><th>Perfil</th><th>Ações</th></tr></thead>
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
                          <td>{getMembershipStatusLabel(organization.membership_status)}</td>
                          <td>{organization.is_organization_admin ? 'Administrador' : 'Participante'}</td>
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
    </main>
  )
}

export default App