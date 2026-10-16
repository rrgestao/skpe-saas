import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const sources = [
  '../src/modules/portability/generateCanonicalWorkbook.ts',
  '../src/modules/portability/generatePortablePackage.ts',
  '../src/modules/portability/parseCanonicalWorkbook.ts',
  '../src/modules/skpe/DeliveryKitDialog.tsx',
]

function source(path: string) {
  return readFileSync(new URL(path, import.meta.url), 'utf8')
}

test('heavy spreadsheet and zip runtimes stay behind dynamic imports', () => {
  const combined = sources.map(source).join('\n')

  assert.doesNotMatch(combined, /import JSZip from ['"]jszip['"]/)
  assert.doesNotMatch(combined, /import ExcelJS from ['"]exceljs['"]/)
  assert.match(combined, /import\(['"]jszip['"]\)/)
  assert.match(combined, /import\(['"]exceljs['"]\)/)
})
