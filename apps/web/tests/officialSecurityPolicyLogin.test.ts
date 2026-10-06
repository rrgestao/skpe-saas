import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const app = readFileSync(
  new URL('../src/App.tsx', import.meta.url),
  'utf8',
)

test('login exposes the official SPARKOOP cyber and information security policy', () => {
  assert.match(app, /Política de Segurança Cibernética e da Informação/)
  assert.match(app, /POL-001/)
  assert.match(app, /SECURITY_POLICY_REVISION = '00'/)
  assert.match(app, /SECURITY_POLICY_DATE = '08\/01\/2025'/)
  assert.match(app, /Índice de Incidentes Cibernéticos e da Informação/)
  assert.match(app, /Atas das Assembleias do Conselho de Administração/)
})

test('official policy is presented without exposing the internal document header as the primary UI', () => {
  assert.match(app, /Documento oficial SPARKOOP/)
  assert.match(app, /Controle documental/)
  assert.match(app, /Elaborador/)
  assert.match(app, /Homologador/)
})

test('account request records acknowledgement instead of fabricated privacy consent', () => {
  assert.match(app, /Li e estou ciente da/)
  assert.match(app, /submit_platform_account_request_v2/)
  assert.match(app, /p_policy_code: SECURITY_POLICY_CODE/)
  assert.doesNotMatch(app, /Li e concordo com a .*Política de Privacidade/)
  assert.doesNotMatch(app, /Política de Privacidade da Plataforma SPARKs/)
})
