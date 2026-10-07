import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const section = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)
const contract = readFileSync(
  new URL('../src/modules/skpe/contracts/journey.ts', import.meta.url),
  'utf8',
)

test('journey UI derives methodology locks from canonical unblock_dependencies metadata', () => {
  assert.match(contract, /unblock_dependencies/)
  assert.match(section, /\.from\('skpe_journey_items'\)/)
  assert.match(section, /\.select\('id,metadata'\)/)
  assert.match(section, /item\.metadata\?\.unblock_dependencies/)
  assert.match(section, /item\.metadata\?\.template_metadata\?\.unblock_dependencies/)
  assert.match(section, /required_status \?\? 'completed'/)
  assert.match(section, /Esta etapa permanece bloqueada até que/)
  assert.match(section, /statusDialogRequest !== null \|\| methodologyLocked/)
})

test('journey UI no longer hardcodes PEM-02 dependency pairs', () => {
  assert.doesNotMatch(section, /pem02DependencyByCode/)
  assert.doesNotMatch(section, /'PEM-02\.04': 'PEM-02\.03'/)
})
