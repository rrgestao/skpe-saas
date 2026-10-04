import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004174500_govern_pem0403_capabilities_change.sql', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicCapabilitiesChangeReadinessSection.tsx', import.meta.url),
  'utf8',
)
const cockpit = readFileSync(
  new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url),
  'utf8',
)

test('PEM-04.03 creates canonical change-gap records without duplicating capacity allocation', () => {
  assert.match(migration, /skpe_implementation_change_packages/)
  assert.match(migration, /skpe_implementation_change_items/)
  assert.match(migration, /personCapacityAuthority','sparks_person_capacity_periods\/allocations'/)
  assert.match(migration, /duplicatesCapacityAllocation',false/)
})

test('PEM-04.03 supports applicable and no-material-gap outcomes', () => {
  assert.match(migration, /undetermined','applicable','no_material_gap/)
  assert.match(migration, /PEM0403_APPLICABILITY_UNDETERMINED/)
  assert.match(migration, /PEM0403_NO_GAP_REASON_MISSING/)
  assert.match(migration, /PEM0403_GAP_ITEM_MISSING/)
})

test('PEM-04.03 requires treatment ownership, deadline and human validation', () => {
  assert.match(migration, /PEM0403_GAP_ITEM_INCOMPLETE/)
  assert.match(migration, /owner_user_id is null/)
  assert.match(migration, /target_date is null/)
  assert.match(migration, /transition_skpe_pem0403_change_package/)
  assert.match(migration, /can_validate_skpe_formulation/)
  assert.match(migration, /skpe_guard_pem0403_completion/)
})

test('PEM-04.03 UI exposes canonical capacity authority and opens plan workspace', () => {
  assert.match(section, /PEM-04\.03 · Capacidades e Gestão da Mudança/)
  assert.match(section, /get_skpe_pem0403_change_readiness/)
  assert.match(section, /não a\s+duplica/)
  assert.match(section, /sparks_person_capacity_periods\/allocations/)
  assert.match(section, /Bloqueadores/)
  assert.match(cockpit, /current_stage_code === 'PEM-04\.03'[\s\S]*'plan'/)
})
