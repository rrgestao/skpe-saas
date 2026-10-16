import assert from 'node:assert/strict'
import test from 'node:test'

import {
  buildExecutiveStrategicReportHtml,
  isExecutiveReportFinalized,
} from '../src/modules/skpe/executiveStrategicReport.ts'

const canonicalSummary = {
  formulationLabel: 'Formulação v3',
  formulationStatus: 'Aprovado',
  objectives: 10,
  indicators: 18,
  okrs: 6,
  keyResults: 18,
  initiatives: 12,
  risks: 4,
  monitoringStatus: 'Validado',
  note: null,
}

test('executive report assembles selected canonical artifacts without inventing decisions', () => {
  const html = buildExecutiveStrategicReportHtml({
    organizationName: 'COOTAQUARA',
    projectName: 'Planejamento Estratégico 2026–2030',
    horizonLabel: '2026–2030',
    isFinalized: false,
    finalGateCompleted: false,
    generatedAt: new Date('2026-10-05T18:00:00.000Z'),
    availableArtifactCount: 2,
    canonicalSummary,
    artifacts: [
      {
        title: 'Pacote de Diagnóstico',
        code: 'A-01',
        typeLabel: 'Relatório',
        phaseCode: 'PEM-01.02',
        purpose: 'Consolidar o diagnóstico.',
        statusLabel: 'Validado',
        version: 3,
        validatedAt: '2026-09-01T12:00:00.000Z',
        contentMarkdown: '# Diagnóstico\nConteúdo confirmado.',
        fileName: 'diagnostico.md',
      },
      {
        title: 'Plano de Evolução',
        code: 'A-02',
        typeLabel: 'Plano',
        phaseCode: 'PEM-02.05',
        purpose: 'Organizar os ciclos.',
        statusLabel: 'Em elaboração',
        version: 1,
        validatedAt: null,
        contentMarkdown: 'Proposta sujeita à validação.',
        fileName: 'evolucao.md',
      },
    ],
  })

  assert.match(html, /Relatório Executivo de Trabalho/)
  assert.match(html, /não deve ser apresentado como versão final institucional/)
  assert.match(html, /PEM-01 — Diagnóstico Estratégico/)
  assert.match(html, /PEM-02 — Formulação Estratégica/)
  assert.match(html, /Pacote de Diagnóstico/)
  assert.match(html, /Plano de Evolução/)
  assert.match(html, /COOTAQUARA/)
  assert.match(html, /Horizonte Estratégico:<\/strong> 2026–2030/)
  assert.match(html, /Formulação e desdobramento registrados/)
  assert.match(html, /Objetivos Estratégicos<\/th><td>10<\/td>/)
  assert.match(html, /KPIs \/ Indicadores estratégicos<\/th><td>18<\/td>/)
  assert.match(html, /Iniciativas selecionadas<\/th><td>12<\/td>/)
  assert.match(html, /Riscos de iniciativas<\/th><td>4<\/td>/)
  assert.match(html, /Governança de monitoramento<\/th><td>Validado<\/td>/)
  assert.match(html, /não cria evidência, aprovação, decisão institucional/)
  assert.doesNotMatch(html, /org-1|project-1/)
})

test('executive report escapes artifact content instead of executing markup', () => {
  const html = buildExecutiveStrategicReportHtml({
    organizationName: '<org>',
    projectName: 'project',
    horizonLabel: null,
    isFinalized: false,
    finalGateCompleted: true,
    generatedAt: new Date('2026-10-05T18:00:00.000Z'),
    availableArtifactCount: 1,
    canonicalSummary,
    artifacts: [{
      title: '<script>alert(1)</script>',
      code: 'A',
      typeLabel: 'Artefato',
      phaseCode: 'PEM-03.01',
      purpose: null,
      statusLabel: 'Proposta',
      version: 1,
      validatedAt: null,
      contentMarkdown: '<img src=x onerror=alert(1)>',
      fileName: null,
    }],
  })

  assert.doesNotMatch(html, /<script>alert\(1\)<\/script>/)
  assert.doesNotMatch(html, /<img src=x/)
  assert.match(html, /&lt;script&gt;/)
  assert.match(html, /&lt;img src=x/)
})

test('executive report cannot be labeled consolidated with an incomplete publication scope', () => {
  assert.equal(isExecutiveReportFinalized({
    finalGateCompleted: false,
    allArtifactsSelected: true,
    allArtifactsValidated: true,
  }), false)
  assert.equal(isExecutiveReportFinalized({
    finalGateCompleted: true,
    allArtifactsSelected: false,
    allArtifactsValidated: true,
  }), false)
  assert.equal(isExecutiveReportFinalized({
    finalGateCompleted: true,
    allArtifactsSelected: true,
    allArtifactsValidated: false,
  }), false)
  assert.equal(isExecutiveReportFinalized({
    finalGateCompleted: true,
    allArtifactsSelected: true,
    allArtifactsValidated: true,
  }), true)
})

test('executive report makes partial artifact selection visible', () => {
  const html = buildExecutiveStrategicReportHtml({
    organizationName: 'Org',
    projectName: 'Project',
    horizonLabel: null,
    isFinalized: false,
    finalGateCompleted: true,
    generatedAt: new Date('2026-10-05T18:00:00.000Z'),
    availableArtifactCount: 3,
    canonicalSummary,
    artifacts: [{
      title: 'Selected artifact',
      code: 'A-01',
      typeLabel: 'Report',
      phaseCode: 'PEM-01.01',
      purpose: null,
      statusLabel: 'Validated',
      version: 1,
      validatedAt: null,
      contentMarkdown: null,
      fileName: 'artifact.pdf',
    }],
  })

  assert.match(html, /1 de 3 artefatos disponíveis/)
  assert.match(html, /Os itens não selecionados não aparecem neste relatório/)
  assert.match(html, /a seleção ou a validação dos artefatos ainda está incompleta/)
})
