import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const admin = readFileSync(
  new URL('../src/modules/portability/PortabilityAdmin.tsx', import.meta.url),
  'utf8',
)
const preview = readFileSync(
  new URL('../src/modules/portability/CanonicalWorkbookImportPreview.tsx', import.meta.url),
  'utf8',
)
const parser = readFileSync(
  new URL('../src/modules/portability/parseCanonicalWorkbook.ts', import.meta.url),
  'utf8',
)
const staging = readFileSync(
  new URL('../src/modules/portability/CanonicalImportStaging.tsx', import.meta.url),
  'utf8',
)
const edge = readFileSync(
  new URL('../../../supabase/functions/skpe-import-incorporation/index.ts', import.meta.url),
  'utf8',
)
const portablePackage = readFileSync(
  new URL('../src/modules/portability/generatePortablePackage.ts', import.meta.url),
  'utf8',
)

test('portability no longer hard-codes a customer as product authority', () => {
  assert.doesNotMatch(preview, /bloqueada para organizações diferentes da COOTAQUARA/)
  assert.match(preview, /parseCanonicalWorkbook\(file, selectedOrganization\)/)
  assert.match(parser, /expectedOrganization/)
  assert.match(parser, /não corresponde à organização selecionada/)
})

test('exports explicitly remain interchange outputs rather than hidden product authority', () => {
  assert.match(portablePackage, /official_source_when_saas_is_active: 'Plataforma SPARKs'/)
  assert.match(portablePackage, /import_requires_validation: true/)
  assert.match(preview, /A planilha é um meio de intercâmbio/)
  assert.match(admin, /prévia, área de conferência, simulação, revisão humana e materialização governada/)
})

test('import flow separates staging, decision and explicit governed materialization', () => {
  assert.match(staging, /Nenhuma tabela estratégica definitiva foi alterada/)
  assert.match(staging, /Aprovar informação/)
  assert.match(staging, /Executar incorporação governada/)
  assert.match(staging, /Nenhum arquivo importado se torna autoridade apenas por ter sido enviado à área de conferência/)
  assert.match(edge, /materialize_request/)
  assert.match(edge, /skpe_execute_governed_import_materialization/)
  assert.match(edge, /human_confirmation: true/)
  assert.match(edge, /semantic_inference: false/)
})

test('materialization is never triggered by review or decision alone', () => {
  assert.match(edge, /action: 'review_item'[\s\S]*?materialization_requested: false/)
  assert.match(edge, /action: 'decide_request'[\s\S]*?materialization_requested: false/)
  assert.match(edge, /if \(payload\.action === 'materialize_request'\)/)
})
