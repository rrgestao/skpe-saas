import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

for (const [file, macro] of [
  ['Pem03GatePanel.tsx','3'],
  ['Pem04GatePanel.tsx','4'],
  ['Pem05GatePanel.tsx','5'],
] as const) {
  test('Macrofase ' + macro + ' validation point uses business-facing language', () => {
    const panel = readFileSync(new URL('../src/modules/skpe/features/journey/' + file, import.meta.url), 'utf8')
    assert.match(panel, /<small>Ponto de validação<\/small>/)
    assert.match(panel, new RegExp('Macrofase ' + macro + ' concluída'))
    assert.doesNotMatch(panel, new RegExp('<small>PEM-0' + macro + '\\.GATE<\\/small>'))
    assert.doesNotMatch(panel, /sem identificador/)
    assert.doesNotMatch(panel, /Pendência identificada pelo backend/)
    assert.match(panel, /Decisão institucional registrada:/)
  })
}
