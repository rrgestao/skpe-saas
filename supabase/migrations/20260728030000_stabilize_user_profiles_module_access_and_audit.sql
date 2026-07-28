-- ============================================================
-- Plataforma SPARKs
-- Bloco 1 - Estabilizacao de usuarios, perfis e acessos
--
-- Entregas:
-- 1. Consulta integral dos perfis modulares por usuario e organizacao.
-- 2. Atribuicao/substituicao/revogacao auditavel de papel modular.
-- 3. Consulta consolidada da auditoria relacionada ao usuario.
-- 4. Preservacao das regras do perfil VISITANTE somente leitura.
-- ============================================================

begin;

create or replace function public.get_platform_admin_user_module_roles(
  target_user_id uuid
)
returns table (
  organization_id uuid,
  organization_code text,
  organization_name text,
  membership_id uuid,
  membership_status text,
  organization_module_id uuid,
  module_id uuid,
  module_code text,
  module_name text,
  module_short_name text,
  module_role_id uuid,
  role_code text,
  role_name text,
  role_description text,
  role_level integer,
  assigned boolean,
  assignment_status text,
  user_module_role_id uuid,
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
    o.id,
    o.code,
    coalesce(o.trade_name, o.legal_name, o.code),
    membership.id,
    membership.status::text,
    om.id,
    m.id,
    m.code,
    m.name,
    m.short_name,
    mr.id,
    mr.code,
    mr.name,
    mr.description,
    mr.role_level,
    coalesce(current_assignment.status = 'active', false),
    current_assignment.status,
    current_assignment.id,
    current_assignment.valid_from,
    current_assignment.valid_until
  from public.organization_memberships membership
  join public.organizations o
    on o.id = membership.organization_id
  join public.organization_modules om
    on om.organization_id = o.id
   and om.enabled = true
   and om.status in ('trial', 'active')
   and om.valid_from <= timezone('utc', now())
   and (om.valid_until is null or om.valid_until >= timezone('utc', now()))
  join public.modules m
    on m.id = om.module_id
   and m.status in ('active', 'planned')
  join public.module_roles mr
    on mr.module_id = m.id
   and mr.active = true
  left join lateral (
    select
      umr.id,
      umr.status,
      umr.valid_from,
      umr.valid_until
    from public.user_module_roles umr
    where umr.organization_module_id = om.id
      and umr.user_id = target_user_id
      and umr.module_role_id = mr.id
    order by
      case when umr.status = 'active' then 0 else 1 end,
      coalesce(umr.assigned_at, umr.valid_from) desc nulls last
    limit 1
  ) current_assignment on true
  where membership.user_id = target_user_id
    and membership.status::text <> 'revoked'
  order by
    lower(coalesce(o.trade_name, o.legal_name, o.code)),
    lower(m.name),
    mr.role_level desc,
    lower(mr.name);
end;
$$;

create or replace function public.set_platform_admin_user_module_role(
  target_user_id uuid,
  target_organization_module_id uuid,
  target_module_role_id uuid default null,
  input_valid_until timestamptz default null,
  input_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_organization_id uuid;
  selected_module_id uuid;
  selected_module_code text;
  selected_role_code text;
  previous_roles jsonb;
begin
  perform public.require_platform_super_admin();

  if trim(coalesce(input_reason, '')) = '' then
    raise exception 'Informe a justificativa da alteracao do perfil modular.';
  end if;

  select
    om.organization_id,
    om.module_id,
    m.code
  into
    selected_organization_id,
    selected_module_id,
    selected_module_code
  from public.organization_modules om
  join public.modules m on m.id = om.module_id
  where om.id = target_organization_module_id
    and om.enabled = true
    and om.status in ('trial', 'active');

  if selected_organization_id is null then
    raise exception 'Modulo da organizacao nao encontrado ou desabilitado.';
  end if;

  if not exists (
    select 1
    from public.organization_memberships membership
    where membership.organization_id = selected_organization_id
      and membership.user_id = target_user_id
      and membership.status::text = 'active'
      and membership.valid_from <= timezone('utc', now())
      and (membership.valid_until is null or membership.valid_until >= timezone('utc', now()))
  ) then
    raise exception 'O usuario precisa possuir vinculo ativo com a organizacao.';
  end if;

  if exists (
    select 1
    from public.user_platform_roles upr
    join public.platform_roles pr on pr.id = upr.platform_role_id
    where upr.user_id = target_user_id
      and upr.status = 'active'
      and pr.code = 'visitor'
      and pr.active = true
  ) then
    raise exception 'O VISITANTE utiliza acesso dinamico somente leitura e nao pode receber papeis modulares.';
  end if;

  if target_module_role_id is not null then
    select mr.code
    into selected_role_code
    from public.module_roles mr
    where mr.id = target_module_role_id
      and mr.module_id = selected_module_id
      and mr.active = true;

    if selected_role_code is null then
      raise exception 'O perfil selecionado nao pertence ao modulo ou esta inativo.';
    end if;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'user_module_role_id', umr.id,
        'module_role_id', umr.module_role_id,
        'role_code', mr.code,
        'role_name', mr.name,
        'status', umr.status,
        'valid_until', umr.valid_until
      ) order by mr.role_level desc, mr.name
    ),
    '[]'::jsonb
  )
  into previous_roles
  from public.user_module_roles umr
  join public.module_roles mr on mr.id = umr.module_role_id
  where umr.organization_module_id = target_organization_module_id
    and umr.user_id = target_user_id;

  update public.user_module_roles
  set
    status = 'revoked',
    revoked_at = timezone('utc', now()),
    revoked_by = auth.uid(),
    valid_until = coalesce(valid_until, timezone('utc', now())),
    updated_at = timezone('utc', now())
  where organization_module_id = target_organization_module_id
    and user_id = target_user_id
    and status = 'active';

  if target_module_role_id is not null then
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
    ) values (
      target_organization_module_id,
      target_user_id,
      target_module_role_id,
      'active',
      timezone('utc', now()),
      input_valid_until,
      timezone('utc', now()),
      auth.uid(),
      null,
      null
    )
    on conflict (organization_module_id, user_id, module_role_id)
    do update set
      status = 'active',
      valid_from = timezone('utc', now()),
      valid_until = excluded.valid_until,
      assigned_at = timezone('utc', now()),
      assigned_by = auth.uid(),
      revoked_at = null,
      revoked_by = null,
      updated_at = timezone('utc', now());
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
  ) values (
    selected_organization_id,
    auth.uid(),
    target_user_id,
    selected_module_id,
    case when target_module_role_id is null then 'module_role_revoked' else 'module_role_assigned' end,
    input_reason,
    previous_roles,
    jsonb_build_object(
      'organization_module_id', target_organization_module_id,
      'module_code', selected_module_code,
      'module_role_id', target_module_role_id,
      'role_code', selected_role_code,
      'valid_until', input_valid_until
    )
  );

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
  ) values (
    auth.uid(),
    selected_organization_id,
    'configuration_changed',
    input_reason,
    'public',
    'user_module_roles',
    target_user_id::text,
    previous_roles,
    jsonb_build_object(
      'organization_module_id', target_organization_module_id,
      'module_role_id', target_module_role_id,
      'role_code', selected_role_code
    ),
    jsonb_build_object(
      'source', 'platform_admin',
      'target_user_id', target_user_id,
      'module_code', selected_module_code
    )
  );
end;
$$;

create or replace function public.get_platform_admin_user_audit(
  target_user_id uuid,
  limit_count integer default 100
)
returns table (
  audit_source text,
  audit_id uuid,
  occurred_at timestamptz,
  actor_user_id uuid,
  actor_name text,
  actor_email text,
  organization_id uuid,
  organization_name text,
  event_type text,
  event_description text,
  entity_table text,
  entity_id text,
  details jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.require_platform_super_admin();

  return query
  select *
  from (
    select
      'global'::text as audit_source,
      audit.id as audit_id,
      audit.occurred_at,
      audit.actor_user_id,
      coalesce(actor.display_name, actor.full_name, actor.email, 'Sistema') as actor_name,
      actor.email as actor_email,
      audit.organization_id,
      coalesce(org.trade_name, org.legal_name, org.code) as organization_name,
      audit.event_type,
      audit.event_description,
      audit.entity_table,
      audit.entity_id,
      jsonb_build_object(
        'previous_data', audit.previous_data,
        'new_data', audit.new_data,
        'metadata', audit.metadata
      ) as details
    from public.privileged_access_audit audit
    left join public.profiles actor on actor.id = audit.actor_user_id
    left join public.organizations org on org.id = audit.organization_id
    where audit.entity_id = target_user_id::text
       or audit.metadata ->> 'target_user_id' = target_user_id::text
       or audit.metadata ->> 'user_id' = target_user_id::text

    union all

    select
      'organizacao'::text,
      access_audit.id,
      access_audit.occurred_at,
      access_audit.actor_user_id,
      coalesce(actor.display_name, actor.full_name, actor.email, 'Sistema'),
      actor.email,
      access_audit.organization_id,
      coalesce(org.trade_name, org.legal_name, org.code),
      access_audit.action_code,
      access_audit.reason,
      'organization_access_audit'::text,
      access_audit.target_user_id::text,
      jsonb_build_object(
        'module_id', access_audit.module_id,
        'previous_data', access_audit.previous_data,
        'new_data', access_audit.new_data
      )
    from public.organization_access_audit access_audit
    left join public.profiles actor on actor.id = access_audit.actor_user_id
    left join public.organizations org on org.id = access_audit.organization_id
    where access_audit.target_user_id = target_user_id
  ) consolidated
  order by consolidated.occurred_at desc
  limit least(greatest(coalesce(limit_count, 100), 1), 500);
end;
$$;

revoke all on function public.get_platform_admin_user_module_roles(uuid) from public;
revoke all on function public.set_platform_admin_user_module_role(uuid, uuid, uuid, timestamptz, text) from public;
revoke all on function public.get_platform_admin_user_audit(uuid, integer) from public;

grant execute on function public.get_platform_admin_user_module_roles(uuid) to authenticated, service_role;
grant execute on function public.set_platform_admin_user_module_role(uuid, uuid, uuid, timestamptz, text) to authenticated, service_role;
grant execute on function public.get_platform_admin_user_audit(uuid, integer) to authenticated, service_role;

commit;

select
  to_regprocedure('public.get_platform_admin_user_module_roles(uuid)') is not null as consulta_perfis_modulares,
  to_regprocedure('public.set_platform_admin_user_module_role(uuid,uuid,uuid,timestamp with time zone,text)') is not null as manutencao_perfis_modulares,
  to_regprocedure('public.get_platform_admin_user_audit(uuid,integer)') is not null as consulta_auditoria_usuario;
