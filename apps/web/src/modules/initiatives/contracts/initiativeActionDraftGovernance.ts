export type InitiativeActionDraftFlags = {
  saving: boolean
  editingCapacityAllocation: boolean
  capacityAllocationCreationDraftDirty: boolean
  responsibilityAssignmentDraftDirty: boolean
  progressDraftDirty: boolean
  economicsDraftDirty: boolean
}

export type InitiativeActionDraftLocks = {
  capacityAllocationCreationLocked: boolean
  responsibilityAssignmentLocked: boolean
  progressUpdateLocked: boolean
  economicsUpdateLocked: boolean
  otherMutationLocked: boolean
  closeLocked: boolean
}

export function getInitiativeActionDraftLocks(
  flags: InitiativeActionDraftFlags,
): InitiativeActionDraftLocks {
  const baseLocked =
    flags.saving ||
    flags.editingCapacityAllocation

  const capacityAllocationCreationLocked =
    baseLocked ||
    flags.responsibilityAssignmentDraftDirty ||
    flags.progressDraftDirty ||
    flags.economicsDraftDirty

  const responsibilityAssignmentLocked =
    baseLocked ||
    flags.capacityAllocationCreationDraftDirty ||
    flags.progressDraftDirty ||
    flags.economicsDraftDirty

  const progressUpdateLocked =
    baseLocked ||
    flags.capacityAllocationCreationDraftDirty ||
    flags.responsibilityAssignmentDraftDirty ||
    flags.economicsDraftDirty

  const economicsUpdateLocked =
    baseLocked ||
    flags.capacityAllocationCreationDraftDirty ||
    flags.responsibilityAssignmentDraftDirty ||
    flags.progressDraftDirty

  const otherMutationLocked =
    baseLocked ||
    flags.capacityAllocationCreationDraftDirty ||
    flags.responsibilityAssignmentDraftDirty ||
    flags.progressDraftDirty ||
    flags.economicsDraftDirty

  return {
    capacityAllocationCreationLocked,
    responsibilityAssignmentLocked,
    progressUpdateLocked,
    economicsUpdateLocked,
    otherMutationLocked,
    closeLocked: otherMutationLocked,
  }
}

export type InitiativeActionCreateDraftValues = {
  code: string
  name: string
  description: string
  actionType: 'action' | 'milestone'
  priority: 'low' | 'medium' | 'high' | 'critical'
  changeReason: string
}

export function isInitiativeActionCreateDraftDirty(
  values: InitiativeActionCreateDraftValues,
) {
  return (
    values.code.trim().length > 0 ||
    values.name.trim().length > 0 ||
    values.description.trim().length > 0 ||
    values.actionType !== 'action' ||
    values.priority !== 'medium' ||
    values.changeReason.trim().length > 0
  )
}

export function isInitiativeActionLifecycleDraftDirty(
  isDropConfirmation: boolean,
  targetStatus: string,
  defaultStatus: string,
  changeReason: string,
) {
  return (
    changeReason.trim().length > 0 ||
    (!isDropConfirmation &&
      targetStatus !== defaultStatus)
  )
}