begin;

create or replace function public.get_skpe_organizational_areas(
  target_organization_id uuid,
  include_inactive boolean default true
)
returns table (
  area_id uuid,
  area_code text,
  area_name text,
  area_description text,
  area_type text,
  parent_area_id uuid,
  parent_area_name text,
  display_order integer,
  active boolean,
  child_count bigint,
  linked_role_count bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_view_skpe_governance(target_organization_id) then
    raise exception 'Acesso negado para consultar áreas da organização.';
  end if;
  return query
  select dv.id, dv.code, dv.name, dv.description, dv.metadata->>'area_type', dv.parent_value_id, parent.name,
         dv.display_order, dv.active,
         (select count(*) from public.sparks_domain_values child where child.parent_value_id=dv.id),
         (select count(*) from public.sparks_organizational_roles r where r.organization_id=target_organization_id and lower(coalesce(r.organizational_area,''))=lower(dv.name))
  from public.sparks_domain_values dv
  join public.sparks_domains d on d.id=dv.domain_id
  left join public.sparks_domain_values parent on parent.id=dv.parent_value_id
  where d.organization_id=target_organization_id and d.scope_type='organization' and d.code='ORGANIZATIONAL_AREA'
    and (include_inactive or dv.active)
  order by lower(dv.name), dv.code;
end;$$;

create or replace function public.upsert_skpe_organizational_area(
  target_organization_id uuid,
  target_area_id uuid,
  target_code text,
  target_name text,
  target_description text,
  target_area_type text,
  target_parent_area_id uuid,
  target_display_order integer,
  target_active boolean,
  change_reason text
)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_domain_id uuid; v_area_id uuid;
begin
  if not (public.can_manage_skpe_governance(target_organization_id) or auth.role()='service_role' or session_user in ('postgres','supabase_admin')) then raise exception 'Acesso negado para manter áreas.'; end if;
  if length(trim(coalesce(change_reason,'')))<10 then raise exception 'Informe justificativa com pelo menos 10 caracteres.'; end if;
  if trim(coalesce(target_code,''))='' or trim(coalesce(target_name,''))='' then raise exception 'Código e nome são obrigatórios.'; end if;
  select id into v_domain_id from public.sparks_domains where organization_id=target_organization_id and scope_type='organization' and code='ORGANIZATIONAL_AREA' limit 1;
  if v_domain_id is null then raise exception 'Domínio ORGANIZATIONAL_AREA não encontrado para a organização.'; end if;
  if target_parent_area_id is not null and target_parent_area_id=target_area_id then raise exception 'Uma área não pode ser superior a si própria.'; end if;
  if target_area_id is null then
    insert into public.sparks_domain_values(domain_id,code,name,description,display_order,parent_value_id,protected,active,metadata,created_by,updated_by)
    values(v_domain_id,upper(trim(target_code)),trim(target_name),nullif(trim(target_description),''),coalesce(target_display_order,100),target_parent_area_id,false,coalesce(target_active,true),jsonb_build_object('area_type',target_area_type,'planning_scope',true,'last_change_reason',change_reason),auth.uid(),auth.uid()) returning id into v_area_id;
  else
    update public.sparks_domain_values set name=trim(target_name),description=nullif(trim(target_description),''),display_order=coalesce(target_display_order,100),parent_value_id=target_parent_area_id,active=coalesce(target_active,true),metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('area_type',target_area_type,'last_change_reason',change_reason),updated_at=timezone('utc',now()),updated_by=auth.uid() where id=target_area_id and domain_id=v_domain_id returning id into v_area_id;
    if v_area_id is null then raise exception 'Área não encontrada.'; end if;
  end if;
  return v_area_id;
end;$$;

create or replace function public.set_skpe_organizational_area_active(target_organization_id uuid,target_area_id uuid,target_active boolean,change_reason text)
returns void language plpgsql security definer set search_path=public as $$
begin
  perform public.upsert_skpe_organizational_area(target_organization_id,target_area_id,dv.code,dv.name,dv.description,dv.metadata->>'area_type',dv.parent_value_id,dv.display_order,target_active,change_reason)
  from public.sparks_domain_values dv where dv.id=target_area_id;
end;$$;

create or replace function public.delete_skpe_organizational_area(target_organization_id uuid,target_area_id uuid,change_reason text)
returns void language plpgsql security definer set search_path=public as $$
declare v_name text; v_children bigint; v_roles bigint;
begin
  if not (public.can_manage_skpe_governance(target_organization_id) or auth.role()='service_role' or session_user in ('postgres','supabase_admin')) then raise exception 'Acesso negado para excluir áreas.'; end if;
  if length(trim(coalesce(change_reason,'')))<10 then raise exception 'Informe justificativa com pelo menos 10 caracteres.'; end if;
  select name into v_name from public.sparks_domain_values where id=target_area_id;
  select count(*) into v_children from public.sparks_domain_values where parent_value_id=target_area_id;
  select count(*) into v_roles from public.sparks_organizational_roles where organization_id=target_organization_id and lower(coalesce(organizational_area,''))=lower(coalesce(v_name,''));
  if v_children>0 then raise exception 'A área possui % área(s) subordinada(s). Desative-a ou reorganize a hierarquia antes de excluir.',v_children; end if;
  if v_roles>0 then raise exception 'A área possui % papel(is) vinculado(s). A exclusão física foi bloqueada; utilize a desativação.',v_roles; end if;
  delete from public.sparks_domain_values dv using public.sparks_domains d where dv.id=target_area_id and d.id=dv.domain_id and d.organization_id=target_organization_id and d.code='ORGANIZATIONAL_AREA';
  if not found then raise exception 'Área não encontrada.'; end if;
end;$$;

grant execute on function public.get_skpe_organizational_areas(uuid,boolean) to authenticated,service_role;
grant execute on function public.upsert_skpe_organizational_area(uuid,uuid,text,text,text,text,uuid,integer,boolean,text) to authenticated,service_role;
grant execute on function public.set_skpe_organizational_area_active(uuid,uuid,boolean,text) to authenticated,service_role;
grant execute on function public.delete_skpe_organizational_area(uuid,uuid,text) to authenticated,service_role;
commit;
