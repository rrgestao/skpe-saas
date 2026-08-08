import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { FavoriteButton } from './FavoriteButton'
import { MyDecisionsPanel } from './MyDecisionsPanel'
import { MyIndicatorsPanel } from './MyIndicatorsPanel'
import { MyInitiativesPanel } from './MyInitiativesPanel'
import { MyKeyResultsPanel } from './MyKeyResultsPanel'
import { MyMeetingsPanel } from './MyMeetingsPanel'
import { MyNotificationsPanel } from './MyNotificationsPanel'
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

type PreferenceStatus =
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
const FAVORITES_KEY = 'workspace.favorites'
const MODULE_CODE = 'SK-PE'

const FAVORITABLE_DASHBOARD_IDS: readonly WorkspaceDashboardId[] = [
  'my-work',
  'executive',
  'portfolio',
  'governance',
]

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

function getFavoriteDashboardIds(
  value: unknown,
): WorkspaceDashboardId[] | null {
  if (
    typeof value !== 'object' ||
    value === null ||
    !('schema_version' in value) ||
    !('dashboard_ids' in value)
  ) {
    return null
  }

  if (value.schema_version !== 1 || !Array.isArray(value.dashboard_ids)) {
    return null
  }

  const dashboardIds = value.dashboard_ids

  if (
    dashboardIds.some(
      (dashboardId) =>
        !isWorkspaceDashboardId(dashboardId) ||
        !FAVORITABLE_DASHBOARD_IDS.includes(dashboardId),
    )
  ) {
    return null
  }

  if (new Set(dashboardIds).size !== dashboardIds.length) {
    return null
  }

  return dashboardIds
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
    useState<PreferenceStatus>('loading')
  const [savingDashboardId, setSavingDashboardId] =
    useState<WorkspaceDashboardId | null>(null)
  const [removingPreference, setRemovingPreference] = useState(false)
  const [feedback, setFeedback] = useState<PreferenceFeedback>(null)

  const [favoriteDashboardIds, setFavoriteDashboardIds] = useState<
    WorkspaceDashboardId[]
  >([])
  const [favoritesStatus, setFavoritesStatus] =
    useState<PreferenceStatus>('loading')
  const [savingFavoriteId, setSavingFavoriteId] =
    useState<WorkspaceDashboardId | null>(null)
  const [favoritesFeedback, setFavoritesFeedback] =
    useState<PreferenceFeedback>(null)

  const [unreadNotificationCount, setUnreadNotificationCount] = useState(0)

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

  const favoriteDashboards = useMemo(
    () =>
      favoriteDashboardIds
        .map((dashboardId) =>
          dashboards.find(
            ({ definition }) => definition.id === dashboardId,
          ),
        )
        .filter(
          (dashboard): dashboard is ResolvedDashboard =>
            dashboard !== undefined,
        ),
    [dashboards, favoriteDashboardIds],
  )

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
    let active = true

    async function loadFavoritesPreference() {
      setFavoritesStatus('loading')
      setFavoriteDashboardIds([])
      setFavoritesFeedback(null)

      const { data, error } = await supabase.rpc(
        'get_my_module_preference',
        {
          input_organization_id: organizationId,
          input_module_code: MODULE_CODE,
          input_preference_key: FAVORITES_KEY,
        },
      )

      if (!active) return

      if (error) {
        setFavoritesStatus('read-error')
        setFavoritesFeedback({
          type: 'error',
          text: `Não foi possível carregar seus Favoritos: ${error.message}`,
        })
        return
      }

      const row = ((data ?? [])[0] ?? null) as PreferenceRow | null

      if (!row) {
        setFavoritesStatus('absent')
        return
      }

      const dashboardIds = getFavoriteDashboardIds(row.preference_value)

      if (!dashboardIds) {
        setFavoritesStatus('invalid')
        setFavoritesFeedback({
          type: 'error',
          text: 'A preferência salva de Favoritos possui formato incompatível e não foi aplicada.',
        })
        return
      }

      setFavoriteDashboardIds(dashboardIds)
      setFavoritesStatus('valid')
    }

    void loadFavoritesPreference()

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

  async function toggleFavorite(dashboardId: WorkspaceDashboardId) {
    const dashboard = dashboards.find(
      ({ definition }) => definition.id === dashboardId,
    )

    if (!dashboard || !FAVORITABLE_DASHBOARD_IDS.includes(dashboardId)) {
      setFavoritesFeedback({
        type: 'error',
        text: 'Este painel não está elegível para Favoritos.',
      })
      return
    }

    const isFavorite = favoriteDashboardIds.includes(dashboardId)

    if (!isFavorite && !dashboard.canOpen) {
      setFavoritesFeedback({
        type: 'error',
        text: 'Este painel não pode ser adicionado aos Favoritos no contexto atual.',
      })
      return
    }

    const nextFavoriteIds = isFavorite
      ? favoriteDashboardIds.filter((id) => id !== dashboardId)
      : [...favoriteDashboardIds, dashboardId]

    setSavingFavoriteId(dashboardId)
    setFavoritesFeedback(null)

    if (nextFavoriteIds.length === 0) {
      const { error } = await supabase.rpc(
        'delete_my_module_preference',
        {
          input_organization_id: organizationId,
          input_module_code: MODULE_CODE,
          input_preference_key: FAVORITES_KEY,
          change_reason:
            'Último painel removido dos Favoritos no Meu Espaço de Trabalho.',
        },
      )

      if (error) {
        setFavoritesFeedback({
          type: 'error',
          text: `Não foi possível atualizar seus Favoritos: ${error.message}`,
        })
        setSavingFavoriteId(null)
        return
      }

      setFavoriteDashboardIds([])
      setFavoritesStatus('absent')
      setFavoritesFeedback({
        type: 'success',
        text: `${dashboard.definition.label} foi removido dos seus Favoritos.`,
      })
      setSavingFavoriteId(null)
      return
    }

    const { error } = await supabase.rpc(
      'set_my_module_preference',
      {
        input_organization_id: organizationId,
        input_module_code: MODULE_CODE,
        input_preference_key: FAVORITES_KEY,
        input_preference_value: {
          schema_version: 1,
          dashboard_ids: nextFavoriteIds,
        },
        change_reason: isFavorite
          ? 'Painel removido dos Favoritos no Meu Espaço de Trabalho.'
          : 'Painel adicionado aos Favoritos no Meu Espaço de Trabalho.',
      },
    )

    if (error) {
      setFavoritesFeedback({
        type: 'error',
        text: `Não foi possível atualizar seus Favoritos: ${error.message}`,
      })
      setSavingFavoriteId(null)
      return
    }

    setFavoriteDashboardIds(nextFavoriteIds)
    setFavoritesStatus('valid')
    setFavoritesFeedback({
      type: 'success',
      text: isFavorite
        ? `${dashboard.definition.label} foi removido dos seus Favoritos.`
        : `${dashboard.definition.label} foi adicionado aos seus Favoritos.`,
    })
    setSavingFavoriteId(null)
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

  const favoritesLoading = favoritesStatus === 'loading'
  const favoritesBusy = savingFavoriteId !== null

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
          <button
            type="button"
            className="skpe-notifications-bell"
            aria-label={`Abrir notificações. ${unreadNotificationCount} ${
              unreadNotificationCount === 1 ? 'não lida' : 'não lidas'
            }`}
            onClick={() => {
              document
                .getElementById('my-notifications-panel')
                ?.scrollIntoView({
                  behavior: 'smooth',
                  block: 'start',
                })
            }}
          >
            <span
              className="skpe-notifications-bell-icon"
              aria-hidden="true"
            >
              🔔
            </span>

            {unreadNotificationCount > 0 && (
              <span className="skpe-notifications-bell-count">
                {unreadNotificationCount > 99
                  ? '99+'
                  : unreadNotificationCount}
              </span>
            )}
          </button>

          <div
            className={`skpe-status-chip ${
              isReadOnly ? 'skpe-status-chip-neutral' : ''
            }`}
          >
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
                <p
                  className="skpe-primary-dashboard-warning"
                  role="status"
                >
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

      <MyIndicatorsPanel
        organizationId={organizationId}
        projectId={project?.id ?? null}
      />

      <MyKeyResultsPanel
        organizationId={organizationId}
        projectId={project?.id ?? null}
      />

      <MyInitiativesPanel
        organizationId={organizationId}
        projectId={project?.id ?? null}
      />

      <MyDecisionsPanel
        organizationId={organizationId}
        projectId={project?.id ?? null}
      />

      <MyMeetingsPanel
        organizationId={organizationId}
        projectId={project?.id ?? null}
      />

      <MyNotificationsPanel
        organizationId={organizationId}
        projectId={project?.id ?? null}
        onUnreadCountChange={setUnreadNotificationCount}
      />

      <section
        id="my-favorites-panel"
        className="skpe-favorites-panel"
        aria-labelledby="my-favorites-title"
      >
        <div>
          <p className="skpe-card-code">Preferência pessoal</p>
          <h2 id="my-favorites-title">Favoritos</h2>
          <p className="skpe-favorites-panel-description">
            Acesse rapidamente os painéis que você marcou como favoritos
            nesta organização.
          </p>
        </div>

        {favoritesFeedback && (
          <div
            className={`skpe-action-message skpe-action-message-${favoritesFeedback.type}`}
            role={
              favoritesFeedback.type === 'error' ? 'alert' : 'status'
            }
          >
            {favoritesFeedback.text}
          </div>
        )}

        {favoritesLoading ? (
          <p className="skpe-favorites-empty" role="status">
            Carregando seus Favoritos...
          </p>
        ) : favoriteDashboards.length === 0 ? (
          <p className="skpe-favorites-empty">
            Você ainda não possui painéis favoritos nesta organização.
          </p>
        ) : (
          <div className="skpe-favorites-grid">
            {favoriteDashboards.map((dashboard) => (
              <article
                key={dashboard.definition.id}
                className="skpe-favorite-card"
                aria-labelledby={`favorite-${dashboard.definition.id}-title`}
              >
                <div>
                  <p className="skpe-card-code">
                    {dashboard.canOpen
                      ? 'Favorito'
                      : getAvailabilityLabel(dashboard.availability)}
                  </p>
                  <h3
                    id={`favorite-${dashboard.definition.id}-title`}
                  >
                    {dashboard.definition.label}
                  </h3>
                </div>

                <p>{dashboard.definition.description}</p>

                {!dashboard.canOpen && dashboard.reason && (
                  <small>{dashboard.reason}</small>
                )}

                <div className="skpe-favorite-card-actions">
                  <button
                    type="button"
                    className="skpe-card-link-button"
                    disabled={!dashboard.canOpen}
                    onClick={() => openDashboard(dashboard)}
                  >
                    Abrir painel
                  </button>

                  <FavoriteButton
                    label={dashboard.definition.label}
                    isFavorite
                    busy={
                      savingFavoriteId === dashboard.definition.id
                    }
                    disabled={
                      favoritesBusy &&
                      savingFavoriteId !== dashboard.definition.id
                    }
                    onToggle={() =>
                      void toggleFavorite(dashboard.definition.id)
                    }
                  />
                </div>
              </article>
            ))}
          </div>
        )}
      </section>

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
            const isFavorite =
              favoriteDashboardIds.includes(definition.id)
            const canToggleFavorite =
              FAVORITABLE_DASHBOARD_IDS.includes(definition.id) &&
              (canOpen || isFavorite)

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

                  {FAVORITABLE_DASHBOARD_IDS.includes(definition.id) && (
                    <FavoriteButton
                      label={definition.label}
                      isFavorite={isFavorite}
                      busy={savingFavoriteId === definition.id}
                      disabled={
                        !canToggleFavorite ||
                        (favoritesBusy &&
                          savingFavoriteId !== definition.id) ||
                        favoritesLoading
                      }
                      onToggle={() =>
                        void toggleFavorite(definition.id)
                      }
                    />
                  )}
                </div>
              </article>
            )
          })}
        </div>
      </section>
    </>
  )
}
