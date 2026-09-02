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

function uniqueSorted(values: Array<string | null | undefined>) {
  return Array.from(
    new Set(
      values
        .map((value) => value?.trim() ?? '')
        .filter(Boolean),
    ),
  ).sort((first, second) => first.localeCompare(second, 'pt-BR'))
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
      Omit<
        InitiativePortfolioRow,
        | 'parent_initiative_id'
        | 'responsible_name'
        | 'is_strategic'
        | 'strategic_theme_names'
        | 'strategic_objective_names'
      >[]
  ).map((row) =>
    mapPortfolioRow({
      ...row,
      parent_initiative_id: null,
      responsible_name: null,
      is_strategic: Boolean(row.skpe_project_id),
      strategic_theme_names: uniqueSorted([row.strategic_theme]),
      strategic_objective_names: [],
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

  const initiativeIds =
    portfolioRows.map((initiative) => initiative.initiative_id)

  const { data: hierarchyData, error: hierarchyError } =
    await supabase
      .from('sparks_initiatives')
      .select('id, parent_initiative_id, who_text, strategic_theme')
      .eq('organization_id', organizationId)
      .in('id', initiativeIds)

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

  const responsibleByInitiative = new Map(
    (hierarchyData ?? []).map((row) => [
      row.id as string,
      ((row.who_text as string | null) ?? '').trim() || null,
    ]),
  )

  const directThemeByInitiative = new Map(
    (hierarchyData ?? []).map((row) => [
      row.id as string,
      ((row.strategic_theme as string | null) ?? '').trim() || null,
    ]),
  )

  const { data: objectiveLinks, error: objectiveLinksError } =
    await supabase
      .from('skpe_initiative_objectives')
      .select('initiative_id, strategic_objective_id')
      .eq('organization_id', organizationId)
      .in('initiative_id', initiativeIds)

  if (objectiveLinksError) {
    throw new Error(
      `Não foi possível carregar os vínculos estratégicos das iniciativas: ${objectiveLinksError.message}`,
    )
  }

  const objectiveIds = Array.from(
    new Set(
      (objectiveLinks ?? [])
        .map((row) => row.strategic_objective_id as string | null)
        .filter((value): value is string => Boolean(value)),
    ),
  )

  const objectiveById = new Map<
    string,
    {
      label: string
      strategicTheme: string | null
      strategicThemeId: string | null
    }
  >()

  if (objectiveIds.length > 0) {
    const { data: objectives, error: objectivesError } =
      await supabase
        .from('skpe_strategic_objectives')
        .select('id, code, name, strategic_theme, strategic_theme_id')
        .eq('organization_id', organizationId)
        .in('id', objectiveIds)

    if (objectivesError) {
      throw new Error(
        `Não foi possível carregar os Objetivos Estratégicos vinculados: ${objectivesError.message}`,
      )
    }

    for (const objective of objectives ?? []) {
      const code = ((objective.code as string | null) ?? '').trim()
      const name = ((objective.name as string | null) ?? '').trim()
      objectiveById.set(objective.id as string, {
        label: code && name ? `${code} · ${name}` : name || code || 'Objetivo sem identificação',
        strategicTheme:
          ((objective.strategic_theme as string | null) ?? '').trim() || null,
        strategicThemeId:
          (objective.strategic_theme_id as string | null) ?? null,
      })
    }
  }

  const themeIds = Array.from(
    new Set(
      Array.from(objectiveById.values())
        .map((objective) => objective.strategicThemeId)
        .filter((value): value is string => Boolean(value)),
    ),
  )

  const themeNameById = new Map<string, string>()

  if (themeIds.length > 0) {
    const { data: themes, error: themesError } =
      await supabase
        .from('skpe_strategic_themes')
        .select('id, code, name')
        .eq('organization_id', organizationId)
        .in('id', themeIds)

    if (themesError) {
      throw new Error(
        `Não foi possível carregar os Temas Estratégicos vinculados: ${themesError.message}`,
      )
    }

    for (const theme of themes ?? []) {
      const code = ((theme.code as string | null) ?? '').trim()
      const name = ((theme.name as string | null) ?? '').trim()
      themeNameById.set(
        theme.id as string,
        code && name ? `${code} · ${name}` : name || code || 'Tema sem identificação',
      )
    }
  }

  const objectiveNamesByInitiative = new Map<string, string[]>()
  const themeNamesByInitiative = new Map<string, string[]>()
  const objectiveLinkedIds = new Set<string>()

  for (const link of objectiveLinks ?? []) {
    const initiativeId = link.initiative_id as string
    const objectiveId = link.strategic_objective_id as string
    const objective = objectiveById.get(objectiveId)

    objectiveLinkedIds.add(initiativeId)

    if (objective) {
      objectiveNamesByInitiative.set(
        initiativeId,
        uniqueSorted([
          ...(objectiveNamesByInitiative.get(initiativeId) ?? []),
          objective.label,
        ]),
      )

      const resolvedTheme =
        (objective.strategicThemeId
          ? themeNameById.get(objective.strategicThemeId)
          : null) ??
        objective.strategicTheme

      themeNamesByInitiative.set(
        initiativeId,
        uniqueSorted([
          ...(themeNamesByInitiative.get(initiativeId) ?? []),
          resolvedTheme,
        ]),
      )
    }
  }

  return {
    dashboard: rawDashboard
      ? mapDashboardRow(rawDashboard)
      : null,
    initiatives: portfolioRows.map((initiative) => {
      const directTheme =
        directThemeByInitiative.get(initiative.initiative_id) ??
        initiative.strategic_theme

      const strategicThemeNames = uniqueSorted([
        directTheme,
        ...(themeNamesByInitiative.get(initiative.initiative_id) ?? []),
      ])

      return {
        ...initiative,
        parent_initiative_id:
          parentByInitiative.get(initiative.initiative_id) ?? null,
        responsible_name:
          responsibleByInitiative.get(initiative.initiative_id) ?? null,
        strategic_theme_names: strategicThemeNames,
        strategic_objective_names:
          objectiveNamesByInitiative.get(initiative.initiative_id) ?? [],
        is_strategic:
          Boolean(initiative.skpe_project_id) ||
          strategicThemeNames.length > 0 ||
          objectiveLinkedIds.has(initiative.initiative_id),
      }
    }),
  }
}