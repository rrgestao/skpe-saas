export function normalizeJourneyStatusChangeReason(
  value: string,
) {
  return value.trim()
}

export function isJourneyStatusChangeDraftDirty(
  value: string,
) {
  return normalizeJourneyStatusChangeReason(value).length > 0
}

export function validateJourneyStatusChangeReason(
  value: string,
) {
  const reason =
    normalizeJourneyStatusChangeReason(value)

  if (reason.length < 10) {
    return {
      valid: false as const,
      reason,
      error:
        'Informe uma justificativa com pelo menos 10 caracteres.',
    }
  }

  return {
    valid: true as const,
    reason,
    error: null,
  }
}