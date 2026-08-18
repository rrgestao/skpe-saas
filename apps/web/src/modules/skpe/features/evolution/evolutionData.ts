import { supabase } from '../../../../lib/supabase'

import type {
  EvolutionCycleRow,
  EvolutionPlanRow,
  EvolutionScenarioCycleRow,
  EvolutionScenarioRow,
  ObjectiveEvolutionAlignmentReadiness,
  StrategicHorizonRow,
} from '../../contracts/evolution'

export type EvolutionOverviewData = {
  horizon: StrategicHorizonRow | null
  scenarios: EvolutionScenarioRow[]
  scenarioCycles: EvolutionScenarioCycleRow[]
  plans: EvolutionPlanRow[]
  cycles: EvolutionCycleRow[]
  readiness: ObjectiveEvolutionAlignmentReadiness | null
}

function throwSupabaseError(
  context: string,
  error: { message: string },
): never {
  throw new Error(`${context}: ${error.message}`)
}

export async function loadEvolutionOverview(
  projectId: string,
): Promise<EvolutionOverviewData> {
  const [
    horizonResult,
    scenariosResult,
    scenarioCyclesResult,
    plansResult,
    cyclesResult,
    readinessResult,
  ] = await Promise.all([
    supabase
      .from('skpe_strategic_horizons')
      .select('*')
      .eq('project_id', projectId)
      .eq('is_current', true)
      .order('version_number', {
        ascending: false,
      })
      .limit(1),

    supabase
      .from('skpe_evolution_scenarios')
      .select('*')
      .eq('project_id', projectId)
      .order('version_number', {
        ascending: false,
      }),

    supabase
      .from('skpe_evolution_scenario_cycles')
      .select('*')
      .eq('project_id', projectId)
      .order('scenario_id', {
        ascending: true,
      })
      .order('sequence_number', {
        ascending: true,
      }),

    supabase
      .from('skpe_evolution_plans')
      .select('*')
      .eq('project_id', projectId)
      .order('version_number', {
        ascending: false,
      }),

    supabase
      .from('skpe_evolution_cycles')
      .select('*')
      .eq('project_id', projectId)
      .order('sequence_number', {
        ascending: true,
      }),

    supabase.rpc(
      'get_skpe_objective_evolution_alignment_readiness',
      {
        target_project_id: projectId,
      },
    ),
  ])

  if (horizonResult.error) {
    throwSupabaseError(
      'Falha ao carregar o Horizonte Estratégico',
      horizonResult.error,
    )
  }

  if (scenariosResult.error) {
    throwSupabaseError(
      'Falha ao carregar os Cenários de Evolução',
      scenariosResult.error,
    )
  }

  if (scenarioCyclesResult.error) {
    throwSupabaseError(
      'Falha ao carregar os Ciclos de Evolução propostos',
      scenarioCyclesResult.error,
    )
  }

  if (plansResult.error) {
    throwSupabaseError(
      'Falha ao carregar os Planos de Evolução',
      plansResult.error,
    )
  }

  if (cyclesResult.error) {
    throwSupabaseError(
      'Falha ao carregar os Ciclos de Evolução institucionalizados',
      cyclesResult.error,
    )
  }

  if (readinessResult.error) {
    throwSupabaseError(
      'Falha ao avaliar a prontidão Objetivo–Ciclo',
      readinessResult.error,
    )
  }

  return {
    horizon:
      ((horizonResult.data ?? [])[0] ??
        null) as StrategicHorizonRow | null,

    scenarios:
      (scenariosResult.data ??
        []) as EvolutionScenarioRow[],

    scenarioCycles:
      (scenarioCyclesResult.data ??
        []) as EvolutionScenarioCycleRow[],

    plans:
      (plansResult.data ??
        []) as EvolutionPlanRow[],

    cycles:
      (cyclesResult.data ??
        []) as EvolutionCycleRow[],

    readiness:
      (readinessResult.data ??
        null) as ObjectiveEvolutionAlignmentReadiness | null,
  }
}