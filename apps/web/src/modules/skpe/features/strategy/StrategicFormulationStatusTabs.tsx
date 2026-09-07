import { useEffect, useMemo, useState } from 'react'

import { WorkspaceTabs } from '../../../../components/design-system'
import { supabase } from '../../../../lib/supabase'

export type StrategicFormulationTab =
  | 'overview'
  | 'pmvv'
  | 'architecture'
  | 'performance'
  | 'initiatives'
  | 'plan'

type TabStatus = 'not_started' | 'in_progress' | 'completed'

type Props = {
  organizationId: string
  projectId: string
  activeId: StrategicFormulationTab
  onChange: (id: StrategicFormulationTab) => void
}

type Snapshot = {
  formulationStatus: string | null
  identityStatus: string | null
  strategicMapPackageStatus: string | null
  okrPackageStatus: string | null
  initiativePackageStatus: string | null
  objectiveCount: number
  okrCount: number
  initiativeCount: number
}

const completedStatuses = new Set([
  'approved',
  'validated',
  'completed',
  'complete',
])

function deriveStatus(
  packageStatus: string | null,
  materializedCount: number,
): TabStatus {
  if (packageStatus && completedStatuses.has(packageStatus)) return 'completed'
  if (packageStatus || materializedCount > 0) return 'in_progress'
  return 'not_started'
}

function labelFor(status: TabStatus) {
  if (status === 'completed') return 'ConcluÃ­do'
  if (status === 'in_progress') return 'Em andamento'
  return 'Ainda nÃ£o iniciado'
}

export function StrategicFormulationStatusTabs({
  organizationId,
  projectId,
  activeId,
  onChange,
}: Props) {
  const [snapshot, setSnapshot] = useState<Snapshot>({
    formulationStatus: null,
    identityStatus: null,
    strategicMapPackageStatus: null,
    okrPackageStatus: null,
    initiativePackageStatus: null,
    objectiveCount: 0,
    okrCount: 0,
    initiativeCount: 0,
  })

  useEffect(() => {
    let active = true

    async function load() {
      const { data: formulationRows } = await supabase
        .from('skpe_strategic_formulations')
        .select('id, status')
        .eq('organization_id', organizationId)
        .eq('project_id', projectId)
        .in('status', ['draft', 'under_review', 'approved'])
        .order('version_number', { ascending: false })
        .limit(2)

      if (!active) return

      const formulationId =
        formulationRows?.length === 1 ? formulationRows[0]?.id ?? null : null
      const formulationStatus =
        formulationRows?.length === 1 ? formulationRows[0]?.status ?? null : null

      const [
        identityResponse,
        objectiveResponse,
        okrResponse,
        initiativeResponse,
        strategicMapPackageResponse,
        okrPackageResponse,
        initiativePackageResponse,
      ] = await Promise.all([
        supabase
          .from('skpe_strategic_identity')
          .select('status')
          .eq('organization_id', organizationId)
          .eq('project_id', projectId)
          .maybeSingle(),
        supabase
          .from('skpe_strategic_objectives')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_okrs')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        supabase
          .from('skpe_sparks_initiative_strategic_links')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organizationId)
          .eq('project_id', projectId),
        formulationId
          ? supabase
              .from('skpe_strategic_map_packages')
              .select('status')
              .eq('organization_id', organizationId)
              .eq('project_id', projectId)
              .eq('formulation_id', formulationId)
              .maybeSingle()
          : Promise.resolve({ data: null }),
        formulationId
          ? supabase
              .from('skpe_okr_packages')
              .select('status')
              .eq('organization_id', organizationId)
              .eq('project_id', projectId)
              .eq('formulation_id', formulationId)
              .maybeSingle()
          : Promise.resolve({ data: null }),
        formulationId
          ? supabase
              .from('skpe_initiative_packages')
              .select('status')
              .eq('organization_id', organizationId)
              .eq('project_id', projectId)
              .eq('formulation_id', formulationId)
              .maybeSingle()
          : Promise.resolve({ data: null }),
      ])

      if (!active) return

      setSnapshot({
        formulationStatus,
        identityStatus: identityResponse.data?.status ?? null,
        strategicMapPackageStatus:
          strategicMapPackageResponse.data?.status ?? null,
        okrPackageStatus: okrPackageResponse.data?.status ?? null,
        initiativePackageStatus:
          initiativePackageResponse.data?.status ?? null,
        objectiveCount: objectiveResponse.count ?? 0,
        okrCount: okrResponse.count ?? 0,
        initiativeCount: initiativeResponse.count ?? 0,
      })
    }

    void load()
    return () => {
      active = false
    }
  }, [organizationId, projectId])

  const tabs = useMemo(() => {
    const overviewStatus: TabStatus = snapshot.formulationStatus
      ? completedStatuses.has(snapshot.formulationStatus)
        ? 'completed'
        : 'in_progress'
      : 'not_started'

    const pmvvStatus: TabStatus = snapshot.identityStatus
      ? completedStatuses.has(snapshot.identityStatus)
        ? 'completed'
        : 'in_progress'
      : 'not_started'

    const architectureStatus = deriveStatus(
      snapshot.strategicMapPackageStatus,
      snapshot.objectiveCount,
    )
    const performanceStatus = deriveStatus(
      snapshot.okrPackageStatus,
      snapshot.okrCount,
    )
    const initiativeStatus = deriveStatus(
      snapshot.initiativePackageStatus,
      snapshot.initiativeCount,
    )

    const planStatus: TabStatus =
      overviewStatus === 'completed' &&
      pmvvStatus === 'completed' &&
      architectureStatus === 'completed' &&
      performanceStatus === 'completed' &&
      initiativeStatus === 'completed'
        ? 'completed'
        : overviewStatus === 'not_started'
          ? 'not_started'
          : 'in_progress'

    return [
      {
        id: 'overview' as const,
        label: 'Visão Geral',
        status: overviewStatus,
        statusLabel: labelFor(overviewStatus),
      },
      {
        id: 'pmvv' as const,
        label: 'PMVV',
        status: pmvvStatus,
        statusLabel: labelFor(pmvvStatus),
      },
      {
        id: 'architecture' as const,
        label: 'Mapa Estratégico',
        status: architectureStatus,
        statusLabel: labelFor(architectureStatus),
      },
      {
        id: 'performance' as const,
        label: 'Desdobramento em OKRs',
        status: performanceStatus,
        statusLabel: labelFor(performanceStatus),
      },
      {
        id: 'initiatives' as const,
        label: 'Plano de Iniciativas',
        status: initiativeStatus,
        statusLabel: labelFor(initiativeStatus),
      },
      {
        id: 'plan' as const,
        label: 'Plano Estratégico',
        status: planStatus,
        statusLabel: labelFor(planStatus),
      },
    ]
  }, [snapshot])

  return (
    <WorkspaceTabs
      ariaLabel="Etapas da FormulaÃ§Ã£o EstratÃ©gica"
      activeId={activeId}
      onChange={onChange}
      tabs={tabs}
    />
  )
}