import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const source = readFileSync(
  new URL(
    '../src/modules/platform-admin/PlatformAdmin.tsx',
    import.meta.url,
  ),
  'utf8',
)

test('expõe Papéis na Organização como categoria distinta de perfis de acesso', () => {
  assert.match(source, /Papéis na Organização/)
  assert.match(
    source,
    /sem misturá-los com cargo\/função, administrador local ou perfis de acesso/,
  )
})

test('carrega papéis organizacionais pela projeção administrativa transversal', () => {
  assert.match(source, /get_platform_admin_user_organizational_roles/)
  assert.match(source, /userDetailTab === 'organizationalRoles'/)
})

test('usa o contrato canônico de mutation da Administração da Plataforma', () => {
  assert.match(source, /set_platform_admin_user_organizational_role/)
  assert.match(source, /target_organizational_role_id: role\.role_id/)
  assert.match(source, /input_assigned: nextAssigned/)
  assert.match(source, /input_reason: reason\.trim\(\)/)
})

test('permite atribuir e revogar sem misturar papéis com perfis', () => {
  assert.match(source, /Atribuir papel/)
  assert.match(source, /Revogar papel/)
  assert.match(source, /Gerenciar papéis na Organização/)
  assert.match(source, /Perfis globais/)
  assert.match(source, /Perfis por módulo/)
})

test('solicita período quando o papel organizacional exige mandato', () => {
  assert.match(source, /role\.requires_mandate/)
  assert.match(source, /data de inicio \(AAAA-MM-DD\)/)
  assert.match(source, /input_mandate_start_date: mandateStartDate/)
  assert.match(source, /input_mandate_end_date: mandateEndDate/)
})