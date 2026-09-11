import { useEffect, useMemo, useState } from 'react'

import { supabase } from '../../../lib/supabase'
import { translateBackendMessage } from '../../../shared/i18n/ptBR'
import { platformRoutes } from '../app/skpeRoutes'

import './MyMeetingsPanel.css'

type ReviewType =
  | 'rae'
  | 'executive'
  | 'governance'
  | 'assembly'
  | 'extraordinary'

type ReviewStatus =
  | 'draft'
  | 'scheduled'
  | 'in_progress'
  | 'pending_ratification'
  | 'ratified'
  | 'closed'
  | 'cancelled'

type CycleType =
  | 'monthly'
  | 'quarterly'
  | 'semester'
  | 'annual'
  | 'custom'

type CycleStatus =
  | 'planned'
  | 'open'
  | 'collecting'
  | 'under_review'
  | 'pending_ratification'
  | 'closed'
  | 'cancelled'
  | 'reopened'

type MeetingRole =
  | 'chair'
  | 'secretary'
  | 'chair_and_secretary'
  | 'none'

type MeetingFilter =
  | 'all'
  | 'attention'
  | 'upcoming'
  | 'today'
  | 'in_progress'
  | 'completed'

type MyMeeting = {
  strategy_review_id: string
  organization_id: string
  project_id: string
  formulation_id: string

  formulation_version_number: number
  formulation_version_label: string
  formulation_status: string

  monitoring_cycle_id: string
  cycle_code: string
  cycle_name: string
  cycle_type: CycleType
  cycle_period_start: string
  cycle_period_end: string
  cycle_status: CycleStatus

  code: string
  title: string
  review_type: ReviewType
  status: ReviewStatus

  scheduled_at: string | null
  held_at: string | null

  chair_user_id: string | null
  secretary_user_id: string | null
  current_user_role: MeetingRole

  participants: unknown
  participant_count: number | null

  executive_summary: string | null
  conclusions: string | null
  minutes_reference: string | null

  ratified_at: string | null
  ratified_by: string | null
  is_ratified: boolean

  is_scheduled: boolean
  is_today: boolean
  is_upcoming: boolean
  is_overdue: boolean
  days_until_meeting: number | null

  review_item_count: number
  open_review_item_count: number
  decision_count: number
  open_decision_count: number

  created_at: string
  updated_at: string
}

type RaeDecision = {
  id: string
  strategy_review_item_id: string | null
  code: string
  title: string
  decision_text: string
  rationale: string | null
  decision_type: string
  priority: string
  responsible_user_id: string | null
  due_date: string | null
  status: string
  escalation_level: string
  ratified_at: string | null
}

type RaeDecisionDraft = {
  strategyReviewItemId: string
  code: string
  title: string
  decisionText: string
  rationale: string
  decisionType: string
  priority: string
  dueDate: string
  escalationLevel: string
}
type RaeReviewItem = {
  id: string
  strategic_objective_id: string | null
  performance_status: string
  finding_type: string
  analysis_text: string | null
  root_cause: string | null
  recommendation: string | null
  requires_decision: boolean
  display_order: number
  status: string
  metadata: unknown
}

type RaeReviewItemDraft = {
  analysisText: string
  rootCause: string
  recommendation: string
  requiresDecision: boolean
  status: string
}
type RaeAgendaSuggestion = {
  strategicObjectiveId: string
  code: string
  name: string
  performance: number | null
  performanceStatus: string
  score: number
  reasons: string[]
  coveredInExercise: boolean
  causalRelationCount: number
  selected: boolean
}

type StrategicPerformancePayload = {
  objectives?: Array<{
    strategicObjectiveId: string
    code: string
    name: string
    performance: number | null
    performanceStatus: string
  }>
}

type ObjectiveRelationRow = {
  source_objective_id: string
  target_objective_id: string
  relation_type: string
  contribution_strength: string | null
}

type ReviewCoverageRow = {
  strategic_objective_id: string | null
  created_at: string
}
type MyMeetingsPanelProps = {
  organizationId: string
  projectId: string | null
}

const reviewTypeLabels: Record<ReviewType, string> = {
  rae: 'RAE',
  executive: 'Revisão executiva',
  governance: 'Governança',
  assembly: 'Assembleia',
  extraordinary: 'Reunião extraordinária',
}

const reviewStatusLabels: Record<ReviewStatus, string> = {
  draft: 'Rascunho',
  scheduled: 'Agendada',
  in_progress: 'Em andamento',
  pending_ratification: 'Pendente de ratificação',
  ratified: 'Ratificada',
  closed: 'Encerrada',
  cancelled: 'Cancelada',
}

const cycleTypeLabels: Record<CycleType, string> = {
  monthly: 'Mensal',
  quarterly: 'Trimestral',
  semester: 'Semestral',
  annual: 'Anual',
  custom: 'Personalizado',
}

const cycleStatusLabels: Record<CycleStatus, string> = {
  planned: 'Planejado',
  open: 'Aberto',
  collecting: 'Em coleta',
  under_review: 'Em análise',
  pending_ratification: 'Pendente de ratificação',
  closed: 'Encerrado',
  cancelled: 'Cancelado',
  reopened: 'Reaberto',
}

const meetingRoleLabels: Record<MeetingRole, string> = {
  chair: 'Presidência da reunião',
  secretary: 'Secretaria da reunião',
  chair_and_secretary: 'Presidência e secretaria',
  none: 'Sem papel pessoal comprovado',
}

function formatDate(value: string | null) {
  if (!value) return 'Não informado'

  const [year, month, day] = value.split('-').map(Number)

  if (!year || !month || !day) return value

  return new Intl.DateTimeFormat('pt-BR').format(
    new Date(year, month - 1, day),
  )
}

function formatDateTime(value: string | null) {
  if (!value) return 'Não informado'

  const date = new Date(value)

  if (Number.isNaN(date.getTime())) return value

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(date)
}

function formatMeetingSummary(item: MyMeeting) {
  if (item.status === 'in_progress') return 'Reunião em andamento'

  if (item.is_today) {
    return item.scheduled_at
      ? `Hoje · ${formatDateTime(item.scheduled_at)}`
      : 'Hoje'
  }

  if (item.is_overdue && item.days_until_meeting !== null) {
    const days = Math.abs(item.days_until_meeting)

    return `${days} ${
      days === 1 ? 'dia em atraso' : 'dias em atraso'
    }`
  }

  if (item.days_until_meeting === 1) return 'Amanhã'

  if (
    item.is_upcoming &&
    item.days_until_meeting !== null &&
    item.days_until_meeting > 1
  ) {
    return `Em ${item.days_until_meeting} dias`
  }

  if (item.held_at) {
    return `Realizada em ${formatDateTime(item.held_at)}`
  }

  if (item.scheduled_at) {
    return `Agendada para ${formatDateTime(item.scheduled_at)}`
  }

  return 'Sem agenda informada'
}

function isAttentionMeeting(item: MyMeeting) {
  return (
    item.is_overdue ||
    item.status === 'pending_ratification' ||
    item.open_review_item_count > 0 ||
    item.open_decision_count > 0
  )
}

function isCompletedMeeting(item: MyMeeting) {
  return (
    item.status === 'ratified' ||
    item.status === 'closed' ||
    item.held_at !== null
  )
}

export function MyMeetingsPanel({
  organizationId,
  projectId,
}: MyMeetingsPanelProps) {
  const [items, setItems] = useState<MyMeeting[]>([])
  const [filter, setFilter] = useState<MeetingFilter>('all')
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [reloadToken, setReloadToken] = useState(0)
  const [selectedRae, setSelectedRae] = useState<MyMeeting | null>(null)
  const [raeExecutiveSummary, setRaeExecutiveSummary] = useState('')
  const [raeConclusions, setRaeConclusions] = useState('')
  const [raeMinutesReference, setRaeMinutesReference] = useState('')
  const [raeChangeReason, setRaeChangeReason] = useState('')
  const [raeSaving, setRaeSaving] = useState(false)
  const [raeActionError, setRaeActionError] = useState<string | null>(null)
  const [raeActionSuccess, setRaeActionSuccess] = useState<string | null>(null)
  // RAE_FE01_EDIT_RATIFY
  const [raeAgendaSuggestions, setRaeAgendaSuggestions] = useState<RaeAgendaSuggestion[]>([])
  const [raeAgendaLoading, setRaeAgendaLoading] = useState(false)
  const [raeAgendaMaterializing, setRaeAgendaMaterializing] = useState(false)
  // RAE_FE02A_PAUTA_SUGERIDA
  const [raeReviewItems, setRaeReviewItems] = useState<RaeReviewItem[]>([])
  const [raeReviewDrafts, setRaeReviewDrafts] = useState<Record<string, RaeReviewItemDraft>>({})
  const [raeReviewLoading, setRaeReviewLoading] = useState(false)
  const [raeReviewSavingId, setRaeReviewSavingId] = useState<string | null>(null)
  // RAE_FE02B_ANALISE_PAUTA
  const [raeDecisions, setRaeDecisions] = useState<RaeDecision[]>([])
  const [raeDecisionLoading, setRaeDecisionLoading] = useState(false)
  const [raeDecisionSaving, setRaeDecisionSaving] = useState(false)
  const [raeDecisionDraft, setRaeDecisionDraft] = useState<RaeDecisionDraft>({
    strategyReviewItemId: '',
    code: '',
    title: '',
    decisionText: '',
    rationale: '',
    decisionType: 'corrective_action',
    priority: 'medium',
    dueDate: '',
    escalationLevel: 'none',
  })
  // RAE_FE03A_DELIBERACOES
  const [raeDecisionTransitionId, setRaeDecisionTransitionId] = useState<string | null>(null)
  const [raeDecisionCompletionNotes, setRaeDecisionCompletionNotes] = useState<Record<string, string>>({})
  // RAE_FE03B_CICLO_DELIBERACAO

  useEffect(() => {
    let active = true

    async function loadMeetings() {
      setLoading(true)
      setErrorMessage(null)

      const { data, error } = await supabase.rpc(
        'get_my_skpe_meetings',
        {
          target_organization_id: organizationId,
          target_project_id: projectId,
          target_formulation_id: null,
        },
      )

      if (!active) return

      if (error) {
        setItems([])
        setErrorMessage(
          `Não foi possível carregar suas reuniões: ${translateBackendMessage(error.message)}`,
        )
        setLoading(false)
        return
      }

      setItems((data ?? []) as MyMeeting[])
      setLoading(false)
    }

    void loadMeetings()

    return () => {
      active = false
    }
  }, [organizationId, projectId, reloadToken])

  const counts = useMemo(
    () => ({
      all: items.length,
      attention: items.filter((item) => isAttentionMeeting(item)).length,
      upcoming: items.filter((item) => item.is_upcoming).length,
      today: items.filter((item) => item.is_today).length,
      in_progress: items.filter((item) => item.status === 'in_progress').length,
      completed: items.filter((item) => isCompletedMeeting(item)).length,
    }),
    [items],
  )

  const visibleItems = useMemo(() => {
    if (filter === 'all') return items

    if (filter === 'attention') {
      return items.filter((item) => isAttentionMeeting(item))
    }

    if (filter === 'upcoming') {
      return items.filter((item) => item.is_upcoming)
    }

    if (filter === 'today') {
      return items.filter((item) => item.is_today)
    }

    if (filter === 'completed') {
      return items.filter((item) => isCompletedMeeting(item))
    }

    return items.filter((item) => item.status === 'in_progress')
  }, [filter, items])

  async function loadRaeDecisions(reviewId: string) {
    setRaeDecisionLoading(true)
    setRaeActionError(null)

    const { data, error } = await supabase
      .from('skpe_governance_decisions')
      .select(
        'id,strategy_review_item_id,code,title,decision_text,rationale,decision_type,priority,responsible_user_id,due_date,status,escalation_level,ratified_at',
      )
      .eq('strategy_review_id', reviewId)
      .order('created_at', { ascending: true })

    if (error) {
      setRaeDecisions([])
      setRaeActionError(translateBackendMessage(error.message))
      setRaeDecisionLoading(false)
      return
    }

    setRaeDecisions((data ?? []) as RaeDecision[])
    setRaeDecisionLoading(false)
  }

  function resetRaeDecisionDraft() {
    setRaeDecisionDraft({
      strategyReviewItemId: '',
      code: '',
      title: '',
      decisionText: '',
      rationale: '',
      decisionType: 'corrective_action',
      priority: 'medium',
      dueDate: '',
      escalationLevel: 'none',
    })
  }

  async function transitionRaeDecision(
    decision: RaeDecision,
    action: 'start' | 'block' | 'complete' | 'cancel' | 'reopen' | 'ratify',
  ) {
    if (!selectedRae) return

    const reason = raeChangeReason.trim()
    if (!reason) {
      setRaeActionError(
        'Informe o motivo da alteração para preservar a rastreabilidade da deliberação.',
      )
      return
    }

    const notes = (raeDecisionCompletionNotes[decision.id] ?? '').trim()

    if ((action === 'complete' || action === 'cancel') && !notes) {
      setRaeActionError(
        'Informe a nota de conclusão/cancelamento antes de concluir esta transição.',
      )
      return
    }

    if (
      action === 'ratify' &&
      !['ratified', 'closed'].includes(selectedRae.status)
    ) {
      setRaeActionError(
        'A decisão só pode ser ratificada depois que a própria RAE estiver ratificada.',
      )
      return
    }

    setRaeDecisionTransitionId(decision.id)
    setRaeActionError(null)
    setRaeActionSuccess(null)

    const { error } = await supabase.rpc(
      'transition_skpe_governance_decision',
      {
        p_decision_id: decision.id,
        p_action: action,
        p_completion_notes:
          action === 'complete' || action === 'cancel' ? notes : null,
        p_change_reason: reason,
      },
    )

    if (error) {
      setRaeActionError(translateBackendMessage(error.message))
      setRaeDecisionTransitionId(null)
      return
    }

    setRaeActionSuccess('Situação da deliberação atualizada com rastreabilidade.')
    await loadRaeDecisions(selectedRae.strategy_review_id)
    setReloadToken((value) => value + 1)
    setRaeDecisionTransitionId(null)
  }
  async function createRaeDecision() {
    if (!selectedRae) return

    const reason = raeChangeReason.trim()
    if (!reason) {
      setRaeActionError(
        'Informe o motivo da alteração para preservar a rastreabilidade da deliberação.',
      )
      return
    }

    if (
      !raeDecisionDraft.code.trim() ||
      !raeDecisionDraft.title.trim() ||
      !raeDecisionDraft.decisionText.trim()
    ) {
      setRaeActionError(
        'Código, título e texto da decisão são obrigatórios para registrar a deliberação.',
      )
      return
    }

    setRaeDecisionSaving(true)
    setRaeActionError(null)
    setRaeActionSuccess(null)

    const { error } = await supabase.rpc('record_skpe_governance_decision', {
      p_strategy_review_id: selectedRae.strategy_review_id,
      p_decision_id: null,
      p_payload: {
        strategyReviewItemId:
          raeDecisionDraft.strategyReviewItemId.trim() || null,
        code: raeDecisionDraft.code.trim(),
        title: raeDecisionDraft.title.trim(),
        decisionText: raeDecisionDraft.decisionText.trim(),
        rationale: raeDecisionDraft.rationale.trim() || null,
        decisionType: raeDecisionDraft.decisionType,
        priority: raeDecisionDraft.priority,
        responsibleUserId: null,
        dueDate: raeDecisionDraft.dueDate || null,
        escalationLevel: raeDecisionDraft.escalationLevel,
        linkedInitiativeActionId: null,
        metadata: {
          source: 'rae_frontend',
          destination: 'to_be_classified',
        },
      },
      p_change_reason: reason,
    })

    if (error) {
      setRaeActionError(translateBackendMessage(error.message))
      setRaeDecisionSaving(false)
      return
    }

    setRaeActionSuccess('Deliberação registrada com rastreabilidade.')
    resetRaeDecisionDraft()
    await loadRaeDecisions(selectedRae.strategy_review_id)
    setReloadToken((value) => value + 1)
    setRaeDecisionSaving(false)
  }
  async function loadRaeReviewItems(reviewId: string) {
    setRaeReviewLoading(true)
    setRaeActionError(null)

    const { data, error } = await supabase
      .from('skpe_strategy_review_items')
      .select(
        'id,strategic_objective_id,performance_status,finding_type,analysis_text,root_cause,recommendation,requires_decision,display_order,status,metadata',
      )
      .eq('strategy_review_id', reviewId)
      .order('display_order', { ascending: true })

    if (error) {
      setRaeReviewItems([])
      setRaeReviewDrafts({})
      setRaeActionError(translateBackendMessage(error.message))
      setRaeReviewLoading(false)
      return
    }

    const items = (data ?? []) as RaeReviewItem[]
    setRaeReviewItems(items)

    const drafts: Record<string, RaeReviewItemDraft> = {}
    for (const item of items) {
      drafts[item.id] = {
        analysisText: item.analysis_text ?? '',
        rootCause: item.root_cause ?? '',
        recommendation: item.recommendation ?? '',
        requiresDecision: item.requires_decision,
        status: item.status,
      }
    }
    setRaeReviewDrafts(drafts)
    setRaeReviewLoading(false)
  }

  function updateRaeReviewDraft(
    itemId: string,
    patch: Partial<RaeReviewItemDraft>,
  ) {
    setRaeReviewDrafts((current) => ({
      ...current,
      [itemId]: {
        ...(current[itemId] ?? {
          analysisText: '',
          rootCause: '',
          recommendation: '',
          requiresDecision: false,
          status: 'open',
        }),
        ...patch,
      },
    }))
  }

  async function saveRaeReviewItem(item: RaeReviewItem) {
    if (!selectedRae) return

    const reason = raeChangeReason.trim()
    if (!reason) {
      setRaeActionError(
        'Informe o motivo da alteração para preservar a rastreabilidade da análise.',
      )
      return
    }

    const draft = raeReviewDrafts[item.id]
    if (!draft) return

    setRaeReviewSavingId(item.id)
    setRaeActionError(null)
    setRaeActionSuccess(null)

    const { error } = await supabase.rpc('upsert_skpe_strategy_review_item', {
      p_strategy_review_id: selectedRae.strategy_review_id,
      p_item_id: item.id,
      p_payload: {
        entityType: 'strategic_objective',
        strategicObjectiveId: item.strategic_objective_id,
        performanceStatus: item.performance_status,
        findingType: item.finding_type,
        analysisText: draft.analysisText.trim() || null,
        rootCause: draft.rootCause.trim() || null,
        recommendation: draft.recommendation.trim() || null,
        requiresDecision: draft.requiresDecision,
        displayOrder: item.display_order,
        status: draft.status,
        metadata: item.metadata ?? {},
      },
      p_change_reason: reason,
    })

    if (error) {
      setRaeActionError(translateBackendMessage(error.message))
      setRaeReviewSavingId(null)
      return
    }

    setRaeActionSuccess('Item da RAE atualizado com rastreabilidade.')
    await loadRaeReviewItems(selectedRae.strategy_review_id)
    setReloadToken((value) => value + 1)
    setRaeReviewSavingId(null)
  }
  async function suggestRaeAgenda() {
    if (!selectedRae) return

    setRaeAgendaLoading(true)
    setRaeActionError(null)
    setRaeActionSuccess(null)

    const performanceResult = await supabase.rpc('get_skpe_strategic_performance', {
      p_cycle_id: selectedRae.monitoring_cycle_id,
    })

    if (performanceResult.error) {
      setRaeActionError(translateBackendMessage(performanceResult.error.message))
      setRaeAgendaLoading(false)
      return
    }

    const payload = (performanceResult.data ?? {}) as StrategicPerformancePayload
    const objectives = payload.objectives ?? []

    const relationsResult = await supabase
      .from('skpe_objective_relations')
      .select(
        'source_objective_id,target_objective_id,relation_type,contribution_strength',
      )
      .eq('formulation_id', selectedRae.formulation_id)

    if (relationsResult.error) {
      setRaeActionError(translateBackendMessage(relationsResult.error.message))
      setRaeAgendaLoading(false)
      return
    }

    const exerciseYear = Number(selectedRae.cycle_period_start.slice(0, 4))
    const yearStart = `${exerciseYear}-01-01T00:00:00.000Z`
    const yearEnd = `${exerciseYear}-12-31T23:59:59.999Z`

    const coverageResult = await supabase
      .from('skpe_strategy_review_items')
      .select('strategic_objective_id,created_at')
      .eq('formulation_id', selectedRae.formulation_id)
      .eq('entity_type', 'strategic_objective')
      .gte('created_at', yearStart)
      .lte('created_at', yearEnd)

    if (coverageResult.error) {
      setRaeActionError(translateBackendMessage(coverageResult.error.message))
      setRaeAgendaLoading(false)
      return
    }

    const relations = (relationsResult.data ?? []) as ObjectiveRelationRow[]
    const coverage = (coverageResult.data ?? []) as ReviewCoverageRow[]
    const coveredIds = new Set(
      coverage
        .map((item) => item.strategic_objective_id)
        .filter((value): value is string => Boolean(value)),
    )

    const criticalIds = new Set(
      objectives
        .filter((item) =>
          ['critical', 'attention'].includes(item.performanceStatus),
        )
        .map((item) => item.strategicObjectiveId),
    )

    const causalNeighborIds = new Set<string>()
    for (const relation of relations) {
      if (relation.relation_type !== 'cause_effect') continue

      if (criticalIds.has(relation.source_objective_id)) {
        causalNeighborIds.add(relation.target_objective_id)
      }
      if (criticalIds.has(relation.target_objective_id)) {
        causalNeighborIds.add(relation.source_objective_id)
      }
    }

    const suggestions = objectives
      .map<RaeAgendaSuggestion>((objective) => {
        const reasons: string[] = []
        let score = 0

        if (objective.performanceStatus === 'critical') {
          score += 100
          reasons.push('desempenho crítico')
        } else if (objective.performanceStatus === 'attention') {
          score += 70
          reasons.push('desempenho em atenção')
        } else if (objective.performanceStatus === 'not_assessed') {
          score += 35
          reasons.push('desempenho ainda não apurado')
        }

        const causalRelations = relations.filter(
          (relation) =>
            relation.relation_type === 'cause_effect' &&
            (relation.source_objective_id === objective.strategicObjectiveId ||
              relation.target_objective_id === objective.strategicObjectiveId),
        )

        if (causalNeighborIds.has(objective.strategicObjectiveId)) {
          score += 35
          reasons.push('integra caminho causal associado a OE crítico/em atenção')
        }

        const strongRelations = causalRelations.filter(
          (relation) => relation.contribution_strength === 'strong',
        ).length

        if (strongRelations > 0) {
          score += Math.min(strongRelations * 10, 30)
          reasons.push(
            `${strongRelations} relação(ões) causal(is) forte(s) no Mapa Estratégico`,
          )
        }

        const coveredInExercise = coveredIds.has(objective.strategicObjectiveId)
        if (!coveredInExercise) {
          score += 25
          reasons.push('OE ainda não analisado em RAE neste exercício')
        }

        if (reasons.length === 0) {
          reasons.push('acompanhamento regular da estratégia')
        }

        const selected =
          objective.performanceStatus === 'critical' ||
          objective.performanceStatus === 'attention' ||
          causalNeighborIds.has(objective.strategicObjectiveId)

        return {
          strategicObjectiveId: objective.strategicObjectiveId,
          code: objective.code,
          name: objective.name,
          performance: objective.performance,
          performanceStatus: objective.performanceStatus,
          score,
          reasons,
          coveredInExercise,
          causalRelationCount: causalRelations.length,
          selected,
        }
      })
      .sort((first, second) => {
        if (first.score !== second.score) return second.score - first.score
        return first.code.localeCompare(second.code, 'pt-BR')
      })

    setRaeAgendaSuggestions(suggestions)
    setRaeAgendaLoading(false)
  }

  function toggleRaeAgendaSuggestion(objectiveId: string) {
    setRaeAgendaSuggestions((items) =>
      items.map((item) =>
        item.strategicObjectiveId === objectiveId
          ? { ...item, selected: !item.selected }
          : item,
      ),
    )
  }

  async function materializeRaeAgendaSuggestions() {
    if (!selectedRae) return

    const reason = raeChangeReason.trim()
    if (!reason) {
      setRaeActionError(
        'Informe o motivo da alteração para registrar a pauta com rastreabilidade.',
      )
      return
    }

    const selected = raeAgendaSuggestions.filter((item) => item.selected)
    if (selected.length === 0) {
      setRaeActionError('Selecione ao menos um item para compor a pauta.')
      return
    }

    setRaeAgendaMaterializing(true)
    setRaeActionError(null)
    setRaeActionSuccess(null)

    for (let index = 0; index < selected.length; index += 1) {
      const item = selected[index]
      const result = await supabase.rpc('upsert_skpe_strategy_review_item', {
        p_strategy_review_id: selectedRae.strategy_review_id,
        p_item_id: null,
        p_payload: {
          entityType: 'strategic_objective',
          strategicObjectiveId: item.strategicObjectiveId,
          performanceStatus: item.performanceStatus,
          findingType:
            item.performanceStatus === 'critical' ||
            item.performanceStatus === 'attention'
              ? 'deviation'
              : 'information',
          analysisText: `Item sugerido para análise estratégica: ${item.reasons.join(
            '; ',
          )}.`,
          rootCause: null,
          recommendation: null,
          requiresDecision:
            item.performanceStatus === 'critical' ||
            item.performanceStatus === 'attention',
          displayOrder: index + 1,
          status: 'open',
          metadata: {
            source: 'sparks_rae_agenda_suggestion',
            suggestionScore: item.score,
            suggestionReasons: item.reasons,
            coveredInExerciseBeforeSuggestion: item.coveredInExercise,
            causalRelationCount: item.causalRelationCount,
          },
        },
        p_change_reason: reason,
      })

      if (result.error) {
        setRaeActionError(
          `Não foi possível registrar ${item.code}: ${translateBackendMessage(
            result.error.message,
          )}`,
        )
        setRaeAgendaMaterializing(false)
        return
      }
    }

    setRaeActionSuccess(
      `${selected.length} item(ns) da pauta registrados como rascunho de análise da RAE.`,
    )
    setReloadToken((value) => value + 1)
    setRaeAgendaMaterializing(false)
  }
  function beginManageRae(item: MyMeeting) {
    setSelectedRae(item)
    void loadRaeReviewItems(item.strategy_review_id)
    void loadRaeDecisions(item.strategy_review_id)
    setRaeExecutiveSummary(item.executive_summary ?? '')
    setRaeConclusions(item.conclusions ?? '')
    setRaeMinutesReference(item.minutes_reference ?? '')
    setRaeChangeReason('')
    setRaeActionError(null)
    setRaeActionSuccess(null)
  }

  function closeManageRae() {
    if (raeSaving) return
    setSelectedRae(null)
    setRaeActionError(null)
    setRaeActionSuccess(null)
  }

  async function saveRae() {
    if (!selectedRae) return

    const reason = raeChangeReason.trim()
    if (!reason) {
      setRaeActionError('Informe o motivo da alteração para preservar a rastreabilidade.')
      return
    }

    setRaeSaving(true)
    setRaeActionError(null)
    setRaeActionSuccess(null)

    const { error } = await supabase.rpc('upsert_skpe_strategy_review', {
      p_cycle_id: selectedRae.monitoring_cycle_id,
      p_review_id: selectedRae.strategy_review_id,
      p_payload: {
        code: selectedRae.code,
        title: selectedRae.title,
        reviewType: selectedRae.review_type,
        status: selectedRae.status,
        scheduledAt: selectedRae.scheduled_at,
        heldAt: selectedRae.held_at,
        chairUserId: selectedRae.chair_user_id,
        secretaryUserId: selectedRae.secretary_user_id,
        participants: selectedRae.participants ?? [],
        executiveSummary: raeExecutiveSummary.trim() || null,
        conclusions: raeConclusions.trim() || null,
        minutesReference: raeMinutesReference.trim() || null,
        metadata: {},
      },
      p_change_reason: reason,
    })

    if (error) {
      setRaeActionError(translateBackendMessage(error.message))
      setRaeSaving(false)
      return
    }

    setRaeActionSuccess('RAE atualizada com rastreabilidade.')
    setReloadToken((value) => value + 1)
    setRaeSaving(false)
  }

  async function ratifyRae() {
    if (!selectedRae) return

    const reason = raeChangeReason.trim()
    if (!reason) {
      setRaeActionError('Informe o motivo da ratificação para preservar a rastreabilidade.')
      return
    }

    if (!selectedRae.held_at) {
      setRaeActionError('A RAE precisa ter data de realização registrada antes da ratificação.')
      return
    }

    if (!raeExecutiveSummary.trim() || !raeConclusions.trim()) {
      setRaeActionError('Síntese executiva e conclusões são obrigatórias antes da ratificação.')
      return
    }

    setRaeSaving(true)
    setRaeActionError(null)
    setRaeActionSuccess(null)

    const saveResult = await supabase.rpc('upsert_skpe_strategy_review', {
      p_cycle_id: selectedRae.monitoring_cycle_id,
      p_review_id: selectedRae.strategy_review_id,
      p_payload: {
        code: selectedRae.code,
        title: selectedRae.title,
        reviewType: selectedRae.review_type,
        status: selectedRae.status,
        scheduledAt: selectedRae.scheduled_at,
        heldAt: selectedRae.held_at,
        chairUserId: selectedRae.chair_user_id,
        secretaryUserId: selectedRae.secretary_user_id,
        participants: selectedRae.participants ?? [],
        executiveSummary: raeExecutiveSummary.trim(),
        conclusions: raeConclusions.trim(),
        minutesReference: raeMinutesReference.trim() || null,
        metadata: {},
      },
      p_change_reason: reason,
    })

    if (saveResult.error) {
      setRaeActionError(translateBackendMessage(saveResult.error.message))
      setRaeSaving(false)
      return
    }

    const { error } = await supabase.rpc('ratify_skpe_strategy_review', {
      p_strategy_review_id: selectedRae.strategy_review_id,
      p_change_reason: reason,
    })

    if (error) {
      setRaeActionError(translateBackendMessage(error.message))
      setRaeSaving(false)
      return
    }

    setRaeActionSuccess('RAE ratificada. O registro estratégico tornou-se governado.')
    setReloadToken((value) => value + 1)
    setRaeSaving(false)
  }
  function openMeeting(item: MyMeeting) {
    window.location.assign(
      platformRoutes.skpe({
        organizationId: item.organization_id,
        projectId: item.project_id,
        formulationId: item.formulation_id,
        section: 'governance',
      }),
    )
  }

  return (
    <section
      className="skpe-meetings-panel"
      aria-labelledby="my-meetings-title"
    >
      <div className="skpe-meetings-heading">
        <div>
          <p className="skpe-card-code">Agenda de governança</p>
          <h2 id="my-meetings-title">Reuniões</h2>
          <p>
            Acompanhe reuniões estratégicas nas quais você exerce papel
            comprovado de presidência ou secretaria, incluindo agenda, ciclo,
            itens de análise, decisões e ratificação.
          </p>
        </div>

        {!loading && !errorMessage && (
          <span className="skpe-meetings-total">
            {items.length} {items.length === 1 ? 'reunião' : 'reuniões'}
          </span>
        )}
      </div>

      <div
        className="skpe-meetings-filters"
        aria-label="Filtros de reuniões"
      >
        {(
          [
            ['all', 'Todas'],
            ['attention', 'Atenção'],
            ['upcoming', 'Próximas'],
            ['today', 'Hoje'],
            ['in_progress', 'Em andamento'],
            ['completed', 'Realizadas'],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            className={
              filter === value
                ? 'skpe-meetings-filter skpe-meetings-filter-active'
                : 'skpe-meetings-filter'
            }
            aria-pressed={filter === value}
            onClick={() => setFilter(value)}
          >
            {label}
            <span>{counts[value]}</span>
          </button>
        ))}
      </div>

      {loading ? (
        <div className="skpe-meetings-state" role="status">
          Carregando suas reuniões...
        </div>
      ) : errorMessage ? (
        <div
          className="skpe-meetings-state skpe-meetings-error"
          role="alert"
        >
          {errorMessage}
        </div>
      ) : visibleItems.length === 0 ? (
        <div className="skpe-meetings-state">
          <strong>Nenhuma reunião encontrada.</strong>
          <span>
            Não existem reuniões em que você exerça presidência ou secretaria
            correspondentes ao filtro selecionado.
          </span>
        </div>
      ) : (
        <div className="skpe-meetings-list">
          {visibleItems.map((item) => (
            <article
              key={item.strategy_review_id}
              className={
                isAttentionMeeting(item)
                  ? 'skpe-meetings-item skpe-meetings-item-attention'
                  : 'skpe-meetings-item'
              }
              role="button"
              tabIndex={0}
              aria-label={`Abrir reunião ${item.code} ${item.title}`}
              onClick={() => openMeeting(item)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault()
                  openMeeting(item)
                }
              }}
            >
              <div className="skpe-meetings-item-main">
                <div className="skpe-meetings-item-labels">
                  <span>{item.code}</span>
                  <span>{reviewTypeLabels[item.review_type]}</span>
                  <span>{meetingRoleLabels[item.current_user_role]}</span>
                  <span>
                    Formulação v{item.formulation_version_number}
                    {item.formulation_version_label
                      ? ` · ${item.formulation_version_label}`
                      : ''}
                  </span>
                </div>

                <div className="skpe-meetings-title-row">
                  <h3>{item.title}</h3>
                  {item.review_type === 'rae' &&
                    !['ratified', 'closed', 'cancelled'].includes(item.status) && (
                      <button
                        type="button"
                        className="skpe-meetings-manage-rae"
                        onClick={(event) => {
                          event.stopPropagation()
                          beginManageRae(item)
                        }}
                      >
                        Gerenciar RAE
                      </button>
                    )}
                </div>

                {item.executive_summary && (
                  <p>{item.executive_summary}</p>
                )}

                <div className="skpe-meetings-governance-grid">
                  <div>
                    <span>Agenda</span>
                    <strong
                      className={
                        item.is_overdue
                          ? 'skpe-meetings-value-alert'
                          : undefined
                      }
                    >
                      {formatMeetingSummary(item)}
                    </strong>
                    <small>
                      {item.scheduled_at
                        ? formatDateTime(item.scheduled_at)
                        : 'Data e horário não informados'}
                    </small>
                  </div>

                  <div>
                    <span>Ciclo de monitoramento</span>
                    <strong>
                      {item.cycle_code} · {item.cycle_name}
                    </strong>
                    <small>
                      {cycleTypeLabels[item.cycle_type]} ·{' '}
                      {cycleStatusLabels[item.cycle_status]}
                    </small>
                  </div>
                </div>

                <div className="skpe-meetings-kpis">
                  <div>
                    <span>Itens da pauta</span>
                    <strong>{item.review_item_count}</strong>
                    <small>
                      {item.open_review_item_count}{' '}
                      {item.open_review_item_count === 1
                        ? 'item aberto'
                        : 'itens abertos'}
                    </small>
                  </div>

                  <div>
                    <span>Decisões</span>
                    <strong>{item.decision_count}</strong>
                    <small>
                      {item.open_decision_count}{' '}
                      {item.open_decision_count === 1
                        ? 'decisão aberta'
                        : 'decisões abertas'}
                    </small>
                  </div>

                  <div>
                    <span>Participantes registrados</span>
                    <strong>
                      {item.participant_count ?? 'Não estruturado'}
                    </strong>
                    <small>
                      Informação exibida sem inferir participação pessoal
                    </small>
                  </div>

                  <div>
                    <span>Período do ciclo</span>
                    <strong>
                      {formatDate(item.cycle_period_start)} a{' '}
                      {formatDate(item.cycle_period_end)}
                    </strong>
                    <small>{cycleTypeLabels[item.cycle_type]}</small>
                  </div>
                </div>

                {item.conclusions && (
                  <div className="skpe-meetings-context">
                    <span>Conclusões registradas</span>
                    <strong>{item.conclusions}</strong>
                  </div>
                )}

                {item.minutes_reference && (
                  <div className="skpe-meetings-context">
                    <span>Referência de ata</span>
                    <strong>{item.minutes_reference}</strong>
                  </div>
                )}

                <div className="skpe-meetings-item-meta">
                  <span>{meetingRoleLabels[item.current_user_role]}</span>
                  <span>
                    Reunião: {reviewStatusLabels[item.status]}
                  </span>
                  <span>
                    Ciclo: {cycleStatusLabels[item.cycle_status]}
                  </span>

                  {item.is_ratified && <span>Ratificada</span>}

                  {item.held_at && (
                    <span>
                      Realizada em {formatDateTime(item.held_at)}
                    </span>
                  )}
                </div>
              </div>

              <div className="skpe-meetings-item-actions">
                <div className="skpe-meetings-status-stack">
                  <span
                    className={`skpe-meetings-status skpe-meetings-status-${item.status}`}
                  >
                    {reviewStatusLabels[item.status]}
                  </span>

                  {item.is_today &&
                    item.status !== 'closed' &&
                    item.status !== 'cancelled' && (
                      <span className="skpe-meetings-today-badge">
                        Hoje
                      </span>
                    )}

                  {isAttentionMeeting(item) && (
                    <span className="skpe-meetings-attention-badge">
                      Atenção
                    </span>
                  )}

                  {item.is_ratified && (
                    <span className="skpe-meetings-ratified-badge">
                      Ratificada
                    </span>
                  )}
                </div>

                <button
                  type="button"
                  className="skpe-card-link-button"
                  onClick={(event) => {
                    event.stopPropagation()
                    openMeeting(item)
                  }}
                >
                  Abrir governança
                </button>
              </div>
            </article>
          ))}
        </div>
      )}
      {selectedRae && (
        <div
          className="skpe-rae-editor-backdrop"
          role="presentation"
          onMouseDown={(event) => {
            if (event.currentTarget === event.target) closeManageRae()
          }}
        >
          <section
            className="skpe-rae-editor"
            role="dialog"
            aria-modal="true"
            aria-labelledby="skpe-rae-editor-title"
          >
            <div className="skpe-rae-editor-heading">
              <div>
                <span>Gestão Estratégica · RAE</span>
                <h3 id="skpe-rae-editor-title">
                  {selectedRae.code} · {selectedRae.title}
                </h3>
                <p>
                  Registre a síntese e as conclusões da análise estratégica.
                  A execução operacional das iniciativas permanece fora deste
                  espaço de governança.
                </p>
              </div>
              <button type="button" onClick={closeManageRae} disabled={raeSaving}>
                Fechar
              </button>
            </div>

            <section className="skpe-rae-agenda-suggestion">
              <div className="skpe-rae-agenda-heading">
                <div>
                  <span>Pauta orientada pelo BSC</span>
                  <strong>Sugestão SPARKs para esta RAE</strong>
                  <p>
                    Prioriza OEs com pior desempenho, relações causais do Mapa
                    Estratégico e lacunas de cobertura no exercício. A pauta
                    permanece ajustável pela Organização.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={suggestRaeAgenda}
                  disabled={raeAgendaLoading || raeSaving}
                >
                  {raeAgendaLoading ? 'Analisando...' : 'Sugerir pauta'}
                </button>
              </div>

              {raeAgendaSuggestions.length > 0 && (
                <>
                  <div className="skpe-rae-agenda-list">
                    {raeAgendaSuggestions.map((item) => (
                      <label
                        key={item.strategicObjectiveId}
                        className={
                          item.selected
                            ? 'skpe-rae-agenda-item skpe-rae-agenda-item-selected'
                            : 'skpe-rae-agenda-item'
                        }
                      >
                        <input
                          type="checkbox"
                          checked={item.selected}
                          onChange={() =>
                            toggleRaeAgendaSuggestion(item.strategicObjectiveId)
                          }
                          disabled={raeAgendaMaterializing}
                        />
                        <div>
                          <div className="skpe-rae-agenda-item-title">
                            <strong>
                              {item.code} · {item.name}
                            </strong>
                            <span>{item.performanceStatus}</span>
                          </div>
                          <p>{item.reasons.join(' · ')}</p>
                          <small>
                            {item.performance === null
                              ? 'Desempenho não apurado'
                              : `Desempenho: ${item.performance.toFixed(1)}%`}
                            {' · '}
                            {item.coveredInExercise
                              ? 'Já analisado no exercício'
                              : 'Ainda não analisado no exercício'}
                          </small>
                        </div>
                      </label>
                    ))}
                  </div>

                  <div className="skpe-rae-agenda-actions">
                    <small>
                      A seleção automática contempla criticidade e caminho causal.
                      O controle de cobertura anual será refinado quando a cadência
                      de governança da Organização estiver parametrizada.
                    </small>
                    <button
                      type="button"
                      onClick={materializeRaeAgendaSuggestions}
                      disabled={raeAgendaMaterializing || raeSaving}
                    >
                      {raeAgendaMaterializing
                        ? 'Registrando...'
                        : 'Registrar itens selecionados na pauta'}
                    </button>
                  </div>
                </>
              )}
            </section>
            <section className="skpe-rae-decisions">
              <div className="skpe-rae-decisions-heading">
                <div>
                  <span>Deliberações</span>
                  <strong>Decisões da RAE</strong>
                  <p>
                    Registre decisões decorrentes da análise estratégica. Neste
                    incremento, a decisão é governada no SK-PE; o desdobramento
                    operacional permanece separado e será conectado à Gestão
                    Operacional em etapa própria.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => void loadRaeDecisions(selectedRae.strategy_review_id)}
                  disabled={raeDecisionLoading || raeSaving}
                >
                  {raeDecisionLoading ? 'Atualizando...' : 'Atualizar decisões'}
                </button>
              </div>

              {raeDecisions.length > 0 && (
                <div className="skpe-rae-decisions-list">
                  {raeDecisions.map((decision) => (
                    <article key={decision.id} className="skpe-rae-decision-item">
                      <div className="skpe-rae-decision-meta">
                        <span>{decision.code}</span>
                        <span>{decision.decision_type}</span>
                        <span>{decision.priority}</span>
                        <span>{decision.status}</span>
                      </div>
                      <strong>{decision.title}</strong>
                      <p>{decision.decision_text}</p>
                      {decision.rationale && <small>{decision.rationale}</small>}

                      <label className="skpe-rae-decision-notes">
                        <span>Nota de conclusão / cancelamento</span>
                        <textarea
                          rows={2}
                          value={raeDecisionCompletionNotes[decision.id] ?? ''}
                          onChange={(event) =>
                            setRaeDecisionCompletionNotes((current) => ({
                              ...current,
                              [decision.id]: event.target.value,
                            }))
                          }
                          disabled={raeDecisionTransitionId === decision.id}
                        />
                      </label>

                      <div className="skpe-rae-decision-transition-actions">
                        {decision.status === 'open' && (
                          <button
                            type="button"
                            onClick={() => void transitionRaeDecision(decision, 'start')}
                            disabled={raeDecisionTransitionId === decision.id}
                          >
                            Iniciar
                          </button>
                        )}

                        {['open', 'in_progress', 'overdue'].includes(decision.status) && (
                          <button
                            type="button"
                            onClick={() => void transitionRaeDecision(decision, 'block')}
                            disabled={raeDecisionTransitionId === decision.id}
                          >
                            Bloquear
                          </button>
                        )}

                        {['open', 'in_progress', 'blocked', 'overdue'].includes(
                          decision.status,
                        ) && (
                          <button
                            type="button"
                            onClick={() => void transitionRaeDecision(decision, 'complete')}
                            disabled={raeDecisionTransitionId === decision.id}
                          >
                            Concluir
                          </button>
                        )}

                        {['open', 'in_progress', 'blocked', 'overdue'].includes(
                          decision.status,
                        ) && (
                          <button
                            type="button"
                            onClick={() => void transitionRaeDecision(decision, 'cancel')}
                            disabled={raeDecisionTransitionId === decision.id}
                          >
                            Cancelar
                          </button>
                        )}

                        {['completed', 'cancelled', 'blocked'].includes(decision.status) && (
                          <button
                            type="button"
                            onClick={() => void transitionRaeDecision(decision, 'reopen')}
                            disabled={raeDecisionTransitionId === decision.id}
                          >
                            Reabrir
                          </button>
                        )}

                        {!decision.ratified_at &&
                          ['ratified', 'closed'].includes(selectedRae.status) && (
                            <button
                              type="button"
                              className="skpe-rae-editor-primary"
                              onClick={() => void transitionRaeDecision(decision, 'ratify')}
                              disabled={raeDecisionTransitionId === decision.id}
                            >
                              Ratificar decisão
                            </button>
                          )}
                      </div>
                    </article>
                  ))}
                </div>
              )}

              <div className="skpe-rae-decision-form">
                <label>
                  <span>Item da pauta de origem</span>
                  <select
                    value={raeDecisionDraft.strategyReviewItemId}
                    onChange={(event) =>
                      setRaeDecisionDraft((current) => ({
                        ...current,
                        strategyReviewItemId: event.target.value,
                      }))
                    }
                    disabled={raeDecisionSaving}
                  >
                    <option value="">Sem item específico</option>
                    {raeReviewItems.map((item) => (
                      <option key={item.id} value={item.id}>
                        Item {item.display_order} · {item.performance_status}
                      </option>
                    ))}
                  </select>
                </label>

                <div className="skpe-rae-decision-grid">
                  <label>
                    <span>Código</span>
                    <input
                      type="text"
                      value={raeDecisionDraft.code}
                      onChange={(event) =>
                        setRaeDecisionDraft((current) => ({
                          ...current,
                          code: event.target.value,
                        }))
                      }
                      disabled={raeDecisionSaving}
                      placeholder="DEC-01"
                    />
                  </label>

                  <label>
                    <span>Prioridade</span>
                    <select
                      value={raeDecisionDraft.priority}
                      onChange={(event) =>
                        setRaeDecisionDraft((current) => ({
                          ...current,
                          priority: event.target.value,
                        }))
                      }
                      disabled={raeDecisionSaving}
                    >
                      <option value="low">Baixa</option>
                      <option value="medium">Média</option>
                      <option value="high">Alta</option>
                      <option value="critical">Crítica</option>
                    </select>
                  </label>
                </div>

                <label>
                  <span>Título</span>
                  <input
                    type="text"
                    value={raeDecisionDraft.title}
                    onChange={(event) =>
                      setRaeDecisionDraft((current) => ({
                        ...current,
                        title: event.target.value,
                      }))
                    }
                    disabled={raeDecisionSaving}
                  />
                </label>

                <label>
                  <span>Decisão</span>
                  <textarea
                    rows={4}
                    value={raeDecisionDraft.decisionText}
                    onChange={(event) =>
                      setRaeDecisionDraft((current) => ({
                        ...current,
                        decisionText: event.target.value,
                      }))
                    }
                    disabled={raeDecisionSaving}
                  />
                </label>

                <label>
                  <span>Fundamentação</span>
                  <textarea
                    rows={3}
                    value={raeDecisionDraft.rationale}
                    onChange={(event) =>
                      setRaeDecisionDraft((current) => ({
                        ...current,
                        rationale: event.target.value,
                      }))
                    }
                    disabled={raeDecisionSaving}
                  />
                </label>

                <div className="skpe-rae-decision-grid">
                  <label>
                    <span>Tipo de decisão</span>
                    <select
                      value={raeDecisionDraft.decisionType}
                      onChange={(event) =>
                        setRaeDecisionDraft((current) => ({
                          ...current,
                          decisionType: event.target.value,
                        }))
                      }
                      disabled={raeDecisionSaving}
                    >
                      <option value="corrective_action">Ação corretiva</option>
                      <option value="preventive_action">Ação preventiva</option>
                      <option value="resource_allocation">Alocação de recurso</option>
                      <option value="reprioritization">Repriorização</option>
                      <option value="escalation">Escalonamento</option>
                      <option value="strategy_review">Revisão da estratégia</option>
                      <option value="communication">Comunicação</option>
                      <option value="other">Outra</option>
                    </select>
                  </label>

                  <label>
                    <span>Prazo</span>
                    <input
                      type="date"
                      value={raeDecisionDraft.dueDate}
                      onChange={(event) =>
                        setRaeDecisionDraft((current) => ({
                          ...current,
                          dueDate: event.target.value,
                        }))
                      }
                      disabled={raeDecisionSaving}
                    />
                  </label>
                </div>

                <label>
                  <span>Nível de escalonamento</span>
                  <select
                    value={raeDecisionDraft.escalationLevel}
                    onChange={(event) =>
                      setRaeDecisionDraft((current) => ({
                        ...current,
                        escalationLevel: event.target.value,
                      }))
                    }
                    disabled={raeDecisionSaving}
                  >
                    <option value="none">Sem escalonamento</option>
                    <option value="management">Gestão</option>
                    <option value="board">Conselho</option>
                    <option value="assembly">Assembleia</option>
                  </select>
                </label>

                <div className="skpe-rae-decision-actions">
                  <small>
                    Responsável e destino operacional serão tratados no próximo
                    refinamento, após reconciliar o vínculo canônico com Gestão
                    Operacional.
                  </small>
                  <button
                    type="button"
                    onClick={() => void createRaeDecision()}
                    disabled={raeDecisionSaving}
                  >
                    {raeDecisionSaving ? 'Registrando...' : 'Registrar deliberação'}
                  </button>
                </div>
              </div>
            </section>
            <section className="skpe-rae-analysis">
              <div className="skpe-rae-analysis-heading">
                <div>
                  <span>Análise da pauta</span>
                  <strong>Itens da RAE</strong>
                  <p>
                    Registre a análise estratégica, causa, recomendação e se o item
                    exige deliberação. O item permanece vinculado ao objeto estratégico
                    que originou sua inclusão na pauta.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => void loadRaeReviewItems(selectedRae.strategy_review_id)}
                  disabled={raeReviewLoading || raeSaving}
                >
                  {raeReviewLoading ? 'Atualizando...' : 'Atualizar itens'}
                </button>
              </div>

              {raeReviewLoading ? (
                <div className="skpe-rae-analysis-state">Carregando itens da RAE...</div>
              ) : raeReviewItems.length === 0 ? (
                <div className="skpe-rae-analysis-state">
                  Nenhum item registrado. Use a sugestão de pauta para materializar
                  os primeiros itens.
                </div>
              ) : (
                <div className="skpe-rae-analysis-list">
                  {raeReviewItems.map((item) => {
                    const draft = raeReviewDrafts[item.id]
                    if (!draft) return null

                    return (
                      <article key={item.id} className="skpe-rae-analysis-item">
                        <div className="skpe-rae-analysis-item-meta">
                          <span>{item.performance_status}</span>
                          <span>{item.finding_type}</span>
                          <span>{draft.status}</span>
                        </div>

                        <label>
                          <span>Análise estratégica</span>
                          <textarea
                            rows={4}
                            value={draft.analysisText}
                            onChange={(event) =>
                              updateRaeReviewDraft(item.id, {
                                analysisText: event.target.value,
                              })
                            }
                            disabled={raeReviewSavingId === item.id}
                          />
                        </label>

                        <label>
                          <span>Causa identificada</span>
                          <textarea
                            rows={3}
                            value={draft.rootCause}
                            onChange={(event) =>
                              updateRaeReviewDraft(item.id, {
                                rootCause: event.target.value,
                              })
                            }
                            disabled={raeReviewSavingId === item.id}
                          />
                        </label>

                        <label>
                          <span>Recomendação</span>
                          <textarea
                            rows={3}
                            value={draft.recommendation}
                            onChange={(event) =>
                              updateRaeReviewDraft(item.id, {
                                recommendation: event.target.value,
                              })
                            }
                            disabled={raeReviewSavingId === item.id}
                          />
                        </label>

                        <div className="skpe-rae-analysis-footer">
                          <label className="skpe-rae-analysis-decision">
                            <input
                              type="checkbox"
                              checked={draft.requiresDecision}
                              onChange={(event) =>
                                updateRaeReviewDraft(item.id, {
                                  requiresDecision: event.target.checked,
                                })
                              }
                              disabled={raeReviewSavingId === item.id}
                            />
                            <span>Exige deliberação da RAE</span>
                          </label>

                          <select
                            value={draft.status}
                            onChange={(event) =>
                              updateRaeReviewDraft(item.id, {
                                status: event.target.value,
                              })
                            }
                            disabled={raeReviewSavingId === item.id}
                          >
                            <option value="open">Aberto</option>
                            <option value="analyzed">Analisado</option>
                            <option value="decided">Deliberado</option>
                            <option value="closed">Encerrado</option>
                          </select>

                          <button
                            type="button"
                            onClick={() => void saveRaeReviewItem(item)}
                            disabled={raeReviewSavingId === item.id}
                          >
                            {raeReviewSavingId === item.id
                              ? 'Salvando...'
                              : 'Salvar análise'}
                          </button>
                        </div>
                      </article>
                    )
                  })}
                </div>
              )}
            </section>
            <div className="skpe-rae-editor-context">
              <div>
                <span>Ciclo</span>
                <strong>
                  {selectedRae.cycle_code} · {selectedRae.cycle_name}
                </strong>
              </div>
              <div>
                <span>Situação</span>
                <strong>{reviewStatusLabels[selectedRae.status]}</strong>
              </div>
              <div>
                <span>Realização</span>
                <strong>{formatDateTime(selectedRae.held_at)}</strong>
              </div>
            </div>

            <label>
              <span>Síntese executiva</span>
              <textarea
                value={raeExecutiveSummary}
                onChange={(event) => setRaeExecutiveSummary(event.target.value)}
                rows={5}
                disabled={raeSaving}
              />
            </label>

            <label>
              <span>Conclusões</span>
              <textarea
                value={raeConclusions}
                onChange={(event) => setRaeConclusions(event.target.value)}
                rows={5}
                disabled={raeSaving}
              />
            </label>

            <label>
              <span>Referência de ata</span>
              <input
                type="text"
                value={raeMinutesReference}
                onChange={(event) => setRaeMinutesReference(event.target.value)}
                disabled={raeSaving}
              />
            </label>

            <label>
              <span>Motivo da alteração / ratificação</span>
              <textarea
                value={raeChangeReason}
                onChange={(event) => setRaeChangeReason(event.target.value)}
                rows={3}
                disabled={raeSaving}
                placeholder="Registre o fundamento da alteração ou da ratificação."
              />
            </label>

            {raeActionError && (
              <div className="skpe-rae-editor-message skpe-rae-editor-error" role="alert">
                {raeActionError}
              </div>
            )}

            {raeActionSuccess && (
              <div className="skpe-rae-editor-message" role="status">
                {raeActionSuccess}
              </div>
            )}

            <div className="skpe-rae-editor-actions">
              <button type="button" onClick={saveRae} disabled={raeSaving}>
                {raeSaving ? 'Salvando...' : 'Salvar RAE'}
              </button>
              {(selectedRae.status === 'in_progress' ||
                selectedRae.status === 'pending_ratification') && (
                <button
                  type="button"
                  className="skpe-rae-editor-primary"
                  onClick={ratifyRae}
                  disabled={raeSaving}
                >
                  Ratificar RAE
                </button>
              )}
            </div>
          </section>
        </div>
      )}
    </section>
  )
}
