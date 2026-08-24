export type InitiativeParentCandidate = {
  initiative_id: string
  parent_initiative_id: string | null
  initiative_code: string
  initiative_name: string
  initiative_class: string
  initiative_status: string
  source_module_code: string | null
}