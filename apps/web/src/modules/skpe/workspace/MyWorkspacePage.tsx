import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { MyPendingItemsPanel } from './MyPendingItemsPanel'
import {
  WORKSPACE_DASHBOARDS,
  isWorkspaceDashboardId,
  type SkpeWorkspaceCapability,
  type WorkspaceDashboardAvailability,
  type WorkspaceDashboardDefinition,
  type WorkspaceDashboardId,
  type WorkspaceRequiredContext,
} from './workspaceDashboards'

type WorkspaceProjectSummary = {
  id: string
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
  organizationId: string
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
  canOpen: boolean
  canBePrimary: boolean
}

type PrimaryPreferenceStatus =
  | 'loading'
  | 'absent'
  | 'valid'
  | 'invalid'
  | 'read-error'

type PreferenceFeedback = {
  type: 'success' | 'error'
  text: string
} | null

type PreferenceRow = {
  preference_value: unknown
}

const PRIMARY_DASHBOARD_KEY = 'workspace.primary_dashboard'
const MODULE_CODE = 'SK-PE'

const dashboardNavigation: Partial<
  Record<WorkspaceDashboardId, WorkspaceNavigationSection>
> = {
  portfolio: 'initiatives',
  governance: 'governance',
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
      canOpen: false,
      canBePrimary: false,
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
      canOpen: false,
      canBePrimary: false,
    }
  }

  if (definition.defaultAvailability !== 'enabled') {
    return {
      definition,
      availability: definition.defaultAvailability,
      reason: getAvailabilityMessage(definition.defaultAvailability),
      canOpen: false,
      canBePrimary: false,
    }
  }

  const destination = dashboardNavigation[definition.id]
  const canOpen =
    definition.supportsDrillDown &&
    (definition.section === 'overview' || Boolean(destination))

  return {
    definition,
    availability: 'enabled',
    reason: null,
    canOpen,
    canBePrimary: definition.eligibleAsPrimary && canOpen,
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

function getPreferenceDashboardId(value: unknown): unknown {
  if (
    typeof value !== 'object' ||
    value === null ||
    !('dashboard_id' in value)
  ) {
    return null
  }

  return value.dashboard_id
}


export function MyWorkspacePage({
  organizationId,
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
  const [persistedPrimaryId, setPersistedPrimaryId] =
    useState<WorkspaceDashboardId | null>(null)
  const [preferenceStatus, setPreferenceStatus] =
    useState<PrimaryPreferenceStatus>('loading')
  const [savingDashboardId, setSavingDashboardId] =
    useState<WorkspaceDashboardId | null>(null)
  const [removingPreference, setRemovingPreference] = useState(false)
  const [feedback, setFeedback] = useState<PreferenceFeedback>(null)

  const dashboards = useMemo(
    () =>
      WORKSPACE_DASHBOARDS.map((definition) =>
        resolveDashboard(definition, availableContext, capabilities),
      ),
    [availableContext, capabilities],
  )

  const eligibleDashboards = useMemo(
    () => dashboards.filter((dashboard) => dashboard.canBePrimary),
    [dashboards],
  )

  const persistedDashboardIsEligible =
    persistedPrimaryId !== null &&
    eligibleDashboards.some(
      ({ definition }) => definition.id === persistedPrimaryId,
    )

  const fallbackDashboardId = useMemo(() => {
    const fallback = eligibleDashboards
      .filter(
        ({ definition }) => definition.fallbackPriority !== null,
      )
      .sort(
        (first, second) =>
          (first.definition.fallbackPriority ?? Number.MAX_SAFE_INTEGER) -
          (second.definition.fallbackPriority ?? Number.MAX_SAFE_INTEGER),
      )[0]

    return fallback?.definition.id ?? null
  }, [eligibleDashboards])

  const effectivePrimaryId = persistedDashboardIsEligible
    ? persistedPrimaryId
    : fallbackDashboardId

  const effectivePrimaryDashboard = effectivePrimaryId
    ? WORKSPACE_DASHBOARDS.find(
        (dashboard) => dashboard.id === effectivePrimaryId,
      ) ?? null
    : null

  const orderedDashboards = useMemo(() => {
    if (!effectivePrimaryId) return dashboards

    return [...dashboards].sort((first, second) => {
      if (first.definition.id === effectivePrimaryId) return -1
      if (second.definition.id === effectivePrimaryId) return 1
      return 0
    })
  }, [dashboards, effectivePrimaryId])

  useEffect(() => {
    let active = true

    async function loadPrimaryPreference() {
      setPreferenceStatus('loading')
      setPersistedPrimaryId(null)
      setFeedback(null)

      const { data, error } = await supabase.rpc(
        'get_my_module_preference',
        {
          input_organization_id: organizationId,
          input_module_code: MODULE_CODE,
          input_preference_key: PRIMARY_DASHBOARD_KEY,
        },
      )

      if (!active) return

      if (error) {
        setPreferenceStatus('read-error')
        setFeedback({
          type: 'error',
          text: `Não foi possível carregar o Painel Principal: ${error.message}`,
        })
        return
      }

      const row = ((data ?? [])[0] ?? null) as PreferenceRow | null

      if (!row) {
        setPreferenceStatus('absent')
        return
      }

      const dashboardId = getPreferenceDashboardId(row.preference_value)

      if (!isWorkspaceDashboardId(dashboardId)) {
        setPreferenceStatus('invalid')
        return
      }

      setPersistedPrimaryId(dashboardId)
      setPreferenceStatus('valid')
    }

    void loadPrimaryPreference()

    return () => {
      active = false
    }
  }, [organizationId])

  useEffect(() => {
    if (
      preferenceStatus === 'valid' &&
      persistedPrimaryId &&
      !persistedDashboardIsEligible
    ) {
      setPreferenceStatus('invalid')
    }
  }, [
    persistedDashboardIsEligible,
    persistedPrimaryId,
    preferenceStatus,
  ])

  async function savePrimaryDashboard(
    dashboardId: WorkspaceDashboardId,
  ) {
    const dashboard = eligibleDashboards.find(
      ({ definition }) => definition.id === dashboardId,
    )

    if (!dashboard) {
      setFeedback({
        type: 'error',
        text: 'Este painel não está elegível como Painel Principal no contexto atual.',
      })
      return
    }

    setSavingDashboardId(dashboardId)
    setFeedback(null)

    const { error } = await supabase.rpc(
      'set_my_module_preference',
      {
        input_organization_id: organizationId,
        input_module_code: MODULE_CODE,
        input_preference_key: PRIMARY_DASHBOARD_KEY,
        input_preference_value: {
          dashboard_id: dashboardId,
          schema_version: 1,
        },
        change_reason:
          'Painel Principal alterado pelo Meu Espaço de Trabalho.',
      },
    )

    if (error) {
      setFeedback({
        type: 'error',
        text: `Não foi possível salvar o Painel Principal: ${error.message}`,
      })
      setSavingDashboardId(null)
      return
    }

    setPersistedPrimaryId(dashboardId)
    setPreferenceStatus('valid')
    setFeedback({
      type: 'success',
      text: `${dashboard.definition.label} foi definido como seu Painel Principal nesta organização.`,
    })
    setSavingDashboardId(null)
  }

  async function removePrimaryPreference() {
    setRemovingPreference(true)
    setFeedback(null)

    const { data, error } = await supabase.rpc(
      'delete_my_module_preference',
      {
        input_organization_id: organizationId,
        input_module_code: MODULE_CODE,
        input_preference_key: PRIMARY_DASHBOARD_KEY,
        change_reason:
          'Painel Principal redefinido para o padrão do Meu Espaço de Trabalho.',
      },
    )

    if (error) {
      setFeedback({
        type: 'error',
        text: `Não foi possível redefinir o Painel Principal: ${error.message}`,
      })
      setRemovingPreference(false)
      return
    }

    setPersistedPrimaryId(null)
    setPreferenceStatus('absent')
    setFeedback({
      type: 'success',
      text:
        data === true
          ? 'A preferência foi removida. O painel padrão voltou a ser utilizado.'
          : 'Nenhuma preferência salva foi encontrada. O painel padrão permanece ativo.',
    })
    setRemovingPreference(false)
  }

  function openDashboard(dashboard: ResolvedDashboard) {
    if (!dashboard.canOpen) return

    const destination = dashboardNavigation[dashboard.definition.id]

    if (destination) {
      onNavigate(destination)
      return
    }

    if (dashboard.definition.section === 'overview') {
      document
        .querySelector<HTMLElement>('.skpe-page-heading')
        ?.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  const preferenceLoading = preferenceStatus === 'loading'
  const preferenceBusy =
    preferenceLoading ||
    savingDashboardId !== null ||
    removingPreference

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

      <section
        className="skpe-primary-dashboard-panel"
        aria-labelledby="primary-dashboard-title"
      >
        <div>
          <p className="skpe-card-code">Preferência pessoal</p>
          <h2 id="primary-dashboard-title">Painel Principal</h2>

          {preferenceLoading ? (
            <p role="status">Carregando sua preferência...</p>
          ) : effectivePrimaryDashboard ? (
            <>
              <p>
                <strong>{effectivePrimaryDashboard.label}</strong>
                {persistedDashboardIsEligible
                  ? ' é o Painel Principal salvo para esta organização.'
                  : ' está sendo utilizado como painel padrão neste contexto.'}
              </p>

              {preferenceStatus === 'invalid' && (
                <p className="skpe-primary-dashboard-warning" role="status">
                  A preferência salva não está disponível no contexto atual e
                  não foi substituída automaticamente.
                </p>
              )}
            </>
          ) : (
            <p>
              Nenhum painel está elegível como principal no contexto atual.
              O Meu Espaço de Trabalho continuará aberto sem navegação
              automática.
            </p>
          )}
        </div>

        <div className="skpe-primary-dashboard-actions">
          {persistedPrimaryId && (
            <button
              type="button"
              className="skpe-secondary-button"
              disabled={preferenceBusy}
              onClick={() => void removePrimaryPreference()}
            >
              {removingPreference
                ? 'Redefinindo...'
                : 'Usar painel padrão'}
            </button>
          )}
        </div>
      </section>

      {feedback && (
        <div
          className={`skpe-action-message skpe-action-message-${feedback.type}`}
          role={feedback.type === 'error' ? 'alert' : 'status'}
        >
          {feedback.text}
        </div>
      )}

      {project ? (
        <section
          className="skpe-kpi-grid"
          aria-label="Síntese do projeto estratégico"
        >
          <article className="skpe-kpi-card">
            <span>Avanço geral estimado</span>
            <strong>
              {project.progress.toLocaleString('pt-BR', {
                maximumFractionDigits: 1,
              })}
              %
            </strong>
            <button
              type="button"
              className="skpe-card-link-button"
              onClick={() => onNavigate('journey')}
            >
              Abrir Jornada Estratégica
            </button>
          </article>

          <article className="skpe-kpi-card">
            <span>Projeto estratégico</span>
            <strong>{project.code}</strong>
            <small>{project.name}</small>
          </article>

          <article className="skpe-kpi-card">
            <span>Etapa atual</span>
            <strong>{project.currentPhaseCode}</strong>
            <small>{project.statusLabel}</small>
          </article>

          <article className="skpe-kpi-card">
            <span>Horizonte estratégico</span>
            <strong>{project.strategicHorizon}</strong>
            <button
              type="button"
              className="skpe-card-link-button"
              onClick={() => onNavigate('governance')}
            >
              {project.reviewCycle}
            </button>
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

      <MyPendingItemsPanel
        organizationId={organizationId}
        projectId={project?.id ?? null}
        onNavigate={onNavigate}
      />

      <section
        className="skpe-workspace-panels"
        aria-labelledby="workspace-panels-title"
      >
        <div className="skpe-card-heading">
          <div>
            <p className="skpe-card-code">Acessos contextuais</p>
            <h2 id="workspace-panels-title">Painéis do contexto atual</h2>
          </div>
        </div>

        <div className="skpe-dashboard-grid">
          {orderedDashboards.map((dashboard) => {
            const {
              definition,
              availability,
              reason,
              canOpen,
              canBePrimary,
            } = dashboard
            const isEffectivePrimary =
              definition.id === effectivePrimaryId
            const isPersistedPrimary =
              persistedDashboardIsEligible &&
              definition.id === persistedPrimaryId
            const isSaving =
              savingDashboardId === definition.id

            return (
              <article
                key={definition.id}
                className={`skpe-dashboard-card ${
                  isEffectivePrimary
                    ? 'skpe-dashboard-card-primary'
                    : ''
                }`}
                aria-labelledby={`dashboard-${definition.id}-title`}
              >
                <div className="skpe-card-heading">
                  <div>
                    <p className="skpe-card-code">
                      {isPersistedPrimary
                        ? 'Painel Principal'
                        : isEffectivePrimary
                          ? 'Painel atual'
                          : getAvailabilityLabel(availability)}
                    </p>
                    <h3 id={`dashboard-${definition.id}-title`}>
                      {definition.label}
                    </h3>
                  </div>

                  {isEffectivePrimary && (
                    <span className="skpe-primary-dashboard-badge">
                      Principal
                    </span>
                  )}
                </div>

                <p className="skpe-card-description">
                  {definition.description}
                </p>

                {!canOpen && reason && <small>{reason}</small>}

                <div className="skpe-dashboard-card-actions">
                  {canOpen && (
                    <button
                      type="button"
                      className="skpe-card-link-button"
                      onClick={() => openDashboard(dashboard)}
                    >
                      Abrir painel
                    </button>
                  )}

                  <button
                    type="button"
                    className="skpe-secondary-button"
                    disabled={
                      !canBePrimary ||
                      preferenceBusy ||
                      isPersistedPrimary
                    }
                    title={
                      canBePrimary
                        ? undefined
                        : reason ??
                          'Este painel não está elegível como Painel Principal.'
                    }
                    onClick={() =>
                      void savePrimaryDashboard(definition.id)
                    }
                  >
                    {isSaving
                      ? 'Salvando...'
                      : isPersistedPrimary
                        ? 'Painel Principal atual'
                        : 'Definir como principal'}
                  </button>
                </div>
              </article>
            )
          })}
        </div>
      </section>
    </>
  )
}
