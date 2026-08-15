import crypto from 'node:crypto'
import fs from 'node:fs'
import path from 'node:path'
import process from 'node:process'
import ExcelJS from 'exceljs'

const SOURCE_URL =
  'https://www.ibge.gov.br/estatisticas/metodos-e-classificacoes/classificacoes-e-listas-estatisticas/9078-classificacao-nacional-de-atividades-economicas.html'
const VERSION_CODE = '2.3'
const VERSION_NAME = 'CNAE-Subclasses 2.3'
const MINIMUM_EXPECTED_RECORDS = 1000

function normalizeHeader(value) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
}

function text(value) {
  return String(value ?? '')
    .replace(/\u00a0/g, ' ')
    .trim()
    .replace(/\s+/g, ' ')
}

function digits(value) {
  return text(value).replace(/[^0-9]/g, '')
}

function codeWithLength(value, expectedLength) {
  const valueDigits = digits(value)

  if (!valueDigits) {
    return ''
  }

  if (valueDigits.length > expectedLength) {
    return ''
  }

  return valueDigits.padStart(expectedLength, '0')
}

function sql(value) {
  if (value === null || value === undefined || value === '') {
    return 'null'
  }

  return `'${String(value).replace(/'/g, "''")}'`
}

function sha256(filePath) {
  return crypto
    .createHash('sha256')
    .update(fs.readFileSync(filePath))
    .digest('hex')
}

function locateHeader(rows) {
  const scanLimit = Math.min(rows.length, 250)

  for (let rowIndex = 0; rowIndex < scanLimit; rowIndex += 1) {
    const normalized = rows[rowIndex].map(normalizeHeader)
    const subclassIndex = normalized.findIndex(
      (item) => item === 'subclasse',
    )
    const descriptionIndex = normalized.findIndex(
      (item) =>
        item === 'denominacao' || item === 'descricao',
    )

    if (subclassIndex >= 0 && descriptionIndex >= 0) {
      return {
        rowIndex,
        normalized,
      }
    }
  }

  throw new Error(
    'Não foi possível localizar o cabeçalho com as colunas Subclasse e Denominação.',
  )
}

function findColumn(headers, candidates) {
  return headers.findIndex((header) =>
    candidates.some((candidate) => header === candidate),
  )
}

function cellText(cell) {
  const value = cell.value

  if (value === null || value === undefined) {
    return ''
  }

  if (value instanceof Date) {
    const day = String(value.getDate()).padStart(2, '0')
    const month = String(value.getMonth() + 1).padStart(2, '0')
    return `${day}/${month}/${value.getFullYear()}`
  }

  if (typeof value === 'object') {
    if ('result' in value && value.result !== null && value.result !== undefined) {
      return text(value.result)
    }

    if ('richText' in value && Array.isArray(value.richText)) {
      return text(value.richText.map((part) => part.text ?? '').join(''))
    }

    if ('text' in value && typeof value.text === 'string') {
      return text(value.text)
    }

    return ''
  }

  return text(cell.text || value)
}

function sheetRows(worksheet) {
  const rows = []

  worksheet.eachRow({ includeEmpty: true }, (row, rowNumber) => {
    const values = []

    for (let column = 1; column <= row.cellCount; column += 1) {
      values.push(cellText(row.getCell(column)))
    }

    rows[rowNumber - 1] = values
  })

  return rows.map((row) => row ?? [])
}

function chooseSheet(workbook) {
  let selected = null

  for (const worksheet of workbook.worksheets) {
    const sheetName = worksheet.name
    const rows = sheetRows(worksheet)

    try {
      const header = locateHeader(rows)

      if (!selected || rows.length > selected.rows.length) {
        selected = {
          sheetName,
          rows,
          header,
        }
      }
    } catch {
      // Abas sem a estrutura detalhada são ignoradas.
    }
  }

  if (!selected) {
    throw new Error(
      'Nenhuma aba compatível com a estrutura detalhada da CNAE foi encontrada.',
    )
  }

  return selected
}

function isRepeatedHeader(row, indexes) {
  const subclassHeader = normalizeHeader(row[indexes.subclass])
  const descriptionHeader = normalizeHeader(row[indexes.description])

  return (
    subclassHeader === 'subclasse' &&
    (descriptionHeader === 'denominacao' ||
      descriptionHeader === 'descricao')
  )
}

function parseCatalog(rows, headerInfo) {
  const headers = headerInfo.normalized
  const indexes = {
    section: findColumn(headers, ['secao']),
    division: findColumn(headers, ['divisao']),
    group: findColumn(headers, ['grupo']),
    class: findColumn(headers, ['classe']),
    subclass: findColumn(headers, ['subclasse']),
    description: findColumn(headers, [
      'denominacao',
      'descricao',
    ]),
  }

  if (indexes.subclass < 0 || indexes.description < 0) {
    throw new Error(
      'As colunas obrigatórias Subclasse e Denominação não foram identificadas.',
    )
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
  const duplicateDescriptions = []

  for (
    let rowIndex = headerInfo.rowIndex + 1;
    rowIndex < rows.length;
    rowIndex += 1
  ) {
    const row = rows[rowIndex]

    if (!Array.isArray(row) || isRepeatedHeader(row, indexes)) {
      continue
    }

    const description = text(row[indexes.description])

    if (!description) {
      continue
    }

    const sectionRaw =
      indexes.section >= 0
        ? text(row[indexes.section]).toUpperCase()
        : ''
    const sectionCode = /^[A-Z]$/.test(sectionRaw)
      ? sectionRaw
      : ''
    const divisionCode =
      indexes.division >= 0
        ? codeWithLength(row[indexes.division], 2)
        : ''
    const groupCode =
      indexes.group >= 0
        ? codeWithLength(row[indexes.group], 3)
        : ''
    const classCode =
      indexes.class >= 0
        ? codeWithLength(row[indexes.class], 5)
        : ''
    const subclassCode = codeWithLength(
      row[indexes.subclass],
      7,
    )

    if (
      sectionCode &&
      !divisionCode &&
      !groupCode &&
      !classCode &&
      !subclassCode
    ) {
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

    if (
      divisionCode &&
      !groupCode &&
      !classCode &&
      !subclassCode
    ) {
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

    if (subclassCode.length !== 7) {
      continue
    }

    const record = {
      subclassCode,
      description,
      sectionCode: current.sectionCode || null,
      sectionName: current.sectionName || null,
      divisionCode:
        current.divisionCode || subclassCode.slice(0, 2),
      divisionName: current.divisionName || null,
      groupCode:
        current.groupCode || subclassCode.slice(0, 3),
      groupName: current.groupName || null,
      classCode:
        current.classCode || subclassCode.slice(0, 5),
      className: current.className || null,
      sourceRowNumber: rowIndex + 1,
    }

    const existing = records.find(
      (item) => item.subclassCode === subclassCode,
    )

    if (
      existing &&
      existing.description !== record.description
    ) {
      duplicateDescriptions.push({
        subclassCode,
        first: existing.description,
        second: record.description,
      })
    }

    records.push(record)
  }

  if (duplicateDescriptions.length > 0) {
    throw new Error(
      `Foram encontrados códigos duplicados com denominações diferentes: ${JSON.stringify(
        duplicateDescriptions.slice(0, 5),
      )}`,
    )
  }

  const unique = new Map()

  for (const record of records) {
    unique.set(record.subclassCode, record)
  }

  return [...unique.values()].sort((first, second) =>
    first.subclassCode.localeCompare(second.subclassCode),
  )
}

function validateRecords(records) {
  if (records.length < MINIMUM_EXPECTED_RECORDS) {
    throw new Error(
      `Foram encontrados somente ${records.length} CNAEs. Revise o arquivo oficial e o parser antes de importar.`,
    )
  }

  const invalidCodes = records.filter(
    (record) => !/^[0-9]{7}$/.test(record.subclassCode),
  )

  if (invalidCodes.length > 0) {
    throw new Error(
      `Foram encontrados códigos inválidos: ${JSON.stringify(
        invalidCodes.slice(0, 5),
      )}`,
    )
  }

  const missingDescriptions = records.filter(
    (record) => !record.description,
  )

  if (missingDescriptions.length > 0) {
    throw new Error(
      `Foram encontradas subclasses sem denominação: ${missingDescriptions.length}.`,
    )
  }
}

function buildSql({
  records,
  workbookName,
  sheetName,
  checksum,
}) {
  const lines = []

  lines.push('-- ============================================================')
  lines.push('-- Plataforma SPARKs')
  lines.push('-- Catálogo oficial CNAE-Subclasses 2.3')
  lines.push(`-- Arquivo: ${workbookName}`)
  lines.push(`-- Aba: ${sheetName}`)
  lines.push(`-- SHA-256: ${checksum}`)
  lines.push(`-- Registros: ${records.length}`)
  lines.push('-- ============================================================')
  lines.push('')
  lines.push('begin;')
  lines.push('')
  lines.push('update public.cnae_catalog_versions')
  lines.push('set is_current = false,')
  lines.push("    updated_at = timezone('utc', now())")
  lines.push(
    `where version_code <> ${sql(VERSION_CODE)} and is_current = true;`,
  )
  lines.push('')
  lines.push('insert into public.cnae_catalog_versions (')
  lines.push('  version_code, version_name, source_organization,')
  lines.push('  source_url, official_reference, is_current, active,')
  lines.push('  source_checksum, imported_at, imported_by')
  lines.push(') values (')
  lines.push(
    `  ${sql(VERSION_CODE)}, ${sql(VERSION_NAME)}, 'IBGE/CONCLA',`,
  )
  lines.push(`  ${sql(SOURCE_URL)},`)
  lines.push(
    `  ${sql(
      `Arquivo oficial ${workbookName}; aba ${sheetName}`,
    )}, true, true,`,
  )
  lines.push(
    `  ${sql(checksum)}, timezone('utc', now()), auth.uid()`,
  )
  lines.push(') on conflict (version_code) do update set')
  lines.push('  version_name = excluded.version_name,')
  lines.push('  source_organization = excluded.source_organization,')
  lines.push('  source_url = excluded.source_url,')
  lines.push('  official_reference = excluded.official_reference,')
  lines.push('  is_current = true,')
  lines.push('  active = true,')
  lines.push('  source_checksum = excluded.source_checksum,')
  lines.push("  imported_at = timezone('utc', now()),")
  lines.push('  imported_by = auth.uid(),')
  lines.push("  updated_at = timezone('utc', now());")
  lines.push('')
  lines.push('update public.cnae_catalog')
  lines.push('set active = false,')
  lines.push("    updated_at = timezone('utc', now()),")
  lines.push('    updated_by = auth.uid()')
  lines.push(`where version_code = ${sql(VERSION_CODE)};`)
  lines.push('')

  const batchSize = 200

  for (
    let start = 0;
    start < records.length;
    start += batchSize
  ) {
    const batch = records.slice(start, start + batchSize)

    lines.push('insert into public.cnae_catalog (')
    lines.push('  version_code, subclass_code, description,')
    lines.push('  section_code, section_name,')
    lines.push('  division_code, division_name,')
    lines.push('  group_code, group_name,')
    lines.push('  class_code, class_name,')
    lines.push('  active, source_row_number, created_by, updated_by')
    lines.push(') values')

    batch.forEach((record, index) => {
      const suffix = index === batch.length - 1 ? '' : ','

      lines.push(
        `  (${sql(VERSION_CODE)}, ${sql(
          record.subclassCode,
        )}, ${sql(record.description)}, ` +
          `${sql(record.sectionCode)}, ${sql(
            record.sectionName,
          )}, ` +
          `${sql(record.divisionCode)}, ${sql(
            record.divisionName,
          )}, ` +
          `${sql(record.groupCode)}, ${sql(
            record.groupName,
          )}, ` +
          `${sql(record.classCode)}, ${sql(
            record.className,
          )}, ` +
          `true, ${record.sourceRowNumber}, auth.uid(), auth.uid())${suffix}`,
      )
    })

    lines.push(
      'on conflict (version_code, subclass_code) do update set',
    )
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
    lines.push(
      '  source_row_number = excluded.source_row_number,',
    )
    lines.push("  updated_at = timezone('utc', now()),")
    lines.push('  updated_by = auth.uid();')
    lines.push('')
  }

  lines.push('commit;')
  lines.push('')
  lines.push('-- Verificação pós-importação')
  lines.push('select')
  lines.push('  version_code,')
  lines.push('  count(*) filter (where active = true) as ativos,')
  lines.push('  count(*) filter (where active = false) as inativos,')
  lines.push('  min(subclass_code) as primeiro_codigo,')
  lines.push('  max(subclass_code) as ultimo_codigo')
  lines.push('from public.cnae_catalog')
  lines.push(`where version_code = ${sql(VERSION_CODE)}`)
  lines.push('group by version_code;')
  lines.push('')
  lines.push('select count(*) as registros_com_hierarquia_incompleta')
  lines.push('from public.cnae_catalog')
  lines.push(`where version_code = ${sql(VERSION_CODE)}`)
  lines.push('  and active = true')
  lines.push('  and (')
  lines.push('    section_code is null')
  lines.push('    or division_code is null')
  lines.push('    or group_code is null')
  lines.push('    or class_code is null')
  lines.push('  );')
  lines.push('')

  return lines.join('\n')
}

const [, , inputArg, outputArg] = process.argv

if (!inputArg) {
  console.error(
    'Uso: node gerar-seed-cnae-oficial.mjs <arquivo-oficial.xlsx> [saida.sql]',
  )
  process.exit(1)
}

const inputPath = path.resolve(inputArg)
const outputPath = path.resolve(
  outputArg ?? 'cnae-subclasses-2.3-seed.sql',
)

if (!fs.existsSync(inputPath)) {
  console.error(`Arquivo não encontrado: ${inputPath}`)
  process.exit(1)
}

if (path.extname(inputPath).toLowerCase() !== '.xlsx') {
  console.error(
    `Formato não suportado: ${path.extname(inputPath) || 'sem extensão'}. Use o arquivo oficial em formato .xlsx.`,
  )
  process.exit(1)
}

const workbook = new ExcelJS.Workbook()
await workbook.xlsx.readFile(inputPath, {
  ignoreNodes: ['drawing', 'legacyDrawing'],
})
const selected = chooseSheet(workbook)
const records = parseCatalog(selected.rows, selected.header)

validateRecords(records)

const checksum = sha256(inputPath)
const sqlContent = buildSql({
  records,
  workbookName: path.basename(inputPath),
  sheetName: selected.sheetName,
  checksum,
})

fs.mkdirSync(path.dirname(outputPath), {
  recursive: true,
})
fs.writeFileSync(outputPath, sqlContent, 'utf8')

const completeHierarchyCount = records.filter(
  (record) =>
    record.sectionCode &&
    record.divisionCode &&
    record.groupCode &&
    record.classCode,
).length

console.log(`Arquivo oficial: ${inputPath}`)
console.log(`Aba utilizada: ${selected.sheetName}`)
console.log(`CNAEs encontrados: ${records.length}`)
console.log(
  `Registros com hierarquia completa: ${completeHierarchyCount}`,
)
console.log(`SHA-256: ${checksum}`)
console.log(`Seed SQL gerado: ${outputPath}`)
