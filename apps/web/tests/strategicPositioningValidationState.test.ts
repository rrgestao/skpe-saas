import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const section = readFileSync(
  new URL('../src/modules/skpe/features/strategy/StrategicPositioningSection.tsx', import.meta.url),
  'utf8',
)

test('PEM-02.03 labels themes and perspectives as validation content', () => {
  assert.match(section, /PEM-02\.03 · Escolhas e Posicionamento Estratégico/)
  assert.match(section, /Conteúdo materializado não equivale a aprovação institucional/)
  assert.match(section, /Temas Estratégicos em validação/)
  assert.match(section, /Perspectivas Estratégicas em validação/)
  assert.match(section, /validationLabel\(theme\.metadata, theme\.status\)/)
  assert.match(section, /validationLabel\(perspective\.metadata, perspective\.status\)/)
})

test('PEM-02.04 objectives stay visibly blocked while positioning is pending', () => {
  assert.match(section, /Próxima etapa · PEM-02\.04/)
  assert.match(section, /Objetivos Estratégicos — prévia bloqueada/)
  assert.match(section, /não fazem parte da validação desta etapa/)
  assert.match(section, /validationLabel\(objective\.metadata, objective\.status\)/)
})
