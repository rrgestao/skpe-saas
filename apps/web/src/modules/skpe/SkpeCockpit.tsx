import {
  type KeyboardEvent,
  type ReactNode,
  useEffect,
  useMemo,
  useState,
} from 'react'

import { supabase } from '../../lib/supabase'

import './SkpeCockpit.css'
import { MethodologyArtifactsSection } from './MethodologyArtifactsSection'

type CockpitSection =
  | 'overview'
  | 'journey'
  | 'initiatives'
  | 'artifacts'
  | 'governance'
  | 'organization'
  | 'administration'
  | 'governance-roles'
  | 'organizational-areas'
  | 'organization-hierarchy'
  | 'domains'

type SkpeCockpitMode =
  | 'module'
  | 'organization-admin'

type SkpeCockpitProps = {
  organizationId: string
  organizationName: string
  organizationCode: string
  userRoleCode: string
  userRoleName: string
  isOrganizationAdmin: boolean
  isPlatformSuperAdmin: boolean
  mode?: SkpeCockpitMode
  initialSection?: CockpitSection
  onReturnToModules: () => void
}

type StrategicProjectContext = {
  project_id: string
  project_code: string
  project_name: string
  project_status: string
  project_progress: number
  current_phase_code: string | null
  planning_horizon_start_year: number | null
  planning_horizon_end_year: number | null
  reference_year: number | null
  review_cycle: string | null
  valid_from: string | null
  valid_until: string | null
}

type JourneyStatus =
  | 'not_started'
  | 'in_progress'
  | 'blocked'
  | 'pending_validation'
  | 'completed'
  | 'cancelled'

type JourneyRow = {
  project_id: string
  project_code: string
  project_name: string
  project_status: string
  project_progress: number
  item_id: string
  parent_item_id: string | null
  item_type:
    | 'macrophase'
    | 'phase'
    | 'stage'
    | 'activity'
    | 'deliverable'
    | 'gate'
  item_code: string
  item_name: string
  item_description: string | null
  item_status: JourneyStatus
  item_progress: number
  display_order: number
  is_current: boolean
  responsible_user_id: string | null
  responsible_name: string | null
  planned_start_date: string | null
  planned_end_date: string | null
  validation_required: boolean
  validation_status: string
  blocked: boolean
  blocking_reason: string | null
}

type JourneyItem = JourneyRow & {
  children: JourneyItem[]
}

type CanvasRow = {
  organization_id: string
  project_id: string
  project_code: string
  project_name: string
  canvas_id: string
  canvas_name: string
  canvas_status: string
  canvas_version: number
  template_code: string
  block_id: string
  block_code: string
  block_name: string
  block_description: string | null
  block_guidance: string | null
  block_order: number
  grid_area: string | null
  item_id: string | null
  item_content: string | null
  item_description: string | null
  item_status: string | null
  item_priority: string | null
  item_order: number | null
  linked_journey_item_id: string | null
  responsible_user_id: string | null
  responsible_name: string | null
}

type CanvasItem = {
  id: string
  content: string
  description: string | null
  status: string
  priority: string
  order: number
  linkedJourneyItemId: string | null
  responsibleUserId: string | null
  responsibleName: string | null
}

type CanvasBlock = {
  id: string
  code: string
  name: string
  description: string | null
  guidance: string | null
  order: number
  gridArea: string | null
  items: CanvasItem[]
}

type CanvasData = {
  projectId: string
  projectCode: string
  projectName: string
  canvasId: string
  canvasName: string
  canvasStatus: string
  canvasVersion: number
  templateCode: string
  blocks: CanvasBlock[]
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


function ChevronDownIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M6 9l6 6 6-6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function InitiativesIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M4 19V8l8-4 8 4v11"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinejoin="round"
      />
      <path
        d="M8 19v-5h8v5M3 19h18"
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


function OrganizationIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M4 20V7l8-4 8 4v13M8 20v-5h8v5M7 9h2M11 9h2M15 9h2M7 12h2M11 12h2M15 12h2M3 20h18"
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

const publicLabelByCode: Record<string, string> = {
  governance: 'Governança',
  management: 'Gestão',
  business: 'Negócios',
  operations: 'Operações',
  support: 'Suporte',
  control: 'Controle',
  project: 'Projeto',
  people: 'Pessoas',
  technology: 'Tecnologia',
  sustainability: 'Sustentabilidade',
  finance: 'Financeiro',
  strategy: 'Estratégia',
  communication: 'Comunicação',
  data: 'Dados',
  information: 'Informações',
  operational: 'Operacional',
  tactical: 'Tático',
  strategic: 'Estratégico',
  advisory: 'Consultivo',
  function: 'Função',
  committee: 'Comitê',
  board: 'Conselho',
  executive: 'Executivo',
  external: 'Externo',
  internal: 'Interno',
  active: 'Ativo',
  inactive: 'Inativo',
  pending: 'Pendente',
  suspended: 'Suspenso',
  revoked: 'Revogado',
  archived: 'Arquivado',
  draft: 'Rascunho',
  approved: 'Aprovado',
  rejected: 'Rejeitado',
  completed: 'Concluído',
  cancelled: 'Cancelado',
  ended: 'Encerrado',
  validated: 'Validado',
  under_review: 'Em análise',
  not_required: 'Não exigido',
  read_only: 'Somente leitura',
  consolidated: 'Consolidado',
  operational_delegated: 'Operacional delegado',
  administrative_delegated: 'Administrativo delegado',
  direct_children: 'Subordinadas diretas',
  all_descendants: 'Toda a estrutura descendente',
  specific_organization: 'Organização específica',
}

function publicLabel(value: string | null | undefined, fallback = 'Não informado') {
  if (!value) return fallback
  return publicLabelByCode[value.trim().toLowerCase()] ?? value
}


function activateRecordWithKeyboard(
  event: KeyboardEvent<HTMLElement>,
  action: () => void,
) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    action()
  }
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
  status: JourneyStatus,
) {
  const labels: Record<JourneyStatus, string> = {
    not_started: 'Não iniciada',
    in_progress: 'Em andamento',
    blocked: 'Bloqueada',
    pending_validation: 'Aguardando validação',
    completed: 'Concluída',
    cancelled: 'Cancelada',
  }

  return labels[status]
}

function getProjectStatusLabel(
  status: string,
) {
  const labels: Record<string, string> = {
    draft: 'Rascunho',
    active: 'Ativo',
    suspended: 'Suspenso',
    completed: 'Concluído',
    cancelled: 'Cancelado',
    archived: 'Arquivado',
  }

  return labels[status] ?? status
}

function getItemTypeLabel(
  itemType: JourneyRow['item_type'],
) {
  const labels: Record<
    JourneyRow['item_type'],
    string
  > = {
    macrophase: 'Macrofase',
    phase: 'Fase',
    stage: 'Etapa',
    activity: 'Atividade',
    deliverable: 'Entregável',
    gate: 'Gate de validação',
  }

  return labels[itemType]
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

function buildJourneyTree(
  rows: JourneyRow[],
): JourneyItem[] {
  const itemMap = new Map<
    string,
    JourneyItem
  >()

  for (const row of rows) {
    itemMap.set(row.item_id, {
      ...row,
      children: [],
    })
  }

  const roots: JourneyItem[] = []

  for (const item of itemMap.values()) {
    if (
      item.parent_item_id &&
      itemMap.has(item.parent_item_id)
    ) {
      itemMap
        .get(item.parent_item_id)
        ?.children.push(item)
    } else {
      roots.push(item)
    }
  }

  const sortItems = (
    items: JourneyItem[],
  ) => {
    items.sort(
      (firstItem, secondItem) =>
        firstItem.display_order -
        secondItem.display_order,
    )

    for (const item of items) {
      sortItems(item.children)
    }
  }

  sortItems(roots)

  return roots
}

function groupCanvasRows(
  rows: CanvasRow[],
): CanvasData | null {
  const firstRow = rows[0]

  if (!firstRow) {
    return null
  }

  const blocks = new Map<
    string,
    CanvasBlock
  >()

  for (const row of rows) {
    let block = blocks.get(row.block_id)

    if (!block) {
      block = {
        id: row.block_id,
        code: row.block_code,
        name: row.block_name,
        description:
          row.block_description,
        guidance: row.block_guidance,
        order: row.block_order,
        gridArea: row.grid_area,
        items: [],
      }

      blocks.set(row.block_id, block)
    }

    if (
      row.item_id &&
      row.item_content &&
      !block.items.some(
        (item) => item.id === row.item_id,
      )
    ) {
      block.items.push({
        id: row.item_id,
        content: row.item_content,
        description:
          row.item_description,
        status: row.item_status ?? 'active',
        priority:
          row.item_priority ?? 'medium',
        order: row.item_order ?? 0,
        linkedJourneyItemId:
          row.linked_journey_item_id,
        responsibleUserId:
          row.responsible_user_id,
        responsibleName:
          row.responsible_name,
      })
    }
  }

  const sortedBlocks = Array.from(
    blocks.values(),
  ).sort(
    (firstBlock, secondBlock) =>
      firstBlock.order - secondBlock.order,
  )

  for (const block of sortedBlocks) {
    block.items.sort(
      (firstItem, secondItem) =>
        firstItem.order - secondItem.order,
    )
  }

  return {
    projectId: firstRow.project_id,
    projectCode: firstRow.project_code,
    projectName: firstRow.project_name,
    canvasId: firstRow.canvas_id,
    canvasName: firstRow.canvas_name,
    canvasStatus:
      firstRow.canvas_status,
    canvasVersion:
      firstRow.canvas_version,
    templateCode: firstRow.template_code,
    blocks: sortedBlocks,
  }
}

function countJourneyDescendants(
  item: JourneyItem,
): number {
  return item.children.reduce(
    (total, child) =>
      total +
      1 +
      countJourneyDescendants(child),
    0,
  )
}

function buildJourneyBreadcrumb(
  rows: JourneyRow[],
  selectedItemId: string | null,
) {
  if (!selectedItemId) {
    return [] as JourneyRow[]
  }

  const rowMap = new Map(
    rows.map((row) => [row.item_id, row]),
  )

  const breadcrumb: JourneyRow[] = []
  let current = rowMap.get(selectedItemId)

  while (current) {
    breadcrumb.unshift(current)
    current = current.parent_item_id
      ? rowMap.get(current.parent_item_id)
      : undefined
  }

  return breadcrumb
}

function getJourneyStatusIcon(
  status: JourneyStatus,
) {
  if (status === 'completed') {
    return <CheckIcon />
  }

  if (
    status === 'in_progress' ||
    status === 'pending_validation'
  ) {
    return <ClockIcon />
  }

  return <LockIcon />
}


function OverviewSection({
  organizationName,
  organizationCode,
  projectContext,
  canManageJourney,
  startingProject,
  onStartProject,
  onNavigate,
}: {
  organizationName: string
  organizationCode: string
  projectContext: StrategicProjectContext | null
  canManageJourney: boolean
  startingProject: boolean
  onStartProject: () => void
  onNavigate: (section: CockpitSection) => void
}) {
  if (!projectContext) {
    const currentYear = new Date().getFullYear()

    return (
      <>
        <section className="skpe-page-heading">
          <div>
            <p className="skpe-eyebrow">Planejamento Estratégico da organização</p>
            <h1>Jornada ainda não iniciada</h1>
            <p>
              O módulo está habilitado para <strong>{organizationName}</strong>, mas não existe
              um projeto estratégico próprio desta organização. Nenhum dado de outra organização
              será utilizado como preenchimento alternativo.
            </p>
          </div>

          <div className="skpe-heading-status-group">
            <div className="skpe-horizon-chip">Horizonte sugerido: {currentYear}–{currentYear + 4}</div>
            <div className="skpe-status-chip skpe-status-chip-neutral">
              <span className="skpe-status-dot" />
              Não iniciado
            </div>
          </div>
        </section>

        <section className="skpe-onboarding-panel" aria-label="Início do Planejamento Estratégico">
          <div className="skpe-onboarding-icon"><GovernanceIcon /></div>
          <div className="skpe-onboarding-content">
            <p className="skpe-card-code">PEM-00</p>
            <h2>Metafase de Governança e Preparação</h2>
            <p>
              A jornada começa pela formalização do mandato, definição da governança, caracterização
              da organização, organização das evidências, avaliação de prontidão e autorização para o diagnóstico.
            </p>

            <div className="skpe-onboarding-steps">
              <article><strong>1</strong><span>Formalizar abertura, mandato e escopo.</span></article>
              <article><strong>2</strong><span>Definir patrocinadores, papéis, ritos e decisões.</span></article>
              <article><strong>3</strong><span>Estruturar evidências, pendências e prontidão.</span></article>
            </div>

            <div className="skpe-onboarding-actions">
              {canManageJourney ? (
                <button
                  type="button"
                  className="skpe-primary-action-button"
                  onClick={onStartProject}
                  disabled={startingProject}
                >
                  {startingProject ? 'Iniciando jornada...' : 'Iniciar Planejamento Estratégico'}
                </button>
              ) : (
                <p className="skpe-onboarding-readonly">
                  Solicite a um administrador ou gestor autorizado que inicie a jornada desta organização.
                </p>
              )}

              <button
                type="button"
                className="skpe-secondary-action-button"
                onClick={() => onNavigate('governance')}
              >
                Conhecer a governança metodológica
              </button>
            </div>

            <small>Organização: {organizationCode} · contexto local e exclusivo.</small>
          </div>
        </section>
      </>
    )
  }

  const strategicHorizon = formatStrategicHorizon(projectContext)
  const currentPhaseCode = projectContext.current_phase_code ?? 'A definir'
  const projectStatusLabel = publicLabel(projectContext.project_status)

  return (
    <>
      <section className="skpe-page-heading">
        <div>
          <p className="skpe-eyebrow">Visão executiva</p>
          <h1>Cockpit Estratégico</h1>
          <p>
            Acompanhamento integrado da jornada de planejamento estratégico da{' '}
            <strong>{organizationName}</strong> para o horizonte{' '}
            <strong>{strategicHorizon}</strong>.
          </p>
        </div>

        <div className="skpe-heading-status-group">
          <div className="skpe-horizon-chip">Horizonte estratégico: {strategicHorizon}</div>
          <div className="skpe-status-chip">
            <span className="skpe-status-dot" />
            {projectStatusLabel}
          </div>
        </div>
      </section>

      <section className="skpe-kpi-grid" aria-label="Indicadores executivos">
        <article className="skpe-kpi-card skpe-clickable-card" role="button" tabIndex={0} onClick={() => onNavigate('journey')} onKeyDown={(event) => activateRecordWithKeyboard(event, () => onNavigate('journey'))}>
          <span>Avanço geral estimado</span>
          <strong>{Number(projectContext.project_progress ?? 0).toLocaleString('pt-BR', { maximumFractionDigits: 1 })}%</strong>
          <small>Abrir Jornada Estratégica</small>
        </article>

        <article className="skpe-kpi-card skpe-clickable-card" role="button" tabIndex={0} onClick={() => onNavigate('journey')} onKeyDown={(event) => activateRecordWithKeyboard(event, () => onNavigate('journey'))}>
          <span>Projeto estratégico</span>
          <strong>{projectContext.project_code}</strong>
          <small>{projectContext.project_name}</small>
        </article>

        <article className="skpe-kpi-card skpe-clickable-card" role="button" tabIndex={0} onClick={() => onNavigate('journey')} onKeyDown={(event) => activateRecordWithKeyboard(event, () => onNavigate('journey'))}>
          <span>Etapa atual</span>
          <strong>{currentPhaseCode}</strong>
          <small>Abrir etapa na jornada</small>
        </article>

        <article className="skpe-kpi-card skpe-clickable-card" role="button" tabIndex={0} onClick={() => onNavigate('governance')} onKeyDown={(event) => activateRecordWithKeyboard(event, () => onNavigate('governance'))}>
          <span>Horizonte estratégico</span>
          <strong>{strategicHorizon}</strong>
          <small>{projectContext.review_cycle ?? 'Ciclo de revisão a definir'}</small>
        </article>
      </section>

      <section className="skpe-dashboard-grid">
        <article className="skpe-dashboard-card skpe-current-phase-card skpe-clickable-card" role="button" tabIndex={0} onClick={() => onNavigate('journey')} onKeyDown={(event) => activateRecordWithKeyboard(event, () => onNavigate('journey'))}>
          <div className="skpe-card-heading">
            <div>
              <p className="skpe-card-code">{currentPhaseCode}</p>
              <h2>Etapa atual da jornada</h2>
            </div>
            <span className="skpe-pill skpe-pill-progress">{projectStatusLabel}</span>
          </div>

          <p className="skpe-card-description">
            Consulte a estrutura metodológica própria de {organizationName}, seus itens, responsáveis,
            evidências, validações e gates.
          </p>

          <div className="skpe-progress-block">
            <div><span>Progresso estimado</span><strong>{Number(projectContext.project_progress ?? 0).toLocaleString('pt-BR', { maximumFractionDigits: 1 })}%</strong></div>
            <div className="skpe-progress-track"><span style={{ width: `${Math.max(0, Math.min(100, Number(projectContext.project_progress ?? 0)))}%` }} /></div>
          </div>
        </article>

        <article className="skpe-dashboard-card skpe-clickable-card" role="button" tabIndex={0} onClick={() => onNavigate('governance')} onKeyDown={(event) => activateRecordWithKeyboard(event, () => onNavigate('governance'))}>
          <div className="skpe-card-heading"><div><p className="skpe-card-code">Governança</p><h2>Controles e decisões</h2></div></div>
          <p className="skpe-card-description">Acesse os controles de governança, papéis, decisões, evidências e validações da organização selecionada.</p>
          <div className="skpe-decision-box"><strong>Contexto protegido</strong><span>Os registros apresentados pertencem exclusivamente a {organizationName}.</span></div>
        </article>

        <article className="skpe-dashboard-card skpe-clickable-card" role="button" tabIndex={0} onClick={() => onNavigate('initiatives')} onKeyDown={(event) => activateRecordWithKeyboard(event, () => onNavigate('initiatives'))}>
          <div className="skpe-card-heading"><div><p className="skpe-card-code">Execução</p><h2>Iniciativas estratégicas</h2></div></div>
          <p className="skpe-card-description">Abra o portfólio de iniciativas e acompanhe responsáveis, entregas, progresso, riscos e evidências.</p>
        </article>
      </section>
    </>
  )
}

type JourneySectionProps = {
  organizationId: string
  canManageJourney: boolean
}

function JourneySection({
  organizationId,
  canManageJourney,
}: JourneySectionProps) {
  const [rows, setRows] =
    useState<JourneyRow[]>([])

  const [loading, setLoading] =
    useState(true)

  const [savingItemId, setSavingItemId] =
    useState<string | null>(null)

  const [errorMessage, setErrorMessage] =
    useState('')

  const [expandedItems, setExpandedItems] =
    useState<Set<string>>(new Set())

  const [selectedItemId, setSelectedItemId] =
    useState<string | null>(null)

  const journeyTree = useMemo(
    () => buildJourneyTree(rows),
    [rows],
  )

  const project = rows[0] ?? null


  const selectedItem = useMemo(
    () =>
      rows.find(
        (row) =>
          row.item_id === selectedItemId,
      ) ?? null,
    [rows, selectedItemId],
  )

  const selectedBreadcrumb = useMemo(
    () =>
      buildJourneyBreadcrumb(
        rows,
        selectedItemId,
      ),
    [rows, selectedItemId],
  )

  const loadJourney = async () => {
    setLoading(true)
    setErrorMessage('')

    const { data, error } = await supabase.rpc(
      'get_skpe_journey',
      {
        target_organization_id:
          organizationId,
      },
    )

    if (error) {
      setRows([])
      setErrorMessage(error.message)
      setLoading(false)
      return
    }

    const journeyRows =
      (data ?? []) as JourneyRow[]

    setRows(journeyRows)

    setExpandedItems(
      new Set(
        journeyRows
          .filter(
            (row) =>
              row.item_type ===
                'macrophase' &&
              (row.is_current ||
                row.item_status ===
                  'in_progress'),
          )
          .map((row) => row.item_id),
      ),
    )

    setSelectedItemId((current) =>
      journeyRows.some(
        (row) => row.item_id === current,
      )
        ? current
        : journeyRows.find(
            (row) => row.is_current,
          )?.item_id ??
          journeyRows.find(
            (row) =>
              row.item_type ===
              'macrophase',
          )?.item_id ??
          null,
    )

    setLoading(false)
  }

  useEffect(() => {
    void loadJourney()
  }, [organizationId])

  const updateJourneyItem = async (
    item: JourneyItem,
    targetStatus: JourneyStatus,
    targetProgress: number,
  ) => {
    const actionLabel =
      targetStatus === 'completed'
        ? 'concluir'
        : targetStatus === 'in_progress'
          ? 'iniciar'
          : 'atualizar'

    const reason = window.prompt(
      `Informe a justificativa para ${actionLabel} "${item.item_name}".`,
    )

    if (!reason) {
      return
    }

    if (reason.trim().length < 10) {
      window.alert(
        'A justificativa deve ter pelo menos 10 caracteres.',
      )
      return
    }

    setSavingItemId(item.item_id)

    const { error } = await supabase.rpc(
      'set_skpe_journey_item_status',
      {
        target_item_id: item.item_id,
        target_status: targetStatus,
        target_progress: targetProgress,
        change_reason: reason.trim(),
      },
    )

    if (error) {
      window.alert(error.message)
      setSavingItemId(null)
      return
    }

    await loadJourney()
    setSavingItemId(null)
  }

  const toggleExpanded = (
    itemId: string,
  ) => {
    setExpandedItems((current) => {
      const next = new Set(current)

      if (next.has(itemId)) {
        next.delete(itemId)
      } else {
        next.add(itemId)
      }

      return next
    })
  }

  const renderJourneyItem = (
    item: JourneyItem,
    level = 0,
  ) => {
    const hasChildren =
      item.children.length > 0

    const isExpanded =
      expandedItems.has(item.item_id)

    return (
      <article
        key={item.item_id}
        className={[
          'skpe-journey-tree-item',
          `skpe-journey-level-${Math.min(
            level,
            4,
          )}`,
          item.is_current
            ? 'skpe-phase-current'
            : '',
          selectedItemId === item.item_id
            ? 'skpe-journey-item-selected'
            : '',
          hasChildren
            ? 'skpe-journey-item-drillable'
            : '',
        ]
          .filter(Boolean)
          .join(' ')}
        onClick={() => {
          setSelectedItemId(item.item_id)

          if (hasChildren) {
            toggleExpanded(item.item_id)
          }
        }}
      >
        <div className="skpe-journey-item-main">
          <div
            className={`skpe-phase-marker skpe-phase-${item.item_status}`}
          >
            {getJourneyStatusIcon(
              item.item_status,
            )}
          </div>

          <div className="skpe-journey-item-content">
            <div className="skpe-phase-heading">
              <div>
                <p>
                  {getItemTypeLabel(
                    item.item_type,
                  )}{' '}
                  · {item.item_code}
                </p>

                <h2>{item.item_name}</h2>
              </div>

              <div className="skpe-journey-heading-actions">
                <span
                  className={`skpe-pill skpe-pill-${item.item_status}`}
                >
                  {getStatusLabel(
                    item.item_status,
                  )}
                </span>

                {hasChildren && (
                  <button
                    type="button"
                    className={[
                      'skpe-tree-toggle-button',
                      isExpanded
                        ? 'skpe-tree-toggle-expanded'
                        : '',
                    ]
                      .filter(Boolean)
                      .join(' ')}
                    onClick={(event) => {
                      event.stopPropagation()
                      setSelectedItemId(
                        item.item_id,
                      )
                      toggleExpanded(
                        item.item_id,
                      )
                    }}
                    aria-expanded={isExpanded}
                    title={
                      isExpanded
                        ? 'Recolher níveis subordinados'
                        : 'Abrir fases, etapas e atividades'
                    }
                  >
                    <span>
                      {countJourneyDescendants(
                        item,
                      )}{' '}
                      itens
                    </span>
                    <ChevronDownIcon />
                  </button>
                )}
              </div>
            </div>

            {item.item_description && (
              <p>{item.item_description}</p>
            )}

            <div className="skpe-journey-meta">
              {item.responsible_name && (
                <span>
                  Responsável:{' '}
                  <strong>
                    {item.responsible_name}
                  </strong>
                </span>
              )}

              {(item.planned_start_date ||
                item.planned_end_date) && (
                <span>
                  Período:{' '}
                  <strong>
                    {formatDate(
                      item.planned_start_date,
                    )}{' '}
                    a{' '}
                    {formatDate(
                      item.planned_end_date,
                    )}
                  </strong>
                </span>
              )}

              {item.validation_required && (
                <span>
                  Validação:{' '}
                  <strong>
                    {item.validation_status}
                  </strong>
                </span>
              )}
            </div>

            {item.blocked &&
              item.blocking_reason && (
                <div className="skpe-journey-blocked-message">
                  {item.blocking_reason}
                </div>
              )}

            <div className="skpe-phase-progress">
              <div className="skpe-progress-track">
                <span
                  style={{
                    width: `${item.item_progress}%`,
                  }}
                />
              </div>

              <strong>
                {item.item_progress}%
              </strong>
            </div>

            {canManageJourney && (
              <div
                className="skpe-journey-quick-actions"
                onClick={(event) =>
                  event.stopPropagation()
                }
              >
                {item.item_status ===
                  'not_started' && (
                  <button
                    type="button"
                    onClick={() =>
                      void updateJourneyItem(
                        item,
                        'in_progress',
                        Math.max(
                          item.item_progress,
                          1,
                        ),
                      )
                    }
                    disabled={
                      savingItemId ===
                      item.item_id
                    }
                  >
                    Iniciar
                  </button>
                )}

                {item.item_status !==
                  'completed' && (
                  <button
                    type="button"
                    onClick={() =>
                      void updateJourneyItem(
                        item,
                        'completed',
                        100,
                      )
                    }
                    disabled={
                      savingItemId ===
                      item.item_id
                    }
                  >
                    Concluir
                  </button>
                )}

                {item.item_status ===
                  'completed' && (
                  <button
                    type="button"
                    onClick={() =>
                      void updateJourneyItem(
                        item,
                        'in_progress',
                        Math.min(
                          item.item_progress,
                          99,
                        ),
                      )
                    }
                    disabled={
                      savingItemId ===
                      item.item_id
                    }
                  >
                    Reabrir
                  </button>
                )}
              </div>
            )}
          </div>
        </div>

        {hasChildren && isExpanded && (
          <div className="skpe-journey-children">
            {item.children.map((child) =>
              renderJourneyItem(
                child,
                level + 1,
              ),
            )}
          </div>
        )}
      </article>
    )
  }

  return (
    <>
      <section className="skpe-page-heading skpe-administration-heading">
        <div>
          <p className="skpe-eyebrow">
            Metodologia de Planejamento Estratégico
          </p>

          <h1>Jornada Estratégica</h1>

          <p>
            Estrutura real do projeto, carregada
            do banco, com macrofases, fases,
            entregáveis e gates de validação.
          </p>
        </div>

        <button
          type="button"
          className="skpe-refresh-button"
          onClick={() => void loadJourney()}
          disabled={loading}
        >
          <RefreshIcon />
          Atualizar jornada
        </button>
      </section>

      {project && (
        <section className="skpe-project-context-card">
          <div>
            <span>Projeto estratégico</span>
            <strong>
              {project.project_name}
            </strong>
            <small>
              {project.project_code}
            </small>
          </div>

          <div>
            <span>Progresso geral</span>
            <strong>
              {project.project_progress}%
            </strong>
            <small>
              Situação: {getProjectStatusLabel(
                project.project_status,
              )}
            </small>
          </div>
        </section>
      )}

      {errorMessage && (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      )}

      {loading ? (
        <section className="skpe-admin-state-card">
          <p>
            Carregando a Jornada Estratégica...
          </p>
        </section>
      ) : journeyTree.length === 0 ? (
        <section className="skpe-admin-state-card">
          <h2>
            Nenhuma jornada encontrada
          </h2>
          <p>
            Verifique se o projeto estratégico
            foi criado para esta organização.
          </p>
        </section>
      ) : (
        <div className="skpe-journey-workspace">
          <section className="skpe-journey-tree">
            {journeyTree.map((item) =>
              renderJourneyItem(item),
            )}
          </section>

          <aside className="skpe-journey-detail-panel">
            {selectedItem ? (
              <>
                <div className="skpe-journey-breadcrumb">
                  {selectedBreadcrumb.map(
                    (breadcrumbItem, index) => (
                      <span
                        key={
                          breadcrumbItem.item_id
                        }
                      >
                        {index > 0 && (
                          <b>›</b>
                        )}
                        {breadcrumbItem.item_code}
                      </span>
                    ),
                  )}
                </div>

                <p className="skpe-eyebrow">
                  {getItemTypeLabel(
                    selectedItem.item_type,
                  )}
                </p>

                <h2>{selectedItem.item_name}</h2>

                <p>
                  {selectedItem.item_description ??
                    'Não há descrição complementar cadastrada.'}
                </p>

                <dl className="skpe-journey-detail-list">
                  <div>
                    <dt>Situação</dt>
                    <dd>
                      {getStatusLabel(
                        selectedItem.item_status,
                      )}
                    </dd>
                  </div>

                  <div>
                    <dt>Progresso</dt>
                    <dd>
                      {selectedItem.item_progress}%
                    </dd>
                  </div>

                  <div>
                    <dt>Responsável</dt>
                    <dd>
                      {selectedItem.responsible_name ??
                        'Não definido'}
                    </dd>
                  </div>

                  <div>
                    <dt>Validação</dt>
                    <dd>
                      {selectedItem.validation_required
                        ? selectedItem.validation_status
                        : 'Não obrigatória'}
                    </dd>
                  </div>
                </dl>

                {selectedItem.item_type ===
                  'macrophase' && (
                  <div className="skpe-journey-detail-hint">
                    Clique novamente no cartão ou no
                    ícone de expansão para navegar pelos
                    níveis subordinados.
                  </div>
                )}
              </>
            ) : (
              <div className="skpe-user-detail-empty">
                <JourneyIcon />
                <h2>Selecione um item</h2>
                <p>
                  Consulte seus detalhes e navegue pela
                  estrutura metodológica.
                </p>
              </div>
            )}
          </aside>
        </div>
      )}
    </>
  )
}

type CanvasSectionProps = {
  organizationId: string
  canManageCanvas: boolean
}

function CanvasSection({
  organizationId,
  canManageCanvas,
}: CanvasSectionProps) {
  const [journeyRows, setJourneyRows] =
    useState<JourneyRow[]>([])

  const [canvasRows, setCanvasRows] =
    useState<CanvasRow[]>([])

  const [loading, setLoading] =
    useState(true)

  const [savingBlockId, setSavingBlockId] =
    useState<string | null>(null)

  const [newItemByBlock, setNewItemByBlock] =
    useState<Record<string, string>>({})

  const [priorityByBlock, setPriorityByBlock] =
    useState<Record<string, string>>({})

  const [errorMessage, setErrorMessage] =
    useState('')

  const canvasData = useMemo(
    () => groupCanvasRows(canvasRows),
    [canvasRows],
  )

  const projectId =
    journeyRows[0]?.project_id ?? null

  const loadCanvas = async () => {
    setLoading(true)
    setErrorMessage('')

    const {
      data: journeyData,
      error: journeyError,
    } = await supabase.rpc(
      'get_skpe_journey',
      {
        target_organization_id:
          organizationId,
      },
    )

    if (journeyError) {
      setErrorMessage(
        journeyError.message,
      )
      setLoading(false)
      return
    }

    const loadedJourneyRows =
      (journeyData ?? []) as JourneyRow[]

    setJourneyRows(loadedJourneyRows)

    const loadedProjectId =
      loadedJourneyRows[0]?.project_id

    if (!loadedProjectId) {
      setCanvasRows([])
      setLoading(false)
      return
    }

    const {
      data: canvasDataResponse,
      error: canvasError,
    } = await supabase.rpc(
      'get_skpe_project_canvas',
      {
        target_project_id:
          loadedProjectId,
      },
    )

    if (canvasError) {
      setErrorMessage(canvasError.message)
      setCanvasRows([])
      setLoading(false)
      return
    }

    setCanvasRows(
      (canvasDataResponse ??
        []) as CanvasRow[],
    )
    setLoading(false)
  }

  useEffect(() => {
    void loadCanvas()
  }, [organizationId])

  const createCanvas = async () => {
    if (!projectId) {
      return
    }

    setLoading(true)

    const { error } = await supabase.rpc(
      'create_skpe_project_canvas',
      {
        target_project_id: projectId,
        canvas_name:
          'Business Model Canvas do Projeto',
      },
    )

    if (error) {
      setErrorMessage(error.message)
      setLoading(false)
      return
    }

    await loadCanvas()
  }

  const addItem = async (
    block: CanvasBlock,
  ) => {
    const content =
      newItemByBlock[block.id]?.trim()

    if (!content) {
      window.alert(
        'Informe o conteúdo do item.',
      )
      return
    }

    setSavingBlockId(block.id)

    const { error } = await supabase.rpc(
      'add_skpe_project_canvas_item',
      {
        target_block_id: block.id,
        item_content: content,
        item_priority:
          priorityByBlock[block.id] ??
          'medium',
        change_reason:
          'Inclusão direta no Canvas do Projeto.',
      },
    )

    if (error) {
      window.alert(error.message)
      setSavingBlockId(null)
      return
    }

    setNewItemByBlock((current) => ({
      ...current,
      [block.id]: '',
    }))

    await loadCanvas()
    setSavingBlockId(null)
  }

  const updateCanvasItemStatus = async (
    item: CanvasItem,
    targetStatus:
      | 'active'
      | 'validated'
      | 'discarded',
  ) => {
    const reason = window.prompt(
      'Informe a justificativa para esta alteração.',
    )

    if (!reason) {
      return
    }

    if (reason.trim().length < 10) {
      window.alert(
        'A justificativa deve ter pelo menos 10 caracteres.',
      )
      return
    }

    const { error } = await supabase.rpc(
      'set_skpe_project_canvas_item_status',
      {
        target_item_id: item.id,
        target_status: targetStatus,
        change_reason: reason.trim(),
      },
    )

    if (error) {
      window.alert(error.message)
      return
    }

    await loadCanvas()
  }

  return (
    <>
      <section className="skpe-page-heading skpe-administration-heading">
        <div>
          <p className="skpe-eyebrow">
            Projeto estratégico selecionado
          </p>

          <h1>Canvas do Projeto</h1>

          <p>
            Business Model Canvas complementar
            à jornada, com 14 blocos, incluindo
            Sustentabilidade e ESG.
          </p>
        </div>

        <button
          type="button"
          className="skpe-refresh-button"
          onClick={() => void loadCanvas()}
          disabled={loading}
        >
          <RefreshIcon />
          Atualizar Canvas
        </button>
      </section>

      {errorMessage && (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      )}

      {loading ? (
        <section className="skpe-admin-state-card">
          <p>
            Carregando o Canvas do Projeto...
          </p>
        </section>
      ) : !projectId ? (
        <section className="skpe-admin-state-card">
          <h2>
            Projeto estratégico não encontrado
          </h2>
          <p>
            Crie a Jornada Estratégica antes de
            utilizar o Canvas do Projeto.
          </p>
        </section>
      ) : !canvasData ? (
        <section className="skpe-admin-state-card">
          <h2>
            Canvas ainda não criado
          </h2>
          <p>
            Utilize o modelo recomendado com
            Sustentabilidade e ESG.
          </p>

          {canManageCanvas && (
            <button
              type="button"
              className="skpe-primary-action-button skpe-create-canvas-button"
              onClick={() =>
                void createCanvas()
              }
            >
              Criar Canvas recomendado
            </button>
          )}
        </section>
      ) : (
        <>
          <section className="skpe-project-context-card">
            <div>
              <span>Projeto</span>
              <strong>
                {canvasData.projectName}
              </strong>
              <small>
                {canvasData.projectCode}
              </small>
            </div>

            <div>
              <span>Modelo</span>
              <strong>
                {canvasData.templateCode}
              </strong>
              <small>
                Versão {canvasData.canvasVersion}
              </small>
            </div>
          </section>

          <section className="skpe-canvas-grid">
            {canvasData.blocks.map(
              (block) => (
                <article
                  key={block.id}
                  className={[
                    'skpe-canvas-block',
                    block.code ===
                    'SUSTAINABILITY_ESG'
                      ? 'skpe-canvas-block-esg'
                      : '',
                  ]
                    .filter(Boolean)
                    .join(' ')}
                >
                  <div className="skpe-canvas-block-heading">
                    <div>
                      <span>
                        {String(
                          block.order / 10,
                        ).padStart(2, '0')}
                      </span>
                      <h2>{block.name}</h2>
                    </div>

                    <small>
                      {block.items.length}{' '}
                      item
                      {block.items.length === 1
                        ? ''
                        : 's'}
                    </small>
                  </div>

                  {block.description && (
                    <p className="skpe-canvas-block-description">
                      {block.description}
                    </p>
                  )}

                  {block.guidance && (
                    <div className="skpe-canvas-guidance">
                      {block.guidance}
                    </div>
                  )}

                  <div className="skpe-canvas-items">
                    {block.items.length === 0 ? (
                      <p className="skpe-canvas-empty">
                        Nenhum conteúdo registrado.
                      </p>
                    ) : (
                      block.items.map((item) => (
                        <div
                          key={item.id}
                          className={`skpe-canvas-item skpe-canvas-item-${item.status}`}
                        >
                          <div>
                            <strong>
                              {item.content}
                            </strong>

                            <span>
                              Prioridade:{' '}
                              {item.priority}
                            </span>
                          </div>

                          {canManageCanvas && (
                            <div className="skpe-canvas-item-actions">
                              {item.status !==
                                'validated' && (
                                <button
                                  type="button"
                                  onClick={() =>
                                    void updateCanvasItemStatus(
                                      item,
                                      'validated',
                                    )
                                  }
                                >
                                  Validar
                                </button>
                              )}

                              {item.status ===
                                'validated' && (
                                <button
                                  type="button"
                                  onClick={() =>
                                    void updateCanvasItemStatus(
                                      item,
                                      'active',
                                    )
                                  }
                                >
                                  Reabrir
                                </button>
                              )}
                            </div>
                          )}
                        </div>
                      ))
                    )}
                  </div>

                  {canManageCanvas && (
                    <div className="skpe-canvas-add-item">
                      <input
                        type="text"
                        value={
                          newItemByBlock[
                            block.id
                          ] ?? ''
                        }
                        onChange={(event) =>
                          setNewItemByBlock(
                            (current) => ({
                              ...current,
                              [block.id]:
                                event.target
                                  .value,
                            }),
                          )
                        }
                        placeholder="Adicionar conteúdo ao bloco"
                      />

                      <select
                        value={
                          priorityByBlock[
                            block.id
                          ] ?? 'medium'
                        }
                        onChange={(event) =>
                          setPriorityByBlock(
                            (current) => ({
                              ...current,
                              [block.id]:
                                event.target
                                  .value,
                            }),
                          )
                        }
                      >
                        <option value="low">
                          Baixa
                        </option>
                        <option value="medium">
                          Média
                        </option>
                        <option value="high">
                          Alta
                        </option>
                        <option value="critical">
                          Crítica
                        </option>
                      </select>

                      <button
                        type="button"
                        onClick={() =>
                          void addItem(block)
                        }
                        disabled={
                          savingBlockId ===
                          block.id
                        }
                      >
                        {savingBlockId ===
                        block.id
                          ? 'Salvando...'
                          : 'Adicionar'}
                      </button>
                    </div>
                  )}
                </article>
              ),
            )}
          </section>
        </>
      )}
    </>
  )
}



type OrganizationProfileRow = {
  organization_id: string
  organization_code: string
  legal_name: string | null
  trade_name: string | null
  formatted_cnpj: string | null
  cnpj: string | null
  institutional_email: string | null
  phone: string | null
  website: string | null
  postal_code: string | null
  street: string | null
  address_number: string | null
  address_complement: string | null
  district: string | null
  city: string | null
  state_code: string | null
  country_code: string | null
  logo_url: string | null
  logo_storage_path: string | null
  logo_version: number | null
  cooperative_branch: string | null
  organization_type: string | null
  primary_activity_description: string | null
  economic_activities: Array<{ id?: string; code: string; description: string | null; is_primary: boolean; status?: string }>
  organization_size: string | null
  institutional_profile_updated_at: string | null
}


type CnaeCatalogSearchRow = {
  cnae_catalog_id: string
  version_code: string
  subclass_code: string
  formatted_code: string
  description: string
  section_code: string | null
  section_name: string | null
  division_code: string | null
  division_name: string | null
  group_code: string | null
  group_name: string | null
  class_code: string | null
  class_name: string | null
}

type OrganizationCnaeRow = {
  organization_activity_id: string
  cnae_catalog_id: string | null
  version_code: string | null
  subclass_code: string
  formatted_code: string
  description: string
  is_primary: boolean
  verification_status: string
  source_type: string | null
  source_reference: string | null
  verified_at: string | null
  verified_by: string | null
  is_official_catalog_entry: boolean
}

type SelectedCnae = {
  cnaeCatalogId: string
  versionCode: string
  subclassCode: string
  formattedCode: string
  description: string
  sectionCode: string | null
  sectionName: string | null
  isPrimary: boolean
}

type OrganizationContactRow = {
  organization_person_id: string
  person_id: string
  full_name: string
  contact_function: string | null
  job_title: string | null
  phone: string | null
  mobile_phone: string | null
  email: string | null
  is_primary_contact: boolean
  status: string
  crm_sync_status: string
}

type OrganizationContactForm = {
  organizationPersonId: string | null
  fullName: string
  contactFunction: string
  phone: string
  mobilePhone: string
  email: string
  isPrimaryContact: boolean
  changeReason: string
}

type OrganizationFormState = {
  legalName: string
  tradeName: string
  cnpj: string
  institutionalEmail: string
  phone: string
  website: string
  postalCode: string
  street: string
  addressNumber: string
  addressComplement: string
  district: string
  city: string
  stateCode: string
  organizationType: string
  primaryActivityDescription: string
  cnaesText: string
  cooperativeBranch: string
  organizationSize: string
  changeReason: string
}

function onlyDigits(value: string) {
  return value.replace(/\D/g, '')
}

function formatCnpjInput(value: string) {
  const digits = onlyDigits(value).slice(0, 14)
  return digits
    .replace(/^(\d{2})(\d)/, '$1.$2')
    .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
    .replace(/\.(\d{3})(\d)/, '.$1/$2')
    .replace(/(\d{4})(\d)/, '$1-$2')
}

function formatPostalCodeInput(value: string) {
  const digits = onlyDigits(value).slice(0, 8)
  return digits.replace(/^(\d{5})(\d)/, '$1-$2')
}


function formatPhoneInput(value: string) {
  const digits = onlyDigits(value).slice(0, 10)
  return digits.replace(/^(\d{2})(\d)/, '($1) $2').replace(/(\d{4})(\d)/, '$1-$2')
}

function formatMobilePhoneInput(value: string) {
  const digits = onlyDigits(value).slice(0, 11)
  return digits.replace(/^(\d{2})(\d)/, '($1) $2').replace(/(\d)(\d{4})(\d)/, '$1 $2-$3')
}

function getOrganizationInitials(name: string) {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('') || 'OR'
}

function getCooperativeBranchLabel(value: string | null | undefined) {
  if (!value) return 'Ramo não informado'

  const normalized = value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()
    .toLowerCase()

  const labels: Record<string, string> = {
    agropecuario: 'Ramo Agropecuário',
    consumo: 'Ramo Consumo',
    credito: 'Ramo Crédito',
    infraestrutura: 'Ramo Infraestrutura',
    saude: 'Ramo Saúde',
    trabalho_producao_bens_servicos: 'Ramo Trabalho, Produção de Bens e Serviços',
    transporte: 'Ramo Transporte',
  }

  return labels[normalized] ?? `Ramo ${value}`
}

function formatStrategicHorizon(context: StrategicProjectContext | null) {
  const start = context?.planning_horizon_start_year
  const end = context?.planning_horizon_end_year

  if (!start || !end) return 'Horizonte a definir'
  return `${start}–${end}`
}

type InitiativeDashboardRow = {
  total_initiatives: number
  proposed_count: number
  in_progress_count: number
  completed_count: number
  delayed_count: number
  blocked_count: number
  critical_count: number
  without_owner_count: number
  without_recent_update_count: number
  with_instrument_count: number
  without_instrument_count: number
  average_progress: number
  planned_cost: number
  actual_cost: number
  planned_benefit: number
  realized_benefit: number
}

type InitiativeObjective = {
  id: string
  code: string
  name: string
  management_model: string
  contribution_type: string
  contribution_weight: number
}

type InitiativeKeyResult = {
  id: string
  code: string
  name: string
  status: string
  progress: number
  contribution_type: string
  contribution_weight: number | null
}

type InitiativeInstrument = {
  id: string
  type: string
  reference_id: string | null
  code: string | null
  status: string
  is_primary: boolean
}

type InitiativeRow = {
  initiative_id: string
  project_id: string | null
  project_code: string | null
  initiative_code: string
  initiative_name: string
  initiative_description: string | null
  initiative_type: string
  initiative_status: string
  priority: string
  responsible_area: string | null
  owner_user_id: string | null
  owner_name: string | null
  start_date: string | null
  due_date: string | null
  progress: number
  planned_cost: number | null
  actual_cost: number | null
  planned_benefit: number | null
  realized_benefit: number | null
  risk_level: string
  health_status: string
  last_update_at: string | null
  delayed: boolean
  proposal_origin: string
  proposal_source_reference: string | null
  validation_status: string
  validation_notes: string | null
  validated_at: string | null
  validated_by_name: string | null
  what_text: string
  why_text: string
  where_text: string
  when_text: string
  who_text: string
  how_text: string
  how_much_text: string
  five_w_two_h_completion: number
  strategic_objectives: InitiativeObjective[]
  key_results: InitiativeKeyResult[]
  instruments: InitiativeInstrument[]
}

type InitiativeFormState = {
  code: string
  name: string
  description: string
  initiativeType: string
  priority: string
  proposalOrigin: string
  proposalSourceReference: string
  responsibleArea: string
  ownerUserId: string
  startDate: string
  dueDate: string
  plannedCost: string
  plannedBenefit: string
  strategicTheme: string
  whatText: string
  whyText: string
  whereText: string
  whenText: string
  whoText: string
  howText: string
  howMuchText: string
  changeReason: string
  createInstrument: boolean
}

type InitiativeOwnerOption = {
  userId: string
  label: string
}

type InitiativesSectionProps = {
  organizationId: string
  canManageCanvas: boolean
  canManageInitiatives: boolean
}

function getInitiativeTypeLabel(value: string) {
  const labels: Record<string, string> = {
    strategic_project: 'Projeto Estratégico',
    operational_improvement: 'Melhoria Operacional',
    process_initiative: 'Iniciativa de Processo',
    simple_action: 'Ação Simples',
    strategic_program: 'Programa Estratégico',
  }
  return labels[value] ?? value
}

function getInitiativeStatusLabel(value: string) {
  const labels: Record<string, string> = {
    proposed: 'Proposta',
    under_analysis: 'Em análise',
    approved: 'Aprovada',
    planned: 'Planejada',
    in_progress: 'Em execução',
    on_hold: 'Em espera',
    blocked: 'Bloqueada',
    completed: 'Concluída',
    cancelled: 'Cancelada',
    archived: 'Arquivada',
  }
  return labels[value] ?? value
}

function getProposalOriginLabel(value: string) {
  const labels: Record<string, string> = {
    sparks_suggestion: 'Sugerida pela SPARKs',
    organization: 'Criada pela organização',
    joint_construction: 'Construída conjuntamente',
    previous_plan: 'Importada de plano anterior',
    assessment: 'Originada de diagnóstico',
    action_plan: 'Originada de plano de ação',
    bmc_vpc: 'Originada de BMC/VPC',
    benchmark: 'Originada de benchmark',
  }
  return labels[value] ?? value
}

function getValidationStatusLabel(value: string) {
  const labels: Record<string, string> = {
    pending_validation: 'Pendente de validação',
    under_review: 'Em análise',
    validated: 'Validada',
    validated_with_adjustments: 'Validada com ajustes',
    rejected: 'Rejeitada',
    replaced: 'Substituída',
    not_required: 'Validação não necessária',
  }
  return labels[value] ?? value
}

function formatCurrency(value: number | null | undefined) {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
    maximumFractionDigits: 0,
  }).format(value ?? 0)
}

function InitiativesSection({
  organizationId,
  canManageCanvas,
  canManageInitiatives,
}: InitiativesSectionProps) {
  const [dashboard, setDashboard] = useState<InitiativeDashboardRow | null>(null)
  const [initiatives, setInitiatives] = useState<InitiativeRow[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')
  const [typeFilter, setTypeFilter] = useState('all')
  const [areaFilter, setAreaFilter] = useState('all')
  const [objectiveFilter, setObjectiveFilter] = useState('all')
  const [originFilter, setOriginFilter] = useState('all')
  const [validationFilter, setValidationFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedInitiative, setSelectedInitiative] = useState<InitiativeRow | null>(null)
  const [showInstrument, setShowInstrument] = useState(false)
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [savingInitiative, setSavingInitiative] = useState(false)
  const [journeyRows, setJourneyRows] = useState<JourneyRow[]>([])
  const [ownerOptions, setOwnerOptions] = useState<InitiativeOwnerOption[]>([])
  const [formMessage, setFormMessage] = useState<ActionMessage | null>(null)
  const [validationNotes, setValidationNotes] = useState('')
  const [validationReason, setValidationReason] = useState('')
  const [quickFilter, setQuickFilter] = useState('all')

  const emptyForm: InitiativeFormState = {
    code: '', name: '', description: '', initiativeType: 'strategic_project',
    priority: 'medium', proposalOrigin: 'sparks_suggestion',
    proposalSourceReference: '', responsibleArea: '', ownerUserId: '',
    startDate: '', dueDate: '', plannedCost: '', plannedBenefit: '',
    strategicTheme: '', whatText: '', whyText: '', whereText: '',
    whenText: '', whoText: '', howText: '', howMuchText: '',
    changeReason: '', createInstrument: true,
  }
  const [initiativeForm, setInitiativeForm] = useState<InitiativeFormState>(emptyForm)

  const loadInitiativeSupportData = async () => {
    const [journeyResponse, usersResponse] = await Promise.all([
      supabase.rpc('get_skpe_journey', { target_organization_id: organizationId }),
      supabase.rpc('get_organization_user_access', { target_organization_id: organizationId }),
    ])
    if (!journeyResponse.error) setJourneyRows((journeyResponse.data ?? []) as JourneyRow[])
    if (!usersResponse.error) {
      const groupedUsers = groupUserAccessRows((usersResponse.data ?? []) as UserAccessRow[])
      setOwnerOptions(groupedUsers.filter((user) => user.membershipStatus === 'active' && user.userActive)
        .map((user) => ({ userId: user.userId, label: user.displayName ?? user.email })))
    }
  }

  const updateInitiativeForm = <K extends keyof InitiativeFormState>(field: K, value: InitiativeFormState[K]) => {
    setInitiativeForm((current) => ({ ...current, [field]: value }))
  }

  const getRecommendedInstrumentType = (initiativeType: string) => {
    if (initiativeType === 'strategic_project' || initiativeType === 'operational_improvement') return 'project_canvas'
    if (initiativeType === 'process_initiative') return 'sipoc_canvas'
    if (initiativeType === 'simple_action') return 'action_plan'
    if (initiativeType === 'strategic_program') return 'program_canvas'
    return null
  }

  const resetInitiativeForm = () => {
    setInitiativeForm(emptyForm)
    setFormMessage(null)
  }

  const handleCreateInitiative = async () => {
    const projectId = journeyRows[0]?.project_id
    if (!projectId) {
      setFormMessage({ type: 'error', text: 'Projeto estratégico não encontrado para esta organização.' })
      return
    }
    if (!initiativeForm.code.trim() || !initiativeForm.name.trim()) {
      setFormMessage({ type: 'error', text: 'Informe o código e o nome da iniciativa.' })
      return
    }
    const required5w2h = [
      initiativeForm.whatText, initiativeForm.whyText, initiativeForm.whereText,
      initiativeForm.whenText, initiativeForm.whoText, initiativeForm.howText,
      initiativeForm.howMuchText,
    ]
    if (required5w2h.some((value) => value.trim().length < 3)) {
      setFormMessage({ type: 'error', text: 'Preencha todos os sete campos do 5W2H.' })
      return
    }
    if (initiativeForm.changeReason.trim().length < 10) {
      setFormMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' })
      return
    }
    if (initiativeForm.startDate && initiativeForm.dueDate && initiativeForm.dueDate < initiativeForm.startDate) {
      setFormMessage({ type: 'error', text: 'A data de término não pode ser anterior à data de início.' })
      return
    }

    setSavingInitiative(true)
    setFormMessage(null)
    const { data, error } = await supabase.rpc('create_skpe_initiative_v2', {
      target_project_id: projectId,
      initiative_code: initiativeForm.code.trim(),
      initiative_name: initiativeForm.name.trim(),
      initiative_description: initiativeForm.description.trim() || null,
      initiative_type: initiativeForm.initiativeType,
      initiative_priority: initiativeForm.priority,
      proposal_origin: initiativeForm.proposalOrigin,
      proposal_source_reference: initiativeForm.proposalSourceReference.trim() || null,
      responsible_area: initiativeForm.responsibleArea.trim() || null,
      owner_user_id: initiativeForm.ownerUserId || null,
      sponsor_user_id: null,
      start_date: initiativeForm.startDate || null,
      due_date: initiativeForm.dueDate || null,
      planned_cost: initiativeForm.plannedCost ? Number(initiativeForm.plannedCost.replace(',', '.')) : null,
      planned_benefit: initiativeForm.plannedBenefit ? Number(initiativeForm.plannedBenefit.replace(',', '.')) : null,
      strategic_theme: initiativeForm.strategicTheme.trim() || null,
      what_text: initiativeForm.whatText.trim(),
      why_text: initiativeForm.whyText.trim(),
      where_text: initiativeForm.whereText.trim(),
      when_text: initiativeForm.whenText.trim(),
      who_text: initiativeForm.whoText.trim(),
      how_text: initiativeForm.howText.trim(),
      how_much_text: initiativeForm.howMuchText.trim(),
      linked_journey_item_id: null,
      parent_initiative_id: null,
      change_reason: initiativeForm.changeReason.trim(),
    })
    if (error) {
      setFormMessage({ type: 'error', text: error.message })
      setSavingInitiative(false)
      return
    }
    const initiativeId = data as string
    const instrumentType = getRecommendedInstrumentType(initiativeForm.initiativeType)
    if (initiativeForm.createInstrument && instrumentType) {
      const instrumentResponse = await supabase.rpc('create_skpe_initiative_instrument', {
        target_initiative_id: initiativeId,
        target_instrument_type: instrumentType,
        target_instrument_code: `${initiativeForm.code.trim()}-${instrumentType.toUpperCase()}`,
        change_reason: initiativeForm.changeReason.trim(),
      })
      if (instrumentResponse.error) {
        setFormMessage({ type: 'error', text: 'A iniciativa foi criada, mas o instrumento não pôde ser criado: ' + instrumentResponse.error.message })
        await loadInitiatives()
        setSavingInitiative(false)
        return
      }
    }
    await loadInitiatives()
    resetInitiativeForm()
    setShowCreateForm(false)
    setSavingInitiative(false)
  }

  const areas = useMemo(
    () =>
      Array.from(
        new Set<string>(
          initiatives
            .map((initiative) => initiative.responsible_area)
            .filter(
              (value): value is string => Boolean(value),
            ),
        ),
      ).sort((firstArea, secondArea) =>
        firstArea.localeCompare(secondArea, 'pt-BR'),
      ),
    [initiatives],
  )

  const objectives = useMemo(() => {
    const map = new Map<string, InitiativeObjective>()
    for (const initiative of initiatives) for (const objective of initiative.strategic_objectives ?? []) map.set(objective.id, objective)
    return Array.from(map.values()).sort((a, b) => a.code.localeCompare(b.code, 'pt-BR'))
  }, [initiatives])

  const filteredInitiatives = useMemo(() => {
    const normalized = searchTerm.trim().toLowerCase()
    return initiatives.filter((initiative) => {
      const matchesSearch = !normalized || initiative.initiative_name.toLowerCase().includes(normalized) ||
        initiative.initiative_code.toLowerCase().includes(normalized) || (initiative.owner_name ?? '').toLowerCase().includes(normalized)
      const matchesQuickFilter =
        quickFilter === 'all' ||
        (quickFilter === 'in_progress' && initiative.initiative_status === 'in_progress') ||
        (quickFilter === 'delayed' && initiative.delayed) ||
        (quickFilter === 'critical' && initiative.priority === 'critical') ||
        (quickFilter === 'without_owner' && !initiative.owner_user_id) ||
        (quickFilter === 'with_instrument' && (initiative.instruments?.length ?? 0) > 0)
      return matchesSearch && matchesQuickFilter && (typeFilter === 'all' || initiative.initiative_type === typeFilter) &&
        (areaFilter === 'all' || initiative.responsible_area === areaFilter) &&
        (statusFilter === 'all' || initiative.initiative_status === statusFilter) &&
        (originFilter === 'all' || initiative.proposal_origin === originFilter) &&
        (validationFilter === 'all' || initiative.validation_status === validationFilter) &&
        (objectiveFilter === 'all' || (initiative.strategic_objectives ?? []).some((o) => o.id === objectiveFilter))
    })
  }, [initiatives, searchTerm, typeFilter, areaFilter, statusFilter, objectiveFilter, originFilter, validationFilter, quickFilter])

  const loadInitiatives = async () => {
    setLoading(true)
    setErrorMessage('')
    const dashboardFilters = {
      target_organization_id: organizationId,
      target_project_id: null,
      target_initiative_type: typeFilter === 'all' ? null : typeFilter,
      target_responsible_area: areaFilter === 'all' ? null : areaFilter,
      target_strategic_objective_id: objectiveFilter === 'all' ? null : objectiveFilter,
      target_status: statusFilter === 'all' ? null : statusFilter,
    }
    const listFilters = {
      ...dashboardFilters,
      target_key_result_id: null,
      target_validation_status: validationFilter === 'all' ? null : validationFilter,
      target_proposal_origin: originFilter === 'all' ? null : originFilter,
    }
    const [dashboardResponse, initiativesResponse] = await Promise.all([
      supabase.rpc('get_skpe_initiatives_dashboard', dashboardFilters),
      supabase.rpc('get_skpe_initiatives_v2', listFilters),
    ])
    if (dashboardResponse.error || initiativesResponse.error) {
      setErrorMessage((dashboardResponse.error ?? initiativesResponse.error)?.message ?? 'Não foi possível carregar as iniciativas.')
      setLoading(false)
      return
    }
    setDashboard(((dashboardResponse.data ?? [])[0] ?? null) as InitiativeDashboardRow | null)
    setInitiatives((initiativesResponse.data ?? []) as InitiativeRow[])
    setLoading(false)
  }

  useEffect(() => { void loadInitiativeSupportData() }, [organizationId])
  useEffect(() => { void loadInitiatives() }, [organizationId, typeFilter, areaFilter, objectiveFilter, statusFilter, originFilter, validationFilter])

  const openInstrument = (initiative: InitiativeRow) => {
    setSelectedInitiative(initiative)
    setShowInstrument(true)
  }

  const validateInitiative = async (initiative: InitiativeRow, targetStatus: string) => {
    if (validationReason.trim().length < 10) {
      window.alert('Informe uma justificativa com pelo menos 10 caracteres.')
      return
    }
    const { error } = await supabase.rpc('validate_skpe_initiative', {
      target_initiative_id: initiative.initiative_id,
      target_validation_status: targetStatus,
      validation_notes: validationNotes.trim() || null,
      replacement_initiative_id: null,
      change_reason: validationReason.trim(),
    })
    if (error) {
      window.alert(error.message)
      return
    }
    setValidationNotes('')
    setValidationReason('')
    await loadInitiatives()
  }

  const applyQuickFilter = (filter: string) => {
    setQuickFilter(filter)
    requestAnimationFrame(() => {
      document.getElementById('skpe-initiative-results')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
    })
  }

  return (
    <>
      <section className="skpe-page-heading skpe-administration-heading">
        <div>
          <p className="skpe-eyebrow">Execução da estratégia</p>
          <h1>Painel de Iniciativas</h1>
          <p>Acompanhe desempenho, origem, validação, 5W2H e vínculos com Objetivos Estratégicos — OKRs.</p>
        </div>
        <div className="skpe-heading-actions">
          {canManageInitiatives && (
            <button type="button" className="skpe-primary-action-button skpe-new-initiative-button" onClick={() => { resetInitiativeForm(); setShowCreateForm(true) }}>
              Nova iniciativa
            </button>
          )}
          <button type="button" className="skpe-refresh-button" onClick={() => void loadInitiatives()} disabled={loading}>
            <RefreshIcon /> Atualizar painel
          </button>
        </div>
      </section>

      {showCreateForm && (
        <section className="skpe-initiative-form-card">
          <div className="skpe-card-heading">
            <div><p className="skpe-card-code">Cadastro assistido</p><h2>Nova iniciativa com 5W2H</h2></div>
            <button type="button" className="skpe-user-details-button" onClick={() => { resetInitiativeForm(); setShowCreateForm(false) }} disabled={savingInitiative}>Fechar</button>
          </div>
          <div className="skpe-initiative-form-grid">
            <label><span>Código *</span><input value={initiativeForm.code} onChange={(e) => updateInitiativeForm('code', e.target.value)} placeholder="Ex.: IE-01" /></label>
            <label className="skpe-form-field-wide"><span>Nome da iniciativa *</span><input value={initiativeForm.name} onChange={(e) => updateInitiativeForm('name', e.target.value)} /></label>
            <label><span>Tipo *</span><select value={initiativeForm.initiativeType} onChange={(e) => updateInitiativeForm('initiativeType', e.target.value)}><option value="strategic_project">Projeto Estratégico</option><option value="operational_improvement">Melhoria Operacional</option><option value="process_initiative">Iniciativa de Processo</option><option value="simple_action">Ação Simples</option><option value="strategic_program">Programa Estratégico</option></select></label>
            <label><span>Origem *</span><select value={initiativeForm.proposalOrigin} onChange={(e) => updateInitiativeForm('proposalOrigin', e.target.value)}><option value="sparks_suggestion">Sugerida pela SPARKs</option><option value="organization">Criada pela organização</option><option value="joint_construction">Construída conjuntamente</option><option value="previous_plan">Importada de plano anterior</option><option value="assessment">Originada de diagnóstico</option><option value="action_plan">Originada de plano de ação</option><option value="bmc_vpc">Originada de BMC/VPC</option><option value="benchmark">Originada de benchmark</option></select></label>
            <label><span>Referência da origem</span><input value={initiativeForm.proposalSourceReference} onChange={(e) => updateInitiativeForm('proposalSourceReference', e.target.value)} placeholder="Ex.: DA 2026 — Critério 3.2" /></label>
            <label><span>Prioridade</span><select value={initiativeForm.priority} onChange={(e) => updateInitiativeForm('priority', e.target.value)}><option value="low">Baixa</option><option value="medium">Média</option><option value="high">Alta</option><option value="critical">Crítica</option></select></label>
            <label className="skpe-form-field-full"><span>Descrição</span><textarea value={initiativeForm.description} onChange={(e) => updateInitiativeForm('description', e.target.value)} /></label>
            <label><span>Área responsável</span><input value={initiativeForm.responsibleArea} onChange={(e) => updateInitiativeForm('responsibleArea', e.target.value)} /></label>
            <label><span>Responsável</span><select value={initiativeForm.ownerUserId} onChange={(e) => updateInitiativeForm('ownerUserId', e.target.value)}><option value="">Definir posteriormente</option>{ownerOptions.map((owner) => <option key={owner.userId} value={owner.userId}>{owner.label}</option>)}</select></label>
            <label><span>Data de início</span><input type="date" value={initiativeForm.startDate} onChange={(e) => updateInitiativeForm('startDate', e.target.value)} /></label>
            <label><span>Data de término</span><input type="date" value={initiativeForm.dueDate} onChange={(e) => updateInitiativeForm('dueDate', e.target.value)} /></label>
            <label><span>Custo planejado (R$)</span><input inputMode="decimal" value={initiativeForm.plannedCost} onChange={(e) => updateInitiativeForm('plannedCost', e.target.value)} /></label>
            <label><span>Benefício planejado (R$)</span><input inputMode="decimal" value={initiativeForm.plannedBenefit} onChange={(e) => updateInitiativeForm('plannedBenefit', e.target.value)} /></label>
            <label className="skpe-form-field-wide"><span>Tema estratégico</span><input value={initiativeForm.strategicTheme} onChange={(e) => updateInitiativeForm('strategicTheme', e.target.value)} /></label>
          </div>
          <div className="skpe-fivew2h-section">
            <div><p className="skpe-card-code">Padrão obrigatório</p><h3>5W2H da iniciativa</h3></div>
            <div className="skpe-fivew2h-grid">
              <label><span>O que será feito? *</span><textarea value={initiativeForm.whatText} onChange={(e) => updateInitiativeForm('whatText', e.target.value)} /></label>
              <label><span>Por que será feito? *</span><textarea value={initiativeForm.whyText} onChange={(e) => updateInitiativeForm('whyText', e.target.value)} /></label>
              <label><span>Onde será realizado? *</span><textarea value={initiativeForm.whereText} onChange={(e) => updateInitiativeForm('whereText', e.target.value)} /></label>
              <label><span>Quando será realizado? *</span><textarea value={initiativeForm.whenText} onChange={(e) => updateInitiativeForm('whenText', e.target.value)} /></label>
              <label><span>Quem será responsável? *</span><textarea value={initiativeForm.whoText} onChange={(e) => updateInitiativeForm('whoText', e.target.value)} /></label>
              <label><span>Como será realizado? *</span><textarea value={initiativeForm.howText} onChange={(e) => updateInitiativeForm('howText', e.target.value)} /></label>
              <label className="skpe-form-field-full"><span>Quanto custará e quais recursos serão necessários? *</span><textarea value={initiativeForm.howMuchText} onChange={(e) => updateInitiativeForm('howMuchText', e.target.value)} /></label>
            </div>
          </div>
          <div className="skpe-initiative-form-grid">
            <label className="skpe-form-field-full"><span>Justificativa para auditoria *</span><textarea value={initiativeForm.changeReason} onChange={(e) => updateInitiativeForm('changeReason', e.target.value)} /></label>
            <label className="skpe-initiative-checkbox skpe-form-field-full"><input type="checkbox" checked={initiativeForm.createInstrument} onChange={(e) => updateInitiativeForm('createInstrument', e.target.checked)} /><span>Criar também o instrumento recomendado para este tipo de iniciativa.</span></label>
          </div>
          {formMessage && <div className={`skpe-action-message skpe-action-message-${formMessage.type}`}>{formMessage.text}</div>}
          <div className="skpe-initiative-form-actions"><button type="button" className="skpe-primary-action-button" onClick={() => void handleCreateInitiative()} disabled={savingInitiative}>{savingInitiative ? 'Salvando...' : 'Salvar iniciativa'}</button></div>
        </section>
      )}

      {dashboard && (
        <section className="skpe-initiative-kpi-grid" aria-label="Filtros rápidos de iniciativas">
          <button type="button" className={quickFilter === 'all' ? 'skpe-initiative-kpi-active' : ''} onClick={() => applyQuickFilter('all')}><span>Total</span><strong>{dashboard.total_initiatives}</strong><small>Clique para ver todas</small></button>
          <button type="button" className={quickFilter === 'in_progress' ? 'skpe-initiative-kpi-active' : ''} onClick={() => applyQuickFilter('in_progress')}><span>Em execução</span><strong>{dashboard.in_progress_count}</strong><small>Clique para filtrar</small></button>
          <button type="button" className={quickFilter === 'delayed' ? 'skpe-initiative-kpi-active' : ''} onClick={() => applyQuickFilter('delayed')}><span>Atrasadas</span><strong>{dashboard.delayed_count}</strong><small>Clique para filtrar</small></button>
          <button type="button" className={quickFilter === 'critical' ? 'skpe-initiative-kpi-active' : ''} onClick={() => applyQuickFilter('critical')}><span>Críticas</span><strong>{dashboard.critical_count}</strong><small>Clique para filtrar</small></button>
          <button type="button" className={quickFilter === 'without_owner' ? 'skpe-initiative-kpi-active' : ''} onClick={() => applyQuickFilter('without_owner')}><span>Sem responsável</span><strong>{dashboard.without_owner_count}</strong><small>Clique para filtrar</small></button>
          <button type="button" className={quickFilter === 'with_instrument' ? 'skpe-initiative-kpi-active' : ''} onClick={() => applyQuickFilter('with_instrument')}><span>Com instrumento</span><strong>{dashboard.with_instrument_count}</strong><small>Clique para filtrar</small></button>
          <button type="button" onClick={() => applyQuickFilter('all')}><span>Progresso médio</span><strong>{dashboard.average_progress}%</strong><small>Ver painel completo</small></button>
          <button type="button" onClick={() => applyQuickFilter('all')}><span>Custo planejado</span><strong>{formatCurrency(dashboard.planned_cost)}</strong><small>Ver painel completo</small></button>
        </section>
      )}

      <section className="skpe-initiative-filters">
        <div className="skpe-admin-search"><SearchIcon /><input value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} placeholder="Buscar iniciativa" /></div>
        <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}><option value="all">Todos os tipos</option><option value="strategic_project">Projetos Estratégicos</option><option value="operational_improvement">Melhorias Operacionais</option><option value="process_initiative">Iniciativas de Processo</option><option value="simple_action">Ações Simples</option><option value="strategic_program">Programas Estratégicos</option></select>
        <select value={originFilter} onChange={(e) => setOriginFilter(e.target.value)}><option value="all">Todas as origens</option><option value="sparks_suggestion">Sugeridas pela SPARKs</option><option value="organization">Criadas pela organização</option><option value="joint_construction">Construídas conjuntamente</option><option value="assessment">Originadas de diagnóstico</option><option value="bmc_vpc">Originadas de BMC/VPC</option><option value="benchmark">Originadas de benchmark</option></select>
        <select value={validationFilter} onChange={(e) => setValidationFilter(e.target.value)}><option value="all">Todas as validações</option><option value="pending_validation">Pendentes de validação</option><option value="under_review">Em análise</option><option value="validated">Validadas</option><option value="validated_with_adjustments">Validadas com ajustes</option><option value="rejected">Rejeitadas</option></select>
        <select value={areaFilter} onChange={(e) => setAreaFilter(e.target.value)}><option value="all">Todas as áreas</option>{areas.map((area) => <option key={area} value={area}>{area}</option>)}</select>
        <select value={objectiveFilter} onChange={(e) => setObjectiveFilter(e.target.value)}><option value="all">Todos os Objetivos Estratégicos — OKRs</option>{objectives.map((objective) => <option key={objective.id} value={objective.id}>{objective.code} — {objective.name}</option>)}</select>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}><option value="all">Todas as situações</option><option value="proposed">Propostas</option><option value="in_progress">Em execução</option><option value="blocked">Bloqueadas</option><option value="completed">Concluídas</option></select>
      </section>

      <section id="skpe-initiative-results" className="skpe-initiative-results-heading">
        <div>
          <p className="skpe-card-code">Painel analítico</p>
          <h2>Iniciativas sinalizadas</h2>
          <span>{filteredInitiatives.length} iniciativa{filteredInitiatives.length === 1 ? '' : 's'} encontrada{filteredInitiatives.length === 1 ? '' : 's'}</span>
        </div>
        {quickFilter !== 'all' && <button type="button" className="skpe-user-details-button" onClick={() => setQuickFilter('all')}>Limpar filtro do cartão</button>}
      </section>

      {errorMessage && <div className="skpe-admin-message skpe-admin-message-error">{errorMessage}</div>}
      {loading ? <section className="skpe-admin-state-card"><p>Carregando iniciativas...</p></section> : filteredInitiatives.length === 0 ? <section className="skpe-admin-state-card"><h2>Nenhuma iniciativa encontrada</h2><p>Cadastre, importe ou ajuste os filtros.</p></section> : (
        <section className="skpe-initiative-list">
          {filteredInitiatives.map((initiative) => (
            <article key={initiative.initiative_id} className={`skpe-initiative-card ${initiative.instruments?.length > 0 ? 'skpe-interactive-record' : ''}`} role={initiative.instruments?.length > 0 ? 'button' : undefined} tabIndex={initiative.instruments?.length > 0 ? 0 : undefined} aria-label={initiative.instruments?.length > 0 ? `Abrir instrumento de ${initiative.initiative_name}` : undefined} onClick={() => { if (initiative.instruments?.length > 0) openInstrument(initiative) }} onKeyDown={(event) => { if (initiative.instruments?.length > 0) activateRecordWithKeyboard(event, () => openInstrument(initiative)) }}>
              <div className="skpe-initiative-card-main">
                <div className="skpe-initiative-card-heading">
                  <div><p>{initiative.initiative_code}</p><h2>{initiative.initiative_name}</h2></div>
                  <div className="skpe-initiative-badges">
                    <span className={`skpe-origin-badge skpe-origin-${initiative.proposal_origin}`}>{getProposalOriginLabel(initiative.proposal_origin)}</span>
                    <span className={`skpe-validation-badge skpe-validation-${initiative.validation_status}`}>{getValidationStatusLabel(initiative.validation_status)}</span>
                  </div>
                </div>
                <p className="skpe-initiative-description">{initiative.initiative_description ?? initiative.what_text}</p>
                <div className="skpe-initiative-meta"><span>{getInitiativeTypeLabel(initiative.initiative_type)}</span><span>{getInitiativeStatusLabel(initiative.initiative_status)}</span><span>Responsável: {initiative.owner_name ?? 'Não definido'}</span><span>Área: {initiative.responsible_area ?? 'Não definida'}</span></div>
                <div className="skpe-initiative-progress"><div className="skpe-progress-track"><span style={{ width: `${initiative.progress}%` }} /></div><strong>{initiative.progress}%</strong></div>
                <div className="skpe-fivew2h-summary"><strong>5W2H completo</strong><span>{initiative.five_w_two_h_completion}%</span></div>
                <details className="skpe-fivew2h-details"><summary>Consultar 5W2H</summary><dl><div><dt>O quê</dt><dd>{initiative.what_text}</dd></div><div><dt>Por quê</dt><dd>{initiative.why_text}</dd></div><div><dt>Onde</dt><dd>{initiative.where_text}</dd></div><div><dt>Quando</dt><dd>{initiative.when_text}</dd></div><div><dt>Quem</dt><dd>{initiative.who_text}</dd></div><div><dt>Como</dt><dd>{initiative.how_text}</dd></div><div><dt>Quanto</dt><dd>{initiative.how_much_text}</dd></div></dl></details>
                {(initiative.strategic_objectives?.length > 0 || initiative.key_results?.length > 0) && <div className="skpe-initiative-links"><strong>Conexão estratégica</strong>{initiative.strategic_objectives?.map((o) => <span key={o.id}>{o.code} — {o.name}</span>)}{initiative.key_results?.map((kr) => <span key={kr.id}>{kr.code} — {kr.name}</span>)}</div>}
              </div>
              <aside className="skpe-initiative-actions" onClick={(event) => event.stopPropagation()} onKeyDown={(event) => event.stopPropagation()}>
                {initiative.instruments?.length > 0 && <button type="button" className="skpe-primary-action-button" onClick={() => openInstrument(initiative)}>Abrir instrumento</button>}
                {canManageInitiatives && initiative.validation_status === 'pending_validation' && <div className="skpe-validation-panel"><textarea value={validationNotes} onChange={(e) => setValidationNotes(e.target.value)} placeholder="Observações da validação" /><textarea value={validationReason} onChange={(e) => setValidationReason(e.target.value)} placeholder="Justificativa para auditoria" /><button type="button" onClick={() => void validateInitiative(initiative, 'under_review')}>Colocar em análise</button><button type="button" onClick={() => void validateInitiative(initiative, 'validated')}>Validar</button><button type="button" onClick={() => void validateInitiative(initiative, 'validated_with_adjustments')}>Validar com ajustes</button><button type="button" onClick={() => void validateInitiative(initiative, 'rejected')}>Rejeitar</button></div>}
              </aside>
            </article>
          ))}
        </section>
      )}

      {showInstrument && selectedInitiative && selectedInitiative.instruments?.[0]?.reference_id && (
        <div className="skpe-initiative-instrument-modal"><div className="skpe-initiative-instrument-modal-content"><button type="button" className="skpe-user-details-button" onClick={() => setShowInstrument(false)}>Fechar</button><CanvasSection organizationId={organizationId} canManageCanvas={canManageCanvas} /></div></div>
      )}
    </>
  )
}


type OrganizationSectionProps = {
  organizationId: string
  canManageOrganization: boolean
  onProfileUpdated: (profile: OrganizationProfileRow, logoUrl: string | null) => void
}

function OrganizationSection({
  organizationId,
  canManageOrganization,
  onProfileUpdated,
}: OrganizationSectionProps) {
  const [profile, setProfile] = useState<OrganizationProfileRow | null>(null)
  const [form, setForm] = useState<OrganizationFormState>({
    legalName: '', tradeName: '', cnpj: '', institutionalEmail: '', phone: '', website: '',
    postalCode: '', street: '', addressNumber: '', addressComplement: '', district: '',
    city: '', stateCode: '', organizationType: 'cooperative', primaryActivityDescription: '', cnaesText: '', cooperativeBranch: '', organizationSize: '', changeReason: '',
  })
  const [logoUrl, setLogoUrl] = useState<string | null>(null)
  const [logoFile, setLogoFile] = useState<File | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<ActionMessage | null>(null)
  const [contacts, setContacts] = useState<OrganizationContactRow[]>([])
  const [contactForm, setContactForm] = useState<OrganizationContactForm>({ organizationPersonId: null, fullName: '', contactFunction: '', phone: '', mobilePhone: '', email: '', isPrimaryContact: false, changeReason: '' })
  const [savingContact, setSavingContact] = useState(false)
  const [selectedCnaes, setSelectedCnaes] = useState<SelectedCnae[]>([])
  const [legacyCnaes, setLegacyCnaes] = useState<OrganizationCnaeRow[]>([])
  const [cnaeSearch, setCnaeSearch] = useState('')
  const [cnaeResults, setCnaeResults] = useState<CnaeCatalogSearchRow[]>([])
  const [searchingCnaes, setSearchingCnaes] = useState(false)
  const [cnaeSearchError, setCnaeSearchError] = useState('')
  const [cnaeSourceType, setCnaeSourceType] = useState('manual_confirmed')
  const [cnaeSourceReference, setCnaeSourceReference] = useState('')

  const loadProfile = async () => {
    setLoading(true)
    setMessage(null)
    setSelectedCnaes([])
    setLegacyCnaes([])
    setCnaeSearch('')
    setCnaeResults([])
    setCnaeSearchError('')
    setCnaeSourceType('manual_confirmed')
    setCnaeSourceReference('')
    const { data, error } = await supabase.rpc('get_sparks_organization_profile_v2', {
      target_organization_id: organizationId,
    })
    if (error) {
      setMessage({ type: 'error', text: error.message })
      setLoading(false)
      return
    }
    const loaded = ((data ?? [])[0] ?? null) as OrganizationProfileRow | null
    setProfile(loaded)
    if (loaded) {
      setForm({
        legalName: loaded.legal_name ?? '',
        tradeName: loaded.trade_name ?? '',
        cnpj: formatCnpjInput(loaded.cnpj ?? loaded.formatted_cnpj ?? ''),
        institutionalEmail: loaded.institutional_email ?? '',
        phone: formatPhoneInput(loaded.phone ?? ''),
        website: loaded.website ?? '',
        postalCode: formatPostalCodeInput(loaded.postal_code ?? ''),
        street: loaded.street ?? '',
        addressNumber: loaded.address_number ?? '',
        addressComplement: loaded.address_complement ?? '',
        district: loaded.district ?? '',
        city: loaded.city ?? '',
        stateCode: loaded.state_code ?? '',
        organizationType: loaded.organization_type ?? 'cooperative',
        primaryActivityDescription: loaded.primary_activity_description ?? '',
        cnaesText: (loaded.economic_activities ?? []).map((item) => `${item.code} | ${item.description ?? ''}${item.is_primary ? ' | PRINCIPAL' : ''}`).join('\n'),
        cooperativeBranch: loaded.cooperative_branch ?? '',
        organizationSize: loaded.organization_size ?? '',
        changeReason: '',
      })
      let signedLogo: string | null = loaded.logo_url
      if (loaded.logo_storage_path) {
        const { data: signedData } = await supabase.storage
          .from('organization-branding')
          .createSignedUrl(loaded.logo_storage_path, 60 * 60)
        signedLogo = signedData?.signedUrl ?? loaded.logo_url
      }
      setLogoUrl(signedLogo)
      onProfileUpdated(loaded, signedLogo)
    }
    const cnaesResponse = await supabase.rpc('get_organization_cnaes_v3', {
      target_organization_id: organizationId,
    })

    if (cnaesResponse.error) {
      setMessage({
        type: 'error',
        text: `Cadastro carregado, mas nao foi possivel consultar os CNAEs: ${cnaesResponse.error.message}`,
      })
    } else {
      const cnaeRows = (cnaesResponse.data ?? []) as OrganizationCnaeRow[]
      const officialRows = cnaeRows.filter(
        (row) => row.is_official_catalog_entry && Boolean(row.cnae_catalog_id),
      )
      const unresolvedRows = cnaeRows.filter(
        (row) => !row.is_official_catalog_entry || !row.cnae_catalog_id,
      )

      setSelectedCnaes(
        officialRows.map((row) => ({
          cnaeCatalogId: row.cnae_catalog_id as string,
          versionCode: row.version_code ?? '2.3',
          subclassCode: row.subclass_code,
          formattedCode: row.formatted_code,
          description: row.description,
          sectionCode: null,
          sectionName: null,
          isPrimary: row.is_primary,
        })),
      )
      setLegacyCnaes(unresolvedRows)

      const primaryCnae = officialRows.find((row) => row.is_primary)
      if (primaryCnae) {
        setForm((current) => ({
          ...current,
          primaryActivityDescription: primaryCnae.description,
        }))
      }

      const sourceRow =
        officialRows.find((row) => row.is_primary) ??
        officialRows[0]

      if (sourceRow?.source_type) {
        setCnaeSourceType(sourceRow.source_type)
      }
      setCnaeSourceReference(sourceRow?.source_reference ?? '')
    }
    const contactsResponse = await supabase.rpc('get_sparks_organization_contacts', { target_organization_id: organizationId })
    if (!contactsResponse.error) setContacts((contactsResponse.data ?? []) as OrganizationContactRow[])
    setLoading(false)
  }

  useEffect(() => { void loadProfile() }, [organizationId])
  useEffect(() => {
    const term = cnaeSearch.trim()

    if (!canManageOrganization || term.length < 2) {
      setCnaeResults([])
      setCnaeSearchError('')
      setSearchingCnaes(false)
      return
    }

    let cancelled = false

    const timer = window.setTimeout(async () => {
      setSearchingCnaes(true)
      setCnaeSearchError('')

      const { data, error } = await supabase.rpc('search_cnae_catalog', {
        search_term: term,
        result_limit: 20,
        result_offset: 0,
      })

      if (cancelled) return

      if (error) {
        setCnaeResults([])
        setCnaeSearchError(error.message)
        setSearchingCnaes(false)
        return
      }

      const selectedIds = new Set(
        selectedCnaes.map((item) => item.cnaeCatalogId),
      )

      setCnaeResults(
        ((data ?? []) as CnaeCatalogSearchRow[]).filter(
          (item) => !selectedIds.has(item.cnae_catalog_id),
        ),
      )
      setSearchingCnaes(false)
    }, 300)

    return () => {
      cancelled = true
      window.clearTimeout(timer)
    }
  }, [cnaeSearch, canManageOrganization, selectedCnaes])

  const addCnae = (candidate: CnaeCatalogSearchRow) => {
    if (
      selectedCnaes.some(
        (item) => item.cnaeCatalogId === candidate.cnae_catalog_id,
      )
    ) {
      return
    }

    const isFirst = selectedCnaes.length === 0
    const next: SelectedCnae = {
      cnaeCatalogId: candidate.cnae_catalog_id,
      versionCode: candidate.version_code,
      subclassCode: candidate.subclass_code,
      formattedCode: candidate.formatted_code,
      description: candidate.description,
      sectionCode: candidate.section_code,
      sectionName: candidate.section_name,
      isPrimary: isFirst,
    }

    setSelectedCnaes((current) => [...current, next])
    setCnaeResults((current) =>
      current.filter(
        (item) => item.cnae_catalog_id !== candidate.cnae_catalog_id,
      ),
    )

    if (isFirst) {
      updateForm('primaryActivityDescription', candidate.description)
    }
  }

  const makePrimaryCnae = (cnaeCatalogId: string) => {
    const selected = selectedCnaes.find(
      (item) => item.cnaeCatalogId === cnaeCatalogId,
    )
    if (!selected) return

    setSelectedCnaes((current) =>
      current.map((item) => ({
        ...item,
        isPrimary: item.cnaeCatalogId === cnaeCatalogId,
      })),
    )
    updateForm('primaryActivityDescription', selected.description)
  }

  const removeCnae = (cnaeCatalogId: string) => {
    const removed = selectedCnaes.find(
      (item) => item.cnaeCatalogId === cnaeCatalogId,
    )
    const remaining = selectedCnaes.filter(
      (item) => item.cnaeCatalogId !== cnaeCatalogId,
    )

    if (removed?.isPrimary && remaining.length > 0) {
      remaining[0] = { ...remaining[0], isPrimary: true }
      updateForm('primaryActivityDescription', remaining[0].description)
    } else if (remaining.length === 0) {
      updateForm('primaryActivityDescription', '')
    }

    setSelectedCnaes(remaining)
  }

  const updateForm = <K extends keyof OrganizationFormState>(field: K, value: OrganizationFormState[K]) => {
    setForm((current) => ({ ...current, [field]: value }))
  }

  const saveProfile = async () => {
    if (!canManageOrganization) return
    if (!form.legalName.trim() || !form.tradeName.trim()) {
      setMessage({ type: 'error', text: 'Informe a Razão Social e o Nome Fantasia.' })
      return
    }
    if (form.changeReason.trim().length < 10) {
      setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' })
      return
    }
    if (legacyCnaes.length > 0) {
      setMessage({
        type: 'error',
        text: 'Existem CNAEs legados sem vinculo com o catalogo oficial. Substitua-os por CNAEs oficiais antes de salvar.',
      })
      return
    }
    if (
      selectedCnaes.length > 0 &&
      selectedCnaes.filter((item) => item.isPrimary).length !== 1
    ) {
      setMessage({
        type: 'error',
        text: 'Selecione exatamente um CNAE principal.',
      })
      return
    }
    setSaving(true)
    setMessage(null)
    let storagePath = profile?.logo_storage_path ?? null
    let uploadedLogoUrl = profile?.logo_url ?? null

    if (logoFile) {
      const extension = logoFile.name.split('.').pop()?.toLowerCase() || 'png'
      storagePath = `${organizationId}/logo/logo-institucional-${Date.now()}.${extension}`
      const { error: uploadError } = await supabase.storage
        .from('organization-branding')
        .upload(storagePath, logoFile, { upsert: true, contentType: logoFile.type })
      if (uploadError) {
        setMessage({ type: 'error', text: `Não foi possível enviar a logo: ${uploadError.message}` })
        setSaving(false)
        return
      }
      const { data: signedData } = await supabase.storage
        .from('organization-branding')
        .createSignedUrl(storagePath, 60 * 60)
      uploadedLogoUrl = signedData?.signedUrl ?? null
    }

    const primaryCnae = selectedCnaes.find((item) => item.isPrimary) ?? null
    const parsedCnaes = selectedCnaes.map((item) => ({
      code: item.subclassCode,
      description: item.description,
      is_primary: item.isPrimary,
    }))

    const { error } = await supabase.rpc('update_sparks_organization_profile_v2', {
      target_organization_id: organizationId,
      target_legal_name: form.legalName.trim(),
      target_trade_name: form.tradeName.trim(),
      target_cnpj: onlyDigits(form.cnpj),
      target_organization_type: form.organizationType,
      target_primary_activity_description: primaryCnae?.description ?? null,
      target_economic_activities: parsedCnaes,
      target_institutional_email: form.institutionalEmail.trim() || null,
      target_phone: onlyDigits(form.phone) || null,
      target_website: form.website.trim() || null,
      target_postal_code: onlyDigits(form.postalCode),
      target_street: form.street.trim() || null,
      target_address_number: form.addressNumber.trim() || null,
      target_address_complement: form.addressComplement.trim() || null,
      target_district: form.district.trim() || null,
      target_city: form.city.trim() || null,
      target_state_code: form.stateCode.trim().toUpperCase() || null,
      target_logo_url: null,
      target_logo_storage_path: storagePath,
      target_cooperative_branch: form.cooperativeBranch.trim() || null,
      target_organization_size: form.organizationSize || null,
      change_reason: form.changeReason.trim(),
    })
    if (error) {
      setMessage({ type: 'error', text: error.message })
      setSaving(false)
      return
    }
    const { error: cnaeError } = await supabase.rpc(
      'replace_organization_cnaes_v3',
      {
        target_organization_id: organizationId,
        selected_cnaes: selectedCnaes.map((item) => ({
          cnae_catalog_id: item.cnaeCatalogId,
          is_primary: item.isPrimary,
        })),
        target_source_type: cnaeSourceType,
        target_source_reference:
          cnaeSourceReference.trim() || null,
        change_reason: form.changeReason.trim(),
      },
    )

    if (cnaeError) {
      setMessage({
        type: 'error',
        text: `Os dados institucionais foram processados, mas os CNAEs oficiais nao puderam ser confirmados: ${cnaeError.message}`,
      })
      setSaving(false)
      return
    }
    setLogoFile(null)
    setMessage({ type: 'success', text: 'Cadastro institucional e CNAEs oficiais atualizados com sucesso.' })
    await loadProfile()
    if (uploadedLogoUrl) setLogoUrl(uploadedLogoUrl)
    setSaving(false)
  }

  const saveContact = async () => {
    if (!canManageOrganization) return
    if (contactForm.fullName.trim().length < 3) { setMessage({ type: 'error', text: 'Informe o nome do contato.' }); return }
    if (contactForm.changeReason.trim().length < 10) { setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' }); return }
    setSavingContact(true)
    const { error } = await supabase.rpc('upsert_sparks_organization_contact', {
      target_organization_id: organizationId,
      target_organization_person_id: contactForm.organizationPersonId,
      target_full_name: contactForm.fullName.trim(),
      target_contact_function: contactForm.contactFunction.trim() || null,
      target_phone: onlyDigits(contactForm.phone) || null,
      target_mobile_phone: onlyDigits(contactForm.mobilePhone) || null,
      target_email: contactForm.email.trim() || null,
      target_is_primary_contact: contactForm.isPrimaryContact,
      change_reason: contactForm.changeReason.trim(),
    })
    if (error) { setMessage({ type: 'error', text: error.message }); setSavingContact(false); return }
    setContactForm({ organizationPersonId: null, fullName: '', contactFunction: '', phone: '', mobilePhone: '', email: '', isPrimaryContact: false, changeReason: '' })
    setMessage({ type: 'success', text: 'Contato salvo com sucesso.' })
    await loadProfile()
    setSavingContact(false)
  }

  return (
    <>
      <section className="skpe-page-heading skpe-administration-heading">
        <div>
          <p className="skpe-eyebrow">Cadastro institucional compartilhado</p>
          <h1>Organização</h1>
          <p>Dados oficiais, endereço, contatos, caracterização cooperativista e identidade visual reutilizados por toda a Plataforma SPARKs.</p>
        </div>
        <button type="button" className="skpe-refresh-button" onClick={() => void loadProfile()} disabled={loading || saving}>
          <RefreshIcon /> Atualizar cadastro
        </button>
      </section>

      {loading ? (
        <section className="skpe-admin-state-card"><p>Carregando cadastro institucional...</p></section>
      ) : (
        <section className="skpe-organization-profile-layout">
          <aside className="skpe-organization-brand-card">
            <div className="skpe-organization-logo-preview">
              {logoUrl ? <img src={logoUrl} alt={`Logo de ${form.tradeName || form.legalName}`} /> : <span>{getOrganizationInitials(form.tradeName || form.legalName)}</span>}
            </div>
            <h2>{form.tradeName || 'Nome Fantasia'}</h2>
            <p>{form.legalName || 'Razão Social'}</p>
            <small>{form.cnpj || 'CNPJ não informado'}</small>
            {canManageOrganization && (
              <label className="skpe-logo-upload">
                <span>Selecionar logo</span>
                <input
                  type="file"
                  accept="image/png,image/jpeg,image/webp,image/svg+xml"
                  onChange={(event) => {
                    const file = event.target.files?.[0] ?? null
                    if (file && file.size > 5 * 1024 * 1024) {
                      setMessage({ type: 'error', text: 'A logo deve possuir no máximo 5 MB.' })
                      return
                    }
                    setLogoFile(file)
                    if (file) setLogoUrl(URL.createObjectURL(file))
                  }}
                />
              </label>
            )}
            <div className="skpe-organization-brand-note">A logo será apresentada no cabeçalho, relatórios, documentos e exportações da organização.</div>
          </aside>

          <div className="skpe-organization-form-card">
            <div className="skpe-organization-form-section">
              <div><p className="skpe-card-code">Identidade institucional</p><h2>Dados oficiais</h2></div>
              <div className="skpe-organization-form-grid">
                <label className="skpe-form-field-wide"><span>Razão Social *</span><input value={form.legalName} onChange={(e) => updateForm('legalName', e.target.value)} disabled={!canManageOrganization} /></label>
                <label className="skpe-form-field-wide"><span>Nome Fantasia *</span><input value={form.tradeName} onChange={(e) => updateForm('tradeName', e.target.value)} disabled={!canManageOrganization} /></label>
                <label className="skpe-organization-field-span-2"><span>CNPJ</span><input value={form.cnpj} onChange={(e) => updateForm('cnpj', formatCnpjInput(e.target.value))} placeholder="99.999.999/9999-99" disabled={!canManageOrganization} /></label>
                <label><span>Tipo de organização *</span><select value={form.organizationType} onChange={(e) => updateForm('organizationType', e.target.value)} disabled={!canManageOrganization}><option value="cooperative">Cooperativa</option><option value="industry">Indústria</option><option value="commerce">Comércio</option><option value="services">Serviços</option><option value="association">Associação</option><option value="foundation">Fundação</option><option value="public_body">Órgão público</option><option value="rural_producer">Produtor rural</option><option value="other">Outro</option></select></label>
                {form.organizationType === 'cooperative' && <label><span>Ramo cooperativo</span><input value={form.cooperativeBranch} onChange={(e) => updateForm('cooperativeBranch', e.target.value)} disabled={!canManageOrganization} /></label>}

                <label className="skpe-organization-field-span-full">
                  <span>Atividade principal</span>
                  <input
                    value={form.primaryActivityDescription}
                    readOnly
                    placeholder="Definida automaticamente pelo CNAE principal"
                    aria-readonly="true"
                  />
                  <small>A descrição é derivada do CNAE marcado como principal e não pode ser digitada livremente.</small>
                </label>

                <div className="skpe-cnae-manager skpe-form-field-full">
                  <div className="skpe-cnae-manager-heading">
                    <div>
                      <span>CNAEs oficiais</span>
                      <small>Catálogo CNAE-Subclasses 2.3 — IBGE/CONCLA</small>
                    </div>
                    <strong>{selectedCnaes.length} selecionado{selectedCnaes.length === 1 ? '' : 's'}</strong>
                  </div>

                  {canManageOrganization && (
                    <div className="skpe-cnae-search">
                      <label>
                        <span>Pesquisar por código ou atividade</span>
                        <input
                          value={cnaeSearch}
                          onChange={(event) => setCnaeSearch(event.target.value)}
                          placeholder="Ex.: 0111301, mandioca, horticultura"
                          role="combobox"
                          aria-expanded={cnaeResults.length > 0}
                          aria-controls="skpe-cnae-search-results"
                          autoComplete="off"
                        />
                      </label>

                      {searchingCnaes && (
                        <p className="skpe-cnae-search-status">
                          Pesquisando no catálogo oficial...
                        </p>
                      )}

                      {cnaeSearchError && (
                        <p className="skpe-cnae-search-error">
                          {cnaeSearchError}
                        </p>
                      )}

                      {cnaeResults.length > 0 && (
                        <div
                          id="skpe-cnae-search-results"
                          className="skpe-cnae-search-results"
                          role="listbox"
                        >
                          {cnaeResults.map((result) => (
                            <button
                              key={result.cnae_catalog_id}
                              type="button"
                              onClick={() => addCnae(result)}
                              role="option"
                            >
                              <strong>{result.formatted_code}</strong>
                              <span>{result.description}</span>
                              <small>
                                {result.section_code && result.section_name
                                  ? `${result.section_code} — ${result.section_name}`
                                  : 'CNAE-Subclasses 2.3'}
                              </small>
                            </button>
                          ))}
                        </div>
                      )}

                      {cnaeSearch.trim().length >= 2 &&
                        !searchingCnaes &&
                        !cnaeSearchError &&
                        cnaeResults.length === 0 && (
                          <p className="skpe-cnae-search-status">
                            Nenhum novo CNAE encontrado para esta pesquisa.
                          </p>
                        )}
                    </div>
                  )}

                  {legacyCnaes.length > 0 && (
                    <div className="skpe-cnae-legacy-warning">
                      <strong>CNAEs legados pendentes de saneamento</strong>
                      <p>
                        Estes registros não possuem vínculo com o catálogo oficial.
                        Pesquise e selecione os CNAEs equivalentes antes de salvar.
                      </p>
                      <ul>
                        {legacyCnaes.map((item) => (
                          <li key={item.organization_activity_id}>
                            {item.formatted_code} — {item.description}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}

                  <div className="skpe-cnae-selected-list">
                    {selectedCnaes.length === 0 ? (
                      <div className="skpe-cnae-empty">
                        Nenhum CNAE oficial selecionado.
                      </div>
                    ) : (
                      selectedCnaes.map((item) => (
                        <article
                          key={item.cnaeCatalogId}
                          className={item.isPrimary ? 'skpe-cnae-primary' : ''}
                        >
                          <label className="skpe-cnae-primary-control">
                            <input
                              type="radio"
                              name="primary-cnae"
                              checked={item.isPrimary}
                              onChange={() => makePrimaryCnae(item.cnaeCatalogId)}
                              disabled={!canManageOrganization}
                            />
                            <span>Principal</span>
                          </label>

                          <div className="skpe-cnae-selected-content">
                            <strong>{item.formattedCode}</strong>
                            <span>{item.description}</span>
                            <small>
                              Versão {item.versionCode}
                              {item.sectionCode && item.sectionName
                                ? ` · ${item.sectionCode} — ${item.sectionName}`
                                : ''}
                            </small>
                          </div>

                          {canManageOrganization && (
                            <button
                              type="button"
                              className="skpe-cnae-remove-button"
                              onClick={() => removeCnae(item.cnaeCatalogId)}
                              aria-label={`Remover CNAE ${item.formattedCode}`}
                            >
                              Remover
                            </button>
                          )}
                        </article>
                      ))
                    )}
                  </div>

                  {canManageOrganization && (
                    <div className="skpe-cnae-source-grid">
                      <label>
                        <span>Origem da confirmação</span>
                        <select
                          value={cnaeSourceType}
                          onChange={(event) => setCnaeSourceType(event.target.value)}
                        >
                          <option value="manual_confirmed">Confirmado pela organização</option>
                          <option value="official_cnpj">Comprovante oficial do CNPJ</option>
                          <option value="official_ibge">Base oficial IBGE/CONCLA</option>
                          <option value="official_document">Outro documento oficial</option>
                        </select>
                      </label>
                      <label>
                        <span>Referência da fonte</span>
                        <input
                          value={cnaeSourceReference}
                          onChange={(event) => setCnaeSourceReference(event.target.value)}
                          placeholder="Número, URL, documento ou observação"
                        />
                      </label>
                    </div>
                  )}
                </div>
                <label><span>Porte</span><select value={form.organizationSize} onChange={(e) => updateForm('organizationSize', e.target.value)} disabled={!canManageOrganization}><option value="">Não informado</option><option value="micro">Micro</option><option value="small">Pequeno</option><option value="medium">Médio</option><option value="large">Grande</option></select></label>
                <label className="skpe-organization-field-span-2"><span>E-mail institucional</span><input type="email" value={form.institutionalEmail} onChange={(e) => updateForm('institutionalEmail', e.target.value)} disabled={!canManageOrganization} /></label>
                <label><span>Telefone</span><input value={form.phone} onChange={(e) => updateForm('phone', formatPhoneInput(e.target.value))} placeholder="(99) 9999-9999" disabled={!canManageOrganization} /></label>
                <label className="skpe-organization-field-span-2"><span>Site</span><input value={form.website} onChange={(e) => updateForm('website', e.target.value)} placeholder="https://" disabled={!canManageOrganization} /></label>
              </div>
            </div>

            <div className="skpe-organization-form-section">
              <div><p className="skpe-card-code">Localização</p><h2>Endereço completo</h2></div>
              <div className="skpe-organization-form-grid">
                <label><span>CEP</span><input value={form.postalCode} onChange={(e) => updateForm('postalCode', formatPostalCodeInput(e.target.value))} placeholder="99999-999" disabled={!canManageOrganization} /></label>
                <label className="skpe-form-field-wide"><span>Logradouro</span><input value={form.street} onChange={(e) => updateForm('street', e.target.value)} disabled={!canManageOrganization} /></label>
                <label><span>Número</span><input value={form.addressNumber} onChange={(e) => updateForm('addressNumber', e.target.value)} disabled={!canManageOrganization} /></label>
                <label className="skpe-form-field-wide"><span>Complemento</span><input value={form.addressComplement} onChange={(e) => updateForm('addressComplement', e.target.value)} disabled={!canManageOrganization} /></label>
                <label><span>Bairro</span><input value={form.district} onChange={(e) => updateForm('district', e.target.value)} disabled={!canManageOrganization} /></label>
                <label><span>Município</span><input value={form.city} onChange={(e) => updateForm('city', e.target.value)} disabled={!canManageOrganization} /></label>
                <label><span>UF</span><input maxLength={2} value={form.stateCode} onChange={(e) => updateForm('stateCode', e.target.value.toUpperCase())} disabled={!canManageOrganization} /></label>
              </div>
            </div>

            <div className="skpe-organization-form-section">
              <div><p className="skpe-card-code">Relacionamento institucional</p><h2>Contatos da organização</h2><p className="skpe-card-description">Fonte integrada de pessoas para uso futuro pelo SK-ASM e pelo CRM.</p></div>
              <div className="skpe-contact-list">
                {contacts.map((contact) => <article key={contact.organization_person_id}>
                  <div><strong>{contact.full_name}</strong><span>{contact.contact_function ?? 'Função não informada'}</span></div>
                  <div><span>{contact.phone ? formatPhoneInput(contact.phone) : 'Sem telefone'}</span><span>{contact.mobile_phone ? formatMobilePhoneInput(contact.mobile_phone) : 'Sem celular'}</span><span>{contact.email ?? 'Sem e-mail'}</span></div>
                  {contact.is_primary_contact && <b>Contato principal</b>}
                  {canManageOrganization && <button type="button" className="skpe-user-details-button" onClick={() => setContactForm({ organizationPersonId: contact.organization_person_id, fullName: contact.full_name, contactFunction: contact.contact_function ?? '', phone: formatPhoneInput(contact.phone ?? ''), mobilePhone: formatMobilePhoneInput(contact.mobile_phone ?? ''), email: contact.email ?? '', isPrimaryContact: contact.is_primary_contact, changeReason: '' })}>Editar</button>}
                </article>)}
              </div>
              {canManageOrganization && <div className="skpe-contact-form">
                <label><span>Nome *</span><input value={contactForm.fullName} onChange={(e) => setContactForm((c) => ({ ...c, fullName: e.target.value }))} /></label>
                <label><span>Função</span><input value={contactForm.contactFunction} onChange={(e) => setContactForm((c) => ({ ...c, contactFunction: e.target.value }))} /></label>
                <label><span>Telefone</span><input value={contactForm.phone} onChange={(e) => setContactForm((c) => ({ ...c, phone: formatPhoneInput(e.target.value) }))} placeholder="(99) 9999-9999" /></label>
                <label><span>Celular</span><input value={contactForm.mobilePhone} onChange={(e) => setContactForm((c) => ({ ...c, mobilePhone: formatMobilePhoneInput(e.target.value) }))} placeholder="(99) 9 9999-9999" /></label>
                <label><span>E-mail</span><input type="email" value={contactForm.email} onChange={(e) => setContactForm((c) => ({ ...c, email: e.target.value }))} /></label>
                <label className="skpe-contact-primary"><input type="checkbox" checked={contactForm.isPrimaryContact} onChange={(e) => setContactForm((c) => ({ ...c, isPrimaryContact: e.target.checked }))} /><span>Contato principal</span></label>
                <label className="skpe-form-field-full"><span>Justificativa *</span><textarea value={contactForm.changeReason} onChange={(e) => setContactForm((c) => ({ ...c, changeReason: e.target.value }))} /></label>
                <button type="button" className="skpe-primary-action-button" onClick={() => void saveContact()} disabled={savingContact}>{savingContact ? 'Salvando...' : contactForm.organizationPersonId ? 'Atualizar contato' : 'Adicionar contato'}</button>
              </div>}
            </div>

            {canManageOrganization && (
              <div className="skpe-organization-form-section">
                <label className="skpe-form-field-full"><span>Justificativa para auditoria *</span><textarea value={form.changeReason} onChange={(e) => updateForm('changeReason', e.target.value)} placeholder="Registre o motivo da inclusão ou alteração dos dados institucionais." /></label>
                {message && <div className={`skpe-action-message skpe-action-message-${message.type}`}>{message.text}</div>}
                <button type="button" className="skpe-primary-action-button skpe-save-organization-button" onClick={() => void saveProfile()} disabled={saving}>{saving ? 'Salvando...' : 'Salvar cadastro institucional'}</button>
              </div>
            )}
            {!canManageOrganization && message && <div className={`skpe-action-message skpe-action-message-${message.type}`}>{message.text}</div>}
          </div>
        </section>
      )}
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



type GovernanceDashboardRow = {
  active_people: number
  active_roles: number
  people_with_roles: number
  active_responsibilities: number
  objects_with_responsibility: number
  objects_without_owner: number
  expired_responsibilities: number
  delegated_responsibilities: number
}

type GovernancePersonRow = {
  organization_person_id: string
  person_id: string
  full_name: string
  preferred_name: string | null
  relationship_type: string
  job_title: string | null
  organizational_area: string | null
  organizational_unit: string | null
  is_director: boolean
  is_board_member: boolean
  is_committee_member: boolean
  relationship_status: string
  active_role_count: number
  active_responsibility_count: number
}

type PersonRoleAssignmentRow = {
  assignment_id: string
  organization_person_id: string
  person_name: string
  role_id: string
  role_name: string
  organizational_area: string | null
  mandate_start_date: string | null
  mandate_end_date: string | null
  indefinite_term: boolean
  assignment_status: string
  appointment_document_reference: string | null
  appointment_document_id: string | null
  document_code: string | null
  document_title: string | null
  document_file_name: string | null
  document_source: string | null
  document_status: string | null
  created_at: string
  registered_by: string | null
}

type OrganizationalRoleRow = {
  role_id: string
  role_code: string
  role_name: string
  role_type: string
  description: string | null
  organizational_area: string | null
  authority_level: string | null
  is_governance_role: boolean
  requires_mandate: boolean
  active: boolean
  active_assignment_count: number
}

type ResponsibilityAssignmentRow = {
  assignment_id: string
  object_type: string
  object_id: string
  responsibility_type: string
  organization_person_id: string
  person_id: string
  person_name: string
  job_title: string | null
  organizational_area: string | null
  allocation_percentage: number | null
  authority_level: string | null
  valid_from: string | null
  valid_until: string | null
  status: string
  assignment_source: string
  assignment_reason: string | null
  delegated: boolean
  delegated_until: string | null
}

type DomainValueRow = {
  domain_code: string
  domain_name: string
  domain_scope: string
  allow_organization_extension: boolean
  value_id: string
  value_code: string
  value_name: string
  value_description: string | null
  display_order: number
  color_token: string | null
  icon_name: string | null
  active: boolean
  protected: boolean
}

type GovernanceOperationsSectionProps = {
  organizationId: string
  canManageGovernance: boolean
}

const governanceDomainCodes = [
  'RESPONSIBILITY_TYPE',
  'ORGANIZATIONAL_ROLE_TYPE',
  'AUTHORITY_LEVEL',
  'STRATEGIC_OBJECT_TYPE',
] as const

function GovernanceOperationsSection({
  organizationId,
  canManageGovernance,
}: GovernanceOperationsSectionProps) {
  const [dashboard, setDashboard] = useState<GovernanceDashboardRow | null>(null)
  const [people, setPeople] = useState<GovernancePersonRow[]>([])
  const [roles, setRoles] = useState<OrganizationalRoleRow[]>([])
  const [roleAssignments, setRoleAssignments] = useState<PersonRoleAssignmentRow[]>([])
  const [responsibilities, setResponsibilities] = useState<ResponsibilityAssignmentRow[]>([])
  const [domains, setDomains] = useState<Record<string, DomainValueRow[]>>({})
  const [loading, setLoading] = useState(true)
  const [message, setMessage] = useState<ActionMessage | null>(null)
  const [activePanel, setActivePanel] = useState<'people' | 'roles' | 'responsibilities'>('people')
  const [saving, setSaving] = useState(false)
  const [governanceViewMode, setGovernanceViewMode] = useState<'cards' | 'grid'>('cards')
  const [governanceSearch, setGovernanceSearch] = useState('')
  const [governanceSortDirection, setGovernanceSortDirection] = useState<'asc' | 'desc'>('asc')
  const [roleForm, setRoleForm] = useState({ id: null as string | null, code: '', name: '', roleType: 'function', description: '', area: '', authorityLevel: 'operational', governance: false, mandate: false, active: true, reason: '' })
  const [assignmentForm, setAssignmentForm] = useState({ personId: '', roleId: '', startDate: '', endDate: '', indefiniteTerm: true, documentReference: '', notes: '', reason: '' })
  const [responsibilityForm, setResponsibilityForm] = useState({ objectType: 'strategic_project', objectId: '', personId: '', responsibilityType: 'owner', allocation: '100', authorityLevel: 'operational', validFrom: '', validUntil: '', assignmentReason: '', reason: '' })

  const normalizedGovernanceSearch = governanceSearch.trim().toLocaleLowerCase('pt-BR')
  const sortByName = <T,>(items: T[], getName: (item: T) => string) =>
    [...items].sort((first, second) => {
      const comparison = getName(first).localeCompare(getName(second), 'pt-BR')
      return governanceSortDirection === 'asc' ? comparison : -comparison
    })
  const visiblePeople = sortByName(people.filter((person) => !normalizedGovernanceSearch || [person.full_name, person.preferred_name, person.job_title, person.organizational_area].filter(Boolean).some((value) => String(value).toLocaleLowerCase('pt-BR').includes(normalizedGovernanceSearch))), (person) => person.preferred_name ?? person.full_name)
  const visibleRoles = sortByName(roles.filter((role) => !normalizedGovernanceSearch || [role.role_name, role.role_code, role.description, role.organizational_area].filter(Boolean).some((value) => String(value).toLocaleLowerCase('pt-BR').includes(normalizedGovernanceSearch))), (role) => role.role_name)
  const visibleResponsibilities = sortByName(responsibilities.filter((assignment) => !normalizedGovernanceSearch || [assignment.person_name, assignment.object_type, assignment.responsibility_type, assignment.organizational_area].filter(Boolean).some((value) => String(value).toLocaleLowerCase('pt-BR').includes(normalizedGovernanceSearch))), (assignment) => assignment.person_name)

  const loadGovernance = async () => {
    setLoading(true)
    setMessage(null)
    const domainRequests = governanceDomainCodes.map((domainCode) =>
      supabase.rpc('get_sparks_domain_values', {
        target_domain_code: domainCode,
        target_organization_id: organizationId,
        target_module_code: 'SK-PE',
        include_inactive: false,
      }),
    )
    const [dashboardResponse, peopleResponse, rolesResponse, roleAssignmentsResponse, responsibilitiesResponse, ...domainResponses] = await Promise.all([
      supabase.rpc('get_skpe_governance_dashboard', { target_organization_id: organizationId }),
      supabase.rpc('get_skpe_governance_people', { target_organization_id: organizationId }),
      supabase.rpc('get_skpe_organizational_roles', { target_organization_id: organizationId }),
      supabase.rpc('get_skpe_person_role_assignments', { target_organization_id: organizationId, include_inactive: false }),
      supabase.rpc('get_skpe_responsibility_assignments', { target_organization_id: organizationId, target_object_type: null, target_object_id: null, include_inactive: false }),
      ...domainRequests,
    ])
    const firstError = [dashboardResponse, peopleResponse, rolesResponse, roleAssignmentsResponse, responsibilitiesResponse, ...domainResponses].find((response) => response.error)?.error
    if (firstError) {
      setMessage({ type: 'error', text: firstError.message })
      setLoading(false)
      return
    }
    setDashboard(((dashboardResponse.data ?? [])[0] ?? null) as GovernanceDashboardRow | null)
    setPeople((peopleResponse.data ?? []) as GovernancePersonRow[])
    setRoles((rolesResponse.data ?? []) as OrganizationalRoleRow[])
    setRoleAssignments((roleAssignmentsResponse.data ?? []) as PersonRoleAssignmentRow[])
    setResponsibilities((responsibilitiesResponse.data ?? []) as ResponsibilityAssignmentRow[])
    const nextDomains: Record<string, DomainValueRow[]> = {}
    governanceDomainCodes.forEach((domainCode, index) => {
      nextDomains[domainCode] = (domainResponses[index]?.data ?? []) as DomainValueRow[]
    })
    setDomains(nextDomains)
    setLoading(false)
  }

  useEffect(() => { void loadGovernance() }, [organizationId])

  const selectPersonForAssignment = (person: GovernancePersonRow) => {
    setAssignmentForm((current) => ({
      ...current,
      personId: person.organization_person_id,
    }))
    window.requestAnimationFrame(() => {
      document
        .getElementById('skpe-role-assignment-form')
        ?.scrollIntoView({ behavior: 'smooth', block: 'center' })
    })
  }

  const openRoleMaintenance = (role: OrganizationalRoleRow) => {
    setRoleForm({
      id: role.role_id,
      code: role.role_code,
      name: role.role_name,
      roleType: role.role_type,
      description: role.description ?? '',
      area: role.organizational_area ?? '',
      authorityLevel: role.authority_level ?? 'operational',
      governance: role.is_governance_role,
      mandate: role.requires_mandate,
      active: role.active,
      reason: '',
    })
    window.requestAnimationFrame(() => {
      document
        .getElementById('skpe-role-maintenance-form')
        ?.scrollIntoView({ behavior: 'smooth', block: 'center' })
    })
  }

  const resetRoleForm = () => {
    setRoleForm({ id: null, code: '', name: '', roleType: 'function', description: '', area: '', authorityLevel: 'operational', governance: false, mandate: false, active: true, reason: '' })
  }

  const createRole = async () => {
    if (!roleForm.code.trim() || !roleForm.name.trim()) {
      setMessage({ type: 'error', text: 'Informe o código e o nome do papel organizacional.' })
      return
    }
    if (roleForm.reason.trim().length < 10) {
      setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' })
      return
    }
    setSaving(true)
    const { error } = await supabase.rpc('upsert_skpe_organizational_role', {
      target_organization_id: organizationId,
      target_role_id: roleForm.id,
      target_code: roleForm.code,
      target_name: roleForm.name,
      target_role_type: roleForm.roleType,
      target_description: roleForm.description || null,
      target_organizational_area: roleForm.area || null,
      target_authority_level: roleForm.authorityLevel || null,
      target_is_governance_role: roleForm.governance,
      target_requires_mandate: roleForm.mandate,
      target_active: roleForm.active,
      change_reason: roleForm.reason,
    })
    if (error) setMessage({ type: 'error', text: error.message })
    else {
      setMessage({ type: 'success', text: roleForm.id ? 'Papel organizacional atualizado com sucesso.' : 'Papel organizacional criado com sucesso.' })
      resetRoleForm()
      await loadGovernance()
    }
    setSaving(false)
  }

  const assignRole = async () => {
    if (!assignmentForm.personId || !assignmentForm.roleId) {
      setMessage({ type: 'error', text: 'Selecione a pessoa e o papel organizacional.' })
      return
    }
    if (assignmentForm.reason.trim().length < 10) {
      setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' })
      return
    }
    setSaving(true)
    const { error } = await supabase.rpc('assign_skpe_person_role', {
      target_organization_id: organizationId,
      target_organization_person_id: assignmentForm.personId,
      target_organizational_role_id: assignmentForm.roleId,
      target_mandate_start_date: assignmentForm.startDate || null,
      target_mandate_end_date: assignmentForm.indefiniteTerm ? null : (assignmentForm.endDate || null),
      target_appointment_document_reference: assignmentForm.documentReference || null,
      target_notes: assignmentForm.notes || null,
      change_reason: assignmentForm.reason,
    })
    if (error) setMessage({ type: 'error', text: error.message })
    else {
      setMessage({ type: 'success', text: assignmentForm.documentReference.trim() ? 'Papel atribuído e referência do documento formal registrada.' : 'Papel atribuído e Termo de Registro de Designação gerado no acervo documental.' })
      setAssignmentForm({ personId: '', roleId: '', startDate: '', endDate: '', indefiniteTerm: true, documentReference: '', notes: '', reason: '' })
      await loadGovernance()
    }
    setSaving(false)
  }

  const assignResponsibility = async () => {
    if (!responsibilityForm.personId || !responsibilityForm.objectId.trim()) {
      setMessage({ type: 'error', text: 'Selecione a pessoa e informe o identificador do objeto estratégico.' })
      return
    }
    if (responsibilityForm.reason.trim().length < 10) {
      setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' })
      return
    }
    setSaving(true)
    const { error } = await supabase.rpc('assign_skpe_responsibility', {
      target_organization_id: organizationId,
      target_object_type: responsibilityForm.objectType,
      target_object_id: responsibilityForm.objectId.trim(),
      target_organization_person_id: responsibilityForm.personId,
      target_responsibility_type: responsibilityForm.responsibilityType,
      target_allocation_percentage: responsibilityForm.allocation ? Number(responsibilityForm.allocation) : null,
      target_authority_level: responsibilityForm.authorityLevel || null,
      target_valid_from: responsibilityForm.validFrom || null,
      target_valid_until: responsibilityForm.validUntil || null,
      target_assignment_reason: responsibilityForm.assignmentReason || null,
      change_reason: responsibilityForm.reason,
    })
    if (error) setMessage({ type: 'error', text: error.message })
    else {
      setMessage({ type: 'success', text: 'Responsabilidade estratégica atribuída com sucesso.' })
      setResponsibilityForm({ objectType: 'strategic_project', objectId: '', personId: '', responsibilityType: 'owner', allocation: '100', authorityLevel: 'operational', validFrom: '', validUntil: '', assignmentReason: '', reason: '' })
      await loadGovernance()
    }
    setSaving(false)
  }

  const endResponsibility = async (assignment: ResponsibilityAssignmentRow) => {
    const reason = window.prompt(`Informe a justificativa para encerrar a responsabilidade de ${assignment.person_name}.`)
    if (!reason || reason.trim().length < 10) return
    const { error } = await supabase.rpc('end_skpe_responsibility', { target_assignment_id: assignment.assignment_id, target_end_date: new Date().toISOString().slice(0, 10), change_reason: reason.trim() })
    if (error) setMessage({ type: 'error', text: error.message })
    else await loadGovernance()
  }

  const openDesignationDocument = async (documentId: string) => {
    const { data, error } = await supabase.rpc('get_sparks_document_record', {
      target_document_id: documentId,
    })
    if (error) {
      setMessage({ type: 'error', text: error.message })
      return
    }
    const documentRecord = ((data ?? [])[0] ?? null) as { content_html: string | null; file_name: string; title: string } | null
    if (!documentRecord?.content_html) {
      setMessage({ type: 'error', text: 'O conteúdo do documento não está disponível.' })
      return
    }
    const documentWindow = window.open('', '_blank', 'noopener,noreferrer')
    if (!documentWindow) {
      setMessage({ type: 'error', text: 'O navegador bloqueou a abertura do documento. Autorize pop-ups para esta aplicação.' })
      return
    }
    documentWindow.document.open()
    documentWindow.document.write(documentRecord.content_html)
    documentWindow.document.close()
    documentWindow.document.title = documentRecord.title
  }

  const domainOptions = (code: string) => domains[code] ?? []

  return (
    <>
      <section className="skpe-page-heading skpe-administration-heading">
        <div><p className="skpe-eyebrow">Governança operacional</p><h1>Papéis e responsabilidades</h1><p>Defina quem exerce papéis organizacionais e quem responde, aprova, valida, executa ou acompanha cada objeto estratégico.</p></div>
        <button type="button" className="skpe-refresh-button" onClick={() => void loadGovernance()} disabled={loading}><RefreshIcon />Atualizar governança</button>
      </section>

      {dashboard && <section className="skpe-governance-kpi-grid">
        <article><span>Pessoas ativas</span><strong>{dashboard.active_people}</strong><small>{dashboard.people_with_roles} com papel atribuído</small></article>
        <article><span>Papéis ativos</span><strong>{dashboard.active_roles}</strong><small>Funções e designações vigentes</small></article>
        <article><span>Responsabilidades</span><strong>{dashboard.active_responsibilities}</strong><small>{dashboard.objects_with_responsibility} objetos cobertos</small></article>
        <article className={dashboard.objects_without_owner > 0 ? 'skpe-governance-alert-card' : ''}><span>Sem responsável</span><strong>{dashboard.objects_without_owner}</strong><small>Objetos com lacuna de titularidade</small></article>
      </section>}

      <div className="skpe-governance-tabs">
        <button type="button" className={activePanel === 'people' ? 'skpe-governance-tab-active' : ''} onClick={() => setActivePanel('people')}>Pessoas e vínculos</button>
        <button type="button" className={activePanel === 'roles' ? 'skpe-governance-tab-active' : ''} onClick={() => setActivePanel('roles')}>Papéis organizacionais</button>
        <button type="button" className={activePanel === 'responsibilities' ? 'skpe-governance-tab-active' : ''} onClick={() => setActivePanel('responsibilities')}>Matriz de responsabilidades</button>
      </div>

      <section className="skpe-primary-list-toolbar">
        <div className="skpe-admin-search"><SearchIcon /><input type="search" value={governanceSearch} onChange={(event) => setGovernanceSearch(event.target.value)} placeholder="Pesquisar pessoas, papéis ou responsabilidades" /></div>
        <button type="button" className="skpe-list-sort-button" onClick={() => setGovernanceSortDirection((current) => current === 'asc' ? 'desc' : 'asc')} title="Alterar ordenação alfabética">{governanceSortDirection === 'asc' ? 'A → Z' : 'Z → A'}</button>
        <div className="skpe-list-view-toggle" aria-label="Modo de visualização"><button type="button" className={governanceViewMode === 'cards' ? 'active' : ''} onClick={() => setGovernanceViewMode('cards')} title="Visualizar em cards">▦</button><button type="button" className={governanceViewMode === 'grid' ? 'active' : ''} onClick={() => setGovernanceViewMode('grid')} title="Visualizar em linhas">☷</button></div>
      </section>

      {message && <div className={`skpe-action-message skpe-action-message-${message.type}`}>{message.text}</div>}
      {loading ? <section className="skpe-admin-state-card"><p>Carregando a governança operacional...</p></section> : activePanel === 'people' ? (
        <section className="skpe-governance-list-card">
          <div className="skpe-user-table-header"><div><h2>Pessoas integradas</h2><p>Fonte única de pessoas vinculadas à organização.</p></div></div>
          <div className={`skpe-governance-card-grid ${governanceViewMode === 'grid' ? 'skpe-governance-row-grid' : ''}`}>{visiblePeople.map((person) => <article key={person.organization_person_id} className="skpe-interactive-record" role="button" tabIndex={0} aria-label={`Selecionar ${person.preferred_name ?? person.full_name} para manutenção`} onClick={() => selectPersonForAssignment(person)} onKeyDown={(event) => activateRecordWithKeyboard(event, () => selectPersonForAssignment(person))}><div><strong>{person.preferred_name ?? person.full_name}</strong><span>{person.job_title ?? person.relationship_type}</span><small>{person.organizational_area ?? 'Área não definida'}</small></div><div className="skpe-governance-counts"><b>{person.active_role_count} papéis</b><b>{person.active_responsibility_count} responsabilidades</b></div></article>)}</div>
          {canManageGovernance && <div id="skpe-role-assignment-form" className="skpe-governance-form"><h3>Atribuir papel a uma pessoa</h3><label><span>Pessoa</span><select value={assignmentForm.personId} onChange={(event) => setAssignmentForm((current) => ({ ...current, personId: event.target.value }))}><option value="">Selecione</option>{visiblePeople.map((person) => <option key={person.organization_person_id} value={person.organization_person_id}>{person.preferred_name ?? person.full_name}</option>)}</select></label><label><span>Papel</span><select value={assignmentForm.roleId} onChange={(event) => setAssignmentForm((current) => ({ ...current, roleId: event.target.value }))}><option value="">Selecione</option>{roles.filter((role) => role.active).map((role) => <option key={role.role_id} value={role.role_id}>{role.role_name}</option>)}</select></label><label><span>Início do mandato</span><input type="date" value={assignmentForm.startDate} onChange={(event) => setAssignmentForm((current) => ({ ...current, startDate: event.target.value }))} /></label><label><span>Término do mandato</span><input type="date" value={assignmentForm.endDate} disabled={assignmentForm.indefiniteTerm} onChange={(event) => setAssignmentForm((current) => ({ ...current, endDate: event.target.value }))} /><small>{assignmentForm.indefiniteTerm ? 'Vigência por prazo indeterminado.' : 'Informe a data formal de encerramento.'}</small></label><label className="skpe-governance-check"><input type="checkbox" checked={assignmentForm.indefiniteTerm} onChange={(event) => setAssignmentForm((current) => ({ ...current, indefiniteTerm: event.target.checked, endDate: event.target.checked ? '' : current.endDate }))} /><span>Mandato por prazo indeterminado</span></label><label className="skpe-form-field-wide"><span>Documento formal de designação (opcional)</span><input value={assignmentForm.documentReference} onChange={(event) => setAssignmentForm((current) => ({ ...current, documentReference: event.target.value }))} placeholder="Ata, resolução, portaria, termo de posse ou referência do arquivo" /><small>Deixe em branco para gerar automaticamente um Termo de Registro de Designação no acervo documental.</small></label><label className="skpe-form-field-wide"><span>Observações</span><textarea value={assignmentForm.notes} onChange={(event) => setAssignmentForm((current) => ({ ...current, notes: event.target.value }))} /></label><label className="skpe-form-field-wide"><span>Justificativa para auditoria *</span><textarea value={assignmentForm.reason} onChange={(event) => setAssignmentForm((current) => ({ ...current, reason: event.target.value }))} /></label><button type="button" className="skpe-primary-action-button" onClick={() => void assignRole()} disabled={saving}>Atribuir papel</button></div>}
          <div className="skpe-designation-archive"><div className="skpe-user-table-header"><div><h2>Registros de designação</h2><p>Documentos formais referenciados e termos gerados automaticamente.</p></div></div>{roleAssignments.length === 0 ? <p className="skpe-designation-empty">Nenhuma designação registrada.</p> : <div className={`skpe-governance-card-grid ${governanceViewMode === 'grid' ? 'skpe-governance-row-grid' : ''}`}>{roleAssignments.map((assignment) => { const openAssignment = () => assignment.appointment_document_id ? void openDesignationDocument(assignment.appointment_document_id) : setAssignmentForm((current) => ({ ...current, personId: assignment.organization_person_id, roleId: assignment.role_id })); return <article key={assignment.assignment_id} className="skpe-interactive-record" role="button" tabIndex={0} aria-label={`Abrir designação de ${assignment.person_name}`} onClick={openAssignment} onKeyDown={(event) => activateRecordWithKeyboard(event, openAssignment)}><div><strong>{assignment.person_name}</strong><span>{assignment.role_name}</span><small>{assignment.mandate_end_date ? `${formatDate(assignment.mandate_start_date)} a ${formatDate(assignment.mandate_end_date)}` : `${formatDate(assignment.mandate_start_date)} · prazo indeterminado`}</small><small>{assignment.document_source === 'system_generated' ? `Termo gerado: ${assignment.document_code ?? assignment.appointment_document_reference}` : `Documento formal: ${assignment.appointment_document_reference ?? 'Referência não informada'}`}</small></div><div className="skpe-governance-counts"><b>{publicLabel(assignment.assignment_status)}</b>{assignment.appointment_document_id && <button type="button" onClick={(event) => { event.stopPropagation(); void openDesignationDocument(assignment.appointment_document_id as string) }}>Abrir termo</button>}</div></article> })}</div>}</div>
        </section>
      ) : activePanel === 'roles' ? (
        <section className="skpe-governance-list-card"><div className={`skpe-governance-card-grid ${governanceViewMode === 'grid' ? 'skpe-governance-row-grid' : ''}`}>{visibleRoles.map((role) => <article key={role.role_id} className="skpe-interactive-record" role="button" tabIndex={0} aria-label={`Abrir manutenção do papel ${role.role_name}`} onClick={() => openRoleMaintenance(role)} onKeyDown={(event) => activateRecordWithKeyboard(event, () => openRoleMaintenance(role))}><div><strong>{role.role_name}</strong><span>{role.role_code} · {publicLabel(role.role_type)}</span><small>{role.description ?? role.organizational_area ?? 'Sem descrição'}</small></div><div className="skpe-governance-counts"><b>{role.active_assignment_count} atribuições</b><b>{publicLabel(role.authority_level, 'Sem nível')}</b></div></article>)}</div>{canManageGovernance && <div id="skpe-role-maintenance-form" className="skpe-governance-form"><h3>{roleForm.id ? 'Editar papel organizacional' : 'Novo papel organizacional'}</h3>{roleForm.id && <button type="button" className="skpe-secondary-action-button" onClick={resetRoleForm}>+ Novo papel</button>}<label><span>Código *</span><input value={roleForm.code} onChange={(event) => setRoleForm((current) => ({ ...current, code: event.target.value }))} /></label><label><span>Nome *</span><input value={roleForm.name} onChange={(event) => setRoleForm((current) => ({ ...current, name: event.target.value }))} /></label><label><span>Tipo</span><select value={roleForm.roleType} onChange={(event) => setRoleForm((current) => ({ ...current, roleType: event.target.value }))}>{domainOptions('ORGANIZATIONAL_ROLE_TYPE').map((item) => <option key={item.value_id} value={item.value_code}>{item.value_name}</option>)}</select></label><label><span>Nível de autoridade</span><select value={roleForm.authorityLevel} onChange={(event) => setRoleForm((current) => ({ ...current, authorityLevel: event.target.value }))}>{domainOptions('AUTHORITY_LEVEL').map((item) => <option key={item.value_id} value={item.value_code}>{item.value_name}</option>)}</select></label><label><span>Área organizacional</span><input value={roleForm.area} onChange={(event) => setRoleForm((current) => ({ ...current, area: event.target.value }))} /></label><label className="skpe-form-field-wide"><span>Descrição</span><textarea value={roleForm.description} onChange={(event) => setRoleForm((current) => ({ ...current, description: event.target.value }))} /></label><label className="skpe-governance-check"><input type="checkbox" checked={roleForm.governance} onChange={(event) => setRoleForm((current) => ({ ...current, governance: event.target.checked }))} /><span>Papel de governança</span></label><label className="skpe-governance-check"><input type="checkbox" checked={roleForm.mandate} onChange={(event) => setRoleForm((current) => ({ ...current, mandate: event.target.checked }))} /><span>Exige mandato</span></label><label className="skpe-governance-check"><input type="checkbox" checked={roleForm.active} onChange={(event) => setRoleForm((current) => ({ ...current, active: event.target.checked }))} /><span>Papel ativo</span></label><label className="skpe-form-field-wide"><span>Justificativa para auditoria *</span><textarea value={roleForm.reason} onChange={(event) => setRoleForm((current) => ({ ...current, reason: event.target.value }))} /></label><button type="button" className="skpe-primary-action-button" onClick={() => void createRole()} disabled={saving}>{roleForm.id ? 'Atualizar papel' : 'Salvar papel'}</button></div>}</section>
      ) : (
        <section className="skpe-governance-list-card"><div className={`skpe-governance-card-grid ${governanceViewMode === 'grid' ? 'skpe-governance-row-grid' : ''}`}>{visibleResponsibilities.map((assignment) => <article key={assignment.assignment_id}><div><strong>{assignment.person_name}</strong><span>{domainOptions('RESPONSIBILITY_TYPE').find((item) => item.value_code === assignment.responsibility_type)?.value_name ?? assignment.responsibility_type}</span><small>{domainOptions('STRATEGIC_OBJECT_TYPE').find((item) => item.value_code === assignment.object_type)?.value_name ?? assignment.object_type} · {assignment.object_id}</small></div><div className="skpe-governance-counts"><b>{assignment.allocation_percentage ?? 0}%</b><button type="button" onClick={() => void endResponsibility(assignment)}>Encerrar</button></div></article>)}</div>{canManageGovernance && <div className="skpe-governance-form"><h3>Atribuir responsabilidade estratégica</h3><label><span>Tipo de objeto</span><select value={responsibilityForm.objectType} onChange={(event) => setResponsibilityForm((current) => ({ ...current, objectType: event.target.value }))}>{domainOptions('STRATEGIC_OBJECT_TYPE').map((item) => <option key={item.value_id} value={item.value_code}>{item.value_name}</option>)}</select></label><label className="skpe-form-field-wide"><span>ID do objeto estratégico *</span><input value={responsibilityForm.objectId} onChange={(event) => setResponsibilityForm((current) => ({ ...current, objectId: event.target.value }))} placeholder="UUID do projeto, objetivo, iniciativa ou item" /></label><label><span>Pessoa</span><select value={responsibilityForm.personId} onChange={(event) => setResponsibilityForm((current) => ({ ...current, personId: event.target.value }))}><option value="">Selecione</option>{visiblePeople.map((person) => <option key={person.organization_person_id} value={person.organization_person_id}>{person.preferred_name ?? person.full_name}</option>)}</select></label><label><span>Responsabilidade</span><select value={responsibilityForm.responsibilityType} onChange={(event) => setResponsibilityForm((current) => ({ ...current, responsibilityType: event.target.value }))}>{domainOptions('RESPONSIBILITY_TYPE').map((item) => <option key={item.value_id} value={item.value_code}>{item.value_name}</option>)}</select></label><label><span>Alocação (%)</span><input type="number" min="0" max="100" value={responsibilityForm.allocation} onChange={(event) => setResponsibilityForm((current) => ({ ...current, allocation: event.target.value }))} /></label><label><span>Autoridade</span><select value={responsibilityForm.authorityLevel} onChange={(event) => setResponsibilityForm((current) => ({ ...current, authorityLevel: event.target.value }))}>{domainOptions('AUTHORITY_LEVEL').map((item) => <option key={item.value_id} value={item.value_code}>{item.value_name}</option>)}</select></label><label><span>Válida a partir de</span><input type="date" value={responsibilityForm.validFrom} onChange={(event) => setResponsibilityForm((current) => ({ ...current, validFrom: event.target.value }))} /></label><label><span>Válida até</span><input type="date" value={responsibilityForm.validUntil} onChange={(event) => setResponsibilityForm((current) => ({ ...current, validUntil: event.target.value }))} /></label><label className="skpe-form-field-wide"><span>Motivo da atribuição</span><textarea value={responsibilityForm.assignmentReason} onChange={(event) => setResponsibilityForm((current) => ({ ...current, assignmentReason: event.target.value }))} /></label><label className="skpe-form-field-wide"><span>Justificativa para auditoria *</span><textarea value={responsibilityForm.reason} onChange={(event) => setResponsibilityForm((current) => ({ ...current, reason: event.target.value }))} /></label><button type="button" className="skpe-primary-action-button" onClick={() => void assignResponsibility()} disabled={saving}>Atribuir responsabilidade</button></div>}</section>
      )}
    </>
  )
}


type OrganizationalAreaRow = {
  area_id: string
  area_code: string
  area_name: string
  area_description: string | null
  area_type: string | null
  parent_area_id: string | null
  parent_area_name: string | null
  display_order: number
  active: boolean
  child_count: number
  linked_role_count: number
}

type OrganizationalAreasSectionProps = {
  organizationId: string
  canManageAreas: boolean
}

type AreaViewMode = 'cards' | 'grid' | 'tree'
type AreaSortKey = 'area_name' | 'area_code' | 'area_type' | 'parent_area_name' | 'active'
type SortDirection = 'asc' | 'desc'

function OrganizationalAreasSection({ organizationId, canManageAreas }: OrganizationalAreasSectionProps) {
  const [areas, setAreas] = useState<OrganizationalAreaRow[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<ActionMessage | null>(null)
  const [viewMode, setViewMode] = useState<AreaViewMode>('cards')
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all')
  const [typeFilter, setTypeFilter] = useState('all')
  const [sortKey, setSortKey] = useState<AreaSortKey>('area_name')
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc')
  const [selectedArea, setSelectedArea] = useState<OrganizationalAreaRow | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ id: '', code: '', name: '', description: '', areaType: 'management', parentId: '', displayOrder: '100', active: true, reason: '' })

  const loadAreas = async () => {
    setLoading(true)
    setMessage(null)
    const { data, error } = await supabase.rpc('get_skpe_organizational_areas', {
      target_organization_id: organizationId,
      include_inactive: true,
    })
    if (error) setMessage({ type: 'error', text: error.message })
    else setAreas((data ?? []) as OrganizationalAreaRow[])
    setLoading(false)
  }

  useEffect(() => { void loadAreas() }, [organizationId])

  const areaTypes = useMemo(() => Array.from(new Set(areas.map((area) => area.area_type).filter(Boolean) as string[])).sort((a, b) => a.localeCompare(b, 'pt-BR')), [areas])

  const visibleAreas = useMemo(() => {
    const normalizedSearch = search.trim().toLocaleLowerCase('pt-BR')
    return areas
      .filter((area) => statusFilter === 'all' || (statusFilter === 'active' ? area.active : !area.active))
      .filter((area) => typeFilter === 'all' || area.area_type === typeFilter)
      .filter((area) => !normalizedSearch || [area.area_name, area.area_code, area.area_description ?? '', area.parent_area_name ?? ''].some((value) => value.toLocaleLowerCase('pt-BR').includes(normalizedSearch)))
      .sort((left, right) => {
        const leftValue = String(left[sortKey] ?? '')
        const rightValue = String(right[sortKey] ?? '')
        const comparison = leftValue.localeCompare(rightValue, 'pt-BR', { sensitivity: 'base', numeric: true })
        return sortDirection === 'asc' ? comparison : -comparison
      })
  }, [areas, search, statusFilter, typeFilter, sortKey, sortDirection])

  const toggleSort = (key: AreaSortKey) => {
    if (sortKey === key) setSortDirection((current) => current === 'asc' ? 'desc' : 'asc')
    else { setSortKey(key); setSortDirection('asc') }
  }

  const openNew = () => {
    setSelectedArea(null)
    setForm({ id: '', code: '', name: '', description: '', areaType: 'management', parentId: '', displayOrder: String((areas.length + 1) * 10), active: true, reason: '' })
    setShowForm(true)
  }

  const openEdit = (area: OrganizationalAreaRow) => {
    setSelectedArea(area)
    setForm({ id: area.area_id, code: area.area_code, name: area.area_name, description: area.area_description ?? '', areaType: area.area_type ?? 'management', parentId: area.parent_area_id ?? '', displayOrder: String(area.display_order), active: area.active, reason: '' })
    setShowForm(true)
  }

  const saveArea = async () => {
    if (!form.code.trim() || !form.name.trim()) { setMessage({ type: 'error', text: 'Informe o código e o nome da área.' }); return }
    if (form.reason.trim().length < 10) { setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' }); return }
    setSaving(true)
    const { error } = await supabase.rpc('upsert_skpe_organizational_area', {
      target_organization_id: organizationId,
      target_area_id: form.id || null,
      target_code: form.code,
      target_name: form.name,
      target_description: form.description || null,
      target_area_type: form.areaType || null,
      target_parent_area_id: form.parentId || null,
      target_display_order: Number(form.displayOrder || 100),
      target_active: form.active,
      change_reason: form.reason,
    })
    if (error) setMessage({ type: 'error', text: error.message })
    else { setMessage({ type: 'success', text: form.id ? 'Área atualizada com sucesso.' : 'Área incluída com sucesso.' }); setShowForm(false); await loadAreas() }
    setSaving(false)
  }

  const deactivateArea = async (area: OrganizationalAreaRow) => {
    const action = area.active ? 'desativar' : 'reativar'
    const reason = window.prompt(`Informe a justificativa para ${action} a área “${area.area_name}”:`, `${action[0].toUpperCase()}${action.slice(1)} área para manutenção da estrutura organizacional.`)
    if (!reason || reason.trim().length < 10) return
    const { error } = await supabase.rpc('set_skpe_organizational_area_active', { target_organization_id: organizationId, target_area_id: area.area_id, target_active: !area.active, change_reason: reason })
    if (error) setMessage({ type: 'error', text: error.message })
    else { setMessage({ type: 'success', text: area.active ? 'Área desativada. O histórico foi preservado.' : 'Área reativada.' }); await loadAreas() }
  }

  const deleteArea = async (area: OrganizationalAreaRow) => {
    if (!window.confirm(`Excluir definitivamente a área “${area.area_name}”? A exclusão só será permitida se não houver vínculos ou áreas subordinadas.`)) return
    const reason = window.prompt('Informe a justificativa para exclusão:', 'Exclusão controlada de área sem vínculos ou histórico operacional.')
    if (!reason || reason.trim().length < 10) return
    const { error } = await supabase.rpc('delete_skpe_organizational_area', { target_organization_id: organizationId, target_area_id: area.area_id, change_reason: reason })
    if (error) setMessage({ type: 'error', text: error.message })
    else { setMessage({ type: 'success', text: 'Área excluída definitivamente.' }); await loadAreas() }
  }

  const printArea = (area: OrganizationalAreaRow) => {
    const popup = window.open('', '_blank', 'width=900,height=700')
    if (!popup) return
    popup.document.write(`<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>${area.area_name}</title><style>body{font-family:Arial,sans-serif;padding:40px;color:#17352d}h1{margin-bottom:6px}.meta{color:#587069;margin-bottom:28px}.box{border:1px solid #d7e2de;border-radius:12px;padding:18px;margin-top:16px}dt{font-weight:700;margin-top:12px}dd{margin:4px 0 0}</style></head><body><h1>${area.area_name}</h1><div class="meta">${area.area_code} · ${area.active ? 'Ativa' : 'Inativa'}</div><div class="box"><dl><dt>Descrição</dt><dd>${area.area_description ?? 'Não informada'}</dd><dt>Tipo</dt><dd>${publicLabel(area.area_type)}</dd><dt>Área superior</dt><dd>${area.parent_area_name ?? 'Sem área superior'}</dd><dt>Papéis vinculados</dt><dd>${area.linked_role_count}</dd><dt>Áreas subordinadas</dt><dd>${area.child_count}</dd></dl></div><script>window.onload=()=>window.print()</script></body></html>`)
    popup.document.close()
  }

  const renderActions = (area: OrganizationalAreaRow) => <div className="skpe-record-actions" onClick={(event) => event.stopPropagation()}>
    <button type="button" title="Editar" aria-label="Editar" onClick={() => openEdit(area)}>✎</button>
    <button type="button" title="Imprimir" aria-label="Imprimir" onClick={() => printArea(area)}>⎙</button>
    <button type="button" title={area.active ? 'Desativar' : 'Reativar'} aria-label={area.active ? 'Desativar' : 'Reativar'} onClick={() => void deactivateArea(area)}>{area.active ? '◉' : '○'}</button>
    <button type="button" title="Excluir" aria-label="Excluir" className="skpe-record-action-danger" onClick={() => void deleteArea(area)}>⌫</button>
  </div>

  const roots = visibleAreas.filter((area) => !area.parent_area_id || !visibleAreas.some((candidate) => candidate.area_id === area.parent_area_id))
  const renderTree = (area: OrganizationalAreaRow, level = 0): ReactNode => <div key={area.area_id} className="skpe-area-tree-node skpe-interactive-record" role="button" tabIndex={0} aria-label={`Abrir detalhes de ${area.area_name}`} style={{ marginLeft: `${level * 24}px` }} onClick={() => setSelectedArea(area)} onKeyDown={(event) => activateRecordWithKeyboard(event, () => setSelectedArea(area))}><div><strong>{area.area_name}</strong><span>{area.area_code} · {publicLabel(area.area_type, 'Sem tipo')}</span></div>{renderActions(area)}{visibleAreas.filter((candidate) => candidate.parent_area_id === area.area_id).map((child) => renderTree(child, level + 1))}</div>

  return <>
    <section className="skpe-page-heading skpe-administration-heading"><div><p className="skpe-eyebrow">Estrutura organizacional</p><h1>Áreas e estrutura organizacional</h1><p>Inclua, edite, organize, filtre e imprima áreas da organização. A ordenação inicial é alfabética crescente (A–Z).</p></div><div className="skpe-heading-actions"><button type="button" className="skpe-refresh-button" onClick={() => void loadAreas()} disabled={loading}><RefreshIcon />Atualizar</button>{canManageAreas && <button type="button" className="skpe-primary-action-button" onClick={openNew}>+ Nova área</button>}</div></section>
    {message && <div className={`skpe-action-message skpe-action-message-${message.type}`}>{message.text}</div>}
    <section className="skpe-list-toolbar"><label className="skpe-list-search"><SearchIcon /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Pesquisar por nome, código, descrição ou área superior" /></label><select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value as typeof statusFilter)}><option value="all">Todas as situações</option><option value="active">Ativas</option><option value="inactive">Inativas</option></select><select value={typeFilter} onChange={(event) => setTypeFilter(event.target.value)}><option value="all">Todos os tipos</option>{areaTypes.map((type) => <option key={type} value={type}>{publicLabel(type)}</option>)}</select><div className="skpe-view-switch" aria-label="Modo de visualização"><button type="button" title="Cards" className={viewMode === 'cards' ? 'active' : ''} onClick={() => setViewMode('cards')}>▦</button><button type="button" title="Grid" className={viewMode === 'grid' ? 'active' : ''} onClick={() => setViewMode('grid')}>☷</button><button type="button" title="Hierarquia" className={viewMode === 'tree' ? 'active' : ''} onClick={() => setViewMode('tree')}>⌘</button></div></section>
    {loading ? <section className="skpe-admin-state-card"><p>Carregando áreas...</p></section> : visibleAreas.length === 0 ? <section className="skpe-admin-state-card"><p>Nenhuma área encontrada para os filtros informados.</p></section> : viewMode === 'cards' ? <section className="skpe-area-card-grid">{visibleAreas.map((area) => <article key={area.area_id} className={`skpe-interactive-record ${!area.active ? 'skpe-record-inactive' : ''}`} role="button" tabIndex={0} aria-label={`Abrir detalhes de ${area.area_name}`} onClick={() => setSelectedArea(area)} onKeyDown={(event) => activateRecordWithKeyboard(event, () => setSelectedArea(area))}><div className="skpe-area-card-heading"><div><strong>{area.area_name}</strong><span>{area.area_code}</span></div>{renderActions(area)}</div><p>{area.area_description ?? 'Sem descrição complementar.'}</p><div className="skpe-area-card-meta"><b>{publicLabel(area.area_type, 'Sem tipo')}</b><span>{area.parent_area_name ? `Subordinada a ${area.parent_area_name}` : 'Área de primeiro nível'}</span><small>{area.linked_role_count} papéis · {area.child_count} áreas subordinadas</small></div></article>)}</section> : viewMode === 'grid' ? <section className="skpe-data-grid-wrapper"><table className="skpe-data-grid"><thead><tr><th><button type="button" onClick={() => toggleSort('area_name')}>Nome {sortKey === 'area_name' ? (sortDirection === 'asc' ? '↑' : '↓') : ''}</button></th><th><button type="button" onClick={() => toggleSort('area_code')}>Código {sortKey === 'area_code' ? (sortDirection === 'asc' ? '↑' : '↓') : ''}</button></th><th><button type="button" onClick={() => toggleSort('area_type')}>Tipo {sortKey === 'area_type' ? (sortDirection === 'asc' ? '↑' : '↓') : ''}</button></th><th><button type="button" onClick={() => toggleSort('parent_area_name')}>Área superior {sortKey === 'parent_area_name' ? (sortDirection === 'asc' ? '↑' : '↓') : ''}</button></th><th>Papéis</th><th><button type="button" onClick={() => toggleSort('active')}>Situação {sortKey === 'active' ? (sortDirection === 'asc' ? '↑' : '↓') : ''}</button></th><th>Ações</th></tr></thead><tbody>{visibleAreas.map((area) => <tr key={area.area_id} className={`skpe-interactive-record ${!area.active ? 'skpe-record-inactive' : ''}`} role="button" tabIndex={0} aria-label={`Abrir detalhes de ${area.area_name}`} onClick={() => setSelectedArea(area)} onKeyDown={(event) => activateRecordWithKeyboard(event, () => setSelectedArea(area))}><td><strong>{area.area_name}</strong></td><td>{area.area_code}</td><td>{publicLabel(area.area_type, '—')}</td><td>{area.parent_area_name ?? '—'}</td><td>{area.linked_role_count}</td><td>{area.active ? 'Ativa' : 'Inativa'}</td><td>{renderActions(area)}</td></tr>)}</tbody></table></section> : <section className="skpe-area-tree">{roots.map((area) => renderTree(area))}</section>}
    {selectedArea && !showForm && <aside className="skpe-record-detail-panel"><button type="button" className="skpe-panel-close" onClick={() => setSelectedArea(null)}>×</button><p className="skpe-eyebrow">Detalhes da área</p><h2>{selectedArea.area_name}</h2><span>{selectedArea.area_code}</span><p>{selectedArea.area_description ?? 'Sem descrição complementar.'}</p><dl><dt>Tipo</dt><dd>{publicLabel(selectedArea.area_type)}</dd><dt>Área superior</dt><dd>{selectedArea.parent_area_name ?? 'Sem área superior'}</dd><dt>Situação</dt><dd>{selectedArea.active ? 'Ativa' : 'Inativa'}</dd><dt>Papéis vinculados</dt><dd>{selectedArea.linked_role_count}</dd></dl>{canManageAreas && <div className="skpe-panel-actions">{renderActions(selectedArea)}</div>}</aside>}
    {showForm && <div className="skpe-modal-backdrop"><section className="skpe-modal-card skpe-area-form-modal"><button type="button" className="skpe-panel-close" onClick={() => setShowForm(false)}>×</button><p className="skpe-eyebrow">{form.id ? 'Editar área' : 'Incluir área'}</p><h2>{form.id ? form.name : 'Nova área organizacional'}</h2><div className="skpe-governance-form"><label><span>Código *</span><input value={form.code} disabled={Boolean(form.id)} onChange={(event) => setForm((current) => ({ ...current, code: event.target.value.toUpperCase().replace(/[^A-Z0-9_]/g, '_') }))} /></label><label><span>Nome *</span><input value={form.name} onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))} /></label><label><span>Tipo</span><select value={form.areaType} onChange={(event) => setForm((current) => ({ ...current, areaType: event.target.value }))}><option value="governance">Governança</option><option value="management">Gestão</option><option value="business">Negócios</option><option value="operations">Operação</option><option value="support">Suporte</option><option value="control">Controle</option><option value="project">Projeto</option><option value="people">Pessoas</option><option value="technology">Tecnologia</option><option value="sustainability">Sustentabilidade</option></select></label><label><span>Área superior</span><select value={form.parentId} onChange={(event) => setForm((current) => ({ ...current, parentId: event.target.value }))}><option value="">Sem área superior</option>{areas.filter((area) => area.area_id !== form.id && area.active).sort((a, b) => a.area_name.localeCompare(b.area_name, 'pt-BR')).map((area) => <option key={area.area_id} value={area.area_id}>{area.area_name}</option>)}</select></label><label><span>Ordem técnica</span><input type="number" value={form.displayOrder} onChange={(event) => setForm((current) => ({ ...current, displayOrder: event.target.value }))} /></label><label className="skpe-governance-check"><input type="checkbox" checked={form.active} onChange={(event) => setForm((current) => ({ ...current, active: event.target.checked }))} /><span>Área ativa</span></label><label className="skpe-form-field-wide"><span>Descrição</span><textarea value={form.description} onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))} /></label><label className="skpe-form-field-wide"><span>Justificativa para auditoria *</span><textarea value={form.reason} onChange={(event) => setForm((current) => ({ ...current, reason: event.target.value }))} /></label><div className="skpe-form-field-wide skpe-modal-actions"><button type="button" onClick={() => setShowForm(false)}>Cancelar</button><button type="button" className="skpe-primary-action-button" onClick={() => void saveArea()} disabled={saving}>{saving ? 'Salvando...' : 'Salvar área'}</button></div></div></section></div>}
  </>
}

type DomainTablesSectionProps = {
  organizationId: string
  canManageDomains: boolean
}

const domainCatalog = [
  ['RESPONSIBILITY_TYPE', 'Tipos de responsabilidade'],
  ['ORGANIZATIONAL_ROLE_TYPE', 'Tipos de papel organizacional'],
  ['AUTHORITY_LEVEL', 'Níveis de autoridade'],
  ['STRATEGIC_OBJECT_TYPE', 'Tipos de objeto estratégico'],
  ['DECISION_TYPE', 'Tipos de decisão'],
  ['APPROVAL_STATUS', 'Situações de aprovação'],
  ['VALIDATION_STATUS', 'Situações de validação'],
  ['MEASUREMENT_FREQUENCY', 'Periodicidades de medição'],
  ['MEASUREMENT_UNIT', 'Unidades de medida'],
  ['INDICATOR_POLARITY', 'Polaridade de indicadores'],
  ['REVIEW_CYCLE', 'Ciclos de revisão'],
  ['RISK_LEVEL', 'Níveis de risco'],
] as const



type HierarchyViewMode = 'cards' | 'grid' | 'tree'
type OrganizationOption = { id: string; code: string | null; legal_name: string; trade_name: string | null; organization_level: string | null; organization_type: string | null }
type RelationshipTypeOption = { id: string; code: string; name: string; description: string | null; relationship_nature: string; is_hierarchical: boolean }
type OrganizationRelationshipRow = {
  id: string; parent_organization_id: string; child_organization_id: string; relationship_type_id: string;
  is_primary: boolean; allows_consolidated_view: boolean; allows_delegated_administration: boolean;
  valid_from: string; valid_until: string | null; status: string; notes: string | null
}
type DescendantPolicyRow = {
  id: string; source_organization_id: string; relationship_scope: string; target_organization_id: string | null;
  module_code: string | null; access_mode: string; can_view_consolidated: boolean; can_view_detail: boolean;
  can_create: boolean; can_update: boolean; can_delete: boolean; can_manage_users: boolean;
  includes_confidential_data: boolean; requires_child_consent: boolean; child_consent_status: string;
  valid_from: string; valid_until: string | null; status: string; reason: string | null
}

const hierarchyLabels: Record<string, string> = {
  active: 'Ativo', pending: 'Pendente', suspended: 'Suspenso', ended: 'Encerrado', draft: 'Rascunho',
  direct_children: 'Subordinadas diretas', all_descendants: 'Toda a estrutura descendente', specific_organization: 'Organização específica',
  consolidated: 'Consolidado', read_only: 'Somente leitura', operational_delegated: 'Operacional delegado', administrative_delegated: 'Administrativo delegado',
  not_required: 'Não exigido', approved: 'Aprovado', rejected: 'Rejeitado', revoked: 'Revogado',
}
const hierarchyLabel = (value: string | null | undefined) => value ? (hierarchyLabels[value] ?? publicLabel(value, '—')) : '—'
const organizationDisplayName = (organization: OrganizationOption | undefined) => organization ? (organization.trade_name ?? organization.legal_name ?? organization.code ?? 'Organização') : 'Organização não localizada'

function OrganizationHierarchySection({ organizationId, canManage }: { organizationId: string; canManage: boolean }) {
  const [organizations, setOrganizations] = useState<OrganizationOption[]>([])
  const [types, setTypes] = useState<RelationshipTypeOption[]>([])
  const [relationships, setRelationships] = useState<OrganizationRelationshipRow[]>([])
  const [policies, setPolicies] = useState<DescendantPolicyRow[]>([])
  const [viewMode, setViewMode] = useState<HierarchyViewMode>('cards')
  const [tab, setTab] = useState<'relationships' | 'policies'>('relationships')
  const [search, setSearch] = useState('')
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)
  const [relationshipForm, setRelationshipForm] = useState({ id: '', parentId: organizationId, childId: '', typeCode: '', primary: true, consolidated: true, delegated: false, start: new Date().toISOString().slice(0,10), end: '', status: 'active', reason: '' })
  const [policyForm, setPolicyForm] = useState({ id: '', sourceId: organizationId, scope: 'all_descendants', targetId: '', moduleCode: 'SK-PE', mode: 'consolidated', viewConsolidated: true, viewDetail: false, create: false, update: false, delete: false, manageUsers: false, confidential: false, consent: true, consentStatus: 'pending', start: new Date().toISOString().slice(0,10), end: '', status: 'active', reason: '' })

  const loadData = async () => {
    setLoading(true); setMessage(null)
    const [orgResult, typeResult, relResult, policyResult] = await Promise.all([
      supabase.from('organizations').select('id,code,legal_name,trade_name,organization_level,organization_type').is('archived_at', null).order('trade_name', { ascending: true }),
      supabase.from('organization_relationship_types').select('id,code,name,description,relationship_nature,is_hierarchical').eq('active', true).order('name', { ascending: true }),
      supabase.from('organization_relationships').select('id,parent_organization_id,child_organization_id,relationship_type_id,is_primary,allows_consolidated_view,allows_delegated_administration,valid_from,valid_until,status,notes').order('created_at', { ascending: false }),
      supabase.from('organization_descendant_access_policies').select('id,source_organization_id,relationship_scope,target_organization_id,module_code,access_mode,can_view_consolidated,can_view_detail,can_create,can_update,can_delete,can_manage_users,includes_confidential_data,requires_child_consent,child_consent_status,valid_from,valid_until,status,reason').order('created_at', { ascending: false }),
    ])
    const error = orgResult.error ?? typeResult.error ?? relResult.error ?? policyResult.error
    if (error) setMessage({ type: 'error', text: error.message })
    setOrganizations((orgResult.data ?? []) as OrganizationOption[])
    setTypes((typeResult.data ?? []) as RelationshipTypeOption[])
    setRelationships((relResult.data ?? []) as OrganizationRelationshipRow[])
    setPolicies((policyResult.data ?? []) as DescendantPolicyRow[])
    setLoading(false)
  }
  useEffect(() => { void loadData() }, [organizationId])
  const orgMap = useMemo(() => new Map(organizations.map(item => [item.id, item])), [organizations])
  const typeMap = useMemo(() => new Map(types.map(item => [item.id, item])), [types])
  const visibleRelationships = useMemo(() => relationships.filter(item => {
    const value = `${organizationDisplayName(orgMap.get(item.parent_organization_id))} ${organizationDisplayName(orgMap.get(item.child_organization_id))} ${typeMap.get(item.relationship_type_id)?.name ?? ''} ${item.status}`.toLocaleLowerCase('pt-BR')
    return value.includes(search.toLocaleLowerCase('pt-BR'))
  }).sort((a,b) => {
    const av = organizationDisplayName(orgMap.get(a.child_organization_id)); const bv = organizationDisplayName(orgMap.get(b.child_organization_id));
    return sortDirection === 'asc' ? av.localeCompare(bv, 'pt-BR') : bv.localeCompare(av, 'pt-BR')
  }), [relationships, orgMap, typeMap, search, sortDirection])
  const visiblePolicies = useMemo(() => policies.filter(item => {
    const value = `${organizationDisplayName(orgMap.get(item.source_organization_id))} ${organizationDisplayName(orgMap.get(item.target_organization_id ?? ''))} ${item.module_code ?? ''} ${hierarchyLabel(item.access_mode)}`.toLocaleLowerCase('pt-BR')
    return value.includes(search.toLocaleLowerCase('pt-BR'))
  }).sort((a,b) => {
    const av = organizationDisplayName(orgMap.get(a.source_organization_id)); const bv = organizationDisplayName(orgMap.get(b.source_organization_id));
    return sortDirection === 'asc' ? av.localeCompare(bv, 'pt-BR') : bv.localeCompare(av, 'pt-BR')
  }), [policies, orgMap, search, sortDirection])

  const saveRelationship = async () => {
    if (!relationshipForm.parentId || !relationshipForm.childId || !relationshipForm.typeCode || !relationshipForm.reason.trim()) { setMessage({type:'error', text:'Preencha organizações, tipo e justificativa.'}); return }
    setSaving(true)
    const { error } = await supabase.rpc('upsert_organization_relationship', { relationship_id: relationshipForm.id || null, parent_id: relationshipForm.parentId, child_id: relationshipForm.childId, relationship_type_code: relationshipForm.typeCode, primary_relationship: relationshipForm.primary, consolidated_view: relationshipForm.consolidated, delegated_administration: relationshipForm.delegated, starts_on: relationshipForm.start, ends_on: relationshipForm.end || null, relationship_status: relationshipForm.status, change_reason: relationshipForm.reason })
    setSaving(false)
    if (error) { setMessage({type:'error', text:error.message}); return }
    setMessage({type:'success', text:'Vínculo organizacional salvo com sucesso.'})
    setRelationshipForm({ id:'', parentId:organizationId, childId:'', typeCode:'', primary:true, consolidated:true, delegated:false, start:new Date().toISOString().slice(0,10), end:'', status:'active', reason:'' })
    await loadData()
  }
  const editRelationship = (item: OrganizationRelationshipRow) => { setTab('relationships'); setRelationshipForm({ id:item.id, parentId:item.parent_organization_id, childId:item.child_organization_id, typeCode:typeMap.get(item.relationship_type_id)?.code ?? '', primary:item.is_primary, consolidated:item.allows_consolidated_view, delegated:item.allows_delegated_administration, start:item.valid_from, end:item.valid_until ?? '', status:item.status, reason:item.notes ?? 'Atualização do vínculo organizacional.' }); window.scrollTo({top:0,behavior:'smooth'}) }
  const printRelationship = (item: OrganizationRelationshipRow) => { const content = `<h1>Vínculo organizacional</h1><p><b>Superior:</b> ${organizationDisplayName(orgMap.get(item.parent_organization_id))}</p><p><b>Subordinada:</b> ${organizationDisplayName(orgMap.get(item.child_organization_id))}</p><p><b>Tipo:</b> ${typeMap.get(item.relationship_type_id)?.name ?? ''}</p><p><b>Situação:</b> ${hierarchyLabel(item.status)}</p><p><b>Vigência:</b> ${item.valid_from} a ${item.valid_until ?? 'prazo indeterminado'}</p>`; const win=window.open('','_blank'); if(win){win.document.write(`<html><head><title>Vínculo organizacional</title></head><body>${content}</body></html>`);win.document.close();win.print()} }

  const savePolicy = async () => {
    if (!policyForm.sourceId || !policyForm.reason.trim()) { setMessage({type:'error', text:'Preencha a organização de origem e a justificativa.'}); return }
    if (policyForm.scope === 'specific_organization' && !policyForm.targetId) { setMessage({type:'error', text:'Selecione a organização específica.'}); return }
    setSaving(true)
    const { error } = await supabase.rpc('upsert_descendant_access_policy', { policy_id: policyForm.id || null, source_org_id: policyForm.sourceId, scope_code: policyForm.scope, target_org_id: policyForm.scope === 'specific_organization' ? policyForm.targetId : null, module_code_value: policyForm.moduleCode, access_mode_value: policyForm.mode, view_consolidated: policyForm.viewConsolidated, view_detail: policyForm.viewDetail, allow_create: policyForm.create, allow_update: policyForm.update, allow_delete: policyForm.delete, allow_manage_users: policyForm.manageUsers, include_confidential: policyForm.confidential, require_child_consent: policyForm.consent, consent_status: policyForm.consentStatus, starts_on: policyForm.start, ends_on: policyForm.end || null, policy_status: policyForm.status, change_reason: policyForm.reason })
    setSaving(false)
    if (error) { setMessage({type:'error', text:error.message}); return }
    setMessage({type:'success', text:'Política de acesso salva com sucesso.'}); await loadData()
  }
  const editPolicy = (item: DescendantPolicyRow) => { setTab('policies'); setPolicyForm({ id:item.id, sourceId:item.source_organization_id, scope:item.relationship_scope, targetId:item.target_organization_id ?? '', moduleCode:item.module_code ?? '', mode:item.access_mode, viewConsolidated:item.can_view_consolidated, viewDetail:item.can_view_detail, create:item.can_create, update:item.can_update, delete:item.can_delete, manageUsers:item.can_manage_users, confidential:item.includes_confidential_data, consent:item.requires_child_consent, consentStatus:item.child_consent_status, start:item.valid_from, end:item.valid_until ?? '', status:item.status, reason:item.reason ?? 'Atualização da política de acesso.' }); window.scrollTo({top:0,behavior:'smooth'}) }
  const printPolicy = (item: DescendantPolicyRow) => { const content = `<h1>Política de acesso hierárquico</h1><p><b>Origem:</b> ${organizationDisplayName(orgMap.get(item.source_organization_id))}</p><p><b>Escopo:</b> ${hierarchyLabel(item.relationship_scope)}</p><p><b>Módulo:</b> ${item.module_code ?? 'Todos'}</p><p><b>Modo:</b> ${hierarchyLabel(item.access_mode)}</p><p><b>Situação:</b> ${hierarchyLabel(item.status)}</p>`; const win=window.open('','_blank'); if(win){win.document.write(`<html><body>${content}</body></html>`);win.document.close();win.print()} }

  return <>
    <section className="skpe-page-heading skpe-administration-heading"><div><p className="skpe-eyebrow">Arquitetura multinível</p><h1>Estrutura organizacional e acessos hierárquicos</h1><p>Administre vínculos entre organizações e autorizações descendentes, sem conceder acesso irrestrito automaticamente.</p></div><button type="button" className="skpe-refresh-button" onClick={() => void loadData()} disabled={loading}><RefreshIcon />Atualizar</button></section>
    {message && <div className={`skpe-action-message skpe-action-message-${message.type}`}>{message.text}</div>}
    <section className="skpe-hierarchy-toolbar"><div className="skpe-hierarchy-tabs"><button className={tab==='relationships'?'active':''} onClick={()=>setTab('relationships')}>Vínculos organizacionais</button><button className={tab==='policies'?'active':''} onClick={()=>setTab('policies')}>Políticas de acesso</button></div><div className="skpe-hierarchy-controls"><label className="skpe-search-field"><SearchIcon /><input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Pesquisar..." /></label><button title="Cards" className={viewMode==='cards'?'active':''} onClick={()=>setViewMode('cards')}>▦</button><button title="Grid" className={viewMode==='grid'?'active':''} onClick={()=>setViewMode('grid')}>☷</button>{tab==='relationships' && <button title="Árvore" className={viewMode==='tree'?'active':''} onClick={()=>setViewMode('tree')}>⌘</button>}<button onClick={()=>setSortDirection(v=>v==='asc'?'desc':'asc')}>{sortDirection==='asc'?'A → Z':'Z → A'}</button></div></section>
    {canManage && tab==='relationships' && <section className="skpe-hierarchy-form"><h2>{relationshipForm.id ? 'Editar vínculo organizacional' : 'Novo vínculo organizacional'}</h2><div className="skpe-hierarchy-form-grid"><label><span>Organização superior *</span><select value={relationshipForm.parentId} onChange={e=>setRelationshipForm(v=>({...v,parentId:e.target.value}))}>{organizations.map(o=><option key={o.id} value={o.id}>{organizationDisplayName(o)}</option>)}</select></label><label><span>Organização subordinada *</span><select value={relationshipForm.childId} onChange={e=>setRelationshipForm(v=>({...v,childId:e.target.value}))}><option value="">Selecione</option>{organizations.filter(o=>o.id!==relationshipForm.parentId).map(o=><option key={o.id} value={o.id}>{organizationDisplayName(o)}</option>)}</select></label><label><span>Tipo de relacionamento *</span><select value={relationshipForm.typeCode} onChange={e=>setRelationshipForm(v=>({...v,typeCode:e.target.value}))}><option value="">Selecione</option>{types.map(t=><option key={t.id} value={t.code}>{t.name}</option>)}</select></label><label><span>Situação</span><select value={relationshipForm.status} onChange={e=>setRelationshipForm(v=>({...v,status:e.target.value}))}><option value="active">Ativo</option><option value="pending">Pendente</option><option value="suspended">Suspenso</option><option value="ended">Encerrado</option></select></label><label><span>Início</span><input type="date" value={relationshipForm.start} onChange={e=>setRelationshipForm(v=>({...v,start:e.target.value}))}/></label><label><span>Término</span><input type="date" value={relationshipForm.end} onChange={e=>setRelationshipForm(v=>({...v,end:e.target.value}))}/></label><label className="skpe-hierarchy-check"><input type="checkbox" checked={relationshipForm.primary} onChange={e=>setRelationshipForm(v=>({...v,primary:e.target.checked}))}/><span>Vínculo principal</span></label><label className="skpe-hierarchy-check"><input type="checkbox" checked={relationshipForm.consolidated} onChange={e=>setRelationshipForm(v=>({...v,consolidated:e.target.checked}))}/><span>Permite visão consolidada</span></label><label className="skpe-hierarchy-check"><input type="checkbox" checked={relationshipForm.delegated} onChange={e=>setRelationshipForm(v=>({...v,delegated:e.target.checked}))}/><span>Permite administração delegada</span></label><label className="wide"><span>Justificativa *</span><textarea value={relationshipForm.reason} onChange={e=>setRelationshipForm(v=>({...v,reason:e.target.value}))}/></label></div><div className="skpe-form-actions"><button className="skpe-primary-action-button" onClick={()=>void saveRelationship()} disabled={saving}>Salvar vínculo</button>{relationshipForm.id && <button onClick={()=>setRelationshipForm(v=>({...v,id:''}))}>Cancelar edição</button>}</div></section>}
    {canManage && tab==='policies' && <section className="skpe-hierarchy-form"><h2>{policyForm.id ? 'Editar política de acesso' : 'Nova política de acesso'}</h2><div className="skpe-hierarchy-form-grid"><label><span>Organização superior *</span><select value={policyForm.sourceId} onChange={e=>setPolicyForm(v=>({...v,sourceId:e.target.value}))}>{organizations.map(o=><option key={o.id} value={o.id}>{organizationDisplayName(o)}</option>)}</select></label><label><span>Escopo</span><select value={policyForm.scope} onChange={e=>setPolicyForm(v=>({...v,scope:e.target.value}))}><option value="direct_children">Subordinadas diretas</option><option value="all_descendants">Toda a estrutura descendente</option><option value="specific_organization">Organização específica</option></select></label>{policyForm.scope==='specific_organization' && <label><span>Organização específica</span><select value={policyForm.targetId} onChange={e=>setPolicyForm(v=>({...v,targetId:e.target.value}))}><option value="">Selecione</option>{organizations.filter(o=>o.id!==policyForm.sourceId).map(o=><option key={o.id} value={o.id}>{organizationDisplayName(o)}</option>)}</select></label>}<label><span>Módulo</span><select value={policyForm.moduleCode} onChange={e=>setPolicyForm(v=>({...v,moduleCode:e.target.value}))}><option value="">Todos</option>{['SK-PE','SK-FIN','SK-ASM','SK-DOC','SK-DA','SK-PN'].map(m=><option key={m}>{m}</option>)}</select></label><label><span>Modo de acesso</span><select value={policyForm.mode} onChange={e=>setPolicyForm(v=>({...v,mode:e.target.value}))}><option value="consolidated">Consolidado</option><option value="read_only">Somente leitura</option><option value="operational_delegated">Operacional delegado</option><option value="administrative_delegated">Administrativo delegado</option></select></label><label><span>Situação</span><select value={policyForm.status} onChange={e=>setPolicyForm(v=>({...v,status:e.target.value}))}><option value="active">Ativo</option><option value="draft">Rascunho</option><option value="suspended">Suspenso</option><option value="ended">Encerrado</option></select></label><label><span>Início</span><input type="date" value={policyForm.start} onChange={e=>setPolicyForm(v=>({...v,start:e.target.value}))}/></label><label><span>Término</span><input type="date" value={policyForm.end} onChange={e=>setPolicyForm(v=>({...v,end:e.target.value}))}/></label>{[['viewConsolidated','Ver consolidado'],['viewDetail','Ver detalhes'],['create','Incluir'],['update','Editar'],['delete','Excluir'],['manageUsers','Administrar usuários'],['confidential','Acessar confidenciais'],['consent','Exigir concordância da subordinada']].map(([key,label])=><label key={key} className="skpe-hierarchy-check"><input type="checkbox" checked={Boolean(policyForm[key as keyof typeof policyForm])} onChange={e=>setPolicyForm(v=>({...v,[key]:e.target.checked}))}/><span>{label}</span></label>)}<label><span>Concordância</span><select value={policyForm.consentStatus} onChange={e=>setPolicyForm(v=>({...v,consentStatus:e.target.value}))}><option value="pending">Pendente</option><option value="approved">Aprovada</option><option value="rejected">Rejeitada</option><option value="revoked">Revogada</option><option value="not_required">Não exigida</option></select></label><label className="wide"><span>Justificativa *</span><textarea value={policyForm.reason} onChange={e=>setPolicyForm(v=>({...v,reason:e.target.value}))}/></label></div><div className="skpe-form-actions"><button className="skpe-primary-action-button" onClick={()=>void savePolicy()} disabled={saving}>Salvar política</button></div></section>}
    {loading ? <section className="skpe-admin-state-card"><p>Carregando estrutura...</p></section> : tab==='relationships' ? <section className={`skpe-hierarchy-list mode-${viewMode}`}>{viewMode==='grid' ? <div className="skpe-hierarchy-table-wrap"><table><thead><tr><th onClick={()=>setSortDirection(v=>v==='asc'?'desc':'asc')}>Subordinada</th><th>Superior</th><th>Tipo</th><th>Situação</th><th>Vigência</th><th>Ações</th></tr></thead><tbody>{visibleRelationships.map(item=><tr key={item.id} className="skpe-interactive-record" role="button" tabIndex={0} aria-label={`Editar vínculo de ${organizationDisplayName(orgMap.get(item.child_organization_id))}`} onClick={()=>editRelationship(item)} onKeyDown={(event)=>activateRecordWithKeyboard(event,()=>editRelationship(item))}><td>{organizationDisplayName(orgMap.get(item.child_organization_id))}</td><td>{organizationDisplayName(orgMap.get(item.parent_organization_id))}</td><td>{typeMap.get(item.relationship_type_id)?.name}</td><td>{hierarchyLabel(item.status)}</td><td>{item.valid_from} — {item.valid_until ?? 'Indeterminado'}</td><td><button title="Editar" onClick={e=>{e.stopPropagation();editRelationship(item)}}>✎</button><button title="Imprimir" onClick={e=>{e.stopPropagation();printRelationship(item)}}>⎙</button></td></tr>)}</tbody></table></div> : viewMode==='tree' ? <div className="skpe-hierarchy-tree">{visibleRelationships.map(item=><article key={item.id} className="skpe-interactive-record" role="button" tabIndex={0} onClick={()=>editRelationship(item)} onKeyDown={(event)=>activateRecordWithKeyboard(event,()=>editRelationship(item))}><strong>{organizationDisplayName(orgMap.get(item.parent_organization_id))}</strong><span>└── {organizationDisplayName(orgMap.get(item.child_organization_id))}</span><small>{typeMap.get(item.relationship_type_id)?.name} · {hierarchyLabel(item.status)}</small><div><button onClick={(event)=>{event.stopPropagation();editRelationship(item)}}>✎</button><button onClick={(event)=>{event.stopPropagation();printRelationship(item)}}>⎙</button></div></article>)}</div> : <div className="skpe-hierarchy-card-grid">{visibleRelationships.map(item=><article key={item.id} className="skpe-interactive-record" role="button" tabIndex={0} aria-label={`Editar vínculo de ${organizationDisplayName(orgMap.get(item.child_organization_id))}`} onClick={()=>editRelationship(item)} onKeyDown={(event)=>activateRecordWithKeyboard(event,()=>editRelationship(item))}><div className="skpe-hierarchy-card-head"><span>{typeMap.get(item.relationship_type_id)?.name}</span><b>{hierarchyLabel(item.status)}</b></div><h3>{organizationDisplayName(orgMap.get(item.child_organization_id))}</h3><p>Subordinada a <strong>{organizationDisplayName(orgMap.get(item.parent_organization_id))}</strong></p><small>{item.valid_from} a {item.valid_until ?? 'prazo indeterminado'}</small><footer><button title="Editar" onClick={e=>{e.stopPropagation();editRelationship(item)}}>✎</button><button title="Imprimir" onClick={e=>{e.stopPropagation();printRelationship(item)}}>⎙</button></footer></article>)}</div>}</section> : <section className={`skpe-hierarchy-list mode-${viewMode}`}>{viewMode==='grid' ? <div className="skpe-hierarchy-table-wrap"><table><thead><tr><th>Organização superior</th><th>Escopo</th><th>Módulo</th><th>Modo</th><th>Situação</th><th>Ações</th></tr></thead><tbody>{visiblePolicies.map(item=><tr key={item.id} className="skpe-interactive-record" role="button" tabIndex={0} aria-label={`Editar política de ${organizationDisplayName(orgMap.get(item.source_organization_id))}`} onClick={()=>editPolicy(item)} onKeyDown={(event)=>activateRecordWithKeyboard(event,()=>editPolicy(item))}><td>{organizationDisplayName(orgMap.get(item.source_organization_id))}</td><td>{hierarchyLabel(item.relationship_scope)}</td><td>{item.module_code ?? 'Todos'}</td><td>{hierarchyLabel(item.access_mode)}</td><td>{hierarchyLabel(item.status)}</td><td><button onClick={e=>{e.stopPropagation();editPolicy(item)}}>✎</button><button onClick={e=>{e.stopPropagation();printPolicy(item)}}>⎙</button></td></tr>)}</tbody></table></div> : <div className="skpe-hierarchy-card-grid">{visiblePolicies.map(item=><article key={item.id} className="skpe-interactive-record" role="button" tabIndex={0} aria-label={`Editar política de ${organizationDisplayName(orgMap.get(item.source_organization_id))}`} onClick={()=>editPolicy(item)} onKeyDown={(event)=>activateRecordWithKeyboard(event,()=>editPolicy(item))}><div className="skpe-hierarchy-card-head"><span>{item.module_code ?? 'Todos os módulos'}</span><b>{hierarchyLabel(item.status)}</b></div><h3>{organizationDisplayName(orgMap.get(item.source_organization_id))}</h3><p>{hierarchyLabel(item.relationship_scope)} · {hierarchyLabel(item.access_mode)}</p><small>Concordância: {hierarchyLabel(item.child_consent_status)}</small><footer><button onClick={e=>{e.stopPropagation();editPolicy(item)}}>✎</button><button onClick={e=>{e.stopPropagation();printPolicy(item)}}>⎙</button></footer></article>)}</div>}</section>}
  </>
}

function DomainTablesSection({ organizationId, canManageDomains }: DomainTablesSectionProps) {
  const [selectedCode, setSelectedCode] = useState<string>('RESPONSIBILITY_TYPE')
  const [values, setValues] = useState<DomainValueRow[]>([])
  const [loading, setLoading] = useState(true)
  const [message, setMessage] = useState<ActionMessage | null>(null)
  const [form, setForm] = useState({ code: '', name: '', description: '', order: '100', reason: '' })

  const loadDomain = async (domainCode = selectedCode) => {
    setLoading(true)
    const { data, error } = await supabase.rpc('get_sparks_domain_values', { target_domain_code: domainCode, target_organization_id: organizationId, target_module_code: 'SK-PE', include_inactive: true })
    if (error) setMessage({ type: 'error', text: error.message })
    else setValues((data ?? []) as DomainValueRow[])
    setLoading(false)
  }
  useEffect(() => { void loadDomain(selectedCode) }, [organizationId, selectedCode])

  const addValue = async () => {
    if (!form.code.trim() || !form.name.trim() || form.reason.trim().length < 10) {
      setMessage({ type: 'error', text: 'Informe código, nome e justificativa com pelo menos 10 caracteres.' })
      return
    }
    const { error } = await supabase.rpc('add_sparks_organization_domain_value', { target_organization_id: organizationId, target_domain_code: selectedCode, target_value_code: form.code, target_value_name: form.name, target_value_description: form.description || null, target_display_order: Number(form.order) || 100, change_reason: form.reason })
    if (error) setMessage({ type: 'error', text: error.message })
    else {
      setMessage({ type: 'success', text: 'Valor complementar registrado para a organização.' })
      setForm({ code: '', name: '', description: '', order: '100', reason: '' })
      await loadDomain()
    }
  }

  const allowsExtension = values.some((value) => value.allow_organization_extension)
  return <><section className="skpe-page-heading skpe-administration-heading"><div><p className="skpe-eyebrow">Padronização transversal</p><h1>Tabelas de domínio</h1><p>Consulte valores canônicos e extensões permitidas para a organização, mantendo consistência entre cadastros, indicadores, responsabilidades e fluxos.</p></div><button type="button" className="skpe-refresh-button" onClick={() => void loadDomain()} disabled={loading}><RefreshIcon />Atualizar domínio</button></section><section className="skpe-domain-layout"><aside className="skpe-domain-menu">{domainCatalog.map(([code, name]) => <button key={code} type="button" className={selectedCode === code ? 'skpe-domain-menu-active' : ''} onClick={() => setSelectedCode(code)}><strong>{name}</strong><small>{code}</small></button>)}</aside><div className="skpe-domain-content">{message && <div className={`skpe-action-message skpe-action-message-${message.type}`}>{message.text}</div>}{loading ? <section className="skpe-admin-state-card"><p>Carregando valores...</p></section> : <div className="skpe-domain-values">{values.map((value) => <article key={`${value.domain_scope}-${value.value_id}`}><div><strong>{value.value_name}</strong><span>{value.value_code}</span><small>{value.value_description ?? 'Sem descrição complementar.'}</small></div><div><b>{value.domain_scope === 'organization' ? 'Específico da organização' : value.domain_scope === 'module' ? 'Padrão do módulo' : 'Padrão global'}</b>{value.protected && <em>Protegido</em>}</div></article>)}</div>}{canManageDomains && allowsExtension && <div className="skpe-governance-form"><h3>Adicionar valor específico da organização</h3><label><span>Código *</span><input value={form.code} onChange={(event) => setForm((current) => ({ ...current, code: event.target.value }))} /></label><label><span>Nome *</span><input value={form.name} onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))} /></label><label><span>Ordem</span><input type="number" value={form.order} onChange={(event) => setForm((current) => ({ ...current, order: event.target.value }))} /></label><label className="skpe-form-field-wide"><span>Descrição</span><textarea value={form.description} onChange={(event) => setForm((current) => ({ ...current, description: event.target.value }))} /></label><label className="skpe-form-field-wide"><span>Justificativa para auditoria *</span><textarea value={form.reason} onChange={(event) => setForm((current) => ({ ...current, reason: event.target.value }))} /></label><button type="button" className="skpe-primary-action-button" onClick={() => void addValue()}>Adicionar valor</button></div>}</div></section></>
}

type AdministrationSectionProps = {
  organizationId: string
  userRoleName: string
  canManageUsers: boolean
}

type ModuleRoleOption = {
  role_code: string
  role_name: string
  role_level: number
}

type ActionMessage = {
  type: 'success' | 'error'
  text: string
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

  const [saving, setSaving] =
    useState(false)

  const [errorMessage, setErrorMessage] =
    useState('')

  const [actionMessage, setActionMessage] =
    useState<ActionMessage | null>(null)

  const [searchTerm, setSearchTerm] =
    useState('')

  const [userViewMode, setUserViewMode] = useState<'cards' | 'grid'>('grid')
  const [userSortDirection, setUserSortDirection] = useState<'asc' | 'desc'>('asc')

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

  const [
    availableRoles,
    setAvailableRoles,
  ] = useState<ModuleRoleOption[]>([])

  const [
    selectedRoleCode,
    setSelectedRoleCode,
  ] = useState('')

  const [changeReason, setChangeReason] =
    useState('')

  const users = useMemo(
    () => groupUserAccessRows(rows),
    [rows],
  )

  const availableModules = useMemo(() => {
    const modules = new Map<string, string>()

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
    }).sort((first, second) => {
      const firstName = first.displayName ?? first.email
      const secondName = second.displayName ?? second.email
      const comparison = firstName.localeCompare(secondName, 'pt-BR')
      return userSortDirection === 'asc' ? comparison : -comparison
    })
  }, [
    users,
    searchTerm,
    membershipStatusFilter,
    moduleFilter,
    userSortDirection,
  ])

  const selectedUser = useMemo(
    () =>
      users.find(
        (user) =>
          user.userId === selectedUserId,
      ) ?? null,
    [users, selectedUserId],
  )

  const selectedSkpeAccess =
    selectedUser?.modules.find(
      (module) =>
        module.moduleCode === 'SK-PE',
    ) ?? null

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

  const loadAvailableRoles = async () => {
    if (!canManageUsers) {
      setAvailableRoles([])
      return
    }

    const { data, error } = await supabase.rpc(
      'get_module_roles_for_organization',
      {
        target_organization_id:
          organizationId,
        target_module_code: 'SK-PE',
      },
    )

    if (error) {
      console.error(
        'Erro ao carregar papéis do módulo:',
        error,
      )
      setAvailableRoles([])
      return
    }

    setAvailableRoles(
      (data ?? []) as ModuleRoleOption[],
    )
  }

  useEffect(() => {
    void loadUsers()
    void loadAvailableRoles()
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

  useEffect(() => {
    setSelectedRoleCode(
      selectedSkpeAccess?.roleCode ?? '',
    )
    setChangeReason('')
    setActionMessage(null)
  }, [
    selectedUserId,
    selectedSkpeAccess?.roleCode,
  ])

  const runAction = async (
    action: () => Promise<{
      error: { message: string } | null
    }>,
    successMessage: string,
  ) => {
    if (!selectedUser) {
      return
    }

    const normalizedReason =
      changeReason.trim()

    if (normalizedReason.length < 10) {
      setActionMessage({
        type: 'error',
        text:
          'Informe uma justificativa com pelo menos 10 caracteres.',
      })
      return
    }

    setSaving(true)
    setActionMessage(null)

    const { error } = await action()

    if (error) {
      setActionMessage({
        type: 'error',
        text: error.message,
      })
      setSaving(false)
      return
    }

    await loadUsers()

    setActionMessage({
      type: 'success',
      text: successMessage,
    })
    setChangeReason('')
    setSaving(false)
  }

  const handleSaveRole = async () => {
    if (!selectedUser || !selectedRoleCode) {
      setActionMessage({
        type: 'error',
        text: 'Selecione um perfil para Planejamento Estratégico.',
      })
      return
    }

    await runAction(
      async () =>
        supabase.rpc(
          'set_user_module_role',
          {
            target_organization_id:
              organizationId,
            target_user_id:
              selectedUser.userId,
            target_module_code: 'SK-PE',
            target_role_code:
              selectedRoleCode,
            change_reason:
              changeReason.trim(),
          },
        ),
      'Perfil de Planejamento Estratégico atualizado com sucesso.',
    )
  }

  const handleModuleStatus = async (
    targetStatus: 'active' | 'suspended',
  ) => {
    if (!selectedUser) {
      return
    }

    await runAction(
      async () =>
        supabase.rpc(
          'set_user_module_access_status',
          {
            target_organization_id:
              organizationId,
            target_user_id:
              selectedUser.userId,
            target_module_code: 'SK-PE',
            target_status: targetStatus,
            change_reason:
              changeReason.trim(),
          },
        ),
      targetStatus === 'active'
        ? 'Acesso ao Planejamento Estratégico reativado com sucesso.'
        : 'Acesso ao Planejamento Estratégico suspenso com sucesso.',
    )
  }

  const handleOrganizationAdmin =
    async () => {
      if (!selectedUser) {
        return
      }

      const newValue =
        !selectedUser.isOrganizationAdmin

      await runAction(
        async () =>
          supabase.rpc(
            'set_organization_member_admin',
            {
              target_organization_id:
                organizationId,
              target_user_id:
                selectedUser.userId,
              target_is_admin: newValue,
              change_reason:
                changeReason.trim(),
            },
          ),
        newValue
          ? 'Usuário definido como administrador da organização.'
          : 'Permissão de administrador da organização removida.',
      )
    }

  const handleMembershipStatus = async (
    targetStatus: 'active' | 'suspended',
  ) => {
    if (!selectedUser) {
      return
    }

    await runAction(
      async () =>
        supabase.rpc(
          'set_organization_member_status',
          {
            target_organization_id:
              organizationId,
            target_user_id:
              selectedUser.userId,
            target_status: targetStatus,
            change_reason:
              changeReason.trim(),
          },
        ),
      targetStatus === 'active'
        ? 'Vínculo organizacional reativado com sucesso.'
        : 'Vínculo organizacional suspenso com sucesso.',
    )
  }

  if (!canManageUsers) {
    return (
      <>
        <section className="skpe-page-heading">
          <div>
            <p className="skpe-eyebrow">
              Administração do módulo
            </p>

            <h1>Usuários e Acessos</h1>

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
            Consulte e administre vínculos,
            perfis e situações de acesso dos
            usuários da organização.
          </p>
        </div>

        <button
          type="button"
          className="skpe-refresh-button"
          onClick={() => void loadUsers()}
          disabled={loading || saving}
        >
          <RefreshIcon />

          {loading
            ? 'Atualizando...'
            : 'Atualizar dados'}
        </button>
      </section>

      <section className="skpe-admin-kpi-grid">
        <article className="skpe-admin-kpi-card">
          <span>Usuários vinculados</span>
          <strong>{users.length}</strong>
          <small>Total de vínculos encontrados</small>
        </article>

        <article className="skpe-admin-kpi-card">
          <span>Usuários ativos</span>
          <strong>{activeUsersCount}</strong>
          <small>Vínculo e cadastro ativos</small>
        </article>

        <article className="skpe-admin-kpi-card">
          <span>Administradores</span>
          <strong>{organizationAdminsCount}</strong>
          <small>Administradores da organização</small>
        </article>

        <article className="skpe-admin-kpi-card">
          <span>Com acesso a módulos</span>
          <strong>{usersWithModulesCount}</strong>
          <small>Usuários com ao menos um perfil</small>
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
            <option value="all">Todas</option>
            <option value="active">Ativos</option>
            <option value="invited">Convidados</option>
            <option value="suspended">Suspensos</option>
            <option value="revoked">Revogados</option>
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
            <option value="all">Todos</option>

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

        <button type="button" className="skpe-list-sort-button" onClick={() => setUserSortDirection((current) => current === 'asc' ? 'desc' : 'asc')} title="Alterar ordenação alfabética">{userSortDirection === 'asc' ? 'A → Z' : 'Z → A'}</button>
        <div className="skpe-list-view-toggle" aria-label="Modo de visualização">
          <button type="button" className={userViewMode === 'cards' ? 'active' : ''} onClick={() => setUserViewMode('cards')} title="Visualizar em cards">▦</button>
          <button type="button" className={userViewMode === 'grid' ? 'active' : ''} onClick={() => setUserViewMode('grid')} title="Visualizar em linhas">☷</button>
        </div>
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
          <p>Carregando usuários e acessos...</p>
        </section>
      ) : filteredUsers.length === 0 ? (
        <section className="skpe-admin-state-card">
          <h2>Nenhum usuário encontrado</h2>

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
                <h2>Matriz de usuários</h2>

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

            {userViewMode === 'cards' ? (
              <div className="skpe-primary-card-grid">
                {filteredUsers.map((user) => (
                  <article key={user.userId} className={`skpe-interactive-record ${selectedUserId === user.userId ? 'selected' : ''}`} role="button" tabIndex={0} aria-label={`Abrir acessos de ${user.displayName ?? user.email}`} onClick={() => setSelectedUserId(user.userId)} onKeyDown={(event) => activateRecordWithKeyboard(event, () => setSelectedUserId(user.userId))}>
                    <header><div><strong>{user.displayName ?? user.email}</strong><span>{user.email}</span></div><span className={`skpe-access-status skpe-access-status-${user.membershipStatus}`}>{getMembershipStatusLabel(user.membershipStatus)}</span></header>
                    <p>{user.jobTitle ?? 'Função não informada'}</p>
                    <small>{user.isOrganizationAdmin ? 'Administrador da organização' : 'Participante'} · {user.modules.length} módulo(s)</small>
                    <footer><button type="button" title="Editar acessos" onClick={(event) => { event.stopPropagation(); setSelectedUserId(user.userId) }}>✎</button><button type="button" title="Imprimir ficha" onClick={(event) => { event.stopPropagation(); window.print() }}>⎙</button></footer>
                  </article>
                ))}
              </div>
            ) : (
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
                        className={`skpe-interactive-record ${
                          selectedUserId === user.userId
                            ? 'skpe-user-row-selected'
                            : ''
                        }`}
                        role="button"
                        tabIndex={0}
                        aria-label={`Abrir acessos de ${user.displayName ?? user.email}`}
                        onClick={() => setSelectedUserId(user.userId)}
                        onKeyDown={(event) =>
                          activateRecordWithKeyboard(event, () =>
                            setSelectedUserId(user.userId),
                          )
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

                              <span>{user.email}</span>

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
                            {user.modules.length === 0 ? (
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
                                      {module.moduleShortName}
                                    </strong>

                                    <span>
                                      {module.roleName}
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
                            Gerenciar
                          </button>
                        </td>
                      </tr>
                    ),
                  )}
                </tbody>
              </table>
            </div>
            )}
          </div>

          <aside className="skpe-user-detail-card">
            {selectedUser ? (
              <>
                <div className="skpe-user-detail-heading">
                  <span className="skpe-user-detail-avatar">
                    <UserIcon />
                  </span>

                  <div>
                    <p>Gestão do usuário</p>

                    <h2>
                      {selectedUser.displayName ??
                        selectedUser.email}
                    </h2>

                    <span>{selectedUser.email}</span>
                  </div>
                </div>

                <dl className="skpe-user-detail-list">
                  <div>
                    <dt>Situação do vínculo</dt>
                    <dd>
                      {getMembershipStatusLabel(
                        selectedUser.membershipStatus,
                      )}
                    </dd>
                  </div>

                  <div>
                    <dt>Cadastro do usuário</dt>
                    <dd>
                      {selectedUser.userActive
                        ? 'Ativo'
                        : 'Inativo'}
                    </dd>
                  </div>

                  <div>
                    <dt>Administrador da organização</dt>
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
                    <dt>Início do vínculo</dt>
                    <dd>
                      {formatDate(
                        selectedUser.membershipValidFrom,
                      )}
                    </dd>
                  </div>

                  <div>
                    <dt>Término do vínculo</dt>
                    <dd>
                      {formatDate(
                        selectedUser.membershipValidUntil,
                      )}
                    </dd>
                  </div>
                </dl>

                <div className="skpe-access-management-form">
                  <h3>Alterar acessos</h3>

                  <label>
                    <span>Perfil em Planejamento Estratégico</span>

                    <select
                      value={selectedRoleCode}
                      onChange={(event) =>
                        setSelectedRoleCode(
                          event.target.value,
                        )
                      }
                      disabled={saving}
                    >
                      <option value="">
                        Selecione um perfil
                      </option>

                      {availableRoles.map(
                        (role) => (
                          <option
                            key={role.role_code}
                            value={role.role_code}
                          >
                            {role.role_name}
                          </option>
                        ),
                      )}
                    </select>
                  </label>

                  <label>
                    <span>
                      Justificativa da alteração
                    </span>

                    <textarea
                      value={changeReason}
                      onChange={(event) =>
                        setChangeReason(
                          event.target.value,
                        )
                      }
                      minLength={10}
                      placeholder="Descreva o motivo da alteração para fins de auditoria."
                      disabled={saving}
                    />
                  </label>

                  {actionMessage && (
                    <div
                      className={`skpe-action-message skpe-action-message-${actionMessage.type}`}
                      role={
                        actionMessage.type ===
                        'error'
                          ? 'alert'
                          : 'status'
                      }
                    >
                      {actionMessage.text}
                    </div>
                  )}

                  <button
                    type="button"
                    className="skpe-primary-action-button"
                    onClick={() =>
                      void handleSaveRole()
                    }
                    disabled={
                      saving ||
                      !selectedRoleCode
                    }
                  >
                    {saving
                      ? 'Salvando...'
                      : 'Salvar perfil'}
                  </button>

                  <div className="skpe-secondary-actions">
                    <button
                      type="button"
                      onClick={() =>
                        void handleModuleStatus(
                          selectedSkpeAccess?.status ===
                            'active'
                            ? 'suspended'
                            : 'active',
                        )
                      }
                      disabled={saving}
                    >
                      {selectedSkpeAccess?.status ===
                      'active'
                        ? 'Suspender acesso ao Planejamento Estratégico'
                        : 'Ativar acesso ao Planejamento Estratégico'}
                    </button>

                    <button
                      type="button"
                      onClick={() =>
                        void handleOrganizationAdmin()
                      }
                      disabled={saving}
                    >
                      {selectedUser.isOrganizationAdmin
                        ? 'Remover administrador'
                        : 'Tornar administrador'}
                    </button>

                    <button
                      type="button"
                      onClick={() =>
                        void handleMembershipStatus(
                          selectedUser.membershipStatus ===
                            'active'
                            ? 'suspended'
                            : 'active',
                        )
                      }
                      disabled={saving}
                    >
                      {selectedUser.membershipStatus ===
                      'active'
                        ? 'Suspender vínculo'
                        : 'Reativar vínculo'}
                    </button>
                  </div>
                </div>

                <div className="skpe-user-detail-modules">
                  <h3>Módulos e perfis atuais</h3>

                  {selectedUser.modules.length === 0 ? (
                    <p>Nenhum módulo atribuído.</p>
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
                              <dd>{module.roleName}</dd>
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
                  Toda alteração exige
                  justificativa e é registrada na
                  trilha de auditoria.
                </div>
              </>
            ) : (
              <div className="skpe-user-detail-empty">
                <UserIcon />

                <h2>Selecione um usuário</h2>

                <p>
                  Clique em “Gerenciar” para
                  consultar e alterar vínculo,
                  perfil e permissões.
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
  mode = 'module',
  initialSection,
  onReturnToModules,
}: SkpeCockpitProps) {
  const [activeSection, setActiveSection] =
    useState<CockpitSection>(
      initialSection ??
        (mode === 'organization-admin'
          ? 'organization'
          : 'overview'),
    )

  const [organizationProfile, setOrganizationProfile] = useState<OrganizationProfileRow | null>(null)
  const [organizationLogoUrl, setOrganizationLogoUrl] = useState<string | null>(null)
  const [projectContext, setProjectContext] = useState<StrategicProjectContext | null>(null)
  const [startingProject, setStartingProject] = useState(false)
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false)
  const [theme, setTheme] = useState<'light' | 'dark'>(() => (localStorage.getItem('sparks-theme') === 'dark' ? 'dark' : 'light'))

  const loadOrganizationHeader = async () => {
    const { data, error } = await supabase.rpc('get_sparks_organization_profile_v2', {
      target_organization_id: organizationId,
    })
    if (error) return
    const loaded = ((data ?? [])[0] ?? null) as OrganizationProfileRow | null
    setOrganizationProfile(loaded)
    if (loaded?.logo_storage_path) {
      const { data: signedData } = await supabase.storage
        .from('organization-branding')
        .createSignedUrl(loaded.logo_storage_path, 60 * 60)
      setOrganizationLogoUrl(signedData?.signedUrl ?? loaded.logo_url)
    } else {
      setOrganizationLogoUrl(loaded?.logo_url ?? null)
    }
  }

  const loadStrategicProjectContext = async () => {
    const { data, error } = await supabase.rpc('get_skpe_project_context', {
      target_organization_id: organizationId,
    })

    if (error) {
      console.error('Não foi possível carregar o horizonte estratégico:', error)
      setProjectContext(null)
      return
    }

    setProjectContext(((data ?? [])[0] ?? null) as StrategicProjectContext | null)
  }

  const startStrategicProject = async () => {
    if (startingProject) return

    const currentYear = new Date().getFullYear()
    const confirmed = window.confirm(
      `Iniciar o Planejamento Estratégico de ${organizationProfile?.trade_name ?? organizationName} pela PEM-00, com horizonte sugerido de ${currentYear} a ${currentYear + 4}?`,
    )

    if (!confirmed) return

    setStartingProject(true)
    const { error } = await supabase.rpc('start_skpe_project_pem00', {
      target_organization_id: organizationId,
      target_project_name: `Planejamento Estratégico de ${organizationProfile?.trade_name ?? organizationName}`,
      target_horizon_start_year: currentYear,
      target_horizon_end_year: currentYear + 4,
    })

    if (error) {
      window.alert(`Não foi possível iniciar a jornada: ${error.message}`)
      setStartingProject(false)
      return
    }

    await loadStrategicProjectContext()
    setActiveSection('journey')
    setStartingProject(false)
  }

  const scrollToPageTop = () => {
    const scrollingElement = document.scrollingElement
    scrollingElement?.scrollTo({ top: 0, behavior: 'smooth' })
    document.documentElement.scrollTop = 0
    document.body.scrollTop = 0
    window.scrollTo({ top: 0, behavior: 'smooth' })
    document.querySelector<HTMLElement>('.skpe-main')?.scrollTo({ top: 0, behavior: 'smooth' })
  }

  useEffect(() => {
    void loadOrganizationHeader()

    if (mode === 'module') {
      void loadStrategicProjectContext()
    } else {
      setProjectContext(null)
    }
  }, [organizationId, mode])
  useEffect(() => {
    localStorage.setItem('sparks-theme', theme)
  }, [theme])

  const canManageUsers =
    isOrganizationAdmin ||
    userRoleCode === 'administrator'

  const canManageJourney =
    isOrganizationAdmin ||
    isPlatformSuperAdmin ||
    [
      'administrator',
      'manager',
      'editor',
    ].includes(userRoleCode)

  const canManageCanvas =
    canManageJourney


  const canManageGovernance =
    isOrganizationAdmin ||
    isPlatformSuperAdmin ||
    userRoleCode === 'administrator'

  const canManageOrganization =
    isOrganizationAdmin ||
    isPlatformSuperAdmin ||
    userRoleCode === 'administrator'

  return (
    <div className={`skpe-shell skpe-theme-${theme} ${sidebarCollapsed ? 'skpe-sidebar-collapsed' : ''}`}>
      <aside className="skpe-sidebar">
        <div className="skpe-sidebar-brand">
          <img className="skpe-platform-mascot" src="/sparkoop-mascot.png" alt="Mascote da SPARKOOP" />
          <div className="skpe-sidebar-brand-text">
            <strong>Plataforma SPARKs</strong>
            <span className="skpe-sidebar-user-role">{userRoleName}</span>

          </div>
          <button type="button" className="skpe-sidebar-icon-button" onClick={() => setSidebarCollapsed((value) => !value)} aria-label={sidebarCollapsed ? 'Expandir menu' : 'Comprimir menu'} title={sidebarCollapsed ? 'Expandir menu' : 'Comprimir menu'}>☰</button>
        </div>
        <div className="skpe-theme-switcher">
          <button
            type="button"
            onClick={() =>
              setTheme(
                theme === 'light' ? 'dark' : 'light',
              )
            }
            title={
              theme === 'light'
                ? 'Ativar tema escuro'
                : 'Ativar tema claro'
            }
            aria-label={
              theme === 'light'
                ? 'Ativar tema escuro'
                : 'Ativar tema claro'
            }
          >
            <span aria-hidden="true">
              {theme === 'light' ? '☾' : '☀'}
            </span>
          </button>
        </div>

        <div className="skpe-organization-context">
          <div className="skpe-organization-context-logo">
            {organizationLogoUrl ? <img src={organizationLogoUrl} alt={`Logo de ${organizationProfile?.trade_name ?? organizationName}`} /> : <span>{getOrganizationInitials(organizationProfile?.trade_name ?? organizationName)}</span>}
          </div>
          <div>
            <span>Organização</span>
            <strong>{organizationProfile?.trade_name ?? organizationName}</strong>
            <small>{getCooperativeBranchLabel(organizationProfile?.cooperative_branch)}</small>
          </div>
        </div>

        <nav
          className="skpe-navigation"
          aria-label={
            mode === 'organization-admin'
              ? 'Navegacao da Administração da Organização'
              : 'Navegacao de Planejamento Estratégico'
          }
        >
          {mode === 'module' ? (
            <>
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
                  activeSection === 'initiatives'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection('initiatives')
                }
              >
                <InitiativesIcon />
                Iniciativas
              </button>

              <button
                type="button"
                className={
                  activeSection === 'artifacts'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection('artifacts')
                }
              >
                <DashboardIcon />
                Artefatos e evidências
              </button>

              <button
                type="button"
                className={
                  activeSection === 'governance'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection('governance')
                }
              >
                <GovernanceIcon />
                Governança
              </button>

              <button
                type="button"
                className={
                  activeSection === 'administration'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection('administration')
                }
              >
                <AdministrationIcon />
                <span>Administração do SK-PE</span>
              </button>
            </>
          ) : (
            <>
              <button
                type="button"
                className={
                  activeSection === 'organization'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection('organization')
                }
              >
                <OrganizationIcon />
                <span>Cadastro institucional</span>
              </button>

              <button
                type="button"
                className={
                  activeSection === 'administration'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection('administration')
                }
              >
                <UserIcon />
                <span>Usuários e acessos</span>
              </button>

              <button
                type="button"
                className={
                  activeSection === 'governance-roles'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection('governance-roles')
                }
              >
                <GovernanceIcon />
                <span>Papéis e responsabilidades</span>
              </button>

              <button
                type="button"
                className={
                  activeSection === 'organizational-areas'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection('organizational-areas')
                }
              >
                <OrganizationIcon />
                <span>Áreas e estrutura</span>
              </button>

              <button
                type="button"
                className={
                  activeSection === 'organization-hierarchy'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection(
                    'organization-hierarchy',
                  )
                }
              >
                <OrganizationIcon />
                <span>Hierarquia e acessos</span>
              </button>

              <button
                type="button"
                className={
                  activeSection === 'domains'
                    ? 'skpe-nav-active'
                    : ''
                }
                onClick={() =>
                  setActiveSection('domains')
                }
              >
                <DashboardIcon />
                <span>Tabelas de domínio</span>
              </button>
            </>
          )}
        </nav>

        <div className="skpe-sidebar-footer">
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
            {mode === 'organization-admin'
              ? 'Voltar à organização'
              : 'Voltar aos módulos'}
          </button>
        </div>
      </aside>

      <main className="skpe-main">
        {activeSection ===
          'overview' && (
          <OverviewSection
            organizationName={organizationProfile?.trade_name ?? organizationName}
            organizationCode={organizationCode}
            projectContext={projectContext}
            canManageJourney={canManageJourney}
            startingProject={startingProject}
            onStartProject={() => void startStrategicProject()}
            onNavigate={setActiveSection}
          />
        )}

        {activeSection ===
          'journey' && (
          <JourneySection
            organizationId={
              organizationId
            }
            canManageJourney={
              canManageJourney
            }
          />
        )}

        {activeSection ===
          'initiatives' && (
          <InitiativesSection
            organizationId={
              organizationId
            }
            canManageCanvas={
              canManageCanvas
            }
            canManageInitiatives={
              canManageJourney
            }
          />
        )}

        {activeSection === 'artifacts' && (
          <MethodologyArtifactsSection
            organizationId={organizationId}
            projectId={projectContext?.project_id ?? ''}
            canManage={canManageJourney}
          />
        )}

        {activeSection ===
          'governance' && (
          <GovernanceSection />
        )}

        {activeSection === 'governance-roles' && (
          <GovernanceOperationsSection organizationId={organizationId} canManageGovernance={canManageGovernance} />
        )}

        {activeSection === 'organizational-areas' && (
          <OrganizationalAreasSection organizationId={organizationId} canManageAreas={canManageGovernance} />
        )}

        {activeSection === 'organization-hierarchy' && (
          <OrganizationHierarchySection organizationId={organizationId} canManage={canManageOrganization} />
        )}

        {activeSection === 'domains' && (
          <DomainTablesSection organizationId={organizationId} canManageDomains={canManageGovernance} />
        )}

        {activeSection === 'organization' && (
          <OrganizationSection
            organizationId={organizationId}
            canManageOrganization={canManageOrganization}
            onProfileUpdated={(profile, logoUrl) => {
              setOrganizationProfile(profile)
              setOrganizationLogoUrl(logoUrl)
            }}
          />
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

      <button
        type="button"
        className="skpe-scroll-top-button"
        onClick={scrollToPageTop}
        title="Voltar ao início da tela"
        aria-label="Voltar ao início da tela"
      >
        ↑
      </button>
    </div>
  )
}
