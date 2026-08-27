import { useEffect, useState } from 'react'

import { translateBackendMessage } from '../../../../shared/i18n/ptBR'
import {
  loadPersonCapacityAudit,
  type PersonCapacityAuditEntry,
} from './personCapacity'
import {
  formatPersonCapacityAuditAction,
  formatPersonCapacityAuditActor,
  summarizePersonCapacityAuditChange,
} from './personCapacityAudit'

type PersonCapacityAuditHistoryProps = {
  organizationId: string
  capacityPeriodId: string
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

export function PersonCapacityAuditHistory({
  organizationId,
  capacityPeriodId,
}: PersonCapacityAuditHistoryProps) {
  const [entries, setEntries] = useState<PersonCapacityAuditEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let active = true

    setLoading(true)
    setErrorMessage(null)

    void loadPersonCapacityAudit(organizationId, capacityPeriodId)
      .then((items) => {
        if (!active) return
        setEntries(items)
      })
      .catch((error) => {
        if (!active) return
        setEntries([])
        setErrorMessage(
          error instanceof Error
            ? translateBackendMessage(error.message)
            : 'Não foi possível carregar o histórico de capacidade.',
        )
      })
      .finally(() => {
        if (!active) return
        setLoading(false)
      })

    return () => {
      active = false
    }
  }, [organizationId, capacityPeriodId])

  return (
    <div className="is-wide skpe-economic-dialog-note">
      <strong>Histórico auditável do período</strong>
      {loading ? (
        <p>Carregando histórico...</p>
      ) : errorMessage ? (
        <p>{errorMessage}</p>
      ) : entries.length === 0 ? (
        <p>Nenhum registro de auditoria encontrado para este período.</p>
      ) : (
        entries.map((entry) => {
          const changes = summarizePersonCapacityAuditChange(entry)

          return (
            <div key={entry.auditId}>
              <p>
                <strong>{formatPersonCapacityAuditAction(entry.actionCode)}</strong>
                {' · '}
                {formatOccurredAt(entry.occurredAt)}
              </p>
              <small>Executado por: {formatPersonCapacityAuditActor(entry)}</small>
              <br />
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
