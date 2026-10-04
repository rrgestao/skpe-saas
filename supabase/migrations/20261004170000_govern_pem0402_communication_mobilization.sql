-- Govern PEM-04.02 Communication and Mobilization.
-- Creates canonical planning records only. It never sends messages automatically.

create table if not exists public.skpe_implementation_communication_packages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  formulation_id uuid not null references public.skpe_strategic_formulations(id) on delete cascade,
  status text not null default 'in_elaboration',
  owner_user_id uuid references public.profiles(id) on delete set null,
  validation_notes text,
  submitted_for_validation_at timestamptz,
  submitted_for_validation_by uuid references public.profiles(id) on delete set null,
  validated_at timestamptz,
  validated_by uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc',now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc',now()),
  updated_by uuid references public.profiles(id) on delete set null,
  constraint skpe_impl_comm_package_unique unique(formulation_id),
  constraint skpe_impl_comm_package_status_check
    check (status in ('in_elaboration','pending_validation','validated','returned_for_adjustment'))
);

create table if not exists public.skpe_implementation_communication_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  formulation_id uuid not null references public.skpe_strategic_formulations(id) on delete cascade,
  package_id uuid not null references public.skpe_implementation_communication_packages(id) on delete cascade,
  audience_label text not null,
  communication_objective text not null,
  key_message text not null,
  channel text not null,
  cadence text not null,
  owner_user_id uuid references public.profiles(id) on delete set null,
  planned_start_date date,
  planned_end_date date,
  mobilization_action text,
  evidence_required boolean not null default false,
  evidence_asset_id uuid references public.sparks_evidence_assets(id) on delete set null,
  status text not null default 'planned',
  validation_status text not null default 'draft',
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc',now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc',now()),
  updated_by uuid references public.profiles(id) on delete set null,
  constraint skpe_impl_comm_item_audience_not_blank check (length(trim(audience_label))>=2),
  constraint skpe_impl_comm_item_objective_not_blank check (length(trim(communication_objective))>=5),
  constraint skpe_impl_comm_item_message_not_blank check (length(trim(key_message))>=5),
  constraint skpe_impl_comm_item_channel_not_blank check (length(trim(channel))>=2),
  constraint skpe_impl_comm_item_cadence_not_blank check (length(trim(cadence))>=2),
  constraint skpe_impl_comm_item_dates_check
    check (planned_end_date is null or planned_start_date is null or planned_end_date>=planned_start_date),
  constraint skpe_impl_comm_item_status_check
    check (status in ('planned','ready','delivered','cancelled','archived')),
  constraint skpe_impl_comm_item_validation_check
    check (validation_status in ('draft','pending_validation','validated','rejected'))
);

create index if not exists idx_skpe_impl_comm_package_scope
on public.skpe_implementation_communication_packages(
  organization_id,project_id,formulation_id,status
);

create index if not exists idx_skpe_impl_comm_item_scope
on public.skpe_implementation_communication_items(
  organization_id,project_id,formulation_id,package_id,status,display_order
);

alter table public.skpe_implementation_communication_packages enable row level security;
alter table public.skpe_implementation_communication_items enable row level security;

drop policy if exists skpe_impl_comm_package_select on public.skpe_implementation_communication_packages;
create policy skpe_impl_comm_package_select
on public.skpe_implementation_communication_packages
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_impl_comm_package_manage on public.skpe_implementation_communication_packages;
create policy skpe_impl_comm_package_manage
on public.skpe_implementation_communication_packages
for all to authenticated
using (public.can_manage_skpe_formulation(organization_id))
with check (public.can_manage_skpe_formulation(organization_id));

drop policy if exists skpe_impl_comm_item_select on public.skpe_implementation_communication_items;
create policy skpe_impl_comm_item_select
on public.skpe_implementation_communication_items
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_impl_comm_item_manage on public.skpe_implementation_communication_items;
create policy skpe_impl_comm_item_manage
on public.skpe_implementation_communication_items
for all to authenticated
using (public.can_manage_skpe_formulation(organization_id))
with check (public.can_manage_skpe_formulation(organization_id));

revoke all on public.skpe_implementation_communication_packages from anon;
revoke all on public.skpe_implementation_communication_items from anon;
grant select,insert,update on public.skpe_implementation_communication_packages to authenticated,service_role;
grant select,insert,update,delete on public.skpe_implementation_communication_items to authenticated,service_role;

create or replace function public.ensure_skpe_pem0402_communication_package(
  target_formulation_id uuid
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_id uuid;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado ao plano de Comunicação e Mobilização.';
  end if;

  insert into public.skpe_implementation_communication_packages(
    organization_id,project_id,formulation_id,created_by,updated_by
  )
  values(
    formulation_row.organization_id,formulation_row.project_id,formulation_row.id,auth.uid(),auth.uid()
  )
  on conflict(formulation_id) do update
    set updated_at=public.skpe_implementation_communication_packages.updated_at
  returning id into package_id;

  return package_id;
end;
$function$;

create or replace function public.upsert_skpe_pem0402_communication_item(
  target_formulation_id uuid,
  target_item_id uuid,
  item_payload jsonb,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_id uuid;
  saved_id uuid;
begin
  perform public.skpe_assert_reason(change_reason);

  if item_payload is null or jsonb_typeof(item_payload)<>'object' then
    raise exception using errcode='22023',message='item_payload deve ser objeto JSON.';
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado ao plano de Comunicação e Mobilização.';
  end if;

  package_id:=public.ensure_skpe_pem0402_communication_package(target_formulation_id);

  if exists (
    select 1
    from public.skpe_implementation_communication_packages p
    where p.id=package_id and p.status='validated'
  ) then
    raise exception using errcode='55000',message='Plano de Comunicação e Mobilização validado é imutável; devolva para ajustes antes de editar.';
  end if;

  if target_item_id is null then
    insert into public.skpe_implementation_communication_items(
      organization_id,project_id,formulation_id,package_id,
      audience_label,communication_objective,key_message,channel,cadence,
      owner_user_id,planned_start_date,planned_end_date,mobilization_action,
      evidence_required,evidence_asset_id,status,validation_status,display_order,
      metadata,created_by,updated_by
    )
    values(
      formulation_row.organization_id,formulation_row.project_id,formulation_row.id,package_id,
      trim(coalesce(item_payload->>'audienceLabel','')),
      trim(coalesce(item_payload->>'communicationObjective','')),
      trim(coalesce(item_payload->>'keyMessage','')),
      trim(coalesce(item_payload->>'channel','')),
      trim(coalesce(item_payload->>'cadence','')),
      nullif(item_payload->>'ownerUserId','')::uuid,
      nullif(item_payload->>'plannedStartDate','')::date,
      nullif(item_payload->>'plannedEndDate','')::date,
      nullif(trim(coalesce(item_payload->>'mobilizationAction','')),''),
      coalesce((item_payload->>'evidenceRequired')::boolean,false),
      nullif(item_payload->>'evidenceAssetId','')::uuid,
      coalesce(nullif(item_payload->>'status',''),'planned'),
      'draft',
      coalesce((item_payload->>'displayOrder')::integer,0),
      coalesce(item_payload->'metadata','{}'::jsonb),
      auth.uid(),auth.uid()
    )
    returning id into saved_id;
  else
    update public.skpe_implementation_communication_items
    set
      audience_label=trim(coalesce(item_payload->>'audienceLabel',audience_label)),
      communication_objective=trim(coalesce(item_payload->>'communicationObjective',communication_objective)),
      key_message=trim(coalesce(item_payload->>'keyMessage',key_message)),
      channel=trim(coalesce(item_payload->>'channel',channel)),
      cadence=trim(coalesce(item_payload->>'cadence',cadence)),
      owner_user_id=coalesce(nullif(item_payload->>'ownerUserId','')::uuid,owner_user_id),
      planned_start_date=coalesce(nullif(item_payload->>'plannedStartDate','')::date,planned_start_date),
      planned_end_date=coalesce(nullif(item_payload->>'plannedEndDate','')::date,planned_end_date),
      mobilization_action=coalesce(nullif(trim(coalesce(item_payload->>'mobilizationAction','')),''),mobilization_action),
      evidence_required=coalesce((item_payload->>'evidenceRequired')::boolean,evidence_required),
      evidence_asset_id=coalesce(nullif(item_payload->>'evidenceAssetId','')::uuid,evidence_asset_id),
      status=coalesce(nullif(item_payload->>'status',''),status),
      validation_status='draft',
      display_order=coalesce((item_payload->>'displayOrder')::integer,display_order),
      metadata=coalesce(item_payload->'metadata',metadata),
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
    where id=target_item_id
      and formulation_id=target_formulation_id
    returning id into saved_id;

    if saved_id is null then
      raise exception using errcode='22023',message='Item de Comunicação e Mobilização não encontrado.';
    end if;
  end if;

  update public.skpe_implementation_communication_packages
  set status='in_elaboration',
      validated_at=null,
      validated_by=null,
      validation_notes=null,
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where id=package_id;

  return saved_id;
end;
$function$;

create or replace function public.get_skpe_pem0402_communication_readiness(
  target_formulation_id uuid,
  include_package_state boolean default true
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_implementation_communication_packages%rowtype;
  activation_readiness jsonb;
  issues jsonb := '[]'::jsonb;
  item_count integer := 0;
  blocking_count integer := 0;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado ao plano de Comunicação e Mobilização.';
  end if;

  activation_readiness:=public.get_skpe_pem0401_activation_readiness(target_formulation_id);

  if not coalesce((activation_readiness->>'readyForCompletion')::boolean,false) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0402_ACTIVATION_NOT_READY',
      'severity','blocking',
      'message','PEM-04.02 exige PEM-04.01 metodologicamente pronto antes da Comunicação e Mobilização.'
    ));
  end if;

  select * into package_row
  from public.skpe_implementation_communication_packages
  where formulation_id=target_formulation_id;

  if package_row.id is null then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0402_PACKAGE_MISSING',
      'severity','blocking',
      'message','Plano de Comunicação e Mobilização ainda não foi configurado.'
    ));
  else
    if package_row.owner_user_id is null then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0402_OWNER_MISSING',
        'severity','blocking',
        'message','Defina o responsável pelo Plano de Comunicação e Mobilização.'
      ));
    end if;

    select count(*)::integer into item_count
    from public.skpe_implementation_communication_items
    where package_id=package_row.id
      and status not in ('cancelled','archived');

    if item_count=0 then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0402_ITEM_MISSING',
        'severity','blocking',
        'message','Inclua ao menos um público/ação no Plano de Comunicação e Mobilização.'
      ));
    end if;

    if exists (
      select 1
      from public.skpe_implementation_communication_items item
      where item.package_id=package_row.id
        and item.status not in ('cancelled','archived')
        and (
          item.owner_user_id is null
          or item.planned_start_date is null
          or length(trim(item.audience_label))<2
          or length(trim(item.communication_objective))<5
          or length(trim(item.key_message))<5
          or length(trim(item.channel))<2
          or length(trim(item.cadence))<2
          or (include_package_state and item.validation_status<>'validated')
        )
    ) then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0402_ITEM_INCOMPLETE',
        'severity','blocking',
        'message','Todo item deve explicitar público, objetivo, mensagem, canal, cadência, responsável, início planejado e validação humana.',
        'affectedCount',(
          select count(*)
          from public.skpe_implementation_communication_items item
          where item.package_id=package_row.id
            and item.status not in ('cancelled','archived')
            and (
              item.owner_user_id is null
              or item.planned_start_date is null
              or length(trim(item.audience_label))<2
              or length(trim(item.communication_objective))<5
              or length(trim(item.key_message))<5
              or length(trim(item.channel))<2
              or length(trim(item.cadence))<2
              or (include_package_state and item.validation_status<>'validated')
            )
        )
      ));
    end if;

    if include_package_state and package_row.status<>'validated' then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0402_PACKAGE_NOT_VALIDATED',
        'severity','blocking',
        'message','Plano de Comunicação e Mobilização ainda não possui validação humana final.'
      ));
    end if;
  end if;

  select count(*)::integer into blocking_count
  from jsonb_array_elements(issues) issue
  where issue->>'severity'='blocking';

  return jsonb_build_object(
    'formulationId',formulation_row.id,
    'projectId',formulation_row.project_id,
    'organizationId',formulation_row.organization_id,
    'packageId',package_row.id,
    'packageStatus',package_row.status,
    'activationReadiness',activation_readiness,
    'readyForValidation',case
      when include_package_state then
        blocking_count=1
        and exists (
          select 1 from jsonb_array_elements(issues) issue
          where issue->>'code'='PEM0402_PACKAGE_NOT_VALIDATED'
        )
      else blocking_count=0
    end,
    'readyForCompletion',blocking_count=0 and (not include_package_state or package_row.status='validated'),
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'metrics',jsonb_build_object(
      'communicationItems',item_count,
      'validatedItems',case when package_row.id is null then 0 else (
        select count(*)
        from public.skpe_implementation_communication_items item
        where item.package_id=package_row.id
          and item.status not in ('cancelled','archived')
          and item.validation_status='validated'
      ) end
    ),
    'deliveryPolicy',jsonb_build_object(
      'automaticSendingEnabled',false,
      'evidenceAuthority','sparks_evidence_assets',
      'humanValidationRequired',true
    )
  );
end;
$function$;

create or replace function public.transition_skpe_pem0402_communication_package(
  target_formulation_id uuid,
  transition_action text,
  decision_notes text,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_row public.skpe_strategic_formulations%rowtype;
  package_row public.skpe_implementation_communication_packages%rowtype;
  readiness jsonb;
  action text;
begin
  perform public.skpe_assert_reason(change_reason);
  action:=lower(trim(coalesce(transition_action,'')));

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if action in ('submit_validation') then
    if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
      raise exception using errcode='42501',message='Acesso negado para submeter o Plano de Comunicação e Mobilização.';
    end if;
  elsif action in ('validate','return_for_adjustments') then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception using errcode='42501',message='Acesso negado para validar o Plano de Comunicação e Mobilização.';
    end if;
  else
    raise exception using errcode='22023',message='Transição inválida do Plano de Comunicação e Mobilização.';
  end if;

  perform public.ensure_skpe_pem0402_communication_package(target_formulation_id);

  select * into package_row
  from public.skpe_implementation_communication_packages
  where formulation_id=target_formulation_id
  for update;

  if action='submit_validation' then
    readiness:=public.get_skpe_pem0402_communication_readiness(target_formulation_id,false);

    if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
      raise exception using
        errcode='55000',
        message='Plano de Comunicação e Mobilização possui pendências antes da submissão.',
        detail=readiness::text;
    end if;

    update public.skpe_implementation_communication_items
    set validation_status=case when validation_status='draft' then 'pending_validation' else validation_status end,
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where package_id=package_row.id
      and status not in ('cancelled','archived');

    update public.skpe_implementation_communication_packages
    set status='pending_validation',
        submitted_for_validation_at=timezone('utc',now()),
        submitted_for_validation_by=auth.uid(),
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=package_row.id;
  elsif action='validate' then
    if length(trim(coalesce(decision_notes,'')))<10 then
      raise exception using errcode='22023',message='A validação exige justificativa com pelo menos 10 caracteres.';
    end if;

    readiness:=public.get_skpe_pem0402_communication_readiness(target_formulation_id,false);

    if not coalesce((readiness->>'readyForValidation')::boolean,false) then
      raise exception using
        errcode='55000',
        message='Plano de Comunicação e Mobilização possui pendências metodológicas antes da validação.',
        detail=readiness::text;
    end if;

    update public.skpe_implementation_communication_items
    set validation_status='validated',
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where package_id=package_row.id
      and status not in ('cancelled','archived');

    update public.skpe_implementation_communication_packages
    set status='validated',
        validation_notes=trim(decision_notes),
        validated_at=timezone('utc',now()),
        validated_by=auth.uid(),
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=package_row.id;
  else
    if length(trim(coalesce(decision_notes,'')))<10 then
      raise exception using errcode='22023',message='O retorno para ajustes exige justificativa com pelo menos 10 caracteres.';
    end if;

    update public.skpe_implementation_communication_items
    set validation_status=case when validation_status='pending_validation' then 'draft' else validation_status end,
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where package_id=package_row.id
      and status not in ('cancelled','archived');

    update public.skpe_implementation_communication_packages
    set status='returned_for_adjustment',
        validation_notes=trim(decision_notes),
        validated_at=null,
        validated_by=null,
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=package_row.id;
  end if;

  return public.get_skpe_pem0402_communication_readiness(target_formulation_id,true);
end;
$function$;

create or replace function public.skpe_guard_pem0402_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
  readiness jsonb;
begin
  if new.code<>'PEM-04.02' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using errcode='55000',message='PEM-04.02 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0402_communication_readiness(formulation_id,true);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-04.02 não pode ser concluída: Comunicação e Mobilização ainda possuem bloqueadores ou plano não validado.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'communicationPackageId',readiness->>'packageId',
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness,
      'automaticSendingPerformed',false
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0402_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0402_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0402_completion();

revoke all on function public.ensure_skpe_pem0402_communication_package(uuid) from public,anon;
revoke all on function public.upsert_skpe_pem0402_communication_item(uuid,uuid,jsonb,text) from public,anon;
revoke all on function public.get_skpe_pem0402_communication_readiness(uuid,boolean) from public,anon;
revoke all on function public.transition_skpe_pem0402_communication_package(uuid,text,text,text) from public,anon;

grant execute on function public.ensure_skpe_pem0402_communication_package(uuid) to authenticated;
grant execute on function public.upsert_skpe_pem0402_communication_item(uuid,uuid,jsonb,text) to authenticated;
grant execute on function public.get_skpe_pem0402_communication_readiness(uuid,boolean) to authenticated,service_role;
grant execute on function public.transition_skpe_pem0402_communication_package(uuid,text,text,text) to authenticated;

comment on table public.skpe_implementation_communication_packages is
'Canonical PEM-04.02 package for Communication and Mobilization of strategy implementation. Planning/validation authority only; no automatic outbound communication.';
comment on table public.skpe_implementation_communication_items is
'Canonical audience/message/channel/cadence items for PEM-04.02. Evidence may reference sparks_evidence_assets.';
