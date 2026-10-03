import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const cockpit = readFileSync(new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url), 'utf8')
const portability = readFileSync(new URL('../src/modules/portability/PortabilityAdmin.tsx', import.meta.url), 'utf8')
const staging = readFileSync(new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url), 'utf8')
const migration = readFileSync(
  new URL('../../../supabase/migrations/20261003184500_enable_organization_admin_portability_layouts.sql', import.meta.url),
  'utf8',
)

test('organization admin can navigate to organization-scoped import and export', () => {
  assert.match(cockpit, /setActiveArea\('portability'\)/)
  assert.match(cockpit, /Importação e Exportação/)
  assert.match(cockpit, /canManagePortability=\{canManageGovernance\}/)
  assert.match(cockpit, /fixedOrganizationId=\{organizationId\}/)
})

test('layout catalog is available to authenticated users while organization writes stay governed elsewhere', () => {
  assert.match(migration, /auth\.uid\(\) is not null/)
  assert.match(migration, /grant execute on function public\.get_portability_layouts\(text, text\) to authenticated/)
  assert.doesNotMatch(migration, /create_portability_package/)
})

test('organization-scoped portability uses business language for historical review', () => {
  assert.match(portability, /Dados da organização/)
  assert.match(portability, /Importe dados históricos para revisão controlada/)
  assert.match(staging, /Dados históricos do Diagnóstico — revisão humana/)
  assert.match(staging, /Preparar dados históricos para revisão/)
  assert.match(staging, /incorporação ao planejamento atual/)
  assert.doesNotMatch(staging, /Preparar pacote completo/)
})
