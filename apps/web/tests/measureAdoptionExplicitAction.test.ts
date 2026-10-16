import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const source = readFileSync(new URL('../src/modules/measures/SparksMeasureDualSelector.tsx', import.meta.url), 'utf8')

test('catalog single click selects and double click adopts through governed action', () => {
  const match = source.match(/onDoubleClick=\{\(id\) => \{([\s\S]*?)\}\}/)
  assert.ok(match, 'catalog double-click handler must exist')
  assert.match(source, /onSelectionChange=\{setCatalogSelection\}/)
  assert.match(match[1], /setCatalogSelection\(\[id\]\)/)
  assert.match(match[1], /void adoptReferences\(\[id\]\)/)
  assert.match(source, /onClick=\{\(\) => void adoptSelected\(\)\}/)
  assert.match(source, /Um clique seleciona; duplo clique adota o indicador/)
})
