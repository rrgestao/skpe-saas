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
        .select('id')
        .eq('organization_id', organizationId)
        .eq('project_id', projectId)
        .in('status', ['draft', 'under_review', 'approved'])
        .order('version_number', { ascending: false })
        .limit(2)

      if (!active) return

      if (formulationError) {
        setErrorMessage(
          `Não foi possível resolver a versão da Formulação Estratégica: ${formulationError.message}`,
        )
        return
      }

      setFormulationId(
        formulationRows?.length === 1 ? formulationRows[0]?.id ?? null : null,
      )
      setInitiatives((initiativesResponse.data ?? []) as InitiativeRow[])
    }

    void load()

    return () => {
      active = false
    }
  }, [organizationId, projectId])
  return (
    <section className="skpe-strategic-formulation">
<StrategicFormulationStatusTabs
        organizationId={organizationId}
        projectId={projectId}
        activeId={activeTab}
        onChange={(id) => setActiveTab(id)}
      />

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
