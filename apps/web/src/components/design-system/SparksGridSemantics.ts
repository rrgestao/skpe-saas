/**
 * SPARKs Grid semantic alignment standard.
 *
 * Canonical rule:
 * fields that represent state/classification/responsibility/time/progress
 * must be centered in every governed Grid.
 *
 * New grids should use these helpers instead of creating local alignment rules.
 */
const CENTERED_GRID_ATTRIBUTE_IDS = new Set([
  'status',
  'situation',
  'initiativeStatus',
  'initiativeClass',
  'class',
  'responsibleArea',
  'responsibleAreaName',
  'priority',
  'responsible',
  'responsibleName',
  'owner',
  'startDate',
  'start_date',
  'dueDate',
  'targetEndDate',
  'target_end_date',
  'progress',
])

export function isCenteredGridAttribute(attributeId: string) {
  return CENTERED_GRID_ATTRIBUTE_IDS.has(attributeId)
}

export function gridSemanticCellClass(attributeId: string) {
  return isCenteredGridAttribute(attributeId)
    ? 'sparks-grid-cell--semantic-center'
    : ''
}

export function gridSemanticHeaderClass(attributeId: string) {
  return isCenteredGridAttribute(attributeId)
    ? 'sparks-grid-header--semantic-center'
    : ''
}
