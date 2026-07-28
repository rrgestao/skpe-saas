import ExcelJS from 'exceljs'

type JsonObject = Record<string, unknown>

type ExportDocument = {
  manifesto?: JsonObject
  dados?: JsonObject
}

const SHEET_MAP: Record<string, { name: string; preferred: string[] }> = {
  skpe_journey_items: { name: 'Fases', preferred: ['code', 'metaphase', 'macrophase', 'phase', 'stage', 'gate', 'status', 'progress', 'responsible_user_id', 'due_date'] },
  skpe_evidence_sources: { name: 'Evidências', preferred: ['code', 'title', 'evidence_type', 'phase_code', 'source', 'responsible_user_id', 'status', 'evidence_date', 'file_url'] },
  skpe_assessment_findings: { name: 'Riscos e Lacunas', preferred: ['code', 'category', 'description', 'probability', 'impact', 'risk_level', 'response', 'responsible_user_id', 'due_date'] },
  skpe_strategic_objectives: { name: 'Objetivos', preferred: ['code', 'perspective', 'title', 'description', 'strategic_theme', 'responsible_user_id', 'status'] },
  skpe_key_results: { name: 'KRs', preferred: ['code', 'objective_id', 'title', 'unit', 'baseline', 'target', 'actual', 'progress', 'responsible_user_id'] },
  skpe_initiatives: { name: 'Iniciativas', preferred: ['code', 'title', 'objective_id', 'responsible_user_id', 'start_date', 'end_date', 'budget', 'status', 'progress'] },
  skpe_action_plans: { name: '5W2H', preferred: ['initiative_id', 'what', 'why', 'where', 'when', 'who', 'how', 'how_much', 'status'] },
  skpe_action_followups: { name: 'Acompanhamento', preferred: ['followup_date', 'object_type', 'object_id', 'previous_status', 'current_status', 'progress', 'comment', 'responsible_user_id'] },
  skpe_business_artifacts: { name: 'Artefatos', preferred: ['code', 'artifact_type', 'title', 'phase_code', 'version', 'responsible_user_id', 'approver_user_id', 'status', 'issued_at', 'file_url'] },
  skpe_evidence_checklists: { name: 'Validações', preferred: ['code', 'object_type', 'checklist_type', 'validated_at', 'validator_user_id', 'result', 'remarks', 'next_action'] },
}

const COLORS = {
  green: '0F5A47', dark: '183029', mid: '2E7D66', light: 'EAF3F0', teal: 'DDEFEA', gray: '66736F', white: 'FFFFFF', imported: '008000',
}

function asObject(value: unknown): JsonObject {
  return value && typeof value === 'object' && !Array.isArray(value) ? value as JsonObject : {}
}

function asRows(value: unknown): JsonObject[] {
  return Array.isArray(value) ? value.filter((item) => item && typeof item === 'object').map((item) => item as JsonObject) : []
}

function label(key: string) {
  return key.replaceAll('_', ' ').replace(/\b\w/g, (char) => char.toUpperCase())
}

function normalize(value: unknown): string | number | boolean | Date | null {
  if (value === null || value === undefined) return null
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') return value
  return JSON.stringify(value)
}

function styleSheet(sheet: ExcelJS.Worksheet, title: string, headers: string[]) {
  sheet.views = [{ showGridLines: false, state: 'frozen', ySplit: 5 }]
  sheet.mergeCells(1, 1, 1, Math.max(3, headers.length))
  const titleCell = sheet.getCell(1, 1)
  titleCell.value = `SPARKs PE | ${title}`
  titleCell.font = { color: { argb: COLORS.white }, bold: true, size: 16 }
  titleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.green } }
  titleCell.alignment = { vertical: 'middle' }
  sheet.getRow(1).height = 28
  const back = sheet.getCell(2, 1)
  back.value = { text: '← Voltar à Capa', hyperlink: "#'Capa'!A1" }
  back.font = { color: { argb: COLORS.mid }, bold: true, underline: true }
  sheet.mergeCells(3, 1, 3, Math.max(3, headers.length))
  sheet.getCell(3, 1).value = 'Dados verdes: importados da Plataforma SPARKs | pretos: fórmulas | azuis: entradas manuais'
  sheet.getCell(3, 1).font = { color: { argb: COLORS.gray }, italic: true, size: 9 }
  const headerRow = sheet.getRow(5)
  headers.forEach((header, index) => {
    const cell = headerRow.getCell(index + 1)
    cell.value = header
    cell.font = { color: { argb: COLORS.dark }, bold: true }
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.light } }
    cell.alignment = { wrapText: true, vertical: 'middle' }
    cell.border = { bottom: { style: 'medium', color: { argb: COLORS.mid } } }
    sheet.getColumn(index + 1).width = Math.max(14, Math.min(34, header.length + 8))
  })
  headerRow.height = 30
  sheet.autoFilter = { from: { row: 5, column: 1 }, to: { row: 5, column: headers.length } }
  sheet.pageSetup = { fitToPage: true, fitToWidth: 1, fitToHeight: 0, orientation: headers.length > 7 ? 'landscape' : 'portrait' }
  sheet.headerFooter.oddFooter = 'Plataforma SPARKs | Gestão Estratégica Portátil                                      Página &P de &N'
}

function addRowsSheet(workbook: ExcelJS.Workbook, name: string, rows: JsonObject[], preferred: string[] = []) {
  const keys = Array.from(new Set([...preferred, ...rows.flatMap((row) => Object.keys(row))]))
  const headers = keys.length ? keys.map(label) : ['Sem registros']
  const sheet = workbook.addWorksheet(name)
  styleSheet(sheet, name, headers)
  if (!rows.length) {
    sheet.getCell(6, 1).value = 'Nenhum registro exportado.'
    sheet.getCell(6, 1).font = { color: { argb: COLORS.gray }, italic: true }
    return
  }
  rows.forEach((row, rowIndex) => {
    const excelRow = sheet.getRow(6 + rowIndex)
    keys.forEach((key, colIndex) => {
      const cell = excelRow.getCell(colIndex + 1)
      cell.value = normalize(row[key])
      cell.font = { color: { argb: COLORS.imported } }
      cell.alignment = { vertical: 'top', wrapText: true }
    })
  })
}

function addKeyValueSheet(workbook: ExcelJS.Workbook, name: string, data: JsonObject) {
  const sheet = workbook.addWorksheet(name)
  styleSheet(sheet, name, ['Campo', 'Valor'])
  Object.entries(data).forEach(([key, value], index) => {
    sheet.getCell(6 + index, 1).value = label(key)
    sheet.getCell(6 + index, 1).font = { color: { argb: COLORS.gray } }
    sheet.getCell(6 + index, 2).value = normalize(value)
    sheet.getCell(6 + index, 2).font = { color: { argb: COLORS.imported } }
    sheet.getCell(6 + index, 2).alignment = { wrapText: true, vertical: 'top' }
  })
  sheet.getColumn(1).width = 30
  sheet.getColumn(2).width = 70
}

export async function createCanonicalWorkbook(documentData: ExportDocument): Promise<{ blob: Blob; fileName: string }> {
  const manifesto = asObject(documentData.manifesto)
  const dados = asObject(documentData.dados)
  const organization = asObject(dados.organizacao)
  const project = asObject(dados.projeto)

  const workbook = new ExcelJS.Workbook()
  workbook.creator = 'Plataforma SPARKs'
  workbook.title = 'SPARKs PE - Gestão Estratégica Portátil'
  workbook.subject = 'Planilha Canônica de Gestão Estratégica'
  workbook.company = String(organization.trade_name ?? organization.name ?? '')
  workbook.created = new Date()
  workbook.calcProperties.fullCalcOnLoad = true

  const cover = workbook.addWorksheet('Capa')
  cover.views = [{ showGridLines: false }]
  cover.mergeCells('A1:H2')
  cover.getCell('A1').value = 'SPARKs PE'
  cover.getCell('A1').font = { color: { argb: COLORS.white }, bold: true, size: 28 }
  cover.getCell('A1').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.green } }
  cover.getCell('A1').alignment = { vertical: 'middle' }
  cover.mergeCells('A3:H3')
  cover.getCell('A3').value = 'Sistema Canônico de Gestão Estratégica Portátil'
  cover.getCell('A3').font = { color: { argb: COLORS.dark }, bold: true, size: 17 }
  cover.mergeCells('A4:H4')
  cover.getCell('A4').value = 'SaaS + Planilha estruturada + Portal HTML + Pacote Estratégico Portável'
  cover.getCell('A4').font = { color: { argb: COLORS.gray }, italic: true }
  const coverData: [string, unknown][] = [
    ['Organização', organization.trade_name ?? organization.name], ['Código da organização', organization.code],
    ['Projeto', project.name ?? project.title], ['Código do projeto', project.code], ['Horizonte estratégico', project.horizon_label ?? project.horizon_end],
    ['Situação', project.status], ['Versão do esquema', manifesto.schema_version], ['Gerado em', manifesto.generated_at],
    ['Origem', manifesto.source_system], ['Confidencialidade', manifesto.confidentiality_level],
  ]
  coverData.forEach(([key, value], index) => {
    cover.getCell(7 + index, 1).value = key
    cover.getCell(7 + index, 1).font = { color: { argb: COLORS.dark }, bold: true }
    cover.mergeCells(7 + index, 2, 7 + index, 5)
    cover.getCell(7 + index, 2).value = normalize(value)
    cover.getCell(7 + index, 2).font = { color: { argb: COLORS.imported } }
  })

  addKeyValueSheet(workbook, 'Organização', organization)
  addKeyValueSheet(workbook, 'Projeto', project)
  addKeyValueSheet(workbook, 'Portabilidade', manifesto)

  Object.entries(SHEET_MAP).forEach(([source, mapping]) => addRowsSheet(workbook, mapping.name, asRows(dados[source]), mapping.preferred))

  const mappedSources = new Set(Object.keys(SHEET_MAP))
  Object.entries(dados).forEach(([source, value]) => {
    if (source === 'organizacao' || source === 'projeto' || mappedSources.has(source)) return
    const rows = asRows(value)
    if (rows.length) addRowsSheet(workbook, label(source).slice(0, 31), rows)
  })

  const dashboard = workbook.addWorksheet('Dashboard')
  styleSheet(dashboard, 'Dashboard', ['Indicador', 'Valor', 'Referência'])
  const metrics: [string, string, string][] = [
    ['Fases e etapas', 'Fases', 'Itens da jornada'], ['Evidências', 'Evidências', 'Evidências registradas'],
    ['Objetivos', 'Objetivos', 'Objetivos estratégicos'], ['Resultados-chave', 'KRs', 'KRs'],
    ['Iniciativas', 'Iniciativas', 'Iniciativas estratégicas'], ['Artefatos', 'Artefatos', 'Artefatos metodológicos'],
  ]
  metrics.forEach(([indicator, sheetName, reference], index) => {
    const row = 6 + index
    dashboard.getCell(row, 1).value = indicator
    dashboard.getCell(row, 1).font = { color: { argb: COLORS.dark }, bold: true }
    dashboard.getCell(row, 2).value = { formula: `MAX(0,COUNTA('${sheetName}'!A:A)-5)` }
    dashboard.getCell(row, 2).font = { color: { argb: '000000' } }
    dashboard.getCell(row, 2).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.teal } }
    dashboard.getCell(row, 3).value = reference
  })

  cover.getCell('A19').value = 'NAVEGAÇÃO PRINCIPAL'
  cover.getCell('A19').font = { color: { argb: COLORS.green }, bold: true, size: 12 }
  workbook.worksheets.filter((sheet) => sheet.name !== 'Capa').forEach((sheet, index) => {
    const row = 21 + Math.floor(index / 3)
    const col = 1 + (index % 3) * 3
    cover.mergeCells(row, col, row, col + 1)
    const cell = cover.getCell(row, col)
    cell.value = { text: sheet.name, hyperlink: `#'${sheet.name}'!A1` }
    cell.font = { color: { argb: COLORS.dark }, bold: true }
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLORS.light } }
    cell.alignment = { horizontal: 'center', vertical: 'middle' }
  })
  for (let column = 1; column <= 8; column += 1) cover.getColumn(column).width = column % 3 === 0 ? 4 : 20

  const buffer = await workbook.xlsx.writeBuffer()
  const organizationCode = String(manifesto.organization_code ?? organization.code ?? 'ORGANIZACAO').replace(/[^A-Za-z0-9_-]+/g, '_')
  const timestamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\..+/, '').replace('T', '_')
  return {
    blob: new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }),
    fileName: `SPARKs_PE_${organizationCode}_${timestamp}.xlsx`,
  }
}
