
import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import './StrategicFutureWorkspace.css'

type Props = {
  organizationId: string
  formulationId: string | null
  onChanged?: () => void
}

type CommunicationItem = {
  id: string
  audience_label: string
  communication_objective: string
  key_message: string
  channel: string
  cadence: string
  owner_user_id: string | null
  planned_start_date: string | null
  planned_end_date: string | null
  mobilization_action: string | null
  evidence_required: boolean
  status: string
  validation_status: string
  display_order: number
}

type PackageRow = {
  id: string
  status: string
  validation_notes: string | null
}

const emptyForm = {
  id: '',
  audienceLabel: '',
  communicationObjective: '',
  keyMessage: '',
  channel: '',
  cadence: '',
  plannedStartDate: '',
  plannedEndDate: '',
  mobilizationAction: '',
  evidenceRequired: true,
  displayOrder: 10,
}

function statusLabel(value: string | null | undefined) {
  const labels: Record<string,string> = {
    draft: 'Em elaboração',
    in_elaboration: 'Em elaboração',
    pending_validation: 'Aguardando validação',
    validated: 'Validado',
    returned_for_adjustment: 'Devolvido para ajustes',
    planned: 'Planejado',
    active: 'Ativo',
    completed: 'Concluído',
  }
  return labels[value ?? ''] ?? value ?? 'Não iniciado'
}

export function StrategicCommunicationMobilizationWorkspace({
  organizationId,
  formulationId,
  onChanged,
}: Props) {
  const [packageRow, setPackageRow] = useState<PackageRow | null>(null)
  const [items, setItems] = useState<CommunicationItem[]>([])
  const [canManage, setCanManage] = useState(false)
  const [canValidate, setCanValidate] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [decisionNotes, setDecisionNotes] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  const load = useCallback(async () => {
    if (!formulationId) {
      setPackageRow(null)
      setItems([])
      return
    }

    const [packageResponse, itemsResponse, manageResponse, validateResponse] = await Promise.all([
      supabase
        .from('skpe_implementation_communication_packages')
        .select('id,status,validation_notes')
        .eq('formulation_id', formulationId)
        .maybeSingle(),
      supabase
        .from('skpe_implementation_communication_items')
        .select('id,audience_label,communication_objective,key_message,channel,cadence,owner_user_id,planned_start_date,planned_end_date,mobilization_action,evidence_required,status,validation_status,display_order')
        .eq('formulation_id', formulationId)
        .order('display_order'),
      supabase.rpc('can_manage_skpe_formulation', { target_organization_id: organizationId }),
      supabase.rpc('can_validate_skpe_formulation', { target_organization_id: organizationId }),
    ])

    const error = packageResponse.error ?? itemsResponse.error ?? manageResponse.error ?? validateResponse.error
    if (error) {
      setMessage(error.message)
      return
    }

    setPackageRow((packageResponse.data ?? null) as PackageRow | null)
    setItems((itemsResponse.data ?? []) as CommunicationItem[])
    setCanManage(Boolean(manageResponse.data))
    setCanValidate(Boolean(validateResponse.data))
  }, [formulationId, organizationId])

  useEffect(() => { void load() }, [load])

  const prepare = async () => {
    if (!formulationId) return
    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('ensure_skpe_pem0402_communication_package', {
      target_formulation_id: formulationId,
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setMessage('Plano de Comunicação e Mobilização preparado em elaboração.')
    await load()
    onChanged?.()
  }

  const edit = (item: CommunicationItem) => {
    setForm({
      id: item.id,
      audienceLabel: item.audience_label,
      communicationObjective: item.communication_objective,
      keyMessage: item.key_message,
      channel: item.channel,
      cadence: item.cadence,
      plannedStartDate: item.planned_start_date ?? '',
      plannedEndDate: item.planned_end_date ?? '',
      mobilizationAction: item.mobilization_action ?? '',
      evidenceRequired: item.evidence_required,
      displayOrder: item.display_order,
    })
  }

  const save = async () => {
    if (!formulationId) return
    if (
      form.audienceLabel.trim().length < 2 ||
      form.communicationObjective.trim().length < 5 ||
      form.keyMessage.trim().length < 5 ||
      form.channel.trim().length < 2 ||
      form.cadence.trim().length < 2
    ) {
      setMessage('Informe público, objetivo, mensagem, canal e cadência antes de salvar.')
      return
    }

    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('upsert_skpe_pem0402_communication_item', {
      target_formulation_id: formulationId,
      target_item_id: form.id || null,
      item_payload: {
        audienceLabel: form.audienceLabel.trim(),
        communicationObjective: form.communicationObjective.trim(),
        keyMessage: form.keyMessage.trim(),
        channel: form.channel.trim(),
        cadence: form.cadence.trim(),
        plannedStartDate: form.plannedStartDate || null,
        plannedEndDate: form.plannedEndDate || null,
        mobilizationAction: form.mobilizationAction.trim() || null,
        evidenceRequired: form.evidenceRequired,
        status: 'planned',
        displayOrder: form.displayOrder,
        metadata: {
          proposalLifecycle: 'sparks_proposal',
          humanValidationRequired: true,
        },
      },
      change_reason: form.id
        ? 'Revisão governada de item do Plano de Comunicação e Mobilização.'
        : 'Inclusão governada de proposta no Plano de Comunicação e Mobilização.',
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setForm(emptyForm)
    setMessage('Proposta salva. Nenhuma comunicação foi enviada.')
    await load()
    onChanged?.()
  }

  const transition = async (action: 'submit_validation' | 'validate' | 'return_for_adjustments') => {
    if (!formulationId) return
    if (action !== 'submit_validation' && decisionNotes.trim().length < 10) {
      setMessage('Registre a justificativa da decisão com pelo menos 10 caracteres.')
      return
    }

    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('transition_skpe_pem0402_communication_package', {
      target_formulation_id: formulationId,
      transition_action: action,
      decision_notes: decisionNotes.trim() || null,
      change_reason:
        action === 'submit_validation'
          ? 'Submissão governada do Plano de Comunicação e Mobilização à validação humana.'
          : 'Registro governado de decisão humana sobre o Plano de Comunicação e Mobilização.',
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setDecisionNotes('')
    setMessage(
      action === 'submit_validation'
        ? 'Plano submetido à validação humana.'
        : action === 'validate'
          ? 'Validação humana registrada.'
          : 'Plano devolvido para ajustes.',
    )
    await load()
    onChanged?.()
  }

  if (!formulationId) return null

  return (
    <section className="skpe-communication-workspace">
      <header>
        <div>
          <span>Área de trabalho</span>
          <h3>Plano de Comunicação e Mobilização</h3>
          <p>Construa as propostas por público antes da validação. Nenhuma mensagem é enviada automaticamente.</p>
        </div>
        <strong>{statusLabel(packageRow?.status)}</strong>
      </header>

      {message ? <div className="skpe-admin-message" role="status">{message}</div> : null}

      {!packageRow ? (
        <div className="skpe-communication-empty">
          <p>O plano ainda não foi preparado.</p>
          {canManage ? <button type="button" onClick={() => void prepare()} disabled={busy}>Preparar plano em elaboração</button> : null}
        </div>
      ) : (
        <>
          <div className="skpe-communication-items">
            {items.length === 0 ? <p>Nenhum público/mensagem cadastrado ainda.</p> : items.map((item) => (
              <article key={item.id}>
                <div>
                  <small>{statusLabel(item.validation_status)}</small>
                  <strong>{item.audience_label}</strong>
                  <p>{item.communication_objective}</p>
                  <span>{item.channel} · {item.cadence}</span>
                </div>
                <p>{item.key_message}</p>
                {canManage && packageRow.status !== 'validated' ? (
                  <button type="button" onClick={() => edit(item)}>Editar proposta</button>
                ) : null}
              </article>
            ))}
          </div>

          {canManage && packageRow.status !== 'validated' ? (
            <div className="skpe-communication-form">
              <h4>{form.id ? 'Revisar proposta' : 'Adicionar proposta'}</h4>
              <div className="skpe-communication-grid">
                <label><span>Público *</span><input value={form.audienceLabel} onChange={(e) => setForm({...form,audienceLabel:e.target.value})} /></label>
                <label><span>Canal *</span><input value={form.channel} onChange={(e) => setForm({...form,channel:e.target.value})} /></label>
                <label><span>Cadência *</span><input value={form.cadence} onChange={(e) => setForm({...form,cadence:e.target.value})} /></label>
                <label><span>Ordem</span><input type="number" value={form.displayOrder} onChange={(e) => setForm({...form,displayOrder:Number(e.target.value)})} /></label>
                <label className="wide"><span>Objetivo da comunicação *</span><textarea value={form.communicationObjective} onChange={(e) => setForm({...form,communicationObjective:e.target.value})} /></label>
                <label className="wide"><span>Mensagem-chave *</span><textarea value={form.keyMessage} onChange={(e) => setForm({...form,keyMessage:e.target.value})} /></label>
                <label><span>Início proposto</span><input type="date" value={form.plannedStartDate} onChange={(e) => setForm({...form,plannedStartDate:e.target.value})} /></label>
                <label><span>Fim proposto</span><input type="date" value={form.plannedEndDate} onChange={(e) => setForm({...form,plannedEndDate:e.target.value})} /></label>
                <label className="wide"><span>Ação de mobilização</span><textarea value={form.mobilizationAction} onChange={(e) => setForm({...form,mobilizationAction:e.target.value})} /></label>
                <label className="check"><input type="checkbox" checked={form.evidenceRequired} onChange={(e) => setForm({...form,evidenceRequired:e.target.checked})} /> Exigir evidência de realização/alcance</label>
              </div>
              <div className="skpe-communication-actions">
                {form.id ? <button type="button" onClick={() => setForm(emptyForm)}>Cancelar edição</button> : null}
                <button type="button" onClick={() => void save()} disabled={busy}>{busy ? 'Salvando...' : 'Salvar proposta'}</button>
              </div>
            </div>
          ) : null}

          <div className="skpe-communication-decision">
            <label><span>Justificativa da decisão</span><textarea value={decisionNotes} onChange={(e) => setDecisionNotes(e.target.value)} /></label>
            <div>
              {canManage && ['in_elaboration','returned_for_adjustment','draft'].includes(packageRow.status) ? (
                <button type="button" onClick={() => void transition('submit_validation')} disabled={busy}>Submeter à validação</button>
              ) : null}
              {canValidate && packageRow.status === 'pending_validation' ? (
                <>
                  <button type="button" onClick={() => void transition('validate')} disabled={busy}>Registrar validação</button>
                  <button type="button" onClick={() => void transition('return_for_adjustments')} disabled={busy}>Devolver para ajustes</button>
                </>
              ) : null}
            </div>
          </div>
        </>
      )}
    </section>
  )
}
