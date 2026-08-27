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
import {
  parsePlatformRoute,
  platformRoutes,
  type SkpeRouteSection,
} from './skpeRoutes'

type SkpeCockpitProps = ComponentProps<typeof SkpeCockpit>

export type SkpeWorkspaceProps = SkpeCockpitProps

type RoutableCockpitSection = Extract<
  CockpitSection,
  SkpeRouteSection
>

const ROUTABLE_COCKPIT_SECTIONS =
  new Set<RoutableCockpitSection>([
    'overview',
    'journey',
    'evolution-cycles',
    'initiatives',
    'monitoring',
    'artifacts',
    'governance',
  ])

function isRoutableCockpitSection(
  section: CockpitSection,
): section is RoutableCockpitSection {
  return ROUTABLE_COCKPIT_SECTIONS.has(
    section as RoutableCockpitSection,
  )
}

function isRoutableCockpitRouteSection(
  section: SkpeRouteSection,
): section is RoutableCockpitSection {
  return ROUTABLE_COCKPIT_SECTIONS.has(
    section as RoutableCockpitSection,
  )
}

function parseLegacyCockpitSection(
  search: string,
): CockpitSection | null {
  const section = new URLSearchParams(search).get('section')
  if (!section) return null

  return ROUTABLE_COCKPIT_SECTIONS.has(
    section as RoutableCockpitSection,
  )
    ? (section as RoutableCockpitSection)
    : null
}

export function SkpeWorkspace(props: SkpeWorkspaceProps) {
  const location = useLocation()
  const navigate = useNavigate()
  const route = parsePlatformRoute(location.pathname)

  const explicitRoute = route.kind === 'skpe' ? route : null

  const explicitSection =
    explicitRoute &&
    isRoutableCockpitRouteSection(
      explicitRoute.section,
    )
      ? explicitRoute.section
      : null

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

  const navigateExplicitSection = (section: SkpeRouteSection) => {
    if (!explicitRoute) return

    navigate(
      platformRoutes.skpe({
        organizationId: explicitRoute.organizationId,
        projectId: explicitRoute.projectId,
        formulationId: explicitRoute.formulationId,
        section,
      }),
    )
  }

  const handleNavigateSection = (section: CockpitSection) => {
    props.onNavigateSection?.(section)

    if (explicitRoute) {
      if (!isRoutableCockpitSection(section)) {
        return
      }

      navigateExplicitSection(section)
      return
    }

    if (
      props.mode === 'organization-admin' ||
      !isRoutableCockpitSection(section)
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
        initialSection={
          explicitSection ??
          legacySection ??
          props.initialSection
        }
        onNavigateSection={handleNavigateSection}
      />
    </SkpeWorkspaceProvider>
  )
}
