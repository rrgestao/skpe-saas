import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

const preview = readFileSync(
  new URL('../src/modules/evidence/EvidenceFilePreview.tsx', import.meta.url),
  'utf8',
)
const workspace = readFileSync(
  new URL('../src/modules/evidence/EvidenceManagementWorkspace.tsx', import.meta.url),
  'utf8',
)

test('evidence viewer keeps files private and loads preview through Supabase storage', () => {
  assert.match(preview, /supabase\.storage/)
  assert.match(preview, /\.download\(storagePath\)/)
  assert.doesNotMatch(preview, /createSignedUrl/)
  assert.doesNotMatch(preview, /officeapps\.live\.com/)
  assert.doesNotMatch(preview, /docs\.google\.com/)
})

test('viewer supports common evidence formats without pretending unsupported binaries are renderable', () => {
  assert.match(preview, /'pdf'/)
  assert.match(preview, /'image'/)
  assert.match(preview, /'md'/)
  assert.match(preview, /'xlsx'/)
  assert.match(preview, /'xlsm'/)
  assert.match(preview, /'docx'/)
  assert.match(preview, /'pptx'/)
  assert.match(preview, /Este formato não possui visualização interna segura/)
})

test('Office preview is generated locally from existing dependencies', () => {
  assert.match(preview, /import\('exceljs'\)/)
  assert.match(preview, /import\('jszip'\)/)
  assert.match(preview, /word\/document\.xml/)
  assert.match(preview, /ppt\\\/slides\\\/slide/)
  assert.match(preview, /PowerPoint · conteúdo textual dos slides/)
  assert.match(preview, /Word · conteúdo textual/)
})

test('evidence maintenance embeds current and prior physical-file previews and preserves download', () => {
  assert.match(workspace, /<EvidenceFilePreview/)
  assert.match(workspace, /Prévia do arquivo/)
  assert.match(workspace, /Baixar arquivo/)
  assert.match(workspace, /storageBucket=\{version\.storage_bucket\}/)
  assert.match(workspace, /storagePath=\{version\.storage_path\}/)
  assert.match(workspace, /setPreviewVersionId/)
  assert.match(workspace, /Versão selecionada/)
  assert.match(workspace, /Fechar prévia/)
  assert.match(workspace, /storageBucket=\{previewVersion\.storage_bucket\}/)
  assert.match(workspace, /storagePath=\{previewVersion\.storage_path\}/)
})
