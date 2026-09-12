import { useEffect, useMemo, useState } from 'react'

import type { StrategicMapPayload } from '../../contracts/strategic-map.ts'
import { loadStrategicMap } from './strategicMapLoader.ts'
import { resolveStrategicCauseEffectSuggestions } from './strategicCauseEffectSuggestions.ts'

import './StrategicArchitectureSummary.css'

type Props = {
  formulationId: string | null
}

export function StrategicArchitectureSummary({ formulationId }: Props) {
  const [payload, setPayload] = useState<StrategicMapPayload | null>(null)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    if (!formulationId) {
      setPayload(null)
      return () => {
        active = false
      }
    }

    void loadStrategicMap(formulationId)
      .then((nextPayload) => {
        if (active) setPayload(nextPayload)
      })
      .catch((error) => {
        if (!active) return
        setErrorMessage(
          error instanceof Error
            ? error.message
            : 'Não foi possível carregar a arquitetura estratégica.',
        )
      })

    return () => {
      active = false
    }
  }, [formulationId])

  const suggestions = useMemo(
    () =>
      payload
        ? resolveStrategicCauseEffectSuggestions(
            payload.objectives,
            payload.perspectives,
          )
        : [],
    [payload],
  )

  if (errorMessage) {
    return <section className="skpe-architecture-state is-error">{errorMessage}</section>
  }

  if (!payload) {
    return (
      <section className="skpe-architecture-state">
        Arquitetura estratégica indisponível para esta versão.
      </section>
    )
  }

  const themes = [...payload.themes].sort(
    (first, second) =>
      first.displayOrder - second.displayOrder ||
      first.code.localeCompare(second.code, 'pt-BR'),
  )

  const perspectives = [...payload.perspectives].sort(
    (first, second) =>
      first.displayOrder - second.displayOrder ||
      first.code.localeCompare(second.code, 'pt-BR'),
  )

  const objectives = [...payload.objectives].sort((first, second) =>
    first.code.localeCompare(second.code, 'pt-BR'),
  )

  const themeById = new Map(themes.map((theme) => [theme.id, theme]))
  const perspectiveById = new Map(
    perspectives.map((perspective) => [perspective.id, perspective]),
  )

  return (
    <section className="skpe-architecture-summary">
      <section className="skpe-architecture-section">
        <h2>Temas Estratégicos</h2>
        <div className="skpe-architecture-theme-grid">
          {themes.map((theme) => (
            <article key={theme.id}>
              <small>{theme.code}</small>
              <strong>{theme.name}</strong>
              {theme.description ? <p>{theme.description}</p> : null}
            </article>
          ))}
        </div>
      </section>

      <section className="skpe-architecture-section">
        <h2>Perspectivas Estratégicas</h2>
        <div className="skpe-architecture-perspective-grid">
          {perspectives.map((perspective) => (
            <article key={perspective.id}>
              <small>{perspective.code}</small>
              <strong>{perspective.name}</strong>
              {perspective.description ? <p>{perspective.description}</p> : null}
            </article>
          ))}
        </div>
      </section>

      <section className="skpe-architecture-section">
        <h2>Objetivos Estratégicos</h2>
        <div className="skpe-architecture-objective-grid">
          {objectives.map((objective) => {
            const theme = objective.strategicThemeId
              ? themeById.get(objective.strategicThemeId)
              : null
            const perspective = objective.perspectiveId
              ? perspectiveById.get(objective.perspectiveId)
              : null
            const incoming = suggestions.filter(
              (suggestion) => suggestion.targetId === objective.id,
            )
            const outgoing = suggestions.filter(
              (suggestion) => suggestion.sourceId === objective.id,
            )

            return (
              <article key={objective.id} className="skpe-architecture-objective-card">
                <small>{objective.code}</small>
                <strong>{objective.title}</strong>
                <p>
                  {theme && perspective
                    ? `Materializa ${theme.name} na perspectiva ${perspective.name}. `
                    : ''}
                  {objective.expectedResult
                    ? `Resultado esperado: ${objective.expectedResult}`
                    : 'O resultado esperado ainda não está materializado.'}
                </p>

                <div className="skpe-architecture-objective-links">
                  {theme ? <span>{theme.code} · {theme.name}</span> : null}
                  {perspective ? (
                    <span>{perspective.code} · {perspective.name}</span>
                  ) : null}
                </div>

                {incoming.length > 0 || outgoing.length > 0 ? (
                  <div className="skpe-architecture-causal-role">
                    {incoming.length > 0 ? (
                      <p>
                        <b>Sustentado por:</b>{' '}
                        {incoming.map((item) => item.sourceCode).join(', ')}
                      </p>
                    ) : null}
                    {outgoing.length > 0 ? (
                      <p>
                        <b>Contribui para:</b>{' '}
                        {outgoing.map((item) => item.targetCode).join(', ')}
                      </p>
                    ) : null}
                  </div>
                ) : null}
              </article>
            )
          })}
        </div>
      </section>

      {suggestions.length > 0 ? (
        <section className="skpe-architecture-section">
          <h2>Relações de causa e efeito sugeridas</h2>
          <p className="skpe-architecture-guidance">
            Hipóteses para validação antes de qualquer registro como relação oficial do Mapa Estratégico.
          </p>
          <div className="skpe-architecture-relation-grid">
            {suggestions.map((suggestion) => (
              <article key={`${suggestion.sourceCode}:${suggestion.targetCode}`}>
                <strong>
                  {suggestion.sourceCode} {'\u2192'} {suggestion.targetCode}
                </strong>
                <p>{suggestion.rationale}</p>
              </article>
            ))}
          </div>
        </section>
      ) : null}
    </section>
  )
}