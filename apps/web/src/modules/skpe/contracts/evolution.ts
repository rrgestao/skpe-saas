/**
 * SK-PE-CONT-01
 * GATE-17-B.4C.8 — Ciclos de Evolução:
 * Contrato de Aplicação e Integração Governada
 *
 * Este contrato espelha o domínio persistido do SK-PE.
 *
 * Invariantes:
 * - Scenario Cycle != Evolution Cycle.
 * - Cenário proposto != Plano institucional.
 * - Alinhamento proposto != Alinhamento institucional.
 * - Strategic Period != Governance Period != Execution Period != Measurement Period.
 * - Objetivos, OKRs e KRs não recebem evolution_cycle_id diretamente.
 */

export type JsonPrimitive =
  | string
  | number
  | boolean
  | null

export type JsonValue =
  | JsonPrimitive
  | JsonValue[]
  | { [key: string]: JsonValue }

export type EvolutionScenarioStatus =
  | 'draft'
  | 'submitted'
  | 'approved'
  | 'adjusted'
  | 'rejected'
  | 'superseded'
  | string

export type EvolutionAlignmentRole =
  | 'primary'
  | 'supporting'
  | 'sustaining'

export type EvolutionAlignmentValidationStatus =
  | 'draft'
  | 'pending_validation'
  | 'validated'
  | 'rejected'
  | string

export type StrategicHorizonRow = {
  id: string
  organization_id: string
  project_id: string
  proposal_id: string | null
  version_number: number

  horizon_start_year: number
  horizon_end_year: number

  valid_from: string | null
  valid_until: string | null

  governance_status: string
  is_current: boolean

  decision_origin_type: string
  decision_gate_id: string | null
  source_reference: string | null

  regularization_status: string
  supersedes_horizon_id: string | null

  metadata: JsonValue

  approved_at: string | null
  approved_by: string | null

  superseded_at: string | null
  superseded_by: string | null

  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
}

export type EvolutionScenarioRow = {
  id: string
  organization_id: string
  project_id: string
  strategic_horizon_id: string

  version_number: number
  status: EvolutionScenarioStatus

  title: string
  description: string | null
  strategic_rationale: string | null

  origin_type: string
  source_reference: string | null
  coverage_policy: string

  supersedes_scenario_id: string | null

  metadata: JsonValue

  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
}

export type EvolutionScenarioCycleRow = {
  id: string
  organization_id: string
  project_id: string

  strategic_horizon_id: string
  scenario_id: string

  sequence_number: number

  title: string
  description: string | null

  period_start: string
  period_end: string

  strategic_intent: string | null
  expected_outcome: string | null

  target_maturity: JsonValue
  assumptions: JsonValue
  entry_criteria: JsonValue
  exit_criteria: JsonValue
  strategic_focus: JsonValue

  rationale: string | null

  metadata: JsonValue

  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
}

export type EvolutionPlanRow = {
  id: string
  organization_id: string
  project_id: string

  strategic_horizon_id: string
  source_scenario_id: string | null

  version_number: number
  governance_status: string
  is_current: boolean

  decision_origin_type: string
  decision_gate_id: string | null
  source_reference: string | null

  valid_from: string | null
  valid_until: string | null

  supersedes_plan_id: string | null

  approved_at: string | null
  approved_by: string | null

  superseded_at: string | null
  superseded_by: string | null

  metadata: JsonValue

  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
}

export type EvolutionCycleRow = {
  id: string
  organization_id: string
  project_id: string

  strategic_horizon_id: string
  evolution_plan_id: string
  source_scenario_cycle_id: string | null

  sequence_number: number

  title: string
  description: string | null

  period_start: string
  period_end: string

  strategic_intent: string | null
  expected_outcome: string | null

  target_maturity: JsonValue
  assumptions: JsonValue
  entry_criteria: JsonValue
  exit_criteria: JsonValue
  strategic_focus: JsonValue

  metadata: JsonValue

  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
}

export type StrategicObjectiveEvolutionRow = {
  id: string
  organization_id: string
  project_id: string
  formulation_id: string | null

  code: string
  name: string
  description: string | null

  management_model: string

  perspective_code: string | null
  strategic_theme: string | null

  expected_result: string | null
  rationale: string | null

  priority: string
  status: string
  validation_status: string

  progress: number
}

export type ObjectiveEvolutionScenarioAlignmentRow = {
  id: string

  organization_id: string
  project_id: string

  formulation_id: string
  strategic_objective_id: string

  strategic_horizon_id: string

  scenario_id: string
  scenario_cycle_id: string

  alignment_role: EvolutionAlignmentRole
  contribution_weight: number | null

  expected_result_in_cycle: string | null
  rationale: string | null

  validation_status: EvolutionAlignmentValidationStatus

  metadata: JsonValue

  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
}

export type ObjectiveEvolutionCycleAlignmentRow = {
  id: string

  organization_id: string
  project_id: string

  formulation_id: string
  strategic_objective_id: string

  strategic_horizon_id: string

  evolution_plan_id: string
  evolution_cycle_id: string

  source_scenario_alignment_id: string | null
  materialization_gate_decision_id: string | null

  alignment_role: EvolutionAlignmentRole
  contribution_weight: number | null

  expected_result_in_cycle: string | null
  rationale: string | null

  metadata: JsonValue

  created_at: string
  created_by: string | null
  updated_at: string
  updated_by: string | null
}

export type ObjectiveEvolutionReadinessIssue = {
  code?: string
  severity?: string
  message?: string
  [key: string]: unknown
}

export type ObjectiveEvolutionMissingObjective = {
  id: string
  code: string
  name: string
}

export type ObjectiveEvolutionAlignmentReadiness = {
  projectId: string
  approvedFormulationId: string | null
  evolutionPlanId: string | null
  sourceScenarioId: string | null

  objectiveCount: number
  alignedObjectiveCount: number
  alignmentCount: number
  materializableAlignmentCount: number

  missingObjectives: ObjectiveEvolutionMissingObjective[]

  readyForClosure: boolean
  blockingIssueCount: number

  issues: ObjectiveEvolutionReadinessIssue[]

  [key: string]: unknown
}

export type EvolutionScenarioReadiness = {
  scenario_id: string
  strategic_horizon_id: string
  coverage_policy: string

  cycle_count: number

  horizon_start: string
  horizon_end: string

  first_cycle_start: string | null
  last_cycle_end: string | null

  gap_count: number
  has_gaps: boolean
  is_continuous: boolean
  covers_horizon: boolean

  ready_to_submit: boolean

  [key: string]: unknown
}

export type EvolutionScenarioAlignmentInput = {
  formulationId: string
  strategicObjectiveId: string
  scenarioCycleId: string

  alignmentId: string | null

  alignmentRole: EvolutionAlignmentRole
  contributionWeight: number | null

  expectedResultInCycle: string
  rationale: string

  changeReason: string
}