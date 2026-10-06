import { useEffect, useMemo, useState } from 'react'
import { supabase } from '../../../lib/supabase'
import './StrategicObjectiveExecutiveAnalytics.css'

type Props = {
  organizationId: string
  projectId: string
  formulationId: string
  onOpenMeasures: (objectiveId: string, objectiveTitle: string) => void
  onOpenInitiatives: (objectiveId: string, objectiveTitle: string, initiativeIds: string[]) => void
}

type Row = Record<string, unknown>

type ObjectiveAnalyticsRow = {
  id: string
  code: string
  name: string
  validationStatus: string
  indicators: number
  officialTargets: number
  officialBenchmarks: number
  okrs: number
  keyResults: number
  initiatives: number
  inProgress: number
  actions: number
  attention: number
  initiativeIds: string[]
}

function text(row: Row, key: string) {
  const value = row[key]
  return typeof value === 'string' ? value : ''
}

function unique(values: string[]) {
  return Array.from(new Set(values.filter(Boolean)))
}

export function StrategicObjectiveExecutiveAnalytics({
  organizationId,
  projectId,
  formulationId,
  onOpenMeasures,
  onOpenInitiatives,
}: Props) {
  const [rows, setRows] = useState<ObjectiveAnalyticsRow[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setLoading(true)
      setErrorMessage('')

      const [objectives, indicators, targets, benchmarks, keyResults] = await Promise.all([
        supabase
          .from('skpe_strategic_objectives')
          .select('id,code,name,status,validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId)
          .neq('status', 'archived')
          .order('code'),
        supabase
          .from('skpe_indicators')
          .select('id,strategic_objective_id,status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId)
          .eq('indicator_scope', 'strategic_kpi')
          .neq('status', 'archived'),
        supabase
          .from('skpe_indicator_targets')
          .select('indicator_id,status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId),
        supabase
          .from('skpe_benchmark_references')
          .select('indicator_id,status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId),
        supabase
          .from('skpe_key_results')
          .select('id,strategic_objective_id,okr_id,status,validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId)
          .neq('status', 'cancelled'),
      ])

      if (!active) return

      const firstError =
        objectives.error ||
        indicators.error ||
        targets.error ||
        benchmarks.error ||
        keyResults.error

      if (firstError) {
        setRows([])
        setErrorMessage(firstError.message)
        setLoading(false)
        return
      }

      const objectiveRows = (objectives.data ?? []) as Row[]
      const indicatorRows = (indicators.data ?? []) as Row[]
      const targetRows = (targets.data ?? []) as Row[]
      const benchmarkRows = (benchmarks.data ?? []) as Row[]
      const keyResultRows = (keyResults.data ?? []) as Row[]

      const keyResultIds = keyResultRows.map((row) => text(row, 'id')).filter(Boolean)
      let linkRows: Row[] = []
      if (keyResultIds.length) {
        const links = await supabase
          .from('skpe_initiative_key_results')
          .select('initiative_id,key_result_id,validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId)
          .in('key_result_id', keyResultIds)
        if (!active) return
        if (links.error) {
          setRows([])
          setErrorMessage(links.error.message)
          setLoading(false)
          return
        }
        linkRows = (links.data ?? []) as Row[]
      }

      const initiativeIds = unique(linkRows.map((row) => text(row, 'initiative_id')))
      let initiativeRows: Row[] = []
      let actionRows: Row[] = []

      if (initiativeIds.length) {
        const [initiatives, actions] = await Promise.all([
          supabase
            .from('sparks_initiatives')
            .select('id,status,criticality,target_end_date,archived_at')
            .in('id', initiativeIds)
            .is('archived_at', null),
          supabase
            .from('sparks_initiative_actions')
            .select('id,initiative_id,status,archived_at')
            .in('initiative_id', initiativeIds)
            .is('archived_at', null),
        ])
        if (!active) return
        if (initiatives.error || actions.error) {
          setRows([])
          setErrorMessage((initiatives.error || actions.error)?.message ?? 'Não foi possível carregar a execução dos objetivos.')
          setLoading(false)
          return
        }
        initiativeRows = (initiatives.data ?? []) as Row[]
        actionRows = (actions.data ?? []) as Row[]
      }

      const targetOfficial = new Set(
        targetRows
          .filter((row) => ['active', 'achieved', 'not_achieved'].includes(text(row, 'status')))
          .map((row) => text(row, 'indicator_id')),
      )
      const benchmarkOfficial = new Set(
        benchmarkRows
          .filter((row) => ['active', 'verified'].includes(text(row, 'status')))
          .map((row) => text(row, 'indicator_id')),
      )

      const analytics = objectiveRows.map((objective) => {
        const objectiveId = text(objective, 'id')
        const objectiveIndicators = indicatorRows.filter(
          (indicator) => text(indicator, 'strategic_objective_id') === objectiveId,
        )
        const objectiveKrs = keyResultRows.filter(
          (kr) => text(kr, 'strategic_objective_id') === objectiveId,
        )
        const objectiveKrIds = new Set(objectiveKrs.map((kr) => text(kr, 'id')))
        const objectiveInitiativeIds = unique(
          linkRows
            .filter((link) => objectiveKrIds.has(text(link, 'key_result_id')))
            .map((link) => text(link, 'initiative_id')),
        )
        const objectiveInitiativeSet = new Set(objectiveInitiativeIds)
        const objectiveInitiatives = initiativeRows.filter((initiative) =>
          objectiveInitiativeSet.has(text(initiative, 'id')),
        )
        const objectiveActions = actionRows.filter((action) =>
          objectiveInitiativeSet.has(text(action, 'initiative_id')),
        )
        const attentionInitiatives = objectiveInitiatives.filter((initiative) => {
          const status = text(initiative, 'status')
          const criticality = text(initiative, 'criticality')
          const dueDate = text(initiative, 'target_end_date')
          return status === 'blocked' || criticality === 'critical' || !dueDate
        }).length

        return {
          id: objectiveId,
          code: text(objective, 'code'),
          name: text(objective, 'name') || 'Objetivo sem nome',
          validationStatus: text(objective, 'validation_status'),
          indicators: objectiveIndicators.length,
          officialTargets: objectiveIndicators.filter((indicator) =>
            targetOfficial.has(text(indicator, 'id')),
          ).length,
          officialBenchmarks: objectiveIndicators.filter((indicator) =>
            benchmarkOfficial.has(text(indicator, 'id')),
          ).length,
          okrs: unique(objectiveKrs.map((kr) => text(kr, 'okr_id'))).length,
          keyResults: objectiveKrs.length,
          initiatives: objectiveInitiatives.length,
          inProgress: objectiveInitiatives.filter(
            (initiative) => text(initiative, 'status') === 'in_progress',
          ).length,
          actions: objectiveActions.length,
          attention: attentionInitiatives,
          initiativeIds: objectiveInitiativeIds,
        }
      })

      setRows(analytics)
      setLoading(false)
    }

    void load()
    return () => {
      active = false
    }
  }, [formulationId, organizationId, projectId])

  const totals = useMemo(
    () => ({
      objectives: rows.length,
      indicators: rows.reduce((sum, row) => sum + row.indicators, 0),
      initiatives: rows.reduce((sum, row) => sum + row.initiatives, 0),
      attention: rows.reduce((sum, row) => sum + row.attention, 0),
    }),
    [rows],
  )

  if (loading) {
    return <div className="skpe-objective-analytics-state">Carregando leitura por Objetivo Estratégico...</div>
  }

  if (errorMessage) {
    return <div className="skpe-objective-analytics-state is-error">Não foi possível montar a leitura por Objetivo Estratégico: {errorMessage}</div>
  }

  if (!rows.length) {
    return <div className="skpe-objective-analytics-state">Nenhum Objetivo Estratégico governado está disponível neste contexto.</div>
  }

  return (
    <section className="skpe-objective-analytics" aria-label="Leitura executiva por Objetivo Estratégico">
      <header>
        <div>
          <p>Rastreabilidade executiva</p>
          <h2>Objetivos Estratégicos e sua cadeia de execução</h2>
        </div>
        <span>
          {totals.objectives} OE · {totals.indicators} KPI · {totals.initiatives} iniciativa(s) · {totals.attention} sinal(is)
        </span>
      </header>

      <p className="skpe-objective-analytics__rule">
        Esta leitura não cria nota de saúde. Ela mostra somente vínculos e estados governados já existentes entre objetivo, medida, OKR/KR e execução.
      </p>

      <div className="skpe-objective-analytics__grid">
        {rows.map((row) => (
          <article key={row.id} className="skpe-objective-analytics__card">
            <div className="skpe-objective-analytics__title">
              <span>{row.code || 'OE'}</span>
              <h3>{row.name}</h3>
              <small>{['validated', 'approved'].includes(row.validationStatus) ? 'Objetivo validado' : 'Objetivo ainda não validado'}</small>
            </div>

            <div className="skpe-objective-analytics__metrics">
              <div><span>KPIs</span><strong>{row.indicators}</strong></div>
              <div><span>Metas oficiais</span><strong>{row.officialTargets}</strong></div>
              <div><span>Benchmarks oficiais</span><strong>{row.officialBenchmarks}</strong></div>
              <div><span>OKRs / KRs</span><strong>{row.okrs} / {row.keyResults}</strong></div>
              <div><span>Iniciativas</span><strong>{row.initiatives}</strong><small>{row.inProgress} em execução</small></div>
              <div><span>Ações</span><strong>{row.actions}</strong></div>
              <div className={row.attention ? 'is-attention' : ''}><span>Sinais de atenção</span><strong>{row.attention}</strong></div>
            </div>

            <div className="skpe-objective-analytics__actions">
              <button type="button" onClick={() => onOpenMeasures(row.id, `${row.code} · ${row.name}`)}>
                Ver indicadores e metas
              </button>
              <button
                type="button"
                onClick={() => onOpenInitiatives(row.id, `${row.code} · ${row.name}`, row.initiativeIds)}
                disabled={!row.initiativeIds.length}
              >
                Ver iniciativas vinculadas
              </button>
            </div>
          </article>
        ))}
      </div>
    </section>
  )
}
