import { useEffect, useMemo, useState } from 'react'

import {
  SparksSmartGrid,
  type SparksSmartGridColumn,
  type SparksSmartGridContextAction,
} from '../../components/design-system/SparksSmartGrid'
import '../skpe/components/OrganizationUsersSmartGrid.css'
import { supabase } from '../../lib/supabase'
import { statusLabelPtBr } from '../../shared/i18n/ptBR'

import './PlatformMeasureCatalog.css'

type Benchmark = {
  id: string
  benchmarkType: string
  sourceName: string
  sourceReference: string | null
  referencePeriod: string | null
  benchmarkValue: number | null
  lowerBound: number | null
  upperBound: number | null
  status: string
}
type Applicability = {
  fit?: {
    organizationTypes?: string[]
    areas?: string[]
    strategicObjectivePatterns?: string[]
  }
  recommendedWhen?: string[]
  useWithCautionWhen?: string[]
  dataRequirements?: string[]
  implementation?: {
    steps?: string[]
    targetSetting?: string
  }
}

type ReferenceSource = {
  source?: string
  publisher?: string
  reference?: string
  url?: string
  sourceType?: string
  support?: string
  notes?: string
}

type ReferenceRow = {
  reference_catalog_id: string
  catalog_code: string
  version_number: number
  name: string
  description: string | null
  purpose: string | null
  formula_text: string | null
  unit: string | null
  polarity: string
  measurement_frequency: string | null
  indicator_category: string | null
  applicability: Applicability | null
  excellence_criteria: unknown[]
  reference_sources: ReferenceSource[]
  status: string
  is_current: boolean
  benchmarks: Benchmark[]
}

const statusLabel = (value: string) =>
  statusLabelPtBr(value, value)

const frequencyLabels: Record<string, string> = {
  daily: 'Diária',
  weekly: 'Semanal',
  monthly: 'Mensal',
  bimonthly: 'Bimestral',
  quarterly: 'Trimestral',
  semiannual: 'Semestral',
  annual: 'Anual',
  on_demand: 'Sob demanda',
}

const categoryLabels: Record<string, string> = {
  financial: 'Financeiro',
  customer_market: 'Mercado e clientes',
  internal_process: 'Processos internos',
  people_learning: 'Pessoas e aprendizado',
  governance: 'Governança',
  social: 'Social',
  environmental: 'Ambiental',
  sustainability: 'Sustentabilidade',
  other: 'Outro',
}

const polarityLabels: Record<string, string> = {
  higher_is_better: 'Maior é melhor',
  lower_is_better: 'Menor é melhor',
  target_is_better: 'Alvo é melhor',
  range_is_better: 'Faixa é melhor',
}

const organizationTypeLabels: Record<string, string> = {
  cooperative: 'Cooperativa',
  company: 'Empresa',
  association: 'Associação',
  institute: 'Instituto',
  foundation: 'Fundação',
  public_body: 'Órgão público',
  other: 'Outro',
}

function labelFrom(
  value: string | null | undefined,
  labels: Record<string, string>,
  fallback: string,
) {
  if (!value) return fallback
  return labels[value] ?? value
}

function frequencyLabel(value: string | null | undefined) {
  return labelFrom(value, frequencyLabels, 'Não informada')
}

function categoryLabel(value: string | null | undefined) {
  return labelFrom(value, categoryLabels, 'Não informada')
}

function polarityLabel(value: string | null | undefined) {
  return labelFrom(value, polarityLabels, 'Não informada')
}


type PlatformReferenceGridRow = {
  id: string
  code: string
  name: string
  category: string
  unit: string
  frequency: string
  polarity: string
  status: string
  current: string
  benchmarks: number
  version: string
}

export function PlatformMeasureCatalog() {
  const [rows, setRows] = useState<ReferenceRow[]>([])
  const [includeHistory, setIncludeHistory] = useState(false)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')
  const [catalogCode, setCatalogCode] = useState('')
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [purpose, setPurpose] = useState('')
  const [formula, setFormula] = useState('')
  const [unit, setUnit] = useState('')
  const [polarity, setPolarity] = useState('higher_is_better')
  const [frequency, setFrequency] = useState('')
  const [category, setCategory] = useState('')
  const [status, setStatus] = useState('draft')
  const [makeCurrent, setMakeCurrent] = useState(true)
  const [changeReason, setChangeReason] = useState('')
  const [benchmarkReferenceId, setBenchmarkReferenceId] = useState('')
  const [benchmarkEditId, setBenchmarkEditId] = useState<string | null>(null)
  const [benchmarkType, setBenchmarkType] = useState('sector')
  const [benchmarkSource, setBenchmarkSource] = useState('')
  const [benchmarkPeriod, setBenchmarkPeriod] = useState('')
  const [benchmarkValue, setBenchmarkValue] = useState('')
  const [benchmarkReason, setBenchmarkReason] = useState('')
  const [selectedReferenceId, setSelectedReferenceId] = useState<string | null>(null)
  const [maintenanceMode, setMaintenanceMode] = useState<
    'reference' | 'benchmark' | null
  >(null)

  const visibleRows = useMemo(
    () => (includeHistory ? rows : rows.filter((row) => row.is_current)),
    [includeHistory, rows],
  )

  const currentReferenceCount = useMemo(
    () => rows.filter((row) => row.is_current).length,
    [rows],
  )

  const historicalReferenceCount = rows.length - currentReferenceCount

  const referenceById = useMemo(
    () => new Map(rows.map((row) => [row.reference_catalog_id, row])),
    [rows],
  )

  const selectedReference = useMemo(
    () =>
      selectedReferenceId
        ? referenceById.get(selectedReferenceId) ?? null
        : null,
    [referenceById, selectedReferenceId],
  )

  const gridRows = useMemo<PlatformReferenceGridRow[]>(
    () =>
      visibleRows.map((row) => ({
        id: row.reference_catalog_id,
        code: row.catalog_code,
        name: row.name,
        category: categoryLabel(row.indicator_category),
        unit: row.unit || 'Não informada',
        frequency: frequencyLabel(row.measurement_frequency),
        polarity: polarityLabel(row.polarity),
        status: statusLabel(row.status),
        current: row.is_current ? 'Vigente' : 'Histórica',
        benchmarks: row.benchmarks?.length ?? 0,
        version: `v${row.version_number}`,
      })),
    [visibleRows],
  )

  const gridColumns = useMemo<SparksSmartGridColumn[]>(
    () => {
      const columns: SparksSmartGridColumn[] = [
        { id: 'code', label: 'Código', minWidth: 105 },
        { id: 'name', label: 'Referência', minWidth: 240, tooltip: true },
        { id: 'category', label: 'Categoria', minWidth: 140, align: 'center' },
        { id: 'unit', label: 'Unidade', minWidth: 110, align: 'center' },
        {
          id: 'frequency',
          label: 'Periodicidade',
          minWidth: 135,
          align: 'center',
        },
        {
          id: 'polarity',
          label: 'Polaridade',
          minWidth: 140,
          align: 'center',
        },
        { id: 'status', label: 'Situação', minWidth: 115, align: 'center' },
        {
          id: 'benchmarks',
          label: 'Benchmarks',
          minWidth: 115,
          align: 'center',
        },
      ]

      if (includeHistory) {
        columns.push(
          { id: 'current', label: 'Vigência', minWidth: 110, align: 'center' },
          { id: 'version', label: 'Versão', minWidth: 90, align: 'center' },
        )
      }

      return columns
    },
    [includeHistory],
  )
  const contextMenuOptions: SparksSmartGridContextAction[] = [
    { id: 'view-details', text: 'Ver detalhes', icon: 'wxi-eye' },
    { comp: 'separator' },
    { id: 'new-version', text: 'Preparar nova versão', icon: 'wxi-plus' },
    { id: 'add-benchmark', text: 'Adicionar benchmark', icon: 'wxi-plus' },
    { id: 'view-history', text: 'Ver histórico de versões', icon: 'wxi-clock' },
    { comp: 'separator' },
    { id: 'activate', text: 'Ativar como vigente', icon: 'wxi-check' },
    { id: 'inactivate', text: 'Inativar', icon: 'wxi-close' },
    { id: 'archive', text: 'Arquivar', icon: 'wxi-folder' },
    { comp: 'separator' },
    { id: 'delete-draft', text: 'Excluir rascunho', icon: 'wxi-delete' },
  ]

  const resolveContextReference = (rowId?: string | null) => {
    const gridSelectedId = rowId ?? selectedReferenceId
    if (!gridSelectedId) return null
    return referenceById.get(String(gridSelectedId)) ?? null
  }

  const openReferenceMaintenance = (reference?: ReferenceRow | null) => {
    if (reference) {
      prepareNewVersion(reference)
      setSelectedReferenceId(reference.reference_catalog_id)
    } else {
      setCatalogCode('')
      setName('')
      setDescription('')
      setPurpose('')
      setFormula('')
      setUnit('')
      setPolarity('higher_is_better')
      setFrequency('')
      setCategory('')
      setStatus('draft')
      setMakeCurrent(true)
      setChangeReason('')
    }

    setMaintenanceMode('reference')
    window.setTimeout(() => {
      document
        .getElementById('pmc-maintenance-panel')
        ?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }, 0)
  }

  const openBenchmarkMaintenance = (
    reference: ReferenceRow,
    benchmark?: Benchmark | null,
  ) => {
    setSelectedReferenceId(reference.reference_catalog_id)
    setBenchmarkReferenceId(reference.reference_catalog_id)
    setBenchmarkEditId(benchmark?.id ?? null)
    setBenchmarkType(benchmark?.benchmarkType ?? 'sector')
    setBenchmarkSource(benchmark?.sourceName ?? '')
    setBenchmarkPeriod(benchmark?.referencePeriod ?? '')
    setBenchmarkValue(
      benchmark?.benchmarkValue != null
        ? String(benchmark.benchmarkValue)
        : benchmark?.lowerBound != null
          ? String(benchmark.lowerBound)
          : benchmark?.upperBound != null
            ? String(benchmark.upperBound)
            : '',
    )
    setBenchmarkReason('')
    setMaintenanceMode('benchmark')

    window.setTimeout(() => {
      document
        .getElementById('pmc-maintenance-panel')
        ?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }, 0)
  }

  const handleContextMenuClick = (actionId: string, rowId: string) => {
    const reference = resolveContextReference(rowId)

    if (!reference) {
      setMessage('Selecione uma referência antes de executar esta ação.')
      return
    }

    setSelectedReferenceId(reference.reference_catalog_id)

    if (actionId === 'view-details') {
      window.setTimeout(() => {
        document
          .getElementById('pmc-reference-detail')
          ?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
      }, 0)
      return
    }

    if (actionId === 'new-version') {
      openReferenceMaintenance(reference)
      return
    }

    if (actionId === 'add-benchmark') {
      openBenchmarkMaintenance(reference)
      return
    }

    if (actionId === 'view-history') {
      if (!includeHistory) setIncludeHistory(true)
      window.setTimeout(() => {
        document
          .getElementById('pmc-reference-detail')
          ?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
      }, 0)
      return
    }

    if (actionId === 'activate') {
      if (reference.status === 'active' && reference.is_current) {
        setMessage('Esta referência já está ativa e vigente.')
        return
      }
      void transition(reference, 'active', true)
      return
    }

    if (actionId === 'inactivate') {
      if (reference.status !== 'active') {
        setMessage('A referência selecionada não está ativa.')
        return
      }
      void transition(reference, 'inactive', false)
      return
    }

    if (actionId === 'archive') {
      void transition(reference, 'archived', false)
      return
    }

    if (actionId === 'delete-draft') {
      if (reference.status !== 'draft') {
        setMessage(
          'Somente referências em rascunho podem ser excluídas. Para referências legítimas do histórico, utilize Arquivar.',
        )
        return
      }

      const reason = window.prompt(
        `Informe o motivo da exclusão do rascunho ${reference.catalog_code} v${reference.version_number}:`,
      )

      if (!reason?.trim()) return

      void deleteReferenceDraft(reference, reason.trim())
    }
  }

  async function updateBenchmarkStatus(
    reference: ReferenceRow,
    benchmark: Benchmark,
    targetStatus: 'inactive' | 'archived',
  ) {
    const reason = window.prompt(
      `Informe o motivo para ${targetStatus === 'archived' ? 'arquivar' : 'inativar'} o benchmark de ${benchmark.sourceName}:`,
    )
    if (!reason?.trim()) return

    setSaving(true)
    setMessage('')

    try {
      const { error } = await supabase.rpc(
        'upsert_platform_measure_reference_benchmark' as never,
        {
          target_reference_catalog_id: reference.reference_catalog_id,
          target_benchmark_type: benchmark.benchmarkType,
          target_source_name: benchmark.sourceName,
          target_source_reference: benchmark.sourceReference,
          target_reference_period: benchmark.referencePeriod,
          target_population_context: null,
          target_benchmark_value: benchmark.benchmarkValue,
          target_lower_bound: benchmark.lowerBound,
          target_upper_bound: benchmark.upperBound,
          target_applicability: null,
          target_comparability_notes: null,
          target_confidence_level: null,
          target_status: targetStatus,
          target_benchmark_id: benchmark.id,
          target_metadata: { managedFromPlatformAdministration: true },
          target_change_reason: reason.trim(),
        } as never,
      )
      if (error) throw error
      await load()
      setMessage(
        targetStatus === 'archived'
          ? 'Benchmark arquivado com governança.'
          : 'Benchmark inativado com governança.',
      )
    } catch (error) {
      setMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível atualizar o benchmark.',
      )
    } finally {
      setSaving(false)
    }
  }

  async function deleteBenchmarkDraft(benchmark: Benchmark) {
    if (benchmark.status !== 'draft') {
      setMessage(
        'Somente benchmarks em rascunho podem ser excluídos. Utilize Inativar ou Arquivar para registros legítimos do histórico.',
      )
      return
    }

    const reason = window.prompt(
      `Informe o motivo da exclusão do benchmark em rascunho de ${benchmark.sourceName}:`,
    )
    if (!reason?.trim()) return

    setSaving(true)
    setMessage('')

    try {
      const { error } = await supabase.rpc(
        'delete_platform_measure_reference_benchmark_draft',
        {
          target_benchmark_id: benchmark.id,
          target_change_reason: reason.trim(),
        } as never,
      )
      if (error) throw error
      await load()
      setMessage('Benchmark em rascunho excluído com governança.')
    } catch (error) {
      setMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível excluir o benchmark.',
      )
    } finally {
      setSaving(false)
    }
  }
  async function deleteReferenceDraft(
    reference: ReferenceRow,
    reason: string,
  ) {
    setSaving(true)
    setMessage('')

    try {
      const { error } = await supabase.rpc(
        'delete_platform_measure_reference_catalog_draft',
        {
          target_reference_catalog_id: reference.reference_catalog_id,
          target_change_reason: reason,
        },
      )

      if (error) throw error

      setSelectedReferenceId(null)
      setMaintenanceMode(null)
      setRows((currentRows) => {
        const remaining = currentRows.filter(
          (row) =>
            row.reference_catalog_id !== reference.reference_catalog_id,
        )

        if (!reference.is_current) return remaining

        const previous = [...remaining]
          .filter(
            (row) =>
              row.catalog_code === reference.catalog_code &&
              row.status !== 'archived',
          )
          .sort((a, b) => b.version_number - a.version_number)[0]

        if (!previous) return remaining

        return remaining.map((row) =>
          row.reference_catalog_id === previous.reference_catalog_id
            ? { ...row, is_current: true }
            : row,
        )
      })
      setMessage(
        `Rascunho ${reference.catalog_code} v${reference.version_number} excluído com governança.`,
      )
    } catch (error) {
      setMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível excluir o rascunho.',
      )
    } finally {
      setSaving(false)
    }
  }

  const prepareNewVersion = (reference: ReferenceRow) => {
    setCatalogCode(reference.catalog_code)
    setName(reference.name)
    setDescription(reference.description ?? '')
    setPurpose(reference.purpose ?? '')
    setFormula(reference.formula_text ?? '')
    setUnit(reference.unit ?? '')
    setPolarity(reference.polarity || 'higher_is_better')
    setFrequency(reference.measurement_frequency ?? '')
    setCategory(reference.indicator_category ?? '')
    setStatus('draft')
    setMakeCurrent(true)
    setChangeReason('')
    setMessage(
      `Preparando nova versão governada de ${reference.catalog_code}. Revise os campos e informe a justificativa para auditoria.`,
    )
  }

  const load = async () => {
    setLoading(true)
    const response = await supabase.rpc(
      'get_platform_measure_reference_catalog' as never,
      {
        target_include_inactive: true,
        target_include_archived: false,
      } as never,
    )
    if (response.error) {
      setRows([])
      setMessage(response.error.message)
      setLoading(false)
      return
    }
    setRows((response.data ?? []) as ReferenceRow[])
    setLoading(false)
  }

  useEffect(() => {
    void load()
  }, [])

  const saveReference = async (event: React.FormEvent) => {
    event.preventDefault()
    if (!catalogCode.trim() || !name.trim() || !changeReason.trim()) {
      setMessage('Código, nome e justificativa para auditoria são obrigatórios.')
      return
    }
    setSaving(true)
    const response = await supabase.rpc(
      'upsert_platform_measure_reference_catalog' as never,
      {
        target_catalog_code: catalogCode.trim(),
        target_name: name.trim(),
        target_description: description.trim() || null,
        target_purpose: purpose.trim() || null,
        target_formula_text: formula.trim() || null,
        target_unit: unit.trim() || null,
        target_polarity: polarity,
        target_measurement_frequency: frequency || null,
        target_indicator_category: category || null,
        target_applicability: {},
        target_excellence_criteria: [],
        target_reference_sources: [],
        target_status: status,
        target_make_current: makeCurrent,
        target_metadata: { managedFromPlatformAdministration: true },
        target_change_reason: changeReason.trim(),
      } as never,
    )
    if (response.error) {
      setMessage(response.error.message)
      setSaving(false)
      return
    }
    setCatalogCode('')
    setName('')
    setDescription('')
    setPurpose('')
    setFormula('')
    setUnit('')
    setFrequency('')
    setCategory('')
    setStatus('draft')
    setMakeCurrent(true)
    setChangeReason('')
    setMessage('Nova versão governada criada com sucesso.')
    await load()
    setSaving(false)
  }

  const transition = async (
    reference: ReferenceRow,
    nextStatus: string,
    current: boolean,
  ) => {
    const reason = window.prompt(
      `Justificativa para alterar ${reference.catalog_code} v${reference.version_number}:`,
      'Governança do Catálogo GERAL de Medidas e Desempenho.',
    )
    if (!reason?.trim()) return
    const response = await supabase.rpc(
      'transition_platform_measure_reference_catalog' as never,
      {
        target_reference_catalog_id: reference.reference_catalog_id,
        target_status: nextStatus,
        target_make_current: current,
        target_change_reason: reason.trim(),
      } as never,
    )
    if (response.error) {
      setMessage(response.error.message)
      return
    }
    setMessage('Situação atualizada com sucesso.')
    await load()
  }

  const saveBenchmark = async (event: React.FormEvent) => {
    event.preventDefault()
    if (!benchmarkReferenceId || !benchmarkSource.trim() || !benchmarkReason.trim()) {
      setMessage('Referência, fonte e justificativa do benchmark são obrigatórias.')
      return
    }
    const parsed = benchmarkValue.trim()
      ? Number(benchmarkValue.replace(',', '.'))
      : null
    setSaving(true)
    const response = await supabase.rpc(
      'upsert_platform_measure_reference_benchmark' as never,
      {
        target_reference_catalog_id: benchmarkReferenceId,
        target_benchmark_type: benchmarkType,
        target_source_name: benchmarkSource.trim(),
        target_source_reference: null,
        target_reference_period: benchmarkPeriod.trim() || null,
        target_population_context: null,
        target_benchmark_value: Number.isFinite(parsed) ? parsed : null,
        target_lower_bound: null,
        target_upper_bound: null,
        target_applicability: null,
        target_comparability_notes: null,
        target_confidence_level: null,
        target_status: 'draft',
        target_benchmark_id: benchmarkEditId,
        target_metadata: { managedFromPlatformAdministration: true },
        target_change_reason: benchmarkReason.trim(),
      } as never,
    )
    if (response.error) {
      setMessage(response.error.message)
      setSaving(false)
      return
    }
    setBenchmarkReferenceId('')
    setBenchmarkEditId(null)
    setBenchmarkSource('')
    setBenchmarkPeriod('')
    setBenchmarkValue('')
    setBenchmarkReason('')
    setMessage('Benchmark cadastrado com sucesso.')
    await load()
    setSaving(false)
  }

  return (
    <section className="pmc-shell">
      <header className="pmc-heading">
        <div>
          <span>Cadastro GERAL</span>
          <h2>Medidas e Desempenho</h2>
          <p>
            Cadastre referências transversais, versões e benchmarks. As organizações
            adotam por vínculo; os módulos apenas consomem o contexto organizacional.
          </p>
        </div>
      </header>

      <div className="pmc-flow">
        <article><b>1</b><div><strong>Cadastro GERAL</strong><small>Referência transversal única</small></div></article>
        <span>→</span>
        <article><b>2</b><div><strong>Administração da Organização</strong><small>Adoção por vínculo e adaptação governada</small></div></article>
        <span>→</span>
        <article><b>3</b><div><strong>Módulos consumidores</strong><small>SPARKs PE e demais módulos</small></div></article>
      </div>

      {message ? <div className="pmc-message">{message}</div> : null}

      <div className="pmc-grid">
        <section className="pmc-panel">
          <div className="pmc-panel-heading">
            <div>
              <h3>Referências gerais</h3>
              <p>
                Por padrão, o Grid apresenta apenas a versão vigente de cada
                medida. O histórico continua preservado para auditoria e
                rastreabilidade.
              </p>
            </div>
            <div className="pmc-reference-heading-actions">
              <span>
                {currentReferenceCount} vigentes
                {historicalReferenceCount > 0
                  ? ` · ${historicalReferenceCount} históricas`
                  : ''}
              </span>
              <button
                type="button"
                className="pa-primary-button pmc-new-reference-button"
                onClick={() => openReferenceMaintenance(null)}
              >
                Nova referência
              </button>
              <label className="pmc-history-toggle">
                <input
                  type="checkbox"
                  checked={includeHistory}
                  onChange={(event) => {
                    setIncludeHistory(event.target.checked)
                    setSelectedReferenceId(null)
                  }}
                />
                <span>Incluir histórico</span>
              </label>
            </div>
          </div>
          {loading ? (
            <div className="pa-empty-state">Carregando Catálogo GERAL...</div>
          ) : rows.length === 0 ? (
            <div className="pa-empty-state">
              Nenhuma referência geral cadastrada. O catálogo permanece vazio
              até a primeira criação governada.
            </div>
          ) : (
            <>
              <SparksSmartGrid
                rows={gridRows}
                columns={gridColumns}
                ariaLabel="Referências gerais de Medidas e Desempenho"
                viewportMode="standard"
                selectedId={selectedReferenceId}
                onSelect={(id) => setSelectedReferenceId(id)}
                onDoubleClick={(id) => {
                  if (!referenceById.has(id)) return
                  setSelectedReferenceId(id)
                  window.setTimeout(() => {
                    document
                      .getElementById('pmc-reference-detail')
                      ?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
                  }, 0)
                }}
                contextMenu={contextMenuOptions}
                onContextAction={handleContextMenuClick}
              />
              <p className="pmc-grid-hint">
                Clique uma vez para selecionar a referência. Dê duplo clique
                para abrir seus detalhes. Use os filtros dos cabeçalhos,
                ordenação e redimensionamento das colunas para consultar o
                Catálogo GERAL.
              </p>

              {selectedReference ? (
                <article
                  id="pmc-reference-detail"
                  className={
                    selectedReference.is_current
                      ? 'pmc-card pmc-reference-detail is-current'
                      : 'pmc-card pmc-reference-detail'
                  }
                >
                  <div className="pmc-card-head">
                    <div>
                      <small>
                        {selectedReference.catalog_code} · v
                        {selectedReference.version_number}
                      </small>
                      <h4>{selectedReference.name}</h4>
                      <p>
                        {selectedReference.description ??
                          selectedReference.purpose ??
                          'Sem descrição complementar.'}
                      </p>
                    </div>
                    <div className="pmc-badges">
                      <span
                        className={`pa-status pa-status-${selectedReference.status}`}
                      >
                        {statusLabel(selectedReference.status)}
                      </span>
                      {selectedReference.is_current ? (
                        <span className="pmc-current">Vigente</span>
                      ) : null}
                    </div>
                  </div>

                  <dl>
                    <div>
                      <dt>Unidade</dt>
                      <dd>{selectedReference.unit || 'Não informada'}</dd>
                    </div>
                    <div>
                      <dt>Periodicidade</dt>
                      <dd>
                        {frequencyLabel(
                          selectedReference.measurement_frequency,
                        )}
                      </dd>
                    </div>
                    <div>
                      <dt>Categoria</dt>
                      <dd>
                        {categoryLabel(selectedReference.indicator_category)}
                      </dd>
                    </div>
                    <div>
                      <dt>Polaridade</dt>
                      <dd>{polarityLabel(selectedReference.polarity)}</dd>
                    </div>
                    <div>
                      <dt>Benchmarks</dt>
                      <dd>{selectedReference.benchmarks?.length ?? 0}</dd>
                    </div>
                  </dl>

                  {rows.filter(
                    (row) =>
                      row.catalog_code === selectedReference.catalog_code,
                  ).length > 1 ? (
                    <section className="pmc-version-history">
                      <div className="pmc-version-history__heading">
                        <strong>Histórico de versões</strong>
                        <span>
                          {
                            rows.filter(
                              (row) =>
                                row.catalog_code ===
                                selectedReference.catalog_code,
                            ).length
                          } versões
                        </span>
                      </div>
                      <div className="pmc-version-history__list">
                        {rows
                          .filter(
                            (row) =>
                              row.catalog_code ===
                              selectedReference.catalog_code,
                          )
                          .sort(
                            (a, b) =>
                              b.version_number - a.version_number,
                          )
                          .map((version) => (
                            <button
                              key={version.reference_catalog_id}
                              type="button"
                              className={
                                version.reference_catalog_id ===
                                selectedReference.reference_catalog_id
                                  ? 'is-selected'
                                  : ''
                              }
                              onClick={() =>
                                setSelectedReferenceId(
                                  version.reference_catalog_id,
                                )
                              }
                            >
                              <span>v{version.version_number}</span>
                              <strong>
                                {version.is_current ? 'Vigente' : 'Histórica'}
                              </strong>
                              <small>{statusLabel(version.status)}</small>
                            </button>
                          ))}
                      </div>
                    </section>
                  ) : null}

                  {selectedReference.purpose ? (
                    <section className="pmc-detail-section">
                      <strong>Propósito</strong>
                      <p>{selectedReference.purpose}</p>
                    </section>
                  ) : null}

                  {selectedReference.formula_text ? (
                    <section className="pmc-detail-section">
                      <strong>Fórmula</strong>
                      <p>{selectedReference.formula_text}</p>
                    </section>
                  ) : null}

                  <details className="pmc-guidance" open>
                    <summary>Aplicabilidade e como estabelecer</summary>
                    <div className="pmc-guidance-body">
                      {selectedReference.applicability?.fit?.areas?.length ? (
                        <section>
                          <strong>Mais apropriada para</strong>
                          <div className="pmc-chips">
                            {selectedReference.applicability.fit.areas.map(
                              (item) => (
                                <span key={item}>{item}</span>
                              ),
                            )}
                          </div>
                        </section>
                      ) : null}

                      {selectedReference.applicability?.fit
                        ?.organizationTypes?.length ? (
                        <section>
                          <strong>Tipos de organização</strong>
                          <div className="pmc-chips">
                            {selectedReference.applicability.fit.organizationTypes.map(
                              (item) => (
                                <span key={item}>
                                  {organizationTypeLabels[item] ?? item}
                                </span>
                              ),
                            )}
                          </div>
                        </section>
                      ) : null}

                      {selectedReference.applicability?.fit
                        ?.strategicObjectivePatterns?.length ? (
                        <section>
                          <strong>Objetivos estratégicos relacionados</strong>
                          <div className="pmc-chips">
                            {selectedReference.applicability.fit.strategicObjectivePatterns.map(
                              (item) => (
                                <span key={item}>{item}</span>
                              ),
                            )}
                          </div>
                        </section>
                      ) : null}

                      {selectedReference.applicability?.recommendedWhen
                        ?.length ? (
                        <section>
                          <strong>Recomendada quando</strong>
                          <ul>
                            {selectedReference.applicability.recommendedWhen.map(
                              (item) => (
                                <li key={item}>{item}</li>
                              ),
                            )}
                          </ul>
                        </section>
                      ) : null}

                      {selectedReference.applicability?.implementation?.steps
                        ?.length ? (
                        <section>
                          <strong>Como estabelecer</strong>
                          <ol>
                            {selectedReference.applicability.implementation.steps.map(
                              (item) => (
                                <li key={item}>{item}</li>
                              ),
                            )}
                          </ol>
                        </section>
                      ) : null}

                      {selectedReference.applicability?.dataRequirements
                        ?.length ? (
                        <section>
                          <strong>Dados necessários</strong>
                          <ul>
                            {selectedReference.applicability.dataRequirements.map(
                              (item) => (
                                <li key={item}>{item}</li>
                              ),
                            )}
                          </ul>
                        </section>
                      ) : null}

                      {selectedReference.applicability?.implementation
                        ?.targetSetting ? (
                        <section>
                          <strong>Como estabelecer a meta</strong>
                          <p>
                            {
                              selectedReference.applicability.implementation
                                .targetSetting
                            }
                          </p>
                        </section>
                      ) : null}

                      {selectedReference.applicability?.useWithCautionWhen
                        ?.length ? (
                        <section className="pmc-guidance-caution">
                          <strong>Usar com cautela quando</strong>
                          <ul>
                            {selectedReference.applicability.useWithCautionWhen.map(
                              (item) => (
                                <li key={item}>{item}</li>
                              ),
                            )}
                          </ul>
                        </section>
                      ) : null}

                      {selectedReference.reference_sources?.length ? (
                        <section className="pmc-sources">
                          <strong>Fontes e referências</strong>
                          {selectedReference.reference_sources.map(
                            (source, index) => (
                              <article
                                key={`${source.source ?? 'fonte'}-${index}`}
                              >
                                <div>
                                  <b>
                                    {source.source ??
                                      source.publisher ??
                                      'Fonte de referência'}
                                  </b>
                                  {source.reference ? (
                                    <span>{source.reference}</span>
                                  ) : null}
                                  {source.support ? (
                                    <small>{source.support}</small>
                                  ) : null}
                                </div>
                                {source.url ? (
                                  <a
                                    href={source.url}
                                    target="_blank"
                                    rel="noreferrer"
                                  >
                                    Consultar fonte
                                  </a>
                                ) : null}
                              </article>
                            ),
                          )}
                        </section>
                      ) : null}
                    </div>
                  </details>

                  {selectedReference.benchmarks?.length ? (
                    <details>
                      <summary>
                        Benchmarks ({selectedReference.benchmarks.length})
                      </summary>
                      {selectedReference.benchmarks.map((benchmark) => (
                        <div className="pmc-benchmark" key={benchmark.id}>
                          <div className="pmc-benchmark__content">
                            <strong>{benchmark.sourceName}</strong>
                            <span>
                              {benchmark.referencePeriod ||
                                'Período não informado'}{' '}
                              ·{' '}
                              {benchmark.benchmarkValue ??
                                benchmark.lowerBound ??
                                benchmark.upperBound ??
                                'Valor não informado'}
                            </span>
                            <small>{statusLabel(benchmark.status)}</small>
                          </div>
                          <div className="pmc-benchmark__actions">
                            <button
                              type="button"
                              className="pa-secondary-button"
                              onClick={() =>
                                openBenchmarkMaintenance(
                                  selectedReference,
                                  benchmark,
                                )
                              }
                            >
                              Editar
                            </button>
                            {benchmark.status === 'draft' ? (
                              <button
                                type="button"
                                className="pa-secondary-button"
                                onClick={() =>
                                  void deleteBenchmarkDraft(benchmark)
                                }
                              >
                                Excluir rascunho
                              </button>
                            ) : null}
                            {benchmark.status === 'active' ? (
                              <button
                                type="button"
                                className="pa-secondary-button"
                                onClick={() =>
                                  void updateBenchmarkStatus(
                                    selectedReference,
                                    benchmark,
                                    'inactive',
                                  )
                                }
                              >
                                Inativar
                              </button>
                            ) : null}
                            {benchmark.status !== 'archived' ? (
                              <button
                                type="button"
                                className="pa-secondary-button"
                                onClick={() =>
                                  void updateBenchmarkStatus(
                                    selectedReference,
                                    benchmark,
                                    'archived',
                                  )
                                }
                              >
                                Arquivar
                              </button>
                            ) : null}
                          </div>
                        </div>
                      ))}                    </details>
                  ) : null}

                  <footer>
                    <button
                      type="button"
                      className="pa-primary-button"
                      onClick={() => openReferenceMaintenance(selectedReference)}
                    >
                      Preparar nova versão
                    </button>
                    <button
                      type="button"
                      className="pa-secondary-button"
                      onClick={() => openBenchmarkMaintenance(selectedReference)}
                    >
                      Adicionar benchmark
                    </button>
                    {selectedReference.status !== 'active' ? (
                      <button
                        type="button"
                        className="pa-primary-button"
                        onClick={() =>
                          void transition(selectedReference, 'active', true)
                        }
                      >
                        Ativar como vigente
                      </button>
                    ) : (
                      <button
                        type="button"
                        className="pa-secondary-button"
                        onClick={() =>
                          void transition(selectedReference, 'inactive', false)
                        }
                      >
                        Inativar
                      </button>
                    )}
                    <button
                      type="button"
                      className="pa-danger-button"
                      onClick={() =>
                        void transition(selectedReference, 'archived', false)
                      }
                    >
                      Arquivar
                    </button>
                  </footer>
                </article>
              ) : (
                <div className="pmc-reference-selection-empty">
                  Selecione uma referência no Grid para consultar
                  aplicabilidade, fórmula, fontes, benchmarks e ações de
                  governança.
                </div>
              )}
            </>
          )}
        </section>

                {maintenanceMode ? (
          <aside
            id="pmc-maintenance-panel"
            className="pmc-side pmc-maintenance-panel"
          >
            <div className="pmc-maintenance-toolbar">
              <div>
                <span>Manutenção contextual</span>
                <strong>
                  {maintenanceMode === 'reference'
                    ? selectedReference
                      ? `${selectedReference.catalog_code} · ${selectedReference.name}`
                      : 'Nova referência geral'
                    : selectedReference
                      ? `${selectedReference.catalog_code} · ${selectedReference.name}`
                      : 'Benchmark'}
                </strong>
              </div>
              <button
                type="button"
                className="pa-secondary-button"
                onClick={() => setMaintenanceMode(null)}
              >
                Fechar
              </button>
            </div>
                      {maintenanceMode === 'reference' ? (
              <form className="pmc-panel pmc-form" onSubmit={saveReference}>
            <div className="pmc-panel-heading"><div><h3>Nova referência ou versão</h3><p>O mesmo código cria nova versão; a anterior não é sobrescrita.</p></div></div>
            <div className="pmc-fields-2"><label>Código *<input value={catalogCode} onChange={(event) => setCatalogCode(event.target.value.toUpperCase())} required /></label><label>Nome *<input value={name} onChange={(event) => setName(event.target.value)} required /></label></div>
            <label>Descrição<textarea rows={2} value={description} onChange={(event) => setDescription(event.target.value)} /></label>
            <label>Propósito<textarea rows={2} value={purpose} onChange={(event) => setPurpose(event.target.value)} /></label>
            <label>Fórmula<textarea rows={2} value={formula} onChange={(event) => setFormula(event.target.value)} /></label>
            <div className="pmc-fields-2"><label>Unidade<input value={unit} onChange={(event) => setUnit(event.target.value)} /></label><label>Polaridade<select value={polarity} onChange={(event) => setPolarity(event.target.value)}><option value="higher_is_better">Maior é melhor</option><option value="lower_is_better">Menor é melhor</option><option value="target_is_better">Alvo é melhor</option><option value="range_is_better">Faixa é melhor</option></select></label><label>Periodicidade<select value={frequency} onChange={(event) => setFrequency(event.target.value)}><option value="">Não informada</option><option value="monthly">Mensal</option><option value="quarterly">Trimestral</option><option value="semiannual">Semestral</option><option value="annual">Anual</option><option value="on_demand">Sob demanda</option></select></label><label>Categoria<select value={category} onChange={(event) => setCategory(event.target.value)}><option value="">Não informada</option><option value="financial">Financeiro</option><option value="customer_market">Mercado e clientes</option><option value="internal_process">Processos internos</option><option value="people_learning">Pessoas e aprendizado</option><option value="governance">Governança</option><option value="social">Social</option><option value="environmental">Ambiental</option><option value="sustainability">Sustentabilidade</option><option value="other">Outro</option></select></label></div>
            <div className="pmc-fields-2"><label>Situação<select value={status} onChange={(event) => setStatus(event.target.value)}><option value="draft">Rascunho</option><option value="active">Ativo</option><option value="inactive">Inativo</option></select></label><label className="pmc-check"><input type="checkbox" checked={makeCurrent} onChange={(event) => setMakeCurrent(event.target.checked)} />Tornar versão vigente</label></div>
            <label>Justificativa para auditoria *<textarea rows={3} value={changeReason} onChange={(event) => setChangeReason(event.target.value)} required /></label>
            <button type="submit" className="pa-primary-button" disabled={saving}>{saving ? 'Salvando...' : 'Criar versão governada'}</button>
              </form>
            ) : null}

            {maintenanceMode === 'benchmark' ? (
              <form className="pmc-panel pmc-form" onSubmit={saveBenchmark}>
            <div className="pmc-panel-heading"><div><h3>{benchmarkEditId ? 'Editar benchmark' : 'Novo benchmark'}</h3><p>Vincule uma referência comparativa ao catálogo geral.</p></div></div>
            <label>Referência geral *<select value={benchmarkReferenceId} onChange={(event) => setBenchmarkReferenceId(event.target.value)} required><option value="">Selecione</option>{rows.filter((row) => row.is_current).map((row) => <option key={row.reference_catalog_id} value={row.reference_catalog_id}>{row.catalog_code} · {row.name}</option>)}</select></label>
            <div className="pmc-fields-2"><label>Tipo<select value={benchmarkType} onChange={(event) => setBenchmarkType(event.target.value)}><option value="internal">Interno</option><option value="sector">Setorial</option><option value="market">Mercado</option><option value="best_practice">Melhor prática</option><option value="regulatory">Regulatório</option></select></label><label>Fonte *<input value={benchmarkSource} onChange={(event) => setBenchmarkSource(event.target.value)} required /></label><label>Período<input value={benchmarkPeriod} onChange={(event) => setBenchmarkPeriod(event.target.value)} /></label><label>Valor<input inputMode="decimal" value={benchmarkValue} onChange={(event) => setBenchmarkValue(event.target.value)} /></label></div>
            <label>Justificativa para auditoria *<textarea rows={3} value={benchmarkReason} onChange={(event) => setBenchmarkReason(event.target.value)} required /></label>
            <button type="submit" className="pa-primary-button" disabled={saving}>{saving ? 'Salvando...' : benchmarkEditId ? 'Salvar alterações' : 'Cadastrar benchmark'}</button>
              </form>
            ) : null}
          </aside>
        ) : null}
      </div>
    </section>
  )
}