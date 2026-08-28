create or replace function public.ensure_active_membership_canonical_person()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  profile_row record;
  target_person_id uuid;
  existing_relationship_id uuid;
  person_name text;
begin
  if new.status::text <> 'active' then
    return new;
  end if;

  select
    p.email,
    p.full_name,
    p.display_name
  into profile_row
  from public.profiles p
  where p.id = new.user_id;

  if not found then
    raise exception 'Nao foi possivel materializar a identidade canonica: perfil % inexistente.', new.user_id;
  end if;

  person_name := coalesce(
    nullif(trim(profile_row.full_name), ''),
    nullif(trim(profile_row.display_name), ''),
    nullif(split_part(profile_row.email, '@', 1), ''),
    'Pessoa vinculada ' || left(new.user_id::text, 8)
  );

  select sp.id
    into target_person_id
  from public.sparks_people sp
  where sp.profile_user_id = new.user_id
    and sp.archived_at is null
  limit 1;

  if target_person_id is null then
    insert into public.sparks_people (
      full_name,
      preferred_name,
      primary_email,
      profile_user_id,
      person_status,
      data_source,
      metadata,
      created_by,
      updated_by
    ) values (
      person_name,
      person_name,
      profile_row.email,
      new.user_id,
      'active',
      'integration',
      jsonb_build_object(
        'source', 'organization_memberships',
        'source_membership_id', new.id,
        'synchronized_at', timezone('utc', now()),
        'synchronization_reason', 'Automatic canonical identity materialization'
      ),
      new.updated_by,
      new.updated_by
    )
    returning id into target_person_id;
  end if;

  select sop.id
    into existing_relationship_id
  from public.sparks_organization_people sop
  where sop.organization_id = new.organization_id
    and sop.person_id = target_person_id
    and sop.status = 'active'
  order by sop.is_primary_relationship desc, sop.created_at
  limit 1;

  if existing_relationship_id is null then
    insert into public.sparks_organization_people (
      organization_id,
      person_id,
      relationship_type,
      job_title,
      start_date,
      status,
      is_primary_relationship,
      metadata,
      created_by,
      updated_by
    ) values (
      new.organization_id,
      target_person_id,
      'other',
      nullif(trim(new.job_title), ''),
      coalesce(new.valid_from::date, current_date),
      'active',
      true,
      jsonb_build_object(
        'source', 'organization_memberships',
        'source_membership_id', new.id,
        'is_organization_admin', new.is_organization_admin,
        'relationship_requires_validation', true,
        'synchronized_at', timezone('utc', now()),
        'synchronization_reason', 'Automatic canonical identity materialization'
      ),
      new.updated_by,
      new.updated_by
    );
  end if;

  return new;
end;
$$;

revoke all on function public.ensure_active_membership_canonical_person() from public;
revoke all on function public.ensure_active_membership_canonical_person() from anon;
revoke all on function public.ensure_active_membership_canonical_person() from authenticated;

drop trigger if exists trg_sync_active_membership_canonical_person on public.organization_memberships;
create trigger trg_sync_active_membership_canonical_person
after insert or update of status, user_id, organization_id, job_title, valid_from, is_organization_admin
on public.organization_memberships
for each row
when (new.status::text = 'active')
execute function public.ensure_active_membership_canonical_person();

do $$
declare
  item record;
  target_person_id uuid;
  person_name text;
begin
  for item in
    select
      om.id as membership_id,
      om.organization_id,
      om.user_id,
      om.job_title,
      om.valid_from,
      om.is_organization_admin,
      om.updated_by,
      p.email,
      p.full_name,
      p.display_name
    from public.organization_memberships om
    join public.profiles p on p.id = om.user_id
    where om.status::text = 'active'
      and not exists (
        select 1
        from public.sparks_people sp
        join public.sparks_organization_people sop
          on sop.person_id = sp.id
         and sop.organization_id = om.organization_id
         and sop.status = 'active'
        where sp.profile_user_id = om.user_id
          and sp.archived_at is null
      )
    order by om.organization_id, p.email
  loop
    person_name := coalesce(
      nullif(trim(item.full_name), ''),
      nullif(trim(item.display_name), ''),
      nullif(split_part(item.email, '@', 1), ''),
      'Pessoa vinculada ' || left(item.user_id::text, 8)
    );

    select sp.id
      into target_person_id
    from public.sparks_people sp
    where sp.profile_user_id = item.user_id
      and sp.archived_at is null
    limit 1;

    if target_person_id is null then
      insert into public.sparks_people (
        full_name,
        preferred_name,
        primary_email,
        profile_user_id,
        person_status,
        data_source,
        metadata,
        created_by,
        updated_by
      ) values (
        person_name,
        person_name,
        item.email,
        item.user_id,
        'active',
        'integration',
        jsonb_build_object(
          'source', 'organization_memberships',
          'source_membership_id', item.membership_id,
          'synchronized_at', timezone('utc', now()),
          'synchronization_reason', 'Backfill canonical identity materialization'
        ),
        item.updated_by,
        item.updated_by
      )
      returning id into target_person_id;
    end if;

    if not exists (
      select 1
      from public.sparks_organization_people sop
      where sop.organization_id = item.organization_id
        and sop.person_id = target_person_id
        and sop.status = 'active'
    ) then
      insert into public.sparks_organization_people (
        organization_id,
        person_id,
        relationship_type,
        job_title,
        start_date,
        status,
        is_primary_relationship,
        metadata,
        created_by,
        updated_by
      ) values (
        item.organization_id,
        target_person_id,
        'other',
        nullif(trim(item.job_title), ''),
        coalesce(item.valid_from::date, current_date),
        'active',
        true,
        jsonb_build_object(
          'source', 'organization_memberships',
          'source_membership_id', item.membership_id,
          'is_organization_admin', item.is_organization_admin,
          'relationship_requires_validation', true,
          'synchronized_at', timezone('utc', now()),
          'synchronization_reason', 'Backfill canonical identity materialization'
        ),
        item.updated_by,
        item.updated_by
      );
    end if;
  end loop;
end;
$$;
