create or replace function public.sparks_upsert_measure_indicator(
  p_source_module_code text,
  p_context_type text,
  p_source_context_id uuid,
  p_subject_type text,
  p_subject_id uuid,
  p_code text,
  p_name text,
  p_description text,
  p_formula_text text,
  p_calculation_method text,
  p_unit text,
  p_polarity text,
  p_measurement_frequency text,
  p_data_source text,
  p_baseline_value numeric,
  p_baseline_date date,
  p_owner_user_id uuid,
  p_indicator_category text,
  p_collection_method text,
  p_collection_automatable boolean,
  p_responsible_area text,
  p_baseline_required_override boolean,
  p_status text,
  p_indicator_id uuid,
  p_metadata jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security invoker
set search_path to ''
as $function$
begin
  if upper(trim(coalesce(p_source_module_code, ''))) <> 'SK-PE'
     or lower(trim(coalesce(p_context_type, ''))) <> 'strategic_formulation' then
    raise exception 'A fachada transversal ainda não possui adaptador de escrita para o módulo/contexto informado.' using errcode = '0A000';
  end if;

  if lower(trim(coalesce(p_subject_type, ''))) <> 'strategic_objective' then
    raise exception 'O adaptador SK-PE atual de indicador suporta somente strategic_objective; outros sujeitos exigem adaptador específico.' using errcode = '0A000';
  end if;

  return public.upsert_skpe_strategic_indicator(
    p_source_context_id,
    p_code,
    p_name,
    p_description,
    p_subject_id,
    p_formula_text,
    p_calculation_method,
    p_unit,
    p_polarity,
    p_measurement_frequency,
    p_data_source,
    p_baseline_value,
    p_baseline_date,
    p_owner_user_id,
    p_indicator_category,
    p_collection_method,
    p_collection_automatable,
    p_responsible_area,
    p_baseline_required_override,
    p_status,
    p_indicator_id,
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'transversal_measure_facade', true,
      'source_module_code', upper(trim(p_source_module_code)),
      'context_type', lower(trim(p_context_type)),
      'subject_type', lower(trim(p_subject_type))
    ),
    p_change_reason
  );
end;
$function$;

create or replace function public.sparks_upsert_measure_target(
  p_indicator_id uuid,
  p_target_type text,
  p_period_start date,
  p_period_end date,
  p_target_value numeric,
  p_minimum_value numeric,
  p_challenge_value numeric,
  p_tolerance_lower numeric,
  p_tolerance_upper numeric,
  p_owner_user_id uuid,
  p_status text,
  p_target_id uuid,
  p_metadata jsonb,
  p_change_reason text
)
returns uuid
language sql
security invoker
set search_path to ''
as $function$
  select public.upsert_skpe_indicator_target(
    p_indicator_id,
    p_target_type,
    p_period_start,
    p_period_end,
    p_target_value,
    p_minimum_value,
    p_challenge_value,
    p_tolerance_lower,
    p_tolerance_upper,
    p_owner_user_id,
    p_status,
    p_target_id,
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object('transversal_measure_facade', true),
    p_change_reason
  );
$function$;

create or replace function public.sparks_supersede_measure_target(
  p_target_id uuid,
  p_change_reason text
)
returns uuid
language sql
security invoker
set search_path to ''
as $function$
  select public.supersede_skpe_indicator_target(p_target_id, p_change_reason);
$function$;

create or replace function public.sparks_upsert_measure_benchmark(
  p_indicator_id uuid,
  p_benchmark_type text,
  p_reference_organization text,
  p_source_name text,
  p_source_reference text,
  p_reference_period text,
  p_benchmark_value numeric,
  p_applicability text,
  p_gap_analysis text,
  p_notes text,
  p_indicator_target_id uuid,
  p_benchmark_id uuid,
  p_metadata jsonb,
  p_change_reason text
)
returns uuid
language sql
security invoker
set search_path to ''
as $function$
  select public.upsert_skpe_benchmark_reference(
    p_indicator_id,
    p_benchmark_type,
    p_reference_organization,
    p_source_name,
    p_source_reference,
    p_reference_period,
    p_benchmark_value,
    p_applicability,
    p_gap_analysis,
    p_notes,
    p_indicator_target_id,
    p_benchmark_id,
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object('transversal_measure_facade', true),
    p_change_reason
  );
$function$;

create or replace function public.sparks_transition_measure_benchmark(
  p_benchmark_id uuid,
  p_transition_action text,
  p_decision_notes text,
  p_change_reason text
)
returns jsonb
language sql
security invoker
set search_path to ''
as $function$
  select public.transition_skpe_benchmark_reference(
    p_benchmark_id,
    p_transition_action,
    p_decision_notes,
    p_change_reason
  );
$function$;

create or replace function public.sparks_record_measurement(
  p_source_cycle_id uuid,
  p_indicator_id uuid,
  p_measured_value numeric,
  p_payload jsonb,
  p_change_reason text
)
returns uuid
language sql
security invoker
set search_path to ''
as $function$
  select public.record_skpe_indicator_measurement(
    p_source_cycle_id,
    p_indicator_id,
    p_measured_value,
    coalesce(p_payload, '{}'::jsonb) || jsonb_build_object('transversal_measure_facade', true),
    p_change_reason
  );
$function$;

comment on function public.sparks_upsert_measure_indicator(text,text,uuid,text,uuid,text,text,text,text,text,text,text,text,text,numeric,date,uuid,text,text,boolean,text,boolean,text,uuid,jsonb,text)
is 'Transversal write facade for measures. Current physical adapter supports SK-PE strategic objectives only; unsupported modules/subjects fail closed.';
comment on function public.sparks_upsert_measure_target(uuid,text,date,date,numeric,numeric,numeric,numeric,numeric,uuid,text,uuid,jsonb,text)
is 'Transversal target write facade. Target remains distinct from benchmark.';
comment on function public.sparks_upsert_measure_benchmark(uuid,text,text,text,text,text,numeric,text,text,text,uuid,uuid,jsonb,text)
is 'Transversal benchmark write facade. Benchmark is a reference and not an organizational target.';
comment on function public.sparks_record_measurement(uuid,uuid,numeric,jsonb,text)
is 'Transversal measurement write facade over the current SK-PE physical authority.';

grant execute on function public.sparks_upsert_measure_indicator(text,text,uuid,text,uuid,text,text,text,text,text,text,text,text,text,numeric,date,uuid,text,text,boolean,text,boolean,text,uuid,jsonb,text) to authenticated;
grant execute on function public.sparks_upsert_measure_target(uuid,text,date,date,numeric,numeric,numeric,numeric,numeric,uuid,text,uuid,jsonb,text) to authenticated;
grant execute on function public.sparks_supersede_measure_target(uuid,text) to authenticated;
grant execute on function public.sparks_upsert_measure_benchmark(uuid,text,text,text,text,text,numeric,text,text,text,uuid,uuid,jsonb,text) to authenticated;
grant execute on function public.sparks_transition_measure_benchmark(uuid,text,text,text) to authenticated;
grant execute on function public.sparks_record_measurement(uuid,uuid,numeric,jsonb,text) to authenticated;
