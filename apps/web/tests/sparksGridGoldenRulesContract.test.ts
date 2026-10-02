import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync, readdirSync, statSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const smartGrid = readFileSync(
  join(testDir, '../src/components/design-system/SparksSmartGrid.tsx'),
  'utf8',
)
const smartGridCss = readFileSync(
  join(testDir, '../src/components/design-system/SparksSmartGrid.css'),
  'utf8',
)
const cockpit = readFileSync(
  join(testDir, '../src/modules/skpe/SkpeCockpit.tsx'),
  'utf8',
)

test('GRID SPARKs mantém linhas compactas sem autoexpansão', () => {
  assert.match(smartGrid, /autoRowHeight = false/)
  assert.match(smartGridCss, /white-space:\s*nowrap\s*!important/)
  assert.match(smartGridCss, /text-overflow:\s*ellipsis\s*!important/)
})
test('GRID SPARKs mantém colunas redimensionáveis por padrão', () => {
  assert.match(smartGrid, /resize:\s*column\.resizable !== false/)
  assert.match(smartGridCss, /preserve the official SVAR resize grip/)
  assert.match(smartGridCss, /\.wx-grip/)
})

test('GRID SPARKs preserva seleção em um clique e manutenção em duplo clique', () => {
  assert.ok(smartGrid.includes("api.on?.('select-row'"))
  assert.ok(smartGrid.includes("api.on?.('open-editor'"))
  assert.match(smartGrid, /selectAndRevealRow\(rowId\)/)
  assert.match(smartGrid, /activateRow\(rowId\)/)
  assert.doesNotMatch(smartGrid, /dblclick-row|double-click-row/)
})

test('GRID SPARKs mantém navegação por teclado e seleção visual canônica', () => {
  assert.match(smartGrid, /event\.key === 'ArrowDown'/)
  assert.match(smartGrid, /event\.key === 'ArrowLeft'/)
  assert.match(smartGrid, /event\.key === 'PageDown'/)
  assert.match(smartGrid, /sparks-smart-grid__row-selected/)
  assert.match(smartGridCss, /GRID-CANON-07 - seleção visual/)
})

test('rascunho sugerido não é enviado diretamente ao workspace operacional', () => {
  assert.match(cockpit, /const isDraft =/)
  assert.match(cockpit, /openSuggestedDraftReview\(initiative\)/)
  assert.match(cockpit, /proposal_origin === 'sparks_suggestion'/)
  assert.match(cockpit, /setSelectedPortfolioInitiativeId\(initiative\.initiative_id\)/)
})

test('valores canônicos exibidos no GRID passam por apresentação PT-BR', () => {
  assert.match(cockpit, /other:\s*'Outro vínculo'/)
  assert.match(cockpit, /relationshipTypeLabel\(person\.relationship_type\)/)
})

test('alterações das golden rules exigem decisão humana explícita', () => {
  assert.match(smartGridCss, /GRID-CANON-05 - Golden rules/)
})

test('somente SparksSmartGrid pode importar SVAR Grid diretamente', () => {
  const srcRoot = join(testDir, '../src')
  const offenders: string[] = []
  const visit = (dir: string) => {
    for (const name of readdirSync(dir)) {
      const path = join(dir, name)
      if (statSync(path).isDirectory()) {
        visit(path)
        continue
      }
      if (!name.endsWith('.tsx')) continue
      if (path.endsWith(join('components', 'design-system', 'SparksSmartGrid.tsx'))) continue
      const source = readFileSync(path, 'utf8')
      if (source.includes("from '@svar-ui/react-grid'")) offenders.push(path)
    }
  }
  visit(srcRoot)
  assert.deepEqual(offenders, [])
})
