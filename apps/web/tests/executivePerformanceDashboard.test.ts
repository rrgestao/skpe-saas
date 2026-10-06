import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

import { buildExecutivePerformanceReportHtml } from '../src/modules/initiatives/analytics/executivePerformanceReport.ts'

const cockpit = readFileSync(
  new URL('../src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx', import.meta.url),
  'utf8',
)

test('executive performance report preserves governed absence and escapes user-facing text', () => {
  const html = buildExecutivePerformanceReportHtml({
    organizationName: '<Organização>',
    projectName: 'Plano & Estratégia',
    generatedAt: new Date('2026-10-06T12:00:00Z'),
    journey: null,
    portfolio: {
      total: 0,
      operationalUniverse: 0,
      averageOperationalProgress: null,
      inProgress: 0,
      underAnalysis: 0,
      proposals: 0,
      blocked: 0,
      critical: 0,
      withoutDueDate: 0,
      attentionSignals: 0,
    },
    priorities: [],
    areas: [],
    classes: [],
  })

  assert.match(html, /Relatório Executivo de Resultados e Desempenho/)
  assert.match(html, /&lt;Organização&gt;/)
  assert.match(html, /Plano &amp; Estratégia/)
  assert.match(html, /Progresso médio operacional[\s\S]*?—/)
  assert.match(html, /Sem leitura disponível/)
  assert.match(html, /não cria aprovação, evidência, meta, decisão institucional ou avanço da Jornada/)
})

test('dashboard first wave exposes governed composition, operational universe and export', () => {
  assert.match(cockpit, /Progresso médio operacional/)
  assert.match(cockpit, /propostas e itens em análise não entram na média/)
  assert.match(cockpit, /Por prioridade/)
  assert.match(cockpit, /Por área responsável/)
  assert.match(cockpit, /Por classe/)
  assert.match(cockpit, /Exportar relatório executivo de desempenho/)
  assert.match(cockpit, /Exportar dados do portfólio \(CSV\)/)
  assert.match(cockpit, /SPARKs-PE-Portfolio-Executivo/)
  assert.match(cockpit, /uma iniciativa pode gerar mais de um sinal/)
})
