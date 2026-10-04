import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004023527_reconcile_existing_diagnostic_materialization.sql', import.meta.url),
  'utf8',
)

test('diagnostic reconciliation reuses existing canonical target', () => {
  assert.match(migration, /resolution_mode <> 'existing_entity'/)
  assert.match(migration, /existing_target_reused',true/)
  assert.match(migration, /business_content_updated',false/)
  assert.match(migration, /reconciliation_only',true/)
})

test('diagnostic reconciliation verifies decision, items and project scope', () => {
  assert.match(migration, /decision_outcome not in \('approved','approved_with_reservations'\)/)
  assert.match(migration, /validation_state not in \('validated','validated_with_reservations'\)/)
  assert.match(migration, /item_status <> 'approved'/)
  assert.match(migration, /requires_human_review=true/)
  assert.match(migration, /extraction_mode='inferred'/)
  assert.match(migration, /t\.organization_id=v_request\.organization_id/)
  assert.match(migration, /t\.project_id=v_request\.project_id/)
})

test('diagnostic reconciliation finalizes without invoking create-new materializers', () => {
  assert.match(migration, /skpe_finalize_governed_import_materialization/)
  assert.match(migration, /DIAGNOSTIC-EXISTING-RECON-V1/)
  assert.match(migration, /skpe_execute_governed_import_materialization_diagnostic_preexisting_v1/)
  assert.doesNotMatch(migration, /insert into public\.skpe_(pestel|swot|tows|strategic_risk)_items/)
})
