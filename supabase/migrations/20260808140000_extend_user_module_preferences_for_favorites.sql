-- ============================================================
-- SPARKs-PaaS
-- FE-09.A.14 — Favoritos
-- Extensão da preferência transversal workspace.favorites
-- ============================================================

begin;

create or replace function public.set_my_module_preference(
  input_organization_id uuid,
  input_module_code text,
  input_preference_key text,
  input_preference_value jsonb,
  change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  normalized_module_code text;
  normalized_preference_key text;
  selected_organization_module_id uuid;
  previous_row public.user_module_preferences%rowtype;
  saved_row public.user_module_preferences%rowtype;
  favorite_count integer;
  distinct_favorite_count integer;
begin
  if current_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if input_organization_id is null then
    raise exception 'A organização é obrigatória.'
      using errcode = '22023';
  end if;

  normalized_module_code :=
    upper(trim(coalesce(input_module_code, '')));

  if normalized_module_code = '' then
    raise exception 'O código do módulo é obrigatório.'
      using errcode = '22023';
  end if;

  normalized_preference_key :=
    lower(trim(coalesce(input_preference_key, '')));

  if normalized_preference_key = '' then
    raise exception 'A chave da preferência é obrigatória.'
      using errcode = '22023';
  end if;

  if length(normalized_preference_key) > 120 then
    raise exception 'A chave da preferência deve ter no máximo 120 caracteres.'
      using errcode = '22023';
  end if;

  if normalized_preference_key
    !~ '^[a-z0-9]+([._-][a-z0-9]+)*$'
  then
    raise exception 'A chave da preferência possui formato inválido.'
      using errcode = '22023';
  end if;

  if input_preference_value is null
    or jsonb_typeof(input_preference_value) <> 'object'
  then
    raise exception 'O valor da preferência deve ser um objeto JSON.'
      using errcode = '22023';
  end if;

  if normalized_preference_key =
    'workspace.primary_dashboard'
  then
    if coalesce(
      trim(input_preference_value ->> 'dashboard_id'),
      ''
    ) = '' then
      raise exception 'O identificador do painel principal é obrigatório.'
        using errcode = '22023';
    end if;

    if (
      input_preference_value ->> 'dashboard_id'
    ) !~ '^[a-z0-9]+([._-][a-z0-9]+)*$' then
      raise exception 'O identificador do painel principal possui formato inválido.'
        using errcode = '22023';
    end if;

    if (
      input_preference_value ->> 'dashboard_id'
    ) not in (
      'my-work',
      'executive',
      'portfolio',
      'governance'
    ) then
      raise exception 'O painel informado não está elegível como Painel Principal.'
        using errcode = '22023';
    end if;

    if coalesce(
      input_preference_value ->> 'schema_version',
      ''
    ) !~ '^[0-9]+$' then
      raise exception 'A versão do esquema da preferência é obrigatória.'
        using errcode = '22023';
    end if;

    if (
      input_preference_value ->> 'schema_version'
    )::integer <> 1 then
      raise exception 'A versão do esquema da preferência não é compatível.'
        using errcode = '22023';
    end if;
  elsif normalized_preference_key =
    'workspace.favorites'
  then
    if coalesce(
      input_preference_value ->> 'schema_version',
      ''
    ) !~ '^[0-9]+$' then
      raise exception 'A versão do esquema da preferência de favoritos é obrigatória.'
        using errcode = '22023';
    end if;

    if (
      input_preference_value ->> 'schema_version'
    )::integer <> 1 then
      raise exception 'A versão do esquema da preferência de favoritos não é compatível.'
        using errcode = '22023';
    end if;

    if not (input_preference_value ? 'dashboard_ids')
      or jsonb_typeof(
        input_preference_value -> 'dashboard_ids'
      ) <> 'array'
    then
      raise exception 'A lista de painéis favoritos deve ser um array.'
        using errcode = '22023';
    end if;

    select count(*)
    into favorite_count
    from jsonb_array_elements(
      input_preference_value -> 'dashboard_ids'
    ) as item
    where jsonb_typeof(item) = 'string';

    if favorite_count <> jsonb_array_length(
      input_preference_value -> 'dashboard_ids'
    ) then
      raise exception 'Todos os identificadores de favoritos devem ser textos.'
        using errcode = '22023';
    end if;

    if favorite_count > 4 then
      raise exception 'É permitido salvar no máximo 4 painéis favoritos nesta versão.'
        using errcode = '22023';
    end if;

    if exists (
      select 1
      from jsonb_array_elements_text(
        input_preference_value -> 'dashboard_ids'
      ) as favorite_id
      where favorite_id not in (
        'my-work',
        'executive',
        'portfolio',
        'governance'
      )
    ) then
      raise exception 'Um ou mais painéis não estão elegíveis como favoritos.'
        using errcode = '22023';
    end if;

    select count(distinct favorite_id)
    into distinct_favorite_count
    from jsonb_array_elements_text(
      input_preference_value -> 'dashboard_ids'
    ) as favorite_id;

    if distinct_favorite_count <> favorite_count then
      raise exception 'A lista de favoritos não pode conter painéis duplicados.'
        using errcode = '22023';
    end if;
  end if;

  if not public.can_read_organization(
    input_organization_id
  ) then
    raise exception 'Você não possui acesso à organização informada.';
  end if;

  if not public.has_module_access(
    input_organization_id,
    normalized_module_code
  ) then
    raise exception 'Você não possui acesso ao módulo informado.';
  end if;

  select om.id
  into selected_organization_module_id
  from public.organization_modules as om
  join public.modules as m
    on m.id = om.module_id
  where om.organization_id = input_organization_id
    and m.code = normalized_module_code
    and m.status = 'active'
    and om.enabled = true
    and om.status in ('trial', 'active')
    and om.valid_from <= timezone('utc', now())
    and (
      om.valid_until is null
      or om.valid_until >= timezone('utc', now())
    )
  limit 1;

  if selected_organization_module_id is null then
    raise exception 'O módulo não está disponível para a organização informada.';
  end if;

  select ump.*
  into previous_row
  from public.user_module_preferences as ump
  where ump.user_id = current_user_id
    and ump.organization_module_id =
      selected_organization_module_id
    and ump.preference_key =
      normalized_preference_key;

  insert into public.user_module_preferences (
    user_id,
    organization_module_id,
    preference_key,
    preference_value
  )
  values (
    current_user_id,
    selected_organization_module_id,
    normalized_preference_key,
    input_preference_value
  )
  on conflict (
    user_id,
    organization_module_id,
    preference_key
  )
  do update
  set
    preference_value = excluded.preference_value,
    updated_at = timezone('utc', now())
  returning *
  into saved_row;

  insert into public.privileged_access_audit (
    actor_user_id,
    organization_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    previous_data,
    new_data,
    metadata
  )
  values (
    current_user_id,
    input_organization_id,
    'configuration_changed',
    coalesce(
      nullif(trim(change_reason), ''),
      'Preferência pessoal do módulo atualizada.'
    ),
    'public',
    'user_module_preferences',
    saved_row.id::text,
    case
      when previous_row.id is null then null
      else to_jsonb(previous_row)
    end,
    to_jsonb(saved_row),
    jsonb_build_object(
      'source', 'user_module_preferences_rpc',
      'operation',
        case
          when previous_row.id is null then 'insert'
          else 'update'
        end,
      'module_code', normalized_module_code,
      'preference_key', normalized_preference_key,
      'organization_module_id',
        selected_organization_module_id
    )
  );

  return saved_row.id;
end;
$function$;

revoke all on function public.set_my_module_preference(
  uuid,
  text,
  text,
  jsonb,
  text
)
from public;

grant execute on function public.set_my_module_preference(
  uuid,
  text,
  text,
  jsonb,
  text
)
to authenticated;

comment on function public.set_my_module_preference(
  uuid,
  text,
  text,
  jsonb,
  text
)
is 'Cria ou atualiza uma preferência pessoal do usuário autenticado, incluindo Painel Principal e Favoritos, com validação de acesso e auditoria.';

commit;
