import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const workspace = readFileSync(
  new URL('../src/modules/evidence/EvidenceManagementWorkspace.tsx', import.meta.url),
  'utf8',
)

test('evidence coverage uses the operational checklist rather than raw asset counts', () => {
  assert.match(workspace, /get_skpe_evidence_checklist/)
  assert.match(workspace, /files_count/)
  assert.match(workspace, /validated_files_count/)
  assert.match(workspace, /Requisitos obrigatórios aplicáveis/)
  assert.match(workspace, /Com arquivo vinculado/)
  assert.match(workspace, /Com arquivo validado/)
  assert.match(workspace, /Itens avaliados/)
})

test('evidence semantics keep availability, linkage, validation and sufficiency distinct', () => {
  assert.match(workspace, /Requisito ≠ arquivo ≠ evidência suficiente/)
  assert.match(workspace, /Arquivo vinculado não é tratado automaticamente como evidência validada ou suficiente/)
  assert.match(workspace, /Suficiência permanece uma avaliação contextual governada/)
  assert.match(workspace, /não é derivada da quantidade de arquivos nem do percentual de cobertura/)
  assert.match(workspace, /Em uso estratégico/)
})

test('validated coverage is calculated only against required applicable operational requirements', () => {
  assert.match(workspace, /operationalChecklistRows\.filter\(\(row\) => row\.is_applicable\)/)
  assert.match(workspace, /applicable\.filter\(\(row\) => row\.is_required\)/)
  assert.match(workspace, /Number\(row\.validated_files_count\) > 0/)
  assert.match(workspace, /validated\.length \/ required\.length/)
})
