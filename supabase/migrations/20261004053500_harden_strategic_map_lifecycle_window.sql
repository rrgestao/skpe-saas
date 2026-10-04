-- Harden PEM-02.05 edit/validation window at the database boundary.
-- Initial map work is allowed only while PEM-02.05 is in progress.
-- Later changes are allowed only through an explicit begin_revision workflow.

create or replace function public.skpe_strategic_map_edit_window_open(
  target_formulation_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  stage_status text;
  package_row public.skpe_strategic_map_packages%rowtype;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    return false;
  end if;

  select status into stage_status
  from public.skpe_journey_items
  where project_id=formulation_row.project_id
    and archived_at is null
    and code='PEM-02.05'
  limit 1;

  if stage_status='in_progress' then
    return true;
  end if;

  select * into package_row
  from public.skpe_strategic_map_packages
  where formulation_id=target_formulation_id;

  return coalesce(
    package_row.status='in_elaboration'
    and package_row.metadata ? 'revisionOfOfficialVersionId',
    false
  );
end;
$function$;

revoke all on function public.skpe_strategic_map_edit_window_open(uuid)
from public,anon,authenticated;
grant execute on function public.skpe_strategic_map_edit_window_open(uuid)
to service_role;

create or replace function public.skpe_guard_strategic_map_content_edit_window()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
begin
  if auth.uid() is null then
    return case when tg_op='DELETE' then old else new end;
  end if;

  formulation_id:=case when tg_op='DELETE' then old.formulation_id else new.formulation_id end;

  if not public.skpe_strategic_map_edit_window_open(formulation_id) then
    raise exception using
      errcode='55000',
      message='O conteúdo do Mapa Estratégico só pode ser alterado durante PEM-02.05 ou em revisão formal iniciada por begin_revision.';
  end if;

  return case when tg_op='DELETE' then old else new end;
end;
$function$;

drop trigger if exists skpe_objective_relations_edit_window_guard
on public.skpe_objective_relations;

create trigger skpe_objective_relations_edit_window_guard
before insert or update or delete
on public.skpe_objective_relations
for each row
execute function public.skpe_guard_strategic_map_content_edit_window();

drop trigger if exists skpe_relation_validation_edit_window_guard
on public.skpe_objective_relation_validation_events;

create trigger skpe_relation_validation_edit_window_guard
before insert
on public.skpe_objective_relation_validation_events
for each row
execute function public.skpe_guard_strategic_map_content_edit_window();

-- Harden the package lifecycle itself.
alter function public.transition_skpe_strategic_map(uuid,text,text,text)
rename to transition_skpe_strategic_map_pre_pem0205_guard_20261004;

revoke execute on function public.transition_skpe_strategic_map_pre_pem0205_guard_20261004(uuid,text,text,text)
from public,authenticated;
grant execute on function public.transition_skpe_strategic_map_pre_pem0205_guard_20261004(uuid,text,text,text)
to service_role;

create or replace function public.transition_skpe_strategic_map(
  target_formulation_id uuid,
  transition_action text,
  decision_notes text default null,
  change_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  normalized_action text;
begin
  normalized_action:=lower(trim(coalesce(transition_action,'')));

  if normalized_action in ('submit_validation','validate','return_for_adjustments')
     and auth.uid() is not null
     and not public.skpe_strategic_map_edit_window_open(target_formulation_id) then
    raise exception using
      errcode='55000',
      message='O workflow inicial do Mapa Estratégico só pode avançar durante PEM-02.05.';
  end if;

  if normalized_action='validate'
     and length(trim(coalesce(decision_notes,''))) < 10 then
    raise exception using
      errcode='22023',
      message='A validação do Mapa Estratégico exige justificativa humana com pelo menos 10 caracteres.';
  end if;

  return public.transition_skpe_strategic_map_pre_pem0205_guard_20261004(
    target_formulation_id,
    transition_action,
    decision_notes,
    change_reason
  );
end;
$function$;

grant execute on function public.transition_skpe_strategic_map(uuid,text,text,text)
to authenticated,service_role;

comment on function public.skpe_strategic_map_edit_window_open(uuid) is
'Allows initial Map edits only in PEM-02.05 and later edits only inside explicit begin_revision.';
