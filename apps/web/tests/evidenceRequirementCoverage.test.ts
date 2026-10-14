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
  assert.match(workspace, /Requisitos e evidências/)
  assert.match(workspace, /quantos requisitos têm arquivos associados e quantas evidências foram avaliadas/)
  assert.match(workspace, /A equipe avalia se cada evidência é suficiente considerando o requisito e seu contexto/)
  assert.match(workspace, /A quantidade de arquivos, por si só, não define essa avaliação/)
  assert.match(workspace, /Em uso estratégico/)
})

test('validated coverage is calculated only against required applicable operational requirements', () => {
  assert.match(workspace, /operationalChecklistRows\.filter\(\(row\) => row\.is_applicable\)/)
  assert.match(workspace, /applicable\.filter\(\(row\) => row\.is_required\)/)
  assert.match(workspace, /Number\(row\.validated_files_count\) > 0/)
  assert.match(workspace, /validated\.length \/ required\.length/)
})
