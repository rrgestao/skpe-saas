
import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../../../../lib/supabase'
import './StrategicFutureWorkspace.css'

type Props = {
  organizationId: string
  formulationId: string | null
  onChanged?: () => void
}

type ChangePackage = {
  id: string
  applicability: string
  applicability_reason: string | null
  status: string
  owner_user_id: string | null
  validation_notes: string | null
}

type ChangeItem = {
  id: string
  gap_type: string
  affected_audience: string
  current_state: string
  required_state: string
  gap_description: string
  treatment_action: string
  owner_user_id: string | null
  target_date: string | null
  adoption_risk: string
  capacity_reference_required: boolean
  validation_status: string
  status: string
  display_order: number
}

const emptyForm = {
  id: '',
  gapType: 'other',
  affectedAudience: '',
  currentState: '',
  requiredState: '',
  gapDescription: '',
  treatmentAction: '',
  targetDate: '',
  adoptionRisk: 'medium',
  capacityReferenceRequired: false,
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

export function StrategicCapabilitiesChangeWorkspace({
  organizationId,
  formulationId,
  onChanged,
}: Props) {
  const [packageRow, setPackageRow] = useState<ChangePackage | null>(null)
  const [items, setItems] = useState<ChangeItem[]>([])
  const [canManage, setCanManage] = useState(false)
  const [canValidate, setCanValidate] = useState(false)
  const [applicability, setApplicability] = useState('applicable')
  const [applicabilityReason, setApplicabilityReason] = useState('')
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
        .from('skpe_implementation_change_packages')
        .select('id,applicability,applicability_reason,status,owner_user_id,validation_notes')
        .eq('formulation_id', formulationId)
        .maybeSingle(),
      supabase
        .from('skpe_implementation_change_items')
        .select('id,gap_type,affected_audience,current_state,required_state,gap_description,treatment_action,owner_user_id,target_date,adoption_risk,capacity_reference_required,validation_status,status,display_order')
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

    const loadedPackage = (packageResponse.data ?? null) as ChangePackage | null
    setPackageRow(loadedPackage)
    setItems((itemsResponse.data ?? []) as ChangeItem[])
    setCanManage(Boolean(manageResponse.data))
    setCanValidate(Boolean(validateResponse.data))
    if (loadedPackage) {
      setApplicability(loadedPackage.applicability)
      setApplicabilityReason(loadedPackage.applicability_reason ?? '')
    }
  }, [formulationId, organizationId])

  useEffect(() => { void load() }, [load])

  const configure = async () => {
    if (!formulationId) return
    if (applicability === 'no_material_gap' && applicabilityReason.trim().length < 10) {
      setMessage('Explique por que não há lacuna material com pelo menos 10 caracteres.')
      return
    }

    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('configure_skpe_pem0403_change_package', {
      target_formulation_id: formulationId,
      target_applicability: applicability,
      target_applicability_reason: applicabilityReason.trim() || null,
      target_owner_user_id: null,
      change_reason: 'Configuração governada da avaliação de Capacidades e Gestão da Mudança.',
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setMessage('Avaliação configurada em elaboração. Responsável permanece pendente de decisão humana.')
    await load()
    onChanged?.()
  }

  const edit = (item: ChangeItem) => {
    setForm({
      id: item.id,
      gapType: item.gap_type,
      affectedAudience: item.affected_audience,
      currentState: item.current_state,
      requiredState: item.required_state,
      gapDescription: item.gap_description,
      treatmentAction: item.treatment_action,
      targetDate: item.target_date ?? '',
      adoptionRisk: item.adoption_risk,
      capacityReferenceRequired: item.capacity_reference_required,
      displayOrder: item.display_order,
    })
  }

  const save = async () => {
    if (!formulationId) return
    if (
      form.affectedAudience.trim().length < 2 ||
      form.currentState.trim().length < 5 ||
      form.requiredState.trim().length < 5 ||
      form.gapDescription.trim().length < 5 ||
      form.treatmentAction.trim().length < 5
    ) {
      setMessage('Descreva público afetado, situação atual, situação requerida, lacuna e ação de tratamento.')
      return
    }

    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('upsert_skpe_pem0403_change_item', {
      target_formulation_id: formulationId,
      target_item_id: form.id || null,
      item_payload: {
        gapType: form.gapType,
        affectedAudience: form.affectedAudience.trim(),
        currentState: form.currentState.trim(),
        requiredState: form.requiredState.trim(),
        gapDescription: form.gapDescription.trim(),
        treatmentAction: form.treatmentAction.trim(),
        targetDate: form.targetDate || null,
        adoptionRisk: form.adoptionRisk,
        capacityReferenceRequired: form.capacityReferenceRequired,
        status: 'planned',
        displayOrder: form.displayOrder,
        metadata: {
          proposalLifecycle: 'sparks_proposal',
          humanValidationRequired: true,
        },
      },
      change_reason: form.id
        ? 'Revisão governada de lacuna de capacidade ou mudança.'
        : 'Inclusão governada de proposta de capacidade ou mudança.',
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setForm(emptyForm)
    setMessage('Proposta salva. Nenhuma responsabilidade ou capacidade foi atribuída automaticamente.')
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
    const { error } = await supabase.rpc('transition_skpe_pem0403_change_package', {
      target_formulation_id: formulationId,
      transition_action: action,
      decision_notes: decisionNotes.trim() || null,
      change_reason:
        action === 'submit_validation'
          ? 'Submissão governada da avaliação de Capacidades e Gestão da Mudança à validação humana.'
          : 'Registro governado de decisão humana sobre Capacidades e Gestão da Mudança.',
    })
    setBusy(false)
    if (error) {
      setMessage(error.message)
      return
    }
    setDecisionNotes('')
    setMessage(
      action === 'submit_validation'
        ? 'Avaliação submetida à validação humana.'
        : action === 'validate'
          ? 'Validação humana registrada.'
          : 'Avaliação devolvida para ajustes.',
    )
    await load()
    onChanged?.()
  }

  if (!formulationId) return null

  return (
    <section className="skpe-change-workspace">
      <header>
        <div>
          <span>Área de trabalho</span>
          <h3>Capacidades e Gestão da Mudança</h3>
          <p>Registre lacunas e propostas de tratamento sem inferir responsáveis nem duplicar a autoridade transversal de capacidade.</p>
        </div>
        <strong>{statusLabel(packageRow?.status)}</strong>
      </header>

      {message ? <div className="skpe-admin-message" role="status">{message}</div> : null}

      {canManage && packageRow?.status !== 'validated' ? (
        <div className="skpe-change-config">
          <label>
            <span>Há lacuna material de capacidade/mudança?</span>
            <select value={applicability} onChange={(e) => setApplicability(e.target.value)}>
              <option value="applicable">Sim — existem lacunas a tratar</option>
              <option value="no_material_gap">Não — nenhuma lacuna material identificada</option>
            </select>
          </label>
          <label>
            <span>Justificativa</span>
            <textarea value={applicabilityReason} onChange={(e) => setApplicabilityReason(e.target.value)} />
          </label>
          <button type="button" onClick={() => void configure()} disabled={busy}>Salvar enquadramento</button>
        </div>
      ) : null}

      {packageRow ? (
        <>
          {packageRow.applicability === 'applicable' ? (
            <>
              <div className="skpe-change-items">
                {items.length === 0 ? <p>Nenhuma lacuna registrada ainda.</p> : items.map((item) => (
                  <article key={item.id}>
                    <div>
                      <small>{statusLabel(item.validation_status)} · risco {item.adoption_risk}</small>
                      <strong>{item.affected_audience}</strong>
                      <p>{item.gap_description}</p>
                    </div>
                    <div><b>Tratamento</b><p>{item.treatment_action}</p></div>
                    {canManage && packageRow.status !== 'validated' ? <button type="button" onClick={() => edit(item)}>Editar proposta</button> : null}
                  </article>
                ))}
              </div>

              {canManage && packageRow.status !== 'validated' ? (
                <div className="skpe-change-form">
                  <h4>{form.id ? 'Revisar lacuna' : 'Adicionar lacuna/proposta'}</h4>
                  <div className="skpe-change-grid">
                    <label><span>Tipo de lacuna</span><select value={form.gapType} onChange={(e) => setForm({...form,gapType:e.target.value})}><option value="people">Pessoas</option><option value="process">Processos</option><option value="technology">Tecnologia</option><option value="governance">Governança</option><option value="culture">Cultura</option><option value="other">Outra</option></select></label>
                    <label><span>Risco de adoção</span><select value={form.adoptionRisk} onChange={(e) => setForm({...form,adoptionRisk:e.target.value})}><option value="low">Baixo</option><option value="medium">Médio</option><option value="high">Alto</option><option value="critical">Crítico</option></select></label>
                    <label className="wide"><span>Público afetado *</span><input value={form.affectedAudience} onChange={(e) => setForm({...form,affectedAudience:e.target.value})} /></label>
                    <label><span>Situação atual *</span><textarea value={form.currentState} onChange={(e) => setForm({...form,currentState:e.target.value})} /></label>
                    <label><span>Situação necessária *</span><textarea value={form.requiredState} onChange={(e) => setForm({...form,requiredState:e.target.value})} /></label>
                    <label className="wide"><span>Lacuna *</span><textarea value={form.gapDescription} onChange={(e) => setForm({...form,gapDescription:e.target.value})} /></label>
                    <label className="wide"><span>Ação de tratamento proposta *</span><textarea value={form.treatmentAction} onChange={(e) => setForm({...form,treatmentAction:e.target.value})} /></label>
                    <label><span>Data-alvo proposta</span><input type="date" value={form.targetDate} onChange={(e) => setForm({...form,targetDate:e.target.value})} /></label>
                    <label><span>Ordem</span><input type="number" value={form.displayOrder} onChange={(e) => setForm({...form,displayOrder:Number(e.target.value)})} /></label>
                    <label className="check"><input type="checkbox" checked={form.capacityReferenceRequired} onChange={(e) => setForm({...form,capacityReferenceRequired:e.target.checked})} /> Exige referência à capacidade quantitativa</label>
                  </div>
                  <div className="skpe-change-actions">
                    {form.id ? <button type="button" onClick={() => setForm(emptyForm)}>Cancelar edição</button> : null}
                    <button type="button" onClick={() => void save()} disabled={busy}>{busy ? 'Salvando...' : 'Salvar proposta'}</button>
                  </div>
                </div>
              ) : null}
            </>
          ) : (
            <div className="skpe-change-empty">
              <strong>Nenhuma lacuna material declarada.</strong>
              <p>{packageRow.applicability_reason ?? 'A justificativa ainda precisa ser registrada.'}</p>
            </div>
          )}

          <div className="skpe-change-decision">
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
      ) : null}
    </section>
  )
}
