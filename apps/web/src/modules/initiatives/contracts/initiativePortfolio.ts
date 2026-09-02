export type InitiativePortfolioDashboardRow = {
  total_initiatives: number
  proposed_count: number
  in_progress_count: number
  completed_count: number
  blocked_count: number
  critical_count: number
  average_progress: number
}

export type InitiativePortfolioRow = {
  initiative_id: string
  organization_id: string
  skpe_project_id: string | null
  parent_initiative_id: string | null
  responsible_name: string | null
  is_strategic: boolean

  category_id: string
  category_code: string
  category_name: string

  initiative_class: string
  initiative_code: string
  initiative_name: string
  initiative_description: string | null
  initiative_status: string

  priority: string
  criticality: string

  responsible_area_id: string | null
  responsible_area_code: string | null
  responsible_area_name: string | null

  proposal_origin: string
  source_module_code: string
  proposal_source_reference: string | null
  validation_status: string

  strategic_theme: string | null
  strategic_theme_names: string[]
  strategic_objective_names: string[]

  start_date: string | null
  target_end_date: string | null
  progress: number

  risk_level: string
  health_status: string
  last_update_at: string | null

  created_at: string
  updated_at: string
}

export type InitiativePortfolioFilters = {
  status?: string | null
  initiativeClass?: string | null
  categoryCode?: string | null
  sourceModuleCode?: string | null
}

export type InitiativePortfolioResult = {
  dashboard: InitiativePortfolioDashboardRow | null
  initiatives: InitiativePortfolioRow[]
}