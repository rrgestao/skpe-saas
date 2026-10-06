import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const migration = readFileSync(
  new URL('../../../supabase/migrations/20261004220000_govern_pem0504_strategy_update.sql', import.meta.url),
  'utf8',
)
const panel = readFileSync(
  new URL('../src/modules/skpe/features/monitoring/MonitoringStrategyUpdateReadinessPanel.tsx', import.meta.url),
  'utf8',
)
const section = readFileSync(
  new URL('../src/modules/skpe/features/monitoring/MonitoringSection.tsx', import.meta.url),
  'utf8',
)

test('PEM-05.04 uses an append-only institutional update decision', () => {
  assert.match(migration, /skpe_strategy_update_decisions/)
  assert.match(migration, /decision_sequence/)
  assert.match(migration, /supersedes_decision_id/)
  assert.match(migration, /no_update_required/)
  assert.match(migration, /revision_required/)
  assert.match(migration, /revision_opened/)
})

test('PEM-05.04 reuses the canonical formulation revision authority', () => {
  assert.match(migration, /revisionAuthority','create_skpe_formulation_revision'/)
  assert.match(migration, /derived_from_formulation_id/)
  assert.match(migration, /PEM0504_REVISION_REQUIRED_NOT_OPENED/)
  assert.match(migration, /PEM0504_TARGET_REVISION_INVALID/)
  assert.match(migration, /preservesLineage',true/)
})

test('PEM-05.04 supports explicit no-update decision and detects lineage conflicts', () => {
  assert.match(migration, /PEM0504_UPDATE_DECISION_MISSING/)
  assert.match(migration, /PEM0504_NO_UPDATE_CONFLICTS_WITH_LEARNING/)
  assert.match(migration, /PEM0504_LEARNING_REVISION_LINEAGE_CONFLICT/)
  assert.match(migration, /requiresInstitutionalDecision',true/)
})

test('PEM-05.04 does not mutate approved formulation or create revision automatically', () => {
  assert.match(migration, /mutatesApprovedFormulation',false/)
  assert.match(migration, /createsRevisionAutomatically',false/)
  assert.match(migration, /skpe_guard_pem0504_completion/)
  assert.doesNotMatch(migration, /update public\.skpe_strategic_formulations/i)
  assert.doesNotMatch(migration, /create_skpe_formulation_revision\(/)
})

test('monitoring UI requires explicit human decision and explicit revision creation', () => {
  assert.match(panel, /Atualização Estratégica Governada/)
  assert.match(panel, /record_skpe_strategy_update_decision/)
  assert.match(panel, /create_skpe_formulation_revision/)
  assert.match(panel, /Uma nova revisão só é criada por ação humana explícita/)
  assert.match(panel, /Nenhuma atualização necessária/)
  assert.match(panel, /Revisão estratégica necessária/)
  assert.match(panel, /Criar revisão estratégica/)
  assert.match(section, /<MonitoringStrategyUpdateReadinessPanel/)
})
