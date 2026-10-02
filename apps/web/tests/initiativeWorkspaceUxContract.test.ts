import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = dirname(fileURLToPath(import.meta.url))
const cockpit = readFileSync(join(root, '../src/modules/skpe/SkpeCockpit.tsx'), 'utf8')
const kanban = readFileSync(join(root, '../src/modules/initiatives/kanban/InitiativeKanbanBoard.tsx'), 'utf8')
const kanbanCss = readFileSync(join(root, '../src/modules/initiatives/kanban/InitiativeKanbanBoard.css'), 'utf8')
const economics = readFileSync(join(root, '../src/modules/initiatives/economics/InitiativeEconomicExecutionDialog.tsx'), 'utf8')
const workspaceCss = readFileSync(join(root, '../src/modules/initiatives/InitiativeWorkspace.css'), 'utf8')

test('Kanban oferece navegação horizontal explícita', () => {
  assert.match(kanban, /initiative-kanban-scroll-controls/)
  assert.match(kanban, /scrollBoardHorizontally/)
  assert.match(kanban, /scrollBoardToEdge/)
  assert.match(kanbanCss, /UX-KANBAN-04/)
})

test('manutenção lateral usa X, ESC e clique fora', () => {
  assert.match(cockpit, /skpe-initiative-detail-frame__close/)
  assert.match(cockpit, /event\.key !== 'Escape'/)
  assert.match(cockpit, /target\.closest\('\.skpe-initiative-detail-frame'\)/)
  assert.doesNotMatch(cockpit, />\s*Fechar\s*<\/button>[\s\S]{0,120}skpe-initiative-detail-frame/)
})
test('workspace econômico tem retorno e não herda drawer fixo', () => {
  assert.match(economics, /Voltar ao Kanban/)
  assert.match(economics, /Orçamento e execução da iniciativa/)
  assert.match(workspaceCss, /INITIATIVE-ECONOMICS-UX-08/)
  assert.match(workspaceCss, /position:\s*static\s*!important/)
})

test('workspace de iniciativas respeita o acento contextual da Organização', () => {
  assert.doesNotMatch(workspaceCss, /#ff4f0c/i)
  assert.doesNotMatch(kanbanCss, /#ff4f0c/i)
  assert.match(kanbanCss, /accent-color:\s*var\(--organization-accent/)
  assert.match(kanbanCss, /var\(--organization-primary/)
})
