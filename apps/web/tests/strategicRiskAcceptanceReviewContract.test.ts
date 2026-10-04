import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004020850_preserve_risk_acceptance_review_contract.sql', import.meta.url),
  'utf8',
)

test('risk review contract preserves explicit acceptance and routing facts', () => {
  assert.match(migration, /'aceite_do_risco','risk_acceptance'/)
  assert.match(migration, /'evidencia_do_aceite','acceptance_evidence'/)
  assert.match(migration, /'reconhecimento_pela_direcao','management_recognition'/)
  assert.match(migration, /'ciclo_de_implementacao','implementation_cycle'/)
  assert.match(migration, /'destino_no_portfolio','portfolio_destination'/)
})

test('risk acceptance review contract stays non-inferential and does not fabricate evidence', () => {
  assert.match(migration, /'semantic_inference',false/)
  assert.match(migration, /'risk_acceptance_policy','preserve_explicit_source_fact'/)
  assert.match(migration, /'formal_evidence_policy','do_not_fabricate'/)
})

test('risk review contract rotates the active mapping version safely', () => {
  assert.match(migration, /version_status='superseded'/)
  assert.match(migration, /supersedes_version_id/)
  assert.match(migration, /current_version=v_new_number/)
  assert.match(migration, /copied_for_risk_acceptance_review_contract/)
})
