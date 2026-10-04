import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004061000_reconcile_pem03_deployment_sequence.sql', import.meta.url),
  'utf8',
)

test('PEM-03 starts with OKR deployment instead of duplicating the strategic map', () => {
  assert.match(migration, /when 'PEM-03\.01' then 'Desdobramento em OKRs'/)
  assert.doesNotMatch(migration, /when 'PEM-03\.01' then 'Mapa Estratégico'/)
  assert.match(migration, /OKRs aprovados e vinculados aos Objetivos Estratégicos/)
})

test('PEM-03 follows the governed deployment sequence after PEM-02.GATE', () => {
  assert.match(migration, /when 'PEM-03' then '\[\{"code":"PEM-02\.GATE","required_status":"completed"\}\]'/)
  assert.match(migration, /when 'PEM-03\.01' then '\[\{"code":"PEM-02\.GATE","required_status":"completed"\}\]'/)
  assert.match(migration, /when 'PEM-03\.02' then '\[\{"code":"PEM-03\.01","required_status":"completed"\}\]'/)
  assert.match(migration, /when 'PEM-03\.03' then '\[\{"code":"PEM-03\.02","required_status":"completed"\}\]'/)
  assert.match(migration, /when 'PEM-03\.04' then '\[\{"code":"PEM-03\.03","required_status":"completed"\}\]'/)
  assert.match(migration, /when 'PEM-03\.GATE' then '\[\{"code":"PEM-03\.04","required_status":"completed"\}\]'/)
})

test('PEM-03 reconciliation changes methodology contracts without advancing business state', () => {
  assert.doesNotMatch(migration, /set\s+status\s*=\s*'completed'/i)
  assert.doesNotMatch(migration, /validation_status\s*=\s*'approved'/i)
})
