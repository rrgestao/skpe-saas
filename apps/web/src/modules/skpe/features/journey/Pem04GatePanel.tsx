import { useCallback, useEffect, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

import './Pem04GatePanel.css'

type GateIssue = {
  code?: string
  severity?: string
  message?: string
}

type GateReadiness = {
  projectId?: string
  gateId?: string | null
  pem04Status?: string | null
  pem04Progress?: number | null
  formulationId?: string | null
  readyForClosure?: boolean
  blockingIssueCount?: number
  issues?: GateIssue[]
  activationReadiness?: {
    readyForCompletion?: boolean
  }
  communicationReadiness?: {
    readyForCompletion?: boolean
  }
  changeReadiness?: {
    readyForCompletion?: boolean
  }
  riskReadiness?: {
    readyForCompletion?: boolean
  }
}

type DecisionOutcome =
  | 'approved'
  | 'approved_with_reservations'
  | 'returned_for_adjustment'

type Props = {
  organizationId: string
  projectId: string | null
}

export function Pem04GatePanel({ organizationId, projectId }: Props) {
  const [readiness, setReadiness] = useState<GateReadiness | null>(null)
  const [canRatify, setCanRatify] = useState(false)
  const [outcome, setOutcome] = useState<DecisionOutcome>('approved')
  const [reason, setReason] = useState('')
  const [reservations, setReservations] = useState('')
  const [adjustments, setAdjustments] = useState('')
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')

  const refresh = useCallback(async () => {
    if (!projectId) {
      setReadiness(null)
      setCanRatify(false)
      return
    }

    const [readinessResponse, permissionResponse] = await Promise.all([
      supabase.rpc('get_skpe_pem04_gate_readiness', {
        target_project_id: projectId,
      }),
      supabase.rpc('can_ratify_skpe_governance', {
        target_organization_id: organizationId,
      }),
    ])

    if (readinessResponse.error) {
      setMessage(readinessResponse.error.message)
      setReadiness(null)
    } else {
      setReadiness((readinessResponse.data ?? null) as GateReadiness | null)
    }

    setCanRatify(Boolean(permissionResponse.data))
    if (permissionResponse.error) setMessage(permissionResponse.error.message)
  }, [organizationId, projectId])

  useEffect(() => {
    void refresh()
  }, [refresh])

  async function ratify() {
    if (!projectId) return

    if (reason.trim().length < 10) {
      setMessage('Registre uma justificativa com pelo menos 10 caracteres.')
      return
    }

    if (
      outcome === 'approved_with_reservations' &&
      reservations.trim().length < 10
    ) {
      setMessage('Descreva as ressalvas com pelo menos 10 caracteres.')
      return
    }

    if (
      outcome === 'returned_for_adjustment' &&
      adjustments.trim().length < 10
    ) {
      setMessage('Descreva os ajustes requeridos com pelo menos 10 caracteres.')
      return
    }

    if (
      (outcome === 'approved' || outcome === 'approved_with_reservations') &&
      !readiness?.readyForClosure
    ) {
      setMessage('A Macrofase 4 ainda possui pendências que impedem a decisão institucional.')
      return
    }

    setBusy(true)
    setMessage('')

    const { data, error } = await supabase.rpc('ratify_skpe_pem04_gate', {
      target_project_id: projectId,
      decision_outcome: outcome,
      decision_reason: reason.trim(),
      reservations:
        outcome === 'approved_with_reservations' ? reservations.trim() : null,
      adjustment_requirements:
        outcome === 'returned_for_adjustment' ? adjustments.trim() : null,
      change_reason: reason.trim(),
    })

    if (error) {
      setBusy(false)
      setMessage(error.message)
      return
    }

    void data

    const outcomeLabel: Record<DecisionOutcome, string> = {
      approved: 'Aprovada',
      approved_with_reservations: 'Aprovada com ressalvas',
      returned_for_adjustment: 'Devolvida para ajustes',
    }

    setMessage(`Decisão institucional registrada: ${outcomeLabel[outcome]}.`)
    setReason('')
    setReservations('')
    setAdjustments('')
    setBusy(false)
    await refresh()
  }

  if (!projectId || !readiness) return null

  const prerequisites = [
    {
      label: 'Macrofase 4 concluída',
      ok:
        readiness.pem04Status === 'completed' &&
        readiness.pem04Progress === 100,
      value:
        readiness.pem04Status === 'completed'
          ? `Concluída · ${readiness.pem04Progress ?? 100}%`
          : `Em andamento · ${readiness.pem04Progress ?? 0}%`,
    },
    {
      label: 'Ativação do Plano de Implementação',
      ok: Boolean(readiness.activationReadiness?.readyForCompletion),
      value: readiness.activationReadiness?.readyForCompletion
        ? 'Pronto'
        : 'Pendente',
    },
    {
      label: 'Comunicação e Mobilização',
      ok: Boolean(readiness.communicationReadiness?.readyForCompletion),
      value: readiness.communicationReadiness?.readyForCompletion
        ? 'Validado'
        : 'Pendente',
    },
    {
      label: 'Capacidades e Gestão da Mudança',
      ok: Boolean(readiness.changeReadiness?.readyForCompletion),
      value: readiness.changeReadiness?.readyForCompletion
        ? 'Validado'
        : 'Pendente',
    },
    {
      label: 'Gestão de Riscos da Implementação',
      ok: Boolean(readiness.riskReadiness?.readyForCompletion),
      value: readiness.riskReadiness?.readyForCompletion
        ? 'Pronto'
        : 'Pendente',
    },
  ]

  return (
    <section className="skpe-pem04-gate-panel">
      <header>
        <div>
          <small>Ponto de validação</small>
          <h3>Ratificação da Macrofase 4</h3>
          <p>
            Este ponto de validação confirma a Implementação e Mobilização preparada pela
            organização. Ele não inicia ações, envia comunicações, cria
            capacidades ou altera riscos; apenas registra o aceite executivo
            depois que todas as etapas e condições necessárias estiverem atendidas.
          </p>
        </div>
        <span className={readiness.readyForClosure ? 'is-ready' : 'is-blocked'}>
          {readiness.readyForClosure ? 'Pronto para decisão' : 'Bloqueado'}
        </span>
      </header>

      <div className="skpe-pem04-gate-prerequisites">
        {prerequisites.map((item) => (
          <article key={item.label} className={item.ok ? 'is-ok' : 'is-pending'}>
            <small>{item.ok ? 'Atendido' : 'Pendente'}</small>
            <strong>{item.label}</strong>
            <span>{item.value}</span>
          </article>
        ))}
      </div>

      {(readiness.issues?.length ?? 0) > 0 ? (
        <div className="skpe-pem04-gate-issues">
          <strong>Pendências bloqueantes</strong>
          <ul>
            {readiness.issues?.map((issue, index) => (
              <li key={(issue.code ?? 'issue') + ':' + index}>
                {issue.message ??
                  issue.code ??
                  'Pendência identificada pela solução.'}
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      {canRatify ? (
        <div className="skpe-pem04-gate-decision">
          <label>
            Decisão institucional
            <select
              value={outcome}
              onChange={(event) =>
                setOutcome(event.target.value as DecisionOutcome)
              }
            >
              <option value="approved">Aprovar Macrofase 4</option>
              <option value="approved_with_reservations">
                Aprovar com ressalvas
              </option>
              <option value="returned_for_adjustment">
                Devolver para ajustes
              </option>
            </select>
          </label>

          <label>
            Justificativa
            <textarea
              rows={4}
              value={reason}
              onChange={(event) => setReason(event.target.value)}
              placeholder="Registre a fundamentação da decisão institucional."
            />
          </label>

          {outcome === 'approved_with_reservations' ? (
            <label>
              Ressalvas
              <textarea
                rows={4}
                value={reservations}
                onChange={(event) => setReservations(event.target.value)}
              />
            </label>
          ) : null}

          {outcome === 'returned_for_adjustment' ? (
            <label>
              Ajustes requeridos
              <textarea
                rows={4}
                value={adjustments}
                onChange={(event) => setAdjustments(event.target.value)}
              />
            </label>
          ) : null}

          <button
            type="button"
            onClick={() => void ratify()}
            disabled={
              busy ||
              ((outcome === 'approved' ||
                outcome === 'approved_with_reservations') &&
                !readiness.readyForClosure)
            }
          >
            {busy ? 'Registrando decisão...' : 'Registrar decisão institucional'}
          </button>
        </div>
      ) : (
        <p className="skpe-pem04-gate-readonly">
          Você pode acompanhar a prontidão, mas não possui permissão para registrar esta decisão institucional.
        </p>
      )}

      {message ? <p className="skpe-pem04-gate-message">{message}</p> : null}
    </section>
  )
}

