export type SkpeRouteSection =
  | 'overview'
  | 'journey'
  | 'formulations'
  | 'identity'
  | 'business-foundation'
  | 'value-chain'
  | 'strategic-map'
  | 'indicators'
  | 'okrs'
  | 'initiatives'
  | 'monitoring'
  | 'governance'
  | 'artifacts'

export type PlatformRoute =
  | { kind: 'home' }
  | { kind: 'workspace' }
  | { kind: 'platform-admin' }
  | { kind: 'organization'; organizationId: string }
  | { kind: 'organization-admin'; organizationId: string }
  | {
      kind: 'module'
      organizationId: string
      moduleCode: string
    }
  | {
      kind: 'skpe'
      organizationId: string
      projectId: string
      formulationId: string
      section: SkpeRouteSection
    }
  | { kind: 'unknown'; pathname: string }

const SKPE_SECTIONS = new Set<SkpeRouteSection>([
  'overview',
  'journey',
  'formulations',
  'identity',
  'business-foundation',
  'value-chain',
  'strategic-map',
  'indicators',
  'okrs',
  'initiatives',
  'monitoring',
  'governance',
  'artifacts',
])

function encode(value: string) {
  return encodeURIComponent(value)
}

function decode(value: string) {
  try {
    return decodeURIComponent(value)
  } catch {
    return value
  }
}

export const platformRoutes = {
  home: () => '/',
  workspace: () => '/workspace',
  platformAdmin: () => '/platform-admin',
  organization: (organizationId: string) =>
    `/organizations/${encode(organizationId)}`,
  organizationAdmin: (organizationId: string) =>
    `/organizations/${encode(organizationId)}/admin`,
  module: (organizationId: string, moduleCode: string) =>
    `/organizations/${encode(organizationId)}/modules/${encode(moduleCode)}`,
  skpe: ({
    organizationId,
    projectId,
    formulationId,
    section = 'overview',
  }: {
    organizationId: string
    projectId: string
    formulationId: string
    section?: SkpeRouteSection
  }) =>
    `/organizations/${encode(organizationId)}/skpe/projects/${encode(projectId)}/formulations/${encode(formulationId)}/${section}`,
}

export function parsePlatformRoute(pathname: string): PlatformRoute {
  const normalizedPath = pathname.replace(/\/+$/, '') || '/'

  if (normalizedPath === '/') return { kind: 'home' }
  if (normalizedPath === '/workspace') return { kind: 'workspace' }
  if (normalizedPath === '/platform-admin') {
    return { kind: 'platform-admin' }
  }

  const skpeMatch = normalizedPath.match(
    /^\/organizations\/([^/]+)\/skpe\/projects\/([^/]+)\/formulations\/([^/]+)(?:\/([^/]+))?$/,
  )
  if (skpeMatch) {
    const sectionCandidate = (skpeMatch[4] ?? 'overview') as SkpeRouteSection
    if (!SKPE_SECTIONS.has(sectionCandidate)) {
      return { kind: 'unknown', pathname: normalizedPath }
    }

    return {
      kind: 'skpe',
      organizationId: decode(skpeMatch[1]),
      projectId: decode(skpeMatch[2]),
      formulationId: decode(skpeMatch[3]),
      section: sectionCandidate,
    }
  }

  const organizationAdminMatch = normalizedPath.match(
    /^\/organizations\/([^/]+)\/admin$/,
  )
  if (organizationAdminMatch) {
    return {
      kind: 'organization-admin',
      organizationId: decode(organizationAdminMatch[1]),
    }
  }

  const moduleMatch = normalizedPath.match(
    /^\/organizations\/([^/]+)\/modules\/([^/]+)$/,
  )
  if (moduleMatch) {
    return {
      kind: 'module',
      organizationId: decode(moduleMatch[1]),
      moduleCode: decode(moduleMatch[2]),
    }
  }

  const organizationMatch = normalizedPath.match(
    /^\/organizations\/([^/]+)$/,
  )
  if (organizationMatch) {
    return {
      kind: 'organization',
      organizationId: decode(organizationMatch[1]),
    }
  }

  return { kind: 'unknown', pathname: normalizedPath }
}
