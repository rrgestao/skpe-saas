import assert from 'node:assert/strict'
import test from 'node:test'

import {
  isJourneyStatusChangeDraftDirty,
  normalizeJourneyStatusChangeReason,
  validateJourneyStatusChangeReason,
} from '../src/modules/skpe/features/journey/journeyItemStatusChange.ts'

test('normaliza justificativa sem alterar o conteúdo interno', () => {
  assert.equal(
    normalizeJourneyStatusChangeReason(
      '  Ajuste operacional necessário.  ',
    ),
    'Ajuste operacional necessário.',
  )
})

test('não considera espaços isolados como rascunho', () => {
  assert.equal(
    isJourneyStatusChangeDraftDirty('   '),
    false,
  )
  assert.equal(
    isJourneyStatusChangeDraftDirty(
      'Mudança necessária',
    ),
    true,
  )
})

test('rejeita justificativa com menos de dez caracteres', () => {
  const result =
    validateJourneyStatusChangeReason('curta')

  assert.equal(result.valid, false)
  assert.match(
    result.error ?? '',
    /10 caracteres/,
  )
})

test('aceita justificativa auditável', () => {
  const result =
    validateJourneyStatusChangeReason(
      'Reprogramação aprovada pela governança.',
    )

  assert.equal(result.valid, true)
  assert.equal(
    result.reason,
    'Reprogramação aprovada pela governança.',
  )
})