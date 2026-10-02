import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = dirname(fileURLToPath(import.meta.url))
const evidenceWorkspace = readFileSync(
  join(testDir, '../src/modules/evidence/EvidenceManagementWorkspace.tsx'),
  'utf8',
)
const diagnosis = readFileSync(
  join(testDir, '../src/modules/skpe/features/diagnosis/StrategicDiagnosisSection.tsx'),
  'utf8',
)
const roadmap = readFileSync(
  join(testDir, '../../../docs/corporate/sk-pe/source/roadmap.md'),
  'utf8',
)

test('Gestão de Evidências possui autoridade transversal fora do SK-PE', () => {
  assert.match(evidenceWorkspace, /export function EvidenceManagementWorkspace/)
  assert.match(evidenceWorkspace, /Checklist de evidências e downloads/)
  assert.match(evidenceWorkspace, /grandes eixos de governança e gestão/)
  assert.match(evidenceWorkspace, /Critérios \/ práticas de referência/)
  assert.match(evidenceWorkspace, /Downloads disponíveis/)
  assert.match(evidenceWorkspace, /Analisar/)
  assert.match(evidenceWorkspace, /selectedEvidenceAssetId/)
  assert.match(evidenceWorkspace, /A consulta e análise permanecem disponíveis mesmo sem arquivo materializado/)
  assert.match(diagnosis, /from '\.\.\/\.\.\/\.\.\/evidence\/EvidenceManagementWorkspace'/)
  assert.doesNotMatch(diagnosis, /StrategicEvidenceSection/)
})

test('roadmap preserva foco e posterga Boas-vindas e telas de Organização', () => {
  assert.match(roadmap, /Capability transversal — Gestão de Evidências/)
  assert.match(roadmap, /Boas-vindas/)
  assert.match(roadmap, /Meu Espaço de Trabalho \/ seleção de Organizações/)
  assert.match(roadmap, /COOTAQUARA/)
  assert.match(roadmap, /QUERUBIM/)
  assert.match(roadmap, /COOPERCOMPANY/)
})
