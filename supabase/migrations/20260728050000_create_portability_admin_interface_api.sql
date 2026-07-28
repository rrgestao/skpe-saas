begin;

create or replace function public.get_portability_layouts(
  target_module_code text default null,
  target_direction text default null
)
returns table (
  layout_id uuid,
  module_code text,
  layout_code text,
  layout_name text,
  layout_version text,
  file_type text,
  direction text,
  description text,
  minimum_platform_version text,
  active boolean
)
language sql
security definer
set search_path = public
as $$
  select l.id, l.module_code, l.layout_code, l.layout_name, l.layout_version,
         l.file_type, l.direction, l.description, l.minimum_platform_version, l.active
  from public.sparks_portability_layouts l
  where (target_module_code is null or l.module_code = target_module_code)
    and (target_direction is null or l.direction in (target_direction, 'both'))
    and (public.is_platform_super_admin() or auth.role() = 'service_role')
  order by l.layout_name asc, l.layout_version desc;
$$;

create or replace function public.set_portability_package_status(
  target_package_id uuid,
  target_status text,
  target_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_package public.sparks_portability_packages%rowtype;
begin
  if target_status not in ('draft','preparing','validating','ready','processing','completed','completed_with_warnings','failed','cancelled','archived') then
    raise exception 'Situação inválida.';
  end if;
  select * into v_package from public.sparks_portability_packages where id = target_package_id;
  if not found then raise exception 'Pacote não encontrado.'; end if;
  if not (public.is_platform_super_admin() or public.can_manage_skpe_governance(v_package.organization_id)) then
    raise exception 'Acesso negado.' using errcode='42501';
  end if;
  update public.sparks_portability_packages
  set status = target_status, metadata = coalesce(metadata,'{}'::jsonb) || jsonb_build_object('last_status_reason', target_reason), updated_at = now(), updated_by = auth.uid()
  where id = target_package_id;
  insert into public.sparks_portability_audit(package_id,organization_id,actor_user_id,action_code,action_description,previous_data,new_data)
  values(target_package_id,v_package.organization_id,auth.uid(),'PACKAGE_STATUS_CHANGED',target_reason,jsonb_build_object('status',v_package.status),jsonb_build_object('status',target_status));
end;
$$;

grant execute on function public.get_portability_layouts(text,text) to authenticated, service_role;
grant execute on function public.set_portability_package_status(uuid,text,text) to authenticated, service_role;

commit;

select
  (select count(*) from public.sparks_portability_layouts where active) as layouts_ativos,
  to_regprocedure('public.get_portability_layouts(text,text)') is not null as funcao_layouts,
  to_regprocedure('public.set_portability_package_status(uuid,text,text)') is not null as funcao_status;
