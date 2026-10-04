import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const loader = readFileSync(
  new URL('../src/modules/skpe/features/diagnosis/strategicDiagnosisImportLoader.ts', import.meta.url),
  'utf8',
)
const staging = readFileSync(
  new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url),
  'utf8',
)

test('post-load diagnosis loader preserves approved strategic risk facts', () => {
  assert.match(loader, /management_recognition/)
  assert.match(loader, /risk_acceptance/)
  assert.match(loader, /acceptance_evidence/)
  assert.match(loader, /implementation_cycle/)
  assert.match(loader, /portfolio_destination/)
  assert.match(loader, /reconhecimento_pela_direcao: row\.management_recognition/)
  assert.match(loader, /aceite_do_risco: row\.risk_acceptance/)
})

test('post-load staging consumes governed queue instead of reopening all covered records', () => {
  assert.match(staging, /action: 'get_batch_review_queue'/)
  assert.match(staging, /pendingImportRecordIds/)
  assert.match(staging, /candidates\.filter\(\(candidate\) => pendingIds\.has\(candidate\.id\)\)/)
})
