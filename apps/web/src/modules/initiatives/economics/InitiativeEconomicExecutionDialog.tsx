import { useEffect, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'
import { IconActionButton } from '../../../components/design-system'

type Numeric = number | string | null

type EconomicProjection = {
  initiative: {
    initiativeId: string
    organizationId: string
    code: string
    name: string
    lifecycleStatus: string
    direct: {
      plannedCost: Numeric
      actualCost: Numeric
      currencyCode: string | null
      costVariance: Numeric
      estimatedEffort: Numeric
      actualEffort: Numeric
      effortUnit: string | null
      effortVariance: Numeric
      resourceEstimate: string | null
    }
  }
  actions: {
    counts: {
      total: Numeric
      currentPlan: Numeric
      cancelled: Numeric
      archived: Numeric
    }
    costByCurrency: Array<{
      currencyCode: string
      currentPlannedCost: Numeric
      actualRealizedCost: Numeric
      currentPlanVariance: Numeric
      cancelledPlannedCost: Numeric
      archivedPlannedCost: Numeric
    }>
    effortByUnit: Array<{
      effortUnit: string
      currentEstimatedEffort: Numeric
      actualRealizedEffort: Numeric
      currentPlanVariance: Numeric
      cancelledEstimatedEffort: Numeric
      archivedEstimatedEffort: Numeric
    }>
    dataQuality: {
      actionsWithCostWithoutCurrency: Numeric
      actionsWithEffortWithoutUnit: Numeric
    }
  }
}

type InitiativeExecutionContext = {
  progress: number | null
  startDate: string | null
  targetEndDate: string | null
  baselineStartDate: string | null
  baselineTargetEndDate: string | null
  forecastStartDate: string | null
  forecastEndDate: string | null
  startedAt: string | null
  completedAt: string | null
}

type ActionEconomicRow = {
  id: string
  code: string
  name: string
  status: string
  progress: number | null
  plannedCost: number | null
  actualCost: number | null
  currencyCode: string | null
  estimatedEffort: number | null
  actualEffort: number | null
  effortUnit: string | null
  plannedDueDate: string | null
  forecastDueDate: string | null
}
type Props = {
  organizationId: string
  initiativeId: string
  initiativeCode: string
  initiativeName: string
  canManage: boolean
  presentation?: 'dialog' | 'panel'
  onClose: () => void
  onSaved: () => Promise<void> | void
}

const effortUnitLabels: Record<string, string> = {
  hours: 'Horas',
  days: 'Dias',
  weeks: 'Semanas',
  months: 'Meses',
  points: 'Pontos',
  custom: 'Unidade personalizada',
}

function toNumber(value: Numeric | undefined) {
  if (value === null || value === undefined || value === '') return null
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function toInput(value: Numeric | undefined) {
  const parsed = toNumber(value)
  return parsed === null ? '' : String(parsed)
}

function formatNumber(value: Numeric | undefined) {
  const parsed = toNumber(value)
  if (parsed === null) return '—'
  return new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 2 }).format(parsed)
}

function currencyDisplayLabel(currency: string | null | undefined) {
  const code = currency?.trim().toUpperCase() || 'BRL'
  return code === 'BRL' ? 'R$' : code
}

function formatMoney(value: Numeric | undefined, currency: string | null | undefined) {
  const parsed = toNumber(value)
  if (parsed === null) return '—'
  const code = currency?.trim().toUpperCase() || 'BRL'
  try {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: code,
      maximumFractionDigits: 2,
    }).format(parsed)
  } catch {
    return `${currencyDisplayLabel(code)} ${formatNumber(parsed)}`
  }
}

function formatVariance(value: Numeric | undefined, suffix = '') {
  const parsed = toNumber(value)
  if (parsed === null) return '—'
  if (parsed === 0) return 'Sem variação'
  return `${parsed > 0 ? '+' : ''}${formatNumber(parsed)}${suffix}`
}

function formatDate(value: string | null | undefined) {
  if (!value) return '—'
  const datePart = value.slice(0, 10)
  const [year, month, day] = datePart.split('-')
  return year && month && day ? `${day}/${month}/${year}` : value
}

function percentageOfPlan(actual: Numeric | undefined, planned: Numeric | undefined) {
  const actualValue = toNumber(actual)
  const plannedValue = toNumber(planned)
  if (actualValue === null || plannedValue === null || plannedValue <= 0) return null
  return (actualValue / plannedValue) * 100
}

function formatPercentage(value: number | null) {
  if (value === null) return '—'
  return `${new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 }).format(value)}%`
}

function economicInterpretation(actual: Numeric | undefined, planned: Numeric | undefined, noun: string) {
  const actualValue = toNumber(actual)
  const plannedValue = toNumber(planned)
  if (actualValue === null || plannedValue === null) return `${noun}: comparação indisponível por ausência de valor planejado ou realizado.`
  const delta = actualValue - plannedValue
  if (delta === 0) return `${noun}: realizado igual ao planejado registrado.`
  return `${noun}: realizado ${delta > 0 ? 'acima' : 'abaixo'} do planejado em ${formatNumber(Math.abs(delta))}.`
}
function actionStatusLabel(status: string) {
  const labels: Record<string, string> = {
    planned: 'Planejada',
    in_progress: 'Em execução',
    on_hold: 'Em espera',
    blocked: 'Bloqueada',
    completed: 'Concluída',
    cancelled: 'Cancelada',
    archived: 'Arquivada',
  }
  return labels[status] ?? status
}
function parseOptionalNumber(value: string) {
  const normalized = value.trim().replace(',', '.')
  if (!normalized) return null
  const parsed = Number(normalized)
  return Number.isFinite(parsed) ? parsed : Number.NaN
}

export function InitiativeEconomicExecutionDialog({
  organizationId,
  initiativeId,
  initiativeCode,
  initiativeName,
  canManage,
  presentation = 'dialog',
  onClose,
  onSaved,
}: Props) {
  const [projection, setProjection] = useState<EconomicProjection | null>(null)
  const [executionContext, setExecutionContext] = useState<InitiativeExecutionContext | null>(null)
  const [economicActions, setEconomicActions] = useState<ActionEconomicRow[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<{ type: 'error' | 'success'; text: string } | null>(null)

  const [plannedCost, setPlannedCost] = useState('')
  const [actualCost, setActualCost] = useState('')
  const [currencyCode, setCurrencyCode] = useState('BRL')
  const [estimatedEffort, setEstimatedEffort] = useState('')
  const [actualEffort, setActualEffort] = useState('')
  const [effortUnit, setEffortUnit] = useState('')
  const [resourceEstimate, setResourceEstimate] = useState('')
  const [changeReason, setChangeReason] = useState('')

  const loadProjection = async () => {
    setLoading(true)
    setMessage(null)

    const [projectionResponse, initiativeResponse, actionsResponse] = await Promise.all([
      supabase.rpc(
        'get_sparks_initiative_economic_projection',
        {
          target_organization_id: organizationId,
          target_initiative_id: initiativeId,
        },
      ),
      supabase
        .from('sparks_initiatives')
        .select('progress,start_date,target_end_date,baseline_start_date,baseline_target_end_date,forecast_start_date,forecast_end_date,started_at,completed_at')
        .eq('organization_id', organizationId)
        .eq('id', initiativeId)
        .maybeSingle(),
      supabase
        .from('sparks_initiative_actions')
        .select('id,code,name,status,progress,planned_cost,actual_cost,currency_code,estimated_effort,actual_effort,effort_unit,planned_due_date,forecast_due_date')
        .eq('organization_id', organizationId)
        .eq('initiative_id', initiativeId)
        .is('archived_at', null)
        .order('code'),
    ])

    const error = projectionResponse.error ?? initiativeResponse.error ?? actionsResponse.error

    if (error) {
      setProjection(null)
      setMessage({
        type: 'error',
        text: `Não foi possível carregar o controle econômico: ${translateBackendMessage(error.message)}`,
      })
      setLoading(false)
      return
    }

    const loaded = projectionResponse.data as EconomicProjection
    const initiative = initiativeResponse.data
    const actions = actionsResponse.data ?? []

    setExecutionContext(initiative ? {
      progress: initiative.progress == null ? null : Number(initiative.progress),
      startDate: initiative.start_date,
      targetEndDate: initiative.target_end_date,
      baselineStartDate: initiative.baseline_start_date,
      baselineTargetEndDate: initiative.baseline_target_end_date,
      forecastStartDate: initiative.forecast_start_date,
      forecastEndDate: initiative.forecast_end_date,
      startedAt: initiative.started_at,
      completedAt: initiative.completed_at,
    } : null)
    setEconomicActions(actions.map((action) => ({
      id: action.id,
      code: action.code,
      name: action.name,
      status: action.status,
      progress: action.progress == null ? null : Number(action.progress),
      plannedCost: action.planned_cost == null ? null : Number(action.planned_cost),
      actualCost: action.actual_cost == null ? null : Number(action.actual_cost),
      currencyCode: action.currency_code,
      estimatedEffort: action.estimated_effort == null ? null : Number(action.estimated_effort),
      actualEffort: action.actual_effort == null ? null : Number(action.actual_effort),
      effortUnit: action.effort_unit,
      plannedDueDate: action.planned_due_date,
      forecastDueDate: action.forecast_due_date,
    })))
    const direct = loaded.initiative.direct

    setProjection(loaded)
    setPlannedCost(toInput(direct.plannedCost))
    setActualCost(toInput(direct.actualCost))
    setCurrencyCode(direct.currencyCode?.trim().toUpperCase() || 'BRL')
    setEstimatedEffort(toInput(direct.estimatedEffort))
    setActualEffort(toInput(direct.actualEffort))
    setEffortUnit(direct.effortUnit ?? '')
    setResourceEstimate(direct.resourceEstimate ?? '')
    setChangeReason('')
    setLoading(false)
  }

  useEffect(() => {
    void loadProjection()
  }, [initiativeId, organizationId])

  useEffect(() => {
    if (presentation !== 'dialog') return

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && !saving) {
        event.preventDefault()
        event.stopPropagation()
        onClose()
      }
    }

    document.addEventListener('keydown', handleKeyDown, true)
    return () =>
      document.removeEventListener('keydown', handleKeyDown, true)
  }, [onClose, saving])

  const lifecycleStatus = projection?.initiative.lifecycleStatus ?? null
  const editable =
    canManage &&
    lifecycleStatus !== null &&
    !['completed', 'cancelled', 'archived'].includes(lifecycleStatus)

  const save = async () => {
    if (!editable || saving) return

    const parsedPlannedCost = parseOptionalNumber(plannedCost)
    const parsedActualCost = parseOptionalNumber(actualCost)
    const parsedEstimatedEffort = parseOptionalNumber(estimatedEffort)
    const parsedActualEffort = parseOptionalNumber(actualEffort)

    const values = [
      parsedPlannedCost,
      parsedActualCost,
      parsedEstimatedEffort,
      parsedActualEffort,
    ]

    if (values.some((value) => typeof value === 'number' && (!Number.isFinite(value) || value < 0))) {
      setMessage({ type: 'error', text: 'Custos e esforços devem ser números não negativos.' })
      return
    }

    const normalizedCurrency = currencyCode.trim().toUpperCase()
    if (!/^[A-Z]{3}$/.test(normalizedCurrency)) {
      setMessage({ type: 'error', text: 'Informe a moeda com três letras, por exemplo BRL.' })
      return
    }

    if (
      (parsedEstimatedEffort !== null || parsedActualEffort !== null) &&
      !effortUnit
    ) {
      setMessage({ type: 'error', text: 'Informe a unidade quando houver esforço.' })
      return
    }

    if (changeReason.trim().length < 10) {
      setMessage({ type: 'error', text: 'Informe uma justificativa com pelo menos 10 caracteres.' })
      return
    }

    setSaving(true)
    setMessage(null)

    const { error } = await supabase.rpc(
      'set_sparks_initiative_economic_execution',
      {
        target_initiative_id: initiativeId,
        target_planned_cost: parsedPlannedCost,
        target_actual_cost: parsedActualCost,
        target_currency_code: normalizedCurrency,
        target_estimated_effort: parsedEstimatedEffort,
        target_actual_effort: parsedActualEffort,
        target_effort_unit: effortUnit || null,
        target_resource_estimate: resourceEstimate.trim() || null,
        change_reason: changeReason.trim(),
      },
    )

    if (error) {
      setMessage({ type: 'error', text: `Não foi possível salvar: ${translateBackendMessage(error.message)}` })
      setSaving(false)
      return
    }

    await loadProjection()
    await onSaved()
    setMessage({ type: 'success', text: 'Controle econômico da iniciativa atualizado e auditado.' })
    setSaving(false)
  }

  const direct = projection?.initiative.direct ?? null
  const costConsumption = direct ? percentageOfPlan(direct.actualCost, direct.plannedCost) : null
  const effortConsumption = direct ? percentageOfPlan(direct.actualEffort, direct.estimatedEffort) : null
  const scheduleReading = !executionContext?.targetEndDate
    ? 'Término-alvo não informado.'
    : !executionContext.forecastEndDate
      ? 'Forecast de término ainda não informado.'
      : executionContext.forecastEndDate > executionContext.targetEndDate
        ? 'Forecast posterior ao término-alvo registrado.'
        : executionContext.forecastEndDate < executionContext.targetEndDate
          ? 'Forecast anterior ao término-alvo registrado.'
          : 'Forecast alinhado ao término-alvo registrado.'

  return (
    <div
      className={
        presentation === 'panel'
          ? 'skpe-initiative-economic-panel'
          : 'skpe-modal-backdrop skpe-initiative-economic-overlay'
      }
      role="presentation"
      data-presentation={presentation}
      onClick={(event) => {
        if (
          presentation === 'dialog' &&
          event.target === event.currentTarget &&
          !saving
        ) {
          onClose()
        }
      }}
    >
      <aside
        className={
          presentation === 'panel'
            ? 'skpe-initiative-economic-panel-body'
            : 'skpe-modal-panel skpe-initiative-economic-dialog'
        }
        role={presentation === 'panel' ? 'region' : 'dialog'}
        aria-modal={presentation === 'dialog' ? true : undefined}
        aria-labelledby="skpe-initiative-economic-title"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="skpe-card-heading skpe-initiative-economic-dialog-header">
          <div>
            {presentation === 'panel' ? (
              <button type="button" className="skpe-workspace-back-button" onClick={onClose}>
                ← Voltar ao Kanban
              </button>
            ) : null}
            <p className="skpe-card-code">{initiativeCode}</p>
            <h2 id="skpe-initiative-economic-title">Orçamento e execução da iniciativa</h2>
            <p>{initiativeName}</p>
          </div>
                    {presentation === 'dialog' ? (
            <IconActionButton
              action="close"
              label="Fechar"
              onClick={onClose}
              disabled={saving}
            />
          ) : (
            <button
              type="button"
              className="skpe-workspace-back-button"
              onClick={onClose}
              disabled={saving}
            >
              <span aria-hidden="true">←</span>
              <span>Plano de Ação</span>
            </button>
          )}
        </div>

        {message && (
          <div className={`skpe-admin-message skpe-admin-message-${message.type}`}>
            {message.text}
          </div>
        )}

        {loading || !projection || !direct ? (
          <section className="skpe-admin-state-card">
            <p>Carregando controle econômico...</p>
          </section>
        ) : (
          <>
            <section className="skpe-initiative-form-card">
              <div className="skpe-card-heading">
                <div>
                  <p className="skpe-card-code">Orçamento e execução da iniciativa</p>
                  <h3>Orçamento da iniciativa × realizado</h3>
                </div>
              </div>

              <div className="skpe-initiative-kpi-grid">
                <div>
                  <span>Custo planejado</span>
                  <strong>{formatMoney(direct.plannedCost, direct.currencyCode)}</strong>
                </div>
                <div>
                  <span>Custo realizado</span>
                  <strong>{formatMoney(direct.actualCost, direct.currencyCode)}</strong>
                </div>
                <div>
                  <span>Variação de custo</span>
                  <strong>{formatVariance(direct.costVariance)}</strong>
                </div>
                <div>
                  <span>Variação de esforço</span>
                  <strong>{formatVariance(direct.effortVariance)}</strong>
                </div>
              </div>

              <section className="skpe-initiative-physical-financial" aria-label="Leitura físico-financeira">
                <div className="skpe-card-heading">
                  <div>
                    <p className="skpe-card-code">Leitura gerencial integrada</p>
                    <h3>Execução física × econômica × prazo</h3>
                    <p>Percentuais econômicos só são calculados quando planejado e realizado existem na mesma moeda ou unidade. Ausência de dado permanece como ausência.</p>
                  </div>
                </div>
                <div className="skpe-initiative-kpi-grid">
                  <div><span>Progresso físico</span><strong>{executionContext?.progress == null ? '—' : formatPercentage(executionContext.progress)}</strong></div>
                  <div><span>Consumo do orçamento direto</span><strong>{formatPercentage(costConsumption)}</strong></div>
                  <div><span>Consumo do esforço direto</span><strong>{formatPercentage(effortConsumption)}</strong></div>
                  <div><span>Término-alvo</span><strong>{formatDate(executionContext?.targetEndDate)}</strong></div>
                  <div><span>Forecast de término</span><strong>{formatDate(executionContext?.forecastEndDate)}</strong></div>
                  <div><span>Início realizado</span><strong>{formatDate(executionContext?.startedAt)}</strong></div>
                </div>
                <div className="skpe-initiative-management-reading">
                  <strong>Leitura factual para a gestão</strong>
                  <p>{direct ? economicInterpretation(direct.actualCost, direct.plannedCost, 'Custo') : 'Custo: sem leitura.'}</p>
                  <p>{direct ? economicInterpretation(direct.actualEffort, direct.estimatedEffort, 'Esforço') : 'Esforço: sem leitura.'}</p>
                  <p>{scheduleReading}</p>
                  <small>Esta leitura não classifica automaticamente a iniciativa como boa ou ruim e não substitui análise gerencial.</small>
                </div>
              </section>
              <div className="skpe-initiative-form-grid">
                <label><span>Custo planejado</span><input inputMode="decimal" value={plannedCost} onChange={(event) => setPlannedCost(event.target.value)} disabled={!editable} /></label>
                <label><span>Custo realizado</span><input inputMode="decimal" value={actualCost} onChange={(event) => setActualCost(event.target.value)} disabled={!editable} /></label>
                <label><span>Moeda</span><input value={currencyDisplayLabel(currencyCode)} maxLength={3} onChange={(event) => {
                  const value = event.target.value.trim().toUpperCase()
                  setCurrencyCode(value === 'R$' ? 'BRL' : value)
                }} disabled={!editable} /></label>
                <label><span>Esforço estimado</span><input inputMode="decimal" value={estimatedEffort} onChange={(event) => setEstimatedEffort(event.target.value)} disabled={!editable} /></label>
                <label><span>Esforço realizado</span><input inputMode="decimal" value={actualEffort} onChange={(event) => setActualEffort(event.target.value)} disabled={!editable} /></label>
                <label>
                  <span>Unidade de esforço</span>
                  <select value={effortUnit} onChange={(event) => setEffortUnit(event.target.value)} disabled={!editable}>
                    <option value="">Sem unidade</option>
                    {Object.entries(effortUnitLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
                  </select>
                </label>
                <label className="skpe-form-field-full"><span>Estimativa qualitativa de recursos</span><textarea value={resourceEstimate} onChange={(event) => setResourceEstimate(event.target.value)} disabled={!editable} /></label>
                {editable && <label className="skpe-form-field-full"><span>Justificativa para auditoria *</span><textarea value={changeReason} onChange={(event) => setChangeReason(event.target.value)} /></label>}
              </div>

              {editable && (
                <div className="skpe-initiative-form-actions">
                  <button type="button" className="skpe-primary-action-button" onClick={() => void save()} disabled={saving}>
                    {saving ? 'Salvando...' : 'Salvar controle econômico'}
                  </button>
                </div>
              )}
            </section>

            <section className="skpe-initiative-form-card">
              <div className="skpe-card-heading"><div><p className="skpe-card-code">Consolidação derivada das ações</p><h3>Custos por moeda</h3></div></div>
              {projection.actions.costByCurrency.length === 0 ? (
                <p>Nenhuma ação possui custo planejado ou realizado informado.</p>
              ) : (
                <div className="skpe-table-wrap">
                  <table className="skpe-admin-table">
                    <thead><tr><th>Moeda</th><th>Planejado vigente</th><th>Realizado</th><th>Variação</th></tr></thead>
                    <tbody>
                      {projection.actions.costByCurrency.map((row) => (
                        <tr key={row.currencyCode}>
                          <td>{currencyDisplayLabel(row.currencyCode)}</td>
                          <td>{formatMoney(row.currentPlannedCost, row.currencyCode)}</td>
                          <td>{formatMoney(row.actualRealizedCost, row.currencyCode)}</td>
                          <td>{formatVariance(row.currentPlanVariance)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </section>

            <section className="skpe-initiative-form-card">
              <div className="skpe-card-heading"><div><p className="skpe-card-code">Consolidação derivada das ações</p><h3>Esforço por unidade</h3></div></div>
              {projection.actions.effortByUnit.length === 0 ? (
                <p>Nenhuma ação possui esforço estimado ou realizado informado.</p>
              ) : (
                <div className="skpe-table-wrap">
                  <table className="skpe-admin-table">
                    <thead><tr><th>Unidade</th><th>Estimado vigente</th><th>Realizado</th><th>Variação</th></tr></thead>
                    <tbody>
                      {projection.actions.effortByUnit.map((row) => (
                        <tr key={row.effortUnit}>
                          <td>{effortUnitLabels[row.effortUnit] ?? row.effortUnit}</td>
                          <td>{formatNumber(row.currentEstimatedEffort)}</td>
                          <td>{formatNumber(row.actualRealizedEffort)}</td>
                          <td>{formatVariance(row.currentPlanVariance)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
              <p>Moedas diferentes e unidades de esforço diferentes permanecem separadas. Não há conversão cambial nem conversão implícita de grandezas.</p>
            </section>

            <section className="skpe-initiative-form-card">
              <div className="skpe-card-heading">
                <div>
                  <p className="skpe-card-code">Plano de ação e execução econômica</p>
                  <h3>Leitura físico-financeira por ação</h3>
                  <p>Cada ação preserva sua moeda e unidade de esforço. Desvios são diferenças factuais, sem conversão ou julgamento automático.</p>
                </div>
              </div>
              {economicActions.length === 0 ? (
                <p>Nenhuma ação vigente foi localizada para esta iniciativa.</p>
              ) : (
                <div className="skpe-table-wrap">
                  <table className="skpe-admin-table skpe-initiative-physical-financial-table">
                    <thead>
                      <tr>
                        <th>Ação</th><th>Situação</th><th>Progresso físico</th><th>Custo planejado</th><th>Custo realizado</th><th>Desvio de custo</th><th>Esforço estimado</th><th>Esforço realizado</th><th>Término planejado</th><th>Forecast</th>
                      </tr>
                    </thead>
                    <tbody>
                      {economicActions.map((action) => (
                        <tr key={action.id}>
                          <td><strong>{action.code}</strong><br /><span>{action.name}</span></td>
                          <td>{actionStatusLabel(action.status)}</td>
                          <td>{action.progress == null ? '—' : formatPercentage(action.progress)}</td>
                          <td>{formatMoney(action.plannedCost, action.currencyCode)}</td>
                          <td>{formatMoney(action.actualCost, action.currencyCode)}</td>
                          <td>{action.plannedCost == null || action.actualCost == null ? '—' : formatMoney(action.actualCost - action.plannedCost, action.currencyCode)}</td>
                          <td>{action.estimatedEffort == null ? '—' : `${formatNumber(action.estimatedEffort)} ${effortUnitLabels[action.effortUnit ?? ''] ?? action.effortUnit ?? ''}`.trim()}</td>
                          <td>{action.actualEffort == null ? '—' : `${formatNumber(action.actualEffort)} ${effortUnitLabels[action.effortUnit ?? ''] ?? action.effortUnit ?? ''}`.trim()}</td>
                          <td>{formatDate(action.plannedDueDate)}</td>
                          <td>{formatDate(action.forecastDueDate)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </section>
          </>
        )}
      </aside>
    </div>
  )
}