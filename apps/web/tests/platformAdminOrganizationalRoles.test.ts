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
    /Cargo\/função, administrador local e perfis de acesso permanecem conceitos distintos/,
  )
})

test('carrega papéis organizacionais pela projeção administrativa transversal', () => {
  assert.match(source, /get_platform_admin_user_organizational_roles/)
  assert.match(source, /userDetailTab === 'organizationalRoles'/)
})

test('não mistura papéis organizacionais com perfis globais ou modulares', () => {
  assert.match(source, /Perfis globais/)
  assert.match(source, /Perfis por módulo/)
  assert.match(source, /Papéis na Organização/)
})
