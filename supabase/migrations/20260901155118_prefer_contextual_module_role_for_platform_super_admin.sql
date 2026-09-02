create or replace function public.get_my_modules(target_organization_id uuid)
returns table(
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
set search_path to ''
as $function$
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
      coalesce(context_role.code, 'super_admin'::text),
      coalesce(context_role.name, 'SUPER-ADMIN da Plataforma'::text)
    from public.organization_modules om
    join public.modules m on m.id = om.module_id
    left join lateral (
      select
        mr.code,
        mr.name
      from public.user_module_roles umr
      join public.module_roles mr on mr.id = umr.module_role_id
      where umr.organization_module_id = om.id
        and umr.user_id = auth.uid()
        and umr.status = 'active'
        and umr.valid_from <= timezone('utc', now())
        and (umr.valid_until is null or umr.valid_until >= timezone('utc', now()))
        and mr.active = true
      order by mr.role_level desc, lower(mr.name)
      limit 1
    ) context_role on true
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
$function$;
