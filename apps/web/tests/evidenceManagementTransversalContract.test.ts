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
const skpeEvidenceFoundation = readFileSync(
  join(
    testDir,
    '../../../supabase/migrations/20260727023000_create_initiatives_business_artifacts_checklist_intelligence.sql',
  ),
  'utf8',
)

test('Gestão de Evidências preserva acervo transversal e contexto analítico do SK-PE', () => {
  assert.match(evidenceWorkspace, /export function EvidenceManagementWorkspace/)
  assert.match(evidenceWorkspace, /Checklist de evidências e downloads/)
  assert.match(evidenceWorkspace, /grandes eixos de governança e gestão/)
  assert.match(evidenceWorkspace, /Critérios e práticas de referência/)
  assert.match(evidenceWorkspace, /Requisitos e práticas/)
  assert.match(evidenceWorkspace, /Abrir manutenção/)
  assert.match(evidenceWorkspace, /onActivate=\{activeFilter === 'expected' \? undefined : openEvidenceMaintenance\}/)
  assert.match(evidenceWorkspace, /Associar a eixo \/ requisito do PEM-00/)
  assert.match(evidenceWorkspace, /register_skpe_checklist_item_file/)
  assert.match(evidenceWorkspace, /link_sparks_evidence/)
  assert.match(evidenceWorkspace, /Referência da fonte original/)
  assert.match(evidenceWorkspace, /source_payload/)
  assert.match(evidenceWorkspace, /source_sheet/)
  assert.match(evidenceWorkspace, /source_external_key/)
  assert.match(evidenceWorkspace, /O SK-DOC governa o documento e suas versões/)
  assert.match(evidenceWorkspace, /O SK-PE registra o vínculo com este requisito/)
  assert.match(diagnosis, /from '\.\.\/\.\.\/\.\.\/evidence\/EvidenceManagementWorkspace'/)
  assert.doesNotMatch(diagnosis, /StrategicEvidenceSection/)
})

test('SK-PE mantém registro documental e análise de aderência sem duplicar a autoridade do SK-DOC', () => {
  assert.match(skpeEvidenceFoundation, /create table public\.skpe_evidence_checklist_item_files/)
  assert.match(skpeEvidenceFoundation, /Arquivos e documentos vinculados aos itens do checklist/)
  assert.match(skpeEvidenceFoundation, /create table public\.skpe_evidence_checklist_assessments/)
  assert.match(skpeEvidenceFoundation, /Hist.rico versionado das avalia..es dos itens do checklist/i)
})

test('roadmap preserva foco e posterga Boas-vindas e telas de Organização', () => {
  assert.match(roadmap, /Capability transversal — Gestão de Evidências/)
  assert.match(roadmap, /Boas-vindas/)
  assert.match(roadmap, /Meu Espaço de Trabalho \/ seleção de Organizações/)
  assert.match(roadmap, /COOTAQUARA/)
  assert.match(roadmap, /QUERUBIM/)
  assert.match(roadmap, /COOPERCOMPANY/)
})
