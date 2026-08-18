import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react'

import { translateBackendMessage } from '../../../../shared/i18n/ptBR'

import type {
  EvolutionAlignmentRole,
  EvolutionScenarioCycleRow,
  ObjectiveEvolutionScenarioAlignmentRow,
} from '../../contracts/evolution'

import {
  canManageObjectiveEvolutionAlignment,
  deleteObjectiveEvolutionScenarioAlignment,
  loadObjectiveEvolutionAlignmentEditorData,
  saveObjectiveEvolutionScenarioAlignment,
  type ObjectiveEvolutionAlignmentEditorData,
} from './evolutionData'

import './ObjectiveEvolutionAlignmentEditor.css'

type ObjectiveEvolutionAlignmentEditorProps = {
  organizationId: string
  projectId: string
  scenarioId: string
  scenarioStatus: string
  scenarioCycles: EvolutionScenarioCycleRow[]
  onChanged: () => Promise<void>
}

type AlignmentFormState = {
  alignmentId: string | null
  strategicObjectiveId: string
  scenarioCycleId: string
  alignmentRole: EvolutionAlignmentRole
  contributionWeight: string
  expectedResultInCycle: string
  rationale: string
  changeReason: string
}

const emptyForm: AlignmentFormState = {
  alignmentId: null,
  strategicObjectiveId: '',
  scenarioCycleId: '',
  alignmentRole: 'primary',
  contributionWeight: '',
  expectedResultInCycle: '',
  rationale: '',
  changeReason: '',
}

const roleLabels: Record<
  EvolutionAlignmentRole,
  string
> = {
  primary: 'Primário',
  supporting: 'Suporte',
  sustaining: 'Sustentação',
}

const validationLabels: Record<string, string> = {
  draft: 'Proposto',
  pending_validation: 'Em validação',
  validated: 'Validado para o cenário',
  rejected: 'Rejeitado',
}

function validationLabel(value: string) {
  return validationLabels[value] ?? value
}

function parseWeight(value: string) {
  if (!value.trim()) return null

  const parsed = Number(
    value.replace(',', '.'),
  )

  return Number.isFinite(parsed)
    ? parsed
    : null
}

export function ObjectiveEvolutionAlignmentEditor({
  organizationId,
  projectId,
  scenarioId,
  scenarioStatus,
  scenarioCycles,
  onChanged,
}: ObjectiveEvolutionAlignmentEditorProps) {
  const [canManage, setCanManage] =
    useState(false)

  const [capabilityLoading, setCapabilityLoading] =
    useState(true)

  const [loading, setLoading] =
    useState(false)

  const [saving, setSaving] =
    useState(false)

  const [errorMessage, setErrorMessage] =
    useState('')

  const [successMessage, setSuccessMessage] =
    useState('')

  const [data, setData] =
    useState<ObjectiveEvolutionAlignmentEditorData | null>(
      null,
    )

  const [selectedCycleId, setSelectedCycleId] =
    useState('')

  const [form, setForm] =
    useState<AlignmentFormState>(emptyForm)

  const scenarioEditable =
    scenarioStatus === 'draft' ||
    scenarioStatus === 'adjusted'

  const loadEditor = useCallback(async () => {
    setCapabilityLoading(true)
    setErrorMessage('')

    try {
      const permitted =
        await canManageObjectiveEvolutionAlignment(
          organizationId,
        )

      setCanManage(permitted)

      if (!permitted) {
        setData(null)
        return
      }

      setLoading(true)

      const result =
        await loadObjectiveEvolutionAlignmentEditorData(
          projectId,
          scenarioId,
        )

      setData(result)
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : String(error)

      setErrorMessage(
        translateBackendMessage(message),
      )

      setData(null)
    } finally {
      setLoading(false)
      setCapabilityLoading(false)
    }
  }, [
    organizationId,
    projectId,
    scenarioId,
  ])

  useEffect(() => {
    void loadEditor()
  }, [loadEditor])

  useEffect(() => {
    if (
      selectedCycleId &&
      scenarioCycles.some(
        (cycle) =>
          cycle.id === selectedCycleId,
      )
    ) {
      return
    }

    setSelectedCycleId(
      scenarioCycles[0]?.id ?? '',
    )
  }, [
    scenarioCycles,
    selectedCycleId,
  ])

  useEffect(() => {
    setForm((current) => ({
      ...current,
      scenarioCycleId:
        selectedCycleId,
    }))
  }, [selectedCycleId])

  const objectiveById = useMemo(
    () =>
      new Map(
        (data?.objectives ?? []).map(
          (objective) => [
            objective.id,
            objective,
          ],
        ),
      ),
    [data],
  )

  const cycleAlignments = useMemo(
    () =>
      (data?.alignments ?? []).filter(
        (alignment) =>
          alignment.scenario_cycle_id ===
          selectedCycleId,
      ),
    [
      data,
      selectedCycleId,
    ],
  )

  const alignedObjectiveIds = useMemo(
    () =>
      new Set(
        cycleAlignments.map(
          (alignment) =>
            alignment.strategic_objective_id,
        ),
      ),
    [cycleAlignments],
  )

  const selectableObjectives = useMemo(
    () =>
      (data?.objectives ?? []).filter(
        (objective) =>
          !alignedObjectiveIds.has(
            objective.id,
          ) ||
          objective.id ===
            form.strategicObjectiveId,
      ),
    [
      alignedObjectiveIds,
      data,
      form.strategicObjectiveId,
    ],
  )

  function resetForm() {
    setForm({
      ...emptyForm,
      scenarioCycleId:
        selectedCycleId,
    })

    setErrorMessage('')
    setSuccessMessage('')
  }

  function editAlignment(
    alignment:
      ObjectiveEvolutionScenarioAlignmentRow,
  ) {
    setSelectedCycleId(
      alignment.scenario_cycle_id,
    )

    setForm({
      alignmentId:
        alignment.id,

      strategicObjectiveId:
        alignment.strategic_objective_id,

      scenarioCycleId:
        alignment.scenario_cycle_id,

      alignmentRole:
        alignment.alignment_role,

      contributionWeight:
        alignment.contribution_weight === null
          ? ''
          : String(
              alignment.contribution_weight,
            ),

      expectedResultInCycle:
        alignment.expected_result_in_cycle ??
        '',

      rationale:
        alignment.rationale ?? '',

      changeReason: '',
    })

    setErrorMessage('')
    setSuccessMessage('')
  }

  async function reloadAfterMutation() {
    await loadEditor()
    await onChanged()
  }

  async function handleSave() {
    if (
      !canManage ||
      !scenarioEditable
    ) {
      return
    }

    if (!data?.formulationId) {
      setErrorMessage(
        'Não existe Formulação Estratégica disponível para o alinhamento.',
      )
      return
    }

    if (
      !form.strategicObjectiveId ||
      !form.scenarioCycleId
    ) {
      setErrorMessage(
        'Selecione o Objetivo Estratégico — OKR e o Ciclo de Evolução.',
      )
      return
    }

    if (!form.changeReason.trim()) {
      setErrorMessage(
        'Informe o motivo da alteração para preservar a rastreabilidade.',
      )
      return
    }

    const contributionWeight =
      parseWeight(
        form.contributionWeight,
      )

    if (
      form.contributionWeight.trim() &&
      contributionWeight === null
    ) {
      setErrorMessage(
        'Informe um peso de contribuição válido.',
      )
      return
    }

    setSaving(true)
    setErrorMessage('')
    setSuccessMessage('')

    try {
      await saveObjectiveEvolutionScenarioAlignment({
        formulationId:
          data.formulationId,

        strategicObjectiveId:
          form.strategicObjectiveId,

        scenarioCycleId:
          form.scenarioCycleId,

        alignmentId:
          form.alignmentId,

        alignmentRole:
          form.alignmentRole,

        contributionWeight,

        expectedResultInCycle:
          form.expectedResultInCycle,

        rationale:
          form.rationale,

        changeReason:
          form.changeReason,
      })

      resetForm()

      setSuccessMessage(
        'Alinhamento proposto salvo com rastreabilidade.',
      )

      await reloadAfterMutation()
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : String(error)

      setErrorMessage(
        translateBackendMessage(message),
      )
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete() {
    if (
      !form.alignmentId ||
      !canManage ||
      !scenarioEditable
    ) {
      return
    }

    if (!form.changeReason.trim()) {
      setErrorMessage(
        'Informe o motivo da remoção para preservar a rastreabilidade.',
      )
      return
    }

    const confirmed = window.confirm(
      'Remover este alinhamento proposto? A operação será registrada na auditoria.',
    )

    if (!confirmed) return

    setSaving(true)
    setErrorMessage('')
    setSuccessMessage('')

    try {
      await deleteObjectiveEvolutionScenarioAlignment(
        form.alignmentId,
        form.changeReason,
      )

      resetForm()

      setSuccessMessage(
        'Alinhamento proposto removido com rastreabilidade.',
      )

      await reloadAfterMutation()
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : String(error)

      setErrorMessage(
        translateBackendMessage(message),
      )
    } finally {
      setSaving(false)
    }
  }

  return (
    <article className="skpe-evolution-alignment-editor">
      <header className="skpe-evolution-alignment-editor-header">
        <div>
          <span className="skpe-evolution-panel-kicker">
            Formulação governada
          </span>

          <h3>
            Alinhamento dos Objetivos Estratégicos — OKRs
          </h3>

          <p>
            Organize como cada Objetivo contribui
            para os Ciclos do Cenário de Evolução.
            Este alinhamento permanece proposto até
            a decisão institucional do PEM-02.GATE.
          </p>
        </div>

        {canManage && (
          <span className="skpe-evolution-badge">
            Gestão autorizada
          </span>
        )}
      </header>

      <div className="skpe-evolution-alignment-rule">
        <strong>
          Proposta ≠ institucionalização
        </strong>

        <span>
          Salvar ou validar um alinhamento nesta
          área não cria o alinhamento institucional
          do Plano de Evolução.
        </span>
      </div>

      {capabilityLoading ? (
        <div className="skpe-evolution-empty">
          Verificando permissões de gestão...
        </div>
      ) : !canManage ? (
        <div className="skpe-evolution-empty">
          A visualização dos Ciclos permanece
          disponível, mas seu perfil não possui a
          combinação de permissões necessária para
          gerir os alinhamentos Objetivo–Ciclo.
        </div>
      ) : loading ? (
        <div className="skpe-evolution-empty">
          Carregando alinhamentos propostos...
        </div>
      ) : (
        <>
          {!scenarioEditable && (
            <div className="skpe-evolution-warning-block">
              <strong>
                Cenário protegido contra edição
              </strong>

              <p>
                O cenário está em estado que não
                permite alterar alinhamentos.
                Somente cenários em Rascunho ou
                Ajustado podem ser editados.
              </p>
            </div>
          )}

          {!data?.formulationId && (
            <div className="skpe-evolution-warning-block">
              <strong>
                Formulação Estratégica não disponível
              </strong>

              <p>
                Não há versão de Formulação para
                associar aos Ciclos deste cenário.
              </p>
            </div>
          )}

          {errorMessage && (
            <div className="skpe-evolution-alignment-message is-error">
              {errorMessage}
            </div>
          )}

          {successMessage && (
            <div className="skpe-evolution-alignment-message">
              {successMessage}
            </div>
          )}

          <div className="skpe-evolution-alignment-layout">
            <section className="skpe-evolution-alignment-cycles">
              <h4>
                1. Selecione o Ciclo
              </h4>

              <div className="skpe-evolution-alignment-cycle-list">
                {scenarioCycles.map(
                  (cycle) => {
                    const count =
                      (data?.alignments ?? [])
                        .filter(
                          (alignment) =>
                            alignment.scenario_cycle_id ===
                            cycle.id,
                        ).length

                    return (
                      <button
                        key={cycle.id}
                        type="button"
                        className={[
                          'skpe-evolution-alignment-cycle',
                          selectedCycleId ===
                          cycle.id
                            ? 'is-selected'
                            : '',
                        ]
                          .filter(Boolean)
                          .join(' ')}
                        onClick={() => {
                          setSelectedCycleId(
                            cycle.id,
                          )
                          resetForm()
                        }}
                      >
                        <span>
                          Ciclo{' '}
                          {cycle.sequence_number}
                        </span>

                        <strong>
                          {cycle.title}
                        </strong>

                        <small>
                          {count}{' '}
                          alinhamento(s)
                        </small>
                      </button>
                    )
                  },
                )}
              </div>
            </section>

            <section className="skpe-evolution-alignment-current">
              <div className="skpe-evolution-alignment-current-header">
                <div>
                  <h4>
                    2. Objetivos alinhados
                  </h4>

                  <span>
                    Clique em Editar para revisar
                    papel, peso, resultado e racional.
                  </span>
                </div>

                {scenarioEditable && (
                  <button
                    type="button"
                    className="skpe-evolution-alignment-secondary"
                    onClick={resetForm}
                  >
                    + Associar objetivo
                  </button>
                )}
              </div>

              {cycleAlignments.length > 0 ? (
                <div className="skpe-evolution-alignment-list">
                  {cycleAlignments.map(
                    (alignment) => {
                      const objective =
                        objectiveById.get(
                          alignment.strategic_objective_id,
                        )

                      return (
                        <article
                          key={alignment.id}
                          className="skpe-evolution-alignment-card"
                        >
                          <div>
                            <span>
                              {objective?.code ??
                                'Objetivo'}
                            </span>

                            <strong>
                              {objective?.name ??
                                'Objetivo não localizado'}
                            </strong>
                          </div>

                          <div className="skpe-evolution-alignment-card-meta">
                            <span>
                              {
                                roleLabels[
                                  alignment.alignment_role
                                ]
                              }
                            </span>

                            <span>
                              Peso:{' '}
                              {alignment.contribution_weight ??
                                '—'}
                              {alignment.contribution_weight !==
                              null
                                ? '%'
                                : ''}
                            </span>

                            <span>
                              {validationLabel(
                                alignment.validation_status,
                              )}
                            </span>
                          </div>

                          {scenarioEditable && (
                            <button
                              type="button"
                              className="skpe-evolution-alignment-secondary"
                              onClick={() =>
                                editAlignment(
                                  alignment,
                                )
                              }
                            >
                              Editar
                            </button>
                          )}
                        </article>
                      )
                    },
                  )}
                </div>
              ) : (
                <div className="skpe-evolution-empty">
                  Nenhum Objetivo está alinhado ao
                  Ciclo selecionado.
                </div>
              )}
            </section>
          </div>

          {scenarioEditable &&
            data?.formulationId && (
            <section className="skpe-evolution-alignment-form">
              <header>
                <div>
                  <span className="skpe-evolution-panel-kicker">
                    Registro proposto
                  </span>

                  <h4>
                    {form.alignmentId
                      ? 'Editar alinhamento'
                      : 'Associar Objetivo ao Ciclo'}
                  </h4>
                </div>
              </header>

              <div className="skpe-evolution-alignment-fields">
                <label>
                  <span>
                    Objetivo Estratégico — OKR
                  </span>

                  <select
                    value={
                      form.strategicObjectiveId
                    }
                    onChange={(event) =>
                      setForm((current) => ({
                        ...current,
                        strategicObjectiveId:
                          event.target.value,
                      }))
                    }
                  >
                    <option value="">
                      Selecione
                    </option>

                    {selectableObjectives.map(
                      (objective) => (
                        <option
                          key={objective.id}
                          value={objective.id}
                        >
                          {objective.code} —{' '}
                          {objective.name}
                        </option>
                      ),
                    )}
                  </select>
                </label>

                <label>
                  <span>
                    Papel no Ciclo
                  </span>

                  <select
                    value={
                      form.alignmentRole
                    }
                    onChange={(event) =>
                      setForm((current) => ({
                        ...current,
                        alignmentRole:
                          event.target
                            .value as EvolutionAlignmentRole,
                      }))
                    }
                  >
                    <option value="primary">
                      Primário
                    </option>
                    <option value="supporting">
                      Suporte
                    </option>
                    <option value="sustaining">
                      Sustentação
                    </option>
                  </select>
                </label>

                <label>
                  <span>
                    Peso de contribuição (%)
                  </span>

                  <input
                    type="number"
                    min="0"
                    max="100"
                    step="0.01"
                    value={
                      form.contributionWeight
                    }
                    onChange={(event) =>
                      setForm((current) => ({
                        ...current,
                        contributionWeight:
                          event.target.value,
                      }))
                    }
                  />
                </label>

                <label className="is-wide">
                  <span>
                    Resultado esperado no Ciclo
                  </span>

                  <textarea
                    rows={3}
                    value={
                      form.expectedResultInCycle
                    }
                    onChange={(event) =>
                      setForm((current) => ({
                        ...current,
                        expectedResultInCycle:
                          event.target.value,
                      }))
                    }
                  />
                </label>

                <label className="is-wide">
                  <span>
                    Racional do alinhamento
                  </span>

                  <textarea
                    rows={3}
                    value={form.rationale}
                    onChange={(event) =>
                      setForm((current) => ({
                        ...current,
                        rationale:
                          event.target.value,
                      }))
                    }
                  />
                </label>

                <label className="is-wide">
                  <span>
                    Motivo da alteração *
                  </span>

                  <textarea
                    rows={2}
                    required
                    value={
                      form.changeReason
                    }
                    onChange={(event) =>
                      setForm((current) => ({
                        ...current,
                        changeReason:
                          event.target.value,
                      }))
                    }
                    placeholder="Registre por que este alinhamento está sendo criado, alterado ou removido."
                  />
                </label>
              </div>

              <div className="skpe-evolution-alignment-actions">
                <button
                  type="button"
                  className="skpe-evolution-alignment-primary"
                  disabled={saving}
                  onClick={() =>
                    void handleSave()
                  }
                >
                  {saving
                    ? 'Salvando...'
                    : form.alignmentId
                      ? 'Salvar alteração'
                      : 'Criar alinhamento proposto'}
                </button>

                <button
                  type="button"
                  className="skpe-evolution-alignment-secondary"
                  disabled={saving}
                  onClick={resetForm}
                >
                  Limpar
                </button>

                {form.alignmentId && (
                  <button
                    type="button"
                    className="skpe-evolution-alignment-danger"
                    disabled={saving}
                    onClick={() =>
                      void handleDelete()
                    }
                  >
                    Remover alinhamento
                  </button>
                )}
              </div>
            </section>
          )}
        </>
      )}
    </article>
  )
}