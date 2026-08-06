-- ============================================================
-- SPARKs-PaaS
-- FE-09.A.06 — Painel Principal
-- Fundação transversal de preferências pessoais por módulo
-- ============================================================

begin;

create table public.user_module_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references public.profiles(id)
    on delete cascade,
  organization_module_id uuid not null
    references public.organization_modules(id)
    on delete cascade,
  preference_key text not null,
  preference_value jsonb not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),

  constraint user_module_preferences_key_not_blank
    check (length(trim(preference_key)) > 0),

  constraint user_module_preferences_key_length
    check (length(preference_key) <= 120),

  constraint user_module_preferences_key_normalized
    check (preference_key = lower(trim(preference_key))),

  constraint user_module_preferences_key_format
    check (
      preference_key ~ '^[a-z0-9]+([._-][a-z0-9]+)*$'
    ),

  constraint user_module_preferences_value_object
    check (jsonb_typeof(preference_value) = 'object'),

  constraint user_module_preferences_unique
    unique (
      user_id,
      organization_module_id,
      preference_key
    )
);

comment on table public.user_module_preferences is
  'Preferências pessoais e transversais do usuário, contextualizadas por organização e módulo.';

comment on column public.user_module_preferences.user_id is
  'Usuário titular da preferência.';

comment on column public.user_module_preferences.organization_module_id is
  'Contexto modular da organização ao qual a preferência pertence.';

comment on column public.user_module_preferences.preference_key is
  'Chave funcional normalizada da preferência, como workspace.primary_dashboard.';

comment on column public.user_module_preferences.preference_value is
  'Valor versionado da preferência em formato JSON.';

create index idx_user_module_preferences_user
  on public.user_module_preferences(user_id);

create index idx_user_module_preferences_organization_module
  on public.user_module_preferences(organization_module_id);

alter table public.user_module_preferences
  enable row level security;

revoke all on table public.user_module_preferences
from anon, authenticated;

grant select on table public.user_module_preferences
to authenticated;

grant all on table public.user_module_preferences
to service_role;

create policy user_module_preferences_select_own_accessible
on public.user_module_preferences
for select
to authenticated
using (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.organization_modules as om
    join public.modules as m
      on m.id = om.module_id
    where om.id =
      user_module_preferences.organization_module_id
      and public.can_read_organization(
        om.organization_id
      )
      and public.has_module_access(
        om.organization_id,
        m.code
      )
  )
);

create or replace function public.get_my_module_preference(
  input_organization_id uuid,
  input_module_code text,
  input_preference_key text
)
returns table (
  preference_id uuid,
  preference_value jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  normalized_module_code text;
  normalized_preference_key text;
  selected_organization_module_id uuid;
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

  return query
  select
    ump.id,
    ump.preference_value,
    ump.created_at,
    ump.updated_at
  from public.user_module_preferences as ump
  where ump.user_id = current_user_id
    and ump.organization_module_id =
      selected_organization_module_id
    and ump.preference_key =
      normalized_preference_key;
end;
$function$;

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

create or replace function public.delete_my_module_preference(
  input_organization_id uuid,
  input_module_code text,
  input_preference_key text,
  change_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  normalized_module_code text;
  normalized_preference_key text;
  selected_organization_module_id uuid;
  deleted_row public.user_module_preferences%rowtype;
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

  delete from public.user_module_preferences as ump
  where ump.user_id = current_user_id
    and ump.organization_module_id =
      selected_organization_module_id
    and ump.preference_key =
      normalized_preference_key
  returning *
  into deleted_row;

  if deleted_row.id is null then
    return false;
  end if;

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
      'Preferência pessoal do módulo removida.'
    ),
    'public',
    'user_module_preferences',
    deleted_row.id::text,
    to_jsonb(deleted_row),
    null,
    jsonb_build_object(
      'source', 'user_module_preferences_rpc',
      'operation', 'delete',
      'module_code', normalized_module_code,
      'preference_key', normalized_preference_key,
      'organization_module_id',
        selected_organization_module_id
    )
  );

  return true;
end;
$function$;

revoke all on function public.get_my_module_preference(
  uuid,
  text,
  text
)
from public;

revoke all on function public.set_my_module_preference(
  uuid,
  text,
  text,
  jsonb,
  text
)
from public;

revoke all on function public.delete_my_module_preference(
  uuid,
  text,
  text,
  text
)
from public;

grant execute on function public.get_my_module_preference(
  uuid,
  text,
  text
)
to authenticated;

grant execute on function public.set_my_module_preference(
  uuid,
  text,
  text,
  jsonb,
  text
)
to authenticated;

grant execute on function public.delete_my_module_preference(
  uuid,
  text,
  text,
  text
)
to authenticated;

comment on function public.get_my_module_preference(
  uuid,
  text,
  text
)
is 'Retorna uma preferência pessoal do usuário autenticado no contexto de uma organização e módulo.';

comment on function public.set_my_module_preference(
  uuid,
  text,
  text,
  jsonb,
  text
)
is 'Cria ou atualiza uma preferência pessoal do usuário autenticado, com validação de acesso e auditoria.';

comment on function public.delete_my_module_preference(
  uuid,
  text,
  text,
  text
)
is 'Remove uma preferência pessoal do usuário autenticado, com validação de acesso e auditoria.';

commit;
