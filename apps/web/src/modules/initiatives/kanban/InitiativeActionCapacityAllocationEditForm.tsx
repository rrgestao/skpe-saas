import { useState } from 'react'

import {
  canEditInitiativeActionCapacityAllocation,
  validateInitiativeActionCapacityAllocationEdit,
} from '../contracts/initiativeActionCapacityAllocationEditing'
import type { InitiativeActionCapacityAllocation } from '../contracts/initiativeActions'
import { updateInitiativeActionCapacityAllocation } from '../data/initiativeActionCapacityAllocationEditingData'

type InitiativeActionCapacityAllocationEditFormProps = {
  organizationId: string
  actionId: string
  allocation: InitiativeActionCapacityAllocation
  disabled: boolean
  onChanged: () => Promise<void>
  onSavingChange: (saving: boolean) => void
  onEditingChange: (editing: boolean) => void
}

export function InitiativeActionCapacityAllocationEditForm({
  organizationId,
  actionId,
  allocation,
  disabled,
  onChanged,
  onSavingChange,
  onEditingChange,
}: InitiativeActionCapacityAllocationEditFormProps) {
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)
  const [allocationStart, setAllocationStart] = useState(allocation.allocationStart)
  const [allocationEnd, setAllocationEnd] = useState(allocation.allocationEnd)
  const [allocatedAmount, setAllocatedAmount] = useState(String(allocation.allocatedAmount))
  const [notes, setNotes] = useState(allocation.notes ?? '')
  const [changeReason, setChangeReason] = useState('')
  const [error, setError] = useState<string | null>(null)

  if (!canEditInitiativeActionCapacityAllocation(allocation.status)) {
    return null
  }

  if (!editing) {
    return (
      <button
        type="button"
        disabled={disabled}
        onClick={() => {
          setError(null)
          setEditing(true)
          onEditingChange(true)
        }}
      >
        Editar alocação
      </button>
    )
  }

  async function handleSave() {
    const validation = validateInitiativeActionCapacityAllocationEdit(
      allocation,
      {
        allocationStart,
        allocationEnd,
        allocatedAmount,
        notes,
        changeReason,
      },
    )

    if (!validation.ok) {
      setError(validation.message)
      return
    }

    setSaving(true)
    onSavingChange(true)
    setError(null)

    try {
      await updateInitiativeActionCapacityAllocation(
        organizationId,
        actionId,
        allocation,
        validation.value,
      )
      await onChanged()
      setEditing(false)
      onEditingChange(false)
      setChangeReason('')
    } catch (saveError) {
      setError(
        saveError instanceof Error
          ? saveError.message
          : 'Não foi possível editar a alocação de capacidade.',
      )
    } finally {
      setSaving(false)
      onSavingChange(false)
    }
  }

  return (
    <div className="initiative-action-drawer__note">
      <strong>Editar alocação</strong>

      <label className="initiative-action-field">
        <span>Início *</span>
        <input
          type="date"
          value={allocationStart}
          disabled={disabled || saving}
          onChange={(event) => setAllocationStart(event.target.value)}
        />
      </label>

      <label className="initiative-action-field">
        <span>Fim *</span>
        <input
          type="date"
          value={allocationEnd}
          disabled={disabled || saving}
          onChange={(event) => setAllocationEnd(event.target.value)}
        />
      </label>

      <label className="initiative-action-field">
        <span>Quantidade *</span>
        <input
          type="number"
          min="0"
          step="0.01"
          value={allocatedAmount}
          disabled={disabled || saving}
          onChange={(event) => setAllocatedAmount(event.target.value)}
        />
      </label>

      <label className="initiative-action-field">
        <span>Observações</span>
        <textarea
          value={notes}
          disabled={disabled || saving}
          onChange={(event) => setNotes(event.target.value)}
        />
      </label>

      <label className="initiative-action-field">
        <span>Justificativa *</span>
        <textarea
          value={changeReason}
          disabled={disabled || saving}
          onChange={(event) => setChangeReason(event.target.value)}
          placeholder="Mínimo 10 caracteres"
        />
      </label>

      {error ? (
        <div
          className="initiative-action-message initiative-action-message--error"
          role="alert"
        >
          {error}
        </div>
      ) : null}

      <div>
        <button
          type="button"
          disabled={disabled || saving}
          onClick={() => void handleSave()}
        >
          {saving ? 'Salvando...' : 'Salvar edição'}
        </button>
        <button
          type="button"
          disabled={disabled || saving}
          onClick={() => {
            setAllocationStart(allocation.allocationStart)
            setAllocationEnd(allocation.allocationEnd)
            setAllocatedAmount(String(allocation.allocatedAmount))
            setNotes(allocation.notes ?? '')
            setChangeReason('')
            setError(null)
            setEditing(false)
            onEditingChange(false)
          }}
        >
          Cancelar edição
        </button>
      </div>
    </div>
  )
}
