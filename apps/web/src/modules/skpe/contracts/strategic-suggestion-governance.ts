export const phase2SuggestionGovernanceNotice =
  'Análise assistida: a aplicação propõe manter, ajustar, substituir, incluir ou remover elementos com evidências, fontes, motivação e justificativa. A decisão final é sempre humana.'

export type StrategicSuggestionAction =
  | 'keep'
  | 'adjust'
  | 'replace'
  | 'add'
  | 'remove'

export type StrategicSuggestionSourceKind =
  | 'organizational_evidence'
  | 'sk_km'
  | 'external_reference'
  | 'benchmark'

export type StrategicSuggestionReliability =
  | 'canonical'
  | 'official'
  | 'peer_reviewed'
  | 'recognized_institution'
  | 'qualified_market_source'

export type StrategicSuggestionSource = {
  kind: StrategicSuggestionSourceKind
  reference: string
  title: string
  reliability: StrategicSuggestionReliability
  comparabilityAssessment?: string | null
  applicabilityAssessment?: string | null
}
export type StrategicSuggestionHumanDecision = {
  decision: 'approved' | 'adjusted' | 'rejected'
  decidedBy: string
  decidedAt: string
  reason: string
  adjustedValue?: string | null
}

export type GovernedStrategicSuggestion = {
  suggestionId: string
  phaseCode: 'PEM-02'
  stageCode: string
  elementType: string
  action: StrategicSuggestionAction
  currentValue?: string | null
  proposedValue?: string | null
  evidenceReferences: string[]
  sources: StrategicSuggestionSource[]
  motivation: string
  justification: string
  maturityFit: string
  visionAlignment: string
  valueContribution: string
  risksOrReservations?: string | null
  confidence: 'low' | 'medium' | 'high'
  status: 'draft' | 'pending_human_validation' | 'approved' | 'adjusted' | 'rejected'
  humanDecision?: StrategicSuggestionHumanDecision | null
}
export type StrategicSuggestionValidation = {
  ok: boolean
  errors: string[]
}

function hasText(value: string | null | undefined) {
  return Boolean(value?.trim())
}

export function validateGovernedStrategicSuggestion(
  suggestion: GovernedStrategicSuggestion,
): StrategicSuggestionValidation {
  const errors: string[] = []

  if (suggestion.phaseCode !== 'PEM-02') errors.push('phase_code_invalid')
  if (!hasText(suggestion.stageCode)) errors.push('stage_code_required')
  if (!hasText(suggestion.elementType)) errors.push('element_type_required')
  if (suggestion.evidenceReferences.length === 0) errors.push('evidence_required')
  if (suggestion.sources.length === 0) errors.push('source_required')
  if (!hasText(suggestion.motivation)) errors.push('motivation_required')
  if (!hasText(suggestion.justification)) errors.push('justification_required')
  if (!hasText(suggestion.maturityFit)) errors.push('maturity_fit_required')
  if (!hasText(suggestion.visionAlignment)) errors.push('vision_alignment_required')
  if (!hasText(suggestion.valueContribution)) errors.push('value_contribution_required')

  if (suggestion.action === 'keep' && !hasText(suggestion.currentValue)) {
    errors.push('keep_requires_current_value')
  }
  if (
    ['adjust', 'replace', 'add'].includes(suggestion.action) &&
    !hasText(suggestion.proposedValue)
  ) {
    errors.push('proposed_value_required')
  }

  for (const source of suggestion.sources) {
    if (!hasText(source.reference) || !hasText(source.title)) {
      errors.push('source_identification_required')
    }
    if (source.kind === 'benchmark') {
      if (!hasText(source.comparabilityAssessment)) {
        errors.push('benchmark_comparability_required')
      }
      if (!hasText(source.applicabilityAssessment)) {
        errors.push('benchmark_applicability_required')
      }
    }
  }

  if (['approved', 'adjusted', 'rejected'].includes(suggestion.status)) {
    const decision = suggestion.humanDecision
    if (!decision) errors.push('human_decision_required')
    else {
      if (!hasText(decision.decidedBy)) errors.push('human_decider_required')
      if (!hasText(decision.decidedAt)) errors.push('human_decision_date_required')
      if (!hasText(decision.reason)) errors.push('human_decision_reason_required')
    }
  }

  return { ok: errors.length === 0, errors }
}
