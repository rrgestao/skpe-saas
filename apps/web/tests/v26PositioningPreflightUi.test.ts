import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const staging = readFileSync(
  new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url),
  'utf8',
)

test('v26 staging exposes PEM-02.03 structured validation preflight before staging', () => {
  assert.match(staging, /Preflight PEM-02\.03 \/ v26/)
  assert.match(staging, /Validação estruturada reportada como aprovada sem adequações/)
  assert.match(staging, /Temas/)
  assert.match(staging, /Perspectivas/)
  assert.match(staging, /Objetivos/)
  assert.match(staging, /19\/19 decisões aprovadas/)
  assert.match(staging, /nenhum estado canônico é promovido/)
  assert.match(staging, /Reconciliação canônica continua pendente/)
})
