import {
  useEffect,
  useMemo,
  useState,
} from 'react'

import { supabase } from '../../lib/supabase'

import './SkpeCockpit.css'

type CockpitSection =
  | 'overview'
  | 'journey'
  | 'governance'
  | 'administration'

type SkpeCockpitProps = {
  organizationId: string
  organizationName: string
  organizationCode: string
  userRoleCode: string
  userRoleName: string
  isOrganizationAdmin: boolean
  isPlatformSuperAdmin: boolean
  onReturnToModules: () => void
}

type MacroPhaseStatus =
  | 'completed'
  | 'in_progress'
  | 'not_started'

type MacroPhase = {
  code: string
  name: string
  description: string
  status: MacroPhaseStatus
  progress: number
  current?: boolean
}

type UserAccessRow = {
  membership_id: string
  user_id: string
  user_email: string
  user_display_name: string | null
  user_active: boolean

  membership_status: string
  is_organization_admin: boolean
  job_title: string | null
  membership_valid_from: string | null
  membership_valid_until: string | null

  organization_module_id: string | null
  module_id: string | null
  module_code: string | null
  module_name: string | null
  module_short_name: string | null

  user_module_role_id: string | null
  module_role_id: string | null
  role_code: string | null
  role_name: string | null
  module_role_status: string | null
  module_role_valid_from: string | null
  module_role_valid_until: string | null
}

type UserModuleAccess = {
  organizationModuleId: string | null
  moduleId: string | null
  moduleCode: string
  moduleName: string
  moduleShortName: string
  userModuleRoleId: string | null
  moduleRoleId: string | null
  roleCode: string
  roleName: string
  status: string
  validFrom: string | null
  validUntil: string | null
}

type OrganizationUser = {
  membershipId: string
  userId: string
  email: string
  displayName: string | null
  userActive: boolean

  membershipStatus: string
  isOrganizationAdmin: boolean
  jobTitle: string | null
  membershipValidFrom: string | null
  membershipValidUntil: string | null

  modules: UserModuleAccess[]
}

const macroPhases: MacroPhase[] = [
  {
    code: 'PEM-01',
    name: 'Diagnóstico e Entendimento Estratégico',
    description:
      'Consolidação das evidências, contexto, riscos, oportunidades e temas críticos para decisão.',
    status: 'completed',
    progress: 100,
  },
  {
    code: 'PEM-02',
    name: 'Formulação Estratégica',
    description:
      'Construção e validação do direcionamento estratégico, objetivos, escolhas e modelo estratégico futuro.',
    status: 'in_progress',
    progress: 45,
    current: true,
  },
  {
    code: 'PEM-03',
    name: 'Desdobramento Estratégico',
    description:
      'Conversão da estratégia em objetivos, indicadores, metas, iniciativas e responsabilidades.',
    status: 'not_started',
    progress: 0,
  },
  {
    code: 'PEM-04',
    name: 'Implementação e Mobilização',
    description:
      'Estruturação da execução, comunicação, engajamento e desenvolvimento das capacidades necessárias.',
    status: 'not_started',
    progress: 0,
  },
  {
    code: 'PEM-05',
    name: 'Monitoramento e Aprendizado',
    description:
      'Acompanhamento dos resultados, análise crítica, aprendizado e atualização contínua da estratégia.',
    status: 'not_started',
    progress: 0,
  },
]

function ArrowLeftIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M19 12H5M11 18l-6-6 6-6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function DashboardIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect
        x="4"
        y="4"
        width="6"
        height="6"
        rx="1"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <rect
        x="14"
        y="4"
        width="6"
        height="6"
        rx="1"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <rect
        x="4"
        y="14"
        width="6"
        height="6"
        rx="1"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <rect
        x="14"
        y="14"
        width="6"
        height="6"
        rx="1"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />
    </svg>
  )
}

function JourneyIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle
        cx="6"
        cy="6"
        r="2"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <circle
        cx="18"
        cy="12"
        r="2"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <circle
        cx="6"
        cy="18"
        r="2"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <path
        d="M8 6h4a4 4 0 014 4M16 14a4 4 0 01-4 4H8"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  )
}

function GovernanceIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M12 3l8 4v5c0 4.5-3.2 7.5-8 9-4.8-1.5-8-4.5-8-9V7l8-4z"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinejoin="round"
      />

      <path
        d="M9 12l2 2 4-4"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function AdministrationIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle
        cx="12"
        cy="8"
        r="3"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <path
        d="M5 20c.5-4 3-6 7-6s6.5 2 7 6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  )
}

function CheckIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M5 12l4 4L19 6"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function ClockIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle
        cx="12"
        cy="12"
        r="8"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <path
        d="M12 8v5l3 2"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  )
}

function LockIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <rect
        x="5"
        y="10"
        width="14"
        height="10"
        rx="2"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <path
        d="M8 10V7a4 4 0 018 0v3"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  )
}

function SearchIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle
        cx="10.5"
        cy="10.5"
        r="6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      />

      <path
        d="M15 15l5 5"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
    </svg>
  )
}

function RefreshIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M20 7v5h-5"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />

      <path
        d="M18.2 12A7 7 0 106 18"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
    </svg>
  )
}

function UserIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle
        cx="12"
        cy="8"
        r="3"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />

      <path
        d="M5 20c.5-4 3-6 7-6s6.5 2 7 6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  )
}

function getStatusLabel(
  status: MacroPhaseStatus,
) {
  if (status === 'completed') {
    return 'Concluída'
  }

  if (status === 'in_progress') {
    return 'Em andamento'
  }

  return 'Não iniciada'
}

function getMembershipStatusLabel(
  status: string,
) {
  if (status === 'active') {
    return 'Ativo'
  }

  if (status === 'invited') {
    return 'Convidado'
  }

  if (status === 'suspended') {
    return 'Suspenso'
  }

  if (status === 'revoked') {
    return 'Revogado'
  }

  return status
}

function formatDate(
  value: string | null,
) {
  if (!value) {
    return 'Sem prazo'
  }

  const date = new Date(value)

  if (Number.isNaN(date.getTime())) {
    return value
  }

  return new Intl.DateTimeFormat(
    'pt-BR',
    {
      dateStyle: 'short',
    },
  ).format(date)
}

function groupUserAccessRows(
  rows: UserAccessRow[],
): OrganizationUser[] {
  const users = new Map<
    string,
    OrganizationUser
  >()

  for (const row of rows) {
    const existingUser = users.get(row.user_id)

    const moduleAccess: UserModuleAccess | null =
      row.module_code
        ? {
            organizationModuleId:
              row.organization_module_id,
            moduleId: row.module_id,
            moduleCode: row.module_code,
            moduleName:
              row.module_name ??
              row.module_code,
            moduleShortName:
              row.module_short_name ??
              row.module_code,
            userModuleRoleId:
              row.user_module_role_id,
            moduleRoleId:
              row.module_role_id,
            roleCode:
              row.role_code ??
              'sem_papel',
            roleName:
              row.role_name ??
              'Sem perfil atribuído',
            status:
              row.module_role_status ??
              'inactive',
            validFrom:
              row.module_role_valid_from,
            validUntil:
              row.module_role_valid_until,
          }
        : null

    if (!existingUser) {
      users.set(row.user_id, {
        membershipId: row.membership_id,
        userId: row.user_id,
        email: row.user_email,
        displayName: row.user_display_name,
        userActive: row.user_active,
        membershipStatus:
          row.membership_status,
        isOrganizationAdmin:
          row.is_organization_admin,
        jobTitle: row.job_title,
        membershipValidFrom:
          row.membership_valid_from,
        membershipValidUntil:
          row.membership_valid_until,
        modules: moduleAccess
          ? [moduleAccess]
          : [],
      })

      continue
    }

    if (
      moduleAccess &&
      !existingUser.modules.some(
        (module) =>
          module.userModuleRoleId ===
          moduleAccess.userModuleRoleId,
      )
    ) {
      existingUser.modules.push(moduleAccess)
    }
  }

  return Array.from(users.values()).sort(
    (firstUser, secondUser) => {
      if (
        firstUser.isOrganizationAdmin !==
        secondUser.isOrganizationAdmin
      ) {
        return firstUser.isOrganizationAdmin
          ? -1
          : 1
      }

      const firstName =
        firstUser.displayName ??
        firstUser.email

      const secondName =
        secondUser.displayName ??
        secondUser.email

      return firstName.localeCompare(
        secondName,
        'pt-BR',
      )
    },
  )
}

function OverviewSection() {
  return (
    <>
      <section className="skpe-page-heading">
        <div>
          <p className="skpe-eyebrow">
            Visão executiva
          </p>

          <h1>Cockpit Estratégico</h1>

          <p>
            Acompanhamento integrado da jornada
            de planejamento estratégico da
            organização.
          </p>
        </div>

        <div className="skpe-status-chip">
          <span className="skpe-status-dot" />
          Macrofase 2 em andamento
        </div>
      </section>

      <section
        className="skpe-kpi-grid"
        aria-label="Indicadores executivos"
      >
        <article className="skpe-kpi-card">
          <span>
            Avanço geral estimado
          </span>

          <strong>29%</strong>

          <small>
            Jornada estratégica completa
          </small>
        </article>

        <article className="skpe-kpi-card">
          <span>
            Macrofases concluídas
          </span>

          <strong>1 de 5</strong>

          <small>
            Diagnóstico concluído
          </small>
        </article>

        <article className="skpe-kpi-card">
          <span>Macrofase atual</span>

          <strong>PEM-02</strong>

          <small>
            Formulação Estratégica
          </small>
        </article>

        <article className="skpe-kpi-card">
          <span>
            Situação de governança
          </span>

          <strong>Ativa</strong>

          <small>
            Validações e decisões controladas
          </small>
        </article>
      </section>

      <section className="skpe-dashboard-grid">
        <article className="skpe-dashboard-card skpe-current-phase-card">
          <div className="skpe-card-heading">
            <div>
              <p className="skpe-card-code">
                PEM-02
              </p>

              <h2>
                Formulação Estratégica
              </h2>
            </div>

            <span className="skpe-pill skpe-pill-progress">
              Em andamento
            </span>
          </div>

          <p className="skpe-card-description">
            Estruturação do modelo estratégico
            futuro, revisão dos direcionadores,
            formulação das escolhas e preparação
            para o desdobramento estratégico.
          </p>

          <div className="skpe-progress-block">
            <div>
              <span>
                Progresso estimado
              </span>

              <strong>45%</strong>
            </div>

            <div className="skpe-progress-track">
              <span
                style={{ width: '45%' }}
              />
            </div>
          </div>

          <div className="skpe-current-items">
            <div>
              <CheckIcon />

              <span>
                Termo de Abertura e Mandato
              </span>
            </div>

            <div>
              <CheckIcon />

              <span>
                Confirmação do Modelo
                Estratégico Futuro
              </span>
            </div>

            <div>
              <ClockIcon />

              <span>
                Revisão e Formulação dos
                Direcionadores
              </span>
            </div>
          </div>
        </article>

        <article className="skpe-dashboard-card">
          <div className="skpe-card-heading">
            <div>
              <p className="skpe-card-code">
                Próxima decisão
              </p>

              <h2>
                Validação executiva
              </h2>
            </div>
          </div>

          <p className="skpe-card-description">
            Consolidar as formulações
            estratégicas já construídas antes de
            avançar para o próximo produto
            metodológico.
          </p>

          <div className="skpe-decision-box">
            <strong>
              Ponto de controle
            </strong>

            <span>
              Confirmar coerência,
              rastreabilidade e aderência ao
              mandato estratégico.
            </span>
          </div>
        </article>

        <article className="skpe-dashboard-card">
          <div className="skpe-card-heading">
            <div>
              <p className="skpe-card-code">
                Governança
              </p>

              <h2>Controles ativos</h2>
            </div>
          </div>

          <ul className="skpe-clean-list">
            <li>
              Rastreabilidade das decisões
            </li>

            <li>Validação por etapa</li>

            <li>
              Registro das evidências
            </li>

            <li>
              Controle das versões
            </li>

            <li>
              Integração com gestão documental
            </li>
          </ul>
        </article>
      </section>
    </>
  )
}

function JourneySection() {
  return (
    <>
      <section className="skpe-page-heading">
        <div>
          <p className="skpe-eyebrow">
            Metodologia SK-PE
          </p>

          <h1>Jornada Estratégica</h1>

          <p>
            Visão integrada das macrofases,
            progresso e conexão entre as entregas
            do planejamento estratégico.
          </p>
        </div>
      </section>

      <section className="skpe-journey-list">
        {macroPhases.map((phase) => (
          <article
            key={phase.code}
            className={[
              'skpe-phase-card',
              phase.current
                ? 'skpe-phase-current'
                : '',
            ]
              .filter(Boolean)
              .join(' ')}
          >
            <div
              className={`skpe-phase-marker skpe-phase-${phase.status}`}
            >
              {phase.status ===
              'completed' ? (
                <CheckIcon />
              ) : phase.status ===
                'in_progress' ? (
                <ClockIcon />
              ) : (
                <LockIcon />
              )}
            </div>

            <div className="skpe-phase-content">
              <div className="skpe-phase-heading">
                <div>
                  <p>{phase.code}</p>

                  <h2>{phase.name}</h2>
                </div>

                <span
                  className={`skpe-pill skpe-pill-${phase.status}`}
                >
                  {getStatusLabel(
                    phase.status,
                  )}
                </span>
              </div>

              <p>{phase.description}</p>

              <div className="skpe-phase-progress">
                <div className="skpe-progress-track">
                  <span
                    style={{
                      width: `${phase.progress}%`,
                    }}
                  />
                </div>

                <strong>
                  {phase.progress}%
                </strong>
              </div>
            </div>
          </article>
        ))}
      </section>
    </>
  )
}

function GovernanceSection() {
  return (
    <>
      <section className="skpe-page-heading">
        <div>
          <p className="skpe-eyebrow">
            Governança estratégica
          </p>

          <h1>
            Controles e Validações
          </h1>

          <p>
            Estrutura de decisão, validação,
            evidências e rastreabilidade da
            jornada estratégica.
          </p>
        </div>
      </section>

      <section className="skpe-governance-grid">
        <article className="skpe-governance-card">
          <span className="skpe-governance-number">
            01
          </span>

          <h2>Mandato estratégico</h2>

          <p>
            Define o propósito, os limites, os
            responsáveis e as condições de
            desenvolvimento do planejamento.
          </p>

          <strong>Concluído</strong>
        </article>

        <article className="skpe-governance-card">
          <span className="skpe-governance-number">
            02
          </span>

          <h2>
            Decisões estratégicas
          </h2>

          <p>
            Registra as decisões, responsáveis,
            fundamentos, impactos e conexões com
            os artefatos.
          </p>

          <strong>
            Em implantação
          </strong>
        </article>

        <article className="skpe-governance-card">
          <span className="skpe-governance-number">
            03
          </span>

          <h2>Validações</h2>

          <p>
            Controla aprovações, ressalvas,
            pendências e aceite dos produtos
            desenvolvidos.
          </p>

          <strong>Ativo</strong>
        </article>

        <article className="skpe-governance-card">
          <span className="skpe-governance-number">
            04
          </span>

          <h2>Evidências</h2>

          <p>
            Mantém a ligação entre documentos,
            análises, entrevistas, oficinas,
            decisões e entregas.
          </p>

          <strong>
            Integração prevista com SK-DOC
          </strong>
        </article>
      </section>
    </>
  )
}

type AdministrationSectionProps = {
  organizationId: string
  userRoleName: string
  canManageUsers: boolean
}

function AdministrationSection({
  organizationId,
  userRoleName,
  canManageUsers,
}: AdministrationSectionProps) {
  const [rows, setRows] =
    useState<UserAccessRow[]>([])

  const [loading, setLoading] =
    useState(false)

  const [errorMessage, setErrorMessage] =
    useState('')

  const [searchTerm, setSearchTerm] =
    useState('')

  const [
    membershipStatusFilter,
    setMembershipStatusFilter,
  ] = useState('all')

  const [
    moduleFilter,
    setModuleFilter,
  ] = useState('all')

  const [
    selectedUserId,
    setSelectedUserId,
  ] = useState<string | null>(null)

  const users = useMemo(
    () => groupUserAccessRows(rows),
    [rows],
  )

  const availableModules = useMemo(() => {
    const modules = new Map<
      string,
      string
    >()

    for (const user of users) {
      for (const module of user.modules) {
        modules.set(
          module.moduleCode,
          module.moduleName,
        )
      }
    }

    return Array.from(
      modules.entries(),
    ).sort((firstModule, secondModule) =>
      firstModule[1].localeCompare(
        secondModule[1],
        'pt-BR',
      ),
    )
  }, [users])

  const filteredUsers = useMemo(() => {
    const normalizedSearch =
      searchTerm.trim().toLowerCase()

    return users.filter((user) => {
      const matchesSearch =
        normalizedSearch.length === 0 ||
        user.email
          .toLowerCase()
          .includes(normalizedSearch) ||
        (user.displayName ?? '')
          .toLowerCase()
          .includes(normalizedSearch) ||
        (user.jobTitle ?? '')
          .toLowerCase()
          .includes(normalizedSearch)

      const matchesStatus =
        membershipStatusFilter === 'all' ||
        user.membershipStatus ===
          membershipStatusFilter

      const matchesModule =
        moduleFilter === 'all' ||
        user.modules.some(
          (module) =>
            module.moduleCode ===
            moduleFilter,
        )

      return (
        matchesSearch &&
        matchesStatus &&
        matchesModule
      )
    })
  }, [
    users,
    searchTerm,
    membershipStatusFilter,
    moduleFilter,
  ])

  const selectedUser = useMemo(
    () =>
      users.find(
        (user) =>
          user.userId === selectedUserId,
      ) ?? null,
    [users, selectedUserId],
  )

  const activeUsersCount = users.filter(
    (user) =>
      user.membershipStatus === 'active' &&
      user.userActive,
  ).length

  const organizationAdminsCount =
    users.filter(
      (user) =>
        user.isOrganizationAdmin &&
        user.membershipStatus === 'active',
    ).length

  const usersWithModulesCount =
    users.filter(
      (user) => user.modules.length > 0,
    ).length

  const loadUsers = async () => {
    if (!canManageUsers) {
      setRows([])
      setErrorMessage('')
      return
    }

    setLoading(true)
    setErrorMessage('')

    const { data, error } = await supabase.rpc(
      'get_organization_user_access',
      {
        target_organization_id:
          organizationId,
      },
    )

    if (error) {
      console.error(
        'Erro ao carregar usuários e acessos:',
        error,
      )

      setRows([])
      setErrorMessage(
        `Não foi possível carregar os usuários: ${error.message}`,
      )
      setLoading(false)
      return
    }

    setRows((data ?? []) as UserAccessRow[])
    setLoading(false)
  }

  useEffect(() => {
    void loadUsers()
  }, [organizationId, canManageUsers])

  useEffect(() => {
    if (
      selectedUserId &&
      !users.some(
        (user) =>
          user.userId === selectedUserId,
      )
    ) {
      setSelectedUserId(null)
    }
  }, [users, selectedUserId])

  if (!canManageUsers) {
    return (
      <>
        <section className="skpe-page-heading">
          <div>
            <p className="skpe-eyebrow">
              Administração do módulo
            </p>

            <h1>
              Usuários e Acessos
            </h1>

            <p>
              Gestão dos participantes, papéis,
              permissões e acessos vinculados à
              organização.
            </p>
          </div>
        </section>

        <section className="skpe-access-denied-card">
          <LockIcon />

          <div>
            <h2>
              Acesso administrativo necessário
            </h2>

            <p>
              Seu perfil atual é{' '}
              <strong>{userRoleName}</strong>.
              A matriz completa de usuários e
              acessos está disponível somente
              para administradores autorizados.
            </p>
          </div>
        </section>
      </>
    )
  }

  return (
    <>
      <section className="skpe-page-heading skpe-administration-heading">
        <div>
          <p className="skpe-eyebrow">
            Administração da organização
          </p>

          <h1>Usuários e Acessos</h1>

          <p>
            Consulte os vínculos, módulos,
            perfis e situações de acesso dos
            usuários da organização.
          </p>
        </div>

        <button
          type="button"
          className="skpe-refresh-button"
          onClick={() => void loadUsers()}
          disabled={loading}
        >
          <RefreshIcon />

          {loading
            ? 'Atualizando...'
            : 'Atualizar dados'}
        </button>
      </section>

      <section className="skpe-admin-kpi-grid">
        <article className="skpe-admin-kpi-card">
          <span>
            Usuários vinculados
          </span>

          <strong>{users.length}</strong>

          <small>
            Total de vínculos encontrados
          </small>
        </article>

        <article className="skpe-admin-kpi-card">
          <span>Usuários ativos</span>

          <strong>
            {activeUsersCount}
          </strong>

          <small>
            Vínculo e cadastro ativos
          </small>
        </article>

        <article className="skpe-admin-kpi-card">
          <span>
            Administradores
          </span>

          <strong>
            {organizationAdminsCount}
          </strong>

          <small>
            Administradores da organização
          </small>
        </article>

        <article className="skpe-admin-kpi-card">
          <span>
            Com acesso a módulos
          </span>

          <strong>
            {usersWithModulesCount}
          </strong>

          <small>
            Usuários com ao menos um perfil
          </small>
        </article>
      </section>

      <section className="skpe-admin-toolbar">
        <div className="skpe-admin-search">
          <SearchIcon />

          <input
            type="search"
            value={searchTerm}
            onChange={(event) =>
              setSearchTerm(
                event.target.value,
              )
            }
            placeholder="Buscar por nome, e-mail ou função"
            aria-label="Buscar usuários"
          />
        </div>

        <label className="skpe-admin-filter">
          <span>Situação</span>

          <select
            value={membershipStatusFilter}
            onChange={(event) =>
              setMembershipStatusFilter(
                event.target.value,
              )
            }
          >
            <option value="all">
              Todas
            </option>

            <option value="active">
              Ativos
            </option>

            <option value="invited">
              Convidados
            </option>

            <option value="suspended">
              Suspensos
            </option>

            <option value="revoked">
              Revogados
            </option>
          </select>
        </label>

        <label className="skpe-admin-filter">
          <span>Módulo</span>

          <select
            value={moduleFilter}
            onChange={(event) =>
              setModuleFilter(
                event.target.value,
              )
            }
          >
            <option value="all">
              Todos
            </option>

            {availableModules.map(
              ([moduleCode, moduleName]) => (
                <option
                  key={moduleCode}
                  value={moduleCode}
                >
                  {moduleName}
                </option>
              ),
            )}
          </select>
        </label>
      </section>

      {errorMessage && (
        <div
          className="skpe-admin-message skpe-admin-message-error"
          role="alert"
        >
          {errorMessage}
        </div>
      )}

      {loading ? (
        <section className="skpe-admin-state-card">
          <p>
            Carregando usuários e acessos...
          </p>
        </section>
      ) : filteredUsers.length === 0 ? (
        <section className="skpe-admin-state-card">
          <h2>
            Nenhum usuário encontrado
          </h2>

          <p>
            Ajuste os filtros ou verifique se
            existem vínculos cadastrados para a
            organização.
          </p>
        </section>
      ) : (
        <section className="skpe-user-management-layout">
          <div className="skpe-user-table-card">
            <div className="skpe-user-table-header">
              <div>
                <h2>
                  Matriz de usuários
                </h2>

                <p>
                  {filteredUsers.length}{' '}
                  usuário
                  {filteredUsers.length === 1
                    ? ''
                    : 's'}{' '}
                  exibido
                  {filteredUsers.length === 1
                    ? ''
                    : 's'}
                </p>
              </div>
            </div>

            <div className="skpe-user-table-wrapper">
              <table className="skpe-user-table">
                <thead>
                  <tr>
                    <th>Usuário</th>
                    <th>Vínculo</th>
                    <th>Administração</th>
                    <th>Módulos e perfis</th>
                    <th />
                  </tr>
                </thead>

                <tbody>
                  {filteredUsers.map(
                    (user) => (
                      <tr
                        key={user.userId}
                        className={
                          selectedUserId ===
                          user.userId
                            ? 'skpe-user-row-selected'
                            : ''
                        }
                      >
                        <td>
                          <div className="skpe-user-identity">
                            <span className="skpe-user-avatar">
                              <UserIcon />
                            </span>

                            <div>
                              <strong>
                                {user.displayName ??
                                  user.email}
                              </strong>

                              <span>
                                {user.email}
                              </span>

                              {user.jobTitle && (
                                <small>
                                  {user.jobTitle}
                                </small>
                              )}
                            </div>
                          </div>
                        </td>

                        <td>
                          <span
                            className={`skpe-access-status skpe-access-status-${user.membershipStatus}`}
                          >
                            {getMembershipStatusLabel(
                              user.membershipStatus,
                            )}
                          </span>
                        </td>

                        <td>
                          {user.isOrganizationAdmin ? (
                            <span className="skpe-admin-badge">
                              ADMIN
                            </span>
                          ) : (
                            <span className="skpe-muted-label">
                              Participante
                            </span>
                          )}
                        </td>

                        <td>
                          <div className="skpe-module-role-list">
                            {user.modules.length ===
                            0 ? (
                              <span className="skpe-muted-label">
                                Sem módulo atribuído
                              </span>
                            ) : (
                              user.modules.map(
                                (module) => (
                                  <span
                                    key={
                                      module.userModuleRoleId ??
                                      `${user.userId}-${module.moduleCode}-${module.roleCode}`
                                    }
                                    className="skpe-module-role-chip"
                                  >
                                    <strong>
                                      {
                                        module.moduleShortName
                                      }
                                    </strong>

                                    <span>
                                      {
                                        module.roleName
                                      }
                                    </span>
                                  </span>
                                ),
                              )
                            )}
                          </div>
                        </td>

                        <td>
                          <button
                            type="button"
                            className="skpe-user-details-button"
                            onClick={() =>
                              setSelectedUserId(
                                user.userId,
                              )
                            }
                          >
                            Detalhes
                          </button>
                        </td>
                      </tr>
                    ),
                  )}
                </tbody>
              </table>
            </div>
          </div>

          <aside className="skpe-user-detail-card">
            {selectedUser ? (
              <>
                <div className="skpe-user-detail-heading">
                  <span className="skpe-user-detail-avatar">
                    <UserIcon />
                  </span>

                  <div>
                    <p>
                      Detalhes do usuário
                    </p>

                    <h2>
                      {selectedUser.displayName ??
                        selectedUser.email}
                    </h2>

                    <span>
                      {selectedUser.email}
                    </span>
                  </div>
                </div>

                <dl className="skpe-user-detail-list">
                  <div>
                    <dt>
                      Situação do vínculo
                    </dt>

                    <dd>
                      {getMembershipStatusLabel(
                        selectedUser.membershipStatus,
                      )}
                    </dd>
                  </div>

                  <div>
                    <dt>
                      Cadastro do usuário
                    </dt>

                    <dd>
                      {selectedUser.userActive
                        ? 'Ativo'
                        : 'Inativo'}
                    </dd>
                  </div>

                  <div>
                    <dt>
                      Administrador da organização
                    </dt>

                    <dd>
                      {selectedUser.isOrganizationAdmin
                        ? 'Sim'
                        : 'Não'}
                    </dd>
                  </div>

                  <div>
                    <dt>Função</dt>

                    <dd>
                      {selectedUser.jobTitle ??
                        'Não informada'}
                    </dd>
                  </div>

                  <div>
                    <dt>
                      Início do vínculo
                    </dt>

                    <dd>
                      {formatDate(
                        selectedUser.membershipValidFrom,
                      )}
                    </dd>
                  </div>

                  <div>
                    <dt>
                      Término do vínculo
                    </dt>

                    <dd>
                      {formatDate(
                        selectedUser.membershipValidUntil,
                      )}
                    </dd>
                  </div>
                </dl>

                <div className="skpe-user-detail-modules">
                  <h3>
                    Módulos e perfis
                  </h3>

                  {selectedUser.modules.length ===
                  0 ? (
                    <p>
                      Nenhum módulo atribuído.
                    </p>
                  ) : (
                    selectedUser.modules.map(
                      (module) => (
                        <article
                          key={
                            module.userModuleRoleId ??
                            `${selectedUser.userId}-${module.moduleCode}-${module.roleCode}`
                          }
                        >
                          <div>
                            <strong>
                              {module.moduleName}
                            </strong>

                            <span>
                              {module.moduleCode}
                            </span>
                          </div>

                          <dl>
                            <div>
                              <dt>Perfil</dt>

                              <dd>
                                {
                                  module.roleName
                                }
                              </dd>
                            </div>

                            <div>
                              <dt>Situação</dt>

                              <dd>
                                {getMembershipStatusLabel(
                                  module.status,
                                )}
                              </dd>
                            </div>

                            <div>
                              <dt>Validade</dt>

                              <dd>
                                {formatDate(
                                  module.validUntil,
                                )}
                              </dd>
                            </div>
                          </dl>
                        </article>
                      ),
                    )
                  )}
                </div>

                <div className="skpe-user-detail-notice">
                  Alterações de perfil, suspensão,
                  convite e recuperação de acesso
                  serão implementadas nas próximas
                  etapas com auditoria.
                </div>
              </>
            ) : (
              <div className="skpe-user-detail-empty">
                <UserIcon />

                <h2>
                  Selecione um usuário
                </h2>

                <p>
                  Clique em “Detalhes” para
                  consultar o vínculo, os módulos
                  e os perfis atribuídos.
                </p>
              </div>
            )}
          </aside>
        </section>
      )}
    </>
  )
}

export function SkpeCockpit({
  organizationId,
  organizationName,
  organizationCode,
  userRoleCode,
  userRoleName,
  isOrganizationAdmin,
  isPlatformSuperAdmin,
  onReturnToModules,
}: SkpeCockpitProps) {
  const [activeSection, setActiveSection] =
    useState<CockpitSection>('overview')

  const canManageUsers =
    isOrganizationAdmin ||
    userRoleCode === 'administrator'

  return (
    <div className="skpe-shell">
      <aside className="skpe-sidebar">
        <div className="skpe-sidebar-brand">
          <div className="skpe-sidebar-symbol">
            PE
          </div>

          <div>
            <strong>SK-PE</strong>

            <span>
              Planejamento Estratégico
            </span>
          </div>
        </div>

        <div className="skpe-organization-context">
          <span>Organização</span>

          <strong>
            {organizationName}
          </strong>

          <small>
            {organizationCode}
          </small>
        </div>

        <nav
          className="skpe-navigation"
          aria-label="Navegação do SK-PE"
        >
          <button
            type="button"
            className={
              activeSection === 'overview'
                ? 'skpe-nav-active'
                : ''
            }
            onClick={() =>
              setActiveSection('overview')
            }
          >
            <DashboardIcon />
            Visão Geral
          </button>

          <button
            type="button"
            className={
              activeSection === 'journey'
                ? 'skpe-nav-active'
                : ''
            }
            onClick={() =>
              setActiveSection('journey')
            }
          >
            <JourneyIcon />
            Jornada Estratégica
          </button>

          <button
            type="button"
            className={
              activeSection === 'governance'
                ? 'skpe-nav-active'
                : ''
            }
            onClick={() =>
              setActiveSection(
                'governance',
              )
            }
          >
            <GovernanceIcon />
            Governança
          </button>

          <button
            type="button"
            className={
              activeSection ===
              'administration'
                ? 'skpe-nav-active'
                : ''
            }
            onClick={() =>
              setActiveSection(
                'administration',
              )
            }
          >
            <AdministrationIcon />
            Administração
          </button>
        </nav>

        <div className="skpe-sidebar-footer">
          <span>Perfil</span>

          <strong>{userRoleName}</strong>

          {isPlatformSuperAdmin && (
            <small className="skpe-platform-role-label">
              SUPER-ADMIN da Plataforma
            </small>
          )}

          <button
            type="button"
            onClick={onReturnToModules}
          >
            <ArrowLeftIcon />
            Voltar aos módulos
          </button>
        </div>
      </aside>

      <main className="skpe-main">
        {activeSection ===
          'overview' && (
          <OverviewSection />
        )}

        {activeSection ===
          'journey' && (
          <JourneySection />
        )}

        {activeSection ===
          'governance' && (
          <GovernanceSection />
        )}

        {activeSection ===
          'administration' && (
          <AdministrationSection
            organizationId={
              organizationId
            }
            userRoleName={userRoleName}
            canManageUsers={
              canManageUsers
            }
          />
        )}
      </main>
    </div>
  )
}