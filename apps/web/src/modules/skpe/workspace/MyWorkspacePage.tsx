import type { KeyboardEvent } from 'react'

import {
  WORKSPACE_DASHBOARDS,
  type SkpeWorkspaceCapability,
  type WorkspaceDashboardAvailability,
  type WorkspaceDashboardDefinition,
  type WorkspaceRequiredContext,
} from './workspaceDashboards'

type WorkspaceProjectSummary = {
  code: string
  name: string
  statusLabel: string
  progress: number
  currentPhaseCode: string
  strategicHorizon: string
  reviewCycle: string
}

type WorkspaceAvailableContext = {
  organization: boolean
  project: boolean
  formulation: boolean
  cycle: boolean
  user: boolean
}

type WorkspaceCapabilities = Partial<
  Record<SkpeWorkspaceCapability, boolean>
>

type WorkspaceNavigationSection =
  | 'journey'
  | 'initiatives'
  | 'governance'
  | 'artifacts'

type MyWorkspacePageProps = {
  organizationName: string
  organizationCode: string
  project: WorkspaceProjectSummary | null
  availableContext: WorkspaceAvailableContext
  capabilities: WorkspaceCapabilities
  isReadOnly: boolean
  canStartProject: boolean
  startingProject: boolean
  onStartProject: () => void
  onNavigate: (section: WorkspaceNavigationSection) => void
}

type ResolvedDashboard = {
  definition: WorkspaceDashboardDefinition
  availability: WorkspaceDashboardAvailability
  reason: string | null
}

const dashboardNavigation: Partial<
  Record<WorkspaceDashboardDefinition['id'], WorkspaceNavigationSection>
> = {
  portfolio: 'initiatives',
  governance: 'governance',
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

function resolveDashboard(
  definition: WorkspaceDashboardDefinition,
  availableContext: WorkspaceAvailableContext,
  capabilities: WorkspaceCapabilities,
): ResolvedDashboard {
  const missingContext = definition.requiredContext.find(
    (context) => !availableContext[context],
  )

  if (missingContext) {
    return {
      definition,
      availability: 'requires-context',
      reason: getMissingContextMessage(missingContext),
    }
  }

  if (
    definition.requiredCapability &&
    !capabilities[definition.requiredCapability]
  ) {
    return {
      definition,
      availability: 'forbidden',
      reason: 'Você não possui permissão para acessar este painel.',
    }
  }

  if (definition.defaultAvailability !== 'enabled') {
    return {
      definition,
      availability: definition.defaultAvailability,
      reason: getAvailabilityMessage(definition.defaultAvailability),
    }
  }

  return {
    definition,
    availability: 'enabled',
    reason: null,
  }
}

function getMissingContextMessage(context: WorkspaceRequiredContext) {
  const messages: Record<WorkspaceRequiredContext, string> = {
    organization: 'Selecione uma organização para acessar este painel.',
    project: 'Este painel depende de um projeto estratégico ativo.',
    formulation: 'Este painel depende de uma Formulação selecionada.',
    cycle: 'Este painel depende de um ciclo de monitoramento selecionado.',
    user: 'Este painel depende de um usuário autenticado.',
  }

  return messages[context]
}

function getAvailabilityMessage(
  availability: WorkspaceDashboardAvailability,
) {
  const messages: Record<WorkspaceDashboardAvailability, string> = {
    enabled: '',
    disabled: 'Este painel está temporariamente indisponível.',
    'coming-soon': 'Este painel será disponibilizado em uma próxima entrega.',
    'requires-context': 'Este painel depende de contexto adicional.',
    forbidden: 'Você não possui permissão para acessar este painel.',
  }

  return messages[availability]
}

function getAvailabilityLabel(
  availability: WorkspaceDashboardAvailability,
) {
  const labels: Record<WorkspaceDashboardAvailability, string> = {
    enabled: 'Disponível',
    disabled: 'Indisponível',
    'coming-soon': 'Em breve',
    'requires-context': 'Requer contexto',
    forbidden: 'Sem permissão',
  }

  return labels[availability]
}

export function MyWorkspacePage({
  organizationName,
  organizationCode,
  project,
  availableContext,
  capabilities,
  isReadOnly,
  canStartProject,
  startingProject,
  onStartProject,
  onNavigate,
}: MyWorkspacePageProps) {
  const dashboards = WORKSPACE_DASHBOARDS.map((definition) =>
    resolveDashboard(definition, availableContext, capabilities),
  )

  return (
    <>
      <section className="skpe-page-heading">
        <div>
          <p className="skpe-eyebrow">Meu Espaço de Trabalho</p>
          <h1>Visão integrada do Planejamento Estratégico</h1>
          <p>
            Acompanhe o contexto atual da <strong>{organizationName}</strong>{' '}
            e acesse as áreas disponíveis conforme suas responsabilidades e
            permissões.
          </p>
        </div>

        <div className="skpe-heading-status-group">
          <div
            className={`skpe-status-chip ${
              isReadOnly ? 'skpe-status-chip-neutral' : ''
            }`}
          >
            <span className="skpe-status-dot" />
            {isReadOnly ? 'Somente leitura' : 'Acesso operacional'}
          </div>
        </div>
      </section>

      {project ? (
        <section
          className="skpe-kpi-grid"
          aria-label="Síntese do projeto estratégico"
        >
          <article
            className="skpe-kpi-card skpe-clickable-card"
            role="button"
            tabIndex={0}
            onClick={() => onNavigate('journey')}
            onKeyDown={(event) =>
              activateWithKeyboard(event, () => onNavigate('journey'))
            }
          >
            <span>Avanço geral estimado</span>
            <strong>
              {project.progress.toLocaleString('pt-BR', {
                maximumFractionDigits: 1,
              })}
              %
            </strong>
            <small>Abrir Jornada Estratégica</small>
          </article>

          <article
            className="skpe-kpi-card skpe-clickable-card"
            role="button"
            tabIndex={0}
            onClick={() => onNavigate('journey')}
            onKeyDown={(event) =>
              activateWithKeyboard(event, () => onNavigate('journey'))
            }
          >
            <span>Projeto estratégico</span>
            <strong>{project.code}</strong>
            <small>{project.name}</small>
          </article>

          <article
            className="skpe-kpi-card skpe-clickable-card"
            role="button"
            tabIndex={0}
            onClick={() => onNavigate('journey')}
            onKeyDown={(event) =>
              activateWithKeyboard(event, () => onNavigate('journey'))
            }
          >
            <span>Etapa atual</span>
            <strong>{project.currentPhaseCode}</strong>
            <small>{project.statusLabel}</small>
          </article>

          <article
            className="skpe-kpi-card skpe-clickable-card"
            role="button"
            tabIndex={0}
            onClick={() => onNavigate('governance')}
            onKeyDown={(event) =>
              activateWithKeyboard(event, () => onNavigate('governance'))
            }
          >
            <span>Horizonte estratégico</span>
            <strong>{project.strategicHorizon}</strong>
            <small>{project.reviewCycle}</small>
          </article>
        </section>
      ) : (
        <section
          className="skpe-onboarding-panel"
          aria-label="Projeto estratégico não disponível"
        >
          <div className="skpe-onboarding-content">
            <p className="skpe-card-code">Contexto da organização</p>
            <h2>Jornada ainda não iniciada</h2>
            <p>
              Não existe um projeto estratégico ativo para esta organização.
              Nenhum dado de outra organização será utilizado como
              preenchimento alternativo.
            </p>
            <small>
              Organização: {organizationCode} · contexto local e exclusivo.
            </small>

            {canStartProject && (
              <button
                type="button"
                className="skpe-primary-button"
                disabled={startingProject}
                onClick={onStartProject}
              >
                {startingProject
                  ? 'Iniciando jornada...'
                  : 'Iniciar Jornada Estratégica'}
              </button>
            )}
          </div>
        </section>
      )}

      <section aria-labelledby="workspace-panels-title">
        <div className="skpe-card-heading">
          <div>
            <p className="skpe-card-code">Acessos contextuais</p>
            <h2 id="workspace-panels-title">Painéis disponíveis</h2>
          </div>
        </div>

        <div className="skpe-dashboard-grid">
          {dashboards.map(({ definition, availability, reason }) => {
            const destination = dashboardNavigation[definition.id]
            const canOpen =
              availability === 'enabled' &&
              definition.supportsDrillDown &&
              Boolean(destination)

            return (
              <article
                key={definition.id}
                className={`skpe-dashboard-card ${
                  canOpen ? 'skpe-clickable-card' : ''
                }`}
                role={canOpen ? 'button' : undefined}
                tabIndex={canOpen ? 0 : undefined}
                aria-disabled={!canOpen}
                onClick={
                  canOpen && destination
                    ? () => onNavigate(destination)
                    : undefined
                }
                onKeyDown={
                  canOpen && destination
                    ? (event) =>
                        activateWithKeyboard(event, () =>
                          onNavigate(destination),
                        )
                    : undefined
                }
              >
                <div className="skpe-card-heading">
                  <div>
                    <p className="skpe-card-code">
                      {getAvailabilityLabel(availability)}
                    </p>
                    <h3>{definition.label}</h3>
                  </div>
                </div>

                <p className="skpe-card-description">
                  {definition.description}
                </p>

                <small>
                  {reason ??
                    (canOpen
                      ? 'Abrir painel'
                      : 'Painel sem destino operacional nesta entrega.')}
                </small>
              </article>
            )
          })}
        </div>
      </section>
    </>
  )
}
