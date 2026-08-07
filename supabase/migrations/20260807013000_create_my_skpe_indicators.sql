begin;

-- ============================================================
-- FE-09.A.08 — MEUS INDICADORES
-- Consulta pessoal e somente leitura de Indicadores Estratégicos.
-- ============================================================

create or replace function public.get_my_skpe_indicators(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_formulation_id uuid default null
)
returns table (
  indicator_id uuid,
  organization_id uuid,
  project_id uuid,
  formulation_id uuid,
  strategic_objective_id uuid,
  strategic_objective_code text,
  strategic_objective_name text,
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
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  if target_organization_id is null then
    raise exception 'Informe a organização.'
      using errcode = '22023';
  end if;

  if not (
    public.is_active_member(target_organization_id)
    and public.has_module_access(target_organization_id, 'SK-PE')
  ) then
    raise exception
      'Acesso negado: o usuário não pode consultar indicadores do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    indicator.id as indicator_id,
    indicator.organization_id,
    indicator.project_id,
    indicator.formulation_id,
    indicator.strategic_objective_id,
    objective.code as strategic_objective_code,
    objective.name as strategic_objective_name,
    indicator.code,
    indicator.name,
    indicator.description,
    indicator.unit,
    indicator.polarity,
    indicator.measurement_frequency,
    indicator.data_source,
    indicator.baseline_value,
    indicator.baseline_date,
    indicator.status,
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
    indicator.updated_at
  from public.skpe_indicators indicator
  join public.skpe_strategic_objectives objective
    on objective.id = indicator.strategic_objective_id
  left join lateral (
    select candidate.*
    from public.skpe_indicator_targets candidate
    where candidate.indicator_id = indicator.id
      and candidate.formulation_id = indicator.formulation_id
      and candidate.status <> 'superseded'
    order by
      case
        when candidate.period_start <= current_date
          and candidate.period_end >= current_date
          then 0
        when candidate.period_end >= current_date
          then 1
        else 2
      end,
      candidate.period_end desc,
      candidate.updated_at desc
    limit 1
  ) target on true
  where indicator.organization_id = target_organization_id
    and indicator.owner_user_id = current_user_id
    and indicator.indicator_scope = 'strategic_kpi'
    and indicator.status <> 'archived'
    and objective.status = 'active'
    and (
      target_project_id is null
      or indicator.project_id = target_project_id
    )
    and (
      target_formulation_id is null
      or indicator.formulation_id = target_formulation_id
    )
  order by
    objective.code,
    indicator.code,
    indicator.name;
end;
$$;

comment on function public.get_my_skpe_indicators(uuid, uuid, uuid) is
  'FE-09.A.08: consulta somente leitura dos Indicadores Estratégicos atribuídos ao usuário autenticado, respeitando organização, projeto e Formulação.';

revoke all on function public.get_my_skpe_indicators(uuid, uuid, uuid)
from public, anon;

grant execute on function public.get_my_skpe_indicators(uuid, uuid, uuid)
to authenticated, service_role;

commit;
