import { useEffect, useMemo, useState } from 'react'

import { MetricCard } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

import './StrategicInitiativePlanSection.css'

type Props = {
  organizationId: string
  projectId: string
}

type ObjectiveRow = {
  id: string
  code: string
  name: string
  validation_status: string | null
}

type KeyResultRow = {
  id: string
  code: string
  name: string
  strategic_objective_id: string | null
  okr_id: string | null
  validation_status: string | null
}

type LegacyInitiativeRow = {
  id: string
  code: string
  name: string
  status: string
  validation_status: string | null
}

type SparksInitiativeRow = {
  id: string
  code: string
  name: string
  status: string
  validation_status: string | null
}

type LegacyObjectiveLinkRow = {
  initiative_id: string
  strategic_objective_id: string
}

type LegacyKeyResultLinkRow = {
  initiative_id: string
  key_result_id: string
}

type SparksStrategicLinkRow = {
  sparks_initiative_id: string
  strategic_objective_id: string | null
  key_result_id: string | null
  contribution_type: string
  validation_status: string
}

type ProjectBindingRow = {
  initiative_id: string
  binding_type: string
}

export function StrategicInitiativePlanSection({
  organizationId,
  projectId,
}: Props) {
  const [objectives, setObjectives] = useState<ObjectiveRow[]>([])
  const [keyResults, setKeyResults] = useState<KeyResultRow[]>([])
  const [legacyInitiatives, setLegacyInitiatives] = useState<LegacyInitiativeRow[]>([])
  const [sparksInitiatives, setSparksInitiatives] = useState<SparksInitiativeRow[]>([])
  const [legacyObjectiveLinks, setLegacyObjectiveLinks] = useState<LegacyObjectiveLinkRow[]>([])
  const [legacyKeyResultLinks, setLegacyKeyResultLinks] = useState<LegacyKeyResultLinkRow[]>([])
  const [sparksStrategicLinks, setSparksStrategicLinks] = useState<SparksStrategicLinkRow[]>([])
  const [projectBindings, setProjectBindings] = useState<ProjectBindingRow[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setLoading(true)
      setErrorMessage('')

      const [
        objectivesResponse,
        keyResultsResponse,
        legacyInitiativesResponse,
        legacyObjectiveLinksResponse,
        legacyKeyResultLinksResponse,
        sparksStrategicLinksResponse,
        projectBindingsResponse,
      ] = await Promise.all([
        supabase
          .from('skpe_strategic_objectives')
          .select('id, code, name, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .order('code'),
        supabase
          .from('skpe_key_results')
          .select('id, code, name, strategic_objective_id, okr_id, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .order('code'),
        supabase
          .from('skpe_initiatives')
          .select('id, code, name, status, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .is('archived_at', null)
          .order('code'),
        supabase
          .from('skpe_initiative_objectives')
          .select('initiative_id, strategic_objective_id')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_initiative_key_results')
          .select('initiative_id, key_result_id')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_sparks_initiative_strategic_links')
          .select('sparks_initiative_id, strategic_objective_id, key_result_id, contribution_type, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_project_initiative_bindings')
          .select('initiative_id, binding_type')
          .eq('organization_id', organizationId)
          .eq('skpe_project_id', projectId),
      ])

      if (!active) return

      const responses = [
        objectivesResponse,
        keyResultsResponse,
        legacyInitiativesResponse,
        legacyObjectiveLinksResponse,
        legacyKeyResultLinksResponse,
        sparksStrategicLinksResponse,
        projectBindingsResponse,
      ]
      const firstError = responses.find((response) => response.error)?.error

      if (firstError) {
        setErrorMessage(
          `Não foi possível consolidar o Plano de Iniciativas: ${firstError.message}`,
        )
        setLoading(false)
        return
      }

      const strategicLinks = (sparksStrategicLinksResponse.data ?? []) as SparksStrategicLinkRow[]
      const bindings = (projectBindingsResponse.data ?? []) as ProjectBindingRow[]
      const sparksIds = Array.from(
        new Set([
          ...strategicLinks.map((row) => row.sparks_initiative_id),
          ...bindings.map((row) => row.initiative_id),
        ]),
      )

      let loadedSparksInitiatives: SparksInitiativeRow[] = []
      if (sparksIds.length > 0) {
        const sparksResponse = await supabase
          .from('sparks_initiatives')
          .select('id, code, name, status, validation_status')
          .eq('organization_id', organizationId)
          .in('id', sparksIds)
          .is('archived_at', null)
          .order('code')

        if (!active) return
        if (sparksResponse.error) {
          setErrorMessage(
            `Não foi possível consolidar as iniciativas transversais: ${sparksResponse.error.message}`,
          )
          setLoading(false)
          return
        }
        loadedSparksInitiatives = (sparksResponse.data ?? []) as SparksInitiativeRow[]
      }

      setObjectives((objectivesResponse.data ?? []) as ObjectiveRow[])
      setKeyResults((keyResultsResponse.data ?? []) as KeyResultRow[])
      setLegacyInitiatives((legacyInitiativesResponse.data ?? []) as LegacyInitiativeRow[])
      setLegacyObjectiveLinks((legacyObjectiveLinksResponse.data ?? []) as LegacyObjectiveLinkRow[])
      setLegacyKeyResultLinks((legacyKeyResultLinksResponse.data ?? []) as LegacyKeyResultLinkRow[])
      setSparksStrategicLinks(strategicLinks)
      setProjectBindings(bindings)
      setSparksInitiatives(loadedSparksInitiatives)
      setLoading(false)
    }

    void load()
    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const objectiveInitiativeIds = useMemo(() => {
    const map = new Map<string, Set<string>>()
    for (const link of legacyObjectiveLinks) {
      const set = map.get(link.strategic_objective_id) ?? new Set<string>()
      set.add(`legacy:${link.initiative_id}`)
      map.set(link.strategic_objective_id, set)
    }
    for (const link of sparksStrategicLinks) {
      if (!link.strategic_objective_id) continue
      const set = map.get(link.strategic_objective_id) ?? new Set<string>()
      set.add(`sparks:${link.sparks_initiative_id}`)
      map.set(link.strategic_objective_id, set)
    }
    return map
  }, [legacyObjectiveLinks, sparksStrategicLinks])

  const keyResultInitiativeIds = useMemo(() => {
    const map = new Map<string, Set<string>>()
    for (const link of legacyKeyResultLinks) {
      const set = map.get(link.key_result_id) ?? new Set<string>()
      set.add(`legacy:${link.initiative_id}`)
      map.set(link.key_result_id, set)
    }
    for (const link of sparksStrategicLinks) {
      if (!link.key_result_id) continue
      const set = map.get(link.key_result_id) ?? new Set<string>()
      set.add(`sparks:${link.sparks_initiative_id}`)
      map.set(link.key_result_id, set)
    }
    return map
  }, [legacyKeyResultLinks, sparksStrategicLinks])

  const coveredObjectives = objectives.filter(
    (objective) => (objectiveInitiativeIds.get(objective.id)?.size ?? 0) > 0,
  ).length
  const coveredKeyResults = keyResults.filter(
    (keyResult) => (keyResultInitiativeIds.get(keyResult.id)?.size ?? 0) > 0,
  ).length

  const linkedInitiativeIds = new Set([
    ...legacyObjectiveLinks.map((row) => `legacy:${row.initiative_id}`),
    ...legacyKeyResultLinks.map((row) => `legacy:${row.initiative_id}`),
    ...sparksStrategicLinks.map((row) => `sparks:${row.sparks_initiative_id}`),
  ])

  const allInitiativeIds = new Set([
    ...legacyInitiatives.map((row) => `legacy:${row.id}`),
    ...sparksInitiatives.map((row) => `sparks:${row.id}`),
  ])

  const uncoveredObjectives = objectives.length - coveredObjectives
  const uncoveredKeyResults = keyResults.length - coveredKeyResults

  const structuralBindings = projectBindings.filter(
    (row) => row.binding_type === 'strategic_plan_implementation',
  )
  const structuralInitiativeIds = new Set(
    structuralBindings.map((row) => row.initiative_id),
  )
  const structuralLinkedCount = sparksStrategicLinks.filter(
    (row) => structuralInitiativeIds.has(row.sparks_initiative_id),
  ).length

  return (
    <section className="skpe-strategic-initiative-plan">
      <header className="skpe-strategic-initiative-plan__header">
        <p className="skpe-eyebrow">Plano de Iniciativas Estratégicas</p>
        <h3>Cobertura estratégica das iniciativas</h3>
        <p>
          Esta superfície verifica a cobertura entre Objetivos Estratégicos,
          Resultados-Chave e iniciativas já materializadas. A identidade canônica
          transversal da iniciativa permanece em SPARKs; a Formulação registra
          apenas seus vínculos estratégicos especializados. Ausência de vínculo é
          tratada como lacuna; nenhuma iniciativa é criada automaticamente.
        </p>
      </header>

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : null}

      <div className="skpe-strategic-initiative-plan__metrics">
        <MetricCard
          label="Objetivos Estratégicos com cobertura"
          value={`${coveredObjectives}/${objectives.length}`}
          helper={
            objectives.length === 0
              ? 'Sem Objetivos Estratégicos materializados.'
              : `${uncoveredObjectives} sem iniciativa vinculada.`
          }
        />
        <MetricCard
          label="Resultados-Chave com cobertura"
          value={`${coveredKeyResults}/${keyResults.length}`}
          helper={
            keyResults.length === 0
              ? 'Sem Resultados-Chave materializados.'
              : `${uncoveredKeyResults} sem iniciativa vinculada.`
          }
        />
        <MetricCard
          label="Iniciativas vinculadas à estratégia"
          value={`${linkedInitiativeIds.size}/${allInitiativeIds.size}`}
          helper="Vínculo especializado a OE e/ou KR sem duplicar a iniciativa transversal."
        />
        <MetricCard
          label="Lacunas de cobertura"
          value={uncoveredObjectives + uncoveredKeyResults}
          helper="Lacunas observadas; não representam reprovação automática."
        />
      </div>

      {structuralBindings.length > 0 ? (
        <div className="skpe-strategic-initiative-plan__panel">
          <h4>Iniciativa estrutural do Planejamento Estratégico</h4>
          <p className="skpe-strategic-initiative-plan__empty">
            {structuralLinkedCount > 0
              ? 'A iniciativa estrutural do PE já possui vínculo estratégico na Formulação.'
              : 'A iniciativa estrutural do PE existe, mas ainda aguarda uma casa estratégica na Formulação.'}
          </p>
        </div>
      ) : null}

      {loading ? (
        <p className="skpe-strategic-initiative-plan__empty">
          Consolidando vínculos estratégicos canônicos...
        </p>
      ) : (
        <div className="skpe-strategic-initiative-plan__grid">
          <article className="skpe-strategic-initiative-plan__panel">
            <h4>Cobertura por Objetivo Estratégico</h4>
            {objectives.length === 0 ? (
              <p className="skpe-strategic-initiative-plan__empty">
                Nenhum Objetivo Estratégico materializado.
              </p>
            ) : (
              <div className="skpe-strategic-initiative-plan__rows">
                {objectives.map((objective) => {
                  const initiativeIds = objectiveInitiativeIds.get(objective.id)
                  const count = initiativeIds?.size ?? 0
                  return (
                    <div
                      className="skpe-strategic-initiative-plan__row"
                      key={objective.id}
                    >
                      <div>
                        <strong>{objective.code}</strong>
                        <span>{objective.name}</span>
                      </div>
                      <small>
                        {count > 0
                          ? `${count} iniciativa(s) vinculada(s)`
                          : 'Sem iniciativa vinculada'}
                      </small>
                    </div>
                  )
                })}
              </div>
            )}
          </article>

          <article className="skpe-strategic-initiative-plan__panel">
            <h4>Cobertura por Resultado-Chave</h4>
            {keyResults.length === 0 ? (
              <p className="skpe-strategic-initiative-plan__empty">
                Nenhum Resultado-Chave materializado.
              </p>
            ) : (
              <div className="skpe-strategic-initiative-plan__rows">
                {keyResults.map((keyResult) => {
                  const initiativeIds = keyResultInitiativeIds.get(keyResult.id)
                  const count = initiativeIds?.size ?? 0
                  return (
                    <div
                      className="skpe-strategic-initiative-plan__row"
                      key={keyResult.id}
                    >
                      <div>
                        <strong>{keyResult.code}</strong>
                        <span>{keyResult.name}</span>
                      </div>
                      <small>
                        {count > 0
                          ? `${count} iniciativa(s) vinculada(s)`
                          : 'Sem iniciativa vinculada'}
                      </small>
                    </div>
                  )
                })}
              </div>
            )}
          </article>
        </div>
      )}
    </section>
  )
}
