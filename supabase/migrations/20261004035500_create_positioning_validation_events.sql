-- SK-PE - Human validation ledger for PEM-02.03 strategic positioning.
-- Decisions are append-only and do not mutate strategic themes/perspectives.
-- Canonical application remains a later, explicit gate.

create table if not exists public.skpe_positioning_validation_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  project_id uuid not null references public.skpe_projects(id),
  formulation_id uuid not null references public.skpe_strategic_formulations(id),
  entity_type text not null,
  entity_id uuid not null,
  entity_code text not null,
  decision_sequence integer not null,
  decision_action text not null,
  proposed_name text,
  proposed_description text,
  rationale text not null,
  evidence_refs jsonb not null default '[]'::jsonb,
  decided_by uuid,
  decided_at timestamptz not null default timezone('utc',now()),
  supersedes_event_id uuid references public.skpe_positioning_validation_events(id),
  metadata jsonb not null default '{}'::jsonb,
  constraint skpe_positioning_validation_entity_type_check
    check (entity_type in ('strategic_theme','bsc_perspective')),
  constraint skpe_positioning_validation_action_check
    check (decision_action in ('keep','adjust','replace','remove')),
  constraint skpe_positioning_validation_sequence_check
    check (decision_sequence > 0),
  constraint skpe_positioning_validation_code_not_blank
    check (length(trim(entity_code)) > 0),
  constraint skpe_positioning_validation_rationale_not_blank
    check (length(trim(rationale)) >= 10),
  constraint skpe_positioning_validation_evidence_refs_array
    check (jsonb_typeof(evidence_refs)='array'),
  constraint skpe_positioning_validation_metadata_object
    check (jsonb_typeof(metadata)='object'),
  constraint skpe_positioning_validation_unique_sequence
    unique (formulation_id,entity_type,entity_id,decision_sequence)
);

create index if not exists idx_skpe_positioning_validation_scope
  on public.skpe_positioning_validation_events(
    organization_id,project_id,formulation_id,entity_type,entity_id,decision_sequence desc
  );

alter table public.skpe_positioning_validation_events enable row level security;

drop policy if exists skpe_positioning_validation_select on public.skpe_positioning_validation_events;
create policy skpe_positioning_validation_select
on public.skpe_positioning_validation_events
for select
to authenticated
using (public.can_view_skpe_journey(organization_id));

revoke insert,update,delete on public.skpe_positioning_validation_events
  from anon,authenticated;

grant select on public.skpe_positioning_validation_events to authenticated;

create or replace function public.record_skpe_positioning_validation_decision(
  target_formulation_id uuid,
  target_entity_type text,
  target_entity_id uuid,
  decision_action text,
  proposed_name text,
  proposed_description text,
  decision_rationale text,
  evidence_refs jsonb default '[]'::jsonb,
  decision_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  normalized_entity_type text;
  normalized_action text;
  target_code text;
  target_status text;
  target_metadata jsonb;
  previous_event public.skpe_positioning_validation_events%rowtype;
  next_sequence integer := 1;
  saved_event public.skpe_positioning_validation_events%rowtype;
  normalized_proposed_name text;
  normalized_proposed_description text;
begin
  if target_formulation_id is null or target_entity_id is null then
    raise exception using errcode='22023',message='Formulação e entidade são obrigatórias.';
  end if;

  normalized_entity_type:=lower(trim(coalesce(target_entity_type,'')));
  normalized_action:=lower(trim(coalesce(decision_action,'')));
  normalized_proposed_name:=nullif(trim(coalesce(proposed_name,'')),'');
  normalized_proposed_description:=nullif(trim(coalesce(proposed_description,'')),'');

  if normalized_entity_type not in ('strategic_theme','bsc_perspective') then
    raise exception using errcode='22023',message='Tipo de entidade inválido para PEM-02.03.';
  end if;

  if normalized_action not in ('keep','adjust','replace','remove') then
    raise exception using errcode='22023',message='Decisão inválida para PEM-02.03.';
  end if;

  if length(trim(coalesce(decision_rationale,''))) < 10 then
    raise exception using errcode='22023',message='Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if evidence_refs is null or jsonb_typeof(evidence_refs)<>'array' then
    raise exception using errcode='22023',message='evidence_refs deve ser um array JSON.';
  end if;

  if decision_metadata is null or jsonb_typeof(decision_metadata)<>'object' then
    raise exception using errcode='22023',message='decision_metadata deve ser um objeto JSON.';
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado para validar o Posicionamento Estratégico.';
  end if;

  perform public.skpe_assert_formulation_editable(target_formulation_id);

  if normalized_entity_type='strategic_theme' then
    select code,status,metadata
    into target_code,target_status,target_metadata
    from public.skpe_strategic_themes
    where id=target_entity_id
      and formulation_id=target_formulation_id
      and organization_id=formulation_row.organization_id
      and project_id=formulation_row.project_id;
  else
    select code,status,metadata
    into target_code,target_status,target_metadata
    from public.skpe_bsc_perspectives
    where id=target_entity_id
      and formulation_id=target_formulation_id
      and organization_id=formulation_row.organization_id
      and project_id=formulation_row.project_id;
  end if;

  if target_code is null then
    raise exception using errcode='22023',message='Entidade de Posicionamento não encontrada no escopo da Formulação.';
  end if;

  if coalesce(target_metadata->>'validation_status','') in ('validated','approved') then
    raise exception using errcode='55000',message='Entidade já validada exige transição governada específica para reabertura.';
  end if;

  if normalized_action in ('adjust','replace')
     and normalized_proposed_name is null
     and normalized_proposed_description is null then
    raise exception using errcode='22023',message='Ajustar/Substituir exige nome ou descrição proposta.';
  end if;

  select * into previous_event
  from public.skpe_positioning_validation_events
  where formulation_id=target_formulation_id
    and entity_type=normalized_entity_type
    and entity_id=target_entity_id
  order by decision_sequence desc
  limit 1;

  if previous_event.id is not null then
    next_sequence:=previous_event.decision_sequence+1;
  end if;

  insert into public.skpe_positioning_validation_events(
    organization_id,project_id,formulation_id,
    entity_type,entity_id,entity_code,decision_sequence,decision_action,
    proposed_name,proposed_description,rationale,evidence_refs,
    decided_by,supersedes_event_id,metadata
  )
  values(
    formulation_row.organization_id,formulation_row.project_id,formulation_row.id,
    normalized_entity_type,target_entity_id,target_code,next_sequence,normalized_action,
    case when normalized_action in ('adjust','replace') then normalized_proposed_name else null end,
    case when normalized_action in ('adjust','replace') then normalized_proposed_description else null end,
    trim(decision_rationale),evidence_refs,
    auth.uid(),previous_event.id,
    decision_metadata || jsonb_build_object(
      'gate','PEM-02.03',
      'source_entity_status',target_status,
      'source_validation_status',target_metadata->>'validation_status',
      'source_status',target_metadata->>'source_status',
      'canonical_mutation_applied',false,
      'next_gate','PEM-02.03_CONSOLIDATION'
    )
  )
  returning * into saved_event;

  perform public.skpe_record_operational_audit(
    saved_event.organization_id,
    saved_event.project_id,
    'positioning_validation_event',
    saved_event.id,
    'pem02.03.positioning_validation_recorded',
    trim(decision_rationale),
    case when previous_event.id is null then null else to_jsonb(previous_event) end,
    to_jsonb(saved_event)
  );

  return saved_event.id;
end;
$function$;

revoke all on function public.record_skpe_positioning_validation_decision(
  uuid,text,uuid,text,text,text,text,jsonb,jsonb
) from public,anon;

grant execute on function public.record_skpe_positioning_validation_decision(
  uuid,text,uuid,text,text,text,text,jsonb,jsonb
) to authenticated;

comment on table public.skpe_positioning_validation_events is
'Append-only human validation ledger for PEM-02.03. Recording a decision never mutates the canonical theme/perspective.';
