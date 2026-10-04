import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004050500_harden_pem02_sequential_dependencies.sql', import.meta.url),
  'utf8',
)

test('PEM-02 enforces the full sequential dependency chain', () => {
  assert.match(migration, /PEM-02\.02'[\s\S]*PEM-02\.01/)
  assert.match(migration, /PEM-02\.03'[\s\S]*PEM-02\.02/)
  assert.match(migration, /PEM-02\.04'[\s\S]*PEM-02\.03/)
  assert.match(migration, /PEM-02\.05'[\s\S]*PEM-02\.04/)
  assert.match(migration, /PEM-02\.GATE'[\s\S]*PEM-02\.05/)
})

test('journey transition guard fails closed on unmet dependency', () => {
  assert.match(migration, /before update of status,progress/)
  assert.match(migration, /new\.status not in \('in_progress','pending_validation','completed'\)/)
  assert.match(migration, /jsonb_array_elements\(new\.metadata->'unblock_dependencies'\)/)
  assert.match(migration, /prerequisite_status is distinct from dependency->>'required_status'/)
  assert.match(migration, /nao pode assumir status/)
})

test('dependency hardening does not complete or approve journey items', () => {
  assert.doesNotMatch(migration, /set\s+status\s*=\s*'completed'/i)
  assert.doesNotMatch(migration, /validation_status\s*=\s*'approved'/i)
})
