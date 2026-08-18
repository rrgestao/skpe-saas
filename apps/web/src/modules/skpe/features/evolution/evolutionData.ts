import { supabase } from '../../../../lib/supabase'

import type {
  EvolutionCycleRow,
  EvolutionPlanRow,
  EvolutionScenarioAlignmentInput,
  EvolutionScenarioCycleRow,
  EvolutionScenarioRow,
  ObjectiveEvolutionAlignmentReadiness,
  ObjectiveEvolutionScenarioAlignmentRow,
  StrategicHorizonRow,
  StrategicObjectiveEvolutionRow,
} from '../../contracts/evolution'

export type EvolutionOverviewData = {
  horizon: StrategicHorizonRow | null
  scenarios: EvolutionScenarioRow[]
  scenarioCycles: EvolutionScenarioCycleRow[]
  plans: EvolutionPlanRow[]
  cycles: EvolutionCycleRow[]
  readiness: ObjectiveEvolutionAlignmentReadiness | null
}

export type ObjectiveEvolutionAlignmentEditorData = {
  formulationId: string | null
  objectives: StrategicObjectiveEvolutionRow[]
  alignments: ObjectiveEvolutionScenarioAlignmentRow[]
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

export async function canManageObjectiveEvolutionAlignment(
  organizationId: string,
): Promise<boolean> {
  const result = await supabase.rpc(
    'can_manage_skpe_objective_evolution_alignment',
    {
      target_organization_id: organizationId,
    },
  )

  if (result.error) {
    throwSupabaseError(
      'Falha ao avaliar a permissão de gestão dos alinhamentos Objetivo–Ciclo',
      result.error,
    )
  }

  return result.data === true
}

export async function loadObjectiveEvolutionAlignmentEditorData(
  projectId: string,
  scenarioId: string,
): Promise<ObjectiveEvolutionAlignmentEditorData> {
  const formulationResult = await supabase
    .from('skpe_strategic_formulations')
    .select('id')
    .eq('project_id', projectId)
    .order('version_number', {
      ascending: false,
    })
    .limit(1)

  if (formulationResult.error) {
    throwSupabaseError(
      'Falha ao identificar a Formulação Estratégica mais recente',
      formulationResult.error,
    )
  }

  const formulationId =
    formulationResult.data?.[0]?.id ?? null

  if (!formulationId) {
    return {
      formulationId: null,
      objectives: [],
      alignments: [],
    }
  }

  const [
    objectivesResult,
    alignmentsResult,
  ] = await Promise.all([
    supabase
      .from('skpe_strategic_objectives')
      .select('*')
      .eq('project_id', projectId)
      .eq('formulation_id', formulationId)
      .neq('status', 'archived')
      .order('code', {
        ascending: true,
      }),

    supabase
      .from('skpe_objective_evolution_scenario_alignments')
      .select('*')
      .eq('project_id', projectId)
      .eq('formulation_id', formulationId)
      .eq('scenario_id', scenarioId)
      .order('strategic_objective_id', {
        ascending: true,
      })
      .order('scenario_cycle_id', {
        ascending: true,
      }),
  ])

  if (objectivesResult.error) {
    throwSupabaseError(
      'Falha ao carregar os Objetivos Estratégicos — OKRs',
      objectivesResult.error,
    )
  }

  if (alignmentsResult.error) {
    throwSupabaseError(
      'Falha ao carregar os alinhamentos propostos Objetivo–Ciclo',
      alignmentsResult.error,
    )
  }

  return {
    formulationId,

    objectives:
      (objectivesResult.data ??
        []) as StrategicObjectiveEvolutionRow[],

    alignments:
      (alignmentsResult.data ??
        []) as ObjectiveEvolutionScenarioAlignmentRow[],
  }
}

export async function saveObjectiveEvolutionScenarioAlignment(
  input: EvolutionScenarioAlignmentInput,
): Promise<string> {
  const result = await supabase.rpc(
    'upsert_skpe_objective_evolution_scenario_alignment',
    {
      target_formulation_id:
        input.formulationId,

      target_strategic_objective_id:
        input.strategicObjectiveId,

      target_scenario_cycle_id:
        input.scenarioCycleId,

      target_alignment_id:
        input.alignmentId,

      target_alignment_role:
        input.alignmentRole,

      target_contribution_weight:
        input.contributionWeight,

      target_expected_result_in_cycle:
        input.expectedResultInCycle,

      target_alignment_rationale:
        input.rationale,

      change_reason:
        input.changeReason,
    },
  )

  if (result.error) {
    throwSupabaseError(
      'Falha ao salvar o alinhamento proposto Objetivo–Ciclo',
      result.error,
    )
  }

  if (typeof result.data !== 'string') {
    throw new Error(
      'Falha ao salvar o alinhamento proposto Objetivo–Ciclo: identificador não retornado.',
    )
  }

  return result.data
}

export async function deleteObjectiveEvolutionScenarioAlignment(
  alignmentId: string,
  changeReason: string,
): Promise<void> {
  const result = await supabase.rpc(
    'delete_skpe_objective_evolution_scenario_alignment',
    {
      target_alignment_id:
        alignmentId,

      change_reason:
        changeReason,
    },
  )

  if (result.error) {
    throwSupabaseError(
      'Falha ao remover o alinhamento proposto Objetivo–Ciclo',
      result.error,
    )
  }
}