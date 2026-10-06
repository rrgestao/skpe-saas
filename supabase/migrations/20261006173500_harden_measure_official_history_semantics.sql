-- Harden measure history official-trend semantics.
-- All current observations remain visible, but only validated observations count as official trend points.

create or replace function public.get_sparks_measure_indicator_history(
  target_organization_id uuid,
  target_source_module_code text,
  target_indicator_id uuid,
  target_limit integer default 24
)
returns table(
  measurement_id uuid,
  indicator_id uuid,
  organization_id uuid,
  source_module_code text,
  source_project_id uuid,
  source_context_id uuid,
  source_cycle_id uuid,
  indicator_target_id uuid,
  measurement_date date,
  period_start date,
  period_end date,
  measured_value numeric,
  automatic_performance numeric,
  manual_performance_override numeric,
  effective_performance numeric,
  measurement_status text,
  data_quality text,
  source_name text,
  source_reference text,
  evidence_reference text,
  notes text,
  validated_at timestamptz,
  validated_by uuid,
  created_at timestamptz,
  created_by uuid,
  observation_order integer,
  valid_observation_count integer,
  trend_eligible boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  normalized_module_code text := upper(trim(coalesce(target_source_module_code, '')));
  normalized_limit integer := greatest(1, least(coalesce(target_limit, 24), 120));
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.' using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.' using errcode = '22023';
  end if;

  if target_indicator_id is null then
    raise exception 'Informe o indicador.' using errcode = '22023';
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
    raise exception
      'Acesso negado: o usuário não pode consultar o histórico de Medidas e Desempenho neste contexto.'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.sparks_measure_indicators indicator
    where indicator.id = target_indicator_id
      and indicator.organization_id = target_organization_id
      and upper(trim(indicator.source_module_code)) = normalized_module_code
      and (indicator.status is null or indicator.status <> 'archived')
  ) then
    raise exception
      'Indicador não encontrado no contexto informado.'
      using errcode = '22023';
  end if;

  return query
  with current_measurements as (
    select measurement.*
    from public.sparks_measure_measurements measurement
    where measurement.organization_id = target_organization_id
      and upper(trim(measurement.source_module_code)) = normalized_module_code
      and measurement.indicator_id = target_indicator_id
      and not exists (
        select 1
        from public.sparks_measure_measurements successor
        where successor.supersedes_measurement_id = measurement.id
          and successor.organization_id = measurement.organization_id
          and successor.indicator_id = measurement.indicator_id
      )
  ),
  ordered as (
    select
      measurement.*,
      row_number() over (
        order by
          measurement.measurement_date asc nulls last,
          measurement.period_end asc nulls last,
          measurement.created_at asc,
          measurement.id asc
      )::integer as observation_order,
      count(*) filter (
        where measurement.status = 'validated'
          and measurement.measured_value is not null
      ) over ()::integer as valid_observation_count
    from current_measurements measurement
  )
  select
    ordered.id as measurement_id,
    ordered.indicator_id,
    ordered.organization_id,
    ordered.source_module_code,
    ordered.source_project_id,
    ordered.source_context_id,
    ordered.source_cycle_id,
    ordered.indicator_target_id,
    ordered.measurement_date,
    ordered.period_start,
    ordered.period_end,
    ordered.measured_value,
    ordered.automatic_performance,
    ordered.manual_performance_override,
    ordered.effective_performance,
    ordered.status as measurement_status,
    ordered.data_quality,
    ordered.source_name,
    ordered.source_reference,
    ordered.evidence_reference,
    ordered.notes,
    ordered.validated_at,
    ordered.validated_by,
    ordered.created_at,
    ordered.created_by,
    ordered.observation_order,
    ordered.valid_observation_count,
    (ordered.valid_observation_count >= 3) as trend_eligible
  from ordered
  order by
    ordered.measurement_date desc nulls last,
    ordered.period_end desc nulls last,
    ordered.created_at desc,
    ordered.id desc
  limit normalized_limit;
end;
$function$;

revoke all on function public.get_sparks_measure_indicator_history(uuid,text,uuid,integer)
from public, anon;

grant execute on function public.get_sparks_measure_indicator_history(uuid,text,uuid,integer)
to authenticated, service_role;

comment on function public.get_sparks_measure_indicator_history(uuid,text,uuid,integer) is
'Returns current measurement history for transparency, but valid_observation_count/trend_eligible count only validated non-null observations. Nonvalidated observations remain visible and must not be presented as official trend points.';
