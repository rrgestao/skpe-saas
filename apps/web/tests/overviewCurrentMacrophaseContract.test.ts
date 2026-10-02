import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const cockpit = readFileSync(
  join(testDir, '../src/modules/skpe/SkpeCockpit.tsx'),
  'utf8',
)

test('Visão Geral deriva a macrofase corrente e próximo marco da Jornada governada', () => {
  assert.match(cockpit, /const currentMacrophase =/)
  assert.match(cockpit, /row\.is_current/)
  assert.match(cockpit, /row\.item_status === 'in_progress'/)
  assert.match(cockpit, /belongsToCurrentMacrophase/)
  assert.match(cockpit, /unfinishedCurrentRows\.find\(\(row\) => row\.item_type === 'gate'\)/)
  assert.match(cockpit, /currentMacrophaseTargetDate/)
  assert.match(cockpit, /nextMilestoneName/)
  assert.match(cockpit, /onJourneyDrilldown=\{\(\) => onNavigate\('journey'\)\}/)
})
