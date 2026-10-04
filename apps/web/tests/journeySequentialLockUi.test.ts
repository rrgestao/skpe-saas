import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const section = readFileSync(
  new URL('../src/modules/skpe/features/journey/JourneySection.tsx', import.meta.url),
  'utf8',
)

test('PEM-02 UI mirrors the canonical sequential lock', () => {
  assert.match(section, /'PEM-02\.02': 'PEM-02\.01'/)
  assert.match(section, /'PEM-02\.03': 'PEM-02\.02'/)
  assert.match(section, /'PEM-02\.04': 'PEM-02\.03'/)
  assert.match(section, /'PEM-02\.05': 'PEM-02\.04'/)
  assert.match(section, /'PEM-02\.GATE': 'PEM-02\.05'/)
  assert.match(section, /Bloqueado metodologicamente/)
  assert.match(section, /statusDialogRequest !== null \|\| methodologyLocked/)
})
