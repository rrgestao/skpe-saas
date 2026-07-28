-- ============================================================
-- Plataforma SPARKs
-- ETAPA B - Correcao de organizacoes, modulos e painel de rede.
-- Execute somente depois da ETAPA A concluir com sucesso.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- Niveis organizacionais exibidos na Administracao Global.
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
      when 'federation_central' then 'Central ou federacao'
      when 'confederation' then 'Confederacao'
      when 'system_guardian' then 'Organizacao guardia do sistema'
      when 'national' then 'Nacional'
      when 'regional' then 'Regional'
      when 'state' then 'Estadual'
      when 'matrix' then 'Matriz'
      when 'branch' then 'Filial'
      when 'unit' then 'Unidade'
      else initcap(replace(enum_value::text, '_', ' '))
    end
  from unnest(enum_range(null::public.organization_level)) enum_value
  order by 2;
end;
$$;

-- ------------------------------------------------------------
-- Validacao tipo x nivel.
-- ------------------------------------------------------------
create or replace function public.validate_organization_type_and_level()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if lower(coalesce(new.organization_type, '')) = 'system'
     and new.organization_level::text not in ('national', 'regional', 'state') then
    raise exception using
      errcode = '23514',
      message = 'Organizacoes do tipo Sistema devem utilizar o nivel Nacional, Regional ou Estadual.';
  end if;

  if lower(coalesce(new.organization_type, '')) = 'cooperative'
     and new.organization_level::text not in ('singular', 'federation_central', 'confederation') then
    raise exception using
      errcode = '23514',
      message = 'Organizacoes do tipo Cooperativa devem utilizar o nivel Singular, Central/Federacao ou Confederacao.';
  end if;

  if lower(coalesce(new.organization_type, '')) = 'company'
     and new.organization_level::text not in ('matrix', 'branch', 'unit') then
    raise exception using
      errcode = '23514',
      message = 'Organizacoes do tipo Empresa devem utilizar o nivel Matriz, Filial ou Unidade.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_organization_type_and_level on public.organizations;
create trigger trg_validate_organization_type_and_level
before insert or update of organization_type, organization_level
on public.organizations
for each row
execute function public.validate_organization_type_and_level();

-- ------------------------------------------------------------
-- Manutencao global de organizacoes.
-- ------------------------------------------------------------
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
  normalized_level text := lower(trim(input_organization_level));
  normalized_type text := lower(trim(coalesce(input_organization_type, 'other')));
begin
  perform public.require_platform_super_admin();

  if normalized_code is null or normalized_code = '' then
    raise exception 'Informe o codigo da organizacao.';
  end if;

  if normalized_legal_name is null or normalized_legal_name = '' then
    raise exception 'Informe a razao social da organizacao.';
  end if;

  if not exists (
    select 1
    from pg_type t
    join pg_enum e on e.enumtypid = t.oid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'organization_level'
      and e.enumlabel = normalized_level
  ) then
    raise exception 'Nivel organizacional invalido: %.', normalized_level;
  end if;

  if target_organization_id is not null
     and input_parent_organization_id = target_organization_id then
    raise exception 'A organizacao nao pode ser superior a si mesma.';
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
    ) values (
      normalized_code,
      normalized_legal_name,
      nullif(trim(input_trade_name), ''),
      normalized_level::public.organization_level,
      nullif(normalized_type, ''),
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
    ) returning id into result_id;
  else
    update public.organizations
    set
      code = normalized_code,
      legal_name = normalized_legal_name,
      trade_name = nullif(trim(input_trade_name), ''),
      organization_level = normalized_level::public.organization_level,
      organization_type = nullif(normalized_type, ''),
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
      raise exception 'Organizacao nao encontrada.';
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
      then 'Organizacao criada pela Administracao da Plataforma.'
      else 'Organizacao atualizada pela Administracao da Plataforma.'
    end,
    'public',
    'organizations',
    result_id::text,
    jsonb_build_object(
      'code', normalized_code,
      'legal_name', normalized_legal_name,
      'organization_level', normalized_level,
      'organization_type', normalized_type,
      'status', input_status,
      'description', nullif(trim(input_description), '')
    ),
    jsonb_build_object('source', 'platform_admin')
  );

  return result_id;
end;
$$;

-- ------------------------------------------------------------
-- Listagem e detalhe completos.
-- ------------------------------------------------------------
drop function if exists public.get_platform_admin_organizations();
create function public.get_platform_admin_organizations()
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
  description text,
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
    o.description,
    (select count(*) from public.organization_memberships om where om.organization_id = o.id and om.status::text <> 'revoked'),
    (select count(*) from public.organization_modules orm where orm.organization_id = o.id and orm.enabled = true and orm.status in ('trial','active')),
    o.created_at,
    o.updated_at
  from public.organizations o
  left join public.organizations parent on parent.id = o.parent_organization_id
  order by lower(coalesce(o.trade_name, o.legal_name, o.code));
end;
$$;

create or replace function public.get_platform_admin_organization_detail(
  target_organization_id uuid
)
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
  description text,
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
    o.description,
    (select count(*) from public.organization_memberships om where om.organization_id = o.id and om.status::text <> 'revoked'),
    (select count(*) from public.organization_modules orm where orm.organization_id = o.id and orm.enabled = true and orm.status in ('trial','active')),
    o.created_at,
    o.updated_at
  from public.organizations o
  left join public.organizations parent on parent.id = o.parent_organization_id
  where o.id = target_organization_id;
end;
$$;

-- ------------------------------------------------------------
-- O SUPER-ADMIN visualiza todos os cadastros globais ativos.
-- ------------------------------------------------------------
create or replace function public.get_my_organizations()
returns table (
  organization_id uuid,
  organization_code text,
  legal_name text,
  trade_name text,
  organization_level public.organization_level,
  membership_status public.membership_status,
  is_organization_admin boolean
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
      o.id,
      o.code,
      o.legal_name,
      o.trade_name,
      o.organization_level,
      'active'::public.membership_status,
      true
    from public.organizations o
    where o.status = 'active'
    order by lower(coalesce(o.trade_name, o.legal_name, o.code));
    return;
  end if;

  return query
  select
    o.id,
    o.code,
    o.legal_name,
    o.trade_name,
    o.organization_level,
    om.status,
    om.is_organization_admin
  from public.organization_memberships om
  join public.organizations o on o.id = om.organization_id
  where om.user_id = auth.uid()
    and om.status = 'active'
    and o.status = 'active'
    and om.valid_from <= timezone('utc', now())
    and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
  order by lower(coalesce(o.trade_name, o.legal_name, o.code));
end;
$$;

-- ------------------------------------------------------------
-- Modulos: SUPER-ADMIN nao depende de papel modular local.
-- ------------------------------------------------------------
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
    order by m.name;
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
  order by m.name;
end;
$$;

-- ------------------------------------------------------------
-- Painel consolidado da organizacao e de sua rede descendente.
-- ------------------------------------------------------------
create or replace function public.get_organization_network_dashboard(
  target_organization_id uuid,
  target_module_code text default 'SK-PE'
)
returns table (
  organization_id uuid,
  organization_code text,
  organization_name text,
  organization_level text,
  hierarchy_depth integer,
  module_enabled boolean,
  active_projects bigint,
  average_project_progress numeric,
  initiatives_total bigint,
  initiatives_attention bigint,
  active_memberships bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  with recursive child_edges as (
    select o.parent_organization_id as parent_id, o.id as child_id
    from public.organizations o
    where o.parent_organization_id is not null

    union

    select r.parent_organization_id, r.child_organization_id
    from public.organization_relationships r
    join public.organization_relationship_types rt on rt.id = r.relationship_type_id
    where rt.is_hierarchical = true
      and r.status = 'active'
      and r.valid_from <= current_date
      and (r.valid_until is null or r.valid_until >= current_date)
  ), network as (
    select
      target_organization_id as organization_id,
      0 as hierarchy_depth,
      array[target_organization_id]::uuid[] as path

    union all

    select
      e.child_id,
      n.hierarchy_depth + 1,
      n.path || e.child_id
    from network n
    join child_edges e on e.parent_id = n.organization_id
    where n.hierarchy_depth < 20
      and not (e.child_id = any(n.path))
  ), visible_network as (
    select distinct on (n.organization_id)
      n.organization_id,
      n.hierarchy_depth
    from network n
    where n.organization_id = target_organization_id
       or public.is_platform_super_admin()
       or public.can_access_descendant_organization(
            n.organization_id,
            target_module_code,
            'consolidated'
          )
    order by n.organization_id, n.hierarchy_depth
  )
  select
    o.id,
    o.code,
    coalesce(o.trade_name, o.legal_name, o.code),
    o.organization_level::text,
    vn.hierarchy_depth,
    exists (
      select 1
      from public.organization_modules om
      join public.modules m on m.id = om.module_id
      where om.organization_id = o.id
        and upper(m.code) = upper(target_module_code)
        and m.status = 'active'
        and om.enabled = true
        and om.status in ('trial','active')
    ),
    coalesce(projects.active_projects, 0),
    coalesce(projects.average_progress, 0),
    coalesce(initiatives.initiatives_total, 0),
    coalesce(initiatives.initiatives_attention, 0),
    coalesce(memberships.active_memberships, 0)
  from visible_network vn
  join public.organizations o on o.id = vn.organization_id
  left join lateral (
    select
      count(*) filter (where p.status in ('draft','active','suspended')) as active_projects,
      round(coalesce(avg(p.progress) filter (where p.status <> 'archived'), 0)::numeric, 2) as average_progress
    from public.skpe_projects p
    where p.organization_id = o.id
      and p.archived_at is null
  ) projects on true
  left join lateral (
    select
      count(*) filter (where i.status <> 'archived') as initiatives_total,
      count(*) filter (
        where i.status = 'blocked'
           or i.health_status in ('attention','critical')
           or i.risk_level in ('high','critical')
      ) as initiatives_attention
    from public.skpe_initiatives i
    where i.organization_id = o.id
      and i.archived_at is null
  ) initiatives on true
  left join lateral (
    select count(*) as active_memberships
    from public.organization_memberships om
    where om.organization_id = o.id
      and om.status = 'active'
      and om.valid_from <= timezone('utc', now())
      and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
  ) memberships on true
  where o.status = 'active'
  order by vn.hierarchy_depth, lower(coalesce(o.trade_name, o.legal_name, o.code));
$$;

revoke all on function public.get_platform_admin_organization_levels() from public;
revoke all on function public.upsert_platform_admin_organization(uuid,text,text,text,text,text,text,uuid,text,text,text,text,text,text) from public;
revoke all on function public.get_platform_admin_organizations() from public;
revoke all on function public.get_platform_admin_organization_detail(uuid) from public;
revoke all on function public.get_my_organizations() from public;
revoke all on function public.get_my_modules(uuid) from public;
revoke all on function public.get_organization_network_dashboard(uuid,text) from public;

grant execute on function public.get_platform_admin_organization_levels() to authenticated, service_role;
grant execute on function public.upsert_platform_admin_organization(uuid,text,text,text,text,text,text,uuid,text,text,text,text,text,text) to authenticated, service_role;
grant execute on function public.get_platform_admin_organizations() to authenticated, service_role;
grant execute on function public.get_platform_admin_organization_detail(uuid) to authenticated, service_role;
grant execute on function public.get_my_organizations() to authenticated, service_role;
grant execute on function public.get_my_modules(uuid) to authenticated, service_role;
grant execute on function public.get_organization_network_dashboard(uuid,text) to authenticated, service_role;

commit;

-- Verificacao final.
select
  (select count(*) from public.get_platform_admin_organization_levels()) as niveis_disponiveis,
  (select count(*) from public.get_platform_admin_organizations()) as organizacoes_cadastradas;
