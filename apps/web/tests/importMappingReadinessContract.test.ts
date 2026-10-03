import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003045000_align_import_readiness_to_mapping_catalog.sql', import.meta.url),
  'utf8',
)
const staging = readFileSync(
  new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url),
  'utf8',
)

test('mapping readiness follows active governed incorporation mappings', () => {
  assert.match(migration, /TARGET_MAPPING_COMPLETE/)
  assert.match(migration, /skpe_incorporation_mapping_catalogs/)
  assert.match(migration, /skpe_incorporation_mapping_versions/)
  assert.match(migration, /v\.version_status = 'active'/)
  assert.match(migration, /v\.version_number = c\.current_version/)
  assert.match(migration, /proposed_action in \('insert','update'\)/)
  assert.match(migration, /and v_unmapped = 0/)
  assert.match(migration, /'unmappedEntities'/)
  assert.match(migration, /'mappingAuthority', 'active_incorporation_mapping_catalog'/)
  assert.match(migration, /'mappingReadinessVersion','2\.0\.0'/)
  assert.match(migration, /'IMPORT_MAPPING_READINESS_ASSESSED'/)
  assert.match(migration, /'definitiveLoadExecuted',false/)
  assert.doesNotMatch(migration, /target_table is null/)
})

test('staging UI exposes the mapping gap without offering definitive load', () => {
  assert.match(staging, /TARGET_MAPPING_COMPLETE: 'Contratos de incorporação definidos'/)
  assert.match(staging, /Mapeamento para o modelo atual pendente/)
  assert.match(staging, /A carga definitiva permanece bloqueada/)
  assert.match(staging, /unmappedEntities/)
  assert.doesNotMatch(staging, /Executar carga definitiva/)
})
