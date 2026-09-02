import assert from 'node:assert/strict'
import test from 'node:test'

import type { StrategicMapPayload } from '../src/modules/skpe/contracts/strategic-map.ts'
import {
  readStrategicMapPosition,
  strategicMapToReactFlow,
} from '../src/modules/skpe/features/strategy/strategicMapAdapter.ts'

const basePayload: StrategicMapPayload = {
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
  themes: [],
  perspectives: [
    {
      id: 'perspective-1',
      code: 'P1',
      name: 'Perspectiva 1',
      description: null,
      displayOrder: 2,
      status: 'active',
      methodologicalNature: null,
      perspectiveModel: null,
      visualColor: null,
      metadata: {},
      createdAt: '2026-09-02T00:00:00Z',
      updatedAt: '2026-09-02T00:00:00Z',
    },
  ],
  objectives: [
    {
      id: 'objective-1',
      code: 'OE1',
      title: 'Objetivo 1',
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
      strategicThemeId: null,
      perspectiveId: 'perspective-1',
      displayOrder: 3,
      mapPosition: { x: 123, y: 456 },
      visualColor: null,
      metadata: {},
      createdAt: '2026-09-02T00:00:00Z',
      updatedAt: '2026-09-02T00:00:00Z',
    },
    {
      id: 'objective-2',
      code: 'OE2',
      title: 'Objetivo 2',
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
      strategicThemeId: null,
      perspectiveId: 'perspective-1',
      displayOrder: 4,
      mapPosition: null,
      visualColor: null,
      metadata: {},
      createdAt: '2026-09-02T00:00:00Z',
      updatedAt: '2026-09-02T00:00:00Z',
    },
  ],
  relations: [
    {
      id: 'relation-1',
      sourceObjectiveId: 'objective-1',
      targetObjectiveId: 'objective-2',
      relationType: 'cause_effect',
      contributionStrength: null,
      relationWeight: null,
      rationale: null,
      displayOrder: 1,
      metadata: {},
      createdAt: '2026-09-02T00:00:00Z',
    },
    {
      id: 'orphan-relation',
      sourceObjectiveId: 'objective-1',
      targetObjectiveId: 'missing-objective',
      relationType: 'cause_effect',
      contributionStrength: null,
      relationWeight: null,
      rationale: null,
      displayOrder: 2,
      metadata: {},
      createdAt: '2026-09-02T00:00:00Z',
    },
  ],
  readiness: {},
}

test('reads only valid persisted map positions', () => {
  assert.deepEqual(readStrategicMapPosition({ x: 10, y: 20 }), { x: 10, y: 20 })
  assert.equal(readStrategicMapPosition({ x: '10', y: 20 }), null)
  assert.equal(readStrategicMapPosition(null), null)
})

test('maps only canonical objectives and relations to React Flow', () => {
  const graph = strategicMapToReactFlow(basePayload)

  assert.equal(graph.nodes.length, 2)
  assert.equal(graph.edges.length, 1)

  assert.deepEqual(graph.nodes[0]?.position, { x: 123, y: 456 })
  assert.equal(graph.nodes[0]?.data.persistedPosition, true)

  assert.equal(graph.nodes[1]?.data.persistedPosition, false)
  assert.equal(graph.edges[0]?.source, 'objective-1')
  assert.equal(graph.edges[0]?.target, 'objective-2')
})