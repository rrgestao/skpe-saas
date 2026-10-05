import { useCallback, useEffect, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

import './Pem02GatePanel.css'

type GateIssue = {
  code?: string
  severity?: string
  message?: string
}

type GateReadiness = {
  projectId?: string
  gateId?: string | null
  pem02Status?: string | null
  pem02Progress?: number | null
  strategicHorizonId?: string | null
  strategicHorizonStartYear?: number | null
  strategicHorizonEndYear?: number | null
  candidateFormulationId?: string | null
  formulationStatus?: string | null
  formulationRatification?: {
    readyForRatification?: boolean
    blockingIssueCount?: number
  } | null
  evolutionScenarioId?: string | null
  evolutionScenarioStatus?: string | null
  evolutionScenarioReadiness?: {
    structurally_ready?: boolean
    temporalization_complete?: boolean
    ready_to_ratify?: boolean
    cycle_count?: number
    undated_cycle_count?: number
  } | null
  evolutionPlanId?: string | null
  planWillBeMaterializedOnApproval?: boolean
  readyForClosure?: boolean
  blockingIssueCount?: number
  issues?: GateIssue[]
}

type DecisionOutcome =
  | 'approved'
  | 'approved_with_reservations'
  | 'returned_for_adjustment'

type Props = {
  organizationId: string
  projectId: string | null
}

export function Pem02GatePanel({ organizationId, projectId }: Props) {
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
      supabase.rpc('get_skpe_pem02_gate_readiness', {
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

    if (outcome === 'approved_with_reservations' && reservations.trim().length < 10) {
      setMessage('Descreva as ressalvas com pelo menos 10 caracteres.')
      return
    }

    if (outcome === 'returned_for_adjustment' && adjustments.trim().length < 10) {
      setMessage('Descreva os ajustes requeridos com pelo menos 10 caracteres.')
      return
    }

    if (
      (outcome === 'approved' || outcome === 'approved_with_reservations') &&
      !readiness?.readyForClosure
    ) {
      setMessage('A Macrofase 2 ainda possui pendências que impedem a decisão institucional.')
      return
    }

    setBusy(true)
    setMessage('')

    const { data, error } = await supabase.rpc('ratify_skpe_pem02_gate', {
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
      approved: 'Macrofase 2 aprovada',
      approved_with_reservations: 'Macrofase 2 aprovada com ressalvas',
      returned_for_adjustment: 'Macrofase 2 devolvida para ajustes',
    }

    setMessage(`Decisão institucional registrada: ${outcomeLabel[outcome]}.`)
    setReason('')
    setReservations('')
    setAdjustments('')
    setBusy(false)
    await refresh()
  }

  if (!projectId || !readiness) return null

  const horizonLabel =
    readiness.strategicHorizonStartYear && readiness.strategicHorizonEndYear
      ? `${readiness.strategicHorizonStartYear}–${readiness.strategicHorizonEndYear}`
      : 'Horizonte não identificado'

  const prerequisites = [
    {
      label: 'Macrofase 2 concluída',
      ok: readiness.pem02Status === 'completed' && readiness.pem02Progress === 100,
      value:
        readiness.pem02Status === 'completed'
          ? `Concluída · ${readiness.pem02Progress ?? 100}%`
          : 'Ainda não concluída',
    },
    {
      label: 'Horizonte Estratégico',
      ok: Boolean(readiness.strategicHorizonId),
      value: horizonLabel,
    },
    {
      label: 'Formulação Estratégica',
      ok: Boolean(readiness.formulationRatification?.readyForRatification),
      value: readiness.candidateFormulationId
        ? 'Pronta para validação institucional'
        : 'Ainda não consolidada',
    },
    {
      label: 'Plano de Evolução',
      ok: Boolean(
        readiness.evolutionPlanId || readiness.evolutionScenarioReadiness?.ready_to_ratify,
      ),
      value: readiness.evolutionPlanId
        ? 'Institucionalizado'
        : readiness.evolutionScenarioId
          ? `${readiness.evolutionScenarioReadiness?.cycle_count ?? 0} ciclos propostos · ${
              readiness.evolutionScenarioReadiness?.temporalization_complete
                ? 'prontos para validação'
                : 'datas ainda em definição'
            }`
          : 'Ainda não estruturado',
    },
    {
      label: 'Prontidão para decisão',
      ok: Boolean(readiness.readyForClosure),
      value:
        (readiness.blockingIssueCount ?? 0) === 0
          ? 'Nenhuma pendência'
          : `${readiness.blockingIssueCount} pendência(s)`,
    },
  ]

  return (
    <section className="skpe-pem02-gate-panel">
      <header>
        <div>
          <small>Ponto de validação</small>
          <h3>Ratificação da Macrofase 2</h3>
          <p>
            Ratifique a Formulação Estratégica e o Plano de Evolução antes de iniciar o Desdobramento Estratégico.
            A Macrofase 3 permanece bloqueada até que esta decisão institucional seja registrada.
          </p>
        </div>
        <span className={readiness.readyForClosure ? 'is-ready' : 'is-blocked'}>
          {readiness.readyForClosure ? 'Pronto para decisão' : 'Bloqueado'}
        </span>
      </header>

      <div className="skpe-pem02-gate-prerequisites">
        {prerequisites.map((item) => (
          <article key={item.label} className={item.ok ? 'is-ok' : 'is-pending'}>
            <small>{item.ok ? 'Atendido' : 'Pendente'}</small>
            <strong>{item.label}</strong>
            <span>{item.value}</span>
          </article>
        ))}
      </div>

      {(readiness.issues?.length ?? 0) > 0 ? (
        <div className="skpe-pem02-gate-issues">
          <strong>Pendências bloqueantes</strong>
          <ul>
            {readiness.issues?.map((issue, index) => (
              <li key={`${issue.code ?? 'issue'}:${index}`}>
                {issue.message ?? 'Pendência identificada pela solução.'}
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      {canRatify ? (
        <div className="skpe-pem02-gate-decision">
          <label>
            Decisão institucional
            <select
              value={outcome}
              onChange={(event) => setOutcome(event.target.value as DecisionOutcome)}
            >
              <option value="approved">Aprovar Macrofase 2</option>
              <option value="approved_with_reservations">Aprovar com ressalvas</option>
              <option value="returned_for_adjustment">Devolver para ajustes</option>
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
              ((outcome === 'approved' || outcome === 'approved_with_reservations') &&
                !readiness.readyForClosure)
            }
          >
            {busy ? 'Registrando decisão...' : 'Registrar decisão institucional'}
          </button>
        </div>
      ) : (
        <p className="skpe-pem02-gate-readonly">
          Você pode acompanhar a prontidão, mas não possui permissão para registrar esta decisão institucional.
        </p>
      )}

      {message ? <p className="skpe-pem02-gate-message">{message}</p> : null}
    </section>
  )
}
