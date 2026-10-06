import { useEffect, useMemo, useState } from 'react'
import { supabase } from '../../lib/supabase'
import './MeasureIndicatorHistoryPanel.css'

type IndicatorIdentity = {
  indicator_id: string
  code: string | null
  name: string | null
  unit: string | null
}

type HistoryRow = {
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
  observation_order: number
  valid_observation_count: number
  trend_eligible: boolean
}

type Props = {
  organizationId: string
  sourceModuleCode: string
  indicator: IndicatorIdentity
  onClose: () => void
}

function dateLabel(value: string | null) {
  if (!value) return '—'
  const parsed = new Date(`${value}T00:00:00`)
  return Number.isNaN(parsed.getTime()) ? value : parsed.toLocaleDateString('pt-BR')
}

function numberLabel(value: number | null, unit: string | null) {
  if (value == null) return '—'
  const formatted = value.toLocaleString('pt-BR', { maximumFractionDigits: 4 })
  return unit ? `${formatted} ${unit}` : formatted
}

export function MeasureIndicatorHistoryPanel({
  organizationId,
  sourceModuleCode,
  indicator,
  onClose,
}: Props) {
  const [rows, setRows] = useState<HistoryRow[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setLoading(true)
      setErrorMessage('')

      const { data, error } = await supabase.rpc(
        'get_sparks_measure_indicator_history' as never,
        {
          target_organization_id: organizationId,
          target_source_module_code: sourceModuleCode,
          target_indicator_id: indicator.indicator_id,
          target_limit: 24,
        } as never,
      )

      if (!active) return
      if (error) {
        setRows([])
        setErrorMessage(error.message)
        setLoading(false)
        return
      }

      setRows(Array.isArray(data) ? (data as unknown as HistoryRow[]) : [])
      setLoading(false)
    }

    void load()
    return () => {
      active = false
    }
  }, [indicator.indicator_id, organizationId, sourceModuleCode])

  const chronological = useMemo(
    () =>
      rows
        .filter((row) => row.measured_value != null)
        .slice()
        .sort((a, b) => {
          const aTime = a.measurement_date ? Date.parse(a.measurement_date) : a.observation_order
          const bTime = b.measurement_date ? Date.parse(b.measurement_date) : b.observation_order
          return aTime - bTime
        }),
    [rows],
  )

  const trendEligible =
    chronological.length >= 3 && rows.some((row) => row.trend_eligible)

  const chart = useMemo(() => {
    if (!trendEligible) return null
    const values = chronological.map((row) => Number(row.measured_value))
    const minimum = Math.min(...values)
    const maximum = Math.max(...values)
    const span = maximum - minimum

    const points = chronological.map((row, index) => {
      const x = chronological.length === 1 ? 50 : 6 + (index / (chronological.length - 1)) * 88
      const normalized = span === 0 ? 0.5 : (Number(row.measured_value) - minimum) / span
      const y = 88 - normalized * 72
      return { row, x, y }
    })

    return {
      minimum,
      maximum,
      points,
      polyline: points.map((point) => `${point.x},${point.y}`).join(' '),
    }
  }, [chronological, trendEligible])

  const newest = chronological.at(-1) ?? null
  const oldest = chronological[0] ?? null

  return (
    <>
      <button
        type="button"
        className="sparks-measure-history-backdrop"
        aria-label="Fechar histórico do indicador"
        onClick={onClose}
      />
      <aside className="sparks-measure-history-panel" aria-label="Histórico e tendência do indicador">
        <header className="sparks-measure-history-panel__header">
          <div>
            <span>Histórico governado</span>
            <h3>{indicator.code ?? 'Indicador'} · {indicator.name ?? 'Sem nome'}</h3>
            <p>
              A trajetória usa somente apurações canônicas vigentes. Ausência de dado não vira zero.
            </p>
          </div>
          <button type="button" onClick={onClose}>Fechar</button>
        </header>

        {loading ? (
          <div className="sparks-measure-history-state">Carregando histórico...</div>
        ) : errorMessage ? (
          <div className="sparks-measure-history-state is-error">{errorMessage}</div>
        ) : (
          <>
            <div className="sparks-measure-history-summary">
              <article><span>Observações válidas</span><strong>{rows[0]?.valid_observation_count ?? rows.length}</strong></article>
              <article><span>Primeira apuração</span><strong>{numberLabel(oldest?.measured_value ?? null, indicator.unit)}</strong></article>
              <article><span>Última apuração</span><strong>{numberLabel(newest?.measured_value ?? null, indicator.unit)}</strong></article>
              <article><span>Período</span><strong>{oldest && newest ? `${dateLabel(oldest.measurement_date)} → ${dateLabel(newest.measurement_date)}` : '—'}</strong></article>
            </div>

            {!trendEligible ? (
              <section className="sparks-measure-history-insufficient">
                <strong>Histórico insuficiente para tendência governada</strong>
                <p>
                  São necessárias pelo menos 3 observações válidas. O SPARKs não cria uma curva sintética nem interpreta ausência de medição.
                </p>
              </section>
            ) : chart ? (
              <section className="sparks-measure-history-chart">
                <header>
                  <div>
                    <span>Trajetória descritiva</span>
                    <strong>{chronological.length} observações</strong>
                  </div>
                  <small>
                    A curva não classifica melhora ou piora automaticamente; essa interpretação depende de polaridade, meta e contexto governados.
                  </small>
                </header>
                <svg viewBox="0 0 100 100" role="img" aria-label="Trajetória histórica do indicador">
                  <line x1="6" y1="88" x2="94" y2="88" />
                  <line x1="6" y1="16" x2="6" y2="88" />
                  <polyline points={chart.polyline} />
                  {chart.points.map((point) => (
                    <circle key={point.row.measurement_id} cx={point.x} cy={point.y} r="1.8">
                      <title>{dateLabel(point.row.measurement_date)} · {numberLabel(point.row.measured_value, indicator.unit)}</title>
                    </circle>
                  ))}
                </svg>
                <div className="sparks-measure-history-range">
                  <span>Mínimo observado: {numberLabel(chart.minimum, indicator.unit)}</span>
                  <span>Máximo observado: {numberLabel(chart.maximum, indicator.unit)}</span>
                </div>
              </section>
            ) : null}

            <section className="sparks-measure-history-table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Data</th>
                    <th>Valor</th>
                    <th>Desempenho</th>
                    <th>Qualidade</th>
                    <th>Fonte</th>
                    <th>Evidência</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.length === 0 ? (
                    <tr><td colSpan={6}>Nenhuma apuração governada registrada para este indicador.</td></tr>
                  ) : rows.map((row) => (
                    <tr key={row.measurement_id}>
                      <td>{dateLabel(row.measurement_date)}</td>
                      <td>{numberLabel(row.measured_value, indicator.unit)}</td>
                      <td>{row.effective_performance == null ? '—' : `${row.effective_performance.toLocaleString('pt-BR', { maximumFractionDigits: 1 })}%`}</td>
                      <td>{row.data_quality ?? 'Não informada'}</td>
                      <td>{row.source_name ?? row.source_reference ?? 'Não informada'}</td>
                      <td>{row.evidence_reference ?? 'Não informada'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          </>
        )}
      </aside>
    </>
  )
}
