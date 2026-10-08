import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const harness = readFileSync(
  new URL('../scripts/validate-neutral-runtime.mjs', import.meta.url),
  'utf8',
)
const packageJson = readFileSync(
  new URL('../package.json', import.meta.url),
  'utf8',
)

test('neutral E2E harness is hard-scoped to the technical runtime tenant', () => {
  assert.match(harness, /EXPECTED_ORG_CODE = 'SKPE-V1-RUNTIME'/)
  assert.match(harness, /EXPECTED_PROJECT_CODE = 'PE-SKPE-V1-RUNTIME-2026'/)
  assert.match(harness, /Execução recusada: o harness só pode operar em/)
  assert.doesNotMatch(harness, /COOTAQUARA/)
})

test('neutral E2E requires external technical credentials and never hardcodes secrets', () => {
  assert.match(harness, /process\.env\.SKPE_E2E_EMAIL/)
  assert.match(harness, /process\.env\.SKPE_E2E_PASSWORD/)
  assert.match(harness, /Credencial técnica E2E ausente/)
  assert.doesNotMatch(harness, /service_role/i)
  assert.doesNotMatch(harness, /password:\s*['"][^'"]+['"]/i)
})

test('neutral E2E proves authenticated membership and fail-closed journey dependency', () => {
  assert.match(harness, /signInWithPassword/)
  assert.match(harness, /organization_memberships/)
  assert.match(harness, /get_skpe_journey_temporal_read_model/)
  assert.match(harness, /set_skpe_journey_item_status/)
  assert.match(harness, /PEM-02\.04/)
  assert.match(harness, /PEM-02\.03/)
  assert.match(harness, /Fail-closed comprovado/)
})

test('neutral E2E is exposed as an explicit npm command', () => {
  assert.match(packageJson, /"test:e2e:neutral": "node scripts\/validate-neutral-runtime\.mjs"/)
})
