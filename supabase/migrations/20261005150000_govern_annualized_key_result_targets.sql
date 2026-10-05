-- Govern annualized Key Result targets for the SK-PE strategic deployment.
-- This adds a year-by-year trajectory without confusing annual targets with Evolution Cycles.
-- 2026 may be a transition/baseline-confirmation year for in-flight implementations.

create table if not exists public.skpe_key_result_annual_targets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  formulation_id uuid not null references public.skpe_strategic_formulations(id) on delete restrict,
  key_result_id uuid not null references public.skpe_key_results(id) on delete cascade,
  target_year integer not null,
  target_type text not null default 'annual',
  target_expression text not null,
  target_value numeric null,
  comparator text null,
  unit text null,
  status text not null default 'draft',
  validation_status text not null default 'draft',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc',now()),
  created_by uuid null references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc',now()),
  updated_by uuid null references public.profiles(id) on delete set null,
  constraint skpe_key_result_annual_targets_year_check
    check (target_year between 2000 and 2100),
  constraint skpe_key_result_annual_targets_type_check
    check (target_type in ('transition','baseline_confirmation','annual')),
  constraint skpe_key_result_annual_targets_expression_check
    check (length(trim(target_expression)) > 0),
  constraint skpe_key_result_annual_targets_comparator_check
    check (comparator is null or comparator in ('eq','gte','gt','lte','lt','range','textual')),
  constraint skpe_key_result_annual_targets_status_check
    check (status in ('draft','active','superseded')),
  constraint skpe_key_result_annual_targets_validation_check
    check (validation_status in ('draft','pending_validation','validated','rejected')),
  constraint skpe_key_result_annual_targets_unique
    unique (key_result_id,target_year)
);

create index if not exists skpe_key_result_annual_targets_scope_idx
  on public.skpe_key_result_annual_targets(organization_id,project_id,formulation_id,target_year);

alter table public.skpe_key_result_annual_targets enable row level security;

drop policy if exists skpe_key_result_annual_targets_select
  on public.skpe_key_result_annual_targets;
create policy skpe_key_result_annual_targets_select
  on public.skpe_key_result_annual_targets
  for select
  to authenticated
  using (public.can_view_skpe_formulation(organization_id));

revoke all on table public.skpe_key_result_annual_targets from public,anon;
grant select on table public.skpe_key_result_annual_targets to authenticated,service_role;

create or replace function public.upsert_skpe_key_result_annual_target(
  p_key_result_id uuid,
  p_target_year integer,
  p_target_type text,
  p_target_expression text,
  p_target_value numeric,
  p_comparator text,
  p_unit text,
  p_target_id uuid,
  p_metadata jsonb,
  p_change_reason text
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  kr public.skpe_key_results%rowtype;
  project_row public.skpe_projects%rowtype;
  target_id uuid;
  existing public.skpe_key_result_annual_targets%rowtype;
  normalized_type text;
  normalized_expression text;
  normalized_comparator text;
  previous_data jsonb;
  new_data jsonb;
begin
  if auth.uid() is null then
    raise exception using errcode='42501',message='Usuário não autenticado.';
  end if;

  perform public.skpe_assert_reason(p_change_reason);

  select * into kr
  from public.skpe_key_results
  where id=p_key_result_id;

  if kr.id is null then
    raise exception using errcode='22023',message='Resultado-Chave não encontrado.';
  end if;

  if not public.can_manage_skpe_formulation(kr.organization_id) then
    raise exception using errcode='42501',message='Acesso negado para editar metas anualizadas do Resultado-Chave.';
  end if;

  select * into project_row
  from public.skpe_projects
  where id=kr.project_id;

  if p_target_year is null
     or p_target_year < coalesce(project_row.planning_horizon_start_year,2000)
     or p_target_year > coalesce(project_row.planning_horizon_end_year,2100) then
    raise exception using errcode='22023',
      message='O ano da meta deve estar dentro do Horizonte Estratégico do projeto.';
  end if;

  normalized_type:=lower(trim(coalesce(p_target_type,'annual')));
  if normalized_type not in ('transition','baseline_confirmation','annual') then
    raise exception using errcode='22023',message='Tipo de meta anual inválido.';
  end if;

  normalized_expression:=trim(coalesce(p_target_expression,''));
  if length(normalized_expression)=0 then
    raise exception using errcode='22023',message='Informe a expressão da meta anual.';
  end if;

  normalized_comparator:=nullif(lower(trim(coalesce(p_comparator,''))),'');
  if normalized_comparator is not null
     and normalized_comparator not in ('eq','gte','gt','lte','lt','range','textual') then
    raise exception using errcode='22023',message='Comparador da meta anual inválido.';
  end if;

  if normalized_type='annual'
     and p_target_year > coalesce(project_row.planning_horizon_start_year,p_target_year)
     and p_target_value is null
     and coalesce(normalized_comparator,'textual')<>'textual' then
    raise exception using errcode='22023',
      message='Meta anual numérica exige valor quando o comparador não é textual.';
  end if;

  if p_target_id is not null then
    select * into existing
    from public.skpe_key_result_annual_targets
    where id=p_target_id
      and key_result_id=kr.id
    for update;

    if existing.id is null then
      raise exception using errcode='22023',message='Meta anual do Resultado-Chave não encontrada.';
    end if;
    target_id:=existing.id;
    previous_data:=to_jsonb(existing);

    update public.skpe_key_result_annual_targets
    set target_year=p_target_year,
        target_type=normalized_type,
        target_expression=normalized_expression,
        target_value=p_target_value,
        comparator=normalized_comparator,
        unit=nullif(trim(coalesce(p_unit,'')),''),
        status='draft',
        validation_status='draft',
        metadata=coalesce(p_metadata,'{}'::jsonb)
          || jsonb_build_object(
            'proposalOnly',true,
            'humanValidationRequired',true,
            'annualizedKrTarget',true
          ),
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=target_id
    returning to_jsonb(skpe_key_result_annual_targets) into new_data;
  else
    insert into public.skpe_key_result_annual_targets(
      organization_id,project_id,formulation_id,key_result_id,
      target_year,target_type,target_expression,target_value,comparator,unit,
      status,validation_status,metadata,created_by,updated_by
    )
    values(
      kr.organization_id,kr.project_id,kr.formulation_id,kr.id,
      p_target_year,normalized_type,normalized_expression,p_target_value,normalized_comparator,
      nullif(trim(coalesce(p_unit,'')),''),
      'draft','draft',
      coalesce(p_metadata,'{}'::jsonb)
        || jsonb_build_object(
          'proposalOnly',true,
          'humanValidationRequired',true,
          'annualizedKrTarget',true
        ),
      auth.uid(),auth.uid()
    )
    on conflict (key_result_id,target_year) do update
    set target_type=excluded.target_type,
        target_expression=excluded.target_expression,
        target_value=excluded.target_value,
        comparator=excluded.comparator,
        unit=excluded.unit,
        status='draft',
        validation_status='draft',
        metadata=excluded.metadata,
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    returning id,to_jsonb(skpe_key_result_annual_targets) into target_id,new_data;
  end if;

  perform public.skpe_record_operational_audit(
    kr.organization_id,kr.project_id,
    'key_result_annual_target',target_id,
    case when previous_data is null then 'key_result_annual_target_created'
         else 'key_result_annual_target_updated' end,
    p_change_reason,previous_data,new_data
  );

  return target_id;
end;
$function$;

revoke all on function public.upsert_skpe_key_result_annual_target(
  uuid,integer,text,text,numeric,text,text,uuid,jsonb,text
) from public,anon;
grant execute on function public.upsert_skpe_key_result_annual_target(
  uuid,integer,text,text,numeric,text,text,uuid,jsonb,text
) to authenticated,service_role;

create or replace function public.get_skpe_key_result_annual_target_readiness(
  p_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  f public.skpe_strategic_formulations%rowtype;
  p public.skpe_projects%rowtype;
  start_year integer;
  end_year integer;
  expected_full_year_start integer;
  active_kr_count integer;
  expected_annual_count integer;
  present_annual_count integer;
  missing_annual_count integer;
  invalid_2026_count integer;
  issues jsonb := '[]'::jsonb;
begin
  select * into f
  from public.skpe_strategic_formulations
  where id=p_formulation_id;

  if f.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(f.organization_id) then
    raise exception using errcode='42501',message='Acesso negado às metas anualizadas dos Resultados-Chave.';
  end if;

  select * into p
  from public.skpe_projects
  where id=f.project_id;

  start_year:=coalesce(p.planning_horizon_start_year,extract(year from f.valid_from)::integer);
  end_year:=coalesce(p.planning_horizon_end_year,extract(year from f.valid_until)::integer);

  -- For a plan introduced late in 2026, 2026 may serve as transition/baseline confirmation.
  -- The first complete performance year is 2027. This is methodology, not a fabricated target.
  expected_full_year_start:=case when start_year=2026 then 2027 else start_year end;

  select count(*) into active_kr_count
  from public.skpe_key_results kr
  where kr.formulation_id=p_formulation_id
    and kr.status<>'cancelled';

  if active_kr_count=0 or start_year is null or end_year is null then
    return jsonb_build_object(
      'formulationId',p_formulation_id,
      'readyForValidation',false,
      'blockingIssueCount',1,
      'expectedFullYearStart',expected_full_year_start,
      'issues',jsonb_build_array(jsonb_build_object(
        'code','KR_ANNUAL_TARGET_CONTEXT_INCOMPLETE',
        'severity','blocking',
        'message','Defina o Horizonte Estratégico e os Resultados-Chave antes de consolidar metas anualizadas.'
      ))
    );
  end if;

  expected_annual_count:=active_kr_count * greatest(end_year-expected_full_year_start+1,0);

  select count(*) into present_annual_count
  from public.skpe_key_result_annual_targets t
  join public.skpe_key_results kr on kr.id=t.key_result_id
  where t.formulation_id=p_formulation_id
    and kr.status<>'cancelled'
    and t.target_year between expected_full_year_start and end_year
    and t.target_type='annual'
    and t.status<>'superseded'
    and length(trim(t.target_expression))>0;

  missing_annual_count:=greatest(expected_annual_count-present_annual_count,0);

  if missing_annual_count>0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','KR_ANNUAL_TARGET_TRAJECTORY_INCOMPLETE',
      'severity','blocking',
      'message','Existem Resultados-Chave sem trajetória anual completa de metas para os exercícios integrais do Horizonte.',
      'affectedCount',missing_annual_count
    ));
  end if;

  if start_year=2026 then
    select count(*) into invalid_2026_count
    from public.skpe_key_result_annual_targets t
    join public.skpe_key_results kr on kr.id=t.key_result_id
    where t.formulation_id=p_formulation_id
      and kr.status<>'cancelled'
      and t.target_year=2026
      and t.status<>'superseded'
      and t.target_type not in ('transition','baseline_confirmation','annual');

    if invalid_2026_count>0 then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','KR_2026_TRANSITION_TARGET_INVALID',
        'severity','blocking',
        'message','Revise o tratamento de 2026 como transição, confirmação de linha de base ou meta anual sustentada por evidência.',
        'affectedCount',invalid_2026_count
      ));
    end if;
  end if;

  return jsonb_build_object(
    'formulationId',p_formulation_id,
    'horizonStartYear',start_year,
    'horizonEndYear',end_year,
    'expectedFullYearStart',expected_full_year_start,
    'activeKeyResults',active_kr_count,
    'expectedAnnualTargets',expected_annual_count,
    'presentAnnualTargets',present_annual_count,
    'missingAnnualTargets',missing_annual_count,
    'readyForValidation',missing_annual_count=0 and invalid_2026_count=0,
    'blockingIssueCount',jsonb_array_length(issues),
    'issues',issues,
    'methodologyRules',jsonb_build_object(
      'annualTargetsAreEvolutionCycles',false,
      'targetYears',jsonb_build_object('start',start_year,'end',end_year),
      'year2026Treatment',case when start_year=2026 then 'transition_or_baseline_confirmation' else 'normal' end,
      'firstFullPerformanceYear',expected_full_year_start,
      'humanValidationRequired',true,
      'proposalOnlyUntilValidation',true
    )
  );
end;
$function$;

revoke all on function public.get_skpe_key_result_annual_target_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_key_result_annual_target_readiness(uuid)
to authenticated,service_role;

comment on table public.skpe_key_result_annual_targets is
'Governed annual target trajectory for Key Results. Years are annual performance targets and are not Evolution Cycles.';

comment on function public.upsert_skpe_key_result_annual_target(uuid,integer,text,text,numeric,text,text,uuid,jsonb,text) is
'Creates or updates a proposal-only annual KR target. Supports numeric and textual target expressions; never validates or approves automatically.';

comment on function public.get_skpe_key_result_annual_target_readiness(uuid) is
'Evaluates annual KR target coverage across the Strategic Horizon. For the current 2026 in-flight implementation, 2026 may be transition/baseline confirmation and 2027 is normally the first full annual performance year.';
