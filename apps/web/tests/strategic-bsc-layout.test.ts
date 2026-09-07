import assert from 'node:assert/strict'
import test from 'node:test'

import type { StrategicMapPayload } from '../src/modules/skpe/contracts/strategic-map.ts'
import {
  BSC_LANE_HEIGHT,
  BSC_LANE_GAP,
  buildStrategicBscLayout,
} from '../src/modules/skpe/features/strategy/strategicBscLayout.ts'

const commonTheme = {
  description: null,
  rationale: null,
  priority: null,
  horizonStart: null,
  horizonEnd: null,
  ownerUserId: null,
  status: 'active',
  visualColor: null,
  metadata: {},
  createdAt: '2026-09-02T00:00:00Z',
  updatedAt: '2026-09-02T00:00:00Z',
}

const commonPerspective = {
  description: null,
  status: 'active',
  methodologicalNature: null,
  perspectiveModel: null,
  visualColor: null,
  metadata: {},
  createdAt: '2026-09-02T00:00:00Z',
  updatedAt: '2026-09-02T00:00:00Z',
}

const commonObjective = {
  description: null,
  expectedResult: null,
  rationale: null,
  priority: null,
  horizonStart: null,
  horizonEnd: null,
  ownerUserId: null,
  status: 'active',
  validationStatus: 'draft',
  progress: 0,
  displayOrder: 100,
  mapPosition: null,
  visualColor: null,
  metadata: {},
  createdAt: '2026-09-02T00:00:00Z',
  updatedAt: '2026-09-02T00:00:00Z',
}

const payload: StrategicMapPayload = {
  formulation: {
    id: 'f1',
    organizationId: 'o1',
    projectId: 'p1',
    versionNumber: 1,
    versionLabel: null,
    status: 'draft',
    validFrom: null,
    validUntil: null,
  },
  package: null,
  themes: [
    {
      ...commonTheme,
      id: 't1',
      code: 'TE-01',
      name: 'Tema 1',
      displayOrder: 1,
    },
    {
      ...commonTheme,
      id: 't3',
      code: 'TE-03',
      name: 'Tema transversal',
      displayOrder: 3,
    },
  ],
  perspectives: [
    {
      ...commonPerspective,
      id: 'p1',
      code: 'PE-01',
      name: 'Base',
      displayOrder: 1,
    },
    {
      ...commonPerspective,
      id: 'p2',
      code: 'PE-02',
      name: 'Processos',
      displayOrder: 2,
    },
    {
      ...commonPerspective,
      id: 'p5',
      code: 'PE-05',
      name: 'Topo',
      displayOrder: 5,
    },
  ],
  objectives: [
    {
      ...commonObjective,
      id: 'oe1',
      code: 'OE-01',
      title: 'Objetivo base 1',
      strategicThemeId: 't3',
      perspectiveId: 'p1',
    },
    {
      ...commonObjective,
      id: 'oe2',
      code: 'OE-02',
      title: 'Objetivo base 2',
      strategicThemeId: 't3',
      perspectiveId: 'p1',
    },
    {
      ...commonObjective,
      id: 'oe3',
      code: 'OE-03',
      title: 'Objetivo processos',
      strategicThemeId: 't3',
      perspectiveId: 'p2',
    },
    {
      ...commonObjective,
      id: 'oe9',
      code: 'OE-09',
      title: 'Objetivo topo',
      strategicThemeId: 't1',
      perspectiveId: 'p5',
    },
  ],
  relations: [],
  readiness: {},
}

test('orders perspectives from PE-05 at top to PE-01 at base', () => {
  const layout = buildStrategicBscLayout(payload)

  assert.deepEqual(
    layout.lanes.map((lane) => lane.perspective.code),
    ['PE-05', 'PE-02', 'PE-01'],
  )

  assert.equal(
    layout.lanes[1]!.y - layout.lanes[0]!.y,
    BSC_LANE_HEIGHT + BSC_LANE_GAP,
  )
})

test('repeats one transversal theme group across different perspectives', () => {
  const layout = buildStrategicBscLayout(payload)

  const te03Groups = layout.themeGroups.filter(
    (group) => group.theme.code === 'TE-03',
  )

  assert.equal(te03Groups.length, 2)
  assert.deepEqual(
    te03Groups.map((group) => group.perspective.code).sort(),
    ['PE-01', 'PE-02'],
  )
})

test('groups objectives of the same theme inside one perspective', () => {
  const layout = buildStrategicBscLayout(payload)

  const group = layout.themeGroups.find(
    (candidate) =>
      candidate.perspective.code === 'PE-01' &&
      candidate.theme.code === 'TE-03',
  )

  assert.ok(group)
  assert.deepEqual(group.objectiveIds, ['oe1', 'oe2'])

  const oe1 = layout.objectives.find((objective) => objective.id === 'oe1')
  const oe2 = layout.objectives.find((objective) => objective.id === 'oe2')

  assert.ok(oe1)
  assert.ok(oe2)
  assert.equal(oe1.theme.code, 'TE-03')
  assert.equal(oe2.theme.code, 'TE-03')
  assert.ok(oe2.x > oe1.x)
  assert.equal(oe1.y, oe2.y)
})