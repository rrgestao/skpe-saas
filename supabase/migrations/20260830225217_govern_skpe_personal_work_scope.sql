create or replace function public.skpe_has_broad_work_scope(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or exists (
      select 1
      from public.user_module_roles umr
      join public.organization_modules om
        on om.id = umr.organization_module_id
      join public.modules m
        on m.id = om.module_id
      join public.module_roles mr
        on mr.id = umr.module_role_id
      where umr.user_id = auth.uid()
        and om.organization_id = target_organization_id
        and m.code = 'SK-PE'
        and om.enabled = true
        and om.status in ('trial', 'active')
        and umr.status = 'active'
        and umr.valid_from <= timezone('utc', now())
        and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
        and mr.active = true
        and mr.role_level >= 80
    );
$$;

create or replace function public.get_my_skpe_work_scope_people(target_organization_id uuid)
returns table(
  user_id uuid,
  display_name text,
  email text,
  is_self boolean,
  in_team boolean,
  in_organization boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with recursive
  current_people as (
    select distinct op.id as organization_person_id
    from public.sparks_organization_people op
    join public.sparks_people p on p.id = op.person_id
    where op.organization_id = target_organization_id
      and p.profile_user_id = auth.uid()
      and op.status = 'active'
      and op.start_date <= current_date
      and (op.end_date is null or op.end_date >= current_date)
  ),
  current_roles as (
    select distinct pra.organizational_role_id as role_id
    from public.sparks_person_role_assignments pra
    join current_people cp on cp.organization_person_id = pra.organization_person_id
    where pra.organization_id = target_organization_id
      and pra.assignment_status = 'active'
      and pra.mandate_start_date <= current_date
      and (pra.mandate_end_date is null or pra.mandate_end_date >= current_date)
  ),
  descendant_roles as (
    select r.id as role_id, 0 as depth, array[r.id]::uuid[] as path
    from public.sparks_organizational_roles r
    join current_roles cr on cr.role_id = r.id
    where r.organization_id = target_organization_id
      and r.active = true

    union all

    select child.id, dr.depth + 1, dr.path || child.id
    from descendant_roles dr
    join public.sparks_organizational_roles child
      on child.reports_to_role_id = dr.role_id
     and child.organization_id = target_organization_id
     and child.active = true
    where dr.depth < 30
      and not child.id = any(dr.path)
  ),
  team_users as (
    select distinct p.profile_user_id as user_id
    from descendant_roles dr
    join public.sparks_person_role_assignments pra
      on pra.organizational_role_id = dr.role_id
     and pra.organization_id = target_organization_id
     and pra.assignment_status = 'active'
     and pra.mandate_start_date <= current_date
     and (pra.mandate_end_date is null or pra.mandate_end_date >= current_date)
    join public.sparks_organization_people op
      on op.id = pra.organization_person_id
     and op.organization_id = target_organization_id
     and op.status = 'active'
     and op.start_date <= current_date
     and (op.end_date is null or op.end_date >= current_date)
    join public.sparks_people p
      on p.id = op.person_id
     and p.profile_user_id is not null
  ),
  organization_users as (
    select distinct
      p.profile_user_id as user_id,
      coalesce(nullif(trim(p.preferred_name), ''), p.full_name, u.raw_user_meta_data ->> 'full_name', u.email) as display_name,
      u.email
    from public.sparks_organization_people op
    join public.sparks_people p on p.id = op.person_id
    left join auth.users u on u.id = p.profile_user_id
    where op.organization_id = target_organization_id
      and p.profile_user_id is not null
      and op.status = 'active'
      and op.start_date <= current_date
      and (op.end_date is null or op.end_date >= current_date)

    union

    select
      membership.user_id,
      coalesce(u.raw_user_meta_data ->> 'full_name', u.email),
      u.email
    from public.organization_memberships membership
    left join auth.users u on u.id = membership.user_id
    where membership.organization_id = target_organization_id
      and membership.status = 'active'
      and membership.valid_from <= timezone('utc', now())
      and (membership.valid_until is null or membership.valid_until >= timezone('utc', now()))
  )
  select
    ou.user_id,
    ou.display_name,
    ou.email,
    ou.user_id = auth.uid() as is_self,
    ou.user_id = auth.uid() or exists(select 1 from team_users tu where tu.user_id = ou.user_id) as in_team,
    true as in_organization
  from organization_users ou
  where public.is_platform_super_admin()
     or (
       public.is_active_member(target_organization_id)
       and public.has_module_access(target_organization_id, 'SK-PE')
     )
  order by
    case when ou.user_id = auth.uid() then 0 else 1 end,
    ou.display_name nulls last,
    ou.email nulls last;
$$;

create or replace function public.get_my_skpe_work_scope_options(target_organization_id uuid)
returns table(
  scope_key text,
  scope_label text,
  enabled boolean,
  is_default boolean,
  user_count integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  broad_scope boolean;
  team_count integer;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado.' using errcode = '42501';
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
      and public.has_module_access(target_organization_id, 'SK-PE')
    )
  ) then
    raise exception 'Acesso negado ao escopo de trabalho do SK-PE.' using errcode = '42501';
  end if;

  broad_scope := public.skpe_has_broad_work_scope(target_organization_id);

  select count(*)::integer into team_count
  from public.get_my_skpe_work_scope_people(target_organization_id) p
  where p.in_team;

  return query
  select 'me'::text, 'Meu trabalho'::text, true, not broad_scope and team_count <= 1, 1
  union all
  select 'team', 'Minha equipe', team_count > 1, not broad_scope and team_count > 1, team_count
  union all
  select 'organization', 'Toda a organização', broad_scope, broad_scope,
    (select count(*)::integer from public.get_my_skpe_work_scope_people(target_organization_id));
end;
$$;

create or replace function public.skpe_work_scope_allows_user(
  target_organization_id uuid,
  candidate_user_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  broad_scope boolean;
  team_count integer;
  requested_scope text;
  requested_user_id uuid;
  effective_scope text;
  pref_value jsonb;
begin
  if candidate_user_id is null or auth.uid() is null then
    return false;
  end if;

  if not (
    public.is_platform_super_admin()
    or (
      public.is_active_member(target_organization_id)
      and public.has_module_access(target_organization_id, 'SK-PE')
    )
  ) then
    return false;
  end if;

  broad_scope := public.skpe_has_broad_work_scope(target_organization_id);

  select count(*)::integer into team_count
  from public.get_my_skpe_work_scope_people(target_organization_id) p
  where p.in_team;

  select ump.preference_value into pref_value
  from public.user_module_preferences ump
  join public.organization_modules om on om.id = ump.organization_module_id
  join public.modules m on m.id = om.module_id
  where ump.user_id = auth.uid()
    and om.organization_id = target_organization_id
    and m.code = 'SK-PE'
    and ump.preference_key = 'workspace.work_scope'
  limit 1;

  requested_scope := lower(coalesce(pref_value ->> 'scope', ''));

  begin
    requested_user_id := nullif(pref_value ->> 'user_id', '')::uuid;
  exception when others then
    requested_user_id := null;
  end;

  effective_scope := case
    when requested_scope = 'organization' and broad_scope then 'organization'
    when requested_scope = 'team' and team_count > 1 then 'team'
    when requested_scope = 'person' and requested_user_id is not null then 'person'
    when requested_scope = 'me' then 'me'
    when broad_scope then 'organization'
    when team_count > 1 then 'team'
    else 'me'
  end;

  if effective_scope = 'organization' then
    return exists (
      select 1 from public.get_my_skpe_work_scope_people(target_organization_id) p
      where p.user_id = candidate_user_id
    );
  end if;

  if effective_scope = 'team' then
    return exists (
      select 1 from public.get_my_skpe_work_scope_people(target_organization_id) p
      where p.user_id = candidate_user_id and p.in_team
    );
  end if;

  if effective_scope = 'person' then
    return requested_user_id = candidate_user_id
      and exists (
        select 1 from public.get_my_skpe_work_scope_people(target_organization_id) p
        where p.user_id = requested_user_id
          and (
            p.is_self
            or (broad_scope and p.in_organization)
            or (not broad_scope and p.in_team)
          )
      );
  end if;

  return candidate_user_id = auth.uid();
end;
$$;

do $$
declare
  fn text;
  patched text;
begin
  fn := pg_get_functiondef('public.get_my_skpe_indicators(uuid,uuid,uuid)'::regprocedure);
  patched := replace(fn,
    'and indicator.owner_user_id = current_user_id',
    'and public.skpe_work_scope_allows_user(target_organization_id, indicator.owner_user_id)');
  if patched = fn then raise exception 'Anchor get_my_skpe_indicators não encontrado.'; end if;
  execute patched;

  fn := pg_get_functiondef('public.get_my_skpe_key_results(uuid,uuid,uuid)'::regprocedure);
  patched := replace(fn,
    'and kr.owner_user_id = current_user_id',
    'and public.skpe_work_scope_allows_user(target_organization_id, kr.owner_user_id)');
  if patched = fn then raise exception 'Anchor get_my_skpe_key_results não encontrado.'; end if;
  execute patched;

  fn := pg_get_functiondef('public.get_my_skpe_decisions(uuid,uuid,uuid)'::regprocedure);
  patched := replace(fn,
    'and decision.responsible_user_id = current_user_id',
    'and public.skpe_work_scope_allows_user(target_organization_id, decision.responsible_user_id)');
  if patched = fn then raise exception 'Anchor get_my_skpe_decisions não encontrado.'; end if;
  execute patched;

  fn := pg_get_functiondef('public.get_my_skpe_initiatives(uuid,uuid,uuid)'::regprocedure);
  patched := replace(fn,
    'initiative.owner_user_id = current_user_id',
    'public.skpe_work_scope_allows_user(target_organization_id, initiative.owner_user_id)');
  patched := replace(patched,
    'initiative.backup_owner_user_id = current_user_id',
    'public.skpe_work_scope_allows_user(target_organization_id, initiative.backup_owner_user_id)');
  patched := replace(patched,
    'initiative.sponsor_user_id = current_user_id',
    'public.skpe_work_scope_allows_user(target_organization_id, initiative.sponsor_user_id)');
  if patched = fn then raise exception 'Anchors get_my_skpe_initiatives não encontrados.'; end if;
  execute patched;

  fn := pg_get_functiondef('public.get_my_skpe_pending_items(uuid,uuid,uuid)'::regprocedure);
  patched := replace(fn,
    'item.responsible_user_id = current_user_id',
    'public.skpe_work_scope_allows_user(target_organization_id, item.responsible_user_id)');
  patched := replace(patched,
    'initiative.owner_user_id = current_user_id',
    'public.skpe_work_scope_allows_user(target_organization_id, initiative.owner_user_id)');
  patched := replace(patched,
    'action.responsible_user_id = current_user_id',
    'public.skpe_work_scope_allows_user(target_organization_id, action.responsible_user_id)');
  patched := replace(patched,
    'action.backup_responsible_user_id = current_user_id',
    'public.skpe_work_scope_allows_user(target_organization_id, action.backup_responsible_user_id)');
  patched := replace(patched,
    'checklist_item.responsible_user_id = current_user_id',
    'public.skpe_work_scope_allows_user(target_organization_id, checklist_item.responsible_user_id)');
  patched := replace(patched,
    'decision.responsible_user_id = current_user_id',
    'public.skpe_work_scope_allows_user(target_organization_id, decision.responsible_user_id)');
  if patched = fn then raise exception 'Anchors get_my_skpe_pending_items não encontrados.'; end if;
  execute patched;
end;
$$;

revoke all on function public.skpe_has_broad_work_scope(uuid) from public, anon;
revoke all on function public.get_my_skpe_work_scope_people(uuid) from public, anon;
revoke all on function public.get_my_skpe_work_scope_options(uuid) from public, anon;
revoke all on function public.skpe_work_scope_allows_user(uuid,uuid) from public, anon;
grant execute on function public.skpe_has_broad_work_scope(uuid) to authenticated;
grant execute on function public.get_my_skpe_work_scope_people(uuid) to authenticated;
grant execute on function public.get_my_skpe_work_scope_options(uuid) to authenticated;
grant execute on function public.skpe_work_scope_allows_user(uuid,uuid) to authenticated;