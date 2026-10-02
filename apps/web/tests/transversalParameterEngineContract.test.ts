import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const root = join(testDir, '../../..')
const engine = readFileSync(
  join(root, 'supabase/migrations/20260916182000_establish_sparks_transversal_parameter_engine.sql'),
  'utf8',
)
const consumer = readFileSync(
  join(root, 'supabase/migrations/20260916183500_parameterize_skpe_journey_temporal_policy.sql'),
  'utf8',
)

test('motor transversal preserva precedencia de escopos', () => {
  assert.match(engine, /when 'project' then 50/)
  assert.match(engine, /when 'organization_module' then 40/)
  assert.match(engine, /when 'organization' then 30/)
  assert.match(engine, /when 'module' then 20/)
  assert.match(engine, /when 'platform' then 10/)
})

test('defaults temporais do SK-PE ficam no catalogo transversal', () => {
  assert.match(engine, /SKPE\.JOURNEY\.DURATION_MODE/)
  assert.match(engine, /business_days/)
  assert.match(engine, /calendar_days/)
  assert.match(engine, /SKPE\.JOURNEY\.STANDARD_DURATION[\s\S]*'90'::jsonb/)
  assert.match(engine, /SKPE\.JOURNEY\.ACCELERATED_DURATION[\s\S]*'45'::jsonb/)
  assert.match(engine, /SKPE\.JOURNEY\.POST_DELIVERY_FOLLOWUP[\s\S]*'90'::jsonb/)
})

test('overrides organizacionais exigem autoridade da organizacao', () => {
  assert.match(engine, /can_manage_organization\(p_organization_id\)/)
  assert.match(engine, /is_platform_super_admin\(\)/)
  assert.match(engine, /change_reason/)
  assert.match(engine, /sparks_parameter_audit/)
})

test('Jornada consome parametro efetivo e registra snapshot', () => {
  assert.match(consumer, /get_sparks_effective_parameter/)
  assert.match(consumer, /sparks_date_at_offset/)
  assert.match(consumer, /parameter_snapshot/)
  assert.match(consumer, /sparks_parameter_engine/)
})

test('Horizonte Estrategico permanece separado da janela parametrizada', () => {
  assert.match(consumer, /planning_horizon_start_year = target_horizon_start_year/)
  assert.match(consumer, /planning_horizon_end_year = target_horizon_end_year/)
  assert.match(consumer, /valid_until = make_date\(target_horizon_end_year, 12, 31\)/)
  assert.match(consumer, /target_end_date = journey_target_end_date/)
})

test('identidade visual nao e duplicada no motor de parametros', () => {
  assert.doesNotMatch(engine, /logo_url|primary_color|secondary_color|accent_color/)
  assert.match(engine, /Identidade visual permanece em sua autoridade propria/)
})

test('Administração da Organização expõe parâmetros herdáveis sem duplicar identidade visual', () => {
  const cockpit = readFileSync(join(testDir, '../src/modules/skpe/SkpeCockpit.tsx'), 'utf8')
  const panel = readFileSync(join(testDir, '../src/modules/skpe/components/OrganizationParametersPanel.tsx'), 'utf8')
  assert.match(cockpit, /OrganizationVisualIdentityCard/)
  assert.match(cockpit, /OrganizationParametersPanel/)
  assert.match(panel, /list_sparks_effective_parameters/)
  assert.match(panel, /set_sparks_parameter_value/)
  assert.match(panel, /clear_sparks_parameter_value/)
  assert.match(panel, /Restaurar padrão SPARKs/)
  assert.match(panel, /Origem efetiva:/)
})
