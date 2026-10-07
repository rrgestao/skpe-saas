import { useEffect, useMemo, useRef, useState } from 'react'
import { SparksSmartGrid, type SparksSmartGridColumn } from '../../components/design-system/SparksSmartGrid'

import { MetricCard } from '../../components/design-system'
import { supabase } from '../../lib/supabase'
import { EvidenceFilePreview } from './EvidenceFilePreview'

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
  target_type?: string | null
  target_id?: string | null
  usage_module_code: string | null
  usage_status: string | null
  is_currently_used: boolean | null
  reuse_status: string | null
  sufficiency_status: string | null
  made_available_at: string | null
  made_available_by_name: string | null
  made_available_actor_type: string | null
  source_external_key?: string | null
  skdoc_document_id?: string | null
  current_version_id?: string | null
  metadata?: Record<string, unknown> | null
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

type OperationalChecklistRow = {
  checklist_id: string
  checklist_code: string
  checklist_name: string
  checklist_status: string
  completion_percentage: number | null
  readiness_score: number | null
  item_id: string
  item_code: string
  item_name: string
  is_required: boolean
  is_applicable: boolean
  collection_status: string | null
  assessment_status: string | null
  compliance_level: number | null
  overall_score: number | null
  files_count: number
  validated_files_count: number
}
type EvidenceVersionDownload = {
  id?: string
  evidence_asset_id: string
  storage_bucket: string | null
  storage_path: string | null
  file_name: string | null
  mime_type?: string | null
  file_size_bytes?: number | null
  version_number: number | null
  version_label?: string | null
  content_hash?: string | null
  change_summary?: string | null
  created_at?: string | null
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

function inferDocumentYear(name: string) {
  const years = Array.from(new Set(name.match(/(?:19|20)\d{2}/g) ?? []))
  return years.length === 1 ? years[0] : null
}

function normalizeSeriesKey(value: string) {
  return value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLocaleUpperCase('pt-BR')
    .replace(/[^A-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

function defaultSeriesTitle(row: EvidenceRow) {
  const metadataSeries = row.metadata?.series_title
  if (typeof metadataSeries === 'string' && metadataSeries.trim()) return metadataSeries.trim()
  return (row.title ?? 'Série documental')
    .replace(/\s+[—-]\s+(?:19|20)\d{2}\s*$/u, '')
    .trim()
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

function sourceReferenceLabel(row: EvidenceRow, version?: EvidenceVersionDownload | null) {
  const metadata = row.metadata ?? {}
  const sourcePayload =
    metadata.source_payload && typeof metadata.source_payload === 'object'
      ? metadata.source_payload as Record<string, unknown>
      : {}
  const sourceSheet = typeof metadata.source_sheet === 'string' ? metadata.source_sheet : null
  const sourceName = typeof sourcePayload.fonte === 'string' ? sourcePayload.fonte : null
  const sourceCode = typeof sourcePayload.codigo === 'string' ? sourcePayload.codigo : null
  const sourceDate = typeof sourcePayload.data_periodo === 'string' ? sourcePayload.data_periodo : null
  const responsible = typeof sourcePayload.responsavel === 'string' ? sourcePayload.responsavel : null
  const risk = typeof sourcePayload.risco_relacionado === 'string' ? sourcePayload.risco_relacionado : null

  const parts = [
    version?.file_name ? `Arquivo: ${version.file_name}` : null,
    sourceName ? `Fonte: ${sourceName}` : originLabel(row),
    sourceSheet ? `Origem: ${sourceSheet}` : null,
    sourceCode ? `Código: ${sourceCode}` : row.source_external_key ? `Chave: ${row.source_external_key}` : null,
    sourceDate ? `Data: ${sourceDate}` : row.reference_date ? `Data: ${formatDate(row.reference_date)}` : null,
    responsible ? `Responsável: ${responsible}` : null,
    risk ? `Risco: ${risk}` : null,
    version?.version_label ? `Versão: ${version.version_label}` : null,
  ].filter(Boolean)

  return parts.join(' · ')
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
  const [evidenceMaintenanceOpen, setEvidenceMaintenanceOpen] = useState(false)
  const [associationChecklistItemId, setAssociationChecklistItemId] = useState('')
  const [associationReason, setAssociationReason] = useState('')
  const [associationMessage, setAssociationMessage] = useState('')
  const [associatingEvidence, setAssociatingEvidence] = useState(false)
  const [seriesTitle, setSeriesTitle] = useState('')
  const [seriesFiles, setSeriesFiles] = useState<File[]>([])
  const [seriesReason, setSeriesReason] = useState('')
  const [seriesMessage, setSeriesMessage] = useState('')
  const [registeringSeries, setRegisteringSeries] = useState(false)
  const [checklistRefreshKey, setChecklistRefreshKey] = useState(0)
  const [showCreateEvidence, setShowCreateEvidence] = useState(false)
  const [evidenceForm, setEvidenceForm] = useState<EvidenceCreateForm>(emptyEvidenceCreateForm)
  const [evidenceFile, setEvidenceFile] = useState<File | null>(null)
  const [savingEvidence, setSavingEvidence] = useState(false)
  const [evidenceCreateMessage, setEvidenceCreateMessage] = useState('')
  const [evidenceRefreshKey, setEvidenceRefreshKey] = useState(0)
  const [versionFile, setVersionFile] = useState<File | null>(null)
  const [versionReason, setVersionReason] = useState('')
  const [savingVersion, setSavingVersion] = useState(false)
  const [versionMessage, setVersionMessage] = useState('')
  const [selectedVersionHistory, setSelectedVersionHistory] = useState<EvidenceVersionDownload[]>([])
  const [previewVersionId, setPreviewVersionId] = useState<string | null>(null)
  const selectedEvidenceAnalysisRef = useRef<HTMLElement | null>(null)

  const [expectedItems, setExpectedItems] = useState<ExpectedChecklistItem[]>([])
  const [expectedLoading, setExpectedLoading] = useState(true)
  const [expectedError, setExpectedError] = useState('')

  const [operationalChecklistRows, setOperationalChecklistRows] = useState<OperationalChecklistRow[]>([])
  const [operationalChecklistError, setOperationalChecklistError] = useState('')
  const [selectedChecklistRequirementId, setSelectedChecklistRequirementId] = useState<string | null>(null)

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
            'target_type',
            'target_id',
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

      const projectionRows = (data ?? []) as unknown as EvidenceRow[]
      const assetIds = Array.from(new Set(projectionRows.map((row) => row.evidence_asset_id)))
      const { data: assetDetails, error: detailsError } = assetIds.length
        ? await supabase
            .from('sparks_evidence_assets')
            .select('id,source_external_key,skdoc_document_id,current_version_id,metadata')
            .in('id', assetIds)
        : { data: [], error: null }

      if (cancelled) return

      if (detailsError) {
        setRows(projectionRows)
      } else {
        const detailById = new Map(
          ((assetDetails ?? []) as Array<{
            id: string
            source_external_key: string | null
            skdoc_document_id: string | null
            current_version_id: string | null
            metadata: Record<string, unknown> | null
          }>).map((detail) => [detail.id, detail]),
        )
        setRows(
          projectionRows.map((row) => ({
            ...row,
            ...(detailById.get(row.evidence_asset_id) ?? {}),
          })),
        )
      }
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
      if (queryError) { setOperationalChecklistRows([]); setOperationalChecklistError(queryError.message); return }
      setOperationalChecklistRows((data ?? []) as unknown as OperationalChecklistRow[])
    }
    void loadOperationalChecklist()
    return () => { cancelled = true }
  }, [checklistRefreshKey, organizationId, projectId])

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
        .select('evidence_asset_id,storage_bucket,storage_path,file_name,mime_type,file_size_bytes,version_number,version_label')
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

  useEffect(() => {
    if (!selectedEvidenceAssetId) return
    const timer = window.setTimeout(() => {
      selectedEvidenceAnalysisRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }, 0)
    return () => window.clearTimeout(timer)
  }, [selectedEvidenceAssetId])
  const selectedEvidenceAsset = useMemo(
    () => assets.find((asset) => asset.evidence_asset_id === selectedEvidenceAssetId) ?? null,
    [assets, selectedEvidenceAssetId],
  )

  useEffect(() => {
    let cancelled = false

    async function loadSelectedVersionHistory() {
      setVersionFile(null)
      setVersionReason('')
      setVersionMessage('')
      setPreviewVersionId(null)

      if (!selectedEvidenceAssetId) {
        setSelectedVersionHistory([])
        return
      }

      const { data, error: historyError } = await supabase
        .from('sparks_evidence_versions')
        .select('id,evidence_asset_id,storage_bucket,storage_path,file_name,mime_type,file_size_bytes,version_number,version_label,content_hash,change_summary,created_at')
        .eq('evidence_asset_id', selectedEvidenceAssetId)
        .order('version_number', { ascending: false })

      if (cancelled) return
      if (historyError) {
        setSelectedVersionHistory([])
        setVersionMessage(historyError.message)
        return
      }

      setSelectedVersionHistory((data ?? []) as EvidenceVersionDownload[])
    }

    void loadSelectedVersionHistory()
    return () => {
      cancelled = true
    }
  }, [selectedEvidenceAssetId, evidenceRefreshKey])
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

  const checklistRequirementRows = useMemo(() => checklistAxes.flatMap(({ axis, requirements }) =>
    requirements.map((requirement) => {
      const operational = operationalChecklistRows.find((row) => row.item_code === requirement.code)
      return {
        id: requirement.id,
        eixo: axis.name,
        codigo: requirement.code,
        requisito: requirement.name,
        evidencias: operational ? String(operational.files_count) : '0',
        atendimento: operational?.assessment_status ? statusLabel(operational.assessment_status) : 'Não avaliado',
        aderencia: operational?.compliance_level == null ? '—' : `${operational.compliance_level}%`,
        situacao: operational?.collection_status ? statusLabel(operational.collection_status) : 'Pendente',
      }
    }),
  ), [checklistAxes, operationalChecklistRows])

  const checklistRequirementColumns: SparksSmartGridColumn[] = [
    { id: 'eixo', label: 'Eixo', minWidth: 170, maxWidth: 260, tooltip: true },
    { id: 'codigo', label: 'Código', minWidth: 105, maxWidth: 130 },
    { id: 'requisito', label: 'Requisito / prática', minWidth: 300, maxWidth: 560, tooltip: true, grow: 2 },
    { id: 'evidencias', label: 'Evidências', minWidth: 105, maxWidth: 130, align: 'center' },
    { id: 'atendimento', label: 'Atendimento', minWidth: 150, maxWidth: 220 },
    { id: 'aderencia', label: 'Aderência', minWidth: 120, maxWidth: 150, align: 'center' },
    { id: 'situacao', label: 'Situação', minWidth: 135, maxWidth: 190 },
  ]

  const assetChecklistAxisMap = useMemo(() => {
    const axisByRequirementCode = new Map<string, string>()
    for (const group of checklistAxes) {
      for (const requirement of group.requirements) {
        axisByRequirementCode.set(requirement.code, group.axis.name)
      }
    }

    const requirementCodeByItemId = new Map(
      operationalChecklistRows.map((item) => [item.item_id, item.item_code]),
    )
    const axisNamesByAsset = new Map<string, Set<string>>()

    for (const link of rows) {
      if (link.target_type !== 'skpe_evidence_checklist_item' || !link.target_id) continue
      const requirementCode = requirementCodeByItemId.get(link.target_id)
      const axisName = requirementCode ? axisByRequirementCode.get(requirementCode) : null
      if (!axisName) continue
      const current = axisNamesByAsset.get(link.evidence_asset_id) ?? new Set<string>()
      current.add(axisName)
      axisNamesByAsset.set(link.evidence_asset_id, current)
    }

    return new Map(
      Array.from(axisNamesByAsset.entries()).map(([assetId, axisNames]) => [
        assetId,
        Array.from(axisNames).join(' · '),
      ]),
    )
  }, [checklistAxes, operationalChecklistRows, rows])

  const selectedChecklistRequirement = useMemo(() => {
    if (!selectedChecklistRequirementId) return null
    for (const group of checklistAxes) {
      const requirement = group.requirements.find((item) => item.id === selectedChecklistRequirementId)
      if (requirement) {
        return {
          axis: group.axis,
          requirement,
          operational: operationalChecklistRows.find((row) => row.item_code === requirement.code) ?? null,
        }
      }
    }
    return null
  }, [checklistAxes, operationalChecklistRows, selectedChecklistRequirementId])

  useEffect(() => {
    if (!selectedChecklistRequirementId && checklistRequirementRows.length > 0) {
      setSelectedChecklistRequirementId(checklistRequirementRows[0].id)
    }
  }, [checklistRequirementRows, selectedChecklistRequirementId])

  const checklistCoverage = useMemo(() => {
    const applicable = operationalChecklistRows.filter((row) => row.is_applicable)
    const required = applicable.filter((row) => row.is_required)
    const linked = required.filter((row) => Number(row.files_count) > 0)
    const validated = required.filter((row) => Number(row.validated_files_count) > 0)
    const assessed = required.filter((row) => {
      const status = row.assessment_status?.trim().toLowerCase() ?? ''
      return Boolean(status) && !['pending', 'not_assessed', 'not_started'].includes(status)
    })

    return {
      applicable: applicable.length,
      required: required.length,
      linked: linked.length,
      validated: validated.length,
      assessed: assessed.length,
      validatedCoverage: required.length ? Math.round((validated.length / required.length) * 100) : null,
    }
  }, [operationalChecklistRows])
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
        eixo: assetChecklistAxisMap.get(row.evidence_asset_id) ?? 'Não vinculado',
        categoria: categoryLabel(row.evidence_type),
        evidencia: row.title ?? 'Evidência sem título',
        situacao:
          availabilityLabels[row.availability_status ?? ''] ??
          row.availability_status ??
          'Não avaliada',
        origem: sourceReferenceLabel(
          row,
          downloadVersions.find((version) => version.evidence_asset_id === row.evidence_asset_id) ?? null,
        ),
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
    [assetChecklistAxisMap, downloadVersions, filteredAssets],
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

  function checklistDetail(value: unknown): string {
    if (Array.isArray(value)) {
      return value.map(checklistDetail).filter(Boolean).join(' · ')
    }
    if (value && typeof value === 'object') {
      return Object.values(value as Record<string, unknown>)
        .map(checklistDetail)
        .filter(Boolean)
        .join(' · ')
    }
    return value === null || value === undefined ? '' : String(value)
  }

  function statusLabel(value: string) {
    const normalized = value.trim().toLowerCase()
    const labels: Record<string, string> = {
      pending: 'Pendente',
      not_started: 'Não iniciado',
      not_assessed: 'Não avaliado',
      in_progress: 'Em andamento',
      collected: 'Coletado',
      linked: 'Associado',
      validated: 'Validado',
      approved: 'Aprovado',
      rejected: 'Rejeitado',
      partial: 'Parcialmente atendido',
      compliant: 'Atendido',
      non_compliant: 'Não atendido',
      high: 'Alto',
      medium: 'Médio',
      low: 'Baixo',
    }
    return labels[normalized] ?? value
  }

  function impactLabel(value: string | null) {
    return value ? statusLabel(value) : 'Não informado'
  }

  function openEvidenceMaintenance(id: string) {
    const asset = assets.find((item) => item.evidence_asset_id === id) ?? null
    setSelectedEvidenceAssetId(id)
    setEvidenceMaintenanceOpen(true)
    setAssociationChecklistItemId('')
    setAssociationReason('')
    setAssociationMessage('')
    setSeriesTitle(asset ? defaultSeriesTitle(asset) : '')
    setSeriesFiles([])
    setSeriesReason('')
    setSeriesMessage('')
  }

  function legacyEvidenceSourceId(row: EvidenceRow) {
    const value = row.metadata?.legacy_evidence_source_id
    return typeof value === 'string' && value.trim() ? value.trim() : null
  }

  async function associateEvidenceToChecklist() {
    if (!selectedEvidenceAsset || !associationChecklistItemId) {
      setAssociationMessage('Selecione um requisito do checklist para associar esta evidência.')
      return
    }
    const target = operationalChecklistRows.find((row) => row.item_id === associationChecklistItemId)
    if (!target) {
      setAssociationMessage('O requisito selecionado ainda não está materializado no checklist operacional.')
      return
    }
    if (associationReason.trim().length < 10) {
      setAssociationMessage('Informe uma justificativa com pelo menos 10 caracteres.')
      return
    }

    setAssociatingEvidence(true)
    setAssociationMessage('')

    try {
      const latestVersion = downloadVersions.find(
        (version) => version.evidence_asset_id === selectedEvidenceAsset.evidence_asset_id,
      )
      const sourceId = legacyEvidenceSourceId(selectedEvidenceAsset)

      const { data: existingFiles, error: existingError } = await supabase
        .from('skpe_evidence_checklist_item_files')
        .select('id,evidence_source_id,skdoc_document_id,storage_path,file_name')
        .eq('checklist_item_id', target.item_id)

      if (existingError) throw existingError

      const alreadyLinked = (existingFiles ?? []).some((file: any) =>
        (sourceId && file.evidence_source_id === sourceId) ||
        (selectedEvidenceAsset.skdoc_document_id && file.skdoc_document_id === selectedEvidenceAsset.skdoc_document_id) ||
        (latestVersion?.storage_path && file.storage_path === latestVersion.storage_path),
      )

      if (!alreadyLinked) {
        const { error: registerError } = await supabase.rpc('register_skpe_checklist_item_file', {
          target_checklist_item_id: target.item_id,
          file_name: latestVersion?.file_name ?? selectedEvidenceAsset.title ?? 'Evidência associada',
          storage_bucket: latestVersion?.storage_bucket ?? null,
          storage_path: latestVersion?.storage_path ?? null,
          mime_type: latestVersion?.mime_type ?? null,
          file_size_bytes: latestVersion?.file_size_bytes ?? null,
          evidence_source_id: sourceId,
          skdoc_document_id: selectedEvidenceAsset.skdoc_document_id ?? null,
          document_date: selectedEvidenceAsset.reference_date ?? null,
          reference_period_start: selectedEvidenceAsset.reference_period_start ?? null,
          reference_period_end: selectedEvidenceAsset.reference_period_end ?? null,
          version_label: latestVersion?.version_label ?? null,
          confidentiality_level: 'internal',
          notes: sourceReferenceLabel(selectedEvidenceAsset, latestVersion ?? null),
          change_reason: associationReason.trim(),
        })
        if (registerError) throw registerError
      }

      const { error: linkError } = await supabase.rpc('link_sparks_evidence', {
        target_organization_id: organizationId,
        target_evidence_asset_id: selectedEvidenceAsset.evidence_asset_id,
        target_module_code: 'SK-PE',
        target_type: 'skpe_evidence_checklist_item',
        target_id: target.item_id,
        target_usage_purpose: `Evidência associada ao requisito ${target.item_code} — ${target.item_name} do checklist PEM-00.`,
        target_relevance_level: 'important',
        target_is_primary: false,
        change_reason: associationReason.trim(),
      })
      if (linkError) throw linkError

      setAssociationMessage(
        alreadyLinked
          ? 'A evidência já estava associada a este requisito. O vínculo governado foi confirmado.'
          : 'Evidência associada ao requisito com rastreabilidade e auditoria.',
      )
      setChecklistRefreshKey((value) => value + 1)
      setEvidenceRefreshKey((value) => value + 1)
    } catch (caught) {
      setAssociationMessage(
        caught instanceof Error ? caught.message : 'Não foi possível associar a evidência ao requisito.',
      )
    } finally {
      setAssociatingEvidence(false)
    }
  }

  async function registerEvidenceSeriesFiles() {
    if (!selectedEvidenceAsset) {
      setSeriesMessage('Selecione uma evidência para iniciar a série documental.')
      return
    }
    const title = seriesTitle.trim()
    if (!title) {
      setSeriesMessage('Informe o nome da série documental.')
      return
    }
    if (seriesFiles.length === 0) {
      setSeriesMessage('Selecione um ou mais arquivos da série histórica.')
      return
    }
    if (seriesReason.trim().length < 10) {
      setSeriesMessage('Informe uma justificativa com pelo menos 10 caracteres.')
      return
    }

    const fileYears = seriesFiles.map((file) => ({ file, year: inferDocumentYear(file.name) }))
    const ambiguous = fileYears.filter((item) => !item.year)
    if (ambiguous.length > 0) {
      setSeriesMessage(
        `Não foi possível identificar uma competência única em: ${ambiguous.map((item) => item.file.name).join(', ')}. Inclua o ano no nome do arquivo.`,
      )
      return
    }

    const repeatedYears = fileYears
      .map((item) => item.year as string)
      .filter((year, index, years) => years.indexOf(year) !== index)
    if (repeatedYears.length > 0) {
      setSeriesMessage(`Há mais de um arquivo para a mesma competência: ${Array.from(new Set(repeatedYears)).join(', ')}.`)
      return
    }

    setRegisteringSeries(true)
    setSeriesMessage('')

    const seriesKey = normalizeSeriesKey(title)
    const results: string[] = []
    const uploadedPaths: string[] = []

    try {
      for (const { file, year } of fileYears) {
        const period = year as string
        const contentHash = await fileSha256(file)

        const { data: duplicateAsset, error: duplicateLookupError } = await supabase
          .from('sparks_evidence_assets')
          .select('id,title')
          .eq('organization_id', organizationId)
          .eq('content_hash', contentHash)
          .is('archived_at', null)
          .maybeSingle()
        if (duplicateLookupError) throw duplicateLookupError

        let storagePath: string | null = null
        if (!duplicateAsset) {
          storagePath = `${organizationId}/${period}/series/${crypto.randomUUID()}-${safeStorageFileName(file.name)}`
          const { error: uploadError } = await supabase.storage
            .from('sparks-evidence')
            .upload(storagePath, file, {
              cacheControl: '3600',
              contentType: file.type || undefined,
              upsert: false,
            })
          if (uploadError) throw uploadError
          uploadedPaths.push(storagePath)
        }

        const { data: registration, error: registrationError } = await supabase.rpc(
          'register_sparks_evidence_series_document',
          {
            target_organization_id: organizationId,
            target_series_key: seriesKey,
            target_series_title: title,
            target_document_family: title,
            target_period_label: period,
            target_period_start: `${period}-01-01`,
            target_period_end: `${period}-12-31`,
            target_reference_date: `${period}-12-31`,
            target_evidence_title: `${title} — ${period}`,
            target_origin_module_code: 'SK-PE',
            target_content_hash: contentHash,
            target_file_name: file.name,
            target_mime_type: file.type || null,
            target_file_size_bytes: file.size,
            target_storage_bucket: duplicateAsset ? null : 'sparks-evidence',
            target_storage_path: storagePath,
            change_reason: seriesReason.trim(),
            seed_evidence_asset_id: selectedEvidenceAsset.evidence_asset_id,
          },
        )
        if (registrationError) {
          if (storagePath) {
            await supabase.storage.from('sparks-evidence').remove([storagePath])
            const index = uploadedPaths.indexOf(storagePath)
            if (index >= 0) uploadedPaths.splice(index, 1)
          }
          throw registrationError
        }

        const status = String((registration as any)?.status ?? '')
        if (storagePath && status !== 'duplicate_content' && status !== 'duplicate_content_reused') {
          const index = uploadedPaths.indexOf(storagePath)
          if (index >= 0) uploadedPaths.splice(index, 1)
        }
        if (status === 'duplicate_content' || status === 'duplicate_content_reused') {
          if (storagePath) {
            await supabase.storage.from('sparks-evidence').remove([storagePath])
            const index = uploadedPaths.indexOf(storagePath)
            if (index >= 0) uploadedPaths.splice(index, 1)
          }
          results.push(`${period}: conteúdo já existente, reutilizado sem duplicação física`)
        } else if (status === 'created_period_version') {
          results.push(`${period}: nova versão registrada para a competência`)
        } else {
          results.push(`${period}: documento da série registrado`)
        }
      }

      setSeriesMessage(`Série processada. ${results.join(' · ')}`)
      setSeriesFiles([])
      setSeriesReason('')
      setEvidenceRefreshKey((value) => value + 1)
    } catch (caught) {
      for (const path of uploadedPaths) {
        await supabase.storage.from('sparks-evidence').remove([path])
      }
      setSeriesMessage(
        caught instanceof Error ? caught.message : 'Não foi possível registrar a série documental.',
      )
    } finally {
      setRegisteringSeries(false)
    }
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
  async function saveEvidenceVersion() {
    if (!selectedEvidenceAssetId) { setVersionMessage('Selecione uma evidência.'); return }
    if (!versionFile) { setVersionMessage('Selecione o arquivo da nova versão.'); return }
    if (versionReason.trim().length < 10) { setVersionMessage('Informe uma justificativa com pelo menos 10 caracteres.'); return }

    setSavingVersion(true)
    setVersionMessage('')
    let uploadedPath: string | null = null

    try {
      const contentHash = await fileSha256(versionFile)
      if (selectedVersionHistory.some((version) => version.content_hash === contentHash)) {
        setVersionMessage('Este arquivo já existe no histórico de versões da evidência.')
        setSavingVersion(false)
        return
      }

      const safeName = safeStorageFileName(versionFile.name)
      const now = new Date()
      uploadedPath = `${organizationId}/${now.getFullYear()}/${selectedEvidenceAssetId}/${crypto.randomUUID()}-${safeName}`

      const { error: uploadError } = await supabase.storage
        .from('sparks-evidence')
        .upload(uploadedPath, versionFile, {
          cacheControl: '3600',
          contentType: versionFile.type || undefined,
          upsert: false,
        })
      if (uploadError) throw uploadError

      const { error: versionError } = await supabase.rpc(
        'add_sparks_evidence_version',
        {
          target_organization_id: organizationId,
          target_evidence_asset_id: selectedEvidenceAssetId,
          target_content_hash: contentHash,
          target_file_name: versionFile.name,
          target_mime_type: versionFile.type || null,
          target_file_size_bytes: versionFile.size,
          target_storage_bucket: 'sparks-evidence',
          target_storage_path: uploadedPath,
          change_reason: versionReason.trim(),
        },
      )
      if (versionError) throw versionError

      setVersionFile(null)
      setVersionReason('')
      setVersionMessage('Nova versão registrada. A evidência retornou para validação, preservando todo o histórico anterior.')
      setEvidenceRefreshKey((value) => value + 1)
    } catch (caught) {
      if (uploadedPath) {
        await supabase.storage.from('sparks-evidence').remove([uploadedPath])
      }
      setVersionMessage(caught instanceof Error ? caught.message : 'Não foi possível registrar a nova versão.')
    } finally {
      setSavingVersion(false)
    }
  }

  async function downloadEvidenceVersion(version: EvidenceVersionDownload, fallbackName: string) {
    if (!version.storage_bucket || !version.storage_path) return
    const { data, error: downloadError } = await supabase.storage
      .from(version.storage_bucket)
      .download(version.storage_path)
    if (downloadError || !data) return
    const url = URL.createObjectURL(data)
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.download = version.file_name ?? fallbackName
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(url)
  }
  async function downloadEvidence(asset: EvidenceRow) {
    const version = downloadVersions.find(
      (item) => item.evidence_asset_id === asset.evidence_asset_id,
    )
    if (!version?.storage_bucket || !version.storage_path) return
    await downloadEvidenceVersion(version, asset.title ?? 'evidencia')
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
          ) : operationalChecklistRows.length === 0 ? (
            <span>O checklist do projeto ainda não foi materializado. Os requisitos previstos abaixo vêm do padrão metodológico publicado e devem ser reconciliados com evidências já disponíveis na organização antes de novas solicitações.</span>
          ) : (
            <span>Checklist do projeto disponível com {operationalChecklistRows.length} itens para coleta, vínculo e avaliação de evidências.</span>
          )}
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
      <section className="skpe-evidence-coverage" aria-label="Cobertura governada do checklist de evidências">
        <header>
          <div><span className="skpe-evidence-section__eyebrow">Cobertura do checklist</span><h3>Requisito ≠ arquivo ≠ evidência suficiente</h3></div>
          <p>A cobertura abaixo só existe quando o checklist operacional foi materializado. Arquivo vinculado não é tratado automaticamente como evidência validada ou suficiente.</p>
        </header>
        {operationalChecklistRows.length === 0 ? (
          <div className="skpe-evidence-coverage-empty">Cobertura ainda indisponível: o checklist operacional do projeto não foi materializado.</div>
        ) : (
          <div className="skpe-evidence-coverage-grid">
            <article><span>Requisitos obrigatórios aplicáveis</span><strong>{checklistCoverage.required}</strong></article>
            <article><span>Com arquivo vinculado</span><strong>{checklistCoverage.linked}</strong><small>vínculo físico não implica validação</small></article>
            <article><span>Com arquivo validado</span><strong>{checklistCoverage.validated}</strong><small>{checklistCoverage.validatedCoverage == null ? '—' : `${checklistCoverage.validatedCoverage}%`} dos obrigatórios</small></article>
            <article><span>Itens avaliados</span><strong>{checklistCoverage.assessed}</strong><small>avaliação contextual registrada</small></article>
          </div>
        )}
        <p className="skpe-evidence-coverage-rule">Suficiência permanece uma avaliação contextual governada. Ela não é derivada da quantidade de arquivos nem do percentual de cobertura.</p>
      </section>
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
          label="Em uso estratégico"
          value={counts.used || '—'}
          helper={
            counts.used
              ? `${counts.used} evidências vinculadas a uso analítico`
              : 'nenhuma evidência marcada como atualmente utilizada'
          }
          active={activeFilter === 'used'}
          onClick={counts.used > 0 ? () => toggleFilter('used') : undefined}
          disabled={counts.used === 0}
          ariaLabel="Filtrar evidências em uso estratégico"
          tooltip="Uso estratégico é distinto da cobertura de requisitos do checklist."
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
              selectedId={activeFilter === 'expected' ? null : selectedEvidenceAssetId}
              onSelect={activeFilter === 'expected' ? undefined : setSelectedEvidenceAssetId}
              onActivate={activeFilter === 'expected' ? undefined : openEvidenceMaintenance}
              primaryActionLabel="Abrir manutenção"
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

      {evidenceMaintenanceOpen && selectedEvidenceAsset ? (
        <aside className="skpe-evidence-maintenance-workspace" aria-label="Manutenção da evidência">
          <button
            type="button"
            className="skpe-evidence-maintenance-backdrop"
            aria-label="Fechar manutenção da evidência"
            onClick={() => setEvidenceMaintenanceOpen(false)}
          />
          <section className="skpe-evidence-maintenance-panel">
            <header>
              <div>
                <span className="skpe-evidence-section__eyebrow">Manutenção da evidência</span>
                <h2>{selectedEvidenceAsset.title ?? 'Evidência sem título'}</h2>
                <p>{sourceReferenceLabel(
                  selectedEvidenceAsset,
                  downloadVersions.find((version) => version.evidence_asset_id === selectedEvidenceAsset.evidence_asset_id) ?? null,
                )}</p>
              </div>
              <button type="button" onClick={() => setEvidenceMaintenanceOpen(false)} aria-label="Fechar">×</button>
            </header>

            <section className="skpe-evidence-maintenance-summary">
              <dl>
                <div><dt>Eixo associado</dt><dd>{assetChecklistAxisMap.get(selectedEvidenceAsset.evidence_asset_id) ?? 'Não vinculado'}</dd></div>
                <div><dt>Origem</dt><dd>{originLabel(selectedEvidenceAsset)}</dd></div>
                <div><dt>Período / vigência</dt><dd>{periodLabel(selectedEvidenceAsset)}</dd></div>
                <div><dt>Qualidade</dt><dd>{qualityLabels[selectedEvidenceAsset.quality_status ?? ''] ?? selectedEvidenceAsset.quality_status ?? 'Não avaliada'}</dd></div>
                <div><dt>Suficiência</dt><dd>{sufficiencyLabels[selectedEvidenceAsset.sufficiency_status ?? ''] ?? selectedEvidenceAsset.sufficiency_status ?? 'Não avaliada'}</dd></div>
                <div><dt>Chave de origem</dt><dd>{selectedEvidenceAsset.source_external_key ?? 'Não informada'}</dd></div>
              </dl>
            </section>

            <section className="skpe-evidence-maintenance-section">
              <div className="skpe-evidence-detail-section-heading">
                <div><span className="skpe-evidence-section__eyebrow">Rastreabilidade</span><h3>Referência da fonte original</h3></div>
              </div>
              <p className="skpe-evidence-source-reference">
                {sourceReferenceLabel(
                  selectedEvidenceAsset,
                  downloadVersions.find((version) => version.evidence_asset_id === selectedEvidenceAsset.evidence_asset_id) ?? null,
                )}
              </p>
              <small>
                Esta referência identifica a origem recuperável da evidência; o título resumido, como “E05 — Mandioca”, não substitui a proveniência.
              </small>
            </section>

            <section className="skpe-evidence-maintenance-section">
              <div className="skpe-evidence-detail-section-heading">
                <div><span className="skpe-evidence-section__eyebrow">Vínculo metodológico</span><h3>Associar a eixo / requisito do PEM-00</h3></div>
              </div>
              {operationalChecklistRows.length === 0 ? (
                <div className="skpe-evidence-detail-empty">
                  O checklist operacional ainda não foi materializado; por isso o vínculo não pode ser gravado neste momento.
                </div>
              ) : (
                <>
                  <label className="skpe-evidence-maintenance-field">
                    <span>Requisito *</span>
                    <select value={associationChecklistItemId} onChange={(event) => setAssociationChecklistItemId(event.target.value)}>
                      <option value="">Selecione o requisito</option>
                      {operationalChecklistRows.map((item) => (
                        <option key={item.item_id} value={item.item_id}>
                          {item.item_code} — {item.item_name}
                        </option>
                      ))}
                    </select>
                  </label>
                  <label className="skpe-evidence-maintenance-field">
                    <span>Justificativa do vínculo *</span>
                    <textarea
                      value={associationReason}
                      onChange={(event) => setAssociationReason(event.target.value)}
                      placeholder="Explique por que esta evidência atende ou apoia o requisito selecionado."
                    />
                  </label>
                  {associationMessage ? <div className="skpe-evidence-version-message" role="status">{associationMessage}</div> : null}
                  <button
                    type="button"
                    className="skpe-evidence-version-primary"
                    disabled={associatingEvidence}
                    onClick={() => void associateEvidenceToChecklist()}
                  >
                    {associatingEvidence ? 'Associando...' : 'Associar evidência ao requisito'}
                  </button>
                </>
              )}
            </section>

            <section className="skpe-evidence-maintenance-section skpe-evidence-series-section">
              <div className="skpe-evidence-detail-section-heading">
                <div>
                  <span className="skpe-evidence-section__eyebrow">Série documental</span>
                  <h3>Análise histórica por competência</h3>
                </div>
              </div>
              <p className="skpe-evidence-version-guidance">
                Exercícios diferentes não são versões entre si. Cada competência vira um documento próprio da série; somente republicações do mesmo exercício geram nova versão.
              </p>
              <label className="skpe-evidence-maintenance-field">
                <span>Nome da série *</span>
                <input
                  value={seriesTitle}
                  onChange={(event) => setSeriesTitle(event.target.value)}
                  placeholder="Ex.: Balanço Patrimonial"
                />
              </label>
              <label className="skpe-evidence-maintenance-field">
                <span>Arquivos da série *</span>
                <input
                  type="file"
                  multiple
                  key={`series-${evidenceRefreshKey}`}
                  onChange={(event) => setSeriesFiles(Array.from(event.target.files ?? []))}
                />
              </label>
              {seriesFiles.length > 0 ? (
                <div className="skpe-evidence-series-preview">
                  {seriesFiles.map((file) => {
                    const year = inferDocumentYear(file.name)
                    return (
                      <div key={`${file.name}:${file.size}`}>
                        <strong>{year ?? 'Ano não identificado'}</strong>
                        <span>{file.name}</span>
                      </div>
                    )
                  })}
                </div>
              ) : null}
              <label className="skpe-evidence-maintenance-field">
                <span>Justificativa do registro da série *</span>
                <textarea
                  value={seriesReason}
                  onChange={(event) => setSeriesReason(event.target.value)}
                  placeholder="Ex.: inclusão da série histórica de demonstrações financeiras para análise evolutiva."
                />
              </label>
              {seriesMessage ? <div className="skpe-evidence-version-message" role="status">{seriesMessage}</div> : null}
              <button
                type="button"
                className="skpe-evidence-version-primary"
                disabled={registeringSeries || seriesFiles.length === 0}
                onClick={() => void registerEvidenceSeriesFiles()}
              >
                {registeringSeries ? 'Processando série...' : 'Registrar série histórica'}
              </button>
            </section>

            <section className="skpe-evidence-maintenance-section">
              <div className="skpe-evidence-detail-section-heading">
                <div><span className="skpe-evidence-section__eyebrow">Arquivo e versão</span><h3>Conteúdo materializado</h3></div>
              </div>
              {(() => {
                const version = downloadVersions.find((item) => item.evidence_asset_id === selectedEvidenceAsset.evidence_asset_id)
                return version?.storage_bucket && version.storage_path ? (
                  <>
                    <div className="skpe-evidence-maintenance-file">
                      <div>
                        <strong>{version.file_name ?? 'Arquivo sem nome'}</strong>
                        <span>Versão {version.version_label ?? version.version_number ?? '—'}</span>
                      </div>
                      <button type="button" onClick={() => void downloadEvidence(selectedEvidenceAsset)}>Baixar arquivo</button>
                    </div>
                    <div className="skpe-evidence-inline-preview">
                      <div className="skpe-evidence-detail-section-heading">
                        <div>
                          <span className="skpe-evidence-section__eyebrow">Visualização</span>
                          <h4>Prévia do arquivo</h4>
                        </div>
                      </div>
                      <EvidenceFilePreview
                        storageBucket={version.storage_bucket}
                        storagePath={version.storage_path}
                        fileName={version.file_name ?? selectedEvidenceAsset.title ?? 'evidencia'}
                        mimeType={version.mime_type}
                      />
                    </div>
                  </>
                ) : (
                  <div className="skpe-evidence-detail-empty">
                    Esta evidência ainda não possui arquivo físico recuperável. Ela pode ser uma evidência declarativa migrada ou apenas um cadastro documental.
                  </div>
                )
              })()}
              <div className="skpe-evidence-maintenance-history">
                {(() => {
                  const physicalVersions = selectedVersionHistory.filter(
                    (version) => Boolean(version.storage_bucket && version.storage_path),
                  )
                  const historicalReferences = selectedVersionHistory.filter(
                    (version) => !version.storage_bucket || !version.storage_path,
                  )
                  return (
                    <>
                      <div className="skpe-evidence-detail-section-heading">
                        <h4>Versões físicas</h4>
                        <strong>{physicalVersions.length}</strong>
                      </div>
                      {physicalVersions.length === 0 ? (
                        <div className="skpe-evidence-detail-empty">Nenhuma versão física registrada.</div>
                      ) : (
                        physicalVersions.map((version) => (
                          <article key={version.id ?? `${version.evidence_asset_id}:${version.version_number}`}>
                            <div>
                              <strong>v{version.version_label ?? version.version_number ?? '—'}</strong>
                              <span>{version.file_name ?? 'Arquivo sem nome'}</span>
                              <small>{version.created_at ? new Date(version.created_at).toLocaleString('pt-BR') : 'Data não informada'}</small>
                            </div>
                            <div className="skpe-evidence-version-actions">
                              <button
                                type="button"
                                onClick={() => setPreviewVersionId(version.id ?? null)}
                              >
                                Visualizar
                              </button>
                              <button
                                type="button"
                                onClick={() => void downloadEvidenceVersion(version, selectedEvidenceAsset.title ?? 'evidencia')}
                              >
                                Baixar
                              </button>
                            </div>
                          </article>
                        ))
                      )}
                      {historicalReferences.length > 0 ? (
                        <details className="skpe-evidence-historical-references">
                          <summary>{historicalReferences.length} referência(s) histórica(s) sem arquivo físico</summary>
                          <p>
                            Estes registros preservam a rastreabilidade de fontes localizadas anteriormente, mas não contam como PDFs ou versões físicas armazenadas.
                          </p>
                          {historicalReferences.map((version) => (
                            <article key={version.id ?? `reference:${version.version_number}`}>
                              <div>
                                <strong>Referência {version.version_label ?? version.version_number ?? '—'}</strong>
                                <span>{version.file_name ?? 'Fonte histórica sem arquivo'}</span>
                                <small>{version.change_summary ?? 'Sem observação adicional.'}</small>
                              </div>
                            </article>
                          ))}
                        </details>
                      ) : null}
                      {(() => {
                        const previewVersion = physicalVersions.find((version) => version.id === previewVersionId)
                        if (!previewVersion?.storage_bucket || !previewVersion.storage_path) return null
                        return (
                          <div className="skpe-evidence-version-preview">
                            <div className="skpe-evidence-detail-section-heading">
                              <div>
                                <span className="skpe-evidence-section__eyebrow">Versão selecionada</span>
                                <h4>
                                  v{previewVersion.version_label ?? previewVersion.version_number ?? '—'} · {previewVersion.file_name ?? 'Arquivo'}
                                </h4>
                              </div>
                              <button type="button" onClick={() => setPreviewVersionId(null)}>Fechar prévia</button>
                            </div>
                            <EvidenceFilePreview
                              storageBucket={previewVersion.storage_bucket}
                              storagePath={previewVersion.storage_path}
                              fileName={previewVersion.file_name ?? selectedEvidenceAsset.title ?? 'evidencia'}
                              mimeType={previewVersion.mime_type}
                            />
                          </div>
                        )
                      })()}
                    </>
                  )
                })()}
              </div>
              <p className="skpe-evidence-version-guidance">
                A versão anterior será preservada. O novo arquivo se tornará a versão corrente e a evidência retornará para validação humana.
              </p>
              <label className="skpe-evidence-maintenance-field">
                <span>Novo arquivo / nova versão</span>
                <input type="file" key={evidenceRefreshKey} onChange={(event) => setVersionFile(event.target.files?.[0] ?? null)} />
              </label>
              <label className="skpe-evidence-maintenance-field">
                <span>Justificativa da nova versão</span>
                <textarea
                  value={versionReason}
                  onChange={(event) => setVersionReason(event.target.value)}
                  placeholder="Informe o que mudou e por que esta versão deve substituir a atual."
                />
              </label>
              {versionMessage ? <div className="skpe-evidence-version-message" role="status">{versionMessage}</div> : null}
              <button
                type="button"
                className="skpe-evidence-version-primary"
                disabled={savingVersion || !versionFile}
                onClick={() => void saveEvidenceVersion()}
              >
                {savingVersion ? 'Registrando versão...' : 'Registrar nova versão'}
              </button>
            </section>
          </section>
        </aside>
      ) : null}

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

            {operationalChecklistRows.length === 0 ? (
              <div className="skpe-evidence-checklist-notice">
                <strong>Checklist operacional ainda não materializado para este projeto.</strong>
                <span>
                  A estrutura abaixo é a versão metodológica publicada. Evidências da organização não serão atribuídas automaticamente a um requisito sem vínculo governado.
                </span>
              </div>
            ) : null}

            <div className="skpe-evidence-checklist-master-detail">
              <section className="skpe-evidence-checklist-grid">
                <header><div><span className="skpe-evidence-section__eyebrow">Checklist PEM-00</span><h3>Requisitos e práticas</h3></div><p>Selecione um registro para consultar evidências, critérios e avaliação no painel lateral.</p></header>
                <SparksSmartGrid rows={checklistRequirementRows} columns={checklistRequirementColumns} ariaLabel="Requisitos e práticas do checklist metodológico PEM-00" selectedId={selectedChecklistRequirementId} onSelect={setSelectedChecklistRequirementId} onActivate={setSelectedChecklistRequirementId} primaryActionLabel="Abrir detalhes" viewportMode="compact" className="skpe-evidence-checklist-smart-grid" emptyMessage="Nenhum requisito metodológico disponível." />
              </section>
              <aside className="skpe-evidence-requirement-detail">
                {selectedChecklistRequirement ? (<>
                  <header><span className="skpe-evidence-section__eyebrow">Detalhes do requisito</span><strong>{selectedChecklistRequirement.requirement.code}</strong><h3>{selectedChecklistRequirement.requirement.name}</h3><p>{selectedChecklistRequirement.axis.name}</p></header>
                  {selectedChecklistRequirement.requirement.description ? (<section><h4>O que será avaliado</h4><p>{selectedChecklistRequirement.requirement.description}</p></section>) : null}
                  <section><h4>Critérios e práticas de referência</h4><p>{checklistDetail(selectedChecklistRequirement.requirement.best_practice_criteria) || 'Não informados.'}</p></section>
                  <section><h4>Evidências esperadas</h4><p>{checklistDetail(selectedChecklistRequirement.requirement.possible_evidences) || 'Não informadas.'}</p></section>
                  <section><h4>Impacto da ausência</h4><p>{impactLabel(selectedChecklistRequirement.requirement.absence_impact)}</p></section>
                  <section className="skpe-evidence-associated-section"><div className="skpe-evidence-detail-section-heading"><h4>Evidências associadas</h4><strong>{selectedChecklistRequirement.operational?.files_count ?? 0}</strong></div>{(selectedChecklistRequirement.operational?.files_count ?? 0) > 0 ? (<p>Há evidência(s) vinculada(s) a este requisito no checklist operacional. A abertura individual será feita a partir do vínculo governado do requisito, sem misturar o acervo geral da organização.</p>) : (<div className="skpe-evidence-detail-empty">Nenhuma evidência foi associada a este requisito.</div>)}</section>
                  <section><h4>Avaliação do SK-PE</h4><dl className="skpe-evidence-requirement-assessment"><div><dt>Atendimento</dt><dd>{selectedChecklistRequirement.operational?.assessment_status ? statusLabel(selectedChecklistRequirement.operational.assessment_status) : 'Não avaliado'}</dd></div><div><dt>Aderência</dt><dd>{selectedChecklistRequirement.operational?.compliance_level == null ? 'Não avaliada' : String(selectedChecklistRequirement.operational.compliance_level) + '%'}</dd></div><div><dt>Situação da coleta</dt><dd>{selectedChecklistRequirement.operational?.collection_status ? statusLabel(selectedChecklistRequirement.operational.collection_status) : 'Pendente'}</dd></div><div><dt>Evidências validadas</dt><dd>{selectedChecklistRequirement.operational?.validated_files_count ?? 0}</dd></div></dl></section>
                  <p className="skpe-evidence-detail-authority">O SK-DOC governa o documento e suas versões. O SK-PE registra o vínculo com este requisito e a avaliação específica de atendimento, aderência, suficiência e maturidade.</p>
                </>) : (<div className="skpe-evidence-detail-empty">Selecione um requisito no GRID para abrir seus detalhes.</div>)}
              </aside>
            </div>
          </div>
        </aside>
      ) : null}
    </section>
  )
}
