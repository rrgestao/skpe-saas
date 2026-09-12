import { useMemo, useState } from 'react'

import {
  SparksSmartGrid,
  type SparksSmartGridColumn,
  type SparksSmartGridContextAction,
} from '../../components/design-system/SparksSmartGrid'
import { supabase } from '../../lib/supabase'

export type OrganizationIndicatorGridItem = {
  indicator_id: string
  code: string | null
  name: string | null
  description: string | null
  unit: string | null
  polarity: string | null
  measurement_frequency: string | null
  baseline_value?: number | null
  baseline_date?: string | null
  indicator_status: string | null
  target_id: string | null
  target_value: number | null
  minimum_value: number | null
  challenge_value: number | null
  measured_value: number | null
  effective_performance: number | null
  measurement_state: string | null
  benchmark_id: string | null
  benchmark_type?: string | null
  benchmark_value: number | null
  benchmark_reference_organization?: string | null
  benchmark_source_name: string | null
  benchmark_source_reference?: string | null
  benchmark_reference_period?: string | null
  benchmark_status?: string | null
  evidence_reference?: string | null
  owner_user_id?: string | null
  owner_name?: string | null
  key_result_id?: string | null
  key_result_code?: string | null
  key_result_name?: string | null
  updated_at: string | null
}

type IndicatorHistoryRow = {
  measurement_id: string
  measurement_date: string | null
  period_start: string | null
  period_end: string | null
  measured_value: number | null
  effective_performance: number | null
  measurement_status: string | null
  data_quality: string | null
  source_name: string | null
  source_reference: string | null
  evidence_reference: string | null
  notes: string | null
  valid_observation_count: number
  trend_eligible: boolean
}

type PanelMode = 'benchmark' | 'history'
type MonitoringParameters = {
  critical_threshold: number
  attention_threshold: number
  on_track_threshold: number
  parameter_source: string
}
type Props = {
  rows: OrganizationIndicatorGridItem[]
  organizationId: string
  sourceModuleCode: string
  monitoringParameters: MonitoringParameters | null
  onReload: () => Promise<void>
}

type GridRow = {
  [key: string]: string
  id: string
  code: string
  name: string
  responsible: string
  keyResult: string
  unit: string
  frequency: string
  status: string
  target: string
  baseline: string
  measurement: string
  evidence: string
  performance: string
  farol: string
  benchmark: string
  benchmarkSource: string
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

function baselineLabel(row: OrganizationIndicatorGridItem) {
  if (row.baseline_value == null) return 'Não informado'

  const value = String(row.baseline_value)
  if (!row.baseline_date) return value

  const date = new Date(`${row.baseline_date}T00:00:00`)
  const formattedDate = Number.isNaN(date.getTime())
    ? row.baseline_date
    : new Intl.DateTimeFormat('pt-BR').format(date)

  return `${value} · ${formattedDate}`
}
function measurementLabel(row: OrganizationIndicatorGridItem) {
  if (!row.measurement_state || row.measurement_state === 'not_assessed') {
    return 'Ainda não apurado'
  }
  return row.measured_value == null ? 'Ainda não apurado' : String(row.measured_value)
}

function formatHistoryDate(value: string | null) {
  if (!value) return 'Data não informada'
  const date = new Date(`${value}T00:00:00`)
  return Number.isNaN(date.getTime())
    ? value
    : new Intl.DateTimeFormat('pt-BR').format(date)
}

function trendLabel(
  rows: IndicatorHistoryRow[],
  polarity: string | null | undefined,
  targetValue: number | null | undefined,
  minimumValue: number | null | undefined,
  challengeValue: number | null | undefined,
) {
  const valid = rows
    .filter((row) => row.measured_value != null)
    .sort((a, b) =>
      String(a.measurement_date ?? '').localeCompare(String(b.measurement_date ?? '')),
    )

  if (valid.length === 0) return 'Não apurado'
  if (valid.length === 1) return 'Sem tendência'
  if (valid.length === 2) return 'Histórico insuficiente'

  const first = valid[0]?.measured_value
  const last = valid[valid.length - 1]?.measured_value

  if (first == null || last == null) return 'Histórico insuficiente'
  if (last === first) return 'Tendência estável'

  const normalizedPolarity = String(polarity ?? '').trim().toLowerCase()

  if (normalizedPolarity === 'higher_is_better') {
    return last > first
      ? 'Tendência favorável · valor em alta'
      : 'Tendência desfavorável · valor em baixa'
  }

  if (normalizedPolarity === 'lower_is_better') {
    return last < first
      ? 'Tendência favorável · valor em baixa'
      : 'Tendência desfavorável · valor em alta'
  }

  if (normalizedPolarity === 'target_is_better' && targetValue != null) {
    const firstDistance = Math.abs(first - targetValue)
    const lastDistance = Math.abs(last - targetValue)

    if (lastDistance < firstDistance) return 'Tendência favorável · aproximando-se da meta'
    if (lastDistance > firstDistance) return 'Tendência desfavorável · afastando-se da meta'
    return 'Tendência estável em relação à meta'
  }

  if (
    normalizedPolarity === 'range_is_better' &&
    minimumValue != null &&
    challengeValue != null
  ) {
    const lower = Math.min(minimumValue, challengeValue)
    const upper = Math.max(minimumValue, challengeValue)

    const distanceToRange = (value: number) => {
      if (value < lower) return lower - value
      if (value > upper) return value - upper
      return 0
    }

    const firstDistance = distanceToRange(first)
    const lastDistance = distanceToRange(last)

    if (lastDistance < firstDistance) return 'Tendência favorável · aproximando-se da faixa'
    if (lastDistance > firstDistance) return 'Tendência desfavorável · afastando-se da faixa'
    return 'Tendência estável em relação à faixa'
  }

  return last > first ? 'Valor em alta' : 'Valor em baixa'
}
function farolLabel(
  performance: number | null,
  parameters: MonitoringParameters | null,
) {
  if (performance == null) return 'Não avaliado'
  if (!parameters) return 'Parâmetros indisponíveis'

  if (performance < parameters.critical_threshold) return 'Crítico'
  if (performance < parameters.attention_threshold) return 'Atenção'
  if (performance >= parameters.on_track_threshold) return 'Atingido'
  return 'No caminho'
}
function performanceLabel(value: number | null) {
  return value == null ? 'Não avaliado' : `${value.toFixed(1)}%`
}

function keyResultLabel(row: OrganizationIndicatorGridItem) {
  if (!row.key_result_id) return 'Não vinculado'

  const code = row.key_result_code?.trim()
  const name = row.key_result_name?.trim()

  if (code && name) return `${code} · ${name}`
  if (name) return name
  if (code) return code
  return 'KR vinculado'
}

function evidenceLabel(value: string | null | undefined) {
  const normalized = value?.trim()
  return normalized || 'Sem evidência registrada'
}

export function OrganizationIndicatorsSmartGrid({
  rows,
  organizationId,
  sourceModuleCode,
  monitoringParameters,
  onReload,
}: Props) {
  const [selectedIndicatorId, setSelectedIndicatorId] = useState<string | null>(null)
  const [panelOpen, setPanelOpen] = useState(false)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState('')
  const [panelMode, setPanelMode] = useState<PanelMode>('benchmark')
  const [historyRows, setHistoryRows] = useState<IndicatorHistoryRow[]>([])
  const [historyLoading, setHistoryLoading] = useState(false)
  const [historyError, setHistoryError] = useState('')

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
    [rows, monitoringParameters],
  )

  const gridRows = useMemo<GridRow[]>(
    () =>
      rows.map((row) => ({
        id: row.indicator_id,
        code: display(row.code),
        name: display(row.name),
        responsible: row.owner_name?.trim() || 'Não definido',
        keyResult: keyResultLabel(row),
        unit: display(row.unit, 'Não informada'),
        frequency: frequencyLabel(row.measurement_frequency),
        status: statusLabel(row.indicator_status),
        target: row.target_id ? display(row.target_value) : 'Não informada',
        baseline: baselineLabel(row),
        measurement: measurementLabel(row),
        evidence: evidenceLabel(row.evidence_reference),
        performance: performanceLabel(row.effective_performance),
        farol: farolLabel(row.effective_performance, monitoringParameters),
        benchmark: row.benchmark_id ? display(row.benchmark_value) : 'Não informado',
        benchmarkSource: row.benchmark_source_name ?? 'Não informada',
      })),
    [rows, monitoringParameters],
  )

  const columns = useMemo<SparksSmartGridColumn[]>(
    () => [
      { id: 'code', label: 'Código', minWidth: 105 },
      { id: 'name', label: 'Indicador', minWidth: 240 },
      { id: 'responsible', label: 'Responsável', minWidth: 180 },
      { id: 'keyResult', label: 'KR vinculado', minWidth: 210 },
      { id: 'unit', label: 'Unidade', minWidth: 120, align: 'center' },
      {
        id: 'frequency',
        label: 'Periodicidade',
        minWidth: 135,
        align: 'center',
      },
      { id: 'status', label: 'Situação', minWidth: 115, align: 'center' },
      {
        id: 'baseline',
        label: 'Baseline',
        minWidth: 145,
        align: 'center',
      },
      { id: 'target', label: 'Meta', minWidth: 120, align: 'center' },
      {
        id: 'measurement',
        label: 'Apuração',
        minWidth: 135,
        align: 'center',
      },
      {
        id: 'evidence',
        label: 'Evidência',
        minWidth: 220,
      },
      {
        id: 'performance',
        label: 'Desempenho',
        minWidth: 130,
        align: 'center',
      },      {
        id: 'farol',
        label: 'Farol',
        minWidth: 120,
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
    ],
    [],
  )

  const openPanel = (indicatorId?: string | null) => {
    const id = indicatorId ?? selectedIndicatorId
    if (!id) return
    const row = byId.get(id)
    if (!row) return

    setSelectedIndicatorId(id)
    setPanelMode('benchmark')
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

  const loadHistory = async (indicatorId: string) => {
    setHistoryLoading(true)
    setHistoryError('')
    setHistoryRows([])

    const { data, error } = await supabase.rpc(
      'get_sparks_measure_indicator_history' as never,
      {
        target_organization_id: organizationId,
        target_source_module_code: sourceModuleCode,
        target_indicator_id: indicatorId,
        target_limit: 100,
      } as never,
    )

    if (error) {
      setHistoryError(error.message)
      setHistoryLoading(false)
      return
    }

    setHistoryRows((Array.isArray(data) ? data : []) as IndicatorHistoryRow[])
    setHistoryLoading(false)
  }

  const openHistoryPanel = (indicatorId?: string | null) => {
    const id = indicatorId ?? selectedIndicatorId
    if (!id) return

    setSelectedIndicatorId(id)
    setPanelMode('history')
    setMessage('')
    setPanelOpen(true)
    void loadHistory(id)
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
    { id: 'history', text: 'Histórico e tendência', icon: 'wxi-clock' },
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
        onDoubleClick={(id) => openHistoryPanel(id)}
        contextMenu={menu}
        onContextAction={(action, id) => {
          setSelectedIndicatorId(id)
          const row = byId.get(id)
          if (!row) return

          if (action === 'history') openHistoryPanel(id)
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

      {panelOpen && selectedIndicatorId ? (
        <aside
          className="sparks-measures-side-panel"
          aria-label={
            panelMode === 'history'
              ? 'Histórico e tendência da medida'
              : 'Manutenção de benchmark'
          }
        >
          <div className="sparks-measures-side-panel__header">
            <div>
              <span>
                {panelMode === 'history'
                  ? 'Histórico e tendência'
                  : 'Benchmark da medida'}
              </span>
              <strong>
                {display(byId.get(selectedIndicatorId)?.code)} ·{' '}
                {display(byId.get(selectedIndicatorId)?.name)}
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

          {panelMode === 'history' ? (
            <div className="sparks-measures-side-panel__grid">
              <div className="is-wide">
                <span>Tendência</span>
                <strong>{trendLabel(
                  historyRows,
                  byId.get(selectedIndicatorId)?.polarity,
                  byId.get(selectedIndicatorId)?.target_value,
                  byId.get(selectedIndicatorId)?.minimum_value,
                  byId.get(selectedIndicatorId)?.challenge_value,
                )}</strong>
                <small>
                  A tendência considera a polaridade do indicador. Meta ou faixa
                  são usadas quando o tipo de polaridade exigir esse contexto.
                </small>
              </div>

              {historyLoading ? (
                <div className="is-wide">Carregando histórico...</div>
              ) : historyError ? (
                <div className="is-wide sparks-measures-side-panel__message">
                  {historyError}
                </div>
              ) : historyRows.length === 0 ? (
                <div className="is-wide">
                  Nenhuma apuração registrada. Ausência de medição não representa zero.
                </div>
              ) : (
                <div className="is-wide">
                  {historyRows.map((history) => (
                    <div key={history.measurement_id}>
                      <strong>
                        {formatHistoryDate(history.measurement_date)} ·{' '}
                        {history.measured_value == null
                          ? 'Não informado'
                          : history.measured_value}
                      </strong>
                      <div>
                        {history.effective_performance == null
                          ? 'Desempenho não avaliado'
                          : `Desempenho ${history.effective_performance.toFixed(1)}%`}
                        {' · '}
                        {history.data_quality ?? 'Qualidade não informada'}
                      </div>
                      <small>
                        {history.source_name
                          ? `Fonte: ${history.source_name}`
                          : 'Fonte não informada'}
                        {history.evidence_reference
                          ? ` · Evidência: ${history.evidence_reference}`
                          : ''}
                      </small>
                    </div>
                  ))}
                </div>
              )}
            </div>
          ) : (
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
          )}
        </aside>
      ) : null}
      {panelOpen ? (
        <button
          type="button"
          className="sparks-measures-side-panel__backdrop"
          aria-label="Fechar manutenção"
          onClick={() => setPanelOpen(false)}
        />
      ) : null}

      {!panelOpen && message ? (
        <div className="sparks-measures-side-panel__message">{message}</div>
      ) : null}
    </>
  )
}
