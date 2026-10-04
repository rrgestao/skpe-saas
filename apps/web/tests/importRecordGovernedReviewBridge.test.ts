import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004022550_confirm_import_record_from_governed_review.sql', import.meta.url),
  'utf8',
)

test('record review bridge requires governed item completion', () => {
  assert.match(migration, /skpe_confirm_import_record_from_governed_review/)
  assert.match(migration, /validation_state not in \('validated','validated_with_reservations'\)/)
  assert.match(migration, /ImportRecord não pode ser confirmado enquanto houver itens pendentes de validação/)
  assert.match(migration, /ImportRecord não pode ser confirmado enquanto houver itens rejeitados/)
  assert.match(migration, /ImportRecord não pode ser confirmado enquanto houver itens inferidos/)
})

test('record review bridge is auditable and non-materializing', () => {
  assert.match(migration, /skpe_import_record_review_events/)
  assert.match(migration, /governed_item_review_bridge/)
  assert.match(migration, /business_decision_created',false/)
  assert.match(migration, /materialization_requested',false/)
  assert.match(migration, /grant execute on function public\.skpe_confirm_import_record_from_governed_review[\s\S]*to service_role/)
})
