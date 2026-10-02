import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const grid = readFileSync(
  join(testDir, '../src/modules/skpe/features/diagnosis/StrategicRisksSmartGrid.tsx'),
  'utf8',
)
const diagnosis = readFileSync(
  join(testDir, '../src/modules/skpe/features/diagnosis/StrategicDiagnosisSection.tsx'),
  'utf8',
)
const cockpit = readFileSync(
  join(testDir, '../src/modules/skpe/SkpeCockpit.tsx'),
  'utf8',
)
const evidence = readFileSync(
  join(testDir, '../src/modules/evidence/EvidenceManagementWorkspace.tsx'),
  'utf8',
)
const roadmap = readFileSync(
  join(testDir, '../../../docs/corporate/sk-pe/source/roadmap.md'),
  'utf8',
)

test('duplo clique em risco preserva rastreabilidade para iniciativa associada', () => {
  assert.match(grid, /onDoubleClick=/)
  assert.match(grid, /onOpenAssociatedInitiative/)
  assert.match(diagnosis, /onOpenRiskInitiative/)
  assert.match(cockpit, /openRiskInitiativeByCode/)
  assert.match(cockpit, /skpe_sparks_suggested_initiative_readiness/)
  assert.match(cockpit, /contains\('source_risk_codes', \[riskCode\]\)/)
  assert.match(cockpit, /setInitiativeDrilldown/)
  assert.match(cockpit, /setInitiativeWorkspaceTab\('kanban'\)/)
})

test('Gestão de Evidências preserva autoridade SK-DOC e SK-KM fora do SK-PE', () => {
  assert.match(evidence, /SK-DOC governa documentos, evidências e versões/)
  assert.match(evidence, /SK-KM sustenta conhecimento/)
  assert.match(evidence, /fatos e dados, não de achismos/)
  assert.match(roadmap, /Evidências e documentos \*\*nunca pertencem ao domínio do SK-PE\*\*/)
  assert.match(roadmap, /Ingestão inteligente de evidências por diretório\/conector/)
  assert.match(roadmap, /SharePoint/)
})
