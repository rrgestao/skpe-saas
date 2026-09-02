import assert from 'node:assert/strict'
import test from 'node:test'

import {
  parsePlatformRoute,
  platformRoutes,
} from '../src/modules/skpe/app/skpeRoutes.ts'

test(
  'gera e reconhece a rota de Ciclos de Evolução',
  () => {
    const pathname = platformRoutes.skpe({
      organizationId: 'org-001',
      projectId: 'project-001',
      formulationId: 'formulation-001',
      section: 'evolution-cycles',
    })

    assert.equal(
      pathname,
      '/organizations/org-001/skpe/projects/project-001/formulations/formulation-001/evolution-cycles',
    )

    assert.deepEqual(
      parsePlatformRoute(pathname),
      {
        kind: 'skpe',
        organizationId: 'org-001',
        projectId: 'project-001',
        formulationId: 'formulation-001',
        section: 'evolution-cycles',
      },
    )
  },
)

test(
  'gera e reconhece a rota de Monitoramento',
  () => {
    const pathname = platformRoutes.skpe({
      organizationId: 'org-001',
      projectId: 'project-001',
      formulationId: 'formulation-001',
      section: 'monitoring',
    })

    assert.equal(
      pathname,
      '/organizations/org-001/skpe/projects/project-001/formulations/formulation-001/monitoring',
    )

    assert.deepEqual(
      parsePlatformRoute(pathname),
      {
        kind: 'skpe',
        organizationId: 'org-001',
        projectId: 'project-001',
        formulationId: 'formulation-001',
        section: 'monitoring',
      },
    )
  },
)

test(
  'preserva codificacao e decodificacao dos identificadores',
  () => {
    const pathname = platformRoutes.skpe({
      organizationId: 'org com espaço',
      projectId: 'projeto/2026',
      formulationId: 'formulação 1',
      section: 'evolution-cycles',
    })

    assert.deepEqual(
      parsePlatformRoute(pathname),
      {
        kind: 'skpe',
        organizationId: 'org com espaço',
        projectId: 'projeto/2026',
        formulationId: 'formulação 1',
        section: 'evolution-cycles',
      },
    )
  },
)

test(
  'rejeita seção SK-PE desconhecida',
  () => {
    const parsed = parsePlatformRoute(
      '/organizations/org-001/skpe/projects/project-001/formulations/formulation-001/evolution-unknown',
    )

    assert.deepEqual(parsed, {
      kind: 'unknown',
      pathname:
        '/organizations/org-001/skpe/projects/project-001/formulations/formulation-001/evolution-unknown',
    })
  },
)

test(
  'gera e reconhece a rota de Diagnóstico Estratégico',
  () => {
    const pathname = platformRoutes.skpe({
      organizationId: 'org-001',
      projectId: 'project-001',
      formulationId: 'formulation-001',
      section: 'diagnosis',
    })

    assert.deepEqual(parsePlatformRoute(pathname), {
      kind: 'skpe',
      organizationId: 'org-001',
      projectId: 'project-001',
      formulationId: 'formulation-001',
      section: 'diagnosis',
    })
  },
)
