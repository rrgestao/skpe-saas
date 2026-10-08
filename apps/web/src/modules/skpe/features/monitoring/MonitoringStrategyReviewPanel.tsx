import { useEffect, useState } from 'react'

import { supabase } from '../../../../lib/supabase'

type Props = {
  organizationId: string
  formulationId: string
  cycleId: string
  onChanged: () => void
}

type Review = {
  id: string
  code: string
  title: string
  status: string
  scheduled_at: string | null
  held_at: string | null
  executive_summary: string | null
  conclusions: string | null
  minutes_reference: string | null
}

type Learning = {
  id: string
  code: string
  title: string
  status: string
  impact_level: string
  governance_decision: string | null
  created_at: string
}

type ReviewItem = {
  id: string
  finding_type: string
  analysis_text: string | null
  root_cause: string | null
  recommendation: string | null
  requires_decision: boolean
  status: string
}

type Person = { userId: string; name: string }

const learningStatusLabels: Record<string, string> = {
  identified: 'Identificado',
  under_analysis: 'Em análise',
  accepted: 'Aceito',
  rejected: 'Rejeitado',
  incorporated: 'Incorporado',
  archived: 'Arquivado',
}

const reviewStatusLabels: Record<string, string> = {
  draft: 'Em elaboração',
  in_progress: 'Em andamento',
  pending_ratification: 'Aguardando ratificação',
  ratified: 'Ratificada',
  closed: 'Encerrada',
  cancelled: 'Cancelada',
}

function dateTimeLocalValue(value: string | null) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60_000)
  return local.toISOString().slice(0, 16)
}

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
  const [reviewItems, setReviewItems] = useState<ReviewItem[]>([])
  const [selectedReviewItemId, setSelectedReviewItemId] = useState('')
  const [reviewItemsRefreshKey, setReviewItemsRefreshKey] = useState(0)

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
  const [learnings, setLearnings] = useState<Learning[]>([])
  const [learningGovernanceDecision, setLearningGovernanceDecision] = useState('')
  const [reason, setReason] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  const reload = async () => {
    const [reviewResponse, learningResponse, peopleResponse, linksResponse, governResponse, ratifyResponse] = await Promise.all([
      supabase
        .from('skpe_strategy_reviews')
        .select('id,code,title,status,scheduled_at,held_at,executive_summary,conclusions,minutes_reference')
        .eq('monitoring_cycle_id', cycleId)
        .eq('review_type', 'rae')
        .order('created_at', { ascending: false }),
      supabase
        .from('skpe_strategic_learnings')
        .select('id,code,title,status,impact_level,governance_decision,created_at')
        .eq('formulation_id', formulationId)
        .eq('monitoring_cycle_id', cycleId)
        .order('created_at', { ascending: false }),
      supabase.rpc('get_skpe_governance_people', { target_organization_id: organizationId }),
      supabase.from('sparks_people').select('id,name,profile_user_id').eq('organization_id', organizationId).eq('active', true),
      supabase.rpc('can_manage_skpe_governance', { target_organization_id: organizationId }),
      supabase.rpc('can_ratify_skpe_governance', { target_organization_id: organizationId }),
    ])

    setReviews(reviewResponse.error ? [] : (reviewResponse.data ?? []) as Review[])
    setLearnings(learningResponse.error ? [] : (learningResponse.data ?? []) as Learning[])
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

  useEffect(() => {
    let active = true

    async function loadReviewItems() {
      if (!reviewId) {
        setReviewItems([])
        setSelectedReviewItemId('')
        return
      }

      const { data, error } = await supabase
        .from('skpe_strategy_review_items')
        .select('id,finding_type,analysis_text,root_cause,recommendation,requires_decision,status')
        .eq('strategy_review_id', reviewId)
        .neq('status', 'archived')
        .order('display_order', { ascending: true })
        .order('created_at', { ascending: true })

      if (!active) return
      if (error) {
        setReviewItems([])
        return
      }

      const items = (data ?? []) as ReviewItem[]
      setReviewItems(items)
      setSelectedReviewItemId((current) =>
        current && items.some((item) => item.id === current) ? current : '',
      )
    }

    void loadReviewItems()
    return () => {
      active = false
    }
  }, [reviewId, reviewItemsRefreshKey])

  const selectedReview = reviews.find((review) => review.id === reviewId) ?? null
  const reviewMutable = !selectedReview || !['ratified', 'closed', 'cancelled'].includes(selectedReview.status)
  const reviewCanRatify = Boolean(
    selectedReview && ['in_progress', 'pending_ratification'].includes(selectedReview.status),
  )
  const learningEntryAllowed = Boolean(
    selectedReview && ['ratified', 'closed'].includes(selectedReview.status),
  )
  const reasonOk = reason.trim().length >= 10

  useEffect(() => {
    if (!selectedReview) {
      if (!reviewId) {
        setCode('')
        setTitle('Reunião de Análise da Estratégia')
        setScheduledAt('')
        setHeldAt('')
        setExecutiveSummary('')
        setConclusions('')
        setMinutesReference('')
      }
      return
    }

    setCode(selectedReview.code)
    setTitle(selectedReview.title)
    setScheduledAt(dateTimeLocalValue(selectedReview.scheduled_at))
    setHeldAt(dateTimeLocalValue(selectedReview.held_at))
    setExecutiveSummary(selectedReview.executive_summary ?? '')
    setConclusions(selectedReview.conclusions ?? '')
    setMinutesReference(selectedReview.minutes_reference ?? '')
  }, [reviewId, selectedReview])

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
    const { data, error } = await supabase.rpc('upsert_skpe_strategy_review_item', {
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
    if (typeof data === 'string') setSelectedReviewItemId(data)
    setReviewItemsRefreshKey((current) => current + 1)
    setMessage(
      requiresDecision
        ? 'Item de análise registrado. Vincule a decisão de governança a este item antes da ratificação.'
        : 'Item de análise registrado na RAE.',
    )
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
        strategyReviewItemId: selectedReviewItemId || null,
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
    if (
      !canGovern ||
      !learningEntryAllowed ||
      !reviewId ||
      !reasonOk ||
      !learningCode.trim() ||
      !learningTitle.trim() ||
      learningEvidence.trim().length < 5 ||
      learningInterpretation.trim().length < 10 ||
      learningLesson.trim().length < 10 ||
      learningRecommendation.trim().length < 10
    ) {
      setMessage(
        'Após a ratificação da RAE, informe código, título, evidência, interpretação, lição e recomendação substantivas antes de registrar o aprendizado.',
      )
      return
    }
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
    await reload()
    onChanged()
  }

  const transitionLearning = async (
    learningId: string,
    action: 'analyze' | 'accept' | 'reject' | 'incorporate' | 'reopen',
  ) => {
    if (!reasonOk) {
      setMessage('Informe uma justificativa auditável com pelo menos 10 caracteres.')
      return
    }
    const learning = learnings.find((item) => item.id === learningId) ?? null
    const requiresGovernanceDecision =
      action === 'incorporate' ||
      (action === 'accept' && Boolean(learning && ['high', 'critical'].includes(learning.impact_level)))

    if (requiresGovernanceDecision && learningGovernanceDecision.trim().length < 10) {
      setMessage(
        action === 'incorporate'
          ? 'A incorporação exige decisão de governança explícita com pelo menos 10 caracteres.'
          : 'Aprendizado de alto impacto exige decisão de governança explícita antes do aceite.',
      )
      return
    }

    setBusy(true)
    setMessage('')
    const { error } = await supabase.rpc('transition_skpe_strategic_learning', {
      p_learning_id: learningId,
      p_action: action,
      p_governance_decision:
        action === 'incorporate' || action === 'accept'
          ? learningGovernanceDecision.trim() || null
          : null,
      p_change_reason: reason.trim(),
    })
    setBusy(false)

    if (error) {
      setMessage(error.message)
      return
    }

    const labels: Record<string, string> = {
      analyze: 'Aprendizado encaminhado para análise.',
      accept: 'Aprendizado aceito por decisão humana.',
      reject: 'Aprendizado rejeitado por decisão humana.',
      incorporate: 'Aprendizado incorporado por autoridade de ratificação.',
      reopen: 'Aprendizado reaberto para nova análise.',
    }
    setMessage(labels[action])
    if (action === 'incorporate') setLearningGovernanceDecision('')
    await reload()
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
            <option key={review.id} value={review.id}>
              {review.code} · {review.title} · {reviewStatusLabels[review.status] ?? review.status}
            </option>
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
        <button type="button" onClick={() => { void ratifyReview() }} disabled={!canRatify || !reviewCanRatify || busy || !reasonOk}>Ratificar RAE</button>
      </div>

      {reviewId ? (
        <>
          {!reviewMutable ? (
            <p className="skpe-monitoring-empty">
              Esta RAE está {reviewStatusLabels[selectedReview?.status ?? '']?.toLocaleLowerCase('pt-BR') ?? 'encerrada'}.
              Análises e decisões anteriores permanecem imutáveis; o aprendizado segue lifecycle próprio.
            </p>
          ) : null}

          <h4>Item de análise</h4>
          <div className="skpe-monitoring-form-grid">
            <label>
              <span>Tipo de achado</span>
              <select value={findingType} onChange={(e) => setFindingType(e.target.value)} disabled={!canGovern || !reviewMutable}>
                <option value="information">Informação</option>
                <option value="attention">Atenção</option>
                <option value="risk">Risco</option>
                <option value="opportunity">Oportunidade</option>
              </select>
            </label>
            <label className="skpe-monitoring-checkbox">
              <input type="checkbox" checked={requiresDecision} onChange={(e) => setRequiresDecision(e.target.checked)} disabled={!canGovern || !reviewMutable} />
              <span>Requer decisão humana</span>
            </label>
          </div>
          <label><span>Análise crítica</span><textarea value={analysisText} onChange={(e) => setAnalysisText(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
          <label><span>Causa-raiz</span><textarea value={rootCause} onChange={(e) => setRootCause(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
          <label><span>Recomendação</span><textarea value={recommendation} onChange={(e) => setRecommendation(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
          <button type="button" onClick={() => { void saveAnalysisItem() }} disabled={!canGovern || !reviewMutable || busy || !reasonOk || !analysisText.trim()}>Registrar análise</button>

          <h4>Decisão de governança</h4>
          <label>
            <span>Item de análise relacionado</span>
            <select
              value={selectedReviewItemId}
              onChange={(e) => setSelectedReviewItemId(e.target.value)}
              disabled={!canGovern || !reviewMutable}
            >
              <option value="">Decisão geral da RAE</option>
              {reviewItems.map((item, index) => (
                <option key={item.id} value={item.id}>
                  {index + 1}. {item.finding_type} · {item.analysis_text?.slice(0, 90) || 'Item sem síntese'}
                  {item.requires_decision ? ' · decisão obrigatória' : ''}
                </option>
              ))}
            </select>
          </label>
          {reviewItems.some((item) => item.requires_decision) && !selectedReviewItemId ? (
            <p className="skpe-monitoring-empty">
              Há item(ns) marcado(s) como requerendo decisão. Selecione o item correspondente para que a decisão fique rastreável e satisfaça a prontidão da RAE.
            </p>
          ) : null}
          <div className="skpe-monitoring-form-grid">
            <label><span>Código</span><input value={decisionCode} onChange={(e) => setDecisionCode(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
            <label><span>Título</span><input value={decisionTitle} onChange={(e) => setDecisionTitle(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
            <label><span>Prioridade</span><select value={decisionPriority} onChange={(e) => setDecisionPriority(e.target.value)} disabled={!canGovern || !reviewMutable}><option value="low">Baixa</option><option value="medium">Média</option><option value="high">Alta</option><option value="critical">Crítica</option></select></label>
            <label><span>Responsável</span><select value={decisionOwner} onChange={(e) => setDecisionOwner(e.target.value)} disabled={!canGovern || !reviewMutable}><option value="">Definir responsável</option>{people.map((person) => <option key={person.userId} value={person.userId}>{person.name}</option>)}</select></label>
            <label><span>Prazo</span><input type="date" value={decisionDueDate} onChange={(e) => setDecisionDueDate(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
          </div>
          <label><span>Decisão</span><textarea value={decisionText} onChange={(e) => setDecisionText(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
          <label><span>Fundamentação</span><textarea value={decisionRationale} onChange={(e) => setDecisionRationale(e.target.value)} disabled={!canGovern || !reviewMutable} /></label>
          <button type="button" onClick={() => { void saveDecision() }} disabled={!canGovern || !reviewMutable || busy || !reasonOk}>Registrar decisão</button>

          <h4>Aprendizado estratégico</h4>
          {!learningEntryAllowed ? (
            <p className="skpe-monitoring-empty">
              O registro de aprendizado é liberado após a ratificação da RAE, preservando a sequência análise → decisão → ratificação → aprendizado.
            </p>
          ) : (
            <>
              <div className="skpe-monitoring-form-grid">
                <label><span>Código</span><input value={learningCode} onChange={(e) => setLearningCode(e.target.value)} disabled={!canGovern} /></label>
                <label><span>Título</span><input value={learningTitle} onChange={(e) => setLearningTitle(e.target.value)} disabled={!canGovern} /></label>
                <label><span>Impacto</span><select value={learningImpact} onChange={(e) => setLearningImpact(e.target.value)} disabled={!canGovern}><option value="low">Baixo</option><option value="medium">Médio</option><option value="high">Alto</option><option value="critical">Crítico</option></select></label>
              </div>
              <label><span>Evidência</span><textarea value={learningEvidence} onChange={(e) => setLearningEvidence(e.target.value)} disabled={!canGovern} /></label>
              <label><span>Interpretação</span><textarea value={learningInterpretation} onChange={(e) => setLearningInterpretation(e.target.value)} disabled={!canGovern} /></label>
              <label><span>Lição aprendida</span><textarea value={learningLesson} onChange={(e) => setLearningLesson(e.target.value)} disabled={!canGovern} /></label>
              <label><span>Recomendação</span><textarea value={learningRecommendation} onChange={(e) => setLearningRecommendation(e.target.value)} disabled={!canGovern} /></label>
              <button type="button" onClick={() => { void saveLearning() }} disabled={!canGovern || busy || !reasonOk}>Registrar aprendizado</button>
            </>
          )}

          {learnings.length > 0 ? (
            <section aria-label="Lifecycle dos aprendizados estratégicos">
              <h4>Aprendizados do ciclo</h4>
              <label>
                <span>Decisão de governança para aceite de alto impacto ou incorporação</span>
                <textarea
                  value={learningGovernanceDecision}
                  onChange={(e) => setLearningGovernanceDecision(e.target.value)}
                  placeholder="Registre a decisão institucional que orienta o aceite/incorporação quando aplicável."
                />
              </label>
              {learnings.map((learning) => (
                <article key={learning.id} className="skpe-monitoring-panel">
                  <header>
                    <div>
                      <span>{learning.code} · {learningStatusLabels[learning.status] ?? learning.status}</span>
                      <h4>{learning.title}</h4>
                    </div>
                  </header>
                  <p className="skpe-monitoring-empty">
                    Impacto: {learning.impact_level === 'critical' ? 'Crítico' : learning.impact_level === 'high' ? 'Alto' : learning.impact_level === 'low' ? 'Baixo' : 'Médio'}
                    {learning.governance_decision ? ` · Decisão: ${learning.governance_decision}` : ''}
                  </p>
                  <div className="skpe-monitoring-actions">
                    {learning.status === 'identified' ? (
                      <button type="button" disabled={!canGovern || busy || !reasonOk} onClick={() => { void transitionLearning(learning.id, 'analyze') }}>Enviar para análise</button>
                    ) : null}
                    {learning.status === 'under_analysis' ? (
                      <>
                        <button type="button" disabled={!canGovern || busy || !reasonOk} onClick={() => { void transitionLearning(learning.id, 'accept') }}>Aceitar</button>
                        <button type="button" disabled={!canGovern || busy || !reasonOk} onClick={() => { void transitionLearning(learning.id, 'reject') }}>Rejeitar</button>
                      </>
                    ) : null}
                    {learning.status === 'accepted' ? (
                      <button type="button" disabled={!canRatify || busy || !reasonOk} onClick={() => { void transitionLearning(learning.id, 'incorporate') }}>Incorporar aprendizado</button>
                    ) : null}
                    {learning.status === 'rejected' || learning.status === 'archived' ? (
                      <button type="button" disabled={!canGovern || busy || !reasonOk} onClick={() => { void transitionLearning(learning.id, 'reopen') }}>Reabrir</button>
                    ) : null}
                  </div>
                </article>
              ))}
            </section>
          ) : null}
        </>
      ) : null}

      <label><span>Justificativa auditável</span><textarea value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Explique a motivação da ação (mín. 10 caracteres)" /></label>
      {message ? <p className="skpe-monitoring-message">{message}</p> : null}
    </section>
  )
}
