import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const source = readFileSync(new URL('../src/modules/measures/SparksMeasureDualSelector.tsx', import.meta.url), 'utf8')

test('catalog double-click only selects; adoption requires explicit action', () => {
  const match = source.match(/onDoubleClick=\{\(id\) => \{([\s\S]*?)\}\}/)
  assert.ok(match, 'catalog double-click handler must exist')
  assert.match(match[1], /setCatalogSelection\(\[id\]\)/)
  assert.doesNotMatch(match[1], /adoptReferences|adoptSelected|supabase\.rpc/)
  assert.match(source, /onClick=\{\(\) => void adoptSelected\(\)\}/)
  assert.match(source, /Selecione os indicadores e clique em Adotar para confirmar/)
})
