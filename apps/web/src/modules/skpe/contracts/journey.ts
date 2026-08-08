export type JourneyStatus =
  | 'not_started'
  | 'in_progress'
  | 'blocked'
  | 'pending_validation'
  | 'completed'
  | 'cancelled'

export type JourneyRow = {
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
