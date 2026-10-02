import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const diagnosis = readFileSync(join(testDir, '../src/modules/skpe/features/diagnosis/StrategicDiagnosisSection.tsx'), 'utf8')
const css = readFileSync(join(testDir, '../src/modules/skpe/features/diagnosis/StrategicDiagnosisSection.css'), 'utf8')

test('Diagnóstico remove cabeçalho redundante e concentra validação no card executivo', () => {
  assert.doesNotMatch(diagnosis, /Leitura integrada do contexto estratégico/)
  assert.doesNotMatch(diagnosis, /skpe-strategic-diagnosis-header/)
  assert.doesNotMatch(diagnosis, /skpe-strategic-diagnosis-validation-stamp/)
  assert.match(diagnosis, /skpe-strategic-diagnosis-validation-card/)
  assert.match(diagnosis, /validationLabel\(diagnosisMacrophase\.validation_status\)/)
  assert.match(css, /\.skpe-strategic-diagnosis-validation-card/)
})