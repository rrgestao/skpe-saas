import { useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import './StrategicContentSection.css'

type Theme = {
  id: string
  code: string
  name: string
  description: string | null
  display_order: number
}

type Perspective = {
  id: string
  code: string
  name: string
  description: string | null
  display_order: number
}

type Objective = {
  id: string
  code: string
  name: string
  description: string | null
  perspective_id: string | null
  perspective_code: string | null
}

type Props = {
  organizationId: string
  projectId?: string | null
}

export function StrategicPositioningSection({
  organizationId,
  projectId,
}: Props) {
  const [themes, setThemes] = useState<Theme[]>([])
  const [perspectives, setPerspectives] = useState<Perspective[]>([])
  const [objectives, setObjectives] = useState<Objective[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true

    const themesQuery = supabase
      .from('skpe_strategic_themes')
      .select('id,code,name,description,display_order')
      .eq('organization_id', organizationId)
      .order('display_order')

    const perspectivesQuery = supabase
      .from('skpe_bsc_perspectives')
      .select('id,code,name,description,display_order')
      .eq('organization_id', organizationId)
      .order('display_order')

    const objectivesQuery = supabase
      .from('skpe_strategic_objectives')
      .select(
        'id,code,name,description,perspective_id,perspective_code',
      )
      .eq('organization_id', organizationId)
      .order('code')

    const scopedThemesQuery = projectId
      ? themesQuery.eq('project_id', projectId)
      : themesQuery
    const scopedPerspectivesQuery = projectId
      ? perspectivesQuery.eq('project_id', projectId)
      : perspectivesQuery
    const scopedObjectivesQuery = projectId
      ? objectivesQuery.eq('project_id', projectId)
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
  }, [organizationId, projectId])

  if (error) {
    return <section className="skpe-strategy-state is-error">{error}</section>
  }

  return (
    <section className="skpe-strategy-content">
      <header>
        <span>Arquitetura Estratégica Integrada</span>
        <h1>Posicionamento Estratégico</h1>
      </header>

      <section>
        <h2>{themes.length} Temas Estratégicos</h2>
        <div className="skpe-strategy-theme-grid">
          {themes.map((theme) => (
            <article key={theme.id}>
              <small>{theme.code}</small>
              <strong>{theme.name}</strong>
              {theme.description ? <p>{theme.description}</p> : null}
            </article>
          ))}
        </div>
      </section>

      <section>
        <h2>{perspectives.length} Perspectivas Estratégicas</h2>
        <div className="skpe-strategy-perspective-grid">
          {perspectives.map((perspective) => (
            <article key={perspective.id}>
              <small>{perspective.code}</small>
              <strong>{perspective.name}</strong>
              {perspective.description ? (
                <p>{perspective.description}</p>
              ) : null}

              <div className="skpe-strategy-objectives">
                {objectives
                  .filter(
                    (objective) =>
                      objective.perspective_id === perspective.id ||
                      objective.perspective_code === perspective.code,
                  )
                  .map((objective) => (
                    <div key={objective.id}>
                      <b>{objective.code}</b>
                      <span>{objective.name}</span>
                    </div>
                  ))}
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="skpe-strategy-objective-section">
      <h2>{objectives.length} Objetivos Estratégicos</h2>
      <div className="skpe-strategy-objective-grid">
        {objectives.map((objective) => (
          <article key={objective.id} className="skpe-strategy-objective-card">
            <small>{objective.code}</small>
            <strong>{objective.name}</strong>
            {objective.description ? <p>{objective.description}</p> : null}
          </article>
        ))}
      </div>
    </section>
    </section>
  )
}