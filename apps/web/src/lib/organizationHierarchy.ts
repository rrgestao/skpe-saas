export type OrganizationSortDirection = 'asc' | 'desc'

export type HierarchicalOrganization = {
  organization_id: string
  organization_code: string
  legal_name: string
  trade_name: string | null
}

export type OrganizationHierarchyNode = {
  organization_id: string
  parent_organization_id: string | null
}

function getOrganizationName(
  organization: HierarchicalOrganization,
) {
  return (
    organization.trade_name ??
    organization.legal_name ??
    organization.organization_code
  )
}

export function sortOrganizationsHierarchically<
  TOrganization extends HierarchicalOrganization,
>(
  organizations: readonly TOrganization[],
  hierarchy: readonly OrganizationHierarchyNode[],
  direction: OrganizationSortDirection,
): TOrganization[] {
  const directionFactor = direction === 'asc' ? 1 : -1
  const compareOrganizations = (
    first: TOrganization,
    second: TOrganization,
  ) =>
    getOrganizationName(first).localeCompare(
      getOrganizationName(second),
      'pt-BR',
    ) * directionFactor

  if (hierarchy.length === 0) {
    return [...organizations].sort(compareOrganizations)
  }

  const visibleById = new Map(
    organizations.map((organization) => [
      organization.organization_id,
      organization,
    ]),
  )

  const hierarchyByOrganization = new Map(
    hierarchy.map((node) => [
      node.organization_id,
      node,
    ]),
  )

  const childrenByParent = new Map<
    string,
    TOrganization[]
  >()
  const roots: TOrganization[] = []

  for (const organization of organizations) {
    const node = hierarchyByOrganization.get(
      organization.organization_id,
    )
    const parentId = node?.parent_organization_id ?? null

    if (!parentId || !visibleById.has(parentId)) {
      roots.push(organization)
      continue
    }

    const siblings = childrenByParent.get(parentId) ?? []
    siblings.push(organization)
    childrenByParent.set(parentId, siblings)
  }

  roots.sort(compareOrganizations)

  for (const siblings of childrenByParent.values()) {
    siblings.sort(compareOrganizations)
  }

  const ordered: TOrganization[] = []
  const visited = new Set<string>()

  const visit = (organization: TOrganization) => {
    if (visited.has(organization.organization_id)) {
      return
    }

    visited.add(organization.organization_id)
    ordered.push(organization)

    const children =
      childrenByParent.get(organization.organization_id) ??
      []

    for (const child of children) {
      visit(child)
    }
  }

  for (const root of roots) {
    visit(root)
  }

  // Protecao deterministica para dados hierarquicos incompletos
  // ou ciclos legados: nenhum item visivel deve desaparecer.
  const remaining = organizations
    .filter(
      (organization) =>
        !visited.has(organization.organization_id),
    )
    .sort(compareOrganizations)

  for (const organization of remaining) {
    visit(organization)
  }

  return ordered
}
