import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005010500_allow_conceptual_cycle_temporality_guard.sql', import.meta.url),
  'utf8',
)

test('conceptual cycles bypass temporal overlap checks until dates exist', () => {
  assert.match(migration, /if new\.period_start is null and new\.period_end is null then/)
  assert.match(migration, /return new/)
})

test('dated cycles still enforce horizon and overlap protection', () => {
  assert.match(migration, /deve permanecer dentro do período estratégico do Horizonte/)
  assert.match(migration, /c\.period_start is not null/)
  assert.match(migration, /daterange\(c\.period_start,c\.period_end,'\[\]'\)/)
  assert.match(migration, /não podem se sobrepor/)
})
