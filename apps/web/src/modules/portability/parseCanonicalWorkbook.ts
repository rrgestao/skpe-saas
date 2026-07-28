import * as XLSX from 'xlsx'

export type ReconciliationConflict = {
  id: string
  severity: 'critical' | 'high' | 'medium' | 'low'
  topic: string
  sourceA: string
  valueA: string
  sourceB: string
  valueB: string
  canonicalValue: string
  rule: string
  decision: 'accept_canonical' | 'keep_source_a' | 'keep_source_b' | 'manual_review'
}

export type QualityIssue = {
  id: string
  severity: 'critical' | 'high' | 'medium' | 'low'
  code: 'DUPLICATE_EXTERNAL_KEY' | 'SHIFTED_COLUMNS' | 'EMPTY_IDENTITY' | 'HEADER_MISMATCH'
  entityCode: string
  sourceSheet: string
  sourceRow: number
  externalKey?: string
  message: string
  action: 'auto_corrected' | 'quarantined' | 'warning'
}

export type SheetInventory = {
  sheet: string
  entity: string | null
  entityCode: string | null
  headerRow: number
  records: number
  headers: string[]
}

export type CanonicalSourceRecord = {
  sourceSheet: string
  sourceRow: number
  entityCode: string
  externalKey: string
  fingerprint: string
  values: Record<string, string>
  qualityStatus: 'valid' | 'corrected'
}

export type QuarantinedRecord = {
  sourceSheet: string
  sourceRow: number
  entityCode: string
  proposedExternalKey: string
  values: Record<string, string>
  reasons: string[]
}

export type CanonicalEntityPayload = {
  entityCode: string
  entityName: string
  sourceSheet: string
  headerRow: number
  records: CanonicalSourceRecord[]
}

export type CanonicalImportPreview = {
  schema: 'SPARKS_PE_CANONICAL_IMPORT_PREVIEW'
  schemaVersion: '2.0.1'
  sourceFile: string
  sourceFileFingerprint: string
  organization: string
  horizon: string
  sheetCount: number
  mappedSheetCount: number
  totalPayloadRecords: number
  validPayloadRecords: number
  quarantinedRecords: number
  journey: Record<string, string>
  sheets: SheetInventory[]
  entities: CanonicalEntityPayload[]
  quarantine: QuarantinedRecord[]
  quality: {
    canDownload: boolean
    criticalIssues: number
    highIssues: number
    autoCorrectedIssues: number
    quarantinedIssues: number
    issues: QualityIssue[]
  }
  conflicts: ReconciliationConflict[]
  generatedAt: string
  databaseWrites: false
}

const ENTITY_BY_SHEET: Record<string, { code: string; name: string }> = {
  '01_Projeto': { code: 'project', name: 'Projeto' },
  '02_Fases': { code: 'journey', name: 'Jornada e fases' },
  '03_Evidencias': { code: 'evidence', name: 'Evidências' },
  '04_PESTEL': { code: 'pestel', name: 'PESTEL' },
  '05_SWOT': { code: 'swot', name: 'SWOT' },
  '06_TOWS': { code: 'tows', name: 'TOWS' },
  '07_Riscos': { code: 'risk', name: 'Riscos' },
  '08_Identidade': { code: 'strategic_identity', name: 'Identidade estratégica' },
  '09_Objetivos_Estrategicos': { code: 'strategic_objective', name: 'Objetivos estratégicos' },
  '10_Mapa_Estrategico': { code: 'strategy_map', name: 'Mapa estratégico' },
  '11_OKRs': { code: 'okr', name: 'OKRs' },
  '12_KRs': { code: 'key_result', name: 'Resultados-chave' },
  '13_Indicadores': { code: 'indicator', name: 'Indicadores' },
  '14_Metas': { code: 'target', name: 'Metas' },
  '15_Iniciativas': { code: 'initiative', name: 'Iniciativas' },
  '16_5W2H': { code: 'action_5w2h', name: 'Planos 5W2H' },
  '17_Acompanhamento': { code: 'monitoring', name: 'Acompanhamento' },
  '18_Decisoes': { code: 'decision', name: 'Decisões' },
  '19_Aprendizados': { code: 'learning', name: 'Aprendizados' },
  '25_Validacao_Cliente': { code: 'client_validation', name: 'Validações do cliente' },
  '26_Artefatos': { code: 'methodology_artifact', name: 'Artefatos metodológicos' },
  '27_Pendencias': { code: 'pending_item', name: 'Pendências' },
  '28_Handoff': { code: 'handoff', name: 'Handoffs' },
  '29_Controle_Versoes': { code: 'version_control', name: 'Controle de versões' },
  '30_Governanca_Viva': { code: 'living_governance', name: 'Governança viva' },
  '31_Gate_Deliberativo': { code: 'deliberative_gate', name: 'Gates deliberativos' },
  '32_Gestao_Evidencias': { code: 'evidence_management', name: 'Gestão de evidências' },
  '33_Maturidade_Processos': { code: 'process_maturity', name: 'Maturidade de processos' },
  '34_PMVV_Validacao': { code: 'pmvv_validation', name: 'Validação PMVV' },
  '35_Valores_Vivos': { code: 'living_value', name: 'Valores vivos' },
  '36_PMVV_5W2H': { code: 'pmvv_institutionalization', name: 'Institucionalização do PMVV' },
  '37_Portfolio_Projetos': { code: 'project_portfolio', name: 'Portfólio de projetos' },
  '38_Resultados_KPI': { code: 'kpi_result', name: 'Resultados KPI' },
  '39_Desvios_Acoes': { code: 'deviation_action', name: 'Desvios e ações' },
  '40_Reunioes_Estrategicas': { code: 'strategic_meeting', name: 'Reuniões estratégicas' },
  '41_Revisao_Estrategica': { code: 'strategic_review', name: 'Revisão estratégica' },
  '42_Rastreabilidade': { code: 'traceability', name: 'Rastreabilidade' },
  '44_Checklist_Evidencias_PE': { code: 'evidence_checklist', name: 'Checklist de evidências' },
  '46_Fichas_Indicadores': { code: 'indicator_sheet', name: 'Fichas de indicadores' },
  '47_Associacao_Estrategica': { code: 'strategic_association', name: 'Associações estratégicas' },
  '48_Benchmarks_Referencias': { code: 'benchmark_reference', name: 'Benchmarks e referências' },
}

type Matrix = string[][]

function normalize(value: unknown): string {
  if (value == null) return ''
  if (value instanceof Date) return value.toISOString()
  return String(value).replace(/\u00a0/g, ' ').replace(/\s+/g, ' ').trim()
}

function slug(value: string): string {
  return normalize(value)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLocaleLowerCase('pt-BR')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
}

function hashText(value: string): string {
  let hash = 2166136261
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index)
    hash = Math.imul(hash, 16777619)
  }
  return (hash >>> 0).toString(16).padStart(8, '0')
}

function sheetMatrix(sheet: XLSX.WorkSheet | undefined): Matrix {
  if (!sheet) return []
  return XLSX.utils.sheet_to_json<unknown[]>(sheet, {
    header: 1,
    raw: false,
    defval: '',
    blankrows: false,
    dateNF: 'dd/mm/yyyy',
  }).map((row) => row.map(normalize))
}

function findValue(rows: Matrix, label: string): string {
  const target = label.toLocaleLowerCase('pt-BR').trim()
  for (const row of rows) {
    const limit = Math.min(row.length, 8)
    for (let column = 0; column < limit; column += 1) {
      if (normalize(row[column]).toLocaleLowerCase('pt-BR') === target) return normalize(row[column + 1])
    }
  }
  return ''
}

function findHeaderRow(rows: Matrix): number {
  let bestIndex = 0
  let bestScore = -1
  const limit = Math.min(rows.length, 12)
  for (let index = 0; index < limit; index += 1) {
    const score = rows[index].filter((value) => normalize(value) !== '').length
    if (score > bestScore) { bestIndex = index; bestScore = score }
  }
  return bestIndex + 1
}

function uniqueHeaders(rawHeaders: string[]): string[] {
  const occurrences = new Map<string, number>()
  return rawHeaders.map((header, index) => {
    const base = slug(header) || `coluna_${index + 1}`
    const count = (occurrences.get(base) ?? 0) + 1
    occurrences.set(base, count)
    return count === 1 ? base : `${base}_${count}`
  })
}

const IDENTITY_FIELDS_BY_ENTITY: Record<string, string[]> = {
  strategic_identity: ['elemento', 'versao_proposta', 'definicao_texto'],
  client_validation: ['codigo', 'artefato_tema', 'data'],
  living_value: ['valor'],
  okr: ['ano', 'oe_relacionado', 'objetivo_anual'],
  strategy_map: ['perspectiva', 'objetivo'],
  project: ['campo'],
}

function baseExternalKey(values: Record<string, string>, entityCode: string, rowNumber: number): string {
  const configured = IDENTITY_FIELDS_BY_ENTITY[entityCode]
  if (configured) {
    const parts = configured.map((field) => slug(values[field] ?? '')).filter(Boolean)
    if (parts.length) return `${entityCode}:${parts.join(':')}`
  }
  const preferred = ['codigo', 'id', 'elemento', 'indicador', 'transicao', 'versao', 'campo', 'valor', 'iniciativa']
  for (const key of preferred) {
    if (values[key]) return `${entityCode}:${slug(values[key])}`
  }
  return `${entityCode}:linha_${rowNumber}`
}

function ensureUniqueExternalKey(baseKey: string, fingerprint: string, usedKeys: Set<string>): { key: string; corrected: boolean } {
  if (!usedKeys.has(baseKey)) {
    usedKeys.add(baseKey)
    return { key: baseKey, corrected: false }
  }
  const candidate = `${baseKey}:${fingerprint}`
  let key = candidate
  let suffix = 2
  while (usedKeys.has(key)) {
    key = `${candidate}:${suffix}`
    suffix += 1
  }
  usedKeys.add(key)
  return { key, corrected: true }
}

function looksLikeDate(value: string): boolean {
  return /^\d{2}\/\d{2}\/\d{4}$/.test(value) || /^\d{4}-\d{2}-\d{2}/.test(value)
}

function shiftedColumnReasons(sheetName: string, values: Record<string, string>): string[] {
  const reasons: string[] = []
  if (sheetName === '26_Artefatos') {
    if (values.codigo === 'PEM-02.SGE-01' && (!looksLikeDate(values.data) || looksLikeDate(values.status))) {
      reasons.push('Campos de data/status e demais colunas aparentam estar deslocados na linha de origem.')
    }
  }
  if (sheetName === '29_Controle_Versoes') {
    if (values.versao === 'v17' && values.data && !looksLikeDate(values.data)) {
      reasons.push('A data da versão v17 não possui formato de data e os campos posteriores aparentam deslocamento.')
    }
  }
  return reasons
}

function extractEntityPayload(
  sheetName: string,
  rows: Matrix,
  headerRow: number,
  usedKeys: Set<string>,
  issues: QualityIssue[],
  quarantine: QuarantinedRecord[],
): CanonicalEntityPayload | null {
  const definition = ENTITY_BY_SHEET[sheetName]
  if (!definition) return null

  const rawHeaders = rows[headerRow - 1] ?? []
  const headers = uniqueHeaders(rawHeaders)
  const records: CanonicalSourceRecord[] = []

  rows.slice(headerRow).forEach((row, offset) => {
    if (!row.some((value) => normalize(value) !== '')) return
    const values: Record<string, string> = {}
    headers.forEach((header, index) => { values[header] = normalize(row[index]) })
    const sourceRow = headerRow + offset + 1
    const fingerprint = hashText(JSON.stringify({ entityCode: definition.code, values }))
    const proposedExternalKey = baseExternalKey(values, definition.code, sourceRow)
    const shiftedReasons = shiftedColumnReasons(sheetName, values)

    if (shiftedReasons.length) {
      quarantine.push({ sourceSheet: sheetName, sourceRow, entityCode: definition.code, proposedExternalKey, values, reasons: shiftedReasons })
      shiftedReasons.forEach((message, index) => issues.push({
        id: `QUAL-${sheetName}-${sourceRow}-${index + 1}`,
        severity: 'high',
        code: 'SHIFTED_COLUMNS',
        entityCode: definition.code,
        sourceSheet: sheetName,
        sourceRow,
        externalKey: proposedExternalKey,
        message,
        action: 'quarantined',
      }))
      return
    }

    const unique = ensureUniqueExternalKey(proposedExternalKey, fingerprint, usedKeys)
    if (unique.corrected) {
      issues.push({
        id: `QUAL-${sheetName}-${sourceRow}-DUP`,
        severity: 'medium',
        code: 'DUPLICATE_EXTERNAL_KEY',
        entityCode: definition.code,
        sourceSheet: sheetName,
        sourceRow,
        externalKey: unique.key,
        message: `Chave duplicada “${proposedExternalKey}” foi corrigida para “${unique.key}”.`,
        action: 'auto_corrected',
      })
    }

    records.push({
      sourceSheet: sheetName,
      sourceRow,
      entityCode: definition.code,
      externalKey: unique.key,
      fingerprint,
      values,
      qualityStatus: unique.corrected ? 'corrected' : 'valid',
    })
  })

  return { entityCode: definition.code, entityName: definition.name, sourceSheet: sheetName, headerRow, records }
}

function readWorkbook(buffer: ArrayBuffer): XLSX.WorkBook {
  return XLSX.read(buffer, {
    type: 'array',
    cellDates: true,
    cellFormula: true,
    cellText: true,
    cellNF: false,
    dense: false,
    bookVBA: false,
    bookFiles: false,
  })
}

export async function parseCanonicalWorkbook(file: File): Promise<CanonicalImportPreview> {
  let workbook: XLSX.WorkBook
  const fileBuffer = await file.arrayBuffer()
  try { workbook = readWorkbook(fileBuffer) }
  catch (reason) {
    const message = reason instanceof Error ? reason.message : String(reason)
    throw new Error(`Não foi possível ler os dados tabulares da planilha: ${message}`)
  }

  const projectRows = sheetMatrix(workbook.Sheets['01_Projeto'])
  const organization = findValue(projectRows, 'Organização')
  if (organization.toLocaleUpperCase('pt-BR') !== 'COOTAQUARA') {
    throw new Error(`A planilha pertence a “${organization || 'organização não identificada'}”. A carga canônica inicial está bloqueada para outra organização.`)
  }

  const sheets: SheetInventory[] = []
  const entities: CanonicalEntityPayload[] = []
  const issues: QualityIssue[] = []
  const quarantine: QuarantinedRecord[] = []
  const usedKeys = new Set<string>()

  workbook.SheetNames.forEach((sheetName) => {
    const rows = sheetMatrix(workbook.Sheets[sheetName])
    const headerRow = findHeaderRow(rows)
    const headers = (rows[headerRow - 1] ?? []).map(normalize).filter(Boolean)
    const payload = extractEntityPayload(sheetName, rows, headerRow, usedKeys, issues, quarantine)
    const definition = ENTITY_BY_SHEET[sheetName]
    sheets.push({
      sheet: sheetName,
      entity: definition?.name ?? null,
      entityCode: definition?.code ?? null,
      headerRow,
      records: payload?.records.length ?? rows.slice(headerRow).filter((row) => row.some((value) => normalize(value) !== '')).length,
      headers,
    })
    if (payload) entities.push(payload)
  })

  const conflicts: ReconciliationConflict[] = [
    { id: 'REC-001', severity: 'critical', topic: 'Status da Macrofase 1', sourceA: '00_Capa / 18_Decisoes', valueA: 'Aprovada e concluída', sourceB: '02_Fases', valueB: 'Em validação; 90%', canonicalValue: 'Concluída; 100%', rule: 'Decisões formais prevalecem sobre quadro-resumo desatualizado.', decision: 'accept_canonical' },
    { id: 'REC-002', severity: 'critical', topic: 'Status da Macrofase 2', sourceA: '00_Capa / 18_Decisoes', valueA: 'Iniciada e em andamento', sourceB: '02_Fases', valueB: 'Não iniciado; 0%', canonicalValue: 'Em andamento', rule: 'DEC-02.01 prevalece.', decision: 'accept_canonical' },
    { id: 'REC-003', severity: 'high', topic: 'Versão da solução', sourceA: 'Nome do arquivo', valueA: file.name.match(/v(\d+)/i)?.[1] ?? 'não identificada', sourceB: '01_Projeto / 26_Artefatos', valueB: findValue(projectRows, 'Versão da solução') || 'não informada', canonicalValue: 'Usar a versão do arquivo para a carga e preservar a versão declarada como histórico.', rule: 'Não apagar histórico de versões.', decision: 'accept_canonical' },
    { id: 'REC-004', severity: 'high', topic: 'Handoff MF1 → MF2', sourceA: '18_Decisoes', valueA: 'MF2 aberta e aprovada', sourceB: '28_Handoff', valueB: 'Aguardando validação', canonicalValue: 'Concluído, vinculado à decisão de abertura.', rule: 'A abertura formal comprova a transição.', decision: 'accept_canonical' },
    { id: 'REC-005', severity: 'critical', topic: 'PMVV', sourceA: '34_PMVV_Validacao / DEC-02.03', valueA: 'Em validação', sourceB: '08_Identidade', valueB: 'Textos propostos', canonicalValue: 'Proposta para validação; não institucionalizada.', rule: 'Sem decisão formal, não importar como aprovado.', decision: 'accept_canonical' },
    { id: 'REC-006', severity: 'critical', topic: 'PEM-02.04', sourceA: '00_Capa / 27_Pendencias', valueA: 'Bloqueado por gate', sourceB: 'Estruturas futuras', valueB: 'Conteúdos já preparados', canonicalValue: 'Bloqueado para execução; importar conteúdos posteriores como proposta.', rule: 'Preparação não equivale a autorização para avanço.', decision: 'accept_canonical' },
  ]

  const validPayloadRecords = entities.reduce((total, entity) => total + entity.records.length, 0)
  const totalPayloadRecords = validPayloadRecords + quarantine.length
  const criticalIssues = issues.filter((item) => item.severity === 'critical').length
  const highIssues = issues.filter((item) => item.severity === 'high').length
  const autoCorrectedIssues = issues.filter((item) => item.action === 'auto_corrected').length
  const quarantinedIssues = issues.filter((item) => item.action === 'quarantined').length

  return {
    schema: 'SPARKS_PE_CANONICAL_IMPORT_PREVIEW',
    schemaVersion: '2.0.1',
    sourceFile: file.name,
    sourceFileFingerprint: hashText(`${file.name}:${file.size}:${file.lastModified}:${new Uint8Array(fileBuffer).byteLength}`),
    organization,
    horizon: findValue(projectRows, 'Horizonte estratégico'),
    sheetCount: workbook.SheetNames.length,
    mappedSheetCount: entities.length,
    totalPayloadRecords,
    validPayloadRecords,
    quarantinedRecords: quarantine.length,
    journey: { MF1: 'Concluída e aprovada', MF2: 'Em andamento', currentStage: 'PEM-02.03 — Em validação', nextStage: 'PEM-02.04 — Bloqueado pelo gate do PMVV' },
    sheets,
    entities,
    quarantine,
    quality: {
      canDownload: criticalIssues === 0,
      criticalIssues,
      highIssues,
      autoCorrectedIssues,
      quarantinedIssues,
      issues,
    },
    conflicts,
    generatedAt: new Date().toISOString(),
    databaseWrites: false,
  }
}
