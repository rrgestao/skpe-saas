import type { ComponentProps } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'

import {
  SkpeCockpit,
  type CockpitSection,
} from '../SkpeCockpit'
import {
  SkpeWorkspaceProvider,
  type SkpeWorkspaceContextValue,
} from '../context/SkpeWorkspaceContext'
import { parsePlatformRoute } from './skpeRoutes'

type SkpeCockpitProps = ComponentProps<typeof SkpeCockpit>

export type SkpeWorkspaceProps = SkpeCockpitProps

const LEGACY_COCKPIT_SECTIONS = new Set<CockpitSection>([
  'overview',
  'journey',
  'initiatives',
  'artifacts',
  'governance',
])

function parseLegacyCockpitSection(
  search: string,
): CockpitSection | null {
  const section = new URLSearchParams(search).get('section')
  if (!section) return null

  return LEGACY_COCKPIT_SECTIONS.has(section as CockpitSection)
    ? (section as CockpitSection)
    : null
}

export function SkpeWorkspace(props: SkpeWorkspaceProps) {
  const location = useLocation()
  const navigate = useNavigate()
  const route = parsePlatformRoute(location.pathname)

  const explicitRoute = route.kind === 'skpe' ? route : null
  const legacySection =
    !explicitRoute && props.mode !== 'organization-admin'
      ? parseLegacyCockpitSection(location.search)
      : null

  const contextValue: SkpeWorkspaceContextValue = {
    organization: {
      id: props.organizationId,
      code: props.organizationCode,
      name: props.organizationName,
    },
    access: {
      roleCode: props.userRoleCode,
      roleName: props.userRoleName,
      isOrganizationAdmin: props.isOrganizationAdmin,
      isPlatformSuperAdmin: props.isPlatformSuperAdmin,
    },
    route: {
      projectId: explicitRoute?.projectId ?? null,
      formulationId: explicitRoute?.formulationId ?? null,
      cycleId: null,
      section: explicitRoute?.section ?? null,
    },
    contextMode: explicitRoute ? 'explicit' : 'legacy',
  }

  const handleNavigateSection = (section: CockpitSection) => {
    props.onNavigateSection?.(section)

    if (
      explicitRoute ||
      props.mode === 'organization-admin' ||
      !LEGACY_COCKPIT_SECTIONS.has(section)
    ) {
      return
    }

    const searchParams = new URLSearchParams(location.search)
    searchParams.set('section', section)

    navigate({
      pathname: location.pathname,
      search: `?${searchParams.toString()}`,
    })
  }

  return (
    <SkpeWorkspaceProvider value={contextValue}>
      <SkpeCockpit
        {...props}
        initialSection={legacySection ?? props.initialSection}
        onNavigateSection={handleNavigateSection}
      />
    </SkpeWorkspaceProvider>
  )
}
