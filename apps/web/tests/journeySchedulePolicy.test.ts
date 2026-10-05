import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261005023000_align_journey_schedule_policy_and_legacy_reconciliation.sql', import.meta.url),
  'utf8',
)

test('SPARKs fallback schedule uses 45-day usual delivery, 90-day extension and 90-day follow-up', () => {
  assert.match(migration, /SKPE\.JOURNEY\.STANDARD_DURATION/)
  assert.match(migration, /default_value = '45'::jsonb/)
  assert.match(migration, /SKPE\.JOURNEY\.EXTENDED_DURATION/)
  assert.match(migration, /'90'::jsonb/)
  assert.match(migration, /SKPE\.JOURNEY\.POST_DELIVERY_FOLLOWUP/)
  assert.match(migration, /usual_delivery_business_days',45/)
  assert.match(migration, /extended_delivery_business_days',90/)
  assert.match(migration, /post_delivery_followup_business_days',90/)
})

test('contract or Service Order dates explicitly take precedence over fallback', () => {
  assert.match(migration, /contract_or_service_order_precedence/)
  assert.match(migration, /Ordem de Servico\/contrato prevalece/)
})

test('legacy projects preserve known actual dates and propose only the remaining path', () => {
  assert.match(migration, /legacy_actual_reconciliation/)
  assert.match(migration, /i\.status='completed'/)
  assert.match(migration, /coalesce\(i\.actual_start_date,i\.actual_end_date\)/)
  assert.match(migration, /proposal_status','proposed_for_validation/)
})

test('PEM-02 validation copy states ratification is required before strategic deployment', () => {
  assert.match(migration, /Ratificar a Formulação Estratégica e o Plano de Evolução antes de iniciar o Desdobramento Estratégico/)
})
