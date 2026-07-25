import { useEffect, useState } from 'react'
import type { FormEvent } from 'react'
import type { AuthChangeEvent, Session } from '@supabase/supabase-js'
import { supabase } from './lib/supabase'
import './App.css'

const LAST_SUCCESSFUL_EMAIL_KEY = 'skpe:last-successful-email'

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
  const [session, setSession] = useState<Session | null>(null)

  const [email, setEmail] = useState(() => {
    return localStorage.getItem(LAST_SUCCESSFUL_EMAIL_KEY) ?? ''
  })

  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)

  const [organizations, setOrganizations] = useState<Organization[]>([])

  const [message, setMessage] = useState('')
  const [messageType, setMessageType] =
    useState<MessageType>('info')

  const [loading, setLoading] = useState(true)

  const [forgotPasswordMode, setForgotPasswordMode] =
    useState(false)

  const [passwordRecoveryMode, setPasswordRecoveryMode] =
    useState(false)

  const [newPassword, setNewPassword] = useState('')
  const [confirmNewPassword, setConfirmNewPassword] = useState('')

  const [showNewPassword, setShowNewPassword] = useState(false)
  const [showConfirmNewPassword, setShowConfirmNewPassword] =
    useState(false)

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
      const { data, error } = await supabase.auth.getSession()

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
      },
    )

    return () => {
      mounted = false
      subscription.unsubscribe()
    }
  }, [])

  useEffect(() => {
    let mounted = true

    const loadOrganizations = async () => {
      if (!session || passwordRecoveryMode) {
        setOrganizations([])
        return
      }

      setLoading(true)
      clearMessage()

      const { data, error } = await supabase.rpc(
        'get_my_organizations',
      )

      if (!mounted) {
        return
      }

      if (error) {
        showMessage(
          `Erro ao carregar organizações: ${error.message}`,
          'error',
        )

        setOrganizations([])
      } else {
        setOrganizations((data ?? []) as Organization[])
      }

      setLoading(false)
    }

    void loadOrganizations()

    return () => {
      mounted = false
    }
  }, [session, passwordRecoveryMode])

  const handleLogin = async (
    event: FormEvent<HTMLFormElement>,
  ) => {
    event.preventDefault()

    setLoading(true)
    clearMessage()

    const normalizedEmail = email.trim().toLowerCase()

    const { error } = await supabase.auth.signInWithPassword({
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

    const { error } = await supabase.auth.signOut()

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
    setLoading(false)
  }

  const handlePasswordResetRequest = async (
    event: FormEvent<HTMLFormElement>,
  ) => {
    event.preventDefault()

    setLoading(true)
    clearMessage()

    const normalizedEmail = email.trim().toLowerCase()

    const { error } = await supabase.auth.resetPasswordForEmail(
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

    const { error } = await supabase.auth.updateUser({
      password: newPassword,
    })

    if (error) {
      showMessage(
        `Não foi possível atualizar a senha: ${error.message}`,
        'error',
      )

      setLoading(false)
      return
    }

    const { error: signOutError } = await supabase.auth.signOut()

    if (signOutError) {
      console.error(
        'Falha ao encerrar a sessão após alterar a senha:',
        signOutError,
      )
    }

    setPasswordRecoveryMode(false)
    setForgotPasswordMode(false)

    setNewPassword('')
    setConfirmNewPassword('')

    setShowNewPassword(false)
    setShowConfirmNewPassword(false)

    setSession(null)

    showMessage(
      'Senha atualizada com sucesso. Entre novamente com a nova senha.',
      'success',
    )

    setLoading(false)
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

  if (loading && !session && !forgotPasswordMode) {
    return (
      <main className="app-shell">
        <section className="panel login-panel">
          <p className="loading-text">Carregando...</p>
        </section>
      </main>
    )
  }

  if (passwordRecoveryMode) {
    return (
      <main className="app-shell">
        <section className="panel login-panel">
          <p className="eyebrow">SK-PE SaaS</p>

          <h1>Definir nova senha</h1>

          <p className="supporting-text">
            Informe e confirme a nova senha da sua conta.
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
                    showNewPassword ? 'text' : 'password'
                  }
                  value={newPassword}
                  onChange={(event) =>
                    setNewPassword(event.target.value)
                  }
                  autoComplete="new-password"
                  minLength={8}
                  required
                />

                <PasswordVisibilityButton
                  visible={showNewPassword}
                  onToggle={() =>
                    setShowNewPassword((current) => !current)
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
                  value={confirmNewPassword}
                  onChange={(event) =>
                    setConfirmNewPassword(event.target.value)
                  }
                  autoComplete="new-password"
                  minLength={8}
                  required
                />

                <PasswordVisibilityButton
                  visible={showConfirmNewPassword}
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
                messageType === 'error' ? 'alert' : 'status'
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
          <p className="eyebrow">SK-PE SaaS</p>

          <h1>
            {forgotPasswordMode
              ? 'Recuperar acesso'
              : 'Gestão da Jornada Estratégica'}
          </h1>

          <p className="supporting-text">
            {forgotPasswordMode
              ? 'Informe seu e-mail para receber as instruções de recuperação.'
              : 'Entre com seu usuário para acessar o sistema.'}
          </p>

          {forgotPasswordMode ? (
            <form
              onSubmit={handlePasswordResetRequest}
              className="login-form"
            >
              <label>
                E-mail

                <input
                  type="email"
                  value={email}
                  onChange={(event) =>
                    setEmail(event.target.value)
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
                    setEmail(event.target.value)
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
                      showPassword ? 'text' : 'password'
                    }
                    value={password}
                    onChange={(event) =>
                      setPassword(event.target.value)
                    }
                    autoComplete="current-password"
                    required
                  />

                  <PasswordVisibilityButton
                    visible={showPassword}
                    onToggle={() =>
                      setShowPassword((current) => !current)
                    }
                    label="senha"
                  />
                </div>
              </label>

              <button
                type="submit"
                className="primary-button"
                disabled={loading}
              >
                {loading ? 'Entrando...' : 'Entrar'}
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
                messageType === 'error' ? 'alert' : 'status'
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
    <main className="app-shell">
      <section className="panel">
        <header className="page-header">
          <div>
            <p className="eyebrow">SK-PE SaaS</p>

            <h1>Minhas organizações</h1>

            <p className="supporting-text">
              {session.user.email}
            </p>
          </div>

          <button
            type="button"
            className="secondary-button"
            onClick={handleLogout}
            disabled={loading}
          >
            {loading ? 'Saindo...' : 'Sair'}
          </button>
        </header>

        {message && (
          <p
            className={`message message-${messageType}`}
            role={
              messageType === 'error' ? 'alert' : 'status'
            }
          >
            {message}
          </p>
        )}

        {organizations.length === 0 ? (
          <div className="empty-state">
            <h2>Nenhuma organização disponível</h2>

            <p>
              O usuário está autenticado, mas não possui
              vínculo ativo com uma organização.
            </p>
          </div>
        ) : (
          <div className="organization-grid">
            {organizations.map((organization) => (
              <article
                className="organization-card"
                key={organization.organization_id}
              >
                <p className="organization-code">
                  {organization.organization_code}
                </p>

                <h2>
                  {organization.trade_name ??
                    organization.legal_name}
                </h2>

                <dl>
                  <div>
                    <dt>Nível</dt>
                    <dd>
                      {organization.organization_level}
                    </dd>
                  </div>

                  <div>
                    <dt>Vínculo</dt>
                    <dd>
                      {organization.membership_status}
                    </dd>
                  </div>

                  <div>
                    <dt>Perfil</dt>
                    <dd>
                      {organization.is_organization_admin
                        ? 'Administrador'
                        : 'Participante'}
                    </dd>
                  </div>
                </dl>
              </article>
            ))}
          </div>
        )}
      </section>
    </main>
  )
}

export default App