-- ============================================================
-- Plataforma SPARKs / Planejamento Estratégico
-- Sincronização segura: usuários vinculados -> pessoas integradas
-- Data: 2026-07-27
-- Correção: permite execução administrativa segura pelo SQL Editor
-- ============================================================

begin;

create or replace function public.get_unsynced_organization_memberships(
  target_organization_id uuid
)
returns table (
  membership_id uuid,
  user_id uuid,
  email text,
  suggested_name text,
  job_title text,
  membership_status text,
  is_organization_admin boolean,
  person_id uuid,
  organization_person_id uuid
)
language sql
security definer
set search_path = ''
as $$
  select
    om.id,
    om.user_id,
    p.email,
    coalesce(
      nullif(trim(p.full_name), ''),
      nullif(trim(p.display_name), ''),
      split_part(p.email, '@', 1)
    ) as suggested_name,
    om.job_title,
    om.status::text,
    om.is_organization_admin,
    sp.id as person_id,
    sop.id as organization_person_id
  from public.organization_memberships om
  join public.profiles p
    on p.id = om.user_id
  left join public.sparks_people sp
    on sp.profile_user_id = om.user_id
   and sp.archived_at is null
  left join public.sparks_organization_people sop
    on sop.organization_id = om.organization_id
   and sop.person_id = sp.id
   and sop.status = 'active'
  where om.organization_id = target_organization_id
    and om.status::text = 'active'
    and (
      public.can_view_skpe_governance(target_organization_id)
      or auth.role() = 'service_role'
      or session_user in ('postgres', 'supabase_admin')
    )
  order by coalesce(p.display_name, p.full_name, p.email);
$$;

comment on function public.get_unsynced_organization_memberships(uuid) is
  'Lista usuários ativos da organização e indica se já possuem pessoa e vínculo na base integrada.';

grant execute on function public.get_unsynced_organization_memberships(uuid) to authenticated;

create or replace function public.sync_organization_memberships_to_sparks_people(
  target_organization_id uuid,
  change_reason text
)
returns table (
  memberships_processed integer,
  people_created integer,
  people_updated integer,
  relationships_created integer,
  relationships_updated integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  item record;
  target_person_id uuid;
  existing_relationship_id uuid;
  processed_count integer := 0;
  created_people_count integer := 0;
  updated_people_count integer := 0;
  created_relationships_count integer := 0;
  updated_relationships_count integer := 0;
  person_name text;
begin
  if not (
    public.can_manage_skpe_governance(target_organization_id)
    or auth.role() = 'service_role'
    or session_user in ('postgres', 'supabase_admin')
  ) then
    raise exception 'Acesso negado para sincronizar pessoas da organização.';
  end if;

  perform public.skpe_assert_reason(change_reason);

  for item in
    select
      om.id as membership_id,
      om.user_id,
      om.job_title,
      om.is_organization_admin,
      om.valid_from,
      profile.email,
      coalesce(
        nullif(trim(profile.full_name), ''),
        nullif(trim(profile.display_name), ''),
        split_part(profile.email, '@', 1)
      ) as full_name
    from public.organization_memberships om
    join public.profiles profile
      on profile.id = om.user_id
    where om.organization_id = target_organization_id
      and om.status::text = 'active'
    order by profile.email
  loop
    processed_count := processed_count + 1;
    person_name := nullif(trim(item.full_name), '');

    if person_name is null then
      person_name := 'Pessoa vinculada ' || left(item.user_id::text, 8);
    end if;

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
          'synchronization_reason', change_reason
        ),
        auth.uid(),
        auth.uid()
      )
      returning id into target_person_id;

      created_people_count := created_people_count + 1;
    else
      update public.sparks_people
         set full_name = case
               when nullif(trim(full_name), '') is null then person_name
               else full_name
             end,
             preferred_name = coalesce(nullif(trim(preferred_name), ''), person_name),
             primary_email = coalesce(nullif(trim(primary_email), ''), item.email),
             person_status = case when person_status = 'archived' then person_status else 'active' end,
             metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
               'last_membership_sync_at', timezone('utc', now()),
               'last_membership_id', item.membership_id,
               'last_synchronization_reason', change_reason
             ),
             updated_by = auth.uid()
       where id = target_person_id;

      updated_people_count := updated_people_count + 1;
    end if;

    select sop.id
      into existing_relationship_id
    from public.sparks_organization_people sop
    where sop.organization_id = target_organization_id
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
        target_organization_id,
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
          'synchronization_reason', change_reason
        ),
        auth.uid(),
        auth.uid()
      );

      created_relationships_count := created_relationships_count + 1;
    else
      update public.sparks_organization_people
         set job_title = coalesce(nullif(trim(job_title), ''), nullif(trim(item.job_title), '')),
             metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
               'last_membership_sync_at', timezone('utc', now()),
               'source_membership_id', item.membership_id,
               'is_organization_admin', item.is_organization_admin,
               'last_synchronization_reason', change_reason
             ),
             updated_by = auth.uid()
       where id = existing_relationship_id;

      updated_relationships_count := updated_relationships_count + 1;
    end if;
  end loop;

  perform public.skpe_record_operational_audit(
    target_organization_id,
    null,
    'organization_people_sync',
    target_organization_id,
    'synchronize',
    change_reason,
    null,
    jsonb_build_object(
      'memberships_processed', processed_count,
      'people_created', created_people_count,
      'people_updated', updated_people_count,
      'relationships_created', created_relationships_count,
      'relationships_updated', updated_relationships_count
    )
  );

  return query
  select
    processed_count,
    created_people_count,
    updated_people_count,
    created_relationships_count,
    updated_relationships_count;
end;
$$;

comment on function public.sync_organization_memberships_to_sparks_people(uuid, text) is
  'Sincroniza usuários ativos da organização com o cadastro integrado de pessoas sem criar papéis ou designações automaticamente.';

grant execute on function public.sync_organization_memberships_to_sparks_people(uuid, text) to authenticated;

commit;

-- ============================================================
-- CONSULTAS DE VERIFICAÇÃO
-- Execute após a migration, em uma nova consulta autenticada.
-- ============================================================

-- 1. Localizar a COOTAQUARA
-- select id, code, trade_name, legal_name
-- from public.organizations
-- where upper(coalesce(code, '')) = 'COOTAQUARA'
--    or upper(coalesce(trade_name, '')) like '%COOTAQUARA%'
--    or upper(coalesce(legal_name, '')) like '%COOTAQUARA%';

-- 2. Prévia dos usuários e da situação de sincronização
-- select *
-- from public.get_unsynced_organization_memberships('<UUID_DA_COOTAQUARA>'::uuid);

-- 3. Executar a sincronização
-- select *
-- from public.sync_organization_memberships_to_sparks_people(
--   '<UUID_DA_COOTAQUARA>'::uuid,
--   'Sincronização inicial dos usuários ativos da COOTAQUARA com a base integrada de pessoas.'
-- );

-- 4. Conferir pessoas e vínculos criados
-- select
--   p.full_name,
--   p.primary_email,
--   p.person_status,
--   op.relationship_type,
--   op.job_title,
--   op.status,
--   op.metadata ->> 'relationship_requires_validation' as requer_validacao
-- from public.sparks_organization_people op
-- join public.sparks_people p on p.id = op.person_id
-- where op.organization_id = '<UUID_DA_COOTAQUARA>'::uuid
-- order by p.full_name;
