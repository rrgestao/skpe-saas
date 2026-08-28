import assert from 'node:assert/strict'
import test from 'node:test'

import {
  sortOrganizationsHierarchically,
  type HierarchicalOrganization,
  type OrganizationHierarchyNode,
} from '../src/lib/organizationHierarchy.ts'

function organization(
  id: string,
  name: string,
): HierarchicalOrganization {
  return {
    organization_id: id,
    organization_code: id,
    legal_name: name,
    trade_name: name,
  }
}

function hierarchyNode(
  id: string,
  parentId: string | null,
): OrganizationHierarchyNode {
  return {
    organization_id: id,
    parent_organization_id: parentId,
  }
}

function names(
  rows: readonly HierarchicalOrganization[],
) {
  return rows.map((row) => row.trade_name)
}

test('ordena organizacoes irmas de A a Z', () => {
  const parent = organization('parent', 'SESCOOP/DF')
  const company = organization('company', 'COOPERCOMPANY')
  const recicla = organization('recicla', 'RECICLE A VIDA')
  const aquara = organization('aquara', 'COOTAQUARA')

  const result = sortOrganizationsHierarchically(
    [parent, company, recicla, aquara],
    [
      hierarchyNode('parent', null),
      hierarchyNode('company', 'parent'),
      hierarchyNode('recicla', 'parent'),
      hierarchyNode('aquara', 'parent'),
    ],
    'asc',
  )

  assert.deepEqual(names(result), [
    'SESCOOP/DF',
    'COOPERCOMPANY',
    'COOTAQUARA',
    'RECICLE A VIDA',
  ])
})

test('ordena organizacoes irmas de Z a A', () => {
  const parent = organization('parent', 'SESCOOP/DF')
  const company = organization('company', 'COOPERCOMPANY')
  const recicla = organization('recicla', 'RECICLE A VIDA')
  const aquara = organization('aquara', 'COOTAQUARA')

  const result = sortOrganizationsHierarchically(
    [parent, company, recicla, aquara],
    [
      hierarchyNode('parent', null),
      hierarchyNode('company', 'parent'),
      hierarchyNode('recicla', 'parent'),
      hierarchyNode('aquara', 'parent'),
    ],
    'desc',
  )

  assert.deepEqual(names(result), [
    'SESCOOP/DF',
    'RECICLE A VIDA',
    'COOTAQUARA',
    'COOPERCOMPANY',
  ])
})

test('mantem o pai antes de seus filhos', () => {
  const parent = organization('parent', 'Pai')
  const child = organization('child', 'Filho')

  const result = sortOrganizationsHierarchically(
    [child, parent],
    [
      hierarchyNode('child', 'parent'),
      hierarchyNode('parent', null),
    ],
    'asc',
  )

  assert.deepEqual(names(result), ['Pai', 'Filho'])
})

test('posiciona netos logo apos o respectivo pai na travessia depth-first', () => {
  const root = organization('root', 'Raiz')
  const childA = organization('a', 'Filho A')
  const grandchild = organization('grandchild', 'Neto A')
  const childB = organization('b', 'Filho B')

  const result = sortOrganizationsHierarchically(
    [childB, grandchild, root, childA],
    [
      hierarchyNode('root', null),
      hierarchyNode('a', 'root'),
      hierarchyNode('grandchild', 'a'),
      hierarchyNode('b', 'root'),
    ],
    'asc',
  )

  assert.deepEqual(names(result), [
    'Raiz',
    'Filho A',
    'Neto A',
    'Filho B',
  ])
})

test('ordena multiplas raizes alfabeticamente e preserva seus descendentes', () => {
  const rootB = organization('root-b', 'Sistema B')
  const rootA = organization('root-a', 'Sistema A')
  const childA = organization('child-a', 'Cooperativa A')
  const childB = organization('child-b', 'Cooperativa B')

  const result = sortOrganizationsHierarchically(
    [rootB, childB, childA, rootA],
    [
      hierarchyNode('root-b', null),
      hierarchyNode('root-a', null),
      hierarchyNode('child-a', 'root-a'),
      hierarchyNode('child-b', 'root-b'),
    ],
    'asc',
  )

  assert.deepEqual(names(result), [
    'Sistema A',
    'Cooperativa A',
    'Sistema B',
    'Cooperativa B',
  ])
})

test('respeita o conjunto ja filtrado sem sintetizar ancestrais ocultos', () => {
  const child = organization('child', 'COOTAQUARA')

  const result = sortOrganizationsHierarchically(
    [child],
    [
      hierarchyNode('parent', null),
      hierarchyNode('child', 'parent'),
    ],
    'asc',
  )

  assert.deepEqual(names(result), ['COOTAQUARA'])
})
