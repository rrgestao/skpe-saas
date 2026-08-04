import {
  createContext,
  type ReactNode,
  useContext,
  useMemo,
} from 'react'

import type { SkpeRouteSection } from '../app/skpeRoutes'

export type SkpeWorkspaceContextValue = {
  organization: {
    id: string
    code: string
    name: string
  }
  access: {
    roleCode: string
    roleName: string
    isOrganizationAdmin: boolean
    isPlatformSuperAdmin: boolean
  }
  route: {
    projectId: string | null
    formulationId: string | null
    cycleId: string | null
    section: SkpeRouteSection | null
  }
  contextMode: 'legacy' | 'explicit'
}

type SkpeWorkspaceProviderProps = {
  value: SkpeWorkspaceContextValue
  children: ReactNode
}

const SkpeWorkspaceContext =
  createContext<SkpeWorkspaceContextValue | null>(null)

export function SkpeWorkspaceProvider({
  value,
  children,
}: SkpeWorkspaceProviderProps) {
  const stableValue = useMemo(
    () => value,
    [
      value.organization.id,
      value.organization.code,
      value.organization.name,
      value.access.roleCode,
      value.access.roleName,
      value.access.isOrganizationAdmin,
      value.access.isPlatformSuperAdmin,
      value.route.projectId,
      value.route.formulationId,
      value.route.cycleId,
      value.route.section,
      value.contextMode,
    ],
  )

  return (
    <SkpeWorkspaceContext.Provider value={stableValue}>
      {children}
    </SkpeWorkspaceContext.Provider>
  )
}

export function useSkpeWorkspace() {
  const context = useContext(SkpeWorkspaceContext)
  if (!context) {
    throw new Error(
      'useSkpeWorkspace deve ser utilizado dentro de SkpeWorkspaceProvider.',
    )
  }
  return context
}
