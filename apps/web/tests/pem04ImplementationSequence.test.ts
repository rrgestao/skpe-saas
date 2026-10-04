import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004075500_reconcile_pem04_implementation_sequence.sql', import.meta.url),
  'utf8',
)

test('PEM-04 starts only after PEM-03.GATE and follows a sequential implementation chain', () => {
  assert.match(migration, /PEM-04'[\s\S]*PEM-03\.GATE/)
  assert.match(migration, /PEM-04\.01'[\s\S]*PEM-03\.GATE/)
  assert.match(migration, /PEM-04\.02'[\s\S]*PEM-04\.01/)
  assert.match(migration, /PEM-04\.03'[\s\S]*PEM-04\.02/)
  assert.match(migration, /PEM-04\.04'[\s\S]*PEM-04\.03/)
  assert.match(migration, /PEM-04\.GATE'[\s\S]*PEM-04\.04/)
})

test('PEM-04.01 activates the approved portfolio instead of recreating it', () => {
  assert.match(migration, /Ativação do Plano de Implementação/)
  assert.match(migration, /sem redefinir o portfólio/)
  assert.match(migration, /Portfólio estratégico aprovado ativado para execução/)
})

test('PEM-04 reconciliation changes contracts without advancing business state', () => {
  assert.doesNotMatch(migration, /set\s+status\s*=\s*'in_progress'/i)
  assert.doesNotMatch(migration, /set\s+status\s*=\s*'completed'/i)
  assert.doesNotMatch(migration, /validation_status\s*=\s*'approved'/i)
})
