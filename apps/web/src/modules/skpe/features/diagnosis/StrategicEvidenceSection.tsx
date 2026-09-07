import { useEffect, useMemo, useState } from 'react'
import { SparksGridNavigator } from '../../../../components/design-system/SparksGridNavigator'
import { Filter, X } from 'lucide-react'
import { Grid, type IColumnConfig } from '@svar-ui/react-grid'
import '@svar-ui/react-grid/all.css'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './StrategicEvidenceSection.css'

type StrategicEvidenceSectionProps = {
  organizationId: string
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
  is_required: boolean
  display_order: number
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

type CardFilter =
  | 'expected'
  | 'available'
  | 'reused'
  | 'valid'
  | 'used'
  | 'insufficient'
  | null

type ColumnFilterId =
  | 'eixo'
  | 'categoria'
  | 'evidencia'
  | 'situacao'
  | 'origem'
  | 'disponibilizada_em'
  | 'disponibilizada_por'
  | 'periodo_vigencia'
  | 'qualidade'
  | 'suficiencia'
  | 'utilizada'

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

const columnFilterIds: ColumnFilterId[] = [
  'eixo',
  'categoria',
  'evidencia',
  'situacao',
  'origem',
  'disponibilizada_em',
  'disponibilizada_por',
  'periodo_vigencia',
  'qualidade',
  'suficiencia',
  'utilizada',
]

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

export function StrategicEvidenceSection({
  organizationId,
}: StrategicEvidenceSectionProps) {
  const [rows, setRows] = useState<EvidenceRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [activeFilter, setActiveFilter] = useState<CardFilter>(null)

  const [expectedItems, setExpectedItems] = useState<ExpectedChecklistItem[]>([])
  const [expectedLoading, setExpectedLoading] = useState(true)
  const [expectedError, setExpectedError] = useState('')

  const [columnFilters, setColumnFilters] = useState<
    Partial<Record<ColumnFilterId, string>>
  >({})
  const [openColumnFilter, setOpenColumnFilter] =
    useState<ColumnFilterId | null>(null)

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
  }, [organizationId])

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
        .eq('version_code', '2026.2')
        .maybeSingle()

      if (cancelled) return

      if (versionError || !version) {
        setExpectedItems([])
        setExpectedError(
          versionError?.message ?? 'Versão 2026.2 do PEM-00 não localizada.',
        )
        setExpectedLoading(false)
        return
      }

      const { data: items, error: itemsError } = await supabase
        .from('sparks_checklist_template_items')
        .select(
          'id,parent_item_id,code,item_type,name,is_required,display_order',
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
        origem: 'PEM-00 2026.2 - Checklist Padrão de Evidências',
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

  const displayedGridData = useMemo(
    () =>
      selectedGridData.filter((row) =>
        columnFilterIds.every((id) => {
          const filterValue = (columnFilters[id] ?? '')
            .trim()
            .toLocaleLowerCase('pt-BR')

          if (!filterValue) return true

          const cellValue = row[id].toLocaleLowerCase('pt-BR')
          return cellValue.includes(filterValue)
        }),
      ),
    [columnFilters, selectedGridData],
  )

  function EvidenceHeaderCell(props: any) {
    const id = props.column.id as ColumnFilterId
    const label = props.cell.text as string
    const value = columnFilters[id] ?? ''
    const open = openColumnFilter === id

    return (
      <div className="skpe-evidence-header-cell">
        {open ? (
          <div
            className="skpe-evidence-header-inline-filter"
            onClick={(event) => event.stopPropagation()}
          >
            <input
              autoFocus
              value={value}
              placeholder={label}
              aria-label={`Filtrar ${label}`}
              onChange={(event) =>
                setColumnFilters((current) => ({
                  ...current,
                  [id]: event.target.value,
                }))
              }
              onKeyDown={(event) => {
                if (event.key === 'Escape') {
                  setOpenColumnFilter(null)
                }
              }}
            />
            {value ? (
              <button
                type="button"
                className="skpe-evidence-header-filter-clear"
                aria-label={`Limpar filtro de ${label}`}
                title={`Limpar filtro de ${label}`}
                onClick={(event) => {
                  event.stopPropagation()
                  setColumnFilters((current) => ({
                    ...current,
                    [id]: '',
                  }))
                }}
              >
                <X aria-hidden="true" size={14} />
              </button>
            ) : null}
          </div>
        ) : (
          <span className="skpe-evidence-header-label">{label}</span>
        )}

        <button
          type="button"
          className={
            value
              ? 'skpe-evidence-header-filter-button skpe-evidence-header-filter-button--active'
              : 'skpe-evidence-header-filter-button'
          }
          aria-label={`${open ? 'Fechar' : 'Abrir'} filtro de ${label}`}
          title={`${open ? 'Fechar' : 'Filtrar'} ${label}`}
          onClick={(event) => {
            event.stopPropagation()
            setOpenColumnFilter((current) => (current === id ? null : id))
          }}
        >
          <Filter aria-hidden="true" size={14} />
        </button>
      </div>
    )
  }

  const columns: IColumnConfig[] = [
    {
      id: 'eixo',
      header: {
        text: 'Eixo',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 160,
      sort: true,
      resize: true,
    },
    {
      id: 'categoria',
      header: {
        text: 'Categoria',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 190,
      sort: true,
      resize: true,
    },
    {
      id: 'evidencia',
      header: {
        text: 'Evidência',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 340,
      sort: true,
      resize: true,
    },
    {
      id: 'situacao',
      header: {
        text: 'Situação',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 175,
      sort: true,
      resize: true,
    },
    {
      id: 'origem',
      header: {
        text: 'Origem',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 320,
      sort: true,
      resize: true,
    },
    {
      id: 'disponibilizada_em',
      header: {
        text: 'Disponibilizada em',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 190,
      sort: true,
      resize: true,
    },
    {
      id: 'disponibilizada_por',
      header: {
        text: 'Disponibilizada por',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 260,
      sort: true,
      resize: true,
    },
    {
      id: 'periodo_vigencia',
      header: {
        text: 'Período / Vigência',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 285,
      sort: true,
      resize: true,
    },
    {
      id: 'qualidade',
      header: {
        text: 'Qualidade',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 170,
      sort: true,
      resize: true,
    },
    {
      id: 'suficiencia',
      header: {
        text: 'Suficiência',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 220,
      sort: true,
      resize: true,
    },
    {
      id: 'utilizada',
      header: {
        text: 'Utilizada na análise',
        cell: EvidenceHeaderCell,
        css: 'skpe-evidence-header-main',
      },
      width: 210,
      sort: true,
      resize: true,
    },
  ]

  function toggleFilter(filter: CardFilter) {
    setActiveFilter((current) => (current === filter ? null : filter))
  }

  return (
    <section className="skpe-evidence-section">
      <header className="skpe-evidence-section__intro">
        <span className="skpe-evidence-section__eyebrow">
          Evidências da organização
        </span>
        <h2>Base transversal para diagnóstico e decisões</h2>
        <p>
          A evidência pertence à organização. Estar disponível não significa
          estar utilizada; suficiência e confiança são avaliadas no contexto de
          um uso explícito.
        </p>
      </header>

      <div className="skpe-evidence-metrics">
        <MetricCard
          label="Evidências previstas"
          value={expectedLoading ? '…' : expectedGridData.length}
          helper={
            expectedError
              ? 'Checklist indisponível no momento'
              : 'requisitos previstos pelo checklist PEM-00 2026.2'
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
              Limpar filtro dos Cards
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
            <div className="skpe-evidence-smart-grid" data-sparks-grid-shell>
              <Grid
                data={displayedGridData}
                columns={columns}
                header
                autoRowHeight
              />
              <SparksGridNavigator />
</div>

            <p className="skpe-evidence-grid-card__footer">
              {displayedGridData.length} de{' '}
              {activeFilter === 'expected'
                ? expectedGridData.length
                : filteredAssets.length}{' '}
              registros exibidos.
            </p>
          </>
        )}
      </section>
    </section>
  )
}
