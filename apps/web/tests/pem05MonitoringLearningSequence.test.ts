import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004194500_reconcile_pem05_monitoring_learning_sequence.sql', import.meta.url),
  'utf8',
)

test('PEM-05 starts only after PEM-04.GATE and follows a sequential monitoring-learning chain', () => {
  assert.match(migration, /PEM-05'[\s\S]*PEM-04\.GATE/)
  assert.match(migration, /PEM-05\.01'[\s\S]*PEM-04\.GATE/)
  assert.match(migration, /PEM-05\.02'[\s\S]*PEM-05\.01/)
  assert.match(migration, /PEM-05\.03'[\s\S]*PEM-05\.02/)
  assert.match(migration, /PEM-05\.04'[\s\S]*PEM-05\.03/)
  assert.match(migration, /PEM-05\.GATE'[\s\S]*PEM-05\.04/)
})

test('PEM-05.01 operates the validated FE-08 monitoring governance instead of recreating it', () => {
  assert.match(migration, /Operação da Rotina de Monitoramento/)
  assert.match(migration, /pacote FE-08 validado/)
  assert.match(migration, /Atualização Estratégica Governada/)
  assert.match(migration, /sem edição silenciosa da estratégia aprovada/)
})

test('PEM-05 reconciliation changes contracts without advancing business state', () => {
  assert.doesNotMatch(migration, /set\s+status\s*=\s*'in_progress'/i)
  assert.doesNotMatch(migration, /set\s+status\s*=\s*'completed'/i)
  assert.doesNotMatch(migration, /validation_status\s*=\s*'approved'/i)
})

