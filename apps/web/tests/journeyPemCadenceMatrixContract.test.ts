import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const root = join(testDir, '../../..')
const migration = readFileSync(
  join(root, 'supabase/migrations/20260916201500_govern_skpe_pem_cadence_matrix_v1.sql'),
  'utf8',
)
const panel = readFileSync(
  join(testDir, '../src/modules/skpe/components/OrganizationParametersPanel.tsx'),
  'utf8',
)

test('matriz default SPARKs PE distribui 90 dias entre PEM-00 e PEM-04', () => {
  assert.match(migration, /PEM00_DURATION[\s\S]*'10'::jsonb/)
  assert.match(migration, /PEM01_DURATION[\s\S]*'20'::jsonb/)
  assert.match(migration, /PEM02_DURATION[\s\S]*'25'::jsonb/)
  assert.match(migration, /PEM03_DURATION[\s\S]*'20'::jsonb/)
  assert.match(migration, /PEM04_DURATION[\s\S]*'15'::jsonb/)
  assert.match(migration, /implementation_total/)
})

test('PEM-05 permanece acompanhamento pos-entrega', () => {
  assert.match(migration, /post_delivery_continuous/)
  assert.match(migration, /SKPE\.JOURNEY\.POST_DELIVERY_FOLLOWUP/)
  assert.match(migration, /when 'PEM-05' then v_segment_start:=v_impl_duration/)
})

test('linha de base usa janelas governadas por Megafase e mantem fases provisórias', () => {
  assert.match(migration, /macrophase_governed_leaf_provisional/)
  assert.match(migration, /pem_configured_phase_pending/)
  assert.doesNotMatch(migration, /default_duration_days = c\.duration_days/)
})

test('Administracao da Organizacao expoe a matriz e o total efetivo', () => {
  assert.match(panel, /Preparação e Enquadramento · Etapas/)
  assert.match(panel, /Implementação e Mobilização · Etapas/)
  assert.match(panel, /implementationCadenceTotal/)
  assert.match(panel, /Total efetivo atual:/)
})

const phaseMigration = readFileSync(
  join(root, 'supabase/migrations/20260916203500_govern_skpe_pem00_pem01_phase_cadence_v1.sql'),
  'utf8',
)

test('PEM-00 e PEM-01 passam a ter cadencia governada por Fase', () => {
  assert.match(phaseMigration, /PEM00\.01_DURATION[\s\S]*'1'::jsonb/)
  assert.match(phaseMigration, /PEM00\.05_DURATION[\s\S]*'2'::jsonb/)
  assert.match(phaseMigration, /PEM00\.07_DURATION[\s\S]*'2'::jsonb/)
  assert.match(phaseMigration, /PEM01\.03_DURATION[\s\S]*'4'::jsonb/)
  assert.match(phaseMigration, /PEM01\.05_DURATION[\s\S]*'4'::jsonb/)
  assert.match(phaseMigration, /pem00_total/)
  assert.match(phaseMigration, /pem01_total/)
})

test('Gates sao marcos e nao consomem duracao propria', () => {
  assert.match(phaseMigration, /Gate posicionado no fechamento da janela governada; nao consome duracao propria/)
  assert.match(phaseMigration, /governed_milestone/)
})

test('Administracao expoe Fases de PEM-00 e PEM-01 e calcula totais derivados', () => {
  assert.match(panel, /Abertura, Mandato e Escopo/)
  assert.match(panel, /SWOT e TOWS/)
  assert.match(panel, /pem00PhaseTotal/)
  assert.match(panel, /pem01PhaseTotal/)
})
const pem02Migration = readFileSync(
  join(root, 'supabase/migrations/20260916205000_govern_skpe_pem02_phase_cadence_v1.sql'),
  'utf8',
)

test('PEM-02 passa a ter cadencia governada por Fase', () => {
  assert.match(pem02Migration, /PEM02\.01_DURATION[\s\S]*'2'::jsonb/)
  assert.match(pem02Migration, /PEM02\.02_DURATION[\s\S]*'5'::jsonb/)
  assert.match(pem02Migration, /PEM02\.03_DURATION[\s\S]*'5'::jsonb/)
  assert.match(pem02Migration, /PEM02\.04_DURATION[\s\S]*'7'::jsonb/)
  assert.match(pem02Migration, /PEM02\.05_DURATION[\s\S]*'6'::jsonb/)
  assert.match(pem02Migration, /pem02_effective_total/)
})

test('Linha de Base posiciona Fases da PEM-02 e Gate no fechamento', () => {
  assert.match(pem02Migration, /v_item\.root_code='PEM-02'/)
  assert.match(pem02Migration, /when 'PEM-02' then v_p0\+v_p1\+v_p2-1/)
  assert.match(pem02Migration, /pem00_pem01_pem02_phase_configured/)
})

test('Administracao expoe Fases e total derivado da PEM-02', () => {
  assert.match(panel, /Objetivos Estratégicos/)
  assert.match(panel, /pem02PhaseTotal/)
  assert.doesNotMatch(panel, /PEM02_DURATION','PEM-02 · Formulação Estratégica/)
})
const pem03Migration = readFileSync(
  join(root, 'supabase/migrations/20260916210500_govern_skpe_pem03_phase_cadence_v1.sql'),
  'utf8',
)

test('PEM-03 passa a ter cadencia governada por Fase', () => {
  assert.match(pem03Migration, /PEM03\.01_DURATION[\s\S]*'4'::jsonb/)
  assert.match(pem03Migration, /PEM03\.02_DURATION[\s\S]*'6'::jsonb/)
  assert.match(pem03Migration, /PEM03\.03_DURATION[\s\S]*'6'::jsonb/)
  assert.match(pem03Migration, /PEM03\.04_DURATION[\s\S]*'4'::jsonb/)
  assert.match(pem03Migration, /pem03_total/)
})

test('Linha de Base posiciona Fases da PEM-03 e Gate no fechamento', () => {
  assert.match(pem03Migration, /root_code='PEM-03'/)
  assert.match(pem03Migration, /PEM-03\.04/)
  assert.match(pem03Migration, /governed_milestone/)
})

const pem04Migration = readFileSync(
  join(root, 'supabase/migrations/20260916212000_govern_skpe_pem04_phase_cadence_v1.sql'),
  'utf8',
)

test('PEM-04 passa a ter cadencia governada por Fase', () => {
  assert.match(pem04Migration, /PEM04\.01_DURATION[\s\S]*'5'::jsonb/)
  assert.match(pem04Migration, /PEM04\.02_DURATION[\s\S]*'3'::jsonb/)
  assert.match(pem04Migration, /PEM04\.03_DURATION[\s\S]*'4'::jsonb/)
  assert.match(pem04Migration, /PEM04\.04_DURATION[\s\S]*'3'::jsonb/)
  assert.match(pem04Migration, /pem04_total/)
})

test('Linha de Base posiciona Fases da PEM-04 e Gate no fechamento', () => {
  assert.match(pem04Migration, /root_code='PEM-04'/)
  assert.match(pem04Migration, /PEM-04\.04/)
  assert.match(pem04Migration, /governed_milestone/)
})

const pem05Migration = readFileSync(
  join(root, 'supabase/migrations/20260916213500_govern_skpe_pem05_cycle_semantics_v1.sql'),
  'utf8',
)

test('PEM-05 permanece ciclo concorrente pos-entrega', () => {
  assert.match(pem05Migration, /post_delivery_cycle_phase/)
  assert.match(pem05Migration, /continuous_learning/)
  assert.match(pem05Migration, /recurring_review/)
  assert.match(pem05Migration, /event_driven/)
  assert.match(pem05Migration, /frequency_status','pending_governance_decision/)
})

test('Gate da PEM-05 encerra o ciclo sem criar duracao adicional', () => {
  assert.match(pem05Migration, /post_delivery_cycle_gate/)
  assert.match(pem05Migration, /cycle_close_milestone/)
  assert.match(pem05Migration, /POST_DELIVERY_FOLLOWUP/)
})
