-- ============================================================
-- SK-PE-CONT-01
-- 17-B.5F.3C.6E
-- Governed Responsibilities for Initiative Actions
--
-- Authority:
--   public.sparks_responsibility_assignments
--
-- Object:
--   object_type = 'initiative_action'
--   object_id   = public.sparks_initiative_actions.id
--
-- Out of scope:
--   roll-up, Kanban, Gantt, agenda, costs, effort,
--   automatic skpe_* <-> sparks_* synchronization.
-- ============================================================

begin;

-- ============================================================
-- 1. HARDEN TRANSVERSAL RESPONSIBILITY AUTHORITY
--
-- Responsibilities remain readable according to RLS.
-- Mutations by authenticated users must happen only through
-- governed RPC contracts.
-- ============================================================

revoke insert, update, delete
on table public.sparks_responsibility_assignments
from authenticated;

grant select
on table public.sparks_responsibility_assignments
to authenticated;

grant select, insert, update, delete
on table public.sparks_responsibility_assignments
to service_role;

drop policy if exists sparks_responsibility_assignments_manage_policy
on public.sparks_responsibility_assignments;

-- ============================================================
-- 2. HARDEN LEGACY RESPONSIBILITY RPC SURFACE
--
-- These functions contain their own authorization checks, but
-- SECURITY DEFINER routines must not remain executable by anon
-- or PUBLIC.
-- ============================================================

revoke all on function public.assign_sparks_responsibility(
  uuid, text, text, uuid, uuid, text, numeric, date, date, text
) from public, anon;

revoke all on function public.assign_skpe_responsibility(
  uuid, text, uuid, uuid, text, numeric, text, date, date, text, text
) from public, anon;

revoke all on function public.end_skpe_responsibility(
  uuid, date, text
) from public, anon;

revoke all on function public.get_skpe_responsibility_assignments(
  uuid, text, uuid, boolean
) from public, anon;

grant execute on function public.assign_sparks_responsibility(
  uuid, text, text, uuid, uuid, text, numeric, date, date, text
) to authenticated, service_role;

grant execute on function public.assign_skpe_responsibility(
  uuid, text, uuid, uuid, text, numeric, text, date, date, text, text
) to authenticated, service_role;

grant execute on function public.end_skpe_responsibility(
  uuid, date, text
) to authenticated, service_role;

grant execute on function public.get_skpe_responsibility_assignments(
  uuid, text, uuid, boolean
) to authenticated, service_role;

-- ============================================================
-- 2B. LEGACY RPC BYPASS HARDENING
--
-- initiative_action is reserved for the governed 6E contracts.
-- Legacy generic/SK-PE RPCs remain available for other object
-- types but cannot create or terminate action responsibilities.
-- ============================================================

create or replace function public.assign_sparks_responsibility(
  target_organization_id uuid,
  target_module_code text,
  target_object_type text,
  target_object_id uuid,
  target_organization_person_id uuid,
  target_responsibility_type text,
  target_allocation_percentage numeric default null,
  target_valid_from date default null,
  target_valid_until date default null,
  target_assignment_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  assignment_id uuid;
  normalized_object_type text;
begin
  if not public.can_manage_sparks_people(target_organization_id) then
    raise exception
      'Acesso negado: o usuário não pode atribuir responsabilidades nesta organização.'
      using errcode = '42501';
  end if;

  normalized_object_type :=
    lower(trim(coalesce(target_object_type, '')));

  if normalized_object_type in (
    'initiative_action',
    'sparks_initiative_action'
  ) then
    raise exception
      'Responsabilidades de ações de iniciativas devem usar o contrato governado específico.'
      using errcode = '55000';
  end if;

  if length(trim(coalesce(target_assignment_reason, ''))) < 10 then
    raise exception
      'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if not exists (
    select 1
    from public.sparks_organization_people relationship
    where relationship.id = target_organization_person_id
      and relationship.organization_id = target_organization_id
      and relationship.status = 'active'
      and (
        relationship.end_date is null
        or relationship.end_date >= current_date
      )
  ) then
    raise exception
      'A pessoa selecionada não possui vínculo ativo com a organização.';
  end if;

  insert into public.sparks_responsibility_assignments (
    organization_id,
    module_code,
    object_type,
    object_id,
    organization_person_id,
    responsibility_type,
    allocation_percentage,
    valid_from,
    valid_until,
    status,
    assignment_reason,
    created_by,
    updated_by
  )
  values (
    target_organization_id,
    upper(trim(target_module_code)),
    trim(target_object_type),
    target_object_id,
    target_organization_person_id,
    target_responsibility_type,
    target_allocation_percentage,
    target_valid_from,
    target_valid_until,
    'active',
    trim(target_assignment_reason),
    auth.uid(),
    auth.uid()
  )
  returning id into assignment_id;

  return assignment_id;
end;
$function$;

create or replace function public.assign_skpe_responsibility(
  target_organization_id uuid,
  target_object_type text,
  target_object_id uuid,
  target_organization_person_id uuid,
  target_responsibility_type text,
  target_allocation_percentage numeric,
  target_authority_level text,
  target_valid_from date,
  target_valid_until date,
  target_assignment_reason text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  assignment_id uuid;
  new_record jsonb;
  normalized_object_type text;
begin
  if not public.can_manage_skpe_governance(target_organization_id) then
    raise exception
      'Acesso negado para atribuir responsabilidades.';
  end if;

  perform public.skpe_assert_reason(change_reason);

  normalized_object_type :=
    lower(trim(coalesce(target_object_type, '')));

  if normalized_object_type in (
    'initiative_action',
    'sparks_initiative_action'
  ) then
    raise exception
      'Responsabilidades de ações de iniciativas devem usar o contrato governado específico.'
      using errcode = '55000';
  end if;

  if length(trim(coalesce(target_object_type, ''))) = 0 then
    raise exception
      'Informe o tipo do objeto estratégico.';
  end if;

  if target_object_id is null then
    raise exception
      'Informe o objeto estratégico.';
  end if;

  if not exists (
    select 1
    from public.sparks_organization_people
    where id = target_organization_person_id
      and organization_id = target_organization_id
      and status = 'active'
  ) then
    raise exception
      'Pessoa não vinculada ou inativa na organização.';
  end if;

  insert into public.sparks_responsibility_assignments (
    organization_id,
    module_code,
    object_type,
    object_id,
    organization_person_id,
    responsibility_type,
    allocation_percentage,
    authority_level,
    valid_from,
    valid_until,
    status,
    assignment_reason,
    assignment_source,
    created_by,
    updated_by
  )
  values (
    target_organization_id,
    'SK-PE',
    trim(target_object_type),
    target_object_id,
    target_organization_person_id,
    target_responsibility_type,
    target_allocation_percentage,
    nullif(trim(target_authority_level), ''),
    target_valid_from,
    target_valid_until,
    'active',
    nullif(trim(target_assignment_reason), ''),
    'manual',
    auth.uid(),
    auth.uid()
  )
  returning id into assignment_id;

  select to_jsonb(responsibility)
  into new_record
  from public.sparks_responsibility_assignments responsibility
  where responsibility.id = assignment_id;

  perform public.skpe_record_operational_audit(
    target_organization_id,
    null,
    'responsibility_assignment',
    assignment_id,
    'assign',
    change_reason,
    null,
    new_record
  );

  return assignment_id;
end;
$function$;

create or replace function public.end_skpe_responsibility(
  target_assignment_id uuid,
  target_end_date date,
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  target_organization_id uuid;
  previous_record jsonb;
  new_record jsonb;
  normalized_object_type text;
begin
  select
    responsibility.organization_id,
    to_jsonb(responsibility)
  into
    target_organization_id,
    previous_record
  from public.sparks_responsibility_assignments responsibility
  where responsibility.id = target_assignment_id
    and responsibility.module_code = 'SK-PE';

  if target_organization_id is null then
    raise exception
      'Responsabilidade não encontrada.';
  end if;

  if not public.can_manage_skpe_governance(target_organization_id) then
    raise exception
      'Acesso negado para encerrar responsabilidades.';
  end if;

  perform public.skpe_assert_reason(change_reason);

  normalized_object_type :=
    lower(trim(coalesce(previous_record ->> 'object_type', '')));

  if normalized_object_type in (
    'initiative_action',
    'sparks_initiative_action'
  ) then
    raise exception
      'Responsabilidades de ações de iniciativas devem usar o contrato governado específico.'
      using errcode = '55000';
  end if;

  update public.sparks_responsibility_assignments
  set
    status = 'ended',
    valid_until = coalesce(target_end_date, current_date),
    updated_by = auth.uid()
  where id = target_assignment_id;

  select to_jsonb(responsibility)
  into new_record
  from public.sparks_responsibility_assignments responsibility
  where responsibility.id = target_assignment_id;

  perform public.skpe_record_operational_audit(
    target_organization_id,
    null,
    'responsibility_assignment',
    target_assignment_id,
    'end',
    change_reason,
    previous_record,
    new_record
  );
end;
$function$;

-- Reassert the intended privilege surface after replacement.

revoke all on function public.assign_sparks_responsibility(
  uuid, text, text, uuid, uuid, text, numeric, date, date, text
) from public, anon;

revoke all on function public.assign_skpe_responsibility(
  uuid, text, uuid, uuid, text, numeric, text, date, date, text, text
) from public, anon;

revoke all on function public.end_skpe_responsibility(
  uuid, date, text
) from public, anon;

grant execute on function public.assign_sparks_responsibility(
  uuid, text, text, uuid, uuid, text, numeric, date, date, text
) to authenticated, service_role;

grant execute on function public.assign_skpe_responsibility(
  uuid, text, uuid, uuid, text, numeric, text, date, date, text, text
) to authenticated, service_role;

grant execute on function public.end_skpe_responsibility(
  uuid, date, text
) to authenticated, service_role;
-- ============================================================
-- 3. GOVERNED ASSIGNMENT CONTRACT
-- ============================================================

create or replace function public.assign_sparks_initiative_action_responsibility(
  target_action_id uuid,
  target_organization_person_id uuid,
  target_responsibility_type text,
  target_allocation_percentage numeric,
  target_authority_level text,
  target_valid_from date,
  target_valid_until date,
  target_assignment_reason text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();

  target_action public.sparks_initiative_actions%rowtype;
  target_person public.sparks_organization_people%rowtype;

  normalized_responsibility_type text;
  normalized_authority_level text;
  normalized_assignment_reason text;
  normalized_change_reason text;

  assignment_id uuid;
  new_record jsonb;
begin
  if current_user_id is null then
    raise exception 'Authentication required.'
      using errcode = '42501';
  end if;

  normalized_responsibility_type :=
    lower(trim(coalesce(target_responsibility_type, '')));

  normalized_authority_level :=
    nullif(lower(trim(coalesce(target_authority_level, ''))), '');

  normalized_change_reason :=
    nullif(trim(coalesce(change_reason, '')), '');

  normalized_assignment_reason :=
    coalesce(
      nullif(trim(coalesce(target_assignment_reason, '')), ''),
      normalized_change_reason
    );

  if target_action_id is null then
    raise exception 'Action is required.'
      using errcode = '22023';
  end if;

  if target_organization_person_id is null then
    raise exception 'Organization person is required.'
      using errcode = '22023';
  end if;

  if length(coalesce(normalized_change_reason, '')) < 10 then
    raise exception 'Change reason must contain at least 10 characters.'
      using errcode = '22023';
  end if;

  if length(normalized_responsibility_type) = 0 then
    raise exception 'Responsibility type is required.'
      using errcode = '22023';
  end if;

  if target_allocation_percentage is not null
     and (
       target_allocation_percentage < 0
       or target_allocation_percentage > 100
     ) then
    raise exception 'Allocation percentage must be between 0 and 100.'
      using errcode = '22023';
  end if;

  if target_valid_until is not null
     and target_valid_from is not null
     and target_valid_until < target_valid_from then
    raise exception 'Responsibility validity dates are inconsistent.'
      using errcode = '22023';
  end if;

  select action.*
  into target_action
  from public.sparks_initiative_actions action
  where action.id = target_action_id;

  if target_action.id is null then
    raise exception 'Initiative action not found.'
      using errcode = 'P0002';
  end if;

  if target_action.status in (
    'completed',
    'cancelled',
    'archived'
  ) then
    raise exception
      'New responsibilities cannot be assigned to a terminal initiative action.'
      using errcode = '55000';
  end if;

  if not public.can_manage_sparks_initiatives(
    target_action.organization_id,
    target_action.source_module_code
  ) then
    raise exception
      'Access denied to manage responsibilities for this initiative action.'
      using errcode = '42501';
  end if;

  select relationship.*
  into target_person
  from public.sparks_organization_people relationship
  join public.sparks_people person
    on person.id = relationship.person_id
  where relationship.id = target_organization_person_id
    and relationship.organization_id = target_action.organization_id
    and relationship.status = 'active'
    and (
      relationship.start_date is null
      or relationship.start_date <= current_date
    )
    and (
      relationship.end_date is null
      or relationship.end_date >= current_date
    )
    and person.person_status = 'active';

  if target_person.id is null then
    raise exception
      'Person does not have an active relationship with the action organization.'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.sparks_domains domain
    join public.sparks_domain_values value
      on value.domain_id = domain.id
    where domain.code = 'RESPONSIBILITY_TYPE'
      and domain.active
      and value.active
      and value.code = normalized_responsibility_type
      and (
        domain.scope_type = 'global'
        or (
          domain.scope_type = 'organization'
          and domain.organization_id = target_action.organization_id
        )
      )
      and (
        value.valid_from is null
        or value.valid_from <= current_date
      )
      and (
        value.valid_until is null
        or value.valid_until >= current_date
      )
  ) then
    raise exception 'Invalid or inactive responsibility type.'
      using errcode = '22023';
  end if;

  if normalized_authority_level is not null
     and not exists (
       select 1
       from public.sparks_domains domain
       join public.sparks_domain_values value
         on value.domain_id = domain.id
       where domain.code = 'AUTHORITY_LEVEL'
         and domain.active
         and value.active
         and value.code = normalized_authority_level
         and (
           domain.scope_type = 'global'
           or (
             domain.scope_type = 'organization'
             and domain.organization_id = target_action.organization_id
           )
         )
         and (
           value.valid_from is null
           or value.valid_from <= current_date
         )
         and (
           value.valid_until is null
           or value.valid_until >= current_date
         )
     ) then
    raise exception 'Invalid or inactive authority level.'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from public.sparks_responsibility_assignments responsibility
    where responsibility.organization_id = target_action.organization_id
      and responsibility.module_code = target_action.source_module_code
      and responsibility.object_type = 'initiative_action'
      and responsibility.object_id = target_action.id
      and responsibility.organization_person_id =
          target_organization_person_id
      and responsibility.responsibility_type =
          normalized_responsibility_type
      and responsibility.status = 'active'
  ) then
    raise exception
      'An active responsibility of this type already exists for this person and action.'
      using errcode = '23505';
  end if;

  insert into public.sparks_responsibility_assignments (
    organization_id,
    module_code,
    object_type,
    object_id,
    organization_person_id,
    responsibility_type,
    allocation_percentage,
    authority_level,
    valid_from,
    valid_until,
    status,
    assignment_reason,
    assignment_source,
    created_by,
    updated_by
  )
  values (
    target_action.organization_id,
    target_action.source_module_code,
    'initiative_action',
    target_action.id,
    target_organization_person_id,
    normalized_responsibility_type,
    target_allocation_percentage,
    normalized_authority_level,
    target_valid_from,
    target_valid_until,
    'active',
    normalized_assignment_reason,
    'manual',
    current_user_id,
    current_user_id
  )
  returning id into assignment_id;

  select to_jsonb(responsibility)
  into new_record
  from public.sparks_responsibility_assignments responsibility
  where responsibility.id = assignment_id;

  insert into public.sparks_initiative_action_audit (
    organization_id,
    initiative_id,
    action_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    target_action.organization_id,
    target_action.initiative_id,
    target_action.id,
    current_user_id,
    target_action.source_module_code,
    'initiative_action_responsibility_assigned',
    normalized_change_reason,
    null,
    new_record
  );

  return assignment_id;
end;
$function$;

-- ============================================================
-- 4. GOVERNED END CONTRACT
-- ============================================================

create or replace function public.end_sparks_initiative_action_responsibility(
  target_assignment_id uuid,
  target_end_date date,
  change_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();

  target_assignment public.sparks_responsibility_assignments%rowtype;
  target_action public.sparks_initiative_actions%rowtype;

  effective_end_date date;
  normalized_change_reason text;

  previous_record jsonb;
  new_record jsonb;
begin
  if current_user_id is null then
    raise exception 'Authentication required.'
      using errcode = '42501';
  end if;

  normalized_change_reason :=
    nullif(trim(coalesce(change_reason, '')), '');

  if length(coalesce(normalized_change_reason, '')) < 10 then
    raise exception 'Change reason must contain at least 10 characters.'
      using errcode = '22023';
  end if;

  select responsibility.*
  into target_assignment
  from public.sparks_responsibility_assignments responsibility
  where responsibility.id = target_assignment_id
    and responsibility.object_type = 'initiative_action';

  if target_assignment.id is null then
    raise exception 'Initiative action responsibility not found.'
      using errcode = 'P0002';
  end if;

  if target_assignment.status not in (
    'active',
    'planned',
    'suspended'
  ) then
    raise exception
      'Responsibility is already terminal.'
      using errcode = '55000';
  end if;

  select action.*
  into target_action
  from public.sparks_initiative_actions action
  where action.id = target_assignment.object_id
    and action.organization_id = target_assignment.organization_id
    and action.source_module_code = target_assignment.module_code;

  if target_action.id is null then
    raise exception
      'Responsibility is not bound to a valid initiative action in the same organizational scope.'
      using errcode = '55000';
  end if;

  if not public.can_manage_sparks_initiatives(
    target_action.organization_id,
    target_action.source_module_code
  ) then
    raise exception
      'Access denied to manage responsibilities for this initiative action.'
      using errcode = '42501';
  end if;

  effective_end_date := coalesce(target_end_date, current_date);

  if target_assignment.valid_from is not null
     and effective_end_date < target_assignment.valid_from then
    raise exception
      'Responsibility end date cannot precede its start date.'
      using errcode = '22023';
  end if;

  previous_record := to_jsonb(target_assignment);

  update public.sparks_responsibility_assignments
  set
    status = 'ended',
    valid_until = effective_end_date,
    updated_by = current_user_id
  where id = target_assignment.id;

  select to_jsonb(responsibility)
  into new_record
  from public.sparks_responsibility_assignments responsibility
  where responsibility.id = target_assignment.id;

  insert into public.sparks_initiative_action_audit (
    organization_id,
    initiative_id,
    action_id,
    actor_user_id,
    source_module_code,
    action_code,
    change_reason,
    previous_data,
    new_data
  )
  values (
    target_action.organization_id,
    target_action.initiative_id,
    target_action.id,
    current_user_id,
    target_action.source_module_code,
    'initiative_action_responsibility_ended',
    normalized_change_reason,
    previous_record,
    new_record
  );
end;
$function$;

-- ============================================================
-- 5. GOVERNED READ CONTRACT
-- ============================================================

create or replace function public.get_sparks_initiative_action_responsibilities(
  target_action_id uuid,
  include_inactive boolean default false
)
returns table (
  assignment_id uuid,
  action_id uuid,
  organization_id uuid,
  source_module_code text,
  organization_person_id uuid,
  person_id uuid,
  person_name text,
  job_title text,
  organizational_area text,
  responsibility_type text,
  allocation_percentage numeric,
  authority_level text,
  valid_from date,
  valid_until date,
  status text,
  assignment_source text,
  assignment_reason text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  target_action public.sparks_initiative_actions%rowtype;
begin
  if current_user_id is null then
    raise exception 'Authentication required.'
      using errcode = '42501';
  end if;

  select action.*
  into target_action
  from public.sparks_initiative_actions action
  where action.id = target_action_id;

  if target_action.id is null then
    raise exception 'Initiative action not found.'
      using errcode = 'P0002';
  end if;

  if not public.can_read_organization(
    target_action.organization_id
  ) then
    raise exception
      'Access denied to view responsibilities for this initiative action.'
      using errcode = '42501';
  end if;

  return query
  select
    responsibility.id,
    target_action.id,
    responsibility.organization_id,
    responsibility.module_code,
    relationship.id,
    person.id,
    coalesce(person.preferred_name, person.full_name),
    relationship.job_title,
    relationship.organizational_area,
    responsibility.responsibility_type,
    responsibility.allocation_percentage,
    responsibility.authority_level,
    responsibility.valid_from,
    responsibility.valid_until,
    responsibility.status,
    responsibility.assignment_source,
    responsibility.assignment_reason
  from public.sparks_responsibility_assignments responsibility
  join public.sparks_organization_people relationship
    on relationship.id = responsibility.organization_person_id
   and relationship.organization_id = responsibility.organization_id
  join public.sparks_people person
    on person.id = relationship.person_id
  where responsibility.organization_id = target_action.organization_id
    and responsibility.module_code = target_action.source_module_code
    and responsibility.object_type = 'initiative_action'
    and responsibility.object_id = target_action.id
    and (
      include_inactive
      or responsibility.status = 'active'
    )
  order by
    case responsibility.responsibility_type
      when 'owner' then 10
      when 'co_owner' then 20
      when 'sponsor' then 30
      when 'approver' then 40
      when 'validator' then 50
      when 'executor' then 60
      else 100
    end,
    coalesce(person.preferred_name, person.full_name);
end;
$function$;

-- ============================================================
-- 6. RPC PRIVILEGES
-- ============================================================

revoke all on function public.assign_sparks_initiative_action_responsibility(
  uuid, uuid, text, numeric, text, date, date, text, text
) from public, anon;

revoke all on function public.end_sparks_initiative_action_responsibility(
  uuid, date, text
) from public, anon;

revoke all on function public.get_sparks_initiative_action_responsibilities(
  uuid, boolean
) from public, anon;

grant execute on function public.assign_sparks_initiative_action_responsibility(
  uuid, uuid, text, numeric, text, date, date, text, text
) to authenticated, service_role;

grant execute on function public.end_sparks_initiative_action_responsibility(
  uuid, date, text
) to authenticated, service_role;

grant execute on function public.get_sparks_initiative_action_responsibilities(
  uuid, boolean
) to authenticated, service_role;

comment on function public.assign_sparks_initiative_action_responsibility(
  uuid, uuid, text, numeric, text, date, date, text, text
) is
  'Governed assignment of a person responsibility to a transversal SPARKs initiative action.';

comment on function public.end_sparks_initiative_action_responsibility(
  uuid, date, text
) is
  'Governed termination of a responsibility assigned to a transversal SPARKs initiative action.';

comment on function public.get_sparks_initiative_action_responsibilities(
  uuid, boolean
) is
  'Governed read projection of responsibilities assigned to a transversal SPARKs initiative action.';

commit;