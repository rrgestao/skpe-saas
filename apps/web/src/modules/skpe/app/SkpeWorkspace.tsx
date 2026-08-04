import type { ComponentProps } from 'react'
import { useLocation } from 'react-router-dom'

import { SkpeCockpit } from '../SkpeCockpit'
import {
  SkpeWorkspaceProvider,
  type SkpeWorkspaceContextValue,
} from '../context/SkpeWorkspaceContext'
import { parsePlatformRoute } from './skpeRoutes'

type SkpeCockpitProps = ComponentProps<typeof SkpeCockpit>

export type SkpeWorkspaceProps = SkpeCockpitProps

export function SkpeWorkspace(props: SkpeWorkspaceProps) {
  const location = useLocation()
  const route = parsePlatformRoute(location.pathname)

  const explicitRoute = route.kind === 'skpe' ? route : null

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

  return (
    <SkpeWorkspaceProvider value={contextValue}>
      <SkpeCockpit {...props} />
    </SkpeWorkspaceProvider>
  )
}
