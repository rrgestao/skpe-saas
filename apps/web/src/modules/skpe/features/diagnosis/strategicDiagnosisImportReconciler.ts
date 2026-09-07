export type ImportedDiagnosisRecord = {
  id: string
  sourceSheet: string
  sourceRow: number | null
  externalKey: string
  simulationStatus: string | null
  targetRecordId: string | null
  values: Record<string, unknown>
  createdAt: string
}

export type DiagnosisImportRecordRow = {
  id: string
  source_sheet: string
  source_row: number | null
  external_key: string
  simulation_status: string | null
  target_record_id: string | null
  values_json: Record<string, unknown> | null
  created_at: string
}

function candidateScore(row: DiagnosisImportRecordRow): number {
  let score = Date.parse(row.created_at) || 0

  if (row.target_record_id) score += 10 ** 15
  if (row.simulation_status === 'update') score += 10 ** 14
  if (row.simulation_status === 'unchanged') score += 10 ** 13

  return score
}

export function reconcileImportedDiagnosisRecords(
  rows: DiagnosisImportRecordRow[],
): ImportedDiagnosisRecord[] {
  const selected = new Map<string, DiagnosisImportRecordRow>()

  for (const row of rows) {
    const current = selected.get(row.external_key)

    if (!current || candidateScore(row) > candidateScore(current)) {
      selected.set(row.external_key, row)
    }
  }

  return [...selected.values()]
    .sort((first, second) => {
      const rowDifference = (first.source_row ?? 0) - (second.source_row ?? 0)

      if (rowDifference !== 0) return rowDifference

      return first.external_key.localeCompare(second.external_key, 'pt-BR')
    })
    .map((row) => ({
      id: row.id,
      sourceSheet: row.source_sheet,
      sourceRow: row.source_row,
      externalKey: row.external_key,
      simulationStatus: row.simulation_status,
      targetRecordId: row.target_record_id,
      values: row.values_json ?? {},
      createdAt: row.created_at,
    }))
}