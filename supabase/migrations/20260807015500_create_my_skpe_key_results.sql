begin;

-- ============================================================
-- FE-09.A.09 — MEUS KRs
-- Consulta pessoal e somente leitura de Resultados-Chave.
-- ============================================================

create or replace function public.get_my_skpe_key_results(
  target_organization_id uuid,
  target_project_id uuid default null,
  target_formulation_id uuid default null
)
returns table (
  key_result_id uuid,
  organization_id uuid,
  project_id uuid,
  formulation_id uuid,
  okr_id uuid,
  okr_code text,
  okr_title text,
  strategic_objective_id uuid,
  strategic_objective_code text,
  strategic_objective_name text,
  code text,
  name text,
  description text,
  baseline_value numeric,
  current_value numeric,
  target_value numeric,
  unit text,
  progress numeric,
  period_start date,
  period_end date,
  status text,
  validation_status text,
  contribution_weight numeric,
  polarity text,
  measurement_frequency text,
  data_source text,
  formula_text text,
  calculation_method text,
  range_lower numeric,
  range_upper numeric,
  collection_automatable boolean,
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
      'Acesso negado: o usuário não pode consultar Resultados-Chave do SK-PE nesta organização.'
      using errcode = '42501';
  end if;

  return query
  select
    kr.id as key_result_id,
    kr.organization_id,
    kr.project_id,
    kr.formulation_id,
    kr.okr_id,
    okr.code as okr_code,
    okr.title as okr_title,
    kr.strategic_objective_id,
    objective.code as strategic_objective_code,
    objective.name as strategic_objective_name,
    kr.code,
    kr.name,
    kr.description,
    kr.baseline_value,
    kr.current_value,
    kr.target_value,
    kr.unit,
    kr.progress,
    kr.period_start,
    kr.period_end,
    kr.status,
    kr.validation_status,
    kr.contribution_weight,
    nullif(kr.metadata ->> 'polarity', '') as polarity,
    nullif(kr.metadata ->> 'measurementFrequency', '') as measurement_frequency,
    nullif(kr.metadata ->> 'dataSource', '') as data_source,
    nullif(kr.metadata ->> 'formulaText', '') as formula_text,
    nullif(kr.metadata ->> 'calculationMethod', '') as calculation_method,
    nullif(kr.metadata ->> 'rangeLower', '')::numeric as range_lower,
    nullif(kr.metadata ->> 'rangeUpper', '')::numeric as range_upper,
    nullif(kr.metadata ->> 'collectionAutomatable', '')::boolean
      as collection_automatable,
    kr.updated_at
  from public.skpe_key_results kr
  join public.skpe_okrs okr
    on okr.id = kr.okr_id
  join public.skpe_strategic_objectives objective
    on objective.id = kr.strategic_objective_id
  where kr.organization_id = target_organization_id
    and kr.owner_user_id = current_user_id
    and kr.status <> 'cancelled'
    and okr.status <> 'cancelled'
    and (
      target_project_id is null
      or kr.project_id = target_project_id
    )
    and (
      target_formulation_id is null
      or kr.formulation_id = target_formulation_id
    )
  order by
    case kr.status
      when 'at_risk' then 0
      when 'active' then 1
      when 'draft' then 2
      when 'not_achieved' then 3
      when 'achieved' then 4
      else 5
    end,
    kr.period_end,
    okr.code,
    kr.code,
    kr.name;
end;
$$;

comment on function public.get_my_skpe_key_results(uuid, uuid, uuid) is
  'FE-09.A.09: consulta somente leitura dos Resultados-Chave atribuídos ao usuário autenticado, respeitando organização, projeto e Formulação.';

revoke all on function public.get_my_skpe_key_results(uuid, uuid, uuid)
from public, anon;

grant execute on function public.get_my_skpe_key_results(uuid, uuid, uuid)
to authenticated, service_role;

commit;
