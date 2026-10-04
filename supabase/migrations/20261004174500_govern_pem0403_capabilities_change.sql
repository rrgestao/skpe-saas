-- Govern PEM-04.03 Capacities and Change Management.
-- Reuses SPARKs person-capacity authority; does not duplicate capacity allocation.

create table if not exists public.skpe_implementation_change_packages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  formulation_id uuid not null references public.skpe_strategic_formulations(id) on delete cascade,
  applicability text not null default 'undetermined',
  applicability_reason text,
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
  constraint skpe_impl_change_package_unique unique(formulation_id),
  constraint skpe_impl_change_package_applicability_check
    check (applicability in ('undetermined','applicable','no_material_gap')),
  constraint skpe_impl_change_package_status_check
    check (status in ('in_elaboration','pending_validation','validated','returned_for_adjustment'))
);

create table if not exists public.skpe_implementation_change_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.skpe_projects(id) on delete cascade,
  formulation_id uuid not null references public.skpe_strategic_formulations(id) on delete cascade,
  package_id uuid not null references public.skpe_implementation_change_packages(id) on delete cascade,
  gap_type text not null,
  affected_audience text not null,
  current_state text not null,
  required_state text not null,
  gap_description text not null,
  treatment_action text not null,
  owner_user_id uuid references public.profiles(id) on delete set null,
  target_date date,
  adoption_risk text not null default 'medium',
  capacity_reference_required boolean not null default false,
  evidence_asset_id uuid references public.sparks_evidence_assets(id) on delete set null,
  validation_status text not null default 'draft',
  status text not null default 'planned',
  display_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc',now()),
  created_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default timezone('utc',now()),
  updated_by uuid references public.profiles(id) on delete set null,
  constraint skpe_impl_change_item_gap_type_check
    check (gap_type in ('people_capacity','competency','process','technology','behavior','governance','other')),
  constraint skpe_impl_change_item_audience_not_blank check (length(trim(affected_audience))>=2),
  constraint skpe_impl_change_item_current_not_blank check (length(trim(current_state))>=5),
  constraint skpe_impl_change_item_required_not_blank check (length(trim(required_state))>=5),
  constraint skpe_impl_change_item_gap_not_blank check (length(trim(gap_description))>=5),
  constraint skpe_impl_change_item_treatment_not_blank check (length(trim(treatment_action))>=5),
  constraint skpe_impl_change_item_risk_check
    check (adoption_risk in ('low','medium','high','critical')),
  constraint skpe_impl_change_item_validation_check
    check (validation_status in ('draft','pending_validation','validated','rejected')),
  constraint skpe_impl_change_item_status_check
    check (status in ('planned','in_progress','completed','cancelled','archived'))
);

create index if not exists idx_skpe_impl_change_package_scope
on public.skpe_implementation_change_packages(
  organization_id,project_id,formulation_id,status
);

create index if not exists idx_skpe_impl_change_item_scope
on public.skpe_implementation_change_items(
  organization_id,project_id,formulation_id,package_id,gap_type,status
);

alter table public.skpe_implementation_change_packages enable row level security;
alter table public.skpe_implementation_change_items enable row level security;

drop policy if exists skpe_impl_change_package_select on public.skpe_implementation_change_packages;
create policy skpe_impl_change_package_select
on public.skpe_implementation_change_packages
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_impl_change_package_manage on public.skpe_implementation_change_packages;
create policy skpe_impl_change_package_manage
on public.skpe_implementation_change_packages
for all to authenticated
using (public.can_manage_skpe_formulation(organization_id))
with check (public.can_manage_skpe_formulation(organization_id));

drop policy if exists skpe_impl_change_item_select on public.skpe_implementation_change_items;
create policy skpe_impl_change_item_select
on public.skpe_implementation_change_items
for select to authenticated
using (public.can_view_skpe_formulation(organization_id));

drop policy if exists skpe_impl_change_item_manage on public.skpe_implementation_change_items;
create policy skpe_impl_change_item_manage
on public.skpe_implementation_change_items
for all to authenticated
using (public.can_manage_skpe_formulation(organization_id))
with check (public.can_manage_skpe_formulation(organization_id));

revoke all on public.skpe_implementation_change_packages from anon;
revoke all on public.skpe_implementation_change_items from anon;
grant select,insert,update on public.skpe_implementation_change_packages to authenticated,service_role;
grant select,insert,update,delete on public.skpe_implementation_change_items to authenticated,service_role;

create or replace function public.ensure_skpe_pem0403_change_package(
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
    raise exception using errcode='42501',message='Acesso negado ao plano de Capacidades e Gestão da Mudança.';
  end if;

  insert into public.skpe_implementation_change_packages(
    organization_id,project_id,formulation_id,created_by,updated_by
  )
  values(
    formulation_row.organization_id,formulation_row.project_id,formulation_row.id,auth.uid(),auth.uid()
  )
  on conflict(formulation_id) do update
    set updated_at=public.skpe_implementation_change_packages.updated_at
  returning id into package_id;

  return package_id;
end;
$function$;

create or replace function public.configure_skpe_pem0403_change_package(
  target_formulation_id uuid,
  target_applicability text,
  target_applicability_reason text,
  target_owner_user_id uuid,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  package_id uuid;
  formulation_row public.skpe_strategic_formulations%rowtype;
begin
  perform public.skpe_assert_reason(change_reason);

  if target_applicability not in ('applicable','no_material_gap') then
    raise exception using errcode='22023',message='Aplicabilidade inválida para PEM-04.03.';
  end if;

  if target_applicability='no_material_gap'
     and length(trim(coalesce(target_applicability_reason,'')))<10 then
    raise exception using errcode='22023',message='A ausência de lacunas materiais exige justificativa com pelo menos 10 caracteres.';
  end if;

  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado ao plano de Capacidades e Gestão da Mudança.';
  end if;

  package_id:=public.ensure_skpe_pem0403_change_package(target_formulation_id);

  update public.skpe_implementation_change_packages
  set applicability=target_applicability,
      applicability_reason=nullif(trim(coalesce(target_applicability_reason,'')),''),
      owner_user_id=target_owner_user_id,
      status='in_elaboration',
      validation_notes=null,
      validated_at=null,
      validated_by=null,
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where id=package_id;

  return package_id;
end;
$function$;

create or replace function public.upsert_skpe_pem0403_change_item(
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
  package_row public.skpe_implementation_change_packages%rowtype;
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
    raise exception using errcode='42501',message='Acesso negado ao plano de Capacidades e Gestão da Mudança.';
  end if;

  package_id:=public.ensure_skpe_pem0403_change_package(target_formulation_id);

  select * into package_row
  from public.skpe_implementation_change_packages
  where id=package_id;

  if package_row.status='validated' then
    raise exception using errcode='55000',message='Plano validado é imutável; devolva para ajustes antes de editar.';
  end if;

  if package_row.applicability='no_material_gap' then
    raise exception using errcode='55000',message='Pacote classificado sem lacuna material não pode receber item de lacuna.';
  end if;

  if target_item_id is null then
    insert into public.skpe_implementation_change_items(
      organization_id,project_id,formulation_id,package_id,
      gap_type,affected_audience,current_state,required_state,gap_description,
      treatment_action,owner_user_id,target_date,adoption_risk,
      capacity_reference_required,evidence_asset_id,
      validation_status,status,display_order,metadata,created_by,updated_by
    )
    values(
      formulation_row.organization_id,formulation_row.project_id,formulation_row.id,package_id,
      coalesce(nullif(item_payload->>'gapType',''),'other'),
      trim(coalesce(item_payload->>'affectedAudience','')),
      trim(coalesce(item_payload->>'currentState','')),
      trim(coalesce(item_payload->>'requiredState','')),
      trim(coalesce(item_payload->>'gapDescription','')),
      trim(coalesce(item_payload->>'treatmentAction','')),
      nullif(item_payload->>'ownerUserId','')::uuid,
      nullif(item_payload->>'targetDate','')::date,
      coalesce(nullif(item_payload->>'adoptionRisk',''),'medium'),
      coalesce((item_payload->>'capacityReferenceRequired')::boolean,false),
      nullif(item_payload->>'evidenceAssetId','')::uuid,
      'draft',
      coalesce(nullif(item_payload->>'status',''),'planned'),
      coalesce((item_payload->>'displayOrder')::integer,0),
      coalesce(item_payload->'metadata','{}'::jsonb),
      auth.uid(),auth.uid()
    )
    returning id into saved_id;
  else
    update public.skpe_implementation_change_items
    set gap_type=coalesce(nullif(item_payload->>'gapType',''),gap_type),
        affected_audience=trim(coalesce(item_payload->>'affectedAudience',affected_audience)),
        current_state=trim(coalesce(item_payload->>'currentState',current_state)),
        required_state=trim(coalesce(item_payload->>'requiredState',required_state)),
        gap_description=trim(coalesce(item_payload->>'gapDescription',gap_description)),
        treatment_action=trim(coalesce(item_payload->>'treatmentAction',treatment_action)),
        owner_user_id=coalesce(nullif(item_payload->>'ownerUserId','')::uuid,owner_user_id),
        target_date=coalesce(nullif(item_payload->>'targetDate','')::date,target_date),
        adoption_risk=coalesce(nullif(item_payload->>'adoptionRisk',''),adoption_risk),
        capacity_reference_required=coalesce((item_payload->>'capacityReferenceRequired')::boolean,capacity_reference_required),
        evidence_asset_id=coalesce(nullif(item_payload->>'evidenceAssetId','')::uuid,evidence_asset_id),
        validation_status='draft',
        status=coalesce(nullif(item_payload->>'status',''),status),
        display_order=coalesce((item_payload->>'displayOrder')::integer,display_order),
        metadata=coalesce(item_payload->'metadata',metadata),
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=target_item_id
      and formulation_id=target_formulation_id
    returning id into saved_id;

    if saved_id is null then
      raise exception using errcode='22023',message='Item de Capacidades e Mudança não encontrado.';
    end if;
  end if;

  update public.skpe_implementation_change_packages
  set applicability='applicable',
      status='in_elaboration',
      validation_notes=null,
      validated_at=null,
      validated_by=null,
      updated_at=timezone('utc',now()),
      updated_by=auth.uid()
  where id=package_id;

  return saved_id;
end;
$function$;

create or replace function public.get_skpe_pem0403_change_readiness(
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
  package_row public.skpe_implementation_change_packages%rowtype;
  communication_readiness jsonb;
  issues jsonb := '[]'::jsonb;
  item_count integer := 0;
  capacity_period_count integer := 0;
  capacity_allocation_count integer := 0;
  blocking_count integer := 0;
begin
  select * into formulation_row
  from public.skpe_strategic_formulations
  where id=target_formulation_id;

  if formulation_row.id is null then
    raise exception using errcode='22023',message='Formulação Estratégica não encontrada.';
  end if;

  if not public.can_view_skpe_formulation(formulation_row.organization_id) then
    raise exception using errcode='42501',message='Acesso negado ao plano de Capacidades e Gestão da Mudança.';
  end if;

  communication_readiness:=public.get_skpe_pem0402_communication_readiness(
    target_formulation_id,
    true
  );

  if not coalesce((communication_readiness->>'readyForCompletion')::boolean,false) then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0403_COMMUNICATION_NOT_READY',
      'severity','blocking',
      'message','PEM-04.03 exige Comunicação e Mobilização validada em PEM-04.02.'
    ));
  end if;

  select count(*)::integer into capacity_period_count
  from public.sparks_person_capacity_periods period
  where period.organization_id=formulation_row.organization_id
    and period.status='active';

  select count(*)::integer into capacity_allocation_count
  from public.sparks_person_capacity_allocations allocation
  join public.sparks_person_capacity_periods period
    on period.id=allocation.capacity_period_id
  where period.organization_id=formulation_row.organization_id
    and allocation.status='active';

  select * into package_row
  from public.skpe_implementation_change_packages
  where formulation_id=target_formulation_id;

  if package_row.id is null then
    issues:=issues || jsonb_build_array(jsonb_build_object(
      'code','PEM0403_PACKAGE_MISSING',
      'severity','blocking',
      'message','Avaliação de Capacidades e Gestão da Mudança ainda não foi configurada.'
    ));
  else
    if package_row.owner_user_id is null then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0403_OWNER_MISSING',
        'severity','blocking',
        'message','Defina o responsável pela avaliação de Capacidades e Gestão da Mudança.'
      ));
    end if;

    if package_row.applicability='undetermined' then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0403_APPLICABILITY_UNDETERMINED',
        'severity','blocking',
        'message','Declare se existem lacunas materiais de capacidade/mudança.'
      ));
    elsif package_row.applicability='no_material_gap' then
      if length(trim(coalesce(package_row.applicability_reason,'')))<10 then
        issues:=issues || jsonb_build_array(jsonb_build_object(
          'code','PEM0403_NO_GAP_REASON_MISSING',
          'severity','blocking',
          'message','A ausência de lacunas materiais exige justificativa explícita.'
        ));
      end if;
    else
      select count(*)::integer into item_count
      from public.skpe_implementation_change_items item
      where item.package_id=package_row.id
        and item.status not in ('cancelled','archived');

      if item_count=0 then
        issues:=issues || jsonb_build_array(jsonb_build_object(
          'code','PEM0403_GAP_ITEM_MISSING',
          'severity','blocking',
          'message','Foram declaradas lacunas materiais, mas nenhum item de capacidade/mudança foi registrado.'
        ));
      end if;

      if exists (
        select 1
        from public.skpe_implementation_change_items item
        where item.package_id=package_row.id
          and item.status not in ('cancelled','archived')
          and (
            item.owner_user_id is null
            or item.target_date is null
            or length(trim(item.affected_audience))<2
            or length(trim(item.current_state))<5
            or length(trim(item.required_state))<5
            or length(trim(item.gap_description))<5
            or length(trim(item.treatment_action))<5
            or (include_package_state and item.validation_status<>'validated')
          )
      ) then
        issues:=issues || jsonb_build_array(jsonb_build_object(
          'code','PEM0403_GAP_ITEM_INCOMPLETE',
          'severity','blocking',
          'message','Toda lacuna deve ter público impactado, estado atual/desejado, tratamento, responsável, prazo e validação humana.',
          'affectedCount',(
            select count(*)
            from public.skpe_implementation_change_items item
            where item.package_id=package_row.id
              and item.status not in ('cancelled','archived')
              and (
                item.owner_user_id is null
                or item.target_date is null
                or length(trim(item.affected_audience))<2
                or length(trim(item.current_state))<5
                or length(trim(item.required_state))<5
                or length(trim(item.gap_description))<5
                or length(trim(item.treatment_action))<5
                or (include_package_state and item.validation_status<>'validated')
              )
          )
        ));
      end if;

      if exists (
        select 1
        from public.skpe_implementation_change_items item
        where item.package_id=package_row.id
          and item.status not in ('cancelled','archived')
          and item.gap_type='people_capacity'
          and item.capacity_reference_required=true
      )
      and capacity_period_count=0 then
        issues:=issues || jsonb_build_array(jsonb_build_object(
          'code','PEM0403_CAPACITY_AUTHORITY_MISSING',
          'severity','blocking',
          'message','Há lacuna de capacidade de pessoas que exige referência quantitativa, mas não existem períodos de capacidade ativos na authority SPARKs.'
        ));
      end if;
    end if;

    if include_package_state and package_row.status<>'validated' then
      issues:=issues || jsonb_build_array(jsonb_build_object(
        'code','PEM0403_PACKAGE_NOT_VALIDATED',
        'severity','blocking',
        'message','Plano de Capacidades e Gestão da Mudança ainda não possui validação humana final.'
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
    'applicability',package_row.applicability,
    'communicationReadiness',communication_readiness,
    'readyForValidation',case
      when include_package_state then
        blocking_count=1
        and exists (
          select 1 from jsonb_array_elements(issues) issue
          where issue->>'code'='PEM0403_PACKAGE_NOT_VALIDATED'
        )
      else blocking_count=0
    end,
    'readyForCompletion',blocking_count=0 and (not include_package_state or package_row.status='validated'),
    'blockingIssueCount',blocking_count,
    'issues',issues,
    'metrics',jsonb_build_object(
      'changeItems',item_count,
      'activeCapacityPeriods',capacity_period_count,
      'activeCapacityAllocations',capacity_allocation_count
    ),
    'authorityPolicy',jsonb_build_object(
      'personCapacityAuthority','sparks_person_capacity_periods/allocations',
      'duplicatesCapacityAllocation',false,
      'evidenceAuthority','sparks_evidence_assets',
      'humanValidationRequired',true
    )
  );
end;
$function$;

create or replace function public.transition_skpe_pem0403_change_package(
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
  package_row public.skpe_implementation_change_packages%rowtype;
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

  if action='submit_validation' then
    if not public.can_manage_skpe_formulation(formulation_row.organization_id) then
      raise exception using errcode='42501',message='Acesso negado para submeter PEM-04.03.';
    end if;
  elsif action in ('validate','return_for_adjustments') then
    if not public.can_validate_skpe_formulation(formulation_row.organization_id) then
      raise exception using errcode='42501',message='Acesso negado para validar PEM-04.03.';
    end if;
  else
    raise exception using errcode='22023',message='Transição inválida para PEM-04.03.';
  end if;

  perform public.ensure_skpe_pem0403_change_package(target_formulation_id);

  select * into package_row
  from public.skpe_implementation_change_packages
  where formulation_id=target_formulation_id
  for update;

  readiness:=public.get_skpe_pem0403_change_readiness(target_formulation_id,false);

  if action in ('submit_validation','validate')
     and not coalesce((readiness->>'readyForValidation')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-04.03 possui pendências metodológicas.',
      detail=readiness::text;
  end if;

  if action='submit_validation' then
    update public.skpe_implementation_change_items
    set validation_status=case when validation_status='draft' then 'pending_validation' else validation_status end,
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where package_id=package_row.id
      and status not in ('cancelled','archived');

    update public.skpe_implementation_change_packages
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

    update public.skpe_implementation_change_items
    set validation_status='validated',
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where package_id=package_row.id
      and status not in ('cancelled','archived');

    update public.skpe_implementation_change_packages
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

    update public.skpe_implementation_change_items
    set validation_status=case when validation_status='pending_validation' then 'draft' else validation_status end,
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where package_id=package_row.id
      and status not in ('cancelled','archived');

    update public.skpe_implementation_change_packages
    set status='returned_for_adjustment',
        validation_notes=trim(decision_notes),
        validated_at=null,
        validated_by=null,
        updated_at=timezone('utc',now()),
        updated_by=auth.uid()
    where id=package_row.id;
  end if;

  return public.get_skpe_pem0403_change_readiness(target_formulation_id,true);
end;
$function$;

create or replace function public.skpe_guard_pem0403_completion()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  formulation_id uuid;
  readiness jsonb;
begin
  if new.code<>'PEM-04.03' or new.status<>'completed' then
    return new;
  end if;

  select id into formulation_id
  from public.skpe_strategic_formulations
  where project_id=new.project_id
    and archived_at is null
  order by version_number desc
  limit 1;

  if formulation_id is null then
    raise exception using errcode='55000',message='PEM-04.03 não pode ser concluída sem Formulação Estratégica.';
  end if;

  readiness:=public.get_skpe_pem0403_change_readiness(formulation_id,true);

  if not coalesce((readiness->>'readyForCompletion')::boolean,false) then
    raise exception using
      errcode='55000',
      message='PEM-04.03 não pode ser concluída: Capacidades e Gestão da Mudança ainda possuem bloqueadores ou pacote não validado.',
      detail=readiness::text;
  end if;

  new.metadata:=jsonb_set(
    coalesce(new.metadata,'{}'::jsonb),
    '{completionEvidence}',
    jsonb_build_object(
      'changePackageId',readiness->>'packageId',
      'applicability',readiness->>'applicability',
      'readinessVerifiedAt',timezone('utc',now()),
      'readinessSnapshot',readiness
    ),
    true
  );

  return new;
end;
$function$;

drop trigger if exists skpe_pem0403_completion_guard
on public.skpe_journey_items;

create trigger skpe_pem0403_completion_guard
before update of status,progress
on public.skpe_journey_items
for each row
execute function public.skpe_guard_pem0403_completion();

revoke all on function public.ensure_skpe_pem0403_change_package(uuid) from public,anon;
revoke all on function public.configure_skpe_pem0403_change_package(uuid,text,text,uuid,text) from public,anon;
revoke all on function public.upsert_skpe_pem0403_change_item(uuid,uuid,jsonb,text) from public,anon;
revoke all on function public.get_skpe_pem0403_change_readiness(uuid,boolean) from public,anon;
revoke all on function public.transition_skpe_pem0403_change_package(uuid,text,text,text) from public,anon;

grant execute on function public.ensure_skpe_pem0403_change_package(uuid) to authenticated;
grant execute on function public.configure_skpe_pem0403_change_package(uuid,text,text,uuid,text) to authenticated;
grant execute on function public.upsert_skpe_pem0403_change_item(uuid,uuid,jsonb,text) to authenticated;
grant execute on function public.get_skpe_pem0403_change_readiness(uuid,boolean) to authenticated,service_role;
grant execute on function public.transition_skpe_pem0403_change_package(uuid,text,text,text) to authenticated;

comment on table public.skpe_implementation_change_packages is
'Canonical PEM-04.03 package for capacity gaps and change impacts. Quantitative person capacity remains authoritative in sparks_person_capacity_periods/allocations.';
comment on table public.skpe_implementation_change_items is
'Canonical PEM-04.03 gap/treatment items. Does not duplicate person capacity allocations.';
