-- ============================================================
-- SK-PE SaaS
-- Migration: Gestao de Usuarios, Vinculos e Acessos por Organizacao
-- ============================================================

-- ============================================================
-- AUDITORIA DE ALTERACOES DE ACESSO
-- ============================================================

create table public.organization_access_audit (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id) on delete cascade,
  actor_user_id uuid not null
    references public.profiles(id) on delete restrict,
  target_user_id uuid
    references public.profiles(id) on delete set null,
  module_id uuid
    references public.modules(id) on delete set null,
  action_code text not null,
  reason text,
  previous_data jsonb,
  new_data jsonb,
  occurred_at timestamptz not null default timezone('utc', now()),

  constraint organization_access_audit_action_not_blank
    check (length(trim(action_code)) > 0)
);

comment on table public.organization_access_audit is
  'Trilha de auditoria das alteracoes de vinculos, administracao e acessos modulares de uma organizacao.';

create index idx_organization_access_audit_organization
  on public.organization_access_audit(organization_id);

create index idx_organization_access_audit_target_user
  on public.organization_access_audit(target_user_id);

create index idx_organization_access_audit_occurred_at
  on public.organization_access_audit(occurred_at desc);

alter table public.organization_access_audit enable row level security;

-- ============================================================
-- AUTORIZACAO PARA GESTAO DE USUARIOS DO MODULO
-- ============================================================

create or replace function public.can_manage_module_users(
  target_organization_id uuid,
  target_module_code text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_organization_admin(target_organization_id)
    or public.has_module_permission(
      target_organization_id,
      target_module_code,
      'users.manage'
    );
$$;

comment on function public.can_manage_module_users(uuid, text) is
  'Autoriza a gestao de usuarios quando o solicitante administra a organizacao ou possui users.manage no modulo.';

-- ============================================================
-- CONSULTA DOS PAPEIS DISPONIVEIS
-- ============================================================

create or replace function public.get_module_roles_for_organization(
  target_organization_id uuid,
  target_module_code text
)
returns table (
  module_role_id uuid,
  role_code text,
  role_name text,
  role_description text,
  role_level integer,
  active boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.can_manage_module_users(
    target_organization_id,
    target_module_code
  ) then
    raise exception
      'Acesso negado: o usuario nao pode administrar os acessos deste modulo.'
      using errcode = '42501';
  end if;

  return query
  select
    mr.id,
    mr.code,
    mr.name,
    mr.description,
    mr.role_level,
    mr.active
  from public.organization_modules om
  join public.modules m
    on m.id = om.module_id
  join public.module_roles mr
    on mr.module_id = m.id
  where om.organization_id = target_organization_id
    and m.code = upper(trim(target_module_code))
    and om.enabled = true
    and om.status in ('trial', 'active')
    and mr.active = true
  order by mr.role_level desc, mr.name;
end;
$$;

-- ============================================================
-- DEFINIR OU REMOVER ADMINISTRADOR DA ORGANIZACAO
-- ============================================================

create or replace function public.set_organization_member_admin(
  target_organization_id uuid,
  target_user_id uuid,
  target_is_admin boolean,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_admin boolean;
  active_admin_count integer;
begin
  if not public.is_organization_admin(target_organization_id) then
    raise exception
      'Acesso negado: somente administradores da organizacao podem alterar esta configuracao.'
      using errcode = '42501';
  end if;

  select membership.is_organization_admin
    into previous_admin
  from public.organization_memberships membership
  where membership.organization_id = target_organization_id
    and membership.user_id = target_user_id
  for update;

  if not found then
    raise exception 'O usuario nao possui vinculo com a organizacao.';
  end if;

  if previous_admin = true and target_is_admin = false then
    select count(*)
      into active_admin_count
    from public.organization_memberships membership
    where membership.organization_id = target_organization_id
      and membership.user_id <> target_user_id
      and membership.is_organization_admin = true
      and membership.status = 'active'
      and membership.valid_from <= timezone('utc', now())
      and (
        membership.valid_until is null
        or membership.valid_until >= timezone('utc', now())
      );

    if active_admin_count = 0 then
      raise exception
        'Nao e permitido remover o ultimo administrador ativo da organizacao.';
    end if;
  end if;

  update public.organization_memberships
  set
    is_organization_admin = target_is_admin,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where organization_id = target_organization_id
    and user_id = target_user_id;

  insert into public.organization_access_audit (
    organization_id,
    actor_user_id,
    target_user_id,
    action_code,
    reason,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    auth.uid(),
    target_user_id,
    'organization_admin_changed',
    nullif(trim(change_reason), ''),
    jsonb_build_object('is_organization_admin', previous_admin),
    jsonb_build_object('is_organization_admin', target_is_admin)
  );
end;
$$;

-- ============================================================
-- ALTERAR SITUACAO DO VINCULO ORGANIZACIONAL
-- ============================================================

create or replace function public.set_organization_member_status(
  target_organization_id uuid,
  target_user_id uuid,
  target_status text,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_status public.membership_status;
  target_is_admin boolean;
  active_admin_count integer;
  normalized_status text;
begin
  if not public.is_organization_admin(target_organization_id) then
    raise exception
      'Acesso negado: somente administradores da organizacao podem alterar o vinculo.'
      using errcode = '42501';
  end if;

  normalized_status := lower(trim(target_status));

  if normalized_status not in ('active', 'suspended', 'revoked') then
    raise exception 'Situacao de vinculo invalida: %.', target_status;
  end if;

  select
    membership.status,
    membership.is_organization_admin
  into
    previous_status,
    target_is_admin
  from public.organization_memberships membership
  where membership.organization_id = target_organization_id
    and membership.user_id = target_user_id
  for update;

  if not found then
    raise exception 'O usuario nao possui vinculo com a organizacao.';
  end if;

  if target_is_admin = true
     and normalized_status in ('suspended', 'revoked') then
    select count(*)
      into active_admin_count
    from public.organization_memberships membership
    where membership.organization_id = target_organization_id
      and membership.user_id <> target_user_id
      and membership.is_organization_admin = true
      and membership.status = 'active'
      and membership.valid_from <= timezone('utc', now())
      and (
        membership.valid_until is null
        or membership.valid_until >= timezone('utc', now())
      );

    if active_admin_count = 0 then
      raise exception
        'Nao e permitido suspender ou revogar o ultimo administrador ativo da organizacao.';
    end if;
  end if;

  update public.organization_memberships
  set
    status = normalized_status::public.membership_status,
    activated_at = case
      when normalized_status = 'active'
        then coalesce(activated_at, timezone('utc', now()))
      else activated_at
    end,
    suspended_at = case
      when normalized_status = 'suspended'
        then timezone('utc', now())
      else null
    end,
    revoked_at = case
      when normalized_status = 'revoked'
        then timezone('utc', now())
      else null
    end,
    updated_at = timezone('utc', now()),
    updated_by = auth.uid()
  where organization_id = target_organization_id
    and user_id = target_user_id;

  if normalized_status in ('suspended', 'revoked') then
    update public.user_module_roles umr
    set
      status = normalized_status,
      revoked_at = case
        when normalized_status = 'revoked'
          then timezone('utc', now())
        else umr.revoked_at
      end,
      revoked_by = case
        when normalized_status = 'revoked'
          then auth.uid()
        else umr.revoked_by
      end,
      updated_at = timezone('utc', now())
    from public.organization_modules om
    where umr.organization_module_id = om.id
      and om.organization_id = target_organization_id
      and umr.user_id = target_user_id;
  end if;

  insert into public.organization_access_audit (
    organization_id,
    actor_user_id,
    target_user_id,
    action_code,
    reason,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    auth.uid(),
    target_user_id,
    'membership_status_changed',
    nullif(trim(change_reason), ''),
    jsonb_build_object('status', previous_status::text),
    jsonb_build_object('status', normalized_status)
  );
end;
$$;

-- ============================================================
-- ATRIBUIR OU ALTERAR PAPEL NO MODULO
-- ============================================================

create or replace function public.set_user_module_role(
  target_organization_id uuid,
  target_user_id uuid,
  target_module_code text,
  target_role_code text,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_organization_module_id uuid;
  selected_module_id uuid;
  selected_module_role_id uuid;
  membership_is_active boolean;
  previous_roles jsonb;
begin
  if not public.can_manage_module_users(
    target_organization_id,
    target_module_code
  ) then
    raise exception
      'Acesso negado: o usuario nao pode administrar os acessos deste modulo.'
      using errcode = '42501';
  end if;

  select exists (
    select 1
    from public.organization_memberships membership
    where membership.organization_id = target_organization_id
      and membership.user_id = target_user_id
      and membership.status = 'active'
      and membership.valid_from <= timezone('utc', now())
      and (
        membership.valid_until is null
        or membership.valid_until >= timezone('utc', now())
      )
  ) into membership_is_active;

  if not membership_is_active then
    raise exception
      'O usuario precisa possuir vinculo organizacional ativo antes de receber um papel de modulo.';
  end if;

  select
    om.id,
    m.id
  into
    selected_organization_module_id,
    selected_module_id
  from public.organization_modules om
  join public.modules m
    on m.id = om.module_id
  where om.organization_id = target_organization_id
    and m.code = upper(trim(target_module_code))
    and om.enabled = true
    and om.status in ('trial', 'active')
    and om.valid_from <= timezone('utc', now())
    and (
      om.valid_until is null
      or om.valid_until >= timezone('utc', now())
    );

  if selected_organization_module_id is null then
    raise exception 'O modulo nao esta ativo para a organizacao.';
  end if;

  select mr.id
    into selected_module_role_id
  from public.module_roles mr
  where mr.module_id = selected_module_id
    and mr.code = lower(trim(target_role_code))
    and mr.active = true;

  if selected_module_role_id is null then
    raise exception 'O papel informado nao pertence ao modulo ou esta inativo.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'user_module_role_id', umr.id,
        'module_role_id', umr.module_role_id,
        'role_code', mr.code,
        'status', umr.status
      )
      order by mr.role_level desc
    ),
    '[]'::jsonb
  )
  into previous_roles
  from public.user_module_roles umr
  join public.module_roles mr
    on mr.id = umr.module_role_id
  where umr.organization_module_id = selected_organization_module_id
    and umr.user_id = target_user_id;

  update public.user_module_roles
  set
    status = 'revoked',
    revoked_at = timezone('utc', now()),
    revoked_by = auth.uid(),
    updated_at = timezone('utc', now())
  where organization_module_id = selected_organization_module_id
    and user_id = target_user_id
    and module_role_id <> selected_module_role_id
    and status <> 'revoked';

  insert into public.user_module_roles (
    organization_module_id,
    user_id,
    module_role_id,
    status,
    valid_from,
    valid_until,
    assigned_at,
    assigned_by,
    revoked_at,
    revoked_by
  )
  values (
    selected_organization_module_id,
    target_user_id,
    selected_module_role_id,
    'active',
    timezone('utc', now()),
    null,
    timezone('utc', now()),
    auth.uid(),
    null,
    null
  )
  on conflict (
    organization_module_id,
    user_id,
    module_role_id
  ) do update
  set
    status = 'active',
    valid_from = timezone('utc', now()),
    valid_until = null,
    assigned_at = timezone('utc', now()),
    assigned_by = auth.uid(),
    revoked_at = null,
    revoked_by = null,
    updated_at = timezone('utc', now());

  insert into public.organization_access_audit (
    organization_id,
    actor_user_id,
    target_user_id,
    module_id,
    action_code,
    reason,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    auth.uid(),
    target_user_id,
    selected_module_id,
    'module_role_changed',
    nullif(trim(change_reason), ''),
    jsonb_build_object('roles', previous_roles),
    jsonb_build_object(
      'module_code', upper(trim(target_module_code)),
      'role_code', lower(trim(target_role_code)),
      'status', 'active'
    )
  );
end;
$$;

-- ============================================================
-- SUSPENDER, REATIVAR OU REVOGAR ACESSO AO MODULO
-- ============================================================

create or replace function public.set_user_module_access_status(
  target_organization_id uuid,
  target_user_id uuid,
  target_module_code text,
  target_status text,
  change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_organization_module_id uuid;
  selected_module_id uuid;
  normalized_status text;
  previous_roles jsonb;
  affected_rows integer;
begin
  if not public.can_manage_module_users(
    target_organization_id,
    target_module_code
  ) then
    raise exception
      'Acesso negado: o usuario nao pode administrar os acessos deste modulo.'
      using errcode = '42501';
  end if;

  normalized_status := lower(trim(target_status));

  if normalized_status not in ('active', 'suspended', 'revoked') then
    raise exception 'Situacao de acesso modular invalida: %.', target_status;
  end if;

  select
    om.id,
    m.id
  into
    selected_organization_module_id,
    selected_module_id
  from public.organization_modules om
  join public.modules m
    on m.id = om.module_id
  where om.organization_id = target_organization_id
    and m.code = upper(trim(target_module_code));

  if selected_organization_module_id is null then
    raise exception 'O modulo nao esta associado a organizacao.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'user_module_role_id', umr.id,
        'role_code', mr.code,
        'status', umr.status
      )
      order by mr.role_level desc
    ),
    '[]'::jsonb
  )
  into previous_roles
  from public.user_module_roles umr
  join public.module_roles mr
    on mr.id = umr.module_role_id
  where umr.organization_module_id = selected_organization_module_id
    and umr.user_id = target_user_id;

  update public.user_module_roles
  set
    status = normalized_status,
    valid_until = case
      when normalized_status = 'active' then null
      else valid_until
    end,
    revoked_at = case
      when normalized_status = 'revoked'
        then timezone('utc', now())
      when normalized_status = 'active'
        then null
      else revoked_at
    end,
    revoked_by = case
      when normalized_status = 'revoked'
        then auth.uid()
      when normalized_status = 'active'
        then null
      else revoked_by
    end,
    updated_at = timezone('utc', now())
  where organization_module_id = selected_organization_module_id
    and user_id = target_user_id;

  get diagnostics affected_rows = row_count;

  if affected_rows = 0 then
    raise exception
      'O usuario ainda nao possui papel atribuido neste modulo.';
  end if;

  insert into public.organization_access_audit (
    organization_id,
    actor_user_id,
    target_user_id,
    module_id,
    action_code,
    reason,
    previous_data,
    new_data
  )
  values (
    target_organization_id,
    auth.uid(),
    target_user_id,
    selected_module_id,
    'module_access_status_changed',
    nullif(trim(change_reason), ''),
    jsonb_build_object('roles', previous_roles),
    jsonb_build_object(
      'module_code', upper(trim(target_module_code)),
      'status', normalized_status
    )
  );
end;
$$;

-- ============================================================
-- POLITICA DE CONSULTA DA AUDITORIA
-- ============================================================

create policy organization_access_audit_select_authorized
on public.organization_access_audit
for select
to authenticated
using (
  public.is_organization_admin(organization_id)
  or (
    module_id is not null
    and exists (
      select 1
      from public.modules module
      where module.id = organization_access_audit.module_id
        and public.has_module_permission(
          organization_access_audit.organization_id,
          module.code,
          'users.view'
        )
    )
  )
);

-- ============================================================
-- PERMISSOES
-- ============================================================

revoke all on table public.organization_access_audit from anon;
revoke all on table public.organization_access_audit from authenticated;
grant select on table public.organization_access_audit to authenticated;
grant all on table public.organization_access_audit to service_role;

revoke all on function public.can_manage_module_users(uuid, text)
from public, anon;
revoke all on function public.get_module_roles_for_organization(uuid, text)
from public, anon;
revoke all on function public.set_organization_member_admin(uuid, uuid, boolean, text)
from public, anon;
revoke all on function public.set_organization_member_status(uuid, uuid, text, text)
from public, anon;
revoke all on function public.set_user_module_role(uuid, uuid, text, text, text)
from public, anon;
revoke all on function public.set_user_module_access_status(uuid, uuid, text, text, text)
from public, anon;

grant execute on function public.can_manage_module_users(uuid, text)
to authenticated, service_role;

grant execute on function public.get_module_roles_for_organization(uuid, text)
to authenticated, service_role;

grant execute on function public.set_organization_member_admin(uuid, uuid, boolean, text)
to authenticated, service_role;

grant execute on function public.set_organization_member_status(uuid, uuid, text, text)
to authenticated, service_role;

grant execute on function public.set_user_module_role(uuid, uuid, text, text, text)
to authenticated, service_role;

grant execute on function public.set_user_module_access_status(uuid, uuid, text, text, text)
to authenticated, service_role;
