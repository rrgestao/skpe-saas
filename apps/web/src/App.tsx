import { useEffect, useState } from 'react'
import type { FormEvent } from 'react'
import type { AuthChangeEvent, Session } from '@supabase/supabase-js'
import { supabase } from './lib/supabase'
import './App.css'

const LAST_SUCCESSFUL_EMAIL_KEY = 'skpe:last-successful-email'

type Organization = {
  organization_id: string
  organization_code: string
  legal_name: string
  trade_name: string | null
  organization_level: string
  membership_status: string
  is_organization_admin: boolean
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
  const [messageType, setMessageType] = useState<'info' | 'success' | 'error'>(
    'info',
  )
  const [loading, setLoading] = useState(true)

  const [forgotPasswordMode, setForgotPasswordMode] = useState(false)
  const [passwordRecoveryMode, setPasswordRecoveryMode] = useState(false)

  const [newPassword, setNewPassword] = useState('')
  const [confirmNewPassword, setConfirmNewPassword] = useState('')
  const [showNewPassword, setShowNewPassword] = useState(false)

  const showMessage = (
    text: string,
    type: 'info' | 'success' | 'error' = 'info',
  ) => {
    setMessage(text)
    setMessageType(type)
  }

  useEffect(() => {
    const loadInitialSession = async () => {
      const { data, error } = await supabase.auth.getSession()

      if (error) {
        showMessage(`Erro ao verificar sessão: ${error.message}`, 'error')
      }

      setSession(data.session)
      setLoading(false)
    }

    void loadInitialSession()

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(
      (event: AuthChangeEvent, currentSession) => {
        setSession(currentSession)

        if (event === 'PASSWORD_RECOVERY') {
          setPasswordRecoveryMode(true)
          setForgotPasswordMode(false)
          setPassword('')
          showMessage(
            'Defina uma nova senha para concluir a recuperação da conta.',
            'info',
          )
        }
      },
    )

    return () => {
      subscription.unsubscribe()
    }
  }, [])

  useEffect(() => {
    const loadOrganizations = async () => {
      if (!session || passwordRecoveryMode) {
        setOrganizations([])
        return
      }

      setLoading(true)
      setMessage('')

      const { data, error } = await supabase.rpc('get_my_organizations')

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
  }, [session, passwordRecoveryMode])

  const handleLogin = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setLoading(true)
    setMessage('')

    const normalizedEmail = email.trim().toLowerCase()

    const { error } = await supabase.auth.signInWithPassword({
      email: normalizedEmail,
      password,
    })

    if (error) {
      showMessage(`Não foi possível entrar: ${error.message}`, 'error')
      setLoading(false)
      return
    }

    localStorage.setItem(LAST_SUCCESSFUL_EMAIL_KEY, normalizedEmail)
    setEmail(normalizedEmail)
    setPassword('')
    setShowPassword(false)
    setLoading(false)
  }

  const handleLogout = async () => {
    setLoading(true)
    setMessage('')

    const { error } = await supabase.auth.signOut()

    if (error) {
      showMessage(`Não foi possível sair: ${error.message}`, 'error')
    }

    setPassword('')
    setOrganizations([])
    setLoading(false)
  }

  const handlePasswordResetRequest = async (
    event: FormEvent<HTMLFormElement>,
  ) => {
    event.preventDefault()
    setLoading(true)
    setMessage('')

    const normalizedEmail = email.trim().toLowerCase()

    const { error } = await supabase.auth.resetPasswordForEmail(
      normalizedEmail,
      {
        redirectTo: window.location.origin,
      },
    )

    if (error) {
      console.error('Password reset request failed:', error)
    }

    showMessage(
      'Caso exista uma conta vinculada a este e-mail, enviaremos as instruções de recuperação.',
      'success',
    )

    setEmail(normalizedEmail)
    setLoading(false)
  }

  const handleNewPassword = async (
    event: FormEvent<HTMLFormElement>,
  ) => {
    event.preventDefault()
    setMessage('')

    if (newPassword.length < 8) {
      showMessage('A nova senha deve ter pelo menos 8 caracteres.', 'error')
      return
    }

    if (newPassword !== confirmNewPassword) {
      showMessage('As senhas informadas não são iguais.', 'error')
      return
    }

    setLoading(true)

    const { error } = await supabase.auth.updateUser({
      password: newPassword,
    })

    if (error) {
      showMessage(`Não foi possível atualizar a senha: ${error.message}`, 'error')
      setLoading(false)
      return
    }

    await supabase.auth.signOut()

    setPasswordRecoveryMode(false)
    setNewPassword('')
    setConfirmNewPassword('')
    setShowNewPassword(false)
    setSession(null)

    showMessage(
      'Senha atualizada com sucesso. Entre novamente com a nova senha.',
      'success',
    )

    setLoading(false)
  }

  if (loading && !session && !forgotPasswordMode) {
    return (
      <main className="app-shell">
        <section className="panel login-panel">
          <p>Carregando...</p>
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

          <form onSubmit={handleNewPassword} className="login-form">
            <label>
              Nova senha

              <div className="password-field">
                <input
                  type={showNewPassword ? 'text' : 'password'}
                  value={newPassword}
                  onChange={(event) => setNewPassword(event.target.value)}
                  autoComplete="new-password"
                  minLength={8}
                  required
                />

                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowNewPassword((current) => !current)}
                  aria-label={
                    showNewPassword
                      ? 'Ocultar nova senha'
                      : 'Mostrar nova senha'
                  }
                >
                  {showNewPassword ? 'Ocultar' : 'Mostrar'}
                </button>
              </div>
            </label>

            <label>
              Confirmar nova senha

              <input
                type={showNewPassword ? 'text' : 'password'}
                value={confirmNewPassword}
                onChange={(event) =>
                  setConfirmNewPassword(event.target.value)
                }
                autoComplete="new-password"
                minLength={8}
                required
              />
            </label>

            <button type="submit" disabled={loading}>
              {loading ? 'Atualizando...' : 'Atualizar senha'}
            </button>
          </form>

          {message && (
            <p className={`message message-${messageType}`}>{message}</p>
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
                  onChange={(event) => setEmail(event.target.value)}
                  autoComplete="email"
                  required
                />
              </label>

              <button type="submit" disabled={loading}>
                {loading ? 'Enviando...' : 'Enviar instruções'}
              </button>

              <button
                type="button"
                className="text-button"
                onClick={() => {
                  setForgotPasswordMode(false)
                  setMessage('')
                }}
              >
                Voltar para o login
              </button>
            </form>
          ) : (
            <form onSubmit={handleLogin} className="login-form">
              <label>
                E-mail
                <input
                  type="email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  autoComplete="email"
                  required
                />
              </label>

              <label>
                Senha

                <div className="password-field">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(event) => setPassword(event.target.value)}
                    autoComplete="current-password"
                    required
                  />

                  <button
                    type="button"
                    className="password-toggle"
                    onClick={() => setShowPassword((current) => !current)}
                    aria-label={
                      showPassword ? 'Ocultar senha' : 'Mostrar senha'
                    }
                    aria-pressed={showPassword}
                  >
                    {showPassword ? 'Ocultar' : 'Mostrar'}
                  </button>
                </div>
              </label>

              <button type="submit" disabled={loading}>
                {loading ? 'Entrando...' : 'Entrar'}
              </button>

              <button
                type="button"
                className="text-button"
                onClick={() => {
                  setForgotPasswordMode(true)
                  setPassword('')
                  setMessage('')
                }}
              >
                Esqueci minha senha
              </button>
            </form>
          )}

          {message && (
            <p className={`message message-${messageType}`}>{message}</p>
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
            <p className="supporting-text">{session.user.email}</p>
          </div>

          <button
            type="button"
            className="secondary-button"
            onClick={handleLogout}
            disabled={loading}
          >
            Sair
          </button>
        </header>

        {message && (
          <p className={`message message-${messageType}`}>{message}</p>
        )}

        {organizations.length === 0 ? (
          <div className="empty-state">
            <h2>Nenhuma organização disponível</h2>
            <p>
              O usuário está autenticado, mas não possui vínculo ativo com uma
              organização.
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

                <h2>{organization.trade_name ?? organization.legal_name}</h2>

                <dl>
                  <div>
                    <dt>Nível</dt>
                    <dd>{organization.organization_level}</dd>
                  </div>

                  <div>
                    <dt>Vínculo</dt>
                    <dd>{organization.membership_status}</dd>
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