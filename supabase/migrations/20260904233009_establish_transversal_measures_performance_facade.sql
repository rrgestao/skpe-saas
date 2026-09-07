create or replace view public.sparks_measure_indicators
with (security_invoker = true)
as
select
  i.id,
  i.organization_id,
  i.project_id as source_project_id,
  i.formulation_id as source_context_id,
  'SK-PE'::text as source_module_code,
  'strategic_formulation'::text as context_type,
  i.code,
  i.name,
  i.description,
  i.indicator_scope,
  case
    when i.key_result_id is not null then 'key_result'
    when i.strategic_objective_id is not null then 'strategic_objective'
    else 'unbound'
  end::text as subject_type,
  coalesce(i.key_result_id, i.strategic_objective_id) as subject_id,
  i.formula_text,
  i.unit,
  i.polarity,
  i.measurement_frequency,
  i.data_source,
  i.baseline_value,
  i.baseline_date,
  i.owner_user_id,
  i.status,
  i.reference_catalog_id,
  i.reference_adaptation_notes,
  i.metadata,
  i.created_at,
  i.created_by,
  i.updated_at,
  i.updated_by
from public.skpe_indicators i;

create or replace view public.sparks_measure_targets
with (security_invoker = true)
as
select
  t.id,
  t.organization_id,
  t.project_id as source_project_id,
  t.formulation_id as source_context_id,
  'SK-PE'::text as source_module_code,
  'strategic_formulation'::text as context_type,
  t.indicator_id,
  t.target_type,
  t.period_start,
  t.period_end,
  t.target_value,
  t.minimum_value,
  t.challenge_value,
  t.tolerance_lower,
  t.tolerance_upper,
  t.owner_user_id,
  t.status,
  t.metadata,
  t.created_at,
  t.created_by,
  t.updated_at,
  t.updated_by
from public.skpe_indicator_targets t;

create or replace view public.sparks_measure_benchmarks
with (security_invoker = true)
as
select
  b.id,
  b.organization_id,
  b.project_id as source_project_id,
  b.formulation_id as source_context_id,
  'SK-PE'::text as source_module_code,
  'strategic_formulation'::text as context_type,
  b.indicator_id,
  b.indicator_target_id,
  b.benchmark_type,
  b.reference_organization,
  b.source_name,
  b.source_reference,
  b.reference_period,
  b.benchmark_value,
  b.applicability,
  b.gap_analysis,
  b.notes,
  b.verified_at,
  b.verified_by,
  b.status,
  b.metadata,
  b.created_at,
  b.created_by,
  b.updated_at,
  b.updated_by
from public.skpe_benchmark_references b;

create or replace view public.sparks_measure_measurements
with (security_invoker = true)
as
select
  m.id,
  m.organization_id,
  m.project_id as source_project_id,
  m.formulation_id as source_context_id,
  'SK-PE'::text as source_module_code,
  'strategic_formulation'::text as context_type,
  m.monitoring_cycle_id as source_cycle_id,
  m.indicator_id,
  m.indicator_target_id,
  m.measurement_date,
  m.period_start,
  m.period_end,
  m.measured_value,
  m.automatic_performance,
  m.manual_performance_override,
  m.effective_performance,
  m.status,
  m.data_quality,
  m.source_name,
  m.source_reference,
  m.evidence_reference,
  m.notes,
  m.supersedes_measurement_id,
  m.validated_at,
  m.validated_by,
  m.metadata,
  m.created_at,
  m.created_by
from public.skpe_indicator_measurements m;

create or replace view public.sparks_measure_reference_catalog
with (security_invoker = true)
as
select
  c.id,
  c.catalog_code,
  c.version_number,
  c.name,
  c.description,
  c.purpose,
  c.formula_text,
  c.unit,
  c.polarity,
  c.measurement_frequency,
  c.indicator_category,
  c.applicability,
  c.excellence_criteria,
  c.reference_sources,
  c.status,
  c.is_current,
  c.metadata,
  c.created_at,
  c.created_by,
  c.updated_at,
  c.updated_by
from public.skpe_indicator_reference_catalog c;

create or replace view public.sparks_measure_reference_benchmarks
with (security_invoker = true)
as
select
  b.id,
  b.reference_indicator_id,
  b.benchmark_type,
  b.source_name,
  b.source_reference,
  b.reference_period,
  b.population_context,
  b.benchmark_value,
  b.lower_bound,
  b.upper_bound,
  b.applicability,
  b.comparability_notes,
  b.confidence_level,
  b.verified_at,
  b.verified_by,
  b.status,
  b.metadata,
  b.created_at,
  b.created_by,
  b.updated_at,
  b.updated_by
from public.skpe_indicator_reference_benchmarks b;

create or replace view public.sparks_performance_snapshots
with (security_invoker = true)
as
select
  s.id,
  s.organization_id,
  s.project_id as source_project_id,
  s.formulation_id as source_context_id,
  'SK-PE'::text as source_module_code,
  'strategic_formulation'::text as context_type,
  s.monitoring_cycle_id as source_cycle_id,
  s.snapshot_version,
  s.status,
  s.calculation_policy,
  s.payload,
  s.checksum_sha256,
  s.generated_at,
  s.generated_by,
  s.ratified_at,
  s.ratified_by
from public.skpe_performance_snapshots s;

comment on view public.sparks_measure_indicators is 'Transversal read facade for measures and performance. Physical authority remains SK-PE during convergence.';
comment on view public.sparks_measure_targets is 'Transversal read facade for targets. Targets are organizational decisions and are distinct from benchmarks.';
comment on view public.sparks_measure_benchmarks is 'Transversal read facade for contextual benchmark references. Benchmarks are references, not targets.';
comment on view public.sparks_measure_measurements is 'Transversal read facade for historical measurement series. Measurements are not duplicated by consuming modules.';
comment on view public.sparks_measure_reference_catalog is 'Transversal read facade for reusable indicator references.';
comment on view public.sparks_measure_reference_benchmarks is 'Transversal read facade for benchmark references attached to reusable indicator definitions.';
comment on view public.sparks_performance_snapshots is 'Transversal read facade for governed performance snapshots.';

grant select on public.sparks_measure_indicators to authenticated;
grant select on public.sparks_measure_targets to authenticated;
grant select on public.sparks_measure_benchmarks to authenticated;
grant select on public.sparks_measure_measurements to authenticated;
grant select on public.sparks_measure_reference_catalog to authenticated;
grant select on public.sparks_measure_reference_benchmarks to authenticated;
grant select on public.sparks_performance_snapshots to authenticated;
