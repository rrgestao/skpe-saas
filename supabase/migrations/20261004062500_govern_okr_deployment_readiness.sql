-- Govern PEM-03.01 OKR deployment readiness without imposing a fixed KR count.
-- Quality and measurability are blocking; quantity is not.

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
  formulation_row public.skpe_strategic_formulations%rowtype;
  issues jsonb := '[]'::jsonb;
  approved_objective_count integer := 0;
  okr_count integer := 0;
  kr_count integer := 0;
  blocking_count integer := 0;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado ao Desdobramento em OKRs.';
  end if;

  select count(*) into approved_objective_count
  from public.skpe_strategic_objectives objective
  where objective.formulation_id=target_formulation_id
    and objective.status in ('active','completed')
    and objective.validation_status in ('validated','approved');

  select count(*) into okr_count
  from public.skpe_okrs okr
  where okr.formulation_id=target_formulation_id
    and okr.status<>'cancelled';

  select count(*) into kr_count
  from public.skpe_key_results kr
  where kr.formulation_id=target_formulation_id
    and kr.status<>'cancelled';

  if approved_objective_count=0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','APPROVED_STRATEGIC_OBJECTIVES_MISSING',
      'severity','blocking',
      'message','PEM-03.01 exige Objetivos Estratégicos validados/aprovados e ativos antes do desdobramento em OKRs.',
      'affectedCount',1
    ));
  end if;

  if exists (
    select 1
    from public.skpe_strategic_objectives objective
    where objective.formulation_id=target_formulation_id
      and objective.status in ('active','completed')
      and objective.validation_status in ('validated','approved')
      and not exists (
        select 1
        from public.skpe_okr_objectives link
        join public.skpe_okrs okr on okr.id=link.okr_id
        where link.formulation_id=target_formulation_id
          and link.strategic_objective_id=objective.id
          and okr.status<>'cancelled'
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','STRATEGIC_OBJECTIVE_WITHOUT_OKR',
      'severity','blocking',
      'message','Todo Objetivo Estratégico aprovado deve possuir pelo menos um desdobramento explícito em OKR.',
      'affectedCount',(
        select count(*)
        from public.skpe_strategic_objectives objective
        where objective.formulation_id=target_formulation_id
          and objective.status in ('active','completed')
          and objective.validation_status in ('validated','approved')
          and not exists (
            select 1
            from public.skpe_okr_objectives link
            join public.skpe_okrs okr on okr.id=link.okr_id
            where link.formulation_id=target_formulation_id
              and link.strategic_objective_id=objective.id
              and okr.status<>'cancelled'
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_okrs okr
    where okr.formulation_id=target_formulation_id
      and okr.status<>'cancelled'
      and not exists (
        select 1
        from public.skpe_okr_objectives link
        where link.formulation_id=target_formulation_id
          and link.okr_id=okr.id
          and link.is_primary=true
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','OKR_WITHOUT_PRIMARY_OBJECTIVE',
      'severity','blocking',
      'message','Todo OKR deve possuir um Objetivo Estratégico primário explícito.',
      'affectedCount',(
        select count(*)
        from public.skpe_okrs okr
        where okr.formulation_id=target_formulation_id
          and okr.status<>'cancelled'
          and not exists (
            select 1
            from public.skpe_okr_objectives link
            where link.formulation_id=target_formulation_id
              and link.okr_id=okr.id
              and link.is_primary=true
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_okrs okr
    left join public.skpe_okr_cycles cycle on cycle.id=okr.okr_cycle_id
    where okr.formulation_id=target_formulation_id
      and okr.status<>'cancelled'
      and coalesce(cycle.status,'missing') not in ('active','completed')
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','OKR_CYCLE_NOT_ACTIVE',
      'severity','blocking',
      'message','Todo OKR validável deve pertencer a um ciclo de OKR ativo ou concluído.',
      'affectedCount',(
        select count(*)
        from public.skpe_okrs okr
        left join public.skpe_okr_cycles cycle on cycle.id=okr.okr_cycle_id
        where okr.formulation_id=target_formulation_id
          and okr.status<>'cancelled'
          and coalesce(cycle.status,'missing') not in ('active','completed')
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_okrs okr
    where okr.formulation_id=target_formulation_id
      and okr.status<>'cancelled'
      and okr.validation_status<>'validated'
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','OKR_VALIDATION_PENDING',
      'severity','blocking',
      'message','Todo Objetivo de OKR deve possuir validação humana antes da conclusão de PEM-03.01.',
      'affectedCount',(
        select count(*)
        from public.skpe_okrs okr
        where okr.formulation_id=target_formulation_id
          and okr.status<>'cancelled'
          and okr.validation_status<>'validated'
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_okrs okr
    where okr.formulation_id=target_formulation_id
      and okr.status<>'cancelled'
      and not exists (
        select 1
        from public.skpe_key_results kr
        where kr.formulation_id=target_formulation_id
          and kr.okr_id=okr.id
          and kr.status<>'cancelled'
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','OKR_WITHOUT_KEY_RESULT',
      'severity','blocking',
      'message','Todo OKR deve possuir ao menos um Resultado-Chave mensurável. A metodologia não impõe quantidade fixa de KRs.',
      'affectedCount',(
        select count(*)
        from public.skpe_okrs okr
        where okr.formulation_id=target_formulation_id
          and okr.status<>'cancelled'
          and not exists (
            select 1
            from public.skpe_key_results kr
            where kr.formulation_id=target_formulation_id
              and kr.okr_id=okr.id
              and kr.status<>'cancelled'
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_key_results kr
    where kr.formulation_id=target_formulation_id
      and kr.status<>'cancelled'
      and (
        kr.okr_id is null
        or kr.baseline_value is null
        or kr.target_value is null
        or length(trim(coalesce(kr.unit,'')))=0
        or kr.period_end is null
        or length(trim(coalesce(
          kr.metadata->>'dataSource',
          kr.metadata->>'data_source',
          kr.metadata->>'source_data_source',
          ''
        )))=0
        or length(trim(coalesce(
          kr.metadata->>'polarity',
          kr.metadata->>'source_polarity',
          ''
        )))=0
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','KEY_RESULT_NOT_MEASURABLE',
      'severity','blocking',
      'message','Todo KR deve explicitar vínculo ao OKR, linha de base, meta, unidade, prazo, fonte e polaridade.',
      'affectedCount',(
        select count(*)
        from public.skpe_key_results kr
        where kr.formulation_id=target_formulation_id
          and kr.status<>'cancelled'
          and (
            kr.okr_id is null
            or kr.baseline_value is null
            or kr.target_value is null
            or length(trim(coalesce(kr.unit,'')))=0
            or kr.period_end is null
            or length(trim(coalesce(
              kr.metadata->>'dataSource',
              kr.metadata->>'data_source',
              kr.metadata->>'source_data_source',
              ''
            )))=0
            or length(trim(coalesce(
              kr.metadata->>'polarity',
              kr.metadata->>'source_polarity',
              ''
            )))=0
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_key_results kr
    where kr.formulation_id=target_formulation_id
      and kr.status<>'cancelled'
      and kr.validation_status not in ('validated','approved')
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','KEY_RESULT_VALIDATION_PENDING',
      'severity','blocking',
      'message','Todo KR deve possuir validação humana antes da conclusão de PEM-03.01.',
      'affectedCount',(
        select count(*)
        from public.skpe_key_results kr
        where kr.formulation_id=target_formulation_id
          and kr.status<>'cancelled'
          and kr.validation_status not in ('validated','approved')
      )
    ));
  end if;

  select count(*)::integer into blocking_count
  from jsonb_array_elements(issues) issue
  where issue->>'severity'='blocking';

  return jsonb_build_object(
    'formulationId',formulation_row.id,
    'projectId',formulation_row.project_id,
    'organizationId',formulation_row.organization_id,
    'readyForValidation',blocking_count=0 and okr_count>0 and kr_count>0,
    'blockingIssueCount',blocking_count,
    'counts',jsonb_build_object(
      'approvedStrategicObjectives',approved_objective_count,
      'okrs',okr_count,
      'keyResults',kr_count
    ),
    'issues',issues,
    'methodologyRules',jsonb_build_object(
      'fixedKrCountRequired',false,
      'krQualityOverFixedQuantity',true,
      'krRequiresBaseline',true,
      'krRequiresTarget',true,
      'krRequiresUnit',true,
      'krRequiresDeadline',true,
      'krRequiresDataSource',true,
      'krRequiresPolarity',true,
      'humanValidationRequired',true,
      'initiativeIsNotKeyResult',true
    )
  );
end;
$function$;

revoke all on function public.get_skpe_okr_deployment_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_okr_deployment_readiness(uuid)
to authenticated,service_role;

create or replace function public.skpe_guard_pem0301_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  readiness jsonb;
  formulation_id uuid;
begin
  if new.code<>'PEM-03.01' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using errcode='55000',message='PEM-03.01 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_okr_deployment_readiness(formulation_id);

  if not coalesce((readiness->>'readyForValidation')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-03.01 não pode ser concluída: o desdobramento em OKRs possui pendências metodológicas ou de validação.';
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0301_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0301_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0301_completion();

comment on function public.get_skpe_okr_deployment_readiness(uuid) is
'Canonical readiness for PEM-03.01. Requires OE->OKR traceability and measurable, human-validated KRs without imposing a fixed KR count.';
