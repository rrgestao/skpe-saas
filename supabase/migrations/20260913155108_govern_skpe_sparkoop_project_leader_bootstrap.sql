-- Plataforma SPARKs / SK-PE
-- Governa o responsável inicial da Jornada Estratégica.
-- Decisão Product 2026-09-13: owner inicial = Líder do Projeto pela SPARKOOP.

begin;

-- ============================================================
-- 1. PAPEL CANÔNICO NA SPARKOOP
-- ============================================================

do $$
declare
  sparkoop_organization_id uuid;
  sparkoop_count integer;
begin
  select count(*)::integer
  into sparkoop_count
  from public.organizations
  where code = 'SPARKOOP'
    and status = 'active';

  select id
  into sparkoop_organization_id
  from public.organizations
  where code = 'SPARKOOP'
    and status = 'active'
  order by id
  limit 1;

  if sparkoop_count <> 1 then
    raise exception
      'Esperada exatamente uma organização ativa SPARKOOP; encontradas %.',
      sparkoop_count
      using errcode = '22023';
  end if;

  insert into public.sparks_organizational_roles (
    organization_id,
    code,
    name,
    role_type,
    description,
    is_governance_role,
    requires_mandate,
    active,
    metadata,
    created_by,
    updated_by
  )
  values (
    sparkoop_organization_id,
    'project_leader',
    'Líder de Projeto',
    'project',
    'Responsável SPARKOOP pela condução inicial de um Projeto/Jornada Estratégica até a definição governada da equipe da Organização.',
    false,
    false,
    true,
    jsonb_build_object(
      'source', 'product_decision_2026_09_13',
      'purpose', 'skpe_initial_project_owner'
    ),
    auth.uid(),
    auth.uid()
  )
  on conflict (organization_id, code) do update
  set
    name = excluded.name,
    role_type = excluded.role_type,
    description = excluded.description,
    is_governance_role = excluded.is_governance_role,
    requires_mandate = excluded.requires_mandate,
    active = true,
    metadata = coalesce(public.sparks_organizational_roles.metadata, '{}'::jsonb) || excluded.metadata,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid();
end;
$$;

-- ============================================================
-- 2. BOOTSTRAP DO OWNER INICIAL DA INICIATIVA PE
-- ============================================================

create or replace function public.bootstrap_skpe_initiative_team_from_binding()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session_user_id uuid;
  v_effective_date date;
  v_sparkoop_organization_id uuid;
  v_project_leader_role_id uuid;
  v_sparkoop_organization_person_id uuid;
  v_relationship_count integer;
  v_role_assignment_count integer;
  v_initiative_source_module text;
  v_initiative_archived_at timestamptz;
  v_assignment_id uuid;
  v_assignment_record jsonb;
begin
  if tg_op <> 'INSERT' then
    raise exception 'Bootstrap somente permitido em INSERT.' using errcode='55000';
  end if;

  if new.created_by is null then
    raise exception 'A Jornada exige usuário criador identificado.' using errcode='23502';
  end if;

  v_session_user_id := auth.uid();
  if v_session_user_id is not null and v_session_user_id is distinct from new.created_by then
    raise exception 'O criador do binding deve ser o usuário autenticado.' using errcode='42501';
  end if;

  select i.source_module_code, i.archived_at
  into v_initiative_source_module, v_initiative_archived_at
  from public.sparks_initiatives i
  where i.id = new.initiative_id
    and i.organization_id = new.organization_id;

  if not found or coalesce(v_initiative_source_module,'') <> 'SK-PE' then
    raise exception 'Bootstrap exige iniciativa SK-PE válida.' using errcode='23514';
  end if;

  if v_initiative_archived_at is not null then
    raise exception 'Não é possível bootstrapar iniciativa arquivada.' using errcode='23514';
  end if;

  select id
  into v_sparkoop_organization_id
  from public.organizations
  where code='SPARKOOP' and status='active'
  order by id
  limit 1;

  select r.id
  into v_project_leader_role_id
  from public.sparks_organizational_roles r
  where r.organization_id = v_sparkoop_organization_id
    and r.code = 'project_leader'
    and r.active;

  if v_project_leader_role_id is null then
    raise exception 'Papel SPARKOOP project_leader não está ativo.' using errcode='23514';
  end if;

  select timezone(
    coalesce(nullif(trim(o.timezone_name), ''), 'UTC'),
    new.created_at
  )::date
  into v_effective_date
  from public.organizations o
  where o.id = new.organization_id;

  select count(*)::integer
  into v_relationship_count
  from public.sparks_people sp
  join public.sparks_organization_people sop
    on sop.person_id = sp.id
   and sop.organization_id = v_sparkoop_organization_id
   and sop.status = 'active'
   and (sop.start_date is null or sop.start_date <= v_effective_date)
   and (sop.end_date is null or sop.end_date >= v_effective_date)
  where sp.profile_user_id = new.created_by
    and sp.person_status = 'active'
    and sp.archived_at is null;

  select sop.id
  into v_sparkoop_organization_person_id
  from public.sparks_people sp
  join public.sparks_organization_people sop
    on sop.person_id = sp.id
   and sop.organization_id = v_sparkoop_organization_id
   and sop.status = 'active'
   and (sop.start_date is null or sop.start_date <= v_effective_date)
   and (sop.end_date is null or sop.end_date >= v_effective_date)
  where sp.profile_user_id = new.created_by
    and sp.person_status = 'active'
    and sp.archived_at is null
  order by sop.id
  limit 1;

  if v_relationship_count <> 1 then
    raise exception
      'O usuário que inicia a Jornada deve possuir exatamente um vínculo ativo com a SPARKOOP; encontrados %.',
      v_relationship_count
      using errcode='23514';
  end if;

  select count(*)::integer
  into v_role_assignment_count
  from public.sparks_person_role_assignments pra
  where pra.organization_id = v_sparkoop_organization_id
    and pra.organization_person_id = v_sparkoop_organization_person_id
    and pra.organizational_role_id = v_project_leader_role_id
    and pra.assignment_status = 'active'
    and (pra.mandate_start_date is null or pra.mandate_start_date <= v_effective_date)
    and (pra.mandate_end_date is null or pra.mandate_end_date >= v_effective_date);

  if v_role_assignment_count <> 1 then
    raise exception
      'O usuário que inicia a Jornada deve possuir atribuição ativa ao papel Líder de Projeto da SPARKOOP; encontradas %.',
      v_role_assignment_count
      using errcode='23514';
  end if;

  insert into public.sparks_responsibility_assignments (
    organization_id,
    module_code,
    object_type,
    object_id,
    organization_person_id,
    responsibility_type,
    valid_from,
    status,
    assignment_reason,
    metadata,
    created_by,
    updated_by,
    assignment_source
  )
  values (
    new.organization_id,
    'SK-PE',
    'initiative',
    new.initiative_id,
    v_sparkoop_organization_person_id,
    'owner',
    v_effective_date,
    'active',
    'Responsável inicial da Jornada Estratégica conforme decisão Product: Líder do Projeto pela SPARKOOP.',
    jsonb_build_object(
      'source', 'skpe_project_initiative_binding',
      'binding_id', new.id,
      'skpe_project_id', new.skpe_project_id,
      'initial_owner_source_organization_id', v_sparkoop_organization_id,
      'initial_owner_role_id', v_project_leader_role_id,
      'initial_owner_role_code', 'project_leader',
      'pending_opening_reconciliation', true
    ),
    new.created_by,
    new.created_by,
    'integration'
  )
  returning id into v_assignment_id;

  select to_jsonb(ra)
  into v_assignment_record
  from public.sparks_responsibility_assignments ra
  where ra.id = v_assignment_id;

  perform public.skpe_record_operational_audit(
    new.organization_id,
    new.skpe_project_id,
    'responsibility_assignment',
    v_assignment_id,
    'assign_initial_sparkoop_project_leader',
    'Responsável inicial definido pelo papel Líder de Projeto da SPARKOOP.',
    null,
    v_assignment_record
  );

  update public.sparks_initiatives i
  set metadata = coalesce(i.metadata, '{}'::jsonb) || jsonb_build_object(
    'bootstrap_team', true,
    'initial_owner_assignment_id', v_assignment_id,
    'initial_owner_role_code', 'project_leader',
    'initial_owner_source_organization_id', v_sparkoop_organization_id,
    'pending_opening_reconciliation', true
  ),
  updated_at = timezone('utc', now()),
  updated_by = new.created_by
  where i.id = new.initiative_id
    and i.organization_id = new.organization_id;

  return new;
end;
$$;

revoke all on function public.bootstrap_skpe_initiative_team_from_binding() from public, anon, authenticated;

-- ============================================================
-- 3. REUNIÃO DE ABERTURA: RESPONSÁVEL PELA ORGANIZAÇÃO
-- ============================================================

create or replace function public.reconcile_skpe_project_opening_owner(
  target_skpe_project_id uuid,
  target_organization_person_id uuid,
  decision_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_binding public.skpe_project_initiative_bindings%rowtype;
  v_initial_owner_assignment_id uuid;
  v_new_owner_assignment_id uuid;
  v_effective_date date;
begin
  perform public.skpe_assert_reason(decision_reason);

  select * into v_binding
  from public.skpe_project_initiative_bindings
  where skpe_project_id = target_skpe_project_id;

  if not found then
    raise exception 'Projeto SK-PE não possui binding transversal.' using errcode='22023';
  end if;

  if not public.can_manage_skpe_journey(v_binding.organization_id) then
    raise exception 'Acesso negado para reconciliar responsável na Reunião de Abertura.' using errcode='42501';
  end if;

  if not exists (
    select 1
    from public.sparks_organization_people sop
    where sop.id = target_organization_person_id
      and sop.organization_id = v_binding.organization_id
      and sop.status = 'active'
      and (sop.end_date is null or sop.end_date >= current_date)
  ) then
    raise exception 'O responsável pela Organização deve possuir vínculo ativo com a organização do Projeto.' using errcode='23514';
  end if;

  select timezone(
    coalesce(nullif(trim(o.timezone_name), ''), 'UTC'),
    timezone('utc', now())
  )::date
  into v_effective_date
  from public.organizations o
  where o.id = v_binding.organization_id;

  select nullif(i.metadata ->> 'initial_owner_assignment_id', '')::uuid
  into v_initial_owner_assignment_id
  from public.sparks_initiatives i
  where i.id = v_binding.initiative_id
    and i.organization_id = v_binding.organization_id
    and coalesce((i.metadata ->> 'pending_opening_reconciliation')::boolean, false) = true;

  if v_initial_owner_assignment_id is null then
    raise exception
      'A reconciliação da Reunião de Abertura não está pendente para este Projeto.'
      using errcode='55000';
  end if;

  if not exists (
    select 1
    from public.sparks_responsibility_assignments ra
    where ra.id = v_initial_owner_assignment_id
      and ra.organization_id = v_binding.organization_id
      and ra.module_code = 'SK-PE'
      and ra.object_type = 'initiative'
      and ra.object_id = v_binding.initiative_id
      and ra.responsibility_type = 'owner'
      and ra.status = 'active'
      and ra.metadata ->> 'initial_owner_role_code' = 'project_leader'
  ) then
    raise exception
      'Owner inicial SPARKOOP esperado não está ativo ou não corresponde ao bootstrap governado.'
      using errcode='55000';
  end if;

  if v_initial_owner_assignment_id is not null then
    update public.sparks_responsibility_assignments
    set
      status = 'ended',
      valid_until = v_effective_date,
      updated_by = auth.uid()
    where id = v_initial_owner_assignment_id;

    perform public.skpe_record_operational_audit(
      v_binding.organization_id,
      target_skpe_project_id,
      'responsibility_assignment',
      v_initial_owner_assignment_id,
      'end_initial_sparkoop_project_leader',
      decision_reason,
      null,
      (select to_jsonb(ra) from public.sparks_responsibility_assignments ra where ra.id = v_initial_owner_assignment_id)
    );
  end if;

  insert into public.sparks_responsibility_assignments (
    organization_id,
    module_code,
    object_type,
    object_id,
    organization_person_id,
    responsibility_type,
    valid_from,
    status,
    assignment_reason,
    metadata,
    created_by,
    updated_by,
    assignment_source
  )
  values (
    v_binding.organization_id,
    'SK-PE',
    'initiative',
    v_binding.initiative_id,
    target_organization_person_id,
    'owner',
    v_effective_date,
    'active',
    'Responsável pelo Projeto definido pela Organização na Reunião de Abertura.',
    jsonb_build_object(
      'source', 'opening_meeting',
      'skpe_project_id', target_skpe_project_id,
      'replaces_initial_sparkoop_owner_assignment_id', v_initial_owner_assignment_id,
      'decision_reason', trim(decision_reason)
    ),
    auth.uid(),
    auth.uid(),
    'manual'
  )
  returning id into v_new_owner_assignment_id;

  perform public.skpe_record_operational_audit(
    v_binding.organization_id,
    target_skpe_project_id,
    'responsibility_assignment',
    v_new_owner_assignment_id,
    'assign_organization_project_owner_opening_meeting',
    decision_reason,
    null,
    (select to_jsonb(ra) from public.sparks_responsibility_assignments ra where ra.id = v_new_owner_assignment_id)
  );

  update public.sparks_initiatives i
  set metadata = coalesce(i.metadata, '{}'::jsonb) || jsonb_build_object(
    'pending_opening_reconciliation', false,
    'organization_owner_assignment_id', v_new_owner_assignment_id,
    'organization_owner_defined_at', timezone('utc', now()),
    'organization_owner_defined_by', auth.uid()
  ),
  updated_at = timezone('utc', now()),
  updated_by = auth.uid()
  where i.id = v_binding.initiative_id
    and i.organization_id = v_binding.organization_id;

  return jsonb_build_object(
    'skpeProjectId', target_skpe_project_id,
    'initiativeId', v_binding.initiative_id,
    'previousInitialOwnerAssignmentId', v_initial_owner_assignment_id,
    'organizationOwnerAssignmentId', v_new_owner_assignment_id,
    'effectiveDate', v_effective_date,
    'openingReconciliationCompleted', true
  );
end;
$$;

grant execute on function public.reconcile_skpe_project_opening_owner(uuid, uuid, text)
  to authenticated, service_role;

commit;
