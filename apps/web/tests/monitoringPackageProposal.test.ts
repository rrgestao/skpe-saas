import assert from 'node:assert/strict'
import test from 'node:test'

import {
  createInitialMonitoringPackageDraft,
  monitoringPackageDraftIsMaterializable,
  monitoringPackageInitialProposal,
  monitoringPackageProposalIsMaterializable,
} from '../src/modules/skpe/features/monitoring/monitoringPackageProposal.ts'

function valueOf(key: string) {
  return monitoringPackageInitialProposal.find((item) => item.key === key)?.value
}

test('proposta FE-08 reflete os defaults técnicos auditados do runtime', () => {
  assert.equal(valueOf('cycleFrequency'), 'monthly')
  assert.equal(valueOf('reviewFrequency'), 'quarterly')
  assert.equal(valueOf('cycleOverlapPolicy'), 'block')
  assert.equal(valueOf('evidenceRequired'), true)
  assert.equal(valueOf('dataQualityRequired'), true)
  assert.equal(valueOf('confidenceRequiredForKeyResults'), true)
  assert.equal(valueOf('allowManualProgressOverride'), false)
})

test('proposta FE-08 preserva limites e política de agregação do runtime', () => {
  assert.equal(valueOf('dataFreshnessDays'), 45)
  assert.equal(valueOf('lateToleranceDays'), 5)
  assert.equal(valueOf('aggregationPolicy'), 'explicit_weight')
  assert.equal(valueOf('criticalThreshold'), 50)
  assert.equal(valueOf('attentionThreshold'), 75)
  assert.equal(valueOf('onTrackThreshold'), 100)
})

test('responsáveis permanecem decisão humana e bloqueiam materialização automática', () => {
  assert.equal(valueOf('ownerUserId'), null)
  assert.equal(valueOf('governanceOwnerUserId'), null)
  assert.equal(monitoringPackageProposalIsMaterializable(), false)
})

test('rascunho FE-08 só é materializável com responsáveis e justificativa auditável', () => {
  const draft = createInitialMonitoringPackageDraft()
  assert.equal(monitoringPackageDraftIsMaterializable(draft), false)

  draft.ownerUserId = '11111111-1111-1111-1111-111111111111'
  draft.governanceOwnerUserId = '22222222-2222-2222-2222-222222222222'
  draft.changeReason = 'Configuração validada para o ciclo inicial.'

  assert.equal(monitoringPackageDraftIsMaterializable(draft), true)
})
