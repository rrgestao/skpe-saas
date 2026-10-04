-- Govern PEM-04.01 activation readiness without starting execution.
-- The approved PEM-03.03 portfolio remains the source. This migration does not
-- create, reprioritize, start or complete any initiative/action.

create or replace function public.get_skpe_pem0401_activation_readiness(
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
  portfolio_readiness jsonb;
  issues jsonb := '[]'::jsonb;
  selected_count integer := 0;
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
      message='Acesso negado à prontidão de ativação do Plano de Implementação.';
  end if;

  portfolio_readiness:=public.get_skpe_initiatives_readiness(
    target_formulation_id,
    true
  );

  if not coalesce((portfolio_readiness->>'readyForFormulation')::boolean,false) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0401_PORTFOLIO_NOT_VALIDATED',
      'severity','blocking',
      'message','PEM-04.01 exige o portfólio de Iniciativas validado em PEM-03.03.'
    ));
  end if;

  select count(*)::integer into selected_count
  from public.skpe_initiative_portfolio_items item
  where item.formulation_id=target_formulation_id
    and item.selection_status='selected';

  if selected_count=0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0401_SELECTED_INITIATIVE_MISSING',
      'severity','blocking',
      'message','Não existem Iniciativas selecionadas para ativação.'
    ));
  end if;

  if exists (
    select 1
    from public.skpe_initiative_portfolio_items item
    join public.skpe_initiatives initiative
      on initiative.id=item.initiative_id
    where item.formulation_id=target_formulation_id
      and item.selection_status='selected'
      and (
        initiative.status not in ('approved','planned')
        or initiative.validation_status not in ('validated','validated_with_adjustments')
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0401_INITIATIVE_NOT_READY_TO_PLAN',
      'severity','blocking',
      'message','Toda Iniciativa selecionada deve estar aprovada/planejada e validada antes da ativação.',
      'affectedCount',(
        select count(*)
        from public.skpe_initiative_portfolio_items item
        join public.skpe_initiatives initiative
          on initiative.id=item.initiative_id
        where item.formulation_id=target_formulation_id
          and item.selection_status='selected'
          and (
            initiative.status not in ('approved','planned')
            or initiative.validation_status not in ('validated','validated_with_adjustments')
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_initiative_portfolio_items item
    join public.skpe_initiatives initiative
      on initiative.id=item.initiative_id
    where item.formulation_id=target_formulation_id
      and item.selection_status='selected'
      and (
        initiative.owner_user_id is null
        or initiative.responsible_area_id is null
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0401_INITIATIVE_RESPONSIBILITY_MISSING',
      'severity','blocking',
      'message','Toda Iniciativa selecionada deve possuir responsável e área responsável antes da ativação.',
      'affectedCount',(
        select count(*)
        from public.skpe_initiative_portfolio_items item
        join public.skpe_initiatives initiative
          on initiative.id=item.initiative_id
        where item.formulation_id=target_formulation_id
          and item.selection_status='selected'
          and (
            initiative.owner_user_id is null
            or initiative.responsible_area_id is null
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_initiative_portfolio_items item
    join public.skpe_initiatives initiative
      on initiative.id=item.initiative_id
    where item.formulation_id=target_formulation_id
      and item.selection_status='selected'
      and (
        initiative.start_date is null
        or initiative.due_date is null
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0401_INITIATIVE_HORIZON_MISSING',
      'severity','blocking',
      'message','Toda Iniciativa selecionada deve possuir início e prazo final planejados.',
      'affectedCount',(
        select count(*)
        from public.skpe_initiative_portfolio_items item
        join public.skpe_initiatives initiative
          on initiative.id=item.initiative_id
        where item.formulation_id=target_formulation_id
          and item.selection_status='selected'
          and (
            initiative.start_date is null
            or initiative.due_date is null
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_initiative_portfolio_items item
    where item.formulation_id=target_formulation_id
      and item.selection_status='selected'
      and not exists (
        select 1
        from public.skpe_initiative_actions action
        where action.initiative_id=item.initiative_id
          and action.archived_at is null
          and action.is_required_for_readiness=true
          and action.status not in ('cancelled','archived')
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0401_ACTION_PLAN_MISSING',
      'severity','blocking',
      'message','Toda Iniciativa selecionada deve possuir ao menos uma ação ou marco obrigatório para execução.',
      'affectedCount',(
        select count(*)
        from public.skpe_initiative_portfolio_items item
        where item.formulation_id=target_formulation_id
          and item.selection_status='selected'
          and not exists (
            select 1
            from public.skpe_initiative_actions action
            where action.initiative_id=item.initiative_id
              and action.archived_at is null
              and action.is_required_for_readiness=true
              and action.status not in ('cancelled','archived')
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_initiative_actions action
    join public.skpe_initiative_portfolio_items item
      on item.initiative_id=action.initiative_id
     and item.formulation_id=target_formulation_id
     and item.selection_status='selected'
    where action.archived_at is null
      and action.is_required_for_readiness=true
      and action.status not in ('cancelled','archived')
      and (
        action.validation_status<>'validated'
        or action.responsible_user_id is null
        or action.start_date is null
        or action.due_date is null
      )
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0401_ACTION_NOT_ACTIVATION_READY',
      'severity','blocking',
      'message','Ações obrigatórias devem estar validadas, com responsável, início e prazo definidos.',
      'affectedCount',(
        select count(*)
        from public.skpe_initiative_actions action
        join public.skpe_initiative_portfolio_items item
          on item.initiative_id=action.initiative_id
         and item.formulation_id=target_formulation_id
         and item.selection_status='selected'
        where action.archived_at is null
          and action.is_required_for_readiness=true
          and action.status not in ('cancelled','archived')
          and (
            action.validation_status<>'validated'
            or action.responsible_user_id is null
            or action.start_date is null
            or action.due_date is null
          )
      )
    ));
  end if;

  if exists (
    select 1
    from public.skpe_initiative_actions action
    join public.skpe_initiative_portfolio_items item
      on item.initiative_id=action.initiative_id
     and item.formulation_id=target_formulation_id
     and item.selection_status='selected'
    where action.archived_at is null
      and action.is_required_for_readiness=true
      and action.status in ('in_progress','completed')
  ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0401_EXECUTION_ALREADY_STARTED',
      'severity','blocking',
      'message','Há ação obrigatória já iniciada/concluída antes do fechamento da ativação governada de PEM-04.01.',
      'affectedCount',(
        select count(*)
        from public.skpe_initiative_actions action
        join public.skpe_initiative_portfolio_items item
          on item.initiative_id=action.initiative_id
         and item.formulation_id=target_formulation_id
         and item.selection_status='selected'
        where action.archived_at is null
          and action.is_required_for_readiness=true
          and action.status in ('in_progress','completed')
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
    'portfolioReadiness',portfolio_readiness,
    'readyForActivation',blocking_count=0 and selected_count>0,
    'readyForCompletion',blocking_count=0 and selected_count>0,
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'metrics',jsonb_build_object(
      'selectedInitiatives',selected_count,
      'requiredActions',(
        select count(*)
        from public.skpe_initiative_actions action
        join public.skpe_initiative_portfolio_items item
          on item.initiative_id=action.initiative_id
         and item.formulation_id=target_formulation_id
         and item.selection_status='selected'
        where action.archived_at is null
          and action.is_required_for_readiness=true
          and action.status not in ('cancelled','archived')
      ),
      'validatedRequiredActions',(
        select count(*)
        from public.skpe_initiative_actions action
        join public.skpe_initiative_portfolio_items item
          on item.initiative_id=action.initiative_id
         and item.formulation_id=target_formulation_id
         and item.selection_status='selected'
        where action.archived_at is null
          and action.is_required_for_readiness=true
          and action.status not in ('cancelled','archived')
          and action.validation_status='validated'
      )
    ),
    'activationPolicy',jsonb_build_object(
      'reusesPem0303Portfolio',true,
      'reprioritizesPortfolio',false,
      'startsExecutionAutomatically',false,
      'requiresValidatedActions',true,
      'requiresResponsibility',true,
      'requiresPlannedHorizon',true
    )
  );
end;
$function$;

revoke all on function public.get_skpe_pem0401_activation_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem0401_activation_readiness(uuid)
to authenticated,service_role;

create or replace function public.skpe_guard_pem0401_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  readiness jsonb;
  formulation_id uuid;
begin
  if new.code<>'PEM-04.01' or new.status<>'completed' then
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
      message='PEM-04.01 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0401_activation_readiness(formulation_id);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-04.01 não pode ser concluída: o Plano de Implementação ainda não possui condições governadas de ativação.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness,
      'executionStartedAutomatically',false
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0401_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0401_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0401_completion();

comment on function public.get_skpe_pem0401_activation_readiness(uuid) is
'Canonical readiness for PEM-04.01. Reuses the validated PEM-03.03 portfolio and verifies execution prerequisites without starting or reprioritizing initiatives.';

comment on function public.skpe_guard_pem0401_completion() is
'Fail-closed completion guard for PEM-04.01. Completion records readiness evidence but never starts execution automatically.';
