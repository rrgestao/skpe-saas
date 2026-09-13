import { useEffect, useState } from 'react'

import { supabase } from '../../../../lib/supabase'
import {
  StrategicFormulationStatusTabs,
  type StrategicFormulationTab,
} from './StrategicFormulationStatusTabs'
import { StrategicInitiativePlanSection } from './StrategicInitiativePlanSection'
import { StrategicIdentitySection } from './StrategicIdentitySection'
import { StrategicExecutiveOverview } from './StrategicExecutiveOverview'
import { StrategicArchitectureSummary } from './StrategicArchitectureSummary'
import { StrategicOkrDecompositionSection } from './StrategicOkrDecompositionSection'
import { StrategicBscMap } from './StrategicBscMap'
import { StrategicFormulationLifecyclePanel } from './StrategicFormulationLifecyclePanel'
import { phase2SuggestionGovernanceNotice } from '../../contracts/strategic-suggestion-governance.ts'

import './StrategicFormulationSection.css'

type FormulationTab = StrategicFormulationTab

type InitiativeRow = {
  id: string
  code: string
  name: string
  status: string
  progress: number
  priority: string
}

type Props = {
  organizationId: string
  projectId: string
  canAdjustStrategicMap: boolean
}

type FormulationReadiness = {
  readyForApproval: boolean
  issues?: Array<{ code: string; severity: string; message: string; affectedCount?: number }>
}

type MonitoringReadiness = {
  packageStatus: string | null
  readyForFormulation: boolean
}

function percent(value: number | null | undefined) {
  return `${Number(value ?? 0).toLocaleString('pt-BR', {
    maximumFractionDigits: 1,
  })}%`
}

export function StrategicFormulationSection({
  organizationId,
  projectId,
  canAdjustStrategicMap,
}: Props) {
  const [formulationId, setFormulationId] = useState<string | null>(null)
  const [formulationStatus, setFormulationStatus] = useState<string | null>(null)
  const [formulationReadiness, setFormulationReadiness] = useState<FormulationReadiness | null>(null)
  const [monitoringReadiness, setMonitoringReadiness] = useState<MonitoringReadiness | null>(null)
  const [canManageFormulation, setCanManageFormulation] = useState(false)
  const [canValidateFormulation, setCanValidateFormulation] = useState(false)
  const [canApproveFormulation, setCanApproveFormulation] = useState(false)
  const [lifecycleTransitioning, setLifecycleTransitioning] = useState(false)
  const [lifecycleMessage, setLifecycleMessage] = useState('')
  const [lifecycleReloadToken, setLifecycleReloadToken] = useState(0)
  const [activeTab, setActiveTab] = useState<FormulationTab>('overview')
  const [initiatives, setInitiatives] = useState<InitiativeRow[]>([])
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    let active = true

    async function load() {
      setErrorMessage('')

      const [
        identityResponse,
        valuesResponse,
        themesResponse,
        objectivesResponse,
        okrsResponse,
        keyResultsResponse,
        indicatorsResponse,
        initiativesResponse,
      ] = await Promise.all([
        supabase
          .from('skpe_strategic_identity')
          .select('status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .maybeSingle(),
        supabase
          .from('skpe_strategic_values')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_strategic_themes')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_strategic_objectives')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_okrs')
          .select('id, code, title, description, status, progress, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .order('display_order'),
        supabase
          .from('skpe_key_results')
          .select('id, code, name, description, target_value, current_value, unit, progress, validation_status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .order('code'),
        supabase
          .from('skpe_indicators')
          .select('id, code, name, description, unit, status, baseline_value')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .order('code'),
        supabase
          .from('sparks_initiatives')
          .select('id, code, name, status, progress, priority')
          .eq('organization_id', organizationId)
          .is('archived_at', null)
          .order('code'),
      ])

      if (!active) return

      const responses = [
        identityResponse,
        valuesResponse,
        themesResponse,
        objectivesResponse,
        okrsResponse,
        keyResultsResponse,
        indicatorsResponse,
        initiativesResponse,
      ]

      const firstError = responses.find((response) => response.error)?.error

      if (firstError) {
        setErrorMessage(
          `Não foi possível consolidar a Formulação Estratégica: ${firstError.message}`,
        )
        return
      }

      const { data: formulationRows, error: formulationError } = await supabase
        .from('skpe_strategic_formulations')
        .select('id,status,version_number')
        .eq('organization_id', organizationId)
        .eq('project_id', projectId)
        .in('status', ['draft', 'in_elaboration', 'pending_validation', 'validated', 'pending_approval', 'approved'])
        .order('version_number', { ascending: false })
        .limit(1)

      if (!active) return

      if (formulationError) {
        setErrorMessage(
          `Não foi possível resolver a versão da Formulação Estratégica: ${formulationError.message}`,
        )
        return
      }

      setFormulationId(formulationRows?.[0]?.id ?? null)
      setFormulationStatus(formulationRows?.[0]?.status ?? null)
      setInitiatives((initiativesResponse.data ?? []) as InitiativeRow[])
    }

    void load()

    return () => {
      active = false
    }
  }, [organizationId, projectId])

  useEffect(() => {
    let active = true

    async function loadLifecycle() {
      if (!formulationId) {
        setFormulationReadiness(null)
        setMonitoringReadiness(null)
        setCanManageFormulation(false)
        setCanValidateFormulation(false)
        setCanApproveFormulation(false)
        return
      }

      const [readinessResponse, monitoringResponse, manageResponse, validateResponse, approveResponse] = await Promise.all([
        supabase.rpc('get_skpe_formulation_readiness', { target_formulation_id: formulationId }),
        supabase.rpc('get_skpe_monitoring_package_readiness', { p_formulation_id: formulationId, p_include_package_state: true }),
        supabase.rpc('can_manage_skpe_formulation', { target_organization_id: organizationId }),
        supabase.rpc('can_validate_skpe_formulation', { target_organization_id: organizationId }),
        supabase.rpc('can_approve_skpe_formulation', { target_organization_id: organizationId }),
      ])

      if (!active) return

      setFormulationReadiness(readinessResponse.error ? null : (readinessResponse.data as FormulationReadiness))
      setMonitoringReadiness(monitoringResponse.error ? null : (monitoringResponse.data as MonitoringReadiness))
      setCanManageFormulation(manageResponse.error ? false : manageResponse.data === true)
      setCanValidateFormulation(validateResponse.error ? false : validateResponse.data === true)
      setCanApproveFormulation(approveResponse.error ? false : approveResponse.data === true)
    }

    void loadLifecycle()
    return () => { active = false }
  }, [formulationId, organizationId, lifecycleReloadToken])

  const transitionFormulation = async (action: string, reason: string, notes: string) => {
    if (!formulationId || reason.trim().length < 10) return
    setLifecycleTransitioning(true)
    setLifecycleMessage('')

    const { data, error } = await supabase.rpc('transition_skpe_formulation', {
      target_formulation_id: formulationId,
      transition_action: action,
      decision_notes: notes.trim() || null,
      change_reason: reason.trim(),
    })

    setLifecycleTransitioning(false)
    if (error) {
      setLifecycleMessage(error.message)
      return
    }

    const currentStatus = (data as { currentStatus?: string } | null)?.currentStatus
    if (currentStatus) setFormulationStatus(currentStatus)
    setLifecycleMessage('Transição da Formulação registrada com rastreabilidade.')
    setLifecycleReloadToken((current) => current + 1)
  }

  return (
    <section className="skpe-strategic-formulation">
<StrategicFormulationStatusTabs
        organizationId={organizationId}
        projectId={projectId}
        activeId={activeTab}
        onChange={(id) => setActiveTab(id)}
      />

      <article className="skpe-formulation-synthesis" aria-label="Governança das sugestões da Fase 2">
        <h3>Análise assistida e validação humana</h3>
        <p>{phase2SuggestionGovernanceNotice}</p>
      </article>

      {formulationStatus && formulationReadiness && monitoringReadiness ? (
        <StrategicFormulationLifecyclePanel
          status={formulationStatus}
          readyForApproval={formulationReadiness.readyForApproval}
          formulationIssues={formulationReadiness.issues ?? []}
          monitoringReady={monitoringReadiness.readyForFormulation}
          monitoringStatus={monitoringReadiness.packageStatus}
          canManage={canManageFormulation}
          canValidate={canValidateFormulation}
          canApprove={canApproveFormulation}
          transitioning={lifecycleTransitioning}
          message={lifecycleMessage}
          onTransition={(action, reason, notes) => { void transitionFormulation(action, reason, notes) }}
        />
      ) : null}

      {errorMessage ? (
        <div className="skpe-admin-message skpe-admin-message-error">
          {errorMessage}
        </div>
      ) : null}

      {activeTab === 'overview' ? (
        <StrategicExecutiveOverview
          organizationId={organizationId}
          projectId={projectId}
        />
      ) : null}
      {activeTab === 'pmvv' ? (
        <section className="skpe-formulation-tab-panel">
          <StrategicIdentitySection
            organizationId={organizationId}
            projectId={projectId}
            formulationId={formulationId}
          />
          <article className="skpe-formulation-synthesis">
            <h3>Síntese e considerações</h3>
            <p>
              O PMVV deve orientar escolhas, objetivos e iniciativas. A
              aprovação da identidade não substitui a validação posterior dos
              Objetivos Estratégicos e demais desdobramentos.
            </p>
          </article>
        </section>
      ) : null}

      {activeTab === 'architecture' ? (
        <section className="skpe-formulation-tab-panel">
          <StrategicBscMap
            formulationId={formulationId}
            canAdjustLayout={canAdjustStrategicMap}
          />
          <StrategicArchitectureSummary formulationId={formulationId} />
        </section>
      ) : null}
{activeTab === 'performance' ? (
        <section className="skpe-formulation-tab-panel">
          <StrategicOkrDecompositionSection
            organizationId={organizationId}
            projectId={projectId}
            formulationId={formulationId}
          />
        </section>
      ) : null}
      {activeTab === 'initiatives' ? (
        <StrategicInitiativePlanSection
          organizationId={organizationId}
          projectId={projectId}
        />
      ) : null}
{activeTab === 'plan' ? (
        <section className="skpe-formulation-tab-panel">
          <div className="skpe-formulation-plan-list">
            {initiatives.map((initiative) => (
              <article key={initiative.id}>
                <div>
                  <small>{initiative.code}</small>
                  <strong>{initiative.name}</strong>
                </div>
                <div>
                  <span>{initiative.status}</span>
                  <strong>{percent(initiative.progress)}</strong>
                </div>
              </article>
            ))}
          </div>

          <article className="skpe-formulation-synthesis">
            <h3>Síntese e considerações</h3>
            <p>
              O Plano Estratégico consolida as iniciativas que materializam a
              execução da estratégia. A edição operacional continua no Plano
              de Ação, preservando uma única fonte de verdade.
            </p>
          </article>
        </section>
      ) : null}
    </section>
  )
}
