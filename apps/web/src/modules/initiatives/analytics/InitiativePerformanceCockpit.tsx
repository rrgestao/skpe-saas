import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { StrategicBscMap } from '../../skpe/features/strategy/StrategicBscMap'
import { StrategicObjectiveExecutiveAnalytics } from './StrategicObjectiveExecutiveAnalytics'
import { buildExecutivePerformanceReportHtml } from './executivePerformanceReport'

import './InitiativePerformanceCockpit.css'

type DrilldownFilter =
  | 'all'
  | 'in_progress'
  | 'draft'
  | 'under_analysis'
  | 'critical'
  | 'blocked'
  | 'attention'
  | 'without_due_date'

type JourneyPerformanceSnapshot = {
  actualProgress: number | null
  plannedProgress: number | null
  variancePoints: number | null
  overdueItems: number
  completedItems: number
  totalItems: number
  referenceDate: string | null
  hasApprovedPlan: boolean
  planningStatus: 'approved' | 'proposed' | 'unavailable'
  currentMacrophaseCode: string | null
  currentMacrophaseName: string | null
  currentMacrophaseStatus: string | null
  currentMacrophaseTargetDate: string | null
  nextMilestoneCode: string | null
  nextMilestoneName: string | null
  nextMilestoneTargetDate: string | null
}

type InitiativePerformanceCockpitProps = {
  surface?: 'dashboard' | 'monitoring'
  dashboard: unknown
  organizationId: string
  organizationName?: string
  projectName?: string
  projectId?: string | null
  initiatives: unknown[]
  journeySnapshot?: JourneyPerformanceSnapshot | null
  canAdjustStrategicMap: boolean
  onJourneyDrilldown?: () => void
  onStatusDrilldown: (filter: DrilldownFilter) => void
  onObjectiveInitiativesDrilldown: (
    objectiveId: string,
    objectiveTitle: string,
    initiativeIds: string[],
  ) => void
  onObjectivePerformanceDrilldown: (objectiveId: string, objectiveTitle: string) => void
}

type NormalizedInitiative = {
  id: string
  code: string
  name: string
  status: string
  priority: string
  initiativeClass: string
  responsibleArea: string
  responsibleName: string
  criticality: string
  proposalOrigin: string
  startDate: string
  dueDate: string
  progress: number | null
  healthStatus: string
  lastUpdateAt: string
  strategicObjectiveNames: string[]
  projectId: string
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object'
    ? (value as Record<string, unknown>)
    : {}
}

function readString(record: Record<string, unknown>, ...keys: string[]): string {
  for (const key of keys) {
    const value = record[key]
    if (typeof value === 'string' && value.trim()) return value.trim()
  }
  return ''
}

function readNumber(record: Record<string, unknown>, ...keys: string[]): number | null {
  for (const key of keys) {
    const value = record[key]
    if (typeof value === 'number' && Number.isFinite(value)) return value
    if (typeof value === 'string' && value.trim()) {
      const parsed = Number(value)
      if (Number.isFinite(parsed)) return parsed
    }
  }
  return null
}

function formatDashboardDate(value: string | null | undefined) {
  if (!value) return '—'
  const parsed = new Date(`${value}T00:00:00`)
  if (Number.isNaN(parsed.getTime())) return value
  return new Intl.DateTimeFormat('pt-BR').format(parsed)
}

function distribution(
  items: NormalizedInitiative[],
  pick: (item: NormalizedInitiative) => string,
  fallback: string,
) {
  const counts = new Map<string, number>()
  for (const item of items) {
    const key = pick(item).trim() || fallback
    counts.set(key, (counts.get(key) ?? 0) + 1)
  }
  return Array.from(counts.entries())
    .map(([label, value]) => ({ label, value }))
    .sort((a, b) => b.value - a.value || a.label.localeCompare(b.label, 'pt-BR'))
}

function priorityLabel(value: string) {
  return (
    {
      critical: 'Crítica',
      high: 'Alta',
      medium: 'Média',
      low: 'Baixa',
    }[value] ?? (value || 'Não informada')
  )
}

function classLabel(value: string) {
  return (
    {
      program: 'Programa',
      project: 'Projeto',
      structuring_action: 'Ação estruturante',
      process: 'Processo',
      sprint: 'Sprint',
      task: 'Tarefa',
      work: 'Trabalho',
      initiative: 'Iniciativa',
    }[value] ?? (value || 'Não informada')
  )
}

function csvCell(value: unknown) {
  const text = String(value ?? '')
  return `"${text.replaceAll('"', '""')}"`
}
function normalizeInitiative(value: unknown): NormalizedInitiative {
  const record = asRecord(value)
  return {
    id: readString(record, 'initiative_id', 'id'),
    code: readString(record, 'initiative_code', 'code'),
    name: readString(record, 'initiative_name', 'name'),
    status: readString(record, 'initiative_status', 'status'),
    priority: readString(record, 'priority'),
    initiativeClass: readString(record, 'initiative_class', 'initiativeClass', 'class'),
    responsibleArea: readString(
      record,
      'responsible_area_name',
      'responsibleAreaName',
      'responsible_area_code',
    ),
    responsibleName: readString(record, 'responsible_name', 'responsibleName'),
    criticality: readString(record, 'criticality'),
    proposalOrigin: readString(record, 'proposal_origin', 'proposalOrigin'),
    startDate: readString(record, 'start_date', 'startDate'),
    dueDate: readString(record, 'target_end_date', 'targetEndDate', 'due_date', 'dueDate'),
    progress: readNumber(record, 'progress'),
    healthStatus: readString(record, 'health_status', 'healthStatus'),
    lastUpdateAt: readString(record, 'last_update_at', 'lastUpdateAt'),
    strategicObjectiveNames: Array.isArray(record.strategic_objective_names)
      ? record.strategic_objective_names.filter(
          (item): item is string => typeof item === 'string' && item.trim() !== '',
        )
      : [],
    projectId: readString(record, 'skpe_project_id', 'project_id', 'projectId'),
  }
}

export function InitiativePerformanceCockpit({
  surface = 'monitoring',
  organizationId,
  organizationName = 'Organização',
  projectName = 'Planejamento Estratégico',
  projectId: projectIdProp = null,
  initiatives,
  journeySnapshot = null,
  canAdjustStrategicMap,
  onJourneyDrilldown,
  onStatusDrilldown,
  onObjectiveInitiativesDrilldown,
  onObjectivePerformanceDrilldown,
}: InitiativePerformanceCockpitProps) {
  const normalized = useMemo(
    () => initiatives.map(normalizeInitiative),
    [initiatives],
  )
  const [formulationId, setFormulationId] = useState<string | null>(null)
  const [formulationResolution, setFormulationResolution] = useState<
    'loading' | 'resolved' | 'unavailable'
  >('loading')
  const [deviationRanges, setDeviationRanges] = useState({ adequateMax: 15, attentionMax: 30 })
  const [planReadiness, setPlanReadiness] = useState({
    objectivesReady: null as number | null,
    objectivesTotal: null as number | null,
    okrsReady: null as number | null,
    okrsTotal: null as number | null,
  })

  const projectId = useMemo(() => {
    if (projectIdProp) return projectIdProp
    const ids = Array.from(
      new Set(normalized.map((item) => item.projectId).filter(Boolean)),
    )
    return ids.length === 1 ? ids[0] : null
  }, [normalized, projectIdProp])

  useEffect(() => {
    let active = true

    async function loadDeviationRanges() {
      const { data, error } = await supabase.rpc('list_sparks_effective_parameters', {
        p_organization_id: organizationId,
        p_module_code: 'SK-PE',
        p_project_id: projectId,
      })
      if (!active || error) return

      let adequateMax = 15
      let attentionMax = 30
      for (const raw of data ?? []) {
        const row = asRecord(raw)
        const key = readString(row, 'parameter_key')
        const value = readNumber(row, 'value')
        if (value == null) continue
        if (key === 'SKPE.PERFORMANCE.DEVIATION.ADEQUATE_MAX_PERCENT') adequateMax = value
        if (key === 'SKPE.PERFORMANCE.DEVIATION.ATTENTION_MAX_PERCENT') attentionMax = value
      }
      setDeviationRanges({ adequateMax, attentionMax: Math.max(adequateMax, attentionMax) })
    }

    void loadDeviationRanges()
    return () => { active = false }
  }, [organizationId, projectId])

  useEffect(() => {
    let active = true

    async function resolveFormulation() {
      if (!projectId) {
        setFormulationId(null)
        setFormulationResolution('unavailable')
        return
      }

      setFormulationResolution('loading')

      const { data, error } = await supabase
        .from('skpe_strategic_formulations')
        .select('id')
        .eq('project_id', projectId)
        .in('status', ['draft', 'under_review', 'approved'])
        .order('version_number', { ascending: false })
        .limit(2)

      if (!active) return

      if (error || !data || data.length !== 1) {
        setFormulationId(null)
        setFormulationResolution('unavailable')
        return
      }

      setFormulationId(data[0]?.id ?? null)
      setFormulationResolution(data[0]?.id ? 'resolved' : 'unavailable')
    }

    void resolveFormulation()

    return () => {
      active = false
    }
  }, [projectId])

  useEffect(() => {
    let active = true

    async function loadPlanReadiness() {
      if (!projectId || !formulationId || formulationResolution !== 'resolved') {
        if (active) {
          setPlanReadiness({
            objectivesReady: null,
            objectivesTotal: null,
            okrsReady: null,
            okrsTotal: null,
          })
        }
        return
      }

      const [objectivesResponse, indicatorsResponse, targetsResponse, okrsResponse, keyResultsResponse] = await Promise.all([
        supabase
          .from('skpe_strategic_objectives')
          .select('id, status, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId)
          .neq('status', 'archived'),
        supabase
          .from('skpe_indicators')
          .select('id, strategic_objective_id, status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId)
          .eq('indicator_scope', 'strategic_kpi')
          .eq('status', 'active'),
        supabase
          .from('skpe_indicator_targets')
          .select('indicator_id, status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId)
          .eq('status', 'active'),
        supabase
          .from('skpe_okrs')
          .select('id, status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId)
          .neq('status', 'cancelled'),
        supabase
          .from('skpe_key_results')
          .select('id, okr_id, status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .eq('formulation_id', formulationId)
          .neq('status', 'cancelled'),
      ])

      if (!active) return

      if (
        objectivesResponse.error ||
        indicatorsResponse.error ||
        targetsResponse.error ||
        okrsResponse.error ||
        keyResultsResponse.error
      ) {
        setPlanReadiness({
          objectivesReady: null,
          objectivesTotal: null,
          okrsReady: null,
          okrsTotal: null,
        })
        return
      }

      const objectiveRows = (objectivesResponse.data ?? []).map(asRecord)
      const indicatorRows = (indicatorsResponse.data ?? []).map(asRecord)
      const targetRows = (targetsResponse.data ?? []).map(asRecord)
      const okrRows = (okrsResponse.data ?? []).map(asRecord)
      const keyResultRows = (keyResultsResponse.data ?? []).map(asRecord)

      const indicatorsWithActiveTarget = new Set(
        targetRows.map((row) => readString(row, 'indicator_id')).filter(Boolean),
      )
      const objectivesWithReadyMeasure = new Set(
        indicatorRows
          .filter((row) => indicatorsWithActiveTarget.has(readString(row, 'id')))
          .map((row) => readString(row, 'strategic_objective_id'))
          .filter(Boolean),
      )
      const objectivesReady = objectiveRows.filter((row) => {
        const validationStatus = readString(row, 'validation_status')
        return (
          ['validated', 'approved'].includes(validationStatus) &&
          objectivesWithReadyMeasure.has(readString(row, 'id'))
        )
      }).length

      const keyResultIds = keyResultRows
        .map((row) => readString(row, 'id'))
        .filter(Boolean)
      let linkedKeyResultIds = new Set<string>()

      if (keyResultIds.length) {
        const linksResponse = await supabase
          .from('skpe_initiative_key_results')
          .select('initiative_id, key_result_id')
          .in('key_result_id', keyResultIds)

        if (!active) return
        if (!linksResponse.error) {
          const availableInitiativeIds = new Set(normalized.map((item) => item.id))
          linkedKeyResultIds = new Set(
            (linksResponse.data ?? [])
              .map(asRecord)
              .filter((row) => availableInitiativeIds.has(readString(row, 'initiative_id')))
              .map((row) => readString(row, 'key_result_id'))
              .filter(Boolean),
          )
        }
      }

      const keyResultsByOkr = new Map<string, string[]>()
      for (const row of keyResultRows) {
        const okrId = readString(row, 'okr_id')
        const keyResultId = readString(row, 'id')
        if (!okrId || !keyResultId) continue
        const current = keyResultsByOkr.get(okrId) ?? []
        current.push(keyResultId)
        keyResultsByOkr.set(okrId, current)
      }

      const okrsReady = okrRows.filter((row) => {
        const okrId = readString(row, 'id')
        const keyResults = keyResultsByOkr.get(okrId) ?? []
        return keyResults.length > 0 && keyResults.every((keyResultId) => linkedKeyResultIds.has(keyResultId))
      }).length

      setPlanReadiness({
        objectivesReady,
        objectivesTotal: objectiveRows.length,
        okrsReady,
        okrsTotal: okrRows.length,
      })
    }

    void loadPlanReadiness()
    return () => { active = false }
  }, [formulationId, formulationResolution, organizationId, projectId, normalized])

  const total = normalized.length
  const proposals = normalized.filter((item) => item.status === 'proposed').length
  const drafts = normalized.filter(
    (item) =>
      item.status === 'proposed' &&
      item.proposalOrigin === 'sparks_suggestion',
  ).length
  const inProgress = normalized.filter((item) => item.status === 'in_progress').length
  const underAnalysis = normalized.filter((item) => item.status === 'under_analysis').length
  const blocked = normalized.filter((item) => item.status === 'blocked').length
  const completed = normalized.filter((item) => item.status === 'completed').length
  const critical = normalized.filter((item) => item.criticality === 'critical').length
  const withoutDueDate = normalized.filter((item) => !item.dueDate).length
  const otherStatuses = Math.max(
    0,
    total - inProgress - proposals - underAnalysis - blocked - completed,
  )

  const operationalItems = normalized.filter(
    (item) => !['proposed', 'under_analysis'].includes(item.status) && item.progress !== null,
  )
  const averageOperationalProgress = operationalItems.length
    ? operationalItems.reduce((sum, item) => sum + (item.progress ?? 0), 0) / operationalItems.length
    : null
  const priorityDistribution = distribution(
    normalized,
    (item) => priorityLabel(item.priority),
    'Não informada',
  )
  const areaDistribution = distribution(
    normalized,
    (item) => item.responsibleArea,
    'Sem área responsável',
  ).slice(0, 6)
  const classDistribution = distribution(
    normalized,
    (item) => classLabel(item.initiativeClass),
    'Não informada',
  )

  const portfolioSegments = [
    { key: 'in_progress', label: 'Em execução', value: inProgress, color: 'var(--organization-secondary, #01877A)' },
    { key: 'proposals', label: 'Propostas', value: proposals, color: 'color-mix(in srgb, var(--organization-secondary, #01877A) 58%, white)' },
    { key: 'under_analysis', label: 'Em análise', value: underAnalysis, color: 'var(--sparks-warning, #c99500)' },
    { key: 'blocked', label: 'Bloqueadas', value: blocked, color: 'var(--sparks-danger, #b42318)' },
    { key: 'completed', label: 'Concluídas', value: completed, color: 'var(--sparks-text-muted, #78847e)' },
    { key: 'other', label: 'Outras situações', value: otherStatuses, color: '#b8c1bd' },
  ].filter((segment) => segment.value > 0)

  let portfolioCursor = 0
  const portfolioGradientStops = portfolioSegments.map((segment) => {
    const start = portfolioCursor
    const end = total > 0 ? start + (segment.value / total) * 100 : start
    portfolioCursor = end
    return `${segment.color} ${start.toFixed(2)}% ${end.toFixed(2)}%`
  })
  const portfolioGradient = total > 0 && portfolioGradientStops.length
    ? `conic-gradient(${portfolioGradientStops.join(', ')})`
    : 'conic-gradient(#dfe6e2 0% 100%)'

  const attentionTotal = drafts + critical + blocked + withoutDueDate
  const attentionMax = Math.max(drafts, critical, blocked, withoutDueDate, 1)
  const journeyActual = journeySnapshot?.actualProgress == null
    ? null
    : Math.max(0, Math.min(100, journeySnapshot.actualProgress))
  const journeyPlanned = journeySnapshot?.plannedProgress == null
    ? null
    : Math.max(0, Math.min(100, journeySnapshot.plannedProgress))
  const journeyVariance = journeySnapshot?.variancePoints ?? null
  const journeyVarianceAbs = journeyVariance == null ? null : Math.abs(journeyVariance)
  const journeyVarianceBand = journeyVarianceAbs == null
    ? 'unavailable'
    : journeyVarianceAbs <= deviationRanges.adequateMax
      ? 'adequate'
      : journeyVarianceAbs <= deviationRanges.attentionMax
        ? 'attention'
        : 'critical'
  const journeyVarianceTooltip = journeyVarianceAbs == null
    ? 'Desvio indisponível até existir leitura temporal suficiente.'
    : journeyVarianceBand === 'adequate'
      ? `Faixa adequada: desvio absoluto de ${journeyVarianceAbs.toFixed(0)}%, dentro do limite de ${deviationRanges.adequateMax}%.`
      : journeyVarianceBand === 'attention'
        ? `Faixa de atenção: desvio absoluto de ${journeyVarianceAbs.toFixed(0)}%, acima de ${deviationRanges.adequateMax}% e até ${deviationRanges.attentionMax}%.`
        : `Faixa crítica: desvio absoluto de ${journeyVarianceAbs.toFixed(0)}%, acima de ${deviationRanges.attentionMax}%.`
  const journeyPlanLabel = journeySnapshot?.planningStatus === 'approved'
    ? 'Planejado aprovado até hoje'
    : journeySnapshot?.planningStatus === 'proposed'
      ? 'Proposto até hoje'
      : 'Planejado até hoje'
  const macrophasesProgress = journeySnapshot?.totalItems
    ? Math.max(0, Math.min(100, (journeySnapshot.completedItems / journeySnapshot.totalItems) * 100))
    : 0
  const objectivesReadinessProgress = planReadiness.objectivesTotal
    ? Math.max(0, Math.min(100, ((planReadiness.objectivesReady ?? 0) / planReadiness.objectivesTotal) * 100))
    : 0
  const okrsReadinessProgress = planReadiness.okrsTotal
    ? Math.max(0, Math.min(100, ((planReadiness.okrsReady ?? 0) / planReadiness.okrsTotal) * 100))
    : 0

  const exportPortfolioCsv = () => {
    const header = ['Código', 'Iniciativa', 'Situação', 'Prioridade', 'Classe', 'Área responsável', 'Responsável', 'Criticidade', 'Progresso (%)', 'Início', 'Término-alvo']
    const lines = normalized.map((item) => [
      item.code,
      item.name,
      item.status,
      priorityLabel(item.priority),
      classLabel(item.initiativeClass),
      item.responsibleArea || 'Sem área responsável',
      item.responsibleName || '',
      item.criticality,
      item.progress ?? '',
      item.startDate,
      item.dueDate,
    ].map(csvCell).join(';'))
    const csv = `\uFEFF${header.map(csvCell).join(';')}\r\n${lines.join('\r\n')}`
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const anchor = document.createElement('a')
    const stamp = new Date().toISOString().slice(0, 10).replaceAll('-', '')
    anchor.href = url
    anchor.download = `SPARKs-PE-Portfolio-Executivo-${stamp}.csv`
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(url)
  }
  const exportExecutivePerformance = () => {
    const html = buildExecutivePerformanceReportHtml({
      organizationName,
      projectName,
      generatedAt: new Date(),
      journey: journeySnapshot,
      portfolio: {
        total,
        operationalUniverse: operationalItems.length,
        averageOperationalProgress,
        inProgress,
        underAnalysis,
        proposals,
        blocked,
        critical,
        withoutDueDate,
        attentionSignals: attentionTotal,
      },
      priorities: priorityDistribution,
      areas: areaDistribution,
      classes: classDistribution,
    })
    const blob = new Blob([html], { type: 'text/html;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const anchor = document.createElement('a')
    const stamp = new Date().toISOString().slice(0, 10).replaceAll('-', '')
    anchor.href = url
    anchor.download = `SPARKs-PE-Relatorio-Executivo-Desempenho-${stamp}.html`
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(url)
  }

  return (
    <section className="skpe-performance-cockpit" aria-label="Painel de Resultados e Desempenho">
      {surface === 'dashboard' ? (
        <div className="skpe-performance-dashboard-layout">
      <section className="skpe-performance-results-section">
        <header className="skpe-performance-panel-heading">
          <h2>Desenvolvimento do Plano Estratégico</h2>
          <p>
            Acompanhe o avanço da Jornada e a prontidão dos elementos necessários à execução da estratégia.
          </p>
        </header>

        <article
          className="skpe-performance-journey-comparison"
          title="Comparação operacional das macrofases da Jornada: progresso realizado versus avanço previsto pelas datas do plano institucional vigente."
        >
          <div className="skpe-performance-journey-comparison__heading">
            <div>
              <strong>Jornada frente ao planejado</strong>
              <span>Leitura atual das macrofases</span>
            </div>

          </div>
          <div className="skpe-performance-journey-bars">
            <div className="skpe-performance-journey-bar-row">
              <div><span>Realizado</span><strong>{journeyActual == null ? '—' : `${journeyActual.toFixed(0)}%`}</strong></div>
              <div className="skpe-performance-journey-track"><span style={{ width: journeyActual == null ? '0%' : `${journeyActual}%` }} /></div>
            </div>
            <div className="skpe-performance-journey-bar-row is-plan">
              <div><span>{journeyPlanLabel}</span><strong>{journeyPlanned == null ? '—' : `${journeyPlanned.toFixed(0)}%`}</strong></div>
              <div className="skpe-performance-journey-track"><span style={{ width: journeyPlanned == null ? '0%' : `${journeyPlanned}%` }} /></div>
            </div>
          </div>
          <div
            className={`skpe-performance-journey-variance is-${journeyVarianceBand}`}
            title={journeyVarianceTooltip}
            aria-label={`Desvio atual. ${journeyVarianceTooltip}`}
          >
            <span>Desvio atual</span>
            <strong className={journeyVariance == null ? '' : journeyVariance < 0 ? 'is-negative' : journeyVariance > 0 ? 'is-positive' : ''}>
              {journeyVariance == null ? '—' : `${journeyVariance >= 0 ? '+' : ''}${journeyVariance.toFixed(0)}%`}
            </strong>
          </div>
        </article>

        <div className="skpe-performance-results-grid">
          <article
            className="skpe-performance-result-card"
            title={journeySnapshot
              ? `${journeySnapshot.completedItems} de ${journeySnapshot.totalItems} macrofases concluídas. ${journeySnapshot.overdueItems} com desvio temporal.`
              : 'Situação das macrofases indisponível.'}
          >
            <div className="skpe-performance-result-card__heading">
              <span>Macrofases</span>
              <strong>
                {journeySnapshot ? `${journeySnapshot.completedItems} de ${journeySnapshot.totalItems}` : '—'}
              </strong>
              <small>{journeySnapshot ? `${journeySnapshot.overdueItems} com desvio temporal` : 'Situação indisponível'}</small>
            </div>
            <div className="skpe-performance-result-track">
              <span style={{ width: `${macrophasesProgress}%` }} />
            </div>
          </article>

          <article
            className="skpe-performance-result-card"
            title="Objetivo Estratégico pronto = validado ou aprovado, com pelo menos um indicador estratégico ativo e uma meta ativa associada."
          >
            <div className="skpe-performance-result-card__heading">
              <span>Objetivos Estratégicos</span>
              <strong>
                {planReadiness.objectivesTotal == null
                  ? '—'
                  : `${planReadiness.objectivesReady ?? 0} de ${planReadiness.objectivesTotal}`}
              </strong>
              <small>com indicadores e metas prontos</small>
            </div>
            <div className="skpe-performance-result-track">
              <span style={{ width: `${objectivesReadinessProgress}%` }} />
            </div>
          </article>

          <article
            className="skpe-performance-result-card"
            title="OKR pronto para execução = possui KRs cadastrados e todos os seus KRs possuem ao menos uma iniciativa do portfólio vinculada."
          >
            <div className="skpe-performance-result-card__heading">
              <span>OKRs</span>
              <strong>
                {planReadiness.okrsTotal == null
                  ? '—'
                  : `${planReadiness.okrsReady ?? 0} de ${planReadiness.okrsTotal}`}
              </strong>
              <small>com KRs cobertos por iniciativas</small>
            </div>
            <div className="skpe-performance-result-track">
              <span style={{ width: `${okrsReadinessProgress}%` }} />
            </div>
          </article>
        </div>

        <button
          type="button"
          className="skpe-performance-current-macrophase"
          onClick={onJourneyDrilldown}
          disabled={!onJourneyDrilldown}
        >
          <div className="skpe-performance-current-macrophase__heading">
            <div>
              <span>Macrofase atual em andamento</span>
              <strong>
                {journeySnapshot?.currentMacrophaseName ?? 'Macrofase em andamento não identificada'}
              </strong>

            </div>
            <span aria-hidden="true">›</span>
          </div>
          <div className="skpe-performance-current-macrophase__facts">
            <div>
              <span>Status</span>
              <strong>
                {journeySnapshot?.currentMacrophaseStatus === 'in_progress'
                  ? 'Em andamento'
                  : journeySnapshot?.currentMacrophaseStatus ?? '—'}
              </strong>
            </div>
            <div>
              <span>Data alvo</span>
              <strong>{journeySnapshot?.nextMilestoneTargetDate ? formatDashboardDate(journeySnapshot.nextMilestoneTargetDate) : '  /  /  '}</strong>
            </div>
          </div>
        </button>
      </section>

      <section className="skpe-performance-executive-column" aria-label="Execução estratégica e atenção à gestão">
        <header className="skpe-performance-panel-heading">
          <h2>Execução estratégica e atenção à gestão</h2>
          <p>Acompanhe o que está sendo executado e onde a gestão precisa agir.</p>
        </header>
        <div className="skpe-performance-export-row">
          <button type="button" className="skpe-performance-export-button" onClick={exportPortfolioCsv}>
            Exportar dados do portfólio (CSV)
          </button>
          <button type="button" className="skpe-performance-export-button" onClick={exportExecutivePerformance}>
            Exportar relatório executivo de desempenho
          </button>
        </div>

      {formulationId && projectId ? (
        <StrategicObjectiveExecutiveAnalytics
          organizationId={organizationId}
          projectId={projectId}
          formulationId={formulationId}
          onOpenMeasures={onObjectivePerformanceDrilldown}
          onOpenInitiatives={onObjectiveInitiativesDrilldown}
        />
      ) : null}
      <section className="skpe-performance-execution-section">
        <header className="skpe-performance-section-heading">
          <div>
            <h2>Monitoramento Executivo das Iniciativas</h2>
          </div>
          <p title="O avanço operacional das iniciativas é acompanhado separadamente do desempenho dos Objetivos Estratégicos; progresso de execução não é convertido automaticamente em resultado estratégico.">
            Execução corrente do portfólio de iniciativas.
          </p>
        </header>

        <div className="skpe-performance-summary-grid">
          <button type="button" className="skpe-performance-summary-card" onClick={() => onStatusDrilldown('all')}>
            <span>Portfólio visível</span><strong>{total}</strong><small>iniciativas no universo carregado</small>
          </button>
          <button type="button" className="skpe-performance-summary-card" onClick={() => onStatusDrilldown('in_progress')}>
            <span>Em execução</span><strong>{inProgress}</strong><small>iniciativas em execução corrente</small>
          </button>
          <article className="skpe-performance-summary-card">
            <span>Progresso médio operacional</span>
            <strong>{averageOperationalProgress == null ? '—' : `${averageOperationalProgress.toFixed(0)}%`}</strong>
            <small>{operationalItems.length} iniciativa(s) elegível(is); propostas e itens em análise não entram na média</small>
          </article>
          <button type="button" className="skpe-performance-summary-card is-attention" onClick={() => onStatusDrilldown('attention')}>
            <span>Sinais para gestão</span><strong>{attentionTotal}</strong><small>ocorrências; uma iniciativa pode gerar mais de um sinal</small>
          </button>
        </div>

        <div className="skpe-performance-portfolio-visual">
          <button
            type="button"
            className="skpe-performance-portfolio-donut"
            style={{ background: portfolioGradient }}
            onClick={() => onStatusDrilldown('all')}
            aria-label={`Portfólio: ${total} iniciativas visíveis`}
          >
            <span>
              <strong>{total}</strong>
              <small>iniciativas</small>
            </span>
          </button>

          <div className="skpe-performance-portfolio-legend" aria-label="Distribuição do portfólio por situação">
            {portfolioSegments.map((segment) => (
              <div key={segment.key}>
                <span className="skpe-performance-portfolio-dot" style={{ background: segment.color }} />
                <span>{segment.label}</span>
                <strong>
                  {segment.value}
                  {total > 0 ? ` (${Math.round((segment.value / total) * 100)}%)` : ''}
                </strong>
              </div>
            ))}
          </div>

          <button
            type="button"
            className="skpe-performance-attention-card"
            title="Soma dos sinais governados que exigem atenção da gestão."
            onClick={() => onStatusDrilldown('attention')}
          >
            <span>Atenção necessária</span>
            <strong>{attentionTotal}</strong>
            <small>sinais para gestão</small>
          </button>
        </div>
      </section>

      <section className="skpe-performance-attention-section">
        <header className="skpe-performance-section-heading">
          <div>
            <p className="skpe-performance-eyebrow">Gestão por exceção</p>
            <h2>Atenção da Gestão</h2>
          </div>
          <p title="A liderança organizacional é distinta da custódia provisória do consultor SPARKOOP.">
            Sinais que demandam ação ou decisão da gestão.
          </p>
        </header>
        <div className="skpe-performance-attention-bars">
          {[
            { label: 'Propostas para curadoria', value: drafts, filter: 'draft' as const, tone: 'primary' },
            { label: 'Iniciativas críticas', value: critical, filter: 'critical' as const, tone: 'warning' },
            { label: 'Bloqueadas', value: blocked, filter: 'blocked' as const, tone: 'danger' },
            { label: 'Sem término-alvo', value: withoutDueDate, filter: 'without_due_date' as const, tone: 'muted' },
          ].map((item) => (
            <button
              key={item.filter}
              type="button"
              className="skpe-performance-attention-bar"
              onClick={() => onStatusDrilldown(item.filter)}
            >
              <span>{item.label}</span>
              <span className="skpe-performance-attention-track">
                <span
                  className={`is-${item.tone}`}
                  style={{ width: `${(item.value / attentionMax) * 100}%` }}
                />
              </span>
              <strong>{item.value}</strong>
            </button>
          ))}
        </div>
      </section>

      <section className="skpe-performance-composition-section">
        <header className="skpe-performance-section-heading">
          <div><p className="skpe-performance-eyebrow">Composição do portfólio</p><h2>Onde a execução está concentrada</h2></div>
          <p>Distribuições calculadas somente com atributos existentes no portfólio governado. Ausência de classificação permanece explícita.</p>
        </header>
        <div className="skpe-performance-grid">
          <article className="skpe-performance-card">
            <header><h3>Por prioridade</h3><span>Quantidade de iniciativas por prioridade registrada.</span></header>
            <div className="skpe-performance-bars">
              {priorityDistribution.map((item) => (
                <div className="skpe-performance-bar-row" key={item.label}>
                  <div className="skpe-performance-bar-label"><span>{item.label}</span><strong>{item.value}</strong></div>
                  <div className="skpe-performance-bar-track"><span style={{ width: `${total ? (item.value / total) * 100 : 0}%` }} /></div>
                </div>
              ))}
            </div>
          </article>
          <article className="skpe-performance-card">
            <header><h3>Por área responsável</h3><span>Até seis áreas com maior concentração do portfólio.</span></header>
            <div className="skpe-performance-bars">
              {areaDistribution.map((item) => (
                <div className="skpe-performance-bar-row" key={item.label}>
                  <div className="skpe-performance-bar-label"><span>{item.label}</span><strong>{item.value}</strong></div>
                  <div className="skpe-performance-bar-track"><span style={{ width: `${total ? (item.value / total) * 100 : 0}%` }} /></div>
                </div>
              ))}
            </div>
          </article>
          <article className="skpe-performance-card">
            <header><h3>Por classe</h3><span>Programas, projetos, ações e demais classes do portfólio.</span></header>
            <div className="skpe-performance-bars">
              {classDistribution.map((item) => (
                <div className="skpe-performance-bar-row" key={item.label}>
                  <div className="skpe-performance-bar-label"><span>{item.label}</span><strong>{item.value}</strong></div>
                  <div className="skpe-performance-bar-track"><span style={{ width: `${total ? (item.value / total) * 100 : 0}%` }} /></div>
                </div>
              ))}
            </div>
          </article>
        </div>
      </section>
      </section>

        </div>
      ) : (
        <>
      <section className="skpe-performance-map-section">
        <header className="skpe-performance-section-heading">
          <div>
            <h2
              className="skpe-performance-map-title"
              tabIndex={0}
              data-tooltip="O farol de cada Objetivo Estratégico permanece cinza enquanto não houver sensibilização governada por execução, indicadores e resultados apurados."
            >
              Mapa Estratégico
            </h2>
          </div>
        </header>

        {formulationResolution === 'loading' ? (
          <div className="skpe-performance-map-state">Carregando Mapa Estratégico...</div>
        ) : formulationId ? (
          <StrategicBscMap
            formulationId={formulationId}
            canAdjustLayout={canAdjustStrategicMap}
            onObjectiveInitiativesDrilldown={onObjectiveInitiativesDrilldown}
          onObjectivePerformanceDrilldown={onObjectivePerformanceDrilldown}
          />
        ) : (
          <div className="skpe-performance-map-state">
            O Mapa Estratégico ainda não pôde ser associado de forma unívoca ao
            portfólio carregado. Nenhum status de Objetivo Estratégico foi inferido.
          </div>
        )}
      </section>

        </>
      )}
    </section>
  )
}
