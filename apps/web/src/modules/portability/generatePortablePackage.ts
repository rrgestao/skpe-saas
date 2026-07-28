import JSZip from 'jszip'

import { createCanonicalWorkbook } from './generateCanonicalWorkbook'
import { createPortablePortal } from './generatePortablePortal'

type JsonObject = Record<string, unknown>

type ExportDocument = {
  manifesto?: JsonObject
  dados?: JsonObject
}

function safeSegment(value: unknown, fallback: string) {
  const normalized = String(value ?? fallback)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^A-Za-z0-9_-]+/g, '_')
    .replace(/^_+|_+$/g, '')
  return normalized || fallback
}

function jsonBlobToText(value: unknown) {
  return JSON.stringify(value, null, 2)
}

export async function createPortablePackage(document: ExportDocument) {
  const manifesto = (document.manifesto ?? {}) as JsonObject
  const dados = (document.dados ?? {}) as JsonObject
  const organizacao = (dados.organizacao ?? {}) as JsonObject
  const projeto = (dados.projeto ?? {}) as JsonObject

  const organizationCode = safeSegment(
    manifesto.organization_code ?? organizacao.code,
    'ORGANIZACAO',
  )
  const projectCode = safeSegment(
    manifesto.project_code ?? projeto.code,
    'PROJETO',
  )
  const timestamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\..+/, '').replace('T', '_')

  const structuredJson = jsonBlobToText(document)
  const { blob: workbookBlob, fileName: workbookFileName } = await createCanonicalWorkbook(document as Record<string, unknown>)
  const { blob: portalBlob, fileName: portalFileName } = createPortablePortal(document as Record<string, unknown>)

  const packageManifest = {
    package_schema: 'SPARKS_PE_PORTABLE_PACKAGE',
    package_schema_version: '1.0.0',
    generated_at: new Date().toISOString(),
    organization_code: organizationCode,
    project_code: projectCode,
    source_manifest: manifesto,
    contents: [
      { path: 'manifest.json', media_type: 'application/json' },
      { path: 'dados/dados_estruturados.json', media_type: 'application/json' },
      { path: `planilha/${workbookFileName}`, media_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' },
      { path: `portal/${portalFileName}`, media_type: 'text/html' },
      { path: 'documentos/LEIA-ME.txt', media_type: 'text/plain' },
    ],
    governance: {
      official_source_when_saas_is_active: 'Plataforma SPARKs',
      portal_mode: 'somente leitura',
      import_requires_validation: true,
      organization_isolation_required: true,
    },
  }

  const zip = new JSZip()
  zip.file('manifest.json', jsonBlobToText(packageManifest))
  zip.folder('dados')?.file('dados_estruturados.json', structuredJson)
  zip.folder('planilha')?.file(workbookFileName, workbookBlob)
  zip.folder('portal')?.file(portalFileName, portalBlob)

  const docs = zip.folder('documentos')
  docs?.file(
    'LEIA-ME.txt',
    [
      'PACOTE ESTRATEGICO PORTATIL SPARKs',
      '',
      `Organizacao: ${String(organizacao.name ?? organizacao.legal_name ?? organizationCode)}`,
      `Projeto: ${String(projeto.name ?? projectCode)}`,
      `Gerado em: ${new Date().toLocaleString('pt-BR')}`,
      '',
      'Este pacote contem o manifesto, os dados estruturados, a Planilha Canonica e o Portal HTML Portatil.',
      'Quando a organizacao opera no SaaS, a Plataforma SPARKs permanece como fonte oficial.',
      'Qualquer importacao deve passar por validacao, pre-visualizacao, tratamento de conflitos e confirmacao auditavel.',
    ].join('\n'),
  )
  docs?.folder('relatorios')?.file('LEIA-ME.txt', 'Relatorios Executivos e documentos de fase serao incluidos nesta pasta.')
  docs?.folder('apresentacoes')?.file('LEIA-ME.txt', 'Apresentacoes executivas serao incluidas nesta pasta.')
  docs?.folder('decisoes')?.file('LEIA-ME.txt', 'Decisoes executivas e registros de validacao serao incluidos nesta pasta.')
  docs?.folder('evidencias')?.file('LEIA-ME.txt', 'Evidencias documentais autorizadas serao incluidas nesta pasta.')
  docs?.folder('prompts')?.file('LEIA-ME.txt', 'Prompts de Gamma, continuidade e proxima fase serao incluidos nesta pasta.')

  const blob = await zip.generateAsync({
    type: 'blob',
    compression: 'DEFLATE',
    compressionOptions: { level: 6 },
    mimeType: 'application/zip',
  })

  return {
    blob,
    fileName: `SPARKs_PE_Pacote_${organizationCode}_${projectCode}_${timestamp}.zip`,
    metadata: {
      package_schema: 'SPARKS_PE_PORTABLE_PACKAGE',
      package_schema_version: '1.0.0',
      contains_json: true,
      contains_xlsx: true,
      contains_html: true,
      contains_document_structure: true,
      generated_locally_by_browser: true,
    },
  }
}
