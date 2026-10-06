import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const journeySection = readFileSync(join(testDir, '../src/modules/skpe/features/journey/JourneySection.tsx'), 'utf8')
const planner = readFileSync(join(testDir, '../src/modules/skpe/features/journey/JourneySchedulePlanner.tsx'), 'utf8')
const gantt = readFileSync(join(testDir, '../src/modules/skpe/features/journey/JourneyGantt.tsx'), 'utf8')
const svar = readFileSync(join(testDir, '../src/modules/skpe/features/journey/SvarJourneyGantt.tsx'), 'utf8')

test('Jornada hidrata liderança e janela do Projeto Estratégico', () => {
  assert.match(journeySection, /get_skpe_project_leadership_context/)
  assert.match(journeySection, /organizationLeadName/)
  assert.match(journeySection, /sparkoopLeadName/)
  assert.match(journeySection, /Liderança da Organização/)
  assert.match(journeySection, /Líder da Consultoria SPARKOOP/)
  assert.match(journeySection, /Responsável pela Cooperativa na Jornada Estratégica/)
  assert.match(journeySection, /Janela do projeto/)
  assert.match(journeySection, /current && availableIds\.has\(current\) \? current : null/)
  assert.match(journeySection, /skpe-journey-type-\$\{item\.item_type\}/)
  assert.match(journeySection, /journeyDetailPanelRef/)
  assert.match(journeySection, /handlePointerDownOutsideDetail/)
  assert.match(journeySection, /closest\('\.skpe-journey-tree-item'\)/)
  assert.match(journeySection, /Concluída e validada/)
  assert.match(journeySection, /current_plan_start_date/)
  assert.match(journeySection, /proposal_start_date/)
  assert.match(journeySection, /row\.item_type === 'macrophase'/)
  assert.match(journeySection, /row\.item_status === 'in_progress'/)
  assert.doesNotMatch(journeySection, /row\.item_status === 'completed' \|\| row\.item_status === 'in_progress'/)
  assert.match(journeySection, /selectedItem\.item_type === 'macrophase' \? 'Condução metodológica' : 'Responsável'/)
})

test('cronograma nasce como sugestão metodológica editável e validável', () => {
  assert.match(planner, /buildSuggestedDrafts/)
  assert.match(planner, /Gerar cronograma sugerido/)
  assert.match(planner, /Aplicar sugestão metodológica às lacunas/)
  assert.match(planner, /pendente de validação do líder do projeto/)
  assert.match(planner, /p_source_mode: 'explicit'/)
})

test('Gantt institucional diferencia sugestão de datas canônicas', () => {
  assert.doesNotMatch(journeySection, /Gantt interativo Beta/)
  assert.doesNotMatch(svar, />Gantt interativo · Beta</)
  assert.match(gantt, /skpe-gantt-bar-suggested/)
  assert.match(gantt, /Sugestão metodológica/)
  assert.match(svar, /source: 'suggested'/)
  assert.match(svar, /getProjectableRange\(row\) \?\? suggestedRanges/)
})

test('roadmap de orçamento permanece separado da contabilidade corporativa', () => {
  const roadmap = readFileSync(join(testDir, '../../../docs/corporate/sk-pe/source/roadmap.md'), 'utf8')
  assert.match(roadmap, /Orçamento das Iniciativas e curvas físico-financeiras/)
  assert.match(roadmap, /sem substituir a contabilidade corporativa/)
})


test('cronograma usa Gantt visual e Smart Grid governado no planejamento', () => {
  assert.match(planner, /SvarJourneyGantt rows=\{schedulePreviewRows\}/)
  assert.match(planner, /<SparksSmartGrid/)
  assert.match(planner, /Cronograma sugerido/)
  assert.match(planner, /Planejamento detalhado/)
  assert.doesNotMatch(planner, /<table className="skpe-schedule-table">/)
})

test('Plano do Projeto separa planejamento de execucao e torna Recursos acionavel', () => {
  const projectPlan = readFileSync(join(testDir, '../src/modules/skpe/features/journey/JourneyProjectPlan.tsx'), 'utf8')
  assert.match(projectPlan, /Abrir execução do Projeto/)
  assert.match(projectPlan, /Planejamento continua nesta Jornada/)
  assert.match(projectPlan, /Gerenciar equipe, capacidade e alocações/)
  assert.match(projectPlan, /O que fazer aqui:/)
})
test('Gantt separa planejamento de execucao integrada com CTAs explicitos', () => {
  assert.match(gantt, /Editar cronograma da Jornada/)
  assert.match(gantt, /Agendar evento/)
  assert.match(gantt, /Abrir Kanban governado/)
  assert.match(gantt, /Abrir orçamento/)
  assert.match(gantt, /Abrir esforço/)
  assert.match(gantt, /Revisar recursos/)
  assert.match(gantt, /skpe-execution-zone/)
  assert.match(journeySection, /setProjectPlanInitialStage\('schedule'\)/)
  assert.match(journeySection, /setProjectPlanInitialStage\('resources'\)/)
})
