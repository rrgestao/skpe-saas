import { useCallback, useEffect, useMemo, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import './StrategicFutureWorkspace.css'

type Props = {
  organizationId: string
  projectId: string
  formulationId: string | null
  onChanged?: () => void
}

type Initiative = {
  id: string
  code: string
  name: string
  status: string
}

type PortfolioItem = {
  initiative_id: string
}

type Risk = {
  id: string
  initiative_id: string
  code: string
  risk_event: string
  cause: string | null
  consequence: string | null
  probability: number | null
  impact: number | null
  inherent_score: number | null
  response_type: string | null
  response_plan: string | null
  owner_user_id: string | null
  response_due_date: string | null
  status: string
  residual_probability: number | null
  residual_impact: number | null
  validation_status: string
  metadata: Record<string, unknown> | null
}

type GovernancePerson = {
  person_id: string
  full_name: string
  preferred_name: string | null
}

type PersonProfile = {
  id: string
  profile_user_id: string | null
}

type OwnerOption = {
  userId: string
  name: string
}

const emptyForm = {
  id: '',
  initiativeId: '',
  code: '',
  riskEvent: '',
  cause: '',
  consequence: '',
  probability: '',
  impact: '',
  responseType: 'mitigate',
  responsePlan: '',
  ownerUserId: '',
  responseDueDate: '',
  residualProbability: '',
  residualImpact: '',
  acceptanceReason: '',
}

function validationLabel(value: string) {
  const labels: Record<string, string> = {
    draft: 'Em elaboração',
    pending_validation: 'Aguardando validação',
    validated: 'Validado',
  }
  return labels[value] ?? value
}

function riskStatusLabel(value: string) {
  const labels: Record<string, string> = {
    identified: 'Identificado',
    assessed: 'Avaliado',
    response_planned: 'Resposta planejada',
    monitoring: 'Em monitoramento',
    occurred: 'Materializado',
    closed: 'Encerrado',
    archived: 'Arquivado',
  }
  return labels[value] ?? value
}

export function StrategicImplementationRiskWorkspace({
  organizationId,
  projectId,
  formulationId,
  onChanged,
}: Props) {
  const [initiatives, setInitiatives] = useState<Initiative[]>([])
  const [risks, setRisks] = useState<Risk[]>([])
  const [owners, setOwners] = useState<OwnerOption[]>([])
  const [canManage, setCanManage] = useState(false)
  const [canValidate, setCanValidate] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [decisionNotes, setDecisionNotes] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  const load = useCallback(async () => {
    if (!formulationId) {
      setInitiatives([])
      setRisks([])
      return
    }

    const [
      portfolioResponse,
      initiativesResponse,
      risksResponse,
      peopleResponse,
      manageResponse,
      validateResponse,
    ] = await Promise.all([
      supabase
        .from('skpe_initiative_portfolio_items')
        .select('initiative_id')
        .eq('formulation_id', formulationId)
        .eq('selection_status', 'selected'),
      supabase
        .from('skpe_initiatives')
        .select('id,code,name,status')
        .eq('organization_id', organizationId)
        .eq('project_id', projectId)
        .is('archived_at', null)
        .order('code'),
      supabase
        .from('skpe_initiative_risks')
        .select(
          'id,initiative_id,code,risk_event,cause,consequence,probability,impact,inherent_score,response_type,response_plan,owner_user_id,response_due_date,status,residual_probability,residual_impact,validation_status,metadata',
        )
        .eq('organization_id', organizationId)
        .eq('project_id', projectId)
        .is('archived_at', null)
        .order('code'),
      supabase.rpc('get_skpe_governance_people', {
        target_organization_id: organizationId,
      }),
      supabase.rpc('can_manage_skpe_initiatives', {
        target_organization_id: organizationId,
      }),
      supabase.rpc('can_validate_skpe_formulation', {
        target_organization_id: organizationId,
      }),
    ])

    const error =
      portfolioResponse.error ??
      initiativesResponse.error ??
      risksResponse.error ??
      peopleResponse.error ??
      manageResponse.error ??
      validateResponse.error

    if (error) {
      setMessage(error.message)
      return
    }

    const selectedIds = new Set(
      ((portfolioResponse.data ?? []) as PortfolioItem[]).map(
        (item) => item.initiative_id,
      ),
    )

    setInitiatives(
      ((initiativesResponse.data ?? []) as Initiative[]).filter((initiative) =>
        selectedIds.has(initiative.id),
      ),
    )
    setRisks(
      ((risksResponse.data ?? []) as Risk[]).filter((risk) =>
        selectedIds.has(risk.initiative_id),
      ),
    )
    setCanManage(Boolean(manageResponse.data))
    setCanValidate(Boolean(validateResponse.data))

    const governancePeople = (peopleResponse.data ?? []) as GovernancePerson[]
    const personIds = governancePeople.map((person) => person.person_id)

    if (personIds.length === 0) {
      setOwners([])
      return
    }

    const { data: profiles, error: profilesError } = await supabase
      .from('sparks_people')
      .select('id,profile_user_id')
      .in('id', personIds)
      .not('profile_user_id', 'is', null)

    if (profilesError) {
      setMessage(profilesError.message)
      return
    }

    const userByPerson = new Map(
      ((profiles ?? []) as PersonProfile[])
        .filter((profile) => Boolean(profile.profile_user_id))
        .map((profile) => [profile.id, profile.profile_user_id as string]),
    )

    setOwners(
      governancePeople.flatMap((person) => {
        const userId = userByPerson.get(person.person_id)
        if (!userId) return []
        return [
          {
            userId,
            name: person.preferred_name?.trim() || person.full_name,
          },
        ]
      }),
    )
  }, [formulationId, organizationId, projectId])

  useEffect(() => {
    void load()
  }, [load])

  const selectedInitiativeIds = useMemo(
    () => new Set(initiatives.map((initiative) => initiative.id)),
    [initiatives],
  )

  const visibleRisks = useMemo(
    () => risks.filter((risk) => selectedInitiativeIds.has(risk.initiative_id)),
    [risks, selectedInitiativeIds],
  )

  const edit = (row: Risk) =>
    setForm({
      id: row.id,
      initiativeId: row.initiative_id,
      code: row.code,
      riskEvent: row.risk_event,
      cause: row.cause ?? '',
      consequence: row.consequence ?? '',
      probability: row.probability ? String(row.probability) : '',
      impact: row.impact ? String(row.impact) : '',
      responseType: row.response_type ?? 'mitigate',
      responsePlan: row.response_plan ?? '',
      ownerUserId: row.owner_user_id ?? '',
      responseDueDate: row.response_due_date ?? '',
      residualProbability: row.residual_probability
        ? String(row.residual_probability)
        : '',
      residualImpact: row.residual_impact ? String(row.residual_impact) : '',
      acceptanceReason: String(row.metadata?.acceptanceReason ?? ''),
    })

  const save = async () => {
    if (!formulationId) return

    if (
      !form.initiativeId ||
      !form.code.trim() ||
      form.riskEvent.trim().length < 5
    ) {
      setMessage(
        'Selecione a iniciativa e informe código e evento de risco.',
      )
      return
    }

    if (
      form.responseType === 'accept' &&
      form.acceptanceReason.trim().length < 10
    ) {
      setMessage(
        'Explique por que a aceitação do risco está sendo proposta antes de salvá-lo.',
      )
      return
    }

    const numeric = (value: string) =>
      value.trim() === '' ? null : Number(value)

    setBusy(true)
    setMessage('')

    const { error } = await supabase.rpc('upsert_skpe_initiative_risk', {
      p_initiative_id: form.initiativeId,
      p_risk_id: form.id || null,
      p_payload: {
        originFormulationId: formulationId,
        code: form.code.trim(),
        riskEvent: form.riskEvent.trim(),
        cause: form.cause.trim() || null,
        consequence: form.consequence.trim() || null,
        probability: numeric(form.probability),
        impact: numeric(form.impact),
        responseType: form.responseType || null,
        responsePlan: form.responsePlan.trim() || null,
        ownerUserId: form.ownerUserId || null,
        responseDueDate: form.responseDueDate || null,
        status: form.responsePlan.trim() ? 'response_planned' : 'identified',
        residualProbability: numeric(form.residualProbability),
        residualImpact: numeric(form.residualImpact),
        metadata: {
          proposalOnly: true,
          humanValidationRequired: true,
          implementationRisk: true,
          acceptanceReason:
            form.responseType === 'accept'
              ? form.acceptanceReason.trim()
              : null,
        },
      },
      p_change_reason: form.id
        ? 'Revisão governada de risco da implementação.'
        : 'Inclusão governada de risco da implementação.',
    })

    setBusy(false)

    if (error) {
      setMessage(error.message)
      return
    }

    setForm(emptyForm)
    setMessage(
      'Risco salvo como proposta. Nenhuma aceitação ou decisão institucional foi criada automaticamente.',
    )
    await load()
    onChanged?.()
  }

  const transitionValidation = async (
    riskId: string,
    action: 'submit_validation' | 'validate' | 'return_for_adjustments',
  ) => {
    if (
      action !== 'submit_validation' &&
      decisionNotes.trim().length < 10
    ) {
      setMessage(
        'Registre a justificativa da decisão com pelo menos 10 caracteres.',
      )
      return
    }

    setBusy(true)
    setMessage('')

    const { error } = await supabase.rpc(
      'transition_skpe_initiative_risk_validation',
      {
        p_risk_id: riskId,
        p_action: action,
        p_decision_notes: decisionNotes.trim() || null,
        p_change_reason:
          action === 'submit_validation'
            ? 'Submissão governada do risco da implementação à validação humana.'
            : 'Registro governado da decisão humana sobre o risco da implementação.',
      },
    )

    setBusy(false)

    if (error) {
      setMessage(error.message)
      return
    }

    setDecisionNotes('')
    setMessage(
      action === 'submit_validation'
        ? 'Risco submetido à validação humana.'
        : action === 'validate'
          ? 'Validação humana do risco registrada.'
          : 'Risco devolvido para ajustes.',
    )
    await load()
    onChanged?.()
  }

  if (!formulationId) return null

  return (
    <section className="skpe-implementation-risk-workspace">
      <header>
        <div>
          <span>Área de trabalho</span>
          <h3>Riscos da Implementação</h3>
          <p>
            Registre riscos vinculados às iniciativas selecionadas, suas causas,
            consequências e respostas. Riscos altos ou críticos exigem responsável,
            plano e prazo antes da validação. Nenhuma aceitação é automática.
          </p>
        </div>
      </header>

      {message ? (
        <div className="skpe-admin-message" role="status">
          {message}
        </div>
      ) : null}

      {visibleRisks.length === 0 ? (
        <p>Nenhum risco de implementação registrado para o portfólio selecionado.</p>
      ) : (
        <div className="skpe-implementation-risk-list">
          {visibleRisks.map((row) => {
            const initiative = initiatives.find(
              (item) => item.id === row.initiative_id,
            )
            return (
              <article key={row.id}>
                <div>
                  <small>
                    {validationLabel(row.validation_status)} ·{' '}
                    {riskStatusLabel(row.status)}
                  </small>
                  <strong>
                    {row.code} · {row.risk_event}
                  </strong>
                  <span>
                    {initiative
                      ? initiative.code + ' · ' + initiative.name
                      : 'Iniciativa não localizada'}
                  </span>
                </div>
                <div>
                  <span>
                    Probabilidade {row.probability ?? '—'} · Impacto{' '}
                    {row.impact ?? '—'} · Nível {row.inherent_score ?? '—'}
                  </span>
                  <p>{row.response_plan ?? 'Resposta ainda não definida.'}</p>
                </div>
                <div className="actions">
                  {canManage && row.validation_status === 'draft' ? (
                    <>
                      <button type="button" onClick={() => edit(row)}>
                        Editar proposta
                      </button>
                      <button
                        type="button"
                        onClick={() =>
                          void transitionValidation(row.id, 'submit_validation')
                        }
                        disabled={busy}
                      >
                        Submeter à validação
                      </button>
                    </>
                  ) : null}
                  {canValidate &&
                  row.validation_status === 'pending_validation' ? (
                    <>
                      <button
                        type="button"
                        onClick={() =>
                          void transitionValidation(row.id, 'validate')
                        }
                        disabled={busy}
                      >
                        Registrar validação
                      </button>
                      <button
                        type="button"
                        onClick={() =>
                          void transitionValidation(
                            row.id,
                            'return_for_adjustments',
                          )
                        }
                        disabled={busy}
                      >
                        Devolver para ajustes
                      </button>
                    </>
                  ) : null}
                </div>
              </article>
            )
          })}
        </div>
      )}

      {canValidate &&
      visibleRisks.some(
        (risk) => risk.validation_status === 'pending_validation',
      ) ? (
        <label className="skpe-implementation-risk-decision">
          <span>Justificativa da decisão de validação</span>
          <textarea
            value={decisionNotes}
            onChange={(event) => setDecisionNotes(event.target.value)}
            placeholder="Registre a fundamentação da decisão."
          />
        </label>
      ) : null}

      {canManage ? (
        <div className="skpe-implementation-risk-form">
          <label>
            <span>Iniciativa *</span>
            <select
              value={form.initiativeId}
              onChange={(event) =>
                setForm({ ...form, initiativeId: event.target.value })
              }
            >
              <option value="">Selecione</option>
              {initiatives.map((row) => (
                <option key={row.id} value={row.id}>
                  {row.code} · {row.name}
                </option>
              ))}
            </select>
          </label>
          <label>
            <span>Código *</span>
            <input
              value={form.code}
              onChange={(event) =>
                setForm({ ...form, code: event.target.value })
              }
            />
          </label>
          <label className="wide">
            <span>Evento de risco *</span>
            <textarea
              value={form.riskEvent}
              onChange={(event) =>
                setForm({ ...form, riskEvent: event.target.value })
              }
            />
          </label>
          <label>
            <span>Causa</span>
            <textarea
              value={form.cause}
              onChange={(event) =>
                setForm({ ...form, cause: event.target.value })
              }
            />
          </label>
          <label>
            <span>Consequência</span>
            <textarea
              value={form.consequence}
              onChange={(event) =>
                setForm({ ...form, consequence: event.target.value })
              }
            />
          </label>
          <label>
            <span>Probabilidade (1–5)</span>
            <input
              type="number"
              min="1"
              max="5"
              value={form.probability}
              onChange={(event) =>
                setForm({ ...form, probability: event.target.value })
              }
            />
          </label>
          <label>
            <span>Impacto (1–5)</span>
            <input
              type="number"
              min="1"
              max="5"
              value={form.impact}
              onChange={(event) =>
                setForm({ ...form, impact: event.target.value })
              }
            />
          </label>
          <label>
            <span>Resposta proposta</span>
            <select
              value={form.responseType}
              onChange={(event) =>
                setForm({ ...form, responseType: event.target.value })
              }
            >
              <option value="avoid">Evitar</option>
              <option value="mitigate">Mitigar</option>
              <option value="transfer">Transferir</option>
              <option value="accept">Aceitar</option>
            </select>
          </label>
          <label>
            <span>Responsável proposto</span>
            <select
              value={form.ownerUserId}
              onChange={(event) =>
                setForm({ ...form, ownerUserId: event.target.value })
              }
            >
              <option value="">A definir</option>
              {owners.map((owner) => (
                <option key={owner.userId} value={owner.userId}>
                  {owner.name}
                </option>
              ))}
            </select>
          </label>
          <label>
            <span>Prazo da resposta</span>
            <input
              type="date"
              value={form.responseDueDate}
              onChange={(event) =>
                setForm({ ...form, responseDueDate: event.target.value })
              }
            />
          </label>
          <label className="wide">
            <span>Plano de resposta</span>
            <textarea
              value={form.responsePlan}
              onChange={(event) =>
                setForm({ ...form, responsePlan: event.target.value })
              }
            />
          </label>
          {form.responseType === 'accept' ? (
            <label className="wide">
              <span>Justificativa para propor a aceitação *</span>
              <textarea
                value={form.acceptanceReason}
                onChange={(event) =>
                  setForm({ ...form, acceptanceReason: event.target.value })
                }
              />
            </label>
          ) : null}
          <label>
            <span>Probabilidade residual</span>
            <input
              type="number"
              min="1"
              max="5"
              value={form.residualProbability}
              onChange={(event) =>
                setForm({
                  ...form,
                  residualProbability: event.target.value,
                })
              }
            />
          </label>
          <label>
            <span>Impacto residual</span>
            <input
              type="number"
              min="1"
              max="5"
              value={form.residualImpact}
              onChange={(event) =>
                setForm({ ...form, residualImpact: event.target.value })
              }
            />
          </label>
          <div className="actions">
            {form.id ? (
              <button type="button" onClick={() => setForm(emptyForm)}>
                Cancelar
              </button>
            ) : null}
            <button type="button" onClick={() => void save()} disabled={busy}>
              {busy ? 'Salvando...' : 'Salvar proposta de risco'}
            </button>
          </div>
        </div>
      ) : null}
    </section>
  )
}
