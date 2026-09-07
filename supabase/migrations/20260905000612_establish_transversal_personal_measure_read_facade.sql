create or replace function public.get_my_sparks_measure_indicators(
  target_organization_id uuid,
  target_source_module_code text default 'SK-PE',
  target_source_project_id uuid default null,
  target_source_context_id uuid default null
)
returns table(
  indicator_id uuid,
  organization_id uuid,
  source_module_code text,
  context_type text,
  source_project_id uuid,
  source_context_id uuid,
  subject_type text,
  subject_id uuid,
  subject_code text,
  subject_name text,
  code text,
  name text,
  description text,
  unit text,
  polarity text,
  measurement_frequency text,
  data_source text,
  baseline_value numeric,
  baseline_date date,
  status text,
  target_id uuid,
  target_type text,
  target_value numeric,
  minimum_value numeric,
  challenge_value numeric,
  tolerance_lower numeric,
  tolerance_upper numeric,
  target_period_start date,
  target_period_end date,
  target_status text,
  updated_at timestamptz
)
language plpgsql
stable
security invoker
set search_path to ''
as $function$
begin
  if upper(trim(coalesce(target_source_module_code, ''))) <> 'SK-PE' then
    raise exception 'A leitura pessoal transversal ainda não possui adaptador para o módulo informado.' using errcode = '0A000';
  end if;

  return query
  select
    source.indicator_id,
    source.organization_id,
    'SK-PE'::text as source_module_code,
    'strategic_formulation'::text as context_type,
    source.project_id as source_project_id,
    source.formulation_id as source_context_id,
    'strategic_objective'::text as subject_type,
    source.strategic_objective_id as subject_id,
    source.strategic_objective_code as subject_code,
    source.strategic_objective_name as subject_name,
    source.code,
    source.name,
    source.description,
    source.unit,
    source.polarity,
    source.measurement_frequency,
    source.data_source,
    source.baseline_value,
    source.baseline_date,
    source.status,
    source.target_id,
    source.target_type,
    source.target_value,
    source.minimum_value,
    source.challenge_value,
    source.tolerance_lower,
    source.tolerance_upper,
    source.target_period_start,
    source.target_period_end,
    source.target_status,
    source.updated_at
  from public.get_my_skpe_indicators(
    target_organization_id,
    target_source_project_id,
    target_source_context_id
  ) source;
end;
$function$;

comment on function public.get_my_sparks_measure_indicators(uuid,text,uuid,uuid)
is 'Transversal personal read facade for measures. Current adapter serves SK-PE and fails closed for unsupported modules.';

grant execute on function public.get_my_sparks_measure_indicators(uuid,text,uuid,uuid) to authenticated;
