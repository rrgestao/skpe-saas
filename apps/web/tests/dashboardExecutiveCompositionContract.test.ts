import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const cockpit = readFileSync(
  join(testDir, '../src/modules/initiatives/analytics/InitiativePerformanceCockpit.tsx'),
  'utf8',
)
const css = readFileSync(
  join(testDir, '../src/modules/initiatives/analytics/InitiativePerformanceCockpit.css'),
  'utf8',
)

test('Visão Geral organiza resultados e execução em dois grandes containers executivos', () => {
  assert.match(cockpit, /skpe-performance-dashboard-layout/)
  assert.match(cockpit, /Desenvolvimento do Plano Estratégico/)
  assert.match(cockpit, /prontidão dos elementos necessários à execução da estratégia/)
  assert.match(cockpit, /<span>Macrofases<\/span>/)
  assert.match(cockpit, /<span>Objetivos Estratégicos<\/span>/)
  assert.match(cockpit, /<span>OKRs<\/span>/)
  assert.match(cockpit, /Objetivo Estratégico pronto = validado ou aprovado/)
  assert.match(cockpit, /OKR pronto para execução = possui KRs cadastrados/)
  assert.match(cockpit, /Execução estratégica e atenção à gestão/)
  assert.match(cockpit, /Acompanhe o que está sendo executado e onde a gestão precisa agir/)
  assert.doesNotMatch(cockpit, />Execução estratégica<\/p>/)
  assert.match(cockpit, /Macrofase atual em andamento/)
  assert.match(cockpit, /skpe-performance-portfolio-donut/)
  assert.match(cockpit, /skpe-performance-portfolio-legend/)
  assert.match(cockpit, /skpe-performance-attention-card/)
  assert.match(cockpit, /skpe-performance-attention-bars/)
  assert.match(cockpit, /Monitoramento Executivo das Iniciativas/)
  assert.doesNotMatch(cockpit, /leitura governada da Jornada/)
  assert.doesNotMatch(cockpit, /<span>Próximo marco<\/span>/)
  assert.match(css, /DASHBOARD EXECUTIVE BALANCE V3 FINAL/)
  assert.match(css, /JOURNEY COMPARISON READABILITY V4/)
  assert.match(css, /white-space: nowrap/)
  assert.match(css, /grid-template-columns: max-content max-content/)
  assert.match(cockpit, /Atenção da Gestão/)
  assert.match(css, /DASHBOARD EXECUTIVE COMPOSITION V2/)
  assert.match(css, /grid-template-columns: minmax\(0, 1fr\) minmax\(0, 1fr\)/)
})
