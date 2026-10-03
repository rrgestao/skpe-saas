import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003040500_add_import_mapping_coverage.sql', import.meta.url),
  'utf8',
)
const staging = readFileSync(
  new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url),
  'utf8',
)

test('mapping coverage is read-only and derived from active governed mappings', () => {
  assert.match(migration, /skpe_get_import_mapping_coverage/)
  assert.match(migration, /skpe_incorporation_mapping_catalogs/)
  assert.match(migration, /skpe_incorporation_mapping_versions/)
  assert.match(migration, /v\.version_status = 'active'/)
  assert.match(migration, /c\.status = 'active'/)
  assert.match(migration, /'materializesStrategicData', false/)
  assert.doesNotMatch(migration, /insert into public\.skpe_import_incorporation_requests/i)
  assert.doesNotMatch(migration, /update public\.skpe_import_records/i)
})

test('staging distinguishes mapping coverage from definitive-load readiness', () => {
  assert.match(staging, /Cobertura do contrato de incorporação/)
  assert.match(staging, /registros já possuem mapping governado/)
  assert.match(staging, /Tipos cobertos/)
  assert.match(staging, /Tipos pendentes/)
  assert.match(staging, /A cobertura indica existência de contrato ativo/)
  assert.match(staging, /Ela não significa que o destino já foi resolvido/)
  assert.match(staging, /skpe_get_import_mapping_coverage/)
})
