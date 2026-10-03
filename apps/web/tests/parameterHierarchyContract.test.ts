import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const cockpit = readFileSync(new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url), 'utf8')
const panel = readFileSync(new URL('../src/modules/skpe/components/OrganizationParametersPanel.tsx', import.meta.url), 'utf8')
const platformAdmin = readFileSync(new URL('../src/modules/platform-admin/PlatformAdmin.tsx', import.meta.url), 'utf8')
const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003205000_align_skpe_parameter_authority.sql', import.meta.url),
  'utf8',
)

test('institutional registration separates information and SK-PE parameters into tabs', () => {
  assert.match(cockpit, /Informações institucionais/)
  assert.match(cockpit, /Parâmetros do SK-PE/)
  assert.match(cockpit, /activeInstitutionalTab === 'parameters'/)
  assert.match(cockpit, /canManageParameters=\{canManageGovernance\}/)
  assert.match(cockpit, /<OrganizationParametersPanel[\s\S]{0,180}canManage=\{canManageParameters\}[\s\S]{0,180}scopeType="organization_module"/)
})

test('parameter panel supports SPARKs module defaults and organization-module overrides', () => {
  assert.match(panel, /scopeType\?: 'module' \| 'organization_module'/)
  assert.match(panel, /scopeType = 'organization_module'/)
  assert.match(panel, /isModuleDefault \? null : organizationId/)
  assert.match(panel, /p_scope_type: scopeType/)
  assert.match(panel, /Padrão SPARKs · SK-PE/)
  assert.match(panel, /Parâmetros da Organização · SK-PE/)
  assert.match(panel, /Restaurar padrão do SK-PE/)
})

test('platform administration exposes SK-PE global defaults', () => {
  assert.match(platformAdmin, /\| 'skpe-parameters'/)
  assert.match(platformAdmin, /'skpe-parameters': 'Parâmetros do SK-PE'/)
  assert.match(platformAdmin, /openAdminTab\('skpe-parameters'\)/)
  assert.match(platformAdmin, /<OrganizationParametersPanel canManage scopeType="module" \/>/)
})

test('organization-module parameter authority accepts organization admin or SK-PE module governance authority', () => {
  assert.match(migration, /p_scope_type = 'organization_module' and p_module_code = 'SK-PE'/)
  assert.match(migration, /can_manage_skpe_governance\(p_organization_id\)/)
  assert.match(migration, /p_scope_type in \('platform','module'\)/)
  assert.match(migration, /is_platform_super_admin\(\)/)
})
