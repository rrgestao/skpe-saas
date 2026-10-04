-- Govern PEM-05.02 Critical Performance Analysis using the existing FE-08 RAE.
-- No review, finding, conclusion or governance decision is created automatically.

create or replace function public.get_skpe_pem0502_critical_review_readiness(
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
  operation_readiness jsonb;
  cycle_id uuid;
  review_row public.skpe_strategy_reviews%rowtype;
  issues jsonb := '[]'::jsonb;
  review_item_count integer := 0;
  decision_count integer := 0;
  blocking_count integer := 0;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_monitoring(formulation_row.organization_id)
     and not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado à Análise Crítica de Desempenho.';
  end if;

  operation_readiness:=public.get_skpe_pem0501_monitoring_operation_readiness(
    target_formulation_id
  );

  if not coalesce((operation_readiness->>'readyForCompletion')::boolean,false) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0502_MONITORING_OPERATION_NOT_READY',
      'severity','blocking',
      'message','PEM-05.02 exige um ciclo de monitoramento operado e pronto para revisão em PEM-05.01.'
    ));
  end if;

  cycle_id:=nullif(operation_readiness->>'cycleId','')::uuid;

  if cycle_id is not null then
    select * into review_row
    from public.skpe_strategy_reviews
    where monitoring_cycle_id=cycle_id
      and review_type='rae'
    order by created_at desc
    limit 1;
  end if;

  if review_row.id is null then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0502_RAE_MISSING',
      'severity','blocking',
      'message','A Análise Crítica exige uma RAE vinculada ao ciclo operado.'
    ));
  else
    if review_row.status not in ('ratified','closed')
       or review_row.ratified_at is null
       or review_row.ratified_by is null then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0502_RAE_NOT_RATIFIED',
        'severity','blocking',
        'message','A RAE deve estar ratificada institucionalmente antes da conclusão de PEM-05.02.'
      ));
    end if;

    if review_row.held_at is null
       or length(trim(coalesce(review_row.executive_summary,'')))<10
       or length(trim(coalesce(review_row.conclusions,'')))<10 then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0502_CRITICAL_SYNTHESIS_INCOMPLETE',
        'severity','blocking',
        'message','A RAE deve registrar realização, síntese executiva e conclusões substantivas.'
      ));
    end if;

    select count(*)::integer into review_item_count
    from public.skpe_strategy_review_items item
    where item.strategy_review_id=review_row.id
      and item.status<>'archived';

    if review_item_count=0 then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0502_REVIEW_ITEM_MISSING',
        'severity','blocking',
        'message','A análise crítica deve possuir ao menos um item de revisão rastreável.'
      ));
    end if;

    if exists (
      select 1
      from public.skpe_strategy_review_items item
      where item.strategy_review_id=review_row.id
        and item.status<>'archived'
        and (
          length(trim(coalesce(item.analysis_text,'')))<10
          or (
            item.finding_type in ('deviation','risk','problem','critical_issue')
            and length(trim(coalesce(item.root_cause,'')))<5
          )
        )
    ) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0502_REVIEW_ITEM_ANALYSIS_INCOMPLETE',
        'severity','blocking',
        'message','Itens críticos da RAE devem possuir análise e, quando aplicável, causa-raiz suficiente.',
        'affectedCount',(
          select count(*)
          from public.skpe_strategy_review_items item
          where item.strategy_review_id=review_row.id
            and item.status<>'archived'
            and (
              length(trim(coalesce(item.analysis_text,'')))<10
              or (
                item.finding_type in ('deviation','risk','problem','critical_issue')
                and length(trim(coalesce(item.root_cause,'')))<5
              )
            )
        )
      ));
    end if;

    if exists (
      select 1
      from public.skpe_strategy_review_items item
      where item.strategy_review_id=review_row.id
        and item.status<>'archived'
        and item.requires_decision=true
        and not exists (
          select 1
          from public.skpe_governance_decisions decision
          where decision.strategy_review_id=review_row.id
            and decision.strategy_review_item_id=item.id
            and decision.status<>'cancelled'
        )
    ) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0502_REQUIRED_DECISION_MISSING',
        'severity','blocking',
        'message','Todo item da RAE marcado como requerendo decisão deve possuir decisão de governança rastreável.',
        'affectedCount',(
          select count(*)
          from public.skpe_strategy_review_items item
          where item.strategy_review_id=review_row.id
            and item.status<>'archived'
            and item.requires_decision=true
            and not exists (
              select 1
              from public.skpe_governance_decisions decision
              where decision.strategy_review_id=review_row.id
                and decision.strategy_review_item_id=item.id
                and decision.status<>'cancelled'
            )
        )
      ));
    end if;

    if exists (
      select 1
      from public.skpe_governance_decisions decision
      where decision.strategy_review_id=review_row.id
        and decision.priority in ('high','critical')
        and decision.status not in ('completed','cancelled')
        and (
          decision.responsible_user_id is null
          or decision.due_date is null
        )
    ) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0502_CRITICAL_DECISION_INCOMPLETE',
        'severity','blocking',
        'message','Decisão de alta criticidade deve possuir responsável e prazo.'
      ));
    end if;

    select count(*)::integer into decision_count
    from public.skpe_governance_decisions decision
    where decision.strategy_review_id=review_row.id
      and decision.status<>'cancelled';
  end if;

  select count(*)::integer into blocking_count
  from jsonb_array_elements(issues) issue
  where issue->>'severity'='blocking';

  return jsonb_build_object(
    'formulationId',formulation_row.id,
    'projectId',formulation_row.project_id,
    'organizationId',formulation_row.organization_id,
    'monitoringOperationReadiness',operation_readiness,
    'cycleId',cycle_id,
    'strategyReviewId',review_row.id,
    'reviewStatus',review_row.status,
    'reviewHeldAt',review_row.held_at,
    'reviewRatifiedAt',review_row.ratified_at,
    'readyForCompletion',blocking_count=0 and review_row.id is not null,
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'metrics',jsonb_build_object(
      'reviewItems',review_item_count,
      'governanceDecisions',decision_count
    ),
    'analysisPolicy',jsonb_build_object(
      'reusesFe08Rae',true,
      'createsReviewAutomatically',false,
      'createsConclusionsAutomatically',false,
      'createsDecisionsAutomatically',false,
      'humanRatificationRequired',true
    )
  );
end;
$function$;

revoke all on function public.get_skpe_pem0502_critical_review_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem0502_critical_review_readiness(uuid)
to authenticated,service_role;

create or replace function public.skpe_guard_pem0502_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
  readiness jsonb;
begin
  if new.code<>'PEM-05.02' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using errcode='55000',message='PEM-05.02 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0502_critical_review_readiness(formulation_id);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-05.02 não pode ser concluída: a Análise Crítica ainda possui bloqueadores.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'monitoringCycleId',readiness->>'cycleId',
      'strategyReviewId',readiness->>'strategyReviewId',
      'reviewRatifiedAt',readiness->>'reviewRatifiedAt',
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness,
      'conclusionCreatedAutomatically',false,
      'decisionCreatedAutomatically',false
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0502_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0502_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0502_completion();

comment on function public.get_skpe_pem0502_critical_review_readiness(uuid) is
'Canonical PEM-05.02 readiness. Reuses the FE-08 RAE, requires human ratification, substantive review items and traceable governance decisions where required.';
comment on function public.skpe_guard_pem0502_completion() is
'Fail-closed completion guard for PEM-05.02.';
