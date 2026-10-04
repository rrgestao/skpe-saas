-- Govern PEM-05.03 Strategic Learning and Improvement using the existing FE-08 ledger.
-- No learning, decision or action is created automatically.

create or replace function public.get_skpe_pem0503_learning_readiness(
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
  critical_review_readiness jsonb;
  cycle_id uuid;
  review_id uuid;
  issues jsonb := '[]'::jsonb;
  learning_count integer := 0;
  accepted_count integer := 0;
  incorporated_count integer := 0;
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
    raise exception using errcode='42501',message='Acesso negado a Aprendizado e Melhoria.';
  end if;

  critical_review_readiness:=public.get_skpe_pem0502_critical_review_readiness(
    target_formulation_id
  );

  if not coalesce((critical_review_readiness->>'readyForCompletion')::boolean,false) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0503_CRITICAL_REVIEW_NOT_READY',
      'severity','blocking',
      'message','PEM-05.03 exige Análise Crítica de Desempenho concluída e ratificada em PEM-05.02.'
    ));
  end if;

  cycle_id:=nullif(critical_review_readiness->>'cycleId','')::uuid;
  review_id:=nullif(critical_review_readiness->>'strategyReviewId','')::uuid;

  select
    count(*)::integer,
    count(*) filter (where learning.status='accepted')::integer,
    count(*) filter (where learning.status='incorporated')::integer
  into learning_count,accepted_count,incorporated_count
  from public.skpe_strategic_learnings learning
  where learning.formulation_id=target_formulation_id
    and learning.status not in ('rejected','archived')
    and (
      (review_id is not null and learning.strategy_review_id=review_id)
      or (cycle_id is not null and learning.monitoring_cycle_id=cycle_id)
    );

  if learning_count=0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0503_LEARNING_MISSING',
      'severity','blocking',
      'message','A RAE ratificada deve produzir ao menos um aprendizado estratégico rastreável para Aprendizado e Melhoria.'
    ));
  end if;

  if exists (
    select 1
    from public.skpe_strategic_learnings learning
    where learning.formulation_id=target_formulation_id
      and learning.status not in ('rejected','archived')
      and (
        (review_id is not null and learning.strategy_review_id=review_id)
        or (cycle_id is not null and learning.monitoring_cycle_id=cycle_id)
      )
      and (
        length(trim(coalesce(learning.evidence_text,'')))<5
        or length(trim(coalesce(learning.interpretation_text,'')))<10
        or length(trim(coalesce(learning.lesson_text,'')))<10
        or length(trim(coalesce(learning.recommendation,'')))<10
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0503_LEARNING_CONTENT_INCOMPLETE',
      'severity','blocking',
      'message','Todo aprendizado ativo deve explicitar evidência, interpretação, lição e recomendação substantivas.',
      'affectedCount',(
        select count(*)
        from public.skpe_strategic_learnings learning
        where learning.formulation_id=target_formulation_id
          and learning.status not in ('rejected','archived')
          and (
            (review_id is not null and learning.strategy_review_id=review_id)
            or (cycle_id is not null and learning.monitoring_cycle_id=cycle_id)
          )
          and (
            length(trim(coalesce(learning.evidence_text,'')))<5
            or length(trim(coalesce(learning.interpretation_text,'')))<10
            or length(trim(coalesce(learning.lesson_text,'')))<10
            or length(trim(coalesce(learning.recommendation,'')))<10
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_strategic_learnings learning
    where learning.formulation_id=target_formulation_id
      and learning.status not in ('rejected','archived')
      and (
        (review_id is not null and learning.strategy_review_id=review_id)
        or (cycle_id is not null and learning.monitoring_cycle_id=cycle_id)
      )
      and learning.status not in ('accepted','incorporated')
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0503_LEARNING_DECISION_PENDING',
      'severity','blocking',
      'message','Todo aprendizado ativo deve possuir decisão humana de aceite ou incorporação antes da conclusão de PEM-05.03.'
    ));
  end if;

  if exists (
    select 1
    from public.skpe_strategic_learnings learning
    where learning.formulation_id=target_formulation_id
      and learning.status in ('accepted','incorporated')
      and (
        (review_id is not null and learning.strategy_review_id=review_id)
        or (cycle_id is not null and learning.monitoring_cycle_id=cycle_id)
      )
      and coalesce((learning.metadata->>'requiresAction')::boolean,false)
      and (
        coalesce(learning.metadata->>'governanceDecisionId','') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        or not exists (
          select 1
          from public.skpe_governance_decisions decision
          where decision.id=case
            when coalesce(learning.metadata->>'governanceDecisionId','') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
            then (learning.metadata->>'governanceDecisionId')::uuid
            else null
          end
            and decision.strategy_review_id=review_id
            and decision.status<>'cancelled'
        )
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0503_ACTION_DECISION_LINK_MISSING',
      'severity','blocking',
      'message','Aprendizado que requer ação deve apontar metadata.governanceDecisionId para uma decisão válida da RAE.'
    ));
  end if;

  if exists (
    select 1
    from public.skpe_strategic_learnings learning
    join public.skpe_governance_decisions decision
      on decision.id=case
        when coalesce(learning.metadata->>'governanceDecisionId','') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
        then (learning.metadata->>'governanceDecisionId')::uuid
        else null
      end
    where learning.formulation_id=target_formulation_id
      and learning.status in ('accepted','incorporated')
      and (
        (review_id is not null and learning.strategy_review_id=review_id)
        or (cycle_id is not null and learning.monitoring_cycle_id=cycle_id)
      )
      and coalesce((learning.metadata->>'requiresAction')::boolean,false)
      and decision.status not in ('completed','cancelled')
      and (
        decision.responsible_user_id is null
        or decision.due_date is null
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0503_IMPROVEMENT_ACTION_OWNER_DUE_MISSING',
      'severity','blocking',
      'message','Decisão de melhoria decorrente de aprendizado deve possuir responsável e prazo.'
    ));
  end if;

  if exists (
    select 1
    from public.skpe_strategic_learnings learning
    where learning.formulation_id=target_formulation_id
      and learning.status in ('accepted','incorporated')
      and learning.impact_level in ('high','critical')
      and (
        (review_id is not null and learning.strategy_review_id=review_id)
        or (cycle_id is not null and learning.monitoring_cycle_id=cycle_id)
      )
      and length(trim(coalesce(learning.governance_decision,'')))<10
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0503_HIGH_IMPACT_GOVERNANCE_DECISION_MISSING',
      'severity','blocking',
      'message','Aprendizado de alto impacto deve registrar a decisão de governança que orienta sua incorporação.'
    ));
  end if;

  select count(*)::integer into blocking_count
  from jsonb_array_elements(issues) issue
  where issue->>'severity'='blocking';

  return jsonb_build_object(
    'formulationId',formulation_row.id,
    'projectId',formulation_row.project_id,
    'organizationId',formulation_row.organization_id,
    'criticalReviewReadiness',critical_review_readiness,
    'cycleId',cycle_id,
    'strategyReviewId',review_id,
    'readyForCompletion',blocking_count=0 and learning_count>0,
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'metrics',jsonb_build_object(
      'learnings',learning_count,
      'acceptedLearnings',accepted_count,
      'incorporatedLearnings',incorporated_count
    ),
    'learningPolicy',jsonb_build_object(
      'learningAuthority','skpe_strategic_learnings',
      'decisionAuthority','skpe_governance_decisions',
      'createsLearningAutomatically',false,
      'acceptsLearningAutomatically',false,
      'createsImprovementActionAutomatically',false,
      'learningIsNotDecision',true
    )
  );
end;
$function$;

revoke all on function public.get_skpe_pem0503_learning_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem0503_learning_readiness(uuid)
to authenticated,service_role;

create or replace function public.skpe_guard_pem0503_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
  readiness jsonb;
begin
  if new.code<>'PEM-05.03' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using errcode='55000',message='PEM-05.03 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0503_learning_readiness(formulation_id);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-05.03 não pode ser concluída: Aprendizado e Melhoria ainda possuem bloqueadores.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'monitoringCycleId',readiness->>'cycleId',
      'strategyReviewId',readiness->>'strategyReviewId',
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness,
      'learningCreatedAutomatically',false,
      'learningAcceptedAutomatically',false,
      'improvementActionCreatedAutomatically',false
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0503_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0503_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0503_completion();

comment on function public.get_skpe_pem0503_learning_readiness(uuid) is
'Canonical PEM-05.03 readiness. Reuses skpe_strategic_learnings and governance decisions, preserving the distinction between learning, decision and improvement action.';
comment on function public.skpe_guard_pem0503_completion() is
'Fail-closed completion guard for PEM-05.03.';
