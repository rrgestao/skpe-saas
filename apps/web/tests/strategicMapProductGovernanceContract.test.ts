import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const positioning = readFileSync(
  join(testDir, '../src/modules/skpe/features/strategy/StrategicPositioningSection.tsx'),
  'utf8',
)
const migration = readFileSync(
  join(testDir, '../../../supabase/migrations/20260913130233_govern_strategic_map_product_rules.sql'),
  'utf8',
)

test('Posicionamento Estratégico exige Formulação explícita e não mistura versões', () => {
  assert.match(positioning, /useSkpeWorkspace/)
  assert.match(positioning, /workspace\.route\.formulationId/)
  assert.match(positioning, /\.eq\('formulation_id', formulationId\)/)
  assert.match(positioning, /Selecione uma Formulação Estratégica/)
})

test('Regra de Ouro torna Tema sem OE bloqueante', () => {
  assert.match(migration, /THEME_WITHOUT_OBJECTIVES/)
  assert.match(migration, /'severity', 'blocking'/)
  assert.match(migration, /Todo Tema Estratégico ativo deve possuir ao menos um Objetivo Estratégico ativo/)
})

test('OE exige Tema, responsável e horizonte para validação', () => {
  assert.match(migration, /OBJECTIVE_WITHOUT_THEME/)
  assert.match(migration, /OBJECTIVE_WITHOUT_OWNER/)
  assert.match(migration, /OBJECTIVE_WITHOUT_HORIZON/)
  assert.match(migration, /'ownerRequired', true/)
  assert.match(migration, /'horizonRequired', true/)
})

test('ME validado gera versão oficial imutável antes de nova revisão', () => {
  assert.match(migration, /skpe_strategic_map_versions/)
  assert.match(migration, /capture_skpe_strategic_map_version/)
  assert.match(migration, /begin_revision/)
  assert.match(migration, /revisionOfOfficialVersionId/)
  assert.match(migration, /strategic_map_official_version_captured/)
  assert.match(migration, /strategic_map_revision_started/)
})

test('ME validado não aceita retorno destrutivo para ajustes', () => {
  assert.match(migration, /return_for_adjustments/)
  assert.match(migration, /Use begin_revision para preservar a versão oficial/)
})

test('configuração legada não pode tornar Tema ou responsável opcionais', () => {
  assert.match(migration, /Tema principal é obrigatório no Mapa Estratégico SPARKs PE/)
  assert.match(migration, /Responsável de Objetivo Estratégico é obrigatório no SPARKs PE/)
  assert.match(migration, /configure_skpe_strategic_map_legacy_20260913/)
})
