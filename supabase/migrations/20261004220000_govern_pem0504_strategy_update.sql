-- Govern PEM-05.04 Strategic Update Decision.
-- The approved formulation is never mutated silently and no revision is created automatically.

create table if not exists public.skpe_strategy_update_decisions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  source_formulation_id uuid not null references public.skpe_strategic_formulations(id) on delete restrict,
  monitoring_cycle_id uuid references public.skpe_monitoring_cycles(id) on delete set null,
  strategy_review_id uuid references public.skpe_strategy_reviews(id) on delete set null,
  decision_sequence integer not null,
  decision_outcome text not null,
  decision_reason text not null,
  target_revision_formulation_id uuid references public.skpe_strategic_formulations(id) on delete restrict,
  supersedes_decision_id uuid references public.skpe_strategy_update_decisions(id) on delete restrict,
  decided_at timestamptz not null default timezone('utc',now()),
  decided_by uuid references public.profiles(id) on delete restrict,
  metadata jsonb not null default '{}'::jsonb,
  constraint skpe_strategy_update_decision_sequence_check check (decision_sequence>=1),
  constraint skpe_strategy_update_decision_outcome_check
    check (decision_outcome in ('no_update_required','revision_required','revision_opened')),
  constraint skpe_strategy_update_decision_reason_check check (length(trim(decision_reason))>=10),
  constraint skpe_strategy_update_decision_not_self_supersede
    check (supersedes_decision_id is null or supersedes_decision_id<>id),
  constraint skpe_strategy_update_decision_sequence_unique
    unique(project_id,source_formulation_id,decision_sequence)
);

create index if not exists idx_skpe_strategy_update_decision_latest
on public.skpe_strategy_update_decisions(
  source_formulation_id,decision_sequence desc
);

alter table public.skpe_strategy_update_decisions enable row level security;

drop policy if exists skpe_strategy_update_decision_select
on public.skpe_strategy_update_decisions;

create policy skpe_strategy_update_decision_select
on public.skpe_strategy_update_decisions
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

revoke all on public.skpe_strategy_update_decisions from anon;
grant select on public.skpe_strategy_update_decisions to authenticated,service_role;

create or replace function public.record_skpe_strategy_update_decision(
  target_formulation_id uuid,
  target_decision_outcome text,
  target_decision_reason text,
  target_revision_formulation_id uuid default null,
  decision_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  critical_readiness jsonb;
  review_id uuid;
  cycle_id uuid;
  revision_row public.skpe_strategic_formulations%rowtype;
  previous_decision_id uuid;
  next_sequence integer;
  saved_id uuid;
begin
  if target_decision_outcome not in (
    'no_update_required',
    'revision_required',
    'revision_opened'
  ) then
    raise exception using errcode='22023',message='Resultado inválido para a decisão de atualização estratégica.';
  end if;

  if length(trim(coalesce(target_decision_reason,'')))<10 then
    raise exception using errcode='22023',message='A decisão de atualização estratégica exige justificativa com pelo menos 10 caracteres.';
  end if;

  if decision_metadata is null or jsonb_typeof(decision_metadata)<>'object' then
    raise exception using errcode='22023',message='decision_metadata deve ser objeto JSON.';
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id
  for update;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if formulation_row.status not in ('approved','superseded') then
    raise exception using errcode='55000',message='A decisão de atualização deve referenciar uma Formulação aprovada ou histórica substituída.';
  end if;

  if not public.can_ratify_skpe_governance(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado para decidir a atualização estratégica.';
  end if;

  critical_readiness:=public.get_skpe_pem0503_learning_readiness(target_formulation_id);

  if not coalesce((critical_readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='A decisão de atualização estratégica exige Aprendizado e Melhoria metodologicamente pronto.',
      detail=critical_readiness::text;
  end if;

  review_id:=nullif(critical_readiness->>'strategyReviewId','')::uuid;
  cycle_id:=nullif(critical_readiness->>'cycleId','')::uuid;

  if target_decision_outcome='no_update_required'
     and target_revision_formulation_id is not null then
    raise exception using errcode='22023',message='Decisão sem atualização necessária não pode apontar revisão-alvo.';
  end if;

  if target_decision_outcome='revision_opened'
     and target_revision_formulation_id is null then
    raise exception using errcode='22023',message='revision_opened exige target_revision_formulation_id.';
  end if;

  if target_revision_formulation_id is not null then
    select * into revision_row
    from public.skpe_strategic_formulations
    where id=target_revision_formulation_id;

    if revision_row.id is null
       or revision_row.project_id<>formulation_row.project_id
       or revision_row.organization_id<>formulation_row.organization_id
       or revision_row.derived_from_formulation_id<>formulation_row.id then
      raise exception using errcode='22023',message='A revisão-alvo deve ser uma revisão formal derivada da Formulação de origem.';
    end if;
  end if;

  select id into previous_decision_id
  from public.skpe_strategy_update_decisions
  where source_formulation_id=formulation_row.id
  order by decision_sequence desc
  limit 1;

  select coalesce(max(decision_sequence),0)+1
  into next_sequence
  from public.skpe_strategy_update_decisions
  where source_formulation_id=formulation_row.id;

  insert into public.skpe_strategy_update_decisions(
    organization_id,project_id,source_formulation_id,
    monitoring_cycle_id,strategy_review_id,
    decision_sequence,decision_outcome,decision_reason,
    target_revision_formulation_id,supersedes_decision_id,
    decided_at,decided_by,metadata
  )
  values(
    formulation_row.organization_id,formulation_row.project_id,formulation_row.id,
    cycle_id,review_id,
    next_sequence,target_decision_outcome,trim(target_decision_reason),
    target_revision_formulation_id,previous_decision_id,
    timezone('utc',now()),auth.uid(),
    decision_metadata || jsonb_build_object(
      'gate','PEM-05.04',
      'revisionCreatedAutomatically',false
    )
  )
  returning id into saved_id;

  perform public.skpe_record_operational_audit(
    formulation_row.organization_id,
    formulation_row.project_id,
    'strategy_update_decision',
    saved_id,
    'pem05.04.strategy_update_decision_recorded',
    trim(target_decision_reason),
    null,
    jsonb_build_object(
      'decision_id',saved_id,
      'decision_outcome',target_decision_outcome,
      'source_formulation_id',formulation_row.id,
      'target_revision_formulation_id',target_revision_formulation_id,
      'supersedes_decision_id',previous_decision_id
    )
  );

  return saved_id;
end;
$function$;

revoke all on function public.record_skpe_strategy_update_decision(uuid,text,text,uuid,jsonb)
from public,anon;
grant execute on function public.record_skpe_strategy_update_decision(uuid,text,text,uuid,jsonb)
to authenticated;

create or replace function public.get_skpe_pem0504_strategy_update_readiness(
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
  learning_readiness jsonb;
  decision_row public.skpe_strategy_update_decisions%rowtype;
  revision_row public.skpe_strategic_formulations%rowtype;
  issues jsonb := '[]'::jsonb;
  blocking_count integer := 0;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado à Atualização Estratégica.';
  end if;

  learning_readiness:=public.get_skpe_pem0503_learning_readiness(target_formulation_id);

  if not coalesce((learning_readiness->>'readyForCompletion')::boolean,false) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0504_LEARNING_NOT_READY',
      'severity','blocking',
      'message','PEM-05.04 exige Aprendizado e Melhoria metodologicamente pronto em PEM-05.03.'
    ));
  end if;

  select * into decision_row
  from public.skpe_strategy_update_decisions
  where source_formulation_id=target_formulation_id
  order by decision_sequence desc
  limit 1;

  if decision_row.id is null then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0504_UPDATE_DECISION_MISSING',
      'severity','blocking',
      'message','Registre decisão institucional explícita sobre a necessidade de atualização da estratégia.'
    ));
  elsif decision_row.decision_outcome='revision_required' then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0504_REVISION_REQUIRED_NOT_OPENED',
      'severity','blocking',
      'message','A revisão foi considerada necessária, mas ainda não existe revisão formal aberta e vinculada.'
    ));
  elsif decision_row.decision_outcome='revision_opened' then
    select * into revision_row
    from public.skpe_strategic_formulations
    where id=decision_row.target_revision_formulation_id;

    if revision_row.id is null
       or revision_row.derived_from_formulation_id<>formulation_row.id
       or revision_row.project_id<>formulation_row.project_id
       or revision_row.status not in (
         'draft','in_elaboration','pending_validation','validated','pending_approval','approved'
       ) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0504_TARGET_REVISION_INVALID',
        'severity','blocking',
        'message','A revisão-alvo não é uma revisão formal válida derivada da Formulação corrente.'
      ));
    end if;
  end if;

  if decision_row.decision_outcome='no_update_required'
     and exists (
       select 1
       from public.skpe_strategic_learnings learning
       where learning.formulation_id=target_formulation_id
         and learning.status in ('accepted','incorporated')
         and learning.target_revision_formulation_id is not null
     ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0504_NO_UPDATE_CONFLICTS_WITH_LEARNING',
      'severity','blocking',
      'message','A decisão de não atualizar conflita com aprendizado aceito/incorporado que já aponta revisão-alvo.'
    ));
  end if;

  if decision_row.decision_outcome='revision_opened'
     and exists (
       select 1
       from public.skpe_strategic_learnings learning
       where learning.formulation_id=target_formulation_id
         and learning.status in ('accepted','incorporated')
         and learning.target_revision_formulation_id is not null
         and learning.target_revision_formulation_id<>decision_row.target_revision_formulation_id
     ) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0504_LEARNING_REVISION_LINEAGE_CONFLICT',
      'severity','blocking',
      'message','Há aprendizado aceito/incorporado apontando revisão diferente da revisão formal da decisão estratégica.'
    ));
  end if;

  select count(*)::integer into blocking_count
  from jsonb_array_elements(issues) issue
  where issue->>'severity'='blocking';

  return jsonb_build_object(
    'formulationId',formulation_row.id,
    'projectId',formulation_row.project_id,
    'organizationId',formulation_row.organization_id,
    'learningReadiness',learning_readiness,
    'strategyUpdateDecisionId',decision_row.id,
    'decisionSequence',decision_row.decision_sequence,
    'decisionOutcome',decision_row.decision_outcome,
    'decisionReason',decision_row.decision_reason,
    'targetRevisionFormulationId',decision_row.target_revision_formulation_id,
    'targetRevisionVersionNumber',revision_row.version_number,
    'targetRevisionStatus',revision_row.status,
    'readyForCompletion',blocking_count=0 and decision_row.id is not null,
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'updatePolicy',jsonb_build_object(
      'revisionAuthority','create_skpe_formulation_revision',
      'mutatesApprovedFormulation',false,
      'createsRevisionAutomatically',false,
      'requiresInstitutionalDecision',true,
      'preservesLineage',true
    )
  );
end;
$function$;

revoke all on function public.get_skpe_pem0504_strategy_update_readiness(uuid)
from public,anon;
grant execute on function public.get_skpe_pem0504_strategy_update_readiness(uuid)
to authenticated,service_role;

create or replace function public.skpe_guard_pem0504_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
  readiness jsonb;
begin
  if new.code<>'PEM-05.04' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using errcode='55000',message='PEM-05.04 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0504_strategy_update_readiness(formulation_id);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-05.04 não pode ser concluída: Atualização Estratégica ainda possui bloqueadores.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'strategyUpdateDecisionId',readiness->>'strategyUpdateDecisionId',
      'decisionOutcome',readiness->>'decisionOutcome',
      'targetRevisionFormulationId',readiness->>'targetRevisionFormulationId',
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness,
      'approvedFormulationMutated',false,
      'revisionCreatedAutomatically',false
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0504_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0504_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0504_completion();

comment on table public.skpe_strategy_update_decisions is
'Append-only institutional decisions for PEM-05.04: no update required, revision required, or formal revision opened. Does not replace the formulation revision authority.';
comment on function public.record_skpe_strategy_update_decision(uuid,text,text,uuid,jsonb) is
'Records an append-only PEM-05.04 institutional update decision. Never creates a formulation revision automatically.';
comment on function public.get_skpe_pem0504_strategy_update_readiness(uuid) is
'Canonical PEM-05.04 readiness. Requires explicit institutional update decision and, when revision is needed, a formal versioned revision created through the canonical formulation authority.';
