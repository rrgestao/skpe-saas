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

    const { data, error } = await supabase.rpc(
      'get_sparks_initiative_economic_projection',
      {
        target_organization_id: organizationId,
        target_initiative_id: initiativeId,
      },
    )

    if (error) {
      setProjection(null)
      setMessage({
        type: 'error',
        text: `Não foi possível carregar o controle econômico: ${translateBackendMessage(error.message)}`,
      })
      setLoading(false)
      return
    }

    const loaded = data as EconomicProjection
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
            <p className="skpe-card-code">{initiativeCode}</p>
            <h2 id="skpe-initiative-economic-title">Custos e esforço</h2>
            <p>{initiativeName}</p>
          </div>
                    {presentation === 'dialog' ? (
            <IconActionButton
              action="close"
              label="Fechar"
              onClick={onClose}
              disabled={saving}
            />
          ) : null}
        </div>

        <div className="skpe-admin-state-card">
          <strong>Fronteira do controle</strong>
          <p>
            Esta visão acompanha execução gerencial. Não substitui contabilidade,
            orçamento corporativo, contas a pagar/receber nem futura integração financeira.
          </p>
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
                  <p className="skpe-card-code">Valores diretos da iniciativa</p>
                  <h3>Planejado × realizado</h3>
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

              <div className="skpe-initiative-form-grid">
                <label><span>Custo planejado</span><input inputMode="decimal" value={plannedCost} onChange={(event) => setPlannedCost(event.target.value)} disabled={!editable} /></label>
                <label><span>Custo realizado</span><input inputMode="decimal" value={actualCost} onChange={(event) => setActualCost(event.target.value)} disabled={!editable} /></label>
                <label><span>Moeda</span><input value={currencyCode} maxLength={3} onChange={(event) => setCurrencyCode(event.target.value.toUpperCase())} disabled={!editable} /></label>
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
          </>
        )}
      </aside>
    </div>
  )
}