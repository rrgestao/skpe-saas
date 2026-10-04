-- Govern human validation of causal relations in PEM-02.05.
-- Validation decisions are append-only; the causal relation itself is not rewritten by the decision.

create table if not exists public.skpe_objective_relation_validation_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  project_id uuid not null references public.skpe_projects(id),
  formulation_id uuid not null references public.skpe_strategic_formulations(id),
  relation_id uuid not null references public.skpe_objective_relations(id),
  decision_sequence integer not null,
  decision_action text not null,
  decision_notes text not null,
  decided_by uuid,
  decided_at timestamptz not null default timezone('utc',now()),
  supersedes_event_id uuid references public.skpe_objective_relation_validation_events(id),
  metadata jsonb not null default '{}'::jsonb,
  constraint skpe_relation_validation_action_check
    check (decision_action in ('validate','reject')),
  constraint skpe_relation_validation_sequence_check
    check (decision_sequence > 0),
  constraint skpe_relation_validation_notes_check
    check (length(trim(decision_notes)) >= 10),
  constraint skpe_relation_validation_metadata_object
    check (jsonb_typeof(metadata)='object'),
  constraint skpe_relation_validation_unique_sequence
    unique (relation_id,decision_sequence)
);

create index if not exists idx_skpe_relation_validation_latest
  on public.skpe_objective_relation_validation_events(
    formulation_id,relation_id,decision_sequence desc
  );

alter table public.skpe_objective_relation_validation_events enable row level security;

drop policy if exists skpe_relation_validation_select
  on public.skpe_objective_relation_validation_events;
create policy skpe_relation_validation_select
on public.skpe_objective_relation_validation_events
for select
to authenticated
using (public.can_view_skpe_formulation(organization_id));

revoke insert,update,delete
on public.skpe_objective_relation_validation_events
from anon,authenticated;

grant select
on public.skpe_objective_relation_validation_events
to authenticated;

create or replace function public.record_skpe_objective_relation_validation(
  target_relation_id uuid,
  decision_action text,
  decision_notes text,
  decision_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  relation_row public.skpe_objective_relations%rowtype;
  formulation_row public.skpe_strategic_formulations%rowtype;
  previous_event public.skpe_objective_relation_validation_events%rowtype;
  saved_event public.skpe_objective_relation_validation_events%rowtype;
  next_sequence integer := 1;
  normalized_action text;
begin
  normalized_action:=lower(trim(coalesce(decision_action,'')));

  if normalized_action not in ('validate','reject') then
    raise exception using errcode='22023',message='Decisão de relação causal inválida.';
  end if;

  if length(trim(coalesce(decision_notes,''))) < 10 then
    raise exception using errcode='22023',message='Informe justificativa com pelo menos 10 caracteres.';
  end if;

  if decision_metadata is null or jsonb_typeof(decision_metadata)<>'object' then
    raise exception using errcode='22023',message='decision_metadata deve ser objeto JSON.';
  end if;

  select * into relation_row
  from public.skpe_objective_relations
  where id=target_relation_id;

  if relation_row.id is null then
    raise exception using errcode='22023',message='Relação causal não encontrada.';
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=relation_row.formulation_id;

  if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado para validar relação causal.';
  end if;

  perform public.skpe_assert_formulation_editable(formulation_row.id);

  select * into previous_event
  from public.skpe_objective_relation_validation_events
  where relation_id=relation_row.id
  order by decision_sequence desc
  limit 1;

  if previous_event.id is not null then
    next_sequence:=previous_event.decision_sequence+1;
  end if;

  insert into public.skpe_objective_relation_validation_events(
    organization_id,project_id,formulation_id,relation_id,
    decision_sequence,decision_action,decision_notes,
    decided_by,supersedes_event_id,metadata
  )
  values(
    relation_row.organization_id,relation_row.project_id,relation_row.formulation_id,relation_row.id,
    next_sequence,normalized_action,trim(decision_notes),
    auth.uid(),previous_event.id,
    decision_metadata || jsonb_build_object(
      'gate','PEM-02.05',
      'canonical_relation_mutated',false
    )
  )
  returning * into saved_event;

  perform public.skpe_record_operational_audit(
    saved_event.organization_id,
    saved_event.project_id,
    'objective_relation_validation_event',
    saved_event.id,
    'pem02.05.causal_relation_validation_recorded',
    trim(decision_notes),
    case when previous_event.id is null then null else to_jsonb(previous_event) end,
    to_jsonb(saved_event)
  );

  perform public.skpe_invalidate_strategic_map_package(
    relation_row.formulation_id,
    'Nova decisão humana sobre relação causal exige reavaliação do Mapa Estratégico.'
  );

  return saved_event.id;
end;
$function$;

revoke all on function public.record_skpe_objective_relation_validation(uuid,text,text,jsonb)
from public,anon;
grant execute on function public.record_skpe_objective_relation_validation(uuid,text,text,jsonb)
to authenticated;

-- Readiness wrapper: the canonical map cannot be ready while causal relations
-- remain unvalidated or active objectives are disconnected from the causal graph.
alter function public.get_skpe_strategic_map_readiness(uuid)
  rename to get_skpe_strategic_map_readiness_pre_causal_validation_20261004;

revoke execute on function public.get_skpe_strategic_map_readiness_pre_causal_validation_20261004(uuid)
from public,authenticated;
grant execute on function public.get_skpe_strategic_map_readiness_pre_causal_validation_20261004(uuid)
to service_role;

create or replace function public.get_skpe_strategic_map_readiness(
  target_formulation_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  base_readiness jsonb;
  issues jsonb;
  pending_relation_validation_count integer := 0;
  rejected_relation_count integer := 0;
  disconnected_objective_count integer := 0;
  active_objective_count integer := 0;
  content_blocking_count integer := 0;
  total_blocking_count integer := 0;
begin
  base_readiness:=public.get_skpe_strategic_map_readiness_pre_causal_validation_20261004(
    target_formulation_id
  );
  issues:=coalesce(base_readiness->'issues','[]'::jsonb);

  select count(*) into active_objective_count
  from public.skpe_strategic_objectives
  where formulation_id=target_formulation_id
    and status='active';

  with latest as (
    select distinct on (event.relation_id)
      event.relation_id,
      event.decision_action
    from public.skpe_objective_relation_validation_events event
    where event.formulation_id=target_formulation_id
    order by event.relation_id,event.decision_sequence desc
  )
  select
    count(*) filter (where latest.relation_id is null),
    count(*) filter (where latest.decision_action='reject')
  into pending_relation_validation_count,rejected_relation_count
  from public.skpe_objective_relations relation
  left join latest on latest.relation_id=relation.id
  where relation.formulation_id=target_formulation_id;

  if active_objective_count > 1 then
    select count(*) into disconnected_objective_count
    from public.skpe_strategic_objectives objective
    where objective.formulation_id=target_formulation_id
      and objective.status='active'
      and not exists (
        select 1
        from public.skpe_objective_relations relation
        where relation.formulation_id=target_formulation_id
          and (
            relation.source_objective_id=objective.id
            or relation.target_objective_id=objective.id
          )
      );
  end if;

  if pending_relation_validation_count > 0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','CAUSAL_RELATION_VALIDATION_PENDING',
      'severity','blocking',
      'scope','content',
      'message','Toda relação causal registrada deve possuir decisão humana explícita antes da validação do Mapa Estratégico.',
      'affectedCount',pending_relation_validation_count
    ));
  end if;

  if rejected_relation_count > 0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','CAUSAL_RELATION_REJECTED',
      'severity','blocking',
      'scope','content',
      'message','Existem relações causais rejeitadas que precisam ser removidas ou reformuladas antes da validação do Mapa Estratégico.',
      'affectedCount',rejected_relation_count
    ));
  end if;

  if disconnected_objective_count > 0 then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','OBJECTIVE_WITHOUT_CAUSAL_LINK',
      'severity','blocking',
      'scope','content',
      'message','Todo Objetivo Estratégico ativo deve participar da arquitetura causal do Mapa Estratégico.',
      'affectedCount',disconnected_objective_count
    ));
  end if;

  select
    count(*) filter (
      where item->>'severity'='blocking'
        and item->>'scope'='content'
    )::integer,
    count(*) filter (
      where item->>'severity'='blocking'
    )::integer
  into content_blocking_count,total_blocking_count
  from jsonb_array_elements(issues) item;

  return base_readiness || jsonb_build_object(
    'issues',issues,
    'contentBlockingIssueCount',content_blocking_count,
    'blockingIssueCount',total_blocking_count,
    'readyForValidation',content_blocking_count=0,
    'readyForFormulation',
      content_blocking_count=0
      and coalesce((base_readiness->>'validated')::boolean,false),
    'causalValidation',jsonb_build_object(
      'pendingRelationValidations',pending_relation_validation_count,
      'rejectedRelations',rejected_relation_count,
      'disconnectedObjectives',disconnected_objective_count
    )
  );
end;
$function$;

grant execute on function public.get_skpe_strategic_map_readiness(uuid)
to authenticated,service_role;

comment on table public.skpe_objective_relation_validation_events is
'Append-only human validation ledger for causal relations in PEM-02.05.';

comment on function public.record_skpe_objective_relation_validation(uuid,text,text,jsonb) is
'Records validate/reject decisions for causal relations without mutating the relation itself.';
