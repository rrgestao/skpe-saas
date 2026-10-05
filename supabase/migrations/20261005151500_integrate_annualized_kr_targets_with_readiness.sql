-- Integrate annualized KR target trajectories into OKR package and PEM-03.01 readiness.
-- Annual targets are not Evolution Cycles and do not create any institutional decision.

alter function public.get_skpe_okrs_readiness(uuid)
  rename to get_skpe_okrs_readiness_pre_annual_targets_20261005;

create or replace function public.get_skpe_okrs_readiness(
  p_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  base jsonb;
  annual jsonb;
  annual_blocking integer;
begin
  base:=public.get_skpe_okrs_readiness_pre_annual_targets_20261005(p_formulation_id);
  annual:=public.get_skpe_key_result_annual_target_readiness(p_formulation_id);
  annual_blocking:=coalesce((annual->>'blockingIssueCount')::integer,0);

  return base || jsonb_build_object(
    'readyForValidation',
      coalesce((base->>'readyForValidation')::boolean,false)
      and coalesce((annual->>'readyForValidation')::boolean,false),
    'readyForFormulation',
      coalesce((base->>'readyForFormulation')::boolean,false)
      and coalesce((annual->>'readyForValidation')::boolean,false),
    'contentBlockingIssueCount',
      coalesce((base->>'contentBlockingIssueCount')::integer,0)+annual_blocking,
    'blockingIssueCount',
      coalesce((base->>'blockingIssueCount')::integer,0)+annual_blocking,
    'issues',
      coalesce(base->'issues','[]'::jsonb) || coalesce(annual->'issues','[]'::jsonb),
    'annualTargetReadiness',annual
  );
end;
$function$;

revoke all on function public.get_skpe_okrs_readiness(uuid) from public,anon;
grant execute on function public.get_skpe_okrs_readiness(uuid) to authenticated,service_role;

alter function public.get_skpe_okr_deployment_readiness(uuid)
  rename to get_skpe_okr_deployment_readiness_pre_annual_targets_20261005;

create or replace function public.get_skpe_okr_deployment_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  base jsonb;
  annual jsonb;
  annual_blocking integer;
begin
  base:=public.get_skpe_okr_deployment_readiness_pre_annual_targets_20261005(target_formulation_id);
  annual:=public.get_skpe_key_result_annual_target_readiness(target_formulation_id);
  annual_blocking:=coalesce((annual->>'blockingIssueCount')::integer,0);

  return base || jsonb_build_object(
    'readyForValidation',
      coalesce((base->>'readyForValidation')::boolean,false)
      and coalesce((annual->>'readyForValidation')::boolean,false),
    'blockingIssueCount',
      coalesce((base->>'blockingIssueCount')::integer,0)+annual_blocking,
    'issues',
      coalesce(base->'issues','[]'::jsonb) || coalesce(annual->'issues','[]'::jsonb),
    'annualTargetReadiness',annual,
    'methodologyRules',
      coalesce(base->'methodologyRules','{}'::jsonb)
      || jsonb_build_object(
        'annualTargetTrajectoryRequired',true,
        'annualTargetsAreEvolutionCycles',false,
        'year2026Treatment','transition_or_baseline_confirmation',
        'firstFullPerformanceYear',coalesce((annual->>'expectedFullYearStart')::integer,2027)
      )
  );
end;
$function$;

revoke all on function public.get_skpe_okr_deployment_readiness(uuid) from public,anon;
grant execute on function public.get_skpe_okr_deployment_readiness(uuid) to authenticated,service_role;

create or replace function public.skpe_sync_annual_kr_target_validation_from_package()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  next_status text;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  next_status:=case new.status
    when 'pending_validation' then 'pending_validation'
    when 'validated' then 'validated'
    when 'in_elaboration' then 'draft'
    else null
  end;

  if next_status is not null then
    update public.skpe_key_result_annual_targets
    set
      validation_status=next_status,
      status=case
        when next_status='validated' then 'active'
        when status='superseded' then status
        else 'draft'
      end,
      metadata=coalesce(metadata,'{}'::jsonb)
        || jsonb_build_object(
          'validationInheritedFromOkrPackage',true,
          'okrPackageStatus',new.status,
          'validationSynchronizedAt',timezone('utc',now())
        ),
      updated_at=timezone('utc',now()),
      updated_by=coalesce(auth.uid(),new.updated_by)
    where formulation_id=new.formulation_id
      and status<>'superseded';
  end if;

  return new;
end;
$function$;

drop trigger if exists skpe_sync_annual_kr_target_validation_from_package
  on public.skpe_okr_packages;
create trigger skpe_sync_annual_kr_target_validation_from_package
after update of status on public.skpe_okr_packages
for each row
execute function public.skpe_sync_annual_kr_target_validation_from_package();

comment on function public.get_skpe_okrs_readiness(uuid) is
'OKR/KR package readiness enriched with annual KR target trajectory coverage. Annual targets are distinct from Evolution Cycles.';

comment on function public.get_skpe_okr_deployment_readiness(uuid) is
'PEM-03.01 readiness enriched with annual KR target trajectory coverage and the governed 2026 transition rule.';
