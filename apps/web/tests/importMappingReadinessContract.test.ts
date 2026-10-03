import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003021500_govern_import_mapping_readiness.sql', import.meta.url),
  'utf8',
)
const staging = readFileSync(
  new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url),
  'utf8',
)

test('mapping readiness blocks definitive load while canonical targets are missing', () => {
  assert.match(migration, /TARGET_MAPPING_COMPLETE/)
  assert.match(migration, /target_table is null/)
  assert.match(migration, /proposed_action in \('insert','update'\)/)
  assert.match(migration, /and v_unmapped = 0/)
  assert.match(migration, /'unmappedEntities'/)
  assert.match(migration, /'mappingReadinessVersion','1\.0\.0'/)
  assert.match(migration, /'IMPORT_MAPPING_READINESS_ASSESSED'/)
  assert.match(migration, /'definitiveLoadExecuted',false/)
})

test('staging UI exposes the mapping gap without offering definitive load', () => {
  assert.match(staging, /TARGET_MAPPING_COMPLETE: 'Destinos canônicos definidos'/)
  assert.match(staging, /Mapeamento para o modelo atual pendente/)
  assert.match(staging, /A carga definitiva permanece bloqueada/)
  assert.match(staging, /unmappedEntities/)
  assert.doesNotMatch(staging, /Executar carga definitiva/)
})
