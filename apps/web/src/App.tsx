import { useEffect, useState } from 'react'
import type { FormEvent } from 'react'
import type { Session } from '@supabase/supabase-js'
import { supabase } from './lib/supabase'
import './App.css'

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
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [organizations, setOrganizations] = useState<Organization[]>([])
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadInitialSession = async () => {
      const { data, error } = await supabase.auth.getSession()

      if (error) {
        setMessage(`Erro ao verificar sessão: ${error.message}`)
      }

      setSession(data.session)
      setLoading(false)
    }

    void loadInitialSession()

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, currentSession) => {
      setSession(currentSession)
    })

    return () => {
      subscription.unsubscribe()
    }
  }, [])

  useEffect(() => {
    const loadOrganizations = async () => {
      if (!session) {
        setOrganizations([])
        return
      }

      setLoading(true)
      setMessage('')

      const { data, error } = await supabase.rpc('get_my_organizations')

      if (error) {
        setMessage(`Erro ao carregar organizações: ${error.message}`)
        setOrganizations([])
      } else {
        setOrganizations((data ?? []) as Organization[])
      }

      setLoading(false)
    }

    void loadOrganizations()
  }, [session])

  const handleLogin = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setLoading(true)
    setMessage('')

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      setMessage(`Não foi possível entrar: ${error.message}`)
    }

    setLoading(false)
  }

  const handleLogout = async () => {
    setLoading(true)
    setMessage('')

    const { error } = await supabase.auth.signOut()

    if (error) {
      setMessage(`Não foi possível sair: ${error.message}`)
    }

    setLoading(false)
  }

  if (loading && !session) {
    return (
      <main className="app-shell">
        <section className="panel">
          <p>Carregando...</p>
        </section>
      </main>
    )
  }

  if (!session) {
    return (
      <main className="app-shell">
        <section className="panel login-panel">
          <p className="eyebrow">SK-PE SaaS</p>
          <h1>Gestão da Jornada Estratégica</h1>
          <p className="supporting-text">
            Entre com o usuário criado no Supabase Auth.
          </p>

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
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                autoComplete="current-password"
                required
              />
            </label>

            <button type="submit" disabled={loading}>
              {loading ? 'Entrando...' : 'Entrar'}
            </button>
          </form>

          {message && <p className="message">{message}</p>}
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

          <button type="button" className="secondary-button" onClick={handleLogout}>
            Sair
          </button>
        </header>

        {message && <p className="message">{message}</p>}

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