-- SPARKs - Restauracao governada de parametros herdados
begin;

create or replace function public.clear_sparks_parameter_value(
  p_parameter_key text,
  p_scope_type text,
  p_organization_id uuid default null,
  p_module_code text default null,
  p_project_id uuid default null,
  p_change_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_existing public.sparks_parameter_values%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;
  if p_change_reason is null or length(trim(p_change_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.' using errcode = '22023';
  end if;
  if p_scope_type in ('platform','module') then
    if not public.is_platform_super_admin() then
      raise exception 'Acesso negado para restaurar parametro de plataforma/modulo.' using errcode = '42501';
    end if;
  elsif p_organization_id is null or not public.can_manage_organization(p_organization_id) then
    raise exception 'Acesso negado para restaurar parametro desta organizacao.' using errcode = '42501';
  end if;

  select * into v_existing
  from public.sparks_parameter_values
  where parameter_key = p_parameter_key
    and scope_type = p_scope_type
    and organization_id is not distinct from p_organization_id
    and module_code is not distinct from p_module_code
    and project_id is not distinct from p_project_id
    and status = 'active'
  for update;

  if v_existing.id is null then
    return;
  end if;

  update public.sparks_parameter_values
  set status = 'inactive',
      updated_at = timezone('utc', now()),
      updated_by = auth.uid(),
      change_reason = trim(p_change_reason)
  where id = v_existing.id;

  insert into public.sparks_parameter_audit (
    parameter_key, scope_type, organization_id, module_code, project_id,
    actor_user_id, action_code, reason, previous_data, new_data
  ) values (
    p_parameter_key, p_scope_type, p_organization_id, p_module_code, p_project_id,
    auth.uid(), 'parameter_override_cleared', trim(p_change_reason),
    jsonb_build_object(
      'parameter_value', v_existing.parameter_value,
      'effective_from', v_existing.effective_from,
      'effective_until', v_existing.effective_until
    ),
    jsonb_build_object('inheritance_restored', true)
  );
end;
$$;

revoke all on function public.clear_sparks_parameter_value(text,text,uuid,text,uuid,text) from public, anon;
grant execute on function public.clear_sparks_parameter_value(text,text,uuid,text,uuid,text) to authenticated, service_role;

commit;
