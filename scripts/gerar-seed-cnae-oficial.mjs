import fs from 'node:fs'
import path from 'node:path'
import process from 'node:process'
import * as XLSX from 'xlsx'

const SOURCE_URL = 'https://cnae.ibge.gov.br/classificacoes/download-concla/8265-download'
const VERSION_CODE = '2.3'
const VERSION_NAME = 'CNAE-Subclasses 2.3'

function normalizeHeader(value) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
}

function digits(value) {
  return String(value ?? '').replace(/[^0-9]/g, '')
}

function text(value) {
  return String(value ?? '').trim().replace(/\s+/g, ' ')
}

function sql(value) {
  if (value === null || value === undefined || value === '') return 'null'
  return `'${String(value).replace(/'/g, "''")}'`
}

function locateHeader(rows) {
  const maxScan = Math.min(rows.length, 40)

  for (let rowIndex = 0; rowIndex < maxScan; rowIndex += 1) {
    const normalized = rows[rowIndex].map(normalizeHeader)
    const subclassIndex = normalized.findIndex((item) => item.includes('subclasse'))
    const descriptionIndex = normalized.findIndex(
      (item) => item.includes('denominacao') || item.includes('descricao'),
    )

    if (subclassIndex >= 0 && descriptionIndex >= 0) {
      return { rowIndex, normalized }
    }
  }

  throw new Error(
    'Não foi possível localizar o cabeçalho com as colunas Subclasse e Denominação.',
  )
}

function findColumn(headers, candidates) {
  return headers.findIndex((header) =>
    candidates.some((candidate) => header === candidate || header.includes(candidate)),
  )
}

function chooseSheet(workbook) {
  let selected = null

  for (const sheetName of workbook.SheetNames) {
    const sheet = workbook.Sheets[sheetName]
    const rows = XLSX.utils.sheet_to_json(sheet, {
      header: 1,
      raw: false,
      defval: '',
      blankrows: false,
    })

    try {
      const header = locateHeader(rows)
      if (!selected || rows.length > selected.rows.length) {
        selected = { sheetName, rows, header }
      }
    } catch {
      // Ignora abas sem a estrutura detalhada.
    }
  }

  if (!selected) {
    throw new Error('Nenhuma aba compatível com a estrutura CNAE foi encontrada.')
  }

  return selected
}

function parseCatalog(rows, headerInfo) {
  const headers = headerInfo.normalized
  const indexes = {
    section: findColumn(headers, ['secao']),
    division: findColumn(headers, ['divisao']),
    group: findColumn(headers, ['grupo']),
    class: findColumn(headers, ['classe']),
    subclass: findColumn(headers, ['subclasse']),
    description: findColumn(headers, ['denominacao', 'descricao']),
  }

  if (indexes.subclass < 0 || indexes.description < 0) {
    throw new Error('As colunas obrigatórias não foram identificadas.')
  }

  const current = {
    sectionCode: '',
    sectionName: '',
    divisionCode: '',
    divisionName: '',
    groupCode: '',
    groupName: '',
    classCode: '',
    className: '',
  }

  const records = []

  for (let rowIndex = headerInfo.rowIndex + 1; rowIndex < rows.length; rowIndex += 1) {
    const row = rows[rowIndex]
    const description = text(row[indexes.description])
    if (!description) continue

    const sectionCode = indexes.section >= 0 ? text(row[indexes.section]).toUpperCase() : ''
    const divisionCode = indexes.division >= 0 ? digits(row[indexes.division]).padStart(2, '0').slice(-2) : ''
    const groupCode = indexes.group >= 0 ? digits(row[indexes.group]).padStart(3, '0').slice(-3) : ''
    const classCode = indexes.class >= 0 ? digits(row[indexes.class]).padStart(5, '0').slice(-5) : ''
    const subclassCode = digits(row[indexes.subclass])

    if (sectionCode && !divisionCode && !groupCode && !classCode && !subclassCode) {
      current.sectionCode = sectionCode
      current.sectionName = description
      current.divisionCode = ''
      current.divisionName = ''
      current.groupCode = ''
      current.groupName = ''
      current.classCode = ''
      current.className = ''
      continue
    }

    if (divisionCode && !groupCode && !classCode && !subclassCode) {
      current.divisionCode = divisionCode
      current.divisionName = description
      current.groupCode = ''
      current.groupName = ''
      current.classCode = ''
      current.className = ''
      continue
    }

    if (groupCode && !classCode && !subclassCode) {
      current.groupCode = groupCode
      current.groupName = description
      current.classCode = ''
      current.className = ''
      continue
    }

    if (classCode && !subclassCode) {
      current.classCode = classCode
      current.className = description
      continue
    }

    if (subclassCode.length === 7) {
      if (sectionCode) current.sectionCode = sectionCode
      if (divisionCode) current.divisionCode = divisionCode
      if (groupCode) current.groupCode = groupCode
      if (classCode) current.classCode = classCode

      records.push({
        subclassCode,
        description,
        sectionCode: current.sectionCode || null,
        sectionName: current.sectionName || null,
        divisionCode: current.divisionCode || subclassCode.slice(0, 2),
        divisionName: current.divisionName || null,
        groupCode: current.groupCode || subclassCode.slice(0, 3),
        groupName: current.groupName || null,
        classCode: current.classCode || subclassCode.slice(0, 5),
        className: current.className || null,
        sourceRowNumber: rowIndex + 1,
      })
    }
  }

  const unique = new Map()
  for (const record of records) unique.set(record.subclassCode, record)
  return [...unique.values()].sort((a, b) => a.subclassCode.localeCompare(b.subclassCode))
}

function buildSql(records, workbookName, sheetName) {
  const lines = []
  lines.push('begin;')
  lines.push('')
  lines.push('insert into public.cnae_catalog_versions (')
  lines.push('  version_code, version_name, source_organization, source_url,')
  lines.push('  official_reference, is_current, active, imported_at, imported_by')
  lines.push(') values (')
  lines.push(`  ${sql(VERSION_CODE)}, ${sql(VERSION_NAME)}, 'IBGE/CONCLA', ${sql(SOURCE_URL)},`)
  lines.push(`  ${sql(`Arquivo oficial ${workbookName}; aba ${sheetName}`)}, true, true, timezone('utc', now()), auth.uid()`)
  lines.push(') on conflict (version_code) do update set')
  lines.push('  version_name = excluded.version_name,')
  lines.push('  source_organization = excluded.source_organization,')
  lines.push('  source_url = excluded.source_url,')
  lines.push('  official_reference = excluded.official_reference,')
  lines.push('  is_current = true, active = true,')
  lines.push("  imported_at = timezone('utc', now()), imported_by = auth.uid(),")
  lines.push("  updated_at = timezone('utc', now());")
  lines.push('')

  const batchSize = 200
  for (let start = 0; start < records.length; start += batchSize) {
    const batch = records.slice(start, start + batchSize)
    lines.push('insert into public.cnae_catalog (')
    lines.push('  version_code, subclass_code, description,')
    lines.push('  section_code, section_name, division_code, division_name,')
    lines.push('  group_code, group_name, class_code, class_name,')
    lines.push('  active, source_row_number, created_by, updated_by')
    lines.push(') values')

    batch.forEach((record, index) => {
      const suffix = index === batch.length - 1 ? '' : ','
      lines.push(
        `  (${sql(VERSION_CODE)}, ${sql(record.subclassCode)}, ${sql(record.description)}, ` +
          `${sql(record.sectionCode)}, ${sql(record.sectionName)}, ` +
          `${sql(record.divisionCode)}, ${sql(record.divisionName)}, ` +
          `${sql(record.groupCode)}, ${sql(record.groupName)}, ` +
          `${sql(record.classCode)}, ${sql(record.className)}, ` +
          `true, ${record.sourceRowNumber}, auth.uid(), auth.uid())${suffix}`,
      )
    })

    lines.push('on conflict (version_code, subclass_code) do update set')
    lines.push('  description = excluded.description,')
    lines.push('  section_code = excluded.section_code,')
    lines.push('  section_name = excluded.section_name,')
    lines.push('  division_code = excluded.division_code,')
    lines.push('  division_name = excluded.division_name,')
    lines.push('  group_code = excluded.group_code,')
    lines.push('  group_name = excluded.group_name,')
    lines.push('  class_code = excluded.class_code,')
    lines.push('  class_name = excluded.class_name,')
    lines.push('  active = true,')
    lines.push('  source_row_number = excluded.source_row_number,')
    lines.push("  updated_at = timezone('utc', now()),")
    lines.push('  updated_by = auth.uid();')
    lines.push('')
  }

  lines.push('update public.cnae_catalog_versions')
  lines.push("set imported_at = timezone('utc', now()), imported_by = auth.uid(), updated_at = timezone('utc', now())")
  lines.push(`where version_code = ${sql(VERSION_CODE)};`)
  lines.push('')
  lines.push('commit;')
  lines.push('')
  lines.push('-- Verificacao')
  lines.push("select version_code, count(*) as quantidade from public.cnae_catalog where active = true group by version_code order by version_code;")
  lines.push('')
  return lines.join('\n')
}

const [, , inputArg, outputArg] = process.argv

if (!inputArg) {
  console.error('Uso: node gerar-seed-cnae-oficial.mjs <arquivo-oficial.xlsx> [saida.sql]')
  process.exit(1)
}

const inputPath = path.resolve(inputArg)
const outputPath = path.resolve(outputArg ?? 'cnae-subclasses-2.3-seed.sql')

if (!fs.existsSync(inputPath)) {
  console.error(`Arquivo não encontrado: ${inputPath}`)
  process.exit(1)
}

const workbook = XLSX.readFile(inputPath, { cellDates: false })
const selected = chooseSheet(workbook)
const records = parseCatalog(selected.rows, selected.header)

if (records.length < 1000) {
  throw new Error(
    `Foram encontrados somente ${records.length} CNAEs. Revise o arquivo e o cabeçalho antes de importar.`,
  )
}

const sqlContent = buildSql(records, path.basename(inputPath), selected.sheetName)
fs.writeFileSync(outputPath, sqlContent, 'utf8')

console.log(`Aba utilizada: ${selected.sheetName}`)
console.log(`CNAEs encontrados: ${records.length}`)
console.log(`Seed SQL gerado: ${outputPath}`)
