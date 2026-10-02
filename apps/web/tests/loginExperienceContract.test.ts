import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const app = readFileSync(join(testDir, '../src/App.tsx'), 'utf8')
const css = readFileSync(join(testDir, '../src/App.css'), 'utf8')

test('login SPARKs usa experiência split premium sem perder autenticação existente', () => {
  assert.match(app, /sparks-login-shell/)
  assert.match(app, /Unifique governança, estratégia e execução/)
  assert.match(app, /Entrar na conta/)
  assert.match(app, /Acesse o ambiente da sua organização/)
  assert.match(app, /Esqueceu\?/)
  assert.match(app, /handleLogin/)
  assert.match(app, /openForgotPassword/)
  assert.match(css, /grid-template-columns: minmax\(0, 1\.05fr\) minmax\(520px, 0\.95fr\)/)
  assert.match(css, /background: linear-gradient\(135deg, #ff671c, #ff4e0b\)/)
})