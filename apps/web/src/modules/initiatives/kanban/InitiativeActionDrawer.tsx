import {
  useEffect,
  useState,
} from 'react'

import {
  canManageInitiativeActionResponsibilities,
  canUpdateInitiativeActionEconomics,
  canUpdateInitiativeActionProgress,
  initiativeActionEffortUnitLabels,
  initiativeActionEffortUnits,
  initiativeActionLifecycleLabels,
  initiativeActionPriorityLabels,
  formatInitiativeActionResponsibilityType,
  validateInitiativeActionEconomics,
  validateInitiativeActionResponsibilityAssignment,
  type InitiativeActionDomainOption,
  type InitiativeActionResponsibility,
  type InitiativeActionResponsibilityCandidate,
  type InitiativeKanbanCardModel,
} from '../contracts/initiativeActions'
import {
  assignInitiativeActionResponsibility,
  endInitiativeActionResponsibility,
  loadInitiativeActionResponsibilities,
  loadInitiativeActionResponsibilityCandidates,
  loadInitiativeActionResponsibilityDomains,
  updateInitiativeActionEconomics,
  updateInitiativeActionProgress,
} from '../data/initiativeActionsData'
import {
  InitiativeLifecycleDialog,
} from './InitiativeLifecycleDialog'

type InitiativeActionDrawerProps = {
  card: InitiativeKanbanCardModel
  onClose: () => void
  onChanged: () => Promise<void>
}

function formatProgress(value: number) {
  return `${new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 1,
  }).format(value)}%`
}

function formatDate(value: string | null) {
  if (!value) return 'Não definida'

  const [year, month, day] =
    value.slice(0, 10).split('-')

  if (!year || !month || !day) {
    return value
  }

  return `${day}/${month}/${year}`
}

function numberToInputValue(
  value: number | null,
) {
  return value === null
    ? ''
    : String(value)
}

export function InitiativeActionDrawer({
  card,
  onClose,
  onChanged,
}: InitiativeActionDrawerProps) {
  const [showLifecycle, setShowLifecycle] =
    useState(false)
  const [progress, setProgress] = useState(
    String(card.officialProgress),
  )
  const [changeReason, setChangeReason] =
    useState('')
  const [savingProgress, setSavingProgress] =
    useState(false)

  const [plannedCost, setPlannedCost] =
    useState(
      numberToInputValue(card.plannedCost),
    )
  const [actualCost, setActualCost] =
    useState(
      numberToInputValue(card.actualCost),
    )
  const [currencyCode, setCurrencyCode] =
    useState(card.currencyCode)
  const [
    estimatedEffort,
    setEstimatedEffort,
  ] = useState(
    numberToInputValue(
      card.estimatedEffort,
    ),
  )
  const [actualEffort, setActualEffort] =
    useState(
      numberToInputValue(card.actualEffort),
    )
  const [effortUnit, setEffortUnit] =
    useState(card.effortUnit ?? '')
  const [
    economicChangeReason,
    setEconomicChangeReason,
  ] = useState('')
  const [
    savingEconomics,
    setSavingEconomics,
  ] = useState(false)

  const [
    responsibilities,
    setResponsibilities,
  ] = useState<
    InitiativeActionResponsibility[]
  >([])
  const [
    responsibilitiesLoading,
    setResponsibilitiesLoading,
  ] = useState(true)
  const [
    responsibilitiesError,
    setResponsibilitiesError,
  ] = useState<string | null>(null)
  const [
    responsibilityCandidates,
    setResponsibilityCandidates,
  ] = useState<
    InitiativeActionResponsibilityCandidate[]
  >([])
  const [
    responsibilityTypes,
    setResponsibilityTypes,
  ] = useState<InitiativeActionDomainOption[]>(
    [],
  )
  const [
    authorityLevels,
    setAuthorityLevels,
  ] = useState<InitiativeActionDomainOption[]>(
    [],
  )
  const [
    responsibilityReferenceLoading,
    setResponsibilityReferenceLoading,
  ] = useState(true)
  const [
    responsibilityReferenceError,
    setResponsibilityReferenceError,
  ] = useState<string | null>(null)

  const [
    selectedOrganizationPersonId,
    setSelectedOrganizationPersonId,
  ] = useState('')
  const [
    selectedResponsibilityType,
    setSelectedResponsibilityType,
  ] = useState('')
  const [
    responsibilityAllocation,
    setResponsibilityAllocation,
  ] = useState('')
  const [
    selectedAuthorityLevel,
    setSelectedAuthorityLevel,
  ] = useState('')
  const [
    responsibilityValidFrom,
    setResponsibilityValidFrom,
  ] = useState('')
  const [
    responsibilityValidUntil,
    setResponsibilityValidUntil,
  ] = useState('')
  const [
    responsibilityAssignmentReason,
    setResponsibilityAssignmentReason,
  ] = useState('')
  const [
    responsibilityChangeReason,
    setResponsibilityChangeReason,
  ] = useState('')
  const [
    savingResponsibility,
    setSavingResponsibility,
  ] = useState(false)
  const [
    endingAssignmentId,
    setEndingAssignmentId,
  ] = useState<string | null>(null)

  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)

  const progressEditable =
    canUpdateInitiativeActionProgress(
      card.status,
    )

  const economicsEditable =
    canUpdateInitiativeActionEconomics(
      card.status,
    )

  const responsibilitiesManageable =
    canManageInitiativeActionResponsibilities(
      card.status,
    )

  const saving =
    savingProgress ||
    savingEconomics ||
    savingResponsibility ||
    endingAssignmentId !== null

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (
        event.key === 'Escape' &&
        !showLifecycle &&
        !saving
      ) {
        onClose()
      }
    }

    window.addEventListener(
      'keydown',
      handleKeyDown,
    )

    return () => {
      window.removeEventListener(
        'keydown',
        handleKeyDown,
      )
    }
  }, [
    onClose,
    saving,
    showLifecycle,
  ])

  useEffect(() => {
    let cancelled = false

    setResponsibilitiesLoading(true)
    setResponsibilitiesError(null)

    void loadInitiativeActionResponsibilities(
      card.actionId,
    )
      .then((items) => {
        if (cancelled) return
        setResponsibilities(items)
      })
      .catch((error) => {
        if (cancelled) return

        setResponsibilities([])
        setResponsibilitiesError(
          error instanceof Error
            ? error.message
            : 'Não foi possível carregar os responsáveis da ação.',
        )
      })
      .finally(() => {
        if (cancelled) return
        setResponsibilitiesLoading(false)
      })

    return () => {
      cancelled = true
    }
  }, [card.actionId])

  useEffect(() => {
    let cancelled = false

    setResponsibilityReferenceLoading(true)
    setResponsibilityReferenceError(null)

    void Promise.all([
      loadInitiativeActionResponsibilityCandidates(
        card.organizationId,
      ),
      loadInitiativeActionResponsibilityDomains(
        card.organizationId,
      ),
    ])
      .then(([candidates, domains]) => {
        if (cancelled) return

        setResponsibilityCandidates(candidates)
        setResponsibilityTypes(
          domains.responsibilityTypes,
        )
        setAuthorityLevels(
          domains.authorityLevels,
        )
      })
      .catch((error) => {
        if (cancelled) return

        setResponsibilityCandidates([])
        setResponsibilityTypes([])
        setAuthorityLevels([])
        setResponsibilityReferenceError(
          error instanceof Error
            ? error.message
            : 'Não foi possível carregar os dados para atribuição de responsabilidades.',
        )
      })
      .finally(() => {
        if (cancelled) return
        setResponsibilityReferenceLoading(false)
      })

    return () => {
      cancelled = true
    }
  }, [card.organizationId])

  async function reloadResponsibilities() {
    const items =
      await loadInitiativeActionResponsibilities(
        card.actionId,
      )

    setResponsibilities(items)
    setResponsibilitiesError(null)
  }

  async function handleAssignResponsibility() {
    if (!responsibilitiesManageable) {
      setErrorMessage(
        'Não é possível atribuir novas responsabilidades a uma ação encerrada.',
      )
      return
    }

    const validation =
      validateInitiativeActionResponsibilityAssignment({
        organizationPersonId:
          selectedOrganizationPersonId,
        responsibilityType:
          selectedResponsibilityType,
        allocationPercentage:
          responsibilityAllocation,
        authorityLevel:
          selectedAuthorityLevel,
        validFrom: responsibilityValidFrom,
        validUntil:
          responsibilityValidUntil,
        assignmentReason:
          responsibilityAssignmentReason,
        changeReason:
          responsibilityChangeReason,
      })

    if (!validation.ok) {
      setErrorMessage(validation.message)
      return
    }

    setSavingResponsibility(true)
    setErrorMessage(null)

    try {
      await assignInitiativeActionResponsibility(
        card.actionId,
        validation.value,
      )
      await reloadResponsibilities()

      setSelectedOrganizationPersonId('')
      setSelectedResponsibilityType('')
      setResponsibilityAllocation('')
      setSelectedAuthorityLevel('')
      setResponsibilityValidFrom('')
      setResponsibilityValidUntil('')
      setResponsibilityAssignmentReason('')
      setResponsibilityChangeReason('')
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível atribuir a responsabilidade.',
      )
    } finally {
      setSavingResponsibility(false)
    }
  }

  async function handleEndResponsibility(
    assignmentId: string,
  ) {
    const reason =
      window.prompt(
        'Justificativa para encerrar a responsabilidade (mínimo 10 caracteres):',
      )?.trim() ?? ''

    if (!reason) return

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa com pelo menos 10 caracteres.',
      )
      return
    }

    setEndingAssignmentId(assignmentId)
    setErrorMessage(null)

    try {
      await endInitiativeActionResponsibility(
        assignmentId,
        null,
        reason,
      )
      await reloadResponsibilities()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível encerrar a responsabilidade.',
      )
    } finally {
      setEndingAssignmentId(null)
    }
  }

  async function handleProgressUpdate() {
    const parsedProgress = Number(progress)
    const reason = changeReason.trim()

    if (
      !Number.isFinite(parsedProgress) ||
      parsedProgress < 0 ||
      parsedProgress >= 100
    ) {
      setErrorMessage(
        'Informe progresso entre 0 e menor que 100. A conclusão ocorre pela situação da ação.',
      )
      return
    }

    if (reason.length < 10) {
      setErrorMessage(
        'Informe uma justificativa com pelo menos 10 caracteres.',
      )
      return
    }

    if (
      parsedProgress === card.officialProgress
    ) {
      setErrorMessage(
        'Informe um progresso diferente do valor oficial atual.',
      )
      return
    }

    setSavingProgress(true)
    setErrorMessage(null)

    try {
      await updateInitiativeActionProgress(
        card.actionId,
        parsedProgress,
        reason,
      )

      await onChanged()
      onClose()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível atualizar o progresso.',
      )
    } finally {
      setSavingProgress(false)
    }
  }

  async function handleEconomicsUpdate() {
    if (!economicsEditable) {
      setErrorMessage(
        'A execução econômica não pode ser alterada em uma ação encerrada.',
      )
      return
    }

    const validation =
      validateInitiativeActionEconomics({
        plannedCost,
        actualCost,
        currencyCode,
        estimatedEffort,
        actualEffort,
        effortUnit,
        changeReason:
          economicChangeReason,
      })

    if (!validation.ok) {
      setErrorMessage(validation.message)
      return
    }

    const next = validation.value

    if (
      next.plannedCost === card.plannedCost &&
      next.actualCost === card.actualCost &&
      next.currencyCode ===
        card.currencyCode.toUpperCase() &&
      next.estimatedEffort ===
        card.estimatedEffort &&
      next.actualEffort ===
        card.actualEffort &&
      next.effortUnit === card.effortUnit
    ) {
      setErrorMessage(
        'Informe ao menos uma alteração econômica efetiva.',
      )
      return
    }

    setSavingEconomics(true)
    setErrorMessage(null)

    try {
      await updateInitiativeActionEconomics(
        card.actionId,
        next,
      )

      await onChanged()
      onClose()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Não foi possível atualizar a execução econômica.',
      )
    } finally {
      setSavingEconomics(false)
    }
  }

  return (
    <>
      <div
        className="initiative-action-drawer-backdrop"
        role="presentation"
        onMouseDown={(event) => {
          if (
            event.target === event.currentTarget &&
            !saving
          ) {
            onClose()
          }
        }}
      >
        <aside
          className="initiative-action-drawer"
          role="dialog"
          aria-modal="true"
          aria-labelledby="initiative-action-drawer-title"
        >
          <header className="initiative-action-drawer__header">
            <div>
              <span>
                {card.actionType === 'milestone'
                  ? 'Marco'
                  : 'Ação'}
              </span>
              <h2 id="initiative-action-drawer-title">
                {card.code} — {card.name}
              </h2>
            </div>

            <button
              type="button"
              onClick={onClose}
              disabled={saving}
              aria-label="Fechar detalhes da ação"
            >
              Fechar
            </button>
          </header>

          {card.description ? (
            <p className="initiative-action-drawer__description">
              {card.description}
            </p>
          ) : null}

          <dl className="initiative-action-drawer__facts">
            <div>
              <dt>Situação</dt>
              <dd>
                {
                  initiativeActionLifecycleLabels[
                    card.status
                  ]
                }
              </dd>
            </div>

            <div>
              <dt>Prioridade</dt>
              <dd>
                {
                  initiativeActionPriorityLabels[
                    card.priority
                  ]
                }
              </dd>
            </div>

            <div>
              <dt>Início planejado</dt>
              <dd>
                {formatDate(
                  card.plannedStartDate,
                )}
              </dd>
            </div>

            <div>
              <dt>Prazo planejado</dt>
              <dd>
                {formatDate(
                  card.plannedDueDate,
                )}
              </dd>
            </div>

            <div>
              <dt>Progresso oficial</dt>
              <dd>
                {formatProgress(
                  card.officialProgress,
                )}
              </dd>
            </div>

            <div>
              <dt>Progresso calculado</dt>
              <dd>
                {card.calculatedProgress === null
                  ? 'Não aplicável'
                  : formatProgress(
                      card.calculatedProgress,
                    )}
              </dd>
            </div>
          </dl>

          <section className="initiative-action-drawer__section">
            <h3>Responsáveis</h3>

            {responsibilitiesLoading ? (
              <p>Carregando responsáveis...</p>
            ) : responsibilitiesError ? (
              <div
                className="initiative-action-message initiative-action-message--error"
                role="alert"
              >
                {responsibilitiesError}
              </div>
            ) : responsibilities.length === 0 ? (
              <p>
                Nenhuma responsabilidade ativa foi
                atribuída a esta ação.
              </p>
            ) : (
              <dl className="initiative-action-drawer__facts">
                {responsibilities.map(
                  (responsibility) => (
                    <div
                      key={
                        responsibility.assignmentId
                      }
                    >
                      <dt>
                        {formatInitiativeActionResponsibilityType(
                          responsibility.responsibilityType,
                        )}
                      </dt>
                      <dd>
                        {responsibility.personName}
                      </dd>

                      {responsibility.jobTitle ? (
                        <small>
                          {
                            responsibility.jobTitle
                          }
                        </small>
                      ) : null}

                      {responsibility.organizationalArea ? (
                        <small>
                          Área:{' '}
                          {
                            responsibility.organizationalArea
                          }
                        </small>
                      ) : null}

                      {responsibility.allocationPercentage !==
                      null ? (
                        <small>
                          Alocação:{' '}
                          {new Intl.NumberFormat(
                            'pt-BR',
                            {
                              maximumFractionDigits: 2,
                            },
                          ).format(
                            responsibility.allocationPercentage,
                          )}
                          %
                        </small>
                      ) : null}

                      {responsibility.validFrom ||
                      responsibility.validUntil ? (
                        <small>
                          Vigência:{' '}
                          {formatDate(
                            responsibility.validFrom,
                          )}
                          {' — '}
                          {formatDate(
                            responsibility.validUntil,
                          )}
                        </small>
                      ) : null}

                      {responsibilitiesManageable ? (
                        <button
                          type="button"
                          onClick={() =>
                            void handleEndResponsibility(
                              responsibility.assignmentId,
                            )
                          }
                          disabled={saving}
                        >
                          {endingAssignmentId ===
                          responsibility.assignmentId
                            ? 'Encerrando...'
                            : 'Encerrar responsabilidade'}
                        </button>
                      ) : null}
                    </div>
                  ),
                )}
              </dl>
            )}

            {responsibilitiesManageable ? (
              <>
                <h4>Atribuir responsabilidade</h4>

                {responsibilityReferenceLoading ? (
                  <p>
                    Carregando pessoas e domínios...
                  </p>
                ) : responsibilityReferenceError ? (
                  <div
                    className="initiative-action-message initiative-action-message--error"
                    role="alert"
                  >
                    {responsibilityReferenceError}
                  </div>
                ) : (
                  <>
                    <label className="initiative-action-field">
                      <span>Pessoa *</span>
                      <select
                        value={
                          selectedOrganizationPersonId
                        }
                        onChange={(event) =>
                          setSelectedOrganizationPersonId(
                            event.target.value,
                          )
                        }
                        disabled={saving}
                      >
                        <option value="">
                          Selecione
                        </option>
                        {responsibilityCandidates.map(
                          (candidate) => (
                            <option
                              key={
                                candidate.organizationPersonId
                              }
                              value={
                                candidate.organizationPersonId
                              }
                            >
                              {candidate.displayName}
                              {candidate.jobTitle
                                ? ` — ${candidate.jobTitle}`
                                : ''}
                            </option>
                          ),
                        )}
                      </select>
                    </label>

                    <label className="initiative-action-field">
                      <span>
                        Tipo de responsabilidade *
                      </span>
                      <select
                        value={
                          selectedResponsibilityType
                        }
                        onChange={(event) =>
                          setSelectedResponsibilityType(
                            event.target.value,
                          )
                        }
                        disabled={saving}
                      >
                        <option value="">
                          Selecione
                        </option>
                        {responsibilityTypes.map(
                          (option) => (
                            <option
                              key={option.code}
                              value={option.code}
                            >
                              {option.name}
                            </option>
                          ),
                        )}
                      </select>
                    </label>

                    <label className="initiative-action-field">
                      <span>Alocação (%)</span>
                      <input
                        type="number"
                        min="0"
                        max="100"
                        step="0.01"
                        value={
                          responsibilityAllocation
                        }
                        onChange={(event) =>
                          setResponsibilityAllocation(
                            event.target.value,
                          )
                        }
                        disabled={saving}
                      />
                    </label>

                    <label className="initiative-action-field">
                      <span>Nível de autoridade</span>
                      <select
                        value={
                          selectedAuthorityLevel
                        }
                        onChange={(event) =>
                          setSelectedAuthorityLevel(
                            event.target.value,
                          )
                        }
                        disabled={saving}
                      >
                        <option value="">
                          Não definido
                        </option>
                        {authorityLevels.map(
                          (option) => (
                            <option
                              key={option.code}
                              value={option.code}
                            >
                              {option.name}
                            </option>
                          ),
                        )}
                      </select>
                    </label>

                    <label className="initiative-action-field">
                      <span>Início da vigência</span>
                      <input
                        type="date"
                        value={
                          responsibilityValidFrom
                        }
                        onChange={(event) =>
                          setResponsibilityValidFrom(
                            event.target.value,
                          )
                        }
                        disabled={saving}
                      />
                    </label>

                    <label className="initiative-action-field">
                      <span>Fim da vigência</span>
                      <input
                        type="date"
                        value={
                          responsibilityValidUntil
                        }
                        onChange={(event) =>
                          setResponsibilityValidUntil(
                            event.target.value,
                          )
                        }
                        disabled={saving}
                      />
                    </label>

                    <label className="initiative-action-field">
                      <span>
                        Motivo da atribuição
                      </span>
                      <textarea
                        rows={3}
                        value={
                          responsibilityAssignmentReason
                        }
                        onChange={(event) =>
                          setResponsibilityAssignmentReason(
                            event.target.value,
                          )
                        }
                        disabled={saving}
                      />
                    </label>

                    <label className="initiative-action-field">
                      <span>
                        Justificativa para auditoria *
                      </span>
                      <textarea
                        rows={3}
                        value={
                          responsibilityChangeReason
                        }
                        onChange={(event) =>
                          setResponsibilityChangeReason(
                            event.target.value,
                          )
                        }
                        disabled={saving}
                      />
                    </label>

                    <button
                      type="button"
                      onClick={() =>
                        void handleAssignResponsibility()
                      }
                      disabled={saving}
                    >
                      {savingResponsibility
                        ? 'Atribuindo...'
                        : 'Atribuir responsabilidade'}
                    </button>
                  </>
                )}
              </>
            ) : (
              <p>
                A gestão de responsabilidades fica
                bloqueada quando a ação está encerrada.
              </p>
            )}
          </section>

          <section className="initiative-action-drawer__section">
            <h3>Lifecycle</h3>
            <p>
              Você pode alterar a situação por aqui
              ou arrastando o cartão para uma coluna
              permitida. Nos dois casos a confirmação
              governada é obrigatória.
            </p>

            <button
              type="button"
              onClick={() =>
                setShowLifecycle(true)
              }
              disabled={saving}
            >
              Alterar situação
            </button>
          </section>

          <section className="initiative-action-drawer__section">
            <h3>Progresso oficial</h3>

            {progressEditable ? (
              <>
                <label className="initiative-action-field">
                  <span>
                    Progresso de 0 a menor que 100
                  </span>
                  <input
                    type="number"
                    min="0"
                    max="99.99"
                    step="0.1"
                    value={progress}
                    onChange={(event) =>
                      setProgress(
                        event.target.value,
                      )
                    }
                    disabled={saving}
                  />
                </label>

                <label className="initiative-action-field">
                  <span>
                    Justificativa para auditoria *
                  </span>
                  <textarea
                    rows={4}
                    value={changeReason}
                    onChange={(event) =>
                      setChangeReason(
                        event.target.value,
                      )
                    }
                    disabled={saving}
                  />
                </label>

                <button
                  type="button"
                  onClick={() =>
                    void handleProgressUpdate()
                  }
                  disabled={saving}
                >
                  {savingProgress
                    ? 'Salvando...'
                    : 'Atualizar progresso'}
                </button>
              </>
            ) : (
              <p>
                O progresso só pode ser atualizado
                quando a ação estiver em execução,
                em espera ou bloqueada.
              </p>
            )}
          </section>

          <section className="initiative-action-drawer__section">
            <h3>Execução econômica</h3>
            <p>
              Registre custos e esforço diretamente
              na ação. Estes valores permanecem
              independentes dos valores da iniciativa
              e não sofrem conversão cambial ou
              consolidação automática.
            </p>

            <label className="initiative-action-field">
              <span>Custo planejado</span>
              <input
                type="number"
                min="0"
                step="0.01"
                value={plannedCost}
                onChange={(event) =>
                  setPlannedCost(
                    event.target.value,
                  )
                }
                disabled={
                  saving || !economicsEditable
                }
              />
            </label>

            <label className="initiative-action-field">
              <span>Custo realizado</span>
              <input
                type="number"
                min="0"
                step="0.01"
                value={actualCost}
                onChange={(event) =>
                  setActualCost(
                    event.target.value,
                  )
                }
                disabled={
                  saving || !economicsEditable
                }
              />
            </label>

            <label className="initiative-action-field">
              <span>Moeda ISO *</span>
              <input
                type="text"
                maxLength={3}
                value={currencyCode}
                onChange={(event) =>
                  setCurrencyCode(
                    event.target.value
                      .toUpperCase(),
                  )
                }
                disabled={
                  saving || !economicsEditable
                }
              />
            </label>

            <label className="initiative-action-field">
              <span>Esforço estimado</span>
              <input
                type="number"
                min="0"
                step="0.01"
                value={estimatedEffort}
                onChange={(event) =>
                  setEstimatedEffort(
                    event.target.value,
                  )
                }
                disabled={
                  saving || !economicsEditable
                }
              />
            </label>

            <label className="initiative-action-field">
              <span>Esforço realizado</span>
              <input
                type="number"
                min="0"
                step="0.01"
                value={actualEffort}
                onChange={(event) =>
                  setActualEffort(
                    event.target.value,
                  )
                }
                disabled={
                  saving || !economicsEditable
                }
              />
            </label>

            <label className="initiative-action-field">
              <span>Unidade de esforço</span>
              <select
                value={effortUnit}
                onChange={(event) =>
                  setEffortUnit(
                    event.target.value,
                  )
                }
                disabled={
                  saving || !economicsEditable
                }
              >
                <option value="">
                  Não definida
                </option>
                {initiativeActionEffortUnits.map(
                  (unit) => (
                    <option
                      key={unit}
                      value={unit}
                    >
                      {
                        initiativeActionEffortUnitLabels[
                          unit
                        ]
                      }
                    </option>
                  ),
                )}
              </select>
            </label>

            {economicsEditable ? (
              <>
                <label className="initiative-action-field">
                  <span>
                    Justificativa para auditoria *
                  </span>
                  <textarea
                    rows={4}
                    value={
                      economicChangeReason
                    }
                    onChange={(event) =>
                      setEconomicChangeReason(
                        event.target.value,
                      )
                    }
                    disabled={saving}
                  />
                </label>

                <button
                  type="button"
                  onClick={() =>
                    void handleEconomicsUpdate()
                  }
                  disabled={saving}
                >
                  {savingEconomics
                    ? 'Salvando...'
                    : 'Atualizar execução econômica'}
                </button>
              </>
            ) : (
              <p>
                A execução econômica fica somente
                para consulta quando a ação estiver
                concluída, cancelada ou arquivada.
              </p>
            )}
          </section>

          {card.hasEligibleChildren ? (
            <p className="initiative-action-drawer__note">
              Esta ação consolida ações subordinadas.
              O progresso calculado permanece derivado
              pelo roll-up governado.
            </p>
          ) : null}

          {errorMessage ? (
            <div
              className="initiative-action-message initiative-action-message--error"
              role="alert"
            >
              {errorMessage}
            </div>
          ) : null}
        </aside>
      </div>

      {showLifecycle ? (
        <InitiativeLifecycleDialog
          card={card}
          onClose={() =>
            setShowLifecycle(false)
          }
          onChanged={onChanged}
        />
      ) : null}
    </>
  )
}
