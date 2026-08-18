import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react'

import { translateBackendMessage } from '../../../../shared/i18n/ptBR'

import type {
  EvolutionCycleRow,
  EvolutionScenarioCycleRow,
} from '../../contracts/evolution'

import {
  loadEvolutionOverview,
  type EvolutionOverviewData,
} from './evolutionData'

import {
  ObjectiveEvolutionAlignmentEditor,
} from './ObjectiveEvolutionAlignmentEditor'

import './EvolutionCyclesSection.css'

type EvolutionCyclesSectionProps = {
  projectId: string
}

type CycleSelection =
  | {
      kind: 'scenario'
      cycle: EvolutionScenarioCycleRow
    }
  | {
      kind: 'institutional'
      cycle: EvolutionCycleRow
    }
  | null

const statusLabels: Record<string, string> = {
  draft: 'Rascunho',
  adjusted: 'Ajustado',
  submitted: 'Submetido',
  approved: 'Aprovado',
  rejected: 'Rejeitado',
  superseded: 'Substituído',
  historical_recognized:
    'Histórico reconhecido',
}

function statusLabel(value: string) {
  return statusLabels[value] ?? value
}

function formatDate(
  value: string | null | undefined,
) {
  if (!value) return 'Não informado'

  const parts = value
    .slice(0, 10)
    .split('-')

  if (parts.length !== 3) {
    return value
  }

  return `${parts[2]}/${parts[1]}/${parts[0]}`
}

function cyclePeriod(
  start: string,
  end: string,
) {
  return `${formatDate(start)} a ${formatDate(end)}`
}

function readableJson(value: unknown) {
  if (
    value === null ||
    value === undefined
  ) {
    return 'Não informado'
  }

  if (Array.isArray(value)) {
    if (value.length === 0) {
      return 'Não informado'
    }

    return value
      .map((item) =>
        typeof item === 'string'
          ? item
          : JSON.stringify(item),
      )
      .join(' • ')
  }

  if (typeof value === 'object') {
    const entries = Object.entries(
      value as Record<string, unknown>,
    )

    if (entries.length === 0) {
      return 'Não informado'
    }

    return entries
      .map(
        ([key, item]) =>
          `${key}: ${
            typeof item === 'string'
              ? item
              : JSON.stringify(item)
          }`,
      )
      .join(' • ')
  }

  return String(value)
}

export function EvolutionCyclesSection({
  projectId,
}: EvolutionCyclesSectionProps) {
  const [data, setData] =
    useState<EvolutionOverviewData | null>(
      null,
    )

  const [loading, setLoading] =
    useState(true)

  const [errorMessage, setErrorMessage] =
    useState('')

  const [selection, setSelection] =
    useState<CycleSelection>(null)

  const loadData = useCallback(async () => {
    if (!projectId) {
      setData(null)
      setLoading(false)
      return
    }

    setLoading(true)
    setErrorMessage('')

    try {
      const result =
        await loadEvolutionOverview(
          projectId,
        )

      setData(result)
    } catch (error) {
      setData(null)

      const message =
        error instanceof Error
          ? error.message
          : String(error)

      setErrorMessage(
        translateBackendMessage(message),
      )
    } finally {
      setLoading(false)
    }
  }, [projectId])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const currentScenario = useMemo(
    () => data?.scenarios[0] ?? null,
    [data],
  )

  const currentScenarioCycles = useMemo(
    () =>
      currentScenario
        ? data?.scenarioCycles.filter(
            (cycle) =>
              cycle.scenario_id ===
              currentScenario.id,
          ) ?? []
        : [],
    [currentScenario, data],
  )

  const currentPlan = useMemo(
    () =>
      data?.plans.find(
        (plan) => plan.is_current,
      ) ?? null,
    [data],
  )

  const currentPlanCycles = useMemo(
    () =>
      currentPlan
        ? data?.cycles.filter(
            (cycle) =>
              cycle.evolution_plan_id ===
              currentPlan.id,
          ) ?? []
        : [],
    [currentPlan, data],
  )

  useEffect(() => {
    setSelection((current) => {
      if (
        current?.kind === 'scenario' &&
        currentScenarioCycles.some(
          (cycle) =>
            cycle.id ===
            current.cycle.id,
        )
      ) {
        return current
      }

      if (
        current?.kind ===
          'institutional' &&
        currentPlanCycles.some(
          (cycle) =>
            cycle.id ===
            current.cycle.id,
        )
      ) {
        return current
      }

      if (currentPlanCycles[0]) {
        return {
          kind: 'institutional',
          cycle: currentPlanCycles[0],
        }
      }

      if (currentScenarioCycles[0]) {
        return {
          kind: 'scenario',
          cycle: currentScenarioCycles[0],
        }
      }

      return null
    })
  }, [
    currentPlanCycles,
    currentScenarioCycles,
  ])

  if (loading) {
    return (
      <section className="skpe-evolution">
        <div className="skpe-evolution-state">
          Carregando Ciclos de Evolução...
        </div>
      </section>
    )
  }

  if (errorMessage) {
    return (
      <section className="skpe-evolution">
        <div className="skpe-evolution-state skpe-evolution-state-error">
          <strong>
            Não foi possível carregar os
            Ciclos de Evolução.
          </strong>

          <span>{errorMessage}</span>

          <button
            type="button"
            onClick={() => void loadData()}
          >
            Tentar novamente
          </button>
        </div>
      </section>
    )
  }

  const horizon = data?.horizon ?? null
  const readiness =
    data?.readiness ?? null

  return (
    <section className="skpe-evolution">
      <header className="skpe-evolution-header">
        <div>
          <span className="skpe-evolution-eyebrow">
            Planejamento Estratégico
          </span>

          <h2>Ciclos de Evolução</h2>

          <p>
            Visualização governada do
            desdobramento temporal do
            Planejamento Estratégico, mantendo
            separadas a proposta de evolução e
            a institucionalização aprovada.
          </p>
        </div>

        <button
          type="button"
          className="skpe-evolution-refresh"
          onClick={() => void loadData()}
        >
          Atualizar
        </button>
      </header>

      <div className="skpe-evolution-semantic-note">
        <strong>
          Regra metodológica:
        </strong>

        <span>
          Cenário de Evolução é uma proposta
          para validação. Plano de Evolução é
          a versão institucionalizada. Os dois
          não são tratados como equivalentes.
        </span>
      </div>

      <div className="skpe-evolution-summary-grid">
        <article className="skpe-evolution-summary-card">
          <span>Horizonte Estratégico aprovado</span>

          <strong>
            {horizon
              ? `${horizon.horizon_start_year}–${horizon.horizon_end_year}`
              : 'Ainda não disponível'}
          </strong>

          <small>
            {horizon
              ? `Governança: ${statusLabel(
                  horizon.governance_status,
                )}`
              : 'O horizonte institucional deve ser definido antes da consolidação dos ciclos.'}
          </small>
        </article>

        <article className="skpe-evolution-summary-card">
          <span>
            Cenário de Evolução — proposta
            para validação
          </span>

          <strong>
            {currentScenario?.title ??
              'Nenhum cenário'}
          </strong>

          <small>
            {currentScenario
              ? `${currentScenarioCycles.length} ciclo(s) • ${statusLabel(
                  currentScenario.status,
                )}`
              : 'Ainda não há cenário de evolução registrado.'}
          </small>
        </article>

        <article className="skpe-evolution-summary-card">
          <span>
            Plano de Evolução —
            institucionalizado
          </span>

          <strong>
            {currentPlan
              ? `Versão ${currentPlan.version_number}`
              : 'Ainda não institucionalizado'}
          </strong>

          <small>
            {currentPlan
              ? `${currentPlanCycles.length} ciclo(s) • ${statusLabel(
                  currentPlan.governance_status,
                )}`
              : 'A aprovação do cenário precede a existência do Plano institucional.'}
          </small>
        </article>

        <article className="skpe-evolution-summary-card">
          <span>
            Prontidão Objetivos Estratégicos
            — OKRs
          </span>

          <strong>
            {readiness?.readyForClosure
              ? 'Pronto para fechamento'
              : 'Ainda requer tratamento'}
          </strong>

          <small>
            {readiness
              ? `${readiness.alignedObjectiveCount}/${readiness.objectiveCount} objetivo(s) alinhado(s)`
              : 'Readiness não disponível.'}
          </small>
        </article>
      </div>

      <div className="skpe-evolution-layout">
        <div className="skpe-evolution-timelines">
          <article className="skpe-evolution-panel">
            <header>
              <div>
                <span className="skpe-evolution-panel-kicker">
                  Proposta
                </span>

                <h3>
                  Cenário de Evolução
                </h3>
              </div>

              {currentScenario && (
                <span className="skpe-evolution-badge">
                  {statusLabel(
                    currentScenario.status,
                  )}
                </span>
              )}
            </header>

            {currentScenario ? (
              <>
                <p className="skpe-evolution-panel-description">
                  {currentScenario.description ??
                    currentScenario.strategic_rationale ??
                    'Cenário registrado sem descrição complementar.'}
                </p>

                <div className="skpe-evolution-cycle-list">
                  {currentScenarioCycles.map(
                    (cycle) => (
                      <button
                        key={cycle.id}
                        type="button"
                        className={[
                          'skpe-evolution-cycle-card',
                          selection?.kind ===
                            'scenario' &&
                          selection.cycle.id ===
                            cycle.id
                            ? 'is-selected'
                            : '',
                        ]
                          .filter(Boolean)
                          .join(' ')}
                        onClick={() =>
                          setSelection({
                            kind: 'scenario',
                            cycle,
                          })
                        }
                      >
                        <span>
                          Ciclo{' '}
                          {cycle.sequence_number}
                        </span>

                        <strong>
                          {cycle.title}
                        </strong>

                        <small>
                          {cyclePeriod(
                            cycle.period_start,
                            cycle.period_end,
                          )}
                        </small>
                      </button>
                    ),
                  )}

                  {currentScenarioCycles.length ===
                    0 && (
                    <div className="skpe-evolution-empty">
                      O cenário ainda não possui
                      ciclos cadastrados.
                    </div>
                  )}
                </div>
              </>
            ) : (
              <div className="skpe-evolution-empty">
                Nenhum Cenário de Evolução foi
                encontrado para este projeto.
              </div>
            )}
          </article>

          <article className="skpe-evolution-panel">
            <header>
              <div>
                <span className="skpe-evolution-panel-kicker">
                  Institucional
                </span>

                <h3>
                  Plano de Evolução
                </h3>
              </div>

              {currentPlan && (
                <span className="skpe-evolution-badge">
                  {statusLabel(
                    currentPlan.governance_status,
                  )}
                </span>
              )}
            </header>

            {currentPlan ? (
              <div className="skpe-evolution-cycle-list">
                {currentPlanCycles.map(
                  (cycle) => (
                    <button
                      key={cycle.id}
                      type="button"
                      className={[
                        'skpe-evolution-cycle-card',
                        selection?.kind ===
                          'institutional' &&
                        selection.cycle.id ===
                          cycle.id
                          ? 'is-selected'
                          : '',
                      ]
                        .filter(Boolean)
                        .join(' ')}
                      onClick={() =>
                        setSelection({
                          kind:
                            'institutional',
                          cycle,
                        })
                      }
                    >
                      <span>
                        Ciclo{' '}
                        {cycle.sequence_number}
                      </span>

                      <strong>
                        {cycle.title}
                      </strong>

                      <small>
                        {cyclePeriod(
                          cycle.period_start,
                          cycle.period_end,
                        )}
                      </small>
                    </button>
                  ),
                )}

                {currentPlanCycles.length ===
                  0 && (
                  <div className="skpe-evolution-empty">
                    O Plano institucional ainda
                    não possui ciclos
                    materializados.
                  </div>
                )}
              </div>
            ) : (
              <div className="skpe-evolution-empty">
                Ainda não existe Plano de
                Evolução institucionalizado.
                Isso não transforma o cenário
                proposto em plano aprovado.
              </div>
            )}
          </article>
        </div>

        <aside className="skpe-evolution-detail">
          <span className="skpe-evolution-panel-kicker">
            Drill-down do ciclo
          </span>

          {selection ? (
            <>
              <h3>
                {selection.cycle.title}
              </h3>

              <div className="skpe-evolution-detail-grid">
                <div>
                  <span>Natureza</span>
                  <strong>
                    {selection.kind ===
                    'scenario'
                      ? 'Ciclo proposto'
                      : 'Ciclo institucional'}
                  </strong>
                </div>

                <div>
                  <span>Período</span>
                  <strong>
                    {cyclePeriod(
                      selection.cycle
                        .period_start,
                      selection.cycle
                        .period_end,
                    )}
                  </strong>
                </div>
              </div>

              <dl className="skpe-evolution-definition-list">
                <div>
                  <dt>
                    Intenção estratégica
                  </dt>
                  <dd>
                    {selection.cycle
                      .strategic_intent ??
                      'Não informada'}
                  </dd>
                </div>

                <div>
                  <dt>
                    Resultado esperado
                  </dt>
                  <dd>
                    {selection.cycle
                      .expected_outcome ??
                      'Não informado'}
                  </dd>
                </div>

                <div>
                  <dt>
                    Foco estratégico
                  </dt>
                  <dd>
                    {readableJson(
                      selection.cycle
                        .strategic_focus,
                    )}
                  </dd>
                </div>

                <div>
                  <dt>
                    Critérios de entrada
                  </dt>
                  <dd>
                    {readableJson(
                      selection.cycle
                        .entry_criteria,
                    )}
                  </dd>
                </div>

                <div>
                  <dt>
                    Critérios de saída
                  </dt>
                  <dd>
                    {readableJson(
                      selection.cycle
                        .exit_criteria,
                    )}
                  </dd>
                </div>

                <div>
                  <dt>
                    Maturidade-alvo
                  </dt>
                  <dd>
                    {readableJson(
                      selection.cycle
                        .target_maturity,
                    )}
                  </dd>
                </div>
              </dl>
            </>
          ) : (
            <div className="skpe-evolution-empty">
              Selecione um ciclo para
              visualizar seus detalhes.
            </div>
          )}
        </aside>
      </div>

      {currentScenario && (
        <ObjectiveEvolutionAlignmentEditor
          organizationId={
            currentScenario.organization_id
          }
          projectId={projectId}
          scenarioId={currentScenario.id}
          scenarioStatus={
            currentScenario.status
          }
          scenarioCycles={
            currentScenarioCycles
          }
          onChanged={loadData}
        />
      )}

      <article className="skpe-evolution-readiness">
        <header>
          <div>
            <span className="skpe-evolution-panel-kicker">
              Governança
            </span>

            <h3>
              Prontidão do alinhamento
              Objetivo–Ciclo
            </h3>
          </div>

          <span
            className={[
              'skpe-evolution-badge',
              readiness?.readyForClosure
                ? 'is-positive'
                : 'is-warning',
            ].join(' ')}
          >
            {readiness?.readyForClosure
              ? 'Pronto'
              : 'Pendente'}
          </span>
        </header>

        {readiness ? (
          <>
            <div className="skpe-evolution-readiness-metrics">
              <div>
                <strong>
                  {readiness.objectiveCount}
                </strong>
                <span>
                  Objetivos Estratégicos — OKRs
                </span>
              </div>

              <div>
                <strong>
                  {
                    readiness.alignedObjectiveCount
                  }
                </strong>
                <span>
                  Objetivos alinhados
                </span>
              </div>

              <div>
                <strong>
                  {readiness.alignmentCount}
                </strong>
                <span>
                  Alinhamentos propostos
                </span>
              </div>

              <div>
                <strong>
                  {
                    readiness.materializableAlignmentCount
                  }
                </strong>
                <span>
                  Alinhamentos materializáveis
                </span>
              </div>
            </div>

            {readiness.missingObjectives.length >
              0 && (
              <div className="skpe-evolution-warning-block">
                <strong>
                  Objetivos ainda sem alinhamento
                </strong>

                <ul>
                  {readiness.missingObjectives.map(
                    (objective) => (
                      <li key={objective.id}>
                        {objective.code} —{' '}
                        {objective.name}
                      </li>
                    ),
                  )}
                </ul>
              </div>
            )}

            {readiness.issues.length > 0 && (
              <div className="skpe-evolution-warning-block">
                <strong>
                  Pendências de governança
                </strong>

                <ul>
                  {readiness.issues.map(
                    (issue, index) => (
                      <li
                        key={`${
                          issue.code ??
                          'issue'
                        }-${index}`}
                      >
                        {issue.message ??
                          issue.code ??
                          'Pendência identificada pelo backend.'}
                      </li>
                    ),
                  )}
                </ul>
              </div>
            )}

            {!readiness.readyForClosure &&
              readiness.issues.length ===
                0 && (
                <div className="skpe-evolution-empty">
                  O fechamento ainda não está
                  liberado. Isso pode ocorrer
                  enquanto não houver Formulação
                  aprovada e Plano de Evolução
                  corrente.
                </div>
              )}
          </>
        ) : (
          <div className="skpe-evolution-empty">
            Readiness ainda não disponível.
          </div>
        )}
      </article>

      <footer className="skpe-evolution-footer-note">
        Esta visualização não materializa
        alinhamentos institucionais e não
        executa o PEM-02.GATE. A fonte de
        verdade para prontidão permanece no
        backend governado do SK-PE.
      </footer>
    </section>
  )
}