import JSZip from 'jszip'
import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../lib/supabase'
import {
  artifactTypeLabelPtBr,
  statusLabelPtBr,
  translateBackendMessage,
} from '../../shared/i18n/ptBR'

import './DeliveryKitDialog.css'

type Props = {
  organizationId: string
  projectId: string
  onClose: () => void
}

type Artifact = {
  artifact_id: string
  artifact_code: string
  artifact_type_code: string
  artifact_type_name: string
  title: string
  purpose: string | null
  metafase_code: string | null
  macrophase_code: string | null
  phase_code: string | null
  stage_code: string | null
  gate_code: string | null
  status: string
  current_version_number: number
  validated_at: string | null
}

type ArtifactDetail = {
  versions: Array<Record<string, unknown>>
  validations: Array<Record<string, unknown>>
}

const VALIDATED_STATUSES = new Set(['validated', 'validated_with_reservations'])

function safeSegment(value: unknown, fallback: string) {
  const normalized = String(value ?? fallback)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^A-Za-z0-9._-]+/g, '_')
    .replace(/^_+|_+$/g, '')
  return normalized || fallback
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  return new Intl.DateTimeFormat('pt-BR', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
}

async function sha256Blob(blob: Blob) {
  const buffer = await blob.arrayBuffer()
  const hash = await crypto.subtle.digest('SHA-256', buffer)
  return Array.from(new Uint8Array(hash)).map((byte) => byte.toString(16).padStart(2, '0')).join('')
}

function downloadBlob(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = fileName
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  URL.revokeObjectURL(url)
}

function markdownBlob(content: string) {
  return new Blob([content], { type: 'text/markdown;charset=utf-8' })
}

export function DeliveryKitDialog({ organizationId, projectId, onClose }: Props) {
  const [artifacts, setArtifacts] = useState<Artifact[]>([])
  const [selectedIds, setSelectedIds] = useState<Set<string>>(() => new Set())
  const [search, setSearch] = useState('')
  const [phaseFilter, setPhaseFilter] = useState('')
  const [loading, setLoading] = useState(true)
  const [generating, setGenerating] = useState(false)
  const [message, setMessage] = useState('')

  useEffect(() => {
    const load = async () => {
      setLoading(true)
      const { data, error } = await supabase.rpc('get_project_methodology_artifacts', {
        target_organization_id: organizationId,
        target_project_id: projectId,
        target_status: null,
        target_phase_code: null,
      })
      if (error) {
        console.error(error)
        setMessage(translateBackendMessage(error.message))
        setLoading(false)
        return
      }
      const rows = (data ?? []) as Artifact[]
      setArtifacts(rows)
      setSelectedIds(new Set(rows.filter((item) => VALIDATED_STATUSES.has(item.status)).map((item) => item.artifact_id)))
      setLoading(false)
    }
    void load()
  }, [organizationId, projectId])

  const phases = useMemo(
    () => Array.from(new Set(artifacts.map((item) => item.phase_code ?? item.macrophase_code ?? item.metafase_code).filter(Boolean) as string[])).sort(),
    [artifacts],
  )

  const visibleArtifacts = useMemo(() => {
    const term = search.trim().toLocaleLowerCase('pt-BR')
    return artifacts.filter((item) => {
      const phase = item.phase_code ?? item.macrophase_code ?? item.metafase_code ?? ''
      const matchesPhase = !phaseFilter || phase === phaseFilter
      const matchesSearch = !term || [item.title, item.artifact_code, item.artifact_type_name, phase]
        .join(' ')
        .toLocaleLowerCase('pt-BR')
        .includes(term)
      return matchesPhase && matchesSearch
    }).sort((a, b) => a.title.localeCompare(b.title, 'pt-BR'))
  }, [artifacts, phaseFilter, search])

  const toggle = (artifactId: string) => {
    setSelectedIds((current) => {
      const next = new Set(current)
      if (next.has(artifactId)) next.delete(artifactId)
      else next.add(artifactId)
      return next
    })
  }

  const loadDetail = async (artifactId: string) => {
    const { data, error } = await supabase.rpc('get_methodology_artifact_detail', { target_artifact_id: artifactId })
    if (error) throw error
    return data as ArtifactDetail
  }

  const versionBlob = async (version: Record<string, unknown>) => {
    const bucket = version.storage_bucket as string | null
    const path = version.storage_path as string | null
    if (bucket && path) {
      const { data, error } = await supabase.storage.from(bucket).download(path)
      if (error) throw error
      return data
    }
    const content = String(version.content_markdown ?? '')
    if (content) return markdownBlob(content)
    throw new Error('O artefato não possui arquivo ou conteúdo disponível.')
  }

  const currentVersion = async (artifact: Artifact) => {
    const detail = await loadDetail(artifact.artifact_id)
    const version = detail.versions?.[0]
    if (!version) throw new Error('O artefato ainda não possui versão registrada.')
    return { detail, version }
  }

  const visualize = async (artifact: Artifact) => {
    try {
      const { version } = await currentVersion(artifact)
      const blob = await versionBlob(version)
      const url = URL.createObjectURL(blob)
      window.open(url, '_blank', 'noopener,noreferrer')
      window.setTimeout(() => URL.revokeObjectURL(url), 120000)
    } catch (error) {
      console.error(error)
      setMessage(translateBackendMessage(error instanceof Error ? error.message : String(error)))
    }
  }

  const download = async (artifact: Artifact) => {
    try {
      const { version } = await currentVersion(artifact)
      const blob = await versionBlob(version)
      const extension = String(version.file_extension ?? 'md').replace(/^\./, '') || 'md'
      const fileName = String(version.file_name ?? `${safeSegment(artifact.artifact_code, 'ARTEFATO')}_v${artifact.current_version_number}.${extension}`)
      downloadBlob(blob, fileName)
    } catch (error) {
      console.error(error)
      setMessage(translateBackendMessage(error instanceof Error ? error.message : String(error)))
    }
  }

  const printArtifact = async (artifact: Artifact) => {
    try {
      const { version } = await currentVersion(artifact)
      const blob = await versionBlob(version)
      const url = URL.createObjectURL(blob)
      const popup = window.open(url, '_blank')
      if (!popup) throw new Error('O navegador bloqueou a janela de impressão.')
      popup.addEventListener('load', () => popup.print(), { once: true })
      window.setTimeout(() => URL.revokeObjectURL(url), 120000)
    } catch (error) {
      console.error(error)
      setMessage(translateBackendMessage(error instanceof Error ? error.message : String(error)))
    }
  }

  const generateKit = async () => {
    const selectedArtifacts = artifacts.filter((artifact) => selectedIds.has(artifact.artifact_id))
    if (selectedArtifacts.length === 0) {
      setMessage('Selecione ao menos um artefato para gerar o Kit de Entregas.')
      return
    }

    setGenerating(true)
    setMessage('Preparando o Kit de Entregas...')
    try {
      const zip = new JSZip()
      const manifestItems: Array<Record<string, unknown>> = []
      const indexRows: string[] = []

      for (const artifact of selectedArtifacts) {
        const { detail, version } = await currentVersion(artifact)
        const blob = await versionBlob(version)
        const hash = await sha256Blob(blob)
        const phase = artifact.phase_code ?? artifact.macrophase_code ?? artifact.metafase_code ?? 'SEM_FASE'
        const extension = String(version.file_extension ?? 'md').replace(/^\./, '') || 'md'
        const originalName = String(version.file_name ?? `${artifact.artifact_code}_v${artifact.current_version_number}.${extension}`)
        const folder = safeSegment(phase, 'SEM_FASE')
        const fileName = `${safeSegment(artifact.artifact_code, 'ARTEFATO')}_${safeSegment(originalName, `versao.${extension}`)}`
        const path = `${folder}/${fileName}`
        zip.file(path, blob)

        const latestValidation = detail.validations?.[0] ?? null
        manifestItems.push({
          artifact_id: artifact.artifact_id,
          artifact_code: artifact.artifact_code,
          title: artifact.title,
          type: artifact.artifact_type_code,
          phase,
          status: artifact.status,
          status_label_pt_br: statusLabelPtBr(artifact.status),
          version: artifact.current_version_number,
          validation_status: latestValidation?.validation_status ?? null,
          file_path: path,
          sha256: hash,
        })
        indexRows.push(`<tr><td>${artifact.title}</td><td>${artifactTypeLabelPtBr(artifact.artifact_type_code, artifact.artifact_type_name)}</td><td>${phase}</td><td>${statusLabelPtBr(artifact.status)}</td><td>v${artifact.current_version_number}</td><td>${path}</td></tr>`)
      }

      const generatedAt = new Date()
      const manifest = {
        schema: 'SPARKS_PE_DELIVERY_KIT',
        schema_version: '1.0.0',
        language: 'pt-BR',
        organization_id: organizationId,
        project_id: projectId,
        generated_at: generatedAt.toISOString(),
        generated_in_read_only_mode: true,
        selected_artifacts: manifestItems,
      }
      zip.file('00_MANIFESTO_KIT.json', JSON.stringify(manifest, null, 2))
      zip.file('00_INDICE_DO_KIT.html', `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>Índice do Kit de Entregas</title><style>body{font-family:Arial,sans-serif;margin:32px;color:#17251e}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccd7d1;padding:8px;text-align:left}th{background:#eef5f1}</style></head><body><h1>Kit de Entregas — SPARKs PE</h1><p>Gerado em ${generatedAt.toLocaleString('pt-BR')}.</p><table><thead><tr><th>Artefato</th><th>Tipo</th><th>Fase</th><th>Situação</th><th>Versão</th><th>Arquivo</th></tr></thead><tbody>${indexRows.join('')}</tbody></table></body></html>`)

      const blob = await zip.generateAsync({ type: 'blob', compression: 'DEFLATE', compressionOptions: { level: 6 } })
      const timestamp = generatedAt.toISOString().replace(/[-:]/g, '').replace(/\..+/, '').replace('T', '_')
      downloadBlob(blob, `SPARKs_PE_Kit_Entregas_${timestamp}.zip`)
      setMessage(`Kit gerado com ${selectedArtifacts.length} artefato(s), índice e manifesto SHA-256.`)
    } catch (error) {
      console.error(error)
      setMessage(translateBackendMessage(error instanceof Error ? error.message : String(error)))
    } finally {
      setGenerating(false)
    }
  }

  return (
    <div className="skpe-delivery-kit" role="dialog" aria-modal="true" aria-label="Kit de Entregas">
      <div className="skpe-delivery-kit-backdrop" onClick={onClose} />
      <section className="skpe-delivery-kit-panel">
        <header><div><span>Consulta e emissão</span><h2>Kit de Entregas</h2><p>Visualize, baixe, imprima ou reúna as versões registradas sem alterar a fase.</p></div><button type="button" className="skpe-delivery-kit-close" onClick={onClose} aria-label="Fechar">×</button></header>
        <div className="skpe-delivery-kit-controls"><input type="search" value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Pesquisar artefato, código ou fase" /><select value={phaseFilter} onChange={(event) => setPhaseFilter(event.target.value)}><option value="">Toda a jornada</option>{phases.map((phase) => <option key={phase}>{phase}</option>)}</select><div className="skpe-delivery-kit-bulk"><button type="button" onClick={() => setSelectedIds(new Set(artifacts.filter((item) => VALIDATED_STATUSES.has(item.status)).map((item) => item.artifact_id)))}>Selecionar validados</button><button type="button" onClick={() => setSelectedIds(new Set(visibleArtifacts.map((item) => item.artifact_id)))}>Selecionar visíveis</button><button type="button" onClick={() => setSelectedIds(new Set())}>Limpar</button></div></div>
        {message && <div className="skpe-delivery-kit-message" role="status">{message}</div>}
        {loading ? <div>Carregando artefatos...</div> : visibleArtifacts.length === 0 ? <div>Nenhum artefato disponível para os filtros informados.</div> : <div className="skpe-delivery-kit-list">{visibleArtifacts.map((artifact) => <article className="skpe-delivery-kit-item" key={artifact.artifact_id}><input type="checkbox" checked={selectedIds.has(artifact.artifact_id)} onChange={() => toggle(artifact.artifact_id)} aria-label={`Selecionar ${artifact.title}`} /><div><h3>{artifact.title}</h3><p>{artifact.purpose ?? artifactTypeLabelPtBr(artifact.artifact_type_code, artifact.artifact_type_name)}</p><div className="skpe-delivery-kit-meta"><span>{artifact.phase_code ?? artifact.macrophase_code ?? artifact.metafase_code ?? 'Sem fase'}</span><span>{statusLabelPtBr(artifact.status)}</span><span>v{artifact.current_version_number}</span><span>{formatDateTime(artifact.validated_at)}</span></div></div><div className="skpe-delivery-kit-actions"><button type="button" onClick={() => void visualize(artifact)}>Visualizar</button><button type="button" onClick={() => void download(artifact)}>Baixar</button><button type="button" onClick={() => void printArtifact(artifact)}>Imprimir</button></div></article>)}</div>}
        <footer className="skpe-delivery-kit-footer"><span>{selectedIds.size} artefato(s) selecionado(s)</span><div><button type="button" onClick={onClose}>Fechar</button><button type="button" className="primary" onClick={() => void generateKit()} disabled={generating}>{generating ? 'Gerando Kit...' : 'Gerar Kit em ZIP'}</button></div></footer>
      </section>
    </div>
  )
}
