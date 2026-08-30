create or replace function public.get_sparks_organization_visual_identity(target_organization_id uuid)
returns table(
  organization_id uuid,
  logo_url text,
  logo_storage_path text,
  logo_version integer,
  visual_identity_metadata jsonb,
  effective_visual_identity jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if not (
    public.is_platform_super_admin()
    or exists (
      select 1
      from public.organization_memberships m
      where m.organization_id = target_organization_id
        and m.user_id = auth.uid()
        and m.status = 'active'
    )
  ) then
    raise exception 'Acesso negado: o usuário não pode consultar a identidade visual desta organização.' using errcode = '42501';
  end if;

  return query
  select
    o.id,
    o.logo_url,
    o.logo_storage_path,
    coalesce(o.logo_version, 0),
    coalesce(o.visual_identity_metadata, '{}'::jsonb),
    case
      when coalesce(o.visual_identity_metadata->>'mode', 'sparks_default') = 'organization'
      then jsonb_build_object(
        'schema_version', 1,
        'mode', 'organization',
        'palette_source', coalesce(o.visual_identity_metadata->>'palette_source', 'manual'),
        'colors', jsonb_build_object(
          'primary', coalesce(o.visual_identity_metadata#>>'{colors,primary}', '#176B53'),
          'secondary', coalesce(o.visual_identity_metadata#>>'{colors,secondary}', '#123F34'),
          'accent', coalesce(o.visual_identity_metadata#>>'{colors,accent}', '#1F8C69'),
          'on_primary', coalesce(o.visual_identity_metadata#>>'{colors,on_primary}', '#FFFFFF')
        ),
        'suggested_from_logo', coalesce(o.visual_identity_metadata->'suggested_from_logo', 'null'::jsonb)
      )
      else jsonb_build_object(
        'schema_version', 1,
        'mode', 'sparks_default',
        'palette_source', 'default',
        'colors', jsonb_build_object(
          'primary', '#176B53',
          'secondary', '#123F34',
          'accent', '#1F8C69',
          'on_primary', '#FFFFFF'
        ),
        'suggested_from_logo', 'null'::jsonb
      )
    end
  from public.organizations o
  where o.id = target_organization_id;
end;
$function$;

revoke all on function public.get_sparks_organization_visual_identity(uuid) from public;
revoke all on function public.get_sparks_organization_visual_identity(uuid) from anon;
grant execute on function public.get_sparks_organization_visual_identity(uuid) to authenticated;

create or replace function public.update_sparks_organization_visual_identity(
  target_organization_id uuid,
  target_theme_mode text,
  target_primary_color text,
  target_secondary_color text,
  target_accent_color text,
  target_palette_source text,
  target_logo_palette jsonb,
  change_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  normalized_mode text := lower(trim(coalesce(target_theme_mode, '')));
  normalized_source text := lower(trim(coalesce(target_palette_source, '')));
  normalized_primary text := upper(trim(coalesce(target_primary_color, '')));
  normalized_secondary text := upper(trim(coalesce(target_secondary_color, '')));
  normalized_accent text := upper(trim(coalesce(target_accent_color, '')));
  normalized_logo_palette jsonb := coalesce(target_logo_palette, '[]'::jsonb);
  previous_metadata jsonb;
  next_metadata jsonb;
  current_logo_version integer;
  primary_r integer;
  primary_g integer;
  primary_b integer;
  on_primary text;
  palette_item jsonb;
  palette_count integer;
begin
  if not (
    public.is_platform_super_admin()
    or public.is_organization_admin(target_organization_id)
    or public.has_module_permission(target_organization_id, 'SK-ASM', 'organization_profile.manage')
  ) then
    raise exception 'Acesso negado: o usuário não pode alterar a identidade visual desta organização.' using errcode = '42501';
  end if;

  if length(trim(coalesce(change_reason, ''))) < 10 then
    raise exception 'Informe uma justificativa com pelo menos 10 caracteres.';
  end if;

  if normalized_mode not in ('sparks_default', 'organization') then
    raise exception 'Modo de identidade visual inválido.';
  end if;

  select coalesce(o.visual_identity_metadata, '{}'::jsonb), coalesce(o.logo_version, 0)
    into previous_metadata, current_logo_version
  from public.organizations o
  where o.id = target_organization_id
  for update;

  if not found then
    raise exception 'Organização não encontrada.';
  end if;

  if normalized_mode = 'sparks_default' then
    next_metadata := jsonb_build_object(
      'schema_version', 1,
      'mode', 'sparks_default',
      'palette_source', 'default'
    );
  else
    if normalized_source not in ('manual', 'logo_suggested') then
      raise exception 'Origem da paleta inválida para identidade organizacional.';
    end if;

    if normalized_primary !~ '^#[0-9A-F]{6}$'
      or normalized_secondary !~ '^#[0-9A-F]{6}$'
      or normalized_accent !~ '^#[0-9A-F]{6}$' then
      raise exception 'As cores devem usar o formato hexadecimal #RRGGBB.';
    end if;

    if jsonb_typeof(normalized_logo_palette) <> 'array' then
      raise exception 'A paleta sugerida pela logo deve ser um array JSON.';
    end if;

    palette_count := jsonb_array_length(normalized_logo_palette);
    if palette_count > 8 then
      raise exception 'A paleta sugerida pela logo pode conter no máximo 8 cores.';
    end if;

    for palette_item in select value from jsonb_array_elements(normalized_logo_palette)
    loop
      if jsonb_typeof(palette_item) <> 'string'
         or upper(trim(palette_item #>> '{}')) !~ '^#[0-9A-F]{6}$' then
        raise exception 'A paleta sugerida pela logo contém uma cor inválida.';
      end if;
    end loop;

    primary_r := ('x' || substr(normalized_primary, 2, 2))::bit(8)::integer;
    primary_g := ('x' || substr(normalized_primary, 4, 2))::bit(8)::integer;
    primary_b := ('x' || substr(normalized_primary, 6, 2))::bit(8)::integer;

    on_primary := case
      when ((primary_r * 299) + (primary_g * 587) + (primary_b * 114)) / 1000 >= 160
        then '#18231F'
      else '#FFFFFF'
    end;

    next_metadata := jsonb_build_object(
      'schema_version', 1,
      'mode', 'organization',
      'palette_source', normalized_source,
      'colors', jsonb_build_object(
        'primary', normalized_primary,
        'secondary', normalized_secondary,
        'accent', normalized_accent,
        'on_primary', on_primary
      ),
      'suggested_from_logo', case
        when normalized_source = 'logo_suggested' then jsonb_build_object(
          'logo_version', current_logo_version,
          'colors', normalized_logo_palette
        )
        else 'null'::jsonb
      end
    );
  end if;

  update public.organizations
  set visual_identity_metadata = next_metadata,
      institutional_profile_updated_at = timezone('utc', now()),
      institutional_profile_updated_by = auth.uid(),
      updated_at = timezone('utc', now()),
      updated_by = auth.uid()
  where id = target_organization_id;

  insert into public.organization_access_audit(
    organization_id,
    actor_user_id,
    target_user_id,
    module_id,
    action_code,
    reason,
    previous_data,
    new_data
  ) values (
    target_organization_id,
    auth.uid(),
    null,
    null,
    'organization.visual_identity.updated',
    trim(change_reason),
    previous_metadata,
    next_metadata
  );

  return next_metadata;
end;
$function$;

revoke all on function public.update_sparks_organization_visual_identity(uuid, text, text, text, text, text, jsonb, text) from public;
revoke all on function public.update_sparks_organization_visual_identity(uuid, text, text, text, text, text, jsonb, text) from anon;
grant execute on function public.update_sparks_organization_visual_identity(uuid, text, text, text, text, text, jsonb, text) to authenticated;
