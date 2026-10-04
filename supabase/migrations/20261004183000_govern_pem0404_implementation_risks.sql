-- Govern PEM-04.04 Implementation Risk Management by composing existing risk authorities.
-- No risk is created, duplicated, accepted or mitigated automatically.

create or replace function public.get_skpe_pem0404_implementation_risk_readiness(
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
  change_readiness jsonb;
  issues jsonb := '[]'::jsonb;
  selected_initiative_risk_count integer := 0;
  high_initiative_risk_count integer := 0;
  strategic_risk_count integer := 0;
  strategic_risk_requiring_mitigation_count integer := 0;
  blocking_count integer := 0;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using
      errcode='22023',
      message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id)
     and not public.can_view_skpe_initiatives(formulation_row.organization_id) then
    raise exception using
      errcode='42501',
      message='Acesso negado à Gestão de Riscos da Implementação.';
  end if;

  change_readiness:=public.get_skpe_pem0403_change_readiness(
    target_formulation_id,
    true
  );

  if not coalesce((change_readiness->>'readyForCompletion')::boolean,false) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0404_CHANGE_NOT_READY',
      'severity','blocking',
      'message','PEM-04.04 exige Capacidades e Gestão da Mudança validada em PEM-04.03.'
    ));
  end if;

  select count(*)::integer into selected_initiative_risk_count
  from public.skpe_initiative_risks risk
  join public.skpe_initiative_portfolio_items item
    on item.initiative_id=risk.initiative_id
   and item.formulation_id=target_formulation_id
   and item.selection_status='selected'
  where risk.archived_at is null
    and risk.status<>'archived';

  select count(*)::integer into high_initiative_risk_count
  from public.skpe_initiative_risks risk
  join public.skpe_initiative_portfolio_items item
    on item.initiative_id=risk.initiative_id
   and item.formulation_id=target_formulation_id
   and item.selection_status='selected'
  where risk.archived_at is null
    and risk.status<>'archived'
    and coalesce(risk.inherent_score,0)>=15;

  if exists (
    select 1
    from public.skpe_initiative_risks risk
    join public.skpe_initiative_portfolio_items item
      on item.initiative_id=risk.initiative_id
     and item.formulation_id=target_formulation_id
     and item.selection_status='selected'
    where risk.archived_at is null
      and risk.status<>'archived'
      and coalesce(risk.inherent_score,0)>=15
      and (
        risk.owner_user_id is null
        or risk.response_type is null
        or length(trim(coalesce(risk.response_plan,'')))<10
        or risk.response_due_date is null
        or risk.validation_status<>'validated'
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0404_HIGH_INITIATIVE_RISK_UNMANAGED',
      'severity','blocking',
      'message','Risco alto/crítico de Iniciativa selecionada exige owner, resposta, plano, prazo e validação humana.',
      'affectedCount',(
        select count(*)
        from public.skpe_initiative_risks risk
        join public.skpe_initiative_portfolio_items item
          on item.initiative_id=risk.initiative_id
         and item.formulation_id=target_formulation_id
         and item.selection_status='selected'
        where risk.archived_at is null
          and risk.status<>'archived'
          and coalesce(risk.inherent_score,0)>=15
          and (
            risk.owner_user_id is null
            or risk.response_type is null
            or length(trim(coalesce(risk.response_plan,'')))<10
            or risk.response_due_date is null
            or risk.validation_status<>'validated'
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_initiative_risks risk
    join public.skpe_initiative_portfolio_items item
      on item.initiative_id=risk.initiative_id
     and item.formulation_id=target_formulation_id
     and item.selection_status='selected'
    where risk.archived_at is null
      and risk.status<>'archived'
      and risk.response_type='accept'
      and length(trim(coalesce(risk.metadata->>'acceptanceReason',''))) < 10
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0404_ACCEPTED_RISK_WITHOUT_REASON',
      'severity','blocking',
      'message','Risco de Iniciativa aceito exige justificativa explícita em metadata.acceptanceReason.',
      'affectedCount',(
        select count(*)
        from public.skpe_initiative_risks risk
        join public.skpe_initiative_portfolio_items item
          on item.initiative_id=risk.initiative_id
         and item.formulation_id=target_formulation_id
         and item.selection_status='selected'
        where risk.archived_at is null
          and risk.status<>'archived'
          and risk.response_type='accept'
          and length(trim(coalesce(risk.metadata->>'acceptanceReason',''))) < 10
      )
    ));
  end if;

  select count(*)::integer,
         count(*) filter (where mitigation_required)::integer
  into strategic_risk_count,strategic_risk_requiring_mitigation_count
  from public.skpe_strategic_risk_mitigation_readiness risk
  where risk.project_id=formulation_row.project_id
    and risk.risk_validation_status in ('validated','approved');

  if exists (
    select 1
    from public.skpe_strategic_risk_mitigation_readiness risk
    where risk.project_id=formulation_row.project_id
      and risk.risk_validation_status in ('validated','approved')
      and risk.mitigation_required
      and risk.readiness_status<>'ready'
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0404_STRATEGIC_RISK_MITIGATION_NOT_READY',
      'severity','blocking',
      'message','Risco estratégico que exige mitigação deve possuir mitigação primária vinculada a Iniciativa/Ação com 5W2H completo.',
      'affectedCount',(
        select count(*)
        from public.skpe_strategic_risk_mitigation_readiness risk
        where risk.project_id=formulation_row.project_id
          and risk.risk_validation_status in ('validated','approved')
          and risk.mitigation_required
          and risk.readiness_status<>'ready'
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
    'changeReadiness',change_readiness,
    'readyForCompletion',blocking_count=0,
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'metrics',jsonb_build_object(
      'initiativeRisks',selected_initiative_risk_count,
      'highOrCriticalInitiativeRisks',high_initiative_risk_count,
      'validatedStrategicRisks',strategic_risk_count,
      'strategicRisksRequiringMitigation',strategic_risk_requiring_mitigation_count
    ),
    'authorityPolicy',jsonb_build_object(
      'initiativeRiskAuthority','skpe_initiative_risks',
      'strategicRiskAuthority','skpe_strategic_risk_items',
      'strategicMitigationAuthority','skpe_strategic_risk_mitigation_links/readiness',
      'duplicatesRisk',false,
      'automaticRiskAcceptance',false,
      'automaticMitigationCreation',false
    )
  );
end;
$function$;

revoke all on function public.get_skpe_pem0404_implementation_risk_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem0404_implementation_risk_readiness(uuid)
to authenticated,service_role;

create or replace function public.skpe_guard_pem0404_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
  readiness jsonb;
begin
  if new.code<>'PEM-04.04' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using
      errcode='55000',
      message='PEM-04.04 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0404_implementation_risk_readiness(formulation_id);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-04.04 não pode ser concluída: Riscos da Implementação ainda possuem bloqueadores.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness,
      'riskCreatedAutomatically',false,
      'riskAcceptedAutomatically',false
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0404_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0404_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0404_completion();

comment on function public.get_skpe_pem0404_implementation_risk_readiness(uuid) is
'Canonical PEM-04.04 readiness. Composes initiative risks and strategic-risk mitigation authorities without duplicating risks or creating/accepting mitigation automatically.';

comment on function public.skpe_guard_pem0404_completion() is
'Fail-closed completion guard for PEM-04.04.';
