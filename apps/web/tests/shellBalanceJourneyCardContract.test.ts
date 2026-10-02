import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const css = readFileSync(
  join(testDir, '../src/modules/skpe/SkpeCockpit.css'),
  'utf8',
)

test('desktop shell usa padding horizontal simétrico', () => {
  assert.match(css, /@media \(min-width: 1181px\)[\s\S]*?\.skpe-main \{[\s\S]*?padding-right: 1rem !important;[\s\S]*?padding-left: 1rem !important;/)
  assert.match(css, /\.skpe-main > \.skpe-cockpit-header \{[\s\S]*?margin-right: -1rem !important;[\s\S]*?margin-left: -1rem !important;/)
})

test('cards da Jornada seguem o contrato visual do Monitoramento', () => {
  assert.match(css, /\.skpe-journey-summary-card \{[\s\S]*?min-height: 104px !important;/)
  assert.match(css, /\.skpe-journey-summary-card > span:first-child \{[\s\S]*?font-weight: 750 !important;/)
  assert.match(css, /JOURNEY SUMMARY GRID V3[\s\S]*?\.skpe-journey-summary-grid-primary \{[\s\S]*?repeat\(3, minmax\(0, 1fr\)\)/)
  assert.match(css, /\.skpe-journey-summary-grid-primary > \.skpe-journey-summary-card,[\s\S]*?grid-column: auto !important;/)
  assert.match(css, /\.skpe-journey-summary-card > strong \{[\s\S]*?font-weight: 800 !important;/)
  assert.match(css, /\.skpe-journey-summary-stack,[\s\S]*?width: 100%;[\s\S]*?max-width: none !important;/)
})
