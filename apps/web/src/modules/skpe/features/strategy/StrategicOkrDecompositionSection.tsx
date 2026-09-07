import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

import './StrategicOkrDecompositionSection.css'

type Props = {
  organizationId: string
  projectId: string
  formulationId: string | null
}

type StrategicObjectiveRow = {
  id: string
  code: string
  name: string
  perspective_code: string | null
  perspective_id: string | null
  perspective: {
    code: string
    name: string
    metadata: Record<string, unknown> | null
  }[] | null
}

type OkrRow = {
  id: string
  code: string
  title: string
  description: string | null
  status: string
  progress: number
  validation_status: string
  metadata: Record<string, unknown> | null
}

type OkrObjectiveLinkRow = {
  okr_id: string
  strategic_objective_id: string
  contribution_weight: number | null
  is_primary: boolean
}

type KeyResultRow = {
  id: string
  okr_id: string | null
  strategic_objective_id: string | null
  code: string
  name: string
  description: string | null
  baseline_value: number | null
  target_value: number | null
  current_value: number | null
  unit: string | null
  period_start: string | null
  period_end: string | null
  status: string
  progress: number
  validation_status: string
  metadata: Record<string, unknown> | null
}

type IndicatorRow = {
  id: string
  code: string
  name: string
  description: string | null
  strategic_objective_id: string | null
  key_result_id: string | null
  formula_text: string | null
  unit: string | null
  polarity: string | null
  measurement_frequency: string | null
  data_source: string | null
  baseline_value: number | null
  baseline_date: string | null
  status: string
}

type IndicatorTargetRow = {
  id: string
  indicator_id: string
  target_type: string
  period_start: string | null
  period_end: string | null
  target_value: number | null
  minimum_value: number | null
  challenge_value: number | null
  status: string
}

type IndicatorMeasurementRow = {
  id: string
  indicator_id: string
  measurement_date: string
  measured_value: number | null
  effective_performance: number | null
  status: string
  data_quality: string | null
}

type InitiativeRow = {
  id: string
  code: string
  name: string
  status: string
  progress: number
  health_status: string | null
}

type InitiativeObjectiveLinkRow = {
  initiative_id: string
  strategic_objective_id: string
  validation_status: string | null
}

type InitiativeKeyResultLinkRow = {
  initiative_id: string
  key_result_id: string
  validation_status: string | null
}

type LoadState = {
  objectives: StrategicObjectiveRow[]
  okrs: OkrRow[]
  okrObjectives: OkrObjectiveLinkRow[]
  keyResults: KeyResultRow[]
  indicators: IndicatorRow[]
  indicatorTargets: IndicatorTargetRow[]
  indicatorMeasurements: IndicatorMeasurementRow[]
  initiatives: InitiativeRow[]
  initiativeObjectives: InitiativeObjectiveLinkRow[]
  initiativeKeyResults: InitiativeKeyResultLinkRow[]
}

const emptyState: LoadState = {
  objectives: [],
  okrs: [],
  okrObjectives: [],
  keyResults: [],
  indicators: [],
  indicatorTargets: [],
  indicatorMeasurements: [],
  initiatives: [],
  initiativeObjectives: [],
  initiativeKeyResults: [],
}

function percent(value: number | null | undefined) {
  if (value === null || value === undefined || Number.isNaN(Number(value))) return '\u2014'
  return `${Math.round(Number(value))}%`
}

function numeric(value: number | null | undefined, unit: string | null | undefined) {
  if (value === null || value === undefined) return 'Não materializado'
  return `${value}${unit ? ` ${unit}` : ''}`
}

function statusLabel(value: string | null | undefined) {
  if (!value) return 'sem status'
  return value.replaceAll('_', ' ')
}

function metadataText(
  metadata: Record<string, unknown> | null | undefined,
  ...keys: string[]
) {
  for (const key of keys) {
    const value = metadata?.[key]
    if (typeof value === 'string' && value.trim()) return value.trim()
  }
  return null
}

function okrTypeLabel(metadata: Record<string, unknown> | null | undefined) {
  const value = metadataText(metadata, 'okrType', 'okr_type')
  if (value === 'committed' || value === 'comprometido') return 'Comprometido'
  if (value === 'aspirational' || value === 'aspiracional') return 'Aspiracional'
  return 'Classificação pendente'
}

function polarityLabel(metadata: Record<string, unknown> | null | undefined) {
  const value = metadataText(metadata, 'polarity')
  if (value === 'higher_is_better') return 'Quanto maior, melhor'
  if (value === 'lower_is_better') return 'Quanto menor, melhor'
  if (value === 'target_is_better') return 'Alvo específico'
  if (value === 'range_is_better') return 'Faixa desejada'
  return 'Não informada'
}

function keyResultQuality(kr: KeyResultRow) {
  const dataSource = metadataText(kr.metadata, 'dataSource')
  const frequency = metadataText(kr.metadata, 'measurementFrequency')
  const missing: string[] = []

  if (kr.baseline_value === null) missing.push('linha de base')
  if (kr.target_value === null) missing.push('meta')
  if (!kr.unit?.trim()) missing.push('unidade')
  if (!kr.period_end) missing.push('prazo')
  if (!dataSource) missing.push('fonte')
  if (!metadataText(kr.metadata, 'polarity')) missing.push('polaridade')

  return {
    ready: missing.length === 0,
    missing,
    dataSource,
    frequency,
  }
}

export function StrategicOkrDecompositionSection({
  organizationId,
  projectId,
  formulationId,
}: Props) {
  const [data, setData] = useState<LoadState>(emptyState)
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setLoading(true)
      setErrorMessage('')

      if (!formulationId) {
        if (active) {
          setData(emptyState)
          setLoading(false)
        }
        return
      }

      const scoped = { organizationId, projectId, formulationId }

      const [
        objectivesResponse,
        okrsResponse,
        okrObjectivesResponse,
        keyResultsResponse,
        indicatorsResponse,
        targetsResponse,
        measurementsResponse,
        initiativesResponse,
        initiativeObjectivesResponse,
        initiativeKeyResultsResponse,
      ] = await Promise.all([
        supabase
          .from('skpe_strategic_objectives')
          .select('id, code, name, perspective_code, perspective_id, perspective:skpe_bsc_perspectives!skpe_strategic_objectives_perspective_id_fkey(code, name, metadata)')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .eq('formulation_id', scoped.formulationId)
          .order('code'),
        supabase
          .from('skpe_okrs')
          .select('id, code, title, description, status, progress, validation_status, metadata')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .eq('formulation_id', scoped.formulationId)
          .order('display_order'),
        supabase
          .from('skpe_okr_objectives')
          .select('okr_id, strategic_objective_id, contribution_weight, is_primary')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .eq('formulation_id', scoped.formulationId),
        supabase
          .from('skpe_key_results')
          .select('id, okr_id, strategic_objective_id, code, name, description, baseline_value, target_value, current_value, unit, period_start, period_end, status, progress, validation_status, metadata')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .eq('formulation_id', scoped.formulationId)
          .order('code'),
        supabase
          .from('skpe_indicators')
          .select('id, code, name, description, strategic_objective_id, key_result_id, formula_text, unit, polarity, measurement_frequency, data_source, baseline_value, baseline_date, status')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .eq('formulation_id', scoped.formulationId)
          .order('code'),
        supabase
          .from('skpe_indicator_targets')
          .select('id, indicator_id, target_type, period_start, period_end, target_value, minimum_value, challenge_value, status')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .eq('formulation_id', scoped.formulationId),
        supabase
          .from('skpe_indicator_measurements')
          .select('id, indicator_id, measurement_date, measured_value, effective_performance, status, data_quality')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .eq('formulation_id', scoped.formulationId)
          .order('measurement_date', { ascending: false }),
        supabase
          .from('skpe_initiatives')
          .select('id, code, name, status, progress, health_status')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .is('archived_at', null)
          .order('code'),
        supabase
          .from('skpe_initiative_objectives')
          .select('initiative_id, strategic_objective_id, validation_status')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .eq('formulation_id', scoped.formulationId),
        supabase
          .from('skpe_initiative_key_results')
          .select('initiative_id, key_result_id, validation_status')
          .eq('organization_id', scoped.organizationId)
          .eq('project_id', scoped.projectId)
          .eq('formulation_id', scoped.formulationId),
      ])

      const responses = [
        objectivesResponse,
        okrsResponse,
        okrObjectivesResponse,
        keyResultsResponse,
        indicatorsResponse,
        targetsResponse,
        measurementsResponse,
        initiativesResponse,
        initiativeObjectivesResponse,
        initiativeKeyResultsResponse,
      ]
      const firstError = responses.find((response) => response.error)?.error

      if (!active) return

      if (firstError) {
        setData(emptyState)
        setErrorMessage(`Não foi possível carregar o desdobramento em OKRs: ${firstError.message}`)
        setLoading(false)
        return
      }

      setData({
        objectives: (objectivesResponse.data ?? []) as StrategicObjectiveRow[],
        okrs: (okrsResponse.data ?? []) as OkrRow[],
        okrObjectives: (okrObjectivesResponse.data ?? []) as OkrObjectiveLinkRow[],
        keyResults: (keyResultsResponse.data ?? []) as KeyResultRow[],
        indicators: (indicatorsResponse.data ?? []) as IndicatorRow[],
        indicatorTargets: (targetsResponse.data ?? []) as IndicatorTargetRow[],
        indicatorMeasurements: (measurementsResponse.data ?? []) as IndicatorMeasurementRow[],
        initiatives: (initiativesResponse.data ?? []) as InitiativeRow[],
        initiativeObjectives: (initiativeObjectivesResponse.data ?? []) as InitiativeObjectiveLinkRow[],
        initiativeKeyResults: (initiativeKeyResultsResponse.data ?? []) as InitiativeKeyResultLinkRow[],
      })
      setLoading(false)
    }

    void load()

    return () => {
      active = false
    }
  }, [formulationId, organizationId, projectId])

  const objectiveSections = useMemo(() => {
    const objectiveById = new Map(data.objectives.map((objective) => [objective.id, objective]))
    const initiativeById = new Map(data.initiatives.map((initiative) => [initiative.id, initiative]))

    return data.objectives.map((objective) => {
      const okrLinks = data.okrObjectives.filter(
        (link) => link.strategic_objective_id === objective.id,
      )
      const linkedOkrIds = new Set(okrLinks.map((link) => link.okr_id))
      const okrs = data.okrs.filter((okr) => linkedOkrIds.has(okr.id))
      const directIndicators = data.indicators.filter(
        (indicator) =>
          indicator.strategic_objective_id === objective.id && !indicator.key_result_id,
      )
      const objectiveInitiativeIds = new Set(
        data.initiativeObjectives
          .filter((link) => link.strategic_objective_id === objective.id)
          .map((link) => link.initiative_id),
      )
      const objectiveInitiatives = Array.from(objectiveInitiativeIds)
        .map((id) => initiativeById.get(id))
        .filter((item): item is InitiativeRow => Boolean(item))

      return {
        objective: objectiveById.get(objective.id)!,
        okrs,
        okrLinks,
        directIndicators,
        objectiveInitiatives,
      }
    })
  }, [data])

  const unlinkedOkrs = useMemo(() => {
    const linkedOkrIds = new Set(data.okrObjectives.map((link) => link.okr_id))
    return data.okrs.filter((okr) => !linkedOkrIds.has(okr.id))
  }, [data.okrObjectives, data.okrs])

  if (loading) {
    return (
      <section className="skpe-okr-decomposition skpe-okr-decomposition-state">
        <h3>Desdobramento em OKRs</h3>
          <p>{'Carregando a cadeia OE \u2192 OKR \u2192 KR \u2192 indicador \u2192 iniciativa \u2192 monitoramento.'}</p>
      </section>
    )
  }

  if (errorMessage) {
    return (
      <section className="skpe-okr-decomposition skpe-okr-decomposition-state is-error">
        <h3>Desdobramento em OKRs</h3>
        <p>{errorMessage}</p>
      </section>
    )
  }

  return (
    <section className="skpe-okr-decomposition">
      <header className="skpe-okr-decomposition-header">
        <div>
          <small>Fase 5 · Desdobramento mensurável</small>
          <h3>Objetivos Estratégicos, OKRs e evidências de execução</h3>
        </div>
        <p>
          Esta visão apresenta somente vínculos e valores já materializados. Linha de base,
          meta ou desempenho ausentes permanecem explícitos, sem inferência automática.
        </p>
      </header>

      <div className="skpe-okr-methodology-guide" role="note" aria-label="Disciplina metodológica de OKRs">
        <strong>Como ler o desdobramento</strong>
        <div>
          <span><b>Perspectiva</b> organiza a lógica causal do BSC.</span>
          <span><b>OE</b> expressa a transformação estratégica de horizonte mais longo.</span>
          <span><b>Objetivo do OKR</b> define o avanço qualitativo do ciclo, sem números.</span>
          <span><b>KR</b> comprova a mudança com linha de base, meta, unidade, prazo e fonte.</span>
          <span><b>Iniciativa</b> é o que fazemos para mover os KRs; não substitui resultado.</span>
        </div>
      </div>

      <div className="skpe-okr-decomposition-summary">
        <article><span>OEs</span><strong>{data.objectives.length}</strong></article>
        <article><span>OKRs</span><strong>{data.okrs.length}</strong></article>
        <article><span>KRs</span><strong>{data.keyResults.length}</strong></article>
        <article><span>Indicadores</span><strong>{data.indicators.length}</strong></article>
        <article><span>Metas</span><strong>{data.indicatorTargets.length}</strong></article>
        <article><span>Medições</span><strong>{data.indicatorMeasurements.length}</strong></article>
      </div>

      <div className="skpe-okr-decomposition-list">
        {objectiveSections.map(({ objective, okrs, okrLinks, directIndicators, objectiveInitiatives }) => (
          <article key={objective.id} className="skpe-okr-objective-card">
            <header className="skpe-okr-objective-header">
              <div>
                <small>{objective.code}</small>
                <h4>{objective.name}</h4>
                <span className="skpe-okr-perspective">
                  Perspectiva: {objective.perspective?.[0]?.name ?? objective.perspective_code ?? 'Não associada'}
                </span>
              </div>
              <span>{okrs.length} OKR(s)</span>
            </header>

            {okrs.length === 0 ? (
              <div className="skpe-okr-empty">
                <strong>OKR ainda não materializado para este OE.</strong>
                <p>O vínculo estratégico permanece como lacuna explícita de desdobramento.</p>
              </div>
            ) : (
              <div className="skpe-okr-stack">
                {okrs.map((okr) => {
                  const link = okrLinks.find((item) => item.okr_id === okr.id)
                  const keyResults = data.keyResults.filter((kr) => kr.okr_id === okr.id)
                  const initiativeIds = new Set<string>()

                  for (const kr of keyResults) {
                    for (const relation of data.initiativeKeyResults) {
                      if (relation.key_result_id === kr.id) initiativeIds.add(relation.initiative_id)
                    }
                  }

                  const linkedInitiatives = data.initiatives.filter((initiative) =>
                    initiativeIds.has(initiative.id),
                  )

                  return (
                    <section key={okr.id} className="skpe-okr-card">
                      <header className="skpe-okr-card-header">
                        <div>
                          <small>{okr.code}</small>
                          <strong>{okr.title}</strong>
                          {okr.description ? <p>{okr.description}</p> : null}
                        </div>
                        <div className="skpe-okr-status-stack">
                          <span className="skpe-okr-chip">{statusLabel(okr.validation_status)}</span>
                          <span className="skpe-okr-chip is-methodology">{okrTypeLabel(okr.metadata)}</span>
                          <span>{percent(okr.progress)}</span>
                        </div>
                      </header>

                      <div className="skpe-okr-link-note">
                        <span>{link?.is_primary ? 'OE primário' : 'OE relacionado'}</span>
                        <span>
                          Peso: {link?.contribution_weight === null || link?.contribution_weight === undefined
                            ? 'não definido'
                            : `${link.contribution_weight}%`}
                        </span>
                      </div>

                      <div className="skpe-okr-kr-list">
                        {keyResults.length === 0 ? (
                          <div className="skpe-okr-empty compact">
                            <strong>Nenhum Resultado-Chave vinculado.</strong>
                          </div>
                        ) : (
                          keyResults.map((kr) => {
                            const indicators = data.indicators.filter(
                              (indicator) => indicator.key_result_id === kr.id,
                            )

                            const quality = keyResultQuality(kr)

                            return (
                              <article key={kr.id} className="skpe-okr-kr-card">
                                <header>
                                  <div>
                                    <small>{kr.code}</small>
                                    <strong>{kr.name}</strong>
                                  </div>
                                  <span>{percent(kr.progress)}</span>
                                </header>

                                {kr.description ? <p>{kr.description}</p> : null}

                                <div className="skpe-okr-kr-quality">
                                  <span className={quality.ready ? 'is-ready' : 'is-pre-kr'}>
                                    {quality.ready ? 'KR metodologicamente completo' : 'Pré-KR: ainda não validável'}
                                  </span>
                                  {!quality.ready ? (
                                    <small>Faltam: {quality.missing.join(', ')}.</small>
                                  ) : null}
                                </div>

                                <div className="skpe-okr-values">
                                  <span><b>Linha de base</b>{numeric(kr.baseline_value, kr.unit)}</span>
                                  <span><b>Meta</b>{numeric(kr.target_value, kr.unit)}</span>
                                  <span><b>Atual</b>{numeric(kr.current_value, kr.unit)}</span>
                                  <span><b>Unidade</b>{kr.unit ?? 'Não informada'}</span>
                                  <span><b>Prazo</b>{kr.period_end ?? 'Não informado'}</span>
                                  <span><b>Fonte</b>{quality.dataSource ?? 'Não informada'}</span>
                                  <span><b>Frequência</b>{quality.frequency ?? 'Não informada'}</span>
                                  <span><b>Polaridade</b>{polarityLabel(kr.metadata)}</span>
                                  <span><b>Validação</b>{statusLabel(kr.validation_status)}</span>
                                </div>

                                <div className="skpe-okr-indicator-list">
                                  {indicators.length === 0 ? (
                                    <p className="skpe-okr-muted">Indicador ainda não materializado para este KR.</p>
                                  ) : (
                                    indicators.map((indicator) => {
                                      const targets = data.indicatorTargets.filter(
                                        (target) => target.indicator_id === indicator.id,
                                      )
                                      const latestMeasurement = data.indicatorMeasurements.find(
                                        (measurement) => measurement.indicator_id === indicator.id,
                                      )

                                      return (
                                        <article key={indicator.id} className="skpe-okr-indicator-card">
                                          <header>
                                            <div>
                                              <small>{indicator.code}</small>
                                              <strong>{indicator.name}</strong>
                                            </div>
                                            <span>{statusLabel(indicator.status)}</span>
                                          </header>
                                          <div className="skpe-okr-indicator-meta">
                                            <span><b>Fórmula</b>{indicator.formula_text ?? 'Não materializada'}</span>
                                            <span><b>Fonte</b>{indicator.data_source ?? 'Não materializada'}</span>
                                            <span><b>Frequência</b>{indicator.measurement_frequency ?? 'Não materializada'}</span>
                                            <span><b>Baseline</b>{numeric(indicator.baseline_value, indicator.unit)}</span>
                                          </div>
                                          <div className="skpe-okr-monitoring-strip">
                                            <span>Metas: <b>{targets.length}</b></span>
                                            <span>
                                              Última medição:{' '}
                                              <b>{latestMeasurement?.measured_value ?? 'não materializada'}</b>
                                            </span>
                                            <span>
                                              Qualidade:{' '}
                                              <b>{latestMeasurement?.data_quality ?? 'não informada'}</b>
                                            </span>
                                          </div>
                                        </article>
                                      )
                                    })
                                  )}
                                </div>
                              </article>
                            )
                          })
                        )}
                      </div>

                      <div className="skpe-okr-initiative-strip">
                        <strong>Iniciativas vinculadas aos KRs</strong>
                        {linkedInitiatives.length === 0 ? (
                          <span>Nenhuma iniciativa vinculada aos KRs deste OKR.</span>
                        ) : (
                          linkedInitiatives.map((initiative) => (
                            <span key={initiative.id}>
                              {initiative.code} · {initiative.name} · {percent(initiative.progress)}
                            </span>
                          ))
                        )}
                      </div>
                    </section>
                  )
                })}
              </div>
            )}

            {directIndicators.length > 0 || objectiveInitiatives.length > 0 ? (
              <footer className="skpe-okr-objective-footer">
                {directIndicators.length > 0 ? (
                  <span>{directIndicators.length} indicador(es) diretamente vinculado(s) ao OE</span>
                ) : null}
                {objectiveInitiatives.length > 0 ? (
                  <span>{objectiveInitiatives.length} iniciativa(s) diretamente vinculada(s) ao OE</span>
                ) : null}
              </footer>
            ) : null}
          </article>
        ))}
      </div>

      {unlinkedOkrs.length > 0 ? (
        <article className="skpe-okr-unlinked">
          <h4>OKRs sem vínculo explícito com Objetivo Estratégico</h4>
          {unlinkedOkrs.map((okr) => (
            <p key={okr.id}><strong>{okr.code}</strong> · {okr.title}</p>
          ))}
        </article>
      ) : null}

      <article className="skpe-okr-method-note">
        <strong>Critério de leitura</strong>
        <p>
          Ausência de linha de base, meta, indicador, iniciativa ou medição não é preenchida
          automaticamente. O sistema evidencia a lacuna para posterior validação e materialização.
        </p>
      </article>
    </section>
  )
}