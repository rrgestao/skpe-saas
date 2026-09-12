import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync, readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const platformAdminDir = join(testDir, '../src/modules/platform-admin')
const platformAdminFiles = readdirSync(platformAdminDir)
  .filter((name) => name.endsWith('.tsx'))
  .map((name) => ({
    name,
    content: readFileSync(join(platformAdminDir, name), 'utf8'),
  }))
const platformAdmin = platformAdminFiles.find((file) => file.name === 'PlatformAdmin.tsx')?.content ?? ''
const measureCatalog = platformAdminFiles.find((file) => file.name === 'PlatformMeasureCatalog.tsx')?.content ?? ''
const smartGridCss = readFileSync(
  join(testDir, '../src/components/design-system/SparksSmartGrid.css'),
  'utf8',
)

test('Administração da Plataforma usa somente o grid canônico nas listagens', () => {
  for (const file of platformAdminFiles) {
    assert.equal(file.content.includes('<table'), false, `${file.name} reintroduziu tabela HTML`)
    assert.equal(file.content.includes('@svar-ui/react-grid'), false, `${file.name} contornou SparksSmartGrid`)
  }
  assert.ok((platformAdmin.match(/<SparksSmartGrid/g) ?? []).length >= 8)
  assert.ok(measureCatalog.includes('<SparksSmartGrid'))
})
test('grid canônico preserva cabeçalho fixo', () => {
  assert.match(smartGridCss, /position:\s*sticky/)
  assert.match(smartGridCss, /top:\s*0\s*!important/)
})
test('cards da visão geral permanecem acionáveis e roteiam para os cadastros', () => {
  assert.match(platformAdmin, /className="pa-summary-card"[\s\S]*openAdminTab\('organizations'\)/)
  assert.match(platformAdmin, /className="pa-summary-card"[\s\S]*openAdminTab\('users'\)/)
  assert.match(platformAdmin, /className="pa-summary-card"[\s\S]*openAdminTab\('memberships'\)/)
  assert.match(platformAdmin, /className="pa-summary-card"[\s\S]*openAdminTab\('modules'\)/)
  assert.match(platformAdmin, /className="pa-summary-card"[\s\S]*openAdminTab\('invitations'\)/)
  assert.match(platformAdmin, /className="pa-quick-grid"/)
})

test('atalho de voltar ao topo só aparece depois de rolagem real', () => {
  assert.match(platformAdmin, /const \[showScrollTop, setShowScrollTop\] = useState\(false\)/)
  assert.match(platformAdmin, /setShowScrollTop\(getScrollTop\(\) > 180\)/)
  assert.match(platformAdmin, /\{showScrollTop \? \(/)
  assert.match(platformAdmin, /<path d="M5 15\.5 12 8l7 7\.5"/)
})
