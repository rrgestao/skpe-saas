import { supabase } from '../../../lib/supabase'

import type {
  InitiativePortfolioDashboardRow,
  InitiativePortfolioFilters,
  InitiativePortfolioResult,
  InitiativePortfolioRow,
} from '../contracts/initiativePortfolio'

function normalizeNumber(value: unknown) {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : 0
}

function mapPortfolioRow(
  row: InitiativePortfolioRow,
): InitiativePortfolioRow {
  return {
    ...row,
    progress: Math.min(
      100,
      Math.max(0, normalizeNumber(row.progress)),
    ),
  }
}

function mapDashboardRow(
  row: InitiativePortfolioDashboardRow,
): InitiativePortfolioDashboardRow {
  return {
    total_initiatives:
      normalizeNumber(row.total_initiatives),
    proposed_count:
      normalizeNumber(row.proposed_count),
    in_progress_count:
      normalizeNumber(row.in_progress_count),
    completed_count:
      normalizeNumber(row.completed_count),
    blocked_count:
      normalizeNumber(row.blocked_count),
    critical_count:
      normalizeNumber(row.critical_count),
    average_progress:
      normalizeNumber(row.average_progress),
  }
}

export async function loadInitiativePortfolio(
  organizationId: string,
  filters: InitiativePortfolioFilters = {},
): Promise<InitiativePortfolioResult> {
  const rpcFilters = {
    target_organization_id: organizationId,
    target_status: filters.status ?? null,
    target_initiative_class:
      filters.initiativeClass ?? null,
    target_category_code:
      filters.categoryCode ?? null,
    target_source_module_code:
      filters.sourceModuleCode ?? null,
  }

  const [
    dashboardResponse,
    portfolioResponse,
  ] = await Promise.all([
    supabase.rpc(
      'get_sparks_initiatives_portfolio_dashboard',
      rpcFilters,
    ),
    supabase.rpc(
      'get_sparks_initiatives_portfolio',
      rpcFilters,
    ),
  ])

  if (
    dashboardResponse.error ||
    portfolioResponse.error
  ) {
    throw new Error(
      dashboardResponse.error?.message ??
        portfolioResponse.error?.message ??
        'Não foi possível carregar o portfólio transversal.',
    )
  }

  const rawDashboard = (
    (dashboardResponse.data ?? []) as
      InitiativePortfolioDashboardRow[]
  )[0]

  const portfolioRows = (
    (portfolioResponse.data ?? []) as
      Omit<InitiativePortfolioRow, 'parent_initiative_id'>[]
  ).map((row) =>
    mapPortfolioRow({
      ...row,
      parent_initiative_id: null,
    }),
  )

  if (portfolioRows.length === 0) {
    return {
      dashboard: rawDashboard
        ? mapDashboardRow(rawDashboard)
        : null,
      initiatives: [],
    }
  }

  const { data: hierarchyData, error: hierarchyError } =
    await supabase
      .from('sparks_initiatives')
      .select('id, parent_initiative_id')
      .eq('organization_id', organizationId)
      .in(
        'id',
        portfolioRows.map((initiative) => initiative.initiative_id),
      )

  if (hierarchyError) {
    throw new Error(
      `Não foi possível carregar a hierarquia das iniciativas: ${hierarchyError.message}`,
    )
  }

  const parentByInitiative = new Map(
    (hierarchyData ?? []).map((row) => [
      row.id as string,
      (row.parent_initiative_id as string | null) ?? null,
    ]),
  )

  return {
    dashboard: rawDashboard
      ? mapDashboardRow(rawDashboard)
      : null,
    initiatives: portfolioRows.map((initiative) => ({
      ...initiative,
      parent_initiative_id:
        parentByInitiative.get(initiative.initiative_id) ?? null,
    })),
  }
}