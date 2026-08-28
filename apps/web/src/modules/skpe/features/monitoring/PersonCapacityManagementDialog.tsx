import { useEffect, useMemo, useState } from 'react'

import { translateBackendMessage } from '../../../../shared/i18n/ptBR'
import { PersonCapacityAuditHistory } from './PersonCapacityAuditHistory'
import {
  createPersonCapacityPeriod,
  loadPersonCapacityCandidates,
  loadPersonCapacityPeriods,
  transitionPersonCapacityPeriod,
  updatePersonCapacityPeriod,
  type PersonCapacityCandidate,
  type PersonCapacityPeriod,
} from './personCapacity'
import {
  getAllowedPersonCapacityPeriodTransitions,
  validatePersonCapacityPeriodCreation,
  validatePersonCapacityPeriodEdit,
  validatePersonCapacityPeriodTransition,
  type PersonCapacityPeriodStatus,
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

const statusLabels: Record<PersonCapacityPeriodStatus, string> = {
  planned: 'Planejada',
  active: 'Ativa',
  closed: 'Encerrada',
  cancelled: 'Cancelada',
}

export function PersonCapacityManagementDialog({
  organizationId,
  onClose,
  onSaved,
}: PersonCapacityManagementDialogProps) {
  const [candidates, setCandidates] = useState<PersonCapacityCandidate[]>([])
  const [loadingCandidates, setLoadingCandidates] = useState(true)
  const [selectedPersonId, setSelectedPersonId] = useState('')
  const [periods, setPeriods] = useState<PersonCapacityPeriod[]>([])
  const [loadingPeriods, setLoadingPeriods] = useState(false)
  const [selectedPeriodId, setSelectedPeriodId] = useState('')
  const [targetStatus, setTargetStatus] = useState('')
  const [transitionReason, setTransitionReason] = useState('')

  const [editPeriodStart, setEditPeriodStart] = useState('')
  const [editPeriodEnd, setEditPeriodEnd] = useState('')
  const [editCapacityAmount, setEditCapacityAmount] = useState('')
  const [editCapacityUnit, setEditCapacityUnit] = useState('hours')
  const [editNotes, setEditNotes] = useState('')
  const [editReason, setEditReason] = useState('')

  const [periodStart, setPeriodStart] = useState('')
  const [periodEnd, setPeriodEnd] = useState('')
  const [capacityAmount, setCapacityAmount] = useState('')
  const [capacityUnit, setCapacityUnit] = useState('hours')
  const [status, setStatus] = useState<'planned' | 'active'>('planned')
  const [notes, setNotes] = useState('')
  const [changeReason, setChangeReason] = useState('')
  const [saving, setSaving] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const selectedPerson = useMemo(
    () =>
      candidates.find(
        (candidate) => candidate.organizationPersonId === selectedPersonId,
      ) ?? null,
    [candidates, selectedPersonId],
  )

  const selectedPeriod = useMemo(
    () =>
      periods.find(
        (period) => period.capacityPeriodId === selectedPeriodId,
      ) ?? null,
    [periods, selectedPeriodId],
  )

  const allowedTransitions = useMemo(
    () =>
      selectedPeriod
        ? getAllowedPersonCapacityPeriodTransitions(
            selectedPeriod.capacityStatus,
          )
        : [],
    [selectedPeriod],
  )

  const selectedPeriodEditable =
    selectedPeriod !== null &&
    (selectedPeriod.capacityStatus === 'planned' ||
      selectedPeriod.capacityStatus === 'active')

  const editDraftDirty =
    selectedPeriodEditable &&
    selectedPeriod !== null &&
    (editPeriodStart !== selectedPeriod.periodStart ||
      editPeriodEnd !== selectedPeriod.periodEnd ||
      editCapacityAmount !== String(selectedPeriod.capacityAmount) ||
      editCapacityUnit !== selectedPeriod.capacityUnit ||
      editNotes !== (selectedPeriod.notes ?? '') ||
      editReason.trim().length > 0)

  const creationDraftDirty =
    selectedPersonId !== '' &&
    (periodStart !== '' ||
      periodEnd !== '' ||
      capacityAmount !== '' ||
      capacityUnit !== 'hours' ||
      status !== 'planned' ||
      notes.trim().length > 0 ||
      changeReason.trim().length > 0)

  const closeLocked =
    saving || editDraftDirty || creationDraftDirty

  function resetEditDraft() {
    if (!selectedPeriod) return

    setEditPeriodStart(selectedPeriod.periodStart)
    setEditPeriodEnd(selectedPeriod.periodEnd)
    setEditCapacityAmount(String(selectedPeriod.capacityAmount))
    setEditCapacityUnit(selectedPeriod.capacityUnit)
    setEditNotes(selectedPeriod.notes ?? '')
    setEditReason('')
    setErrorMessage(null)
  }

  function resetCreationDraft() {
    setPeriodStart('')
    setPeriodEnd('')
    setCapacityAmount('')
    setCapacityUnit('hours')
    setStatus('planned')
    setNotes('')
    setChangeReason('')
    setErrorMessage(null)
  }

  useEffect(() => {
    let active = true

    setLoadingCandidates(true)

    void loadPersonCapacityCandidates(organizationId)
      .then((items) => {
        if (!active) return
        setCandidates(items)
      })
      .catch((error) => {
        if (!active) return
        setCandidates([])
        setErrorMessage(
          error instanceof Error
            ? translateBackendMessage(error.message)
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

    setSelectedPeriodId('')
    setTargetStatus('')
    setTransitionReason('')

    if (!selectedPersonId) {
      setPeriods([])
      setLoadingPeriods(false)
      return () => {
        active = false
      }
    }

    setLoadingPeriods(true)
    setErrorMessage(null)

    void loadPersonCapacityPeriods(organizationId, selectedPersonId)
      .then((items) => {
        if (!active) return
        setPeriods(items)
      })
      .catch((error) => {
        if (!active) return
        setPeriods([])
        setErrorMessage(
          error instanceof Error
            ? translateBackendMessage(error.message)
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
    if (!selectedPeriod) {
      setEditPeriodStart('')
      setEditPeriodEnd('')
      setEditCapacityAmount('')
      setEditCapacityUnit('hours')
      setEditNotes('')
      setEditReason('')
      return
    }

    setEditPeriodStart(selectedPeriod.periodStart)
    setEditPeriodEnd(selectedPeriod.periodEnd)
    setEditCapacityAmount(String(selectedPeriod.capacityAmount))
    setEditCapacityUnit(selectedPeriod.capacityUnit)
    setEditNotes(selectedPeriod.notes ?? '')
    setEditReason('')
  }, [selectedPeriod])

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape' && !closeLocked) {
        onClose()
      }
    }

    window.addEventListener('keydown', handleKeyDown)

    return () => {
      window.removeEventListener('keydown', handleKeyDown)
    }
  }, [closeLocked, onClose])

  async function handleCreate() {
    const validation = validatePersonCapacityPeriodCreation({
      organizationPersonId: selectedPersonId,
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
      await createPersonCapacityPeriod(organizationId, validation.value)
      onSaved()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? translateBackendMessage(error.message)
          : 'Não foi possível registrar o período de capacidade.',
      )
      setSaving(false)
    }
  }

  async function handleEdit() {
    if (!selectedPeriod || !selectedPersonId) {
      setErrorMessage('Selecione um período de capacidade.')
      return
    }

    const validation = validatePersonCapacityPeriodEdit({
      currentStatus: selectedPeriod.capacityStatus,
      periodStart: editPeriodStart,
      periodEnd: editPeriodEnd,
      capacityAmount: editCapacityAmount,
      capacityUnit: editCapacityUnit,
      notes: editNotes,
      changeReason: editReason,
    })

    if (!validation.ok) {
      setErrorMessage(validation.message)
      return
    }

    setSaving(true)
    setErrorMessage(null)

    try {
      await updatePersonCapacityPeriod(
        organizationId,
        selectedPersonId,
        selectedPeriod,
        validation.value,
      )
      onSaved()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? translateBackendMessage(error.message)
          : 'Não foi possível atualizar o período de capacidade.',
      )
      setSaving(false)
    }
  }

  async function handleTransition() {
    if (!selectedPeriod || !selectedPersonId) {
      setErrorMessage('Selecione um período de capacidade.')
      return
    }

    const validation = validatePersonCapacityPeriodTransition({
      currentStatus: selectedPeriod.capacityStatus,
      targetStatus,
      currentAllocationCount: selectedPeriod.currentAllocationCount,
      changeReason: transitionReason,
    })

    if (!validation.ok) {
      setErrorMessage(validation.message)
      return
    }

    setSaving(true)
    setErrorMessage(null)

    try {
      await transitionPersonCapacityPeriod(
        organizationId,
        selectedPersonId,
        selectedPeriod,
        validation.value,
      )
      onSaved()
    } catch (error) {
      setErrorMessage(
        error instanceof Error
          ? translateBackendMessage(error.message)
          : 'Não foi possível alterar a situação do período de capacidade.',
      )
      setSaving(false)
    }
  }

  return (
    <div
      className="skpe-economic-dialog-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !closeLocked) {
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
            <span>Capacidade transversal de pessoas</span>
            <h2 id="skpe-person-capacity-dialog-title">
              Gerenciar períodos de capacidade
            </h2>
          </div>
          <button type="button" onClick={onClose} disabled={closeLocked}>
            Fechar
          </button>
        </header>

        <p className="skpe-economic-dialog-note">
          Capacidade é uma quantidade explícita, temporal e vinculada a uma
          unidade. Disponibilidade percentual, responsabilidades e esforço das
          ações permanecem conceitos independentes e não são convertidos
          automaticamente.
        </p>

        <div className="skpe-economic-dialog-grid">
          <label className="is-wide">
            <span>Pessoa *</span>
            <select
              value={selectedPersonId}
              onChange={(event) => setSelectedPersonId(event.target.value)}
              disabled={saving || loadingCandidates || editDraftDirty || creationDraftDirty}
            >
              <option value="">
                {loadingCandidates ? 'Carregando...' : 'Selecione'}
              </option>
              {candidates.map((candidate) => (
                <option
                  key={candidate.organizationPersonId}
                  value={candidate.organizationPersonId}
                >
                  {candidate.displayName}
                  {candidate.jobTitle ? ` — ${candidate.jobTitle}` : ''}
                </option>
              ))}
            </select>
          </label>

          {selectedPerson ? (
            <div className="is-wide skpe-economic-dialog-note">
              <strong>{selectedPerson.displayName}</strong>
              {selectedPerson.organizationalArea
                ? ` · ${selectedPerson.organizationalArea}`
                : ''}
              {selectedPerson.availabilityPercentage !== null
                ? ` · Disponibilidade cadastral: ${formatNumber(
                    selectedPerson.availabilityPercentage,
                  )}%`
                : ''}
              <br />
              <small>
                A disponibilidade cadastral é apenas contexto; ela não define a
                capacidade quantitativa abaixo.
              </small>
            </div>
          ) : null}

          {selectedPersonId ? (
            <div className="is-wide skpe-economic-dialog-note">
              <strong>Períodos já cadastrados</strong>
              {loadingPeriods ? (
                <p>Carregando períodos...</p>
              ) : periods.length === 0 ? (
                <p>
                  Nenhum período explícito de capacidade cadastrado para esta
                  pessoa.
                </p>
              ) : (
                <>
                  <label className="is-wide">
                    <span>Período para gestão</span>
                    <select
                      value={selectedPeriodId}
                      onChange={(event) => {
                        setSelectedPeriodId(event.target.value)
                        setTargetStatus('')
                        setTransitionReason('')
                      }}
                      disabled={saving || editDraftDirty || creationDraftDirty}
                    >
                      <option value="">Selecione</option>
                      {periods.map((period) => (
                        <option
                          key={period.capacityPeriodId}
                          value={period.capacityPeriodId}
                        >
                          {period.periodStart} — {period.periodEnd}
                          {' · '}
                          {formatNumber(period.capacityAmount)}{' '}
                          {unitLabels[period.capacityUnit] ?? period.capacityUnit}
                          {' · '}
                          {statusLabels[period.capacityStatus]}
                        </option>
                      ))}
                    </select>
                  </label>

                  {selectedPeriod ? (
                    <div className="is-wide skpe-economic-dialog-note">
                      <strong>
                        {selectedPeriod.periodStart} — {selectedPeriod.periodEnd}
                      </strong>
                      {' · '}
                      {formatNumber(selectedPeriod.capacityAmount)}{' '}
                      {unitLabels[selectedPeriod.capacityUnit] ??
                        selectedPeriod.capacityUnit}
                      {' · '}
                      {statusLabels[selectedPeriod.capacityStatus]}
                      {' · alocado '}
                      {formatNumber(selectedPeriod.allocatedCurrentAmount)}
                      {' · disponível '}
                      {formatNumber(selectedPeriod.availableAmount)}
                      {' · alocações abertas '}
                      {selectedPeriod.currentAllocationCount}
                      {selectedPeriod.isOverallocated
                        ? ` · SOBREALOCAÇÃO ${formatNumber(
                            selectedPeriod.overallocationAmount,
                          )}`
                        : ''}
                    </div>
                  ) : null}

                  {selectedPeriod ? (
                    <PersonCapacityAuditHistory
                      organizationId={organizationId}
                      capacityPeriodId={selectedPeriod.capacityPeriodId}
                    />
                  ) : null}

                  {selectedPeriodEditable && selectedPeriod ? (
                    <>
                      <div className="is-wide skpe-economic-dialog-note">
                        <strong>Editar período selecionado</strong>
                        <br />
                        <small>
                          O banco validará sobreposição, vínculo das alocações e
                          imutabilidade da unidade quando houver alocações.
                        </small>
                      </div>

                      <label>
                        <span>Início *</span>
                        <input
                          type="date"
                          value={editPeriodStart}
                          onChange={(event) =>
                            setEditPeriodStart(event.target.value)
                          }
                          disabled={saving || creationDraftDirty}
                        />
                      </label>

                      <label>
                        <span>Fim *</span>
                        <input
                          type="date"
                          value={editPeriodEnd}
                          onChange={(event) =>
                            setEditPeriodEnd(event.target.value)
                          }
                          disabled={saving || creationDraftDirty}
                        />
                      </label>

                      <label>
                        <span>Capacidade quantitativa *</span>
                        <input
                          type="number"
                          min="0"
                          step="0.01"
                          value={editCapacityAmount}
                          onChange={(event) =>
                            setEditCapacityAmount(event.target.value)
                          }
                          disabled={saving || creationDraftDirty}
                        />
                      </label>

                      <label>
                        <span>Unidade *</span>
                        <select
                          value={editCapacityUnit}
                          onChange={(event) =>
                            setEditCapacityUnit(event.target.value)
                          }
                          disabled={saving || creationDraftDirty}
                        >
                          {Object.entries(unitLabels).map(([value, label]) => (
                            <option key={value} value={value}>
                              {label}
                            </option>
                          ))}
                        </select>
                      </label>

                      <label className="is-wide">
                        <span>Observações</span>
                        <textarea
                          rows={3}
                          value={editNotes}
                          onChange={(event) => setEditNotes(event.target.value)}
                          disabled={saving || creationDraftDirty}
                        />
                      </label>

                      <label className="is-wide">
                        <span>Justificativa da edição *</span>
                        <textarea
                          rows={3}
                          value={editReason}
                          onChange={(event) => setEditReason(event.target.value)}
                          disabled={saving || creationDraftDirty}
                        />
                      </label>

                      <div className="is-wide">
                        <button
                          type="button"
                          onClick={() => void handleEdit()}
                          disabled={saving || creationDraftDirty}
                        >
                          {saving ? 'Atualizando...' : 'Salvar edição'}
                        </button>
                        <button
                          type="button"
                          onClick={resetEditDraft}
                          disabled={saving || creationDraftDirty || !editDraftDirty}
                        >
                          Descartar edição
                        </button>
                      </div>
                    </>
                  ) : selectedPeriod ? (
                    <div className="is-wide skpe-economic-dialog-note">
                      <small>
                        Este período está em situação terminal e não pode ser
                        modificado.
                      </small>
                    </div>
                  ) : null}

                  {selectedPeriod && allowedTransitions.length > 0 ? (
                    <>
                      <div className="is-wide skpe-economic-dialog-note">
                        <strong>Alterar situação</strong>
                      </div>

                      <label>
                        <span>Nova situação *</span>
                        <select
                          value={targetStatus}
                          onChange={(event) =>
                            setTargetStatus(event.target.value)
                          }
                          disabled={saving || editDraftDirty || creationDraftDirty}
                        >
                          <option value="">Selecione</option>
                          {allowedTransitions.map((candidateStatus) => (
                            <option
                              key={candidateStatus}
                              value={candidateStatus}
                            >
                              {statusLabels[candidateStatus]}
                            </option>
                          ))}
                        </select>
                      </label>

                      <label className="is-wide">
                        <span>Justificativa da transição *</span>
                        <textarea
                          rows={3}
                          value={transitionReason}
                          onChange={(event) =>
                            setTransitionReason(event.target.value)
                          }
                          disabled={saving || editDraftDirty || creationDraftDirty}
                        />
                      </label>

                      {editDraftDirty ? (
                        <div className="is-wide skpe-economic-dialog-note">
                          <small>
                            Salve ou descarte o rascunho de edição antes de alterar
                            a situação, trocar pessoa/período, criar outro período
                            ou fechar esta janela.
                          </small>
                        </div>
                      ) : null}

                      <div className="is-wide skpe-economic-dialog-note">
                        <small>
                          A transição altera somente o status. Datas, quantidade,
                          unidade e observações são preservadas integralmente.
                        </small>
                      </div>

                      <div className="is-wide">
                        <button
                          type="button"
                          onClick={() => void handleTransition()}
                          disabled={saving || editDraftDirty || creationDraftDirty}
                        >
                          {saving ? 'Atualizando...' : 'Aplicar transição'}
                        </button>
                      </div>
                    </>
                  ) : null}
                </>
              )}
            </div>
          ) : null}

          <div className="is-wide skpe-economic-dialog-note">
            <strong>Novo período de capacidade</strong>
            {!selectedPersonId ? (
              <>
                <br />
                <small>
                  Selecione primeiro a pessoa à qual o novo período pertencerá.
                </small>
              </>
            ) : null}
            {editDraftDirty ? (
              <>
                <br />
                <small>
                  Salve ou descarte a edição em andamento antes de registrar
                  outro período.
                </small>
              </>
            ) : null}
          </div>

          {creationDraftDirty ? (
            <div className="is-wide skpe-economic-dialog-note">
              <small>
                Este rascunho está vinculado à pessoa selecionada. Registre ou
                descarte o novo período antes de trocar pessoa/período, editar
                outro período, alterar situação ou fechar esta janela.
              </small>
            </div>
          ) : null}

          <label>
            <span>Início *</span>
            <input
              type="date"
              value={periodStart}
              onChange={(event) => setPeriodStart(event.target.value)}
              disabled={saving || editDraftDirty || !selectedPersonId}
            />
          </label>

          <label>
            <span>Fim *</span>
            <input
              type="date"
              value={periodEnd}
              onChange={(event) => setPeriodEnd(event.target.value)}
              disabled={saving || editDraftDirty || !selectedPersonId}
            />
          </label>

          <label>
            <span>Capacidade quantitativa *</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={capacityAmount}
              onChange={(event) => setCapacityAmount(event.target.value)}
              disabled={saving || editDraftDirty || !selectedPersonId}
            />
          </label>

          <label>
            <span>Unidade *</span>
            <select
              value={capacityUnit}
              onChange={(event) => setCapacityUnit(event.target.value)}
              disabled={saving || editDraftDirty || !selectedPersonId}
            >
              {Object.entries(unitLabels).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </label>

          <label>
            <span>Situação inicial *</span>
            <select
              value={status}
              onChange={(event) =>
                setStatus(event.target.value as 'planned' | 'active')
              }
              disabled={saving || editDraftDirty || !selectedPersonId}
            >
              <option value="planned">Planejada</option>
              <option value="active">Ativa</option>
            </select>
          </label>

          <label className="is-wide">
            <span>Observações</span>
            <textarea
              rows={3}
              value={notes}
              onChange={(event) => setNotes(event.target.value)}
              disabled={saving || editDraftDirty || !selectedPersonId}
            />
          </label>

          <label className="is-wide">
            <span>Justificativa para auditoria *</span>
            <textarea
              rows={3}
              value={changeReason}
              onChange={(event) => setChangeReason(event.target.value)}
              disabled={saving || editDraftDirty || !selectedPersonId}
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
          <button type="button" onClick={onClose} disabled={closeLocked}>
            Cancelar
          </button>
          <button
            type="button"
            onClick={resetCreationDraft}
            disabled={saving || editDraftDirty || !creationDraftDirty}
          >
            Descartar novo período
          </button>
          <button
            type="button"
            className="is-primary"
            onClick={() => void handleCreate()}
            disabled={saving || editDraftDirty || !selectedPersonId}
          >
            {saving ? 'Registrando...' : 'Registrar capacidade'}
          </button>
        </footer>
      </section>
    </div>
  )
}
