-- ============================================================
-- Plataforma SPARKs
-- Administração global da plataforma para SUPER-ADMIN
-- Data: 2026-07-27
-- ============================================================

begin;

-- ------------------------------------------------------------
-- Fila auditável de convites de usuários.
-- A criação da conta de autenticação é executada pela Edge
-- Function invite-platform-user, nunca pelo navegador.
-- ------------------------------------------------------------

create table if not exists public.platform_user_invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  full_name text,
  organization_id uuid references public.organizations(id) on delete restrict,
  platform_role_id uuid references public.platform_roles(id) on delete restrict,
  is_organization_admin boolean not null default false,
  job_title text,
  status text not null default 'pending'
    check (status in ('pending', 'sent', 'accepted', 'cancelled', 'failed')),
  requested_at timestamptz not null default timezone('utc', now()),
  requested_by uuid references auth.users(id),
  sent_at timestamptz,
  accepted_at timestamptz,
  cancelled_at timestamptz,
  failure_reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists ux_platform_user_invitations_open_email
  on public.platform_user_invitations (lower(email))
  where status in ('pending', 'sent');

create index if not exists idx_platform_user_invitations_status
  on public.platform_user_invitations (status, requested_at desc);

create index if not exists idx_platform_user_invitations_organization
  on public.platform_user_invitations (organization_id);

alter table public.platform_user_invitations enable row level security;

-- ------------------------------------------------------------
-- Utilitário interno de autorização.
-- ------------------------------------------------------------

create or replace function public.require_platform_super_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_platform_super_admin() then
    raise exception 'Acesso restrito ao SUPER-ADMIN da Plataforma SPARKs.'
      using errcode = '42501';
  end if;
end;
$$;

-- ------------------------------------------------------------
-- Resumo executivo da administração global.
-- ------------------------------------------------------------

create or replace function public.get_platform_admin_summary()
returns table (
  organizations_total bigint,
  organizations_active bigint,
  users_total bigint,
  users_active bigint,
  memberships_active bigint,
  modules_total bigint,
  modules_active bigint,
  pending_invitations bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    (select count(*) from public.organizations),
    (select count(*) from public.organizations where status::text = 'active'),
    (select count(*) from public.profiles),
    (select count(*) from public.profiles where active = true),
    (select count(*) from public.organization_memberships where status::text = 'active'),
    (select count(*) from public.modules),
    (select count(*) from public.modules where status = 'active'),
    (select count(*) from public.platform_user_invitations where status = 'pending');
end;
$$;

-- ------------------------------------------------------------
-- Valores válidos do enum de nível organizacional.
-- ------------------------------------------------------------

create or replace function public.get_platform_admin_organization_levels()
returns table (
  level_code text,
  level_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    enum_value::text,
    case enum_value::text
      when 'singular' then 'Cooperativa singular'
      when 'federation_central' then 'Central ou federação'
      when 'confederation' then 'Confederação'
      when 'system_guardian' then 'Organização guardiã do sistema'
      when 'matrix' then 'Matriz'
      when 'branch' then 'Filial'
      when 'unit' then 'Unidade'
      when 'national' then 'Nacional'
      when 'state' then 'Estadual'
      when 'municipal' then 'Municipal'
      else initcap(replace(enum_value::text, '_', ' '))
    end
  from unnest(enum_range(null::public.organization_level)) enum_value
  order by 2;
end;
$$;

-- ------------------------------------------------------------
-- Organizações globais.
-- ------------------------------------------------------------

create or replace function public.get_platform_admin_organizations()
returns table (
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  organization_level text,
  organization_type text,
  status text,
  parent_organization_id uuid,
  parent_organization_name text,
  cnpj text,
  state_code text,
  city text,
  institutional_email text,
  cooperative_branch text,
  memberships_count bigint,
  enabled_modules_count bigint,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    o.id,
    o.code,
    o.legal_name,
    o.trade_name,
    o.organization_level::text,
    o.organization_type,
    o.status::text,
    o.parent_organization_id,
    coalesce(parent.trade_name, parent.legal_name, parent.code),
    coalesce(o.cnpj, o.tax_identifier),
    o.state_code::text,
    o.city,
    coalesce(o.institutional_email, o.email),
    o.cooperative_branch,
    (
      select count(*)
      from public.organization_memberships om
      where om.organization_id = o.id
        and om.status::text <> 'revoked'
    ),
    (
      select count(*)
      from public.organization_modules orm
      where orm.organization_id = o.id
        and orm.enabled = true
        and orm.status = 'active'
    ),
    o.created_at,
    o.updated_at
  from public.organizations o
  left join public.organizations parent
    on parent.id = o.parent_organization_id
  order by lower(coalesce(o.trade_name, o.legal_name, o.code));
end;
$$;

create or replace function public.upsert_platform_admin_organization(
  target_organization_id uuid,
  input_code text,
  input_legal_name text,
  input_trade_name text default null,
  input_organization_level text default 'singular',
  input_organization_type text default null,
  input_status text default 'draft',
  input_parent_organization_id uuid default null,
  input_cnpj text default null,
  input_state_code text default null,
  input_city text default null,
  input_institutional_email text default null,
  input_cooperative_branch text default null,
  input_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
  normalized_code text := upper(trim(input_code));
  normalized_legal_name text := trim(input_legal_name);
begin
  perform public.require_platform_super_admin();

  if normalized_code is null or normalized_code = '' then
    raise exception 'Informe o código da organização.';
  end if;

  if normalized_legal_name is null or normalized_legal_name = '' then
    raise exception 'Informe a razão social da organização.';
  end if;

  if input_parent_organization_id = target_organization_id
     and target_organization_id is not null then
    raise exception 'A organização não pode ser superior a si mesma.';
  end if;

  if target_organization_id is null then
    insert into public.organizations (
      code,
      legal_name,
      trade_name,
      organization_level,
      organization_type,
      status,
      parent_organization_id,
      cnpj,
      tax_identifier,
      state_code,
      city,
      institutional_email,
      email,
      cooperative_branch,
      description,
      created_by,
      updated_by
    )
    values (
      normalized_code,
      normalized_legal_name,
      nullif(trim(input_trade_name), ''),
      input_organization_level::public.organization_level,
      nullif(trim(input_organization_type), ''),
      input_status::public.organization_status,
      input_parent_organization_id,
      nullif(regexp_replace(coalesce(input_cnpj, ''), '[^0-9]', '', 'g'), ''),
      nullif(regexp_replace(coalesce(input_cnpj, ''), '[^0-9]', '', 'g'), ''),
      nullif(upper(trim(input_state_code)), ''),
      nullif(trim(input_city), ''),
      nullif(lower(trim(input_institutional_email)), ''),
      nullif(lower(trim(input_institutional_email)), ''),
      nullif(trim(input_cooperative_branch), ''),
      nullif(trim(input_description), ''),
      auth.uid(),
      auth.uid()
    )
    returning id into result_id;
  else
    update public.organizations
    set
      code = normalized_code,
      legal_name = normalized_legal_name,
      trade_name = nullif(trim(input_trade_name), ''),
      organization_level = input_organization_level::public.organization_level,
      organization_type = nullif(trim(input_organization_type), ''),
      status = input_status::public.organization_status,
      parent_organization_id = input_parent_organization_id,
      cnpj = nullif(regexp_replace(coalesce(input_cnpj, ''), '[^0-9]', '', 'g'), ''),
      tax_identifier = nullif(regexp_replace(coalesce(input_cnpj, ''), '[^0-9]', '', 'g'), ''),
      state_code = nullif(upper(trim(input_state_code)), ''),
      city = nullif(trim(input_city), ''),
      institutional_email = nullif(lower(trim(input_institutional_email)), ''),
      email = nullif(lower(trim(input_institutional_email)), ''),
      cooperative_branch = nullif(trim(input_cooperative_branch), ''),
      description = nullif(trim(input_description), ''),
      archived_at = case
        when input_status = 'archived' then coalesce(archived_at, timezone('utc', now()))
        else null
      end,
      updated_by = auth.uid(),
      updated_at = timezone('utc', now())
    where id = target_organization_id
    returning id into result_id;

    if result_id is null then
      raise exception 'Organização não encontrada.';
    end if;
  end if;

  insert into public.privileged_access_audit (
    actor_user_id,
    organization_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    new_data,
    metadata
  ) values (
    auth.uid(),
    result_id,
    case when target_organization_id is null then 'data_created' else 'data_updated' end,
    case when target_organization_id is null
      then 'Organização criada pela Administração da Plataforma.'
      else 'Organização atualizada pela Administração da Plataforma.'
    end,
    'public',
    'organizations',
    result_id::text,
    jsonb_build_object(
      'code', normalized_code,
      'legal_name', normalized_legal_name,
      'status', input_status
    ),
    jsonb_build_object('source', 'platform_admin')
  );

  return result_id;
end;
$$;

create or replace function public.set_platform_admin_organization_status(
  target_organization_id uuid,
  input_status text,
  input_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  if trim(coalesce(input_reason, '')) = '' then
    raise exception 'Informe a justificativa da alteração.';
  end if;

  update public.organizations
  set
    status = input_status::public.organization_status,
    archived_at = case
      when input_status = 'archived' then timezone('utc', now())
      else null
    end,
    updated_by = auth.uid(),
    updated_at = timezone('utc', now())
  where id = target_organization_id;

  if not found then
    raise exception 'Organização não encontrada.';
  end if;

  insert into public.privileged_access_audit (
    actor_user_id,
    organization_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    metadata
  ) values (
    auth.uid(),
    target_organization_id,
    'configuration_changed',
    input_reason,
    'public',
    'organizations',
    target_organization_id::text,
    jsonb_build_object('status', input_status, 'source', 'platform_admin')
  );
end;
$$;

-- ------------------------------------------------------------
-- Usuários, vínculos e papéis globais.
-- ------------------------------------------------------------

create or replace function public.get_platform_admin_users()
returns table (
  user_id uuid,
  full_name text,
  display_name text,
  email text,
  phone text,
  active boolean,
  platform_roles text,
  memberships_count bigint,
  admin_memberships_count bigint,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    p.id,
    p.full_name,
    p.display_name,
    p.email,
    p.phone,
    p.active,
    coalesce((
      select string_agg(pr.name, ', ' order by pr.name)
      from public.user_platform_roles upr
      join public.platform_roles pr on pr.id = upr.platform_role_id
      where upr.user_id = p.id
        and upr.status = 'active'
        and pr.active = true
        and upr.valid_from <= timezone('utc', now())
        and (upr.valid_until is null or upr.valid_until >= timezone('utc', now()))
    ), ''),
    (
      select count(*)
      from public.organization_memberships om
      where om.user_id = p.id
        and om.status::text <> 'revoked'
    ),
    (
      select count(*)
      from public.organization_memberships om
      where om.user_id = p.id
        and om.status::text = 'active'
        and om.is_organization_admin = true
    ),
    p.created_at,
    p.updated_at
  from public.profiles p
  order by lower(coalesce(p.display_name, p.full_name, p.email, p.id::text));
end;
$$;

create or replace function public.update_platform_admin_user_profile(
  target_user_id uuid,
  input_full_name text,
  input_display_name text default null,
  input_phone text default null,
  input_active boolean default true
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  update public.profiles
  set
    full_name = nullif(trim(input_full_name), ''),
    display_name = coalesce(nullif(trim(input_display_name), ''), nullif(trim(input_full_name), '')),
    phone = nullif(trim(input_phone), ''),
    active = input_active,
    updated_at = timezone('utc', now())
  where id = target_user_id;

  if not found then
    raise exception 'Usuário não encontrado.';
  end if;

  insert into public.privileged_access_audit (
    actor_user_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    metadata
  ) values (
    auth.uid(),
    'data_updated',
    'Perfil de usuário atualizado pela Administração da Plataforma.',
    'public',
    'profiles',
    target_user_id::text,
    jsonb_build_object('source', 'platform_admin', 'active', input_active)
  );
end;
$$;

create or replace function public.get_platform_admin_memberships(
  filter_user_id uuid default null,
  filter_organization_id uuid default null
)
returns table (
  membership_id uuid,
  user_id uuid,
  user_name text,
  user_email text,
  organization_id uuid,
  organization_name text,
  organization_code text,
  membership_status text,
  is_organization_admin boolean,
  job_title text,
  valid_from timestamptz,
  valid_until timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    om.id,
    om.user_id,
    coalesce(p.display_name, p.full_name, p.email, om.user_id::text),
    p.email,
    om.organization_id,
    coalesce(o.trade_name, o.legal_name, o.code),
    o.code,
    om.status::text,
    om.is_organization_admin,
    om.job_title,
    om.valid_from,
    om.valid_until
  from public.organization_memberships om
  join public.organizations o on o.id = om.organization_id
  left join public.profiles p on p.id = om.user_id
  where (filter_user_id is null or om.user_id = filter_user_id)
    and (filter_organization_id is null or om.organization_id = filter_organization_id)
  order by
    lower(coalesce(o.trade_name, o.legal_name, o.code)),
    lower(coalesce(p.display_name, p.full_name, p.email, om.user_id::text));
end;
$$;

create or replace function public.upsert_platform_admin_membership(
  target_membership_id uuid,
  target_organization_id uuid,
  target_user_id uuid,
  input_status text default 'active',
  input_is_organization_admin boolean default false,
  input_job_title text default null,
  input_valid_until timestamptz default null,
  input_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
begin
  perform public.require_platform_super_admin();

  if trim(coalesce(input_reason, '')) = '' then
    raise exception 'Informe a justificativa do vínculo.';
  end if;

  if target_membership_id is null then
    insert into public.organization_memberships (
      organization_id,
      user_id,
      status,
      is_organization_admin,
      job_title,
      valid_from,
      valid_until,
      invited_by,
      activated_at,
      created_by,
      updated_by
    ) values (
      target_organization_id,
      target_user_id,
      input_status::public.membership_status,
      input_is_organization_admin,
      nullif(trim(input_job_title), ''),
      timezone('utc', now()),
      input_valid_until,
      auth.uid(),
      case when input_status = 'active' then timezone('utc', now()) else null end,
      auth.uid(),
      auth.uid()
    )
    on conflict (organization_id, user_id)
    do update set
      status = excluded.status,
      is_organization_admin = excluded.is_organization_admin,
      job_title = excluded.job_title,
      valid_until = excluded.valid_until,
      activated_at = case
        when excluded.status::text = 'active'
        then coalesce(public.organization_memberships.activated_at, timezone('utc', now()))
        else public.organization_memberships.activated_at
      end,
      suspended_at = case when excluded.status::text = 'suspended' then timezone('utc', now()) else null end,
      revoked_at = case when excluded.status::text = 'revoked' then timezone('utc', now()) else null end,
      updated_by = auth.uid(),
      updated_at = timezone('utc', now())
    returning id into result_id;
  else
    update public.organization_memberships
    set
      organization_id = target_organization_id,
      user_id = target_user_id,
      status = input_status::public.membership_status,
      is_organization_admin = input_is_organization_admin,
      job_title = nullif(trim(input_job_title), ''),
      valid_until = input_valid_until,
      activated_at = case
        when input_status = 'active' then coalesce(activated_at, timezone('utc', now()))
        else activated_at
      end,
      suspended_at = case when input_status = 'suspended' then timezone('utc', now()) else null end,
      revoked_at = case when input_status = 'revoked' then timezone('utc', now()) else null end,
      updated_by = auth.uid(),
      updated_at = timezone('utc', now())
    where id = target_membership_id
    returning id into result_id;
  end if;

  if result_id is null then
    raise exception 'Não foi possível manter o vínculo organizacional.';
  end if;

  insert into public.privileged_access_audit (
    actor_user_id,
    organization_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    metadata
  ) values (
    auth.uid(),
    target_organization_id,
    'configuration_changed',
    input_reason,
    'public',
    'organization_memberships',
    result_id::text,
    jsonb_build_object(
      'source', 'platform_admin',
      'user_id', target_user_id,
      'status', input_status,
      'is_organization_admin', input_is_organization_admin
    )
  );

  return result_id;
end;
$$;

create or replace function public.get_platform_admin_platform_roles()
returns table (
  platform_role_id uuid,
  role_code text,
  role_name text,
  description text,
  role_level integer,
  active boolean,
  users_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    pr.id,
    pr.code,
    pr.name,
    pr.description,
    pr.role_level,
    pr.active,
    (
      select count(*)
      from public.user_platform_roles upr
      where upr.platform_role_id = pr.id
        and upr.status = 'active'
    )
  from public.platform_roles pr
  order by pr.role_level desc, lower(pr.name);
end;
$$;

create or replace function public.get_platform_admin_user_roles(
  target_user_id uuid
)
returns table (
  platform_role_id uuid,
  role_code text,
  role_name text,
  role_level integer,
  assigned boolean,
  assignment_status text,
  user_platform_role_id uuid
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    pr.id,
    pr.code,
    pr.name,
    pr.role_level,
    (upr.id is not null and upr.status = 'active'),
    upr.status,
    upr.id
  from public.platform_roles pr
  left join public.user_platform_roles upr
    on upr.platform_role_id = pr.id
   and upr.user_id = target_user_id
  order by pr.role_level desc, lower(pr.name);
end;
$$;

create or replace function public.set_platform_admin_user_role(
  target_user_id uuid,
  target_platform_role_id uuid,
  input_assigned boolean,
  input_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  if trim(coalesce(input_reason, '')) = '' then
    raise exception 'Informe a justificativa da atribuição.';
  end if;

  if input_assigned then
    insert into public.user_platform_roles (
      user_id,
      platform_role_id,
      status,
      valid_from,
      assigned_at,
      assigned_by,
      assignment_reason
    ) values (
      target_user_id,
      target_platform_role_id,
      'active',
      timezone('utc', now()),
      timezone('utc', now()),
      auth.uid(),
      input_reason
    )
    on conflict (user_id, platform_role_id)
    do update set
      status = 'active',
      valid_from = timezone('utc', now()),
      valid_until = null,
      assigned_at = timezone('utc', now()),
      assigned_by = auth.uid(),
      suspended_at = null,
      suspended_by = null,
      revoked_at = null,
      revoked_by = null,
      assignment_reason = excluded.assignment_reason,
      updated_at = timezone('utc', now());
  else
    update public.user_platform_roles
    set
      status = 'revoked',
      revoked_at = timezone('utc', now()),
      revoked_by = auth.uid(),
      assignment_reason = input_reason,
      updated_at = timezone('utc', now())
    where user_id = target_user_id
      and platform_role_id = target_platform_role_id;
  end if;

  insert into public.privileged_access_audit (
    actor_user_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    metadata
  ) values (
    auth.uid(),
    'configuration_changed',
    input_reason,
    'public',
    'user_platform_roles',
    target_user_id::text,
    jsonb_build_object(
      'source', 'platform_admin',
      'platform_role_id', target_platform_role_id,
      'assigned', input_assigned
    )
  );
end;
$$;

-- ------------------------------------------------------------
-- Módulos da plataforma e habilitação por organização.
-- ------------------------------------------------------------

create or replace function public.get_platform_admin_modules()
returns table (
  module_id uuid,
  module_code text,
  module_name text,
  module_short_name text,
  description text,
  status text,
  is_core boolean,
  display_order integer,
  enabled_organizations_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    m.id,
    m.code,
    m.name,
    m.short_name,
    m.description,
    m.status,
    m.is_core,
    m.display_order,
    (
      select count(*)
      from public.organization_modules om
      where om.module_id = m.id
        and om.enabled = true
        and om.status = 'active'
    )
  from public.modules m
  order by m.display_order, lower(m.name);
end;
$$;

create or replace function public.get_platform_admin_organization_modules(
  target_organization_id uuid
)
returns table (
  module_id uuid,
  module_code text,
  module_name text,
  module_short_name text,
  module_status text,
  organization_module_id uuid,
  enabled boolean,
  organization_module_status text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    m.id,
    m.code,
    m.name,
    m.short_name,
    m.status,
    om.id,
    coalesce(om.enabled, false),
    om.status
  from public.modules m
  left join public.organization_modules om
    on om.module_id = m.id
   and om.organization_id = target_organization_id
  order by m.display_order, lower(m.name);
end;
$$;

create or replace function public.set_platform_admin_organization_module(
  target_organization_id uuid,
  target_module_id uuid,
  input_enabled boolean,
  input_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
begin
  perform public.require_platform_super_admin();

  if trim(coalesce(input_reason, '')) = '' then
    raise exception 'Informe a justificativa da alteração do módulo.';
  end if;

  insert into public.organization_modules (
    organization_id,
    module_id,
    status,
    enabled,
    enabled_at,
    disabled_at,
    valid_from,
    created_by,
    updated_by
  ) values (
    target_organization_id,
    target_module_id,
    case when input_enabled then 'active' else 'cancelled' end,
    input_enabled,
    case when input_enabled then timezone('utc', now()) else null end,
    case when input_enabled then null else timezone('utc', now()) end,
    timezone('utc', now()),
    auth.uid(),
    auth.uid()
  )
  on conflict (organization_id, module_id)
  do update set
    status = case when input_enabled then 'active' else 'cancelled' end,
    enabled = input_enabled,
    enabled_at = case
      when input_enabled then coalesce(public.organization_modules.enabled_at, timezone('utc', now()))
      else public.organization_modules.enabled_at
    end,
    disabled_at = case when input_enabled then null else timezone('utc', now()) end,
    valid_until = null,
    updated_by = auth.uid(),
    updated_at = timezone('utc', now())
  returning id into result_id;

  insert into public.privileged_access_audit (
    actor_user_id,
    organization_id,
    event_type,
    event_description,
    entity_schema,
    entity_table,
    entity_id,
    metadata
  ) values (
    auth.uid(),
    target_organization_id,
    'configuration_changed',
    input_reason,
    'public',
    'organization_modules',
    result_id::text,
    jsonb_build_object(
      'source', 'platform_admin',
      'module_id', target_module_id,
      'enabled', input_enabled
    )
  );

  return result_id;
end;
$$;

-- ------------------------------------------------------------
-- Convites auditáveis.
-- ------------------------------------------------------------

create or replace function public.get_platform_admin_invitations()
returns table (
  invitation_id uuid,
  email text,
  full_name text,
  organization_id uuid,
  organization_name text,
  platform_role_id uuid,
  platform_role_name text,
  is_organization_admin boolean,
  job_title text,
  status text,
  requested_at timestamptz,
  sent_at timestamptz,
  failure_reason text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select
    i.id,
    i.email,
    i.full_name,
    i.organization_id,
    coalesce(o.trade_name, o.legal_name, o.code),
    i.platform_role_id,
    pr.name,
    i.is_organization_admin,
    i.job_title,
    i.status,
    i.requested_at,
    i.sent_at,
    i.failure_reason
  from public.platform_user_invitations i
  left join public.organizations o on o.id = i.organization_id
  left join public.platform_roles pr on pr.id = i.platform_role_id
  order by i.requested_at desc;
end;
$$;

create or replace function public.request_platform_user_invitation(
  input_email text,
  input_full_name text default null,
  input_organization_id uuid default null,
  input_platform_role_id uuid default null,
  input_is_organization_admin boolean default false,
  input_job_title text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id uuid;
  normalized_email text := lower(trim(input_email));
begin
  perform public.require_platform_super_admin();

  if normalized_email is null
     or normalized_email = ''
     or normalized_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Informe um e-mail válido.';
  end if;

  insert into public.platform_user_invitations (
    email,
    full_name,
    organization_id,
    platform_role_id,
    is_organization_admin,
    job_title,
    status,
    requested_at,
    requested_by,
    failure_reason,
    updated_at
  ) values (
    normalized_email,
    nullif(trim(input_full_name), ''),
    input_organization_id,
    input_platform_role_id,
    input_is_organization_admin,
    nullif(trim(input_job_title), ''),
    'pending',
    timezone('utc', now()),
    auth.uid(),
    null,
    timezone('utc', now())
  )
  on conflict (lower(email)) where status in ('pending', 'sent')
  do update set
    full_name = excluded.full_name,
    organization_id = excluded.organization_id,
    platform_role_id = excluded.platform_role_id,
    is_organization_admin = excluded.is_organization_admin,
    job_title = excluded.job_title,
    status = 'pending',
    requested_at = timezone('utc', now()),
    requested_by = auth.uid(),
    sent_at = null,
    failure_reason = null,
    updated_at = timezone('utc', now())
  returning id into result_id;

  return result_id;
end;
$$;

create or replace function public.cancel_platform_user_invitation(
  target_invitation_id uuid,
  input_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  if trim(coalesce(input_reason, '')) = '' then
    raise exception 'Informe a justificativa do cancelamento.';
  end if;

  update public.platform_user_invitations
  set
    status = 'cancelled',
    cancelled_at = timezone('utc', now()),
    failure_reason = input_reason,
    updated_at = timezone('utc', now())
  where id = target_invitation_id
    and status in ('pending', 'sent');

  if not found then
    raise exception 'Convite não encontrado ou já encerrado.';
  end if;
end;
$$;

-- ------------------------------------------------------------
-- Políticas RLS e permissões de execução.
-- ------------------------------------------------------------

drop policy if exists platform_user_invitations_super_admin on public.platform_user_invitations;
create policy platform_user_invitations_super_admin
on public.platform_user_invitations
for all
to authenticated
using (public.is_platform_super_admin())
with check (public.is_platform_super_admin());

revoke all on public.platform_user_invitations from anon, authenticated;
grant select, insert, update on public.platform_user_invitations to authenticated;

revoke all on function public.require_platform_super_admin() from public;
revoke all on function public.get_platform_admin_summary() from public;
revoke all on function public.get_platform_admin_organization_levels() from public;
revoke all on function public.get_platform_admin_organizations() from public;
revoke all on function public.upsert_platform_admin_organization(uuid,text,text,text,text,text,text,uuid,text,text,text,text,text,text) from public;
revoke all on function public.set_platform_admin_organization_status(uuid,text,text) from public;
revoke all on function public.get_platform_admin_users() from public;
revoke all on function public.update_platform_admin_user_profile(uuid,text,text,text,boolean) from public;
revoke all on function public.get_platform_admin_memberships(uuid,uuid) from public;
revoke all on function public.upsert_platform_admin_membership(uuid,uuid,uuid,text,boolean,text,timestamptz,text) from public;
revoke all on function public.get_platform_admin_platform_roles() from public;
revoke all on function public.get_platform_admin_user_roles(uuid) from public;
revoke all on function public.set_platform_admin_user_role(uuid,uuid,boolean,text) from public;
revoke all on function public.get_platform_admin_modules() from public;
revoke all on function public.get_platform_admin_organization_modules(uuid) from public;
revoke all on function public.set_platform_admin_organization_module(uuid,uuid,boolean,text) from public;
revoke all on function public.get_platform_admin_invitations() from public;
revoke all on function public.request_platform_user_invitation(text,text,uuid,uuid,boolean,text) from public;
revoke all on function public.cancel_platform_user_invitation(uuid,text) from public;

grant execute on function public.require_platform_super_admin() to authenticated, service_role;
grant execute on function public.get_platform_admin_summary() to authenticated, service_role;
grant execute on function public.get_platform_admin_organization_levels() to authenticated, service_role;
grant execute on function public.get_platform_admin_organizations() to authenticated, service_role;
grant execute on function public.upsert_platform_admin_organization(uuid,text,text,text,text,text,text,uuid,text,text,text,text,text,text) to authenticated, service_role;
grant execute on function public.set_platform_admin_organization_status(uuid,text,text) to authenticated, service_role;
grant execute on function public.get_platform_admin_users() to authenticated, service_role;
grant execute on function public.update_platform_admin_user_profile(uuid,text,text,text,boolean) to authenticated, service_role;
grant execute on function public.get_platform_admin_memberships(uuid,uuid) to authenticated, service_role;
grant execute on function public.upsert_platform_admin_membership(uuid,uuid,uuid,text,boolean,text,timestamptz,text) to authenticated, service_role;
grant execute on function public.get_platform_admin_platform_roles() to authenticated, service_role;
grant execute on function public.get_platform_admin_user_roles(uuid) to authenticated, service_role;
grant execute on function public.set_platform_admin_user_role(uuid,uuid,boolean,text) to authenticated, service_role;
grant execute on function public.get_platform_admin_modules() to authenticated, service_role;
grant execute on function public.get_platform_admin_organization_modules(uuid) to authenticated, service_role;
grant execute on function public.set_platform_admin_organization_module(uuid,uuid,boolean,text) to authenticated, service_role;
grant execute on function public.get_platform_admin_invitations() to authenticated, service_role;
grant execute on function public.request_platform_user_invitation(text,text,uuid,uuid,boolean,text) to authenticated, service_role;
grant execute on function public.cancel_platform_user_invitation(uuid,text) to authenticated, service_role;

commit;
