-- Govern PEM-05.01 as proof that at least one FE-08 monitoring cycle
-- was actually operated and reached review readiness.
-- This migration does not open, submit, ratify or close any cycle.

create or replace function public.get_skpe_pem0501_monitoring_operation_readiness(
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
  package_readiness jsonb;
  package_row public.skpe_monitoring_packages%rowtype;
  cycle_row public.skpe_monitoring_cycles%rowtype;
  cycle_readiness jsonb := '{}'::jsonb;
  candidate_cycle_id uuid;
  issues jsonb := '[]'::jsonb;
  blocking_count integer := 0;
  operational_record_count integer := 0;
  missing_evidence_count integer := 0;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_monitoring(formulation_row.organization_id)
     and not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado à Operação da Rotina de Monitoramento.';
  end if;

  package_readiness:=public.get_skpe_monitoring_package_readiness(
    target_formulation_id,
    true
  );

  if not coalesce((package_readiness->>'readyForFormulation')::boolean,false) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0501_FE08_NOT_READY',
      'severity','blocking',
      'message','PEM-05.01 exige o pacote FE-08 validado e sem bloqueadores.'
    ));
  end if;

  select * into package_row
  from public.skpe_monitoring_packages
  where formulation_id=target_formulation_id;

  select cycle.id into candidate_cycle_id
  from public.skpe_monitoring_cycles cycle
  where cycle.formulation_id=target_formulation_id
    and cycle.status in ('under_review','pending_ratification','closed')
    and cycle.submitted_for_review_at is not null
  order by
    case cycle.status
      when 'closed' then 1
      when 'pending_ratification' then 2
      else 3
    end,
    cycle.period_end desc,
    cycle.created_at desc
  limit 1;

  if candidate_cycle_id is null then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0501_OPERATED_CYCLE_MISSING',
      'severity','blocking',
      'message','Não existe ciclo FE-08 operado e submetido para revisão.'
    ));
  else
    select * into cycle_row
    from public.skpe_monitoring_cycles
    where id=candidate_cycle_id;

    cycle_readiness:=public.get_skpe_monitoring_readiness(candidate_cycle_id);

    if not coalesce((cycle_readiness->>'readyForReview')::boolean,false) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0501_CYCLE_NOT_READY_FOR_REVIEW',
        'severity','blocking',
        'message','O ciclo operado ainda possui pendências de dados, check-ins ou qualidade antes da análise crítica.',
        'cycleId',candidate_cycle_id,
        'cycleBlockingIssues',coalesce(cycle_readiness->'reviewBlockingIssues','[]'::jsonb)
      ));
    end if;

    select
      (select count(*) from public.skpe_indicator_measurements m
        where m.monitoring_cycle_id=candidate_cycle_id
          and m.status in ('submitted','validated'))
      +
      (select count(*) from public.skpe_key_result_check_ins c
        where c.monitoring_cycle_id=candidate_cycle_id
          and c.status in ('submitted','validated'))
      +
      (select count(*) from public.skpe_initiative_check_ins c
        where c.monitoring_cycle_id=candidate_cycle_id
          and c.status in ('submitted','validated'))
      +
      (select count(*) from public.skpe_initiative_outcome_measurements m
        where m.monitoring_cycle_id=candidate_cycle_id
          and m.status in ('submitted','validated'))
    into operational_record_count;

    if operational_record_count=0 then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0501_OPERATIONAL_DATA_MISSING',
        'severity','blocking',
        'message','O ciclo foi submetido para revisão, mas não possui medições ou check-ins operacionais.'
      ));
    end if;

    if coalesce(package_row.evidence_required,false) then
      select
        (select count(*) from public.skpe_indicator_measurements m
          where m.monitoring_cycle_id=candidate_cycle_id
            and m.status in ('submitted','validated')
            and length(trim(coalesce(m.evidence_reference,'')))=0)
        +
        (select count(*) from public.skpe_key_result_check_ins c
          where c.monitoring_cycle_id=candidate_cycle_id
            and c.status in ('submitted','validated')
            and length(trim(coalesce(c.evidence_reference,'')))=0)
        +
        (select count(*) from public.skpe_initiative_check_ins c
          where c.monitoring_cycle_id=candidate_cycle_id
            and c.status in ('submitted','validated')
            and length(trim(coalesce(c.evidence_reference,'')))=0)
        +
        (select count(*) from public.skpe_initiative_outcome_measurements m
          where m.monitoring_cycle_id=candidate_cycle_id
            and m.status in ('submitted','validated')
            and length(trim(coalesce(m.evidence_reference,'')))=0)
      into missing_evidence_count;

      if missing_evidence_count>0 then
        issues:=issues || jsonb_build_array(jsonb_build_object(
          'code','PEM0501_REQUIRED_EVIDENCE_MISSING',
          'severity','blocking',
          'message','O FE-08 exige evidências e há registros operacionais sem referência de evidência.',
          'affectedCount',missing_evidence_count
        ));
      end if;
    end if;
  end if;

  select count(*)::integer into blocking_count
  from jsonb_array_elements(issues) issue
  where issue->>'severity'='blocking';

  return jsonb_build_object(
    'formulationId',formulation_row.id,
    'projectId',formulation_row.project_id,
    'organizationId',formulation_row.organization_id,
    'monitoringPackageId',package_row.id,
    'monitoringPackageStatus',package_row.status,
    'cycleId',candidate_cycle_id,
    'cycleCode',cycle_row.code,
    'cycleName',cycle_row.name,
    'cycleStatus',cycle_row.status,
    'cyclePeriodStart',cycle_row.period_start,
    'cyclePeriodEnd',cycle_row.period_end,
    'cycleReadiness',cycle_readiness,
    'readyForCompletion',blocking_count=0 and candidate_cycle_id is not null,
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'metrics',jsonb_build_object(
      'operationalRecords',operational_record_count,
      'missingRequiredEvidence',missing_evidence_count,
      'indicatorMeasurements',coalesce((cycle_readiness->'metrics'->>'indicatorMeasurements')::integer,0),
      'keyResultCheckIns',coalesce((cycle_readiness->'metrics'->>'keyResultCheckIns')::integer,0),
      'initiativeCheckIns',coalesce((cycle_readiness->'metrics'->>'initiativeCheckIns')::integer,0)
    ),
    'operationPolicy',jsonb_build_object(
      'reusesFe08',true,
      'opensCycleAutomatically',false,
      'submitsCycleAutomatically',false,
      'ratifiesCycleAutomatically',false,
      'closesCycleAutomatically',false,
      'fabricatesPerformance',false
    )
  );
end;
$function$;

revoke all on function public.get_skpe_pem0501_monitoring_operation_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem0501_monitoring_operation_readiness(uuid)
to authenticated,service_role;

create or replace function public.skpe_guard_pem0501_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
  readiness jsonb;
begin
  if new.code<>'PEM-05.01' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using errcode='55000',message='PEM-05.01 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0501_monitoring_operation_readiness(formulation_id);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-05.01 não pode ser concluída: a rotina de monitoramento ainda não possui ciclo operado e pronto para análise crítica.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'monitoringCycleId',readiness->>'cycleId',
      'monitoringCycleStatus',readiness->>'cycleStatus',
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness,
      'cycleOpenedAutomatically',false,
      'performanceFabricated',false
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0501_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0501_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0501_completion();

comment on function public.get_skpe_pem0501_monitoring_operation_readiness(uuid) is
'Canonical PEM-05.01 readiness. Requires a validated FE-08 package and at least one operated cycle submitted and ready for critical review, without auto-opening, submitting, ratifying, closing or fabricating performance.';
comment on function public.skpe_guard_pem0501_completion() is
'Fail-closed completion guard for PEM-05.01.';
