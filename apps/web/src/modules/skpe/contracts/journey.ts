export type JourneyStatus =
  | 'not_started'
  | 'in_progress'
  | 'blocked'
  | 'pending_validation'
  | 'completed'
  | 'cancelled'

export type JourneyItemType =
  | 'macrophase'
  | 'phase'
  | 'stage'
  | 'meta_stage'
  | 'activity'
  | 'deliverable'
  | 'gate'

export type JourneyRow = {
  project_id: string
  project_code: string
  project_name: string
  project_status: string
  project_progress: number
  item_id: string
  parent_item_id: string | null
  item_type: JourneyItemType
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

export type JourneyTemporalState =
  | 'cancelled'
  | 'unscheduled'
  | 'completed_without_actual_end'
  | 'completed_on_time'
  | 'completed_late'
  | 'blocked'
  | 'completion_overdue'
  | 'start_overdue'
  | 'on_schedule'

export type JourneyTemporalReadRow = Omit<
  JourneyRow,
  'planned_start_date' | 'planned_end_date'
> & {
  organization_id: string
  organization_timezone: string
  reference_date: string
  project_start_date: string | null
  project_target_end_date: string | null
  project_actual_end_date: string | null
  is_mandatory: boolean

  baseline_version_id: string | null
  baseline_version_number: number | null
  baseline_governance_status: string | null
  baseline_start_date: string | null
  baseline_end_date: string | null
  baseline_source_mode: string | null

  current_plan_version_id: string | null
  current_plan_version_number: number | null
  current_plan_kind: 'baseline' | 'rebaseline' | null
  current_plan_approved_at: string | null
  current_plan_start_date: string | null
  current_plan_end_date: string | null
  current_plan_source_mode: string | null

  current_forecast_version_id: string | null
  current_forecast_version_number: number | null
  current_forecast_activated_at: string | null
  forecast_start_date: string | null
  forecast_end_date: string | null
  forecast_source_mode: string | null

  operational_expected_start_date: string | null
  operational_expected_end_date: string | null
  materialized_plan_start_date: string | null
  materialized_plan_end_date: string | null
  actual_start_date: string | null
  actual_end_date: string | null

  has_approved_plan: boolean
  has_active_forecast: boolean
  plan_projection_consistent: boolean

  current_plan_end_variance_vs_baseline_days: number | null
  forecast_end_variance_vs_current_plan_days: number | null
  actual_start_variance_vs_current_plan_days: number | null
  actual_end_variance_vs_current_plan_days: number | null

  is_start_overdue: boolean
  is_completion_overdue: boolean
  days_start_overdue: number
  days_completion_overdue: number
  temporal_state: JourneyTemporalState
}

export type JourneyTemporalRow = JourneyTemporalReadRow & {
  // Aliases de compatibilidade para consumidores legados do JourneyRow.
  // A fonte continua sendo o plano institucional vigente calculado no backend.
  planned_start_date: string | null
  planned_end_date: string | null
}
