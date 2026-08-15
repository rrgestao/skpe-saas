import ExcelJS from 'exceljs'
import JSZip from 'jszip'

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
  '35_Valores': { code: 'living_value', name: 'Valores' },
  '35_Valores_Vivos': { code: 'living_value', name: 'Valores' },
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

function formatBrazilianDate(value: Date): string {
  const day = String(value.getUTCDate()).padStart(2, '0')
  const month = String(value.getUTCMonth() + 1).padStart(2, '0')
  return `${day}/${month}/${value.getUTCFullYear()}`
}

function excelValueText(value: ExcelJS.CellValue): string {
  if (value == null) return ''
  if (value instanceof Date) return formatBrazilianDate(value)
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') return normalize(value)
  if (typeof value !== 'object') return normalize(value)

  if ('result' in value) {
    if (value.result != null) return excelValueText(value.result as ExcelJS.CellValue)
    if ('formula' in value && typeof value.formula === 'string') return normalize(`=${value.formula}`)
    if ('sharedFormula' in value && typeof value.sharedFormula === 'string') return normalize(`=${value.sharedFormula}`)
    return ''
  }
  if ('richText' in value && Array.isArray(value.richText)) {
    return normalize(value.richText.map((part) => part.text).join(''))
  }
  if ('text' in value && typeof value.text === 'string') return normalize(value.text)
  if ('error' in value && typeof value.error === 'string') return normalize(value.error)

  return ''
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

function sheetMatrix(sheet: ExcelJS.Worksheet | undefined): Matrix {
  if (!sheet) return []
  const rows: Matrix = []
  sheet.eachRow({ includeEmpty: false }, (row) => {
    const values: string[] = []
    for (let column = 1; column <= row.cellCount; column += 1) {
      const cell = row.getCell(column)
      values.push(cell.isMerged && cell.master.address !== cell.address ? '' : excelValueText(cell.value))
    }
    rows.push(values)
  })
  return rows
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

const SUPPORTED_MIME_TYPES = new Set([
  '',
  'application/octet-stream',
  'application/zip',
  'application/x-zip-compressed',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
])

const REQUIRED_CANONICAL_SHEETS = ['01_Projeto', '02_Fases'] as const

function validateFileMetadata(file: File): void {
  const extension = file.name.toLocaleLowerCase('pt-BR').split('.').pop()
  if (extension !== 'xlsx') {
    throw new Error('Formato não suportado. Selecione uma Planilha Mestre no formato .xlsx.')
  }
  if (file.type && !SUPPORTED_MIME_TYPES.has(file.type)) {
    throw new Error(`Formato não suportado. O arquivo possui extensão .xlsx, mas o navegador informou o tipo “${file.type}”.`)
  }
}

function hasZipSignature(buffer: ArrayBuffer): boolean {
  const signature = new Uint8Array(buffer, 0, Math.min(buffer.byteLength, 4))
  return signature.length >= 4 && signature[0] === 0x50 && signature[1] === 0x4b && (
    (signature[2] === 0x03 && signature[3] === 0x04)
    || (signature[2] === 0x05 && signature[3] === 0x06)
    || (signature[2] === 0x07 && signature[3] === 0x08)
  )
}

async function normalizeOoxmlForTabularRead(buffer: ArrayBuffer): Promise<ArrayBuffer> {
  const zip = await JSZip.loadAsync(buffer)
  const spreadsheetNamespace = 'xmlns:x="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'

  for (const [path, entry] of Object.entries(zip.files)) {
    if (entry.dir) continue

    if (path.startsWith('xl/worksheets/_rels/') && path.endsWith('.rels')) {
      const relationships = (await entry.async('string'))
        .replace(/<Relationship\b(?=[^>]*\bType="[^"]*\/(?:comments|vmlDrawing|drawing|table)")[^>]*\/>/gi, '')
        .replace(/Target="\/xl\//g, 'Target="../')
      zip.file(path, relationships)
      continue
    }

    if (!path.endsWith('.xml')) continue
    const xml = await entry.async('string')
    if (!xml.includes(spreadsheetNamespace)) continue
    zip.file(path, xml.replace(/<(\/?)x:/g, '<$1').replace(/xmlns:x=/g, 'xmlns='))
  }

  return zip.generateAsync({ type: 'arraybuffer' })
}

async function loadWorkbook(buffer: ArrayBuffer): Promise<ExcelJS.Workbook> {
  const workbook = new ExcelJS.Workbook()
  try {
    await workbook.xlsx.load(buffer as unknown as ExcelJS.Buffer, {
      ignoreNodes: ['drawing', 'legacyDrawing', 'tableParts'],
    })
    return workbook
  } catch {
    const normalizedBuffer = await normalizeOoxmlForTabularRead(buffer)
    const normalizedWorkbook = new ExcelJS.Workbook()
    await normalizedWorkbook.xlsx.load(normalizedBuffer as unknown as ExcelJS.Buffer, {
      ignoreNodes: ['drawing', 'legacyDrawing', 'tableParts'],
    })
    return normalizedWorkbook
  }
}

function tableRecords(rows: Matrix): Record<string, string>[] {
  const headerRow = findHeaderRow(rows)
  const headers = uniqueHeaders(rows[headerRow - 1] ?? [])
  return rows.slice(headerRow)
    .filter((row) => row.some((value) => normalize(value) !== ''))
    .map((row) => Object.fromEntries(headers.map((header, index) => [header, normalize(row[index])])))
}

function recordValue(rows: Matrix, key: string, expected: string, field: string): string {
  const record = tableRecords(rows).find((item) => normalize(item[key]).toLocaleUpperCase('pt-BR') === expected.toLocaleUpperCase('pt-BR'))
  return normalize(record?.[field])
}

function canonicalConflicts(workbook: ExcelJS.Workbook, valuesCount: number): ReconciliationConflict[] {
  const decisionRows = sheetMatrix(workbook.getWorksheet('18_Decisoes'))
  const pmvvRows = sheetMatrix(workbook.getWorksheet('34_PMVV_Validacao'))
  const gateRows = sheetMatrix(workbook.getWorksheet('31_Gate_Deliberativo'))
  const pem0204Rows = sheetMatrix(workbook.getWorksheet('51_Validacao_PEM0204'))
  const pmvvDecision = recordValue(decisionRows, 'codigo', 'DEC-02.03', 'decisao') || 'Não informada'
  const pmvvDate = recordValue(decisionRows, 'codigo', 'DEC-02.03', 'data') || 'Data não informada'
  const pmvvStatus = recordValue(pmvvRows, 'elemento', 'Propósito', 'status_pos_reuniao') || 'Não informado'
  const valuesDecision = recordValue(decisionRows, 'codigo', 'DEC-02.04', 'decisao') || 'Não informada'
  const riskDecision = recordValue(gateRows, 'codigo', 'RIS-01', 'situacao') || 'Não informada'
  const riskCondition = recordValue(gateRows, 'codigo', 'RIS-01', 'justificativa_condicao') || 'Sem condição registrada'
  const pem0204Decisions = tableRecords(pem0204Rows).map((item) => item.decisao).filter(Boolean)
  const pem0204State = pem0204Decisions.length ? `${pem0204Decisions.length} decisões registradas` : 'Nenhuma deliberação registrada'

  return [
    {
      id: 'REC-001', severity: 'critical', topic: 'PMVV',
      sourceA: '18_Decisoes / DEC-02.03', valueA: `${pmvvDecision} em ${pmvvDate}`,
      sourceB: '34_PMVV_Validacao', valueB: pmvvStatus,
      canonicalValue: 'PMVV aprovado pela Direção em 30/07/2026; institucionalização em andamento.',
      rule: 'Decisão formal, data, evidência e status pós-reunião devem ser interpretados em conjunto.', decision: 'accept_canonical',
    },
    {
      id: 'REC-002', severity: 'high', topic: 'Valores',
      sourceA: '18_Decisoes / DEC-02.04', valueA: valuesDecision,
      sourceB: '35_Valores ou alias legado', valueB: `${valuesCount} Valores reconhecidos`,
      canonicalValue: 'Sete Valores aprovados; institucionalização e medição permanecem em andamento.',
      rule: 'A aprovação do conteúdo não equivale à conclusão da institucionalização.', decision: 'accept_canonical',
    },
    {
      id: 'REC-003', severity: 'high', topic: 'Riscos estratégicos',
      sourceA: '31_Gate_Deliberativo / RIS-01', valueA: riskDecision,
      sourceB: 'Condição de tratamento', valueB: riskCondition,
      canonicalValue: 'Riscos reconhecidos e aceitos; tratamento previsto para o Ciclo 1.',
      rule: 'Aceite do risco não elimina o tratamento, o acompanhamento nem as evidências.', decision: 'accept_canonical',
    },
    {
      id: 'REC-004', severity: 'critical', topic: 'PEM-02.04',
      sourceA: '51_Validacao_PEM0204', valueA: pem0204State,
      sourceB: '50_Temas_Perspectivas / 09_Objetivos_Estrategicos', valueB: 'Conteúdos preparados para validação',
      canonicalValue: 'PEM-02.04 em pré-validação; Temas, Perspectivas e Objetivos Estratégicos — OKRs permanecem como propostas não deliberadas.',
      rule: 'Conteúdo preparado não equivale a conteúdo deliberado ou aprovado.', decision: 'accept_canonical',
    },
  ]
}

export async function parseCanonicalWorkbook(file: File): Promise<CanonicalImportPreview> {
  validateFileMetadata(file)
  const fileBuffer = await file.arrayBuffer()
  if (!hasZipSignature(fileBuffer)) {
    throw new Error('Arquivo inválido ou corrompido. O conteúdo não possui uma estrutura XLSX/ZIP reconhecível.')
  }

  let workbook: ExcelJS.Workbook
  try { workbook = await loadWorkbook(fileBuffer) }
  catch (reason) {
    const message = reason instanceof Error ? reason.message : String(reason)
    throw new Error(`Falha de leitura da Planilha Mestre. O arquivo parece ser XLSX, mas seus dados tabulares não puderam ser interpretados: ${message}`)
  }

  const missingSheets = REQUIRED_CANONICAL_SHEETS.filter((sheetName) => !workbook.getWorksheet(sheetName))
  if (missingSheets.length) {
    throw new Error(`Ausência de abas canônicas obrigatórias: ${missingSheets.join(', ')}.`)
  }

  const projectRows = sheetMatrix(workbook.getWorksheet('01_Projeto'))
  const organization = findValue(projectRows, 'Organização')
  if (organization.toLocaleUpperCase('pt-BR') !== 'COOTAQUARA') {
    throw new Error(`A planilha pertence a “${organization || 'organização não identificada'}”. A carga canônica inicial está bloqueada para outra organização.`)
  }

  const sheets: SheetInventory[] = []
  const entities: CanonicalEntityPayload[] = []
  const issues: QualityIssue[] = []
  const quarantine: QuarantinedRecord[] = []
  const usedKeys = new Set<string>()

  workbook.worksheets.forEach((worksheet) => {
    const sheetName = worksheet.name
    const rows = sheetMatrix(worksheet)
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

  const valuesCount = entities.find((entity) => entity.entityCode === 'living_value')?.records.length ?? 0
  const conflicts = canonicalConflicts(workbook, valuesCount)
  const phaseRows = sheetMatrix(workbook.getWorksheet('02_Fases'))
  const mf1Status = recordValue(phaseRows, 'codigo', 'MF1', 'status') || 'Não informado'
  const mf2Status = recordValue(phaseRows, 'codigo', 'MF2', 'status') || 'Não informado'

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
    sheetCount: workbook.worksheets.length,
    mappedSheetCount: entities.length,
    totalPayloadRecords,
    validPayloadRecords,
    quarantinedRecords: quarantine.length,
    journey: {
      MF1: mf1Status,
      MF2: mf2Status,
      currentStage: 'PEM-02.04 — Pré-validação',
      nextStage: 'Deliberação de Temas, Perspectivas e Objetivos Estratégicos — OKRs',
    },
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
