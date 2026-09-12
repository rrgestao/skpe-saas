import { useEffect, useMemo, useState } from 'react'
import { MeasuresCatalogSmartGrid } from './MeasuresCatalogSmartGrid'
import { SparksSummaryCards } from '../../components/design-system/SparksSummaryCards'
import { SparksMeasureDualSelector } from './SparksMeasureDualSelector'
import { OrganizationIndicatorsSmartGrid } from './OrganizationIndicatorsSmartGrid'
import { supabase } from '../../lib/supabase'

import './MeasuresPerformanceWorkspace.css'

type MeasuresPerformanceWorkspaceMode = 'context' | 'administration'

type MeasuresPerformanceWorkspaceProps = {
  organizationId: string
  projectId?: string | null
  sourceModuleCode: string
  subjectType?: string | null
  subjectId?: string | null
  subjectLabel?: string | null
  mode?: MeasuresPerformanceWorkspaceMode
  onBack?: () => void
}

type MeasureContextRow = {
  indicator_id: string
  source_context_id: string | null
  code: string | null
  name: string | null
  description: string | null
  unit: string | null
  polarity: string | null
  measurement_frequency: string | null
  indicator_status: string | null
  target_id: string | null
  target_value: number | null
  minimum_value: number | null
  challenge_value: number | null
  measured_value: number | null
  effective_performance: number | null
  measurement_state: string | null
  benchmark_id: string | null
  benchmark_value: number | null
  benchmark_source_name: string | null
  evidence_reference: string | null
  owner_user_id?: string | null
  owner_name?: string | null
  key_result_id?: string | null
  key_result_code?: string | null
  key_result_name?: string | null
  updated_at: string | null
}

type IndicatorLinkRow = {
  id: string
  owner_user_id: string | null
  key_result_id: string | null
}

type WorkScopePersonRow = {
  user_id: string
  display_name: string | null
  email: string | null
}

type KeyResultLookupRow = {
  key_result_id: string
  code: string | null
  name: string | null
}

type MonitoringParameters = {
  formulation_id: string
  monitoring_package_id: string | null
  package_status: string | null
  critical_threshold: number
  attention_threshold: number
  on_track_threshold: number
  parameter_source: 'application_default' | 'organization_package' | string
}
type ReferenceCatalogRow = {
  reference_catalog_id: string
  catalog_code: string
  version_number: number
  name: string
  description: string | null
  purpose: string | null
  formula_text: string | null
  unit: string | null
  polarity: string | null
  measurement_frequency: string | null
  indicator_category: string | null
  applicability: unknown
  excellence_criteria: unknown
  reference_sources: unknown
  status: string | null
  is_current: boolean
  benchmarks: unknown
  updated_at: string | null
}

type FormulationOption = {
  id: string
  project_id: string
  version_number: number
  status: string
}

type ObjectiveOption = {
  id: string
  code: string
  title: string
  status: string
}

type AdoptionForm = {
  referenceCatalogId: string
  formulationId: string
  objectiveId: string
  code: string
  name: string
  description: string
  unit: string
  measurementFrequency: string
  adaptationNotes: string
  reason: string
}

const emptyAdoptionForm: AdoptionForm = {
  referenceCatalogId: '',
  formulationId: '',
  objectiveId: '',
  code: '',
  name: '',
  description: '',
  unit: '',
  measurementFrequency: '',
  adaptationNotes: '',
  reason: '',
}

function normalizeRows<T>(value: unknown): T[] {
  return Array.isArray(value) ? (value as T[]) : []
}

export function MeasuresPerformanceWorkspace({
  organizationId,
  projectId = null,
  sourceModuleCode,
  subjectType = null,
  subjectId = null,
  subjectLabel = null,
  mode = 'context',
  onBack,
}: MeasuresPerformanceWorkspaceProps) {
  const [rows, setRows] = useState<MeasureContextRow[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')
  const [monitoringParameters, setMonitoringParameters] =
    useState<MonitoringParameters | null>(null)
  const [monitoringParametersError, setMonitoringParametersError] = useState('')

  const [catalog, setCatalog] = useState<ReferenceCatalogRow[]>([])
  const [catalogLoading, setCatalogLoading] = useState(false)
  const [catalogError, setCatalogError] = useState('')
  const [formulations, setFormulations] = useState<FormulationOption[]>([])
  const [objectives, setObjectives] = useState<ObjectiveOption[]>([])
  const [adoptionForm, setAdoptionForm] =
    useState<AdoptionForm>(emptyAdoptionForm)
  const [adoptionMessage, setAdoptionMessage] = useState('')
  const [adopting, setAdopting] = useState(false)
  const [adoptionPanelOpen, setAdoptionPanelOpen] = useState(false)
  const [summaryFilter, setSummaryFilter] = useState<'all' | 'withTarget' | 'assessed' | 'withBenchmark'>('all')

  const selectedReference = useMemo(
    () =>
      catalog.find(
        (item) =>
          item.reference_catalog_id === adoptionForm.referenceCatalogId,
      ) ?? null,
    [adoptionForm.referenceCatalogId, catalog],
  )

  const loadMeasures = async () => {
    setLoading(true)
    setErrorMessage('')

    const response = await supabase.rpc(
      'get_sparks_measure_performance_context',
      {
        target_organization_id: organizationId,
        target_source_module_code: sourceModuleCode,
        target_source_project_id: projectId,
        target_source_context_id: null,
        target_subject_type: subjectType,
        target_subject_id: subjectId,
      },
    )

    if (response.error) {
      setRows([])
      setErrorMessage(response.error.message)
      setLoading(false)
      return
    }

    const baseRows = normalizeRows<MeasureContextRow>(response.data)
    const formulationId =
      baseRows.find((row) => row.source_context_id)?.source_context_id ?? null

    await loadMonitoringParameters(formulationId)
    const indicatorIds = Array.from(
      new Set(baseRows.map((row) => row.indicator_id).filter(Boolean)),
    )

    if (indicatorIds.length === 0) {
      setRows(baseRows)
      setLoading(false)
      return
    }

    const [indicatorLinksResponse, peopleResponse, keyResultsResponse] =
      await Promise.all([
        supabase
          .from('skpe_indicators')
          .select('id, owner_user_id, key_result_id')
          .in('id', indicatorIds),
        supabase.rpc('get_my_skpe_work_scope_people' as never, {
          target_organization_id: organizationId,
        } as never),
        supabase.rpc('get_my_skpe_key_results' as never, {
          target_organization_id: organizationId,
          target_project_id: projectId,
          target_formulation_id: null,
        } as never),
      ])

    const indicatorLinks = indicatorLinksResponse.error
      ? []
      : normalizeRows<IndicatorLinkRow>(indicatorLinksResponse.data)

    const people = peopleResponse.error
      ? []
      : normalizeRows<WorkScopePersonRow>(peopleResponse.data)

    const keyResults = keyResultsResponse.error
      ? []
      : normalizeRows<KeyResultLookupRow>(keyResultsResponse.data)

    const linksByIndicator = new Map(
      indicatorLinks.map((item) => [item.id, item]),
    )
    const peopleByUser = new Map(
      people.map((person) => [person.user_id, person]),
    )
    const keyResultsById = new Map(
      keyResults.map((keyResult) => [keyResult.key_result_id, keyResult]),
    )

    const enrichedRows = baseRows.map((row) => {
      const link = linksByIndicator.get(row.indicator_id)
      const owner = link?.owner_user_id
        ? peopleByUser.get(link.owner_user_id)
        : null
      const keyResult = link?.key_result_id
        ? keyResultsById.get(link.key_result_id)
        : null

      return {
        ...row,
        owner_user_id: link?.owner_user_id ?? null,
        owner_name:
          owner?.display_name?.trim() ||
          owner?.email?.trim() ||
          null,
        key_result_id: link?.key_result_id ?? null,
        key_result_code: keyResult?.code ?? null,
        key_result_name: keyResult?.name ?? null,
      }
    })

    setRows(enrichedRows)
    setLoading(false)
  }

  const loadMonitoringParameters = async (formulationId: string | null) => {
    if (!formulationId) {
      setMonitoringParameters(null)
      setMonitoringParametersError('')
      return
    }

    setMonitoringParametersError('')

    const response = await supabase.rpc(
      'get_sparks_measure_monitoring_parameters' as never,
      {
        target_organization_id: organizationId,
        target_formulation_id: formulationId,
      } as never,
    )

    if (response.error) {
      setMonitoringParameters(null)
      setMonitoringParametersError(response.error.message)
      return
    }

    const parameterRows = normalizeRows<MonitoringParameters>(response.data)
    setMonitoringParameters(parameterRows[0] ?? null)
  }
  const loadCatalog = async () => {
    if (mode !== 'administration') return

    setCatalogLoading(true)
    setCatalogError('')

    const response = await supabase.rpc(
      'get_sparks_measure_reference_catalog' as never,
      {
        target_organization_id: organizationId,
        target_source_module_code: sourceModuleCode,
      } as never,
    )

    if (response.error) {
      setCatalog([])
      setCatalogError(response.error.message)
      setCatalogLoading(false)
      return
    }

    setCatalog(normalizeRows<ReferenceCatalogRow>(response.data))
    setCatalogLoading(false)
  }

  const loadFormulations = async () => {
    if (mode !== 'administration') return

    const { data, error } = await supabase
      .from('skpe_strategic_formulations')
      .select('id, project_id, version_number, status')
      .eq('organization_id', organizationId)
      .in('status', ['draft', 'under_review', 'approved'])
      .order('version_number', { ascending: false })

    if (error) {
      setFormulations([])
      return
    }

    const options = normalizeRows<FormulationOption>(data)
    setFormulations(options)

    setAdoptionForm((current) => ({
      ...current,
      formulationId:
        current.formulationId || options[0]?.id || '',
    }))
  }

  const loadObjectives = async (formulationId: string) => {
    if (!formulationId) {
      setObjectives([])
      return
    }

    const { data, error } = await supabase
      .from('skpe_strategic_objectives')
      .select('id, code, title, status')
      .eq('organization_id', organizationId)
      .eq('formulation_id', formulationId)
      .eq('status', 'active')
      .order('code')

    if (error) {
      setObjectives([])
      return
    }

    const options = normalizeRows<ObjectiveOption>(data)
    setObjectives(options)

    setAdoptionForm((current) => ({
      ...current,
      objectiveId:
        options.some((option) => option.id === current.objectiveId)
          ? current.objectiveId
          : options[0]?.id || '',
    }))
  }

  useEffect(() => {
    void loadMeasures()
  }, [
    organizationId,
    projectId,
    sourceModuleCode,
    subjectType,
    subjectId,
  ])

  useEffect(() => {
    if (mode !== 'administration') return
    void Promise.all([loadCatalog(), loadFormulations()])
  }, [mode, organizationId, sourceModuleCode])

  useEffect(() => {
    if (mode !== 'administration') return
    void loadObjectives(adoptionForm.formulationId)
  }, [mode, adoptionForm.formulationId])

  useEffect(() => {
    if (!selectedReference) return

    setAdoptionForm((current) => ({
      ...current,
      code: selectedReference.catalog_code,
      name: selectedReference.name,
      description: selectedReference.description ?? '',
      unit: selectedReference.unit ?? '',
      measurementFrequency:
        selectedReference.measurement_frequency ?? '',
    }))
  }, [selectedReference])

  const uniqueRows = useMemo<MeasureContextRow[]>(() => {
    const byIndicator = new Map<string, MeasureContextRow>()

    for (const row of rows) {
      const current = byIndicator.get(row.indicator_id)

      if (!current) {
        byIndicator.set(row.indicator_id, row)
        continue
      }

      const currentTimestamp = current.updated_at
        ? Date.parse(current.updated_at)
        : Number.NEGATIVE_INFINITY
      const candidateTimestamp = row.updated_at
        ? Date.parse(row.updated_at)
        : Number.NEGATIVE_INFINITY

      if (candidateTimestamp >= currentTimestamp) {
        byIndicator.set(row.indicator_id, row)
      }
    }

    return Array.from(byIndicator.values())
  }, [rows])

  const summary = useMemo(() => {
    const withTarget = uniqueRows.filter((row) => row.target_id).length
    const assessed = uniqueRows.filter(
      (row) =>
        row.measurement_state &&
        row.measurement_state !== 'not_assessed',
    ).length
    const withBenchmark = uniqueRows.filter((row) => row.benchmark_id).length

    return {
      indicators: uniqueRows.length,
      withTarget,
      assessed,
      withBenchmark,
    }
  }, [uniqueRows])

  const summaryFilteredRows = useMemo(() => {
    if (summaryFilter === 'withTarget') {
      return uniqueRows.filter((row) => Boolean(row.target_id))
    }

    if (summaryFilter === 'assessed') {
      return uniqueRows.filter(
        (row) =>
          Boolean(row.measurement_state) &&
          row.measurement_state !== 'not_assessed',
      )
    }

    if (summaryFilter === 'withBenchmark') {
      return uniqueRows.filter((row) => Boolean(row.benchmark_id))
    }

    return uniqueRows
  }, [uniqueRows, summaryFilter])

  const adoptReference = async () => {
    if (
      !adoptionForm.referenceCatalogId ||
      !adoptionForm.formulationId ||
      !adoptionForm.objectiveId
    ) {
      setAdoptionMessage(
        'Selecione a referência, a Formulação Estratégica e o Objetivo Estratégico.',
      )
      return
    }

    if (!adoptionForm.reason.trim()) {
      setAdoptionMessage(
        'Informe a justificativa para auditoria antes de adotar a referência.',
      )
      return
    }

    setAdopting(true)
    setAdoptionMessage('')

    const response = await supabase.rpc(
      'adopt_sparks_measure_reference_indicator' as never,
      {
        target_organization_id: organizationId,
        target_source_module_code: sourceModuleCode,
        target_source_context_id: adoptionForm.formulationId,
        target_subject_type: 'strategic_objective',
        target_subject_id: adoptionForm.objectiveId,
        target_reference_catalog_id:
          adoptionForm.referenceCatalogId,
        target_code: adoptionForm.code.trim() || null,
        target_name: adoptionForm.name.trim() || null,
        target_description:
          adoptionForm.description.trim() || null,
        target_formula_text: null,
        target_unit: adoptionForm.unit.trim() || null,
        target_polarity: null,
        target_measurement_frequency:
          adoptionForm.measurementFrequency || null,
        target_data_source: null,
        target_owner_user_id: null,
        target_status: 'draft',
        target_reference_adaptation_notes:
          adoptionForm.adaptationNotes.trim() || null,
        target_metadata: {
          adoptedFromOrganizationAdministration: true,
        },
        target_change_reason: adoptionForm.reason.trim(),
      } as never,
    )

    if (response.error) {
      setAdoptionMessage(response.error.message)
      setAdopting(false)
      return
    }

    setAdoptionMessage(
      'Referência adotada como indicador da organização em situação Rascunho.',
    )
    setAdoptionForm((current) => ({
      ...current,
      referenceCatalogId: '',
      code: '',
      name: '',
      description: '',
      unit: '',
      measurementFrequency: '',
      adaptationNotes: '',
      reason: '',
    }))

    await Promise.all([loadMeasures(), loadCatalog()])
    setAdopting(false)
  }

  if (String(mode) === 'administration') {
    return <SparksMeasureDualSelector organizationId={organizationId} />
  }
  return (
    <section
      className="sparks-measures-workspace"
      aria-label="Medidas e Desempenho"
    >
      <header className="sparks-measures-workspace__header">
        <div>
          <span className="sparks-measures-workspace__eyebrow">
            Medidas, metas, benchmarks e apurações
          </span>
          <h2>Medidas e Desempenho</h2>
          <p>
            {mode === 'administration'
              ? 'Administre como a organização adota referências gerais e contextualiza suas próprias medidas sem duplicar a fonte transversal.'
              : 'Consulte o desempenho governado no contexto estratégico selecionado.'}
          </p>
        </div>

        {mode === 'context' && onBack ? (
          <button
            type="button"
            className="sparks-measures-workspace__back"
            onClick={onBack}
          >
            Voltar ao Mapa Estratégico
          </button>
        ) : null}
      </header>

      {subjectLabel ? (
        <div className="sparks-measures-workspace__context">
          <span>Objetivo Estratégico</span>
          <strong>{subjectLabel}</strong>
        </div>
      ) : null}

      <SparksSummaryCards
        ariaLabel="Filtros rápidos dos indicadores"
        items={[
          { id: 'all', label: 'Indicadores', value: summary.indicators },
          { id: 'withTarget', label: 'Com meta', value: summary.withTarget },
          { id: 'assessed', label: 'Apurados', value: summary.assessed },
          { id: 'withBenchmark', label: 'Com benchmark', value: summary.withBenchmark },
        ]}
        selectedId={summaryFilter}
        onSelect={(id) => {
          if (
            id === 'all' ||
            id === 'withTarget' ||
            id === 'assessed' ||
            id === 'withBenchmark'
          ) {
            setSummaryFilter(id)
          }
        }}
      />

      <div className="sparks-measures-workspace__section-heading">
        <div>
          <h3>
            {mode === 'administration'
              ? 'Indicadores da organização'
              : 'Medidas do contexto'}
          </h3>
          <p>
            Ausência de apuração permanece distinta de valor zero.
          </p>
        </div>
      </div>

      {monitoringParametersError ? (
        <div className="sparks-measures-workspace__state is-error">
          Não foi possível carregar os parâmetros do farol: {monitoringParametersError}
        </div>
      ) : null}
      {errorMessage ? (
        <div className="sparks-measures-workspace__state is-error">
          {errorMessage}
        </div>
      ) : loading ? (
        <div className="sparks-measures-workspace__state">
          Carregando medidas...
        </div>
      ) : rows.length === 0 ? (
        <div className="sparks-measures-workspace__state">
          Nenhuma medida governada foi encontrada neste contexto.
        </div>
      ) : (
        <OrganizationIndicatorsSmartGrid
          rows={summaryFilteredRows}
          organizationId={organizationId}
          sourceModuleCode={sourceModuleCode}
          monitoringParameters={monitoringParameters}
          onReload={loadMeasures}
        />
      )}

      {mode === 'administration' ? (
        <section className="sparks-measures-workspace__catalog-section">
          <div className="sparks-measures-workspace__admin-note">
            <strong>Catálogo GERAL → Organização → módulos</strong>
            <span>
              A referência permanece única no Catálogo GERAL. A organização
              adota por vínculo e registra somente as adaptações necessárias ao
              seu contexto. O SPARKs PE consome a instância organizacional.
            </span>
          </div>

          <div className="sparks-measures-workspace__section-heading">
            <div>
              <h3>Catálogo GERAL disponível para adoção</h3>
              <p>
                Selecione uma referência vigente e vincule-a a um Objetivo
                Estratégico da organização.
              </p>
            </div>
            <button
              type="button"
              className="sparks-measures-workspace__secondary-action"
              onClick={() => void loadCatalog()}
              disabled={catalogLoading}
            >
              Atualizar catálogo
            </button>
          </div>

          {catalogError ? (
            <div className="sparks-measures-workspace__state is-error">
              {catalogError}
            </div>
          ) : catalogLoading ? (
            <div className="sparks-measures-workspace__state">
              Carregando Catálogo GERAL...
            </div>
          ) : catalog.length === 0 ? (
            <div className="sparks-measures-workspace__state">
              O Catálogo GERAL ainda não possui referências vigentes para
              adoção. Nenhum indicador será criado automaticamente.
            </div>
          ) : (
            <MeasuresCatalogSmartGrid
              catalog={catalog}
              selectedReferenceId={adoptionForm.referenceCatalogId}
              onSelect={(referenceId) =>
                setAdoptionForm((current) => ({
                  ...current,
                  referenceCatalogId: referenceId,
                }))
              }
              onOpenAdoption={(referenceId) => {
                setAdoptionForm((current) => ({
                  ...current,
                  referenceCatalogId: referenceId,
                }))
                setAdoptionPanelOpen(true)
              }}
            />
          )}

                    {selectedReference && adoptionPanelOpen ? (
            <>
              <button
                type="button"
                className="sparks-measures-workspace__adoption-backdrop"
                aria-label="Fechar adoção"
                onClick={() => setAdoptionPanelOpen(false)}
              />
              <div className="sparks-measures-workspace__adoption-form is-side-panel">
                <div className="sparks-measures-workspace__adoption-panel-header">
                  <div>
                    <strong>Adotar referência na organização</strong>
                    <span>{selectedReference.catalog_code} · {selectedReference.name}</span>
                  </div>
                  <button
                    type="button"
                    onClick={() => setAdoptionPanelOpen(false)}
                  >
                    Fechar
                  </button>
                </div>
              <div className="sparks-measures-workspace__section-heading">
                <div>
                  <h3>Adotar referência na organização</h3>
                  <p>
                    A adoção cria a instância organizacional vinculada ao
                    Catálogo GERAL. Ajustes abaixo ficam registrados como
                    adaptação, sem substituir a referência.
                  </p>
                </div>
              </div>

              <div className="sparks-measures-workspace__form-grid">
                <label>
                  <span>Formulação Estratégica *</span>
                  <select
                    value={adoptionForm.formulationId}
                    onChange={(event) =>
                      setAdoptionForm((current) => ({
                        ...current,
                        formulationId: event.target.value,
                        objectiveId: '',
                      }))
                    }
                  >
                    <option value="">
                      Selecione
                    </option>
                    {formulations.map((item) => (
                      <option key={item.id} value={item.id}>
                        Formulação v{item.version_number} · {item.status}
                      </option>
                    ))}
                  </select>
                </label>

                <label>
                  <span>Objetivo Estratégico *</span>
                  <select
                    value={adoptionForm.objectiveId}
                    onChange={(event) =>
                      setAdoptionForm((current) => ({
                        ...current,
                        objectiveId: event.target.value,
                      }))
                    }
                  >
                    <option value="">
                      Selecione
                    </option>
                    {objectives.map((item) => (
                      <option key={item.id} value={item.id}>
                        {item.code} · {item.title}
                      </option>
                    ))}
                  </select>
                </label>

                <label>
                  <span>Código na organização</span>
                  <input
                    value={adoptionForm.code}
                    onChange={(event) =>
                      setAdoptionForm((current) => ({
                        ...current,
                        code: event.target.value,
                      }))
                    }
                  />
                </label>

                <label>
                  <span>Nome na organização</span>
                  <input
                    value={adoptionForm.name}
                    onChange={(event) =>
                      setAdoptionForm((current) => ({
                        ...current,
                        name: event.target.value,
                      }))
                    }
                  />
                </label>

                <label>
                  <span>Unidade</span>
                  <input
                    value={adoptionForm.unit}
                    onChange={(event) =>
                      setAdoptionForm((current) => ({
                        ...current,
                        unit: event.target.value,
                      }))
                    }
                  />
                </label>

                <label>
                  <span>Periodicidade</span>
                  <select
                    value={adoptionForm.measurementFrequency}
                    onChange={(event) =>
                      setAdoptionForm((current) => ({
                        ...current,
                        measurementFrequency:
                          event.target.value,
                      }))
                    }
                  >
                    <option value="">Herdar referência</option>
                    <option value="daily">Diária</option>
                    <option value="weekly">Semanal</option>
                    <option value="monthly">Mensal</option>
                    <option value="bimonthly">Bimestral</option>
                    <option value="quarterly">Trimestral</option>
                    <option value="semiannual">Semestral</option>
                    <option value="annual">Anual</option>
                    <option value="on_demand">Sob demanda</option>
                  </select>
                </label>

                <label className="is-wide">
                  <span>Descrição adaptada</span>
                  <textarea
                    value={adoptionForm.description}
                    onChange={(event) =>
                      setAdoptionForm((current) => ({
                        ...current,
                        description: event.target.value,
                      }))
                    }
                  />
                </label>

                <label className="is-wide">
                  <span>Notas da adaptação organizacional</span>
                  <textarea
                    value={adoptionForm.adaptationNotes}
                    onChange={(event) =>
                      setAdoptionForm((current) => ({
                        ...current,
                        adaptationNotes: event.target.value,
                      }))
                    }
                    placeholder="Explique apenas o que difere da referência geral."
                  />
                </label>

                <label className="is-wide">
                  <span>Justificativa para auditoria *</span>
                  <textarea
                    value={adoptionForm.reason}
                    onChange={(event) =>
                      setAdoptionForm((current) => ({
                        ...current,
                        reason: event.target.value,
                      }))
                    }
                    placeholder="Informe por que esta referência está sendo adotada."
                  />
                </label>
              </div>

              {adoptionMessage ? (
                <div className="sparks-measures-workspace__adoption-message">
                  {adoptionMessage}
                </div>
              ) : null}

              <button
                type="button"
                className="sparks-measures-workspace__primary-action"
                onClick={() => void adoptReference()}
                disabled={adopting}
              >
                {adopting
                  ? 'Adotando referência...'
                  : 'Adotar referência'}
              </button>
              </div>
            </>
          ) : null}
        </section>
      ) : null}


    </section>
  )
}
