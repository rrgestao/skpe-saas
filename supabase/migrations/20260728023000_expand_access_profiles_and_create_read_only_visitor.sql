-- ============================================================
-- Plataforma SPARKs
-- Expansao dos perfis de acesso e criacao do perfil VISITANTE.
--
-- Objetivos:
-- 1. Garantir que a Administracao Global carregue todos os perfis ativos,
--    sem limite fixo de quantidade.
-- 2. Criar o perfil global VISITANTE.
-- 3. Criar o papel VISITANTE em todos os modulos cadastrados.
-- 4. Conceder ao VISITANTE somente permissoes de leitura.
-- 5. Impedir que um VISITANTE acumule perfis de escrita, administracao
--    ou administracao local.
-- 6. Disponibilizar os papeis de todos os modulos habilitados da
--    organizacao no cadastro direto de usuarios.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- Perfil global VISITANTE.
-- O perfil nao concede acesso a organizacoes por si so.
-- O usuario precisa possuir vinculo ativo com a organizacao.
-- ------------------------------------------------------------
insert into public.platform_roles (
  code,
  name,
  description,
  role_level,
  active,
  is_system_role
) values (
  'visitor',
  'VISITANTE',
  'Acesso somente leitura a todas as funcionalidades autorizadas das organizacoes em que o usuario possua vinculo ativo. Nao permite criar, editar, excluir, aprovar, configurar ou administrar.',
  5,
  true,
  true
)
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description,
  role_level = excluded.role_level,
  active = excluded.active,
  is_system_role = excluded.is_system_role,
  updated_at = timezone('utc', now());

-- ------------------------------------------------------------
-- Papel VISITANTE em cada modulo cadastrado.
-- ------------------------------------------------------------
insert into public.module_roles (
  module_id,
  code,
  name,
  description,
  role_level,
  is_system_role,
  active
)
select
  m.id,
  'visitor',
  'Visitante',
  'Consulta o modulo em modo somente leitura, sem permissoes de inclusao, alteracao, exclusao, aprovacao, exportacao administrativa ou configuracao.',
  5,
  true,
  true
from public.modules m
on conflict (module_id, code) do update
set
  name = excluded.name,
  description = excluded.description,
  role_level = excluded.role_level,
  is_system_role = excluded.is_system_role,
  active = excluded.active,
  updated_at = timezone('utc', now());

-- ------------------------------------------------------------
-- Permissoes de leitura para o papel VISITANTE.
-- Nao concede exportacao, aprovacao, administracao ou escrita.
-- ------------------------------------------------------------
insert into public.role_permissions (
  module_role_id,
  module_permission_id
)
select
  mr.id,
  mp.id
from public.module_roles mr
join public.module_permissions mp
  on mp.module_id = mr.module_id
where mr.code = 'visitor'
  and mr.active = true
  and mp.active = true
  and lower(mp.code) ~ '(^|\.)(view|read|list|search|preview|print)$'
on conflict do nothing;

-- Remove qualquer permissao nao estritamente de leitura que tenha sido
-- eventualmente associada ao VISITANTE em execucao anterior.
delete from public.role_permissions rp
using public.module_roles mr, public.module_permissions mp
where rp.module_role_id = mr.id
  and rp.module_permission_id = mp.id
  and mr.code = 'visitor'
  and not (lower(mp.code) ~ '(^|\.)(view|read|list|search|preview|print)$');

-- ------------------------------------------------------------
-- Identificacao do VISITANTE.
-- ------------------------------------------------------------
create or replace function public.is_platform_visitor()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.has_platform_role('visitor');
$$;

-- ------------------------------------------------------------
-- Acesso aos modulos.
-- SUPER-ADMIN: acesso total aos modulos habilitados.
-- VISITANTE: acesso de leitura aos modulos habilitados das organizacoes
--            em que possui vinculo ativo.
-- Demais usuarios: acesso por papel modular atribuido.
-- ------------------------------------------------------------
create or replace function public.has_module_access(
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
    public.is_platform_super_admin()
    or exists (
      select 1
      from public.organization_modules om
      join public.modules m on m.id = om.module_id
      join public.user_module_roles umr on umr.organization_module_id = om.id
      join public.module_roles mr on mr.id = umr.module_role_id
      where om.organization_id = target_organization_id
        and m.code = upper(trim(target_module_code))
        and m.status = 'active'
        and om.enabled = true
        and om.status in ('trial', 'active')
        and om.valid_from <= timezone('utc', now())
        and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
        and umr.user_id = auth.uid()
        and umr.status = 'active'
        and umr.valid_from <= timezone('utc', now())
        and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
        and mr.active = true
        and public.is_active_member(om.organization_id)
    )
    or (
      public.is_platform_visitor()
      and public.is_active_member(target_organization_id)
      and exists (
        select 1
        from public.organization_modules om
        join public.modules m on m.id = om.module_id
        where om.organization_id = target_organization_id
          and m.code = upper(trim(target_module_code))
          and m.status = 'active'
          and om.enabled = true
          and om.status in ('trial', 'active')
          and om.valid_from <= timezone('utc', now())
          and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
      )
    );
$$;

create or replace function public.has_module_permission(
  target_organization_id uuid,
  target_module_code text,
  target_permission_code text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_platform_super_admin()
    or exists (
      select 1
      from public.organization_modules om
      join public.modules m on m.id = om.module_id
      join public.user_module_roles umr on umr.organization_module_id = om.id
      join public.module_roles mr on mr.id = umr.module_role_id
      join public.role_permissions rp on rp.module_role_id = mr.id
      join public.module_permissions mp on mp.id = rp.module_permission_id
      where om.organization_id = target_organization_id
        and m.code = upper(trim(target_module_code))
        and mp.code = lower(trim(target_permission_code))
        and m.status = 'active'
        and mp.active = true
        and mr.active = true
        and om.enabled = true
        and om.status in ('trial', 'active')
        and om.valid_from <= timezone('utc', now())
        and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
        and umr.user_id = auth.uid()
        and umr.status = 'active'
        and umr.valid_from <= timezone('utc', now())
        and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
        and public.is_active_member(om.organization_id)
    )
    or (
      public.is_platform_visitor()
      and public.is_active_member(target_organization_id)
      and lower(trim(target_permission_code)) ~ '(^|\.)(view|read|list|search|preview|print)$'
      and exists (
        select 1
        from public.organization_modules om
        join public.modules m on m.id = om.module_id
        join public.module_permissions mp on mp.module_id = m.id
        where om.organization_id = target_organization_id
          and m.code = upper(trim(target_module_code))
          and mp.code = lower(trim(target_permission_code))
          and m.status = 'active'
          and mp.active = true
          and om.enabled = true
          and om.status in ('trial', 'active')
          and om.valid_from <= timezone('utc', now())
          and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
      )
    );
$$;

create or replace function public.get_my_modules(target_organization_id uuid)
returns table (
  organization_module_id uuid,
  module_id uuid,
  module_code text,
  module_name text,
  module_short_name text,
  module_description text,
  module_route_path text,
  module_icon_name text,
  role_code text,
  role_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if public.is_platform_super_admin() then
    return query
    select
      om.id,
      m.id,
      m.code,
      m.name,
      m.short_name,
      m.description,
      m.route_path,
      m.icon_name,
      'super_admin'::text,
      'SUPER-ADMIN da Plataforma'::text
    from public.organization_modules om
    join public.modules m on m.id = om.module_id
    where om.organization_id = target_organization_id
      and m.status = 'active'
      and om.enabled = true
      and om.status in ('trial', 'active')
      and om.valid_from <= timezone('utc', now())
      and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
    order by lower(m.name);
    return;
  end if;

  if public.is_platform_visitor() and public.is_active_member(target_organization_id) then
    return query
    select
      om.id,
      m.id,
      m.code,
      m.name,
      m.short_name,
      m.description,
      m.route_path,
      m.icon_name,
      'visitor'::text,
      'Visitante'::text
    from public.organization_modules om
    join public.modules m on m.id = om.module_id
    where om.organization_id = target_organization_id
      and m.status = 'active'
      and om.enabled = true
      and om.status in ('trial', 'active')
      and om.valid_from <= timezone('utc', now())
      and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
    order by lower(m.name);
    return;
  end if;

  return query
  select distinct
    om.id,
    m.id,
    m.code,
    m.name,
    m.short_name,
    m.description,
    m.route_path,
    m.icon_name,
    mr.code,
    mr.name
  from public.organization_modules om
  join public.modules m on m.id = om.module_id
  join public.user_module_roles umr on umr.organization_module_id = om.id
  join public.module_roles mr on mr.id = umr.module_role_id
  where om.organization_id = target_organization_id
    and umr.user_id = auth.uid()
    and m.status = 'active'
    and om.enabled = true
    and om.status in ('trial', 'active')
    and om.valid_from <= timezone('utc', now())
    and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
    and umr.status = 'active'
    and umr.valid_from <= timezone('utc', now())
    and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
    and mr.active = true
    and public.is_active_member(om.organization_id)
  order by 4, 10;
end;
$$;

-- ------------------------------------------------------------
-- Todos os papeis modulares ativos da organizacao selecionada.
-- Utilizado no cadastro direto de usuarios.
-- ------------------------------------------------------------
create or replace function public.get_platform_admin_organization_module_roles(
  target_organization_id uuid
)
returns table (
  organization_module_id uuid,
  module_id uuid,
  module_code text,
  module_name text,
  module_short_name text,
  module_role_id uuid,
  role_code text,
  role_name text,
  role_description text,
  role_level integer
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
    m.id,
    m.code,
    m.name,
    m.short_name,
    mr.id,
    mr.code,
    mr.name,
    mr.description,
    mr.role_level
  from public.organization_modules om
  join public.modules m on m.id = om.module_id
  join public.module_roles mr on mr.module_id = m.id
  where om.organization_id = target_organization_id
    and om.enabled = true
    and om.status in ('trial', 'active')
    and om.valid_from <= timezone('utc', now())
    and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
    and m.status in ('active', 'planned')
    and mr.active = true
  order by lower(m.name), mr.role_level desc, lower(mr.name);
end;
$$;

-- ------------------------------------------------------------
-- Regras de incompatibilidade do VISITANTE.
-- ------------------------------------------------------------
create or replace function public.validate_platform_visitor_role_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_role_code text;
begin
  select pr.code
  into selected_role_code
  from public.platform_roles pr
  where pr.id = new.platform_role_id;

  if new.status <> 'active' then
    return new;
  end if;

  if selected_role_code = 'visitor' then
    if exists (
      select 1
      from public.user_platform_roles upr
      join public.platform_roles pr on pr.id = upr.platform_role_id
      where upr.user_id = new.user_id
        and upr.id is distinct from new.id
        and upr.status = 'active'
        and pr.code <> 'visitor'
    ) then
      raise exception 'O perfil VISITANTE deve ser exclusivo e nao pode ser acumulado com outro perfil global ativo.';
    end if;

    if exists (
      select 1
      from public.user_module_roles umr
      where umr.user_id = new.user_id
        and umr.status = 'active'
    ) then
      raise exception 'Remova os papeis modulares ativos antes de atribuir o perfil VISITANTE.';
    end if;

    if exists (
      select 1
      from public.organization_memberships om
      where om.user_id = new.user_id
        and om.status = 'active'
        and om.is_organization_admin = true
    ) then
      raise exception 'Um VISITANTE nao pode ser administrador de organizacao.';
    end if;
  elsif exists (
    select 1
    from public.user_platform_roles upr
    join public.platform_roles pr on pr.id = upr.platform_role_id
    where upr.user_id = new.user_id
      and upr.status = 'active'
      and pr.code = 'visitor'
      and upr.id is distinct from new.id
  ) then
    raise exception 'Revogue o perfil VISITANTE antes de atribuir outro perfil global.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_platform_visitor_role_assignment on public.user_platform_roles;
create trigger trg_validate_platform_visitor_role_assignment
before insert or update of platform_role_id, status
on public.user_platform_roles
for each row
execute function public.validate_platform_visitor_role_assignment();

create or replace function public.block_module_roles_for_platform_visitor()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'active' and exists (
    select 1
    from public.user_platform_roles upr
    join public.platform_roles pr on pr.id = upr.platform_role_id
    where upr.user_id = new.user_id
      and upr.status = 'active'
      and pr.code = 'visitor'
  ) then
    raise exception 'O perfil VISITANTE utiliza acesso dinamico somente leitura e nao pode receber papeis modulares adicionais.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_block_module_roles_for_platform_visitor on public.user_module_roles;
create trigger trg_block_module_roles_for_platform_visitor
before insert or update of module_role_id, status
on public.user_module_roles
for each row
execute function public.block_module_roles_for_platform_visitor();

create or replace function public.block_organization_admin_for_platform_visitor()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.is_organization_admin = true and exists (
    select 1
    from public.user_platform_roles upr
    join public.platform_roles pr on pr.id = upr.platform_role_id
    where upr.user_id = new.user_id
      and upr.status = 'active'
      and pr.code = 'visitor'
  ) then
    raise exception 'Um VISITANTE nao pode ser administrador de organizacao.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_block_organization_admin_for_platform_visitor on public.organization_memberships;
create trigger trg_block_organization_admin_for_platform_visitor
before insert or update of is_organization_admin, status
on public.organization_memberships
for each row
execute function public.block_organization_admin_for_platform_visitor();

-- ------------------------------------------------------------
-- Permissoes das funcoes.
-- ------------------------------------------------------------
revoke all on function public.is_platform_visitor() from public;
revoke all on function public.get_platform_admin_organization_module_roles(uuid) from public;

grant execute on function public.is_platform_visitor() to authenticated, service_role;
grant execute on function public.get_platform_admin_organization_module_roles(uuid) to authenticated, service_role;

commit;

-- ------------------------------------------------------------
-- Verificacao final.
-- ------------------------------------------------------------
select
  (select count(*) from public.platform_roles where active = true) as perfis_globais_ativos,
  (select count(*) from public.platform_roles where code = 'visitor' and active = true) as perfil_visitante_global,
  (select count(*) from public.module_roles where code = 'visitor' and active = true) as papeis_visitante_modulares,
  (
    select count(*)
    from public.role_permissions rp
    join public.module_roles mr on mr.id = rp.module_role_id
    join public.module_permissions mp on mp.id = rp.module_permission_id
    where mr.code = 'visitor'
      and lower(mp.code) ~ '(^|\.)(view|read|list|search|preview|print)$'
  ) as permissoes_somente_leitura;
