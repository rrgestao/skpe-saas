import type { SkpeRouteSection } from '../app/skpeRoutes'

export type WorkspaceDashboardId =
  | 'my-work'
  | 'executive'
  | 'organization'
  | 'formulation'
  | 'indicators'
  | 'okrs'
  | 'portfolio'
  | 'monitoring'
  | 'governance'

export type WorkspaceRequiredContext =
  | 'organization'
  | 'project'
  | 'formulation'
  | 'cycle'
  | 'user'

export type WorkspaceDashboardAvailability =
  | 'enabled'
  | 'disabled'
  | 'coming-soon'
  | 'requires-context'
  | 'forbidden'

export type SkpeWorkspaceCapability =
  | 'can_view_overview'
  | 'can_view_journey'
  | 'can_view_initiatives'
  | 'can_view_artifacts'
  | 'can_generate_delivery_kit'
  | 'can_view_governance'
  | 'can_manage_journey'
  | 'can_manage_artifacts'
  | 'can_manage_skpe'
  | 'can_administer_users'
  | 'can_administer_memberships'
  | 'can_administer_settings'

export type WorkspaceDashboardDefinition = {
  id: WorkspaceDashboardId
  label: string
  description: string
  section: SkpeRouteSection | null
  requiredContext: readonly WorkspaceRequiredContext[]
  requiredCapability: SkpeWorkspaceCapability | null
  defaultAvailability: WorkspaceDashboardAvailability
  supportsDrillDown: boolean
}

export const WORKSPACE_DASHBOARDS = [
  {
    id: 'my-work',
    label: 'Meu Trabalho',
    description:
      'Consolida responsabilidades, pendências e acessos pessoais disponíveis no contexto atual.',
    section: 'overview',
    requiredContext: ['organization', 'user'],
    requiredCapability: 'can_view_overview',
    defaultAvailability: 'enabled',
    supportsDrillDown: true,
  },
  {
    id: 'executive',
    label: 'Executivo',
    description:
      'Apresenta a situação do projeto estratégico, seu progresso, etapa atual e horizonte.',
    section: 'overview',
    requiredContext: ['organization', 'project'],
    requiredCapability: 'can_view_overview',
    defaultAvailability: 'enabled',
    supportsDrillDown: true,
  },
  {
    id: 'organization',
    label: 'Organização',
    description:
      'Direciona para as informações institucionais e administrativas autorizadas.',
    section: null,
    requiredContext: ['organization'],
    requiredCapability: null,
    defaultAvailability: 'disabled',
    supportsDrillDown: false,
  },
  {
    id: 'formulation',
    label: 'Formulação',
    description:
      'Acessa as versões, conteúdos e controles da Formulação Estratégica.',
    section: 'formulations',
    requiredContext: ['organization', 'project', 'formulation'],
    requiredCapability: null,
    defaultAvailability: 'coming-soon',
    supportsDrillDown: true,
  },
  {
    id: 'indicators',
    label: 'Indicadores',
    description:
      'Acessa indicadores, metas, medições e referências de desempenho.',
    section: 'indicators',
    requiredContext: ['organization', 'project', 'formulation'],
    requiredCapability: null,
    defaultAvailability: 'coming-soon',
    supportsDrillDown: true,
  },
  {
    id: 'okrs',
    label: 'Objetivos Estratégicos — OKRs',
    description:
      'Acessa Objetivos Estratégicos — OKRs e seus Resultados-Chave.',
    section: 'okrs',
    requiredContext: ['organization', 'project', 'formulation'],
    requiredCapability: null,
    defaultAvailability: 'coming-soon',
    supportsDrillDown: true,
  },
  {
    id: 'portfolio',
    label: 'Portfólio',
    description:
      'Acessa Iniciativas, programas, projetos e planos de ação vinculados.',
    section: 'initiatives',
    requiredContext: ['organization', 'project'],
    requiredCapability: 'can_view_initiatives',
    defaultAvailability: 'enabled',
    supportsDrillDown: true,
  },
  {
    id: 'monitoring',
    label: 'Monitoramento',
    description:
      'Acessa ciclos, medições, check-ins e acompanhamento estratégico.',
    section: 'monitoring',
    requiredContext: ['organization', 'project', 'formulation'],
    requiredCapability: null,
    defaultAvailability: 'coming-soon',
    supportsDrillDown: true,
  },
  {
    id: 'governance',
    label: 'Governança',
    description:
      'Acessa papéis, decisões, validações e controles metodológicos.',
    section: 'governance',
    requiredContext: ['organization', 'project'],
    requiredCapability: 'can_view_governance',
    defaultAvailability: 'enabled',
    supportsDrillDown: true,
  },
] as const satisfies readonly WorkspaceDashboardDefinition[]

export function getWorkspaceDashboard(
  dashboardId: WorkspaceDashboardId,
): WorkspaceDashboardDefinition {
  const dashboard = WORKSPACE_DASHBOARDS.find(
    (item) => item.id === dashboardId,
  )

  if (!dashboard) {
    throw new Error(
      `Painel do Meu Espaço de Trabalho não encontrado: ${dashboardId}`,
    )
  }

  return dashboard
}
