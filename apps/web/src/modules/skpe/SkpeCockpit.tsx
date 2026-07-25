import { useState } from 'react'

import './SkpeCockpit.css'

type CockpitSection =
  | 'overview'
  | 'journey'
  | 'governance'
  | 'administration'

type SkpeCockpitProps = {
  organizationName: string
  organizationCode: string
  userRole: string
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
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
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
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
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
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
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
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
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
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
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
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
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
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
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
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
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

function AdministrationSection({
  userRole,
}: {
  userRole: string
}) {
  return (
    <>
      <section className="skpe-page-heading">
        <div>
          <p className="skpe-eyebrow">
            Administração do módulo
          </p>

          <h1>Configurações do SK-PE</h1>

          <p>
            Gestão dos participantes, papéis,
            permissões e parâmetros do módulo de
            Planejamento Estratégico.
          </p>
        </div>
      </section>

      <section className="skpe-administration-grid">
        <article className="skpe-administration-card">
          <h2>
            Seu perfil no módulo
          </h2>

          <strong>{userRole}</strong>

          <p>
            As funcionalidades disponíveis serão
            controladas pelas permissões
            associadas a esse perfil.
          </p>
        </article>

        <article className="skpe-administration-card">
          <h2>
            Usuários e perfis
          </h2>

          <p>
            Associação de usuários aos papéis de
            Administrador, Gestor, Editor,
            Aprovador ou Leitor.
          </p>

          <span>
            Interface administrativa em
            desenvolvimento
          </span>
        </article>

        <article className="skpe-administration-card">
          <h2>
            Parâmetros metodológicos
          </h2>

          <p>
            Configuração da jornada,
            nomenclaturas, etapas, aprovações e
            controles aplicáveis à organização.
          </p>

          <span>Em desenvolvimento</span>
        </article>
      </section>
    </>
  )
}

export function SkpeCockpit({
  organizationName,
  organizationCode,
  userRole,
  onReturnToModules,
}: SkpeCockpitProps) {
  const [activeSection, setActiveSection] =
    useState<CockpitSection>('overview')

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

          <strong>{userRole}</strong>

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
            userRole={userRole}
          />
        )}
      </main>
    </div>
  )
}