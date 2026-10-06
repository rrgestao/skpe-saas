import { useEffect, useMemo, useState } from 'react'
import { SparksSmartGrid, type SparksSmartGridColumn } from '../../components/design-system/SparksSmartGrid'

import { MetricCard } from '../../components/design-system'
import { supabase } from '../../lib/supabase'

import './EvidenceManagementWorkspace.css'

type EvidenceManagementWorkspaceProps = {
  organizationId: string
  projectId: string
}

type EvidenceRow = {
  evidence_asset_id: string
  organization_id: string
  title: string | null
  evidence_type: string | null
  source_type: string | null
  origin_module_code: string | null
  external_origin: string | null
  reference_date: string | null
  reference_period_start: string | null
  reference_period_end: string | null
  validity_date: string | null
  validation_status: string | null
  reliability_level: string | null
  quality_status: string | null
  validity_status: string | null
  availability_status: string | null
  evidence_link_id: string | null
  usage_module_code: string | null
  usage_status: string | null
  is_currently_used: boolean | null
  reuse_status: string | null
  sufficiency_status: string | null
  made_available_at: string | null
  made_available_by_name: string | null
  made_available_actor_type: string | null
}

type ExpectedChecklistItem = {
  id: string
  parent_item_id: string | null
  code: string
  item_type: string
  name: string
  description: string | null
  request_reason: string | null
  possible_evidences: unknown
  best_practice_criteria: unknown
  absence_impact: string | null
  is_required: boolean
  display_order: number
}

type EvidenceVersionDownload = {
  evidence_asset_id: string
  storage_bucket: string | null
  storage_path: string | null
  file_name: string | null
  version_number: number | null
}

type EvidenceGridRow = {
  id: string
  eixo: string
  categoria: string
  evidencia: string
  situacao: string
  origem: string
  disponibilizada_em: string
  disponibilizada_por: string
  periodo_vigencia: string
  qualidade: string
  suficiencia: string
  utilizada: string
}

type EvidenceCreateForm = {
  title: string
  description: string
  evidenceType: string
  sourceType: string
  referenceDate: string
  validityDate: string
  confidentialityLevel: string
  changeReason: string
}

const emptyEvidenceCreateForm: EvidenceCreateForm = {
  title: '',
  description: '',
  evidenceType: 'document',
  sourceType: 'internal',
  referenceDate: '',
  validityDate: '',
  confidentialityLevel: 'internal',
  changeReason: '',
}

async function fileSha256(file: File) {
  const digest = await crypto.subtle.digest('SHA-256', await file.arrayBuffer())
  return Array.from(new Uint8Array(digest)).map((value) => value.toString(16).padStart(2, '0')).join('')
}

function safeStorageFileName(name: string) {
  return name.normalize('NFKD').replace(/[^a-zA-Z0-9._-]+/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '') || 'evidencia'
}
type CardFilter =
  | 'expected'
  | 'available'
  | 'reused'
  | 'valid'
  | 'used'
  | 'insufficient'
  | null

const categoryLabels: Record<string, string> = {
  document: 'Documento',
  dataset: 'Base de dados',
  indicator: 'Indicador',
  self_assessment: 'Autoavaliação',
  assisted_diagnosis: 'Diagnóstico assistido',
  action_plan: 'Plano de ação',
  interview: 'Entrevista',
  workshop: 'Oficina',
  bmc: 'Modelo de Negócio — BMC',
  vpc: 'Proposta de Valor — VPC',
  benchmark: 'Benchmark / Referência comparativa',
  market_study: 'Estudo de mercado',
  legal_reference: 'Referência legal ou normativa',
  image: 'Imagem',
  audio: 'Áudio',
  video: 'Vídeo',
  other: 'Outro',
}

const availabilityLabels: Record<string, string> = {
  available: 'Disponível',
  archived: 'Arquivada',
}

const qualityLabels: Record<string, string> = {
  high: 'Alta',
  moderate: 'Média',
  low: 'Baixa',
  not_assessed: 'Não avaliada',
}

const sufficiencyLabels: Record<string, string> = {
  sufficient: 'Suficiente',
  partially_sufficient: 'Parcialmente suficiente',
  partial: 'Parcialmente suficiente',
  insufficient: 'Insuficiente',
  not_assessed: 'Não avaliada',
  not_applicable_without_use: 'Não aplicável sem uso',
}

function categoryLabel(value: string | null) {
  if (!value) return 'Não classificada'
  return categoryLabels[value] ?? value
}

function formatDate(value: string | null) {
  if (!value) return 'Não informado'
  const date = new Date(`${value}T00:00:00`)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat('pt-BR').format(date)
}

function formatDateTime(value: string | null) {
  if (!value) return 'Não registrado'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(date)
}

function originLabel(row: EvidenceRow) {
  const rawOrigin = row.external_origin?.trim()
  const moduleCode = row.origin_module_code?.trim()

  if (rawOrigin === 'SK-DOC') {
    return 'SK-PE - Evidências no SK-DOC'
  }

  const knownOrigins: Record<string, string> = {
    skpe_import_batches: 'SK-PE - Importação da Planilha de Gestão Estratégica',
    skpe_evidence_sources: 'SK-PE - Evidências históricas do Diagnóstico',
    skpe_data_provenance: 'SK-PE - Proveniência de dados do Diagnóstico',
    'Respostas ao Questionário':
      'SK-PE - Questionário e levantamento de informações',
  }

  if (rawOrigin && knownOrigins[rawOrigin]) {
    return knownOrigins[rawOrigin]
  }

  if (rawOrigin?.startsWith('skpe_')) {
    return 'SK-PE - Fonte interna do Planejamento Estratégico'
  }

  if (rawOrigin && moduleCode) {
    return `${moduleCode} - ${rawOrigin}`
  }

  return rawOrigin || moduleCode || 'Origem não informada'
}

function periodLabel(row: EvidenceRow) {
  if (row.reference_period_start || row.reference_period_end) {
    const start = formatDate(row.reference_period_start)
    const end = formatDate(row.reference_period_end)
    const period =
      row.reference_period_start && row.reference_period_end
        ? `${start} a ${end}`
        : row.reference_period_start
          ? `Desde ${start}`
          : `Até ${end}`

    return row.validity_date
      ? `${period} · Vigência: ${formatDate(row.validity_date)}`
      : `${period} · Vigência: Não avaliada`
  }

  if (row.reference_date) {
    return row.validity_date
      ? `${formatDate(row.reference_date)} · Vigência: ${formatDate(row.validity_date)}`
      : `${formatDate(row.reference_date)} · Vigência: Não avaliada`
  }

  return row.validity_date
    ? `Período não informado · Vigência: ${formatDate(row.validity_date)}`
    : 'Período não informado · Vigência: Não avaliada'
}

function deduplicateEvidence(rows: EvidenceRow[]) {
  const byAsset = new Map<string, EvidenceRow>()

  rows.forEach((row) => {
    const current = byAsset.get(row.evidence_asset_id)

    if (!current) {
      byAsset.set(row.evidence_asset_id, row)
      return
    }

    if (row.is_currently_used && !current.is_currently_used) {
      byAsset.set(row.evidence_asset_id, row)
      return
    }

    if (
      row.reuse_status === 'reused_cross_module' &&
      current.reuse_status !== 'reused_cross_module'
    ) {
      byAsset.set(row.evidence_asset_id, row)
    }
  })

  return Array.from(byAsset.values())
}

export function EvidenceManagementWorkspace({
  organizationId,
  projectId,
}: EvidenceManagementWorkspaceProps) {
  const [rows, setRows] = useState<EvidenceRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [activeFilter, setActiveFilter] = useState<CardFilter>(null)
  const [showChecklistWorkspace, setShowChecklistWorkspace] = useState(false)
  const [downloadVersions, setDownloadVersions] = useState<EvidenceVersionDownload[]>([])
  const [selectedEvidenceAssetId, setSelectedEvidenceAssetId] = useState<string | null>(null)
  const [showCreateEvidence, setShowCreateEvidence] = useState(false)
  const [evidenceForm, setEvidenceForm] = useState<EvidenceCreateForm>(emptyEvidenceCreateForm)
  const [evidenceFile, setEvidenceFile] = useState<File | null>(null)
  const [savingEvidence, setSavingEvidence] = useState(false)
  const [evidenceCreateMessage, setEvidenceCreateMessage] = useState('')
  const [evidenceRefreshKey, setEvidenceRefreshKey] = useState(0)

  const [expectedItems, setExpectedItems] = useState<ExpectedChecklistItem[]>([])
  const [expectedLoading, setExpectedLoading] = useState(true)
  const [expectedError, setExpectedError] = useState('')

  const [operationalChecklistItems, setOperationalChecklistItems] = useState<number | null>(null)
  const [operationalChecklistError, setOperationalChecklistError] = useState('')

  useEffect(() => {
    let cancelled = false

    async function loadEvidence() {
      setLoading(true)
      setError('')

      const { data, error: queryError } = await supabase
        .from('sparks_evidence_operational_projection')
        .select(
          [
            'evidence_asset_id',
            'organization_id',
            'title',
            'evidence_type',
            'source_type',
            'origin_module_code',
            'external_origin',
            'reference_date',
            'reference_period_start',
            'reference_period_end',
            'validity_date',
            'validation_status',
            'reliability_level',
            'quality_status',
            'validity_status',
            'availability_status',
            'evidence_link_id',
            'usage_module_code',
            'usage_status',
            'is_currently_used',
            'reuse_status',
            'sufficiency_status',
            'made_available_at',
            'made_available_by_name',
            'made_available_actor_type',
          ].join(','),
        )
        .eq('organization_id', organizationId)

      if (cancelled) return

      if (queryError) {
        setRows([])
        setError(queryError.message)
        setLoading(false)
        return
      }

      setRows((data ?? []) as unknown as EvidenceRow[])
      setLoading(false)
    }

    void loadEvidence()

    return () => {
      cancelled = true
    }
  }, [organizationId, evidenceRefreshKey])

  useEffect(() => {
    let cancelled = false
    async function loadOperationalChecklist() {
      setOperationalChecklistError('')
      const { data, error: queryError } = await supabase.rpc('get_skpe_evidence_checklist', {
        target_organization_id: organizationId,
        target_project_id: projectId,
      })
      if (cancelled) return
      if (queryError) { setOperationalChecklistItems(null); setOperationalChecklistError(queryError.message); return }
      setOperationalChecklistItems((data ?? []).length)
    }
    void loadOperationalChecklist()
    return () => { cancelled = true }
  }, [organizationId, projectId])

  useEffect(() => {
    let cancelled = false

    async function loadExpectedEvidenceChecklist() {
      setExpectedLoading(true)
      setExpectedError('')

      const { data: template, error: templateError } = await supabase
        .from('sparks_checklist_templates')
        .select('id')
        .eq('code', 'SPARKS-PEM00-GERAL')
        .eq('active', true)
        .maybeSingle()

      if (cancelled) return

      if (templateError || !template) {
        setExpectedItems([])
        setExpectedError(
          templateError?.message ?? 'Checklist PEM-00 não localizado.',
        )
        setExpectedLoading(false)
        return
      }

      const { data: version, error: versionError } = await supabase
        .from('sparks_checklist_template_versions')
        .select('id')
        .eq('template_id', template.id)
        .eq('status', 'published')
        .order('version_code', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (cancelled) return

      if (versionError || !version) {
        setExpectedItems([])
        setExpectedError(
          versionError?.message ?? 'Nenhuma versão publicada do PEM-00 foi localizada.',
        )
        setExpectedLoading(false)
        return
      }

      const { data: items, error: itemsError } = await supabase
        .from('sparks_checklist_template_items')
        .select(
          'id,parent_item_id,code,item_type,name,description,request_reason,possible_evidences,best_practice_criteria,absence_impact,is_required,display_order',
        )
        .eq('template_version_id', version.id)
        .order('display_order', { ascending: true })

      if (cancelled) return

      if (itemsError) {
        setExpectedItems([])
        setExpectedError(itemsError.message)
        setExpectedLoading(false)
        return
      }

      setExpectedItems((items ?? []) as unknown as ExpectedChecklistItem[])
      setExpectedLoading(false)
    }

    void loadExpectedEvidenceChecklist()

    return () => {
      cancelled = true
    }
  }, [])

  const assets = useMemo(() => deduplicateEvidence(rows), [rows])

  useEffect(() => {
    let cancelled = false

    async function loadDownloadVersions() {
      const assetIds = assets.map((row) => row.evidence_asset_id)
      if (assetIds.length === 0) {
        setDownloadVersions([])
        return
      }

      const { data, error: versionError } = await supabase
        .from('sparks_evidence_versions')
        .select('evidence_asset_id,storage_bucket,storage_path,file_name,version_number')
        .in('evidence_asset_id', assetIds)
        .order('version_number', { ascending: false })

      if (cancelled) return
      if (versionError) {
        setDownloadVersions([])
        return
      }

      const latestByAsset = new Map<string, EvidenceVersionDownload>()
      for (const row of (data ?? []) as EvidenceVersionDownload[]) {
        if (!latestByAsset.has(row.evidence_asset_id)) {
          latestByAsset.set(row.evidence_asset_id, row)
        }
      }
      setDownloadVersions(Array.from(latestByAsset.values()))
    }

    void loadDownloadVersions()
    return () => {
      cancelled = true
    }
  }, [assets])

  const selectedEvidenceAsset = useMemo(
    () => assets.find((asset) => asset.evidence_asset_id === selectedEvidenceAssetId) ?? null,
    [assets, selectedEvidenceAssetId],
  )

  const checklistAxes = useMemo(() => {
    const requirementsByAxis = new Map<string, ExpectedChecklistItem[]>()
    for (const item of expectedItems) {
      if (item.item_type !== 'requirement' || !item.parent_item_id) continue
      const current = requirementsByAxis.get(item.parent_item_id) ?? []
      current.push(item)
      requirementsByAxis.set(item.parent_item_id, current)
    }

    return expectedItems
      .filter((item) => item.item_type === 'axis')
      .map((axis) => ({
        axis,
        requirements: (requirementsByAxis.get(axis.id) ?? []).sort(
          (first, second) => first.display_order - second.display_order,
        ),
      }))
  }, [expectedItems])

  const counts = useMemo(
    () => ({
      available: assets.filter(
        (row) => row.availability_status === 'available',
      ).length,
      reused: assets.filter(
        (row) => row.reuse_status === 'reused_cross_module',
      ).length,
      valid: assets.filter((row) => row.validity_status === 'valid').length,
      used: assets.filter((row) => row.is_currently_used).length,
      insufficient: assets.filter(
        (row) => row.sufficiency_status === 'insufficient',
      ).length,
    }),
    [assets],
  )

  const filteredAssets = useMemo(() => {
    switch (activeFilter) {
      case 'available':
        return assets.filter(
          (row) => row.availability_status === 'available',
        )
      case 'reused':
        return assets.filter(
          (row) => row.reuse_status === 'reused_cross_module',
        )
      case 'valid':
        return assets.filter((row) => row.validity_status === 'valid')
      case 'used':
        return assets.filter((row) => row.is_currently_used)
      case 'insufficient':
        return assets.filter(
          (row) => row.sufficiency_status === 'insufficient',
        )
      default:
        return assets
    }
  }, [activeFilter, assets])

  const assetGridData = useMemo<EvidenceGridRow[]>(
    () =>
      filteredAssets.map((row) => ({
        id: row.evidence_asset_id,
        eixo: 'Não vinculado',
        categoria: categoryLabel(row.evidence_type),
        evidencia: row.title ?? 'Evidência sem título',
        situacao:
          availabilityLabels[row.availability_status ?? ''] ??
          row.availability_status ??
          'Não avaliada',
        origem: originLabel(row),
        disponibilizada_em: formatDateTime(row.made_available_at),
        disponibilizada_por:
          row.made_available_by_name ?? 'Não registrado',
        periodo_vigencia: periodLabel(row),
        qualidade:
          qualityLabels[row.quality_status ?? ''] ??
          row.quality_status ??
          'Não avaliada',
        suficiencia:
          sufficiencyLabels[row.sufficiency_status ?? ''] ??
          row.sufficiency_status ??
          'Não avaliada',
        utilizada: row.is_currently_used ? 'Sim' : 'Não',
      })),
    [filteredAssets],
  )

  const expectedGridData = useMemo<EvidenceGridRow[]>(() => {
    const axisById = new Map(
      expectedItems
        .filter((item) => item.item_type === 'axis')
        .map((item) => [item.id, item]),
    )

    return expectedItems
      .filter((item) => item.item_type === 'requirement')
      .map((item) => ({
        id: item.id,
        eixo: item.parent_item_id
          ? axisById.get(item.parent_item_id)?.name ?? 'Eixo não identificado'
          : 'Eixo não identificado',
        categoria: 'Evidência prevista',
        evidencia: item.name,
        situacao: 'Prevista no checklist',
        origem: 'PEM-00 - Checklist Padrão de Evidências',
        disponibilizada_em: 'Ainda não aplicável',
        disponibilizada_por: 'Ainda não aplicável',
        periodo_vigencia: 'Preparação do Diagnóstico Estratégico',
        qualidade: 'Não avaliada',
        suficiencia: 'Não avaliada',
        utilizada: 'Não',
      }))
  }, [expectedItems])

  const selectedGridData =
    activeFilter === 'expected' ? expectedGridData : assetGridData

  const columns: SparksSmartGridColumn[] = [
    { id: 'eixo', label: 'Eixo', minWidth: 160, maxWidth: 260, tooltip: true },
    { id: 'categoria', label: 'Categoria', minWidth: 170, maxWidth: 260, tooltip: true },
    { id: 'evidencia', label: 'Evidência', minWidth: 340, maxWidth: 620, tooltip: true, grow: 2 },
    { id: 'situacao', label: 'Situação', minWidth: 175, maxWidth: 280, tooltip: true },
    { id: 'origem', label: 'Origem', minWidth: 280, maxWidth: 520, tooltip: true, grow: 2 },
    { id: 'disponibilizada_em', label: 'Disponibilizada em', minWidth: 180, maxWidth: 240 },
    { id: 'disponibilizada_por', label: 'Disponibilizada por', minWidth: 220, maxWidth: 360, tooltip: true },
    { id: 'periodo_vigencia', label: 'Período / Vigência', minWidth: 260, maxWidth: 420, tooltip: true },
    { id: 'qualidade', label: 'Qualidade', minWidth: 150, maxWidth: 220 },
    { id: 'suficiencia', label: 'Suficiência', minWidth: 190, maxWidth: 280, tooltip: true },
    { id: 'utilizada', label: 'Utilizada na análise', minWidth: 180, maxWidth: 240 },
  ]

  function toggleFilter(filter: CardFilter) {
    setActiveFilter((current) => (current === filter ? null : filter))
  }

  function checklistDetail(value: unknown) {
    if (Array.isArray(value)) {
      return value.map((item) => String(item)).filter(Boolean).join(' · ')
    }
    if (value && typeof value === 'object') {
      return Object.values(value as Record<string, unknown>)
        .flatMap((item) => (Array.isArray(item) ? item : [item]))
        .map((item) => String(item))
        .filter(Boolean)
        .join(' · ')
    }
    return value ? String(value) : ''
  }

  async function saveEvidence() {
    const title = evidenceForm.title.trim()
    const reason = evidenceForm.changeReason.trim()
    if (!title) { setEvidenceCreateMessage('Informe o título da evidência.'); return }
    if (reason.length < 10) { setEvidenceCreateMessage('Informe uma justificativa com pelo menos 10 caracteres.'); return }

    setSavingEvidence(true)
    setEvidenceCreateMessage('')

    let uploadedPath: string | null = null
    let contentHash: string | null = null
    let assetId: string | null = null

    try {
      if (evidenceFile) {
        contentHash = await fileSha256(evidenceFile)
        const { data: existingEvidence, error: existingEvidenceError } = await supabase
          .from('sparks_evidence_assets')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('content_hash', contentHash)
          .is('archived_at', null)
          .maybeSingle()
        if (existingEvidenceError) throw existingEvidenceError
        assetId = existingEvidence?.id ?? null

        if (!assetId) {
          const safeName = safeStorageFileName(evidenceFile.name)
          const now = new Date()
          uploadedPath = `${organizationId}/${now.getFullYear()}/${crypto.randomUUID()}-${safeName}`
          const { error: uploadError } = await supabase.storage
            .from('sparks-evidence')
            .upload(uploadedPath, evidenceFile, {
              cacheControl: '3600',
              contentType: evidenceFile.type || undefined,
              upsert: false,
            })
          if (uploadError) throw uploadError
        }
      }

      if (!assetId) {
        const { data: evidenceAssetId, error: registerError } = await supabase.rpc(
        'register_sparks_evidence_asset',
        {
          target_organization_id: organizationId,
          evidence_title: title,
          evidence_description: evidenceForm.description.trim() || null,
          target_evidence_type: evidenceForm.evidenceType,
          target_source_type: evidenceForm.sourceType,
          target_origin_module_code: 'SK-PE',
          target_reference_date: evidenceForm.referenceDate || null,
          target_validity_date: evidenceForm.validityDate || null,
          target_confidentiality_level: evidenceForm.confidentialityLevel,
          target_content_hash: contentHash,
          target_file_name: evidenceFile?.name ?? null,
          target_mime_type: evidenceFile?.type || null,
          target_file_size_bytes: evidenceFile?.size ?? null,
          target_storage_bucket: uploadedPath ? 'sparks-evidence' : null,
          target_storage_path: uploadedPath,
          change_reason: reason,
        },
      )

        if (registerError) throw registerError
        assetId = typeof evidenceAssetId === 'string' ? evidenceAssetId : null
      }

      if (assetId) {
        const { error: linkError } = await supabase.rpc('link_sparks_evidence', {
          target_organization_id: organizationId,
          target_evidence_asset_id: assetId,
          target_module_code: 'SK-PE',
          target_type: 'strategic_project',
          target_id: projectId,
          target_usage_purpose: 'Evidência disponível para diagnóstico, formulação, execução e monitoramento do Planejamento Estratégico.',
          target_relevance_level: 'important',
          target_is_primary: false,
          change_reason: reason,
        })
        if (linkError) {
          setEvidenceCreateMessage(`Evidência registrada, mas o vínculo ao projeto requer revisão: ${linkError.message}`)
        } else {
          setEvidenceCreateMessage('Evidência registrada e vinculada ao projeto com rastreabilidade.')
        }
      }

      setEvidenceForm(emptyEvidenceCreateForm)
      setEvidenceFile(null)
      setEvidenceRefreshKey((value) => value + 1)
    } catch (caught) {
      if (uploadedPath) {
        await supabase.storage.from('sparks-evidence').remove([uploadedPath])
      }
      setEvidenceCreateMessage(caught instanceof Error ? caught.message : 'Não foi possível registrar a evidência.')
    } finally {
      setSavingEvidence(false)
    }
  }
  async function downloadEvidence(asset: EvidenceRow) {
    const version = downloadVersions.find(
      (item) => item.evidence_asset_id === asset.evidence_asset_id,
    )
    if (!version?.storage_bucket || !version.storage_path) return

    const { data, error: downloadError } = await supabase.storage
      .from(version.storage_bucket)
      .download(version.storage_path)

    if (downloadError || !data) return
    const url = URL.createObjectURL(data)
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = version.file_name ?? asset.title ?? 'evidencia'
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(url)
  }

  return (
    <section className="skpe-evidence-section">
      <header className="skpe-evidence-section__intro">
        <span className="skpe-evidence-section__eyebrow">
          Evidências da organização
        </span>
        <div className="skpe-evidence-intro-heading-row">
          <h2>Base transversal para diagnóstico e decisões</h2>
          <div className="skpe-evidence-heading-actions">
            <button
              type="button"
              className="skpe-evidence-checklist-button"
              onClick={() => setShowCreateEvidence((value) => !value)}
            >
              {showCreateEvidence ? 'Fechar cadastro' : 'Registrar evidência'}
            </button>
            <button
              type="button"
              className="skpe-evidence-checklist-button"
              onClick={() => setShowChecklistWorkspace(true)}
            >
              Checklist de evidências e downloads
            </button>
          </div>
        </div>
        <p>
          Decisões estratégicas confiáveis precisam nascer de fatos e dados, não de achismos.
          Esta base reúne as evidências governadas pela Plataforma para sustentar diagnóstico,
          maturidade, riscos, escolhas e acompanhamento com rastreabilidade.
        </p>
        <p className="skpe-evidence-authority-note">
          SK-DOC governa documentos, evidências e versões. SK-KM sustenta conhecimento,
          classificação e contexto. O SK-PE apenas consome essas evidências e avalia sua
          suficiência e uso no contexto estratégico.
        </p>
        <div className="skpe-evidence-operational-state">
          {operationalChecklistError ? (
            <span>Não foi possível consultar o checklist do projeto neste momento.</span>
          ) : operationalChecklistItems === 0 ? (
            <span>O checklist do projeto ainda não foi materializado. Os requisitos previstos abaixo vêm do padrão metodológico publicado e devem ser reconciliados com evidências já disponíveis na organização antes de novas solicitações.</span>
          ) : operationalChecklistItems !== null ? (
            <span>Checklist do projeto disponível com {operationalChecklistItems} itens para coleta, vínculo e avaliação de evidências.</span>
          ) : null}
        </div>
      </header>

      {showCreateEvidence ? (
        <section className="skpe-evidence-create-card" aria-label="Registrar evidência">
          <header>
            <div><span className="skpe-evidence-section__eyebrow">Cadastro governado</span><h3>Nova evidência transversal</h3></div>
            <p>O arquivo e seus metadados serão registrados no serviço transversal de evidências, sob autoridade documental do SK-DOC, e vinculados ao projeto estratégico atual.</p>
          </header>
          {evidenceCreateMessage ? <div className="skpe-evidence-create-message" role="status">{evidenceCreateMessage}</div> : null}
          <div className="skpe-evidence-create-grid">
            <label className="wide"><span>Título *</span><input value={evidenceForm.title} onChange={(event) => setEvidenceForm({ ...evidenceForm, title: event.target.value })} /></label>
            <label><span>Categoria *</span><select value={evidenceForm.evidenceType} onChange={(event) => setEvidenceForm({ ...evidenceForm, evidenceType: event.target.value })}>{Object.entries(categoryLabels).map(([value, label]) => <option value={value} key={value}>{label}</option>)}</select></label>
            <label><span>Origem *</span><select value={evidenceForm.sourceType} onChange={(event) => setEvidenceForm({ ...evidenceForm, sourceType: event.target.value })}><option value="internal">Interna</option><option value="external">Externa</option><option value="public">Pública</option><option value="market">Mercado</option><option value="benchmark">Benchmark</option><option value="regulatory">Regulatória</option><option value="partner">Parceiro</option><option value="other">Outra</option></select></label>
            <label><span>Data de referência</span><input type="date" value={evidenceForm.referenceDate} onChange={(event) => setEvidenceForm({ ...evidenceForm, referenceDate: event.target.value })} /></label>
            <label><span>Validade</span><input type="date" value={evidenceForm.validityDate} onChange={(event) => setEvidenceForm({ ...evidenceForm, validityDate: event.target.value })} /></label>
            <label><span>Confidencialidade</span><select value={evidenceForm.confidentialityLevel} onChange={(event) => setEvidenceForm({ ...evidenceForm, confidentialityLevel: event.target.value })}><option value="public">Pública</option><option value="internal">Interna</option><option value="restricted">Restrita</option><option value="confidential">Confidencial</option></select></label>
            <label className="wide"><span>Arquivo</span><input type="file" onChange={(event) => setEvidenceFile(event.target.files?.[0] ?? null)} /><small>Até 50 MB. PDF, Office, texto, CSV, JSON, ZIP e imagens usuais.</small></label>
            <label className="wide"><span>Descrição</span><textarea value={evidenceForm.description} onChange={(event) => setEvidenceForm({ ...evidenceForm, description: event.target.value })} /></label>
            <label className="wide"><span>Justificativa / contexto do registro *</span><textarea value={evidenceForm.changeReason} onChange={(event) => setEvidenceForm({ ...evidenceForm, changeReason: event.target.value })} placeholder="Explique por que esta evidência está sendo disponibilizada e para qual uso estratégico." /></label>
          </div>
          <div className="skpe-evidence-create-actions">
            <button type="button" onClick={() => { setEvidenceForm(emptyEvidenceCreateForm); setEvidenceFile(null); setEvidenceCreateMessage('') }} disabled={savingEvidence}>Limpar</button>
            <button type="button" className="primary" onClick={() => void saveEvidence()} disabled={savingEvidence}>{savingEvidence ? 'Registrando...' : 'Registrar evidência'}</button>
          </div>
        </section>
      ) : null}
      <div className="skpe-evidence-metrics">
        <MetricCard
          label="Evidências previstas"
          value={expectedLoading ? '…' : expectedError ? '—' : expectedGridData.length}
          helper={
            expectedError
              ? 'Checklist indisponível no momento'
              : 'requisitos previstos pela versão publicada do checklist PEM-00'
          }
          active={activeFilter === 'expected'}
          onClick={
            !expectedLoading && !expectedError
              ? () => toggleFilter('expected')
              : undefined
          }
          disabled={expectedLoading || Boolean(expectedError)}
          ariaLabel="Mostrar evidências previstas pelo checklist"
          tooltip={
            expectedError
              ? expectedError
              : 'Clique para mostrar os requisitos de evidência previstos pelo PEM-00.'
          }
        />

        <MetricCard
          label="Disponíveis"
          value={counts.available}
          helper={`${counts.available} ativos de evidência cadastrados`}
          active={activeFilter === 'available'}
          onClick={() => toggleFilter('available')}
          ariaLabel="Filtrar evidências disponíveis"
          tooltip="Clique para filtrar; clique novamente para limpar."
        />

        <MetricCard
          label="Reutilizadas de outros processos"
          value={counts.reused}
          helper={`${counts.reused} evidências com reutilização transversal`}
          active={activeFilter === 'reused'}
          onClick={() => toggleFilter('reused')}
          ariaLabel="Filtrar evidências reutilizadas"
          tooltip="Clique para filtrar; clique novamente para limpar."
        />

        <MetricCard
          label="Faltantes / insuficientes"
          value={counts.insufficient || '—'}
          helper="faltantes dependem do vínculo checklist ↔ evidência"
          active={activeFilter === 'insufficient'}
          onClick={
            counts.insufficient > 0
              ? () => toggleFilter('insufficient')
              : undefined
          }
          disabled={counts.insufficient === 0}
          ariaLabel="Filtrar evidências insuficientes"
          tooltip={
            counts.insufficient > 0
              ? 'Clique para filtrar evidências avaliadas como insuficientes.'
              : 'Faltantes serão calculadas após o vínculo checklist ↔ evidência.'
          }
        />

        <MetricCard
          label="Atualizadas / válidas"
          value={counts.valid}
          helper={`${assets.length - counts.valid} ainda sem validade confirmada`}
          active={activeFilter === 'valid'}
          onClick={() => toggleFilter('valid')}
          ariaLabel="Filtrar evidências válidas"
          tooltip="Clique para filtrar; clique novamente para limpar."
        />

        <MetricCard
          label="Cobertura do Diagnóstico"
          value={counts.used || '—'}
          helper={
            counts.used
              ? `${counts.used} evidências vinculadas a uso analítico`
              : 'não calculada sem vínculo requisito ↔ evidência'
          }
          active={activeFilter === 'used'}
          onClick={
            counts.used > 0 ? () => toggleFilter('used') : undefined
          }
          disabled={counts.used === 0}
          ariaLabel="Filtrar evidências utilizadas no diagnóstico"
          tooltip={
            counts.used > 0
              ? 'Clique para mostrar evidências atualmente utilizadas.'
              : 'A cobertura percentual será calculada após o vínculo do checklist.'
          }
        />
      </div>

      <section className="skpe-evidence-grid-card">
        <div className="skpe-evidence-grid-card__header">
          <div>
            <h3>
              {activeFilter === 'expected'
                ? 'Evidências previstas'
                : 'Evidências disponíveis'}
            </h3>
            <p>
              Clique no label para ordenar, use o funil para filtrar e arraste a
              divisória direita para redimensionar. O cabeçalho permanece
              visível enquanto as linhas rolam.
            </p>
          </div>

          {activeFilter ? (
            <button
              type="button"
              className="skpe-evidence-clear-filter"
              onClick={() => setActiveFilter(null)}
            >
              Limpar filtro
            </button>
          ) : null}
        </div>

        {loading ? (
          <p className="skpe-evidence-state">Carregando evidências...</p>
        ) : error ? (
          <p className="skpe-evidence-state skpe-evidence-state--error">
            Não foi possível carregar as evidências: {error}
          </p>
        ) : (
          <>
            <SparksSmartGrid
              rows={selectedGridData}
              columns={columns}
              ariaLabel={activeFilter === 'expected' ? 'Evidências previstas' : 'Evidências disponíveis'}
              fillViewport
              autoRowHeight={false}
            />

            <p className="skpe-evidence-grid-card__footer">
              {selectedGridData.length} de{' '}
              {activeFilter === 'expected'
                ? expectedGridData.length
                : filteredAssets.length}{' '}
              registros exibidos.
            </p>
          </>
        )}
      </section>

      {showChecklistWorkspace ? (
        <aside className="skpe-evidence-checklist-workspace" aria-label="Checklist de evidências e downloads">
          <button
            type="button"
            className="skpe-evidence-checklist-backdrop"
            aria-label="Fechar checklist de evidências"
            onClick={() => setShowChecklistWorkspace(false)}
          />
          <div className="skpe-evidence-checklist-panel">
            <header className="skpe-evidence-checklist-panel__header">
              <div>
                <span className="skpe-evidence-section__eyebrow">Checklist metodológico PEM-00</span>
                <h2>Evidências para diagnóstico, governança e maturidade</h2>
                <p>
                  Organizado pelos grandes eixos de governança e gestão e, dentro deles,
                  pelos requisitos/práticas que orientam a análise do ambiente interno e da maturidade organizacional.
                </p>
              </div>
              <button
                type="button"
                className="skpe-evidence-checklist-close"
                onClick={() => setShowChecklistWorkspace(false)}
                aria-label="Fechar"
              >
                ×
              </button>
            </header>

            {operationalChecklistItems === 0 ? (
              <div className="skpe-evidence-checklist-notice">
                <strong>Checklist operacional ainda não materializado para este projeto.</strong>
                <span>
                  A estrutura abaixo é a versão metodológica publicada. Evidências da organização não serão atribuídas automaticamente a um requisito sem vínculo governado.
                </span>
              </div>
            ) : null}

            <div className="skpe-evidence-checklist-layout">
              <section className="skpe-evidence-checklist-axes">
                {checklistAxes.map(({ axis, requirements }) => (
                  <article key={axis.id} className="skpe-evidence-axis-card">
                    <header>
                      <span>{axis.code}</span>
                      <h3>{axis.name}</h3>
                      {axis.description ? <p>{axis.description}</p> : null}
                    </header>
                    <div className="skpe-evidence-axis-requirements">
                      {requirements.map((requirement) => {
                        const criteria = checklistDetail(requirement.best_practice_criteria)
                        const possible = checklistDetail(requirement.possible_evidences)
                        return (
                          <section key={requirement.id} className="skpe-evidence-requirement-card">
                            <div className="skpe-evidence-requirement-heading">
                              <span>{requirement.code}</span>
                              <strong>{requirement.name}</strong>
                            </div>
                            {requirement.description ? <p>{requirement.description}</p> : null}
                            {criteria ? (
                              <div>
                                <small>Critérios / práticas de referência</small>
                                <p>{criteria}</p>
                              </div>
                            ) : null}
                            {possible ? (
                              <div>
                                <small>Evidências possíveis</small>
                                <p>{possible}</p>
                              </div>
                            ) : null}
                            {requirement.absence_impact ? (
                              <div>
                                <small>Impacto da ausência</small>
                                <p>{requirement.absence_impact}</p>
                              </div>
                            ) : null}
                          </section>
                        )
                      })}
                    </div>
                  </article>
                ))}
              </section>

              <aside className="skpe-evidence-downloads-panel">
                <div>
                  <span className="skpe-evidence-section__eyebrow">Arquivos da organização</span>
                  <h3>Downloads disponíveis</h3>
                  <p>
                    Somente arquivos efetivamente materializados no repositório canônico podem ser baixados.
                  </p>
                </div>
                <div className="skpe-evidence-download-list">
                  {assets.map((asset) => {
                    const version = downloadVersions.find(
                      (item) => item.evidence_asset_id === asset.evidence_asset_id,
                    )
                    const downloadable = Boolean(version?.storage_bucket && version.storage_path)
                    return (
                      <article key={asset.evidence_asset_id}>
                        <div>
                          <strong>{asset.title ?? 'Evidência sem título'}</strong>
                          <span>{originLabel(asset)}</span>
                        </div>
                        <div className="skpe-evidence-download-actions">
                          <button
                            type="button"
                            className="skpe-evidence-analysis-button"
                            onClick={() => setSelectedEvidenceAssetId(asset.evidence_asset_id)}
                          >
                            Analisar
                          </button>
                          <button
                            type="button"
                            disabled={!downloadable}
                            onClick={() => void downloadEvidence(asset)}
                            title={
                              downloadable
                                ? 'Baixar versão materializada'
                                : 'Arquivo ainda não materializado no repositório canônico'
                            }
                          >
                            {downloadable ? 'Baixar' : 'Sem arquivo'}
                          </button>
                        </div>
                      </article>
                    )
                  })}
                </div>

                {selectedEvidenceAsset ? (
                  <section className="skpe-evidence-analysis-card">
                    <div className="skpe-evidence-analysis-card__heading">
                      <div>
                        <span className="skpe-evidence-section__eyebrow">Análise da evidência</span>
                        <h4>{selectedEvidenceAsset.title ?? 'Evidência sem título'}</h4>
                      </div>
                      <button
                        type="button"
                        aria-label="Fechar análise da evidência"
                        onClick={() => setSelectedEvidenceAssetId(null)}
                      >
                        ×
                      </button>
                    </div>
                    <dl>
                      <div>
                        <dt>Origem</dt>
                        <dd>{originLabel(selectedEvidenceAsset)}</dd>
                      </div>
                      <div>
                        <dt>Qualidade</dt>
                        <dd>{qualityLabels[selectedEvidenceAsset.reliability_level ?? 'not_assessed'] ?? selectedEvidenceAsset.reliability_level ?? 'Não avaliada'}</dd>
                      </div>
                      <div>
                        <dt>Suficiência</dt>
                        <dd>{sufficiencyLabels[selectedEvidenceAsset.sufficiency_status ?? 'not_assessed'] ?? selectedEvidenceAsset.sufficiency_status ?? 'Não avaliada'}</dd>
                      </div>
                      <div>
                        <dt>Validação</dt>
                        <dd>{selectedEvidenceAsset.validation_status ?? 'Não avaliada'}</dd>
                      </div>
                      <div>
                        <dt>Vigência</dt>
                        <dd>{periodLabel(selectedEvidenceAsset)}</dd>
                      </div>
                      <div>
                        <dt>Uso no SK-PE</dt>
                        <dd>{selectedEvidenceAsset.is_currently_used ? 'Em uso no contexto estratégico' : 'Ainda não vinculada a um uso estratégico governado'}</dd>
                      </div>
                    </dl>
                    <p>
                      A consulta e análise permanecem disponíveis mesmo sem arquivo materializado.
                      O download só é liberado quando existir uma versão física governada pelo SK-DOC.
                    </p>
                  </section>
                ) : null}
              </aside>
            </div>
          </div>
        </aside>
      ) : null}
    </section>
  )
}
