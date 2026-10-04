import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004170000_govern_pem0402_communication_mobilization.sql', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicCommunicationMobilizationReadinessSection.tsx', import.meta.url),
  'utf8',
)
const cockpit = readFileSync(
  new URL('../src/modules/skpe/SkpeCockpit.tsx', import.meta.url),
  'utf8',
)

test('PEM-04.02 introduces a canonical package and communication items', () => {
  assert.match(migration, /skpe_implementation_communication_packages/)
  assert.match(migration, /skpe_implementation_communication_items/)
  assert.match(migration, /audience_label/)
  assert.match(migration, /communication_objective/)
  assert.match(migration, /key_message/)
  assert.match(migration, /channel/)
  assert.match(migration, /cadence/)
  assert.match(migration, /evidence_asset_id/)
})

test('PEM-04.02 reuses activation readiness and requires human validation', () => {
  assert.match(migration, /get_skpe_pem0401_activation_readiness/)
  assert.match(migration, /PEM0402_ACTIVATION_NOT_READY/)
  assert.match(migration, /PEM0402_PACKAGE_NOT_VALIDATED/)
  assert.match(migration, /can_validate_skpe_formulation/)
  assert.match(migration, /transition_skpe_pem0402_communication_package/)
})

test('PEM-04.02 completion is fail-closed and never sends communication', () => {
  assert.match(migration, /skpe_guard_pem0402_completion/)
  assert.match(migration, /readyForCompletion/)
  assert.match(migration, /automaticSendingPerformed',false/)
  assert.match(migration, /automaticSendingEnabled',false/)
  assert.doesNotMatch(migration, /send_email|send_message|smtp|twilio/i)
})

test('PEM-04.02 UI exposes readiness and opens the plan workspace', () => {
  assert.match(section, /PEM-04\.02 · Comunicação e Mobilização/)
  assert.match(section, /get_skpe_pem0402_communication_readiness/)
  assert.match(section, /não\s+dispara mensagens automaticamente/)
  assert.match(section, /Validação humana obrigatória/)
  assert.match(section, /Bloqueadores/)
  assert.match(cockpit, /current_stage_code === 'PEM-04\.02'[\s\S]*'plan'/)
})
