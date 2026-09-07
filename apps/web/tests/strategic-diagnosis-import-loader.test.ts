import assert from 'node:assert/strict'
import test from 'node:test'

import { reconcileImportedDiagnosisRecords } from '../src/modules/skpe/features/diagnosis/strategicDiagnosisImportReconciler.ts'

test('prefers reconciled import record for the same external key', () => {
  const rows = [
    {
      id: 'new-record',
      source_sheet: '04_PESTEL',
      source_row: 5,
      external_key: 'pestel:pest_p01',
      simulation_status: 'new',
      target_record_id: null,
      values_json: { codigo: 'PEST-P01', fator_externo: 'Fator anterior' },
      created_at: '2026-08-01T00:00:00Z',
    },
    {
      id: 'reconciled-record',
      source_sheet: '04_PESTEL',
      source_row: 5,
      external_key: 'pestel:pest_p01',
      simulation_status: 'unchanged',
      target_record_id: 'new-record',
      values_json: { codigo: 'PEST-P01', fator_externo: 'Fator canônico' },
      created_at: '2026-08-02T00:00:00Z',
    },
  ]

  const result = reconcileImportedDiagnosisRecords(rows)

  assert.equal(result.length, 1)
  assert.equal(result[0]?.id, 'reconciled-record')
  assert.equal(result[0]?.values.fator_externo, 'Fator canônico')
  assert.equal(result[0]?.targetRecordId, 'new-record')
})

test('prefers update over unchanged when both are reconciled', () => {
  const rows = [
    {
      id: 'unchanged-record',
      source_sheet: '06_TOWS',
      source_row: 7,
      external_key: 'tows:tw_fo01',
      simulation_status: 'unchanged',
      target_record_id: 'original',
      values_json: { codigo: 'TW-FO01', estrategia_formulada: 'Estratégia anterior' },
      created_at: '2026-08-03T00:00:00Z',
    },
    {
      id: 'update-record',
      source_sheet: '06_TOWS',
      source_row: 7,
      external_key: 'tows:tw_fo01',
      simulation_status: 'update',
      target_record_id: 'unchanged-record',
      values_json: { codigo: 'TW-FO01', estrategia_formulada: 'Estratégia atualizada' },
      created_at: '2026-08-02T00:00:00Z',
    },
  ]

  const result = reconcileImportedDiagnosisRecords(rows)

  assert.equal(result.length, 1)
  assert.equal(result[0]?.id, 'update-record')
  assert.equal(result[0]?.values.estrategia_formulada, 'Estratégia atualizada')
})

test('falls back to latest valid record when no reconciliation exists', () => {
  const rows = [
    {
      id: 'older',
      source_sheet: '05_SWOT',
      source_row: 5,
      external_key: 'swot:sw_f01',
      simulation_status: 'new',
      target_record_id: null,
      values_json: { codigo: 'SW-F01', fator: 'Versão antiga' },
      created_at: '2026-08-01T00:00:00Z',
    },
    {
      id: 'newer',
      source_sheet: '05_SWOT',
      source_row: 5,
      external_key: 'swot:sw_f01',
      simulation_status: 'new',
      target_record_id: null,
      values_json: { codigo: 'SW-F01', fator: 'Versão nova' },
      created_at: '2026-08-03T00:00:00Z',
    },
  ]

  const result = reconcileImportedDiagnosisRecords(rows)

  assert.equal(result.length, 1)
  assert.equal(result[0]?.id, 'newer')
})