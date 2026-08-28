import assert from 'node:assert/strict'
import test from 'node:test'

import {
  buildExecutionMatrixRows,
  deriveExecutionAttentionReasons,
  type ActionBoardExecutionRow,
  type CapacityAllocationExecutionRow,
  type PersonCapacityExecutionRow,
} from '../src/modules/skpe/features/monitoring/monitoringExecutionMatrix.ts'
import type {
  InitiativeTemporalTimelineRow,
} from '../src/modules/skpe/features/monitoring/monitoringTimeline.ts'

function action(
  overrides: Partial<ActionBoardExecutionRow> = {},
): ActionBoardExecutionRow {
  return {
    action_id: 'action-1',
    initiative_id: 'initiative-1',
    code: 'A-01',
    name: 'Ação 01',
    status: 'in_progress',
    priority: 'medium',
    official_progress: 35,
    calculated_progress: 50,
    has_eligible_children: false,
    planned_cost: 100,
    actual_cost: 80,
    currency_code: 'BRL',
    estimated_effort: 10,
    actual_effort: 8,
    effort_unit: 'hours',
    ...overrides,
  }
}

function temporal(
  overrides: Partial<InitiativeTemporalTimelineRow> = {},
): InitiativeTemporalTimelineRow {
  return {
    entity_type: 'action',
    entity_id: 'action-1',
    initiative_id: 'initiative-1',
    code: 'A-01',
    name: 'Ação 01',
    baseline_start_date: null,
    baseline_end_date: null,
    current_plan_start_date: '2026-08-01',
    current_plan_end_date: '2026-08-20',
    forecast_start_date: null,
    forecast_end_date: null,
    actual_start_date: '2026-08-02',
    actual_end_date: null,
    is_start_overdue: false,
    days_start_overdue: 0,
    is_completion_overdue: false,
    days_completion_overdue: 0,
    temporal_state: 'in_progress',
    temporal_data_quality_state: 'ok',
    ...overrides,
  }
}

function allocation(
  overrides: Partial<CapacityAllocationExecutionRow> = {},
): CapacityAllocationExecutionRow {
  return {
    allocationId: 'allocation-1',
    capacityPeriodId: 'capacity-1',
    organizationPersonId: 'person-1',
    personName: 'Pessoa 1',
    capacityUnit: 'hours',
    objectType: 'initiative_action',
    objectId: 'action-1',
    allocatedAmount: 12,
    allocationStatus: 'active',
    ...overrides,
  }
}

function capacity(
  overrides: Partial<PersonCapacityExecutionRow> = {},
): PersonCapacityExecutionRow {
  return {
    capacity_period_id: 'capacity-1',
    person_name: 'Pessoa 1',
    capacity_unit: 'hours',
    overallocation_amount: 0,
    is_overallocated: false,
    ...overrides,
  }
}

test('usa progresso oficial quando a ação não consolida filhos', () => {
  const [row] = buildExecutionMatrixRows(
    [action()],
    [temporal()],
    [],
    [],
  )

  assert.equal(row.progressSource, 'official')
  assert.equal(row.progressValue, 35)
})

test('usa progresso calculado quando a ação consolida filhos elegíveis', () => {
  const [row] = buildExecutionMatrixRows(
    [
      action({
        has_eligible_children: true,
      }),
    ],
    [temporal()],
    [],
    [],
  )

  assert.equal(row.progressSource, 'calculated')
  assert.equal(row.progressValue, 50)
})

test('agrupa capacidade somente por unidade sem converter grandezas', () => {
  const [row] = buildExecutionMatrixRows(
    [action()],
    [temporal()],
    [
      allocation(),
      allocation({
        allocationId: 'allocation-2',
        organizationPersonId: 'person-2',
        capacityUnit: 'hours',
        allocatedAmount: 8,
      }),
      allocation({
        allocationId: 'allocation-3',
        capacityUnit: 'points',
        allocatedAmount: 3,
      }),
    ],
    [],
  )

  assert.deepEqual(row.capacityGroups, [
    {
      unit: 'hours',
      allocatedAmount: 20,
      allocationCount: 2,
      personCount: 2,
    },
    {
      unit: 'points',
      allocatedAmount: 3,
      allocationCount: 1,
      personCount: 1,
    },
  ])
})

test('ignora alocação que não pertence a uma ação', () => {
  const [row] = buildExecutionMatrixRows(
    [action()],
    [temporal()],
    [
      allocation({
        objectType: 'initiative',
        objectId: 'initiative-1',
      }),
    ],
    [],
  )

  assert.deepEqual(row.capacityGroups, [])
})

test('sinaliza sobrealocação sem normalizar o valor alocado', () => {
  const [row] = buildExecutionMatrixRows(
    [action()],
    [temporal()],
    [allocation()],
    [
      capacity({
        is_overallocated: true,
        overallocation_amount: 4,
      }),
    ],
  )

  assert.equal(row.hasOverallocatedCapacity, true)
  assert.equal(
    row.capacityGroups[0].allocatedAmount,
    12,
  )
  assert.ok(
    row.attentionReasons.includes(
      'Capacidade sobrealocada',
    ),
  )
})

test('expõe custo sem moeda e esforço sem unidade como qualidade, não conversão', () => {
  const reasons =
    deriveExecutionAttentionReasons(
      temporal(),
      false,
      action({
        currency_code: null,
        effort_unit: null,
      }),
    )

  assert.ok(reasons.includes('Custo sem moeda'))
  assert.ok(
    reasons.includes('Esforço sem unidade'),
  )
})

test('ordena ações com atenção antes das demais sem criar score composto', () => {
  const rows = buildExecutionMatrixRows(
    [
      action({
        action_id: 'action-ok',
        code: 'A-01',
        priority: 'critical',
      }),
      action({
        action_id: 'action-risk',
        code: 'A-02',
        priority: 'low',
      }),
    ],
    [
      temporal({
        entity_id: 'action-ok',
        code: 'A-01',
      }),
      temporal({
        entity_id: 'action-risk',
        code: 'A-02',
        is_completion_overdue: true,
        days_completion_overdue: 5,
      }),
    ],
    [],
    [],
  )

  assert.equal(
    rows[0].action.action_id,
    'action-risk',
  )
  assert.equal(
    rows[1].action.action_id,
    'action-ok',
  )
})