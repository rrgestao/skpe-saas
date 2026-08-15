import ExcelJS from 'exceljs'
import JSZip from 'jszip'
import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { parseCanonicalWorkbook } from '../src/modules/portability/parseCanonicalWorkbook.ts'

const V26_SHEETS = [
  '00_Capa', '01_Projeto', '02_Fases', '03_Evidencias', '04_PESTEL', '05_SWOT', '06_TOWS', '07_Riscos',
  '08_Identidade', '09_Objetivos_Estrategicos', '10_Mapa_Estrategico', '11_OKRs', '12_KRs', '13_Indicadores',
  '14_Metas', '15_Iniciativas', '16_5W2H', '17_Acompanhamento', '18_Decisoes', '19_Aprendizados', '20_Dashboard',
  '21_Guia_Abas', '22_Dicionario_Dados', '23_Regras_Integridade', '24_Blueprint_HTML', '25_Validacao_Cliente',
  '26_Artefatos', '27_Pendencias', '28_Handoff', '29_Controle_Versoes', '99_Listas_Parametros', '30_Governanca_Viva',
  '31_Gate_Deliberativo', '32_Gestao_Evidencias', '33_Maturidade_Processos', '34_PMVV_Validacao', '35_Valores',
  '36_PMVV_5W2H', '37_Portfolio_Projetos', '38_Resultados_KPI', '39_Desvios_Acoes', '40_Reunioes_Estrategicas',
  '41_Revisao_Estrategica', '42_Rastreabilidade', '43_Arquitetura_SGE', '44_Checklist_Evidencias_PE',
  '45_Protótipo_SPARKs_PE', '46_Fichas_Indicadores', '47_Associacao_Estrategica', '48_Benchmarks_Referencias',
  '49_Premissas_Idioma_Propósito', '50_Temas_Perspectivas', '51_Validacao_PEM0204', '52_Matriz_Evidencias_0204',
] as const

function setTable(sheet: ExcelJS.Worksheet, headers: string[], rows: Array<Array<string | number | Date | null>>) {
  sheet.getRow(4).values = [null, ...headers]
  rows.forEach((values, index) => { sheet.getRow(index + 5).values = [null, ...values] })
}

async function representativeV26(options: { prefixedOoxml?: boolean; valuesSheet?: string } = {}): Promise<Uint8Array> {
  const workbook = new ExcelJS.Workbook()
  V26_SHEETS.forEach((name) => workbook.addWorksheet(name === '35_Valores' ? (options.valuesSheet ?? name) : name))
  setTable(workbook.getWorksheet('01_Projeto')!, ['Campo', 'Informação'], [
    ['Organização', 'COOTAQUARA'], ['Horizonte estratégico', '2026–2030'], ['Versão da solução', '26.0'],
  ])
  setTable(workbook.getWorksheet('02_Fases')!, ['Código', 'Fase', 'Status'], [
    ['MF1', 'Diagnóstico e Entendimento Estratégico', 'Aprovado'], ['MF2', 'Formulação Estratégica', 'Em andamento'],
  ])
  setTable(workbook.getWorksheet('18_Decisoes')!, ['Código', 'Data', 'Tema', 'Decisão', 'Situação'], [
    ['DEC-02.03', new Date(Date.UTC(2026, 6, 30)), 'PMVV', 'Aprovado integralmente', 'Aprovado'],
    ['DEC-02.04', new Date(Date.UTC(2026, 6, 30)), 'Arquitetura dos Valores', 'Aprovado integralmente', 'Aprovado'],
  ])
  setTable(workbook.getWorksheet('31_Gate_Deliberativo')!, ['Código', 'Situação', 'Justificativa/condição'], [
    ['RIS-01', 'Aprovada', 'Todos os riscos aceitos; iniciativas devem compor o portfólio do Ciclo 1'],
  ])
  setTable(workbook.getWorksheet('34_PMVV_Validacao')!, ['Elemento', 'Data', 'Evidência', 'Status pós-reunião'], [
    ['Propósito', new Date(Date.UTC(2026, 6, 30)), 'Deliberação da Direção', 'Aprovado'],
  ])
  const valuesSheet = workbook.getWorksheet(options.valuesSheet ?? '35_Valores')!
  setTable(valuesSheet, ['Valor', 'Decisão', 'Maturidade'], Array.from({ length: 7 }, (_, index) => [
    `Valor ${index + 1}`, 'Aprovado integralmente', 'Aprovado — institucionalização em andamento',
  ]))
  setTable(workbook.getWorksheet('51_Validacao_PEM0204')!, ['Código', 'Elemento', 'Tipo', 'Decisão'], [
    ['TE-01', 'Tema 1', 'Tema', ''], ['PE-01', 'Perspectiva 1', 'Perspectiva', ''],
    ['OE-01', 'Objetivo 1', 'Objetivo Estratégico — OKR', ''],
  ])
  setTable(workbook.getWorksheet('12_KRs')!, ['Código', 'Título'], [
    ['KR-01', 'Resultado duplicado A'], ['KR-01', 'Resultado duplicado B'],
  ])
  setTable(workbook.getWorksheet('26_Artefatos')!, ['Código', 'Data', 'Status'], [
    ['PEM-02.SGE-01', 'data inválida', '30/07/2026'],
  ])

  const original = new Uint8Array(await workbook.xlsx.writeBuffer())
  if (!options.prefixedOoxml) return original

  const zip = await JSZip.loadAsync(original)
  for (const [path, entry] of Object.entries(zip.files)) {
    if (entry.dir || !path.endsWith('.xml')) continue
    const xml = await entry.async('string')
    if (!xml.includes('xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"')) continue
    zip.file(path, xml
      .replace('xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"', 'xmlns:x="http://schemas.openxmlformats.org/spreadsheetml/2006/main"')
      .replace(/<(\/?)([A-Za-z][\w.-]*)(?=[\s/>])/g, '<$1x:$2'))
  }
  return zip.generateAsync({ type: 'uint8array' })
}

function asFile(bytes: Uint8Array, name = 'SPARKs_PE_COOTAQUARA_v26.xlsx', type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
  return new File([bytes], name, { type, lastModified: Date.UTC(2026, 7, 15) })
}

describe('parseCanonicalWorkbook', () => {
  it('lê a estrutura representativa da v26, preserva os sete Valores e não grava no banco', async () => {
    const preview = await parseCanonicalWorkbook(asFile(await representativeV26({ prefixedOoxml: true })))
    assert.equal(preview.sheetCount, 54)
    assert.equal(preview.organization, 'COOTAQUARA')
    assert.equal(preview.databaseWrites, false)
    assert.equal(preview.sheets.find((sheet) => sheet.sheet === '35_Valores')?.entityCode, 'living_value')
    assert.equal(preview.entities.find((entity) => entity.entityCode === 'living_value')?.records.length, 7)
    assert.ok(preview.quality.autoCorrectedIssues > 0)
    assert.ok(preview.quarantinedRecords > 0)
    assert.equal(preview.quarantine[0]?.entityCode, 'methodology_artifact')
    assert.match(preview.conflicts.find((item) => item.topic === 'PMVV')?.canonicalValue ?? '', /aprovado/)
    assert.match(preview.conflicts.find((item) => item.topic === 'PEM-02.04')?.canonicalValue ?? '', /pré-validação/)
    assert.equal(preview.journey.currentStage, 'PEM-02.04 — Pré-validação')
  })

  it('mantém compatibilidade com o alias legado 35_Valores_Vivos', async () => {
    const preview = await parseCanonicalWorkbook(asFile(await representativeV26({ valuesSheet: '35_Valores_Vivos' })))
    assert.equal(preview.entities.find((entity) => entity.entityCode === 'living_value')?.records.length, 7)
  })

  it('distingue formato não suportado, arquivo corrompido e ausência de abas obrigatórias', async () => {
    await assert.rejects(parseCanonicalWorkbook(asFile(new Uint8Array([1, 2, 3]), 'dados.csv', 'text/csv')), /Formato não suportado/)
    await assert.rejects(parseCanonicalWorkbook(asFile(new Uint8Array([1, 2, 3, 4]))), /Arquivo inválido ou corrompido/)

    const workbook = new ExcelJS.Workbook()
    workbook.addWorksheet('01_Projeto')
    const bytes = new Uint8Array(await workbook.xlsx.writeBuffer())
    await assert.rejects(parseCanonicalWorkbook(asFile(bytes)), /Ausência de abas canônicas obrigatórias: 02_Fases/)
  })
})
