import { useEffect, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

type Props = {
  organizationId: string
  formulationId: string
  cycleId: string
  onChanged: () => void
}

type Review = { id: string; code: string; title: string; status: string }
type Person = { userId: string; name: string }

export function MonitoringStrategyReviewPanel({
  organizationId,
  formulationId,
  cycleId,
  onChanged,
}: Props) {
  const [reviews, setReviews] = useState<Review[]>([])
  const [people, setPeople] = useState<Person[]>([])
  const [canGovern, setCanGovern] = useState(false)
  const [canRatify, setCanRatify] = useState(false)
  const [reviewId, setReviewId] = useState<string | null>(null)
  const [code, setCode] = useState('')
  const [title, setTitle] = useState('Reunião de Análise da Estratégia')
  const [scheduledAt, setScheduledAt] = useState('')
  const [heldAt, setHeldAt] = useState('')
  const [executiveSummary, setExecutiveSummary] = useState('')
  const [conclusions, setConclusions] = useState('')
  const [minutesReference, setMinutesReference] = useState('')

  const [findingType, setFindingType] = useState('information')
  const [analysisText, setAnalysisText] = useState('')
  const [rootCause, setRootCause] = useState('')
  const [recommendation, setRecommendation] = useState('')
  const [requiresDecision, setRequiresDecision] = useState(false)

  const [decisionCode, setDecisionCode] = useState('')
  const [decisionTitle, setDecisionTitle] = useState('')
  const [decisionText, setDecisionText] = useState('')
  const [decisionRationale, setDecisionRationale] = useState('')
  const [decisionPriority, setDecisionPriority] = useState('medium')
  const [decisionOwner, setDecisionOwner] = useState('')
  const [decisionDueDate, setDecisionDueDate] = useState('')

  const [learningCode, setLearningCode] = useState('')
  const [learningTitle, setLearningTitle] = useState('')
  const [learningEvidence, setLearningEvidence] = useState('')
  const [learningInterpretation, setLearningInterpretation] = useState('')
  const [learningLesson, setLearningLesson] = useState('')
  const [learningImpact, setLearningImpact] = useState('medium')
  const [learningRecommendation, setLearningRecommendation] = useState('')
  const [reason, setReason] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  const reload = async () => {
    const [reviewResponse, peopleResponse, linksResponse, governResponse, ratifyResponse] = await Promise.all([
      supabase.from('skpe_strategy_reviews').select('id,code,title,status').eq('monitoring_cycle_id', cycleId).eq('review_type', 'rae').order('created_at', { ascending: false }),
      supabase.rpc('get_skpe_governance_people', { target_organization_id: organizationId }),
      supabase.from('sparks_people').select('id,name,profile_user_id').eq('organization_id', organizationId).eq('active', true),
      supabase.rpc('can_manage_skpe_governance', { target_organization_id: organizationId }),
      supabase.rpc('can_ratify_skpe_governance', { target_organization_id: organizationId }),
    ])

    setReviews(reviewResponse.error ? [] : (reviewResponse.data ?? []) as Review[])
    const visiblePeople = peopleResponse.error ? [] : (peopleResponse.data ?? [])
    const personLinks = linksResponse.error ? [] : (linksResponse.data ?? [])
    const names = new Map<string, string>()
    for (const row of visiblePeople as Array<{ id: string; name?: string }>) names.set(row.id, row.name ?? 'Pessoa')
    setPeople((personLinks as Array<{ id: string; name?: string; profile_user_id: string | null }>)
      .filter((row) => Boolean(row.profile_user_id))
      .map((row) => ({ userId: row.profile_user_id as string, name: row.name ?? names.get(row.id) ?? 'Pessoa' })))
    setCanGovern(governResponse.error ? false : governResponse.data === true)
    setCanRatify(ratifyResponse.error ? false : ratifyResponse.data === true)
  }

  useEffect(() => {
    void reload()
  }, [cycleId, formulationId, organizationId])

  const selectedReview = reviews.find((review) => review.id === reviewId) ?? null
  const reviewMutable = !selectedReview || !['ratified', 'closed', 'cancelled'].includes(selectedReview.status)
  const reasonOk = reason.trim().length >= 10

  const saveReview = async () => {
    if (!canGovern || !reviewMutable || !reasonOk || !code.trim() || !title.trim()) return
    setBusy(true); setMessage('')
    const { data, error } = await supabase.rpc('upsert_skpe_strategy_review', {
      p_cycle_id: cycleId,
      p_review_id: reviewId,
      p_payload: {
        code: code.trim(), title: title.trim(), reviewType: 'rae', status: 'in_progress',
        scheduledAt: scheduledAt || null, heldAt: heldAt || null,
        executiveSummary: executiveSummary.trim() || null,
        conclusions: conclusions.trim() || null,
        minutesReference: minutesReference.trim() || null,
      },
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) { setMessage(error.message); return }
    if (typeof data === 'string') setReviewId(data)
    setMessage('RAE salva em andamento. A ratificação continua sendo decisão separada.')
    await reload(); onChanged()
  }

  const saveAnalysisItem = async () => {
    if (!canGovern || !reviewId || !reasonOk || !analysisText.trim()) return
    setBusy(true); setMessage('')
    const { error } = await supabase.rpc('upsert_skpe_strategy_review_item', {
      p_strategy_review_id: reviewId,
      p_item_id: null,
      p_payload: {
        entityType: 'monitoring_cycle',
        performanceStatus: 'not_assessed',
        findingType,
        analysisText: analysisText.trim(),
        rootCause: rootCause.trim() || null,
        recommendation: recommendation.trim() || null,
        requiresDecision,
      },
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) { setMessage(error.message); return }
    setMessage('Item de análise registrado na RAE.')
    setAnalysisText(''); setRootCause(''); setRecommendation(''); setRequiresDecision(false)
    onChanged()
  }

  const saveDecision = async () => {
    if (!canGovern || !reviewId || !reasonOk || !decisionCode.trim() || !decisionTitle.trim() || !decisionText.trim()) return
    if (['high', 'critical'].includes(decisionPriority) && (!decisionOwner || !decisionDueDate)) {
      setMessage('Decisão de alta criticidade exige responsável e prazo.'); return
    }
    setBusy(true); setMessage('')
    const { error } = await supabase.rpc('record_skpe_governance_decision', {
      p_strategy_review_id: reviewId,
      p_decision_id: null,
      p_payload: {
        code: decisionCode.trim(),
        title: decisionTitle.trim(),
        decisionText: decisionText.trim(),
        rationale: decisionRationale.trim() || null,
        decisionType: 'corrective_action',
        priority: decisionPriority,
        responsibleUserId: decisionOwner || null,
        dueDate: decisionDueDate || null,
        escalationLevel: 'none',
      },
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) { setMessage(error.message); return }
    setMessage('Decisão de governança registrada com responsável e prazo quando exigidos.')
    setDecisionCode(''); setDecisionTitle(''); setDecisionText(''); setDecisionRationale('')
    setDecisionPriority('medium'); setDecisionOwner(''); setDecisionDueDate('')
    onChanged()
  }

  const saveLearning = async () => {
    if (!canGovern || !reviewId || !reasonOk || !learningCode.trim() || !learningTitle.trim() || !learningEvidence.trim() || !learningLesson.trim()) return
    setBusy(true); setMessage('')
    const { error } = await supabase.rpc('record_skpe_strategic_learning', {
      p_formulation_id: formulationId,
      p_learning_id: null,
      p_payload: {
        monitoringCycleId: cycleId,
        strategyReviewId: reviewId,
        code: learningCode.trim(),
        title: learningTitle.trim(),
        evidenceText: learningEvidence.trim(),
        interpretationText: learningInterpretation.trim() || null,
        lessonText: learningLesson.trim(),
        impactLevel: learningImpact,
        recommendation: learningRecommendation.trim() || null,
      },
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) { setMessage(error.message); return }
    setMessage('Aprendizado estratégico registrado para análise de governança.')
    setLearningCode(''); setLearningTitle(''); setLearningEvidence('')
    setLearningInterpretation(''); setLearningLesson(''); setLearningRecommendation('')
    onChanged()
  }

  const ratifyReview = async () => {
    if (!canRatify || !reviewId || !reasonOk) return
    setBusy(true); setMessage('')
    const { error } = await supabase.rpc('ratify_skpe_strategy_review', {
      p_strategy_review_id: reviewId,
      p_change_reason: reason.trim(),
    })
    setBusy(false)
    if (error) { setMessage(error.message); return }
    setMessage('RAE ratificada humanamente.')
    await reload(); onChanged()
  }

  return (
    <section className="skpe-monitoring-governance" aria-label="RAE e governança estratégica">
      <header>
        <div><span>Governança estratégica</span><h3>RAE, decisões e aprendizado</h3></div>
      </header>

      <label>
        <span>RAE do ciclo</span>
        <select value={reviewId ?? ''} onChange={(event) => setReviewId(event.target.value || null)}>
          <option value="">Nova RAE</option>
          {reviews.map((review) => (
            <option key={review.id} value={review.id}>{review.code} · {review.title} · {review.status}</option>
          ))}
        </select>
      </label>

      <div className="skpe-monitoring-form-grid">
        <label><span>Código</span><input value={code} onChange={(e) => setCode(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
        <label><span>Título</span><input value={title} onChange={(e) => setTitle(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
        <label><span>Agendada para</span><input type="datetime-local" value={scheduledAt} onChange={(e) => setScheduledAt(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
        <label><span>Realizada em</span><input type="datetime-local" value={heldAt} onChange={(e) => setHeldAt(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
      </div>
      <label><span>Síntese executiva</span><textarea value={executiveSummary} onChange={(e) => setExecutiveSummary(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
      <label><span>Conclusões</span><textarea value={conclusions} onChange={(e) => setConclusions(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
      <label><span>Referência da ata/evidência</span><input value={minutesReference} onChange={(e) => setMinutesReference(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
      <div className="skpe-monitoring-actions">
        <button type="button" onClick={() => { void saveReview() }} disabled={!canGovern || !reviewMutable || busy || !reasonOk}>Salvar RAE</button>
        <button type="button" onClick={() => { void ratifyReview() }} disabled={!canRatify || !reviewId || busy || !reasonOk}>Ratificar RAE</button>
      </div>

      {reviewId ? (
        <>
          <h4>Item de análise</h4>
          <div className="skpe-monitoring-form-grid">
            <label><span>Tipo de achado</span><select value={findingType} onChange={(e) => setFindingType(e.target.value)}><option value="information">Informação</option><option value="attention">Atenção</option><option value="risk">Risco</option><option value="opportunity">Oportunidade</option></select></label>
            <label className="skpe-monitoring-checkbox"><input type="checkbox" checked={requiresDecision} onChange={(e) => setRequiresDecision(e.target.checked)} /><span>Requer decisão humana</span></label>
          </div>
          <label><span>Análise crítica</span><textarea value={analysisText} onChange={(e) => setAnalysisText(e.target.value)} /></label>
          <label><span>Causa-raiz</span><textarea value={rootCause} onChange={(e) => setRootCause(e.target.value)} /></label>
          <label><span>Recomendação</span><textarea value={recommendation} onChange={(e) => setRecommendation(e.target.value)} /></label>
          <button type="button" onClick={() => { void saveAnalysisItem() }} disabled={!canGovern || busy || !reasonOk || !analysisText.trim()}>Registrar análise</button>

          <h4>Decisão de governança</h4>
          <div className="skpe-monitoring-form-grid">
            <label><span>Código</span><input value={decisionCode} onChange={(e) => setDecisionCode(e.target.value)} /></label>
            <label><span>Título</span><input value={decisionTitle} onChange={(e) => setDecisionTitle(e.target.value)} /></label>
            <label><span>Prioridade</span><select value={decisionPriority} onChange={(e) => setDecisionPriority(e.target.value)}><option value="low">Baixa</option><option value="medium">Média</option><option value="high">Alta</option><option value="critical">Crítica</option></select></label>
            <label><span>Responsável</span><select value={decisionOwner} onChange={(e) => setDecisionOwner(e.target.value)}><option value="">Definir responsável</option>{people.map((person) => <option key={person.userId} value={person.userId}>{person.name}</option>)}</select></label>
            <label><span>Prazo</span><input type="date" value={decisionDueDate} onChange={(e) => setDecisionDueDate(e.target.value)} /></label>
          </div>
          <label><span>Decisão</span><textarea value={decisionText} onChange={(e) => setDecisionText(e.target.value)} /></label>
          <label><span>Fundamentação</span><textarea value={decisionRationale} onChange={(e) => setDecisionRationale(e.target.value)} /></label>
          <button type="button" onClick={() => { void saveDecision() }} disabled={!canGovern || busy || !reasonOk}>Registrar decisão</button>

          <h4>Aprendizado estratégico</h4>
          <div className="skpe-monitoring-form-grid">
            <label><span>Código</span><input value={learningCode} onChange={(e) => setLearningCode(e.target.value)} /></label>
            <label><span>Título</span><input value={learningTitle} onChange={(e) => setLearningTitle(e.target.value)} /></label>
            <label><span>Impacto</span><select value={learningImpact} onChange={(e) => setLearningImpact(e.target.value)}><option value="low">Baixo</option><option value="medium">Médio</option><option value="high">Alto</option><option value="critical">Crítico</option></select></label>
          </div>
          <label><span>Evidência</span><textarea value={learningEvidence} onChange={(e) => setLearningEvidence(e.target.value)} /></label>
          <label><span>Interpretação</span><textarea value={learningInterpretation} onChange={(e) => setLearningInterpretation(e.target.value)} /></label>
          <label><span>Lição aprendida</span><textarea value={learningLesson} onChange={(e) => setLearningLesson(e.target.value)} /></label>
          <label><span>Recomendação</span><textarea value={learningRecommendation} onChange={(e) => setLearningRecommendation(e.target.value)} /></label>
          <button type="button" onClick={() => { void saveLearning() }} disabled={!canGovern || busy || !reasonOk}>Registrar aprendizado</button>
        </>
      ) : null}

      <label><span>Justificativa auditável</span><textarea value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Explique a motivação da ação (mín. 10 caracteres)" /></label>
      {message ? <p className="skpe-monitoring-message">{message}</p> : null}
    </section>
  )
}
