-- ============================================================
-- Verificacao da fundacao de acesso hierarquico e CNAE oficial
-- Execute depois da migration e, novamente, depois do seed CNAE.
-- ============================================================

select
  to_regclass('public.cnae_catalog_versions') as cnae_catalog_versions,
  to_regclass('public.cnae_catalog') as cnae_catalog,
  to_regclass('public.organization_cnae_audit') as organization_cnae_audit;

select
  version_code,
  version_name,
  is_current,
  active,
  imported_at
from public.cnae_catalog_versions
order by version_code;

select
  version_code,
  count(*) as quantidade_cnaes_ativos
from public.cnae_catalog
where active = true
group by version_code
order by version_code;

select
  organization.code as organization_code,
  coalesce(organization.trade_name, organization.legal_name) as organization_name,
  count(*) filter (where activity.status = 'active') as cnaes_ativos,
  count(*) filter (
    where activity.status = 'active'
      and activity.cnae_catalog_id is null
  ) as cnaes_legados_para_revisao,
  count(*) filter (
    where activity.status = 'active'
      and activity.verification_status = 'verified'
  ) as cnaes_verificados
from public.organizations organization
left join public.organization_economic_activities activity
  on activity.organization_id = organization.id
group by organization.id, organization.code, organization.trade_name, organization.legal_name
order by organization.code;

select
  source.code as source_code,
  coalesce(source.trade_name, source.legal_name) as source_name,
  child.code as child_code,
  coalesce(child.trade_name, child.legal_name) as child_name,
  relationship_type.code as relationship_type,
  relationship.allows_consolidated_view,
  relationship_type.allows_consolidated_view as type_allows_consolidated_view,
  relationship.status
from public.organization_relationships relationship
join public.organization_relationship_types relationship_type
  on relationship_type.id = relationship.relationship_type_id
join public.organizations source
  on source.id = relationship.parent_organization_id
join public.organizations child
  on child.id = relationship.child_organization_id
where relationship.status = 'active'
order by source.code, child.code;

-- Execute autenticado na aplicacao para validar o resultado por usuario:
-- select * from public.get_my_organizations_v2();
