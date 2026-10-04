import { useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import { useSkpeWorkspace } from '../../context/SkpeWorkspaceContext'
import './StrategicContentSection.css'

type ValidationMetadata = {
  source_status?: string | null
  validation_status?: string | null
  validation_gate?: string | null
}

type Theme = {
  id: string
  code: string
  name: string
  description: string | null
  display_order: number
  status: string
  metadata: ValidationMetadata | null
}

type Perspective = {
  id: string
  code: string
  name: string
  description: string | null
  display_order: number
  status: string
  metadata: ValidationMetadata | null
}

type Objective = {
  id: string
  code: string
  name: string
  description: string | null
  perspective_id: string | null
  perspective_code: string | null
  status: string
  metadata: ValidationMetadata | null
}

function validationLabel(metadata: ValidationMetadata | null, status: string) {
  const sourceStatus = metadata?.source_status?.trim()
  if (sourceStatus) return sourceStatus

  const validationStatus = metadata?.validation_status?.trim()
  if (validationStatus === 'pending_validation') return 'Pendente de validação'
  if (validationStatus === 'draft') return 'Hipótese técnica — não submetida'

  return status === 'draft' ? 'Hipótese técnica — não submetida' : status
}

type Props = {
  organizationId: string
  projectId?: string | null
}

export function StrategicPositioningSection({
  organizationId,
  projectId,
}: Props) {
  const workspace = useSkpeWorkspace()
  const formulationId = workspace.route.formulationId
  const effectiveProjectId = workspace.route.projectId ?? projectId

  const [themes, setThemes] = useState<Theme[]>([])
  const [perspectives, setPerspectives] = useState<Perspective[]>([])
  const [objectives, setObjectives] = useState<Objective[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true

    if (!formulationId) {
      setThemes([])
      setPerspectives([])
      setObjectives([])
      setError('')
      return () => {
        active = false
      }
    }

    setError('')

    const themesQuery = supabase
      .from('skpe_strategic_themes')
      .select('id,code,name,description,display_order,status,metadata')
      .eq('organization_id', organizationId)
      .eq('formulation_id', formulationId)
      .order('display_order')

    const perspectivesQuery = supabase
      .from('skpe_bsc_perspectives')
      .select('id,code,name,description,display_order,status,metadata')
      .eq('organization_id', organizationId)
      .eq('formulation_id', formulationId)
      .order('display_order')

    const objectivesQuery = supabase
      .from('skpe_strategic_objectives')
      .select(
        'id,code,name,description,perspective_id,perspective_code,status,metadata',
      )
      .eq('organization_id', organizationId)
      .eq('formulation_id', formulationId)
      .order('code')

    const scopedThemesQuery = effectiveProjectId
      ? themesQuery.eq('project_id', effectiveProjectId)
      : themesQuery
    const scopedPerspectivesQuery = effectiveProjectId
      ? perspectivesQuery.eq('project_id', effectiveProjectId)
      : perspectivesQuery
    const scopedObjectivesQuery = effectiveProjectId
      ? objectivesQuery.eq('project_id', effectiveProjectId)
      : objectivesQuery

    void Promise.all([
      scopedThemesQuery,
      scopedPerspectivesQuery,
      scopedObjectivesQuery,
    ]).then(([themeResponse, perspectiveResponse, objectiveResponse]) => {
      if (!active) return

      if (
        themeResponse.error ||
        perspectiveResponse.error ||
        objectiveResponse.error
      ) {
        setError('Não foi possível carregar o Posicionamento Estratégico.')
        return
      }

      setThemes((themeResponse.data ?? []) as Theme[])
      setPerspectives((perspectiveResponse.data ?? []) as Perspective[])
      setObjectives((objectiveResponse.data ?? []) as Objective[])
    })

    return () => {
      active = false
    }
  }, [organizationId, effectiveProjectId, formulationId])

  if (!formulationId) {
    return (
      <section className="skpe-strategy-state">
        Selecione uma Formulação Estratégica para consultar o Mapa Estratégico.
      </section>
    )
  }

  if (error) {
    return <section className="skpe-strategy-state is-error">{error}</section>
  }

  return (
    <section className="skpe-strategy-content">
      <header>
        <span>PEM-02.03 · Escolhas e Posicionamento Estratégico</span>
        <h1>Posicionamento Estratégico</h1>
        <p className="skpe-strategy-validation-guidance">
          Esta etapa organiza hipóteses de Temas e Perspectivas para validação
          humana. Conteúdo materializado não equivale a aprovação institucional.
        </p>
      </header>

      <section>
        <h2>{themes.length} Temas Estratégicos em validação</h2>
        <div className="skpe-strategy-theme-grid">
          {themes.map((theme) => (
            <article key={theme.id}>
              <small>{theme.code}</small>
              <span className="skpe-strategy-validation-badge">
                {validationLabel(theme.metadata, theme.status)}
              </span>
              <strong>{theme.name}</strong>
              {theme.description ? <p>{theme.description}</p> : null}
            </article>
          ))}
        </div>
      </section>

      <section>
        <h2>{perspectives.length} Perspectivas Estratégicas em validação</h2>
        <div className="skpe-strategy-perspective-grid">
          {perspectives.map((perspective) => (
            <article key={perspective.id}>
              <small>{perspective.code}</small>
              <span className="skpe-strategy-validation-badge">
                {validationLabel(perspective.metadata, perspective.status)}
              </span>
              <strong>{perspective.name}</strong>
              {perspective.description ? (
                <p>{perspective.description}</p>
              ) : null}
            </article>
          ))}
        </div>
      </section>

      <section className="skpe-strategy-next-stage-preview">
        <header>
          <span>Próxima etapa · PEM-02.04</span>
          <h2>Objetivos Estratégicos — prévia bloqueada</h2>
          <p>
            Os {objectives.length} Objetivos já materializados permanecem em
            draft e não fazem parte da validação desta etapa. Eles só devem ser
            trabalhados após a conclusão governada do Posicionamento Estratégico.
          </p>
        </header>
        <div className="skpe-strategy-objective-grid">
          {objectives.map((objective) => (
            <article key={objective.id} className="skpe-strategy-objective-card">
              <small>{objective.code}</small>
              <span className="skpe-strategy-validation-badge">
                {validationLabel(objective.metadata, objective.status)}
              </span>
              <strong>{objective.name}</strong>
            </article>
          ))}
        </div>
      </section>
    </section>
  )
}