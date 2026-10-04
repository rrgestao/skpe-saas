import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const source = readFileSync(
  new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url),
  'utf8',
)

test('review queue is not limited to diagnostic entity types', () => {
  assert.doesNotMatch(source, /DIAGNOSTIC_INCORPORATION_TYPES/)
  assert.doesNotMatch(source, /diagnosticTypes/)
  assert.match(source, /const reviewableTypes = Array\.from\(coveredTypes\)/)
  assert.match(source, /\.in\('entity_code', reviewableTypes\)/)
})

test('review queue only exposes actionable valid import records', () => {
  assert.match(source, /\.in\('proposed_action', \['insert', 'update'\]\)/)
  assert.match(source, /\.eq\('quality_status', 'valid'\)/)
})

test('governed backend queue remains authoritative', () => {
  assert.match(source, /action: 'get_batch_review_queue'/)
  assert.match(source, /pendingImportRecordIds/)
  assert.match(source, /candidates\.filter\(\(candidate\) => pendingIds\.has\(candidate\.id\)\)/)
})

test('batch preparation language is generic pre-load review, not diagnostic-only', () => {
  assert.match(source, /Preparação governada para revisão pré-carga/)
  assert.doesNotMatch(source, /primeiro pacote de Diagnóstico/)
})
