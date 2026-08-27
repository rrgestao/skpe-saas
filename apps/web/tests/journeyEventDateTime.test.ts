import assert from 'node:assert/strict'
import test from 'node:test'

import {
  isoToZonedLocalDateTime,
  isValidTimeZone,
  zonedLocalDateTimeToIso,
} from '../src/modules/skpe/features/journey/journeyEventDateTime.ts'

test('reconhece timezone IANA valido e rejeita timezone invalido', () => {
  assert.equal(isValidTimeZone('America/Sao_Paulo'), true)
  assert.equal(isValidTimeZone('Timezone/Inexistente'), false)
})

test('interpreta datetime-local no timezone do evento, nao no navegador', () => {
  assert.equal(
    zonedLocalDateTimeToIso(
      '2026-08-27T09:00',
      'America/Sao_Paulo',
    ),
    '2026-08-27T12:00:00.000Z',
  )
})

test('reconstroi UTC no horario local canonico do evento', () => {
  assert.equal(
    isoToZonedLocalDateTime(
      '2026-08-27T12:00:00.000Z',
      'America/Sao_Paulo',
    ),
    '2026-08-27T09:00',
  )
})

test('preserva semantica em timezone diferente do Brasil', () => {
  assert.equal(
    zonedLocalDateTimeToIso(
      '2026-08-27T09:00',
      'America/New_York',
    ),
    '2026-08-27T13:00:00.000Z',
  )
})

test('rejeita horario local inexistente durante salto de DST', () => {
  assert.equal(
    zonedLocalDateTimeToIso(
      '2026-03-08T02:30',
      'America/New_York',
    ),
    null,
  )
})

test('aceita horario valido logo apos salto de DST', () => {
  assert.equal(
    zonedLocalDateTimeToIso(
      '2026-03-08T03:30',
      'America/New_York',
    ),
    '2026-03-08T07:30:00.000Z',
  )
})