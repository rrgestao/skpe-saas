import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'
import { translateBackendMessage } from '../../../../shared/i18n/ptBR'

export type InitiativeEconomicDirect = {
  plannedCost: number | null
  actualCost: number | null
  currencyCode: string | null
  costVariance: number | null
  estimatedEffort: number | null
  actualEffort: number | null
  effortUnit: string | null
  effortVariance: number | null
  resourceEstimate: string | null
}

type InitiativeEconomicExecutionDialogProps = {
  initiativeId: string
  initiativeCode: string
  initiativeName: string
  lifecycleStatus: string
  direct: InitiativeEconomicDirect
  onClose: () => void
  onSaved: () => void
}

const closedStatuses = new Set([
  'completed',
  'cancelled',
  'archived',
])

function toInputNumber(value: number | null) {
  return value === null ? '' : String(value)
}

function parseOptionalNumber(value: string) {
  if (!value.trim()) return null

  const parsed = Number(value.replace(',', '.'))
  return Number.isFinite(parsed) ? parsed : Number.NaN
}

export function InitiativeEconomicExecutionDialog({
  initiativeId,
  initiativeCode,
  initiativeName,
  lifecycleStatus,
  direct,
  onClose,
  onSaved,
}: InitiativeEconomicExecutionDialogProps) {
  const [plannedCost, setPlannedCost] = useState(
    toInputNumber(direct.plannedCost),
  )
  const [actualCost, setActualCost] = useState(
    toInputNumber(direct.actualCost),
  )
  const [currencyCode, setCurrencyCode] = useState(
    direct.currencyCode ?? 'BRL',
  )
  const [estimatedEffort, setEstimatedEffort] = useState(
    toInputNumber(direct.estimatedEffort),
  )
  const [actualEffort, setActualEffort] = useState(
    toInputNumber(direct.actualEffort),
  )
  const [effortUnit, setEffortUnit] = useState(
    direct.effortUnit ?? '',
  )
  const [resourceEstimate, setResourceEstimate] = useState(
    direct.resourceEstimate ?? '',
  )
  const [changeReason, setChangeReason] = useState('')
  const [saving, setSaving] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const isClosed = closedStatuses.has(lifecycleStatus)

  const numericValues = useMemo(
    () => ({
      plannedCost: parseOptionalNumber(plannedCost),
      actualCost: parseOptionalNumber(actualCost),
      estimatedEffort: parseOptionalNumber(estimatedEffort),
      actualEffort: parseOptionalNumber(actualEffort),
    }),
    [actualCost, actualEffort, estimatedEffort, plannedCost],
  )

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape' && !saving) onClose()
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [onClose, saving])

  async function saveEconomicExecution() {
    const reason = changeReason.trim()
    const normalizedCurrency = currencyCode.trim().toUpperCase()
    const normalizedResource = resourceEstimate.trim() || null

    if (isClosed) {
      setErrorMessage(
        'A execução econômica não pode ser alterada após o encerramento da iniciativa.',
      )
      return
    }

    if (
      Number.isNaN(numericValues.plannedCost) ||
      Number.isNaN(numericValues.actualCost) ||
      Number.isNaN(numericValues.estimatedEffort) ||
      Number.isNaN(numericValues.actualEffort)
    ) {
      setErrorMessage('Informe valores numéricos válidos.')
      return
    }

    if (
      (numericValues.plannedCost ?? 0) < 0 ||
      (numericValues.actualCost ?? 0) < 0 ||
      (numericValues.estimatedEffort ?? 0) < 0 ||
      (numericValues.actualEffort ?? 0) < 0
    ) {
      setErrorMessage('Custos e esforços não podem ser negativos.')
      return
    }

    if (!/^[A-Z]{3}$/.test(normalizedCurrency)) {
      setErrorMessage('Informe a moeda no padrão ISO de três letras, como BRL.')
      return
    }

    if (
      (numericValues.estimatedEffort !== null ||
        numericValues.actualEffort !== null) &&
      !effortUnit
    ) {
      setErrorMessage(
        'Informe a unidade quando houver esforço estimado ou realizado.',
      )
      return
    }

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa com pelo menos 10 caracteres.',
      )
      return
    }

    setSaving(true)
    setErrorMessage(null)

    const { error } = await supabase.rpc(
      'set_sparks_initiative_economic_execution',
      {
        target_initiative_id: initiativeId,
        target_planned_cost: numericValues.plannedCost,
        target_actual_cost: numericValues.actualCost,
        target_currency_code: normalizedCurrency,
        target_estimated_effort: numericValues.estimatedEffort,
        target_actual_effort: numericValues.actualEffort,
        target_effort_unit: effortUnit || null,
        target_resource_estimate: normalizedResource,
        change_reason: reason,
      },
    )

    if (error) {
      setErrorMessage(translateBackendMessage(error.message))
      setSaving(false)
      return
    }

    onSaved()
  }

  return (
    <div
      className="skpe-economic-dialog-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !saving) onClose()
      }}
    >
      <section
        className="skpe-economic-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="skpe-economic-dialog-title"
      >
        <header>
          <div>
            <span>Execução econômica governada</span>
            <h2 id="skpe-economic-dialog-title">
              {initiativeCode} — {initiativeName}
            </h2>
          </div>
          <button type="button" onClick={onClose} disabled={saving}>
            Fechar
          </button>
        </header>

        <p className="skpe-economic-dialog-note">
          Estes valores pertencem diretamente à iniciativa. Os valores das ações
          permanecem independentes e não são somados automaticamente à iniciativa.
        </p>

        <div className="skpe-economic-dialog-grid">
          <label>
            <span>Custo planejado</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={plannedCost}
              onChange={(event) => setPlannedCost(event.target.value)}
              disabled={saving || isClosed}
            />
          </label>

          <label>
            <span>Custo realizado</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={actualCost}
              onChange={(event) => setActualCost(event.target.value)}
              disabled={saving || isClosed}
            />
          </label>

          <label>
            <span>Moeda *</span>
            <input
              maxLength={3}
              value={currencyCode}
              onChange={(event) => setCurrencyCode(event.target.value)}
              disabled={saving || isClosed}
              placeholder="BRL"
            />
          </label>

          <label>
            <span>Unidade de esforço</span>
            <select
              value={effortUnit}
              onChange={(event) => setEffortUnit(event.target.value)}
              disabled={saving || isClosed}
            >
              <option value="">Não definida</option>
              <option value="hours">Horas</option>
              <option value="days">Dias</option>
              <option value="weeks">Semanas</option>
              <option value="months">Meses</option>
              <option value="points">Pontos</option>
              <option value="custom">Personalizada</option>
            </select>
          </label>

          <label>
            <span>Esforço estimado</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={estimatedEffort}
              onChange={(event) => setEstimatedEffort(event.target.value)}
              disabled={saving || isClosed}
            />
          </label>

          <label>
            <span>Esforço realizado</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={actualEffort}
              onChange={(event) => setActualEffort(event.target.value)}
              disabled={saving || isClosed}
            />
          </label>

          <label className="is-wide">
            <span>Estimativa qualitativa de recursos</span>
            <textarea
              rows={3}
              value={resourceEstimate}
              onChange={(event) => setResourceEstimate(event.target.value)}
              disabled={saving || isClosed}
              placeholder="Ex.: equipe interna, consultoria, viagens, infraestrutura..."
            />
          </label>

          <label className="is-wide">
            <span>Justificativa para auditoria *</span>
            <textarea
              rows={3}
              value={changeReason}
              onChange={(event) => setChangeReason(event.target.value)}
              disabled={saving || isClosed}
            />
          </label>
        </div>

        {isClosed ? (
          <div className="skpe-economic-dialog-message">
            A iniciativa está encerrada ({lifecycleStatus}) e seus valores econômicos
            ficam preservados para leitura histórica.
          </div>
        ) : null}

        {errorMessage ? (
          <div className="skpe-economic-dialog-message is-error" role="alert">
            {errorMessage}
          </div>
        ) : null}

        <footer>
          <button type="button" onClick={onClose} disabled={saving}>
            Cancelar
          </button>
          <button
            type="button"
            className="is-primary"
            onClick={() => void saveEconomicExecution()}
            disabled={saving || isClosed}
          >
            {saving ? 'Salvando...' : 'Salvar execução econômica'}
          </button>
        </footer>
      </section>
    </div>
  )
}