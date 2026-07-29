begin;

create or replace function public.replace_organization_cnaes_v3(
  target_organization_id uuid,
  selected_cnaes jsonb,
  target_source_type text,
  target_source_reference text,
  change_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_item jsonb;
  selected_catalog_id uuid;
  selected_is_primary boolean;
  selected_count integer;
  primary_count integer;
  distinct_count integer;
  valid_catalog_count integer;
  previous_data jsonb;
  new_data jsonb;
  primary_description text;
  normalized_source_type text;
  catalog_row record;
  existing_activity_id uuid;
begin
  if not (
    public.is_platform_super_admin()
    or public.can_manage_organization(target_organization_id)
  ) then
    raise exception
      'Acesso negado: somente administradores diretos podem alterar os CNAEs desta organizaÃ§Ã£o.'
      using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception
      'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if jsonb_typeof(coalesce(selected_cnaes, '[]'::jsonb)) <> 'array' then
    raise exception
      'A seleÃ§Ã£o de CNAEs deve ser enviada como uma lista.';
  end if;

  normalized_source_type :=
    lower(trim(coalesce(target_source_type, 'manual_confirmed')));

  if normalized_source_type not in (
    'official_cnpj',
    'official_ibge',
    'official_document',
    'manual_confirmed'
  ) then
    raise exception
      'Origem de verificaÃ§Ã£o dos CNAEs invÃ¡lida.';
  end if;

  selected_count :=
    jsonb_array_length(coalesce(selected_cnaes, '[]'::jsonb));

  select count(*)
  into primary_count
  from jsonb_array_elements(
    coalesce(selected_cnaes, '[]'::jsonb)
  ) item
  where lower(
    coalesce(item ->> 'is_primary', 'false')
  ) in ('true', '1', 'yes', 'sim');

  if selected_count > 0 and primary_count <> 1 then
    raise exception
      'Selecione exatamente um CNAE principal.';
  end if;

  select count(distinct (item ->> 'cnae_catalog_id'))
  into distinct_count
  from jsonb_array_elements(
    coalesce(selected_cnaes, '[]'::jsonb)
  ) item;

  if distinct_count <> selected_count then
    raise exception
      'A lista contÃ©m CNAEs duplicados ou sem identificador oficial.';
  end if;

  select count(*)
  into valid_catalog_count
  from public.cnae_catalog catalog
  join public.cnae_catalog_versions version
    on version.version_code = catalog.version_code
  where catalog.id in (
    select (item ->> 'cnae_catalog_id')::uuid
    from jsonb_array_elements(
      coalesce(selected_cnaes, '[]'::jsonb)
    ) item
  )
    and catalog.active = true
    and version.active = true
    and version.is_current = true;

  if valid_catalog_count <> selected_count then
    raise exception
      'Um ou mais CNAEs nÃ£o pertencem ao catÃ¡logo oficial vigente.';
  end if;

  select coalesce(
    jsonb_agg(
      to_jsonb(activity)
      order by
        activity.is_primary desc,
        activity.cnae_code,
        activity.updated_at desc
    ),
    '[]'::jsonb
  )
  into previous_data
  from public.organization_economic_activities activity
  where activity.organization_id = target_organization_id
    and activity.status = 'active';

  update public.organization_economic_activities
  set
    status = 'inactive',
    is_primary = false,
    valid_until = current_date,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where organization_id = target_organization_id
    and status = 'active';

  for selected_item in
    select item
    from jsonb_array_elements(
      coalesce(selected_cnaes, '[]'::jsonb)
    ) item
  loop
    selected_catalog_id :=
      (selected_item ->> 'cnae_catalog_id')::uuid;

    selected_is_primary :=
      lower(
        coalesce(
          selected_item ->> 'is_primary',
          'false'
        )
      ) in ('true', '1', 'yes', 'sim');

    select catalog.*
    into catalog_row
    from public.cnae_catalog catalog
    join public.cnae_catalog_versions version
      on version.version_code = catalog.version_code
    where catalog.id = selected_catalog_id
      and catalog.active = true
      and version.active = true
      and version.is_current = true;

    if catalog_row.id is null then
      raise exception
        'CNAE oficial nÃ£o encontrado durante a gravaÃ§Ã£o.';
    end if;

    existing_activity_id := null;

    select activity.id
    into existing_activity_id
    from public.organization_economic_activities activity
    where activity.organization_id = target_organization_id
      and activity.cnae_code = catalog_row.subclass_code
    order by
      activity.updated_at desc nulls last,
      activity.created_at desc nulls last,
      activity.id
    limit 1;

    if existing_activity_id is null then
      insert into public.organization_economic_activities (
        organization_id,
        cnae_code,
        description,
        is_primary,
        status,
        cnae_catalog_id,
        verification_status,
        source_type,
        source_reference,
        verified_at,
        verified_by,
        valid_from,
        valid_until,
        created_by,
        updated_by
      )
      values (
        target_organization_id,
        catalog_row.subclass_code,
        catalog_row.description,
        selected_is_primary,
        'active',
        catalog_row.id,
        'verified',
        normalized_source_type,
        nullif(trim(target_source_reference), ''),
        timezone('utc', now()),
        auth.uid(),
        current_date,
        null,
        auth.uid(),
        auth.uid()
      );
    else
      update public.organization_economic_activities
      set
        description = catalog_row.description,
        is_primary = selected_is_primary,
        status = 'active',
        cnae_catalog_id = catalog_row.id,
        verification_status = 'verified',
        source_type = normalized_source_type,
        source_reference =
          nullif(trim(target_source_reference), ''),
        verified_at = timezone('utc', now()),
        verified_by = auth.uid(),
        valid_from = current_date,
        valid_until = null,
        updated_at = timezone('utc', now()),
        updated_by = auth.uid()
      where id = existing_activity_id;
    end if;

    if selected_is_primary then
      primary_description := catalog_row.description;
    end if;
  end loop;

  update public.organizations
  set
    primary_activity_description = primary_description,
    institutional_profile_updated_at = timezone('utc', now()),
    institutional_profile_updated_by = auth.uid(),
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where id = target_organization_id;

  select coalesce(
    jsonb_agg(
      to_jsonb(activity)
      order by
        activity.is_primary desc,
        activity.cnae_code
    ),
    '[]'::jsonb
  )
  into new_data
  from public.organization_economic_activities activity
  where activity.organization_id = target_organization_id
    and activity.status = 'active';

  insert into public.organization_cnae_audit (
    organization_id,
    actor_user_id,
    action_code,
    reason,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    auth.uid(),
    'cnaes_replaced_from_official_catalog',
    trim(change_reason),
    previous_data,
    new_data
  );

  return target_organization_id;
end;
$$;

revoke all on function public.replace_organization_cnaes_v3(
  uuid,
  jsonb,
  text,
  text,
  text
) from public;

grant execute on function public.replace_organization_cnaes_v3(
  uuid,
  jsonb,
  text,
  text,
  text
) to authenticated, service_role;

comment on function public.replace_organization_cnaes_v3(
  uuid,
  jsonb,
  text,
  text,
  text
) is
  'Substitui os CNAEs ativos usando o catÃ¡logo oficial vigente, sem depender de restriÃ§Ã£o ON CONFLICT, preservando auditoria e histÃ³rico.';

commit;