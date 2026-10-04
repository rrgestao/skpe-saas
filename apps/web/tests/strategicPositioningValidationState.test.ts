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

test('human validation UI records append-only decisions without canonical mutation', () => {
  assert.match(section, /Registrar decisão humana/)
  assert.match(section, /<option value="keep">Manter<\/option>/)
  assert.match(section, /<option value="adjust">Ajustar<\/option>/)
  assert.match(section, /<option value="replace">Substituir<\/option>/)
  assert.match(section, /<option value="remove">Remover<\/option>/)
  assert.match(section, /record_skpe_positioning_validation_decision/)
  assert.match(section, /canonical_mutation_requested: false/)
  assert.match(section, /Decisão registrada\. O conteúdo canônico ainda não foi alterado\./)
})

test('validation controls use the canonical validation permission', () => {
  assert.match(section, /can_validate_skpe_formulation/)
  assert.match(section, /canValidate=\{canValidate\}/)
  assert.match(section, /Você pode consultar esta proposta, mas não possui permissão de validação/)
})
