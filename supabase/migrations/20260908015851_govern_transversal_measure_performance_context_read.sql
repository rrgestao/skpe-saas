create or replace function public.get_sparks_measure_performance_context(
  target_organization_id uuid,
  target_source_module_code text,
  target_source_project_id uuid default null,
  target_source_context_id uuid default null,
  target_subject_type text default null,
  target_subject_id uuid default null
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
  code text,
  name text,
  description text,
  unit text,
  polarity text,
  measurement_frequency text,
  data_source text,
  baseline_value numeric,
  baseline_date date,
  indicator_status text,
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
  measurement_id uuid,
  measurement_date date,
  measurement_period_start date,
  measurement_period_end date,
  measured_value numeric,
  automatic_performance numeric,
  manual_performance_override numeric,
  effective_performance numeric,
  measurement_status text,
  data_quality text,
  measurement_source_name text,
  measurement_source_reference text,
  evidence_reference text,
  measurement_state text,
  benchmark_id uuid,
  benchmark_type text,
  benchmark_value numeric,
  benchmark_reference_organization text,
  benchmark_source_name text,
  benchmark_source_reference text,
  benchmark_reference_period text,
  benchmark_status text,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  normalized_module_code text := upper(trim(coalesce(target_source_module_code, '')));
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.' using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.' using errcode = '22023';
  end if;

  if normalized_module_code = '' then
    raise exception 'Informe o módulo de origem.' using errcode = '22023';
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
      and public.has_module_access(target_organization_id, normalized_module_code)
    )
  ) then
    raise exception 'Acesso negado: o usuário não pode consultar Medidas e Desempenho neste contexto.'
      using errcode = '42501';
  end if;

  return query
  select
    indicator.id as indicator_id,
    indicator.organization_id,
    indicator.source_module_code,
    indicator.context_type,
    indicator.source_project_id,
    indicator.source_context_id,
    indicator.subject_type,
    indicator.subject_id,
    indicator.code,
    indicator.name,
    indicator.description,
    indicator.unit,
    indicator.polarity,
    indicator.measurement_frequency,
    indicator.data_source,
    indicator.baseline_value,
    indicator.baseline_date,
    indicator.status as indicator_status,
    target.id as target_id,
    target.target_type,
    target.target_value,
    target.minimum_value,
    target.challenge_value,
    target.tolerance_lower,
    target.tolerance_upper,
    target.period_start as target_period_start,
    target.period_end as target_period_end,
    target.status as target_status,
    measurement.id as measurement_id,
    measurement.measurement_date,
    measurement.period_start as measurement_period_start,
    measurement.period_end as measurement_period_end,
    measurement.measured_value,
    measurement.automatic_performance,
    measurement.manual_performance_override,
    measurement.effective_performance,
    measurement.status as measurement_status,
    measurement.data_quality,
    measurement.source_name as measurement_source_name,
    measurement.source_reference as measurement_source_reference,
    measurement.evidence_reference,
    case
      when measurement.id is null then 'not_assessed'::text
      else coalesce(nullif(trim(measurement.status), ''), 'assessed')
    end as measurement_state,
    benchmark.id as benchmark_id,
    benchmark.benchmark_type,
    benchmark.benchmark_value,
    benchmark.reference_organization as benchmark_reference_organization,
    benchmark.source_name as benchmark_source_name,
    benchmark.source_reference as benchmark_source_reference,
    benchmark.reference_period as benchmark_reference_period,
    benchmark.status as benchmark_status,
    greatest(
      indicator.updated_at,
      coalesce(target.updated_at, indicator.updated_at),
      coalesce(measurement.created_at, indicator.updated_at),
      coalesce(benchmark.updated_at, indicator.updated_at)
    ) as updated_at
  from public.sparks_measure_indicators indicator
  left join lateral (
    select candidate.*
    from public.sparks_measure_targets candidate
    where candidate.organization_id = indicator.organization_id
      and candidate.source_module_code = indicator.source_module_code
      and candidate.indicator_id = indicator.id
      and (candidate.status is null or candidate.status <> 'superseded')
    order by
      case
        when candidate.period_start <= current_date and candidate.period_end >= current_date then 0
        when candidate.period_end >= current_date then 1
        else 2
      end,
      candidate.period_end desc nulls last,
      candidate.updated_at desc
    limit 1
  ) target on true
  left join lateral (
    select candidate.*
    from public.sparks_measure_measurements candidate
    where candidate.organization_id = indicator.organization_id
      and candidate.source_module_code = indicator.source_module_code
      and candidate.indicator_id = indicator.id
    order by
      candidate.measurement_date desc nulls last,
      candidate.created_at desc
    limit 1
  ) measurement on true
  left join lateral (
    select candidate.*
    from public.sparks_measure_benchmarks candidate
    where candidate.organization_id = indicator.organization_id
      and candidate.source_module_code = indicator.source_module_code
      and candidate.indicator_id = indicator.id
    order by
      candidate.verified_at desc nulls last,
      candidate.updated_at desc
    limit 1
  ) benchmark on true
  where indicator.organization_id = target_organization_id
    and upper(trim(indicator.source_module_code)) = normalized_module_code
    and (target_source_project_id is null or indicator.source_project_id = target_source_project_id)
    and (target_source_context_id is null or indicator.source_context_id = target_source_context_id)
    and (target_subject_type is null or indicator.subject_type = target_subject_type)
    and (target_subject_id is null or indicator.subject_id = target_subject_id)
    and (indicator.status is null or indicator.status <> 'archived')
  order by indicator.code, indicator.name;
end;
$function$;

revoke all on function public.get_sparks_measure_performance_context(uuid, text, uuid, uuid, text, uuid) from public;
revoke all on function public.get_sparks_measure_performance_context(uuid, text, uuid, uuid, text, uuid) from anon;
grant execute on function public.get_sparks_measure_performance_context(uuid, text, uuid, uuid, text, uuid) to authenticated;

comment on function public.get_sparks_measure_performance_context(uuid, text, uuid, uuid, text, uuid) is
'Leitura transversal governada de Medidas e Desempenho por organização, módulo, projeto/contexto e sujeito. Retorna indicador, meta aplicável, última apuração e benchmark mais recente sem converter ausência de apuração em zero.';
