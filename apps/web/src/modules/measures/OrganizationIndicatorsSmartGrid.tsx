import { useMemo, useState } from 'react'

import {
  SparksSmartGrid,
  type SparksSmartGridColumn,
  type SparksSmartGridContextAction,
} from '../../components/design-system/SparksSmartGrid'
import { supabase } from '../../lib/supabase'

export type OrganizationIndicatorGridItem = {
  indicator_id: string
  subject_type?: string | null
  subject_id?: string | null
  owner_user_id?: string | null
  code: string | null
  name: string | null
  description: string | null
  unit: string | null
  polarity: string | null
  measurement_frequency: string | null
  data_source?: string | null
  baseline_value?: number | null
  baseline_date?: string | null
  indicator_status: string | null
  target_id: string | null
  target_type?: string | null
  target_value: number | null
  minimum_value: number | null
  challenge_value: number | null
  target_period_start?: string | null
  target_period_end?: string | null
  target_status?: string | null
  measurement_id?: string | null
  measurement_date?: string | null
  measured_value: number | null
  automatic_performance?: number | null
  manual_performance_override?: number | null
  effective_performance: number | null
  measurement_source_name?: string | null
  measurement_source_reference?: string | null
  evidence_reference?: string | null
  measurement_state: string | null
  benchmark_id: string | null
  benchmark_type?: string | null
  benchmark_value: number | null
  benchmark_reference_organization?: string | null
  benchmark_source_name: string | null
  benchmark_source_reference?: string | null
  benchmark_reference_period?: string | null
  benchmark_status?: string | null
  updated_at: string | null
}

type Props = {
  rows: OrganizationIndicatorGridItem[]
  onReload: () => Promise<void>
  readOnly?: boolean
}

type GridRow = {
  [key: string]: string
  id: string
  code: string
  name: string
  unit: string
  frequency: string
  dataSource: string
  baseline: string
  responsibility: string
  strategicBinding: string
  status: string
  target: string
  targetPeriod: string
  measurement: string
  measurementDate: string
  measurementSource: string
  evidence: string
  interpretation: string
  performance: string
  benchmark: string
  benchmarkSource: string
  benchmarkContext: string
}

function display(value: string | number | null | undefined, fallback = 'Não informado') {
  if (value == null || value === '') return fallback
  return String(value)
}

function frequencyLabel(value: string | null) {
  const labels: Record<string, string> = {
    daily: 'Diária',
    weekly: 'Semanal',
    monthly: 'Mensal',
    bimonthly: 'Bimestral',
    quarterly: 'Trimestral',
    semiannual: 'Semestral',
    annual: 'Anual',
    on_demand: 'Sob demanda',
  }
  return value ? labels[value] ?? value : 'Não informada'
}

function statusLabel(value: string | null | undefined) {
  const labels: Record<string, string> = {
    draft: 'Rascunho',
    verified: 'Verificado',
    active: 'Ativo',
    inactive: 'Inativo',
    archived: 'Arquivado',
  }
  return value ? labels[value] ?? value : 'Não informada'
}

function measurementLabel(row: OrganizationIndicatorGridItem) {
  if (!row.measurement_state || row.measurement_state === 'not_assessed') {
    return 'Ainda não apurado'
  }
  return row.measured_value == null ? 'Ainda não apurado' : String(row.measured_value)
}

function performanceLabel(value: number | null) {
  return value == null ? 'Não avaliado' : `${value.toFixed(1)}%`
}

function responsibilityLabel(value: string | null | undefined) {
  if (value === undefined) return 'Não disponível nesta leitura'
  return value ? 'Responsável definido' : 'Não definido'
}

function strategicBindingLabel(row: OrganizationIndicatorGridItem) {
  if (row.subject_type === 'key_result') return 'Resultado-Chave vinculado'
  if (row.subject_type === 'strategic_objective') return 'Objetivo Estratégico vinculado'
  return row.subject_id ? 'Vínculo estratégico definido' : 'Sem vínculo estratégico'
}

function interpretationLabel(row: OrganizationIndicatorGridItem) {
  if (row.manual_performance_override != null) return 'Override manual'
  if (row.automatic_performance != null) return 'Automática'
  return 'Não avaliada'
}

function dateLabel(value: string | null | undefined) {
  if (!value) return 'Não informada'
  const parsed = new Date(`${value}T00:00:00`)
  return Number.isNaN(parsed.getTime()) ? value : parsed.toLocaleDateString('pt-BR')
}

function periodLabel(start: string | null | undefined, end: string | null | undefined) {
  if (!start && !end) return 'Não informado'
  if (start && end) return `${dateLabel(start)} a ${dateLabel(end)}`
  return start ? `Desde ${dateLabel(start)}` : `Até ${dateLabel(end)}`
}

export function OrganizationIndicatorsSmartGrid({ rows, onReload, readOnly = false }: Props) {
  const [selectedIndicatorId, setSelectedIndicatorId] = useState<string | null>(null)
  const [panelOpen, setPanelOpen] = useState(false)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')

  const [benchmarkType, setBenchmarkType] = useState('sector')
  const [referenceOrganization, setReferenceOrganization] = useState('')
  const [sourceName, setSourceName] = useState('')
  const [sourceReference, setSourceReference] = useState('')
  const [referencePeriod, setReferencePeriod] = useState('')
  const [benchmarkValue, setBenchmarkValue] = useState('')
  const [applicability, setApplicability] = useState('')
  const [gapAnalysis, setGapAnalysis] = useState('')
  const [notes, setNotes] = useState('')
  const [changeReason, setChangeReason] = useState('')

  const byId = useMemo(
    () => new Map(rows.map((row) => [row.indicator_id, row])),
    [rows],
  )

  const gridRows = useMemo<GridRow[]>(
    () =>
      rows.map((row) => ({
        id: row.indicator_id,
        code: display(row.code),
        name: display(row.name),
        unit: display(row.unit, 'Não informada'),
        frequency: frequencyLabel(row.measurement_frequency),
        dataSource: display(row.data_source, 'Não informada'),
        baseline: row.baseline_value == null
          ? 'Não informada'
          : `${row.baseline_value}${row.baseline_date ? ` · ${dateLabel(row.baseline_date)}` : ''}`,
        responsibility: responsibilityLabel(row.owner_user_id),
        strategicBinding: strategicBindingLabel(row),
        status: statusLabel(row.indicator_status),
        target: row.target_id ? display(row.target_value) : 'Não informada',
        targetPeriod: periodLabel(row.target_period_start, row.target_period_end),
        measurement: measurementLabel(row),
        measurementDate: dateLabel(row.measurement_date),
        measurementSource: display(row.measurement_source_name, 'Não informada'),
        evidence: display(row.evidence_reference, 'Não informada'),
        interpretation: interpretationLabel(row),
        performance: performanceLabel(row.effective_performance),
        benchmark: row.benchmark_id ? display(row.benchmark_value) : 'Não informado',
        benchmarkSource: row.benchmark_source_name ?? 'Não informada',
        benchmarkContext: [row.benchmark_reference_organization, row.benchmark_reference_period]
          .filter(Boolean)
          .join(' · ') || 'Não informado',
      })),
    [rows],
  )

  const columns = useMemo<SparksSmartGridColumn[]>(
    () => [
      { id: 'code', label: 'Código', minWidth: 105 },
      { id: 'name', label: 'Indicador', minWidth: 240 },
      { id: 'unit', label: 'Unidade', minWidth: 120, align: 'center' },
      {
        id: 'frequency',
        label: 'Periodicidade',
        minWidth: 135,
        align: 'center',
      },
      { id: 'dataSource', label: 'Fonte de dados', minWidth: 180 },
      { id: 'baseline', label: 'Linha de base', minWidth: 150 },
      { id: 'responsibility', label: 'Responsabilidade', minWidth: 175 },
      { id: 'strategicBinding', label: 'Vínculo estratégico', minWidth: 205 },
      { id: 'status', label: 'Situação', minWidth: 115, align: 'center' },
      { id: 'target', label: 'Meta', minWidth: 120, align: 'center' },
      { id: 'targetPeriod', label: 'Horizonte da meta', minWidth: 185 },
      {
        id: 'measurement',
        label: 'Apuração',
        minWidth: 135,
        align: 'center',
      },
      { id: 'measurementDate', label: 'Data da apuração', minWidth: 150 },
      { id: 'measurementSource', label: 'Fonte da apuração', minWidth: 180 },
      { id: 'evidence', label: 'Evidência', minWidth: 180 },
      { id: 'interpretation', label: 'Interpretação', minWidth: 150 },
      {
        id: 'performance',
        label: 'Desempenho',
        minWidth: 130,
        align: 'center',
      },
      {
        id: 'benchmark',
        label: 'Benchmark',
        minWidth: 125,
        align: 'center',
      },
      {
        id: 'benchmarkSource',
        label: 'Fonte do benchmark',
        minWidth: 180,
      },
      {
        id: 'benchmarkContext',
        label: 'Contexto do benchmark',
        minWidth: 190,
      },
    ],
    [],
  )

  const openPanel = (indicatorId?: string | null) => {
    const id = indicatorId ?? selectedIndicatorId
    if (!id) return
    const row = byId.get(id)
    if (!row) return

    setSelectedIndicatorId(id)
    setBenchmarkType(row.benchmark_type ?? 'sector')
    setReferenceOrganization(row.benchmark_reference_organization ?? '')
    setSourceName(row.benchmark_source_name ?? '')
    setSourceReference(row.benchmark_source_reference ?? '')
    setReferencePeriod(row.benchmark_reference_period ?? '')
    setBenchmarkValue(row.benchmark_value == null ? '' : String(row.benchmark_value))
    setApplicability('')
    setGapAnalysis('')
    setNotes('')
    setChangeReason('')
    setMessage('')
    setPanelOpen(true)
  }

  const transitionBenchmark = async (
    row: OrganizationIndicatorGridItem,
    action: 'verify' | 'activate' | 'return_to_draft' | 'archive',
  ) => {
    if (!row.benchmark_id) {
      setMessage('A medida selecionada ainda não possui benchmark associado.')
      return
    }

    const reason = window.prompt(`Informe o motivo da transição "${action}" do benchmark:`)
    if (!reason?.trim()) return

    setSaving(true)
    try {
      const { error } = await supabase.rpc(
        'sparks_transition_measure_benchmark' as never,
        {
          p_benchmark_id: row.benchmark_id,
          p_transition_action: action,
          p_decision_notes: null,
          p_change_reason: reason.trim(),
        } as never,
      )
      if (error) throw error
      await onReload()
      setMessage('Benchmark atualizado com governança.')
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Não foi possível atualizar o benchmark.')
    } finally {
      setSaving(false)
    }
  }

  const saveBenchmark = async (event: React.FormEvent) => {
    event.preventDefault()
    if (!selectedIndicatorId || !sourceName.trim() || !changeReason.trim()) {
      setMessage('Indicador, fonte e justificativa são obrigatórios.')
      return
    }

    const row = byId.get(selectedIndicatorId)
    if (!row) return

    const parsedValue = benchmarkValue.trim()
      ? Number(benchmarkValue.replace(',', '.'))
      : null

    setSaving(true)
    try {
      const { error } = await supabase.rpc(
        'sparks_upsert_measure_benchmark' as never,
        {
          p_indicator_id: row.indicator_id,
          p_benchmark_type: benchmarkType,
          p_reference_organization: referenceOrganization.trim() || null,
          p_source_name: sourceName.trim(),
          p_source_reference: sourceReference.trim() || null,
          p_reference_period: referencePeriod.trim() || null,
          p_benchmark_value: Number.isFinite(parsedValue) ? parsedValue : null,
          p_applicability: applicability.trim() || null,
          p_gap_analysis: gapAnalysis.trim() || null,
          p_notes: notes.trim() || null,
          p_indicator_target_id: row.target_id,
          p_benchmark_id: row.benchmark_id,
          p_metadata: { managedFromMeasuresPerformanceWorkspace: true },
          p_change_reason: changeReason.trim(),
        } as never,
      )
      if (error) throw error
      await onReload()
      setPanelOpen(false)
      setMessage('Benchmark salvo em rascunho com governança.')
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Não foi possível salvar o benchmark.')
    } finally {
      setSaving(false)
    }
  }

  const menu: SparksSmartGridContextAction[] = [
    { id: 'benchmark', text: 'Associar / editar benchmark', icon: 'wxi-edit' },
    { comp: 'separator' },
    { id: 'verify', text: 'Verificar benchmark', icon: 'wxi-check' },
    { id: 'activate', text: 'Ativar benchmark', icon: 'wxi-check' },
    { id: 'return_to_draft', text: 'Retornar benchmark a rascunho', icon: 'wxi-undo' },
    { id: 'archive', text: 'Arquivar benchmark', icon: 'wxi-folder' },
  ]

  return (
    <>
      <SparksSmartGrid
        rows={gridRows}
        columns={columns}
        ariaLabel="Indicadores da organização"
        viewportMode="balanced"
        selectedId={selectedIndicatorId}
        onSelect={(id) => setSelectedIndicatorId(id)}
        onDoubleClick={readOnly ? undefined : (id) => openPanel(id)}
        contextMenu={readOnly ? undefined : menu}
        onContextAction={readOnly ? undefined : (action, id) => {
          setSelectedIndicatorId(id)
          const row = byId.get(id)
          if (!row) return

          if (action === 'benchmark') openPanel(id)
          if (
            action === 'verify' ||
            action === 'activate' ||
            action === 'return_to_draft' ||
            action === 'archive'
          ) {
            void transitionBenchmark(row, action)
          }
        }}
      />

      {!readOnly && panelOpen && selectedIndicatorId ? (
        <aside className="sparks-measures-side-panel" aria-label="Manutenção de benchmark">
          <div className="sparks-measures-side-panel__header">
            <div>
              <span>Benchmark da medida</span>
              <strong>
                {display(byId.get(selectedIndicatorId)?.code)} · {display(byId.get(selectedIndicatorId)?.name)}
              </strong>
            </div>
            <button
              type="button"
              className="sparks-measures-side-panel__close"
              onClick={() => setPanelOpen(false)}
              aria-label="Fechar manutenção"
            >
              Fechar
            </button>
          </div>

          <form onSubmit={saveBenchmark}>
            <div className="sparks-measures-side-panel__grid">
              <label><span>Tipo</span><select value={benchmarkType} onChange={(e) => setBenchmarkType(e.target.value)}><option value="internal">Interno</option><option value="sector">Setorial</option><option value="market">Mercado</option><option value="best_practice">Melhor prática</option><option value="regulatory">Regulatório</option></select></label>
              <label><span>Organização de referência</span><input value={referenceOrganization} onChange={(e) => setReferenceOrganization(e.target.value)} /></label>
              <label><span>Fonte *</span><input value={sourceName} onChange={(e) => setSourceName(e.target.value)} required /></label>
              <label><span>Referência da fonte</span><input value={sourceReference} onChange={(e) => setSourceReference(e.target.value)} /></label>
              <label><span>Período de referência</span><input value={referencePeriod} onChange={(e) => setReferencePeriod(e.target.value)} /></label>
              <label><span>Valor</span><input inputMode="decimal" value={benchmarkValue} onChange={(e) => setBenchmarkValue(e.target.value)} /></label>
              <label className="is-wide"><span>Aplicabilidade</span><textarea rows={2} value={applicability} onChange={(e) => setApplicability(e.target.value)} /></label>
              <label className="is-wide"><span>Análise de lacuna</span><textarea rows={2} value={gapAnalysis} onChange={(e) => setGapAnalysis(e.target.value)} /></label>
              <label className="is-wide"><span>Notas</span><textarea rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} /></label>
              <label className="is-wide"><span>Justificativa para auditoria *</span><textarea rows={3} value={changeReason} onChange={(e) => setChangeReason(e.target.value)} required /></label>
            </div>

            {message ? <div className="sparks-measures-side-panel__message">{message}</div> : null}

            <button type="submit" disabled={saving}>
              {saving ? 'Salvando...' : 'Salvar benchmark em rascunho'}
            </button>
          </form>
        </aside>
      ) : null}

      {!readOnly && panelOpen ? (
        <button
          type="button"
          className="sparks-measures-side-panel__backdrop"
          aria-label="Fechar manutenção"
          onClick={() => setPanelOpen(false)}
        />
      ) : null}

      {!readOnly && !panelOpen && message ? (
        <div className="sparks-measures-side-panel__message">{message}</div>
      ) : null}
    </>
  )
}
