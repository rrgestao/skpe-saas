import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const panel = readFileSync(
  join(testDir, '../src/modules/skpe/features/monitoring/MonitoringStrategyReviewPanel.tsx'),
  'utf8',
)
const section = readFileSync(
  join(testDir, '../src/modules/skpe/features/monitoring/MonitoringSection.tsx'),
  'utf8',
)

test('G4C preserva RAE, análise, decisão e aprendizado como contratos distintos', () => {
  assert.match(panel, /upsert_skpe_strategy_review/)
  assert.match(panel, /upsert_skpe_strategy_review_item/)
  assert.match(panel, /record_skpe_governance_decision/)
  assert.match(panel, /record_skpe_strategic_learning/)
})

test('G4C mantém ratificação humana separada da edição da RAE', () => {
  assert.match(panel, /ratify_skpe_strategy_review/)
  assert.match(panel, /can_ratify_skpe_governance/)
  assert.match(panel, /RAE ratificada humanamente/)
})

test('G4C exige responsável e prazo para decisão de alta criticidade', () => {
  assert.match(panel, /\['high', 'critical'\]/)
  assert.match(panel, /Decisão de alta criticidade exige responsável e prazo/)
  assert.match(panel, /responsibleUserId/)
  assert.match(panel, /dueDate/)
})

test('G4C só opera quando existe ciclo real selecionado', () => {
  assert.match(section, /MonitoringStrategyReviewPanel/)
  assert.match(section, /cycleId=\{effectiveCycleId\}/)
})
