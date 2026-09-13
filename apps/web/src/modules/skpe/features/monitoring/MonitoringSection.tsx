import { useEffect, useMemo, useState, type ComponentType } from 'react'

import { supabase } from '../../../../lib/supabase'
import { useSkpeWorkspace } from '../../context/SkpeWorkspaceContext'
import {
  InitiativeEconomicExecutionDialog,
  type InitiativeEconomicDirect,
} from './InitiativeEconomicExecutionDialog'
import { PersonCapacityManagementDialog } from './PersonCapacityManagementDialog'
import { ManagementTimeline } from './ManagementTimeline'
import { ManagementExecutionMatrix } from './ManagementExecutionMatrix'
import { MonitoringPackageConfigurationPanel } from './MonitoringPackageConfigurationPanel'
import { MonitoringPackageWorkflowPanel } from './MonitoringPackageWorkflowPanel'
import type {
  ActionBoardExecutionRow,
  CapacityAllocationExecutionRow,
  PersonCapacityExecutionRow,
} from './monitoringExecutionMatrix'
import type {
  InitiativeTemporalTimelineRow,
  JourneyEventTimelineRow,
  JourneyTemporalTimelineRow,
} from './monitoringTimeline'
import {
  createInitialMonitoringPackageDraft,
  monitoringPackageDraftIsMaterializable,
  monitoringPackageInitialProposal,
  monitoringPackageProposalDisplayValue,
  type MonitoringPackageDraft,
} from './monitoringPackageProposal'

import './MonitoringSection.css'

type MonitoringDrilldownTarget = {
  initiativeId: string
  actionId: string | null
}

type MonitoringSectionProps = {
  fallbackProjectId: string | null
  canManageEconomic: boolean
  canViewJourney: boolean
  canViewInitiatives: boolean
  JourneyIcon: ComponentType
  InitiativesIcon: ComponentType
  onOpenJourney: () => void
  onOpenInitiatives: (target?: MonitoringDrilldownTarget) => void
  refreshRequestKey?: number
}



function EconomicExecutionIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle
        cx="12"
        cy="12"
        r="8"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />
      <path
        d="M9 9.4c0-1 1.1-1.8 2.6-1.8h.8c1.5 0 2.6.8 2.6 1.8s-1 1.7-2.6 1.9h-.8C10 11.5 9 12.3 9 13.5s1.1 1.8 2.6 1.8h.8c1.5 0 2.6-.8 2.6-1.8M12 6.3v11.4"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  )
}

function CapacityManagementIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="8" cy="8" r="2.4" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <circle cx="16" cy="8" r="2.4" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <path d="M3.8 17c.5-2.8 2-4.2 4.2-4.2s3.7 1.4 4.2 4.2M11.8 17c.5-2.8 2-4.2 4.2-4.2s3.7 1.4 4.2 4.2" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  )
}
type OperationalProjection = {
  referenceDate?: string
  journeyTemporal?: JourneyTemporalTimelineRow[]
  journeyEvents?: JourneyEventTimelineRow[]
  initiativeTemporal?: InitiativeTemporalTimelineRow[]
  actionBoard?: ActionBoardExecutionRow[]
  economic?: {
    initiative?: {
      initiativeId: string
      organizationId: string
      code: string
      name: string
      lifecycleStatus: string
      direct: InitiativeEconomicDirect
    }
    actions?: {
      costByCurrency?: Array<{
        currencyCode: string
        currentPlannedCost: number
        actualRealizedCost: number
        currentPlanVariance: number
      }>
      effortByUnit?: Array<{
        effortUnit: string
        currentEstimatedEffort: number
        actualRealizedEffort: number
        currentPlanVariance: number
      }>
      dataQuality?: {
        actionsWithCostWithoutCurrency: number
        actionsWithEffortWithoutUnit: number
      }
    }
  }
  capacity?: {
    visible?: boolean
    allocations?: CapacityAllocationExecutionRow[]
    involvedPeopleCapacity?: PersonCapacityExecutionRow[]
  }
  governance?: {
    readOnlyProjection?: boolean
    journeyVisible?: boolean
    initiativesVisible?: boolean
    economicVisible?: boolean
    capacityVisible?: boolean
  }
}

type MonitoringPackageReadiness = { packageStatus: string | null; readyForValidation: boolean; readyForFormulation: boolean; blockingIssues?: Array<{ code: string; severity: string; message: string }>; recommendations?: Array<{ code: string; severity: string; message: string }> }
type StrategicPerformance = { aggregationPolicy?: string | null; objectives?: Array<{ strategicObjectiveId: string; code: string; name: string; performance: number | null; performanceStatus: string }>; themes?: Array<{ strategicThemeId: string; code: string; name: string; performance: number | null; performanceStatus: string }>; visionProgress?: number | null; visionProgressStatus?: string | null }
type EligibleMonitoringOwner = { userId: string; personId: string; name: string }
type MonitoringPackageRow = {
  cycle_frequency: string
  review_frequency: string
  cycle_overlap_policy: string
  evidence_required: boolean
  data_quality_required: boolean
  confidence_required_for_key_results: boolean
  allow_manual_progress_override: boolean
  data_freshness_days: number
  late_tolerance_days: number
  aggregation_policy: string
  critical_threshold: number
  attention_threshold: number
  on_track_threshold: number
  owner_user_id: string | null
  governance_owner_user_id: string | null
}

function currencyDisplayLabel(currency: string | null | undefined) {
  const code = currency?.trim().toUpperCase() || 'BRL'
  return code === 'BRL' ? 'R$' : code
}

function operationalStatusLabel(value: string) {
  const labels: Record<string, string> = {
    proposed: 'Proposta',
    under_analysis: 'Em análise',
    approved: 'Aprovada',
    planned: 'Planejada',
    in_progress: 'Em execução',
    on_hold: 'Em espera',
    blocked: 'Bloqueada',
    completed: 'Concluída',
    cancelled: 'Cancelada',
    archived: 'Arquivada',
    draft: 'Rascunho',
    scheduled: 'Programado',
    pending: 'Pendente',
    confirmed: 'Confirmado',
    done: 'Concluído',
  }

  return labels[value] ?? value
}

function countBy<T>(rows: T[], read: (row: T) => string) {
  const counts = new Map<string, number>()
  for (const row of rows) {
    const key = read(row)
    counts.set(key, (counts.get(key) ?? 0) + 1)
  }
  return Array.from(counts.entries()).sort(([first], [second]) =>
    first.localeCompare(second, 'pt-BR'),
  )
}

function describeTemporalDataQuality(state: string) {
  switch (state) {
    case 'actual_start_unknown':
      return 'A execução foi sinalizada, mas a data real de início ainda não foi registrada.'
    case 'actual_end_unknown':
      return 'A conclusão foi sinalizada, mas a data real de término ainda não foi registrada.'
    case 'planned_start_unknown':
    case 'current_plan_start_unknown':
      return 'A data planejada de início ainda não foi definida.'
    case 'planned_end_unknown':
    case 'current_plan_end_unknown':
      return 'A data planejada de conclusão ainda não foi definida.'
    case 'forecast_start_unknown':
      return 'A previsão operacional de início ainda não possui uma data definida.'
    case 'forecast_end_unknown':
      return 'A previsão operacional de conclusão ainda não possui uma data definida.'
    case 'baseline_start_unknown':
      return 'A linha de base ainda não possui data de início definida.'
    case 'baseline_end_unknown':
      return 'A linha de base ainda não possui data de conclusão definida.'
    default:
      return 'Há informações temporais incompletas que precisam ser revisadas.'
  }
}

function getTemporalException(
  row: InitiativeTemporalTimelineRow,
) {
  if (row.is_completion_overdue) {
    return {
      severity: 3,
      days: row.days_completion_overdue,
      label: `Conclusão em atraso há ${row.days_completion_overdue} dia(s).`,
      guidance:
        'Revisar o prazo, registrar a conclusão ou atualizar a previsão operacional de término.',
    }
  }

  if (row.is_start_overdue) {
    return {
      severity: 2,
      days: row.days_start_overdue,
      label: `Início em atraso há ${row.days_start_overdue} dia(s).`,
      guidance:
        'Confirmar o início, reprogramar a data ou atualizar a situação da execução.',
    }
  }

  if (row.temporal_data_quality_state !== 'ok') {
    return {
      severity: 1,
      days: 0,
      label: describeTemporalDataQuality(row.temporal_data_quality_state),
      guidance:
        'Completar ou corrigir as datas de planejamento e execução deste item.',
    }
  }

  return null
}

export function MonitoringSection({
  fallbackProjectId,
  canManageEconomic,
  canViewJourney,
  canViewInitiatives,
  JourneyIcon,
  InitiativesIcon,
  onOpenJourney,
  onOpenInitiatives,
  refreshRequestKey = 0,
}: MonitoringSectionProps) {
  const workspace = useSkpeWorkspace()
  const projectId = workspace.route.projectId ?? fallbackProjectId
  const organizationId = workspace.organization.id
  const formulationId = workspace.route.formulationId
  const cycleId = workspace.route.cycleId

  const [projection, setProjection] = useState<OperationalProjection | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [reloadToken, setReloadToken] = useState(0)
  const [showEconomicEditor, setShowEconomicEditor] = useState(false)
  const [showCapacityManager, setShowCapacityManager] = useState(false)
  const [canManageCapacity, setCanManageCapacity] = useState(false)
  const [capacityPermissionLoading, setCapacityPermissionLoading] = useState(true)
  const [capacityPermissionError, setCapacityPermissionError] = useState('')
  const [strategicReadiness, setStrategicReadiness] = useState<MonitoringPackageReadiness | null>(null)
  const [strategicPerformance, setStrategicPerformance] = useState<StrategicPerformance | null>(null)
  const [strategicLoading, setStrategicLoading] = useState(false)
  const [strategicError, setStrategicError] = useState('')
  const [strategicReloadToken, setStrategicReloadToken] = useState(0)
  const [eligibleMonitoringOwners, setEligibleMonitoringOwners] = useState<EligibleMonitoringOwner[]>([])
  const [monitoringPackageDraft, setMonitoringPackageDraft] = useState<MonitoringPackageDraft>(() => createInitialMonitoringPackageDraft())
  const [monitoringPackageSaving, setMonitoringPackageSaving] = useState(false)
  const [monitoringPackageMessage, setMonitoringPackageMessage] = useState('')
  const [canSubmitMonitoringPackage, setCanSubmitMonitoringPackage] = useState(false)
  const [canValidateMonitoringPackage, setCanValidateMonitoringPackage] = useState(false)
  const [monitoringPackageTransitioning, setMonitoringPackageTransitioning] = useState(false)
  const [monitoringPackageWorkflowMessage, setMonitoringPackageWorkflowMessage] = useState('')

  useEffect(() => {
    let active = true

    setCanManageCapacity(false)
    setCapacityPermissionLoading(true)
    setCapacityPermissionError('')

    async function loadCapacityPermission() {
      try {
        const { data, error } = await supabase.rpc(
          'can_manage_sparks_people',
          {
            target_organization_id: organizationId,
          },
        )

        if (!active) return

        if (error) {
          setCanManageCapacity(false)
          setCapacityPermissionError(
            'Não foi possível verificar a permissão de gestão de capacidade.',
          )
          return
        }

        setCanManageCapacity(data === true)
      } catch {
        if (!active) return
        setCanManageCapacity(false)
        setCapacityPermissionError(
          'Não foi possível verificar a permissão de gestão de capacidade.',
        )
      } finally {
        if (active) {
          setCapacityPermissionLoading(false)
        }
      }
    }

    void loadCapacityPermission()

    return () => {
      active = false
    }
  }, [organizationId])

  useEffect(() => {
    let active = true

    async function loadMonitoringPackagePermissions() {
      if (!formulationId) {
        setCanSubmitMonitoringPackage(false)
        setCanValidateMonitoringPackage(false)
        return
      }

      const [submitPermission, validatePermission] = await Promise.all([
        supabase.rpc('can_manage_skpe_formulation', { target_organization_id: organizationId }),
        supabase.rpc('can_validate_skpe_formulation', { target_organization_id: organizationId }),
      ])
      if (!active) return
      setCanSubmitMonitoringPackage(submitPermission.error ? false : submitPermission.data === true)
      setCanValidateMonitoringPackage(validatePermission.error ? false : validatePermission.data === true)
    }

    void loadMonitoringPackagePermissions()
    return () => { active = false }
  }, [formulationId, organizationId])

  useEffect(() => {
    let active = true

    async function loadMonitoringPackageConfiguration() {
      if (!formulationId) {
        setEligibleMonitoringOwners([])
        setMonitoringPackageDraft(createInitialMonitoringPackageDraft())
        return
      }

      const [peopleResponse, packageResponse] = await Promise.all([
        supabase.rpc('get_skpe_governance_people', {
          target_organization_id: organizationId,
        }),
        supabase
          .from('skpe_monitoring_packages')
          .select('cycle_frequency,review_frequency,cycle_overlap_policy,evidence_required,data_quality_required,confidence_required_for_key_results,allow_manual_progress_override,data_freshness_days,late_tolerance_days,aggregation_policy,critical_threshold,attention_threshold,on_track_threshold,owner_user_id,governance_owner_user_id')
          .eq('formulation_id', formulationId)
          .maybeSingle(),
      ])

      if (!active) return

      const governancePeople = (peopleResponse.data ?? []) as Array<{
        person_id: string
        full_name: string
        preferred_name: string | null
      }>
      const personIds = governancePeople.map((person) => person.person_id)
      let owners: EligibleMonitoringOwner[] = []

      if (!peopleResponse.error && personIds.length > 0) {
        const { data: personProfiles } = await supabase
          .from('sparks_people')
          .select('id,profile_user_id')
          .in('id', personIds)
          .not('profile_user_id', 'is', null)

        const userByPerson = new Map(
          ((personProfiles ?? []) as Array<{ id: string; profile_user_id: string | null }>)
            .filter((person) => person.profile_user_id)
            .map((person) => [person.id, person.profile_user_id as string]),
        )
        owners = governancePeople.flatMap((person) => {
          const userId = userByPerson.get(person.person_id)
          if (!userId) return []
          return [{
            userId,
            personId: person.person_id,
            name: person.preferred_name?.trim() || person.full_name,
          }]
        })
      }

      setEligibleMonitoringOwners(owners)

      if (!packageResponse.error && packageResponse.data) {
        const row = packageResponse.data as MonitoringPackageRow
        setMonitoringPackageDraft((current) => ({
          ...current,
          cycleFrequency: row.cycle_frequency,
          reviewFrequency: row.review_frequency,
          cycleOverlapPolicy: row.cycle_overlap_policy,
          evidenceRequired: row.evidence_required,
          dataQualityRequired: row.data_quality_required,
          confidenceRequiredForKeyResults: row.confidence_required_for_key_results,
          allowManualProgressOverride: row.allow_manual_progress_override,
          dataFreshnessDays: row.data_freshness_days,
          lateToleranceDays: row.late_tolerance_days,
          aggregationPolicy: row.aggregation_policy,
          criticalThreshold: Number(row.critical_threshold),
          attentionThreshold: Number(row.attention_threshold),
          onTrackThreshold: Number(row.on_track_threshold),
          ownerUserId: row.owner_user_id ?? '',
          governanceOwnerUserId: row.governance_owner_user_id ?? '',
        }))
      } else if (!packageResponse.data) {
        setMonitoringPackageDraft(createInitialMonitoringPackageDraft())
      }
    }

    void loadMonitoringPackageConfiguration()
    return () => { active = false }
  }, [formulationId, organizationId, strategicReloadToken])

  useEffect(() => {
    let active = true
    const loadStrategicMonitoring = async () => {
      if (!formulationId) { setStrategicReadiness(null); setStrategicPerformance(null); setStrategicError(''); setStrategicLoading(false); return }
      setStrategicLoading(true); setStrategicError('')
      const readinessResult = await supabase.rpc('get_skpe_monitoring_package_readiness', { p_formulation_id: formulationId, p_include_package_state: true })
      if (!active) return
      if (readinessResult.error) { setStrategicReadiness(null); setStrategicPerformance(null); setStrategicError(readinessResult.error.message); setStrategicLoading(false); return }
      setStrategicReadiness((readinessResult.data ?? null) as MonitoringPackageReadiness | null)
      if (!cycleId) { setStrategicPerformance(null); setStrategicLoading(false); return }
      const performanceResult = await supabase.rpc('get_skpe_strategic_performance', { p_cycle_id: cycleId })
      if (!active) return
      if (performanceResult.error) { setStrategicPerformance(null); setStrategicError(performanceResult.error.message) } else { setStrategicPerformance((performanceResult.data ?? null) as StrategicPerformance | null) }
      setStrategicLoading(false)
    }
    void loadStrategicMonitoring()
    return () => { active = false }
  }, [formulationId, cycleId, strategicReloadToken])

  useEffect(() => {
    let active = true

    const load = async () => {
      if (!projectId) {
        setProjection(null)
        setError('Planejamento Estratégico ainda não iniciado.')
        setLoading(false)
        return
      }

      setLoading(true)
      setError('')

      const { data, error: projectionError } = await supabase.rpc(
        'get_skpe_project_operational_projection',
        {
          target_organization_id: organizationId,
          target_project_id: projectId,
          target_as_of_date: null,
        },
      )

      if (!active) return

      if (projectionError) {
        setProjection(null)
        setError('Não foi possível carregar o monitoramento governado deste projeto.')
      } else {
        setProjection((data ?? {}) as OperationalProjection)
      }

      setLoading(false)
    }

    void load()

    return () => {
      active = false
    }
  }, [organizationId, projectId, reloadToken, refreshRequestKey])

  const initiativeTemporal = projection?.initiativeTemporal ?? []
  const actionBoard = projection?.actionBoard ?? []
  const events = projection?.journeyEvents ?? []
  const capacityRows = projection?.capacity?.involvedPeopleCapacity ?? []

  const temporalExceptions = useMemo(
    () =>
      initiativeTemporal
        .map((row) => ({ row, exception: getTemporalException(row) }))
        .filter(
          (entry): entry is {
            row: InitiativeTemporalTimelineRow
            exception: NonNullable<
              ReturnType<typeof getTemporalException>
            >
          } =>
            entry.exception !== null,
        )
        .sort(
          (first, second) =>
            second.exception.severity - first.exception.severity ||
            second.exception.days - first.exception.days ||
            first.row.code.localeCompare(second.row.code, 'pt-BR'),
        ),
    [initiativeTemporal],
  )

  const overallocated = useMemo(
    () => capacityRows.filter((row) => row.is_overallocated),
    [capacityRows],
  )

  const statusCounts = useMemo(
    () => countBy(actionBoard, (row) => row.status),
    [actionBoard],
  )

  const eventStatusCounts = useMemo(
    () => countBy(events, (row) => row.event_status),
    [events],
  )

  const economicInitiative = projection?.economic?.initiative
  const economicDirect = economicInitiative?.direct
  const economicQuality = projection?.economic?.actions?.dataQuality
  const costCurrencies = projection?.economic?.actions?.costByCurrency ?? []
  const effortUnits = projection?.economic?.actions?.effortByUnit ?? []
  const economicEditable =
    canManageEconomic &&
    economicInitiative !== undefined &&
    !['completed', 'cancelled', 'archived'].includes(
      economicInitiative.lifecycleStatus,
    )
  const allocations = projection?.capacity?.allocations ?? []

  const saveMonitoringPackage = async () => {
    if (!formulationId) return
    if (!monitoringPackageDraftIsMaterializable(monitoringPackageDraft)) {
      setMonitoringPackageMessage('Defina os dois responsáveis, revise os limites e informe uma justificativa com pelo menos 10 caracteres.')
      return
    }

    setMonitoringPackageSaving(true)
    setMonitoringPackageMessage('')
    const { error: saveError } = await supabase.rpc(
      'configure_skpe_monitoring_package',
      {
        p_formulation_id: formulationId,
        p_payload: {
          cycleFrequency: monitoringPackageDraft.cycleFrequency,
          reviewFrequency: monitoringPackageDraft.reviewFrequency,
          cycleOverlapPolicy: monitoringPackageDraft.cycleOverlapPolicy,
          evidenceRequired: monitoringPackageDraft.evidenceRequired,
          dataQualityRequired: monitoringPackageDraft.dataQualityRequired,
          confidenceRequiredForKeyResults: monitoringPackageDraft.confidenceRequiredForKeyResults,
          allowManualProgressOverride: monitoringPackageDraft.allowManualProgressOverride,
          dataFreshnessDays: monitoringPackageDraft.dataFreshnessDays,
          lateToleranceDays: monitoringPackageDraft.lateToleranceDays,
          aggregationPolicy: monitoringPackageDraft.aggregationPolicy,
          criticalThreshold: monitoringPackageDraft.criticalThreshold,
          attentionThreshold: monitoringPackageDraft.attentionThreshold,
          onTrackThreshold: monitoringPackageDraft.onTrackThreshold,
          ownerUserId: monitoringPackageDraft.ownerUserId,
          governanceOwnerUserId: monitoringPackageDraft.governanceOwnerUserId,
        },
        p_change_reason: monitoringPackageDraft.changeReason.trim(),
      },
    )

    setMonitoringPackageSaving(false)
    if (saveError) {
      setMonitoringPackageMessage(saveError.code === '42501'
        ? 'Seu perfil não possui permissão para configurar o pacote FE-08.'
        : saveError.message)
      return
    }

    setMonitoringPackageMessage('Configuração FE-08 salva em elaboração. A submissão e a validação humana continuam pendentes.')
    setMonitoringPackageDraft((current) => ({ ...current, changeReason: '' }))
    setStrategicReloadToken((current) => current + 1)
  }

  const transitionMonitoringPackage = async (
    action: 'submit' | 'validate' | 'return',
    reason: string,
    notes: string,
  ) => {
    if (!formulationId || reason.trim().length < 10) return
    setMonitoringPackageTransitioning(true)
    setMonitoringPackageWorkflowMessage('')

    const { error: transitionError } = await supabase.rpc(
      'transition_skpe_monitoring_package',
      {
        p_formulation_id: formulationId,
        p_action: action,
        p_validation_notes: notes.trim() || null,
        p_change_reason: reason.trim(),
      },
    )

    setMonitoringPackageTransitioning(false)
    if (transitionError) {
      setMonitoringPackageWorkflowMessage(
        transitionError.code === '42501'
          ? 'Seu perfil não possui permissão para esta transição do pacote FE-08.'
          : transitionError.message,
      )
      return
    }

    const labels = {
      submit: 'Pacote FE-08 submetido para validação humana.',
      validate: 'Pacote FE-08 validado humanamente.',
      return: 'Pacote FE-08 devolvido para ajustes.',
    }
    setMonitoringPackageWorkflowMessage(labels[action])
    setStrategicReloadToken((current) => current + 1)
  }

  return (
    <section className="skpe-monitoring" aria-label="Monitoramento gerencial do Planejamento Estratégico">
      <header className="skpe-monitoring-header">
        <div
          className="skpe-monitoring-title-help"
          tabIndex={0}
          aria-label="Execução Estratégica. Visão Gerencial."
          data-help="Leitura integrada da projeção operacional canônica. Jornada, ações, agenda e capacidade permanecem em suas fontes governadas; a execução econômica da iniciativa pode ser registrada aqui por usuários autorizados."
        >
          <h1 className="skpe-monitoring-title">
            <span>Execução Estratégica</span>
            <span>Visão Gerencial</span>
          </h1>
        </div>

        <div
          className="skpe-monitoring-icon-actions"
          aria-label="Ações do monitoramento"
        >
          {canViewJourney ? (
            <button
              type="button"
              className="skpe-monitoring-icon-action"
              onClick={onOpenJourney}
              aria-label="Abrir Jornada Estratégica"
              title="Abrir Jornada Estratégica"
              data-tooltip="Abrir Jornada Estratégica"
            >
              <JourneyIcon />
            </button>
          ) : null}

          {canViewInitiatives ? (
            <button
              type="button"
              className="skpe-monitoring-icon-action"
              onClick={() => onOpenInitiatives()}
              aria-label="Abrir Iniciativas e Kanban"
              title="Abrir Iniciativas e Kanban"
              data-tooltip="Abrir Iniciativas e Kanban"
            >
              <InitiativesIcon />
            </button>
          ) : null}

          {economicEditable ? (
            <button
              type="button"
              className="skpe-monitoring-icon-action"
              onClick={() => setShowEconomicEditor(true)}
              aria-label="Registrar execução econômica"
              title="Registrar execução econômica"
              data-tooltip="Registrar execução econômica"
            >
              <EconomicExecutionIcon />
            </button>
          ) : null}

          {canManageCapacity ? (
            <button
              type="button"
              className="skpe-monitoring-icon-action"
              onClick={() => setShowCapacityManager(true)}
              aria-label="Gerenciar capacidade"
              title="Gerenciar capacidade"
              data-tooltip="Gerenciar capacidade"
            >
              <CapacityManagementIcon />
            </button>
          ) : null}
        </div>
      </header>

      {capacityPermissionLoading && (
        <div className="skpe-monitoring-state">
          Verificando permissão de gestão de capacidade...
        </div>
      )}
      {!capacityPermissionLoading && capacityPermissionError && (
        <div className="skpe-monitoring-state is-error" role="alert">
          {capacityPermissionError}
        </div>
      )}

      {strategicLoading && <div className="skpe-monitoring-state">Verificando prontidão do desempenho estratégico...</div>}
      {!strategicLoading && strategicError && <div className="skpe-monitoring-state is-error" role="alert">{strategicError}</div>}
      {!strategicLoading && strategicReadiness && (
        <article className="skpe-monitoring-panel" aria-label="Desempenho estratégico governado">
          <header><div><span>Desempenho estratégico</span><h2>Painel de resultados</h2></div></header>
          {((strategicReadiness.blockingIssues ?? []).some((item) => item.code === 'FE08_PACKAGE_MISSING') || strategicReadiness.packageStatus === 'in_elaboration') ? (
            <>
              <p className="skpe-monitoring-empty">
                {strategicReadiness.packageStatus === 'in_elaboration'
                  ? 'O pacote FE-08 está em elaboração. Revise a configuração antes da submissão para validação humana.'
                  : 'O desempenho ainda não pode ser consolidado: o pacote FE-08 desta Formulação não foi configurado.'}
              </p>
              <div className="skpe-monitoring-tags">
                {(strategicReadiness.blockingIssues ?? []).map((item) => (
                  <span key={item.code}>{item.message}</span>
                ))}
              </div>
              <section aria-label="Proposta inicial de configuração FE-08">
                <h3>Proposta inicial de configuração</h3>
                <p className="skpe-monitoring-empty">
                  Os valores abaixo são defaults técnicos atuais do runtime, não decisões organizacionais. Devem ser analisados e validados por pessoa autorizada antes de qualquer persistência.
                </p>
                <div className="skpe-monitoring-grid">
                  {monitoringPackageInitialProposal.map((item) => (
                    <article key={item.key}>
                      <span>{item.label}</span>
                      <strong>{monitoringPackageProposalDisplayValue(item)}</strong>
                      <small>{item.rationale}</small>
                    </article>
                  ))}
                </div>
                <p className="skpe-monitoring-empty">
                  Materialização automática permanece bloqueada: os responsáveis são decisão humana explícita.
                </p>
              </section>
              <MonitoringPackageConfigurationPanel
                draft={monitoringPackageDraft}
                owners={eligibleMonitoringOwners}
                saving={monitoringPackageSaving}
                message={monitoringPackageMessage}
                onChange={(patch) => setMonitoringPackageDraft((current) => ({ ...current, ...patch }))}
                onSave={() => { void saveMonitoringPackage() }}
              />
              {strategicReadiness.packageStatus === 'in_elaboration' ? (
                <MonitoringPackageWorkflowPanel
                  status={strategicReadiness.packageStatus}
                  readyForValidation={strategicReadiness.readyForValidation}
                  canSubmit={canSubmitMonitoringPackage}
                  canValidate={canValidateMonitoringPackage}
                  transitioning={monitoringPackageTransitioning}
                  message={monitoringPackageWorkflowMessage}
                  onTransition={(action, reason, notes) => { void transitionMonitoringPackage(action, reason, notes) }}
                />
              ) : null}
            </>
          ) : !cycleId ? (
            <>
              <p className="skpe-monitoring-empty">O pacote de monitoramento existe, mas nenhum ciclo está selecionado neste contexto. O painel não sintetiza desempenho sem um ciclo formal.</p>
              {strategicReadiness.packageStatus === 'pending_validation' ? (
                <MonitoringPackageWorkflowPanel
                  status={strategicReadiness.packageStatus}
                  readyForValidation={strategicReadiness.readyForValidation}
                  canSubmit={canSubmitMonitoringPackage}
                  canValidate={canValidateMonitoringPackage}
                  transitioning={monitoringPackageTransitioning}
                  message={monitoringPackageWorkflowMessage}
                  onTransition={(action, reason, notes) => { void transitionMonitoringPackage(action, reason, notes) }}
                />
              ) : null}
              {strategicReadiness.packageStatus === 'validated' ? (
                <p className="skpe-monitoring-empty">Pacote FE-08 validado. A abertura do ciclo permanece condicionada à Formulação aprovada e à autoridade de monitoramento.</p>
              ) : null}
            </>
          ) : strategicPerformance ? (
            <><div className="skpe-monitoring-grid"><article><span>Progresso da Visão</span><strong>{strategicPerformance.visionProgress == null ? 'Não avaliado' : `${strategicPerformance.visionProgress.toFixed(1)}%`}</strong><small>{strategicPerformance.visionProgressStatus ?? 'sem classificação'}</small></article><article><span>Objetivos avaliados</span><strong>{strategicPerformance.objectives?.length ?? 0}</strong><small>agregados pelo runtime governado</small></article><article><span>Temas avaliados</span><strong>{strategicPerformance.themes?.length ?? 0}</strong><small>agregados pelo runtime governado</small></article></div><p className="skpe-monitoring-empty">Política de agregação: {strategicPerformance.aggregationPolicy ?? 'não informada'}.</p></>
          ) : null}
        </article>
      )}

      {loading && <div className="skpe-monitoring-state">Carregando monitoramento...</div>}
      {!loading && error && <div className="skpe-monitoring-state is-error">{error}</div>}

      {!loading && projection && (
        <>
          <div className="skpe-monitoring-grid">
            <article>
              <span>Jornada temporal</span>
              <strong>
                {canViewJourney
                  ? projection.journeyTemporal?.length ?? 0
                  : '—'}
              </strong>
              <small>
                {canViewJourney
                  ? 'itens na projeção temporal da jornada'
                  : 'domínio não autorizado para este usuário'}
              </small>
            </article>
            <article className={temporalExceptions.length > 0 ? 'is-warning' : ''}>
              <span>Atenções temporais</span>
              <strong>{temporalExceptions.length}</strong>
              <small>itens que requerem revisão gerencial</small>
            </article>
            <article>
              <span>Kanban transversal</span>
              <strong>
                {canViewInitiatives
                  ? actionBoard.length
                  : '—'}
              </strong>
              <small>
                {canViewInitiatives
                  ? 'ações ativas na projeção do board'
                  : 'domínio não autorizado para este usuário'}
              </small>
            </article>
            <article>
              <span>Agenda da Jornada</span>
              <strong>
                {canViewJourney ? events.length : '—'}
              </strong>
              <small>
                {canViewJourney
                  ? 'eventos vinculados à jornada'
                  : 'domínio não autorizado para este usuário'}
              </small>
            </article>
            <article className={overallocated.length > 0 ? 'is-warning' : ''}>
              <span>Capacidade</span>
              <strong>{projection.capacity?.visible === false ? '—' : allocations.length}</strong>
              <small>
                {projection.capacity?.visible === false
                  ? 'capacidade não visível para este usuário'
                  : `${overallocated.length} período(s) sobrealocado(s)`}
              </small>
            </article>
            <article>
              <span>Econômico</span>
              <strong>
                {canViewInitiatives
                  ? costCurrencies.length + effortUnits.length
                  : '—'}
              </strong>
              <small>
                {canViewInitiatives
                  ? `${costCurrencies.length} moeda(s) · ${effortUnits.length} unidade(s) de esforço`
                  : 'domínio não autorizado para este usuário'}
              </small>
            </article>
          </div>

          <div className="skpe-monitoring-columns">
            <article className="skpe-monitoring-panel">
              <header>
                <div>
                  <span>Atenção gerencial</span>
                  <h2>Atenções prioritárias</h2>
                </div>
                <strong>{temporalExceptions.length + overallocated.length}</strong>
              </header>

              {temporalExceptions.length === 0 && overallocated.length === 0 ? (
                <p className="skpe-monitoring-empty">Nenhuma atenção temporal ou de capacidade identificada.</p>
              ) : (
                <div className="skpe-monitoring-exceptions">
                  {temporalExceptions.slice(0, 8).map(({ row, exception }) => (
                    <button
                      key={row.entity_id}
                      type="button"
                      className="skpe-monitoring-exception-link"
                      onClick={() =>
                        onOpenInitiatives({
                          initiativeId: row.initiative_id,
                          actionId:
                            row.entity_type === 'action'
                              ? row.entity_id
                              : null,
                        })
                      }
                    >
                      <strong>{row.code} · {row.name}</strong>
                      <span>{exception.label}</span>
                      <span className="skpe-monitoring-attention-guidance">
                        <b>Próxima ação:</b> {exception.guidance}
                      </span>
                      <small>
                        {row.entity_type === 'action'
                          ? 'Abrir ação para revisar'
                          : 'Abrir iniciativa para revisar'}
                      </small>
                    </button>
                  ))}
                  {overallocated.slice(0, 5).map((row) => (
                    <div key={row.capacity_period_id}>
                      <strong>{row.person_name}</strong>
                      <span>
                        Sobrealocação de {row.overallocation_amount} {row.capacity_unit}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </article>

            <article className="skpe-monitoring-panel">
              <header>
                <div>
                  <span>Distribuições operacionais</span>
                  <h2>Status de execução e agenda</h2>
                </div>
              </header>

              <div className="skpe-monitoring-tags">
                {statusCounts.map(([status, count]) => (
                  <span key={`action-${status}`}>Ações · {operationalStatusLabel(status)}: {count}</span>
                ))}
                {eventStatusCounts.map(([status, count]) => (
                  <span key={`event-${status}`}>Agenda · {operationalStatusLabel(status)}: {count}</span>
                ))}
                {statusCounts.length === 0 && eventStatusCounts.length === 0 && (
                  <span>Sem ações ou eventos registrados.</span>
                )}
              </div>

              <div className="skpe-monitoring-quality">
                <span>
                  Custos sem moeda: {economicQuality?.actionsWithCostWithoutCurrency ?? 0}
                </span>
                <span>
                  Esforços sem unidade: {economicQuality?.actionsWithEffortWithoutUnit ?? 0}
                </span>
              </div>
            </article>
          </div>

          <ManagementTimeline
            JourneyIcon={JourneyIcon}
            InitiativesIcon={InitiativesIcon}
            onOpenEconomicExecution={() => setShowEconomicEditor(true)}
            journeyRows={projection.journeyTemporal ?? []}
            initiativeRows={initiativeTemporal}
            events={events}
            referenceDate={projection.referenceDate}
            journeyVisible={canViewJourney}
            initiativesVisible={canViewInitiatives}
            onOpenJourney={onOpenJourney}
            onOpenInitiatives={onOpenInitiatives}
          />

          {canViewInitiatives ? (
            <ManagementExecutionMatrix
              actions={actionBoard}
              temporalRows={initiativeTemporal}
              allocations={allocations}
              capacityRows={capacityRows}
              capacityVisible={
                projection.capacity?.visible === true
              }
              onOpenInitiatives={onOpenInitiatives}
            />
          ) : null}

          {economicInitiative && economicDirect ? (
            <article className="skpe-monitoring-economic">
              <header>
                <div>
                  <span>Execução econômica governada</span>
                  <h2>
                    {economicInitiative.code} · {economicInitiative.name}
                  </h2>
                </div>
                {economicEditable ? (
                  <button
                    type="button"
                    onClick={() => setShowEconomicEditor(true)}
                  >
                    Editar valores diretos
                  </button>
                ) : null}
              </header>

              <div className="skpe-monitoring-economic-grid">
                <div>
                  <span>Custo direto planejado</span>
                  <strong>
                    {currencyDisplayLabel(economicDirect.currencyCode)}{' '}
                    {economicDirect.plannedCost ?? '—'}
                  </strong>
                </div>
                <div>
                  <span>Custo direto realizado</span>
                  <strong>
                    {currencyDisplayLabel(economicDirect.currencyCode)}{' '}
                    {economicDirect.actualCost ?? '—'}
                  </strong>
                </div>
                <div>
                  <span>Esforço direto estimado</span>
                  <strong>
                    {economicDirect.estimatedEffort ?? '—'}{' '}
                    {economicDirect.effortUnit ?? ''}
                  </strong>
                </div>
                <div>
                  <span>Esforço direto realizado</span>
                  <strong>
                    {economicDirect.actualEffort ?? '—'}{' '}
                    {economicDirect.effortUnit ?? ''}
                  </strong>
                </div>
              </div>

              <div className="skpe-monitoring-economic-breakdown">
                {costCurrencies.map((row) => (
                  <span key={`cost-${row.currencyCode}`}>
                    Ações · {currencyDisplayLabel(row.currencyCode)}: planejado {row.currentPlannedCost}
                    {' · '}realizado {row.actualRealizedCost}
                  </span>
                ))}
                {effortUnits.map((row) => (
                  <span key={`effort-${row.effortUnit}`}>
                    Ações · {row.effortUnit}: estimado {row.currentEstimatedEffort}
                    {' · '}realizado {row.actualRealizedEffort}
                  </span>
                ))}
              </div>

              <p>
                Valores diretos da iniciativa e valores derivados das ações são
                apresentados separadamente. Não há roll-up automático nem conversão
                cambial.
              </p>
            </article>
          ) : null}

          <footer className="skpe-monitoring-footer">
            <span>Referência: {projection.referenceDate ?? 'data atual da organização'}</span>
            <span>
              Projeção somente leitura: {projection.governance?.readOnlyProjection === false ? 'não' : 'sim'}
            </span>
          </footer>
        </>
      )}
      {showEconomicEditor && economicInitiative ? (
        <InitiativeEconomicExecutionDialog
          initiativeId={economicInitiative.initiativeId}
          initiativeCode={economicInitiative.code}
          initiativeName={economicInitiative.name}
          lifecycleStatus={economicInitiative.lifecycleStatus}
          direct={economicInitiative.direct}
          onClose={() => setShowEconomicEditor(false)}
          onSaved={() => {
            setShowEconomicEditor(false)
            setReloadToken((current) => current + 1)
          }}
        />
      ) : null}

      {showCapacityManager ? (
        <PersonCapacityManagementDialog
          organizationId={organizationId}
          onClose={() =>
            setShowCapacityManager(false)
          }
          onSaved={() => {
            setShowCapacityManager(false)
            setReloadToken(
              (current) => current + 1,
            )
          }}
        />
      ) : null}
    </section>
  )
}
