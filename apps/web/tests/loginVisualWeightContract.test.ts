import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const css = readFileSync(join(testDir, '../src/App.css'), 'utf8')

test('login aproxima escala visual do NEXUS sem perder conteúdo adicional do SPARKs', () => {
  assert.match(css, /LOGIN NEXUS SCALE ALIGNMENT V3/)
  assert.match(css, /width: min\(410px, calc\(100% - 3rem\)\)/)
  assert.match(css, /font-size: clamp\(2rem, 3\.15vw, 3\.45rem\)/)
  assert.match(css, /\.sparks-login-brand-lockup strong \{ font-size: 1\.48rem; font-weight: 650; \}/)
  assert.match(css, /\.sparks-login-card \.login-title \{ font-size: clamp\(1\.45rem, 2vw, 1\.7rem\); font-weight: 640; \}/)
  assert.match(css, /\.sparks-login-card input \{ min-height: 44px; font-size: 0\.88rem; \}/)
})
