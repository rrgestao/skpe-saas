import assert from 'node:assert/strict'
import test from 'node:test'

import {
  deriveMonitoringTimelineWindow,
  formatMonitoringTimelineDate,
  getJourneyTimelineDepth,
  getMonitoringTimelinePoint,
  getMonitoringTimelineSegment,
  type InitiativeTemporalTimelineRow,
  type JourneyEventTimelineRow,
  type JourneyTemporalTimelineRow,
} from '../src/modules/skpe/features/monitoring/monitoringTimeline.ts'

function journey(
  overrides: Partial<JourneyTemporalTimelineRow> = {},
): JourneyTemporalTimelineRow {
  return {
    item_id: 'item-1',
    parent_item_id: null,
    item_type: 'phase',
    item_code: 'F-01',
    item_name: 'Fase 01',
    item_status: 'in_progress',
    item_progress: 30,
    display_order: 1,
    baseline_start_date: null,
    baseline_end_date: null,
    current_plan_start_date: '2026-01-01',
    current_plan_end_date: '2026-01-10',
    forecast_start_date: null,
    forecast_end_date: null,
    operational_expected_start_date: '2026-01-01',
    operational_expected_end_date: '2026-01-10',
    actual_start_date: null,
    actual_end_date: null,
    is_start_overdue: false,
    days_start_overdue: 0,
    is_completion_overdue: false,
    days_completion_overdue: 0,
    temporal_state: 'in_progress',
    ...overrides,
  }
}

function initiative(
  overrides: Partial<InitiativeTemporalTimelineRow> = {},
): InitiativeTemporalTimelineRow {
  return {
    entity_type: 'initiative',
    entity_id: 'initiative-1',
    initiative_id: 'initiative-1',
    code: 'I-01',
    name: 'Iniciativa 01',
    baseline_start_date: null,
    baseline_end_date: null,
    current_plan_start_date: '2026-01-05',
    current_plan_end_date: '2026-01-20',
    forecast_start_date: null,
    forecast_end_date: null,
    actual_start_date: null,
    actual_end_date: null,
    is_start_overdue: false,
    days_start_overdue: 0,
    is_completion_overdue: false,
    days_completion_overdue: 0,
    temporal_data_quality_state: 'ok',
    ...overrides,
  }
}

function event(
  overrides: Partial<JourneyEventTimelineRow> = {},
): JourneyEventTimelineRow {
  return {
    event_id: 'event-1',
    journey_item_id: 'item-1',
    journey_item_code: 'F-01',
    journey_item_title: 'Fase 01',
    journey_item_type: 'phase',
    event_type: 'meeting',
    event_title: 'Reunião',
    starts_at: '2026-01-12T12:00:00Z',
    ends_at: '2026-01-12T13:00:00Z',
    all_day: false,
    timezone_name: 'America/Sao_Paulo',
    event_status: 'scheduled',
    priority: 'normal',
    ...overrides,
  }
}

test('deriva a janela temporal somente de datas canônicas disponíveis', () => {
  const window = deriveMonitoringTimelineWindow(
    [journey()],
    [initiative()],
    [event()],
    '2026-01-08',
  )

  assert.ok(window)
  assert.equal(window.startDate, '2026-01-01')
  assert.equal(window.endDate, '2026-01-20')
  assert.equal(window.totalDays, 20)
  assert.ok(window.referencePosition !== null)
})

test('não inventa janela quando nenhuma data canônica existe', () => {
  const emptyJourney = journey({
    current_plan_start_date: null,
    current_plan_end_date: null,
    operational_expected_start_date: null,
    operational_expected_end_date: null,
  })

  assert.equal(
    deriveMonitoringTimelineWindow(
      [emptyJourney],
      [],
      [],
      '2026-01-08',
    ),
    null,
  )
})

test('calcula segmento inclusivo e preserva um dia como barra visível', () => {
  const window = {
    startDate: '2026-01-01',
    endDate: '2026-01-10',
    totalDays: 10,
    referencePosition: null,
  }

  assert.deepEqual(
    getMonitoringTimelineSegment(
      '2026-01-03',
      '2026-01-03',
      window,
    ),
    {
      left: 20,
      width: 10,
    },
  )
})

test('recorta segmento nos limites da janela sem alterar a fonte', () => {
  const window = {
    startDate: '2026-01-01',
    endDate: '2026-01-10',
    totalDays: 10,
    referencePosition: null,
  }

  const result = getMonitoringTimelineSegment(
    '2025-12-20',
    '2026-01-05',
    window,
  )

  assert.deepEqual(result, {
    left: 0,
    width: 50,
  })
})

test('posiciona evento pela data de início dentro da mesma janela', () => {
  const window = {
    startDate: '2026-01-01',
    endDate: '2026-01-10',
    totalDays: 10,
    referencePosition: null,
  }

  assert.equal(
    getMonitoringTimelinePoint(
      '2026-01-01T15:00:00Z',
      window,
    ),
    5,
  )
  assert.equal(
    getMonitoringTimelinePoint(
      '2026-01-10T15:00:00Z',
      window,
    ),
    95,
  )
})

test('deriva profundidade da Jornada pela relação pai-filho', () => {
  const rows = [
    journey({
      item_id: 'mega',
      item_code: 'M-01',
    }),
    journey({
      item_id: 'phase',
      parent_item_id: 'mega',
      item_code: 'F-01',
    }),
    journey({
      item_id: 'step',
      parent_item_id: 'phase',
      item_code: 'E-01',
    }),
  ]

  assert.equal(
    getJourneyTimelineDepth(rows, 'mega'),
    0,
  )
  assert.equal(
    getJourneyTimelineDepth(rows, 'phase'),
    1,
  )
  assert.equal(
    getJourneyTimelineDepth(rows, 'step'),
    2,
  )
})

test('formata somente a parte de data sem reinterpretar timezone', () => {
  assert.equal(
    formatMonitoringTimelineDate(
      '2026-08-28T23:30:00-03:00',
    ),
    '28/08/2026',
  )
})