import { useEffect, useState } from 'react'

import {
  loadInitiativeActionCapacityAllocationAudit,
  type InitiativeActionCapacityAuditEntry,
} from '../data/initiativeActionCapacityAuditData'
import {
  formatInitiativeActionCapacityAuditAction,
  summarizeInitiativeActionCapacityAuditChange,
} from '../contracts/initiativeActionCapacityAudit'

type InitiativeActionCapacityAuditHistoryProps = {
  organizationId: string
  allocationId: string
}

function formatOccurredAt(value: string) {
  const parsed = new Date(value)

  if (Number.isNaN(parsed.getTime())) {
    return value
  }

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(parsed)
}

export function InitiativeActionCapacityAuditHistory({
  organizationId,
  allocationId,
}: InitiativeActionCapacityAuditHistoryProps) {
  const [entries, setEntries] = useState<InitiativeActionCapacityAuditEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    setLoading(true)
    setErrorMessage(null)

    void loadInitiativeActionCapacityAllocationAudit(
      organizationId,
      allocationId,
    )
      .then((items) => {
        if (!active) return
        setEntries(items)
      })
      .catch((error) => {
        if (!active) return
        setEntries([])
        setErrorMessage(
          error instanceof Error
            ? error.message
            : 'Não foi possível carregar o histórico da alocação de capacidade.',
        )
      })
      .finally(() => {
        if (!active) return
        setLoading(false)
      })

    return () => {
      active = false
    }
  }, [allocationId, organizationId])

  return (
    <div className="initiative-action-drawer__note">
      <strong>Histórico auditável da alocação</strong>
      {loading ? (
        <p>Carregando histórico...</p>
      ) : errorMessage ? (
        <p>{errorMessage}</p>
      ) : entries.length === 0 ? (
        <p>Nenhum registro de auditoria encontrado para esta alocação.</p>
      ) : (
        entries.map((entry) => {
          const changes = summarizeInitiativeActionCapacityAuditChange(entry)

          return (
            <div key={entry.auditId}>
              <p>
                <strong>{formatInitiativeActionCapacityAuditAction(entry.actionCode)}</strong>
                {' · '}
                {formatOccurredAt(entry.occurredAt)}
              </p>
              <small>Justificativa: {entry.changeReason}</small>
              {changes.length > 0 ? (
                <ul>
                  {changes.map((change) => (
                    <li key={change}>{change}</li>
                  ))}
                </ul>
              ) : null}
            </div>
          )
        })
      )}
    </div>
  )
}
