-- SK-PE - Parameter authority alignment
-- Platform/module defaults remain platform-super-admin only.
-- Organization x SK-PE overrides may be managed by organization admin
-- or by SK-PE module governance administrators.

create or replace function public.set_sparks_parameter_value(
  p_parameter_key text,
  p_scope_type text,
  p_parameter_value jsonb,
  p_organization_id uuid default null::uuid,
  p_module_code text default null::text,
  p_project_id uuid default null::uuid,
  p_effective_from date default null::date,
  p_effective_until date default null::date,
  p_change_reason text default null::text
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_existing public.sparks_parameter_values%rowtype;
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuario nao autenticado.' using errcode = '42501';
  end if;

  if p_change_reason is null or length(trim(p_change_reason)) < 10 then
    raise exception 'Informe justificativa com pelo menos 10 caracteres.' using errcode = '22023';
  end if;

  if p_scope_type not in ('platform','module','organization','organization_module','project') then
    raise exception 'Escopo de parametro invalido.' using errcode = '22023';
  end if;

  perform public.validate_sparks_parameter_value(p_parameter_key, p_parameter_value);

  if p_scope_type in ('platform','module') then
    if not public.is_platform_super_admin() then
      raise exception 'Acesso negado para alterar parametros de plataforma/modulo.' using errcode = '42501';
    end if;
  elsif p_scope_type = 'organization_module' and p_module_code = 'SK-PE' then
    if p_organization_id is null or not public.can_manage_skpe_governance(p_organization_id) then
      raise exception 'Acesso negado para parametrizar o SK-PE desta organizacao.' using errcode = '42501';
    end if;
  else
    if p_organization_id is null or not public.can_manage_organization(p_organization_id) then
      raise exception 'Acesso negado para alterar parametros desta organizacao.' using errcode = '42501';
    end if;
  end if;

  if p_scope_type = 'platform' and (p_organization_id is not null or p_module_code is not null or p_project_id is not null) then
    raise exception 'Escopo platform nao aceita organizacao, modulo ou projeto.' using errcode = '22023';
  elsif p_scope_type = 'module' and (p_module_code is null or p_organization_id is not null or p_project_id is not null) then
    raise exception 'Escopo module exige somente module_code.' using errcode = '22023';
  elsif p_scope_type = 'organization' and (p_organization_id is null or p_module_code is not null or p_project_id is not null) then
    raise exception 'Escopo organization exige somente organization_id.' using errcode = '22023';
  elsif p_scope_type = 'organization_module' and (p_organization_id is null or p_module_code is null or p_project_id is not null) then
    raise exception 'Escopo organization_module exige organization_id e module_code.' using errcode = '22023';
  elsif p_scope_type = 'project' and (p_organization_id is null or p_module_code is null or p_project_id is null) then
    raise exception 'Escopo project exige organization_id, module_code e project_id.' using errcode = '22023';
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
    insert into public.sparks_parameter_values (
      parameter_key, scope_type, organization_id, module_code, project_id,
      parameter_value, effective_from, effective_until, change_reason,
      created_by, updated_by
    ) values (
      p_parameter_key, p_scope_type, p_organization_id, p_module_code, p_project_id,
      p_parameter_value, p_effective_from, p_effective_until, trim(p_change_reason),
      auth.uid(), auth.uid()
    ) returning id into v_id;
  else
    update public.sparks_parameter_values
    set parameter_value = p_parameter_value,
        effective_from = p_effective_from,
        effective_until = p_effective_until,
        change_reason = trim(p_change_reason),
        updated_at = timezone('utc', now()),
        updated_by = auth.uid()
    where id = v_existing.id
    returning id into v_id;
  end if;

  insert into public.sparks_parameter_audit (
    parameter_key, scope_type, organization_id, module_code, project_id,
    actor_user_id, action_code, reason, previous_data, new_data
  ) values (
    p_parameter_key, p_scope_type, p_organization_id, p_module_code, p_project_id,
    auth.uid(), case when v_existing.id is null then 'parameter_override_created' else 'parameter_override_updated' end,
    trim(p_change_reason),
    case when v_existing.id is null then null else jsonb_build_object(
      'parameter_value', v_existing.parameter_value,
      'effective_from', v_existing.effective_from,
      'effective_until', v_existing.effective_until
    ) end,
    jsonb_build_object(
      'parameter_value', p_parameter_value,
      'effective_from', p_effective_from,
      'effective_until', p_effective_until
    )
  );

  return v_id;
end;
$function$;

create or replace function public.clear_sparks_parameter_value(
  p_parameter_key text,
  p_scope_type text,
  p_organization_id uuid default null::uuid,
  p_module_code text default null::text,
  p_project_id uuid default null::uuid,
  p_change_reason text default null::text
)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
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
  elsif p_scope_type = 'organization_module' and p_module_code = 'SK-PE' then
    if p_organization_id is null or not public.can_manage_skpe_governance(p_organization_id) then
      raise exception 'Acesso negado para restaurar parametro do SK-PE desta organizacao.' using errcode = '42501';
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

  if v_existing.id is null then return; end if;

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
$function$;
