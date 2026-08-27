import { useEffect, useMemo, useState } from 'react'

import { translateBackendMessage } from '../../../../shared/i18n/ptBR'
import {
  createPersonCapacityPeriod,
  loadPersonCapacityCandidates,
  loadPersonCapacityPeriods,
  type PersonCapacityCandidate,
  type PersonCapacityPeriod,
} from './personCapacity'
import {
  validatePersonCapacityPeriodCreation,
} from './personCapacityValidation'

type PersonCapacityManagementDialogProps = {
  organizationId: string
  onClose: () => void
  onSaved: () => void
}

function formatNumber(value: number) {
  return new Intl.NumberFormat('pt-BR', {
    maximumFractionDigits: 2,
  }).format(value)
}

const unitLabels: Record<string, string> = {
  hours: 'Horas',
  days: 'Dias',
  weeks: 'Semanas',
  months: 'Meses',
  points: 'Pontos',
  custom: 'Personalizada',
}

export function PersonCapacityManagementDialog({
  organizationId,
  onClose,
  onSaved,
}: PersonCapacityManagementDialogProps) {
  const [candidates, setCandidates] = useState<
    PersonCapacityCandidate[]
  >([])
  const [loadingCandidates, setLoadingCandidates] =
    useState(true)
  const [selectedPersonId, setSelectedPersonId] =
    useState('')
  const [periods, setPeriods] = useState<
    PersonCapacityPeriod[]
  >([])
  const [loadingPeriods, setLoadingPeriods] =
    useState(false)

  const [periodStart, setPeriodStart] = useState('')
  const [periodEnd, setPeriodEnd] = useState('')
  const [capacityAmount, setCapacityAmount] =
    useState('')
  const [capacityUnit, setCapacityUnit] =
    useState('hours')
  const [status, setStatus] = useState<
    'planned' | 'active'
  >('planned')
  const [notes, setNotes] = useState('')
  const [changeReason, setChangeReason] =
    useState('')
  const [saving, setSaving] = useState(false)
  const [errorMessage, setErrorMessage] =
    useState<string | null>(null)

  const selectedPerson = useMemo(
    () =>
      candidates.find(
        (candidate) =>
          candidate.organizationPersonId ===
          selectedPersonId,
      ) ?? null,
    [candidates, selectedPersonId],
  )

  useEffect(() => {
    let active = true

    setLoadingCandidates(true)

    void loadPersonCapacityCandidates(
      organizationId,
    )
      .then((items) => {
        if (!active) return
        setCandidates(items)
      })
      .catch((error) => {
        if (!active) return
        setCandidates([])
        setErrorMessage(
          error instanceof Error
            ? translateBackendMessage(
                error.message,
              )
            : 'Não foi possível carregar as pessoas elegíveis.',
        )
      })
      .finally(() => {
        if (!active) return
        setLoadingCandidates(false)
      })

    return () => {
      active = false
    }
  }, [organizationId])

  useEffect(() => {
    let active = true

    if (!selectedPersonId) {
      setPeriods([])
      setLoadingPeriods(false)
      return () => {
        active = false
      }
    }

    setLoadingPeriods(true)
    setErrorMessage(null)

    void loadPersonCapacityPeriods(
      organizationId,
      selectedPersonId,
    )
      .then((items) => {
        if (!active) return
        setPeriods(items)
      })
      .catch((error) => {
        if (!active) return
        setPeriods([])
        setErrorMessage(
          error instanceof Error
            ? translateBackendMessage(
                error.message,
              )
            : 'Não foi possível carregar os períodos de capacidade.',
        )
      })
      .finally(() => {
        if (!active) return
        setLoadingPeriods(false)
      })

    return () => {
      active = false
    }
  }, [organizationId, selectedPersonId])

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (
        event.key === 'Escape' &&
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
  }, [onClose, saving])

  async function handleCreate() {
    const validation =
      validatePersonCapacityPeriodCreation({
        organizationPersonId:
          selectedPersonId,
        periodStart,
        periodEnd,
        capacityAmount,
        capacityUnit,
        status,
        notes,
        changeReason,
      })

    if (!validation.ok) {
      setErrorMessage(validation.message)
      return
    }

    setSaving(true)
    setErrorMessage(null)

    try {
      await createPersonCapacityPeriod(
        organizationId,
        validation.value,
      )
      onSaved()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? translateBackendMessage(
              error.message,
            )
          : 'Não foi possível registrar o período de capacidade.',
      )
      setSaving(false)
    }
  }

  return (
    <div
      className="skpe-economic-dialog-backdrop"
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
      <section
        className="skpe-economic-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="skpe-person-capacity-dialog-title"
      >
        <header>
          <div>
            <span>
              Capacidade transversal de pessoas
            </span>
            <h2 id="skpe-person-capacity-dialog-title">
              Registrar período de capacidade
            </h2>
          </div>
          <button
            type="button"
            onClick={onClose}
            disabled={saving}
          >
            Fechar
          </button>
        </header>

        <p className="skpe-economic-dialog-note">
          Capacidade é uma quantidade explícita,
          temporal e vinculada a uma unidade.
          Disponibilidade percentual, responsabilidades
          e esforço das ações permanecem conceitos
          independentes e não são convertidos
          automaticamente.
        </p>

        <div className="skpe-economic-dialog-grid">
          <label className="is-wide">
            <span>Pessoa *</span>
            <select
              value={selectedPersonId}
              onChange={(event) => {
                setSelectedPersonId(
                  event.target.value,
                )
              }}
              disabled={
                saving || loadingCandidates
              }
            >
              <option value="">
                {loadingCandidates
                  ? 'Carregando...'
                  : 'Selecione'}
              </option>
              {candidates.map((candidate) => (
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
              ))}
            </select>
          </label>

          {selectedPerson ? (
            <div className="is-wide skpe-economic-dialog-note">
              <strong>
                {selectedPerson.displayName}
              </strong>
              {selectedPerson.organizationalArea
                ? ` · ${selectedPerson.organizationalArea}`
                : ''}
              {selectedPerson.availabilityPercentage !==
              null
                ? ` · Disponibilidade cadastral: ${formatNumber(
                    selectedPerson.availabilityPercentage,
                  )}%`
                : ''}
              <br />
              <small>
                A disponibilidade cadastral é apenas
                contexto; ela não define a capacidade
                quantitativa abaixo.
              </small>
            </div>
          ) : null}

          {selectedPersonId ? (
            <div className="is-wide skpe-economic-dialog-note">
              <strong>
                Períodos já cadastrados
              </strong>
              {loadingPeriods ? (
                <p>Carregando períodos...</p>
              ) : periods.length === 0 ? (
                <p>
                  Nenhum período explícito de capacidade
                  cadastrado para esta pessoa.
                </p>
              ) : (
                periods.map((period) => (
                  <p
                    key={
                      period.capacityPeriodId
                    }
                  >
                    {period.periodStart}
                    {' — '}
                    {period.periodEnd}
                    {' · '}
                    {formatNumber(
                      period.capacityAmount,
                    )}{' '}
                    {unitLabels[
                      period.capacityUnit
                    ] ?? period.capacityUnit}
                    {' · '}
                    {period.capacityStatus}
                    {' · alocado '}
                    {formatNumber(
                      period.allocatedCurrentAmount,
                    )}
                    {' · disponível '}
                    {formatNumber(
                      period.availableAmount,
                    )}
                    {period.isOverallocated
                      ? ` · SOBREALOCAÇÃO ${formatNumber(
                          period.overallocationAmount,
                        )}`
                      : ''}
                  </p>
                ))
              )}
            </div>
          ) : null}

          <label>
            <span>Início *</span>
            <input
              type="date"
              value={periodStart}
              onChange={(event) =>
                setPeriodStart(
                  event.target.value,
                )
              }
              disabled={saving}
            />
          </label>

          <label>
            <span>Fim *</span>
            <input
              type="date"
              value={periodEnd}
              onChange={(event) =>
                setPeriodEnd(
                  event.target.value,
                )
              }
              disabled={saving}
            />
          </label>

          <label>
            <span>Capacidade quantitativa *</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={capacityAmount}
              onChange={(event) =>
                setCapacityAmount(
                  event.target.value,
                )
              }
              disabled={saving}
            />
          </label>

          <label>
            <span>Unidade *</span>
            <select
              value={capacityUnit}
              onChange={(event) =>
                setCapacityUnit(
                  event.target.value,
                )
              }
              disabled={saving}
            >
              <option value="hours">
                Horas
              </option>
              <option value="days">
                Dias
              </option>
              <option value="weeks">
                Semanas
              </option>
              <option value="months">
                Meses
              </option>
              <option value="points">
                Pontos
              </option>
              <option value="custom">
                Personalizada
              </option>
            </select>
          </label>

          <label>
            <span>Situação inicial *</span>
            <select
              value={status}
              onChange={(event) =>
                setStatus(
                  event.target.value as
                    | 'planned'
                    | 'active',
                )
              }
              disabled={saving}
            >
              <option value="planned">
                Planejada
              </option>
              <option value="active">
                Ativa
              </option>
            </select>
          </label>

          <label className="is-wide">
            <span>Observações</span>
            <textarea
              rows={3}
              value={notes}
              onChange={(event) =>
                setNotes(event.target.value)
              }
              disabled={saving}
            />
          </label>

          <label className="is-wide">
            <span>
              Justificativa para auditoria *
            </span>
            <textarea
              rows={3}
              value={changeReason}
              onChange={(event) =>
                setChangeReason(
                  event.target.value,
                )
              }
              disabled={saving}
            />
          </label>
        </div>

        {errorMessage ? (
          <div
            className="skpe-economic-dialog-message is-error"
            role="alert"
          >
            {errorMessage}
          </div>
        ) : null}

        <footer>
          <button
            type="button"
            onClick={onClose}
            disabled={saving}
          >
            Cancelar
          </button>
          <button
            type="button"
            className="is-primary"
            onClick={() =>
              void handleCreate()
            }
            disabled={saving}
          >
            {saving
              ? 'Registrando...'
              : 'Registrar capacidade'}
          </button>
        </footer>
      </section>
    </div>
  )
}
