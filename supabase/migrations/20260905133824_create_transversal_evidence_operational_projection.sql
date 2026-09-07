create or replace view public.sparks_evidence_operational_projection
with (security_invoker = true)
as
select
  asset.id as evidence_asset_id,
  asset.organization_id,
  asset.title,
  asset.evidence_type,
  asset.source_type,
  asset.origin_module_code,
  asset.external_origin,
  asset.reference_date,
  asset.reference_period_start,
  asset.reference_period_end,
  asset.validity_date,
  asset.validation_status,
  asset.reliability_level,
  asset.quality_score,
  asset.completeness_score,
  asset.currentness_score,
  asset.overall_score,
  asset.source_evidence_asset_id,
  asset.source_external_key,
  asset.archived_at,
  case
    when asset.archived_at is not null then 'archived'
    else 'available'
  end as availability_status,
  case
    when asset.validity_date is null then 'not_assessed'
    when asset.validity_date < current_date then 'expired'
    else 'valid'
  end as validity_status,
  case
    when asset.overall_score is not null then
      case
        when asset.overall_score >= 80 then 'high'
        when asset.overall_score >= 60 then 'moderate'
        else 'low'
      end
    when asset.quality_score is not null then
      case
        when asset.quality_score >= 80 then 'high'
        when asset.quality_score >= 60 then 'moderate'
        else 'low'
      end
    else 'not_assessed'
  end as quality_status,
  link.id as evidence_link_id,
  link.module_code as usage_module_code,
  link.target_type,
  link.target_id,
  link.usage_purpose,
  link.usage_status,
  link.relevance_level,
  link.is_primary,
  case
    when link.id is null then false
    when link.usage_status = 'active' then true
    else false
  end as is_currently_used,
  case
    when link.id is null then 'not_used'
    when link.usage_status <> 'active' then 'not_active'
    when asset.origin_module_code is null then 'reused_origin_unknown'
    when link.module_code is distinct from asset.origin_module_code then 'reused_cross_module'
    else 'used_in_origin_module'
  end as reuse_status,
  latest_assessment.assessment_version,
  latest_assessment.adequacy_score,
  latest_assessment.sufficiency_score,
  latest_assessment.reliability_score as usage_reliability_score,
  latest_assessment.confidence_level,
  latest_assessment.strengths,
  latest_assessment.gaps,
  latest_assessment.risks,
  latest_assessment.recommendations,
  latest_assessment.assessment_basis,
  latest_assessment.assessed_at,
  case
    when link.id is null then 'not_applicable_without_use'
    when latest_assessment.id is null then 'not_assessed'
    when latest_assessment.sufficiency_score is null then 'not_assessed'
    when latest_assessment.sufficiency_score >= 80 then 'sufficient'
    when latest_assessment.sufficiency_score >= 60 then 'partially_sufficient'
    else 'insufficient'
  end as sufficiency_status
from public.sparks_evidence_assets asset
left join public.sparks_evidence_links link
  on link.evidence_asset_id = asset.id
 and link.organization_id = asset.organization_id
left join lateral (
  select assessment.*
  from public.sparks_evidence_usage_assessments assessment
  where assessment.evidence_link_id = link.id
  order by assessment.assessment_version desc, assessment.assessed_at desc, assessment.id desc
  limit 1
) latest_assessment on true;

comment on view public.sparks_evidence_operational_projection is
  'Projecao transversal do estado operacional das evidencias. Separa disponibilidade e validade do ativo, uso e reutilizacao por vinculo e suficiencia/confianca por avaliacao contextual. Evidencia disponivel nao implica evidencia utilizada.';

grant select on public.sparks_evidence_operational_projection to authenticated;