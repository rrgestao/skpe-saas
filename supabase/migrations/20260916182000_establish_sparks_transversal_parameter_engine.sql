-- SPARKs - Fundacao transversal de parametros herdaveis
-- Precedencia: projeto > organizacao/modulo > organizacao > modulo > default SPARKs.
-- Identidade visual permanece em sua autoridade propria; esta fundacao governa regras operacionais.

begin;

create table public.sparks_parameter_definitions (
  parameter_key text primary key,
  parameter_group text not null,
  name text not null,
  description text,
  value_type text not null,
  default_value jsonb not null,
  module_code text,
  unit text,
  validation_rule jsonb not null default '{}'::jsonb,
  status text not null default 'active',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),
  constraint sparks_parameter_definitions_type_check
    check (value_type in ('number','text','boolean','json')),
  constraint sparks_parameter_definitions_status_check
    check (status in ('active','inactive','deprecated'))
);

create table public.sparks_parameter_values (
  id uuid primary key default gen_random_uuid(),
  parameter_key text not null references public.sparks_parameter_definitions(parameter_key) on delete cascade,
  scope_type text not null,
  organization_id uuid references public.organizations(id) on delete cascade,
  module_code text,
  project_id uuid,
  parameter_value jsonb not null,
  effective_from date,
  effective_until date,
  change_reason text not null,
  status text not null default 'active',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references public.profiles(id),
  constraint sparks_parameter_values_scope_check
    check (scope_type in ('platform','module','organization','organization_module','project')),
  constraint sparks_parameter_values_status_check
    check (status in ('active','inactive')),
  constraint sparks_parameter_values_period_check
    check (effective_until is null or effective_from is null or effective_until >= effective_from)
);

create unique index ux_sparks_parameter_values_active_scope
on public.sparks_parameter_values(
  parameter_key,
  scope_type,
  coalesce(organization_id, '00000000-0000-0000-0000-000000000000'::uuid),
  coalesce(module_code, ''),
  coalesce(project_id, '00000000-0000-0000-0000-000000000000'::uuid)
)
where status = 'active';

create table public.sparks_parameter_audit (
  id uuid primary key default gen_random_uuid(),
  parameter_key text not null,
  scope_type text not null,
  organization_id uuid,
  module_code text,
  project_id uuid,
  actor_user_id uuid references public.profiles(id),
  action_code text not null,
  reason text not null,
  previous_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.sparks_parameter_definitions is
  'Catalogo transversal de parametros SPARKs, com default, tipo, unidade e regras de validacao.';
comment on table public.sparks_parameter_values is
  'Overrides herdaveis por plataforma, modulo, organizacao, organizacao/modulo e projeto.';
comment on table public.sparks_parameter_audit is
  'Trilha de auditoria das alteracoes de parametros transversais.';

create or replace function public.validate_sparks_parameter_value(
  p_parameter_key text,
  p_value jsonb
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_definition public.sparks_parameter_definitions%rowtype;
  v_number numeric;
begin
  select * into v_definition
  from public.sparks_parameter_definitions
  where parameter_key = p_parameter_key and status = 'active';

  if v_definition.parameter_key is null then
    raise exception 'Parametro ativo nao encontrado: %', p_parameter_key using errcode = '22023';
  end if;

  if p_value is null then
    raise exception 'Valor do parametro nao pode ser nulo.' using errcode = '22023';
  end if;

  if v_definition.value_type = 'number' then
    if jsonb_typeof(p_value) <> 'number' then
      raise exception 'Parametro % exige valor numerico.', p_parameter_key using errcode = '22023';
    end if;
    v_number := (p_value #>> '{}')::numeric;
    if v_definition.validation_rule ? 'min'
       and v_number < (v_definition.validation_rule->>'min')::numeric then
      raise exception 'Valor abaixo do minimo permitido para %.', p_parameter_key using errcode = '22023';
    end if;
    if v_definition.validation_rule ? 'max'
       and v_number > (v_definition.validation_rule->>'max')::numeric then
      raise exception 'Valor acima do maximo permitido para %.', p_parameter_key using errcode = '22023';
    end if;
  elsif v_definition.value_type = 'text' then
    if jsonb_typeof(p_value) <> 'string' then
      raise exception 'Parametro % exige valor textual.', p_parameter_key using errcode = '22023';
    end if;
  elsif v_definition.value_type = 'boolean' then
    if jsonb_typeof(p_value) <> 'boolean' then
      raise exception 'Parametro % exige valor booleano.', p_parameter_key using errcode = '22023';
    end if;
  end if;

  if v_definition.validation_rule ? 'allowed_values'
     and not exists (
       select 1
       from jsonb_array_elements(v_definition.validation_rule->'allowed_values') allowed(value)
       where allowed.value = p_value
     ) then
    raise exception 'Valor nao permitido para o parametro %.', p_parameter_key using errcode = '22023';
  end if;

  return true;
end;
$$;

create or replace function public.get_sparks_effective_parameter(
  p_parameter_key text,
  p_organization_id uuid default null,
  p_module_code text default null,
  p_project_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_definition public.sparks_parameter_definitions%rowtype;
  v_value public.sparks_parameter_values%rowtype;
  v_source text := 'sparks_default';
begin
  select * into v_definition
  from public.sparks_parameter_definitions
  where parameter_key = p_parameter_key
    and status = 'active';

  if v_definition.parameter_key is null then
    raise exception 'Parametro ativo nao encontrado: %', p_parameter_key using errcode = '22023';
  end if;

  if p_organization_id is not null
     and auth.uid() is not null
     and not public.can_read_organization(p_organization_id) then
    raise exception 'Acesso negado para consultar parametros desta organizacao.' using errcode = '42501';
  end if;

  select candidate.* into v_value
  from (
    select pv.*,
      case pv.scope_type
        when 'project' then 50
        when 'organization_module' then 40
        when 'organization' then 30
        when 'module' then 20
        when 'platform' then 10
        else 0
      end as precedence
    from public.sparks_parameter_values pv
    where pv.parameter_key = p_parameter_key
      and pv.status = 'active'
      and (pv.effective_from is null or pv.effective_from <= current_date)
      and (pv.effective_until is null or pv.effective_until >= current_date)
      and (
        (pv.scope_type = 'project' and p_project_id is not null and pv.project_id = p_project_id)
        or (pv.scope_type = 'organization_module' and p_organization_id is not null and p_module_code is not null and pv.organization_id = p_organization_id and pv.module_code = p_module_code)
        or (pv.scope_type = 'organization' and p_organization_id is not null and pv.organization_id = p_organization_id)
        or (pv.scope_type = 'module' and p_module_code is not null and pv.module_code = p_module_code)
        or pv.scope_type = 'platform'
      )
  ) candidate
  order by candidate.precedence desc, candidate.updated_at desc
  limit 1;

  if v_value.id is not null then
    v_source := v_value.scope_type;
  end if;

  return jsonb_build_object(
    'parameter_key', v_definition.parameter_key,
    'parameter_group', v_definition.parameter_group,
    'name', v_definition.name,
    'value_type', v_definition.value_type,
    'unit', v_definition.unit,
    'value', coalesce(v_value.parameter_value, v_definition.default_value),
    'source_scope', v_source,
    'source_value_id', v_value.id,
    'organization_id', v_value.organization_id,
    'module_code', coalesce(v_value.module_code, v_definition.module_code),
    'project_id', v_value.project_id,
    'default_value', v_definition.default_value
  );
end;
$$;

create or replace function public.get_sparks_effective_parameter_number(
  p_parameter_key text,
  p_organization_id uuid default null,
  p_module_code text default null,
  p_project_id uuid default null
)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select ((public.get_sparks_effective_parameter(
    p_parameter_key, p_organization_id, p_module_code, p_project_id
  )->'value') #>> '{}')::numeric;
$$;

create or replace function public.set_sparks_parameter_value(
  p_parameter_key text,
  p_scope_type text,
  p_parameter_value jsonb,
  p_organization_id uuid default null,
  p_module_code text default null,
  p_project_id uuid default null,
  p_effective_from date default null,
  p_effective_until date default null,
  p_change_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

insert into public.sparks_parameter_definitions (
  parameter_key, parameter_group, name, description, value_type,
  default_value, module_code, unit, validation_rule, metadata
) values
  ('SKPE.JOURNEY.DURATION_MODE', 'skpe.journey.temporal', 'Modo de contagem da Jornada',
   'Define se os prazos da Jornada SK-PE usam dias uteis ou dias corridos.',
   'text', '"business_days"'::jsonb, 'SK-PE', null,
   '{"allowed_values":["business_days","calendar_days"]}'::jsonb,
   '{"source":"SPARKs PE default","ownership":"parameter_engine"}'::jsonb),
  ('SKPE.JOURNEY.STANDARD_DURATION', 'skpe.journey.temporal', 'Duracao padrao da Jornada',
   'Duracao global sugerida para implantacao da Jornada Estrategica.',
   'number', '90'::jsonb, 'SK-PE', 'days', '{"min":1,"max":730}'::jsonb,
   '{"source":"SPARKs PE default","ownership":"parameter_engine"}'::jsonb),
  ('SKPE.JOURNEY.ACCELERATED_DURATION', 'skpe.journey.temporal', 'Duracao acelerada da Jornada',
   'Referencia acelerada para implantacao da Jornada Estrategica.',
   'number', '45'::jsonb, 'SK-PE', 'days', '{"min":1,"max":730}'::jsonb,
   '{"source":"SPARKs PE default","ownership":"parameter_engine"}'::jsonb),
  ('SKPE.JOURNEY.POST_DELIVERY_FOLLOWUP', 'skpe.journey.temporal', 'Acompanhamento pos-entrega',
   'Periodo sugerido de acompanhamento apos a entrega da Jornada.',
   'number', '90'::jsonb, 'SK-PE', 'days', '{"min":0,"max":730}'::jsonb,
   '{"source":"SPARKs PE default","ownership":"parameter_engine"}'::jsonb)
on conflict (parameter_key) do nothing;

create or replace function public.sparks_date_at_offset(
  p_start_date date,
  p_offset integer,
  p_duration_mode text
)
returns date
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_start_date is null then return null; end if;
  if p_offset is null or p_offset < 0 then
    raise exception 'Offset deve ser maior ou igual a zero.' using errcode = '22023';
  end if;
  if p_duration_mode = 'business_days' then
    return public.skpe_business_day_at_offset(p_start_date, p_offset);
  elsif p_duration_mode = 'calendar_days' then
    return p_start_date + p_offset;
  end if;
  raise exception 'Modo de duracao invalido: %', p_duration_mode using errcode = '22023';
end;
$$;

create or replace function public.list_sparks_effective_parameters(
  p_organization_id uuid default null,
  p_module_code text default null,
  p_project_id uuid default null
)
returns setof jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select public.get_sparks_effective_parameter(
    d.parameter_key, p_organization_id, p_module_code, p_project_id
  )
  from public.sparks_parameter_definitions d
  where d.status = 'active'
    and (d.module_code is null or p_module_code is null or d.module_code = p_module_code)
  order by d.parameter_group, d.parameter_key;
$$;

alter table public.sparks_parameter_definitions enable row level security;
alter table public.sparks_parameter_values enable row level security;
alter table public.sparks_parameter_audit enable row level security;

revoke all on table public.sparks_parameter_definitions from public, anon, authenticated;
revoke all on table public.sparks_parameter_values from public, anon, authenticated;
revoke all on table public.sparks_parameter_audit from public, anon, authenticated;

grant select on table public.sparks_parameter_definitions to authenticated;
grant all on table public.sparks_parameter_definitions to service_role;
grant all on table public.sparks_parameter_values to service_role;
grant all on table public.sparks_parameter_audit to service_role;

create policy sparks_parameter_definitions_select_authenticated
on public.sparks_parameter_definitions
for select to authenticated
using (status <> 'deprecated');

revoke all on function public.validate_sparks_parameter_value(text,jsonb) from public, anon;
revoke all on function public.get_sparks_effective_parameter(text,uuid,text,uuid) from public, anon;
revoke all on function public.get_sparks_effective_parameter_number(text,uuid,text,uuid) from public, anon;
revoke all on function public.set_sparks_parameter_value(text,text,jsonb,uuid,text,uuid,date,date,text) from public, anon;
revoke all on function public.sparks_date_at_offset(date,integer,text) from public, anon;
revoke all on function public.list_sparks_effective_parameters(uuid,text,uuid) from public, anon;

grant execute on function public.validate_sparks_parameter_value(text,jsonb) to authenticated, service_role;
grant execute on function public.get_sparks_effective_parameter(text,uuid,text,uuid) to authenticated, service_role;
grant execute on function public.get_sparks_effective_parameter_number(text,uuid,text,uuid) to authenticated, service_role;
grant execute on function public.set_sparks_parameter_value(text,text,jsonb,uuid,text,uuid,date,date,text) to authenticated, service_role;
grant execute on function public.sparks_date_at_offset(date,integer,text) to authenticated, service_role;
grant execute on function public.list_sparks_effective_parameters(uuid,text,uuid) to authenticated, service_role;

commit;
